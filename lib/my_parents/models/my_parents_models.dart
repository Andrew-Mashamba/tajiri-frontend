// lib/my_parents/models/my_parents_models.dart

// ─── Parent ───────────────────────────────────────────────────────

class Parent {
  final int id;
  final int userId;
  final String name;
  final DateTime dateOfBirth;
  final String? gender;
  final String? photoUrl;
  final String relationship; // mother, father, guardian, in_law
  final String? phone;
  final bool whatsappAvailable;
  final String? locationName;
  final String? livingSituation; // alone, with_spouse, with_family, care_facility
  final String? bloodType;
  final String? mobilityStatus; // independent, uses_aid, wheelchair, bedridden
  final String? cognitiveStatus; // sharp, mild_forgetfulness, needs_supervision
  final List<String> chronicConditions;
  final List<String> allergies;
  final String? nhifNumber;
  final String? nhifStatus;
  final List<Map<String, String>> emergencyContacts;

  Parent({
    required this.id,
    required this.userId,
    required this.name,
    required this.dateOfBirth,
    this.gender,
    this.photoUrl,
    required this.relationship,
    this.phone,
    this.whatsappAvailable = false,
    this.locationName,
    this.livingSituation,
    this.bloodType,
    this.mobilityStatus,
    this.cognitiveStatus,
    this.chronicConditions = const [],
    this.allergies = const [],
    this.nhifNumber,
    this.nhifStatus,
    this.emergencyContacts = const [],
  });

  factory Parent.fromJson(Map<String, dynamic> json) {
    // Parse emergency contacts
    List<Map<String, String>> contacts = [];
    if (json['emergency_contacts'] is List) {
      contacts = (json['emergency_contacts'] as List)
          .map((c) => (c as Map<String, dynamic>)
              .map((k, v) => MapEntry(k, v?.toString() ?? '')))
          .toList();
    }

    // Parse chronic conditions
    List<String> conditions = [];
    if (json['chronic_conditions'] is List) {
      conditions = (json['chronic_conditions'] as List)
          .map((a) => a.toString())
          .toList();
    } else if (json['chronic_conditions'] is String) {
      final raw = json['chronic_conditions'] as String;
      if (raw.isNotEmpty) {
        conditions = raw.split(',').map((a) => a.trim()).toList();
      }
    }

    // Parse allergies
    List<String> parsedAllergies = [];
    if (json['allergies'] is List) {
      parsedAllergies =
          (json['allergies'] as List).map((a) => a.toString()).toList();
    } else if (json['allergies'] is String) {
      final raw = json['allergies'] as String;
      if (raw.isNotEmpty) {
        parsedAllergies = raw.split(',').map((a) => a.trim()).toList();
      }
    }

    return Parent(
      id: _parseInt(json['id']),
      userId: _parseInt(json['user_id']),
      name: json['name'] as String? ?? '',
      dateOfBirth: _parseDate(json['date_of_birth']) ?? DateTime.now(),
      gender: json['gender'] as String?,
      photoUrl: json['photo_url'] as String?,
      relationship: json['relationship'] as String? ?? 'mother',
      phone: json['phone'] as String?,
      whatsappAvailable: _parseBool(json['whatsapp_available']),
      locationName: json['location_name'] as String?,
      livingSituation: json['living_situation'] as String?,
      bloodType: json['blood_type'] as String?,
      mobilityStatus: json['mobility_status'] as String?,
      cognitiveStatus: json['cognitive_status'] as String?,
      chronicConditions: conditions,
      allergies: parsedAllergies,
      nhifNumber: json['nhif_number'] as String?,
      nhifStatus: json['nhif_status'] as String?,
      emergencyContacts: contacts,
    );
  }

  Map<String, dynamic> toJson() => {
        'user_id': userId,
        'name': name,
        'date_of_birth': dateOfBirth.toIso8601String(),
        'relationship': relationship,
        if (gender != null) 'gender': gender,
        if (photoUrl != null) 'photo_url': photoUrl,
        if (phone != null) 'phone': phone,
        'whatsapp_available': whatsappAvailable,
        if (locationName != null) 'location_name': locationName,
        if (livingSituation != null) 'living_situation': livingSituation,
        if (bloodType != null) 'blood_type': bloodType,
        if (mobilityStatus != null) 'mobility_status': mobilityStatus,
        if (cognitiveStatus != null) 'cognitive_status': cognitiveStatus,
        if (chronicConditions.isNotEmpty) 'chronic_conditions': chronicConditions,
        if (allergies.isNotEmpty) 'allergies': allergies,
        if (nhifNumber != null) 'nhif_number': nhifNumber,
        if (nhifStatus != null) 'nhif_status': nhifStatus,
        if (emergencyContacts.isNotEmpty)
          'emergency_contacts': emergencyContacts,
      };

