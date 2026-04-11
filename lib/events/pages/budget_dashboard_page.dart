// lib/events/pages/budget_dashboard_page.dart
import 'package:flutter/material.dart';
import '../models/budget.dart';
import '../models/event_strings.dart';
import '../services/budget_service.dart';
import '../../services/local_storage_service.dart';

const Color _kPrimary = Color(0xFF1A1A1A);
const Color _kSecondary = Color(0xFF666666);
const Color _kBg = Color(0xFFFAFAFA);

class BudgetDashboardPage extends StatefulWidget {
  final int eventId;
  final String eventName;

  const BudgetDashboardPage({
    super.key,
    required this.eventId,
    required this.eventName,
  });

  @override
  State<BudgetDashboardPage> createState() => _BudgetDashboardPageState();
}

class _BudgetDashboardPageState extends State<BudgetDashboardPage>
    with SingleTickerProviderStateMixin {
  final _service = BudgetService();
  late EventStrings _strings;
  late TabController _tabs;

  EventBudget? _budget;
  List<Expense> _expenses = [];
  bool _loading = true;
  String? _error;

  @override
  void initState() {
    super.initState();
    _tabs = TabController(length: 2, vsync: this);
    final lang = LocalStorageService.instanceSync?.getLanguageCode() ?? 'sw';
    _strings = EventStrings(isSwahili: lang == 'sw');
    _load();
  }

  @override
  void dispose() {
    _tabs.dispose();
    super.dispose();
  }

  Future<void> _load() async {
    setState(() { _loading = true; _error = null; });
    final budgetResult = await _service.getBudget(eventId: widget.eventId);
    if (!mounted) return;
    if (budgetResult.success && budgetResult.data != null) {
      final expenseResult = await _service.getExpenses(eventId: widget.eventId);
      if (!mounted) return;
      setState(() {
        _budget = budgetResult.data;
        _expenses = expenseResult.success ? expenseResult.items : [];
        _loading = false;
      });
    } else {
      setState(() { _error = budgetResult.message; _loading = false; });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: _kBg,
      appBar: AppBar(
        backgroundColor: _kBg,
        foregroundColor: _kPrimary,
        elevation: 0,
        title: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(_strings.isSwahili ? 'Bajeti' : 'Budget',
                style: const TextStyle(fontSize: 16, fontWeight: FontWeight.w700, color: _kPrimary)),
            Text(widget.eventName,
                style: const TextStyle(fontSize: 12, color: _kSecondary),
                maxLines: 1, overflow: TextOverflow.ellipsis),
          ],
        ),
        actions: [
          IconButton(icon: const Icon(Icons.refresh_rounded), onPressed: _load),
        ],
        bottom: TabBar(
          controller: _tabs,
          labelColor: _kPrimary,
          unselectedLabelColor: _kSecondary,
          indicatorColor: _kPrimary,
          tabs: [
            Tab(text: _strings.isSwahili ? 'Muhtasari' : 'Overview'),
            Tab(text: _strings.isSwahili ? 'Matumizi' : 'Expenses'),
          ],
        ),
      ),
      floatingActionButton: FloatingActionButton.extended(
        backgroundColor: _kPrimary,
        foregroundColor: Colors.white,
        icon: const Icon(Icons.add_rounded),
        label: Text(_strings.isSwahili ? 'Rekodi Gharama' : 'Log Expense'),
        onPressed: _budget != null ? _showLogExpenseDialog : null,
      ),
      body: _loading
          ? const Center(child: CircularProgressIndicator(color: _kPrimary))
          : _error != null
              ? _ErrorView(message: _error!, onRetry: _load)
              : TabBarView(
                  controller: _tabs,
                  children: [
                    _OverviewTab(budget: _budget!, strings: _strings, onRefresh: _load),
                    _ExpensesTab(expenses: _expenses, strings: _strings, onRefresh: _load),
                  ],
                ),
    );
  }

  void _showLogExpenseDialog() {
    final amountCtrl = TextEditingController();
    final descCtrl = TextEditingController();
    String? selectedCategory = _budget!.categories.isNotEmpty ? _budget!.categories.first.name : null;
    int? selectedCategoryId = _budget!.categories.isNotEmpty ? _budget!.categories.first.id : null;
    showDialog(
      context: context,
      builder: (ctx) => StatefulBuilder(
        builder: (ctx, setSt) => AlertDialog(
          backgroundColor: _kBg,
          title: Text(
            _strings.isSwahili ? 'Rekodi Gharama' : 'Log Expense',
            style: const TextStyle(fontSize: 15, fontWeight: FontWeight.w700, color: _kPrimary),
          ),
          content: SingleChildScrollView(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                _Field(controller: amountCtrl,
                    label: _strings.isSwahili ? 'Kiasi (TZS)' : 'Amount (TZS)',
                    keyboardType: TextInputType.number),
                const SizedBox(height: 10),
                _Field(controller: descCtrl,
                    label: _strings.isSwahili ? 'Maelezo' : 'Description'),
                const SizedBox(height: 10),
                if (_budget!.categories.isNotEmpty)
                  DropdownButtonFormField<int>(
                    initialValue: selectedCategoryId,
                    decoration: InputDecoration(
                      labelText: _strings.isSwahili ? 'Aina ya Gharama' : 'Category',
                      border: const OutlineInputBorder(),
                      contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
                    ),
                    items: _budget!.categories
                        .map((c) => DropdownMenuItem(
                              value: c.id,
                              child: Text(c.name, style: const TextStyle(fontSize: 13)),
                            ))
                        .toList(),
                    onChanged: (v) => setSt(() {
                      selectedCategoryId = v;
                      selectedCategory = _budget!.categories
                          .firstWhere((c) => c.id == v, orElse: () => _budget!.categories.first)
                          .name;
                    }),
                  )
                else
                  _Field(
                    controller: TextEditingController(text: selectedCategory),
                    label: _strings.isSwahili ? 'Aina ya Gharama' : 'Category',
                  ),
              ],
            ),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(ctx),
              child: Text(_strings.back, style: const TextStyle(color: _kSecondary)),
            ),
            FilledButton(
              style: FilledButton.styleFrom(backgroundColor: _kPrimary),
              onPressed: () async {
                final amount = double.tryParse(amountCtrl.text.trim());
                final desc = descCtrl.text.trim();
                if (amount == null || amount <= 0 || desc.isEmpty) return;
                Navigator.pop(ctx);
                await _service.logExpense(
                  eventId: widget.eventId,
                  categoryName: selectedCategory ?? '',
                  amount: amount,
                  description: desc,
                  budgetCategoryId: selectedCategoryId,
                );
                _load();
              },
              child: Text(_strings.isSwahili ? 'Hifadhi' : 'Save',
                  style: const TextStyle(color: Colors.white)),
            ),
          ],
        ),
      ),
    );
  }
}

