import 'dart:convert';
import 'package:flutter/foundation.dart';
import 'package:http/http.dart' as http;
import '../config/api_config.dart';
import '../models/payment_models.dart';

String get _baseUrl => ApiConfig.baseUrl;

/// Service for creator fund pool and payout operations.
/// Instance-based (same pattern as CreatorService, FeedService).
class PaymentService {
  /// GET /api/fund-pool/current
  Future<CreatorFundPool?> getCurrentPool(String token) async {
    try {
      final response = await http.get(
        Uri.parse('$_baseUrl/fund-pool/current'),
        headers: ApiConfig.authHeaders(token),
      );
      if (response.statusCode == 200) {
        final body = jsonDecode(response.body);
        final data = body['data'] ?? body;
        if (data is Map<String, dynamic>) {
          return CreatorFundPool.fromJson(data);
        }
      }
      if (kDebugMode) {
        debugPrint('[PaymentService] getCurrentPool ${response.statusCode}');
      }
      return null;
    } catch (e) {
      if (kDebugMode) debugPrint('[PaymentService] getCurrentPool error: $e');
      return null;
    }
  }

  /// GET /api/creators/{id}/payouts
  Future<List<CreatorFundPayout>> getPayoutHistory(
      String token, int creatorId) async {
    try {
      final response = await http.get(
        Uri.parse('$_baseUrl/creators/$creatorId/payouts'),
        headers: ApiConfig.authHeaders(token),
      );
      if (response.statusCode == 200) {
        final body = jsonDecode(response.body);
        final list = body['data'] ?? body;
        if (list is List) {
          return list
              .whereType<Map<String, dynamic>>()
              .map(CreatorFundPayout.fromJson)
              .toList();
        }
      }
      if (kDebugMode) {
        debugPrint('[PaymentService] getPayoutHistory ${response.statusCode}');
      }
      return [];
    } catch (e) {
      if (kDebugMode) debugPrint('[PaymentService] getPayoutHistory error: $e');
      return [];
    }
  }

  /// POST /api/creators/{id}/payout/request
  Future<bool> requestPayout(String token, int creatorId) async {
    try {
      final response = await http.post(
        Uri.parse('$_baseUrl/creators/$creatorId/payout/request'),
        headers: ApiConfig.authHeaders(token),
      );
      return response.statusCode == 200 || response.statusCode == 201;
    } catch (e) {
      if (kDebugMode) debugPrint('[PaymentService] requestPayout error: $e');
      return false;
    }
  }
}
