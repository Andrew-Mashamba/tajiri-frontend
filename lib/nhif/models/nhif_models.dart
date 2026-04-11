// lib/nhif/models/nhif_models.dart
import '../../config/api_config.dart';

int _parseInt(dynamic v) => (v is num) ? v.toInt() : int.tryParse('$v') ?? 0;
double _parseDouble(dynamic v) => (v is num) ? v.toDouble() : double.tryParse('$v') ?? 0.0;
bool _parseBool(dynamic v) => v == true || v == 1 || v == '1' || v == 'true';

class SingleResult<T> { final bool success; final T? data; final String? message; SingleResult({required this.success, this.data, this.message}); }
class PaginatedResult<T> { final bool success; final List<T> items; final String? message; final int currentPage; final int lastPage;
  PaginatedResult({required this.success, this.items = const [], this.message, this.currentPage = 1, this.lastPage = 1}); bool get hasMore => currentPage < lastPage; }

class NhifMembership {
  final int id; final String memberNumber; final String status; final DateTime? validFrom;
  final DateTime? validTo; final String? plan; final String? employerName; final double contributionAmount;

  NhifMembership({required this.id, required this.memberNumber, required this.status,
    this.validFrom, this.validTo, this.plan, this.employerName, this.contributionAmount = 0});

  factory NhifMembership.fromJson(Map<String, dynamic> json) => NhifMembership(
    id: _parseInt(json['id']), memberNumber: json['member_number'] ?? '',
    status: json['status'] ?? 'unknown',
    validFrom: json['valid_from'] != null ? DateTime.tryParse(json['valid_from']) : null,
    validTo: json['valid_to'] != null ? DateTime.tryParse(json['valid_to']) : null,
    plan: json['plan'], employerName: json['employer_name'],
    contributionAmount: _parseDouble(json['contribution_amount']));

  bool get isActive => status == 'active';
  bool get isExpired => validTo != null && validTo!.isBefore(DateTime.now());
}

class Dependent {
  final int id; final String name; final String relationship; final DateTime? dateOfBirth; final String status;
  Dependent({required this.id, required this.name, required this.relationship, this.dateOfBirth, this.status = 'active'});
  factory Dependent.fromJson(Map<String, dynamic> json) => Dependent(
    id: _parseInt(json['id']), name: json['name'] ?? '', relationship: json['relationship'] ?? '',
    dateOfBirth: json['date_of_birth'] != null ? DateTime.tryParse(json['date_of_birth']) : null,
    status: json['status'] ?? 'active');
}

class AccreditedFacility {
  final int id; final String name; final String type; final String? address; final String? phone;
  final double? lat; final double? lng; final double rating;
  AccreditedFacility({required this.id, required this.name, required this.type, this.address, this.phone, this.lat, this.lng, this.rating = 0});
  factory AccreditedFacility.fromJson(Map<String, dynamic> json) => AccreditedFacility(
    id: _parseInt(json['id']), name: json['name'] ?? '', type: json['type'] ?? '',
    address: json['address'], phone: json['phone'],
    lat: json['lat'] != null ? _parseDouble(json['lat']) : null,
    lng: json['lng'] != null ? _parseDouble(json['lng']) : null,
    rating: _parseDouble(json['rating']));
}

class Claim {
  final int id; final String facilityName; final DateTime serviceDate; final double amount; final String status;
  Claim({required this.id, required this.facilityName, required this.serviceDate, required this.amount, required this.status});
  factory Claim.fromJson(Map<String, dynamic> json) => Claim(
    id: _parseInt(json['id']), facilityName: json['facility_name'] ?? '',
    serviceDate: DateTime.tryParse(json['service_date'] ?? '') ?? DateTime.now(),
    amount: _parseDouble(json['amount']), status: json['status'] ?? '');
}

class Drug {
  final int id; final String genericName; final List<String> brandNames; final String coverageLevel;
  Drug({required this.id, required this.genericName, this.brandNames = const [], required this.coverageLevel});
  factory Drug.fromJson(Map<String, dynamic> json) => Drug(
    id: _parseInt(json['id']), genericName: json['generic_name'] ?? '',
    brandNames: (json['brand_names'] as List?)?.map((e) => '$e').toList() ?? [],
    coverageLevel: json['coverage_level'] ?? '');
}
