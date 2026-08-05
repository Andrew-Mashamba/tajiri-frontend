// lib/creator/screens/photo_earnings_screen.dart
//
// Photo earnings — this user's actual earnings from every photo
// post for the current month, grouped by (metric × actor_role).
// Backed by GET /api/users/me/earnings/by-metric?post_type=photo,
// which JOINs earning_events to posts and restricts to
// posts.post_type = 'photo' (server-side filter, added 2026-05-04).
//
// Rows are bucketed into the three attribution layers from
// `docs/creators/strategy.md` §1:
//
//   1. DIRECT — actor_role = author
//   2. CONTEXT — actor_role ∈ {comment_author, reply_author,
//                              parent_thread, host}
//   3. DISTRIBUTION & DERIVATIVE — actor_role ∈ {sharer,
//                                  original_creator_royalty}
//
// Period selector: week / month / quarter / year (default month).
//
// Footer CTA opens the per-photo earnings list (drill into actual
// posts) via MyPostsEarningsListScreen?postTypeFilter=photo.
//
// Playbook compliance: monochrome, bilingual, 48dp targets,
// tabular figures, ellipsised, pull-to-refresh, empty/loading/error
// triumvirate, no SnackBars.

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import '../../l10n/app_strings_scope.dart';
import '../../services/local_storage_service.dart';
import '../../widgets/tajiri_app_bar.dart';
import '../models/creator_earnings_models.dart';
import '../models/post_type_earnings_taxonomy.dart';
import '../services/creator_earnings_service.dart';
import 'my_posts_earnings_list_screen.dart';

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

/// Generic strategy renderer keyed by post type. Reads its label,
/// icon, and per-row applicability from [kPostTypeEarningsConfigs]
/// + [isRowRelevantForPostType] in
/// `lib/creator/models/post_type_earnings_taxonomy.dart`.
class PostTypeEarningsScreen extends StatefulWidget {
  final int creatorId;
  final String postType;
  const PostTypeEarningsScreen({
    super.key,
    required this.creatorId,
    required this.postType,
  });

  @override
  State<PostTypeEarningsScreen> createState() => _PostTypeEarningsScreenState();
}

/// Backward-compat wrapper — the rest of the app still imports
/// PhotoEarningsScreen by name.
class PhotoEarningsScreen extends StatelessWidget {
  final int creatorId;
  const PhotoEarningsScreen({super.key, required this.creatorId});
  @override
  Widget build(BuildContext context) =>
      PostTypeEarningsScreen(creatorId: creatorId, postType: 'photo');
}

class _PostTypeEarningsScreenState extends State<PostTypeEarningsScreen> {
  final _service = CreatorEarningsService();

  _Period _period = _Period.month;
  MetricBreakdownResponse? _data;
  DerivativeKindResponse? _byKind;
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
      // Fetch (metric × actor_role) breakdown, derivative-kind
      // breakdown, AND per-multiplier contribution analysis in
      // parallel. The third feeds §XI.A bonus + §XI.B clamp rows.
      final wire = postTypeEarningsConfigFor(widget.postType)?.wire
          ?? widget.postType;
      final breakdownF = _service.getByMetric(
        userId: widget.creatorId,
        token: _token!,
        period: _period.wire,
        postType: wire,
      );
      final byKindF = _service.getByDerivativeKind(
        userId: widget.creatorId,
        token: _token!,
        period: _period.wire,
        postType: wire,
      );
      final byMultiplierF = _service.getByMultiplier(
        userId: widget.creatorId,
        token: _token!,
        period: _period.wire,
        postType: wire,
      );
      final fresh = await breakdownF;
      final byKind = await byKindF;
      final byMultiplier = await byMultiplierF;
      if (!mounted) return;
      setState(() {
        _data = fresh;
        _byKind = byKind;
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
    final cfg = postTypeEarningsConfigFor(widget.postType);
    final title = cfg == null
        ? (isSw ? '${widget.postType} · Mapato' : '${widget.postType} · Earnings')
        : (isSw ? '${cfg.labelSw} · Mapato' : '${cfg.labelEn} · Earnings');
    return Scaffold(
      backgroundColor: _kBackground,
      appBar: TajiriAppBar(
        title: title,
      ),
      body: SafeArea(
        child: RefreshIndicator(
          color: _kPrimary,
          onRefresh: _load,
          child: _loading && _data == null
              ? const _LoadingList()
              : _data == null && _error != null
                  ? _ErrorView(
                      message: _error!, onRetry: _load, isSw: isSw)
                  : _buildBody(isSw),
        ),
      ),
    );
  }

  Widget _buildBody(bool isSw) {
    final data = _data!;
    final agg = _PairAgg.fromRows(data.rows);
    final pt = widget.postType;

    // Filter helper — drops rows whose required capabilities the
    // current post type doesn't have. e.g. text posts hide
    // watch_second·author, photo posts hide dub_create·voice_actor.
    List<_Pair> filterPairs(List<_Pair> all) => all
        .where((p) => isRowRelevantForPostType(
              postType: pt,
              metric: p.metric,
              actorRole: p.actorRole,
            ))
        .toList(growable: false);

    Widget? section(_SectionMeta meta, List<_Pair> pairs, {Widget? trailing}) {
      final relevant = filterPairs(pairs);
      // If a section has no relevant rows AND no trailing widget,
      // hide it entirely so we don't show empty section labels.
      if (relevant.isEmpty && trailing == null) return null;
      return Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _SectionLabel(meta.label(isSw)),
          const SizedBox(height: 8),
          if (relevant.isNotEmpty) _PairTable(pairs: relevant, agg: agg, isSw: isSw),
          if (trailing != null) ...[
            if (relevant.isNotEmpty) const SizedBox(height: 8),
            trailing,
          ],
        ],
      );
    }

