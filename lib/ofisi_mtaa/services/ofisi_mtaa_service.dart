// lib/ofisi_mtaa/services/ofisi_mtaa_service.dart
import 'package:dio/dio.dart';
import '../../services/authenticated_dio.dart';
import '../models/ofisi_mtaa_models.dart';

class OfisiMtaaService {
  Dio get _dio => AuthenticatedDio.instance;

  // ─── Officials ────────────────────────────────────────────────
  Future<PaginatedResult<MtaaOfficial>> getOfficials(int mtaaId) async {
    try {
      final r = await _dio.get('/mtaa/$mtaaId/officials');
      final d = r.data;
      if (d['success'] == true) {
        final items = (d['data'] as List?)
                ?.map((e) => MtaaOfficial.fromJson(e))
                .toList() ??
            [];
        return PaginatedResult(success: true, items: items);
      }
      return PaginatedResult(message: d['message'] ?? 'Failed');
    } catch (e) {
      return PaginatedResult(message: '$e');
    }
  }

  // ─── Service Catalog ──────────────────────────────────────────
  Future<PaginatedResult<ServiceCatalog>> getServiceCatalog(int mtaaId) async {
    try {
      final r = await _dio.get('/mtaa/$mtaaId/services');
      final d = r.data;
      if (d['success'] == true) {
        final items = (d['data'] as List?)
                ?.map((e) => ServiceCatalog.fromJson(e))
                .toList() ??
            [];
        return PaginatedResult(success: true, items: items);
      }
      return PaginatedResult(message: d['message'] ?? 'Failed');
    } catch (e) {
      return PaginatedResult(message: '$e');
    }
  }

  // ─── Service Request ──────────────────────────────────────────
  Future<SingleResult<ServiceRequest>> submitRequest(
    Map<String, dynamic> data,
  ) async {
    try {
      final r = await _dio.post('/mtaa/requests', data: data);
      final d = r.data;
      if (d['success'] == true && d['data'] != null) {
        return SingleResult(
          success: true,
          data: ServiceRequest.fromJson(d['data']),
        );
      }
      return SingleResult(message: d['message'] ?? 'Failed');
    } catch (e) {
      return SingleResult(message: '$e');
    }
  }

  Future<PaginatedResult<ServiceRequest>> getMyRequests({
    int page = 1,
  }) async {
    try {
      final r = await _dio.get('/mtaa/requests/mine', queryParameters: {
        'page': page,
      });
      final d = r.data;
      if (d['success'] == true) {
        final items = (d['data'] as List?)
                ?.map((e) => ServiceRequest.fromJson(e))
                .toList() ??
            [];
        return PaginatedResult(success: true, items: items, page: page);
      }
      return PaginatedResult(message: d['message'] ?? 'Failed');
    } catch (e) {
      return PaginatedResult(message: '$e');
    }
  }

  // ─── Appointments ─────────────────────────────────────────────
  Future<SingleResult<Appointment>> bookAppointment(
    Map<String, dynamic> data,
  ) async {
    try {
      final r = await _dio.post('/mtaa/appointments', data: data);
      final d = r.data;
      if (d['success'] == true && d['data'] != null) {
        return SingleResult(
          success: true,
          data: Appointment.fromJson(d['data']),
        );
      }
      return SingleResult(message: d['message'] ?? 'Failed');
    } catch (e) {
      return SingleResult(message: '$e');
    }
  }

  Future<PaginatedResult<TimeSlot>> getAvailableSlots(
    int officialId,
    String date,
  ) async {
    try {
      final r = await _dio.get('/mtaa/appointments/slots', queryParameters: {
        'official_id': officialId,
        'date': date,
      });
      final d = r.data;
      if (d['success'] == true) {
        final items = (d['data'] as List?)
                ?.map((e) => TimeSlot.fromJson(e))
                .toList() ??
            [];
        return PaginatedResult(success: true, items: items);
      }
      return PaginatedResult(message: d['message'] ?? 'Failed');
    } catch (e) {
      return PaginatedResult(message: '$e');
    }
  }

  // ─── Notices ──────────────────────────────────────────────────
  Future<PaginatedResult<CommunityNotice>> getNotices(
    int mtaaId, {
    int page = 1,
  }) async {
    try {
      final r = await _dio.get('/mtaa/$mtaaId/notices', queryParameters: {
        'page': page,
      });
      final d = r.data;
      if (d['success'] == true) {
        final items = (d['data'] as List?)
                ?.map((e) => CommunityNotice.fromJson(e))
                .toList() ??
            [];
        return PaginatedResult(success: true, items: items, page: page);
      }
      return PaginatedResult(message: d['message'] ?? 'Failed');
    } catch (e) {
      return PaginatedResult(message: '$e');
    }
  }
}
