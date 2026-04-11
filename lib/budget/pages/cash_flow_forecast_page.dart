// lib/budget/pages/cash_flow_forecast_page.dart
import 'package:flutter/material.dart';
import '../../l10n/app_strings_scope.dart';
import '../models/budget_models.dart';
import '../../services/expenditure_service.dart';
import '../../services/income_service.dart';
import '../../services/local_storage_service.dart';
import '../../services/wallet_service.dart';

// DESIGN.md tokens
const Color _kBackground = Color(0xFFFAFAFA);
const Color _kSurface = Color(0xFFFFFFFF);
const Color _kPrimary = Color(0xFF1A1A1A);
const Color _kSecondary = Color(0xFF666666);
const Color _kTertiary = Color(0xFF999999);
const Color _kDivider = Color(0xFFE0E0E0);
const Color _kSuccess = Color(0xFF4CAF50);
const Color _kError = Color(0xFFE53935);
const Color _kWarning = Color(0xFFFF9800);

class CashFlowForecastPage extends StatefulWidget {
  final int userId;

  const CashFlowForecastPage({super.key, required this.userId});

  @override
  State<CashFlowForecastPage> createState() =>
      _CashFlowForecastPageState();
}

class _CashFlowForecastPageState extends State<CashFlowForecastPage> {
  bool _isLoading = true;
  String? _error;
  String _token = '';
  bool _isSwahili = false;

  // Data
  double _walletBalance = 0;
  List<RecurringIncome> _recurringIncome = [];
  List<RecurringExpense> _recurringExpenses = [];
  List<UpcomingExpense> _upcomingExpenses = [];

  // Computed: 30-day projection
  List<_DayProjection> _projection = [];
  double _endOfMonthBalance = 0;
  bool _goesNegative = false;

  // What-if scenario
  final TextEditingController _whatIfController = TextEditingController();
  double? _whatIfAmount;

  @override
  void initState() {
    super.initState();
    _init();
  }

