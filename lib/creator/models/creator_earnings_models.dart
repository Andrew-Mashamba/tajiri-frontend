// lib/creator/models/creator_earnings_models.dart
//
// Data models for the Creators Fund engine — strategy §1.2 + §9.

int _parseInt(dynamic v) {
  if (v == null) return 0;
  if (v is int) return v;
  if (v is String) return int.tryParse(v) ?? 0;
  return 0;
}

double _parseDouble(dynamic v, [double d = 0.0]) {
  if (v == null) return d;
  if (v is double) return v;
  if (v is int) return v.toDouble();
  if (v is String) return double.tryParse(v) ?? d;
  return d;
}

bool _parseBool(dynamic v, [bool d = false]) {
  if (v == null) return d;
  if (v is bool) return v;
  if (v is int) return v != 0;
  if (v is String) return v == 'true' || v == '1';
  return d;
}

class StreamBreakdown {
  final double clearedTsh;
  final double pendingTsh;
  final int eventCount;

  const StreamBreakdown({
    required this.clearedTsh,
    required this.pendingTsh,
    required this.eventCount,
  });

  factory StreamBreakdown.fromJson(Map<String, dynamic> j) => StreamBreakdown(
        clearedTsh: _parseDouble(j['cleared_tsh']),
        pendingTsh: _parseDouble(j['pending_tsh']),
        eventCount: _parseInt(j['event_count']),
      );
}

class FundPeriodSummary {
  final String periodStart;
  final String periodEnd;
  final String phase;
  final double fundSizeTsh;
  final double? fundPerPoint;
  final double yourPoints;

  const FundPeriodSummary({
    required this.periodStart,
    required this.periodEnd,
    required this.phase,
    required this.fundSizeTsh,
    this.fundPerPoint,
    required this.yourPoints,
  });

  factory FundPeriodSummary.fromJson(Map<String, dynamic> j) => FundPeriodSummary(
        periodStart: j['period_start'] as String? ?? '',
        periodEnd: j['period_end'] as String? ?? '',
        phase: j['phase'] as String? ?? 'phase_1',
        fundSizeTsh: _parseDouble(j['fund_size_tsh']),
        fundPerPoint:
            j['fund_per_point'] != null ? _parseDouble(j['fund_per_point']) : null,
        yourPoints: _parseDouble(j['your_points']),
      );
}

class CreatorEarningsDashboard {
  final int userId;
  final double totalClearedTsh;
  final double totalPendingTsh;
  final double? estimatedThisPeriodTsh;
  final String currency;
  final String tier;
  final bool isMwanzoActive;
  final String? mwanzoExpiresAt;
  final bool monetizationPaused;
  final Map<String, StreamBreakdown> breakdownByStream;
  final FundPeriodSummary? currentPeriod;

  const CreatorEarningsDashboard({
    required this.userId,
    required this.totalClearedTsh,
    required this.totalPendingTsh,
    this.estimatedThisPeriodTsh,
    required this.currency,
    required this.tier,
    required this.isMwanzoActive,
    this.mwanzoExpiresAt,
    required this.monetizationPaused,
    required this.breakdownByStream,
    this.currentPeriod,
  });

  factory CreatorEarningsDashboard.fromJson(Map<String, dynamic> j) {
    final rawBreakdown = j['breakdown_by_stream'] as Map<String, dynamic>? ?? {};
    final breakdown = rawBreakdown.map(
      (k, v) => MapEntry(k, StreamBreakdown.fromJson(v as Map<String, dynamic>)),
    );
    return CreatorEarningsDashboard(
      userId: _parseInt(j['user_id']),
      totalClearedTsh: _parseDouble(j['total_cleared_tsh']),
      totalPendingTsh: _parseDouble(j['total_pending_tsh']),
      estimatedThisPeriodTsh: j['estimated_this_period_tsh'] != null
          ? _parseDouble(j['estimated_this_period_tsh'])
          : null,
      currency: j['currency'] as String? ?? 'TSh',
      tier: j['tier'] as String? ?? 'mwanzo',
      isMwanzoActive: _parseBool(j['is_mwanzo_active']),
      mwanzoExpiresAt: j['mwanzo_expires_at'] as String?,
      monetizationPaused: _parseBool(j['monetization_paused']),
      breakdownByStream: breakdown,
      currentPeriod: j['current_period'] != null
          ? FundPeriodSummary.fromJson(j['current_period'] as Map<String, dynamic>)
          : null,
    );
  }
}

class EarningEventItem {
  final int eventId;
  final String occurredAt;
  final int? postId;
  final String stream;
  final String metric;
  final String actorRole;
  final int rawCount;
  final double rateTsh;
  final Map<String, dynamic> multipliers;
  final double grossCredit;
  final double platformTake;
  final double traWhtHeld;
  final double netToCreator;
  final bool isChargeable;
  final String? chargeReason;
  final String settlementStatus;
  final String? clearedAt;
  final String? disbursedAt;
  final String? fundingSource;

  const EarningEventItem({
    required this.eventId,
    required this.occurredAt,
    this.postId,
    required this.stream,
    required this.metric,
    required this.actorRole,
    required this.rawCount,
    required this.rateTsh,
    required this.multipliers,
    required this.grossCredit,
    required this.platformTake,
    required this.traWhtHeld,
    required this.netToCreator,
    required this.isChargeable,
    this.chargeReason,
    required this.settlementStatus,
    this.clearedAt,
    this.disbursedAt,
    this.fundingSource,
  });

