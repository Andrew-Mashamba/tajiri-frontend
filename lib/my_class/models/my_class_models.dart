// lib/my_class/models/my_class_models.dart
import 'package:flutter/material.dart';

// ─── Class Role ──────────────────────────────────────────────

enum ClassRole {
  member,
  cr,
  assistantCr,
  subjectRep,
  secretary,
  lecturer;

  String get displayName {
    switch (this) {
      case ClassRole.member:
        return 'Mwanachuo';
      case ClassRole.cr:
        return 'CR';
      case ClassRole.assistantCr:
        return 'Msaidizi CR';
      case ClassRole.subjectRep:
        return 'Mwakilishi Somo';
      case ClassRole.secretary:
        return 'Katibu';
      case ClassRole.lecturer:
        return 'Mhadhiri';
    }
  }

  String get subtitle {
    switch (this) {
      case ClassRole.member:
        return 'Member';
      case ClassRole.cr:
        return 'Class Representative';
      case ClassRole.assistantCr:
        return 'Assistant CR';
      case ClassRole.subjectRep:
        return 'Subject Rep';
      case ClassRole.secretary:
        return 'Secretary';
      case ClassRole.lecturer:
        return 'Lecturer';
    }
  }

  IconData get icon {
    switch (this) {
      case ClassRole.member:
        return Icons.person_rounded;
      case ClassRole.cr:
        return Icons.star_rounded;
      case ClassRole.assistantCr:
        return Icons.star_half_rounded;
      case ClassRole.subjectRep:
        return Icons.book_rounded;
      case ClassRole.secretary:
        return Icons.edit_note_rounded;
      case ClassRole.lecturer:
        return Icons.school_rounded;
    }
  }

  static ClassRole fromString(String? s) {
    return ClassRole.values.firstWhere(
      (v) => v.name == s,
      orElse: () => ClassRole.member,
    );
  }
}

// ─── StudentClass ────────────────────────────────────────────

class StudentClass {
  final int id;
  final String name;
  final String courseCode;
  final String semester;
  final int year;
  final String? department;
  final String? institution;
  final String joinCode;
  final int memberCount;
  final int? groupId;
  final int createdBy;
  final DateTime createdAt;
  final bool isArchived;

  StudentClass({
    required this.id,
    required this.name,
    required this.courseCode,
    required this.semester,
    required this.year,
    this.department,
    this.institution,
    required this.joinCode,
    this.memberCount = 0,
    this.groupId,
    required this.createdBy,
    required this.createdAt,
    this.isArchived = false,
  });

  factory StudentClass.fromJson(Map<String, dynamic> json) {
    return StudentClass(
      id: _parseInt(json['id']),
      name: json['name']?.toString() ?? '',
      courseCode: json['course_code']?.toString() ?? '',
      semester: json['semester']?.toString() ?? '',
      year: _parseInt(json['year']),
      department: json['department']?.toString(),
      institution: json['institution']?.toString(),
      joinCode: json['join_code']?.toString() ?? '',
      memberCount: _parseInt(json['member_count']),
      groupId: json['group_id'] != null ? _parseInt(json['group_id']) : null,
      createdBy: _parseInt(json['created_by']),
      createdAt: DateTime.tryParse(json['created_at']?.toString() ?? '') ??
          DateTime.now(),
      isArchived: _parseBool(json['is_archived']),
    );
  }
}

// ─── ClassMember ─────────────────────────────────────────────

class ClassMember {
  final int id;
  final int userId;
  final String name;
  final String? avatarUrl;
  final String? phone;
  final ClassRole role;
  final DateTime joinedAt;

  ClassMember({
    required this.id,
    required this.userId,
    required this.name,
    this.avatarUrl,
    this.phone,
    this.role = ClassRole.member,
    required this.joinedAt,
  });

  factory ClassMember.fromJson(Map<String, dynamic> json) {
    return ClassMember(
      id: _parseInt(json['id']),
      userId: _parseInt(json['user_id']),
      name: json['name']?.toString() ?? '',
      avatarUrl: json['avatar_url']?.toString(),
      phone: json['phone']?.toString(),
      role: ClassRole.fromString(json['role']?.toString()),
      joinedAt: DateTime.tryParse(json['joined_at']?.toString() ?? '') ??
          DateTime.now(),
    );
  }
}

// ─── ClassAnnouncement ───────────────────────────────────────

class ClassAnnouncement {
  final int id;
  final int classId;
  final int authorId;
  final String authorName;
  final String? authorAvatar;
  final String title;
  final String body;
  final bool isPinned;
  final DateTime createdAt;

  ClassAnnouncement({
    required this.id,
    required this.classId,
    required this.authorId,
    required this.authorName,
    this.authorAvatar,
    required this.title,
    required this.body,
    this.isPinned = false,
    required this.createdAt,
  });

  factory ClassAnnouncement.fromJson(Map<String, dynamic> json) {
    return ClassAnnouncement(
      id: _parseInt(json['id']),
      classId: _parseInt(json['class_id']),
      authorId: _parseInt(json['author_id']),
      authorName: json['author_name']?.toString() ?? '',
      authorAvatar: json['author_avatar']?.toString(),
      title: json['title']?.toString() ?? '',
      body: json['body']?.toString() ?? '',
      isPinned: _parseBool(json['is_pinned']),
      createdAt: DateTime.tryParse(json['created_at']?.toString() ?? '') ??
          DateTime.now(),
    );
  }
}

// ─── LecturerProfile ─────────────────────────────────────────

class LecturerProfile {
  final int id;
  final String name;
  final String? department;
  final String? officeLocation;
  final String? officeHours;
  final String? email;
  final String? phone;
  final String? avatarUrl;

  LecturerProfile({
    required this.id,
    required this.name,
    this.department,
    this.officeLocation,
    this.officeHours,
    this.email,
    this.phone,
    this.avatarUrl,
  });

  factory LecturerProfile.fromJson(Map<String, dynamic> json) {
    return LecturerProfile(
      id: _parseInt(json['id']),
      name: json['name']?.toString() ?? '',
      department: json['department']?.toString(),
      officeLocation: json['office_location']?.toString(),
      officeHours: json['office_hours']?.toString(),
      email: json['email']?.toString(),
      phone: json['phone']?.toString(),
      avatarUrl: json['avatar_url']?.toString(),
    );
  }
}

// ─── Result wrappers ─────────────────────────────────────────

class ClassResult<T> {
  final bool success;
  final T? data;
  final String? message;

  ClassResult({required this.success, this.data, this.message});
}

class ClassListResult<T> {
  final bool success;
  final List<T> items;
  final String? message;

  ClassListResult({required this.success, this.items = const [], this.message});
}

// ─── Parse helpers ───────────────────────────────────────────

int _parseInt(dynamic v) {
  if (v is int) return v;
  if (v is double) return v.toInt();
  if (v is String) return int.tryParse(v) ?? 0;
  return 0;
}

bool _parseBool(dynamic v) {
  if (v is bool) return v;
  if (v is int) return v != 0;
  if (v is String) return v == '1' || v.toLowerCase() == 'true';
  return false;
}
