// lib/screens/budget/monthly_report_screen.dart
import 'dart:math' as math;
import 'package:flutter/material.dart';
import '../../models/budget_models.dart';
import '../../services/budget_service.dart';

const Color _kPrimary = Color(0xFF1A1A1A);
const Color _kSecondary = Color(0xFF666666);
const Color _kTertiary = Color(0xFF999999);
const Color _kSurface = Color(0xFFFFFFFF);
const Color _kBackground = Color(0xFFFAFAFA);
const Color _kDivider = Color(0xFFE0E0E0);
const Color _kSuccess = Color(0xFF4CAF50);
const Color _kError = Color(0xFFE53935);

/// Monochromatic colors for chart segments
const List<Color> _kChartColors = [
  Color(0xFF1A1A1A),
  Color(0xFF333333),
  Color(0xFF4D4D4D),
  Color(0xFF666666),
  Color(0xFF808080),
  Color(0xFF999999),
  Color(0xFFB3B3B3),
  Color(0xFFCCCCCC),
  Color(0xFFE0E0E0),
  Color(0xFFEEEEEE),
];

class MonthlyReportScreen extends StatefulWidget {
  final int userId;

  const MonthlyReportScreen({super.key, required this.userId});

  @override
  State<MonthlyReportScreen> createState() => _MonthlyReportScreenState();
}

