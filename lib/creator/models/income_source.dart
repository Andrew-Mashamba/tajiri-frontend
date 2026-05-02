// Income Sources data model.
// Spec: docs/superpowers/specs/2026-05-02-creator-income-sources-design.md
//
// All money amounts use the `_minor` suffix and store integer minor units
// (1 TSh = 100 minor). Use `formatTzsMinor()` for display.

import 'package:flutter/widgets.dart';
import '../../l10n/app_strings_scope.dart';

// ---------------------------------------------------------------------------
// Parse helpers (mirror lib/creator/models/flywheel_models.dart conventions)
// ---------------------------------------------------------------------------

int _parseInt(dynamic v, [int defaultValue = 0]) {
  if (v == null) return defaultValue;
  if (v is int) return v;
  if (v is double) return v.toInt();
  if (v is String) return int.tryParse(v) ?? defaultValue;
  return defaultValue;
}

double _parseDouble(dynamic v, [double defaultValue = 0.0]) {
  if (v == null) return defaultValue;
  if (v is double) return v;
  if (v is int) return v.toDouble();
  if (v is String) return double.tryParse(v) ?? defaultValue;
  return defaultValue;
}

bool _parseBool(dynamic v, [bool defaultValue = false]) {
  if (v == null) return defaultValue;
  if (v is bool) return v;
  if (v is int) return v != 0;
  if (v is String) return v.toLowerCase() == 'true' || v == '1';
  return defaultValue;
}

DateTime? _parseDate(dynamic v) {
  if (v == null) return null;
  return DateTime.tryParse(v.toString());
}

// ---------------------------------------------------------------------------
// Format helper
// ---------------------------------------------------------------------------

/// Renders a minor-unit TZS amount as e.g. `TSh 86,450`.
String formatTzsMinor(int minor) {
  final whole = (minor / 100).round();
  return 'TSh ${_thousandsSeparated(whole)}';
}

/// Renders a minor-unit TZS amount without the "TSh" prefix.
String formatTzsMinorBare(int minor) {
  final whole = (minor / 100).round();
  return _thousandsSeparated(whole);
}

String _thousandsSeparated(int n) {
  final s = n.abs().toString();
  final buf = StringBuffer();
  for (var i = 0; i < s.length; i++) {
    if (i > 0 && (s.length - i) % 3 == 0) buf.write(',');
    buf.write(s[i]);
  }
  return n < 0 ? '-${buf.toString()}' : buf.toString();
}

// ---------------------------------------------------------------------------
// Bilingual text
// ---------------------------------------------------------------------------

/// A backend-provided string with both Swahili (`sw`) and English (`en`) variants.
@immutable
class BilingualText {
  final String en;
  final String sw;
  const BilingualText({required this.en, required this.sw});

  /// Returns the variant matching the current language. English is the default
  /// when the bilingual scope is unavailable, per ENGINEERING_PLAYBOOK.md.
  String forContext(BuildContext context) {
    final isSw = AppStringsScope.of(context)?.isSwahili ?? false;
    return isSw ? sw : en;
  }

  factory BilingualText.fromJson(dynamic json, {String fallback = ''}) {
    if (json is Map) {
      final en = (json['en'] as String?) ?? fallback;
      final sw = (json['sw'] as String?) ?? en;
      return BilingualText(en: en, sw: sw);
    }
    if (json is String) return BilingualText(en: json, sw: json);
    return BilingualText(en: fallback, sw: fallback);
  }
}

// ---------------------------------------------------------------------------
// Enums
// ---------------------------------------------------------------------------

/// Period selectors shown as pills (Wiki / Mwezi / Robo / Yote).
enum IncomePeriod {
  week('week'),
  month('month'),
  quarter('quarter'),
  all('all');

  final String wire;
  const IncomePeriod(this.wire);

  static IncomePeriod fromWire(String? s) {
    return IncomePeriod.values.firstWhere(
      (p) => p.wire == s,
      orElse: () => IncomePeriod.month,
    );
  }
}

