// lib/lawyer/models/lawyer_models.dart
import 'package:flutter/material.dart';

// ─── Legal Specialties ─────────────────────────────────────────

enum LegalSpecialty {
  corporate,
  criminal,
  family,
  propertyLand,
  labor,
  tax,
  immigration,
  intellectualProperty,
  contract,
  debtRecovery,
  general;

  String get displayName {
    switch (this) {
      case LegalSpecialty.corporate: return 'Biashara';
      case LegalSpecialty.criminal: return 'Jinai';
      case LegalSpecialty.family: return 'Familia';
      case LegalSpecialty.propertyLand: return 'Ardhi na Mali';
      case LegalSpecialty.labor: return 'Kazi';
      case LegalSpecialty.tax: return 'Kodi';
      case LegalSpecialty.immigration: return 'Uhamiaji';
      case LegalSpecialty.intellectualProperty: return 'Hakimiliki';
      case LegalSpecialty.contract: return 'Mikataba';
      case LegalSpecialty.debtRecovery: return 'Madeni';
      case LegalSpecialty.general: return 'Sheria ya Jumla';
    }
  }

  String get subtitle {
    switch (this) {
      case LegalSpecialty.corporate: return 'Corporate Law';
      case LegalSpecialty.criminal: return 'Criminal Law';
      case LegalSpecialty.family: return 'Family Law';
      case LegalSpecialty.propertyLand: return 'Property & Land';
      case LegalSpecialty.labor: return 'Labor Law';
      case LegalSpecialty.tax: return 'Tax Law';
      case LegalSpecialty.immigration: return 'Immigration';
      case LegalSpecialty.intellectualProperty: return 'IP Law';
      case LegalSpecialty.contract: return 'Contract Law';
      case LegalSpecialty.debtRecovery: return 'Debt Recovery';
      case LegalSpecialty.general: return 'General Practice';
    }
  }

  IconData get icon {
    switch (this) {
      case LegalSpecialty.corporate: return Icons.business_rounded;
      case LegalSpecialty.criminal: return Icons.gavel_rounded;
      case LegalSpecialty.family: return Icons.family_restroom_rounded;
      case LegalSpecialty.propertyLand: return Icons.landscape_rounded;
      case LegalSpecialty.labor: return Icons.work_rounded;
      case LegalSpecialty.tax: return Icons.receipt_long_rounded;
      case LegalSpecialty.immigration: return Icons.flight_rounded;
      case LegalSpecialty.intellectualProperty: return Icons.lightbulb_rounded;
      case LegalSpecialty.contract: return Icons.description_rounded;
      case LegalSpecialty.debtRecovery: return Icons.account_balance_rounded;
      case LegalSpecialty.general: return Icons.balance_rounded;
    }
  }

  static LegalSpecialty fromString(String? s) {
    return LegalSpecialty.values.firstWhere(
      (v) => v.name == s,
      orElse: () => LegalSpecialty.general,
    );
  }
}

// ─── Verification Status ───────────────────────────────────────

enum LawyerVerificationStatus {
  pending,
  verified,
  rejected,
  suspended;

  String get displayName {
    switch (this) {
      case LawyerVerificationStatus.pending: return 'Inasubiri Uthibitisho';
      case LawyerVerificationStatus.verified: return 'Imethibitishwa';
      case LawyerVerificationStatus.rejected: return 'Imekataliwa';
      case LawyerVerificationStatus.suspended: return 'Imesimamishwa';
    }
  }

  Color get color {
    switch (this) {
      case LawyerVerificationStatus.pending: return Colors.orange;
      case LawyerVerificationStatus.verified: return const Color(0xFF4CAF50);
      case LawyerVerificationStatus.rejected: return Colors.red;
      case LawyerVerificationStatus.suspended: return Colors.red;
    }
  }

  static LawyerVerificationStatus fromString(String? s) {
    return LawyerVerificationStatus.values.firstWhere(
      (v) => v.name == s,
      orElse: () => LawyerVerificationStatus.pending,
    );
  }
}

// ─── Lawyer Profile ────────────────────────────────────────────

class Lawyer {
  final int id;
  final int userId;
  final String fullName;
  final String? profilePhotoUrl;
  final String barNumber;
  final LegalSpecialty specialty;
  final List<LegalSpecialty> additionalSpecialties;
  final LawyerVerificationStatus verificationStatus;
  final String? firm;
  final String? location;
  final int experienceYears;
  final double rating;
  final int totalConsultations;
  final int totalReviews;
  final double consultationFee;
  final String? bio;
  final List<String> languages;
  final bool isOnline;
  final bool acceptsVideo;
  final bool acceptsAudio;
  final bool acceptsChat;

