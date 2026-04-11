// lib/my_faith/pages/faith_goals_page.dart
import 'package:flutter/material.dart';
import '../models/my_faith_models.dart';
import '../services/my_faith_service.dart';
import '../widgets/goal_card.dart';

const Color _kPrimary = Color(0xFF1A1A1A);
const Color _kSecondary = Color(0xFF666666);
const Color _kBg = Color(0xFFFAFAFA);

class FaithGoalsPage extends StatefulWidget {
  const FaithGoalsPage({super.key});
  @override
  State<FaithGoalsPage> createState() => _FaithGoalsPageState();
}

class _FaithGoalsPageState extends State<FaithGoalsPage> {
  List<SpiritualGoal> _goals = [];
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    setState(() => _isLoading = true);
    final r = await MyFaithService.getGoals();
    if (mounted) {
      setState(() {
        _isLoading = false;
        if (r.success) _goals = r.items;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: _kBg,
      appBar: AppBar(
        title: const Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text('Malengo ya Kiroho',
                style: TextStyle(fontSize: 18, fontWeight: FontWeight.w600)),
            Text('Spiritual Goals',
                style: TextStyle(fontSize: 12, color: _kSecondary)),
          ],
        ),
        backgroundColor: Colors.transparent,
        elevation: 0,
        foregroundColor: _kPrimary,
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: _showCreateDialog,
        backgroundColor: _kPrimary,
        child: const Icon(Icons.add_rounded, color: Colors.white),
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator(strokeWidth: 2, color: _kPrimary))
          : _goals.isEmpty
              ? Center(
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Icon(Icons.flag_rounded, size: 48, color: Colors.grey.shade400),
                      const SizedBox(height: 12),
                      const Text('Bado huna malengo',
                          style: TextStyle(color: _kSecondary, fontSize: 14)),
                      const Text('No goals yet',
                          style: TextStyle(color: _kSecondary, fontSize: 12)),
                    ],
                  ),
                )
              : RefreshIndicator(
                  onRefresh: _load,
                  color: _kPrimary,
                  child: ListView.separated(
                    padding: const EdgeInsets.all(16),
                    itemCount: _goals.length,
                    separatorBuilder: (_, __) => const SizedBox(height: 10),
                    itemBuilder: (_, i) => GoalCard(
                      goal: _goals[i],
                      onMarkDay: () => _markDay(_goals[i].id),
                    ),
                  ),
                ),
    );
  }

  Future<void> _markDay(int goalId) async {
    final r = await MyFaithService.markGoalDay(goalId);
    if (!mounted) return;
    if (r.success) {
      _load();
    } else {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(r.message ?? 'Imeshindwa / Failed')),
      );
    }
  }

  void _showCreateDialog() {
    final titleCtrl = TextEditingController();
    final daysCtrl = TextEditingController(text: '30');
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        title: const Text('Lengo Jipya / New Goal',
            style: TextStyle(fontSize: 16, fontWeight: FontWeight.w600, color: _kPrimary)),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            TextField(
              controller: titleCtrl,
              decoration: InputDecoration(
                hintText: 'Jina la lengo...',
                border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
              ),
            ),
            const SizedBox(height: 12),
            TextField(
              controller: daysCtrl,
              keyboardType: TextInputType.number,
              decoration: InputDecoration(
                hintText: 'Siku / Days',
                border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
              ),
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: const Text('Ghairi / Cancel', style: TextStyle(color: _kSecondary)),
          ),
          ElevatedButton(
            onPressed: () async {
              final title = titleCtrl.text.trim();
              if (title.isEmpty) return;
              Navigator.pop(ctx);
              final r = await MyFaithService.createGoal({
                'title': title,
                'target_days': int.tryParse(daysCtrl.text) ?? 30,
              });
              if (!mounted) return;
              if (r.success) {
                _load();
              } else {
                ScaffoldMessenger.of(context).showSnackBar(
                  SnackBar(content: Text(r.message ?? 'Imeshindwa kuongeza / Failed to add')),
                );
              }
            },
            style: ElevatedButton.styleFrom(
              backgroundColor: _kPrimary,
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
            ),
            child: const Text('Ongeza / Add', style: TextStyle(color: Colors.white)),
          ),
        ],
      ),
    );
  }
}
