// Models for the ad system — campaigns, creatives, performance, and served ads.

/// Helper to safely parse int from dynamic
int _parseInt(dynamic v) => v is int ? v : int.tryParse(v?.toString() ?? '') ?? 0;

/// Helper to safely parse double from dynamic
double _parseDouble(dynamic v) => v is double ? v : double.tryParse(v?.toString() ?? '') ?? 0.0;

/// Helper to safely parse bool from dynamic
bool _parseBool(dynamic v) => v == true || v == 1 || v == '1' || v == 'true';

/// An advertiser campaign with budget, targeting, and associated creatives.
class AdCampaign {
  final int id;
  final int advertiserId;
  final String title;
  final String? description;
  final String campaignType;
  final String status;
  final double dailyBudget;
  final double totalBudget;
  final double spentAmount;
  final double bidAmount;
  final String startDate;
  final String? endDate;
  final Map<String, dynamic> targeting;
  final List<String> placements;
  final String? rejectionReason;
  final String? createdAt;
  final String? updatedAt;
  final List<AdCreative>? creatives;

  AdCampaign({
    required this.id,
    required this.advertiserId,
    required this.title,
    this.description,
    required this.campaignType,
    required this.status,
    required this.dailyBudget,
    required this.totalBudget,
    required this.spentAmount,
    required this.bidAmount,
    required this.startDate,
    this.endDate,
    required this.targeting,
    required this.placements,
    this.rejectionReason,
    this.createdAt,
    this.updatedAt,
    this.creatives,
  });

  double get remainingBudget => totalBudget - spentAmount;

  factory AdCampaign.fromJson(Map<String, dynamic> json) {
    final rawPlacements = json['placements'];
    final List<String> placements;
    if (rawPlacements is List) {
      placements = rawPlacements.map((e) => e?.toString() ?? '').toList();
    } else {
      placements = [];
    }

    final rawCreatives = json['creatives'];
    final List<AdCreative>? creatives;
    if (rawCreatives is List) {
      creatives = rawCreatives
          .whereType<Map<String, dynamic>>()
          .map(AdCreative.fromJson)
          .toList();
    } else {
      creatives = null;
    }

    return AdCampaign(
      id: _parseInt(json['id']),
      advertiserId: _parseInt(json['advertiser_id']),
      title: (json['title'] as String?) ?? '',
      description: json['description'] as String?,
      campaignType: (json['campaign_type'] as String?) ?? '',
      status: (json['status'] as String?) ?? 'draft',
      dailyBudget: _parseDouble(json['daily_budget']),
      totalBudget: _parseDouble(json['total_budget']),
      spentAmount: _parseDouble(json['spent_amount']),
      bidAmount: _parseDouble(json['bid_amount']),
      startDate: (json['start_date'] as String?) ?? '',
      endDate: json['end_date'] as String?,
      targeting: (json['targeting'] is Map<String, dynamic>)
          ? json['targeting'] as Map<String, dynamic>
          : {},
      placements: placements,
      rejectionReason: json['rejection_reason'] as String?,
      createdAt: json['created_at'] as String?,
      updatedAt: json['updated_at'] as String?,
      creatives: creatives,
    );
  }

  Map<String, dynamic> toJson() => {
        'id': id,
        'advertiser_id': advertiserId,
        'title': title,
        if (description != null) 'description': description,
        'campaign_type': campaignType,
        'status': status,
        'daily_budget': dailyBudget,
        'total_budget': totalBudget,
        'spent_amount': spentAmount,
        'bid_amount': bidAmount,
        'start_date': startDate,
        if (endDate != null) 'end_date': endDate,
        'targeting': targeting,
        'placements': placements,
        if (rejectionReason != null) 'rejection_reason': rejectionReason,
        if (createdAt != null) 'created_at': createdAt,
        if (updatedAt != null) 'updated_at': updatedAt,
      };
}

/// A creative asset attached to a campaign (image, video, native, etc.).
class AdCreative {
  final int id;
  final int campaignId;
  final String format;
  final String? mediaUrl;
  final String headline;
  final String? bodyText;
  final String ctaType;
  final String ctaUrl;
  final int? productId;
  final bool approved;
  final String? createdAt;

  AdCreative({
    required this.id,
    required this.campaignId,
    required this.format,
    this.mediaUrl,
    required this.headline,
    this.bodyText,
    required this.ctaType,
    required this.ctaUrl,
    this.productId,
    required this.approved,
    this.createdAt,
  });