/// State machine for a single income source. Drives the visual treatment of
/// the row + hero + CTA. Backend-evaluated.
enum SourceState {
  earning,   // unlocked & received money this period
  live,      // earning right now (live stream)
  pending,   // finalized but not yet paid out (Creator Fund cycle)
  paused,    // creator manually disabled
  ready,     // eligibility met, not yet activated
  locked,    // eligibility unmet
  unknown;

  static SourceState fromWire(String? s) {
    switch (s) {
      case 'earning':
        return SourceState.earning;
      case 'live':
        return SourceState.live;
      case 'pending':
        return SourceState.pending;
      case 'paused':
        return SourceState.paused;
      case 'ready':
        return SourceState.ready;
      case 'locked':
        return SourceState.locked;
    }
    return SourceState.unknown;
  }

  bool get isActive => this == earning || this == live || this == pending;
  bool get isLocked => this == locked || this == ready;
}

// ---------------------------------------------------------------------------
// Sub-objects
// ---------------------------------------------------------------------------

@immutable
class CurrentPeriodEarnings {
  final IncomePeriod period;
  final DateTime? startsAt;
  final DateTime? endsAt;
  final int grossMinor;
  final int platformFeeMinor;
  final int processingFeeMinor;
  final int netMinor;
  final String currency;
  final int count;
  final BilingualText countLabel;
  final int averageMinor;
  final double deltaPctVsPrev;

  const CurrentPeriodEarnings({
    required this.period,
    required this.startsAt,
    required this.endsAt,
    required this.grossMinor,
    required this.platformFeeMinor,
    required this.processingFeeMinor,
    required this.netMinor,
    required this.currency,
    required this.count,
    required this.countLabel,
    required this.averageMinor,
    required this.deltaPctVsPrev,
  });

  factory CurrentPeriodEarnings.fromJson(Map<String, dynamic> json) {
    return CurrentPeriodEarnings(
      period: IncomePeriod.fromWire(json['period'] as String?),
      startsAt: _parseDate(json['starts_at']),
      endsAt: _parseDate(json['ends_at']),
      grossMinor: _parseInt(json['gross_minor']),
      platformFeeMinor: _parseInt(json['platform_fee_minor']),
      processingFeeMinor: _parseInt(json['processing_fee_minor']),
      netMinor: _parseInt(json['net_minor']),
      currency: (json['currency'] as String?) ?? 'TZS',
      count: _parseInt(json['count']),
      countLabel: BilingualText.fromJson(json['count_label'], fallback: ''),
      averageMinor: _parseInt(json['average_minor']),
      deltaPctVsPrev: _parseDouble(json['delta_pct_vs_prev']),
    );
  }
}

@immutable
class MathComponent {
  final String key;
  final BilingualText label;
  final int amountMinor;
  final bool isTotal;

  const MathComponent({
    required this.key,
    required this.label,
    required this.amountMinor,
    required this.isTotal,
  });

  factory MathComponent.fromJson(Map<String, dynamic> json) {
    return MathComponent(
      key: (json['key'] as String?) ?? '',
      label: BilingualText(
        en: (json['label_en'] as String?) ?? '',
        sw: (json['label_sw'] as String?) ?? (json['label_en'] as String?) ?? '',
      ),
      amountMinor: _parseInt(json['amount_minor']),
      isTotal: _parseBool(json['is_total']),
    );
  }
}

@immutable
class MathInfo {
  final String formula;
  final double platformRate;
  final BilingualText platformRateLabel;
  final List<MathComponent> components;
  final BilingualText ownStatement;

  const MathInfo({
    required this.formula,
    required this.platformRate,
    required this.platformRateLabel,
    required this.components,
    required this.ownStatement,
  });

