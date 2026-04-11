// lib/games/games/speed_quiz/speed_quiz_registration.dart

import 'package:flutter/material.dart';
import '../../core/game_context.dart';
import '../../core/game_definition.dart';
import '../../core/game_enums.dart';
import '../../core/game_registry.dart';
import 'speed_quiz_game.dart';

void registerSpeedQuiz() {
  GameRegistry.instance.register(
    GameDefinition(
      id: 'speed_quiz',
      name: 'Speed Quiz',
      nameSwahili: 'Maswali Haraka',
      description:
          'Answer as many general knowledge questions as possible in 60 seconds!',
      descriptionSwahili:
          'Jibu maswali mengi ya ujuzi uwezavyo ndani ya sekunde 60!',
      category: GameCategory.trivia,
      icon: Icons.speed_rounded,
      minPlayers: 1,
      maxPlayers: 2,
      estimatedMinutes: 1,
      modes: [GameMode.practice, GameMode.friend, GameMode.ranked],
      stakeSafe: true,
      maxStakeTier: StakeTier.diamond,
      imagePath: 'assets/images/games/speed_quiz.png',
      builder: (GameContext context) => SpeedQuizGame(gameContext: context),
    ),
  );
}
