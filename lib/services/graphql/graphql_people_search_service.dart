import '../../models/people_search_models.dart';
import '../people_search_service.dart';
import 'tajiri_graphql_client.dart';

/// GraphQL people search / discovery (Phase 78, extended Phase 88–90, 176–178).
/// Multi-sort combos and ETag caching remain REST-only.
class GraphqlPeopleSearchService {
  static String? _cursor;
  static int _lastPage = 1;
  static String? _queryKey;

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
    String sort = 'relevance',
    bool? hasPhoto,
    bool? online,
    String? gender,
    String? location,
    String? employer,
    String? school,
    String? sector,
    String? relationshipStatus,
    int? ageMin,
    int? ageMax,
    bool? hasBusiness,
    bool? student,
    bool? profileComplete,
    bool? verified,
    bool? hasInterests,
    bool? possibleEmployer,
    bool? possibleBusinessConnection,
    bool shuffle = false,
  }) async {
    try {
      final key =
          '${query ?? ''}|$friendsOfFriendsOnly|$sort|${hasPhoto == true}|${online == true}|$gender|$location|$employer|$school|$sector|$relationshipStatus|$ageMin|$ageMax|${hasBusiness == true}|${student == true}|${profileComplete == true}|${verified == true}|${hasInterests == true}|${possibleEmployer == true}|${possibleBusinessConnection == true}|$shuffle';
      if (page == 1) {
        _cursor = null;
        _lastPage = 1;
        _queryKey = key;
      } else if (_queryKey != key) {
        return PeopleSearchResult.failure('Filter changed — restart from page 1');
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
      final graphqlSort = sort == 'relevance' ? 'newest' : sort;
      final data = await TajiriGraphqlClient.instance.query(
        '''
        query PeopleSearch(
          \$q: String
          \$cursor: String
          \$friendsOfFriendsOnly: Boolean!
          \$sort: String
          \$shuffle: Boolean
          \$filter: PeopleSearchFilter
        ) {
          peopleSearch(
            q: \$q
            cursor: \$cursor
            friendsOfFriendsOnly: \$friendsOfFriendsOnly
            sort: \$sort
            shuffle: \$shuffle
            filter: \$filter
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
          'sort': graphqlSort,
          'shuffle': shuffle,
          if (hasPhoto == true ||
              online == true ||
              gender != null ||
              location != null ||
              employer != null ||
              school != null ||
              sector != null ||
              relationshipStatus != null ||
              ageMin != null ||
              ageMax != null ||
              hasBusiness == true ||
              student == true ||
              profileComplete == true ||
              verified == true ||
              hasInterests == true ||
              possibleEmployer == true ||
              possibleBusinessConnection == true)
            'filter': {
              if (hasPhoto == true) 'hasPhoto': true,
              if (online == true) 'online': true,
              if (gender != null && gender.isNotEmpty) 'gender': gender,
              if (location != null && location.isNotEmpty) 'location': location,
              if (employer != null && employer.isNotEmpty) 'employer': employer,
              if (school != null && school.isNotEmpty) 'school': school,
              if (sector != null && sector.isNotEmpty) 'sector': sector,
              if (relationshipStatus != null && relationshipStatus.isNotEmpty)
                'relationshipStatus': relationshipStatus,
              if (ageMin != null) 'ageMin': ageMin,
              if (ageMax != null) 'ageMax': ageMax,
              if (hasBusiness == true) 'hasBusiness': true,
              if (student == true) 'student': true,
              if (profileComplete == true) 'profileComplete': true,
              if (verified == true) 'verified': true,
              if (hasInterests == true) 'hasInterests': true,
              if (possibleEmployer == true) 'possibleEmployer': true,
              if (possibleBusinessConnection == true)
                'possibleBusinessConnection': true,
            },
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