  factory EarningEventItem.fromJson(Map<String, dynamic> j) => EarningEventItem(
        eventId: _parseInt(j['event_id']),
        occurredAt: j['occurred_at'] as String? ?? '',
        postId: j['post_id'] != null ? _parseInt(j['post_id']) : null,
        stream: j['stream'] as String? ?? 'engagement',
        metric: j['metric'] as String? ?? '',
        actorRole: j['actor_role'] as String? ?? 'author',
        rawCount: _parseInt(j['raw_count']),
        rateTsh: _parseDouble(j['rate_tsh']),
        multipliers: (j['multipliers'] as Map<String, dynamic>?) ?? {},
        grossCredit: _parseDouble(j['gross_credit']),
        platformTake: _parseDouble(j['platform_take']),
        traWhtHeld: _parseDouble(j['tra_wht_held']),
        netToCreator: _parseDouble(j['net_to_creator']),
        isChargeable: _parseBool(j['is_chargeable'], true),
        chargeReason: j['charge_reason'] as String?,
        settlementStatus: j['settlement_status'] as String? ?? 'pending',
        clearedAt: j['cleared_at'] as String?,
        disbursedAt: j['disbursed_at'] as String?,
        fundingSource: j['funding_source'] as String?,
      );

  /// Human-readable multiplier summary, e.g. "2.0× watch × 1.1× streak"
  String multiplierSummary() {
    final parts = <String>[];
    final wc = multipliers['watch_completion'];
    if (wc != null && wc != 1.0) parts.add('$wc× watch');
    final mb = multipliers['mwanzo_boost'];
    if (mb != null && mb != 1.0) parts.add('$mb× Mwanzo');
    final sk = multipliers['streak'];
    if (sk != null && sk != 1.0) parts.add('$sk× streak');
    final dm = multipliers['discovery_mode'];
    if (dm != null && dm != 1.0) parts.add('$dm× discovery');
    return parts.isEmpty ? 'no multipliers' : parts.join(' × ');
  }
}

class PostEarningsV2 {
  final int postId;
  final double totalClearedTsh;
  final double totalPendingTsh;
  final double? estimatedPoolTsh;
  final double? fundPerPoint;
  final String currency;
  final String settlementNote;
  final Map<String, PostMetricBreakdown> breakdown;

  const PostEarningsV2({
    required this.postId,
    required this.totalClearedTsh,
    required this.totalPendingTsh,
    this.estimatedPoolTsh,
    this.fundPerPoint,
    required this.currency,
    required this.settlementNote,
    required this.breakdown,
  });

  double get totalTsh => totalClearedTsh + totalPendingTsh;

  factory PostEarningsV2.fromJson(Map<String, dynamic> j) {
    final rawBreakdown = j['breakdown'] as Map<String, dynamic>? ?? {};
    final breakdown = rawBreakdown.map(
      (k, v) => MapEntry(k, PostMetricBreakdown.fromJson(v as Map<String, dynamic>)),
    );
    return PostEarningsV2(
      postId: _parseInt(j['post_id']),
      totalClearedTsh: _parseDouble(j['total_cleared_tsh']),
      totalPendingTsh: _parseDouble(j['total_pending_tsh']),
      estimatedPoolTsh: j['estimated_pool_tsh'] != null
          ? _parseDouble(j['estimated_pool_tsh'])
          : null,
      fundPerPoint:
          j['fund_per_point'] != null ? _parseDouble(j['fund_per_point']) : null,
      currency: j['currency'] as String? ?? 'TSh',
      settlementNote: j['settlement_note'] as String? ?? '',
      breakdown: breakdown,
    );
  }
}

/// One post in the "my posts earnings" list — surfaces per-post
/// totals + a compact per-metric breakdown.
class PostEarningsListRow {
  final int postId;
  final String postType;
  final String? content;
  final String? thumbnailUrl;
  final String? createdAt;
  final double totalNetTsh;
  final int eventCount;
  final List<PostMetricSlice> metrics;

  const PostEarningsListRow({
    required this.postId,
    required this.postType,
    required this.content,
    required this.thumbnailUrl,
    required this.createdAt,
    required this.totalNetTsh,
    required this.eventCount,
    required this.metrics,
  });

  factory PostEarningsListRow.fromJson(Map<String, dynamic> j) {
    final raw = (j['metrics'] as List<dynamic>?) ?? const [];
    return PostEarningsListRow(
      postId: _parseInt(j['post_id']),
      postType: j['post_type'] as String? ?? 'text',
      content: j['content'] as String?,
      thumbnailUrl: j['thumbnail_url'] as String?,
      createdAt: j['created_at'] as String?,
      totalNetTsh: _parseDouble(j['total_net_tsh']),
      eventCount: _parseInt(j['event_count']),
      metrics: raw
          .map((e) => PostMetricSlice.fromJson(e as Map<String, dynamic>))
          .toList(),
    );
  }
}

class PostMetricSlice {
  final String metric;
  final int rawCountTotal;
  final int eventCount;
  final double netTsh;

  const PostMetricSlice({
    required this.metric,
    required this.rawCountTotal,
    required this.eventCount,
    required this.netTsh,
  });

  factory PostMetricSlice.fromJson(Map<String, dynamic> j) => PostMetricSlice(
        metric: j['metric'] as String? ?? '',
        rawCountTotal: _parseInt(j['raw_count_total']),
        eventCount: _parseInt(j['event_count']),
        netTsh: _parseDouble(j['net_tsh']),
      );
}

