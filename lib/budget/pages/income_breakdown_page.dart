// lib/budget/pages/income_breakdown_page.dart
import 'package:flutter/material.dart';
import '../../l10n/app_strings_scope.dart';
import '../models/budget_models.dart';
import '../../services/income_service.dart';
import '../../services/local_storage_service.dart';
import '../widgets/income_source_tile.dart';

// DESIGN.md tokens
const Color _kBackground = Color(0xFFFAFAFA);
const Color _kSurface = Color(0xFFFFFFFF);
const Color _kPrimary = Color(0xFF1A1A1A);
const Color _kSecondary = Color(0xFF666666);
const Color _kTertiary = Color(0xFF999999);
const Color _kDivider = Color(0xFFE0E0E0);
const Color _kSuccess = Color(0xFF4CAF50);
const Color _kError = Color(0xFFE53935);

/// Monochromatic bar colors
const List<Color> _kBarColors = [
  Color(0xFF1A1A1A),
  Color(0xFF333333),
  Color(0xFF4D4D4D),
  Color(0xFF666666),
  Color(0xFF808080),
  Color(0xFF999999),
  Color(0xFFB3B3B3),
  Color(0xFFCCCCCC),
];

class IncomeBreakdownPage extends StatefulWidget {
  final int userId;

  const IncomeBreakdownPage({super.key, required this.userId});

  @override
  State<IncomeBreakdownPage> createState() => _IncomeBreakdownPageState();
}

class _IncomeBreakdownPageState extends State<IncomeBreakdownPage> {
  bool _isLoading = true;
  String? _error;
  String _token = '';
  bool _isSwahili = false;

  // Data
  IncomeSummary? _summary;
  Map<String, double> _bySource = {};
  List<IncomeRecord> _records = [];

  // Period toggle: 'weekly' or 'monthly'
  String _period = 'monthly';

  @override
  void initState() {
    super.initState();
    _init();
  }

  Future<void> _init() async {
    final storage = await LocalStorageService.getInstance();
    final token = storage.getAuthToken();
    if (token == null || token.isEmpty) {
      if (mounted) setState(() => _error = 'Auth required');
      return;
    }
    _token = token;
    _loadData();
  }

