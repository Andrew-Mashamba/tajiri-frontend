// lib/jumuiya/widgets/jumuiya_card.dart
import 'package:flutter/material.dart';
import '../models/jumuiya_models.dart';

const Color _kPrimary = Color(0xFF1A1A1A);
const Color _kSecondary = Color(0xFF666666);

class JumuiyaCard extends StatelessWidget {
  final JumuiyaGroup group;
  final VoidCallback? onTap;
  final VoidCallback? onJoin;
  final bool showJoinButton;

  const JumuiyaCard({
    super.key,
    required this.group,
    this.onTap,
    this.onJoin,
    this.showJoinButton = false,
  });

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
                    color: Colors.grey.shade100,
                    borderRadius: BorderRadius.circular(10),
                  ),
                  child: const Icon(Icons.groups_rounded, size: 22, color: _kPrimary),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(group.name,
                          style: const TextStyle(fontSize: 15, fontWeight: FontWeight.w600, color: _kPrimary),
                          maxLines: 1, overflow: TextOverflow.ellipsis),
                      if (group.churchName != null)
                        Text(group.churchName!,
                            style: const TextStyle(fontSize: 12, color: _kSecondary),
                            maxLines: 1, overflow: TextOverflow.ellipsis),
                    ],
                  ),
                ),
                if (showJoinButton)
                  GestureDetector(
                    onTap: onJoin,
                    child: Container(
                      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                      decoration: BoxDecoration(
                        color: _kPrimary,
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: const Text('Jiunge / Join',
                          style: TextStyle(color: Colors.white, fontSize: 12, fontWeight: FontWeight.w600)),
                    ),
                  ),
              ],
            ),
            const SizedBox(height: 10),
            Row(
              children: [
                Icon(Icons.people_rounded, size: 14, color: Colors.grey.shade400),
                const SizedBox(width: 4),
                Text('${group.memberCount} wanachama / members',
                    style: const TextStyle(fontSize: 12, color: _kSecondary)),
                if (group.meetingDay != null) ...[
                  const SizedBox(width: 14),
                  Icon(Icons.schedule_rounded, size: 14, color: Colors.grey.shade400),
                  const SizedBox(width: 4),
                  Text(group.meetingDay!,
                      style: const TextStyle(fontSize: 12, color: _kSecondary)),
                ],
              ],
            ),
          ],
        ),
      ),
    );
  }
}
