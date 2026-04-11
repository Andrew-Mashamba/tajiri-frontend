// lib/games/games/reaction/reaction_registration.dart

import 'package:flutter/material.dart';
import '../../core/game_context.dart';
import '../../core/game_definition.dart';
import '../../core/game_enums.dart';
import '../../core/game_registry.dart';
import 'reaction_game.dart';

void registerReaction() {
  GameRegistry.instance.register(
    GameDefinition(
      id: 'reaction',
      name: 'Reaction Time',
      nameSwahili: 'Kasi ya Kugonga',
      description: 'Test your reflexes in 5 rounds!',
      descriptionSwahili: 'Jaribu kasi yako katika raundi 5!',
      category: GameCategory.arcade,
      icon: Icons.flash_on_rounded,
      minPlayers: 1,
      maxPlayers: 2,
      estimatedMinutes: 1,
      modes: [GameMode.practice, GameMode.friend, GameMode.ranked],
      stakeSafe: true,
      maxStakeTier: StakeTier.diamond,
      imagePath: 'assets/images/games/reaction.png',
      builder: (GameContext context) => ReactionGame(gameContext: context),
    ),
  );
}
