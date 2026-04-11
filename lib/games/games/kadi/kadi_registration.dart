// lib/games/games/kadi/kadi_registration.dart

import 'package:flutter/material.dart';
import '../../core/game_context.dart';
import '../../core/game_definition.dart';
import '../../core/game_enums.dart';
import '../../core/game_registry.dart';
import 'kadi_game.dart';

void registerKadi() {
  GameRegistry.instance.register(
    GameDefinition(
      id: 'kadi',
      name: 'Kadi',
      nameSwahili: 'Kadi',
      description: 'East African card shedding game with special cards',
      descriptionSwahili: 'Mchezo wa kadi wa Afrika Mashariki wenye kadi maalum',
      category: GameCategory.card,
      icon: Icons.style_rounded,
      minPlayers: 1,
      maxPlayers: 2,
      estimatedMinutes: 3,
      modes: [GameMode.practice, GameMode.friend, GameMode.ranked],
      stakeSafe: true,
      maxStakeTier: StakeTier.diamond,
      imagePath: 'assets/images/games/kadi.png',
      builder: (GameContext context) => KadiGame(gameContext: context),
    ),
  );
}