class _MonthlyReportScreenState extends State<MonthlyReportScreen> {
  final BudgetService _service = BudgetService();
  BudgetPeriod? _period;
  List<BudgetEnvelope> _envelopes = [];
  Map<BudgetSource, double> _incomeBreakdown = {};
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _loadData();
  }

  Future<void> _loadData() async {
    setState(() => _isLoading = true);
    final results = await Future.wait([
      _service.getCurrentPeriod(),
      _service.getEnvelopes(),
      _service.getCurrentIncomeBreakdown(),
    ]);
    if (mounted) {
      setState(() {
        _period = results[0] as BudgetPeriod;
        _envelopes = results[1] as List<BudgetEnvelope>;
        _incomeBreakdown = results[2] as Map<BudgetSource, double>;
        _isLoading = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    final now = DateTime.now();
    final months = [
      'Januari', 'Februari', 'Machi', 'Aprili', 'Mei', 'Juni',
      'Julai', 'Agosti', 'Septemba', 'Oktoba', 'Novemba', 'Desemba'
    ];

    return Scaffold(
      backgroundColor: _kBackground,
      appBar: AppBar(
        backgroundColor: _kSurface,
        elevation: 0,
        title: Text(
          'Ripoti — ${months[now.month - 1]} ${now.year}',
          style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: _kPrimary),
        ),
        iconTheme: const IconThemeData(color: _kPrimary),
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator(strokeWidth: 2))
          : ListView(
              padding: const EdgeInsets.all(16),
              children: [
                _buildSummaryCard(),
                const SizedBox(height: 20),
                const Text('VYANZO VYA MAPATO', style: TextStyle(fontSize: 11, fontWeight: FontWeight.w600, color: _kTertiary, letterSpacing: 0.8)),
                const SizedBox(height: 12),
                _buildIncomeBreakdown(),
                const SizedBox(height: 20),
                const Text('MATUMIZI KWA BAHASHA', style: TextStyle(fontSize: 11, fontWeight: FontWeight.w600, color: _kTertiary, letterSpacing: 0.8)),
                const SizedBox(height: 12),
                _buildEnvelopeBreakdown(),
              ],
            ),
    );
  }

  Widget _buildSummaryCard() {
    final p = _period!;
    final net = p.totalIncome - p.totalSpent;
    final isPositive = net >= 0;

    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: _kSurface,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [BoxShadow(color: Colors.black.withValues(alpha: 0.06), blurRadius: 4, offset: const Offset(0, 2))],
      ),
      child: Column(
        children: [
          Row(
            children: [
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text('Mapato', style: TextStyle(fontSize: 12, color: _kTertiary)),
                    const SizedBox(height: 4),
                    Text('TZS ${p.totalIncome.toStringAsFixed(0)}', style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: _kSuccess)),
                  ],
                ),
              ),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.end,
                  children: [
                    const Text('Matumizi', style: TextStyle(fontSize: 12, color: _kTertiary)),
                    const SizedBox(height: 4),
                    Text('TZS ${p.totalSpent.toStringAsFixed(0)}', style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: _kError)),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),
          const Divider(height: 1, color: _kDivider),
          const SizedBox(height: 16),
          Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(
                isPositive ? Icons.trending_up_rounded : Icons.trending_down_rounded,
                color: isPositive ? _kSuccess : _kError,
                size: 20,
              ),
              const SizedBox(width: 8),
              Text(
                '${isPositive ? '+' : ''}TZS ${net.toStringAsFixed(0)}',
                style: TextStyle(
                  fontSize: 20,
                  fontWeight: FontWeight.bold,
                  color: isPositive ? _kSuccess : _kError,
                ),
              ),
            ],
          ),
          const SizedBox(height: 4),
          Text(
            isPositive ? 'Umebakiza mwezi huu' : 'Umetumia zaidi ya mapato',
            style: const TextStyle(fontSize: 12, color: _kTertiary),
          ),
        ],
      ),
    );
  }

  Widget _buildIncomeBreakdown() {
    if (_incomeBreakdown.isEmpty) {
      return const Padding(
        padding: EdgeInsets.all(20),
        child: Center(child: Text('Hakuna mapato bado', style: TextStyle(color: _kTertiary))),
      );
    }

    final total = _incomeBreakdown.values.fold(0.0, (a, b) => a + b);
    final entries = _incomeBreakdown.entries.toList()..sort((a, b) => b.value.compareTo(a.value));

    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: _kSurface,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [BoxShadow(color: Colors.black.withValues(alpha: 0.04), blurRadius: 3, offset: const Offset(0, 1))],
      ),
      child: Column(
        children: [
          ...entries.asMap().entries.map((e) {
            final entry = e.value;
            final pct = total > 0 ? entry.value / total : 0.0;
            final color = _kChartColors[e.key % _kChartColors.length];
            return Padding(
              padding: const EdgeInsets.only(bottom: 10),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Text(entry.key.label, style: const TextStyle(fontSize: 12, color: _kPrimary)),
                      Text('TZS ${entry.value.toStringAsFixed(0)} (${(pct * 100).toStringAsFixed(0)}%)', style: const TextStyle(fontSize: 11, color: _kSecondary)),
                    ],
                  ),
                  const SizedBox(height: 4),
                  ClipRRect(
                    borderRadius: BorderRadius.circular(3),
                    child: LinearProgressIndicator(
                      value: pct,
                      backgroundColor: _kDivider,
                      valueColor: AlwaysStoppedAnimation(color),
                      minHeight: 6,
                    ),
                  ),
                ],
              ),
            );
          }),
        ],
      ),
    );
  }

  Widget _buildEnvelopeBreakdown() {
    final spentEnvelopes = _envelopes.where((e) => e.spentAmount > 0).toList()
      ..sort((a, b) => b.spentAmount.compareTo(a.spentAmount));

    if (spentEnvelopes.isEmpty) {
      return const Padding(
        padding: EdgeInsets.all(20),
        child: Center(child: Text('Hakuna matumizi bado', style: TextStyle(color: _kTertiary))),
      );
    }

    final totalSpent = spentEnvelopes.fold(0.0, (a, b) => a + b.spentAmount);

    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: _kSurface,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [BoxShadow(color: Colors.black.withValues(alpha: 0.04), blurRadius: 3, offset: const Offset(0, 1))],
      ),
      child: Column(
        children: [
          // Stacked bar
          ClipRRect(
            borderRadius: BorderRadius.circular(6),
            child: SizedBox(
              height: 12,
              child: Row(
                children: spentEnvelopes.asMap().entries.map((e) {
                  final flex = (e.value.spentAmount / totalSpent * 100).round();
                  if (flex <= 0) return const SizedBox.shrink();
                  return Flexible(
                    flex: math.max(flex, 1),
                    child: Container(color: _kChartColors[e.key % _kChartColors.length]),
                  );
                }).toList(),
              ),
            ),
          ),
          const SizedBox(height: 16),
          // Legend
          ...spentEnvelopes.asMap().entries.map((e) {
            final env = e.value;
            final pct = totalSpent > 0 ? (env.spentAmount / totalSpent * 100) : 0.0;
            final color = _kChartColors[e.key % _kChartColors.length];
            return Padding(
              padding: const EdgeInsets.only(bottom: 8),
              child: Row(
                children: [
                  Container(width: 10, height: 10, decoration: BoxDecoration(color: color, borderRadius: BorderRadius.circular(3))),
                  const SizedBox(width: 8),
                  Expanded(child: Text(env.name, style: const TextStyle(fontSize: 12, color: _kPrimary))),
                  Text('TZS ${env.spentAmount.toStringAsFixed(0)}', style: const TextStyle(fontSize: 12, color: _kSecondary)),
                  const SizedBox(width: 8),
                  Text('${pct.toStringAsFixed(0)}%', style: const TextStyle(fontSize: 11, fontWeight: FontWeight.w600, color: _kTertiary)),
                ],
              ),
            );
          }),
        ],
      ),
    );
  }
}
