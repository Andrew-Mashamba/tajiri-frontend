import '../config/api_config.dart';

/// SPKI SHA-256 certificate pins for TLS pinning.
///
/// Spec: docs/superpowers/specs/2026-03-30-persistent-auth-design.md §6
///
/// Pins are ONLY enforced for production (tajiri.zimasystems.com).
/// Disabled for UAT/localhost and via runtime kill switch.
class CertificatePins {
  CertificatePins._();

  /// Primary pin: current tajiri.zimasystems.com leaf certificate.
  /// Extract with:
  /// ```bash
  /// openssl s_client -connect tajiri.zimasystems.com:443 2>/dev/null | \
  ///   openssl x509 -pubkey -noout | \
  ///   openssl pkey -pubin -outform DER | \
  ///   openssl dgst -sha256 -binary | base64
  /// ```
  static const String primary = 'sha256/PLACEHOLDER_PRIMARY_PIN';

  /// Backup pin: CA intermediate (prevents lockout on cert rotation).
  static const String backup = 'sha256/PLACEHOLDER_BACKUP_PIN';

  /// Runtime kill switch — fetched from `GET /api/config/pinning` on app start.
  /// Defaults to true; set to false if remote config says so or request fails.
  static bool enabled = true;

  /// Pinning only active for production domain. Auto-disabled for UAT/localhost.
  static bool get shouldPin =>
      enabled && ApiConfig.baseUrl.contains('tajiri.zimasystems.com');

  /// All pins to validate against (any match = pass).
  static List<String> get pins => [primary, backup];
}
