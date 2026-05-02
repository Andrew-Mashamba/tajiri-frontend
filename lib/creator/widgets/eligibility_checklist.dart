// Eligibility checklist — done / todo rules for a locked source.
// Spec §5 (locked variant): rules with current/target values rendered as a
// numbered checklist.

import 'package:flutter/material.dart';
import '../models/income_source.dart';

class EligibilityChecklist extends StatelessWidget {
  final List<EligibilityRule> rules;
  const EligibilityChecklist({super.key, required this.rules});

  @override
  Widget build(BuildContext context) {
    var todoCounter = 0;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        for (final rule in rules) ...[
          _ChecklistRow(
            rule: rule,
            todoNumber: rule.done ? null : (++todoCounter),
          ),
          if (rule != rules.last) const SizedBox(height: 4),
        ],
      ],
    );
  }
}

class _ChecklistRow extends StatelessWidget {
  final EligibilityRule rule;
  final int? todoNumber;
  const _ChecklistRow({required this.rule, this.todoNumber});

  @override
  Widget build(BuildContext context) {
    final small = _smallText(context);
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 6),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _Mark(done: rule.done, todoNumber: todoNumber),
          const SizedBox(width: 8),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisSize: MainAxisSize.min,
              children: [
                Text(
                  rule.label.forContext(context),
                  style: const TextStyle(
                    fontSize: 12,
                    color: Color(0xFF1A1A1A),
                  ),
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                ),
                if (small != null) ...[
                  const SizedBox(height: 2),
                  Text(
                    small,
                    style: const TextStyle(
                      fontSize: 10,
                      color: Color(0xFF666666),
                    ),
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                  ),
                ],
              ],
            ),
          ),
        ],
      ),
    );
  }

  String? _smallText(BuildContext context) {
    if (rule.done && rule.completedAt != null) {
      final d = rule.completedAt!;
      return '${d.day.toString().padLeft(2, '0')}/${d.month.toString().padLeft(2, '0')}/${d.year}';
    }
    if (!rule.done && rule.currentValue != null && rule.targetValue != null) {
      final remaining = rule.targetValue! - rule.currentValue!;
      return '${rule.currentValue} / ${rule.targetValue} · ${remaining > 0 ? "+$remaining" : ""}';
    }
    if (!rule.done && rule.blockingReason != null) {
      return rule.blockingReason;
    }
    return null;
  }
}

class _Mark extends StatelessWidget {
  final bool done;
  final int? todoNumber;
  const _Mark({required this.done, this.todoNumber});

  @override
  Widget build(BuildContext context) {
    if (done) {
      return Container(
        width: 18,
        height: 18,
        decoration: const BoxDecoration(
          color: Color(0xFF1A1A1A),
          shape: BoxShape.circle,
        ),
        alignment: Alignment.center,
        child: const Icon(
          Icons.check_rounded,
          size: 12,
          color: Color(0xFFFAFAFA),
        ),
      );
    }
    return Container(
      width: 18,
      height: 18,
      decoration: BoxDecoration(
        color: Colors.white,
        shape: BoxShape.circle,
        border: Border.all(color: const Color(0xFF999999), width: 1.5),
      ),
      alignment: Alignment.center,
      child: Text(
        todoNumber?.toString() ?? '·',
        style: const TextStyle(
          fontSize: 11,
          fontWeight: FontWeight.w600,
          color: Color(0xFF666666),
          height: 1,
        ),
      ),
    );
  }
}
