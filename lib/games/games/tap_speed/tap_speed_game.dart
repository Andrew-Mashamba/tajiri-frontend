// lib/games/games/tap_speed/tap_speed_game.dart

import 'dart:async';

import 'package:flutter/material.dart';

import '../../core/game_context.dart' as gc;
import '../../core/game_enums.dart';
import '../../core/game_interface.dart';

const Color _kPrimary = Color(0xFF1A1A1A);

class TapSpeedGame extends StatefulWidget {
  final gc.GameContext gameContext;
  const TapSpeedGame({super.key, required this.gameContext});

  @override
  State<TapSpeedGame> createState() => TapSpeedGameState();
}

class TapSpeedGameState extends State<TapSpeedGame>
    with SingleTickerProviderStateMixin
    implements GameInterface {
  int _tapCount = 0;
  int _timeRemainingTenths = 100; // 10.0 seconds in tenths
  bool _isRunning = false;
  bool _gameOver = false;
  Timer? _timer;
  double _scale = 1.0;

  gc.GameContext get _ctx => widget.gameContext;

  @override
  String get gameId => 'tap_speed';

  @override
  void initState() {
    super.initState();
  }

  @override
  void dispose() {
    _timer?.cancel();
    super.dispose();
  }

  void _startTimer() {
    _isRunning = true;
    _timer = Timer.periodic(const Duration(milliseconds: 100), (timer) {
      if (!mounted) {
        timer.cancel();
        return;
      }
      setState(() {
        _timeRemainingTenths--;
      });
      if (_timeRemainingTenths <= 0) {
        timer.cancel();
        _endGame();
      }
    });
  }

  void _onTap() {
    if (_gameOver) return;
    if (!_isRunning) {
      _startTimer();
    }
    setState(() {
      _tapCount++;
      _scale = 0.95;
    });
    // Animate back
    Future.delayed(const Duration(milliseconds: 80), () {
      if (mounted) {
        setState(() {
          _scale = 1.0;
        });
      }
    });
  }

  void _endGame() {
    setState(() {
      _gameOver = true;
    });
    final winnerId = (_ctx.mode == GameMode.practice)
        ? (_tapCount > 0 ? _ctx.userId : null)
        : _ctx.userId;
    _ctx.onGameComplete({
      'winner_id': winnerId,
      'player_1_score': _tapCount,
      'player_2_score': 0,
    });
  }

  double get _tapsPerSecond {
    if (!_isRunning || _tapCount == 0) return 0.0;
    final elapsed = (100 - _timeRemainingTenths) / 10.0;
    if (elapsed <= 0) return 0.0;
    return _tapCount / elapsed;
  }

  @override
  void onOpponentMove(Map<String, dynamic> moveData) {}

  @override
  void onReconnect(Map<String, dynamic> savedState) {
    setState(() {
      _tapCount = savedState['tapCount'] as int? ?? 0;
      _timeRemainingTenths = savedState['timeRemainingTenths'] as int? ?? 100;
    });
  }

  @override
  Map<String, dynamic> getCurrentState() {
    return {
      'tapCount': _tapCount,
      'timeRemainingTenths': _timeRemainingTenths,
    };
  }

  @override
  Widget build(BuildContext context) {
    if (_gameOver) return _buildGameOver();

    final seconds = _timeRemainingTenths / 10.0;
    final fraction = _timeRemainingTenths / 100.0;

    return Scaffold(
      backgroundColor: Colors.white,
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              _buildTimerBar(fraction, seconds),
              const Spacer(),
              if (!_isRunning)
                const Text(
                  'Tap to start!\nGonga kuanza!',
                  style: TextStyle(
                    fontSize: 18,
                    color: Color(0xFF666666),
                    fontWeight: FontWeight.w500,
                  ),
                  textAlign: TextAlign.center,
                ),
              if (_isRunning) ...[
                Text(
                  '${_tapsPerSecond.toStringAsFixed(1)} taps/s',
                  style: const TextStyle(
                    fontSize: 16,
                    color: Color(0xFF666666),
                    fontWeight: FontWeight.w500,
                  ),
                  textAlign: TextAlign.center,
                ),
              ],
              const SizedBox(height: 24),
              Center(
                child: GestureDetector(
                  onTapDown: (_) => _onTap(),
                  child: AnimatedScale(
                    scale: _scale,
                    duration: const Duration(milliseconds: 80),
                    child: Container(
                      width: 200,
                      height: 200,
                      decoration: const BoxDecoration(
                        color: _kPrimary,
                        shape: BoxShape.circle,
                      ),
                      alignment: Alignment.center,
                      child: Text(
                        '$_tapCount',
                        style: const TextStyle(
                          fontSize: 48,
                          fontWeight: FontWeight.bold,
                          color: Colors.white,
                        ),
                      ),
                    ),
                  ),
                ),
              ),
              const Spacer(flex: 2),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildTimerBar(double fraction, double seconds) {
    Color color;
    if (seconds > 7) {
      color = Colors.green;
    } else if (seconds > 3) {
      color = Colors.orange;
    } else {
      color = Colors.red;
    }

    return Column(
      children: [
        ClipRRect(
          borderRadius: BorderRadius.circular(4),
          child: LinearProgressIndicator(
            value: fraction,
            backgroundColor: Colors.grey.shade200,
            valueColor: AlwaysStoppedAnimation(color),
            minHeight: 6,
          ),
        ),
        const SizedBox(height: 4),
        Text(
          '${seconds.toStringAsFixed(1)}s',
          style: TextStyle(
            fontSize: 13,
            color: color,
            fontWeight: FontWeight.w600,
          ),
        ),
      ],
    );
  }

  Widget _buildGameOver() {
    final tps = _tapCount / 10.0;

    return Scaffold(
      backgroundColor: Colors.white,
      body: SafeArea(
        child: Center(
          child: Padding(
            padding: const EdgeInsets.all(32),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                const Icon(Icons.touch_app_rounded, size: 64, color: _kPrimary),
                const SizedBox(height: 16),
                const Text(
                  'Game Over!',
                  style: TextStyle(
                    fontSize: 24,
                    fontWeight: FontWeight.bold,
                    color: _kPrimary,
                  ),
                ),
                const SizedBox(height: 4),
                const Text(
                  'Mchezo Umekwisha!',
                  style: TextStyle(fontSize: 14, color: Color(0xFF666666)),
                ),
                const SizedBox(height: 24),
                Text(
                  '$_tapCount',
                  style: const TextStyle(
                    fontSize: 48,
                    fontWeight: FontWeight.bold,
                    color: _kPrimary,
                  ),
                ),
                const Text(
                  'taps / migongo',
                  style: TextStyle(fontSize: 14, color: Color(0xFF666666)),
                ),
                const SizedBox(height: 8),
                Text(
                  '${tps.toStringAsFixed(1)} taps/second',
                  style: const TextStyle(
                    fontSize: 16,
                    color: Color(0xFF666666),
                  ),
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
