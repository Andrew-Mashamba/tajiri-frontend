// lib/insurance/models/insurance_models.dart
import 'package:flutter/material.dart';

// ─── Insurance Categories ───────────────────────────────────────

enum InsuranceCategory {
  health,
  life,
  motor,
  property,
  travel,
  creditLife,
  micro,
  business,
  device,
  buyerProtection;

  String get displayName {
    switch (this) {
      case InsuranceCategory.health: return 'Afya';
      case InsuranceCategory.life: return 'Maisha';
      case InsuranceCategory.motor: return 'Gari';
      case InsuranceCategory.property: return 'Mali';
      case InsuranceCategory.travel: return 'Safari';
      case InsuranceCategory.creditLife: return 'Mkopo';
      case InsuranceCategory.micro: return 'Bima Ndogo';
      case InsuranceCategory.business: return 'Biashara';
      case InsuranceCategory.device: return 'Simu';
      case InsuranceCategory.buyerProtection: return 'Ununuzi';
    }
  }

  String get subtitle {
    switch (this) {
      case InsuranceCategory.health: return 'Health';
      case InsuranceCategory.life: return 'Life';
      case InsuranceCategory.motor: return 'Motor';
      case InsuranceCategory.property: return 'Property';
      case InsuranceCategory.travel: return 'Travel';
      case InsuranceCategory.creditLife: return 'Credit Life';
      case InsuranceCategory.micro: return 'Micro-Insurance';
      case InsuranceCategory.business: return 'Business';
      case InsuranceCategory.device: return 'Device';
      case InsuranceCategory.buyerProtection: return 'Buyer Protection';
    }
  }

  IconData get icon {
    switch (this) {
      case InsuranceCategory.health: return Icons.health_and_safety_rounded;
      case InsuranceCategory.life: return Icons.favorite_rounded;
      case InsuranceCategory.motor: return Icons.directions_car_rounded;
      case InsuranceCategory.property: return Icons.home_rounded;
      case InsuranceCategory.travel: return Icons.flight_rounded;
      case InsuranceCategory.creditLife: return Icons.shield_rounded;
      case InsuranceCategory.micro: return Icons.security_rounded;
      case InsuranceCategory.business: return Icons.store_rounded;
      case InsuranceCategory.device: return Icons.phone_android_rounded;
      case InsuranceCategory.buyerProtection: return Icons.shopping_bag_rounded;
    }
  }

  static InsuranceCategory fromString(String? s) {
    return InsuranceCategory.values.firstWhere(
      (v) => v.name == s,
      orElse: () => InsuranceCategory.health,
    );
  }
}

// ─── Insurance Product ──────────────────────────────────────────

class InsuranceProduct {
  final int id;
  final String name;
  final String providerName;
  final String? providerLogoUrl;
  final InsuranceCategory category;
  final String coverageType; // basic, standard, comprehensive
  final double premiumMonthly;
  final double? premiumAnnual;
  final double coverLimit;
  final String currency;
  final String? description;
  final List<String> benefits;
  final List<String> exclusions;
  final int? waitingPeriodDays;
  final bool isPopular;
  final double? rating;

  InsuranceProduct({
    required this.id,
    required this.name,
    required this.providerName,
    this.providerLogoUrl,
    required this.category,
    required this.coverageType,
    required this.premiumMonthly,
    this.premiumAnnual,
    required this.coverLimit,
    this.currency = 'TZS',
    this.description,
    this.benefits = const [],
    this.exclusions = const [],
    this.waitingPeriodDays,
    this.isPopular = false,
    this.rating,
  });

