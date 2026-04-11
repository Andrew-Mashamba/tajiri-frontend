// lib/nssf/services/nssf_service.dart
import 'package:dio/dio.dart';
import '../../services/authenticated_dio.dart';
import '../models/nssf_models.dart';

Dio get _dio => AuthenticatedDio.instance;

class NssfService {
  static Future<SingleResult<NssfMembership>> getMembership() async {
    try {
      final r = await _dio.get('/nssf/membership');
      final d = r.data;
      if (d['success'] == true) return SingleResult(success: true, data: NssfMembership.fromJson(d['data']));
      return SingleResult(success: false, message: d['message']);
    } catch (e) { return SingleResult(success: false, message: '$e'); }
  }

  static Future<PaginatedResult<Contribution>> getContributions({int? year, int page = 1}) async {
    try {
      final params = <String, dynamic>{'page': page};
      if (year != null) params['year'] = year;
      final r = await _dio.get('/nssf/contributions', queryParameters: params);
      final d = r.data;
      if (d['success'] == true) {
        final items = (d['data'] as List).map((j) => Contribution.fromJson(j)).toList();
        return PaginatedResult(success: true, items: items,
          currentPage: d['meta']?['current_page'] ?? page, lastPage: d['meta']?['last_page'] ?? 1);
      }
      return PaginatedResult(success: false, message: d['message']);
    } catch (e) { return PaginatedResult(success: false, message: '$e'); }
  }

  static Future<SingleResult<PensionProjection>> calculatePension(Map<String, dynamic> params) async {
    try {
      final r = await _dio.post('/nssf/pension-calc', data: params);
      final d = r.data;
      if (d['success'] == true) return SingleResult(success: true, data: PensionProjection.fromJson(d['data']));
      return SingleResult(success: false, message: d['message']);
    } catch (e) { return SingleResult(success: false, message: '$e'); }
  }

  static Future<SingleResult<EmployerCompliance>> checkEmployer(String query) async {
    try {
      final r = await _dio.get('/nssf/employer-check', queryParameters: {'query': query});
      final d = r.data;
      if (d['success'] == true) return SingleResult(success: true, data: EmployerCompliance.fromJson(d['data']));
      return SingleResult(success: false, message: d['message']);
    } catch (e) { return SingleResult(success: false, message: '$e'); }
  }

  static Future<PaginatedResult<Nominee>> getNominees() async {
    try {
      final r = await _dio.get('/nssf/nominees');
      final d = r.data;
      if (d['success'] == true) {
        final items = (d['data'] as List).map((j) => Nominee.fromJson(j)).toList();
        return PaginatedResult(success: true, items: items);
      }
      return PaginatedResult(success: false, message: d['message']);
    } catch (e) { return PaginatedResult(success: false, message: '$e'); }
  }

  static Future<SingleResult<Map<String, dynamic>>> payVoluntary(Map<String, dynamic> body) async {
    try {
      final r = await _dio.post('/nssf/payments', data: body);
      final d = r.data;
      if (d['success'] == true) return SingleResult(success: true, data: d['data']);
      return SingleResult(success: false, message: d['message']);
    } catch (e) { return SingleResult(success: false, message: '$e'); }
  }
}
