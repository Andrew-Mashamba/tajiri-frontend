import 'package:flutter/foundation.dart';
import 'feed_cache_service.dart';
import 'local_storage_service.dart';
import 'content_engine_service.dart';

/// Service to refresh feed cache in the background.
/// Currently runs on app startup if cache is stale (>15 min).
/// Can be extended with WorkManager for true background execution.
class BackgroundSyncService {
  BackgroundSyncService._();
  static final BackgroundSyncService instance = BackgroundSyncService._();

  static const Duration _staleThreshold = Duration(minutes: 15);
  bool _isSyncing = false;

  /// Initialize background sync. Call from main.dart after Hive init.
  /// Checks if feed cache is stale and refreshes in background if needed.
  Future<void> initialize() async {
    if (_isSyncing) return;

    try {
      final lastFetch = await FeedCacheService.instance.getLastFetchTime('posts');
      if (lastFetch == null) return; // No cache yet, will be populated on first load

      final elapsed = DateTime.now().difference(lastFetch);
      if (elapsed > _staleThreshold) {
        if (kDebugMode) {
          debugPrint('[BackgroundSync] Cache is ${elapsed.inMinutes}m old, refreshing...');
        }
        _refreshFeedInBackground();
      } else {
        if (kDebugMode) {
          debugPrint('[BackgroundSync] Cache is fresh (${elapsed.inMinutes}m old)');
        }
      }
    } catch (e) {
      if (kDebugMode) debugPrint('[BackgroundSync] Init error: $e');
    }
  }

  Future<void> _refreshFeedInBackground() async {
    if (_isSyncing) return;
    _isSyncing = true;

    try {
      final storage = await LocalStorageService.getInstance();
      final user = storage.getUser();
      final userId = user?.userId;
      if (userId == null) {
        _isSyncing = false;
        return;
      }

      final engineResult = await ContentEngineService.feed(
        feedType: 'for_you',
        userId: userId,
        page: 1,
      );

      final freshPosts = engineResult.items
          .where((item) => item.post != null)
          .map((item) => item.post!)
          .toList();

      if (freshPosts.isNotEmpty) {
        await FeedCacheService.instance.savePosts('posts', freshPosts);
        if (kDebugMode) {
          debugPrint('[BackgroundSync] Refreshed ${freshPosts.length} posts');
        }
      }
    } catch (e) {
      if (kDebugMode) debugPrint('[BackgroundSync] Refresh error: $e');
    } finally {
      _isSyncing = false;
    }
  }
}
