// lib/creator/screens/stream_type_earnings_screen.dart
//
// Streams earnings — mirror of PostTypeEarningsScreen but keyed on
// stream_type. Sources its row taxonomy from
// EarningsTaxonomyService.instance.current.streamRows (server-served)
// with hardcoded fallback in
// lib/creator/models/stream_type_earnings_taxonomy.dart.
//
// Backend driven by `stream_type` query param to /by-metric,
// /by-multiplier, /by-derivative-kind. (Backend filter accepts the
// same arg name as posts; the streams API surface uses the same
// /users/me/earnings/* endpoints — earnings are stream-context-aware
// via the post_type/stream column on earning_events.)

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import '../../l10n/app_strings_scope.dart';
import '../../services/local_storage_service.dart';
import '../../widgets/tajiri_app_bar.dart';
import '../models/creator_earnings_models.dart';
import '../models/stream_type_earnings_taxonomy.dart';
import '../services/creator_earnings_service.dart';
import '../services/earnings_taxonomy_service.dart';

const Color _kPrimary = Color(0xFF1A1A1A);
const Color _kSecondary = Color(0xFF666666);
const Color _kTertiary = Color(0xFF999999);
const Color _kBorder = Color(0xFFE5E5E5);
const Color _kSurface = Colors.white;
const Color _kBackground = Color(0xFFFAFAFA);
const Color _kIconBg = Color(0xFFF5F5F5);

enum _Period { week, month, quarter, year }

extension _PeriodWire on _Period {
  String get wire => name;
  String label(bool isSw) => switch (this) {
        _Period.week => isSw ? 'Wiki' : 'Week',
        _Period.month => isSw ? 'Mwezi' : 'Month',
        _Period.quarter => isSw ? 'Robo' : 'Quarter',
        _Period.year => isSw ? 'Mwaka' : 'Year',
      };
}

class StreamTypeEarningsScreen extends StatefulWidget {
  final int creatorId;
  final String streamType;
  const StreamTypeEarningsScreen({
    super.key,
    required this.creatorId,
    required this.streamType,
  });

  @override
  State<StreamTypeEarningsScreen> createState() =>
      _StreamTypeEarningsScreenState();
}

class _StreamTypeEarningsScreenState extends State<StreamTypeEarningsScreen> {
  final _service = CreatorEarningsService();

  _Period _period = _Period.month;
  MetricBreakdownResponse? _data;
  MultiplierContributionResponse? _byMultiplier;
  bool _loading = true;
  String? _error;
  String? _token;

  @override
  void initState() {
    super.initState();
    _hydrate();
  }

  Future<void> _hydrate() async {
    final token = (await LocalStorageService.getInstance()).getAuthToken();
    if (!mounted) return;
    setState(() => _token = token);
    await _load();
  }

  Future<void> _load() async {
    if (_token == null) return;
    setState(() {
      _loading = true;
      _error = null;
    });
    try {
      // Stream events are filed under existing earning_events.stream
      // column with values 'engagement' / 'fan_funding' / 'live_gifts' /
      // 'marketplace'. We pull the union and let the screen filter +
      // bucket per stream-row taxonomy.
      final breakdownF = _service.getByMetric(
        userId: widget.creatorId,
        token: _token!,
        period: _period.wire,
        // No post_type filter — streams have no posts.id; we'd need a
        // separate stream-context filter if backend ever splits live
        // events by stream_type. For v1 the screen taxonomy gates by
        // capability matrix client-side.
      );
      final byMultiplierF = _service.getByMultiplier(
        userId: widget.creatorId,
        token: _token!,
        period: _period.wire,
      );
      final fresh = await breakdownF;
      final byMultiplier = await byMultiplierF;
      if (!mounted) return;
      setState(() {
        _data = fresh;
        _byMultiplier = byMultiplier;
        _loading = false;
      });
    } catch (e) {
      if (!mounted) return;
      setState(() {
        _loading = false;
        _error = _sanitize(e.toString());
      });
    }
  }

  String _sanitize(String raw) {
    final isSw = AppStringsScope.of(context)?.isSwahili ?? false;
    if (raw.contains('SocketException') || raw.contains('Failed host lookup')) {
      return isSw
          ? 'Hakuna intaneti. Hakikisha umeunganishwa.'
          : "Can't reach the server. Check your connection.";
    }
    return isSw ? 'Imeshindwa kupakia.' : 'Failed to load.';
  }

  void _setPeriod(_Period p) {
    if (p == _period) return;
    HapticFeedback.selectionClick();
    setState(() => _period = p);
    _load();
  }

