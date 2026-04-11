// lib/dawasco/pages/consumption_dashboard_page.dart
import 'package:flutter/material.dart';
import '../../l10n/app_strings_scope.dart';
import '../models/dawasco_models.dart';
import '../services/dawasco_service.dart';
import '../widgets/consumption_chart.dart';

const Color _kPrimary = Color(0xFF1A1A1A);
const Color _kSecondary = Color(0xFF666666);
const Color _kBg = Color(0xFFFAFAFA);

class ConsumptionDashboardPage extends StatefulWidget {
  final String? accountNumber;
  const ConsumptionDashboardPage({super.key, this.accountNumber});
  @override
  State<ConsumptionDashboardPage> createState() => _ConsumptionDashboardPageState();
}

class _ConsumptionDashboardPageState extends State<ConsumptionDashboardPage> {
  List<ConsumptionRecord> _records = [];
  bool _loading = true;
  String? _error;

  @override
  void initState() {
    super.initState();
    _load();
  }

  bool get _sw => AppStringsScope.of(context)?.isSwahili ?? false;

  Future<void> _load() async {
    if (widget.accountNumber == null) {
      setState(() { _loading = false; _error = _sw ? 'Hakuna akaunti' : 'No account'; });
      return;
    }
    setState(() { _loading = true; _error = null; });
    try {
      final result = await DawascoService.getConsumption(widget.accountNumber!);
      if (!mounted) return;
      setState(() {
        _loading = false;
        if (result.success) {
          _records = result.items;
        } else {
          _error = result.message;
        }
      });
    } catch (e) {
      if (!mounted) return;
      setState(() { _loading = false; _error = '$e'; });
    }
  }

  @override
  Widget build(BuildContext context) {
    final sw = _sw;

    // Compute stats
    final totalM3 = _records.fold<double>(0, (s, r) => s + r.consumptionM3);
    final totalCost = _records.fold<double>(0, (s, r) => s + r.cost);
    final avgMonthlyM3 = _records.isNotEmpty ? totalM3 / _records.length : 0.0;
    final avgDailyM3 = avgMonthlyM3 / 30;

    return Scaffold(
      backgroundColor: _kBg,
      appBar: AppBar(
        title: Text(sw ? 'Matumizi ya Maji' : 'Water Usage',
            style: const TextStyle(color: _kPrimary, fontWeight: FontWeight.w700, fontSize: 16)),
        backgroundColor: Colors.white, elevation: 0, iconTheme: const IconThemeData(color: _kPrimary),
      ),
      body: _loading
          ? const Center(child: CircularProgressIndicator(strokeWidth: 2, color: _kPrimary))
          : _error != null
              ? Center(child: Column(mainAxisSize: MainAxisSize.min, children: [
                  Text(_error!, style: const TextStyle(color: _kSecondary, fontSize: 13),
                      maxLines: 3, overflow: TextOverflow.ellipsis, textAlign: TextAlign.center),
                  const SizedBox(height: 12),
                  TextButton(onPressed: _load, child: Text(sw ? 'Jaribu tena' : 'Retry',
                      style: const TextStyle(color: _kPrimary))),
                ]))
              : RefreshIndicator(
                  onRefresh: _load,
                  color: _kPrimary,
                  child: ListView(padding: const EdgeInsets.all(16), children: [
                    // Summary cards
                    Row(children: [
                      _StatCard(
                        label: sw ? 'Wastani/Mwezi' : 'Avg/Month',
                        value: '${avgMonthlyM3.toStringAsFixed(1)} m\u00B3',
                        icon: Icons.water_drop_rounded,
                      ),
                      const SizedBox(width: 10),
                      _StatCard(
                        label: sw ? 'Wastani/Siku' : 'Avg/Day',
                        value: '${avgDailyM3.toStringAsFixed(1)} m\u00B3',
                        icon: Icons.today_rounded,
                      ),
                    ]),
                    const SizedBox(height: 10),
                    Row(children: [
                      _StatCard(
                        label: sw ? 'Jumla Matumizi' : 'Total Usage',
                        value: '${totalM3.toStringAsFixed(0)} m\u00B3',
                        icon: Icons.analytics_rounded,
                      ),
                      const SizedBox(width: 10),
                      _StatCard(
                        label: sw ? 'Jumla Gharama' : 'Total Cost',
                        value: 'TZS ${totalCost.toStringAsFixed(0)}',
                        icon: Icons.payments_rounded,
                      ),
                    ]),
                    const SizedBox(height: 24),

                    // Chart
                    Container(
                      padding: const EdgeInsets.all(16),
                      decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(12)),
                      child: ConsumptionChart(records: _records, isSwahili: sw),
                    ),
                    const SizedBox(height: 20),

                    // Cost trends
                    Text(sw ? 'Gharama kwa Mwezi' : 'Monthly Costs',
                        style: const TextStyle(fontSize: 14, fontWeight: FontWeight.w600, color: _kPrimary)),
                    const SizedBox(height: 10),
                    ..._records.map((r) => Container(
                      margin: const EdgeInsets.only(bottom: 8),
                      padding: const EdgeInsets.all(12),
                      decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(10)),
                      child: Row(children: [
                        Container(
                          width: 40, height: 40,
                          decoration: BoxDecoration(
                            color: _kPrimary.withValues(alpha: 0.08),
                            borderRadius: BorderRadius.circular(8),
                          ),
                          child: Center(child: Text(r.month.length >= 7 ? r.month.substring(5, 7) : r.month,
                              style: const TextStyle(fontSize: 13, fontWeight: FontWeight.w700, color: _kPrimary))),
                        ),
                        const SizedBox(width: 12),
                        Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                          Text(r.month,
                              style: const TextStyle(fontSize: 13, fontWeight: FontWeight.w500, color: _kPrimary),
                              maxLines: 1, overflow: TextOverflow.ellipsis),
                          Text('${r.consumptionM3.toStringAsFixed(1)} m\u00B3',
                              style: const TextStyle(fontSize: 11, color: _kSecondary),
                              maxLines: 1, overflow: TextOverflow.ellipsis),
                        ])),
                        Text('TZS ${r.cost.toStringAsFixed(0)}',
                            style: const TextStyle(fontSize: 13, fontWeight: FontWeight.w600, color: _kPrimary),
                            maxLines: 1, overflow: TextOverflow.ellipsis),
                      ]),
                    )),
                    const SizedBox(height: 32),
                  ]),
                ),
    );
  }
}

class _StatCard extends StatelessWidget {
  final String label;
  final String value;
  final IconData icon;
  const _StatCard({required this.label, required this.value, required this.icon});

  @override
  Widget build(BuildContext context) {
    return Expanded(
      child: Container(
        padding: const EdgeInsets.all(14),
        decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(12)),
        child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
          Icon(icon, size: 20, color: _kPrimary.withValues(alpha: 0.5)),
          const SizedBox(height: 8),
          Text(value, style: const TextStyle(fontSize: 16, fontWeight: FontWeight.w700, color: _kPrimary),
              maxLines: 1, overflow: TextOverflow.ellipsis),
          const SizedBox(height: 2),
          Text(label, style: const TextStyle(fontSize: 11, color: _kSecondary),
              maxLines: 1, overflow: TextOverflow.ellipsis),
        ]),
      ),
    );
  }
}
