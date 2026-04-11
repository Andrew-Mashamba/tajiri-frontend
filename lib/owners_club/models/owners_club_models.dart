// lib/owners_club/models/owners_club_models.dart
import '../../config/api_config.dart';

// ─── Helpers ───────────────────────────────────────────────────

int _parseInt(dynamic v, [int fallback = 0]) {
  if (v is int) return v;
  if (v is double) return v.toInt();
  if (v is String) return int.tryParse(v) ?? fallback;
  return fallback;
}

double _parseDouble(dynamic v, [double fallback = 0.0]) {
  if (v is double) return v;
  if (v is int) return v.toDouble();
  if (v is String) return double.tryParse(v) ?? fallback;
  return fallback;
}

bool _parseBool(dynamic v, [bool fallback = false]) {
  if (v is bool) return v;
  if (v is int) return v == 1;
  if (v is String) return v == '1' || v.toLowerCase() == 'true';
  return fallback;
}

String? _imageUrl(dynamic v) {
  if (v == null) return null;
  return ApiConfig.sanitizeUrl(v.toString());
}

// ─── Result wrappers ──────────────────────────────────────────

class SingleResult<T> {
  final bool success;
  final T? data;
  final String? message;
  SingleResult({required this.success, this.data, this.message});
}

class PaginatedResult<T> {
  final bool success;
  final List<T> items;
  final int currentPage;
  final int lastPage;
  final String? message;
  PaginatedResult({
    required this.success,
    this.items = const [],
    this.currentPage = 1,
    this.lastPage = 1,
    this.message,
  });
}

// ─── Community ────────────────────────────────────────────────

enum CommunityType {
  brand,
  model,
  regional;

  static CommunityType fromString(String? s) {
    return CommunityType.values.firstWhere(
      (v) => v.name == s,
      orElse: () => CommunityType.brand,
    );
  }
}

class Community {
  final int id;
  final String name;
  final String? brand;
  final String? model;
  final CommunityType type;
  final String? description;
  final int memberCount;
  final String? logoUrl;
  final String? rules;
  final bool isJoined;
  final String role;
  final DateTime? createdAt;

  Community({
    required this.id,
    required this.name,
    this.brand,
    this.model,
    this.type = CommunityType.brand,
    this.description,
    this.memberCount = 0,
    this.logoUrl,
    this.rules,
    this.isJoined = false,
    this.role = 'member',
    this.createdAt,
  });

  factory Community.fromJson(Map<String, dynamic> json) {
    return Community(
      id: _parseInt(json['id']),
      name: json['name'] ?? '',
      brand: json['brand'],
      model: json['model'],
      type: CommunityType.fromString(json['type']),
      description: json['description'],
      memberCount: _parseInt(json['member_count']),
      logoUrl: _imageUrl(json['logo_url']),
      rules: json['rules'],
      isJoined: _parseBool(json['is_joined']),
      role: json['role'] ?? 'member',
      createdAt: DateTime.tryParse(json['created_at'] ?? ''),
    );
  }
}

// ─── Vehicle Showcase ─────────────────────────────────────────

class VehicleShowcase {
  final int id;
  final int userId;
  final int communityId;
  final String? userName;
  final String? userAvatar;
  final String make;
  final String model;
  final int year;
  final List<String> photos;
  final String? story;
  final List<Modification> modifications;
  final int votes;
  final DateTime? createdAt;

  VehicleShowcase({
    required this.id,
    required this.userId,
    required this.communityId,
    this.userName,
    this.userAvatar,
    this.make = '',
    this.model = '',
    this.year = 0,
    this.photos = const [],
    this.story,
    this.modifications = const [],
    this.votes = 0,
    this.createdAt,
  });

