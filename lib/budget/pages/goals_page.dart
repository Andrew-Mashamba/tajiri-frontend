// lib/budget/pages/goals_page.dart
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import '../../l10n/app_strings_scope.dart';
import '../models/budget_models.dart';
import '../services/budget_service.dart';
import '../../services/expenditure_service.dart';
import '../../services/local_storage_service.dart';
import '../widgets/goal_card.dart';

// ── Design tokens ────────────────────────────────────────────────────────────
const Color _kPrimary = Color(0xFF1A1A1A);
const Color _kSecondary = Color(0xFF666666);
const Color _kTertiary = Color(0xFF999999);
const Color _kSurface = Color(0xFFFFFFFF);
const Color _kBackground = Color(0xFFFAFAFA);
const Color _kDivider = Color(0xFFE0E0E0);
const Color _kError = Color(0xFFE53935);

/// Common icons for goal icon picker
const List<_GoalIconOption> _kGoalIcons = [
  _GoalIconOption(Icons.flag_rounded, 'flag'),
  _GoalIconOption(Icons.home_rounded, 'home'),
  _GoalIconOption(Icons.directions_car_rounded, 'car'),
  _GoalIconOption(Icons.school_rounded, 'school'),
  _GoalIconOption(Icons.flight_rounded, 'travel'),
  _GoalIconOption(Icons.phone_iphone_rounded, 'phone'),
  _GoalIconOption(Icons.laptop_rounded, 'laptop'),
  _GoalIconOption(Icons.medical_services_rounded, 'health'),
  _GoalIconOption(Icons.celebration_rounded, 'celebration'),
  _GoalIconOption(Icons.savings_rounded, 'savings'),
  _GoalIconOption(Icons.business_rounded, 'business'),
  _GoalIconOption(Icons.child_care_rounded, 'child'),
  _GoalIconOption(Icons.restaurant_rounded, 'food'),
  _GoalIconOption(Icons.shopping_bag_rounded, 'shopping'),
  _GoalIconOption(Icons.fitness_center_rounded, 'fitness'),
  _GoalIconOption(Icons.diamond_rounded, 'diamond'),
];

class GoalsPage extends StatefulWidget {
  final int userId;

  const GoalsPage({super.key, required this.userId});

  @override
  State<GoalsPage> createState() => _GoalsPageState();
}

class _GoalsPageState extends State<GoalsPage> {
  // ── State ──────────────────────────────────────────────────────────────────
  List<BudgetGoal> _goals = [];
  bool _isLoading = true;
  String? _error;

  @override
  void initState() {
    super.initState();
    _loadGoals();
  }

  // ── Data loading ───────────────────────────────────────────────────────────

