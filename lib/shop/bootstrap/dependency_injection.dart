import '../../services/authenticated_dio.dart';
import '../core/network/api_client.dart';
import '../core/network/interceptors.dart';
import '../data/repositories/shop_repository.dart';

/// Manual service registry for `lib/shop` (no DI package).
class DependencyInjection {
  DependencyInjection._();

  static final Map<Type, Object> _registry = <Type, Object>{};

  static void register<T extends Object>(T instance) {
    _registry[T] = instance;
  }

  static T resolve<T extends Object>() => _registry[T]! as T;

  static bool isRegistered<T>() => _registry.containsKey(T);

  /// Idempotent — safe to call from `AppInitializer` once per process.
  static void initialize() {
    ShopNetworkLogging.attachIfDebug(AuthenticatedDio.instance);

    if (!isRegistered<ShopApiClient>()) {
      register<ShopApiClient>(ShopApiClient());
    }
    if (!isRegistered<ShopRepository>()) {
      register<ShopRepository>(ShopRepository.instance);
    }
  }
}
