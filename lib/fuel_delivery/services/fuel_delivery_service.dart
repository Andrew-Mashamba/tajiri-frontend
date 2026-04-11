// lib/fuel_delivery/services/fuel_delivery_service.dart
import 'package:dio/dio.dart';
import '../../services/authenticated_dio.dart';
import '../models/fuel_delivery_models.dart';

Dio get _dio => AuthenticatedDio.instance;

class FuelDeliveryService {
  // ─── Fuel Prices ─────────────────────────────────────────────

  static Future<PaginatedResult<FuelPrice>> getFuelPrices(
      {String? region}) async {
    try {
      final r = await _dio.get('/fuel-delivery/prices',
          queryParameters: {if (region != null) 'region': region});
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

  // ─── Orders ──────────────────────────────────────────────────

  static Future<SingleResult<FuelOrder>> placeOrder(
      Map<String, dynamic> body) async {
    try {
      final r = await _dio.post('/fuel-delivery/orders', data: body);
      final data = r.data;
      if (data['success'] == true) {
        return SingleResult(
            success: true, data: FuelOrder.fromJson(data['data']));
      }
      return SingleResult(success: false, message: data['message']);
    } catch (e) {
      return SingleResult(success: false, message: '$e');
    }
  }

  static Future<PaginatedResult<FuelOrder>> getMyOrders(
      {int page = 1}) async {
    try {
      final r = await _dio.get('/fuel-delivery/orders',
          queryParameters: {'page': page});
      final data = r.data;
      if (data['success'] == true) {
        final items = (data['data'] as List)
            .map((j) => FuelOrder.fromJson(j))
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

  static Future<SingleResult<FuelOrder>> getOrderDetail(int orderId) async {
    try {
      final r = await _dio.get('/fuel-delivery/orders/$orderId');
      final data = r.data;
      if (data['success'] == true) {
        return SingleResult(
            success: true, data: FuelOrder.fromJson(data['data']));
      }
      return SingleResult(success: false, message: data['message']);
    } catch (e) {
      return SingleResult(success: false, message: '$e');
    }
  }

  static Future<SingleResult<void>> cancelOrder(int orderId) async {
    try {
      final r = await _dio.post('/fuel-delivery/orders/$orderId/cancel');
      return SingleResult(success: r.data['success'] == true);
    } catch (e) {
      return SingleResult(success: false, message: '$e');
    }
  }

  // ─── Delivery Fee ────────────────────────────────────────────

  static Future<SingleResult<double>> estimateDeliveryFee({
    required double latitude,
    required double longitude,
    required double liters,
  }) async {
    try {
      final r = await _dio.post('/fuel-delivery/estimate-fee', data: {
        'latitude': latitude,
        'longitude': longitude,
        'liters': liters,
      });
      final data = r.data;
      if (data['success'] == true) {
        return SingleResult(
            success: true,
            data: (data['data']['fee'] as num?)?.toDouble() ?? 0);
      }
      return SingleResult(success: false, message: data['message']);
    } catch (e) {
      return SingleResult(success: false, message: '$e');
    }
  }
}