class PostEarningsListResponse {
  final List<PostEarningsListRow> items;
  final String period;
  final String periodStart;
  final String periodEnd;
  final int page;
  final int lastPage;
  final int total;
  final String currency;

  const PostEarningsListResponse({
    required this.items,
    required this.period,
    required this.periodStart,
    required this.periodEnd,
    required this.page,
    required this.lastPage,
    required this.total,
    required this.currency,
  });

  factory PostEarningsListResponse.fromJson(Map<String, dynamic> body) {
    final data = (body['data'] as List<dynamic>?) ?? const [];
    final meta = (body['meta'] as Map<String, dynamic>?) ?? const {};
    return PostEarningsListResponse(
      items: data
          .map((e) => PostEarningsListRow.fromJson(e as Map<String, dynamic>))
          .toList(),
      period: meta['period'] as String? ?? 'month',
      periodStart: meta['period_start'] as String? ?? '',
      periodEnd: meta['period_end'] as String? ?? '',
      page: _parseInt(meta['page']),
      lastPage: _parseInt(meta['last_page']),
      total: _parseInt(meta['total']),
      currency: meta['currency'] as String? ?? 'TSh',
    );
  }
}

/// One row of the per-event-type breakdown table — strategy §2.1 +
/// §2.2 attribution. Powers the Posts category page (and any other
/// category that surfaces the B+C breakdown).
class MetricBreakdownRow {
  final String metric;       // 'view' | 'reaction' | 'comment' | 'reply' | 'share' | 'save' | 'watch_second' | 'comment_reaction' | 'follow_from_post' | 'subscribe_from_post' | 'derivative_royalty' | 'period_settlement'
  final String actorRole;    // 'author' | 'comment_author' | 'host' | 'sharer' | 'original_creator_royalty' | …
  final String stream;       // 'engagement' | 'fan_funding' | …
  final int eventCount;
  final int rawCountTotal;
  final double grossTsh;
  final double platformTakeTsh;
  final double whtTsh;
  final double netTsh;

  const MetricBreakdownRow({
    required this.metric,
    required this.actorRole,
    required this.stream,
    required this.eventCount,
    required this.rawCountTotal,
    required this.grossTsh,
    required this.platformTakeTsh,
    required this.whtTsh,
    required this.netTsh,
  });

  factory MetricBreakdownRow.fromJson(Map<String, dynamic> j) =>
      MetricBreakdownRow(
        metric: j['metric'] as String? ?? '',
        actorRole: j['actor_role'] as String? ?? 'author',
        stream: j['stream'] as String? ?? 'engagement',
        eventCount: _parseInt(j['event_count']),
        rawCountTotal: _parseInt(j['raw_count_total']),
        grossTsh: _parseDouble(j['gross_tsh']),
        platformTakeTsh: _parseDouble(j['platform_take_tsh']),
        whtTsh: _parseDouble(j['wht_tsh']),
        netTsh: _parseDouble(j['net_tsh']),
      );
}

class MetricBreakdownResponse {
  final String period;
  final String periodStart;
  final String periodEnd;
  final String currency;
  final double totalGrossTsh;
  final double totalNetTsh;
  final int totalEventCount;
  final List<MetricBreakdownRow> rows;

  const MetricBreakdownResponse({
    required this.period,
    required this.periodStart,
    required this.periodEnd,
    required this.currency,
    required this.totalGrossTsh,
    required this.totalNetTsh,
    required this.totalEventCount,
    required this.rows,
  });

  factory MetricBreakdownResponse.fromJson(Map<String, dynamic> j) {
    final totals = (j['totals'] as Map<String, dynamic>?) ?? const {};
    final rawRows = (j['rows'] as List<dynamic>?) ?? const [];
    return MetricBreakdownResponse(
      period: j['period'] as String? ?? 'month',
      periodStart: j['period_start'] as String? ?? '',
      periodEnd: j['period_end'] as String? ?? '',
      currency: j['currency'] as String? ?? 'TSh',
      totalGrossTsh: _parseDouble(totals['gross_tsh']),
      totalNetTsh: _parseDouble(totals['net_tsh']),
      totalEventCount: _parseInt(totals['event_count']),
      rows: rawRows
          .map((e) => MetricBreakdownRow.fromJson(e as Map<String, dynamic>))
          .toList(),
    );
  }
}

class PostMetricBreakdown {
  final int count;
  final double clearedTsh;
  final double pendingTsh;

  const PostMetricBreakdown({
    required this.count,
    required this.clearedTsh,
    required this.pendingTsh,
  });

  double get totalTsh => clearedTsh + pendingTsh;

  factory PostMetricBreakdown.fromJson(Map<String, dynamic> j) =>
      PostMetricBreakdown(
        count: _parseInt(j['count']),
        clearedTsh: _parseDouble(j['cleared_tsh']),
        pendingTsh: _parseDouble(j['pending_tsh']),
      );
}

// ───────────────────────────────────────────────────────────────────────
// Strategy alignment — docs/creators/strategy.md
// ───────────────────────────────────────────────────────────────────────

/// The three earning layers from strategy §1: A) Direct engagement,
/// B) Context-chain (threads/comments/host), C) Derivative content
/// royalty. Distribution (sharer credit) is a sub-class of A under
/// the strategy doc but kept separate here to surface attribution
/// transparency to creators.
enum PayoutLayer { direct, context, derivative, distribution }

