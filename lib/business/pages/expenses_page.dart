// lib/business/pages/expenses_page.dart
// Expense tracking (Matumizi) — summary, category filter, list.
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import '../../services/local_storage_service.dart';
import '../models/business_models.dart';
import '../services/business_service.dart';
import 'add_expense_page.dart';

const Color _kPrimary = Color(0xFF1A1A1A);
const Color _kSecondary = Color(0xFF666666);
const Color _kBackground = Color(0xFFFAFAFA);
const Color _kCardBg = Color(0xFFFFFFFF);

class ExpensesPage extends StatefulWidget {
  final int businessId;
  const ExpensesPage({super.key, required this.businessId});

  @override
  State<ExpensesPage> createState() => _ExpensesPageState();
}

class _ExpensesPageState extends State<ExpensesPage> {
  String? _token;
  bool _loading = true;
  String? _error;
  List<Expense> _expenses = [];
  ExpenseSummary? _summary;
  ExpenseCategory? _selectedCategory;

  @override
  void initState() {
    super.initState();
    _init();
  }

  Future<void> _init() async {
    final storage = await LocalStorageService.getInstance();
    _token = storage.getAuthToken();
    await _load();
  }

  Future<void> _load() async {
    if (_token == null) return;
    setState(() {
      _loading = true;
      _error = null;
    });
    try {
      final futures = await Future.wait([
        BusinessService.getExpenses(_token!, widget.businessId,
            category: _selectedCategory?.name),
        BusinessService.getExpenseSummary(_token!, widget.businessId),
      ]);

      final expRes = futures[0] as BusinessListResult<Expense>;
      final sumRes = futures[1] as BusinessResult<ExpenseSummary>;

      if (mounted) {
        setState(() {
          _loading = false;
          if (expRes.success) {
            _expenses = expRes.data;
          } else {
            _error = expRes.message ?? 'Failed to load expenses';
          }
          if (sumRes.success && sumRes.data != null) _summary = sumRes.data;
        });
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          _loading = false;
          _error = 'Connection error. Pull to retry.';
        });
      }
    }
  }

  Future<bool> _confirmDeleteExpense(Expense e) async {
    if (_token == null || e.id == null) return false;
    final confirm = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Delete Expense?'),
        content: const Text('This action cannot be undone.'),
        actions: [
          TextButton(
              onPressed: () => Navigator.pop(ctx, false),
              child: const Text('Cancel')),
          TextButton(
              onPressed: () => Navigator.pop(ctx, true),
              child: const Text('Delete',
                  style: TextStyle(color: Colors.red))),
        ],
      ),
    );
    if (confirm != true) return false;

    final res = await BusinessService.deleteExpense(_token!, e.id!);
    if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(res.success ? 'Expense deleted' : (res.message ?? 'Failed'))));
      if (res.success) _load();
    }
    return res.success;
  }

  IconData _categoryIcon(ExpenseCategory c) {
    switch (c) {
      case ExpenseCategory.rent:
        return Icons.home_rounded;
      case ExpenseCategory.utilities:
        return Icons.bolt_rounded;
      case ExpenseCategory.supplies:
        return Icons.inventory_2_rounded;
      case ExpenseCategory.transport:
        return Icons.directions_car_rounded;
      case ExpenseCategory.salary:
        return Icons.people_rounded;
      case ExpenseCategory.marketing:
        return Icons.campaign_rounded;
      case ExpenseCategory.food:
        return Icons.restaurant_rounded;
      case ExpenseCategory.communication:
        return Icons.phone_rounded;
      case ExpenseCategory.maintenance:
        return Icons.build_rounded;
      case ExpenseCategory.tax:
        return Icons.account_balance_rounded;
      case ExpenseCategory.insurance:
        return Icons.shield_rounded;
      case ExpenseCategory.other:
        return Icons.more_horiz_rounded;
    }
  }

  String _categoryLabel(ExpenseCategory c) {
    switch (c) {
      case ExpenseCategory.rent:
        return 'Rent';
      case ExpenseCategory.utilities:
        return 'Utilities';
      case ExpenseCategory.supplies:
        return 'Supplies';
      case ExpenseCategory.transport:
        return 'Transport';
      case ExpenseCategory.salary:
        return 'Salary';
      case ExpenseCategory.marketing:
        return 'Marketing';
      case ExpenseCategory.food:
        return 'Food';
      case ExpenseCategory.communication:
        return 'Communication';
      case ExpenseCategory.maintenance:
        return 'Maintenance';
      case ExpenseCategory.tax:
        return 'Tax';
      case ExpenseCategory.insurance:
        return 'Insurance';
      case ExpenseCategory.other:
        return 'Other';
    }
  }

  @override
  Widget build(BuildContext context) {
    final nf = NumberFormat('#,###', 'en');
    final df = DateFormat('dd/MM/yyyy');

    return Scaffold(
      backgroundColor: _kBackground,
      floatingActionButton: FloatingActionButton(
        onPressed: () async {
          final added = await Navigator.push<bool>(
            context,
            MaterialPageRoute(
                builder: (_) =>
                    AddExpensePage(businessId: widget.businessId)),
          );
          if (added == true) _load();
        },
        backgroundColor: _kPrimary,
        child: const Icon(Icons.add_rounded, color: Colors.white),
      ),
      body: _loading
          ? const Center(
              child: CircularProgressIndicator(
                  strokeWidth: 2, color: _kPrimary))
          : _error != null && _expenses.isEmpty
              ? Center(
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Icon(Icons.error_outline_rounded,
                          size: 64, color: Colors.grey.shade300),
                      const SizedBox(height: 12),
                      Text(_error!,
                          style: TextStyle(
                              color: Colors.grey.shade500, fontSize: 14)),
                      const SizedBox(height: 12),
                      TextButton.icon(
                        onPressed: _load,
                        icon: const Icon(Icons.refresh_rounded, size: 18),
                        label: const Text('Retry'),
                        style:
                            TextButton.styleFrom(foregroundColor: _kPrimary),
                      ),
                    ],
                  ),
                )
              : RefreshIndicator(
                  color: _kPrimary,
                  onRefresh: _load,
                  child: ListView(
                    padding: const EdgeInsets.all(16),
                    children: [
                      // Summary card
                      if (_summary != null) _buildSummaryCard(nf),

                      const SizedBox(height: 16),

                      // Category filter
                      SizedBox(
                        height: 38,
                        child: ListView(
                          scrollDirection: Axis.horizontal,
                          children: [
                            _filterChip(null, 'All'),
                            ...ExpenseCategory.values
                                .map((c) => _filterChip(c, _categoryLabel(c))),
                          ],
                        ),
                      ),

                      const SizedBox(height: 16),

                      // Expense list
                      if (_expenses.isEmpty)
                        Center(
                          child: Padding(
                            padding: const EdgeInsets.all(32),
                            child: Column(
                              children: [
                                Icon(Icons.receipt_long_rounded,
                                    size: 64,
                                    color: Colors.grey.shade300),
                                const SizedBox(height: 12),
                                Text('No expenses yet',
                                    style: TextStyle(
                                        color: Colors.grey.shade500,
                                        fontSize: 16)),
                                const SizedBox(height: 4),
                                Text('Tap + to record an expense',
                                    style: TextStyle(
                                        color: Colors.grey.shade400,
                                        fontSize: 13)),
                              ],
                            ),
                          ),
                        )
                      else
                        ...(_expenses
                            .map((e) => _buildExpenseCard(e, nf, df))),

                      const SizedBox(height: 80),
                    ],
                  ),
                ),
    );
  }

  Widget _buildSummaryCard(NumberFormat nf) {
    final s = _summary!;
    final isUp = s.changePercent > 0;
    final isDown = s.changePercent < 0;

    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: _kPrimary,
        borderRadius: BorderRadius.circular(16),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text('This Month\'s Expenses',
              style: TextStyle(
                  color: Colors.white.withValues(alpha: 0.7), fontSize: 13)),
          const SizedBox(height: 4),
          Text('TZS ${nf.format(s.totalThisMonth)}',
              style: const TextStyle(
                  color: Colors.white,
                  fontSize: 24,
                  fontWeight: FontWeight.bold)),
          const SizedBox(height: 8),
          Row(
            children: [
              Icon(
                isUp
                    ? Icons.trending_up_rounded
                    : isDown
                        ? Icons.trending_down_rounded
                        : Icons.trending_flat_rounded,
                color: isUp
                    ? Colors.red.shade300
                    : isDown
                        ? Colors.green.shade300
                        : Colors.white54,
                size: 18,
              ),
              const SizedBox(width: 4),
              Text(
                '${s.changePercent.abs().toStringAsFixed(1)}% ${isUp ? 'more' : isDown ? 'less' : 'same as'} last month',
                style: TextStyle(
                  color: isUp
                      ? Colors.red.shade300
                      : isDown
                          ? Colors.green.shade300
                          : Colors.white54,
                  fontSize: 12,
                ),
              ),
            ],
          ),
          const SizedBox(height: 4),
          Text('Last month: TZS ${nf.format(s.totalLastMonth)}',
              style: TextStyle(
                  color: Colors.white.withValues(alpha: 0.5), fontSize: 11)),
        ],
      ),
    );
  }

  Widget _filterChip(ExpenseCategory? cat, String label) {
    final isSelected = _selectedCategory == cat;
    return Padding(
      padding: const EdgeInsets.only(right: 8),
      child: FilterChip(
        label: Text(label,
            style: TextStyle(
                fontSize: 12,
                color: isSelected ? Colors.white : _kPrimary)),
        selected: isSelected,
        onSelected: (_) {
          setState(() => _selectedCategory = cat);
          _load();
        },
        selectedColor: _kPrimary,
        backgroundColor: _kCardBg,
        side: BorderSide(
            color: isSelected ? _kPrimary : Colors.grey.shade200),
        shape:
            RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
        showCheckmark: false,
      ),
    );
  }

  Widget _buildExpenseCard(Expense e, NumberFormat nf, DateFormat df) {
    return Dismissible(
      key: Key('expense_${e.id}'),
      direction: DismissDirection.endToStart,
      background: Container(
        alignment: Alignment.centerRight,
        padding: const EdgeInsets.only(right: 20),
        margin: const EdgeInsets.only(bottom: 10),
        decoration: BoxDecoration(
          color: Colors.red.shade50,
          borderRadius: BorderRadius.circular(12),
        ),
        child: Icon(Icons.delete_rounded, color: Colors.red.shade700),
      ),
      confirmDismiss: (_) => _confirmDeleteExpense(e),
      child: Container(
        margin: const EdgeInsets.only(bottom: 10),
        padding: const EdgeInsets.all(14),
        decoration: BoxDecoration(
          color: _kCardBg,
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: Colors.grey.shade100),
        ),
        child: Row(
          children: [
            Container(
              padding: const EdgeInsets.all(10),
              decoration: BoxDecoration(
                color: _kPrimary.withValues(alpha: 0.06),
                borderRadius: BorderRadius.circular(10),
              ),
              child: Icon(_categoryIcon(e.category),
                  size: 20, color: _kPrimary),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                      e.description ?? _categoryLabel(e.category),
                      style: const TextStyle(
                          fontWeight: FontWeight.w600,
                          color: _kPrimary,
                          fontSize: 13),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis),
                  const SizedBox(height: 2),
                  Row(
                    children: [
                      Text(_categoryLabel(e.category),
                          style: const TextStyle(
                              fontSize: 11, color: _kSecondary)),
                      if (e.vendorName != null &&
                          e.vendorName!.isNotEmpty) ...[
                        const Text(' - ',
                            style: TextStyle(
                                fontSize: 11, color: _kSecondary)),
                        Flexible(
                          child: Text(e.vendorName!,
                              style: const TextStyle(
                                  fontSize: 11, color: _kSecondary),
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis),
                        ),
                      ],
                    ],
                  ),
                  if (e.date != null)
                    Text(df.format(e.date!),
                        style: const TextStyle(
                            fontSize: 10, color: _kSecondary)),
                ],
              ),
            ),
            Column(
              crossAxisAlignment: CrossAxisAlignment.end,
              children: [
                Text('TZS ${nf.format(e.amount)}',
                    style: const TextStyle(
                        fontWeight: FontWeight.bold,
                        color: _kPrimary,
                        fontSize: 14)),
                if (e.paymentMethod != null)
                  Text(_paymentMethodLabel(e.paymentMethod!),
                      style: const TextStyle(
                          fontSize: 10, color: _kSecondary)),
              ],
            ),
            if (e.receiptPhotoUrl != null && e.receiptPhotoUrl!.isNotEmpty)
              Padding(
                padding: const EdgeInsets.only(left: 8),
                child: Icon(Icons.receipt_rounded,
                    size: 16, color: Colors.green.shade700),
              ),
          ],
        ),
      ),
    );
  }

  String _paymentMethodLabel(String method) {
    switch (method.toLowerCase()) {
      case 'cash':
        return 'Cash';
      case 'mpesa':
        return 'M-Pesa';
      case 'bank':
        return 'Bank';
      default:
        return method;
    }
  }
}
