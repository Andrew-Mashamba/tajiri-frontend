// lib/games/games/bao/bao_game.dart

import 'dart:async';
import 'dart:math';

import 'package:flutter/material.dart';

import '../../core/game_context.dart' as gc;
import '../../core/game_enums.dart';
import '../../core/game_interface.dart';
import 'bao_engine.dart';

const Color _kPrimary = Color(0xFF1A1A1A);
const Color _kWood = Color(0xFFD4A76A);
const Color _kPit = Color(0xFF8B6914);
const Color _kKuuBorder = Color(0xFFDAA520);

class BaoGame extends StatefulWidget {
  final gc.GameContext gameContext;
  const BaoGame({super.key, required this.gameContext});

  @override
  State<BaoGame> createState() => BaoGameState();
}

class BaoGameState extends State<BaoGame> implements GameInterface {
  late BaoBoard _board;
  late Random _rng;
  bool _gameOver = false;
  bool _isMyTurn = true;
  bool _animating = false;
  int? _lastAnimPit;
  late BaoPlayer _myPlayer;

  gc.GameContext get _ctx => widget.gameContext;

  @override
  String get gameId => 'bao';

  @override
  void initState() {
    super.initState();
    _rng = Random(_ctx.gameSeed.hashCode);
    _myPlayer = BaoPlayer.south; // Player 1 = south
    if (_ctx.gameState != null) {
      _board = BaoBoard.fromJson(_ctx.gameState!);
    } else {
      _board = BaoBoard.initial();
    }
    _isMyTurn = _board.currentPlayer == _myPlayer;

    // Register for opponent moves delivered via GameContext
    _ctx.setOnOpponentMove(onOpponentMove);

    if (!_isMyTurn && _ctx.mode == GameMode.practice) {
      _scheduleAiMove();
    }
  }

  void _scheduleAiMove() {
    Future.delayed(const Duration(milliseconds: 600), () {
      if (!mounted || _gameOver) return;
      final moves = _board.legalMoves(_board.currentPlayer);
      if (moves.isEmpty) {
        _checkGameOver();
        return;
      }
      final pit = moves[_rng.nextInt(moves.length)];
      final steps = _board.makeMove(pit);
      _animateSteps(steps, () {
        if (!mounted) return;
        setState(() {
          _isMyTurn = true;
        });
        _checkGameOver();
      });
    });
  }

  void _onPitTap(int index) {
    if (_gameOver || !_isMyTurn || _animating) return;

    final legal = _board.legalMoves(_myPlayer);
    if (!legal.contains(index)) return;

    setState(() => _isMyTurn = false);
    final steps = _board.makeMove(index);

    _sendMove(index);
    _animateSteps(steps, () {
      if (!mounted) return;
      _checkGameOver();
      if (!_gameOver && _ctx.mode == GameMode.practice) {
        _scheduleAiMove();
      }
    });
  }

  void _animateSteps(List<BaoAnimStep> steps, VoidCallback onDone) {
    if (steps.isEmpty) {
      onDone();
      return;
    }
    setState(() => _animating = true);

    int i = 0;
    Timer.periodic(const Duration(milliseconds: 200), (timer) {
      if (!mounted) {
        timer.cancel();
        return;
      }
      if (i >= steps.length) {
        timer.cancel();
        setState(() {
          _animating = false;
          _lastAnimPit = null;
        });
        onDone();
        return;
      }
      setState(() {
        _lastAnimPit = steps[i].pitIndex;
      });
      i++;
    });
  }

  void _checkGameOver() {
    if (_board.isGameOver()) {
      setState(() => _gameOver = true);
      final w = _board.winner();
      int winnerId = 0;
      if (w == _myPlayer) {
        winnerId = _ctx.userId;
      } else if (w != null) {
        winnerId = _ctx.opponentId ?? 0;
      }
      _ctx.onGameComplete({
        'winner_id': winnerId,
        'player_1_score': w == _myPlayer ? 1 : 0,
        'player_2_score': w == _myPlayer.opponent ? 1 : 0,
      });
    }
  }

  void _sendMove(int pitIndex) {
    _ctx.socketService.sendMove(_ctx.userId, {
      'type': 'move',
      'pit': pitIndex,
      'state': _board.toJson(),
    });
  }

  @override
  void onOpponentMove(Map<String, dynamic> moveData) {
    if (moveData['state'] != null) {
      setState(() {
        _board = BaoBoard.fromJson(Map<String, dynamic>.from(moveData['state']));
        _isMyTurn = _board.currentPlayer == _myPlayer;
      });
      _checkGameOver();
    }
  }