extension PayoutLayerWire on PayoutLayer {
  /// Title — bilingual.
  String label(bool isSw) => switch (this) {
        PayoutLayer.direct =>
          isSw ? 'Mapato ya moja kwa moja' : 'Direct engagement',
        PayoutLayer.context =>
          isSw ? 'Royalty ya muktadha' : 'Context royalty',
        PayoutLayer.derivative =>
          isSw ? 'Royalty ya derivative' : 'Derivative royalty',
        PayoutLayer.distribution =>
          isSw ? 'Salio la usambazaji' : 'Distribution credit',
      };

  /// One-line description — what this layer rewards. Strategy §1.
  String description(bool isSw) => switch (this) {
        PayoutLayer.direct => isSw
            ? 'Mtumiaji aliangalia / kuitikia / kushiriki post yako moja kwa moja.'
            : 'A user viewed, reacted to, or engaged with your post directly.',
        PayoutLayer.context => isSw
            ? 'Maoni au jibu lako ndani ya thread ya mtu mwingine lilipokea mwingiliano.'
            : 'Your comment or reply inside another creator\'s thread received engagement.',
        PayoutLayer.derivative => isSw
            ? 'Mtu alijenga kazi mpya (quote / stitch / remix) juu ya post yako.'
            : 'Someone built a new work (quote / stitch / remix) on top of your post.',
        PayoutLayer.distribution => isSw
            ? 'Ulishiriki post na mwingiliano halisi ulitokana na kushiriki kwako.'
            : 'You shared a post and real engagement came from your distribution.',
      };

  /// Bounded-propagation share per strategy §4. The numbers are the
  /// recommended split — e.g., a derivative post earning 100 routes
  /// 85 to the direct creator and 15 to the original.
  String shareLabel(bool isSw) => switch (this) {
        PayoutLayer.direct => '100%',
        PayoutLayer.context => '10–20%',
        PayoutLayer.derivative => '10–20%',
        PayoutLayer.distribution => '5–15%',
      };
}

/// Strategy §2 distinguishes "engagement payout" (user interacted)
/// from "royalty payout" (another creator's derivative work
/// generated value). They settle differently and have different
/// claw-back rules.
enum PayoutKind { engagement, royalty, distribution }

extension PayoutKindWire on PayoutKind {
  String label(bool isSw) => switch (this) {
        PayoutKind.engagement =>
          isSw ? 'Mwingiliano' : 'Engagement payout',
        PayoutKind.royalty => isSw ? 'Royalty' : 'Royalty payout',
        PayoutKind.distribution =>
          isSw ? 'Usambazaji' : 'Distribution payout',
      };
}

/// Strategy-aligned classification for an actor role.
PayoutLayer payoutLayerFor(String actorRole, String metric) {
  switch (actorRole) {
    case 'author':
      return PayoutLayer.direct;
    case 'comment_author':
    case 'reply_author':
    case 'parent_thread':
    case 'host':
      return PayoutLayer.context;
    case 'sharer':
      return PayoutLayer.distribution;
    case 'original_creator_royalty':
      return PayoutLayer.derivative;
  }
  // metric-driven fallback
  if (metric == 'derivative_royalty') return PayoutLayer.derivative;
  return PayoutLayer.direct;
}

PayoutKind payoutKindFor(String actorRole, String metric) {
  if (metric == 'derivative_royalty' ||
      actorRole == 'original_creator_royalty') {
    return PayoutKind.royalty;
  }
  if (actorRole == 'sharer') return PayoutKind.distribution;
  return PayoutKind.engagement;
}

/// Strategy §11 — platform-grade naming for actor roles. Replaces
/// "secondary earners", raw "host"/"sharer" in user-facing copy.
/// Extended for the strategy doc at docs/creators/posts/strategies/posts.md.
String actorRoleLabel(String actorRole, bool isSw) {
  switch (actorRole) {
    // Direct creation
    case 'author':
      return isSw ? 'Mwandishi (moja kwa moja)' : 'Direct creator';
    // Conversation
    case 'comment_author':
      return isSw ? 'Mwandishi wa maoni' : 'Comment author';
    case 'reply_author':
      return isSw ? 'Mwandishi wa jibu' : 'Reply author';
    case 'parent_thread':
      return isSw
          ? 'Mnufaika wa attribution (thread mzazi)'
          : 'Attribution beneficiary (parent thread)';
    case 'host':
      return isSw ? 'Mwenye post (host)' : 'Post host';
    // Distribution
    case 'sharer':
      return isSw ? 'Aliyeshiriki' : 'Sharer';
    // Derivative + cascade
    case 'original_author':
    case 'original_creator_royalty':
      return isSw ? 'Mwandishi wa awali' : 'Original author';
    case 'parent_creator_royalty':
      return isSw ? 'Mwandishi wa mzazi' : 'Parent creator';
    case 'root_creator_royalty':
      return isSw ? 'Mwandishi wa asili' : 'Root creator';
    // Clipper / Editor
    case 'clipper':
      return isSw ? 'Mtengenezaji wa clip' : 'Clipper';
    case 'editor':
      return isSw ? 'Mhariri' : 'Editor';
    // Localization
    case 'translator':
      return isSw ? 'Mtafsiri' : 'Translator';
    case 'voice_actor':
      return isSw ? 'Msemaji' : 'Voice actor';
    // Curation
    case 'curator':
      return isSw ? 'Mkusanyaji' : 'Curator';
    // Collaboration
    case 'contributor':
      return isSw ? 'Mchangiaji' : 'Contributor';
    // AI / synthetic
    case 'remixer':
      return isSw ? 'Mtengenezaji wa remix' : 'Remixer';
    // Community
    case 'mentor':
      return isSw ? 'Mwalimu' : 'Mentor';
    case 'connector':
      return isSw ? 'Mhusianaji' : 'Connector';
    case 'moderator':
      return isSw ? 'Msimamizi' : 'Moderator';
    default:
      return actorRole;
  }
}

