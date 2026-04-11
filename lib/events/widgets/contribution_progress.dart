import 'package:flutter/material.dart';
import '../models/event_strings.dart';

const Color _kPrimary = Color(0xFF1A1A1A);

class ContributionProgress extends StatelessWidget {
  final double collected;
  final double goal;
  final String currency;
  const ContributionProgress({super.key, required this.collected, required this.goal, this.currency = 'TZS'});

  @override
  Widget build(BuildContext context) {
    final strings = EventStrings(isSwahili: true);
    final progress = goal > 0 ? (collected / goal).clamp(0.0, 1.0) : 0.0;
    final percent = (progress * 100).toInt();

    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(color: _kPrimary, borderRadius: BorderRadius.circular(16)),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(strings.formatPrice(collected, currency), style: const TextStyle(fontSize: 22, fontWeight: FontWeight.w700, color: Colors.white)),
              Text('$percent%', style: const TextStyle(fontSize: 16, fontWeight: FontWeight.w700, color: Colors.white)),
            ],
          ),
          const SizedBox(height: 4),
          Text('${strings.isSwahili ? "Lengo" : "Goal"}: ${strings.formatPrice(goal, currency)}', style: TextStyle(fontSize: 13, color: Colors.white.withValues(alpha: 0.7))),
          const SizedBox(height: 12),
          ClipRRect(
            borderRadius: BorderRadius.circular(6),
            child: LinearProgressIndicator(
              value: progress,
              backgroundColor: Colors.white.withValues(alpha: 0.2),
              valueColor: const AlwaysStoppedAnimation<Color>(Colors.white),
              minHeight: 8,
            ),
          ),
        ],
      ),
    );
  }
}
