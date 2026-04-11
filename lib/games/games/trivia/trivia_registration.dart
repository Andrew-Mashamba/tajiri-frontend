// lib/games/games/trivia/trivia_registration.dart

import 'package:flutter/material.dart';
import '../../core/game_context.dart';
import '../../core/game_definition.dart';
import '../../core/game_enums.dart';
import '../../core/game_registry.dart';
import 'trivia_game.dart';

void registerTrivia() {
  GameRegistry.instance.register(
    GameDefinition(
      id: 'trivia',
      name: 'Trivia Showdown',
      nameSwahili: 'Mashindano ya Maswali',
      description: 'Answer 10 questions as fast as you can!',
      descriptionSwahili: 'Jibu maswali 10 haraka uwezavyo!',
      category: GameCategory.trivia,
      icon: Icons.quiz_rounded,
      minPlayers: 1,
      maxPlayers: 2,
      estimatedMinutes: 2,
      modes: [GameMode.practice, GameMode.friend, GameMode.ranked],
      stakeSafe: true,
      maxStakeTier: StakeTier.diamond,
      imagePath: 'assets/images/games/trivia.png',
      builder: (GameContext context) => TriviaGame(gameContext: context),
    ),
  );
}
