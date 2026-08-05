/// TAJIRI marketplace (shop) — buyer + seller surfaces wired from `main.dart`.
///
/// Route namespace: `/shop`, `/shop/cart`, `/shop/product`, etc. (see [ShopRoutes]).
library;

export 'bootstrap/app_initializer.dart';
export 'bootstrap/dependency_injection.dart';
export 'bootstrap/module_registry.dart';
export 'bootstrap/service_locator.dart';
export 'config/app_config.dart';
export 'config/feature_flags.dart';
export 'config/shop_constants.dart';
export 'data/data.dart';
export 'routes/shop_routes.dart';
export 'analytics/services/shop_analytics_service.dart';
export 'integrations/shop_extended_api.dart';
