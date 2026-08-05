import 'dart:convert';
import 'package:http/http.dart' as http;
import '../../../services/http_retry.dart';
import '../../../config/api_config.dart';
import '../../../services/graphql/graphql_verification_service.dart';
import '../models/trust_models.dart';

/// Static service for seller verification & trust profile endpoints.
class SellerVerificationService {
  SellerVerificationService._();

  static Future<SellerTrustProfile?> getTrustProfile(
    int sellerId,
    String token,
  ) async {
    if (ApiConfig.useGraphqlBackend) {
      return GraphqlVerificationService.getTrustProfile(sellerId);
    }
    try {
      final uri = Uri.parse('${ApiConfig.baseUrl}/v1/shop/sellers/$sellerId/trust-profile');
      final res = await httpGetWithRetry(
        uri,
        headers: ApiConfig.authHeaders(token),
      ).timeout(const Duration(seconds: 10));

      if (res.statusCode == 200) {
        final data = jsonDecode(res.body) as Map<String, dynamic>;
        return SellerTrustProfile.fromJson(data);
      }
    } catch (_) {}
    return null;
  }

  static Future<bool> submitVerification(
    String token, {
    required String type,
    String? nidaNumber,
    String? brelaNumber,
  }) async {
    if (ApiConfig.useGraphqlBackend) {
      return GraphqlVerificationService.submitVerification(
        type: type,
        nidaNumber: nidaNumber,
        brelaNumber: brelaNumber,
      );
    }
    try {
      final uri = Uri.parse('${ApiConfig.baseUrl}/v1/shop/sellers/verification/submit');
      final body = <String, dynamic>{'type': type};
      if (nidaNumber != null && nidaNumber.isNotEmpty) body['nida_number'] = nidaNumber;
      if (brelaNumber != null && brelaNumber.isNotEmpty) body['brela_number'] = brelaNumber;

      final res = await http.post(
        uri,
        headers: ApiConfig.authHeaders(token),
        body: jsonEncode(body),
      ).timeout(const Duration(seconds: 15));

      if (res.statusCode == 200) {
        final data = jsonDecode(res.body) as Map<String, dynamic>;
        return data['success'] == true;
      }
    } catch (_) {}
    return false;
  }

  static Future<SellerVerificationStatus?> getVerificationStatus(
    String token,
  ) async {
    if (ApiConfig.useGraphqlBackend) {
      return GraphqlVerificationService.getVerificationStatus();
    }
    try {
      final uri = Uri.parse('${ApiConfig.baseUrl}/v1/shop/sellers/verification/status');
      final res = await httpGetWithRetry(
        uri,
        headers: ApiConfig.authHeaders(token),
      ).timeout(const Duration(seconds: 10));

      if (res.statusCode == 200) {
        final data = jsonDecode(res.body) as Map<String, dynamic>;
        return SellerVerificationStatus.fromJson(data);
      }
    } catch (_) {}
    return null;
  }
}
