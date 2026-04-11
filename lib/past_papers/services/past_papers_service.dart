// lib/past_papers/services/past_papers_service.dart
import 'package:dio/dio.dart';
import '../../services/authenticated_dio.dart';
import '../models/past_papers_models.dart';

class PastPapersService {
  Dio get _dio => AuthenticatedDio.instance;

  Future<PapersListResult<PastPaper>> getPapers({
    String? subject,
    int? year,
    String? level,
    String? examType,
    String? institution,
    String? search,
    int page = 1,
  }) async {
    try {
      final params = <String, dynamic>{'page': page};
      if (subject != null) params['subject'] = subject;
      if (year != null) params['year'] = year;
      if (level != null) params['level'] = level;
      if (examType != null) params['exam_type'] = examType;
      if (institution != null) params['institution'] = institution;
      if (search != null && search.isNotEmpty) params['search'] = search;
      final res =
          await _dio.get('/education/past-papers', queryParameters: params);
      if (res.statusCode == 200 && res.data['success'] == true) {
        final items = (res.data['data'] as List)
            .map((j) => PastPaper.fromJson(j))
            .toList();
        return PapersListResult(success: true, items: items);
      }
      return PapersListResult(success: false, message: 'Imeshindwa kupakia');
    } catch (e) {
      return PapersListResult(success: false, message: '$e');
    }
  }

  Future<PapersResult<PastPaper>> uploadPaper({
    required String filePath,
    required String subject,
    required int year,
    required String level,
    required String examType,
    String? courseCode,
    String? institution,
  }) async {
    try {
      final formData = FormData.fromMap({
        'file': await MultipartFile.fromFile(filePath),
        'subject': subject,
        'year': year,
        'level': level,
        'exam_type': examType,
        if (courseCode != null) 'course_code': courseCode,
        if (institution != null) 'institution': institution,
      });
      final res = await _dio.post('/education/past-papers', data: formData);
      if (res.statusCode == 200 && res.data['success'] == true) {
        return PapersResult(
          success: true,
          data: PastPaper.fromJson(res.data['data']),
        );
      }
      return PapersResult(success: false, message: 'Imeshindwa kupakia');
    } catch (e) {
      return PapersResult(success: false, message: '$e');
    }
  }

  Future<PapersResult<void>> bookmarkPaper(int paperId) async {
    try {
      final res =
          await _dio.post('/education/past-papers/$paperId/bookmark');
      return PapersResult(success: res.statusCode == 200);
    } catch (e) {
      return PapersResult(success: false, message: '$e');
    }
  }

  Future<PapersResult<void>> ratePaper({
    required int paperId,
    required int difficulty,
  }) async {
    try {
      final res = await _dio.post(
        '/education/past-papers/$paperId/rate',
        data: {'difficulty': difficulty},
      );
      return PapersResult(success: res.statusCode == 200);
    } catch (e) {
      return PapersResult(success: false, message: '$e');
    }
  }

  Future<PapersListResult<PaperRequest>> getRequests() async {
    try {
      final res = await _dio.get('/education/past-papers/requests');
      if (res.statusCode == 200 && res.data['success'] == true) {
        final items = (res.data['data'] as List)
            .map((j) => PaperRequest.fromJson(j))
            .toList();
        return PapersListResult(success: true, items: items);
      }
      return PapersListResult(success: false);
    } catch (e) {
      return PapersListResult(success: false, message: '$e');
    }
  }

  Future<PapersListResult<PastPaper>> getBookmarked() async {
    try {
      final res = await _dio.get('/education/past-papers/bookmarked');
      if (res.statusCode == 200 && res.data['success'] == true) {
        final items = (res.data['data'] as List)
            .map((j) => PastPaper.fromJson(j))
            .toList();
        return PapersListResult(success: true, items: items);
      }
      return PapersListResult(success: false);
    } catch (e) {
      return PapersListResult(success: false, message: '$e');
    }
  }
}
