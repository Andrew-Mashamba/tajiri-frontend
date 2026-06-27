import '../../models/people_search_models.dart';
import 'tajiri_graphql_client.dart';

/// GraphQL people search / discovery (Phase 78).
/// Advanced filters, ETag caching, and non-relevance sorts remain REST-only.
class GraphqlPeopleSearchService {
  static String? _cursor;
  static int _lastPage = 1;

  static Map<String, dynamic> _personToLegacy(Map<String, dynamic> row) {
    final displayName = row['displayName']?.toString() ?? '';
    final parts = displayName.split(' ');
    return {
      'id': int.tryParse(row['id']?.toString() ?? '') ?? 0,
      'first_name': parts.isNotEmpty ? parts.first : displayName,
      'last_name': parts.length > 1 ? parts.sublist(1).join(' ') : '',
      'username': row['username'],
      'profile_photo_path': row['avatarUrl'],
      'mutual_friends_count': row['mutualFriendsCount'] ?? 0,
      'friendship_status': row['friendshipStatus'] ?? 'none',
      'friends_count': row['friendsCount'] ?? 0,
      'posts_count': row['postsCount'] ?? 0,
      'photos_count': row['photosCount'] ?? 0,
      'in_common': <String>[],
      'is_online': false,
    };
  }

  static const _personFields = r'''
    id
    username
    displayName
    avatarUrl
    friendshipStatus
    mutualFriendsCount
    isFollowing
    isFollowedBy
    friendsCount
    postsCount
    photosCount
  ''';

  static Future<PeopleSearchResult> search({
    String? query,
    int page = 1,
    int perPage = 20,
    bool friendsOfFriendsOnly = false,
  }) async {
    try {
      if (page == 1) {
        _cursor = null;
        _lastPage = 1;
      } else if (page > _lastPage + 1) {
        return PeopleSearchResult.failure('Invalid page');
      } else if (page > 1 && _cursor == null) {
        return PeopleSearchResult.success(PeopleSearchResponse(
          people: [],
          currentPage: page,
          lastPage: page,
          total: 0,
          perPage: perPage,
        ));
      }

      final q = query?.trim() ?? '';
      final data = await TajiriGraphqlClient.instance.query(
        '''
        query PeopleSearch(
          \$q: String
          \$cursor: String
          \$friendsOfFriendsOnly: Boolean!
        ) {
          peopleSearch(
            q: \$q
            cursor: \$cursor
            friendsOfFriendsOnly: \$friendsOfFriendsOnly
          ) {
            items { $_personFields }
            nextCursor
            hasMore
          }
        }
        ''',
        variables: {
          if (q.length >= 2) 'q': q,
          if (_cursor != null) 'cursor': _cursor,
          'friendsOfFriendsOnly': friendsOfFriendsOnly,
        },
        auth: true,
      );

      final conn = data['peopleSearch'] as Map<String, dynamic>? ?? {};
      final rows = conn['items'] as List<dynamic>? ?? [];
      final people = rows
          .whereType<Map<String, dynamic>>()
          .map((row) => PersonSearchResult.fromJson(_personToLegacy(row)))
          .toList();
      final hasMore = conn['hasMore'] == true;
      final nextCursor = conn['nextCursor']?.toString();
      if (hasMore && nextCursor != null) {
        _cursor = nextCursor;
        _lastPage = page + 1;
      } else {
        _lastPage = page;
      }

      return PeopleSearchResult.success(PeopleSearchResponse(
        people: people,
        currentPage: page,
        lastPage: hasMore ? page + 1 : page,
        total: people.length,
        perPage: perPage,
      ));
    } catch (e) {
      return PeopleSearchResult.failure('$e');
    }
  }
}
