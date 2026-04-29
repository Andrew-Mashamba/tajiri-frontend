import 'package:flutter/material.dart';

enum AppointmentVertical {
  hairNails,
  skincare,
  fitness;

  String get apiValue {
    switch (this) {
      case AppointmentVertical.hairNails: return 'hair_nails';
      case AppointmentVertical.skincare: return 'skincare';
      case AppointmentVertical.fitness: return 'fitness';
    }
  }

  String get label {
    switch (this) {
      case AppointmentVertical.hairNails: return 'Hair & Nails';
      case AppointmentVertical.skincare: return 'Skincare';
      case AppointmentVertical.fitness: return 'Fitness';
    }
  }

  String get labelSwahili {
    switch (this) {
      case AppointmentVertical.hairNails: return 'Nywele na Kucha';
      case AppointmentVertical.skincare: return 'Ngozi';
      case AppointmentVertical.fitness: return 'Mazoezi';
    }
  }

  static AppointmentVertical fromString(String? raw) {
    switch (raw) {
      case 'hair_nails': return AppointmentVertical.hairNails;
      case 'skincare': return AppointmentVertical.skincare;
      case 'fitness': return AppointmentVertical.fitness;
      default: return AppointmentVertical.hairNails;
    }
  }
}

enum LocationKind {
  salon,
  home,
  virtual;

  String get apiValue {
    switch (this) {
      case LocationKind.salon: return 'salon';
      case LocationKind.home: return 'home';
      case LocationKind.virtual: return 'virtual';
    }
  }

  String get label {
    switch (this) {
      case LocationKind.salon: return 'At provider';
      case LocationKind.home: return 'At my place';
      case LocationKind.virtual: return 'Virtual';
    }
  }

  String get labelSwahili {
    switch (this) {
      case LocationKind.salon: return 'Kwa fundi';
      case LocationKind.home: return 'Nyumbani kwangu';
      case LocationKind.virtual: return 'Mtandaoni';
    }
  }

  IconData get icon {
    switch (this) {
      case LocationKind.salon: return Icons.storefront_rounded;
      case LocationKind.home: return Icons.home_rounded;
      case LocationKind.virtual: return Icons.videocam_rounded;
    }
  }

  static LocationKind fromString(String? raw) {
    switch (raw) {
      case 'salon': return LocationKind.salon;
      case 'home': return LocationKind.home;
      case 'virtual': return LocationKind.virtual;
      default: return LocationKind.salon;
    }
  }
}

enum AppointmentStatus {
  pending,
  confirmed,
  checkedIn,
  inProgress,
  completed,
  noShow,
  cancelled,
  rejected;

  String get apiValue {
    switch (this) {
      case AppointmentStatus.pending: return 'pending';
      case AppointmentStatus.confirmed: return 'confirmed';
      case AppointmentStatus.checkedIn: return 'checked_in';
      case AppointmentStatus.inProgress: return 'in_progress';
      case AppointmentStatus.completed: return 'completed';
      case AppointmentStatus.noShow: return 'no_show';
      case AppointmentStatus.cancelled: return 'cancelled';
      case AppointmentStatus.rejected: return 'rejected';
    }
  }

  String get label {
    switch (this) {
      case AppointmentStatus.pending: return 'Pending';
      case AppointmentStatus.confirmed: return 'Confirmed';
      case AppointmentStatus.checkedIn: return 'Checked in';
      case AppointmentStatus.inProgress: return 'In progress';
      case AppointmentStatus.completed: return 'Completed';
      case AppointmentStatus.noShow: return 'No show';
      case AppointmentStatus.cancelled: return 'Cancelled';
      case AppointmentStatus.rejected: return 'Rejected';
    }
  }

  String get labelSwahili {
    switch (this) {
      case AppointmentStatus.pending: return 'Inasubiri';
      case AppointmentStatus.confirmed: return 'Imethibitishwa';
      case AppointmentStatus.checkedIn: return 'Amefika';
      case AppointmentStatus.inProgress: return 'Inaendelea';
      case AppointmentStatus.completed: return 'Imekamilika';
      case AppointmentStatus.noShow: return 'Hakufika';
      case AppointmentStatus.cancelled: return 'Imeghairiwa';
      case AppointmentStatus.rejected: return 'Imekataliwa';
    }
  }

