// Generated for docs/shop/shop.md — see data/repositories/order_repository.dart
import 'shop_repository.dart';

class OrderRepository {
  OrderRepository({ShopRepository? repo}) : _r = repo ?? ShopRepository.instance;
  final ShopRepository _r;
  ShopRepository get api => _r;
}
