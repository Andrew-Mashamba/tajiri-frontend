import 'package:flutter_test/flutter_test.dart';
import 'package:tajiri/models/sponsored_post_models.dart';

void main() {
  group('SponsoredPostStatus', () {
    test('fromString parses valid statuses', () {
      expect(SponsoredPostStatus.fromString('active'), SponsoredPostStatus.active);
      expect(SponsoredPostStatus.fromString('completed'), SponsoredPostStatus.completed);
      expect(SponsoredPostStatus.fromString(null), SponsoredPostStatus.draft);
    });
  });

  group('SponsoredPost', () {
    test('fromJson parses full sponsored post', () {
      final sp = SponsoredPost.fromJson({
        'id': 1, 'post_id': 42, 'sponsor_user_id': 10, 'creator_user_id': 20,
        'budget': 50000.0, 'currency': 'TSh', 'status': 'active',
        'tier_required': 'star', 'impressions_target': 10000, 'impressions_delivered': 5000,
        'sponsor_name': 'Biz', 'creator_name': 'Creator', 'created_at': '2026-03-26T00:00:00Z',
      });
      expect(sp.id, 1);
      expect(sp.budget, 50000.0);
      expect(sp.status, SponsoredPostStatus.active);
      expect(sp.deliveryPercent, 50.0);
    });

    test('fromJson handles minimal data', () {
      final sp = SponsoredPost.fromJson({});
      expect(sp.id, 0);
      expect(sp.status, SponsoredPostStatus.draft);
      expect(sp.currency, 'TSh');
    });
  });

  group('SponsorableCreator', () {
    test('fromJson parses creator', () {
      final c = SponsorableCreator.fromJson({
        'user_id': 5, 'name': 'TestCreator', 'tier': 'legend',
        'follower_count': 50000, 'avg_engagement_rate': 8.5, 'top_category': 'music',
      });
      expect(c.name, 'TestCreator');
      expect(c.tier, 'legend');
      expect(c.avgEngagementRate, 8.5);
    });
  });
}