  @override
  Widget build(BuildContext context) {
    final isSw = AppStringsScope.of(context)?.isSwahili ?? false;
    final cfg = streamTypeEarningsConfigFor(widget.streamType);
    final title = cfg == null
        ? (isSw ? '${widget.streamType} · Mapato' : '${widget.streamType} · Earnings')
        : (isSw ? '${cfg.labelSw} · Mapato' : '${cfg.labelEn} · Earnings');
    return Scaffold(
      backgroundColor: _kBackground,
      appBar: TajiriAppBar(title: title),
      body: SafeArea(
        child: RefreshIndicator(
          color: _kPrimary,
          onRefresh: _load,
          child: _loading && _data == null
              ? const _LoadingList()
              : _data == null && _error != null
                  ? _ErrorView(message: _error!, onRetry: _load, isSw: isSw)
                  : _buildBody(isSw),
        ),
      ),
    );
  }

  /// Live + fallback section labels.
  String _sectionLabel(String section, bool isSw) {
    final live = EarningsTaxonomyService.instance.current;
    if (live != null) {
      final m = live.streamSectionLabels[section];
      if (m != null) return '$section. ${(isSw ? m['sw'] : m['en']) ?? section}';
    }
    return '$section. ${_kFallbackSectionLabels[section]?[isSw ? 'sw' : 'en'] ?? section}';
  }

  static const Map<String, Map<String, String>> _kFallbackSectionLabels = {
    'I':    {'en': 'DIRECT STREAM ENGAGEMENT', 'sw': 'USHIRIKI WA MOJA KWA MOJA'},
    'II':   {'en': 'CHAT & CONVERSATION',      'sw': 'GUMZO NA MAZUNGUMZO'},
    'III':  {'en': 'DISTRIBUTION & DISCOVERY', 'sw': 'USAMBAZAJI NA UGUNDUZI'},
    'IV':   {'en': 'VOD & DERIVATIVE',         'sw': 'VOD NA YALIYOMO YA DERIVATIVE'},
    'V':    {'en': 'LOCALIZATION & ACCESSIBILITY','sw': 'KUTAFSIRI NA UFIKIAJI'},
    'VI':   {'en': 'CURATION',                 'sw': 'UKUSANYAJI'},
    'VII':  {'en': 'MULTI-STREAMER COLLAB',    'sw': 'USHIRIKIANO WA WATAGAJI'},
    'VIII': {'en': 'EDUCATIONAL & UTILITY',    'sw': 'ELIMU NA MATUMIZI'},
    'IX':   {'en': 'LIVE COMMERCE',            'sw': 'BIASHARA YA MOJA KWA MOJA'},
    'X':    {'en': 'PLATFORM HEALTH & QUALITY','sw': 'AFYA YA JUKWAA'},
    'XI':   {'en': 'AI & SYNTHETIC MEDIA',     'sw': 'AI NA VYOMBO VYA AI'},
    'XII':  {'en': 'COMMUNITY CONTRIBUTION',   'sw': 'MCHANGO WA JAMII'},
  };

  /// All (metric, actor_role) rows from the live response or fallback.
  List<TaxonomyRow> _allStreamRows() {
    final live = EarningsTaxonomyService.instance.current;
    if (live != null && live.streamRows.isNotEmpty) {
      return live.streamRows;
    }
    return _kFallbackStreamRows;
  }

  /// Multiplier groups — service first, fallback constants.
  List<String> _multiplierGroup(String group) {
    final live = EarningsTaxonomyService.instance.current;
    if (live != null && live.streamXMultipliers.isNotEmpty) {
      return live.streamXMultipliers[group] ?? const [];
    }
    return _kFallbackXMultipliers[group] ?? const [];
  }

  static const Map<String, List<String>> _kFallbackXMultipliers = {
    'bonuses': [
      'originality_bonus', 'uptime_consistency_bonus', 'low_buffer_bonus',
      'partner_tier_boost', 'mwanzo_boost',
      'peak_concurrency_multiplier', 'chat_health_bonus',
      'accessible_stream_bonus',
    ],
    'engagement_penalties': [
      'rapid_leave_penalty', 'mute_streamer_penalty',
      'unfollow_after_stream_penalty', 'block_streamer_penalty',
      'report_stream_penalty', 'negative_reaction_penalty',
      'chat_disable_penalty',
    ],
    'system_clamps': [
      'low_uptime_clamp', 'high_buffer_clamp', 'late_start_clamp',
      'cancel_streak_clamp', 'simulcast_only_clamp',
      'viewbot_detected', 'chat_bot_ratio_high', 'coordinated_gift_dump',
      'self_tipping', 'circular_subscription_ring',
      'raid_drop_back_out', 'restream_without_license',
      'mature_content_clamp', 'ragebait_chat_clamp',
      'harassment_pattern_clamp', 'misinformation_clamp',
      'synthetic_undisclosed_clamp',
    ],
  };

