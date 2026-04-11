// lib/games/games/ultimate_ttt/ultimate_ttt_registration.dart

import 'package:flutter/material.dart';
import '../../core/game_context.dart';
import '../../core/game_definition.dart';
import '../../core/game_enums.dart';
import '../../core/game_registry.dart';
import 'ultimate_ttt_game.dart';

void registerUltimateTtt() {
  GameRegistry.instance.register(
    GameDefinition(
      id: 'ultimate_ttt',
      name: 'Ultimate Tic-Tac-Toe',
      nameSwahili: 'Tic-Tac-Toe Kubwa',
      description:
          'Tic-Tac-Toe within Tic-Tac-Toe! Win small boards to claim the big one.',
      descriptionSwahili:
          'Tic-Tac-Toe ndani ya Tic-Tac-Toe! Shinda bodi ndogo kupata kubwa.',
      category: GameCategory.strategy,
      icon: Icons.apps_rounded,
      minPlayers: 1,
      maxPlayers: 2,
      estimatedMinutes: 3,
      modes: [GameMode.practice, GameMode.friend, GameMode.ranked],
      stakeSafe: true,
      maxStakeTier: StakeTier.diamond,
      imagePath: 'assets/images/games/ultimate_ttt.png',
      builder: (GameContext context) => UltimateTttGame(gameContext: context),
    ),
  );
}
