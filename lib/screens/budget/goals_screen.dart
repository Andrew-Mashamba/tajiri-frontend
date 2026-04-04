// lib/screens/budget/goals_screen.dart
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import '../../models/budget_models.dart';
import '../../services/budget_service.dart';

const Color _kPrimary = Color(0xFF1A1A1A);
const Color _kSecondary = Color(0xFF666666);
const Color _kTertiary = Color(0xFF999999);
const Color _kSurface = Color(0xFFFFFFFF);
const Color _kBackground = Color(0xFFFAFAFA);
const Color _kDivider = Color(0xFFE0E0E0);
const Color _kSuccess = Color(0xFF4CAF50);

class GoalsScreen extends StatefulWidget {
  final int userId;

  const GoalsScreen({super.key, required this.userId});

  @override
  State<GoalsScreen> createState() => _GoalsScreenState();
}

class _GoalsScreenState extends State<GoalsScreen> {
  final BudgetService _service = BudgetService();
  List<BudgetGoal> _goals = [];
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _loadGoals();
  }

  Future<void> _loadGoals() async {
    setState(() => _isLoading = true);
    final goals = await _service.getGoals();
    if (mounted) setState(() { _goals = goals; _isLoading = false; });
  }

  Future<void> _addGoal() async {
    final result = await _showGoalDialog();
    if (result != null) {
      await _service.createGoal(
        name: result['name'] as String,
        icon: result['icon'] as String,
        targetAmount: result['target'] as double,
        deadline: result['deadline'] as DateTime?,
      );
      _loadGoals();
    }
  }

  Future<void> _addFunds(BudgetGoal goal) async {
    final controller = TextEditingController();
    final amount = await showDialog<double>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Ongeza Akiba'),
        content: TextField(
          controller: controller,
          keyboardType: TextInputType.number,
          inputFormatters: [FilteringTextInputFormatter.digitsOnly],
          decoration: const InputDecoration(prefixText: 'TZS ', border: OutlineInputBorder()),
          autofocus: true,
        ),
        actions: [
          TextButton(onPressed: () => Navigator.pop(ctx), child: const Text('Ghairi')),
          FilledButton(
            onPressed: () {
              final val = double.tryParse(controller.text);
              Navigator.pop(ctx, val);
            },
            child: const Text('Ongeza'),
          ),
        ],
      ),
    );
    controller.dispose();

    if (amount != null && amount > 0) {
      await _service.addToGoal(goal.id!, amount);
      _loadGoals();
    }
  }

  Future<void> _deleteGoal(BudgetGoal goal) async {
    final confirm = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Futa Lengo'),
        content: Text('Una uhakika unataka kufuta "${goal.name}"?'),
        actions: [
          TextButton(onPressed: () => Navigator.pop(ctx, false), child: const Text('Hapana')),
          FilledButton(
            onPressed: () => Navigator.pop(ctx, true),
            style: FilledButton.styleFrom(backgroundColor: Colors.red),
            child: const Text('Futa'),
          ),
        ],
      ),
    );
    if (confirm == true) {
      await _service.deleteGoal(goal.id!);
      _loadGoals();
    }
  }

  Future<Map<String, dynamic>?> _showGoalDialog() async {
    final nameController = TextEditingController();
    final targetController = TextEditingController();
    DateTime? deadline;

    return showDialog<Map<String, dynamic>>(
      context: context,
      builder: (ctx) => StatefulBuilder(
        builder: (ctx, setDialogState) => AlertDialog(
          title: const Text('Lengo Jipya'),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              TextField(
                controller: nameController,
                textCapitalization: TextCapitalization.sentences,
                decoration: const InputDecoration(labelText: 'Jina la lengo', border: OutlineInputBorder()),
              ),
              const SizedBox(height: 12),
              TextField(
                controller: targetController,
                keyboardType: TextInputType.number,
                inputFormatters: [FilteringTextInputFormatter.digitsOnly],
                decoration: const InputDecoration(labelText: 'Kiasi (TZS)', prefixText: 'TZS ', border: OutlineInputBorder()),
              ),
              const SizedBox(height: 12),
              GestureDetector(
                onTap: () async {
                  final picked = await showDatePicker(
                    context: ctx,
                    initialDate: DateTime.now().add(const Duration(days: 90)),
                    firstDate: DateTime.now(),
                    lastDate: DateTime.now().add(const Duration(days: 3650)),
                  );
                  if (picked != null) setDialogState(() => deadline = picked);
                },
                child: Container(
                  padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 14),
                  decoration: BoxDecoration(
                    border: Border.all(color: _kDivider),
                    borderRadius: BorderRadius.circular(4),
                  ),
                  child: Row(
                    children: [
                      const Icon(Icons.calendar_month_outlined, size: 18, color: _kSecondary),
                      const SizedBox(width: 8),
                      Text(
                        deadline != null ? '${deadline!.day}/${deadline!.month}/${deadline!.year}' : 'Tarehe ya mwisho (hiari)',
                        style: TextStyle(color: deadline != null ? _kPrimary : _kTertiary),
                      ),
                    ],
                  ),
                ),
              ),
            ],
          ),
          actions: [
            TextButton(onPressed: () => Navigator.pop(ctx), child: const Text('Ghairi')),
            FilledButton(
              onPressed: () {
                final name = nameController.text.trim();
                final target = double.tryParse(targetController.text);
                if (name.isEmpty || target == null || target <= 0) return;
                Navigator.pop(ctx, {
                  'name': name,
                  'icon': 'flag',
                  'target': target,
                  'deadline': deadline,
                });
              },
              child: const Text('Unda'),
            ),
          ],
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: _kBackground,
      appBar: AppBar(
        backgroundColor: _kSurface,
        elevation: 0,
        title: const Text('Malengo', style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: _kPrimary)),
        iconTheme: const IconThemeData(color: _kPrimary),
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator(strokeWidth: 2))
          : _goals.isEmpty
              ? Center(
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      const Icon(Icons.flag_outlined, size: 48, color: _kTertiary),
                      const SizedBox(height: 16),
                      const Text('Bado hakuna lengo', style: TextStyle(fontSize: 16, color: _kSecondary)),
                      const SizedBox(height: 8),
                      const Text('Weka lengo la akiba kuanza kufuatilia', style: TextStyle(fontSize: 13, color: _kTertiary)),
                      const SizedBox(height: 24),
                      FilledButton.icon(
                        onPressed: _addGoal,
                        icon: const Icon(Icons.add),
                        label: const Text('Ongeza Lengo'),
                        style: FilledButton.styleFrom(backgroundColor: _kPrimary),
                      ),
                    ],
                  ),
                )
              : RefreshIndicator(
                  onRefresh: _loadGoals,
                  child: ListView.builder(
                    padding: const EdgeInsets.all(16),
                    itemCount: _goals.length,
                    itemBuilder: (ctx, i) => _buildGoalCard(_goals[i]),
                  ),
                ),
      floatingActionButton: _goals.isNotEmpty
          ? FloatingActionButton(
              onPressed: _addGoal,
              backgroundColor: _kPrimary,
              child: const Icon(Icons.add, color: Colors.white),
            )
          : null,
    );
  }

  Widget _buildGoalCard(BudgetGoal goal) {
    final pct = goal.percentComplete / 100;
    return Container(
      margin: const EdgeInsets.only(bottom: 12),
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
              const Icon(Icons.flag_rounded, size: 20, color: _kPrimary),
              const SizedBox(width: 8),
              Expanded(
                child: Text(goal.name, style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold, color: _kPrimary)),
              ),
              PopupMenuButton<String>(
                icon: const Icon(Icons.more_vert, size: 18, color: _kTertiary),
                onSelected: (v) {
                  if (v == 'delete') _deleteGoal(goal);
                },
                itemBuilder: (_) => [
                  const PopupMenuItem(value: 'delete', child: Text('Futa', style: TextStyle(color: Colors.red))),
                ],
              ),
            ],
          ),
          const SizedBox(height: 12),
          ClipRRect(
            borderRadius: BorderRadius.circular(6),
            child: LinearProgressIndicator(
              value: pct.clamp(0.0, 1.0),
              backgroundColor: _kDivider,
              valueColor: AlwaysStoppedAnimation(goal.isComplete ? _kSuccess : _kPrimary),
              minHeight: 10,
            ),
          ),
          const SizedBox(height: 8),
          Row(
            children: [
              Text(
                'TZS ${goal.savedAmount.toStringAsFixed(0)} / TZS ${goal.targetAmount.toStringAsFixed(0)}',
                style: const TextStyle(fontSize: 12, color: _kSecondary),
              ),
              const Spacer(),
              Text(
                '${goal.percentComplete.toStringAsFixed(0)}%',
                style: TextStyle(
                  fontSize: 14,
                  fontWeight: FontWeight.bold,
                  color: goal.isComplete ? _kSuccess : _kPrimary,
                ),
              ),
            ],
          ),
          if (goal.monthlyTarget != null) ...[
            const SizedBox(height: 4),
            Text(
              'Weka TZS ${goal.monthlyTarget!.toStringAsFixed(0)} kwa mwezi ufikie lengo',
              style: const TextStyle(fontSize: 11, color: _kTertiary),
            ),
          ],
          const SizedBox(height: 12),
          SizedBox(
            width: double.infinity,
            child: OutlinedButton(
              onPressed: () => _addFunds(goal),
              style: OutlinedButton.styleFrom(
                foregroundColor: _kPrimary,
                side: const BorderSide(color: _kDivider),
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
              ),
              child: const Text('Ongeza Akiba'),
            ),
          ),
        ],
      ),
    );
  }
}
