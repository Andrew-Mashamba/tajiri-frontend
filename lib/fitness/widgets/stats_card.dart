// lib/fitness/widgets/stats_card.dart
import 'package:flutter/material.dart';
import '../models/fitness_models.dart';

const Color _kPrimary = Color(0xFF1A1A1A);

class StatsCard extends StatelessWidget {
  final FitnessStats stats;

  const StatsCard({super.key, required this.stats});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: _kPrimary,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [BoxShadow(color: _kPrimary.withValues(alpha: 0.3), blurRadius: 20, offset: const Offset(0, 8))],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Weekly progress ring
          Row(
            children: [
              SizedBox(
                width: 64, height: 64,
                child: Stack(
                  children: [
                    SizedBox.expand(
                      child: CircularProgressIndicator(
                        value: stats.weeklyProgress,
                        strokeWidth: 6,
                        backgroundColor: Colors.white.withValues(alpha: 0.1),
                        valueColor: const AlwaysStoppedAnimation<Color>(Color(0xFF4CAF50)),
                      ),
                    ),
                    Center(
                      child: Column(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Text(
                            '${stats.thisWeekMinutes}',
                            style: const TextStyle(color: Colors.white, fontSize: 18, fontWeight: FontWeight.w800),
                          ),
                          const Text('dk', style: TextStyle(color: Colors.white54, fontSize: 10)),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(width: 16),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text('Wiki Hii', style: TextStyle(color: Colors.white70, fontSize: 13)),
                    Text(
                      '${stats.thisWeekWorkouts} mazoezi, ${stats.thisWeekMinutes}/${stats.weeklyGoalMinutes} dk',
                      style: const TextStyle(color: Colors.white, fontSize: 14, fontWeight: FontWeight.w600),
                    ),
                  ],
                ),
              ),
              // Streak
              if (stats.currentStreak > 0)
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                  decoration: BoxDecoration(
                    color: Colors.orange.withValues(alpha: 0.2),
                    borderRadius: BorderRadius.circular(10),
                  ),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      const Icon(Icons.local_fire_department_rounded, size: 16, color: Colors.orange),
                      const SizedBox(width: 4),
                      Text('${stats.currentStreak}', style: const TextStyle(color: Colors.orange, fontSize: 14, fontWeight: FontWeight.w700)),
                    ],
                  ),
                ),
            ],
          ),
          const SizedBox(height: 16),
          // Quick stats row
          Row(
            children: [
              _MiniStat(value: '${stats.totalWorkouts}', label: 'Mazoezi'),
              _MiniStat(value: '${stats.totalMinutes}', label: 'Dakika'),
              _MiniStat(value: '${stats.totalCalories}', label: 'Kalori'),
              if (stats.currentWeight != null)
                _MiniStat(value: '${stats.currentWeight!.toStringAsFixed(1)}', label: 'kg'),
            ],
          ),
        ],
      ),
    );
  }
}

class _MiniStat extends StatelessWidget {
  final String value;
  final String label;
  const _MiniStat({required this.value, required this.label});

  @override
  Widget build(BuildContext context) {
    return Expanded(
      child: Column(
        children: [
          Text(value, style: const TextStyle(color: Colors.white, fontSize: 16, fontWeight: FontWeight.w700)),
          Text(label, style: const TextStyle(color: Colors.white54, fontSize: 10)),
        ],
      ),
    );
  }
}
