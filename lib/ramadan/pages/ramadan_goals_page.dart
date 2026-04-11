// lib/ramadan/pages/ramadan_goals_page.dart
import 'package:flutter/material.dart';
import '../models/ramadan_models.dart';
import '../services/ramadan_service.dart';
import '../../services/local_storage_service.dart';

const Color _kPrimary = Color(0xFF1A1A1A);
const Color _kSecondary = Color(0xFF666666);
const Color _kBg = Color(0xFFFAFAFA);

class RamadanGoalsPage extends StatefulWidget {
  final int userId;
  const RamadanGoalsPage({super.key, required this.userId});

  @override
  State<RamadanGoalsPage> createState() => _RamadanGoalsPageState();
}

class _RamadanGoalsPageState extends State<RamadanGoalsPage> {
  final _service = RamadanService();
  List<RamadanGoal> _goals = [];
  bool _loading = true;

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    setState(() => _loading = true);
    final storage = await LocalStorageService.getInstance();
    final token = storage.getAuthToken() ?? '';
    final result = await _service.getGoals(token: token);
    if (mounted) {
      setState(() {
        _goals = result.items;
        _loading = false;
      });
    }
  }

  IconData _categoryIcon(String category) {
    switch (category) {
      case 'prayer':
        return Icons.mosque_rounded;
      case 'quran':
        return Icons.menu_book_rounded;
      case 'charity':
        return Icons.volunteer_activism_rounded;
      case 'fasting':
        return Icons.no_food_rounded;
      default:
        return Icons.flag_rounded;
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: _kBg,
      appBar: AppBar(
        backgroundColor: _kBg,
        elevation: 0,
        scrolledUnderElevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_rounded, color: _kPrimary),
          onPressed: () => Navigator.pop(context),
        ),
        title: const Text(
          'Malengo ya Ramadan',
          style: TextStyle(
            color: _kPrimary, fontSize: 18, fontWeight: FontWeight.w600,
          ),
        ),
      ),
      body: SafeArea(
        child: _loading
            ? const Center(
                child: CircularProgressIndicator(
                    strokeWidth: 2, color: _kPrimary))
            : _goals.isEmpty
                ? const Center(
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Icon(Icons.flag_rounded, size: 48, color: _kSecondary),
                        SizedBox(height: 12),
                        Text('Hakuna malengo bado',
                            style: TextStyle(
                                color: _kSecondary, fontSize: 14)),
                      ],
                    ),
                  )
                : ListView.builder(
                    padding: const EdgeInsets.all(16),
                    itemCount: _goals.length,
                    itemBuilder: (context, i) {
                      final goal = _goals[i];
                      return Container(
                        margin: const EdgeInsets.only(bottom: 12),
                        padding: const EdgeInsets.all(16),
                        decoration: BoxDecoration(
                          color: Colors.white,
                          borderRadius: BorderRadius.circular(12),
                          border: Border.all(
                            color: goal.completed
                                ? Colors.green.shade200
                                : Colors.grey.shade200,
                          ),
                        ),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Row(
                              children: [
                                Icon(
                                  _categoryIcon(goal.category),
                                  color: goal.completed
                                      ? Colors.green
                                      : _kSecondary,
                                  size: 20,
                                ),
                                const SizedBox(width: 10),
                                Expanded(
                                  child: Text(
                                    goal.titleSwahili.isNotEmpty
                                        ? goal.titleSwahili
                                        : goal.title,
                                    style: const TextStyle(
                                      color: _kPrimary, fontSize: 15,
                                      fontWeight: FontWeight.w500,
                                    ),
                                    maxLines: 1,
                                    overflow: TextOverflow.ellipsis,
                                  ),
                                ),
                                Text(
                                  '${goal.progress}/${goal.target}',
                                  style: const TextStyle(
                                    color: _kSecondary, fontSize: 13,
                                  ),
                                ),
                              ],
                            ),
                            const SizedBox(height: 10),
                            LinearProgressIndicator(
                              value: goal.progressRate,
                              backgroundColor: Colors.grey.shade200,
                              valueColor: AlwaysStoppedAnimation<Color>(
                                goal.completed
                                    ? Colors.green
                                    : _kPrimary,
                              ),
                              minHeight: 6,
                              borderRadius: BorderRadius.circular(3),
                            ),
                          ],
                        ),
                      );
                    },
                  ),
      ),
    );
  }
}
