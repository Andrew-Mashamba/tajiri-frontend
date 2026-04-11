// lib/games/games/block_puzzle/block_puzzle_registration.dart

import 'package:flutter/material.dart';
import '../../core/game_context.dart';
import '../../core/game_definition.dart';
import '../../core/game_enums.dart';
import '../../core/game_registry.dart';
import 'block_puzzle_game.dart';

void registerBlockPuzzle() {
  GameRegistry.instance.register(
    GameDefinition(
      id: 'block_puzzle',
      name: 'Block Puzzle',
      nameSwahili: 'Fumbo la Vitalu',
      description: 'Place blocks to clear rows and columns!',
      descriptionSwahili: 'Weka vitalu kufuta safu na nguzo!',
      category: GameCategory.puzzle,
      icon: Icons.view_module_rounded,
      minPlayers: 1,
      maxPlayers: 2,
      estimatedMinutes: 3,
      modes: [GameMode.practice, GameMode.friend, GameMode.ranked],
      stakeSafe: true,
      maxStakeTier: StakeTier.diamond,
      imagePath: 'assets/images/games/block_puzzle.png',
      builder: (GameContext context) => BlockPuzzleGame(gameContext: context),
    ),
  );
}
