// lib/barozi_wangu/services/barozi_wangu_service.dart
import 'package:dio/dio.dart';
import '../../services/authenticated_dio.dart';
import '../models/barozi_wangu_models.dart';

class BaroziWanguService {
  Dio get _dio => AuthenticatedDio.instance;

  // ─── Councillor ───────────────────────────────────────────────
  Future<SingleResult<Councillor>> getCouncillor(int wardId) async {
    try {
      final r = await _dio.get('/barozi/councillor/$wardId');
      final d = r.data;
      if (d['success'] == true && d['data'] != null) {
        return SingleResult(
          success: true,
          data: Councillor.fromJson(d['data']),
        );
      }
      return SingleResult(message: d['message'] ?? 'Councillor not found');
    } catch (e) {
      return SingleResult(message: '$e');
    }
  }

  // ─── Issues ───────────────────────────────────────────────────
  Future<SingleResult<WardIssue>> reportIssue(Map<String, dynamic> data) async {
    try {
      final r = await _dio.post('/barozi/issues', data: data);
      final d = r.data;
      if (d['success'] == true && d['data'] != null) {
        return SingleResult(
          success: true,
          data: WardIssue.fromJson(d['data']),
        );
      }
      return SingleResult(message: d['message'] ?? 'Failed to report issue');
    } catch (e) {
      return SingleResult(message: '$e');
    }
  }

  Future<PaginatedResult<WardIssue>> getIssues(
    int wardId, {
    String? status,
    String? category,
    int page = 1,
  }) async {
    try {
      final r = await _dio.get('/barozi/issues', queryParameters: {
        'ward_id': wardId,
        if (status != null) 'status': status,
        if (category != null) 'category': category,
        'page': page,
      });
      final d = r.data;
      if (d['success'] == true) {
        final items = (d['data'] as List?)
                ?.map((e) => WardIssue.fromJson(e))
                .toList() ??
            [];
        return PaginatedResult(
          success: true,
          items: items,
          total: (d['total'] as num?)?.toInt() ?? items.length,
          page: page,
        );
      }
      return PaginatedResult(message: d['message'] ?? 'Failed');
    } catch (e) {
      return PaginatedResult(message: '$e');
    }
  }

  // ─── Promises ─────────────────────────────────────────────────
  Future<PaginatedResult<CampaignPromise>> getPromises(
    int councillorId, {
    int page = 1,
  }) async {
    try {
      final r = await _dio.get('/barozi/promises', queryParameters: {
        'councillor_id': councillorId,
        'page': page,
      });
      final d = r.data;
      if (d['success'] == true) {
        final items = (d['data'] as List?)
                ?.map((e) => CampaignPromise.fromJson(e))
                .toList() ??
            [];
        return PaginatedResult(success: true, items: items, page: page);
      }
      return PaginatedResult(message: d['message'] ?? 'Failed');
    } catch (e) {
      return PaginatedResult(message: '$e');
    }
  }

  // ─── Rate councillor ─────────────────────────────────────────
  Future<SingleResult<PerformanceScore>> rateCouncillor(
    int councillorId,
    Map<String, dynamic> scores,
  ) async {
    try {
      final r = await _dio.post(
        '/barozi/councillors/$councillorId/rate',
        data: scores,
      );
      final d = r.data;
      if (d['success'] == true && d['data'] != null) {
        return SingleResult(
          success: true,
          data: PerformanceScore.fromJson(d['data']),
        );
      }
      return SingleResult(message: d['message'] ?? 'Failed');
    } catch (e) {
      return SingleResult(message: '$e');
    }
  }

  // ─── Projects ─────────────────────────────────────────────────
  Future<PaginatedResult<DevelopmentProject>> getProjects(
    int wardId, {
    int page = 1,
  }) async {
    try {
      final r = await _dio.get('/barozi/projects', queryParameters: {
        'ward_id': wardId,
        'page': page,
      });
      final d = r.data;
      if (d['success'] == true) {
        final items = (d['data'] as List?)
                ?.map((e) => DevelopmentProject.fromJson(e))
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