// ── Overview Tab ──────────────────────────────────────────────────────────────

class _OverviewTab extends StatelessWidget {
  final EventBudget budget;
  final EventStrings strings;
  final VoidCallback onRefresh;

  const _OverviewTab({required this.budget, required this.strings, required this.onRefresh});

  @override
  Widget build(BuildContext context) {
    return RefreshIndicator(
      color: _kPrimary,
      onRefresh: () async => onRefresh(),
      child: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          _BudgetSummaryCard(budget: budget, strings: strings),
          const SizedBox(height: 20),
          _SectionLabel(strings.isSwahili ? 'Mgawanyo wa Bajeti' : 'Category Breakdown'),
          const SizedBox(height: 12),
          if (budget.categories.isEmpty)
            Center(
              child: Padding(
                padding: const EdgeInsets.symmetric(vertical: 24),
                child: Text(
                  strings.isSwahili ? 'Hakuna aina za bajeti' : 'No budget categories',
                  style: const TextStyle(color: _kSecondary),
                ),
              ),
            )
          else
            ...budget.categories.map((c) => _CategoryRow(category: c, strings: strings)),
        ],
      ),
    );
  }
}

class _BudgetSummaryCard extends StatelessWidget {
  final EventBudget budget;
  final EventStrings strings;
  const _BudgetSummaryCard({required this.budget, required this.strings});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: const Color(0xFFE8E8E8)),
      ),
      child: Column(
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceAround,
            children: [
              _BudgetStat(
                label: strings.isSwahili ? 'Bajeti Jumla' : 'Total Budget',
                value: _fmt(budget.totalBudget, budget.currency),
                icon: Icons.account_balance_rounded,
              ),
              Container(width: 1, height: 40, color: const Color(0xFFE8E8E8)),
              _BudgetStat(
                label: strings.isSwahili ? 'Imetumika' : 'Spent',
                value: _fmt(budget.totalSpent, budget.currency),
                icon: Icons.payments_rounded,
                highlight: budget.isOverBudget,
              ),
              Container(width: 1, height: 40, color: const Color(0xFFE8E8E8)),
              _BudgetStat(
                label: strings.isSwahili ? 'Inabaki' : 'Available',
                value: _fmt(budget.available, budget.currency),
                icon: Icons.savings_rounded,
              ),
            ],
          ),
          const SizedBox(height: 14),
          ClipRRect(
            borderRadius: BorderRadius.circular(4),
            child: LinearProgressIndicator(
              value: budget.budgetUtilization.clamp(0.0, 1.0),
              minHeight: 6,
              backgroundColor: const Color(0xFFE8E8E8),
              color: budget.isOverBudget ? const Color(0xFFF44336) : _kPrimary,
            ),
          ),
          const SizedBox(height: 6),
          Text(
            '${(budget.budgetUtilization * 100).toStringAsFixed(0)}% ${strings.isSwahili ? "imetumika" : "utilized"}',
            style: const TextStyle(fontSize: 11, color: _kSecondary),
          ),
        ],
      ),
    );
  }

  String _fmt(double amount, String currency) {
    final s = amount.toStringAsFixed(0).replaceAllMapped(
        RegExp(r'(\d{1,3})(?=(\d{3})+(?!\d))'), (m) => '${m[1]},');
    return '$currency $s';
  }
}

