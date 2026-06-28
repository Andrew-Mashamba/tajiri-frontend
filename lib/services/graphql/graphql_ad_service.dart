import '../models/ad_models.dart';
import 'tajiri_graphql_client.dart';

/// GraphQL ads & biashara campaigns (Phase 33).
class GraphqlAdService {
  static const _campaignFields = r'''
    id
    advertiserId
    title
    description
    campaignType
    status
    dailyBudget
    totalBudget
    spentAmount
    bidAmount
    startDate
    endDate
    targeting
    placements
    rejectionReason
    createdAt
    updatedAt
    creatives {
      id
      campaignId
      format
      mediaUrl
      headline
      bodyText
      ctaType
      ctaUrl
      productId
      approved
      createdAt
    }
  ''';

  static const _creativeFields = r'''
    id
    campaignId
    format
    mediaUrl
    headline
    bodyText
    ctaType
    ctaUrl
    productId
    approved
    createdAt
  ''';

  static Map<String, dynamic> _campaignToLegacy(Map<String, dynamic> row) {
    return {
      'id': int.parse(row['id'].toString()),
      'advertiser_id': int.parse(row['advertiserId'].toString()),
      'title': row['title'],
      'description': row['description'],
      'campaign_type': row['campaignType'],
      'status': row['status'],
      'daily_budget': (row['dailyBudget'] as num).toDouble(),
      'total_budget': (row['totalBudget'] as num).toDouble(),
      'spent_amount': (row['spentAmount'] as num).toDouble(),
      'bid_amount': (row['bidAmount'] as num).toDouble(),
      'start_date': row['startDate'],
      'end_date': row['endDate'],
      'targeting': row['targeting'] ?? {},
      'placements': row['placements'] ?? [],
      'rejection_reason': row['rejectionReason'],
      'created_at': row['createdAt'],
      'updated_at': row['updatedAt'],
      'creatives': (row['creatives'] as List? ?? [])
          .map((c) => _creativeToLegacy(c as Map<String, dynamic>))
          .toList(),
    };
  }

  static Map<String, dynamic> _creativeToLegacy(Map<String, dynamic> row) {
    return {
      'id': int.parse(row['id'].toString()),
      'campaign_id': int.parse(row['campaignId'].toString()),
      'format': row['format'],
      'media_url': row['mediaUrl'],
      'headline': row['headline'],
      'body_text': row['bodyText'],
      'cta_type': row['ctaType'],
      'cta_url': row['ctaUrl'],
      'product_id': row['productId'] != null
          ? int.parse(row['productId'].toString())
          : null,
      'approved': row['approved'] == true,
      'created_at': row['createdAt'],
    };
  }

  static Map<String, dynamic> _servedAdToLegacy(Map<String, dynamic> row) {
    return {
      'campaign_id': int.parse(row['campaignId'].toString()),
      'creative_id': int.parse(row['creativeId'].toString()),
      'title': row['title'],
      'headline': row['headline'],
      'body_text': row['bodyText'],
      'media_url': row['mediaUrl'],
      'cta_type': row['ctaType'],
      'cta_url': row['ctaUrl'],
      'campaign_type': row['campaignType'],
      'placement': row['placement'],
    };
  }

  static Map<String, dynamic> _createCampaignInput(Map<String, dynamic> data) {
    return {
      'title': data['title'],
      if (data['description'] != null) 'description': data['description'],
      'campaignType': data['campaign_type'] ?? data['campaignType'] ?? 'display',
      'dailyBudget': data['daily_budget'] ?? data['dailyBudget'] ?? 0,
      'totalBudget': data['total_budget'] ?? data['totalBudget'],
      'bidAmount': data['bid_amount'] ?? data['bidAmount'] ?? 0,
      'startDate': data['start_date'] ?? data['startDate'],
      if (data['end_date'] != null) 'endDate': data['end_date'],
      if (data['endDate'] != null) 'endDate': data['endDate'],
      if (data['targeting'] != null) 'targeting': data['targeting'],
      if (data['placements'] != null) 'placements': data['placements'],
    };
  }

