import 'package:flutter_test/flutter_test.dart';
import 'package:tajiri/creator/models/creator_earnings_models.dart';

void main() {
  group('CreatorEarningsDashboard.fromJson', () {
    test('parses minimal payload', () {
      final d = CreatorEarningsDashboard.fromJson(<String, dynamic>{
        'user_id': 42,
        'total_cleared_tsh': 12345.67,
        'total_pending_tsh': 8901.23,
        'currency': 'TSh',
        'tier': 'mwanzo',
        'is_mwanzo_active': true,
        'monetization_paused': false,
        'breakdown_by_stream': <String, dynamic>{},
      });
      expect(d.userId, 42);
      expect(d.totalClearedTsh, 12345.67);
      expect(d.totalPendingTsh, 8901.23);
      expect(d.tier, 'mwanzo');
      expect(d.isMwanzoActive, true);
      expect(d.monetizationPaused, false);
    });

    test('parses stream breakdown', () {
      final d = CreatorEarningsDashboard.fromJson({
        'user_id': 1,
        'total_cleared_tsh': 0.0,
        'total_pending_tsh': 0.0,
        'currency': 'TSh',
        'tier': 'standard',
        'is_mwanzo_active': false,
        'monetization_paused': false,
        'breakdown_by_stream': {
          'engagement': {'cleared_tsh': 100.0, 'pending_tsh': 50.0, 'event_count': 10},
          'fan_funding': {'cleared_tsh': 200.0, 'pending_tsh': 0.0, 'event_count': 1},
        },
      });
      expect(d.breakdownByStream['engagement']!.clearedTsh, 100.0);
      expect(d.breakdownByStream['engagement']!.eventCount, 10);
      expect(d.breakdownByStream['fan_funding']!.clearedTsh, 200.0);
    });
  });

  group('EarningEventItem.multiplierSummary', () {
    test('returns "no multipliers" when all are 1.0', () {
      final e = EarningEventItem(
        eventId: 1,
        occurredAt: '',
        stream: 'engagement',
        metric: 'view',
        actorRole: 'author',
        rawCount: 1,
        rateTsh: 0.5,
        multipliers: const {'watch_completion': 1.0, 'mwanzo_boost': 1.0},
        grossCredit: 0.5,
        platformTake: 0,
        traWhtHeld: 0,
        netToCreator: 0.5,
        isChargeable: true,
        settlementStatus: 'pending',
      );
      expect(e.multiplierSummary(), 'no multipliers');
    });

    test('formats non-trivial multipliers', () {
      final e = EarningEventItem(
        eventId: 1,
        occurredAt: '',
        stream: 'engagement',
        metric: 'view',
        actorRole: 'author',
        rawCount: 1,
        rateTsh: 0.5,
        multipliers: const {'watch_completion': 2.0, 'mwanzo_boost': 2.0, 'streak': 1.10},
        grossCredit: 2.2,
        platformTake: 0,
        traWhtHeld: 0,
        netToCreator: 2.2,
        isChargeable: true,
        settlementStatus: 'pending',
      );
      expect(e.multiplierSummary(), contains('watch'));
      expect(e.multiplierSummary(), contains('Mwanzo'));
      expect(e.multiplierSummary(), contains('streak'));
    });
  });
}
