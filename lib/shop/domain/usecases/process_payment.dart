import '../../../models/shop_models.dart';
import '../../../services/shop_service.dart' show CheckoutItem;
import '../../data/repositories/shop_repository.dart';

/// Tajiri Pay wallet flows — delegates to [ShopRepository] checkout APIs.
class ProcessPayment {
  ProcessPayment({ShopRepository? repo}) : _repo = repo ?? ShopRepository.instance;

  final ShopRepository _repo;

  Future<OrderResult> paySingleProduct({
    required int buyerId,
    required int productId,
    required int quantity,
    required DeliveryMethod deliveryMethod,
    String? deliveryAddress,
    String? deliveryNotes,
    String? pin,
    String paymentMethod = 'wallet',
    String? promoCode,
  }) =>
      _repo.createOrder(
        buyerId: buyerId,
        productId: productId,
        quantity: quantity,
        deliveryMethod: deliveryMethod,
        deliveryAddress: deliveryAddress,
        deliveryNotes: deliveryNotes,
        pin: pin,
        paymentMethod: paymentMethod,
        promoCode: promoCode,
      );

  Future<OrderListResult> payCart({
    required int buyerId,
    required List<CheckoutItem> items,
    String? pin,
    String paymentMethod = 'wallet',
    String? promoCode,
  }) =>
      _repo.checkout(
        buyerId: buyerId,
        items: items,
        pin: pin,
        paymentMethod: paymentMethod,
        promoCode: promoCode,
      );
}
