// lib/jumuiya/services/jumuiya_service.dart
import 'package:dio/dio.dart';
import '../../services/authenticated_dio.dart';
import '../models/jumuiya_models.dart';

Dio get _dio => AuthenticatedDio.instance;

class JumuiyaService {
  // ─── My Groups ──────────────────────────────────────────────

  static Future<PaginatedResult<JumuiyaGroup>> getMyGroups(
      {int page = 1}) async {
    try {
      final r =
          await _dio.get('/jumuiya/my-groups', queryParameters: {'page': page});
      final data = r.data;
      if (data['success'] == true) {
        final items = (data['data'] as List)
            .map((j) => JumuiyaGroup.fromJson(j))
            .toList();
        return PaginatedResult(success: true, items: items);
      }
      return PaginatedResult(success: false, message: data['message']);
    } catch (e) {
      return PaginatedResult(success: false, message: '$e');
    }
  }

  // ─── Discover ───────────────────────────────────────────────

  static Future<PaginatedResult<JumuiyaGroup>> discover(
      {String? search, int page = 1}) async {
    try {
      final params = <String, dynamic>{'page': page};
      if (search != null) params['q'] = search;
      final r =
          await _dio.get('/jumuiya/discover', queryParameters: params);
      final data = r.data;
      if (data['success'] == true) {
        final items = (data['data'] as List)
            .map((j) => JumuiyaGroup.fromJson(j))
            .toList();
        return PaginatedResult(success: true, items: items);
      }
      return PaginatedResult(success: false, message: data['message']);
    } catch (e) {
      return PaginatedResult(success: false, message: '$e');
    }
  }

  // ─── Join / Leave ───────────────────────────────────────────

  static Future<SingleResult<void>> joinGroup(int groupId) async {
    try {
      final r = await _dio.post('/jumuiya/$groupId/join');
      return SingleResult(success: r.data['success'] == true);
    } catch (e) {
      return SingleResult(success: false, message: '$e');
    }
  }

  // ─── Members ────────────────────────────────────────────────

  static Future<PaginatedResult<JumuiyaMember>> getMembers(int groupId,
      {int page = 1}) async {
    try {
      final r = await _dio.get('/jumuiya/$groupId/members',
          queryParameters: {'page': page});
      final data = r.data;
      if (data['success'] == true) {
        final items = (data['data'] as List)
            .map((j) => JumuiyaMember.fromJson(j))
            .toList();
        return PaginatedResult(success: true, items: items);
      }
      return PaginatedResult(success: false, message: data['message']);
    } catch (e) {
      return PaginatedResult(success: false, message: '$e');
    }
  }

  // ─── Meetings ───────────────────────────────────────────────

  static Future<PaginatedResult<JumuiyaMeeting>> getMeetings(int groupId,
      {int page = 1}) async {
    try {
      final r = await _dio.get('/jumuiya/$groupId/meetings',
          queryParameters: {'page': page});
      final data = r.data;
      if (data['success'] == true) {
        final items = (data['data'] as List)
            .map((j) => JumuiyaMeeting.fromJson(j))
            .toList();
        return PaginatedResult(success: true, items: items);
      }
      return PaginatedResult(success: false, message: data['message']);
    } catch (e) {
      return PaginatedResult(success: false, message: '$e');
    }
  }
}
