// lib/my_baby/models/my_baby_models.dart

import 'package:flutter/material.dart';
import '../../config/api_config.dart';

// ─── Baby ──────────────────────────────────────────────────────

class Baby {
  final int id;
  final int userId;
  final String name;
  final DateTime dateOfBirth;
  final String? gender; // male, female
  final int? birthWeightGrams;
  final double? birthLengthCm;

  Baby({
    required this.id,
    required this.userId,
    required this.name,
    required this.dateOfBirth,
    this.gender,
    this.birthWeightGrams,
    this.birthLengthCm,
  });

  factory Baby.fromJson(Map<String, dynamic> json) {
    return Baby(
      id: _parseInt(json['id']),
      userId: _parseInt(json['user_id']),
      name: json['name'] as String? ?? '',
      dateOfBirth:
          _parseDate(json['date_of_birth']) ?? DateTime.now(),
      gender: json['gender'] as String?,
      birthWeightGrams: json['birth_weight_grams'] != null
          ? _parseInt(json['birth_weight_grams'])
          : null,
      birthLengthCm: json['birth_length_cm'] != null
          ? _parseDouble(json['birth_length_cm'])
          : null,
    );
  }

  Map<String, dynamic> toJson() => {
        'user_id': userId,
        'name': name,
        'date_of_birth': dateOfBirth.toIso8601String(),
        if (gender != null) 'gender': gender,
        if (birthWeightGrams != null) 'birth_weight_grams': birthWeightGrams,
        if (birthLengthCm != null) 'birth_length_cm': birthLengthCm,
      };

  int get ageInDays => DateTime.now().difference(dateOfBirth).inDays;
  int get ageInMonths => (ageInDays / 30.44).floor();
  int get ageInWeeks => (ageInDays / 7).floor();

  String get ageLabel => ageLabelLocalized(isSwahili: true);

  String ageLabelLocalized({bool isSwahili = true}) {
    if (isSwahili) {
      if (ageInDays < 7) return 'Siku $ageInDays';
      if (ageInDays < 30) return 'Wiki $ageInWeeks';
      if (ageInMonths < 24) return 'Miezi $ageInMonths';
      return 'Miaka ${(ageInMonths / 12).floor()}';
    } else {
      if (ageInDays < 7) return '$ageInDays days';
      if (ageInDays < 30) return '$ageInWeeks weeks';
      if (ageInMonths < 24) return '$ageInMonths months';
      return '${(ageInMonths / 12).floor()} years';
    }
  }
}

// ─── Vaccination ───────────────────────────────────────────────

class Vaccination {
  final int id;
  final int babyId;
  final String name;
  final String swahiliName;
  final DateTime? dueDate;
  final DateTime? givenDate;
  final bool isDone;
  final String ageLabel;
  final int? dueAgeDays;

  Vaccination({
    required this.id,
    this.babyId = 0,
    required this.name,
    required this.swahiliName,
    this.dueDate,
    this.givenDate,
    this.isDone = false,
    required this.ageLabel,
    this.dueAgeDays,
  });

  factory Vaccination.fromJson(Map<String, dynamic> json) {
    return Vaccination(
      id: _parseInt(json['id']),
      babyId: _parseInt(json['baby_id']),
      name: json['name'] as String? ?? '',
      swahiliName: json['swahili_name'] as String? ?? '',
      dueDate: _parseDate(json['due_date']),
      givenDate: _parseDate(json['given_date']),
      isDone: _parseBool(json['is_done']),
      ageLabel: json['age_label'] as String? ?? '',
      dueAgeDays: json['due_age_days'] != null ? _parseInt(json['due_age_days']) : null,
    );
  }

  /// Compute effective due date: use server-provided dueDate, or calculate from baby DOB + dueAgeDays.
  DateTime? effectiveDueDate(DateTime? babyDob) {
    if (dueDate != null) return dueDate;
    if (babyDob != null && dueAgeDays != null) {
      return babyDob.add(Duration(days: dueAgeDays!));
    }
    return null;
  }

  bool get isOverdue =>
      !isDone && dueDate != null && dueDate!.isBefore(DateTime.now());

