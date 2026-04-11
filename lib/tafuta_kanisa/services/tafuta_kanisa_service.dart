// lib/tafuta_kanisa/services/tafuta_kanisa_service.dart
import 'package:dio/dio.dart';
import '../../services/authenticated_dio.dart';
import '../models/tafuta_kanisa_models.dart';

Dio get _dio => AuthenticatedDio.instance;

class TafutaKanisaService {
  // ─── Search ─────────────────────────────────────────────────

  static Future<PaginatedResult<ChurchListing>> search({
    double? latitude,
    double? longitude,
    String? denomination,
    String? query,
    int page = 1,
  }) async {
    try {
      final params = <String, dynamic>{'page': page};
      if (latitude != null) params['latitude'] = latitude;
      if (longitude != null) params['longitude'] = longitude;
      if (denomination != null) params['denomination'] = denomination;
      if (query != null) params['q'] = query;
      final r =
          await _dio.get('/tafuta-kanisa/search', queryParameters: params);
      final data = r.data;
      if (data['success'] == true) {
        final items = (data['data'] as List)
            .map((j) => ChurchListing.fromJson(j))
            .toList();
        return PaginatedResult(
          success: true,
          items: items,
          currentPage: data['meta']?['current_page'] ?? page,
          lastPage: data['meta']?['last_page'] ?? 1,
        );
      }
      return PaginatedResult(success: false, message: data['message']);
    } catch (e) {
      return PaginatedResult(success: false, message: '$e');
    }
  }

  // ─── Church Detail ──────────────────────────────────────────

  static Future<SingleResult<ChurchListing>> getChurch(
      int churchId) async {
    try {
      final r = await _dio.get('/tafuta-kanisa/$churchId');
      final data = r.data;
      if (data['success'] == true && data['data'] != null) {
        return SingleResult(
            success: true, data: ChurchListing.fromJson(data['data']));
      }
      return SingleResult(success: false, message: data['message']);
    } catch (e) {
      return SingleResult(success: false, message: '$e');
    }
  }

  // ─── Reviews ────────────────────────────────────────────────

  static Future<PaginatedResult<ChurchReview>> getReviews(int churchId,
      {int page = 1}) async {
    try {
      final r = await _dio.get('/tafuta-kanisa/$churchId/reviews',
          queryParameters: {'page': page});
      final data = r.data;
      if (data['success'] == true) {
        final items = (data['data'] as List)
            .map((j) => ChurchReview.fromJson(j))
            .toList();
        return PaginatedResult(success: true, items: items);
      }
      return PaginatedResult(success: false, message: data['message']);
    } catch (e) {
      return PaginatedResult(success: false, message: '$e');
    }
  }

  static Future<SingleResult<void>> submitReview(
      int churchId, Map<String, dynamic> body) async {
    try {
      final r =
          await _dio.post('/tafuta-kanisa/$churchId/reviews', data: body);
      return SingleResult(success: r.data['success'] == true);
    } catch (e) {
      return SingleResult(success: false, message: '$e');
    }
  }

  // ─── Save / Unsave ─────────────────────────────────────────

  static Future<SingleResult<void>> toggleSaved(int churchId) async {
    try {
      final r = await _dio.post('/tafuta-kanisa/$churchId/save');
      return SingleResult(success: r.data['success'] == true);
    } catch (e) {
      return SingleResult(success: false, message: '$e');
    }
  }

  // ─── Denominations ─────────────────────────────────────────

  static Future<PaginatedResult<String>> getDenominations() async {
    try {
      final r = await _dio.get('/tafuta-kanisa/denominations');
      final data = r.data;
      if (data['success'] == true) {
        final items =
            (data['data'] as List).map((e) => e.toString()).toList();
        return PaginatedResult(success: true, items: items);
      }
      return PaginatedResult(success: false);
    } catch (e) {
      return PaginatedResult(success: false, message: '$e');
    }
  }
}
