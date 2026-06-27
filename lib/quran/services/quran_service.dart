// lib/quran/services/quran_service.dart
import 'dart:convert';
import 'package:http/http.dart' as http;
import '../../services/http_retry.dart';
import '../../config/api_config.dart';
import '../../services/graphql/graphql_quran_service.dart';
import '../models/quran_models.dart';

String get _baseUrl => ApiConfig.baseUrl;

class QuranService {
  Future<PaginatedResult<Surah>> getSurahs() async {
    if (ApiConfig.useGraphqlBackend) {
      return GraphqlQuranService.getSurahs();
    }
    try {
      final response = await httpGetWithRetry(
        Uri.parse('$_baseUrl/quran/surahs'),
      );
      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        if (data['success'] == true) {
          final items = (data['data'] as List?)
                  ?.map((j) => Surah.fromJson(j))
                  .toList() ??
              [];
          return PaginatedResult(success: true, items: items, total: items.length);
        }
      }
      return PaginatedResult(success: false, message: 'Imeshindwa kupakia sura');
    } catch (e) {
      return PaginatedResult(success: false, message: 'Kosa: $e');
    }
  }

  Future<PaginatedResult<Ayah>> getAyahs({
    required int surahNumber,
    int page = 1,
    int perPage = 50,
  }) async {
    if (ApiConfig.useGraphqlBackend) {
      return GraphqlQuranService.getAyahs(
        surahNumber: surahNumber,
        page: page,
        perPage: perPage,
      );
    }
    try {
      final response = await httpGetWithRetry(
        Uri.parse('$_baseUrl/quran/surahs/$surahNumber/ayahs'
            '?page=$page&per_page=$perPage'),
      );
      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        if (data['success'] == true) {
          final items = (data['data'] as List?)
                  ?.map((j) => Ayah.fromJson(j))
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
      return PaginatedResult(success: false, message: 'Imeshindwa kupakia aya');
    } catch (e) {
      return PaginatedResult(success: false, message: 'Kosa: $e');
    }
  }

  Future<PaginatedResult<Juz>> getJuzList() async {
    if (ApiConfig.useGraphqlBackend) {
      return GraphqlQuranService.getJuzList();
    }
    try {
      final response = await httpGetWithRetry(Uri.parse('$_baseUrl/quran/juz'));
      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        if (data['success'] == true) {
          final items = (data['data'] as List?)
                  ?.map((j) => Juz.fromJson(j))
                  .toList() ??
              [];
          return PaginatedResult(success: true, items: items, total: items.length);
        }
      }
      return PaginatedResult(success: false, message: 'Imeshindwa kupakia juz');
    } catch (e) {
      return PaginatedResult(success: false, message: 'Kosa: $e');
    }
  }

  Future<PaginatedResult<Ayah>> search({
    required String query,
    String language = 'sw',
  }) async {
    if (ApiConfig.useGraphqlBackend) {
      return GraphqlQuranService.search(query: query, language: language);
    }
    try {
      final response = await httpGetWithRetry(
        Uri.parse('$_baseUrl/quran/search?q=$query&lang=$language'),
      );
      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        if (data['success'] == true) {
          final items = (data['data'] as List?)
                  ?.map((j) => Ayah.fromJson(j))
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

  Future<PaginatedResult<QuranBookmark>> getBookmarks({
    required String token,
  }) async {
    if (ApiConfig.useGraphqlBackend) {
      return GraphqlQuranService.getBookmarks();
    }
    try {
      final response = await httpGetWithRetry(
        Uri.parse('$_baseUrl/quran/bookmarks'),
        headers: ApiConfig.authHeaders(token),
      );
      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        if (data['success'] == true) {
          final items = (data['data'] as List?)
                  ?.map((j) => QuranBookmark.fromJson(j))
                  .toList() ??
              [];
          return PaginatedResult(success: true, items: items, total: items.length);
        }
      }
      return PaginatedResult(success: false, message: 'Imeshindwa kupakia alama');
    } catch (e) {
      return PaginatedResult(success: false, message: 'Kosa: $e');
    }
  }

  Future<SingleResult<QuranBookmark>> addBookmark({
    required String token,
    required QuranBookmark bookmark,
  }) async {
    if (ApiConfig.useGraphqlBackend) {
      return GraphqlQuranService.addBookmark(bookmark);
    }
    try {
      final response = await http.post(
        Uri.parse('$_baseUrl/quran/bookmarks'),
        headers: ApiConfig.authHeaders(token),
        body: jsonEncode(bookmark.toJson()),
      );
      if (response.statusCode == 200 || response.statusCode == 201) {
        final data = jsonDecode(response.body);
        if (data['success'] == true) {
          return SingleResult(
            success: true,
            data: QuranBookmark.fromJson(data['data']),
          );
        }
      }
      return SingleResult(success: false, message: 'Imeshindwa kuhifadhi');
    } catch (e) {
      return SingleResult(success: false, message: 'Kosa: $e');
    }
  }

  Future<PaginatedResult<Reciter>> getReciters() async {
    if (ApiConfig.useGraphqlBackend) {
      return GraphqlQuranService.getReciters();
    }
    try {
      final response = await httpGetWithRetry(Uri.parse('$_baseUrl/quran/reciters'));
      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        if (data['success'] == true) {
          final items = (data['data'] as List?)
                  ?.map((j) => Reciter.fromJson(j))
                  .toList() ??
              [];
          return PaginatedResult(success: true, items: items, total: items.length);
        }
      }
      return PaginatedResult(success: false, message: 'Imeshindwa kupakia wasomaji');
    } catch (e) {
      return PaginatedResult(success: false, message: 'Kosa: $e');
    }
  }
}

int _parseInt(dynamic v) {
  if (v is int) return v;
  if (v is double) return v.toInt();
  if (v is String) return int.tryParse(v) ?? 0;
  return 0;
}
