import 'package:flutter/foundation.dart';

/// Feature toggles for the shop module (`docs/shop/IMPLEMENTATION_PLAN.md`).
///
/// Unsafe / unfinished surfaces stay **off** in release builds.
class ShopFeatureFlags {
  ShopFeatureFlags._();

  /// When true, prefetch categories + first product page during shop bootstrap (logged-in user).
  /// Keep **false** by default — `ShopScreen` already loads fresh data when opened.
  static bool warmOfflineCacheAfterInit = false;

  /// Marketplace extensions — backend routes live (`/api/shop/...`).
  static bool enableShopAdsMvp = true;
  static bool enableSocialCommerce = true;

  /// Heavier surfaces — keep off in release until wired end-to-end.
  static bool enableShopAiFeatures = false;
  static bool enableLiveShopping = false;

  static void ensureDefaults() {
    if (!kDebugMode) {
      warmOfflineCacheAfterInit = false;
      enableShopAiFeatures = false;
      enableLiveShopping = false;
    }
  }
}
