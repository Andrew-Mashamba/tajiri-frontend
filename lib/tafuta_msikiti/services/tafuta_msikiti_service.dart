// lib/tafuta_msikiti/services/tafuta_msikiti_service.dart
import 'dart:convert';
import 'package:http/http.dart' as http;
import '../../config/api_config.dart';
import '../models/tafuta_msikiti_models.dart';

String get _baseUrl => ApiConfig.baseUrl;

class TafutaMsikitiService {
  // ─── Search Nearby Mosques ──────────────────────────────────
  Future<PaginatedResult<Mosque>> searchNearby({
    required double latitude,
    required double longitude,
    double radiusKm = 10,
    String? query,
    List<String>? facilities,
    int page = 1,
    int perPage = 20,
  }) async {
    try {
      final params = <String, String>{
        'latitude': '$latitude',
        'longitude': '$longitude',
        'radius_km': '$radiusKm',
        'page': '$page',
        'per_page': '$perPage',
      };
      if (query != null) params['q'] = query;
      if (facilities != null && facilities.isNotEmpty) {
        params['facilities'] = facilities.join(',');
      }

      final uri = Uri.parse('$_baseUrl/mosques/search')
          .replace(queryParameters: params);
      final response = await http.get(uri);

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        if (data['success'] == true) {
          final items = (data['data'] as List?)
                  ?.map((j) => Mosque.fromJson(j))
                  .toList() ??
              [];
          return PaginatedResult(
            success: true, items: items,
            currentPage: _parseInt(data['meta']?['current_page']),
            lastPage: _parseInt(data['meta']?['last_page']),
            total: _parseInt(data['meta']?['total']),
          );
        }
      }
      return PaginatedResult(success: false, message: 'Imeshindwa kupakia');
    } catch (e) {
      return PaginatedResult(success: false, message: 'Kosa: $e');
    }
  }

  // ─── Get Mosque Detail ──────────────────────────────────────
  Future<SingleResult<Mosque>> getMosqueDetail(int mosqueId) async {
    try {
      final response = await http.get(
        Uri.parse('$_baseUrl/mosques/$mosqueId'),
      );
      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        if (data['success'] == true && data['data'] != null) {
          return SingleResult(
            success: true,
            data: Mosque.fromJson(data['data']),
          );
        }
      }
      return SingleResult(success: false, message: 'Imeshindwa kupakia msikiti');
    } catch (e) {
      return SingleResult(success: false, message: 'Kosa: $e');
    }
  }

  // ─── Get Reviews ────────────────────────────────────────────
  Future<PaginatedResult<MosqueReview>> getReviews({
    required int mosqueId,
    int page = 1,
  }) async {
    try {
      final response = await http.get(
        Uri.parse('$_baseUrl/mosques/$mosqueId/reviews?page=$page'),
      );
      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        if (data['success'] == true) {
          final items = (data['data'] as List?)
                  ?.map((j) => MosqueReview.fromJson(j))
                  .toList() ??
              [];
          return PaginatedResult(success: true, items: items, total: items.length);
        }
      }
      return PaginatedResult(success: false, message: 'Imeshindwa kupakia tathmini');
    } catch (e) {
      return PaginatedResult(success: false, message: 'Kosa: $e');
    }
  }

  // ─── Submit Review ──────────────────────────────────────────
  Future<SingleResult<MosqueReview>> submitReview({
    required String token,
    required int mosqueId,
    required double rating,
    String? comment,
  }) async {
    try {
      final response = await http.post(
        Uri.parse('$_baseUrl/mosques/$mosqueId/reviews'),
        headers: ApiConfig.authHeaders(token),
        body: jsonEncode({
          'rating': rating,
          if (comment != null) 'comment': comment,
        }),
      );
      if (response.statusCode == 200 || response.statusCode == 201) {
        final data = jsonDecode(response.body);
        if (data['success'] == true) {
          return SingleResult(
            success: true,
            data: MosqueReview.fromJson(data['data']),
          );
        }
      }
      return SingleResult(success: false, message: 'Imeshindwa kutuma');
    } catch (e) {
      return SingleResult(success: false, message: 'Kosa: $e');
    }
  }

  // ─── Suggest Mosque ─────────────────────────────────────────
  Future<SingleResult<bool>> suggestMosque({
    required String token,
    required String name,
    required double latitude,
    required double longitude,
    String? address,
  }) async {
    try {
      final response = await http.post(
        Uri.parse('$_baseUrl/mosques/suggest'),
        headers: ApiConfig.authHeaders(token),
        body: jsonEncode({
          'name': name,
          'latitude': latitude,
          'longitude': longitude,
          if (address != null) 'address': address,
        }),
      );
      return SingleResult(
        success: response.statusCode == 200 || response.statusCode == 201,
        data: true,
      );
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
