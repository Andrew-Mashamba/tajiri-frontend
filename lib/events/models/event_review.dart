// lib/events/models/event_review.dart
import '../../config/api_config.dart';
import 'event_rsvp.dart';

int _parseInt(dynamic v) {
  if (v is int) return v;
  if (v is double) return v.toInt();
  if (v is String) return int.tryParse(v) ?? 0;
  return 0;
}

class EventReview {
  final int id;
  final int eventId;
  final int userId;
  final int rating;
  final String? content;
  final List<String> photoUrls;
  final int helpfulCount;
  final DateTime createdAt;
  final EventAttendee? user;

  EventReview({
    required this.id,
    required this.eventId,
    required this.userId,
    required this.rating,
    this.content,
    this.photoUrls = const [],
    this.helpfulCount = 0,
    required this.createdAt,
    this.user,
  });

  factory EventReview.fromJson(Map<String, dynamic> json) {
    return EventReview(
      id: _parseInt(json['id']),
      eventId: _parseInt(json['event_id']),
      userId: _parseInt(json['user_id']),
      rating: _parseInt(json['rating']),
      content: json['content']?.toString(),
      photoUrls: (json['photo_urls'] as List?)?.map((e) => ApiConfig.sanitizeUrl(e.toString()) ?? e.toString()).toList() ?? [],
      helpfulCount: _parseInt(json['helpful_count']),
      createdAt: DateTime.tryParse(json['created_at']?.toString() ?? '') ?? DateTime.now(),
      user: json['user'] != null ? EventAttendee.fromJson(json['user']) : null,
    );
  }
}
