// lib/games/widgets/player_banner.dart
import 'package:flutter/material.dart';

const Color _kPrimary = Color(0xFF1A1A1A);

/// Compact horizontal bar showing player info during gameplay.
/// Avatar (32px) + name + score.
class PlayerBanner extends StatelessWidget {
  final String name;
  final String? avatar;
  final int score;
  final bool isCurrentUser;

  const PlayerBanner({
    super.key,
    required this.name,
    this.avatar,
    this.score = 0,
    this.isCurrentUser = false,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
      decoration: BoxDecoration(
        color: isCurrentUser
            ? _kPrimary.withValues(alpha: 0.06)
            : Colors.transparent,
        borderRadius: BorderRadius.circular(10),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          CircleAvatar(
            radius: 16,
            backgroundColor: Colors.grey.shade200,
            backgroundImage:
                avatar != null ? NetworkImage(avatar!) : null,
            child: avatar == null
                ? Text(
                    name.isNotEmpty ? name[0].toUpperCase() : '?',
                    style: const TextStyle(
                      fontSize: 12,
                      fontWeight: FontWeight.w600,
                      color: _kPrimary,
                    ),
                  )
                : null,
          ),
          const SizedBox(width: 8),
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            mainAxisSize: MainAxisSize.min,
            children: [
              Text(
                name,
                style: TextStyle(
                  fontSize: 12,
                  fontWeight: isCurrentUser ? FontWeight.w600 : FontWeight.w500,
                  color: _kPrimary,
                ),
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
              ),
              Text(
                '$score',
                style: const TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.w700,
                  color: _kPrimary,
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}
