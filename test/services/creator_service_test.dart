import 'package:flutter_test/flutter_test.dart';
import 'package:tajiri/models/flywheel_models.dart';
import 'package:tajiri/services/creator_service.dart';

void main() {
  group('CreatorService', () {
    test('instance can be created', () {
      final service = CreatorService();
      expect(service, isNotNull);
    });
  });

  group('CreatorScore tier logic', () {
    test('rising tier has 1.0x multiplier', () {
      final score = CreatorScore.fromJson({
        'score': 20.0,
        'tier': 'rising',
        'tier_multiplier': 1.0,
      });
      expect(score.tier, 'rising');
      expect(score.tierMultiplier, 1.0);
    });

    test('star tier has 2.0x multiplier', () {
      final score = CreatorScore.fromJson({
        'score': 72.5,
        'tier': 'star',
        'tier_multiplier': 2.0,
      });
      expect(score.tier, 'star');
      expect(score.tierMultiplier, 2.0);
    });
  });
}
