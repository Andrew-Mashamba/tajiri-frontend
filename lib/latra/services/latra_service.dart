// lib/latra/services/latra_service.dart
import 'package:dio/dio.dart';
import '../../services/authenticated_dio.dart';
import '../models/latra_models.dart';

Dio get _dio => AuthenticatedDio.instance;

class LatraService {
  static Future<SingleResult<FareResult>> checkFare({
    required String origin,
    required String destination,
    String vehicleType = 'daladala',
  }) async {
    try {
      final r = await _dio.get('/latra/fare-check', queryParameters: {
        'origin': origin,
        'destination': destination,
        'vehicle_type': vehicleType,
      });
      final data = r.data;
      if (data['success'] == true) {
        return SingleResult(
            success: true, data: FareResult.fromJson(data['data']));
      }
      return SingleResult(success: false, message: data['message']);
    } catch (e) {
      return SingleResult(success: false, message: '$e');
    }
  }

  static Future<SingleResult<LatraComplaint>> submitComplaint(
      Map<String, dynamic> body) async {
    try {
      final r = await _dio.post('/latra/complaints', data: body);
      final data = r.data;
      if (data['success'] == true) {
        return SingleResult(
            success: true, data: LatraComplaint.fromJson(data['data']));
      }
      return SingleResult(success: false, message: data['message']);
    } catch (e) {
      return SingleResult(success: false, message: '$e');
    }
  }

  static Future<PaginatedResult<LatraComplaint>> getMyComplaints({
    int page = 1,
  }) async {
    try {
      final r =
          await _dio.get('/latra/complaints', queryParameters: {'page': page});
      final data = r.data;
      if (data['success'] == true) {
        final items = (data['data'] as List)
            .map((j) => LatraComplaint.fromJson(j))
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

  static Future<PaginatedResult<TransportOperator>> searchOperators({
    String? query,
    int page = 1,
  }) async {
    try {
      final q = <String, dynamic>{'page': page};
      if (query != null) q['search'] = query;
      final r = await _dio.get('/latra/operators', queryParameters: q);
      final data = r.data;
      if (data['success'] == true) {
        final items = (data['data'] as List)
            .map((j) => TransportOperator.fromJson(j))
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
}
