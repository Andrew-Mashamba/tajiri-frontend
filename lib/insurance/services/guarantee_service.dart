import 'dart:convert';
import 'package:http/http.dart' as http;
import '../../config/api_config.dart';

String get _baseUrl => ApiConfig.baseUrl;

class GuaranteePolicyResult {
  final bool success;
  final Map<String, dynamic>? policy;
  final String? message;
  GuaranteePolicyResult({required this.success, this.policy, this.message});
}

class GuaranteeClaimResult {
  final bool success;
  final Map<String, dynamic>? claim;
  final String? message;
  GuaranteeClaimResult({required this.success, this.claim, this.message});
}

class GuaranteeService {
  static Future<GuaranteePolicyResult> createPolicy({
    required int partnerUserId,
    String? skillCategory,
    int premiumTzsMonthly = 15000,
    int coverageTzs = 500000,
    int deductibleTzs = 25000,
  }) async {
    try {
      final res = await http.post(
        Uri.parse('$_baseUrl/guarantee-policies'),
        headers: const {'Content-Type': 'application/json'},
        body: jsonEncode({
          'partner_user_id': partnerUserId,
          'skill_category': skillCategory,
          'premium_tzs_monthly': premiumTzsMonthly,
          'coverage_tzs': coverageTzs,
          'deductible_tzs': deductibleTzs,
        }),
      );
      final body = jsonDecode(res.body) as Map<String, dynamic>;
      return GuaranteePolicyResult(
        success: body['success'] == true,
        policy: body['data'] as Map<String, dynamic>?,
        message: body['message']?.toString(),
      );
    } catch (e) {
      return GuaranteePolicyResult(success: false, message: 'Error: $e');
    }
  }

  static Future<GuaranteePolicyResult> listPolicies({required int partnerUserId}) async {
    try {
      final res = await http.get(
        Uri.parse('$_baseUrl/guarantee-policies?partner_user_id=$partnerUserId'),
        headers: const {'Accept': 'application/json'},
      );
      final body = jsonDecode(res.body) as Map<String, dynamic>;
      return GuaranteePolicyResult(
        success: body['success'] == true,
        policy: body['data'] is List && (body['data'] as List).isNotEmpty
            ? (body['data'] as List).first as Map<String, dynamic>
            : null,
        message: body['message']?.toString(),
      );
    } catch (e) {
      return GuaranteePolicyResult(success: false, message: 'Error: $e');
    }
  }

  static Future<GuaranteeClaimResult> fileClaim({
    required int policyId,
    required int customerUserId,
    required String reason,
    required String description,
    int amountClaimedTzs = 0,
    List<String> photos = const [],
  }) async {
    try {
      final res = await http.post(
        Uri.parse('$_baseUrl/guarantee-claims'),
        headers: const {'Content-Type': 'application/json'},
        body: jsonEncode({
          'policy_id': policyId,
          'customer_user_id': customerUserId,
          'reason': reason,
          'description': description,
          'amount_claimed_tzs': amountClaimedTzs,
          'photos': photos,
        }),
      );
      final body = jsonDecode(res.body) as Map<String, dynamic>;
      return GuaranteeClaimResult(
        success: body['success'] == true,
        claim: body['data'] as Map<String, dynamic>?,
        message: body['message']?.toString(),
      );
    } catch (e) {
      return GuaranteeClaimResult(success: false, message: 'Error: $e');
    }
  }
}