  static Map<String, dynamic> _updateCampaignInput(Map<String, dynamic> data) {
    final input = <String, dynamic>{};
    if (data['title'] != null) input['title'] = data['title'];
    if (data['description'] != null) input['description'] = data['description'];
    if (data['campaign_type'] != null) {
      input['campaignType'] = data['campaign_type'];
    }
    if (data['campaignType'] != null) input['campaignType'] = data['campaignType'];
    if (data['daily_budget'] != null) input['dailyBudget'] = data['daily_budget'];
    if (data['dailyBudget'] != null) input['dailyBudget'] = data['dailyBudget'];
    if (data['total_budget'] != null) input['totalBudget'] = data['total_budget'];
    if (data['totalBudget'] != null) input['totalBudget'] = data['totalBudget'];
    if (data['bid_amount'] != null) input['bidAmount'] = data['bid_amount'];
    if (data['bidAmount'] != null) input['bidAmount'] = data['bidAmount'];
    if (data['start_date'] != null) input['startDate'] = data['start_date'];
    if (data['startDate'] != null) input['startDate'] = data['startDate'];
    if (data['end_date'] != null) input['endDate'] = data['end_date'];
    if (data['endDate'] != null) input['endDate'] = data['endDate'];
    if (data['targeting'] != null) input['targeting'] = data['targeting'];
    if (data['placements'] != null) input['placements'] = data['placements'];
    return input;
  }

  static Future<List<ServedAd>> getServedAds(String placement, int count) async {
    try {
      final data = await TajiriGraphqlClient.instance.query(
        '''
        query ServeAds(\$placement: String!, \$count: Int!) {
          serveAds(placement: \$placement, count: \$count) {
            campaignId
            creativeId
            title
            headline
            bodyText
            mediaUrl
            ctaType
            ctaUrl
            campaignType
            placement
          }
        }
        ''',
        variables: {'placement': placement, 'count': count},
        auth: true,
      );
      return (data['serveAds'] as List? ?? []).map((row) {
        return ServedAd.fromJson(_servedAdToLegacy(row as Map<String, dynamic>));
      }).toList();
    } catch (_) {
      return [];
    }
  }

  static Future<bool> recordAdEvent(
    int campaignId,
    int creativeId,
    int userId,
    String placement,
    String eventType,
  ) async {
    try {
      final data = await TajiriGraphqlClient.instance.mutate(
        '''
        mutation RecordAdEvent(\$input: RecordAdEventInput!) {
          recordAdEvent(input: \$input)
        }
        ''',
        variables: {
          'input': {
            'campaignId': campaignId.toString(),
            'creativeId': creativeId.toString(),
            'placement': placement,
            'eventType': eventType,
          },
        },
        auth: true,
      );
      return data['recordAdEvent'] == true;
    } catch (_) {
      return false;
    }
  }

  static Future<bool> reportAdMobRevenue(
    int userId,
    String placement,
    double revenue,
  ) async {
    try {
      final data = await TajiriGraphqlClient.instance.mutate(
        '''
        mutation ReportAdMobRevenue(\$input: ReportAdMobRevenueInput!) {
          reportAdmobRevenue(input: \$input)
        }
        ''',
        variables: {
          'input': {
            'placement': placement,
            'revenue': revenue,
            'referenceId': 'admob_${DateTime.now().millisecondsSinceEpoch}',
          },
        },
        auth: true,
      );
      return data['reportAdmobRevenue'] == true;
    } catch (_) {
      return false;
    }
  }

