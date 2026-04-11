// lib/shule_ya_jumapili/widgets/lesson_card.dart
import 'package:flutter/material.dart';
import '../models/shule_ya_jumapili_models.dart';

const Color _kPrimary = Color(0xFF1A1A1A);
const Color _kSecondary = Color(0xFF666666);

class LessonCard extends StatelessWidget {
  final SundaySchoolLesson lesson;
  final VoidCallback? onTap;

  const LessonCard({super.key, required this.lesson, this.onTap});

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
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
                Container(
                  width: 44,
                  height: 44,
                  decoration: BoxDecoration(
                    color: _kPrimary,
                    borderRadius: BorderRadius.circular(10),
                  ),
                  child: const Icon(Icons.school_rounded, size: 22, color: Colors.white),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(lesson.title,
                          style: const TextStyle(fontSize: 14, fontWeight: FontWeight.w600, color: _kPrimary),
                          maxLines: 2, overflow: TextOverflow.ellipsis),
                      const SizedBox(height: 2),
                      Text(lesson.date,
                          style: const TextStyle(fontSize: 12, color: _kSecondary)),
                    ],
                  ),
                ),
              ],
            ),
            const SizedBox(height: 10),
            // Memory verse preview
            Container(
              padding: const EdgeInsets.all(10),
              decoration: BoxDecoration(
                color: Colors.grey.shade50,
                borderRadius: BorderRadius.circular(8),
              ),
              child: Row(
                children: [
                  const Icon(Icons.format_quote_rounded, size: 16, color: _kSecondary),
                  const SizedBox(width: 6),
                  Expanded(
                    child: Text(lesson.memoryVerse,
                        style: const TextStyle(fontSize: 12, fontStyle: FontStyle.italic, color: _kSecondary),
                        maxLines: 2, overflow: TextOverflow.ellipsis),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 8),
            Row(
              children: [
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                  decoration: BoxDecoration(
                    color: Colors.grey.shade100,
                    borderRadius: BorderRadius.circular(6),
                  ),
                  child: Text(lesson.ageGroup,
                      style: const TextStyle(fontSize: 10, color: _kSecondary)),
                ),
                if (lesson.scriptureRef != null) ...[
                  const SizedBox(width: 8),
                  const Icon(Icons.menu_book_rounded, size: 12, color: _kSecondary),
                  const SizedBox(width: 4),
                  Text(lesson.scriptureRef!,
                      style: const TextStyle(fontSize: 11, color: _kSecondary)),
                ],
              ],
            ),
          ],
        ),
      ),
    );
  }
}
