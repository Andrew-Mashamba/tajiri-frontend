import 'package:flutter/material.dart';

import '../../l10n/app_strings_scope.dart';
import '../../services/wave_h_services.dart';

/// Spec F13 #110 — Cross-persona time-vs-revenue dashboard.
class CrossPersonaDashboardPage extends StatefulWidget {
  final int partnerUserId;
  const CrossPersonaDashboardPage({super.key, required this.partnerUserId});

  @override
  State<CrossPersonaDashboardPage> createState() =>
      _CrossPersonaDashboardPageState();
}

class _CrossPersonaDashboardPageState extends State<CrossPersonaDashboardPage> {
  bool _loading = true;
  List<Map<String, dynamic>> _metrics = const [];

  @override
  void initState() {
    super.initState();
    _refresh();
  }

  Future<void> _refresh() async {
    setState(() => _loading = true);
    await CrossPersonaDashboardService.rebuild(widget.partnerUserId);
    final rows = await CrossPersonaDashboardService.show(widget.partnerUserId);
    if (!mounted) return;
    setState(() {
      _metrics = rows;
      _loading = false;
    });
  }

  String _fmt(int n) {
    final s = n.toString();
    final out = StringBuffer();
    for (int i = 0; i < s.length; i++) {
      if (i > 0 && (s.length - i) % 3 == 0) out.write(',');
      out.write(s[i]);
    }
    return out.toString();
  }

  @override
  Widget build(BuildContext context) {
    final isSw = AppStringsScope.of(context)?.isSwahili ?? false;
    final byPeriod = <String, List<Map<String, dynamic>>>{};
    for (final m in _metrics) {
      final p = m['period_month']?.toString().substring(0, 7) ?? '?';
      byPeriod.putIfAbsent(p, () => []).add(m);
    }
    final sortedPeriods = byPeriod.keys.toList()..sort((a, b) => b.compareTo(a));
    return Scaffold(
      backgroundColor: const Color(0xFFFAFAFA),
      appBar: AppBar(
        backgroundColor: Colors.white,
        title: Text(isSw ? 'Muda dhidi ya mapato' : 'Time vs revenue'),
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh_rounded),
            onPressed: _refresh,
          ),
        ],
      ),
      body: _loading
          ? const Center(child: CircularProgressIndicator())
          : sortedPeriods.isEmpty
              ? Center(
                  child: Padding(
                    padding: const EdgeInsets.all(24),
                    child: Text(
                      isSw
                          ? 'Hakuna data bado.'
                          : 'No data yet — check back after orders.',
                      style: const TextStyle(color: Color(0xFF666666)),
                    ),
                  ),
                )
              : ListView.builder(
                  padding: const EdgeInsets.all(16),
                  itemCount: sortedPeriods.length,
                  itemBuilder: (ctx, i) {
                    final period = sortedPeriods[i];
                    final rows = byPeriod[period]!;
                    final totalMin = rows.fold<int>(
                        0, (s, r) => s + ((r['time_minutes'] as num?)?.toInt() ?? 0));
                    final totalRev = rows.fold<int>(
                        0, (s, r) => s + ((r['revenue_tzs'] as num?)?.toInt() ?? 0));
                    final totalOrders = rows.fold<int>(
                        0, (s, r) => s + ((r['orders_count'] as num?)?.toInt() ?? 0));
                    return Container(
                      margin: const EdgeInsets.only(bottom: 12),
                      padding: const EdgeInsets.all(12),
                      decoration: BoxDecoration(
                        color: Colors.white,
                        borderRadius: BorderRadius.circular(12),
                        border: Border.all(color: const Color(0xFFEEEEEE)),
                      ),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Row(
                            children: [
                              Text(
                                period,
                                style: const TextStyle(
                                    fontSize: 16,
                                    fontWeight: FontWeight.w800,
                                    color: Color(0xFF1A1A1A)),
                              ),
                              const Spacer(),
                              Text('TZS ${_fmt(totalRev)}',
                                  style: const TextStyle(
                                      fontSize: 14,
                                      fontWeight: FontWeight.w800,
                                      color: Color(0xFF1B5E20))),
                            ],
                          ),
                          Text(
                            isSw
                                ? '$totalOrders agizo • ${(totalMin / 60).toStringAsFixed(1)}h'
                                : '$totalOrders orders • ${(totalMin / 60).toStringAsFixed(1)}h',
                            style: const TextStyle(
                                fontSize: 12, color: Color(0xFF666666)),
                          ),
                          const SizedBox(height: 8),
                          ...rows.map((r) {
                            final skill = r['skill_category']?.toString() ?? '?';
                            final mins = (r['time_minutes'] as num?)?.toInt() ?? 0;
                            final rev = (r['revenue_tzs'] as num?)?.toInt() ?? 0;
                            final orders = (r['orders_count'] as num?)?.toInt() ?? 0;
                            return Padding(
                              padding: const EdgeInsets.symmetric(vertical: 4),
                              child: Row(
                                children: [
                                  Expanded(
                                    flex: 4,
                                    child: Text(
                                      skill,
                                      style: const TextStyle(
                                          fontSize: 13,
                                          fontWeight: FontWeight.w600,
                                          color: Color(0xFF1A1A1A)),
                                    ),
                                  ),
                                  Expanded(
                                    child: Text('$orders',
                                        textAlign: TextAlign.center,
                                        style: const TextStyle(
                                            fontSize: 12, color: Color(0xFF666666))),
                                  ),
                                  Expanded(
                                    child: Text(
                                      '${(mins / 60).toStringAsFixed(1)}h',
                                      textAlign: TextAlign.center,
                                      style: const TextStyle(
                                          fontSize: 12, color: Color(0xFF666666)),
                                    ),
                                  ),
                                  Expanded(
                                    flex: 2,
                                    child: Text(
                                      'TZS ${_fmt(rev)}',
                                      textAlign: TextAlign.right,
                                      style: const TextStyle(
                                          fontSize: 13,
                                          fontWeight: FontWeight.w700,
                                          color: Color(0xFF1A1A1A)),
                                    ),
                                  ),
                                ],
                              ),
                            );
                          }),
                        ],
                      ),
                    );
                  },
                ),
    );
  }
}
