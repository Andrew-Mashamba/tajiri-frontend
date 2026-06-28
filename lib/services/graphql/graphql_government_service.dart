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

  static Future<GovtResult<NhifInfo>> lookupNhif({
    required String memberNumber,
  }) async {
    try {
      final data = await TajiriGraphqlClient.instance.query(
        '''
        query LookupNhif(\$memberNumber: String!) {
          lookupNhif(memberNumber: \$memberNumber) {
            memberNumber
            status
          }
        }
        ''',
        variables: {'memberNumber': memberNumber},
        auth: true,
      );
      final row = data['lookupNhif'] as Map<String, dynamic>?;
      if (row == null) {
        return GovtResult(success: false, message: 'Imeshindwa kuthibitisha NHIF');
      }
      return GovtResult(
        success: true,
        data: NhifInfo.fromJson({
          'member_number': row['memberNumber'],
          'status': row['status'],
        }),
      );
    } catch (e) {
      return GovtResult(success: false, message: '$e');
    }
  }

  static Future<GovtResult<NssfInfo>> lookupNssf({
    required String memberNumber,
  }) async {
    try {
      final data = await TajiriGraphqlClient.instance.query(
        '''
        query LookupNssf(\$memberNumber: String!) {
          lookupNssf(memberNumber: \$memberNumber) {
            memberNumber
            status
          }
        }
        ''',
        variables: {'memberNumber': memberNumber},
        auth: true,
      );
      final row = data['lookupNssf'] as Map<String, dynamic>?;
      if (row == null) {
        return GovtResult(success: false, message: 'Imeshindwa kuthibitisha NSSF');
      }
      return GovtResult(
        success: true,
        data: NssfInfo.fromJson({
          'member_number': row['memberNumber'],
          'status': row['status'],
        }),
      );
    } catch (e) {
      return GovtResult(success: false, message: '$e');
    }
  }

  static Future<GovtListResult<BrelaInfo>> searchBrela({
    required String businessName,
  }) async {
    try {
      final data = await TajiriGraphqlClient.instance.query(
        '''
        query SearchBrela(\$businessName: String!) {
          searchBrela(businessName: \$businessName) {
            businessName
            status
          }
        }
        ''',
        variables: {'businessName': businessName},
        auth: true,
      );
      final rows = data['searchBrela'] as List<dynamic>? ?? [];
      final items = rows
          .whereType<Map<String, dynamic>>()
          .map(
            (row) => BrelaInfo.fromJson({
              'business_name': row['businessName'],
              'status': row['status'],
            }),
          )
          .toList();
      return GovtListResult(success: true, items: items);
    } catch (e) {
      return GovtListResult(success: false, message: '$e');
    }
  }

  static Future<GovtResult<Map<String, dynamic>>> calculateNssfContribution({
    required double monthlySalary,
    required int years,
  }) async {
    try {
      final data = await TajiriGraphqlClient.instance.query(
        '''
        query CalculateNssfContribution(\$monthlySalary: Float!, \$years: Int!) {
          calculateNssfContribution(monthlySalary: \$monthlySalary, years: \$years) {
            employeeContribution
            employerContribution
            totalMonthly
            totalProjected
          }
        }
        ''',
        variables: {
          'monthlySalary': monthlySalary,
          'years': years,
        },
        auth: false,
      );
      final row = data['calculateNssfContribution'] as Map<String, dynamic>?;
      if (row == null) {
        return GovtResult(success: false, message: 'Imeshindwa kuhesabu');
      }
      return GovtResult(
        success: true,
        data: {
          'employee_contribution': row['employeeContribution'],
          'employer_contribution': row['employerContribution'],
          'total_monthly': row['totalMonthly'],
          'total_projected': row['totalProjected'],
        },
      );
    } catch (e) {
      return GovtResult(success: false, message: '$e');
    }
  }
}
