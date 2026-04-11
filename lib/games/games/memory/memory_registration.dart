// lib/games/games/memory/memory_registration.dart

import 'package:flutter/material.dart';
import '../../core/game_context.dart';
import '../../core/game_definition.dart';
import '../../core/game_enums.dart';
import '../../core/game_registry.dart';
import 'memory_game.dart';

void registerMemory() {
  GameRegistry.instance.register(
    GameDefinition(
      id: 'memory',
      name: 'Memory Match',
      nameSwahili: 'Kumbuka Kadi',
      description: 'Find all matching pairs as fast as you can!',
      descriptionSwahili: 'Tafuta jozi zote haraka uwezavyo!',
      category: GameCategory.card,
      icon: Icons.dashboard_rounded,
      minPlayers: 1,
      maxPlayers: 2,
      estimatedMinutes: 2,
      modes: [GameMode.practice, GameMode.friend, GameMode.ranked],
      stakeSafe: true,
      maxStakeTier: StakeTier.diamond,
      imagePath: 'assets/images/games/memory.png',
      builder: (GameContext context) =>
          MemoryGame(gameContext: context),
    ),
  );
}