  @override
  void dispose() {
    _whatIfController.dispose();
    super.dispose();
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
      final walletService = WalletService();
      final results = await Future.wait([
        walletService.getWallet(widget.userId),
        IncomeService.getRecurringIncome(token: _token),
        ExpenditureService.getRecurringExpenses(token: _token),
        ExpenditureService.getUpcomingExpenses(token: _token),
      ]);

      if (!mounted) return;

      final walletResult = results[0] as dynamic;
      final balance =
          walletResult.success ? (walletResult.wallet?.balance ?? 0.0) : 0.0;

      setState(() {
        _walletBalance = balance;
        _recurringIncome = results[1] as List<RecurringIncome>;
        _recurringExpenses = results[2] as List<RecurringExpense>;
        _upcomingExpenses = results[3] as List<UpcomingExpense>;
        _computeProjection();
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

  void _computeProjection() {
    final now = DateTime.now();
    final today = DateTime(now.year, now.month, now.day);
    double runningBalance = _walletBalance;
    _goesNegative = false;
    _projection = [];

    for (int i = 0; i < 30; i++) {
      final day = today.add(Duration(days: i));
      double dayIncome = 0;
      double dayExpense = 0;

      // Check recurring income expected on this day
      for (final ri in _recurringIncome) {
        if (_matchesDay(ri.nextExpected, ri.frequency, day)) {
          dayIncome += ri.amount;
        }
      }

      // Check recurring expenses expected on this day
      for (final re in _recurringExpenses) {
        if (_matchesDay(re.nextExpected, re.frequency, day)) {
          dayExpense += re.amount;
        }
      }

      // Check upcoming expenses on this day
      for (final ue in _upcomingExpenses) {
        if (ue.expectedDate != null &&
            ue.expectedDate!.year == day.year &&
            ue.expectedDate!.month == day.month &&
            ue.expectedDate!.day == day.day) {
          dayExpense += ue.amount;
        }
      }

      runningBalance = runningBalance + dayIncome - dayExpense;
      if (runningBalance < 0) _goesNegative = true;

      _projection.add(_DayProjection(
        date: day,
        income: dayIncome,
        expense: dayExpense,
        balance: runningBalance,
      ));
    }

    _endOfMonthBalance = runningBalance;
  }

  /// Check if a recurring item's next expected date matches a given day,
  /// accounting for frequency-based recurrence.
  bool _matchesDay(DateTime? nextExpected, String frequency, DateTime day) {
    if (nextExpected == null) return false;
    final next = DateTime(
      nextExpected.year,
      nextExpected.month,
      nextExpected.day,
    );
    if (next == day) return true;

    // If the day is past the next expected, check if it recurs
    if (day.isAfter(next)) {
      switch (frequency) {
        case 'weekly':
          final diff = day.difference(next).inDays;
          return diff > 0 && diff % 7 == 0;
        case 'monthly':
          return day.day == next.day && day.isAfter(next);
        default:
          return false;
      }
    }
    return false;
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    final strings = AppStringsScope.of(context);
    _isSwahili = strings?.isSwahili ?? false;
  }

  String _formatTZS(double value) {
    final abs = value.abs();
    final prefix = value < 0 ? '-' : '';
    if (abs >= 1000000) {
      return '${prefix}TZS ${(abs / 1000000).toStringAsFixed(1)}M';
    }
    if (abs >= 1000) {
      return '${prefix}TZS ${(abs / 1000).toStringAsFixed(0)}K';
    }
    return '${prefix}TZS ${abs.toStringAsFixed(0)}';
  }

  String _formatDate(DateTime date) {
    final day = date.day.toString().padLeft(2, '0');
    final month = date.month.toString().padLeft(2, '0');
    return '$day/$month';
  }

  String _dayName(DateTime date, bool isSw) {
    const enDays = ['Mon', 'Tue', 'Wed', 'Thu', 'Fri', 'Sat', 'Sun'];
    const swDays = ['Jtt', 'Jnn', 'Jtn', 'Alh', 'Ijm', 'Jms', 'Jpi'];
    final idx = date.weekday - 1; // 1=Monday
    return isSw ? swDays[idx] : enDays[idx];
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: _kBackground,
      appBar: AppBar(
        backgroundColor: _kSurface,
        elevation: 0,
        title: Text(
          _isSwahili ? 'Utabiri wa Fedha' : 'Cash Flow Forecast',
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
                        _buildCurrentBalanceCard(),
                        const SizedBox(height: 12),
                        _buildProjectionSummary(),
                        if (_goesNegative) ...[
                          const SizedBox(height: 12),
                          _buildWarningBanner(),
                        ],
                        const SizedBox(height: 20),
                        _buildProjectionList(),
                        const SizedBox(height: 20),
                        _buildUpcomingIncomeSection(),
                        const SizedBox(height: 20),
                        _buildUpcomingExpensesSection(),
                        const SizedBox(height: 20),
                        _buildWhatIfSection(),
                        const SizedBox(height: 24),
                      ],
                    ),
                  ),
      ),
    );
  }

