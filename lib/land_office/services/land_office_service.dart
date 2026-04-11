// lib/land_office/services/land_office_service.dart
import 'package:dio/dio.dart';
import '../../services/authenticated_dio.dart';
import '../models/land_office_models.dart';

Dio get _dio => AuthenticatedDio.instance;

class LandOfficeService {
  static Future<PaginatedResult<Plot>> searchPlot(
      {String? plotNumber, String? location, int page = 1}) async {
    try {
      final params = <String, dynamic>{'page': page};
      if (plotNumber != null) params['plot_number'] = plotNumber;
      if (location != null) params['location'] = location;
      final r = await _dio.get('/land/search', queryParameters: params);
      final data = r.data;
      if (data['success'] == true) {
        final items = (data['data'] as List).map((j) => Plot.fromJson(j)).toList();
        return PaginatedResult(success: true, items: items,
          currentPage: data['meta']?['current_page'] ?? page,
          lastPage: data['meta']?['last_page'] ?? 1);
      }
      return PaginatedResult(success: false, message: data['message']);
    } catch (e) {
      return PaginatedResult(success: false, message: '$e');
    }
  }

  static Future<SingleResult<TitleDeed>> verifyTitle(String certNo) async {
    try {
      final r = await _dio.get('/land/verify', queryParameters: {'certificate_number': certNo});
      final data = r.data;
      if (data['success'] == true) {
        return SingleResult(success: true, data: TitleDeed.fromJson(data['data']));
      }
      return SingleResult(success: false, message: data['message']);
    } catch (e) {
      return SingleResult(success: false, message: '$e');
    }
  }

  static Future<PaginatedResult<FraudAlert>> getFraudAlerts({String? districtId}) async {
    try {
      final params = <String, dynamic>{};
      if (districtId != null) params['district_id'] = districtId;
      final r = await _dio.get('/land/fraud-alerts', queryParameters: params);
      final data = r.data;
      if (data['success'] == true) {
        final items = (data['data'] as List).map((j) => FraudAlert.fromJson(j)).toList();
        return PaginatedResult(success: true, items: items);
      }
      return PaginatedResult(success: false, message: data['message']);
    } catch (e) {
      return PaginatedResult(success: false, message: '$e');
    }
  }

  static Future<PaginatedResult<Surveyor>> getSurveyors({String? districtId}) async {
    try {
      final params = <String, dynamic>{};
      if (districtId != null) params['district_id'] = districtId;
      final r = await _dio.get('/land/surveyors', queryParameters: params);
      final data = r.data;
      if (data['success'] == true) {
        final items = (data['data'] as List).map((j) => Surveyor.fromJson(j)).toList();
        return PaginatedResult(success: true, items: items);
      }
      return PaginatedResult(success: false, message: data['message']);
    } catch (e) {
      return PaginatedResult(success: false, message: '$e');
    }
  }

  static Future<SingleResult<FraudAlert>> reportFraud(Map<String, dynamic> body) async {
    try {
      final r = await _dio.post('/land/fraud-alerts', data: body);
      final data = r.data;
      if (data['success'] == true) {
        return SingleResult(success: true, data: FraudAlert.fromJson(data['data']));
      }
      return SingleResult(success: false, message: data['message']);
    } catch (e) {
      return SingleResult(success: false, message: '$e');
    }
  }
}