class _BudgetStat extends StatelessWidget {
  final String label;
  final String value;
  final IconData icon;
  final bool highlight;

  const _BudgetStat({required this.label, required this.value, required this.icon, this.highlight = false});

  @override
  Widget build(BuildContext context) {
    final color = highlight ? const Color(0xFFF44336) : _kPrimary;
    return Column(
      children: [
        Icon(icon, size: 18, color: color),
        const SizedBox(height: 4),
        Text(value,
            style: TextStyle(fontSize: 11, fontWeight: FontWeight.w700, color: color),
            maxLines: 1, overflow: TextOverflow.ellipsis),
        Text(label, style: const TextStyle(fontSize: 10, color: _kSecondary)),
      ],
    );
  }
}

class _CategoryRow extends StatelessWidget {
  final BudgetCategory category;
  final EventStrings strings;
  const _CategoryRow({required this.category, required this.strings});

  @override
  Widget build(BuildContext context) {
    final util = category.utilization.clamp(0.0, 1.0);
    return Container(
      margin: const EdgeInsets.only(bottom: 10),
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(10),
        border: Border.all(color: const Color(0xFFE8E8E8)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Expanded(
                child: Text(category.name,
                    style: const TextStyle(fontSize: 13, fontWeight: FontWeight.w600, color: _kPrimary),
                    maxLines: 1, overflow: TextOverflow.ellipsis),
              ),
              if (category.isOverspent)
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                  decoration: BoxDecoration(
                    color: const Color(0x1FF44336),
                    borderRadius: BorderRadius.circular(4),
                  ),
                  child: Text(
                    strings.isSwahili ? 'Imezidi' : 'Over',
                    style: const TextStyle(fontSize: 9, color: Color(0xFFF44336), fontWeight: FontWeight.w700),
                  ),
                ),
            ],
          ),
          const SizedBox(height: 8),
          ClipRRect(
            borderRadius: BorderRadius.circular(3),
            child: LinearProgressIndicator(
              value: util,
              minHeight: 5,
              backgroundColor: const Color(0xFFE8E8E8),
              color: category.isOverspent ? const Color(0xFFF44336) : _kPrimary,
            ),
          ),
          const SizedBox(height: 6),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text('${strings.isSwahili ? "Imetengwa" : "Alloc"}: TZS ${_fmt(category.allocated)}',
                  style: const TextStyle(fontSize: 10, color: _kSecondary)),
              Text('${strings.isSwahili ? "Imetumika" : "Spent"}: TZS ${_fmt(category.spent)}',
                  style: const TextStyle(fontSize: 10, color: _kSecondary)),
              Text('${strings.isSwahili ? "Inabaki" : "Left"}: TZS ${_fmt(category.remaining)}',
                  style: const TextStyle(fontSize: 10, color: _kSecondary)),
            ],
          ),
        ],
      ),
    );
  }

  String _fmt(double v) => v.toStringAsFixed(0).replaceAllMapped(
      RegExp(r'(\d{1,3})(?=(\d{3})+(?!\d))'), (m) => '${m[1]},');
}

// ── Expenses Tab ──────────────────────────────────────────────────────────────

class _ExpensesTab extends StatelessWidget {
  final List<Expense> expenses;
  final EventStrings strings;
  final VoidCallback onRefresh;

