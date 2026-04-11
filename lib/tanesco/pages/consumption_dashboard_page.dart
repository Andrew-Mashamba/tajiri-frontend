// lib/tanesco/pages/consumption_dashboard_page.dart
import 'package:flutter/material.dart';
import '../../l10n/app_strings_scope.dart';
import '../models/tanesco_models.dart';
import '../services/tanesco_service.dart';
import '../widgets/consumption_chart.dart';

const Color _kPrimary = Color(0xFF1A1A1A);
const Color _kSecondary = Color(0xFF666666);
const Color _kBg = Color(0xFFFAFAFA);

class ConsumptionDashboardPage extends StatefulWidget {
  final Meter meter;
  const ConsumptionDashboardPage({super.key, required this.meter});
  @override
  State<ConsumptionDashboardPage> createState() => _ConsumptionDashboardPageState();
}

class _ConsumptionDashboardPageState extends State<ConsumptionDashboardPage> {
  static const _periods = ['daily', 'weekly', 'monthly'];
  static const _periodLabels = ['Kila Siku', 'Kila Wiki', 'Kila Mwezi'];
  static const _periodLabelsEn = ['Daily', 'Weekly', 'Monthly'];
  int _periodIndex = 0;
  List<ConsumptionRecord> _records = [];
  bool _loading = true;
  int? _selectedBar;

  @override
  void initState() { super.initState(); _load(); }

  Future<void> _load() async {
    setState(() { _loading = true; _selectedBar = null; });
    final result = await TanescoService.getConsumption(
        widget.meter.meterNumber, _periods[_periodIndex]);
    if (!mounted) return;
    setState(() {
      _loading = false;
      if (result.success) _records = result.items;
    });
  }

  double get _totalUnits => _records.fold(0, (s, r) => s + r.unitsUsed);
  double get _totalCost => _records.fold(0, (s, r) => s + r.cost);
  double get _avgDaily {
    if (_records.isEmpty) return 0;
    return _totalUnits / _records.length;
  }

