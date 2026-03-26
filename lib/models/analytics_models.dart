// Models for creator analytics dashboard.

int _parseInt(dynamic value) {
  if (value == null) return 0;
  if (value is int) return value;
  if (value is String) return int.tryParse(value) ?? 0;
  return 0;
}

double _parseDouble(dynamic value, [double defaultValue = 0.0]) {
  if (value == null) return defaultValue;
  if (value is double) return value;
  if (value is int) return value.toDouble();
  if (value is String) return double.tryParse(value) ?? defaultValue;
  return defaultValue;
}

/// Full analytics dashboard data for a creator.
class AnalyticsDashboard {
  final int totalViews;
  final int totalLikes;
  final int totalShares;
  final int totalComments;
  final double avgEngagementRate;
  final int followerCount;
  final int followerChange30d;
  final int threadsTriggered30d;
  final int postsCount30d;
  final double sessionDepthAvg;
  final String bestPostingTime;
  final String topContentFormat;
  final String topCategory;
  final String engagementTrend;
  final List<DailyMetric> dailyMetrics;

  AnalyticsDashboard({
    required this.totalViews,
    required this.totalLikes,
    required this.totalShares,
    required this.totalComments,
    required this.avgEngagementRate,
    required this.followerCount,
    required this.followerChange30d,
    required this.threadsTriggered30d,
    required this.postsCount30d,
    required this.sessionDepthAvg,
    required this.bestPostingTime,
    required this.topContentFormat,
    required this.topCategory,
    required this.engagementTrend,
    required this.dailyMetrics,
  });

  factory AnalyticsDashboard.fromJson(Map<String, dynamic> json) {
    final rawMetrics = json['daily_metrics'] is List ? json['daily_metrics'] as List : [];
    return AnalyticsDashboard(
      totalViews: _parseInt(json['total_views']),
      totalLikes: _parseInt(json['total_likes']),
      totalShares: _parseInt(json['total_shares']),
      totalComments: _parseInt(json['total_comments']),
      avgEngagementRate: _parseDouble(json['avg_engagement_rate']),
      followerCount: _parseInt(json['follower_count']),
      followerChange30d: _parseInt(json['follower_change_30d']),
      threadsTriggered30d: _parseInt(json['threads_triggered_30d']),
      postsCount30d: _parseInt(json['posts_count_30d']),
      sessionDepthAvg: _parseDouble(json['session_depth_avg']),
      bestPostingTime: (json['best_posting_time'] as String?) ?? '',
      topContentFormat: (json['top_content_format'] as String?) ?? '',
      topCategory: (json['top_category'] as String?) ?? '',
      engagementTrend: (json['engagement_trend'] as String?) ?? 'stable',
      dailyMetrics: rawMetrics
          .whereType<Map<String, dynamic>>()
          .map((e) => DailyMetric.fromJson(e))
          .toList(),
    );
  }
}

/// Single day's metric point for charts.
class DailyMetric {
  final String date;
  final int views;
  final int likes;
  final int followers;

  DailyMetric({
    required this.date,
    required this.views,
    required this.likes,
    required this.followers,
  });

  factory DailyMetric.fromJson(Map<String, dynamic> json) {
    return DailyMetric(
      date: (json['date'] as String?) ?? '',
      views: _parseInt(json['views']),
      likes: _parseInt(json['likes']),
      followers: _parseInt(json['followers']),
    );
  }
}

/// Per-post analytics.
class PostPerformance {
  final int postId;
  final int views;
  final int likes;
  final int comments;
  final int shares;
  final int saves;
  final double engagementRate;
  final int avgDwellMs;
  final String? threadTitle;

  PostPerformance({
    required this.postId,
    required this.views,
    required this.likes,
    required this.comments,
    required this.shares,
    required this.saves,
    required this.engagementRate,
    required this.avgDwellMs,
    this.threadTitle,
  });

  factory PostPerformance.fromJson(Map<String, dynamic> json) {
    return PostPerformance(
      postId: _parseInt(json['post_id']),
      views: _parseInt(json['views']),
      likes: _parseInt(json['likes']),
      comments: _parseInt(json['comments']),
      shares: _parseInt(json['shares']),
      saves: _parseInt(json['saves']),
      engagementRate: _parseDouble(json['engagement_rate']),
      avgDwellMs: _parseInt(json['avg_dwell_ms']),
      threadTitle: json['thread_title'] as String?,
    );
  }
}

/// Audience demographic insights.
class AudienceInsight {
  final String topCity;
  final String topAgeRange;
  final double malePercent;
  final double femalePercent;
  final int activeFollowersCount;
  final String peakActivityTime;

  AudienceInsight({
    required this.topCity,
    required this.topAgeRange,
    required this.malePercent,
    required this.femalePercent,
    required this.activeFollowersCount,
    required this.peakActivityTime,
  });

  factory AudienceInsight.fromJson(Map<String, dynamic> json) {
    return AudienceInsight(
      topCity: (json['top_city'] as String?) ?? '',
      topAgeRange: (json['top_age_range'] as String?) ?? '',
      malePercent: _parseDouble(json['male_percent']),
      femalePercent: _parseDouble(json['female_percent']),
      activeFollowersCount: _parseInt(json['active_followers_count']),
      peakActivityTime: (json['peak_activity_time'] as String?) ?? '',
    );
  }
}
