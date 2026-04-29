// lib/my_children/models/school_age_models.dart

// ─── Academic Record ──────────────────────────────────────────

class AcademicRecord {
  final int id;
  final int childId;
  final int term;
  final int year;
  final String subject;
  final String? grade;
  final double? score;
  final String? teacherNotes;
  final int? schoolId;

  AcademicRecord({
    required this.id,
    required this.childId,
    required this.term,
    required this.year,
    required this.subject,
    this.grade,
    this.score,
    this.teacherNotes,
    this.schoolId,
  });

  factory AcademicRecord.fromJson(Map<String, dynamic> json) {
    return AcademicRecord(
      id: _parseInt(json['id']),
      childId: _parseInt(json['child_id']),
      term: _parseInt(json['term']),
      year: _parseInt(json['year']),
      subject: json['subject'] as String? ?? '',
      grade: json['grade'] as String?,
      score: json['score'] != null ? _parseDouble(json['score']) : null,
      teacherNotes: json['teacher_notes'] as String?,
      schoolId: json['school_id'] != null ? _parseInt(json['school_id']) : null,
    );
  }

  Map<String, dynamic> toJson() => {
        'child_id': childId,
        'term': term,
        'year': year,
        'subject': subject,
        if (grade != null) 'grade': grade,
        if (score != null) 'score': score,
        if (teacherNotes != null) 'teacher_notes': teacherNotes,
        if (schoolId != null) 'school_id': schoolId,
      };
}

// ─── Homework Assignment ──────────────────────────────────────

class HomeworkAssignment {
  final int id;
  final int childId;
  final String subject;
  final String title;
  final String? description;
  final DateTime dueDate;
  final bool isCompleted;
  final DateTime? completedAt;

  HomeworkAssignment({
    required this.id,
    required this.childId,
    required this.subject,
    required this.title,
    this.description,
    required this.dueDate,
    this.isCompleted = false,
    this.completedAt,
  });

  factory HomeworkAssignment.fromJson(Map<String, dynamic> json) {
    return HomeworkAssignment(
      id: _parseInt(json['id']),
      childId: _parseInt(json['child_id']),
      subject: json['subject'] as String? ?? '',
      title: json['title'] as String? ?? '',
      description: json['description'] as String?,
      dueDate: _parseDate(json['due_date']) ?? DateTime.now(),
      isCompleted: _parseBool(json['is_completed']),
      completedAt: _parseDate(json['completed_at']),
    );
  }

  Map<String, dynamic> toJson() => {
        'child_id': childId,
        'subject': subject,
        'title': title,
        if (description != null) 'description': description,
        'due_date': dueDate.toIso8601String(),
        'is_completed': isCompleted,
        if (completedAt != null) 'completed_at': completedAt!.toIso8601String(),
      };

  HomeworkAssignment copyWith({
    bool? isCompleted,
    DateTime? completedAt,
  }) {
    return HomeworkAssignment(
      id: id,
      childId: childId,
      subject: subject,
      title: title,
      description: description,
      dueDate: dueDate,
      isCompleted: isCompleted ?? this.isCompleted,
      completedAt: completedAt ?? this.completedAt,
    );
  }

  bool get isOverdue =>
      !isCompleted && dueDate.isBefore(DateTime.now());

  bool get isDueToday {
    final now = DateTime.now();
    return !isCompleted &&
        dueDate.year == now.year &&
        dueDate.month == now.month &&
        dueDate.day == now.day;
  }
}

// ─── Chore Assignment ─────────────────────────────────────────

class ChoreAssignment {
  final int id;
  final int childId;
  final String title;
  final String? titleSwahili;
  final String frequency; // daily, weekly, monthly
  final double rewardAmount;
  final bool isCompleted;
  final DateTime? completedAt;
  final int? assignedBy;

  ChoreAssignment({
    required this.id,
    required this.childId,
    required this.title,
    this.titleSwahili,
    required this.frequency,
    this.rewardAmount = 0,
    this.isCompleted = false,
    this.completedAt,
    this.assignedBy,
  });

