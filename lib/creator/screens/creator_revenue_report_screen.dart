// lib/creator/screens/creator_revenue_report_screen.dart
//
// Creator Revenue Report — implements the 15-section spec added to
// docs/creators/strategy.md (2026-05-04). The strategy frames a
// good revenue report as one that answers 5 questions instantly:
//
//   1. How much did I earn?
//   2. Where did it come from?
//   3. Which content generated it?
//   4. Who amplified it?
//   5. What should I do next?
//
// Sections backed by existing data (rendered live):
//   §1 Revenue summary, §3 Top earning posts CTA,
//   §4 Engagement event revenue, §8 Conversation revenue tree,
//   §13 Wallet & payouts (partial).
//
// Sections requiring backend work (rendered as phase-tagged
// "Coming in Pn" cards linking to docs/creators/STRATEGY_ALIGNMENT.md):
//   §2 Revenue by source (true layer mix),
//   §5 Derivative royalties, §6 Top downstream creators,
//   §7 Share attribution, §9 Conversion funnel,
//   §10 Integrity adjustments, §11 Geographic revenue,
//   §12 Revenue timeline, §14 AI insights, §15 CSV export.
//
// Playbook compliance: monochrome (#1A1A1A / #666666 / #999999 /
// #FAFAFA / #FFFFFF), bilingual, tabular figures on numerics,
// pull-to-refresh, empty/loading/error triumvirate, 48dp targets,
// no SnackBars.

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import '../../l10n/app_strings_scope.dart';
import '../../services/local_storage_service.dart';
import '../../widgets/tajiri_app_bar.dart';
import '../models/creator_earnings_models.dart';
import '../services/creator_earnings_service.dart';
import '../widgets/fund_period_card.dart';
import 'creator_earnings_dashboard_screen.dart';
import 'my_posts_earnings_list_screen.dart';

const Color _kPrimary = Color(0xFF1A1A1A);
const Color _kSecondary = Color(0xFF666666);
const Color _kTertiary = Color(0xFF999999);
const Color _kBorder = Color(0xFFE5E5E5);
const Color _kSurface = Colors.white;
const Color _kBackground = Color(0xFFFAFAFA);
const Color _kIconBg = Color(0xFFF5F5F5);
const Color _kBadgeBg = Color(0xFFFFF8E1);
const Color _kBadgeFg = Color(0xFF8A4B00);

enum _ReportPeriod { week, month, quarter, year }

extension _ReportPeriodWire on _ReportPeriod {
  String get wire => name;
  String label(bool isSw) => switch (this) {
        _ReportPeriod.week => isSw ? 'Wiki' : 'Week',
        _ReportPeriod.month => isSw ? 'Mwezi' : 'Month',
        _ReportPeriod.quarter => isSw ? 'Robo' : 'Quarter',
        _ReportPeriod.year => isSw ? 'Mwaka' : 'Year',
      };
}

class CreatorRevenueReportScreen extends StatefulWidget {
  final int creatorId;

  const CreatorRevenueReportScreen({super.key, required this.creatorId});

  @override
  State<CreatorRevenueReportScreen> createState() =>
      _CreatorRevenueReportScreenState();
}

