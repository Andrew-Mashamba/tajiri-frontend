import 'tajiri_graphql_client.dart';

/// GraphQL creator metrics, onboarding, collaborations (Phase 47).
class GraphqlCreatorMetricsService {
  static Map<String, dynamic> _scoreFromGql(Map<String, dynamic> row) => {
        'user_id': row['userId'],
        'score': row['score'],
        'tier': row['tier'],
        'community_score': row['communityScore'],
        'quality_score': row['qualityScore'],
        'consistency_score': row['consistencyScore'],
        'tier_multiplier': row['tierMultiplier'],
        'computed_at': row['computedAt'],
      };

  static Map<String, dynamic> _streakFromGql(Map<String, dynamic> row) => {
        'user_id': row['userId'],
        'current_streak_days': row['currentStreakDays'],
        'longest_streak_days': row['longestStreakDays'],
        'last_post_at': row['lastPostAt'],
        'banked_skip_days': row['bankedSkipDays'],
        'is_frozen': row['isFrozen'],
        'frozen_at': row['frozenAt'],
        'streak_multiplier': row['streakMultiplier'],
      };

  static Map<String, dynamic> _viewerStreakFromGql(Map<String, dynamic> row) => {
        'user_id': row['userId'],
        'current_streak_days': row['currentStreakDays'],
        'longest_streak_days': row['longestStreakDays'],
        'last_active_date': row['lastActiveDate'],
        'is_frozen': row['isFrozen'],
        'frozen_at': row['frozenAt'],
      };

  static Map<String, dynamic> _weeklyReportFromGql(Map<String, dynamic> row) => {
        'total_earnings': row['totalEarnings'],
        'earnings_change_percent': row['earningsChangePercent'],
        'best_post_id': row['bestPostId'],
        'best_post_likes': row['bestPostLikes'],
        'engagement_trend': row['engagementTrend'],
        'follower_change': row['followerChange'],
        'threads_triggered': row['threadsTriggered'],
        'total_views': row['totalViews'],
        'total_likes': row['totalLikes'],
        'week_start': row['weekStart'],
        'week_end': row['weekEnd'],
        'posting_tip': row['postingTip'],
      };

  static Map<String, dynamic> _nudgeFromGql(Map<String, dynamic> row) => {
        'message': row['message'],
        'message_sw': row['messageSw'],
        'nudge_type': row['nudgeType'],
        'hours_until_streak_expiry': row['hoursUntilStreakExpiry'],
      };

  static Map<String, dynamic> _calendarFromGql(Map<String, dynamic> row) => {
        'drafts_count': row['draftsCount'],
        'posts_this_week': row['postsThisWeek'],
        'scheduled_count': row['scheduledCount'],
        'suggested_post_time': row['suggestedPostTime'],
      };

  static Map<String, dynamic> _payoutFromGql(Map<String, dynamic> row) => {
        'user_id': row['userId'],
        'current_month': row['currentMonth'],
        'projected_score': row['projectedScore'],
        'projected_payout': row['projectedPayout'],
        'tier': row['tier'],
        'multipliers': row['multipliers'],
      };

  static Map<String, dynamic> _onboardingFromGql(Map<String, dynamic> row) => {
        'tajirika': {
          'auto_provisioned_at': row['tajirikaAutoProvisionedAt'],
          'banner_dismissed_at': row['tajirikaBannerDismissedAt'],
          'show_banner': row['tajirikaShowBanner'],
        },
        'wellness': {
          'off_day_mode': row['offDayMode'],
        },
      };

  static Map<String, dynamic> _collabFromGql(Map<String, dynamic> row) => {
        'id': row['id'],
        'creator_a_id': row['creatorAId'],
        'creator_b_id': row['creatorBId'],
        'shared_category': row['sharedCategory'],
        'affinity_score': row['affinityScore'],
        'status': row['status'],
        'partner_name': row['partnerName'],
        'partner_avatar_url': row['partnerAvatarUrl'],
        'partner_tier': row['partnerTier'],
        'partner_follower_count': row['partnerFollowerCount'],
      };

