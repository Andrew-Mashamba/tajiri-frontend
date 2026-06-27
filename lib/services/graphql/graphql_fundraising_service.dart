import '../models/contribution_models.dart';
import 'tajiri_graphql_client.dart';

/// GraphQL fundraising / michango campaigns (Phase 35).
class GraphqlFundraisingService {
  static const _campaignFields = r'''
    id
    userId
    title
    story
    shortDescription
    goalAmount
    raisedAmount
    currency
    status
    category
    isVerified
    deadline
    coverImageUrl
    mediaUrls
    donorsCount
    sharesCount
    viewsCount
    allowAnonymousDonations
    minimumDonation
    isUrgent
    bankName
    accountNumber
    mobileMoneyNumber
    createdAt
    updatedAt
    organizer {
      id
      fullName
      avatarUrl
      isVerified
      kycStatus
    }
    updates {
      id
      campaignId
      content
      mediaUrls
      createdAt
    }
  ''';

  static int _parseInt(dynamic v) =>
      v is int ? v : int.tryParse(v?.toString() ?? '') ?? 0;

  static Map<String, dynamic> _campaignToLegacy(Map<String, dynamic> row) {
    final organizer = row['organizer'] as Map<String, dynamic>?;
    return {
      'id': _parseInt(row['id']),
      'user_id': _parseInt(row['userId']),
      'title': row['title'],
      'story': row['story'],
      'short_description': row['shortDescription'],
      'goal_amount': (row['goalAmount'] as num).toDouble(),
      'raised_amount': (row['raisedAmount'] as num?)?.toDouble() ?? 0,
      'currency': row['currency'] ?? 'TZS',
      'status': row['status'],
      'category': row['category'],
      'is_verified': row['isVerified'] == true,
      'deadline': row['deadline'],
      'cover_image_url': row['coverImageUrl'],
      'media_urls': row['mediaUrls'] ?? [],
      'donors_count': row['donorsCount'] ?? 0,
      'shares_count': row['sharesCount'] ?? 0,
      'views_count': row['viewsCount'] ?? 0,
      'allow_anonymous_donations': row['allowAnonymousDonations'] == true,
      'minimum_donation': (row['minimumDonation'] as num?)?.toDouble() ?? 1000,
      'is_urgent': row['isUrgent'] == true,
      'bank_name': row['bankName'],
      'account_number': row['accountNumber'],
      'mobile_money_number': row['mobileMoneyNumber'],
      'created_at': row['createdAt'],
      'updated_at': row['updatedAt'],
      if (organizer != null)
        'organizer': {
          'id': _parseInt(organizer['id']),
          'full_name': organizer['fullName'],
          'avatar_url': organizer['avatarUrl'],
          'is_verified': organizer['isVerified'] == true,
          'kyc_status': organizer['kycStatus'],
        },
      'updates': (row['updates'] as List? ?? []).map((u) {
        final update = u as Map<String, dynamic>;
        return {
          'id': _parseInt(update['id']),
          'campaign_id': _parseInt(update['campaignId']),
          'content': update['content'],
          'media_urls': update['mediaUrls'] ?? [],
          'created_at': update['createdAt'],
        };
      }).toList(),
    };
  }

  static Future<List<Campaign>> getUserCampaigns({String? status}) async {
    try {
      final data = await TajiriGraphqlClient.instance.query(
        '''
        query MyFundraisingCampaigns(\$status: String) {
          myFundraisingCampaigns(status: \$status) {
            $_campaignFields
          }
        }
        ''',
        variables: {if (status != null) 'status': status},
        auth: true,
      );
      return (data['myFundraisingCampaigns'] as List? ?? []).map((row) {
        return Campaign.fromJson(_campaignToLegacy(row as Map<String, dynamic>));
      }).toList();
    } catch (_) {
      return [];
    }
  }

  static Future<CampaignStats?> getUserCampaignStats() async {
    try {
      final data = await TajiriGraphqlClient.instance.query(
        '''
        query MyFundraisingCampaignStats {
          myFundraisingCampaignStats {
            totalCampaigns
            activeCampaigns
            completedCampaigns
            totalRaised
            totalWithdrawn
            availableBalance
            totalDonors
            totalDonations
          }
        }
        ''',
        auth: true,
      );
      final row = data['myFundraisingCampaignStats'] as Map<String, dynamic>?;
      if (row == null) return null;
      return CampaignStats.fromJson({
        'total_campaigns': row['totalCampaigns'],
        'active_campaigns': row['activeCampaigns'],
        'completed_campaigns': row['completedCampaigns'],
        'total_raised': row['totalRaised'],
        'total_withdrawn': row['totalWithdrawn'],
        'available_balance': row['availableBalance'],
        'total_donors': row['totalDonors'],
        'total_donations': row['totalDonations'],
      });
    } catch (_) {
      return null;
    }
  }

