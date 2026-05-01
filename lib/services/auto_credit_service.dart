import 'dart:convert';

import 'package:http/http.dart' as http;

import '../config/api_config.dart';

/// Spec F2 #11 — Auto-credit on detected partner error.
class AutoCreditResult {
  final bool ok;
  final String decision;
  final int? amountTzs;
  final double? aiScore;
  final String? message;

  const AutoCreditResult({
    required this.ok,
    required this.decision,
    this.amountTzs,
    this.aiScore,
    this.message,
  });

  bool get autoCredited => decision == 'auto_credited';
}

class AutoCreditService {
  static Future<AutoCreditResult?> selfReport({
    required int userId,
    required int orderId,
    required String orderKind,
    required String reason,
    required int amountTzs,
  }) async {
    final url = ApiConfig.sanitizeUrl(
        '${ApiConfig.baseUrl}/api/auto-credit/self-report')!;
    final res = await http.post(
      Uri.parse(url),
      headers: {'Content-Type': 'application/json'},
      body: jsonEncode({
        'user_id': userId,
        'order_id': orderId,
        'order_kind': orderKind,
        'reason': reason,
        'amount_tzs': amountTzs,
      }),
    );
    final body = jsonDecode(res.body);
    if (body is! Map<String, dynamic>) return null;
    return AutoCreditResult(
      ok: body['ok'] == true,
      decision: body['decision']?.toString() ?? 'review',
      amountTzs: (body['amount_tzs'] as num?)?.toInt(),
      aiScore: (body['ai_score'] as num?)?.toDouble(),
      message: body['message']?.toString(),
    );
  }
}
