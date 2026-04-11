// lib/alerts/models/alerts_models.dart

int _parseInt(dynamic v) => (v is num) ? v.toInt() : int.tryParse('$v') ?? 0;
double _parseDouble(dynamic v) =>
    (v is num) ? v.toDouble() : double.tryParse('$v') ?? 0.0;
bool _parseBool(dynamic v) =>
    v == true || v == 1 || v == '1' || v == 'true';

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

// ─── Emergency Alert ──────────────────────────────────────────

class EmergencyAlert {
  final int id;
  final String type; // weather, flood, earthquake, fire, tsunami, other
  final String title;
  final String description;
  final String severity; // advisory, watch, warning, emergency
  final String? region;
  final DateTime issuedAt;
  final DateTime? expiresAt;
  final bool isActive;
  final String? instructions;

  EmergencyAlert({
    required this.id,
    required this.type,
    required this.title,
    required this.description,
    required this.severity,
    this.region,
    required this.issuedAt,
    this.expiresAt,
    required this.isActive,
    this.instructions,
  });

  factory EmergencyAlert.fromJson(Map<String, dynamic> json) {
    return EmergencyAlert(
      id: _parseInt(json['id']),
      type: json['type'] ?? 'other',
      title: json['title'] ?? '',
      description: json['description'] ?? '',
      severity: json['severity'] ?? 'advisory',
      region: json['region'],
      issuedAt: DateTime.tryParse('${json['issued_at']}') ?? DateTime.now(),
      expiresAt: json['expires_at'] != null
          ? DateTime.tryParse('${json['expires_at']}')
          : null,
      isActive: _parseBool(json['is_active']),
      instructions: json['instructions'],
    );
  }
}

// ─── Family Check-in ─────────────────────────────────────────

class FamilyCheckIn {
  final int id;
  final int userId;
  final String userName;
  final String status; // safe, need_help, no_response
  final String? message;
  final double? lat;
  final double? lng;
  final DateTime checkedAt;

  FamilyCheckIn({
    required this.id,
    required this.userId,
    required this.userName,
    required this.status,
    this.message,
    this.lat,
    this.lng,
    required this.checkedAt,
  });

  factory FamilyCheckIn.fromJson(Map<String, dynamic> json) {
    return FamilyCheckIn(
      id: _parseInt(json['id']),
      userId: _parseInt(json['user_id']),
      userName: json['user_name'] ?? '',
      status: json['status'] ?? 'no_response',
      message: json['message'],
      lat: json['lat'] != null ? _parseDouble(json['lat']) : null,
      lng: json['lng'] != null ? _parseDouble(json['lng']) : null,
      checkedAt: DateTime.tryParse('${json['checked_at']}') ?? DateTime.now(),
    );
  }
}
