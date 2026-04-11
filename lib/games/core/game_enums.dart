// lib/games/core/game_enums.dart
import 'package:flutter/material.dart';

// ─── Game Category ───────────────────────────────────────────

enum GameCategory {
  all,
  puzzle,
  trivia,
  word,
  card,
  board,
  arcade,
  math,
  strategy;

  String get displayName {
    switch (this) {
      case GameCategory.all:
        return 'All';
      case GameCategory.puzzle:
        return 'Puzzles';
      case GameCategory.trivia:
        return 'Trivia';
      case GameCategory.word:
        return 'Word';
      case GameCategory.card:
        return 'Card';
      case GameCategory.board:
        return 'Board';
      case GameCategory.arcade:
        return 'Arcade';
      case GameCategory.math:
        return 'Math';
      case GameCategory.strategy:
        return 'Strategy';
    }
  }

  String get displayNameSwahili {
    switch (this) {
      case GameCategory.all:
        return 'Zote';
      case GameCategory.puzzle:
        return 'Mafumbo';
      case GameCategory.trivia:
        return 'Maswali';
      case GameCategory.word:
        return 'Maneno';
      case GameCategory.card:
        return 'Kadi';
      case GameCategory.board:
        return 'Bodi';
      case GameCategory.arcade:
        return 'Arcade';
      case GameCategory.math:
        return 'Hesabu';
      case GameCategory.strategy:
        return 'Mkakati';
    }
  }

  IconData get icon {
    switch (this) {
      case GameCategory.all:
        return Icons.grid_view_rounded;
      case GameCategory.puzzle:
        return Icons.extension_rounded;
      case GameCategory.trivia:
        return Icons.quiz_rounded;
      case GameCategory.word:
        return Icons.abc_rounded;
      case GameCategory.card:
        return Icons.style_rounded;
      case GameCategory.board:
        return Icons.grid_on_rounded;
      case GameCategory.arcade:
        return Icons.sports_esports_rounded;
      case GameCategory.math:
        return Icons.calculate_rounded;
      case GameCategory.strategy:
        return Icons.psychology_rounded;
    }
  }

  static GameCategory fromString(String? s) {
    return GameCategory.values.firstWhere(
      (v) => v.name == s,
      orElse: () => GameCategory.all,
    );
  }
}

// ─── Game Mode ───────────────────────────────────────────────

enum GameMode {
  practice,
  friend,
  ranked;

  String get displayName {
    switch (this) {
      case GameMode.practice:
        return 'Practice';
      case GameMode.friend:
        return 'Challenge Friend';
      case GameMode.ranked:
        return 'Ranked';
    }
  }

  String get displayNameSwahili {
    switch (this) {
      case GameMode.practice:
        return 'Mazoezi';
      case GameMode.friend:
        return 'Changamoto Rafiki';
      case GameMode.ranked:
        return 'Mashindano';
    }
  }

  IconData get icon {
    switch (this) {
      case GameMode.practice:
        return Icons.fitness_center_rounded;
      case GameMode.friend:
        return Icons.people_rounded;
      case GameMode.ranked:
        return Icons.emoji_events_rounded;
    }
  }

  static GameMode fromString(String? s) {
    return GameMode.values.firstWhere(
      (v) => v.name == s,
      orElse: () => GameMode.practice,
    );
  }
}

// ─── Stake Tier ──────────────────────────────────────────────

enum StakeTier {
  free,
  bronze,
  silver,
  gold,
  diamond,
  custom;

  String get displayName {
    switch (this) {
      case StakeTier.free:
        return 'Free';
      case StakeTier.bronze:
        return 'Bronze';
      case StakeTier.silver:
        return 'Silver';
      case StakeTier.gold:
        return 'Gold';
      case StakeTier.diamond:
        return 'Diamond';
      case StakeTier.custom:
        return 'Custom';
    }
  }

  double get amount {
    switch (this) {
      case StakeTier.free:
        return 0;
      case StakeTier.bronze:
        return 500;
      case StakeTier.silver:
        return 2000;
      case StakeTier.gold:
        return 5000;
      case StakeTier.diamond:
        return 20000;
      case StakeTier.custom:
        return 0;
    }
  }

  String get formattedAmount {
    if (this == StakeTier.free) return 'Free';
    if (this == StakeTier.custom) return 'Custom';
    final amt = amount.toInt();
    if (amt >= 1000) {
      return 'TZS ${(amt / 1000).toStringAsFixed(amt % 1000 == 0 ? 0 : 1)}K';
    }
    return 'TZS $amt';
  }

  static StakeTier fromString(String? s) {
    return StakeTier.values.firstWhere(
      (v) => v.name == s,
      orElse: () => StakeTier.free,
    );
  }
}

// ─── Session Status ──────────────────────────────────────────

enum SessionStatus {
  pending,
  matching,
  active,
  completed,
  cancelled,
  forfeited;

  String get displayName {
    switch (this) {
      case SessionStatus.pending:
        return 'Pending';
      case SessionStatus.matching:
        return 'Matching';
      case SessionStatus.active:
        return 'Active';
      case SessionStatus.completed:
        return 'Completed';
      case SessionStatus.cancelled:
        return 'Cancelled';
      case SessionStatus.forfeited:
        return 'Forfeited';
    }
  }

  Color get color {
    switch (this) {
      case SessionStatus.pending:
        return const Color(0xFFF59E0B);
      case SessionStatus.matching:
        return const Color(0xFF3B82F6);
      case SessionStatus.active:
        return const Color(0xFF10B981);
      case SessionStatus.completed:
        return const Color(0xFF6B7280);
      case SessionStatus.cancelled:
        return const Color(0xFFEF4444);
      case SessionStatus.forfeited:
        return const Color(0xFFEF4444);
    }
  }

  static SessionStatus fromString(String? s) {
    return SessionStatus.values.firstWhere(
      (v) => v.name == s,
      orElse: () => SessionStatus.pending,
    );
  }
}