    // Gather section widgets, skipping any that are nullable + null.
    Widget? maybeSection5 = shouldShowClipperSection(pt)
        ? section(_kSection5, _kSection5Pairs)
        : null;
    Widget? maybeSection6 = shouldShowLocalizationSection(pt)
        ? section(_kSection6, _kSection6Pairs)
        : null;
    Widget? maybeSection10 = shouldShowCommerceSection(pt)
        ? section(_kSection10, _kSection10Pairs)
        : null;
    final contribRoles = contributorRolesForPostType(pt);
    Widget? maybeSection8 = shouldShowContributorRoles(pt)
        ? section(
            _kSection8,
            _kSection8Pairs,
            trailing: _ContributorRoleTable(isSw: isSw, roles: contribRoles),
          )
        : null;

    // Catchall: any (metric × actor_role) returned by the backend
    // that isn't in any of the 91 canonical pairs. Prevents silent
    // value drops if the backend ships new metrics or a different
    // stream (e.g. fan_funding subscriptions) lands under a post_type
    // filter.
    final knownPairs = <String>{
      ..._kSection1Pairs.map((p) => p.key),
      ..._kSection2Pairs.map((p) => p.key),
      ..._kSection3Pairs.map((p) => p.key),
      ..._kSection4Pairs.map((p) => p.key),
      ..._kSection5Pairs.map((p) => p.key),
      ..._kSection6Pairs.map((p) => p.key),
      ..._kSection7Pairs.map((p) => p.key),
      ..._kSection8Pairs.map((p) => p.key),
      ..._kSection9Pairs.map((p) => p.key),
      ..._kSection10Pairs.map((p) => p.key),
      ..._kSection12Pairs.map((p) => p.key),
      ..._kSection13Pairs.map((p) => p.key),
    };
    final unknownPairs = <_Pair>[
      for (final entry in agg.map.entries)
        if (!knownPairs.contains(entry.key) && entry.value.netTsh.abs() > 0)
          _Pair(
            entry.key.split('|').first,
            entry.key.split('|').elementAt(1),
          ),
    ]..sort((a, b) => a.key.compareTo(b.key));
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
      _Hero(data: data, isSw: isSw, postType: pt),
      const SizedBox(height: 14),
      _PeriodPills(
        selected: _period, onChanged: _setPeriod, isSw: isSw),
      const SizedBox(height: 18),
      section(_kSection1, _kSection1Pairs),
      const SizedBox(height: 18),
      section(_kSection2, _kSection2Pairs),
      const SizedBox(height: 18),
      section(_kSection3, _kSection3Pairs),
      const SizedBox(height: 18),
      section(
        _kSection4,
        _kSection4Pairs,
        trailing: _DerivativeKindTable(byKind: _byKind, isSw: isSw),
      ),
      const SizedBox(height: 18),
      maybeSection5,
      if (maybeSection5 != null) const SizedBox(height: 18),
      maybeSection6,
      if (maybeSection6 != null) const SizedBox(height: 18),
      section(_kSection7, _kSection7Pairs),
      const SizedBox(height: 18),
      maybeSection8,
      if (maybeSection8 != null) const SizedBox(height: 18),
      section(_kSection9, _kSection9Pairs),
      const SizedBox(height: 18),
      maybeSection10,
      if (maybeSection10 != null) const SizedBox(height: 18),
    ].whereType<Widget>().toList();

    return ListView(
      physics: const AlwaysScrollableScrollPhysics(),
      padding: const EdgeInsets.fromLTRB(16, 16, 16, 24),
      children: [
        ...body,
        // §XI — 3 explicit sub-tables + 1 catchall, all sourced from
        // /by-multiplier. Catchall renders any backend multiplier not
        // listed in A/B/C so nothing drops silently.
        Builder(builder: (_) {
          final returned = <String>{
            for (final r in _byMultiplier?.rows ?? const []) r.multiplier,
          };
          final unknown = returned.difference(_kSection11AllListed).toList()
            ..sort();
          return Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              _SectionLabel(_kSection11.label(isSw)),
              const SizedBox(height: 8),
              _SubLabel(isSw ? 'Bonasi' : 'Bonuses'),
              const SizedBox(height: 6),
              _MultiplierTable(
                multipliers: _kSection11BonusMultipliers,
                contributions: _byMultiplier,
                isSw: isSw,
              ),
              const SizedBox(height: 12),
              _SubLabel(isSw
                  ? 'Adhabu za ubora wa mwingiliano'
                  : 'Engagement-quality penalties'),
              const SizedBox(height: 6),
              _MultiplierTable(
                multipliers: _kSection11EngagementPenaltyMultipliers,
                contributions: _byMultiplier,
                isSw: isSw,
              ),
              const SizedBox(height: 12),
              _SubLabel(isSw
                  ? 'Punguzo za uaminifu, udanganyifu, usalama na AI'
                  : 'Trust / fraud / safety / AI clamps'),
              const SizedBox(height: 6),
              _MultiplierTable(
                multipliers: _kSection11SystemClampMultipliers,
                contributions: _byMultiplier,
                isSw: isSw,
              ),
              if (unknown.isNotEmpty) ...[
                const SizedBox(height: 12),
                _SubLabel(isSw ? 'Mengineyo' : 'Other (uncategorised)'),
                const SizedBox(height: 6),
                _MultiplierTable(
                  multipliers: unknown,
                  contributions: _byMultiplier,
                  isSw: isSw,
                ),
              ],
            ],
          );
        }),
        const SizedBox(height: 18),
        ...[
          section(_kSection12, _kSection12Pairs),
          if (filterPairs(_kSection12Pairs).isNotEmpty)
            const SizedBox(height: 18),
          section(_kSection13, _kSection13Pairs),
          if (catchallSection != null) const SizedBox(height: 18),
          catchallSection,
        ].whereType<Widget>(),
        const SizedBox(height: 22),
        _ViewPostsCTA(
          creatorId: widget.creatorId,
          postType: pt,
          isSw: isSw,
        ),
        const SizedBox(height: 16),
        _HowItWorks(isSw: isSw, postType: pt),
      ],
    );
  }
}

