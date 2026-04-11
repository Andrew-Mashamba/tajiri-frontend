// lib/my_family/widgets/member_avatar.dart
import 'package:flutter/material.dart';
import '../models/my_family_models.dart';

const Color _kPrimary = Color(0xFF1A1A1A);
const Color _kSecondary = Color(0xFF666666);

class MemberAvatar extends StatelessWidget {
  final FamilyMember member;
  final double size;
  final bool showLabel;
  final bool showRelationship;
  final VoidCallback? onTap;

  const MemberAvatar({
    super.key,
    required this.member,
    this.size = 56,
    this.showLabel = true,
    this.showRelationship = true,
    this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: SizedBox(
        width: size + 16,
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Stack(
              children: [
                Container(
                  width: size,
                  height: size,
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    color: _kPrimary.withValues(alpha: 0.08),
                    border: Border.all(
                      color: member.isLinked
                          ? _kPrimary
                          : _kPrimary.withValues(alpha: 0.15),
                      width: member.isLinked ? 2 : 1,
                    ),
                  ),
                  child: member.photoUrl != null && member.photoUrl!.isNotEmpty
                      ? ClipOval(
                          child: Image.network(
                            member.photoUrl!,
                            fit: BoxFit.cover,
                            width: size,
                            height: size,
                            errorBuilder: (c, e, s) => _buildInitials(),
                          ),
                        )
                      : _buildInitials(),
                ),
                if (member.isLinked)
                  Positioned(
                    bottom: 0,
                    right: 0,
                    child: Container(
                      width: 18,
                      height: 18,
                      decoration: BoxDecoration(
                        color: const Color(0xFF4CAF50),
                        shape: BoxShape.circle,
                        border: Border.all(color: Colors.white, width: 2),
                      ),
                      child: const Icon(
                        Icons.check_rounded,
                        size: 10,
                        color: Colors.white,
                      ),
                    ),
                  ),
              ],
            ),
            if (showLabel) ...[
              const SizedBox(height: 6),
              Text(
                member.name.split(' ').first,
                style: const TextStyle(
                  fontSize: 11,
                  fontWeight: FontWeight.w600,
                  color: _kPrimary,
                ),
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                textAlign: TextAlign.center,
              ),
            ],
            if (showRelationship) ...[
              const SizedBox(height: 1),
              Text(
                member.relationship.displayName,
                style: const TextStyle(fontSize: 9, color: _kSecondary),
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                textAlign: TextAlign.center,
              ),
            ],
          ],
        ),
      ),
    );
  }

  Widget _buildInitials() {
    return Center(
      child: Text(
        member.initials,
        style: TextStyle(
          fontSize: size * 0.35,
          fontWeight: FontWeight.w700,
          color: _kPrimary,
        ),
      ),
    );
  }
}

/// Compact avatar used in list rows (no label)
class MemberAvatarSmall extends StatelessWidget {
  final FamilyMember member;
  final double size;

  const MemberAvatarSmall({
    super.key,
    required this.member,
    this.size = 36,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      width: size,
      height: size,
      decoration: BoxDecoration(
        shape: BoxShape.circle,
        color: _kPrimary.withValues(alpha: 0.08),
      ),
      child: member.photoUrl != null && member.photoUrl!.isNotEmpty
          ? ClipOval(
              child: Image.network(
                member.photoUrl!,
                fit: BoxFit.cover,
                width: size,
                height: size,
                errorBuilder: (c, e, s) => Center(
                  child: Text(
                    member.initials,
                    style: TextStyle(
                      fontSize: size * 0.35,
                      fontWeight: FontWeight.w700,
                      color: _kPrimary,
                    ),
                  ),
                ),
              ),
            )
          : Center(
              child: Text(
                member.initials,
                style: TextStyle(
                  fontSize: size * 0.35,
                  fontWeight: FontWeight.w700,
                  color: _kPrimary,
                ),
              ),
            ),
    );
  }
}
