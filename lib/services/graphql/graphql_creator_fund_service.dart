import '../../creator/models/creator_earnings_models.dart';
import 'tajiri_graphql_client.dart';

/// GraphQL Creators Fund earnings (Phase 42).
class GraphqlCreatorFundService {
  static const _dashboardFields = r'''
    userId
    totalClearedTsh
    totalPendingTsh
    estimatedThisPeriodTsh
    currency
    tier
    isMwanzoActive
    mwanzoExpiresAt
    monetizationPaused
    breakdownByStream
    currentPeriod {
      periodStart
      periodEnd
      phase
      fundSizeTsh
      fundPerPoint
      yourPoints
    }
  ''';

  static const _eventFields = r'''
    eventId
    occurredAt
    postId
    stream
    metric
    actorRole
    rawCount
    rateTsh
    multipliers
    grossCredit
    platformTake
    traWhtHeld
    netToCreator
    isChargeable
    chargeReason
    settlementStatus
    clearedAt
    disbursedAt
    fundingSource
  ''';

  static const _postEarningsFields = r'''
    postId
    totalClearedTsh
    totalPendingTsh
    estimatedPoolTsh
    fundPerPoint
    currency
    settlementNote
    breakdown
  ''';

  static Map<String, dynamic> _dashboardToLegacy(Map<String, dynamic> row) {
    return {
      'user_id': int.parse(row['userId'].toString()),
      'total_cleared_tsh': row['totalClearedTsh'],
      'total_pending_tsh': row['totalPendingTsh'],
      'estimated_this_period_tsh': row['estimatedThisPeriodTsh'],
      'currency': row['currency'],
      'tier': row['tier'],
      'is_mwanzo_active': row['isMwanzoActive'] == true,
      'mwanzo_expires_at': row['mwanzoExpiresAt'],
      'monetization_paused': row['monetizationPaused'] == true,
      'breakdown_by_stream': row['breakdownByStream'] ?? {},
      'current_period': row['currentPeriod'] == null
          ? null
          : {
              'period_start': (row['currentPeriod'] as Map<String, dynamic>)['periodStart'],
              'period_end': (row['currentPeriod'] as Map<String, dynamic>)['periodEnd'],
              'phase': (row['currentPeriod'] as Map<String, dynamic>)['phase'],
              'fund_size_tsh': (row['currentPeriod'] as Map<String, dynamic>)['fundSizeTsh'],
              'fund_per_point': (row['currentPeriod'] as Map<String, dynamic>)['fundPerPoint'],
              'your_points': (row['currentPeriod'] as Map<String, dynamic>)['yourPoints'],
            },
    };
  }

  static Map<String, dynamic> _eventToLegacy(Map<String, dynamic> row) {
    return {
      'event_id': int.parse(row['eventId'].toString()),
      'occurred_at': row['occurredAt'],
      'post_id': row['postId'] != null ? int.parse(row['postId'].toString()) : null,
      'stream': row['stream'],
      'metric': row['metric'],
      'actor_role': row['actorRole'],
      'raw_count': row['rawCount'],
      'rate_tsh': row['rateTsh'],
      'multipliers': row['multipliers'] ?? {},
      'gross_credit': row['grossCredit'],
      'platform_take': row['platformTake'],
      'tra_wht_held': row['traWhtHeld'],
      'net_to_creator': row['netToCreator'],
      'is_chargeable': row['isChargeable'] == true,
      'charge_reason': row['chargeReason'],
      'settlement_status': row['settlementStatus'],
      'cleared_at': row['clearedAt'],
      'disbursed_at': row['disbursedAt'],
      'funding_source': row['fundingSource'],
    };
  }

  static Map<String, dynamic> _postEarningsToLegacy(Map<String, dynamic> row) {
    return {
      'post_id': int.parse(row['postId'].toString()),
      'total_cleared_tsh': row['totalClearedTsh'],
      'total_pending_tsh': row['totalPendingTsh'],
      'estimated_pool_tsh': row['estimatedPoolTsh'],
      'fund_per_point': row['fundPerPoint'],
      'currency': row['currency'],
      'settlement_note': row['settlementNote'],
      'breakdown': row['breakdown'] ?? {},
    };
  }

