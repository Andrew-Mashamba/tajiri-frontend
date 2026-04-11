// lib/rc/services/rc_service.dart
import 'package:dio/dio.dart';
import '../../services/authenticated_dio.dart';
import '../models/rc_models.dart';

class RcService {
  Dio get _dio => AuthenticatedDio.instance;

  // ─── Region ───────────────────────────────────────────────────
  Future<SingleResult<Region>> getRegion(int id) async {
    try {
      final r = await _dio.get('/rc/regions/$id');
      final d = r.data;
      if (d['success'] == true && d['data'] != null) {
        return SingleResult(success: true, data: Region.fromJson(d['data']));
      }
      return SingleResult(message: d['message'] ?? 'Not found');
    } catch (e) {
      return SingleResult(message: '$e');
    }
  }

  // ─── RC Profile ───────────────────────────────────────────────
  Future<SingleResult<RegionalCommissioner>> getRcProfile(
    int regionId,
  ) async {
    try {
      final r = await _dio.get('/rc/regions/$regionId/commissioner');
      final d = r.data;
      if (d['success'] == true && d['data'] != null) {
        return SingleResult(
          success: true,
          data: RegionalCommissioner.fromJson(d['data']),
        );
      }
      return SingleResult(message: d['message'] ?? 'Not found');
    } catch (e) {
      return SingleResult(message: '$e');
    }
  }

  // ─── Mega Projects ────────────────────────────────────────────
  Future<PaginatedResult<MegaProject>> getMegaProjects(
    int regionId, {
    int page = 1,
  }) async {
    try {
      final r = await _dio.get('/rc/projects', queryParameters: {
        'region_id': regionId,
        'page': page,
      });
      final d = r.data;
      if (d['success'] == true) {
        final items = (d['data'] as List?)
                ?.map((e) => MegaProject.fromJson(e))
                .toList() ??
            [];
        return PaginatedResult(success: true, items: items, page: page);
      }
      return PaginatedResult(message: d['message'] ?? 'Failed');
    } catch (e) {
      return PaginatedResult(message: '$e');
    }
  }

  // ─── Budget ───────────────────────────────────────────────────
  Future<SingleResult<RegionalBudget>> getBudget(
    int regionId, {
    int? year,
  }) async {
    try {
      final r = await _dio.get('/rc/regions/$regionId/budget', queryParameters: {
        if (year != null) 'year': year,
      });
      final d = r.data;
      if (d['success'] == true && d['data'] != null) {
        return SingleResult(
          success: true,
          data: RegionalBudget.fromJson(d['data']),
        );
      }
      return SingleResult(message: d['message'] ?? 'Not found');
    } catch (e) {
      return SingleResult(message: '$e');
    }
  }

  // ─── Reports ──────────────────────────────────────────────────
  Future<SingleResult<RcReport>> submitReport(
    Map<String, dynamic> data,
  ) async {
    try {
      final r = await _dio.post('/rc/reports', data: data);
      final d = r.data;
      if (d['success'] == true && d['data'] != null) {
        return SingleResult(
          success: true,
          data: RcReport.fromJson(d['data']),
        );
      }
      return SingleResult(message: d['message'] ?? 'Failed');
    } catch (e) {
      return SingleResult(message: '$e');
    }
  }

  Future<SingleResult<RcReport>> escalateComplaint(int complaintId) async {
    try {
      final r = await _dio.post('/rc/escalate/$complaintId');
      final d = r.data;
      if (d['success'] == true && d['data'] != null) {
        return SingleResult(
          success: true,
          data: RcReport.fromJson(d['data']),
        );
      }
      return SingleResult(message: d['message'] ?? 'Failed');
    } catch (e) {
      return SingleResult(message: '$e');
    }
  }

  // ─── Investments ──────────────────────────────────────────────
  Future<PaginatedResult<InvestmentOpportunity>> getInvestments(
    int regionId, {
    int page = 1,
  }) async {
    try {
      final r = await _dio.get('/rc/investments', queryParameters: {
        'region_id': regionId,
        'page': page,
      });
      final d = r.data;
      if (d['success'] == true) {
        final items = (d['data'] as List?)
                ?.map((e) => InvestmentOpportunity.fromJson(e))
                .toList() ??
            [];
        return PaginatedResult(success: true, items: items, page: page);
      }
      return PaginatedResult(message: d['message'] ?? 'Failed');
    } catch (e) {
      return PaginatedResult(message: '$e');
    }
  }

  // ─── Stats ────────────────────────────────────────────────────
  Future<SingleResult<RegionalStats>> getStats(int regionId) async {
    try {
      final r = await _dio.get('/rc/regions/$regionId/stats');
      final d = r.data;
      if (d['success'] == true && d['data'] != null) {
        return SingleResult(
          success: true,
          data: RegionalStats.fromJson(d['data']),
        );
      }
      return SingleResult(message: d['message'] ?? 'Not found');
    } catch (e) {
      return SingleResult(message: '$e');
    }
  }
}
