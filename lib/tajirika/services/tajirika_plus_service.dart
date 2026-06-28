import 'dart:convert';
import 'package:http/http.dart' as http;
import '../../services/http_retry.dart';
import '../../config/api_config.dart';
import '../../services/graphql/graphql_tajirika_sub_service.dart';

String get _baseUrl => ApiConfig.baseUrl;

class TajirikaPlusPlan {
  final String tier;
  final String name;
  final String nameSw;
  final int priceMonthlyTzs;
  final List<String> benefits;
  final List<String> benefitsSw;

  TajirikaPlusPlan({
    required this.tier,
    required this.name,
    required this.nameSw,
    required this.priceMonthlyTzs,
    required this.benefits,
    required this.benefitsSw,
  });

  factory TajirikaPlusPlan.fromJson(Map<String, dynamic> json) {
    return TajirikaPlusPlan(
      tier: json['tier']?.toString() ?? 'plus',
      name: json['name']?.toString() ?? 'Tajirika+',
      nameSw: json['name_sw']?.toString() ?? 'Tajirika+',
      priceMonthlyTzs: (json['price_monthly_tzs'] as num?)?.toInt() ?? 15000,
      benefits: (json['benefits'] as List?)?.map((e) => e.toString()).toList() ?? const [],
      benefitsSw: (json['benefits_sw'] as List?)?.map((e) => e.toString()).toList() ?? const [],
    );
  }
}

class TajirikaPlusStatus {
  final bool active;
  final String? tier;
  final DateTime? expiresAt;
  final bool autoRenew;

  TajirikaPlusStatus({
    required this.active,
    this.tier,
    this.expiresAt,
    this.autoRenew = false,
  });

  factory TajirikaPlusStatus.fromJson(Map<String, dynamic> json) {
    return TajirikaPlusStatus(
      active: json['active'] == true,
      tier: json['tier']?.toString(),
      expiresAt: json['expires_at'] != null
          ? DateTime.tryParse(json['expires_at'].toString())
          : null,
      autoRenew: json['auto_renew'] == true,
    );
  }
}

class TajirikaPlusResult {
  final bool success;
  final TajirikaPlusStatus? status;
  final List<TajirikaPlusPlan>? plans;
  final String? message;

  TajirikaPlusResult({required this.success, this.status, this.plans, this.message});
}

class TajirikaPlusService {
  static Future<TajirikaPlusResult> getPlans() async {
    if (ApiConfig.useGraphqlBackend) {
      return GraphqlTajirikaSubService.getPlans();
    }
    try {
      final res = await httpGetWithRetry(
        Uri.parse('$_baseUrl/tajirika-plus/plans'),
        headers: {'Accept': 'application/json'},
      );
      final body = jsonDecode(res.body) as Map<String, dynamic>;
      final data = body['data'];
      return TajirikaPlusResult(
        success: body['success'] == true,
        plans: data is List
            ? data.map((m) => TajirikaPlusPlan.fromJson(m as Map<String, dynamic>)).toList()
            : null,
        message: body['message']?.toString(),
      );
    } catch (e) {
      return TajirikaPlusResult(success: false, message: 'Error: $e');
    }
  }

  static Future<TajirikaPlusResult> getStatus(int partnerUserId) async {
    if (ApiConfig.useGraphqlBackend) {
      return GraphqlTajirikaSubService.getStatus(partnerUserId);
    }
    try {
      final res = await httpGetWithRetry(
        Uri.parse('$_baseUrl/tajirika-plus/status?partner_user_id=$partnerUserId'),
        headers: {'Accept': 'application/json'},
      );
      final body = jsonDecode(res.body) as Map<String, dynamic>;
      final data = body['data'];
      return TajirikaPlusResult(
        success: body['success'] == true,
        status: data is Map<String, dynamic> ? TajirikaPlusStatus.fromJson(data) : null,
        message: body['message']?.toString(),
      );
    } catch (e) {
      return TajirikaPlusResult(success: false, message: 'Error: $e');
    }
  }

  static Future<TajirikaPlusResult> subscribe({
    required int partnerUserId,
    required String tier,
    String paymentMethod = 'wallet_auto_debit',
  }) async {
    if (ApiConfig.useGraphqlBackend) {
      return GraphqlTajirikaSubService.subscribe(
        partnerUserId: partnerUserId,
        tier: tier,
        paymentMethod: paymentMethod,
      );
    }
    try {
      final res = await http.post(
        Uri.parse('$_baseUrl/tajirika-plus/subscribe'),
        headers: const {'Content-Type': 'application/json'},
        body: jsonEncode({
          'partner_user_id': partnerUserId,
          'tier': tier,
          'payment_method': paymentMethod,
        }),
      );
      final body = jsonDecode(res.body) as Map<String, dynamic>;
      final data = body['data'];
      return TajirikaPlusResult(
        success: body['success'] == true,
        status: data is Map<String, dynamic> ? TajirikaPlusStatus.fromJson(data) : null,
        message: body['message']?.toString(),
      );
    } catch (e) {
      return TajirikaPlusResult(success: false, message: 'Error: $e');
    }
  }
}
