// lib/games/models/match_result.dart

class MatchResult {
  final int? winnerId;
  final Map<String, int> scores;
  final List<Map<String, dynamic>> payouts;
  final bool isDraw;

  MatchResult({
    this.winnerId,
    required this.scores,
    this.payouts = const [],
    this.isDraw = false,
  });

  factory MatchResult.fromJson(Map<String, dynamic> json) {
    final scoresRaw = json['scores'];
    final Map<String, int> parsedScores = {};
    if (scoresRaw is Map) {
      for (final entry in scoresRaw.entries) {
        parsedScores[entry.key.toString()] = _parseInt(entry.value);
      }
    }

    final payoutsRaw = json['payouts'];
    final List<Map<String, dynamic>> parsedPayouts = [];
    if (payoutsRaw is List) {
      for (final p in payoutsRaw) {
        if (p is Map<String, dynamic>) {
          parsedPayouts.add(p);
        }
      }
    }

    return MatchResult(
      winnerId: json['winner_id'] != null ? _parseInt(json['winner_id']) : null,
      scores: parsedScores,
      payouts: parsedPayouts,
      isDraw: _parseBool(json['is_draw']),
    );
  }
}

int _parseInt(dynamic v) {
  if (v is int) return v;
  if (v is double) return v.toInt();
  if (v is String) return int.tryParse(v) ?? 0;
  return 0;
}

bool _parseBool(dynamic v) {
  if (v is bool) return v;
  if (v is int) return v != 0;
  if (v is String) return v == '1' || v.toLowerCase() == 'true';
  return false;
}
