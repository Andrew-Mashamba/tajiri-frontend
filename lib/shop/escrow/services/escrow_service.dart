import 'dart:convert';
import 'package:http/http.dart' as http;
import '../../../services/http_retry.dart';
import '../../../config/api_config.dart';
import '../../../services/graphql/graphql_escrow_service.dart';
import '../models/escrow_models.dart';

class EscrowService {
  static const String _base = '${ApiConfig.baseUrl}/v1';

  static Future<EscrowInfo?> getOrderEscrow(
      int orderId, String token) async {
    if (ApiConfig.useGraphqlBackend) {
      return GraphqlEscrowService.getOrderEscrow(orderId);
    }
    try {
      final response = await httpGetWithRetry(
        Uri.parse('$_base/shop/orders/$orderId/escrow'),
        headers: ApiConfig.authHeaders(token),
      );
      if (response.statusCode == 200) {
        final body = jsonDecode(response.body) as Map<String, dynamic>;
        if (body['success'] == true && body['data'] != null) {
          return EscrowInfo.fromJson(body['data'] as Map<String, dynamic>);
        }
      }
      return null;
    } catch (_) {
      return null;
    }
  }

  static Future<bool> releaseEscrow(int orderId, String token) async {
    if (ApiConfig.useGraphqlBackend) {
      return GraphqlEscrowService.releaseEscrow(orderId);
    }
    try {
      final response = await http.post(
        Uri.parse('$_base/shop/orders/$orderId/escrow/release'),
        headers: ApiConfig.authHeaders(token),
      );
      if (response.statusCode == 200) {
        final body = jsonDecode(response.body) as Map<String, dynamic>;
        return body['success'] == true;
      }
      return false;
    } catch (_) {
      return false;
    }
  }

  static Future<bool> raiseDispute(
    int orderId,
    String token, {
    required String reason,
    String? description,
    List<String> evidenceUrls = const [],
  }) async {
    if (ApiConfig.useGraphqlBackend) {
      return GraphqlEscrowService.raiseDispute(
        orderId,
        reason: reason,
        description: description,
        evidenceUrls: evidenceUrls,
      );
    }
    try {
      final response = await http.post(
        Uri.parse('$_base/shop/orders/$orderId/escrow/dispute'),
        headers: ApiConfig.authHeaders(token),
        body: jsonEncode({
          'reason': reason,
          if (description != null && description.isNotEmpty)
            'description': description,
          'evidence_urls': evidenceUrls,
        }),
      );
      if (response.statusCode == 200 || response.statusCode == 201) {
        final body = jsonDecode(response.body) as Map<String, dynamic>;
        return body['success'] == true;
      }
      return false;
    } catch (_) {
      return false;
    }
  }

  static Future<EscrowDispute?> getDispute(
      int orderId, String token) async {
    if (ApiConfig.useGraphqlBackend) {
      return GraphqlEscrowService.getDispute(orderId);
    }
    try {
      final response = await httpGetWithRetry(
        Uri.parse('$_base/shop/orders/$orderId/escrow/dispute'),
        headers: ApiConfig.authHeaders(token),
      );
      if (response.statusCode == 200) {
        final body = jsonDecode(response.body) as Map<String, dynamic>;
        if (body['success'] == true && body['data'] != null) {
          final data = body['data'] as Map<String, dynamic>;
          if (data['dispute'] != null) {
            return EscrowDispute.fromJson(
                data['dispute'] as Map<String, dynamic>);
          }
        }
      }
      return null;
    } catch (_) {
      return null;
    }
  }

  static Future<bool> sellerRespondToDispute(
      int orderId, String response, String token) async {
    if (ApiConfig.useGraphqlBackend) {
      return GraphqlEscrowService.sellerRespondToDispute(orderId, response);
    }
    try {
      final res = await http.post(
        Uri.parse('$_base/shop/orders/$orderId/escrow/dispute/respond'),
        headers: ApiConfig.authHeaders(token),
        body: jsonEncode({'response': response}),
      );
      if (res.statusCode == 200) {
        final body = jsonDecode(res.body) as Map<String, dynamic>;
        return body['success'] == true;
      }
      return false;
    } catch (_) {
      return false;
    }
  }

  static Future<List<EscrowDispute>> listDisputes(
    String token, {
    String? status,
    int page = 1,
    int perPage = 20,
  }) async {
    if (ApiConfig.useGraphqlBackend) {
      return GraphqlEscrowService.listDisputes(status: status);
    }
    try {
      final params = <String, String>{'per_page': '$perPage', 'page': '$page'};
      if (status != null) params['status'] = status;

      final uri = Uri.parse('$_base/shop/disputes')
          .replace(queryParameters: params);
      final response = await httpGetWithRetry(uri, headers: ApiConfig.authHeaders(token));
      if (response.statusCode == 200) {
        final body = jsonDecode(response.body) as Map<String, dynamic>;
        if (body['success'] == true && body['data'] != null) {
          final data = body['data'] as Map<String, dynamic>;
          final list = data['disputes'] as List<dynamic>? ?? [];
          return list
              .map((e) =>
                  EscrowDispute.fromJson(e as Map<String, dynamic>))
              .toList();
        }
      }
      return [];
    } catch (_) {
      return [];
    }
  }

  static Future<EscrowWalletSummary?> getWalletSummary(String token) async {
    if (ApiConfig.useGraphqlBackend) {
      return GraphqlEscrowService.getWalletSummary();
    }
    try {
      final response = await httpGetWithRetry(
        Uri.parse('$_base/shop/escrow/wallet-summary'),
        headers: ApiConfig.authHeaders(token),
      );
      if (response.statusCode == 200) {
        final body = jsonDecode(response.body) as Map<String, dynamic>;
        if (body['success'] == true && body['data'] != null) {
          return EscrowWalletSummary.fromJson(
              body['data'] as Map<String, dynamic>);
        }
      }
      return null;
    } catch (_) {
      return null;
    }
  }
}
