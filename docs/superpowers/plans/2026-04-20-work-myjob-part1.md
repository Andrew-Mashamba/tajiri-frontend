# Work Management & My Job — Implementation Plan (Part 1: Foundation)

> **For agentic workers:** REQUIRED SUB-SKILL: Use superpowers:subagent-driven-development (recommended) or superpowers:executing-plans to implement this plan task-by-task.

**Goal:** Build the data models + API service layer that all UI tasks depend on.

**Architecture:** Two new model files (`work_models.dart`, `task_models.dart`) + two service files (`work_service.dart` for manager, `my_job_service.dart` for employee). All follow existing TAJIRI patterns: static methods, bearer token param, `Result<T>` wrappers, null-safe `_parse*` helpers.

**Tech Stack:** Flutter/Dart, `http` package, `ApiConfig.baseUrl` + `ApiConfig.authHeaders(token)`

---

## Task 1: Request Backend Endpoints

**Files:**
- Run: `./scripts/ask_backend.sh`

- [ ] **Step 1: Request job description + KPI endpoints**

```bash
./scripts/ask_backend.sh "Please add these endpoints to the business API:

GET    /business/employees/{id}/job-description
       Returns: {id, employee_id, business_id, role_summary, responsibilities (JSON array of strings), reporting_to, updated_at}

PUT    /business/employees/{id}/job-description
       Body: {role_summary, responsibilities}
       Upsert — creates if not exists, updates if exists

GET    /business/employees/{id}/kpis
       Returns array of KPI objects: {id, employee_id, business_id, name, target_value, unit, review_period}

POST   /business/kpis
       Body: {employee_id, business_id, name, target_value, unit, review_period}

PUT    /business/kpis/{id}
       Body: {name, target_value, unit, review_period}

DELETE /business/kpis/{id}

GET    /business/kpis/{id}/entries
       Returns array: {id, kpi_id, actual_value, period_label, recorded_at, note}

POST   /business/kpis/{id}/entries
       Body: {actual_value, period_label, note?}

DELETE /business/kpi-entries/{id}"
```

- [ ] **Step 1b: Verify KPI/job-description routes exist on server**

```bash
sshpass -p "ZimaBlueApps" ssh root@172.240.241.180 \
  "cd /var/www/tajiri.zimasystems.com && \
   php artisan route:list | grep 'job-description' && \
   php artisan route:list | grep 'kpis' && \
   php artisan migrate && \
   php artisan optimize:clear"
```

Expected: route lines printed for each endpoint, migrations run cleanly.

- [ ] **Step 2: Request task endpoints**

```bash
./scripts/ask_backend.sh "Please add these task management endpoints:

GET    /business/employees/{id}/tasks
       Returns array of task objects for this employee.
       Each task object must include last_comment field (text of most recent TaskUpdate comment, null if none)

GET    /business/{id}/tasks
       Query params: status (pending|in_progress|done), type (standing|adhoc), employee_id
       Returns all tasks for the business, filtered. Also include last_comment on each task object.

POST   /business/tasks
       Body: {employee_id, business_id, title, description?, task_type (standing|adhoc),
              recurrence? (daily|weekly|weekdays|custom), recurrence_days? (array of ints 1-7),
              due_date? (YYYY-MM-DD, required if adhoc), assigned_date}

PUT    /business/tasks/{id}/reassign
       Body: {employee_id}

DELETE /business/tasks/{id}

GET    /business/tasks/{id}/updates
       Returns array: {id, task_id, status, progress, comment, created_at, created_by}

POST   /business/tasks/{id}/updates
       Body: {status (pending|in_progress|done), progress (0-100), comment?}"
```

- [ ] **Step 2b: Verify task routes exist on server**

```bash
sshpass -p "ZimaBlueApps" ssh root@172.240.241.180 \
  "cd /var/www/tajiri.zimasystems.com && \
   php artisan route:list | grep 'tasks' && \
   php artisan migrate && \
   php artisan optimize:clear"
```

Expected: route lines for employee tasks, business tasks, task updates, reassign, delete.

- [ ] **Step 3: Request employee-side (My Job) endpoints**

