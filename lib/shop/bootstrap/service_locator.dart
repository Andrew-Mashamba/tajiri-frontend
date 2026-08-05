import 'dependency_injection.dart';
import '../data/repositories/shop_repository.dart';
import '../core/network/api_client.dart';

/// Ergonomic alias for [`DependencyInjection`] (`IMPLEMENTATION_PLAN` Phase 0).
class ServiceLocator {
  ServiceLocator._();

  static ShopApiClient get api => DependencyInjection.resolve<ShopApiClient>();

  static ShopRepository get shop => DependencyInjection.resolve<ShopRepository>();
}