/// Earnings split by `posts.relationship_type` — strategy §1C.
/// Powers the "BY DERIVATIVE KIND" section on Photo / Video etc.
/// earnings pages and the report's §5 derivative royalties row.
class DerivativeKindRow {
  final String kind; // 'original' | 'quote' | 'stitch' | 'reply_post' | 'remix' | 'duet' | 'shared'
  final int postCount;
  final int eventCount;
  final double grossTsh;
  final double netTsh;

  const DerivativeKindRow({
    required this.kind,
    required this.postCount,
    required this.eventCount,
    required this.grossTsh,
    required this.netTsh,
  });

  factory DerivativeKindRow.fromJson(Map<String, dynamic> j) =>
      DerivativeKindRow(
        kind: j['kind'] as String? ?? 'original',
        postCount: _parseInt(j['post_count']),
        eventCount: _parseInt(j['event_count']),
        grossTsh: _parseDouble(j['gross_tsh']),
        netTsh: _parseDouble(j['net_tsh']),
      );
}

class DerivativeKindResponse {
  final String period;
  final String periodStart;
  final String periodEnd;
  final String? postType;
  final String currency;
  final double totalGrossTsh;
  final double totalNetTsh;
  final int totalEventCount;
  final List<DerivativeKindRow> rows;

  const DerivativeKindResponse({
    required this.period,
    required this.periodStart,
    required this.periodEnd,
    required this.postType,
    required this.currency,
    required this.totalGrossTsh,
    required this.totalNetTsh,
    required this.totalEventCount,
    required this.rows,
  });

  factory DerivativeKindResponse.fromJson(Map<String, dynamic> j) {
    final totals = (j['totals'] as Map<String, dynamic>?) ?? const {};
    final raw = (j['rows'] as List<dynamic>?) ?? const [];
    return DerivativeKindResponse(
      period: j['period'] as String? ?? 'month',
      periodStart: j['period_start'] as String? ?? '',
      periodEnd: j['period_end'] as String? ?? '',
      postType: j['post_type'] as String?,
      currency: j['currency'] as String? ?? 'TSh',
      totalGrossTsh: _parseDouble(totals['gross_tsh']),
      totalNetTsh: _parseDouble(totals['net_tsh']),
      totalEventCount: _parseInt(totals['event_count']),
      rows: raw
          .map((e) => DerivativeKindRow.fromJson(e as Map<String, dynamic>))
          .toList(),
    );
  }
}

/// Top creator who built derivatives on this user's content. Powers
/// revenue report §6.
class DownstreamCreator {
  final int creatorId;
  final String? firstName;
  final String? lastName;
  final String? username;
  final String? profilePhotoPath;
  final int derivativePostCount;
  final int eventCount;
  final double yourRoyaltyTsh;

  const DownstreamCreator({
    required this.creatorId,
    required this.firstName,
    required this.lastName,
    required this.username,
    required this.profilePhotoPath,
    required this.derivativePostCount,
    required this.eventCount,
    required this.yourRoyaltyTsh,
  });

  factory DownstreamCreator.fromJson(Map<String, dynamic> j) =>
      DownstreamCreator(
        creatorId: _parseInt(j['creator_id']),
        firstName: j['first_name'] as String?,
        lastName: j['last_name'] as String?,
        username: j['username'] as String?,
        profilePhotoPath: j['profile_photo_path'] as String?,
        derivativePostCount: _parseInt(j['derivative_post_count']),
        eventCount: _parseInt(j['event_count']),
        yourRoyaltyTsh: _parseDouble(j['your_royalty_tsh']),
      );

  String get displayName {
    final parts = [firstName, lastName]
        .whereType<String>()
        .where((s) => s.isNotEmpty);
    final n = parts.join(' ');
    if (n.isNotEmpty) return n;
    return username ?? 'creator_$creatorId';
  }
}

/// One row from `GET /api/users/me/earnings/by-multiplier` —
/// per-multiplier contribution analysis. Powers Photos.earnings
/// §XI.A bonuses and §XI.B clamping rows.
class MultiplierContributionRow {
  final String multiplier;
  final double contributionTsh;
  final int eventCount;
  final double avgValue;

  const MultiplierContributionRow({
    required this.multiplier,
    required this.contributionTsh,
    required this.eventCount,
    required this.avgValue,
  });

  factory MultiplierContributionRow.fromJson(Map<String, dynamic> j) =>
      MultiplierContributionRow(
        multiplier: j['multiplier'] as String? ?? '',
        contributionTsh: _parseDouble(j['contribution_tsh']),
        eventCount: _parseInt(j['event_count']),
        avgValue: _parseDouble(j['avg_value'], 1.0),
      );
}

class MultiplierContributionResponse {
  final String period;
  final String periodStart;
  final String periodEnd;
  final String? postType;
  final String currency;
  final List<MultiplierContributionRow> rows;

  const MultiplierContributionResponse({
    required this.period,
    required this.periodStart,
    required this.periodEnd,
    required this.postType,
    required this.currency,
    required this.rows,
  });

