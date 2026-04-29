import 'dart:convert';

import '../../config/api_config.dart';

enum BeneficiaryOrgType {
  yatima,
  jumuiya,
  msikiti,
  kanisa,
  ngo,
  kikundi,
  shuleYaKula,
}

extension BeneficiaryOrgTypeX on BeneficiaryOrgType {
  String get apiValue {
    switch (this) {
      case BeneficiaryOrgType.yatima:
        return 'yatima';
      case BeneficiaryOrgType.jumuiya:
        return 'jumuiya';
      case BeneficiaryOrgType.msikiti:
        return 'msikiti';
      case BeneficiaryOrgType.kanisa:
        return 'kanisa';
      case BeneficiaryOrgType.ngo:
        return 'ngo';
      case BeneficiaryOrgType.kikundi:
        return 'kikundi';
      case BeneficiaryOrgType.shuleYaKula:
        return 'shule_ya_kula';
    }
  }

  String get labelSwahili {
    switch (this) {
      case BeneficiaryOrgType.yatima:
        return 'Yatima';
      case BeneficiaryOrgType.jumuiya:
        return 'Jumuiya';
      case BeneficiaryOrgType.msikiti:
        return 'Msikiti';
      case BeneficiaryOrgType.kanisa:
        return 'Kanisa';
      case BeneficiaryOrgType.ngo:
        return 'NGO';
      case BeneficiaryOrgType.kikundi:
        return 'Kikundi';
      case BeneficiaryOrgType.shuleYaKula:
        return 'Shule ya kula';
    }
  }

  static BeneficiaryOrgType fromString(String? s) {
    switch (s) {
      case 'yatima':
        return BeneficiaryOrgType.yatima;
      case 'jumuiya':
        return BeneficiaryOrgType.jumuiya;
      case 'msikiti':
        return BeneficiaryOrgType.msikiti;
      case 'kanisa':
        return BeneficiaryOrgType.kanisa;
      case 'ngo':
        return BeneficiaryOrgType.ngo;
      case 'kikundi':
        return BeneficiaryOrgType.kikundi;
      case 'shule_ya_kula':
        return BeneficiaryOrgType.shuleYaKula;
      default:
        return BeneficiaryOrgType.jumuiya;
    }
  }
}

class BeneficiaryOrg {
  final int id;
  final int userId;
  final String name;
  final BeneficiaryOrgType type;
  final String? description;
  final String? registrationNumber;
  final String? registrationAuthority;
  final String? certificateUrl;
  final String? region;
  final String? district;
  final String? ward;
  final String? street;
  final int? populationServed;
  final int? mealsPerWeek;
  final String? phone;
  final String? photoUrl;
  final String status;
  final String? rejectionReason;
  final int portionsReceivedMonth;
  final int portionsReceivedYear;
  final int uniqueDonorsCount;

  BeneficiaryOrg({
    required this.id,
    required this.userId,
    required this.name,
    required this.type,
    required this.description,
    required this.registrationNumber,
    required this.registrationAuthority,
    required this.certificateUrl,
    required this.region,
    required this.district,
    required this.ward,
    required this.street,
    required this.populationServed,
    required this.mealsPerWeek,
    required this.phone,
    required this.photoUrl,
    required this.status,
    required this.rejectionReason,
    required this.portionsReceivedMonth,
    required this.portionsReceivedYear,
    required this.uniqueDonorsCount,
  });

  String get locationText {
    final parts = [ward, district, region].where((p) => p != null && p.trim().isNotEmpty).cast<String>().toList();
    return parts.join(', ');
  }

  bool get isVerified => status == 'verified';
  bool get isPending => status == 'pending';
  bool get isRejected => status == 'rejected';

  String get resolvedPhotoUrl {
    final p = photoUrl ?? '';
    if (p.isEmpty) return '';
    if (p.startsWith('http')) return ApiConfig.sanitizeUrl(p) ?? '';
    return ApiConfig.sanitizeUrl('${ApiConfig.storageUrl}/$p') ?? '';
  }

