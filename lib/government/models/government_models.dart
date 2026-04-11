// lib/government/models/government_models.dart
import 'package:flutter/material.dart';

// ─── Service Categories ────────────────────────────────────────

enum GovtServiceCategory {
  identity,
  tax,
  business,
  socialSecurity,
  health,
  land,
  education;

  String get displayName {
    switch (this) {
      case GovtServiceCategory.identity: return 'Kitambulisho';
      case GovtServiceCategory.tax: return 'Kodi';
      case GovtServiceCategory.business: return 'Biashara';
      case GovtServiceCategory.socialSecurity: return 'Hifadhi ya Jamii';
      case GovtServiceCategory.health: return 'Afya';
      case GovtServiceCategory.land: return 'Ardhi';
      case GovtServiceCategory.education: return 'Elimu';
    }
  }

  String get subtitle {
    switch (this) {
      case GovtServiceCategory.identity: return 'Identity';
      case GovtServiceCategory.tax: return 'Tax';
      case GovtServiceCategory.business: return 'Business';
      case GovtServiceCategory.socialSecurity: return 'Social Security';
      case GovtServiceCategory.health: return 'Health';
      case GovtServiceCategory.land: return 'Land';
      case GovtServiceCategory.education: return 'Education';
    }
  }

  IconData get icon {
    switch (this) {
      case GovtServiceCategory.identity: return Icons.badge_rounded;
      case GovtServiceCategory.tax: return Icons.receipt_long_rounded;
      case GovtServiceCategory.business: return Icons.business_rounded;
      case GovtServiceCategory.socialSecurity: return Icons.shield_rounded;
      case GovtServiceCategory.health: return Icons.health_and_safety_rounded;
      case GovtServiceCategory.land: return Icons.landscape_rounded;
      case GovtServiceCategory.education: return Icons.school_rounded;
    }
  }

  static GovtServiceCategory fromString(String? s) {
    return GovtServiceCategory.values.firstWhere(
      (v) => v.name == s,
      orElse: () => GovtServiceCategory.identity,
    );
  }
}

// ─── Government Service ────────────────────────────────────────

class GovtService {
  final int id;
  final String name;
  final String description;
  final String iconName;
  final String? url;
  final GovtServiceCategory category;

  GovtService({
    required this.id,
    required this.name,
    required this.description,
    required this.iconName,
    this.url,
    required this.category,
  });

  factory GovtService.fromJson(Map<String, dynamic> json) {
    return GovtService(
      id: json['id'] ?? 0,
      name: json['name'] ?? '',
      description: json['description'] ?? '',
      iconName: json['icon_name'] ?? 'public',
      url: json['url'],
      category: GovtServiceCategory.fromString(json['category']),
    );
  }
}

// ─── Government Query ──────────────────────────────────────────

class GovtQuery {
  final int id;
  final int userId;
  final String serviceType;
  final String query;
  final String? result;
  final String? status;
  final DateTime createdAt;

  GovtQuery({
    required this.id,
    required this.userId,
    required this.serviceType,
    required this.query,
    this.result,
    this.status,
    required this.createdAt,
  });

  factory GovtQuery.fromJson(Map<String, dynamic> json) {
    return GovtQuery(
      id: json['id'] ?? 0,
      userId: json['user_id'] ?? 0,
      serviceType: json['service_type'] ?? '',
      query: json['query'] ?? '',
      result: json['result'],
      status: json['status'],
      createdAt: DateTime.parse(json['created_at'] ?? DateTime.now().toIso8601String()),
    );
  }

  bool get isSuccess => status == 'success';
  bool get isPending => status == 'pending';
}

// ─── NIDA Info ─────────────────────────────────────────────────

class NidaInfo {
  final String number;
  final String? fullName;
  final String? dateOfBirth;
  final String? gender;
  final String status;
  final DateTime? verifiedAt;

  NidaInfo({
    required this.number,
    this.fullName,
    this.dateOfBirth,
    this.gender,
    required this.status,
    this.verifiedAt,
  });

