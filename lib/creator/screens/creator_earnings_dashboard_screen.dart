// lib/creator/screens/creator_earnings_dashboard_screen.dart
//
// Cross-stream creator earnings dashboard. Strategy §1.2 + §9.
// Layered cache + SWR per ENGINEERING_PLAYBOOK.md.

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import '../../l10n/app_strings_scope.dart';
import '../../services/local_storage_service.dart';
import '../../widgets/tajiri_app_bar.dart';
import '../models/creator_earnings_models.dart';
import '../services/creator_earnings_service.dart';
import '../widgets/attribution_layers_card.dart';
import '../widgets/fund_period_card.dart';
import '../widgets/revenue_source_mix_card.dart';
import 'creator_revenue_report_screen.dart';
import 'stream_type_earnings_screen.dart';

const Color _kPrimary = Color(0xFF1A1A1A);
const Color _kSecondary = Color(0xFF666666);
const Color _kTertiary = Color(0xFF999999);
const Color _kBorder = Color(0xFFE5E5E5);
const Color _kSurface = Colors.white;
const Color _kBackground = Color(0xFFFAFAFA);

class CreatorEarningsDashboardScreen extends StatefulWidget {
  final int currentUserId;

  const CreatorEarningsDashboardScreen({super.key, required this.currentUserId});

  @override
  State<CreatorEarningsDashboardScreen> createState() =>
      _CreatorEarningsDashboardScreenState();
}

