// lib/budget/pages/budget_home_page.dart
import 'dart:async';
import 'package:flutter/material.dart';
import '../../l10n/app_strings_scope.dart';
import '../../services/expenditure_service.dart';
import '../models/budget_models.dart';
import '../services/budget_service.dart';
import '../../services/live_update_service.dart';
import '../../services/local_storage_service.dart';
import '../../my_wallet/pages/deposit_page.dart';
import 'add_transaction_page.dart';
import 'allocate_funds_page.dart';
import 'cash_flow_forecast_page.dart';
import 'envelope_detail_page.dart';
import 'goals_page.dart';
import 'income_breakdown_page.dart';
import 'monthly_report_page.dart';
import 'recurring_expenses_page.dart';
import '../widgets/envelope_list_tile.dart';
import '../widgets/safe_to_spend_card.dart';
import '../widgets/wallet_balance_card.dart';

// ── Design tokens ────────────────────────────────────────────────────────────
const Color _kPrimary = Color(0xFF1A1A1A);
const Color _kSecondary = Color(0xFF666666);
const Color _kTertiary = Color(0xFF999999);
const Color _kSurface = Color(0xFFFFFFFF);

/// Icon choices for the custom envelope picker.
const List<_IconChoice> _kIconChoices = [
  _IconChoice('restaurant', Icons.restaurant_rounded),
  _IconChoice('directions_bus', Icons.directions_bus_rounded),
  _IconChoice('home', Icons.home_rounded),
  _IconChoice('school', Icons.school_rounded),
  _IconChoice('local_hospital', Icons.local_hospital_rounded),
  _IconChoice('checkroom', Icons.checkroom_rounded),
  _IconChoice('savings', Icons.savings_rounded),
  _IconChoice('shopping_bag', Icons.shopping_bag_rounded),
  _IconChoice('phone_android', Icons.phone_android_rounded),
  _IconChoice('bolt', Icons.bolt_rounded),
  _IconChoice('water_drop', Icons.water_drop_rounded),
  _IconChoice('movie', Icons.movie_rounded),
  _IconChoice('fitness_center', Icons.fitness_center_rounded),
  _IconChoice('pets', Icons.pets_rounded),
  _IconChoice('child_care', Icons.child_care_rounded),
  _IconChoice('church', Icons.church_rounded),
  _IconChoice('volunteer_activism', Icons.volunteer_activism_rounded),
  _IconChoice('flight', Icons.flight_rounded),
  _IconChoice('category', Icons.category_rounded),
  _IconChoice('more_horiz', Icons.more_horiz_rounded),
];

/// Color swatches for the custom envelope picker.
const List<_ColorChoice> _kColorChoices = [
  _ColorChoice('1A1A1A', Color(0xFF1A1A1A)),
  _ColorChoice('E53935', Color(0xFFE53935)),
  _ColorChoice('FF9800', Color(0xFFFF9800)),
  _ColorChoice('FDD835', Color(0xFFFDD835)),
  _ColorChoice('4CAF50', Color(0xFF4CAF50)),
  _ColorChoice('2196F3', Color(0xFF2196F3)),
  _ColorChoice('7C4DFF', Color(0xFF7C4DFF)),
  _ColorChoice('EC407A', Color(0xFFEC407A)),
  _ColorChoice('00BCD4', Color(0xFF00BCD4)),
  _ColorChoice('795548', Color(0xFF795548)),
  _ColorChoice('607D8B', Color(0xFF607D8B)),
  _ColorChoice('FF5722', Color(0xFFFF5722)),
];

/// Budget home screen — rendered inside a profile tab (NO AppBar).
///
/// Shows wallet balance (with streak badge), safe-to-spend, monthly envelope
/// list grouped by status, and quick-action navigation row.
class BudgetHomePage extends StatefulWidget {
  final int userId;

  const BudgetHomePage({super.key, required this.userId});

  @override
  State<BudgetHomePage> createState() => _BudgetHomePageState();
}

class _BudgetHomePageState extends State<BudgetHomePage> {
  BudgetSnapshot? _snapshot;
  BudgetStreak _streak = BudgetStreak();
  bool _isLoading = true;
  String? _error;

  // Live update subscription
  StreamSubscription<LiveUpdateEvent>? _liveUpdateSub;

  // Last sync timestamp
  DateTime? _lastSyncTime;

  // Edit mode for reorder
  bool _isEditMode = false;

  // Show hidden envelopes toggle
  bool _showHidden = false;

  // Biashara envelope prompt
  bool _showBiasharaPrompt = false;

  // "Not Used" section collapsed state
  bool _notUsedExpanded = false;

  @override
  void initState() {
    super.initState();
    _loadData();
    _liveUpdateSub = LiveUpdateService.instance.stream.listen((event) {
      if (event is BudgetUpdateEvent) {
        _loadData(); // refresh on any budget-related event
      }
    });
  }

