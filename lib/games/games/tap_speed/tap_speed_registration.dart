// lib/games/games/tap_speed/tap_speed_registration.dart

import 'package:flutter/material.dart';
import '../../core/game_context.dart';
import '../../core/game_definition.dart';
import '../../core/game_enums.dart';
import '../../core/game_registry.dart';
import 'tap_speed_game.dart';

void registerTapSpeed() {
  GameRegistry.instance.register(
    GameDefinition(
      id: 'tap_speed',
      name: 'Tap Speed',
      nameSwahili: 'Kasi ya Vidole',
      description: 'Tap as fast as you can in 10 seconds!',
      descriptionSwahili: 'Gonga haraka uwezavyo ndani ya sekunde 10!',
      category: GameCategory.arcade,
      icon: Icons.touch_app_rounded,
      minPlayers: 1,
      maxPlayers: 2,
      estimatedMinutes: 1,
      modes: [GameMode.practice, GameMode.friend, GameMode.ranked],
      stakeSafe: true,
      maxStakeTier: StakeTier.diamond,
      imagePath: 'assets/images/games/tap_speed.png',
      builder: (GameContext context) => TapSpeedGame(gameContext: context),
    ),
  );
}
