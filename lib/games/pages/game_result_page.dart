// lib/games/pages/game_result_page.dart
import 'package:flutter/material.dart';
import '../core/game_definition.dart';
import '../core/game_enums.dart';
import '../models/game_session.dart';
import '../services/games_service.dart';
import 'game_lobby_page.dart';
import 'game_room_page.dart';

const Color _kPrimary = Color(0xFF1A1A1A);
const Color _kSecondary = Color(0xFF666666);

/// Full-screen result page shown after a game ends.
class GameResultPage extends StatelessWidget {
  final GameSession session;
  final int userId;
  final GameDefinition definition;

  const GameResultPage({
    super.key,
    required this.session,
    required this.userId,
    required this.definition,
  });

  bool get _isWin => session.winnerId == userId;
  bool get _isLoss =>
      session.winnerId != null && session.winnerId != userId;
  bool get _isDraw => session.winnerId == null && session.isCompleted;

  String get _titleText {
    if (_isWin) return 'You Won!';
    if (_isLoss) return 'You Lost';
    return 'Draw';
  }

  String get _titleTextSwahili {
    if (_isWin) return 'Umeshinda!';
    if (_isLoss) return 'Umeshindwa';
    return 'Sare';
  }

  IconData get _resultIcon {
    if (_isWin) return Icons.emoji_events_rounded;
    if (_isLoss) return Icons.thumb_down_rounded;
    return Icons.handshake_rounded;
  }

  Color get _resultColor {
    if (_isWin) return const Color(0xFF10B981);
    if (_isLoss) return const Color(0xFFEF4444);
    return const Color(0xFFF59E0B);
  }

  int get _myScore => session.myScore(userId);
  int get _opponentScore => session.opponentScore(userId);

