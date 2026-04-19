# Projects & Tasks Module Implementation Plan

> **For agentic workers:** REQUIRED SUB-SKILL: Use superpowers:subagent-driven-development (recommended) or superpowers:executing-plans to implement this plan task-by-task. Steps use checkbox (`- [ ]`) syntax for tracking.

**Goal:** Build `lib/projects/` — a project management module where business owners create projects, add tasks, assign them to team members, and track progress by status.

**Architecture:** New module following the `lib/team/` and `lib/crb/` barrel pattern. `ProjectsPage` lists projects per business. `ProjectDetailPage` shows tasks in 3 filter tabs. All mutations use bottom sheets. Wired into the business profile tab switcher in `profile_screen.dart`.

**Tech Stack:** Flutter/Dart, `http` package, `flutter_test` for unit tests, existing `BizTabWrapper` and `TeamService` for employee lookup.

**Prerequisite:** Complete `2026-04-19-enhanced-team.md` plan first (needs enhanced `Employee` model and `TeamService`).

---

### Task 1: Request backend endpoints via ask_backend.sh

**Files:**
- Run: `./scripts/ask_backend.sh`

- [ ] **Step 1: Run the backend request**

```bash
./scripts/ask_backend.sh "Please add the following Laravel API endpoints for a Projects & Tasks module:

PROJECTS:
1. GET /api/business/{businessId}/projects
   Returns: { data: [ { id, business_id, title, description, status (active|completed|on_hold), start_date, end_date, task_count, completed_count } ] }

2. POST /api/business/projects
   Body: { business_id, title, description, status, start_date, end_date }
   Returns: { data: { ...project fields } }

3. PUT /api/business/projects/{id}
   Body: same as POST (partial updates OK)
   Returns: { data: { ...project fields } }

4. DELETE /api/business/projects/{id}
   Returns: { message: 'Deleted' }

TASKS:
5. GET /api/business/projects/{projectId}/tasks
   Returns: { data: [ { id, project_id, title, description, assignee_id (employee id), assignee_name, due_date, priority (low|medium|high), status (todo|in_progress|done) } ] }

6. POST /api/business/tasks
   Body: { project_id, title, description, assignee_id, due_date, priority, status }
   Returns: { data: { ...task fields } }

7. PUT /api/business/tasks/{id}
   Body: same as POST (partial updates OK)
   Returns: { data: { ...task fields } }

8. DELETE /api/business/tasks/{id}
   Returns: { message: 'Deleted' }

All endpoints require Bearer token auth."
```

- [ ] **Step 2: Verify routes on UAT**

```bash
ssh root@172.240.241.180 "cd /var/www/tajiri && php artisan route:list | grep -E 'business/projects|business/tasks'"
```

Expected: 8 route rows covering GET/POST/PUT/DELETE for projects and tasks.

---

### Task 2: Project data models

**Files:**
- Create: `lib/projects/models/project_models.dart`
- Create: `test/projects/project_models_test.dart`

- [ ] **Step 1: Write failing tests**

```dart
// test/projects/project_models_test.dart
import 'package:flutter_test/flutter_test.dart';
import 'package:tajiri/projects/models/project_models.dart';

void main() {
  group('Project.fromJson', () {
    final json = {
      'id': 1, 'business_id': 2, 'title': 'Website Redesign',
      'description': 'Redesign the company website',
      'status': 'active', 'start_date': '2026-01-01', 'end_date': '2026-06-30',
      'task_count': 10, 'completed_count': 3,
    };
    test('parses all fields', () {
      final p = Project.fromJson(json);
      expect(p.id, 1);
      expect(p.title, 'Website Redesign');
      expect(p.status, ProjectStatus.active);
      expect(p.taskCount, 10);
      expect(p.completedCount, 3);
      expect(p.startDate?.year, 2026);
    });
    test('unknown status defaults to active', () {
      final p = Project.fromJson({...json, 'status': 'unknown'});
      expect(p.status, ProjectStatus.active);
    });
  });

  group('Task.fromJson', () {
    final json = {
      'id': 5, 'project_id': 1, 'title': 'Design mockups',
      'description': 'Create Figma mockups',
      'assignee_id': 3, 'assignee_name': 'Alice',
      'due_date': '2026-02-15',
      'priority': 'high', 'status': 'in_progress',
    };
    test('parses all fields', () {
      final t = Task.fromJson(json);
      expect(t.id, 5);
      expect(t.title, 'Design mockups');
      expect(t.priority, TaskPriority.high);
      expect(t.status, TaskStatus.inProgress);
      expect(t.assigneeId, 3);
      expect(t.assigneeName, 'Alice');
    });
    test('unknown priority defaults to medium', () {
      final t = Task.fromJson({...json, 'priority': 'urgent'});
      expect(t.priority, TaskPriority.medium);
    });
    test('unknown status defaults to todo', () {
      final t = Task.fromJson({...json, 'status': 'unknown'});
      expect(t.status, TaskStatus.todo);
    });
  });
}
```

- [ ] **Step 2: Run tests — expect failure**

```bash
flutter test test/projects/project_models_test.dart
```

Expected: compilation errors — types not defined yet.

- [ ] **Step 3: Create `lib/projects/models/project_models.dart`**

```dart
// lib/projects/models/project_models.dart
int? _parseInt(dynamic v) {
  if (v == null) return null;
  if (v is int) return v;
  if (v is double) return v.toInt();
  return int.tryParse(v.toString());
}

DateTime? _parseDate(dynamic v) {
  if (v == null) return null;
  if (v is DateTime) return v;
  return DateTime.tryParse(v.toString());
}

enum ProjectStatus { active, completed, onHold }

enum TaskStatus { todo, inProgress, done }

enum TaskPriority { low, medium, high }

ProjectStatus _parseProjectStatus(dynamic v) {
  switch (v?.toString()) {
    case 'completed': return ProjectStatus.completed;
    case 'on_hold': return ProjectStatus.onHold;
    default: return ProjectStatus.active;
  }
}

TaskStatus _parseTaskStatus(dynamic v) {
  switch (v?.toString()) {
    case 'in_progress': return TaskStatus.inProgress;
    case 'done': return TaskStatus.done;
    default: return TaskStatus.todo;
  }
}

TaskPriority _parseTaskPriority(dynamic v) {
  switch (v?.toString()) {
    case 'low': return TaskPriority.low;
    case 'high': return TaskPriority.high;
    default: return TaskPriority.medium;
  }
}

class Project {
  final int? id;
  final int? businessId;
  final String title;
  final String description;
  final ProjectStatus status;
  final DateTime? startDate;
  final DateTime? endDate;
  final int taskCount;
  final int completedCount;

  const Project({
    this.id,
    this.businessId,
    required this.title,
    this.description = '',
    this.status = ProjectStatus.active,
    this.startDate,
    this.endDate,
    this.taskCount = 0,
    this.completedCount = 0,
  });

  factory Project.fromJson(Map<String, dynamic> json) => Project(
        id: _parseInt(json['id']),
        businessId: _parseInt(json['business_id']),
        title: json['title']?.toString() ?? '',
        description: json['description']?.toString() ?? '',
        status: _parseProjectStatus(json['status']),
        startDate: _parseDate(json['start_date']),
        endDate: _parseDate(json['end_date']),
        taskCount: _parseInt(json['task_count']) ?? 0,
        completedCount: _parseInt(json['completed_count']) ?? 0,
      );

  Map<String, dynamic> toJson() => {
        'business_id': businessId,
        'title': title,
        'description': description,
        'status': switch (status) {
          ProjectStatus.active => 'active',
          ProjectStatus.completed => 'completed',
          ProjectStatus.onHold => 'on_hold',
        },
        'start_date': startDate?.toIso8601String(),
        'end_date': endDate?.toIso8601String(),
      };
}

class Task {
  final int? id;
  final int? projectId;
  final String title;
  final String description;
  final int? assigneeId;
  final String? assigneeName;
  final DateTime? dueDate;
  final TaskPriority priority;
  final TaskStatus status;

  const Task({
    this.id,
    this.projectId,
    required this.title,
    this.description = '',
    this.assigneeId,
    this.assigneeName,
    this.dueDate,
    this.priority = TaskPriority.medium,
    this.status = TaskStatus.todo,
  });

  factory Task.fromJson(Map<String, dynamic> json) => Task(
        id: _parseInt(json['id']),
        projectId: _parseInt(json['project_id']),
        title: json['title']?.toString() ?? '',
        description: json['description']?.toString() ?? '',
        assigneeId: _parseInt(json['assignee_id']),
        assigneeName: json['assignee_name']?.toString(),
        dueDate: _parseDate(json['due_date']),
        priority: _parseTaskPriority(json['priority']),
        status: _parseTaskStatus(json['status']),
      );

  Map<String, dynamic> toJson() => {
        'project_id': projectId,
        'title': title,
        'description': description,
        'assignee_id': assigneeId,
        'due_date': dueDate?.toIso8601String(),
        'priority': switch (priority) {
          TaskPriority.low => 'low',
          TaskPriority.medium => 'medium',
          TaskPriority.high => 'high',
        },
        'status': switch (status) {
          TaskStatus.todo => 'todo',
          TaskStatus.inProgress => 'in_progress',
          TaskStatus.done => 'done',
        },
      };
}
```

