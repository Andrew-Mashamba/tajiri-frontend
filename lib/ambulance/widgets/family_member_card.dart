// lib/ambulance/widgets/family_member_card.dart
import 'package:flutter/material.dart';
import '../models/ambulance_models.dart';

const Color _kPrimary = Color(0xFF1A1A1A);
const Color _kSecondary = Color(0xFF666666);
const Color _kRed = Color(0xFFCC0000);

class FamilyMemberCard extends StatelessWidget {
  final FamilyProfile member;
  final VoidCallback? onTap;
  final VoidCallback? onDelete;
  final bool isSwahili;

  const FamilyMemberCard({
    super.key,
    required this.member,
    this.onTap,
    this.onDelete,
    this.isSwahili = false,
  });

  @override
  Widget build(BuildContext context) {
    return Material(
      color: Colors.white,
      borderRadius: BorderRadius.circular(12),
      child: InkWell(
        borderRadius: BorderRadius.circular(12),
        onTap: onTap,
        child: Padding(
          padding: const EdgeInsets.all(14),
          child: Row(
            children: [
              CircleAvatar(
                radius: 24,
                backgroundColor: const Color(0xFFE8E8E8),
                child: Text(
                  member.name.isNotEmpty
                      ? member.name[0].toUpperCase()
                      : '?',
                  style: const TextStyle(
                      color: _kPrimary,
                      fontWeight: FontWeight.w600,
                      fontSize: 18),
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      member.name,
                      style: const TextStyle(
                          fontSize: 14,
                          fontWeight: FontWeight.w500,
                          color: _kPrimary),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                    const SizedBox(height: 2),
                    Text(
                      member.relationship,
                      style:
                          const TextStyle(fontSize: 12, color: _kSecondary),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                    if (member.allergies.isNotEmpty ||
                        member.conditions.isNotEmpty)
                      Padding(
                        padding: const EdgeInsets.only(top: 4),
                        child: Text(
                          '${isSwahili ? 'Mzio' : 'Allergies'}: ${member.allergies.length} | ${isSwahili ? 'Hali' : 'Conditions'}: ${member.conditions.length}',
                          style: const TextStyle(
                              fontSize: 11, color: _kSecondary),
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                        ),
                      ),
                  ],
                ),
              ),
              if (member.bloodType != null)
                Container(
                  padding:
                      const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                  decoration: BoxDecoration(
                    color: _kRed.withValues(alpha: 0.1),
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Text(
                    member.bloodType!,
                    style: const TextStyle(
                        fontSize: 14,
                        fontWeight: FontWeight.w800,
                        color: _kRed),
                  ),
                ),
              if (onDelete != null) ...[
                const SizedBox(width: 8),
                SizedBox(
                  width: 48,
                  height: 48,
                  child: IconButton(
                    onPressed: onDelete,
                    icon: const Icon(Icons.delete_outline_rounded,
                        color: _kSecondary, size: 22),
                  ),
                ),
              ],
            ],
          ),
        ),
      ),
    );
  }
}
