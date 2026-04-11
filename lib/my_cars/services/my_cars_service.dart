// lib/my_cars/services/my_cars_service.dart
import 'package:dio/dio.dart';
import '../../services/authenticated_dio.dart';
import '../models/my_cars_models.dart';

Dio get _dio => AuthenticatedDio.instance;

class MyCarsService {
  // ─── Cars ────────────────────────────────────────────────────

  static Future<PaginatedResult<Car>> getMyCars({int page = 1}) async {
    try {
      final r = await _dio.get('/my-cars', queryParameters: {'page': page});
      final data = r.data;
      if (data['success'] == true) {
        final items =
            (data['data'] as List).map((j) => Car.fromJson(j)).toList();
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

  static Future<SingleResult<Car>> getCarDetail(int carId) async {
    try {
      final r = await _dio.get('/my-cars/$carId');
      final data = r.data;
      if (data['success'] == true) {
        return SingleResult(success: true, data: Car.fromJson(data['data']));
      }
      return SingleResult(success: false, message: data['message']);
    } catch (e) {
      return SingleResult(success: false, message: '$e');
    }
  }

  static Future<SingleResult<Car>> addCar(Map<String, dynamic> body) async {
    try {
      final r = await _dio.post('/my-cars', data: body);
      final data = r.data;
      if (data['success'] == true) {
        return SingleResult(success: true, data: Car.fromJson(data['data']));
      }
      return SingleResult(
          success: false, message: data['message'] ?? 'Imeshindwa kuongeza');
    } catch (e) {
      return SingleResult(success: false, message: '$e');
    }
  }

  static Future<SingleResult<Car>> updateCar(
      int carId, Map<String, dynamic> body) async {
    try {
      final r = await _dio.put('/my-cars/$carId', data: body);
      final data = r.data;
      if (data['success'] == true) {
        return SingleResult(success: true, data: Car.fromJson(data['data']));
      }
      return SingleResult(success: false, message: data['message']);
    } catch (e) {
      return SingleResult(success: false, message: '$e');
    }
  }

  static Future<SingleResult<void>> deleteCar(int carId) async {
    try {
      final r = await _dio.delete('/my-cars/$carId');
      return SingleResult(success: r.data['success'] == true);
    } catch (e) {
      return SingleResult(success: false, message: '$e');
    }
  }

  // ─── Documents ───────────────────────────────────────────────

  static Future<PaginatedResult<CarDocument>> getDocuments(int carId) async {
    try {
      final r = await _dio.get('/my-cars/$carId/documents');
      final data = r.data;
      if (data['success'] == true) {
        final items =
            (data['data'] as List).map((j) => CarDocument.fromJson(j)).toList();
        return PaginatedResult(success: true, items: items);
      }
      return PaginatedResult(success: false, message: data['message']);
    } catch (e) {
      return PaginatedResult(success: false, message: '$e');
    }
  }

  // ─── Service Records ────────────────────────────────────────

  static Future<PaginatedResult<CarServiceRecord>> getServiceRecords(
      int carId,
      {int page = 1}) async {
    try {
      final r = await _dio.get('/my-cars/$carId/services',
          queryParameters: {'page': page});
      final data = r.data;
      if (data['success'] == true) {
        final items = (data['data'] as List)
            .map((j) => CarServiceRecord.fromJson(j))
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

  static Future<SingleResult<CarServiceRecord>> addServiceRecord(
      int carId, Map<String, dynamic> body) async {
    try {
      final r = await _dio.post('/my-cars/$carId/services', data: body);
      final data = r.data;
      if (data['success'] == true) {
        return SingleResult(
            success: true, data: CarServiceRecord.fromJson(data['data']));
      }
      return SingleResult(success: false, message: data['message']);
    } catch (e) {
      return SingleResult(success: false, message: '$e');
    }
  }

  // ─── Fuel Logs ───────────────────────────────────────────────

  static Future<PaginatedResult<CarFuelLog>> getFuelLogs(int carId,
      {int page = 1}) async {
    try {
      final r = await _dio.get('/my-cars/$carId/fuel-logs',
          queryParameters: {'page': page});
      final data = r.data;
      if (data['success'] == true) {
        final items = (data['data'] as List)
            .map((j) => CarFuelLog.fromJson(j))
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

  static Future<SingleResult<CarFuelLog>> addFuelLog(
      int carId, Map<String, dynamic> body) async {
    try {
      final r = await _dio.post('/my-cars/$carId/fuel-logs', data: body);
      final data = r.data;
      if (data['success'] == true) {
        return SingleResult(
            success: true, data: CarFuelLog.fromJson(data['data']));
      }
      return SingleResult(success: false, message: data['message']);
    } catch (e) {
      return SingleResult(success: false, message: '$e');
    }
  }
}
