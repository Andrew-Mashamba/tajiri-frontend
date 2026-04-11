// lib/doctor/models/doctor_models.dart
import 'package:flutter/material.dart';

// ─── Medical Specialties ────────────────────────────────────────

enum MedicalSpecialty {
  generalPractice,
  internalMedicine,
  pediatrics,
  obstetrics,
  surgery,
  dermatology,
  ophthalmology,
  ent,
  orthopedics,
  psychiatry,
  cardiology,
  neurology,
  urology,
  dentistry,
  nutrition,
  physiotherapy;

  String get displayName {
    switch (this) {
      case MedicalSpecialty.generalPractice: return 'Daktari Mkuu';
      case MedicalSpecialty.internalMedicine: return 'Tiba ya Ndani';
      case MedicalSpecialty.pediatrics: return 'Watoto';
      case MedicalSpecialty.obstetrics: return 'Uzazi';
      case MedicalSpecialty.surgery: return 'Upasuaji';
      case MedicalSpecialty.dermatology: return 'Ngozi';
      case MedicalSpecialty.ophthalmology: return 'Macho';
      case MedicalSpecialty.ent: return 'Masikio/Pua/Koo';
      case MedicalSpecialty.orthopedics: return 'Mifupa';
      case MedicalSpecialty.psychiatry: return 'Afya ya Akili';
      case MedicalSpecialty.cardiology: return 'Moyo';
      case MedicalSpecialty.neurology: return 'Neva';
      case MedicalSpecialty.urology: return 'Mkojo';
      case MedicalSpecialty.dentistry: return 'Meno';
      case MedicalSpecialty.nutrition: return 'Lishe';
      case MedicalSpecialty.physiotherapy: return 'Tiba ya Mwili';
    }
  }

  String get subtitle {
    switch (this) {
      case MedicalSpecialty.generalPractice: return 'General Practice';
      case MedicalSpecialty.internalMedicine: return 'Internal Medicine';
      case MedicalSpecialty.pediatrics: return 'Pediatrics';
      case MedicalSpecialty.obstetrics: return 'Obstetrics & Gynecology';
      case MedicalSpecialty.surgery: return 'Surgery';
      case MedicalSpecialty.dermatology: return 'Dermatology';
      case MedicalSpecialty.ophthalmology: return 'Ophthalmology';
      case MedicalSpecialty.ent: return 'ENT';
      case MedicalSpecialty.orthopedics: return 'Orthopedics';
      case MedicalSpecialty.psychiatry: return 'Psychiatry';
      case MedicalSpecialty.cardiology: return 'Cardiology';
      case MedicalSpecialty.neurology: return 'Neurology';
      case MedicalSpecialty.urology: return 'Urology';
      case MedicalSpecialty.dentistry: return 'Dentistry';
      case MedicalSpecialty.nutrition: return 'Nutrition';
      case MedicalSpecialty.physiotherapy: return 'Physiotherapy';
    }
  }

  IconData get icon {
    switch (this) {
      case MedicalSpecialty.generalPractice: return Icons.medical_services_rounded;
      case MedicalSpecialty.internalMedicine: return Icons.monitor_heart_rounded;
      case MedicalSpecialty.pediatrics: return Icons.child_care_rounded;
      case MedicalSpecialty.obstetrics: return Icons.pregnant_woman_rounded;
      case MedicalSpecialty.surgery: return Icons.healing_rounded;
      case MedicalSpecialty.dermatology: return Icons.spa_rounded;
      case MedicalSpecialty.ophthalmology: return Icons.visibility_rounded;
      case MedicalSpecialty.ent: return Icons.hearing_rounded;
      case MedicalSpecialty.orthopedics: return Icons.accessibility_new_rounded;
      case MedicalSpecialty.psychiatry: return Icons.psychology_rounded;
      case MedicalSpecialty.cardiology: return Icons.favorite_rounded;
      case MedicalSpecialty.neurology: return Icons.hub_rounded;
      case MedicalSpecialty.urology: return Icons.water_drop_rounded;
      case MedicalSpecialty.dentistry: return Icons.sentiment_satisfied_rounded;
      case MedicalSpecialty.nutrition: return Icons.restaurant_rounded;
      case MedicalSpecialty.physiotherapy: return Icons.fitness_center_rounded;
    }
  }

