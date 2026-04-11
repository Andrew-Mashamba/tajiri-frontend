// lib/my_family/models/my_family_models.dart
import 'package:flutter/material.dart';

// ─── Relationship Enum ─────────────────────────────────────────

enum Relationship {
  spouse,
  child,
  parent,
  sibling,
  grandparent,
  grandchild,
  uncle,
  aunt,
  cousin,
  nephew,
  niece,
  inLaw,
  stepChild,
  stepParent,
  guardian,
  other;

  String get displayName {
    switch (this) {
      case Relationship.spouse:
        return 'Mke/Mume';
      case Relationship.child:
        return 'Mtoto';
      case Relationship.parent:
        return 'Mzazi';
      case Relationship.sibling:
        return 'Ndugu';
      case Relationship.grandparent:
        return 'Bibi/Babu';
      case Relationship.grandchild:
        return 'Mjukuu';
      case Relationship.uncle:
        return 'Mjomba/Baba Mdogo';
      case Relationship.aunt:
        return 'Shangazi/Mama Mdogo';
      case Relationship.cousin:
        return 'Binamu';
      case Relationship.nephew:
        return 'Mpwa (Mvulana)';
      case Relationship.niece:
        return 'Mpwa (Msichana)';
      case Relationship.inLaw:
        return 'Mkwe';
      case Relationship.stepChild:
        return 'Mtoto wa Kambo';
      case Relationship.stepParent:
        return 'Mzazi wa Kambo';
      case Relationship.guardian:
        return 'Mlezi';
      case Relationship.other:
        return 'Mwingine';
    }
  }

  IconData get icon {
    switch (this) {
      case Relationship.spouse:
        return Icons.favorite_rounded;
      case Relationship.child:
        return Icons.child_care_rounded;
      case Relationship.parent:
        return Icons.person_rounded;
      case Relationship.sibling:
        return Icons.people_rounded;
      case Relationship.grandparent:
        return Icons.elderly_rounded;
      case Relationship.grandchild:
        return Icons.child_friendly_rounded;
      case Relationship.uncle:
        return Icons.person_outline_rounded;
      case Relationship.aunt:
        return Icons.person_outline_rounded;
      case Relationship.cousin:
        return Icons.people_outline_rounded;
      case Relationship.nephew:
        return Icons.boy_rounded;
      case Relationship.niece:
        return Icons.girl_rounded;
      case Relationship.inLaw:
        return Icons.people_alt_rounded;
      case Relationship.stepChild:
        return Icons.child_care_rounded;
      case Relationship.stepParent:
        return Icons.person_rounded;
      case Relationship.guardian:
        return Icons.shield_rounded;
      case Relationship.other:
        return Icons.person_add_rounded;
    }
  }

  static Relationship fromString(String? s) {
    return Relationship.values.firstWhere(
      (v) => v.name == s,
      orElse: () => Relationship.other,
    );
  }
}

// ─── Gender Enum ───────────────────────────────────────────────

enum Gender {
  male,
  female;

  String get displayName {
    switch (this) {
      case Gender.male:
        return 'Me (Mwanaume)';
      case Gender.female:
        return 'Ke (Mwanamke)';
    }
  }

  static Gender fromString(String? s) {
    switch (s) {
      case 'male':
        return Gender.male;
      case 'female':
        return Gender.female;
      default:
        return Gender.male;
    }
  }
}

// ─── Blood Type Enum ───────────────────────────────────────────

enum BloodType {
  aPositive,
  aNegative,
  bPositive,
  bNegative,
  abPositive,
  abNegative,
  oPositive,
  oNegative,
  unknown;

  String get displayName {
    switch (this) {
      case BloodType.aPositive:
        return 'A+';
      case BloodType.aNegative:
        return 'A-';
      case BloodType.bPositive:
        return 'B+';
      case BloodType.bNegative:
        return 'B-';
      case BloodType.abPositive:
        return 'AB+';
      case BloodType.abNegative:
        return 'AB-';
      case BloodType.oPositive:
        return 'O+';
      case BloodType.oNegative:
        return 'O-';
      case BloodType.unknown:
        return 'Haijulikani';
    }
  }

