// lib/insurance/services/insurance_service.dart
import 'dart:convert';
import 'package:flutter/foundation.dart';
import 'package:http/http.dart' as http;
import '../../config/api_config.dart';
import '../../services/expenditure_service.dart';
import '../../services/local_storage_service.dart';
import '../models/insurance_models.dart';

String get _baseUrl => ApiConfig.baseUrl;

class InsuranceService {
  // ─── Products ──────────────────────────────────────────────────

  Future<InsuranceListResult<InsuranceProduct>> getProducts({
    String? category,
    String? search,
    bool? popularOnly,
  }) async {
    try {
      final params = <String, String>{};
      if (category != null) params['category'] = category;
      if (search != null && search.isNotEmpty) params['search'] = search;
      if (popularOnly == true) params['popular'] = '1';

      final uri = Uri.parse('$_baseUrl/insurance/products').replace(queryParameters: params);
      final response = await http.get(uri);
      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        if (data['success'] == true) {
          final items = (data['data'] as List).map((j) => InsuranceProduct.fromJson(j)).toList();
          return InsuranceListResult(success: true, items: items);
        }
      }
      return InsuranceListResult(success: false, message: 'Imeshindwa kupakia bidhaa');
    } catch (e) {
      return InsuranceListResult(success: false, message: 'Kosa: $e');
    }
  }

  Future<InsuranceResult<InsuranceProduct>> getProductDetail(int productId) async {
    try {
      final response = await http.get(Uri.parse('$_baseUrl/insurance/products/$productId'));
      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        if (data['success'] == true) {
          return InsuranceResult(success: true, data: InsuranceProduct.fromJson(data['data']));
        }
      }
      return InsuranceResult(success: false);
    } catch (e) {
      return InsuranceResult(success: false);
    }
  }

  // ─── Purchase / Subscribe ──────────────────────────────────────

  Future<InsuranceResult<InsurancePolicy>> purchasePolicy({
    required int userId,
    required int productId,
    required String premiumFrequency,
    String? beneficiaryName,
    required String paymentMethod,
    String? phoneNumber,
    int? linkedModuleId,
    String? linkedModule,
  }) async {
    try {
      final response = await http.post(
        Uri.parse('$_baseUrl/insurance/purchase'),
        headers: {'Content-Type': 'application/json'},
        body: jsonEncode({
          'user_id': userId,
          'product_id': productId,
          'premium_frequency': premiumFrequency,
          if (beneficiaryName != null) 'beneficiary_name': beneficiaryName,
          'payment_method': paymentMethod,
          if (phoneNumber != null) 'phone_number': phoneNumber,
          if (linkedModuleId != null) 'linked_module_id': linkedModuleId,
          if (linkedModule != null) 'linked_module': linkedModule,
        }),
      );
      final data = jsonDecode(response.body);
      if (response.statusCode == 200 && data['success'] == true) {
        final policy = InsurancePolicy.fromJson(data['data']);
        // Fire-and-forget: record expenditure for budget tracking
        LocalStorageService.getInstance().then((storage) {
          final token = storage.getAuthToken();
          if (token != null) {
            ExpenditureService.recordExpenditure(
              token: token,
              amount: policy.premiumAmount,
              category: 'bima',
              description: 'Bima: ${policy.productName}',
              referenceId: 'insurance_purchase_${policy.id}',
              sourceModule: 'insurance',
            ).catchError((_) => null);
          }
        }).catchError((_) {
          debugPrint('[InsuranceService] expenditure tracking skipped');
        });
        return InsuranceResult(success: true, data: policy);
      }
      return InsuranceResult(success: false, message: data['message'] ?? 'Imeshindwa kununua bima');
    } catch (e) {
      return InsuranceResult(success: false, message: 'Kosa: $e');
    }
  }

  // ─── My Policies ───────────────────────────────────────────────

  Future<InsuranceListResult<InsurancePolicy>> getMyPolicies(int userId) async {
    try {
      final response = await http.get(Uri.parse('$_baseUrl/insurance/policies?user_id=$userId'));
      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        if (data['success'] == true) {
          final items = (data['data'] as List).map((j) => InsurancePolicy.fromJson(j)).toList();
          return InsuranceListResult(success: true, items: items);
        }
      }
      return InsuranceListResult(success: false, message: 'Imeshindwa kupakia bima zako');
    } catch (e) {
      return InsuranceListResult(success: false, message: 'Kosa: $e');
    }
  }

  Future<InsuranceResult<void>> cancelPolicy(int policyId) async {
    try {
      final response = await http.post(
        Uri.parse('$_baseUrl/insurance/policies/$policyId/cancel'),
        headers: {'Content-Type': 'application/json'},
      );
      final data = jsonDecode(response.body);
      if (response.statusCode == 200 && data['success'] == true) {
        return InsuranceResult(success: true);
      }
      return InsuranceResult(success: false, message: data['message'] ?? 'Imeshindwa kughairi');
    } catch (e) {
      return InsuranceResult(success: false, message: 'Kosa: $e');
    }
  }

  Future<InsuranceResult<void>> renewPolicy({
    required int policyId,
    required String paymentMethod,
    String? phoneNumber,
  }) async {
    try {
      final response = await http.post(
        Uri.parse('$_baseUrl/insurance/policies/$policyId/renew'),
        headers: {'Content-Type': 'application/json'},
        body: jsonEncode({
          'payment_method': paymentMethod,
          if (phoneNumber != null) 'phone_number': phoneNumber,
        }),
      );
      final data = jsonDecode(response.body);
      if (response.statusCode == 200 && data['success'] == true) {
        return InsuranceResult(success: true);
      }
      return InsuranceResult(success: false, message: data['message'] ?? 'Imeshindwa kuhuisha');
    } catch (e) {
      return InsuranceResult(success: false, message: 'Kosa: $e');
    }
  }

  // ─── Claims ────────────────────────────────────────────────────

  Future<InsuranceResult<InsuranceClaim>> submitClaim({
    required int policyId,
    required double amount,
    required String reason,
    String? description,
  }) async {
    try {
      final response = await http.post(
        Uri.parse('$_baseUrl/insurance/claims'),
        headers: {'Content-Type': 'application/json'},
        body: jsonEncode({
          'policy_id': policyId,
          'amount': amount,
          'reason': reason,
          if (description != null) 'description': description,
        }),
      );
      final data = jsonDecode(response.body);
      if (response.statusCode == 200 && data['success'] == true) {
        return InsuranceResult(success: true, data: InsuranceClaim.fromJson(data['data']));
      }
      return InsuranceResult(success: false, message: data['message'] ?? 'Imeshindwa kutuma dai');
    } catch (e) {
      return InsuranceResult(success: false, message: 'Kosa: $e');
    }
  }

  Future<InsuranceListResult<InsuranceClaim>> getMyClaims(int userId) async {
    try {
      final response = await http.get(Uri.parse('$_baseUrl/insurance/claims?user_id=$userId'));
      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        if (data['success'] == true) {
          final items = (data['data'] as List).map((j) => InsuranceClaim.fromJson(j)).toList();
          return InsuranceListResult(success: true, items: items);
        }
      }
      return InsuranceListResult(success: false, message: 'Imeshindwa kupakia madai');
    } catch (e) {
      return InsuranceListResult(success: false, message: 'Kosa: $e');
    }
  }

  // ─── Recommendations (cross-module context) ────────────────────

  Future<InsuranceListResult<InsuranceProduct>> getRecommendations(int userId) async {
    try {
      final response = await http.get(
        Uri.parse('$_baseUrl/insurance/recommendations?user_id=$userId'),
      );
      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        if (data['success'] == true) {
          final items = (data['data'] as List).map((j) => InsuranceProduct.fromJson(j)).toList();
          return InsuranceListResult(success: true, items: items);
        }
      }
      return InsuranceListResult(success: false);
    } catch (e) {
      return InsuranceListResult(success: false);
    }
  }
}
