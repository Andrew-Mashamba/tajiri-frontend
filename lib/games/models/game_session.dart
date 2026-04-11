// lib/games/models/game_session.dart
import '../core/game_enums.dart';

class GameSession {
  final int id;
  final String gameId;
  final GameMode mode;
  final SessionStatus status;
  final StakeTier stakeTier;
  final double stakeAmount;
  final String currency;
  final double platformFee;
  final int player1Id;
  final int? player2Id;
  final int player1Score;
  final int player2Score;
  final int? winnerId;
  final String gameSeed;
  final Map<String, dynamic>? gameState;
  final String? roomCode;
  final DateTime? startedAt;
  final DateTime? endedAt;
  final DateTime createdAt;

  GameSession({
    required this.id,
    required this.gameId,
    required this.mode,
    required this.status,
    required this.stakeTier,
    required this.stakeAmount,
    this.currency = 'TZS',
    this.platformFee = 0,
    required this.player1Id,
    this.player2Id,
    this.player1Score = 0,
    this.player2Score = 0,
    this.winnerId,
    required this.gameSeed,
    this.gameState,
    this.roomCode,
    this.startedAt,
    this.endedAt,
    required this.createdAt,
  });

  bool get isActive =>
      status == SessionStatus.active || status == SessionStatus.matching;

  bool get isCompleted => status == SessionStatus.completed;

  bool get isPending => status == SessionStatus.pending;

  bool isMyWin(int userId) => winnerId == userId;

  bool isDraw() => isCompleted && winnerId == null;

  int myScore(int userId) {
    if (userId == player1Id) return player1Score;
    if (userId == player2Id) return player2Score;
    return 0;
  }

  int opponentScore(int userId) {
    if (userId == player1Id) return player2Score;
    if (userId == player2Id) return player1Score;
    return 0;
  }

  int? opponentId(int userId) {
    if (userId == player1Id) return player2Id;
    if (userId == player2Id) return player1Id;
    return null;
  }

  factory GameSession.fromJson(Map<String, dynamic> json) {
    return GameSession(
      id: _parseInt(json['id']),
      gameId: json['game_id']?.toString() ?? '',
      mode: GameMode.fromString(json['mode']?.toString()),
      status: SessionStatus.fromString(json['status']?.toString()),
      stakeTier: StakeTier.fromString(json['stake_tier']?.toString()),
      stakeAmount: _parseDouble(json['stake_amount']),
      currency: json['currency']?.toString() ?? 'TZS',
      platformFee: _parseDouble(json['platform_fee']),
      player1Id: _parseInt(json['player_1_id'] ?? json['player1_id'] ?? json['user_id']),
      player2Id: json['player_2_id'] != null
          ? _parseInt(json['player_2_id'])
          : json['player2_id'] != null
              ? _parseInt(json['player2_id'])
              : json['opponent_id'] != null
                  ? _parseInt(json['opponent_id'])
                  : null,
      player1Score: _parseInt(json['player_1_score'] ?? json['player1_score']),
      player2Score: _parseInt(json['player_2_score'] ?? json['player2_score']),
      winnerId: json['winner_id'] != null ? _parseInt(json['winner_id']) : null,
      gameSeed: json['game_seed']?.toString() ?? '',
      gameState: json['game_state'] is Map<String, dynamic>
          ? json['game_state'] as Map<String, dynamic>
          : null,
      roomCode: json['room_code']?.toString(),
      startedAt: DateTime.tryParse(json['started_at']?.toString() ?? ''),
      endedAt: DateTime.tryParse(json['ended_at']?.toString() ?? ''),
      createdAt: DateTime.tryParse(json['created_at']?.toString() ?? '') ?? DateTime.now(),
    );
  }
}

// ─── Parse helpers ───────────────────────────────────────────

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
