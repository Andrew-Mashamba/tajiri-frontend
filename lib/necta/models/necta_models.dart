// lib/necta/models/necta_models.dart

int _parseInt(dynamic v) => (v is num) ? v.toInt() : int.tryParse('$v') ?? 0;
double _parseDouble(dynamic v) =>
    (v is num) ? v.toDouble() : double.tryParse('$v') ?? 0.0;

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

// ─── Exam Result ──────────────────────────────────────────────

class ExamResult {
  final int id;
  final String candidateNumber;
  final String candidateName;
  final String examType; // csee, acsee, ftna, psle
  final int year;
  final String? schoolName;
  final String? division;
  final double? points;
  final List<SubjectResult> subjects;

  ExamResult({
    required this.id,
    required this.candidateNumber,
    required this.candidateName,
    required this.examType,
    required this.year,
    this.schoolName,
    this.division,
    this.points,
    this.subjects = const [],
  });

  factory ExamResult.fromJson(Map<String, dynamic> json) {
    return ExamResult(
      id: _parseInt(json['id']),
      candidateNumber: json['candidate_number'] ?? '',
      candidateName: json['candidate_name'] ?? '',
      examType: json['exam_type'] ?? 'csee',
      year: _parseInt(json['year']),
      schoolName: json['school_name'],
      division: json['division'],
      points:
          json['points'] != null ? _parseDouble(json['points']) : null,
      subjects: (json['subjects'] as List?)
              ?.map((j) => SubjectResult.fromJson(j))
              .toList() ??
          [],
    );
  }
}

class SubjectResult {
  final String subject;
  final String grade;

  SubjectResult({required this.subject, required this.grade});

  factory SubjectResult.fromJson(Map<String, dynamic> json) {
    return SubjectResult(
      subject: json['subject'] ?? '',
      grade: json['grade'] ?? '',
    );
  }
}

// ─── Past Paper ───────────────────────────────────────────────

class PastPaper {
  final int id;
  final String examType;
  final String subject;
  final int year;
  final String? fileUrl;
  final int downloads;

  PastPaper({
    required this.id,
    required this.examType,
    required this.subject,
    required this.year,
    this.fileUrl,
    required this.downloads,
  });

  factory PastPaper.fromJson(Map<String, dynamic> json) {
    return PastPaper(
      id: _parseInt(json['id']),
      examType: json['exam_type'] ?? 'csee',
      subject: json['subject'] ?? '',
      year: _parseInt(json['year']),
      fileUrl: json['file_url'],
      downloads: _parseInt(json['downloads']),
    );
  }
}

// ─── School Stats ─────────────────────────────────────────────

class SchoolStats {
  final int id;
  final String name;
  final String region;
  final String district;
  final int totalCandidates;
  final int divisionI;
  final int divisionII;
  final int divisionIII;
  final int divisionIV;
  final int divisionZero;
  final double passRate;
  final int year;

  SchoolStats({
    required this.id,
    required this.name,
    required this.region,
    required this.district,
    required this.totalCandidates,
    required this.divisionI,
    required this.divisionII,
    required this.divisionIII,
    required this.divisionIV,
    required this.divisionZero,
    required this.passRate,
    required this.year,
  });

  factory SchoolStats.fromJson(Map<String, dynamic> json) {
    return SchoolStats(
      id: _parseInt(json['id']),
      name: json['name'] ?? '',
      region: json['region'] ?? '',
      district: json['district'] ?? '',
      totalCandidates: _parseInt(json['total_candidates']),
      divisionI: _parseInt(json['division_i']),
      divisionII: _parseInt(json['division_ii']),
      divisionIII: _parseInt(json['division_iii']),
      divisionIV: _parseInt(json['division_iv']),
      divisionZero: _parseInt(json['division_zero']),
      passRate: _parseDouble(json['pass_rate']),
      year: _parseInt(json['year']),
    );
  }
}
