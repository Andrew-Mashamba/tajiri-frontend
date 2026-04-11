// lib/passport/services/passport_service.dart
import 'package:dio/dio.dart';
import '../../services/authenticated_dio.dart';
import '../models/passport_models.dart';

Dio get _dio => AuthenticatedDio.instance;

class PassportService {
  static Future<SingleResult<PassportApplication>> trackApplication(
      String appNumber) async {
    try {
      final r = await _dio.get('/passport/track/$appNumber');
      final data = r.data;
      if (data['success'] == true) {
        return SingleResult(success: true, data: PassportApplication.fromJson(data['data']));
      }
      return SingleResult(success: false, message: data['message']);
    } catch (e) {
      return SingleResult(success: false, message: '$e');
    }
  }

  static Future<SingleResult<PassportFee>> calculateFees(
      String type, int pages, int validity) async {
    try {
      final r = await _dio.get('/passport/fees', queryParameters: {
        'type': type, 'pages': pages, 'validity': validity});
      final data = r.data;
      if (data['success'] == true) {
        return SingleResult(success: true, data: PassportFee.fromJson(data['data']));
      }
      return SingleResult(success: false, message: data['message']);
    } catch (e) {
      return SingleResult(success: false, message: '$e');
    }
  }

  static Future<PaginatedResult<VisaRequirement>> getVisaRequirements() async {
    try {
      final r = await _dio.get('/passport/visa');
      final data = r.data;
      if (data['success'] == true) {
        final items = (data['data'] as List)
            .map((j) => VisaRequirement.fromJson(j)).toList();
        return PaginatedResult(success: true, items: items);
      }
      return PaginatedResult(success: false, message: data['message']);
    } catch (e) {
      return PaginatedResult(success: false, message: '$e');
    }
  }

  static Future<PaginatedResult<Embassy>> getEmbassies() async {
    try {
      final r = await _dio.get('/passport/embassies');
      final data = r.data;
      if (data['success'] == true) {
        final items = (data['data'] as List)
            .map((j) => Embassy.fromJson(j)).toList();
        return PaginatedResult(success: true, items: items);
      }
      return PaginatedResult(success: false, message: data['message']);
    } catch (e) {
      return PaginatedResult(success: false, message: '$e');
    }
  }

  static Future<PaginatedResult<PassportInfo>> getFamilyPassports() async {
    try {
      final r = await _dio.get('/passport/family');
      final data = r.data;
      if (data['success'] == true) {
        final items = (data['data'] as List)
            .map((j) => PassportInfo.fromJson(j)).toList();
        return PaginatedResult(success: true, items: items);
      }
      return PaginatedResult(success: false, message: data['message']);
    } catch (e) {
      return PaginatedResult(success: false, message: '$e');
    }
  }
}
