// lib/hair_nails/services/hair_nails_service.dart
import 'dart:convert';
import 'package:http/http.dart' as http;
import '../../config/api_config.dart';
import '../models/hair_nails_models.dart';

String get _baseUrl => ApiConfig.baseUrl;

class HairNailsService {
  // ─── Hair Profile ──────────────────────────────────────────────

  Future<HairNailsResult<HairProfile>> getHairProfile(int userId) async {
    try {
      final response = await http.get(Uri.parse('$_baseUrl/hair-nails/profile?user_id=$userId'));
      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        if (data['success'] == true) {
          return HairNailsResult(success: true, data: HairProfile.fromJson(data['data']));
        }
      }
      return HairNailsResult(success: false, message: 'Imeshindwa kupakia profaili ya nywele');
    } catch (e) {
      return HairNailsResult(success: false, message: 'Kosa: $e');
    }
  }

  Future<HairNailsResult<HairProfile>> saveHairProfile({
    required int userId,
    required HairType hairType,
    required Porosity porosity,
    required HairDensity density,
    double? lengthCm,
    required HairState currentState,
    String? scalpCondition,
    required List<String> goals,
  }) async {
    try {
      final response = await http.post(
        Uri.parse('$_baseUrl/hair-nails/profile'),
        headers: {'Content-Type': 'application/json'},
        body: jsonEncode({
          'user_id': userId,
          'hair_type': hairType.name,
          'porosity': porosity.name,
          'density': density.name,
          if (lengthCm != null) 'length_cm': lengthCm,
          'current_state': currentState.name,
          if (scalpCondition != null) 'scalp_condition': scalpCondition,
          'goals': goals,
        }),
      );
      final data = jsonDecode(response.body);
      if (response.statusCode == 200 && data['success'] == true) {
        return HairNailsResult(success: true, data: HairProfile.fromJson(data['data']));
      }
      return HairNailsResult(success: false, message: data['message'] ?? 'Imeshindwa kuhifadhi');
    } catch (e) {
      return HairNailsResult(success: false, message: 'Kosa: $e');
    }
  }

  // ─── Salons ────────────────────────────────────────────────────

  Future<HairNailsListResult<Salon>> findSalons({
    String? search,
    String? serviceCategory,
    double? minRating,
    bool? homeBased,
    bool? mobile,
    bool? walkIn,
    double? latitude,
    double? longitude,
    int page = 1,
  }) async {
    try {
      final params = <String, String>{'page': '$page'};
      if (search != null && search.isNotEmpty) params['search'] = search;
      if (serviceCategory != null) params['category'] = serviceCategory;
      if (minRating != null) params['min_rating'] = '$minRating';
      if (homeBased == true) params['home_based'] = '1';
      if (mobile == true) params['mobile'] = '1';
      if (walkIn == true) params['walk_in'] = '1';
      if (latitude != null) params['latitude'] = '$latitude';
      if (longitude != null) params['longitude'] = '$longitude';

      final uri = Uri.parse('$_baseUrl/hair-nails/salons').replace(queryParameters: params);
      final response = await http.get(uri);
      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        if (data['success'] == true) {
          return HairNailsListResult(success: true, items: (data['data'] as List).map((j) => Salon.fromJson(j)).toList());
        }
      }
      return HairNailsListResult(success: false, message: 'Imeshindwa kupakia saluni');
    } catch (e) {
      return HairNailsListResult(success: false, message: 'Kosa: $e');
    }
  }

  Future<HairNailsResult<Salon>> getSalonDetail(int salonId) async {
    try {
      final response = await http.get(Uri.parse('$_baseUrl/hair-nails/salons/$salonId'));
      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        if (data['success'] == true) return HairNailsResult(success: true, data: Salon.fromJson(data['data']));
      }
      return HairNailsResult(success: false);
    } catch (e) {
      return HairNailsResult(success: false);
    }
  }

  Future<HairNailsListResult<SalonReview>> getSalonReviews(int salonId, {int page = 1}) async {
    try {
      final response = await http.get(Uri.parse('$_baseUrl/hair-nails/salons/$salonId/reviews?page=$page'));
      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        if (data['success'] == true) {
          return HairNailsListResult(success: true, items: (data['data'] as List).map((j) => SalonReview.fromJson(j)).toList());
        }
      }
      return HairNailsListResult(success: false);
    } catch (e) {
      return HairNailsListResult(success: false);
    }
  }

  // ─── Bookings ──────────────────────────────────────────────────

  Future<HairNailsResult<Booking>> bookAppointment({
    required int userId,
    required int salonId,
    required int serviceId,
    required DateTime dateTime,
    String? notes,
    String? paymentMethod,
    String? phoneNumber,
  }) async {
    try {
      final response = await http.post(
        Uri.parse('$_baseUrl/hair-nails/bookings'),
        headers: {'Content-Type': 'application/json'},
        body: jsonEncode({
          'user_id': userId,
          'salon_id': salonId,
          'service_id': serviceId,
          'date_time': dateTime.toIso8601String(),
          if (notes != null) 'notes': notes,
          if (paymentMethod != null) 'payment_method': paymentMethod,
          if (phoneNumber != null) 'phone_number': phoneNumber,
        }),
      );
      final data = jsonDecode(response.body);
      if (response.statusCode == 200 && data['success'] == true) {
        return HairNailsResult(success: true, data: Booking.fromJson(data['data']));
      }
      return HairNailsResult(success: false, message: data['message'] ?? 'Imeshindwa kubook');
    } catch (e) {
      return HairNailsResult(success: false, message: 'Kosa: $e');
    }
  }

  Future<HairNailsListResult<Booking>> getMyBookings(int userId) async {
    try {
      final response = await http.get(Uri.parse('$_baseUrl/hair-nails/bookings?user_id=$userId'));
      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        if (data['success'] == true) {
          return HairNailsListResult(success: true, items: (data['data'] as List).map((j) => Booking.fromJson(j)).toList());
        }
      }
      return HairNailsListResult(success: false);
    } catch (e) {
      return HairNailsListResult(success: false);
    }
  }

  Future<HairNailsResult<void>> cancelBooking(int bookingId) async {
    try {
      final response = await http.post(
        Uri.parse('$_baseUrl/hair-nails/bookings/$bookingId/cancel'),
        headers: {'Content-Type': 'application/json'},
      );
      final data = jsonDecode(response.body);
      if (response.statusCode == 200 && data['success'] == true) return HairNailsResult(success: true);
      return HairNailsResult(success: false, message: data['message'] ?? 'Imeshindwa kufuta');
    } catch (e) {
      return HairNailsResult(success: false, message: 'Kosa: $e');
    }
  }

  Future<HairNailsResult<void>> rateBooking({
    required int bookingId,
    required int rating,
    String? comment,
  }) async {
    try {
      final response = await http.post(
        Uri.parse('$_baseUrl/hair-nails/bookings/$bookingId/rate'),
        headers: {'Content-Type': 'application/json'},
        body: jsonEncode({'rating': rating, if (comment != null) 'comment': comment}),
      );
      final data = jsonDecode(response.body);
      if (response.statusCode == 200 && data['success'] == true) return HairNailsResult(success: true);
      return HairNailsResult(success: false, message: data['message'] ?? 'Imeshindwa');
    } catch (e) {
      return HairNailsResult(success: false, message: 'Kosa: $e');
    }
  }

  // ─── Style Gallery ─────────────────────────────────────────────

  Future<HairNailsListResult<StyleInspiration>> getStyleGallery({String? category, int page = 1}) async {
    try {
      final params = <String, String>{'page': '$page'};
      if (category != null) params['category'] = category;

      final uri = Uri.parse('$_baseUrl/hair-nails/styles').replace(queryParameters: params);
      final response = await http.get(uri);
      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        if (data['success'] == true) {
          return HairNailsListResult(success: true, items: (data['data'] as List).map((j) => StyleInspiration.fromJson(j)).toList());
        }
      }
      return HairNailsListResult(success: false, message: 'Imeshindwa kupakia mitindo');
    } catch (e) {
      return HairNailsListResult(success: false, message: 'Kosa: $e');
    }
  }

  Future<HairNailsListResult<StyleInspiration>> getSavedStyles(int userId) async {
    try {
      final response = await http.get(Uri.parse('$_baseUrl/hair-nails/styles/saved?user_id=$userId'));
      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        if (data['success'] == true) {
          return HairNailsListResult(success: true, items: (data['data'] as List).map((j) => StyleInspiration.fromJson(j)).toList());
        }
      }
      return HairNailsListResult(success: false);
    } catch (e) {
      return HairNailsListResult(success: false);
    }
  }

  Future<HairNailsResult<void>> saveStyle({required int userId, required int styleId}) async {
    try {
      final response = await http.post(
        Uri.parse('$_baseUrl/hair-nails/styles/$styleId/save'),
        headers: {'Content-Type': 'application/json'},
        body: jsonEncode({'user_id': userId}),
      );
      final data = jsonDecode(response.body);
      if (response.statusCode == 200 && data['success'] == true) return HairNailsResult(success: true);
      return HairNailsResult(success: false);
    } catch (e) {
      return HairNailsResult(success: false);
    }
  }

  // ─── Growth Tracking ───────────────────────────────────────────

  Future<HairNailsResult<GrowthLog>> logGrowth({
    required int userId,
    required double lengthCm,
    String? photoUrl,
    String? notes,
  }) async {
    try {
      final response = await http.post(
        Uri.parse('$_baseUrl/hair-nails/growth'),
        headers: {'Content-Type': 'application/json'},
        body: jsonEncode({
          'user_id': userId,
          'length_cm': lengthCm,
          if (photoUrl != null) 'photo_url': photoUrl,
          if (notes != null) 'notes': notes,
        }),
      );
      final data = jsonDecode(response.body);
      if (response.statusCode == 200 && data['success'] == true) {
        return HairNailsResult(success: true, data: GrowthLog.fromJson(data['data']));
      }
      return HairNailsResult(success: false, message: data['message'] ?? 'Imeshindwa kuhifadhi');
    } catch (e) {
      return HairNailsResult(success: false, message: 'Kosa: $e');
    }
  }

  Future<HairNailsListResult<GrowthLog>> getGrowthHistory(int userId) async {
    try {
      final response = await http.get(Uri.parse('$_baseUrl/hair-nails/growth?user_id=$userId'));
      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        if (data['success'] == true) {
          return HairNailsListResult(success: true, items: (data['data'] as List).map((j) => GrowthLog.fromJson(j)).toList());
        }
      }
      return HairNailsListResult(success: false);
    } catch (e) {
      return HairNailsListResult(success: false);
    }
  }
}
