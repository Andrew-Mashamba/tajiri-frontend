// lib/campus_news/models/campus_news_models.dart

// ─── News Category ───────────────────────────────────────────

enum CampusCategory {
  official,
  events,
  clubs,
  academic,
  sports,
  health,
  safety,
  accommodation;

  String get displayName {
    switch (this) {
      case CampusCategory.official:
        return 'Rasmi';
      case CampusCategory.events:
        return 'Matukio';
      case CampusCategory.clubs:
        return 'Vilabu';
      case CampusCategory.academic:
        return 'Masomo';
      case CampusCategory.sports:
        return 'Michezo';
      case CampusCategory.health:
        return 'Afya';
      case CampusCategory.safety:
        return 'Usalama';
      case CampusCategory.accommodation:
        return 'Makazi';
    }
  }

  String get subtitle {
    switch (this) {
      case CampusCategory.official:
        return 'Official';
      case CampusCategory.events:
        return 'Events';
      case CampusCategory.clubs:
        return 'Clubs';
      case CampusCategory.academic:
        return 'Academic';
      case CampusCategory.sports:
        return 'Sports';
      case CampusCategory.health:
        return 'Health';
      case CampusCategory.safety:
        return 'Safety';
      case CampusCategory.accommodation:
        return 'Housing';
    }
  }

  static CampusCategory fromString(String? s) {
    return CampusCategory.values.firstWhere(
      (v) => v.name == s,
      orElse: () => CampusCategory.official,
    );
  }
}

// ─── CampusAnnouncement ──────────────────────────────────────

class CampusAnnouncement {
  final int id;
  final String title;
  final String body;
  final String? imageUrl;
  final CampusCategory category;
  final String source;
  final String? sourceAvatar;
  final bool isVerified;
  final bool isEmergency;
  final bool isSaved;
  final int commentCount;
  final DateTime publishedAt;

  CampusAnnouncement({
    required this.id,
    required this.title,
    required this.body,
    this.imageUrl,
    required this.category,
    required this.source,
    this.sourceAvatar,
    this.isVerified = false,
    this.isEmergency = false,
    this.isSaved = false,
    this.commentCount = 0,
    required this.publishedAt,
  });

  factory CampusAnnouncement.fromJson(Map<String, dynamic> json) {
    return CampusAnnouncement(
      id: _parseInt(json['id']),
      title: json['title']?.toString() ?? '',
      body: json['body']?.toString() ?? '',
      imageUrl: json['image_url']?.toString(),
      category: CampusCategory.fromString(json['category']?.toString()),
      source: json['source']?.toString() ?? '',
      sourceAvatar: json['source_avatar']?.toString(),
      isVerified: _parseBool(json['is_verified']),
      isEmergency: _parseBool(json['is_emergency']),
      isSaved: _parseBool(json['is_saved']),
      commentCount: _parseInt(json['comment_count']),
      publishedAt:
          DateTime.tryParse(json['published_at']?.toString() ?? '') ??
              DateTime.now(),
    );
  }
}

// ─── CampusEvent ─────────────────────────────────────────────

class CampusEvent {
  final int id;
  final String title;
  final String description;
  final String venue;
  final DateTime startDate;
  final DateTime? endDate;
  final String? imageUrl;
  final String organizer;
  final int rsvpCount;
  final bool hasRsvped;

  CampusEvent({
    required this.id,
    required this.title,
    required this.description,
    required this.venue,
    required this.startDate,
    this.endDate,
    this.imageUrl,
    required this.organizer,
    this.rsvpCount = 0,
    this.hasRsvped = false,
  });

  factory CampusEvent.fromJson(Map<String, dynamic> json) {
    return CampusEvent(
      id: _parseInt(json['id']),
      title: json['title']?.toString() ?? '',
      description: json['description']?.toString() ?? '',
      venue: json['venue']?.toString() ?? '',
      startDate: DateTime.tryParse(json['start_date']?.toString() ?? '') ??
          DateTime.now(),
      endDate: DateTime.tryParse(json['end_date']?.toString() ?? ''),
      imageUrl: json['image_url']?.toString(),
      organizer: json['organizer']?.toString() ?? '',
      rsvpCount: _parseInt(json['rsvp_count']),
      hasRsvped: _parseBool(json['has_rsvped']),
    );
  }
}

// ─── Result wrappers ─────────────────────────────────────────

class CampusResult<T> {
  final bool success;
  final T? data;
  final String? message;

  CampusResult({required this.success, this.data, this.message});
}

class CampusListResult<T> {
  final bool success;
  final List<T> items;
  final String? message;

  CampusListResult({
    required this.success,
    this.items = const [],
    this.message,
  });
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
