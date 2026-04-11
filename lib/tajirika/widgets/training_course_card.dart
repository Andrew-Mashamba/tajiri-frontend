import 'package:flutter/material.dart';
import '../models/tajirika_models.dart';

class TrainingCourseCard extends StatelessWidget {
  final TrainingCourse course;
  final bool isSwahili;
  final VoidCallback? onTap;

  const TrainingCourseCard({
    super.key,
    required this.course,
    this.isSwahili = false,
    this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        margin: const EdgeInsets.only(bottom: 12),
        padding: const EdgeInsets.all(12),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: Colors.grey.shade200),
        ),
        child: Row(
          children: [
            ClipRRect(
              borderRadius: BorderRadius.circular(8),
              child: Container(
                width: 56,
                height: 56,
                color: Colors.grey.shade200,
                child: course.displayThumbnail.isNotEmpty
                    ? Image.network(
                        course.displayThumbnail,
                        fit: BoxFit.cover,
                        errorBuilder: (_, __, ___) =>
                            const Icon(Icons.play_circle_outline_rounded, color: Color(0xFF666666)),
                      )
                    : const Icon(Icons.play_circle_outline_rounded, color: Color(0xFF666666)),
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Expanded(
                        child: Text(
                          isSwahili && course.titleSwahili.isNotEmpty
                              ? course.titleSwahili
                              : course.title,
                          style: const TextStyle(
                            fontSize: 14,
                            fontWeight: FontWeight.w600,
                            color: Color(0xFF1A1A1A),
                          ),
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                        ),
                      ),
                      if (course.isRequired)
                        Container(
                          margin: const EdgeInsets.only(left: 6),
                          padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                          decoration: BoxDecoration(
                            color: const Color(0xFF1A1A1A),
                            borderRadius: BorderRadius.circular(4),
                          ),
                          child: Text(
                            isSwahili ? 'Lazima' : 'Required',
                            style: const TextStyle(color: Colors.white, fontSize: 9, fontWeight: FontWeight.w600),
                          ),
                        ),
                    ],
                  ),
                  const SizedBox(height: 4),
                  Text(
                    course.durationText,
                    style: const TextStyle(fontSize: 12, color: Color(0xFF666666)),
                  ),
                  if (course.progress > 0 && !course.isCompleted) ...[
                    const SizedBox(height: 6),
                    LinearProgressIndicator(
                      value: course.progress,
                      backgroundColor: Colors.grey.shade200,
                      valueColor: const AlwaysStoppedAnimation(Color(0xFF1A1A1A)),
                      minHeight: 3,
                      borderRadius: BorderRadius.circular(2),
                    ),
                  ],
                  if (course.isCompleted)
                    Padding(
                      padding: const EdgeInsets.only(top: 4),
                      child: Row(
                        children: [
                          const Icon(Icons.check_circle_rounded, size: 14, color: Color(0xFF4CAF50)),
                          const SizedBox(width: 4),
                          Text(
                            isSwahili ? 'Imekamilika' : 'Completed',
                            style: const TextStyle(fontSize: 11, color: Color(0xFF4CAF50), fontWeight: FontWeight.w500),
                          ),
                        ],
                      ),
                    ),
                ],
              ),
            ),
            const Icon(Icons.chevron_right_rounded, color: Color(0xFF9E9E9E)),
          ],
        ),
      ),
    );
  }
}
