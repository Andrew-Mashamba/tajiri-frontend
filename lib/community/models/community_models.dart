// lib/community/models/community_models.dart

// ─── Community Post Type ───────────────────────────────────────

enum CommunityPostType {
  alert,
  question,
  recommendation,
  event,
  general;

  String get displayName {
    switch (this) {
      case CommunityPostType.alert:
        return 'Tahadhari';
      case CommunityPostType.question:
        return 'Swali';
      case CommunityPostType.recommendation:
        return 'Pendekezo';
      case CommunityPostType.event:
        return 'Tukio';
      case CommunityPostType.general:
        return 'Kawaida';
    }
  }

  String get subtitle {
    switch (this) {
      case CommunityPostType.alert:
        return 'Alert';
      case CommunityPostType.question:
        return 'Question';
      case CommunityPostType.recommendation:
        return 'Recommendation';
      case CommunityPostType.event:
        return 'Event';
      case CommunityPostType.general:
        return 'General';
    }
  }
}

// ─── Community Post ────────────────────────────────────────────

class CommunityPost {
  final int id;
  final int userId;
  final String userName;
  final String? userAvatar;
  final String content;
  final CommunityPostType type;
  final String? location;
  final DateTime createdAt;
  final int likesCount;
  final int commentsCount;
  final bool isLiked;

  CommunityPost({
    required this.id,
    required this.userId,
    required this.userName,
    this.userAvatar,
    required this.content,
    required this.type,
    this.location,
    required this.createdAt,
    this.likesCount = 0,
    this.commentsCount = 0,
    this.isLiked = false,
  });

  factory CommunityPost.fromJson(Map<String, dynamic> json) {
    return CommunityPost(
      id: _parseInt(json['id']),
      userId: _parseInt(json['user_id']),
      userName: json['user_name']?.toString() ?? '',
      userAvatar: json['user_avatar']?.toString(),
      content: json['content']?.toString() ?? '',
      type: _parsePostType(json['type']),
      location: json['location']?.toString(),
      createdAt: DateTime.tryParse(json['created_at']?.toString() ?? '') ??
          DateTime.now(),
      likesCount: _parseInt(json['likes_count']),
      commentsCount: _parseInt(json['comments_count']),
      isLiked: _parseBool(json['is_liked']),
    );
  }
}

// ─── Local Service Type ────────────────────────────────────────

enum LocalServiceType {
  hospital,
  police,
  fire,
  school,
  market;

  String get displayName {
    switch (this) {
      case LocalServiceType.hospital:
        return 'Hospitali';
      case LocalServiceType.police:
        return 'Polisi';
      case LocalServiceType.fire:
        return 'Zimamoto';
      case LocalServiceType.school:
        return 'Shule';
      case LocalServiceType.market:
        return 'Soko';
    }
  }

  String get subtitle {
    switch (this) {
      case LocalServiceType.hospital:
        return 'Hospital';
      case LocalServiceType.police:
        return 'Police';
      case LocalServiceType.fire:
        return 'Fire Station';
      case LocalServiceType.school:
        return 'School';
      case LocalServiceType.market:
        return 'Market';
    }
  }
}

// ─── Local Service ─────────────────────────────────────────────

class LocalService {
  final int id;
  final String name;
  final LocalServiceType type;
  final String address;
  final String? phone;
  final double latitude;
  final double longitude;
  final double? distanceKm;

  LocalService({
    required this.id,
    required this.name,
    required this.type,
    required this.address,
    this.phone,
    required this.latitude,
    required this.longitude,
    this.distanceKm,
  });

  factory LocalService.fromJson(Map<String, dynamic> json) {
    return LocalService(
      id: _parseInt(json['id']),
      name: json['name']?.toString() ?? '',
      type: _parseServiceType(json['type']),
      address: json['address']?.toString() ?? '',
      phone: json['phone']?.toString(),
      latitude: _parseDouble(json['latitude']),
      longitude: _parseDouble(json['longitude']),
      distanceKm: json['distance_km'] != null
          ? _parseDouble(json['distance_km'])
          : null,
    );
  }
}

// ─── Emergency Contact ─────────────────────────────────────────

class EmergencyContact {
  final String name;
  final String number;
  final String description;

  EmergencyContact({
    required this.name,
    required this.number,
    required this.description,
  });
}

// ─── Result wrappers ───────────────────────────────────────────

class CommunityResult<T> {
  final bool success;
  final T? data;
  final String? message;

  CommunityResult({required this.success, this.data, this.message});
}

class CommunityListResult<T> {
  final bool success;
  final List<T> items;
  final String? message;

  CommunityListResult({
    required this.success,
    this.items = const [],
    this.message,
  });
}

// ─── Parse helpers ─────────────────────────────────────────────

int _parseInt(dynamic v) {
  if (v is int) return v;
  if (v is double) return v.toInt();
  if (v is String) return int.tryParse(v) ?? 0;
  return 0;
}

double _parseDouble(dynamic v) {
  if (v is double) return v;
  if (v is int) return v.toDouble();
  if (v is String) return double.tryParse(v) ?? 0.0;
  return 0.0;
}

bool _parseBool(dynamic v) {
  if (v is bool) return v;
  if (v is int) return v != 0;
  if (v is String) return v == '1' || v.toLowerCase() == 'true';
  return false;
}

CommunityPostType _parsePostType(dynamic v) {
  final s = v?.toString().toLowerCase() ?? '';
  switch (s) {
    case 'alert':
      return CommunityPostType.alert;
    case 'question':
      return CommunityPostType.question;
    case 'recommendation':
      return CommunityPostType.recommendation;
    case 'event':
      return CommunityPostType.event;
    default:
      return CommunityPostType.general;
  }
}

LocalServiceType _parseServiceType(dynamic v) {
  final s = v?.toString().toLowerCase() ?? '';
  switch (s) {
    case 'hospital':
      return LocalServiceType.hospital;
    case 'police':
      return LocalServiceType.police;
    case 'fire':
      return LocalServiceType.fire;
    case 'school':
      return LocalServiceType.school;
    case 'market':
      return LocalServiceType.market;
    default:
      return LocalServiceType.hospital;
  }
}
