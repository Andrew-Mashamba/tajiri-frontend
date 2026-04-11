// lib/police/services/police_service.dart
import 'package:dio/dio.dart';
import '../../services/authenticated_dio.dart';
import '../models/police_models.dart';

Dio get _dio => AuthenticatedDio.instance;

class PoliceService {
  // ─── Stations ───────────────────────────────────────────────

  static Future<PaginatedResult<PoliceStation>> getStations({
    int page = 1,
    String? region,
    double? lat,
    double? lng,
  }) async {
    try {
      final q = <String, dynamic>{'page': page};
      if (region != null) q['region'] = region;
      if (lat != null) q['lat'] = lat;
      if (lng != null) q['lng'] = lng;
      final r = await _dio.get('/police/stations', queryParameters: q);
      final data = r.data;
      if (data['success'] == true) {
        final items = (data['data'] as List)
            .map((j) => PoliceStation.fromJson(j))
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

  static Future<SingleResult<PoliceStation>> getStation(int id) async {
    try {
      final r = await _dio.get('/police/stations/$id');
      final data = r.data;
      if (data['success'] == true) {
        return SingleResult(
            success: true, data: PoliceStation.fromJson(data['data']));
      }
      return SingleResult(success: false, message: data['message']);
    } catch (e) {
      return SingleResult(success: false, message: '$e');
    }
  }

  // ─── Crime Reports ──────────────────────────────────────────

  static Future<PaginatedResult<CrimeReport>> getMyReports({
    int page = 1,
  }) async {
    try {
      final r = await _dio.get('/police/reports', queryParameters: {'page': page});
      final data = r.data;
      if (data['success'] == true) {
        final items = (data['data'] as List)
            .map((j) => CrimeReport.fromJson(j))
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

  static Future<SingleResult<CrimeReport>> submitReport(
      Map<String, dynamic> body) async {
    try {
      final r = await _dio.post('/police/reports', data: body);
      final data = r.data;
      if (data['success'] == true) {
        return SingleResult(
            success: true, data: CrimeReport.fromJson(data['data']));
      }
      return SingleResult(success: false, message: data['message']);
    } catch (e) {
      return SingleResult(success: false, message: '$e');
    }
  }

  // ─── Emergency Contacts ─────────────────────────────────────

  static Future<PaginatedResult<EmergencyContact>> getEmergencyContacts() async {
    try {
      final r = await _dio.get('/police/emergency-contacts');
      final data = r.data;
      if (data['success'] == true) {
        final items = (data['data'] as List)
            .map((j) => EmergencyContact.fromJson(j))
            .toList();
        return PaginatedResult(success: true, items: items);
      }
      return PaginatedResult(success: false, message: data['message']);
    } catch (e) {
      return PaginatedResult(success: false, message: '$e');
    }
  }

  static Future<SingleResult<EmergencyContact>> addEmergencyContact(
      Map<String, dynamic> body) async {
    try {
      final r = await _dio.post('/police/emergency-contacts', data: body);
      final data = r.data;
      if (data['success'] == true) {
        return SingleResult(
            success: true, data: EmergencyContact.fromJson(data['data']));
      }
      return SingleResult(success: false, message: data['message']);
    } catch (e) {
      return SingleResult(success: false, message: '$e');
    }
  }

  // ─── SOS ────────────────────────────────────────────────────

  static Future<SingleResult<void>> triggerSos({
    required double lat,
    required double lng,
  }) async {
    try {
      final r = await _dio.post('/police/sos', data: {'lat': lat, 'lng': lng});
      return SingleResult(success: r.data['success'] == true);
    } catch (e) {
      return SingleResult(success: false, message: '$e');
    }
  }
}