  static AppointmentStatus fromString(String? raw) {
    switch (raw) {
      case 'pending': return AppointmentStatus.pending;
      case 'confirmed': return AppointmentStatus.confirmed;
      case 'checked_in': return AppointmentStatus.checkedIn;
      case 'in_progress': return AppointmentStatus.inProgress;
      case 'completed': return AppointmentStatus.completed;
      case 'no_show': return AppointmentStatus.noShow;
      case 'cancelled': return AppointmentStatus.cancelled;
      case 'rejected': return AppointmentStatus.rejected;
      default: return AppointmentStatus.pending;
    }
  }
}

int? _parseIntN(dynamic v) {
  if (v == null) return null;
  if (v is int) return v;
  if (v is num) return v.toInt();
  if (v is String) return int.tryParse(v);
  return null;
}

double? _parseDoubleN(dynamic v) {
  if (v == null) return null;
  if (v is double) return v;
  if (v is num) return v.toDouble();
  if (v is String) return double.tryParse(v);
  return null;
}

bool _parseBool(dynamic v) {
  if (v == null) return false;
  if (v is bool) return v;
  if (v is num) return v != 0;
  if (v is String) {
    final s = v.toLowerCase();
    return s == 'true' || s == '1';
  }
  return false;
}

DateTime? _parseDate(dynamic v) {
  if (v == null) return null;
  if (v is DateTime) return v;
  return DateTime.tryParse(v.toString());
}

class RecurringPattern {
  // Carbon convention: 0=Sun, 1=Mon..6=Sat (matches backend `between:0,6` validation
  // and `Carbon::dayOfWeek` comparison in AppointmentController::store).
  final List<int> weekdays;
  final DateTime? until;

  RecurringPattern({required this.weekdays, this.until});

  factory RecurringPattern.fromJson(Map<String, dynamic> json) {
    final wd = (json['weekdays'] as List?)
            ?.map((e) => _parseIntN(e) ?? -1)
            .where((d) => d >= 0 && d <= 6)
            .toList() ??
        const <int>[];
    return RecurringPattern(weekdays: wd, until: _parseDate(json['until']));
  }

  Map<String, dynamic> toJson() => {
        'weekdays': weekdays,
        if (until != null) 'until': until!.toIso8601String().split('T').first,
      };
}

class Appointment {
  final int id;
  final int customerUserId;
  final String? customerName;
  final String? customerPhotoUrl;
  final String? customerPhone;
  final int targetPartnerUserId;
  final int? targetPartnerId;
  final String? partnerName;
  final String? partnerPhotoUrl;
  final AppointmentVertical vertical;
  final int? partnerProductId;
  final String? skillCategory;
  final String serviceTitle;
  final int servicePriceTzs;
  final int durationMin;
  final LocationKind locationKind;
  final String? customerAddress;
  final double? customerLat;
  final double? customerLng;
  final String? notes;
  final DateTime startsAt;
  final DateTime endsAt;
  final bool isRecurring;
  final int? recurringParentId;
  final RecurringPattern? recurringPattern;
  final AppointmentStatus status;
  final DateTime? confirmedAt;
  final DateTime? rejectedAt;
  final DateTime? checkedInAt;
  final DateTime? startedAt;
  final DateTime? completedAt;
  final DateTime? noShowAt;
  final DateTime? cancelledAt;
  final String? rejectionReason;
  final String? cancellationReason;
  final int? noShowFeeTzs;
  final int rescheduleCount;
  final DateTime? createdAt;

  Appointment({
    required this.id,
    required this.customerUserId,
    required this.customerName,
    required this.customerPhotoUrl,
    required this.customerPhone,
    required this.targetPartnerUserId,
    required this.targetPartnerId,
    required this.partnerName,
    required this.partnerPhotoUrl,
    required this.vertical,
    required this.partnerProductId,
    required this.skillCategory,
    required this.serviceTitle,
    required this.servicePriceTzs,
    required this.durationMin,
    required this.locationKind,
    required this.customerAddress,
    required this.customerLat,
    required this.customerLng,
    required this.notes,
    required this.startsAt,
    required this.endsAt,
    required this.isRecurring,
    required this.recurringParentId,
    required this.recurringPattern,
    required this.status,
    required this.confirmedAt,
    required this.rejectedAt,
    required this.checkedInAt,
    required this.startedAt,
    required this.completedAt,
    required this.noShowAt,
    required this.cancelledAt,
    required this.rejectionReason,
    required this.cancellationReason,
    required this.noShowFeeTzs,
    required this.rescheduleCount,
    required this.createdAt,
  });