  String? get _payoutText {
    if (session.stakeAmount <= 0) return null;
    if (_isDraw) return 'Stakes refunded / Dau limerudishwa';
    if (_isWin) {
      // Winner gets both stakes minus platform fee
      final payout = (session.stakeAmount * 2) - session.platformFee;
      return 'You won TZS ${payout.toStringAsFixed(0)}!';
    }
    return 'You lost TZS ${session.stakeAmount.toStringAsFixed(0)}';
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFFAFAFA),
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.all(24),
          child: Column(
            children: [
              const Spacer(flex: 2),

              // Result icon
              Container(
                width: 96,
                height: 96,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  color: _resultColor.withValues(alpha: 0.12),
                ),
                child: Icon(_resultIcon, size: 48, color: _resultColor),
              ),
              const SizedBox(height: 20),

              // Title
              Text(
                _titleText,
                style: TextStyle(
                  fontSize: 28,
                  fontWeight: FontWeight.w700,
                  color: _resultColor,
                ),
              ),
              Text(
                _titleTextSwahili,
                style: TextStyle(
                  fontSize: 16,
                  color: _resultColor.withValues(alpha: 0.7),
                ),
              ),
              const SizedBox(height: 24),

              // Score
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 32, vertical: 16),
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(16),
                  border: Border.all(color: Colors.grey.shade200),
                ),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Column(
                      children: [
                        const Text(
                          'You',
                          style: TextStyle(fontSize: 13, color: _kSecondary),
                        ),
                        const SizedBox(height: 4),
                        Text(
                          '$_myScore',
                          style: const TextStyle(
                            fontSize: 36,
                            fontWeight: FontWeight.w700,
                            color: _kPrimary,
                          ),
                        ),
                      ],
                    ),
                    Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 24),
                      child: Text(
                        '-',
                        style: TextStyle(
                          fontSize: 28,
                          fontWeight: FontWeight.w700,
                          color: Colors.grey.shade300,
                        ),
                      ),
                    ),
                    Column(
                      children: [
                        const Text(
                          'Opponent',
                          style: TextStyle(fontSize: 13, color: _kSecondary),
                        ),
                        const SizedBox(height: 4),
                        Text(
                          '$_opponentScore',
                          style: const TextStyle(
                            fontSize: 36,
                            fontWeight: FontWeight.w700,
                            color: _kPrimary,
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),

              // Payout info
              if (_payoutText != null) ...[
                const SizedBox(height: 16),
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
                  decoration: BoxDecoration(
                    color: _isWin
                        ? const Color(0xFF10B981).withValues(alpha: 0.08)
                        : _isDraw
                            ? const Color(0xFFF59E0B).withValues(alpha: 0.08)
                            : const Color(0xFFEF4444).withValues(alpha: 0.08),
                    borderRadius: BorderRadius.circular(10),
                  ),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Icon(
                        _isWin
                            ? Icons.account_balance_wallet_rounded
                            : _isDraw
                                ? Icons.refresh_rounded
                                : Icons.money_off_rounded,
                        size: 18,
                        color: _resultColor,
                      ),
                      const SizedBox(width: 8),
                      Text(
                        _payoutText!,
                        style: TextStyle(
                          fontSize: 14,
                          fontWeight: FontWeight.w600,
                          color: _resultColor,
                        ),
                      ),
                    ],
                  ),
                ),
              ],

              const Spacer(flex: 3),

              // ─── Action Buttons ────────────────────────────────
              // Rematch
              SizedBox(
                width: double.infinity,
                height: 50,
                child: ElevatedButton.icon(
                  onPressed: () => _rematch(context),
                  icon: const Icon(Icons.replay_rounded, size: 20),
                  label: const Text(
                    'Rematch / Cheza Tena',
                    style: TextStyle(fontSize: 15, fontWeight: FontWeight.w600),
                  ),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: _kPrimary,
                    foregroundColor: Colors.white,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                    elevation: 0,
                  ),
                ),
              ),
              const SizedBox(height: 10),

              // New Game
              SizedBox(
                width: double.infinity,
                height: 50,
                child: OutlinedButton.icon(
                  onPressed: () => _newGame(context),
                  icon: const Icon(Icons.sports_esports_rounded, size: 20),
                  label: const Text(
                    'New Game / Mchezo Mpya',
                    style: TextStyle(fontSize: 15, fontWeight: FontWeight.w600),
                  ),
                  style: OutlinedButton.styleFrom(
                    foregroundColor: _kPrimary,
                    side: BorderSide(color: Colors.grey.shade300),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                  ),
                ),
              ),
              const SizedBox(height: 10),

              // Home
              SizedBox(
                width: double.infinity,
                height: 50,
                child: TextButton(
                  onPressed: () => _goHome(context),
                  child: const Text(
                    'Home / Nyumbani',
                    style: TextStyle(
                      fontSize: 15,
                      fontWeight: FontWeight.w500,
                      color: _kSecondary,
                    ),
                  ),
                ),
              ),
              const SizedBox(height: 16),
            ],
          ),
        ),
      ),
    );
  }

  Future<void> _rematch(BuildContext context) async {
    final messenger = ScaffoldMessenger.of(context);
    final navigator = Navigator.of(context);

    final service = GamesService();

    // For ranked mode, re-enter matchmaking queue (may get a different
    // opponent) instead of directly challenging the same person.
    final isRanked = session.mode == GameMode.ranked;
    final result = await service.createSession(
      gameId: definition.id,
      mode: session.mode,
      userId: userId,
      stakeTier: session.stakeAmount > 0 ? session.stakeTier : null,
      stakeAmount: session.stakeAmount > 0 ? session.stakeAmount : null,
      opponentId: isRanked ? null : session.opponentId(userId),
    );

    if (result.success && result.data != null) {
      navigator.pushReplacement(
        MaterialPageRoute(
          builder: (_) => GameRoomPage(
            session: result.data!,
            definition: definition,
            userId: userId,
          ),
        ),
      );
    } else {
      messenger.showSnackBar(
        SnackBar(
          content: Text(result.message ?? 'Failed to create rematch'),
          backgroundColor: const Color(0xFFEF4444),
        ),
      );
    }
  }

  void _newGame(BuildContext context) {
    Navigator.pushReplacement(
      context,
      MaterialPageRoute(
        builder: (_) => GameLobbyPage(
          definition: definition,
          userId: userId,
        ),
      ),
    );
  }

  void _goHome(BuildContext context) {
    // Pop all game screens (result, lobby) to return to the profile screen
    // that hosts GamesHomePage. Since game_room and game_play use
    // pushReplacement, the actual stack from profile is typically:
    //   [profile, lobby, result] or [profile, result]
    // We pop until only the profile (or root) route remains.
    Navigator.of(context).popUntil((route) {
      // Stop when we reach a route that is NOT one of our game pages.
      // Game pages are pushed via MaterialPageRoute without a name,
      // so we stop at a named route (profile, home) or at root.
      return route.isFirst || route.settings.name != null;
    });
  }
}
