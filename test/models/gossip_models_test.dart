import 'package:flutter_test/flutter_test.dart';
import 'package:tajiri/models/gossip_models.dart';

void main() {
  group('ThreadStatus', () {
    test('fromString parses valid statuses', () {
      expect(ThreadStatus.fromString('active'), ThreadStatus.active);
      expect(ThreadStatus.fromString('cooling'), ThreadStatus.cooling);
      expect(ThreadStatus.fromString('archived'), ThreadStatus.archived);
    });

    test('fromString defaults to active for unknown', () {
      expect(ThreadStatus.fromString('unknown'), ThreadStatus.active);
      expect(ThreadStatus.fromString(null), ThreadStatus.active);
    });
  });

  group('GossipThread', () {
    test('fromJson parses full thread', () {
      final thread = GossipThread.fromJson({
        'id': 42,
        'seed_post_id': 100,
        'title_en': 'Bongo Flava Is On Fire',
        'title_sw': 'Bongo Flava Imewaka',
        'category': 'entertainment',
        'velocity_score': 85.5,
        'post_count': 23,
        'participant_count': 18,
        'status': 'active',
        'geographic_scope': 'national',
        'created_at': '2026-03-26T10:00:00.000Z',
      });
      expect(thread.id, 42);
      expect(thread.seedPostId, 100);
      expect(thread.titleEn, 'Bongo Flava Is On Fire');
      expect(thread.titleSw, 'Bongo Flava Imewaka');
      expect(thread.category, 'entertainment');
      expect(thread.velocityScore, 85.5);
      expect(thread.postCount, 23);
      expect(thread.participantCount, 18);
      expect(thread.status, ThreadStatus.active);
    });

    test('fromJson handles minimal data', () {
      final thread = GossipThread.fromJson({'id': 1});
      expect(thread.id, 1);
      expect(thread.postCount, 0);
      expect(thread.status, ThreadStatus.active);
      expect(thread.category, 'general');
    });

    test('title returns correct language', () {
      final thread = GossipThread.fromJson({
        'id': 1,
        'title_en': 'English Title',
        'title_sw': 'Kichwa cha Kiswahili',
      });
      expect(thread.title(isSwahili: false), 'English Title');
      expect(thread.title(isSwahili: true), 'Kichwa cha Kiswahili');
    });

    test('title falls back to English when Swahili missing', () {
      final thread = GossipThread.fromJson({
        'id': 1,
        'title_en': 'English Only',
      });
      expect(thread.title(isSwahili: true), 'English Only');
    });
  });

  group('GossipThreadDetail', () {
    test('fromJson parses thread with posts', () {
      final detail = GossipThreadDetail.fromJson({
        'id': 42,
        'title_en': 'Test Thread',
        'title_sw': 'Thread ya Jaribio',
        'category': 'music',
        'velocity_score': 50.0,
        'post_count': 3,
        'participant_count': 3,
        'status': 'active',
        'posts': [
          {
            'id': 1, 'user_id': 10, 'content': 'Post 1',
            'created_at': '2026-03-26T10:00:00.000Z',
            'updated_at': '2026-03-26T10:00:00.000Z',
          },
          {
            'id': 2, 'user_id': 11, 'content': 'Post 2',
            'created_at': '2026-03-26T10:05:00.000Z',
            'updated_at': '2026-03-26T10:05:00.000Z',
          },
        ],
      });
      expect(detail.thread.id, 42);
      expect(detail.posts.length, 2);
      expect(detail.posts[0].id, 1);
    });
  });

  group('DigestResponse', () {
    test('fromJson parses threads and proverb', () {
      final digest = DigestResponse.fromJson({
        'threads': [
          {'id': 1, 'title_en': 'Thread 1', 'title_sw': 'Thread 1'},
        ],
        'proverb': {
          'text_en': 'Patience brings good things',
          'text_sw': 'Subira huvuta heri',
        },
      });
      expect(digest.threads.length, 1);
      expect(digest.proverbEn, 'Patience brings good things');
      expect(digest.proverbSw, 'Subira huvuta heri');
    });
  });
}
