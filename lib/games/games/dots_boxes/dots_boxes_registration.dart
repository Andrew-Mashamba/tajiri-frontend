// lib/games/games/dots_boxes/dots_boxes_registration.dart

import 'package:flutter/material.dart';
import '../../core/game_context.dart';
import '../../core/game_definition.dart';
import '../../core/game_enums.dart';
import '../../core/game_registry.dart';
import 'dots_boxes_game.dart';

void registerDotsBoxes() {
  GameRegistry.instance.register(
    GameDefinition(
      id: 'dots_boxes',
      name: 'Dots & Boxes',
      nameSwahili: 'Nukta na Sanduku',
      description: 'Draw lines to complete boxes and outscore your opponent!',
      descriptionSwahili: 'Chora mistari kukamilisha sanduku na kushinda mpinzani!',
      category: GameCategory.strategy,
      icon: Icons.grid_4x4_rounded,
      minPlayers: 1,
      maxPlayers: 2,
      estimatedMinutes: 3,
      modes: [GameMode.practice, GameMode.friend, GameMode.ranked],
      stakeSafe: true,
      maxStakeTier: StakeTier.diamond,
      imagePath: 'assets/images/games/dots_boxes.png',
      builder: (GameContext context) => DotsBoxesGame(gameContext: context),
    ),
  );
}