  Future<void> _loadGoals() async {
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

      final result = await BudgetService.getGoals(token, widget.userId);
      if (!mounted) return;

      setState(() {
        _goals = result.success ? result.goals : [];
        _error = result.success ? null : result.message;
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

  // ── Add goal ───────────────────────────────────────────────────────────────

  Future<void> _addGoal() async {
    final strings = AppStringsScope.of(context);
    final isSwahili = strings?.isSwahili ?? false;

    final result = await _showAddGoalSheet(isSwahili);
    if (result == null || !mounted) return;

    try {
      final storage = await LocalStorageService.getInstance();
      final token = storage.getAuthToken();
      if (token == null) return;

      final goal = await BudgetService.createGoal(token, widget.userId, {
        'name': result['name'],
        'icon': result['icon'],
        'target_amount': result['target'],
        if (result['deadline'] != null)
          'deadline': (result['deadline'] as DateTime).toIso8601String(),
      });

      if (!mounted) return;
      if (goal != null) {
        _loadGoals();
      } else {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
              isSwahili ? 'Imeshindikana kuunda lengo' : 'Failed to create goal',
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

  // ── Contribute to goal ─────────────────────────────────────────────────────

  Future<void> _contributeToGoal(BudgetGoal goal) async {
    final strings = AppStringsScope.of(context);
    final isSwahili = strings?.isSwahili ?? false;

    final amount = await _showContributeDialog(isSwahili);
    if (amount == null || amount <= 0 || !mounted) return;

    try {
      final storage = await LocalStorageService.getInstance();
      final token = storage.getAuthToken();
      if (token == null || goal.id == null) return;

      final updated = await BudgetService.updateGoal(
        token,
        widget.userId,
        goal.id!,
        {'add_amount': amount},
      );

      if (!mounted) return;
      if (updated != null) {
        // Record goal contribution as savings expenditure
        ExpenditureService.recordExpenditure(
          token: token,
          amount: amount,
          category: 'akiba',
          description: 'Goal: ${goal.name}',
          sourceModule: 'budget',
          referenceId:
              'goal_contrib_${goal.id}_${DateTime.now().millisecondsSinceEpoch}',
        ).catchError((_) => null);

        // Check if goal just reached 100%
        final wasComplete = goal.isComplete;
        final nowComplete = updated.isComplete;
        _loadGoals();
        if (!wasComplete && nowComplete && mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              backgroundColor: const Color(0xFF4CAF50),
              behavior: SnackBarBehavior.floating,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(12),
              ),
              content: Text(
                isSwahili
                    ? '\u{1F389} Hongera! Lengo "${updated.name}" limefikiwa!'
                    : '\u{1F389} Congrats! Goal "${updated.name}" reached!',
                maxLines: 2,
                overflow: TextOverflow.ellipsis,
                style: const TextStyle(
                  fontWeight: FontWeight.w600,
                  color: Colors.white,
                ),
              ),
              duration: const Duration(seconds: 4),
            ),
          );
        }
      } else {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
              isSwahili ? 'Imeshindikana kuongeza akiba' : 'Failed to add savings',
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

  // ── Delete goal ────────────────────────────────────────────────────────────

  Future<void> _deleteGoal(BudgetGoal goal) async {
    final strings = AppStringsScope.of(context);
    final isSwahili = strings?.isSwahili ?? false;
    final messenger = ScaffoldMessenger.of(context);

    final confirm = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: Text(isSwahili ? 'Futa Lengo' : 'Delete Goal'),
        content: Text(
          isSwahili
              ? 'Una uhakika unataka kufuta "${goal.name}"?'
              : 'Are you sure you want to delete "${goal.name}"?',
          maxLines: 3,
          overflow: TextOverflow.ellipsis,
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx, false),
            child: Text(isSwahili ? 'Hapana' : 'Cancel'),
          ),
          FilledButton(
            onPressed: () => Navigator.pop(ctx, true),
            style: FilledButton.styleFrom(backgroundColor: _kError),
            child: Text(isSwahili ? 'Futa' : 'Delete'),
          ),
        ],
      ),
    );

    if (confirm != true || !mounted) return;

    try {
      final storage = await LocalStorageService.getInstance();
      final token = storage.getAuthToken();
      if (token == null || goal.id == null) return;

      final success =
          await BudgetService.deleteGoal(token, widget.userId, goal.id!);
      if (!mounted) return;

      if (success) {
        _loadGoals();
      } else {
        messenger.showSnackBar(
          SnackBar(
            content: Text(
              isSwahili
                  ? 'Imeshindikana kufuta lengo'
                  : 'Failed to delete goal',
            ),
          ),
        );
      }
    } catch (e) {
      if (!mounted) return;
      messenger.showSnackBar(SnackBar(content: Text(e.toString())));
    }
  }

  // ── Goal detail bottom sheet ───────────────────────────────────────────────

  void _showGoalDetail(BudgetGoal goal) {
    final strings = AppStringsScope.of(context);
    final isSwahili = strings?.isSwahili ?? false;

    showModalBottomSheet(
      context: context,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (ctx) => SafeArea(
        child: Padding(
          padding: const EdgeInsets.all(24),
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
              const SizedBox(height: 20),
              Row(
                children: [
                  Icon(
                    _iconForName(goal.icon),
                    size: 28,
                    color: _kPrimary,
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Text(
                      goal.name,
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                      style: const TextStyle(
                        fontSize: 20,
                        fontWeight: FontWeight.bold,
                        color: _kPrimary,
                      ),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 20),
              // Progress bar
              ClipRRect(
                borderRadius: BorderRadius.circular(6),
                child: LinearProgressIndicator(
                  value: (goal.percentComplete / 100).clamp(0.0, 1.0),
                  backgroundColor: _kDivider,
                  valueColor: AlwaysStoppedAnimation(
                    goal.isComplete
                        ? const Color(0xFF4CAF50)
                        : _kPrimary,
                  ),
                  minHeight: 10,
                ),
              ),
              const SizedBox(height: 8),
              Text(
                '${goal.percentComplete.toStringAsFixed(1)}% ${isSwahili ? 'imekamilika' : 'complete'}',
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: const TextStyle(fontSize: 13, color: _kSecondary),
              ),
              const SizedBox(height: 16),
              _detailRow(
                isSwahili ? 'Kiasi kilichofikishwa' : 'Saved',
                _formatTZS(goal.savedAmount),
              ),
              const SizedBox(height: 8),
              _detailRow(
                isSwahili ? 'Lengo' : 'Target',
                _formatTZS(goal.targetAmount),
              ),
              const SizedBox(height: 8),
              _detailRow(
                isSwahili ? 'Kiasi kinachobaki' : 'Remaining',
                _formatTZS(goal.remainingAmount),
              ),
              if (goal.deadline != null) ...[
                const SizedBox(height: 8),
                _detailRow(
                  isSwahili ? 'Tarehe ya mwisho' : 'Deadline',
                  '${goal.deadline!.day}/${goal.deadline!.month}/${goal.deadline!.year}',
                ),
              ],
              if (goal.monthlyTarget != null) ...[
                const SizedBox(height: 8),
                _detailRow(
                  isSwahili ? 'Kwa mwezi' : 'Monthly target',
                  '${_formatTZS(goal.monthlyTarget!)}/${isSwahili ? 'mwezi' : 'mo'}',
                ),
              ],
              const SizedBox(height: 24),
              if (!goal.isComplete)
                SizedBox(
                  width: double.infinity,
                  height: 48,
                  child: FilledButton(
                    onPressed: () {
                      Navigator.pop(ctx);
                      _contributeToGoal(goal);
                    },
                    style: FilledButton.styleFrom(
                      backgroundColor: _kPrimary,
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12),
                      ),
                    ),
                    child: Text(
                      isSwahili ? 'Changia' : 'Contribute',
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
  }

  Widget _detailRow(String label, String value) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Text(
          label,
          maxLines: 1,
          overflow: TextOverflow.ellipsis,
          style: const TextStyle(fontSize: 13, color: _kTertiary),
        ),
        Text(
          value,
          maxLines: 1,
          overflow: TextOverflow.ellipsis,
          style: const TextStyle(
            fontSize: 13,
            fontWeight: FontWeight.w600,
            color: _kPrimary,
          ),
        ),
      ],
    );
  }

  // ── Add goal bottom sheet ──────────────────────────────────────────────────

  Future<Map<String, dynamic>?> _showAddGoalSheet(bool isSwahili) async {
    final nameController = TextEditingController();
    final targetController = TextEditingController();
    DateTime? deadline;
    String selectedIcon = 'flag';

    final result = await showModalBottomSheet<Map<String, dynamic>>(
      context: context,
      isScrollControlled: true,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (ctx) => StatefulBuilder(
        builder: (ctx, setSheetState) => SafeArea(
          child: Padding(
            padding: EdgeInsets.only(
              left: 24,
              right: 24,
              top: 24,
              bottom: MediaQuery.of(ctx).viewInsets.bottom + 24,
            ),
            child: SingleChildScrollView(
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
                  const SizedBox(height: 20),
                  Text(
                    isSwahili ? 'Lengo Jipya' : 'New Goal',
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: const TextStyle(
                      fontSize: 20,
                      fontWeight: FontWeight.bold,
                      color: _kPrimary,
                    ),
                  ),
                  const SizedBox(height: 20),
                  // Name field
                  TextField(
                    controller: nameController,
                    textCapitalization: TextCapitalization.sentences,
                    decoration: InputDecoration(
                      labelText: isSwahili ? 'Jina la lengo' : 'Goal name',
                      border: const OutlineInputBorder(),
                    ),
                  ),
                  const SizedBox(height: 16),
                  // Icon picker
                  Text(
                    isSwahili ? 'Chagua ikoni' : 'Choose icon',
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: const TextStyle(fontSize: 13, color: _kSecondary),
                  ),
                  const SizedBox(height: 8),
                  Wrap(
                    spacing: 8,
                    runSpacing: 8,
                    children: _kGoalIcons.map((option) {
                      final isSelected = selectedIcon == option.name;
                      return InkWell(
                        onTap: () =>
                            setSheetState(() => selectedIcon = option.name),
                        borderRadius: BorderRadius.circular(10),
                        child: Container(
                          width: 44,
                          height: 44,
                          decoration: BoxDecoration(
                            color: isSelected
                                ? _kPrimary
                                : _kBackground,
                            borderRadius: BorderRadius.circular(10),
                            border: Border.all(
                              color: isSelected ? _kPrimary : _kDivider,
                            ),
                          ),
                          child: Icon(
                            option.icon,
                            size: 22,
                            color: isSelected ? Colors.white : _kSecondary,
                          ),
                        ),
                      );
                    }).toList(),
                  ),
                  const SizedBox(height: 16),
                  // Target amount
                  TextField(
                    controller: targetController,
                    keyboardType: TextInputType.number,
                    inputFormatters: [FilteringTextInputFormatter.digitsOnly],
                    decoration: InputDecoration(
                      labelText:
                          isSwahili ? 'Kiasi lengwa (TZS)' : 'Target amount (TZS)',
                      prefixText: 'TZS ',
                      border: const OutlineInputBorder(),
                    ),
                  ),
                  const SizedBox(height: 16),
                  // Deadline picker
                  GestureDetector(
                    onTap: () async {
                      final picked = await showDatePicker(
                        context: ctx,
                        initialDate:
                            DateTime.now().add(const Duration(days: 90)),
                        firstDate: DateTime.now(),
                        lastDate:
                            DateTime.now().add(const Duration(days: 3650)),
                      );
                      if (picked != null) {
                        setSheetState(() => deadline = picked);
                      }
                    },
                    child: Container(
                      padding: const EdgeInsets.symmetric(
                          horizontal: 12, vertical: 14),
                      decoration: BoxDecoration(
                        border: Border.all(color: _kDivider),
                        borderRadius: BorderRadius.circular(4),
                      ),
                      child: Row(
                        children: [
                          const Icon(Icons.calendar_month_outlined,
                              size: 18, color: _kSecondary),
                          const SizedBox(width: 8),
                          Expanded(
                            child: Text(
                              deadline != null
                                  ? '${deadline!.day}/${deadline!.month}/${deadline!.year}'
                                  : (isSwahili
                                      ? 'Tarehe ya mwisho (hiari)'
                                      : 'Deadline (optional)'),
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                              style: TextStyle(
                                color:
                                    deadline != null ? _kPrimary : _kTertiary,
                              ),
                            ),
                          ),
                          if (deadline != null)
                            GestureDetector(
                              onTap: () =>
                                  setSheetState(() => deadline = null),
                              child: const Icon(Icons.close_rounded,
                                  size: 18, color: _kTertiary),
                            ),
                        ],
                      ),
                    ),
                  ),
                  const SizedBox(height: 24),
                  // Submit button
                  SizedBox(
                    width: double.infinity,
                    height: 48,
                    child: FilledButton(
                      onPressed: () {
                        final name = nameController.text.trim();
                        final target =
                            double.tryParse(targetController.text);
                        if (name.isEmpty || target == null || target <= 0) {
                          return;
                        }
                        Navigator.pop(ctx, {
                          'name': name,
                          'icon': selectedIcon,
                          'target': target,
                          'deadline': deadline,
                        });
                      },
                      style: FilledButton.styleFrom(
                        backgroundColor: _kPrimary,
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(12),
                        ),
                      ),
                      child: Text(
                        isSwahili ? 'Unda Lengo' : 'Create Goal',
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );

    nameController.dispose();
    targetController.dispose();
    return result;
  }

  // ── Contribute dialog ──────────────────────────────────────────────────────

  Future<double?> _showContributeDialog(bool isSwahili) async {
    final controller = TextEditingController();
    final amount = await showDialog<double>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: Text(isSwahili ? 'Ongeza Akiba' : 'Add Savings'),
        content: TextField(
          controller: controller,
          keyboardType: TextInputType.number,
          inputFormatters: [FilteringTextInputFormatter.digitsOnly],
          autofocus: true,
          decoration: InputDecoration(
            prefixText: 'TZS ',
            border: const OutlineInputBorder(),
            hintText: isSwahili ? 'Kiasi' : 'Amount',
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: Text(isSwahili ? 'Ghairi' : 'Cancel'),
          ),
          FilledButton(
            onPressed: () {
              final val = double.tryParse(controller.text);
              Navigator.pop(ctx, val);
            },
            style: FilledButton.styleFrom(backgroundColor: _kPrimary),
            child: Text(isSwahili ? 'Ongeza' : 'Add'),
          ),
        ],
      ),
    );
    controller.dispose();
    return amount;
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

  static IconData _iconForName(String name) {
    for (final option in _kGoalIcons) {
      if (option.name == name) return option.icon;
    }
    return Icons.flag_rounded;
  }

  // ── Build ──────────────────────────────────────────────────────────────────

  @override
  Widget build(BuildContext context) {
    final strings = AppStringsScope.of(context);
    final isSwahili = strings?.isSwahili ?? false;

    return Scaffold(
      backgroundColor: _kBackground,
      appBar: AppBar(
        backgroundColor: _kSurface,
        elevation: 0,
        title: Text(
          isSwahili ? 'Malengo ya Akiba' : 'Savings Goals',
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
            onPressed: _addGoal,
            icon: const Icon(Icons.add_rounded, color: _kPrimary),
            tooltip: isSwahili ? 'Ongeza lengo' : 'Add goal',
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
                            onPressed: _loadGoals,
                            child: Text(isSwahili ? 'Jaribu tena' : 'Retry'),
                          ),
                        ],
                      ),
                    ),
                  )
                : _goals.isEmpty
                    ? _buildEmptyState(isSwahili)
                    : RefreshIndicator(
                        onRefresh: _loadGoals,
                        child: ListView.builder(
                          padding: const EdgeInsets.all(16),
                          itemCount: _goals.length,
                          itemBuilder: (ctx, i) {
                            final goal = _goals[i];
                            return Dismissible(
                              key: ValueKey(goal.id ?? i),
                              direction: DismissDirection.endToStart,
                              background: Container(
                                alignment: Alignment.centerRight,
                                padding: const EdgeInsets.only(right: 20),
                                margin: const EdgeInsets.only(bottom: 12),
                                decoration: BoxDecoration(
                                  color: _kError,
                                  borderRadius: BorderRadius.circular(14),
                                ),
                                child: const Icon(
                                  Icons.delete_rounded,
                                  color: Colors.white,
                                ),
                              ),
                              confirmDismiss: (_) async {
                                await _deleteGoal(goal);
                                // Return false — _deleteGoal handles reload
                                return false;
                              },
                              child: Padding(
                                padding: const EdgeInsets.only(bottom: 12),
                                child: GoalCard(
                                  goal: goal,
                                  isSwahili: isSwahili,
                                  onTap: () => _showGoalDetail(goal),
                                  onContribute: () =>
                                      _contributeToGoal(goal),
                                ),
                              ),
                            );
                          },
                        ),
                      ),
      ),
      floatingActionButton: _goals.isNotEmpty
          ? FloatingActionButton(
              onPressed: _addGoal,
              backgroundColor: _kPrimary,
              child: const Icon(Icons.add_rounded, color: Colors.white),
            )
          : null,
    );
  }

  // ── Empty state ────────────────────────────────────────────────────────────

  Widget _buildEmptyState(bool isSwahili) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(32),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Icon(Icons.flag_outlined, size: 64, color: _kTertiary),
            const SizedBox(height: 16),
            Text(
              isSwahili
                  ? 'Weka lengo lako la kwanza'
                  : 'Set your first goal',
              maxLines: 2,
              overflow: TextOverflow.ellipsis,
              textAlign: TextAlign.center,
              style: const TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.w600,
                color: _kSecondary,
              ),
            ),
            const SizedBox(height: 8),
            Text(
              isSwahili
                  ? 'Fuatilia malengo yako ya akiba hapa'
                  : 'Track your savings goals here',
              maxLines: 2,
              overflow: TextOverflow.ellipsis,
              textAlign: TextAlign.center,
              style: const TextStyle(fontSize: 14, color: _kTertiary),
            ),
            const SizedBox(height: 24),
            SizedBox(
              height: 48,
              child: FilledButton.icon(
                onPressed: _addGoal,
                icon: const Icon(Icons.add_rounded),
                label: Text(
                  isSwahili ? 'Ongeza Lengo' : 'Add Goal',
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
      ),
    );
  }
}

// ── Icon option helper ───────────────────────────────────────────────────────

class _GoalIconOption {
  final IconData icon;
  final String name;

  const _GoalIconOption(this.icon, this.name);
}