- [ ] **Step 4: Run tests — expect pass**

```bash
flutter test test/projects/project_models_test.dart
```

Expected: All tests pass.

- [ ] **Step 5: Commit**

```bash
git add lib/projects/models/project_models.dart test/projects/project_models_test.dart
git commit -m "feat(projects): add Project and Task data models with unit tests"
```

---

### Task 3: ProjectService

**Files:**
- Create: `lib/projects/services/project_service.dart`

- [ ] **Step 1: Create the service**

```dart
// lib/projects/services/project_service.dart
import 'dart:convert';
import 'package:flutter/foundation.dart';
import 'package:http/http.dart' as http;
import '../../config/api_config.dart';
import '../models/project_models.dart';

String get _base => ApiConfig.baseUrl;
void _log(String msg) => debugPrint('[ProjectService] $msg');

class ProjectResult<T> {
  final bool success;
  final T? data;
  final String? message;
  ProjectResult({required this.success, this.data, this.message});
}

class ProjectListResult<T> {
  final bool success;
  final List<T> data;
  final String? message;
  ProjectListResult({required this.success, this.data = const [], this.message});
}

class ProjectService {
  ProjectService._();

  static Future<ProjectListResult<Project>> getProjects(
      String token, int businessId) async {
    try {
      final url = '$_base/business/$businessId/projects';
      _log('GET $url');
      final res = await http.get(Uri.parse(url), headers: ApiConfig.authHeaders(token));
      if (res.statusCode == 200) {
        final data = jsonDecode(res.body);
        final list = (data['data'] as List? ?? [])
            .map((e) => Project.fromJson(e as Map<String, dynamic>))
            .toList();
        return ProjectListResult(success: true, data: list);
      }
      return ProjectListResult(success: false,
          message: (jsonDecode(res.body)['message']?.toString()) ?? 'Error: ${res.statusCode}');
    } catch (e) {
      return ProjectListResult(success: false, message: e.toString());
    }
  }

  static Future<ProjectResult<Project>> createProject(
      String token, Map<String, dynamic> body) async {
    try {
      final url = '$_base/business/projects';
      _log('POST $url');
      final res = await http.post(Uri.parse(url),
          headers: ApiConfig.authHeaders(token), body: jsonEncode(body));
      if (res.statusCode == 200 || res.statusCode == 201) {
        final data = jsonDecode(res.body);
        return ProjectResult(success: true, data: Project.fromJson(data['data'] ?? data));
      }
      return ProjectResult(success: false,
          message: (jsonDecode(res.body)['message']?.toString()) ?? 'Error: ${res.statusCode}');
    } catch (e) {
      return ProjectResult(success: false, message: e.toString());
    }
  }

  static Future<ProjectResult<Project>> updateProject(
      String token, int projectId, Map<String, dynamic> body) async {
    try {
      final url = '$_base/business/projects/$projectId';
      _log('PUT $url');
      final res = await http.put(Uri.parse(url),
          headers: ApiConfig.authHeaders(token), body: jsonEncode(body));
      if (res.statusCode == 200) {
        final data = jsonDecode(res.body);
        return ProjectResult(success: true, data: Project.fromJson(data['data'] ?? data));
      }
      return ProjectResult(success: false,
          message: (jsonDecode(res.body)['message']?.toString()) ?? 'Error: ${res.statusCode}');
    } catch (e) {
      return ProjectResult(success: false, message: e.toString());
    }
  }

  static Future<ProjectResult<void>> deleteProject(
      String token, int projectId) async {
    try {
      final url = '$_base/business/projects/$projectId';
      _log('DELETE $url');
      final res = await http.delete(Uri.parse(url), headers: ApiConfig.authHeaders(token));
      if (res.statusCode == 200) return ProjectResult(success: true);
      return ProjectResult(success: false, message: 'Error: ${res.statusCode}');
    } catch (e) {
      return ProjectResult(success: false, message: e.toString());
    }
  }

  static Future<ProjectListResult<Task>> getTasks(
      String token, int projectId) async {
    try {
      final url = '$_base/business/projects/$projectId/tasks';
      _log('GET $url');
      final res = await http.get(Uri.parse(url), headers: ApiConfig.authHeaders(token));
      if (res.statusCode == 200) {
        final data = jsonDecode(res.body);
        final list = (data['data'] as List? ?? [])
            .map((e) => Task.fromJson(e as Map<String, dynamic>))
            .toList();
        return ProjectListResult(success: true, data: list);
      }
      return ProjectListResult(success: false,
          message: (jsonDecode(res.body)['message']?.toString()) ?? 'Error: ${res.statusCode}');
    } catch (e) {
      return ProjectListResult(success: false, message: e.toString());
    }
  }

  static Future<ProjectResult<Task>> createTask(
      String token, Map<String, dynamic> body) async {
    try {
      final url = '$_base/business/tasks';
      _log('POST $url');
      final res = await http.post(Uri.parse(url),
          headers: ApiConfig.authHeaders(token), body: jsonEncode(body));
      if (res.statusCode == 200 || res.statusCode == 201) {
        final data = jsonDecode(res.body);
        return ProjectResult(success: true, data: Task.fromJson(data['data'] ?? data));
      }
      return ProjectResult(success: false,
          message: (jsonDecode(res.body)['message']?.toString()) ?? 'Error: ${res.statusCode}');
    } catch (e) {
      return ProjectResult(success: false, message: e.toString());
    }
  }

  static Future<ProjectResult<Task>> updateTask(
      String token, int taskId, Map<String, dynamic> body) async {
    try {
      final url = '$_base/business/tasks/$taskId';
      _log('PUT $url');
      final res = await http.put(Uri.parse(url),
          headers: ApiConfig.authHeaders(token), body: jsonEncode(body));
      if (res.statusCode == 200) {
        final data = jsonDecode(res.body);
        return ProjectResult(success: true, data: Task.fromJson(data['data'] ?? data));
      }
      return ProjectResult(success: false,
          message: (jsonDecode(res.body)['message']?.toString()) ?? 'Error: ${res.statusCode}');
    } catch (e) {
      return ProjectResult(success: false, message: e.toString());
    }
  }

  static Future<ProjectResult<void>> deleteTask(
      String token, int taskId) async {
    try {
      final url = '$_base/business/tasks/$taskId';
      _log('DELETE $url');
      final res = await http.delete(Uri.parse(url), headers: ApiConfig.authHeaders(token));
      if (res.statusCode == 200) return ProjectResult(success: true);
      return ProjectResult(success: false, message: 'Error: ${res.statusCode}');
    } catch (e) {
      return ProjectResult(success: false, message: e.toString());
    }
  }
}
```

