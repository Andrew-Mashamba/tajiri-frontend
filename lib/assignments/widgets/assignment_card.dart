// lib/assignments/widgets/assignment_card.dart
import 'package:flutter/material.dart';
import '../models/assignments_models.dart';

const Color _kPrimary = Color(0xFF1A1A1A);
const Color _kSecondary = Color(0xFF666666);

class AssignmentCard extends StatelessWidget {
  final Assignment assignment;
  final VoidCallback? onTap;
  const AssignmentCard({super.key, required this.assignment, this.onTap});

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.all(14),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: assignment.isOverdue ? Colors.red.shade200 : Colors.grey.shade200),
        ),
        child: Row(children: [
          Container(
            width: 4, height: 48,
            decoration: BoxDecoration(color: Color(assignment.priority.colorValue), borderRadius: BorderRadius.circular(2)),
          ),
          const SizedBox(width: 12),
          Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
            Text(assignment.title, style: const TextStyle(fontSize: 14, fontWeight: FontWeight.w600, color: _kPrimary), maxLines: 1, overflow: TextOverflow.ellipsis),
            const SizedBox(height: 2),
            Text(assignment.subject, style: const TextStyle(fontSize: 12, color: _kSecondary), maxLines: 1, overflow: TextOverflow.ellipsis),
            const SizedBox(height: 4),
            Row(children: [
              Icon(Icons.timer_rounded, size: 13, color: assignment.isOverdue ? Colors.red : _kSecondary),
              const SizedBox(width: 4),
              Text(assignment.remainingTime, style: TextStyle(fontSize: 12, color: assignment.isOverdue ? Colors.red : _kSecondary)),
              const Spacer(),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                decoration: BoxDecoration(color: _kPrimary.withValues(alpha: 0.06), borderRadius: BorderRadius.circular(4)),
                child: Text(assignment.status.displayName, style: const TextStyle(fontSize: 10, fontWeight: FontWeight.w500, color: _kPrimary)),
              ),
            ]),
          ])),
        ]),
      ),
    );
  }
}