  static Future<Campaign?> getCampaign(int campaignId) async {
    try {
      final data = await TajiriGraphqlClient.instance.query(
        '''
        query FundraisingCampaign(\$id: ID!) {
          fundraisingCampaign(id: \$id) {
            $_campaignFields
          }
        }
        ''',
        variables: {'id': campaignId.toString()},
        auth: true,
      );
      final row = data['fundraisingCampaign'] as Map<String, dynamic>?;
      if (row == null) return null;
      return Campaign.fromJson(_campaignToLegacy(row));
    } catch (_) {
      return null;
    }
  }

  static Future<Campaign?> createCampaign(Map<String, dynamic> fields) async {
    try {
      final result = await TajiriGraphqlClient.instance.mutate(
        '''
        mutation CreateFundraisingCampaign(\$input: CreateFundraisingCampaignInput!) {
          createFundraisingCampaign(input: \$input) {
            $_campaignFields
          }
        }
        ''',
        variables: {
          'input': {
            'title': fields['title'],
            'story': fields['story'],
            if (fields['short_description'] != null)
              'shortDescription': fields['short_description'],
            'goalAmount': fields['goal_amount'] ?? fields['goalAmount'],
            'category': fields['category'] ?? 'other',
            if (fields['deadline'] != null) 'deadline': fields['deadline'],
            if (fields['cover_image_url'] != null)
              'coverImageUrl': fields['cover_image_url'],
            if (fields['media_urls'] != null) 'mediaUrls': fields['media_urls'],
            'allowAnonymousDonations':
                fields['allow_anonymous_donations'] ?? true,
            'minimumDonation': fields['minimum_donation'] ?? 1000,
            'isUrgent': fields['is_urgent'] ?? false,
            if (fields['bank_name'] != null) 'bankName': fields['bank_name'],
            if (fields['account_number'] != null)
              'accountNumber': fields['account_number'],
            if (fields['mobile_money_number'] != null)
              'mobileMoneyNumber': fields['mobile_money_number'],
          },
        },
        auth: true,
      );
      final row = result['createFundraisingCampaign'] as Map<String, dynamic>?;
      if (row == null) return null;
      return Campaign.fromJson(_campaignToLegacy(row));
    } catch (_) {
      return null;
    }
  }

  static Future<Campaign?> _campaignAction(String mutation, int campaignId) async {
    try {
      final result = await TajiriGraphqlClient.instance.mutate(
        '''
        mutation ${mutation[0].toUpperCase()}${mutation.substring(1)}(\$campaignId: ID!) {
          $mutation(campaignId: \$campaignId) {
            $_campaignFields
          }
        }
        ''',
        variables: {'campaignId': campaignId.toString()},
        auth: true,
      );
      final row = result[mutation] as Map<String, dynamic>?;
      if (row == null) return null;
      return Campaign.fromJson(_campaignToLegacy(row));
    } catch (_) {
      return null;
    }
  }

  static Future<Campaign?> publishCampaign(int id) =>
      _campaignAction('publishFundraisingCampaign', id);

  static Future<Campaign?> pauseCampaign(int id) =>
      _campaignAction('pauseFundraisingCampaign', id);

  static Future<Campaign?> resumeCampaign(int id) =>
      _campaignAction('resumeFundraisingCampaign', id);

  static Future<Campaign?> completeCampaign(int id) =>
      _campaignAction('completeFundraisingCampaign', id);

  static Future<bool> deleteCampaign(int id) async {
    try {
      final result = await TajiriGraphqlClient.instance.mutate(
        '''
        mutation DeleteFundraisingCampaign(\$campaignId: ID!) {
          deleteFundraisingCampaign(campaignId: \$campaignId)
        }
        ''',
        variables: {'campaignId': id.toString()},
        auth: true,
      );
      return result['deleteFundraisingCampaign'] == true;
    } catch (_) {
      return false;
    }
  }

