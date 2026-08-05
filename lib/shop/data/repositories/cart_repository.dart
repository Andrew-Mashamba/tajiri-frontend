// Generated for docs/shop/shop.md — see data/repositories/cart_repository.dart
import 'shop_repository.dart';

class CartRepository {
  CartRepository({ShopRepository? repo}) : _r = repo ?? ShopRepository.instance;
  final ShopRepository _r;
  ShopRepository get api => _r;
}
