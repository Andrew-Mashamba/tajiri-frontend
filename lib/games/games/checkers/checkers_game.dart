// lib/games/games/checkers/checkers_game.dart

import 'dart:async';
import 'dart:math';

import 'package:flutter/material.dart';

import '../../core/game_context.dart' as gc;
import '../../core/game_enums.dart';
import '../../core/game_interface.dart';
import 'checkers_engine.dart';

const Color _kPrimary = Color(0xFF1A1A1A);
const Color _kLightSquare = Color(0xFFEEEED2);
const Color _kDarkSquare = Color(0xFF769656);

class CheckersGame extends StatefulWidget {
  final gc.GameContext gameContext;
  const CheckersGame({super.key, required this.gameContext});

  @override
  State<CheckersGame> createState() => CheckersGameState();
}

class CheckersGameState extends State<CheckersGame> implements GameInterface {
  late CheckersBoard _board;
  late Random _rng;
  int? _selectedSquare;
  List<CheckersMove> _legalForSelected = [];
  bool _gameOver = false;
  bool _isMyTurn = true;
  late CheckersPlayer _myColor;

  gc.GameContext get _ctx => widget.gameContext;

  @override
  String get gameId => 'checkers';

  @override
  void initState() {
    super.initState();
    _rng = Random(_ctx.gameSeed.hashCode);
    _myColor = CheckersPlayer.dark; // Player 1 is dark
    if (_ctx.gameState != null) {
      _board = CheckersBoard.fromJson(_ctx.gameState!);
    } else {
      _board = CheckersBoard.initial();
    }
    _isMyTurn = _board.currentPlayer == _myColor;

    // Register for opponent moves delivered via GameContext
    _ctx.setOnOpponentMove(onOpponentMove);

    if (!_isMyTurn && _ctx.mode == GameMode.practice) {
      _scheduleAiMove();
    }
  }

  void _scheduleAiMove() {
    Future.delayed(const Duration(milliseconds: 500), () {
      if (!mounted || _gameOver) return;
      final moves = _board.legalMoves(_board.currentPlayer);
      if (moves.isEmpty) {
        _checkGameOver();
        return;
      }
      final move = moves[_rng.nextInt(moves.length)];
      setState(() {
        _board.makeMove(move);
        _isMyTurn = true;
      });
      _checkGameOver();
    });
  }

  void _onSquareTap(int index) {
    if (_gameOver || !_isMyTurn) return;

    final piece = _board.squares[index];
    final allMoves = _board.legalMoves(_myColor);

    // Tapping a legal move target
    if (_selectedSquare != null) {
      final move = _legalForSelected.where((m) => m.to == index).firstOrNull;
      if (move != null) {
        setState(() {
          _board.makeMove(move);
          _selectedSquare = null;
          _legalForSelected = [];
          _isMyTurn = false;
        });
        _sendMove(move);
        _checkGameOver();
        if (!_gameOver && _ctx.mode == GameMode.practice) {
          _scheduleAiMove();
        }
        return;
      }
    }

    // Selecting own piece
    if (piece != null && piece.owner == _myColor) {
      final movesForPiece = allMoves.where((m) => m.from == index).toList();
      if (movesForPiece.isNotEmpty) {
        setState(() {
          _selectedSquare = index;
          _legalForSelected = movesForPiece;
        });
      }
    } else {
      setState(() {
        _selectedSquare = null;
        _legalForSelected = [];
      });
    }
  }

  void _checkGameOver() {
    if (_board.isGameOver()) {
      setState(() => _gameOver = true);
      final w = _board.winner();
      int winnerId;
      if (w == null) {
        winnerId = 0; // draw
      } else if (w == _myColor) {
        winnerId = _ctx.userId;
      } else {
        winnerId = _ctx.opponentId ?? 0;
      }
      _ctx.onGameComplete({
        'winner_id': winnerId,
        'player_1_score': w == _myColor ? 1 : 0,
        'player_2_score': w == _myColor.opponent ? 1 : 0,
      });
    }
  }

  void _sendMove(CheckersMove move) {
    _ctx.socketService.sendMove(_ctx.userId, {
      'type': 'move',
      'move': move.toJson(),
      'state': _board.toJson(),
    });
  }