class _CreatorRevenueReportScreenState
    extends State<CreatorRevenueReportScreen> {
  final _service = CreatorEarningsService();

  _ReportPeriod _period = _ReportPeriod.month;
  CreatorEarningsDashboard? _dashboard;
  MetricBreakdownResponse? _metricBreakdown;
  DerivativeKindResponse? _byKind;
  List<DownstreamCreator> _downstream = const [];
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
      final dashboardF = _service.getDashboard(
        userId: widget.creatorId,
        token: _token!,
      );
      final breakdownF = _service.getByMetric(
        userId: widget.creatorId,
        token: _token!,
        period: _period.wire,
      );
      final byKindF = _service.getByDerivativeKind(
        userId: widget.creatorId,
        token: _token!,
        period: _period.wire,
      );
      final downstreamF = _service.getDownstreamCreators(
        userId: widget.creatorId,
        token: _token!,
        period: _period.wire,
        limit: 5,
      );
      final dashboard = await dashboardF;
      final breakdown = await breakdownF;
      final byKind = await byKindF;
      final downstream = await downstreamF;
      if (!mounted) return;
      setState(() {
        _dashboard = dashboard;
        _metricBreakdown = breakdown;
        _byKind = byKind;
        _downstream = downstream;
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

  void _setPeriod(_ReportPeriod p) {
    if (p == _period) return;
    HapticFeedback.selectionClick();
    setState(() => _period = p);
    _load();
  }

  @override
  Widget build(BuildContext context) {
    final isSw = AppStringsScope.of(context)?.isSwahili ?? false;
    return Scaffold(
      backgroundColor: _kBackground,
      appBar: TajiriAppBar(
        title: isSw ? 'Ripoti ya mapato' : 'Revenue Report',
      ),
      body: SafeArea(
        child: RefreshIndicator(
          color: _kPrimary,
          onRefresh: _load,
          child: _loading && _dashboard == null
              ? const _LoadingList()
              : _dashboard == null && _error != null
                  ? _ErrorView(
                      message: _error!, onRetry: _load, isSw: isSw)
                  : _buildBody(isSw),
        ),
      ),
    );
  }

  Widget _buildBody(bool isSw) {
    final d = _dashboard!;
    final mb = _metricBreakdown!;
    return ListView(
      physics: const AlwaysScrollableScrollPhysics(),
      padding: const EdgeInsets.fromLTRB(16, 16, 16, 32),
      children: [
        _ReportHeader(periodMeta: mb, isSw: isSw),
        const SizedBox(height: 14),
        EarningsTierBadge(
          tier: d.tier,
          isMwanzoActive: d.isMwanzoActive,
          mwanzoExpiresAt: d.mwanzoExpiresAt,
          isSw: isSw,
        ),
        const SizedBox(height: 14),
        if (d.currentPeriod != null) ...[
          FundPeriodCard(period: d.currentPeriod!, isSw: isSw),
          const SizedBox(height: 14),
        ],
        _PeriodPills(
          selected: _period,
          onChanged: _setPeriod,
          isSw: isSw,
        ),
        const SizedBox(height: 18),
        _Section1RevenueSummary(
            dashboard: d, breakdown: mb, isSw: isSw),
        const SizedBox(height: 18),
        _Section2RevenueBySource(
            dashboard: d, breakdown: mb, isSw: isSw),
        const SizedBox(height: 18),
        _Section3TopEarningPosts(
            creatorId: widget.creatorId, isSw: isSw),
        const SizedBox(height: 18),
        _Section4EngagementEventRevenue(breakdown: mb, isSw: isSw),
        const SizedBox(height: 18),
        _Section5DerivativeRoyalties(byKind: _byKind, isSw: isSw),
        const SizedBox(height: 18),
        _Section6TopDownstreamCreators(creators: _downstream, isSw: isSw),
        const SizedBox(height: 18),
        _Section7ShareAttribution(isSw: isSw),
        const SizedBox(height: 18),
        _Section8ConversationTree(breakdown: mb, isSw: isSw),
        const SizedBox(height: 18),
        _Section9ConversionFunnel(isSw: isSw),
        const SizedBox(height: 18),
        _Section10IntegrityAdjustments(breakdown: mb, isSw: isSw),
        const SizedBox(height: 18),
        _Section11GeoRevenue(isSw: isSw),
        const SizedBox(height: 18),
        _Section12RevenueTimeline(isSw: isSw),
        const SizedBox(height: 18),
        _Section13WalletPayouts(dashboard: d, isSw: isSw),
        const SizedBox(height: 18),
        _Section14AIInsights(isSw: isSw),
        const SizedBox(height: 18),
        _Section15CSVExport(isSw: isSw),
        const SizedBox(height: 24),
        _OtherViewsFooter(creatorId: widget.creatorId, isSw: isSw),
      ],
    );
  }
}

// ─── Header ───────────────────────────────────────────────────────────

class _ReportHeader extends StatelessWidget {
  final MetricBreakdownResponse periodMeta;
  final bool isSw;

  const _ReportHeader({required this.periodMeta, required this.isSw});

  @override
  Widget build(BuildContext context) {
    final range = _formatRange(
        periodMeta.periodStart, periodMeta.periodEnd, isSw);
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
                child: const Icon(Icons.receipt_long_rounded,
                    color: Colors.white, size: 18),
              ),
              const SizedBox(width: 10),
              Expanded(
                child: Text(
                  isSw
                      ? 'Ripoti kamili ya mapato'
                      : 'Full revenue report',
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
          Text(
            range,
            style: const TextStyle(
              fontSize: 20,
              fontWeight: FontWeight.w800,
              color: Colors.white,
              letterSpacing: -0.2,
            ),
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
          ),
          const SizedBox(height: 6),
          Text(
            isSw
                ? 'Sehemu 15 · Imeundwa kwa watengenezaji'
                : '15 sections · Built for creators',
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
  final _ReportPeriod selected;
  final ValueChanged<_ReportPeriod> onChanged;
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
        for (var i = 0; i < _ReportPeriod.values.length; i++) ...[
          Expanded(
            child: _PeriodPill(
              label: _ReportPeriod.values[i].label(isSw),
              isSelected: _ReportPeriod.values[i] == selected,
              onTap: () => onChanged(_ReportPeriod.values[i]),
            ),
          ),
          if (i < _ReportPeriod.values.length - 1)
            const SizedBox(width: 6),
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

// ─── Reusable section shell ───────────────────────────────────────────

class _ReportSection extends StatelessWidget {
  final int number;
  final String title;
  final String? subtitle;
  final Widget child;

  const _ReportSection({
    required this.number,
    required this.title,
    this.subtitle,
    required this.child,
  });

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 4),
          child: Row(
            children: [
              Container(
                width: 22,
                height: 22,
                decoration: BoxDecoration(
                  color: _kPrimary,
                  borderRadius: BorderRadius.circular(6),
                ),
                alignment: Alignment.center,
                child: Text(
                  '$number',
                  style: const TextStyle(
                    fontSize: 11,
                    fontWeight: FontWeight.w800,
                    color: Colors.white,
                    fontFeatures: [FontFeature.tabularFigures()],
                  ),
                ),
              ),
              const SizedBox(width: 10),
              Expanded(
                child: Text(
                  title,
                  style: const TextStyle(
                    fontSize: 15,
                    fontWeight: FontWeight.w800,
                    color: _kPrimary,
                    letterSpacing: -0.1,
                  ),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
              ),
            ],
          ),
        ),
        if (subtitle != null) ...[
          const SizedBox(height: 4),
          Padding(
            padding: const EdgeInsets.only(left: 36, right: 4),
            child: Text(
              subtitle!,
              style: const TextStyle(
                fontSize: 11, color: _kTertiary, height: 1.4),
              maxLines: 2,
              overflow: TextOverflow.ellipsis,
            ),
          ),
        ],
        const SizedBox(height: 10),
        child,
      ],
    );
  }
}

// ─── Coming-soon card (deferred sections) ────────────────────────────

class _ComingSoonCard extends StatelessWidget {
  /// Phase from STRATEGY_ALIGNMENT.md roadmap, e.g. "P1", "P3".
  final String phase;
  final String reason;
  final String detail;

  const _ComingSoonCard({
    required this.phase,
    required this.reason,
    required this.detail,
  });

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
              Container(
                padding: const EdgeInsets.symmetric(
                    horizontal: 8, vertical: 3),
                decoration: BoxDecoration(
                  color: _kBadgeBg,
                  borderRadius: BorderRadius.circular(20),
                ),
                child: Text(
                  phase,
                  style: const TextStyle(
                    fontSize: 10,
                    fontWeight: FontWeight.w800,
                    color: _kBadgeFg,
                    letterSpacing: 0.4,
                  ),
                ),
              ),
              const SizedBox(width: 8),
              Expanded(
                child: Text(
                  reason,
                  style: const TextStyle(
                    fontSize: 12,
                    fontWeight: FontWeight.w700,
                    color: _kPrimary,
                  ),
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                ),
              ),
            ],
          ),
          const SizedBox(height: 8),
          Text(
            detail,
            style: const TextStyle(
              fontSize: 12,
              color: _kSecondary,
              height: 1.45,
            ),
            maxLines: 4,
            overflow: TextOverflow.ellipsis,
          ),
        ],
      ),
    );
  }
}

