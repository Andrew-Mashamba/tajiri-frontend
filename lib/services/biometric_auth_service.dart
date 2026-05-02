import 'dart:convert';

import 'package:flutter/foundation.dart';
import 'package:flutter/services.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:http/http.dart' as http;
import 'package:local_auth/local_auth.dart';

import '../config/api_config.dart';
import 'biometric_key_helper.dart';

/// docs/Bio.md Flow 2 — passkey-style server-verified biometric sign-in.
///
/// At enrollment we generate a fresh EC P-256 keypair on-device. The
/// private half lives in a biometric-gated OS storage container
/// (`biometric_storage`); the public half goes to the server which
/// stores it in `biometric_credentials`. At sign-in the server issues
/// a one-time nonce, the client signs it with the biometric-protected
/// key (OS prompts the user mid-signing), and the server verifies the
/// signature against the stored public key.
///
/// Why this is stronger than Flow 1:
///   • No long-lived bearer secret on the device. The server-issued
///     refresh token from the previous session never gets stored
///     biometrically — it's exchanged for the new tokens after the
///     passkey login succeeds.
///   • Each sign-in produces a unique signature over a server-issued
///     nonce. Replay returns 410 Gone (cache pulled on use).
///   • The OS itself enforces biometric before signing — Frida-hooking
///     a Dart-level biometric prompt doesn't help.
///   • A rooted-device attacker who reads the storage container gets
///     an encrypted blob whose decryption key is in the secure enclave
///     / Keystore TEE.
///
/// The same key powers re-prompts for sensitive actions via
/// `BiometricStepUp.confirm(reason)` — see biometric_step_up.dart.
class BiometricAuthService {
  static final BiometricAuthService instance = BiometricAuthService._();
  BiometricAuthService._();

  // The non-biometric secure storage stores only the `key_id` so we
  // can find the right biometric_storage container at sign-in. The
  // private key itself never lives here.
  static const _secureStorage = FlutterSecureStorage(
    aOptions: AndroidOptions(encryptedSharedPreferences: true),
    iOptions: IOSOptions(
      accessibility: KeychainAccessibility.first_unlock_this_device,
    ),
  );
  static const _kKeyIdKey = 'bio_passkey_key_id';
  static const _kDeviceIdKey = 'bio_passkey_device_id';
  static const _kEnrolledAtKey = 'bio_passkey_enrolled_at';

  static final _localAuth = LocalAuthentication();

  // ── Capability ───────────────────────────────────────────────────────────

  Future<BiometricAvailability> checkAvailability() async {
    try {
      final supported = await _localAuth.isDeviceSupported();
      if (!supported) return BiometricAvailability.notSupported;
      final canCheck = await _localAuth.canCheckBiometrics;
      if (!canCheck) return BiometricAvailability.notEnrolled;
      final types = await _localAuth.getAvailableBiometrics();
      if (types.isEmpty) return BiometricAvailability.notEnrolled;
      final hasStrong = types.contains(BiometricType.strong) ||
          types.contains(BiometricType.fingerprint) ||
          types.contains(BiometricType.face);
      if (!hasStrong) return BiometricAvailability.weakOnly;
      return BiometricAvailability.available;
    } on PlatformException catch (e) {
      debugPrint('[BiometricAuth] availability error: $e');
      return BiometricAvailability.notSupported;
    }
  }

  Future<BiometricKind> kind() async {
    try {
      final types = await _localAuth.getAvailableBiometrics();
      if (types.contains(BiometricType.face)) return BiometricKind.face;
      if (types.contains(BiometricType.fingerprint)) return BiometricKind.fingerprint;
      if (types.contains(BiometricType.iris)) return BiometricKind.iris;
      return BiometricKind.generic;
    } catch (_) {
      return BiometricKind.generic;
    }
  }

  /// Whether passkey sign-in is armed on this device. Cheap; no prompt.
  Future<bool> isEnrolled() async {
    final keyId = await _secureStorage.read(key: _kKeyIdKey);
    return keyId != null && keyId.isNotEmpty;
  }

  Future<String?> currentKeyId() => _secureStorage.read(key: _kKeyIdKey);

  // ── Enrollment ───────────────────────────────────────────────────────────

