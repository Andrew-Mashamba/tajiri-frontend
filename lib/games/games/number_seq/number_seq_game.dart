// lib/games/games/number_seq/number_seq_game.dart

import 'dart:async';
import 'dart:math';

import 'package:flutter/material.dart';

import '../../core/game_context.dart' as gc;
import '../../core/game_enums.dart';
import '../../core/game_interface.dart';

const Color _kPrimary = Color(0xFF1A1A1A);
const Color _kSecondary = Color(0xFF666666);

// ─── Sequence types ──────────────────────────────────────────
enum _SeqType { arithmetic, geometric, fibonacci, squares, triangular, powers, alternating }

class _Sequence {
  final List<int> shown;
  final int answer;
  const _Sequence(this.shown, this.answer);
}

class NumberSeqGame extends StatefulWidget {
  final gc.GameContext gameContext;
  const NumberSeqGame({super.key, required this.gameContext});

  @override
  State<NumberSeqGame> createState() => NumberSeqGameState();
}

class NumberSeqGameState extends State<NumberSeqGame>
    implements GameInterface {
  late Random _rng;
  gc.GameContext get _ctx => widget.gameContext;

  int _score = 0;
  int _questionCount = 0;
  int _correctCount = 0;
  int _timeRemaining = 60;
  int _difficulty = 0; // increases over time
  bool _gameOver = false;
  Timer? _timer;

  late _Sequence _currentSeq;
  List<int> _choices = [];
  int _selectedAnswer = -1;
  bool _showingResult = false;
  Timer? _resultTimer;

  @override
  String get gameId => 'number_seq';

  @override
  void initState() {
    super.initState();
    _rng = Random(_ctx.gameSeed.hashCode);
    _generateSequence();
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
        // Ramp difficulty
        if (_timeRemaining == 40) _difficulty = 1;
        if (_timeRemaining == 20) _difficulty = 2;
      });
      if (_timeRemaining <= 0) {
        timer.cancel();
        _endGame();
      }
    });
  }

  void _generateSequence() {
    final types = _SeqType.values;
    final type = types[_rng.nextInt(types.length)];
    _currentSeq = _makeSequence(type);
    _choices = _makeChoices(_currentSeq.answer);
    _selectedAnswer = -1;
    _showingResult = false;
    _questionCount++;
  }

  _Sequence _makeSequence(_SeqType type) {
    switch (type) {
      case _SeqType.arithmetic:
        final diff = (_rng.nextInt(5) + 2) * (_difficulty + 1);
        final start = _rng.nextInt(10) + 1;
        final count = _rng.nextInt(2) + 4; // 4-5 shown
        final seq = List.generate(count + 1, (i) => start + diff * i);
        return _Sequence(seq.sublist(0, count), seq[count]);

      case _SeqType.geometric:
        final mult = _rng.nextInt(3) + 2; // 2, 3, or 4
        final start = _rng.nextInt(3) + 1;
        final count = _rng.nextInt(2) + 4;
        final seq = <int>[start];
        for (int i = 1; i <= count; i++) {
          seq.add(seq[i - 1] * mult);
        }
        return _Sequence(seq.sublist(0, count), seq[count]);

      case _SeqType.fibonacci:
        final a = _rng.nextInt(3) + 1;
        final b = _rng.nextInt(3) + 1;
        final seq = <int>[a, b];
        for (int i = 2; i <= 6; i++) {
          seq.add(seq[i - 1] + seq[i - 2]);
        }
        final count = _rng.nextInt(2) + 5; // 5-6 shown
        final shown = count <= seq.length ? count : seq.length - 1;
        return _Sequence(seq.sublist(0, shown), seq[shown]);

      case _SeqType.squares:
        final offset = _rng.nextInt(3); // start at 1, 2, or 3
        final count = _rng.nextInt(2) + 4;
        final seq = List.generate(
            count + 1, (i) => (i + 1 + offset) * (i + 1 + offset));
        return _Sequence(seq.sublist(0, count), seq[count]);

      case _SeqType.triangular:
        final count = _rng.nextInt(2) + 4;
        final seq = <int>[];
        int sum = 0;
        for (int i = 1; i <= count + 1; i++) {
          sum += i;
          seq.add(sum);
        }
        return _Sequence(seq.sublist(0, count), seq[count]);

      case _SeqType.powers:
        final base = _rng.nextInt(2) + 2; // 2 or 3
        final count = _rng.nextInt(2) + 4;
        final seq = List.generate(count + 1, (i) => _pow(base, i));
        return _Sequence(seq.sublist(0, count), seq[count]);

      case _SeqType.alternating:
        final count = _rng.nextInt(2) + 5;
        final seq = <int>[];
        for (int i = 1; i <= count + 1; i++) {
          seq.add(i * (i.isOdd ? 1 : -1));
        }
        return _Sequence(seq.sublist(0, count), seq[count]);
    }
  }

  static int _pow(int base, int exp) {
    int result = 1;
    for (int i = 0; i < exp; i++) {
      result *= base;
    }
    return result;
  }

  List<int> _makeChoices(int correct) {
    final choices = <int>{correct};
    int attempts = 0;
    while (choices.length < 4 && attempts < 50) {
      attempts++;
      final offset = _rng.nextInt(max(correct.abs(), 5)) + 1;
      final d = _rng.nextBool() ? correct + offset : correct - offset;
      if (d != correct) choices.add(d);
    }
    // Fill remaining with simple offsets if needed
    int off = 1;
    while (choices.length < 4) {
      choices.add(correct + off * 2);
      off++;
    }
    final list = choices.toList();
    list.shuffle(_rng);
    return list;
  }

  void _selectAnswer(int index) {
    if (_showingResult || _gameOver) return;

    final chosen = _choices[index];
    final isCorrect = chosen == _currentSeq.answer;

    int points = 0;
    if (isCorrect) {
      points = 10;
      // Speed bonus
      if (_timeRemaining > 40) {
        points += 5;
      } else if (_timeRemaining > 20) {
        points += 3;
      }
      _correctCount++;
    }

    setState(() {
      _selectedAnswer = index;
      _showingResult = true;
      _score += points;
    });

    _resultTimer = Timer(const Duration(milliseconds: 500), () {
      if (mounted && !_gameOver) {
        setState(() {
          _generateSequence();
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
      _questionCount = savedState['questionCount'] as int? ?? 0;
    });
  }

  @override
  Map<String, dynamic> getCurrentState() {
    return {
      'score': _score,
      'timeRemaining': _timeRemaining,
      'questionCount': _questionCount,
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
              _buildSequenceDisplay(),
              const SizedBox(height: 32),
              _buildChoiceGrid(),
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
          'Sequence #$_questionCount',
          style: const TextStyle(
            fontSize: 14,
            fontWeight: FontWeight.w600,
            color: _kSecondary,
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
              fontSize: 13, color: color, fontWeight: FontWeight.w600),
        ),
      ],
    );
  }

  Widget _buildSequenceDisplay() {
    final items = <String>[
      ..._currentSeq.shown.map((n) => '$n'),
      '?',
    ];

    return Wrap(
      alignment: WrapAlignment.center,
      spacing: 8,
      runSpacing: 8,
      children: items.map((item) {
        final isQuestion = item == '?';
        return Container(
          constraints: const BoxConstraints(minWidth: 48),
          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
          decoration: BoxDecoration(
            color: isQuestion ? _kPrimary : Colors.grey.shade100,
            borderRadius: BorderRadius.circular(12),
            border: Border.all(
              color: isQuestion ? _kPrimary : Colors.grey.shade300,
            ),
          ),
          child: Text(
            item,
            style: TextStyle(
              fontSize: 22,
              fontWeight: FontWeight.bold,
              color: isQuestion ? Colors.white : _kPrimary,
            ),
            textAlign: TextAlign.center,
          ),
        );
      }).toList(),
    );
  }

  Widget _buildChoiceGrid() {
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
          if (_choices[i] == _currentSeq.answer) {
            bg = Colors.green;
            textColor = Colors.white;
          } else if (i == _selectedAnswer &&
              _choices[i] != _currentSeq.answer) {
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
                const Icon(Icons.trending_up_rounded,
                    size: 64, color: _kPrimary),
                const SizedBox(height: 16),
                const Text(
                  'Time\'s Up!',
                  style: TextStyle(
                    fontSize: 24,
                    fontWeight: FontWeight.bold,
                    color: _kPrimary,
                  ),
                ),
                const Text(
                  'Muda Umekwisha!',
                  style: TextStyle(fontSize: 14, color: _kSecondary),
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
                  style: TextStyle(fontSize: 14, color: _kSecondary),
                ),
                const SizedBox(height: 8),
                Text(
                  '$_correctCount correct out of $_questionCount',
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
