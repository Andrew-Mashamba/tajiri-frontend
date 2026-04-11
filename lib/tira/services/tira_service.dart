// lib/tira/services/tira_service.dart
import 'package:dio/dio.dart';
import '../../services/authenticated_dio.dart';
import '../models/tira_models.dart';

Dio get _dio => AuthenticatedDio.instance;

class TiraService {
  static Future<SingleResult<InsurancePolicy>> verifyPolicy(
      String policyNumber) async {
    try {
      final r = await _dio.get('/tira/verify',
          queryParameters: {'policy_number': policyNumber});
      final data = r.data;
      if (data['success'] == true) {
        return SingleResult(
            success: true, data: InsurancePolicy.fromJson(data['data']));
      }
      return SingleResult(success: false, message: data['message']);
    } catch (e) {
      return SingleResult(success: false, message: '$e');
    }
  }

  static Future<PaginatedResult<Insurer>> getInsurers({
    int page = 1,
    String? search,
  }) async {
    try {
      final q = <String, dynamic>{'page': page};
      if (search != null) q['search'] = search;
      final r = await _dio.get('/tira/insurers', queryParameters: q);
      final data = r.data;
      if (data['success'] == true) {
        final items =
            (data['data'] as List).map((j) => Insurer.fromJson(j)).toList();
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

  static Future<SingleResult<TiraComplaint>> submitComplaint(
      Map<String, dynamic> body) async {
    try {
      final r = await _dio.post('/tira/complaints', data: body);
      final data = r.data;
      if (data['success'] == true) {
        return SingleResult(
            success: true, data: TiraComplaint.fromJson(data['data']));
      }
      return SingleResult(success: false, message: data['message']);
    } catch (e) {
      return SingleResult(success: false, message: '$e');
    }
  }

  static Future<PaginatedResult<TiraComplaint>> getMyComplaints() async {
    try {
      final r = await _dio.get('/tira/complaints');
      final data = r.data;
      if (data['success'] == true) {
        final items = (data['data'] as List)
            .map((j) => TiraComplaint.fromJson(j))
            .toList();
        return PaginatedResult(success: true, items: items);
      }
      return PaginatedResult(success: false, message: data['message']);
    } catch (e) {
      return PaginatedResult(success: false, message: '$e');
    }
  }
}