  static Future<List<AdCampaign>> getCampaigns() async {
    try {
      final data = await TajiriGraphqlClient.instance.query(
        '''
        query MyAdCampaigns {
          myAdCampaigns {
            $_campaignFields
          }
        }
        ''',
        auth: true,
      );
      return (data['myAdCampaigns'] as List? ?? []).map((row) {
        return AdCampaign.fromJson(_campaignToLegacy(row as Map<String, dynamic>));
      }).toList();
    } catch (_) {
      return [];
    }
  }

  static Future<AdCampaign?> createCampaign(Map<String, dynamic> data) async {
    try {
      final result = await TajiriGraphqlClient.instance.mutate(
        '''
        mutation CreateAdCampaign(\$input: CreateAdCampaignInput!) {
          createAdCampaign(input: \$input) {
            $_campaignFields
          }
        }
        ''',
        variables: {'input': _createCampaignInput(data)},
        auth: true,
      );
      final row = result['createAdCampaign'] as Map<String, dynamic>?;
      if (row == null) return null;
      return AdCampaign.fromJson(_campaignToLegacy(row));
    } catch (_) {
      return null;
    }
  }

  static Future<AdCampaign?> getCampaign(int id) async {
    try {
      final data = await TajiriGraphqlClient.instance.query(
        '''
        query AdCampaign(\$id: ID!) {
          adCampaign(id: \$id) {
            $_campaignFields
          }
        }
        ''',
        variables: {'id': id.toString()},
        auth: true,
      );
      final row = data['adCampaign'] as Map<String, dynamic>?;
      if (row == null) return null;
      return AdCampaign.fromJson(_campaignToLegacy(row));
    } catch (_) {
      return null;
    }
  }

  static Future<AdCampaign?> updateCampaign(
    int id,
    Map<String, dynamic> data,
  ) async {
    try {
      final result = await TajiriGraphqlClient.instance.mutate(
        '''
        mutation UpdateAdCampaign(\$campaignId: ID!, \$input: UpdateAdCampaignInput!) {
          updateAdCampaign(campaignId: \$campaignId, input: \$input) {
            $_campaignFields
          }
        }
        ''',
        variables: {
          'campaignId': id.toString(),
          'input': _updateCampaignInput(data),
        },
        auth: true,
      );
      final row = result['updateAdCampaign'] as Map<String, dynamic>?;
      if (row == null) return null;
      return AdCampaign.fromJson(_campaignToLegacy(row));
    } catch (_) {
      return null;
    }
  }

  static Future<AdCreative?> uploadCreative(
    int campaignId,
    Map<String, dynamic> data,
  ) async {
    try {
      final result = await TajiriGraphqlClient.instance.mutate(
        '''
        mutation AddAdCreative(\$campaignId: ID!, \$input: AddAdCreativeInput!) {
          addAdCreative(campaignId: \$campaignId, input: \$input) {
            $_creativeFields
          }
        }
        ''',
        variables: {
          'campaignId': campaignId.toString(),
          'input': {
            'format': data['format'] ?? 'image',
            if (data['media_url'] != null) 'mediaUrl': data['media_url'],
            if (data['mediaUrl'] != null) 'mediaUrl': data['mediaUrl'],
            'headline': data['headline'] ?? '',
            if (data['body_text'] != null) 'bodyText': data['body_text'],
            if (data['bodyText'] != null) 'bodyText': data['bodyText'],
            'ctaType': data['cta_type'] ?? data['ctaType'] ?? 'learn_more',
            'ctaUrl': data['cta_url'] ?? data['ctaUrl'] ?? '',
            if (data['product_id'] != null)
              'productId': data['product_id'].toString(),
            if (data['productId'] != null)
              'productId': data['productId'].toString(),
          },
        },
        auth: true,
      );
      final row = result['addAdCreative'] as Map<String, dynamic>?;
      if (row == null) return null;
      return AdCreative.fromJson(_creativeToLegacy(row));
    } catch (_) {
      return null;
    }
  }

  static Future<bool> submitCampaign(int id) async =>
      _campaignAction('submitAdCampaign', id);

