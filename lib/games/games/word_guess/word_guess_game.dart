// lib/games/games/word_guess/word_guess_game.dart

import 'dart:math';

import 'package:flutter/material.dart';

import '../../core/game_context.dart' as gc;
import '../../core/game_enums.dart';
import '../../core/game_interface.dart';

const Color _kPrimary = Color(0xFF1A1A1A);
const Color _kSecondary = Color(0xFF666666);

// 200+ common 5-letter English words
const List<String> _kWordPool = [
  'about', 'above', 'abuse', 'actor', 'adapt', 'admit', 'adopt', 'adult',
  'after', 'again', 'agent', 'agree', 'ahead', 'alarm', 'album', 'alert',
  'alien', 'align', 'alike', 'alive', 'alley', 'allow', 'alone', 'along',
  'alter', 'amino', 'among', 'ample', 'angel', 'anger', 'angle', 'angry',
  'anime', 'ankle', 'apart', 'apple', 'apply', 'arena', 'argue', 'arise',
  'armor', 'array', 'arrow', 'aside', 'asset', 'audio', 'audit', 'avoid',
  'award', 'aware', 'badly', 'baker', 'basic', 'basin', 'basis', 'batch',
  'beach', 'beard', 'beast', 'begin', 'being', 'below', 'bench', 'berry',
  'bible', 'birth', 'black', 'blade', 'blame', 'bland', 'blank', 'blast',
  'blaze', 'bleed', 'blend', 'bless', 'blind', 'block', 'blood', 'bloom',
  'blown', 'board', 'boost', 'bound', 'brain', 'brand', 'brave', 'bread',
  'break', 'breed', 'brick', 'bride', 'brief', 'bring', 'broad', 'brook',
  'brown', 'brush', 'buddy', 'build', 'bunch', 'burst', 'buyer', 'cabin',
  'cable', 'candy', 'cargo', 'carry', 'catch', 'cause', 'cedar', 'chain',
  'chair', 'chalk', 'champ', 'chaos', 'charm', 'chart', 'chase', 'cheap',
  'check', 'cheek', 'cheer', 'chess', 'chest', 'chief', 'child', 'china',
  'chunk', 'civic', 'civil', 'claim', 'clash', 'class', 'clean', 'clear',
  'clerk', 'click', 'cliff', 'climb', 'cling', 'clock', 'clone', 'close',
  'cloth', 'cloud', 'coach', 'coast', 'color', 'comet', 'comic', 'coral',
  'count', 'court', 'cover', 'crack', 'craft', 'crane', 'crash', 'crazy',
  'cream', 'crest', 'crime', 'cross', 'crowd', 'crown', 'crush', 'curve',
  'cycle', 'daily', 'dance', 'death', 'debug', 'decay', 'delay', 'delta',
  'dense', 'depot', 'depth', 'derby', 'devil', 'digit', 'dirty', 'disco',
  'donor', 'doubt', 'dough', 'draft', 'drain', 'drake', 'drama', 'drank',
  'drawn', 'dream', 'dress', 'dried', 'drift', 'drill', 'drink', 'drive',
  'drone', 'drops', 'drove', 'dying', 'eager', 'eagle', 'early', 'earth',
  'eight', 'elect', 'elite', 'email', 'empty', 'enemy', 'enjoy', 'enter',
  'entry', 'equal', 'error', 'essay', 'event', 'every', 'exact', 'exile',
  'exist', 'extra', 'faint', 'fairy', 'faith', 'false', 'fancy', 'fatal',
  'fault', 'feast', 'fence', 'ferry', 'fever', 'fiber', 'field', 'fifth',
  'fifty', 'fight', 'final', 'first', 'fixed', 'flame', 'flash', 'fleet',
  'flesh', 'float', 'flood', 'floor', 'flora', 'flour', 'fluid', 'flush',
  'focal', 'focus', 'force', 'forge', 'forth', 'forum', 'found', 'frame',
  'frank', 'fraud', 'fresh', 'front', 'frost', 'fruit', 'fully', 'giant',
  'given', 'ghost', 'glass', 'globe', 'gloom', 'glory', 'glove', 'going',
  'grace', 'grade', 'grain', 'grand', 'grant', 'grape', 'graph', 'grasp',
  'grass', 'grave', 'great', 'green', 'greet', 'grief', 'grill', 'grind',
  'gross', 'group', 'grove', 'grown', 'guard', 'guess', 'guest', 'guide',
  'guild', 'guilt', 'happy', 'harsh', 'haven', 'heard', 'heart', 'heavy',
  'herbs', 'honey', 'honor', 'horse', 'hotel', 'house', 'human', 'humor',
  'hurry', 'hyper', 'ideal', 'image', 'imply', 'inbox', 'index', 'indie',
  'inner', 'input', 'inter', 'irony', 'ivory', 'jewel', 'joint', 'joker',
  'judge', 'juice', 'knock', 'known', 'label', 'labor', 'large', 'laser',
  'later', 'laugh', 'layer', 'learn', 'lease', 'least', 'legal', 'lemon',
  'level', 'light', 'limit', 'linen', 'liver', 'local', 'logic', 'lonely',
  'loose', 'lover', 'lucky', 'lunar', 'lunch', 'lying', 'magic', 'major',
  'maker', 'manor', 'maple', 'march', 'marry', 'match', 'mayor', 'media',
  'mercy', 'merge', 'merit', 'merry', 'metal', 'meter', 'might', 'minor',
  'minus', 'mixed', 'model', 'money', 'month', 'moral', 'motor', 'mount',
  'mouse', 'mouth', 'movie', 'music', 'naive', 'nerve', 'never', 'newly',
  'night', 'noble', 'noise', 'north', 'noted', 'novel', 'nurse', 'occur',
  'ocean', 'offer', 'often', 'olive', 'onset', 'opera', 'orbit', 'order',
  'organ', 'other', 'outer', 'owner', 'oxide', 'ozone', 'paced', 'paint',
  'panel', 'panic', 'paper', 'paste', 'patch', 'pause', 'peace', 'pearl',
  'penny', 'phase', 'phone', 'photo', 'piano', 'piece', 'pilot', 'pitch',
  'pixel', 'pizza', 'place', 'plain', 'plane', 'plant', 'plate', 'plaza',
  'plead', 'plumb', 'plume', 'point', 'polar', 'pound', 'power', 'press',
  'price', 'pride', 'prime', 'print', 'prior', 'prize', 'probe', 'proof',
  'proud', 'prove', 'proxy', 'psalm', 'pulse', 'punch', 'pupil', 'purse',
  'queen', 'query', 'quest', 'queue', 'quick', 'quiet', 'quite', 'quota',
  'quote', 'radar', 'radio', 'raise', 'rally', 'ranch', 'range', 'rapid',
  'ratio', 'reach', 'ready', 'realm', 'rebel', 'reign', 'relax', 'reply',
  'rider', 'ridge', 'rifle', 'right', 'rigid', 'risky', 'rival', 'river',
  'robin', 'robot', 'rocky', 'round', 'route', 'royal', 'rugby', 'rural',
  'sadly', 'saint', 'salad', 'scale', 'scare', 'scene', 'scope', 'score',
  'sense', 'serve', 'seven', 'shade', 'shake', 'shall', 'shame', 'shape',
  'share', 'shark', 'sharp', 'sheep', 'sheer', 'sheet', 'shelf', 'shell',
  'shift', 'shine', 'shirt', 'shock', 'shoot', 'shore', 'short', 'shout',
  'sight', 'sigma', 'since', 'sixth', 'sixty', 'skill', 'sleep', 'slice',
  'slide', 'slope', 'smart', 'smell', 'smile', 'smoke', 'snake', 'solar',
  'solid', 'solve', 'sorry', 'sound', 'south', 'space', 'spare', 'spark',
  'speak', 'speed', 'spend', 'spice', 'spine', 'spite', 'spoke', 'spoon',
  'sport', 'spray', 'squad', 'stack', 'staff', 'stage', 'stain', 'stake',
  'stall', 'stamp', 'stand', 'stark', 'start', 'state', 'stays', 'steal',
  'steam', 'steel', 'steep', 'steer', 'stern', 'stick', 'stiff', 'still',
  'stock', 'stone', 'stood', 'store', 'storm', 'story', 'stove', 'stuff',
  'style', 'sugar', 'suite', 'sunny', 'super', 'surge', 'swamp', 'swear',
  'sweep', 'sweet', 'swept', 'swing', 'sword', 'syrup', 'table', 'taken',
  'taste', 'teach', 'teeth', 'tempo', 'tends', 'thick', 'thing', 'think',
  'third', 'those', 'three', 'throw', 'thumb', 'tiger', 'tight', 'timer',
  'tired', 'title', 'today', 'token', 'tooth', 'total', 'touch', 'tough',
  'tower', 'toxic', 'trace', 'track', 'trade', 'trail', 'train', 'trait',
  'trash', 'treat', 'trend', 'trial', 'tribe', 'trick', 'tried', 'troop',
  'truck', 'truly', 'trump', 'trunk', 'trust', 'truth', 'tumor', 'twice',
  'twist', 'ultra', 'uncle', 'under', 'union', 'unite', 'unity', 'until',
  'upper', 'upset', 'urban', 'usage', 'usual', 'utter', 'valid', 'value',
  'vapor', 'vault', 'venue', 'verse', 'vigor', 'viral', 'virus', 'visit',
  'vital', 'vivid', 'vocal', 'voice', 'voter', 'wages', 'waste', 'watch',
  'water', 'weary', 'weave', 'wedge', 'weird', 'wheat', 'wheel', 'where',
  'which', 'while', 'white', 'whole', 'whose', 'widow', 'width', 'woman',
  'world', 'worry', 'worse', 'worst', 'worth', 'would', 'wound', 'wrath',
  'write', 'wrote', 'yacht', 'yield', 'young', 'youth', 'zebra',
];

