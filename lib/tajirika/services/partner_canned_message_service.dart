import 'dart:convert';

import 'package:http/http.dart' as http;

import '../../services/http_retry.dart';
import '../../config/api_config.dart';
import '../../services/graphql/graphql_tajirika_c2b_service.dart';
import '../models/partner_canned_message.dart';

class PartnerCannedMessageService {
  static Future<List<PartnerCannedMessage>> listForPartner(int partnerUserId) async {
    if (ApiConfig.useGraphqlBackend) {
      return GraphqlTajirikaC2bService.listPartnerCannedMessages(partnerUserId);
    }
    final uri = Uri.parse('${ApiConfig.baseUrl}/partner-canned-messages')
        .replace(queryParameters: {'partner_user_id': '$partnerUserId'});
    try {
      final res = await httpGetWithRetry(uri);
      if (res.statusCode != 200) return const [];
      final body = jsonDecode(res.body);
      if (body['success'] != true) return const [];
      return ((body['data'] as List?) ?? const [])
          .whereType<Map>()
          .map((m) => PartnerCannedMessage.fromJson(m.cast<String, dynamic>()))
          .toList();
    } catch (_) {
      return const [];
    }
  }

  static Future<PartnerCannedMessage?> create({
    required int partnerUserId,
    required String label,
    required String body,
  }) async {
    if (ApiConfig.useGraphqlBackend) {
      return GraphqlTajirikaC2bService.createPartnerCannedMessage(
        label: label,
        body: body,
      );
    }
    try {
      final res = await http.post(
        Uri.parse('${ApiConfig.baseUrl}/partner-canned-messages'),
        headers: const {'Content-Type': 'application/json'},
        body: jsonEncode({
          'partner_user_id': partnerUserId,
          'label': label,
          'body': body,
        }),
      );
      final r = jsonDecode(res.body);
      if (res.statusCode >= 200 && res.statusCode < 300 && r['success'] == true) {
        return PartnerCannedMessage.fromJson((r['data'] as Map).cast<String, dynamic>());
      }
    } catch (_) {}
    return null;
  }

  static Future<bool> delete(int id) async {
    if (ApiConfig.useGraphqlBackend) {
      return GraphqlTajirikaC2bService.deletePartnerCannedMessage(id);
    }
    try {
      final res = await http.delete(
        Uri.parse('${ApiConfig.baseUrl}/partner-canned-messages/$id'),
      );
      return res.statusCode == 200;
    } catch (_) {
      return false;
    }
  }
}