  Widget _buildBody(bool isSw) {
    final data = _data!;
    final agg = _PairAgg.fromRows(data.rows);
    final st = widget.streamType;

    final allRows = _allStreamRows();
    final relevant = allRows.where((r) => isStreamRowRelevantForStreamType(
          streamType: st,
          metric: r.metric,
          actorRole: r.actorRole,
        ));
    final bySection = <String, List<TaxonomyRow>>{};
    for (final r in relevant) {
      bySection.putIfAbsent(r.section, () => []).add(r);
    }

    // Compute streams-only totals — the API returns ALL of the user's
    // earning events (posts + streams). The Hero must only sum the
    // rows that match the streams taxonomy for this stream type, plus
    // any non-canonical rows the catchall surfaces.
    final relevantKeys = relevant
        .map((r) => '${r.metric}|${r.actorRole}')
        .toSet();
    double streamsTotalNet = 0;
    int streamsTotalEvents = 0;
    for (final entry in agg.map.entries) {
      if (relevantKeys.contains(entry.key)) {
        streamsTotalNet += entry.value.netTsh;
        streamsTotalEvents += entry.value.events;
      }
    }

    Widget? sectionWidget(String section) {
      final rows = bySection[section];
      if (rows == null || rows.isEmpty) return null;
      final pairs = rows
          .map((r) => _Pair(r.metric, r.actorRole))
          .toList(growable: false);
      return Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _SectionLabel(_sectionLabel(section, isSw)),
          const SizedBox(height: 8),
          _PairTable(pairs: pairs, agg: agg, isSw: isSw),
        ],
      );
    }

    // Catchall for non-canonical pairs returned by backend BUT only
    // pairs that look stream-related (heuristic: metric starts with
    // 'live_', 'vod_', 'stream_', 'chat_', 'q_and_a_', 'cohost_',
    // 'battle_', 'raid_', 'host_', or matches a known stream-context
    // metric). Prevents the screen from surfacing post-side rows like
    // 'view·author' on the streams page.
    bool isLikelyStreamMetric(String metric) {
      const prefixes = [
        'live_', 'vod_', 'stream_', 'chat_', 'q_and_a_',
        'cohost_', 'battle_', 'raid_', 'host_',
      ];
      return prefixes.any(metric.startsWith);
    }
    final knownPairs = <String>{
      for (final r in allRows) '${r.metric}|${r.actorRole}',
    };
    final unknownPairs = <_Pair>[
      for (final entry in agg.map.entries)
        if (!knownPairs.contains(entry.key)
            && entry.value.netTsh.abs() > 0
            && isLikelyStreamMetric(entry.key.split('|').first))
          _Pair(
            entry.key.split('|').first,
            entry.key.split('|').elementAt(1),
          ),
    ]..sort((a, b) => a.key.compareTo(b.key));
    // Catchall sums also count toward Hero total.
    for (final p in unknownPairs) {
      final v = agg.get(p);
      streamsTotalNet += v.netTsh;
      streamsTotalEvents += v.events;
    }
    Widget? catchallSection;
    if (unknownPairs.isNotEmpty) {
      catchallSection = Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _SectionLabel(isSw
              ? '∗  MENGINEYO (HAYAJATAJWA)'
              : '∗  OTHER (UNCATEGORISED)'),
          const SizedBox(height: 8),
          _PairTable(pairs: unknownPairs, agg: agg, isSw: isSw),
        ],
      );
    }

    final body = <Widget?>[
      _Hero(
        data: data,
        isSw: isSw,
        streamType: st,
        streamsTotalNet: streamsTotalNet,
        streamsTotalEvents: streamsTotalEvents,
      ),
      const SizedBox(height: 14),
      _PeriodPills(selected: _period, onChanged: _setPeriod, isSw: isSw),
      const SizedBox(height: 18),
      for (final section in const [
        'I', 'II', 'III', 'IV', 'V', 'VI', 'VII', 'VIII', 'IX', 'XI', 'XII'
      ]) ...[
        sectionWidget(section),
        if (sectionWidget(section) != null) const SizedBox(height: 18),
      ],
      // §X — multipliers (3 sub-tables + catchall) sourced from /by-multiplier.
      _StreamXMultipliers(
        bonuses: _multiplierGroup('bonuses'),
        engagementPenalties: _multiplierGroup('engagement_penalties'),
        systemClamps: _multiplierGroup('system_clamps'),
        contributions: _byMultiplier,
        sectionLabel: _sectionLabel('X', isSw),
        isSw: isSw,
      ),
      const SizedBox(height: 18),
      catchallSection,
      const SizedBox(height: 22),
      _ProvenanceCTA(streamType: st, isSw: isSw),
      const SizedBox(height: 16),
      _HowItWorks(isSw: isSw, streamType: st),
    ].whereType<Widget>().toList();

    return ListView(
      physics: const AlwaysScrollableScrollPhysics(),
      padding: const EdgeInsets.fromLTRB(16, 16, 16, 24),
      children: body,
    );
  }
}

/// Convenience wrappers for navigation.
class LiveVideoEarningsScreen extends StatelessWidget {
  final int creatorId;
  const LiveVideoEarningsScreen({super.key, required this.creatorId});
  @override
  Widget build(BuildContext context) =>
      StreamTypeEarningsScreen(creatorId: creatorId, streamType: 'live_video');
}