  factory MathInfo.fromJson(Map<String, dynamic> json) {
    final raw = (json['components'] as List?) ?? const [];
    return MathInfo(
      formula: (json['formula'] as String?) ?? '',
      platformRate: _parseDouble(json['platform_rate']),
      platformRateLabel: BilingualText.fromJson(json['platform_rate_label']),
      components: raw
          .whereType<Map<String, dynamic>>()
          .map(MathComponent.fromJson)
          .toList(growable: false),
      ownStatement: BilingualText(
        en: (json['own_statement'] is Map ? json['own_statement']['en'] as String? : null) ?? '',
        sw: (json['own_statement'] is Map ? json['own_statement']['sw'] as String? : null) ??
            (json['own_statement'] is Map ? json['own_statement']['en'] as String? : null) ??
            '',
      ),
    );
  }
}

@immutable
class EligibilityRule {
  final String key;
  final BilingualText label;
  final bool done;
  final DateTime? completedAt;
  final num? currentValue;
  final num? targetValue;
  final double progressPct;
  final String? blockingReason;

  const EligibilityRule({
    required this.key,
    required this.label,
    required this.done,
    required this.completedAt,
    required this.currentValue,
    required this.targetValue,
    required this.progressPct,
    required this.blockingReason,
  });

  factory EligibilityRule.fromJson(Map<String, dynamic> json) {
    return EligibilityRule(
      key: (json['key'] as String?) ?? '',
      label: BilingualText(
        en: (json['label_en'] as String?) ?? '',
        sw: (json['label_sw'] as String?) ?? (json['label_en'] as String?) ?? '',
      ),
      done: _parseBool(json['done']),
      completedAt: _parseDate(json['completed_at']),
      currentValue: json['current_value'] is num ? json['current_value'] as num : null,
      targetValue: json['target_value'] is num ? json['target_value'] as num : null,
      progressPct: _parseDouble(json['progress_pct']),
      blockingReason: json['blocking_reason'] as String?,
    );
  }
}

@immutable
class Eligibility {
  final double completionPct;
  final String? primaryBlocker;
  final DateTime? estimatedUnlockAt;
  final List<EligibilityRule> rules;

  const Eligibility({
    required this.completionPct,
    required this.primaryBlocker,
    required this.estimatedUnlockAt,
    required this.rules,
  });

  factory Eligibility.fromJson(Map<String, dynamic> json) {
    final raw = (json['rules'] as List?) ?? const [];
    return Eligibility(
      completionPct: _parseDouble(json['completion_pct']),
      primaryBlocker: json['primary_blocker'] as String?,
      estimatedUnlockAt: _parseDate(json['estimated_unlock_at']),
      rules: raw
          .whereType<Map<String, dynamic>>()
          .map(EligibilityRule.fromJson)
          .toList(growable: false),
    );
  }

  /// First incomplete rule with a current/target value pair — used in the
  /// locked-state hero ("47 / 100").
  EligibilityRule? get blockingRule {
    if (primaryBlocker != null) {
      for (final r in rules) {
        if (r.key == primaryBlocker && !r.done) return r;
      }
    }
    for (final r in rules) {
      if (!r.done && r.targetValue != null) return r;
    }
    return null;
  }
}

@immutable
class Estimate {
  final int amountPerMonthMinor;
  final String currency;
  final BilingualText assumptions;

  const Estimate({
    required this.amountPerMonthMinor,
    required this.currency,
    required this.assumptions,
  });

  factory Estimate.fromJson(Map<String, dynamic> json) {
    return Estimate(
      amountPerMonthMinor: _parseInt(json['amount_per_month_minor']),
      currency: (json['currency'] as String?) ?? 'TZS',
      assumptions: BilingualText(
        en: (json['assumptions_en'] as String?) ?? '',
        sw: (json['assumptions_sw'] as String?) ?? (json['assumptions_en'] as String?) ?? '',
      ),
    );
  }
}

@immutable
class Accelerator {
  final String key;
  final String? icon;
  final BilingualText title;
  final BilingualText subtitle;
  final String? deeplink;

  const Accelerator({
    required this.key,
    required this.icon,
    required this.title,
    required this.subtitle,
    required this.deeplink,
  });

