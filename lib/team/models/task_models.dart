// lib/team/models/task_models.dart

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

class WorkTask {
  final int? id;
  final int employeeId;
  final int businessId;
  final String title;
  final String? description;
  final String taskType;
  final String? recurrence;
  final List<int> recurrenceDays;
  final DateTime? dueDate;
  final String status;
  final int progress;
  final DateTime assignedDate;
  final String? assigneeName;
  final String? lastComment;

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