  @override
  void dispose() {
    _liveUpdateSub?.cancel();
    super.dispose();
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
      if (token == null) {
        if (!mounted) return;
        setState(() {
          _error = 'Auth token missing';
          _isLoading = false;
        });
        return;
      }

      var snapshot =
          await BudgetService.loadBudgetSnapshot(token, widget.userId);

      // First-open seeding: the first getUserEnvelopes call triggers backend
      // auto-seeding from defaults. If envelopes came back empty, retry once
      // so the seeded envelopes are returned on the second call.
      if (snapshot.envelopes.isEmpty) {
        final retryResult =
            await BudgetService.getUserEnvelopes(token, widget.userId);
        if (retryResult.success && retryResult.envelopes.isNotEmpty) {
          snapshot = BudgetSnapshot(
            walletBalance: snapshot.walletBalance,
            envelopes: retryResult.envelopes,
            incomeSummary: snapshot.incomeSummary,
            expenditureSummary: snapshot.expenditureSummary,
            recurringExpenses: snapshot.recurringExpenses,
            upcomingExpenses: snapshot.upcomingExpenses,
          );
        }
      }

      // Month-boundary rollover check: if loaded envelopes are from a
      // previous month, re-fetch so the backend auto-creates new-month
      // envelopes and processes rollovers.
      final now = DateTime.now();
      if (snapshot.envelopes.isNotEmpty) {
        final first = snapshot.envelopes.first;
        if (first.year != now.year || first.month != now.month) {
          final refreshed =
              await BudgetService.getUserEnvelopes(token, widget.userId);
          if (refreshed.success && refreshed.envelopes.isNotEmpty) {
            snapshot = BudgetSnapshot(
              walletBalance: snapshot.walletBalance,
              envelopes: refreshed.envelopes,
              incomeSummary: snapshot.incomeSummary,
              expenditureSummary: snapshot.expenditureSummary,
              recurringExpenses: snapshot.recurringExpenses,
              upcomingExpenses: snapshot.upcomingExpenses,
            );
          }
        }
      }

      // Biashara envelope auto-detection: check if user has business
      // income but no visible Biashara envelope, and prompt to enable it.
      bool showBiashara = false;
      final hasBiashara = snapshot.envelopes.any((e) =>
          (e.moduleTag == 'business' ||
              e.nameSw.toLowerCase() == 'biashara') &&
          e.isVisible);
      if (!hasBiashara && snapshot.incomeSummary != null) {
        final bySource = snapshot.incomeSummary!.bySource;
        final hasBusinessIncome = (bySource['shop_sale'] ?? 0) > 0 ||
            (bySource['ad_revenue'] ?? 0) > 0;
        if (hasBusinessIncome) {
          showBiashara = true;
        }
      }

      // Load streak in parallel (non-blocking)
      final streakData =
          await BudgetService.getStreak(token, widget.userId);

      if (!mounted) return;
      setState(() {
        _snapshot = snapshot;
        _streak = streakData;
        _showBiasharaPrompt = showBiashara;
        _isLoading = false;
        _lastSyncTime = DateTime.now();
      });

      // Auto check-in: determine if all envelopes are within budget
      _autoCheckIn(token, snapshot);

      // Fire-and-forget: trigger backend notification checks
      BudgetService.checkNotifications(token, widget.userId);
    } catch (e) {
      if (!mounted) return;
      setState(() {
        _error = e.toString();
        _isLoading = false;
      });
    }
  }

  /// Automatically check in for today's streak after loading envelope data.
  Future<void> _autoCheckIn(String token, BudgetSnapshot snapshot) async {
    try {
      final envelopes = snapshot.envelopes.where((e) => e.isVisible).toList();
      if (envelopes.isEmpty) return; // no envelopes yet, skip check-in

      final allWithinBudget = envelopes.every((e) => !e.isOverBudget);
      final result = await BudgetService.checkInStreak(
          token, widget.userId, allWithinBudget);

      if (!mounted || result == null) return;
      setState(() => _streak = result);
    } catch (e) {
      debugPrint('[BudgetHomePage] autoCheckIn error: $e');
    }
  }

  // ── Last sync display ───────────────────────────────────────────────────

  String _formatLastSync(bool isSwahili) {
    if (_lastSyncTime == null) return '';
    final diff = DateTime.now().difference(_lastSyncTime!);
    if (diff.inMinutes < 1) {
      return isSwahili ? 'Imesasishwa: sasa hivi' : 'Updated: just now';
    }
    if (diff.inMinutes < 60) {
      final m = diff.inMinutes;
      return isSwahili
          ? 'Imesasishwa: dakika $m zilizopita'
          : 'Last updated: $m min ago';
    }
    final h = diff.inHours;
    return isSwahili
        ? 'Imesasishwa: saa $h zilizopita'
        : 'Last updated: $h hr ago';
  }

  // ── Envelope grouping ───────────────────────────────────────────────────

  /// Sort visible envelopes into four status groups.
  _EnvelopeGroups _groupEnvelopes(List<BudgetEnvelope> visibleEnvelopes) {
    final needsAttention = <BudgetEnvelope>[];
    final onTrack = <BudgetEnvelope>[];
    final fullyPaid = <BudgetEnvelope>[];
    final notUsed = <BudgetEnvelope>[];

    for (final env in visibleEnvelopes) {
      if (env.allocatedAmount <= 0 && env.spentAmount <= 0) {
        notUsed.add(env);
      } else if (env.isOverBudget || env.percentUsed > 75) {
        needsAttention.add(env);
      } else if (env.spentAmount >= env.allocatedAmount &&
          env.allocatedAmount > 0) {
        fullyPaid.add(env);
      } else {
        onTrack.add(env);
      }
    }

    return _EnvelopeGroups(
      needsAttention: needsAttention,
      onTrack: onTrack,
      fullyPaid: fullyPaid,
      notUsed: notUsed,
    );
  }

  // ── Build ────────────────────────────────────────────────────────────────

  @override
  Widget build(BuildContext context) {
    final s = AppStringsScope.of(context);
    final isSwahili = s?.isSwahili ?? false;

    if (_isLoading) {
      return const Center(
        child: CircularProgressIndicator(strokeWidth: 2, color: _kPrimary),
      );
    }

    if (_error != null) {
      return Center(
        child: Padding(
          padding: const EdgeInsets.all(32),
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
        ),
      );
    }

    final snap = _snapshot ?? BudgetSnapshot();
    final visibleEnvelopes =
        snap.envelopes.where((e) => e.isVisible).toList();
    final hiddenEnvelopes =
        snap.envelopes.where((e) => !e.isVisible).toList();
    final groups = _groupEnvelopes(visibleEnvelopes);

    return Stack(
      children: [
        RefreshIndicator(
          onRefresh: _loadData,
          color: _kPrimary,
          child: ListView(
            padding: const EdgeInsets.all(16),
            children: [
              // 1. Wallet balance hero card (with inline streak badge)
              WalletBalanceCard(
                balance: snap.walletBalance,
                isSwahili: isSwahili,
                streakDays: _streak.currentStreak,
              ),

              // 1b. Last sync timestamp
              if (_lastSyncTime != null)
                Padding(
                  padding: const EdgeInsets.only(top: 6, bottom: 6),
                  child: Text(
                    _formatLastSync(isSwahili),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    textAlign: TextAlign.center,
                    style: const TextStyle(
                      fontSize: 11,
                      color: _kTertiary,
                    ),
                  ),
                ),
              const SizedBox(height: 6),

              // 2. Safe to spend (with allocate prompt when nothing allocated)
              SafeToSpendCard(
                amount: snap.safeToSpend,
                walletBalance: snap.walletBalance,
                isSwahili: isSwahili,
                onAllocate: snap.unallocated > 0
                    ? () => _openAllocateFunds(snap)
                    : null,
              ),
              const SizedBox(height: 12),

              // 3. Get Started card (new user with zero balance)
              if (snap.walletBalance == 0 && snap.totalAllocated == 0) ...[
                _buildGetStartedCard(isSwahili),
                const SizedBox(height: 12),
              ],

              // 4. Section header — Monthly Budget (with edit + add buttons)
              _buildEnvelopeSectionHeader(isSwahili),
              const SizedBox(height: 8),

              // 5. Envelope list — grouped by status
              if (visibleEnvelopes.isEmpty)
                _buildEmptyEnvelopes(isSwahili)
              else if (_isEditMode)
                _buildReorderableEnvelopeList(visibleEnvelopes, isSwahili)
              else ...[
                // ── Needs Attention ──
                if (groups.needsAttention.isNotEmpty) ...[
                  _buildGroupHeader(
                    isSwahili
                        ? '\u26A0 Zinahitaji Umakini'
                        : '\u26A0 Needs Attention',
                  ),
                  ...groups.needsAttention
                      .map((env) => _buildEnvelopeTile(env, isSwahili)),
                  const SizedBox(height: 8),
                ],

                // ── On Track ──
                if (groups.onTrack.isNotEmpty) ...[
                  _buildGroupHeader(
                    isSwahili ? 'Inaendelea Vizuri' : 'On Track',
                  ),
                  ...groups.onTrack.map((env) => _buildEnvelopeTile(
                        env,
                        isSwahili,
                        compact: true,
                      )),
                  const SizedBox(height: 8),
                ],

                // ── Fully Paid ──
                if (groups.fullyPaid.isNotEmpty) ...[
                  _buildGroupHeader(
                    isSwahili ? 'Imelipwa Yote' : 'Fully Paid',
                  ),
                  ...groups.fullyPaid.map((env) => Opacity(
                        opacity: 0.6,
                        child: _buildEnvelopeTile(
                          env,
                          isSwahili,
                          compact: true,
                        ),
                      )),
                  const SizedBox(height: 8),
                ],

                // ── Not Used (collapsed by default) ──
                if (groups.notUsed.isNotEmpty) ...[
                  _buildNotUsedHeader(groups.notUsed.length, isSwahili),
                  if (_notUsedExpanded)
                    ...groups.notUsed.map((env) => Opacity(
                          opacity: 0.5,
                          child: _buildEnvelopeTile(
                            env,
                            isSwahili,
                            compact: true,
                          ),
                        )),
                ],
              ],

              // 5b. Hidden envelopes (when toggle is on)
              if (_showHidden && hiddenEnvelopes.isNotEmpty) ...[
                const SizedBox(height: 12),
                Padding(
                  padding: const EdgeInsets.symmetric(vertical: 4),
                  child: Text(
                    (isSwahili ? 'Zilizofichwa' : 'Hidden').toUpperCase(),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: const TextStyle(
                      fontSize: 11,
                      fontWeight: FontWeight.w600,
                      color: _kTertiary,
                      letterSpacing: 0.8,
                    ),
                  ),
                ),
                ...hiddenEnvelopes.map((envelope) => Opacity(
                      opacity: 0.5,
                      child: Container(
                        margin: const EdgeInsets.only(bottom: 2),
                        child: Row(
                          children: [
                            Expanded(
                              child: EnvelopeListTile(
                                envelope: envelope,
                                isSwahili: isSwahili,
                                onTap: () => _openEnvelopeDetail(envelope),
                              ),
                            ),
                            IconButton(
                              icon: const Icon(Icons.visibility_rounded,
                                  size: 18, color: _kSecondary),
                              tooltip: isSwahili ? 'Onyesha' : 'Unhide',
                              onPressed: () =>
                                  _unhideEnvelope(envelope, isSwahili),
                            ),
                          ],
                        ),
                      ),
                    )),
              ],

              // 5c. Biashara envelope suggestion
              if (_showBiasharaPrompt) ...[
                const SizedBox(height: 12),
                _buildBiasharaPromptCard(isSwahili),
              ],

              const SizedBox(height: 24),

              // 6. Quick actions row
              _buildQuickActions(isSwahili),
              const SizedBox(height: 80), // room for FAB
            ],
          ),
        ),
        // FAB for adding a manual cash transaction
        Positioned(
          right: 16,
          bottom: 16,
          child: FloatingActionButton(
            heroTag: 'budget_add_txn',
            onPressed: () => _openAddTransaction(),
            backgroundColor: _kPrimary,
            tooltip: isSwahili ? 'Ongeza muamala' : 'Add transaction',
            child: const Icon(Icons.add_rounded, color: Colors.white),
          ),
        ),
      ],
    );
  }

  // ── Group section header ────────────────────────────────────────────────

  Widget _buildGroupHeader(String label) {
    return Padding(
      padding: const EdgeInsets.only(top: 4, bottom: 4),
      child: Text(
        label.toUpperCase(),
        maxLines: 1,
        overflow: TextOverflow.ellipsis,
        style: const TextStyle(
          fontSize: 11,
          fontWeight: FontWeight.w600,
          color: _kTertiary,
          letterSpacing: 0.8,
        ),
      ),
    );
  }

  // ── Not Used collapsible header ─────────────────────────────────────────

  Widget _buildNotUsedHeader(int count, bool isSwahili) {
    final label = isSwahili
        ? 'Hazijatumika ($count)'
        : 'Not Used ($count)';
    return InkWell(
      onTap: () => setState(() => _notUsedExpanded = !_notUsedExpanded),
      borderRadius: BorderRadius.circular(8),
      child: Padding(
        padding: const EdgeInsets.symmetric(vertical: 8, horizontal: 4),
        child: Row(
          children: [
            Expanded(
              child: Text(
                label.toUpperCase(),
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: const TextStyle(
                  fontSize: 11,
                  fontWeight: FontWeight.w600,
                  color: _kTertiary,
                  letterSpacing: 0.8,
                ),
              ),
            ),
            Icon(
              _notUsedExpanded
                  ? Icons.expand_less_rounded
                  : Icons.expand_more_rounded,
              size: 18,
              color: _kTertiary,
            ),
          ],
        ),
      ),
    );
  }

  // ── Envelope section header with edit + add ──────────────────────────────

  Widget _buildEnvelopeSectionHeader(bool isSwahili) {
    final title = isSwahili ? 'Bajeti ya Mwezi' : 'Monthly Budget';
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4),
      child: Row(
        children: [
          Expanded(
            child: Text(
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
          ),
          // Edit/done toggle
          SizedBox(
            width: 48,
            height: 48,
            child: IconButton(
              icon: Icon(
                _isEditMode
                    ? Icons.check_rounded
                    : Icons.swap_vert_rounded,
                size: 18,
                color: _kSecondary,
              ),
              tooltip: _isEditMode
                  ? (isSwahili ? 'Maliza' : 'Done')
                  : (isSwahili ? 'Panga upya' : 'Reorder'),
              onPressed: () {
                setState(() => _isEditMode = !_isEditMode);
              },
            ),
          ),
          // Show/hide hidden envelopes toggle
          SizedBox(
            width: 48,
            height: 48,
            child: IconButton(
              icon: Icon(
                _showHidden
                    ? Icons.visibility_rounded
                    : Icons.visibility_off_rounded,
                size: 18,
                color: _showHidden ? _kPrimary : _kSecondary,
              ),
              tooltip: _showHidden
                  ? (isSwahili ? 'Ficha zilizofichwa' : 'Hide hidden')
                  : (isSwahili ? 'Onyesha zilizofichwa' : 'Show hidden'),
              onPressed: () {
                setState(() => _showHidden = !_showHidden);
              },
            ),
          ),
          // Add envelope
          SizedBox(
            width: 48,
            height: 48,
            child: IconButton(
              icon: const Icon(Icons.add_rounded, size: 18, color: _kSecondary),
              tooltip: isSwahili ? 'Ongeza bahasha' : 'Add envelope',
              onPressed: () => _showAddEnvelopeSheet(isSwahili),
            ),
          ),
        ],
      ),
    );
  }

  // ── Envelope tile with long-press ────────────────────────────────────────

  Widget _buildEnvelopeTile(
    BudgetEnvelope envelope,
    bool isSwahili, {
    bool compact = false,
  }) {
    return Dismissible(
      key: ValueKey('swipe_${envelope.id ?? envelope.nameEn}'),
      direction: DismissDirection.startToEnd,
      confirmDismiss: (_) async {
        _showQuickAddExpenseDialog(envelope, isSwahili);
        return false; // never actually dismiss
      },
      background: Container(
        alignment: Alignment.centerLeft,
        padding: const EdgeInsets.only(left: 20),
        decoration: BoxDecoration(
          color: const Color(0xFF4CAF50).withValues(alpha: 0.12),
          borderRadius: BorderRadius.circular(12),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Icon(Icons.add_circle_rounded,
                color: Color(0xFF4CAF50), size: 24),
            const SizedBox(width: 8),
            Text(
              isSwahili ? 'Ongeza' : 'Add',
              style: const TextStyle(
                color: Color(0xFF4CAF50),
                fontWeight: FontWeight.w600,
                fontSize: 14,
              ),
            ),
          ],
        ),
      ),
      child: GestureDetector(
        onLongPress: () => _showEnvelopeContextMenu(envelope, isSwahili),
        child: EnvelopeListTile(
          envelope: envelope,
          isSwahili: isSwahili,
          compact: compact,
          onTap: () => _openEnvelopeDetail(envelope),
        ),
      ),
    );
  }

  // ── Quick-add expense dialog (swipe-to-add) ──────────────────────────────

  void _showQuickAddExpenseDialog(BudgetEnvelope envelope, bool isSwahili) {
    final amountController = TextEditingController();
    final descController = TextEditingController();
    bool isSaving = false;

    showDialog(
      context: context,
      builder: (ctx) {
        return StatefulBuilder(
          builder: (ctx, setDialogState) {
            return AlertDialog(
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(16),
              ),
              title: Text(
                envelope.displayName(isSwahili),
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: const TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.w600,
                  color: _kPrimary,
                ),
              ),
              content: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  TextField(
                    controller: amountController,
                    keyboardType:
                        const TextInputType.numberWithOptions(decimal: true),
                    decoration: InputDecoration(
                      labelText: isSwahili ? 'Kiasi (TZS)' : 'Amount (TZS)',
                      border: const OutlineInputBorder(),
                      prefixText: 'TZS ',
                    ),
                    autofocus: true,
                  ),
                  const SizedBox(height: 12),
                  TextField(
                    controller: descController,
                    decoration: InputDecoration(
                      labelText: isSwahili ? 'Maelezo' : 'Description',
                      border: const OutlineInputBorder(),
                    ),
                    textCapitalization: TextCapitalization.sentences,
                    maxLength: 100,
                  ),
                ],
              ),
              actions: [
                TextButton(
                  onPressed: isSaving ? null : () => Navigator.pop(ctx),
                  child: Text(
                    isSwahili ? 'Ghairi' : 'Cancel',
                    style: const TextStyle(color: _kSecondary),
                  ),
                ),
                ElevatedButton(
                  onPressed: isSaving
                      ? null
                      : () async {
                          final amountText = amountController.text.trim();
                          final amount = double.tryParse(amountText);
                          if (amount == null || amount <= 0) return;

                          final desc = descController.text.trim().isNotEmpty
                              ? descController.text.trim()
                              : envelope.displayName(isSwahili);

                          setDialogState(() => isSaving = true);
                          final messenger =
                              ScaffoldMessenger.of(context);

                          try {
                            final storage =
                                await LocalStorageService.getInstance();
                            final token = storage.getAuthToken();
                            if (token == null) return;

                            final result =
                                await ExpenditureService.recordExpenditure(
                              token: token,
                              amount: amount,
                              category: envelope.moduleTag ??
                                  envelope.nameEn.toLowerCase(),
                              description: desc,
                              sourceModule: 'manual',
                              referenceId:
                                  'manual_${DateTime.now().millisecondsSinceEpoch}',
                              envelopeTag: envelope.moduleTag,
                              metadata: {'entry_type': 'cash'},
                            );

                            if (!ctx.mounted) return;
                            Navigator.pop(ctx);

                            if (result != null) {
                              messenger.showSnackBar(
                                SnackBar(
                                  content: Text(
                                    isSwahili
                                        ? 'Matumizi yameongezwa'
                                        : 'Expense added',
                                  ),
                                ),
                              );
                              _loadData();
                            } else {
                              messenger.showSnackBar(
                                SnackBar(
                                  content: Text(
                                    isSwahili
                                        ? 'Imeshindikana kuhifadhi'
                                        : 'Failed to save expense',
                                  ),
                                ),
                              );
                            }
                          } catch (e) {
                            if (!ctx.mounted) return;
                            Navigator.pop(ctx);
                            messenger.showSnackBar(
                              SnackBar(
                                content: Text(
                                  isSwahili
                                      ? 'Imeshindikana kuhifadhi'
                                      : 'Failed to save expense',
                                ),
                              ),
                            );
                          }
                        },
                  style: ElevatedButton.styleFrom(
                    backgroundColor: _kPrimary,
                    foregroundColor: Colors.white,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(8),
                    ),
                  ),
                  child: isSaving
                      ? const SizedBox(
                          width: 18,
                          height: 18,
                          child: CircularProgressIndicator(
                            strokeWidth: 2,
                            color: Colors.white,
                          ),
                        )
                      : Text(isSwahili ? 'Hifadhi' : 'Save'),
                ),
              ],
            );
          },
        );
      },
    );
  }

  // ── Reorderable envelope list (edit mode) ────────────────────────────────

  Widget _buildReorderableEnvelopeList(
      List<BudgetEnvelope> envelopes, bool isSwahili) {
    return ReorderableListView.builder(
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      itemCount: envelopes.length,
      onReorder: (oldIndex, newIndex) =>
          _onReorderEnvelopes(envelopes, oldIndex, newIndex),
      itemBuilder: (context, index) {
        final envelope = envelopes[index];
        return ListTile(
          key: ValueKey(envelope.id ?? index),
          contentPadding: const EdgeInsets.symmetric(horizontal: 4),
          leading: const Icon(Icons.drag_handle_rounded,
              color: _kTertiary, size: 20),
          title: Text(
            envelope.displayName(isSwahili),
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            style: const TextStyle(
              fontSize: 14,
              fontWeight: FontWeight.w500,
              color: _kPrimary,
            ),
          ),
          trailing: IconButton(
            icon: const Icon(Icons.visibility_off_rounded,
                size: 18, color: _kTertiary),
            tooltip: isSwahili ? 'Ficha' : 'Hide',
            onPressed: () => _hideEnvelope(envelope, isSwahili),
          ),
        );
      },
    );
  }

  // ── Reorder callback ────────────────────────────────────────────────────

  Future<void> _onReorderEnvelopes(
      List<BudgetEnvelope> envelopes, int oldIndex, int newIndex) async {
    if (oldIndex < newIndex) newIndex -= 1;
    final moved = envelopes.removeAt(oldIndex);
    envelopes.insert(newIndex, moved);

    // Optimistic UI update
    setState(() {});

    try {
      final storage = await LocalStorageService.getInstance();
      final token = storage.getAuthToken();
      if (token == null) return;

      // Update sort_order for all affected envelopes
      for (var i = 0; i < envelopes.length; i++) {
        final env = envelopes[i];
        if (env.id != null && env.sortOrder != i) {
          await BudgetService.updateEnvelope(
              token, widget.userId, env.id!, {'sort_order': i});
        }
      }

      _loadData();
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(
        content: Text(
          AppStringsScope.of(context)?.isSwahili == true
              ? 'Imeshindikana kupanga upya'
              : 'Failed to reorder',
        ),
      ));
      _loadData(); // revert to server state
    }
  }

  // ── Long-press context menu ──────────────────────────────────────────────

  void _showEnvelopeContextMenu(BudgetEnvelope envelope, bool isSwahili) {
    showModalBottomSheet(
      context: context,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(16)),
      ),
      builder: (ctx) {
        return SafeArea(
          child: Padding(
            padding: const EdgeInsets.symmetric(vertical: 8),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                // Sheet handle
                Container(
                  width: 36,
                  height: 4,
                  margin: const EdgeInsets.only(bottom: 12),
                  decoration: BoxDecoration(
                    color: _kTertiary.withValues(alpha: 0.4),
                    borderRadius: BorderRadius.circular(2),
                  ),
                ),
                // Envelope name header
                Padding(
                  padding:
                      const EdgeInsets.symmetric(horizontal: 20, vertical: 8),
                  child: Text(
                    envelope.displayName(isSwahili),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: const TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.w600,
                      color: _kPrimary,
                    ),
                  ),
                ),
                const Divider(height: 1),
                // Hide
                ListTile(
                  leading: const Icon(Icons.visibility_off_rounded, size: 22),
                  title: Text(
                    isSwahili ? 'Ficha' : 'Hide',
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                  onTap: () {
                    Navigator.pop(ctx);
                    _hideEnvelope(envelope, isSwahili);
                  },
                ),
                // Edit Allocation
                ListTile(
                  leading: const Icon(Icons.edit_rounded, size: 22),
                  title: Text(
                    isSwahili ? 'Badilisha Kiasi' : 'Edit Allocation',
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                  onTap: () {
                    Navigator.pop(ctx);
                    _openEnvelopeDetail(envelope);
                  },
                ),
                // Move Up
                ListTile(
                  leading: const Icon(Icons.arrow_upward_rounded, size: 22),
                  title: Text(
                    isSwahili ? 'Sogeza Juu' : 'Move Up',
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                  onTap: () {
                    Navigator.pop(ctx);
                    _moveEnvelope(envelope, -1);
                  },
                ),
                // Move Down
                ListTile(
                  leading: const Icon(Icons.arrow_downward_rounded, size: 22),
                  title: Text(
                    isSwahili ? 'Sogeza Chini' : 'Move Down',
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                  onTap: () {
                    Navigator.pop(ctx);
                    _moveEnvelope(envelope, 1);
                  },
                ),
              ],
            ),
          ),
        );
      },
    );
  }

  // ── Hide envelope ────────────────────────────────────────────────────────

  Future<void> _hideEnvelope(BudgetEnvelope envelope, bool isSwahili) async {
    if (envelope.id == null) return;

    final messenger = ScaffoldMessenger.of(context);
    try {
      final storage = await LocalStorageService.getInstance();
      final token = storage.getAuthToken();
      if (token == null) return;

      await BudgetService.updateEnvelope(
          token, widget.userId, envelope.id!, {'is_visible': false});

      if (!mounted) return;
      messenger.showSnackBar(SnackBar(
        content: Text(
          isSwahili
              ? '${envelope.displayName(true)} imefichwa'
              : '${envelope.displayName(false)} hidden',
        ),
      ));
      _loadData();
    } catch (e) {
      if (!mounted) return;
      messenger.showSnackBar(SnackBar(
        content: Text(
          isSwahili ? 'Imeshindikana kuficha' : 'Failed to hide envelope',
        ),
      ));
    }
  }

  // ── Unhide envelope ──────────────────────────────────────────────────

  Future<void> _unhideEnvelope(BudgetEnvelope envelope, bool isSwahili) async {
    if (envelope.id == null) return;

    final messenger = ScaffoldMessenger.of(context);
    try {
      final storage = await LocalStorageService.getInstance();
      final token = storage.getAuthToken();
      if (token == null) return;

      await BudgetService.updateEnvelope(
          token, widget.userId, envelope.id!, {'is_visible': true});

      if (!mounted) return;
      messenger.showSnackBar(SnackBar(
        content: Text(
          isSwahili
              ? '${envelope.displayName(true)} imeonyeshwa'
              : '${envelope.displayName(false)} restored',
        ),
      ));
      _loadData();
    } catch (e) {
      if (!mounted) return;
      messenger.showSnackBar(SnackBar(
        content: Text(
          isSwahili ? 'Imeshindikana kuonyesha' : 'Failed to unhide envelope',
        ),
      ));
    }
  }

  // ── Move envelope up/down ─────────────────────────────────────────────

  Future<void> _moveEnvelope(BudgetEnvelope envelope, int direction) async {
    if (envelope.id == null || _snapshot == null) return;

    final visible =
        _snapshot!.envelopes.where((e) => e.isVisible).toList();
    final idx = visible.indexWhere((e) => e.id == envelope.id);
    final targetIdx = idx + direction;
    if (idx < 0 || targetIdx < 0 || targetIdx >= visible.length) return;

    try {
      final storage = await LocalStorageService.getInstance();
      final token = storage.getAuthToken();
      if (token == null) return;

      final other = visible[targetIdx];
      // Swap sort_order values
      await Future.wait([
        if (envelope.id != null)
          BudgetService.updateEnvelope(
              token, widget.userId, envelope.id!, {'sort_order': other.sortOrder}),
        if (other.id != null)
          BudgetService.updateEnvelope(
              token, widget.userId, other.id!, {'sort_order': envelope.sortOrder}),
      ]);

      _loadData();
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(
        content: Text(
          AppStringsScope.of(context)?.isSwahili == true
              ? 'Imeshindikana kusogeza'
              : 'Failed to move envelope',
        ),
      ));
    }
  }

  // ── Add custom envelope bottom sheet ─────────────────────────────────────

  void _showAddEnvelopeSheet(bool isSwahili) {
    final nameEnController = TextEditingController();
    final nameSwController = TextEditingController();
    String selectedIcon = 'category';
    String selectedColor = '1A1A1A';

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(16)),
      ),
      builder: (ctx) {
        return StatefulBuilder(
          builder: (ctx, setSheetState) {
            return SafeArea(
              child: Padding(
                padding: EdgeInsets.only(
                  left: 20,
                  right: 20,
                  top: 16,
                  bottom: MediaQuery.of(ctx).viewInsets.bottom + 16,
                ),
                child: SingleChildScrollView(
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    children: [
                      // Handle
                      Center(
                        child: Container(
                          width: 36,
                          height: 4,
                          margin: const EdgeInsets.only(bottom: 16),
                          decoration: BoxDecoration(
                            color: _kTertiary.withValues(alpha: 0.4),
                            borderRadius: BorderRadius.circular(2),
                          ),
                        ),
                      ),
                      Text(
                        isSwahili ? 'Ongeza Bahasha' : 'Add Envelope',
                        style: const TextStyle(
                          fontSize: 18,
                          fontWeight: FontWeight.w600,
                          color: _kPrimary,
                        ),
                      ),
                      const SizedBox(height: 16),

                      // Name (English)
                      TextField(
                        controller: nameEnController,
                        decoration: InputDecoration(
                          labelText: isSwahili ? 'Jina (Kiingereza)' : 'Name (English)',
                          border: const OutlineInputBorder(),
                        ),
                        textCapitalization: TextCapitalization.words,
                        maxLength: 40,
                      ),
                      const SizedBox(height: 8),

                      // Name (Swahili)
                      TextField(
                        controller: nameSwController,
                        decoration: InputDecoration(
                          labelText: isSwahili ? 'Jina (Kiswahili)' : 'Name (Swahili)',
                          border: const OutlineInputBorder(),
                        ),
                        textCapitalization: TextCapitalization.words,
                        maxLength: 40,
                      ),
                      const SizedBox(height: 16),

                      // Icon picker
                      Text(
                        isSwahili ? 'Ikoni' : 'Icon',
                        style: const TextStyle(
                          fontSize: 13,
                          fontWeight: FontWeight.w500,
                          color: _kSecondary,
                        ),
                      ),
                      const SizedBox(height: 8),
                      Wrap(
                        spacing: 8,
                        runSpacing: 8,
                        children: _kIconChoices.map((ic) {
                          final isSelected = ic.name == selectedIcon;
                          return GestureDetector(
                            onTap: () =>
                                setSheetState(() => selectedIcon = ic.name),
                            child: Container(
                              width: 44,
                              height: 44,
                              decoration: BoxDecoration(
                                color: isSelected
                                    ? _kPrimary.withValues(alpha: 0.12)
                                    : _kPrimary.withValues(alpha: 0.04),
                                borderRadius: BorderRadius.circular(10),
                                border: isSelected
                                    ? Border.all(color: _kPrimary, width: 2)
                                    : null,
                              ),
                              child: Icon(ic.icon, size: 20, color: _kPrimary),
                            ),
                          );
                        }).toList(),
                      ),
                      const SizedBox(height: 16),

                      // Color picker
                      Text(
                        isSwahili ? 'Rangi' : 'Color',
                        style: const TextStyle(
                          fontSize: 13,
                          fontWeight: FontWeight.w500,
                          color: _kSecondary,
                        ),
                      ),
                      const SizedBox(height: 8),
                      Wrap(
                        spacing: 8,
                        runSpacing: 8,
                        children: _kColorChoices.map((cc) {
                          final isSelected = cc.hex == selectedColor;
                          return GestureDetector(
                            onTap: () =>
                                setSheetState(() => selectedColor = cc.hex),
                            child: Container(
                              width: 36,
                              height: 36,
                              decoration: BoxDecoration(
                                color: cc.color,
                                shape: BoxShape.circle,
                                border: isSelected
                                    ? Border.all(
                                        color: Colors.white, width: 3)
                                    : null,
                                boxShadow: isSelected
                                    ? [
                                        BoxShadow(
                                          color: cc.color.withValues(alpha: 0.5),
                                          blurRadius: 8,
                                        )
                                      ]
                                    : null,
                              ),
                              child: isSelected
                                  ? const Icon(Icons.check_rounded,
                                      size: 16, color: Colors.white)
                                  : null,
                            ),
                          );
                        }).toList(),
                      ),
                      const SizedBox(height: 24),

                      // Save button
                      SizedBox(
                        height: 48,
                        child: ElevatedButton(
                          onPressed: () => _createEnvelope(
                            ctx,
                            nameEnController.text.trim(),
                            nameSwController.text.trim(),
                            selectedIcon,
                            selectedColor,
                            isSwahili,
                          ),
                          style: ElevatedButton.styleFrom(
                            backgroundColor: _kPrimary,
                            foregroundColor: Colors.white,
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(12),
                            ),
                          ),
                          child: Text(
                            isSwahili ? 'Hifadhi' : 'Save',
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            );
          },
        );
      },
    );
  }

  // ── Create envelope API call ──────────────────────────────────────────

  Future<void> _createEnvelope(
    BuildContext sheetContext,
    String nameEn,
    String nameSw,
    String icon,
    String color,
    bool isSwahili,
  ) async {
    if (nameEn.isEmpty && nameSw.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(
        content: Text(
          isSwahili
              ? 'Tafadhali ingiza jina angalau moja'
              : 'Please enter at least one name',
        ),
      ));
      return;
    }

    // Use one name as fallback for the other
    final finalNameEn = nameEn.isNotEmpty ? nameEn : nameSw;
    final finalNameSw = nameSw.isNotEmpty ? nameSw : nameEn;

    Navigator.pop(sheetContext);

    final messenger = ScaffoldMessenger.of(context);
    try {
      final storage = await LocalStorageService.getInstance();
      final token = storage.getAuthToken();
      if (token == null) return;

      final result = await BudgetService.createEnvelope(
        token,
        widget.userId,
        {
          'name_en': finalNameEn,
          'name_sw': finalNameSw,
          'icon': icon,
          'color': color,
        },
      );

      if (!mounted) return;
      if (result != null) {
        messenger.showSnackBar(SnackBar(
          content: Text(
            isSwahili
                ? 'Bahasha "$finalNameSw" imeundwa'
                : 'Envelope "$finalNameEn" created',
          ),
        ));
        _loadData();
      } else {
        messenger.showSnackBar(SnackBar(
          content: Text(
            isSwahili
                ? 'Imeshindikana kuunda bahasha'
                : 'Failed to create envelope',
          ),
        ));
      }
    } catch (e) {
      if (!mounted) return;
      messenger.showSnackBar(SnackBar(
        content: Text(
          isSwahili
              ? 'Imeshindikana kuunda bahasha'
              : 'Failed to create envelope',
        ),
      ));
    }
  }

  // ── Get Started card (new user with zero balance) ───────────────────────

  Widget _buildGetStartedCard(bool isSwahili) {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: _kSurface,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: const Color(0xFFE0E0E0)),
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          const Icon(Icons.account_balance_wallet_rounded,
              size: 36, color: _kTertiary),
          const SizedBox(height: 12),
          Text(
            isSwahili ? 'Anza Hapa' : 'Get Started',
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            style: const TextStyle(
              fontSize: 16,
              fontWeight: FontWeight.w600,
              color: _kPrimary,
            ),
          ),
          const SizedBox(height: 4),
          Text(
            isSwahili
                ? 'Jaza mkoba wako kuanza kupanga bajeti'
                : 'Top up your wallet to start budgeting',
            maxLines: 2,
            overflow: TextOverflow.ellipsis,
            textAlign: TextAlign.center,
            style: const TextStyle(fontSize: 13, color: _kSecondary),
          ),
          const SizedBox(height: 16),
          SizedBox(
            height: 48,
            child: FilledButton.icon(
              onPressed: () {
                Navigator.push(
                  context,
                  MaterialPageRoute(builder: (_) => DepositPage(userId: widget.userId)),
                ).then((_) => _loadData());
              },
              icon: const Icon(Icons.add_rounded, size: 18),
              label: Text(
                isSwahili ? 'Jaza Pesa' : 'Top Up',
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
              ),
              style: FilledButton.styleFrom(
                backgroundColor: _kPrimary,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  // ── Empty envelopes placeholder ──────────────────────────────────────────

  Widget _buildEmptyEnvelopes(bool isSwahili) {
    return Container(
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        color: _kSurface,
        borderRadius: BorderRadius.circular(12),
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          const Icon(Icons.inbox_rounded, size: 36, color: _kTertiary),
          const SizedBox(height: 8),
          Text(
            isSwahili ? 'Bado hakuna bahasha' : 'No envelopes yet',
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            style: const TextStyle(color: _kSecondary, fontSize: 13),
          ),
        ],
      ),
    );
  }

  // ── Quick action row ─────────────────────────────────────────────────────

  Widget _buildQuickActions(bool isSwahili) {
    final actions = <_QuickAction>[
      _QuickAction(
        icon: Icons.arrow_downward_rounded,
        labelEn: 'Income',
        labelSw: 'Mapato',
        onTap: () => Navigator.push(
          context,
          MaterialPageRoute(
            builder: (_) => IncomeBreakdownPage(userId: widget.userId),
          ),
        ).then((_) => _loadData()),
      ),
      _QuickAction(
        icon: Icons.flag_rounded,
        labelEn: 'Goals',
        labelSw: 'Malengo',
        onTap: () => Navigator.push(
          context,
          MaterialPageRoute(
            builder: (_) => GoalsPage(userId: widget.userId),
          ),
        ).then((_) => _loadData()),
      ),
      _QuickAction(
        icon: Icons.bar_chart_rounded,
        labelEn: 'Report',
        labelSw: 'Ripoti',
        onTap: () => Navigator.push(
          context,
          MaterialPageRoute(
            builder: (_) => MonthlyReportPage(userId: widget.userId),
          ),
        ),
      ),
      _QuickAction(
        icon: Icons.trending_up_rounded,
        labelEn: 'Forecast',
        labelSw: 'Utabiri',
        onTap: () => Navigator.push(
          context,
          MaterialPageRoute(
            builder: (_) => CashFlowForecastPage(userId: widget.userId),
          ),
        ),
      ),
      _QuickAction(
        icon: Icons.repeat_rounded,
        labelEn: 'Recurring',
        labelSw: 'Mara kwa Mara',
        onTap: () => Navigator.push(
          context,
          MaterialPageRoute(
            builder: (_) => RecurringExpensesPage(userId: widget.userId),
          ),
        ),
      ),
    ];

    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceAround,
      children: actions.map((a) {
        final label = isSwahili ? a.labelSw : a.labelEn;
        return Expanded(
          child: InkWell(
            onTap: a.onTap,
            borderRadius: BorderRadius.circular(12),
            child: Padding(
              padding: const EdgeInsets.symmetric(vertical: 8),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Container(
                    width: 48,
                    height: 48,
                    decoration: BoxDecoration(
                      color: _kPrimary.withValues(alpha: 0.06),
                      shape: BoxShape.circle,
                    ),
                    child: Icon(a.icon, size: 22, color: _kPrimary),
                  ),
                  const SizedBox(height: 6),
                  Text(
                    label,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    textAlign: TextAlign.center,
                    style: const TextStyle(
                      fontSize: 11,
                      color: _kSecondary,
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                ],
              ),
            ),
          ),
        );
      }).toList(),
    );
  }

  // ── Biashara prompt card ──────────────────────────────────────────────────

  Widget _buildBiasharaPromptCard(bool isSwahili) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: _kSurface,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: const Color(0xFFE0E0E0)),
      ),
      child: Row(
        children: [
          Container(
            width: 40,
            height: 40,
            decoration: BoxDecoration(
              color: _kPrimary.withValues(alpha: 0.06),
              shape: BoxShape.circle,
            ),
            child: const Icon(Icons.storefront_rounded,
                size: 20, color: _kPrimary),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisSize: MainAxisSize.min,
              children: [
                Text(
                  isSwahili
                      ? 'Una mapato ya biashara'
                      : 'You have business income',
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: const TextStyle(
                    fontSize: 13,
                    fontWeight: FontWeight.w600,
                    color: _kPrimary,
                  ),
                ),
                const SizedBox(height: 2),
                Text(
                  isSwahili
                      ? 'Weka bahasha ya Biashara?'
                      : 'Enable Biashara envelope?',
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: const TextStyle(fontSize: 12, color: _kSecondary),
                ),
              ],
            ),
          ),
          const SizedBox(width: 8),
          SizedBox(
            height: 36,
            child: FilledButton(
              onPressed: () => _enableBiasharaEnvelope(isSwahili),
              style: FilledButton.styleFrom(
                backgroundColor: _kPrimary,
                padding: const EdgeInsets.symmetric(horizontal: 16),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(8),
                ),
              ),
              child: Text(
                isSwahili ? 'Weka' : 'Enable',
                style: const TextStyle(fontSize: 12),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Future<void> _enableBiasharaEnvelope(bool isSwahili) async {
    final messenger = ScaffoldMessenger.of(context);
    try {
      final storage = await LocalStorageService.getInstance();
      final token = storage.getAuthToken();
      if (token == null) return;

      final snap = _snapshot;
      if (snap == null) return;

      // Check if a hidden Biashara envelope exists — unhide it
      final hiddenBiashara = snap.envelopes.where((e) =>
          (e.moduleTag == 'business' ||
              e.nameSw.toLowerCase() == 'biashara') &&
          !e.isVisible);

      if (hiddenBiashara.isNotEmpty && hiddenBiashara.first.id != null) {
        await BudgetService.updateEnvelope(
          token,
          widget.userId,
          hiddenBiashara.first.id!,
          {'is_visible': true},
        );
      } else {
        // Create a new Biashara envelope
        await BudgetService.createEnvelope(token, widget.userId, {
          'name_en': 'Business',
          'name_sw': 'Biashara',
          'icon': 'storefront',
          'color': '795548',
          'module_tag': 'business',
          'allocated_amount': 0,
          'is_visible': true,
        });
      }

      if (!mounted) return;
      setState(() => _showBiasharaPrompt = false);
      messenger.showSnackBar(SnackBar(
        content: Text(
          isSwahili
              ? 'Bahasha ya Biashara imewezeshwa'
              : 'Biashara envelope enabled',
        ),
      ));
      _loadData();
    } catch (e) {
      if (!mounted) return;
      messenger.showSnackBar(SnackBar(
        content: Text(
          isSwahili
              ? 'Imeshindikana kuweka bahasha'
              : 'Failed to enable envelope',
        ),
      ));
    }
  }

  // ── Navigation ───────────────────────────────────────────────────────────

  void _openEnvelopeDetail(BudgetEnvelope envelope) {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (_) => EnvelopeDetailPage(envelope: envelope),
      ),
    ).then((_) => _loadData());
  }

  void _openAddTransaction() {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (_) => const AddTransactionPage(),
      ),
    ).then((_) => _loadData());
  }

  void _openAllocateFunds(BudgetSnapshot snap) {
    final visibleEnvelopes =
        snap.envelopes.where((e) => e.isVisible).toList();
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (_) => AllocateFundsPage(
          unallocatedAmount: snap.unallocated,
          envelopes: visibleEnvelopes,
        ),
      ),
    ).then((result) {
      if (result == true) _loadData();
    });
  }
}

// ── Envelope groups data holder ─────────────────────────────────────────────

class _EnvelopeGroups {
  final List<BudgetEnvelope> needsAttention;
  final List<BudgetEnvelope> onTrack;
  final List<BudgetEnvelope> fullyPaid;
  final List<BudgetEnvelope> notUsed;

  const _EnvelopeGroups({
    required this.needsAttention,
    required this.onTrack,
    required this.fullyPaid,
    required this.notUsed,
  });
}

// ── Quick action data holder ─────────────────────────────────────────────────

class _QuickAction {
  final IconData icon;
  final String labelEn;
  final String labelSw;
  final VoidCallback? onTap;

  const _QuickAction({
    required this.icon,
    required this.labelEn,
    required this.labelSw,
    this.onTap,
  });
}

// ── Icon choice data holder ──────────────────────────────────────────────────

class _IconChoice {
  final String name;
  final IconData icon;

  const _IconChoice(this.name, this.icon);
}

// ── Color choice data holder ─────────────────────────────────────────────────

class _ColorChoice {
  final String hex;
  final Color color;

  const _ColorChoice(this.hex, this.color);
}