  factory ChoreAssignment.fromJson(Map<String, dynamic> json) {
    return ChoreAssignment(
      id: _parseInt(json['id']),
      childId: _parseInt(json['child_id']),
      title: json['title'] as String? ?? '',
      titleSwahili: json['title_swahili'] as String?,
      frequency: json['frequency'] as String? ?? 'daily',
      rewardAmount: _parseDouble(json['reward_amount']),
      isCompleted: _parseBool(json['is_completed']),
      completedAt: _parseDate(json['completed_at']),
      assignedBy:
          json['assigned_by'] != null ? _parseInt(json['assigned_by']) : null,
    );
  }

  Map<String, dynamic> toJson() => {
        'child_id': childId,
        'title': title,
        if (titleSwahili != null) 'title_swahili': titleSwahili,
        'frequency': frequency,
        'reward_amount': rewardAmount,
        'is_completed': isCompleted,
        if (completedAt != null) 'completed_at': completedAt!.toIso8601String(),
        if (assignedBy != null) 'assigned_by': assignedBy,
      };

  ChoreAssignment copyWith({bool? isCompleted, DateTime? completedAt}) {
    return ChoreAssignment(
      id: id,
      childId: childId,
      title: title,
      titleSwahili: titleSwahili,
      frequency: frequency,
      rewardAmount: rewardAmount,
      isCompleted: isCompleted ?? this.isCompleted,
      completedAt: completedAt ?? this.completedAt,
      assignedBy: assignedBy,
    );
  }

  String localizedTitle({bool isSwahili = true}) {
    if (isSwahili && titleSwahili != null && titleSwahili!.isNotEmpty) {
      return titleSwahili!;
    }
    return title;
  }
}

// ─── Allowance Transaction ────────────────────────────────────

class AllowanceTransaction {
  final int id;
  final int childId;
  final double amount;
  final String type; // earned, spent, saved, given
  final String? description;
  final String? source; // chore, gift, other
  final DateTime date;

  AllowanceTransaction({
    required this.id,
    required this.childId,
    required this.amount,
    required this.type,
    this.description,
    this.source,
    required this.date,
  });

  factory AllowanceTransaction.fromJson(Map<String, dynamic> json) {
    return AllowanceTransaction(
      id: _parseInt(json['id']),
      childId: _parseInt(json['child_id']),
      amount: _parseDouble(json['amount']),
      type: json['type'] as String? ?? 'earned',
      description: json['description'] as String?,
      source: json['source'] as String?,
      date: _parseDate(json['date']) ?? DateTime.now(),
    );
  }

  Map<String, dynamic> toJson() => {
        'child_id': childId,
        'amount': amount,
        'type': type,
        if (description != null) 'description': description,
        if (source != null) 'source': source,
        'date': date.toIso8601String(),
      };
}

// ─── Activity Enrollment ──────────────────────────────────────

class ActivityEnrollment {
  final int id;
  final int childId;
  final String activityName;
  final String category; // sports, arts, academic, religious, other
  final String? schedule;
  final double feeAmount;
  final String? feeFrequency; // monthly, termly, yearly
  final DateTime? startDate;
  final DateTime? endDate;

  ActivityEnrollment({
    required this.id,
    required this.childId,
    required this.activityName,
    required this.category,
    this.schedule,
    this.feeAmount = 0,
    this.feeFrequency,
    this.startDate,
    this.endDate,
  });

  factory ActivityEnrollment.fromJson(Map<String, dynamic> json) {
    return ActivityEnrollment(
      id: _parseInt(json['id']),
      childId: _parseInt(json['child_id']),
      activityName: json['activity_name'] as String? ?? '',
      category: json['category'] as String? ?? 'other',
      schedule: json['schedule'] as String?,
      feeAmount: _parseDouble(json['fee_amount']),
      feeFrequency: json['fee_frequency'] as String?,
      startDate: _parseDate(json['start_date']),
      endDate: _parseDate(json['end_date']),
    );
  }

  Map<String, dynamic> toJson() => {
        'child_id': childId,
        'activity_name': activityName,
        'category': category,
        if (schedule != null) 'schedule': schedule,
        'fee_amount': feeAmount,
        if (feeFrequency != null) 'fee_frequency': feeFrequency,
        if (startDate != null) 'start_date': startDate!.toIso8601String(),
        if (endDate != null) 'end_date': endDate!.toIso8601String(),
      };

