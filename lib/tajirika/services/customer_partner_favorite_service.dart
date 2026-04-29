import 'dart:convert';

import 'package:http/http.dart' as http;

import '../../config/api_config.dart';
import '../models/customer_partner_favorite.dart';

class CustomerPartnerFavoriteService {
  static Future<List<CustomerPartnerFavorite>> listForCustomer(int customerUserId) async {
    final uri = Uri.parse('${ApiConfig.baseUrl}/customer-partner-favorites')
        .replace(queryParameters: {'customer_user_id': '$customerUserId'});
    try {
      final res = await http.get(uri);
      if (res.statusCode != 200) return const [];
      final body = jsonDecode(res.body);
      if (body['success'] != true) return const [];
      return ((body['data'] as List?) ?? const [])
          .whereType<Map>()
          .map((m) => CustomerPartnerFavorite.fromJson(m.cast<String, dynamic>()))
          .toList();
    } catch (_) {
      return const [];
    }
  }

  static Future<bool> add({
    required int customerUserId,
    required int partnerUserId,
    String? skillCategory,
  }) async {
    try {
      final body = <String, dynamic>{
        'customer_user_id': customerUserId,
        'partner_user_id': partnerUserId,
      };
      if (skillCategory != null && skillCategory.isNotEmpty) {
        body['skill_category'] = skillCategory;
      }
      final res = await http.post(
        Uri.parse('${ApiConfig.baseUrl}/customer-partner-favorites'),
        headers: const {'Content-Type': 'application/json'},
        body: jsonEncode(body),
      );
      return res.statusCode >= 200 && res.statusCode < 300;
    } catch (_) {
      return false;
    }
  }

  static Future<bool> remove(int favoriteId) async {
    try {
      final res = await http.delete(
        Uri.parse('${ApiConfig.baseUrl}/customer-partner-favorites/$favoriteId'),
      );
      return res.statusCode == 200;
    } catch (_) {
      return false;
    }
  }
}
