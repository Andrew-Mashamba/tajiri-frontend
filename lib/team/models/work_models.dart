// lib/team/models/work_models.dart

int? _parseInt(dynamic v) {
  if (v == null) return null;
  if (v is int) return v;
  if (v is double) return v.toInt();
  return int.tryParse(v.toString());
}

double _parseDouble(dynamic v, [double fallback = 0.0]) {
  if (v == null) return fallback;
  if (v is double) return v;
  if (v is int) return v.toDouble();
  return double.tryParse(v.toString()) ?? fallback;
}

DateTime? _parseDate(dynamic v) {
  if (v == null) return null;
  if (v is DateTime) return v;
  return DateTime.tryParse(v.toString());
}

class JobDescription {
  final int? id;
  final int employeeId;
  final int businessId;
  final String roleSummary;
  final List<String> responsibilities;
  final String reportingTo;
  final DateTime? updatedAt;

  const JobDescription({
    this.id,
    required this.employeeId,
    required this.businessId,
    required this.roleSummary,
    required this.responsibilities,
    required this.reportingTo,
    this.updatedAt,
  });

  factory JobDescription.fromJson(Map<String, dynamic> json) {
    final raw = json['responsibilities'];
    final List<String> resps = raw is List
        ? raw.map((e) => e.toString()).toList()
        : <String>[];
    return JobDescription(
      id: _parseInt(json['id']),
      employeeId: _parseInt(json['employee_id']) ?? 0,
      businessId: _parseInt(json['business_id']) ?? 0,
      roleSummary: json['role_summary']?.toString() ?? '',
      responsibilities: resps,
      reportingTo: json['reporting_to']?.toString() ?? '',
      updatedAt: _parseDate(json['updated_at']),
    );
  }

  Map<String, dynamic> toJson() => {
        'role_summary': roleSummary,
        'responsibilities': responsibilities,
      };
}

class Kpi {
  final int? id;
  final int employeeId;
  final int businessId;
  final String name;
  final double targetValue;
  final String unit;
  final String reviewPeriod;

  const Kpi({
    this.id,
    required this.employeeId,
    required this.businessId,
    required this.name,
    required this.targetValue,
    required this.unit,
    required this.reviewPeriod,
  });

  factory Kpi.fromJson(Map<String, dynamic> json) => Kpi(
        id: _parseInt(json['id']),
        employeeId: _parseInt(json['employee_id']) ?? 0,
        businessId: _parseInt(json['business_id']) ?? 0,
        name: json['name']?.toString() ?? '',
        targetValue: _parseDouble(json['target_value']),
        unit: json['unit']?.toString() ?? '%',
        reviewPeriod: json['review_period']?.toString() ?? 'monthly',
      );

  Map<String, dynamic> toJson() => {
        'employee_id': employeeId,
        'business_id': businessId,
        'name': name,
        'target_value': targetValue,
        'unit': unit,
        'review_period': reviewPeriod,
      };
}

class KpiEntry {
  final int? id;
  final int kpiId;
  final double actualValue;
  final String periodLabel;
  final DateTime recordedAt;
  final String? note;

  const KpiEntry({
    this.id,
    required this.kpiId,
    required this.actualValue,
    required this.periodLabel,
    required this.recordedAt,
    this.note,
  });

  factory KpiEntry.fromJson(Map<String, dynamic> json) => KpiEntry(
        id: _parseInt(json['id']),
        kpiId: _parseInt(json['kpi_id']) ?? 0,
        actualValue: _parseDouble(json['actual_value']),
        periodLabel: json['period_label']?.toString() ?? '',
        recordedAt: _parseDate(json['recorded_at']) ?? DateTime.now(),
        note: json['note']?.toString(),
      );

  Map<String, dynamic> toJson() => {
        'actual_value': actualValue,
        'period_label': periodLabel,
        if (note != null) 'note': note,
      };
}
