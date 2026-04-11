// lib/housing/services/housing_service.dart
import 'dart:convert';
import 'package:flutter/foundation.dart';
import 'package:http/http.dart' as http;
import '../../config/api_config.dart';
import '../../services/expenditure_service.dart';
import '../../services/local_storage_service.dart';
import '../models/housing_models.dart';

String get _baseUrl => ApiConfig.baseUrl;

class HousingService {
  // ─── Properties ────────────────────────────────────────────────

  Future<HousingListResult<Property>> getProperties({
    String? type,
    String? location,
    double? minPrice,
    double? maxPrice,
    int? bedrooms,
    String? priceFrequency,
    String? search,
    bool? featuredOnly,
  }) async {
    try {
      final params = <String, String>{};
      if (type != null) params['type'] = type;
      if (location != null) params['location'] = location;
      if (minPrice != null) params['min_price'] = minPrice.toString();
      if (maxPrice != null) params['max_price'] = maxPrice.toString();
      if (bedrooms != null) params['bedrooms'] = bedrooms.toString();
      if (priceFrequency != null) params['price_frequency'] = priceFrequency;
      if (search != null && search.isNotEmpty) params['search'] = search;
      if (featuredOnly == true) params['featured'] = '1';

      final uri = Uri.parse('$_baseUrl/housing/properties')
          .replace(queryParameters: params.isNotEmpty ? params : null);
      final response = await http.get(uri);
      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        if (data['success'] == true) {
          final items = (data['data'] as List)
              .map((j) => Property.fromJson(j))
              .toList();
          return HousingListResult(success: true, items: items);
        }
      }
      return HousingListResult(success: false, message: 'Imeshindwa kupakia mali');
    } catch (e) {
      return HousingListResult(success: false, message: 'Kosa: $e');
    }
  }

  Future<HousingResult<Property>> getPropertyDetail(int propertyId) async {
    try {
      final response = await http.get(Uri.parse('$_baseUrl/housing/properties/$propertyId'));
      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        if (data['success'] == true) {
          return HousingResult(success: true, data: Property.fromJson(data['data']));
        }
      }
      return HousingResult(success: false);
    } catch (e) {
      return HousingResult(success: false);
    }
  }

  Future<HousingListResult<Property>> getFeaturedProperties() async {
    return getProperties(featuredOnly: true);
  }

  // ─── My Rentals ────────────────────────────────────────────────

  Future<HousingListResult<MyRental>> getMyRentals(int userId) async {
    try {
      final response = await http.get(
        Uri.parse('$_baseUrl/housing/rentals?user_id=$userId'),
      );
      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        if (data['success'] == true) {
          final items = (data['data'] as List)
              .map((j) => MyRental.fromJson(j))
              .toList();
          return HousingListResult(success: true, items: items);
        }
      }
      return HousingListResult(success: false, message: 'Imeshindwa kupakia');
    } catch (e) {
      return HousingListResult(success: false, message: 'Kosa: $e');
    }
  }

  // ─── Rental Payments ──────────────────────────────────────────

  Future<HousingListResult<RentalPayment>> getRentalPayments(int rentalId) async {
    try {
      final response = await http.get(
        Uri.parse('$_baseUrl/housing/rentals/$rentalId/payments'),
      );
      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        if (data['success'] == true) {
          final items = (data['data'] as List)
              .map((j) => RentalPayment.fromJson(j))
              .toList();
          return HousingListResult(success: true, items: items);
        }
      }
      return HousingListResult(success: false);
    } catch (e) {
      return HousingListResult(success: false);
    }
  }

  Future<HousingResult<RentalPayment>> makeRentalPayment({
    required int rentalId,
    required double amount,
    required String paymentMethod,
    String? phoneNumber,
  }) async {
    try {
      final response = await http.post(
        Uri.parse('$_baseUrl/housing/rentals/$rentalId/pay'),
        headers: {'Content-Type': 'application/json'},
        body: jsonEncode({
          'amount': amount,
          'payment_method': paymentMethod,
          if (phoneNumber != null) 'phone_number': phoneNumber,
        }),
      );
      final data = jsonDecode(response.body);
      if (data['success'] == true) {
        final payment = RentalPayment.fromJson(data['data']);
        // Fire-and-forget: record expenditure for budget tracking
        LocalStorageService.getInstance().then((storage) {
          final token = storage.getAuthToken();
          if (token != null) {
            ExpenditureService.recordExpenditure(
              token: token,
              amount: amount,
              category: 'kodi',
              description: 'Kodi: Rental payment',
              referenceId: 'housing_${rentalId}_${DateTime.now().millisecondsSinceEpoch}',
              sourceModule: 'housing',
            ).catchError((_) => null);
          }
        }).catchError((_) {
          debugPrint('[HousingService] expenditure tracking skipped');
        });
        return HousingResult(success: true, data: payment);
      }
      return HousingResult(success: false, message: data['message'] ?? 'Malipo yameshindwa');
    } catch (e) {
      return HousingResult(success: false, message: 'Kosa: $e');
    }
  }

  // ─── Apply for Property ───────────────────────────────────────

  Future<HousingResult<void>> applyForProperty({
    required int userId,
    required int propertyId,
    String? message,
  }) async {
    try {
      final response = await http.post(
        Uri.parse('$_baseUrl/housing/properties/$propertyId/apply'),
        headers: {'Content-Type': 'application/json'},
        body: jsonEncode({
          'user_id': userId,
          if (message != null) 'message': message,
        }),
      );
      final data = jsonDecode(response.body);
      if (data['success'] == true) {
        return HousingResult(success: true);
      }
      return HousingResult(success: false, message: data['message'] ?? 'Ombi limeshindwa');
    } catch (e) {
      return HousingResult(success: false, message: 'Kosa: $e');
    }
  }
}
