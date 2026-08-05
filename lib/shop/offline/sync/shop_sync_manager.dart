import '../../data/repositories/shop_repository.dart';

/// Flushes outbox mutations and coordinates with the remote API.
class ShopSyncManager {
  ShopSyncManager({ShopRepository? repository})
      : _repo = repository ?? ShopRepository.instance;

  final ShopRepository _repo;

  /// Runs [`ShopService.syncPendingMutations`] via the repository façade.
  Future<void> flushPendingMutations() => _repo.syncPendingMutations();

  /// Full sync hook — extend when orders/cart reconciliation is added server-side.
  Future<void> synchronizeNow() async {
    await flushPendingMutations();
  }
}
