// lib/tra/widgets/deadline_tile.dart
import 'package:flutter/material.dart';
import '../models/tra_models.dart';

const Color _kPrimary = Color(0xFF1A1A1A);
const Color _kSecondary = Color(0xFF666666);

class DeadlineTile extends StatelessWidget {
  final TaxDeadline deadline;
  final VoidCallback? onTap;
  const DeadlineTile({super.key, required this.deadline, this.onTap});

  Color get _color {
    switch (deadline.status) {
      case 'overdue': return Colors.red;
      case 'due': return Colors.orange;
      case 'filed': return const Color(0xFF4CAF50);
      default: return _kSecondary;
    }
  }

  @override
  Widget build(BuildContext context) {
    return Material(
      color: Colors.white, borderRadius: BorderRadius.circular(12),
      child: InkWell(
        onTap: onTap, borderRadius: BorderRadius.circular(12),
        child: Padding(
          padding: const EdgeInsets.all(14),
          child: Row(children: [
            Container(
              width: 8, height: 40,
              decoration: BoxDecoration(
                color: _color, borderRadius: BorderRadius.circular(4)),
            ),
            const SizedBox(width: 12),
            Expanded(child: Column(
                crossAxisAlignment: CrossAxisAlignment.start, children: [
              Text(deadline.taxType, style: const TextStyle(fontSize: 13,
                  fontWeight: FontWeight.w600, color: _kPrimary),
                  maxLines: 1, overflow: TextOverflow.ellipsis),
              Text(deadline.period, style: const TextStyle(fontSize: 11, color: _kSecondary)),
            ])),
            Text('${deadline.dueDate.day}/${deadline.dueDate.month}',
                style: const TextStyle(fontSize: 12, fontWeight: FontWeight.w600, color: _kPrimary)),
          ]),
        ),
      ),
    );
  }
}
