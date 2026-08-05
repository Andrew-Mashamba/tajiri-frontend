import 'dart:convert';

import 'package:flutter/foundation.dart';
import '../../services/http_retry.dart';
import '../../config/api_config.dart';

class ConsentReceipt {
  final int id;
  final int userId;
  final String action;
  final String? recipient;
  final Map<String, dynamic>? payload;
  final DateTime? acknowledgedAt;

  ConsentReceipt({
    required this.id,
    required this.userId,
    required this.action,
    required this.recipient,
    required this.payload,
    required this.acknowledgedAt,
  });

  factory ConsentReceipt.fromJson(Map<String, dynamic> json) {
    Map<String, dynamic>? p;
    final raw = json['payload_summary'];
    if (raw is Map) {
      p = raw.cast<String, dynamic>();
    } else if (raw is String && raw.isNotEmpty) {
      try {
        final dec = jsonDecode(raw);
        if (dec is Map) p = dec.cast<String, dynamic>();
      } catch (_) {}
    }
    return ConsentReceipt(
      id: json['id'] is int ? json['id'] as int : int.tryParse(json['id']?.toString() ?? '') ?? 0,
      userId: json['user_id'] is int ? json['user_id'] as int : int.tryParse(json['user_id']?.toString() ?? '') ?? 0,
      action: json['action']?.toString() ?? '',
      recipient: json['recipient']?.toString(),
      payload: p,
      acknowledgedAt: json['acknowledged_at'] == null
          ? null
          : DateTime.tryParse(json['acknowledged_at'].toString()),
    );
  }
}

class ConsentReceiptService {
  static Future<List<ConsentReceipt>> list(int userId) async {
    try {
      final res = await httpGetWithRetry(
        Uri.parse('${ApiConfig.baseUrl}/consent-receipts')
            .replace(queryParameters: {'user_id': '$userId'}),
      );
      if (res.statusCode != 200) return const [];
      final body = jsonDecode(res.body);
      if (body['success'] != true) return const [];
      return ((body['data'] as List?) ?? const [])
          .whereType<Map>()
          .map((m) => ConsentReceipt.fromJson(m.cast<String, dynamic>()))
          .toList();
    } catch (e) {
      debugPrint('[ConsentReceiptService] $e');
      return const [];
    }
  }
}
