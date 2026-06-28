import '../../government/models/government_models.dart';
import 'tajiri_graphql_client.dart';

/// GraphQL government service catalog (Phase 91).
class GraphqlGovernmentService {
  static Map<String, dynamic> _serviceToLegacy(Map<String, dynamic> row) {
    return {
      'id': int.tryParse(row['id']?.toString() ?? '') ?? 0,
      'name': row['name'],
      'description': row['description'] ?? '',
      'icon_name': row['icon'] ?? 'public',
      'category': row['category'],
    };
  }

  static Future<GovtListResult<GovtService>> getServices({
    String? category,
  }) async {
    try {
      final data = await TajiriGraphqlClient.instance.query(
        '''
        query GovernmentServices(\$category: String) {
          governmentServices(category: \$category) {
            id
            category
            name
            description
            icon
            isActive
          }
        }
        ''',
        variables: {
          if (category != null) 'category': category,
        },
        auth: false,
      );
      final rows = data['governmentServices'] as List<dynamic>? ?? [];
      final items = rows
          .whereType<Map<String, dynamic>>()
          .where((row) => row['isActive'] != false)
          .map((row) => GovtService.fromJson(_serviceToLegacy(row)))
          .toList();
      return GovtListResult(success: true, items: items);
    } catch (e) {
      return GovtListResult(
        success: false,
        message: 'Imeshindwa kupakia huduma: $e',
      );
    }
  }

  static Future<GovtResult<NidaInfo>> lookupNida({
    required String nidaNumber,
  }) async {
    try {
      final data = await TajiriGraphqlClient.instance.query(
        '''
        query LookupNida(\$nidaNumber: String!) {
          lookupNida(nidaNumber: \$nidaNumber) {
            number
            status
          }
        }
        ''',
        variables: {'nidaNumber': nidaNumber},
        auth: true,
      );
      final row = data['lookupNida'] as Map<String, dynamic>?;
      if (row == null) {
        return GovtResult(success: false, message: 'Imeshindwa kuthibitisha NIDA');
      }
      return GovtResult(
        success: true,
        data: NidaInfo.fromJson({
          'number': row['number'],
          'status': row['status'],
        }),
      );
    } catch (e) {
      return GovtResult(success: false, message: '$e');
    }
  }

  static Future<GovtResult<TinInfo>> lookupTin({
    required String tinNumber,
  }) async {
    try {
      final data = await TajiriGraphqlClient.instance.query(
        '''
        query LookupTin(\$tinNumber: String!) {
          lookupTin(tinNumber: \$tinNumber) {
            number
            status
          }
        }
        ''',
        variables: {'tinNumber': tinNumber},
        auth: true,
      );
      final row = data['lookupTin'] as Map<String, dynamic>?;
      if (row == null) {
        return GovtResult(success: false, message: 'Imeshindwa kutafuta TIN');
      }
      return GovtResult(
        success: true,
        data: TinInfo.fromJson({
          'number': row['number'],
          'status': row['status'],
        }),
      );
    } catch (e) {
      return GovtResult(success: false, message: '$e');
    }
  }
}
