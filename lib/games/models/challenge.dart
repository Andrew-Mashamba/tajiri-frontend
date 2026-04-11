// lib/games/models/challenge.dart
import '../core/game_enums.dart';

class Challenge {
  final int sessionId;
  final String gameId;
  final int challengerId;
  final String challengerName;
  final String? challengerAvatar;
  final StakeTier stakeTier;
  final double stakeAmount;
  final DateTime createdAt;

  Challenge({
    required this.sessionId,
    required this.gameId,
    required this.challengerId,
    required this.challengerName,
    this.challengerAvatar,
    required this.stakeTier,
    this.stakeAmount = 0,
    required this.createdAt,
  });

  bool get hasStake => stakeAmount > 0;

  String get stakeDisplay {
    if (stakeAmount <= 0) return 'Free';
    return 'TZS ${stakeAmount.toStringAsFixed(0)}';
  }

  factory Challenge.fromJson(Map<String, dynamic> json) {
    return Challenge(
      sessionId: _parseInt(json['session_id'] ?? json['id']),
      gameId: json['game_id']?.toString() ?? '',
      challengerId: _parseInt(json['challenger_id'] ?? json['player_1_id']),
      challengerName: json['challenger_name']?.toString() ??
          json['player_1_name']?.toString() ??
          '',
      challengerAvatar: json['challenger_avatar']?.toString() ??
          json['player_1_avatar']?.toString(),
      stakeTier: StakeTier.fromString(json['stake_tier']?.toString()),
      stakeAmount: _parseDouble(json['stake_amount']),
      createdAt: DateTime.tryParse(json['created_at']?.toString() ?? '') ??
          DateTime.now(),
    );
  }
}

int _parseInt(dynamic v) {
  if (v is int) return v;
  if (v is double) return v.toInt();
  if (v is String) return int.tryParse(v) ?? 0;
  return 0;
}

double _parseDouble(dynamic v) {
  if (v is double) return v;
  if (v is int) return v.toDouble();
  if (v is String) return double.tryParse(v) ?? 0.0;
  return 0.0;
}
