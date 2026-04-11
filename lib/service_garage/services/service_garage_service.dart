// lib/service_garage/services/service_garage_service.dart
import 'package:dio/dio.dart';
import '../../services/authenticated_dio.dart';
import '../models/service_garage_models.dart';

Dio get _dio => AuthenticatedDio.instance;

class ServiceGarageService {
  // ─── Garages ─────────────────────────────────────────────────

  static Future<PaginatedResult<Garage>> getGarages({
    int page = 1,
    String? search,
    String? serviceType,
    String? specialization,
    double? latitude,
    double? longitude,
    double? radiusKm,
  }) async {
    try {
      final r = await _dio.get('/service-garages', queryParameters: {
        'page': page,
        if (search != null) 'search': search,
        if (serviceType != null) 'service_type': serviceType,
        if (specialization != null) 'specialization': specialization,
        if (latitude != null) 'latitude': latitude,
        if (longitude != null) 'longitude': longitude,
        if (radiusKm != null) 'radius_km': radiusKm,
      });
      final data = r.data;
      if (data['success'] == true) {
        final items =
            (data['data'] as List).map((j) => Garage.fromJson(j)).toList();
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

  static Future<SingleResult<Garage>> getGarageDetail(int garageId) async {
    try {
      final r = await _dio.get('/service-garages/$garageId');
      final data = r.data;
      if (data['success'] == true) {
        return SingleResult(
            success: true, data: Garage.fromJson(data['data']));
      }
      return SingleResult(success: false, message: data['message']);
    } catch (e) {
      return SingleResult(success: false, message: '$e');
    }
  }

  // ─── Reviews ─────────────────────────────────────────────────

  static Future<PaginatedResult<GarageReview>> getGarageReviews(
      int garageId,
      {int page = 1}) async {
    try {
      final r = await _dio.get('/service-garages/$garageId/reviews',
          queryParameters: {'page': page});
      final data = r.data;
      if (data['success'] == true) {
        final items = (data['data'] as List)
            .map((j) => GarageReview.fromJson(j))
            .toList();
        return PaginatedResult(success: true, items: items);
      }
      return PaginatedResult(success: false, message: data['message']);
    } catch (e) {
      return PaginatedResult(success: false, message: '$e');
    }
  }

  // ─── Bookings ────────────────────────────────────────────────

  static Future<PaginatedResult<ServiceBooking>> getMyBookings(
      {int page = 1}) async {
    try {
      final r = await _dio.get('/service-garages/bookings',
          queryParameters: {'page': page});
      final data = r.data;
      if (data['success'] == true) {
        final items = (data['data'] as List)
            .map((j) => ServiceBooking.fromJson(j))
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

  static Future<SingleResult<ServiceBooking>> bookService(
      Map<String, dynamic> body) async {
    try {
      final r = await _dio.post('/service-garages/bookings', data: body);
      final data = r.data;
      if (data['success'] == true) {
        return SingleResult(
            success: true, data: ServiceBooking.fromJson(data['data']));
      }
      return SingleResult(success: false, message: data['message']);
    } catch (e) {
      return SingleResult(success: false, message: '$e');
    }
  }

  static Future<SingleResult<void>> cancelBooking(int bookingId) async {
    try {
      final r =
          await _dio.post('/service-garages/bookings/$bookingId/cancel');
      return SingleResult(success: r.data['success'] == true);
    } catch (e) {
      return SingleResult(success: false, message: '$e');
    }
  }

  static Future<SingleResult<void>> submitReview(
      int garageId, Map<String, dynamic> body) async {
    try {
      final r = await _dio.post('/service-garages/$garageId/reviews',
          data: body);
      return SingleResult(success: r.data['success'] == true);
    } catch (e) {
      return SingleResult(success: false, message: '$e');
    }
  }
}