// ─── Reusable rendered table ─────────────────────────────────────────

class _ReportTable extends StatelessWidget {
  /// Each row: [label, value1, value2, …]. Non-label cells are
  /// right-aligned with tabular figures.
  final List<List<String>> rows;
  final List<String>? headers;
  final List<int>? boldRows;

  const _ReportTable({
    required this.rows,
    this.headers,
    this.boldRows,
  });

  @override
  Widget build(BuildContext context) {
    if (rows.isEmpty) {
      return Container(
        padding: const EdgeInsets.all(14),
        decoration: BoxDecoration(
          color: _kSurface,
          borderRadius: BorderRadius.circular(14),
          border: Border.all(color: _kBorder),
        ),
        child: const Text(
          '—',
          style: TextStyle(fontSize: 12, color: _kTertiary),
          maxLines: 1,
        ),
      );
    }
    final colCount = rows.first.length;
    return Container(
      decoration: BoxDecoration(
        color: _kSurface,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: _kBorder),
      ),
      child: Column(
        children: [
          if (headers != null && headers!.length == colCount) ...[
            Padding(
              padding: const EdgeInsets.fromLTRB(14, 12, 14, 8),
              child: Row(
                children: [
                  for (var i = 0; i < headers!.length; i++)
                    Expanded(
                      flex: i == 0 ? 3 : 2,
                      child: Text(
                        headers![i],
                        style: const TextStyle(
                          fontSize: 10,
                          color: _kTertiary,
                          fontWeight: FontWeight.w700,
                          letterSpacing: 0.6,
                        ),
                        textAlign: i == 0 ? TextAlign.start : TextAlign.end,
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                    ),
                ],
              ),
            ),
            const Divider(
                height: 1, color: _kBorder, indent: 14, endIndent: 14),
          ],
          for (var r = 0; r < rows.length; r++) ...[
            Padding(
              padding: const EdgeInsets.symmetric(
                  horizontal: 14, vertical: 12),
              child: Row(
                children: [
                  for (var c = 0; c < rows[r].length; c++)
                    Expanded(
                      flex: c == 0 ? 3 : 2,
                      child: Text(
                        rows[r][c],
                        style: TextStyle(
                          fontSize: 13,
                          fontWeight: (boldRows?.contains(r) ?? false)
                              ? FontWeight.w800
                              : FontWeight.w500,
                          color: _kPrimary,
                          fontFeatures: c > 0
                              ? const [FontFeature.tabularFigures()]
                              : null,
                        ),
                        textAlign: c == 0 ? TextAlign.start : TextAlign.end,
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                    ),
                ],
              ),
            ),
            if (r < rows.length - 1)
              const Divider(
                  height: 1, color: _kBorder, indent: 14, endIndent: 14),
          ],
        ],
      ),
    );
  }
}

// ─── §1 Revenue Summary ───────────────────────────────────────────────

class _Section1RevenueSummary extends StatelessWidget {
  final CreatorEarningsDashboard dashboard;
  final MetricBreakdownResponse breakdown;
  final bool isSw;

  const _Section1RevenueSummary({
    required this.dashboard,
    required this.breakdown,
    required this.isSw,
  });

  @override
  Widget build(BuildContext context) {
    final gross = breakdown.totalGrossTsh;
    final net = breakdown.totalNetTsh;
    final platformFeePlusWht = (gross - net).clamp(0, gross).toDouble();
    final pending = dashboard.totalPendingTsh;
    final paid = (dashboard.totalClearedTsh - pending).clamp(0.0, double.infinity);

    return _ReportSection(
      number: 1,
      title: isSw ? 'Muhtasari wa mapato' : 'Revenue summary',
      subtitle:
          isSw ? 'Jumla, ada na malipo' : 'Totals, fees, and payouts',
      child: _ReportTable(
        boldRows: const [3],
        rows: [
          [isSw ? 'Mapato ghafi' : 'Gross revenue', _money(gross)],
          [
            isSw ? 'Ada za jukwaa + WHT' : 'Platform fee + WHT',
            '−${_money(platformFeePlusWht)}'
          ],
          [
            isSw ? 'Hifadhi ya udanganyifu' : 'Fraud / risk reserve',
            '—'
          ],
          [
            isSw ? 'Mapato halisi' : 'Net creator earnings',
            _money(net)
          ],
          [
            isSw ? 'Inangoja kuisha' : 'Pending clearance',
            _money(pending)
          ],
          [isSw ? 'Yameshalipwa' : 'Paid out', _money(paid)],
        ],
      ),
    );
  }
}

// ─── §2 Revenue by Source ────────────────────────────────────────────

class _Section2RevenueBySource extends StatelessWidget {
  final CreatorEarningsDashboard dashboard;
  final MetricBreakdownResponse breakdown;
  final bool isSw;

  const _Section2RevenueBySource({
    required this.dashboard,
    required this.breakdown,
    required this.isSw,
  });

