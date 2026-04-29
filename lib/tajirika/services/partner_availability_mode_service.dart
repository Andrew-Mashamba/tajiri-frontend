import 'dart:convert';

import 'package:http/http.dart' as http;

import '../../config/api_config.dart';

/// Spec line 305-313 — partner-side controls for availability mode.
/// open|busy|closed plus busy ETA delta. Auto-pause flow has a Resume CTA.
class PartnerAvailabilityModeService {
  static Future<bool> setMode({
    required int partnerUserId,
    required String mode, // open | busy | closed
    DateTime? busyUntil,
    int busyEtaExtraMinutes = 0,
  }) async {
    final body = <String, dynamic>{
      'availability_mode': mode,
      'busy_eta_extra_minutes': busyEtaExtraMinutes,
    };
    if (busyUntil != null) body['busy_until'] = busyUntil.toUtc().toIso8601String();
    try {
      final res = await http.patch(
        Uri.parse('${ApiConfig.baseUrl}/partners/$partnerUserId/availability-mode'),
        headers: const {'Content-Type': 'application/json'},
        body: jsonEncode(body),
      );
      return res.statusCode >= 200 && res.statusCode < 300;
    } catch (_) {
      return false;
    }
  }

  static Future<bool> resume(int partnerUserId) async {
    try {
      final res = await http.post(
        Uri.parse('${ApiConfig.baseUrl}/partners/$partnerUserId/resume'),
      );
      return res.statusCode == 200;
    } catch (_) {
      return false;
    }
  }
}
