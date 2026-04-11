// lib/dc/models/dc_models.dart
import '../../config/api_config.dart';

// ─── Parse helpers ──────────────────────────────────────────────
int _parseInt(dynamic v, [int fallback = 0]) =>
    (v is num) ? v.toInt() : int.tryParse('$v') ?? fallback;

double _parseDouble(dynamic v, [double fallback = 0.0]) =>
    (v is num) ? v.toDouble() : double.tryParse('$v') ?? fallback;

String _buildUrl(String? path) {
  if (path == null || path.isEmpty) return '';
  if (path.startsWith('http')) return ApiConfig.sanitizeUrl(path) ?? path;
  return '${ApiConfig.storageUrl}/$path';
}

// ─── Result wrappers ────────────────────────────────────────────
class SingleResult<T> {
  final bool success;
  final T? data;
  final String message;
  SingleResult({this.success = false, this.data, this.message = ''});
}

class PaginatedResult<T> {
  final bool success;
  final List<T> items;
  final int total;
  final int page;
  final String message;
  PaginatedResult({
    this.success = false,
    this.items = const [],
    this.total = 0,
    this.page = 1,
    this.message = '',
  });
}

// ─── District Commissioner ──────────────────────────────────────
class DistrictCommissioner {
  final int id;
  final int userId;
  final int districtId;
  final String name;
  final String photo;
  final String bio;
  final String appointmentDate;
  final List<String> previousPositions;
  final String phone;
  final String email;
  final String officeLocation;

  DistrictCommissioner({
    required this.id,
    this.userId = 0,
    this.districtId = 0,
    this.name = '',
    this.photo = '',
    this.bio = '',
    this.appointmentDate = '',
    this.previousPositions = const [],
    this.phone = '',
    this.email = '',
    this.officeLocation = '',
  });

  factory DistrictCommissioner.fromJson(Map<String, dynamic> json) =>
      DistrictCommissioner(
        id: _parseInt(json['id']),
        userId: _parseInt(json['user_id']),
        districtId: _parseInt(json['district_id']),
        name: json['name'] as String? ?? '',
        photo: _buildUrl(json['photo'] as String?),
        bio: json['bio'] as String? ?? '',
        appointmentDate: json['appointment_date'] as String? ?? '',
        previousPositions: (json['previous_positions'] as List?)
                ?.map((e) => e.toString())
                .toList() ??
            [],
        phone: json['phone'] as String? ?? '',
        email: json['email'] as String? ?? '',
        officeLocation: json['office_location'] as String? ?? '',
      );
}

// ─── District ───────────────────────────────────────────────────
class District {
  final int id;
  final String name;
  final int regionId;
  final int population;
  final int wardCount;
  final int schools;
  final int healthFacilities;
  final Map<String, dynamic> economicIndicators;

  District({
    required this.id,
    this.name = '',
    this.regionId = 0,
    this.population = 0,
    this.wardCount = 0,
    this.schools = 0,
    this.healthFacilities = 0,
    this.economicIndicators = const {},
  });

  factory District.fromJson(Map<String, dynamic> json) => District(
        id: _parseInt(json['id']),
        name: json['name'] as String? ?? '',
        regionId: _parseInt(json['region_id']),
        population: _parseInt(json['population']),
        wardCount: _parseInt(json['ward_count']),
        schools: _parseInt(json['schools']),
        healthFacilities: _parseInt(json['health_facilities']),
        economicIndicators:
            (json['economic_indicators'] as Map<String, dynamic>?) ?? {},
      );
}

// ─── Complaint Status ───────────────────────────────────────────
enum ComplaintStatus { received, assigned, investigating, resolved }

ComplaintStatus _parseComplaintStatus(dynamic v) {
  switch ('$v') {
    case 'assigned':
      return ComplaintStatus.assigned;
    case 'investigating':
      return ComplaintStatus.investigating;
    case 'resolved':
      return ComplaintStatus.resolved;
    default:
      return ComplaintStatus.received;
  }
}

// ─── District Complaint ─────────────────────────────────────────
class DistrictComplaint {
  final int id;
  final int reporterId;
  final int districtId;
  final String category;
  final String description;
  final List<String> attachments;
  final ComplaintStatus status;
  final String trackingNumber;
  final String createdAt;
  final String updatedAt;

  DistrictComplaint({
    required this.id,
    this.reporterId = 0,
    this.districtId = 0,
    this.category = '',
    this.description = '',
    this.attachments = const [],
    this.status = ComplaintStatus.received,
    this.trackingNumber = '',
    this.createdAt = '',
    this.updatedAt = '',
  });