  factory NidaInfo.fromJson(Map<String, dynamic> json) {
    return NidaInfo(
      number: json['number'] ?? '',
      fullName: json['full_name'],
      dateOfBirth: json['date_of_birth'],
      gender: json['gender'],
      status: json['status'] ?? 'unknown',
      verifiedAt: json['verified_at'] != null ? DateTime.parse(json['verified_at']) : null,
    );
  }

  bool get isVerified => status == 'verified';
  bool get isActive => status == 'active';
}

// ─── TIN Info ──────────────────────────────────────────────────

class TinInfo {
  final String number;
  final String? businessName;
  final String? ownerName;
  final String status;
  final String? taxType;
  final DateTime? registeredAt;

  TinInfo({
    required this.number,
    this.businessName,
    this.ownerName,
    required this.status,
    this.taxType,
    this.registeredAt,
  });

  factory TinInfo.fromJson(Map<String, dynamic> json) {
    return TinInfo(
      number: json['number'] ?? '',
      businessName: json['business_name'],
      ownerName: json['owner_name'],
      status: json['status'] ?? 'unknown',
      taxType: json['tax_type'],
      registeredAt: json['registered_at'] != null ? DateTime.parse(json['registered_at']) : null,
    );
  }

  bool get isCompliant => status == 'compliant';
}

// ─── BRELA Info ────────────────────────────────────────────────

class BrelaInfo {
  final String businessName;
  final String? registrationNumber;
  final String status;
  final String? businessType;
  final DateTime? registeredAt;

  BrelaInfo({
    required this.businessName,
    this.registrationNumber,
    required this.status,
    this.businessType,
    this.registeredAt,
  });

  factory BrelaInfo.fromJson(Map<String, dynamic> json) {
    return BrelaInfo(
      businessName: json['business_name'] ?? '',
      registrationNumber: json['registration_number'],
      status: json['status'] ?? 'unknown',
      businessType: json['business_type'],
      registeredAt: json['registered_at'] != null ? DateTime.parse(json['registered_at']) : null,
    );
  }

  bool get isRegistered => status == 'registered' || status == 'active';
}

// ─── NSSF Info ─────────────────────────────────────────────────

class NssfInfo {
  final String memberNumber;
  final String? memberName;
  final String status;
  final double totalContributions;
  final int monthsContributed;
  final String? employer;

  NssfInfo({
    required this.memberNumber,
    this.memberName,
    required this.status,
    this.totalContributions = 0,
    this.monthsContributed = 0,
    this.employer,
  });

  factory NssfInfo.fromJson(Map<String, dynamic> json) {
    return NssfInfo(
      memberNumber: json['member_number'] ?? '',
      memberName: json['member_name'],
      status: json['status'] ?? 'unknown',
      totalContributions: (json['total_contributions'] as num?)?.toDouble() ?? 0,
      monthsContributed: (json['months_contributed'] as num?)?.toInt() ?? 0,
      employer: json['employer'],
    );
  }

  bool get isActive => status == 'active';
}

// ─── NHIF Info ─────────────────────────────────────────────────

class NhifInfo {
  final String memberNumber;
  final String? memberName;
  final String status;
  final String? packageType;
  final DateTime? expiresAt;
  final int dependants;

  NhifInfo({
    required this.memberNumber,
    this.memberName,
    required this.status,
    this.packageType,
    this.expiresAt,
    this.dependants = 0,
  });

  factory NhifInfo.fromJson(Map<String, dynamic> json) {
    return NhifInfo(
      memberNumber: json['member_number'] ?? '',
      memberName: json['member_name'],
      status: json['status'] ?? 'unknown',
      packageType: json['package_type'],
      expiresAt: json['expires_at'] != null ? DateTime.parse(json['expires_at']) : null,
      dependants: (json['dependants'] as num?)?.toInt() ?? 0,
    );
  }

  bool get isActive => status == 'active';
  bool get isExpired => expiresAt != null && expiresAt!.isBefore(DateTime.now());
}

// ─── Result wrappers ───────────────────────────────────────────

class GovtResult<T> {
  final bool success;
  final T? data;
  final String? message;
  GovtResult({required this.success, this.data, this.message});
}

class GovtListResult<T> {
  final bool success;
  final List<T> items;
  final String? message;
  GovtListResult({required this.success, this.items = const [], this.message});
}
