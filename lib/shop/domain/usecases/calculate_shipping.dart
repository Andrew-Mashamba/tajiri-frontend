import '../../../models/shop_models.dart';
import '../../data/repositories/shop_repository.dart';

/// Client-side delivery fee estimate (per-item fees); replace with API quote when backend ships.
class CalculateShipping {
  CalculateShipping({ShopRepository? repo}) : _repo = repo ?? ShopRepository.instance;

  final ShopRepository _repo;

  ShopRepository get repository => _repo;

  double estimateCartDelivery({
    required Cart cart,
    required Map<int, DeliveryMethod> methodsPerProduct,
  }) {
    var total = 0.0;
    for (final item in cart.items) {
      final m = methodsPerProduct[item.productId] ?? DeliveryMethod.pickup;
      if (m == DeliveryMethod.pickup || m == DeliveryMethod.digital) {
        continue;
      }
      total += item.product?.deliveryFee ?? 0;
    }
    return total;
  }
}
