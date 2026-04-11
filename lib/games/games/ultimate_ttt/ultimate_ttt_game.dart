// lib/games/games/ultimate_ttt/ultimate_ttt_game.dart

import 'dart:math';

import 'package:flutter/material.dart';

import '../../core/game_context.dart' as gc;
import '../../core/game_enums.dart';
import '../../core/game_interface.dart';
import 'ultimate_ttt_engine.dart';

const Color _kPrimary = Color(0xFF1A1A1A);
const Color _kSecondary = Color(0xFF666666);

class UltimateTttGame extends StatefulWidget {
  final gc.GameContext gameContext;
  const UltimateTttGame({super.key, required this.gameContext});

  @override
  State<UltimateTttGame> createState() => UltimateTttGameState();
}

class UltimateTttGameState extends State<UltimateTttGame>
    implements GameInterface {
  late Random _rng;
  late UltimateTttEngine _engine;
  gc.GameContext get _ctx => widget.gameContext;

  bool _gameOver = false;
  int? _winner; // null = draw, 1 = X, 2 = O
  int _playerMark = 1; // 1 = X
  int _moveCount = 0;

  @override
  String get gameId => 'ultimate_ttt';

  @override
  void initState() {
    super.initState();
    _rng = Random(_ctx.gameSeed.hashCode);
    _engine = UltimateTttEngine();
    // In multiplayer, player with lower userId is X
    if (_ctx.opponentId != null) {
      _playerMark = _ctx.userId < _ctx.opponentId! ? 1 : 2;
    }
    _ctx.setOnOpponentMove(onOpponentMove);
  }

  bool get _isPlayerTurn => _engine.currentPlayer == _playerMark;

  void _onCellTap(int board, int cell) {
    if (_gameOver) return;
    if (!_isPlayerTurn && _ctx.mode != GameMode.practice) return;

    final success = _engine.makeMove(board, cell);
    if (!success) return;

    _moveCount++;
    setState(() {});

    if (_engine.isGameOver()) {
      _finishGame();
      return;
    }

    if (_ctx.mode == GameMode.practice) {
      // AI move
      Future.delayed(const Duration(milliseconds: 400), () {
        if (mounted && !_gameOver) _aiMove();
      });
    } else {
      _ctx.socketService.sendMove(_ctx.userId, {
        'type': 'move',
        'board': board,
        'cell': cell,
      });
    }
  }

  void _aiMove() {
    final moves = _engine.legalMoves();
    if (moves.isEmpty) {
      _finishGame();
      return;
    }
    final move = moves[_rng.nextInt(moves.length)];
    _engine.makeMove(move.board, move.cell);
    _moveCount++;
    setState(() {});

    if (_engine.isGameOver()) {
      _finishGame();
    }
  }

  void _finishGame() {
    final w = _engine.winner();
    setState(() {
      _gameOver = true;
      _winner = (w != null && w != 0) ? w : null;
    });

    int? winnerId;
    if (_winner == _playerMark) {
      winnerId = _ctx.userId;
    } else if (_winner != null) {
      winnerId = _ctx.opponentId ?? 0;
    }

    _ctx.onGameComplete({
      'winner_id': winnerId,
      'player_1_score': _winner == 1 ? 1 : 0,
      'player_2_score': _winner == 2 ? 1 : 0,
    });
  }

  @override
  void onOpponentMove(Map<String, dynamic> moveData) {
    final board = moveData['board'] as int?;
    final cell = moveData['cell'] as int?;
    if (board == null || cell == null) return;
    _engine.makeMove(board, cell);
    _moveCount++;
    setState(() {});
    if (_engine.isGameOver()) {
      _finishGame();
    }
  }

  @override
  void onReconnect(Map<String, dynamic> savedState) {
    _engine = UltimateTttEngine.fromJson(savedState);
    setState(() {});
  }

  @override
  Map<String, dynamic> getCurrentState() => _engine.toJson();

  @override
  Widget build(BuildContext context) {
    if (_gameOver) return _buildGameOver();

    return Scaffold(
      backgroundColor: Colors.white,
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.all(12),
          child: Column(
            children: [
              _buildHeader(),
              const Spacer(),
              _buildMetaGrid(),
              const Spacer(),
              _buildTurnIndicator(),
              const SizedBox(height: 8),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildHeader() {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Text(
          'Moves: $_moveCount',
          style: const TextStyle(
            fontSize: 14,
            fontWeight: FontWeight.w600,
            color: _kSecondary,
          ),
        ),
        Row(
          children: [
            _buildMarkBadge(1, 'X'),
            const SizedBox(width: 8),
            _buildMarkBadge(2, 'O'),
          ],
        ),
      ],
    );
  }

  Widget _buildMarkBadge(int mark, String label) {
    final isActive = _engine.currentPlayer == mark;
    final isPlayer = mark == _playerMark;
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
      decoration: BoxDecoration(
        color: isActive ? _kPrimary : Colors.grey.shade100,
        borderRadius: BorderRadius.circular(12),
        border: isPlayer
            ? Border.all(color: _kPrimary, width: 2)
            : null,
      ),
      child: Text(
        label,
        style: TextStyle(
          color: isActive ? Colors.white : _kSecondary,
          fontWeight: FontWeight.bold,
          fontSize: 14,
        ),
      ),
    );
  }

  Widget _buildMetaGrid() {
    return AspectRatio(
      aspectRatio: 1,
      child: LayoutBuilder(
        builder: (context, constraints) {
          final size = constraints.maxWidth;
          final boardSize = (size - 8) / 3; // 4px gap between meta-cells

          return Column(
            mainAxisSize: MainAxisSize.min,
            children: List.generate(3, (metaRow) {
              return Row(
                mainAxisSize: MainAxisSize.min,
                children: List.generate(3, (metaCol) {
                  final boardIndex = metaRow * 3 + metaCol;
                  final isActive = _engine.activeBoard == null
                      ? _engine.boardWinners[boardIndex] == 0
                      : _engine.activeBoard == boardIndex;
                  final winner = _engine.boardWinners[boardIndex];

                  return Container(
                    width: boardSize,
                    height: boardSize,
                    margin: EdgeInsets.only(
                      right: metaCol < 2 ? 4 : 0,
                      bottom: metaRow < 2 ? 4 : 0,
                    ),
                    decoration: BoxDecoration(
                      borderRadius: BorderRadius.circular(6),
                      border: Border.all(
                        color: isActive && !_gameOver
                            ? _kPrimary
                            : Colors.grey.shade300,
                        width: isActive && !_gameOver ? 2 : 1,
                      ),
                      color: winner == 1
                          ? _kPrimary.withValues(alpha: 0.08)
                          : winner == 2
                              ? _kSecondary.withValues(alpha: 0.08)
                              : winner == 3
                                  ? Colors.grey.shade100
                                  : Colors.white,
                    ),
                    child: winner != 0 && winner != 3
                        ? Center(
                            child: Text(
                              winner == 1 ? 'X' : 'O',
                              style: TextStyle(
                                fontSize: boardSize * 0.5,
                                fontWeight: FontWeight.bold,
                                color: winner == 1
                                    ? _kPrimary.withValues(alpha: 0.3)
                                    : _kSecondary.withValues(alpha: 0.3),
                              ),
                            ),
                          )
                        : winner == 3
                            ? Center(
                                child: Icon(Icons.remove_rounded,
                                    size: boardSize * 0.3,
                                    color: Colors.grey.shade400),
                              )
                            : _buildSmallBoard(boardIndex, boardSize),
                  );
                }),
              );
            }),
          );
        },
      ),
    );
  }

  Widget _buildSmallBoard(int boardIndex, double boardSize) {
    final cellSize = (boardSize - 10) / 3; // padding
    return Padding(
      padding: const EdgeInsets.all(3),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: List.generate(3, (row) {
          return Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: List.generate(3, (col) {
              final cellIndex = row * 3 + col;
              final value = _engine.boards[boardIndex][cellIndex];
              return GestureDetector(
                onTap: () => _onCellTap(boardIndex, cellIndex),
                child: Container(
                  width: cellSize,
                  height: cellSize,
                  decoration: BoxDecoration(
                    border: Border(
                      right: col < 2
                          ? BorderSide(
                              color: Colors.grey.shade300, width: 0.5)
                          : BorderSide.none,
                      bottom: row < 2
                          ? BorderSide(
                              color: Colors.grey.shade300, width: 0.5)
                          : BorderSide.none,
                    ),
                  ),
                  child: Center(
                    child: value == 0
                        ? null
                        : Text(
                            value == 1 ? 'X' : 'O',
                            style: TextStyle(
                              fontSize: cellSize * 0.55,
                              fontWeight: FontWeight.bold,
                              color: value == 1 ? _kPrimary : _kSecondary,
                            ),
                          ),
                  ),
                ),
              );
            }),
          );
        }),
      ),
    );
  }

  Widget _buildTurnIndicator() {
    final mark = _engine.currentPlayer == 1 ? 'X' : 'O';
    final isYou = _isPlayerTurn;
    return Text(
      isYou ? 'Your turn ($mark)' : 'Opponent\'s turn ($mark)',
      style: const TextStyle(
        fontSize: 15,
        fontWeight: FontWeight.w600,
        color: _kPrimary,
      ),
    );
  }

  Widget _buildGameOver() {
    final playerWon = _winner == _playerMark;
    final isDraw = _winner == null;

    String title;
    String titleSw;
    if (isDraw) {
      title = 'Draw!';
      titleSw = 'Sare!';
    } else if (playerWon) {
      title = 'You Won!';
      titleSw = 'Umeshinda!';
    } else {
      title = 'You Lost';
      titleSw = 'Umeshindwa';
    }

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
                  isDraw
                      ? Icons.handshake_rounded
                      : playerWon
                          ? Icons.emoji_events_rounded
                          : Icons.sentiment_dissatisfied_rounded,
                  size: 64,
                  color: _kPrimary,
                ),
                const SizedBox(height: 16),
                Text(
                  title,
                  style: const TextStyle(
                    fontSize: 24,
                    fontWeight: FontWeight.bold,
                    color: _kPrimary,
                  ),
                ),
                Text(
                  titleSw,
                  style: const TextStyle(fontSize: 14, color: _kSecondary),
                ),
                const SizedBox(height: 16),
                Text(
                  '$_moveCount moves',
                  style: const TextStyle(fontSize: 16, color: _kSecondary),
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
                        borderRadius: BorderRadius.circular(12),
                      ),
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
