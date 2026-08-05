import 'dart:io';

import '../../../models/shop_models.dart';
import '../../../services/shop_service.dart';

/// Single façade over [`ShopService`] for `lib/shop` (`IMPLEMENTATION_PLAN` Phase 2).
///
/// Screens use this instead of constructing [`ShopService`] directly so calls can be
/// mocked, swapped, or augmented later without touching UI files.
class ShopRepository {
  ShopRepository._();
  static final ShopRepository instance = ShopRepository._();

  final ShopService _api = ShopService();

  Future<void> syncPendingMutations() => _api.syncPendingMutations();

  Future<CategoryListResult> getCategories({bool includeChildren = true}) =>
      _api.getCategories(includeChildren: includeChildren);

  Future<ProductListResult> getFeaturedProducts({int? currentUserId}) =>
      _api.getFeaturedProducts(currentUserId: currentUserId);

  Future<ProductListResult> getTrendingProducts({int? currentUserId}) =>
      _api.getTrendingProducts(currentUserId: currentUserId);

  Future<ProductListResult> getRecommendedProducts(int userId) =>
      _api.getRecommendedProducts(userId);

  Future<ProductListResult> getNearbyProducts({
    required double latitude,
    required double longitude,
    double radius = 10,
    int? currentUserId,
    int page = 1,
    int perPage = 20,
  }) =>
      _api.getNearbyProducts(
        latitude: latitude,
        longitude: longitude,
        radius: radius,
        currentUserId: currentUserId,
        page: page,
        perPage: perPage,
      );

  Future<ProductListResult> getProducts({
    int page = 1,
    int perPage = 20,
    int? categoryId,
    String? search,
    String? sortBy,
    double? minPrice,
    double? maxPrice,
    ProductCondition? condition,
    ProductType? type,
    int? sellerId,
    int? currentUserId,
  }) =>
      _api.getProducts(
        page: page,
        perPage: perPage,
        categoryId: categoryId,
        search: search,
        sortBy: sortBy,
        minPrice: minPrice,
        maxPrice: maxPrice,
        condition: condition,
        type: type,
        sellerId: sellerId,
        currentUserId: currentUserId,
      );

  Future<ProductListResult> getFlashDeals({int page = 1, int perPage = 20}) =>
      _api.getFlashDeals(page: page, perPage: perPage);

  Future<ProductResult> getProduct(int productId, {int? currentUserId}) =>
      _api.getProduct(productId, currentUserId: currentUserId);

  Future<void> recordProductView(int productId, {int? userId, int? originPostId}) =>
      _api.recordProductView(productId, userId: userId, originPostId: originPostId);

  Future<FavoriteResult> toggleFavorite(int userId, int productId, {int? originPostId}) =>
      _api.toggleFavorite(userId, productId, originPostId: originPostId);

  Future<CartResult> getCart(int userId) => _api.getCart(userId);

  Future<CartResult> addToCart(int userId, int productId, {int quantity = 1}) =>
      _api.addToCart(userId, productId, quantity: quantity);

  Future<CartResult> updateCartItem(int userId, int productId, int quantity) =>
      _api.updateCartItem(userId, productId, quantity);

  Future<CartResult> removeFromCart(int userId, int productId) =>
      _api.removeFromCart(userId, productId);

  Future<bool> clearCart(int userId) => _api.clearCart(userId);

  Future<PromoCodeResult> validatePromoCode({
    required String code,
    required int userId,
  }) =>
      _api.validatePromoCode(code: code, userId: userId);

  Future<OrderResult> createOrder({
    required int buyerId,
    required int productId,
    required int quantity,
    required DeliveryMethod deliveryMethod,
    String? deliveryAddress,
    String? deliveryNotes,
    String? pin,
    String paymentMethod = 'wallet',
    String? promoCode,
    int? originPostId,
    int? affiliateUserId,
  }) =>
      _api.createOrder(
        buyerId: buyerId,
        productId: productId,
        quantity: quantity,
        deliveryMethod: deliveryMethod,
        deliveryAddress: deliveryAddress,
        deliveryNotes: deliveryNotes,
        pin: pin,
        paymentMethod: paymentMethod,
        promoCode: promoCode,
        originPostId: originPostId,
        affiliateUserId: affiliateUserId,
      );

  Future<OrderListResult> checkout({
    required int buyerId,
    required List<CheckoutItem> items,
    String? pin,
    String paymentMethod = 'wallet',
    String? promoCode,
  }) =>
      _api.checkout(
        buyerId: buyerId,
        items: items,
        pin: pin,
        paymentMethod: paymentMethod,
        promoCode: promoCode,
      );

  Future<OrderResult> getOrder(int orderId, {required int userId}) =>
      _api.getOrder(orderId, userId: userId);

  Future<OrderListResult> getSellerOrders(
    int sellerId, {
    OrderStatus? status,
    int page = 1,
    int perPage = 20,
  }) =>
      _api.getSellerOrders(sellerId, status: status, page: page, perPage: perPage);

