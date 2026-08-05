import 'dart:convert';

import 'package:http/http.dart' as http;

import '../../services/http_retry.dart';
import '../../config/api_config.dart';
import '../models/class_session.dart';

class ClassSessionService {
  static Future<List<FitnessClassSession>> listForPartner({
    required int partnerId,
    DateTime? from,
    DateTime? to,
  }) async {
    final params = <String, String>{'partner_id': '$partnerId'};
    if (from != null) params['from'] = from.toIso8601String();
    if (to != null) params['to'] = to.toIso8601String();
    final uri = Uri.parse('${ApiConfig.baseUrl}/class-sessions')
        .replace(queryParameters: params);
    try {
      final res = await httpGetWithRetry(uri);
      if (res.statusCode != 200) return const [];
      final body = jsonDecode(res.body);
      if (body['success'] != true) return const [];
      return ((body['data'] as List?) ?? const [])
          .whereType<Map>()
          .map((m) => FitnessClassSession.fromJson(m.cast<String, dynamic>()))
          .toList();
    } catch (_) {
      return const [];
    }
  }

  static Future<FitnessClassSession?> create({
    required int partnerId,
    int? partnerProductId,
    required String title,
    required DateTime startsAt,
    required int durationMinutes,
    required int capacity,
    int waitlistCapacity = 0,
    required int priceTzs,
    bool isDropin = true,
  }) async {
    final body = <String, dynamic>{
      'partner_id': partnerId,
      'title': title,
      'starts_at': startsAt.toUtc().toIso8601String(),
      'duration_minutes': durationMinutes,
      'capacity': capacity,
      'waitlist_capacity': waitlistCapacity,
      'price_tzs': priceTzs,
      'is_dropin': isDropin,
    };
    if (partnerProductId != null) body['partner_product_id'] = partnerProductId;
    try {
      final res = await http.post(
        Uri.parse('${ApiConfig.baseUrl}/class-sessions'),
        headers: const {'Content-Type': 'application/json'},
        body: jsonEncode(body),
      );
      final r = jsonDecode(res.body);
      if (res.statusCode >= 200 && res.statusCode < 300 && r['success'] == true) {
        return FitnessClassSession.fromJson((r['data'] as Map).cast<String, dynamic>());
      }
    } catch (_) {}
    return null;
  }

  /// Returns ('confirmed' | 'waitlist') on success, null on failure.
  static Future<String?> book({
    required int sessionId,
    required int customerUserId,
    int? spotNumber,
  }) async {
    final body = <String, dynamic>{'customer_user_id': customerUserId};
    if (spotNumber != null) body['spot_number'] = spotNumber;
    try {
      final res = await http.post(
        Uri.parse('${ApiConfig.baseUrl}/class-sessions/$sessionId/book'),
        headers: const {'Content-Type': 'application/json'},
        body: jsonEncode(body),
      );
      final r = jsonDecode(res.body);
      if (res.statusCode >= 200 && res.statusCode < 300 && r['success'] == true) {
        final data = (r['data'] as Map).cast<String, dynamic>();
        return data['status']?.toString();
      }
    } catch (_) {}
    return null;
  }

  static Future<bool> cancelBooking(int bookingId) async {
    try {
      final res = await http.post(
        Uri.parse('${ApiConfig.baseUrl}/class-session-bookings/$bookingId/cancel'),
      );
      return res.statusCode == 200;
    } catch (_) {
      return false;
    }
  }
}
