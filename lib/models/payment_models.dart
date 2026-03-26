// Models for creator fund pools, payouts, and weekly performance reports.

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

/// Monthly creator fund pool that gets distributed to eligible creators.
class CreatorFundPool {
  final int id;
  final double totalAmount;
  final String currency;
  final String month;
  final bool isDistributed;
  final DateTime? distributedAt;

  CreatorFundPool({
    required this.id,
    required this.totalAmount,
    required this.currency,
    required this.month,
    required this.isDistributed,
    this.distributedAt,
  });

  factory CreatorFundPool.fromJson(Map<String, dynamic> json) {
    return CreatorFundPool(
      id: _parseInt(json['id']),
      totalAmount: _parseDouble(json['total_amount']),
      currency: (json['currency'] as String?) ?? 'KES',
      month: (json['month'] as String?) ?? '',
      isDistributed: _parseBool(json['is_distributed']),
      distributedAt: json['distributed_at'] != null
          ? DateTime.tryParse(json['distributed_at'].toString())
          : null,
    );
  }
}

/// Individual creator payout record from a monthly fund distribution.
class CreatorFundPayout {
  final int id;
  final int userId;
  final double baseScore;
  final double tierMultiplier;
  final double streakMultiplier;
  final double communityMultiplier;
  final double viralityMultiplier;
  final double effectiveMultiplier;
  final double finalScore;
  final double payoutAmount;
  final String payoutCurrency;
  final String status;
  final DateTime? paidAt;

  CreatorFundPayout({
    required this.id,
    required this.userId,
    required this.baseScore,
    required this.tierMultiplier,
    required this.streakMultiplier,
    required this.communityMultiplier,
    required this.viralityMultiplier,
    required this.effectiveMultiplier,
    required this.finalScore,
    required this.payoutAmount,
    required this.payoutCurrency,
    required this.status,
    this.paidAt,
  });

  factory CreatorFundPayout.fromJson(Map<String, dynamic> json) {
    return CreatorFundPayout(
      id: _parseInt(json['id']),
      userId: _parseInt(json['user_id']),
      baseScore: _parseDouble(json['base_score']),
      tierMultiplier: _parseDouble(json['tier_multiplier'], 1.0),
      streakMultiplier: _parseDouble(json['streak_multiplier'], 1.0),
      communityMultiplier: _parseDouble(json['community_multiplier'], 1.0),
      viralityMultiplier: _parseDouble(json['virality_multiplier'], 1.0),
      effectiveMultiplier: _parseDouble(json['effective_multiplier'], 1.0),
      finalScore: _parseDouble(json['final_score']),
      payoutAmount: _parseDouble(json['payout_amount']),
      payoutCurrency: (json['payout_currency'] as String?) ?? 'KES',
      status: (json['status'] as String?) ?? 'pending',
      paidAt: json['paid_at'] != null
          ? DateTime.tryParse(json['paid_at'].toString())
          : null,
    );
  }
}

/// Weekly performance summary for a creator.
class WeeklyReport {
  final double totalEarnings;
  final double earningsChangePercent;
  final int? bestPostId;
  final int bestPostLikes;
  final String engagementTrend;
  final int followerChange;
  final int threadsTriggered;
  final int totalViews;
  final int totalLikes;
  final String weekStart;
  final String weekEnd;

  WeeklyReport({
    required this.totalEarnings,
    required this.earningsChangePercent,
    this.bestPostId,
    required this.bestPostLikes,
    required this.engagementTrend,
    required this.followerChange,
    required this.threadsTriggered,
    required this.totalViews,
    required this.totalLikes,
    required this.weekStart,
    required this.weekEnd,
  });

  factory WeeklyReport.fromJson(Map<String, dynamic> json) {
    return WeeklyReport(
      totalEarnings: _parseDouble(json['total_earnings']),
      earningsChangePercent: _parseDouble(json['earnings_change_percent']),
      bestPostId: json['best_post_id'] != null
          ? _parseInt(json['best_post_id'])
          : null,
      bestPostLikes: _parseInt(json['best_post_likes']),
      engagementTrend: (json['engagement_trend'] as String?) ?? 'stable',
      followerChange: _parseInt(json['follower_change']),
      threadsTriggered: _parseInt(json['threads_triggered']),
      totalViews: _parseInt(json['total_views']),
      totalLikes: _parseInt(json['total_likes']),
      weekStart: (json['week_start'] as String?) ?? '',
      weekEnd: (json['week_end'] as String?) ?? '',
    );
  }
}