  static Future<CreatorEarningsDashboard> getDashboard() async {
    final data = await TajiriGraphqlClient.instance.query(
      '''
      query MyCreatorFundDashboard {
        myCreatorFundDashboard {
          $_dashboardFields
        }
      }
      ''',
      auth: true,
    );
    final row = data['myCreatorFundDashboard'] as Map<String, dynamic>;
    return CreatorEarningsDashboard.fromJson(_dashboardToLegacy(row));
  }

  static Future<({List<EarningEventItem> items, int lastPage})> getEvents({
    int page = 1,
    int perPage = 20,
    String? stream,
    String? status,
  }) async {
    final data = await TajiriGraphqlClient.instance.query(
      '''
      query MyCreatorFundEvents(\$page: Int, \$perPage: Int, \$stream: String, \$status: String) {
        myCreatorFundEvents(page: \$page, perPage: \$perPage, stream: \$stream, status: \$status) {
          page
          lastPage
          items {
            $_eventFields
          }
        }
      }
      ''',
      variables: {
        'page': page,
        'perPage': perPage,
        if (stream != null) 'stream': stream,
        if (status != null) 'status': status,
      },
      auth: true,
    );
    final conn = data['myCreatorFundEvents'] as Map<String, dynamic>;
    final rows = conn['items'] as List<dynamic>? ?? [];
    return (
      items: rows
          .map((row) => EarningEventItem.fromJson(
              _eventToLegacy(row as Map<String, dynamic>)))
          .toList(),
      lastPage: (conn['lastPage'] as num?)?.toInt() ?? 1,
    );
  }

  static Future<PostEarningsV2> getPostEarnings(int postId) async {
    final data = await TajiriGraphqlClient.instance.query(
      '''
      query PostEarnings(\$postId: ID!) {
        postEarnings(postId: \$postId) {
          $_postEarningsFields
        }
      }
      ''',
      variables: {'postId': postId.toString()},
      auth: false,
    );
    final row = data['postEarnings'] as Map<String, dynamic>;
    return PostEarningsV2.fromJson(_postEarningsToLegacy(row));
  }

  static Future<({List<EarningEventItem> items, int lastPage})> getPostEarningEvents({
    required int postId,
    int page = 1,
    int perPage = 20,
  }) async {
    final data = await TajiriGraphqlClient.instance.query(
      '''
      query PostEarningEvents(\$postId: ID!, \$page: Int, \$perPage: Int) {
        postEarningEvents(postId: \$postId, page: \$page, perPage: \$perPage) {
          page
          lastPage
          items {
            $_eventFields
          }
        }
      }
      ''',
      variables: {
        'postId': postId.toString(),
        'page': page,
        'perPage': perPage,
      },
      auth: true,
    );
    final conn = data['postEarningEvents'] as Map<String, dynamic>;
    final rows = conn['items'] as List<dynamic>? ?? [];
    return (
      items: rows
          .map((row) => EarningEventItem.fromJson(
              _eventToLegacy(row as Map<String, dynamic>)))
          .toList(),
      lastPage: (conn['lastPage'] as num?)?.toInt() ?? 1,
    );
  }

  static Future<Map<String, dynamic>> getRateCard() async {
    final data = await TajiriGraphqlClient.instance.query(
      '''
      query CreatorRateCard {
        creatorRateCard
      }
      ''',
      auth: false,
    );
    final row = data['creatorRateCard'];
    if (row is Map<String, dynamic>) return row;
    return {};
  }

  static const _metricBreakdownFields = r'''
    period
    periodStart
    periodEnd
    currency
    totals {
      grossTsh
      netTsh
      eventCount
    }
    rows {
      metric
      actorRole
      stream
      eventCount
      rawCountTotal
      grossTsh
      platformTakeTsh
      whtTsh
      netTsh
    }
  ''';

  static Map<String, dynamic> _metricBreakdownToLegacy(Map<String, dynamic> row) {
    final totals = row['totals'] as Map<String, dynamic>? ?? {};
    final rows = row['rows'] as List<dynamic>? ?? [];
    return {
      'period': row['period'],
      'period_start': row['periodStart'],
      'period_end': row['periodEnd'],
      'currency': row['currency'],
      'totals': {
        'gross_tsh': totals['grossTsh'],
        'net_tsh': totals['netTsh'],
        'event_count': totals['eventCount'],
      },
      'rows': rows.map((item) {
        final r = item as Map<String, dynamic>;
        return {
          'metric': r['metric'],
          'actor_role': r['actorRole'],
          'stream': r['stream'],
          'event_count': r['eventCount'],
          'raw_count_total': r['rawCountTotal'],
          'gross_tsh': r['grossTsh'],
          'platform_take_tsh': r['platformTakeTsh'],
          'wht_tsh': r['whtTsh'],
          'net_tsh': r['netTsh'],
        };
      }).toList(),
    };
  }

