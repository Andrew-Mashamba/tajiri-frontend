// lib/exam_prep/widgets/exam_countdown_card.dart
import 'package:flutter/material.dart';
import '../models/exam_prep_models.dart';

const Color _kPrimary = Color(0xFF1A1A1A);
const Color _kSecondary = Color(0xFF666666);

class ExamCountdownCard extends StatelessWidget {
  final ExamCountdown exam;
  final VoidCallback? onTap;
  const ExamCountdownCard({super.key, required this.exam, this.onTap});

  @override
  Widget build(BuildContext context) {
    final isUrgent = exam.daysRemaining <= 3 && !exam.isPast;
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.all(14),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: isUrgent ? Colors.red.shade200 : Colors.grey.shade200),
        ),
        child: Row(children: [
          Container(
            width: 52, height: 52,
            decoration: BoxDecoration(
              color: isUrgent ? Colors.red.shade50 : _kPrimary.withValues(alpha: 0.06),
              borderRadius: BorderRadius.circular(12),
            ),
            child: Center(child: Column(mainAxisSize: MainAxisSize.min, children: [
              Text('${exam.daysRemaining}', style: TextStyle(fontSize: 20, fontWeight: FontWeight.w700, color: isUrgent ? Colors.red : _kPrimary)),
              Text('siku', style: TextStyle(fontSize: 10, color: isUrgent ? Colors.red : _kSecondary)),
            ])),
          ),
          const SizedBox(width: 12),
          Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
            Text(exam.subject, style: const TextStyle(fontSize: 14, fontWeight: FontWeight.w600, color: _kPrimary), maxLines: 1, overflow: TextOverflow.ellipsis),
            if (exam.courseCode != null) Text(exam.courseCode!, style: const TextStyle(fontSize: 12, color: _kSecondary)),
            Text('${exam.examDate.day}/${exam.examDate.month}/${exam.examDate.year}${exam.venue != null ? ' · ${exam.venue}' : ''}', style: const TextStyle(fontSize: 12, color: _kSecondary), maxLines: 1, overflow: TextOverflow.ellipsis),
          ])),
        ]),
      ),
    );
  }
}
