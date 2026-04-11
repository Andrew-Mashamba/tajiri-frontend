// lib/rent_car/services/rent_car_service.dart
import 'package:dio/dio.dart';
import '../../services/authenticated_dio.dart';
import '../models/rent_car_models.dart';

class RentCarService {
  Dio get _dio => AuthenticatedDio.instance;

  // ─── Vehicles ─────────────────────────────────────────────────

  Future<PaginatedResult<RentalVehicle>> searchVehicles({
    String? category,
    String? location,
    String? pickupDate,
    String? returnDate,
    double? minPrice,
    double? maxPrice,
    int page = 1,
  }) async {
    try {
      final params = <String, dynamic>{'page': page};
      if (category != null) params['category'] = category;
      if (location != null) params['location'] = location;
      if (pickupDate != null) params['pickup_date'] = pickupDate;
      if (returnDate != null) params['return_date'] = returnDate;
      if (minPrice != null) params['min_price'] = minPrice;
      if (maxPrice != null) params['max_price'] = maxPrice;

      final resp = await _dio.get('/rent-car/vehicles', queryParameters: params);
      final data = resp.data;
      if (data['success'] == true) {
        final list = (data['data'] as List)
            .map((j) => RentalVehicle.fromJson(j))
            .toList();
        return PaginatedResult(
          success: true,
          items: list,
          currentPage: data['current_page'] ?? page,
          lastPage: data['last_page'] ?? 1,
        );
      }
      return PaginatedResult(success: false, message: data['message']);
    } catch (e) {
      return PaginatedResult(success: false, message: '$e');
    }
  }

  Future<SingleResult<RentalVehicle>> getVehicle(int id) async {
    try {
      final resp = await _dio.get('/rent-car/vehicles/$id');
      final data = resp.data;
      if (data['success'] == true) {
        return SingleResult(success: true, data: RentalVehicle.fromJson(data['data']));
      }
      return SingleResult(success: false, message: data['message']);
    } catch (e) {
      return SingleResult(success: false, message: '$e');
    }
  }

  // ─── Bookings ─────────────────────────────────────────────────

  Future<SingleResult<RentalBooking>> createBooking({
    required int vehicleId,
    required String pickupDate,
    required String returnDate,
    String? pickupLocation,
    String? returnLocation,
    String insuranceTier = 'basic',
    int? chauffeurId,
  }) async {
    try {
      final resp = await _dio.post('/rent-car/bookings', data: {
        'vehicle_id': vehicleId,
        'pickup_date': pickupDate,
        'return_date': returnDate,
        if (pickupLocation != null) 'pickup_location': pickupLocation,
        if (returnLocation != null) 'return_location': returnLocation,
        'insurance_tier': insuranceTier,
        if (chauffeurId != null) 'chauffeur_id': chauffeurId,
      });
      final data = resp.data;
      if (data['success'] == true) {
        return SingleResult(success: true, data: RentalBooking.fromJson(data['data']));
      }
      return SingleResult(success: false, message: data['message']);
    } catch (e) {
      return SingleResult(success: false, message: '$e');
    }
  }

  Future<PaginatedResult<RentalBooking>> getMyBookings({int page = 1}) async {
    try {
      final resp = await _dio.get('/rent-car/bookings', queryParameters: {'page': page});
      final data = resp.data;
      if (data['success'] == true) {
        final list = (data['data'] as List)
            .map((j) => RentalBooking.fromJson(j))
            .toList();
        return PaginatedResult(success: true, items: list);
      }
      return PaginatedResult(success: false, message: data['message']);
    } catch (e) {
      return PaginatedResult(success: false, message: '$e');
    }
  }

  Future<SingleResult<RentalBooking>> getBooking(int id) async {
    try {
      final resp = await _dio.get('/rent-car/bookings/$id');
      final data = resp.data;
      if (data['success'] == true) {
        return SingleResult(success: true, data: RentalBooking.fromJson(data['data']));
      }
      return SingleResult(success: false, message: data['message']);
    } catch (e) {
      return SingleResult(success: false, message: '$e');
    }
  }

  // ─── Chauffeurs ───────────────────────────────────────────────

  Future<PaginatedResult<Chauffeur>> getChauffeurs({
    String? language,
    bool? safariGuide,
    int page = 1,
  }) async {
    try {
      final params = <String, dynamic>{'page': page};
      if (language != null) params['language'] = language;
      if (safariGuide == true) params['safari_guide'] = 1;

      final resp = await _dio.get('/rent-car/chauffeurs', queryParameters: params);
      final data = resp.data;
      if (data['success'] == true) {
        final list = (data['data'] as List)
            .map((j) => Chauffeur.fromJson(j))
            .toList();
        return PaginatedResult(success: true, items: list);
      }
      return PaginatedResult(success: false, message: data['message']);
    } catch (e) {
      return PaginatedResult(success: false, message: '$e');
    }
  }

  // ─── Host ─────────────────────────────────────────────────────

  Future<SingleResult<Map<String, dynamic>>> getHostDashboard() async {
    try {
      final resp = await _dio.get('/rent-car/host/dashboard');
      final data = resp.data;
      if (data['success'] == true) {
        return SingleResult(success: true, data: data['data']);
      }
      return SingleResult(success: false, message: data['message']);
    } catch (e) {
      return SingleResult(success: false, message: '$e');
    }
  }

  Future<SingleResult<RentalVehicle>> listCarForRent(Map<String, dynamic> vehicleData) async {
    try {
      final resp = await _dio.post('/rent-car/host/vehicles', data: vehicleData);
      final data = resp.data;
      if (data['success'] == true) {
        return SingleResult(success: true, data: RentalVehicle.fromJson(data['data']));
      }
      return SingleResult(success: false, message: data['message']);
    } catch (e) {
      return SingleResult(success: false, message: '$e');
    }
  }

  // ─── Roadside Assistance ──────────────────────────────────────

  Future<SingleResult<Map<String, dynamic>>> requestRoadsideAssistance(int bookingId) async {
    try {
      final resp = await _dio.post('/rent-car/roadside', data: {'booking_id': bookingId});
      final data = resp.data;
      if (data['success'] == true) {
        return SingleResult(success: true, data: data['data']);
      }
      return SingleResult(success: false, message: data['message']);
    } catch (e) {
      return SingleResult(success: false, message: '$e');
    }
  }
}