  factory InsuranceProduct.fromJson(Map<String, dynamic> json) {
    return InsuranceProduct(
      id: json['id'] ?? 0,
      name: json['name'] ?? '',
      providerName: json['provider_name'] ?? '',
      providerLogoUrl: json['provider_logo_url'],
      category: InsuranceCategory.fromString(json['category']),
      coverageType: json['coverage_type'] ?? 'basic',
      premiumMonthly: (json['premium_monthly'] as num?)?.toDouble() ?? 0,
      premiumAnnual: (json['premium_annual'] as num?)?.toDouble(),
      coverLimit: (json['cover_limit'] as num?)?.toDouble() ?? 0,
      currency: json['currency'] ?? 'TZS',
      description: json['description'],
      benefits: (json['benefits'] as List?)?.cast<String>() ?? [],
      exclusions: (json['exclusions'] as List?)?.cast<String>() ?? [],
      waitingPeriodDays: (json['waiting_period_days'] as num?)?.toInt(),
      isPopular: json['is_popular'] ?? false,
      rating: (json['rating'] as num?)?.toDouble(),
    );
  }

  String get coverageLabel {
    switch (coverageType) {
      case 'basic': return 'Msingi';
      case 'standard': return 'Kawaida';
      case 'comprehensive': return 'Kamili';
      default: return coverageType;
    }
  }
}

// ─── Policy (Active Insurance) ──────────────────────────────────

enum PolicyStatus {
  active,
  pendingPayment,
  expired,
  cancelled,
  claimed;

  String get displayName {
    switch (this) {
      case PolicyStatus.active: return 'Hai';
      case PolicyStatus.pendingPayment: return 'Inasubiri Malipo';
      case PolicyStatus.expired: return 'Imeisha';
      case PolicyStatus.cancelled: return 'Imeghairiwa';
      case PolicyStatus.claimed: return 'Imeidaiwa';
    }
  }

  Color get color {
    switch (this) {
      case PolicyStatus.active: return const Color(0xFF4CAF50);
      case PolicyStatus.pendingPayment: return Colors.orange;
      case PolicyStatus.expired: return Colors.grey;
      case PolicyStatus.cancelled: return Colors.red;
      case PolicyStatus.claimed: return Colors.blue;
    }
  }

  static PolicyStatus fromString(String? s) {
    switch (s) {
      case 'active': return PolicyStatus.active;
      case 'pending_payment': return PolicyStatus.pendingPayment;
      case 'expired': return PolicyStatus.expired;
      case 'cancelled': return PolicyStatus.cancelled;
      case 'claimed': return PolicyStatus.claimed;
      default: return PolicyStatus.active;
    }
  }
}

class InsurancePolicy {
  final int id;
  final String policyNumber;
  final int userId;
  final int productId;
  final String productName;
  final String providerName;
  final InsuranceCategory category;
  final PolicyStatus status;
  final double premiumAmount;
  final String premiumFrequency; // monthly, annual
  final double coverLimit;
  final DateTime startDate;
  final DateTime endDate;
  final DateTime? nextPaymentDate;
  final String? beneficiaryName;
  final int? linkedModuleId; // e.g. loan ID for credit life
  final String? linkedModule; // e.g. 'loan', 'shop_order'

  InsurancePolicy({
    required this.id,
    required this.policyNumber,
    required this.userId,
    required this.productId,
    required this.productName,
    required this.providerName,
    required this.category,
    required this.status,
    required this.premiumAmount,
    required this.premiumFrequency,
    required this.coverLimit,
    required this.startDate,
    required this.endDate,
    this.nextPaymentDate,
    this.beneficiaryName,
    this.linkedModuleId,
    this.linkedModule,
  });

  factory InsurancePolicy.fromJson(Map<String, dynamic> json) {
    return InsurancePolicy(
      id: json['id'] ?? 0,
      policyNumber: json['policy_number'] ?? '',
      userId: json['user_id'] ?? 0,
      productId: json['product_id'] ?? 0,
      productName: json['product_name'] ?? '',
      providerName: json['provider_name'] ?? '',
      category: InsuranceCategory.fromString(json['category']),
      status: PolicyStatus.fromString(json['status']),
      premiumAmount: (json['premium_amount'] as num?)?.toDouble() ?? 0,
      premiumFrequency: json['premium_frequency'] ?? 'monthly',
      coverLimit: (json['cover_limit'] as num?)?.toDouble() ?? 0,
      startDate: DateTime.parse(json['start_date'] ?? DateTime.now().toIso8601String()),
      endDate: DateTime.parse(json['end_date'] ?? DateTime.now().toIso8601String()),
      nextPaymentDate: json['next_payment_date'] != null ? DateTime.tryParse(json['next_payment_date']) : null,
      beneficiaryName: json['beneficiary_name'],
      linkedModuleId: (json['linked_module_id'] as num?)?.toInt(),
      linkedModule: json['linked_module'],
    );
  }