class AudioRoomEarningsScreen extends StatelessWidget {
  final int creatorId;
  const AudioRoomEarningsScreen({super.key, required this.creatorId});
  @override
  Widget build(BuildContext context) =>
      StreamTypeEarningsScreen(creatorId: creatorId, streamType: 'audio_only');
}

class SimulcastEarningsScreen extends StatelessWidget {
  final int creatorId;
  const SimulcastEarningsScreen({super.key, required this.creatorId});
  @override
  Widget build(BuildContext context) =>
      StreamTypeEarningsScreen(creatorId: creatorId, streamType: 'simulcast');
}

class SubscriberOnlyEarningsScreen extends StatelessWidget {
  final int creatorId;
  const SubscriberOnlyEarningsScreen({super.key, required this.creatorId});
  @override
  Widget build(BuildContext context) => StreamTypeEarningsScreen(
      creatorId: creatorId, streamType: 'subscriber_only');
}

class PaidAttendanceEarningsScreen extends StatelessWidget {
  final int creatorId;
  const PaidAttendanceEarningsScreen({super.key, required this.creatorId});
  @override
  Widget build(BuildContext context) => StreamTypeEarningsScreen(
      creatorId: creatorId, streamType: 'paid_attendance');
}

class CoStreamingEarningsScreen extends StatelessWidget {
  final int creatorId;
  const CoStreamingEarningsScreen({super.key, required this.creatorId});
  @override
  Widget build(BuildContext context) =>
      StreamTypeEarningsScreen(creatorId: creatorId, streamType: 'co_streaming');
}

// ─── Hardcoded fallback rows (used only when service cache empty) ───
const List<TaxonomyRow> _kFallbackStreamRows = [
  // Minimal — full taxonomy lives on backend; this is just enough so
  // the screen doesn't render empty when offline on first launch.
  TaxonomyRow(metric: 'live_view', actorRole: 'author', section: 'I', requiredCaps: <String>{}),
  TaxonomyRow(metric: 'live_watch_minute', actorRole: 'author', section: 'I', requiredCaps: {'time_based'}),
  TaxonomyRow(metric: 'live_reaction', actorRole: 'author', section: 'I', requiredCaps: <String>{}),
  TaxonomyRow(metric: 'live_chat', actorRole: 'author', section: 'I', requiredCaps: <String>{}),
  TaxonomyRow(metric: 'live_super_chat', actorRole: 'author', section: 'I', requiredCaps: <String>{}),
  TaxonomyRow(metric: 'live_gift', actorRole: 'author', section: 'I', requiredCaps: <String>{}),
  TaxonomyRow(metric: 'live_tip', actorRole: 'author', section: 'I', requiredCaps: <String>{}),
  TaxonomyRow(metric: 'follow_from_live', actorRole: 'author', section: 'I', requiredCaps: <String>{}),
  TaxonomyRow(metric: 'subscribe_from_live', actorRole: 'author', section: 'I', requiredCaps: <String>{}),
];

// ─── Pair / aggregator types (mirror photo_earnings_screen) ─────────

class _Pair {
  final String metric;
  final String actorRole;
  const _Pair(this.metric, this.actorRole);
  String get key => '$metric|$actorRole';
}

class _PairAgg {
  final Map<String, ({double netTsh, int events, int rawCount})> map;
  const _PairAgg(this.map);
  factory _PairAgg.fromRows(List<MetricBreakdownRow> rows) {
    final out = <String, ({double netTsh, int events, int rawCount})>{};
    for (final r in rows) {
      if (r.metric == 'period_settlement') continue;
      final k = '${r.metric}|${r.actorRole}';
      final cur = out[k] ?? (netTsh: 0.0, events: 0, rawCount: 0);
      out[k] = (
        netTsh: cur.netTsh + r.netTsh,
        events: cur.events + r.eventCount,
        rawCount: cur.rawCount + r.rawCountTotal,
      );
    }
    return _PairAgg(out);
  }

  ({double netTsh, int events, int rawCount}) get(_Pair p) =>
      map[p.key] ?? (netTsh: 0.0, events: 0, rawCount: 0);
}

// ─── Hero ───────────────────────────────────────────────────────────

class _Hero extends StatelessWidget {
  final MetricBreakdownResponse data;
  final bool isSw;
  final String streamType;
  /// Streams-only filtered total (sum of all streams-taxonomy rows
  /// that survived the per-stream-type capability gate, plus
  /// non-canonical catchall rows that look stream-context). NOT the
  /// raw API total — the API returns the user's earnings across all
  /// categories.
  final double streamsTotalNet;
  final int streamsTotalEvents;
  const _Hero({
    required this.data,
    required this.isSw,
    required this.streamType,
    required this.streamsTotalNet,
    required this.streamsTotalEvents,
  });

