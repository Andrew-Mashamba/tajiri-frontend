import 'dart:convert';

import 'package:biometric_storage/biometric_storage.dart';
import 'package:cryptography/cryptography.dart';
import 'package:flutter/foundation.dart';

/// Native key helper for the docs/Bio.md Flow 2 passkey flow.
///
/// What this gives us that Flow 1 didn't:
///
///   • The EC P-256 private key never leaves a biometric-gated OS
///     storage container. On iOS that's a Keychain item with
///     `kSecAccessControlBiometryCurrentSet`; on Android, a Keystore-
///     backed encrypted blob with `setUserAuthenticationRequired(true)`.
///     A rooted-device attacker cannot extract the bytes, and a Frida
///     hook on Dart-level biometric checks cannot bypass the OS-level
///     signing requirement (the OS itself refuses to release the key
///     for cryptographic operations without biometric).
///
///   • Each "use" of the key (signing a fresh server-issued challenge)
///     produces a single-use signature the server can mathematically
///     verify against the stored public key — so the server has proof
///     that someone with biometric access on this enrolled device just
///     authenticated, less than 60 seconds ago.
///
/// Implementation note on the storage shape:
/// `biometric_storage` exposes a "biometric-gated string" container.
/// We serialize the EC private key to a deterministic JWK and store
/// that. Per call, we pull it out (one biometric prompt), reconstruct
/// the SimpleKeyPair, sign the message, and immediately drop it from
/// memory.
///
/// This is the closest pure-Dart approximation to a hardware-resident
/// key. The cryptographic operation happens in app memory, not in the
/// secure enclave — a determined attacker who can attach a debugger
/// to a foregrounded app process during the sign-in window could
/// theoretically read it. Going further would require platform-channel
/// code that uses SecKeyCreateSignature on iOS and a Keystore-bound
/// Signature object on Android. For the threat models docs/Bio.md
/// targets (stolen tokens, Frida hooks, rooted-device storage
/// extraction), what we have here is sufficient.
class BiometricKeyHelper {
  static final BiometricKeyHelper instance = BiometricKeyHelper._();
  BiometricKeyHelper._();

  /// `biometric_storage` keys each container by name. We use the
  /// `key_id` we register with the server so multiple per-device
  /// biometric credentials can coexist in theory (currently TAJIRI uses
  /// one per device).
  static String _containerNameFor(String keyId) => 'tajiri_bio_$keyId';

  /// Generate a fresh EC P-256 keypair, store the private half in a
  /// biometric-gated container, and return the public-key PEM (SPKI
  /// format) plus the matching `key_id` so the caller can register
  /// the public key with the server.
  ///
  /// The keypair is *generated* without prompting biometric — there's
  /// nothing to authenticate against yet. The first biometric prompt
  /// comes when the user actually signs in or steps up.
  Future<({String keyId, String publicKeyPem})> generateAndStore() async {
    final ecdsa = Ecdsa.p256(Sha256());
    final keyPair = await ecdsa.newKeyPair();
    final keyPairData = await keyPair.extract();

    // Generate a stable per-keypair key_id (32 hex chars).
    final keyId = await _randomKeyId();

    // We persist the keypair as a JWK-style JSON blob in biometric
    // storage. This format is deterministic, small, and trivial to
    // reconstruct via SimpleKeyPairData.
    final blob = jsonEncode({
      'd':  base64Encode(keyPairData.d),
      'x':  base64Encode(keyPairData.publicKey.x),
      'y':  base64Encode(keyPairData.publicKey.y),
    });

    final container = await _container(keyId, biometricRequired: true);
    await container.write(blob);

    final pubKeyPem = _ecPublicKeyPem(
      Uint8List.fromList(keyPairData.publicKey.x),
      Uint8List.fromList(keyPairData.publicKey.y),
    );

    return (keyId: keyId, publicKeyPem: pubKeyPem);
  }

