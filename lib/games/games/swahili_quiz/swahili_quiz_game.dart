// lib/games/games/swahili_quiz/swahili_quiz_game.dart

import 'dart:async';
import 'dart:math';

import 'package:flutter/material.dart';

import '../../core/game_context.dart' as gc;
import '../../core/game_enums.dart';
import '../../core/game_interface.dart';

const Color _kPrimary = Color(0xFF1A1A1A);
const Color _kSecondary = Color(0xFF666666);

/// Hardcoded Swahili language questions.
const List<Map<String, dynamic>> _kQuestionPool = [
  // ─── Vocabulary: What does X mean in English? ───
  {'q': "What does 'nyumba' mean in English?", 'a': ['House', 'Car', 'Tree', 'River'], 'c': 0},
  {'q': "What does 'maji' mean in English?", 'a': ['Water', 'Fire', 'Earth', 'Wind'], 'c': 0},
  {'q': "What does 'chakula' mean in English?", 'a': ['Food', 'Clothes', 'Money', 'Sleep'], 'c': 0},
  {'q': "What does 'shule' mean in English?", 'a': ['School', 'Church', 'Market', 'Hospital'], 'c': 0},
  {'q': "What does 'kitabu' mean in English?", 'a': ['Book', 'Pen', 'Table', 'Chair'], 'c': 0},
  {'q': "What does 'barabara' mean in English?", 'a': ['Road', 'Bridge', 'Building', 'Field'], 'c': 0},
  {'q': "What does 'duka' mean in English?", 'a': ['Shop', 'Farm', 'Office', 'Kitchen'], 'c': 0},
  {'q': "What does 'jua' mean in English?", 'a': ['Sun', 'Moon', 'Star', 'Cloud'], 'c': 0},
  {'q': "What does 'mvua' mean in English?", 'a': ['Rain', 'Snow', 'Wind', 'Fog'], 'c': 0},
  {'q': "What does 'ndege' mean in English?", 'a': ['Bird / Airplane', 'Fish', 'Snake', 'Dog'], 'c': 0},
  {'q': "What does 'samaki' mean in English?", 'a': ['Fish', 'Chicken', 'Goat', 'Cow'], 'c': 0},
  {'q': "What does 'mti' mean in English?", 'a': ['Tree', 'Flower', 'Grass', 'Rock'], 'c': 0},
  {'q': "What does 'rafiki' mean in English?", 'a': ['Friend', 'Enemy', 'Brother', 'Teacher'], 'c': 0},
  {'q': "What does 'kazi' mean in English?", 'a': ['Work', 'Play', 'Rest', 'Travel'], 'c': 0},
  {'q': "What does 'haraka' mean in English?", 'a': ['Quickly / Hurry', 'Slowly', 'Carefully', 'Quietly'], 'c': 0},

  // ─── Proverbs (Methali) ───
  {'q': "Complete the proverb: 'Haraka haraka...'", 'a': ['haina baraka', 'haina dawa', 'haina mwisho', 'haina furaha'], 'c': 0},
  {'q': "Complete the proverb: 'Asiyesikia la mkuu...'", 'a': ['huvunjika guu', 'hupotea njia', 'huchoka sana', 'haishi siku'], 'c': 0},
  {'q': "Complete the proverb: 'Umoja ni...'", 'a': ['nguvu', 'upendo', 'amani', 'utajiri'], 'c': 0},
  {'q': "Complete the proverb: 'Mgeni siku mbili...'", 'a': ['ya tatu mpe jembe', 'ya tatu aondoke', 'ya tatu ni rafiki', 'ya tatu ni adui'], 'c': 0},
  {'q': "Complete the proverb: 'Pole pole...'", 'a': ['ndio mwendo', 'ndio nguvu', 'ndio upendo', 'ndio uzima'], 'c': 0},
  {'q': "Complete the proverb: 'Haba na haba...'", 'a': ['hujaza kibaba', 'hujaza nyumba', 'hujaza mfuko', 'hujaza moyo'], 'c': 0},
  {'q': "Complete the proverb: 'Mwacha mila...'", 'a': ['ni mtumwa', 'ni mshenzi', 'ni mjinga', 'ni maskini'], 'c': 0},
  {'q': "Complete the proverb: 'Dawa ya moto...'", 'a': ['ni moto', 'ni maji', 'ni upepo', 'ni udongo'], 'c': 0},
  {'q': "Complete the proverb: 'Penye nia...'", 'a': ['pana njia', 'pana baraka', 'pana furaha', 'pana amani'], 'c': 0},
  {'q': "Complete the proverb: 'Mnyonge mnyongeni...'", 'a': ['lakini haki yake mpeni', 'lakini msimcheke', 'lakini msimtese', 'lakini msimdhuru'], 'c': 0},

  // ─── Translation to Swahili ───
  {'q': "Translate to Swahili: 'house'", 'a': ['nyumba', 'gari', 'mti', 'mlima'], 'c': 0},
  {'q': "Translate to Swahili: 'water'", 'a': ['maji', 'moto', 'upepo', 'ardhi'], 'c': 0},
  {'q': "Translate to Swahili: 'child'", 'a': ['mtoto', 'mzee', 'mama', 'baba'], 'c': 0},
  {'q': "Translate to Swahili: 'love'", 'a': ['upendo', 'chuki', 'hasira', 'hofu'], 'c': 0},
  {'q': "Translate to Swahili: 'food'", 'a': ['chakula', 'kinywaji', 'nguo', 'pesa'], 'c': 0},
  {'q': "Translate to Swahili: 'teacher'", 'a': ['mwalimu', 'daktari', 'fundi', 'askari'], 'c': 0},
  {'q': "Translate to Swahili: 'thank you'", 'a': ['asante', 'pole', 'tafadhali', 'samahani'], 'c': 0},
  {'q': "Translate to Swahili: 'beautiful'", 'a': ['nzuri', 'kubwa', 'ndogo', 'refu'], 'c': 0},
  {'q': "Translate to Swahili: 'money'", 'a': ['pesa', 'kazi', 'duka', 'bidhaa'], 'c': 0},
  {'q': "Translate to Swahili: 'big'", 'a': ['kubwa', 'ndogo', 'refu', 'fupi'], 'c': 0},

  // ─── Grammar ───
  {'q': "'Watoto' is the plural of?", 'a': ['Mtoto', 'Kitoto', 'Utoto', 'Toto'], 'c': 0},
  {'q': "'Vitabu' is the plural of?", 'a': ['Kitabu', 'Mtabu', 'Utabu', 'Tabu'], 'c': 0},
  {'q': "'Nyumba' belongs to which noun class?", 'a': ['N-class (9/10)', 'M-Wa (1/2)', 'Ki-Vi (7/8)', 'U (11)'], 'c': 0},
  {'q': "What is the past tense prefix in Swahili?", 'a': ['li-', 'na-', 'ta-', 'me-'], 'c': 0},
  {'q': "What prefix indicates 'we' in Swahili verbs?", 'a': ['Tu-', 'Ni-', 'A-', 'Wa-'], 'c': 0},
  {'q': "'Miti' is the plural of?", 'a': ['Mti', 'Kiti', 'Uti', 'Titi'], 'c': 0},
  {'q': "'Viti' is the plural of?", 'a': ['Kiti', 'Mti', 'Uti', 'Jiti'], 'c': 0},
  {'q': "What does the prefix 'wa-' indicate?", 'a': ['Plural of M-class nouns (people)', 'Singular noun', 'Past tense', 'Future tense'], 'c': 0},
  {'q': "What is 'nimekula' in English?", 'a': ['I have eaten', 'I am eating', 'I will eat', 'I was eating'], 'c': 0},
  {'q': "What tense is 'atapika'?", 'a': ['Future tense', 'Past tense', 'Present tense', 'Perfect tense'], 'c': 0},

  // ─── More vocabulary ───
  {'q': "What does 'habari' mean in English?", 'a': ['News / How are you', 'Goodbye', 'Sorry', 'Please'], 'c': 0},
  {'q': "What does 'soko' mean in English?", 'a': ['Market', 'Forest', 'Lake', 'Mountain'], 'c': 0},
  {'q': "What does 'simba' mean in English?", 'a': ['Lion', 'Elephant', 'Giraffe', 'Hippo'], 'c': 0},
  {'q': "What does 'tembo' mean in English?", 'a': ['Elephant', 'Lion', 'Buffalo', 'Rhino'], 'c': 0},
  {'q': "What does 'kesho' mean in English?", 'a': ['Tomorrow', 'Yesterday', 'Today', 'Now'], 'c': 0},
  {'q': "What does 'jana' mean in English?", 'a': ['Yesterday', 'Tomorrow', 'Later', 'Soon'], 'c': 0},
  {'q': "What does 'sasa' mean in English?", 'a': ['Now', 'Later', 'Before', 'After'], 'c': 0},
  {'q': "What does 'karibu' mean in English?", 'a': ['Welcome / Near', 'Far away', 'Goodbye', 'Sorry'], 'c': 0},
  {'q': "What does 'kwaheri' mean in English?", 'a': ['Goodbye', 'Hello', 'Welcome', 'Please'], 'c': 0},
  {'q': "What does 'daktari' mean in English?", 'a': ['Doctor', 'Teacher', 'Farmer', 'Driver'], 'c': 0},
];

