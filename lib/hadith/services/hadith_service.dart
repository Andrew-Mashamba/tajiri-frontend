// lib/hadith/services/hadith_service.dart
import 'dart:convert';
import 'package:http/http.dart' as http;
import '../../services/http_retry.dart';
import '../../config/api_config.dart';
import '../../services/graphql/graphql_hadith_service.dart';
import '../models/hadith_models.dart';

String get _baseUrl => ApiConfig.baseUrl;

class HadithService {
  Future<PaginatedResult<HadithCollection>> getCollections() async {
    if (ApiConfig.useGraphqlBackend) {
      return GraphqlHadithService.getCollections();
    }
    try {
      final response = await httpGetWithRetry(
        Uri.parse('$_baseUrl/hadith/collections'),
      );
      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        if (data['success'] == true) {
          final items = (data['data'] as List?)
                  ?.map((j) => HadithCollection.fromJson(j))
                  .toList() ??
              [];
          return PaginatedResult(success: true, items: items, total: items.length);
        }
      }
      return PaginatedResult(success: false, message: 'Imeshindwa kupakia');
    } catch (e) {
      return PaginatedResult(success: false, message: 'Kosa: $e');
    }
  }

  Future<PaginatedResult<HadithBook>> getBooks({
    required int collectionId,
  }) async {
    if (ApiConfig.useGraphqlBackend) {
      return GraphqlHadithService.getBooks(collectionId: collectionId);
    }
    try {
      final response = await httpGetWithRetry(
        Uri.parse('$_baseUrl/hadith/collections/$collectionId/books'),
      );
      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        if (data['success'] == true) {
          final items = (data['data'] as List?)
                  ?.map((j) => HadithBook.fromJson(j))
                  .toList() ??
              [];
          return PaginatedResult(success: true, items: items, total: items.length);
        }
      }
      return PaginatedResult(success: false, message: 'Imeshindwa kupakia vitabu');
    } catch (e) {
      return PaginatedResult(success: false, message: 'Kosa: $e');
    }
  }

  Future<PaginatedResult<Hadith>> getHadiths({
    required int bookId,
    int page = 1,
    int perPage = 20,
  }) async {
    if (ApiConfig.useGraphqlBackend) {
      return GraphqlHadithService.getHadiths(
        bookId: bookId,
        page: page,
        perPage: perPage,
      );
    }
    try {
      final response = await httpGetWithRetry(
        Uri.parse('$_baseUrl/hadith/books/$bookId'
            '?page=$page&per_page=$perPage'),
      );
      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        if (data['success'] == true) {
          final items = (data['data'] as List?)
                  ?.map((j) => Hadith.fromJson(j))
                  .toList() ??
              [];
          return PaginatedResult(
            success: true,
            items: items,
            currentPage: _parseInt(data['meta']?['current_page']),
            lastPage: _parseInt(data['meta']?['last_page']),
            total: _parseInt(data['meta']?['total']),
          );
        }
      }
      return PaginatedResult(success: false, message: 'Imeshindwa kupakia hadith');
    } catch (e) {
      return PaginatedResult(success: false, message: 'Kosa: $e');
    }
  }

  Future<SingleResult<Hadith>> getDailyHadith() async {
    if (ApiConfig.useGraphqlBackend) {
      return GraphqlHadithService.getDailyHadith();
    }
    try {
      final response = await httpGetWithRetry(
        Uri.parse('$_baseUrl/hadith/daily'),
      );
      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        if (data['success'] == true && data['data'] != null) {
          return SingleResult(success: true, data: Hadith.fromJson(data['data']));
        }
      }
      return SingleResult(success: false, message: 'Imeshindwa kupakia');
    } catch (e) {
      return SingleResult(success: false, message: 'Kosa: $e');
    }
  }

  Future<PaginatedResult<Hadith>> search({required String query}) async {
    if (ApiConfig.useGraphqlBackend) {
      return GraphqlHadithService.search(query: query);
    }
    try {
      final response = await httpGetWithRetry(
        Uri.parse('$_baseUrl/hadith/search?q=$query'),
      );
      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        if (data['success'] == true) {
          final items = (data['data'] as List?)
                  ?.map((j) => Hadith.fromJson(j))
                  .toList() ??
              [];
          return PaginatedResult(success: true, items: items, total: items.length);
        }
      }
      return PaginatedResult(success: false, message: 'Hakuna matokeo');
    } catch (e) {
      return PaginatedResult(success: false, message: 'Kosa: $e');
    }
  }

  Future<SingleResult<bool>> toggleFavorite({
    required String token,
    required int hadithId,
  }) async {
    if (ApiConfig.useGraphqlBackend) {
      return GraphqlHadithService.toggleFavorite(hadithId: hadithId);
    }
    try {
      final response = await http.post(
        Uri.parse('$_baseUrl/hadith/$hadithId/favorite'),
        headers: ApiConfig.authHeaders(token),
      );
      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        return SingleResult(success: true, data: data['is_favorite'] == true);
      }
      return SingleResult(success: false, message: 'Imeshindwa');
    } catch (e) {
      return SingleResult(success: false, message: 'Kosa: $e');
    }
  }
}

int _parseInt(dynamic v) {
  if (v is int) return v;
  if (v is double) return v.toInt();
  if (v is String) return int.tryParse(v) ?? 0;
  return 0;
}