/// A canonical (metric × actor_role) pair listed on this page.
class _Pair {
  final String metric;
  final String actorRole;
  const _Pair(this.metric, this.actorRole);
  String get key => '$metric|$actorRole';
}

// ─── Strategy-doc taxonomy ───────────────────────────────────────────
// Source: docs/creators/posts/strategies/posts.md
// 75 canonical metric × actor_role pairs across 13 sections.
// Every row always renders — empty rows show TZS 0 until the
// corresponding event fires on the backend.

/// §I — Direct Creation (rows 1-17). You authored the photo.
const List<_Pair> _kSection1Pairs = [
  _Pair('view', 'author'),
  _Pair('watch_second', 'author'),
  _Pair('reaction', 'author'),
  _Pair('comment', 'author'),
  _Pair('reply', 'author'),
  _Pair('save', 'author'),
  _Pair('share', 'author'),
  _Pair('follow_from_post', 'author'),
  _Pair('subscribe_from_post', 'author'),
  _Pair('profile_visit_from_post', 'author'),
  _Pair('return_session_credit', 'author'),
  _Pair('retention_day_n', 'author'),
  _Pair('external_link_click', 'author'),
  _Pair('purchase_assist', 'author'),
  _Pair('screenshot', 'author'),
  _Pair('revisit_post', 'author'),
  _Pair('copy_text', 'author'),
];

/// §II — Conversation & Context (rows 18-25).
const List<_Pair> _kSection2Pairs = [
  _Pair('comment_reaction', 'comment_author'),
  _Pair('reply', 'comment_author'),
  _Pair('reply_reaction', 'reply_author'),
  _Pair('comment_reaction', 'host'),
  _Pair('reply_reaction', 'host'),
  _Pair('thread_depth_bonus', 'host'),
  _Pair('unique_participant_bonus', 'host'),
  _Pair('creator_reply_bonus', 'author'),
];

/// §III — Distribution & Discovery (rows 26-33).
const List<_Pair> _kSection3Pairs = [
  _Pair('view', 'sharer'),
  _Pair('reaction', 'sharer'),
  _Pair('share', 'sharer'),
  _Pair('follow_from_share', 'sharer'),
  _Pair('subscribe_from_share', 'sharer'),
  _Pair('profile_visit_from_share', 'sharer'),
  _Pair('distribution_retention_credit', 'sharer'),
  _Pair('high_quality_share_bonus', 'sharer'),
];

/// §IV — Derivative Content (row 34, single metric). The 13
/// relationship_types live in the derivative-kind table below.
const List<_Pair> _kSection4Pairs = [
  _Pair('derivative_royalty', 'original_author'),
];

