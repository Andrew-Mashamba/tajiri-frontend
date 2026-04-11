// lib/games/games_module.dart
//
// Entry point for the Games module.
// Provides GamesModule widget and re-exports core types for convenience.

import 'package:flutter/material.dart';
import 'pages/games_home_page.dart';

import 'games/trivia/trivia_registration.dart';
import 'games/twenty48/twenty48_registration.dart';
import 'games/speed_math/speed_math_registration.dart';
import 'games/reaction/reaction_registration.dart';
import 'games/tap_speed/tap_speed_registration.dart';
import 'games/bao/bao_registration.dart';
import 'games/kadi/kadi_registration.dart';
import 'games/ludo/ludo_registration.dart';
import 'games/chess/chess_registration.dart';
import 'games/checkers/checkers_registration.dart';
import 'games/swahili_quiz/swahili_quiz_registration.dart';
import 'games/word_guess/word_guess_registration.dart';
import 'games/sudoku/sudoku_registration.dart';
import 'games/anagram/anagram_registration.dart';
import 'games/memory/memory_registration.dart';
import 'games/snap/snap_registration.dart';
import 'games/dots_boxes/dots_boxes_registration.dart';
import 'games/connect4/connect4_registration.dart';
import 'games/snake/snake_registration.dart';
import 'games/block_puzzle/block_puzzle_registration.dart';
import 'games/word_chain/word_chain_registration.dart';
import 'games/speed_quiz/speed_quiz_registration.dart';
import 'games/ultimate_ttt/ultimate_ttt_registration.dart';
import 'games/number_seq/number_seq_registration.dart';
import 'games/sliding_puzzle/sliding_puzzle_registration.dart';

// Re-export core types for convenience
export 'core/game_enums.dart';
export 'core/game_definition.dart';
export 'core/game_interface.dart';
export 'core/game_context.dart';
export 'core/game_registry.dart';

/// Top-level module widget. Renders inside _ProfileTabPage (no AppBar).
class GamesModule extends StatelessWidget {
  final int userId;
  const GamesModule({super.key, required this.userId});

  static bool _registered = false;
  static void _registerGames() {
    if (_registered) return;
    _registered = true;
    registerTrivia();
    registerTwenty48();
    registerSpeedMath();
    registerReaction();
    registerTapSpeed();
    registerBao();
    registerKadi();
    registerLudo();
    registerChess();
    registerCheckers();
    registerSwahiliQuiz();
    registerWordGuess();
    registerSudoku();
    registerAnagram();
    registerMemory();
    registerSnap();
    registerDotsBoxes();
    registerConnect4();
    registerSnake();
    registerBlockPuzzle();
    registerWordChain();
    registerSpeedQuiz();
    registerUltimateTtt();
    registerNumberSeq();
    registerSlidingPuzzle();
  }

  @override
  Widget build(BuildContext context) {
    _registerGames();
    return GamesHomePage(userId: userId);
  }
}