  double? get _previousPeriodComparison {
    if (_records.length < 2) return null;
    final half = _records.length ~/ 2;
    final recent = _records.sublist(half).fold<double>(0, (s, r) => s + r.unitsUsed);
    final older = _records.sublist(0, half).fold<double>(0, (s, r) => s + r.unitsUsed);
    if (older == 0) return null;
    return ((recent - older) / older) * 100;
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: _kBg,
      appBar: AppBar(
        title: Text((AppStringsScope.of(context)?.isSwahili ?? false) ? 'Matumizi ya Umeme' : 'Power Consumption',
            style: const TextStyle(color: _kPrimary, fontWeight: FontWeight.w700, fontSize: 16)),
        backgroundColor: Colors.white, elevation: 0,
        iconTheme: const IconThemeData(color: _kPrimary),
      ),
      body: _loading
          ? const Center(child: CircularProgressIndicator(strokeWidth: 2, color: _kPrimary))
          : RefreshIndicator(
              onRefresh: _load,
              color: _kPrimary,
              child: ListView(
                padding: const EdgeInsets.all(16),
                children: [
                  // Meter info
                  Text(widget.meter.alias ?? widget.meter.meterNumber,
                      style: const TextStyle(fontSize: 13, color: _kSecondary),
                      maxLines: 1, overflow: TextOverflow.ellipsis),
                  const SizedBox(height: 12),

                  // Period selector
                  Container(
                    padding: const EdgeInsets.all(4),
                    decoration: BoxDecoration(
                      color: Colors.white,
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: Row(
                      children: List.generate(3, (i) => Expanded(
                        child: GestureDetector(
                          onTap: () {
                            if (_periodIndex != i) {
                              setState(() => _periodIndex = i);
                              _load();
                            }
                          },
                          child: Container(
                            padding: const EdgeInsets.symmetric(vertical: 10),
                            decoration: BoxDecoration(
                              color: _periodIndex == i ? _kPrimary : Colors.transparent,
                              borderRadius: BorderRadius.circular(10),
                            ),
                            alignment: Alignment.center,
                            child: Text(
                              (AppStringsScope.of(context)?.isSwahili ?? false) ? _periodLabels[i] : _periodLabelsEn[i],
                              style: TextStyle(
                                fontSize: 12,
                                fontWeight: FontWeight.w600,
                                color: _periodIndex == i ? Colors.white : _kSecondary,
                              ),
                            ),
                          ),
                        ),
                      )),
                    ),
                  ),
                  const SizedBox(height: 16),

                  // Summary cards
                  Row(
                    children: [
                      _SummaryCard(
                        label: 'Jumla / Total',
                        value: '${_totalUnits.toStringAsFixed(1)} kWh',
                        subvalue: 'TZS ${_totalCost.toStringAsFixed(0)}',
                      ),
                      const SizedBox(width: 10),
                      _SummaryCard(
                        label: 'Wastani / Avg Daily',
                        value: '${_avgDaily.toStringAsFixed(1)} kWh',
                        subvalue: _previousPeriodComparison != null
                            ? '${_previousPeriodComparison! > 0 ? '+' : ''}${_previousPeriodComparison!.toStringAsFixed(1)}% vs before'
                            : '',
                      ),
                    ],
                  ),
                  const SizedBox(height: 16),

                  // Chart
                  Container(
                    padding: const EdgeInsets.all(16),
                    decoration: BoxDecoration(
                      color: Colors.white,
                      borderRadius: BorderRadius.circular(12),
                      border: Border.all(color: Colors.grey.shade200),
                    ),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text('${_periodLabelsEn[_periodIndex]} Usage',
                            style: const TextStyle(fontSize: 13, fontWeight: FontWeight.w600, color: _kPrimary)),
                        const SizedBox(height: 12),
                        ConsumptionChart(
                          records: _records,
                          period: _periods[_periodIndex],
                          selectedIndex: _selectedBar,
                          onBarTap: (i) => setState(() => _selectedBar = i),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 16),

                  // Selected bar detail
                  if (_selectedBar != null && _selectedBar! < _records.length) ...[
                    Container(
                      padding: const EdgeInsets.all(14),
                      decoration: BoxDecoration(
                        color: Colors.white,
                        borderRadius: BorderRadius.circular(12),
                        border: Border.all(color: Colors.grey.shade200),
                      ),
                      child: Row(
                        children: [
                          Container(
                            width: 40, height: 40,
                            decoration: BoxDecoration(
                              color: _kPrimary.withValues(alpha: 0.08),
                              borderRadius: BorderRadius.circular(10),
                            ),
                            child: const Icon(Icons.electric_bolt_rounded, size: 20, color: _kPrimary),
                          ),
                          const SizedBox(width: 12),
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text('${_records[_selectedBar!].date.day}/${_records[_selectedBar!].date.month}/${_records[_selectedBar!].date.year}',
                                    style: const TextStyle(fontSize: 13, fontWeight: FontWeight.w600, color: _kPrimary)),
                                Text('${_records[_selectedBar!].unitsUsed.toStringAsFixed(1)} kWh',
                                    style: const TextStyle(fontSize: 12, color: _kSecondary)),
                              ],
                            ),
                          ),
                          Text('TZS ${_records[_selectedBar!].cost.toStringAsFixed(0)}',
                              style: const TextStyle(fontSize: 14, fontWeight: FontWeight.w700, color: _kPrimary)),
                        ],
                      ),
                    ),
                  ],

                  // Comparison with previous period
                  if (_previousPeriodComparison != null) ...[
                    const SizedBox(height: 16),
                    Container(
                      padding: const EdgeInsets.all(14),
                      decoration: BoxDecoration(
                        color: _previousPeriodComparison! > 0
                            ? Colors.red.withValues(alpha: 0.06)
                            : const Color(0xFF4CAF50).withValues(alpha: 0.06),
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: Row(
                        children: [
                          Icon(
                            _previousPeriodComparison! > 0
                                ? Icons.trending_up_rounded
                                : Icons.trending_down_rounded,
                            size: 20,
                            color: _previousPeriodComparison! > 0 ? Colors.red : const Color(0xFF4CAF50),
                          ),
                          const SizedBox(width: 10),
                          Expanded(
                            child: Text(
                              (AppStringsScope.of(context)?.isSwahili ?? false)
                                  ? (_previousPeriodComparison! > 0
                                      ? 'Matumizi yameongezeka ${_previousPeriodComparison!.toStringAsFixed(1)}%'
                                      : 'Matumizi yamepungua ${_previousPeriodComparison!.abs().toStringAsFixed(1)}%')
                                  : (_previousPeriodComparison! > 0
                                      ? 'Usage increased ${_previousPeriodComparison!.toStringAsFixed(1)}%'
                                      : 'Usage decreased ${_previousPeriodComparison!.abs().toStringAsFixed(1)}%'),
                              style: TextStyle(
                                fontSize: 12,
                                color: _previousPeriodComparison! > 0 ? Colors.red : const Color(0xFF4CAF50),
                                fontWeight: FontWeight.w500,
                              ),
                              maxLines: 2, overflow: TextOverflow.ellipsis,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                  const SizedBox(height: 32),
                ],
              ),
            ),
    );
  }
}

class _SummaryCard extends StatelessWidget {
  final String label; final String value; final String subvalue;
  const _SummaryCard({required this.label, required this.value, this.subvalue = ''});
  @override
  Widget build(BuildContext context) => Expanded(
    child: Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: Colors.grey.shade200),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(label, style: const TextStyle(fontSize: 10, color: _kSecondary)),
          const SizedBox(height: 4),
          Text(value, style: const TextStyle(fontSize: 16, fontWeight: FontWeight.w700, color: _kPrimary),
              maxLines: 1, overflow: TextOverflow.ellipsis),
          if (subvalue.isNotEmpty)
            Text(subvalue, style: const TextStyle(fontSize: 10, color: _kSecondary),
                maxLines: 1, overflow: TextOverflow.ellipsis),
        ],
      ),
    ),
  );
}