  // ─── Age helpers ────────────────────────────────────────────

  int get ageInYears {
    final now = DateTime.now();
    int years = now.year - dateOfBirth.year;
    if (now.month < dateOfBirth.month ||
        (now.month == dateOfBirth.month && now.day < dateOfBirth.day)) {
      years--;
    }
    return years;
  }

  String ageLabel({bool isSwahili = false}) {
    final years = ageInYears;
    if (isSwahili) {
      return 'Miaka $years';
    }
    return '$years years';
  }
}

// ─── Parent Medication ────────────────────────────────────────────

class ParentMedication {
  final int id;
  final int parentId;
  final String name;
  final String dosage;
  final String frequency; // daily, twice_daily, thrice_daily, weekly
  final List<String> timeSlots;
  final DateTime? startDate;
  final DateTime? endDate;
  final String? prescribingDoctor;
  final int? pillsRemaining;
  final int? pillsPerDose;
  final int? refillThreshold;
  final bool isActive;

  ParentMedication({
    required this.id,
    required this.parentId,
    required this.name,
    required this.dosage,
    required this.frequency,
    this.timeSlots = const [],
    this.startDate,
    this.endDate,
    this.prescribingDoctor,
    this.pillsRemaining,
    this.pillsPerDose,
    this.refillThreshold,
    this.isActive = true,
  });

  factory ParentMedication.fromJson(Map<String, dynamic> json) {
    List<String> slots = [];
    if (json['time_slots'] is List) {
      slots = (json['time_slots'] as List).map((s) => s.toString()).toList();
    } else if (json['time_slots'] is String) {
      final raw = json['time_slots'] as String;
      if (raw.isNotEmpty) {
        slots = raw.split(',').map((s) => s.trim()).toList();
      }
    }

    return ParentMedication(
      id: _parseInt(json['id']),
      parentId: _parseInt(json['parent_id']),
      name: json['name'] as String? ?? '',
      dosage: json['dosage'] as String? ?? '',
      frequency: json['frequency'] as String? ?? 'daily',
      timeSlots: slots,
      startDate: _parseDate(json['start_date']),
      endDate: _parseDate(json['end_date']),
      prescribingDoctor: json['prescribing_doctor'] as String?,
      pillsRemaining: json['pills_remaining'] != null
          ? _parseInt(json['pills_remaining'])
          : null,
      pillsPerDose: json['pills_per_dose'] != null
          ? _parseInt(json['pills_per_dose'])
          : null,
      refillThreshold: json['refill_threshold'] != null
          ? _parseInt(json['refill_threshold'])
          : null,
      isActive: _parseBool(json['is_active'], fallback: true),
    );
  }

  Map<String, dynamic> toJson() => {
        'parent_id': parentId,
        'name': name,
        'dosage': dosage,
        'frequency': frequency,
        if (timeSlots.isNotEmpty) 'time_slots': timeSlots,
        if (startDate != null) 'start_date': startDate!.toIso8601String(),
        if (endDate != null) 'end_date': endDate!.toIso8601String(),
        if (prescribingDoctor != null) 'prescribing_doctor': prescribingDoctor,
        if (pillsRemaining != null) 'pills_remaining': pillsRemaining,
        if (pillsPerDose != null) 'pills_per_dose': pillsPerDose,
        if (refillThreshold != null) 'refill_threshold': refillThreshold,
        'is_active': isActive,
      };
}

// ─── Parent Health Reading ────────────────────────────────────────

class ParentHealthReading {
  final int id;
  final int parentId;
  final String type; // blood_pressure, blood_sugar, weight, symptom
  final double value;
  final double? value2; // for BP: diastolic
  final String? unit;
  final String? notes;
  final DateTime measuredAt;

  ParentHealthReading({
    required this.id,
    required this.parentId,
    required this.type,
    required this.value,
    this.value2,
    this.unit,
    this.notes,
    required this.measuredAt,
  });

  factory ParentHealthReading.fromJson(Map<String, dynamic> json) {
    return ParentHealthReading(
      id: _parseInt(json['id']),
      parentId: _parseInt(json['parent_id']),
      type: json['type'] as String? ?? 'blood_pressure',
      value: _parseDouble(json['value']),
      value2: json['value2'] != null ? _parseDouble(json['value2']) : null,
      unit: json['unit'] as String?,
      notes: json['notes'] as String?,
      measuredAt: _parseDate(json['measured_at']) ?? DateTime.now(),
    );
  }

