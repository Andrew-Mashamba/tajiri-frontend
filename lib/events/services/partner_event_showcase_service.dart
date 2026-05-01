import 'dart:convert';

import 'package:flutter/foundation.dart';
import 'package:http/http.dart' as http;

import '../../config/api_config.dart';
import '../models/partner_event_showcase.dart';

/// Spec F10 #88 — Real Events partner gallery service.
class PartnerEventShowcaseService {
  static String get _baseUrl => ApiConfig.baseUrl;

  static Future<List<PartnerEventShowcase>> list({int? partnerUserId}) async {
    final params = <String, String>{};
    if (partnerUserId != null) params['partner_user_id'] = '$partnerUserId';
    final uri = Uri.parse('$_baseUrl/partner-event-showcase')
        .replace(queryParameters: params.isEmpty ? null : params);
    try {
      final res = await http.get(uri);
      if (res.statusCode != 200) return const [];
      final body = jsonDecode(res.body);
      if (body['success'] != true) return const [];
      return (body['data'] as List)
          .whereType<Map>()
          .map((m) => PartnerEventShowcase.fromJson(m.cast<String, dynamic>()))
          .toList();
    } catch (e) {
      debugPrint('[PartnerEventShowcaseService] list error: $e');
      return const [];
    }
  }

  static Future<PartnerEventShowcase?> create({
    required int partnerId,
    required int partnerUserId,
    int? eventBookingId,
    required List<String> photoUrls,
    String? caption,
  }) async {
    try {
      final body = <String, dynamic>{
        'partner_id': partnerId,
        'partner_user_id': partnerUserId,
        'photo_urls': photoUrls,
        if (eventBookingId != null) 'event_booking_id': eventBookingId,
        if (caption != null && caption.isNotEmpty) 'caption': caption,
      };
      final res = await http.post(
        Uri.parse('$_baseUrl/partner-event-showcase'),
        headers: const {'Content-Type': 'application/json'},
        body: jsonEncode(body),
      );
      if (res.statusCode != 201 && res.statusCode != 200) return null;
      final r = jsonDecode(res.body);
      if (r['success'] != true) return null;
      return PartnerEventShowcase.fromJson(
          (r['data'] as Map).cast<String, dynamic>());
    } catch (e) {
      debugPrint('[PartnerEventShowcaseService] create error: $e');
      return null;
    }
  }

  static Future<bool> destroy(int id, int userId) async {
    try {
      final res = await http.delete(
        Uri.parse('$_baseUrl/partner-event-showcase/$id'),
        headers: const {'Content-Type': 'application/json'},
        body: jsonEncode({'user_id': userId}),
      );
      return res.statusCode == 200;
    } catch (_) {
      return false;
    }
  }
}
