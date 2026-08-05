import '../../../models/shop_models.dart';
import '../../data/repositories/shop_repository.dart';

/// Single-product checkout — delegates to [ShopRepository.createOrder].
class CreateOrder {
  CreateOrder({ShopRepository? repo}) : _repo = repo ?? ShopRepository.instance;

  final ShopRepository _repo;

  Future<OrderResult> execute({
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
}
