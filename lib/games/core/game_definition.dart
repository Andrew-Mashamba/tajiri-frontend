// lib/games/core/game_definition.dart
import 'package:flutter/material.dart';
import 'game_enums.dart';
import 'game_context.dart';

/// Describes a game that can be registered with the platform.
/// Each game plugin provides one of these to [GameRegistry.register].
class GameDefinition {
  /// Unique identifier for the game (e.g. 'tic_tac_toe', 'trivia_tz').
  final String id;

  /// Display name in English.
  final String name;

  /// Display name in Swahili.
  final String nameSwahili;

  /// Short description in English.
  final String description;

  /// Short description in Swahili.
  final String descriptionSwahili;

  /// Category this game belongs to.
  final GameCategory category;

  /// Icon to display in the game card.
  final IconData icon;

  /// Minimum number of players required.
  final int minPlayers;

  /// Maximum number of players supported.
  final int maxPlayers;

  /// Estimated play time in minutes.
  final int estimatedMinutes;

  /// Supported game modes.
  final List<GameMode> modes;

  /// Whether this game is safe for real-money stakes.
  /// Games with significant RNG or exploitable mechanics should be false.
  final bool stakeSafe;

  /// Maximum allowed stake tier for this game.
  final StakeTier maxStakeTier;

  /// Optional asset image path for the game card (e.g. 'assets/images/games/chess.png').
  final String? imagePath;

  /// Builder function that creates the game widget.
  /// Receives a [GameContext] with session info, socket service, etc.
  final Widget Function(GameContext context) builder;

  const GameDefinition({
    required this.id,
    required this.name,
    required this.nameSwahili,
    required this.description,
    required this.descriptionSwahili,
    required this.category,
    required this.icon,
    required this.minPlayers,
    required this.maxPlayers,
    required this.estimatedMinutes,
    required this.modes,
    required this.stakeSafe,
    required this.maxStakeTier,
    this.imagePath,
    required this.builder,
  });

  /// Player count display string (e.g. "1-2 players").
  String get playerCountLabel {
    if (minPlayers == maxPlayers) return '$minPlayers player${minPlayers == 1 ? '' : 's'}';
    return '$minPlayers-$maxPlayers players';
  }
}
