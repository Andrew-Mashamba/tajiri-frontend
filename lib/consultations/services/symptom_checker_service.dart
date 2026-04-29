import 'dart:convert';

import 'package:flutter/foundation.dart';
import 'package:http/http.dart' as http;

import '../../config/api_config.dart';

/// Spec line 716 — AI symptom checker. Free-text symptom -> specialty +
/// severity + routing recommendation. Backed by `/api/symptoms/check`.
class SymptomTriage {
  final String specialty;
  final double confidence;
  final String severity; // emergency | urgent | routine
  final String routing;  // er | in_person | video | async | self_care
  final String? followUpQuestionSw;
  final String? followUpQuestionEn;
  final bool ready;

  SymptomTriage({
    required this.specialty,
    required this.confidence,
    required this.severity,
    required this.routing,
    this.followUpQuestionSw,
    this.followUpQuestionEn,
    this.ready = false,
  });

  factory SymptomTriage.fromJson(Map<String, dynamic> json) {
    return SymptomTriage(
      specialty: json['specialty']?.toString() ?? 'general',
      confidence: () {
        final v = json['confidence'];
        if (v is num) return v.toDouble();
        if (v is String) return double.tryParse(v) ?? 0.0;
        return 0.0;
      }(),
      severity: json['severity']?.toString() ?? 'routine',
      routing: json['routing']?.toString() ?? 'async',
      followUpQuestionSw: json['follow_up_question_sw']?.toString(),
      followUpQuestionEn: json['follow_up_question_en']?.toString(),
      ready: () {
        final v = json['ready'];
        if (v is bool) return v;
        if (v is num) return v != 0;
        if (v is String) return v.toLowerCase() == 'true';
        return false;
      }(),
    );
  }
}

class SymptomCheckerService {
  static Future<SymptomTriage?> check(String symptom) async {
    if (symptom.trim().length < 4) return null;
    try {
      final res = await http
          .post(
            Uri.parse('${ApiConfig.baseUrl}/symptoms/check'),
            headers: const {'Content-Type': 'application/json'},
            body: jsonEncode({'symptom': symptom.trim()}),
          )
          .timeout(const Duration(seconds: 35));
      final r = jsonDecode(res.body);
      if (res.statusCode >= 200 && res.statusCode < 300 && r['success'] == true) {
        return SymptomTriage.fromJson((r['data'] as Map).cast<String, dynamic>());
      }
      debugPrint('[SymptomCheckerService] non-200: ${res.statusCode} ${res.body}');
    } catch (e) {
      debugPrint('[SymptomCheckerService] error: $e');
    }
    return null;
  }

  static Future<SymptomTriage?> checkConversational({
    required String symptom,
    required List<Map<String, String>> conversationHistory,
  }) async {
    if (symptom.trim().length < 2 && conversationHistory.isEmpty) return null;
    try {
      final res = await http
          .post(
            Uri.parse('${ApiConfig.baseUrl}/symptoms/check'),
            headers: const {'Content-Type': 'application/json'},
            body: jsonEncode({
              'symptom': symptom.trim(),
              'conversation_history': conversationHistory,
            }),
          )
          .timeout(const Duration(seconds: 35));
      final r = jsonDecode(res.body);
      if (res.statusCode >= 200 && res.statusCode < 300 && r['success'] == true) {
        return SymptomTriage.fromJson((r['data'] as Map).cast<String, dynamic>());
      }
      debugPrint('[SymptomCheckerService] non-200: ${res.statusCode} ${res.body}');
    } catch (e) {
      debugPrint('[SymptomCheckerService] error: $e');
    }
    return null;
  }
}
