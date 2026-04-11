// lib/necta/services/necta_service.dart
import 'package:dio/dio.dart';
import '../../services/authenticated_dio.dart';
import '../models/necta_models.dart';

Dio get _dio => AuthenticatedDio.instance;

class NectaService {
  static Future<SingleResult<ExamResult>> checkResults({
    required String candidateNumber,
    required String examType,
    required int year,
  }) async {
    try {
      final r = await _dio.get('/necta/results', queryParameters: {
        'candidate_number': candidateNumber,
        'exam_type': examType,
        'year': year,
      });
      final data = r.data;
      if (data['success'] == true) {
        return SingleResult(
            success: true, data: ExamResult.fromJson(data['data']));
      }
      return SingleResult(success: false, message: data['message']);
    } catch (e) {
      return SingleResult(success: false, message: '$e');
    }
  }

  static Future<PaginatedResult<PastPaper>> getPastPapers({
    String? examType,
    String? subject,
    int page = 1,
  }) async {
    try {
      final q = <String, dynamic>{'page': page};
      if (examType != null) q['exam_type'] = examType;
      if (subject != null) q['subject'] = subject;
      final r = await _dio.get('/necta/past-papers', queryParameters: q);
      final data = r.data;
      if (data['success'] == true) {
        final items = (data['data'] as List)
            .map((j) => PastPaper.fromJson(j))
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

  static Future<PaginatedResult<SchoolStats>> getSchoolStats({
    String? region,
    int? year,
    int page = 1,
  }) async {
    try {
      final q = <String, dynamic>{'page': page};
      if (region != null) q['region'] = region;
      if (year != null) q['year'] = year;
      final r = await _dio.get('/necta/school-stats', queryParameters: q);
      final data = r.data;
      if (data['success'] == true) {
        final items = (data['data'] as List)
            .map((j) => SchoolStats.fromJson(j))
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
