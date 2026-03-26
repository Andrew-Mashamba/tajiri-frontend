import 'package:flutter_test/flutter_test.dart';
import 'package:tajiri/models/battle_models.dart';

void main() {
  group('BattleStatus', () {
    test('fromString parses valid statuses', () {
      expect(BattleStatus.fromString('voting'), BattleStatus.voting);
      expect(BattleStatus.fromString('closed'), BattleStatus.closed);
      expect(BattleStatus.fromString(null), BattleStatus.open);
    });
  });

  group('CreatorBattle', () {
    test('fromJson parses full battle', () {
      final b = CreatorBattle.fromJson({
        'id': 1, 'thread_id': 5, 'creator_a_id': 10, 'creator_b_id': 20,
        'topic': 'Best genre?', 'votes_a': 60, 'votes_b': 40,
        'status': 'open', 'creator_a_name': 'Alice', 'creator_b_name': 'Bob',
      });
      expect(b.id, 1);
      expect(b.topic, 'Best genre?');
      expect(b.totalVotes, 100);
      expect(b.percentA, 60.0);
      expect(b.percentB, 40.0);
    });

    test('fromJson handles empty data', () {
      final b = CreatorBattle.fromJson({});
      expect(b.id, 0);
      expect(b.status, BattleStatus.open);
      expect(b.percentA, 50);
      expect(b.percentB, 50);
    });
  });
}
