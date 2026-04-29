import 'dart:convert';

import 'package:flutter/foundation.dart';
import 'package:http/http.dart' as http;

import '../../config/api_config.dart';
import '../models/partner_availability.dart';

String get _baseUrl => ApiConfig.baseUrl;

void _log(String m) => debugPrint('[PartnerAvailabilityService] $m');

String _snippet(String body, [int max = 300]) {
  final t = body.replaceAll(RegExp(r'\s+'), ' ').trim();
  return t.length <= max ? t : '${t.substring(0, max)}…';
}

class PartnerAvailabilityService {
  // ──────────────── Weekly hours ────────────────

  static Future<PartnerAvailabilityResult> upsertHours({
    required int partnerUserId,
    required int weekday,
    required String openTime,
    required String closeTime,
    required int slotMinutes,
    String? skillCategory,
    bool isActive = true,
    int? reminderCadenceHours,
    int? pricingModifierPct,
    int? minNoticeMinutes,
    int? bookingHorizonDays,
    bool? lastMinuteDiscountEnabled,
    int? lastMinuteDiscountPct,
    String? waitlistMode,
    int? preBufferMinutes,
    int? processingMinutes,
    int? postBufferMinutes,
    int? travelSurchargeTzs,
    int? afterHoursSurchargeTzs,
    int? holidayPremiumTzs,
    int? parkingPassThroughTzs,
  }) async {
    final url = '$_baseUrl/partner-availability';
    final body = <String, dynamic>{
      'partner_user_id': partnerUserId,
      'weekday': weekday,
      'open_time': openTime,
      'close_time': closeTime,
      'slot_minutes': slotMinutes,
      'is_active': isActive,
    };
    if (skillCategory != null && skillCategory.isNotEmpty) {
      body['skill_category'] = skillCategory;
    }
    if (reminderCadenceHours != null) {
      body['reminder_cadence_hours'] = reminderCadenceHours;
    }
    if (pricingModifierPct != null) {
      body['pricing_modifier_pct'] = pricingModifierPct;
    }
    if (minNoticeMinutes != null) body['min_notice_minutes'] = minNoticeMinutes;
    if (bookingHorizonDays != null) {
      body['booking_horizon_days'] = bookingHorizonDays;
    }
    if (lastMinuteDiscountEnabled != null) {
      body['last_minute_discount_enabled'] = lastMinuteDiscountEnabled;
    }
    if (lastMinuteDiscountPct != null) {
      body['last_minute_discount_pct'] = lastMinuteDiscountPct;
    }
    if (waitlistMode != null && waitlistMode.isNotEmpty) {
      body['waitlist_mode'] = waitlistMode;
    }
    if (preBufferMinutes != null) body['pre_buffer_minutes'] = preBufferMinutes;
    if (processingMinutes != null) body['processing_minutes'] = processingMinutes;
    if (postBufferMinutes != null) body['post_buffer_minutes'] = postBufferMinutes;
    if (travelSurchargeTzs != null) body['travel_surcharge_tzs'] = travelSurchargeTzs;
    if (afterHoursSurchargeTzs != null) body['after_hours_surcharge_tzs'] = afterHoursSurchargeTzs;
    if (holidayPremiumTzs != null) body['holiday_premium_tzs'] = holidayPremiumTzs;
    if (parkingPassThroughTzs != null) body['parking_pass_through_tzs'] = parkingPassThroughTzs;
    _log('POST $url body=${jsonEncode(body)}');
    try {
      final res = await http.post(
        Uri.parse(url),
        headers: const {'Content-Type': 'application/json'},
        body: jsonEncode(body),
      );
      _log('upsertHours status=${res.statusCode} body=${_snippet(res.body)}');
      return _decodeHours(res);
    } catch (e, s) {
      _log('upsertHours error: $e\n$s');
      return PartnerAvailabilityResult(success: false, message: 'Kosa: $e');
    }
  }

