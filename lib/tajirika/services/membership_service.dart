import 'dart:convert';

import 'package:http/http.dart' as http;

import '../../config/api_config.dart';

/// Spec F6 #43 — Memberships (ClassPass-style credits).
class Membership {
  final int id;
  final int partnerId;
  final String? partnerName;
  final String plan;
  final int? creditsTotal;
  final int? creditsRemaining;
  final int priceTzs;
  final DateTime? expiresAt;
  final String status;

  const Membership({
    required this.id,
    required this.partnerId,
    this.partnerName,
    required this.plan,
    this.creditsTotal,
    this.creditsRemaining,
    required this.priceTzs,
    this.expiresAt,
    required this.status,
  });

  factory Membership.fromJson(Map<String, dynamic> json) {
    int? parseInt(dynamic v) {
      if (v == null) return null;
      if (v is int) return v;
      if (v is num) return v.toInt();
      return int.tryParse(v.toString());
    }
    DateTime? parseDt(dynamic v) {
      if (v == null) return null;
      try {
        return DateTime.parse(v.toString()).toLocal();
      } catch (_) {
        return null;
      }
    }
    return Membership(
      id: parseInt(json['id']) ?? 0,
      partnerId: parseInt(json['partner_id']) ?? 0,
      partnerName: json['partner_name'] as String?,
      plan: json['plan']?.toString() ?? '',
      creditsTotal: parseInt(json['credits_total']),
      creditsRemaining: parseInt(json['credits_remaining']),
      priceTzs: parseInt(json['price_tzs']) ?? 0,
      expiresAt: parseDt(json['expires_at']),
      status: json['status']?.toString() ?? 'active',
    );
  }
}

class MembershipService {
  static Future<List<Membership>> myMemberships({required int userId}) async {
    final url = ApiConfig.sanitizeUrl(
        '${ApiConfig.baseUrl}/api/memberships/mine?user_id=$userId')!;
    final res = await http.get(Uri.parse(url));
    if (res.statusCode != 200) return const [];
    final body = jsonDecode(res.body);
    if (body is Map<String, dynamic> && body['memberships'] is List) {
      return (body['memberships'] as List)
          .whereType<Map>()
          .map((m) => Membership.fromJson(m.cast<String, dynamic>()))
          .toList();
    }
    return const [];
  }

  static Future<List<Map<String, dynamic>>> partnerPlans({
    required int partnerId,
  }) async {
    final url = ApiConfig.sanitizeUrl(
        '${ApiConfig.baseUrl}/api/memberships/partner/$partnerId/plans')!;
    final res = await http.get(Uri.parse(url));
    if (res.statusCode != 200) return const [];
    final body = jsonDecode(res.body);
    if (body is Map<String, dynamic> && body['plans'] is List) {
      return (body['plans'] as List)
          .whereType<Map>()
          .map((m) => m.cast<String, dynamic>())
          .toList();
    }
    return const [];
  }

  static Future<int?> purchase({
    required int userId,
    required int partnerId,
    required String plan,
    required int priceTzs,
    int? creditsTotal,
    int? durationDays,
  }) async {
    final url = ApiConfig.sanitizeUrl(
        '${ApiConfig.baseUrl}/api/memberships/purchase')!;
    final res = await http.post(
      Uri.parse(url),
      headers: {'Content-Type': 'application/json'},
      body: jsonEncode({
        'user_id': userId,
        'partner_id': partnerId,
        'plan': plan,
        'price_tzs': priceTzs,
        if (creditsTotal != null) 'credits_total': creditsTotal,
        if (durationDays != null) 'duration_days': durationDays,
      }),
    );
    if (res.statusCode != 200) return null;
    final body = jsonDecode(res.body);
    if (body is Map<String, dynamic> && body['ok'] == true) {
      final id = body['membership_id'];
      if (id is num) return id.toInt();
    }
    return null;
  }

  static Future<bool> deductCredit({
    required int userId,
    required int membershipId,
    int credits = 1,
  }) async {
    final url = ApiConfig.sanitizeUrl(
        '${ApiConfig.baseUrl}/api/memberships/deduct')!;
    final res = await http.post(
      Uri.parse(url),
      headers: {'Content-Type': 'application/json'},
      body: jsonEncode({
        'user_id': userId,
        'membership_id': membershipId,
        'credits': credits,
      }),
    );
    return res.statusCode == 200;
  }
}
