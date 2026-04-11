// lib/transport/services/transport_service.dart
import 'dart:convert';
import 'package:http/http.dart' as http;
import '../../config/api_config.dart';
import '../models/transport_models.dart';

String get _baseUrl => ApiConfig.baseUrl;

class TransportService {
  // ─── Fare Estimates ───────────────────────────────────────────

  Future<TransportListResult<FareEstimate>> getFareEstimates({
    required String pickup,
    required String dropoff,
    double? pickupLat,
    double? pickupLng,
    double? dropoffLat,
    double? dropoffLng,
  }) async {
    try {
      final response = await http.post(
        Uri.parse('$_baseUrl/transport/estimate'),
        headers: {'Content-Type': 'application/json'},
        body: jsonEncode({
          'pickup': pickup,
          'dropoff': dropoff,
          if (pickupLat != null) 'pickup_lat': pickupLat,
          if (pickupLng != null) 'pickup_lng': pickupLng,
          if (dropoffLat != null) 'dropoff_lat': dropoffLat,
          if (dropoffLng != null) 'dropoff_lng': dropoffLng,
        }),
      );
      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        if (data['success'] == true) {
          final items = (data['data'] as List)
              .map((j) => FareEstimate.fromJson(j))
              .toList();
          return TransportListResult(success: true, items: items);
        }
      }
      return TransportListResult(success: false, message: 'Imeshindwa kupata bei');
    } catch (e) {
      return TransportListResult(success: false, message: 'Kosa: $e');
    }
  }

  // ─── Ride Requests ────────────────────────────────────────────

  Future<TransportResult<RideRequest>> requestRide({
    required int userId,
    required String pickup,
    required String dropoff,
    required VehicleType vehicleType,
    double? pickupLat,
    double? pickupLng,
    double? dropoffLat,
    double? dropoffLng,
    required String paymentMethod,
  }) async {
    try {
      final response = await http.post(
        Uri.parse('$_baseUrl/transport/rides'),
        headers: {'Content-Type': 'application/json'},
        body: jsonEncode({
          'user_id': userId,
          'pickup': pickup,
          'dropoff': dropoff,
          'vehicle_type': vehicleType.name,
          if (pickupLat != null) 'pickup_lat': pickupLat,
          if (pickupLng != null) 'pickup_lng': pickupLng,
          if (dropoffLat != null) 'dropoff_lat': dropoffLat,
          if (dropoffLng != null) 'dropoff_lng': dropoffLng,
          'payment_method': paymentMethod,
        }),
      );
      final data = jsonDecode(response.body);
      if (response.statusCode == 200 && data['success'] == true) {
        return TransportResult(success: true, data: RideRequest.fromJson(data['data']));
      }
      return TransportResult(success: false, message: data['message'] ?? 'Imeshindwa kuagiza');
    } catch (e) {
      return TransportResult(success: false, message: 'Kosa: $e');
    }
  }

  Future<TransportResult<RideRequest>> getRide(int rideId) async {
    try {
      final response = await http.get(
        Uri.parse('$_baseUrl/transport/rides/$rideId'),
      );
      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        if (data['success'] == true) {
          return TransportResult(success: true, data: RideRequest.fromJson(data['data']));
        }
      }
      return TransportResult(success: false, message: 'Imeshindwa kupakia safari');
    } catch (e) {
      return TransportResult(success: false, message: 'Kosa: $e');
    }
  }

  Future<TransportResult<void>> cancelRide(int rideId) async {
    try {
      final response = await http.post(
        Uri.parse('$_baseUrl/transport/rides/$rideId/cancel'),
        headers: {'Content-Type': 'application/json'},
      );
      final data = jsonDecode(response.body);
      if (response.statusCode == 200 && data['success'] == true) {
        return TransportResult(success: true);
      }
      return TransportResult(success: false, message: data['message'] ?? 'Imeshindwa kughairi');
    } catch (e) {
      return TransportResult(success: false, message: 'Kosa: $e');
    }
  }

  Future<TransportResult<void>> rateRide({
    required int rideId,
    required double rating,
    String? comment,
  }) async {
    try {
      final response = await http.post(
        Uri.parse('$_baseUrl/transport/rides/$rideId/rate'),
        headers: {'Content-Type': 'application/json'},
        body: jsonEncode({
          'rating': rating,
          if (comment != null) 'comment': comment,
        }),
      );
      final data = jsonDecode(response.body);
      if (response.statusCode == 200 && data['success'] == true) {
        return TransportResult(success: true);
      }
      return TransportResult(success: false, message: data['message'] ?? 'Imeshindwa');
    } catch (e) {
      return TransportResult(success: false, message: 'Kosa: $e');
    }
  }

  // ─── Bus Routes ───────────────────────────────────────────────

  Future<TransportListResult<BusRoute>> searchBusRoutes({
    required String from,
    required String to,
    DateTime? date,
    int page = 1,
  }) async {
    try {
      final params = <String, String>{
        'from': from,
        'to': to,
        'page': '$page',
      };
      if (date != null) params['date'] = date.toIso8601String().split('T').first;

      final uri = Uri.parse('$_baseUrl/transport/bus-routes').replace(queryParameters: params);
      final response = await http.get(uri);

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        if (data['success'] == true) {
          final items = (data['data'] as List)
              .map((j) => BusRoute.fromJson(j))
              .toList();
          return TransportListResult(success: true, items: items);
        }
      }
      return TransportListResult(success: false, message: 'Imeshindwa kutafuta njia');
    } catch (e) {
      return TransportListResult(success: false, message: 'Kosa: $e');
    }
  }

  Future<TransportResult<BusTicket>> bookBusTicket({
    required int userId,
    required int busRouteId,
    required String passengerName,
    required String phone,
    required String paymentMethod,
  }) async {
    try {
      final response = await http.post(
        Uri.parse('$_baseUrl/transport/bus-tickets'),
        headers: {'Content-Type': 'application/json'},
        body: jsonEncode({
          'user_id': userId,
          'bus_route_id': busRouteId,
          'passenger_name': passengerName,
          'phone': phone,
          'payment_method': paymentMethod,
        }),
      );
      final data = jsonDecode(response.body);
      if (response.statusCode == 200 && data['success'] == true) {
        return TransportResult(success: true, data: BusTicket.fromJson(data['data']));
      }
      return TransportResult(success: false, message: data['message'] ?? 'Imeshindwa kunua tiketi');
    } catch (e) {
      return TransportResult(success: false, message: 'Kosa: $e');
    }
  }

  // ─── Trip History ─────────────────────────────────────────────

  Future<TransportListResult<Trip>> getMyTrips({
    required int userId,
    String? type,
    int page = 1,
  }) async {
    try {
      String url = '$_baseUrl/transport/trips?user_id=$userId&page=$page';
      if (type != null) url += '&type=$type';

      final response = await http.get(Uri.parse(url));
      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        if (data['success'] == true) {
          final items = (data['data'] as List)
              .map((j) => Trip.fromJson(j))
              .toList();
          return TransportListResult(success: true, items: items);
        }
      }
      return TransportListResult(success: false, message: 'Imeshindwa kupakia safari');
    } catch (e) {
      return TransportListResult(success: false, message: 'Kosa: $e');
    }
  }
}
