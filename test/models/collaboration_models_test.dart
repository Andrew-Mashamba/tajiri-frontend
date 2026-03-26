import 'package:flutter_test/flutter_test.dart';
import 'package:tajiri/models/collaboration_models.dart';

void main() {
  group('CollaborationSuggestion', () {
    test('fromJson parses full suggestion', () {
      final cs = CollaborationSuggestion.fromJson({
        'id': 1, 'creator_a_id': 10, 'creator_b_id': 20,
        'shared_category': 'music', 'affinity_score': 0.85,
        'status': 'suggested', 'partner_name': 'TestPartner',
        'partner_tier': 'star', 'partner_follower_count': 5000,
      });
      expect(cs.id, 1);
      expect(cs.sharedCategory, 'music');
      expect(cs.affinityScore, 0.85);
      expect(cs.partnerName, 'TestPartner');
    });

    test('fromJson handles minimal data', () {
      final cs = CollaborationSuggestion.fromJson({});
      expect(cs.id, 0);
      expect(cs.status, 'suggested');
      expect(cs.sharedCategory, '');
    });
  });
}
