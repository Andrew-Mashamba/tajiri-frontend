// lib/car_insurance/services/car_insurance_service.dart
import 'package:dio/dio.dart';
import 'package:flutter/foundation.dart';
import '../../services/authenticated_dio.dart';
import '../../services/expenditure_service.dart';
import '../../services/local_storage_service.dart';
import '../models/car_insurance_models.dart';

Dio get _dio => AuthenticatedDio.instance;

class CarInsuranceService {
  // ─── Policies ────────────────────────────────────────────────

  static Future<PaginatedResult<InsurancePolicy>> getMyPolicies(
      {int page = 1}) async {
    try {
      final r =
          await _dio.get('/car-insurance/policies', queryParameters: {'page': page});
      final data = r.data;
      if (data['success'] == true) {
        final items = (data['data'] as List)
            .map((j) => InsurancePolicy.fromJson(j))
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

  static Future<SingleResult<InsurancePolicy>> getPolicyDetail(
      int policyId) async {
    try {
      final r = await _dio.get('/car-insurance/policies/$policyId');
      final data = r.data;
      if (data['success'] == true) {
        return SingleResult(
            success: true, data: InsurancePolicy.fromJson(data['data']));
      }
      return SingleResult(success: false, message: data['message']);
    } catch (e) {
      return SingleResult(success: false, message: '$e');
    }
  }

  // ─── Quotes ──────────────────────────────────────────────────

  static Future<PaginatedResult<InsuranceQuote>> getQuotes({
    required String make,
    required String model,
    required int year,
    required String coverageType,
    double? vehicleValue,
  }) async {
    try {
      final r = await _dio.post('/car-insurance/quotes', data: {
        'make': make,
        'model': model,
        'year': year,
        'coverage_type': coverageType,
        if (vehicleValue != null) 'vehicle_value': vehicleValue,
      });
      final data = r.data;
      if (data['success'] == true) {
        final items = (data['data'] as List)
            .map((j) => InsuranceQuote.fromJson(j))
            .toList();
        return PaginatedResult(success: true, items: items);
      }
      return PaginatedResult(success: false, message: data['message']);
    } catch (e) {
      return PaginatedResult(success: false, message: '$e');
    }
  }

  static Future<SingleResult<InsurancePolicy>> purchasePolicy(
      int quoteId, Map<String, dynamic> body) async {
    try {
      final r =
          await _dio.post('/car-insurance/quotes/$quoteId/purchase', data: body);
      final data = r.data;
      if (data['success'] == true) {
        final policy = InsurancePolicy.fromJson(data['data']);
        // Fire-and-forget: record expenditure for budget tracking
        LocalStorageService.getInstance().then((storage) {
          final token = storage.getAuthToken();
          if (token != null) {
            ExpenditureService.recordExpenditure(
              token: token,
              amount: policy.premium,
              category: 'bima',
              description: 'Bima ya Gari: ${policy.providerName}',
              referenceId: 'car_insurance_${policy.id}',
              sourceModule: 'car_insurance',
            ).catchError((_) => null);
          }
        }).catchError((_) {
          debugPrint('[CarInsuranceService] expenditure tracking skipped');
        });
        return SingleResult(success: true, data: policy);
      }
      return SingleResult(success: false, message: data['message']);
    } catch (e) {
      return SingleResult(success: false, message: '$e');
    }
  }

  // ─── Claims ──────────────────────────────────────────────────

  static Future<PaginatedResult<InsuranceClaim>> getMyClaims(
      {int page = 1}) async {
    try {
      final r =
          await _dio.get('/car-insurance/claims', queryParameters: {'page': page});
      final data = r.data;
      if (data['success'] == true) {
        final items = (data['data'] as List)
            .map((j) => InsuranceClaim.fromJson(j))
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

  static Future<SingleResult<InsuranceClaim>> fileClaim(
      Map<String, dynamic> body) async {
    try {
      final r = await _dio.post('/car-insurance/claims', data: body);
      final data = r.data;
      if (data['success'] == true) {
        return SingleResult(
            success: true, data: InsuranceClaim.fromJson(data['data']));
      }
      return SingleResult(success: false, message: data['message']);
    } catch (e) {
      return SingleResult(success: false, message: '$e');
    }
  }

  // ─── Providers ───────────────────────────────────────────────

  static Future<PaginatedResult<InsuranceProvider>> getProviders() async {
    try {
      final r = await _dio.get('/car-insurance/providers');
      final data = r.data;
      if (data['success'] == true) {
        final items = (data['data'] as List)
            .map((j) => InsuranceProvider.fromJson(j))
            .toList();
        return PaginatedResult(success: true, items: items);
      }
      return PaginatedResult(success: false, message: data['message']);
    } catch (e) {
      return PaginatedResult(success: false, message: '$e');
    }
  }
}
