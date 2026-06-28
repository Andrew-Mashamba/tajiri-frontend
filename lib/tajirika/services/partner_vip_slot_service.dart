import 'dart:convert';

import 'package:http/http.dart' as http;

import '../../services/http_retry.dart';
import '../../config/api_config.dart';
import '../../services/graphql/graphql_tajirika_loyalty_service.dart';
import '../models/partner_vip_slot.dart';

class PartnerVipSlotService {
  static Future<List<PartnerVipSlot>> listForPartner(int partnerUserId) async {
    if (ApiConfig.useGraphqlBackend) {
      return GraphqlTajirikaLoyaltyService.listPartnerVipSlots(partnerUserId);
    }
    try {
      final res = await httpGetWithRetry(
        Uri.parse('${ApiConfig.baseUrl}/partner-vip-slots')
            .replace(queryParameters: {'partner_user_id': '$partnerUserId'}),
      );
      if (res.statusCode != 200) return const [];
      final body = jsonDecode(res.body);
      if (body['success'] != true) return const [];
      return ((body['data'] as List?) ?? const [])
          .whereType<Map>()
          .map((m) => PartnerVipSlot.fromJson(m.cast<String, dynamic>()))
          .toList();
    } catch (_) {
      return const [];
    }
  }

  static Future<bool> create({
    required int partnerUserId,
    required int customerUserId,
    String? skillCategory,
    required int weekday,
    required String slotTime,
  }) async {
    if (ApiConfig.useGraphqlBackend) {
      return GraphqlTajirikaLoyaltyService.createPartnerVipSlot(
        partnerUserId: partnerUserId,
        customerUserId: customerUserId,
        weekday: weekday,
        slotTime: slotTime,
        skillCategory: skillCategory,
      );
    }
    try {
      final body = <String, dynamic>{
        'partner_user_id': partnerUserId,
        'customer_user_id': customerUserId,
        'weekday': weekday,
        'slot_time': slotTime,
      };
      if (skillCategory != null && skillCategory.isNotEmpty) {
        body['skill_category'] = skillCategory;
      }
      final res = await http.post(
        Uri.parse('${ApiConfig.baseUrl}/partner-vip-slots'),
        headers: const {'Content-Type': 'application/json'},
        body: jsonEncode(body),
      );
      return res.statusCode >= 200 && res.statusCode < 300;
    } catch (_) {
      return false;
    }
  }

  static Future<bool> delete(int id) async {
    if (ApiConfig.useGraphqlBackend) {
      return GraphqlTajirikaLoyaltyService.deletePartnerVipSlot(id);
    }
    try {
      final res = await http.delete(
        Uri.parse('${ApiConfig.baseUrl}/partner-vip-slots/$id'),
      );
      return res.statusCode == 200;
    } catch (_) {
      return false;
    }
  }
}
