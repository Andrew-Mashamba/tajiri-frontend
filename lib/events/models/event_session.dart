// lib/events/models/event_session.dart
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

class EventSession {
  final int id;
  final int eventId;
  final String title;
  final String? description;
  final DateTime startTime;
  final DateTime endTime;
  final String? location;
  final String? track;
  final List<EventSpeaker> speakers;
  final int? capacity;
  final bool requiresRSVP;

  EventSession({
    required this.id,
    required this.eventId,
    required this.title,
    this.description,
    required this.startTime,
    required this.endTime,
    this.location,
    this.track,
    this.speakers = const [],
    this.capacity,
    this.requiresRSVP = false,
  });

  factory EventSession.fromJson(Map<String, dynamic> json) {
    return EventSession(
      id: _parseInt(json['id']),
      eventId: _parseInt(json['event_id']),
      title: json['title']?.toString() ?? '',
      description: json['description']?.toString(),
      startTime: DateTime.tryParse(json['start_time']?.toString() ?? '') ?? DateTime.now(),
      endTime: DateTime.tryParse(json['end_time']?.toString() ?? '') ?? DateTime.now(),
      location: json['location']?.toString(),
      track: json['track']?.toString(),
      speakers: (json['speakers'] as List?)?.map((e) => EventSpeaker.fromJson(e)).toList() ?? [],
      capacity: json['capacity'] != null ? _parseInt(json['capacity']) : null,
      requiresRSVP: _parseBool(json['requires_rsvp']),
    );
  }

  Map<String, dynamic> toJson() => {
    'title': title,
    'description': description,
    'start_time': startTime.toIso8601String(),
    'end_time': endTime.toIso8601String(),
    'location': location,
    'track': track,
    'capacity': capacity,
    'requires_rsvp': requiresRSVP,
  };
}

class EventSpeaker {
  final int id;
  final String name;
  final String? title;
  final String? bio;
  final String? avatarUrl;
  final int? userId;
  final List<String> socialLinks;

  EventSpeaker({
    required this.id,
    required this.name,
    this.title,
    this.bio,
    this.avatarUrl,
    this.userId,
    this.socialLinks = const [],
  });

  factory EventSpeaker.fromJson(Map<String, dynamic> json) {
    return EventSpeaker(
      id: _parseInt(json['id']),
      name: json['name']?.toString() ?? '',
      title: json['title']?.toString(),
      bio: json['bio']?.toString(),
      avatarUrl: ApiConfig.sanitizeUrl(json['avatar_url']?.toString()),
      userId: json['user_id'] != null ? _parseInt(json['user_id']) : null,
      socialLinks: (json['social_links'] as List?)?.map((e) => e.toString()).toList() ?? [],
    );
  }

  Map<String, dynamic> toJson() => {
    'name': name,
    'title': title,
    'bio': bio,
    if (userId != null) 'user_id': userId,
  };
}

class EventSponsor {
  final int id;
  final String name;
  final String? logoUrl;
  final String? website;
  final SponsorTier tier;
  final int order;

  EventSponsor({
    required this.id,
    required this.name,
    this.logoUrl,
    this.website,
    this.tier = SponsorTier.community,
    this.order = 0,
  });

  factory EventSponsor.fromJson(Map<String, dynamic> json) {
    return EventSponsor(
      id: _parseInt(json['id']),
      name: json['name']?.toString() ?? '',
      logoUrl: ApiConfig.sanitizeUrl(json['logo_url']?.toString()),
      website: json['website']?.toString(),
      tier: SponsorTier.fromApi(json['tier']?.toString()),
      order: _parseInt(json['order']),
    );
  }

  Map<String, dynamic> toJson() => {
    'name': name,
    'logo_url': logoUrl,
    'website': website,
    'tier': tier.name,
    'order': order,
  };
}