  static Future<MetricBreakdownResponse> getByMetric({
    String period = 'month',
    String? postType,
    String? stream,
  }) async {
    final data = await TajiriGraphqlClient.instance.query(
      '''
      query MyCreatorFundByMetric(\$period: String, \$postType: String, \$stream: String) {
        myCreatorFundByMetric(period: \$period, postType: \$postType, stream: \$stream) {
          $_metricBreakdownFields
        }
      }
      ''',
      variables: {
        'period': period,
        if (postType != null) 'postType': postType,
        if (stream != null) 'stream': stream,
      },
      auth: true,
    );
    final row = data['myCreatorFundByMetric'] as Map<String, dynamic>;
    return MetricBreakdownResponse.fromJson(_metricBreakdownToLegacy(row));
  }

  static Future<MultiplierContributionResponse> getByMultiplier({
    String period = 'month',
    String? postType,
  }) async {
    final data = await TajiriGraphqlClient.instance.query(
      '''
      query MyCreatorFundByMultiplier(\$period: String, \$postType: String) {
        myCreatorFundByMultiplier(period: \$period, postType: \$postType) {
          period
          periodStart
          periodEnd
          postType
          currency
          rows {
            multiplier
            contributionTsh
            eventCount
            avgValue
          }
        }
      }
      ''',
      variables: {
        'period': period,
        if (postType != null) 'postType': postType,
      },
      auth: true,
    );
    final row = data['myCreatorFundByMultiplier'] as Map<String, dynamic>;
    final rows = row['rows'] as List<dynamic>? ?? [];
    return MultiplierContributionResponse.fromJson({
      'period': row['period'],
      'period_start': row['periodStart'],
      'period_end': row['periodEnd'],
      'post_type': row['postType'],
      'currency': row['currency'],
      'rows': rows.map((item) {
        final r = item as Map<String, dynamic>;
        return {
          'multiplier': r['multiplier'],
          'contribution_tsh': r['contributionTsh'],
          'event_count': r['eventCount'],
          'avg_value': r['avgValue'],
        };
      }).toList(),
    });
  }

  static Future<DerivativeKindResponse> getByDerivativeKind({
    String period = 'month',
    String? postType,
  }) async {
    final data = await TajiriGraphqlClient.instance.query(
      '''
      query MyCreatorFundByDerivativeKind(\$period: String, \$postType: String) {
        myCreatorFundByDerivativeKind(period: \$period, postType: \$postType) {
          period
          periodStart
          periodEnd
          postType
          currency
          totals {
            grossTsh
            netTsh
            eventCount
          }
          rows {
            kind
            postCount
            eventCount
            grossTsh
            netTsh
          }
        }
      }
      ''',
      variables: {
        'period': period,
        if (postType != null) 'postType': postType,
      },
      auth: true,
    );
    final row = data['myCreatorFundByDerivativeKind'] as Map<String, dynamic>;
    final totals = row['totals'] as Map<String, dynamic>? ?? {};
    final rows = row['rows'] as List<dynamic>? ?? [];
    return DerivativeKindResponse.fromJson({
      'period': row['period'],
      'period_start': row['periodStart'],
      'period_end': row['periodEnd'],
      'post_type': row['postType'],
      'currency': row['currency'],
      'totals': {
        'gross_tsh': totals['grossTsh'],
        'net_tsh': totals['netTsh'],
        'event_count': totals['eventCount'],
      },
      'rows': rows.map((item) {
        final r = item as Map<String, dynamic>;
        return {
          'kind': r['kind'],
          'post_count': r['postCount'],
          'event_count': r['eventCount'],
          'gross_tsh': r['grossTsh'],
          'net_tsh': r['netTsh'],
        };
      }).toList(),
    });
  }

