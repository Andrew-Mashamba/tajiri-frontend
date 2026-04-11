// lib/games/games/dots_boxes/dots_boxes_game.dart

import 'dart:async';
import 'dart:math';

import 'package:flutter/material.dart';

import '../../core/game_context.dart' as gc;
import '../../core/game_enums.dart';
import '../../core/game_interface.dart';
import 'dots_boxes_engine.dart';

const Color _kPrimary = Color(0xFF1A1A1A);
const Color _kSecondary = Color(0xFF666666);

class DotsBoxesGame extends StatefulWidget {
  final gc.GameContext gameContext;
  const DotsBoxesGame({super.key, required this.gameContext});

  @override
  State<DotsBoxesGame> createState() => DotsBoxesGameState();
}

class DotsBoxesGameState extends State<DotsBoxesGame>
    implements GameInterface {
  gc.GameContext get _ctx => widget.gameContext;

  late DotsBoxesEngine _engine;
  bool _gameOver = false;
  bool _aiThinking = false;

  // Player 1 = user (currentPlayer==1), Player 2 = opponent
  bool get _isMyTurn => _engine.currentPlayer == 1;

  @override
  String get gameId => 'dots_boxes';

  @override
  void initState() {
    super.initState();
    _engine = DotsBoxesEngine();
    _ctx.setOnOpponentMove(onOpponentMove);
  }

  void _onLineTap(String lineId) {
    if (_gameOver || !_isMyTurn || _engine.isLineDrawn(lineId) || _aiThinking) {
      return;
    }

    setState(() {
      _engine.drawLine(lineId);
    });

    _checkGameEnd();

    // If it's now opponent's turn and practice mode, AI moves
    if (!_isMyTurn && !_gameOver && _ctx.mode == GameMode.practice) {
      _doAiMove();
    }
  }

  void _doAiMove() {
    _aiThinking = true;
    Timer(const Duration(milliseconds: 500), () {
      if (!mounted || _gameOver) return;

      final moves = _engine.legalMoves();
      if (moves.isEmpty) return;

      final rng = Random();
      // Simple AI: prefer moves that complete a box, avoid giving boxes
      String? bestMove;
      for (final m in moves) {
        // Temporarily check if this line completes a box
        // We'll pick a completing move if possible
        bestMove ??= m;
      }

      // Try to find a move that completes a box
      for (final m in moves) {
        // Check adjacent boxes
        final tempEngine = DotsBoxesEngine.fromJson(_engine.toJson());
        tempEngine.currentPlayer = 2;
        final completed = tempEngine.drawLine(m);
        if (completed > 0) {
          bestMove = m;
          break;
        }
      }

      // If no completing move, pick random
      bestMove ??= moves[rng.nextInt(moves.length)];

      setState(() {
        _engine.drawLine(bestMove!);
        _aiThinking = false;
      });

      _checkGameEnd();

      // AI might get another turn if it completed a box
      if (!_isMyTurn && !_gameOver && _ctx.mode == GameMode.practice) {
        _doAiMove();
      }
    });
  }

  void _checkGameEnd() {
    if (_engine.isGameOver) {
      setState(() => _gameOver = true);

      final p1 = _engine.player1Score;
      final p2 = _engine.player2Score;
      int? winnerId;
      if (p1 > p2) {
        winnerId = _ctx.userId;
      } else if (p2 > p1) {
        winnerId = _ctx.opponentId;
      }
      _ctx.onGameComplete({
        'winner_id': winnerId,
        'player_1_score': p1,
        'player_2_score': p2,
      });
    }
  }

  // ─── GameInterface ─────────────────────────────────────────

  @override
  void onOpponentMove(Map<String, dynamic> moveData) {
    final lineId = moveData['line'] as String?;
    if (lineId == null) return;
    setState(() {
      _engine.drawLine(lineId);
    });
    _checkGameEnd();
  }

  @override
  void onReconnect(Map<String, dynamic> savedState) {
    setState(() {
      _engine = DotsBoxesEngine.fromJson(savedState);
    });
  }

  @override
  Map<String, dynamic> getCurrentState() => _engine.toJson();

  // ─── Build ─────────────────────────────────────────────────

  @override
  Widget build(BuildContext context) {
    if (_gameOver) return _buildGameOver();

    return Scaffold(
      backgroundColor: Colors.white,
      body: SafeArea(
        child: Column(
          children: [
            const SizedBox(height: 12),
            _buildHeader(),
            const SizedBox(height: 8),
            Expanded(child: _buildGrid()),
            const SizedBox(height: 16),
          ],
        ),
      ),
    );
  }

  Widget _buildHeader() {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Text('Dots & Boxes',
                  style: TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.bold,
                      color: _kPrimary)),
              Text(
                _isMyTurn ? 'Your turn' : 'Opponent\'s turn',
                style: const TextStyle(fontSize: 13, color: _kSecondary),
              ),
            ],
          ),
          Row(
            children: [
              _buildScorePill('You', _engine.player1Score, true),
              const SizedBox(width: 8),
              _buildScorePill(
                _ctx.opponentName ?? 'AI',
                _engine.player2Score,
                false,
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildScorePill(String label, int score, bool isPlayer) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
      decoration: BoxDecoration(
        color: isPlayer ? _kPrimary : Colors.grey.shade200,
        borderRadius: BorderRadius.circular(12),
      ),
      child: Text(
        '$label: $score',
        style: TextStyle(
          fontSize: 13,
          fontWeight: FontWeight.w600,
          color: isPlayer ? Colors.white : _kPrimary,
        ),
      ),
    );
  }

  Widget _buildGrid() {
    return Center(
      child: LayoutBuilder(
        builder: (context, constraints) {
          final maxSize = min(constraints.maxWidth, constraints.maxHeight) - 32;
          final cellSize = maxSize / DotsBoxesEngine.gridSize;

          return SizedBox(
            width: maxSize,
            height: maxSize,
            child: Stack(
              children: [
                // Box fills
                ..._buildBoxFills(cellSize),
                // Lines (interactive)
                ..._buildLines(cellSize),
                // Dots
                ..._buildDots(cellSize),
              ],
            ),
          );
        },
      ),
    );
  }

  List<Widget> _buildBoxFills(double cellSize) {
    final widgets = <Widget>[];
    for (int r = 0; r < DotsBoxesEngine.gridSize - 1; r++) {
      for (int c = 0; c < DotsBoxesEngine.gridSize - 1; c++) {
        final owner = _engine.boxOwner(r, c);
        if (owner != null) {
          widgets.add(Positioned(
            left: c * cellSize + 6,
            top: r * cellSize + 6,
            child: Container(
              width: cellSize - 12,
              height: cellSize - 12,
              decoration: BoxDecoration(
                color: owner == 1
                    ? _kPrimary.withAlpha(30)
                    : _kSecondary.withAlpha(30),
                borderRadius: BorderRadius.circular(4),
              ),
              alignment: Alignment.center,
              child: Text(
                owner == 1 ? 'Y' : 'O',
                style: TextStyle(
                  fontSize: 14,
                  fontWeight: FontWeight.bold,
                  color: owner == 1
                      ? _kPrimary.withAlpha(120)
                      : _kSecondary.withAlpha(120),
                ),
              ),
            ),
          ));
        }
      }
    }
    return widgets;
  }

  List<Widget> _buildLines(double cellSize) {
    final widgets = <Widget>[];

    // Horizontal lines
    for (int r = 0; r < DotsBoxesEngine.gridSize; r++) {
      for (int c = 0; c < DotsBoxesEngine.gridSize - 1; c++) {
        final lineId = 'h_${r}_$c';
        final drawn = _engine.isLineDrawn(lineId);
        widgets.add(Positioned(
          left: c * cellSize + 6,
          top: r * cellSize - 3,
          child: GestureDetector(
            onTap: () => _onLineTap(lineId),
            child: Container(
              width: cellSize - 12,
              height: 10,
              margin: const EdgeInsets.only(left: 4),
              decoration: BoxDecoration(
                color: drawn ? _kPrimary : Colors.grey.shade200,
                borderRadius: BorderRadius.circular(3),
              ),
            ),
          ),
        ));
      }
    }

    // Vertical lines
    for (int r = 0; r < DotsBoxesEngine.gridSize - 1; r++) {
      for (int c = 0; c < DotsBoxesEngine.gridSize; c++) {
        final lineId = 'v_${r}_$c';
        final drawn = _engine.isLineDrawn(lineId);
        widgets.add(Positioned(
          left: c * cellSize - 3,
          top: r * cellSize + 6,
          child: GestureDetector(
            onTap: () => _onLineTap(lineId),
            child: Container(
              width: 10,
              height: cellSize - 12,
              margin: const EdgeInsets.only(top: 4),
              decoration: BoxDecoration(
                color: drawn ? _kPrimary : Colors.grey.shade200,
                borderRadius: BorderRadius.circular(3),
              ),
            ),
          ),
        ));
      }
    }

    return widgets;
  }

  List<Widget> _buildDots(double cellSize) {
    final widgets = <Widget>[];
    for (int r = 0; r < DotsBoxesEngine.gridSize; r++) {
      for (int c = 0; c < DotsBoxesEngine.gridSize; c++) {
        widgets.add(Positioned(
          left: c * cellSize - 6,
          top: r * cellSize - 6,
          child: Container(
            width: 12,
            height: 12,
            decoration: const BoxDecoration(
              color: _kPrimary,
              shape: BoxShape.circle,
            ),
          ),
        ));
      }
    }
    return widgets;
  }

  Widget _buildGameOver() {
    final p1 = _engine.player1Score;
    final p2 = _engine.player2Score;
    final won = p1 > p2;
    final tied = p1 == p2;

    return Scaffold(
      backgroundColor: Colors.white,
      body: SafeArea(
        child: Center(
          child: Padding(
            padding: const EdgeInsets.all(32),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Icon(
                  won
                      ? Icons.emoji_events_rounded
                      : Icons.sentiment_neutral_rounded,
                  size: 64,
                  color: _kPrimary,
                ),
                const SizedBox(height: 16),
                Text(
                  tied
                      ? 'Draw!'
                      : won
                          ? 'You Win!'
                          : 'You Lose!',
                  style: const TextStyle(
                      fontSize: 24,
                      fontWeight: FontWeight.bold,
                      color: _kPrimary),
                ),
                Text(
                  tied
                      ? 'Sare!'
                      : won
                          ? 'Umeshinda!'
                          : 'Umeshindwa!',
                  style: const TextStyle(fontSize: 14, color: _kSecondary),
                ),
                const SizedBox(height: 24),
                Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    _buildEndScore('You', p1),
                    const SizedBox(width: 32),
                    _buildEndScore(_ctx.opponentName ?? 'AI', p2),
                  ],
                ),
                const SizedBox(height: 32),
                SizedBox(
                  width: double.infinity,
                  height: 48,
                  child: ElevatedButton(
                    onPressed: () => Navigator.of(context).pop(),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: _kPrimary,
                      foregroundColor: Colors.white,
                      shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(12)),
                    ),
                    child: const Text('Done / Maliza'),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildEndScore(String label, int score) {
    return Column(
      children: [
        Text(label,
            style: const TextStyle(fontSize: 13, color: _kSecondary)),
        const SizedBox(height: 4),
        Text('$score',
            style: const TextStyle(
                fontSize: 36,
                fontWeight: FontWeight.bold,
                color: _kPrimary)),
        const Text('boxes / sanduku',
            style: TextStyle(fontSize: 12, color: _kSecondary)),
      ],
    );
  }
}