  const _ExpensesTab({required this.expenses, required this.strings, required this.onRefresh});

  @override
  Widget build(BuildContext context) {
    return RefreshIndicator(
      color: _kPrimary,
      onRefresh: () async => onRefresh(),
      child: expenses.isEmpty
          ? Center(
              child: Text(
                strings.isSwahili ? 'Hakuna matumizi bado' : 'No expenses yet',
                style: const TextStyle(color: _kSecondary),
              ),
            )
          : ListView.separated(
              padding: const EdgeInsets.all(16),
              itemCount: expenses.length,
              separatorBuilder: (context, index) => const SizedBox(height: 8),
              itemBuilder: (_, i) => _ExpenseTile(expense: expenses[i], strings: strings),
            ),
    );
  }
}

class _ExpenseTile extends StatelessWidget {
  final Expense expense;
  final EventStrings strings;
  const _ExpenseTile({required this.expense, required this.strings});

  Color get _statusColor {
    switch (expense.status) {
      case 'approved': return const Color(0xFF4CAF50);
      case 'rejected': return const Color(0xFFF44336);
      default: return _kSecondary;
    }
  }

  String get _statusLabel {
    switch (expense.status) {
      case 'approved': return strings.isSwahili ? 'Imeidhinishwa' : 'Approved';
      case 'rejected': return strings.isSwahili ? 'Imekataliwa' : 'Rejected';
      default: return strings.isSwahili ? 'Inasubiri' : 'Pending';
    }
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(10),
        border: Border.all(color: const Color(0xFFE8E8E8)),
      ),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(8),
            decoration: BoxDecoration(
              color: const Color(0xFFF5F5F5),
              borderRadius: BorderRadius.circular(8),
            ),
            child: const Icon(Icons.receipt_long_rounded, size: 18, color: _kSecondary),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(expense.description,
                    style: const TextStyle(fontSize: 13, fontWeight: FontWeight.w600, color: _kPrimary),
                    maxLines: 1, overflow: TextOverflow.ellipsis),
                Text(expense.categoryName,
                    style: const TextStyle(fontSize: 11, color: _kSecondary)),
                Text(strings.formatDateShort(expense.createdAt),
                    style: const TextStyle(fontSize: 10, color: _kSecondary)),
              ],
            ),
          ),
          Column(
            crossAxisAlignment: CrossAxisAlignment.end,
            children: [
              Text(
                '${expense.currency} ${expense.amount.toStringAsFixed(0)}',
                style: const TextStyle(fontSize: 12, fontWeight: FontWeight.w700, color: _kPrimary),
              ),
              Container(
                margin: const EdgeInsets.only(top: 3),
                padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                decoration: BoxDecoration(
                  color: _statusColor.withValues(alpha: 0.12),
                  borderRadius: BorderRadius.circular(4),
                ),
                child: Text(_statusLabel,
                    style: TextStyle(fontSize: 9, color: _statusColor, fontWeight: FontWeight.w600)),
              ),
            ],
          ),
        ],
      ),
    );
  }
}

// ── Shared ────────────────────────────────────────────────────────────────────

class _SectionLabel extends StatelessWidget {
  final String text;
  const _SectionLabel(this.text);

  @override
  Widget build(BuildContext context) => Text(text,
      style: const TextStyle(fontSize: 13, fontWeight: FontWeight.w700, color: _kSecondary, letterSpacing: 0.5));
}

class _Field extends StatelessWidget {
  final TextEditingController controller;
  final String label;
  final TextInputType keyboardType;

  const _Field({required this.controller, required this.label, this.keyboardType = TextInputType.text});

  @override
  Widget build(BuildContext context) {
    return TextField(
      controller: controller,
      keyboardType: keyboardType,
      decoration: InputDecoration(
        labelText: label,
        labelStyle: const TextStyle(color: _kSecondary, fontSize: 13),
        border: const OutlineInputBorder(),
        contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
      ),
    );
  }
}

class _ErrorView extends StatelessWidget {
  final String message;
  final VoidCallback onRetry;
  const _ErrorView({required this.message, required this.onRetry});

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Text(message, style: const TextStyle(color: _kSecondary), textAlign: TextAlign.center),
          const SizedBox(height: 12),
          OutlinedButton(onPressed: onRetry, child: Text(Localizations.localeOf(context).languageCode == 'sw' ? 'Jaribu tena' : 'Try again')),
        ],
      ),
    );
  }
}
