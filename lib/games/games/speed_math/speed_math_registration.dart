// lib/games/games/speed_math/speed_math_registration.dart

import 'package:flutter/material.dart';
import '../../core/game_context.dart';
import '../../core/game_definition.dart';
import '../../core/game_enums.dart';
import '../../core/game_registry.dart';
import 'speed_math_game.dart';

void registerSpeedMath() {
  GameRegistry.instance.register(
    GameDefinition(
      id: 'speed_math',
      name: 'Speed Math',
      nameSwahili: 'Hesabu Haraka',
      description: 'Solve as many math problems as you can in 60 seconds!',
      descriptionSwahili: 'Tatua hesabu nyingi uwezavyo ndani ya sekunde 60!',
      category: GameCategory.math,
      icon: Icons.calculate_rounded,
      minPlayers: 1,
      maxPlayers: 2,
      estimatedMinutes: 1,
      modes: [GameMode.practice, GameMode.friend, GameMode.ranked],
      stakeSafe: true,
      maxStakeTier: StakeTier.diamond,
      imagePath: 'assets/images/games/speed_math.png',
      builder: (GameContext context) => SpeedMathGame(gameContext: context),
    ),
  );
}
