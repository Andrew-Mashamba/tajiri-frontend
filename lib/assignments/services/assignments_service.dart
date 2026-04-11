// lib/assignments/services/assignments_service.dart
import 'package:dio/dio.dart';
import '../../services/authenticated_dio.dart';
import '../models/assignments_models.dart';

class AssignmentsService {
  Dio get _dio => AuthenticatedDio.instance;

  Future<AssignmentListResult<Assignment>> getAssignments({
    String? subject,
    String? status,
    int page = 1,
  }) async {
    try {
      final params = <String, dynamic>{'page': page};
      if (subject != null) params['subject'] = subject;
      if (status != null) params['status'] = status;
      final res =
          await _dio.get('/education/assignments', queryParameters: params);
      if (res.statusCode == 200 && res.data['success'] == true) {
        final items = (res.data['data'] as List)
            .map((j) => Assignment.fromJson(j))
            .toList();
        return AssignmentListResult(success: true, items: items);
      }
      return AssignmentListResult(success: false, message: 'Imeshindwa kupakia');
    } catch (e) {
      return AssignmentListResult(success: false, message: '$e');
    }
  }

  Future<AssignmentResult<Assignment>> createAssignment({
    required String title,
    required String description,
    required String subject,
    String? courseCode,
    int? classId,
    required String priority,
    required DateTime dueDate,
    double? maxGrade,
  }) async {
    try {
      final res = await _dio.post('/education/assignments', data: {
        'title': title,
        'description': description,
        'subject': subject,
        if (courseCode != null) 'course_code': courseCode,
        if (classId != null) 'class_id': classId,
        'priority': priority,
        'due_date': dueDate.toIso8601String(),
        if (maxGrade != null) 'max_grade': maxGrade,
      });
      if (res.statusCode == 200 && res.data['success'] == true) {
        return AssignmentResult(
          success: true,
          data: Assignment.fromJson(res.data['data']),
        );
      }
      return AssignmentResult(success: false, message: 'Imeshindwa kuunda');
    } catch (e) {
      return AssignmentResult(success: false, message: '$e');
    }
  }

  Future<AssignmentResult<Assignment>> updateStatus({
    required int assignmentId,
    required String status,
    double? grade,
  }) async {
    try {
      final res = await _dio.put('/education/assignments/$assignmentId', data: {
        'status': status,
        if (grade != null) 'grade': grade,
      });
      if (res.statusCode == 200 && res.data['success'] == true) {
        return AssignmentResult(
          success: true,
          data: Assignment.fromJson(res.data['data']),
        );
      }
      return AssignmentResult(success: false);
    } catch (e) {
      return AssignmentResult(success: false, message: '$e');
    }
  }

  Future<AssignmentResult<void>> deleteAssignment(int id) async {
    try {
      final res = await _dio.delete('/education/assignments/$id');
      return AssignmentResult(success: res.statusCode == 200);
    } catch (e) {
      return AssignmentResult(success: false, message: '$e');
    }
  }

  Future<AssignmentListResult<GradeSummary>> getGradesSummary() async {
    try {
      final res = await _dio.get('/education/assignments/grades-summary');
      if (res.statusCode == 200 && res.data['success'] == true) {
        final items = (res.data['data'] as List)
            .map((j) => GradeSummary.fromJson(j))
            .toList();
        return AssignmentListResult(success: true, items: items);
      }
      return AssignmentListResult(success: false);
    } catch (e) {
      return AssignmentListResult(success: false, message: '$e');
    }
  }
}
