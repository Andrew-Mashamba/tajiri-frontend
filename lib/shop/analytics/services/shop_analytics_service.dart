import '../../../services/event_tracking_service.dart';

/// Shop-scoped analytics bridged to [`EventTrackingService`] + commerce metadata.
class ShopAnalyticsService {
  ShopAnalyticsService._();
  static final ShopAnalyticsService instance = ShopAnalyticsService._();

  Future<EventTrackingService> _ets() => EventTrackingService.getInstance();

  Future<void> trackProductViewed(int productId, {int? sellerId}) async {
    final ets = await _ets();
    ets.trackEvent(
      eventType: 'product_view',
      postId: productId,
      creatorId: sellerId,
      metadata: {'product_id': productId},
    );
  }

  Future<void> trackAddToCart(int productId, {int? sellerId}) async {
    final ets = await _ets();
    ets.trackEvent(
      eventType: 'add_to_cart',
      postId: productId,
      creatorId: sellerId,
      metadata: {'product_id': productId},
    );
  }

  Future<void> trackCheckoutStarted(double totalAmount, {String currency = 'TZS'}) async {
    final ets = await _ets();
    ets.trackEvent(
      eventType: 'purchase',
      durationMs: (totalAmount * 100).round().clamp(0, 1 << 31),
      metadata: {'phase': 'checkout_started', 'currency': currency},
    );
  }

  Future<void> trackPurchaseCompleted(int orderId, double amount) async {
    final ets = await _ets();
    ets.trackEvent(
      eventType: 'purchase',
      postId: orderId,
      durationMs: (amount * 100).round().clamp(0, 1 << 31),
      metadata: {'order_id': orderId},
    );
  }
}