  @override
  Widget build(BuildContext context) {
    final cfg = streamTypeEarningsConfigFor(streamType);
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: _kPrimary,
        borderRadius: BorderRadius.circular(16),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                width: 36, height: 36,
                decoration: BoxDecoration(
                  color: Colors.white.withValues(alpha: 0.10),
                  borderRadius: BorderRadius.circular(10),
                ),
                alignment: Alignment.center,
                child: Icon(cfg?.icon ?? Icons.live_tv_rounded,
                    color: Colors.white, size: 18),
              ),
              const SizedBox(width: 10),
              Expanded(
                child: Text(
                  isSw
                      ? '${cfg?.labelSw ?? streamType} · ${_formatMonth(data.periodStart, true)}'
                      : '${cfg?.labelEn ?? streamType} · ${_formatMonth(data.periodStart, false)}',
                  style: TextStyle(
                    fontSize: 12,
                    color: Colors.white.withValues(alpha: 0.70),
                    fontWeight: FontWeight.w500,
                    letterSpacing: 0.2,
                  ),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          Row(
            crossAxisAlignment: CrossAxisAlignment.end,
            children: [
              Text(
                _fmtAmount(streamsTotalNet),
                style: const TextStyle(
                  fontSize: 36,
                  fontWeight: FontWeight.w800,
                  color: Colors.white,
                  height: 1.0,
                  letterSpacing: -0.6,
                  fontFeatures: [FontFeature.tabularFigures()],
                ),
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
              ),
              const SizedBox(width: 6),
              Padding(
                padding: const EdgeInsets.only(bottom: 4),
                child: Text(
                  data.currency,
                  style: TextStyle(
                    fontSize: 14,
                    fontWeight: FontWeight.w600,
                    color: Colors.white.withValues(alpha: 0.80),
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 6),
          Text(
            isSw
                ? '$streamsTotalEvents matukio · halisi (baada ya ada)'
                : '$streamsTotalEvents events · net (after fees)',
            style: TextStyle(
              fontSize: 12,
              color: Colors.white.withValues(alpha: 0.70),
            ),
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
          ),
        ],
      ),
    );
  }
}

// ─── Period pills ──────────────────────────────────────────────────

class _PeriodPills extends StatelessWidget {
  final _Period selected;
  final ValueChanged<_Period> onChanged;
  final bool isSw;
  const _PeriodPills({
    required this.selected,
    required this.onChanged,
    required this.isSw,
  });

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        for (var i = 0; i < _Period.values.length; i++) ...[
          Expanded(
            child: InkWell(
              borderRadius: BorderRadius.circular(20),
              onTap: () => onChanged(_Period.values[i]),
              child: Container(
                padding: const EdgeInsets.symmetric(vertical: 8),
                decoration: BoxDecoration(
                  color: _Period.values[i] == selected ? _kPrimary : _kSurface,
                  borderRadius: BorderRadius.circular(20),
                  border: Border.all(
                      color: _Period.values[i] == selected
                          ? _kPrimary
                          : _kBorder),
                ),
                alignment: Alignment.center,
                child: Text(
                  _Period.values[i].label(isSw),
                  style: TextStyle(
                    fontSize: 12,
                    fontWeight: FontWeight.w600,
                    color: _Period.values[i] == selected
                        ? Colors.white
                        : _kPrimary,
                  ),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
              ),
            ),
          ),
          if (i < _Period.values.length - 1) const SizedBox(width: 6),
        ],
      ],
    );
  }
}

// ─── Section label / pair table / row ──────────────────────────────

class _SectionLabel extends StatelessWidget {
  final String label;
  const _SectionLabel(this.label);
  @override
  Widget build(BuildContext context) => Padding(
        padding: const EdgeInsets.symmetric(horizontal: 4),
        child: Text(
          label,
          style: const TextStyle(
            fontSize: 11,
            fontWeight: FontWeight.w700,
            color: _kTertiary,
            letterSpacing: 0.6,
          ),
          maxLines: 1,
          overflow: TextOverflow.ellipsis,
        ),
      );
}

class _SubLabel extends StatelessWidget {
  final String label;
  const _SubLabel(this.label);
  @override
  Widget build(BuildContext context) => Padding(
        padding: const EdgeInsets.symmetric(horizontal: 4),
        child: Text(
          label,
          style: const TextStyle(
            fontSize: 10,
            fontWeight: FontWeight.w600,
            color: _kSecondary,
            letterSpacing: 0.4,
          ),
          maxLines: 1,
          overflow: TextOverflow.ellipsis,
        ),
      );
}

class _PairTable extends StatelessWidget {
  final List<_Pair> pairs;
  final _PairAgg agg;
  final bool isSw;
  const _PairTable({
    required this.pairs,
    required this.agg,
    required this.isSw,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        color: _kSurface,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: _kBorder),
      ),
      child: Column(
        children: [
          for (var i = 0; i < pairs.length; i++) ...[
            _PairRowTile(pair: pairs[i], data: agg.get(pairs[i]), isSw: isSw),
            if (i < pairs.length - 1)
              const Divider(
                  height: 1,
                  color: _kBorder,
                  indent: 14,
                  endIndent: 14),
          ],
        ],
      ),
    );
  }
}

