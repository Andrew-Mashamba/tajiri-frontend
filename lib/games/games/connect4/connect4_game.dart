// lib/games/games/connect4/connect4_game.dart

import 'dart:async';
import 'dart:math';

import 'package:flutter/material.dart';

import '../../core/game_context.dart' as gc;
import '../../core/game_enums.dart';
import '../../core/game_interface.dart';
import 'connect4_engine.dart';

const Color _kPrimary = Color(0xFF1A1A1A);
const Color _kSecondary = Color(0xFF666666);

class Connect4Game extends StatefulWidget {
  final gc.GameContext gameContext;
  const Connect4Game({super.key, required this.gameContext});

  @override
  State<Connect4Game> createState() => Connect4GameState();
}

class Connect4GameState extends State<Connect4Game>
    with SingleTickerProviderStateMixin
    implements GameInterface {
  gc.GameContext get _ctx => widget.gameContext;

  late Connect4Engine _engine;
  bool _gameOver = false;
  bool _aiThinking = false;
  int? _winnerPlayer; // 1 or 2
  List<List<int>>? _winCells;

  // Drop animation
  AnimationController? _dropController;
  Animation<double>? _dropAnim;
  int _animCol = -1;
  int _animRow = -1;
  int _animPlayer = 0;

  bool get _isMyTurn => _engine.currentPlayer == 1;

  @override
  String get gameId => 'connect4';

  @override
  void initState() {
    super.initState();
    _engine = Connect4Engine();
    _dropController = AnimationController(
      duration: const Duration(milliseconds: 300),
      vsync: this,
    );
    _dropAnim = CurvedAnimation(
      parent: _dropController!,
      curve: Curves.bounceOut,
    );
    _ctx.setOnOpponentMove(onOpponentMove);
  }

  @override
  void dispose() {
    _dropController?.dispose();
    super.dispose();
  }

  void _onColumnTap(int col) {
    if (_gameOver || !_isMyTurn || _aiThinking) return;
    _playMove(col);
  }

  void _playMove(int col) {
    final row = _engine.dropDisc(col);
    if (row == -1) return; // column full

    final player = _engine.currentPlayer; // still current before switch
    _engine.switchPlayer();

    // Animate the drop
    setState(() {
      _animCol = col;
      _animRow = row;
      _animPlayer = player;
    });
    _dropController!.forward(from: 0).then((_) {
      if (!mounted) return;
      setState(() {
        _animCol = -1;
        _animRow = -1;
      });

      // Check win
      final result = _engine.checkWin();
      if (result != null) {
        _endGame(result.player, result.cells);
        return;
      }
      if (_engine.isFull()) {
        _endGame(null, null);
        return;
      }

      // AI move
      if (!_isMyTurn && _ctx.mode == GameMode.practice && !_gameOver) {
        _doAiMove();
      }
    });
  }

  void _doAiMove() {
    _aiThinking = true;
    Timer(const Duration(milliseconds: 500), () {
      if (!mounted || _gameOver) return;

      final legal = _engine.legalColumns();
      if (legal.isEmpty) return;

      final rng = Random();

      // Simple AI: check if AI can win, then block, then random
      int? chosen;

      // Try to win
      for (final c in legal) {
        final test = Connect4Engine.fromJson(_engine.toJson());
        test.dropDisc(c);
        if (test.checkWin() != null) {
          chosen = c;
          break;
        }
      }

      // Try to block
      if (chosen == null) {
        for (final c in legal) {
          final test = Connect4Engine.fromJson(_engine.toJson());
          test.currentPlayer = 1; // pretend player 1
          test.dropDisc(c);
          if (test.checkWin() != null) {
            chosen = c;
            break;
          }
        }
      }

      // Prefer center
      chosen ??= legal.contains(3) ? 3 : legal[rng.nextInt(legal.length)];

      setState(() => _aiThinking = false);
      _playMove(chosen);
    });
  }

  void _endGame(int? winner, List<List<int>>? cells) {
    setState(() {
      _gameOver = true;
      _winnerPlayer = winner;
      _winCells = cells;
    });

    int? winnerId;
    if (winner == 1) {
      winnerId = _ctx.userId;
    } else if (winner == 2) {
      winnerId = _ctx.opponentId;
    }
    _ctx.onGameComplete({
      'winner_id': winnerId,
      'player_1_score': winner == 1 ? 1 : 0,
      'player_2_score': winner == 2 ? 1 : 0,
    });
  }

  bool _isWinCell(int row, int col) {
    if (_winCells == null) return false;
    return _winCells!.any((c) => c[0] == row && c[1] == col);
  }

  // ─── GameInterface ─────────────────────────────────────────

  @override
  void onOpponentMove(Map<String, dynamic> moveData) {
    final col = moveData['column'] as int?;
    if (col == null) return;
    _playMove(col);
  }

  @override
  void onReconnect(Map<String, dynamic> savedState) {
    setState(() {
      _engine = Connect4Engine.fromJson(savedState);
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
            Expanded(child: _buildBoard()),
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
              const Text('Connect Four',
                  style: TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.bold,
                      color: _kPrimary)),
              Text(
                _aiThinking
                    ? 'AI thinking...'
                    : _isMyTurn
                        ? 'Your turn'
                        : 'Opponent\'s turn',
                style: const TextStyle(fontSize: 13, color: _kSecondary),
              ),
            ],
          ),
          Row(
            children: [
              _buildPlayerIndicator('You', 1),
              const SizedBox(width: 12),
              _buildPlayerIndicator(_ctx.opponentName ?? 'AI', 2),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildPlayerIndicator(String label, int player) {
    final isActive = _engine.currentPlayer == player && !_gameOver;
    return Row(
      children: [
        Container(
          width: 20,
          height: 20,
          decoration: BoxDecoration(
            shape: BoxShape.circle,
            color: player == 1 ? _kPrimary : Colors.white,
            border: Border.all(color: _kPrimary, width: 2),
          ),
        ),
        const SizedBox(width: 4),
        Text(
          label,
          style: TextStyle(
            fontSize: 13,
            fontWeight: isActive ? FontWeight.bold : FontWeight.normal,
            color: isActive ? _kPrimary : _kSecondary,
          ),
        ),
      ],
    );
  }

  Widget _buildBoard() {
    return Center(
      child: LayoutBuilder(
        builder: (context, constraints) {
          final maxWidth = constraints.maxWidth - 32;
          final maxHeight = constraints.maxHeight - 16;
          final cellFromWidth = maxWidth / Connect4Engine.cols;
          final cellFromHeight = maxHeight / (Connect4Engine.rows + 1); // +1 for tap arrows
          final cellSize = min(cellFromWidth, cellFromHeight);
          final boardWidth = cellSize * Connect4Engine.cols;
          final boardHeight = cellSize * (Connect4Engine.rows + 1);

          return SizedBox(
            width: boardWidth,
            height: boardHeight,
            child: Column(
              children: [
                // Tap arrows row
                SizedBox(
                  height: cellSize,
                  child: Row(
                    children: List.generate(Connect4Engine.cols, (c) {
                      final isLegal = _engine.legalColumns().contains(c);
                      return GestureDetector(
                        onTap: () => _onColumnTap(c),
                        child: SizedBox(
                          width: cellSize,
                          height: cellSize,
                          child: Center(
                            child: Icon(
                              Icons.arrow_drop_down_rounded,
                              size: cellSize * 0.7,
                              color: (_isMyTurn && isLegal && !_aiThinking)
                                  ? _kPrimary
                                  : Colors.transparent,
                            ),
                          ),
                        ),
                      );
                    }),
                  ),
                ),
                // Board
                Expanded(
                  child: Container(
                    decoration: BoxDecoration(
                      color: const Color(0xFFE8E8E8),
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: Column(
                      children: List.generate(Connect4Engine.rows, (r) {
                        return Expanded(
                          child: Row(
                            children: List.generate(Connect4Engine.cols, (c) {
                              return _buildCell(r, c, cellSize);
                            }),
                          ),
                        );
                      }),
                    ),
                  ),
                ),
              ],
            ),
          );
        },
      ),
    );
  }

  Widget _buildCell(int row, int col, double cellSize) {
    int val = _engine.board[row][col];
    bool isAnimating = (_animCol == col && _animRow == row);
    final isWin = _isWinCell(row, col);

    Widget disc;
    if (isAnimating) {
      disc = AnimatedBuilder(
        animation: _dropAnim!,
        builder: (context, _) {
          return _discWidget(_animPlayer, cellSize, isWin);
        },
      );
    } else if (val != 0) {
      disc = _discWidget(val, cellSize, isWin);
    } else {
      disc = Container(
        width: cellSize * 0.7,
        height: cellSize * 0.7,
        decoration: const BoxDecoration(
          shape: BoxShape.circle,
          color: Colors.white,
        ),
      );
    }

    return GestureDetector(
      onTap: () => _onColumnTap(col),
      child: SizedBox(
        width: cellSize,
        height: cellSize,
        child: Center(child: disc),
      ),
    );
  }

  Widget _discWidget(int player, double cellSize, bool isWin) {
    return Container(
      width: cellSize * 0.7,
      height: cellSize * 0.7,
      decoration: BoxDecoration(
        shape: BoxShape.circle,
        color: player == 1 ? _kPrimary : Colors.white,
        border: Border.all(
          color: isWin ? Colors.amber : _kPrimary,
          width: isWin ? 3 : 2,
        ),
        boxShadow: isWin
            ? [BoxShadow(color: Colors.amber.withAlpha(100), blurRadius: 8)]
            : null,
      ),
    );
  }

  Widget _buildGameOver() {
    final won = _winnerPlayer == 1;
    final draw = _winnerPlayer == null;

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
                  draw
                      ? Icons.handshake_rounded
                      : won
                          ? Icons.emoji_events_rounded
                          : Icons.sentiment_neutral_rounded,
                  size: 64,
                  color: _kPrimary,
                ),
                const SizedBox(height: 16),
                Text(
                  draw
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
                  draw
                      ? 'Sare!'
                      : won
                          ? 'Umeshinda!'
                          : 'Umeshindwa!',
                  style: const TextStyle(fontSize: 14, color: _kSecondary),
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
}

/// Thin AnimatedBuilder wrapper.
class AnimatedBuilder extends AnimatedWidget {
  final Widget Function(BuildContext context, Widget? child) builder;

  const AnimatedBuilder({
    super.key,
    required Animation<double> animation,
    required this.builder,
  }) : super(listenable: animation);

  @override
  Widget build(BuildContext context) => builder(context, null);
}
