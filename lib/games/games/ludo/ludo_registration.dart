// lib/games/games/ludo/ludo_registration.dart

import 'package:flutter/material.dart';
import '../../core/game_context.dart';
import '../../core/game_definition.dart';
import '../../core/game_enums.dart';
import '../../core/game_registry.dart';
import 'ludo_game.dart';

void registerLudo() {
  GameRegistry.instance.register(
    GameDefinition(
      id: 'ludo',
      name: 'Ludo',
      nameSwahili: 'Ludo',
      description: 'Race your tokens home before your opponent',
      descriptionSwahili: 'Fikisha vipande vyako nyumbani kabla ya mpinzani',
      category: GameCategory.board,
      icon: Icons.casino_rounded,
      minPlayers: 1,
      maxPlayers: 2,
      estimatedMinutes: 5,
      modes: [GameMode.practice, GameMode.friend, GameMode.ranked],
      stakeSafe: false,
      maxStakeTier: StakeTier.gold,
      imagePath: 'assets/images/games/ludo.png',
      builder: (GameContext context) => LudoGame(gameContext: context),
    ),
  );
}