```bash
./scripts/ask_backend.sh "Please add these employee-facing endpoints (authenticated as the current user):

GET /my/job-description
    Returns the job description for the authenticated user's employee record
    Same shape as GET /business/employees/{id}/job-description

GET /my/kpis
    Returns KPIs for the authenticated user's employee record

GET /my/kpis/{id}/entries
    Returns KPI entries for the authenticated user

GET /my/tasks?date={YYYY-MM-DD}
    Returns two groups:
    - standing_tasks: recurring tasks active on the weekday of the given date
    - adhoc_tasks: ad-hoc tasks with due_date matching the given date
    Each task object must include last_comment field."
```

- [ ] **Step 3b: Verify My Job routes exist on server**

```bash
sshpass -p "ZimaBlueApps" ssh root@172.240.241.180 \
  "cd /var/www/tajiri.zimasystems.com && \
   php artisan route:list | grep 'my/' && \
   php artisan migrate && \
   php artisan optimize:clear"
```

Expected: routes for /my/job-description, /my/kpis, /my/tasks.

---

## Task 2: Work Models (`work_models.dart`)

**Files:**
- Create: `lib/team/models/work_models.dart`

- [ ] **Step 1: Create the file**

```dart
// lib/team/models/work_models.dart

int? _parseInt(dynamic v) {
  if (v == null) return null;
  if (v is int) return v;
  if (v is double) return v.toInt();
  return int.tryParse(v.toString());
}

double _parseDouble(dynamic v, [double fallback = 0.0]) {
  if (v == null) return fallback;
  if (v is double) return v;
  if (v is int) return v.toDouble();
  return double.tryParse(v.toString()) ?? fallback;
}

DateTime? _parseDate(dynamic v) {
  if (v == null) return null;
  if (v is DateTime) return v;
  return DateTime.tryParse(v.toString());
}

class JobDescription {
  final int? id;
  final int employeeId;
  final int businessId;
  final String roleSummary;
  final List<String> responsibilities;
  final String reportingTo;
  final DateTime? updatedAt;

  const JobDescription({
    this.id,
    required this.employeeId,
    required this.businessId,
    required this.roleSummary,
    required this.responsibilities,
    required this.reportingTo,
    this.updatedAt,
  });

  factory JobDescription.fromJson(Map<String, dynamic> json) {
    final raw = json['responsibilities'];
    final List<String> resps = raw is List
        ? raw.map((e) => e.toString()).toList()
        : <String>[];
    return JobDescription(
      id: _parseInt(json['id']),
      employeeId: _parseInt(json['employee_id']) ?? 0,
      businessId: _parseInt(json['business_id']) ?? 0,
      roleSummary: json['role_summary']?.toString() ?? '',
      responsibilities: resps,
      reportingTo: json['reporting_to']?.toString() ?? '',
      updatedAt: _parseDate(json['updated_at']),
    );
  }

  Map<String, dynamic> toJson() => {
        'role_summary': roleSummary,
        'responsibilities': responsibilities,
      };
}

class Kpi {
  final int? id;
  final int employeeId;
  final int businessId;
  final String name;
  final double targetValue;
  final String unit;         // "%" | "TZS" | "count" | "hrs" | custom string
  final String reviewPeriod; // "monthly" | "quarterly" | "annual"

  const Kpi({
    this.id,
    required this.employeeId,
    required this.businessId,
    required this.name,
    required this.targetValue,
    required this.unit,
    required this.reviewPeriod,
  });

  factory Kpi.fromJson(Map<String, dynamic> json) => Kpi(
        id: _parseInt(json['id']),
        employeeId: _parseInt(json['employee_id']) ?? 0,
        businessId: _parseInt(json['business_id']) ?? 0,
        name: json['name']?.toString() ?? '',
        targetValue: _parseDouble(json['target_value']),
        unit: json['unit']?.toString() ?? '%',
        reviewPeriod: json['review_period']?.toString() ?? 'monthly',
      );

  Map<String, dynamic> toJson() => {
        'employee_id': employeeId,
        'business_id': businessId,
        'name': name,
        'target_value': targetValue,
        'unit': unit,
        'review_period': reviewPeriod,
      };
}

class KpiEntry {
  final int? id;
  final int kpiId;
  final double actualValue;
  final String periodLabel;
  final DateTime recordedAt;
  final String? note;

  const KpiEntry({
    this.id,
    required this.kpiId,
    required this.actualValue,
    required this.periodLabel,
    required this.recordedAt,
    this.note,
  });

  factory KpiEntry.fromJson(Map<String, dynamic> json) => KpiEntry(
        id: _parseInt(json['id']),
        kpiId: _parseInt(json['kpi_id']) ?? 0,
        actualValue: _parseDouble(json['actual_value']),
        periodLabel: json['period_label']?.toString() ?? '',
        recordedAt: _parseDate(json['recorded_at']) ?? DateTime.now(),
        note: json['note']?.toString(),
      );

  Map<String, dynamic> toJson() => {
        'actual_value': actualValue,
        'period_label': periodLabel,
        if (note != null) 'note': note,
      };
}
```

