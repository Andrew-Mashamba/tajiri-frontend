// lib/neighbourhood_watch/models/neighbourhood_watch_models.dart

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

// ─── Community Alert ──────────────────────────────────────────

class CommunityAlert {
  final int id;
  final int userId;
  final String userName;
  final String type; // suspicious, theft, break_in, noise, fire, other
  final String title;
  final String description;
  final String? location;
  final double? lat;
  final double? lng;
  final String urgency; // low, medium, high, critical
  final int confirmations;
  final bool isActive;
  final DateTime createdAt;

  CommunityAlert({
    required this.id,
    required this.userId,
    required this.userName,
    required this.type,
    required this.title,
    required this.description,
    this.location,
    this.lat,
    this.lng,
    required this.urgency,
    required this.confirmations,
    required this.isActive,
    required this.createdAt,
  });

  factory CommunityAlert.fromJson(Map<String, dynamic> json) {
    return CommunityAlert(
      id: _parseInt(json['id']),
      userId: _parseInt(json['user_id']),
      userName: json['user_name'] ?? '',
      type: json['type'] ?? 'other',
      title: json['title'] ?? '',
      description: json['description'] ?? '',
      location: json['location'],
      lat: json['lat'] != null ? _parseDouble(json['lat']) : null,
      lng: json['lng'] != null ? _parseDouble(json['lng']) : null,
      urgency: json['urgency'] ?? 'medium',
      confirmations: _parseInt(json['confirmations']),
      isActive: _parseBool(json['is_active']),
      createdAt: DateTime.tryParse('${json['created_at']}') ?? DateTime.now(),
    );
  }

  Map<String, dynamic> toJson() => {
        'type': type,
        'title': title,
        'description': description,
        if (location != null) 'location': location,
        if (lat != null) 'lat': lat,
        if (lng != null) 'lng': lng,
        'urgency': urgency,
      };
}

// ─── Patrol Schedule ──────────────────────────────────────────

class PatrolSchedule {
  final int id;
  final String zone;
  final String dayOfWeek;
  final String startTime;
  final String endTime;
  final List<String> volunteers;
  final bool isActive;

  PatrolSchedule({
    required this.id,
    required this.zone,
    required this.dayOfWeek,
    required this.startTime,
    required this.endTime,
    this.volunteers = const [],
    required this.isActive,
  });

  factory PatrolSchedule.fromJson(Map<String, dynamic> json) {
    return PatrolSchedule(
      id: _parseInt(json['id']),
      zone: json['zone'] ?? '',
      dayOfWeek: json['day_of_week'] ?? '',
      startTime: json['start_time'] ?? '',
      endTime: json['end_time'] ?? '',
      volunteers:
          (json['volunteers'] as List?)?.map((e) => '$e').toList() ?? [],
      isActive: _parseBool(json['is_active']),
    );
  }
}
