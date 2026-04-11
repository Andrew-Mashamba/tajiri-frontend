// lib/barozi_wangu/widgets/issue_status_timeline.dart
import 'package:flutter/material.dart';
import '../models/barozi_wangu_models.dart';

const Color _kPrimary = Color(0xFF1A1A1A);
const Color _kSecondary = Color(0xFF666666);

/// Small colored dot representing issue status.
class IssueStatusDot extends StatelessWidget {
  final IssueStatus status;
  const IssueStatusDot({super.key, required this.status});

  @override
  Widget build(BuildContext context) {
    final color = switch (status) {
      IssueStatus.submitted => const Color(0xFFE53935),
      IssueStatus.acknowledged => const Color(0xFFFFA000),
      IssueStatus.inProgress => const Color(0xFF1E88E5),
      IssueStatus.resolved => const Color(0xFF4CAF50),
    };

    return Container(
      width: 10,
      height: 10,
      decoration: BoxDecoration(shape: BoxShape.circle, color: color),
    );
  }
}

/// Vertical timeline for issue status progression.
class IssueStatusTimeline extends StatelessWidget {
  final IssueStatus currentStatus;
  const IssueStatusTimeline({super.key, required this.currentStatus});

  @override
  Widget build(BuildContext context) {
    final steps = [
      ('Imewasilishwa', IssueStatus.submitted),
      ('Imepokewa', IssueStatus.acknowledged),
      ('Inafanyiwa kazi', IssueStatus.inProgress),
      ('Imekamilika', IssueStatus.resolved),
    ];

    return Column(
      children: List.generate(steps.length, (i) {
        final reached = currentStatus.index >= steps[i].$2.index;
        final isLast = i == steps.length - 1;

        return Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Column(
              children: [
                Container(
                  width: 14,
                  height: 14,
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    color: reached ? _kPrimary : const Color(0xFFDDDDDD),
                  ),
                  child: reached
                      ? const Icon(Icons.check_rounded, size: 10, color: Colors.white)
                      : null,
                ),
                if (!isLast)
                  Container(
                    width: 2,
                    height: 24,
                    color: reached ? _kPrimary : const Color(0xFFDDDDDD),
                  ),
              ],
            ),
            const SizedBox(width: 12),
            Padding(
              padding: const EdgeInsets.only(top: 0),
              child: Text(
                steps[i].$1,
                style: TextStyle(
                  fontSize: 13,
                  color: reached ? _kPrimary : _kSecondary,
                  fontWeight: reached ? FontWeight.w500 : FontWeight.normal,
                ),
              ),
            ),
          ],
        );
      }),
    );
  }
}
