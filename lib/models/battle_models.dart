// Models for creator battles (split-thread debates).

int _parseInt(dynamic value) {
  if (value == null) return 0;
  if (value is int) return value;
  if (value is String) return int.tryParse(value) ?? 0;
  return 0;
}

/// Status of a creator battle.
enum BattleStatus {
  open, voting, closed;

  factory BattleStatus.fromString(String? s) {
    switch (s?.toLowerCase()) {
      case 'voting': return BattleStatus.voting;
      case 'closed': return BattleStatus.closed;
      default: return BattleStatus.open;
    }
  }
}

/// A creator battle: two creators, opposing takes, audience votes.
class CreatorBattle {
  final int id;
  final int? threadId;
  final int creatorAId;
  final int creatorBId;
  final String topic;
  final int votesA;
  final int votesB;
  final BattleStatus status;
  final DateTime? startsAt;
  final DateTime? endsAt;
  final String? creatorAName;
  final String? creatorBName;
  final String? creatorAAvatarUrl;
  final String? creatorBAvatarUrl;
  final String? userVote; // null, 'a', or 'b'

  CreatorBattle({
    required this.id,
    this.threadId,
    required this.creatorAId,
    required this.creatorBId,
    required this.topic,
    required this.votesA,
    required this.votesB,
    required this.status,
    this.startsAt,
    this.endsAt,
    this.creatorAName,
    this.creatorBName,
    this.creatorAAvatarUrl,
    this.creatorBAvatarUrl,
    this.userVote,
  });

  factory CreatorBattle.fromJson(Map<String, dynamic> json) {
    return CreatorBattle(
      id: _parseInt(json['id']),
      threadId: json['thread_id'] != null ? _parseInt(json['thread_id']) : null,
      creatorAId: _parseInt(json['creator_a_id']),
      creatorBId: _parseInt(json['creator_b_id']),
      topic: (json['topic'] as String?) ?? '',
      votesA: _parseInt(json['votes_a']),
      votesB: _parseInt(json['votes_b']),
      status: BattleStatus.fromString(json['status'] as String?),
      startsAt: json['started_at'] != null ? DateTime.tryParse(json['started_at'].toString()) : null,
      endsAt: json['ends_at'] != null ? DateTime.tryParse(json['ends_at'].toString()) : null,
      creatorAName: json['creator_a_name'] as String?,
      creatorBName: json['creator_b_name'] as String?,
      creatorAAvatarUrl: json['creator_a_avatar_url'] as String?,
      creatorBAvatarUrl: json['creator_b_avatar_url'] as String?,
      userVote: json['user_vote'] as String?,
    );
  }

  int get totalVotes => votesA + votesB;
  double get percentA => totalVotes > 0 ? votesA / totalVotes * 100 : 50;
  double get percentB => totalVotes > 0 ? votesB / totalVotes * 100 : 50;
}
