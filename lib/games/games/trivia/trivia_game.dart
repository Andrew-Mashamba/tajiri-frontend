// lib/games/games/trivia/trivia_game.dart

import 'dart:async';
import 'dart:convert';
import 'dart:math';

import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;

import '../../../config/api_config.dart';
import '../../core/game_context.dart' as gc;
import '../../core/game_enums.dart';
import '../../core/game_interface.dart';

const Color _kPrimary = Color(0xFF1A1A1A);

class TriviaGame extends StatefulWidget {
  final gc.GameContext gameContext;
  const TriviaGame({super.key, required this.gameContext});

  @override
  State<TriviaGame> createState() => TriviaGameState();
}

class TriviaGameState extends State<TriviaGame> implements GameInterface {
  int _currentIndex = 0;
  int _score = 0;
  int _selectedAnswer = -1;
  int _timeRemaining = 15;
  bool _showingResult = false;
  bool _isLoading = true;
  bool _gameOver = false;
  List<Map<String, dynamic>> _questions = [];
  Timer? _timer;
  Timer? _resultTimer;

  gc.GameContext get _ctx => widget.gameContext;

  @override
  String get gameId => 'trivia';

  @override
  void initState() {
    super.initState();
    _ctx.setOnOpponentMove(onOpponentMove);
    _loadQuestions();
  }

  @override
  void dispose() {
    _timer?.cancel();
    _resultTimer?.cancel();
    super.dispose();
  }

  Future<void> _loadQuestions() async {
    try {
      final uri = Uri.parse(
        '${ApiConfig.baseUrl}/games/trivia/questions?seed=${_ctx.gameSeed}&count=10',
      );
      final response = await http.get(uri, headers: ApiConfig.headers);
      if (response.statusCode == 200) {
        final data = json.decode(response.body);
        if (data is Map && data['questions'] is List) {
          setState(() {
            _questions = List<Map<String, dynamic>>.from(data['questions']);
            _isLoading = false;
          });
          _startTimer();
          return;
        }
      }
    } catch (_) {
      // Fallback to generated questions
    }
    // Fallback: generate questions locally using seed
    _generateFallbackQuestions();
  }

  void _generateFallbackQuestions() {
    final rng = Random(_ctx.gameSeed.hashCode);
    final List<Map<String, dynamic>> questions = [];
    final categories = [
      _mathQuestion,
      _generalQuestion,
      _geographyQuestion,
      _scienceQuestion,
    ];
    for (int i = 0; i < 10; i++) {
      questions.add(categories[rng.nextInt(categories.length)](rng, i));
    }
    setState(() {
      _questions = questions;
      _isLoading = false;
    });
    _startTimer();
  }

  Map<String, dynamic> _mathQuestion(Random rng, int idx) {
    final a = rng.nextInt(50) + 10;
    final b = rng.nextInt(50) + 10;
    final ops = ['+', '-', '*'];
    final op = ops[rng.nextInt(ops.length)];
    int answer;
    switch (op) {
      case '+':
        answer = a + b;
        break;
      case '-':
        answer = a - b;
        break;
      default:
        answer = a * b;
    }
    final distractors = _makeDistractors(rng, answer);
    return {
      'question': 'What is $a $op $b?',
      'correct': 0,
      'answers': [answer.toString(), ...distractors.map((d) => d.toString())],
    };
  }

  Map<String, dynamic> _generalQuestion(Random rng, int idx) {
    final pool = [
      {
        'q': 'Which planet is known as the Red Planet?',
        'a': ['Mars', 'Venus', 'Jupiter', 'Saturn'],
        'c': 0,
      },
      {
        'q': 'What is the largest ocean on Earth?',
        'a': ['Pacific Ocean', 'Atlantic Ocean', 'Indian Ocean', 'Arctic Ocean'],
        'c': 0,
      },
      {
        'q': 'How many continents are there?',
        'a': ['7', '5', '6', '8'],
        'c': 0,
      },
      {
        'q': 'What is the capital of Tanzania?',
        'a': ['Dodoma', 'Dar es Salaam', 'Arusha', 'Mwanza'],
        'c': 0,
      },
      {
        'q': 'Which element has the chemical symbol O?',
        'a': ['Oxygen', 'Osmium', 'Gold', 'Iron'],
        'c': 0,
      },
      {
        'q': 'What year did Tanzania gain independence?',
        'a': ['1961', '1960', '1963', '1964'],
        'c': 0,
      },
      {
        'q': 'What is the tallest mountain in Africa?',
        'a': ['Mount Kilimanjaro', 'Mount Kenya', 'Mount Elgon', 'Mount Meru'],
        'c': 0,
      },
      {
        'q': 'How many sides does a hexagon have?',
        'a': ['6', '5', '7', '8'],
        'c': 0,
      },
      {
        'q': 'What is the largest lake in Africa?',
        'a': ['Lake Victoria', 'Lake Tanganyika', 'Lake Malawi', 'Lake Chad'],
        'c': 0,
      },
      {
        'q': 'What is H2O commonly known as?',
        'a': ['Water', 'Hydrogen Peroxide', 'Helium', 'Salt'],
        'c': 0,
      },
    ];
    final q = pool[idx % pool.length];
    // Shuffle answers deterministically
    final answers = List<String>.from(q['a'] as List);
    final correct = answers[q['c'] as int];
    final shuffled = List<String>.from(answers);
    shuffled.shuffle(rng);
    return {
      'question': q['q'],
      'correct': shuffled.indexOf(correct),
      'answers': shuffled,
    };
  }

  Map<String, dynamic> _geographyQuestion(Random rng, int idx) {
    return _generalQuestion(rng, idx);
  }