  factory MultiplierContributionResponse.fromJson(Map<String, dynamic> j) {
    final raw = (j['rows'] as List<dynamic>?) ?? const [];
    return MultiplierContributionResponse(
      period: j['period'] as String? ?? 'month',
      periodStart: j['period_start'] as String? ?? '',
      periodEnd: j['period_end'] as String? ?? '',
      postType: j['post_type'] as String?,
      currency: j['currency'] as String? ?? 'TSh',
      rows: raw
          .map((e) => MultiplierContributionRow.fromJson(
              e as Map<String, dynamic>))
          .toList(),
    );
  }
}

/// Bilingual label for each canonical relationship_type — strategy
/// doc §IV (13 types).
String relationshipTypeLabel(String kind, bool isSw) {
  return switch (kind) {
    'original' => isSw ? 'Asili' : 'Original',
    'quote' => isSw ? 'Quote' : 'Quote post',
    'stitch' => isSw ? 'Stitch' : 'Stitch',
    'reply_post' => isSw ? 'Jibu (post)' : 'Reply post',
    'remix' => isSw ? 'Remix' : 'Remix',
    'duet' => isSw ? 'Duet' : 'Duet',
    'clip' => isSw ? 'Clip' : 'Clip',
    'template_derivative' =>
      isSw ? 'Derivative ya template' : 'Template derivative',
    'meme_lineage' =>
      isSw ? 'Mzunguko wa meme' : 'Meme lineage',
    'ai_generated_variant' =>
      isSw ? 'Toleo lililotengenezwa na AI' : 'AI-generated variant',
    'localized_remix' =>
      isSw ? 'Remix iliyotafsiriwa' : 'Localized remix',
    'translation' => isSw ? 'Tafsiri' : 'Translation',
    'dub' => isSw ? 'Sauti iliyobadilishwa' : 'Dub',
    'shared' => isSw ? 'Imeshirikiwa' : 'Shared',
    _ => kind,
  };
}

/// Bilingual label for each contributor role on a multi-author
/// post — strategy doc §VIII (8 roles).
String contributorRoleLabel(String role, bool isSw) {
  return switch (role) {
    'photographer' => isSw ? 'Mpiga picha' : 'Photographer',
    'editor' => isSw ? 'Mhariri' : 'Editor',
    'colorist' => isSw ? 'Mtaalamu wa rangi' : 'Colorist',
    'thumbnail_designer' =>
      isSw ? 'Mbunifu wa thumbnail' : 'Thumbnail designer',
    'caption_writer' =>
      isSw ? 'Mwandishi wa maelezo' : 'Caption writer',
    'narrator' => isSw ? 'Msimulizi' : 'Narrator',
    'composer' => isSw ? 'Mtunzi wa muziki' : 'Composer',
    'creative_director' =>
      isSw ? 'Mkurugenzi wa ubunifu' : 'Creative director',
    _ => role,
  };
}

