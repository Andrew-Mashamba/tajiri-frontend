import 'package:flutter/material.dart';
import '../models/flywheel_models.dart';
import '../l10n/app_strings_scope.dart';

class PostingNudgeCard extends StatelessWidget {
  final PostingNudge nudge;
  final VoidCallback? onDismiss;
  final VoidCallback? onCreatePost;

  const PostingNudgeCard({
    super.key,
    required this.nudge,
    this.onDismiss,
    this.onCreatePost,
  });

  IconData get _icon {
    switch (nudge.nudgeType) {
      case 'peak_hour':
        return Icons.schedule_rounded;
      case 'streak_warning':
        return Icons.local_fire_department_rounded;
      case 'consistency':
        return Icons.trending_up_rounded;
      default:
        return Icons.lightbulb_outline_rounded;
    }
  }

  @override
  Widget build(BuildContext context) {
    final strings = AppStringsScope.of(context);
    final isSwahili = strings?.isSwahili ?? false;
    final message = isSwahili ? nudge.messageSwahili : nudge.message;

    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 6),
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: const Color(0xFF1A1A1A),
        borderRadius: BorderRadius.circular(16),
      ),
      child: Row(
        children: [
          Icon(_icon, color: Colors.white70, size: 20),
          const SizedBox(width: 12),
          Expanded(
            child: Text(
              message,
              style: const TextStyle(
                color: Colors.white,
                fontSize: 13,
                fontWeight: FontWeight.w500,
                height: 1.3,
              ),
              maxLines: 2,
              overflow: TextOverflow.ellipsis,
            ),
          ),
          const SizedBox(width: 8),
          GestureDetector(
            onTap: onCreatePost,
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(20),
              ),
              child: Text(
                isSwahili ? 'Chapisha' : 'Post',
                style: const TextStyle(
                  color: Color(0xFF1A1A1A),
                  fontSize: 12,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ),
          ),
          const SizedBox(width: 4),
          GestureDetector(
            onTap: onDismiss,
            child: const Padding(
              padding: EdgeInsets.all(4),
              child: Icon(Icons.close, color: Colors.white54, size: 16),
            ),
          ),
        ],
      ),
    );
  }
}