  /// Check overdue using effective due date (with baby DOB fallback).
  bool isOverdueWithDob(DateTime? babyDob) {
    final effective = effectiveDueDate(babyDob);
    return !isDone && effective != null && effective.isBefore(DateTime.now());
  }
}

// ─── Baby Milestone ────────────────────────────────────────────

class BabyMilestone {
  final int id;
  final int babyId;
  final String title;
  final String? description;
  final int ageMonths;
  final bool isDone;
  final DateTime? completedDate;

  BabyMilestone({
    required this.id,
    this.babyId = 0,
    required this.title,
    this.description,
    required this.ageMonths,
    this.isDone = false,
    this.completedDate,
  });

  factory BabyMilestone.fromJson(Map<String, dynamic> json) {
    return BabyMilestone(
      id: _parseInt(json['id']),
      babyId: _parseInt(json['baby_id']),
      title: json['title'] as String? ?? '',
      description: json['description'] as String?,
      ageMonths: _parseInt(json['age_months']),
      isDone: _parseBool(json['is_done']),
      completedDate: _parseDate(json['completed_date']),
    );
  }
}

// ─── Feeding Log ───────────────────────────────────────────────

enum FeedingType {
  breast,
  bottle,
  solid;

  String get swahiliName {
    switch (this) {
      case FeedingType.breast:
        return 'Kunyonyesha';
      case FeedingType.bottle:
        return 'Chupa';
      case FeedingType.solid:
        return 'Chakula Kigumu';
    }
  }

  String get englishName {
    switch (this) {
      case FeedingType.breast:
        return 'Breastfeeding';
      case FeedingType.bottle:
        return 'Bottle';
      case FeedingType.solid:
        return 'Solid Food';
    }
  }

  String localizedName({bool isSwahili = true}) =>
      isSwahili ? swahiliName : englishName;
}

enum BreastSide {
  left,
  right;

  String get swahiliName {
    switch (this) {
      case BreastSide.left:
        return 'Kushoto';
      case BreastSide.right:
        return 'Kulia';
    }
  }

  String get englishName {
    switch (this) {
      case BreastSide.left:
        return 'Left';
      case BreastSide.right:
        return 'Right';
    }
  }

  String localizedName({bool isSwahili = true}) =>
      isSwahili ? swahiliName : englishName;
}

class FeedingLog {
  final int id;
  final int babyId;
  final FeedingType type;
  final BreastSide? side;
  final int? durationMinutes;
  final double? amountMl;
  final String? foodDescription;
  final DateTime date;
  final int? loggedBy;

  FeedingLog({
    required this.id,
    this.babyId = 0,
    required this.type,
    this.side,
    this.durationMinutes,
    this.amountMl,
    this.foodDescription,
    required this.date,
    this.loggedBy,
  });

  factory FeedingLog.fromJson(Map<String, dynamic> json) {
    return FeedingLog(
      id: _parseInt(json['id']),
      babyId: _parseInt(json['baby_id']),
      type: FeedingType.values.firstWhere(
        (t) => t.name == json['type'],
        orElse: () => FeedingType.breast,
      ),
      side: json['side'] != null
          ? BreastSide.values.firstWhere(
              (s) => s.name == json['side'],
              orElse: () => BreastSide.left,
            )
          : null,
      durationMinutes: json['duration_minutes'] != null
          ? _parseInt(json['duration_minutes'])
          : null,
      amountMl: json['amount_ml'] != null
          ? _parseDouble(json['amount_ml'])
          : null,
      foodDescription: json['food_description'] as String?,
      date: _parseDate(json['date']) ?? DateTime.now(),
      loggedBy: json['logged_by'] != null ? _parseInt(json['logged_by']) : null,
    );
  }

  Map<String, dynamic> toJson() => {
        'baby_id': babyId,
        'type': type.name,
        if (side != null) 'side': side!.name,
        if (durationMinutes != null) 'duration_minutes': durationMinutes,
        if (amountMl != null) 'amount_ml': amountMl,
        if (foodDescription != null) 'food_description': foodDescription,
        'date': date.toIso8601String(),
      };
}

