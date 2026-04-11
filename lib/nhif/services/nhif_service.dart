// lib/nhif/services/nhif_service.dart
import 'package:dio/dio.dart';
import '../../services/authenticated_dio.dart';
import '../models/nhif_models.dart';

Dio get _dio => AuthenticatedDio.instance;

class NhifService {
  static Future<SingleResult<NhifMembership>> verifyMembership(String query) async {
    try {
      final r = await _dio.get('/nhif/verify', queryParameters: {'query': query});
      final d = r.data;
      if (d['success'] == true) return SingleResult(success: true, data: NhifMembership.fromJson(d['data']));
      return SingleResult(success: false, message: d['message']);
    } catch (e) { return SingleResult(success: false, message: '$e'); }
  }

  static Future<PaginatedResult<AccreditedFacility>> findFacilities({String? type, int page = 1}) async {
    try {
      final params = <String, dynamic>{'page': page};
      if (type != null) params['type'] = type;
      final r = await _dio.get('/nhif/facilities', queryParameters: params);
      final d = r.data;
      if (d['success'] == true) {
        final items = (d['data'] as List).map((j) => AccreditedFacility.fromJson(j)).toList();
        return PaginatedResult(success: true, items: items,
          currentPage: d['meta']?['current_page'] ?? page, lastPage: d['meta']?['last_page'] ?? 1);
      }
      return PaginatedResult(success: false, message: d['message']);
    } catch (e) { return PaginatedResult(success: false, message: '$e'); }
  }

  static Future<PaginatedResult<Claim>> getClaimsHistory({int page = 1}) async {
    try {
      final r = await _dio.get('/nhif/claims', queryParameters: {'page': page});
      final d = r.data;
      if (d['success'] == true) {
        final items = (d['data'] as List).map((j) => Claim.fromJson(j)).toList();
        return PaginatedResult(success: true, items: items);
      }
      return PaginatedResult(success: false, message: d['message']);
    } catch (e) { return PaginatedResult(success: false, message: '$e'); }
  }

  static Future<SingleResult<Map<String, dynamic>>> payPremium(Map<String, dynamic> body) async {
    try {
      final r = await _dio.post('/nhif/payments', data: body);
      final d = r.data;
      if (d['success'] == true) return SingleResult(success: true, data: d['data']);
      return SingleResult(success: false, message: d['message']);
    } catch (e) { return SingleResult(success: false, message: '$e'); }
  }

  static Future<PaginatedResult<Dependent>> getDependents() async {
    try {
      final r = await _dio.get('/nhif/dependents');
      final d = r.data;
      if (d['success'] == true) {
        final items = (d['data'] as List).map((j) => Dependent.fromJson(j)).toList();
        return PaginatedResult(success: true, items: items);
      }
      return PaginatedResult(success: false, message: d['message']);
    } catch (e) { return PaginatedResult(success: false, message: '$e'); }
  }

  static Future<PaginatedResult<Drug>> searchDrugs(String query) async {
    try {
      final r = await _dio.get('/nhif/drugs', queryParameters: {'query': query});
      final d = r.data;
      if (d['success'] == true) {
        final items = (d['data'] as List).map((j) => Drug.fromJson(j)).toList();
        return PaginatedResult(success: true, items: items);
      }
      return PaginatedResult(success: false, message: d['message']);
    } catch (e) { return PaginatedResult(success: false, message: '$e'); }
  }
}
