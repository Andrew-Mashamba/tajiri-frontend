import 'package:flutter/material.dart';
import 'package:intl/intl.dart';

import '../../l10n/app_strings_scope.dart';
import '../services/partner_c2b_metrics_service.dart';

const Color _kPrimary = Color(0xFF1A1A1A);
const Color _kSecondary = Color(0xFF666666);
const Color _kBorder = Color(0xFFEEEEEE);

/// Spec §F — source-mix breakdown across the F1–F13 verticals. Shows a
/// horizontal bar per `source_type` with proportional fill so the partner
/// sees which verticals drive the most volume in their selected window.
class PartnerC2BSourceMixCard extends StatefulWidget {
  final int userId;
  final String role;
  final int rangeDays;
  const PartnerC2BSourceMixCard({
    super.key,
    required this.userId,
    this.role = 'partner',
    this.rangeDays = 30,
  });

  @override
  State<PartnerC2BSourceMixCard> createState() => _PartnerC2BSourceMixCardState();
}

class _PartnerC2BSourceMixCardState extends State<PartnerC2BSourceMixCard> {
  bool _loading = true;
  List<PartnerC2BMetricsRow> _rows = const [];

  bool get _isSwahili => AppStringsScope.of(context)?.isSwahili ?? false;

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    final to = DateTime.now();
    final from = to.subtract(Duration(days: widget.rangeDays));
    final rows = await PartnerC2BMetricsApi.fetch(
      userId: widget.userId,
      role: widget.role,
      from: from,
      to: to,
    );
    if (!mounted) return;
    setState(() {
      _loading = false;
      _rows = rows;
    });
  }

  String _sourceLabel(String s) {
    final isSw = _isSwahili;
    switch (s) {
      case 'appointment':     return isSw ? 'Miadi' : 'Appointments';
      case 'consultation':    return isSw ? 'Mashauriano' : 'Consultations';
      case 'engagement':      return isSw ? 'Mikataba' : 'Engagements';
      case 'event_booking':   return isSw ? 'Matukio' : 'Events';
      case 'service_request': return isSw ? 'Mafundi' : 'Pro services';
      case 'garage_booking':  return isSw ? 'Karakana' : 'Garage';
      case 'listing_inquiry': return isSw ? 'Mali' : 'Property';
      case 'partner_product': return isSw ? 'Bidhaa' : 'Products';
      default: return s;
    }
  }

  @override
  Widget build(BuildContext context) {
    if (_loading) {
      return const SizedBox(
        height: 80,
        child: Center(child: CircularProgressIndicator(strokeWidth: 2)),
      );
    }
    final isSw = _isSwahili;
    if (_rows.isEmpty) {
      return Container(
        padding: const EdgeInsets.all(12),
        decoration: BoxDecoration(
          color: Colors.white,
          border: Border.all(color: _kBorder),
          borderRadius: BorderRadius.circular(8),
        ),
        child: Text(
          isSw ? 'Hakuna data ya siku ${widget.rangeDays}' : 'No data for last ${widget.rangeDays} days',
          style: const TextStyle(fontSize: 12, color: _kSecondary),
        ),
      );
    }
    // Aggregate per source_type.
    final perSource = <String, _SourceTotals>{};
    for (final r in _rows) {
      final t = perSource.putIfAbsent(r.sourceType, () => _SourceTotals());
      t.count += r.countCompleted;
      t.revenue += r.revenueTzs;
    }
    final entries = perSource.entries.toList()
      ..sort((a, b) => b.value.count.compareTo(a.value.count));
    final maxCount = entries.first.value.count.clamp(1, 1 << 30);
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: Colors.white,
        border: Border.all(color: _kBorder),
        borderRadius: BorderRadius.circular(8),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            isSw ? 'Mchanganyiko kwa aina' : 'Source mix',
            style: const TextStyle(
                fontSize: 13, fontWeight: FontWeight.w700, color: _kPrimary),
          ),
          const SizedBox(height: 8),
          ...entries.map((e) => Padding(
                padding: const EdgeInsets.only(bottom: 6),
                child: _bar(e.key, e.value, maxCount),
              )),
        ],
      ),
    );
  }

  Widget _bar(String key, _SourceTotals t, int maxCount) {
    final pct = maxCount == 0 ? 0.0 : (t.count / maxCount).clamp(0.0, 1.0);
    final fmt = NumberFormat('#,##0');
    return Row(
      children: [
        SizedBox(
          width: 100,
          child: Text(
            _sourceLabel(key),
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            style: const TextStyle(fontSize: 11, color: _kPrimary, fontWeight: FontWeight.w600),
          ),
        ),
        Expanded(
          child: Stack(
            children: [
              Container(
                height: 8,
                decoration: BoxDecoration(
                  color: _kBorder,
                  borderRadius: BorderRadius.circular(4),
                ),
              ),
              FractionallySizedBox(
                widthFactor: pct,
                child: Container(
                  height: 8,
                  decoration: BoxDecoration(
                    color: _kPrimary,
                    borderRadius: BorderRadius.circular(4),
                  ),
                ),
              ),
            ],
          ),
        ),
        const SizedBox(width: 8),
        SizedBox(
          width: 90,
          child: Text(
            '${t.count} • TZS ${fmt.format(t.revenue)}',
            textAlign: TextAlign.right,
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            style: const TextStyle(fontSize: 10, color: _kSecondary),
          ),
        ),
      ],
    );
  }
}

class _SourceTotals {
  int count = 0;
  int revenue = 0;
}
