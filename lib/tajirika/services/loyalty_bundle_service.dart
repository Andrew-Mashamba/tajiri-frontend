import 'dart:convert';

import 'package:flutter/foundation.dart';
import 'package:http/http.dart' as http;

import '../../services/http_retry.dart';
import '../../config/api_config.dart';
import '../../services/graphql/graphql_tajirika_loyalty_service.dart';
import '../models/loyalty_bundle.dart';

void _log(String m) => debugPrint('[LoyaltyBundleService] $m');

String _snippet(String body, [int max = 250]) {
  final t = body.replaceAll(RegExp(r'\s+'), ' ').trim();
  return t.length <= max ? t : '${t.substring(0, max)}…';
}

class LoyaltyBundleService {
  static Future<LoyaltyBundleListResult> listForPartner({
    required int partnerUserId,
  }) async {
    if (ApiConfig.useGraphqlBackend) {
      return GraphqlTajirikaLoyaltyService.listLoyaltyBundles(partnerUserId);
    }
    final uri = Uri.parse('${ApiConfig.baseUrl}/partner-c2b/loyalty-bundles')
        .replace(queryParameters: {'partner_user_id': '$partnerUserId'});
    _log('GET $uri');
    try {
      final res = await httpGetWithRetry(uri);
      _log('list status=${res.statusCode} body=${_snippet(res.body)}');
      final body = jsonDecode(res.body);
      if (res.statusCode == 200 && body['success'] == true) {
        final list = (body['data'] as List?) ?? const [];
        return LoyaltyBundleListResult(
          success: true,
          items: list
              .whereType<Map>()
              .map((m) => LoyaltyBundle.fromJson(m.cast<String, dynamic>()))
              .toList(),
        );
      }
      return LoyaltyBundleListResult(
        success: false,
        message: body['message']?.toString() ?? 'HTTP ${res.statusCode}',
        statusCode: res.statusCode,
      );
    } catch (e, s) {
      _log('list error: $e\n$s');
      return LoyaltyBundleListResult(success: false, message: 'Kosa: $e');
    }
  }

  static Future<bool> purchase({
    required int bundleId,
    required int customerUserId,
  }) async {
    if (ApiConfig.useGraphqlBackend) {
      return GraphqlTajirikaLoyaltyService.purchaseLoyaltyBundle(bundleId);
    }
    final url = '${ApiConfig.baseUrl}/partner-c2b/loyalty-bundles/$bundleId/purchase';
    _log('POST $url');
    try {
      final res = await http.post(
        Uri.parse(url),
        headers: const {'Content-Type': 'application/json'},
        body: jsonEncode({'customer_user_id': customerUserId}),
      );
      _log('purchase status=${res.statusCode} body=${_snippet(res.body)}');
      final body = jsonDecode(res.body);
      return res.statusCode >= 200 &&
          res.statusCode < 300 &&
          body['success'] == true;
    } catch (e, s) {
      _log('purchase error: $e\n$s');
      return false;
    }
  }
}