- [ ] **Step 2: Analyze**

```bash
flutter analyze lib/projects/services/project_service.dart
```

Expected: No errors.

- [ ] **Step 3: Commit**

```bash
git add lib/projects/services/project_service.dart
git commit -m "feat(projects): add ProjectService — full CRUD for projects and tasks"
```

---

### Task 4: ProjectCard and TaskCard widgets

**Files:**
- Create: `lib/projects/widgets/project_card.dart`
- Create: `lib/projects/widgets/task_card.dart`

- [ ] **Step 1: Create `lib/projects/widgets/project_card.dart`**

```dart
// lib/projects/widgets/project_card.dart
import 'package:flutter/material.dart';
import '../models/project_models.dart';

const Color _kPrimary = Color(0xFF1A1A1A);
const Color _kSecondary = Color(0xFF666666);
const Color _kCardBg = Color(0xFFFFFFFF);

class ProjectCard extends StatelessWidget {
  final Project project;
  final bool isSwahili;
  final VoidCallback onTap;
  final VoidCallback onEditTap;
  final VoidCallback onDeleteTap;

  const ProjectCard({
    super.key,
    required this.project,
    required this.isSwahili,
    required this.onTap,
    required this.onEditTap,
    required this.onDeleteTap,
  });

  String _statusLabel(bool sw) {
    switch (project.status) {
      case ProjectStatus.active: return sw ? 'Inafanya Kazi' : 'Active';
      case ProjectStatus.completed: return sw ? 'Imekamilika' : 'Completed';
      case ProjectStatus.onHold: return sw ? 'Imesimamishwa' : 'On Hold';
    }
  }

  @override
  Widget build(BuildContext context) {
    final sw = isSwahili;
    final progress = project.taskCount > 0
        ? project.completedCount / project.taskCount
        : 0.0;
    final isOverdue = project.endDate != null &&
        project.endDate!.isBefore(DateTime.now()) &&
        project.status != ProjectStatus.completed;

    return GestureDetector(
      onTap: onTap,
      child: Container(
        margin: const EdgeInsets.only(bottom: 10),
        padding: const EdgeInsets.all(14),
        decoration: BoxDecoration(
          color: _kCardBg,
          borderRadius: BorderRadius.circular(14),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Expanded(
                  child: Text(project.title,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: const TextStyle(
                          fontSize: 15, fontWeight: FontWeight.w600, color: _kPrimary)),
                ),
                PopupMenuButton<String>(
                  icon: const Icon(Icons.more_vert_rounded, size: 18, color: _kSecondary),
                  onSelected: (v) {
                    if (v == 'edit') onEditTap();
                    if (v == 'delete') onDeleteTap();
                  },
                  itemBuilder: (_) => [
                    PopupMenuItem(value: 'edit', child: Text(sw ? 'Hariri' : 'Edit')),
                    PopupMenuItem(value: 'delete', child: Text(sw ? 'Futa' : 'Delete')),
                  ],
                ),
              ],
            ),
            if (project.description.isNotEmpty) ...[
              const SizedBox(height: 4),
              Text(project.description,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: const TextStyle(fontSize: 13, color: _kSecondary)),
            ],
            const SizedBox(height: 8),
            Row(
              children: [
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                  decoration: BoxDecoration(
                    color: Colors.grey.shade100,
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Text(_statusLabel(sw),
                      style: const TextStyle(fontSize: 11, color: _kPrimary)),
                ),
                const Spacer(),
                if (project.endDate != null)
                  Text(
                    '${project.endDate!.year}-${project.endDate!.month.toString().padLeft(2, '0')}-${project.endDate!.day.toString().padLeft(2, '0')}',
                    style: TextStyle(
                        fontSize: 11,
                        color: isOverdue ? Colors.red : _kSecondary),
                  ),
              ],
            ),
            const SizedBox(height: 8),
            LinearProgressIndicator(
              value: progress,
              backgroundColor: Colors.grey.shade200,
              color: _kPrimary,
              minHeight: 4,
              borderRadius: BorderRadius.circular(2),
            ),
            const SizedBox(height: 4),
            Text(
              sw
                  ? '${project.completedCount}/${project.taskCount} kazi zilizokamilika'
                  : '${project.completedCount}/${project.taskCount} tasks done',
              style: const TextStyle(fontSize: 11, color: _kSecondary),
            ),
          ],
        ),
      ),
    );
  }
}
```

- [ ] **Step 2: Create `lib/projects/widgets/task_card.dart`**

```dart
// lib/projects/widgets/task_card.dart
import 'package:flutter/material.dart';
import '../models/project_models.dart';

const Color _kPrimary = Color(0xFF1A1A1A);
const Color _kSecondary = Color(0xFF666666);
const Color _kCardBg = Color(0xFFFFFFFF);

class TaskCard extends StatelessWidget {
  final Task task;
  final bool isSwahili;
  final VoidCallback onTap;

  const TaskCard({
    super.key,
    required this.task,
    required this.isSwahili,
    required this.onTap,
  });

  Color _priorityColor() {
    switch (task.priority) {
      case TaskPriority.low: return Colors.grey.shade400;
      case TaskPriority.medium: return Colors.amber.shade600;
      case TaskPriority.high: return Colors.red.shade400;
    }
  }

  @override
  Widget build(BuildContext context) {
    final sw = isSwahili;
    final isOverdue = task.dueDate != null &&
        task.dueDate!.isBefore(DateTime.now()) &&
        task.status != TaskStatus.done;

    return GestureDetector(
      onTap: onTap,
      child: Container(
        margin: const EdgeInsets.only(bottom: 8),
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
        decoration: BoxDecoration(
          color: _kCardBg,
          borderRadius: BorderRadius.circular(12),
        ),
        child: Row(
          children: [
            Container(
              width: 8, height: 8,
              margin: const EdgeInsets.only(right: 10, top: 2),
              decoration: BoxDecoration(
                color: _priorityColor(),
                shape: BoxShape.circle,
              ),
            ),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(task.title,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: const TextStyle(
                          fontSize: 14, fontWeight: FontWeight.w600, color: _kPrimary)),
                  if (task.assigneeName != null) ...[
                    const SizedBox(height: 2),
                    Text(task.assigneeName!,
                        style: const TextStyle(fontSize: 12, color: _kSecondary)),
                  ],
                ],
              ),
            ),
            if (task.dueDate != null)
              Text(
                '${task.dueDate!.month.toString().padLeft(2, '0')}/${task.dueDate!.day.toString().padLeft(2, '0')}',
                style: TextStyle(
                    fontSize: 11,
                    color: isOverdue ? Colors.red : _kSecondary),
              ),
            const SizedBox(width: 6),
            const Icon(Icons.chevron_right_rounded, size: 16, color: _kSecondary),
          ],
        ),
      ),
    );
  }
}
```

