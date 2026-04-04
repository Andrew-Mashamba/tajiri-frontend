// lib/screens/budget/budget_home_screen.dart
import 'package:flutter/material.dart';
import '../../models/budget_models.dart';
import '../../services/budget_service.dart';
import 'add_transaction_screen.dart';
import 'envelope_detail_screen.dart';
import 'goals_screen.dart';
import 'monthly_report_screen.dart';

// DESIGN.md tokens
const Color _kBackground = Color(0xFFFAFAFA);
const Color _kSurface = Color(0xFFFFFFFF);
const Color _kPrimary = Color(0xFF1A1A1A);
const Color _kSecondary = Color(0xFF666666);
const Color _kTertiary = Color(0xFF999999);
const Color _kDivider = Color(0xFFE0E0E0);
const Color _kSuccess = Color(0xFF4CAF50);
const Color _kWarning = Color(0xFFFF9800);
const Color _kError = Color(0xFFE53935);

class BudgetHomeScreen extends StatefulWidget {
  final int userId;

  const BudgetHomeScreen({super.key, required this.userId});

  @override
  State<BudgetHomeScreen> createState() => _BudgetHomeScreenState();
}

class _BudgetHomeScreenState extends State<BudgetHomeScreen> {
  final BudgetService _service = BudgetService();
  BudgetPeriod? _period;
  List<BudgetEnvelope> _envelopes = [];
  List<BudgetGoal> _goals = [];
  Map<BudgetSource, double> _incomeBreakdown = {};
  List<BudgetTransaction> _recentTransactions = [];
  bool _isLoading = true;
  bool _isSyncing = false;

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
      _service.getGoals(),
      _service.getCurrentIncomeBreakdown(),
      _service.getTransactions(limit: 5),
    ]);

    if (mounted) {
      setState(() {
        _period = results[0] as BudgetPeriod;
        _envelopes = results[1] as List<BudgetEnvelope>;
        _goals = results[2] as List<BudgetGoal>;
        _incomeBreakdown = results[3] as Map<BudgetSource, double>;
        _recentTransactions = results[4] as List<BudgetTransaction>;
        _isLoading = false;
      });
    }

    // Fire-and-forget auto-sync
    _autoSync();
  }

  Future<void> _autoSync() async {
    if (_isSyncing) return;
    setState(() => _isSyncing = true);
    final synced = await _service.syncFromTajiri(widget.userId);
    if (mounted) {
      setState(() => _isSyncing = false);
      if (synced > 0) _loadData(); // Reload if new transactions found
    }
  }

  @override
  Widget build(BuildContext context) {
    if (_isLoading) {
      return const Center(child: CircularProgressIndicator(strokeWidth: 2));
    }

    return Scaffold(
      backgroundColor: _kBackground,
      floatingActionButton: FloatingActionButton(
        onPressed: () async {
          final added = await Navigator.push<bool>(
            context,
            MaterialPageRoute(builder: (_) => const AddTransactionScreen()),
          );
          if (added == true) _loadData();
        },
        backgroundColor: _kPrimary,
        child: const Icon(Icons.add, color: Colors.white),
      ),
      body: RefreshIndicator(
        onRefresh: _loadData,
        color: _kPrimary,
        child: ListView(
          padding: const EdgeInsets.all(16),
          children: [
            _buildMonthHeader(),
            const SizedBox(height: 16),
            _buildIncomeCard(),
            const SizedBox(height: 16),
            _buildSectionHeader('BAHASHA', onAction: _addEnvelope, actionLabel: '+ Ongeza'),
            const SizedBox(height: 8),
            ..._envelopes.map(_buildEnvelopeCard),
            const SizedBox(height: 20),
            _buildSectionHeader('MALENGO', onAction: _openGoals, actionLabel: 'Tazama'),
            const SizedBox(height: 8),
            if (_goals.isEmpty)
              _buildEmptyGoals()
            else
              ..._goals.take(3).map(_buildGoalCard),
            const SizedBox(height: 20),
            _buildSectionHeader('MIAMALA YA HIVI KARIBUNI'),
            const SizedBox(height: 8),
            if (_recentTransactions.isEmpty)
              _buildEmptyTransactions()
            else
              ..._recentTransactions.map(_buildTransactionRow),
            const SizedBox(height: 80), // Space for FAB
          ],
        ),
      ),
    );
  }

  // ── Month Header ──────────────────────────────────────────────────────

  Widget _buildMonthHeader() {
    final now = DateTime.now();
    final months = [
      'Januari', 'Februari', 'Machi', 'Aprili', 'Mei', 'Juni',
      'Julai', 'Agosti', 'Septemba', 'Oktoba', 'Novemba', 'Desemba'
    ];
    return Row(
      children: [
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                '${months[now.month - 1]} ${now.year}',
                style: const TextStyle(fontSize: 20, fontWeight: FontWeight.bold, color: _kPrimary),
              ),
              if (_isSyncing)
                const Padding(
                  padding: EdgeInsets.only(top: 4),
                  child: Text('Inasawazisha...', style: TextStyle(fontSize: 12, color: _kTertiary)),
                ),
            ],
          ),
        ),
        IconButton(
          icon: const Icon(Icons.bar_chart_rounded, color: _kPrimary),
          tooltip: 'Ripoti',
          onPressed: () => Navigator.push(
            context,
            MaterialPageRoute(builder: (_) => MonthlyReportScreen(userId: widget.userId)),
          ),
        ),
      ],
    );
  }

  // ── Income Card ───────────────────────────────────────────────────────

  Widget _buildIncomeCard() {
    final period = _period ?? BudgetPeriod(year: 0, month: 0, totalIncome: 0, totalAllocated: 0, totalSpent: 0);
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: _kSurface,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [BoxShadow(color: Colors.black.withValues(alpha: 0.06), blurRadius: 4, offset: const Offset(0, 2))],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              const Text('Mapato', style: TextStyle(fontSize: 13, color: _kSecondary, fontWeight: FontWeight.w500)),
              const Spacer(),
              Text(
                _formatTZS(period.totalIncome),
                style: const TextStyle(fontSize: 22, fontWeight: FontWeight.bold, color: _kPrimary),
              ),
            ],
          ),
          const SizedBox(height: 12),
          Row(
            children: [
              _buildMiniStat('Imegawanywa', _formatTZS(period.totalAllocated), _kPrimary),
              const SizedBox(width: 16),
              _buildMiniStat('Imetumika', _formatTZS(period.totalSpent), _kError),
              const SizedBox(width: 16),
              _buildMiniStat('Imebaki', _formatTZS(period.remaining), _kSuccess),
            ],
          ),
          if (_incomeBreakdown.isNotEmpty) ...[
            const SizedBox(height: 12),
            const Divider(height: 1, color: _kDivider),
            const SizedBox(height: 12),
            Wrap(
              spacing: 12,
              runSpacing: 6,
              children: _incomeBreakdown.entries.map((e) => Text(
                '${e.key.label}: ${_formatTZS(e.value)}',
                style: const TextStyle(fontSize: 11, color: _kTertiary),
              )).toList(),
            ),
          ],
        ],
      ),
    );
  }

  Widget _buildMiniStat(String label, String value, Color color) {
    return Expanded(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(value, style: TextStyle(fontSize: 14, fontWeight: FontWeight.bold, color: color)),
          Text(label, style: const TextStyle(fontSize: 10, color: _kTertiary)),
        ],
      ),
    );
  }

  // ── Envelope Card ─────────────────────────────────────────────────────

  Widget _buildEnvelopeCard(BudgetEnvelope envelope) {
    final pct = envelope.percentUsed.clamp(0, 100) / 100;
    final isOver = envelope.isOverBudget;
    final barColor = isOver ? _kError : (pct > 0.8 ? _kWarning : _kPrimary);

    return GestureDetector(
      onTap: () async {
        await Navigator.push(
          context,
          MaterialPageRoute(builder: (_) => EnvelopeDetailScreen(envelope: envelope)),
        );
        _loadData();
      },
      child: Container(
        margin: const EdgeInsets.only(bottom: 8),
        padding: const EdgeInsets.all(14),
        decoration: BoxDecoration(
          color: _kSurface,
          borderRadius: BorderRadius.circular(12),
          boxShadow: [BoxShadow(color: Colors.black.withValues(alpha: 0.04), blurRadius: 3, offset: const Offset(0, 1))],
        ),
        child: Column(
          children: [
            Row(
              children: [
                Icon(_envelopeIcon(envelope.icon), size: 20, color: Color(int.parse('FF${envelope.color}', radix: 16))),
                const SizedBox(width: 10),
                Expanded(
                  child: Text(
                    envelope.name,
                    style: const TextStyle(fontSize: 14, fontWeight: FontWeight.w600, color: _kPrimary),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                ),
                Text(
                  isOver
                      ? '-${_formatTZS(envelope.spentAmount - envelope.allocatedAmount)}'
                      : _formatTZS(envelope.remainingAmount),
                  style: TextStyle(
                    fontSize: 13,
                    fontWeight: FontWeight.w600,
                    color: isOver ? _kError : _kSecondary,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 8),
            ClipRRect(
              borderRadius: BorderRadius.circular(4),
              child: LinearProgressIndicator(
                value: pct.clamp(0.0, 1.0),
                backgroundColor: _kDivider,
                valueColor: AlwaysStoppedAnimation(barColor),
                minHeight: 6,
              ),
            ),
            const SizedBox(height: 4),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  '${_formatTZS(envelope.spentAmount)} / ${_formatTZS(envelope.allocatedAmount)}',
                  style: const TextStyle(fontSize: 10, color: _kTertiary),
                ),
                Text(
                  '${envelope.percentUsed.toStringAsFixed(0)}%',
                  style: TextStyle(fontSize: 10, fontWeight: FontWeight.w600, color: barColor),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  // ── Goal Card ─────────────────────────────────────────────────────────

  Widget _buildGoalCard(BudgetGoal goal) {
    final pct = goal.percentComplete / 100;
    return Container(
      margin: const EdgeInsets.only(bottom: 8),
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: _kSurface,
        borderRadius: BorderRadius.circular(12),
        boxShadow: [BoxShadow(color: Colors.black.withValues(alpha: 0.04), blurRadius: 3, offset: const Offset(0, 1))],
      ),
      child: Row(
        children: [
          Icon(_envelopeIcon(goal.icon), size: 20, color: _kPrimary),
          const SizedBox(width: 10),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(goal.name, style: const TextStyle(fontSize: 13, fontWeight: FontWeight.w600, color: _kPrimary)),
                const SizedBox(height: 4),
                ClipRRect(
                  borderRadius: BorderRadius.circular(4),
                  child: LinearProgressIndicator(
                    value: pct.clamp(0.0, 1.0),
                    backgroundColor: _kDivider,
                    valueColor: AlwaysStoppedAnimation(goal.isComplete ? _kSuccess : _kPrimary),
                    minHeight: 5,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  '${_formatTZS(goal.savedAmount)} / ${_formatTZS(goal.targetAmount)}'
                  '${goal.monthsRemaining != null ? ' — Miezi ${goal.monthsRemaining}' : ''}',
                  style: const TextStyle(fontSize: 10, color: _kTertiary),
                ),
              ],
            ),
          ),
          const SizedBox(width: 8),
          Text(
            '${goal.percentComplete.toStringAsFixed(0)}%',
            style: const TextStyle(fontSize: 13, fontWeight: FontWeight.bold, color: _kPrimary),
          ),
        ],
      ),
    );
  }

  Widget _buildEmptyGoals() {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: _kSurface,
        borderRadius: BorderRadius.circular(12),
      ),
      child: Column(
        children: [
          const Icon(Icons.flag_outlined, size: 32, color: _kTertiary),
          const SizedBox(height: 8),
          const Text('Bado hakuna lengo', style: TextStyle(color: _kSecondary, fontSize: 13)),
          const SizedBox(height: 8),
          TextButton(
            onPressed: _openGoals,
            child: const Text('Ongeza Lengo'),
          ),
        ],
      ),
    );
  }

  // ── Transaction Row ───────────────────────────────────────────────────

  Widget _buildTransactionRow(BudgetTransaction txn) {
    final isIncome = txn.isIncome;
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 6),
      child: Row(
        children: [
          Container(
            width: 32,
            height: 32,
            decoration: BoxDecoration(
              color: (isIncome ? _kSuccess : _kError).withValues(alpha: 0.1),
              borderRadius: BorderRadius.circular(8),
            ),
            child: Icon(
              isIncome ? Icons.arrow_downward_rounded : Icons.arrow_upward_rounded,
              size: 16,
              color: isIncome ? _kSuccess : _kError,
            ),
          ),
          const SizedBox(width: 10),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  txn.description,
                  style: const TextStyle(fontSize: 13, color: _kPrimary),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
                Text(txn.source.label, style: const TextStyle(fontSize: 10, color: _kTertiary)),
              ],
            ),
          ),
          Text(
            '${isIncome ? '+' : '-'}${_formatTZS(txn.amount)}',
            style: TextStyle(
              fontSize: 13,
              fontWeight: FontWeight.w600,
              color: isIncome ? _kSuccess : _kPrimary,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildEmptyTransactions() {
    return const Padding(
      padding: EdgeInsets.all(20),
      child: Center(
        child: Text('Hakuna miamala bado', style: TextStyle(color: _kTertiary, fontSize: 13)),
      ),
    );
  }

  // ── Section Header ────────────────────────────────────────────────────

  Widget _buildSectionHeader(String title, {VoidCallback? onAction, String? actionLabel}) {
    return Row(
      children: [
        Text(
          title,
          style: const TextStyle(fontSize: 11, fontWeight: FontWeight.w600, color: _kTertiary, letterSpacing: 0.8),
        ),
        const Spacer(),
        if (onAction != null && actionLabel != null)
          GestureDetector(
            onTap: onAction,
            child: Text(
              actionLabel,
              style: const TextStyle(fontSize: 12, fontWeight: FontWeight.w600, color: _kPrimary),
            ),
          ),
      ],
    );
  }

  // ── Navigation ────────────────────────────────────────────────────────

  void _addEnvelope() {
    showEnvelopeDialog(context, onSaved: _loadData);
  }

  void _openGoals() {
    Navigator.push(
      context,
      MaterialPageRoute(builder: (_) => GoalsScreen(userId: widget.userId)),
    ).then((_) => _loadData());
  }

  // ── Helpers ───────────────────────────────────────────────────────────

  static String _formatTZS(double amount) {
    if (amount >= 1000000) return 'TZS ${(amount / 1000000).toStringAsFixed(1)}M';
    if (amount >= 1000) return 'TZS ${(amount / 1000).toStringAsFixed(0)}K';
    return 'TZS ${amount.toStringAsFixed(0)}';
  }

  static IconData _envelopeIcon(String name) {
    switch (name) {
      case 'home': return Icons.home_outlined;
      case 'restaurant': return Icons.restaurant_outlined;
      case 'directions_car': return Icons.directions_car_outlined;
      case 'school': return Icons.school_outlined;
      case 'receipt_long': return Icons.receipt_long_outlined;
      case 'savings': return Icons.savings_outlined;
      case 'phone_android': return Icons.phone_android_outlined;
      case 'medical_services': return Icons.medical_services_outlined;
      case 'warning': return Icons.warning_outlined;
      case 'sports_esports': return Icons.sports_esports_outlined;
      case 'flag': return Icons.flag_outlined;
      case 'phone': return Icons.phone_outlined;
      case 'shopping_bag': return Icons.shopping_bag_outlined;
      default: return Icons.circle_outlined;
    }
  }
}

/// Show envelope add/edit dialog
void showEnvelopeDialog(
  BuildContext context, {
  BudgetEnvelope? envelope,
  required VoidCallback onSaved,
}) {
  showModalBottomSheet(
    context: context,
    isScrollControlled: true,
    backgroundColor: Colors.transparent,
    builder: (_) => _EnvelopeDialog(envelope: envelope, onSaved: onSaved),
  );
}

class _EnvelopeDialog extends StatefulWidget {
  final BudgetEnvelope? envelope;
  final VoidCallback onSaved;

  const _EnvelopeDialog({this.envelope, required this.onSaved});

  @override
  State<_EnvelopeDialog> createState() => _EnvelopeDialogState();
}

class _EnvelopeDialogState extends State<_EnvelopeDialog> {
  final BudgetService _service = BudgetService();
  final _nameController = TextEditingController();
  final _amountController = TextEditingController();
  String _selectedIcon = 'circle';
  String _selectedColor = '1A1A1A';
  bool _isSaving = false;

  bool get _isEditing => widget.envelope != null;

  static const _icons = [
    'home', 'restaurant', 'directions_car', 'school', 'receipt_long',
    'savings', 'phone_android', 'medical_services', 'warning',
    'sports_esports', 'shopping_bag', 'flag',
  ];

  static const _colors = [
    '1A1A1A', '4CAF50', '2196F3', 'FF9800', '9C27B0',
    '009688', '607D8B', 'E53935', 'FF5722', '795548',
  ];

  @override
  void initState() {
    super.initState();
    if (_isEditing) {
      _nameController.text = widget.envelope!.name;
      _amountController.text = widget.envelope!.allocatedAmount.toStringAsFixed(0);
      _selectedIcon = widget.envelope!.icon;
      _selectedColor = widget.envelope!.color;
    }
  }

  @override
  void dispose() {
    _nameController.dispose();
    _amountController.dispose();
    super.dispose();
  }

  Future<void> _save() async {
    final name = _nameController.text.trim();
    final amount = double.tryParse(_amountController.text.replaceAll(',', ''));
    if (name.isEmpty || amount == null) return;

    setState(() => _isSaving = true);

    if (_isEditing) {
      await _service.updateEnvelope(widget.envelope!.copyWith(
        name: name,
        allocatedAmount: amount,
        icon: _selectedIcon,
        color: _selectedColor,
      ));
    } else {
      await _service.createEnvelope(
        name: name,
        icon: _selectedIcon,
        allocatedAmount: amount,
        color: _selectedColor,
      );
    }

    if (mounted) {
      widget.onSaved();
      Navigator.pop(context);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: EdgeInsets.only(
        left: 20, right: 20, top: 20,
        bottom: MediaQuery.of(context).viewInsets.bottom + 20,
      ),
      decoration: const BoxDecoration(
        color: _kSurface,
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Center(
            child: Container(
              width: 40, height: 4,
              decoration: BoxDecoration(color: _kDivider, borderRadius: BorderRadius.circular(2)),
            ),
          ),
          const SizedBox(height: 16),
          Text(
            _isEditing ? 'Hariri Bahasha' : 'Bahasha Mpya',
            style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: _kPrimary),
          ),
          const SizedBox(height: 16),

          // Name
          TextField(
            controller: _nameController,
            textCapitalization: TextCapitalization.sentences,
            decoration: InputDecoration(
              labelText: 'Jina',
              filled: true,
              fillColor: _kBackground,
              border: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: BorderSide.none),
            ),
          ),
          const SizedBox(height: 12),

          // Amount
          TextField(
            controller: _amountController,
            keyboardType: TextInputType.number,
            decoration: InputDecoration(
              labelText: 'Kiasi (TZS)',
              prefixText: 'TZS ',
              filled: true,
              fillColor: _kBackground,
              border: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: BorderSide.none),
            ),
          ),
          const SizedBox(height: 12),

          // Icon picker
          const Text('Ikoni', style: TextStyle(fontSize: 12, color: _kSecondary)),
          const SizedBox(height: 8),
          Wrap(
            spacing: 8,
            runSpacing: 8,
            children: _icons.map((icon) {
              final selected = _selectedIcon == icon;
              return GestureDetector(
                onTap: () => setState(() => _selectedIcon = icon),
                child: Container(
                  width: 40, height: 40,
                  decoration: BoxDecoration(
                    color: selected ? _kPrimary : _kBackground,
                    borderRadius: BorderRadius.circular(10),
                  ),
                  child: Icon(
                    _BudgetHomeScreenState._envelopeIcon(icon),
                    size: 20,
                    color: selected ? Colors.white : _kSecondary,
                  ),
                ),
              );
            }).toList(),
          ),
          const SizedBox(height: 12),

          // Color picker
          const Text('Rangi', style: TextStyle(fontSize: 12, color: _kSecondary)),
          const SizedBox(height: 8),
          Wrap(
            spacing: 8,
            runSpacing: 8,
            children: _colors.map((color) {
              final selected = _selectedColor == color;
              return GestureDetector(
                onTap: () => setState(() => _selectedColor = color),
                child: Container(
                  width: 32, height: 32,
                  decoration: BoxDecoration(
                    color: Color(int.parse('FF$color', radix: 16)),
                    borderRadius: BorderRadius.circular(8),
                    border: selected ? Border.all(color: _kPrimary, width: 2) : null,
                  ),
                ),
              );
            }).toList(),
          ),
          const SizedBox(height: 20),

          // Save button
          SizedBox(
            width: double.infinity,
            child: FilledButton(
              onPressed: _isSaving ? null : _save,
              style: FilledButton.styleFrom(
                backgroundColor: _kPrimary,
                minimumSize: const Size.fromHeight(48),
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
              ),
              child: _isSaving
                  ? const SizedBox(width: 20, height: 20, child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white))
                  : Text(_isEditing ? 'Hifadhi' : 'Ongeza', style: const TextStyle(fontSize: 15, fontWeight: FontWeight.w600)),
            ),
          ),
        ],
      ),
    );
  }
}
