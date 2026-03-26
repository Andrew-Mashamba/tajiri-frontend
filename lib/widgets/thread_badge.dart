import 'package:flutter/material.dart';
import '../l10n/app_strings_scope.dart';

/// Small badge shown on PostCard when a post belongs to a gossip thread.
/// Tapping navigates to the thread via [onTap].
class ThreadBadge extends StatelessWidget {
  final int threadId;
  final String? threadTitle;
  final VoidCallback? onTap;

  const ThreadBadge({
    super.key,
    required this.threadId,
    this.threadTitle,
    this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final strings = AppStringsScope.of(context);
    return GestureDetector(
      onTap: onTap,
      child: Container(
        margin: const EdgeInsets.only(bottom: 8),
        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
        decoration: BoxDecoration(
          color: const Color(0xFFF5F5F5),
          borderRadius: BorderRadius.circular(8),
          border: Border.all(color: const Color(0xFFE0E0E0), width: 0.5),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Icon(
              Icons.local_fire_department_rounded,
              size: 14,
              color: Color(0xFF666666),
            ),
            const SizedBox(width: 6),
            Flexible(
              child: Text(
                threadTitle ?? strings?.partOfThread ?? 'Part of trending thread',
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: const TextStyle(
                  color: Color(0xFF666666),
                  fontSize: 12,
                  fontWeight: FontWeight.w500,
                ),
              ),
            ),
            const SizedBox(width: 4),
            const Icon(
              Icons.chevron_right_rounded,
              size: 14,
              color: Color(0xFF999999),
            ),
          ],
        ),
      ),
    );
  }
}