  @override
  Widget build(BuildContext context) {
    // Compute layer mix client-side from MetricBreakdownResponse rows.
    // True strategy-aligned categories. This is an approximation until
    // the /by-layer endpoint ships (ALIGNMENT §10a).
    final byLayer = <PayoutLayer, double>{
      PayoutLayer.direct: 0,
      PayoutLayer.context: 0,
      PayoutLayer.derivative: 0,
      PayoutLayer.distribution: 0,
    };
    for (final r in breakdown.rows) {
      byLayer[r.layer] = (byLayer[r.layer] ?? 0) + r.netTsh;
    }
    final total = byLayer.values.fold<double>(0, (a, b) => a + b);

    return _ReportSection(
      number: 2,
      title: isSw ? 'Mapato kwa chanzo' : 'Revenue by source',
      subtitle: isSw
          ? 'Mgawanyo wa kweli wa attribution layer'
          : 'True attribution-layer split',
      child: total <= 0
          ? const _ComingSoonCard(
              phase: 'P0',
              reason: 'No earnings yet',
              detail:
                  'Once you start earning, the seven strategy categories — direct engagement, watch-time, comment-tree, distribution credits, derivative royalties, follower conversions, subscription discoveries — will populate here.',
            )
          : _ReportTable(
              boldRows: [byLayer.length],
              rows: [
                for (final entry in byLayer.entries)
                  if (entry.value > 0)
                    [entry.key.label(isSw), _money(entry.value)],
                [isSw ? 'JUMLA' : 'TOTAL', _money(total)],
              ],
            ),
    );
  }
}

// ─── §3 Top Earning Posts ────────────────────────────────────────────

class _Section3TopEarningPosts extends StatelessWidget {
  final int creatorId;
  final bool isSw;

  const _Section3TopEarningPosts({
    required this.creatorId,
    required this.isSw,
  });