  static Future<CampaignUpdate?> postCampaignUpdate(
    int campaignId,
    String content, {
    List<String>? mediaUrls,
  }) async {
    try {
      final result = await TajiriGraphqlClient.instance.mutate(
        '''
        mutation PostFundraisingCampaignUpdate(\$campaignId: ID!, \$input: PostFundraisingCampaignUpdateInput!) {
          postFundraisingCampaignUpdate(campaignId: \$campaignId, input: \$input) {
            id
            campaignId
            content
            mediaUrls
            createdAt
          }
        }
        ''',
        variables: {
          'campaignId': campaignId.toString(),
          'input': {
            'content': content,
            if (mediaUrls != null) 'mediaUrls': mediaUrls,
          },
        },
        auth: true,
      );
      final row = result['postFundraisingCampaignUpdate'] as Map<String, dynamic>?;
      if (row == null) return null;
      return CampaignUpdate.fromJson({
        'id': _parseInt(row['id']),
        'campaign_id': _parseInt(row['campaignId']),
        'content': row['content'],
        'media_urls': row['mediaUrls'] ?? [],
        'created_at': row['createdAt'],
      });
    } catch (_) {
      return null;
    }
  }

  static Future<List<CampaignUpdate>> getCampaignUpdates(int campaignId) async {
    try {
      final data = await TajiriGraphqlClient.instance.query(
        '''
        query FundraisingCampaignUpdates(\$campaignId: ID!) {
          fundraisingCampaignUpdates(campaignId: \$campaignId) {
            id
            campaignId
            content
            mediaUrls
            createdAt
          }
        }
        ''',
        variables: {'campaignId': campaignId.toString()},
        auth: true,
      );
      return (data['fundraisingCampaignUpdates'] as List? ?? []).map((row) {
        final item = row as Map<String, dynamic>;
        return CampaignUpdate.fromJson({
          'id': _parseInt(item['id']),
          'campaign_id': _parseInt(item['campaignId']),
          'content': item['content'],
          'media_urls': item['mediaUrls'] ?? [],
          'created_at': item['createdAt'],
        });
      }).toList();
    } catch (_) {
      return [];
    }
  }

  static Future<Donation?> donateToCampaign(
    int campaignId, {
    required double amount,
    required String paymentMethod,
    String? message,
    bool isAnonymous = false,
    String? pin,
  }) async {
    try {
      final result = await TajiriGraphqlClient.instance.mutate(
        '''
        mutation DonateToFundraisingCampaign(\$input: DonateToFundraisingCampaignInput!) {
          donateToFundraisingCampaign(input: \$input) {
            id
            campaignId
            donorId
            amount
            currency
            isAnonymous
            message
            donorName
            donorAvatarUrl
            paymentRef
            status
            createdAt
          }
        }
        ''',
        variables: {
          'input': {
            'campaignId': campaignId.toString(),
            'amount': amount,
            'paymentMethod': paymentMethod,
            if (pin != null) 'pin': pin,
            if (message != null) 'message': message,
            'isAnonymous': isAnonymous,
            'idempotencyKey':
                'donate_${campaignId}_${DateTime.now().millisecondsSinceEpoch}',
          },
        },
        auth: true,
      );
      final row = result['donateToFundraisingCampaign'] as Map<String, dynamic>?;
      if (row == null) return null;
      return Donation.fromJson({
        'id': _parseInt(row['id']),
        'campaign_id': _parseInt(row['campaignId']),
        'donor_id': row['donorId'] != null ? _parseInt(row['donorId']) : null,
        'amount': (row['amount'] as num).toDouble(),
        'currency': row['currency'] ?? 'TZS',
        'is_anonymous': row['isAnonymous'] == true,
        'message': row['message'],
        'donor_name': row['donorName'],
        'donor_avatar_url': row['donorAvatarUrl'],
        'payment_ref': row['paymentRef'],
        'status': row['status'],
        'created_at': row['createdAt'],
      });
    } catch (_) {
      return null;
    }
  }

  static Future<List<Donation>> getCampaignDonations(int campaignId) async {
    try {
      final data = await TajiriGraphqlClient.instance.query(
        '''
        query FundraisingCampaignDonations(\$campaignId: ID!) {
          fundraisingCampaignDonations(campaignId: \$campaignId) {
            items {
              id
              campaignId
              donorId
              amount
              currency
              isAnonymous
              message
              donorName
              donorAvatarUrl
              paymentRef
              status
              createdAt
            }
          }
        }
        ''',
        variables: {'campaignId': campaignId.toString()},
        auth: true,
      );
      final page = data['fundraisingCampaignDonations'] as Map<String, dynamic>?;
      return (page?['items'] as List? ?? []).map((row) {
        final item = row as Map<String, dynamic>;
        return Donation.fromJson({
          'id': _parseInt(item['id']),
          'campaign_id': _parseInt(item['campaignId']),
          'donor_id': item['donorId'] != null ? _parseInt(item['donorId']) : null,
          'amount': (item['amount'] as num).toDouble(),
          'currency': item['currency'] ?? 'TZS',
          'is_anonymous': item['isAnonymous'] == true,
          'message': item['message'],
          'donor_name': item['donorName'],
          'donor_avatar_url': item['donorAvatarUrl'],
          'payment_ref': item['paymentRef'],
          'status': item['status'],
          'created_at': item['createdAt'],
        });
      }).toList();
    } catch (_) {
      return [];
    }
  }