  @override
  void onReconnect(Map<String, dynamic> savedState) {
    setState(() {
      _board = BaoBoard.fromJson(savedState);
      _isMyTurn = _board.currentPlayer == _myPlayer;
    });
  }

  @override
  Map<String, dynamic> getCurrentState() => _board.toJson();

  @override
  Widget build(BuildContext context) {
    final legal = _isMyTurn && !_animating
        ? _board.legalMoves(_myPlayer).toSet()
        : <int>{};

    return Column(
      children: [
        const SizedBox(height: 8),
        _buildHeader(),
        const SizedBox(height: 8),
        _buildStockBar(BaoPlayer.north),
        const SizedBox(height: 4),
        _buildBoardWidget(legal),
        const SizedBox(height: 4),
        _buildStockBar(BaoPlayer.south),
        const SizedBox(height: 8),
        if (_gameOver) _buildGameOverBanner(),
      ],
    );
  }

  Widget _buildHeader() {
    final phaseText = _board.phase == BaoPhase.namua ? 'Namua' : 'Mtaji';
    final turnText = _gameOver
        ? (_board.winner() == _myPlayer ? 'You win!' : 'You lose!')
        : (_isMyTurn ? 'Your turn' : 'Opponent\'s turn');
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(turnText,
              style: const TextStyle(
                  fontSize: 16, fontWeight: FontWeight.w600, color: _kPrimary)),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
            decoration: BoxDecoration(
              color: _kPrimary,
              borderRadius: BorderRadius.circular(12),
            ),
            child: Text(phaseText,
                style: const TextStyle(
                    fontSize: 12,
                    fontWeight: FontWeight.w600,
                    color: Colors.white)),
          ),
        ],
      ),
    );
  }

  Widget _buildStockBar(BaoPlayer player) {
    final stock =
        player == BaoPlayer.north ? _board.northStock : _board.southStock;
    final label = player == BaoPlayer.north ? 'North' : 'South';
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16),
      child: Row(
        mainAxisAlignment: player == BaoPlayer.north
            ? MainAxisAlignment.start
            : MainAxisAlignment.end,
        children: [
          Text('$label Stock: $stock',
              style: TextStyle(
                  fontSize: 13,
                  fontWeight: FontWeight.w500,
                  color: Colors.grey.shade700)),
        ],
      ),
    );
  }

  Widget _buildBoardWidget(Set<int> legal) {
    // Board: 4 rows x 8 cols
    // Row 0 = north outer (0-7), Row 1 = north inner (8-15)
    // Row 2 = south inner (16-23), Row 3 = south outer (24-31)
    return Center(
      child: Container(
        margin: const EdgeInsets.symmetric(horizontal: 12),
        padding: const EdgeInsets.all(8),
        decoration: BoxDecoration(
          color: _kWood,
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: Colors.brown.shade600, width: 2),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withValues(alpha: 0.2),
              blurRadius: 6,
              offset: const Offset(0, 3),
            ),
          ],
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            _buildPitRow(0, 7, legal),  // north outer
            const SizedBox(height: 4),
            _buildPitRow(8, 15, legal),  // north inner
            Padding(
              padding: const EdgeInsets.symmetric(vertical: 4),
              child: Container(
                height: 2,
                color: Colors.brown.shade700,
              ),
            ),
            _buildPitRow(16, 23, legal), // south inner
            const SizedBox(height: 4),
            _buildPitRow(24, 31, legal), // south outer
          ],
        ),
      ),
    );
  }

  Widget _buildPitRow(int start, int end, Set<int> legal) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceEvenly,
      children: List.generate(end - start + 1, (i) {
        final pitIndex = start + i;
        return _buildPit(pitIndex, legal.contains(pitIndex));
      }),
    );
  }

  Widget _buildPit(int index, bool isLegal) {
    final isKuu = index == BaoBoard.northKuu || index == BaoBoard.southKuu;
    final isAnimTarget = _lastAnimPit == index;
    final seeds = _board.pits[index];
    final size = isKuu ? 40.0 : 36.0;

    return GestureDetector(
      onTap: () => _onPitTap(index),
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 150),
        width: size,
        height: size,
        decoration: BoxDecoration(
          color: isAnimTarget ? Colors.red.shade300 : _kPit,
          shape: BoxShape.circle,
          border: Border.all(
            color: isKuu
                ? _kKuuBorder
                : (isLegal ? Colors.green : Colors.brown.shade800),
            width: isKuu || isLegal ? 2.5 : 1.5,
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
          '$seeds',
          style: TextStyle(
            fontSize: isKuu ? 14 : 12,
            fontWeight: FontWeight.bold,
            color: Colors.white,
          ),
        ),
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
