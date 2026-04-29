import 'dart:convert';

import 'package:http/http.dart' as http;

import '../../config/api_config.dart';
import '../models/training_plan.dart';

class TrainingPlanService {
  static Future<List<TrainingPlan>> listForCustomer(int customerUserId) async {
    final uri = Uri.parse('${ApiConfig.baseUrl}/training-plans')
        .replace(queryParameters: {'customer_user_id': '$customerUserId'});
    try {
      final res = await http.get(uri);
      if (res.statusCode != 200) return const [];
      final body = jsonDecode(res.body);
      if (body['success'] != true) return const [];
      return ((body['data'] as List?) ?? const [])
          .whereType<Map>()
          .map((m) => TrainingPlan.fromJson(m.cast<String, dynamic>()))
          .toList();
    } catch (_) {
      return const [];
    }
  }

  static Future<TrainingPlan?> create({
    required int partnerUserId,
    required int customerUserId,
    required String title,
    required DateTime startsOn,
    DateTime? endsOn,
    List<Map<String, dynamic>>? weeklyBlocks,
  }) async {
    final body = <String, dynamic>{
      'partner_user_id': partnerUserId,
      'customer_user_id': customerUserId,
      'title': title,
      'starts_on': startsOn.toIso8601String().split('T').first,
    };
    if (endsOn != null) body['ends_on'] = endsOn.toIso8601String().split('T').first;
    if (weeklyBlocks != null) body['weekly_blocks'] = weeklyBlocks;
    try {
      final res = await http.post(
        Uri.parse('${ApiConfig.baseUrl}/training-plans'),
        headers: const {'Content-Type': 'application/json'},
        body: jsonEncode(body),
      );
      final r = jsonDecode(res.body);
      if (res.statusCode >= 200 && res.statusCode < 300 && r['success'] == true) {
        return TrainingPlan.fromJson((r['data'] as Map).cast<String, dynamic>());
      }
    } catch (_) {}
    return null;
  }

  static Future<TrainingPlanCheckin?> checkin({
    required int planId,
    required DateTime date,
    List<Map<String, dynamic>>? setsRepsWeight,
    int? hrAvg,
    int? hrMax,
    bool isPr = false,
    String? prLabel,
    String? notes,
  }) async {
    final body = <String, dynamic>{
      'date': date.toIso8601String().split('T').first,
      'is_pr': isPr,
    };
    if (setsRepsWeight != null) body['sets_reps_weight'] = setsRepsWeight;
    if (hrAvg != null) body['hr_avg'] = hrAvg;
    if (hrMax != null) body['hr_max'] = hrMax;
    if (prLabel != null && prLabel.isNotEmpty) body['pr_label'] = prLabel;
    if (notes != null && notes.isNotEmpty) body['notes'] = notes;
    try {
      final res = await http.post(
        Uri.parse('${ApiConfig.baseUrl}/training-plans/$planId/checkin'),
        headers: const {'Content-Type': 'application/json'},
        body: jsonEncode(body),
      );
      final r = jsonDecode(res.body);
      if (res.statusCode >= 200 && res.statusCode < 300 && r['success'] == true) {
        return TrainingPlanCheckin.fromJson((r['data'] as Map).cast<String, dynamic>());
      }
    } catch (_) {}
    return null;
  }

  static Future<List<TrainingPlanCheckin>> listCheckins(int planId) async {
    try {
      final res = await http.get(Uri.parse('${ApiConfig.baseUrl}/training-plans/$planId/checkins'));
      if (res.statusCode != 200) return const [];
      final body = jsonDecode(res.body);
      if (body['success'] != true) return const [];
      return ((body['data'] as List?) ?? const [])
          .whereType<Map>()
          .map((m) => TrainingPlanCheckin.fromJson(m.cast<String, dynamic>()))
          .toList();
    } catch (_) {
      return const [];
    }
  }
}