  static MedicalSpecialty fromString(String? s) {
    return MedicalSpecialty.values.firstWhere(
      (v) => v.name == s,
      orElse: () => MedicalSpecialty.generalPractice,
    );
  }
}

// ─── Doctor Profile ─────────────────────────────────────────────

enum DoctorVerificationStatus {
  pending,
  verified,
  rejected,
  suspended;

  String get displayName {
    switch (this) {
      case DoctorVerificationStatus.pending: return 'Inasubiri Uthibitisho';
      case DoctorVerificationStatus.verified: return 'Imethibitishwa';
      case DoctorVerificationStatus.rejected: return 'Imekataliwa';
      case DoctorVerificationStatus.suspended: return 'Imesimamishwa';
    }
  }

  Color get color {
    switch (this) {
      case DoctorVerificationStatus.pending: return Colors.orange;
      case DoctorVerificationStatus.verified: return const Color(0xFF4CAF50);
      case DoctorVerificationStatus.rejected: return Colors.red;
      case DoctorVerificationStatus.suspended: return Colors.red;
    }
  }

  static DoctorVerificationStatus fromString(String? s) {
    return DoctorVerificationStatus.values.firstWhere(
      (v) => v.name == s,
      orElse: () => DoctorVerificationStatus.pending,
    );
  }
}

class Doctor {
  final int id;
  final int userId;
  final String fullName;
  final String? profilePhotoUrl;
  final String mctRegistrationNumber;
  final MedicalSpecialty specialty;
  final List<MedicalSpecialty> additionalSpecialties;
  final DoctorVerificationStatus verificationStatus;
  final String? hospital;
  final String? location;
  final int experienceYears;
  final double rating;
  final int totalConsultations;
  final int totalReviews;
  final double consultationFee;
  final String? bio;
  final List<String> languages;
  final List<String> availableDays;
  final String? availableFrom; // e.g. "08:00"
  final String? availableTo;   // e.g. "17:00"
  final bool isOnline;
  final bool acceptsVideo;
  final bool acceptsAudio;
  final bool acceptsChat;

  Doctor({
    required this.id,
    required this.userId,
    required this.fullName,
    this.profilePhotoUrl,
    required this.mctRegistrationNumber,
    required this.specialty,
    this.additionalSpecialties = const [],
    required this.verificationStatus,
    this.hospital,
    this.location,
    this.experienceYears = 0,
    this.rating = 0,
    this.totalConsultations = 0,
    this.totalReviews = 0,
    required this.consultationFee,
    this.bio,
    this.languages = const ['Swahili', 'English'],
    this.availableDays = const [],
    this.availableFrom,
    this.availableTo,
    this.isOnline = false,
    this.acceptsVideo = true,
    this.acceptsAudio = true,
    this.acceptsChat = true,
  });

  factory Doctor.fromJson(Map<String, dynamic> json) {
    return Doctor(
      id: json['id'] ?? 0,
      userId: json['user_id'] ?? 0,
      fullName: json['full_name'] ?? '',
      profilePhotoUrl: json['profile_photo_url'],
      mctRegistrationNumber: json['mct_registration_number'] ?? '',
      specialty: MedicalSpecialty.fromString(json['specialty']),
      additionalSpecialties: (json['additional_specialties'] as List?)
              ?.map((s) => MedicalSpecialty.fromString(s))
              .toList() ??
          [],
      verificationStatus: DoctorVerificationStatus.fromString(json['verification_status']),
      hospital: json['hospital'],
      location: json['location'],
      experienceYears: (json['experience_years'] as num?)?.toInt() ?? 0,
      rating: (json['rating'] as num?)?.toDouble() ?? 0,
      totalConsultations: (json['total_consultations'] as num?)?.toInt() ?? 0,
      totalReviews: (json['total_reviews'] as num?)?.toInt() ?? 0,
      consultationFee: (json['consultation_fee'] as num?)?.toDouble() ?? 0,
      bio: json['bio'],
      languages: (json['languages'] as List?)?.cast<String>() ?? ['Swahili', 'English'],
      availableDays: (json['available_days'] as List?)?.cast<String>() ?? [],
      availableFrom: json['available_from'],
      availableTo: json['available_to'],
      isOnline: json['is_online'] ?? false,
      acceptsVideo: json['accepts_video'] ?? true,
      acceptsAudio: json['accepts_audio'] ?? true,
      acceptsChat: json['accepts_chat'] ?? true,
    );
  }

