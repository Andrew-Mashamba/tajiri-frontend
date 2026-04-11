// lib/my_class/services/my_class_service.dart
import 'package:dio/dio.dart';
import '../../services/authenticated_dio.dart';
import '../models/my_class_models.dart';

class MyClassService {
  Dio get _dio => AuthenticatedDio.instance;

  Future<ClassListResult<StudentClass>> getMyClasses() async {
    try {
      final res = await _dio.get('/education/classes');
      if (res.statusCode == 200 && res.data['success'] == true) {
        final items = (res.data['data'] as List)
            .map((j) => StudentClass.fromJson(j))
            .toList();
        return ClassListResult(success: true, items: items);
      }
      return ClassListResult(success: false, message: 'Imeshindwa kupakia');
    } catch (e) {
      return ClassListResult(success: false, message: '$e');
    }
  }

  Future<ClassResult<StudentClass>> createClass({
    required String name,
    required String courseCode,
    required String semester,
    required int year,
    String? department,
    String? institution,
  }) async {
    try {
      final res = await _dio.post('/education/classes', data: {
        'name': name,
        'course_code': courseCode,
        'semester': semester,
        'year': year,
        if (department != null) 'department': department,
        if (institution != null) 'institution': institution,
      });
      if (res.statusCode == 200 && res.data['success'] == true) {
        return ClassResult(
          success: true,
          data: StudentClass.fromJson(res.data['data']),
        );
      }
      return ClassResult(success: false, message: 'Imeshindwa kuunda darasa');
    } catch (e) {
      return ClassResult(success: false, message: '$e');
    }
  }

  Future<ClassResult<StudentClass>> joinClass(String joinCode) async {
    try {
      final res = await _dio.post('/education/classes/join', data: {
        'join_code': joinCode,
      });
      if (res.statusCode == 200 && res.data['success'] == true) {
        return ClassResult(
          success: true,
          data: StudentClass.fromJson(res.data['data']),
        );
      }
      return ClassResult(success: false, message: 'Nambari si sahihi');
    } catch (e) {
      return ClassResult(success: false, message: '$e');
    }
  }

  Future<ClassListResult<ClassMember>> getMembers(int classId) async {
    try {
      final res = await _dio.get('/education/classes/$classId/members');
      if (res.statusCode == 200 && res.data['success'] == true) {
        final items = (res.data['data'] as List)
            .map((j) => ClassMember.fromJson(j))
            .toList();
        return ClassListResult(success: true, items: items);
      }
      return ClassListResult(success: false);
    } catch (e) {
      return ClassListResult(success: false, message: '$e');
    }
  }

  Future<ClassListResult<ClassAnnouncement>> getAnnouncements(
      int classId) async {
    try {
      final res =
          await _dio.get('/education/classes/$classId/announcements');
      if (res.statusCode == 200 && res.data['success'] == true) {
        final items = (res.data['data'] as List)
            .map((j) => ClassAnnouncement.fromJson(j))
            .toList();
        return ClassListResult(success: true, items: items);
      }
      return ClassListResult(success: false);
    } catch (e) {
      return ClassListResult(success: false, message: '$e');
    }
  }

  Future<ClassResult<ClassAnnouncement>> postAnnouncement({
    required int classId,
    required String title,
    required String body,
  }) async {
    try {
      final res = await _dio.post(
        '/education/classes/$classId/announcements',
        data: {'title': title, 'body': body},
      );
      if (res.statusCode == 200 && res.data['success'] == true) {
        return ClassResult(
          success: true,
          data: ClassAnnouncement.fromJson(res.data['data']),
        );
      }
      return ClassResult(success: false, message: 'Imeshindwa kutuma');
    } catch (e) {
      return ClassResult(success: false, message: '$e');
    }
  }

  Future<ClassListResult<LecturerProfile>> getLecturers(int classId) async {
    try {
      final res = await _dio.get('/education/classes/$classId/lecturers');
      if (res.statusCode == 200 && res.data['success'] == true) {
        final items = (res.data['data'] as List)
            .map((j) => LecturerProfile.fromJson(j))
            .toList();
        return ClassListResult(success: true, items: items);
      }
      return ClassListResult(success: false);
    } catch (e) {
      return ClassListResult(success: false, message: '$e');
    }
  }
}
