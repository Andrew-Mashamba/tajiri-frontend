// lib/results/services/results_service.dart
import 'package:dio/dio.dart';
import '../../services/authenticated_dio.dart';
import '../models/results_models.dart';

class ResultsService {
  Dio get _dio => AuthenticatedDio.instance;

  Future<ResultsDataResult<GpaSummary>> getGpaSummary() async {
    try {
      final res = await _dio.get('/education/results/summary');
      if (res.statusCode == 200 && res.data['success'] == true) {
        return ResultsDataResult(
          success: true,
          data: GpaSummary.fromJson(res.data['data']),
        );
      }
      return ResultsDataResult(success: false, message: 'Imeshindwa kupakia');
    } catch (e) {
      return ResultsDataResult(success: false, message: '$e');
    }
  }

  Future<ResultsListResult<SemesterResult>> getSemesters() async {
    try {
      final res = await _dio.get('/education/results/semesters');
      if (res.statusCode == 200 && res.data['success'] == true) {
        final items = (res.data['data'] as List)
            .map((j) => SemesterResult.fromJson(j))
            .toList();
        return ResultsListResult(success: true, items: items);
      }
      return ResultsListResult(success: false);
    } catch (e) {
      return ResultsListResult(success: false, message: '$e');
    }
  }

  Future<ResultsDataResult<CourseGrade>> addGrade({
    required String courseName,
    required String courseCode,
    required String grade,
    required double gradePoint,
    required int creditHours,
    required int semesterId,
    required String semester,
    required int year,
  }) async {
    try {
      final res = await _dio.post('/education/results/grades', data: {
        'course_name': courseName,
        'course_code': courseCode,
        'grade': grade,
        'grade_point': gradePoint,
        'credit_hours': creditHours,
        'semester_id': semesterId,
        'semester': semester,
        'year': year,
      });
      if (res.statusCode == 200 && res.data['success'] == true) {
        return ResultsDataResult(
          success: true,
          data: CourseGrade.fromJson(res.data['data']),
        );
      }
      return ResultsDataResult(success: false, message: 'Imeshindwa kuongeza');
    } catch (e) {
      return ResultsDataResult(success: false, message: '$e');
    }
  }

  Future<ResultsDataResult<NectaResult>> checkNectaResults({
    required String examNumber,
    required String examType,
    required int year,
  }) async {
    try {
      final res = await _dio.post('/education/results/necta', data: {
        'exam_number': examNumber,
        'exam_type': examType,
        'year': year,
      });
      if (res.statusCode == 200 && res.data['success'] == true) {
        return ResultsDataResult(
          success: true,
          data: NectaResult.fromJson(res.data['data']),
        );
      }
      return ResultsDataResult(success: false, message: 'Matokeo hayapatikani');
    } catch (e) {
      return ResultsDataResult(success: false, message: '$e');
    }
  }

  Future<ResultsDataResult<double>> whatIfCalculation({
    required List<Map<String, dynamic>> hypotheticalGrades,
  }) async {
    try {
      final res = await _dio.post('/education/results/what-if', data: {
        'grades': hypotheticalGrades,
      });
      if (res.statusCode == 200 && res.data['success'] == true) {
        final gpa = (res.data['data']['projected_gpa'] as num?)?.toDouble();
        return ResultsDataResult(success: true, data: gpa);
      }
      return ResultsDataResult(success: false);
    } catch (e) {
      return ResultsDataResult(success: false, message: '$e');
    }
  }
}
