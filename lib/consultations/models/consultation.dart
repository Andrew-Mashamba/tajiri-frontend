import 'package:flutter/material.dart';

import '../../config/api_config.dart';

enum ConsultationVertical {
  legal,
  medical,
  business;

  String get apiValue {
    switch (this) {
      case ConsultationVertical.legal: return 'legal';
      case ConsultationVertical.medical: return 'medical';
      case ConsultationVertical.business: return 'business';
    }
  }

  String get label {
    switch (this) {
      case ConsultationVertical.legal: return 'Legal';
      case ConsultationVertical.medical: return 'Medical';
      case ConsultationVertical.business: return 'Business';
    }
  }

  String get labelSwahili {
    switch (this) {
      case ConsultationVertical.legal: return 'Sheria';
      case ConsultationVertical.medical: return 'Afya';
      case ConsultationVertical.business: return 'Biashara';
    }
  }

  IconData get icon {
    switch (this) {
      case ConsultationVertical.legal: return Icons.gavel_rounded;
      case ConsultationVertical.medical: return Icons.medical_services_rounded;
      case ConsultationVertical.business: return Icons.business_center_rounded;
    }
  }

  static ConsultationVertical fromString(String? raw) {
    switch (raw) {
      case 'legal': return ConsultationVertical.legal;
      case 'medical': return ConsultationVertical.medical;
      case 'business': return ConsultationVertical.business;
      default: return ConsultationVertical.medical;
    }
  }
}

enum ConsultationMode {
  text,
  phone,
  video,
  inPerson;

  String get apiValue {
    switch (this) {
      case ConsultationMode.text: return 'text';
      case ConsultationMode.phone: return 'phone';
      case ConsultationMode.video: return 'video';
      case ConsultationMode.inPerson: return 'in_person';
    }
  }

  String get label {
    switch (this) {
      case ConsultationMode.text: return 'Async chat';
      case ConsultationMode.phone: return 'Phone';
      case ConsultationMode.video: return 'Video';
      case ConsultationMode.inPerson: return 'In person';
    }
  }

  String get labelSwahili {
    switch (this) {
      case ConsultationMode.text: return 'Maandishi';
      case ConsultationMode.phone: return 'Simu';
      case ConsultationMode.video: return 'Video';
      case ConsultationMode.inPerson: return 'Ana kwa ana';
    }
  }

  IconData get icon {
    switch (this) {
      case ConsultationMode.text: return Icons.chat_bubble_outline_rounded;
      case ConsultationMode.phone: return Icons.phone_rounded;
      case ConsultationMode.video: return Icons.videocam_rounded;
      case ConsultationMode.inPerson: return Icons.people_rounded;
    }
  }

  /// Three-tier SKU multipliers per spec line 717: text < video < in_person.
  /// Phone slots between text and video. Used as a default suggestion when no
  /// partner-specific catalog is available — user can override.
  double get baseMultiplier {
    switch (this) {
      case ConsultationMode.text: return 0.2;
      case ConsultationMode.phone: return 0.5;
      case ConsultationMode.video: return 1.0;
      case ConsultationMode.inPerson: return 2.4;
    }
  }

  static ConsultationMode fromString(String? raw) {
    switch (raw) {
      case 'text': return ConsultationMode.text;
      case 'phone': return ConsultationMode.phone;
      case 'video': return ConsultationMode.video;
      case 'in_person': return ConsultationMode.inPerson;
      default: return ConsultationMode.video;
    }
  }
}

enum ConsultationStatus {
  pending,
  confirmed,
  inProgress,
  completed,
  cancelled,
  rejected;

  String get apiValue {
    switch (this) {
      case ConsultationStatus.pending: return 'pending';
      case ConsultationStatus.confirmed: return 'confirmed';
      case ConsultationStatus.inProgress: return 'in_progress';
      case ConsultationStatus.completed: return 'completed';
      case ConsultationStatus.cancelled: return 'cancelled';
      case ConsultationStatus.rejected: return 'rejected';
    }
  }