/// §V — Clipper / Editor Economy (rows 48-53).
const List<_Pair> _kSection5Pairs = [
  _Pair('clip_create', 'clipper'),
  _Pair('clip_view', 'clipper'),
  _Pair('clip_conversion', 'clipper'),
  _Pair('subtitle_addition', 'editor'),
  _Pair('format_adaptation', 'editor'),
  _Pair('highlight_selection', 'editor'),
];

/// §VI — Localization & Translation (rows 54-58).
const List<_Pair> _kSection6Pairs = [
  _Pair('translation_create', 'translator'),
  _Pair('translated_view', 'translator'),
  _Pair('translated_conversion', 'translator'),
  _Pair('dub_create', 'voice_actor'),
  _Pair('subtitle_localization', 'translator'),
];

/// §VII — Curation & Collection (rows 59-63).
const List<_Pair> _kSection7Pairs = [
  _Pair('collection_add', 'curator'),
  _Pair('collection_view', 'curator'),
  _Pair('collection_follow', 'curator'),
  _Pair('collection_conversion', 'curator'),
  _Pair('thematic_feed_bonus', 'curator'),
];

/// §VIII — Collaboration (row 64, single metric). The 8 contributor
/// roles live in the contributor-roles table below.
const List<_Pair> _kSection8Pairs = [
  _Pair('collaborator_split', 'contributor'),
];

/// §IX — Educational & Utility (rows 73-76).
const List<_Pair> _kSection9Pairs = [
  _Pair('reference_revisit', 'author'),
  _Pair('instructional_completion', 'author'),
  _Pair('save_to_learning_collection', 'author'),
  _Pair('external_reference_click', 'author'),
];

/// §X — Commerce & Intent (rows 77-80).
const List<_Pair> _kSection10Pairs = [
  _Pair('product_expand', 'author'),
  _Pair('wishlist_add', 'author'),
  _Pair('affiliate_conversion', 'author'),
  _Pair('local_business_conversion', 'author'),
];

/// §XI — Platform Health & Quality.
///
/// All three sub-tables are sourced from `/by-multiplier`; rows are
/// keyed by **multiplier name** (the canonical key the backend
/// emits in `earning_events.multipliers`). Lists below match the
/// authoritative emitters in:
///   • app/Services/Earnings/MultiplierEngine.php  (engine-level)
///   • app/Services/Earnings/Filters/QualityFilter.php
///   • app/Services/Earnings/Filters/TrustFilter.php
///   • app/Services/Earnings/Filters/FraudFilter.php
///   • app/Services/Earnings/Filters/SafetyFilter.php
///
/// A 4th catchall sub-table renders any multiplier returned by the
/// backend that isn't explicitly listed below — prevents silent
/// drops if the backend adds new multipliers.

/// §XI.A Bonuses — multipliers that boost earnings on positive
/// signals. All entries here have a value range ≥ 1.0 (or are
/// bidirectional and mostly-positive in practice, like
/// `watch_completion` 0.5..2.5).
const List<String> _kSection11BonusMultipliers = [
  'mwanzo_boost',          // 2.0 during launch window, else null
  'watch_completion',      // 0.5..2.5 (bidirectional — listed here
                           // because positive completion is the
                           // common case; row tile auto-flips icon)
  'tier_boost',            // 1.05 for partners, else null
  'streak',                // 1.10 for active creators, else null
  'actor_trust_expert',    // 1.5 for verified experts
  'originality_bonus',     // 1.20 for original posts (framework §XIII)
  'evergreen_bonus',       // 1.15 for posts older than 7d still active
  'trust_score_bonus',     // graduated from TrustScoreService
  'healthy_discussion_bonus',
  'cross_ideology_bonus',
  'expert_participation_bonus',
  'fact_checked_bonus',
  'community_health_bonus',
];

/// §XI.B Engagement-quality penalties (≤ 1.0) — viewer-driven from
/// the negative-attribution framework's negative_events table.
const List<String> _kSection11EngagementPenaltyMultipliers = [
  'rapid_hide_penalty',
  'report_penalty',
  'bounce_penalty',
  'mute_after_view_penalty',
  'spam_ring_detection_penalty',
  'coordinated_bot_ring_penalty',
];

/// §XI.C Trust / fraud / safety / AI clamps (≤ 1.0) — system-driven
/// from TrustFilter, FraudFilter, SafetyFilter, and AI-spam clamps in
/// QualityFilter. Also includes engine-level clamps that range 0..1:
///   • `originality` (1.0 original / 0.7 derivative_substantial /
///                    0.4 derivative_minimal / 0.0 reused)
///     — distinct from `originality_bonus` (§XI.A); this is a
///     base-score clamp on derivative content.
///   • `discovery_mode` (0.70 when post is in discovery push).
const List<String> _kSection11SystemClampMultipliers = [
  'originality',
  'discovery_mode',
  'actor_trust_age',
  'actor_authenticity',
  'actor_network_reputation',
  'fraud_risk',
  'human_probability',
  'device_cluster',
  'diminishing_returns',
  'synthetic_spam_detection',
  'ai_content_flood_penalty',
  'mass_generation_penalty',
  'ragebait_penalty',
  'content_safety_mature',
  'content_safety_suggestive',
];

