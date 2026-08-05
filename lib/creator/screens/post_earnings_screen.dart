// lib/creator/screens/post_earnings_screen.dart
//
// Detailed earnings breakdown for a single post — reachable from the
// sticky earnings strip on PostDetailScreen. Replaces the old bottom
// sheet so creators get a richer surface (hero number, performance
// pills, per-activity breakdown table, transparency explainer).
//
// Playbook compliance: monochrome (#1A1A1A / #666666 / #999999 /
// #FAFAFA / #FFFFFF), dark hero stat card per §105, pull-to-refresh
// (#1A1A1A), inline error/loading triumvirate, no SnackBars,
// MotionTokens for any animation, bilingual.

import 'package:flutter/material.dart';

import '../../l10n/app_strings_scope.dart';
import '../../models/post_models.dart';
import '../../services/post_service.dart';
import '../../widgets/tajiri_app_bar.dart';
import '../widgets/algorithm_transparency_card.dart';
import '../widgets/attribution_layers_card.dart';

const Color _kPrimary = Color(0xFF1A1A1A);
const Color _kSecondary = Color(0xFF666666);
const Color _kTertiary = Color(0xFF999999);
const Color _kBorder = Color(0xFFE5E5E5);
const Color _kSurface = Colors.white;
const Color _kBackground = Color(0xFFFAFAFA);
const Color _kIconBg = Color(0xFFF5F5F5);

class PostEarningsScreen extends StatefulWidget {
  final int postId;
  final int currentUserId;
  final PostEarningsResult? initialEarnings;
  final Post? post;

  const PostEarningsScreen({
    super.key,
    required this.postId,
    required this.currentUserId,
    this.initialEarnings,
    this.post,
  });

  @override
  State<PostEarningsScreen> createState() => _PostEarningsScreenState();
}

class _PostEarningsScreenState extends State<PostEarningsScreen> {
  final PostService _postService = PostService();

  PostEarningsResult? _earnings;
  PostInsightsResult? _insights;
  bool _loading = true;
  String? _error;

  @override
  void initState() {
    super.initState();
    if (widget.initialEarnings != null) {
      _earnings = widget.initialEarnings;
      _loading = false;
    }
    _refresh();
  }

  Future<void> _refresh() async {
    if (_earnings == null) {
      setState(() => _loading = true);
    }
    try {
      // L7 — fetch earnings and insights in parallel. Insights endpoint is
      // author-gated, so we pass the current user; if they're not the author
      // the result is null and we degrade to the earnings-only card.
      final results = await Future.wait<dynamic>([
        _postService.getPostEarnings(widget.postId),
        _postService.getPostInsights(widget.postId, currentUserId: widget.currentUserId),
      ]);
      if (!mounted) return;
      setState(() {
        _earnings = results[0] as PostEarningsResult;
        _insights = results[1] as PostInsightsResult?;
        _loading = false;
        _error = null;
      });
    } catch (e) {
      if (!mounted) return;
      setState(() {
        _loading = false;
        _error = _sanitizeError(e.toString());
      });
    }
  }

  String _sanitizeError(String raw) {
    final stripped =
        raw.startsWith('Exception: ') ? raw.substring(11) : raw;
    final isSw = AppStringsScope.of(context)?.isSwahili ?? false;
    if (stripped.contains('SocketException') ||
        stripped.contains('Failed host lookup')) {
      return isSw
          ? 'Hakuna intaneti. Hakikisha umeunganishwa.'
          : "Can't reach the server. Check your connection.";
    }
    if (stripped.contains('TimeoutException')) {
      return isSw ? 'Muda umeisha. Jaribu tena.' : 'Request timed out. Try again.';
    }
    return isSw ? 'Imeshindwa kupakia.' : 'Failed to load.';
  }

