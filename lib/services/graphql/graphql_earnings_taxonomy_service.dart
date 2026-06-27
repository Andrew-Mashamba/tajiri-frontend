import 'tajiri_graphql_client.dart';

/// GraphQL earnings UI taxonomy (Phase 44).
class GraphqlEarningsTaxonomyService {
  static Future<Map<String, dynamic>?> fetch() async {
    try {
      final data = await TajiriGraphqlClient.instance.query(
        '''
        query EarningsTaxonomy {
          earningsTaxonomy
        }
        ''',
        auth: false,
      );
      final row = data['earningsTaxonomy'];
      if (row is Map<String, dynamic>) return row;
      return null;
    } catch (_) {
      return null;
    }
  }
}
