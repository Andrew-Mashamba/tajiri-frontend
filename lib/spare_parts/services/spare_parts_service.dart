// lib/spare_parts/services/spare_parts_service.dart
import 'package:dio/dio.dart';
import '../../services/authenticated_dio.dart';
import '../models/spare_parts_models.dart';

class SparePartsService {
  Dio get _dio => AuthenticatedDio.instance;

  // ─── Parts Search ─────────────────────────────────────────────

  Future<PaginatedResult<SparePart>> searchParts({
    String? query,
    String? make,
    String? model,
    int? year,
    String? category,
    String? condition,
    int page = 1,
  }) async {
    try {
      final params = <String, dynamic>{'page': page};
      if (query != null && query.isNotEmpty) params['q'] = query;
      if (make != null) params['make'] = make;
      if (model != null) params['model'] = model;
      if (year != null) params['year'] = year;
      if (category != null) params['category'] = category;
      if (condition != null) params['condition'] = condition;

      final resp = await _dio.get('/spare-parts/search', queryParameters: params);
      final data = resp.data;
      if (data['success'] == true) {
        final list = (data['data'] as List)
            .map((j) => SparePart.fromJson(j))
            .toList();
        return PaginatedResult(
          success: true,
          items: list,
          currentPage: data['current_page'] ?? page,
          lastPage: data['last_page'] ?? 1,
        );
      }
      return PaginatedResult(success: false, message: data['message']);
    } catch (e) {
      return PaginatedResult(success: false, message: '$e');
    }
  }

  Future<SingleResult<SparePart>> getPart(int id) async {
    try {
      final resp = await _dio.get('/spare-parts/parts/$id');
      final data = resp.data;
      if (data['success'] == true) {
        return SingleResult(success: true, data: SparePart.fromJson(data['data']));
      }
      return SingleResult(success: false, message: data['message']);
    } catch (e) {
      return SingleResult(success: false, message: '$e');
    }
  }

  // ─── Sellers ──────────────────────────────────────────────────

  Future<SingleResult<PartsSeller>> getSeller(int id) async {
    try {
      final resp = await _dio.get('/spare-parts/sellers/$id');
      final data = resp.data;
      if (data['success'] == true) {
        return SingleResult(success: true, data: PartsSeller.fromJson(data['data']));
      }
      return SingleResult(success: false, message: data['message']);
    } catch (e) {
      return SingleResult(success: false, message: '$e');
    }
  }

  Future<PaginatedResult<PartsSeller>> getShopDirectory({
    double? lat,
    double? lng,
    String? specialization,
    int page = 1,
  }) async {
    try {
      final params = <String, dynamic>{'page': page};
      if (lat != null) params['lat'] = lat;
      if (lng != null) params['lng'] = lng;
      if (specialization != null) params['specialization'] = specialization;

      final resp = await _dio.get('/spare-parts/shops', queryParameters: params);
      final data = resp.data;
      if (data['success'] == true) {
        final list = (data['data'] as List)
            .map((j) => PartsSeller.fromJson(j))
            .toList();
        return PaginatedResult(success: true, items: list);
      }
      return PaginatedResult(success: false, message: data['message']);
    } catch (e) {
      return PaginatedResult(success: false, message: '$e');
    }
  }

  // ─── Orders ───────────────────────────────────────────────────

  Future<SingleResult<PartsOrder>> createOrder(Map<String, dynamic> orderData) async {
    try {
      final resp = await _dio.post('/spare-parts/orders', data: orderData);
      final data = resp.data;
      if (data['success'] == true) {
        return SingleResult(success: true, data: PartsOrder.fromJson(data['data']));
      }
      return SingleResult(success: false, message: data['message']);
    } catch (e) {
      return SingleResult(success: false, message: '$e');
    }
  }

  Future<PaginatedResult<PartsOrder>> getMyOrders({int page = 1}) async {
    try {
      final resp = await _dio.get('/spare-parts/orders', queryParameters: {'page': page});
      final data = resp.data;
      if (data['success'] == true) {
        final list = (data['data'] as List)
            .map((j) => PartsOrder.fromJson(j))
            .toList();
        return PaginatedResult(success: true, items: list);
      }
      return PaginatedResult(success: false, message: data['message']);
    } catch (e) {
      return PaginatedResult(success: false, message: '$e');
    }
  }

  Future<SingleResult<PartsOrder>> getOrderStatus(int id) async {
    try {
      final resp = await _dio.get('/spare-parts/orders/$id');
      final data = resp.data;
      if (data['success'] == true) {
        return SingleResult(success: true, data: PartsOrder.fromJson(data['data']));
      }
      return SingleResult(success: false, message: data['message']);
    } catch (e) {
      return SingleResult(success: false, message: '$e');
    }
  }

  // ─── Compatibility ────────────────────────────────────────────

  Future<SingleResult<bool>> checkCompatibility(int partId, int vehicleId) async {
    try {
      final resp = await _dio.get('/spare-parts/compatibility', queryParameters: {
        'part_id': partId,
        'vehicle_id': vehicleId,
      });
      final data = resp.data;
      if (data['success'] == true) {
        return SingleResult(success: true, data: data['compatible'] == true);
      }
      return SingleResult(success: false, message: data['message']);
    } catch (e) {
      return SingleResult(success: false, message: '$e');
    }
  }

  // ─── Counterfeit Reporting ────────────────────────────────────

  Future<SingleResult<bool>> reportCounterfeit(int partId, String reason) async {
    try {
      final resp = await _dio.post('/spare-parts/report', data: {
        'part_id': partId,
        'reason': reason,
      });
      final data = resp.data;
      return SingleResult(success: data['success'] == true);
    } catch (e) {
      return SingleResult(success: false, message: '$e');
    }
  }
}
