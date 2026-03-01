import 'dart:convert';
import 'package:http/http.dart' as http;
import '../config/api_config.dart';
import '../models/post_models.dart';

String get _baseUrl => ApiConfig.baseUrl;

/// Service for hashtag discovery and search (Story 68).
/// GET /api/hashtags/trending, GET /api/hashtags/search, GET /api/posts/hashtag/{tag} (see PostService).
class HashtagService {
  /// GET /api/hashtags/trending – list trending hashtags for discovery.
  Future<TrendingHashtagsResult> getTrendingHashtags({int limit = 20}) async {
    try {
      final url = '$_baseUrl/hashtags/trending?limit=$limit';
      final response = await http.get(Uri.parse(url));

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        if (data['success'] == true && data['data'] != null) {
          final list = data['data'] as List;
          final hashtags = list
              .map((e) => e is Map<String, dynamic>
                  ? Hashtag.fromJson(e)
                  : Hashtag.fromJson(Map<String, dynamic>.from(e)))
              .toList();
          return TrendingHashtagsResult(success: true, hashtags: hashtags);
        }
      }
      return TrendingHashtagsResult(
        success: false,
        message: 'Failed to load trending hashtags',
      );
    } catch (e) {
      return TrendingHashtagsResult(
        success: false,
        message: 'Error: $e',
      );
    }
  }

  /// GET /api/hashtags/search?q=... – search hashtags by query.
  Future<HashtagSearchResult> searchHashtags(String query, {int limit = 20}) async {
    if (query.trim().isEmpty) {
      return HashtagSearchResult(success: true, hashtags: []);
    }
    try {
      final encoded = Uri.encodeComponent(query.trim());
      final url = '$_baseUrl/hashtags/search?q=$encoded&limit=$limit';
      final response = await http.get(Uri.parse(url));

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        if (data['success'] == true && data['data'] != null) {
          final list = data['data'] as List;
          final hashtags = list
              .map((e) => e is Map<String, dynamic>
                  ? Hashtag.fromJson(e)
                  : Hashtag.fromJson(Map<String, dynamic>.from(e)))
              .toList();
          return HashtagSearchResult(success: true, hashtags: hashtags);
        }
      }
      return HashtagSearchResult(
        success: false,
        message: 'Failed to search hashtags',
      );
    } catch (e) {
      return HashtagSearchResult(
        success: false,
        message: 'Error: $e',
      );
    }
  }
}

class TrendingHashtagsResult {
  final bool success;
  final List<Hashtag> hashtags;
  final String? message;

  TrendingHashtagsResult({
    required this.success,
    this.hashtags = const [],
    this.message,
  });
}

class HashtagSearchResult {
  final bool success;
  final List<Hashtag> hashtags;
  final String? message;

  HashtagSearchResult({
    required this.success,
    this.hashtags = const [],
    this.message,
  });
}
