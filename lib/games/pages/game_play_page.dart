// lib/games/pages/game_play_page.dart
import 'package:flutter/material.dart';
import '../core/game_definition.dart';
import '../core/game_context.dart';
import '../core/game_enums.dart';
import '../models/game_session.dart';
import '../services/games_service.dart';
import '../services/game_socket_service.dart';
import '../widgets/player_banner.dart';
import '../widgets/game_timer.dart';
import 'game_result_page.dart';

const Color _kPrimary = Color(0xFF1A1A1A);

/// Full-screen game play container.
/// Provides player banners, timer, and the game widget from the definition builder.
class GamePlayPage extends StatefulWidget {
  final GameSession session;
  final GameDefinition definition;
  final int userId;

  const GamePlayPage({
    super.key,
    required this.session,
    required this.definition,
    required this.userId,
  });

  @override
  State<GamePlayPage> createState() => _GamePlayPageState();
}

class _GamePlayPageState extends State<GamePlayPage> {
  late GameSocketService _socketService;
  late GameSession _session;
  int _myScore = 0;
  int _opponentScore = 0;
  String _opponentName = 'Opponent';

  /// Context passed to the game widget; stores the opponent-move listener.
  late GameContext _gameContext;

  @override
  void initState() {
    super.initState();
    _session = widget.session;
    _socketService = GameSocketService();
    _socketService.connect(_session.id);

    _socketService.onPlayerJoined = (data) {
      if (mounted) {
        final name = data['user_name']?.toString() ??
            data['player_2_name']?.toString();
        if (name != null && name.isNotEmpty) {
          setState(() => _opponentName = name);
        }
      }
    };

    // Deliver opponent moves to the game widget via GameContext listener.
    // Games register their onOpponentMove handler via gameContext.setOnOpponentMove
    // in their initState, so moves are forwarded automatically.
    _socketService.onPlayerMove = (moveData) {
      if (!mounted) return;
      _gameContext.deliverOpponentMove(moveData);
    };

    _socketService.onGameEnded = (data) {
      if (mounted) {
        _navigateToResult();
      }
    };
  }

  @override
  void dispose() {
    _socketService.dispose();
    super.dispose();
  }

  void _updateScores(int myScore, int opponentScore) {
    if (!mounted) return;
    setState(() {
      _myScore = myScore;
      _opponentScore = opponentScore;
    });
  }

  void _onGameComplete(Map<String, dynamic> result) async {
    final winnerId = result['winner_id'] as int?;
    final p1Score = result['player_1_score'] as int? ?? 0;
    final p2Score = result['player_2_score'] as int? ?? 0;

    final service = GamesService();
    final endResult = await service.endGame(
      _session.id,
      winnerId: winnerId,
      player1Score: p1Score,
      player2Score: p2Score,
    );

    if (!mounted) return;

    if (endResult.success && endResult.data != null) {
      _session = endResult.data!;
    }

    // Reload session to capture the latest escrow state (backend settles/refunds
    // inside endGame, so we just need the updated session data for display).
    final refreshed = await service.getSession(_session.id);
    if (!mounted) return;
    if (refreshed.success && refreshed.data != null) {
      _session = refreshed.data!;
    }

    _navigateToResult();
  }

  void _navigateToResult() {
    Navigator.pushReplacement(
      context,
      MaterialPageRoute(
        builder: (_) => GameResultPage(
          session: _session,
          userId: widget.userId,
          definition: widget.definition,
        ),
      ),
    );
  }

  void _onTimerComplete() {
    // Timer ran out — end game. Current scores determine winner.
    _onGameComplete({
      'winner_id': _myScore > _opponentScore
          ? widget.userId
          : _myScore < _opponentScore
              ? _session.opponentId(widget.userId)
              : null,
      'player_1_score': _session.player1Id == widget.userId ? _myScore : _opponentScore,
      'player_2_score': _session.player1Id == widget.userId ? _opponentScore : _myScore,
    });
  }

  Widget _buildGameWidget() {
    _gameContext = GameContext(
      sessionId: _session.id,
      userId: widget.userId,
      opponentId: _session.opponentId(widget.userId),
      opponentName: _opponentName,
      gameId: widget.definition.id,
      mode: _session.mode,
      gameSeed: _session.gameSeed,
      gameState: _session.gameState,
      socketService: _socketService,
      onGameComplete: _onGameComplete,
      onScoreUpdate: _updateScores,
    );

    try {
      return widget.definition.builder(_gameContext);
    } catch (e) {
      // If builder fails, show a meaningful error instead of a generic placeholder
      return _buildErrorWidget('Game failed to load: $e. Please try again.');
    }
  }

  Widget _buildErrorWidget(String message) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(32),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              Icons.error_outline_rounded,
              size: 64,
              color: Colors.grey.shade300,
            ),
            const SizedBox(height: 16),
            Text(
              message,
              style: const TextStyle(
                fontSize: 14,
                fontWeight: FontWeight.w600,
                color: _kPrimary,
              ),
              textAlign: TextAlign.center,
              maxLines: 4,
              overflow: TextOverflow.ellipsis,
            ),
            const SizedBox(height: 24),
            SizedBox(
              height: 44,
              child: ElevatedButton(
                onPressed: () => _onGameComplete({
                  'winner_id': null,
                  'player_1_score': 0,
                  'player_2_score': 0,
                }),
                style: ElevatedButton.styleFrom(
                  backgroundColor: _kPrimary,
                  foregroundColor: Colors.white,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                ),
                child: const Text('End Game / Maliza Mchezo'),
              ),
            ),
          ],
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFFAFAFA),
      body: SafeArea(
        child: Column(
          children: [
            // ─── Top bar: Player | Timer | Opponent ──────────────
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
              decoration: BoxDecoration(
                color: Colors.white,
                border: Border(
                  bottom: BorderSide(color: Colors.grey.shade200),
                ),
              ),
              child: Row(
                children: [
                  // Current player
                  Expanded(
                    child: PlayerBanner(
                      name: 'You',
                      score: _myScore,
                      isCurrentUser: true,
                    ),
                  ),

                  // Timer (hidden in practice mode — no opponent, no timeout)
                  if (widget.session.mode != GameMode.practice)
                    GameTimer(
                      totalSeconds: widget.definition.estimatedMinutes * 60,
                      onComplete: _onTimerComplete,
                      size: 52,
                    )
                  else
                    const SizedBox(width: 52),

                  // Opponent
                  Expanded(
                    child: Align(
                      alignment: Alignment.centerRight,
                      child: PlayerBanner(
                        name: _session.player2Id != null ? _opponentName : '---',
                        score: _opponentScore,
                        isCurrentUser: false,
                      ),
                    ),
                  ),
                ],
              ),
            ),

            // ─── Game area ───────────────────────────────────────
            Expanded(child: _buildGameWidget()),
          ],
        ),
      ),
    );
  }
}