- [ ] **Step 3: Analyze**

```bash
flutter analyze lib/projects/widgets/
```

Expected: No errors.

- [ ] **Step 4: Commit**

```bash
git add lib/projects/widgets/project_card.dart lib/projects/widgets/task_card.dart
git commit -m "feat(projects): add ProjectCard and TaskCard widgets"
```

---

### Task 5: AddProjectSheet and AddTaskSheet widgets

**Files:**
- Create: `lib/projects/widgets/add_project_sheet.dart`
- Create: `lib/projects/widgets/add_task_sheet.dart`

- [ ] **Step 1: Create `lib/projects/widgets/add_project_sheet.dart`**

Handles both add (project==null) and edit (project!=null) modes.

```dart
// lib/projects/widgets/add_project_sheet.dart
import 'package:flutter/material.dart';
import '../../l10n/app_strings_scope.dart';
import '../models/project_models.dart';
import '../services/project_service.dart';

const Color _kPrimary = Color(0xFF1A1A1A);
const Color _kSecondary = Color(0xFF666666);
const Color _kBackground = Color(0xFFFAFAFA);
const Color _kCardBg = Color(0xFFFFFFFF);

class AddProjectSheet extends StatefulWidget {
  final String token;
  final int businessId;
  final Project? project; // null = add mode
  final VoidCallback onSaved;

  const AddProjectSheet({
    super.key,
    required this.token,
    required this.businessId,
    this.project,
    required this.onSaved,
  });

  @override
  State<AddProjectSheet> createState() => _AddProjectSheetState();
}

class _AddProjectSheetState extends State<AddProjectSheet> {
  late final TextEditingController _titleCtrl;
  late final TextEditingController _descCtrl;
  late ProjectStatus _status;
  DateTime? _startDate;
  DateTime? _endDate;
  bool _saving = false;

  static const _statuses = [ProjectStatus.active, ProjectStatus.onHold, ProjectStatus.completed];

  @override
  void initState() {
    super.initState();
    final p = widget.project;
    _titleCtrl = TextEditingController(text: p?.title ?? '');
    _descCtrl = TextEditingController(text: p?.description ?? '');
    _status = p?.status ?? ProjectStatus.active;
    _startDate = p?.startDate;
    _endDate = p?.endDate;
  }

  @override
  void dispose() {
    _titleCtrl.dispose();
    _descCtrl.dispose();
    super.dispose();
  }

  String _statusLabel(ProjectStatus s, bool sw) {
    switch (s) {
      case ProjectStatus.active: return sw ? 'Inafanya Kazi' : 'Active';
      case ProjectStatus.completed: return sw ? 'Imekamilika' : 'Completed';
      case ProjectStatus.onHold: return sw ? 'Imesimamishwa' : 'On Hold';
    }
  }

  String _statusValue(ProjectStatus s) {
    switch (s) {
      case ProjectStatus.active: return 'active';
      case ProjectStatus.completed: return 'completed';
      case ProjectStatus.onHold: return 'on_hold';
    }
  }

  Future<void> _pickDate(bool isStart, bool sw) async {
    final initial = (isStart ? _startDate : _endDate) ?? DateTime.now();
    final picked = await showDatePicker(
      context: context,
      initialDate: initial,
      firstDate: DateTime(2020),
      lastDate: DateTime(2100),
    );
    if (picked != null && mounted) {
      setState(() {
        if (isStart) _startDate = picked;
        else _endDate = picked;
      });
    }
  }

  Future<void> _save(bool sw) async {
    if (_titleCtrl.text.trim().isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(sw ? 'Tafadhali weka jina la mradi' : 'Please enter a project title')));
      return;
    }
    setState(() => _saving = true);
    final messenger = ScaffoldMessenger.of(context);
    final nav = Navigator.of(context);
    final body = {
      'business_id': widget.businessId,
      'title': _titleCtrl.text.trim(),
      'description': _descCtrl.text.trim(),
      'status': _statusValue(_status),
      'start_date': _startDate?.toIso8601String(),
      'end_date': _endDate?.toIso8601String(),
    };
    try {
      final bool success;
      String? msg;
      if (widget.project == null) {
        final res = await ProjectService.createProject(widget.token, body);
        success = res.success;
        msg = res.message;
      } else {
        final res = await ProjectService.updateProject(widget.token, widget.project!.id!, body);
        success = res.success;
        msg = res.message;
      }
      if (!mounted) return;
      nav.pop();
      messenger.showSnackBar(SnackBar(
          content: Text(success
              ? (sw ? 'Imehifadhiwa' : 'Saved')
              : (msg ?? (sw ? 'Imeshindikana' : 'Failed')))));
      if (success) widget.onSaved();
    } catch (e) {
      if (mounted) {
        setState(() => _saving = false);
        messenger.showSnackBar(
            SnackBar(content: Text(sw ? 'Imeshindikana' : 'An error occurred')));
      }
    }
  }

  Widget _dateRow(String label, DateTime? date, VoidCallback onTap) {
    return InkWell(
      onTap: onTap,
      child: InputDecorator(
        decoration: InputDecoration(
          labelText: label,
          prefixIcon: const Icon(Icons.calendar_today_rounded, size: 18, color: _kSecondary),
          filled: true,
          fillColor: _kBackground,
          border: OutlineInputBorder(borderRadius: BorderRadius.circular(10), borderSide: BorderSide.none),
          contentPadding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
        ),
        child: Text(
          date != null
              ? '${date.year}-${date.month.toString().padLeft(2, '0')}-${date.day.toString().padLeft(2, '0')}'
              : '—',
          style: TextStyle(
              fontSize: 14, color: date != null ? _kPrimary : Colors.grey.shade400),
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final sw = AppStringsScope.of(context)?.isSwahili ?? false;
    return Padding(
      padding: EdgeInsets.only(
        left: 20, right: 20, top: 20,
        bottom: MediaQuery.of(context).viewInsets.bottom + 20,
      ),
      child: SingleChildScrollView(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Center(child: Container(width: 40, height: 4,
                decoration: BoxDecoration(color: Colors.grey.shade300, borderRadius: BorderRadius.circular(2)))),
            const SizedBox(height: 16),
            Text(
              widget.project == null
                  ? (sw ? 'Mradi Mpya' : 'New Project')
                  : (sw ? 'Hariri Mradi' : 'Edit Project'),
              style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: _kPrimary),
            ),
            const SizedBox(height: 16),
            TextField(
              controller: _titleCtrl,
              decoration: InputDecoration(
                labelText: sw ? 'Jina la Mradi' : 'Project Title',
                prefixIcon: const Icon(Icons.folder_rounded, size: 20, color: _kSecondary),
                filled: true, fillColor: _kBackground,
                border: OutlineInputBorder(borderRadius: BorderRadius.circular(10), borderSide: BorderSide.none),
                contentPadding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
              ),
            ),
            const SizedBox(height: 10),
            TextField(
              controller: _descCtrl,
              maxLines: 3,
              decoration: InputDecoration(
                labelText: sw ? 'Maelezo' : 'Description',
                filled: true, fillColor: _kBackground,
                border: OutlineInputBorder(borderRadius: BorderRadius.circular(10), borderSide: BorderSide.none),
                contentPadding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
              ),
            ),
            const SizedBox(height: 10),
            DropdownButtonFormField<ProjectStatus>(
              value: _status,
              decoration: InputDecoration(
                labelText: sw ? 'Hali' : 'Status',
                prefixIcon: const Icon(Icons.flag_rounded, size: 20, color: _kSecondary),
                filled: true, fillColor: _kBackground,
                border: OutlineInputBorder(borderRadius: BorderRadius.circular(10), borderSide: BorderSide.none),
                contentPadding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
              ),
              items: _statuses.map((s) => DropdownMenuItem(
                value: s, child: Text(_statusLabel(s, sw)),
              )).toList(),
              onChanged: (v) => setState(() => _status = v ?? ProjectStatus.active),
            ),
            const SizedBox(height: 10),
            _dateRow(sw ? 'Tarehe ya Kuanza' : 'Start Date', _startDate,
                () => _pickDate(true, sw)),
            const SizedBox(height: 10),
            _dateRow(sw ? 'Tarehe ya Mwisho' : 'End Date', _endDate,
                () => _pickDate(false, sw)),
            const SizedBox(height: 16),
            SizedBox(
              width: double.infinity, height: 48,
              child: ElevatedButton(
                onPressed: _saving ? null : () => _save(sw),
                style: ElevatedButton.styleFrom(
                  backgroundColor: _kPrimary, foregroundColor: Colors.white,
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                ),
                child: _saving
                    ? const SizedBox(width: 18, height: 18,
                        child: CircularProgressIndicator(color: Colors.white, strokeWidth: 2))
                    : Text(sw ? 'Hifadhi' : 'Save',
                        style: const TextStyle(fontSize: 15, fontWeight: FontWeight.w600)),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
```