  static Future<List<DownstreamCreator>> getDownstreamCreators({
    String period = 'month',
    int limit = 10,
  }) async {
    final data = await TajiriGraphqlClient.instance.query(
      '''
      query MyDownstreamCreators(\$period: String, \$limit: Int) {
        myDownstreamCreators(period: \$period, limit: \$limit) {
          rows {
            creatorId
            firstName
            lastName
            username
            profilePhotoPath
            derivativePostCount
            eventCount
            yourRoyaltyTsh
          }
        }
      }
      ''',
      variables: {'period': period, 'limit': limit},
      auth: true,
    );
    final conn = data['myDownstreamCreators'] as Map<String, dynamic>;
    final rows = conn['rows'] as List<dynamic>? ?? [];
    return rows.map((item) {
      final r = item as Map<String, dynamic>;
      return DownstreamCreator.fromJson({
        'creator_id': int.parse(r['creatorId'].toString()),
        'first_name': r['firstName'],
        'last_name': r['lastName'],
        'username': r['username'],
        'profile_photo_path': r['profilePhotoPath'],
        'derivative_post_count': r['derivativePostCount'],
        'event_count': r['eventCount'],
        'your_royalty_tsh': r['yourRoyaltyTsh'],
      });
    }).toList();
  }

  static Future<PostEarningsListResponse> getMyPostsEarnings({
    String period = 'month',
    int page = 1,
    int perPage = 20,
  }) async {
    final data = await TajiriGraphqlClient.instance.query(
      '''
      query MyPostsEarnings(\$period: String, \$page: Int, \$perPage: Int) {
        myPostsEarnings(period: \$period, page: \$page, perPage: \$perPage) {
          period
          periodStart
          periodEnd
          page
          lastPage
          total
          currency
          items {
            postId
            postType
            content
            thumbnailUrl
            createdAt
            totalNetTsh
            eventCount
            metrics {
              metric
              rawCountTotal
              eventCount
              netTsh
            }
          }
        }
      }
      ''',
      variables: {'period': period, 'page': page, 'perPage': perPage},
      auth: true,
    );
    final conn = data['myPostsEarnings'] as Map<String, dynamic>;
    final items = conn['items'] as List<dynamic>? ?? [];
    return PostEarningsListResponse.fromJson({
      'data': items.map((item) {
        final r = item as Map<String, dynamic>;
        final metrics = r['metrics'] as List<dynamic>? ?? [];
        return {
          'post_id': int.parse(r['postId'].toString()),
          'post_type': r['postType'],
          'content': r['content'],
          'thumbnail_url': r['thumbnailUrl'],
          'created_at': r['createdAt'],
          'total_net_tsh': r['totalNetTsh'],
          'event_count': r['eventCount'],
          'metrics': metrics.map((m) {
            final row = m as Map<String, dynamic>;
            return {
              'metric': row['metric'],
              'raw_count_total': row['rawCountTotal'],
              'event_count': row['eventCount'],
              'net_tsh': row['netTsh'],
            };
          }).toList(),
        };
      }).toList(),
      'meta': {
        'period': conn['period'],
        'period_start': conn['periodStart'],
        'period_end': conn['periodEnd'],
        'page': conn['page'],
        'last_page': conn['lastPage'],
        'total': conn['total'],
        'currency': conn['currency'],
      },
    });
  }

  static Future<Map<String, dynamic>> getTaxSummary({int? year}) async {
    final data = await TajiriGraphqlClient.instance.query(
      '''
      query MyCreatorFundTaxSummary(\$year: Int) {
        myCreatorFundTaxSummary(year: \$year) {
          year
          currency
          grossEarningsTsh
          whtWithheldTsh
          netAfterWhtTsh
          eventCount
          clearedWhtTsh
          pendingWhtTsh
        }
      }
      ''',
      variables: {if (year != null) 'year': year},
      auth: true,
    );
    final row = data['myCreatorFundTaxSummary'] as Map<String, dynamic>;
    return {
      'year': row['year'],
      'currency': row['currency'],
      'gross_earnings_tsh': row['grossEarningsTsh'],
      'wht_withheld_tsh': row['whtWithheldTsh'],
      'net_after_wht_tsh': row['netAfterWhtTsh'],
      'event_count': row['eventCount'],
      'cleared_wht_tsh': row['clearedWhtTsh'],
      'pending_wht_tsh': row['pendingWhtTsh'],
    };
  }
}
