import 'dart:convert';

import 'package:http/http.dart' as http;

import '../../config/api_config.dart';

/// Spec F7 #61 — Pay-per-question legal Q&A.
class LegalQnaThread {
  final int id;
  final int customerUserId;
  final int? partnerUserId;
  final String? topic;
  final String question;
  final String? answer;
  final int priceTzs;
  final String status;
  final DateTime? answeredAt;
  final DateTime? createdAt;
  /// F7 #19 — follow-up window in days (e.g., 7 days to ask a related question).
  final int? followUpWindowDays;
  final DateTime? followUpExpiresAt;

  const LegalQnaThread({
    required this.id,
    required this.customerUserId,
    this.partnerUserId,
    this.topic,
    required this.question,
    this.answer,
    required this.priceTzs,
    required this.status,
    this.answeredAt,
    this.createdAt,
    this.followUpWindowDays,
    this.followUpExpiresAt,
  });

  factory LegalQnaThread.fromJson(Map<String, dynamic> json) {
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
    return LegalQnaThread(
      id: parseInt(json['id']) ?? 0,
      customerUserId: parseInt(json['customer_user_id']) ?? 0,
      partnerUserId: parseInt(json['partner_user_id']),
      topic: json['topic'] as String?,
      question: json['question']?.toString() ?? '',
      answer: json['answer'] as String?,
      priceTzs: parseInt(json['price_tzs']) ?? 0,
      status: json['status']?.toString() ?? 'paid',
      answeredAt: parseDt(json['answered_at']),
      createdAt: parseDt(json['created_at']),
      followUpWindowDays: parseInt(json['follow_up_window_days']),
      followUpExpiresAt: parseDt(json['follow_up_expires_at']),
    );
  }
}

class LegalQnaService {
  static Future<int?> ask({
    required int userId,
    int? partnerUserId,
    String? topic,
    required String question,
    required int priceTzs,
  }) async {
    final url = ApiConfig.sanitizeUrl('${ApiConfig.baseUrl}/api/legal-qna/ask')!;
    final res = await http.post(
      Uri.parse(url),
      headers: {'Content-Type': 'application/json'},
      body: jsonEncode({
        'user_id': userId,
        if (partnerUserId != null) 'partner_user_id': partnerUserId,
        if (topic != null) 'topic': topic,
        'question': question,
        'price_tzs': priceTzs,
      }),
    );
    if (res.statusCode != 200) return null;
    final body = jsonDecode(res.body);
    if (body is Map<String, dynamic> && body['ok'] == true) {
      final id = body['thread_id'];
      if (id is num) return id.toInt();
    }
    return null;
  }

  static Future<bool> answer({
    required int userId,
    required int threadId,
    required String answer,
  }) async {
    final url = ApiConfig.sanitizeUrl(
        '${ApiConfig.baseUrl}/api/legal-qna/$threadId/answer')!;
    final res = await http.post(
      Uri.parse(url),
      headers: {'Content-Type': 'application/json'},
      body: jsonEncode({'user_id': userId, 'answer': answer}),
    );
    return res.statusCode == 200;
  }

  static Future<List<LegalQnaThread>> myThreads({required int userId}) async {
    final url = ApiConfig.sanitizeUrl(
        '${ApiConfig.baseUrl}/api/legal-qna/mine?user_id=$userId')!;
    final res = await http.get(Uri.parse(url));
    if (res.statusCode != 200) return const [];
    final body = jsonDecode(res.body);
    if (body is Map<String, dynamic> && body['threads'] is List) {
      return (body['threads'] as List)
          .whereType<Map>()
          .map((m) => LegalQnaThread.fromJson(m.cast<String, dynamic>()))
          .toList();
    }
    return const [];
  }

  static Future<List<LegalQnaThread>> partnerInbox({required int userId}) async {
    final url = ApiConfig.sanitizeUrl(
        '${ApiConfig.baseUrl}/api/legal-qna/inbox?user_id=$userId')!;
    final res = await http.get(Uri.parse(url));
    if (res.statusCode != 200) return const [];
    final body = jsonDecode(res.body);
    if (body is Map<String, dynamic> && body['threads'] is List) {
      return (body['threads'] as List)
          .whereType<Map>()
          .map((m) => LegalQnaThread.fromJson(m.cast<String, dynamic>()))
          .toList();
    }
    return const [];
  }
}
