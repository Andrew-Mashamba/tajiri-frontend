// lib/games/games/twenty48/twenty48_registration.dart

import 'package:flutter/material.dart';
import '../../core/game_context.dart';
import '../../core/game_definition.dart';
import '../../core/game_enums.dart';
import '../../core/game_registry.dart';
import 'twenty48_game.dart';

void registerTwenty48() {
  GameRegistry.instance.register(
    GameDefinition(
      id: 'twenty48',
      name: '2048',
      nameSwahili: '2048',
      description: 'Slide and merge tiles to reach 2048!',
      descriptionSwahili: 'Sogeza na unganisha vigae kufikia 2048!',
      category: GameCategory.puzzle,
      icon: Icons.grid_4x4_rounded,
      minPlayers: 1,
      maxPlayers: 2,
      estimatedMinutes: 3,
      modes: [GameMode.practice, GameMode.friend, GameMode.ranked],
      stakeSafe: true,
      maxStakeTier: StakeTier.diamond,
      imagePath: 'assets/images/games/twenty48.png',
      builder: (GameContext context) => Twenty48Game(gameContext: context),
    ),
  );
}