  factory DistrictComplaint.fromJson(Map<String, dynamic> json) =>
      DistrictComplaint(
        id: _parseInt(json['id']),
        reporterId: _parseInt(json['reporter_id']),
        districtId: _parseInt(json['district_id']),
        category: json['category'] as String? ?? '',
        description: json['description'] as String? ?? '',
        attachments: (json['attachments'] as List?)
                ?.map((e) => _buildUrl(e as String?))
                .toList() ??
            [],
        status: _parseComplaintStatus(json['status']),
        trackingNumber: json['tracking_number'] as String? ?? '',
        createdAt: json['created_at'] as String? ?? '',
        updatedAt: json['updated_at'] as String? ?? '',
      );

  String get statusLabel {
    switch (status) {
      case ComplaintStatus.received:
        return 'Imepokelewa';
      case ComplaintStatus.assigned:
        return 'Imepewa mtu';
      case ComplaintStatus.investigating:
        return 'Inachunguzwa';
      case ComplaintStatus.resolved:
        return 'Imetatuliwa';
    }
  }
}

// ─── District Project ───────────────────────────────────────────
class DistrictProject {
  final int id;
  final int districtId;
  final String name;
  final double budget;
  final String funder;
  final String contractor;
  final String startDate;
  final String endDate;
  final int progressPercent;
  final String sector;
  final List<String> photos;

  DistrictProject({
    required this.id,
    this.districtId = 0,
    this.name = '',
    this.budget = 0,
    this.funder = '',
    this.contractor = '',
    this.startDate = '',
    this.endDate = '',
    this.progressPercent = 0,
    this.sector = '',
    this.photos = const [],
  });

  factory DistrictProject.fromJson(Map<String, dynamic> json) =>
      DistrictProject(
        id: _parseInt(json['id']),
        districtId: _parseInt(json['district_id']),
        name: json['name'] as String? ?? '',
        budget: _parseDouble(json['budget']),
        funder: json['funder'] as String? ?? '',
        contractor: json['contractor'] as String? ?? '',
        startDate: json['start_date'] as String? ?? '',
        endDate: json['end_date'] as String? ?? '',
        progressPercent: _parseInt(json['progress_percent']),
        sector: json['sector'] as String? ?? '',
        photos: (json['photos'] as List?)
                ?.map((e) => _buildUrl(e as String?))
                .toList() ??
            [],
      );
}

// ─── Emergency Alert ────────────────────────────────────────────
class EmergencyAlert {
  final int id;
  final String type; // flood, disease, security, weather
  final String title;
  final String description;
  final String severity; // low, medium, high, critical
  final int districtId;
  final bool active;
  final String createdAt;

  EmergencyAlert({
    required this.id,
    this.type = '',
    this.title = '',
    this.description = '',
    this.severity = 'medium',
    this.districtId = 0,
    this.active = true,
    this.createdAt = '',
  });

  factory EmergencyAlert.fromJson(Map<String, dynamic> json) => EmergencyAlert(
        id: _parseInt(json['id']),
        type: json['type'] as String? ?? '',
        title: json['title'] as String? ?? '',
        description: json['description'] as String? ?? '',
        severity: json['severity'] as String? ?? 'medium',
        districtId: _parseInt(json['district_id']),
        active: json['active'] as bool? ?? true,
        createdAt: json['created_at'] as String? ?? '',
      );
}

// ─── Department ─────────────────────────────────────────────────
class Department {
  final int id;
  final String name;
  final String headName;
  final String phone;
  final String email;
  final String location;
  final List<String> services;

  Department({
    required this.id,
    this.name = '',
    this.headName = '',
    this.phone = '',
    this.email = '',
    this.location = '',
    this.services = const [],
  });

  factory Department.fromJson(Map<String, dynamic> json) => Department(
        id: _parseInt(json['id']),
        name: json['name'] as String? ?? '',
        headName: json['head_name'] as String? ?? '',
        phone: json['phone'] as String? ?? '',
        email: json['email'] as String? ?? '',
        location: json['location'] as String? ?? '',
        services: (json['services'] as List?)
                ?.map((e) => e.toString())
                .toList() ??
            [],
      );
}

// ─── District Stats ─────────────────────────────────────────────
class DistrictStats {
  final int districtId;
  final Map<String, dynamic> education;
  final Map<String, dynamic> health;
  final Map<String, dynamic> economy;
  final Map<String, dynamic> infrastructure;

  DistrictStats({
    this.districtId = 0,
    this.education = const {},
    this.health = const {},
    this.economy = const {},
    this.infrastructure = const {},
  });

  factory DistrictStats.fromJson(Map<String, dynamic> json) => DistrictStats(
        districtId: _parseInt(json['district_id']),
        education: (json['education'] as Map<String, dynamic>?) ?? {},
        health: (json['health'] as Map<String, dynamic>?) ?? {},
        economy: (json['economy'] as Map<String, dynamic>?) ?? {},
        infrastructure: (json['infrastructure'] as Map<String, dynamic>?) ?? {},
      );
}
