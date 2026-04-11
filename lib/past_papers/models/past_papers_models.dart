// lib/past_papers/models/past_papers_models.dart

// ─── Education Level ─────────────────────────────────────────

enum EducationLevel {
  primary,
  formFour,
  formSix,
  diploma,
  degree,
  masters;

  String get displayName {
    switch (this) {
      case EducationLevel.primary:
        return 'Msingi (PSLE)';
      case EducationLevel.formFour:
        return 'Kidato 4 (CSEE)';
      case EducationLevel.formSix:
        return 'Kidato 6 (ACSEE)';
      case EducationLevel.diploma:
        return 'Diploma';
      case EducationLevel.degree:
        return 'Shahada';
      case EducationLevel.masters:
        return 'Uzamili';
    }
  }

  static EducationLevel fromString(String? s) {
    return EducationLevel.values.firstWhere(
      (v) => v.name == s,
      orElse: () => EducationLevel.degree,
    );
  }
}

// ─── Exam Type ───────────────────────────────────────────────

enum ExamType {
  midSemester,
  endSemester,
  supplementary,
  necta,
  mock;

  String get displayName {
    switch (this) {
      case ExamType.midSemester:
        return 'Katikati Muhula';
      case ExamType.endSemester:
        return 'Mwisho Muhula';
      case ExamType.supplementary:
        return 'Supplementary';
      case ExamType.necta:
        return 'NECTA';
      case ExamType.mock:
        return 'Mock';
    }
  }

  static ExamType fromString(String? s) {
    return ExamType.values.firstWhere(
      (v) => v.name == s,
      orElse: () => ExamType.endSemester,
    );
  }
}

// ─── PastPaper ───────────────────────────────────────────────

class PastPaper {
  final int id;
  final String subject;
  final String? courseCode;
  final int year;
  final EducationLevel level;
  final ExamType examType;
  final String? institution;
  final String fileUrl;
  final int fileSize;
  final String? markingSchemeUrl;
  final int downloadCount;
  final int viewCount;
  final double difficultyRating;
  final int ratingCount;
  final int uploaderId;
  final String uploaderName;
  final bool isVerified;
  final bool isBookmarked;
  final DateTime createdAt;

  PastPaper({
    required this.id,
    required this.subject,
    this.courseCode,
    required this.year,
    required this.level,
    required this.examType,
    this.institution,
    required this.fileUrl,
    this.fileSize = 0,
    this.markingSchemeUrl,
    this.downloadCount = 0,
    this.viewCount = 0,
    this.difficultyRating = 0,
    this.ratingCount = 0,
    required this.uploaderId,
    required this.uploaderName,
    this.isVerified = false,
    this.isBookmarked = false,
    required this.createdAt,
  });

  factory PastPaper.fromJson(Map<String, dynamic> json) {
    return PastPaper(
      id: _parseInt(json['id']),
      subject: json['subject']?.toString() ?? '',
      courseCode: json['course_code']?.toString(),
      year: _parseInt(json['year']),
      level: EducationLevel.fromString(json['level']?.toString()),
      examType: ExamType.fromString(json['exam_type']?.toString()),
      institution: json['institution']?.toString(),
      fileUrl: json['file_url']?.toString() ?? '',
      fileSize: _parseInt(json['file_size']),
      markingSchemeUrl: json['marking_scheme_url']?.toString(),
      downloadCount: _parseInt(json['download_count']),
      viewCount: _parseInt(json['view_count']),
      difficultyRating: _parseDouble(json['difficulty_rating']) ?? 0,
      ratingCount: _parseInt(json['rating_count']),
      uploaderId: _parseInt(json['uploader_id']),
      uploaderName: json['uploader_name']?.toString() ?? '',
      isVerified: _parseBool(json['is_verified']),
      isBookmarked: _parseBool(json['is_bookmarked']),
      createdAt: DateTime.tryParse(json['created_at']?.toString() ?? '') ??
          DateTime.now(),
    );
  }

  String get fileSizeFormatted {
    if (fileSize < 1024) return '$fileSize B';
    if (fileSize < 1024 * 1024) {
      return '${(fileSize / 1024).toStringAsFixed(1)} KB';
    }
    return '${(fileSize / (1024 * 1024)).toStringAsFixed(1)} MB';
  }
}

// ─── PaperRequest ────────────────────────────────────────────

class PaperRequest {
  final int id;
  final String subject;
  final int year;
  final EducationLevel level;
  final String? institution;
  final int requesterId;
  final String requesterName;
  final bool isFulfilled;
  final DateTime createdAt;

  PaperRequest({
    required this.id,
    required this.subject,
    required this.year,
    required this.level,
    this.institution,
    required this.requesterId,
    required this.requesterName,
    this.isFulfilled = false,
    required this.createdAt,
  });

  factory PaperRequest.fromJson(Map<String, dynamic> json) {
    return PaperRequest(
      id: _parseInt(json['id']),
      subject: json['subject']?.toString() ?? '',
      year: _parseInt(json['year']),
      level: EducationLevel.fromString(json['level']?.toString()),
      institution: json['institution']?.toString(),
      requesterId: _parseInt(json['requester_id']),
      requesterName: json['requester_name']?.toString() ?? '',
      isFulfilled: _parseBool(json['is_fulfilled']),
      createdAt: DateTime.tryParse(json['created_at']?.toString() ?? '') ??
          DateTime.now(),
    );
  }
}

// ─── Result wrappers ─────────────────────────────────────────

class PapersResult<T> {
  final bool success;
  final T? data;
  final String? message;

  PapersResult({required this.success, this.data, this.message});
}

class PapersListResult<T> {
  final bool success;
  final List<T> items;
  final String? message;

  PapersListResult({
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
