// lib/police/models/police_models.dart
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

// ─── Police Station ───────────────────────────────────────────

class PoliceStation {
  final int id;
  final String name;
  final String address;
  final double lat;
  final double lng;
  final String? phone;
  final String? ocdName;
  final String regionName;
  final String districtName;
  final String? operatingHours;
  final double? distance;

  PoliceStation({
    required this.id,
    required this.name,
    required this.address,
    required this.lat,
    required this.lng,
    this.phone,
    this.ocdName,
    required this.regionName,
    required this.districtName,
    this.operatingHours,
    this.distance,
  });

  factory PoliceStation.fromJson(Map<String, dynamic> json) {
    return PoliceStation(
      id: _parseInt(json['id']),
      name: json['name'] ?? '',
      address: json['address'] ?? '',
      lat: _parseDouble(json['lat']),
      lng: _parseDouble(json['lng']),
      phone: json['phone'],
      ocdName: json['ocd_name'],
      regionName: json['region_name'] ?? '',
      districtName: json['district_name'] ?? '',
      operatingHours: json['operating_hours'],
      distance: json['distance'] != null ? _parseDouble(json['distance']) : null,
    );
  }
}

// ─── Crime Report ─────────────────────────────────────────────

class CrimeReport {
  final int id;
  final int userId;
  final String incidentType;
  final String description;
  final String? location;
  final double? lat;
  final double? lng;
  final List<String> photos;
  final String? caseNumber;
  final String status; // received, investigating, resolved
  final DateTime createdAt;

  CrimeReport({
    required this.id,
    required this.userId,
    required this.incidentType,
    required this.description,
    this.location,
    this.lat,
    this.lng,
    this.photos = const [],
    this.caseNumber,
    required this.status,
    required this.createdAt,
  });

  factory CrimeReport.fromJson(Map<String, dynamic> json) {
    return CrimeReport(
      id: _parseInt(json['id']),
      userId: _parseInt(json['user_id']),
      incidentType: json['incident_type'] ?? '',
      description: json['description'] ?? '',
      location: json['location'],
      lat: json['lat'] != null ? _parseDouble(json['lat']) : null,
      lng: json['lng'] != null ? _parseDouble(json['lng']) : null,
      photos: (json['photos'] as List?)?.map((e) => '$e').toList() ?? [],
      caseNumber: json['case_number'],
      status: json['status'] ?? 'received',
      createdAt: DateTime.tryParse('${json['created_at']}') ?? DateTime.now(),
    );
  }

  Map<String, dynamic> toJson() => {
        'incident_type': incidentType,
        'description': description,
        if (location != null) 'location': location,
        if (lat != null) 'lat': lat,
        if (lng != null) 'lng': lng,
      };

  String get statusLabel {
    switch (status) {
      case 'investigating':
        return 'Under Investigation';
      case 'resolved':
        return 'Resolved';
      default:
        return 'Received';
    }
  }
}

// ─── Emergency Contact ────────────────────────────────────────

class EmergencyContact {
  final int id;
  final String name;
  final String phone;
  final String? relationship;
  final bool isPrimary;

  EmergencyContact({
    required this.id,
    required this.name,
    required this.phone,
    this.relationship,
    required this.isPrimary,
  });

  factory EmergencyContact.fromJson(Map<String, dynamic> json) {
    return EmergencyContact(
      id: _parseInt(json['id']),
      name: json['name'] ?? '',
      phone: json['phone'] ?? '',
      relationship: json['relationship'],
      isPrimary: _parseBool(json['is_primary']),
    );
  }

  Map<String, dynamic> toJson() => {
        'name': name,
        'phone': phone,
        if (relationship != null) 'relationship': relationship,
        'is_primary': isPrimary,
      };
}