  @override
  Widget build(BuildContext context) {
    final s = AppStringsScope.of(context);
    final isSw = s?.isSwahili ?? false;

    return Scaffold(
      backgroundColor: _kBackground,
      appBar: TajiriAppBar(title: isSw ? 'Mapato' : 'Earnings'),
      body: SafeArea(
        child: _loading
            ? const Center(
                child: CircularProgressIndicator(
                  strokeWidth: 2,
                  color: _kPrimary,
                ),
              )
            : _error != null && _earnings == null
                ? _buildError(isSw)
                : RefreshIndicator(
                    color: _kPrimary,
                    onRefresh: _refresh,
                    child: ListView(
                      physics: const AlwaysScrollableScrollPhysics(),
                      padding:
                          const EdgeInsets.fromLTRB(16, 16, 16, 24),
                      children: [
                        _buildHeroCard(isSw),
                        const SizedBox(height: 20),
                        _SectionLabel(isSw ? 'UTENDAJI' : 'PERFORMANCE'),
                        const SizedBox(height: 8),
                        _buildPerformanceRow(isSw),
                        const SizedBox(height: 24),
                        _SectionLabel(isSw ? 'KWA NINI?' : 'WHY THIS PERFORMED'),
                        const SizedBox(height: 8),
                        _buildAlgorithmCard(),
                        const SizedBox(height: 24),
                        _SectionLabel(
                            isSw ? 'MAPATO KWA SHUGHULI' : 'EARNINGS BY ACTIVITY'),
                        const SizedBox(height: 8),
                        _buildBreakdownCard(isSw),
                        const SizedBox(height: 24),
                        _SectionLabel(isSw
                            ? 'TABAKA ZA ATTRIBUTION'
                            : 'ATTRIBUTION LAYERS'),
                        const SizedBox(height: 8),
                        AttributionLayersCard(isSw: isSw),
                        AttributionPropagationFooter(isSw: isSw),
                        const SizedBox(height: 24),
                        _SectionLabel(
                            isSw ? 'JINSI MAPATO HUHESABIWA' : 'HOW IT WORKS'),
                        const SizedBox(height: 8),
                        _buildExplainerCard(isSw),
                      ],
                    ),
                  ),
      ),
    );
  }

  // ── Hero card ────────────────────────────────────────────────────────

