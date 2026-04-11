// lib/shule_ya_jumapili/services/shule_ya_jumapili_service.dart
import 'package:dio/dio.dart';
import '../../services/authenticated_dio.dart';
import '../models/shule_ya_jumapili_models.dart';

Dio get _dio => AuthenticatedDio.instance;

class ShuleYaJumapiliService {
  // ─── Lessons ────────────────────────────────────────────────

  static Future<PaginatedResult<SundaySchoolLesson>> getLessons({
    String? ageGroup,
    int page = 1,
  }) async {
    try {
      final params = <String, dynamic>{'page': page};
      if (ageGroup != null) params['age_group'] = ageGroup;
      final r = await _dio.get('/shule-ya-jumapili/lessons',
          queryParameters: params);
      final data = r.data;
      if (data['success'] == true) {
        final items = (data['data'] as List)
            .map((j) => SundaySchoolLesson.fromJson(j))
            .toList();
        return PaginatedResult(success: true, items: items);
      }
      return PaginatedResult(success: false, message: data['message']);
    } catch (e) {
      return PaginatedResult(success: false, message: '$e');
    }
  }

  static Future<SingleResult<SundaySchoolLesson>> getLesson(
      int lessonId) async {
    try {
      final r = await _dio.get('/shule-ya-jumapili/lessons/$lessonId');
      final data = r.data;
      if (data['success'] == true && data['data'] != null) {
        return SingleResult(
            success: true, data: SundaySchoolLesson.fromJson(data['data']));
      }
      return SingleResult(success: false, message: data['message']);
    } catch (e) {
      return SingleResult(success: false, message: '$e');
    }
  }

  // ─── Children ───────────────────────────────────────────────

  static Future<PaginatedResult<ChildProfile>> getChildren(
      {int page = 1}) async {
    try {
      final r = await _dio.get('/shule-ya-jumapili/children',
          queryParameters: {'page': page});
      final data = r.data;
      if (data['success'] == true) {
        final items = (data['data'] as List)
            .map((j) => ChildProfile.fromJson(j))
            .toList();
        return PaginatedResult(success: true, items: items);
      }
      return PaginatedResult(success: false, message: data['message']);
    } catch (e) {
      return PaginatedResult(success: false, message: '$e');
    }
  }

  // ─── Attendance ─────────────────────────────────────────────

  static Future<PaginatedResult<AttendanceRecord>> getAttendance(
      {int page = 1}) async {
    try {
      final r = await _dio.get('/shule-ya-jumapili/attendance',
          queryParameters: {'page': page});
      final data = r.data;
      if (data['success'] == true) {
        final items = (data['data'] as List)
            .map((j) => AttendanceRecord.fromJson(j))
            .toList();
        return PaginatedResult(success: true, items: items);
      }
      return PaginatedResult(success: false, message: data['message']);
    } catch (e) {
      return PaginatedResult(success: false, message: '$e');
    }
  }

  static Future<SingleResult<void>> markAttendance(
      Map<String, dynamic> body) async {
    try {
      final r =
          await _dio.post('/shule-ya-jumapili/attendance', data: body);
      return SingleResult(success: r.data['success'] == true);
    } catch (e) {
      return SingleResult(success: false, message: '$e');
    }
  }
}