  Widget _buildCurrentBalanceCard() {
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
            _isSwahili ? 'Salio la Sasa' : 'Current Balance',
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            style: const TextStyle(color: _kSecondary, fontSize: 13),
          ),
          const SizedBox(height: 8),
          Text(
            _formatTZS(_walletBalance),
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            style: const TextStyle(
              color: _kPrimary,
              fontSize: 28,
              fontWeight: FontWeight.bold,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildProjectionSummary() {
    final isPositive = _endOfMonthBalance >= 0;
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: _kSurface,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(
          color: isPositive ? _kSuccess.withValues(alpha: 0.3) : _kError.withValues(alpha: 0.3),
        ),
      ),
      child: Row(
        children: [
          Icon(
            isPositive
                ? Icons.trending_up_rounded
                : Icons.trending_down_rounded,
            color: isPositive ? _kSuccess : _kError,
            size: 24,
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  _isSwahili
                      ? 'Mwisho wa siku 30'
                      : 'End of 30 days',
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: const TextStyle(color: _kSecondary, fontSize: 12),
                ),
                const SizedBox(height: 4),
                Text(
                  _formatTZS(_endOfMonthBalance),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: TextStyle(
                    color: isPositive ? _kSuccess : _kError,
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildWarningBanner() {
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: _kWarning.withValues(alpha:0.08),
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: _kWarning.withValues(alpha:0.3)),
      ),
      child: Row(
        children: [
          const Icon(Icons.warning_amber_rounded, color: _kWarning, size: 20),
          const SizedBox(width: 8),
          Expanded(
            child: Text(
              _isSwahili
                  ? 'Salio linatarajiwa kushuka chini ya sifuri ndani ya siku 30'
                  : 'Balance projected to go below zero within 30 days',
              maxLines: 2,
              overflow: TextOverflow.ellipsis,
              style: const TextStyle(color: _kPrimary, fontSize: 13),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildProjectionList() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          _isSwahili ? 'UTABIRI WA SIKU 30' : '30-DAY PROJECTION',
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
          decoration: BoxDecoration(
            color: _kSurface,
            borderRadius: BorderRadius.circular(12),
            border: Border.all(color: _kDivider),
          ),
          child: Column(
            children: [
              for (int i = 0; i < _projection.length; i++) ...[
                if (i > 0) const Divider(height: 1, color: _kDivider),
                _buildDayRow(_projection[i]),
              ],
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildDayRow(_DayProjection day) {
    final hasActivity = day.income > 0 || day.expense > 0;
    final isNegative = day.balance < 0;

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
      color: isNegative ? _kError.withValues(alpha:0.04) : Colors.transparent,
      child: Row(
        children: [
          SizedBox(
            width: 52,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  _dayName(day.date, _isSwahili),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: const TextStyle(
                    color: _kTertiary,
                    fontSize: 11,
                  ),
                ),
                Text(
                  _formatDate(day.date),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: const TextStyle(
                    color: _kPrimary,
                    fontSize: 13,
                    fontWeight: FontWeight.w500,
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(width: 8),
          Expanded(
            child: hasActivity
                ? Row(
                    children: [
                      if (day.income > 0)
                        Text(
                          '+${_formatTZS(day.income)}',
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          style: const TextStyle(
                            color: _kSuccess,
                            fontSize: 12,
                          ),
                        ),
                      if (day.income > 0 && day.expense > 0)
                        const SizedBox(width: 8),
                      if (day.expense > 0)
                        Text(
                          '-${_formatTZS(day.expense)}',
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          style: const TextStyle(
                            color: _kError,
                            fontSize: 12,
                          ),
                        ),
                    ],
                  )
                : const Text(
                    '-',
                    style: TextStyle(color: _kTertiary, fontSize: 12),
                  ),
          ),
          Text(
            _formatTZS(day.balance),
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            style: TextStyle(
              color: isNegative ? _kError : _kPrimary,
              fontSize: 13,
              fontWeight: FontWeight.w600,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildUpcomingIncomeSection() {
    if (_recurringIncome.isEmpty) return const SizedBox.shrink();

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          _isSwahili
              ? 'MAPATO YANAYOTARAJIWA'
              : 'UPCOMING INCOME',
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
              for (int i = 0; i < _recurringIncome.length; i++) ...[
                if (i > 0) const Divider(height: 1, color: _kDivider),
                _buildRecurringIncomeRow(_recurringIncome[i]),
              ],
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildRecurringIncomeRow(RecurringIncome ri) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 10),
      child: Row(
        children: [
          Container(
            width: 36,
            height: 36,
            decoration: BoxDecoration(
              color: _kSuccess.withValues(alpha:0.1),
              shape: BoxShape.circle,
            ),
            child: const Icon(Icons.repeat_rounded, color: _kSuccess, size: 18),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  ri.description,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: const TextStyle(
                    color: _kPrimary,
                    fontSize: 14,
                    fontWeight: FontWeight.w500,
                  ),
                ),
                if (ri.nextExpected != null) ...[
                  const SizedBox(height: 2),
                  Text(
                    '${_isSwahili ? 'Inayofuata' : 'Next'}: ${_formatDate(ri.nextExpected!)}',
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: const TextStyle(
                      color: _kTertiary,
                      fontSize: 12,
                    ),
                  ),
                ],
              ],
            ),
          ),
          Text(
            '+${_formatTZS(ri.amount)}',
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            style: const TextStyle(
              color: _kSuccess,
              fontSize: 14,
              fontWeight: FontWeight.w600,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildUpcomingExpensesSection() {
    if (_upcomingExpenses.isEmpty) return const SizedBox.shrink();

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          _isSwahili
              ? 'MATUMIZI YANAYOTARAJIWA'
              : 'UPCOMING EXPENSES',
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
              for (int i = 0; i < _upcomingExpenses.length; i++) ...[
                if (i > 0) const Divider(height: 1, color: _kDivider),
                _buildUpcomingExpenseRow(_upcomingExpenses[i]),
              ],
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildUpcomingExpenseRow(UpcomingExpense ue) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 10),
      child: Row(
        children: [
          Container(
            width: 36,
            height: 36,
            decoration: BoxDecoration(
              color: _kError.withValues(alpha:0.08),
              shape: BoxShape.circle,
            ),
            child: Icon(
              ue.isRecurring
                  ? Icons.repeat_rounded
                  : Icons.receipt_long_rounded,
              color: _kError.withValues(alpha:0.7),
              size: 18,
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  ue.description,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: const TextStyle(
                    color: _kPrimary,
                    fontSize: 14,
                    fontWeight: FontWeight.w500,
                  ),
                ),
                if (ue.expectedDate != null) ...[
                  const SizedBox(height: 2),
                  Text(
                    _formatDate(ue.expectedDate!),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: const TextStyle(
                      color: _kTertiary,
                      fontSize: 12,
                    ),
                  ),
                ],
              ],
            ),
          ),
          Text(
            '-${_formatTZS(ue.amount)}',
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            style: const TextStyle(
              color: _kError,
              fontSize: 14,
              fontWeight: FontWeight.w600,
            ),
          ),
        ],
      ),
    );
  }
  // ── What-if section ──────────────────────────────────────────────────────

  Widget _buildWhatIfSection() {
    final whatIfBalance = _whatIfAmount != null
        ? _endOfMonthBalance - _whatIfAmount!
        : null;
    final isPositive = whatIfBalance != null && whatIfBalance >= 0;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          _isSwahili
              ? 'NINI KAMA...?'
              : 'WHAT IF...?',
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
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                _isSwahili
                    ? 'Nini kama nitatumia kiasi hiki zaidi?'
                    : 'What if I spend this much more?',
                maxLines: 2,
                overflow: TextOverflow.ellipsis,
                style: const TextStyle(
                  fontSize: 13,
                  color: _kSecondary,
                ),
              ),
              const SizedBox(height: 12),
              TextField(
                controller: _whatIfController,
                keyboardType: TextInputType.number,
                decoration: InputDecoration(
                  prefixText: 'TZS ',
                  hintText: _isSwahili ? 'Ingiza kiasi' : 'Enter amount',
                  filled: true,
                  fillColor: _kBackground,
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(10),
                    borderSide: BorderSide.none,
                  ),
                  contentPadding: const EdgeInsets.symmetric(
                    horizontal: 14,
                    vertical: 12,
                  ),
                ),
                onChanged: (val) {
                  setState(() {
                    _whatIfAmount =
                        double.tryParse(val.replaceAll(',', ''));
                  });
                },
              ),
              if (whatIfBalance != null) ...[
                const SizedBox(height: 16),
                Container(
                  width: double.infinity,
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: isPositive
                        ? _kSuccess.withValues(alpha: 0.08)
                        : _kError.withValues(alpha: 0.08),
                    borderRadius: BorderRadius.circular(8),
                    border: Border.all(
                      color: isPositive
                          ? _kSuccess.withValues(alpha: 0.3)
                          : _kError.withValues(alpha: 0.3),
                    ),
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        _isSwahili
                            ? 'Salio mwishoni mwa siku 30:'
                            : 'Balance at end of 30 days:',
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: const TextStyle(
                          fontSize: 12,
                          color: _kSecondary,
                        ),
                      ),
                      const SizedBox(height: 4),
                      Row(
                        children: [
                          Text(
                            _formatTZS(_endOfMonthBalance),
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                            style: const TextStyle(
                              fontSize: 14,
                              color: _kTertiary,
                              decoration: TextDecoration.lineThrough,
                            ),
                          ),
                          const SizedBox(width: 8),
                          const Icon(Icons.arrow_forward_rounded,
                              size: 14, color: _kTertiary),
                          const SizedBox(width: 8),
                          Expanded(
                            child: Text(
                              _formatTZS(whatIfBalance),
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
                      if (!isPositive) ...[
                        const SizedBox(height: 6),
                        Text(
                          _isSwahili
                              ? 'Salio litakuwa hasi!'
                              : 'Balance will go negative!',
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          style: const TextStyle(
                            fontSize: 12,
                            fontWeight: FontWeight.w500,
                            color: _kError,
                          ),
                        ),
                      ],
                    ],
                  ),
                ),
              ],
            ],
          ),
        ),
      ],
    );
  }
}

/// Internal model for a single day's projection
class _DayProjection {
  final DateTime date;
  final double income;
  final double expense;
  final double balance;

  const _DayProjection({
    required this.date,
    required this.income,
    required this.expense,
    required this.balance,
  });
}
