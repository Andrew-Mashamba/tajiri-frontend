// lib/myjob/pages/my_kpis_page.dart
import 'package:flutter/material.dart';
import '../../l10n/app_strings_scope.dart';
import '../../team/widgets/kpi_sparkline_chart.dart';
import '../models/myjob_models.dart';
import '../services/my_job_service.dart';

const Color _kPrimary = Color(0xFF1A1A1A);
const Color _kSecondary = Color(0xFF666666);
const Color _kBg = Color(0xFFFAFAFA);
const Color _kCard = Color(0xFFFFFFFF);

class MyKpisPage extends StatefulWidget {
  final String token;

  const MyKpisPage({super.key, required this.token});

  @override
  State<MyKpisPage> createState() => _MyKpisPageState();
}

class _MyKpisPageState extends State<MyKpisPage> {
  List<Kpi> _kpis = [];
  final Map<int, List<KpiEntry>> _entries = {};
  final Set<int> _expanded = {};
  bool _loading = true;
  String? _error;

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    setState(() { _loading = true; _error = null; });
    try {
      final res = await MyJobService.getMyKpis(widget.token);
      if (!mounted) return;
      setState(() {
        _loading = false;
        _kpis = res.data;
      });
      for (final kpi in _kpis) {
        if (kpi.id != null) _loadEntries(kpi.id!);
      }
    } catch (e) {
      if (!mounted) return;
      setState(() { _loading = false; _error = e.toString(); });
    }
  }

  Future<void> _loadEntries(int kpiId) async {
    try {
      final res = await MyJobService.getMyKpiEntries(widget.token, kpiId);
      if (!mounted) return;
      setState(() => _entries[kpiId] = res.data);
    } catch (_) {}
  }

  String _fmt(Kpi kpi, double v) {
    if (kpi.unit == 'TZS') return 'TZS ${v.round()}';
    return '${v == v.roundToDouble() ? v.round() : v.toStringAsFixed(1)} ${kpi.unit}';
  }

  String _trendLabel(List<KpiEntry> entries, double target) {
    if (entries.length < 2) return '→';
    final last3 = entries.take(3).map((e) => e.actualValue).toList();
    if (last3.length < 2) return '→';
    double sum = 0;
    for (int i = 0; i < last3.length - 1; i++) {
      sum += last3[i] - last3[i + 1];
    }
    if (sum > 0) return '↑';
    if (sum < 0) return '↓';
    return '→';
  }

  @override
  Widget build(BuildContext context) {
    final sw = AppStringsScope.of(context)?.isSwahili ?? false;
    return Scaffold(
      backgroundColor: _kBg,
      appBar: AppBar(
        backgroundColor: _kBg,
        elevation: 0,
        leading: const BackButton(color: _kPrimary),
        title: Text(sw ? 'Viashiria Vyangu' : 'My KPIs',
            style: const TextStyle(
                color: _kPrimary, fontSize: 16, fontWeight: FontWeight.bold)),
      ),
      body: _loading
          ? const Center(child: CircularProgressIndicator(color: _kPrimary, strokeWidth: 2))
          : _error != null
              ? Center(child: Column(mainAxisSize: MainAxisSize.min, children: [
                  Icon(Icons.error_outline_rounded, size: 48, color: Colors.grey.shade400),
                  const SizedBox(height: 12),
                  Text(sw ? 'Imeshindwa kupakia KPI.' : 'Failed to load KPIs.',
                      style: TextStyle(color: Colors.grey.shade500, fontSize: 13)),
                  const SizedBox(height: 12),
                  ElevatedButton(
                    onPressed: _load,
                    style: ElevatedButton.styleFrom(backgroundColor: _kPrimary, foregroundColor: Colors.white),
                    child: Text(sw ? 'Jaribu Tena' : 'Retry'),
                  ),
                ]))
          : _kpis.isEmpty
              ? Center(
                  child: Text(
                      sw ? 'Hakuna malengo ya KPI bado. Meneja wako ataongeza.'
                         : 'No KPI targets set yet. Your manager will add them.',
                      textAlign: TextAlign.center,
                      style: TextStyle(fontSize: 14, color: Colors.grey.shade400)),
                )
              : RefreshIndicator(
                  color: _kPrimary,
                  onRefresh: _load,
                  child: ListView.builder(
                    padding: const EdgeInsets.all(16),
                    itemCount: _kpis.length,
                    itemBuilder: (_, i) {
                      final kpi = _kpis[i];
                      final entries = _entries[kpi.id] ?? [];
                      final isExpanded = _expanded.contains(kpi.id);
                      final lastEntry = entries.isNotEmpty ? entries.first : null;
                      final delta = entries.length >= 2
                          ? entries[0].actualValue - entries[1].actualValue
                          : null;
                      final trend = _trendLabel(entries, kpi.targetValue);

                      return Card(
                        color: _kCard, elevation: 0,
                        margin: const EdgeInsets.only(bottom: 12),
                        shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(14)),
                        child: InkWell(
                          borderRadius: BorderRadius.circular(14),
                          onTap: kpi.id == null ? null : () => setState(() {
                            isExpanded
                                ? _expanded.remove(kpi.id)
                                : _expanded.add(kpi.id!);
                          }),
                          child: Padding(
                            padding: const EdgeInsets.all(16),
                            child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                              Row(children: [
                                Expanded(child: Text(kpi.name,
                                    style: const TextStyle(
                                        fontSize: 14, fontWeight: FontWeight.w600,
                                        color: _kPrimary),
                                    maxLines: 1, overflow: TextOverflow.ellipsis)),
                                Text(trend, style: TextStyle(
                                    fontSize: 16,
                                    color: trend == '↑' ? Colors.green
                                        : trend == '↓' ? Colors.red
                                        : _kSecondary)),
                              ]),
                              const SizedBox(height: 4),
                              Wrap(spacing: 6, children: [
                                _chip('${sw ? 'Lengo' : 'Target'}: ${_fmt(kpi, kpi.targetValue)}'),
                                _chip(sw
                                    ? (kpi.reviewPeriod == 'monthly' ? 'Kila Mwezi'
                                        : kpi.reviewPeriod == 'quarterly' ? 'Kila Robo' : 'Kila Mwaka')
                                    : (kpi.reviewPeriod == 'monthly' ? 'Monthly'
                                        : kpi.reviewPeriod == 'quarterly' ? 'Quarterly' : 'Annual')),
                              ]),
                              if (lastEntry != null) ...[
                                const SizedBox(height: 8),
                                Row(children: [
                                  Expanded(child: LinearProgressIndicator(
                                    value: (lastEntry.actualValue / kpi.targetValue).clamp(0, 1),
                                    backgroundColor: Colors.grey.shade200,
                                    valueColor: AlwaysStoppedAnimation(
                                        lastEntry.actualValue >= kpi.targetValue
                                            ? Colors.green : Colors.red),
                                    minHeight: 4,
                                    borderRadius: BorderRadius.circular(2),
                                  )),
                                  const SizedBox(width: 8),
                                  Text(_fmt(kpi, lastEntry.actualValue),
                                      style: TextStyle(
                                          fontSize: 12,
                                          color: lastEntry.actualValue >= kpi.targetValue
                                              ? Colors.green : Colors.red,
                                          fontWeight: FontWeight.w600)),
                                  if (delta != null) ...[
                                    const SizedBox(width: 4),
                                    Text('${delta >= 0 ? '+' : ''}${delta.toStringAsFixed(1)}',
                                        style: TextStyle(
                                            fontSize: 11,
                                            color: delta >= 0 ? Colors.green : Colors.red)),
                                  ],
                                ]),
                                Text(
                                    '${sw ? 'Imesasishwa mwisho' : 'Last updated'}: ${lastEntry.periodLabel}',
                                    style: const TextStyle(fontSize: 11, color: _kSecondary)),
                              ],

                              if (isExpanded && entries.isNotEmpty) ...[
                                const Divider(height: 16),
                                SizedBox(
                                  height: 80,
                                  child: KpiSparklineChart(
                                      entries: entries.reversed.take(6).toList().reversed.toList(),
                                      target: kpi.targetValue),
                                ),
                                const SizedBox(height: 8),
                                ...entries.map((e) => Padding(
                                  padding: const EdgeInsets.only(bottom: 6),
                                  child: Row(children: [
                                    Expanded(child: Text(e.periodLabel,
                                        style: const TextStyle(fontSize: 12, color: _kPrimary))),
                                    Text(_fmt(kpi, e.actualValue),
                                        style: TextStyle(
                                            fontSize: 12,
                                            fontWeight: FontWeight.bold,
                                            color: e.actualValue >= kpi.targetValue
                                                ? Colors.green : Colors.red)),
                                  ]),
                                )),
                              ],

                              if (!isExpanded) ...[
                                const SizedBox(height: 4),
                                Text(
                                    sw ? 'Meneja wako anasasisha thamani za KPI.'
                                       : 'Your manager updates KPI values.',
                                    style: TextStyle(fontSize: 11, color: Colors.grey.shade400)),
                              ],
                            ]),
                          ),
                        ),
                      );
                    },
                  ),
                ),
    );
  }

  Widget _chip(String label) => Container(
        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
        decoration: BoxDecoration(
            color: Colors.grey.shade100, borderRadius: BorderRadius.circular(10)),
        child: Text(label, style: const TextStyle(fontSize: 11, color: _kPrimary)),
      );
}