// Valid guesses = same pool (for simplicity, we accept any word from the pool)
final Set<String> _kValidWords = _kWordPool.toSet();

class WordGuessGame extends StatefulWidget {
  final gc.GameContext gameContext;
  const WordGuessGame({super.key, required this.gameContext});

  @override
  State<WordGuessGame> createState() => WordGuessGameState();
}

class WordGuessGameState extends State<WordGuessGame>
    with SingleTickerProviderStateMixin
    implements GameInterface {
  late final String _targetWord;
  final List<String> _guesses = [];
  String _currentGuess = '';
  bool _gameOver = false;
  bool _won = false;
  bool _shaking = false;
  String _message = '';

  // Keyboard state: letter -> color (0=unused, 1=grey, 2=yellow, 3=green)
  final Map<String, int> _keyStates = {};

  gc.GameContext get _ctx => widget.gameContext;

  @override
  String get gameId => 'word_guess';

  @override
  void initState() {
    super.initState();
    final rng = Random(_ctx.gameSeed.hashCode);
    _targetWord = _kWordPool[rng.nextInt(_kWordPool.length)];
  }

  void _onKeyTap(String key) {
    if (_gameOver) return;

    if (key == 'ENTER') {
      _submitGuess();
    } else if (key == 'DEL') {
      if (_currentGuess.isNotEmpty) {
        setState(() {
          _currentGuess = _currentGuess.substring(0, _currentGuess.length - 1);
          _message = '';
        });
      }
    } else if (_currentGuess.length < 5) {
      setState(() {
        _currentGuess += key.toLowerCase();
        _message = '';
      });
    }
  }

  void _submitGuess() {
    if (_currentGuess.length != 5) {
      _showShake('Not enough letters');
      return;
    }
    if (!_kValidWords.contains(_currentGuess)) {
      _showShake('Not in word list');
      return;
    }

    setState(() {
      _guesses.add(_currentGuess);
      _updateKeyStates(_currentGuess);

      if (_currentGuess == _targetWord) {
        _won = true;
        _gameOver = true;
        _message = 'Brilliant! / Bora sana!';
      } else if (_guesses.length >= 6) {
        _gameOver = true;
        _message = 'The word was: ${_targetWord.toUpperCase()}';
      }
      _currentGuess = '';
    });

    if (_gameOver) {
      final score = _won ? (7 - _guesses.length) * 10 : 0;
      final winnerId =
          (_ctx.mode == GameMode.practice) ? (_won ? _ctx.userId : null) : _ctx.userId;
      _ctx.onGameComplete({
        'winner_id': winnerId,
        'player_1_score': score,
        'player_2_score': 0,
      });
    }
  }

  void _showShake(String msg) {
    setState(() {
      _shaking = true;
      _message = msg;
    });
    Future.delayed(const Duration(milliseconds: 500), () {
      if (mounted) setState(() => _shaking = false);
    });
  }

  void _updateKeyStates(String guess) {
    for (int i = 0; i < 5; i++) {
      final letter = guess[i];
      if (_targetWord[i] == letter) {
        _keyStates[letter] = 3; // green
      } else if (_targetWord.contains(letter)) {
        if ((_keyStates[letter] ?? 0) < 3) {
          _keyStates[letter] = 2; // yellow (don't downgrade from green)
        }
      } else {
        if (!_keyStates.containsKey(letter)) {
          _keyStates[letter] = 1; // grey
        }
      }
    }
  }

  List<_LetterResult> _evaluateGuess(String guess) {
    final results = List<_LetterResult>.filled(5, _LetterResult.absent);
    final targetChars = _targetWord.split('');
    final guessChars = guess.split('');

    // First pass: correct positions
    for (int i = 0; i < 5; i++) {
      if (guessChars[i] == targetChars[i]) {
        results[i] = _LetterResult.correct;
        targetChars[i] = '_'; // Mark as used
      }
    }
    // Second pass: present but wrong position
    for (int i = 0; i < 5; i++) {
      if (results[i] == _LetterResult.correct) continue;
      final idx = targetChars.indexOf(guessChars[i]);
      if (idx != -1) {
        results[i] = _LetterResult.present;
        targetChars[idx] = '_';
      }
    }
    return results;
  }

  @override
  void onOpponentMove(Map<String, dynamic> moveData) {}

  @override
  void onReconnect(Map<String, dynamic> savedState) {
    final guesses = (savedState['guesses'] as List?)?.cast<String>() ?? [];
    setState(() {
      _guesses.addAll(guesses);
      for (final g in _guesses) {
        _updateKeyStates(g);
      }
    });
  }

  @override
  Map<String, dynamic> getCurrentState() {
    return {'guesses': _guesses, 'target': _targetWord};
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      body: SafeArea(
        child: Column(
          children: [
            const SizedBox(height: 8),
            const Text('Word Guess / Nadhani Neno',
                style: TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                    color: _kPrimary)),
            if (_message.isNotEmpty)
              Padding(
                padding: const EdgeInsets.only(top: 8),
                child: Text(_message,
                    style: TextStyle(
                        fontSize: 14,
                        color: _won ? Colors.green : _kSecondary,
                        fontWeight: FontWeight.w600)),
              ),
            const SizedBox(height: 12),
            Expanded(child: _buildGrid()),
            _buildKeyboard(),
            if (_gameOver)
              Padding(
                padding: const EdgeInsets.all(16),
                child: SizedBox(
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
              ),
          ],
        ),
      ),
    );
  }

  Widget _buildGrid() {
    return Center(
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 40),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: List.generate(6, (row) {
            final isCurrentRow = row == _guesses.length && !_gameOver;
            final isGuessed = row < _guesses.length;
            final guess = isGuessed ? _guesses[row] : (isCurrentRow ? _currentGuess : '');
            final results = isGuessed ? _evaluateGuess(_guesses[row]) : null;

            return Padding(
              padding: const EdgeInsets.only(bottom: 6),
              child: AnimatedContainer(
                duration: const Duration(milliseconds: 100),
                transform: (_shaking && isCurrentRow)
                    // ignore: deprecated_member_use
                    ? (Matrix4.identity()..translate(4.0 * (row.isEven ? 1 : -1)))
                    : Matrix4.identity(),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: List.generate(5, (col) {
                    String letter = col < guess.length ? guess[col].toUpperCase() : '';
                    Color bg = Colors.white;
                    Color border = Colors.grey.shade300;
                    Color textColor = _kPrimary;

                    if (isGuessed && results != null) {
                      switch (results[col]) {
                        case _LetterResult.correct:
                          bg = const Color(0xFF6AAA64);
                          textColor = Colors.white;
                          border = bg;
                          break;
                        case _LetterResult.present:
                          bg = const Color(0xFFC9B458);
                          textColor = Colors.white;
                          border = bg;
                          break;
                        case _LetterResult.absent:
                          bg = const Color(0xFF787C7E);
                          textColor = Colors.white;
                          border = bg;
                          break;
                      }
                    } else if (letter.isNotEmpty) {
                      border = _kPrimary;
                    }

                    return Container(
                      width: 52,
                      height: 52,
                      margin: const EdgeInsets.symmetric(horizontal: 3),
                      decoration: BoxDecoration(
                        color: bg,
                        border: Border.all(color: border, width: 2),
                        borderRadius: BorderRadius.circular(4),
                      ),
                      alignment: Alignment.center,
                      child: Text(
                        letter,
                        style: TextStyle(
                          fontSize: 24,
                          fontWeight: FontWeight.bold,
                          color: textColor,
                        ),
                      ),
                    );
                  }),
                ),
              ),
            );
          }),
        ),
      ),
    );
  }

  Widget _buildKeyboard() {
    const rows = [
      ['Q', 'W', 'E', 'R', 'T', 'Y', 'U', 'I', 'O', 'P'],
      ['A', 'S', 'D', 'F', 'G', 'H', 'J', 'K', 'L'],
      ['ENTER', 'Z', 'X', 'C', 'V', 'B', 'N', 'M', 'DEL'],
    ];

    return Padding(
      padding: const EdgeInsets.only(bottom: 8, left: 4, right: 4),
      child: Column(
        children: rows.map((row) {
          return Padding(
            padding: const EdgeInsets.only(bottom: 4),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: row.map((key) {
                final isSpecial = key == 'ENTER' || key == 'DEL';
                final keyLower = key.toLowerCase();
                final state = _keyStates[keyLower] ?? 0;

                Color bg;
                Color textColor;
                switch (state) {
                  case 3:
                    bg = const Color(0xFF6AAA64);
                    textColor = Colors.white;
                    break;
                  case 2:
                    bg = const Color(0xFFC9B458);
                    textColor = Colors.white;
                    break;
                  case 1:
                    bg = const Color(0xFF787C7E);
                    textColor = Colors.white;
                    break;
                  default:
                    bg = Colors.grey.shade200;
                    textColor = _kPrimary;
                }

                if (isSpecial) {
                  bg = Colors.grey.shade300;
                  textColor = _kPrimary;
                }

                return Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 2),
                  child: GestureDetector(
                    onTap: () => _onKeyTap(key),
                    child: Container(
                      width: isSpecial ? 56 : 32,
                      height: 48,
                      decoration: BoxDecoration(
                        color: bg,
                        borderRadius: BorderRadius.circular(6),
                      ),
                      alignment: Alignment.center,
                      child: Text(
                        key == 'DEL' ? '\u232B' : key,
                        style: TextStyle(
                          fontSize: isSpecial ? 12 : 14,
                          fontWeight: FontWeight.w600,
                          color: textColor,
                        ),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                    ),
                  ),
                );
              }).toList(),
            ),
          );
        }).toList(),
      ),
    );
  }
}

enum _LetterResult { correct, present, absent }
