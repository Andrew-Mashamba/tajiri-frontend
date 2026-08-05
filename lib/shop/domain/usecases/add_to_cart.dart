import '../../../models/shop_models.dart';
import '../../data/repositories/shop_repository.dart';

/// Add line item — delegates to [ShopRepository].
class AddToCart {
  AddToCart({ShopRepository? repo}) : _repo = repo ?? ShopRepository.instance;

  final ShopRepository _repo;

  Future<CartResult> execute({
    required int userId,
    required int productId,
    int quantity = 1,
  }) =>
      _repo.addToCart(userId, productId, quantity: quantity);
}
