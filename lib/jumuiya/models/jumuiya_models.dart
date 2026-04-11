// lib/jumuiya/models/jumuiya_models.dart

int _parseInt(dynamic v) => (v is num) ? v.toInt() : int.tryParse('$v') ?? 0;
bool _parseBool(dynamic v) =>
    v == true || v == 1 || v == '1' || v == 'true';

// ─── Result wrappers ───────────────────────────────────────────

class SingleResult<T> {
  final bool success;
  final T? data;
  final String? message;
  SingleResult({required this.success, this.data, this.message});
}

class PaginatedResult<T> {
  final bool success;
  final List<T> items;
  final String? message;
  final int currentPage;
  final int lastPage;
  PaginatedResult({
    required this.success,
    this.items = const [],
    this.message,
    this.currentPage = 1,
    this.lastPage = 1,
  });
  bool get hasMore => currentPage < lastPage;
}

// ─── Jumuiya Group ────────────────────────────────────────────

class JumuiyaGroup {
  final int id;
  final String name;
  final String? description;
  final String? churchName;
  final String? meetingDay;
  final String? meetingTime;
  final String? meetingLocation;
  final String? leaderName;
  final int memberCount;
  final bool isMember;
  final String? imageUrl;

  JumuiyaGroup({
    required this.id,
    required this.name,
    this.description,
    this.churchName,
    this.meetingDay,
    this.meetingTime,
    this.meetingLocation,
    this.leaderName,
    required this.memberCount,
    this.isMember = false,
    this.imageUrl,
  });

  factory JumuiyaGroup.fromJson(Map<String, dynamic> json) {
    return JumuiyaGroup(
      id: _parseInt(json['id']),
      name: json['name']?.toString() ?? '',
      description: json['description']?.toString(),
      churchName: json['church_name']?.toString(),
      meetingDay: json['meeting_day']?.toString(),
      meetingTime: json['meeting_time']?.toString(),
      meetingLocation: json['meeting_location']?.toString(),
      leaderName: json['leader_name']?.toString(),
      memberCount: _parseInt(json['member_count']),
      isMember: _parseBool(json['is_member']),
      imageUrl: json['image_url']?.toString(),
    );
  }
}

// ─── Jumuiya Member ───────────────────────────────────────────

class JumuiyaMember {
  final int id;
  final String name;
  final String? role;
  final String? photoUrl;
  final int attendancePercent;

  JumuiyaMember({
    required this.id,
    required this.name,
    this.role,
    this.photoUrl,
    required this.attendancePercent,
  });

  factory JumuiyaMember.fromJson(Map<String, dynamic> json) {
    return JumuiyaMember(
      id: _parseInt(json['id']),
      name: json['name']?.toString() ?? '',
      role: json['role']?.toString(),
      photoUrl: json['photo_url']?.toString(),
      attendancePercent: _parseInt(json['attendance_percent']),
    );
  }
}

// ─── Meeting ──────────────────────────────────────────────────

class JumuiyaMeeting {
  final int id;
  final String date;
  final String? topic;
  final String? scriptureRef;
  final String? hostName;
  final int attendeeCount;
  final String? notes;

  JumuiyaMeeting({
    required this.id,
    required this.date,
    this.topic,
    this.scriptureRef,
    this.hostName,
    required this.attendeeCount,
    this.notes,
  });

  factory JumuiyaMeeting.fromJson(Map<String, dynamic> json) {
    return JumuiyaMeeting(
      id: _parseInt(json['id']),
      date: json['date']?.toString() ?? '',
      topic: json['topic']?.toString(),
      scriptureRef: json['scripture_ref']?.toString(),
      hostName: json['host_name']?.toString(),
      attendeeCount: _parseInt(json['attendee_count']),
      notes: json['notes']?.toString(),
    );
  }
}
