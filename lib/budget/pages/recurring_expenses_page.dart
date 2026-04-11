// lib/budget/pages/recurring_expenses_page.dart
import 'package:flutter/material.dart';
import '../../l10n/app_strings_scope.dart';
import '../models/budget_models.dart';
import '../../services/expenditure_service.dart';
import '../../services/local_storage_service.dart';
import '../widgets/recurring_expense_tile.dart';

// DESIGN.md tokens
const Color _kBackground = Color(0xFFFAFAFA);
const Color _kSurface = Color(0xFFFFFFFF);
const Color _kPrimary = Color(0xFF1A1A1A);
const Color _kSecondary = Color(0xFF666666);
const Color _kTertiary = Color(0xFF999999);
const Color _kDivider = Color(0xFFE0E0E0);

class RecurringExpensesPage extends StatefulWidget {
  final int userId;

  const RecurringExpensesPage({super.key, required this.userId});

  @override
  State<RecurringExpensesPage> createState() =>
      _RecurringExpensesPageState();
}

class _RecurringExpensesPageState extends State<RecurringExpensesPage> {
  bool _isLoading = true;
  String? _error;
  String _token = '';
  bool _isSwahili = false;

  List<RecurringExpense> _confirmed = [];
  List<RecurringExpense> _unconfirmed = [];

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
      final expenses = await ExpenditureService.getRecurringExpenses(
        token: _token,
      );

      if (!mounted) return;
      setState(() {
        _splitExpenses(expenses);
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

  void _splitExpenses(List<RecurringExpense> all) {
    _confirmed = all.where((e) => e.isConfirmed).toList();
    _unconfirmed = all.where((e) => !e.isConfirmed).toList();
  }

  Future<void> _confirmExpense(RecurringExpense expense) async {
    if (expense.id != null && _token.isNotEmpty) {
      final ok = await ExpenditureService.confirmRecurringExpense(
        _token,
        expense.id!,
      );
      if (!ok && mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
              _isSwahili
                  ? 'Imeshindikana kuthibitisha'
                  : 'Failed to confirm expense',
            ),
          ),
        );
        return;
      }
    }
    if (!mounted) return;
    setState(() {
      _unconfirmed.remove(expense);
      _confirmed.add(RecurringExpense(
        id: expense.id,
        description: expense.description,
        amount: expense.amount,
        envelopeId: expense.envelopeId,
        category: expense.category,
        frequency: expense.frequency,
        lastOccurrence: expense.lastOccurrence,
        nextExpected: expense.nextExpected,
        isConfirmed: true,
      ));
    });
    if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            _isSwahili ? 'Imethibitishwa' : 'Confirmed',
          ),
        ),
      );
    }
  }

  Future<void> _dismissExpense(RecurringExpense expense) async {
    if (expense.id != null && _token.isNotEmpty) {
      final ok = await ExpenditureService.dismissRecurringExpense(
        _token,
        expense.id!,
      );
      if (!ok && mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
              _isSwahili
                  ? 'Imeshindikana kuondoa'
                  : 'Failed to dismiss expense',
            ),
          ),
        );
        return;
      }
    }
    if (!mounted) return;
    setState(() {
      _unconfirmed.remove(expense);
    });
    if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            _isSwahili ? 'Imeondolewa' : 'Dismissed',
          ),
        ),
      );
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

  double get _totalMonthly {
    double total = 0;
    for (final e in _confirmed) {
      switch (e.frequency) {
        case 'weekly':
          total += e.amount * 4;
          break;
        case 'yearly':
          total += e.amount / 12;
          break;
        default: // monthly
          total += e.amount;
      }
    }
    return total;
  }

  @override
  Widget build(BuildContext context) {
    final isEmpty = _confirmed.isEmpty && _unconfirmed.isEmpty;

    return Scaffold(
      backgroundColor: _kBackground,
      appBar: AppBar(
        backgroundColor: _kSurface,
        elevation: 0,
        title: Text(
          _isSwahili ? 'Malipo ya Kila Mwezi' : 'Recurring Expenses',
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
                : isEmpty
                    ? _buildEmptyState()
                    : RefreshIndicator(
                        onRefresh: _loadData,
                        child: ListView(
                          padding: const EdgeInsets.all(16),
                          children: [
                            _buildSummaryCard(),
                            if (_unconfirmed.isNotEmpty) ...[
                              const SizedBox(height: 20),
                              _buildSectionHeader(
                                _isSwahili
                                    ? 'HAZIJATHIBITISHWA'
                                    : 'UNCONFIRMED',
                              ),
                              const SizedBox(height: 12),
                              _buildExpenseList(_unconfirmed, showActions: true),
                            ],
                            if (_confirmed.isNotEmpty) ...[
                              const SizedBox(height: 20),
                              _buildSectionHeader(
                                _isSwahili
                                    ? 'YALIYOTHIBITISHWA'
                                    : 'CONFIRMED',
                              ),
                              const SizedBox(height: 12),
                              _buildExpenseList(_confirmed, showActions: false),
                            ],
                          ],
                        ),
                      ),
      ),
    );
  }

  Widget _buildEmptyState() {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(32),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(
              Icons.repeat_rounded,
              size: 48,
              color: _kTertiary.withValues(alpha:0.5),
            ),
            const SizedBox(height: 16),
            Text(
              _isSwahili
                  ? 'Hatujapata malipo ya kila mwezi'
                  : 'No recurring expenses detected yet',
              textAlign: TextAlign.center,
              maxLines: 2,
              overflow: TextOverflow.ellipsis,
              style: const TextStyle(
                color: _kSecondary,
                fontSize: 15,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildSummaryCard() {
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
            _isSwahili
                ? 'Jumla ya Malipo ya Kila Mwezi'
                : 'Total Monthly Recurring',
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            style: const TextStyle(color: _kSecondary, fontSize: 13),
          ),
          const SizedBox(height: 8),
          Text(
            _formatTZS(_totalMonthly),
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            style: const TextStyle(
              color: _kPrimary,
              fontSize: 28,
              fontWeight: FontWeight.bold,
            ),
          ),
          const SizedBox(height: 4),
          Text(
            _isSwahili
                ? '${_confirmed.length} malipo yaliyothibitishwa'
                : '${_confirmed.length} confirmed expenses',
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            style: const TextStyle(color: _kTertiary, fontSize: 12),
          ),
        ],
      ),
    );
  }

  Widget _buildSectionHeader(String label) {
    return Text(
      label,
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

  Widget _buildExpenseList(
    List<RecurringExpense> expenses, {
    required bool showActions,
  }) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
      decoration: BoxDecoration(
        color: _kSurface,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: _kDivider),
      ),
      child: Column(
        children: [
          for (int i = 0; i < expenses.length; i++) ...[
            if (i > 0) const Divider(height: 1, color: _kDivider),
            RecurringExpenseTile(
              expense: expenses[i],
              isSwahili: _isSwahili,
              onConfirm: showActions
                  ? () => _confirmExpense(expenses[i])
                  : null,
              onDismiss: showActions
                  ? () => _dismissExpense(expenses[i])
                  : null,
            ),
          ],
        ],
      ),
    );
  }
}
