import '../../shop/seller/models/trust_models.dart';
import 'tajiri_graphql_client.dart';

/// GraphQL seller verification & trust (Phase 21).
class GraphqlVerificationService {
  static const _trustFields = r'''
    nidaVerified
    brelaRegistered
    totalSales
    salesBadge
    responseRate
    responseLabel
    trustLevel
    verificationStatus
  ''';

  static const _statusFields = r'''
    verificationStatus
    nidaVerified
    brelaRegistered
    brelaNumber
    verificationSubmittedAt
    verificationNotes
    trustLevel
  ''';

  static Future<SellerTrustProfile?> getTrustProfile(int sellerId) async {
    try {
      final data = await TajiriGraphqlClient.instance.query(
        '''
        query ShopSellerTrustProfile(\$sellerId: ID!) {
          shopSellerTrustProfile(sellerId: \$sellerId) {
            $_trustFields
          }
        }
        ''',
        variables: {'sellerId': sellerId.toString()},
      );
      final profile = data['shopSellerTrustProfile'] as Map<String, dynamic>?;
      if (profile == null) return null;
      return SellerTrustProfile.fromJson(_trustToLegacy(profile));
    } catch (_) {
      return null;
    }
  }

  static Future<SellerVerificationStatus?> getVerificationStatus() async {
    try {
      final data = await TajiriGraphqlClient.instance.query('''
        query MyShopSellerVerificationStatus {
          myShopSellerVerificationStatus {
            $_statusFields
          }
        }
      ''');
      final status = data['myShopSellerVerificationStatus'] as Map<String, dynamic>?;
      if (status == null) return null;
      return SellerVerificationStatus.fromJson(_statusToLegacy(status));
    } catch (_) {
      return null;
    }
  }

  static Future<bool> submitVerification({
    required String type,
    String? nidaNumber,
    String? brelaNumber,
  }) async {
    try {
      await TajiriGraphqlClient.instance.mutate(
        '''
        mutation SubmitShopSellerVerification(\$input: SubmitShopSellerVerificationInput!) {
          submitShopSellerVerification(input: \$input) {
            verificationStatus
          }
        }
        ''',
        variables: {
          'input': {
            'type': type,
            if (nidaNumber != null && nidaNumber.isNotEmpty) 'nidaNumber': nidaNumber,
            if (brelaNumber != null && brelaNumber.isNotEmpty) 'brelaNumber': brelaNumber,
          },
        },
        auth: true,
      );
      return true;
    } catch (_) {
      return false;
    }
  }

  static Map<String, dynamic> _trustToLegacy(Map<String, dynamic> gql) {
    return {
      'nida_verified': gql['nidaVerified'] ?? false,
      'brela_registered': gql['brelaRegistered'] ?? false,
      'total_sales': gql['totalSales'] ?? 0,
      'sales_badge': gql['salesBadge'],
      'response_rate': gql['responseRate'] ?? 0,
      'response_label': gql['responseLabel'] ?? 'Slow',
      'trust_level': gql['trustLevel'] ?? 'basic',
      'verification_status': gql['verificationStatus'] ?? 'unverified',
    };
  }

  static Map<String, dynamic> _statusToLegacy(Map<String, dynamic> gql) {
    return {
      'verification_status': gql['verificationStatus'] ?? 'unverified',
      'nida_verified': gql['nidaVerified'] ?? false,
      'brela_registered': gql['brelaRegistered'] ?? false,
      'brela_number': gql['brelaNumber'],
      if (gql['verificationSubmittedAt'] != null)
        'verification_submitted_at': gql['verificationSubmittedAt'].toString(),
      'verification_notes': gql['verificationNotes'],
      'trust_level': gql['trustLevel'] ?? 'basic',
    };
  }
}