  bool get isVerified => verificationStatus == DoctorVerificationStatus.verified;
  String get initials {
    final parts = fullName.split(' ');
    if (parts.length >= 2) return '${parts[0][0]}${parts[1][0]}'.toUpperCase();
    return fullName.isNotEmpty ? fullName[0].toUpperCase() : '?';
  }
}

// ─── Appointments ───────────────────────────────────────────────

enum AppointmentStatus {
  pending,
  confirmed,
  inProgress,
  completed,
  cancelled,
  noShow;

  String get displayName {
    switch (this) {
      case AppointmentStatus.pending: return 'Inasubiri';
      case AppointmentStatus.confirmed: return 'Imethibitishwa';
      case AppointmentStatus.inProgress: return 'Inaendelea';
      case AppointmentStatus.completed: return 'Imekamilika';
      case AppointmentStatus.cancelled: return 'Imeghairiwa';
      case AppointmentStatus.noShow: return 'Haukuhudhuria';
    }
  }

  Color get color {
    switch (this) {
      case AppointmentStatus.pending: return Colors.orange;
      case AppointmentStatus.confirmed: return Colors.blue;
      case AppointmentStatus.inProgress: return const Color(0xFF4CAF50);
      case AppointmentStatus.completed: return const Color(0xFF4CAF50);
      case AppointmentStatus.cancelled: return Colors.red;
      case AppointmentStatus.noShow: return Colors.grey;
    }
  }

  static AppointmentStatus fromString(String? s) {
    switch (s) {
      case 'pending': return AppointmentStatus.pending;
      case 'confirmed': return AppointmentStatus.confirmed;
      case 'in_progress': return AppointmentStatus.inProgress;
      case 'completed': return AppointmentStatus.completed;
      case 'cancelled': return AppointmentStatus.cancelled;
      case 'no_show': return AppointmentStatus.noShow;
      default: return AppointmentStatus.pending;
    }
  }
}

enum ConsultationType { video, audio, chat }

class Appointment {
  final int id;
  final String appointmentId;
  final int patientId;
  final int doctorId;
  final Doctor? doctor;
  final String? patientName;
  final ConsultationType type;
  final DateTime scheduledAt;
  final int durationMinutes;
  final AppointmentStatus status;
  final String? reason;
  final String? symptoms;
  final double fee;
  final String? paymentStatus;
  final String? conversationId;
  final String? callId;
  final bool consentGiven;
  final DateTime createdAt;
  final String? cancellationReason;

  Appointment({
    required this.id,
    required this.appointmentId,
    required this.patientId,
    required this.doctorId,
    this.doctor,
    this.patientName,
    required this.type,
    required this.scheduledAt,
    this.durationMinutes = 15,
    required this.status,
    this.reason,
    this.symptoms,
    required this.fee,
    this.paymentStatus,
    this.conversationId,
    this.callId,
    this.consentGiven = false,
    required this.createdAt,
    this.cancellationReason,
  });

  factory Appointment.fromJson(Map<String, dynamic> json) {
    return Appointment(
      id: json['id'] ?? 0,
      appointmentId: json['appointment_id'] ?? '',
      patientId: json['patient_id'] ?? 0,
      doctorId: json['doctor_id'] ?? 0,
      doctor: json['doctor'] != null ? Doctor.fromJson(json['doctor']) : null,
      patientName: json['patient_name'],
      type: ConsultationType.values.firstWhere(
        (t) => t.name == json['type'],
        orElse: () => ConsultationType.chat,
      ),
      scheduledAt: DateTime.parse(json['scheduled_at'] ?? DateTime.now().toIso8601String()),
      durationMinutes: (json['duration_minutes'] as num?)?.toInt() ?? 15,
      status: AppointmentStatus.fromString(json['status']),
      reason: json['reason'],
      symptoms: json['symptoms'],
      fee: (json['fee'] as num?)?.toDouble() ?? 0,
      paymentStatus: json['payment_status'],
      conversationId: json['conversation_id'],
      callId: json['call_id'],
      consentGiven: json['consent_given'] ?? false,
      createdAt: DateTime.parse(json['created_at'] ?? DateTime.now().toIso8601String()),
      cancellationReason: json['cancellation_reason'],
    );
  }