  Widget _buildHeroCard(bool isSw) {
    final e = _earnings!;
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
                child: const Icon(
                  Icons.payments_rounded,
                  color: Colors.white,
                  size: 18,
                ),
              ),
              const SizedBox(width: 10),
              Text(
                isSw ? 'Mapato yaliyokadiriwa' : 'Estimated earnings',
                style: TextStyle(
                  fontSize: 12,
                  color: Colors.white.withValues(alpha: 0.70),
                  fontWeight: FontWeight.w500,
                  letterSpacing: 0.2,
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          Row(
            crossAxisAlignment: CrossAxisAlignment.end,
            children: [
              Text(
                _fmtAmount(e.estimatedEarnings),
                style: const TextStyle(
                  fontSize: 36,
                  fontWeight: FontWeight.w800,
                  color: Colors.white,
                  height: 1.0,
                  letterSpacing: -0.6,
                  fontFeatures: [FontFeature.tabularFigures()],
                ),
              ),
              const SizedBox(width: 6),
              Padding(
                padding: const EdgeInsets.only(bottom: 4),
                child: Text(
                  e.currency,
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
                ? 'Inakadiriwa kulingana na utendaji'
                : 'Estimated based on engagement',
            style: TextStyle(
              fontSize: 12,
              color: Colors.white.withValues(alpha: 0.70),
            ),
          ),
        ],
      ),
    );
  }

  // ── Algorithm transparency (Lever 8) ─────────────────────────────────
  //
  // Renders [AlgorithmTransparencyCard] using the real insights payload
  // when /api/posts/{id}/insights returned, falling back to the
  // earnings-only view if the insights endpoint failed.

  Widget _buildAlgorithmCard() {
    final e = _earnings!;
    final ins = _insights;
    final s = AppStringsScope.of(context);
    final isSw = s?.isSwahili ?? false;

    if (ins == null) {
      // Fallback: derive what we can from the earnings breakdown.
      return AlgorithmTransparencyCard(
        reach: e.impressions,
        reachChangePercent: 0,
        topDriver: _deriveTopDriver(e),
        predictedEarnings: e.estimatedEarnings,
      );
    }

    // Average the three normalized score multipliers into one "community"
    // figure for display, keep tier separate. The card only takes two so
    // we present the most-actionable pair.
    final avgScoreMult = ((ins.communityMultiplier + ins.qualityMultiplier + ins.consistencyMultiplier) / 3.0);

    return AlgorithmTransparencyCard(
      reach: ins.reach,
      reachChangePercent: ins.reachChangePercent,
      topDriver: ins.topDriverLabel(isSwahili: isSw),
      watchTimeDecay: ins.watchTimeDecayLabel(isSwahili: isSw),
      predictedEarnings: ins.predictedEarnings,
      communityMultiplier: avgScoreMult,
      viralityMultiplier: ins.tierMultiplier,
    );
  }

  String? _deriveTopDriver(PostEarningsResult e) {
    final s = AppStringsScope.of(context);
    final isSw = s?.isSwahili ?? false;
    final pairs = <(String labelEn, String labelSw, double amount, int count)>[
      ('Views',   'Mionekano',  e.views.amount,    e.views.count),
      ('Likes',   'Mapenzi',    e.likes.amount,    e.likes.count),
      ('Comments','Maoni',      e.comments.amount, e.comments.count),
      ('Shares',  'Mishirikishaji', e.shares.amount, e.shares.count),
      ('Saves',   'Kuhifadhi',  e.saves.amount,    e.saves.count),
      ('Watch',   'Muda wa kuangalia', e.watchTime.amount, e.watchTime.count),
    ];
    pairs.sort((a, b) => b.$3.compareTo(a.$3));
    final top = pairs.first;
    if (top.$3 <= 0) return null;
    final label = isSw ? top.$2 : top.$1;
    return isSw
        ? '$label ndio chanzo kikuu cha mapato'
        : '$label is your top earnings driver';
  }

  // ── Performance row (twin pills) ─────────────────────────────────────

  Widget _buildPerformanceRow(bool isSw) {
    final e = _earnings!;
    return Row(
      children: [
        Expanded(
          child: _StatTile(
            label: isSw ? 'Mwoneko' : 'Reach',
            value: _fmtCount(e.impressions),
            icon: Icons.visibility_outlined,
          ),
        ),
        const SizedBox(width: 12),
        Expanded(
          child: _StatTile(
            label: isSw ? 'Mwingiliano' : 'Engagement',
            value: '${e.engagementRate.toStringAsFixed(1)}%',
            icon: Icons.bolt_rounded,
          ),
        ),
      ],
    );
  }

  // ── Breakdown card ───────────────────────────────────────────────────

  Widget _buildBreakdownCard(bool isSw) {
    final e = _earnings!;
    final rows = <_BreakdownRowSpec>[
      _BreakdownRowSpec(
        icon: Icons.visibility_outlined,
        label: isSw ? 'Mwoneko' : 'Views',
        metric: e.views,
        currency: e.currency,
      ),
      _BreakdownRowSpec(
        icon: Icons.favorite_outline_rounded,
        label: isSw ? 'Mapenzi' : 'Likes',
        metric: e.likes,
        currency: e.currency,
      ),
      _BreakdownRowSpec(
        icon: Icons.chat_bubble_outline_rounded,
        label: isSw ? 'Maoni' : 'Comments',
        metric: e.comments,
        currency: e.currency,
      ),
      _BreakdownRowSpec(
        icon: Icons.repeat_rounded,
        label: isSw ? 'Mishirikishaji' : 'Shares',
        metric: e.shares,
        currency: e.currency,
      ),
      _BreakdownRowSpec(
        icon: Icons.bookmark_outline_rounded,
        label: isSw ? 'Hifadhi' : 'Saves',
        metric: e.saves,
        currency: e.currency,
      ),
      _BreakdownRowSpec(
        icon: Icons.timer_outlined,
        label: isSw ? 'Muda wa kutazama' : 'Watch time',
        metric: e.watchTime,
        currency: e.currency,
        isWatchTime: true,
      ),
    ];

    return Container(
      decoration: BoxDecoration(
        color: _kSurface,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.04),
            blurRadius: 10,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Column(
        children: [
          for (var i = 0; i < rows.length; i++) ...[
            _BreakdownRow(spec: rows[i]),
            if (i < rows.length - 1)
              const Divider(
                height: 1,
                thickness: 1,
                color: _kBorder,
                indent: 16,
                endIndent: 16,
              ),
          ],
        ],
      ),
    );
  }

  // ── Explainer card ───────────────────────────────────────────────────

  Widget _buildExplainerCard(bool isSw) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: _kSurface,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.04),
            blurRadius: 10,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              const Icon(Icons.info_outline_rounded,
                  size: 18, color: _kSecondary),
              const SizedBox(width: 8),
              Text(
                isSw ? 'Vyanzo vya mapato' : 'Where earnings come from',
                style: const TextStyle(
                  fontSize: 14,
                  fontWeight: FontWeight.w600,
                  color: _kPrimary,
                ),
              ),
            ],
          ),
          const SizedBox(height: 8),
          Text(
            isSw
                ? 'Kila shughuli kwenye chapisho lako (mwoneko, kupenda, '
                    'maoni, mishirikishaji, kuhifadhi, muda wa kutazama) '
                    'huongeza mapato yako kwa kiwango maalum kilichowekwa '
                    'na TAJIRI. Kiwango huboreshwa mara kwa mara kulingana '
                    'na utendaji wa jukwaa.'
                : "Every interaction on your post (views, likes, comments, "
                    'shares, saves, watch time) earns a small share at a '
                    'rate set by TAJIRI. Rates are updated periodically '
                    'as the platform grows.',
            style: const TextStyle(
              fontSize: 13,
              color: _kSecondary,
              height: 1.45,
            ),
            maxLines: 8,
            overflow: TextOverflow.ellipsis,
          ),
          const SizedBox(height: 12),
          Text(
            isSw
                ? 'Mapato yanaonyeshwa kama makadirio. Malipo halisi yanafanyika kupitia Tajiri Pay.'
                : 'Figures are estimates. Actual payouts settle through Tajiri Pay.',
            style: const TextStyle(
              fontSize: 12,
              color: _kTertiary,
              fontStyle: FontStyle.italic,
            ),
            maxLines: 3,
            overflow: TextOverflow.ellipsis,
          ),
        ],
      ),
    );
  }

  // ── Error block ──────────────────────────────────────────────────────

  Widget _buildError(bool isSw) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(24),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.error_outline_rounded,
                size: 64, color: Colors.grey.shade300),
            const SizedBox(height: 16),
            Text(
              _error ?? '',
              style: const TextStyle(color: _kSecondary, fontSize: 14),
              textAlign: TextAlign.center,
              maxLines: 4,
              overflow: TextOverflow.ellipsis,
            ),
            const SizedBox(height: 16),
            OutlinedButton(
              onPressed: _refresh,
              style: OutlinedButton.styleFrom(
                foregroundColor: _kPrimary,
                side: const BorderSide(color: _kPrimary),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
                padding:
                    const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
              ),
              child: Text(isSw ? 'Jaribu tena' : 'Retry'),
            ),
          ],
        ),
      ),
    );
  }

  // ── Formatters ───────────────────────────────────────────────────────

  String _fmtAmount(double v) {
    if (v >= 1000000) {
      return '${(v / 1000000).toStringAsFixed(v >= 10000000 ? 0 : 1)}M';
    }
    if (v >= 10000) return '${(v / 1000).toStringAsFixed(0)}K';
    final whole = v.truncateToDouble() == v;
    final s = whole ? v.toStringAsFixed(0) : v.toStringAsFixed(2);
    final parts = s.split('.');
    final intPart = parts[0];
    final reversed = intPart.split('').reversed.toList();
    final out = StringBuffer();
    for (var i = 0; i < reversed.length; i++) {
      if (i > 0 && i % 3 == 0) out.write(',');
      out.write(reversed[i]);
    }
    final formatted = out.toString().split('').reversed.join('');
    return parts.length > 1 ? '$formatted.${parts[1]}' : formatted;
  }

  String _fmtCount(int n) {
    if (n >= 1000000) return '${(n / 1000000).toStringAsFixed(1)}M';
    if (n >= 1000) return '${(n / 1000).toStringAsFixed(1)}K';
    return n.toString();
  }
}