  Future<OrderResult> updateOrderStatus(
    int orderId, {
    required int sellerId,
    required OrderStatus status,
    String? trackingNumber,
    String? note,
    DateTime? estimatedDelivery,
  }) =>
      _api.updateOrderStatus(
        orderId,
        sellerId: sellerId,
        status: status,
        trackingNumber: trackingNumber,
        note: note,
        estimatedDelivery: estimatedDelivery,
      );

  Future<OrderResult> cancelOrder(
    int orderId, {
    required int userId,
    String? reason,
  }) =>
      _api.cancelOrder(orderId, userId: userId, reason: reason);

  Future<OrderResult> confirmReceived(int orderId, {required int buyerId}) =>
      _api.confirmReceived(orderId, buyerId: buyerId);

  Future<OrderResult> requestReturn(
    int orderId, {
    required int buyerId,
    required String reason,
    List<String>? imageUrls,
  }) =>
      _api.requestReturn(
        orderId,
        userId: buyerId,
        reason: reason,
        imageUrls: imageUrls,
      );

  Future<ProductListResult> getSellerProducts(
    int sellerId, {
    ProductStatus? status,
    int page = 1,
    int perPage = 20,
    int? currentUserId,
  }) =>
      _api.getSellerProducts(
        sellerId,
        status: status,
        page: page,
        perPage: perPage,
        currentUserId: currentUserId,
      );

  Future<SellerStatsResult> getSellerStats(int sellerId) =>
      _api.getSellerStats(sellerId);

  Future<ProductResult> createProduct({
    required int sellerId,
    required String title,
    String? description,
    required ProductType type,
    required double price,
    double? compareAtPrice,
    String currency = 'TZS',
    int stockQuantity = 0,
    int? categoryId,
    List<String>? tags,
    ProductCondition condition = ProductCondition.brandNew,
    String? locationName,
    double? latitude,
    double? longitude,
    bool allowPickup = true,
    bool allowDelivery = false,
    bool allowShipping = false,
    double? deliveryFee,
    String? deliveryNotes,
    String? pickupAddress,
    String? downloadUrl,
    int? downloadLimit,
    int? durationMinutes,
    String? serviceLocation,
    List<File>? images,
  }) =>
      _api.createProduct(
        sellerId: sellerId,
        title: title,
        description: description,
        type: type,
        price: price,
        compareAtPrice: compareAtPrice,
        currency: currency,
        stockQuantity: stockQuantity,
        categoryId: categoryId,
        tags: tags,
        condition: condition,
        locationName: locationName,
        latitude: latitude,
        longitude: longitude,
        allowPickup: allowPickup,
        allowDelivery: allowDelivery,
        allowShipping: allowShipping,
        deliveryFee: deliveryFee,
        deliveryNotes: deliveryNotes,
        pickupAddress: pickupAddress,
        downloadUrl: downloadUrl,
        downloadLimit: downloadLimit,
        durationMinutes: durationMinutes,
        serviceLocation: serviceLocation,
        images: images,
      );

  Future<ProductResult> updateProduct({
    required int productId,
    required int sellerId,
    String? title,
    String? description,
    double? price,
    double? compareAtPrice,
    int? stockQuantity,
    ProductStatus? status,
    int? categoryId,
    List<String>? tags,
    ProductCondition? condition,
    String? locationName,
    double? latitude,
    double? longitude,
    bool? allowPickup,
    bool? allowDelivery,
    bool? allowShipping,
    double? deliveryFee,
    String? deliveryNotes,
    String? pickupAddress,
    String? downloadUrl,
    int? downloadLimit,
    int? durationMinutes,
    String? serviceLocation,
    List<File>? newImages,
    List<String>? removeImages,
  }) =>
      _api.updateProduct(
        productId: productId,
        sellerId: sellerId,
        title: title,
        description: description,
        price: price,
        compareAtPrice: compareAtPrice,
        stockQuantity: stockQuantity,
        status: status,
        categoryId: categoryId,
        tags: tags,
        condition: condition,
        locationName: locationName,
        latitude: latitude,
        longitude: longitude,
        allowPickup: allowPickup,
        allowDelivery: allowDelivery,
        allowShipping: allowShipping,
        deliveryFee: deliveryFee,
        deliveryNotes: deliveryNotes,
        pickupAddress: pickupAddress,
        downloadUrl: downloadUrl,
        downloadLimit: downloadLimit,
        durationMinutes: durationMinutes,
        serviceLocation: serviceLocation,
        newImages: newImages,
        removeImages: removeImages,
      );

  Future<bool> deleteProduct(int productId, int sellerId) =>
      _api.deleteProduct(productId, sellerId);

  Future<ReviewListResult> getProductReviews(
    int productId, {
    int page = 1,
    int perPage = 20,
    int? rating,
    int? currentUserId,
  }) =>
      _api.getProductReviews(
        productId,
        page: page,
        perPage: perPage,
        rating: rating,
        currentUserId: currentUserId,
      );

  Future<ReviewResult> createReview({
    required int productId,
    required int userId,
    required int rating,
    String? comment,
    List<File>? images,
  }) =>
      _api.createReview(
        productId: productId,
        userId: userId,
        rating: rating,
        comment: comment,
        images: images,
      );

  Future<bool> markReviewHelpful(int reviewId, int userId) =>
      _api.markReviewHelpful(reviewId, userId);
}
