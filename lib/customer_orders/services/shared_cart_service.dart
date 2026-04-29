import 'dart:convert';

import 'package:flutter/foundation.dart';
import 'package:http/http.dart' as http;

import '../../config/api_config.dart';
import '../models/shared_cart.dart';

class SharedCartService {
  static Future<SharedCart?> create({
    required int ownerUserId,
    int? partnerId,
  }) async {
    final body = <String, dynamic>{'owner_user_id': ownerUserId};
    if (partnerId != null) body['partner_id'] = partnerId;
    try {
      final res = await http.post(
        Uri.parse('${ApiConfig.baseUrl}/shared-carts'),
        headers: const {'Content-Type': 'application/json'},
        body: jsonEncode(body),
      );
      final r = jsonDecode(res.body);
      if (res.statusCode >= 200 && res.statusCode < 300 && r['success'] == true) {
        return SharedCart.fromJson((r['data'] as Map).cast<String, dynamic>());
      }
    } catch (e) {
      debugPrint('[SharedCartService] create error: $e');
    }
    return null;
  }

  static Future<({SharedCart cart, List<SharedCartItem> items})?> show(
    String token,
  ) async {
    try {
      final res = await http
          .get(Uri.parse('${ApiConfig.baseUrl}/shared-carts/$token'));
      if (res.statusCode != 200) return null;
      final r = jsonDecode(res.body);
      if (r['success'] != true) return null;
      final data = (r['data'] as Map).cast<String, dynamic>();
      final cart = SharedCart.fromJson((data['cart'] as Map).cast<String, dynamic>());
      final items = ((data['items'] as List?) ?? const [])
          .whereType<Map>()
          .map((m) => SharedCartItem.fromJson(m.cast<String, dynamic>()))
          .toList();
      return (cart: cart, items: items);
    } catch (e) {
      debugPrint('[SharedCartService] show error: $e');
      return null;
    }
  }

  static Future<bool> addItem({
    required String token,
    required int userId,
    required int partnerProductId,
    int quantity = 1,
    String? notes,
  }) async {
    try {
      final body = <String, dynamic>{
        'user_id': userId,
        'partner_product_id': partnerProductId,
        'quantity': quantity,
      };
      if (notes != null && notes.isNotEmpty) body['notes'] = notes;
      final res = await http.post(
        Uri.parse('${ApiConfig.baseUrl}/shared-carts/$token/items'),
        headers: const {'Content-Type': 'application/json'},
        body: jsonEncode(body),
      );
      return res.statusCode >= 200 && res.statusCode < 300;
    } catch (_) {
      return false;
    }
  }

  static Future<bool> removeItem({
    required String token,
    required int itemId,
  }) async {
    try {
      final res = await http.delete(
        Uri.parse('${ApiConfig.baseUrl}/shared-carts/$token/items/$itemId'),
      );
      return res.statusCode == 200;
    } catch (_) {
      return false;
    }
  }

  static Future<bool> settle(String token) async {
    try {
      final res = await http.post(
        Uri.parse('${ApiConfig.baseUrl}/shared-carts/$token/settle'),
      );
      return res.statusCode == 200;
    } catch (_) {
      return false;
    }
  }
}