// ─── Sleep Session ─────────────────────────────────────────────

class SleepSession {
  final int? id;
  final int babyId;
  final DateTime startTime;
  final DateTime? endTime;
  final int? durationMinutes;
  final String type; // 'nap' or 'night'
  final String? notes;
  final int? loggedBy;

  SleepSession({
    this.id,
    required this.babyId,
    required this.startTime,
    this.endTime,
    this.durationMinutes,
    required this.type,
    this.notes,
    this.loggedBy,
  });

  bool get isActive => endTime == null;

  String get durationText {
    final mins = durationMinutes ??
        (endTime != null ? endTime!.difference(startTime).inMinutes : DateTime.now().difference(startTime).inMinutes);
    if (mins < 60) return '${mins}m';
    final h = mins ~/ 60;
    final m = mins % 60;
    return m > 0 ? '${h}h ${m}m' : '${h}h';
  }

  factory SleepSession.fromJson(Map<String, dynamic> json) {
    return SleepSession(
      id: json['id'] != null ? _parseInt(json['id']) : null,
      babyId: _parseInt(json['baby_id']),
      startTime: _parseDate(json['start_time']) ?? DateTime.now(),
      endTime: _parseDate(json['end_time']),
      durationMinutes: json['duration_minutes'] != null
          ? _parseInt(json['duration_minutes'])
          : null,
      type: json['type'] as String? ?? 'nap',
      notes: json['notes'] as String?,
      loggedBy: json['logged_by'] != null ? _parseInt(json['logged_by']) : null,
    );
  }

  Map<String, dynamic> toJson() => {
        'baby_id': babyId,
        'start_time': startTime.toIso8601String(),
        if (endTime != null) 'end_time': endTime!.toIso8601String(),
        'type': type,
        if (notes != null) 'notes': notes,
      };
}

// ─── Diaper Log ────────────────────────────────────────────────

class DiaperLog {
  final int? id;
  final int babyId;
  final String type; // 'wet', 'dirty', 'both'
  final String? color; // optional stool color
  final String? notes;
  final DateTime loggedAt;
  final int? loggedBy;

  DiaperLog({
    this.id,
    required this.babyId,
    required this.type,
    this.color,
    this.notes,
    required this.loggedAt,
    this.loggedBy,
  });

  factory DiaperLog.fromJson(Map<String, dynamic> json) {
    return DiaperLog(
      id: json['id'] != null ? _parseInt(json['id']) : null,
      babyId: _parseInt(json['baby_id']),
      type: json['type'] as String? ?? 'wet',
      color: json['color'] as String? ?? json['stool_color'] as String?,
      notes: json['notes'] as String?,
      loggedAt: _parseDate(json['logged_at']) ?? DateTime.now(),
      loggedBy: json['logged_by'] != null ? _parseInt(json['logged_by']) : null,
    );
  }

  Map<String, dynamic> toJson() => {
        'baby_id': babyId,
        'type': type,
        if (color != null) 'stool_color': color,
        if (notes != null) 'notes': notes,
        'logged_at': loggedAt.toIso8601String(),
      };
}

// ─── Growth Measurement ────────────────────────────────────────

class GrowthMeasurement {
  final int? id;
  final int babyId;
  final double? weightKg;
  final double? heightCm;
  final double? headCm;
  final DateTime measuredAt;
  final String? notes;

  GrowthMeasurement({
    this.id,
    required this.babyId,
    this.weightKg,
    this.heightCm,
    this.headCm,
    required this.measuredAt,
    this.notes,
  });

  factory GrowthMeasurement.fromJson(Map<String, dynamic> json) {
    // Backend stores weight in grams, convert to kg
    double? wKg;
    if (json['weight_kg'] != null) {
      wKg = _parseDouble(json['weight_kg']);
    } else if (json['weight_grams'] != null) {
      wKg = _parseDouble(json['weight_grams']) / 1000.0;
    }

    return GrowthMeasurement(
      id: json['id'] != null ? _parseInt(json['id']) : null,
      babyId: _parseInt(json['baby_id']),
      weightKg: wKg,
      heightCm: json['height_cm'] != null
          ? _parseDouble(json['height_cm'])
          : null,
      headCm: json['head_circumference_cm'] != null
          ? _parseDouble(json['head_circumference_cm'])
          : (json['head_cm'] != null ? _parseDouble(json['head_cm']) : null),
      measuredAt: _parseDate(json['measured_at']) ?? DateTime.now(),
      notes: json['notes'] as String?,
    );
  }

