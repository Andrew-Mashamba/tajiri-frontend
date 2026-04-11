// lib/timetable/models/timetable_models.dart

// ─── Day of Week ─────────────────────────────────────────────

enum SchoolDay {
  monday,
  tuesday,
  wednesday,
  thursday,
  friday,
  saturday;

  String get displayName {
    switch (this) {
      case SchoolDay.monday:
        return 'Jumatatu';
      case SchoolDay.tuesday:
        return 'Jumanne';
      case SchoolDay.wednesday:
        return 'Jumatano';
      case SchoolDay.thursday:
        return 'Alhamisi';
      case SchoolDay.friday:
        return 'Ijumaa';
      case SchoolDay.saturday:
        return 'Jumamosi';
    }
  }

  String get shortName {
    switch (this) {
      case SchoolDay.monday:
        return 'Jtt';
      case SchoolDay.tuesday:
        return 'Jnn';
      case SchoolDay.wednesday:
        return 'Jtn';
      case SchoolDay.thursday:
        return 'Alh';
      case SchoolDay.friday:
        return 'Ijm';
      case SchoolDay.saturday:
        return 'Jms';
    }
  }

  static SchoolDay fromIndex(int index) {
    return SchoolDay.values[index.clamp(0, 5)];
  }

  static SchoolDay fromString(String? s) {
    return SchoolDay.values.firstWhere(
      (v) => v.name == s,
      orElse: () => SchoolDay.monday,
    );
  }
}

// ─── Semester ────────────────────────────────────────────────

class Semester {
  final int id;
  final String name;
  final int year;
  final bool isActive;
  final DateTime startDate;
  final DateTime endDate;

  Semester({
    required this.id,
    required this.name,
    required this.year,
    this.isActive = false,
    required this.startDate,
    required this.endDate,
  });

  factory Semester.fromJson(Map<String, dynamic> json) {
    return Semester(
      id: _parseInt(json['id']),
      name: json['name']?.toString() ?? '',
      year: _parseInt(json['year']),
      isActive: _parseBool(json['is_active']),
      startDate: DateTime.tryParse(json['start_date']?.toString() ?? '') ??
          DateTime.now(),
      endDate: DateTime.tryParse(json['end_date']?.toString() ?? '') ??
          DateTime.now(),
    );
  }
}

// ─── TimetableEntry ──────────────────────────────────────────

class TimetableEntry {
  final int id;
  final String subject;
  final String courseCode;
  final String lecturer;
  final String room;
  final String? building;
  final SchoolDay day;
  final String startTime; // "08:00"
  final String endTime;   // "10:00"
  final int colorValue;
  final int? classId;
  final int? semesterId;
  final bool isExam;

  TimetableEntry({
    required this.id,
    required this.subject,
    required this.courseCode,
    required this.lecturer,
    required this.room,
    this.building,
    required this.day,
    required this.startTime,
    required this.endTime,
    this.colorValue = 0xFF1A1A1A,
    this.classId,
    this.semesterId,
    this.isExam = false,
  });

  factory TimetableEntry.fromJson(Map<String, dynamic> json) {
    return TimetableEntry(
      id: _parseInt(json['id']),
      subject: json['subject']?.toString() ?? '',
      courseCode: json['course_code']?.toString() ?? '',
      lecturer: json['lecturer']?.toString() ?? '',
      room: json['room']?.toString() ?? '',
      building: json['building']?.toString(),
      day: SchoolDay.fromString(json['day']?.toString()),
      startTime: json['start_time']?.toString() ?? '08:00',
      endTime: json['end_time']?.toString() ?? '10:00',
      colorValue: _parseInt(json['color_value']),
      classId: json['class_id'] != null ? _parseInt(json['class_id']) : null,
      semesterId:
          json['semester_id'] != null ? _parseInt(json['semester_id']) : null,
      isExam: _parseBool(json['is_exam']),
    );
  }

  /// Returns a Duration from start to end.
  Duration get duration {
    final s = _parseTime(startTime);
    final e = _parseTime(endTime);
    return e.difference(s);
  }

  static DateTime _parseTime(String t) {
    final parts = t.split(':');
    return DateTime(2000, 1, 1, int.tryParse(parts[0]) ?? 0,
        parts.length > 1 ? int.tryParse(parts[1]) ?? 0 : 0);
  }
}

// ─── Result wrappers ─────────────────────────────────────────

class TimetableResult<T> {
  final bool success;
  final T? data;
  final String? message;

  TimetableResult({required this.success, this.data, this.message});
}

class TimetableListResult<T> {
  final bool success;
  final List<T> items;
  final String? message;

  TimetableListResult({
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

bool _parseBool(dynamic v) {
  if (v is bool) return v;
  if (v is int) return v != 0;
  if (v is String) return v == '1' || v.toLowerCase() == 'true';
  return false;
}