  static BloodType fromString(String? s) {
    switch (s) {
      case 'A+':
        return BloodType.aPositive;
      case 'A-':
        return BloodType.aNegative;
      case 'B+':
        return BloodType.bPositive;
      case 'B-':
        return BloodType.bNegative;
      case 'AB+':
        return BloodType.abPositive;
      case 'AB-':
        return BloodType.abNegative;
      case 'O+':
        return BloodType.oPositive;
      case 'O-':
        return BloodType.oNegative;
      default:
        return BloodType.unknown;
    }
  }
}

// ─── Family Member ─────────────────────────────────────────────

class FamilyMember {
  final int id;
  final int? userId; // Linked TAJIRI user ID (nullable)
  final String name;
  final Relationship relationship;
  final DateTime? dateOfBirth;
  final Gender gender;
  final String? photoUrl;
  final BloodType bloodType;
  final List<String> allergies;
  final List<String> chronicConditions;
  final String? nhifNumber;
  final String? emergencyPhone;
  final bool isLinked; // Has a TAJIRI account

  FamilyMember({
    required this.id,
    this.userId,
    required this.name,
    required this.relationship,
    this.dateOfBirth,
    required this.gender,
    this.photoUrl,
    this.bloodType = BloodType.unknown,
    this.allergies = const [],
    this.chronicConditions = const [],
    this.nhifNumber,
    this.emergencyPhone,
    this.isLinked = false,
  });

  factory FamilyMember.fromJson(Map<String, dynamic> json) {
    return FamilyMember(
      id: (json['id'] as num?)?.toInt() ?? 0,
      userId: (json['user_id'] as num?)?.toInt(),
      name: json['name'] ?? '',
      relationship: Relationship.fromString(json['relationship']),
      dateOfBirth: json['date_of_birth'] != null
          ? DateTime.tryParse(json['date_of_birth'])
          : null,
      gender: Gender.fromString(json['gender']),
      photoUrl: json['photo_url'],
      bloodType: BloodType.fromString(json['blood_type']),
      allergies: (json['allergies'] as List?)?.cast<String>() ?? [],
      chronicConditions:
          (json['chronic_conditions'] as List?)?.cast<String>() ?? [],
      nhifNumber: json['nhif_number'],
      emergencyPhone: json['emergency_phone'],
      isLinked: json['is_linked'] ?? false,
    );
  }

  Map<String, dynamic> toJson() => {
        'id': id,
        if (userId != null) 'user_id': userId,
        'name': name,
        'relationship': relationship.name,
        if (dateOfBirth != null)
          'date_of_birth': dateOfBirth!.toIso8601String().split('T').first,
        'gender': gender.name,
        if (photoUrl != null) 'photo_url': photoUrl,
        'blood_type': bloodType.displayName,
        'allergies': allergies,
        'chronic_conditions': chronicConditions,
        if (nhifNumber != null) 'nhif_number': nhifNumber,
        if (emergencyPhone != null) 'emergency_phone': emergencyPhone,
        'is_linked': isLinked,
      };

  int? get age {
    if (dateOfBirth == null) return null;
    final now = DateTime.now();
    int years = now.year - dateOfBirth!.year;
    if (now.month < dateOfBirth!.month ||
        (now.month == dateOfBirth!.month && now.day < dateOfBirth!.day)) {
      years--;
    }
    return years;
  }

  String get initials {
    final parts = name.trim().split(' ');
    if (parts.length >= 2) {
      return '${parts.first[0]}${parts.last[0]}'.toUpperCase();
    }
    return name.isNotEmpty ? name[0].toUpperCase() : '?';
  }
}

// ─── Family Event ──────────────────────────────────────────────

class FamilyEvent {
  final int id;
  final String title;
  final DateTime date;
  final String? time;
  final List<int> memberIds;
  final bool isRecurring;
  final String? recurrenceRule; // daily, weekly, monthly, yearly
  final String? notes;
  final Color color;

  FamilyEvent({
    required this.id,
    required this.title,
    required this.date,
    this.time,
    this.memberIds = const [],
    this.isRecurring = false,
    this.recurrenceRule,
    this.notes,
    this.color = const Color(0xFF1A1A1A),
  });

