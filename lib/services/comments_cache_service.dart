// lib/services/comments_cache_service.dart
//
// Layered cache for per-post comments threads. Mirrors the canonical
// pattern from docs/ENGINEERING_PLAYBOOK.md → "Local-first list pages
// — layered cache & SWR (project-wide)". Used by PostDetailScreen.
//
//   • In-memory `Map<int, List<Comment>>` keyed by postId — uncapped
//     per post (full scroll-back state survives nav pop/repush).
//   • Hive `Box<String>` capped at 100 newest comments per post on
//     disk — bounds storage growth across many viewed posts.
//
// Pagination uses the network exclusively; the cache only persists
// the page-1 snapshot for instant first paint on next visit. Mutation
// (add/delete/like) writes back so the next hydrate reflects state.
//
// Cleared by AuthService._performLocalLogout() on sign-out.

import 'dart:convert';

import 'package:flutter/foundation.dart';
import 'package:hive_flutter/hive_flutter.dart';

import '../models/post_models.dart';

class CommentsCacheService {
  CommentsCacheService._();
  static final CommentsCacheService instance = CommentsCacheService._();

  static const String _boxName = 'comments_cache';
  static const int _maxPerPost = 100;

  Box<String>? _box;
  final Map<int, List<Comment>> _hot = {};

  Future<Box<String>> _getBox() async {
    _box ??= await Hive.openBox<String>(_boxName);
    return _box!;
  }

  String _key(int postId) => 'post_$postId';

  /// Sync hot read — null on miss; caller falls back to [getCached].
  List<Comment>? getSync(int postId) => _hot[postId];

  /// Async: hot first, then disk; hydrates hot on first disk hit.
  Future<List<Comment>?> getCached(int postId) async {
    final hot = _hot[postId];
    if (hot != null) return hot;
    try {
      final box = await _getBox();
      final raw = box.get(_key(postId));
      if (raw == null) return null;
      final list = (jsonDecode(raw) as List)
          .whereType<Map<String, dynamic>>()
          .map(Comment.fromJson)
          .toList();
      _hot[postId] = list;
      return list;
    } catch (e) {
      if (kDebugMode) debugPrint('[CommentsCache] getCached failed: $e');
      return null;
    }
  }

  /// Persist comments for a post. In-memory uncapped; disk capped.
  Future<void> save(int postId, List<Comment> comments) async {
    _hot[postId] = comments;
    final capped = comments.length > _maxPerPost
        ? comments.sublist(0, _maxPerPost)
        : comments;
    try {
      final box = await _getBox();
      await box.put(
        _key(postId),
        jsonEncode(capped.map((c) => c.toJson()).toList()),
      );
    } catch (e) {
      if (kDebugMode) debugPrint('[CommentsCache] save failed: $e');
    }
  }

  Future<void> invalidate(int postId) async {
    _hot.remove(postId);
    try {
      final box = await _getBox();
      await box.delete(_key(postId));
    } catch (_) {}
  }

  Future<void> clear() async {
    _hot.clear();
    try {
      final box = await _getBox();
      await box.clear();
    } catch (_) {}
  }
}
