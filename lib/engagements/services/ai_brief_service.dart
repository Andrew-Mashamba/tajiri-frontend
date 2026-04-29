import 'dart:convert';

import 'package:flutter/foundation.dart';
import 'package:http/http.dart' as http;

import '../../config/api_config.dart';

/// Spec line 825 — AI hiring-brief generator. Customer types one line, AI
/// returns a structured engagement brief that pre-fills propose_engagement_page.
class AiBrief {
  final String titleSw;
  final String titleEn;
  final String scopeSw;
  final String scopeEn;
  final List<String> deliverables;
  final List<AiBriefMilestone> milestones;
  final int timelineDays;
  final int budgetBandLowTzs;
  final int budgetBandHighTzs;
  final String contractType;

  AiBrief({
    required this.titleSw,
    required this.titleEn,
    required this.scopeSw,
    required this.scopeEn,
    required this.deliverables,
    required this.milestones,
    required this.timelineDays,
    required this.budgetBandLowTzs,
    required this.budgetBandHighTzs,
    required this.contractType,
  });

  factory AiBrief.fromJson(Map<String, dynamic> json) {
    return AiBrief(
      titleSw: json['title_sw']?.toString() ?? '',
      titleEn: json['title_en']?.toString() ?? '',
      scopeSw: json['scope_sw']?.toString() ?? '',
      scopeEn: json['scope_en']?.toString() ?? '',
      deliverables: (json['deliverables'] is List)
          ? (json['deliverables'] as List).map((e) => e.toString()).toList()
          : const [],
      milestones: (json['milestones'] is List)
          ? (json['milestones'] as List)
              .whereType<Map>()
              .map((m) => AiBriefMilestone.fromJson(m.cast<String, dynamic>()))
              .toList()
          : const [],
      timelineDays: _i(json['timeline_days']) ?? 0,
      budgetBandLowTzs: _i(json['budget_band_low_tzs']) ?? 0,
      budgetBandHighTzs: _i(json['budget_band_high_tzs']) ?? 0,
      contractType: json['contract_type']?.toString() ?? 'fixed_price',
    );
  }

  static int? _i(dynamic v) {
    if (v == null) return null;
    if (v is int) return v;
    if (v is num) return v.toInt();
    return int.tryParse(v.toString());
  }
}

class AiBriefMilestone {
  final String title;
  final int amountTzs;
  AiBriefMilestone({required this.title, required this.amountTzs});

  factory AiBriefMilestone.fromJson(Map<String, dynamic> json) {
    return AiBriefMilestone(
      title: json['title']?.toString() ?? '',
      amountTzs: AiBrief._i(json['amount_tzs']) ?? 0,
    );
  }
}

class AiBriefService {
  static Future<AiBrief?> generate({
    required String goal,
    String? skillCategory,
  }) async {
    final body = <String, dynamic>{'goal': goal};
    if (skillCategory != null && skillCategory.isNotEmpty) {
      body['skill_category'] = skillCategory;
    }
    try {
      final res = await http
          .post(
            Uri.parse('${ApiConfig.baseUrl}/ai/brief'),
            headers: const {'Content-Type': 'application/json'},
            body: jsonEncode(body),
          )
          .timeout(const Duration(seconds: 35));
      final r = jsonDecode(res.body);
      if (res.statusCode >= 200 && res.statusCode < 300 && r['success'] == true) {
        return AiBrief.fromJson((r['data'] as Map).cast<String, dynamic>());
      }
      debugPrint('[AiBriefService] non-200: ${res.statusCode} ${res.body}');
    } catch (e) {
      debugPrint('[AiBriefService] error: $e');
    }
    return null;
  }
}
