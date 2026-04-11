// lib/games/models/leaderboard_entry.dart

class LeaderboardEntry {
  final int rank;
  final int userId;
  final String userName;
  final String? avatar;
  final String? gameId;
  final int wins;
  final int losses;
  final int draws;
  final int totalScore;
  final int eloRating;

  LeaderboardEntry({
    required this.rank,
    required this.userId,
    required this.userName,
    this.avatar,
    this.gameId,
    this.wins = 0,
    this.losses = 0,
    this.draws = 0,
    this.totalScore = 0,
    this.eloRating = 1200,
  });

  int get totalGames => wins + losses + draws;

  double get winRate {
    if (totalGames == 0) return 0.0;
    return wins / totalGames;
  }

  String get winRateFormatted => '${(winRate * 100).toStringAsFixed(0)}%';

  String get record => '$wins-$losses${draws > 0 ? '-$draws' : ''}';

  factory LeaderboardEntry.fromJson(Map<String, dynamic> json) {
    return LeaderboardEntry(
      rank: _parseInt(json['rank']),
      userId: _parseInt(json['user_id']),
      userName: json['user_name']?.toString() ?? json['name']?.toString() ?? '',
      avatar: json['avatar']?.toString() ?? json['user_avatar']?.toString(),
      gameId: json['game_id']?.toString(),
      wins: _parseInt(json['wins']),
      losses: _parseInt(json['losses']),
      draws: _parseInt(json['draws']),
      totalScore: _parseInt(json['total_score'] ?? json['score']),
      eloRating: json['elo_rating'] != null
          ? _parseInt(json['elo_rating'])
          : json['rating'] != null
              ? _parseInt(json['rating'])
              : 1200,
    );
  }
}

int _parseInt(dynamic v) {
  if (v is int) return v;
  if (v is double) return v.toInt();
  if (v is String) return int.tryParse(v) ?? 0;
  return 0;
}
