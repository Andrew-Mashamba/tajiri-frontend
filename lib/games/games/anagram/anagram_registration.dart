// lib/games/games/anagram/anagram_registration.dart

import 'package:flutter/material.dart';
import '../../core/game_context.dart';
import '../../core/game_definition.dart';
import '../../core/game_enums.dart';
import '../../core/game_registry.dart';
import 'anagram_game.dart';

void registerAnagram() {
  GameRegistry.instance.register(
    GameDefinition(
      id: 'anagram',
      name: 'Anagram Battle',
      nameSwahili: 'Vita vya Herufi',
      description: 'Form as many words as you can from 7 letters!',
      descriptionSwahili: 'Tengeneza maneno mengi kutoka herufi 7!',
      category: GameCategory.word,
      icon: Icons.abc_rounded,
      minPlayers: 1,
      maxPlayers: 2,
      estimatedMinutes: 2,
      modes: [GameMode.practice, GameMode.friend, GameMode.ranked],
      stakeSafe: true,
      maxStakeTier: StakeTier.diamond,
      imagePath: 'assets/images/games/anagram.png',
      builder: (GameContext context) =>
          AnagramGame(gameContext: context),
    ),
  );
}
