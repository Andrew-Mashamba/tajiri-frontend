import 'tajiri_graphql_client.dart';

/// GraphQL creator income sources (Phase 46).
class GraphqlIncomeSourcesService {
  static Future<Map<String, dynamic>?> getSources({
    String period = 'month',
  }) async {
    try {
      final data = await TajiriGraphqlClient.instance.query(
        '''
        query MyIncomeSources(\$period: String) {
          myIncomeSources(period: \$period)
        }
        ''',
        variables: {'period': period},
        auth: true,
      );
      final row = data['myIncomeSources'];
      if (row is Map<String, dynamic>) return row;
      return null;
    } catch (_) {
      return null;
    }
  }

  static Future<Map<String, dynamic>?> getSourceDetail({
    required String sourceId,
    String period = 'month',
  }) async {
    try {
      final data = await TajiriGraphqlClient.instance.query(
        '''
        query MyIncomeSource(\$sourceId: String!, \$period: String) {
          myIncomeSource(sourceId: \$sourceId, period: \$period)
        }
        ''',
        variables: {'sourceId': sourceId, 'period': period},
        auth: true,
      );
      final row = data['myIncomeSource'];
      if (row is Map<String, dynamic>) return row;
      return null;
    } catch (_) {
      return null;
    }
  }

  static Future<Map<String, dynamic>?> getHistory({
    required String sourceId,
    String? cursor,
    int limit = 20,
  }) async {
    try {
      final data = await TajiriGraphqlClient.instance.query(
        '''
        query MyIncomeSourceHistory(\$sourceId: String!, \$cursor: String, \$limit: Int) {
          myIncomeSourceHistory(sourceId: \$sourceId, cursor: \$cursor, limit: \$limit)
        }
        ''',
        variables: {
          'sourceId': sourceId,
          'limit': limit,
          if (cursor != null) 'cursor': cursor,
        },
        auth: true,
      );
      final row = data['myIncomeSourceHistory'];
      if (row is Map<String, dynamic>) return row;
      return null;
    } catch (_) {
      return null;
    }
  }

  static Future<Map<String, dynamic>?> activateSource(String sourceId) async {
    try {
      final result = await TajiriGraphqlClient.instance.mutate(
        '''
        mutation ActivateIncomeSource(\$sourceId: String!) {
          activateIncomeSource(sourceId: \$sourceId)
        }
        ''',
        variables: {'sourceId': sourceId},
        auth: true,
      );
      final row = result['activateIncomeSource'];
      if (row is Map<String, dynamic>) return row;
      return null;
    } catch (_) {
      return null;
    }
  }

  static Future<bool> updateSettings(
    String sourceId,
    Map<String, dynamic> settings,
  ) async {
    try {
      final result = await TajiriGraphqlClient.instance.mutate(
        '''
        mutation UpdateIncomeSourceSettings(\$sourceId: String!, \$settings: JSON!) {
          updateIncomeSourceSettings(sourceId: \$sourceId, settings: \$settings)
        }
        ''',
        variables: {'sourceId': sourceId, 'settings': settings},
        auth: true,
      );
      return result['updateIncomeSourceSettings'] == true;
    } catch (_) {
      return false;
    }
  }

  static Future<bool> notifyOnUnlock(String sourceId) async {
    try {
      final result = await TajiriGraphqlClient.instance.mutate(
        '''
        mutation NotifyOnIncomeSourceUnlock(\$sourceId: String!) {
          notifyOnIncomeSourceUnlock(sourceId: \$sourceId)
        }
        ''',
        variables: {'sourceId': sourceId},
        auth: true,
      );
      return result['notifyOnIncomeSourceUnlock'] == true;
    } catch (_) {
      return false;
    }
  }
}
