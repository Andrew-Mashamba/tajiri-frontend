// lib/kanisa_langu/services/kanisa_langu_service.dart
import 'package:dio/dio.dart';
import '../../services/authenticated_dio.dart';
import '../models/kanisa_langu_models.dart';

Dio get _dio => AuthenticatedDio.instance;

class KanisaLanguService {
  // ─── Church Profile ─────────────────────────────────────────

  static Future<SingleResult<ChurchProfile>> getMyChurch() async {
    try {
      final r = await _dio.get('/kanisa-langu/my-church');
      final data = r.data;
      if (data['success'] == true && data['data'] != null) {
        return SingleResult(
            success: true, data: ChurchProfile.fromJson(data['data']));
      }
      return SingleResult(success: false, message: data['message']);
    } catch (e) {
      return SingleResult(success: false, message: '$e');
    }
  }

  static Future<SingleResult<ChurchProfile>> getChurch(int churchId) async {
    try {
      final r = await _dio.get('/kanisa-langu/$churchId');
      final data = r.data;
      if (data['success'] == true && data['data'] != null) {
        return SingleResult(
            success: true, data: ChurchProfile.fromJson(data['data']));
      }
      return SingleResult(success: false, message: data['message']);
    } catch (e) {
      return SingleResult(success: false, message: '$e');
    }
  }

  static Future<SingleResult<void>> joinChurch(int churchId) async {
    try {
      final r = await _dio.post('/kanisa-langu/$churchId/join');
      return SingleResult(success: r.data['success'] == true);
    } catch (e) {
      return SingleResult(success: false, message: '$e');
    }
  }

  // ─── Announcements ──────────────────────────────────────────

  static Future<PaginatedResult<ChurchAnnouncement>> getAnnouncements(
      int churchId,
      {int page = 1}) async {
    try {
      final r = await _dio.get('/kanisa-langu/$churchId/announcements',
          queryParameters: {'page': page});
      final data = r.data;
      if (data['success'] == true) {
        final items = (data['data'] as List)
            .map((j) => ChurchAnnouncement.fromJson(j))
            .toList();
        return PaginatedResult(success: true, items: items);
      }
      return PaginatedResult(success: false, message: data['message']);
    } catch (e) {
      return PaginatedResult(success: false, message: '$e');
    }
  }

  // ─── Events ─────────────────────────────────────────────────

  static Future<PaginatedResult<ChurchEvent>> getEvents(int churchId,
      {int page = 1}) async {
    try {
      final r = await _dio.get('/kanisa-langu/$churchId/events',
          queryParameters: {'page': page});
      final data = r.data;
      if (data['success'] == true) {
        final items = (data['data'] as List)
            .map((j) => ChurchEvent.fromJson(j))
            .toList();
        return PaginatedResult(success: true, items: items);
      }
      return PaginatedResult(success: false, message: data['message']);
    } catch (e) {
      return PaginatedResult(success: false, message: '$e');
    }
  }

  // ─── Members ────────────────────────────────────────────────

  static Future<PaginatedResult<ChurchMember>> getMembers(int churchId,
      {int page = 1}) async {
    try {
      final r = await _dio.get('/kanisa-langu/$churchId/members',
          queryParameters: {'page': page});
      final data = r.data;
      if (data['success'] == true) {
        final items = (data['data'] as List)
            .map((j) => ChurchMember.fromJson(j))
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
}