  /// Generate a fresh keypair, register the public key with the server
  /// (PIN-gated to prove possession), and store the key_id locally.
  /// Caller is the Two-factor & biometric screen.
  Future<({bool success, String? error})> enroll({
    required int userId,
    required String pin,
    required String deviceId,
    String? deviceName,
  }) async {
    final avail = await checkAvailability();
    if (avail != BiometricAvailability.available) {
      return (success: false, error: 'Biometric is not available on this device');
    }

    // If a previous credential exists, revoke it server-side first so
    // we don't leave dangling rows in `biometric_credentials`.
    final existing = await _secureStorage.read(key: _kKeyIdKey);
    if (existing != null) {
      await _revokeServer(userId: userId, keyId: existing);
      await BiometricKeyHelper.instance.wipe(existing);
    }

    final ({String keyId, String publicKeyPem}) keys;
    try {
      keys = await BiometricKeyHelper.instance.generateAndStore();
    } catch (e) {
      return (success: false, error: 'Could not generate biometric key: $e');
    }

    try {
      final resp = await http.post(
        Uri.parse('${ApiConfig.baseUrl}/auth/biometric-enroll'),
        headers: const {
          'Content-Type': 'application/json',
          'Accept': 'application/json',
        },
        body: jsonEncode({
          'user_id':     userId,
          'pin':         pin,
          'public_key':  keys.publicKeyPem,
          'key_id':      keys.keyId,
          'device_id':   deviceId,
          'device_name': deviceName,
        }),
      ).timeout(const Duration(seconds: 15));

      if (resp.statusCode == 200) {
        await _secureStorage.write(key: _kKeyIdKey, value: keys.keyId);
        await _secureStorage.write(key: _kDeviceIdKey, value: deviceId);
        await _secureStorage.write(
          key: _kEnrolledAtKey,
          value: DateTime.now().toIso8601String(),
        );
        return (success: true, error: null);
      }

      // Roll back the local key — server didn't accept it.
      await BiometricKeyHelper.instance.wipe(keys.keyId);
      try {
        final body = jsonDecode(resp.body) as Map<String, dynamic>;
        return (success: false, error: body['message'] as String? ?? 'Enrollment failed');
      } catch (_) {
        return (success: false, error: 'Enrollment failed (HTTP ${resp.statusCode})');
      }
    } catch (e) {
      await BiometricKeyHelper.instance.wipe(keys.keyId);
      return (success: false, error: 'Could not reach the server');
    }
  }

  // ── Sign-in ──────────────────────────────────────────────────────────────

  Future<BiometricLoginResult> signIn() async {
    final keyId = await _secureStorage.read(key: _kKeyIdKey);
    final deviceId = await _secureStorage.read(key: _kDeviceIdKey);
    if (keyId == null || deviceId == null) {
      return BiometricLoginResult.failure(
        BiometricLoginError.notEnrolled,
        'No biometric sign-in is set up on this device.',
      );
    }

    // 1) Get a fresh challenge from the server.
    final String nonce;
    try {
      final r = await http.post(
        Uri.parse('${ApiConfig.baseUrl}/auth/biometric-challenge'),
        headers: const {
          'Content-Type': 'application/json',
          'Accept': 'application/json',
        },
        body: jsonEncode({'key_id': keyId}),
      ).timeout(const Duration(seconds: 10));
      if (r.statusCode != 200) {
        if (r.statusCode == 404) {
          // Server has no record of this credential — wipe local state.
          await _wipeLocal(keyId);
          return BiometricLoginResult.failure(
            BiometricLoginError.tokenRejected,
            'Biometric sign-in was revoked. Please sign in with your PIN.',
          );
        }
        return BiometricLoginResult.failure(
          BiometricLoginError.serverError,
          'Could not start biometric sign-in (HTTP ${r.statusCode}).',
        );
      }
      final body = jsonDecode(r.body) as Map<String, dynamic>;
      nonce = ((body['data'] as Map?)?['challenge'] as String?) ?? '';
      if (nonce.isEmpty) {
        return BiometricLoginResult.failure(
          BiometricLoginError.serverError,
          'Server returned an empty challenge.',
        );
      }
    } catch (_) {
      return BiometricLoginResult.failure(
        BiometricLoginError.network,
        'Could not reach the server.',
      );
    }

    // 2) Sign the nonce with the biometric-protected key (OS prompt).
    final signature = await BiometricKeyHelper.instance.sign(
      keyId,
      utf8.encode(nonce),
    );
    if (signature == null) {
      return BiometricLoginResult.failure(
        BiometricLoginError.userCancelled,
        'Biometric authentication was cancelled.',
      );
    }

    // 3) Send the signature to the server. On success it mints fresh
    //    access + refresh tokens with `is_biometric=true`.
    try {
      final r = await http.post(
        Uri.parse('${ApiConfig.baseUrl}/auth/biometric-login'),
        headers: const {
          'Content-Type': 'application/json',
          'Accept': 'application/json',
        },
        body: jsonEncode({
          'key_id':           keyId,
          'signed_challenge': base64Encode(signature),
          'device_id':        deviceId,
        }),
      ).timeout(const Duration(seconds: 15));

      final body = jsonDecode(r.body) as Map<String, dynamic>;
      if (r.statusCode == 200 && body['success'] == true) {
        return BiometricLoginResult.success(
          accessToken:       body['access_token'] as String,
          refreshToken:      body['refresh_token'] as String,
          accessExpiresIn:   body['access_expires_in'] as int? ?? 86400,
          refreshExpiresIn:  body['refresh_expires_in'] as int? ?? 7776000,
          user:              body['user'] as Map<String, dynamic>?,
        );
      }
      // 401 = bad signature; 410 = expired challenge. Either way, the
      // safe move is to retry — but if the server says the credential
      // is unknown (404), wipe local state.
      if (r.statusCode == 404) {
        await _wipeLocal(keyId);
        return BiometricLoginResult.failure(
          BiometricLoginError.tokenRejected,
          'Biometric sign-in was revoked. Please sign in with your PIN.',
        );
      }
      return BiometricLoginResult.failure(
        BiometricLoginError.serverError,
        body['message'] as String? ?? 'Could not sign in (HTTP ${r.statusCode}).',
      );
    } catch (_) {
      return BiometricLoginResult.failure(
        BiometricLoginError.network,
        'Could not reach the server.',
      );
    }
  }