// ─── Subwidgets ─────────────────────────────────────────────────────────

class _SectionLabel extends StatelessWidget {
  final String label;
  const _SectionLabel(this.label);

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 4),
      child: Text(
        label,
        style: const TextStyle(
          fontSize: 11,
          fontWeight: FontWeight.w600,
          color: _kTertiary,
          letterSpacing: 0.6,
        ),
        maxLines: 1,
        overflow: TextOverflow.ellipsis,
      ),
    );
  }
}

class _StatTile extends StatelessWidget {
  final String label;
  final String value;
  final IconData icon;
  const _StatTile({required this.label, required this.value, required this.icon});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 14),
      decoration: BoxDecoration(
        color: _kSurface,
        borderRadius: BorderRadius.circular(14),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.04),
            blurRadius: 10,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisSize: MainAxisSize.min,
        children: [
          Row(
            children: [
              Icon(icon, size: 16, color: _kSecondary),
              const SizedBox(width: 6),
              Text(
                label,
                style: const TextStyle(
                  fontSize: 12,
                  fontWeight: FontWeight.w500,
                  color: _kSecondary,
                  letterSpacing: 0.2,
                ),
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
              ),
            ],
          ),
          const SizedBox(height: 8),
          Text(
            value,
            style: const TextStyle(
              fontSize: 22,
              fontWeight: FontWeight.w700,
              color: _kPrimary,
              height: 1.0,
              fontFeatures: [FontFeature.tabularFigures()],
            ),
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
          ),
        ],
      ),
    );
  }
}

