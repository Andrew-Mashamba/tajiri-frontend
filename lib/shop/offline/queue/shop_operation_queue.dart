import '../../../services/shop_database.dart';

/// Facade over [`ShopDatabase`] pending mutation queue (`IMPLEMENTATION_PLAN` Phase 1).
class ShopOperationQueue {
  ShopOperationQueue({ShopDatabase? database})
      : _db = database ?? ShopDatabase.instance;

  final ShopDatabase _db;

  Future<int> pendingCount() async {
    final rows = await _db.getPendingMutations();
    return rows.length;
  }

  Future<List<Map<String, dynamic>>> peekPending() => _db.getPendingMutations();
}
