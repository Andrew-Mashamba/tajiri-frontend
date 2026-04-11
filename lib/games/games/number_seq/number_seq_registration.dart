// lib/games/games/number_seq/number_seq_registration.dart

import 'package:flutter/material.dart';
import '../../core/game_context.dart';
import '../../core/game_definition.dart';
import '../../core/game_enums.dart';
import '../../core/game_registry.dart';
import 'number_seq_game.dart';

void registerNumberSeq() {
  GameRegistry.instance.register(
    GameDefinition(
      id: 'number_seq',
      name: 'Number Sequence',
      nameSwahili: 'Mfuatano wa Nambari',
      description:
          'Find the next number in the sequence! 60 seconds, as many as you can.',
      descriptionSwahili:
          'Tafuta nambari inayofuata! Sekunde 60, kadri uwezavyo.',
      category: GameCategory.math,
      icon: Icons.trending_up_rounded,
      minPlayers: 1,
      maxPlayers: 2,
      estimatedMinutes: 1,
      modes: [GameMode.practice, GameMode.friend, GameMode.ranked],
      stakeSafe: true,
      maxStakeTier: StakeTier.diamond,
      imagePath: 'assets/images/games/number_seq.png',
      builder: (GameContext context) => NumberSeqGame(gameContext: context),
    ),
  );
}