  Map<String, dynamic> _scienceQuestion(Random rng, int idx) {
    return _generalQuestion(rng, (idx + 5) % 10);
  }

  List<int> _makeDistractors(Random rng, int correct) {
    final Set<int> distractors = {};
    while (distractors.length < 3) {
      final offset = rng.nextInt(10) + 1;
      final d = rng.nextBool() ? correct + offset : correct - offset;
      if (d != correct && !distractors.contains(d)) {
        distractors.add(d);
      }
    }
    return distractors.toList();
  }

  void _startTimer() {
    _timer?.cancel();
    _timeRemaining = 15;
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
        _autoAdvance();
      }
    });
  }

  void _autoAdvance() {
    // No points for timeout
    _advanceToNext();
  }

  void _selectAnswer(int index) {
    if (_showingResult || _selectedAnswer >= 0 || _gameOver) return;
    _timer?.cancel();

    final correct = _questions[_currentIndex]['correct'] as int;
    int points = 0;
    if (index == correct) {
      points = 10;
      // Speed bonus
      if (_timeRemaining >= 12) {
        points += 5;
      } else if (_timeRemaining >= 10) {
        points += 3;
      } else if (_timeRemaining >= 5) {
        points += 1;
      }
    }

    setState(() {
      _selectedAnswer = index;
      _showingResult = true;
      _score += points;
    });

    _resultTimer = Timer(const Duration(milliseconds: 1500), () {
      if (mounted) _advanceToNext();
    });
  }

  void _advanceToNext() {
    if (_currentIndex >= 9) {
      _endGame();
      return;
    }
    setState(() {
      _currentIndex++;
      _selectedAnswer = -1;
      _showingResult = false;
    });
    _startTimer();
  }

  void _endGame() {
    setState(() {
      _gameOver = true;
    });
    // In practice mode, player wins if they scored any points.
    // In multiplayer, the backend determines the winner by comparing
    // both players' scores; we report our score and let the server decide.
    final winnerId = (_ctx.mode == GameMode.practice)
        ? (_score > 0 ? _ctx.userId : null)
        : null; // Let server decide based on both scores
    _ctx.onGameComplete({
      'winner_id': winnerId,
      'player_1_score': _score,
      'player_2_score': 0,
    });
  }

  @override
  void onOpponentMove(Map<String, dynamic> moveData) {
    // In multiplayer, opponent's score updates could be shown
  }

  @override
  void onReconnect(Map<String, dynamic> savedState) {
    setState(() {
      _currentIndex = savedState['currentIndex'] as int? ?? 0;
      _score = savedState['score'] as int? ?? 0;
      _timeRemaining = savedState['timeRemaining'] as int? ?? 15;
    });
  }

  @override
  Map<String, dynamic> getCurrentState() {
    return {
      'currentIndex': _currentIndex,
      'score': _score,
      'timeRemaining': _timeRemaining,
    };
  }

  @override
  Widget build(BuildContext context) {
    if (_isLoading) {
      return const Scaffold(
        body: Center(child: CircularProgressIndicator(color: _kPrimary)),
      );
    }

    if (_gameOver) {
      return _buildGameOver();
    }

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
              const SizedBox(height: 24),
              _buildQuestion(),
              const SizedBox(height: 24),
              _buildAnswers(),
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
          'Q ${_currentIndex + 1}/10',
          style: const TextStyle(
            fontSize: 16,
            fontWeight: FontWeight.w600,
            color: _kPrimary,
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
    final fraction = _timeRemaining / 15.0;
    final color = _timeRemaining > 10
        ? Colors.green
        : _timeRemaining > 5
            ? Colors.orange
            : Colors.red;
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

  Widget _buildQuestion() {
    final q = _questions[_currentIndex];
    return Text(
      q['question'] as String,
      style: const TextStyle(
        fontSize: 18,
        fontWeight: FontWeight.bold,
        color: _kPrimary,
      ),
      textAlign: TextAlign.center,
      maxLines: 4,
      overflow: TextOverflow.ellipsis,
    );
  }

  Widget _buildAnswers() {
    final q = _questions[_currentIndex];
    final answers = (q['answers'] as List).cast<String>();
    final correct = q['correct'] as int;

    return Expanded(
      child: GridView.count(
        crossAxisCount: 2,
        mainAxisSpacing: 12,
        crossAxisSpacing: 12,
        childAspectRatio: 2.8,
        shrinkWrap: true,
        physics: const NeverScrollableScrollPhysics(),
        children: List.generate(answers.length, (i) {
          Color bg = Colors.grey.shade100;
          Color textColor = _kPrimary;
          if (_showingResult) {
            if (i == correct) {
              bg = Colors.green;
              textColor = Colors.white;
            } else if (i == _selectedAnswer && i != correct) {
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
                answers[i],
                style: TextStyle(
                  fontSize: 14,
                  fontWeight: FontWeight.w600,
                  color: textColor,
                ),
                maxLines: 2,
                overflow: TextOverflow.ellipsis,
                textAlign: TextAlign.center,
              ),
            ),
          );
        }),
      ),
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
                const Icon(Icons.emoji_events_rounded, size: 64, color: _kPrimary),
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
                const SizedBox(height: 16),
                const SizedBox(
                  width: 24,
                  height: 24,
                  child: CircularProgressIndicator(
                    strokeWidth: 2,
                    color: _kPrimary,
                  ),
                ),
                const SizedBox(height: 8),
                const Text(
                  'Saving results...',
                  style: TextStyle(fontSize: 12, color: Color(0xFF666666)),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