  static Future<PartnerAvailabilityListResult> listHours({
    required int partnerUserId,
    String? skillCategory,
  }) async {
    final params = <String, String>{'partner_user_id': '$partnerUserId'};
    if (skillCategory != null && skillCategory.isNotEmpty) {
      params['skill_category'] = skillCategory;
    }
    final uri = Uri.parse('$_baseUrl/partner-availability').replace(queryParameters: params);
    _log('GET $uri');
    try {
      final res = await http.get(uri);
      _log('listHours status=${res.statusCode} body=${_snippet(res.body)}');
      final body = jsonDecode(res.body);
      if (res.statusCode == 200 && body['success'] == true) {
        return PartnerAvailabilityListResult(
          success: true,
          items: (body['data'] as List)
              .whereType<Map>()
              .map((m) => PartnerAvailability.fromJson(m.cast<String, dynamic>()))
              .toList(),
        );
      }
      return PartnerAvailabilityListResult(
        success: false,
        message: body['message']?.toString() ?? 'HTTP ${res.statusCode}',
        statusCode: res.statusCode,
      );
    } catch (e, s) {
      _log('listHours error: $e\n$s');
      return PartnerAvailabilityListResult(success: false, message: 'Kosa: $e');
    }
  }

  static Future<bool> deactivateHours({
    required int id,
    required int partnerUserId,
  }) async {
    final url = '$_baseUrl/partner-availability/$id';
    _log('DELETE $url');
    try {
      final res = await http.delete(
        Uri.parse(url),
        headers: const {'Content-Type': 'application/json'},
        body: jsonEncode({'partner_user_id': partnerUserId}),
      );
      final body = jsonDecode(res.body);
      return res.statusCode == 200 && body['success'] == true;
    } catch (e, s) {
      _log('deactivateHours error: $e\n$s');
      return false;
    }
  }

  // ──────────────── Blackouts ────────────────

  static Future<PartnerBlackoutResult> addBlackout({
    required int partnerUserId,
    required DateTime startsAt,
    required DateTime endsAt,
    String? reason,
    bool allDay = false,
    List<String>? skillCategories,
  }) async {
    final url = '$_baseUrl/partner-availability/blackouts';
    final body = <String, dynamic>{
      'partner_user_id': partnerUserId,
      'starts_at': startsAt.toUtc().toIso8601String(),
      'ends_at': endsAt.toUtc().toIso8601String(),
      'all_day': allDay,
    };
    if (reason != null && reason.isNotEmpty) body['reason'] = reason;
    if (skillCategories != null && skillCategories.isNotEmpty) {
      body['skill_categories'] = skillCategories;
    }
    _log('POST $url body=${jsonEncode(body)}');
    try {
      final res = await http.post(
        Uri.parse(url),
        headers: const {'Content-Type': 'application/json'},
        body: jsonEncode(body),
      );
      return _decodeBlackout(res);
    } catch (e, s) {
      _log('addBlackout error: $e\n$s');
      return PartnerBlackoutResult(success: false, message: 'Kosa: $e');
    }
  }

  static Future<PartnerBlackoutListResult> listBlackouts({
    required int partnerUserId,
  }) async {
    final uri = Uri.parse('$_baseUrl/partner-availability/blackouts')
        .replace(queryParameters: {'partner_user_id': '$partnerUserId'});
    _log('GET $uri');
    try {
      final res = await http.get(uri);
      _log('listBlackouts status=${res.statusCode} body=${_snippet(res.body)}');
      final body = jsonDecode(res.body);
      if (res.statusCode == 200 && body['success'] == true) {
        return PartnerBlackoutListResult(
          success: true,
          items: (body['data'] as List)
              .whereType<Map>()
              .map((m) => PartnerBlackout.fromJson(m.cast<String, dynamic>()))
              .toList(),
        );
      }
      return PartnerBlackoutListResult(
        success: false,
        message: body['message']?.toString() ?? 'HTTP ${res.statusCode}',
        statusCode: res.statusCode,
      );
    } catch (e, s) {
      _log('listBlackouts error: $e\n$s');
      return PartnerBlackoutListResult(success: false, message: 'Kosa: $e');
    }
  }

