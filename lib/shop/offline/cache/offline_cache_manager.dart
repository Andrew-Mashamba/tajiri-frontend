import 'package:flutter/foundation.dart';

import '../../../services/shop_database.dart';
import '../../data/repositories/shop_repository.dart';

/// Warms and reads the on-device catalog cache (SQLite via `ShopDatabase`).
class ShopOfflineCacheManager {
  ShopOfflineCacheManager({
    ShopDatabase? database,
    ShopRepository? repository,
  })  : _db = database ?? ShopDatabase.instance,
        _repo = repository ?? ShopRepository.instance;

  final ShopDatabase _db;
  final ShopRepository _repo;

  /// Best-effort prefetch for offline browsing (categories + first product page).
  Future<void> warmUpCache(int userId) async {
    try {
      await _db.database;

      final categories = await _repo.getCategories();
      if (categories.success) {
        await _db.upsertCategories(categories.categories);
      }

      final grid = await _repo.getProducts(
        page: 1,
        perPage: 20,
        currentUserId: userId,
      );
      if (grid.success && grid.products.isNotEmpty) {
        await _db.upsertProducts(grid.products);
      }
    } catch (e) {
      debugPrint('[ShopOfflineCacheManager] warmUpCache: $e');
    }
  }

  Future<List<Map<String, dynamic>>> getCachedProducts({
    int limit = 50,
  }) async {
    final rows = await _db.queryProducts(limit: limit);
    return rows.map((p) => p.toJson()).toList();
  }

  Future<void> invalidateProduct(String productId) async {
    final id = int.tryParse(productId);
    if (id == null) return;
    final db = await _db.database;
    await db.delete('shop_products', where: 'id = ?', whereArgs: [id]);
  }
}