- [ ] **Step 2: Verify it compiles**

```bash
flutter analyze lib/team/models/work_models.dart
```
Expected: No issues.

---

## Task 3: Task Models (`task_models.dart`)

**Files:**
- Create: `lib/team/models/task_models.dart`

- [ ] **Step 1: Create the file**

```dart
// lib/team/models/task_models.dart

int? _parseInt(dynamic v) {
  if (v == null) return null;
  if (v is int) return v;
  if (v is double) return v.toInt();
  return int.tryParse(v.toString());
}

bool _parseBool(dynamic v, [bool fallback = false]) {
  if (v == null) return fallback;
  if (v is bool) return v;
  if (v is int) return v == 1;
  if (v is String) return v == '1' || v.toLowerCase() == 'true';
  return fallback;
}

DateTime? _parseDate(dynamic v) {
  if (v == null) return null;
  if (v is DateTime) return v;
  return DateTime.tryParse(v.toString());
}

class WorkTask {
  final int? id;
  final int employeeId;
  final int businessId;
  final String title;
  final String? description;
  final String taskType;          // "standing" | "adhoc"
  final String? recurrence;       // "daily" | "weekly" | "weekdays" | "custom"
  final List<int> recurrenceDays; // 1=Mon…7=Sun; empty for non-custom
  final DateTime? dueDate;
  final String status;            // "pending" | "in_progress" | "done"
  final int progress;             // 0–100
  final DateTime assignedDate;
  final String? assigneeName;
  final String? lastComment; // most recent TaskUpdate comment, denormalized

  const WorkTask({
    this.id,
    required this.employeeId,
    required this.businessId,
    required this.title,
    this.description,
    required this.taskType,
    this.recurrence,
    this.recurrenceDays = const [],
    this.dueDate,
    this.status = 'pending',
    this.progress = 0,
    required this.assignedDate,
    this.assigneeName,
    this.lastComment,
  });

  factory WorkTask.fromJson(Map<String, dynamic> json) {
    final rawDays = json['recurrence_days'];
    final days = rawDays is List
        ? rawDays.map((d) => _parseInt(d) ?? 0).where((d) => d > 0).toList()
        : <int>[];
    return WorkTask(
      id: _parseInt(json['id']),
      employeeId: _parseInt(json['employee_id']) ?? 0,
      businessId: _parseInt(json['business_id']) ?? 0,
      title: json['title']?.toString() ?? '',
      description: json['description']?.toString(),
      taskType: json['task_type']?.toString() ?? 'adhoc',
      recurrence: json['recurrence']?.toString(),
      recurrenceDays: days,
      dueDate: _parseDate(json['due_date']),
      status: json['status']?.toString() ?? 'pending',
      progress: _parseInt(json['progress']) ?? 0,
      assignedDate: _parseDate(json['assigned_date']) ?? DateTime.now(),
      assigneeName: json['assignee_name']?.toString(),
      lastComment: json['last_comment']?.toString(),
    );
  }

  Map<String, dynamic> toJson() => {
        'employee_id': employeeId,
        'business_id': businessId,
        'title': title,
        if (description != null) 'description': description,
        'task_type': taskType,
        if (recurrence != null) 'recurrence': recurrence,
        if (recurrenceDays.isNotEmpty) 'recurrence_days': recurrenceDays,
        if (dueDate != null)
          'due_date': dueDate!.toIso8601String().substring(0, 10),
        'assigned_date': assignedDate.toIso8601String().substring(0, 10),
      };

  bool get isStanding => taskType == 'standing';
  bool get isAdhoc => taskType == 'adhoc';
  bool get isDone => status == 'done';
  bool get isInProgress => status == 'in_progress';
}

class TaskUpdate {
  final int? id;
  final int taskId;
  final String status;
  final int progress;
  final String? comment;
  final DateTime createdAt;
  final int createdBy;

  const TaskUpdate({
    this.id,
    required this.taskId,
    required this.status,
    required this.progress,
    this.comment,
    required this.createdAt,
    required this.createdBy,
  });

  factory TaskUpdate.fromJson(Map<String, dynamic> json) => TaskUpdate(
        id: _parseInt(json['id']),
        taskId: _parseInt(json['task_id']) ?? 0,
        status: json['status']?.toString() ?? 'pending',
        progress: _parseInt(json['progress']) ?? 0,
        comment: json['comment']?.toString(),
        createdAt: _parseDate(json['created_at']) ?? DateTime.now(),
        createdBy: _parseInt(json['created_by']) ?? 0,
      );

  Map<String, dynamic> toJson() => {
        'status': status,
        'progress': progress,
        if (comment != null && comment!.isNotEmpty) 'comment': comment,
      };
}
```

