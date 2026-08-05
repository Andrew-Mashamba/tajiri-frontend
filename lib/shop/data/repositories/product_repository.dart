// Generated for docs/shop/shop.md — see data/repositories/product_repository.dart
import 'shop_repository.dart';

class ProductRepository {
  ProductRepository({ShopRepository? repo}) : _r = repo ?? ShopRepository.instance;
  final ShopRepository _r;
  ShopRepository get api => _r;
}
