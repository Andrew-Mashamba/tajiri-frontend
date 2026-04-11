// lib/kalenda_hijri/models/kalenda_hijri_models.dart

// ─── Hijri Date ───────────────────────────────────────────────
class HijriDate {
  final int day;
  final int month;
  final int year;
  final String monthName;
  final String monthNameSwahili;
  final String gregorianDate;
  final double moonPhase; // 0.0 - 1.0

  HijriDate({
    required this.day,
    required this.month,
    required this.year,
    required this.monthName,
    required this.monthNameSwahili,
    required this.gregorianDate,
    this.moonPhase = 0,
  });

  factory HijriDate.fromJson(Map<String, dynamic> json) {
    return HijriDate(
      day: _parseInt(json['day']),
      month: _parseInt(json['month']),
      year: _parseInt(json['year']),
      monthName: json['month_name']?.toString() ?? '',
      monthNameSwahili: json['month_name_sw']?.toString() ?? '',
      gregorianDate: json['gregorian_date']?.toString() ?? '',
      moonPhase: _parseDouble(json['moon_phase']),
    );
  }

  String get formatted => '$day $monthName $year AH';
  String get formattedSw => '$day $monthNameSwahili $year AH';
}

// ─── Islamic Event ────────────────────────────────────────────
class IslamicEvent {
  final int id;
  final String name;
  final String nameSwahili;
  final String description;
  final String descriptionSwahili;
  final HijriDate hijriDate;
  final String? gregorianDate;
  final String significance;
  final List<String> recommendedPractices;
  final bool isPublicHoliday;

  IslamicEvent({
    required this.id,
    required this.name,
    required this.nameSwahili,
    required this.description,
    required this.descriptionSwahili,
    required this.hijriDate,
    this.gregorianDate,
    required this.significance,
    this.recommendedPractices = const [],
    this.isPublicHoliday = false,
  });

  factory IslamicEvent.fromJson(Map<String, dynamic> json) {
    return IslamicEvent(
      id: _parseInt(json['id']),
      name: json['name']?.toString() ?? '',
      nameSwahili: json['name_sw']?.toString() ?? '',
      description: json['description']?.toString() ?? '',
      descriptionSwahili: json['description_sw']?.toString() ?? '',
      hijriDate: json['hijri_date'] != null
          ? HijriDate.fromJson(json['hijri_date'])
          : HijriDate(
              day: 0, month: 0, year: 0,
              monthName: '', monthNameSwahili: '',
              gregorianDate: '',
            ),
      gregorianDate: json['gregorian_date']?.toString(),
      significance: json['significance']?.toString() ?? '',
      recommendedPractices: (json['recommended_practices'] as List?)
              ?.map((e) => e.toString())
              .toList() ??
          [],
      isPublicHoliday: _parseBool(json['is_public_holiday']),
    );
  }
}

// ─── Moon Sighting Report ─────────────────────────────────────
class MoonSightingReport {
  final int id;
  final String location;
  final String reporterName;
  final String status; // confirmed, pending, rejected
  final String hijriMonth;
  final DateTime reportedAt;
  final bool isOfficial;

  MoonSightingReport({
    required this.id,
    required this.location,
    required this.reporterName,
    required this.status,
    required this.hijriMonth,
    required this.reportedAt,
    this.isOfficial = false,
  });

  factory MoonSightingReport.fromJson(Map<String, dynamic> json) {
    return MoonSightingReport(
      id: _parseInt(json['id']),
      location: json['location']?.toString() ?? '',
      reporterName: json['reporter_name']?.toString() ?? '',
      status: json['status']?.toString() ?? 'pending',
      hijriMonth: json['hijri_month']?.toString() ?? '',
      reportedAt: DateTime.tryParse(json['reported_at']?.toString() ?? '') ??
          DateTime.now(),
      isOfficial: _parseBool(json['is_official']),
    );
  }
}

// ─── Result Wrappers ──────────────────────────────────────────
class SingleResult<T> {
  final bool success;
  final T? data;
  final String? message;
  SingleResult({required this.success, this.data, this.message});
}

class PaginatedResult<T> {
  final bool success;
  final List<T> items;
  final int currentPage;
  final int lastPage;
  final int total;
  final String? message;
  PaginatedResult({
    required this.success,
    this.items = const [],
    this.currentPage = 1,
    this.lastPage = 1,
    this.total = 0,
    this.message,
  });
}

// ─── Parse Helpers ────────────────────────────────────────────
int _parseInt(dynamic v) {
  if (v is int) return v;
  if (v is double) return v.toInt();
  if (v is String) return int.tryParse(v) ?? 0;
  return 0;
}

double _parseDouble(dynamic v) {
  if (v is double) return v;
  if (v is int) return v.toDouble();
  if (v is String) return double.tryParse(v) ?? 0.0;
  return 0.0;
}

bool _parseBool(dynamic v) {
  if (v is bool) return v;
  if (v is int) return v == 1;
  if (v is String) return v == '1' || v.toLowerCase() == 'true';
  return false;
}