- [ ] **Step 2: Create `lib/projects/widgets/add_task_sheet.dart`**

Handles both add (task==null) and edit modes. Loads employees via `TeamService.getEmployees`.

```dart
// lib/projects/widgets/add_task_sheet.dart
import 'package:flutter/material.dart';
import '../../l10n/app_strings_scope.dart';
import '../../team/models/team_models.dart';
import '../../team/services/team_service.dart';
import '../models/project_models.dart';
import '../services/project_service.dart';

const Color _kPrimary = Color(0xFF1A1A1A);
const Color _kSecondary = Color(0xFF666666);
const Color _kBackground = Color(0xFFFAFAFA);
const Color _kCardBg = Color(0xFFFFFFFF);

class AddTaskSheet extends StatefulWidget {
  final String token;
  final int projectId;
  final int businessId;
  final Task? task; // null = add mode
  final VoidCallback onSaved;

  const AddTaskSheet({
    super.key,
    required this.token,
    required this.projectId,
    required this.businessId,
    this.task,
    required this.onSaved,
  });

  @override
  State<AddTaskSheet> createState() => _AddTaskSheetState();
}

class _AddTaskSheetState extends State<AddTaskSheet> {
  late final TextEditingController _titleCtrl;
  late final TextEditingController _descCtrl;
  late TaskPriority _priority;
  late TaskStatus _status;
  DateTime? _dueDate;
  int? _assigneeId;
  String? _assigneeName;
  List<Employee> _employees = [];
  bool _saving = false;

  @override
  void initState() {
    super.initState();
    final t = widget.task;
    _titleCtrl = TextEditingController(text: t?.title ?? '');
    _descCtrl = TextEditingController(text: t?.description ?? '');
    _priority = t?.priority ?? TaskPriority.medium;
    _status = t?.status ?? TaskStatus.todo;
    _dueDate = t?.dueDate;
    _assigneeId = t?.assigneeId;
    _assigneeName = t?.assigneeName;
    _loadEmployees();
  }

  @override
  void dispose() {
    _titleCtrl.dispose();
    _descCtrl.dispose();
    super.dispose();
  }

  Future<void> _loadEmployees() async {
    final res = await TeamService.getEmployees(widget.token, widget.businessId);
    if (mounted && res.success) {
      setState(() => _employees = res.data);
    }
  }

  Future<void> _pickDate(bool sw) async {
    final picked = await showDatePicker(
      context: context,
      initialDate: _dueDate ?? DateTime.now(),
      firstDate: DateTime(2020),
      lastDate: DateTime(2100),
    );
    if (picked != null && mounted) setState(() => _dueDate = picked);
  }

  String _priorityLabel(TaskPriority p, bool sw) {
    switch (p) {
      case TaskPriority.low: return sw ? 'Chini' : 'Low';
      case TaskPriority.medium: return sw ? 'Kati' : 'Medium';
      case TaskPriority.high: return sw ? 'Juu' : 'High';
    }
  }

  String _statusLabel(TaskStatus s, bool sw) {
    switch (s) {
      case TaskStatus.todo: return sw ? 'Kusubiri' : 'To-Do';
      case TaskStatus.inProgress: return sw ? 'Inaendelea' : 'In Progress';
      case TaskStatus.done: return sw ? 'Imekamilika' : 'Done';
    }
  }

  Future<void> _save(bool sw) async {
    if (_titleCtrl.text.trim().isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(sw ? 'Tafadhali weka jina la kazi' : 'Please enter a task title')));
      return;
    }
    setState(() => _saving = true);
    final messenger = ScaffoldMessenger.of(context);
    final nav = Navigator.of(context);
    final body = {
      'project_id': widget.projectId,
      'title': _titleCtrl.text.trim(),
      'description': _descCtrl.text.trim(),
      'assignee_id': _assigneeId,
      'due_date': _dueDate?.toIso8601String(),
      'priority': switch (_priority) {
        TaskPriority.low => 'low',
        TaskPriority.medium => 'medium',
        TaskPriority.high => 'high',
      },
      'status': switch (_status) {
        TaskStatus.todo => 'todo',
        TaskStatus.inProgress => 'in_progress',
        TaskStatus.done => 'done',
      },
    };
    try {
      final bool success;
      String? msg;
      if (widget.task == null) {
        final res = await ProjectService.createTask(widget.token, body);
        success = res.success;
        msg = res.message;
      } else {
        final res = await ProjectService.updateTask(widget.token, widget.task!.id!, body);
        success = res.success;
        msg = res.message;
      }
      if (!mounted) return;
      nav.pop();
      messenger.showSnackBar(SnackBar(
          content: Text(success
              ? (sw ? 'Imehifadhiwa' : 'Saved')
              : (msg ?? (sw ? 'Imeshindikana' : 'Failed')))));
      if (success) widget.onSaved();
    } catch (e) {
      if (mounted) {
        setState(() => _saving = false);
        messenger.showSnackBar(SnackBar(content: Text(sw ? 'Imeshindikana' : 'An error occurred')));
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final sw = AppStringsScope.of(context)?.isSwahili ?? false;
    return Padding(
      padding: EdgeInsets.only(
        left: 20, right: 20, top: 20,
        bottom: MediaQuery.of(context).viewInsets.bottom + 20,
      ),
      child: SingleChildScrollView(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Center(child: Container(width: 40, height: 4,
                decoration: BoxDecoration(color: Colors.grey.shade300, borderRadius: BorderRadius.circular(2)))),
            const SizedBox(height: 16),
            Text(
              widget.task == null ? (sw ? 'Kazi Mpya' : 'New Task') : (sw ? 'Hariri Kazi' : 'Edit Task'),
              style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: _kPrimary),
            ),
            const SizedBox(height: 16),
            TextField(
              controller: _titleCtrl,
              decoration: InputDecoration(
                labelText: sw ? 'Jina la Kazi' : 'Task Title',
                prefixIcon: const Icon(Icons.task_rounded, size: 20, color: _kSecondary),
                filled: true, fillColor: _kBackground,
                border: OutlineInputBorder(borderRadius: BorderRadius.circular(10), borderSide: BorderSide.none),
                contentPadding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
              ),
            ),
            const SizedBox(height: 10),
            TextField(
              controller: _descCtrl,
              maxLines: 2,
              decoration: InputDecoration(
                labelText: sw ? 'Maelezo' : 'Description',
                filled: true, fillColor: _kBackground,
                border: OutlineInputBorder(borderRadius: BorderRadius.circular(10), borderSide: BorderSide.none),
                contentPadding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
              ),
            ),
            const SizedBox(height: 10),
            // Assignee picker
            DropdownButtonFormField<int?>(
              value: _assigneeId,
              decoration: InputDecoration(
                labelText: sw ? 'Mwanatimu' : 'Assignee',
                prefixIcon: const Icon(Icons.person_rounded, size: 20, color: _kSecondary),
                filled: true, fillColor: _kBackground,
                border: OutlineInputBorder(borderRadius: BorderRadius.circular(10), borderSide: BorderSide.none),
                contentPadding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
              ),
              items: [
                DropdownMenuItem<int?>(value: null, child: Text(sw ? 'Hakuna' : 'Unassigned')),
                ..._employees.map((e) => DropdownMenuItem<int?>(
                  value: e.id,
                  child: Text(e.name, maxLines: 1, overflow: TextOverflow.ellipsis),
                )),
              ],
              onChanged: (v) => setState(() {
                _assigneeId = v;
                _assigneeName = v == null
                    ? null
                    : _employees.firstWhere((e) => e.id == v, orElse: () => Employee(name: '')).name;
              }),
            ),
            const SizedBox(height: 10),
            DropdownButtonFormField<TaskPriority>(
              value: _priority,
              decoration: InputDecoration(
                labelText: sw ? 'Kipaumbele' : 'Priority',
                prefixIcon: const Icon(Icons.flag_rounded, size: 20, color: _kSecondary),
                filled: true, fillColor: _kBackground,
                border: OutlineInputBorder(borderRadius: BorderRadius.circular(10), borderSide: BorderSide.none),
                contentPadding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
              ),
              items: TaskPriority.values.map((p) => DropdownMenuItem(
                value: p, child: Text(_priorityLabel(p, sw)),
              )).toList(),
              onChanged: (v) => setState(() => _priority = v ?? TaskPriority.medium),
            ),
            const SizedBox(height: 10),
            DropdownButtonFormField<TaskStatus>(
              value: _status,
              decoration: InputDecoration(
                labelText: sw ? 'Hali' : 'Status',
                prefixIcon: const Icon(Icons.checklist_rounded, size: 20, color: _kSecondary),
                filled: true, fillColor: _kBackground,
                border: OutlineInputBorder(borderRadius: BorderRadius.circular(10), borderSide: BorderSide.none),
                contentPadding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
              ),
              items: TaskStatus.values.map((s) => DropdownMenuItem(
                value: s, child: Text(_statusLabel(s, sw)),
              )).toList(),
              onChanged: (v) => setState(() => _status = v ?? TaskStatus.todo),
            ),
            const SizedBox(height: 10),
            InkWell(
              onTap: () => _pickDate(sw),
              child: InputDecorator(
                decoration: InputDecoration(
                  labelText: sw ? 'Tarehe ya Mwisho' : 'Due Date',
                  prefixIcon: const Icon(Icons.calendar_today_rounded, size: 18, color: _kSecondary),
                  filled: true, fillColor: _kBackground,
                  border: OutlineInputBorder(borderRadius: BorderRadius.circular(10), borderSide: BorderSide.none),
                  contentPadding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
                ),
                child: Text(
                  _dueDate != null
                      ? '${_dueDate!.year}-${_dueDate!.month.toString().padLeft(2, '0')}-${_dueDate!.day.toString().padLeft(2, '0')}'
                      : '—',
                  style: TextStyle(
                      fontSize: 14, color: _dueDate != null ? _kPrimary : Colors.grey.shade400),
                ),
              ),
            ),
            const SizedBox(height: 16),
            SizedBox(
              width: double.infinity, height: 48,
              child: ElevatedButton(
                onPressed: _saving ? null : () => _save(sw),
                style: ElevatedButton.styleFrom(
                  backgroundColor: _kPrimary, foregroundColor: Colors.white,
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                ),
                child: _saving
                    ? const SizedBox(width: 18, height: 18,
                        child: CircularProgressIndicator(color: Colors.white, strokeWidth: 2))
                    : Text(sw ? 'Hifadhi' : 'Save',
                        style: const TextStyle(fontSize: 15, fontWeight: FontWeight.w600)),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
```