  static Future<bool> pauseCampaign(int id) async =>
      _campaignAction('pauseAdCampaign', id);

  static Future<bool> resumeCampaign(int id) async =>
      _campaignAction('resumeAdCampaign', id);

  static Future<bool> cancelCampaign(int id) async =>
      _campaignAction('cancelAdCampaign', id);

  static Future<bool> _campaignAction(String mutationName, int id) async {
    try {
      final data = await TajiriGraphqlClient.instance.mutate(
        '''
        mutation ${mutationName[0].toUpperCase()}${mutationName.substring(1)}(\$campaignId: ID!) {
          $mutationName(campaignId: \$campaignId) { id }
        }
        ''',
        variables: {'campaignId': id.toString()},
        auth: true,
      );
      return data[mutationName] != null;
    } catch (_) {
      return false;
    }
  }

  static Future<AdPerformance?> getCampaignPerformance(int id) async {
    try {
      final data = await TajiriGraphqlClient.instance.query(
        '''
        query AdCampaignPerformance(\$campaignId: ID!) {
          adCampaignPerformance(campaignId: \$campaignId) {
            totalImpressions
            totalClicks
            ctr
            totalSpend
            dailyStats {
              date
              impressions
              clicks
              spend
            }
          }
        }
        ''',
        variables: {'campaignId': id.toString()},
        auth: true,
      );
      final row = data['adCampaignPerformance'] as Map<String, dynamic>?;
      if (row == null) return null;
      return AdPerformance.fromJson({
        'total_impressions': row['totalImpressions'],
        'total_clicks': row['totalClicks'],
        'ctr': row['ctr'],
        'total_spend': row['totalSpend'],
        'daily_stats': (row['dailyStats'] as List? ?? []).map((item) {
          final stat = item as Map<String, dynamic>;
          return {
            'date': stat['date'],
            'impressions': stat['impressions'],
            'clicks': stat['clicks'],
            'spend': stat['spend'],
          };
        }).toList(),
      });
    } catch (_) {
      return null;
    }
  }

  static Future<double> getAdBalance() async {
    try {
      final data = await TajiriGraphqlClient.instance.query(
        '''
        query MyAdBalance {
          myAdBalance { adBalance }
        }
        ''',
        auth: true,
      );
      final row = data['myAdBalance'] as Map<String, dynamic>?;
      return (row?['adBalance'] as num?)?.toDouble() ?? 0.0;
    } catch (_) {
      return 0.0;
    }
  }

  static Future<Map<String, dynamic>> depositAdBalance(double amount) async {
    try {
      final result = await TajiriGraphqlClient.instance.mutate(
        '''
        mutation DepositAdBalance(\$input: DepositAdBalanceInput!) {
          depositAdBalance(input: \$input) {
            success
            adBalance
            walletBalance
            message
          }
        }
        ''',
        variables: {
          'input': {
            'amount': amount,
            'idempotencyKey':
                'ad_deposit_${DateTime.now().millisecondsSinceEpoch}',
          },
        },
        auth: true,
      );
      final row = result['depositAdBalance'] as Map<String, dynamic>?;
      if (row == null) {
        return {'success': false, 'message': 'Deposit failed'};
      }
      return {
        'success': row['success'] == true,
        'data': {
          'ad_balance': row['adBalance'],
          'wallet_balance': row['walletBalance'],
        },
        if (row['message'] != null) 'message': row['message'],
      };
    } catch (e) {
      return {'success': false, 'message': e.toString()};
    }
  }

  static Future<Map<String, dynamic>> getClientSettings() async {
    try {
      final data = await TajiriGraphqlClient.instance.query(
        '''
        query AdClientSettings {
          adClientSettings
        }
        ''',
        auth: true,
      );
      final raw = data['adClientSettings'];
      if (raw is Map<String, dynamic>) return raw;
      return {};
    } catch (_) {
      return {};
    }
  }
}
