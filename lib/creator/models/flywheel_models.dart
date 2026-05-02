// Models for the Flywheel event tracking and creator/viewer metrics.

/// Helper to safely parse int from dynamic
int _parseInt(dynamic value) {
  if (value == null) return 0;
  if (value is int) return value;
  if (value is String) return int.tryParse(value) ?? 0;
  return 0;
}

/// Helper to safely parse double from dynamic
double _parseDouble(dynamic value, [double defaultValue = 0.0]) {
  if (value == null) return defaultValue;
  if (value is double) return value;
  if (value is int) return value.toDouble();
  if (value is String) return double.tryParse(value) ?? defaultValue;
  return defaultValue;
}

/// Helper to safely parse bool from dynamic
bool _parseBool(dynamic value, [bool defaultValue = false]) {
  if (value == null) return defaultValue;
  if (value is bool) return value;
  if (value is int) return value != 0;
  if (value is String) return value.toLowerCase() == 'true' || value == '1';
  return defaultValue;
}

/// A single user behavior event for the Flywheel tracking pipeline.
class UserEvent {
  final String eventType;
  final int? postId;
  final int? creatorId;
  final DateTime timestamp;
  final int durationMs;
  final String sessionId;
  final Map<String, dynamic>? metadata;

  UserEvent({
    required this.eventType,
    this.postId,
    this.creatorId,
    required this.timestamp,
    this.durationMs = 0,
    required this.sessionId,
    this.metadata,
  });

  Map<String, dynamic> toJson() {
    final json = <String, dynamic>{
      'event_type': eventType,
      'timestamp': timestamp.toUtc().toIso8601String(),
      'duration_ms': durationMs,
      'session_id': sessionId,
    };
    if (postId != null) json['post_id'] = postId;
    if (creatorId != null) json['creator_id'] = creatorId;
    if (metadata != null && metadata!.isNotEmpty) json['metadata'] = metadata;
    return json;
  }

  String deduplicationKey({required int userId}) {
    final ts = timestamp.toUtc();
    final truncated = DateTime.utc(
        ts.year, ts.month, ts.day, ts.hour, ts.minute, ts.second);
    return '${userId}_${eventType}_${postId ?? 0}_${truncated.toIso8601String().split('.').first}';
  }
}

/// Creator posting streak with multiplier calculation.
class CreatorStreak {
  final int userId;
  final int currentStreakDays;
  final int longestStreakDays;
  final DateTime? lastPostAt;
  final int bankedSkipDays;
  final bool isFrozen;
  final DateTime? frozenAt;
  final double streakMultiplier;

  CreatorStreak({
    required this.userId,
    required this.currentStreakDays,
    required this.longestStreakDays,
    this.lastPostAt,
    required this.bankedSkipDays,
    required this.isFrozen,
    this.frozenAt,
    required this.streakMultiplier,
  });

  factory CreatorStreak.fromJson(Map<String, dynamic> json) {
    return CreatorStreak(
      userId: _parseInt(json['user_id']),
      currentStreakDays: _parseInt(json['current_streak_days']),
      longestStreakDays: _parseInt(json['longest_streak_days']),
      lastPostAt: json['last_post_at'] != null
          ? DateTime.tryParse(json['last_post_at'].toString())
          : null,
      bankedSkipDays: _parseInt(json['banked_skip_days']),
      isFrozen: _parseBool(json['is_frozen']),
      frozenAt: json['frozen_at'] != null
          ? DateTime.tryParse(json['frozen_at'].toString())
          : null,
      streakMultiplier: _parseDouble(json['streak_multiplier'], 1.0),
    );
  }
}

/// Viewer daily open streak.
class ViewerStreak {
  final int userId;
  final int currentStreakDays;
  final int longestStreakDays;
  final String? lastActiveDate;
  final bool isFrozen;
  final DateTime? frozenAt;

  ViewerStreak({
    required this.userId,
    required this.currentStreakDays,
    required this.longestStreakDays,
    this.lastActiveDate,
    required this.isFrozen,
    this.frozenAt,
  });