  Lawyer({
    required this.id,
    required this.userId,
    required this.fullName,
    this.profilePhotoUrl,
    required this.barNumber,
    required this.specialty,
    this.additionalSpecialties = const [],
    required this.verificationStatus,
    this.firm,
    this.location,
    this.experienceYears = 0,
    this.rating = 0,
    this.totalConsultations = 0,
    this.totalReviews = 0,
    required this.consultationFee,
    this.bio,
    this.languages = const ['Swahili', 'English'],
    this.isOnline = false,
    this.acceptsVideo = true,
    this.acceptsAudio = true,
    this.acceptsChat = true,
  });

  factory Lawyer.fromJson(Map<String, dynamic> json) {
    return Lawyer(
      id: json['id'] ?? 0,
      userId: json['user_id'] ?? 0,
      fullName: json['full_name'] ?? '',
      profilePhotoUrl: json['profile_photo_url'],
      barNumber: json['bar_number'] ?? '',
      specialty: LegalSpecialty.fromString(json['specialty']),
      additionalSpecialties: (json['additional_specialties'] as List?)
              ?.map((s) => LegalSpecialty.fromString(s))
              .toList() ??
          [],
      verificationStatus: LawyerVerificationStatus.fromString(json['verification_status']),
      firm: json['firm'],
      location: json['location'],
      experienceYears: (json['experience_years'] as num?)?.toInt() ?? 0,
      rating: (json['rating'] as num?)?.toDouble() ?? 0,
      totalConsultations: (json['total_consultations'] as num?)?.toInt() ?? 0,
      totalReviews: (json['total_reviews'] as num?)?.toInt() ?? 0,
      consultationFee: (json['consultation_fee'] as num?)?.toDouble() ?? 0,
      bio: json['bio'],
      languages: (json['languages'] as List?)?.cast<String>() ?? ['Swahili', 'English'],
      isOnline: json['is_online'] ?? false,
      acceptsVideo: json['accepts_video'] ?? true,
      acceptsAudio: json['accepts_audio'] ?? true,
      acceptsChat: json['accepts_chat'] ?? true,
    );
  }

  bool get isVerified => verificationStatus == LawyerVerificationStatus.verified;
  String get initials {
    final parts = fullName.split(' ');
    if (parts.length >= 2) return '${parts[0][0]}${parts[1][0]}'.toUpperCase();
    return fullName.isNotEmpty ? fullName[0].toUpperCase() : '?';
  }
}

// ─── Legal Consultation ────────────────────────────────────────

enum ConsultationType { video, audio, chat }

enum ConsultationStatus {
  pending,
  confirmed,
  inProgress,
  completed,
  cancelled;

  String get displayName {
    switch (this) {
      case ConsultationStatus.pending: return 'Inasubiri';
      case ConsultationStatus.confirmed: return 'Imethibitishwa';
      case ConsultationStatus.inProgress: return 'Inaendelea';
      case ConsultationStatus.completed: return 'Imekamilika';
      case ConsultationStatus.cancelled: return 'Imeghairiwa';
    }
  }

  Color get color {
    switch (this) {
      case ConsultationStatus.pending: return Colors.orange;
      case ConsultationStatus.confirmed: return Colors.blue;
      case ConsultationStatus.inProgress: return const Color(0xFF4CAF50);
      case ConsultationStatus.completed: return const Color(0xFF4CAF50);
      case ConsultationStatus.cancelled: return Colors.red;
    }
  }

  static ConsultationStatus fromString(String? s) {
    switch (s) {
      case 'pending': return ConsultationStatus.pending;
      case 'confirmed': return ConsultationStatus.confirmed;
      case 'in_progress': return ConsultationStatus.inProgress;
      case 'completed': return ConsultationStatus.completed;
      case 'cancelled': return ConsultationStatus.cancelled;
      default: return ConsultationStatus.pending;
    }
  }
}

class LegalConsultation {
  final int id;
  final String consultationId;
  final int lawyerId;
  final int clientId;
  final Lawyer? lawyer;
  final String? clientName;
  final ConsultationType type;
  final DateTime scheduledAt;
  final int durationMinutes;
  final ConsultationStatus status;
  final double fee;
  final String? issue;
  final String? notes;
  final String? paymentStatus;
  final String? conversationId;
  final String? callId;
  final DateTime createdAt;
  final String? cancellationReason;

