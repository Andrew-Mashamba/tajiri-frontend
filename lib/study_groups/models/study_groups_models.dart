// lib/study_groups/models/study_groups_models.dart

// ─── GroupRole ────────────────────────────────────────────────

enum StudyGroupRole {
  leader,
  noteTaker,
  quizMaster,
  scheduler,
  member;

  String get displayName {
    switch (this) {
      case StudyGroupRole.leader:
        return 'Kiongozi';
      case StudyGroupRole.noteTaker:
        return 'Mwandishi';
      case StudyGroupRole.quizMaster:
        return 'Mtahini';
      case StudyGroupRole.scheduler:
        return 'Mpangaji';
      case StudyGroupRole.member:
        return 'Mwanachama';
    }
  }

  static StudyGroupRole fromString(String? s) {
    return StudyGroupRole.values.firstWhere(
      (v) => v.name == s,
      orElse: () => StudyGroupRole.member,
    );
  }
}

// ─── StudyGroup ──────────────────────────────────────────────

class StudyGroup {
  final int id;
  final String name;
  final String subject;
  final String? description;
  final String? courseCode;
  final int memberCount;
  final int maxMembers;
  final bool isPublic;
  final int? groupId; // TAJIRI group ID
  final int createdBy;
  final int streak;
  final int totalSessions;
  final DateTime createdAt;

  StudyGroup({
    required this.id,
    required this.name,
    required this.subject,
    this.description,
    this.courseCode,
    this.memberCount = 0,
    this.maxMembers = 8,
    this.isPublic = true,
    this.groupId,
    required this.createdBy,
    this.streak = 0,
    this.totalSessions = 0,
    required this.createdAt,
  });

  factory StudyGroup.fromJson(Map<String, dynamic> json) {
    return StudyGroup(
      id: _parseInt(json['id']),
      name: json['name']?.toString() ?? '',
      subject: json['subject']?.toString() ?? '',
      description: json['description']?.toString(),
      courseCode: json['course_code']?.toString(),
      memberCount: _parseInt(json['member_count']),
      maxMembers: _parseInt(json['max_members']),
      isPublic: _parseBool(json['is_public']),
      groupId: json['group_id'] != null ? _parseInt(json['group_id']) : null,
      createdBy: _parseInt(json['created_by']),
      streak: _parseInt(json['streak']),
      totalSessions: _parseInt(json['total_sessions']),
      createdAt: DateTime.tryParse(json['created_at']?.toString() ?? '') ??
          DateTime.now(),
    );
  }

  bool get isFull => memberCount >= maxMembers;
}

// ─── StudyGroupMember ────────────────────────────────────────

class StudyGroupMember {
  final int id;
  final int userId;
  final String name;
  final String? avatarUrl;
  final StudyGroupRole role;
  final int attendanceCount;
  final int contributionScore;
  final DateTime joinedAt;

  StudyGroupMember({
    required this.id,
    required this.userId,
    required this.name,
    this.avatarUrl,
    this.role = StudyGroupRole.member,
    this.attendanceCount = 0,
    this.contributionScore = 0,
    required this.joinedAt,
  });

  factory StudyGroupMember.fromJson(Map<String, dynamic> json) {
    return StudyGroupMember(
      id: _parseInt(json['id']),
      userId: _parseInt(json['user_id']),
      name: json['name']?.toString() ?? '',
      avatarUrl: json['avatar_url']?.toString(),
      role: StudyGroupRole.fromString(json['role']?.toString()),
      attendanceCount: _parseInt(json['attendance_count']),
      contributionScore: _parseInt(json['contribution_score']),
      joinedAt: DateTime.tryParse(json['joined_at']?.toString() ?? '') ??
          DateTime.now(),
    );
  }
}

// ─── StudySession ────────────────────────────────────────────

class GroupStudySession {
  final int id;
  final int groupId;
  final String topic;
  final DateTime scheduledAt;
  final int durationMinutes;
  final String? location;
  final bool isVirtual;
  final int attendeeCount;
  final bool hasCheckedIn;

  GroupStudySession({
    required this.id,
    required this.groupId,
    required this.topic,
    required this.scheduledAt,
    this.durationMinutes = 60,
    this.location,
    this.isVirtual = false,
    this.attendeeCount = 0,
    this.hasCheckedIn = false,
  });

  factory GroupStudySession.fromJson(Map<String, dynamic> json) {
    return GroupStudySession(
      id: _parseInt(json['id']),
      groupId: _parseInt(json['group_id']),
      topic: json['topic']?.toString() ?? '',
      scheduledAt:
          DateTime.tryParse(json['scheduled_at']?.toString() ?? '') ??
              DateTime.now(),
      durationMinutes: _parseInt(json['duration_minutes']),
      location: json['location']?.toString(),
      isVirtual: _parseBool(json['is_virtual']),
      attendeeCount: _parseInt(json['attendee_count']),
      hasCheckedIn: _parseBool(json['has_checked_in']),
    );
  }

  bool get isPast => DateTime.now().isAfter(scheduledAt);
}

// ─── Result wrappers ─────────────────────────────────────────

class StudyResult<T> {
  final bool success;
  final T? data;
  final String? message;

  StudyResult({required this.success, this.data, this.message});
}

class StudyListResult<T> {
  final bool success;
  final List<T> items;
  final String? message;

  StudyListResult({required this.success, this.items = const [], this.message});
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
