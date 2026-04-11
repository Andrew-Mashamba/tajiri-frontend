// lib/shule_ya_jumapili/models/shule_ya_jumapili_models.dart

int _parseInt(dynamic v) => (v is num) ? v.toInt() : int.tryParse('$v') ?? 0;
bool _parseBool(dynamic v) =>
    v == true || v == 1 || v == '1' || v == 'true';

// ─── Result wrappers ───────────────────────────────────────────

class SingleResult<T> {
  final bool success;
  final T? data;
  final String? message;
  SingleResult({required this.success, this.data, this.message});
}

class PaginatedResult<T> {
  final bool success;
  final List<T> items;
  final String? message;
  final int currentPage;
  final int lastPage;
  PaginatedResult({
    required this.success,
    this.items = const [],
    this.message,
    this.currentPage = 1,
    this.lastPage = 1,
  });
  bool get hasMore => currentPage < lastPage;
}

// ─── Age Group ────────────────────────────────────────────────

enum AgeGroup {
  young, // 3-6
  older, // 7-12
  teen; // 13-17

  String get label {
    switch (this) {
      case young: return 'Wadogo (3-6) / Young';
      case older: return 'Wakubwa (7-12) / Older';
      case teen: return 'Vijana (13-17) / Teens';
    }
  }
}

// ─── Lesson ───────────────────────────────────────────────────

class SundaySchoolLesson {
  final int id;
  final String title;
  final String? description;
  final String ageGroup;
  final String? scriptureRef;
  final String memoryVerse;
  final String? objective;
  final String? activity;
  final String date;
  final String? seriesName;

  SundaySchoolLesson({
    required this.id,
    required this.title,
    this.description,
    required this.ageGroup,
    this.scriptureRef,
    required this.memoryVerse,
    this.objective,
    this.activity,
    required this.date,
    this.seriesName,
  });

  factory SundaySchoolLesson.fromJson(Map<String, dynamic> json) {
    return SundaySchoolLesson(
      id: _parseInt(json['id']),
      title: json['title']?.toString() ?? '',
      description: json['description']?.toString(),
      ageGroup: json['age_group']?.toString() ?? 'young',
      scriptureRef: json['scripture_ref']?.toString(),
      memoryVerse: json['memory_verse']?.toString() ?? '',
      objective: json['objective']?.toString(),
      activity: json['activity']?.toString(),
      date: json['date']?.toString() ?? '',
      seriesName: json['series_name']?.toString(),
    );
  }
}

// ─── Child Profile ────────────────────────────────────────────

class ChildProfile {
  final int id;
  final String name;
  final String ageGroup;
  final int attendanceCount;
  final int memoryVerseCount;
  final List<String> badges;

  ChildProfile({
    required this.id,
    required this.name,
    required this.ageGroup,
    required this.attendanceCount,
    required this.memoryVerseCount,
    required this.badges,
  });

  factory ChildProfile.fromJson(Map<String, dynamic> json) {
    return ChildProfile(
      id: _parseInt(json['id']),
      name: json['name']?.toString() ?? '',
      ageGroup: json['age_group']?.toString() ?? 'young',
      attendanceCount: _parseInt(json['attendance_count']),
      memoryVerseCount: _parseInt(json['memory_verse_count']),
      badges: (json['badges'] as List?)
              ?.map((e) => e.toString())
              .toList() ??
          [],
    );
  }
}

// ─── Attendance ───────────────────────────────────────────────

class AttendanceRecord {
  final int id;
  final String date;
  final String className;
  final int totalChildren;
  final int presentCount;

  AttendanceRecord({
    required this.id,
    required this.date,
    required this.className,
    required this.totalChildren,
    required this.presentCount,
  });

  factory AttendanceRecord.fromJson(Map<String, dynamic> json) {
    return AttendanceRecord(
      id: _parseInt(json['id']),
      date: json['date']?.toString() ?? '',
      className: json['class_name']?.toString() ?? '',
      totalChildren: _parseInt(json['total_children']),
      presentCount: _parseInt(json['present_count']),
    );
  }
}
