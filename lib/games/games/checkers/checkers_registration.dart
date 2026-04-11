// lib/games/games/checkers/checkers_registration.dart

import 'package:flutter/material.dart';
import '../../core/game_context.dart';
import '../../core/game_definition.dart';
import '../../core/game_enums.dart';
import '../../core/game_registry.dart';
import 'checkers_game.dart';

void registerCheckers() {
  GameRegistry.instance.register(
    GameDefinition(
      id: 'checkers',
      name: 'Checkers',
      nameSwahili: 'Dama',
      description: 'Classic checkers with mandatory captures',
      descriptionSwahili: 'Mchezo wa dama na kukamata lazima',
      category: GameCategory.board,
      icon: Icons.grid_on_rounded,
      minPlayers: 1,
      maxPlayers: 2,
      estimatedMinutes: 3,
      modes: [GameMode.practice, GameMode.friend, GameMode.ranked],
      stakeSafe: true,
      maxStakeTier: StakeTier.diamond,
      imagePath: 'assets/images/games/checkers.png',
      builder: (GameContext context) => CheckersGame(gameContext: context),
    ),
  );
}
