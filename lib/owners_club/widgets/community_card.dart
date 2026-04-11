// lib/owners_club/widgets/community_card.dart
import 'package:flutter/material.dart';
import '../models/owners_club_models.dart';

const Color _kPrimary = Color(0xFF1A1A1A);
const Color _kSecondary = Color(0xFF666666);

class CommunityCard extends StatelessWidget {
  final Community community;
  final VoidCallback? onTap;

  const CommunityCard({super.key, required this.community, this.onTap});

  @override
  Widget build(BuildContext context) {
    return Material(
      color: Colors.white,
      borderRadius: BorderRadius.circular(12),
      child: InkWell(
        borderRadius: BorderRadius.circular(12),
        onTap: onTap,
        child: Padding(
          padding: const EdgeInsets.all(12),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              CircleAvatar(
                radius: 24,
                backgroundColor: const Color(0xFFE8E8E8),
                backgroundImage:
                    community.logoUrl != null ? NetworkImage(community.logoUrl!) : null,
                child: community.logoUrl == null
                    ? Text(
                        community.name.isNotEmpty ? community.name[0] : '?',
                        style: const TextStyle(
                            fontSize: 18, fontWeight: FontWeight.w700, color: _kPrimary),
                      )
                    : null,
              ),
              const SizedBox(height: 8),
              Text(community.name,
                  style: const TextStyle(fontSize: 12, fontWeight: FontWeight.w600, color: _kPrimary),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  textAlign: TextAlign.center),
              const SizedBox(height: 2),
              Text('${community.memberCount}',
                  style: const TextStyle(fontSize: 11, color: _kSecondary)),
            ],
          ),
        ),
      ),
    );
  }
}
