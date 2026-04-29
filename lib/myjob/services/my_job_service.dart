// lib/myjob/services/my_job_service.dart

import 'dart:convert';
import 'package:flutter/foundation.dart';
import 'package:http/http.dart' as http;
import '../../config/api_config.dart';
import '../../team/models/work_models.dart';
import '../../team/models/task_models.dart';
import '../../team/services/work_service.dart' show WorkResult, WorkListResult;
import '../models/myjob_models.dart' show MyPayslip;

void _log(String m) => debugPrint('[MyJobService] $m');

class MyTasksResult {
  final bool success;
  final List<WorkTask> standingTasks;
  final List<WorkTask> adhocTasks;
  final String? message;

  const MyTasksResult({
    required this.success,
    this.standingTasks = const [],
    this.adhocTasks = const [],
    this.message,
  });
}

class MyJobService {
  static Map<String, String> _h(String token) => ApiConfig.authHeaders(token);

  static Future<WorkResult<JobDescription>> getMyJobDescription(String token) async {
    _log('GET /my/job-description');
    try {
      final res = await http.get(
          Uri.parse('${ApiConfig.baseUrl}/my/job-description'),
          headers: _h(token));
      final body = jsonDecode(res.body) as Map<String, dynamic>;
      final d = body['data'];
      if (res.statusCode == 200 && d != null) {
        return WorkResult(success: true, data: JobDescription.fromJson(d as Map<String, dynamic>));
      }
      return WorkResult(success: false, message: body['message']?.toString());
    } catch (e) {
      return WorkResult(success: false, message: e.toString());
    }
  }

  static Future<WorkListResult<Kpi>> getMyKpis(String token) async {
    _log('GET /my/kpis');
    try {
      final res = await http.get(
          Uri.parse('${ApiConfig.baseUrl}/my/kpis'),
          headers: _h(token));
      final body = jsonDecode(res.body) as Map<String, dynamic>;
      if (res.statusCode == 200) {
        final list = (body['data'] as List? ?? [])
            .map((e) => Kpi.fromJson(e as Map<String, dynamic>)).toList();
        return WorkListResult(success: true, data: list);
      }
      return WorkListResult(success: false, message: body['message']?.toString());
    } catch (e) {
      return WorkListResult(success: false, message: e.toString());
    }
  }

  static Future<WorkListResult<KpiEntry>> getMyKpiEntries(
      String token, int kpiId) async {
    _log('GET /my/kpis/$kpiId/entries');
    try {
      final res = await http.get(
          Uri.parse('${ApiConfig.baseUrl}/my/kpis/$kpiId/entries'),
          headers: _h(token));
      final body = jsonDecode(res.body) as Map<String, dynamic>;
      if (res.statusCode == 200) {
        final list = (body['data'] as List? ?? [])
            .map((e) => KpiEntry.fromJson(e as Map<String, dynamic>)).toList();
        return WorkListResult(success: true, data: list);
      }
      return WorkListResult(success: false, message: body['message']?.toString());
    } catch (e) {
      return WorkListResult(success: false, message: e.toString());
    }
  }

  static Future<MyTasksResult> getMyTasks(String token, {DateTime? date}) async {
    final d = date ?? DateTime.now();
    final dateStr =
        '${d.year}-${d.month.toString().padLeft(2, '0')}-${d.day.toString().padLeft(2, '0')}';
    _log('GET /my/tasks?date=$dateStr');
    try {
      final uri = Uri.parse('${ApiConfig.baseUrl}/my/tasks')
          .replace(queryParameters: {'date': dateStr});
      final res = await http.get(uri, headers: _h(token));
      final body = jsonDecode(res.body) as Map<String, dynamic>;
      if (res.statusCode == 200) {
        // Backend returns {standing: [...], adhoc: [...]}
        final standing = (body['standing'] as List? ?? [])
            .map((e) => WorkTask.fromJson(e as Map<String, dynamic>)).toList();
        final adhoc = (body['adhoc'] as List? ?? [])
            .map((e) => WorkTask.fromJson(e as Map<String, dynamic>)).toList();
        return MyTasksResult(success: true, standingTasks: standing, adhocTasks: adhoc);
      }
      return MyTasksResult(success: false, message: body['message']?.toString());
    } catch (e) {
      return MyTasksResult(success: false, message: e.toString());
    }
  }

  static Future<WorkListResult<MyPayslip>> getMyPayslips(String token) async {
    _log('GET /my/payslips');
    try {
      final res = await http.get(
          Uri.parse('${ApiConfig.baseUrl}/my/payslips'),
          headers: _h(token));
      final body = jsonDecode(res.body) as Map<String, dynamic>;
      if (res.statusCode == 200) {
        final list = (body['data'] as List? ?? [])
            .map((e) => MyPayslip.fromJson(e as Map<String, dynamic>))
            .toList();
        return WorkListResult(success: true, data: list);
      }
      return WorkListResult(success: false, message: body['message']?.toString());
    } catch (e) {
      return WorkListResult(success: false, message: e.toString());
    }
  }

  static Future<WorkResult<TaskUpdate>> postTaskUpdate(
      String token, int taskId, Map<String, dynamic> body) async {
    _log('POST /business/work-tasks/$taskId/updates');
    try {
      final res = await http.post(
          Uri.parse('${ApiConfig.baseUrl}/business/work-tasks/$taskId/updates'),
          headers: {..._h(token), 'Content-Type': 'application/json'},
          body: jsonEncode(body));
      final data = jsonDecode(res.body) as Map<String, dynamic>;
      final d = data['data'];
      if ((res.statusCode == 200 || res.statusCode == 201) && d != null) {
        return WorkResult(success: true, data: TaskUpdate.fromJson(d as Map<String, dynamic>));
      }
      return WorkResult(success: false, message: data['message']?.toString());
    } catch (e) {
      return WorkResult(success: false, message: e.toString());
    }
  }
}
