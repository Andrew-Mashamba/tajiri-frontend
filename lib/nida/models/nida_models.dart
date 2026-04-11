// lib/nida/models/nida_models.dart
import '../../config/api_config.dart';

int _parseInt(dynamic v) => (v is num) ? v.toInt() : int.tryParse('$v') ?? 0;
double _parseDouble(dynamic v) =>
    (v is num) ? v.toDouble() : double.tryParse('$v') ?? 0.0;
bool _parseBool(dynamic v) =>
    v == true || v == 1 || v == '1' || v == 'true';

// ─── Result wrappers ───────────────────────────────────────────

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

// ─── NIDA Application ─────────────────────────────────────────

enum NidaStatus { registered, biometrics, printing, atOffice, collected, unknown }

NidaStatus _parseNidaStatus(String? s) {
  switch (s) {
    case 'registered': return NidaStatus.registered;
    case 'biometrics': return NidaStatus.biometrics;
    case 'printing': return NidaStatus.printing;
    case 'at_office': return NidaStatus.atOffice;
    case 'collected': return NidaStatus.collected;
    default: return NidaStatus.unknown;
  }
}

class NidaApplication {
  final int id;
  final int userId;
  final String receiptNumber;
  final String? nidaNumber;
  final NidaStatus status;
  final String? currentStage;
  final DateTime? estimatedDate;
  final String? officeName;
  final DateTime createdAt;

  NidaApplication({
    required this.id,
    required this.userId,
    required this.receiptNumber,
    this.nidaNumber,
    required this.status,
    this.currentStage,
    this.estimatedDate,
    this.officeName,
    required this.createdAt,
  });

  factory NidaApplication.fromJson(Map<String, dynamic> json) {
    return NidaApplication(
      id: _parseInt(json['id']),
      userId: _parseInt(json['user_id']),
      receiptNumber: json['receipt_number'] ?? '',
      nidaNumber: json['nida_number'],
      status: _parseNidaStatus(json['status']),
      currentStage: json['current_stage'],
      estimatedDate: json['estimated_date'] != null
          ? DateTime.tryParse(json['estimated_date'])
          : null,
      officeName: json['office_name'],
      createdAt: DateTime.tryParse(json['created_at'] ?? '') ?? DateTime.now(),
    );
  }

  int get stageIndex {
    switch (status) {
      case NidaStatus.registered: return 0;
      case NidaStatus.biometrics: return 1;
      case NidaStatus.printing: return 2;
      case NidaStatus.atOffice: return 3;
      case NidaStatus.collected: return 4;
      case NidaStatus.unknown: return -1;
    }
  }
}

// ─── NIDA Office ──────────────────────────────────────────────

class NidaOffice {
  final int id;
  final String name;
  final String? district;
  final String? address;
  final String? phone;
  final String? hours;
  final List<String> services;
  final int? queueEstimateMinutes;
  final double? lat;
  final double? lng;
  final double? distanceKm;

  NidaOffice({
    required this.id,
    required this.name,
    this.district,
    this.address,
    this.phone,
    this.hours,
    this.services = const [],
    this.queueEstimateMinutes,
    this.lat,
    this.lng,
    this.distanceKm,
  });

  factory NidaOffice.fromJson(Map<String, dynamic> json) {
    return NidaOffice(
      id: _parseInt(json['id']),
      name: json['name'] ?? '',
      district: json['district'],
      address: json['address'],
      phone: json['phone'],
      hours: json['hours'],
      services: (json['services'] as List?)?.map((e) => '$e').toList() ?? [],
      queueEstimateMinutes: json['queue_estimate_minutes'] != null
          ? _parseInt(json['queue_estimate_minutes'])
          : null,
      lat: json['lat'] != null ? _parseDouble(json['lat']) : null,
      lng: json['lng'] != null ? _parseDouble(json['lng']) : null,
      distanceKm: json['distance_km'] != null
          ? _parseDouble(json['distance_km'])
          : null,
    );
  }

  String get queueLabel {
    if (queueEstimateMinutes == null) return 'N/A';
    if (queueEstimateMinutes! < 60) return '${queueEstimateMinutes}min';
    final h = queueEstimateMinutes! ~/ 60;
    final m = queueEstimateMinutes! % 60;
    return m > 0 ? '${h}h ${m}m' : '${h}h';
  }
}

// ─── Checklist Item ───────────────────────────────────────────

class ChecklistItem {
  final String id;
  final String title;
  final String description;
  final String? whereToGet;
  final bool required_;

  ChecklistItem({
    required this.id,
    required this.title,
    required this.description,
    this.whereToGet,
    this.required_ = true,
  });

  factory ChecklistItem.fromJson(Map<String, dynamic> json) {
    return ChecklistItem(
      id: json['id'] ?? '',
      title: json['title'] ?? '',
      description: json['description'] ?? '',
      whereToGet: json['where_to_get'],
      required_: _parseBool(json['required']),
    );
  }
}

// ─── Family Member ────────────────────────────────────────────

class FamilyMember {
  final int id;
  final String name;
  final String relationship;
  final NidaStatus nidaStatus;
  final String? nidaNumber;
  final DateTime? dateOfBirth;

  FamilyMember({
    required this.id,
    required this.name,
    required this.relationship,
    required this.nidaStatus,
    this.nidaNumber,
    this.dateOfBirth,
  });

  factory FamilyMember.fromJson(Map<String, dynamic> json) {
    return FamilyMember(
      id: _parseInt(json['id']),
      name: json['name'] ?? '',
      relationship: json['relationship'] ?? '',
      nidaStatus: _parseNidaStatus(json['nida_status']),
      nidaNumber: json['nida_number'],
      dateOfBirth: json['date_of_birth'] != null
          ? DateTime.tryParse(json['date_of_birth'])
          : null,
    );
  }
}