  Map<String, dynamic> toJson() => {
        'parent_id': parentId,
        'type': type,
        'value': value,
        if (value2 != null) 'value2': value2,
        if (unit != null) 'unit': unit,
        if (notes != null) 'notes': notes,
        'measured_at': measuredAt.toIso8601String(),
      };
}

// ─── Parent Appointment ───────────────────────────────────────────

class ParentAppointment {
  final int id;
  final int parentId;
  final String? doctorName;
  final String? facility;
  final String? reason;
  final DateTime date;
  final String? time;
  final String? diagnosis;
  final String? prescription;
  final double? cost;
  final DateTime? followUpDate;
  final String? notes;
  final String status; // upcoming, completed, cancelled

  ParentAppointment({
    required this.id,
    required this.parentId,
    this.doctorName,
    this.facility,
    this.reason,
    required this.date,
    this.time,
    this.diagnosis,
    this.prescription,
    this.cost,
    this.followUpDate,
    this.notes,
    this.status = 'upcoming',
  });

  factory ParentAppointment.fromJson(Map<String, dynamic> json) {
    return ParentAppointment(
      id: _parseInt(json['id']),
      parentId: _parseInt(json['parent_id']),
      doctorName: json['doctor_name'] as String?,
      facility: json['facility'] as String?,
      reason: json['reason'] as String?,
      date: _parseDate(json['date']) ?? DateTime.now(),
      time: json['time'] as String?,
      diagnosis: json['diagnosis'] as String?,
      prescription: json['prescription'] as String?,
      cost: json['cost'] != null ? _parseDouble(json['cost']) : null,
      followUpDate: _parseDate(json['follow_up_date']),
      notes: json['notes'] as String?,
      status: json['status'] as String? ?? 'upcoming',
    );
  }

  Map<String, dynamic> toJson() => {
        'parent_id': parentId,
        if (doctorName != null) 'doctor_name': doctorName,
        if (facility != null) 'facility': facility,
        if (reason != null) 'reason': reason,
        'date': date.toIso8601String(),
        if (time != null) 'time': time,
        if (diagnosis != null) 'diagnosis': diagnosis,
        if (prescription != null) 'prescription': prescription,
        if (cost != null) 'cost': cost,
        if (followUpDate != null)
          'follow_up_date': followUpDate!.toIso8601String(),
        if (notes != null) 'notes': notes,
        'status': status,
      };
}

// ─── Financial Support ────────────────────────────────────────────

class FinancialSupport {
  final int id;
  final int parentId;
  final double amount;
  final String type; // monthly_support, medical, insurance, other
  final String? description;
  final DateTime date;
  final String? paymentMethod; // mpesa, bank, cash

  FinancialSupport({
    required this.id,
    required this.parentId,
    required this.amount,
    required this.type,
    this.description,
    required this.date,
    this.paymentMethod,
  });

  factory FinancialSupport.fromJson(Map<String, dynamic> json) {
    return FinancialSupport(
      id: _parseInt(json['id']),
      parentId: _parseInt(json['parent_id']),
      amount: _parseDouble(json['amount']),
      type: json['type'] as String? ?? 'monthly_support',
      description: json['description'] as String?,
      date: _parseDate(json['date']) ?? DateTime.now(),
      paymentMethod: json['payment_method'] as String?,
    );
  }

  Map<String, dynamic> toJson() => {
        'parent_id': parentId,
        'amount': amount,
        'type': type,
        if (description != null) 'description': description,
        'date': date.toIso8601String(),
        if (paymentMethod != null) 'payment_method': paymentMethod,
      };
}

// ─── Wellness Check-In ───────────────────────────────────────────

class WellnessCheckIn {
  final int id;
  final int parentId;
  final DateTime date;
  final String? mood; // happy, okay, sad, unwell
  final bool ateMeals;
  final bool tookMedication;
  final bool exercised;
  final bool socialized;
  final String? notes;
  final int? checkedBy;

  WellnessCheckIn({
    required this.id,
    required this.parentId,
    required this.date,
    this.mood,
    this.ateMeals = false,
    this.tookMedication = false,
    this.exercised = false,
    this.socialized = false,
    this.notes,
    this.checkedBy,
  });