  factory FamilyEvent.fromJson(Map<String, dynamic> json) {
    return FamilyEvent(
      id: (json['id'] as num?)?.toInt() ?? 0,
      title: json['title'] ?? '',
      date: DateTime.parse(json['date'] ?? DateTime.now().toIso8601String()),
      time: json['time'],
      memberIds: (json['member_ids'] as List?)
              ?.map((e) => (e as num).toInt())
              .toList() ??
          [],
      isRecurring: json['is_recurring'] ?? false,
      recurrenceRule: json['recurrence_rule'],
      notes: json['notes'],
      color: Color(
          int.tryParse(json['color']?.toString() ?? '4279308058') ?? 0xFF1A1A1A),
    );
  }

  Map<String, dynamic> toJson() => {
        'title': title,
        'date': date.toIso8601String().split('T').first,
        if (time != null) 'time': time,
        'member_ids': memberIds,
        'is_recurring': isRecurring,
        if (recurrenceRule != null) 'recurrence_rule': recurrenceRule,
        if (notes != null) 'notes': notes,
        'color': '${color.toARGB32()}',
      };

  bool get isToday {
    final now = DateTime.now();
    return date.year == now.year &&
        date.month == now.month &&
        date.day == now.day;
  }

  bool get isPast => date.isBefore(DateTime.now());
}

// ─── Shared List & Items ───────────────────────────────────────

enum SharedListType {
  shopping,
  todo,
  chores;

  String get displayName {
    switch (this) {
      case SharedListType.shopping:
        return 'Ununuzi';
      case SharedListType.todo:
        return 'Ya Kufanya';
      case SharedListType.chores:
        return 'Kazi za Nyumbani';
    }
  }

  IconData get icon {
    switch (this) {
      case SharedListType.shopping:
        return Icons.shopping_cart_rounded;
      case SharedListType.todo:
        return Icons.checklist_rounded;
      case SharedListType.chores:
        return Icons.cleaning_services_rounded;
    }
  }

  static SharedListType fromString(String? s) {
    switch (s) {
      case 'shopping':
        return SharedListType.shopping;
      case 'todo':
        return SharedListType.todo;
      case 'chores':
        return SharedListType.chores;
      default:
        return SharedListType.todo;
    }
  }
}

class SharedListItem {
  final int id;
  final int listId;
  final String title;
  final bool isDone;
  final int? assignedMemberId;
  final String? assignedMemberName;
  final DateTime createdAt;

  SharedListItem({
    required this.id,
    required this.listId,
    required this.title,
    this.isDone = false,
    this.assignedMemberId,
    this.assignedMemberName,
    required this.createdAt,
  });

  factory SharedListItem.fromJson(Map<String, dynamic> json) {
    return SharedListItem(
      id: (json['id'] as num?)?.toInt() ?? 0,
      listId: (json['list_id'] as num?)?.toInt() ?? 0,
      title: json['title'] ?? '',
      isDone: json['is_done'] ?? false,
      assignedMemberId: (json['assigned_member_id'] as num?)?.toInt(),
      assignedMemberName: json['assigned_member_name'],
      createdAt:
          DateTime.parse(json['created_at'] ?? DateTime.now().toIso8601String()),
    );
  }
}

class SharedList {
  final int id;
  final String name;
  final SharedListType type;
  final List<SharedListItem> items;
  final int createdBy;

  SharedList({
    required this.id,
    required this.name,
    required this.type,
    this.items = const [],
    required this.createdBy,
  });

  factory SharedList.fromJson(Map<String, dynamic> json) {
    return SharedList(
      id: (json['id'] as num?)?.toInt() ?? 0,
      name: json['name'] ?? '',
      type: SharedListType.fromString(json['type']),
      items: (json['items'] as List?)
              ?.map((j) => SharedListItem.fromJson(j))
              .toList() ??
          [],
      createdBy: (json['created_by'] as num?)?.toInt() ?? 0,
    );
  }

  int get completedCount => items.where((i) => i.isDone).length;
  int get totalCount => items.length;
  double get progress =>
      totalCount > 0 ? completedCount / totalCount : 0.0;
}

// ─── Emergency Contact ─────────────────────────────────────────

class EmergencyContact {
  final int id;
  final String name;
  final String phone;
  final String? relationship;
  final bool isPrimary;

  EmergencyContact({
    required this.id,
    required this.name,
    required this.phone,
    this.relationship,
    this.isPrimary = false,
  });

  factory EmergencyContact.fromJson(Map<String, dynamic> json) {
    return EmergencyContact(
      id: (json['id'] as num?)?.toInt() ?? 0,
      name: json['name'] ?? '',
      phone: json['phone'] ?? '',
      relationship: json['relationship'],
      isPrimary: json['is_primary'] ?? false,
    );
  }

