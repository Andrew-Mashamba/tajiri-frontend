// lib/results/models/results_models.dart

// ─── Grading Scale ───────────────────────────────────────────

enum GradingScale {
  tanzanian5, // A=5, B+=4, B=3, C=2, D=1, E=0
  international4, // A=4, B=3, C=2, D=1, F=0
  percentage;

  String get displayName {
    switch (this) {
      case GradingScale.tanzanian5:
        return 'Tanzania (5.0)';
      case GradingScale.international4:
        return 'International (4.0)';
      case GradingScale.percentage:
        return 'Asilimia (%)';
    }
  }

  static GradingScale fromString(String? s) {
    return GradingScale.values.firstWhere(
      (v) => v.name == s,
      orElse: () => GradingScale.tanzanian5,
    );
  }
}

// ─── CourseGrade ──────────────────────────────────────────────

class CourseGrade {
  final int id;
  final String courseName;
  final String courseCode;
  final String grade;
  final double gradePoint;
  final int creditHours;
  final int semesterId;
  final String semester;
  final int year;
  final bool isSupplementary;
  final double? caScore;
  final double? examScore;
  final DateTime? gradedAt;

  CourseGrade({
    required this.id,
    required this.courseName,
    required this.courseCode,
    required this.grade,
    required this.gradePoint,
    required this.creditHours,
    required this.semesterId,
    required this.semester,
    required this.year,
    this.isSupplementary = false,
    this.caScore,
    this.examScore,
    this.gradedAt,
  });

  factory CourseGrade.fromJson(Map<String, dynamic> json) {
    return CourseGrade(
      id: _parseInt(json['id']),
      courseName: json['course_name']?.toString() ?? '',
      courseCode: json['course_code']?.toString() ?? '',
      grade: json['grade']?.toString() ?? '',
      gradePoint: _parseDouble(json['grade_point']) ?? 0,
      creditHours: _parseInt(json['credit_hours']),
      semesterId: _parseInt(json['semester_id']),
      semester: json['semester']?.toString() ?? '',
      year: _parseInt(json['year']),
      isSupplementary: _parseBool(json['is_supplementary']),
      caScore: _parseDouble(json['ca_score']),
      examScore: _parseDouble(json['exam_score']),
      gradedAt: DateTime.tryParse(json['graded_at']?.toString() ?? ''),
    );
  }
}

// ─── SemesterResult ──────────────────────────────────────────

class SemesterResult {
  final int id;
  final String semester;
  final int year;
  final double gpa;
  final int totalCredits;
  final int totalCourses;
  final List<CourseGrade> courses;

  SemesterResult({
    required this.id,
    required this.semester,
    required this.year,
    required this.gpa,
    required this.totalCredits,
    required this.totalCourses,
    this.courses = const [],
  });

  factory SemesterResult.fromJson(Map<String, dynamic> json) {
    return SemesterResult(
      id: _parseInt(json['id']),
      semester: json['semester']?.toString() ?? '',
      year: _parseInt(json['year']),
      gpa: _parseDouble(json['gpa']) ?? 0,
      totalCredits: _parseInt(json['total_credits']),
      totalCourses: _parseInt(json['total_courses']),
      courses: (json['courses'] as List?)
              ?.map((c) => CourseGrade.fromJson(c))
              .toList() ??
          [],
    );
  }
}

// ─── NectaResult ─────────────────────────────────────────────

class NectaResult {
  final String examNumber;
  final String examType; // CSEE / ACSEE
  final int year;
  final String division;
  final int points;
  final Map<String, String> subjects; // {subject: grade}

  NectaResult({
    required this.examNumber,
    required this.examType,
    required this.year,
    required this.division,
    required this.points,
    this.subjects = const {},
  });

  factory NectaResult.fromJson(Map<String, dynamic> json) {
    final subjMap = <String, String>{};
    if (json['subjects'] is Map) {
      (json['subjects'] as Map).forEach((k, v) {
        subjMap[k.toString()] = v.toString();
      });
    }
    return NectaResult(
      examNumber: json['exam_number']?.toString() ?? '',
      examType: json['exam_type']?.toString() ?? '',
      year: _parseInt(json['year']),
      division: json['division']?.toString() ?? '',
      points: _parseInt(json['points']),
      subjects: subjMap,
    );
  }
}

// ─── GPA Summary ─────────────────────────────────────────────

class GpaSummary {
  final double cumulativeGpa;
  final int totalCreditsEarned;
  final int totalCreditsRequired;
  final int semestersCompleted;
  final bool isDeansList;

  GpaSummary({
    required this.cumulativeGpa,
    required this.totalCreditsEarned,
    required this.totalCreditsRequired,
    required this.semestersCompleted,
    this.isDeansList = false,
  });

  factory GpaSummary.fromJson(Map<String, dynamic> json) {
    return GpaSummary(
      cumulativeGpa: _parseDouble(json['cumulative_gpa']) ?? 0,
      totalCreditsEarned: _parseInt(json['total_credits_earned']),
      totalCreditsRequired: _parseInt(json['total_credits_required']),
      semestersCompleted: _parseInt(json['semesters_completed']),
      isDeansList: _parseBool(json['is_deans_list']),
    );
  }

  double get progressPercent => totalCreditsRequired > 0
      ? totalCreditsEarned / totalCreditsRequired
      : 0;
}

// ─── Result wrappers ─────────────────────────────────────────

class ResultsDataResult<T> {
  final bool success;
  final T? data;
  final String? message;

  ResultsDataResult({required this.success, this.data, this.message});
}

class ResultsListResult<T> {
  final bool success;
  final List<T> items;
  final String? message;

  ResultsListResult({
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