  LegalConsultation({
    required this.id,
    required this.consultationId,
    required this.lawyerId,
    required this.clientId,
    this.lawyer,
    this.clientName,
    required this.type,
    required this.scheduledAt,
    this.durationMinutes = 30,
    required this.status,
    required this.fee,
    this.issue,
    this.notes,
    this.paymentStatus,
    this.conversationId,
    this.callId,
    required this.createdAt,
    this.cancellationReason,
  });

  factory LegalConsultation.fromJson(Map<String, dynamic> json) {
    return LegalConsultation(
      id: json['id'] ?? 0,
      consultationId: json['consultation_id'] ?? '',
      lawyerId: json['lawyer_id'] ?? 0,
      clientId: json['client_id'] ?? 0,
      lawyer: json['lawyer'] != null ? Lawyer.fromJson(json['lawyer']) : null,
      clientName: json['client_name'],
      type: ConsultationType.values.firstWhere(
        (t) => t.name == json['type'],
        orElse: () => ConsultationType.chat,
      ),
      scheduledAt: DateTime.parse(json['scheduled_at'] ?? DateTime.now().toIso8601String()),
      durationMinutes: (json['duration_minutes'] as num?)?.toInt() ?? 30,
      status: ConsultationStatus.fromString(json['status']),
      fee: (json['fee'] as num?)?.toDouble() ?? 0,
      issue: json['issue'],
      notes: json['notes'],
      paymentStatus: json['payment_status'],
      conversationId: json['conversation_id'],
      callId: json['call_id'],
      createdAt: DateTime.parse(json['created_at'] ?? DateTime.now().toIso8601String()),
      cancellationReason: json['cancellation_reason'],
    );
  }

  bool get isUpcoming =>
      [ConsultationStatus.pending, ConsultationStatus.confirmed].contains(status) &&
      scheduledAt.isAfter(DateTime.now());
  bool get canJoin =>
      status == ConsultationStatus.confirmed &&
      DateTime.now().difference(scheduledAt).inMinutes.abs() <= 15;
  bool get isPaid => paymentStatus == 'paid';

  String get typeLabel {
    switch (type) {
      case ConsultationType.video: return 'Video';
      case ConsultationType.audio: return 'Simu';
      case ConsultationType.chat: return 'Ujumbe';
    }
  }

  IconData get typeIcon {
    switch (type) {
      case ConsultationType.video: return Icons.videocam_rounded;
      case ConsultationType.audio: return Icons.phone_rounded;
      case ConsultationType.chat: return Icons.chat_rounded;
    }
  }
}

// ─── Consultation Review ───────────────────────────────────────

class LawyerReview {
  final int id;
  final int consultationId;
  final int clientId;
  final int lawyerId;
  final double rating;
  final String? comment;
  final DateTime createdAt;

  LawyerReview({
    required this.id,
    required this.consultationId,
    required this.clientId,
    required this.lawyerId,
    required this.rating,
    this.comment,
    required this.createdAt,
  });

  factory LawyerReview.fromJson(Map<String, dynamic> json) {
    return LawyerReview(
      id: json['id'] ?? 0,
      consultationId: json['consultation_id'] ?? 0,
      clientId: json['client_id'] ?? 0,
      lawyerId: json['lawyer_id'] ?? 0,
      rating: (json['rating'] as num?)?.toDouble() ?? 0,
      comment: json['comment'],
      createdAt: DateTime.parse(json['created_at'] ?? DateTime.now().toIso8601String()),
    );
  }
}

// ─── Lawyer Registration ───────────────────────────────────────

class LawyerRegistrationRequest {
  final String fullName;
  final String barNumber;
  final String specialty;
  final String? firm;
  final String? location;
  final int experienceYears;
  final double consultationFee;
  final String? bio;
  final String nidaNumber;

  LawyerRegistrationRequest({
    required this.fullName,
    required this.barNumber,
    required this.specialty,
    this.firm,
    this.location,
    required this.experienceYears,
    required this.consultationFee,
    this.bio,
    required this.nidaNumber,
  });

  Map<String, dynamic> toJson() => {
        'full_name': fullName,
        'bar_number': barNumber,
        'specialty': specialty,
        'firm': firm,
        'location': location,
        'experience_years': experienceYears,
        'consultation_fee': consultationFee,
        'bio': bio,
        'nida_number': nidaNumber,
      };
}

// ─── Result wrappers ───────────────────────────────────────────

class LawyerResult<T> {
  final bool success;
  final T? data;
  final String? message;
  LawyerResult({required this.success, this.data, this.message});
}

class LawyerListResult<T> {
  final bool success;
  final List<T> items;
  final String? message;
  LawyerListResult({required this.success, this.items = const [], this.message});
}