  Map<String, dynamic> toJson() => {
        'name': name,
        'phone': phone,
        if (relationship != null) 'relationship': relationship,
        'is_primary': isPrimary,
      };
}

// ─── Family Health Record ──────────────────────────────────────

enum HealthRecordType {
  vaccination,
  allergy,
  condition,
  medication;

  String get displayName {
    switch (this) {
      case HealthRecordType.vaccination:
        return 'Chanjo';
      case HealthRecordType.allergy:
        return 'Mzio';
      case HealthRecordType.condition:
        return 'Hali ya Afya';
      case HealthRecordType.medication:
        return 'Dawa';
    }
  }

  IconData get icon {
    switch (this) {
      case HealthRecordType.vaccination:
        return Icons.vaccines_rounded;
      case HealthRecordType.allergy:
        return Icons.warning_amber_rounded;
      case HealthRecordType.condition:
        return Icons.monitor_heart_rounded;
      case HealthRecordType.medication:
        return Icons.medication_rounded;
    }
  }

  Color get color {
    switch (this) {
      case HealthRecordType.vaccination:
        return const Color(0xFF4CAF50);
      case HealthRecordType.allergy:
        return Colors.orange;
      case HealthRecordType.condition:
        return Colors.red;
      case HealthRecordType.medication:
        return Colors.blue;
    }
  }

  static HealthRecordType fromString(String? s) {
    switch (s) {
      case 'vaccination':
        return HealthRecordType.vaccination;
      case 'allergy':
        return HealthRecordType.allergy;
      case 'condition':
        return HealthRecordType.condition;
      case 'medication':
        return HealthRecordType.medication;
      default:
        return HealthRecordType.condition;
    }
  }
}

class FamilyHealthRecord {
  final int id;
  final int memberId;
  final String memberName;
  final HealthRecordType type;
  final String title;
  final String? details;
  final DateTime date;

  FamilyHealthRecord({
    required this.id,
    required this.memberId,
    required this.memberName,
    required this.type,
    required this.title,
    this.details,
    required this.date,
  });

  factory FamilyHealthRecord.fromJson(Map<String, dynamic> json) {
    return FamilyHealthRecord(
      id: (json['id'] as num?)?.toInt() ?? 0,
      memberId: (json['member_id'] as num?)?.toInt() ?? 0,
      memberName: json['member_name'] ?? '',
      type: HealthRecordType.fromString(json['type']),
      title: json['title'] ?? '',
      details: json['details'],
      date: DateTime.parse(json['date'] ?? DateTime.now().toIso8601String()),
    );
  }

  Map<String, dynamic> toJson() => {
        'member_id': memberId,
        'member_name': memberName,
        'type': type.name,
        'title': title,
        if (details != null) 'details': details,
        'date': date.toIso8601String().split('T').first,
      };
}

// ─── Chore ─────────────────────────────────────────────────────

class Chore {
  final int id;
  final String title;
  final int? assignedMemberId;
  final String? assignedMemberName;
  final DateTime? dueDate;
  final bool isDone;
  final int points;

  Chore({
    required this.id,
    required this.title,
    this.assignedMemberId,
    this.assignedMemberName,
    this.dueDate,
    this.isDone = false,
    this.points = 0,
  });

  factory Chore.fromJson(Map<String, dynamic> json) {
    return Chore(
      id: (json['id'] as num?)?.toInt() ?? 0,
      title: json['title'] ?? '',
      assignedMemberId: (json['assigned_member_id'] as num?)?.toInt(),
      assignedMemberName: json['assigned_member_name'],
      dueDate: json['due_date'] != null
          ? DateTime.tryParse(json['due_date'])
          : null,
      isDone: json['is_done'] ?? false,
      points: (json['points'] as num?)?.toInt() ?? 0,
    );
  }

  bool get isOverdue =>
      dueDate != null && !isDone && dueDate!.isBefore(DateTime.now());
}

// ─── Result Wrappers ───────────────────────────────────────────

class FamilyResult<T> {
  final bool success;
  final T? data;
  final String? message;
  FamilyResult({required this.success, this.data, this.message});
}

class FamilyListResult<T> {
  final bool success;
  final List<T> items;
  final String? message;
  FamilyListResult({required this.success, this.items = const [], this.message});
}
