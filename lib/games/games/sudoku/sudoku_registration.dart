// lib/games/games/sudoku/sudoku_registration.dart

import 'package:flutter/material.dart';
import '../../core/game_context.dart';
import '../../core/game_definition.dart';
import '../../core/game_enums.dart';
import '../../core/game_registry.dart';
import 'sudoku_game.dart';

void registerSudoku() {
  GameRegistry.instance.register(
    GameDefinition(
      id: 'sudoku',
      name: 'Sudoku Duel',
      nameSwahili: 'Sudoku',
      description: 'Solve the puzzle faster than your opponent!',
      descriptionSwahili: 'Tatua fumbo haraka kuliko mpinzani wako!',
      category: GameCategory.puzzle,
      icon: Icons.grid_3x3_rounded,
      minPlayers: 1,
      maxPlayers: 2,
      estimatedMinutes: 5,
      modes: [GameMode.practice, GameMode.friend, GameMode.ranked],
      stakeSafe: true,
      maxStakeTier: StakeTier.gold,
      imagePath: 'assets/images/games/sudoku.png',
      builder: (GameContext context) =>
          SudokuGame(gameContext: context),
    ),
  );
}
