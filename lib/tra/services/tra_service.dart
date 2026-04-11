// lib/tra/services/tra_service.dart
import 'package:dio/dio.dart';
import '../../services/authenticated_dio.dart';
import '../models/tra_models.dart';

Dio get _dio => AuthenticatedDio.instance;

class TraService {
  static Future<SingleResult<TaxProfile>> lookupTin(String query) async {
    try {
      final r = await _dio.get('/tra/tin/lookup', queryParameters: {'query': query});
      final data = r.data;
      if (data['success'] == true) {
        return SingleResult(success: true, data: TaxProfile.fromJson(data['data']));
      }
      return SingleResult(success: false, message: data['message']);
    } catch (e) {
      return SingleResult(success: false, message: '$e');
    }
  }

  static Future<SingleResult<TaxBreakdown>> calculateTax(
      String type, Map<String, dynamic> params) async {
    try {
      final r = await _dio.post('/tra/calculate', data: {'type': type, ...params});
      final data = r.data;
      if (data['success'] == true) {
        return SingleResult(success: true, data: TaxBreakdown.fromJson(data['data']));
      }
      return SingleResult(success: false, message: data['message']);
    } catch (e) {
      return SingleResult(success: false, message: '$e');
    }
  }

  static Future<SingleResult<TaxPayment>> makePayment(
      Map<String, dynamic> body) async {
    try {
      final r = await _dio.post('/tra/payments', data: body);
      final data = r.data;
      if (data['success'] == true) {
        return SingleResult(success: true, data: TaxPayment.fromJson(data['data']));
      }
      return SingleResult(success: false, message: data['message']);
    } catch (e) {
      return SingleResult(success: false, message: '$e');
    }
  }

  static Future<PaginatedResult<TaxPayment>> getPaymentHistory(
      {int page = 1}) async {
    try {
      final r = await _dio.get('/tra/payments', queryParameters: {'page': page});
      final data = r.data;
      if (data['success'] == true) {
        final items = (data['data'] as List)
            .map((j) => TaxPayment.fromJson(j)).toList();
        return PaginatedResult(success: true, items: items,
          currentPage: data['meta']?['current_page'] ?? page,
          lastPage: data['meta']?['last_page'] ?? 1);
      }
      return PaginatedResult(success: false, message: data['message']);
    } catch (e) {
      return PaginatedResult(success: false, message: '$e');
    }
  }

  static Future<PaginatedResult<TaxDeadline>> getDeadlines() async {
    try {
      final r = await _dio.get('/tra/deadlines');
      final data = r.data;
      if (data['success'] == true) {
        final items = (data['data'] as List)
            .map((j) => TaxDeadline.fromJson(j)).toList();
        return PaginatedResult(success: true, items: items);
      }
      return PaginatedResult(success: false, message: data['message']);
    } catch (e) {
      return PaginatedResult(success: false, message: '$e');
    }
  }

  static Future<SingleResult<TaxProfile>> getCompliance() async {
    try {
      final r = await _dio.get('/tra/compliance');
      final data = r.data;
      if (data['success'] == true) {
        return SingleResult(success: true, data: TaxProfile.fromJson(data['data']));
      }
      return SingleResult(success: false, message: data['message']);
    } catch (e) {
      return SingleResult(success: false, message: '$e');
    }
  }
}
