/// REST segments under [`ApiConfig.baseUrl`] (`…/api/...`).
///
/// Mirrors `ShopService` paths (`/shop/...`).
class ShopApiPaths {
  ShopApiPaths._();

  static const String prefix = '/shop';

  static const String products = '$prefix/products';
  static const String productsFeatured = '$prefix/products/featured';
  static const String productsTrending = '$prefix/products/trending';
  static const String productsRecommended = '$prefix/products/recommended';
  static const String productsNearby = '$prefix/products/nearby';

  static const String categories = '$prefix/categories';
  static const String flashDeals = '$prefix/flash-deals';
  static const String favorites = '$prefix/favorites';

  static const String cart = '$prefix/cart';
  static const String cartItems = '$prefix/cart/items';

  static const String checkout = '$prefix/checkout';
  static const String orders = '$prefix/orders';
  static const String ordersBuyer = '$prefix/orders/buyer';
  static const String ordersSeller = '$prefix/orders/seller';

  static String product(int id) => '$prefix/products/$id';
  static String order(int id) => '$prefix/orders/$id';

  static const String promoValidate = '$prefix/promo/validate';

  /// Seller ads + optional Laravel extensions ([`ShopExtendedApi`] — same `/shop` prefix as [`ShopService`]).
  static const String adsCampaigns = '$prefix/ads/campaigns';

  /// Batch commerce analytics (`docs/shop/shop_backend_api.md`).
  static const String analyticsEventsBatch = '$prefix/analytics/events';

  /// Social commerce — boost a feed post (`POST` body includes `budget_minor_units`).
  static String socialCommerceBoostPost(int postId) =>
      '$prefix/social-commerce/posts/$postId/boost';

  /// Create / list social posts with tagged products.
  static const String socialCommercePosts = '$prefix/social-commerce/posts';
}
