// lib/rita/models/rita_models.dart
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

// ─── Certificate Types ────────────────────────────────────────

enum CertificateType { birth, death, marriage }

CertificateType _parseCertType(String? s) {
  switch (s) {
    case 'birth': return CertificateType.birth;
    case 'death': return CertificateType.death;
    case 'marriage': return CertificateType.marriage;
    default: return CertificateType.birth;
  }
}

enum ApplicationStatus { submitted, processing, printing, ready, collected }

ApplicationStatus _parseAppStatus(String? s) {
  switch (s) {
    case 'submitted': return ApplicationStatus.submitted;
    case 'processing': return ApplicationStatus.processing;
    case 'printing': return ApplicationStatus.printing;
    case 'ready': return ApplicationStatus.ready;
    case 'collected': return ApplicationStatus.collected;
    default: return ApplicationStatus.submitted;
  }
}

// ─── Certificate Application ──────────────────────────────────

class CertificateApplication {
  final int id;
  final int userId;
  final CertificateType type;
  final ApplicationStatus status;
  final String trackingNumber;
  final String? holderName;
  final DateTime? dateOfEvent;
  final String? placeOfEvent;
  final double? feeAmount;
  final String? collectionOffice;
  final DateTime createdAt;

  CertificateApplication({
    required this.id,
    required this.userId,
    required this.type,
    required this.status,
    required this.trackingNumber,
    this.holderName,
    this.dateOfEvent,
    this.placeOfEvent,
    this.feeAmount,
    this.collectionOffice,
    required this.createdAt,
  });

  factory CertificateApplication.fromJson(Map<String, dynamic> json) {
    return CertificateApplication(
      id: _parseInt(json['id']),
      userId: _parseInt(json['user_id']),
      type: _parseCertType(json['type']),
      status: _parseAppStatus(json['status']),
      trackingNumber: json['tracking_number'] ?? '',
      holderName: json['holder_name'],
      dateOfEvent: json['date_of_event'] != null
          ? DateTime.tryParse(json['date_of_event']) : null,
      placeOfEvent: json['place_of_event'],
      feeAmount: json['fee_amount'] != null ? _parseDouble(json['fee_amount']) : null,
      collectionOffice: json['collection_office'],
      createdAt: DateTime.tryParse(json['created_at'] ?? '') ?? DateTime.now(),
    );
  }

  int get stageIndex {
    switch (status) {
      case ApplicationStatus.submitted: return 0;
      case ApplicationStatus.processing: return 1;
      case ApplicationStatus.printing: return 2;
      case ApplicationStatus.ready: return 3;
      case ApplicationStatus.collected: return 4;
    }
  }

  String get typeLabel {
    switch (type) {
      case CertificateType.birth: return 'Cheti cha Kuzaliwa';
      case CertificateType.death: return 'Cheti cha Kifo';
      case CertificateType.marriage: return 'Cheti cha Ndoa';
    }
  }
}

// ─── RITA Office ──────────────────────────────────────────────

class RitaOffice {
  final int id;
  final String name;
  final String? type;
  final String? address;
  final String? phone;
  final String? hours;
  final double? lat;
  final double? lng;

  RitaOffice({
    required this.id,
    required this.name,
    this.type,
    this.address,
    this.phone,
    this.hours,
    this.lat,
    this.lng,
  });

  factory RitaOffice.fromJson(Map<String, dynamic> json) {
    return RitaOffice(
      id: _parseInt(json['id']),
      name: json['name'] ?? '',
      type: json['type'],
      address: json['address'],
      phone: json['phone'],
      hours: json['hours'],
      lat: json['lat'] != null ? _parseDouble(json['lat']) : null,
      lng: json['lng'] != null ? _parseDouble(json['lng']) : null,
    );
  }
}

// ─── Fee Breakdown ────────────────────────────────────────────

class FeeBreakdown {
  final String certificateType;
  final double registrationFee;
  final double processingFee;
  final double expressFee;
  final double total;
  final String? note;

  FeeBreakdown({
    required this.certificateType,
    required this.registrationFee,
    required this.processingFee,
    this.expressFee = 0,
    required this.total,
    this.note,
  });

  factory FeeBreakdown.fromJson(Map<String, dynamic> json) {
    return FeeBreakdown(
      certificateType: json['certificate_type'] ?? '',
      registrationFee: _parseDouble(json['registration_fee']),
      processingFee: _parseDouble(json['processing_fee']),
      expressFee: _parseDouble(json['express_fee']),
      total: _parseDouble(json['total']),
      note: json['note'],
    );
  }
}

// ─── Family Record ────────────────────────────────────────────

class FamilyRecord {
  final int id;
  final String name;
  final String relationship;
  final List<String> certificates;
  final int pendingApplications;

  FamilyRecord({
    required this.id,
    required this.name,
    required this.relationship,
    this.certificates = const [],
    this.pendingApplications = 0,
  });

  factory FamilyRecord.fromJson(Map<String, dynamic> json) {
    return FamilyRecord(
      id: _parseInt(json['id']),
      name: json['name'] ?? '',
      relationship: json['relationship'] ?? '',
      certificates: (json['certificates'] as List?)?.map((e) => '$e').toList() ?? [],
      pendingApplications: _parseInt(json['pending_applications']),
    );
  }
}