  /// Sign an arbitrary message with the biometric key — used by
  /// `BiometricStepUp` for sensitive-action confirmations. Returns
  /// null on cancel / lockout.
  Future<({String keyId, String signatureB64})?> signForStepUp(String message) async {
    final keyId = await _secureStorage.read(key: _kKeyIdKey);
    if (keyId == null) return null;
    final sig = await BiometricKeyHelper.instance.sign(keyId, utf8.encode(message));
    if (sig == null) return null;
    return (keyId: keyId, signatureB64: base64Encode(sig));
  }

  // ── Revoke ───────────────────────────────────────────────────────────────

  Future<void> revoke({int? userId}) async {
    final keyId = await _secureStorage.read(key: _kKeyIdKey);
    if (keyId == null) return;
    if (userId != null) {
      await _revokeServer(userId: userId, keyId: keyId);
    }
    await _wipeLocal(keyId);
  }

  Future<void> _revokeServer({required int userId, required String keyId}) async {
    try {
      await http.post(
        Uri.parse('${ApiConfig.baseUrl}/auth/biometric-revoke'),
        headers: const {
          'Content-Type': 'application/json',
          'Accept': 'application/json',
        },
        body: jsonEncode({'user_id': userId, 'key_id': keyId}),
      ).timeout(const Duration(seconds: 10));
    } catch (_) {
      // Best-effort. Even if the server-side delete fails the local
      // wipe still happens, so the credential becomes unusable from
      // this device. The server-side row will be orphaned but a future
      // re-enrollment generates a different key_id.
    }
  }

  Future<void> _wipeLocal(String keyId) async {
    await BiometricKeyHelper.instance.wipe(keyId);
    await _secureStorage.delete(key: _kKeyIdKey);
    await _secureStorage.delete(key: _kDeviceIdKey);
    await _secureStorage.delete(key: _kEnrolledAtKey);
  }
}

// ── Public types (unchanged from Flow 1 — callers don't notice the swap) ───

enum BiometricAvailability { notSupported, notEnrolled, weakOnly, available }

enum BiometricKind { fingerprint, face, iris, generic }

extension BiometricKindCopy on BiometricKind {
  String get copyForPrompt {
    switch (this) {
      case BiometricKind.fingerprint:
        return 'fingerprint';
      case BiometricKind.face:
        return 'Face ID';
      case BiometricKind.iris:
        return 'iris';
      case BiometricKind.generic:
        return 'biometrics';
    }
  }
}

enum BiometricLoginError {
  notEnrolled,
  userCancelled,
  tokenRejected,
  network,
  serverError,
}

class BiometricLoginResult {
  final bool success;
  final String? accessToken;
  final String? refreshToken;
  final int? accessExpiresIn;
  final int? refreshExpiresIn;
  final Map<String, dynamic>? user;
  final BiometricLoginError? errorCode;
  final String? errorMessage;

  const BiometricLoginResult._({
    required this.success,
    this.accessToken,
    this.refreshToken,
    this.accessExpiresIn,
    this.refreshExpiresIn,
    this.user,
    this.errorCode,
    this.errorMessage,
  });

  factory BiometricLoginResult.success({
    required String accessToken,
    required String refreshToken,
    required int accessExpiresIn,
    required int refreshExpiresIn,
    Map<String, dynamic>? user,
  }) =>
      BiometricLoginResult._(
        success: true,
        accessToken: accessToken,
        refreshToken: refreshToken,
        accessExpiresIn: accessExpiresIn,
        refreshExpiresIn: refreshExpiresIn,
        user: user,
      );

  factory BiometricLoginResult.failure(BiometricLoginError code, String message) =>
      BiometricLoginResult._(success: false, errorCode: code, errorMessage: message);
}

