// lib/traffic/services/traffic_service.dart
import 'package:dio/dio.dart';
import '../../services/authenticated_dio.dart';
import '../models/traffic_models.dart';

Dio get _dio => AuthenticatedDio.instance;

class TrafficService {
  static Future<PaginatedResult<TrafficReport>> getFeed({
    int page = 1,
    String? type,
  }) async {
    try {
      final q = <String, dynamic>{'page': page};
      if (type != null) q['type'] = type;
      final r = await _dio.get('/traffic/reports', queryParameters: q);
      final data = r.data;
      if (data['success'] == true) {
        final items = (data['data'] as List)
            .map((j) => TrafficReport.fromJson(j))
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

  static Future<SingleResult<TrafficReport>> submitReport(
      Map<String, dynamic> body) async {
    try {
      final r = await _dio.post('/traffic/reports', data: body);
      final data = r.data;
      if (data['success'] == true) {
        return SingleResult(
            success: true, data: TrafficReport.fromJson(data['data']));
      }
      return SingleResult(success: false, message: data['message']);
    } catch (e) {
      return SingleResult(success: false, message: '$e');
    }
  }

  static Future<SingleResult<void>> upvoteReport(int reportId) async {
    try {
      final r = await _dio.post('/traffic/reports/$reportId/upvote');
      return SingleResult(success: r.data['success'] == true);
    } catch (e) {
      return SingleResult(success: false, message: '$e');
    }
  }

  static Future<PaginatedResult<CongestionAlert>> getCongestionAlerts() async {
    try {
      final r = await _dio.get('/traffic/congestion');
      final data = r.data;
      if (data['success'] == true) {
        final items = (data['data'] as List)
            .map((j) => CongestionAlert.fromJson(j))
            .toList();
        return PaginatedResult(success: true, items: items);
      }
      return PaginatedResult(success: false, message: data['message']);
    } catch (e) {
      return PaginatedResult(success: false, message: '$e');
    }
  }
}
