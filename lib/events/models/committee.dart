// lib/events/models/committee.dart
import '../../config/api_config.dart';

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

enum CommitteeRole {
  mwenyekiti,   // Chairperson
  katibu,       // Secretary
  mhazini,      // Treasurer
  mshauri,      // Advisor
  mratibu,      // Coordinator
  mjumbe;       // Member

  String get displayName {
    switch (this) {
      case CommitteeRole.mwenyekiti: return 'Mwenyekiti';
      case CommitteeRole.katibu: return 'Katibu';
      case CommitteeRole.mhazini: return 'Mhazini';
      case CommitteeRole.mshauri: return 'Mshauri';
      case CommitteeRole.mratibu: return 'Mratibu';
      case CommitteeRole.mjumbe: return 'Mjumbe';
    }
  }

  String get subtitle {
    switch (this) {
      case CommitteeRole.mwenyekiti: return 'Chairperson';
      case CommitteeRole.katibu: return 'Secretary';
      case CommitteeRole.mhazini: return 'Treasurer';
      case CommitteeRole.mshauri: return 'Advisor';
      case CommitteeRole.mratibu: return 'Coordinator';
      case CommitteeRole.mjumbe: return 'Member';
    }
  }

  /// Maps to GroupService role
  String get groupRole {
    switch (this) {
      case CommitteeRole.mwenyekiti: return 'admin';
      case CommitteeRole.katibu: return 'moderator';
      case CommitteeRole.mhazini: return 'moderator';
      case CommitteeRole.mshauri: return 'member';
      case CommitteeRole.mratibu: return 'moderator';
      case CommitteeRole.mjumbe: return 'member';
    }
  }

  static CommitteeRole fromApi(String? value) {
    if (value == null) return CommitteeRole.mjumbe;
    for (final r in CommitteeRole.values) {
      if (r.name == value) return r;
    }
    return CommitteeRole.mjumbe;
  }
}

class EventCommittee {
  final int id;
  final int eventId;
  final int groupId;          // links to TAJIRI Group
  final int? conversationId;  // links to group chat
  final String name;
  final bool isMainCommittee;
  final int? parentCommitteeId; // null for main, set for sub-committees
  final List<CommitteeMember> members;
  final double? budgetAllocation;
  final double? budgetSpent;

  EventCommittee({
    required this.id,
    required this.eventId,
    required this.groupId,
    this.conversationId,
    required this.name,
    this.isMainCommittee = true,
    this.parentCommitteeId,
    this.members = const [],
    this.budgetAllocation,
    this.budgetSpent,
  });

  bool get isSubCommittee => parentCommitteeId != null;
  double get budgetRemaining => (budgetAllocation ?? 0) - (budgetSpent ?? 0);

  factory EventCommittee.fromJson(Map<String, dynamic> json) {
    return EventCommittee(
      id: _parseInt(json['id']),
      eventId: _parseInt(json['event_id']),
      groupId: _parseInt(json['group_id']),
      conversationId: json['conversation_id'] != null ? _parseInt(json['conversation_id']) : null,
      name: json['name']?.toString() ?? '',
      isMainCommittee: json['is_main_committee'] != null ? _parseBool(json['is_main_committee']) : true,
      parentCommitteeId: json['parent_committee_id'] != null ? _parseInt(json['parent_committee_id']) : null,
      members: (json['members'] as List?)?.map((e) => CommitteeMember.fromJson(e)).toList() ?? [],
      budgetAllocation: json['budget_allocation'] != null ? (json['budget_allocation'] as num).toDouble() : null,
      budgetSpent: json['budget_spent'] != null ? (json['budget_spent'] as num).toDouble() : null,
    );
  }
}

class CommitteeMember {
  final int userId;
  final String firstName;
  final String lastName;
  final String? username;
  final String? avatarUrl;
  final CommitteeRole role;
  final bool isOnline;
  final DateTime? lastSeen;
  final DateTime joinedAt;

  CommitteeMember({
    required this.userId,
    required this.firstName,
    required this.lastName,
    this.username,
    this.avatarUrl,
    this.role = CommitteeRole.mjumbe,
    this.isOnline = false,
    this.lastSeen,
    required this.joinedAt,
  });

  String get fullName => '$firstName $lastName';

  factory CommitteeMember.fromJson(Map<String, dynamic> json) {
    return CommitteeMember(
      userId: _parseInt(json['user_id'] ?? json['id']),
      firstName: json['first_name']?.toString() ?? '',
      lastName: json['last_name']?.toString() ?? '',
      username: json['username']?.toString(),
      avatarUrl: ApiConfig.sanitizeUrl(json['avatar_url']?.toString() ?? json['profile_photo_url']?.toString()),
      role: CommitteeRole.fromApi(json['committee_role']?.toString() ?? json['role']?.toString()),
      isOnline: _parseBool(json['is_online']),
      lastSeen: json['last_seen'] != null ? DateTime.tryParse(json['last_seen'].toString()) : null,
      joinedAt: DateTime.tryParse(json['joined_at']?.toString() ?? json['created_at']?.toString() ?? '') ?? DateTime.now(),
    );
  }
}

class Meeting {
  final int id;
  final int committeeId;
  final String title;
  final DateTime date;
  final String? location;
  final String? agenda;
  final String? minutes;
  final int attendanceCount;
  final List<int> attendeeIds;

  Meeting({
    required this.id,
    required this.committeeId,
    required this.title,
    required this.date,
    this.location,
    this.agenda,
    this.minutes,
    this.attendanceCount = 0,
    this.attendeeIds = const [],
  });

  factory Meeting.fromJson(Map<String, dynamic> json) {
    return Meeting(
      id: _parseInt(json['id']),
      committeeId: _parseInt(json['committee_id']),
      title: json['title']?.toString() ?? '',
      date: DateTime.tryParse(json['date']?.toString() ?? '') ?? DateTime.now(),
      location: json['location']?.toString(),
      agenda: json['agenda']?.toString(),
      minutes: json['minutes']?.toString(),
      attendanceCount: _parseInt(json['attendance_count']),
      attendeeIds: (json['attendee_ids'] as List?)?.map((e) => _parseInt(e)).toList() ?? [],
    );
  }

  Map<String, dynamic> toJson() => {
    'committee_id': committeeId,
    'title': title,
    'date': date.toIso8601String(),
    if (location != null) 'location': location,
    if (agenda != null) 'agenda': agenda,
    if (minutes != null) 'minutes': minutes,
  };
}