/// Union of all explicitly-listed multipliers — used to compute the
/// catchall (any backend multiplier NOT in this set).
final Set<String> _kSection11AllListed = {
  ..._kSection11BonusMultipliers,
  ..._kSection11EngagementPenaltyMultipliers,
  ..._kSection11SystemClampMultipliers,
};

/// §XII — AI & Synthetic Media (rows 89-92).
const List<_Pair> _kSection12Pairs = [
  _Pair('ai_style_usage', 'original_author'),
  _Pair('synthetic_voice_usage', 'original_author'),
  _Pair('ai_training_contribution', 'original_author'),
  _Pair('ai_assisted_remix', 'remixer'),
];

/// §XIII — Community Contribution (rows 93-96).
const List<_Pair> _kSection13Pairs = [
  _Pair('mentorship_attribution', 'mentor'),
  _Pair('collaboration_origin_credit', 'connector'),
  _Pair('moderation_quality_bonus', 'moderator'),
  _Pair('community_retention_bonus', 'host'),
];

/// 13 canonical relationship_types — strategy doc §IV (rows 35-47).
const List<String> _kRelationshipTypes = [
  'original',
  'quote',
  'stitch',
  'reply_post',
  'remix',
  'duet',
  'clip',
  'template_derivative',
  'meme_lineage',
  'ai_generated_variant',
  'localized_remix',
  'translation',
  'dub',
];

/// Per-type contributor roles now live in
/// `lib/creator/models/post_type_earnings_taxonomy.dart` —
/// `contributorRolesForPostType()`.

/// Bilingual section header pulled from docs/creators/posts/strategies/posts.md.
class _SectionMeta {
  final String roman;
  final String labelEn;
  final String labelSw;
  const _SectionMeta(this.roman, this.labelEn, this.labelSw);
  String label(bool isSw) => '$roman. ${isSw ? labelSw : labelEn}';
}

const _SectionMeta _kSection1 = _SectionMeta(
    'I', 'DIRECT CREATION', 'UTENGENEZAJI WA MOJA KWA MOJA');
const _SectionMeta _kSection2 = _SectionMeta(
    'II', 'CONVERSATION & CONTEXT', 'MAZUNGUMZO NA MUKTADHA');
const _SectionMeta _kSection3 = _SectionMeta(
    'III', 'DISTRIBUTION & DISCOVERY', 'USAMBAZAJI NA UGUNDUZI');
const _SectionMeta _kSection4 =
    _SectionMeta('IV', 'DERIVATIVE CONTENT', 'YALIYOMO YA DERIVATIVE');
const _SectionMeta _kSection5 = _SectionMeta(
    'V', 'CLIPPER / EDITOR ECONOMY', 'UCHAGUZI / UHARIRI');
const _SectionMeta _kSection6 = _SectionMeta(
    'VI', 'LOCALIZATION & TRANSLATION', 'KUTAFSIRI NA MAZINGIRA');
const _SectionMeta _kSection7 =
    _SectionMeta('VII', 'CURATION & COLLECTION', 'UKUSANYAJI');
const _SectionMeta _kSection8 =
    _SectionMeta('VIII', 'COLLABORATION', 'USHIRIKIANO');
const _SectionMeta _kSection9 = _SectionMeta(
    'IX', 'EDUCATIONAL & UTILITY', 'ELIMU NA MATUMIZI');
const _SectionMeta _kSection10 =
    _SectionMeta('X', 'COMMERCE & INTENT', 'BIASHARA NA NIA');
const _SectionMeta _kSection11 = _SectionMeta(
    'XI', 'PLATFORM HEALTH & QUALITY', 'AFYA YA JUKWAA');
const _SectionMeta _kSection12 =
    _SectionMeta('XII', 'AI & SYNTHETIC MEDIA', 'AI NA VYOMBO VYA AI');
const _SectionMeta _kSection13 =
    _SectionMeta('XIII', 'COMMUNITY CONTRIBUTION', 'MCHANGO WA JAMII');

/// Aggregate net + event count per (metric × actor_role), summed
/// across all stream variants in the backend response.
class _PairAgg {
  final Map<String, ({double netTsh, int events, int rawCount})> map;
  const _PairAgg(this.map);