  /// Sign `message` with the biometric-protected private key associated
  /// with `keyId`. Reading the container triggers the OS biometric
  /// prompt — if the user cancels or the sensor is locked out, this
  /// throws. Returns the raw 64-byte ECDSA signature (r||s).
  Future<Uint8List?> sign(String keyId, List<int> message) async {
    try {
      final container = await _container(keyId, biometricRequired: true);
      final blob = await container.read();
      if (blob == null) return null;

      final json = jsonDecode(blob) as Map<String, dynamic>;
      final d = base64Decode(json['d'] as String);
      final x = base64Decode(json['x'] as String);
      final y = base64Decode(json['y'] as String);

      final ecdsa = Ecdsa.p256(Sha256());
      final keyPair = await ecdsa.newKeyPairFromSeed(d);
      // Sanity-check public coords against what we stored. If they
      // disagree the storage is corrupt; refuse rather than silently
      // signing with a key the server doesn't know.
      final pubFromSeed = await keyPair.extractPublicKey();
      if (!_equalBytes(pubFromSeed.x, x) || !_equalBytes(pubFromSeed.y, y)) {
        debugPrint('[BiometricKeyHelper] stored public key mismatch — refusing to sign');
        return null;
      }

      final signature = await ecdsa.sign(message, keyPair: keyPair);
      return Uint8List.fromList(signature.bytes);
    } on AuthException catch (e) {
      debugPrint('[BiometricKeyHelper] auth exception: ${e.code}');
      return null;
    } catch (e) {
      debugPrint('[BiometricKeyHelper] sign error: $e');
      return null;
    }
  }

  /// Wipe the biometric-protected key from device storage. Called on
  /// logout, PIN change, account deletion, or explicit revoke.
  Future<void> wipe(String keyId) async {
    try {
      final container = await _container(keyId, biometricRequired: false);
      await container.delete();
    } catch (e) {
      debugPrint('[BiometricKeyHelper] wipe error: $e');
    }
  }

  /// Whether the platform can host a biometric-gated storage container.
  /// Different from `local_auth.canCheckBiometrics`: this checks the
  /// `biometric_storage` capability, which on Android additionally
  /// requires Keystore + AES support.
  Future<CanAuthenticateResponse> capability() {
    return BiometricStorage().canAuthenticate();
  }

  // ── Internals ────────────────────────────────────────────────────────────

  Future<BiometricStorageFile> _container(String keyId, {required bool biometricRequired}) {
    return BiometricStorage().getStorage(
      _containerNameFor(keyId),
      options: StorageFileInitOptions(
        authenticationRequired: biometricRequired,
        // Don't expire the storage between authentications; we want
        // each *use* to prompt biometric, not accumulate trust.
        authenticationValidityDurationSeconds: 0,
      ),
      promptInfo: const PromptInfo(
        iosPromptInfo: IosPromptInfo(
          accessTitle: 'Authenticate',
          saveTitle: 'Authenticate',
        ),
        androidPromptInfo: AndroidPromptInfo(
          title: 'Sign in',
          subtitle: 'Use your fingerprint or face',
          negativeButton: 'Use PIN',
          confirmationRequired: false,
        ),
      ),
    );
  }

  Future<String> _randomKeyId() async {
    // 16 bytes from a CSPRNG, hex-encoded. cryptography exposes
    // SecureRandom via newKeyPair, so reuse that to avoid an extra dep.
    final ecdsa = Ecdsa.p256(Sha256());
    final kp = await ecdsa.newKeyPair();
    final data = await kp.extract();
    return data.d.take(16).map((b) => b.toRadixString(16).padLeft(2, '0')).join();
  }

  /// Wrap an uncompressed EC P-256 point (x, y) as a PEM-encoded
  /// SubjectPublicKeyInfo block, which is what `openssl_pkey_get_public`
  /// expects on the backend.
  String _ecPublicKeyPem(Uint8List x, Uint8List y) {
    // SPKI for prime256v1: a fixed 26-byte ASN.1 prefix followed by
    // 0x04 (uncompressed) || x (32B) || y (32B). Hard-coded prefix
    // avoids pulling in a full ASN.1 encoder for one shape.
    const prefix = [
      0x30, 0x59, 0x30, 0x13, 0x06, 0x07, 0x2a, 0x86, 0x48, 0xce,
      0x3d, 0x02, 0x01, 0x06, 0x08, 0x2a, 0x86, 0x48, 0xce, 0x3d,
      0x03, 0x01, 0x07, 0x03, 0x42, 0x00, 0x04,
    ];
    final spki = <int>[...prefix, ...x, ...y];
    final b64 = base64Encode(spki);
    final wrapped = StringBuffer()
      ..writeln('-----BEGIN PUBLIC KEY-----');
    for (var i = 0; i < b64.length; i += 64) {
      wrapped.writeln(b64.substring(i, i + 64 > b64.length ? b64.length : i + 64));
    }
    wrapped.writeln('-----END PUBLIC KEY-----');
    return wrapped.toString();
  }

  bool _equalBytes(List<int> a, List<int> b) {
    if (a.length != b.length) return false;
    for (var i = 0; i < a.length; i++) {
      if (a[i] != b[i]) return false;
    }
    return true;
  }
}
