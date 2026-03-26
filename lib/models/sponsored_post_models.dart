// Models for sponsored posts marketplace.

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

/// Status of a sponsored post campaign.
enum SponsoredPostStatus {
  draft, pending, active, completed, cancelled;

  factory SponsoredPostStatus.fromString(String? s) {
    switch (s?.toLowerCase()) {
      case 'pending': return SponsoredPostStatus.pending;
      case 'active': return SponsoredPostStatus.active;
      case 'completed': return SponsoredPostStatus.completed;
      case 'cancelled': return SponsoredPostStatus.cancelled;
      default: return SponsoredPostStatus.draft;
    }
  }
}

/// A sponsored post campaign linking a business sponsor to a creator's post.
class SponsoredPost {
  final int id;
  final int postId;
  final int sponsorUserId;
  final int creatorUserId;
  final double budget;
  final String currency;
  final SponsoredPostStatus status;
  final String tierRequired;
  final int impressionsTarget;
  final int impressionsDelivered;
  final String? sponsorName;
  final String? creatorName;
  final DateTime createdAt;

  SponsoredPost({
    required this.id,
    required this.postId,
    required this.sponsorUserId,
    required this.creatorUserId,
    required this.budget,
    required this.currency,
    required this.status,
    required this.tierRequired,
    required this.impressionsTarget,
    required this.impressionsDelivered,
    this.sponsorName,
    this.creatorName,
    required this.createdAt,
  });

  factory SponsoredPost.fromJson(Map<String, dynamic> json) {
    return SponsoredPost(
      id: _parseInt(json['id']),
      postId: _parseInt(json['post_id']),
      sponsorUserId: _parseInt(json['sponsor_user_id']),
      creatorUserId: _parseInt(json['creator_user_id']),
      budget: _parseDouble(json['budget']),
      currency: (json['currency'] as String?) ?? 'TSh',
      status: SponsoredPostStatus.fromString(json['status'] as String?),
      tierRequired: (json['tier_required'] as String?) ?? 'star',
      impressionsTarget: _parseInt(json['impressions_target']),
      impressionsDelivered: _parseInt(json['impressions_delivered']),
      sponsorName: json['sponsor_name'] as String?,
      creatorName: json['creator_name'] as String?,
      createdAt: json['created_at'] != null
          ? DateTime.tryParse(json['created_at'].toString()) ?? DateTime.now()
          : DateTime.now(),
    );
  }

  double get deliveryPercent => impressionsTarget > 0
      ? (impressionsDelivered / impressionsTarget * 100).clamp(0, 100)
      : 0;
}

/// A creator available for sponsorship (browse result).
class SponsorableCreator {
  final int userId;
  final String name;
  final String? avatarUrl;
  final String tier;
  final int followerCount;
  final double avgEngagementRate;
  final String topCategory;

  SponsorableCreator({
    required this.userId,
    required this.name,
    this.avatarUrl,
    required this.tier,
    required this.followerCount,
    required this.avgEngagementRate,
    required this.topCategory,
  });

  factory SponsorableCreator.fromJson(Map<String, dynamic> json) {
    return SponsorableCreator(
      userId: _parseInt(json['user_id']),
      name: (json['name'] as String?) ?? '',
      avatarUrl: json['avatar_url'] as String?,
      tier: (json['tier'] as String?) ?? 'star',
      followerCount: _parseInt(json['follower_count']),
      avgEngagementRate: _parseDouble(json['avg_engagement_rate']),
      topCategory: (json['top_category'] as String?) ?? '',
    );
  }
}