class _PairRowTile extends StatelessWidget {
  final _Pair pair;
  final ({double netTsh, int events, int rawCount}) data;
  final bool isSw;
  const _PairRowTile({
    required this.pair,
    required this.data,
    required this.isSw,
  });

  @override
  Widget build(BuildContext context) {
    final hasData = data.netTsh.abs() > 0;
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
      child: Row(
        children: [
          Container(
            width: 36,
            height: 36,
            decoration: BoxDecoration(
              color: _kIconBg,
              borderRadius: BorderRadius.circular(10),
            ),
            alignment: Alignment.center,
            child: Icon(_metricIcon(pair.metric), size: 18, color: _kPrimary),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  '${pair.metric} · ${pair.actorRole}',
                  style: const TextStyle(
                    fontSize: 13,
                    fontWeight: FontWeight.w700,
                    color: _kPrimary,
                    fontFeatures: [FontFeature.tabularFigures()],
                  ),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
                const SizedBox(height: 2),
                Text(
                  isSw
                      ? '${data.events} matukio · ${data.rawCount} jumla'
                      : '${data.events} events · ${data.rawCount} total',
                  style: const TextStyle(
                    fontSize: 11,
                    color: _kTertiary,
                    fontFeatures: [FontFeature.tabularFigures()],
                  ),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
              ],
            ),
          ),
          const SizedBox(width: 10),
          Text(
            'TZS ${_fmtAmount(data.netTsh)}',
            style: TextStyle(
              fontSize: 14,
              fontWeight: FontWeight.w800,
              color: hasData ? _kPrimary : _kTertiary,
              fontFeatures: const [FontFeature.tabularFigures()],
            ),
          ),
        ],
      ),
    );
  }
}

// ─── §X multiplier sub-tables ──────────────────────────────────────

class _StreamXMultipliers extends StatelessWidget {
  final List<String> bonuses;
  final List<String> engagementPenalties;
  final List<String> systemClamps;
  final MultiplierContributionResponse? contributions;
  final String sectionLabel;
  final bool isSw;
  const _StreamXMultipliers({
    required this.bonuses,
    required this.engagementPenalties,
    required this.systemClamps,
    required this.contributions,
    required this.sectionLabel,
    required this.isSw,
  });

  @override
  Widget build(BuildContext context) {
    final returned = <String>{
      for (final r in contributions?.rows ?? const []) r.multiplier,
    };
    final allListed = {...bonuses, ...engagementPenalties, ...systemClamps};
    final unknown = returned.difference(allListed).toList()..sort();
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _SectionLabel(sectionLabel),
        const SizedBox(height: 8),
        _SubLabel(isSw ? 'Bonasi' : 'Bonuses'),
        const SizedBox(height: 6),
        _MultiplierTable(
          multipliers: bonuses, contributions: contributions, isSw: isSw),
        const SizedBox(height: 12),
        _SubLabel(isSw
            ? 'Adhabu za ubora wa mwingiliano'
            : 'Engagement-quality penalties'),
        const SizedBox(height: 6),
        _MultiplierTable(
          multipliers: engagementPenalties,
          contributions: contributions,
          isSw: isSw,
        ),
        const SizedBox(height: 12),
        _SubLabel(isSw
            ? 'Punguzo za mfumo, usalama na AI'
            : 'System / safety / AI clamps'),
        const SizedBox(height: 6),
        _MultiplierTable(
          multipliers: systemClamps,
          contributions: contributions,
          isSw: isSw,
        ),
        if (unknown.isNotEmpty) ...[
          const SizedBox(height: 12),
          _SubLabel(isSw ? 'Mengineyo' : 'Other (uncategorised)'),
          const SizedBox(height: 6),
          _MultiplierTable(
            multipliers: unknown, contributions: contributions, isSw: isSw),
        ],
      ],
    );
  }
}

class _MultiplierTable extends StatelessWidget {
  final List<String> multipliers;
  final MultiplierContributionResponse? contributions;
  final bool isSw;
  const _MultiplierTable({
    required this.multipliers,
    required this.contributions,
    required this.isSw,
  });

  @override
  Widget build(BuildContext context) {
    if (multipliers.isEmpty) return const SizedBox.shrink();
    final map = <String, MultiplierContributionRow>{
      for (final r in contributions?.rows ??
          const <MultiplierContributionRow>[])
        r.multiplier: r,
    };
    return Container(
      decoration: BoxDecoration(
        color: _kSurface,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: _kBorder),
      ),
      child: Column(
        children: [
          for (var i = 0; i < multipliers.length; i++) ...[
            _MultiplierRowTile(
              multiplier: multipliers[i],
              contribution: map[multipliers[i]],
              isSw: isSw,
            ),
            if (i < multipliers.length - 1)
              const Divider(
                  height: 1,
                  color: _kBorder,
                  indent: 14,
                  endIndent: 14),
          ],
        ],
      ),
    );
  }
}

