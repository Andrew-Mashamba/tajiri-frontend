/// Runtime environment hint for shop module diagnostics and optional UI.
enum ShopEnvironment {
  production,
  development,
}

/// Resolved from API base URL (`lib/config/api_config.dart`).
ShopEnvironment resolveShopEnvironment(String apiBaseUrl) {
  final u = apiBaseUrl.toLowerCase();
  if (u.contains('127.0.0.1') ||
      u.contains('localhost') ||
      u.contains('10.0.2.2')) {
    return ShopEnvironment.development;
  }
  return ShopEnvironment.production;
}
