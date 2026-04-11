// lib/dc/services/dc_service.dart
import 'package:dio/dio.dart';
import '../../services/authenticated_dio.dart';
import '../models/dc_models.dart';

class DcService {
  Dio get _dio => AuthenticatedDio.instance;

  // ─── District ─────────────────────────────────────────────────
  Future<SingleResult<District>> getDistrict(int id) async {
    try {
      final r = await _dio.get('/dc/districts/$id');
      final d = r.data;
      if (d['success'] == true && d['data'] != null) {
        return SingleResult(success: true, data: District.fromJson(d['data']));
      }
      return SingleResult(message: d['message'] ?? 'Not found');
    } catch (e) {
      return SingleResult(message: '$e');
    }
  }

  // ─── DC Profile ───────────────────────────────────────────────
  Future<SingleResult<DistrictCommissioner>> getDcProfile(
    int districtId,
  ) async {
    try {
      final r = await _dio.get('/dc/districts/$districtId/commissioner');
      final d = r.data;
      if (d['success'] == true && d['data'] != null) {
        return SingleResult(
          success: true,
          data: DistrictCommissioner.fromJson(d['data']),
        );
      }
      return SingleResult(message: d['message'] ?? 'Not found');
    } catch (e) {
      return SingleResult(message: '$e');
    }
  }

  // ─── Projects ─────────────────────────────────────────────────
  Future<PaginatedResult<DistrictProject>> getProjects(
    int districtId, {
    String? sector,
    int page = 1,
  }) async {
    try {
      final r = await _dio.get('/dc/projects', queryParameters: {
        'district_id': districtId,
        if (sector != null) 'sector': sector,
        'page': page,
      });
      final d = r.data;
      if (d['success'] == true) {
        final items = (d['data'] as List?)
                ?.map((e) => DistrictProject.fromJson(e))
                .toList() ??
            [];
        return PaginatedResult(success: true, items: items, page: page);
      }
      return PaginatedResult(message: d['message'] ?? 'Failed');
    } catch (e) {
      return PaginatedResult(message: '$e');
    }
  }

  // ─── Complaints ───────────────────────────────────────────────
  Future<SingleResult<DistrictComplaint>> submitComplaint(
    Map<String, dynamic> data,
  ) async {
    try {
      final r = await _dio.post('/dc/complaints', data: data);
      final d = r.data;
      if (d['success'] == true && d['data'] != null) {
        return SingleResult(
          success: true,
          data: DistrictComplaint.fromJson(d['data']),
        );
      }
      return SingleResult(message: d['message'] ?? 'Failed');
    } catch (e) {
      return SingleResult(message: '$e');
    }
  }

  Future<PaginatedResult<DistrictComplaint>> getMyComplaints({
    int page = 1,
  }) async {
    try {
      final r = await _dio.get('/dc/complaints/mine', queryParameters: {
        'page': page,
      });
      final d = r.data;
      if (d['success'] == true) {
        final items = (d['data'] as List?)
                ?.map((e) => DistrictComplaint.fromJson(e))
                .toList() ??
            [];
        return PaginatedResult(success: true, items: items, page: page);
      }
      return PaginatedResult(message: d['message'] ?? 'Failed');
    } catch (e) {
      return PaginatedResult(message: '$e');
    }
  }

  // ─── Alerts ───────────────────────────────────────────────────
  Future<PaginatedResult<EmergencyAlert>> getAlerts(int districtId) async {
    try {
      final r = await _dio.get('/dc/alerts', queryParameters: {
        'district_id': districtId,
      });
      final d = r.data;
      if (d['success'] == true) {
        final items = (d['data'] as List?)
                ?.map((e) => EmergencyAlert.fromJson(e))
                .toList() ??
            [];
        return PaginatedResult(success: true, items: items);
      }
      return PaginatedResult(message: d['message'] ?? 'Failed');
    } catch (e) {
      return PaginatedResult(message: '$e');
    }
  }

  // ─── Stats ────────────────────────────────────────────────────
  Future<SingleResult<DistrictStats>> getStats(int districtId) async {
    try {
      final r = await _dio.get('/dc/districts/$districtId/stats');
      final d = r.data;
      if (d['success'] == true && d['data'] != null) {
        return SingleResult(
          success: true,
          data: DistrictStats.fromJson(d['data']),
        );
      }
      return SingleResult(message: d['message'] ?? 'Not found');
    } catch (e) {
      return SingleResult(message: '$e');
    }
  }

  // ─── Departments ──────────────────────────────────────────────
  Future<PaginatedResult<Department>> getDepartments(int districtId) async {
    try {
      final r = await _dio.get('/dc/districts/$districtId/departments');
      final d = r.data;
      if (d['success'] == true) {
        final items = (d['data'] as List?)
                ?.map((e) => Department.fromJson(e))
                .toList() ??
            [];
        return PaginatedResult(success: true, items: items);
      }
      return PaginatedResult(message: d['message'] ?? 'Failed');
    } catch (e) {
      return PaginatedResult(message: '$e');
    }
  }
}
