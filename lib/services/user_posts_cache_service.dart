// lib/services/user_posts_cache_service.dart
//
// Layered cache for a user's posts grid (Profile → My Posts and the
// visitor-view of someone else's Posts tab).
//
//   • In-memory (Map<int, List<Post>>) — hot reads (~0ms) for the
//     same session. Survives across navigator pop/push, so re-opening
//     the Posts page after browsing elsewhere is instant.
//
//   • Hive-backed disk (Box<String>) — survives cold starts. On app
//     boot the most-recent grid renders instantly while a fresh fetch
//     happens in background. Capped at [_maxPostsPerUser] to bound
//     storage growth.
//
// Usage from ProfilePostsPage:
//   final cached = UserPostsCacheService.instance.getSync(userId);
//   if (cached != null) render(cached);
//   else (await UserPostsCacheService.instance.getCached(userId)) ...
//   final fresh = await postService.getPosts(...);
//   await UserPostsCacheService.instance.save(userId, fresh.posts);
//
// Cleared by AuthService._performLocalLogout() on sign-out.

import 'dart:convert';

import 'package:flutter/foundation.dart';
import 'package:hive_flutter/hive_flutter.dart';

import '../models/post_models.dart';

class UserPostsCacheService {
  UserPostsCacheService._();
  static final UserPostsCacheService instance = UserPostsCacheService._();

  static const String _boxName = 'user_posts_cache';
  static const int _maxPostsPerUser = 100;

  Box<String>? _box;
  final Map<int, List<Post>> _hot = {};

  Future<Box<String>> _getBox() async {
    _box ??= await Hive.openBox<String>(_boxName);
    return _box!;
  }

  String _key(int userId) => 'posts_$userId';

  /// Synchronous hot-cache read — returns null if not yet loaded in
  /// this session (caller falls back to [getCached] for disk read).
  List<Post>? getSync(int userId) => _hot[userId];

  /// Async read: hot cache first, then disk. Hydrates the hot cache
  /// from disk on first hit so subsequent calls return synchronously.
  Future<List<Post>?> getCached(int userId) async {
    final hot = _hot[userId];
    if (hot != null) return hot;
    try {
      final box = await _getBox();
      final raw = box.get(_key(userId));
      if (raw == null) return null;
      final list = jsonDecode(raw) as List;
      final posts = list
          .whereType<Map<String, dynamic>>()
          .map(Post.fromJson)
          .toList();
      _hot[userId] = posts;
      return posts;
    } catch (e) {
      if (kDebugMode) debugPrint('[UserPostsCache] getCached failed: $e');
      return null;
    }
  }

  /// Persist the latest batch of posts. In-memory holds the full
  /// list (uncapped — the user's scroll-back state survives the
  /// session); disk caps at [_maxPostsPerUser] to bound storage.
  Future<void> save(int userId, List<Post> posts) async {
    _hot[userId] = posts;
    final capped = posts.length > _maxPostsPerUser
        ? posts.sublist(0, _maxPostsPerUser)
        : posts;
    try {
      final box = await _getBox();
      final json = jsonEncode(capped.map((p) => p.toJson()).toList());
      await box.put(_key(userId), json);
    } catch (e) {
      if (kDebugMode) debugPrint('[UserPostsCache] save failed: $e');
    }
  }

  /// Drop a single user's cache (e.g. after they delete a post and we
  /// want the next paint to pull canonical state from the server).
  Future<void> invalidate(int userId) async {
    _hot.remove(userId);
    try {
      final box = await _getBox();
      await box.delete(_key(userId));
    } catch (_) {}
  }

  /// Wipe everything — called by AuthService on logout.
  Future<void> clear() async {
    _hot.clear();
    try {
      final box = await _getBox();
      await box.clear();
    } catch (_) {}
  }
}