class _BreakdownRowSpec {
  final IconData icon;
  final String label;
  final EarningsMetric metric;
  final String currency;
  final bool isWatchTime;
  const _BreakdownRowSpec({
    required this.icon,
    required this.label,
    required this.metric,
    required this.currency,
    this.isWatchTime = false,
  });
}

class _BreakdownRow extends StatelessWidget {
  final _BreakdownRowSpec spec;
  const _BreakdownRow({required this.spec});

  @override
  Widget build(BuildContext context) {
    final m = spec.metric;
    final countStr = spec.isWatchTime
        ? _fmtDuration(m.count)
        : _fmtCount(m.count);
    final amountStr = '${_fmtAmount(m.amount)} ${spec.currency}';
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
      child: Row(
        children: [
          Container(
            width: 36,
            height: 36,
            decoration: BoxDecoration(
              color: _kIconBg,
              borderRadius: BorderRadius.circular(10),
            ),
            child: Icon(spec.icon, size: 18, color: _kPrimary),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  spec.label,
                  style: const TextStyle(
                    fontSize: 14,
                    fontWeight: FontWeight.w600,
                    color: _kPrimary,
                  ),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
                const SizedBox(height: 2),
                Text(
                  countStr,
                  style: const TextStyle(fontSize: 12, color: _kSecondary),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
              ],
            ),
          ),
          const SizedBox(width: 8),
          Text(
            amountStr,
            style: const TextStyle(
              fontSize: 14,
              fontWeight: FontWeight.w700,
              color: _kPrimary,
              fontFeatures: [FontFeature.tabularFigures()],
            ),
          ),
        ],
      ),
    );
  }

  String _fmtAmount(double v) {
    if (v >= 1000000) {
      return '${(v / 1000000).toStringAsFixed(v >= 10000000 ? 0 : 1)}M';
    }
    if (v >= 10000) return '${(v / 1000).toStringAsFixed(0)}K';
    final whole = v.truncateToDouble() == v;
    final s = whole ? v.toStringAsFixed(0) : v.toStringAsFixed(2);
    final parts = s.split('.');
    final intPart = parts[0];
    final reversed = intPart.split('').reversed.toList();
    final out = StringBuffer();
    for (var i = 0; i < reversed.length; i++) {
      if (i > 0 && i % 3 == 0) out.write(',');
      out.write(reversed[i]);
    }
    final formatted = out.toString().split('').reversed.join('');
    return parts.length > 1 ? '$formatted.${parts[1]}' : formatted;
  }

  String _fmtCount(int n) {
    if (n >= 1000000) return '${(n / 1000000).toStringAsFixed(1)}M';
    if (n >= 1000) return '${(n / 1000).toStringAsFixed(1)}K';
    return n.toString();
  }

  String _fmtDuration(int seconds) {
    if (seconds < 60) return '${seconds}s';
    if (seconds < 3600) {
      final m = seconds ~/ 60;
      final s = seconds % 60;
      return s == 0 ? '${m}m' : '${m}m ${s}s';
    }
    final h = seconds ~/ 3600;
    final m = (seconds % 3600) ~/ 60;
    return m == 0 ? '${h}h' : '${h}h ${m}m';
  }
}