  String get label {
    switch (this) {
      case ConsultationStatus.pending: return 'Pending';
      case ConsultationStatus.confirmed: return 'Confirmed';
      case ConsultationStatus.inProgress: return 'In progress';
      case ConsultationStatus.completed: return 'Completed';
      case ConsultationStatus.cancelled: return 'Cancelled';
      case ConsultationStatus.rejected: return 'Rejected';
    }
  }

  String get labelSwahili {
    switch (this) {
      case ConsultationStatus.pending: return 'Inasubiri';
      case ConsultationStatus.confirmed: return 'Imekubaliwa';
      case ConsultationStatus.inProgress: return 'Inaendelea';
      case ConsultationStatus.completed: return 'Imekamilika';
      case ConsultationStatus.cancelled: return 'Imeghairiwa';
      case ConsultationStatus.rejected: return 'Imekataliwa';
    }
  }

  static ConsultationStatus fromString(String? raw) {
    switch (raw) {
      case 'pending': return ConsultationStatus.pending;
      case 'confirmed': return ConsultationStatus.confirmed;
      case 'in_progress': return ConsultationStatus.inProgress;
      case 'completed': return ConsultationStatus.completed;
      case 'cancelled': return ConsultationStatus.cancelled;
      case 'rejected': return ConsultationStatus.rejected;
      default: return ConsultationStatus.pending;
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

class ConsultationAttachment {
  final String url;
  final String? name;
  final int? size;
  final String? mime;

  ConsultationAttachment({
    required this.url,
    this.name,
    this.size,
    this.mime,
  });

  factory ConsultationAttachment.fromJson(Map<String, dynamic> json) {
    return ConsultationAttachment(
      url: json['url']?.toString() ?? '',
      name: json['name']?.toString(),
      size: _parseIntN(json['size']),
      mime: json['mime']?.toString(),
    );
  }

  Map<String, dynamic> toJson() => {
        'url': url,
        if (name != null) 'name': name,
        if (size != null) 'size': size,
        if (mime != null) 'mime': mime,
      };

  String get resolvedUrl {
    if (url.isEmpty) return '';
    if (url.startsWith('http')) return ApiConfig.sanitizeUrl(url) ?? '';
    return ApiConfig.sanitizeUrl('${ApiConfig.storageUrl}/$url') ?? '';
  }
}

class Consultation {
  final int id;
  final int customerUserId;
  final String? customerName;
  final String? customerPhotoUrl;
  final String? customerPhone;
  final int targetPartnerUserId;
  final int? targetPartnerId;
  final String? partnerName;
  final String? partnerPhotoUrl;

  final ConsultationVertical vertical;
  final String? skillCategory;
  final ConsultationMode mode;
  final int durationMin;
  final String serviceTitle;
  final int feeTzs;

  /// Sensitive — null when viewer is not the buyer or assigned partner.
  final String? intakeSummary;
  final List<ConsultationAttachment>? attachments;
  final String? followUpNotes;
  final DateTime? followUpNotesAt;
  final String? prescription;
  final DateTime? prescriptionAt;

  final String? customerAddress;
  final double? customerLat;
  final double? customerLng;

  final bool ndaAccepted;
  final DateTime? ndaAcceptedAt;
  final bool isPrivileged;

  final DateTime startsAt;
  final DateTime endsAt;
  final ConsultationStatus status;
  final DateTime? confirmedAt;
  final DateTime? rejectedAt;
  final DateTime? startedAt;
  final DateTime? completedAt;
  final DateTime? cancelledAt;
  final String? rejectionReason;
  final String? cancellationReason;
  final DateTime? createdAt;

  /// Spec line 718 — productized SKU tier: text|video|in_person.
  final String? skuTier;
  /// Spec line 719 — accepted insurance provider: NHIF|AAR|Jubilee|null.
  final String? insuranceProvider;
  /// Spec line 723 — average wait minutes from check-in data.
  final int? avgWaitMinutes;
  /// Spec line 727 — partner has acknowledged completed pre-visit intake.
  final bool preVisitIntakeCompleted;
  /// Spec line 729 — derm photo intake URLs (HEIC/JPG).
  final List<String> dermIntakePhotos;
  /// Spec line 731 — pre-call mic/camera/bandwidth test passed.
  final bool connectivityTestPassed;
  /// Spec line 736 — list of consent screen identifiers signed by patient.
  final List<String> consentScreensSigned;
  /// Spec line 737 — visit notes pushed in-app immediately post-call.
  final List<dynamic>? visitNotes;
  /// Spec line 738 — care plan delivered with visit summary.
  final List<dynamic>? carePlan;
  /// Spec line 739 — pharmacy chosen for eRx dispatch.
  final String? erxPharmacy;
  /// Spec line 739 — QR-redeemable code for off-network pharmacies.
  final String? erxQrCode;
  /// Spec line 741 — auto-suggested follow-up date (per condition cadence).
  final DateTime? followupDueAt;
  /// Spec line 745 — legal: opposing-party conflict-check payload.
  final Map<String, dynamic>? opposingPartyCheck;
  /// Spec line 752 — FLAG_SECURE active on Rx + NDA-gated chat + ID upload.
  final bool flagSecureActive;

  Consultation({
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
    required this.skillCategory,
    required this.mode,
    required this.durationMin,
    required this.serviceTitle,
    required this.feeTzs,
    required this.intakeSummary,
    required this.attachments,
    required this.followUpNotes,
    required this.followUpNotesAt,
    required this.prescription,
    required this.prescriptionAt,
    required this.customerAddress,
    required this.customerLat,
    required this.customerLng,
    required this.ndaAccepted,
    required this.ndaAcceptedAt,
    required this.isPrivileged,
    required this.startsAt,
    required this.endsAt,
    required this.status,
    required this.confirmedAt,
    required this.rejectedAt,
    required this.startedAt,
    required this.completedAt,
    required this.cancelledAt,
    required this.rejectionReason,
    required this.cancellationReason,
    required this.createdAt,
    this.skuTier,
    this.insuranceProvider,
    this.avgWaitMinutes,
    this.preVisitIntakeCompleted = false,
    this.dermIntakePhotos = const [],
    this.connectivityTestPassed = false,
    this.consentScreensSigned = const [],
    this.visitNotes,
    this.carePlan,
    this.erxPharmacy,
    this.erxQrCode,
    this.followupDueAt,
    this.opposingPartyCheck,
    this.flagSecureActive = false,
  });

  factory Consultation.fromJson(Map<String, dynamic> json) {
    List<ConsultationAttachment>? atts;
    final raw = json['attachments'];
    if (raw is List) {
      atts = raw
          .whereType<Map>()
          .map((m) => ConsultationAttachment.fromJson(m.cast<String, dynamic>()))
          .toList();
    }
    return Consultation(
      id: _parseIntN(json['id']) ?? 0,
      customerUserId: _parseIntN(json['customer_user_id']) ?? 0,
      customerName: json['customer_name']?.toString(),
      customerPhotoUrl: json['customer_photo_url']?.toString(),
      customerPhone: json['customer_phone']?.toString(),
      targetPartnerUserId: _parseIntN(json['target_partner_user_id']) ?? 0,
      targetPartnerId: _parseIntN(json['target_partner_id']),
      partnerName: json['partner_name']?.toString(),
      partnerPhotoUrl: json['partner_photo_url']?.toString(),
      vertical: ConsultationVertical.fromString(json['vertical']?.toString()),
      skillCategory: json['skill_category']?.toString(),
      mode: ConsultationMode.fromString(json['mode']?.toString()),
      durationMin: _parseIntN(json['duration_min']) ?? 30,
      serviceTitle: json['service_title']?.toString() ?? '',
      feeTzs: _parseIntN(json['fee_tzs']) ?? 0,
      intakeSummary: json['intake_summary']?.toString(),
      attachments: atts,
      followUpNotes: json['follow_up_notes']?.toString(),
      followUpNotesAt: _parseDate(json['follow_up_notes_at']),
      prescription: json['prescription']?.toString(),
      prescriptionAt: _parseDate(json['prescription_at']),
      customerAddress: json['customer_address']?.toString(),
      customerLat: _parseDoubleN(json['customer_lat']),
      customerLng: _parseDoubleN(json['customer_lng']),
      ndaAccepted: _parseBool(json['nda_accepted']),
      ndaAcceptedAt: _parseDate(json['nda_accepted_at']),
      isPrivileged: _parseBool(json['is_privileged']),
      startsAt: _parseDate(json['starts_at']) ?? DateTime.now(),
      endsAt: _parseDate(json['ends_at']) ?? DateTime.now(),
      status: ConsultationStatus.fromString(json['status']?.toString()),
      confirmedAt: _parseDate(json['confirmed_at']),
      rejectedAt: _parseDate(json['rejected_at']),
      startedAt: _parseDate(json['started_at']),
      completedAt: _parseDate(json['completed_at']),
      cancelledAt: _parseDate(json['cancelled_at']),
      rejectionReason: json['rejection_reason']?.toString(),
      cancellationReason: json['cancellation_reason']?.toString(),
      createdAt: _parseDate(json['created_at']),
      skuTier: json['sku_tier']?.toString(),
      insuranceProvider: json['insurance_provider']?.toString(),
      avgWaitMinutes: _parseIntN(json['avg_wait_minutes']),
      preVisitIntakeCompleted: _parseBool(json['pre_visit_intake_completed']),
      dermIntakePhotos: (json['derm_intake_photos'] is List)
          ? (json['derm_intake_photos'] as List).map((e) => e.toString()).toList()
          : const [],
      connectivityTestPassed: _parseBool(json['connectivity_test_passed']),
      consentScreensSigned: (json['consent_screens_signed'] is List)
          ? (json['consent_screens_signed'] as List).map((e) => e.toString()).toList()
          : const [],
      visitNotes: json['visit_notes'] is List
          ? (json['visit_notes'] as List)
          : null,
      carePlan: json['care_plan'] is List ? (json['care_plan'] as List) : null,
      erxPharmacy: json['erx_pharmacy']?.toString(),
      erxQrCode: json['erx_qr_code']?.toString(),
      followupDueAt: _parseDate(json['followup_due_at']),
      opposingPartyCheck: json['opposing_party_check'] is Map
          ? (json['opposing_party_check'] as Map).cast<String, dynamic>()
          : null,
      flagSecureActive: _parseBool(json['flag_secure_active']),
    );
  }

  bool get hasFinalised =>
      status == ConsultationStatus.completed ||
      status == ConsultationStatus.cancelled ||
      status == ConsultationStatus.rejected;

  bool get isCancellableByEither =>
      status == ConsultationStatus.pending ||
      status == ConsultationStatus.confirmed;

  /// At-or-after starts_at the customer can tap "Join" (mode-dependent).
  bool get isJoinable {
    if (status != ConsultationStatus.confirmed &&
        status != ConsultationStatus.inProgress) {
      return false;
    }
    return DateTime.now().isAfter(startsAt.subtract(const Duration(minutes: 5)));
  }
}

class ConsultationResult {
  final bool success;
  final Consultation? consultation;
  final String? message;
  final int? statusCode;
  ConsultationResult({
    required this.success,
    this.consultation,
    this.message,
    this.statusCode,
  });
}

class ConsultationListResult {
  final bool success;
  final List<Consultation> items;
  final String? message;
  final int? statusCode;
  ConsultationListResult({
    required this.success,
    this.items = const [],
    this.message,
    this.statusCode,
  });
}

/// Spec line 670 — phone-reveal response. `locked=true` indicates the call
/// happened outside the 15min-before-to-2h-after window; `revealAt` is the
/// earliest ISO8601 timestamp when reveal will succeed.
class RevealPhoneResult {
  final bool success;
  final bool locked;
  final String? phoneNumber;
  final DateTime? revealAt;
  final DateTime? closesAt;
  final String? message;
  RevealPhoneResult({
    required this.success,
    this.locked = false,
    this.phoneNumber,
    this.revealAt,
    this.closesAt,
    this.message,
  });
}

class ConsultationAttachmentUploadResult {
  final bool success;
  final ConsultationAttachment? attachment;
  final String? message;
  final int? statusCode;
  ConsultationAttachmentUploadResult({
    required this.success,
    this.attachment,
    this.message,
    this.statusCode,
  });
}
