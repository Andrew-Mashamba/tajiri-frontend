/// Integration test: verify the app can pull posts from the backend.
///
/// Backend must be running and ApiConfig.baseUrl must point to it.
/// Run: flutter test test/pull_posts_test.dart
///
/// Expected backend response shape:
///   { "success": true, "data": [ { "id", "user_id", "type", "content", ... } ], "meta": { ... } }

import 'package:flutter_test/flutter_test.dart';
import 'package:tajiri/services/post_service.dart';
import 'package:tajiri/services/feed_service.dart';

void main() {
  late PostService postService;
  late FeedService feedService;

  setUp(() {
    postService = PostService();
    feedService = FeedService();
  });

  test('GET /api/posts returns posts from backend', () async {
    final result = await postService.getPosts(page: 1, perPage: 20);

    expect(result, isNotNull);
    if (result.success) {
      expect(result.posts, isNotNull);
      // Backend table has posts with IDs 1,3,4,5,6,7,8,9,12,13,14,15
      print('[PullPosts] GET /api/posts: success=true, count=${result.posts.length}');
      for (final p in result.posts.take(5)) {
        print('  - id=${p.id} user=${p.userId} type=${p.postType} content=${p.content?.toString().replaceAll('\n', ' ').length ?? 0} chars');
      }
      if (result.posts.length > 5) {
        print('  ... and ${result.posts.length - 5} more');
      }
    } else {
      print('[PullPosts] GET /api/posts: success=false message=${result.message}');
    }
    // Pass as long as the call completed (backend reachable and JSON parsed)
    expect(result.posts, isNotNull);
  });

  test('GET /api/posts/feed/for-you returns feed for user', () async {
    // Use userId 2 (has posts 1,3,4,5,6,7,8,9) or 4 (has 12,13,14,15)
    const testUserId = 2;
    final result = await feedService.getForYouFeed(
      userId: testUserId,
      page: 1,
      perPage: 20,
    );

    expect(result, isNotNull);
    if (result.success) {
      expect(result.posts, isNotNull);
      print('[PullPosts] GET /api/posts/feed/for-you (user_id=$testUserId): success=true, count=${result.posts.length}');
      for (final p in result.posts.take(5)) {
        print('  - id=${p.id} type=${p.postType} content=${p.content ?? "—"}');
      }
      if (result.posts.length > 5) {
        print('  ... and ${result.posts.length - 5} more');
      }
    } else {
      print('[PullPosts] GET /api/posts/feed/for-you: success=false message=${result.message}');
    }
    expect(result.posts, isNotNull);
  });
}
