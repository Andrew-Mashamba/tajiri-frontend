// lib/traffic/models/traffic_models.dart

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

// ─── Traffic Report ───────────────────────────────────────────

class TrafficReport {
  final int id;
  final int userId;
  final String type; // congestion, accident, roadwork, closure, hazard
  final String description;
  final String? location;
  final double? lat;
  final double? lng;
  final String severity; // low, medium, high
  final int upvotes;
  final bool isActive;
  final DateTime createdAt;

  TrafficReport({
    required this.id,
    required this.userId,
    required this.type,
    required this.description,
    this.location,
    this.lat,
    this.lng,
    required this.severity,
    required this.upvotes,
    required this.isActive,
    required this.createdAt,
  });

  factory TrafficReport.fromJson(Map<String, dynamic> json) {
    return TrafficReport(
      id: _parseInt(json['id']),
      userId: _parseInt(json['user_id']),
      type: json['type'] ?? 'congestion',
      description: json['description'] ?? '',
      location: json['location'],
      lat: json['lat'] != null ? _parseDouble(json['lat']) : null,
      lng: json['lng'] != null ? _parseDouble(json['lng']) : null,
      severity: json['severity'] ?? 'medium',
      upvotes: _parseInt(json['upvotes']),
      isActive: _parseBool(json['is_active']),
      createdAt: DateTime.tryParse('${json['created_at']}') ?? DateTime.now(),
    );
  }

  Map<String, dynamic> toJson() => {
        'type': type,
        'description': description,
        if (location != null) 'location': location,
        if (lat != null) 'lat': lat,
        if (lng != null) 'lng': lng,
        'severity': severity,
      };

  String get typeIcon {
    switch (type) {
      case 'accident':
        return '!';
      case 'roadwork':
        return 'W';
      case 'closure':
        return 'X';
      case 'hazard':
        return 'H';
      default:
        return 'C';
    }
  }
}

// ─── Congestion Alert ─────────────────────────────────────────

class CongestionAlert {
  final int id;
  final String roadName;
  final String direction;
  final String level; // light, moderate, heavy, gridlock
  final int delayMinutes;
  final DateTime updatedAt;

  CongestionAlert({
    required this.id,
    required this.roadName,
    required this.direction,
    required this.level,
    required this.delayMinutes,
    required this.updatedAt,
  });

  factory CongestionAlert.fromJson(Map<String, dynamic> json) {
    return CongestionAlert(
      id: _parseInt(json['id']),
      roadName: json['road_name'] ?? '',
      direction: json['direction'] ?? '',
      level: json['level'] ?? 'moderate',
      delayMinutes: _parseInt(json['delay_minutes']),
      updatedAt: DateTime.tryParse('${json['updated_at']}') ?? DateTime.now(),
    );
  }
}
