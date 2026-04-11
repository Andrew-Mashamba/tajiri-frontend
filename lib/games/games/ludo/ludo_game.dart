// lib/games/games/ludo/ludo_game.dart

import 'dart:async';
import 'dart:math';

import 'package:flutter/material.dart';

import '../../core/game_context.dart' as gc;
import '../../core/game_enums.dart';
import '../../core/game_interface.dart';
import 'ludo_engine.dart';
import 'ludo_board_painter.dart';

const Color _kPrimary = Color(0xFF1A1A1A);
const Color _kSecondary = Color(0xFF666666);

class LudoGame extends StatefulWidget {
  final gc.GameContext gameContext;
  const LudoGame({super.key, required this.gameContext});

  @override
  State<LudoGame> createState() => LudoGameState();
}

class LudoGameState extends State<LudoGame> implements GameInterface {
  late LudoBoard _board;
  late Random _rng;
  bool _gameOver = false;
  int _myPlayer = 0; // Player 1
  bool _needsRoll = true;
  bool _rolling = false;
  int _displayDice = 1;
  int? _currentDice;
  List<LudoMove> _legalMoves = [];
  Timer? _rollTimer;

  gc.GameContext get _ctx => widget.gameContext;
  bool get _isMyTurn => _board.currentPlayer == _myPlayer;

  @override
  String get gameId => 'ludo';

  @override
  void initState() {
    super.initState();
    _rng = Random(_ctx.gameSeed.hashCode);
    _myPlayer = 0;
    if (_ctx.gameState != null) {
      _board = LudoBoard.fromJson(_ctx.gameState!);
    } else {
      _board = LudoBoard();
    }
    _ctx.setOnOpponentMove(onOpponentMove);
    if (!_isMyTurn && _ctx.mode == GameMode.practice) {
      _scheduleAiTurn();
    }
  }

  @override
  void dispose() {
    _rollTimer?.cancel();
    super.dispose();
  }

  void _onRollDice() {
    if (_gameOver || !_isMyTurn || !_needsRoll || _rolling) return;

    setState(() => _rolling = true);

    // Animate dice rolling
    int ticks = 0;
    _rollTimer?.cancel();
    _rollTimer = Timer.periodic(const Duration(milliseconds: 80), (timer) {
      if (!mounted) {
        timer.cancel();
        return;
      }
      setState(() {
        _displayDice = _rng.nextInt(6) + 1;
      });
      ticks++;
      if (ticks >= 6) {
        timer.cancel();
        final dice = _board.rollDice(_rng);
        final moves = _board.legalMoves(_myPlayer, dice);
        setState(() {
          _displayDice = dice;
          _currentDice = dice;
          _rolling = false;
          _needsRoll = false;
          _legalMoves = moves;
        });

        if (moves.isEmpty) {
          // No legal moves, pass turn
          Future.delayed(const Duration(milliseconds: 800), () {
            if (!mounted) return;
            setState(() {
              _board.currentPlayer = 1 - _board.currentPlayer;
              _board.consecutiveSixes = 0;
              _needsRoll = true;
              _currentDice = null;
              _legalMoves = [];
            });
            if (_ctx.mode == GameMode.practice) {
              _scheduleAiTurn();
            }
          });
        }
      }
    });
  }

  void _onTokenTap(int player, int tokenIndex) {
    if (_gameOver || !_isMyTurn || _needsRoll || _currentDice == null) return;

    final move = _legalMoves.where((m) =>
        m.player == player && m.tokenIndex == tokenIndex).firstOrNull;
    if (move == null) return;

    _board.makeMove(move);
    final bonusTurn = move.diceValue == 6 &&
        _board.currentPlayer == _myPlayer;

    setState(() {
      _currentDice = null;
      _legalMoves = [];
      _needsRoll = true;
    });

    _sendMove(move);
    _checkGameOver();

    if (!_gameOver && !bonusTurn && _ctx.mode == GameMode.practice) {
      _scheduleAiTurn();
    }
  }