- [ ] **Step 2: Verify it compiles**

```bash
flutter analyze lib/team/models/task_models.dart
```
Expected: No issues.

---

## Task 4: Work Service (`work_service.dart`)

**Files:**
- Create: `lib/team/services/work_service.dart`

- [ ] **Step 1: Create the file**

```dart
// lib/team/services/work_service.dart

import 'dart:convert';
import 'package:flutter/foundation.dart';
import 'package:http/http.dart' as http;
import '../../config/api_config.dart';
import '../models/work_models.dart';
import '../models/task_models.dart';

String get _base => ApiConfig.baseUrl;
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

  // ── Job Description ─────────────────────────────────────────────────

  static Future<WorkResult<JobDescription>> getJobDescription(
      String token, int employeeId) async {
    final url = '$_base/business/employees/$employeeId/job-description';
    _log('GET $url');
    try {
      final res = await http.get(Uri.parse(url), headers: _h(token));
      final body = jsonDecode(res.body);
      if (res.statusCode == 200 && body['success'] == true) {
        return WorkResult(
            success: true,
            data: JobDescription.fromJson(body['data'] as Map<String, dynamic>));
      }
      return WorkResult(success: false, message: body['message']?.toString());
    } catch (e) {
      return WorkResult(success: false, message: e.toString());
    }
  }

  static Future<WorkResult<JobDescription>> saveJobDescription(
      String token, int employeeId, Map<String, dynamic> body) async {
    final url = '$_base/business/employees/$employeeId/job-description';
    _log('PUT $url');
    try {
      final res = await http.put(Uri.parse(url),
          headers: {..._h(token), 'Content-Type': 'application/json'},
          body: jsonEncode(body));
      final data = jsonDecode(res.body);
      if ((res.statusCode == 200 || res.statusCode == 201) &&
          data['success'] == true) {
        return WorkResult(
            success: true,
            data: JobDescription.fromJson(data['data'] as Map<String, dynamic>));
      }
      return WorkResult(success: false, message: data['message']?.toString());
    } catch (e) {
      return WorkResult(success: false, message: e.toString());
    }
  }

  // ── KPIs ─────────────────────────────────────────────────────────────

  static Future<WorkListResult<Kpi>> getKpis(
      String token, int employeeId) async {
    final url = '$_base/business/employees/$employeeId/kpis';
    _log('GET $url');
    try {
      final res = await http.get(Uri.parse(url), headers: _h(token));
      final body = jsonDecode(res.body);
      if (res.statusCode == 200 && body['success'] == true) {
        final list = (body['data'] as List? ?? [])
            .map((e) => Kpi.fromJson(e as Map<String, dynamic>))
            .toList();
        return WorkListResult(success: true, data: list);
      }
      return WorkListResult(success: false, message: body['message']?.toString());
    } catch (e) {
      return WorkListResult(success: false, message: e.toString());
    }
  }

  static Future<WorkResult<Kpi>> createKpi(
      String token, Map<String, dynamic> body) async {
    final url = '$_base/business/kpis';
    _log('POST $url');
    try {
      final res = await http.post(Uri.parse(url),
          headers: {..._h(token), 'Content-Type': 'application/json'},
          body: jsonEncode(body));
      final data = jsonDecode(res.body);
      if ((res.statusCode == 200 || res.statusCode == 201) &&
          data['success'] == true) {
        return WorkResult(
            success: true, data: Kpi.fromJson(data['data'] as Map<String, dynamic>));
      }
      return WorkResult(success: false, message: data['message']?.toString());
    } catch (e) {
      return WorkResult(success: false, message: e.toString());
    }
  }

  static Future<WorkResult<Kpi>> updateKpi(
      String token, int kpiId, Map<String, dynamic> body) async {
    final url = '$_base/business/kpis/$kpiId';
    _log('PUT $url');
    try {
      final res = await http.put(Uri.parse(url),
          headers: {..._h(token), 'Content-Type': 'application/json'},
          body: jsonEncode(body));
      final data = jsonDecode(res.body);
      if (res.statusCode == 200 && data['success'] == true) {
        return WorkResult(
            success: true, data: Kpi.fromJson(data['data'] as Map<String, dynamic>));
      }
      return WorkResult(success: false, message: data['message']?.toString());
    } catch (e) {
      return WorkResult(success: false, message: e.toString());
    }
  }

  static Future<WorkResult<void>> deleteKpi(String token, int kpiId) async {
    final url = '$_base/business/kpis/$kpiId';
    _log('DELETE $url');
    try {
      final res = await http.delete(Uri.parse(url), headers: _h(token));
      final data = jsonDecode(res.body);
      if (res.statusCode == 200 && data['success'] == true) {
        return const WorkResult(success: true);
      }
      return WorkResult(success: false, message: data['message']?.toString());
    } catch (e) {
      return WorkResult(success: false, message: e.toString());
    }
  }

  // ── KPI Entries ───────────────────────────────────────────────────────

  static Future<WorkListResult<KpiEntry>> getKpiEntries(
      String token, int kpiId) async {
    final url = '$_base/business/kpis/$kpiId/entries';
    _log('GET $url');
    try {
      final res = await http.get(Uri.parse(url), headers: _h(token));
      final body = jsonDecode(res.body);
      if (res.statusCode == 200 && body['success'] == true) {
        final list = (body['data'] as List? ?? [])
            .map((e) => KpiEntry.fromJson(e as Map<String, dynamic>))
            .toList();
        return WorkListResult(success: true, data: list);
      }
      return WorkListResult(success: false, message: body['message']?.toString());
    } catch (e) {
      return WorkListResult(success: false, message: e.toString());
    }
  }

  static Future<WorkResult<KpiEntry>> logKpiEntry(
      String token, int kpiId, Map<String, dynamic> body) async {
    final url = '$_base/business/kpis/$kpiId/entries';
    _log('POST $url');
    try {
      final res = await http.post(Uri.parse(url),
          headers: {..._h(token), 'Content-Type': 'application/json'},
          body: jsonEncode(body));
      final data = jsonDecode(res.body);
      if ((res.statusCode == 200 || res.statusCode == 201) &&
          data['success'] == true) {
        return WorkResult(
            success: true,
            data: KpiEntry.fromJson(data['data'] as Map<String, dynamic>));
      }
      return WorkResult(success: false, message: data['message']?.toString());
    } catch (e) {
      return WorkResult(success: false, message: e.toString());
    }
  }

  static Future<WorkResult<void>> deleteKpiEntry(
      String token, int entryId) async {
    final url = '$_base/business/kpi-entries/$entryId';
    _log('DELETE $url');
    try {
      final res = await http.delete(Uri.parse(url), headers: _h(token));
      final data = jsonDecode(res.body);
      if (res.statusCode == 200 && data['success'] == true) {
        return const WorkResult(success: true);
      }
      return WorkResult(success: false, message: data['message']?.toString());
    } catch (e) {
      return WorkResult(success: false, message: e.toString());
    }
  }

  // ── Tasks ─────────────────────────────────────────────────────────────

  static Future<WorkListResult<WorkTask>> getEmployeeTasks(
      String token, int employeeId) async {
    final url = '$_base/business/employees/$employeeId/tasks';
    _log('GET $url');
    try {
      final res = await http.get(Uri.parse(url), headers: _h(token));
      final body = jsonDecode(res.body);
      if (res.statusCode == 200 && body['success'] == true) {
        final list = (body['data'] as List? ?? [])
            .map((e) => WorkTask.fromJson(e as Map<String, dynamic>))
            .toList();
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
    final uri = Uri.parse('$_base/business/$businessId/tasks').replace(
      queryParameters: {
        if (status != null) 'status': status,
        if (type != null) 'type': type,
        if (employeeId != null) 'employee_id': employeeId.toString(),
      },
    );
    _log('GET $uri');
    try {
      final res = await http.get(uri, headers: _h(token));
      final body = jsonDecode(res.body);
      if (res.statusCode == 200 && body['success'] == true) {
        final list = (body['data'] as List? ?? [])
            .map((e) => WorkTask.fromJson(e as Map<String, dynamic>))
            .toList();
        return WorkListResult(success: true, data: list);
      }
      return WorkListResult(success: false, message: body['message']?.toString());
    } catch (e) {
      return WorkListResult(success: false, message: e.toString());
    }
  }

  static Future<WorkResult<WorkTask>> createTask(
      String token, Map<String, dynamic> body) async {
    final url = '$_base/business/tasks';
    _log('POST $url');
    try {
      final res = await http.post(Uri.parse(url),
          headers: {..._h(token), 'Content-Type': 'application/json'},
          body: jsonEncode(body));
      final data = jsonDecode(res.body);
      if ((res.statusCode == 200 || res.statusCode == 201) &&
          data['success'] == true) {
        return WorkResult(
            success: true,
            data: WorkTask.fromJson(data['data'] as Map<String, dynamic>));
      }
      return WorkResult(success: false, message: data['message']?.toString());
    } catch (e) {
      return WorkResult(success: false, message: e.toString());
    }
  }

  static Future<WorkResult<void>> reassignTask(
      String token, int taskId, int employeeId) async {
    final url = '$_base/business/tasks/$taskId/reassign';
    _log('PUT $url');
    try {
      final res = await http.put(Uri.parse(url),
          headers: {..._h(token), 'Content-Type': 'application/json'},
          body: jsonEncode({'employee_id': employeeId}));
      final data = jsonDecode(res.body);
      if (res.statusCode == 200 && data['success'] == true) {
        return const WorkResult(success: true);
      }
      return WorkResult(success: false, message: data['message']?.toString());
    } catch (e) {
      return WorkResult(success: false, message: e.toString());
    }
  }

  static Future<WorkResult<void>> deleteTask(String token, int taskId) async {
    final url = '$_base/business/tasks/$taskId';
    _log('DELETE $url');
    try {
      final res = await http.delete(Uri.parse(url), headers: _h(token));
      final data = jsonDecode(res.body);
      if (res.statusCode == 200 && data['success'] == true) {
        return const WorkResult(success: true);
      }
      return WorkResult(success: false, message: data['message']?.toString());
    } catch (e) {
      return WorkResult(success: false, message: e.toString());
    }
  }

  static Future<WorkListResult<TaskUpdate>> getTaskUpdates(
      String token, int taskId) async {
    final url = '$_base/business/tasks/$taskId/updates';
    _log('GET $url');
    try {
      final res = await http.get(Uri.parse(url), headers: _h(token));
      final body = jsonDecode(res.body);
      if (res.statusCode == 200 && body['success'] == true) {
        final list = (body['data'] as List? ?? [])
            .map((e) => TaskUpdate.fromJson(e as Map<String, dynamic>))
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
    final url = '$_base/business/tasks/$taskId/updates';
    _log('POST $url');
    try {
      final res = await http.post(Uri.parse(url),
          headers: {..._h(token), 'Content-Type': 'application/json'},
          body: jsonEncode(body));
      final data = jsonDecode(res.body);
      if ((res.statusCode == 200 || res.statusCode == 201) &&
          data['success'] == true) {
        return WorkResult(
            success: true,
            data: TaskUpdate.fromJson(data['data'] as Map<String, dynamic>));
      }
      return WorkResult(success: false, message: data['message']?.toString());
    } catch (e) {
      return WorkResult(success: false, message: e.toString());
    }
  }
}
```