  factory Accelerator.fromJson(Map<String, dynamic> json) {
    return Accelerator(
      key: (json['key'] as String?) ?? '',
      icon: json['icon'] as String?,
      title: BilingualText(
        en: (json['title_en'] as String?) ?? '',
        sw: (json['title_sw'] as String?) ?? (json['title_en'] as String?) ?? '',
      ),
      subtitle: BilingualText(
        en: (json['subtitle_en'] as String?) ?? '',
        sw: (json['subtitle_sw'] as String?) ?? (json['subtitle_en'] as String?) ?? '',
      ),
      deeplink: json['deeplink'] as String?,
    );
  }
}

@immutable
class IncomeInsight {
  final String key;
  final BilingualText label;
  final BilingualText value;

  const IncomeInsight({
    required this.key,
    required this.label,
    required this.value,
  });

  factory IncomeInsight.fromJson(Map<String, dynamic> json) {
    return IncomeInsight(
      key: (json['key'] as String?) ?? '',
      label: BilingualText(
        en: (json['label_en'] as String?) ?? '',
        sw: (json['label_sw'] as String?) ?? (json['label_en'] as String?) ?? '',
      ),
      value: BilingualText(
        en: (json['value_en'] as String?) ?? '',
        sw: (json['value_sw'] as String?) ?? (json['value_en'] as String?) ?? '',
      ),
    );
  }
}

@immutable
class IncomeCta {
  final BilingualText label;
  final String action;

  const IncomeCta({required this.label, required this.action});

  factory IncomeCta.fromJson(Map<String, dynamic> json) {
    return IncomeCta(
      label: BilingualText(
        en: (json['label_en'] as String?) ?? '',
        sw: (json['label_sw'] as String?) ?? (json['label_en'] as String?) ?? '',
      ),
      action: (json['action'] as String?) ?? '',
    );
  }
}

@immutable
class HistoryItem {
  final String id;
  final DateTime occurredAt;
  final int? actorId;
  final String? actorUsername;
  final String? actorAvatarUrl;
  final int grossMinor;
  final int netMinor;
  final String currency;
  final String? message;
  final int? postId;
  final int? streamId;

  const HistoryItem({
    required this.id,
    required this.occurredAt,
    required this.actorId,
    required this.actorUsername,
    required this.actorAvatarUrl,
    required this.grossMinor,
    required this.netMinor,
    required this.currency,
    required this.message,
    required this.postId,
    required this.streamId,
  });

  factory HistoryItem.fromJson(Map<String, dynamic> json) {
    final actor = json['actor'] is Map ? json['actor'] as Map : const {};
    return HistoryItem(
      id: (json['id'] as String?) ?? '',
      occurredAt: _parseDate(json['occurred_at']) ?? DateTime.now(),
      actorId: actor['id'] is num ? (actor['id'] as num).toInt() : null,
      actorUsername: actor['username'] as String?,
      actorAvatarUrl: actor['avatar_url'] as String?,
      grossMinor: _parseInt(json['gross_minor']),
      netMinor: _parseInt(json['net_minor']),
      currency: (json['currency'] as String?) ?? 'TZS',
      message: json['message'] as String?,
      postId: json['post_id'] is num ? (json['post_id'] as num).toInt() : null,
      streamId: json['stream_id'] is num ? (json['stream_id'] as num).toInt() : null,
    );
  }
}

// ---------------------------------------------------------------------------
// IncomeSource — the central entity
// ---------------------------------------------------------------------------

@immutable
class IncomeSource {
  final String id;
  final BilingualText displayName;
  final String category;
  final String? icon;
  final SourceState state;
  final BilingualText stateLabel;
  final String phase;

  // Active variant (state == earning | live | pending | paused)
  final CurrentPeriodEarnings? currentPeriod;
  final MathInfo? math;
  final List<IncomeInsight> insights;
  final String? historyEndpoint;
  final List<HistoryItem> recentHistory;

