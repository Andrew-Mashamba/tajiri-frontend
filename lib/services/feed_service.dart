import 'dart:convert';
import 'package:flutter/foundation.dart';
import 'package:http/http.dart' as http;
import '../models/post_models.dart';
import '../config/api_config.dart';
import 'post_service.dart';
import 'local_storage_service.dart';

String get _baseUrl => ApiConfig.baseUrl;

/// Parse data map into posts list and meta; never throws.
(List<Post>, PaginationMeta) _parseFeedData(Map<String, dynamic> data) {
  final rawList = data['data'] is List ? data['data'] as List : <dynamic>[];
  final posts = <Post>[];
  for (var i = 0; i < rawList.length; i++) {
    try {
      final item = rawList[i];
      if (item is Map<String, dynamic>) {
        posts.add(Post.fromJson(item));
      }
    } catch (e) {
      debugPrint('[FeedService] Skipping post index $i (parse error: $e)');
    }
  }
  PaginationMeta meta;
  try {
    final metaJson = data['meta'];
    meta = metaJson is Map<String, dynamic>
        ? PaginationMeta.fromJson(metaJson)
        : PaginationMeta.fromJson({});
  } catch (_) {
    meta = PaginationMeta.fromJson({});
  }
  return (posts, meta);
}

class FeedService {
  final PostService _postService = PostService();

  /// Retrieve auth headers for feed requests that require authentication.
  static Future<Map<String, String>> _authHeaders() async {
    try {
      final storage = await LocalStorageService.getInstance();
      final token = storage.getAuthToken();
      if (token != null && token.isNotEmpty) {
        return ApiConfig.authHeaders(token);
      }
    } catch (_) {}
    return ApiConfig.headers;
  }

  /// Get feed by type (posts, friends, following, discover, shorts, trending, live)
  /// 'posts' = all posts from everyone. 'friends' = posts from people you follow.
  Future<PostListResult> getFeed({
    required int userId,
    int page = 1,
    int perPage = 20,
    String feedType = 'posts',
  }) async {
    switch (feedType) {
      case 'posts':
        return getPostsFeed(userId: userId, page: page, perPage: perPage);
      case 'for_you':
        return getForYouFeed(userId: userId, page: page, perPage: perPage);
      case 'friends':
        return getFriendsFeed(userId: userId, page: page, perPage: perPage);
      case 'following':
        return getFollowingFeed(userId: userId, page: page, perPage: perPage);
      case 'discover':
        return getDiscoverFeed(userId: userId, page: page, perPage: perPage);
      case 'shorts':
        return getShortsFeed(userId: userId, page: page, perPage: perPage);
      case 'trending':
        return getTrendingFeed(userId: userId, page: page, perPage: perPage);
      default:
        return getPostsFeed(userId: userId, page: page, perPage: perPage);
    }
  }

  /// Get all posts from everyone (global timeline for Posts tab).
  /// GET /api/posts?user_id=... (no profile_user_id → backend returns global timeline).
  Future<PostListResult> getPostsFeed({
    required int userId,
    int page = 1,
    int perPage = 20,
  }) async {
    return _postService.getPosts(userId: userId, page: page, perPage: perPage);
  }

  /// Get posts for a specific user's profile (their timeline).
  /// GET /api/posts?user_id=currentUserId&profile_user_id=profileUserId
  Future<PostListResult> getProfilePostsFeed({
    required int currentUserId,
    required int profileUserId,
    int page = 1,
    int perPage = 20,
  }) async {
    return _postService.getPosts(
      userId: currentUserId,
      profileUserId: profileUserId,
      page: page,
      perPage: perPage,
    );
  }

