// lib/projects/widgets/project_card.dart
import 'package:flutter/material.dart';
import '../models/project_models.dart';

const Color _kPrimary = Color(0xFF1A1A1A);
const Color _kSecondary = Color(0xFF666666);
const Color _kCardBg = Color(0xFFFFFFFF);

class ProjectCard extends StatelessWidget {
  final Project project;
  final bool isSwahili;
  final VoidCallback onTap;
  final VoidCallback onEditTap;
  final VoidCallback onDeleteTap;

  const ProjectCard({
    super.key,
    required this.project,
    required this.isSwahili,
    required this.onTap,
    required this.onEditTap,
    required this.onDeleteTap,
  });

  String _statusLabel(bool sw) {
    switch (project.status) {
      case ProjectStatus.active:
        return sw ? 'Inafanya Kazi' : 'Active';
      case ProjectStatus.completed:
        return sw ? 'Imekamilika' : 'Completed';
      case ProjectStatus.onHold:
        return sw ? 'Imesimamishwa' : 'On Hold';
    }
  }

  @override
  Widget build(BuildContext context) {
    final sw = isSwahili;
    final progress = project.taskCount > 0
        ? project.completedCount / project.taskCount
        : 0.0;
    final isOverdue = project.endDate != null &&
        project.endDate!.isBefore(DateTime.now()) &&
        project.status != ProjectStatus.completed;

    return GestureDetector(
      onTap: onTap,
      child: Container(
        margin: const EdgeInsets.only(bottom: 10),
        padding: const EdgeInsets.all(14),
        decoration: BoxDecoration(
          color: _kCardBg,
          borderRadius: BorderRadius.circular(14),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withValues(alpha: 0.05),
              blurRadius: 8,
              offset: const Offset(0, 2),
            ),
          ],
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Expanded(
                  child: Text(
                    project.title,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: const TextStyle(
                        fontSize: 15,
                        fontWeight: FontWeight.w600,
                        color: _kPrimary),
                  ),
                ),
                PopupMenuButton<String>(
                  icon: const Icon(Icons.more_vert_rounded,
                      size: 18, color: _kSecondary),
                  onSelected: (v) {
                    if (v == 'edit') onEditTap();
                    if (v == 'delete') onDeleteTap();
                  },
                  itemBuilder: (_) => [
                    PopupMenuItem(
                        value: 'edit',
                        child: Text(sw ? 'Hariri' : 'Edit')),
                    PopupMenuItem(
                        value: 'delete',
                        child: Text(sw ? 'Futa' : 'Delete')),
                  ],
                ),
              ],
            ),
            if (project.description.isNotEmpty) ...[
              const SizedBox(height: 4),
              Text(
                project.description,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: const TextStyle(
                    fontSize: 13, color: _kSecondary),
              ),
            ],
            const SizedBox(height: 8),
            Row(
              children: [
                Container(
                  padding: const EdgeInsets.symmetric(
                      horizontal: 8, vertical: 3),
                  decoration: BoxDecoration(
                    color: Colors.grey.shade100,
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Text(_statusLabel(sw),
                      style: const TextStyle(
                          fontSize: 11, color: _kPrimary)),
                ),
                const Spacer(),
                if (project.endDate != null)
                  Text(
                    '${project.endDate!.year}-${project.endDate!.month.toString().padLeft(2, '0')}-${project.endDate!.day.toString().padLeft(2, '0')}',
                    style: TextStyle(
                        fontSize: 11,
                        color: isOverdue ? Colors.red : _kSecondary),
                  ),
              ],
            ),
            const SizedBox(height: 8),
            LinearProgressIndicator(
              value: progress,
              backgroundColor: Colors.grey.shade200,
              color: _kPrimary,
              minHeight: 4,
              borderRadius: BorderRadius.circular(2),
            ),
            const SizedBox(height: 4),
            Text(
              sw
                  ? '${project.completedCount}/${project.taskCount} kazi zilizokamilika'
                  : '${project.completedCount}/${project.taskCount} tasks done',
              style: const TextStyle(
                  fontSize: 11, color: _kSecondary),
            ),
          ],
        ),
      ),
    );
  }
}
