// lib/shule_ya_jumapili/pages/lesson_detail_page.dart
import 'package:flutter/material.dart';
import '../models/shule_ya_jumapili_models.dart';

const Color _kPrimary = Color(0xFF1A1A1A);
const Color _kSecondary = Color(0xFF666666);
const Color _kBg = Color(0xFFFAFAFA);

class LessonDetailPage extends StatelessWidget {
  final SundaySchoolLesson lesson;
  const LessonDetailPage({super.key, required this.lesson});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: _kBg,
      appBar: AppBar(
        title: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(lesson.title,
                style: const TextStyle(fontSize: 16, fontWeight: FontWeight.w600)),
            Text(lesson.date,
                style: const TextStyle(fontSize: 12, color: _kSecondary)),
          ],
        ),
        backgroundColor: Colors.transparent,
        elevation: 0,
        foregroundColor: _kPrimary,
      ),
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          // Series & age group
          Row(
            children: [
              if (lesson.seriesName != null)
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                  decoration: BoxDecoration(
                    color: _kPrimary,
                    borderRadius: BorderRadius.circular(6),
                  ),
                  child: Text(lesson.seriesName!,
                      style: const TextStyle(color: Colors.white, fontSize: 11)),
                ),
              if (lesson.seriesName != null) const SizedBox(width: 8),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                decoration: BoxDecoration(
                  color: Colors.grey.shade100,
                  borderRadius: BorderRadius.circular(6),
                ),
                child: Text(lesson.ageGroup,
                    style: const TextStyle(color: _kSecondary, fontSize: 11)),
              ),
            ],
          ),
          const SizedBox(height: 16),

          // Scripture
          if (lesson.scriptureRef != null) ...[
            _Section(
              icon: Icons.menu_book_rounded,
              title: 'Aya / Scripture',
              child: Text(lesson.scriptureRef!,
                  style: const TextStyle(fontSize: 15, fontStyle: FontStyle.italic, color: _kPrimary)),
            ),
            const SizedBox(height: 16),
          ],

          // Memory verse
          _Section(
            icon: Icons.format_quote_rounded,
            title: 'Aya ya Kujifunza / Memory Verse',
            child: Container(
              width: double.infinity,
              padding: const EdgeInsets.all(14),
              decoration: BoxDecoration(
                color: _kPrimary,
                borderRadius: BorderRadius.circular(12),
              ),
              child: Text(lesson.memoryVerse,
                  style: const TextStyle(color: Colors.white, fontSize: 15, fontStyle: FontStyle.italic, height: 1.5)),
            ),
          ),
          const SizedBox(height: 16),

          // Objective
          if (lesson.objective != null) ...[
            _Section(
              icon: Icons.track_changes_rounded,
              title: 'Lengo / Objective',
              child: Text(lesson.objective!,
                  style: const TextStyle(fontSize: 14, color: _kPrimary, height: 1.5)),
            ),
            const SizedBox(height: 16),
          ],

          // Description
          if (lesson.description != null) ...[
            _Section(
              icon: Icons.article_rounded,
              title: 'Somo / Lesson',
              child: Text(lesson.description!,
                  style: const TextStyle(fontSize: 14, color: _kPrimary, height: 1.5)),
            ),
            const SizedBox(height: 16),
          ],

          // Activity
          if (lesson.activity != null) ...[
            _Section(
              icon: Icons.palette_rounded,
              title: 'Shughuli / Activity',
              child: Text(lesson.activity!,
                  style: const TextStyle(fontSize: 14, color: _kPrimary, height: 1.5)),
            ),
          ],
          const SizedBox(height: 24),
        ],
      ),
    );
  }
}

class _Section extends StatelessWidget {
  final IconData icon;
  final String title;
  final Widget child;
  const _Section({required this.icon, required this.title, required this.child});
  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            Icon(icon, size: 18, color: _kPrimary),
            const SizedBox(width: 8),
            Text(title,
                style: const TextStyle(fontSize: 14, fontWeight: FontWeight.w600, color: _kPrimary)),
          ],
        ),
        const SizedBox(height: 8),
        child,
      ],
    );
  }
}