  Map<String, dynamic> toJson() => {
        'baby_id': babyId,
        if (weightKg != null) 'weight_kg': weightKg,
        if (heightCm != null) 'height_cm': heightCm,
        if (headCm != null) 'head_circumference_cm': headCm,
        'measured_at': measuredAt.toIso8601String(),
        if (notes != null) 'notes': notes,
      };
}

// ─── Health Log ────────────────────────────────────────────────

class HealthLog {
  final int? id;
  final int babyId;
  final String type; // 'temperature', 'medication', 'illness', 'allergy', 'doctor_visit'
  final String title;
  final String? value; // e.g., "38.5C" for temperature
  final String? description;
  final DateTime loggedAt;

  HealthLog({
    this.id,
    required this.babyId,
    required this.type,
    required this.title,
    this.value,
    this.description,
    required this.loggedAt,
  });

  IconData get icon {
    switch (type) {
      case 'temperature':
        return Icons.thermostat_rounded;
      case 'medication':
        return Icons.medication_rounded;
      case 'illness':
        return Icons.sick_rounded;
      case 'allergy':
        return Icons.warning_amber_rounded;
      case 'doctor_visit':
        return Icons.local_hospital_rounded;
      default:
        return Icons.health_and_safety_rounded;
    }
  }

  factory HealthLog.fromJson(Map<String, dynamic> json) {
    return HealthLog(
      id: json['id'] != null ? _parseInt(json['id']) : null,
      babyId: _parseInt(json['baby_id']),
      type: json['type'] as String? ?? 'illness',
      title: json['title'] as String? ?? '',
      value: json['value'] as String?,
      description: json['description'] as String?,
      loggedAt: _parseDate(json['logged_at']) ??
          _parseDate(json['start_date']) ??
          DateTime.now(),
    );
  }

  Map<String, dynamic> toJson() => {
        'baby_id': babyId,
        'type': type,
        'title': title,
        if (value != null) 'value': value,
        if (description != null) 'description': description,
        'logged_at': loggedAt.toIso8601String(),
      };
}

// ─── Baby Photo ────────────────────────────────────────────────

class BabyPhoto {
  final int? id;
  final int babyId;
  final String photoPath;
  final String? caption;
  final int? milestoneId;
  final String type; // 'monthly', 'milestone', 'memory'
  final int? monthNumber;
  final DateTime createdAt;

  BabyPhoto({
    this.id,
    required this.babyId,
    required this.photoPath,
    this.caption,
    this.milestoneId,
    required this.type,
    this.monthNumber,
    required this.createdAt,
  });

  String get displayUrl {
    if (photoPath.startsWith('http')) return photoPath;
    final clean = photoPath.startsWith('/') ? photoPath.substring(1) : photoPath;
    return '${ApiConfig.storageUrl}/$clean';
  }

  factory BabyPhoto.fromJson(Map<String, dynamic> json) {
    return BabyPhoto(
      id: json['id'] != null ? _parseInt(json['id']) : null,
      babyId: _parseInt(json['baby_id']),
      photoPath: json['photo_path'] as String? ?? json['photo_url'] as String? ?? '',
      caption: json['caption'] as String?,
      milestoneId: json['milestone_id'] != null
          ? _parseInt(json['milestone_id'])
          : null,
      type: json['type'] as String? ?? json['category'] as String? ?? 'memory',
      monthNumber: json['month_number'] != null
          ? _parseInt(json['month_number'])
          : null,
      createdAt: _parseDate(json['created_at']) ?? DateTime.now(),
    );
  }
}

// ─── Caregiver Share ───────────────────────────────────────────

