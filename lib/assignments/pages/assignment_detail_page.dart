// lib/assignments/pages/assignment_detail_page.dart
import 'package:flutter/material.dart';
import '../models/assignments_models.dart';

const Color _kPrimary = Color(0xFF1A1A1A);
const Color _kSecondary = Color(0xFF666666);
const Color _kBg = Color(0xFFFAFAFA);

class AssignmentDetailPage extends StatelessWidget {
  final Assignment assignment;
  const AssignmentDetailPage({super.key, required this.assignment});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: _kBg,
      appBar: AppBar(backgroundColor: _kBg, foregroundColor: _kPrimary, elevation: 0, title: const Text('Kazi', style: TextStyle(fontSize: 16, fontWeight: FontWeight.w600))),
      body: SafeArea(
        child: ListView(padding: const EdgeInsets.all(16), children: [
          // Status + Priority
          Row(children: [
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
              decoration: BoxDecoration(color: Color(assignment.priority.colorValue).withValues(alpha: 0.15), borderRadius: BorderRadius.circular(6)),
              child: Text(assignment.priority.displayName, style: TextStyle(fontSize: 12, fontWeight: FontWeight.w600, color: Color(assignment.priority.colorValue))),
            ),
            const SizedBox(width: 8),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
              decoration: BoxDecoration(color: _kPrimary.withValues(alpha: 0.06), borderRadius: BorderRadius.circular(6)),
              child: Text(assignment.status.displayName, style: const TextStyle(fontSize: 12, color: _kPrimary)),
            ),
          ]),
          const SizedBox(height: 14),

          // Title
          Text(assignment.title, style: const TextStyle(fontSize: 20, fontWeight: FontWeight.w700, color: _kPrimary)),
          const SizedBox(height: 4),
          Text(assignment.subject, style: const TextStyle(fontSize: 14, color: _kSecondary)),
          const SizedBox(height: 16),

          // Due date
          Container(
            padding: const EdgeInsets.all(14),
            decoration: BoxDecoration(
              color: assignment.isOverdue ? Colors.red.shade50 : Colors.white,
              borderRadius: BorderRadius.circular(12),
              border: Border.all(color: assignment.isOverdue ? Colors.red.shade200 : Colors.grey.shade200),
            ),
            child: Row(children: [
              Icon(Icons.timer_rounded, size: 20, color: assignment.isOverdue ? Colors.red : _kPrimary),
              const SizedBox(width: 10),
              Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                Text('Tarehe ya Mwisho / Due Date', style: TextStyle(fontSize: 11, color: assignment.isOverdue ? Colors.red : _kSecondary)),
                Text('${assignment.dueDate.day}/${assignment.dueDate.month}/${assignment.dueDate.year} — ${assignment.remainingTime}',
                    style: TextStyle(fontSize: 14, fontWeight: FontWeight.w600, color: assignment.isOverdue ? Colors.red : _kPrimary)),
              ])),
            ]),
          ),
          const SizedBox(height: 16),

          // Description
          const Text('Maelezo / Description', style: TextStyle(fontSize: 14, fontWeight: FontWeight.w600, color: _kPrimary)),
          const SizedBox(height: 6),
          Text(assignment.description.isEmpty ? 'Hakuna maelezo' : assignment.description, style: const TextStyle(fontSize: 14, color: _kSecondary, height: 1.5)),
          const SizedBox(height: 16),

          // Grade
          if (assignment.grade != null) ...[
            Container(
              padding: const EdgeInsets.all(14),
              decoration: BoxDecoration(color: Colors.green.shade50, borderRadius: BorderRadius.circular(12)),
              child: Row(children: [
                const Icon(Icons.grade_rounded, size: 20, color: Colors.green),
                const SizedBox(width: 10),
                Text('Alama: ${assignment.grade}${assignment.maxGrade != null ? ' / ${assignment.maxGrade}' : ''}',
                    style: const TextStyle(fontSize: 16, fontWeight: FontWeight.w600, color: Colors.green)),
              ]),
            ),
          ],
        ]),
      ),
    );
  }
}