  static Future<bool> deleteBlackout({
    required int id,
    required int partnerUserId,
  }) async {
    final url = '$_baseUrl/partner-availability/blackouts/$id';
    _log('DELETE $url');
    try {
      final res = await http.delete(
        Uri.parse(url),
        headers: const {'Content-Type': 'application/json'},
        body: jsonEncode({'partner_user_id': partnerUserId}),
      );
      final body = jsonDecode(res.body);
      return res.statusCode == 200 && body['success'] == true;
    } catch (e, s) {
      _log('deleteBlackout error: $e\n$s');
      return false;
    }
  }

  // ──────────────── Slots expansion ────────────────

  static Future<AvailableSlotListResult> fetchSlots({
    required int partnerUserId,
    String? skillCategory,
    DateTime? from,
    DateTime? to,
  }) async {
    final params = <String, String>{
      'partner_user_id': '$partnerUserId',
    };
    if (skillCategory != null && skillCategory.isNotEmpty) {
      params['skill_category'] = skillCategory;
    }
    if (from != null) {
      params['from'] = from.toIso8601String().split('T').first;
    }
    if (to != null) {
      params['to'] = to.toIso8601String().split('T').first;
    }
    final uri = Uri.parse('$_baseUrl/partner-availability/slots').replace(queryParameters: params);
    _log('GET $uri');
    try {
      final res = await http.get(uri);
      _log('fetchSlots status=${res.statusCode} body=${_snippet(res.body)}');
      final body = jsonDecode(res.body);
      if (res.statusCode == 200 && body['success'] == true) {
        return AvailableSlotListResult(
          success: true,
          items: (body['data'] as List)
              .whereType<Map>()
              .map((m) => AvailableSlot.fromJson(m.cast<String, dynamic>()))
              .toList(),
        );
      }
      return AvailableSlotListResult(
        success: false,
        message: body['message']?.toString() ?? 'HTTP ${res.statusCode}',
        statusCode: res.statusCode,
      );
    } catch (e, s) {
      _log('fetchSlots error: $e\n$s');
      return AvailableSlotListResult(success: false, message: 'Kosa: $e');
    }
  }

  static PartnerAvailabilityResult _decodeHours(http.Response res) {
    try {
      final body = jsonDecode(res.body);
      if (res.statusCode >= 200 && res.statusCode < 300 && body['success'] == true) {
        return PartnerAvailabilityResult(
          success: true,
          hours: PartnerAvailability.fromJson((body['data'] as Map).cast<String, dynamic>()),
          statusCode: res.statusCode,
        );
      }
      return PartnerAvailabilityResult(
        success: false,
        message: body['message']?.toString() ?? 'HTTP ${res.statusCode}',
        statusCode: res.statusCode,
      );
    } catch (e) {
      return PartnerAvailabilityResult(
        success: false,
        message: 'Decode error: $e',
        statusCode: res.statusCode,
      );
    }
  }

  static PartnerBlackoutResult _decodeBlackout(http.Response res) {
    try {
      final body = jsonDecode(res.body);
      if (res.statusCode >= 200 && res.statusCode < 300 && body['success'] == true) {
        return PartnerBlackoutResult(
          success: true,
          blackout: PartnerBlackout.fromJson((body['data'] as Map).cast<String, dynamic>()),
          statusCode: res.statusCode,
        );
      }
      return PartnerBlackoutResult(
        success: false,
        message: body['message']?.toString() ?? 'HTTP ${res.statusCode}',
        statusCode: res.statusCode,
      );
    } catch (e) {
      return PartnerBlackoutResult(
        success: false,
        message: 'Decode error: $e',
        statusCode: res.statusCode,
      );
    }
  }
}