  factory BeneficiaryOrg.fromJson(Map<String, dynamic> json) {
    return BeneficiaryOrg(
      id: _parseInt(json['id']) ?? 0,
      userId: _parseInt(json['user_id']) ?? 0,
      name: json['name']?.toString() ?? '',
      type: BeneficiaryOrgTypeX.fromString(json['type']?.toString()),
      description: json['description']?.toString(),
      registrationNumber: json['registration_number']?.toString(),
      registrationAuthority: json['registration_authority']?.toString(),
      certificateUrl: json['certificate_url']?.toString(),
      region: json['region']?.toString(),
      district: json['district']?.toString(),
      ward: json['ward']?.toString(),
      street: json['street']?.toString(),
      populationServed: _parseInt(json['population_served']),
      mealsPerWeek: _parseInt(json['meals_per_week']),
      phone: json['phone']?.toString(),
      photoUrl: json['photo_url']?.toString(),
      status: json['status']?.toString() ?? 'pending',
      rejectionReason: json['rejection_reason']?.toString(),
      portionsReceivedMonth: _parseInt(json['portions_received_month']) ?? 0,
      portionsReceivedYear: _parseInt(json['portions_received_year']) ?? 0,
      uniqueDonorsCount: _parseInt(json['unique_donors_count']) ?? 0,
    );
  }
}

class BeneficiaryNeed {
  final int id;
  final int orgId;
  final String title;
  final String? description;
  final int portionsNeeded;
  final int portionsFulfilled;
  final DateTime? dueDate;
  final bool isFulfilled;
  final String needType;
  final String? mealType;
  final List<int> daysOfWeek;
  final String deliveryMode;
  final List<String> dietaryConstraints;
  final int? durationWeeks;
  final bool isPaused;

  BeneficiaryNeed({
    required this.id,
    required this.orgId,
    required this.title,
    required this.description,
    required this.portionsNeeded,
    required this.portionsFulfilled,
    required this.dueDate,
    required this.isFulfilled,
    required this.needType,
    required this.mealType,
    required this.daysOfWeek,
    required this.deliveryMode,
    required this.dietaryConstraints,
    required this.durationWeeks,
    required this.isPaused,
  });

  int get portionsRemaining => (portionsNeeded - portionsFulfilled).clamp(0, portionsNeeded);
  bool get isRecurring => needType == 'recurring';

  factory BeneficiaryNeed.fromJson(Map<String, dynamic> json) {
    final daysRaw = json['days_of_week'];
    final days = <int>[];
    if (daysRaw is String && daysRaw.isNotEmpty) {
      try {
        final decoded = jsonDecode(daysRaw);
        if (decoded is List) {
          for (final d in decoded) {
            final v = _parseInt(d);
            if (v != null) days.add(v);
          }
        }
      } catch (_) {}
    } else if (daysRaw is List) {
      for (final d in daysRaw) {
        final v = _parseInt(d);
        if (v != null) days.add(v);
      }
    }
    final dietRaw = json['dietary_constraints'];
    final diet = <String>[];
    if (dietRaw is String && dietRaw.isNotEmpty) {
      try {
        final decoded = jsonDecode(dietRaw);
        if (decoded is List) {
          for (final d in decoded) {
            if (d != null) diet.add(d.toString());
          }
        }
      } catch (_) {}
    } else if (dietRaw is List) {
      for (final d in dietRaw) {
        if (d != null) diet.add(d.toString());
      }
    }
    return BeneficiaryNeed(
      id: _parseInt(json['id']) ?? 0,
      orgId: _parseInt(json['org_id']) ?? 0,
      title: json['title']?.toString() ?? '',
      description: json['description']?.toString(),
      portionsNeeded: _parseInt(json['portions_needed']) ?? 0,
      portionsFulfilled: _parseInt(json['portions_fulfilled']) ?? 0,
      dueDate: json['due_date'] == null ? null : DateTime.tryParse(json['due_date'].toString()),
      isFulfilled: json['is_fulfilled'] == true || json['is_fulfilled'] == 1,
      needType: json['need_type']?.toString() ?? 'one_off',
      mealType: json['meal_type']?.toString(),
      daysOfWeek: days,
      deliveryMode: json['delivery_mode']?.toString() ?? 'either',
      dietaryConstraints: diet,
      durationWeeks: _parseInt(json['duration_weeks']),
      isPaused: json['is_paused'] == true || json['is_paused'] == 1,
    );
  }
}

int? _parseInt(dynamic v) {
  if (v == null) return null;
  if (v is int) return v;
  if (v is num) return v.toInt();
  if (v is String) return int.tryParse(v);
  return null;
}
