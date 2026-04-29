import 'dart:convert';

import 'package:flutter/foundation.dart';
import 'package:http/http.dart' as http;

import '../../config/api_config.dart';
import '../models/product_variant.dart';

void _log(String m) => debugPrint('[ProductVariantService] $m');

class ProductVariantService {
  static Future<List<ProductVariant>> listForProduct(int productId) async {
    final uri = Uri.parse(
      '${ApiConfig.baseUrl}/partner-product-variants',
    ).replace(queryParameters: {'partner_product_id': '$productId'});
    try {
      final res = await http.get(uri);
      if (res.statusCode != 200) return const [];
      final body = jsonDecode(res.body);
      if (body['success'] != true) return const [];
      final list = (body['data'] as List?) ?? const [];
      return list
          .whereType<Map>()
          .map((m) => ProductVariant.fromJson(m.cast<String, dynamic>()))
          .toList();
    } catch (e) {
      _log('list error: $e');
      return const [];
    }
  }

  static Future<ProductVariant?> create({
    required int partnerProductId,
    String? labelSw,
    String? labelEn,
    required int priceTzs,
    int leadTimeHours = 0,
    int durationMinutes = 0,
    int sortOrder = 0,
  }) async {
    final body = <String, dynamic>{
      'partner_product_id': partnerProductId,
      'price_tzs': priceTzs,
      'lead_time_hours': leadTimeHours,
      'duration_minutes': durationMinutes,
      'sort_order': sortOrder,
    };
    if (labelSw != null && labelSw.isNotEmpty) body['label_sw'] = labelSw;
    if (labelEn != null && labelEn.isNotEmpty) body['label_en'] = labelEn;
    try {
      final res = await http.post(
        Uri.parse('${ApiConfig.baseUrl}/partner-product-variants'),
        headers: const {'Content-Type': 'application/json'},
        body: jsonEncode(body),
      );
      final r = jsonDecode(res.body);
      if (res.statusCode >= 200 && res.statusCode < 300 && r['success'] == true) {
        return ProductVariant.fromJson((r['data'] as Map).cast<String, dynamic>());
      }
    } catch (e) {
      _log('create error: $e');
    }
    return null;
  }

  static Future<bool> delete(int id) async {
    try {
      final res = await http.delete(
        Uri.parse('${ApiConfig.baseUrl}/partner-product-variants/$id'),
      );
      return res.statusCode == 200;
    } catch (_) {
      return false;
    }
  }
}
