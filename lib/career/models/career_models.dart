// lib/career/models/career_models.dart

// ─── Job Type ────────────────────────────────────────────────

enum JobType {
  internship,
  partTime,
  fullTime,
  attachment,
  volunteer;

  String get displayName {
    switch (this) {
      case JobType.internship:
        return 'Mafunzo Kazini';
      case JobType.partTime:
        return 'Nusu Muda';
      case JobType.fullTime:
        return 'Muda Wote';
      case JobType.attachment:
        return 'Practical';
      case JobType.volunteer:
        return 'Kujitolea';
    }
  }

  static JobType fromString(String? s) {
    return JobType.values.firstWhere(
      (v) => v.name == s,
      orElse: () => JobType.fullTime,
    );
  }
}

// ─── Application Status ──────────────────────────────────────

enum ApplicationStatus {
  applied,
  underReview,
  interview,
  offer,
  rejected,
  withdrawn;

  String get displayName {
    switch (this) {
      case ApplicationStatus.applied:
        return 'Imewasilishwa';
      case ApplicationStatus.underReview:
        return 'Inakaguliwa';
      case ApplicationStatus.interview:
        return 'Mahojiano';
      case ApplicationStatus.offer:
        return 'Kupokea Kazi';
      case ApplicationStatus.rejected:
        return 'Imekataliwa';
      case ApplicationStatus.withdrawn:
        return 'Imeondolewa';
    }
  }

  int get colorValue {
    switch (this) {
      case ApplicationStatus.applied:
        return 0xFF2196F3;
      case ApplicationStatus.underReview:
        return 0xFFFFC107;
      case ApplicationStatus.interview:
        return 0xFF9C27B0;
      case ApplicationStatus.offer:
        return 0xFF4CAF50;
      case ApplicationStatus.rejected:
        return 0xFFF44336;
      case ApplicationStatus.withdrawn:
        return 0xFF9E9E9E;
    }
  }

  static ApplicationStatus fromString(String? s) {
    return ApplicationStatus.values.firstWhere(
      (v) => v.name == s,
      orElse: () => ApplicationStatus.applied,
    );
  }
}

// ─── JobListing ──────────────────────────────────────────────

class JobListing {
  final int id;
  final String title;
  final String company;
  final String? companyLogo;
  final String location;
  final JobType type;
  final String? salary;
  final String description;
  final List<String> requirements;
  final String? industry;
  final DateTime deadline;
  final bool isSaved;
  final bool hasApplied;
  final DateTime postedAt;

  JobListing({
    required this.id,
    required this.title,
    required this.company,
    this.companyLogo,
    required this.location,
    required this.type,
    this.salary,
    required this.description,
    this.requirements = const [],
    this.industry,
    required this.deadline,
    this.isSaved = false,
    this.hasApplied = false,
    required this.postedAt,
  });

  factory JobListing.fromJson(Map<String, dynamic> json) {
    return JobListing(
      id: _parseInt(json['id']),
      title: json['title']?.toString() ?? '',
      company: json['company']?.toString() ?? '',
      companyLogo: json['company_logo']?.toString(),
      location: json['location']?.toString() ?? '',
      type: JobType.fromString(json['type']?.toString()),
      salary: json['salary']?.toString(),
      description: json['description']?.toString() ?? '',
      requirements: _parseStringList(json['requirements']),
      industry: json['industry']?.toString(),
      deadline: DateTime.tryParse(json['deadline']?.toString() ?? '') ??
          DateTime.now(),
      isSaved: _parseBool(json['is_saved']),
      hasApplied: _parseBool(json['has_applied']),
      postedAt: DateTime.tryParse(json['posted_at']?.toString() ?? '') ??
          DateTime.now(),
    );
  }

  bool get isExpired => DateTime.now().isAfter(deadline);

  String get daysUntilDeadline {
    final diff = deadline.difference(DateTime.now()).inDays;
    if (diff < 0) return 'Imepita';
    if (diff == 0) return 'Leo';
    return 'Siku $diff';
  }
}

// ─── JobApplication ──────────────────────────────────────────

class JobApplication {
  final int id;
  final int jobId;
  final String jobTitle;
  final String company;
  final ApplicationStatus status;
  final DateTime appliedAt;
  final DateTime? updatedAt;

  JobApplication({
    required this.id,
    required this.jobId,
    required this.jobTitle,
    required this.company,
    required this.status,
    required this.appliedAt,
    this.updatedAt,
  });

  factory JobApplication.fromJson(Map<String, dynamic> json) {
    return JobApplication(
      id: _parseInt(json['id']),
      jobId: _parseInt(json['job_id']),
      jobTitle: json['job_title']?.toString() ?? '',
      company: json['company']?.toString() ?? '',
      status: ApplicationStatus.fromString(json['status']?.toString()),
      appliedAt: DateTime.tryParse(json['applied_at']?.toString() ?? '') ??
          DateTime.now(),
      updatedAt: DateTime.tryParse(json['updated_at']?.toString() ?? ''),
    );
  }
}

// ─── CVSection ───────────────────────────────────────────────

class CVSection {
  final String type; // personal, education, experience, skills, references
  final Map<String, String> fields;

  CVSection({required this.type, this.fields = const {}});

  factory CVSection.fromJson(Map<String, dynamic> json) {
    final fieldMap = <String, String>{};
    if (json['fields'] is Map) {
      (json['fields'] as Map).forEach((k, v) {
        fieldMap[k.toString()] = v.toString();
      });
    }
    return CVSection(
      type: json['type']?.toString() ?? '',
      fields: fieldMap,
    );
  }
}

// ─── CompanyProfile ──────────────────────────────────────────

class CompanyProfile {
  final int id;
  final String name;
  final String? logoUrl;
  final String? industry;
  final String? description;
  final String? website;
  final String? location;
  final int openPositions;

  CompanyProfile({
    required this.id,
    required this.name,
    this.logoUrl,
    this.industry,
    this.description,
    this.website,
    this.location,
    this.openPositions = 0,
  });

  factory CompanyProfile.fromJson(Map<String, dynamic> json) {
    return CompanyProfile(
      id: _parseInt(json['id']),
      name: json['name']?.toString() ?? '',
      logoUrl: json['logo_url']?.toString(),
      industry: json['industry']?.toString(),
      description: json['description']?.toString(),
      website: json['website']?.toString(),
      location: json['location']?.toString(),
      openPositions: _parseInt(json['open_positions']),
    );
  }
}

// ─── Result wrappers ─────────────────────────────────────────

class CareerResult<T> {
  final bool success;
  final T? data;
  final String? message;

  CareerResult({required this.success, this.data, this.message});
}

class CareerListResult<T> {
  final bool success;
  final List<T> items;
  final String? message;

  CareerListResult({
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

List<String> _parseStringList(dynamic v) {
  if (v is List) return v.map((e) => e.toString()).toList();
  return [];
}
