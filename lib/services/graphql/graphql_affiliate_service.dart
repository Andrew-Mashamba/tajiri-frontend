import 'affiliate_service.dart' show AffiliateLookup;
import 'tajiri_graphql_client.dart';

/// GraphQL affiliate referral codes (Phase 36).
class GraphqlAffiliateService {
  static Future<String?> getMyCode() async {
    try {
      final data = await TajiriGraphqlClient.instance.query(
        '''
        query MyAffiliateCode {
          myAffiliateCode
        }
        ''',
        auth: true,
      );
      return data['myAffiliateCode'] as String?;
    } catch (_) {
      return null;
    }
  }

  static Future<bool> setMyCode(String? code) async {
    try {
      final result = await TajiriGraphqlClient.instance.mutate(
        '''
        mutation SetAffiliateCode(\$code: String!) {
          setAffiliateCode(code: \$code) {
            success
            codeTaken
          }
        }
        ''',
        variables: {'code': code ?? ''},
        auth: true,
      );
      final row = result['setAffiliateCode'] as Map<String, dynamic>?;
      if (row == null) return false;
      if (row['codeTaken'] == true) throw 'taken';
      return row['success'] == true;
    } catch (e) {
      if (e == 'taken') rethrow;
      return false;
    }
  }

  static Future<AffiliateLookup?> lookup(String code) async {
    try {
      final data = await TajiriGraphqlClient.instance.query(
        '''
        query AffiliateCodeLookup(\$code: String!) {
          affiliateCodeLookup(code: \$code) {
            userId
            name
            username
          }
        }
        ''',
        variables: {'code': code},
        auth: false,
      );
      final row = data['affiliateCodeLookup'] as Map<String, dynamic>?;
      if (row == null) return null;
      return AffiliateLookup.fromJson({
        'user_id': int.parse(row['userId'].toString()),
        'name': row['name'],
        'username': row['username'],
      });
    } catch (_) {
      return null;
    }
  }
}
