import 'dart:convert';

import 'package:flutter/foundation.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:http/http.dart' as http;

import '../../config/api_config.dart';

/// Thin GraphQL HTTP client for TAJIRI-BACKEND (no REST shim).
class TajiriGraphqlClient {
  TajiriGraphqlClient._();
  static final TajiriGraphqlClient instance = TajiriGraphqlClient._();

  static const _storage = FlutterSecureStorage(
    aOptions: AndroidOptions(encryptedSharedPreferences: true),
  );
  static const _accessTokenKey = 'tajiri_access_token';

  Future<String?> _accessToken() async {
    return _storage.read(key: _accessTokenKey);
  }

  Future<Map<String, dynamic>> query(
    String document, {
    Map<String, dynamic>? variables,
    bool auth = true,
  }) async {
    return _post(document, variables: variables, auth: auth);
  }

  Future<Map<String, dynamic>> mutate(
    String document, {
    Map<String, dynamic>? variables,
    bool auth = false,
  }) async {
    return _post(document, variables: variables, auth: auth);
  }

  Future<Map<String, dynamic>> _post(
    String document, {
    Map<String, dynamic>? variables,
    bool auth = true,
  }) async {
    final headers = Map<String, String>.from(ApiConfig.headers);
    if (auth) {
      final token = await _accessToken();
      if (token == null || token.isEmpty) {
        throw StateError('No access token');
      }
      headers['Authorization'] = 'Bearer $token';
    }

    final response = await http
        .post(
          Uri.parse(ApiConfig.graphqlUrl),
          headers: headers,
          body: jsonEncode({
            'query': document,
            if (variables != null) 'variables': variables,
          }),
        )
        .timeout(const Duration(seconds: 15));

    final body = jsonDecode(response.body) as Map<String, dynamic>;
    if (body['errors'] != null) {
      final errors = body['errors'] as List;
      final message = errors.isNotEmpty
          ? (errors.first as Map<String, dynamic>)['message']?.toString()
          : 'GraphQL error';
      if (kDebugMode) {
        debugPrint('[TajiriGraphqlClient] $message');
      }
      throw Exception(message ?? 'GraphQL error');
    }
    final data = body['data'];
    if (data is! Map<String, dynamic>) {
      throw Exception('Invalid GraphQL response');
    }
    return data;
  }
}
