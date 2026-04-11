// lib/assignments/models/assignments_models.dart

// ─── Priority ────────────────────────────────────────────────

enum AssignmentPriority {
  low,
  medium,
  high,
  critical;

  String get displayName {
    switch (this) {
      case AssignmentPriority.low:
        return 'Chini';
      case AssignmentPriority.medium:
        return 'Wastani';
      case AssignmentPriority.high:
        return 'Juu';
      case AssignmentPriority.critical:
        return 'Dharura';
    }
  }

  String get subtitle {
    switch (this) {
      case AssignmentPriority.low:
        return 'Low';
      case AssignmentPriority.medium:
        return 'Medium';
      case AssignmentPriority.high:
        return 'High';
      case AssignmentPriority.critical:
        return 'Critical';
    }
  }

  int get colorValue {
    switch (this) {
      case AssignmentPriority.low:
        return 0xFF4CAF50;
      case AssignmentPriority.medium:
        return 0xFFFFC107;
      case AssignmentPriority.high:
        return 0xFFFF9800;
      case AssignmentPriority.critical:
        return 0xFFF44336;
    }
  }

  static AssignmentPriority fromString(String? s) {
    return AssignmentPriority.values.firstWhere(
      (v) => v.name == s,
      orElse: () => AssignmentPriority.medium,
    );
  }
}

// ─── Status ──────────────────────────────────────────────────

enum AssignmentStatus {
  notStarted,
  inProgress,
  submitted,
  graded,
  late;

  String get displayName {
    switch (this) {
      case AssignmentStatus.notStarted:
        return 'Haijaanza';
      case AssignmentStatus.inProgress:
        return 'Inaendelea';
      case AssignmentStatus.submitted:
        return 'Imewasilishwa';
      case AssignmentStatus.graded:
        return 'Imesahihishwa';
      case AssignmentStatus.late:
        return 'Imechelewa';
    }
  }

  static AssignmentStatus fromString(String? s) {
    return AssignmentStatus.values.firstWhere(
      (v) => v.name == s,
      orElse: () => AssignmentStatus.notStarted,
    );
  }
}

// ─── Assignment ──────────────────────────────────────────────

class Assignment {
  final int id;
  final String title;
  final String description;
  final String subject;
  final String? courseCode;
  final int? classId;
  final AssignmentPriority priority;
  final AssignmentStatus status;
  final DateTime dueDate;
  final double? grade;
  final double? maxGrade;
  final List<String> attachments;
  final List<String> submissions;
  final bool isGroupAssignment;
  final DateTime createdAt;

  Assignment({
    required this.id,
    required this.title,
    required this.description,
    required this.subject,
    this.courseCode,
    this.classId,
    required this.priority,
    required this.status,
    required this.dueDate,
    this.grade,
    this.maxGrade,
    this.attachments = const [],
    this.submissions = const [],
    this.isGroupAssignment = false,
    required this.createdAt,
  });

  factory Assignment.fromJson(Map<String, dynamic> json) {
    return Assignment(
      id: _parseInt(json['id']),
      title: json['title']?.toString() ?? '',
      description: json['description']?.toString() ?? '',
      subject: json['subject']?.toString() ?? '',
      courseCode: json['course_code']?.toString(),
      classId: json['class_id'] != null ? _parseInt(json['class_id']) : null,
      priority: AssignmentPriority.fromString(json['priority']?.toString()),
      status: AssignmentStatus.fromString(json['status']?.toString()),
      dueDate: DateTime.tryParse(json['due_date']?.toString() ?? '') ??
          DateTime.now(),
      grade: _parseDouble(json['grade']),
      maxGrade: _parseDouble(json['max_grade']),
      attachments: _parseStringList(json['attachments']),
      submissions: _parseStringList(json['submissions']),
      isGroupAssignment: _parseBool(json['is_group_assignment']),
      createdAt: DateTime.tryParse(json['created_at']?.toString() ?? '') ??
          DateTime.now(),
    );
  }

  bool get isOverdue =>
      status != AssignmentStatus.submitted &&
      status != AssignmentStatus.graded &&
      DateTime.now().isAfter(dueDate);

  String get remainingTime {
    final diff = dueDate.difference(DateTime.now());
    if (diff.isNegative) return 'Imepita';
    if (diff.inDays > 0) return 'Siku ${diff.inDays}';
    if (diff.inHours > 0) return 'Saa ${diff.inHours}';
    return 'Dak ${diff.inMinutes}';
  }
}

// ─── GradeSummary ────────────────────────────────────────────

class GradeSummary {
  final String subject;
  final double average;
  final int totalAssignments;
  final int gradedCount;

  GradeSummary({
    required this.subject,
    required this.average,
    required this.totalAssignments,
    required this.gradedCount,
  });

  factory GradeSummary.fromJson(Map<String, dynamic> json) {
    return GradeSummary(
      subject: json['subject']?.toString() ?? '',
      average: _parseDouble(json['average']) ?? 0,
      totalAssignments: _parseInt(json['total_assignments']),
      gradedCount: _parseInt(json['graded_count']),
    );
  }
}

// ─── Result wrappers ─────────────────────────────────────────

class AssignmentResult<T> {
  final bool success;
  final T? data;
  final String? message;

  AssignmentResult({required this.success, this.data, this.message});
}

class AssignmentListResult<T> {
  final bool success;
  final List<T> items;
  final String? message;

  AssignmentListResult({
    required this.success,
    this.items = const [],
    this.message,
  });
}

// ─── Parse helpers ───────────────────────────────────────────

int _parseInt(dynamic v) {
  if (v is int) return v;
  if (v is double) return v.toInt();
  if (v is String) return int.tryParse(v) ?? 0;
  return 0;
}

double? _parseDouble(dynamic v) {
  if (v == null) return null;
  if (v is double) return v;
  if (v is int) return v.toDouble();
  if (v is String) return double.tryParse(v);
  return null;
}

bool _parseBool(dynamic v) {
  if (v is bool) return v;
  if (v is int) return v != 0;
  if (v is String) return v == '1' || v.toLowerCase() == 'true';
  return false;
}

List<String> _parseStringList(dynamic v) {
  if (v is List) return v.map((e) => e.toString()).toList();
  return [];
}
