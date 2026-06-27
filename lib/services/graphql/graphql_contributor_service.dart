import 'contributor_service.dart' show PostContributor;
import 'tajiri_graphql_client.dart';

/// GraphQL post revenue-split contributors (Phase 39).
class GraphqlContributorService {
  static const _fields = r'''
    id
    postId
    userId
    role
    sharePct
    userName
    userHandle
    userPhotoUrl
    accepted
  ''';

  static Map<String, dynamic> _toLegacy(Map<String, dynamic> row) {
    return {
      'id': int.parse(row['id'].toString()),
      'post_id': int.parse(row['postId'].toString()),
      'user_id': int.parse(row['userId'].toString()),
      'role': row['role'],
      'share_pct': (row['sharePct'] as num).toDouble(),
      'user_name': row['userName'],
      'user_handle': row['userHandle'],
      'user_photo_url': row['userPhotoUrl'],
      'accepted': row['accepted'] == true,
    };
  }

  static Future<List<PostContributor>> list(int postId) async {
    try {
      final data = await TajiriGraphqlClient.instance.query(
        '''
        query PostContributors(\$postId: ID!) {
          postContributors(postId: \$postId) {
            $_fields
          }
        }
        ''',
        variables: {'postId': postId.toString()},
        auth: false,
      );
      final rows = data['postContributors'] as List<dynamic>? ?? [];
      return rows
          .map((row) => PostContributor.fromJson(_toLegacy(row as Map<String, dynamic>)))
          .toList(growable: false);
    } catch (_) {
      return [];
    }
  }

  static Future<bool> add({
    required int postId,
    required int userId,
    required String role,
    required double sharePct,
  }) async {
    try {
      final result = await TajiriGraphqlClient.instance.mutate(
        '''
        mutation AddPostContributor(\$input: AddPostContributorInput!) {
          addPostContributor(input: \$input) {
            id
          }
        }
        ''',
        variables: {
          'input': {
            'postId': postId.toString(),
            'userId': userId.toString(),
            'role': role,
            'sharePct': sharePct,
          },
        },
        auth: true,
      );
      return result['addPostContributor'] != null;
    } catch (_) {
      return false;
    }
  }

  static Future<bool> remove({
    required int postId,
    required int contributorId,
  }) async {
    try {
      final result = await TajiriGraphqlClient.instance.mutate(
        '''
        mutation RemovePostContributor(\$postId: ID!, \$contributorId: ID!) {
          removePostContributor(postId: \$postId, contributorId: \$contributorId)
        }
        ''',
        variables: {
          'postId': postId.toString(),
          'contributorId': contributorId.toString(),
        },
        auth: true,
      );
      return result['removePostContributor'] == true;
    } catch (_) {
      return false;
    }
  }
}
