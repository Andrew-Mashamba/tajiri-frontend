// lib/fundi/services/fundi_service.dart
import 'dart:convert';
import 'package:http/http.dart' as http;
import '../../config/api_config.dart';
import '../models/fundi_models.dart';

String get _baseUrl => ApiConfig.baseUrl;

class FundiService {
  // ─── Find Fundis ──────────────────────────────────────────────

  Future<FundiListResult<Fundi>> findFundis({
    String? service,
    String? search,
    bool? availableOnly,
    int page = 1,
    int perPage = 20,
  }) async {
    try {
      final params = <String, String>{
        'page': '$page',
        'per_page': '$perPage',
      };
      if (service != null) params['service'] = service;
      if (search != null && search.isNotEmpty) params['search'] = search;
      if (availableOnly == true) params['available'] = '1';

      final uri = Uri.parse('$_baseUrl/fundis').replace(queryParameters: params);
      final response = await http.get(uri);

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        if (data['success'] == true) {
          final items = (data['data'] as List)
              .map((j) => Fundi.fromJson(j))
              .toList();
          return FundiListResult(success: true, items: items);
        }
      }
      return FundiListResult(success: false, message: 'Imeshindwa kupakia mafundi');
    } catch (e) {
      return FundiListResult(success: false, message: 'Kosa: $e');
    }
  }

  Future<FundiResult<Fundi>> getFundiProfile(int fundiId) async {
    try {
      final response = await http.get(
        Uri.parse('$_baseUrl/fundis/$fundiId'),
      );
      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        if (data['success'] == true) {
          return FundiResult(success: true, data: Fundi.fromJson(data['data']));
        }
      }
      return FundiResult(success: false, message: 'Imeshindwa kupakia fundi');
    } catch (e) {
      return FundiResult(success: false, message: 'Kosa: $e');
    }
  }

  // ─── Fundi Registration ───────────────────────────────────────

  Future<FundiResult<Fundi>> registerAsFundi({
    required int userId,
    required FundiRegistrationRequest request,
  }) async {
    try {
      final response = await http.post(
        Uri.parse('$_baseUrl/fundis/register'),
        headers: {'Content-Type': 'application/json'},
        body: jsonEncode({
          'user_id': userId,
          ...request.toJson(),
        }),
      );
      final data = jsonDecode(response.body);
      if (response.statusCode == 200 && data['success'] == true) {
        return FundiResult(success: true, data: Fundi.fromJson(data['data']));
      }
      return FundiResult(success: false, message: data['message'] ?? 'Imeshindwa kusajili');
    } catch (e) {
      return FundiResult(success: false, message: 'Kosa: $e');
    }
  }

  Future<FundiResult<Fundi>> getMyFundiProfile(int userId) async {
    try {
      final response = await http.get(
        Uri.parse('$_baseUrl/fundis/me?user_id=$userId'),
      );
      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        if (data['success'] == true) {
          return FundiResult(success: true, data: Fundi.fromJson(data['data']));
        }
      }
      return FundiResult(success: false);
    } catch (e) {
      return FundiResult(success: false);
    }
  }

  // ─── Bookings ─────────────────────────────────────────────────

  Future<FundiResult<FundiBooking>> createBooking({
    required int userId,
    required int fundiId,
    required ServiceCategory service,
    required DateTime scheduledDate,
    String? scheduledTime,
    required String description,
    String? address,
    double? estimatedCost,
  }) async {
    try {
      final response = await http.post(
        Uri.parse('$_baseUrl/fundis/bookings'),
        headers: {'Content-Type': 'application/json'},
        body: jsonEncode({
          'user_id': userId,
          'fundi_id': fundiId,
          'service': service.name,
          'scheduled_date': scheduledDate.toIso8601String().split('T').first,
          if (scheduledTime != null) 'scheduled_time': scheduledTime,
          'description': description,
          if (address != null) 'address': address,
          if (estimatedCost != null) 'estimated_cost': estimatedCost,
        }),
      );
      final data = jsonDecode(response.body);
      if (response.statusCode == 200 && data['success'] == true) {
        return FundiResult(success: true, data: FundiBooking.fromJson(data['data']));
      }
      return FundiResult(success: false, message: data['message'] ?? 'Imeshindwa kuagiza');
    } catch (e) {
      return FundiResult(success: false, message: 'Kosa: $e');
    }
  }

  Future<FundiListResult<FundiBooking>> getMyBookings({
    required int userId,
    String? status,
    int page = 1,
  }) async {
    try {
      String url = '$_baseUrl/fundis/bookings?user_id=$userId&page=$page';
      if (status != null) url += '&status=$status';

      final response = await http.get(Uri.parse(url));
      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        if (data['success'] == true) {
          final items = (data['data'] as List)
              .map((j) => FundiBooking.fromJson(j))
              .toList();
          return FundiListResult(success: true, items: items);
        }
      }
      return FundiListResult(success: false, message: 'Imeshindwa kupakia nafasi');
    } catch (e) {
      return FundiListResult(success: false, message: 'Kosa: $e');
    }
  }

  Future<FundiResult<void>> cancelBooking(int bookingId, {String? reason}) async {
    try {
      final response = await http.post(
        Uri.parse('$_baseUrl/fundis/bookings/$bookingId/cancel'),
        headers: {'Content-Type': 'application/json'},
        body: jsonEncode({if (reason != null) 'reason': reason}),
      );
      final data = jsonDecode(response.body);
      if (response.statusCode == 200 && data['success'] == true) {
        return FundiResult(success: true);
      }
      return FundiResult(success: false, message: data['message'] ?? 'Imeshindwa kughairi');
    } catch (e) {
      return FundiResult(success: false, message: 'Kosa: $e');
    }
  }

  // ─── Reviews ──────────────────────────────────────────────────

  Future<FundiResult<FundiReview>> submitReview({
    required int bookingId,
    required int userId,
    required int fundiId,
    required double rating,
    String? comment,
  }) async {
    try {
      final response = await http.post(
        Uri.parse('$_baseUrl/fundis/reviews'),
        headers: {'Content-Type': 'application/json'},
        body: jsonEncode({
          'booking_id': bookingId,
          'user_id': userId,
          'fundi_id': fundiId,
          'rating': rating,
          if (comment != null) 'comment': comment,
        }),
      );
      final data = jsonDecode(response.body);
      if (response.statusCode == 200 && data['success'] == true) {
        return FundiResult(success: true, data: FundiReview.fromJson(data['data']));
      }
      return FundiResult(success: false, message: data['message'] ?? 'Imeshindwa');
    } catch (e) {
      return FundiResult(success: false, message: 'Kosa: $e');
    }
  }

  Future<FundiListResult<FundiReview>> getFundiReviews(int fundiId) async {
    try {
      final response = await http.get(
        Uri.parse('$_baseUrl/fundis/$fundiId/reviews'),
      );
      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        if (data['success'] == true) {
          final items = (data['data'] as List)
              .map((j) => FundiReview.fromJson(j))
              .toList();
          return FundiListResult(success: true, items: items);
        }
      }
      return FundiListResult(success: false);
    } catch (e) {
      return FundiListResult(success: false);
    }
  }
}
