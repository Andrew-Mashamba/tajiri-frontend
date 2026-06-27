import '../models/sponsored_post_models.dart';
import 'tajiri_graphql_client.dart';

/// GraphQL sponsored posts marketplace (Phase 34).
class GraphqlSponsoredPostService {
  static const _sponsoredPostFields = r'''
    id
    postId
    sponsorUserId
    creatorUserId
    budget
    currency
    status
    tierRequired
    impressionsTarget
    impressionsDelivered
    sponsorName
    creatorName
    createdAt
  ''';

  static Map<String, dynamic> _sponsoredPostToLegacy(Map<String, dynamic> row) {
    return {
      'id': int.parse(row['id'].toString()),
      'post_id': int.parse(row['postId'].toString()),
      'sponsor_user_id': int.parse(row['sponsorUserId'].toString()),
      'creator_user_id': int.parse(row['creatorUserId'].toString()),
      'budget': (row['budget'] as num).toDouble(),
      'currency': row['currency'],
      'status': row['status'],
      'tier_required': row['tierRequired'],
      'impressions_target': row['impressionsTarget'],
      'impressions_delivered': row['impressionsDelivered'],
      'sponsor_name': row['sponsorName'],
      'creator_name': row['creatorName'],
      'created_at': row['createdAt'],
    };
  }

  static Map<String, dynamic> _creatorToLegacy(Map<String, dynamic> row) {
    return {
      'user_id': int.parse(row['userId'].toString()),
      'name': row['name'],
      'avatar_url': row['avatarUrl'],
      'tier': row['tier'],
      'follower_count': row['followerCount'],
      'avg_engagement_rate': (row['avgEngagementRate'] as num).toDouble(),
      'top_category': row['topCategory'],
    };
  }

  static Future<List<SponsoredPost>> getActiveSponsoredPosts() async {
    try {
      final data = await TajiriGraphqlClient.instance.query(
        '''
        query ActiveSponsoredPosts {
          activeSponsoredPosts {
            $_sponsoredPostFields
          }
        }
        ''',
        auth: true,
      );
      return (data['activeSponsoredPosts'] as List? ?? []).map((row) {
        return SponsoredPost.fromJson(
          _sponsoredPostToLegacy(row as Map<String, dynamic>),
        );
      }).toList();
    } catch (_) {
      return [];
    }
  }

  static Future<List<SponsorableCreator>> browseSponsorableCreators() async {
    try {
      final data = await TajiriGraphqlClient.instance.query(
        '''
        query SponsorableCreators {
          sponsorableCreators {
            userId
            name
            avatarUrl
            tier
            followerCount
            avgEngagementRate
            topCategory
          }
        }
        ''',
        auth: true,
      );
      return (data['sponsorableCreators'] as List? ?? []).map((row) {
        return SponsorableCreator.fromJson(
          _creatorToLegacy(row as Map<String, dynamic>),
        );
      }).toList();
    } catch (_) {
      return [];
    }
  }

  static Future<bool> createSponsoredPost({
    required int postId,
    required int creatorUserId,
    required double budget,
    required int impressionsTarget,
  }) async {
    try {
      final result = await TajiriGraphqlClient.instance.mutate(
        '''
        mutation CreateSponsoredPost(\$input: CreateSponsoredPostInput!) {
          createSponsoredPost(input: \$input) {
            id
          }
        }
        ''',
        variables: {
          'input': {
            'postId': postId.toString(),
            'creatorUserId': creatorUserId.toString(),
            'budget': budget,
            'impressionsTarget': impressionsTarget,
            'idempotencyKey':
                'sponsored_post_${DateTime.now().millisecondsSinceEpoch}',
          },
        },
        auth: true,
      );
      return result['createSponsoredPost'] != null;
    } catch (_) {
      return false;
    }
  }

  static Future<List<SponsoredPost>> getCreatorSponsored(int creatorId) async {
    try {
      final data = await TajiriGraphqlClient.instance.query(
        '''
        query CreatorSponsoredPosts(\$creatorId: ID!) {
          creatorSponsoredPosts(creatorId: \$creatorId) {
            $_sponsoredPostFields
          }
        }
        ''',
        variables: {'creatorId': creatorId.toString()},
        auth: true,
      );
      return (data['creatorSponsoredPosts'] as List? ?? []).map((row) {
        return SponsoredPost.fromJson(
          _sponsoredPostToLegacy(row as Map<String, dynamic>),
        );
      }).toList();
    } catch (_) {
      return [];
    }
  }
}
