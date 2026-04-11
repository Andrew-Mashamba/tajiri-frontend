// lib/land_office/models/land_office_models.dart
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

// ─── Plot ─────────────────────────────────────────────────────

class Plot {
  final int id;
  final String plotNumber;
  final String? location;
  final String? registeredOwner;
  final String titleType; // granted, deemed, ccro
  final String? encumbrances;
  final double? area;
  final String? zoning;
  final String status;

  Plot({
    required this.id, required this.plotNumber, this.location,
    this.registeredOwner, required this.titleType,
    this.encumbrances, this.area, this.zoning, required this.status,
  });

  factory Plot.fromJson(Map<String, dynamic> json) {
    return Plot(
      id: _parseInt(json['id']),
      plotNumber: json['plot_number'] ?? '',
      location: json['location'],
      registeredOwner: json['registered_owner'],
      titleType: json['title_type'] ?? 'granted',
      encumbrances: json['encumbrances'],
      area: json['area'] != null ? _parseDouble(json['area']) : null,
      zoning: json['zoning'],
      status: json['status'] ?? '',
    );
  }
}

// ─── Title Deed ───────────────────────────────────────────────

class TitleDeed {
  final int id;
  final String certificateNumber;
  final String ownerName;
  final DateTime? issueDate;
  final String titleType;
  final bool verified;

  TitleDeed({
    required this.id, required this.certificateNumber,
    required this.ownerName, this.issueDate,
    required this.titleType, this.verified = false,
  });

  factory TitleDeed.fromJson(Map<String, dynamic> json) {
    return TitleDeed(
      id: _parseInt(json['id']),
      certificateNumber: json['certificate_number'] ?? '',
      ownerName: json['owner_name'] ?? '',
      issueDate: json['issue_date'] != null
          ? DateTime.tryParse(json['issue_date']) : null,
      titleType: json['title_type'] ?? '',
      verified: _parseBool(json['verified']),
    );
  }
}

// ─── Fraud Alert ──────────────────────────────────────────────

class FraudAlert {
  final int id;
  final String plotNumber;
  final String? location;
  final String alertType;
  final String description;
  final DateTime reportedAt;
  final String status;

  FraudAlert({
    required this.id, required this.plotNumber, this.location,
    required this.alertType, required this.description,
    required this.reportedAt, required this.status,
  });

  factory FraudAlert.fromJson(Map<String, dynamic> json) {
    return FraudAlert(
      id: _parseInt(json['id']),
      plotNumber: json['plot_number'] ?? '',
      location: json['location'],
      alertType: json['alert_type'] ?? '',
      description: json['description'] ?? '',
      reportedAt: DateTime.tryParse(json['reported_at'] ?? '') ?? DateTime.now(),
      status: json['status'] ?? 'active',
    );
  }
}

// ─── Surveyor ─────────────────────────────────────────────────

class Surveyor {
  final int id;
  final String name;
  final String? licenceNumber;
  final String? location;
  final double rating;
  final String? feeRange;
  final String? phone;

  Surveyor({
    required this.id, required this.name, this.licenceNumber,
    this.location, this.rating = 0, this.feeRange, this.phone,
  });

  factory Surveyor.fromJson(Map<String, dynamic> json) {
    return Surveyor(
      id: _parseInt(json['id']),
      name: json['name'] ?? '',
      licenceNumber: json['licence_number'],
      location: json['location'],
      rating: _parseDouble(json['rating']),
      feeRange: json['fee_range'],
      phone: json['phone'],
    );
  }
}
