// lib/games/games/snap/snap_registration.dart

import 'package:flutter/material.dart';
import '../../core/game_context.dart';
import '../../core/game_definition.dart';
import '../../core/game_enums.dart';
import '../../core/game_registry.dart';
import 'snap_game.dart';

void registerSnap() {
  GameRegistry.instance.register(
    GameDefinition(
      id: 'snap',
      name: 'Snap',
      nameSwahili: 'Snapi',
      description: 'Fast reaction card game — snap matching cards!',
      descriptionSwahili: 'Mchezo wa kadi wa haraka — snapi kadi zinazofanana!',
      category: GameCategory.card,
      icon: Icons.bolt_rounded,
      minPlayers: 1,
      maxPlayers: 2,
      estimatedMinutes: 2,
      modes: [GameMode.practice, GameMode.friend, GameMode.ranked],
      stakeSafe: true,
      maxStakeTier: StakeTier.diamond,
      imagePath: 'assets/images/games/snap.png',
      builder: (GameContext context) => SnapGame(gameContext: context),
    ),
  );
}
