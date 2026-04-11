// lib/news/services/news_service.dart
import 'dart:convert';
import 'package:http/http.dart' as http;
import '../../config/api_config.dart';
import '../models/news_models.dart';

String get _baseUrl => ApiConfig.baseUrl;

class NewsService {
  // ─── Articles ─────────────────────────────────────────────────

  Future<NewsListResult<NewsArticle>> getArticles({
    NewsCategory? category,
    String? search,
    int page = 1,
    int perPage = 20,
  }) async {
    try {
      final params = <String, String>{
        'page': '$page',
        'per_page': '$perPage',
      };
      if (category != null) params['category'] = category.name;
      if (search != null && search.isNotEmpty) params['search'] = search;

      final uri = Uri.parse('$_baseUrl/news/articles')
          .replace(queryParameters: params);
      final response = await http.get(uri);

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        if (data['success'] == true) {
          final items = (data['data'] as List)
              .map((j) => NewsArticle.fromJson(j))
              .toList();
          return NewsListResult(success: true, items: items);
        }
      }
      return NewsListResult(
        success: false,
        message: 'Imeshindwa kupakia habari',
      );
    } catch (e) {
      return NewsListResult(success: false, message: 'Kosa: $e');
    }
  }

  Future<NewsResult<NewsArticle>> getArticle(int articleId) async {
    try {
      final response = await http.get(
        Uri.parse('$_baseUrl/news/articles/$articleId'),
      );
      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        if (data['success'] == true) {
          return NewsResult(
            success: true,
            data: NewsArticle.fromJson(data['data']),
          );
        }
      }
      return NewsResult(success: false, message: 'Imeshindwa kupakia makala');
    } catch (e) {
      return NewsResult(success: false, message: 'Kosa: $e');
    }
  }

  // ─── Top Stories ──────────────────────────────────────────────

  Future<NewsListResult<NewsArticle>> getTopStories() async {
    try {
      final response = await http.get(
        Uri.parse('$_baseUrl/news/top-stories'),
      );
      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        if (data['success'] == true) {
          final items = (data['data'] as List)
              .map((j) => NewsArticle.fromJson(j))
              .toList();
          return NewsListResult(success: true, items: items);
        }
      }
      return NewsListResult(success: false);
    } catch (e) {
      return NewsListResult(success: false);
    }
  }

  // ─── Save / Unsave Article ────────────────────────────────────

  Future<NewsResult<void>> saveArticle({
    required int articleId,
    required int userId,
  }) async {
    try {
      final response = await http.post(
        Uri.parse('$_baseUrl/news/articles/$articleId/save'),
        headers: ApiConfig.headers,
        body: jsonEncode({'user_id': userId}),
      );
      if (response.statusCode == 200) {
        return NewsResult(success: true);
      }
      return NewsResult(success: false, message: 'Imeshindwa kuhifadhi');
    } catch (e) {
      return NewsResult(success: false, message: 'Kosa: $e');
    }
  }

  Future<NewsListResult<NewsArticle>> getSavedArticles(int userId) async {
    try {
      final response = await http.get(
        Uri.parse('$_baseUrl/news/saved?user_id=$userId'),
      );
      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        if (data['success'] == true) {
          final items = (data['data'] as List)
              .map((j) => NewsArticle.fromJson(j))
              .toList();
          return NewsListResult(success: true, items: items);
        }
      }
      return NewsListResult(success: false);
    } catch (e) {
      return NewsListResult(success: false);
    }
  }
}
