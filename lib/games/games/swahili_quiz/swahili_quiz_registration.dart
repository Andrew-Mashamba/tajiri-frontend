// lib/games/games/swahili_quiz/swahili_quiz_registration.dart

import 'package:flutter/material.dart';
import '../../core/game_context.dart';
import '../../core/game_definition.dart';
import '../../core/game_enums.dart';
import '../../core/game_registry.dart';
import 'swahili_quiz_game.dart';

void registerSwahiliQuiz() {
  GameRegistry.instance.register(
    GameDefinition(
      id: 'swahili_quiz',
      name: 'Swahili Quiz',
      nameSwahili: 'Jaribio la Kiswahili',
      description: 'Test your Swahili vocabulary and proverbs!',
      descriptionSwahili: 'Jaribu msamiati wako wa Kiswahili na methali!',
      category: GameCategory.trivia,
      icon: Icons.translate_rounded,
      minPlayers: 1,
      maxPlayers: 2,
      estimatedMinutes: 2,
      modes: [GameMode.practice, GameMode.friend, GameMode.ranked],
      stakeSafe: true,
      maxStakeTier: StakeTier.diamond,
      imagePath: 'assets/images/games/swahili_quiz.png',
      builder: (GameContext context) =>
          SwahiliQuizGame(gameContext: context),
    ),
  );
}
