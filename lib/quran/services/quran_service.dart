// lib/quran/services/quran_service.dart
import 'dart:convert';
import 'package:http/http.dart' as http;
import '../../config/api_config.dart';
import '../models/quran_models.dart';

String get _baseUrl => ApiConfig.baseUrl;

class QuranService {
  // ─── Get All Surahs ─────────────────────────────────────────
  Future<PaginatedResult<Surah>> getSurahs() async {
    try {
      final response = await http.get(
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

  // ─── Get Ayahs for Surah ────────────────────────────────────
  Future<PaginatedResult<Ayah>> getAyahs({
    required int surahNumber,
    int page = 1,
    int perPage = 50,
  }) async {
    try {
      final response = await http.get(
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

  // ─── Get Juz List ───────────────────────────────────────────
  Future<PaginatedResult<Juz>> getJuzList() async {
    try {
      final response = await http.get(Uri.parse('$_baseUrl/quran/juz'));
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

  // ─── Search Quran ───────────────────────────────────────────
  Future<PaginatedResult<Ayah>> search({
    required String query,
    String language = 'sw',
  }) async {
    try {
      final response = await http.get(
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

  // ─── Bookmarks ──────────────────────────────────────────────
  Future<PaginatedResult<QuranBookmark>> getBookmarks({
    required String token,
  }) async {
    try {
      final response = await http.get(
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

  // ─── Reciters ───────────────────────────────────────────────
  Future<PaginatedResult<Reciter>> getReciters() async {
    try {
      final response = await http.get(Uri.parse('$_baseUrl/quran/reciters'));
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
