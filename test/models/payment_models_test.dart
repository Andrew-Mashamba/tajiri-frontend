import 'package:flutter_test/flutter_test.dart';
import 'package:tajiri/models/payment_models.dart';

void main() {
  group('CreatorFundPool', () {
    test('fromJson parses full pool', () {
      final pool = CreatorFundPool.fromJson({
        'id': 7,
        'total_amount': 500000.0,
        'currency': 'KES',
        'month': '2026-03',
        'is_distributed': true,
        'distributed_at': '2026-03-31T23:59:00.000Z',
      });
      expect(pool.id, 7);
      expect(pool.totalAmount, 500000.0);
      expect(pool.currency, 'KES');
      expect(pool.month, '2026-03');
      expect(pool.isDistributed, isTrue);
      expect(pool.distributedAt, isNotNull);
      expect(pool.distributedAt!.year, 2026);
      expect(pool.distributedAt!.month, 3);
    });

    test('fromJson handles minimal data with defaults', () {
      final pool = CreatorFundPool.fromJson({'id': 1});
      expect(pool.id, 1);
      expect(pool.totalAmount, 0.0);
      expect(pool.currency, 'KES');
      expect(pool.month, '');
      expect(pool.isDistributed, isFalse);
      expect(pool.distributedAt, isNull);
    });

    test('fromJson parses string numeric total_amount', () {
      final pool = CreatorFundPool.fromJson({
        'id': 2,
        'total_amount': '250000.50',
        'currency': 'TZS',
        'month': '2026-02',
        'is_distributed': 0,
      });
      expect(pool.totalAmount, 250000.50);
      expect(pool.currency, 'TZS');
      expect(pool.isDistributed, isFalse);
    });

    test('fromJson parses int 1 as is_distributed true', () {
      final pool = CreatorFundPool.fromJson({
        'id': 3,
        'is_distributed': 1,
      });
      expect(pool.isDistributed, isTrue);
    });
  });

  group('CreatorFundPayout', () {
    test('fromJson parses full payout', () {
      final payout = CreatorFundPayout.fromJson({
        'id': 55,
        'user_id': 101,
        'base_score': 780.5,
        'tier_multiplier': 1.5,
        'streak_multiplier': 1.2,
        'community_multiplier': 1.1,
        'virality_multiplier': 1.3,
        'effective_multiplier': 2.574,
        'final_score': 2008.47,
        'payout_amount': 3500.0,
        'payout_currency': 'KES',
        'status': 'paid',
        'paid_at': '2026-04-01T08:00:00.000Z',
      });
      expect(payout.id, 55);
      expect(payout.userId, 101);
      expect(payout.baseScore, 780.5);
      expect(payout.tierMultiplier, 1.5);
      expect(payout.streakMultiplier, 1.2);
      expect(payout.communityMultiplier, 1.1);
      expect(payout.viralityMultiplier, 1.3);
      expect(payout.effectiveMultiplier, 2.574);
      expect(payout.finalScore, 2008.47);
      expect(payout.payoutAmount, 3500.0);
      expect(payout.payoutCurrency, 'KES');
      expect(payout.status, 'paid');
      expect(payout.paidAt, isNotNull);
      expect(payout.paidAt!.year, 2026);
    });

    test('fromJson handles minimal data with defaults', () {
      final payout = CreatorFundPayout.fromJson({'id': 1, 'user_id': 10});
      expect(payout.id, 1);
      expect(payout.userId, 10);
      expect(payout.baseScore, 0.0);
      expect(payout.tierMultiplier, 1.0);
      expect(payout.streakMultiplier, 1.0);
      expect(payout.communityMultiplier, 1.0);
      expect(payout.viralityMultiplier, 1.0);
      expect(payout.effectiveMultiplier, 1.0);
      expect(payout.finalScore, 0.0);
      expect(payout.payoutAmount, 0.0);
      expect(payout.payoutCurrency, 'KES');
      expect(payout.status, 'pending');
      expect(payout.paidAt, isNull);
    });

    test('fromJson parses string numeric fields', () {
      final payout = CreatorFundPayout.fromJson({
        'id': 2,
        'user_id': '20',
        'base_score': '400.0',
        'payout_amount': '1200.75',
        'payout_currency': 'TZS',
        'status': 'processing',
      });
      expect(payout.userId, 20);
      expect(payout.baseScore, 400.0);
      expect(payout.payoutAmount, 1200.75);
      expect(payout.payoutCurrency, 'TZS');
      expect(payout.status, 'processing');
    });
  });

  group('WeeklyReport', () {
    test('fromJson parses full report', () {
      final report = WeeklyReport.fromJson({
        'total_earnings': 1200.0,
        'earnings_change_percent': 15.5,
        'best_post_id': 999,
        'best_post_likes': 342,
        'engagement_trend': 'rising',
        'follower_change': 47,
        'threads_triggered': 3,
        'total_views': 12500,
        'total_likes': 880,
        'week_start': '2026-03-20',
        'week_end': '2026-03-26',
      });
      expect(report.totalEarnings, 1200.0);
      expect(report.earningsChangePercent, 15.5);
      expect(report.bestPostId, 999);
      expect(report.bestPostLikes, 342);
      expect(report.engagementTrend, 'rising');
      expect(report.followerChange, 47);
      expect(report.threadsTriggered, 3);
      expect(report.totalViews, 12500);
      expect(report.totalLikes, 880);
      expect(report.weekStart, '2026-03-20');
      expect(report.weekEnd, '2026-03-26');
    });

    test('fromJson handles minimal data with defaults', () {
      final report = WeeklyReport.fromJson({});
      expect(report.totalEarnings, 0.0);
      expect(report.earningsChangePercent, 0.0);
      expect(report.bestPostId, isNull);
      expect(report.bestPostLikes, 0);
      expect(report.engagementTrend, 'stable');
      expect(report.followerChange, 0);
      expect(report.threadsTriggered, 0);
      expect(report.totalViews, 0);
      expect(report.totalLikes, 0);
      expect(report.weekStart, '');
      expect(report.weekEnd, '');
    });

    test('fromJson parses negative follower_change', () {
      final report = WeeklyReport.fromJson({
        'follower_change': -12,
        'earnings_change_percent': -8.3,
        'engagement_trend': 'falling',
      });
      expect(report.followerChange, -12);
      expect(report.earningsChangePercent, closeTo(-8.3, 0.001));
      expect(report.engagementTrend, 'falling');
    });

    test('fromJson treats null best_post_id as null', () {
      final report = WeeklyReport.fromJson({
        'best_post_id': null,
        'total_views': 500,
      });
      expect(report.bestPostId, isNull);
      expect(report.totalViews, 500);
    });
  });
}
