// lib/alerts/services/alerts_service.dart
import 'package:dio/dio.dart';
import '../../services/authenticated_dio.dart';
import '../models/alerts_models.dart';

Dio get _dio => AuthenticatedDio.instance;

class AlertsService {
  static Future<PaginatedResult<EmergencyAlert>> getAlerts({
    int page = 1,
    String? type,
  }) async {
    try {
      final q = <String, dynamic>{'page': page};
      if (type != null) q['type'] = type;
      final r = await _dio.get('/alerts', queryParameters: q);
      final data = r.data;
      if (data['success'] == true) {
        final items = (data['data'] as List)
            .map((j) => EmergencyAlert.fromJson(j))
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

  static Future<PaginatedResult<FamilyCheckIn>> getFamilyCheckIns() async {
    try {
      final r = await _dio.get('/alerts/family-checkins');
      final data = r.data;
      if (data['success'] == true) {
        final items = (data['data'] as List)
            .map((j) => FamilyCheckIn.fromJson(j))
            .toList();
        return PaginatedResult(success: true, items: items);
      }
      return PaginatedResult(success: false, message: data['message']);
    } catch (e) {
      return PaginatedResult(success: false, message: '$e');
    }
  }

  static Future<SingleResult<void>> checkIn({
    required String status,
    String? message,
  }) async {
    try {
      final r = await _dio.post('/alerts/checkin', data: {
        'status': status,
        if (message != null) 'message': message,
      });
      return SingleResult(success: r.data['success'] == true);
    } catch (e) {
      return SingleResult(success: false, message: '$e');
    }
  }

  static Future<SingleResult<void>> requestFamilyCheckIn() async {
    try {
      final r = await _dio.post('/alerts/family-checkins/request');
      return SingleResult(success: r.data['success'] == true);
    } catch (e) {
      return SingleResult(success: false, message: '$e');
    }
  }
}