  factory Appointment.fromJson(Map<String, dynamic> json) {
    RecurringPattern? pattern;
    final rp = json['recurring_pattern'];
    if (rp is Map) {
      pattern = RecurringPattern.fromJson(rp.cast<String, dynamic>());
    }
    return Appointment(
      id: _parseIntN(json['id']) ?? 0,
      customerUserId: _parseIntN(json['customer_user_id']) ?? 0,
      customerName: json['customer_name']?.toString(),
      customerPhotoUrl: json['customer_photo_url']?.toString(),
      customerPhone: json['customer_phone']?.toString(),
      targetPartnerUserId: _parseIntN(json['target_partner_user_id']) ?? 0,
      targetPartnerId: _parseIntN(json['target_partner_id']),
      partnerName: json['partner_name']?.toString(),
      partnerPhotoUrl: json['partner_photo_url']?.toString(),
      vertical: AppointmentVertical.fromString(json['vertical']?.toString()),
      partnerProductId: _parseIntN(json['partner_product_id']),
      skillCategory: json['skill_category']?.toString(),
      serviceTitle: json['service_title']?.toString() ?? '',
      servicePriceTzs: _parseIntN(json['service_price_tzs']) ?? 0,
      durationMin: _parseIntN(json['duration_min']) ?? 60,
      locationKind: LocationKind.fromString(json['location_kind']?.toString()),
      customerAddress: json['customer_address']?.toString(),
      customerLat: _parseDoubleN(json['customer_lat']),
      customerLng: _parseDoubleN(json['customer_lng']),
      notes: json['notes']?.toString(),
      startsAt: _parseDate(json['starts_at']) ?? DateTime.now(),
      endsAt: _parseDate(json['ends_at']) ?? DateTime.now(),
      isRecurring: _parseBool(json['is_recurring']),
      recurringParentId: _parseIntN(json['recurring_parent_id']),
      recurringPattern: pattern,
      status: AppointmentStatus.fromString(json['status']?.toString()),
      confirmedAt: _parseDate(json['confirmed_at']),
      rejectedAt: _parseDate(json['rejected_at']),
      checkedInAt: _parseDate(json['checked_in_at']),
      startedAt: _parseDate(json['started_at']),
      completedAt: _parseDate(json['completed_at']),
      noShowAt: _parseDate(json['no_show_at']),
      cancelledAt: _parseDate(json['cancelled_at']),
      rejectionReason: json['rejection_reason']?.toString(),
      cancellationReason: json['cancellation_reason']?.toString(),
      noShowFeeTzs: _parseIntN(json['no_show_fee_tzs']),
      rescheduleCount: _parseIntN(json['reschedule_count']) ?? 0,
      createdAt: _parseDate(json['created_at']),
    );
  }

  bool get hasFinalised =>
      status == AppointmentStatus.completed ||
      status == AppointmentStatus.cancelled ||
      status == AppointmentStatus.rejected ||
      status == AppointmentStatus.noShow;

  bool get isCancellableByCustomer =>
      status == AppointmentStatus.pending ||
      status == AppointmentStatus.confirmed;

  bool get isReschedulableByCustomer {
    if (status != AppointmentStatus.pending &&
        status != AppointmentStatus.confirmed) {
      return false;
    }
    return startsAt.difference(DateTime.now()).inHours > 4;
  }
}

class AppointmentResult {
  final bool success;
  final Appointment? appointment;
  final String? message;
  final int? statusCode;
  AppointmentResult({
    required this.success,
    this.appointment,
    this.message,
    this.statusCode,
  });
}

class AppointmentListResult {
  final bool success;
  final List<Appointment> appointments;
  final String? message;
  final int? statusCode;
  AppointmentListResult({
    required this.success,
    this.appointments = const [],
    this.message,
    this.statusCode,
  });
}