  static Future<Map<String, dynamic>?> getCreatorScore(int creatorId) async {
    try {
      final data = await TajiriGraphqlClient.instance.query(
        '''
        query CreatorScore(\$creatorId: ID!) {
          creatorScore(creatorId: \$creatorId) {
            userId score tier communityScore qualityScore
            consistencyScore tierMultiplier computedAt
          }
        }
        ''',
        variables: {'creatorId': creatorId.toString()},
        auth: false,
      );
      final row = data['creatorScore'];
      if (row is Map<String, dynamic>) return _scoreFromGql(row);
      return null;
    } catch (_) {
      return null;
    }
  }

  static Future<Map<String, dynamic>?> getCreatorStreak(int creatorId) async {
    try {
      final data = await TajiriGraphqlClient.instance.query(
        '''
        query CreatorStreak(\$creatorId: ID!) {
          creatorStreak(creatorId: \$creatorId) {
            userId currentStreakDays longestStreakDays lastPostAt
            bankedSkipDays isFrozen frozenAt streakMultiplier
          }
        }
        ''',
        variables: {'creatorId': creatorId.toString()},
        auth: false,
      );
      final row = data['creatorStreak'];
      if (row is Map<String, dynamic>) return _streakFromGql(row);
      return null;
    } catch (_) {
      return null;
    }
  }

  static Future<Map<String, dynamic>?> getViewerStreak(int userId) async {
    try {
      final data = await TajiriGraphqlClient.instance.query(
        '''
        query ViewerStreak(\$userId: ID!) {
          viewerStreak(userId: \$userId) {
            userId currentStreakDays longestStreakDays lastActiveDate
            isFrozen frozenAt
          }
        }
        ''',
        variables: {'userId': userId.toString()},
        auth: false,
      );
      final row = data['viewerStreak'];
      if (row is Map<String, dynamic>) return _viewerStreakFromGql(row);
      return null;
    } catch (_) {
      return null;
    }
  }

  static Future<Map<String, dynamic>?> getWeeklyReport(int creatorId) async {
    try {
      final data = await TajiriGraphqlClient.instance.query(
        '''
        query CreatorWeeklyReport(\$creatorId: ID!) {
          creatorWeeklyReport(creatorId: \$creatorId) {
            totalEarnings earningsChangePercent bestPostId bestPostLikes
            engagementTrend followerChange threadsTriggered totalViews
            totalLikes weekStart weekEnd postingTip
          }
        }
        ''',
        variables: {'creatorId': creatorId.toString()},
        auth: false,
      );
      final row = data['creatorWeeklyReport'];
      if (row is Map<String, dynamic>) return _weeklyReportFromGql(row);
      return null;
    } catch (_) {
      return null;
    }
  }

  static Future<int> getViralAssists(int creatorId) async {
    try {
      final data = await TajiriGraphqlClient.instance.query(
        '''
        query CreatorViralAssists(\$creatorId: ID!) {
          creatorViralAssists(creatorId: \$creatorId)
        }
        ''',
        variables: {'creatorId': creatorId.toString()},
        auth: false,
      );
      return (data['creatorViralAssists'] as int?) ?? 0;
    } catch (_) {
      return 0;
    }
  }

  static Future<Map<String, dynamic>?> getPostingNudge(int creatorId) async {
    try {
      final data = await TajiriGraphqlClient.instance.query(
        '''
        query CreatorPostingNudge(\$creatorId: ID!) {
          creatorPostingNudge(creatorId: \$creatorId) {
            message messageSw nudgeType hoursUntilStreakExpiry
          }
        }
        ''',
        variables: {'creatorId': creatorId.toString()},
        auth: false,
      );
      final row = data['creatorPostingNudge'];
      if (row is Map<String, dynamic>) return _nudgeFromGql(row);
      return null;
    } catch (_) {
      return null;
    }
  }

  static Future<Map<String, dynamic>?> getContentCalendar(int creatorId) async {
    try {
      final data = await TajiriGraphqlClient.instance.query(
        '''
        query CreatorContentCalendar(\$creatorId: ID!) {
          creatorContentCalendar(creatorId: \$creatorId) {
            draftsCount postsThisWeek scheduledCount suggestedPostTime
          }
        }
        ''',
        variables: {'creatorId': creatorId.toString()},
        auth: false,
      );
      final row = data['creatorContentCalendar'];
      if (row is Map<String, dynamic>) return _calendarFromGql(row);
      return null;
    } catch (_) {
      return null;
    }
  }