class CaregiverShare {
  final int? id;
  final int babyId;
  final int ownerUserId;
  final int? caregiverUserId;
  final String inviteCode;
  final String role; // 'caregiver', 'viewer'
  final String status; // 'pending', 'accepted', 'revoked'
  final String? caregiverName;
  final String? caregiverPhoto;

  CaregiverShare({
    this.id,
    required this.babyId,
    required this.ownerUserId,
    this.caregiverUserId,
    required this.inviteCode,
    required this.role,
    required this.status,
    this.caregiverName,
    this.caregiverPhoto,
  });

  factory CaregiverShare.fromJson(Map<String, dynamic> json) {
    return CaregiverShare(
      id: json['id'] != null ? _parseInt(json['id']) : null,
      babyId: _parseInt(json['baby_id']),
      ownerUserId: _parseInt(json['owner_user_id']),
      caregiverUserId: json['caregiver_user_id'] != null
          ? _parseInt(json['caregiver_user_id'])
          : null,
      inviteCode: json['invite_code'] as String? ?? '',
      role: json['role'] as String? ?? 'viewer',
      status: json['status'] as String? ?? 'pending',
      caregiverName: json['caregiver_name'] as String?,
      caregiverPhoto: json['caregiver_photo'] as String?,
    );
  }
}

// ─── Daily Summary ─────────────────────────────────────────────

class DailySummary {
  final int feedCount;
  final int totalFeedingMinutes;
  final int totalBottleMl;
  final int sleepMinutes;
  final int napCount;
  final int diaperWet;
  final int diaperDirty;

  DailySummary({
    required this.feedCount,
    required this.totalFeedingMinutes,
    required this.totalBottleMl,
    required this.sleepMinutes,
    required this.napCount,
    required this.diaperWet,
    required this.diaperDirty,
  });

  factory DailySummary.fromJson(Map<String, dynamic> json) {
    return DailySummary(
      feedCount: _parseInt(json['feed_count']),
      totalFeedingMinutes: _parseInt(json['total_feeding_minutes']),
      totalBottleMl: _parseInt(json['total_bottle_ml']),
      sleepMinutes: _parseInt(json['sleep_minutes']),
      napCount: _parseInt(json['nap_count']),
      diaperWet: _parseInt(json['diaper_wet']),
      diaperDirty: _parseInt(json['diaper_dirty']),
    );
  }
}

// ─── Typed Result Wrappers ─────────────────────────────────────

typedef SleepListResult = MyBabyListResult<SleepSession>;
typedef DiaperListResult = MyBabyListResult<DiaperLog>;
typedef GrowthListResult = MyBabyListResult<GrowthMeasurement>;
typedef HealthLogListResult = MyBabyListResult<HealthLog>;
typedef PhotoListResult = MyBabyListResult<BabyPhoto>;
typedef CaregiverListResult = MyBabyListResult<CaregiverShare>;

// ─── Result Wrappers ───────────────────────────────────────────

class MyBabyResult<T> {
  final bool success;
  final T? data;
  final String? message;
  MyBabyResult({required this.success, this.data, this.message});
}

class MyBabyListResult<T> {
  final bool success;
  final List<T> items;
  final String? message;
  MyBabyListResult({required this.success, this.items = const [], this.message});
}

// ─── Parsing Helpers ───────────────────────────────────────────

int _parseInt(dynamic v, {int fallback = 0}) {
  if (v == null) return fallback;
  if (v is int) return v;
  if (v is double) return v.toInt();
  if (v is String) return int.tryParse(v) ?? fallback;
  return fallback;
}

double _parseDouble(dynamic v, {double fallback = 0}) {
  if (v == null) return fallback;
  if (v is double) return v;
  if (v is int) return v.toDouble();
  if (v is String) return double.tryParse(v) ?? fallback;
  return fallback;
}

bool _parseBool(dynamic v, {bool fallback = false}) {
  if (v == null) return fallback;
  if (v is bool) return v;
  if (v is int) return v == 1;
  if (v is String) return v == '1' || v == 'true';
  return fallback;
}

DateTime? _parseDate(dynamic v) {
  if (v == null) return null;
  if (v is DateTime) return v;
  if (v is String) {
    return DateTime.tryParse(v);
  }
  return null;
}
