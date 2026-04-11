// lib/games/games/bao/bao_registration.dart

import 'package:flutter/material.dart';
import '../../core/game_context.dart';
import '../../core/game_definition.dart';
import '../../core/game_enums.dart';
import '../../core/game_registry.dart';
import 'bao_game.dart';

void registerBao() {
  GameRegistry.instance.register(
    GameDefinition(
      id: 'bao',
      name: 'Bao la Kiswahili',
      nameSwahili: 'Bao la Kiswahili',
      description: 'Tanzania\'s ancient board game of strategy',
      descriptionSwahili: 'Mchezo wa bao wa jadi wa Tanzania',
      category: GameCategory.board,
      icon: Icons.circle_outlined,
      minPlayers: 1,
      maxPlayers: 2,
      estimatedMinutes: 5,
      modes: [GameMode.practice, GameMode.friend, GameMode.ranked],
      stakeSafe: true,
      maxStakeTier: StakeTier.diamond,
      imagePath: 'assets/images/games/bao.png',
      builder: (GameContext context) => BaoGame(gameContext: context),
    ),
  );
}