class _CreatorEarningsDashboardScreenState
    extends State<CreatorEarningsDashboardScreen> {
  final _service = CreatorEarningsService();
  CreatorEarningsDashboard? _dashboard;
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
    final cached = await _service.getCachedDashboard(widget.currentUserId);
    if (!mounted) return;
    setState(() {
      _token = token;
      if (cached != null) _dashboard = cached;
      _loading = cached == null;
    });
    _refresh();
  }

  Future<void> _refresh() async {
    if (_token == null) return;
    try {
      final fresh = await _service.getDashboard(
        userId: widget.currentUserId,
        token: _token!,
      );
      if (!mounted) return;
      setState(() {
        _dashboard = fresh;
        _loading = false;
        _error = null;
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

  @override
  Widget build(BuildContext context) {
    final isSw = AppStringsScope.of(context)?.isSwahili ?? false;
    return Scaffold(
      backgroundColor: _kBackground,
      appBar: TajiriAppBar(title: isSw ? 'Mapato' : 'Earnings'),
      body: SafeArea(
        child: _loading
            ? const Center(
                child: CircularProgressIndicator(strokeWidth: 2, color: _kPrimary))
            : _dashboard == null && _error != null
                ? _buildError(isSw)
                : RefreshIndicator(
                    color: _kPrimary,
                    onRefresh: _refresh,
                    child: ListView(
                      physics: const AlwaysScrollableScrollPhysics(),
                      padding: const EdgeInsets.fromLTRB(16, 16, 16, 24),
                      children: _buildContent(isSw),
                    ),
                  ),
      ),
    );
  }

  List<Widget> _buildContent(bool isSw) {
    final d = _dashboard!;
    return [
      _buildHero(d, isSw),
      const SizedBox(height: 16),
      EarningsTierBadge(
        tier: d.tier,
        isMwanzoActive: d.isMwanzoActive,
        mwanzoExpiresAt: d.mwanzoExpiresAt,
        isSw: isSw,
      ),
      const SizedBox(height: 20),
      if (d.currentPeriod != null) ...[
        FundPeriodCard(period: d.currentPeriod!, isSw: isSw),
        const SizedBox(height: 20),
      ],
      _SectionLabel(
          isSw ? 'MCHANGANYIKO WA VYANZO' : 'REVENUE SOURCE MIX'),
      const SizedBox(height: 8),
      RevenueSourceMixCard(
        breakdownByStream: d.breakdownByStream,
        isSw: isSw,
      ),
      const SizedBox(height: 20),
      _SectionLabel(isSw ? 'MAPATO KWA AINA' : 'BREAKDOWN BY STREAM'),
      const SizedBox(height: 8),
      _buildBreakdownCard(d, isSw),
      const SizedBox(height: 20),
      _SectionLabel(
          isSw ? 'TABAKA ZA ATTRIBUTION' : 'ATTRIBUTION LAYERS'),
      const SizedBox(height: 8),
      AttributionLayersCard(isSw: isSw),
      AttributionPropagationFooter(isSw: isSw),
      const SizedBox(height: 20),
      _buildActions(isSw),
    ];
  }

  Widget _buildHero(CreatorEarningsDashboard d, bool isSw) {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(color: _kPrimary, borderRadius: BorderRadius.circular(16)),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            isSw ? 'Jumla iliyoisha · imelipwa baada ya siku 30' : 'Total cleared · paid out after 30 days',
            style: TextStyle(fontSize: 11, color: Colors.white.withValues(alpha: 0.70), letterSpacing: 0.4, fontWeight: FontWeight.w500),
            maxLines: 2, overflow: TextOverflow.ellipsis,
          ),
          const SizedBox(height: 8),
          Text(
            'TZS ${_fmt(d.totalClearedTsh)}',
            style: const TextStyle(fontSize: 36, fontWeight: FontWeight.w800, color: Colors.white, height: 1.0, letterSpacing: -0.6, fontFeatures: [FontFeature.tabularFigures()]),
            maxLines: 1, overflow: TextOverflow.ellipsis,
          ),
          const SizedBox(height: 12),
          Row(
            children: [
              Expanded(child: _heroPill(label: isSw ? 'Inangoja' : 'Pending', value: 'TZS ${_fmt(d.totalPendingTsh)}')),
              const SizedBox(width: 8),
              Expanded(child: _heroPill(label: isSw ? 'Kadiriwa' : 'Estimated', value: d.estimatedThisPeriodTsh != null ? 'TZS ${_fmt(d.estimatedThisPeriodTsh!)}' : '—')),
            ],
          ),
        ],
      ),
    );
  }

  Widget _heroPill({required String label, required String value}) {
    return Container(
      padding: const EdgeInsets.symmetric(vertical: 8, horizontal: 10),
      decoration: BoxDecoration(color: Colors.white.withValues(alpha: 0.10), borderRadius: BorderRadius.circular(10)),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(label, style: TextStyle(color: Colors.white.withValues(alpha: 0.70), fontSize: 11), maxLines: 1, overflow: TextOverflow.ellipsis),
          const SizedBox(height: 2),
          Text(value, style: const TextStyle(color: Colors.white, fontSize: 14, fontWeight: FontWeight.w700, fontFeatures: [FontFeature.tabularFigures()]), maxLines: 1, overflow: TextOverflow.ellipsis),
        ],
      ),
    );
  }

  Widget _buildBreakdownCard(CreatorEarningsDashboard d, bool isSw) {
    final streams = ['engagement', 'fan_funding', 'marketplace', 'brand_deal', 'live_gifts', 'affiliate'];
    return Container(
      decoration: BoxDecoration(
        color: _kSurface,
        borderRadius: BorderRadius.circular(14),
        boxShadow: [BoxShadow(color: Colors.black.withValues(alpha: 0.04), blurRadius: 10, offset: const Offset(0, 2))],
      ),
      child: Column(
        children: [
          for (var i = 0; i < streams.length; i++) ...[
            _StreamBreakdownRow(
              streamKey: streams[i],
              data: d.breakdownByStream[streams[i]] ??
                  const StreamBreakdown(clearedTsh: 0, pendingTsh: 0, eventCount: 0),
              isSw: isSw,
              onTap: () {
                HapticFeedback.selectionClick();
                // Live Gifts row routes to the dedicated streams
                // strategy renderer; others fall through to the
                // per-event provenance ledger.
                if (streams[i] == 'live_gifts') {
                  Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (_) => StreamTypeEarningsScreen(
                        creatorId: widget.currentUserId,
                        streamType: 'live_video',
                      ),
                    ),
                  );
                } else {
                  Navigator.pushNamed(context, '/earnings-provenance',
                      arguments: {'stream': streams[i]});
                }
              },
            ),
            if (i < streams.length - 1)
              const Divider(height: 1, thickness: 1, color: _kBorder, indent: 16, endIndent: 16),
          ],
        ],
      ),
    );
  }

  Widget _buildActions(bool isSw) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        ElevatedButton.icon(
          onPressed: () {
            HapticFeedback.selectionClick();
            Navigator.push(
              context,
              MaterialPageRoute(
                builder: (_) => CreatorRevenueReportScreen(
                    creatorId: widget.currentUserId),
              ),
            );
          },
          icon: const Icon(Icons.receipt_long_rounded, size: 18),
          label: Text(
              isSw ? 'Ripoti kamili ya mapato' : 'Full revenue report'),
          style: ElevatedButton.styleFrom(
            backgroundColor: _kPrimary,
            foregroundColor: Colors.white,
            elevation: 0,
            shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(12)),
            padding: const EdgeInsets.symmetric(vertical: 14),
          ),
        ),
        const SizedBox(height: 8),
        OutlinedButton(
          onPressed: () {
            HapticFeedback.selectionClick();
            Navigator.pushNamed(context, '/earnings-provenance');
          },
          style: OutlinedButton.styleFrom(
            foregroundColor: _kPrimary,
            side: const BorderSide(color: _kPrimary),
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
            padding: const EdgeInsets.symmetric(vertical: 14),
          ),
          child: Text(isSw ? 'Angalia matukio yote' : 'View all events'),
        ),
        const SizedBox(height: 8),
        OutlinedButton(
          onPressed: () {
            HapticFeedback.selectionClick();
            Navigator.pushNamed(context, '/creator-tier');
          },
          style: OutlinedButton.styleFrom(
            foregroundColor: _kPrimary,
            side: const BorderSide(color: _kPrimary),
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
            padding: const EdgeInsets.symmetric(vertical: 14),
          ),
          child: Text(isSw ? 'Kiwango chako' : 'Your tier'),
        ),
      ],
    );
  }

  Widget _buildError(bool isSw) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(24),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.error_outline_rounded, size: 64, color: Colors.grey.shade300),
            const SizedBox(height: 16),
            Text(_error ?? '', style: const TextStyle(color: _kSecondary, fontSize: 14), textAlign: TextAlign.center, maxLines: 4, overflow: TextOverflow.ellipsis),
            const SizedBox(height: 16),
            OutlinedButton(
              onPressed: _refresh,
              style: OutlinedButton.styleFrom(
                foregroundColor: _kPrimary,
                side: const BorderSide(color: _kPrimary),
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
              ),
              child: Text(isSw ? 'Jaribu tena' : 'Retry'),
            ),
          ],
        ),
      ),
    );
  }

  static String _fmt(double v) {
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
}

