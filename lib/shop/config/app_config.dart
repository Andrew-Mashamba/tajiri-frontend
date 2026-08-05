import '../../config/api_config.dart';
import 'environment.dart';
import 'feature_flags.dart';

/// Shop module configuration derived from core app wiring.
///
/// Single source for API/storage roots remains [`ApiConfig`] in `lib/config/api_config.dart`.
class ShopAppConfig {
  ShopAppConfig._();

  static String get apiBaseUrl => ApiConfig.baseUrl;

  static String get storageRoot => ApiConfig.storageUrl;

  static ShopEnvironment get environment =>
      resolveShopEnvironment(apiBaseUrl);

  /// Module semantic version for logs / future remote config.
  static const String moduleVersion = '0.1.0';

  static void bootstrap() {
    ShopFeatureFlags.ensureDefaults();
  }
}
