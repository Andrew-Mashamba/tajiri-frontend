import 'tajiri_graphql_client.dart';

/// GraphQL business revenue and income summary (Phase 48).
class GraphqlRevenueService {
  static String _periodWire(String scope) {
    switch (scope) {
      case 'all':
        return 'all';
      case 'this_month':
        return 'this_month';
      case 'last_30_days':
        return 'last_30_days';
      default:
        return 'this_month';
    }
  }

  static Future<Map<String, dynamic>?> revenueSummary({
    required String period,
    int? businessId,
    bool includeLedgerHint = false,
  }) async {
    try {
      final data = await TajiriGraphqlClient.instance.query(
        '''
        query RevenueSummary(\$period: String!, \$businessId: ID, \$includeLedgerHint: Boolean) {
          revenueSummary(
            period: \$period
            businessId: \$businessId
            includeLedgerHint: \$includeLedgerHint
          )
        }
        ''',
        variables: {
          'period': period,
          'includeLedgerHint': includeLedgerHint,
          if (businessId != null) 'businessId': businessId.toString(),
        },
        auth: true,
      );
      final row = data['revenueSummary'];
      if (row is Map<String, dynamic>) return row;
      return null;
    } catch (_) {
      return null;
    }
  }

  static Future<Map<String, dynamic>?> businessIncomeSummary({
    required String period,
    int? businessId,
  }) async {
    try {
      final data = await TajiriGraphqlClient.instance.query(
        '''
        query BusinessIncomeSummary(\$period: String!, \$businessId: ID) {
          businessIncomeSummary(period: \$period, businessId: \$businessId)
        }
        ''',
        variables: {
          'period': period,
          if (businessId != null) 'businessId': businessId.toString(),
        },
        auth: true,
      );
      final row = data['businessIncomeSummary'];
      if (row is Map<String, dynamic>) return row;
      return null;
    } catch (_) {
      return null;
    }
  }

  /// Maps [RevenuePeriodScope] enum wire values from revenue_service.dart.
  static String periodFromScope(String scopeName) {
    return _periodWire(scopeName);
  }
}
