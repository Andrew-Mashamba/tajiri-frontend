import 'package:flutter_test/flutter_test.dart';
import 'package:tajiri/models/flywheel_models.dart';

void main() {
  group('UserEvent', () {
    test('toJson serializes all fields', () {
      final event = UserEvent(
        eventType: 'view',
        postId: 42,
        creatorId: 15,
        timestamp: DateTime.utc(2026, 3, 26, 19, 30),
        durationMs: 3200,
        sessionId: 'abc-123',
        metadata: {'source': 'feed'},
      );
      final json = event.toJson();
      expect(json['event_type'], 'view');
      expect(json['post_id'], 42);
      expect(json['creator_id'], 15);
      expect(json['timestamp'], '2026-03-26T19:30:00.000Z');
      expect(json['duration_ms'], 3200);
      expect(json['session_id'], 'abc-123');
      expect(json['metadata'], {'source': 'feed'});
    });

    test('toJson omits null optional fields', () {
      final event = UserEvent(
        eventType: 'scroll_past',
        timestamp: DateTime.utc(2026, 3, 26),
        sessionId: 'abc-123',
      );
      final json = event.toJson();
      expect(json['event_type'], 'scroll_past');
      expect(json.containsKey('post_id'), false);
      expect(json.containsKey('creator_id'), false);
      expect(json['duration_ms'], 0);
    });

    test('deduplication key uses 1-second granularity', () {
      final event = UserEvent(
        eventType: 'view',
        postId: 42,
        timestamp: DateTime.utc(2026, 3, 26, 19, 30, 15, 500),
        sessionId: 'abc',
      );
      final key = event.deduplicationKey(userId: 1);
      expect(key, '1_view_42_2026-03-26T19:30:15');
    });
  });

  group('CreatorStreak', () {
    test('fromJson parses correctly', () {
      final streak = CreatorStreak.fromJson({
        'user_id': 15,
        'current_streak_days': 23,
        'longest_streak_days': 45,
        'last_post_at': '2026-03-25T14:00:00.000Z',
        'banked_skip_days': 3,
        'is_frozen': false,
        'streak_multiplier': 1.25,
      });
      expect(streak.userId, 15);
      expect(streak.currentStreakDays, 23);
      expect(streak.longestStreakDays, 45);
      expect(streak.bankedSkipDays, 3);
      expect(streak.isFrozen, false);
      expect(streak.streakMultiplier, 1.25);
    });

    test('fromJson handles defaults', () {
      final streak = CreatorStreak.fromJson({});
      expect(streak.userId, 0);
      expect(streak.currentStreakDays, 0);
      expect(streak.streakMultiplier, 1.0);
      expect(streak.isFrozen, false);
    });
  });

  group('ViewerStreak', () {
    test('fromJson parses correctly', () {
      final streak = ViewerStreak.fromJson({
        'user_id': 42,
        'current_streak_days': 12,
        'longest_streak_days': 30,
        'last_active_date': '2026-03-26',
        'is_frozen': false,
      });
      expect(streak.userId, 42);
      expect(streak.currentStreakDays, 12);
      expect(streak.longestStreakDays, 30);
      expect(streak.isFrozen, false);
    });
  });

  group('CreatorScore', () {
    test('fromJson parses correctly', () {
      final score = CreatorScore.fromJson({
        'user_id': 15,
        'score': 72.5,
        'tier': 'star',
        'community_score': 85.0,
        'quality_score': 68.0,
        'consistency_score': 64.5,
        'tier_multiplier': 2.0,
        'computed_at': '2026-03-26T00:00:00.000Z',
      });
      expect(score.userId, 15);
      expect(score.score, 72.5);
      expect(score.tier, 'star');
      expect(score.tierMultiplier, 2.0);
      expect(score.communityScore, 85.0);
    });

    test('fromJson handles defaults', () {
      final score = CreatorScore.fromJson({});
      expect(score.score, 0.0);
      expect(score.tier, 'rising');
      expect(score.tierMultiplier, 1.0);
    });
  });

  group('FundPayoutProjection', () {
    test('fromJson parses correctly', () {
      final payout = FundPayoutProjection.fromJson({
        'user_id': 15,
        'current_month': '2026-03',
        'projected_score': 5625.0,
        'projected_payout': 500000.0,
        'tier': 'star',
        'multipliers': {
          'tier': 2.0,
          'streak': 1.25,
          'community': 1.5,
          'virality': 3.0,
          'effective': 11.25,
          'capped': false,
        },
      });
      expect(payout.userId, 15);
      expect(payout.currentMonth, '2026-03');
      expect(payout.projectedScore, 5625.0);
      expect(payout.tier, 'star');
      expect(payout.multipliers['effective'], 11.25);
    });

    test('fromJson handles defaults', () {
      final payout = FundPayoutProjection.fromJson({});
      expect(payout.projectedScore, 0.0);
      expect(payout.tier, 'rising');
      expect(payout.multipliers, isEmpty);
    });
  });
}