  @override
  void onOpponentMove(Map<String, dynamic> moveData) {
    if (moveData['move'] != null) {
      final move = CheckersMove.fromJson(
          Map<String, dynamic>.from(moveData['move']));
      setState(() {
        _board.makeMove(move);
        _isMyTurn = true;
      });
      _checkGameOver();
    }
  }

  @override
  void onReconnect(Map<String, dynamic> savedState) {
    setState(() {
      _board = CheckersBoard.fromJson(savedState);
      _isMyTurn = _board.currentPlayer == _myColor;
    });
  }

  @override
  Map<String, dynamic> getCurrentState() => _board.toJson();

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        const SizedBox(height: 8),
        _buildStatusBar(),
        const SizedBox(height: 8),
        _buildBoard(),
        const SizedBox(height: 12),
        if (_gameOver) _buildGameOverBanner(),
      ],
    );
  }

  Widget _buildStatusBar() {
    final turnText = _gameOver
        ? (_board.winner() == null
            ? 'Draw!'
            : (_board.winner() == _myColor ? 'You win!' : 'You lose!'))
        : (_isMyTurn ? 'Your turn' : 'Opponent\'s turn');
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(turnText,
              style: const TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.w600,
                  color: _kPrimary)),
          Text(
            'Moves w/o capture: ${_board.movesWithoutCapture}/40',
            style: TextStyle(fontSize: 12, color: Colors.grey.shade600),
          ),
        ],
      ),
    );
  }

  Widget _buildBoard() {
    final legalTargets = _legalForSelected.map((m) => m.to).toSet();

    return Center(
      child: AspectRatio(
        aspectRatio: 1.0,
        child: Container(
          margin: const EdgeInsets.symmetric(horizontal: 16),
          decoration: BoxDecoration(
            border: Border.all(color: _kPrimary, width: 2),
            borderRadius: BorderRadius.circular(4),
          ),
          child: GridView.builder(
            physics: const NeverScrollableScrollPhysics(),
            gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
              crossAxisCount: 8,
            ),
            itemCount: 64,
            itemBuilder: (context, index) {
              final row = index ~/ 8;
              final col = index % 8;
              final isDark = (row + col) % 2 == 1;
              final piece = _board.squares[index];
              final isSelected = index == _selectedSquare;
              final isTarget = legalTargets.contains(index);

              return GestureDetector(
                onTap: () => _onSquareTap(index),
                child: Container(
                  decoration: BoxDecoration(
                    color: isDark ? _kDarkSquare : _kLightSquare,
                    border: isSelected
                        ? Border.all(color: Colors.blue, width: 2)
                        : null,
                  ),
                  child: Stack(
                    alignment: Alignment.center,
                    children: [
                      if (isTarget)
                        Container(
                          width: 16,
                          height: 16,
                          decoration: BoxDecoration(
                            color: Colors.green.withValues(alpha: 0.6),
                            shape: BoxShape.circle,
                          ),
                        ),
                      if (piece != null) _buildPiece(piece),
                    ],
                  ),
                ),
              );
            },
          ),
        ),
      ),
    );
  }

  Widget _buildPiece(CheckersPiece piece) {
    final color = piece.owner == CheckersPlayer.dark
        ? _kPrimary
        : Colors.white;
    final borderColor = piece.owner == CheckersPlayer.dark
        ? Colors.grey.shade700
        : Colors.grey.shade400;

    return FractionallySizedBox(
      widthFactor: 0.75,
      heightFactor: 0.75,
      child: Container(
        decoration: BoxDecoration(
          color: color,
          shape: BoxShape.circle,
          border: Border.all(color: borderColor, width: 2),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withValues(alpha: 0.3),
              blurRadius: 2,
              offset: const Offset(1, 1),
            ),
          ],
        ),
        child: piece.isKing
            ? Icon(
                Icons.star_rounded,
                color: piece.owner == CheckersPlayer.dark
                    ? Colors.amber
                    : Colors.amber.shade700,
                size: 18,
              )
            : null,
      ),
    );
  }

  Widget _buildGameOverBanner() {
    final w = _board.winner();
    final text = w == null
        ? 'Game ended in a draw'
        : (w == _myColor ? 'You won!' : 'You lost');
    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 16),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.grey.shade100,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: Colors.grey.shade200),
      ),
      child: Text(
        text,
        textAlign: TextAlign.center,
        style: const TextStyle(
            fontSize: 18, fontWeight: FontWeight.bold, color: _kPrimary),
      ),
    );
  }
}
