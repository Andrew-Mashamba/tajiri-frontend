import 'package:flutter/foundation.dart';
import 'package:flutter/services.dart';
import 'package:local_auth/local_auth.dart';

/// Biometric authentication wrapper for sensitive actions.
///
/// Spec: docs/superpowers/specs/2026-03-30-persistent-auth-design.md §5
///
/// Fallback chain: biometrics → device PIN/pattern → skip (no lock screen).
class BiometricService {
  BiometricService._();

  static final _auth = LocalAuthentication();

  /// Authenticate the user via biometrics or device credentials.
  ///
  /// Returns `true` if:
  /// - Biometric/device PIN authentication succeeded, OR
  /// - Device has no biometric hardware AND no lock screen (skip gate)
  ///
  /// Returns `false` if:
  /// - User cancelled authentication
  /// - Authentication failed
  static Future<bool> authenticate({
    String reason = 'Thibitisha ni wewe kwa alama ya kidole au uso',
  }) async {
    try {
      final canCheck = await _auth.canCheckBiometrics;
      final isDeviceSupported = await _auth.isDeviceSupported();

      if (!canCheck && !isDeviceSupported) {
        // No biometric hardware AND no device lock screen — don't block user
        return true;
      }

      return await _auth.authenticate(
        localizedReason: reason,
        options: const AuthenticationOptions(
          biometricOnly: false,
          useErrorDialogs: true,
          stickyAuth: true,
        ),
      );
    } on PlatformException catch (e) {
      debugPrint('BiometricService: $e');
      if (e.code == 'NotAvailable' || e.code == 'NotEnrolled') {
        return true;
      }
      return false;
    } catch (e) {
      debugPrint('BiometricService: unexpected error: $e');
      return false;
    }
  }
}
