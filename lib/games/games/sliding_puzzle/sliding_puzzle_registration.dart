// lib/games/games/sliding_puzzle/sliding_puzzle_registration.dart

import 'package:flutter/material.dart';
import '../../core/game_context.dart';
import '../../core/game_definition.dart';
import '../../core/game_enums.dart';
import '../../core/game_registry.dart';
import 'sliding_puzzle_game.dart';

void registerSlidingPuzzle() {
  GameRegistry.instance.register(
    GameDefinition(
      id: 'sliding_puzzle',
      name: 'Sliding Puzzle',
      nameSwahili: 'Fumbo la Kuteleza',
      description:
          'Slide tiles into order! Classic 15-puzzle — fewest moves wins.',
      descriptionSwahili:
          'Teleza vigae kwa mpangilio! Fumbo la 15 — hatua chache kushinda.',
      category: GameCategory.puzzle,
      icon: Icons.swap_calls_rounded,
      minPlayers: 1,
      maxPlayers: 2,
      estimatedMinutes: 2,
      modes: [GameMode.practice, GameMode.friend, GameMode.ranked],
      stakeSafe: true,
      maxStakeTier: StakeTier.diamond,
      imagePath: 'assets/images/games/sliding_puzzle.png',
      builder: (GameContext context) =>
          SlidingPuzzleGame(gameContext: context),
    ),
  );
}
