// lib/projects/widgets/task_card.dart
import 'package:flutter/material.dart';
import '../models/project_models.dart';

const Color _kPrimary = Color(0xFF1A1A1A);
const Color _kSecondary = Color(0xFF666666);
const Color _kCardBg = Color(0xFFFFFFFF);

class TaskCard extends StatelessWidget {
  final Task task;
  final bool isSwahili;
  final VoidCallback onTap;

  const TaskCard({
    super.key,
    required this.task,
    required this.isSwahili,
    required this.onTap,
  });

  Color _priorityColor() {
    switch (task.priority) {
      case TaskPriority.low:
        return Colors.grey.shade400;
      case TaskPriority.medium:
        return Colors.amber.shade600;
      case TaskPriority.high:
        return Colors.red.shade400;
    }
  }

  @override
  Widget build(BuildContext context) {
    final isOverdue = task.dueDate != null &&
        task.dueDate!.isBefore(DateTime.now()) &&
        task.status != TaskStatus.done;

    return GestureDetector(
      onTap: onTap,
      child: Container(
        margin: const EdgeInsets.only(bottom: 8),
        padding: const EdgeInsets.symmetric(
            horizontal: 14, vertical: 12),
        decoration: BoxDecoration(
          color: _kCardBg,
          borderRadius: BorderRadius.circular(12),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withValues(alpha: 0.04),
              blurRadius: 6,
              offset: const Offset(0, 2),
            ),
          ],
        ),
        child: Row(
          children: [
            Container(
              width: 8,
              height: 8,
              margin: const EdgeInsets.only(right: 10, top: 2),
              decoration: BoxDecoration(
                color: _priorityColor(),
                shape: BoxShape.circle,
              ),
            ),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    task.title,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: const TextStyle(
                        fontSize: 14,
                        fontWeight: FontWeight.w600,
                        color: _kPrimary),
                  ),
                  if (task.assigneeName != null) ...[
                    const SizedBox(height: 2),
                    Text(
                      task.assigneeName!,
                      style: const TextStyle(
                          fontSize: 12, color: _kSecondary),
                    ),
                  ],
                ],
              ),
            ),
            if (task.dueDate != null)
              Text(
                '${task.dueDate!.year}-${task.dueDate!.month.toString().padLeft(2, '0')}-${task.dueDate!.day.toString().padLeft(2, '0')}',
                style: TextStyle(
                    fontSize: 11,
                    color: isOverdue ? Colors.red : _kSecondary),
              ),
            const SizedBox(width: 6),
            const Icon(Icons.chevron_right_rounded,
                size: 16, color: _kSecondary),
          ],
        ),
      ),
    );
  }
}
