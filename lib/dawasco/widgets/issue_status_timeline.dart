// lib/dawasco/widgets/issue_status_timeline.dart
import 'package:flutter/material.dart';

const Color _kPrimary = Color(0xFF1A1A1A);
const Color _kSecondary = Color(0xFF666666);
const Color _kGreen = Color(0xFF4CAF50);

class IssueStatusTimeline extends StatelessWidget {
  final String currentStatus; // reported, acknowledged, dispatched, fixed
  final bool isSwahili;
  const IssueStatusTimeline({super.key, required this.currentStatus, this.isSwahili = false});

  @override
  Widget build(BuildContext context) {
    final steps = [
      _Step('reported', isSwahili ? 'Imeripotiwa' : 'Reported', Icons.flag_rounded),
      _Step('acknowledged', isSwahili ? 'Imethibitishwa' : 'Acknowledged', Icons.check_circle_outline_rounded),
      _Step('dispatched', isSwahili ? 'Timu Imetumwa' : 'Crew Dispatched', Icons.engineering_rounded),
      _Step('fixed', isSwahili ? 'Imerekebishwa' : 'Fixed', Icons.done_all_rounded),
    ];

    final currentIdx = steps.indexWhere((s) => s.key == currentStatus);
    final activeIdx = currentIdx >= 0 ? currentIdx : 0;

    return Row(
      children: List.generate(steps.length * 2 - 1, (i) {
        if (i.isOdd) {
          final beforeIdx = i ~/ 2;
          final isActive = beforeIdx < activeIdx;
          return Expanded(
            child: Container(
              height: 2,
              color: isActive ? _kGreen : _kPrimary.withValues(alpha: 0.15),
            ),
          );
        }
        final stepIdx = i ~/ 2;
        final step = steps[stepIdx];
        final isDone = stepIdx <= activeIdx;
        final isCurrent = stepIdx == activeIdx;
        final color = isDone ? _kGreen : _kPrimary.withValues(alpha: 0.3);

        return Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              width: 32, height: 32,
              decoration: BoxDecoration(
                color: isDone ? _kGreen.withValues(alpha: 0.15) : _kPrimary.withValues(alpha: 0.06),
                shape: BoxShape.circle,
                border: isCurrent ? Border.all(color: _kGreen, width: 2) : null,
              ),
              child: Icon(step.icon, size: 16, color: color),
            ),
            const SizedBox(height: 4),
            Text(step.label, style: TextStyle(fontSize: 9, fontWeight: FontWeight.w500, color: isDone ? _kPrimary : _kSecondary),
                textAlign: TextAlign.center, maxLines: 1, overflow: TextOverflow.ellipsis),
          ],
        );
      }),
    );
  }
}

class _Step {
  final String key;
  final String label;
  final IconData icon;
  const _Step(this.key, this.label, this.icon);
}
