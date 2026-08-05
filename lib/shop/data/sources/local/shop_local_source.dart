// Generated for docs/shop/shop.md — see data/sources/local/shop_local_source.dart
import '../../../offline/persistence/local_database.dart';

class ShopLocalSource {
  ShopLocalSource({ShopLocalDatabase? db}) : _db = db ?? ShopLocalDatabase();
  final ShopLocalDatabase _db;
  ShopLocalDatabase get database => _db;
}