  String get categoryLabel {
    switch (category) {
      case 'sports':
        return 'Sports';
      case 'arts':
        return 'Arts';
      case 'academic':
        return 'Academic';
      case 'religious':
        return 'Religious';
      default:
        return 'Other';
    }
  }

  String categoryLabelLocalized({bool isSwahili = true}) {
    if (!isSwahili) return categoryLabel;
    switch (category) {
      case 'sports':
        return 'Michezo';
      case 'arts':
        return 'Sanaa';
      case 'academic':
        return 'Elimu';
      case 'religious':
        return 'Dini';
      default:
        return 'Nyingine';
    }
  }
}

// ─── Reading Log Entry ────────────────────────────────────────

class ReadingLogEntry {
  final int id;
  final int childId;
  final String bookTitle;
  final String? author;
  final int pagesRead;
  final int? totalPages;
  final DateTime? startDate;
  final DateTime? finishDate;
  final int? rating;
  final String? notes;

  ReadingLogEntry({
    required this.id,
    required this.childId,
    required this.bookTitle,
    this.author,
    required this.pagesRead,
    this.totalPages,
    this.startDate,
    this.finishDate,
    this.rating,
    this.notes,
  });

  factory ReadingLogEntry.fromJson(Map<String, dynamic> json) {
    return ReadingLogEntry(
      id: _parseInt(json['id']),
      childId: _parseInt(json['child_id']),
      bookTitle: json['book_title'] as String? ?? '',
      author: json['author'] as String?,
      pagesRead: _parseInt(json['pages_read']),
      totalPages:
          json['total_pages'] != null ? _parseInt(json['total_pages']) : null,
      startDate: _parseDate(json['start_date']),
      finishDate: _parseDate(json['finish_date']),
      rating: json['rating'] != null ? _parseInt(json['rating']) : null,
      notes: json['notes'] as String?,
    );
  }

  Map<String, dynamic> toJson() => {
        'child_id': childId,
        'book_title': bookTitle,
        if (author != null) 'author': author,
        'pages_read': pagesRead,
        if (totalPages != null) 'total_pages': totalPages,
        if (startDate != null) 'start_date': startDate!.toIso8601String(),
        if (finishDate != null) 'finish_date': finishDate!.toIso8601String(),
        if (rating != null) 'rating': rating,
        if (notes != null) 'notes': notes,
      };

  double get progress {
    if (totalPages == null || totalPages == 0) return 0;
    return (pagesRead / totalPages!).clamp(0.0, 1.0);
  }

  bool get isCompleted => finishDate != null;
}

// ─── Allowance Balance ────────────────────────────────────────

class AllowanceBalance {
  final double totalEarned;
  final double totalSpent;
  final double totalSaved;
  final double balance;

  AllowanceBalance({
    required this.totalEarned,
    required this.totalSpent,
    required this.totalSaved,
    required this.balance,
  });

  factory AllowanceBalance.fromJson(Map<String, dynamic> json) {
    return AllowanceBalance(
      totalEarned: _parseDouble(json['total_earned']),
      totalSpent: _parseDouble(json['total_spent']),
      totalSaved: _parseDouble(json['total_saved']),
      balance: _parseDouble(json['balance']),
    );
  }
}

// ─── Parsing Helpers ──────────────────────────────────────────

int _parseInt(dynamic v, {int fallback = 0}) {
  if (v == null) return fallback;
  if (v is int) return v;
  if (v is double) return v.toInt();
  if (v is String) return int.tryParse(v) ?? fallback;
  return fallback;
}

double _parseDouble(dynamic v, {double fallback = 0}) {
  if (v == null) return fallback;
  if (v is double) return v;
  if (v is int) return v.toDouble();
  if (v is String) return double.tryParse(v) ?? fallback;
  return fallback;
}

bool _parseBool(dynamic v, {bool fallback = false}) {
  if (v == null) return fallback;
  if (v is bool) return v;
  if (v is int) return v == 1;
  if (v is String) return v == '1' || v == 'true';
  return fallback;
}

DateTime? _parseDate(dynamic v) {
  if (v == null) return null;
  if (v is DateTime) return v;
  if (v is String) return DateTime.tryParse(v);
  return null;
}