  factory WellnessCheckIn.fromJson(Map<String, dynamic> json) {
    return WellnessCheckIn(
      id: _parseInt(json['id']),
      parentId: _parseInt(json['parent_id']),
      date: _parseDate(json['date']) ?? DateTime.now(),
      mood: json['mood'] as String?,
      ateMeals: _parseBool(json['ate_meals']),
      tookMedication: _parseBool(json['took_medication']),
      exercised: _parseBool(json['exercised']),
      socialized: _parseBool(json['socialized']),
      notes: json['notes'] as String?,
      checkedBy:
          json['checked_by'] != null ? _parseInt(json['checked_by']) : null,
    );
  }

  Map<String, dynamic> toJson() => {
        'parent_id': parentId,
        'date': date.toIso8601String(),
        if (mood != null) 'mood': mood,
        'ate_meals': ateMeals,
        'took_medication': tookMedication,
        'exercised': exercised,
        'socialized': socialized,
        if (notes != null) 'notes': notes,
      };
}

// ─── Care Task ────────────────────────────────────────────────────

class CareTask {
  final int id;
  final int parentId;
  final int? assignedTo;
  final int? assignedBy;
  final String title;
  final String? description;
  final DateTime? dueDate;
  final String status; // pending, in_progress, completed
  final DateTime? completedAt;
  final String? notes;

  CareTask({
    required this.id,
    required this.parentId,
    this.assignedTo,
    this.assignedBy,
    required this.title,
    this.description,
    this.dueDate,
    this.status = 'pending',
    this.completedAt,
    this.notes,
  });

  factory CareTask.fromJson(Map<String, dynamic> json) {
    return CareTask(
      id: _parseInt(json['id']),
      parentId: _parseInt(json['parent_id']),
      assignedTo:
          json['assigned_to'] != null ? _parseInt(json['assigned_to']) : null,
      assignedBy:
          json['assigned_by'] != null ? _parseInt(json['assigned_by']) : null,
      title: json['title'] as String? ?? '',
      description: json['description'] as String?,
      dueDate: _parseDate(json['due_date']),
      status: json['status'] as String? ?? 'pending',
      completedAt: _parseDate(json['completed_at']),
      notes: json['notes'] as String?,
    );
  }

  Map<String, dynamic> toJson() => {
        'parent_id': parentId,
        if (assignedTo != null) 'assigned_to': assignedTo,
        if (assignedBy != null) 'assigned_by': assignedBy,
        'title': title,
        if (description != null) 'description': description,
        if (dueDate != null) 'due_date': dueDate!.toIso8601String(),
        'status': status,
        if (completedAt != null)
          'completed_at': completedAt!.toIso8601String(),
        if (notes != null) 'notes': notes,
      };
}

// ─── Caregiver Share ──────────────────────────────────────────────

class ParentCaregiverShare {
  final int? id;
  final int parentId;
  final int ownerUserId;
  final int? caregiverUserId;
  final String inviteCode;
  final String role; // co_caregiver, sibling, viewer, doctor
  final String status; // pending, accepted, revoked
  final String? caregiverName;
  final String? caregiverPhoto;

  ParentCaregiverShare({
    this.id,
    required this.parentId,
    required this.ownerUserId,
    this.caregiverUserId,
    required this.inviteCode,
    required this.role,
    required this.status,
    this.caregiverName,
    this.caregiverPhoto,
  });

  factory ParentCaregiverShare.fromJson(Map<String, dynamic> json) {
    return ParentCaregiverShare(
      id: json['id'] != null ? _parseInt(json['id']) : null,
      parentId: _parseInt(json['parent_id']),
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

  Map<String, dynamic> toJson() => {
        if (id != null) 'id': id,
        'parent_id': parentId,
        'owner_user_id': ownerUserId,
        if (caregiverUserId != null) 'caregiver_user_id': caregiverUserId,
        'invite_code': inviteCode,
        'role': role,
        'status': status,
        if (caregiverName != null) 'caregiver_name': caregiverName,
        if (caregiverPhoto != null) 'caregiver_photo': caregiverPhoto,
      };
}

// ─── Result Wrappers ──────────────────────────────────────────────

class ParentResult<T> {
  final bool success;
  final String? message;
  final T? data;
  final List<T> items;

  ParentResult({
    required this.success,
    this.message,
    this.data,
    this.items = const [],
  });
}

class ParentListResult<T> {
  final bool success;
  final List<T> items;
  final String? message;

  ParentListResult({
    required this.success,
    this.items = const [],
    this.message,
  });
}

// ─── Parsing Helpers ──────────────────────────────────────────────

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