class SwahiliQuizGame extends StatefulWidget {
  final gc.GameContext gameContext;
  const SwahiliQuizGame({super.key, required this.gameContext});

  @override
  State<SwahiliQuizGame> createState() => SwahiliQuizGameState();
}

class SwahiliQuizGameState extends State<SwahiliQuizGame>
    implements GameInterface {
  int _currentIndex = 0;
  int _score = 0;
  int _selectedAnswer = -1;
  int _timeRemaining = 15;
  bool _showingResult = false;
  bool _gameOver = false;
  List<Map<String, dynamic>> _questions = [];
  Timer? _timer;
  Timer? _resultTimer;

  gc.GameContext get _ctx => widget.gameContext;

  @override
  String get gameId => 'swahili_quiz';

  @override
  void initState() {
    super.initState();
    _generateQuestions();
  }

  @override
  void dispose() {
    _timer?.cancel();
    _resultTimer?.cancel();
    super.dispose();
  }

  void _generateQuestions() {
    final rng = Random(_ctx.gameSeed.hashCode);
    // Shuffle and pick 10
    final indices = List<int>.generate(_kQuestionPool.length, (i) => i);
    indices.shuffle(rng);
    final selected = indices.take(10).toList();

    _questions = selected.map((idx) {
      final q = _kQuestionPool[idx];
      final answers = List<String>.from(q['a'] as List);
      final correct = answers[q['c'] as int];
      answers.shuffle(rng);
      return {
        'question': q['q'],
        'correct': answers.indexOf(correct),
        'answers': answers,
      };
    }).toList();

    _startTimer();
  }

  void _startTimer() {
    _timer?.cancel();
    _timeRemaining = 15;
    _timer = Timer.periodic(const Duration(seconds: 1), (timer) {
      if (!mounted) {
        timer.cancel();
        return;
      }
      setState(() => _timeRemaining--);
      if (_timeRemaining <= 0) {
        timer.cancel();
        _advanceToNext();
      }
    });
  }

  void _selectAnswer(int index) {
    if (_showingResult || _selectedAnswer >= 0 || _gameOver) return;
    _timer?.cancel();

    final correct = _questions[_currentIndex]['correct'] as int;
    int points = 0;
    if (index == correct) {
      points = 10;
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
    _timer?.cancel();
    setState(() => _gameOver = true);
    final winnerId =
        (_ctx.mode == GameMode.practice) ? (_score > 0 ? _ctx.userId : null) : _ctx.userId;
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
              fontSize: 16, fontWeight: FontWeight.w600, color: _kPrimary),
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
                color: Colors.white, fontWeight: FontWeight.w600, fontSize: 14),
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
          style:
              TextStyle(fontSize: 13, color: color, fontWeight: FontWeight.w600),
        ),
      ],
    );
  }

  Widget _buildQuestion() {
    final q = _questions[_currentIndex];
    return Text(
      q['question'] as String,
      style: const TextStyle(
          fontSize: 18, fontWeight: FontWeight.bold, color: _kPrimary),
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
                    color: textColor),
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
                const Icon(Icons.emoji_events_rounded,
                    size: 64, color: _kPrimary),
                const SizedBox(height: 16),
                const Text('Game Over!',
                    style: TextStyle(
                        fontSize: 24,
                        fontWeight: FontWeight.bold,
                        color: _kPrimary)),
                const SizedBox(height: 4),
                const Text('Mchezo Umekwisha!',
                    style: TextStyle(fontSize: 14, color: _kSecondary)),
                const SizedBox(height: 24),
                Text('$_score',
                    style: const TextStyle(
                        fontSize: 48,
                        fontWeight: FontWeight.bold,
                        color: _kPrimary)),
                const Text('points / pointi',
                    style: TextStyle(fontSize: 14, color: _kSecondary)),
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
