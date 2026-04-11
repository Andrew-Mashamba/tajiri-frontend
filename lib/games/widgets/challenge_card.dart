// lib/games/widgets/challenge_card.dart
import 'package:flutter/material.dart';
import '../models/challenge.dart';
import '../core/game_registry.dart';

const Color _kPrimary = Color(0xFF1A1A1A);
const Color _kSecondary = Color(0xFF666666);

/// Card displaying a pending challenge from another player.
class ChallengeCard extends StatelessWidget {
  final Challenge challenge;
  final VoidCallback? onAccept;
  final VoidCallback? onDecline;

  const ChallengeCard({
    super.key,
    required this.challenge,
    this.onAccept,
    this.onDecline,
  });

  @override
  Widget build(BuildContext context) {
    final gameDef = GameRegistry.instance.get(challenge.gameId);
    final gameName = gameDef?.name ?? challenge.gameId;

    return Container(
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
              // Challenger avatar
              CircleAvatar(
                radius: 20,
                backgroundColor: Colors.grey.shade200,
                backgroundImage: challenge.challengerAvatar != null
                    ? NetworkImage(challenge.challengerAvatar!)
                    : null,
                child: challenge.challengerAvatar == null
                    ? Text(
                        challenge.challengerName.isNotEmpty
                            ? challenge.challengerName[0].toUpperCase()
                            : '?',
                        style: const TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.w600,
                          color: _kPrimary,
                        ),
                      )
                    : null,
              ),
              const SizedBox(width: 12),

              // Challenge text
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    RichText(
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                      text: TextSpan(
                        style: const TextStyle(fontSize: 14, color: _kPrimary),
                        children: [
                          TextSpan(
                            text: challenge.challengerName,
                            style: const TextStyle(fontWeight: FontWeight.w600),
                          ),
                          const TextSpan(text: ' challenged you!'),
                        ],
                      ),
                    ),
                    const SizedBox(height: 2),
                    Text(
                      gameName,
                      style: const TextStyle(fontSize: 12, color: _kSecondary),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                  ],
                ),
              ),
            ],
          ),

          // Stake amount (if any)
          if (challenge.hasStake) ...[
            const SizedBox(height: 10),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
              decoration: BoxDecoration(
                color: _kPrimary.withValues(alpha: 0.06),
                borderRadius: BorderRadius.circular(8),
              ),
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  const Icon(Icons.account_balance_wallet_rounded, size: 14, color: _kPrimary),
                  const SizedBox(width: 6),
                  Text(
                    'Stake: ${challenge.stakeDisplay}',
                    style: const TextStyle(
                      fontSize: 12,
                      fontWeight: FontWeight.w600,
                      color: _kPrimary,
                    ),
                  ),
                ],
              ),
            ),
          ],

          const SizedBox(height: 12),

          // Accept / Decline buttons
          Row(
            children: [
              Expanded(
                child: SizedBox(
                  height: 40,
                  child: OutlinedButton(
                    onPressed: onDecline,
                    style: OutlinedButton.styleFrom(
                      foregroundColor: _kSecondary,
                      side: BorderSide(color: Colors.grey.shade300),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(10),
                      ),
                    ),
                    child: const Text(
                      'Decline',
                      style: TextStyle(fontSize: 13, fontWeight: FontWeight.w500),
                    ),
                  ),
                ),
              ),
              const SizedBox(width: 10),
              Expanded(
                child: SizedBox(
                  height: 40,
                  child: ElevatedButton(
                    onPressed: onAccept,
                    style: ElevatedButton.styleFrom(
                      backgroundColor: _kPrimary,
                      foregroundColor: Colors.white,
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(10),
                      ),
                      elevation: 0,
                    ),
                    child: const Text(
                      'Accept',
                      style: TextStyle(fontSize: 13, fontWeight: FontWeight.w600),
                    ),
                  ),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}
