// lib/games/games/word_guess/word_guess_registration.dart

import 'package:flutter/material.dart';
import '../../core/game_context.dart';
import '../../core/game_definition.dart';
import '../../core/game_enums.dart';
import '../../core/game_registry.dart';
import 'word_guess_game.dart';

void registerWordGuess() {
  GameRegistry.instance.register(
    GameDefinition(
      id: 'word_guess',
      name: 'Word Guess',
      nameSwahili: 'Nadhani Neno',
      description: 'Guess the 5-letter word in 6 tries!',
      descriptionSwahili: 'Nadhani neno la herufi 5 kwa majaribio 6!',
      category: GameCategory.word,
      icon: Icons.spellcheck_rounded,
      minPlayers: 1,
      maxPlayers: 2,
      estimatedMinutes: 3,
      modes: [GameMode.practice, GameMode.friend, GameMode.ranked],
      stakeSafe: true,
      maxStakeTier: StakeTier.diamond,
      imagePath: 'assets/images/games/word_guess.png',
      builder: (GameContext context) =>
          WordGuessGame(gameContext: context),
    ),
  );
}
