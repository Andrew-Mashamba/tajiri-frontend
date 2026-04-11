// lib/games/games/speed_quiz/speed_quiz_game.dart

import 'dart:async';
import 'dart:math';

import 'package:flutter/material.dart';

import '../../core/game_context.dart' as gc;
import '../../core/game_enums.dart';
import '../../core/game_interface.dart';

const Color _kPrimary = Color(0xFF1A1A1A);
const Color _kSecondary = Color(0xFF666666);

// ─── Question data ───────────────────────────────────────────
class _Q {
  final String question;
  final List<String> options;
  final int correctIndex;
  const _Q(this.question, this.options, this.correctIndex);
}

const List<_Q> _allQuestions = [
  _Q('What is the capital of France?', ['Berlin', 'Paris', 'Rome', 'Madrid'], 1),
  _Q('How many continents are there?', ['5', '6', '7', '8'], 2),
  _Q('What planet is closest to the Sun?', ['Venus', 'Mercury', 'Mars', 'Earth'], 1),
  _Q('What is the boiling point of water in Celsius?', ['90', '100', '110', '120'], 1),
  _Q('How many legs does a spider have?', ['6', '8', '10', '12'], 1),
  _Q('What gas do plants absorb?', ['Oxygen', 'Nitrogen', 'Carbon Dioxide', 'Helium'], 2),
  _Q('What is the largest ocean?', ['Atlantic', 'Indian', 'Arctic', 'Pacific'], 3),
  _Q('How many days in a leap year?', ['365', '366', '364', '367'], 1),
  _Q('What is the chemical symbol for gold?', ['Go', 'Au', 'Ag', 'Gd'], 1),
  _Q('Which is the smallest prime number?', ['0', '1', '2', '3'], 2),
  _Q('What is the capital of Japan?', ['Osaka', 'Kyoto', 'Tokyo', 'Nagoya'], 2),
  _Q('How many colors in a rainbow?', ['5', '6', '7', '8'], 2),
  _Q('What is the hardest natural substance?', ['Gold', 'Iron', 'Diamond', 'Quartz'], 2),
  _Q('Which planet is known as the Red Planet?', ['Venus', 'Mars', 'Jupiter', 'Saturn'], 1),
  _Q('How many bones in the adult human body?', ['186', '196', '206', '216'], 2),
  _Q('What is the speed of light in km/s?', ['200000', '300000', '400000', '500000'], 1),
  _Q('What year did World War II end?', ['1943', '1944', '1945', '1946'], 2),
  _Q('What is the largest mammal?', ['Elephant', 'Blue Whale', 'Giraffe', 'Hippo'], 1),
  _Q('How many teeth does an adult human have?', ['28', '30', '32', '34'], 2),
  _Q('What is the capital of Australia?', ['Sydney', 'Melbourne', 'Canberra', 'Perth'], 2),
  _Q('Which element has symbol O?', ['Osmium', 'Oxygen', 'Gold', 'Silver'], 1),
  _Q('What is the square root of 144?', ['10', '11', '12', '13'], 2),
  _Q('How many seconds in one hour?', ['3000', '3600', '4200', '6000'], 1),
  _Q('What is the largest continent?', ['Africa', 'Europe', 'Asia', 'N. America'], 2),
  _Q('Which animal is the fastest on land?', ['Lion', 'Cheetah', 'Horse', 'Gazelle'], 1),
  _Q('What is the freezing point of water in Fahrenheit?', ['0', '32', '100', '212'], 1),
  _Q('How many players on a soccer team?', ['9', '10', '11', '12'], 2),
  _Q('What is the capital of Brazil?', ['Sao Paulo', 'Rio', 'Brasilia', 'Salvador'], 2),
  _Q('Which gas makes up most of the atmosphere?', ['Oxygen', 'Nitrogen', 'CO2', 'Argon'], 1),
  _Q('What is the largest desert?', ['Sahara', 'Gobi', 'Antarctic', 'Arabian'], 2),
  _Q('How many strings on a standard guitar?', ['4', '5', '6', '7'], 2),
  _Q('What is the capital of Canada?', ['Toronto', 'Vancouver', 'Ottawa', 'Montreal'], 2),
  _Q('Which planet has the most moons?', ['Jupiter', 'Saturn', 'Uranus', 'Neptune'], 1),
  _Q('What is H2O?', ['Hydrogen', 'Oxygen', 'Water', 'Helium'], 2),
  _Q('How many sides does a hexagon have?', ['5', '6', '7', '8'], 1),
  _Q('What is the tallest mountain?', ['K2', 'Kangchenjunga', 'Everest', 'Lhotse'], 2),
  _Q('What does DNA stand for?', ['Deoxyribonucleic Acid', 'Dual Nucleic Acid', 'Di-Nitrogen Acid', 'Dense Nuclear Atom'], 0),
  _Q('What is the capital of Egypt?', ['Cairo', 'Alexandria', 'Luxor', 'Giza'], 0),
  _Q('How many weeks in a year?', ['48', '50', '52', '54'], 2),
  _Q('Which blood type is universal donor?', ['A', 'B', 'AB', 'O'], 3),
  _Q('What is the capital of Germany?', ['Munich', 'Berlin', 'Hamburg', 'Cologne'], 1),
  _Q('How many chambers does the human heart have?', ['2', '3', '4', '5'], 2),
  _Q('What is the longest river in the world?', ['Amazon', 'Nile', 'Mississippi', 'Yangtze'], 1),
  _Q('Which country has the most people?', ['India', 'USA', 'China', 'Indonesia'], 0),
  _Q('What is the chemical symbol for silver?', ['Si', 'Sv', 'Ag', 'Au'], 2),
  _Q('How many zeros in a million?', ['5', '6', '7', '8'], 1),
  _Q('What is the capital of South Korea?', ['Busan', 'Seoul', 'Incheon', 'Daegu'], 1),
  _Q('Which is the largest bird?', ['Eagle', 'Ostrich', 'Emu', 'Albatross'], 1),
  _Q('What does CPU stand for?', ['Central Power Unit', 'Central Processing Unit', 'Computer Personal Unit', 'Core Process Utility'], 1),
  _Q('What is the capital of Italy?', ['Milan', 'Venice', 'Rome', 'Naples'], 2),
  _Q('How many planets in our solar system?', ['7', '8', '9', '10'], 1),
  _Q('What vitamin does sunlight give us?', ['A', 'B', 'C', 'D'], 3),
  _Q('What is the capital of Russia?', ['St. Petersburg', 'Moscow', 'Novosibirsk', 'Kazan'], 1),
  _Q('Which metal is liquid at room temperature?', ['Lead', 'Tin', 'Mercury', 'Zinc'], 2),
  _Q('What is the capital of Spain?', ['Barcelona', 'Madrid', 'Seville', 'Valencia'], 1),
  _Q('How many vertices does a cube have?', ['4', '6', '8', '12'], 2),
  _Q('What is the smallest country?', ['Monaco', 'Vatican City', 'San Marino', 'Malta'], 1),
  _Q('Which instrument has 88 keys?', ['Guitar', 'Violin', 'Piano', 'Harp'], 2),
  _Q('What is the capital of Kenya?', ['Mombasa', 'Nairobi', 'Kisumu', 'Nakuru'], 1),
  _Q('How many faces does a die have?', ['4', '5', '6', '8'], 2),
  _Q('What is the most spoken language?', ['Spanish', 'English', 'Mandarin', 'Hindi'], 2),
  _Q('Which ocean is the deepest?', ['Atlantic', 'Indian', 'Pacific', 'Arctic'], 2),
  _Q('What is the capital of Tanzania?', ['Dar es Salaam', 'Dodoma', 'Arusha', 'Mwanza'], 1),
  _Q('How many minutes in a day?', ['1200', '1440', '1560', '1680'], 1),
  _Q('What element has atomic number 1?', ['Helium', 'Hydrogen', 'Lithium', 'Carbon'], 1),
  _Q('Which is the longest bone in the body?', ['Tibia', 'Humerus', 'Femur', 'Spine'], 2),
  _Q('What is the capital of China?', ['Shanghai', 'Beijing', 'Guangzhou', 'Shenzhen'], 1),
  _Q('How many sides does a pentagon have?', ['4', '5', '6', '7'], 1),
  _Q('What is the currency of Japan?', ['Won', 'Yuan', 'Yen', 'Ringgit'], 2),
  _Q('Which planet is largest?', ['Saturn', 'Jupiter', 'Neptune', 'Uranus'], 1),
  _Q('What is the capital of India?', ['Mumbai', 'Kolkata', 'New Delhi', 'Chennai'], 2),
  _Q('How many months have 31 days?', ['5', '6', '7', '8'], 2),
  _Q('What is the chemical formula for salt?', ['NaO', 'NaCl', 'KCl', 'NaC'], 1),
  _Q('Which is the hottest planet?', ['Mercury', 'Venus', 'Mars', 'Jupiter'], 1),
  _Q('What is the capital of Nigeria?', ['Lagos', 'Abuja', 'Ibadan', 'Kano'], 1),
  _Q('How many years in a century?', ['10', '50', '100', '1000'], 2),
  _Q('What is the capital of Mexico?', ['Cancun', 'Guadalajara', 'Mexico City', 'Monterrey'], 2),
  _Q('Which vitamin is good for eyesight?', ['A', 'B', 'C', 'K'], 0),
  _Q('What is the capital of Thailand?', ['Phuket', 'Bangkok', 'Chiang Mai', 'Pattaya'], 1),
  _Q('How many quarts in a gallon?', ['2', '3', '4', '5'], 2),
  _Q('What is the largest organ in the human body?', ['Liver', 'Brain', 'Skin', 'Heart'], 2),
  _Q('Which country invented pizza?', ['France', 'Spain', 'Italy', 'Greece'], 2),
  _Q('What is the capital of Argentina?', ['Lima', 'Buenos Aires', 'Santiago', 'Bogota'], 1),
  _Q('How many degrees in a circle?', ['180', '270', '360', '400'], 2),
  _Q('What is the capital of Turkey?', ['Istanbul', 'Ankara', 'Izmir', 'Antalya'], 1),
  _Q('Which is the deepest lake?', ['Victoria', 'Superior', 'Baikal', 'Tanganyika'], 2),
  _Q('What color is an emerald?', ['Blue', 'Red', 'Green', 'Yellow'], 2),
  _Q('What is the capital of Indonesia?', ['Jakarta', 'Bali', 'Surabaya', 'Bandung'], 0),
  _Q('How many bits in a byte?', ['4', '6', '8', '16'], 2),
  _Q('What is the lightest element?', ['Helium', 'Hydrogen', 'Lithium', 'Carbon'], 1),
  _Q('Which sport uses a shuttlecock?', ['Tennis', 'Badminton', 'Squash', 'Cricket'], 1),
  _Q('What is the capital of Poland?', ['Krakow', 'Warsaw', 'Gdansk', 'Poznan'], 1),
  _Q('How many lungs do humans have?', ['1', '2', '3', '4'], 1),
  _Q('What does USB stand for?', ['Universal Serial Bus', 'Ultra System Backup', 'Unified Software Bridge', 'Universal Storage Base'], 0),
  _Q('Which is the nearest star to Earth?', ['Sirius', 'Proxima Centauri', 'Alpha Centauri', 'Sun'], 3),
  _Q('What is the capital of Peru?', ['Cusco', 'Lima', 'Arequipa', 'Trujillo'], 1),
  _Q('How many wives did Henry VIII have?', ['4', '5', '6', '8'], 2),
  _Q('What is the currency of UK?', ['Euro', 'Dollar', 'Pound', 'Franc'], 2),
  _Q('Which continent is the Sahara on?', ['Asia', 'Africa', 'S. America', 'Australia'], 1),
  _Q('What is the capital of Sweden?', ['Oslo', 'Helsinki', 'Stockholm', 'Copenhagen'], 2),
  _Q('How many protons does carbon have?', ['4', '5', '6', '8'], 2),
  _Q('What is the national sport of Japan?', ['Karate', 'Judo', 'Sumo', 'Kendo'], 2),
  _Q('Which is the smallest planet?', ['Mars', 'Mercury', 'Venus', 'Pluto'], 1),
  _Q('What is the capital of Vietnam?', ['Ho Chi Minh', 'Hanoi', 'Da Nang', 'Hue'], 1),
  _Q('How many cards in a standard deck?', ['48', '50', '52', '54'], 2),
  _Q('What does WWW stand for?', ['World Wide Web', 'Western Web Works', 'World Web Wire', 'Wireless World Web'], 0),
  _Q('What is the capital of Morocco?', ['Casablanca', 'Marrakesh', 'Rabat', 'Fez'], 2),
  _Q('Which animal is called King of the Jungle?', ['Tiger', 'Elephant', 'Lion', 'Gorilla'], 2),
  _Q('What is the capital of Colombia?', ['Medellin', 'Bogota', 'Cali', 'Cartagena'], 1),
  _Q('How many sides does a triangle have?', ['2', '3', '4', '5'], 1),
  _Q('What is the capital of Ethiopia?', ['Nairobi', 'Addis Ababa', 'Asmara', 'Kampala'], 1),
  _Q('Which gas do we breathe out?', ['Oxygen', 'Nitrogen', 'Carbon Dioxide', 'Helium'], 2),
  _Q('What is the capital of Norway?', ['Bergen', 'Oslo', 'Stavanger', 'Tromso'], 1),
  _Q('How many Olympic rings are there?', ['3', '4', '5', '6'], 2),
];