- [ ] **Step 3: Analyze**

```bash
flutter analyze lib/projects/widgets/
```

Expected: No errors.

- [ ] **Step 4: Commit**

```bash
git add lib/projects/widgets/add_project_sheet.dart lib/projects/widgets/add_task_sheet.dart
git commit -m "feat(projects): add AddProjectSheet and AddTaskSheet — add/edit bottom sheets"
```

---

### Task 6: ProjectsPage

**Files:**
- Create: `lib/projects/pages/projects_page.dart`

- [ ] **Step 1: Create the page**

```dart
// lib/projects/pages/projects_page.dart
import 'package:flutter/material.dart';
import '../../l10n/app_strings_scope.dart';
import '../../services/local_storage_service.dart';
import '../models/project_models.dart';
import '../services/project_service.dart';
import '../widgets/add_project_sheet.dart';
import '../widgets/project_card.dart';
import 'project_detail_page.dart';

const Color _kPrimary = Color(0xFF1A1A1A);
const Color _kSecondary = Color(0xFF666666);
const Color _kBackground = Color(0xFFFAFAFA);
const Color _kCardBg = Color(0xFFFFFFFF);

class ProjectsPage extends StatefulWidget {
  final int businessId;
  const ProjectsPage({super.key, required this.businessId});

  @override
  State<ProjectsPage> createState() => _ProjectsPageState();
}

class _ProjectsPageState extends State<ProjectsPage> {
  String? _token;
  bool _loading = true;
  String? _error;
  List<Project> _projects = [];

  bool get _sw => AppStringsScope.of(context)?.isSwahili ?? false;

  @override
  void initState() {
    super.initState();
    _init();
  }

  Future<void> _init() async {
    final storage = await LocalStorageService.getInstance();
    _token = storage.getAuthToken();
    await _load();
  }

  Future<void> _load() async {
    if (_token == null || !mounted) return;
    setState(() { _loading = true; _error = null; });
    final res = await ProjectService.getProjects(_token!, widget.businessId);
    if (!mounted) return;
    setState(() {
      _loading = false;
      if (res.success) {
        _projects = res.data;
      } else {
        _error = res.message;
      }
    });
  }

  void _openAdd() {
    if (_token == null) return;
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: _kCardBg,
      shape: const RoundedRectangleBorder(
          borderRadius: BorderRadius.vertical(top: Radius.circular(20))),
      builder: (_) => AddProjectSheet(
        token: _token!,
        businessId: widget.businessId,
        onSaved: _load,
      ),
    );
  }

  void _openEdit(Project project) {
    if (_token == null) return;
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: _kCardBg,
      shape: const RoundedRectangleBorder(
          borderRadius: BorderRadius.vertical(top: Radius.circular(20))),
      builder: (_) => AddProjectSheet(
        token: _token!,
        businessId: widget.businessId,
        project: project,
        onSaved: _load,
      ),
    );
  }

  Future<void> _confirmDelete(Project project) async {
    if (_token == null || project.id == null) return;
    final sw = _sw;
    final confirm = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: Text(sw ? 'Futa Mradi' : 'Delete Project',
            style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
        content: Text(sw
            ? 'Futa mradi "${project.title}"?'
            : 'Delete project "${project.title}"?'),
        actions: [
          TextButton(onPressed: () => Navigator.pop(ctx, false),
              child: Text(sw ? 'Ghairi' : 'Cancel')),
          ElevatedButton(
            onPressed: () => Navigator.pop(ctx, true),
            style: ElevatedButton.styleFrom(backgroundColor: Colors.red, foregroundColor: Colors.white),
            child: Text(sw ? 'Futa' : 'Delete'),
          ),
        ],
      ),
    );
    if (confirm != true || !mounted) return;
    final res = await ProjectService.deleteProject(_token!, project.id!);
    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(SnackBar(
        content: Text(res.success
            ? (sw ? 'Imefutwa' : 'Deleted')
            : (res.message ?? (sw ? 'Imeshindikana' : 'Failed')))));
    if (res.success) _load();
  }

  void _openDetail(Project project) {
    if (_token == null) return;
    Navigator.of(context).push(MaterialPageRoute<void>(
      builder: (_) => ProjectDetailPage(
        project: project,
        token: _token!,
        businessId: widget.businessId,
        onChanged: _load,
      ),
    ));
  }

  @override
  Widget build(BuildContext context) {
    final sw = _sw;
    return Scaffold(
      backgroundColor: _kBackground,
      floatingActionButton: FloatingActionButton(
        onPressed: _openAdd,
        backgroundColor: _kPrimary,
        child: const Icon(Icons.add_rounded, color: Colors.white),
      ),
      body: _loading
          ? const Center(child: CircularProgressIndicator(color: _kPrimary, strokeWidth: 2))
          : _error != null
              ? Center(
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Icon(Icons.error_outline_rounded, size: 48, color: Colors.grey.shade300),
                      const SizedBox(height: 12),
                      Text(sw ? 'Imeshindikana kupakia' : 'Failed to load',
                          style: TextStyle(color: Colors.grey.shade500)),
                      const SizedBox(height: 12),
                      ElevatedButton(
                        onPressed: _load,
                        style: ElevatedButton.styleFrom(
                            backgroundColor: _kPrimary, foregroundColor: Colors.white),
                        child: Text(sw ? 'Jaribu Tena' : 'Retry'),
                      ),
                    ],
                  ),
                )
              : _projects.isEmpty
                  ? Center(
                      child: Column(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Icon(Icons.folder_open_rounded, size: 64, color: Colors.grey.shade300),
                          const SizedBox(height: 12),
                          Text(sw ? 'Hakuna miradi' : 'No projects yet',
                              style: TextStyle(color: Colors.grey.shade500, fontSize: 16)),
                          const SizedBox(height: 4),
                          Text(sw ? 'Bonyeza + kuunda mradi' : 'Tap + to create a project',
                              style: TextStyle(color: Colors.grey.shade400, fontSize: 13)),
                        ],
                      ),
                    )
                  : RefreshIndicator(
                      color: _kPrimary,
                      onRefresh: _load,
                      child: ListView.builder(
                        padding: const EdgeInsets.all(16),
                        itemCount: _projects.length,
                        itemBuilder: (_, i) {
                          final p = _projects[i];
                          return ProjectCard(
                            project: p,
                            isSwahili: sw,
                            onTap: () => _openDetail(p),
                            onEditTap: () => _openEdit(p),
                            onDeleteTap: () => _confirmDelete(p),
                          );
                        },
                      ),
                    ),
    );
  }
}
```

