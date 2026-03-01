/// Battle Mode (PK Battle) UI Overlay - Real-time Competition Display
/// Shows both streamers' scores, progress bars, and battle status
import 'dart:async';
import 'package:flutter/material.dart';
import '../services/battle_mode_service.dart';

class BattleModeOverlay extends StatefulWidget {
  final BattleState battleState;
  final String myName;
  final int currentUserId;
  final VoidCallback? onForfeit;

  const BattleModeOverlay({
    super.key,
    required this.battleState,
    required this.myName,
    required this.currentUserId,
    this.onForfeit,
  });

  @override
  State<BattleModeOverlay> createState() => _BattleModeOverlayState();
}

class _BattleModeOverlayState extends State<BattleModeOverlay>
    with TickerProviderStateMixin {
  late AnimationController _scoreAnimationController;
  late AnimationController _pulseAnimationController;
  Timer? _durationTimer;
  Duration _battleDuration = Duration.zero;

  @override
  void initState() {
    super.initState();

    _scoreAnimationController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 500),
    );

    _pulseAnimationController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1000),
    )..repeat(reverse: true);

    _startDurationTimer();
  }

  @override
  void dispose() {
    _scoreAnimationController.dispose();
    _pulseAnimationController.dispose();
    _durationTimer?.cancel();
    super.dispose();
  }

  void _startDurationTimer() {
    if (widget.battleState.startTime == null) return;

    _durationTimer = Timer.periodic(const Duration(seconds: 1), (timer) {
      if (mounted) {
        setState(() {
          _battleDuration = DateTime.now().difference(widget.battleState.startTime!);
        });
      }
    });
  }

  @override
  void didUpdateWidget(BattleModeOverlay oldWidget) {
    super.didUpdateWidget(oldWidget);

    // Animate score changes
    if (oldWidget.battleState.myScore != widget.battleState.myScore ||
        oldWidget.battleState.opponentScore != widget.battleState.opponentScore) {
      _scoreAnimationController.forward(from: 0);
    }
  }

  @override
  Widget build(BuildContext context) {
    final isEnded = widget.battleState.status == BattleStatus.ended;
    final isWinner = widget.battleState.isWinning;

    return Container(
      width: double.infinity,
      decoration: BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topCenter,
          end: Alignment.bottomCenter,
          colors: [
            Colors.black.withOpacity(0.8),
            Colors.transparent,
          ],
        ),
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          // Battle header
          _buildBattleHeader(isEnded, isWinner),

          const SizedBox(height: 12),

          // Score comparison
          _buildScoreComparison(),

          const SizedBox(height: 16),

          // Actions
          if (!isEnded) _buildBattleActions(),
        ],
      ),
    );
  }

  Widget _buildBattleHeader(bool isEnded, bool isWinner) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      child: Row(
        children: [
          // Battle status indicator
          AnimatedBuilder(
            animation: _pulseAnimationController,
            builder: (context, child) {
              return Container(
                padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    colors: isEnded
                        ? [Colors.grey.shade700, Colors.grey.shade900]
                        : isWinner
                            ? [Colors.green.shade600, Colors.green.shade800]
                            : [Colors.red.shade600, Colors.red.shade800],
                  ),
                  borderRadius: BorderRadius.circular(20),
                  boxShadow: [
                    BoxShadow(
                      color: (isEnded
                              ? Colors.grey
                              : isWinner
                                  ? Colors.green
                                  : Colors.red)
                          .withOpacity(0.3 + (_pulseAnimationController.value * 0.3)),
                      blurRadius: 8 + (_pulseAnimationController.value * 4),
                      spreadRadius: 2 + (_pulseAnimationController.value * 2),
                    ),
                  ],
                ),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Icon(
                      isEnded
                          ? Icons.emoji_events
                          : Icons.sports_kabaddi,
                      color: Colors.white,
                      size: 16,
                    ),
                    const SizedBox(width: 6),
                    Text(
                      isEnded ? 'BATTLE ENDED' : 'PK BATTLE',
                      style: const TextStyle(
                        color: Colors.white,
                        fontWeight: FontWeight.bold,
                        fontSize: 12,
                        letterSpacing: 1.2,
                      ),
                    ),
                  ],
                ),
              );
            },
          ),

          const Spacer(),

          // Battle duration
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
            decoration: BoxDecoration(
              color: Colors.black.withOpacity(0.6),
              borderRadius: BorderRadius.circular(16),
            ),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                const Icon(Icons.timer, color: Colors.white, size: 14),
                const SizedBox(width: 6),
                Text(
                  _formatDuration(_battleDuration),
                  style: const TextStyle(
                    color: Colors.white,
                    fontWeight: FontWeight.w600,
                    fontSize: 12,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildScoreComparison() {
    final myPercentage = widget.battleState.myPercentage;
    final opponentPercentage = widget.battleState.opponentPercentage;
    final isWinning = widget.battleState.isWinning;

    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 16),
      child: Column(
        children: [
          // Streamer names and scores
          Row(
            children: [
              // My side
              Expanded(
                child: _buildStreamerInfo(
                  widget.myName,
                  widget.battleState.myScore,
                  isWinning,
                  isMe: true,
                ),
              ),

              // VS indicator
              Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    colors: [
                      Colors.purple.shade700,
                      Colors.pink.shade700,
                    ],
                  ),
                  shape: BoxShape.circle,
                  boxShadow: [
                    BoxShadow(
                      color: Colors.purple.withOpacity(0.5),
                      blurRadius: 12,
                      spreadRadius: 2,
                    ),
                  ],
                ),
                child: const Text(
                  'VS',
                  style: TextStyle(
                    color: Colors.white,
                    fontWeight: FontWeight.bold,
                    fontSize: 16,
                    letterSpacing: 2,
                  ),
                ),
              ),

              // Opponent side
              Expanded(
                child: _buildStreamerInfo(
                  widget.battleState.opponentName,
                  widget.battleState.opponentScore,
                  !isWinning,
                  isMe: false,
                ),
              ),
            ],
          ),

          const SizedBox(height: 16),

          // Progress bars
          ClipRRect(
            borderRadius: BorderRadius.circular(8),
            child: SizedBox(
              height: 8,
              child: Stack(
                children: [
                  // Background
                  Container(
                    color: Colors.grey.shade800,
                  ),

                  // My progress
                  FractionallySizedBox(
                    widthFactor: myPercentage,
                    alignment: Alignment.centerLeft,
                    child: AnimatedBuilder(
                      animation: _scoreAnimationController,
                      builder: (context, child) {
                        return Container(
                          decoration: BoxDecoration(
                            gradient: LinearGradient(
                              colors: isWinning
                                  ? [Colors.green.shade400, Colors.green.shade600]
                                  : [Colors.red.shade400, Colors.red.shade600],
                            ),
                          ),
                        );
                      },
                    ),
                  ),

                  // Opponent progress (from right)
                  FractionallySizedBox(
                    widthFactor: opponentPercentage,
                    alignment: Alignment.centerRight,
                    child: AnimatedBuilder(
                      animation: _scoreAnimationController,
                      builder: (context, child) {
                        return Container(
                          decoration: BoxDecoration(
                            gradient: LinearGradient(
                              colors: !isWinning
                                  ? [Colors.green.shade400, Colors.green.shade600]
                                  : [Colors.red.shade400, Colors.red.shade600],
                            ),
                          ),
                        );
                      },
                    ),
                  ),
                ],
              ),
            ),
          ),

          const SizedBox(height: 8),

          // Percentage labels
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                '${(myPercentage * 100).toStringAsFixed(1)}%',
                style: TextStyle(
                  color: isWinning ? Colors.green : Colors.red,
                  fontWeight: FontWeight.bold,
                  fontSize: 12,
                ),
              ),
              Text(
                '${(opponentPercentage * 100).toStringAsFixed(1)}%',
                style: TextStyle(
                  color: !isWinning ? Colors.green : Colors.red,
                  fontWeight: FontWeight.bold,
                  fontSize: 12,
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildStreamerInfo(String name, int score, bool isWinning, {required bool isMe}) {
    return Column(
      crossAxisAlignment: isMe ? CrossAxisAlignment.start : CrossAxisAlignment.end,
      children: [
        // Name
        Text(
          name,
          style: TextStyle(
            color: Colors.white,
            fontWeight: isWinning ? FontWeight.bold : FontWeight.w500,
            fontSize: 14,
          ),
          maxLines: 1,
          overflow: TextOverflow.ellipsis,
        ),

        const SizedBox(height: 4),

        // Score with animation
        AnimatedBuilder(
          animation: _scoreAnimationController,
          builder: (context, child) {
            return Transform.scale(
              scale: 1.0 + (_scoreAnimationController.value * 0.2),
              child: Container(
                padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    colors: isWinning
                        ? [Colors.amber.shade600, Colors.amber.shade800]
                        : [Colors.grey.shade700, Colors.grey.shade900],
                  ),
                  borderRadius: BorderRadius.circular(16),
                  boxShadow: isWinning
                      ? [
                          BoxShadow(
                            color: Colors.amber.withOpacity(0.5),
                            blurRadius: 8,
                            spreadRadius: 2,
                          ),
                        ]
                      : null,
                ),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    if (isWinning) ...[
                      const Icon(Icons.star, color: Colors.white, size: 14),
                      const SizedBox(width: 4),
                    ],
                    Text(
                      _formatNumber(score),
                      style: const TextStyle(
                        color: Colors.white,
                        fontWeight: FontWeight.bold,
                        fontSize: 16,
                      ),
                    ),
                  ],
                ),
              ),
            );
          },
        ),
      ],
    );
  }

  Widget _buildBattleActions() {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16),
      child: Row(
        children: [
          // Forfeit button
          OutlinedButton.icon(
            onPressed: () {
              showDialog(
                context: context,
                builder: (context) => AlertDialog(
                  title: const Text('Forfeit Battle?'),
                  content: const Text(
                    'Are you sure you want to forfeit this battle? This will count as a loss.',
                  ),
                  actions: [
                    TextButton(
                      onPressed: () => Navigator.pop(context),
                      child: const Text('Cancel'),
                    ),
                    ElevatedButton(
                      onPressed: () {
                        Navigator.pop(context);
                        widget.onForfeit?.call();
                      },
                      style: ElevatedButton.styleFrom(
                        backgroundColor: Colors.red,
                        foregroundColor: Colors.white,
                      ),
                      child: const Text('Forfeit'),
                    ),
                  ],
                ),
              );
            },
            icon: const Icon(Icons.flag, size: 16),
            label: const Text('Forfeit'),
            style: OutlinedButton.styleFrom(
              foregroundColor: Colors.white,
              side: const BorderSide(color: Colors.red),
            ),
          ),

          const Spacer(),

          // Encourage support message
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
            decoration: BoxDecoration(
              color: Colors.purple.withOpacity(0.3),
              borderRadius: BorderRadius.circular(16),
              border: Border.all(color: Colors.purple.shade300),
            ),
            child: const Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                Icon(Icons.card_giftcard, color: Colors.white, size: 16),
                SizedBox(width: 6),
                Text(
                  'Send gifts to win!',
                  style: TextStyle(
                    color: Colors.white,
                    fontSize: 12,
                    fontWeight: FontWeight.w500,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  String _formatNumber(int number) {
    if (number >= 1000000) return '${(number / 1000000).toStringAsFixed(1)}M';
    if (number >= 1000) return '${(number / 1000).toStringAsFixed(1)}K';
    return number.toString();
  }

  String _formatDuration(Duration duration) {
    final minutes = duration.inMinutes;
    final seconds = duration.inSeconds % 60;
    return '${minutes.toString().padLeft(2, '0')}:${seconds.toString().padLeft(2, '0')}';
  }
}

/// Battle result dialog shown at the end
class BattleResultDialog extends StatelessWidget {
  final BattleState battleState;
  final String myName;
  final int currentUserId;

  const BattleResultDialog({
    super.key,
    required this.battleState,
    required this.myName,
    required this.currentUserId,
  });

  @override
  Widget build(BuildContext context) {
    final isWinner = battleState.isWinning;
    final scoreDiff = battleState.scoreDifference.abs();

    return Dialog(
      backgroundColor: Colors.transparent,
      child: Container(
        padding: const EdgeInsets.all(24),
        decoration: BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
            colors: isWinner
                ? [Colors.amber.shade700, Colors.amber.shade900]
                : [Colors.grey.shade800, Colors.grey.shade900],
          ),
          borderRadius: BorderRadius.circular(20),
          boxShadow: [
            BoxShadow(
              color: (isWinner ? Colors.amber : Colors.grey).withOpacity(0.5),
              blurRadius: 20,
              spreadRadius: 5,
            ),
          ],
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            // Trophy/Result icon
            Icon(
              isWinner ? Icons.emoji_events : Icons.sentiment_dissatisfied,
              size: 80,
              color: Colors.white,
            ),

            const SizedBox(height: 16),

            // Result text
            Text(
              isWinner ? 'VICTORY!' : 'DEFEAT',
              style: const TextStyle(
                color: Colors.white,
                fontSize: 32,
                fontWeight: FontWeight.bold,
                letterSpacing: 2,
              ),
            ),

            const SizedBox(height: 8),

            Text(
              isWinner ? 'You won the battle!' : 'Better luck next time!',
              style: TextStyle(
                color: Colors.white.withOpacity(0.8),
                fontSize: 16,
              ),
            ),

            const SizedBox(height: 24),

            // Final scores
            Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: Colors.black.withOpacity(0.3),
                borderRadius: BorderRadius.circular(12),
              ),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceAround,
                children: [
                  _buildFinalScore(myName, battleState.myScore, isWinner),
                  const Text(
                    'VS',
                    style: TextStyle(
                      color: Colors.white,
                      fontSize: 20,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  _buildFinalScore(
                    battleState.opponentName,
                    battleState.opponentScore,
                    !isWinner,
                  ),
                ],
              ),
            ),

            const SizedBox(height: 16),

            // Score difference
            Text(
              'Won by $scoreDiff points',
              style: TextStyle(
                color: Colors.white.withOpacity(0.7),
                fontSize: 14,
              ),
            ),

            const SizedBox(height: 24),

            // Close button
            ElevatedButton(
              onPressed: () => Navigator.pop(context),
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.white,
                foregroundColor: isWinner ? Colors.amber.shade900 : Colors.grey.shade900,
                padding: const EdgeInsets.symmetric(horizontal: 48, vertical: 16),
              ),
              child: const Text(
                'Continue',
                style: TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildFinalScore(String name, int score, bool isWinner) {
    return Column(
      children: [
        Text(
          name,
          style: TextStyle(
            color: Colors.white,
            fontSize: 14,
            fontWeight: isWinner ? FontWeight.bold : FontWeight.w500,
          ),
          maxLines: 1,
          overflow: TextOverflow.ellipsis,
        ),
        const SizedBox(height: 8),
        Text(
          score.toString(),
          style: TextStyle(
            color: Colors.white,
            fontSize: 24,
            fontWeight: FontWeight.bold,
            shadows: isWinner
                ? [
                    Shadow(
                      color: Colors.white.withOpacity(0.5),
                      blurRadius: 10,
                    ),
                  ]
                : null,
          ),
        ),
      ],
    );
  }
}

/// Battle invite dialog
class BattleInviteDialog extends StatelessWidget {
  final BattleInvite invite;
  final VoidCallback onAccept;
  final VoidCallback onDecline;

  const BattleInviteDialog({
    super.key,
    required this.invite,
    required this.onAccept,
    required this.onDecline,
  });

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      title: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(8),
            decoration: BoxDecoration(
              gradient: LinearGradient(
                colors: [Colors.purple.shade600, Colors.pink.shade600],
              ),
              shape: BoxShape.circle,
            ),
            child: const Icon(Icons.sports_kabaddi, color: Colors.white, size: 24),
          ),
          const SizedBox(width: 12),
          const Text('Battle Invite!'),
        ],
      ),
      content: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          RichText(
            text: TextSpan(
              style: const TextStyle(color: Colors.black, fontSize: 16),
              children: [
                TextSpan(
                  text: invite.opponentName,
                  style: const TextStyle(fontWeight: FontWeight.bold),
                ),
                const TextSpan(text: ' has challenged you to a PK Battle!'),
              ],
            ),
          ),
          const SizedBox(height: 16),
          Container(
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: Colors.purple.withOpacity(0.1),
              borderRadius: BorderRadius.circular(8),
              border: Border.all(color: Colors.purple.shade200),
            ),
            child: const Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'How it works:',
                  style: TextStyle(fontWeight: FontWeight.bold, fontSize: 14),
                ),
                SizedBox(height: 8),
                Text(
                  '• Both streams will compete for gifts\n'
                  '• Viewers send gifts to support their favorite\n'
                  '• Highest score wins after time runs out',
                  style: TextStyle(fontSize: 12),
                ),
              ],
            ),
          ),
        ],
      ),
      actions: [
        TextButton(
          onPressed: () {
            Navigator.pop(context);
            onDecline();
          },
          child: const Text('Decline'),
        ),
        ElevatedButton(
          onPressed: () {
            Navigator.pop(context);
            onAccept();
          },
          style: ElevatedButton.styleFrom(
            backgroundColor: Colors.purple,
            foregroundColor: Colors.white,
          ),
          child: const Text('Accept Challenge!'),
        ),
      ],
    );
  }
}
