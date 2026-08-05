import 'dart:convert';

import 'package:flutter/foundation.dart';
import 'package:http/http.dart' as http;

import '../../services/http_retry.dart';
import '../../config/api_config.dart';
import '../models/event_booking.dart';

String get _baseUrl => ApiConfig.baseUrl;

void _log(String m) => debugPrint('[EventBookingService] $m');

String _snippet(String body, [int max = 300]) {
  final t = body.replaceAll(RegExp(r'\s+'), ' ').trim();
  return t.length <= max ? t : '${t.substring(0, max)}…';
}

class EventBookingService {
  static Future<EventBookingResult> create({
    required int customerUserId,
    required int partnerUserId,
    required EventKind eventKind,
    required String eventTitle,
    required DateTime eventStartsAt,
    required int basePriceTzs,
    int? partnerId,
    int? partnerProductId,
    String? skillCategory,
    DateTime? eventEndsAt,
    String? eventAddress,
    double? eventLat,
    double? eventLng,
    int partySize = 1,
    List<EventAddOn>? addOns,
    int depositPct = 50,
    List<ItineraryDay>? itinerary,
    List<Traveler>? travelers,
    /// Spec line 1042 — list of song requests for DJ/MC bookings.
    /// Each entry is `{title, artist?, note?}`.
    List<Map<String, dynamic>>? songRequests,
  }) async {
    final url = '$_baseUrl/event-bookings';
    final body = <String, dynamic>{
      'customer_user_id': customerUserId,
      'partner_user_id': partnerUserId,
      'event_kind': eventKind.apiValue,
      'event_title': eventTitle,
      'event_starts_at': eventStartsAt.toUtc().toIso8601String(),
      'base_price_tzs': basePriceTzs,
      'party_size': partySize,
      'deposit_pct': depositPct,
    };
    if (partnerId != null) body['partner_id'] = partnerId;
    if (partnerProductId != null) body['partner_product_id'] = partnerProductId;
    if (skillCategory != null && skillCategory.isNotEmpty) body['skill_category'] = skillCategory;
    if (eventEndsAt != null) body['event_ends_at'] = eventEndsAt.toUtc().toIso8601String();
    if (eventAddress != null && eventAddress.isNotEmpty) body['event_address'] = eventAddress;
    if (eventLat != null) body['event_lat'] = eventLat;
    if (eventLng != null) body['event_lng'] = eventLng;
    if (addOns != null && addOns.isNotEmpty) {
      body['add_ons'] = addOns.map((a) => a.toJson()).toList();
    }
    if (itinerary != null && itinerary.isNotEmpty) {
      body['itinerary'] = itinerary.map((d) => d.toJson()).toList();
    }
    if (travelers != null && travelers.isNotEmpty) {
      body['travelers'] = travelers.map((t) => t.toJson()).toList();
    }
    if (songRequests != null && songRequests.isNotEmpty) {
      body['song_requests'] = songRequests;
    }
    _log('POST $url kind=${eventKind.apiValue}');
    try {
      final res = await http.post(
        Uri.parse(url),
        headers: const {'Content-Type': 'application/json'},
        body: jsonEncode(body),
      );
      _log('create status=${res.statusCode} body=${_snippet(res.body)}');
      return _decodeOne(res);
    } catch (e, s) {
      _log('create error: $e\n$s');
      return EventBookingResult(success: false, message: 'Kosa: $e');
    }
  }

