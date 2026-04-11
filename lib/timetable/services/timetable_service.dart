// lib/timetable/services/timetable_service.dart
import 'package:dio/dio.dart';
import '../../services/authenticated_dio.dart';
import '../models/timetable_models.dart';

class TimetableService {
  Dio get _dio => AuthenticatedDio.instance;

  Future<TimetableListResult<TimetableEntry>> getEntries({
    int? semesterId,
  }) async {
    try {
      final params = <String, dynamic>{};
      if (semesterId != null) params['semester_id'] = semesterId;
      final res =
          await _dio.get('/education/timetable', queryParameters: params);
      if (res.statusCode == 200 && res.data['success'] == true) {
        final items = (res.data['data'] as List)
            .map((j) => TimetableEntry.fromJson(j))
            .toList();
        return TimetableListResult(success: true, items: items);
      }
      return TimetableListResult(success: false, message: 'Imeshindwa kupakia');
    } catch (e) {
      return TimetableListResult(success: false, message: '$e');
    }
  }

  Future<TimetableResult<TimetableEntry>> addEntry({
    required String subject,
    required String courseCode,
    required String lecturer,
    required String room,
    String? building,
    required String day,
    required String startTime,
    required String endTime,
    int? semesterId,
    int? classId,
    int colorValue = 0xFF1A1A1A,
  }) async {
    try {
      final res = await _dio.post('/education/timetable', data: {
        'subject': subject,
        'course_code': courseCode,
        'lecturer': lecturer,
        'room': room,
        if (building != null) 'building': building,
        'day': day,
        'start_time': startTime,
        'end_time': endTime,
        if (semesterId != null) 'semester_id': semesterId,
        if (classId != null) 'class_id': classId,
        'color_value': colorValue,
      });
      if (res.statusCode == 200 && res.data['success'] == true) {
        return TimetableResult(
          success: true,
          data: TimetableEntry.fromJson(res.data['data']),
        );
      }
      return TimetableResult(success: false, message: 'Imeshindwa kuongeza');
    } catch (e) {
      return TimetableResult(success: false, message: '$e');
    }
  }

  Future<TimetableResult<void>> deleteEntry(int entryId) async {
    try {
      final res = await _dio.delete('/education/timetable/$entryId');
      if (res.statusCode == 200) {
        return TimetableResult(success: true);
      }
      return TimetableResult(success: false, message: 'Imeshindwa kufuta');
    } catch (e) {
      return TimetableResult(success: false, message: '$e');
    }
  }

  Future<TimetableListResult<Semester>> getSemesters() async {
    try {
      final res = await _dio.get('/education/semesters');
      if (res.statusCode == 200 && res.data['success'] == true) {
        final items = (res.data['data'] as List)
            .map((j) => Semester.fromJson(j))
            .toList();
        return TimetableListResult(success: true, items: items);
      }
      return TimetableListResult(success: false);
    } catch (e) {
      return TimetableListResult(success: false, message: '$e');
    }
  }

  Future<TimetableResult<Semester>> createSemester({
    required String name,
    required int year,
    required DateTime startDate,
    required DateTime endDate,
  }) async {
    try {
      final res = await _dio.post('/education/semesters', data: {
        'name': name,
        'year': year,
        'start_date': startDate.toIso8601String(),
        'end_date': endDate.toIso8601String(),
      });
      if (res.statusCode == 200 && res.data['success'] == true) {
        return TimetableResult(
          success: true,
          data: Semester.fromJson(res.data['data']),
        );
      }
      return TimetableResult(success: false);
    } catch (e) {
      return TimetableResult(success: false, message: '$e');
    }
  }
}