- [ ] **Step 2: Analyze**

```bash
flutter analyze lib/projects/pages/projects_page.dart
```

Expected: No errors (ProjectDetailPage import will resolve after Task 7).

- [ ] **Step 3: Commit**

```bash
git add lib/projects/pages/projects_page.dart
git commit -m "feat(projects): add ProjectsPage — project list with add/edit/delete"
```

---

### Task 7: ProjectDetailPage

**Files:**
- Create: `lib/projects/pages/project_detail_page.dart`

- [ ] **Step 1: Create the page**

```dart
// lib/projects/pages/project_detail_page.dart
import 'package:flutter/material.dart';
import '../../l10n/app_strings_scope.dart';
import '../models/project_models.dart';
import '../services/project_service.dart';
import '../widgets/add_project_sheet.dart';
import '../widgets/add_task_sheet.dart';
import '../widgets/task_card.dart';

const Color _kPrimary = Color(0xFF1A1A1A);
const Color _kSecondary = Color(0xFF666666);
const Color _kBackground = Color(0xFFFAFAFA);
const Color _kCardBg = Color(0xFFFFFFFF);

class ProjectDetailPage extends StatefulWidget {
  final Project project;
  final String token;
  final int businessId;
  final VoidCallback onChanged;

  const ProjectDetailPage({
    super.key,
    required this.project,
    required this.token,
    required this.businessId,
    required this.onChanged,
  });

  @override
  State<ProjectDetailPage> createState() => _ProjectDetailPageState();
}

class _ProjectDetailPageState extends State<ProjectDetailPage>
    with SingleTickerProviderStateMixin {
  late TabController _tabCtrl;
  List<Task> _tasks = [];
  bool _loading = true;
  String? _error;

  bool get _sw => AppStringsScope.of(context)?.isSwahili ?? false;

  @override
  void initState() {
    super.initState();
    _tabCtrl = TabController(length: 3, vsync: this);
    _load();
  }

  @override
  void dispose() {
    _tabCtrl.dispose();
    super.dispose();
  }

  Future<void> _load() async {
    if (!mounted) return;
    setState(() { _loading = true; _error = null; });
    final res = await ProjectService.getTasks(widget.token, widget.project.id!);
    if (!mounted) return;
    setState(() {
      _loading = false;
      if (res.success) {
        _tasks = res.data;
      } else {
        _error = res.message;
      }
    });
  }

  List<Task> _filteredByStatus(TaskStatus status) =>
      _tasks.where((t) => t.status == status).toList();

  void _openAddTask() {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: _kCardBg,
      shape: const RoundedRectangleBorder(
          borderRadius: BorderRadius.vertical(top: Radius.circular(20))),
      builder: (_) => AddTaskSheet(
        token: widget.token,
        projectId: widget.project.id!,
        businessId: widget.businessId,
        onSaved: () { _load(); widget.onChanged(); },
      ),
    );
  }

  void _openEditTask(Task task) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: _kCardBg,
      shape: const RoundedRectangleBorder(
          borderRadius: BorderRadius.vertical(top: Radius.circular(20))),
      builder: (_) => AddTaskSheet(
        token: widget.token,
        projectId: widget.project.id!,
        businessId: widget.businessId,
        task: task,
        onSaved: () { _load(); widget.onChanged(); },
      ),
    );
  }

  Future<void> _confirmDeleteTask(Task task) async {
    if (task.id == null) return;
    final sw = _sw;
    final confirm = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: Text(sw ? 'Futa Kazi' : 'Delete Task',
            style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
        content: Text(sw ? 'Futa "${task.title}"?' : 'Delete "${task.title}"?'),
        actions: [
          TextButton(onPressed: () => Navigator.pop(ctx, false),
              child: Text(sw ? 'Ghairi' : 'Cancel')),
          ElevatedButton(
            onPressed: () => Navigator.pop(ctx, true),
            style: ElevatedButton.styleFrom(backgroundColor: Colors.red, foregroundColor: Colors.white),
            child: Text(sw ? 'Futa' : 'Delete'),
          ),
        ],
      ),
    );
    if (confirm != true || !mounted) return;
    final res = await ProjectService.deleteTask(widget.token, task.id!);
    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(SnackBar(
        content: Text(res.success
            ? (sw ? 'Imefutwa' : 'Deleted')
            : (res.message ?? (sw ? 'Imeshindikana' : 'Failed')))));
    if (res.success) { _load(); widget.onChanged(); }
  }

  void _openEditProject() {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: _kCardBg,
      shape: const RoundedRectangleBorder(
          borderRadius: BorderRadius.vertical(top: Radius.circular(20))),
      builder: (_) => AddProjectSheet(
        token: widget.token,
        businessId: widget.businessId,
        project: widget.project,
        onSaved: () { widget.onChanged(); if (mounted) Navigator.of(context).pop(); },
      ),
    );
  }

  Widget _taskList(TaskStatus status) {
    final list = _filteredByStatus(status);
    final sw = _sw;
    if (_loading) {
      return const Center(child: CircularProgressIndicator(color: _kPrimary, strokeWidth: 2));
    }
    if (_error != null) {
      return Center(child: Text(_error!, style: TextStyle(color: Colors.grey.shade500)));
    }
    if (list.isEmpty) {
      return Center(
        child: Text(
          sw ? 'Hakuna kazi' : 'No tasks',
          style: TextStyle(color: Colors.grey.shade400, fontSize: 14),
        ),
      );
    }
    return RefreshIndicator(
      color: _kPrimary,
      onRefresh: _load,
      child: ListView.builder(
        padding: const EdgeInsets.all(16),
        itemCount: list.length,
        itemBuilder: (_, i) {
          final t = list[i];
          return GestureDetector(
            onLongPress: () => _confirmDeleteTask(t),
            child: TaskCard(
              task: t,
              isSwahili: sw,
              onTap: () => _openEditTask(t),
            ),
          );
        },
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final sw = _sw;
    final p = widget.project;

    return Scaffold(
      backgroundColor: _kBackground,
      appBar: AppBar(
        backgroundColor: _kBackground,
        elevation: 0,
        leading: BackButton(
          color: _kPrimary,
          onPressed: () { widget.onChanged(); Navigator.of(context).pop(); },
        ),
        title: Text(p.title,
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            style: const TextStyle(color: _kPrimary, fontSize: 16, fontWeight: FontWeight.bold)),
        actions: [
          IconButton(
            icon: const Icon(Icons.edit_rounded, color: _kPrimary),
            onPressed: _openEditProject,
          ),
        ],
        bottom: TabBar(
          controller: _tabCtrl,
          labelColor: _kPrimary,
          unselectedLabelColor: _kSecondary,
          indicatorColor: _kPrimary,
          tabs: [
            Tab(text: sw ? 'Kusubiri' : 'To-Do'),
            Tab(text: sw ? 'Inaendelea' : 'In Progress'),
            Tab(text: sw ? 'Imekamilika' : 'Done'),
          ],
        ),
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: _openAddTask,
        backgroundColor: _kPrimary,
        child: const Icon(Icons.add_task_rounded, color: Colors.white),
      ),
      body: TabBarView(
        controller: _tabCtrl,
        children: [
          _taskList(TaskStatus.todo),
          _taskList(TaskStatus.inProgress),
          _taskList(TaskStatus.done),
        ],
      ),
    );
  }
}
```