  /// Get shorts feed (vertical short-form video posts).
  /// GET /api/posts/feed/shorts — returns posts with is_short_video / video media.
  Future<PostListResult> getShortsFeed({
    required int userId,
    int page = 1,
    int perPage = 20,
  }) async {
    try {
      final headers = await _authHeaders();
      final response = await http.get(
        Uri.parse(
          '$_baseUrl/posts/feed/shorts?user_id=$userId&page=$page&per_page=$perPage',
        ),
        headers: headers,
      );

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        if (data['success'] == true && data is Map<String, dynamic>) {
          final (posts, meta) = _parseFeedData(data);
          return PostListResult(
            success: true,
            posts: posts,
            meta: meta,
            message: data['message']?.toString(),
          );
        }
      }
      return PostListResult(
        success: false,
        message: 'Failed to load shorts feed',
      );
    } catch (e) {
      return PostListResult(success: false, message: 'Error: $e');
    }
  }

  /// Get following feed: posts from people the user follows (Marafiki tab).
  /// GET /api/posts/feed/following — chronological order (newest first).
  Future<PostListResult> getFollowingFeed({
    required int userId,
    int page = 1,
    int perPage = 20,
  }) async {
    try {
      final headers = await _authHeaders();
      final response = await http.get(
        Uri.parse(
          '$_baseUrl/posts/feed/following?user_id=$userId&page=$page&per_page=$perPage',
        ),
        headers: headers,
      );

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        if (data['success'] == true && data is Map<String, dynamic>) {
          final (posts, meta) = _parseFeedData(data);
          posts.sort((a, b) => b.createdAt.compareTo(a.createdAt));
          return PostListResult(
            success: true,
            posts: posts,
            meta: meta,
            message: data['message']?.toString(),
          );
        }
      }
      return PostListResult(
        success: false,
        message: 'Failed to load following feed',
      );
    } catch (e) {
      return PostListResult(success: false, message: 'Error: $e');
    }
  }

  /// Get algorithm-curated For You feed (personalized, engagement-based ranking).
  /// GET /api/posts/feed/for-you
  Future<PostListResult> getForYouFeed({
    required int userId,
    int page = 1,
    int perPage = 20,
  }) async {
    try {
      final headers = await _authHeaders();
      final response = await http.get(
        Uri.parse(
          '$_baseUrl/posts/feed/for-you?user_id=$userId&page=$page&per_page=$perPage',
        ),
        headers: headers,
      );

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        if (data['success'] == true && data is Map<String, dynamic>) {
          final (posts, meta) = _parseFeedData(data);
          return PostListResult(
            success: true,
            posts: posts,
            meta: meta,
            message: data['message']?.toString(),
          );
        }
      }
      return PostListResult(
        success: false,
        message: 'Failed to load For You feed',
      );
    } catch (e) {
      return PostListResult(success: false, message: 'Error: $e');
    }
  }

  /// Get ML-personalized feed using Bearer token auth.
  /// Falls back to [getForYouFeed] on any failure (no token, non-200, parse error).
  /// GET /api/feed/personalized
  Future<PostListResult> getPersonalizedFeed({
    required int userId,
    int page = 1,
    int perPage = 20,
  }) async {
    try {
      final storage = await LocalStorageService.getInstance();
      final token = storage.getAuthToken();
      if (token == null || token.isEmpty) {
        debugPrint('[FeedService] No auth token — falling back to For You feed');
        return getForYouFeed(userId: userId, page: page, perPage: perPage);
      }

      final response = await http.get(
        Uri.parse(
          '$_baseUrl/feed/personalized?page=$page&per_page=$perPage',
        ),
        headers: ApiConfig.authHeaders(token),
      );

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        if (data is Map<String, dynamic> && data['success'] == true) {
          final (posts, meta) = _parseFeedData(data);
          return PostListResult(
            success: true,
            posts: posts,
            meta: meta,
            message: data['message']?.toString(),
          );
        }
      }
      debugPrint(
        '[FeedService] Personalized feed returned ${response.statusCode} — falling back to For You feed',
      );
    } catch (e) {
      debugPrint('[FeedService] Personalized feed error: $e — falling back to For You feed');
    }
    return getForYouFeed(userId: userId, page: page, perPage: perPage);
  }

  /// Get personalized feed for a user (all posts)
  Future<PostListResult> getAllFeed({
    required int userId,
    int page = 1,
    int perPage = 20,
  }) async {
    try {
      final headers = await _authHeaders();
      final response = await http.get(
        Uri.parse('$_baseUrl/feed?user_id=$userId&page=$page&per_page=$perPage'),
        headers: headers,
      );

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        if (data['success'] == true && data is Map<String, dynamic>) {
          final (posts, meta) = _parseFeedData(data);
          return PostListResult(
            success: true,
            posts: posts,
            meta: meta,
          );
        }
      }
      return PostListResult(success: false, message: 'Failed to load feed');
    } catch (e) {
      return PostListResult(success: false, message: 'Error: $e');
    }
  }

  /// Get feed with only friends' posts
  Future<PostListResult> getFriendsFeed({
    required int userId,
    int page = 1,
    int perPage = 20,
  }) async {
    try {
      final headers = await _authHeaders();
      final response = await http.get(
        Uri.parse('$_baseUrl/feed/friends?user_id=$userId&page=$page&per_page=$perPage'),
        headers: headers,
      );

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        if (data['success'] == true && data is Map<String, dynamic>) {
          final (posts, meta) = _parseFeedData(data);
          return PostListResult(
            success: true,
            posts: posts,
            meta: meta,
            message: data['message']?.toString(),
          );
        }
      }
      return PostListResult(success: false, message: 'Failed to load feed');
    } catch (e) {
      return PostListResult(success: false, message: 'Error: $e');
    }
  }

  /// Get discovery feed (public posts from non-friends)
  Future<PostListResult> getDiscoverFeed({
    int? userId,
    int page = 1,
    int perPage = 20,
  }) async {
    try {
      String url = '$_baseUrl/feed/discover?page=$page&per_page=$perPage';
      if (userId != null) url += '&user_id=$userId';

      final headers = await _authHeaders();
      final response = await http.get(Uri.parse(url), headers: headers);

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        if (data['success'] == true && data is Map<String, dynamic>) {
          final (posts, meta) = _parseFeedData(data);
          return PostListResult(
            success: true,
            posts: posts,
            meta: meta,
          );
        }
      }
      return PostListResult(success: false, message: 'Failed to load feed');
    } catch (e) {
      return PostListResult(success: false, message: 'Error: $e');
    }
  }

  /// Get trending posts
  Future<PostListResult> getTrendingFeed({
    int? userId,
    int page = 1,
    int perPage = 20,
  }) async {
    try {
      String url = '$_baseUrl/feed/trending?page=$page&per_page=$perPage';
      if (userId != null) url += '&user_id=$userId';

      final headers = await _authHeaders();
      final response = await http.get(Uri.parse(url), headers: headers);

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        if (data['success'] == true && data is Map<String, dynamic>) {
          final (posts, meta) = _parseFeedData(data);
          return PostListResult(
            success: true,
            posts: posts,
            meta: meta,
          );
        }
      }
      return PostListResult(success: false, message: 'Failed to load feed');
    } catch (e) {
      return PostListResult(success: false, message: 'Error: $e');
    }
  }

  /// Get nearby posts (same region)
  Future<PostListResult> getNearbyFeed({
    int? userId,
    int? regionId,
    int page = 1,
    int perPage = 20,
  }) async {
    try {
      String url = '$_baseUrl/feed/nearby?page=$page&per_page=$perPage';
      if (userId != null) url += '&user_id=$userId';
      if (regionId != null) url += '&region_id=$regionId';

      final headers = await _authHeaders();
      final response = await http.get(Uri.parse(url), headers: headers);

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        if (data['success'] == true && data is Map<String, dynamic>) {
          final (posts, meta) = _parseFeedData(data);
          return PostListResult(
            success: true,
            posts: posts,
            meta: meta,
          );
        }
      }
      return PostListResult(success: false, message: 'Failed to load feed');
    } catch (e) {
      return PostListResult(success: false, message: 'Error: $e');
    }
  }
}