  void _scheduleAiTurn() {
    Future.delayed(const Duration(milliseconds: 600), () {
      if (!mounted || _gameOver || _isMyTurn) return;
      _aiTurn();
    });
  }

  void _aiTurn() {
    final dice = _board.rollDice(_rng);
    final moves = _board.legalMoves(_board.currentPlayer, dice);

    setState(() {
      _displayDice = dice;
    });

    if (moves.isEmpty) {
      setState(() {
        _board.currentPlayer = 1 - _board.currentPlayer;
        _board.consecutiveSixes = 0;
        _needsRoll = true;
      });
      return;
    }

    final move = moves[_rng.nextInt(moves.length)];

    Future.delayed(const Duration(milliseconds: 400), () {
      if (!mounted) return;
      _board.makeMove(move);
      final bonusTurn = move.diceValue == 6 &&
          _board.currentPlayer == 1 - _myPlayer;
      setState(() {
        _needsRoll = true;
      });
      _checkGameOver();
      if (!_gameOver && bonusTurn) {
        _scheduleAiTurn();
      }
    });
  }

  void _checkGameOver() {
    if (_board.isGameOver()) {
      setState(() => _gameOver = true);
      final w = _board.winner();
      _ctx.onGameComplete({
        'winner_id': w == _myPlayer ? _ctx.userId : (_ctx.opponentId ?? 0),
        'player_1_score': w == 0 ? 1 : 0,
        'player_2_score': w == 1 ? 1 : 0,
      });
    }
  }

  void _sendMove(LudoMove move) {
    _ctx.socketService.sendMove(_ctx.userId, {
      'type': 'move',
      'move': move.toJson(),
      'state': _board.toJson(),
    });
  }

  @override
  void onOpponentMove(Map<String, dynamic> moveData) {
    if (moveData['state'] != null) {
      setState(() {
        _board =
            LudoBoard.fromJson(Map<String, dynamic>.from(moveData['state']));
        _needsRoll = true;
        _currentDice = null;
        _legalMoves = [];
      });
      _checkGameOver();
    }
  }

  @override
  void onReconnect(Map<String, dynamic> savedState) {
    setState(() {
      _board = LudoBoard.fromJson(savedState);
      _needsRoll = true;
      _currentDice = null;
      _legalMoves = [];
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
        _buildBoardWidget(),
        const SizedBox(height: 12),
        _buildDiceArea(),
        if (_gameOver) ...[
          const SizedBox(height: 12),
          _buildGameOverBanner(),
        ],
      ],
    );
  }

