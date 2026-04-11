// lib/car_insurance/models/car_insurance_models.dart
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

// ─── Insurance Provider ────────────────────────────────────────

class InsuranceProvider {
  final int id;
  final String name;
  final String? logoUrl;
  final double rating;
  final int reviewCount;
  final String? phone;
  final String? email;
  final bool isVerified;

  InsuranceProvider({
    required this.id,
    required this.name,
    this.logoUrl,
    required this.rating,
    required this.reviewCount,
    this.phone,
    this.email,
    required this.isVerified,
  });

  factory InsuranceProvider.fromJson(Map<String, dynamic> json) {
    final rawLogo = json['logo_url'] as String?;
    return InsuranceProvider(
      id: _parseInt(json['id']),
      name: json['name'] ?? '',
      logoUrl: rawLogo != null ? ApiConfig.sanitizeUrl(rawLogo) : null,
      rating: _parseDouble(json['rating']),
      reviewCount: _parseInt(json['review_count']),
      phone: json['phone'],
      email: json['email'],
      isVerified: _parseBool(json['is_verified']),
    );
  }
}

// ─── Insurance Quote ──────────────────────────────────────────

class InsuranceQuote {
  final int id;
  final int providerId;
  final String providerName;
  final String? providerLogo;
  final String coverageType; // tpo, tpft, comprehensive
  final double premium;
  final double excess;
  final List<String> inclusions;
  final List<String> exclusions;
  final bool hasNoClaimsDiscount;
  final double? discountPercent;
  final DateTime validUntil;

  InsuranceQuote({
    required this.id,
    required this.providerId,
    required this.providerName,
    this.providerLogo,
    required this.coverageType,
    required this.premium,
    required this.excess,
    this.inclusions = const [],
    this.exclusions = const [],
    required this.hasNoClaimsDiscount,
    this.discountPercent,
    required this.validUntil,
  });

  factory InsuranceQuote.fromJson(Map<String, dynamic> json) {
    final rawLogo = json['provider_logo'] as String?;
    return InsuranceQuote(
      id: _parseInt(json['id']),
      providerId: _parseInt(json['provider_id']),
      providerName: json['provider_name'] ?? '',
      providerLogo: rawLogo != null ? ApiConfig.sanitizeUrl(rawLogo) : null,
      coverageType: json['coverage_type'] ?? 'tpo',
      premium: _parseDouble(json['premium']),
      excess: _parseDouble(json['excess']),
      inclusions: (json['inclusions'] as List?)?.cast<String>() ?? [],
      exclusions: (json['exclusions'] as List?)?.cast<String>() ?? [],
      hasNoClaimsDiscount: _parseBool(json['has_no_claims_discount']),
      discountPercent: json['discount_percent'] != null
          ? _parseDouble(json['discount_percent'])
          : null,
      validUntil:
          DateTime.tryParse('${json['valid_until']}') ?? DateTime.now(),
    );
  }

  String get coverageLabel {
    switch (coverageType) {
      case 'tpo':
        return 'Third Party Only';
      case 'tpft':
        return 'Third Party Fire & Theft';
      case 'comprehensive':
        return 'Comprehensive';
      default:
        return coverageType;
    }
  }
}

// ─── Insurance Policy ─────────────────────────────────────────

class InsurancePolicy {
  final int id;
  final int userId;
  final int? carId;
  final String policyNumber;
  final String providerName;
  final String? providerLogo;
  final String coverageType;
  final double premium;
  final DateTime startDate;
  final DateTime endDate;
  final String status; // active, expired, cancelled
  final String? vehicleMake;
  final String? vehicleModel;
  final String? plateNumber;
  final int noClaimsYears;

  InsurancePolicy({
    required this.id,
    required this.userId,
    this.carId,
    required this.policyNumber,
    required this.providerName,
    this.providerLogo,
    required this.coverageType,
    required this.premium,
    required this.startDate,
    required this.endDate,
    required this.status,
    this.vehicleMake,
    this.vehicleModel,
    this.plateNumber,
    required this.noClaimsYears,
  });

  factory InsurancePolicy.fromJson(Map<String, dynamic> json) {
    final rawLogo = json['provider_logo'] as String?;
    return InsurancePolicy(
      id: _parseInt(json['id']),
      userId: _parseInt(json['user_id']),
      carId: json['car_id'] != null ? _parseInt(json['car_id']) : null,
      policyNumber: json['policy_number'] ?? '',
      providerName: json['provider_name'] ?? '',
      providerLogo: rawLogo != null ? ApiConfig.sanitizeUrl(rawLogo) : null,
      coverageType: json['coverage_type'] ?? 'tpo',
      premium: _parseDouble(json['premium']),
      startDate: DateTime.tryParse('${json['start_date']}') ?? DateTime.now(),
      endDate: DateTime.tryParse('${json['end_date']}') ?? DateTime.now(),
      status: json['status'] ?? 'active',
      vehicleMake: json['vehicle_make'],
      vehicleModel: json['vehicle_model'],
      plateNumber: json['plate_number'],
      noClaimsYears: _parseInt(json['no_claims_years']),
    );
  }

  bool get isActive => status == 'active';
  bool get isExpired => endDate.isBefore(DateTime.now());
  int get daysRemaining => endDate.difference(DateTime.now()).inDays;
  String get vehicleDisplay =>
      '${vehicleMake ?? ''} ${vehicleModel ?? ''}'.trim();
}

// ─── Insurance Claim ──────────────────────────────────────────

class InsuranceClaim {
  final int id;
  final int policyId;
  final String claimNumber;
  final String type; // accident, theft, fire, other
  final String status; // submitted, under_review, approved, rejected, settled
  final String description;
  final DateTime incidentDate;
  final double? claimAmount;
  final double? settledAmount;
  final String? policeReportNumber;
  final DateTime createdAt;

  InsuranceClaim({
    required this.id,
    required this.policyId,
    required this.claimNumber,
    required this.type,
    required this.status,
    required this.description,
    required this.incidentDate,
    this.claimAmount,
    this.settledAmount,
    this.policeReportNumber,
    required this.createdAt,
  });

  factory InsuranceClaim.fromJson(Map<String, dynamic> json) {
    return InsuranceClaim(
      id: _parseInt(json['id']),
      policyId: _parseInt(json['policy_id']),
      claimNumber: json['claim_number'] ?? '',
      type: json['type'] ?? 'other',
      status: json['status'] ?? 'submitted',
      description: json['description'] ?? '',
      incidentDate:
          DateTime.tryParse('${json['incident_date']}') ?? DateTime.now(),
      claimAmount: json['claim_amount'] != null
          ? _parseDouble(json['claim_amount'])
          : null,
      settledAmount: json['settled_amount'] != null
          ? _parseDouble(json['settled_amount'])
          : null,
      policeReportNumber: json['police_report_number'],
      createdAt: DateTime.tryParse('${json['created_at']}') ?? DateTime.now(),
    );
  }

  Map<String, dynamic> toJson() => {
        'policy_id': policyId,
        'type': type,
        'description': description,
        'incident_date': incidentDate.toIso8601String(),
        if (claimAmount != null) 'claim_amount': claimAmount,
        if (policeReportNumber != null)
          'police_report_number': policeReportNumber,
      };
}