  static Future<EventBookingListResult> list({
    required int userId,
    required String role,
    String? status,
    String? eventKind,
    int limit = 50,
    int offset = 0,
  }) async {
    final params = <String, String>{
      'user_id': '$userId',
      'role': role,
      'limit': '$limit',
      'offset': '$offset',
    };
    if (status != null && status.isNotEmpty) params['status'] = status;
    if (eventKind != null && eventKind.isNotEmpty) params['event_kind'] = eventKind;
    final uri = Uri.parse('$_baseUrl/event-bookings').replace(queryParameters: params);
    _log('GET $uri');
    try {
      final res = await httpGetWithRetry(uri);
      final body = jsonDecode(res.body);
      if (res.statusCode == 200 && body['success'] == true) {
        final items = (body['data'] as List)
            .whereType<Map>()
            .map((m) => EventBooking.fromJson(m.cast<String, dynamic>()))
            .toList();
        return EventBookingListResult(success: true, items: items);
      }
      return EventBookingListResult(
        success: false,
        message: body['message']?.toString() ?? 'HTTP ${res.statusCode}',
        statusCode: res.statusCode,
      );
    } catch (e, s) {
      _log('list error: $e\n$s');
      return EventBookingListResult(success: false, message: 'Kosa: $e');
    }
  }

  static Future<EventBookingResult> get({required int id, required int userId}) async {
    final uri = Uri.parse('$_baseUrl/event-bookings/$id')
        .replace(queryParameters: {'user_id': '$userId'});
    _log('GET $uri');
    try {
      final res = await httpGetWithRetry(uri);
      return _decodeOne(res);
    } catch (e, s) {
      _log('get error: $e\n$s');
      return EventBookingResult(success: false, message: 'Kosa: $e');
    }
  }

  static Future<EventBookingResult> accept({required int id, required int userId}) =>
      _action(id, 'accept', {'user_id': userId});

  static Future<EventBookingResult> reject({
    required int id,
    required int userId,
    String? reason,
  }) {
    final body = <String, dynamic>{'user_id': userId};
    if (reason != null && reason.trim().isNotEmpty) body['reason'] = reason.trim();
    return _action(id, 'reject', body);
  }

  static Future<EventBookingResult> payDeposit({required int id, required int userId}) =>
      _action(id, 'pay-deposit', {'user_id': userId});

  static Future<EventBookingResult> markDayOf({required int id, required int userId}) =>
      _action(id, 'mark-day-of', {'user_id': userId});

  static Future<EventBookingResult> markCompleted({required int id, required int userId}) =>
      _action(id, 'mark-completed', {'user_id': userId});

  static Future<EventBookingResult> cancel({
    required int id,
    required int userId,
    String? reason,
  }) {
    final body = <String, dynamic>{'user_id': userId};
    if (reason != null && reason.trim().isNotEmpty) body['reason'] = reason.trim();
    return _action(id, 'cancel', body);
  }

  /// Spec line 1029 — partner declares force majeure (illness, accident, etc.).
  /// Triggers full refund regardless of standard cancellation tier.
  static Future<EventBookingResult> markForceMajeure({
    required int id,
    required int userId,
    required String reason,
  }) {
    return _action(id, 'force-majeure', {'user_id': userId, 'reason': reason});
  }

  static Future<EventBookingResult> _action(
    int id,
    String action,
    Map<String, dynamic> body,
  ) async {
    final url = '$_baseUrl/event-bookings/$id/$action';
    _log('POST $url body=${jsonEncode(body)}');
    try {
      final res = await http.post(
        Uri.parse(url),
        headers: const {'Content-Type': 'application/json'},
        body: jsonEncode(body),
      );
      _log('$action status=${res.statusCode} body=${_snippet(res.body)}');
      return _decodeOne(res);
    } catch (e, s) {
      _log('$action error: $e\n$s');
      return EventBookingResult(success: false, message: 'Kosa: $e');
    }
  }

  static EventBookingResult _decodeOne(http.Response res) {
    try {
      final body = jsonDecode(res.body);
      if (res.statusCode >= 200 && res.statusCode < 300 && body['success'] == true) {
        return EventBookingResult(
          success: true,
          booking: EventBooking.fromJson((body['data'] as Map).cast<String, dynamic>()),
          statusCode: res.statusCode,
        );
      }
      return EventBookingResult(
        success: false,
        message: body['message']?.toString() ?? 'HTTP ${res.statusCode}',
        statusCode: res.statusCode,
      );
    } catch (e) {
      return EventBookingResult(success: false, message: 'Decode error: $e', statusCode: res.statusCode);
    }
  }
}
