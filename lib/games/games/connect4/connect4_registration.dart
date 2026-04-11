// lib/games/games/connect4/connect4_registration.dart

import 'package:flutter/material.dart';
import '../../core/game_context.dart';
import '../../core/game_definition.dart';
import '../../core/game_enums.dart';
import '../../core/game_registry.dart';
import 'connect4_game.dart';

void registerConnect4() {
  GameRegistry.instance.register(
    GameDefinition(
      id: 'connect4',
      name: 'Connect Four',
      nameSwahili: 'Unganisha Nne',
      description: 'Drop discs to connect four in a row!',
      descriptionSwahili: 'Weka diski kuunganisha nne mfululizo!',
      category: GameCategory.strategy,
      icon: Icons.view_week_rounded,
      minPlayers: 1,
      maxPlayers: 2,
      estimatedMinutes: 3,
      modes: [GameMode.practice, GameMode.friend, GameMode.ranked],
      stakeSafe: true,
      maxStakeTier: StakeTier.diamond,
      imagePath: 'assets/images/games/connect4.png',
      builder: (GameContext context) => Connect4Game(gameContext: context),
    ),
  );
}