  @override
  Widget build(BuildContext context) {
    return _ReportSection(
      number: 3,
      title: isSw ? 'Posts zinazoongoza' : 'Top earning posts',
      subtitle: isSw
          ? 'Bofya post yoyote kuona uchanganuzi kamili'
          : 'Tap any post to see the full breakdown',
      child: Material(
        color: _kSurface,
        borderRadius: BorderRadius.circular(14),
        clipBehavior: Clip.antiAlias,
        child: InkWell(
          onTap: () {
            HapticFeedback.selectionClick();
            Navigator.push(
              context,
              MaterialPageRoute(
                builder: (_) =>
                    MyPostsEarningsListScreen(creatorId: creatorId),
              ),
            );
          },
          child: Container(
            decoration: BoxDecoration(
              border: Border.all(color: _kBorder),
              borderRadius: BorderRadius.circular(14),
            ),
            padding: const EdgeInsets.all(16),
            child: Row(
              children: [
                Container(
                  width: 40,
                  height: 40,
                  decoration: BoxDecoration(
                    color: _kIconBg,
                    borderRadius: BorderRadius.circular(10),
                  ),
                  alignment: Alignment.center,
                  child: const Icon(Icons.format_list_numbered_rounded,
                      size: 20, color: _kPrimary),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        isSw
                            ? 'Tazama posts zinazoongoza'
                            : 'View top earning posts',
                        style: const TextStyle(
                          fontSize: 14,
                          fontWeight: FontWeight.w700,
                          color: _kPrimary,
                        ),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                      const SizedBox(height: 2),
                      Text(
                        isSw
                            ? 'Ukurasa wenye orodha kamili na mapato kwa kila tendo'
                            : 'Full ranked list with per-action earnings',
                        style: const TextStyle(
                            fontSize: 12, color: _kSecondary),
                        maxLines: 2,
                        overflow: TextOverflow.ellipsis,
                      ),
                    ],
                  ),
                ),
                const SizedBox(width: 8),
                const Icon(Icons.chevron_right_rounded,
                    size: 20, color: _kTertiary),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

// ─── §4 Engagement Event Revenue ─────────────────────────────────────

class _Section4EngagementEventRevenue extends StatelessWidget {
  final MetricBreakdownResponse breakdown;
  final bool isSw;

  const _Section4EngagementEventRevenue({
    required this.breakdown,
    required this.isSw,
  });

  @override
  Widget build(BuildContext context) {
    // Roll up rows by metric (collapsing across actor_role).
    final byMetric = <String, ({int events, int rawCount, double net})>{};
    for (final r in breakdown.rows) {
      if (r.metric == 'period_settlement') continue;
      final cur = byMetric[r.metric] ??
          (events: 0, rawCount: 0, net: 0.0);
      byMetric[r.metric] = (
        events: cur.events + r.eventCount,
        rawCount: cur.rawCount + r.rawCountTotal,
        net: cur.net + r.netTsh,
      );
    }
    final entries = byMetric.entries.toList()
      ..sort((a, b) => b.value.net.compareTo(a.value.net));

    return _ReportSection(
      number: 4,
      title: isSw
          ? 'Mapato kwa aina ya tendo'
          : 'Engagement event revenue',
      subtitle: isSw
          ? 'Jinsi kila tendo lilivyoleta mapato'
          : 'How each event type generated revenue',
      child: entries.isEmpty
          ? const _ComingSoonCard(
              phase: 'P0',
              reason: 'No events in this period',
              detail:
                  'Views, watch-seconds, reactions, comments, replies, shares, bookmarks and conversions populate here once they fire.',
            )
          : _ReportTable(
              headers: [
                isSw ? 'Tendo' : 'Event',
                isSw ? 'Idadi' : 'Count',
                isSw ? 'Mapato' : 'Revenue',
              ],
              rows: [
                for (final e in entries)
                  [
                    _metricLabel(e.key, isSw),
                    _fmtCount(e.value.rawCount > 0
                        ? e.value.rawCount
                        : e.value.events),
                    _money(e.value.net),
                  ],
              ],
            ),
    );
  }
}

// ─── §5 Derivative Royalties ─────────────────────────────────────────

class _Section5DerivativeRoyalties extends StatelessWidget {
  final DerivativeKindResponse? byKind;
  final bool isSw;
  const _Section5DerivativeRoyalties({required this.byKind, required this.isSw});

  static const _derivativeKinds = ['quote', 'stitch', 'reply_post', 'remix', 'duet'];

  @override
  Widget build(BuildContext context) {
    final map = <String, DerivativeKindRow>{
      for (final r in byKind?.rows ?? const <DerivativeKindRow>[]) r.kind: r,
    };
    final hasAny = _derivativeKinds.any(
        (k) => (map[k]?.netTsh ?? 0) > 0 || (map[k]?.postCount ?? 0) > 0);

    return _ReportSection(
      number: 5,
      title:
          isSw ? 'Royalty za derivative' : 'Derivative royalty earnings',
      subtitle: isSw
          ? '"Watu wanaojenga juu ya kazi yangu hunilipa."'
          : '"People building on my content makes me money."',
      child: !hasAny
          ? _ReportTable(
              boldRows: [_derivativeKinds.length],
              rows: [
                for (final k in _derivativeKinds)
                  [relationshipTypeLabel(k, isSw), _money(0)],
                [isSw ? 'JUMLA' : 'TOTAL', _money(0)],
              ],
            )
          : _ReportTable(
              boldRows: [_derivativeKinds.length],
              headers: [
                isSw ? 'Aina' : 'Kind',
                isSw ? 'Posts' : 'Posts',
                isSw ? 'Royalty' : 'Royalty',
              ],
              rows: [
                for (final k in _derivativeKinds)
                  [
                    relationshipTypeLabel(k, isSw),
                    '${map[k]?.postCount ?? 0}',
                    _money(map[k]?.netTsh ?? 0),
                  ],
                [
                  isSw ? 'JUMLA' : 'TOTAL',
                  '${_derivativeKinds.fold<int>(0, (a, k) => a + (map[k]?.postCount ?? 0))}',
                  _money(_derivativeKinds.fold<double>(
                      0, (a, k) => a + (map[k]?.netTsh ?? 0))),
                ],
              ],
            ),
    );
  }
}

// ─── §6 Top Downstream Creators ──────────────────────────────────────

class _Section6TopDownstreamCreators extends StatelessWidget {
  final List<DownstreamCreator> creators;
  final bool isSw;
  const _Section6TopDownstreamCreators({
    required this.creators,
    required this.isSw,
  });

  @override
  Widget build(BuildContext context) {
    return _ReportSection(
      number: 6,
      title: isSw
          ? 'Watengenezaji wanaokuendeleza'
          : 'Top downstream creators',
      subtitle: isSw
          ? 'Watengenezaji walioleta royalty kwako'
          : 'Creators whose derivatives earned you royalties',
      child: creators.isEmpty
          ? Container(
              padding: const EdgeInsets.all(14),
              decoration: BoxDecoration(
                color: _kSurface,
                borderRadius: BorderRadius.circular(14),
                border: Border.all(color: _kBorder),
              ),
              child: Text(
                isSw
                    ? 'Hakuna royalty kutoka kwa watengenezaji wengine bado.'
                    : 'No royalties from other creators yet.',
                style: const TextStyle(fontSize: 12, color: _kSecondary),
                maxLines: 2,
                overflow: TextOverflow.ellipsis,
              ),
            )
          : _ReportTable(
              headers: [
                isSw ? 'Mtengenezaji' : 'Creator',
                isSw ? 'Posts' : 'Derivatives',
                isSw ? 'Royalty' : 'Your royalty',
              ],
              rows: [
                for (final c in creators)
                  [
                    '@${c.username ?? c.displayName}',
                    '${c.derivativePostCount}',
                    _money(c.yourRoyaltyTsh),
                  ],
              ],
            ),
    );
  }
}

// ─── §7 Share Attribution ───────────────────────────────────────────

class _Section7ShareAttribution extends StatelessWidget {
  final bool isSw;
  const _Section7ShareAttribution({required this.isSw});

  @override
  Widget build(BuildContext context) {
    return _ReportSection(
      number: 7,
      title: isSw
          ? 'Attribution ya usambazaji'
          : 'Share attribution report',
      subtitle: isSw
          ? 'Ni wapi traffic yako ilitoka'
          : 'Where your traffic came from',
      child: _ComingSoonCard(
        phase: 'P3',
        reason: isSw
            ? 'Inahitaji uga wa share_source kwenye matukio'
            : 'Requires share_source field on engagement events',
        detail: isSw
            ? 'Direct feed / external share / DM / community thread itakuwa kategoria. Mwoneko, mapato yaliyozalishwa na CPM kwa kila chanzo zitaonekana hapa.'
            : 'Direct feed / external share / internal repost / DM / community thread will be tracked as separate sources. Views, revenue generated, and CPM per source will surface here.',
      ),
    );
  }
}

// ─── §8 Conversation Revenue Tree ────────────────────────────────────

class _Section8ConversationTree extends StatelessWidget {
  final MetricBreakdownResponse breakdown;
  final bool isSw;

  const _Section8ConversationTree({
    required this.breakdown,
    required this.isSw,
  });

  @override
  Widget build(BuildContext context) {
    // Strategy buckets:
    //   Direct comments       = comment events on YOUR posts (actor_role=author)
    //   Replies on comments   = reply events on YOUR comments (actor_role=comment_author)
    //   Replies on replies    = reply events on YOUR replies  (actor_role=reply_author)
    //   Reactions on comments = comment_reaction (actor_role=comment_author)
    //   Reactions on replies  = comment_reaction (actor_role=reply_author)
    double direct = 0, replyOnComment = 0, replyOnReply = 0;
    double reactionOnComment = 0, reactionOnReply = 0;
    for (final r in breakdown.rows) {
      if (r.metric == 'comment' && r.actorRole == 'author') {
        direct += r.netTsh;
      } else if (r.metric == 'reply' &&
          r.actorRole == 'comment_author') {
        replyOnComment += r.netTsh;
      } else if (r.metric == 'reply' && r.actorRole == 'reply_author') {
        replyOnReply += r.netTsh;
      } else if (r.metric == 'comment_reaction' &&
          r.actorRole == 'comment_author') {
        reactionOnComment += r.netTsh;
      } else if (r.metric == 'comment_reaction' &&
          r.actorRole == 'reply_author') {
        reactionOnReply += r.netTsh;
      }
    }
    final total = direct +
        replyOnComment +
        replyOnReply +
        reactionOnComment +
        reactionOnReply;

    return _ReportSection(
      number: 8,
      title:
          isSw ? 'Mti wa mazungumzo' : 'Conversation revenue tree',
      subtitle:
          isSw ? 'Mazungumzo ni mali' : 'Discussions are assets',
      child: total <= 0
          ? const _ComingSoonCard(
              phase: 'P0',
              reason: 'No conversation earnings yet',
              detail:
                  'Comments and replies on your posts (and on your own comments) will populate this section as the engagement engine fires.',
            )
          : _ReportTable(
              rows: [
                [
                  isSw ? 'Maoni ya moja kwa moja' : 'Direct comments',
                  _money(direct)
                ],
                [
                  isSw ? 'Majibu kwenye maoni' : 'Replies on comments',
                  _money(replyOnComment)
                ],
                [
                  isSw ? 'Majibu kwenye majibu' : 'Replies on replies',
                  _money(replyOnReply)
                ],
                [
                  isSw
                      ? 'Reactions kwenye maoni'
                      : 'Reactions on comments',
                  _money(reactionOnComment)
                ],
                [
                  isSw ? 'Reactions kwenye majibu' : 'Reactions on replies',
                  _money(reactionOnReply)
                ],
              ],
            ),
    );
  }
}

// ─── §9 Conversion Funnel ────────────────────────────────────────────

class _Section9ConversionFunnel extends StatelessWidget {
  final bool isSw;
  const _Section9ConversionFunnel({required this.isSw});

  @override
  Widget build(BuildContext context) {
    return _ReportSection(
      number: 9,
      title: isSw ? 'Funnel ya watazamaji' : 'Audience conversion funnel',
      subtitle: isSw
          ? 'Impressions → Views → Followers → Subscribers'
          : 'Impressions → Views → Followers → Subscribers',
      child: _ComingSoonCard(
        phase: 'P3',
        reason: isSw
            ? 'Inahitaji impressions + endpoint ya funnel'
            : 'Requires impressions + funnel rollup endpoint',
        detail: isSw
            ? 'Itaonyesha kiwango cha mageuzi kutoka impression hadi subscriber, ikiwa ni pamoja na percentage halisi ili kupima utendaji wa post.'
            : 'Surfaces the impression → view → engaged → follower → subscriber conversion rate per post and overall, so you can spot which content type converts best.',
      ),
    );
  }
}

// ─── §10 Integrity Adjustments ───────────────────────────────────────

class _Section10IntegrityAdjustments extends StatelessWidget {
  final MetricBreakdownResponse breakdown;
  final bool isSw;
  const _Section10IntegrityAdjustments({
    required this.breakdown,
    required this.isSw,
  });

  /// 5 transparency categories per integrity framework §XIV. Each
  /// aggregates one or more §XI.C penalty metrics from the
  /// MetricBreakdownResponse. Categories are displayed in fixed
  /// order regardless of which ones have data.
  static const Map<String, List<String>> _kCategories = {
    'spam_engagement_removed': [
      'spam_penalty',
      'spam_ring_detection_penalty',
      'synthetic_spam_detection',
      'ai_content_flood_penalty',
      'mass_generation_penalty',
    ],
    'bot_traffic_reversal': [
      'coordinated_bot_ring_penalty',
    ],
    'adult_content_reduction': [
      'adult_content_reduction',
      'sexual_engagement_bait_penalty',
      'mature_content_distribution_limit',
    ],
    'harassment_penalty': [
      'harassment_penalty',
    ],
    'misinformation_penalty': [
      'misinformation_penalty',
    ],
  };

  String _categoryLabel(String key, bool isSw) => switch (key) {
        'spam_engagement_removed' =>
          isSw ? 'Spam iliyoondolewa' : 'Spam engagement removed',
        'bot_traffic_reversal' =>
          isSw ? 'Trafiki ya bot iliyobatilishwa' : 'Bot traffic reversal',
        'adult_content_reduction' =>
          isSw ? 'Punguzo la maudhui ya watu wazima' : 'Adult-content reduction',
        'harassment_penalty' =>
          isSw ? 'Adhabu ya unyanyasaji' : 'Harassment penalty',
        'misinformation_penalty' =>
          isSw ? 'Adhabu ya taarifa potofu' : 'Misinformation penalty',
        _ => key,
      };

  @override
  Widget build(BuildContext context) {
    // Bucket the breakdown rows by metric → category.
    final byMetric = <String, double>{};
    final eventsByMetric = <String, int>{};
    for (final r in breakdown.rows) {
      byMetric[r.metric] = (byMetric[r.metric] ?? 0) + r.netTsh;
      eventsByMetric[r.metric] =
          (eventsByMetric[r.metric] ?? 0) + r.eventCount;
    }

    final rows = <List<String>>[];
    var totalAdjustment = 0.0;
    var totalEvents = 0;
    _kCategories.forEach((category, metrics) {
      final amount = metrics.fold<double>(
          0, (a, m) => a + (byMetric[m] ?? 0));
      final events =
          metrics.fold<int>(0, (a, m) => a + (eventsByMetric[m] ?? 0));
      totalAdjustment += amount;
      totalEvents += events;
      rows.add([
        _categoryLabel(category, isSw),
        '$events',
        amount > 0 ? '−${_money(amount)}' : _money(0),
      ]);
    });
    // Net adjustment row.
    rows.add([
      isSw ? 'JUMLA YA MAREKEBISHO' : 'NET ADJUSTMENT',
      '$totalEvents',
      totalAdjustment > 0
          ? '−${_money(totalAdjustment)}'
          : _money(0),
    ]);

    return _ReportSection(
      number: 10,
      title: isSw
          ? 'Marekebisho ya uadilifu'
          : 'Integrity & quality adjustments',
      subtitle: isSw
          ? 'Marekebisho yote yanaonyeshwa wazi — kuepuka migogoro ya uaminifu'
          : 'Every adjustment shown openly — to avoid trust disputes',
      child: _ReportTable(
        headers: [
          isSw ? 'Aina' : 'Category',
          isSw ? 'Matukio' : 'Events',
          isSw ? 'Marekebisho' : 'Adjustment',
        ],
        boldRows: [_kCategories.length],
        rows: rows,
      ),
    );
  }
}

// ─── §11 Geographic Revenue ──────────────────────────────────────────

class _Section11GeoRevenue extends StatelessWidget {
  final bool isSw;
  const _Section11GeoRevenue({required this.isSw});

  @override
  Widget build(BuildContext context) {
    return _ReportSection(
      number: 11,
      title: isSw ? 'Mapato kwa nchi' : 'Geographic revenue sources',
      subtitle: isSw
          ? 'Nchi zinazoongoza + CPM equivalent'
          : 'Top countries + CPM equivalent',
      child: _ComingSoonCard(
        phase: 'P3',
        reason: isSw
            ? 'Inahitaji geo-tagging kwenye matukio'
            : 'Requires geo-tagging on engagement events',
        detail: isSw
            ? 'Mara IP / locale ya mtazamaji itakapokuwa imenukuliwa kwenye matukio, hii itaonyesha nchi 5 zinazoongoza, mapato yake na CPM equivalent kuongoza maamuzi ya yaliyomo.'
            : "Once viewer IP / locale is logged with each event, this surfaces the top countries, their revenue, and a CPM-equivalent figure to inform content decisions.",
      ),
    );
  }
}

// ─── §12 Revenue Timeline ────────────────────────────────────────────

class _Section12RevenueTimeline extends StatelessWidget {
  final bool isSw;
  const _Section12RevenueTimeline({required this.isSw});

  @override
  Widget build(BuildContext context) {
    return _ReportSection(
      number: 12,
      title: isSw ? 'Ratiba ya mapato' : 'Revenue timeline',
      subtitle: isSw
            ? 'Mapato ya kila siku, alama za mlipuko'
            : 'Daily earnings with viral-spike annotations',
      child: _ComingSoonCard(
        phase: 'P3',
        reason: isSw
            ? 'Inahitaji rollup ya kila siku + algorithm ya kugundua mlipuko'
            : 'Requires daily rollup endpoint + spike-detection',
        detail: isSw
            ? 'Itaonyesha ratiba ya kila siku ya mapato yako pamoja na alama za mlipuko ("Stitch ya viral", "Mfululizo wa kushiriki") ili uone wakati gani ulifanya vizuri zaidi.'
            : 'A daily timeline of your earnings, annotated with viral-spike markers ("Viral stitch spike", "Share cascade") so you can connect content moves to revenue inflections.',
      ),
    );
  }
}

// ─── §13 Wallet & Payouts ────────────────────────────────────────────

class _Section13WalletPayouts extends StatelessWidget {
  final CreatorEarningsDashboard dashboard;
  final bool isSw;

  const _Section13WalletPayouts({
    required this.dashboard,
    required this.isSw,
  });

  @override
  Widget build(BuildContext context) {
    return _ReportSection(
      number: 13,
      title: isSw ? 'Mkoba na malipo' : 'Wallet & payouts',
      subtitle: isSw
          ? 'Salio, malipo yajayo, mapato ya maisha'
          : 'Balance, next payout, lifetime earnings',
      child: _ReportTable(
        rows: [
          [
            isSw ? 'Salio linalopatikana' : 'Available balance',
            _money(dashboard.totalClearedTsh)
          ],
          [
            isSw ? 'Inangoja kuisha' : 'Pending clearance',
            _money(dashboard.totalPendingTsh)
          ],
          [
            isSw ? 'Tarehe ya malipo yajayo' : 'Next payout date',
            '—',
          ],
          [
            isSw ? 'Mapato ya maisha' : 'Lifetime earnings',
            '—',
          ],
        ],
      ),
    );
  }
}

// ─── §14 AI Insights ─────────────────────────────────────────────────

class _Section14AIInsights extends StatelessWidget {
  final bool isSw;
  const _Section14AIInsights({required this.isSw});

  @override
  Widget build(BuildContext context) {
    return _ReportSection(
      number: 14,
      title: isSw ? 'Maarifa ya AI' : 'AI-suggested insights',
      subtitle: isSw
          ? 'Kugeuza takwimu kuwa mkakati'
          : 'Turning analytics into strategy',
      child: _ComingSoonCard(
        phase: 'P6',
        reason: isSw
            ? 'Inahitaji LLM layer juu ya rollup za matukio'
            : 'Requires LLM layer over event rollups',
        detail: isSw
            ? '"Posts zenye majadiliano makubwa zilipata 2.1× zaidi", "Quote-postable content ililetua 18% ya mapato" — ujumbe wa busara kutoka kwa modeli iliyofunzwa kwenye ushahidi wako.'
            : '"Posts with debate-heavy comments earned 2.1×", "Quote-postable content drove 18% of revenue", "External shares from Discord converted highest" — actionable insights derived from a model trained on your event ledger.',
      ),
    );
  }
}

// ─── §15 CSV Export ──────────────────────────────────────────────────

class _Section15CSVExport extends StatelessWidget {
  final bool isSw;
  const _Section15CSVExport({required this.isSw});

  @override
  Widget build(BuildContext context) {
    return _ReportSection(
      number: 15,
      title: isSw ? 'Export ya rekodi (CSV)' : 'Raw ledger export (CSV)',
      subtitle: isSw
          ? 'Kwa wakaguzi, mawakala, kodi'
          : 'For audits, agencies, taxes, creator studios',
      child: _ComingSoonCard(
        phase: 'P4',
        reason: isSw
            ? 'Inahitaji endpoint ya export'
            : 'Requires backend export endpoint',
        detail: isSw
            ? 'Itazalisha CSV: event_id · timestamp · event_type · source_post · viewer_id_hash · revenue_generated · royalty_split · final_creator_share. Muhimu kwa wakaguzi na mawakala wa kodi.'
            : 'Schema: event_id · timestamp · event_type · source_post · viewer_id_hash · revenue_generated · royalty_split · final_creator_share. Essential for audits and tax agencies.',
      ),
    );
  }
}

// ─── Loading + error sentinels ───────────────────────────────────────

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

String _money(double v) {
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
  return 'TZS ${parts.length > 1 ? '$formatted.${parts[1]}' : formatted}';
}

String _fmtCount(int v) {
  if (v >= 1000000) {
    return '${(v / 1000000).toStringAsFixed(v >= 10000000 ? 0 : 1)}M';
  }
  if (v >= 1000) {
    return '${(v / 1000).toStringAsFixed(v >= 10000 ? 0 : 1)}K';
  }
  return '$v';
}

String _formatRange(String startIso, String endIso, bool isSw) {
  if (startIso.isEmpty || endIso.isEmpty) {
    return isSw ? 'Kipindi cha sasa' : 'Current period';
  }
  final start = DateTime.tryParse(startIso);
  final end = DateTime.tryParse(endIso);
  if (start == null || end == null) {
    return '$startIso → $endIso';
  }
  const enMonths = [
    'January', 'February', 'March', 'April', 'May', 'June',
    'July', 'August', 'September', 'October', 'November', 'December',
  ];
  const swMonths = [
    'Januari', 'Februari', 'Machi', 'Aprili', 'Mei', 'Juni',
    'Julai', 'Agosti', 'Septemba', 'Oktoba', 'Novemba', 'Desemba',
  ];
  final months = isSw ? swMonths : enMonths;
  if (start.year == end.year && start.month == end.month) {
    return '${months[start.month - 1]} ${start.year}';
  }
  return '${months[start.month - 1]} ${start.day} – ${months[end.month - 1]} ${end.day}, ${end.year}';
}

// ─── Other-views footer ──────────────────────────────────────────────

class _OtherViewsFooter extends StatelessWidget {
  final int creatorId;
  final bool isSw;
  const _OtherViewsFooter({required this.creatorId, required this.isSw});

  @override
  Widget build(BuildContext context) {
    final items = <(IconData, String, VoidCallback)>[
      (
        Icons.dashboard_outlined,
        isSw ? 'Mtazamo wa Streams' : 'Cross-stream view',
        () {
          HapticFeedback.selectionClick();
          Navigator.push(
            context,
            MaterialPageRoute(
              builder: (_) => CreatorEarningsDashboardScreen(
                  currentUserId: creatorId),
            ),
          );
        },
      ),
      (
        Icons.receipt_outlined,
        isSw ? 'Matukio yote (rekodi)' : 'All events (ledger)',
        () {
          HapticFeedback.selectionClick();
          Navigator.pushNamed(context, '/earnings-provenance');
        },
      ),
      (
        Icons.workspace_premium_outlined,
        isSw ? 'Kiwango chako' : 'Your creator tier',
        () {
          HapticFeedback.selectionClick();
          Navigator.pushNamed(context, '/creator-tier');
        },
      ),
    ];

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 4),
          child: Text(
            isSw ? 'MITAZAMO MINGINE' : 'OTHER VIEWS',
            style: const TextStyle(
              fontSize: 11,
              fontWeight: FontWeight.w700,
              color: _kTertiary,
              letterSpacing: 0.6,
            ),
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
          ),
        ),
        const SizedBox(height: 10),
        Container(
          decoration: BoxDecoration(
            color: _kSurface,
            borderRadius: BorderRadius.circular(14),
            border: Border.all(color: _kBorder),
          ),
          child: Column(
            children: [
              for (var i = 0; i < items.length; i++) ...[
                _OtherViewRow(
                  icon: items[i].$1,
                  label: items[i].$2,
                  onTap: items[i].$3,
                ),
                if (i < items.length - 1)
                  const Divider(
                      height: 1,
                      color: _kBorder,
                      indent: 14,
                      endIndent: 14),
              ],
            ],
          ),
        ),
      ],
    );
  }
}

class _OtherViewRow extends StatelessWidget {
  final IconData icon;
  final String label;
  final VoidCallback onTap;

  const _OtherViewRow({
    required this.icon,
    required this.label,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: onTap,
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 14),
          child: Row(
            children: [
              Container(
                width: 32,
                height: 32,
                decoration: BoxDecoration(
                  color: _kIconBg,
                  borderRadius: BorderRadius.circular(8),
                ),
                alignment: Alignment.center,
                child: Icon(icon, size: 16, color: _kPrimary),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Text(
                  label,
                  style: const TextStyle(
                    fontSize: 13,
                    fontWeight: FontWeight.w600,
                    color: _kPrimary,
                  ),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
              ),
              const Icon(Icons.chevron_right_rounded,
                  size: 18, color: _kTertiary),
            ],
          ),
        ),
      ),
    );
  }
}

String _metricLabel(String metric, bool isSw) {
  return switch (metric) {
    'view' => isSw ? 'Mioneko' : 'Views',
    'watch_second' => isSw ? 'Sekunde za kutazama' : 'Watch seconds',
    'reaction' => isSw ? 'Reactions' : 'Reactions',
    'comment' => isSw ? 'Maoni' : 'Comments',
    'reply' => isSw ? 'Majibu' : 'Replies',
    'share' => isSw ? 'Mishirikishaji' : 'Shares',
    'save' => isSw ? 'Hifadhi' : 'Bookmarks',
    'comment_reaction' =>
      isSw ? 'Reactions kwenye maoni' : 'Comment reactions',
    'follow_from_post' =>
      isSw ? 'Followa kutoka post' : 'Follow conversions',
    'subscribe_from_post' =>
      isSw ? 'Subscribers kutoka post' : 'Subscription conversions',
    'derivative_royalty' =>
      isSw ? 'Royalty ya derivative' : 'Derivative royalty',
    _ => metric,
  };
}