  // Locked variant (state == locked | ready)
  final Eligibility? eligibility;
  final Estimate? estimate;
  final List<Accelerator> accelerators;

  // CTAs (always)
  final IncomeCta? primaryCta;
  final IncomeCta? secondaryCta;

  const IncomeSource({
    required this.id,
    required this.displayName,
    required this.category,
    required this.icon,
    required this.state,
    required this.stateLabel,
    required this.phase,
    required this.currentPeriod,
    required this.math,
    required this.insights,
    required this.historyEndpoint,
    required this.recentHistory,
    required this.eligibility,
    required this.estimate,
    required this.accelerators,
    required this.primaryCta,
    required this.secondaryCta,
  });

  factory IncomeSource.fromJson(Map<String, dynamic> json) {
    final insightsRaw = (json['insights'] as List?) ?? const [];
    final acceleratorsRaw = (json['accelerators'] as List?) ?? const [];
    final historyRaw = (json['recent_history'] as List?) ?? const [];

    return IncomeSource(
      id: (json['id'] as String?) ?? '',
      displayName: BilingualText.fromJson(json['display_name']),
      category: (json['category'] as String?) ?? '',
      icon: json['icon'] as String?,
      state: SourceState.fromWire(json['state'] as String?),
      stateLabel: BilingualText.fromJson(json['state_label'], fallback: ''),
      phase: (json['phase'] as String?) ?? '',
      currentPeriod: json['current_period'] is Map<String, dynamic>
          ? CurrentPeriodEarnings.fromJson(json['current_period'] as Map<String, dynamic>)
          : null,
      math: json['math'] is Map<String, dynamic>
          ? MathInfo.fromJson(json['math'] as Map<String, dynamic>)
          : null,
      insights: insightsRaw
          .whereType<Map<String, dynamic>>()
          .map(IncomeInsight.fromJson)
          .toList(growable: false),
      historyEndpoint: json['history_endpoint'] as String?,
      recentHistory: historyRaw
          .whereType<Map<String, dynamic>>()
          .map(HistoryItem.fromJson)
          .toList(growable: false),
      eligibility: json['eligibility'] is Map<String, dynamic>
          ? Eligibility.fromJson(json['eligibility'] as Map<String, dynamic>)
          : null,
      estimate: json['estimate'] is Map<String, dynamic>
          ? Estimate.fromJson(json['estimate'] as Map<String, dynamic>)
          : null,
      accelerators: acceleratorsRaw
          .whereType<Map<String, dynamic>>()
          .map(Accelerator.fromJson)
          .toList(growable: false),
      primaryCta: json['primary_cta'] is Map<String, dynamic>
          ? IncomeCta.fromJson(json['primary_cta'] as Map<String, dynamic>)
          : null,
      secondaryCta: json['secondary_cta'] is Map<String, dynamic>
          ? IncomeCta.fromJson(json['secondary_cta'] as Map<String, dynamic>)
          : null,
    );
  }
}

// ---------------------------------------------------------------------------
// Top-level wrapper for GET /api/creators/{id}/income/sources
// ---------------------------------------------------------------------------

@immutable
class IncomeSummary {
  final int walletBalanceMinor;
  final int walletPendingMinor;
  final int walletLifetimeMinor;
  final String currency;
  final int thisPeriodNetMinor;
  final double thisPeriodDeltaPct;
  final String? topSourceId;
  final double topSourceSharePct;
  final int unlockedCount;
  final int totalCount;

  const IncomeSummary({
    required this.walletBalanceMinor,
    required this.walletPendingMinor,
    required this.walletLifetimeMinor,
    required this.currency,
    required this.thisPeriodNetMinor,
    required this.thisPeriodDeltaPct,
    required this.topSourceId,
    required this.topSourceSharePct,
    required this.unlockedCount,
    required this.totalCount,
  });

