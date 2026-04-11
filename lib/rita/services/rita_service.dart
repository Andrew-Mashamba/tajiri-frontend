// lib/rita/services/rita_service.dart
import 'package:dio/dio.dart';
import '../../services/authenticated_dio.dart';
import '../models/rita_models.dart';

Dio get _dio => AuthenticatedDio.instance;

class RitaService {
  // ─── Applications ───────────────────────────────────────────

  static Future<SingleResult<CertificateApplication>> applyForCertificate(
      Map<String, dynamic> body) async {
    try {
      final r = await _dio.post('/rita/applications', data: body);
      final data = r.data;
      if (data['success'] == true) {
        return SingleResult(
            success: true, data: CertificateApplication.fromJson(data['data']));
      }
      return SingleResult(success: false, message: data['message']);
    } catch (e) {
      return SingleResult(success: false, message: '$e');
    }
  }

  static Future<SingleResult<CertificateApplication>> trackApplication(
      String trackingNo) async {
    try {
      final r = await _dio.get('/rita/applications/$trackingNo');
      final data = r.data;
      if (data['success'] == true) {
        return SingleResult(
            success: true, data: CertificateApplication.fromJson(data['data']));
      }
      return SingleResult(success: false, message: data['message']);
    } catch (e) {
      return SingleResult(success: false, message: '$e');
    }
  }

  static Future<PaginatedResult<CertificateApplication>> getMyApplications(
      {int page = 1}) async {
    try {
      final r = await _dio.get('/rita/applications/mine',
          queryParameters: {'page': page});
      final data = r.data;
      if (data['success'] == true) {
        final items = (data['data'] as List)
            .map((j) => CertificateApplication.fromJson(j))
            .toList();
        return PaginatedResult(
          success: true, items: items,
          currentPage: data['meta']?['current_page'] ?? page,
          lastPage: data['meta']?['last_page'] ?? 1,
        );
      }
      return PaginatedResult(success: false, message: data['message']);
    } catch (e) {
      return PaginatedResult(success: false, message: '$e');
    }
  }

  // ─── Fees ───────────────────────────────────────────────────

  static Future<SingleResult<FeeBreakdown>> calculateFees(
      String type, Map<String, dynamic> params) async {
    try {
      final qp = <String, dynamic>{'type': type, ...params};
      final r = await _dio.get('/rita/fees', queryParameters: qp);
      final data = r.data;
      if (data['success'] == true) {
        return SingleResult(
            success: true, data: FeeBreakdown.fromJson(data['data']));
      }
      return SingleResult(success: false, message: data['message']);
    } catch (e) {
      return SingleResult(success: false, message: '$e');
    }
  }

  // ─── Family Records ─────────────────────────────────────────

  static Future<PaginatedResult<FamilyRecord>> getFamilyRecords() async {
    try {
      final r = await _dio.get('/rita/family');
      final data = r.data;
      if (data['success'] == true) {
        final items = (data['data'] as List)
            .map((j) => FamilyRecord.fromJson(j))
            .toList();
        return PaginatedResult(success: true, items: items);
      }
      return PaginatedResult(success: false, message: data['message']);
    } catch (e) {
      return PaginatedResult(success: false, message: '$e');
    }
  }

  // ─── Offices ────────────────────────────────────────────────

  static Future<PaginatedResult<RitaOffice>> getOffices(
      {String? districtId, int page = 1}) async {
    try {
      final params = <String, dynamic>{'page': page};
      if (districtId != null) params['district_id'] = districtId;
      final r = await _dio.get('/rita/offices', queryParameters: params);
      final data = r.data;
      if (data['success'] == true) {
        final items = (data['data'] as List)
            .map((j) => RitaOffice.fromJson(j))
            .toList();
        return PaginatedResult(success: true, items: items,
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