- [ ] **Step 2: Analyze**

```bash
flutter analyze lib/team/services/work_service.dart
```
Expected: No issues.

---

## Task 5: My Job Service (`my_job_service.dart`)

**Files:**
- Create: `lib/myjob/services/my_job_service.dart` (create `lib/myjob/services/` directory first)

- [ ] **Step 1: Create the file**

```dart
// lib/myjob/services/my_job_service.dart

import 'dart:convert';
import 'package:flutter/foundation.dart';
import 'package:http/http.dart' as http;
import '../../config/api_config.dart';
import '../../team/models/work_models.dart';
import '../../team/models/task_models.dart';
import '../../team/services/work_service.dart' show WorkResult, WorkListResult;

String get _base => ApiConfig.baseUrl;
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

  static Future<WorkResult<JobDescription>> getMyJobDescription(
      String token) async {
    const url = '$_base/my/job-description';
    // ignore: avoid_print
    _log('GET $url');
    try {
      final res = await http.get(Uri.parse('${ApiConfig.baseUrl}/my/job-description'),
          headers: _h(token));
      final body = jsonDecode(res.body);
      if (res.statusCode == 200 && body['success'] == true) {
        return WorkResult(
            success: true,
            data: JobDescription.fromJson(body['data'] as Map<String, dynamic>));
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
      final body = jsonDecode(res.body);
      if (res.statusCode == 200 && body['success'] == true) {
        final list = (body['data'] as List? ?? [])
            .map((e) => Kpi.fromJson(e as Map<String, dynamic>))
            .toList();
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
      final body = jsonDecode(res.body);
      if (res.statusCode == 200 && body['success'] == true) {
        final list = (body['data'] as List? ?? [])
            .map((e) => KpiEntry.fromJson(e as Map<String, dynamic>))
            .toList();
        return WorkListResult(success: true, data: list);
      }
      return WorkListResult(success: false, message: body['message']?.toString());
    } catch (e) {
      return WorkListResult(success: false, message: e.toString());
    }
  }

  static Future<MyTasksResult> getMyTasks(String token,
      {DateTime? date}) async {
    final d = date ?? DateTime.now();
    final dateStr =
        '${d.year}-${d.month.toString().padLeft(2, '0')}-${d.day.toString().padLeft(2, '0')}';
    _log('GET /my/tasks?date=$dateStr');
    try {
      final uri = Uri.parse('${ApiConfig.baseUrl}/my/tasks')
          .replace(queryParameters: {'date': dateStr});
      final res = await http.get(uri, headers: _h(token));
      final body = jsonDecode(res.body);
      if (res.statusCode == 200 && body['success'] == true) {
        final data = body['data'];
        List<WorkTask> standing = [];
        List<WorkTask> adhoc = [];
        if (data is Map) {
          final rawStanding = data['standing_tasks'];
          final rawAdhoc = data['adhoc_tasks'];
          if (rawStanding is List) {
            standing = rawStanding
                .map((e) => WorkTask.fromJson(e as Map<String, dynamic>))
                .toList();
          }
          if (rawAdhoc is List) {
            adhoc = rawAdhoc
                .map((e) => WorkTask.fromJson(e as Map<String, dynamic>))
                .toList();
          }
        } else if (data is List) {
          // Flat list fallback — split by task_type
          final all = data
              .map((e) => WorkTask.fromJson(e as Map<String, dynamic>))
              .toList();
          standing = all.where((t) => t.isStanding).toList();
          adhoc = all.where((t) => t.isAdhoc).toList();
        }
        return MyTasksResult(
            success: true, standingTasks: standing, adhocTasks: adhoc);
      }
      return MyTasksResult(
          success: false, message: body['message']?.toString());
    } catch (e) {
      return MyTasksResult(success: false, message: e.toString());
    }
  }

  static Future<WorkResult<TaskUpdate>> postTaskUpdate(
      String token, int taskId, Map<String, dynamic> body) async {
    _log('POST /business/tasks/$taskId/updates');
    try {
      final res = await http.post(
          Uri.parse('${ApiConfig.baseUrl}/business/tasks/$taskId/updates'),
          headers: {..._h(token), 'Content-Type': 'application/json'},
          body: jsonEncode(body));
      final data = jsonDecode(res.body);
      if ((res.statusCode == 200 || res.statusCode == 201) &&
          data['success'] == true) {
        return WorkResult(
            success: true,
            data: TaskUpdate.fromJson(data['data'] as Map<String, dynamic>));
      }
      return WorkResult(success: false, message: data['message']?.toString());
    } catch (e) {
      return WorkResult(success: false, message: e.toString());
    }
  }
}
```

- [ ] **Step 2: Analyze**

```bash
flutter analyze lib/myjob/services/my_job_service.dart
```
Expected: No issues.

- [ ] **Step 3: Commit Part 1**

```bash
git add lib/team/models/work_models.dart lib/team/models/task_models.dart \
        lib/team/services/work_service.dart lib/myjob/services/my_job_service.dart
git commit -m "feat(work): add data models and service layer for Work/MyJob module"
```
