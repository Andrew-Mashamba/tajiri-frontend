class FoodEmergency {
  final int id;
  final String title;
  final String? description;
  final String? region;
  final String? district;
  final String? ward;
  final String severity;
  final bool isActive;
  final DateTime? activatedAt;
  final DateTime? resolvedAt;

  FoodEmergency({
    required this.id,
    required this.title,
    required this.description,
    required this.region,
    required this.district,
    required this.ward,
    required this.severity,
    required this.isActive,
    required this.activatedAt,
    required this.resolvedAt,
  });

  String get scopeLabel {
    if (ward != null) return ward!;
    if (district != null) return district!;
    if (region != null) return region!;
    return 'Nchi nzima';
  }

  factory FoodEmergency.fromJson(Map<String, dynamic> json) {
    return FoodEmergency(
      id: _parseInt(json['id']) ?? 0,
      title: json['title']?.toString() ?? '',
      description: json['description']?.toString(),
      region: json['region']?.toString(),
      district: json['district']?.toString(),
      ward: json['ward']?.toString(),
      severity: json['severity']?.toString() ?? 'normal',
      isActive: _parseBool(json['is_active']),
      activatedAt: _parseDate(json['activated_at']),
      resolvedAt: _parseDate(json['resolved_at']),
    );
  }
}

int? _parseInt(dynamic v) {
  if (v == null) return null;
  if (v is int) return v;
  if (v is num) return v.toInt();
  if (v is String) return int.tryParse(v);
  return null;
}

bool _parseBool(dynamic v) {
  if (v == null) return false;
  if (v is bool) return v;
  if (v is num) return v != 0;
  if (v is String) return v == '1' || v.toLowerCase() == 'true' || v == 't';
  return false;
}

DateTime? _parseDate(dynamic v) {
  if (v == null) return null;
  if (v is DateTime) return v;
  if (v is String) return DateTime.tryParse(v);
  return null;
}
