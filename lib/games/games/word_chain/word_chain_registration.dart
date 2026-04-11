// lib/games/games/word_chain/word_chain_registration.dart

import 'package:flutter/material.dart';
import '../../core/game_context.dart';
import '../../core/game_definition.dart';
import '../../core/game_enums.dart';
import '../../core/game_registry.dart';
import 'word_chain_game.dart';

void registerWordChain() {
  GameRegistry.instance.register(
    GameDefinition(
      id: 'word_chain',
      name: 'Word Chain',
      nameSwahili: 'Msururu wa Maneno',
      description:
          'Say a word starting with the last letter of the previous word!',
      descriptionSwahili:
          'Sema neno linaloanza na herufi ya mwisho ya neno lililotangulia!',
      category: GameCategory.word,
      icon: Icons.link_rounded,
      minPlayers: 1,
      maxPlayers: 2,
      estimatedMinutes: 3,
      modes: [GameMode.practice, GameMode.friend, GameMode.ranked],
      stakeSafe: true,
      maxStakeTier: StakeTier.diamond,
      imagePath: 'assets/images/games/word_chain.png',
      builder: (GameContext context) => WordChainGame(gameContext: context),
    ),
  );
}
