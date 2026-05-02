import 'dart:convert';

import 'package:flutter/foundation.dart';
import 'package:http/http.dart' as http;

import '../config/api_config.dart';
import 'biometric_auth_service.dart';

/// Cryptographic re-authentication for sensitive actions.
///
/// docs/Bio.md §3 — "Re-prompt biometric for sensitive actions —
/// don't trust an active session."
///
/// Usage in a sensitive screen, just before submitting:
///
///   final token = await BiometricStepUp.confirm(purpose: 'pin_change');
///   if (token == null) {
///     setState(() => _error = 'Biometric confirmation required');
///     return;
///   }
///   final r = await http.put(
///     someSensitiveUrl,
///     headers: { ...auth, 'X-Step-Up-Token': token },
///     body: ...,
///   );
///
/// If the user is PIN-only (no biometric enrolled), `confirm()` returns
/// the sentinel `BiometricStepUp.skipStepUp` and the caller should
/// proceed normally — backend honors the same rule (PIN-only users
/// pass through without a token).
class BiometricStepUp {
  /// Sentinel returned by `confirm()` when the user has no biometric
  /// credential armed. The backend's `BiometricStepUp::consume()`
  /// fails-open in the same case, so callers can use this to short-
  /// circuit the header on the outgoing request.
  static const String skipStepUp = '__bio_step_up_not_enrolled__';

  /// Run the full challenge → sign → step-up dance. Returns:
  ///   • the step-up token on success (48-char hex, 5-min TTL)
  ///   • `skipStepUp` if the user has no biometric credential
  ///   • `null` if the prompt was cancelled or the server rejected
  static Future<String?> confirm({required String purpose}) async {
    final keyId = await BiometricAuthService.instance.currentKeyId();
    if (keyId == null) {
      // No biometric armed on this device. The backend bypasses the
      // step-up gate for PIN-only users, so let the caller proceed.
      return skipStepUp;
    }

    // 1) Get a fresh nonce.
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
        debugPrint('[BiometricStepUp] challenge HTTP ${r.statusCode}');
        return null;
      }
      final body = jsonDecode(r.body) as Map<String, dynamic>;
      nonce = ((body['data'] as Map?)?['challenge'] as String?) ?? '';
      if (nonce.isEmpty) return null;
    } catch (e) {
      debugPrint('[BiometricStepUp] challenge error: $e');
      return null;
    }

    // 2) Sign the nonce with the biometric-protected key. The OS
    //    biometric prompt fires inside this call.
    final signed = await BiometricAuthService.instance.signForStepUp(nonce);
    if (signed == null) {
      // User cancelled, sensor lockout, or local key tampered with.
      return null;
    }

    // 3) Exchange the signature for a 5-minute step-up token.
    try {
      final r = await http.post(
        Uri.parse('${ApiConfig.baseUrl}/auth/biometric-step-up'),
        headers: const {
          'Content-Type': 'application/json',
          'Accept': 'application/json',
        },
        body: jsonEncode({
          'key_id':           signed.keyId,
          'signed_challenge': signed.signatureB64,
          'purpose':          purpose,
        }),
      ).timeout(const Duration(seconds: 10));
      if (r.statusCode != 200) {
        debugPrint('[BiometricStepUp] step-up HTTP ${r.statusCode}');
        return null;
      }
      final body = jsonDecode(r.body) as Map<String, dynamic>;
      if (body['success'] != true) return null;
      return ((body['data'] as Map?)?['step_up_token'] as String?);
    } catch (e) {
      debugPrint('[BiometricStepUp] step-up error: $e');
      return null;
    }
  }

  /// Convenience wrapper — given a (possibly null) base headers map and
  /// a step-up token, returns headers including the step-up if the
  /// token is real (not the skip sentinel).
  static Map<String, String> withHeader(
    Map<String, String> base,
    String? token,
  ) {
    if (token == null || token == skipStepUp) return base;
    return {...base, 'X-Step-Up-Token': token};
  }
}
