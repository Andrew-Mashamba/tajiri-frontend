// lib/games/games/speed_math/speed_math_game.dart

import 'dart:async';
import 'dart:math';

import 'package:flutter/material.dart';

import '../../core/game_context.dart' as gc;
import '../../core/game_enums.dart';
import '../../core/game_interface.dart';

const Color _kPrimary = Color(0xFF1A1A1A);

class SpeedMathGame extends StatefulWidget {
  final gc.GameContext gameContext;
  const SpeedMathGame({super.key, required this.gameContext});

  @override
  State<SpeedMathGame> createState() => SpeedMathGameState();
}

class SpeedMathGameState extends State<SpeedMathGame>
    implements GameInterface {
  late Random _rng;
  int _score = 0;
  int _problemCount = 0;
  int _correctCount = 0;
  int _timeRemaining = 60;
  bool _gameOver = false;
  Timer? _timer;

  String _expression = '';
  int _correctAnswer = 0;
  List<int> _choices = [];
  int _selectedAnswer = -1;
  bool _showingResult = false;
  Timer? _resultTimer;

  gc.GameContext get _ctx => widget.gameContext;

  @override
  String get gameId => 'speed_math';

  @override
  void initState() {
    super.initState();
    _rng = Random(_ctx.gameSeed.hashCode);
    _generateProblem();
    _startTimer();
  }

  @override
  void dispose() {
    _timer?.cancel();
    _resultTimer?.cancel();
    super.dispose();
  }

  void _startTimer() {
    _timer = Timer.periodic(const Duration(seconds: 1), (timer) {
      if (!mounted) {
        timer.cancel();
        return;
      }
      setState(() {
        _timeRemaining--;
      });
      if (_timeRemaining <= 0) {
        timer.cancel();
        _endGame();
      }
    });
  }

  void _generateProblem() {
    int a, b, answer;
    String op;

    if (_problemCount < 5) {
      // Easy: single digit add/subtract
      a = _rng.nextInt(9) + 1;
      b = _rng.nextInt(9) + 1;
      if (_rng.nextBool()) {
        op = '+';
        answer = a + b;
      } else {
        // Ensure no negative results
        if (a < b) {
          final tmp = a;
          a = b;
          b = tmp;
        }
        op = '-';
        answer = a - b;
      }
    } else if (_problemCount < 10) {
      // Medium: double digit add/subtract
      a = _rng.nextInt(90) + 10;
      b = _rng.nextInt(90) + 10;
      if (_rng.nextBool()) {
        op = '+';
        answer = a + b;
      } else {
        if (a < b) {
          final tmp = a;
          a = b;
          b = tmp;
        }
        op = '-';
        answer = a - b;
      }
    } else {
      // Hard: include multiplication
      final opChoice = _rng.nextInt(3);
      if (opChoice == 0) {
        a = _rng.nextInt(90) + 10;
        b = _rng.nextInt(90) + 10;
        op = '+';
        answer = a + b;
      } else if (opChoice == 1) {
        a = _rng.nextInt(90) + 10;
        b = _rng.nextInt(90) + 10;
        if (a < b) {
          final tmp = a;
          a = b;
          b = tmp;
        }
        op = '-';
        answer = a - b;
      } else {
        a = _rng.nextInt(12) + 2;
        b = _rng.nextInt(12) + 2;
        op = 'x';
        answer = a * b;
      }
    }

    _expression = '$a $op $b = ?';
    _correctAnswer = answer;
    _choices = _makeChoices(answer);
    _selectedAnswer = -1;
    _showingResult = false;
    _problemCount++;
  }

  List<int> _makeChoices(int correct) {
    final Set<int> choices = {correct};
    while (choices.length < 4) {
      final offset = _rng.nextInt(10) + 1;
      final d = _rng.nextBool() ? correct + offset : correct - offset;
      if (d >= 0 && d != correct) {
        choices.add(d);
      }
    }
    final list = choices.toList();
    list.shuffle(_rng);
    return list;
  }

  void _selectAnswer(int index) {
    if (_showingResult || _gameOver) return;

    final chosen = _choices[index];
    final isCorrect = chosen == _correctAnswer;
    int points = 0;
    if (isCorrect) {
      points = 10;
      // Speed bonus based on remaining time proportion
      if (_timeRemaining > 45) {
        points += 5;
      } else if (_timeRemaining > 30) {
        points += 3;
      } else if (_timeRemaining > 15) {
        points += 1;
      }
      _correctCount++;
    }

    setState(() {
      _selectedAnswer = index;
      _showingResult = true;
      _score += points;
    });

    _resultTimer = Timer(const Duration(milliseconds: 400), () {
      if (mounted && !_gameOver) {
        setState(() {
          _generateProblem();
        });
      }
    });
  }

  void _endGame() {
    setState(() {
      _gameOver = true;
    });
    final winnerId = (_ctx.mode == GameMode.practice)
        ? (_score > 0 ? _ctx.userId : null)
        : _ctx.userId;
    _ctx.onGameComplete({
      'winner_id': winnerId,
      'player_1_score': _score,
      'player_2_score': 0,
    });
  }

  @override
  void onOpponentMove(Map<String, dynamic> moveData) {}

  @override
  void onReconnect(Map<String, dynamic> savedState) {
    setState(() {
      _score = savedState['score'] as int? ?? 0;
      _timeRemaining = savedState['timeRemaining'] as int? ?? 60;
      _problemCount = savedState['problemCount'] as int? ?? 0;
    });
  }

  @override
  Map<String, dynamic> getCurrentState() {
    return {
      'score': _score,
      'timeRemaining': _timeRemaining,
      'problemCount': _problemCount,
    };
  }

  @override
  Widget build(BuildContext context) {
    if (_gameOver) return _buildGameOver();

    return Scaffold(
      backgroundColor: Colors.white,
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              _buildHeader(),
              const SizedBox(height: 8),
              _buildTimerBar(),
              const Spacer(),
              _buildProblem(),
              const SizedBox(height: 32),
              _buildChoices(),
              const Spacer(flex: 2),
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
          'Problem #$_problemCount',
          style: const TextStyle(
            fontSize: 14,
            fontWeight: FontWeight.w600,
            color: Color(0xFF666666),
          ),
        ),
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
          decoration: BoxDecoration(
            color: _kPrimary,
            borderRadius: BorderRadius.circular(12),
          ),
          child: Text(
            'Score: $_score',
            style: const TextStyle(
              color: Colors.white,
              fontWeight: FontWeight.w600,
              fontSize: 14,
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildTimerBar() {
    final fraction = _timeRemaining / 60.0;
    Color color;
    if (_timeRemaining > 30) {
      color = Colors.green;
    } else if (_timeRemaining > 10) {
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
          '${_timeRemaining}s',
          style: TextStyle(
            fontSize: 13,
            color: color,
            fontWeight: FontWeight.w600,
          ),
        ),
      ],
    );
  }

  Widget _buildProblem() {
    return Text(
      _expression,
      style: const TextStyle(
        fontSize: 36,
        fontWeight: FontWeight.bold,
        color: _kPrimary,
      ),
      textAlign: TextAlign.center,
    );
  }

  Widget _buildChoices() {
    return GridView.count(
      crossAxisCount: 2,
      mainAxisSpacing: 12,
      crossAxisSpacing: 12,
      childAspectRatio: 2.5,
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      children: List.generate(4, (i) {
        Color bg = Colors.grey.shade100;
        Color textColor = _kPrimary;
        if (_showingResult) {
          if (_choices[i] == _correctAnswer) {
            bg = Colors.green;
            textColor = Colors.white;
          } else if (i == _selectedAnswer && _choices[i] != _correctAnswer) {
            bg = Colors.red;
            textColor = Colors.white;
          }
        }

        return SizedBox(
          height: 52,
          child: ElevatedButton(
            onPressed: _showingResult ? null : () => _selectAnswer(i),
            style: ElevatedButton.styleFrom(
              backgroundColor: bg,
              foregroundColor: textColor,
              elevation: 0,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(12),
                side: BorderSide(color: Colors.grey.shade300),
              ),
            ),
            child: Text(
              '${_choices[i]}',
              style: TextStyle(
                fontSize: 20,
                fontWeight: FontWeight.bold,
                color: textColor,
              ),
            ),
          ),
        );
      }),
    );
  }

  Widget _buildGameOver() {
    return Scaffold(
      backgroundColor: Colors.white,
      body: SafeArea(
        child: Center(
          child: Padding(
            padding: const EdgeInsets.all(32),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                const Icon(Icons.calculate_rounded, size: 64, color: _kPrimary),
                const SizedBox(height: 16),
                const Text(
                  'Time\'s Up!',
                  style: TextStyle(
                    fontSize: 24,
                    fontWeight: FontWeight.bold,
                    color: _kPrimary,
                  ),
                ),
                const SizedBox(height: 4),
                const Text(
                  'Muda Umekwisha!',
                  style: TextStyle(fontSize: 14, color: Color(0xFF666666)),
                ),
                const SizedBox(height: 24),
                Text(
                  '$_score',
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
                const SizedBox(height: 8),
                Text(
                  '$_correctCount correct out of $_problemCount',
                  style: const TextStyle(
                    fontSize: 14,
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
