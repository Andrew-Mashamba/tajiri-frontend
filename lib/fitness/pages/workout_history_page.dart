// lib/fitness/pages/workout_history_page.dart
import 'package:flutter/material.dart';
import '../models/fitness_models.dart';
import '../services/fitness_service.dart';

const Color _kPrimary = Color(0xFF1A1A1A);
const Color _kSecondary = Color(0xFF666666);
const Color _kBackground = Color(0xFFFAFAFA);
const Color _kCardBg = Color(0xFFFFFFFF);

class WorkoutHistoryPage extends StatefulWidget {
  final int userId;
  const WorkoutHistoryPage({super.key, required this.userId});
  @override
  State<WorkoutHistoryPage> createState() => _WorkoutHistoryPageState();
}

class _WorkoutHistoryPageState extends State<WorkoutHistoryPage> {
  final FitnessService _service = FitnessService();
  List<WorkoutLog> _logs = [];
  bool _isLoading = true;

  @override
  void initState() { super.initState(); _load(); }

  Future<void> _load() async {
    setState(() => _isLoading = true);
    final result = await _service.getWorkoutHistory(widget.userId);
    if (mounted) setState(() { _isLoading = false; if (result.success) _logs = result.items; });
  }

  String _fmtDate(DateTime dt) {
    final now = DateTime.now();
    final diff = now.difference(dt);
    if (diff.inDays == 0) return 'Leo';
    if (diff.inDays == 1) return 'Jana';
    if (diff.inDays < 7) return '${diff.inDays} siku zilizopita';
    return '${dt.day}/${dt.month}/${dt.year}';
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: _kBackground,
      appBar: AppBar(backgroundColor: _kCardBg, elevation: 0, scrolledUnderElevation: 1, title: const Text('Historia ya Mazoezi', style: TextStyle(fontSize: 18, fontWeight: FontWeight.w600)), centerTitle: true),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator(strokeWidth: 2, color: _kPrimary))
          : _logs.isEmpty
              ? Center(child: Column(mainAxisAlignment: MainAxisAlignment.center, children: [
                  Icon(Icons.history_rounded, size: 64, color: Colors.grey.shade300), const SizedBox(height: 16),
                  Text('Hakuna mazoezi bado', style: TextStyle(fontSize: 16, color: Colors.grey.shade500)),
                  const SizedBox(height: 8),
                  Text('Anza mazoezi yako ya kwanza!', style: TextStyle(fontSize: 13, color: Colors.grey.shade400)),
                ]))
              : RefreshIndicator(
                  onRefresh: _load, color: _kPrimary,
                  child: ListView.builder(
                    padding: const EdgeInsets.all(16), itemCount: _logs.length,
                    itemBuilder: (context, i) {
                      final log = _logs[i];
                      return Container(
                        margin: const EdgeInsets.only(bottom: 8),
                        padding: const EdgeInsets.all(14),
                        decoration: BoxDecoration(color: _kCardBg, borderRadius: BorderRadius.circular(12)),
                        child: Row(children: [
                          Container(
                            width: 44, height: 44,
                            decoration: BoxDecoration(color: _kPrimary.withValues(alpha: 0.08), borderRadius: BorderRadius.circular(10)),
                            child: Icon(log.type.icon, size: 22, color: _kPrimary),
                          ),
                          const SizedBox(width: 12),
                          Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                            Text(log.type.displayName, style: const TextStyle(fontSize: 14, fontWeight: FontWeight.w600, color: _kPrimary)),
                            Text(_fmtDate(log.date), style: const TextStyle(fontSize: 12, color: _kSecondary)),
                            if (log.notes != null) Text(log.notes!, style: const TextStyle(fontSize: 11, color: _kSecondary), maxLines: 1, overflow: TextOverflow.ellipsis),
                          ])),
                          Column(crossAxisAlignment: CrossAxisAlignment.end, children: [
                            Text('${log.durationMinutes} dk', style: const TextStyle(fontSize: 14, fontWeight: FontWeight.w700, color: _kPrimary)),
                            if (log.caloriesBurned != null) Text('${log.caloriesBurned} kcal', style: const TextStyle(fontSize: 11, color: _kSecondary)),
                          ]),
                        ]),
                      );
                    },
                  ),
                ),
    );
  }
}
