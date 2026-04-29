import 'dart:convert';
import 'package:flutter/foundation.dart';
import 'package:http/http.dart' as http;
import '../../config/api_config.dart';

String get _baseUrl => ApiConfig.baseUrl;

void _log(String m) => debugPrint('[LoyaltyStampService] $m');

class LoyaltyStampCard {
  final int id;
  final int partnerId;
  final int customerUserId;
  final int stampsEarned;
  final int target;
  final DateTime? expiresAt;
  final DateTime? createdAt;
  final DateTime? updatedAt;

  LoyaltyStampCard({
    required this.id,
    required this.partnerId,
    required this.customerUserId,
    required this.stampsEarned,
    required this.target,
    this.expiresAt,
    this.createdAt,
    this.updatedAt,
  });

  factory LoyaltyStampCard.fromJson(Map<String, dynamic> json) {
    int? parseInt(dynamic v) {
      if (v == null) return null;
      if (v is int) return v;
      if (v is num) return v.toInt();
      return int.tryParse(v.toString());
    }

    DateTime? parseDate(dynamic v) {
      if (v == null) return null;
      if (v is DateTime) return v;
      return DateTime.tryParse(v.toString());
    }

    return LoyaltyStampCard(
      id: parseInt(json['id']) ?? 0,
      partnerId: parseInt(json['partner_id']) ?? 0,
      customerUserId: parseInt(json['customer_user_id']) ?? 0,
      stampsEarned: parseInt(json['stamps_earned']) ?? 0,
      target: parseInt(json['target']) ?? 10,
      expiresAt: parseDate(json['expires_at']),
      createdAt: parseDate(json['created_at']),
      updatedAt: parseDate(json['updated_at']),
    );
  }
}

class LoyaltyStampService {
  static Future<LoyaltyStampCard?> fetchForCustomer({
    required int partnerId,
    required int customerUserId,
  }) async {
    final uri = Uri.parse('$_baseUrl/loyalty-stamp-cards')
        .replace(queryParameters: {
      'partner_id': '$partnerId',
      'customer_user_id': '$customerUserId',
    });
    _log('GET $uri');
    try {
      final res = await http.get(uri);
      _log('status=${res.statusCode}');
      final body = jsonDecode(res.body);
      if (res.statusCode == 200 && body['success'] == true && body['data'] != null) {
        return LoyaltyStampCard.fromJson((body['data'] as Map).cast<String, dynamic>());
      }
      return null;
    } catch (e, s) {
      _log('error: $e\n$s');
      return null;
    }
  }
}
