import 'dart:convert';

import 'package:flutter/foundation.dart';
import 'package:http/http.dart' as http;

import '../../config/api_config.dart';

class AiReviewSummary {
  final String summarySw;
  final String summaryEn;
  final int sampleSize;
  final DateTime? windowStart;
  final DateTime? windowEnd;

  AiReviewSummary({
    required this.summarySw,
    required this.summaryEn,
    required this.sampleSize,
    required this.windowStart,
    required this.windowEnd,
  });

  factory AiReviewSummary.fromJson(Map<String, dynamic> json) {
    return AiReviewSummary(
      summarySw: json['summary_sw']?.toString() ?? '',
      summaryEn: json['summary_en']?.toString() ?? '',
      sampleSize: json['sample_size'] is int
          ? json['sample_size'] as int
          : int.tryParse(json['sample_size']?.toString() ?? '') ?? 0,
      windowStart: json['window_start'] == null
          ? null
          : DateTime.tryParse(json['window_start'].toString()),
      windowEnd: json['window_end'] == null
          ? null
          : DateTime.tryParse(json['window_end'].toString()),
    );
  }
}

class AiReviewSummaryService {
  static Future<AiReviewSummary?> fetch(int partnerUserId) async {
    try {
      final res = await http
          .get(Uri.parse(
              '${ApiConfig.baseUrl}/ai/review-summary/$partnerUserId'))
          .timeout(const Duration(seconds: 35));
      if (res.statusCode != 200) return null;
      final r = jsonDecode(res.body);
      if (r['success'] != true || r['data'] == null) return null;
      return AiReviewSummary.fromJson((r['data'] as Map).cast<String, dynamic>());
    } catch (e) {
      debugPrint('[AiReviewSummaryService] $e');
      return null;
    }
  }
}
