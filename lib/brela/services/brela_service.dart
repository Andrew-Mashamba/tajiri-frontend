// lib/brela/services/brela_service.dart
import 'package:dio/dio.dart';
import '../../services/authenticated_dio.dart';
import '../models/brela_models.dart';

Dio get _dio => AuthenticatedDio.instance;

class BrelaService {
  static Future<PaginatedResult<NameResult>> searchName(String query) async {
    try {
      final r = await _dio.get('/brela/names/search',
          queryParameters: {'query': query});
      final data = r.data;
      if (data['success'] == true) {
        final items = (data['data'] as List)
            .map((j) => NameResult.fromJson(j)).toList();
        return PaginatedResult(success: true, items: items);
      }
      return PaginatedResult(success: false, message: data['message']);
    } catch (e) {
      return PaginatedResult(success: false, message: '$e');
    }
  }

  static Future<SingleResult<NameReservation>> reserveName(String name) async {
    try {
      final r = await _dio.post('/brela/names/reserve', data: {'name': name});
      final data = r.data;
      if (data['success'] == true) {
        return SingleResult(success: true, data: NameReservation.fromJson(data['data']));
      }
      return SingleResult(success: false, message: data['message']);
    } catch (e) {
      return SingleResult(success: false, message: '$e');
    }
  }

  static Future<PaginatedResult<Business>> getMyBusinesses({int page = 1}) async {
    try {
      final r = await _dio.get('/brela/businesses/mine',
          queryParameters: {'page': page});
      final data = r.data;
      if (data['success'] == true) {
        final items = (data['data'] as List)
            .map((j) => Business.fromJson(j)).toList();
        return PaginatedResult(success: true, items: items,
          currentPage: data['meta']?['current_page'] ?? page,
          lastPage: data['meta']?['last_page'] ?? 1);
      }
      return PaginatedResult(success: false, message: data['message']);
    } catch (e) {
      return PaginatedResult(success: false, message: '$e');
    }
  }

  static Future<SingleResult<Business>> registerBusiness(
      Map<String, dynamic> body) async {
    try {
      final r = await _dio.post('/brela/register', data: body);
      final data = r.data;
      if (data['success'] == true) {
        return SingleResult(success: true, data: Business.fromJson(data['data']));
      }
      return SingleResult(success: false, message: data['message']);
    } catch (e) {
      return SingleResult(success: false, message: '$e');
    }
  }

  static Future<PaginatedResult<ComplianceItem>> getComplianceItems(
      int businessId) async {
    try {
      final r = await _dio.get('/brela/compliance',
          queryParameters: {'business_id': businessId});
      final data = r.data;
      if (data['success'] == true) {
        final items = (data['data'] as List)
            .map((j) => ComplianceItem.fromJson(j)).toList();
        return PaginatedResult(success: true, items: items);
      }
      return PaginatedResult(success: false, message: data['message']);
    } catch (e) {
      return PaginatedResult(success: false, message: '$e');
    }
  }
}
