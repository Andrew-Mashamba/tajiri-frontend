// lib/travel/services/travel_service.dart

import 'dart:convert';
import 'package:http/http.dart' as http;
import '../../config/api_config.dart';
import '../models/travel_models.dart';

String get _baseUrl => ApiConfig.baseUrl;

class TravelService {

  // ─── Search ─────────────────────────────────────────────────

  Future<TransportListResult<TransportOption>> search({
    required String origin,
    required String destination,
    required String date,
    int passengers = 1,
    String? preferredMode,
  }) async {
    try {
      final body = <String, dynamic>{
        'origin': origin,
        'destination': destination,
        'date': date,
        'passengers': passengers,
      };
      if (preferredMode != null) body['preferred_mode'] = preferredMode;

      final response = await http.post(
        Uri.parse('$_baseUrl/transport/search'),
        headers: ApiConfig.headers,
        body: jsonEncode(body),
      );

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        if (data['success'] == true) {
          final items = (data['data'] as List)
              .map((j) => TransportOption.fromJson(j))
              .toList();
          return TransportListResult(success: true, items: items);
        }
      }
      return TransportListResult(success: false, message: 'Imeshindwa kutafuta safari / Search failed');
    } catch (e) {
      return TransportListResult(success: false, message: 'Kosa: $e');
    }
  }

  // ─── Option Detail ──────────────────────────────────────────

  Future<TransportResult<TransportOption>> getOption(String optionId) async {
    try {
      final response = await http.get(
        Uri.parse('$_baseUrl/transport/option/$optionId'),
      );
      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        if (data['success'] == true) {
          return TransportResult(
            success: true,
            data: TransportOption.fromJson(data['data']),
          );
        }
      }
      return TransportResult(success: false, message: 'Imeshindwa kupakia chaguo / Failed to load option');
    } catch (e) {
      return TransportResult(success: false, message: 'Kosa: $e');
    }
  }

  // ─── Cities ─────────────────────────────────────────────────

  Future<TransportListResult<City>> getCities({String? query}) async {
    try {
      final params = <String, String>{};
      if (query != null && query.isNotEmpty) params['q'] = query;

      final uri = Uri.parse('$_baseUrl/transport/cities')
          .replace(queryParameters: params.isNotEmpty ? params : null);
      final response = await http.get(uri);

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        if (data['success'] == true) {
          final items = (data['data'] as List)
              .map((j) => City.fromJson(j))
              .toList();
          return TransportListResult(success: true, items: items);
        }
      }
      return TransportListResult(success: false, message: 'Imeshindwa kupakia miji / Failed to load cities');
    } catch (e) {
      return TransportListResult(success: false, message: 'Kosa: $e');
    }
  }

  // ─── Popular Routes ─────────────────────────────────────────

  Future<TransportListResult<PopularRoute>> getPopularRoutes() async {
    try {
      final response = await http.get(
        Uri.parse('$_baseUrl/transport/popular-routes'),
      );
      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        if (data['success'] == true) {
          final items = (data['data'] as List)
              .map((j) => PopularRoute.fromJson(j))
              .toList();
          return TransportListResult(success: true, items: items);
        }
      }
      return TransportListResult(success: false, message: 'Imeshindwa kupakia njia maarufu / Failed to load popular routes');
    } catch (e) {
      return TransportListResult(success: false, message: 'Kosa: $e');
    }
  }

  // ─── Booking ────────────────────────────────────────────────

  Future<TransportResult<TransportBooking>> createBooking({
    required String optionId,
    required int userId,
    required List<Passenger> passengers,
    required PaymentMethod paymentMethod,
    String? paymentPhone,
  }) async {
    try {
      final response = await http.post(
        Uri.parse('$_baseUrl/transport/bookings'),
        headers: ApiConfig.headers,
        body: jsonEncode({
          'option_id': optionId,
          'user_id': userId,
          'passengers': passengers.map((p) => p.toJson()).toList(),
          'payment_method': paymentMethod.name,
          if (paymentPhone != null && paymentPhone.isNotEmpty)
            'payment_phone': paymentPhone,
        }),
      );

      if (response.statusCode == 200 || response.statusCode == 201) {
        final data = jsonDecode(response.body);
        if (data['success'] == true) {
          return TransportResult(
            success: true,
            data: TransportBooking.fromJson(data['data']),
          );
        }
        return TransportResult(success: false, message: data['message']?.toString());
      }

      try {
        final data = jsonDecode(response.body);
        return TransportResult(success: false, message: data['message']?.toString() ?? 'Imeshindwa kubuking / Booking failed');
      } catch (_) {
        return TransportResult(success: false, message: 'Imeshindwa kubuking / Booking failed');
      }
    } catch (e) {
      return TransportResult(success: false, message: 'Kosa: $e');
    }
  }

  // ─── My Bookings ────────────────────────────────────────────

  Future<TransportListResult<TransportBooking>> getBookings(int userId) async {
    try {
      final uri = Uri.parse('$_baseUrl/transport/bookings')
          .replace(queryParameters: {'user_id': '$userId'});
      final response = await http.get(uri);

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        if (data['success'] == true) {
          final items = (data['data'] as List)
              .map((j) => TransportBooking.fromJson(j))
              .toList();
          return TransportListResult(success: true, items: items);
        }
      }
      return TransportListResult(success: false, message: 'Imeshindwa kupakia safari zako / Failed to load bookings');
    } catch (e) {
      return TransportListResult(success: false, message: 'Kosa: $e');
    }
  }

  // ─── Cancel Booking ─────────────────────────────────────────

  Future<TransportResult<TransportBooking>> cancelBooking(int bookingId) async {
    try {
      final response = await http.post(
        Uri.parse('$_baseUrl/transport/bookings/$bookingId/cancel'),
        headers: ApiConfig.headers,
      );

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        if (data['success'] == true) {
          return TransportResult(
            success: true,
            data: TransportBooking.fromJson(data['data']),
          );
        }
        return TransportResult(success: false, message: data['message']?.toString());
      }
      return TransportResult(success: false, message: 'Imeshindwa kughairi / Cancellation failed');
    } catch (e) {
      return TransportResult(success: false, message: 'Kosa: $e');
    }
  }

  // ─── Ticket ─────────────────────────────────────────────────

  Future<TransportResult<TransportTicket>> getTicket(int bookingId) async {
    try {
      final response = await http.get(
        Uri.parse('$_baseUrl/transport/tickets/$bookingId'),
      );
      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        if (data['success'] == true) {
          return TransportResult(
            success: true,
            data: TransportTicket.fromJson(data['data']),
          );
        }
      }
      return TransportResult(success: false, message: 'Imeshindwa kupakia tiketi / Failed to load ticket');
    } catch (e) {
      return TransportResult(success: false, message: 'Kosa: $e');
    }
  }

  // ─── Weather ────────────────────────────────────────────────

  Future<TransportResult<Map<String, dynamic>>> getWeather(String cityCode) async {
    try {
      final response = await http.get(
        Uri.parse('$_baseUrl/transport/cities/$cityCode/weather'),
      );
      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        if (data['success'] == true) {
          return TransportResult(success: true, data: data['data'] as Map<String, dynamic>);
        }
      }
      return TransportResult(success: false, message: 'Hali ya hewa haipatikani / Weather data unavailable');
    } catch (e) {
      return TransportResult(success: false, message: 'Kosa: $e');
    }
  }
}
