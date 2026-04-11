// lib/budget/pages/monthly_report_page.dart
import 'dart:io';
import 'dart:math' as math;
import 'dart:ui' as ui;
import 'package:flutter/material.dart';
import 'package:flutter/rendering.dart';
import 'package:path_provider/path_provider.dart';
import 'package:share_plus/share_plus.dart';
import '../../l10n/app_strings_scope.dart';
import '../models/budget_models.dart';
import '../services/budget_service.dart';
import '../../services/expenditure_service.dart';
import '../../services/income_service.dart';
import '../../services/local_storage_service.dart';

// ── Design tokens ────────────────────────────────────────────────────────────
const Color _kPrimary = Color(0xFF1A1A1A);
const Color _kSecondary = Color(0xFF666666);
const Color _kTertiary = Color(0xFF999999);
const Color _kSurface = Color(0xFFFFFFFF);
const Color _kBackground = Color(0xFFFAFAFA);
const Color _kDivider = Color(0xFFE0E0E0);
const Color _kSuccess = Color(0xFF4CAF50);
const Color _kError = Color(0xFFE53935);

/// Monochromatic palette for bar chart segments
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

const List<String> _kMonthsEn = [
  'January', 'February', 'March', 'April', 'May', 'June',
  'July', 'August', 'September', 'October', 'November', 'December',
];
const List<String> _kMonthsSw = [
  'Januari', 'Februari', 'Machi', 'Aprili', 'Mei', 'Juni',
  'Julai', 'Agosti', 'Septemba', 'Oktoba', 'Novemba', 'Desemba',
];

class MonthlyReportPage extends StatefulWidget {
  final int userId;

  const MonthlyReportPage({super.key, required this.userId});

  @override
  State<MonthlyReportPage> createState() => _MonthlyReportPageState();
}

class _MonthlyReportPageState extends State<MonthlyReportPage> {
  // ── State ──────────────────────────────────────────────────────────────────
  final _repaintKey = GlobalKey();

  late int _year;
  late int _month;

  bool _isLoading = true;
  String? _error;

  BudgetPeriod? _period;
  BudgetPeriod? _prevPeriod;
  Map<String, double> _spendingByCategory = {};
  Map<String, double> _prevSpendingByCategory = {};
  Map<String, double> _incomeBySource = {};
  List<BudgetEnvelope> _envelopes = [];
  List<_MonthSpending> _spendingTrend = [];

  @override
  void initState() {
    super.initState();
    final now = DateTime.now();
    _year = now.year;
    _month = now.month;
    _loadData();
  }

  // ── Data loading ───────────────────────────────────────────────────────────

  Future<void> _loadData() async {
    setState(() {
      _isLoading = true;
      _error = null;
    });

    try {
      final storage = await LocalStorageService.getInstance();
      final token = storage.getAuthToken();
      if (token == null) {
        if (!mounted) return;
        setState(() {
          _error = 'Auth token missing';
          _isLoading = false;
        });
        return;
      }

      // Previous month for comparison
      final prevMonth = _month == 1 ? 12 : _month - 1;
      final prevYear = _month == 1 ? _year - 1 : _year;

      final results = await Future.wait([
        BudgetService.getPeriod(token, widget.userId, year: _year, month: _month),
        BudgetService.getPeriod(token, widget.userId, year: prevYear, month: prevMonth),
        ExpenditureService.getExpenditureByCategory(
          token: token,
          year: _year,
          month: _month,
        ),
        ExpenditureService.getExpenditureByCategory(
          token: token,
          year: prevYear,
          month: prevMonth,
        ),
        IncomeService.getIncomeBySource(
          token: token,
          year: _year,
          month: _month,
        ),
        BudgetService.getUserEnvelopes(token, widget.userId),
      ]);

      // Load spending trend (up to 6 months back including current)
      final trendData = <_MonthSpending>[];
      try {
        final trendFutures = <Future<BudgetPeriod?>>[];
        for (int i = 5; i >= 0; i--) {
          var tM = _month - i;
          var tY = _year;
          while (tM <= 0) {
            tM += 12;
            tY -= 1;
          }
          trendFutures.add(
            BudgetService.getPeriod(token, widget.userId, year: tY, month: tM),
          );
        }
        final trendResults = await Future.wait(trendFutures);
        for (int i = 0; i < trendResults.length; i++) {
          final p = trendResults[i];
          if (p != null && p.totalSpent > 0) {
            trendData.add(_MonthSpending(
              year: p.year,
              month: p.month,
              totalSpent: p.totalSpent,
            ));
          }
        }
      } catch (_) {
        // Trend is optional — don't fail the whole page
      }

      if (!mounted) return;
      setState(() {
        _period = results[0] as BudgetPeriod?;
        _prevPeriod = results[1] as BudgetPeriod?;
        _spendingByCategory = results[2] as Map<String, double>;
        _prevSpendingByCategory = results[3] as Map<String, double>;
        _incomeBySource = results[4] as Map<String, double>;
        final envResult = results[5] as EnvelopeListResult;
        _envelopes = envResult.success ? envResult.envelopes : [];
        _spendingTrend = trendData;
        _isLoading = false;
      });
    } catch (e) {
      if (!mounted) return;
      setState(() {
        _error = e.toString();
        _isLoading = false;
      });
    }
  }

