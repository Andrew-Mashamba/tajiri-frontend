// lib/games/widgets/leaderboard_tile.dart
import 'package:flutter/material.dart';
import '../models/leaderboard_entry.dart';

const Color _kPrimary = Color(0xFF1A1A1A);
const Color _kSecondary = Color(0xFF666666);

/// Single row in a leaderboard list.
/// Gold/silver/bronze medals for top 3, numbers for the rest.
class LeaderboardTile extends StatelessWidget {
  final LeaderboardEntry entry;
  final bool isCurrentUser;

  const LeaderboardTile({
    super.key,
    required this.entry,
    this.isCurrentUser = false,
  });

  Widget _buildRank() {
    if (entry.rank == 1) {
      return const Icon(Icons.emoji_events_rounded, size: 22, color: Color(0xFFFFD700));
    }
    if (entry.rank == 2) {
      return const Icon(Icons.emoji_events_rounded, size: 22, color: Color(0xFFC0C0C0));
    }
    if (entry.rank == 3) {
      return const Icon(Icons.emoji_events_rounded, size: 22, color: Color(0xFFCD7F32));
    }
    return Text(
      '#${entry.rank}',
      style: const TextStyle(
        fontSize: 14,
        fontWeight: FontWeight.w600,
        color: _kSecondary,
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
      decoration: BoxDecoration(
        color: isCurrentUser ? _kPrimary.withValues(alpha: 0.04) : Colors.white,
        borderRadius: BorderRadius.circular(10),
        border: Border.all(
          color: isCurrentUser ? _kPrimary.withValues(alpha: 0.2) : Colors.grey.shade200,
        ),
      ),
      child: Row(
        children: [
          // Rank
          SizedBox(width: 32, child: Center(child: _buildRank())),
          const SizedBox(width: 10),

          // Avatar
          CircleAvatar(
            radius: 18,
            backgroundColor: Colors.grey.shade200,
            backgroundImage:
                entry.avatar != null ? NetworkImage(entry.avatar!) : null,
            child: entry.avatar == null
                ? Text(
                    entry.userName.isNotEmpty
                        ? entry.userName[0].toUpperCase()
                        : '?',
                    style: const TextStyle(
                      fontSize: 14,
                      fontWeight: FontWeight.w600,
                      color: _kPrimary,
                    ),
                  )
                : null,
          ),
          const SizedBox(width: 12),

          // Name + record
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  entry.userName,
                  style: TextStyle(
                    fontSize: 14,
                    fontWeight: isCurrentUser ? FontWeight.w700 : FontWeight.w500,
                    color: _kPrimary,
                  ),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
                const SizedBox(height: 1),
                Text(
                  entry.record,
                  style: const TextStyle(fontSize: 12, color: _kSecondary),
                ),
              ],
            ),
          ),

          // ELO rating
          Column(
            crossAxisAlignment: CrossAxisAlignment.end,
            children: [
              Text(
                '${entry.eloRating}',
                style: const TextStyle(
                  fontSize: 15,
                  fontWeight: FontWeight.w700,
                  color: _kPrimary,
                ),
              ),
              const Text(
                'ELO',
                style: TextStyle(fontSize: 10, color: _kSecondary),
              ),
            ],
          ),
        ],
      ),
    );
  }
}
