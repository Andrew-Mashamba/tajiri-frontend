// lib/games/games/snake/snake_registration.dart

import 'package:flutter/material.dart';
import '../../core/game_context.dart';
import '../../core/game_definition.dart';
import '../../core/game_enums.dart';
import '../../core/game_registry.dart';
import 'snake_game.dart';

void registerSnake() {
  GameRegistry.instance.register(
    GameDefinition(
      id: 'snake',
      name: 'Snake',
      nameSwahili: 'Nyoka',
      description: 'Classic snake — eat food, grow, and survive!',
      descriptionSwahili: 'Nyoka wa zamani — kula chakula, kukua, na kuishi!',
      category: GameCategory.arcade,
      icon: Icons.linear_scale_rounded,
      minPlayers: 1,
      maxPlayers: 2,
      estimatedMinutes: 2,
      modes: [GameMode.practice, GameMode.friend, GameMode.ranked],
      stakeSafe: true,
      maxStakeTier: StakeTier.diamond,
      imagePath: 'assets/images/games/snake.png',
      builder: (GameContext context) => SnakeGame(gameContext: context),
    ),
  );
}