  factory _PairAgg.fromRows(List<MetricBreakdownRow> rows) {
    final out =
        <String, ({double netTsh, int events, int rawCount})>{};
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

// ─── Hero ──────────────────────────────────────────────────────────────

class _Hero extends StatelessWidget {
  final MetricBreakdownResponse data;
  final bool isSw;
  final String postType;
  const _Hero({
    required this.data,
    required this.isSw,
    required this.postType,
  });

  @override
  Widget build(BuildContext context) {
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
                width: 36,
                height: 36,
                decoration: BoxDecoration(
                  color: Colors.white.withValues(alpha: 0.10),
                  borderRadius: BorderRadius.circular(10),
                ),
                alignment: Alignment.center,
                child: Icon(
                  postTypeEarningsConfigFor(postType)?.icon
                      ?? Icons.image_outlined,
                  color: Colors.white,
                  size: 18,
                ),
              ),
              const SizedBox(width: 10),
              Expanded(
                child: Text(
                  isSw
                      ? '${postTypeEarningsConfigFor(postType)?.labelSw ?? postType} · ${_formatMonth(data.periodStart, true)}'
                      : '${postTypeEarningsConfigFor(postType)?.labelEn ?? postType} · ${_formatMonth(data.periodStart, false)}',
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
                _fmtAmount(data.totalNetTsh),
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
                ? '${data.totalEventCount} matukio · halisi (baada ya ada)'
                : '${data.totalEventCount} events · net (after fees)',
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

// ─── Period selector ──────────────────────────────────────────────────

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
            child: _PeriodPill(
              label: _Period.values[i].label(isSw),
              isSelected: _Period.values[i] == selected,
              onTap: () => onChanged(_Period.values[i]),
            ),
          ),
          if (i < _Period.values.length - 1) const SizedBox(width: 6),
        ],
      ],
    );
  }
}

class _PeriodPill extends StatelessWidget {
  final String label;
  final bool isSelected;
  final VoidCallback onTap;
  const _PeriodPill({
    required this.label,
    required this.isSelected,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return InkWell(
      borderRadius: BorderRadius.circular(20),
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.symmetric(vertical: 8),
        decoration: BoxDecoration(
          color: isSelected ? _kPrimary : _kSurface,
          borderRadius: BorderRadius.circular(20),
          border: Border.all(color: isSelected ? _kPrimary : _kBorder),
        ),
        alignment: Alignment.center,
        child: Text(
          label,
          style: TextStyle(
            fontSize: 12,
            fontWeight: FontWeight.w600,
            color: isSelected ? Colors.white : _kPrimary,
          ),
          maxLines: 1,
          overflow: TextOverflow.ellipsis,
        ),
      ),
    );
  }
}

// ─── Section label / table / row ─────────────────────────────────────

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