  factory AdCreative.fromJson(Map<String, dynamic> json) {
    return AdCreative(
      id: _parseInt(json['id']),
      campaignId: _parseInt(json['campaign_id']),
      format: (json['format'] as String?) ?? '',
      mediaUrl: json['media_url'] as String?,
      headline: (json['headline'] as String?) ?? '',
      bodyText: json['body_text'] as String?,
      ctaType: (json['cta_type'] as String?) ?? '',
      ctaUrl: (json['cta_url'] as String?) ?? '',
      productId: json['product_id'] != null ? _parseInt(json['product_id']) : null,
      approved: _parseBool(json['approved']),
      createdAt: json['created_at'] as String?,
    );
  }

  Map<String, dynamic> toJson() => {
        'id': id,
        'campaign_id': campaignId,
        'format': format,
        if (mediaUrl != null) 'media_url': mediaUrl,
        'headline': headline,
        if (bodyText != null) 'body_text': bodyText,
        'cta_type': ctaType,
        'cta_url': ctaUrl,
        if (productId != null) 'product_id': productId,
        'approved': approved,
        if (createdAt != null) 'created_at': createdAt,
      };
}

/// Aggregated performance metrics for a campaign.
class AdPerformance {
  final int totalImpressions;
  final int totalClicks;
  final double ctr;
  final double totalSpend;
  final List<DailyAdStat> dailyStats;

  AdPerformance({
    required this.totalImpressions,
    required this.totalClicks,
    required this.ctr,
    required this.totalSpend,
    required this.dailyStats,
  });

  factory AdPerformance.fromJson(Map<String, dynamic> json) {
    final rawStats = json['daily_stats'];
    final List<DailyAdStat> dailyStats;
    if (rawStats is List) {
      dailyStats = rawStats
          .whereType<Map<String, dynamic>>()
          .map(DailyAdStat.fromJson)
          .toList();
    } else {
      dailyStats = [];
    }

    return AdPerformance(
      totalImpressions: _parseInt(json['total_impressions']),
      totalClicks: _parseInt(json['total_clicks']),
      ctr: _parseDouble(json['ctr']),
      totalSpend: _parseDouble(json['total_spend']),
      dailyStats: dailyStats,
    );
  }

  Map<String, dynamic> toJson() => {
        'total_impressions': totalImpressions,
        'total_clicks': totalClicks,
        'ctr': ctr,
        'total_spend': totalSpend,
        'daily_stats': dailyStats.map((s) => s.toJson()).toList(),
      };
}

/// Performance data for a single day.
class DailyAdStat {
  final String date;
  final int impressions;
  final int clicks;
  final double spend;

  DailyAdStat({
    required this.date,
    required this.impressions,
    required this.clicks,
    required this.spend,
  });

  factory DailyAdStat.fromJson(Map<String, dynamic> json) {
    return DailyAdStat(
      date: (json['date'] as String?) ?? '',
      impressions: _parseInt(json['impressions']),
      clicks: _parseInt(json['clicks']),
      spend: _parseDouble(json['spend']),
    );
  }

  Map<String, dynamic> toJson() => {
        'date': date,
        'impressions': impressions,
        'clicks': clicks,
        'spend': spend,
      };
}

/// A resolved ad ready to be rendered in a placement surface.
class ServedAd {
  final int campaignId;
  final int creativeId;
  final String title;
  final String headline;
  final String? bodyText;
  final String? mediaUrl;
  final String ctaType;
  final String ctaUrl;
  final String campaignType;
  final String placement;

  ServedAd({
    required this.campaignId,
    required this.creativeId,
    required this.title,
    required this.headline,
    this.bodyText,
    this.mediaUrl,
    required this.ctaType,
    required this.ctaUrl,
    required this.campaignType,
    required this.placement,
  });

  factory ServedAd.fromJson(Map<String, dynamic> json) {
    return ServedAd(
      campaignId: _parseInt(json['campaign_id']),
      creativeId: _parseInt(json['creative_id']),
      title: (json['title'] as String?) ?? '',
      headline: (json['headline'] as String?) ?? '',
      bodyText: json['body_text'] as String?,
      mediaUrl: json['media_url'] as String?,
      ctaType: (json['cta_type'] as String?) ?? '',
      ctaUrl: (json['cta_url'] as String?) ?? '',
      campaignType: (json['campaign_type'] as String?) ?? '',
      placement: (json['placement'] as String?) ?? '',
    );
  }

  Map<String, dynamic> toJson() => {
        'campaign_id': campaignId,
        'creative_id': creativeId,
        'title': title,
        'headline': headline,
        if (bodyText != null) 'body_text': bodyText,
        if (mediaUrl != null) 'media_url': mediaUrl,
        'cta_type': ctaType,
        'cta_url': ctaUrl,
        'campaign_type': campaignType,
        'placement': placement,
      };
}