  static Future<Map<String, dynamic>?> getFundPayoutProjection(int creatorId) async {
    try {
      final data = await TajiriGraphqlClient.instance.query(
        '''
        query CreatorFundPayoutProjection(\$creatorId: ID!) {
          creatorFundPayoutProjection(creatorId: \$creatorId) {
            userId currentMonth projectedScore projectedPayout tier multipliers
          }
        }
        ''',
        variables: {'creatorId': creatorId.toString()},
        auth: false,
      );
      final row = data['creatorFundPayoutProjection'];
      if (row is Map<String, dynamic>) return _payoutFromGql(row);
      return null;
    } catch (_) {
      return null;
    }
  }

  static Future<bool> resumeViewerStreak() async {
    try {
      final result = await TajiriGraphqlClient.instance.mutate(
        'mutation { resumeViewerStreak }',
        auth: true,
      );
      return result['resumeViewerStreak'] == true;
    } catch (_) {
      return false;
    }
  }

  static Future<Map<String, dynamic>?> getOnboarding() async {
    try {
      final data = await TajiriGraphqlClient.instance.query(
        '''
        query MyCreatorOnboarding {
          myCreatorOnboarding {
            tajirikaAutoProvisionedAt tajirikaBannerDismissedAt
            tajirikaShowBanner offDayMode
          }
        }
        ''',
        auth: true,
      );
      final row = data['myCreatorOnboarding'];
      if (row is Map<String, dynamic>) return _onboardingFromGql(row);
      return null;
    } catch (_) {
      return null;
    }
  }

  static Future<bool> dismissTajirikaBanner() async {
    try {
      final result = await TajiriGraphqlClient.instance.mutate(
        '''
        mutation {
          dismissTajirikaBanner {
            tajirikaShowBanner
          }
        }
        ''',
        auth: true,
      );
      final row = result['dismissTajirikaBanner'];
      if (row is Map<String, dynamic>) {
        return row['tajirikaShowBanner'] != true;
      }
      return false;
    } catch (_) {
      return false;
    }
  }

  static Future<bool> setOffDayMode(bool enabled) async {
    try {
      final result = await TajiriGraphqlClient.instance.mutate(
        '''
        mutation SetCreatorOffDayMode(\$enabled: Boolean!) {
          setCreatorOffDayMode(enabled: \$enabled) {
            offDayMode
          }
        }
        ''',
        variables: {'enabled': enabled},
        auth: true,
      );
      final row = result['setCreatorOffDayMode'];
      if (row is Map<String, dynamic>) {
        return row['offDayMode'] == enabled;
      }
      return false;
    } catch (_) {
      return false;
    }
  }

  static Future<List<Map<String, dynamic>>> getCollaborations(int creatorId) async {
    try {
      final data = await TajiriGraphqlClient.instance.query(
        '''
        query CreatorCollaborations(\$creatorId: ID!) {
          creatorCollaborations(creatorId: \$creatorId) {
            id creatorAId creatorBId sharedCategory affinityScore status
            partnerName partnerAvatarUrl partnerTier partnerFollowerCount
          }
        }
        ''',
        variables: {'creatorId': creatorId.toString()},
        auth: false,
      );
      final rows = data['creatorCollaborations'];
      if (rows is List) {
        return rows
            .whereType<Map<String, dynamic>>()
            .map(_collabFromGql)
            .toList();
      }
      return [];
    } catch (_) {
      return [];
    }
  }

  static Future<bool> respondToCollaboration({
    required int suggestionId,
    required String action,
  }) async {
    try {
      final result = await TajiriGraphqlClient.instance.mutate(
        '''
        mutation RespondToCollaboration(\$suggestionId: ID!, \$action: String!) {
          respondToCollaboration(suggestionId: \$suggestionId, action: \$action)
        }
        ''',
        variables: {
          'suggestionId': suggestionId.toString(),
          'action': action,
        },
        auth: true,
      );
      return result['respondToCollaboration'] == true;
    } catch (_) {
      return false;
    }
  }
}