/// Smaller label for sub-groups within a section (e.g. §XI's
/// Bonuses / Engagement-quality penalties / Content-safety & AI).
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
    final hasData = data.netTsh > 0 || data.events > 0;
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
                  '${metricLabel(pair.metric, isSw)} · ${actorRoleLabel(pair.actorRole, isSw)}',
                  style: const TextStyle(
                    fontSize: 11,
                    color: _kTertiary,
                  ),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
              ],
            ),
          ),
          const SizedBox(width: 10),
          Column(
            crossAxisAlignment: CrossAxisAlignment.end,
            children: [
              Text(
                'TZS ${_fmtAmount(data.netTsh)}',
                style: TextStyle(
                  fontSize: 14,
                  fontWeight: FontWeight.w800,
                  color: hasData ? _kPrimary : _kTertiary,
                  fontFeatures: const [FontFeature.tabularFigures()],
                ),
              ),
              const SizedBox(height: 2),
              Text(
                isSw
                    ? '${data.events} matukio'
                    : '${data.events} events',
                style: const TextStyle(
                  fontSize: 10,
                  color: _kTertiary,
                  fontFeatures: [FontFeature.tabularFigures()],
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}

// ─── Multiplier-contribution table (§XI.A bonuses + §XI.B clamps) ──

/// Reads from `MultiplierContributionResponse` (the
/// `/by-multiplier` endpoint). Each pair's `metric` is looked up
/// in the response; the row shows TZS contribution + event count
/// + average multiplier value. Bonus multipliers (>1.0) yield
/// positive contributions; clamping multipliers (<1.0) yield
/// negative contributions (rendered with leading "−").
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
            width: 36,
            height: 36,
            decoration: BoxDecoration(
              color: _kIconBg,
              borderRadius: BorderRadius.circular(10),
            ),
            alignment: Alignment.center,
            child: Icon(
              isClamp
                  ? Icons.trending_down_rounded
                  : Icons.trending_up_rounded,
              size: 18,
              color: _kPrimary,
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
                const SizedBox(height: 2),
                Text(
                  c == null || c.eventCount == 0
                      ? metricLabel(multiplier, isSw)
                      : (isSw
                          ? '${metricLabel(multiplier, isSw)} · ${c.avgValue.toStringAsFixed(2)}× wastani · ${c.eventCount} matukio'
                          : '${metricLabel(multiplier, isSw)} · ${c.avgValue.toStringAsFixed(2)}× avg · ${c.eventCount} events'),
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

// ─── Footer CTA ──────────────────────────────────────────────────────

/// Renders earnings split by `posts.relationship_type`. Always shows
/// the 13 canonical kinds — empty kinds render as TZS 0.
/// Strategy doc §IV (rows 35-47).
class _DerivativeKindTable extends StatelessWidget {
  final DerivativeKindResponse? byKind;
  final bool isSw;
  const _DerivativeKindTable({required this.byKind, required this.isSw});

  @override
  Widget build(BuildContext context) {
    final map = <String, DerivativeKindRow>{
      for (final r in byKind?.rows ?? const <DerivativeKindRow>[]) r.kind: r,
    };
    return Container(
      decoration: BoxDecoration(
        color: _kSurface,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: _kBorder),
      ),
      child: Column(
        children: [
          for (var i = 0; i < _kRelationshipTypes.length; i++) ...[
            _DerivativeKindRowTile(
              kind: _kRelationshipTypes[i],
              row: map[_kRelationshipTypes[i]],
              isSw: isSw,
            ),
            if (i < _kRelationshipTypes.length - 1)
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

/// Renders the 8 canonical contributor_roles for collaboration
/// posts — strategy doc §VIII (rows 65-72). Per-role earnings will
/// populate when the collaborator_split mechanism ships; for now
/// each row reads as a placeholder taxonomy entry.
class _ContributorRoleTable extends StatelessWidget {
  final bool isSw;
  final List<String> roles;
  const _ContributorRoleTable({required this.isSw, required this.roles});

  @override
  Widget build(BuildContext context) {
    if (roles.isEmpty) return const SizedBox.shrink();
    return Container(
      decoration: BoxDecoration(
        color: _kSurface,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: _kBorder),
      ),
      child: Column(
        children: [
          for (var i = 0; i < roles.length; i++) ...[
            Padding(
              padding: const EdgeInsets.symmetric(
                  horizontal: 14, vertical: 12),
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
                    child: const Icon(Icons.person_outline_rounded,
                        size: 18, color: _kPrimary),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          roles[i],
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
                          contributorRoleLabel(roles[i], isSw),
                          style: const TextStyle(
                            fontSize: 11,
                            color: _kTertiary,
                          ),
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(width: 10),
                  const Text(
                    'TZS 0',
                    style: TextStyle(
                      fontSize: 14,
                      fontWeight: FontWeight.w800,
                      color: _kTertiary,
                      fontFeatures: [FontFeature.tabularFigures()],
                    ),
                  ),
                ],
              ),
            ),
            if (i < roles.length - 1)
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

class _DerivativeKindRowTile extends StatelessWidget {
  final String kind;
  final DerivativeKindRow? row;
  final bool isSw;

  const _DerivativeKindRowTile({
    required this.kind,
    required this.row,
    required this.isSw,
  });

  @override
  Widget build(BuildContext context) {
    final hasData = row != null && row!.netTsh > 0;
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
            child: Icon(_kindIcon(kind), size: 18, color: _kPrimary),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  relationshipTypeLabel(kind, isSw),
                  style: const TextStyle(
                    fontSize: 13,
                    fontWeight: FontWeight.w700,
                    color: _kPrimary,
                  ),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
                const SizedBox(height: 2),
                Text(
                  row == null
                      ? (isSw ? 'Hakuna posts' : 'No posts')
                      : (isSw
                          ? '${row!.postCount} posts · ${row!.eventCount} matukio'
                          : '${row!.postCount} posts · ${row!.eventCount} events'),
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
            'TZS ${_fmtAmount(row?.netTsh ?? 0)}',
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

  IconData _kindIcon(String kind) => switch (kind) {
        'original' => Icons.article_outlined,
        'quote' => Icons.format_quote_rounded,
        'stitch' => Icons.cut_rounded,
        'reply_post' => Icons.reply_rounded,
        'remix' => Icons.auto_awesome_outlined,
        'duet' => Icons.people_outline_rounded,
        'shared' => Icons.repeat_rounded,
        _ => Icons.article_outlined,
      };
}

class _ViewPostsCTA extends StatelessWidget {
  final int creatorId;
  final String postType;
  final bool isSw;
  const _ViewPostsCTA({
    required this.creatorId,
    required this.postType,
    required this.isSw,
  });

  @override
  Widget build(BuildContext context) {
    final cfg = postTypeEarningsConfigFor(postType);
    final labelEn = cfg?.labelEn.toLowerCase() ?? postType;
    final labelSw = cfg?.labelSw ?? postType;
    return Material(
      color: _kPrimary,
      borderRadius: BorderRadius.circular(12),
      clipBehavior: Clip.antiAlias,
      child: InkWell(
        onTap: () {
          HapticFeedback.selectionClick();
          Navigator.push(
            context,
            MaterialPageRoute(
              builder: (_) => MyPostsEarningsListScreen(
                creatorId: creatorId,
                postTypeFilter: postType,
              ),
            ),
          );
        },
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
          child: Row(
            children: [
              Icon(cfg?.icon ?? Icons.photo_library_outlined,
                  size: 18, color: Colors.white),
              const SizedBox(width: 10),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      isSw
                          ? 'Tazama $labelSw zako moja moja'
                          : 'View your $labelEn individually',
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
                          ? 'Per-post: kila post na mapato yake halisi'
                          : 'Per-post: each post and its actual earnings',
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

// ─── How it works ────────────────────────────────────────────────────

class _HowItWorks extends StatelessWidget {
  final bool isSw;
  final String postType;
  const _HowItWorks({required this.isSw, required this.postType});

  @override
  Widget build(BuildContext context) {
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
                    fontWeight: FontWeight.w600,
                    color: _kPrimary,
                  ),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
              ),
            ],
          ),
          const SizedBox(height: 8),
          Builder(builder: (_) {
            final cfg = postTypeEarningsConfigFor(postType);
            final labelEn = cfg?.labelEn.toLowerCase() ?? '$postType';
            final labelSw = cfg?.labelSw ?? '$postType';
            return Text(
              isSw
                  ? 'Idadi hii ni jumla ya mapato halisi kutoka kwa $labelSw zako zote katika kipindi kilichochaguliwa, baada ya ada za jukwaa na WHT. Mapato ya kuchakata yana dirisha la siku 30 kabla ya kuingia kwenye mkoba wako.'
                  : 'These totals are your net earnings across all of your $labelEn posts in the selected period, after platform fees and WHT. Each event has a 30-day clearing window before it lands in your wallet.',
              style: const TextStyle(
                fontSize: 12,
                color: _kSecondary,
                height: 1.5,
              ),
              maxLines: 5,
              overflow: TextOverflow.ellipsis,
            );
          }),
        ],
      ),
    );
  }
}

// ─── Sentinels ────────────────────────────────────────────────────────

class _LoadingList extends StatelessWidget {
  const _LoadingList();
  @override
  Widget build(BuildContext context) {
    return ListView(
      physics: const AlwaysScrollableScrollPhysics(),
      children: const [
        SizedBox(height: 120),
        Center(
          child: SizedBox(
            width: 24,
            height: 24,
            child: CircularProgressIndicator(
                strokeWidth: 2, color: _kPrimary),
          ),
        ),
      ],
    );
  }
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
  Widget build(BuildContext context) {
    return ListView(
      physics: const AlwaysScrollableScrollPhysics(),
      padding: const EdgeInsets.all(24),
      children: [
        const SizedBox(height: 60),
        Icon(Icons.error_outline_rounded,
            size: 64, color: Colors.grey.shade300),
        const SizedBox(height: 16),
        Text(
          message,
          style: const TextStyle(color: _kSecondary, fontSize: 14),
          textAlign: TextAlign.center,
          maxLines: 4,
          overflow: TextOverflow.ellipsis,
        ),
        const SizedBox(height: 16),
        Center(
          child: OutlinedButton(
            onPressed: onRetry,
            style: OutlinedButton.styleFrom(
              foregroundColor: _kPrimary,
              side: const BorderSide(color: _kPrimary),
              shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12)),
              padding: const EdgeInsets.symmetric(
                  horizontal: 24, vertical: 12),
            ),
            child: Text(isSw ? 'Jaribu tena' : 'Retry'),
          ),
        ),
      ],
    );
  }
}

// ─── Helpers ─────────────────────────────────────────────────────────

IconData _metricIcon(String metric) {
  return switch (metric) {
    'view' => Icons.visibility_outlined,
    'watch_second' => Icons.timer_outlined,
    'reaction' => Icons.favorite_outline_rounded,
    'live_reaction' => Icons.flash_on_rounded,
    'comment' => Icons.chat_bubble_outline_rounded,
    'reply' => Icons.reply_rounded,
    'share' => Icons.share_outlined,
    'save' => Icons.bookmark_outline_rounded,
    'comment_reaction' => Icons.add_reaction_outlined,
    'follow_from_post' => Icons.person_add_outlined,
    'subscribe_from_post' => Icons.workspace_premium_outlined,
    'derivative_royalty' => Icons.copy_all_outlined,
    _ => Icons.bolt_rounded,
  };
}

String _formatMonth(String iso, bool isSw) {
  if (iso.isEmpty) return isSw ? 'mwezi huu' : 'this month';
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
  return negative ? '−$body' : body;
}