  bool get isUpcoming =>
      [AppointmentStatus.pending, AppointmentStatus.confirmed].contains(status) &&
      scheduledAt.isAfter(DateTime.now());
  bool get canJoin =>
      status == AppointmentStatus.confirmed &&
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

// ─── Prescriptions ──────────────────────────────────────────────

class Prescription {
  final int id;
  final int appointmentId;
  final int doctorId;
  final int patientId;
  final String doctorName;
  final String mctNumber;
  final List<PrescriptionItem> items;
  final String? notes;
  final String? diagnosis;
  final DateTime issuedAt;
  final String? pdfUrl;

  Prescription({
    required this.id,
    required this.appointmentId,
    required this.doctorId,
    required this.patientId,
    required this.doctorName,
    required this.mctNumber,
    this.items = const [],
    this.notes,
    this.diagnosis,
    required this.issuedAt,
    this.pdfUrl,
  });

  factory Prescription.fromJson(Map<String, dynamic> json) {
    return Prescription(
      id: json['id'] ?? 0,
      appointmentId: json['appointment_id'] ?? 0,
      doctorId: json['doctor_id'] ?? 0,
      patientId: json['patient_id'] ?? 0,
      doctorName: json['doctor_name'] ?? '',
      mctNumber: json['mct_number'] ?? '',
      items: (json['items'] as List?)
              ?.map((i) => PrescriptionItem.fromJson(i))
              .toList() ??
          [],
      notes: json['notes'],
      diagnosis: json['diagnosis'],
      issuedAt: DateTime.parse(json['issued_at'] ?? DateTime.now().toIso8601String()),
      pdfUrl: json['pdf_url'],
    );
  }
}

class PrescriptionItem {
  final String medication;
  final String dosage;
  final String frequency;
  final int durationDays;
  final String? instructions;

  PrescriptionItem({
    required this.medication,
    required this.dosage,
    required this.frequency,
    required this.durationDays,
    this.instructions,
  });

  factory PrescriptionItem.fromJson(Map<String, dynamic> json) {
    return PrescriptionItem(
      medication: json['medication'] ?? '',
      dosage: json['dosage'] ?? '',
      frequency: json['frequency'] ?? '',
      durationDays: (json['duration_days'] as num?)?.toInt() ?? 0,
      instructions: json['instructions'],
    );
  }
}

// ─── Consultation Review ────────────────────────────────────────

class ConsultationReview {
  final int id;
  final int appointmentId;
  final int patientId;
  final int doctorId;
  final double rating;
  final String? comment;
  final DateTime createdAt;

  ConsultationReview({
    required this.id,
    required this.appointmentId,
    required this.patientId,
    required this.doctorId,
    required this.rating,
    this.comment,
    required this.createdAt,
  });

  factory ConsultationReview.fromJson(Map<String, dynamic> json) {
    return ConsultationReview(
      id: json['id'] ?? 0,
      appointmentId: json['appointment_id'] ?? 0,
      patientId: json['patient_id'] ?? 0,
      doctorId: json['doctor_id'] ?? 0,
      rating: (json['rating'] as num?)?.toDouble() ?? 0,
      comment: json['comment'],
      createdAt: DateTime.parse(json['created_at'] ?? DateTime.now().toIso8601String()),
    );
  }
}

// ─── Doctor Registration ────────────────────────────────────────

class DoctorRegistrationRequest {
  final String fullName;
  final String mctRegistrationNumber;
  final String specialty;
  final String? hospital;
  final String? location;
  final int experienceYears;
  final double consultationFee;
  final String? bio;
  final String nidaNumber;

  DoctorRegistrationRequest({
    required this.fullName,
    required this.mctRegistrationNumber,
    required this.specialty,
    this.hospital,
    this.location,
    required this.experienceYears,
    required this.consultationFee,
    this.bio,
    required this.nidaNumber,
  });

  Map<String, dynamic> toJson() => {
        'full_name': fullName,
        'mct_registration_number': mctRegistrationNumber,
        'specialty': specialty,
        'if_hospital': hospital,
        'location': location,
        'experience_years': experienceYears,
        'consultation_fee': consultationFee,
        'bio': bio,
        'nida_number': nidaNumber,
      };
}

// ─── Result wrappers ────────────────────────────────────────────

class DoctorResult<T> {
  final bool success;
  final T? data;
  final String? message;
  DoctorResult({required this.success, this.data, this.message});
}

class DoctorListResult<T> {
  final bool success;
  final List<T> items;
  final String? message;
  DoctorListResult({required this.success, this.items = const [], this.message});
}
