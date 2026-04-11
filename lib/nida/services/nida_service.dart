// lib/nida/services/nida_service.dart
import 'package:dio/dio.dart';
import '../../services/authenticated_dio.dart';
import '../models/nida_models.dart';

Dio get _dio => AuthenticatedDio.instance;

class NidaService {
  // ─── Status Check ───────────────────────────────────────────

  static Future<SingleResult<NidaApplication>> checkStatus(
      String receiptOrNida) async {
    try {
      final r = await _dio.get('/nida/status',
          queryParameters: {'query': receiptOrNida});
      final data = r.data;
      if (data['success'] == true) {
        return SingleResult(
            success: true,
            data: NidaApplication.fromJson(data['data']));
      }
      return SingleResult(success: false, message: data['message']);
    } catch (e) {
      return SingleResult(success: false, message: '$e');
    }
  }

  // ─── Offices ────────────────────────────────────────────────

  static Future<PaginatedResult<NidaOffice>> getOffices({
    String? districtId,
    int page = 1,
  }) async {
    try {
      final params = <String, dynamic>{'page': page};
      if (districtId != null) params['district_id'] = districtId;
      final r = await _dio.get('/nida/offices', queryParameters: params);
      final data = r.data;
      if (data['success'] == true) {
        final items = (data['data'] as List)
            .map((j) => NidaOffice.fromJson(j))
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

  // ─── Document Checklist ─────────────────────────────────────

  static Future<PaginatedResult<ChecklistItem>> getChecklist(
      String type) async {
    try {
      final r = await _dio.get('/nida/checklist/$type');
      final data = r.data;
      if (data['success'] == true) {
        final items = (data['data'] as List)
            .map((j) => ChecklistItem.fromJson(j))
            .toList();
        return PaginatedResult(success: true, items: items);
      }
      return PaginatedResult(success: false, message: data['message']);
    } catch (e) {
      return PaginatedResult(success: false, message: '$e');
    }
  }

  // ─── Report Lost ────────────────────────────────────────────

  static Future<SingleResult<Map<String, dynamic>>> reportLost(
      Map<String, dynamic> body) async {
    try {
      final r = await _dio.post('/nida/lost', data: body);
      final data = r.data;
      if (data['success'] == true) {
        return SingleResult(success: true, data: data['data']);
      }
      return SingleResult(success: false, message: data['message']);
    } catch (e) {
      return SingleResult(success: false, message: '$e');
    }
  }

  // ─── Family Members ─────────────────────────────────────────

  static Future<PaginatedResult<FamilyMember>> getFamilyMembers() async {
    try {
      final r = await _dio.get('/nida/family');
      final data = r.data;
      if (data['success'] == true) {
        final items = (data['data'] as List)
            .map((j) => FamilyMember.fromJson(j))
            .toList();
        return PaginatedResult(success: true, items: items);
      }
      return PaginatedResult(success: false, message: data['message']);
    } catch (e) {
      return PaginatedResult(success: false, message: '$e');
    }
  }
}
