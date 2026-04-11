// lib/sell_car/services/sell_car_service.dart
import 'package:dio/dio.dart';
import '../../services/authenticated_dio.dart';
import '../models/sell_car_models.dart';

Dio get _dio => AuthenticatedDio.instance;

class SellCarService {
  // ─── Listings ────────────────────────────────────────────────

  static Future<PaginatedResult<SellListing>> getMyListings(
      {int page = 1}) async {
    try {
      final r = await _dio.get('/sell-car/my-listings',
          queryParameters: {'page': page});
      final data = r.data;
      if (data['success'] == true) {
        final items = (data['data'] as List)
            .map((j) => SellListing.fromJson(j))
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

  static Future<SingleResult<SellListing>> createListing(
      Map<String, dynamic> body) async {
    try {
      final r = await _dio.post('/sell-car/listings', data: body);
      final data = r.data;
      if (data['success'] == true) {
        return SingleResult(
            success: true, data: SellListing.fromJson(data['data']));
      }
      return SingleResult(success: false, message: data['message']);
    } catch (e) {
      return SingleResult(success: false, message: '$e');
    }
  }

  static Future<SingleResult<SellListing>> updateListing(
      int listingId, Map<String, dynamic> body) async {
    try {
      final r =
          await _dio.put('/sell-car/listings/$listingId', data: body);
      final data = r.data;
      if (data['success'] == true) {
        return SingleResult(
            success: true, data: SellListing.fromJson(data['data']));
      }
      return SingleResult(success: false, message: data['message']);
    } catch (e) {
      return SingleResult(success: false, message: '$e');
    }
  }

  static Future<SingleResult<void>> pauseListing(int listingId) async {
    try {
      final r = await _dio.post('/sell-car/listings/$listingId/pause');
      return SingleResult(success: r.data['success'] == true);
    } catch (e) {
      return SingleResult(success: false, message: '$e');
    }
  }

  static Future<SingleResult<void>> markAsSold(int listingId) async {
    try {
      final r = await _dio.post('/sell-car/listings/$listingId/sold');
      return SingleResult(success: r.data['success'] == true);
    } catch (e) {
      return SingleResult(success: false, message: '$e');
    }
  }

  // ─── Offers ──────────────────────────────────────────────────

  static Future<PaginatedResult<SellOffer>> getOffersForListing(
      int listingId,
      {int page = 1}) async {
    try {
      final r = await _dio.get('/sell-car/listings/$listingId/offers',
          queryParameters: {'page': page});
      final data = r.data;
      if (data['success'] == true) {
        final items = (data['data'] as List)
            .map((j) => SellOffer.fromJson(j))
            .toList();
        return PaginatedResult(success: true, items: items);
      }
      return PaginatedResult(success: false, message: data['message']);
    } catch (e) {
      return PaginatedResult(success: false, message: '$e');
    }
  }

  static Future<SingleResult<void>> respondToOffer(
      int offerId, String action) async {
    try {
      final r = await _dio.post('/sell-car/offers/$offerId/$action');
      return SingleResult(success: r.data['success'] == true);
    } catch (e) {
      return SingleResult(success: false, message: '$e');
    }
  }

  // ─── Price Suggestion ────────────────────────────────────────

  static Future<SingleResult<PriceSuggestion>> getPriceSuggestion({
    required String make,
    required String model,
    required int year,
    required double mileage,
    required String condition,
  }) async {
    try {
      final r = await _dio.post('/sell-car/price-suggestion', data: {
        'make': make,
        'model': model,
        'year': year,
        'mileage': mileage,
        'condition': condition,
      });
      final data = r.data;
      if (data['success'] == true) {
        return SingleResult(
            success: true, data: PriceSuggestion.fromJson(data['data']));
      }
      return SingleResult(success: false, message: data['message']);
    } catch (e) {
      return SingleResult(success: false, message: '$e');
    }
  }
}
