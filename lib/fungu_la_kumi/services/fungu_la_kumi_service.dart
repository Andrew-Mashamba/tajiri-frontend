// lib/fungu_la_kumi/services/fungu_la_kumi_service.dart
import 'package:dio/dio.dart';
import '../../services/authenticated_dio.dart';
import '../models/fungu_la_kumi_models.dart';

Dio get _dio => AuthenticatedDio.instance;

class FunguLaKumiService {
  // ─── Summary ────────────────────────────────────────────────

  static Future<SingleResult<GivingSummary>> getSummary() async {
    try {
      final r = await _dio.get('/fungu-la-kumi/summary');
      final data = r.data;
      if (data['success'] == true && data['data'] != null) {
        return SingleResult(
            success: true, data: GivingSummary.fromJson(data['data']));
      }
      return SingleResult(success: false, message: data['message']);
    } catch (e) {
      return SingleResult(success: false, message: '$e');
    }
  }

  // ─── Giving Records ─────────────────────────────────────────

  static Future<PaginatedResult<GivingRecord>> getHistory({
    String? type,
    int page = 1,
  }) async {
    try {
      final params = <String, dynamic>{'page': page};
      if (type != null) params['type'] = type;
      final r =
          await _dio.get('/fungu-la-kumi/records', queryParameters: params);
      final data = r.data;
      if (data['success'] == true) {
        final items = (data['data'] as List)
            .map((j) => GivingRecord.fromJson(j))
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

  static Future<SingleResult<GivingRecord>> recordGiving(
      Map<String, dynamic> body) async {
    try {
      final r = await _dio.post('/fungu-la-kumi/records', data: body);
      final data = r.data;
      if (data['success'] == true) {
        return SingleResult(
            success: true, data: GivingRecord.fromJson(data['data']));
      }
      return SingleResult(success: false, message: data['message']);
    } catch (e) {
      return SingleResult(success: false, message: '$e');
    }
  }

  // ─── Pledges ────────────────────────────────────────────────

  static Future<PaginatedResult<Pledge>> getPledges({int page = 1}) async {
    try {
      final r =
          await _dio.get('/fungu-la-kumi/pledges', queryParameters: {'page': page});
      final data = r.data;
      if (data['success'] == true) {
        final items =
            (data['data'] as List).map((j) => Pledge.fromJson(j)).toList();
        return PaginatedResult(success: true, items: items);
      }
      return PaginatedResult(success: false, message: data['message']);
    } catch (e) {
      return PaginatedResult(success: false, message: '$e');
    }
  }

  static Future<SingleResult<Pledge>> createPledge(
      Map<String, dynamic> body) async {
    try {
      final r = await _dio.post('/fungu-la-kumi/pledges', data: body);
      final data = r.data;
      if (data['success'] == true) {
        return SingleResult(
            success: true, data: Pledge.fromJson(data['data']));
      }
      return SingleResult(success: false, message: data['message']);
    } catch (e) {
      return SingleResult(success: false, message: '$e');
    }
  }
}
