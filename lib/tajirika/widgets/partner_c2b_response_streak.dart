import 'package:flutter/material.dart';

import '../../l10n/app_strings_scope.dart';
import '../services/partner_c2b_metrics_service.dart';

const Color _kPrimary = Color(0xFF1A1A1A);
const Color _kSecondary = Color(0xFF666666);
const Color _kBorder = Color(0xFFEEEEEE);
const Color _kAccent = Color(0xFF1B5E20);

/// Spec line 358 — daily activity sparkline. Mini bar chart of completed
/// counts across the last 14 days. Uses CustomPainter so no chart-lib dep.
class PartnerC2BActivitySparkline extends StatefulWidget {
  final int userId;
  final String role;
  final int rangeDays;
  const PartnerC2BActivitySparkline({
    super.key,
    required this.userId,
    this.role = 'partner',
    this.rangeDays = 14,
  });

  @override
  State<PartnerC2BActivitySparkline> createState() =>
      _PartnerC2BActivitySparklineState();
}

class _PartnerC2BActivitySparklineState extends State<PartnerC2BActivitySparkline> {
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

  @override
  Widget build(BuildContext context) {
    if (_loading) {
      return const SizedBox(
        height: 60,
        child: Center(child: CircularProgressIndicator(strokeWidth: 2)),
      );
    }
    // Bucket per date.
    final perDate = <String, int>{};
    for (final r in _rows) {
      perDate[r.date] = (perDate[r.date] ?? 0) + r.countCompleted;
    }
    final dates = <String>[];
    final to = DateTime.now();
    for (var i = widget.rangeDays - 1; i >= 0; i--) {
      final d = to.subtract(Duration(days: i));
      dates.add(d.toIso8601String().split('T').first);
    }
    final values = dates.map((d) => perDate[d] ?? 0).toList();
    final maxV = values.fold<int>(0, (m, v) => v > m ? v : m).clamp(1, 1 << 30);
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
          Row(
            children: [
              Text(
                _isSwahili ? 'Shughuli (siku ${widget.rangeDays})' : 'Activity (${widget.rangeDays}d)',
                style: const TextStyle(fontSize: 11, fontWeight: FontWeight.w700, color: _kPrimary),
              ),
              const Spacer(),
              Text(
                '${values.fold<int>(0, (s, v) => s + v)} ${_isSwahili ? "kazi" : "jobs"}',
                style: const TextStyle(fontSize: 10, color: _kSecondary),
              ),
            ],
          ),
          const SizedBox(height: 8),
          SizedBox(
            height: 36,
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.end,
              children: values.map((v) {
                final h = v == 0 ? 1.0 : (v / maxV) * 32;
                return Expanded(
                  child: Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 1),
                    child: Container(
                      height: h,
                      decoration: BoxDecoration(
                        color: v == 0 ? _kBorder : _kAccent,
                        borderRadius: BorderRadius.circular(2),
                      ),
                    ),
                  ),
                );
              }).toList(),
            ),
          ),
        ],
      ),
    );
  }
}
