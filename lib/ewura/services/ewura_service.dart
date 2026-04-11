// lib/ewura/services/ewura_service.dart
import 'package:dio/dio.dart';
import '../../services/authenticated_dio.dart';
import '../models/ewura_models.dart';

Dio get _dio => AuthenticatedDio.instance;

class EwuraService {
  static Future<PaginatedResult<FuelPrice>> getFuelPrices({
    String? region,
    String? fuelType,
  }) async {
    try {
      final q = <String, dynamic>{};
      if (region != null) q['region'] = region;
      if (fuelType != null) q['fuel_type'] = fuelType;
      final r = await _dio.get('/ewura/fuel-prices', queryParameters: q);
      final data = r.data;
      if (data['success'] == true) {
        final items = (data['data'] as List)
            .map((j) => FuelPrice.fromJson(j))
            .toList();
        return PaginatedResult(success: true, items: items);
      }
      return PaginatedResult(success: false, message: data['message']);
    } catch (e) {
      return PaginatedResult(success: false, message: '$e');
    }
  }

  static Future<PaginatedResult<FuelStation>> getStations({
    int page = 1,
    String? region,
    double? lat,
    double? lng,
  }) async {
    try {
      final q = <String, dynamic>{'page': page};
      if (region != null) q['region'] = region;
      if (lat != null) q['lat'] = lat;
      if (lng != null) q['lng'] = lng;
      final r = await _dio.get('/ewura/stations', queryParameters: q);
      final data = r.data;
      if (data['success'] == true) {
        final items = (data['data'] as List)
            .map((j) => FuelStation.fromJson(j))
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

  static Future<PaginatedResult<UtilityTariff>> getTariffs({
    String? utilityType,
  }) async {
    try {
      final q = <String, dynamic>{};
      if (utilityType != null) q['utility_type'] = utilityType;
      final r = await _dio.get('/ewura/tariffs', queryParameters: q);
      final data = r.data;
      if (data['success'] == true) {
        final items = (data['data'] as List)
            .map((j) => UtilityTariff.fromJson(j))
            .toList();
        return PaginatedResult(success: true, items: items);
      }
      return PaginatedResult(success: false, message: data['message']);
    } catch (e) {
      return PaginatedResult(success: false, message: '$e');
    }
  }
}