class _MultiplierRowTile extends StatelessWidget {
  final String multiplier;
  final MultiplierContributionRow? contribution;
  final bool isSw;
  const _MultiplierRowTile({
    required this.multiplier,
    required this.contribution,
    required this.isSw,
  });

  @override
  Widget build(BuildContext context) {
    final c = contribution;
    final hasData = c != null && c.contributionTsh.abs() > 0;
    final isClamp = c != null && c.avgValue < 1.0;
    final tzsLabel =
        c == null ? 'TZS 0' : 'TZS ${_fmtAmount(c.contributionTsh)}';
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
      child: Row(
        children: [
          Container(
            width: 36, height: 36,
            decoration: BoxDecoration(
              color: _kIconBg,
              borderRadius: BorderRadius.circular(10),
            ),
            alignment: Alignment.center,
            child: Icon(
              isClamp ? Icons.trending_down_rounded : Icons.trending_up_rounded,
              size: 18, color: _kPrimary,
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  multiplier,
                  style: const TextStyle(
                    fontSize: 13,
                    fontWeight: FontWeight.w700,
                    color: _kPrimary,
                    fontFeatures: [FontFeature.tabularFigures()],
                  ),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
                if (c != null && c.eventCount > 0) ...[
                  const SizedBox(height: 2),
                  Text(
                    isSw
                        ? '${c.avgValue.toStringAsFixed(2)}× wastani · ${c.eventCount} matukio'
                        : '${c.avgValue.toStringAsFixed(2)}× avg · ${c.eventCount} events',
                    style: const TextStyle(
                      fontSize: 11,
                      color: _kTertiary,
                      fontFeatures: [FontFeature.tabularFigures()],
                    ),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                ],
              ],
            ),
          ),
          const SizedBox(width: 10),
          Text(
            tzsLabel,
            style: TextStyle(
              fontSize: 14,
              fontWeight: FontWeight.w800,
              color: hasData ? _kPrimary : _kTertiary,
              fontFeatures: const [FontFeature.tabularFigures()],
            ),
          ),
        ],
      ),
    );
  }
}

// ─── Footer CTAs ───────────────────────────────────────────────────

class _ProvenanceCTA extends StatelessWidget {
  final String streamType;
  final bool isSw;
  const _ProvenanceCTA({required this.streamType, required this.isSw});

  @override
  Widget build(BuildContext context) {
    final cfg = streamTypeEarningsConfigFor(streamType);
    final label = cfg?.labelEn.toLowerCase() ?? streamType;
    return Material(
      color: _kPrimary,
      borderRadius: BorderRadius.circular(12),
      clipBehavior: Clip.antiAlias,
      child: InkWell(
        onTap: () {
          HapticFeedback.selectionClick();
          Navigator.pushNamed(context, '/earnings-provenance',
              arguments: {'stream': 'live_gifts'});
        },
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
          child: Row(
            children: [
              Icon(cfg?.icon ?? Icons.live_tv_rounded,
                  size: 18, color: Colors.white),
              const SizedBox(width: 10),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      isSw
                          ? 'Ledger ya matukio ya $label'
                          : 'View per-event ledger ($label)',
                      style: const TextStyle(
                        fontSize: 13,
                        fontWeight: FontWeight.w700,
                        color: Colors.white,
                      ),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                    const SizedBox(height: 2),
                    Text(
                      isSw
                          ? 'Tukio kwa tukio: muda, kiasi, hali'
                          : 'Per-event: timestamp, amount, status',
                      style: TextStyle(
                        fontSize: 11,
                        color: Colors.white.withValues(alpha: 0.75),
                      ),
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                    ),
                  ],
                ),
              ),
              Icon(Icons.chevron_right_rounded,
                  color: Colors.white.withValues(alpha: 0.85)),
            ],
          ),
        ),
      ),
    );
  }
}

class _HowItWorks extends StatelessWidget {
  final bool isSw;
  final String streamType;
  const _HowItWorks({required this.isSw, required this.streamType});

  @override
  Widget build(BuildContext context) {
    final cfg = streamTypeEarningsConfigFor(streamType);
    final labelEn = cfg?.labelEn.toLowerCase() ?? streamType;
    final labelSw = cfg?.labelSw ?? streamType;
    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: _kSurface,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: _kBorder),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              const Icon(Icons.info_outline_rounded,
                  size: 16, color: _kSecondary),
              const SizedBox(width: 8),
              Expanded(
                child: Text(
                  isSw ? 'Jinsi inavyofanya kazi' : 'How it works',
                  style: const TextStyle(
                    fontSize: 13,
                    fontWeight: FontWeight.w700,
                    color: _kPrimary,
                  ),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
              ),
            ],
          ),
          const SizedBox(height: 8),
          Text(
            isSw
                ? 'Idadi hii ni jumla ya mapato halisi kutoka kwa $labelSw zako zote katika kipindi kilichochaguliwa, baada ya 5% ya jukwaa na WHT. Mapato yana dirisha la siku 30 kabla ya kuingia kwenye mkoba wako (Lever 2).'
                : 'These totals are your net earnings across all of your $labelEn streams in the selected period, after the 5% platform fee and WHT. Each event has a 30-day clearing window before it lands in your wallet (Lever 2).',
            style: const TextStyle(
              fontSize: 12,
              color: _kSecondary,
              height: 1.5,
            ),
            maxLines: 5,
            overflow: TextOverflow.ellipsis,
          ),
        ],
      ),
    );
  }
}

