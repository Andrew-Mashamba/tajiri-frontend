// lib/my_class/widgets/class_card.dart
import 'package:flutter/material.dart';
import '../models/my_class_models.dart';

const Color _kPrimary = Color(0xFF1A1A1A);
const Color _kSecondary = Color(0xFF666666);

class ClassCard extends StatelessWidget {
  final StudentClass studentClass;
  final VoidCallback? onTap;

  const ClassCard({super.key, required this.studentClass, this.onTap});

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: Colors.grey.shade200),
        ),
        child: Row(
          children: [
            Container(
              width: 48,
              height: 48,
              decoration: BoxDecoration(
                color: _kPrimary.withValues(alpha: 0.08),
                borderRadius: BorderRadius.circular(12),
              ),
              child: const Icon(Icons.school_rounded, color: _kPrimary, size: 24),
            ),
            const SizedBox(width: 14),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    studentClass.name,
                    style: const TextStyle(fontSize: 14, fontWeight: FontWeight.w600, color: _kPrimary),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                  const SizedBox(height: 2),
                  Text(
                    '${studentClass.courseCode} · ${studentClass.semester} ${studentClass.year}',
                    style: const TextStyle(fontSize: 12, color: _kSecondary),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                  const SizedBox(height: 2),
                  Row(
                    children: [
                      const Icon(Icons.people_rounded, size: 14, color: _kSecondary),
                      const SizedBox(width: 4),
                      Text('${studentClass.memberCount}', style: const TextStyle(fontSize: 12, color: _kSecondary)),
                      const SizedBox(width: 12),
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 1),
                        decoration: BoxDecoration(
                          color: _kPrimary.withValues(alpha: 0.06),
                          borderRadius: BorderRadius.circular(4),
                        ),
                        child: Text(
                          studentClass.joinCode,
                          style: const TextStyle(fontSize: 10, fontWeight: FontWeight.w600, color: _kPrimary, letterSpacing: 1),
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
            const Icon(Icons.chevron_right_rounded, color: _kSecondary, size: 20),
          ],
        ),
      ),
    );
  }
}
