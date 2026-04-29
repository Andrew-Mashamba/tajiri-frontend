import 'dart:convert';

import 'package:flutter/foundation.dart';
import 'package:http/http.dart' as http;

import '../../config/api_config.dart';
import '../models/partner_skill_persona.dart';

String get _baseUrl => ApiConfig.baseUrl;

void _log(String m) => debugPrint('[PartnerSkillPersonaService] $m');

String _snippet(String body, [int max = 300]) {
  final t = body.replaceAll(RegExp(r'\s+'), ' ').trim();
  return t.length <= max ? t : '${t.substring(0, max)}…';
}

class PartnerSkillPersonaService {
  static Future<PartnerSkillPersonaListResult> list({
    required int partnerUserId,
  }) async {
    final uri = Uri.parse('$_baseUrl/partner-skill-personas')
        .replace(queryParameters: {'partner_user_id': '$partnerUserId'});
    _log('GET $uri');
    try {
      final res = await http.get(uri);
      _log('list status=${res.statusCode} body=${_snippet(res.body)}');
      final body = jsonDecode(res.body);
      if (res.statusCode == 200 && body['success'] == true) {
        return PartnerSkillPersonaListResult(
          success: true,
          items: (body['data'] as List)
              .whereType<Map>()
              .map((m) => PartnerSkillPersona.fromJson(m.cast<String, dynamic>()))
              .toList(),
        );
      }
      return PartnerSkillPersonaListResult(
        success: false,
        message: body['message']?.toString() ?? 'HTTP ${res.statusCode}',
        statusCode: res.statusCode,
      );
    } catch (e, s) {
      _log('list error: $e\n$s');
      return PartnerSkillPersonaListResult(success: false, message: 'Kosa: $e');
    }
  }

  static Future<PartnerSkillPersonaResult> get({
    required int partnerUserId,
    required String skillCategory,
  }) async {
    final url = '$_baseUrl/partner-skill-personas/$partnerUserId/$skillCategory';
    _log('GET $url');
    try {
      final res = await http.get(Uri.parse(url));
      return _decodeOne(res);
    } catch (e, s) {
      _log('get error: $e\n$s');
      return PartnerSkillPersonaResult(success: false, message: 'Kosa: $e');
    }
  }

  static Future<PartnerSkillPersonaResult> upsert({
    required int partnerUserId,
    required String skillCategory,
    required int actingUserId,
    String? displayName,
    String? profilePhotoUrl,
    String? bio,
    int? pricingBandLowTzs,
    int? pricingBandHighTzs,
    List<String>? tagPreset,
    String? autoReplyText,
  }) async {
    final url = '$_baseUrl/partner-skill-personas/$partnerUserId/$skillCategory';
    final body = <String, dynamic>{'acting_user_id': actingUserId};
    if (displayName != null) body['display_name'] = displayName;
    if (profilePhotoUrl != null) body['profile_photo_url'] = profilePhotoUrl;
    if (bio != null) body['bio'] = bio;
    if (pricingBandLowTzs != null) body['pricing_band_low_tzs'] = pricingBandLowTzs;
    if (pricingBandHighTzs != null) body['pricing_band_high_tzs'] = pricingBandHighTzs;
    if (tagPreset != null) body['tag_preset'] = tagPreset;
    if (autoReplyText != null) body['auto_reply_text'] = autoReplyText;
    _log('PATCH $url body=${jsonEncode(body)}');
    try {
      final res = await http.patch(
        Uri.parse(url),
        headers: const {'Content-Type': 'application/json'},
        body: jsonEncode(body),
      );
      return _decodeOne(res);
    } catch (e, s) {
      _log('upsert error: $e\n$s');
      return PartnerSkillPersonaResult(success: false, message: 'Kosa: $e');
    }
  }

  static Future<PartnerSkillPersonaResult> pause({
    required int partnerUserId,
    required String skillCategory,
    required int actingUserId,
  }) =>
      _action(partnerUserId, skillCategory, 'pause', actingUserId);

  static Future<PartnerSkillPersonaResult> resume({
    required int partnerUserId,
    required String skillCategory,
    required int actingUserId,
  }) =>
      _action(partnerUserId, skillCategory, 'resume', actingUserId);

  static Future<({bool success, String? message})> remove({
    required int partnerUserId,
    required String skillCategory,
    required int actingUserId,
  }) async {
    final url = '$_baseUrl/partner-skill-personas/$partnerUserId/$skillCategory';
    _log('DELETE $url');
    try {
      final res = await http.delete(
        Uri.parse(url),
        headers: const {'Content-Type': 'application/json'},
        body: jsonEncode({'acting_user_id': actingUserId}),
      );
      final body = jsonDecode(res.body);
      if (res.statusCode == 200 && body['success'] == true) {
        return (success: true, message: null);
      }
      return (success: false, message: body['message']?.toString() ?? 'HTTP ${res.statusCode}');
    } catch (e, s) {
      _log('remove error: $e\n$s');
      return (success: false, message: 'Kosa: $e');
    }
  }

  static Future<PartnerSkillPersonaResult> _action(
    int partnerUserId,
    String skillCategory,
    String action,
    int actingUserId,
  ) async {
    final url = '$_baseUrl/partner-skill-personas/$partnerUserId/$skillCategory/$action';
    _log('POST $url');
    try {
      final res = await http.post(
        Uri.parse(url),
        headers: const {'Content-Type': 'application/json'},
        body: jsonEncode({'acting_user_id': actingUserId}),
      );
      return _decodeOne(res);
    } catch (e, s) {
      _log('$action error: $e\n$s');
      return PartnerSkillPersonaResult(success: false, message: 'Kosa: $e');
    }
  }

  static PartnerSkillPersonaResult _decodeOne(http.Response res) {
    try {
      final body = jsonDecode(res.body);
      if (res.statusCode >= 200 && res.statusCode < 300 && body['success'] == true) {
        return PartnerSkillPersonaResult(
          success: true,
          persona: PartnerSkillPersona.fromJson((body['data'] as Map).cast<String, dynamic>()),
          statusCode: res.statusCode,
        );
      }
      return PartnerSkillPersonaResult(
        success: false,
        message: body['message']?.toString() ?? 'HTTP ${res.statusCode}',
        statusCode: res.statusCode,
      );
    } catch (e) {
      return PartnerSkillPersonaResult(
        success: false,
        message: 'Decode error: $e',
        statusCode: res.statusCode,
      );
    }
  }
}
