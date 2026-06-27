import '../../models/analytics_models.dart';
import 'tajiri_graphql_client.dart';

/// GraphQL creator analytics (Phase 40).
class GraphqlAnalyticsService {
  static const _dashboardFields = r'''
    totalViews
    totalLikes
    totalShares
    totalComments
    avgEngagementRate
    followerCount
    followerChange30d
    threadsTriggered30d
    postsCount30d
    sessionDepthAvg
    bestPostingTime
    topContentFormat
    topCategory
    engagementTrend
    dailyMetrics {
      date
      views
      likes
      followers
    }
  ''';

  static const _postPerformanceFields = r'''
    postId
    views
    likes
    comments
    shares
    saves
    engagementRate
    avgDwellMs
    threadTitle
  ''';

  static const _audienceFields = r'''
    topCity
    topAgeRange
    malePercent
    femalePercent
    activeFollowersCount
    peakActivityTime
  ''';

  static Map<String, dynamic> _dashboardToLegacy(Map<String, dynamic> row) {
    final metrics = row['dailyMetrics'] as List<dynamic>? ?? [];
    return {
      'total_views': row['totalViews'],
      'total_likes': row['totalLikes'],
      'total_shares': row['totalShares'],
      'total_comments': row['totalComments'],
      'avg_engagement_rate': row['avgEngagementRate'],
      'follower_count': row['followerCount'],
      'follower_change_30d': row['followerChange30d'],
      'threads_triggered_30d': row['threadsTriggered30d'],
      'posts_count_30d': row['postsCount30d'],
      'session_depth_avg': row['sessionDepthAvg'],
      'best_posting_time': row['bestPostingTime'],
      'top_content_format': row['topContentFormat'],
      'top_category': row['topCategory'],
      'engagement_trend': row['engagementTrend'],
      'daily_metrics': metrics
          .map((m) => {
                'date': (m as Map<String, dynamic>)['date'],
                'views': m['views'],
                'likes': m['likes'],
                'followers': m['followers'],
              })
          .toList(),
    };
  }

  static Map<String, dynamic> _postPerformanceToLegacy(Map<String, dynamic> row) {
    return {
      'post_id': int.parse(row['postId'].toString()),
      'views': row['views'],
      'likes': row['likes'],
      'comments': row['comments'],
      'shares': row['shares'],
      'saves': row['saves'],
      'engagement_rate': row['engagementRate'],
      'avg_dwell_ms': row['avgDwellMs'],
      'thread_title': row['threadTitle'],
    };
  }

  static Map<String, dynamic> _audienceToLegacy(Map<String, dynamic> row) {
    return {
      'top_city': row['topCity'],
      'top_age_range': row['topAgeRange'],
      'male_percent': row['malePercent'],
      'female_percent': row['femalePercent'],
      'active_followers_count': row['activeFollowersCount'],
      'peak_activity_time': row['peakActivityTime'],
    };
  }

  static Future<AnalyticsDashboard?> getDashboard({
    required int creatorId,
  }) async {
    try {
      final data = await TajiriGraphqlClient.instance.query(
        '''
        query CreatorAnalyticsDashboard(\$creatorId: ID!) {
          creatorAnalyticsDashboard(creatorId: \$creatorId) {
            $_dashboardFields
          }
        }
        ''',
        variables: {'creatorId': creatorId.toString()},
        auth: false,
      );
      final row = data['creatorAnalyticsDashboard'] as Map<String, dynamic>?;
      if (row == null) return null;
      return AnalyticsDashboard.fromJson(_dashboardToLegacy(row));
    } catch (_) {
      return null;
    }
  }

  static Future<List<PostPerformance>> getPostPerformance({
    required int creatorId,
  }) async {
    try {
      final data = await TajiriGraphqlClient.instance.query(
        '''
        query CreatorPostPerformance(\$creatorId: ID!) {
          creatorPostPerformance(creatorId: \$creatorId) {
            $_postPerformanceFields
          }
        }
        ''',
        variables: {'creatorId': creatorId.toString()},
        auth: false,
      );
      final rows = data['creatorPostPerformance'] as List<dynamic>? ?? [];
      return rows
          .map((row) => PostPerformance.fromJson(
              _postPerformanceToLegacy(row as Map<String, dynamic>)))
          .toList();
    } catch (_) {
      return [];
    }
  }

  static Future<AudienceInsight?> getAudienceInsights({
    required int creatorId,
  }) async {
    try {
      final data = await TajiriGraphqlClient.instance.query(
        '''
        query CreatorAudienceInsights(\$creatorId: ID!) {
          creatorAudienceInsights(creatorId: \$creatorId) {
            $_audienceFields
          }
        }
        ''',
        variables: {'creatorId': creatorId.toString()},
        auth: false,
      );
      final row = data['creatorAudienceInsights'] as Map<String, dynamic>?;
      if (row == null) return null;
      return AudienceInsight.fromJson(_audienceToLegacy(row));
    } catch (_) {
      return null;
    }
  }

  static Future<String> getEngagementLevel({
    required int userId,
  }) async {
    try {
      final data = await TajiriGraphqlClient.instance.query(
        '''
        query EngagementLevel(\$userId: ID!) {
          engagementLevel(userId: \$userId)
        }
        ''',
        variables: {'userId': userId.toString()},
        auth: false,
      );
      return (data['engagementLevel'] as String?) ?? 'gentle';
    } catch (_) {
      return 'gentle';
    }
  }
}
