// lib/passport/models/passport_models.dart
import '../../config/api_config.dart';

int _parseInt(dynamic v) => (v is num) ? v.toInt() : int.tryParse('$v') ?? 0;
double _parseDouble(dynamic v) =>
    (v is num) ? v.toDouble() : double.tryParse('$v') ?? 0.0;
bool _parseBool(dynamic v) =>
    v == true || v == 1 || v == '1' || v == 'true';

class SingleResult<T> {
  final bool success; final T? data; final String? message;
  SingleResult({required this.success, this.data, this.message});
}

class PaginatedResult<T> {
  final bool success; final List<T> items; final String? message;
  final int currentPage; final int lastPage;
  PaginatedResult({required this.success, this.items = const [], this.message,
    this.currentPage = 1, this.lastPage = 1});
  bool get hasMore => currentPage < lastPage;
}

// ─── Passport Application ─────────────────────────────────────

class PassportApplication {
  final int id;
  final String applicationNumber;
  final String type; // ordinary, diplomatic, service
  final int pages; // 32 or 64
  final int validity; // 5 or 10
  final String status; // submitted, processing, printing, ready
  final String? submissionOffice;
  final DateTime createdAt;

  PassportApplication({
    required this.id, required this.applicationNumber,
    required this.type, required this.pages, required this.validity,
    required this.status, this.submissionOffice, required this.createdAt,
  });

  factory PassportApplication.fromJson(Map<String, dynamic> json) {
    return PassportApplication(
      id: _parseInt(json['id']),
      applicationNumber: json['application_number'] ?? '',
      type: json['type'] ?? 'ordinary',
      pages: _parseInt(json['pages']),
      validity: _parseInt(json['validity']),
      status: json['status'] ?? 'submitted',
      submissionOffice: json['submission_office'],
      createdAt: DateTime.tryParse(json['created_at'] ?? '') ?? DateTime.now(),
    );
  }

  int get stageIndex {
    switch (status) {
      case 'submitted': return 0;
      case 'processing': return 1;
      case 'printing': return 2;
      case 'ready': return 3;
      default: return 0;
    }
  }
}

// ─── Passport Info ────────────────────────────────────────────

class PassportInfo {
  final int id;
  final String passportNumber;
  final String holderName;
  final String type;
  final DateTime issueDate;
  final DateTime expiryDate;
  final int pages;

  PassportInfo({
    required this.id, required this.passportNumber, required this.holderName,
    required this.type, required this.issueDate, required this.expiryDate,
    required this.pages,
  });

  factory PassportInfo.fromJson(Map<String, dynamic> json) {
    return PassportInfo(
      id: _parseInt(json['id']),
      passportNumber: json['passport_number'] ?? '',
      holderName: json['holder_name'] ?? '',
      type: json['type'] ?? 'ordinary',
      issueDate: DateTime.tryParse(json['issue_date'] ?? '') ?? DateTime.now(),
      expiryDate: DateTime.tryParse(json['expiry_date'] ?? '') ?? DateTime.now(),
      pages: _parseInt(json['pages']),
    );
  }

  int get daysUntilExpiry => expiryDate.difference(DateTime.now()).inDays;
  bool get isExpiring => daysUntilExpiry <= 180;
  bool get isExpired => daysUntilExpiry < 0;
}

// ─── Visa Requirement ─────────────────────────────────────────

class VisaRequirement {
  final String countryCode;
  final String countryName;
  final String status; // visaFree, visaOnArrival, visaRequired
  final String? details;
  final int? stayDuration;

  VisaRequirement({
    required this.countryCode, required this.countryName,
    required this.status, this.details, this.stayDuration,
  });

  factory VisaRequirement.fromJson(Map<String, dynamic> json) {
    return VisaRequirement(
      countryCode: json['country_code'] ?? '',
      countryName: json['country_name'] ?? '',
      status: json['status'] ?? 'visaRequired',
      details: json['details'],
      stayDuration: json['stay_duration'] != null
          ? _parseInt(json['stay_duration']) : null,
    );
  }
}

// ─── Embassy ──────────────────────────────────────────────────

class Embassy {
  final int id;
  final String country;
  final String city;
  final String? address;
  final String? phone;
  final String? email;
  final String? emergencyPhone;

  Embassy({
    required this.id, required this.country, required this.city,
    this.address, this.phone, this.email, this.emergencyPhone,
  });

  factory Embassy.fromJson(Map<String, dynamic> json) {
    return Embassy(
      id: _parseInt(json['id']),
      country: json['country'] ?? '',
      city: json['city'] ?? '',
      address: json['address'],
      phone: json['phone'],
      email: json['email'],
      emergencyPhone: json['emergency_phone'],
    );
  }
}

// ─── Fee Breakdown ────────────────────────────────────────────

class PassportFee {
  final String type;
  final int pages;
  final int validity;
  final double applicationFee;
  final double expressFee;
  final double total;

  PassportFee({
    required this.type, required this.pages, required this.validity,
    required this.applicationFee, this.expressFee = 0, required this.total,
  });

  factory PassportFee.fromJson(Map<String, dynamic> json) {
    return PassportFee(
      type: json['type'] ?? '',
      pages: _parseInt(json['pages']),
      validity: _parseInt(json['validity']),
      applicationFee: _parseDouble(json['application_fee']),
      expressFee: _parseDouble(json['express_fee']),
      total: _parseDouble(json['total']),
    );
  }
}
