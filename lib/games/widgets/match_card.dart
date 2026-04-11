// lib/games/widgets/match_card.dart
import 'package:flutter/material.dart';
import '../models/game_session.dart';
import '../core/game_registry.dart';

const Color _kPrimary = Color(0xFF1A1A1A);
const Color _kSecondary = Color(0xFF666666);

/// Card for an active or recent match.
class MatchCard extends StatelessWidget {
  final GameSession session;
  final int currentUserId;
  final VoidCallback? onTap;

  const MatchCard({
    super.key,
    required this.session,
    required this.currentUserId,
    this.onTap,
  });

  String _timeAgo(DateTime dt) {
    final diff = DateTime.now().difference(dt);
    if (diff.inSeconds < 60) return 'just now';
    if (diff.inMinutes < 60) return '${diff.inMinutes}m ago';
    if (diff.inHours < 24) return '${diff.inHours}h ago';
    if (diff.inDays < 7) return '${diff.inDays}d ago';
    return '${dt.day}/${dt.month}/${dt.year}';
  }

  @override
  Widget build(BuildContext context) {
    final gameDef = GameRegistry.instance.get(session.gameId);
    final gameName = gameDef?.name ?? session.gameId;
    final gameIcon = gameDef?.icon ?? Icons.sports_esports_rounded;
    final opponentName = session.player2Id != null ? 'Opponent' : 'Waiting...';

    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.all(14),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: Colors.grey.shade200),
        ),
        child: Row(
          children: [
            // Game icon
            Container(
              width: 40,
              height: 40,
              decoration: BoxDecoration(
                color: _kPrimary.withValues(alpha: 0.06),
                borderRadius: BorderRadius.circular(10),
              ),
              child: Icon(gameIcon, size: 20, color: _kPrimary),
            ),
            const SizedBox(width: 12),

            // Game name + opponent
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    gameName,
                    style: const TextStyle(
                      fontSize: 14,
                      fontWeight: FontWeight.w600,
                      color: _kPrimary,
                    ),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                  const SizedBox(height: 2),
                  Text(
                    'vs $opponentName',
                    style: const TextStyle(fontSize: 12, color: _kSecondary),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                ],
              ),
            ),

            // Status + score / time
            Column(
              crossAxisAlignment: CrossAxisAlignment.end,
              children: [
                // Status badge
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                  decoration: BoxDecoration(
                    color: session.status.color.withValues(alpha: 0.12),
                    borderRadius: BorderRadius.circular(6),
                  ),
                  child: Text(
                    session.status.displayName,
                    style: TextStyle(
                      fontSize: 11,
                      fontWeight: FontWeight.w600,
                      color: session.status.color,
                    ),
                  ),
                ),
                const SizedBox(height: 4),

                // Score or time
                if (session.isCompleted)
                  Text(
                    '${session.myScore(currentUserId)} - ${session.opponentScore(currentUserId)}',
                    style: const TextStyle(
                      fontSize: 13,
                      fontWeight: FontWeight.w600,
                      color: _kPrimary,
                    ),
                  )
                else
                  Text(
                    _timeAgo(session.createdAt),
                    style: const TextStyle(fontSize: 11, color: _kSecondary),
                  ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}
