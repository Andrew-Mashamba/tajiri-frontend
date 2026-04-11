// lib/budget/pages/envelope_detail_page.dart
import 'dart:math' as math;
import 'package:flutter/material.dart';
import '../../l10n/app_strings_scope.dart';
import '../models/budget_models.dart';
import '../services/budget_service.dart';
import '../../services/expenditure_service.dart';
import '../../services/local_storage_service.dart';
import '../widgets/spending_pace_badge.dart';

// ── Design tokens ────────────────────────────────────────────────────────────
const Color _kBg = Color(0xFFFAFAFA);
const Color _kPrimary = Color(0xFF1A1A1A);
const Color _kSecondary = Color(0xFF666666);
const Color _kTertiary = Color(0xFF999999);
const Color _kSurface = Color(0xFFFFFFFF);
const Color _kDivider = Color(0xFFE0E0E0);
const Color _kSuccess = Color(0xFF4CAF50);
const Color _kWarning = Color(0xFFFF9800);
const Color _kError = Color(0xFFE53935);

/// Detail screen for a single budget envelope.
///
/// Shows header with allocation/spent/remaining, progress bar, daily allowance,
/// spending pace, edit/move-money actions, and transaction list.
class EnvelopeDetailPage extends StatefulWidget {
  final BudgetEnvelope envelope;

  const EnvelopeDetailPage({super.key, required this.envelope});

  @override
  State<EnvelopeDetailPage> createState() => _EnvelopeDetailPageState();
}

class _EnvelopeDetailPageState extends State<EnvelopeDetailPage> {
  BudgetEnvelope? _envelope;
  SpendingPace? _pace;
  List<ExpenditureRecord> _transactions = [];
  bool _isLoading = true;
  String? _error;

  @override
  void initState() {
    super.initState();
    _envelope = widget.envelope;
    _loadData();
  }

  // ── Data loading ─────────────────────────────────────────────────────────

