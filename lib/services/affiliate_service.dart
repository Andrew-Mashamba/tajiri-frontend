// lib/services/affiliate_service.dart
//
// UN-014 — strategy posts.md row 79 (affiliate_conversion·author).
// Lets a creator set their affiliate code and a buyer resolve a code
// to a user_id during checkout.

import 'dart:convert';
import 'package:http/http.dart' as http;
import 'http_retry.dart';
import '../config/api_config.dart';
import 'graphql/graphql_affiliate_service.dart';

class AffiliateLookup {
  final int userId;
  final String name;
  final String? username;
  AffiliateLookup({required this.userId, required this.name, this.username});

  factory AffiliateLookup.fromJson(Map<String, dynamic> j) => AffiliateLookup(
        userId: (j['user_id'] as num?)?.toInt() ?? 0,
        name: j['name'] as String? ?? '',
        username: j['username'] as String?,
      );
}

class AffiliateService {
  String get _base => ApiConfig.baseUrl;

  Future<String?> getMyCode(int userId) async {
    if (ApiConfig.useGraphqlBackend) {
      return GraphqlAffiliateService.getMyCode();
    }
    try {
      final resp = await httpGetWithRetry(Uri.parse('$_base/users/$userId/affiliate-code'));
      if (resp.statusCode != 200) return null;
      final body = jsonDecode(resp.body) as Map<String, dynamic>;
      if (body['success'] != true) return null;
      return body['data']?['affiliate_code'] as String?;
    } catch (_) {
      return null;
    }
  }

  /// Set or clear the user's affiliate code. Pass `null` or `''` to clear.
  /// Returns:
  ///   `true`  — saved
  ///   `false` — server error
  ///   throws `'taken'` — code is in use by another user (HTTP 409)
  Future<bool> setMyCode(int userId, String? code) async {
    if (ApiConfig.useGraphqlBackend) {
      return GraphqlAffiliateService.setMyCode(code);
    }
    try {
      final resp = await http.put(
        Uri.parse('$_base/users/$userId/affiliate-code'),
        headers: {'Content-Type': 'application/json'},
        body: jsonEncode({'affiliate_code': code ?? ''}),
      );
      if (resp.statusCode == 409) throw 'taken';
      return resp.statusCode == 200;
    } catch (e) {
      if (e == 'taken') rethrow;
      return false;
    }
  }

  Future<AffiliateLookup?> lookup(String code) async {
    if (ApiConfig.useGraphqlBackend) {
      return GraphqlAffiliateService.lookup(code);
    }
    try {
      final resp = await httpGetWithRetry(
        Uri.parse('$_base/affiliate-codes/${Uri.encodeComponent(code)}/lookup'),
      );
      if (resp.statusCode != 200) return null;
      final body = jsonDecode(resp.body) as Map<String, dynamic>;
      if (body['success'] != true) return null;
      final inner = body['data'];
      if (inner is! Map<String, dynamic>) return null;
      return AffiliateLookup.fromJson(inner);
    } catch (_) {
      return null;
    }
  }
}