// ─── Loading / error / utilities ───────────────────────────────────

class _LoadingList extends StatelessWidget {
  const _LoadingList();
  @override
  Widget build(BuildContext context) => const Center(
      child: Padding(
          padding: EdgeInsets.all(24),
          child: CircularProgressIndicator(color: _kPrimary)));
}

class _ErrorView extends StatelessWidget {
  final String message;
  final VoidCallback onRetry;
  final bool isSw;
  const _ErrorView({
    required this.message,
    required this.onRetry,
    required this.isSw,
  });
  @override
  Widget build(BuildContext context) => Center(
        child: Padding(
          padding: const EdgeInsets.all(24),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              const Icon(Icons.cloud_off_rounded, size: 36, color: _kSecondary),
              const SizedBox(height: 8),
              Text(message,
                  textAlign: TextAlign.center,
                  style: const TextStyle(color: _kSecondary, fontSize: 13)),
              const SizedBox(height: 12),
              FilledButton(
                  onPressed: onRetry,
                  style: FilledButton.styleFrom(backgroundColor: _kPrimary),
                  child: Text(isSw ? 'Jaribu tena' : 'Retry')),
            ],
          ),
        ),
      );
}

IconData _metricIcon(String metric) {
  switch (metric) {
    case 'live_view':              return Icons.visibility_outlined;
    case 'live_watch_minute':      return Icons.timer_outlined;
    case 'live_reaction':          return Icons.flash_on_rounded;
    case 'live_chat':              return Icons.chat_bubble_outline_rounded;
    case 'live_super_chat':        return Icons.star_rate_rounded;
    case 'live_gift':              return Icons.card_giftcard_rounded;
    case 'live_tip':               return Icons.attach_money_rounded;
    case 'follow_from_live':       return Icons.person_add_outlined;
    case 'subscribe_from_live':    return Icons.workspace_premium_outlined;
    case 'raid_in':                return Icons.move_to_inbox_rounded;
    case 'host_in':                return Icons.podcasts_rounded;
    case 'cohost_split':           return Icons.groups_outlined;
    case 'battle_winner_bonus':    return Icons.emoji_events_outlined;
    case 'live_purchase':          return Icons.shopping_bag_outlined;
    case 'vod_view':               return Icons.replay_rounded;
    default:                       return Icons.bolt_rounded;
  }
}

String _formatMonth(String iso, bool isSw) {
  if (iso.isEmpty) return isSw ? 'kipindi hiki' : 'this period';
  final dt = DateTime.tryParse(iso);
  if (dt == null) return iso;
  const enMonths = [
    'January', 'February', 'March', 'April', 'May', 'June',
    'July', 'August', 'September', 'October', 'November', 'December',
  ];
  const swMonths = [
    'Januari', 'Februari', 'Machi', 'Aprili', 'Mei', 'Juni',
    'Julai', 'Agosti', 'Septemba', 'Oktoba', 'Novemba', 'Desemba',
  ];
  final months = isSw ? swMonths : enMonths;
  return '${months[dt.month - 1]} ${dt.year}';
}

String _fmtAmount(double v) {
  // Always preserve the sign — totals can legitimately be negative
  // when system clamps + integrity penalties exceed positive
  // earnings for the period.
  final negative = v < 0;
  final abs = v.abs();
  String body;
  if (abs >= 1000000) {
    body = '${(abs / 1000000).toStringAsFixed(abs >= 10000000 ? 0 : 1)}M';
  } else if (abs >= 10000) {
    body = '${(abs / 1000).toStringAsFixed(0)}K';
  } else {
    final whole = abs.truncateToDouble() == abs;
    final s = whole ? abs.toStringAsFixed(0) : abs.toStringAsFixed(2);
    final parts = s.split('.');
    final intPart = parts[0];
    final reversed = intPart.split('').reversed.toList();
    final out = StringBuffer();
    for (var i = 0; i < reversed.length; i++) {
      if (i > 0 && i % 3 == 0) out.write(',');
      out.write(reversed[i]);
    }
    final formatted = out.toString().split('').reversed.join('');
    body = parts.length > 1 ? '$formatted.${parts[1]}' : formatted;
  }
  // U+2212 minus sign (matches the proper-minus convention already
  // used by the per-row tile in this file).
  return negative ? '−$body' : body;
}
