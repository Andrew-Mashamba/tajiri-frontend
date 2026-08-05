// Generated for docs/shop/shop.md — see offline/cache/product_cache.dart
import '../../../services/shop_database.dart';

class ProductCache {
  ProductCache({ShopDatabase? db}) : _db = db ?? ShopDatabase.instance;
  final ShopDatabase _db;
  Future<void> warm() async => _db.database;
}