  Widget _buildStatusBar() {
    final turnText = _gameOver
        ? (_board.winner() == _myPlayer ? 'You win!' : 'You lose!')
        : (_isMyTurn ? 'Your turn' : 'Opponent\'s turn');
    final p1Finished =
        _board.tokens[0].where((t) => t.state == LudoTokenState.finished).length;
    final p2Finished =
        _board.tokens[1].where((t) => t.state == LudoTokenState.finished).length;
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(turnText,
              style: const TextStyle(
                  fontSize: 16, fontWeight: FontWeight.w600, color: _kPrimary)),
          Text('You: $p1Finished/4  Opp: $p2Finished/4',
              style: TextStyle(fontSize: 12, color: Colors.grey.shade600)),
        ],
      ),
    );
  }

  Widget _buildBoardWidget() {
    return Center(
      child: AspectRatio(
        aspectRatio: 1.0,
        child: Container(
          margin: const EdgeInsets.symmetric(horizontal: 16),
          decoration: BoxDecoration(
            border: Border.all(color: _kPrimary, width: 2),
            borderRadius: BorderRadius.circular(4),
          ),
          child: LayoutBuilder(
            builder: (context, constraints) {
              final size = constraints.biggest;
              final cellSize = size.width / 15;
              return Stack(
                children: [
                  CustomPaint(
                    size: size,
                    painter: LudoBoardPainter(),
                  ),
                  // Draw tokens
                  ..._buildTokenWidgets(cellSize),
                ],
              );
            },
          ),
        ),
      ),
    );
  }

  List<Widget> _buildTokenWidgets(double cellSize) {
    final widgets = <Widget>[];
    final legalTokens = _legalMoves
        .map((m) => '${m.player}_${m.tokenIndex}')
        .toSet();

    for (int p = 0; p < 2; p++) {
      for (int i = 0; i < 4; i++) {
        final token = _board.tokens[p][i];
        Offset pos;

        if (token.state == LudoTokenState.home) {
          pos = homeBasePosition(p, i, cellSize);
        } else if (token.state == LudoTokenState.finished) {
          // Place finished tokens in center area
          pos = Offset((6.5 + i * 0.5) * cellSize, (p == 0 ? 6.5 : 7.5) * cellSize);
        } else if (token.homeProgress > 0) {
          pos = homeColumnPosition(p, token.homeProgress, cellSize);
        } else {
          pos = squareToGridPosition(token.position, cellSize);
        }

        final isLegal = legalTokens.contains('${p}_$i');
        final tokenColor = p == 0 ? _kPrimary : _kSecondary;
        final tokenSize = cellSize * 0.7;

        widgets.add(
          Positioned(
            left: pos.dx + (cellSize - tokenSize) / 2,
            top: pos.dy + (cellSize - tokenSize) / 2,
            child: GestureDetector(
              onTap: () => _onTokenTap(p, i),
              child: AnimatedContainer(
                duration: const Duration(milliseconds: 200),
                width: tokenSize,
                height: tokenSize,
                decoration: BoxDecoration(
                  color: tokenColor,
                  shape: BoxShape.circle,
                  border: Border.all(
                    color: isLegal ? Colors.green : Colors.white,
                    width: isLegal ? 2.5 : 1.5,
                  ),
                  boxShadow: [
                    BoxShadow(
                      color: Colors.black.withValues(alpha: 0.3),
                      blurRadius: 2,
                      offset: const Offset(0, 1),
                    ),
                  ],
                ),
                alignment: Alignment.center,
                child: Text(
                  '${i + 1}',
                  style: TextStyle(
                    color: Colors.white,
                    fontSize: tokenSize * 0.45,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ),
            ),
          ),
        );
      }
    }
    return widgets;
  }

  Widget _buildDiceArea() {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 40),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          // Dice display
          Container(
            width: 56,
            height: 56,
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(10),
              border: Border.all(color: _kPrimary, width: 2),
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withValues(alpha: 0.15),
                  blurRadius: 4,
                  offset: const Offset(0, 2),
                ),
              ],
            ),
            alignment: Alignment.center,
            child: Text(
              _rolling ? '$_displayDice' : '${_currentDice ?? _displayDice}',
              style: const TextStyle(
                  fontSize: 28,
                  fontWeight: FontWeight.bold,
                  color: _kPrimary),
            ),
          ),
          const SizedBox(width: 16),
          // Roll button
          GestureDetector(
            onTap: _onRollDice,
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
              decoration: BoxDecoration(
                color: _isMyTurn && _needsRoll && !_rolling
                    ? _kPrimary
                    : Colors.grey.shade300,
                borderRadius: BorderRadius.circular(8),
              ),
              child: Text(
                _isMyTurn ? 'Roll / Ruka Dadu' : 'Wait...',
                style: TextStyle(
                  fontSize: 14,
                  fontWeight: FontWeight.w600,
                  color: _isMyTurn && _needsRoll && !_rolling
                      ? Colors.white
                      : Colors.grey.shade600,
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildGameOverBanner() {
    final w = _board.winner();
    final text = w == _myPlayer ? 'You won!' : 'You lost';
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
