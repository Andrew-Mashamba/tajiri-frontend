// lib/dua/services/dua_service.dart
import 'dart:convert';
import 'package:http/http.dart' as http;
import '../../config/api_config.dart';
import '../models/dua_models.dart';

String get _baseUrl => ApiConfig.baseUrl;

class DuaService {
  // ─── Get Categories ─────────────────────────────────────────
  Future<PaginatedResult<DuaCategory>> getCategories() async {
    try {
      final response = await http.get(
        Uri.parse('$_baseUrl/duas/categories'),
      );
      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        if (data['success'] == true) {
          final items = (data['data'] as List?)
                  ?.map((j) => DuaCategory.fromJson(j))
                  .toList() ??
              [];
          return PaginatedResult(success: true, items: items, total: items.length);
        }
      }
      return PaginatedResult(success: false, message: 'Imeshindwa kupakia makundi');
    } catch (e) {
      return PaginatedResult(success: false, message: 'Kosa: $e');
    }
  }

  // ─── Get Duas by Category ──────────────────────────────────
  Future<PaginatedResult<Dua>> getDuasByCategory({
    required int categoryId,
    int page = 1,
  }) async {
    try {
      final response = await http.get(
        Uri.parse('$_baseUrl/duas/category/$categoryId?page=$page'),
      );
      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        if (data['success'] == true) {
          final items = (data['data'] as List?)
                  ?.map((j) => Dua.fromJson(j))
                  .toList() ??
              [];
          return PaginatedResult(success: true, items: items, total: items.length);
        }
      }
      return PaginatedResult(success: false, message: 'Imeshindwa kupakia dua');
    } catch (e) {
      return PaginatedResult(success: false, message: 'Kosa: $e');
    }
  }

  // ─── Get Adhkar ─────────────────────────────────────────────
  Future<PaginatedResult<AdhkarItem>> getAdhkar({
    required String type, // morning, evening
  }) async {
    try {
      final response = await http.get(
        Uri.parse('$_baseUrl/duas/adhkar?type=$type'),
      );
      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        if (data['success'] == true) {
          final items = (data['data'] as List?)
                  ?.map((j) => AdhkarItem.fromJson(j))
                  .toList() ??
              [];
          return PaginatedResult(success: true, items: items, total: items.length);
        }
      }
      return PaginatedResult(success: false, message: 'Imeshindwa kupakia adhkar');
    } catch (e) {
      return PaginatedResult(success: false, message: 'Kosa: $e');
    }
  }

  // ─── Get Favorites ──────────────────────────────────────────
  Future<PaginatedResult<Dua>> getFavorites({required String token}) async {
    try {
      final response = await http.get(
        Uri.parse('$_baseUrl/duas/favorites'),
        headers: ApiConfig.authHeaders(token),
      );
      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        if (data['success'] == true) {
          final items = (data['data'] as List?)
                  ?.map((j) => Dua.fromJson(j))
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

  // ─── Toggle Favorite ───────────────────────────────────────
  Future<SingleResult<bool>> toggleFavorite({
    required String token,
    required int duaId,
  }) async {
    try {
      final response = await http.post(
        Uri.parse('$_baseUrl/duas/$duaId/favorite'),
        headers: ApiConfig.authHeaders(token),
      );
      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        return SingleResult(
          success: true,
          data: _parseBool(data['is_favorite']),
        );
      }
      return SingleResult(success: false, message: 'Imeshindwa');
    } catch (e) {
      return SingleResult(success: false, message: 'Kosa: $e');
    }
  }

  // ─── Search Duas ────────────────────────────────────────────
  Future<PaginatedResult<Dua>> search({required String query}) async {
    try {
      final response = await http.get(
        Uri.parse('$_baseUrl/duas/search?q=$query'),
      );
      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        if (data['success'] == true) {
          final items = (data['data'] as List?)
                  ?.map((j) => Dua.fromJson(j))
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
}

bool _parseBool(dynamic v) {
  if (v is bool) return v;
  if (v is int) return v == 1;
  if (v is String) return v == '1' || v.toLowerCase() == 'true';
  return false;
}
