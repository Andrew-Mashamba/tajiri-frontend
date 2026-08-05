import 'package:flutter/foundation.dart';

import '../../services/local_storage_service.dart';
import '../config/app_config.dart';
import '../config/feature_flags.dart';
import '../offline/cache/offline_cache_manager.dart';
import '../offline/persistence/local_database.dart';
import 'dependency_injection.dart';

/// Cold-start hook for marketplace infrastructure (`docs/shop/IMPLEMENTATION_PLAN.md` Phase 0).
class AppInitializer {
  AppInitializer._();

  static bool _initialized = false;

  static Future<void> initialize() async {
    if (_initialized) return;
    _initialized = true;

    ShopAppConfig.bootstrap();
    DependencyInjection.initialize();

    final db = ShopLocalDatabase();
    await db.initialize();

    if (ShopFeatureFlags.warmOfflineCacheAfterInit) {
      try {
        final storage = await LocalStorageService.getInstance();
        final uid = storage.getUser()?.userId;
        if (uid != null) {
          await ShopOfflineCacheManager().warmUpCache(uid);
        }
      } catch (e) {
        if (kDebugMode) debugPrint('[Shop] warmOfflineCacheAfterInit: $e');
      }
    }

    if (kDebugMode) {
      debugPrint(
        '[Shop] ready v${ShopAppConfig.moduleVersion} env=${ShopAppConfig.environment}',
      );
    }
  }
}
