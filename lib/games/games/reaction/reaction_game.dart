// lib/games/games/reaction/reaction_game.dart

import 'dart:async';
import 'dart:math';

import 'package:flutter/material.dart';

import '../../core/game_context.dart' as gc;
import '../../core/game_enums.dart';
import '../../core/game_interface.dart';

const Color _kPrimary = Color(0xFF1A1A1A);

enum _RoundPhase { waiting, go, tapped, falseStart, result }

class ReactionGame extends StatefulWidget {
  final gc.GameContext gameContext;
  const ReactionGame({super.key, required this.gameContext});

  @override
  State<ReactionGame> createState() => ReactionGameState();
}

class ReactionGameState extends State<ReactionGame>
    implements GameInterface {
  late Random _rng;
  late List<int> _delays;
  int _currentRound = 0;
  _RoundPhase _phase = _RoundPhase.waiting;
  final List<int> _reactionTimes = [];
  Timer? _goTimer;
  Timer? _resultTimer;
  Stopwatch? _stopwatch;
  int _lastReactionMs = 0;
  bool _gameOver = false;

  gc.GameContext get _ctx => widget.gameContext;

  @override
  String get gameId => 'reaction';

  @override
  void initState() {
    super.initState();
    _rng = Random(_ctx.gameSeed.hashCode);
    _delays = List.generate(5, (_) => _rng.nextInt(4000) + 2000);
    _startRound();
  }

  @override
  void dispose() {
    _goTimer?.cancel();
    _resultTimer?.cancel();
    super.dispose();
  }

  void _startRound() {
    if (_currentRound >= 5) {
      _endGame();
      return;
    }
    setState(() {
      _phase = _RoundPhase.waiting;
    });
    _goTimer = Timer(Duration(milliseconds: _delays[_currentRound]), () {
      if (!mounted) return;
      setState(() {
        _phase = _RoundPhase.go;
        _stopwatch = Stopwatch()..start();
      });
    });
  }

  void _onTap() {
    switch (_phase) {
      case _RoundPhase.waiting:
        // False start
        _goTimer?.cancel();
        setState(() {
          _phase = _RoundPhase.falseStart;
          _lastReactionMs = 500; // penalty
          _reactionTimes.add(500);
        });
        _resultTimer = Timer(const Duration(milliseconds: 1500), () {
          if (mounted) {
            _currentRound++;
            _startRound();
          }
        });
        break;
      case _RoundPhase.go:
        _stopwatch?.stop();
        final ms = _stopwatch?.elapsedMilliseconds ?? 999;
        setState(() {
          _phase = _RoundPhase.tapped;
          _lastReactionMs = ms;
          _reactionTimes.add(ms);
        });
        _resultTimer = Timer(const Duration(seconds: 2), () {
          if (mounted) {
            _currentRound++;
            _startRound();
          }
        });
        break;
      case _RoundPhase.falseStart:
      case _RoundPhase.tapped:
      case _RoundPhase.result:
        break;
    }
  }

  void _endGame() {
    setState(() {
      _gameOver = true;
    });
    final avg = _reactionTimes.isEmpty
        ? 999
        : _reactionTimes.reduce((a, b) => a + b) ~/ _reactionTimes.length;
    final score = max(0, 5000 - avg);
    final winnerId = (_ctx.mode == GameMode.practice)
        ? (score > 0 ? _ctx.userId : null)
        : _ctx.userId;
    _ctx.onGameComplete({
      'winner_id': winnerId,
      'player_1_score': score,
      'player_2_score': 0,
    });
  }

  String _reactionLabel(int ms) {
    if (ms < 200) return 'Lightning!';
    if (ms < 300) return 'Great!';
    if (ms < 500) return 'OK';
    return 'Slow';
  }

  Color _reactionColor(int ms) {
    if (ms < 200) return Colors.green;
    if (ms < 300) return Colors.blue;
    if (ms < 500) return Colors.orange;
    return Colors.red;
  }

  @override
  void onOpponentMove(Map<String, dynamic> moveData) {}

  @override
  void onReconnect(Map<String, dynamic> savedState) {
    setState(() {
      _currentRound = savedState['currentRound'] as int? ?? 0;
      final times = savedState['reactionTimes'];
      if (times is List) {
        _reactionTimes.clear();
        _reactionTimes.addAll(times.cast<int>());
      }
    });
  }

  @override
  Map<String, dynamic> getCurrentState() {
    return {
      'currentRound': _currentRound,
      'reactionTimes': List<int>.from(_reactionTimes),
    };
  }

  @override
  Widget build(BuildContext context) {
    if (_gameOver) return _buildSummary();

    Color bgColor;
    String mainText;
    String subText;

    switch (_phase) {
      case _RoundPhase.waiting:
        bgColor = const Color(0xFF444444);
        mainText = 'WAIT...';
        subText = 'SUBIRI...';
        break;
      case _RoundPhase.go:
        bgColor = const Color(0xFF2ECC71);
        mainText = 'TAP!';
        subText = 'GONGA!';
        break;
      case _RoundPhase.tapped:
        bgColor = Colors.white;
        mainText = '${_lastReactionMs}ms';
        subText = _reactionLabel(_lastReactionMs);
        break;
      case _RoundPhase.falseStart:
        bgColor = const Color(0xFFE74C3C);
        mainText = 'Too Early!';
        subText = 'Mapema sana! (+500ms)';
        break;
      case _RoundPhase.result:
        bgColor = Colors.white;
        mainText = '';
        subText = '';
        break;
    }

    final isLight = _phase == _RoundPhase.tapped || _phase == _RoundPhase.result;

    return GestureDetector(
      onTapDown: (_) => _onTap(),
      child: Scaffold(
        backgroundColor: bgColor,
        body: SafeArea(
          child: Column(
            children: [
              Padding(
                padding: const EdgeInsets.all(16),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text(
                      'Round ${_currentRound + 1}/5',
                      style: TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.w600,
                        color: isLight ? _kPrimary : Colors.white70,
                      ),
                    ),
                    _buildDotsIndicator(),
                  ],
                ),
              ),
              const Spacer(),
              Text(
                mainText,
                style: TextStyle(
                  fontSize: _phase == _RoundPhase.tapped ? 48 : 36,
                  fontWeight: FontWeight.bold,
                  color: _phase == _RoundPhase.tapped
                      ? _reactionColor(_lastReactionMs)
                      : (isLight ? _kPrimary : Colors.white),
                ),
              ),
              const SizedBox(height: 8),
              Text(
                subText,
                style: TextStyle(
                  fontSize: 18,
                  color: _phase == _RoundPhase.tapped
                      ? _reactionColor(_lastReactionMs)
                      : (isLight ? const Color(0xFF666666) : Colors.white70),
                ),
              ),
              const Spacer(),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildDotsIndicator() {
    return Row(
      children: List.generate(5, (i) {
        Color dotColor;
        if (i < _reactionTimes.length) {
          dotColor = _reactionColor(_reactionTimes[i]);
        } else if (i == _currentRound) {
          dotColor = Colors.white.withAlpha(180);
        } else {
          dotColor = Colors.white.withAlpha(80);
        }
        return Container(
          width: 10,
          height: 10,
          margin: const EdgeInsets.symmetric(horizontal: 3),
          decoration: BoxDecoration(
            color: dotColor,
            shape: BoxShape.circle,
          ),
        );
      }),
    );
  }

  Widget _buildSummary() {
    final avg = _reactionTimes.isEmpty
        ? 0
        : _reactionTimes.reduce((a, b) => a + b) ~/ _reactionTimes.length;
    final best = _reactionTimes.isEmpty
        ? 0
        : _reactionTimes.reduce(min);
    final worst = _reactionTimes.isEmpty
        ? 0
        : _reactionTimes.reduce(max);
    final score = max(0, 5000 - avg);

    return Scaffold(
      backgroundColor: Colors.white,
      body: SafeArea(
        child: Center(
          child: Padding(
            padding: const EdgeInsets.all(32),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                const Icon(Icons.flash_on_rounded, size: 64, color: _kPrimary),
                const SizedBox(height: 16),
                const Text(
                  'Results',
                  style: TextStyle(
                    fontSize: 24,
                    fontWeight: FontWeight.bold,
                    color: _kPrimary,
                  ),
                ),
                const SizedBox(height: 4),
                const Text(
                  'Matokeo',
                  style: TextStyle(fontSize: 14, color: Color(0xFF666666)),
                ),
                const SizedBox(height: 24),
                _statRow('Average / Wastani', '${avg}ms', _reactionColor(avg)),
                _statRow('Best / Bora', '${best}ms', _reactionColor(best)),
                _statRow('Worst / Mbaya', '${worst}ms', _reactionColor(worst)),
                const Divider(height: 32),
                Text(
                  '$score',
                  style: const TextStyle(
                    fontSize: 48,
                    fontWeight: FontWeight.bold,
                    color: _kPrimary,
                  ),
                ),
                const Text(
                  'points / pointi',
                  style: TextStyle(fontSize: 14, color: Color(0xFF666666)),
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

  Widget _statRow(String label, String value, Color color) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(
            label,
            style: const TextStyle(fontSize: 14, color: Color(0xFF666666)),
          ),
          Text(
            value,
            style: TextStyle(
              fontSize: 16,
              fontWeight: FontWeight.bold,
              color: color,
            ),
          ),
        ],
      ),
    );
  }
}
