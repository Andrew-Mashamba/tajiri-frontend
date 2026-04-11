// lib/events/models/event_wall.dart
import '../../config/api_config.dart';
import 'event_enums.dart';
import 'event_rsvp.dart';

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

List<String> _parseUrls(dynamic v) {
  if (v is List) return v.map((e) => ApiConfig.sanitizeUrl(e.toString()) ?? e.toString()).toList();
  return [];
}

class EventComment {
  final int id;
  final int eventId;
  final int userId;
  final String content;
  final List<String> mediaUrls;
  final int likesCount;
  final int repliesCount;
  final bool isLiked;
  final bool isPinned;
  final DateTime createdAt;
  final EventAttendee? user;
  final List<EventComment> replies;

  EventComment({
    required this.id,
    required this.eventId,
    required this.userId,
    required this.content,
    this.mediaUrls = const [],
    this.likesCount = 0,
    this.repliesCount = 0,
    this.isLiked = false,
    this.isPinned = false,
    required this.createdAt,
    this.user,
    this.replies = const [],
  });

  factory EventComment.fromJson(Map<String, dynamic> json) {
    return EventComment(
      id: _parseInt(json['id']),
      eventId: _parseInt(json['event_id']),
      userId: _parseInt(json['user_id']),
      content: json['content']?.toString() ?? '',
      mediaUrls: _parseUrls(json['media_urls']),
      likesCount: _parseInt(json['likes_count']),
      repliesCount: _parseInt(json['replies_count']),
      isLiked: _parseBool(json['is_liked']),
      isPinned: _parseBool(json['is_pinned']),
      createdAt: DateTime.tryParse(json['created_at']?.toString() ?? '') ?? DateTime.now(),
      user: json['user'] != null ? EventAttendee.fromJson(json['user']) : null,
      replies: (json['replies'] as List?)?.map((e) => EventComment.fromJson(e)).toList() ?? [],
    );
  }
}

class EventWallPost {
  final int id;
  final int eventId;
  final int userId;
  final EventWallPostType type;
  final String? content;
  final List<String> mediaUrls;
  final int likesCount;
  final int commentsCount;
  final bool isLiked;
  final bool isPinned;
  final DateTime createdAt;
  final EventAttendee? user;
  final List<PollOption>? pollOptions;
  final bool isAnnouncement;

  EventWallPost({
    required this.id,
    required this.eventId,
    required this.userId,
    this.type = EventWallPostType.text,
    this.content,
    this.mediaUrls = const [],
    this.likesCount = 0,
    this.commentsCount = 0,
    this.isLiked = false,
    this.isPinned = false,
    required this.createdAt,
    this.user,
    this.pollOptions,
    this.isAnnouncement = false,
  });

  factory EventWallPost.fromJson(Map<String, dynamic> json) {
    return EventWallPost(
      id: _parseInt(json['id']),
      eventId: _parseInt(json['event_id']),
      userId: _parseInt(json['user_id']),
      type: EventWallPostType.fromApi(json['type']?.toString()),
      content: json['content']?.toString(),
      mediaUrls: _parseUrls(json['media_urls']),
      likesCount: _parseInt(json['likes_count']),
      commentsCount: _parseInt(json['comments_count']),
      isLiked: _parseBool(json['is_liked']),
      isPinned: _parseBool(json['is_pinned']),
      createdAt: DateTime.tryParse(json['created_at']?.toString() ?? '') ?? DateTime.now(),
      user: json['user'] != null ? EventAttendee.fromJson(json['user']) : null,
      pollOptions: (json['poll_options'] as List?)?.map((e) => PollOption.fromJson(e)).toList(),
      isAnnouncement: _parseBool(json['is_announcement']),
    );
  }
}

class PollOption {
  final int id;
  final String text;
  final int votesCount;
  final bool isVoted;

  PollOption({required this.id, required this.text, this.votesCount = 0, this.isVoted = false});

  factory PollOption.fromJson(Map<String, dynamic> json) {
    return PollOption(
      id: _parseInt(json['id']),
      text: json['text']?.toString() ?? '',
      votesCount: _parseInt(json['votes_count']),
      isVoted: _parseBool(json['is_voted']),
    );
  }
}

class EventPhoto {
  final int id;
  final int eventId;
  final int userId;
  final String url;
  final String? caption;
  final DateTime createdAt;
  final EventAttendee? user;

  EventPhoto({required this.id, required this.eventId, required this.userId, required this.url, this.caption, required this.createdAt, this.user});

  factory EventPhoto.fromJson(Map<String, dynamic> json) {
    return EventPhoto(
      id: _parseInt(json['id']),
      eventId: _parseInt(json['event_id']),
      userId: _parseInt(json['user_id']),
      url: ApiConfig.sanitizeUrl(json['url']?.toString()) ?? '',
      caption: json['caption']?.toString(),
      createdAt: DateTime.tryParse(json['created_at']?.toString() ?? '') ?? DateTime.now(),
      user: json['user'] != null ? EventAttendee.fromJson(json['user']) : null,
    );
  }
}
