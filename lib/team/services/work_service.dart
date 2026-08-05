// lib/team/services/work_service.dart

import 'dart:convert';
import 'package:flutter/foundation.dart';
import 'package:http/http.dart' as http;
import '../../services/http_retry.dart';
import '../../config/api_config.dart';
import '../models/work_models.dart';
import '../models/task_models.dart';

void _log(String m) => debugPrint('[WorkService] $m');

class WorkResult<T> {
  final bool success;
  final T? data;
  final String? message;
  const WorkResult({required this.success, this.data, this.message});
}

class WorkListResult<T> {
  final bool success;
  final List<T> data;
  final String? message;
  const WorkListResult({required this.success, this.data = const [], this.message});
}

class WorkService {
  static Map<String, String> _h(String token) => ApiConfig.authHeaders(token);

  // ── Job Description ──────────────────────────────────────────────────────

  static Future<WorkResult<JobDescription>> getJobDescription(
      String token, int employeeId) async {
    final url = '${ApiConfig.baseUrl}/business/employees/$employeeId/job-description';
    _log('GET $url');
    try {
      final res = await httpGetWithRetry(Uri.parse(url), headers: _h(token));
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

  static Future<WorkResult<JobDescription>> saveJobDescription(
      String token, int employeeId, Map<String, dynamic> body) async {
    final url = '${ApiConfig.baseUrl}/business/employees/$employeeId/job-description';
    _log('PUT $url');
    try {
      final res = await http.put(Uri.parse(url),
          headers: {..._h(token), 'Content-Type': 'application/json'},
          body: jsonEncode(body));
      final data = jsonDecode(res.body) as Map<String, dynamic>;
      final d = data['data'];
      if ((res.statusCode == 200 || res.statusCode == 201) && d != null) {
        return WorkResult(success: true, data: JobDescription.fromJson(d as Map<String, dynamic>));
      }
      return WorkResult(success: false, message: data['message']?.toString());
    } catch (e) {
      return WorkResult(success: false, message: e.toString());
    }
  }

  // ── KPIs ─────────────────────────────────────────────────────────────────

  static Future<WorkListResult<Kpi>> getKpis(String token, int employeeId) async {
    final url = '${ApiConfig.baseUrl}/business/employees/$employeeId/kpis';
    _log('GET $url');
    try {
      final res = await httpGetWithRetry(Uri.parse(url), headers: _h(token));
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

  static Future<WorkResult<Kpi>> createKpi(String token, Map<String, dynamic> body) async {
    final url = '${ApiConfig.baseUrl}/business/kpis';
    _log('POST $url');
    try {
      final res = await http.post(Uri.parse(url),
          headers: {..._h(token), 'Content-Type': 'application/json'},
          body: jsonEncode(body));
      final data = jsonDecode(res.body) as Map<String, dynamic>;
      final d = data['data'];
      if ((res.statusCode == 200 || res.statusCode == 201) && d != null) {
        return WorkResult(success: true, data: Kpi.fromJson(d as Map<String, dynamic>));
      }
      return WorkResult(success: false, message: data['message']?.toString());
    } catch (e) {
      return WorkResult(success: false, message: e.toString());
    }
  }

  static Future<WorkResult<Kpi>> updateKpi(String token, int kpiId, Map<String, dynamic> body) async {
    final url = '${ApiConfig.baseUrl}/business/kpis/$kpiId';
    _log('PUT $url');
    try {
      final res = await http.put(Uri.parse(url),
          headers: {..._h(token), 'Content-Type': 'application/json'},
          body: jsonEncode(body));
      final data = jsonDecode(res.body) as Map<String, dynamic>;
      final d = data['data'];
      if (res.statusCode == 200 && d != null) {
        return WorkResult(success: true, data: Kpi.fromJson(d as Map<String, dynamic>));
      }
      return WorkResult(success: false, message: data['message']?.toString());
    } catch (e) {
      return WorkResult(success: false, message: e.toString());
    }
  }

  static Future<WorkResult<void>> deleteKpi(String token, int kpiId) async {
    final url = '${ApiConfig.baseUrl}/business/kpis/$kpiId';
    _log('DELETE $url');
    try {
      final res = await http.delete(Uri.parse(url), headers: _h(token));
      final data = jsonDecode(res.body) as Map<String, dynamic>;
      if (res.statusCode == 200) return const WorkResult(success: true);
      return WorkResult(success: false, message: data['message']?.toString());
    } catch (e) {
      return WorkResult(success: false, message: e.toString());
    }
  }

  static Future<WorkListResult<KpiEntry>> getKpiEntries(String token, int kpiId) async {
    final url = '${ApiConfig.baseUrl}/business/kpis/$kpiId/entries';
    _log('GET $url');
    try {
      final res = await httpGetWithRetry(Uri.parse(url), headers: _h(token));
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

  static Future<WorkResult<KpiEntry>> logKpiEntry(
      String token, int kpiId, Map<String, dynamic> body) async {
    final url = '${ApiConfig.baseUrl}/business/kpis/$kpiId/entries';
    _log('POST $url');
    try {
      final res = await http.post(Uri.parse(url),
          headers: {..._h(token), 'Content-Type': 'application/json'},
          body: jsonEncode(body));
      final data = jsonDecode(res.body) as Map<String, dynamic>;
      final d = data['data'];
      if ((res.statusCode == 200 || res.statusCode == 201) && d != null) {
        return WorkResult(success: true, data: KpiEntry.fromJson(d as Map<String, dynamic>));
      }
      return WorkResult(success: false, message: data['message']?.toString());
    } catch (e) {
      return WorkResult(success: false, message: e.toString());
    }
  }

  static Future<WorkResult<void>> deleteKpiEntry(String token, int entryId) async {
    final url = '${ApiConfig.baseUrl}/business/kpi-entries/$entryId';
    _log('DELETE $url');
    try {
      final res = await http.delete(Uri.parse(url), headers: _h(token));
      final data = jsonDecode(res.body) as Map<String, dynamic>;
      if (res.statusCode == 200) return const WorkResult(success: true);
      return WorkResult(success: false, message: data['message']?.toString());
    } catch (e) {
      return WorkResult(success: false, message: e.toString());
    }
  }

  // ── Tasks ─────────────────────────────────────────────────────────────────

  static Future<WorkListResult<WorkTask>> getEmployeeTasks(
      String token, int employeeId) async {
    final url = '${ApiConfig.baseUrl}/business/employees/$employeeId/tasks';
    _log('GET $url');
    try {
      final res = await httpGetWithRetry(Uri.parse(url), headers: _h(token));
      final body = jsonDecode(res.body) as Map<String, dynamic>;
      if (res.statusCode == 200) {
        final list = (body['data'] as List? ?? [])
            .map((e) => WorkTask.fromJson(e as Map<String, dynamic>)).toList();
        return WorkListResult(success: true, data: list);
      }
      return WorkListResult(success: false, message: body['message']?.toString());
    } catch (e) {
      return WorkListResult(success: false, message: e.toString());
    }
  }

  static Future<WorkListResult<WorkTask>> getAllBusinessTasks(
      String token, int businessId,
      {String? status, String? type, int? employeeId}) async {
    final uri = Uri.parse('${ApiConfig.baseUrl}/business/$businessId/tasks').replace(
      queryParameters: {
        if (status != null) 'status': status,
        if (type != null) 'type': type,
        if (employeeId != null) 'employee_id': employeeId.toString(),
      },
    );
    _log('GET $uri');
    try {
      final res = await httpGetWithRetry(uri, headers: _h(token));
      final body = jsonDecode(res.body) as Map<String, dynamic>;
      if (res.statusCode == 200) {
        final list = (body['data'] as List? ?? [])
            .map((e) => WorkTask.fromJson(e as Map<String, dynamic>)).toList();
        return WorkListResult(success: true, data: list);
      }
      return WorkListResult(success: false, message: body['message']?.toString());
    } catch (e) {
      return WorkListResult(success: false, message: e.toString());
    }
  }

  // NOTE: createTask/updateTask/reassignTask/deleteTask/getTaskUpdates/postTaskUpdate
  // all use /business/work-tasks (not /business/tasks) to avoid collision with project tasks

  static Future<WorkResult<WorkTask>> createTask(
      String token, Map<String, dynamic> body) async {
    final url = '${ApiConfig.baseUrl}/business/work-tasks';
    _log('POST $url');
    try {
      final res = await http.post(Uri.parse(url),
          headers: {..._h(token), 'Content-Type': 'application/json'},
          body: jsonEncode(body));
      final data = jsonDecode(res.body) as Map<String, dynamic>;
      final d = data['data'];
      if ((res.statusCode == 200 || res.statusCode == 201) && d != null) {
        return WorkResult(success: true, data: WorkTask.fromJson(d as Map<String, dynamic>));
      }
      return WorkResult(success: false, message: data['message']?.toString());
    } catch (e) {
      return WorkResult(success: false, message: e.toString());
    }
  }

  static Future<WorkResult<WorkTask>> updateTask(
      String token, int taskId, Map<String, dynamic> body) async {
    final url = '${ApiConfig.baseUrl}/business/work-tasks/$taskId';
    _log('PUT $url');
    try {
      final res = await http.put(Uri.parse(url),
          headers: {..._h(token), 'Content-Type': 'application/json'},
          body: jsonEncode(body));
      final data = jsonDecode(res.body) as Map<String, dynamic>;
      final d = data['data'];
      if (res.statusCode == 200 && d != null) {
        return WorkResult(success: true, data: WorkTask.fromJson(d as Map<String, dynamic>));
      }
      return WorkResult(success: false, message: data['message']?.toString());
    } catch (e) {
      return WorkResult(success: false, message: e.toString());
    }
  }

  static Future<WorkResult<void>> reassignTask(
      String token, int taskId, int employeeId) async {
    final url = '${ApiConfig.baseUrl}/business/work-tasks/$taskId/reassign';
    _log('PUT $url');
    try {
      final res = await http.put(Uri.parse(url),
          headers: {..._h(token), 'Content-Type': 'application/json'},
          body: jsonEncode({'employee_id': employeeId}));
      final data = jsonDecode(res.body) as Map<String, dynamic>;
      if (res.statusCode == 200) return const WorkResult(success: true);
      return WorkResult(success: false, message: data['message']?.toString());
    } catch (e) {
      return WorkResult(success: false, message: e.toString());
    }
  }

  static Future<WorkResult<void>> deleteTask(String token, int taskId) async {
    final url = '${ApiConfig.baseUrl}/business/work-tasks/$taskId';
    _log('DELETE $url');
    try {
      final res = await http.delete(Uri.parse(url), headers: _h(token));
      final data = jsonDecode(res.body) as Map<String, dynamic>;
      if (res.statusCode == 200) return const WorkResult(success: true);
      return WorkResult(success: false, message: data['message']?.toString());
    } catch (e) {
      return WorkResult(success: false, message: e.toString());
    }
  }

  static Future<WorkListResult<TaskUpdate>> getTaskUpdates(
      String token, int taskId) async {
    final url = '${ApiConfig.baseUrl}/business/work-tasks/$taskId/updates';
    _log('GET $url');
    try {
      final res = await httpGetWithRetry(Uri.parse(url), headers: _h(token));
      final body = jsonDecode(res.body) as Map<String, dynamic>;
      if (res.statusCode == 200) {
        final list = (body['data'] as List? ?? [])
            .map((e) => TaskUpdate.fromJson(e as Map<String, dynamic>)).toList();
        return WorkListResult(success: true, data: list);
      }
      return WorkListResult(success: false, message: body['message']?.toString());
    } catch (e) {
      return WorkListResult(success: false, message: e.toString());
    }
  }

  static Future<WorkResult<TaskUpdate>> postTaskUpdate(
      String token, int taskId, Map<String, dynamic> body) async {
    final url = '${ApiConfig.baseUrl}/business/work-tasks/$taskId/updates';
    _log('POST $url');
    try {
      final res = await http.post(Uri.parse(url),
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
