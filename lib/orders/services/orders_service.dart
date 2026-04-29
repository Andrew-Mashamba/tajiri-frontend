// lib/orders/services/orders_service.dart
import 'dart:convert';
import 'package:http/http.dart' as http;

import '../../config/api_config.dart';
import '../models/incoming_order.dart';

class OrdersResult<T> {
  final bool success;
  final T? data;
  final String? message;
  OrdersResult({required this.success, this.data, this.message});
}

class OrdersListResult {
  final bool success;
  final List<IncomingOrder> data;
  final String? message;
  OrdersListResult({required this.success, this.data = const [], this.message});
}

class OrdersService {
  static const String _baseUrl = '${ApiConfig.baseUrl}/business';

  /// GET /api/business/users/{userId}/incoming-orders
  /// Returns orders destined for any business the user owns.
  static Future<OrdersListResult> getIncomingOrders(
    String token,
    int userId, {
    int? receivingBusinessId,
    String? status,
  }) async {
    try {
      var url = '$_baseUrl/users/$userId/incoming-orders';
      final params = <String, String>{};
      if (receivingBusinessId != null) {
        params['receiving_business_id'] = receivingBusinessId.toString();
      }
      if (status != null && status.isNotEmpty) {
        // Buyer-side writes 'sent' while receiver UI sends 'submitted' —
        // expand so the backend whereIn matches both wire values.
        params['status'] = status == 'submitted' ? 'submitted,sent' : status;
      }
      if (params.isNotEmpty) {
        url += '?${Uri(queryParameters: params).query}';
      }
      final res =
          await http.get(Uri.parse(url), headers: ApiConfig.authHeaders(token));
      if (res.statusCode == 200) {
        final body = jsonDecode(res.body);
        if (body['success'] == true) {
          final list = (body['data'] as List? ?? [])
              .whereType<Map>()
              .map((e) => IncomingOrder.fromJson(e.cast<String, dynamic>()))
              .toList();
          return OrdersListResult(success: true, data: list);
        }
        return OrdersListResult(
            success: false, message: body['message']?.toString());
      }
      return OrdersListResult(
          success: false, message: 'HTTP ${res.statusCode}');
    } catch (e) {
      return OrdersListResult(success: false, message: e.toString());
    }
  }

  /// PATCH /api/business/incoming-orders/{id}/status
  /// Receiver updates the order status.
  static Future<OrdersResult<void>> updateStatus(
    String token,
    int orderId,
    int userId,
    OrderStatus status, {
    String? reason,
  }) async {
    try {
      final url = '$_baseUrl/incoming-orders/$orderId/status';
      final body = <String, dynamic>{
        'user_id': userId,
        'status': status.wire,
      };
      if (reason != null && reason.isNotEmpty) {
        body['rejection_reason'] = reason;
      }
      final res = await http.patch(
        Uri.parse(url),
        headers: ApiConfig.authHeaders(token),
        body: jsonEncode(body),
      );
      if (res.statusCode == 200) {
        final body = jsonDecode(res.body);
        return OrdersResult(
            success: body['success'] == true,
            message: body['message']?.toString());
      }
      return OrdersResult(success: false, message: 'HTTP ${res.statusCode}');
    } catch (e) {
      return OrdersResult(success: false, message: e.toString());
    }
  }
}
