import 'dart:convert';
import 'package:flutter/foundation.dart';
import 'package:hive_flutter/hive_flutter.dart';
import '../models/post_models.dart';

/// Hive-backed feed cache for instant feed rendering on app open.
/// Stores up to 100 posts per feed type as JSON strings.
class FeedCacheService {
  FeedCacheService._();
  static final FeedCacheService instance = FeedCacheService._();

  static const String _boxName = 'feed_cache';
  static const int _maxPostsPerFeed = 100;

  Box<String>? _box;

  Future<Box<String>> _getBox() async {
    _box ??= await Hive.openBox<String>(_boxName);
    return _box!;
  }

  String _feedKey(String feedType) => 'feed_$feedType';
  String _metaKey(String feedType) => 'meta_$feedType';

  /// Save posts for a feed type. Keeps at most [_maxPostsPerFeed] posts.
  Future<void> savePosts(String feedType, List<Post> posts) async {
    try {
      final box = await _getBox();
      final toStore = posts.length > _maxPostsPerFeed
          ? posts.sublist(0, _maxPostsPerFeed)
          : posts;
      final list = toStore.map((p) => p.toJson()).toList();
      await box.put(_feedKey(feedType), jsonEncode(list));
      await box.put(_metaKey(feedType), DateTime.now().toIso8601String());
      if (kDebugMode) {
        debugPrint('[FeedCache] Saved ${toStore.length} posts for $feedType');
      }
    } catch (e) {
      if (kDebugMode) debugPrint('[FeedCache] Save error: $e');
    }
  }

  /// Load cached posts for a feed type. Returns empty list if none cached.
  Future<List<Post>> getPosts(String feedType) async {
    try {
      final box = await _getBox();
      final json = box.get(_feedKey(feedType));
      if (json == null || json.isEmpty) return [];
      final list = jsonDecode(json) as List<dynamic>?;
      if (list == null) return [];
      final posts = <Post>[];
      for (final e in list) {
        if (e is Map<String, dynamic>) {
          try {
            posts.add(Post.fromJson(e));
          } catch (_) {}
        }
      }
      if (kDebugMode) {
        debugPrint('[FeedCache] Loaded ${posts.length} cached posts for $feedType');
      }
      return posts;
    } catch (e) {
      if (kDebugMode) debugPrint('[FeedCache] Load error: $e');
      return [];
    }
  }

  /// Get the last time this feed type was fetched from the API.
  Future<DateTime?> getLastFetchTime(String feedType) async {
    try {
      final box = await _getBox();
      final timestamp = box.get(_metaKey(feedType));
      if (timestamp == null) return null;
      return DateTime.tryParse(timestamp);
    } catch (_) {
      return null;
    }
  }

  /// Clear all feed caches (call on logout).
  Future<void> clear() async {
    try {
      final box = await _getBox();
      await box.clear();
      if (kDebugMode) debugPrint('[FeedCache] Cleared all feed caches');
    } catch (e) {
      if (kDebugMode) debugPrint('[FeedCache] Clear error: $e');
    }
  }
}
