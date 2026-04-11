import 'package:flutter/material.dart';
import '../models/committee.dart';

const Color _kPrimary = Color(0xFF1A1A1A);
const Color _kSecondary = Color(0xFF666666);

class CommitteeMemberCard extends StatelessWidget {
  final CommitteeMember member;
  final VoidCallback? onTap;
  final VoidCallback? onRemove;
  const CommitteeMemberCard({super.key, required this.member, this.onTap, this.onRemove});

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(10),
          border: Border.all(color: Colors.grey.shade200),
        ),
        child: Row(
          children: [
            Stack(
              children: [
                CircleAvatar(
                  radius: 20,
                  backgroundColor: Colors.grey.shade200,
                  backgroundImage: member.avatarUrl != null ? NetworkImage(member.avatarUrl!) : null,
                  child: member.avatarUrl == null
                      ? Text(member.firstName.isNotEmpty ? member.firstName[0] : '?', style: const TextStyle(color: _kSecondary, fontWeight: FontWeight.w600))
                      : null,
                ),
                if (member.isOnline)
                  Positioned(
                    right: 0, bottom: 0,
                    child: Container(
                      width: 12, height: 12,
                      decoration: BoxDecoration(
                        color: Colors.green,
                        shape: BoxShape.circle,
                        border: Border.all(color: Colors.white, width: 2),
                      ),
                    ),
                  ),
              ],
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(member.fullName, style: const TextStyle(fontSize: 14, fontWeight: FontWeight.w600, color: _kPrimary)),
                  if (member.username != null)
                    Text('@${member.username}', style: const TextStyle(fontSize: 12, color: _kSecondary)),
                ],
              ),
            ),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
              decoration: BoxDecoration(
                color: member.role == CommitteeRole.mwenyekiti ? _kPrimary : Colors.grey.shade100,
                borderRadius: BorderRadius.circular(8),
              ),
              child: Text(
                member.role.displayName,
                style: TextStyle(fontSize: 11, fontWeight: FontWeight.w600, color: member.role == CommitteeRole.mwenyekiti ? Colors.white : _kSecondary),
              ),
            ),
            if (onRemove != null) ...[
              const SizedBox(width: 8),
              GestureDetector(onTap: onRemove, child: Icon(Icons.close_rounded, size: 18, color: Colors.grey.shade400)),
            ],
          ],
        ),
      ),
    );
  }
}
