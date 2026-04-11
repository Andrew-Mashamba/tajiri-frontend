// lib/newton/widgets/usage_counter.dart
import 'package:flutter/material.dart';
import '../models/newton_models.dart';

const Color _kPrimary = Color(0xFF1A1A1A);
const Color _kSecondary = Color(0xFF666666);

class UsageCounter extends StatelessWidget {
  final UsageStats stats;
  final bool isSwahili;

  const UsageCounter({
    super.key,
    required this.stats,
    this.isSwahili = false,
  });

  @override
  Widget build(BuildContext context) {
    final progress = stats.dailyLimit > 0
        ? (stats.questionsToday / stats.dailyLimit).clamp(0.0, 1.0)
        : 0.0;
    final isLow = stats.remaining <= 3;
    final label = isSwahili
        ? '${stats.questionsToday}/${stats.dailyLimit} maswali leo'
        : '${stats.questionsToday}/${stats.dailyLimit} questions today';

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
      decoration: BoxDecoration(
        color: isLow
            ? Colors.red.shade50
            : Colors.grey.shade100,
        borderRadius: BorderRadius.circular(16),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          SizedBox(
            width: 14,
            height: 14,
            child: CircularProgressIndicator(
              value: progress,
              strokeWidth: 2,
              backgroundColor: Colors.grey.shade300,
              color: isLow ? Colors.red : _kPrimary,
            ),
          ),
          const SizedBox(width: 6),
          Text(
            label,
            style: TextStyle(
              fontSize: 11,
              color: isLow ? Colors.red.shade700 : _kSecondary,
              fontWeight: FontWeight.w500,
            ),
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
          ),
        ],
      ),
    );
  }
}