  factory VehicleShowcase.fromJson(Map<String, dynamic> json) {
    return VehicleShowcase(
      id: _parseInt(json['id']),
      userId: _parseInt(json['user_id']),
      communityId: _parseInt(json['community_id']),
      userName: json['user_name'],
      userAvatar: _imageUrl(json['user_avatar']),
      make: json['make'] ?? '',
      model: json['model'] ?? '',
      year: _parseInt(json['year']),
      photos: (json['photos'] as List?)
              ?.map((p) => _imageUrl(p) ?? '')
              .where((p) => p.isNotEmpty)
              .toList() ??
          [],
      story: json['story'],
      modifications: (json['modifications'] as List?)
              ?.map((m) => Modification.fromJson(m))
              .toList() ??
          [],
      votes: _parseInt(json['votes']),
      createdAt: DateTime.tryParse(json['created_at'] ?? ''),
    );
  }

  String get title => '$make $model ${year > 0 ? '($year)' : ''}';
}

class Modification {
  final String name;
  final String? description;
  final double? cost;
  final String? photoUrl;

  Modification({required this.name, this.description, this.cost, this.photoUrl});

  factory Modification.fromJson(Map<String, dynamic> json) {
    return Modification(
      name: json['name'] ?? '',
      description: json['description'],
      cost: json['cost'] != null ? _parseDouble(json['cost']) : null,
      photoUrl: _imageUrl(json['photo_url']),
    );
  }
}

// ─── Knowledge Post ───────────────────────────────────────────

class KnowledgePost {
  final int id;
  final int communityId;
  final int authorId;
  final String? authorName;
  final String? authorAvatar;
  final String title;
  final String content;
  final List<String> tags;
  final bool solutionMarked;
  final bool isPinned;
  final int upvotes;
  final int replyCount;
  final DateTime? createdAt;

  KnowledgePost({
    required this.id,
    required this.communityId,
    required this.authorId,
    this.authorName,
    this.authorAvatar,
    required this.title,
    this.content = '',
    this.tags = const [],
    this.solutionMarked = false,
    this.isPinned = false,
    this.upvotes = 0,
    this.replyCount = 0,
    this.createdAt,
  });

  factory KnowledgePost.fromJson(Map<String, dynamic> json) {
    return KnowledgePost(
      id: _parseInt(json['id']),
      communityId: _parseInt(json['community_id']),
      authorId: _parseInt(json['author_id']),
      authorName: json['author_name'],
      authorAvatar: _imageUrl(json['author_avatar']),
      title: json['title'] ?? '',
      content: json['content'] ?? '',
      tags: (json['tags'] as List?)?.cast<String>() ?? [],
      solutionMarked: _parseBool(json['solution_marked']),
      isPinned: _parseBool(json['is_pinned']),
      upvotes: _parseInt(json['upvotes']),
      replyCount: _parseInt(json['reply_count']),
      createdAt: DateTime.tryParse(json['created_at'] ?? ''),
    );
  }
}

// ─── Community Event ──────────────────────────────────────────

class CommunityEvent {
  final int id;
  final int communityId;
  final String title;
  final String type;
  final DateTime? eventDate;
  final String? location;
  final String? description;
  final int rsvpCount;
  final int? maxCapacity;
  final bool hasRsvped;

  CommunityEvent({
    required this.id,
    required this.communityId,
    required this.title,
    this.type = 'meetup',
    this.eventDate,
    this.location,
    this.description,
    this.rsvpCount = 0,
    this.maxCapacity,
    this.hasRsvped = false,
  });

  factory CommunityEvent.fromJson(Map<String, dynamic> json) {
    return CommunityEvent(
      id: _parseInt(json['id']),
      communityId: _parseInt(json['community_id']),
      title: json['title'] ?? '',
      type: json['type'] ?? 'meetup',
      eventDate: DateTime.tryParse(json['event_date'] ?? ''),
      location: json['location'] is Map
          ? json['location']['name']
          : json['location']?.toString(),
      description: json['description'],
      rsvpCount: _parseInt(json['rsvp_count']),
      maxCapacity:
          json['max_capacity'] != null ? _parseInt(json['max_capacity']) : null,
      hasRsvped: _parseBool(json['has_rsvped']),
    );
  }
}
