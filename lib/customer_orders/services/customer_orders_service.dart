import 'dart:convert';
import 'package:flutter/foundation.dart';
import 'package:http/http.dart' as http;

import '../../config/api_config.dart';
import '../models/customer_order.dart';

class CustomerOrderResult<T> {
  final bool success;
  final T? data;
  final String? message;

  /// Populated for non-success responses so callers can branch on 409/422
  /// (stale state) and trigger a refresh.
  final int? statusCode;
  CustomerOrderResult({
    required this.success,
    this.data,
    this.message,
    this.statusCode,
  });
}

class CustomerOrderListResult {
  final bool success;
  final List<CustomerOrder> items;
  final String? message;
  CustomerOrderListResult({required this.success, this.items = const [], this.message});
}

class BatchResult {
  final bool success;
  final int count;
  final String? message;
  BatchResult({required this.success, this.count = 0, this.message});
}

class CustomerOrdersService {
  static const String _baseUrl = ApiConfig.baseUrl;

  /// GET /customer-orders?user_id=X&role=partner&status=&limit=&offset=
  static Future<CustomerOrderListResult> list({
    required int userId,
    String role = 'partner',
    String? status,
    int limit = 50,
    int offset = 0,
  }) async {
    try {
      final params = <String, String>{
        'user_id': '$userId',
        'role': role,
        'limit': '$limit',
        'offset': '$offset',
        if (status != null && status.isNotEmpty) 'status': status,
      };
      final uri = Uri.parse('$_baseUrl/customer-orders')
          .replace(queryParameters: params);
      final res = await http.get(uri);
      final body = jsonDecode(res.body);
      if (res.statusCode == 200 && body['success'] == true) {
        final raw = body['data'] as List? ?? const [];
        final items = raw
            .whereType<Map>()
            .map((m) => CustomerOrder.fromJson(m.cast<String, dynamic>()))
            .toList();
        return CustomerOrderListResult(success: true, items: items);
      }
      return CustomerOrderListResult(
          success: false, message: body['message']?.toString() ?? 'HTTP ${res.statusCode}');
    } catch (e) {
      return CustomerOrderListResult(success: false, message: 'Kosa: $e');
    }
  }

  /// GET /customer-orders/{source}/{id}?user_id=X
  static Future<CustomerOrderResult<CustomerOrder>> get({
    required int userId,
    required CustomerOrderSource source,
    required int id,
  }) async {
    try {
      final uri = Uri.parse('$_baseUrl/customer-orders/${source.apiValue}/$id')
          .replace(queryParameters: {'user_id': '$userId'});
      final res = await http.get(uri);
      final body = jsonDecode(res.body);
      if (res.statusCode == 200 && body['success'] == true) {
        return CustomerOrderResult(
          success: true,
          data: CustomerOrder.fromJson(body['data'] as Map<String, dynamic>),
        );
      }
      return CustomerOrderResult(
          success: false, message: body['message']?.toString() ?? 'HTTP ${res.statusCode}');
    } catch (e) {
      return CustomerOrderResult(success: false, message: 'Kosa: $e');
    }
  }

  /// POST /customer-orders/{source}/{id}/{action}
  /// action: accept | reject | ready | dispatch | complete | cancel
  static Future<CustomerOrderResult<CustomerOrder>> action({
    required int userId,
    required CustomerOrderSource source,
    required int id,
    required String action,
    String? reason,
  }) async {
    try {
      final uri = Uri.parse('$_baseUrl/customer-orders/${source.apiValue}/$id/$action');
      final res = await http.post(
        uri,
        headers: {'Content-Type': 'application/json'},
        body: jsonEncode({
          'user_id': userId,
          if (reason != null && reason.isNotEmpty) 'reason': reason,
        }),
      );
      final body = jsonDecode(res.body);
      if ((res.statusCode == 200 || res.statusCode == 201) && body['success'] == true) {
        return CustomerOrderResult(
          success: true,
          data: body['data'] is Map<String, dynamic>
              ? CustomerOrder.fromJson(body['data'] as Map<String, dynamic>)
              : null,
        );
      }
      return CustomerOrderResult(
        success: false,
        message: body['message']?.toString() ?? 'HTTP ${res.statusCode}',
        statusCode: res.statusCode,
      );
    } catch (e) {
      return CustomerOrderResult(success: false, message: 'Kosa: $e');
    }
  }

  /// POST /customer-orders/batch-accept
  static Future<BatchResult> batchAccept({
    required int userId,
    required List<Map<String, dynamic>> items,
  }) async {
    try {
      final uri = Uri.parse('$_baseUrl/customer-orders/batch-accept');
      final res = await http.post(
        uri,
        headers: {'Content-Type': 'application/json'},
        body: jsonEncode({'user_id': userId, 'items': items}),
      );
      final body = jsonDecode(res.body);
      if ((res.statusCode == 200 || res.statusCode == 201) && body['success'] == true) {
        return BatchResult(
          success: true,
          count: (body['count'] as num?)?.toInt() ?? 0,
        );
      }
      return BatchResult(
        success: false,
        message: body['message']?.toString() ?? 'HTTP ${res.statusCode}',
      );
    } catch (e) {
      return BatchResult(success: false, message: 'Kosa: $e');
    }
  }

  /// POST /customer-orders/batch-decline
  static Future<BatchResult> batchDecline({
    required int userId,
    required List<Map<String, dynamic>> items,
  }) async {
    try {
      final uri = Uri.parse('$_baseUrl/customer-orders/batch-decline');
      final res = await http.post(
        uri,
        headers: {'Content-Type': 'application/json'},
        body: jsonEncode({'user_id': userId, 'items': items}),
      );
      final body = jsonDecode(res.body);
      if ((res.statusCode == 200 || res.statusCode == 201) && body['success'] == true) {
        return BatchResult(
          success: true,
          count: (body['count'] as num?)?.toInt() ?? 0,
        );
      }
      return BatchResult(
        success: false,
        message: body['message']?.toString() ?? 'HTTP ${res.statusCode}',
      );
    } catch (e) {
      return BatchResult(success: false, message: 'Kosa: $e');
    }
  }

  /// GET /partner-weekly-benchmarks?partner_user_id=
  static Future<Map<String, dynamic>?> weeklyBenchmark({required int partnerUserId}) async {
    try {
      final uri = Uri.parse('$_baseUrl/partner-weekly-benchmarks')
          .replace(queryParameters: {'partner_user_id': '$partnerUserId'});
      final res = await http.get(uri);
      final body = jsonDecode(res.body);
      if (res.statusCode == 200 && body['success'] == true) {
        return (body['data'] as Map).cast<String, dynamic>();
      }
      return null;
    } catch (e) {
      debugPrint('[CustomerOrdersService] benchmark error: $e');
      return null;
    }
  }
}
