// lib/study_groups/widgets/study_group_card.dart
import 'package:flutter/material.dart';
import '../models/study_groups_models.dart';

const Color _kPrimary = Color(0xFF1A1A1A);
const Color _kSecondary = Color(0xFF666666);

class StudyGroupCard extends StatelessWidget {
  final StudyGroup group;
  final VoidCallback? onTap;
  final VoidCallback? onJoin;
  final bool showJoin;
  const StudyGroupCard({super.key, required this.group, this.onTap, this.onJoin, this.showJoin = false});

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.all(14),
        decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(12), border: Border.all(color: Colors.grey.shade200)),
        child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
          Row(children: [
            Container(
              width: 44, height: 44,
              decoration: BoxDecoration(color: _kPrimary.withValues(alpha: 0.08), borderRadius: BorderRadius.circular(10)),
              child: const Icon(Icons.groups_rounded, color: _kPrimary, size: 22),
            ),
            const SizedBox(width: 12),
            Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
              Text(group.name, style: const TextStyle(fontSize: 14, fontWeight: FontWeight.w600, color: _kPrimary), maxLines: 1, overflow: TextOverflow.ellipsis),
              Text(group.subject, style: const TextStyle(fontSize: 12, color: _kSecondary), maxLines: 1, overflow: TextOverflow.ellipsis),
            ])),
            if (showJoin && !group.isFull) GestureDetector(
              onTap: onJoin,
              child: Container(
                padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                decoration: BoxDecoration(color: _kPrimary, borderRadius: BorderRadius.circular(8)),
                child: const Text('Jiunge', style: TextStyle(fontSize: 12, color: Colors.white, fontWeight: FontWeight.w600)),
              ),
            ),
          ]),
          const SizedBox(height: 10),
          Row(children: [
            const Icon(Icons.people_rounded, size: 14, color: _kSecondary), const SizedBox(width: 4),
            Text('${group.memberCount}/${group.maxMembers}', style: const TextStyle(fontSize: 12, color: _kSecondary)),
            const SizedBox(width: 14),
            if (group.streak > 0) ...[
              const Icon(Icons.local_fire_department_rounded, size: 14, color: Colors.orange), const SizedBox(width: 4),
              Text('${group.streak} siku', style: const TextStyle(fontSize: 12, color: _kSecondary)),
              const SizedBox(width: 14),
            ],
            const Icon(Icons.event_rounded, size: 14, color: _kSecondary), const SizedBox(width: 4),
            Text('${group.totalSessions} vikao', style: const TextStyle(fontSize: 12, color: _kSecondary)),
            const Spacer(),
            if (group.isFull) Container(
              padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
              decoration: BoxDecoration(color: Colors.red.shade50, borderRadius: BorderRadius.circular(4)),
              child: const Text('Imejaa', style: TextStyle(fontSize: 10, color: Colors.red)),
            ),
          ]),
        ]),
      ),
    );
  }
}
