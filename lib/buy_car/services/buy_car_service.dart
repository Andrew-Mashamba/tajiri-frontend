// lib/buy_car/services/buy_car_service.dart
import 'package:dio/dio.dart';
import '../../services/authenticated_dio.dart';
import '../models/buy_car_models.dart';

Dio get _dio => AuthenticatedDio.instance;

class BuyCarService {
  // ─── Listings ────────────────────────────────────────────────

  static Future<PaginatedResult<CarListing>> getListings({
    int page = 1,
    String? make,
    String? model,
    int? yearMin,
    int? yearMax,
    double? priceMin,
    double? priceMax,
    String? fuelType,
    String? transmission,
    String? source,
    String? sortBy,
  }) async {
    try {
      final r = await _dio.get('/buy-car/listings', queryParameters: {
        'page': page,
        if (make != null) 'make': make,
        if (model != null) 'model': model,
        if (yearMin != null) 'year_min': yearMin,
        if (yearMax != null) 'year_max': yearMax,
        if (priceMin != null) 'price_min': priceMin,
        if (priceMax != null) 'price_max': priceMax,
        if (fuelType != null) 'fuel_type': fuelType,
        if (transmission != null) 'transmission': transmission,
        if (source != null) 'source': source,
        if (sortBy != null) 'sort_by': sortBy,
      });
      final data = r.data;
      if (data['success'] == true) {
        final items = (data['data'] as List)
            .map((j) => CarListing.fromJson(j))
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

  static Future<SingleResult<CarListing>> getListingDetail(
      int listingId) async {
    try {
      final r = await _dio.get('/buy-car/listings/$listingId');
      final data = r.data;
      if (data['success'] == true) {
        return SingleResult(
            success: true, data: CarListing.fromJson(data['data']));
      }
      return SingleResult(success: false, message: data['message']);
    } catch (e) {
      return SingleResult(success: false, message: '$e');
    }
  }

  static Future<SingleResult<void>> saveListing(int listingId) async {
    try {
      final r = await _dio.post('/buy-car/listings/$listingId/save');
      return SingleResult(success: r.data['success'] == true);
    } catch (e) {
      return SingleResult(success: false, message: '$e');
    }
  }

  static Future<PaginatedResult<CarListing>> getSavedListings(
      {int page = 1}) async {
    try {
      final r = await _dio
          .get('/buy-car/saved', queryParameters: {'page': page});
      final data = r.data;
      if (data['success'] == true) {
        final items = (data['data'] as List)
            .map((j) => CarListing.fromJson(j))
            .toList();
        return PaginatedResult(success: true, items: items);
      }
      return PaginatedResult(success: false, message: data['message']);
    } catch (e) {
      return PaginatedResult(success: false, message: '$e');
    }
  }

  // ─── Import Calculator ──────────────────────────────────────

  static Future<SingleResult<ImportCost>> calculateImportCost({
    required double cifPrice,
    required String cifCurrency,
    required int engineCc,
    required int vehicleAge,
  }) async {
    try {
      final r = await _dio.post('/buy-car/import-calculator', data: {
        'cif_price': cifPrice,
        'cif_currency': cifCurrency,
        'engine_cc': engineCc,
        'vehicle_age': vehicleAge,
      });
      final data = r.data;
      if (data['success'] == true) {
        return SingleResult(
            success: true, data: ImportCost.fromJson(data['data']));
      }
      return SingleResult(success: false, message: data['message']);
    } catch (e) {
      return SingleResult(success: false, message: '$e');
    }
  }

  // ─── Dealers ─────────────────────────────────────────────────

  static Future<PaginatedResult<CarDealer>> getDealers(
      {int page = 1}) async {
    try {
      final r = await _dio
          .get('/buy-car/dealers', queryParameters: {'page': page});
      final data = r.data;
      if (data['success'] == true) {
        final items = (data['data'] as List)
            .map((j) => CarDealer.fromJson(j))
            .toList();
        return PaginatedResult(success: true, items: items);
      }
      return PaginatedResult(success: false, message: data['message']);
    } catch (e) {
      return PaginatedResult(success: false, message: '$e');
    }
  }
}
