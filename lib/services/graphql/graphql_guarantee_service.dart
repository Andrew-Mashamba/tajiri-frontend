import 'tajiri_graphql_client.dart';

/// GraphQL service guarantee policies (Phase 62).
class GraphqlGuaranteeService {
  static const _policyFields = r'''
    id
    partnerUserId
    skillCategory
    premiumTzsMonthly
    coverageTzs
    deductibleTzs
    status
    createdAt
  ''';

  static const _claimFields = r'''
    id
    policyId
    customerUserId
    reason
    description
    amountClaimedTzs
    photos
    status
    createdAt
  ''';

  static Map<String, dynamic> _policyToLegacy(Map<String, dynamic> row) {
    return {
      'id': int.parse(row['id'].toString()),
      'partner_user_id': int.parse(row['partnerUserId'].toString()),
      'skill_category': row['skillCategory'],
      'premium_tzs_monthly': row['premiumTzsMonthly'],
      'coverage_tzs': row['coverageTzs'],
      'deductible_tzs': row['deductibleTzs'],
      'status': row['status'],
      'created_at': row['createdAt'],
    };
  }

  static Map<String, dynamic> _claimToLegacy(Map<String, dynamic> row) {
    return {
      'id': int.parse(row['id'].toString()),
      'policy_id': int.parse(row['policyId'].toString()),
      'customer_user_id': int.parse(row['customerUserId'].toString()),
      'reason': row['reason'],
      'description': row['description'],
      'amount_claimed_tzs': row['amountClaimedTzs'],
      'photos': row['photos'] ?? [],
      'status': row['status'],
      'created_at': row['createdAt'],
    };
  }

  static Future<({
    bool success,
    Map<String, dynamic>? policy,
    String? message,
  })> createPolicy({
    String? skillCategory,
    int premiumTzsMonthly = 15000,
    int coverageTzs = 500000,
    int deductibleTzs = 25000,
  }) async {
    try {
      final data = await TajiriGraphqlClient.instance.mutate(
        '''
        mutation CreateGuaranteePolicy(\$input: CreateGuaranteePolicyInput!) {
          createGuaranteePolicy(input: \$input) {
            $_policyFields
          }
        }
        ''',
        variables: {
          'input': {
            if (skillCategory != null) 'skillCategory': skillCategory,
            'premiumTzsMonthly': premiumTzsMonthly,
            'coverageTzs': coverageTzs,
            'deductibleTzs': deductibleTzs,
          },
        },
        auth: true,
      );
      final row = data['createGuaranteePolicy'] as Map<String, dynamic>;
      return (
        success: true,
        policy: _policyToLegacy(row),
        message: null,
      );
    } catch (e) {
      return (success: false, policy: null, message: 'Error: $e');
    }
  }

  static Future<({
    bool success,
    Map<String, dynamic>? policy,
    String? message,
  })> listPolicies() async {
    try {
      final data = await TajiriGraphqlClient.instance.query(
        '''
        query MyGuaranteePolicies {
          myGuaranteePolicies {
            $_policyFields
          }
        }
        ''',
        auth: true,
      );
      final rows = data['myGuaranteePolicies'] as List<dynamic>? ?? [];
      return (
        success: true,
        policy: rows.isNotEmpty
            ? _policyToLegacy(rows.first as Map<String, dynamic>)
            : null,
        message: null,
      );
    } catch (e) {
      return (success: false, policy: null, message: 'Error: $e');
    }
  }

  static Future<({
    bool success,
    Map<String, dynamic>? claim,
    String? message,
  })> fileClaim({
    required int policyId,
    required String reason,
    required String description,
    int amountClaimedTzs = 0,
    List<String> photos = const [],
  }) async {
    try {
      final data = await TajiriGraphqlClient.instance.mutate(
        '''
        mutation FileGuaranteeClaim(\$policyId: ID!, \$input: FileGuaranteeClaimInput!) {
          fileGuaranteeClaim(policyId: \$policyId, input: \$input) {
            $_claimFields
          }
        }
        ''',
        variables: {
          'policyId': policyId.toString(),
          'input': {
            'reason': reason,
            'description': description,
            'amountClaimedTzs': amountClaimedTzs,
            'photos': photos,
          },
        },
        auth: true,
      );
      final row = data['fileGuaranteeClaim'] as Map<String, dynamic>;
      return (
        success: true,
        claim: _claimToLegacy(row),
        message: null,
      );
    } catch (e) {
      return (success: false, claim: null, message: 'Error: $e');
    }
  }
}
