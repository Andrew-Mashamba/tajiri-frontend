import 'dart:convert';

import 'package:flutter/foundation.dart';
import 'package:http/http.dart' as http;

import '../../config/api_config.dart';

/// Spec line 627 — appointment waitlist for full slots.
class WaitlistEntry {
  final int id;
  final int customerUserId;
  final int targetPartnerUserId;
  final String vertical;
  final String serviceTitle;
  final int servicePriceTzs;
  final int durationMin;
  final String preferredDate;
  final String preferredWindow;
  final String status;
  final DateTime? notifiedAt;
  final DateTime? expiresAt;
  WaitlistEntry({
    required this.id,
    required this.customerUserId,
    required this.targetPartnerUserId,
    required this.vertical,
    required this.serviceTitle,
    required this.servicePriceTzs,
    required this.durationMin,
    required this.preferredDate,
    required this.preferredWindow,
    required this.status,
    required this.notifiedAt,
    required this.expiresAt,
  });
  factory WaitlistEntry.fromJson(Map<String, dynamic> json) {
    DateTime? d(dynamic v) =>
        v == null ? null : DateTime.tryParse(v.toString());
    int? p(dynamic v) =>
        v == null ? null : (v is int ? v : int.tryParse(v.toString()));
    return WaitlistEntry(
      id: p(json['id']) ?? 0,
      customerUserId: p(json['customer_user_id']) ?? 0,
      targetPartnerUserId: p(json['target_partner_user_id']) ?? 0,
      vertical: json['vertical']?.toString() ?? '',
      serviceTitle: json['service_title']?.toString() ?? '',
      servicePriceTzs: p(json['service_price_tzs']) ?? 0,
      durationMin: p(json['duration_min']) ?? 60,
      preferredDate: json['preferred_date']?.toString() ?? '',
      preferredWindow: json['preferred_window']?.toString() ?? 'any',
      status: json['status']?.toString() ?? 'waiting',
      notifiedAt: d(json['notified_at']),
      expiresAt: d(json['expires_at']),
    );
  }
}

class AppointmentWaitlistService {
  static String get _baseUrl => ApiConfig.baseUrl;

  static Future<List<WaitlistEntry>> list({required int userId, required String role, int? partnerUserId}) async {
    final params = <String, String>{'user_id': '$userId', 'role': role};
    if (partnerUserId != null) params['partner_user_id'] = '$partnerUserId';
    final uri = Uri.parse('$_baseUrl/appointments/waitlist').replace(queryParameters: params);
    debugPrint('[AppointmentWaitlistService] GET $uri');
    try {
      final res = await http.get(uri);
      if (res.statusCode == 200) {
        final body = jsonDecode(res.body);
        if (body['success'] == true) {
          return (body['data'] as List)
              .whereType<Map>()
              .map((m) => WaitlistEntry.fromJson(m.cast<String, dynamic>()))
              .toList();
        }
      }
      return const [];
    } catch (_) {
      return const [];
    }
  }

  static Future<WaitlistEntry?> join({
    required int customerUserId,
    required int targetPartnerUserId,
    required String vertical,
    required String serviceTitle,
    required int servicePriceTzs,
    required int durationMin,
    required DateTime preferredDate,
    String preferredWindow = 'any',
  }) async {
    final uri = Uri.parse('$_baseUrl/appointments/waitlist');
    try {
      final res = await http.post(
        uri,
        headers: const {'Content-Type': 'application/json'},
        body: jsonEncode({
          'customer_user_id': customerUserId,
          'target_partner_user_id': targetPartnerUserId,
          'vertical': vertical,
          'service_title': serviceTitle,
          'service_price_tzs': servicePriceTzs,
          'duration_min': durationMin,
          'preferred_date': preferredDate.toIso8601String().split('T').first,
          'preferred_window': preferredWindow,
        }),
      );
      if (res.statusCode == 200) {
        final body = jsonDecode(res.body);
        if (body['success'] == true && body['data'] is Map) {
          return WaitlistEntry.fromJson((body['data'] as Map).cast<String, dynamic>());
        }
      }
      return null;
    } catch (_) {
      return null;
    }
  }

  static Future<bool> remove({required int id, required int userId}) async {
    final uri = Uri.parse('$_baseUrl/appointments/waitlist/$id');
    try {
      final res = await http.delete(
        uri,
        headers: const {'Content-Type': 'application/json'},
        body: jsonEncode({'user_id': userId}),
      );
      return res.statusCode == 200;
    } catch (_) {
      return false;
    }
  }
}