class SpeedQuizGame extends StatefulWidget {
  final gc.GameContext gameContext;
  const SpeedQuizGame({super.key, required this.gameContext});

  @override
  State<SpeedQuizGame> createState() => SpeedQuizGameState();
}

class SpeedQuizGameState extends State<SpeedQuizGame>
    implements GameInterface {
  late Random _rng;
  gc.GameContext get _ctx => widget.gameContext;

  int _score = 0;
  int _streak = 0;
  int _questionsAnswered = 0;
  int _correctCount = 0;
  int _timeRemaining = 60;
  bool _gameOver = false;
  Timer? _timer;

  late List<int> _questionOrder;
  int _currentQIndex = 0;
  int _selectedAnswer = -1;
  bool _showingResult = false;
  Timer? _resultTimer;

  @override
  String get gameId => 'speed_quiz';

  @override
  void initState() {
    super.initState();
    _rng = Random(_ctx.gameSeed.hashCode);
    // Shuffle question indices
    _questionOrder = List.generate(_allQuestions.length, (i) => i);
    _questionOrder.shuffle(_rng);
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

  double get _multiplier {
    if (_streak >= 10) return 3.0;
    if (_streak >= 5) return 2.0;
    if (_streak >= 3) return 1.5;
    return 1.0;
  }

  _Q get _currentQuestion {
    final idx = _questionOrder[_currentQIndex % _questionOrder.length];
    return _allQuestions[idx];
  }

  void _selectAnswer(int index) {
    if (_showingResult || _gameOver) return;

    final q = _currentQuestion;
    final isCorrect = index == q.correctIndex;

    int points = 0;
    if (isCorrect) {
      _streak++;
      _correctCount++;
      points = (10 * _multiplier).round();
    } else {
      _streak = 0;
    }

    setState(() {
      _selectedAnswer = index;
      _showingResult = true;
      _score += points;
      _questionsAnswered++;
    });

    // Auto-advance fast
    _resultTimer = Timer(const Duration(milliseconds: 300), () {
      if (mounted && !_gameOver) {
        setState(() {
          _currentQIndex++;
          _selectedAnswer = -1;
          _showingResult = false;
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
      _questionsAnswered = savedState['questionsAnswered'] as int? ?? 0;
      _streak = savedState['streak'] as int? ?? 0;
      _currentQIndex = savedState['currentQIndex'] as int? ?? 0;
    });
  }

  @override
  Map<String, dynamic> getCurrentState() {
    return {
      'score': _score,
      'timeRemaining': _timeRemaining,
      'questionsAnswered': _questionsAnswered,
      'streak': _streak,
      'currentQIndex': _currentQIndex,
    };
  }

  @override
  Widget build(BuildContext context) {
    if (_gameOver) return _buildGameOver();

    final q = _currentQuestion;

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
              Text(
                q.question,
                style: const TextStyle(
                  fontSize: 20,
                  fontWeight: FontWeight.w600,
                  color: _kPrimary,
                ),
                textAlign: TextAlign.center,
                maxLines: 3,
                overflow: TextOverflow.ellipsis,
              ),
              const SizedBox(height: 24),
              ...List.generate(4, (i) => _buildOption(i, q)),
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
        Row(
          children: [
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
              decoration: BoxDecoration(
                color: _kPrimary,
                borderRadius: BorderRadius.circular(12),
              ),
              child: Text(
                'Score: $_score',
                style: const TextStyle(
                  color: Colors.white,
                  fontWeight: FontWeight.w600,
                  fontSize: 13,
                ),
              ),
            ),
            const SizedBox(width: 8),
            if (_streak >= 3)
              Container(
                padding:
                    const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                decoration: BoxDecoration(
                  color: Colors.orange,
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Text(
                  '${_multiplier}x',
                  style: const TextStyle(
                    color: Colors.white,
                    fontWeight: FontWeight.bold,
                    fontSize: 13,
                  ),
                ),
              ),
          ],
        ),
        Row(
          children: [
            Icon(Icons.local_fire_department_rounded,
                size: 18,
                color: _streak > 0 ? Colors.orange : Colors.grey.shade300),
            const SizedBox(width: 2),
            Text(
              '$_streak',
              style: TextStyle(
                fontSize: 14,
                fontWeight: FontWeight.w600,
                color: _streak > 0 ? Colors.orange : _kSecondary,
              ),
            ),
          ],
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
        const SizedBox(height: 2),
        Text(
          '${_timeRemaining}s',
          style: TextStyle(
              fontSize: 12, color: color, fontWeight: FontWeight.w600),
        ),
      ],
    );
  }

  Widget _buildOption(int index, _Q q) {
    Color bg = Colors.grey.shade100;
    Color textColor = _kPrimary;

    if (_showingResult) {
      if (index == q.correctIndex) {
        bg = Colors.green;
        textColor = Colors.white;
      } else if (index == _selectedAnswer && index != q.correctIndex) {
        bg = Colors.red;
        textColor = Colors.white;
      }
    }

    return Padding(
      padding: const EdgeInsets.only(bottom: 8),
      child: SizedBox(
        height: 48,
        child: ElevatedButton(
          onPressed: _showingResult ? null : () => _selectAnswer(index),
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
            q.options[index],
            style: TextStyle(
              fontSize: 15,
              fontWeight: FontWeight.w500,
              color: textColor,
            ),
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
          ),
        ),
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
                const Icon(Icons.speed_rounded, size: 64, color: _kPrimary),
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
                  '$_correctCount correct of $_questionsAnswered answered',
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
