// lib/my_faith/widgets/goal_card.dart
import 'package:flutter/material.dart';
import '../models/my_faith_models.dart';

const Color _kPrimary = Color(0xFF1A1A1A);
const Color _kSecondary = Color(0xFF666666);

class GoalCard extends StatelessWidget {
  final SpiritualGoal goal;
  final VoidCallback? onMarkDay;

  const GoalCard({super.key, required this.goal, this.onMarkDay});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: Colors.grey.shade200),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              const Icon(Icons.flag_rounded, size: 20, color: _kPrimary),
              const SizedBox(width: 10),
              Expanded(
                child: Text(goal.title,
                    style: const TextStyle(fontSize: 15, fontWeight: FontWeight.w600, color: _kPrimary),
                    maxLines: 1, overflow: TextOverflow.ellipsis),
              ),
              if (onMarkDay != null)
                GestureDetector(
                  onTap: onMarkDay,
                  child: Container(
                    padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                    decoration: BoxDecoration(
                      color: _kPrimary,
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: const Text('Leo / Today',
                        style: TextStyle(color: Colors.white, fontSize: 12, fontWeight: FontWeight.w600)),
                  ),
                ),
            ],
          ),
          const SizedBox(height: 10),
          ClipRRect(
            borderRadius: BorderRadius.circular(4),
            child: LinearProgressIndicator(
              value: goal.progress,
              backgroundColor: Colors.grey.shade200,
              valueColor: const AlwaysStoppedAnimation<Color>(_kPrimary),
              minHeight: 6,
            ),
          ),
          const SizedBox(height: 6),
          Text(
            '${goal.completedDays} / ${goal.targetDays} siku / days',
            style: const TextStyle(fontSize: 12, color: _kSecondary),
          ),
        ],
      ),
    );
  }
}