  bool get isActive => status == PolicyStatus.active;
  int get daysRemaining => endDate.difference(DateTime.now()).inDays;
  bool get isExpiringSoon => daysRemaining > 0 && daysRemaining <= 30;
}

// ─── Claims ─────────────────────────────────────────────────────

enum ClaimStatus {
  submitted,
  underReview,
  approved,
  rejected,
  paid;

  String get displayName {
    switch (this) {
      case ClaimStatus.submitted: return 'Imetumwa';
      case ClaimStatus.underReview: return 'Inakaguliwa';
      case ClaimStatus.approved: return 'Imekubaliwa';
      case ClaimStatus.rejected: return 'Imekataliwa';
      case ClaimStatus.paid: return 'Imelipwa';
    }
  }

  Color get color {
    switch (this) {
      case ClaimStatus.submitted: return Colors.orange;
      case ClaimStatus.underReview: return Colors.blue;
      case ClaimStatus.approved: return const Color(0xFF4CAF50);
      case ClaimStatus.rejected: return Colors.red;
      case ClaimStatus.paid: return const Color(0xFF4CAF50);
    }
  }

  static ClaimStatus fromString(String? s) {
    switch (s) {
      case 'submitted': return ClaimStatus.submitted;
      case 'under_review': return ClaimStatus.underReview;
      case 'approved': return ClaimStatus.approved;
      case 'rejected': return ClaimStatus.rejected;
      case 'paid': return ClaimStatus.paid;
      default: return ClaimStatus.submitted;
    }
  }
}

class InsuranceClaim {
  final int id;
  final String claimNumber;
  final int policyId;
  final String policyNumber;
  final String productName;
  final ClaimStatus status;
  final double claimAmount;
  final double? approvedAmount;
  final String reason;
  final String? description;
  final DateTime submittedAt;
  final DateTime? resolvedAt;
  final String? rejectionReason;

  InsuranceClaim({
    required this.id,
    required this.claimNumber,
    required this.policyId,
    required this.policyNumber,
    required this.productName,
    required this.status,
    required this.claimAmount,
    this.approvedAmount,
    required this.reason,
    this.description,
    required this.submittedAt,
    this.resolvedAt,
    this.rejectionReason,
  });

  factory InsuranceClaim.fromJson(Map<String, dynamic> json) {
    return InsuranceClaim(
      id: json['id'] ?? 0,
      claimNumber: json['claim_number'] ?? '',
      policyId: json['policy_id'] ?? 0,
      policyNumber: json['policy_number'] ?? '',
      productName: json['product_name'] ?? '',
      status: ClaimStatus.fromString(json['status']),
      claimAmount: (json['claim_amount'] as num?)?.toDouble() ?? 0,
      approvedAmount: (json['approved_amount'] as num?)?.toDouble(),
      reason: json['reason'] ?? '',
      description: json['description'],
      submittedAt: DateTime.parse(json['submitted_at'] ?? DateTime.now().toIso8601String()),
      resolvedAt: json['resolved_at'] != null ? DateTime.tryParse(json['resolved_at']) : null,
      rejectionReason: json['rejection_reason'],
    );
  }
}

// ─── Result wrappers ────────────────────────────────────────────

class InsuranceResult<T> {
  final bool success;
  final T? data;
  final String? message;
  InsuranceResult({required this.success, this.data, this.message});
}

class InsuranceListResult<T> {
  final bool success;
  final List<T> items;
  final String? message;
  InsuranceListResult({required this.success, this.items = const [], this.message});
}
