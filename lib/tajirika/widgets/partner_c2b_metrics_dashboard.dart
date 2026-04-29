import 'package:flutter/material.dart';
import 'package:intl/intl.dart';

import '../../l10n/app_strings_scope.dart';
import '../services/partner_c2b_metrics_service.dart';

const Color _kPrimary = Color(0xFF1A1A1A);
const Color _kSecondary = Color(0xFF666666);
const Color _kBorder = Color(0xFFEEEEEE);
const Color _kAccent = Color(0xFF2E7D32);

/// Spec §F dashboard — pulls daily aggregates from
/// `GET /partner-c2b/metrics` and renders 4 stat cards (completed jobs,
/// revenue, new orders, avg rating). Drop in on tajirika home or any
/// dashboard surface that wants a 30-day rolling summary.
class PartnerC2BMetricsDashboard extends StatefulWidget {
  final int userId;
  final String role; // 'partner' (default) or 'customer'
  final int rangeDays;
  final String? sourceType; // optional scope filter
  const PartnerC2BMetricsDashboard({
    super.key,
    required this.userId,
    this.role = 'partner',
    this.rangeDays = 30,
    this.sourceType,
  });

  @override
  State<PartnerC2BMetricsDashboard> createState() =>
      _PartnerC2BMetricsDashboardState();
}

class _PartnerC2BMetricsDashboardState extends State<PartnerC2BMetricsDashboard> {
  bool _loading = true;
  PartnerC2BMetricsTotals? _totals;
  List<PartnerC2BMetricsRow> _rows = const [];

  bool get _isSwahili => AppStringsScope.of(context)?.isSwahili ?? false;

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    setState(() => _loading = true);
    final to = DateTime.now();
    final from = to.subtract(Duration(days: widget.rangeDays));
    final rows = await PartnerC2BMetricsApi.fetch(
      userId: widget.userId,
      role: widget.role,
      sourceType: widget.sourceType,
      from: from,
      to: to,
    );
    if (!mounted) return;
    setState(() {
      _rows = rows;
      _totals = PartnerC2BMetricsTotals.from(rows);
      _loading = false;
    });
  }

  @override
  Widget build(BuildContext context) {
    final isSw = _isSwahili;
    if (_loading) {
      return const SizedBox(
        height: 100,
        child: Center(child: CircularProgressIndicator(strokeWidth: 2)),
      );
    }
    final t = _totals!;
    final fmt = NumberFormat('#,##0');
    final label = widget.rangeDays == 30
        ? (isSw ? 'Siku 30' : 'Last 30 days')
        : (isSw ? 'Siku ${widget.rangeDays}' : 'Last ${widget.rangeDays} days');
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Padding(
          padding: const EdgeInsets.only(bottom: 8, left: 4),
          child: Text(
            label.toUpperCase(),
            style: const TextStyle(
              fontSize: 11,
              fontWeight: FontWeight.w700,
              color: _kSecondary,
              letterSpacing: 0.4,
            ),
          ),
        ),
        Row(
          children: [
            Expanded(child: _statCard(
              icon: Icons.task_alt_rounded,
              label: isSw ? 'Imekamilika' : 'Completed',
              value: '${t.totalCompleted}',
              color: _kAccent,
            )),
            const SizedBox(width: 8),
            Expanded(child: _statCard(
              icon: Icons.attach_money_rounded,
              label: isSw ? 'Mapato' : 'Revenue',
              value: 'TZS ${fmt.format(t.totalRevenueTzs)}',
              color: _kPrimary,
            )),
          ],
        ),
        const SizedBox(height: 8),
        Row(
          children: [
            Expanded(child: _statCard(
              icon: Icons.add_shopping_cart_rounded,
              label: isSw ? 'Mpya' : 'New',
              value: '${t.totalNew}',
              color: _kPrimary,
            )),
            const SizedBox(width: 8),
            Expanded(child: _statCard(
              icon: Icons.star_rounded,
              label: isSw ? 'Ukadiriaji' : 'Rating',
              value: t.avgRating != null
                  ? '${t.avgRating!.toStringAsFixed(1)} (${t.totalReviews})'
                  : '—',
              color: const Color(0xFFFFB300),
            )),
          ],
        ),
        if (_rows.isEmpty)
          Padding(
            padding: const EdgeInsets.only(top: 8, left: 4),
            child: Text(
              isSw
                  ? 'Hakuna data ya siku 30 zilizopita.'
                  : 'No data for the last 30 days.',
              style: const TextStyle(fontSize: 11, color: _kSecondary),
            ),
          ),
      ],
    );
  }

  Widget _statCard({
    required IconData icon,
    required String label,
    required String value,
    required Color color,
  }) {
    return Container(
      padding: const EdgeInsets.all(10),
      decoration: BoxDecoration(
        color: Colors.white,
        border: Border.all(color: _kBorder),
        borderRadius: BorderRadius.circular(8),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(icon, size: 16, color: color),
          const SizedBox(height: 4),
          Text(
            value,
            style: const TextStyle(
              fontSize: 13,
              fontWeight: FontWeight.w800,
              color: _kPrimary,
            ),
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
          ),
          Text(
            label,
            style: const TextStyle(fontSize: 10, color: _kSecondary),
          ),
        ],
      ),
    );
  }
}