  static Future<List<Withdrawal>> getCampaignWithdrawals(int campaignId) async {
    try {
      final data = await TajiriGraphqlClient.instance.query(
        '''
        query FundraisingCampaignWithdrawals(\$campaignId: ID!) {
          fundraisingCampaignWithdrawals(campaignId: \$campaignId) {
            id
            campaignId
            amount
            currency
            status
            destinationType
            destinationDetails
            rejectionReason
            createdAt
            processedAt
          }
        }
        ''',
        variables: {'campaignId': campaignId.toString()},
        auth: true,
      );
      return (data['fundraisingCampaignWithdrawals'] as List? ?? []).map((row) {
        final item = row as Map<String, dynamic>;
        return Withdrawal.fromJson({
          'id': _parseInt(item['id']),
          'campaign_id': _parseInt(item['campaignId']),
          'amount': (item['amount'] as num).toDouble(),
          'currency': item['currency'] ?? 'TZS',
          'status': item['status'],
          'destination_type': item['destinationType'],
          'destination_details': item['destinationDetails'],
          'rejection_reason': item['rejectionReason'],
          'created_at': item['createdAt'],
          'processed_at': item['processedAt'],
        });
      }).toList();
    } catch (_) {
      return [];
    }
  }

  static Future<Withdrawal?> requestWithdrawal(
    int campaignId, {
    required double amount,
    required String destinationType,
    required String destinationDetails,
  }) async {
    try {
      final result = await TajiriGraphqlClient.instance.mutate(
        '''
        mutation RequestFundraisingWithdrawal(\$input: RequestFundraisingWithdrawalInput!) {
          requestFundraisingWithdrawal(input: \$input) {
            id
            campaignId
            amount
            currency
            status
            destinationType
            destinationDetails
            rejectionReason
            createdAt
            processedAt
          }
        }
        ''',
        variables: {
          'input': {
            'campaignId': campaignId.toString(),
            'amount': amount,
            'destinationType': destinationType,
            'destinationDetails': destinationDetails,
            'idempotencyKey':
                'withdraw_${campaignId}_${DateTime.now().millisecondsSinceEpoch}',
          },
        },
        auth: true,
      );
      final row = result['requestFundraisingWithdrawal'] as Map<String, dynamic>?;
      if (row == null) return null;
      return Withdrawal.fromJson({
        'id': _parseInt(row['id']),
        'campaign_id': _parseInt(row['campaignId']),
        'amount': (row['amount'] as num).toDouble(),
        'currency': row['currency'] ?? 'TZS',
        'status': row['status'],
        'destination_type': row['destinationType'],
        'destination_details': row['destinationDetails'],
        'rejection_reason': row['rejectionReason'],
        'created_at': row['createdAt'],
        'processed_at': row['processedAt'],
      });
    } catch (_) {
      return null;
    }
  }

  static Future<List<Withdrawal>> getUserWithdrawals() async {
    try {
      final data = await TajiriGraphqlClient.instance.query(
        '''
        query MyFundraisingWithdrawals {
          myFundraisingWithdrawals {
            id
            campaignId
            amount
            currency
            status
            destinationType
            destinationDetails
            rejectionReason
            createdAt
            processedAt
          }
        }
        ''',
        auth: true,
      );
      return (data['myFundraisingWithdrawals'] as List? ?? []).map((row) {
        final item = row as Map<String, dynamic>;
        return Withdrawal.fromJson({
          'id': _parseInt(item['id']),
          'campaign_id': _parseInt(item['campaignId']),
          'amount': (item['amount'] as num).toDouble(),
          'currency': item['currency'] ?? 'TZS',
          'status': item['status'],
          'destination_type': item['destinationType'],
          'destination_details': item['destinationDetails'],
          'rejection_reason': item['rejectionReason'],
          'created_at': item['createdAt'],
          'processed_at': item['processedAt'],
        });
      }).toList();
    } catch (_) {
      return [];
    }
  }
}