- [ ] **Step 2: Analyze**

```bash
flutter analyze lib/projects/pages/
```

Expected: No errors.

- [ ] **Step 3: Commit**

```bash
git add lib/projects/pages/project_detail_page.dart lib/projects/pages/projects_page.dart
git commit -m "feat(projects): add ProjectDetailPage — tabbed task view (To-Do/In Progress/Done)"
```

---

### Task 8: projects.dart barrel

**Files:**
- Create: `lib/projects/projects.dart`

- [ ] **Step 1: Create the barrel**

```dart
// lib/projects/projects.dart
export 'models/project_models.dart';
export 'pages/project_detail_page.dart' show ProjectDetailPage;
export 'pages/projects_page.dart' show ProjectsPage;
export 'services/project_service.dart' show ProjectService;
```

- [ ] **Step 2: Analyze the whole module**

```bash
flutter analyze lib/projects/
```

Expected: No errors.

- [ ] **Step 3: Commit**

```bash
git add lib/projects/projects.dart
git commit -m "feat(projects): add projects.dart barrel"
```

---

### Task 9: Wire navigation — profile_screen.dart and reminder_navigation.dart

**Files:**
- Modify: `lib/screens/profile/profile_screen.dart`
- Modify: `lib/reminders/reminder_navigation.dart`

- [ ] **Step 1: Add import to `profile_screen.dart`**

Find the existing import block near the top of `lib/screens/profile/profile_screen.dart` where other `lib/` modules are imported, and add:

```dart
import '../../projects/projects.dart' show ProjectsPage;
```

- [ ] **Step 2: Add the `biz_projects` case in `profile_screen.dart`**

In the big switch statement around line 2214 (after the `biz_payroll` case), add:

```dart
      case 'biz_projects':
        return BizTabWrapper(userId: userId, builder: (uid, all, first, fId) =>
            fId != null ? ProjectsPage(businessId: fId) : const SizedBox.shrink());
```

- [ ] **Step 3: Add import to `reminder_navigation.dart`**

Add to the imports in `lib/reminders/reminder_navigation.dart`:

```dart
import '../projects/projects.dart' show ProjectsPage;
```

- [ ] **Step 4: Add the `/biz_projects` case in `reminder_navigation.dart`**

In the switch statement inside `openSource`, after the `/biz_appointments` case (around line 176), add:

```dart
      case '/biz_projects':
        page = BizTabWrapper(
          userId: profileUserId,
          builder: (uid, all, first, fId) =>
              fId != null ? ProjectsPage(businessId: fId) : const SizedBox.shrink(),
        );
        break;
```

- [ ] **Step 5: Analyze both files**

```bash
flutter analyze lib/screens/profile/profile_screen.dart lib/reminders/reminder_navigation.dart
```

Expected: No errors.

- [ ] **Step 6: Run all tests**

```bash
flutter test
```

Expected: All tests pass.

- [ ] **Step 7: Analyze entire project**

```bash
flutter analyze
```

Expected: No errors.

- [ ] **Step 8: Commit**

```bash
git add lib/screens/profile/profile_screen.dart lib/reminders/reminder_navigation.dart
git commit -m "feat(projects): wire ProjectsPage into profile tab switcher and reminder navigation"
```

---