  factory IncomeSummary.fromJson(Map<String, dynamic> json) {
    return IncomeSummary(
      walletBalanceMinor: _parseInt(json['wallet_balance_minor']),
      walletPendingMinor: _parseInt(json['wallet_pending_minor']),
      walletLifetimeMinor: _parseInt(json['wallet_lifetime_minor']),
      currency: (json['currency'] as String?) ?? 'TZS',
      thisPeriodNetMinor: _parseInt(json['this_period_net_minor']),
      thisPeriodDeltaPct: _parseDouble(json['this_period_delta_pct']),
      topSourceId: json['top_source_id'] as String?,
      topSourceSharePct: _parseDouble(json['top_source_share_pct']),
      unlockedCount: _parseInt(json['unlocked_count']),
      totalCount: _parseInt(json['total_count']),
    );
  }

  static const empty = IncomeSummary(
    walletBalanceMinor: 0,
    walletPendingMinor: 0,
    walletLifetimeMinor: 0,
    currency: 'TZS',
    thisPeriodNetMinor: 0,
    thisPeriodDeltaPct: 0,
    topSourceId: null,
    topSourceSharePct: 0,
    unlockedCount: 0,
    totalCount: 0,
  );
}

@immutable
class IncomeSourcesResponse {
  final IncomeSummary summary;
  final IncomePeriod period;
  final DateTime? periodStartsAt;
  final DateTime? periodEndsAt;
  final List<IncomeSource> sources;
  final LiveEarningsTally? liveTally;

  const IncomeSourcesResponse({
    required this.summary,
    required this.period,
    required this.periodStartsAt,
    required this.periodEndsAt,
    required this.sources,
    required this.liveTally,
  });

  factory IncomeSourcesResponse.fromJson(Map<String, dynamic> json) {
    final sourcesRaw = (json['sources'] as List?) ?? const [];
    final periodMap = json['period'] is Map<String, dynamic>
        ? json['period'] as Map<String, dynamic>
        : const <String, dynamic>{};
    return IncomeSourcesResponse(
      summary: json['summary'] is Map<String, dynamic>
          ? IncomeSummary.fromJson(json['summary'] as Map<String, dynamic>)
          : IncomeSummary.empty,
      period: IncomePeriod.fromWire(periodMap['type'] as String?),
      periodStartsAt: _parseDate(periodMap['starts_at']),
      periodEndsAt: _parseDate(periodMap['ends_at']),
      sources: sourcesRaw
          .whereType<Map<String, dynamic>>()
          .map(IncomeSource.fromJson)
          .toList(growable: false),
      liveTally: json['live_tally'] is Map<String, dynamic>
          ? LiveEarningsTally.fromJson(json['live_tally'] as Map<String, dynamic>)
          : null,
    );
  }
}

/// Pinned LIVE card state — present only when the creator is currently
/// streaming. Spec §11.
@immutable
class LiveEarningsTally {
  final int streamId;
  final DateTime startedAt;
  final int giftsCount;
  final int superChatCount;
  final int totalNetMinor;

  const LiveEarningsTally({
    required this.streamId,
    required this.startedAt,
    required this.giftsCount,
    required this.superChatCount,
    required this.totalNetMinor,
  });

  factory LiveEarningsTally.fromJson(Map<String, dynamic> json) {
    return LiveEarningsTally(
      streamId: _parseInt(json['stream_id']),
      startedAt: _parseDate(json['started_at']) ?? DateTime.now(),
      giftsCount: _parseInt(json['gifts_count']),
      superChatCount: _parseInt(json['super_chat_count']),
      totalNetMinor: _parseInt(json['total_net_minor']),
    );
  }
}

@immutable
class HistoryPage {
  final List<HistoryItem> items;
  final String? nextCursor;
  const HistoryPage({required this.items, required this.nextCursor});

  factory HistoryPage.fromJson(Map<String, dynamic> json) {
    final raw = (json['items'] as List?) ?? const [];
    return HistoryPage(
      items: raw
          .whereType<Map<String, dynamic>>()
          .map(HistoryItem.fromJson)
          .toList(growable: false),
      nextCursor: json['next_cursor'] as String?,
    );
  }
}
