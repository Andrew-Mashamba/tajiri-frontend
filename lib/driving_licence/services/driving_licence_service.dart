// lib/driving_licence/services/driving_licence_service.dart
import 'package:dio/dio.dart';
import '../../services/authenticated_dio.dart';
import '../models/driving_licence_models.dart';

Dio get _dio => AuthenticatedDio.instance;

class DrivingLicenceService {
  static Future<SingleResult<DrivingLicence>> getMyLicence() async {
    try {
      final r = await _dio.get('/licence/mine');
      final data = r.data;
      if (data['success'] == true) {
        return SingleResult(success: true, data: DrivingLicence.fromJson(data['data']));
      }
      return SingleResult(success: false, message: data['message']);
    } catch (e) {
      return SingleResult(success: false, message: '$e');
    }
  }

  static Future<PaginatedResult<DrivingSchool>> getSchools({
    String? districtId, String? classCode, int page = 1}) async {
    try {
      final params = <String, dynamic>{'page': page};
      if (districtId != null) params['district_id'] = districtId;
      if (classCode != null) params['class'] = classCode;
      final r = await _dio.get('/licence/schools', queryParameters: params);
      final data = r.data;
      if (data['success'] == true) {
        final items = (data['data'] as List)
            .map((j) => DrivingSchool.fromJson(j)).toList();
        return PaginatedResult(success: true, items: items,
          currentPage: data['meta']?['current_page'] ?? page,
          lastPage: data['meta']?['last_page'] ?? 1);
      }
      return PaginatedResult(success: false, message: data['message']);
    } catch (e) {
      return PaginatedResult(success: false, message: '$e');
    }
  }

  static Future<PaginatedResult<TheoryQuestion>> getTheoryQuestions(
      {String? category}) async {
    try {
      final params = <String, dynamic>{};
      if (category != null) params['category'] = category;
      final r = await _dio.get('/licence/theory', queryParameters: params);
      final data = r.data;
      if (data['success'] == true) {
        final items = (data['data'] as List)
            .map((j) => TheoryQuestion.fromJson(j)).toList();
        return PaginatedResult(success: true, items: items);
      }
      return PaginatedResult(success: false, message: data['message']);
    } catch (e) {
      return PaginatedResult(success: false, message: '$e');
    }
  }

  static Future<PaginatedResult<TrafficFine>> getFines() async {
    try {
      final r = await _dio.get('/licence/fines');
      final data = r.data;
      if (data['success'] == true) {
        final items = (data['data'] as List)
            .map((j) => TrafficFine.fromJson(j)).toList();
        return PaginatedResult(success: true, items: items);
      }
      return PaginatedResult(success: false, message: data['message']);
    } catch (e) {
      return PaginatedResult(success: false, message: '$e');
    }
  }

  static Future<SingleResult<Map<String, dynamic>>> payFine(
      int fineId, Map<String, dynamic> body) async {
    try {
      final r = await _dio.post('/licence/fines/$fineId/pay', data: body);
      final data = r.data;
      if (data['success'] == true) {
        return SingleResult(success: true, data: data['data']);
      }
      return SingleResult(success: false, message: data['message']);
    } catch (e) {
      return SingleResult(success: false, message: '$e');
    }
  }
}