  Future<void> _loadData() async {
    setState(() {
      _isLoading = true;
      _error = null;
    });

    try {
      final storage = await LocalStorageService.getInstance();
      final token = storage.getAuthToken();
      final userId = storage.getUser()?.userId;
      if (token == null || userId == null) {
        if (!mounted) return;
        setState(() {
          _error = 'Auth token missing';
          _isLoading = false;
        });
        return;
      }

      final now = DateTime.now();
      final category = (widget.envelope.moduleTag ?? widget.envelope.nameEn).toLowerCase();

      // Parallel load: transactions, spending pace, refreshed envelope data
      final results = await Future.wait([
        ExpenditureService.getExpenditures(
          token: token,
          category: category,
          from: DateTime(now.year, now.month, 1),
          to: DateTime(now.year, now.month + 1, 0, 23, 59, 59),
        ),
        ExpenditureService.getSpendingPace(
          token: token,
          category: category,
          year: now.year,
          month: now.month,
        ),
        BudgetService.getUserEnvelopes(token, userId),
      ]);

      final txnResult = results[0] as ExpenditureListResult;
      final pace = results[1] as SpendingPace?;
      final envelopeResult = results[2] as EnvelopeListResult;

      // Find refreshed envelope
      BudgetEnvelope updated = widget.envelope;
      if (envelopeResult.success) {
        final match = envelopeResult.envelopes
            .where((e) => e.id == widget.envelope.id);
        if (match.isNotEmpty) updated = match.first;
      }

      if (!mounted) return;
      setState(() {
        _envelope = updated;
        _pace = pace;
        _transactions = txnResult.success ? txnResult.records : [];
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

  // ── Edit allocation ──────────────────────────────────────────────────────

  Future<void> _editAllocation() async {
    final s = AppStringsScope.of(context);
    final isSwahili = s?.isSwahili ?? false;
    final env = _envelope ?? widget.envelope;

    final controller = TextEditingController(
      text: env.allocatedAmount.toStringAsFixed(0),
    );

    final result = await showDialog<double>(
      context: context,
      builder: (ctx) => AlertDialog(
        backgroundColor: _kSurface,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        title: Text(
          isSwahili ? 'Badilisha Kiasi' : 'Edit Allocation',
          style: const TextStyle(
            fontSize: 18,
            fontWeight: FontWeight.bold,
            color: _kPrimary,
          ),
        ),
        content: TextField(
          controller: controller,
          keyboardType: TextInputType.number,
          autofocus: true,
          decoration: InputDecoration(
            prefixText: 'TZS ',
            filled: true,
            fillColor: _kBg,
            border: OutlineInputBorder(
              borderRadius: BorderRadius.circular(12),
              borderSide: BorderSide.none,
            ),
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: Text(
              isSwahili ? 'Ghairi' : 'Cancel',
              style: const TextStyle(color: _kSecondary),
            ),
          ),
          FilledButton(
            onPressed: () {
              final val =
                  double.tryParse(controller.text.replaceAll(',', ''));
              Navigator.pop(ctx, val);
            },
            style: FilledButton.styleFrom(
              backgroundColor: _kPrimary,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(10),
              ),
            ),
            child: Text(isSwahili ? 'Hifadhi' : 'Save'),
          ),
        ],
      ),
    );

    controller.dispose();

    if (result == null || result < 0) return;
    if (!mounted) return;

    try {
      final messenger = ScaffoldMessenger.of(context);
      final storage = await LocalStorageService.getInstance();
      final token = storage.getAuthToken();
      final userId = storage.getUser()?.userId;
      if (token == null || userId == null || env.id == null) return;

      final updated = await BudgetService.updateEnvelope(
        token,
        userId,
        env.id!,
        {'allocated_amount': result},
      );

      if (!mounted) return;
      if (updated != null) {
        setState(() => _envelope = updated);
        _loadData();
      } else {
        messenger.showSnackBar(
          SnackBar(
            content: Text(
              isSwahili ? 'Imeshindikana kuhifadhi' : 'Failed to save',
            ),
          ),
        );
      }
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(e.toString())),
      );
    }
  }

  // ── Move money ───────────────────────────────────────────────────────────

  Future<void> _moveMoney() async {
    final s = AppStringsScope.of(context);
    final isSwahili = s?.isSwahili ?? false;
    final env = _envelope ?? widget.envelope;

    final storage = await LocalStorageService.getInstance();
    final token = storage.getAuthToken();
    final userId = storage.getUser()?.userId;
    if (token == null || userId == null) return;

    // Load all envelopes for the picker
    final envelopeResult = await BudgetService.getUserEnvelopes(token, userId);
    if (!mounted) return;
    if (!envelopeResult.success) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            isSwahili ? 'Imeshindikana kupakia' : 'Failed to load envelopes',
          ),
        ),
      );
      return;
    }

    // Filter out current envelope
    final otherEnvelopes = envelopeResult.envelopes
        .where((e) => e.id != env.id && e.isVisible)
        .toList();

    if (otherEnvelopes.isEmpty) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            isSwahili
                ? 'Hakuna bahasha nyingine'
                : 'No other envelopes available',
          ),
        ),
      );
      return;
    }

    BudgetEnvelope? targetEnvelope;
    final amountController = TextEditingController();

    final confirmed = await showModalBottomSheet<bool>(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (ctx) => StatefulBuilder(
        builder: (ctx, setSheetState) {
          return Container(
            padding: EdgeInsets.only(
              left: 20,
              right: 20,
              top: 20,
              bottom: MediaQuery.of(ctx).viewInsets.bottom + 20,
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
                    width: 40,
                    height: 4,
                    decoration: BoxDecoration(
                      color: _kDivider,
                      borderRadius: BorderRadius.circular(2),
                    ),
                  ),
                ),
                const SizedBox(height: 16),
                Text(
                  isSwahili ? 'Hamisha Pesa' : 'Move Money',
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: const TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                    color: _kPrimary,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  isSwahili
                      ? 'Kutoka: ${env.displayName(true)}'
                      : 'From: ${env.displayName(false)}',
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: const TextStyle(fontSize: 13, color: _kSecondary),
                ),
                const SizedBox(height: 16),

                // Target envelope picker
                Text(
                  isSwahili ? 'Kwenda' : 'To',
                  style: const TextStyle(fontSize: 12, color: _kSecondary),
                ),
                const SizedBox(height: 8),
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 12),
                  decoration: BoxDecoration(
                    color: _kBg,
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: DropdownButtonHideUnderline(
                    child: DropdownButton<int>(
                      isExpanded: true,
                      value: targetEnvelope?.id,
                      hint: Text(
                        isSwahili ? 'Chagua bahasha' : 'Select envelope',
                        style: const TextStyle(color: _kTertiary),
                      ),
                      items: otherEnvelopes.map((e) {
                        return DropdownMenuItem<int>(
                          value: e.id,
                          child: Text(
                            e.displayName(isSwahili),
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                          ),
                        );
                      }).toList(),
                      onChanged: (id) {
                        setSheetState(() {
                          targetEnvelope = otherEnvelopes
                              .firstWhere((e) => e.id == id);
                        });
                      },
                    ),
                  ),
                ),
                const SizedBox(height: 16),

                // Amount input
                TextField(
                  controller: amountController,
                  keyboardType: TextInputType.number,
                  decoration: InputDecoration(
                    labelText: isSwahili ? 'Kiasi (TZS)' : 'Amount (TZS)',
                    prefixText: 'TZS ',
                    filled: true,
                    fillColor: _kBg,
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(12),
                      borderSide: BorderSide.none,
                    ),
                  ),
                ),
                const SizedBox(height: 20),

                SizedBox(
                  width: double.infinity,
                  height: 48,
                  child: FilledButton(
                    onPressed: (targetEnvelope != null)
                        ? () => Navigator.pop(ctx, true)
                        : null,
                    style: FilledButton.styleFrom(
                      backgroundColor: _kPrimary,
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12),
                      ),
                    ),
                    child: Text(
                      isSwahili ? 'Hamisha' : 'Move',
                      style: const TextStyle(
                        fontSize: 15,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ),
                ),
              ],
            ),
          );
        },
      ),
    );

    if (confirmed != true || targetEnvelope == null) {
      amountController.dispose();
      return;
    }

    final moveAmount =
        double.tryParse(amountController.text.replaceAll(',', ''));
    amountController.dispose();

    if (moveAmount == null || moveAmount <= 0) return;
    if (!mounted) return;

    try {
      final messenger = ScaffoldMessenger.of(context);

      // Reduce source
      final sourceOldAmount = env.allocatedAmount;
      final sourceUpdate = await BudgetService.updateEnvelope(
        token,
        userId,
        env.id!,
        {'allocated_amount': sourceOldAmount - moveAmount},
      );

      if (sourceUpdate == null) {
        if (!mounted) return;
        messenger.showSnackBar(
          SnackBar(
            content: Text(
              isSwahili ? 'Imeshindikana kuhamisha' : 'Move failed',
            ),
          ),
        );
        return;
      }

      // Increase target
      final targetUpdate = await BudgetService.updateEnvelope(
        token,
        userId,
        targetEnvelope!.id!,
        {
          'allocated_amount':
              targetEnvelope!.allocatedAmount + moveAmount,
        },
      );

      if (targetUpdate == null) {
        // Rollback source envelope
        await BudgetService.updateEnvelope(
          token,
          userId,
          env.id!,
          {'allocated_amount': sourceOldAmount},
        );
        if (!mounted) return;
        messenger.showSnackBar(
          SnackBar(
            content: Text(
              isSwahili ? 'Imeshindikana kuhamisha' : 'Move failed',
            ),
          ),
        );
        return;
      }

      if (!mounted) return;
      setState(() => _envelope = sourceUpdate);
      _loadData();
      messenger.showSnackBar(
        SnackBar(
          content: Text(
            isSwahili
                ? 'Pesa imehamishwa'
                : 'Money moved successfully',
          ),
        ),
      );
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(e.toString())),
      );
    }
  }

  // ── Recategorize transaction ─────────────────────────────────────────────

  Future<void> _recategorizeTransaction(ExpenditureRecord txn) async {
    final s = AppStringsScope.of(context);
    final isSwahili = s?.isSwahili ?? false;

    final storage = await LocalStorageService.getInstance();
    final token = storage.getAuthToken();
    final userId = storage.getUser()?.userId;
    if (token == null || userId == null) return;

    // Load all envelopes
    final envelopeResult = await BudgetService.getUserEnvelopes(token, userId);
    if (!mounted) return;
    if (!envelopeResult.success || envelopeResult.envelopes.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            isSwahili ? 'Imeshindikana kupakia bahasha' : 'Failed to load envelopes',
          ),
        ),
      );
      return;
    }

    final envelopes = envelopeResult.envelopes
        .where((e) => e.isVisible)
        .toList();

    String? selectedCategory;

    final confirmed = await showModalBottomSheet<bool>(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (ctx) => StatefulBuilder(
        builder: (ctx, setSheetState) {
          return Container(
            padding: EdgeInsets.only(
              left: 20,
              right: 20,
              top: 20,
              bottom: MediaQuery.of(ctx).viewInsets.bottom + 20,
            ),
            constraints: BoxConstraints(
              maxHeight: MediaQuery.of(ctx).size.height * 0.6,
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
                    width: 40,
                    height: 4,
                    decoration: BoxDecoration(
                      color: _kDivider,
                      borderRadius: BorderRadius.circular(2),
                    ),
                  ),
                ),
                const SizedBox(height: 16),
                Text(
                  isSwahili ? 'Badilisha Kategoria' : 'Reassign Category',
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: const TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                    color: _kPrimary,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  '${txn.description.isNotEmpty ? txn.description : txn.category} - ${_formatTZS(txn.amount)}',
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                  style: const TextStyle(fontSize: 13, color: _kSecondary),
                ),
                const SizedBox(height: 4),
                Text(
                  '${isSwahili ? "Sasa hivi" : "Currently"}: ${txn.category}',
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: const TextStyle(fontSize: 12, color: _kTertiary),
                ),
                const SizedBox(height: 16),
                Flexible(
                  child: ListView.separated(
                    shrinkWrap: true,
                    itemCount: envelopes.length,
                    separatorBuilder: (_, __) =>
                        const Divider(height: 1, color: _kDivider),
                    itemBuilder: (_, i) {
                      final env = envelopes[i];
                      final tag = (env.moduleTag ?? env.nameEn).toLowerCase();
                      final isSelected = selectedCategory == tag;
                      final isCurrent = txn.category == tag;

                      return ListTile(
                        dense: true,
                        contentPadding: EdgeInsets.zero,
                        leading: Text(
                          env.icon,
                          style: const TextStyle(fontSize: 20),
                        ),
                        title: Text(
                          env.displayName(isSwahili),
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          style: TextStyle(
                            fontSize: 14,
                            color: isCurrent ? _kTertiary : _kPrimary,
                            fontWeight:
                                isSelected ? FontWeight.bold : FontWeight.normal,
                          ),
                        ),
                        trailing: isCurrent
                            ? Text(
                                isSwahili ? 'Sasa hivi' : 'Current',
                                style: const TextStyle(
                                  fontSize: 11,
                                  color: _kTertiary,
                                ),
                              )
                            : isSelected
                                ? const Icon(Icons.check_circle_rounded,
                                    color: _kSuccess, size: 20)
                                : null,
                        onTap: isCurrent
                            ? null
                            : () {
                                setSheetState(() => selectedCategory = tag);
                              },
                      );
                    },
                  ),
                ),
                const SizedBox(height: 16),
                SizedBox(
                  width: double.infinity,
                  height: 48,
                  child: FilledButton(
                    onPressed: selectedCategory != null
                        ? () => Navigator.pop(ctx, true)
                        : null,
                    style: FilledButton.styleFrom(
                      backgroundColor: _kPrimary,
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12),
                      ),
                    ),
                    child: Text(
                      isSwahili ? 'Badilisha' : 'Reassign',
                      style: const TextStyle(
                        fontSize: 15,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ),
                ),
              ],
            ),
          );
        },
      ),
    );

    if (confirmed != true || selectedCategory == null) return;
    if (!mounted) return;

    final messenger = ScaffoldMessenger.of(context);
    final success = await ExpenditureService.recategorizeExpenditure(
      token,
      txn.id,
      selectedCategory!,
    );

    if (!mounted) return;
    if (success) {
      messenger.showSnackBar(
        SnackBar(
          content: Text(
            isSwahili ? 'Kategoria imebadilishwa' : 'Category reassigned',
          ),
        ),
      );
      _loadData();
    } else {
      messenger.showSnackBar(
        SnackBar(
          content: Text(
            isSwahili ? 'Imeshindikana kubadilisha' : 'Failed to reassign',
          ),
        ),
      );
    }
  }

  // ── Build ────────────────────────────────────────────────────────────────

  @override
  Widget build(BuildContext context) {
    final s = AppStringsScope.of(context);
    final isSwahili = s?.isSwahili ?? false;
    final env = _envelope ?? widget.envelope;

    return Scaffold(
      backgroundColor: _kBg,
      appBar: AppBar(
        backgroundColor: _kSurface,
        elevation: 0,
        scrolledUnderElevation: 1,
        title: Text(
          env.displayName(isSwahili),
          maxLines: 1,
          overflow: TextOverflow.ellipsis,
          style: const TextStyle(
            fontSize: 18,
            fontWeight: FontWeight.bold,
            color: _kPrimary,
          ),
        ),
        iconTheme: const IconThemeData(color: _kPrimary),
      ),
      body: SafeArea(
        child: _error != null && !_isLoading
            ? Center(
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    const Icon(Icons.error_outline_rounded,
                        size: 40, color: _kTertiary),
                    const SizedBox(height: 12),
                    Text(
                      isSwahili ? 'Imeshindikana kupakia' : 'Failed to load',
                      style: const TextStyle(color: _kSecondary, fontSize: 14),
                    ),
                    const SizedBox(height: 12),
                    SizedBox(
                      height: 48,
                      child: TextButton(
                        onPressed: _loadData,
                        child: Text(isSwahili ? 'Jaribu tena' : 'Retry'),
                      ),
                    ),
                  ],
                ),
              )
            : RefreshIndicator(
          onRefresh: _loadData,
          color: _kPrimary,
          child: ListView(
            padding: const EdgeInsets.all(16),
            children: [
              // Header card
              _buildHeaderCard(env, isSwahili),
              const SizedBox(height: 12),

              // Action buttons
              _buildActionButtons(isSwahili),
              const SizedBox(height: 12),

              // Rollover toggle
              _buildRolloverToggle(env, isSwahili),
              const SizedBox(height: 20),

              // Daily spending chart
              if (!_isLoading && _transactions.isNotEmpty)
                _buildDailyChart(_transactions, isSwahili),
              if (!_isLoading && _transactions.isNotEmpty)
                const SizedBox(height: 20),

              // Transactions section header
              _buildSectionHeader(
                isSwahili ? 'Miamala' : 'Transactions',
                trailing: '${_transactions.length}',
              ),
              const SizedBox(height: 8),

              // Transactions list
              if (_isLoading)
                const Center(
                  child: Padding(
                    padding: EdgeInsets.all(32),
                    child: CircularProgressIndicator(
                      strokeWidth: 2,
                      color: _kPrimary,
                    ),
                  ),
                )
              else if (_transactions.isEmpty)
                Padding(
                  padding: const EdgeInsets.all(32),
                  child: Center(
                    child: Text(
                      isSwahili ? 'Hakuna miamala bado' : 'No transactions yet',
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: const TextStyle(color: _kTertiary, fontSize: 13),
                    ),
                  ),
                )
              else
                ..._transactions.map((txn) => _buildTransactionTile(txn, isSwahili)),

              const SizedBox(height: 24),
            ],
          ),
        ),
      ),
    );
  }

  // ── Daily spending chart ──────────────────────────────────────────────────

  Widget _buildDailyChart(List<ExpenditureRecord> transactions, bool isSwahili) {
    final now = DateTime.now();
    final daysInMonth = DateTime(now.year, now.month + 1, 0).day;

    // Group spending by day of month
    final dailySpending = <int, double>{};
    for (final txn in transactions) {
      if (txn.date.year == now.year && txn.date.month == now.month) {
        dailySpending[txn.date.day] =
            (dailySpending[txn.date.day] ?? 0) + txn.amount;
      }
    }

    final maxAmount = dailySpending.values.fold<double>(
      0,
      (prev, val) => math.max(prev, val),
    );

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
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            isSwahili ? 'Matumizi ya Kila Siku' : 'Daily Spending',
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
          SizedBox(
            height: 100,
            child: SingleChildScrollView(
              scrollDirection: Axis.horizontal,
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.end,
                children: List.generate(daysInMonth, (i) {
                  final day = i + 1;
                  final amount = dailySpending[day] ?? 0;
                  final barHeight = maxAmount > 0
                      ? (amount / maxAmount * 72).clamp(0.0, 72.0)
                      : 0.0;
                  final isToday = day == now.day;

                  return Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 2),
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.end,
                      children: [
                        Container(
                          width: 14,
                          height: math.max(barHeight, amount > 0 ? 4.0 : 1.0),
                          decoration: BoxDecoration(
                            color: isToday
                                ? _kPrimary
                                : (amount > 0
                                    ? _kPrimary.withValues(alpha: 0.35)
                                    : _kDivider),
                            borderRadius: BorderRadius.circular(2),
                          ),
                        ),
                        const SizedBox(height: 4),
                        Text(
                          '$day',
                          style: TextStyle(
                            fontSize: 8,
                            color: isToday ? _kPrimary : _kTertiary,
                            fontWeight: isToday
                                ? FontWeight.bold
                                : FontWeight.normal,
                          ),
                        ),
                      ],
                    ),
                  );
                }),
              ),
            ),
          ),
        ],
      ),
    );
  }

  // ── Header card ──────────────────────────────────────────────────────────

  Widget _buildHeaderCard(BudgetEnvelope env, bool isSwahili) {
    final total = env.allocatedAmount + env.rolledOverAmount;
    final progress = total > 0
        ? (env.spentAmount / total).clamp(0.0, 1.5)
        : 0.0;
    final isOver = env.isOverBudget;
    final barColor = isOver
        ? _kError
        : (progress > 0.75 ? _kWarning : _kSuccess);

    // Compute daily allowance
    final now = DateTime.now();
    final daysInMonth =
        DateTime(now.year, now.month + 1, 0).day;
    final daysRemaining = daysInMonth - now.day + 1;
    final daily =
        daysRemaining > 0 ? (env.remainingAmount / daysRemaining) : 0.0;

    // Pace status derived from envelope or from _pace
    final paceStatus = _pace?.status ??
        (isOver
            ? 'over_budget'
            : (env.percentUsed > 75 ? 'caution' : 'on_track'));

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
        mainAxisSize: MainAxisSize.min,
        children: [
          // Allocated / Spent / Remaining row
          Row(
            children: [
              _buildStatColumn(
                isSwahili ? 'Imegawanywa' : 'Allocated',
                _formatTZS(env.allocatedAmount),
                _kPrimary,
              ),
              _buildStatColumn(
                isSwahili ? 'Matumizi' : 'Spent',
                _formatTZS(env.spentAmount),
                _kError,
              ),
              _buildStatColumn(
                isSwahili ? 'Imebaki' : 'Remaining',
                _formatTZS(env.remainingAmount.clamp(0, double.infinity)),
                isOver ? _kError : _kSuccess,
              ),
            ],
          ),
          const SizedBox(height: 16),

          // Progress bar
          ClipRRect(
            borderRadius: BorderRadius.circular(4),
            child: LinearProgressIndicator(
              value: progress.clamp(0.0, 1.0),
              minHeight: 8,
              backgroundColor: const Color(0xFFEEEEEE),
              valueColor: AlwaysStoppedAnimation<Color>(barColor),
            ),
          ),
          const SizedBox(height: 12),

          // Rolled-over amount (if any)
          if (env.rolledOverAmount > 0) ...[
            Row(
              children: [
                const Icon(Icons.redo_rounded, size: 14, color: _kTertiary),
                const SizedBox(width: 6),
                Expanded(
                  child: Text(
                    isSwahili
                        ? 'Imehamishwa: ${_formatTZS(env.rolledOverAmount)}'
                        : 'Rolled over: ${_formatTZS(env.rolledOverAmount)}',
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: const TextStyle(fontSize: 12, color: _kSecondary),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 8),
          ],

          // Daily allowance + pace badge
          Row(
            children: [
              Expanded(
                child: Text(
                  daily >= 0
                      ? 'TZS ${daily.toStringAsFixed(0)} ${isSwahili ? "kwa siku" : "per day"}'
                      : isSwahili
                          ? 'Umezidi bajeti'
                          : 'Over budget',
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: TextStyle(
                    fontSize: 13,
                    color: daily >= 0 ? _kSecondary : _kError,
                    fontWeight: FontWeight.w500,
                  ),
                ),
              ),
              SpendingPaceBadge(
                status: paceStatus,
                isSwahili: isSwahili,
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildStatColumn(String label, String value, Color valueColor) {
    return Expanded(
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            value,
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            style: TextStyle(
              fontSize: 16,
              fontWeight: FontWeight.bold,
              color: valueColor,
            ),
          ),
          const SizedBox(height: 2),
          Text(
            label,
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            style: const TextStyle(fontSize: 11, color: _kTertiary),
          ),
        ],
      ),
    );
  }

  // ── Rollover toggle ──────────────────────────────────────────────────────

  Widget _buildRolloverToggle(BudgetEnvelope env, bool isSwahili) {
    return Container(
      decoration: BoxDecoration(
        color: _kSurface,
        borderRadius: BorderRadius.circular(12),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.04),
            blurRadius: 3,
            offset: const Offset(0, 1),
          ),
        ],
      ),
      child: SwitchListTile(
        contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 2),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
        title: Text(
          isSwahili ? 'Hamishia mwezi ujao' : 'Roll over to next month',
          maxLines: 1,
          overflow: TextOverflow.ellipsis,
          style: const TextStyle(
            fontSize: 13,
            fontWeight: FontWeight.w500,
            color: _kPrimary,
          ),
        ),
        subtitle: Text(
          isSwahili
              ? 'Kiasi kilichobaki kitahamishiwa'
              : 'Remaining amount carries forward',
          maxLines: 1,
          overflow: TextOverflow.ellipsis,
          style: const TextStyle(fontSize: 11, color: _kTertiary),
        ),
        value: env.rollover,
        activeTrackColor: _kPrimary,
        onChanged: (value) => _toggleRollover(env, value),
      ),
    );
  }

  Future<void> _toggleRollover(BudgetEnvelope env, bool value) async {
    if (env.id == null) return;

    try {
      final storage = await LocalStorageService.getInstance();
      final token = storage.getAuthToken();
      final userId = storage.getUser()?.userId;
      if (token == null || userId == null) return;

      final updated = await BudgetService.updateEnvelope(
        token,
        userId,
        env.id!,
        {'rollover': value},
      );

      if (!mounted) return;
      if (updated != null) {
        setState(() => _envelope = updated);
      }
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(e.toString())),
      );
    }
  }

  // ── Action buttons ───────────────────────────────────────────────────────

  Widget _buildActionButtons(bool isSwahili) {
    return Row(
      children: [
        Expanded(
          child: SizedBox(
            height: 48,
            child: OutlinedButton.icon(
              onPressed: _editAllocation,
              icon: const Icon(Icons.edit_rounded, size: 18),
              label: Text(
                isSwahili ? 'Badilisha Bajeti' : 'Edit Allocation',
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: const TextStyle(fontSize: 13),
              ),
              style: OutlinedButton.styleFrom(
                foregroundColor: _kPrimary,
                side: const BorderSide(color: _kDivider),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
              ),
            ),
          ),
        ),
        const SizedBox(width: 12),
        Expanded(
          child: SizedBox(
            height: 48,
            child: OutlinedButton.icon(
              onPressed: _moveMoney,
              icon: const Icon(Icons.swap_horiz_rounded, size: 18),
              label: Text(
                isSwahili ? 'Hamisha Pesa' : 'Move Money',
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: const TextStyle(fontSize: 13),
              ),
              style: OutlinedButton.styleFrom(
                foregroundColor: _kPrimary,
                side: const BorderSide(color: _kDivider),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
              ),
            ),
          ),
        ),
      ],
    );
  }

  // ── Section header ───────────────────────────────────────────────────────

  Widget _buildSectionHeader(String title, {String? trailing}) {
    return Row(
      children: [
        Text(
          title.toUpperCase(),
          maxLines: 1,
          overflow: TextOverflow.ellipsis,
          style: const TextStyle(
            fontSize: 11,
            fontWeight: FontWeight.w600,
            color: _kTertiary,
            letterSpacing: 0.8,
          ),
        ),
        const Spacer(),
        if (trailing != null)
          Text(
            trailing,
            style: const TextStyle(fontSize: 12, color: _kTertiary),
          ),
      ],
    );
  }

  // ── Transaction tile ─────────────────────────────────────────────────────

  Widget _buildTransactionTile(ExpenditureRecord txn, bool isSwahili) {
    final dateStr = '${txn.date.day}/${txn.date.month}/${txn.date.year}';
    final source = txn.sourceModule ?? txn.category;

    // Determine if cash or wallet (check both legacy and current metadata keys)
    final isCash = txn.metadata?['payment_method'] == 'cash' || txn.metadata?['entry_type'] == 'cash';
    final badgeLabel = isCash
        ? (isSwahili ? 'Taslimu' : 'Cash')
        : (isSwahili ? 'Pochi' : 'Wallet');

    return InkWell(
      onTap: () => _recategorizeTransaction(txn),
      borderRadius: BorderRadius.circular(4),
      child: Container(
        margin: const EdgeInsets.only(bottom: 1),
        padding: const EdgeInsets.symmetric(vertical: 12, horizontal: 4),
        decoration: const BoxDecoration(
          border: Border(bottom: BorderSide(color: _kDivider, width: 0.5)),
        ),
        child: Row(
          children: [
            // Date + description
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                mainAxisSize: MainAxisSize.min,
                children: [
                  Text(
                    txn.description.isNotEmpty ? txn.description : source,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: const TextStyle(fontSize: 13, color: _kPrimary),
                  ),
                  const SizedBox(height: 2),
                  Row(
                    children: [
                      Text(
                        dateStr,
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: const TextStyle(fontSize: 11, color: _kTertiary),
                      ),
                      const SizedBox(width: 8),
                      Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 6,
                          vertical: 1,
                        ),
                        decoration: BoxDecoration(
                          color: isCash
                              ? _kWarning.withValues(alpha: 0.1)
                              : _kPrimary.withValues(alpha: 0.06),
                          borderRadius: BorderRadius.circular(4),
                        ),
                        child: Text(
                          badgeLabel,
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          style: TextStyle(
                            fontSize: 10,
                            color: isCash ? _kWarning : _kSecondary,
                            fontWeight: FontWeight.w500,
                          ),
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
            const SizedBox(width: 8),
            // Amount
            Text(
              _formatTZS(txn.amount),
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: const TextStyle(
                fontSize: 13,
                fontWeight: FontWeight.w600,
                color: _kPrimary,
              ),
            ),
          ],
        ),
      ),
    );
  }

  // ── Helpers ──────────────────────────────────────────────────────────────

  static String _formatTZS(double amount) {
    if (amount >= 1000000) {
      return 'TZS ${(amount / 1000000).toStringAsFixed(1)}M';
    }
    if (amount >= 1000) {
      return 'TZS ${(amount / 1000).toStringAsFixed(0)}K';
    }
    return 'TZS ${amount.toStringAsFixed(0)}';
  }
}
