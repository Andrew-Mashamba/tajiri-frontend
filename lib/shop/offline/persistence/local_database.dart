import '../../../services/shop_database.dart';

/// Facade around the production SQLite catalog already used by `ShopService`
/// (`lib/services/shop_database.dart`).
class ShopLocalDatabase {
  ShopLocalDatabase();

  final ShopDatabase _db = ShopDatabase.instance;

  /// Opens the SQLite file and runs `onCreate` if needed.
  Future<void> initialize() async {
    await _db.database;
  }

  Future<void> close() async => _db.close();

  ShopDatabase get raw => _db;
}