class _SectionLabel extends StatelessWidget {
  final String label;
  const _SectionLabel(this.label);
  @override
  Widget build(BuildContext context) => Padding(
        padding: const EdgeInsets.symmetric(horizontal: 4),
        child: Text(label, style: const TextStyle(fontSize: 11, fontWeight: FontWeight.w600, color: _kTertiary, letterSpacing: 0.6), maxLines: 1, overflow: TextOverflow.ellipsis),
      );
}

class _StreamBreakdownRow extends StatelessWidget {
  final String streamKey;
  final StreamBreakdown data;
  final bool isSw;
  final VoidCallback? onTap;

  const _StreamBreakdownRow({
    required this.streamKey,
    required this.data,
    required this.isSw,
    this.onTap,
  });

  static const _labels = {
    'engagement': ('Engagement Pool', 'Mfuko wa Ushiriki'),
    'fan_funding': ('Fan Funding', 'Msaada wa Mashabiki'),
    'marketplace': ('Marketplace', 'Soko'),
    'brand_deal': ('Brand Deals', 'Mikataba ya Brand'),
    // Tapping this row opens the full Streams.earnings strategy
    // renderer — see streams.md §I-§XII (75 events). The amount on
    // the card is the Live Gifts earnings-stream subtotal; the
    // destination shows every stream-related metric.
    'live_gifts': ('Streams', 'Mitiririko'),
    'affiliate': ('Affiliate', 'Mshauri'),
  };

  static const _icons = {
    'engagement': Icons.bolt_rounded,
    'fan_funding': Icons.favorite_rounded,
    'marketplace': Icons.storefront_rounded,
    'brand_deal': Icons.handshake_rounded,
    'live_gifts': Icons.live_tv_rounded,
    'affiliate': Icons.share_rounded,
  };

  @override
  Widget build(BuildContext context) {
    final pair = _labels[streamKey];
    final name = isSw ? (pair?.$2 ?? streamKey) : (pair?.$1 ?? streamKey);
    final icon = _icons[streamKey] ?? Icons.attach_money_rounded;
    final cleared = data.clearedTsh;
    final pending = data.pendingTsh;
    final isStreamsRow = streamKey == 'live_gifts';

    return InkWell(
      onTap: onTap,
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
        child: Row(
          children: [
            Container(
              width: 40, height: 40,
              decoration: BoxDecoration(color: const Color(0xFFF5F5F5), borderRadius: BorderRadius.circular(10)),
              child: Icon(icon, size: 20, color: _kPrimary),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(name, style: const TextStyle(fontSize: 14, fontWeight: FontWeight.w600, color: _kPrimary), maxLines: 1, overflow: TextOverflow.ellipsis),
                  const SizedBox(height: 2),
                  Text(
                    isStreamsRow
                        ? (isSw
                            ? 'Mitiririko yote · ${_fmt(pending)} inangoja · ${_fmt(cleared)} imeisha'
                            : 'All streams · ${_fmt(pending)} pending · ${_fmt(cleared)} cleared')
                        : (isSw
                            ? '${_fmt(pending)} inangoja · ${_fmt(cleared)} imeisha'
                            : '${_fmt(pending)} pending · ${_fmt(cleared)} cleared'),
                    style: const TextStyle(fontSize: 12, color: _kSecondary),
                    maxLines: 1, overflow: TextOverflow.ellipsis,
                  ),
                ],
              ),
            ),
            Text('TZS ${_fmt(cleared + pending)}',
                style: const TextStyle(
                    fontSize: 14, fontWeight: FontWeight.w700, color: _kPrimary)),
            if (isStreamsRow) ...[
              const SizedBox(width: 4),
              const Icon(Icons.chevron_right_rounded,
                  size: 18, color: _kTertiary),
            ],
          ],
        ),
      ),
    );
  }

  static String _fmt(double v) {
    if (v >= 1000000) return '${(v / 1000000).toStringAsFixed(1)}M';
    if (v >= 1000) return '${(v / 1000).toStringAsFixed(0)}K';
    return v.toStringAsFixed(0);
  }
}
