// lib/events/models/event_rsvp.dart
import '../../config/api_config.dart';
import 'event_enums.dart';

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

class EventRSVP {
  final int id;
  final int eventId;
  final int userId;
  final RSVPStatus status;
  final int guestCount;
  final List<String> guestNames;
  final DateTime respondedAt;
  final EventAttendee? user;

  EventRSVP({
    required this.id,
    required this.eventId,
    required this.userId,
    required this.status,
    this.guestCount = 0,
    this.guestNames = const [],
    required this.respondedAt,
    this.user,
  });

  bool get isGoing => status == RSVPStatus.going;

  factory EventRSVP.fromJson(Map<String, dynamic> json) {
    return EventRSVP(
      id: _parseInt(json['id']),
      eventId: _parseInt(json['event_id']),
      userId: _parseInt(json['user_id']),
      status: RSVPStatus.fromApi(json['status']?.toString()),
      guestCount: _parseInt(json['guest_count']),
      guestNames: (json['guest_names'] as List?)?.map((e) => e.toString()).toList() ?? [],
      respondedAt: DateTime.tryParse(json['responded_at']?.toString() ?? json['created_at']?.toString() ?? '') ?? DateTime.now(),
      user: json['user'] != null ? EventAttendee.fromJson(json['user']) : null,
    );
  }
}

class EventAttendee {
  final int userId;
  final String firstName;
  final String lastName;
  final String? username;
  final String? avatarUrl;
  final bool isFriend;
  final RSVPStatus? rsvpStatus;
  final bool isCheckedIn;

  EventAttendee({
    required this.userId,
    required this.firstName,
    required this.lastName,
    this.username,
    this.avatarUrl,
    this.isFriend = false,
    this.rsvpStatus,
    this.isCheckedIn = false,
  });

  String get fullName => '$firstName $lastName';

  factory EventAttendee.fromJson(Map<String, dynamic> json) {
    return EventAttendee(
      userId: _parseInt(json['user_id'] ?? json['id']),
      firstName: json['first_name']?.toString() ?? '',
      lastName: json['last_name']?.toString() ?? '',
      username: json['username']?.toString(),
      avatarUrl: ApiConfig.sanitizeUrl(json['avatar_url']?.toString() ?? json['profile_photo_url']?.toString()),
      isFriend: _parseBool(json['is_friend']),
      rsvpStatus: json['rsvp_status'] != null ? RSVPStatus.fromApi(json['rsvp_status'].toString()) : null,
      isCheckedIn: _parseBool(json['is_checked_in']),
    );
  }
}