/// Bilingual label for a canonical engagement metric — single
/// source of truth used across rate cards, breakdown tables and
/// the per-event ledger. Covers the full strategy doc taxonomy at
/// docs/creators/posts/strategies/posts.md.
String metricLabel(String metric, bool isSw) {
  return switch (metric) {
    // §I Direct creation
    'view' => isSw ? 'Mwoneko' : 'View',
    'watch_second' => isSw ? 'Sekunde za kutazama' : 'Watch-second',
    'reaction' => isSw ? 'Reaction' : 'Reaction',
    'comment' => isSw ? 'Maoni' : 'Comment',
    'reply' => isSw ? 'Jibu' : 'Reply',
    'save' => isSw ? 'Hifadhi' : 'Save',
    'share' => isSw ? 'Kushiriki' : 'Share',
    'follow_from_post' =>
      isSw ? 'Followa kutoka post' : 'Follow from post',
    'subscribe_from_post' =>
      isSw ? 'Subscribe kutoka post' : 'Subscribe from post',
    'profile_visit_from_post' =>
      isSw ? 'Ziara ya profile kutoka post' : 'Profile visit from post',
    'return_session_credit' =>
      isSw ? 'Salio la kurudi tena' : 'Return-session credit',
    'retention_day_n' =>
      isSw ? 'Kubaki siku N' : 'Retention day N',
    'external_link_click' =>
      isSw ? 'Bofya link ya nje' : 'External link click',
    'purchase_assist' =>
      isSw ? 'Msaada wa ununuzi' : 'Purchase assist',
    'screenshot' => isSw ? 'Screenshot' : 'Screenshot',
    'revisit_post' =>
      isSw ? 'Kurudi kwenye post' : 'Revisit post',
    'copy_text' => isSw ? 'Nakili maandishi' : 'Copy text',
    // §II Conversation & context
    'comment_reaction' =>
      isSw ? 'Reaction kwenye maoni' : 'Comment reaction',
    'reply_reaction' =>
      isSw ? 'Reaction kwenye jibu' : 'Reply reaction',
    'thread_depth_bonus' =>
      isSw ? 'Bonasi ya kina cha mazungumzo' : 'Thread depth bonus',
    'unique_participant_bonus' =>
      isSw ? 'Bonasi ya washiriki tofauti' : 'Unique participant bonus',
    'creator_reply_bonus' =>
      isSw ? 'Bonasi ya mwandishi kuhusika' : 'Creator reply bonus',
    // §III Distribution
    'follow_from_share' =>
      isSw ? 'Followa kutoka share' : 'Follow from share',
    'subscribe_from_share' =>
      isSw ? 'Subscribe kutoka share' : 'Subscribe from share',
    'profile_visit_from_share' =>
      isSw ? 'Ziara ya profile kutoka share' : 'Profile visit from share',
    'distribution_retention_credit' =>
      isSw ? 'Salio la kurudi (usambazaji)' : 'Distribution retention credit',
    'high_quality_share_bonus' =>
      isSw ? 'Bonasi ya share ya ubora' : 'High-quality share bonus',
    // §IV Derivative
    'derivative_royalty' =>
      isSw ? 'Royalty ya derivative' : 'Derivative royalty',
    // §V Clipper / editor
    'clip_create' => isSw ? 'Tengeneza clip' : 'Clip create',
    'clip_view' => isSw ? 'Mwoneko wa clip' : 'Clip view',
    'clip_conversion' =>
      isSw ? 'Mageuzi ya clip' : 'Clip conversion',
    'subtitle_addition' =>
      isSw ? 'Ongeza subtitle' : 'Subtitle addition',
    'format_adaptation' =>
      isSw ? 'Kubadilisha format' : 'Format adaptation',
    'highlight_selection' =>
      isSw ? 'Chagua sehemu nzuri' : 'Highlight selection',
    // §VI Localization
    'translation_create' =>
      isSw ? 'Tengeneza tafsiri' : 'Translation create',
    'translated_view' =>
      isSw ? 'Mwoneko wa tafsiri' : 'Translated view',
    'translated_conversion' =>
      isSw ? 'Mageuzi ya tafsiri' : 'Translated conversion',
    'dub_create' => isSw ? 'Tengeneza dub' : 'Dub create',
    'subtitle_localization' =>
      isSw ? 'Subtitle ya lugha' : 'Subtitle localization',
    // §VII Curation
    'collection_add' =>
      isSw ? 'Ongeza kwenye mkusanyiko' : 'Collection add',
    'collection_view' =>
      isSw ? 'Mwoneko wa mkusanyiko' : 'Collection view',
    'collection_follow' =>
      isSw ? 'Followa mkusanyiko' : 'Collection follow',
    'collection_conversion' =>
      isSw ? 'Mageuzi ya mkusanyiko' : 'Collection conversion',
    'thematic_feed_bonus' =>
      isSw ? 'Bonasi ya feed ya mada' : 'Thematic feed bonus',
    // §VIII Collaboration
    'collaborator_split' =>
      isSw ? 'Mgawanyo wa washirika' : 'Collaborator split',
    // §IX Educational
    'reference_revisit' =>
      isSw ? 'Kurudi kwa marejeo' : 'Reference revisit',
    'instructional_completion' =>
      isSw ? 'Kumaliza maelekezo' : 'Instructional completion',
    'save_to_learning_collection' =>
      isSw ? 'Hifadhi kwenye mkusanyiko wa kujifunza' : 'Save to learning collection',
    'external_reference_click' =>
      isSw ? 'Bofya marejeo ya nje' : 'External reference click',
    // §X Commerce
    'product_expand' =>
      isSw ? 'Fungua bidhaa' : 'Product expand',
    'wishlist_add' =>
      isSw ? 'Ongeza kwenye wishlist' : 'Wishlist add',
    'affiliate_conversion' =>
      isSw ? 'Mageuzi ya affiliate' : 'Affiliate conversion',
    'local_business_conversion' =>
      isSw ? 'Mageuzi ya biashara ya ndani' : 'Local business conversion',
    // §XI.A Engine-level positive multipliers (always emitted by the
    // earnings pipeline before integrity-framework bonuses apply).
    'mwanzo_boost' =>
      isSw ? 'Bonasi ya Mwanzo' : 'Mwanzo (launch) boost',
    'watch_completion' =>
      isSw ? 'Bonasi ya kumaliza' : 'Watch-completion bonus',
    'tier_boost' =>
      isSw ? 'Bonasi ya daraja' : 'Creator-tier boost',
    'streak' =>
      isSw ? 'Bonasi ya mfululizo' : 'Streak bonus',
    'discovery_mode' =>
      isSw ? 'Hali ya ugunduzi' : 'Discovery-mode boost',
    'originality' =>
      isSw ? 'Uhalisi (engine)' : 'Originality (engine signal)',
    'actor_trust_expert' =>
      isSw ? 'Bonasi ya uaminifu wa mtaalamu' : 'Expert-trust bonus',
    // §XI.A Platform health bonuses (positive multipliers from the
    // integrity framework — applied on top of engine-level bonuses).
    'originality_bonus' =>
      isSw ? 'Bonasi ya uhalisi' : 'Originality bonus',
    'evergreen_bonus' =>
      isSw ? 'Bonasi ya muda mrefu' : 'Evergreen bonus',
    'trust_score_bonus' =>
      isSw ? 'Bonasi ya alama ya uaminifu' : 'Trust score bonus',
    'healthy_discussion_bonus' =>
      isSw ? 'Bonasi ya mazungumzo bora' : 'Healthy discussion bonus',
    'cross_ideology_bonus' =>
      isSw ? 'Bonasi ya tofauti za fikra' : 'Cross-ideology bonus',
    'expert_participation_bonus' =>
      isSw ? 'Bonasi ya mtaalamu' : 'Expert participation bonus',
    'fact_checked_bonus' =>
      isSw ? 'Bonasi ya kuhakikiwa' : 'Fact-checked bonus',
    'community_health_bonus' =>
      isSw ? 'Bonasi ya afya ya jamii' : 'Community health bonus',
    // §XI.B Engagement-quality penalties (viewer-driven)
    'rapid_hide_penalty' =>
      isSw ? 'Adhabu ya kuficha haraka' : 'Rapid-hide penalty',
    'report_penalty' =>
      isSw ? 'Adhabu ya ripoti' : 'Report penalty',
    'bounce_penalty' =>
      isSw ? 'Adhabu ya kuondoka haraka' : 'Bounce penalty',
    'mute_after_view_penalty' =>
      isSw ? 'Adhabu ya kunyamazisha' : 'Mute-after-view penalty',
    'spam_ring_detection_penalty' =>
      isSw ? 'Adhabu ya spam-ring' : 'Spam-ring detection penalty',
    // §XI.C Trust / fraud / safety / AI penalties (classifier-driven
    // and integrity-pipeline clamps).
    'actor_trust_age' =>
      isSw ? 'Punguzo la umri wa akaunti' : 'Account-age clamp',
    'actor_authenticity' =>
      isSw ? 'Punguzo la uhalisi wa mtumiaji' : 'Actor authenticity clamp',
    'actor_network_reputation' =>
      isSw ? 'Punguzo la sifa ya mtandao' : 'Network-reputation clamp',
    'fraud_risk' =>
      isSw ? 'Punguzo la hatari ya udanganyifu' : 'Fraud-risk clamp',
    'human_probability' =>
      isSw ? 'Punguzo la uwezekano wa binadamu' : 'Human-probability clamp',
    'device_cluster' =>
      isSw ? 'Punguzo la kifaa kilichojaa' : 'Device-cluster clamp',
    'diminishing_returns' =>
      isSw ? 'Punguzo la kupungua kwa thamani' : 'Diminishing-returns clamp',
    'content_safety_mature' =>
      isSw ? 'Punguzo la maudhui makomavu' : 'Mature-content clamp',
    'content_safety_suggestive' =>
      isSw ? 'Punguzo la maudhui ya pendekezo' : 'Suggestive-content clamp',
    // Legacy/spec-doc names not yet emitted by backend filters — kept
    // for future-compat. Do not delete unless backend confirms removal.
    'spam_penalty' =>
      isSw ? 'Adhabu ya spam' : 'Spam penalty',
    'misinformation_penalty' =>
      isSw ? 'Adhabu ya taarifa potofu' : 'Misinformation penalty',
    'harassment_penalty' =>
      isSw ? 'Adhabu ya unyanyasaji' : 'Harassment penalty',
    'ragebait_penalty' =>
      isSw ? 'Adhabu ya ragebait' : 'Ragebait penalty',
    'adult_content_reduction' =>
      isSw ? 'Punguzo la maudhui ya watu wazima' : 'Adult-content reduction',
    'sexual_engagement_bait_penalty' =>
      isSw ? 'Adhabu ya udanganyifu wa kingono' : 'Sexual engagement bait penalty',
    'mature_content_distribution_limit' =>
      isSw ? 'Kikomo cha usambazaji wa maudhui makomavu' : 'Mature content distribution limit',
    'synthetic_spam_detection' =>
      isSw ? 'Ugunduzi wa spam ya kisynthetic' : 'Synthetic spam detection',
    'ai_content_flood_penalty' =>
      isSw ? 'Adhabu ya mafuriko ya AI' : 'AI content flood penalty',
    'coordinated_bot_ring_penalty' =>
      isSw ? 'Adhabu ya kikundi cha bot' : 'Coordinated bot-ring penalty',
    'mass_generation_penalty' =>
      isSw ? 'Adhabu ya uzalishaji mkubwa' : 'Mass-generation penalty',
    // §XII AI / synthetic
    'ai_style_usage' =>
      isSw ? 'Matumizi ya mtindo wa AI' : 'AI style usage',
    'synthetic_voice_usage' =>
      isSw ? 'Matumizi ya sauti ya kisynthetic' : 'Synthetic voice usage',
    'ai_training_contribution' =>
      isSw ? 'Mchango wa kufundisha AI' : 'AI training contribution',
    'ai_assisted_remix' =>
      isSw ? 'Remix iliyosaidiwa na AI' : 'AI-assisted remix',
    // §XIII Community
    'mentorship_attribution' =>
      isSw ? 'Attribution ya ualimu' : 'Mentorship attribution',
    'collaboration_origin_credit' =>
      isSw ? 'Salio la asili ya ushirikiano' : 'Collaboration origin credit',
    'moderation_quality_bonus' =>
      isSw ? 'Bonasi ya usimamizi bora' : 'Moderation quality bonus',
    'community_retention_bonus' =>
      isSw ? 'Bonasi ya kubaki kwa jamii' : 'Community retention bonus',
    // System
    'period_settlement' =>
      isSw ? 'Settlement ya kipindi' : 'Period settlement',
    _ => metric,
  };
}

extension EarningEventLayer on EarningEventItem {
  PayoutLayer get layer => payoutLayerFor(actorRole, metric);
  PayoutKind get kind => payoutKindFor(actorRole, metric);
  String roleLabel(bool isSw) => actorRoleLabel(actorRole, isSw);
}

extension MetricBreakdownRowLayer on MetricBreakdownRow {
  PayoutLayer get layer => payoutLayerFor(actorRole, metric);
  PayoutKind get kind => payoutKindFor(actorRole, metric);
  String roleLabel(bool isSw) => actorRoleLabel(actorRole, isSw);
}