  Future<void> _loadData() async {
    setState(() {
      _isLoading = true;
      _error = null;
    });

    try {
      final now = DateTime.now();
      final results = await Future.wait([
        IncomeService.getIncomeSummary(token: _token, period: _period),
        IncomeService.getIncomeBySource(
          token: _token,
          year: now.year,
          month: now.month,
        ),
        IncomeService.getIncome(token: _token, perPage: 100),
      ]);

      if (!mounted) return;
      setState(() {
        _summary = results[0] as IncomeSummary?;
        _bySource = results[1] as Map<String, double>;
        final listResult = results[2] as IncomeListResult;
        _records = listResult.records;
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

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    final strings = AppStringsScope.of(context);
    _isSwahili = strings?.isSwahili ?? false;
  }

  String _formatTZS(double value) {
    if (value >= 1000000) {
      return 'TZS ${(value / 1000000).toStringAsFixed(1)}M';
    }
    if (value >= 1000) {
      return 'TZS ${(value / 1000).toStringAsFixed(0)}K';
    }
    return 'TZS ${value.toStringAsFixed(0)}';
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: _kBackground,
      appBar: AppBar(
        backgroundColor: _kSurface,
        elevation: 0,
        title: Text(
          _isSwahili ? 'Mapato' : 'Income',
          style: const TextStyle(
            fontSize: 18,
            fontWeight: FontWeight.bold,
            color: _kPrimary,
          ),
        ),
        iconTheme: const IconThemeData(color: _kPrimary),
      ),
      body: SafeArea(
        child: _isLoading
            ? const Center(
                child: CircularProgressIndicator(strokeWidth: 2),
              )
            : _error != null
                ? Center(
                    child: Padding(
                      padding: const EdgeInsets.all(24),
                      child: Column(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          const Icon(Icons.error_outline_rounded,
                              size: 48, color: _kTertiary),
                          const SizedBox(height: 16),
                          Text(
                            _error!,
                            textAlign: TextAlign.center,
                            maxLines: 3,
                            overflow: TextOverflow.ellipsis,
                            style: const TextStyle(
                              color: _kSecondary,
                              fontSize: 14,
                            ),
                          ),
                          const SizedBox(height: 16),
                          OutlinedButton(
                            onPressed: _loadData,
                            child: Text(
                              _isSwahili ? 'Jaribu tena' : 'Retry',
                            ),
                          ),
                        ],
                      ),
                    ),
                  )
                : RefreshIndicator(
                    onRefresh: _loadData,
                    child: ListView(
                      padding: const EdgeInsets.all(16),
                      children: [
                        _buildTotalIncomeCard(),
                        const SizedBox(height: 16),
                        _buildPeriodToggle(),
                        const SizedBox(height: 20),
                        _buildSourceBreakdownSection(),
                        const SizedBox(height: 20),
                        _buildTopIncomeDays(),
                        const SizedBox(height: 20),
                        _buildIncomeListSection(),
                      ],
                    ),
                  ),
      ),
    );
  }

  Widget _buildTotalIncomeCard() {
    final total = _summary?.totalIncome ?? 0;
    final trend = _summary?.trend ?? 0;
    final trendUp = trend >= 0;

    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: _kSurface,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: _kDivider),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            _isSwahili ? 'Jumla ya Mapato' : 'Total Income',
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            style: const TextStyle(
              color: _kSecondary,
              fontSize: 13,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            _formatTZS(total),
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            style: const TextStyle(
              color: _kPrimary,
              fontSize: 28,
              fontWeight: FontWeight.bold,
            ),
          ),
          if (trend != 0) ...[
            const SizedBox(height: 8),
            Row(
              children: [
                Icon(
                  trendUp
                      ? Icons.arrow_upward_rounded
                      : Icons.arrow_downward_rounded,
                  size: 16,
                  color: trendUp ? _kSuccess : _kError,
                ),
                const SizedBox(width: 4),
                Text(
                  '${trend.abs().toStringAsFixed(1)}% ${_isSwahili ? 'vs mwezi uliopita' : 'vs last month'}',
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: TextStyle(
                    color: trendUp ? _kSuccess : _kError,
                    fontSize: 13,
                    fontWeight: FontWeight.w500,
                  ),
                ),
              ],
            ),
          ],
        ],
      ),
    );
  }

  Widget _buildPeriodToggle() {
    return Row(
      children: [
        _buildToggleChip(
          label: _isSwahili ? 'Wiki' : 'Weekly',
          isSelected: _period == 'weekly',
          onTap: () {
            if (_period != 'weekly') {
              _period = 'weekly';
              _loadData();
            }
          },
        ),
        const SizedBox(width: 8),
        _buildToggleChip(
          label: _isSwahili ? 'Mwezi' : 'Monthly',
          isSelected: _period == 'monthly',
          onTap: () {
            if (_period != 'monthly') {
              _period = 'monthly';
              _loadData();
            }
          },
        ),
      ],
    );
  }

  Widget _buildToggleChip({
    required String label,
    required bool isSelected,
    required VoidCallback onTap,
  }) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
        decoration: BoxDecoration(
          color: isSelected ? _kPrimary : _kSurface,
          borderRadius: BorderRadius.circular(20),
          border: Border.all(
            color: isSelected ? _kPrimary : _kDivider,
          ),
        ),
        child: Text(
          label,
          maxLines: 1,
          overflow: TextOverflow.ellipsis,
          style: TextStyle(
            color: isSelected ? _kSurface : _kSecondary,
            fontSize: 13,
            fontWeight: FontWeight.w500,
          ),
        ),
      ),
    );
  }

  Widget _buildSourceBreakdownSection() {
    if (_bySource.isEmpty) return const SizedBox.shrink();

    final total = _bySource.values.fold<double>(0, (a, b) => a + b);
    if (total <= 0) return const SizedBox.shrink();

    // Sort by amount descending
    final sorted = _bySource.entries.toList()
      ..sort((a, b) => b.value.compareTo(a.value));

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          _isSwahili
              ? 'MAPATO KWA CHANZO'
              : 'INCOME BY SOURCE',
          maxLines: 1,
          overflow: TextOverflow.ellipsis,
          style: const TextStyle(
            fontSize: 11,
            fontWeight: FontWeight.w600,
            color: _kTertiary,
            letterSpacing: 0.8,
          ),
        ),
        const SizedBox(height: 12),
        Container(
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            color: _kSurface,
            borderRadius: BorderRadius.circular(12),
            border: Border.all(color: _kDivider),
          ),
          child: Column(
            children: [
              for (int i = 0; i < sorted.length; i++) ...[
                if (i > 0) const SizedBox(height: 12),
                _buildSourceBar(
                  source: sorted[i].key,
                  amount: sorted[i].value,
                  total: total,
                  color: _kBarColors[i % _kBarColors.length],
                ),
              ],
            ],
          ),
        ),
      ],
    );
  }

  static String _sourceLabel(String source, bool isSwahili) {
    const labels = {
      'top_up': ['Top Up', 'Jaza Mkoba'],
      'transfer_in': ['Transfer Received', 'Uhamisho Ulipokelewa'],
      'payment_received': ['Payment Received', 'Malipo Yalipokelewa'],
      'creator_subscription': ['Subscriptions', 'Usajili'],
      'creator_tip': ['Tips', 'Tuzo'],
      'creator_payout': ['Creator Payout', 'Malipo ya Ubunifu'],
      'creator_fund': ['Creator Fund', 'Mfuko wa Ubunifu'],
      'shop_sale': ['Shop Sales', 'Mauzo ya Duka'],
      'tajirika_job': ['Service Earnings', 'Mapato ya Huduma'],
      'tajirika_payout': ['Partner Payout', 'Malipo ya Mshirika'],
      'michango_withdrawal': ['Michango Withdrawal', 'Utoaji wa Michango'],
      'ad_revenue': ['Ad Revenue', 'Mapato ya Matangazo'],
      'stream_gift': ['Stream Gifts', 'Zawadi za Live'],
      'event_ticket': ['Ticket Sales', 'Mauzo ya Tiketi'],
      'kikoba_payout': ['Kikoba Payout', 'Malipo ya Kikoba'],
      'salary': ['Salary', 'Mshahara'],
      'manual': ['Manual Entry', 'Ingizo la Mkono'],
      'other': ['Other', 'Nyingine'],
    };
    final pair = labels[source];
    if (pair == null) return source.replaceAll('_', ' ');
    return isSwahili ? pair[1] : pair[0];
  }

  Widget _buildSourceBar({
    required String source,
    required double amount,
    required double total,
    required Color color,
  }) {
    final pct = total > 0 ? (amount / total) : 0.0;
    final displaySource = _sourceLabel(source, _isSwahili);

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            Expanded(
              child: Text(
                displaySource,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: const TextStyle(
                  color: _kPrimary,
                  fontSize: 13,
                  fontWeight: FontWeight.w500,
                ),
              ),
            ),
            Text(
              '${(pct * 100).toStringAsFixed(0)}%',
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: const TextStyle(
                color: _kSecondary,
                fontSize: 12,
              ),
            ),
            const SizedBox(width: 8),
            Text(
              _formatTZS(amount),
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: const TextStyle(
                color: _kPrimary,
                fontSize: 13,
                fontWeight: FontWeight.w600,
              ),
            ),
          ],
        ),
        const SizedBox(height: 6),
        ClipRRect(
          borderRadius: BorderRadius.circular(3),
          child: LinearProgressIndicator(
            value: pct.clamp(0.0, 1.0),
            minHeight: 6,
            backgroundColor: _kDivider,
            valueColor: AlwaysStoppedAnimation<Color>(color),
          ),
        ),
      ],
    );
  }

  Widget _buildTopIncomeDays() {
    if (_records.isEmpty) return const SizedBox.shrink();

    // Group income by day for current month
    final now = DateTime.now();
    final dailyIncome = <DateTime, double>{};
    for (final r in _records) {
      if (r.date.year == now.year && r.date.month == now.month) {
        final dayKey = DateTime(r.date.year, r.date.month, r.date.day);
        dailyIncome[dayKey] = (dailyIncome[dayKey] ?? 0) + r.amount;
      }
    }

    if (dailyIncome.isEmpty) return const SizedBox.shrink();

    // Sort by amount descending, take top 5
    final sorted = dailyIncome.entries.toList()
      ..sort((a, b) => b.value.compareTo(a.value));
    final top = sorted.take(5).toList();

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          _isSwahili
              ? 'SIKU ZENYE MAPATO ZAIDI'
              : 'TOP INCOME DAYS',
          maxLines: 1,
          overflow: TextOverflow.ellipsis,
          style: const TextStyle(
            fontSize: 11,
            fontWeight: FontWeight.w600,
            color: _kTertiary,
            letterSpacing: 0.8,
          ),
        ),
        const SizedBox(height: 12),
        Container(
          padding: const EdgeInsets.all(12),
          decoration: BoxDecoration(
            color: _kSurface,
            borderRadius: BorderRadius.circular(12),
            border: Border.all(color: _kDivider),
          ),
          child: Column(
            children: top.asMap().entries.map((entry) {
              final idx = entry.key;
              final day = entry.value.key;
              final amount = entry.value.value;
              final dateStr =
                  '${day.day.toString().padLeft(2, '0')}/${day.month.toString().padLeft(2, '0')}';

              return Padding(
                padding: EdgeInsets.only(
                  top: idx > 0 ? 8 : 0,
                  bottom: idx < top.length - 1 ? 8 : 0,
                ),
                child: Row(
                  children: [
                    Container(
                      width: 28,
                      height: 28,
                      decoration: BoxDecoration(
                        color: _kSuccess.withValues(alpha: 0.1),
                        shape: BoxShape.circle,
                      ),
                      child: Center(
                        child: Text(
                          '${idx + 1}',
                          style: const TextStyle(
                            fontSize: 12,
                            fontWeight: FontWeight.bold,
                            color: _kSuccess,
                          ),
                        ),
                      ),
                    ),
                    const SizedBox(width: 12),
                    Text(
                      dateStr,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: const TextStyle(
                        fontSize: 13,
                        color: _kSecondary,
                      ),
                    ),
                    const Spacer(),
                    Text(
                      '+${_formatTZS(amount)}',
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: const TextStyle(
                        fontSize: 14,
                        fontWeight: FontWeight.w600,
                        color: _kSuccess,
                      ),
                    ),
                  ],
                ),
              );
            }).toList(),
          ),
        ),
      ],
    );
  }

  Widget _buildIncomeListSection() {
    if (_records.isEmpty) {
      return Container(
        padding: const EdgeInsets.all(24),
        alignment: Alignment.center,
        child: Text(
          _isSwahili
              ? 'Hakuna mapato bado'
              : 'No income recorded yet',
          maxLines: 2,
          overflow: TextOverflow.ellipsis,
          style: const TextStyle(color: _kSecondary, fontSize: 14),
        ),
      );
    }

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          _isSwahili ? 'VYANZO VYA MAPATO' : 'INCOME SOURCES',
          maxLines: 1,
          overflow: TextOverflow.ellipsis,
          style: const TextStyle(
            fontSize: 11,
            fontWeight: FontWeight.w600,
            color: _kTertiary,
            letterSpacing: 0.8,
          ),
        ),
        const SizedBox(height: 12),
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
          decoration: BoxDecoration(
            color: _kSurface,
            borderRadius: BorderRadius.circular(12),
            border: Border.all(color: _kDivider),
          ),
          child: Column(
            children: [
              for (int i = 0; i < _records.length; i++) ...[
                if (i > 0)
                  const Divider(height: 1, color: _kDivider),
                IncomeSourceTile.fromRecord(
                  record: _records[i],
                  isSwahili: _isSwahili,
                ),
              ],
            ],
          ),
        ),
      ],
    );
  }
}