  // ── Month navigation ───────────────────────────────────────────────────────

  void _goToPreviousMonth() {
    setState(() {
      if (_month == 1) {
        _month = 12;
        _year -= 1;
      } else {
        _month -= 1;
      }
    });
    _loadData();
  }

  void _goToNextMonth() {
    final now = DateTime.now();
    if (_year == now.year && _month == now.month) return; // Can't go beyond current
    setState(() {
      if (_month == 12) {
        _month = 1;
        _year += 1;
      } else {
        _month += 1;
      }
    });
    _loadData();
  }

  // ── Share report as image ─────────────────────────────────────────────────

  Future<void> _shareReport() async {
    final strings = AppStringsScope.of(context);
    final isSwahili = strings?.isSwahili ?? false;
    try {
      final boundary = _repaintKey.currentContext?.findRenderObject()
          as RenderRepaintBoundary?;
      if (boundary == null) return;

      final image = await boundary.toImage(pixelRatio: 3.0);
      final byteData = await image.toByteData(format: ui.ImageByteFormat.png);
      if (byteData == null) return;

      final bytes = byteData.buffer.asUint8List();
      final tempDir = await getTemporaryDirectory();
      final file = File('${tempDir.path}/tajiri_budget_report.png');
      await file.writeAsBytes(bytes);

      await SharePlus.instance.share(
        ShareParams(
          files: [XFile(file.path)],
          text: isSwahili ? 'Ripoti ya Bajeti — TAJIRI' : 'Budget Report — TAJIRI',
        ),
      );
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            isSwahili
                ? 'Imeshindikana kushiriki: $e'
                : 'Failed to share: $e',
          ),
        ),
      );
    }
  }

  // ── Helpers ────────────────────────────────────────────────────────────────

  String _formatTZS(double amount) {
    if (amount >= 1000000) {
      return 'TZS ${(amount / 1000000).toStringAsFixed(1)}M';
    }
    if (amount >= 1000) {
      return 'TZS ${(amount / 1000).toStringAsFixed(0)}K';
    }
    return 'TZS ${amount.toStringAsFixed(0)}';
  }

  /// Find the envelope display name for a category key
  String _envelopeName(String categoryKey, bool isSwahili) {
    final match = _envelopes.where(
      (e) => e.nameEn.toLowerCase() == categoryKey.toLowerCase() ||
             e.nameSw.toLowerCase() == categoryKey.toLowerCase() ||
             (e.moduleTag ?? '').toLowerCase() == categoryKey.toLowerCase(),
    );
    if (match.isNotEmpty) return match.first.displayName(isSwahili);
    // Fallback: capitalize the key
    if (categoryKey.isEmpty) return categoryKey;
    return categoryKey[0].toUpperCase() + categoryKey.substring(1);
  }

  // ── Build ──────────────────────────────────────────────────────────────────

  @override
  Widget build(BuildContext context) {
    final strings = AppStringsScope.of(context);
    final isSwahili = strings?.isSwahili ?? false;
    final now = DateTime.now();
    final isCurrentMonth = _year == now.year && _month == now.month;

    final monthLabel = isSwahili
        ? '${_kMonthsSw[_month - 1]} $_year'
        : '${_kMonthsEn[_month - 1]} $_year';

    return Scaffold(
      backgroundColor: _kBackground,
      appBar: AppBar(
        backgroundColor: _kSurface,
        elevation: 0,
        title: Text(
          isSwahili ? 'Ripoti ya Mwezi' : 'Monthly Report',
          maxLines: 1,
          overflow: TextOverflow.ellipsis,
          style: const TextStyle(
            fontSize: 18,
            fontWeight: FontWeight.bold,
            color: _kPrimary,
          ),
        ),
        iconTheme: const IconThemeData(color: _kPrimary),
        actions: [
          IconButton(
            icon: const Icon(Icons.share_rounded),
            onPressed: _isLoading ? null : _shareReport,
            tooltip: isSwahili ? 'Shiriki' : 'Share',
          ),
        ],
      ),
      body: SafeArea(
        child: _isLoading
            ? const Center(
                child: CircularProgressIndicator(
                  strokeWidth: 2,
                  color: _kPrimary,
                ),
              )
            : _error != null
                ? Center(
                    child: Padding(
                      padding: const EdgeInsets.all(32),
                      child: Column(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          const Icon(Icons.error_outline_rounded,
                              size: 48, color: _kTertiary),
                          const SizedBox(height: 16),
                          Text(
                            _error!,
                            maxLines: 3,
                            overflow: TextOverflow.ellipsis,
                            textAlign: TextAlign.center,
                            style: const TextStyle(
                              fontSize: 14,
                              color: _kSecondary,
                            ),
                          ),
                          const SizedBox(height: 16),
                          OutlinedButton(
                            onPressed: _loadData,
                            child: Text(isSwahili ? 'Jaribu tena' : 'Retry'),
                          ),
                        ],
                      ),
                    ),
                  )
                : RefreshIndicator(
                    onRefresh: _loadData,
                    child: RepaintBoundary(
                      key: _repaintKey,
                      child: ListView(
                      padding: const EdgeInsets.all(16),
                      children: [
                        _buildMonthSelector(monthLabel, isCurrentMonth),
                        const SizedBox(height: 16),
                        _buildSummaryCard(isSwahili),
                        const SizedBox(height: 24),
                        _buildSectionHeader(
                          isSwahili
                              ? 'MATUMIZI KWA BAHASHA'
                              : 'SPENDING BY ENVELOPE',
                        ),
                        const SizedBox(height: 12),
                        _buildSpendingByEnvelope(isSwahili),
                        const SizedBox(height: 24),
                        _buildSectionHeader(
                          isSwahili
                              ? 'VYANZO VYA MAPATO'
                              : 'INCOME BY SOURCE',
                        ),
                        const SizedBox(height: 12),
                        _buildIncomeBySource(isSwahili),
                        if (_prevPeriod != null) ...[
                          const SizedBox(height: 24),
                          _buildSectionHeader(
                            isSwahili
                                ? 'LINGANISHA NA MWEZI ULIOPITA'
                                : 'MONTH COMPARISON',
                          ),
                          const SizedBox(height: 12),
                          _buildMonthComparison(isSwahili),
                        ],
                        if (_spendingTrend.length >= 2) ...[
                          const SizedBox(height: 24),
                          _buildSectionHeader(
                            isSwahili
                                ? 'MWELEKEO WA MATUMIZI'
                                : 'SPENDING TREND',
                          ),
                          const SizedBox(height: 12),
                          _buildSpendingTrend(isSwahili),
                        ],
                        const SizedBox(height: 32),
                      ],
                    ),
                    ),
                  ),
      ),
    );
  }

  // ── Month selector ─────────────────────────────────────────────────────────

  Widget _buildMonthSelector(String label, bool isCurrentMonth) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        IconButton(
          onPressed: _goToPreviousMonth,
          icon: const Icon(Icons.chevron_left_rounded, color: _kPrimary),
          splashRadius: 24,
        ),
        Text(
          label,
          maxLines: 1,
          overflow: TextOverflow.ellipsis,
          style: const TextStyle(
            fontSize: 16,
            fontWeight: FontWeight.w600,
            color: _kPrimary,
          ),
        ),
        IconButton(
          onPressed: isCurrentMonth ? null : _goToNextMonth,
          icon: Icon(
            Icons.chevron_right_rounded,
            color: isCurrentMonth ? _kDivider : _kPrimary,
          ),
          splashRadius: 24,
        ),
      ],
    );
  }

  // ── Summary card ───────────────────────────────────────────────────────────

  Widget _buildSummaryCard(bool isSwahili) {
    final income = _period?.totalIncome ?? 0;
    final spent = _period?.totalSpent ?? 0;
    final savings = income - spent;
    final savingsRate = income > 0 ? (savings / income * 100) : 0.0;
    final isPositive = savings >= 0;

    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: _kSurface,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.06),
            blurRadius: 4,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Column(
        children: [
          // Income & Spent row
          Row(
            children: [
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      isSwahili ? 'Mapato' : 'Total Income',
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: const TextStyle(fontSize: 12, color: _kTertiary),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      _formatTZS(income),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: const TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.bold,
                        color: _kSuccess,
                      ),
                    ),
                  ],
                ),
              ),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.end,
                  children: [
                    Text(
                      isSwahili ? 'Matumizi' : 'Total Spent',
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: const TextStyle(fontSize: 12, color: _kTertiary),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      _formatTZS(spent),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: const TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.bold,
                        color: _kError,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),
          const Divider(height: 1, color: _kDivider),
          const SizedBox(height: 16),
          // Savings row
          Row(
            children: [
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      isSwahili ? 'Akiba' : 'Savings',
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: const TextStyle(fontSize: 12, color: _kTertiary),
                    ),
                    const SizedBox(height: 4),
                    Row(
                      children: [
                        Icon(
                          isPositive
                              ? Icons.trending_up_rounded
                              : Icons.trending_down_rounded,
                          color: isPositive ? _kSuccess : _kError,
                          size: 18,
                        ),
                        const SizedBox(width: 4),
                        Expanded(
                          child: Text(
                            '${isPositive ? '+' : ''}${_formatTZS(savings)}',
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                            style: TextStyle(
                              fontSize: 16,
                              fontWeight: FontWeight.bold,
                              color: isPositive ? _kSuccess : _kError,
                            ),
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.end,
                  children: [
                    Text(
                      isSwahili ? 'Kiwango cha Akiba' : 'Savings Rate',
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: const TextStyle(fontSize: 12, color: _kTertiary),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      '${savingsRate.toStringAsFixed(1)}%',
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.bold,
                        color: isPositive ? _kSuccess : _kError,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  // ── Section header ─────────────────────────────────────────────────────────

  Widget _buildSectionHeader(String title) {
    return Text(
      title,
      maxLines: 1,
      overflow: TextOverflow.ellipsis,
      style: const TextStyle(
        fontSize: 11,
        fontWeight: FontWeight.w600,
        color: _kTertiary,
        letterSpacing: 0.8,
      ),
    );
  }

  // ── Spending by envelope (horizontal bar chart) ────────────────────────────

  Widget _buildSpendingByEnvelope(bool isSwahili) {
    if (_spendingByCategory.isEmpty) {
      return _buildEmptyCard(
        isSwahili ? 'Hakuna matumizi bado' : 'No spending yet',
      );
    }

    // Sort by amount descending
    final sorted = _spendingByCategory.entries.toList()
      ..sort((a, b) => b.value.compareTo(a.value));
    final totalSpent = sorted.fold(0.0, (sum, e) => sum + e.value);

    // Build a set of over-budget categories
    final overBudgetCategories = <String>{};
    for (final env in _envelopes) {
      if (env.isOverBudget) {
        overBudgetCategories.add(env.nameEn.toLowerCase());
        overBudgetCategories.add(env.nameSw.toLowerCase());
        if (env.moduleTag != null) {
          overBudgetCategories.add(env.moduleTag!.toLowerCase());
        }
      }
    }

    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: _kSurface,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.04),
            blurRadius: 3,
            offset: const Offset(0, 1),
          ),
        ],
      ),
      child: Column(
        children: sorted.asMap().entries.map((entry) {
          final idx = entry.key;
          final category = entry.value.key;
          final amount = entry.value.value;
          final pct = totalSpent > 0 ? amount / totalSpent : 0.0;
          final isOverBudget =
              overBudgetCategories.contains(category.toLowerCase());
          final barColor = isOverBudget
              ? _kError
              : _kChartColors[idx % _kChartColors.length];
          final displayName = _envelopeName(category, isSwahili);

          return Padding(
            padding: EdgeInsets.only(bottom: idx < sorted.length - 1 ? 12 : 0),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Expanded(
                      child: Text(
                        displayName,
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: TextStyle(
                          fontSize: 13,
                          fontWeight: FontWeight.w500,
                          color: isOverBudget ? _kError : _kPrimary,
                        ),
                      ),
                    ),
                    const SizedBox(width: 8),
                    Text(
                      '${_formatTZS(amount)} (${(pct * 100).toStringAsFixed(0)}%)',
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: TextStyle(
                        fontSize: 12,
                        color: isOverBudget ? _kError : _kSecondary,
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 4),
                ClipRRect(
                  borderRadius: BorderRadius.circular(3),
                  child: LinearProgressIndicator(
                    value: pct.clamp(0.0, 1.0),
                    backgroundColor: _kDivider,
                    valueColor: AlwaysStoppedAnimation(barColor),
                    minHeight: 8,
                  ),
                ),
                if (isOverBudget)
                  Padding(
                    padding: const EdgeInsets.only(top: 2),
                    child: Text(
                      isSwahili ? 'Imezidi bajeti' : 'Over budget',
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: const TextStyle(
                        fontSize: 10,
                        fontWeight: FontWeight.w500,
                        color: _kError,
                      ),
                    ),
                  ),
              ],
            ),
          );
        }).toList(),
      ),
    );
  }

  // ── Income by source ───────────────────────────────────────────────────────

  Widget _buildIncomeBySource(bool isSwahili) {
    if (_incomeBySource.isEmpty) {
      return _buildEmptyCard(
        isSwahili ? 'Hakuna mapato bado' : 'No income yet',
      );
    }

    final sorted = _incomeBySource.entries.toList()
      ..sort((a, b) => b.value.compareTo(a.value));
    final total = sorted.fold(0.0, (sum, e) => sum + e.value);

    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: _kSurface,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.04),
            blurRadius: 3,
            offset: const Offset(0, 1),
          ),
        ],
      ),
      child: Column(
        children: sorted.asMap().entries.map((entry) {
          final idx = entry.key;
          final source = entry.value.key;
          final amount = entry.value.value;
          final pct = total > 0 ? amount / total : 0.0;
          final color = _kChartColors[idx % _kChartColors.length];

          // Capitalize source name
          final label = source.isEmpty
              ? source
              : source[0].toUpperCase() + source.substring(1);

          return Padding(
            padding: EdgeInsets.only(bottom: idx < sorted.length - 1 ? 10 : 0),
            child: Row(
              children: [
                Container(
                  width: 10,
                  height: 10,
                  decoration: BoxDecoration(
                    color: color,
                    borderRadius: BorderRadius.circular(3),
                  ),
                ),
                const SizedBox(width: 8),
                Expanded(
                  child: Text(
                    label,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: const TextStyle(fontSize: 13, color: _kPrimary),
                  ),
                ),
                Text(
                  _formatTZS(amount),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: const TextStyle(fontSize: 12, color: _kSecondary),
                ),
                const SizedBox(width: 8),
                Text(
                  '${(pct * 100).toStringAsFixed(0)}%',
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: const TextStyle(
                    fontSize: 11,
                    fontWeight: FontWeight.w600,
                    color: _kTertiary,
                  ),
                ),
              ],
            ),
          );
        }).toList(),
      ),
    );
  }

  // ── Month-over-month comparison ────────────────────────────────────────────

  Widget _buildMonthComparison(bool isSwahili) {
    if (_spendingByCategory.isEmpty && _prevSpendingByCategory.isEmpty) {
      return _buildEmptyCard(
        isSwahili
            ? 'Hakuna data ya kulinganisha'
            : 'No data to compare',
      );
    }

    // Merge all categories from both months
    final allCategories = <String>{
      ..._spendingByCategory.keys,
      ..._prevSpendingByCategory.keys,
    };

    final comparisons = <_ComparisonItem>[];
    for (final cat in allCategories) {
      final current = _spendingByCategory[cat] ?? 0;
      final prev = _prevSpendingByCategory[cat] ?? 0;
      if (prev > 0 || current > 0) {
        final changePercent = prev > 0
            ? ((current - prev) / prev * 100)
            : (current > 0 ? 100.0 : 0.0);
        comparisons.add(_ComparisonItem(
          category: cat,
          currentAmount: current,
          previousAmount: prev,
          changePercent: changePercent,
        ));
      }
    }

    // Sort by absolute change
    comparisons.sort((a, b) =>
        b.changePercent.abs().compareTo(a.changePercent.abs()));

    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: _kSurface,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.04),
            blurRadius: 3,
            offset: const Offset(0, 1),
          ),
        ],
      ),
      child: Column(
        children: comparisons.asMap().entries.map((entry) {
          final idx = entry.key;
          final item = entry.value;
          final isDecrease = item.changePercent < 0;
          final displayName = _envelopeName(item.category, isSwahili);

          return Padding(
            padding: EdgeInsets.only(
              bottom: idx < comparisons.length - 1 ? 10 : 0,
            ),
            child: Row(
              children: [
                Icon(
                  isDecrease
                      ? Icons.arrow_downward_rounded
                      : Icons.arrow_upward_rounded,
                  size: 16,
                  color: isDecrease ? _kSuccess : _kError,
                ),
                const SizedBox(width: 6),
                Expanded(
                  child: Text(
                    displayName,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: const TextStyle(fontSize: 13, color: _kPrimary),
                  ),
                ),
                Text(
                  '${isDecrease ? '' : '+'}${item.changePercent.toStringAsFixed(0)}%',
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: TextStyle(
                    fontSize: 12,
                    fontWeight: FontWeight.w600,
                    color: isDecrease ? _kSuccess : _kError,
                  ),
                ),
                const SizedBox(width: 4),
                Text(
                  isSwahili ? 'vs mwezi uliopita' : 'vs last month',
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: const TextStyle(fontSize: 10, color: _kTertiary),
                ),
              ],
            ),
          );
        }).toList(),
      ),
    );
  }

  // ── Empty state card ───────────────────────────────────────────────────────

  Widget _buildEmptyCard(String message) {
    return Container(
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        color: _kSurface,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.04),
            blurRadius: 3,
            offset: const Offset(0, 1),
          ),
        ],
      ),
      child: Center(
        child: Text(
          message,
          maxLines: 1,
          overflow: TextOverflow.ellipsis,
          style: const TextStyle(fontSize: 14, color: _kTertiary),
        ),
      ),
    );
  }

  // ── Spending trend (horizontal bar chart) ──────────────────────────────────

  Widget _buildSpendingTrend(bool isSwahili) {
    final maxSpent = _spendingTrend.fold<double>(
      0,
      (prev, m) => math.max(prev, m.totalSpent),
    );

    const List<String> shortMonthsEn = [
      'Jan', 'Feb', 'Mar', 'Apr', 'May', 'Jun',
      'Jul', 'Aug', 'Sep', 'Oct', 'Nov', 'Dec',
    ];
    const List<String> shortMonthsSw = [
      'Jan', 'Feb', 'Mac', 'Apr', 'Mei', 'Jun',
      'Jul', 'Ago', 'Sep', 'Okt', 'Nov', 'Des',
    ];

    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: _kSurface,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.04),
            blurRadius: 3,
            offset: const Offset(0, 1),
          ),
        ],
      ),
      child: Column(
        children: _spendingTrend.map((m) {
          final isCurrent = m.year == _year && m.month == _month;
          final barFraction = maxSpent > 0 ? m.totalSpent / maxSpent : 0.0;
          final monthLabel = isSwahili
              ? shortMonthsSw[m.month - 1]
              : shortMonthsEn[m.month - 1];

          return Padding(
            padding: const EdgeInsets.symmetric(vertical: 4),
            child: Row(
              children: [
                SizedBox(
                  width: 36,
                  child: Text(
                    monthLabel,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: TextStyle(
                      fontSize: 12,
                      color: isCurrent ? _kPrimary : _kSecondary,
                      fontWeight: isCurrent
                          ? FontWeight.bold
                          : FontWeight.normal,
                    ),
                  ),
                ),
                const SizedBox(width: 8),
                Expanded(
                  child: LayoutBuilder(
                    builder: (ctx, constraints) {
                      final barWidth =
                          constraints.maxWidth * barFraction.clamp(0.0, 1.0);
                      return Align(
                        alignment: Alignment.centerLeft,
                        child: Container(
                          height: 20,
                          width: math.max(barWidth, 4),
                          decoration: BoxDecoration(
                            color: isCurrent
                                ? _kPrimary
                                : _kPrimary.withValues(alpha: 0.25),
                            borderRadius: BorderRadius.circular(4),
                          ),
                        ),
                      );
                    },
                  ),
                ),
                const SizedBox(width: 8),
                Text(
                  _formatTZS(m.totalSpent),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: TextStyle(
                    fontSize: 12,
                    color: isCurrent ? _kPrimary : _kSecondary,
                    fontWeight: isCurrent
                        ? FontWeight.w600
                        : FontWeight.normal,
                  ),
                ),
              ],
            ),
          );
        }).toList(),
      ),
    );
  }
}

// ── Helper class ─────────────────────────────────────────────────────────────

class _MonthSpending {
  final int year;
  final int month;
  final double totalSpent;

  const _MonthSpending({
    required this.year,
    required this.month,
    required this.totalSpent,
  });
}

class _ComparisonItem {
  final String category;
  final double currentAmount;
  final double previousAmount;
  final double changePercent;

  const _ComparisonItem({
    required this.category,
    required this.currentAmount,
    required this.previousAmount,
    required this.changePercent,
  });
}
