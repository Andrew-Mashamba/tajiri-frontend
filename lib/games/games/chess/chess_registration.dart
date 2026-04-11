// lib/games/games/chess/chess_registration.dart

import 'package:flutter/material.dart';
import '../../core/game_context.dart';
import '../../core/game_definition.dart';
import '../../core/game_enums.dart';
import '../../core/game_registry.dart';
import 'chess_game.dart';

void registerChess() {
  GameRegistry.instance.register(
    GameDefinition(
      id: 'chess',
      name: 'Chess',
      nameSwahili: 'Chesi',
      description: 'Classic chess with 5-minute clock',
      descriptionSwahili: 'Chesi ya kawaida na saa dakika 5',
      category: GameCategory.board,
      icon: Icons.castle_rounded,
      minPlayers: 1,
      maxPlayers: 2,
      estimatedMinutes: 5,
      modes: [GameMode.practice, GameMode.friend, GameMode.ranked],
      stakeSafe: true,
      maxStakeTier: StakeTier.diamond,
      imagePath: 'assets/images/games/chess.png',
      builder: (GameContext context) => ChessGame(gameContext: context),
    ),
  );
}
