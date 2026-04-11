// lib/results/widgets/gpa_card.dart
import 'package:flutter/material.dart';
import '../models/results_models.dart';

const Color _kPrimary = Color(0xFF1A1A1A);
const Color _kSecondary = Color(0xFF666666);

class GpaCard extends StatelessWidget {
  final GpaSummary summary;
  const GpaCard({super.key, required this.summary});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(12), border: Border.all(color: Colors.grey.shade200)),
      child: Column(children: [
        const Text('Maendeleo ya Shahada', style: TextStyle(fontSize: 14, fontWeight: FontWeight.w600, color: _kPrimary)),
        const Text('Degree Progress', style: TextStyle(fontSize: 11, color: _kSecondary)),
        const SizedBox(height: 12),
        LinearProgressIndicator(
          value: summary.progressPercent.clamp(0, 1).toDouble(),
          backgroundColor: Colors.grey.shade200,
          color: _kPrimary,
          minHeight: 8,
          borderRadius: BorderRadius.circular(4),
        ),
        const SizedBox(height: 8),
        Row(mainAxisAlignment: MainAxisAlignment.spaceBetween, children: [
          Text('${summary.totalCreditsEarned} credits earned', style: const TextStyle(fontSize: 12, color: _kSecondary)),
          Text('${(summary.progressPercent * 100).toInt()}%', style: const TextStyle(fontSize: 12, fontWeight: FontWeight.w600, color: _kPrimary)),
        ]),
        const SizedBox(height: 4),
        Row(mainAxisAlignment: MainAxisAlignment.spaceBetween, children: [
          Text('Muhula: ${summary.semestersCompleted}', style: const TextStyle(fontSize: 12, color: _kSecondary)),
          Text('Jumla: ${summary.totalCreditsRequired} credits', style: const TextStyle(fontSize: 12, color: _kSecondary)),
        ]),
      ]),
    );
  }
}