  factory ViewerStreak.fromJson(Map<String, dynamic> json) {
    return ViewerStreak(
      userId: _parseInt(json['user_id']),
      currentStreakDays: _parseInt(json['current_streak_days']),
      longestStreakDays: _parseInt(json['longest_streak_days']),
      lastActiveDate: json['last_active_date']?.toString(),
      isFrozen: _parseBool(json['is_frozen']),
      frozenAt: json['frozen_at'] != null
          ? DateTime.tryParse(json['frozen_at'].toString())
          : null,
    );
  }
}

/// Creator score with tier and component breakdowns.
class CreatorScore {
  final int userId;
  final double score;
  final String tier;
  final double communityScore;
  final double qualityScore;
  final double consistencyScore;
  final double tierMultiplier;
  final DateTime? computedAt;

  CreatorScore({
    required this.userId,
    required this.score,
    required this.tier,
    required this.communityScore,
    required this.qualityScore,
    required this.consistencyScore,
    required this.tierMultiplier,
    this.computedAt,
  });

  factory CreatorScore.fromJson(Map<String, dynamic> json) {
    return CreatorScore(
      userId: _parseInt(json['user_id']),
      score: _parseDouble(json['score']),
      tier: (json['tier'] as String?) ?? 'rising',
      communityScore: _parseDouble(json['community_score']),
      qualityScore: _parseDouble(json['quality_score']),
      consistencyScore: _parseDouble(json['consistency_score']),
      tierMultiplier: _parseDouble(json['tier_multiplier'], 1.0),
      computedAt: json['computed_at'] != null
          ? DateTime.tryParse(json['computed_at'].toString())
          : null,
    );
  }
}

/// Fund payout projection for current month.
class FundPayoutProjection {
  final int userId;
  final String currentMonth;
  final double projectedScore;
  final double projectedPayout;
  final String tier;
  final Map<String, dynamic> multipliers;

  FundPayoutProjection({
    required this.userId,
    required this.currentMonth,
    required this.projectedScore,
    required this.projectedPayout,
    required this.tier,
    required this.multipliers,
  });

  factory FundPayoutProjection.fromJson(Map<String, dynamic> json) {
    return FundPayoutProjection(
      userId: _parseInt(json['user_id']),
      currentMonth: (json['current_month'] as String?) ?? '',
      projectedScore: _parseDouble(json['projected_score']),
      projectedPayout: _parseDouble(json['projected_payout']),
      tier: (json['tier'] as String?) ?? 'rising',
      multipliers: json['multipliers'] is Map<String, dynamic>
          ? json['multipliers'] as Map<String, dynamic>
          : {},
    );
  }
}

/// Posting nudge suggestion from backend.
class PostingNudge {
  final String message;
  final String messageSwahili;
  final String nudgeType; // 'peak_hour', 'streak_warning', 'consistency', 'engagement_tip'
  final int? hoursUntilStreakExpiry;

  PostingNudge({
    required this.message,
    required this.messageSwahili,
    required this.nudgeType,
    this.hoursUntilStreakExpiry,
  });

  factory PostingNudge.fromJson(Map<String, dynamic> json) {
    return PostingNudge(
      message: (json['message'] as String?) ?? '',
      messageSwahili: (json['message_sw'] as String?) ?? (json['message'] as String?) ?? '',
      nudgeType: (json['nudge_type'] as String?) ?? 'engagement_tip',
      hoursUntilStreakExpiry: json['hours_until_streak_expiry'] as int?,
    );
  }
}

/// Content calendar data for creator dashboard.
class ContentCalendar {
  final int draftsCount;
  final int postsThisWeek;
  final int scheduledCount;
  final String? suggestedPostTime;

  ContentCalendar({
    required this.draftsCount,
    required this.postsThisWeek,
    required this.scheduledCount,
    this.suggestedPostTime,
  });

  factory ContentCalendar.fromJson(Map<String, dynamic> json) {
    return ContentCalendar(
      draftsCount: (json['drafts_count'] as int?) ?? 0,
      postsThisWeek: (json['posts_this_week'] as int?) ?? 0,
      scheduledCount: (json['scheduled_count'] as int?) ?? 0,
      suggestedPostTime: json['suggested_post_time'] as String?,
    );
  }
}
