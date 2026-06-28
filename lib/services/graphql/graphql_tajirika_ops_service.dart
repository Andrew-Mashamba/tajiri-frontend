import '../../tajirika/services/delivery_fee_service.dart';
import '../../tajirika/services/geofence_service.dart';
import '../../tajirika/services/service_taxonomy_service.dart';
import '../../tajirika/services/tip_pool_service.dart';
import 'tajiri_graphql_client.dart';

/// GraphQL Tajirika ops (Phases 163–166): tip pools, delivery fee, taxonomy, geofence.
class GraphqlTajirikaOpsService {
  static Map<String, dynamic> _tipPoolToLegacy(Map<String, dynamic> row) {
    return {
      'id': int.tryParse(row['id']?.toString() ?? '') ?? 0,
      'partner_user_id': int.tryParse(row['partnerUserId']?.toString() ?? '') ?? 0,
      if (row['skillCategory'] != null) 'skill_category': row['skillCategory'],
      'is_active': row['isActive'] == true,
      'tip_split_type': int.tryParse(row['tipSplitType']?.toString() ?? '') ?? 1,
      'staff_shares': (row['staffShares'] as List<dynamic>? ?? [])
          .whereType<Map<String, dynamic>>()
          .map(
            (s) => {
              'user_id': int.tryParse(s['userId']?.toString() ?? '') ?? 0,
              'name': s['name'] ?? '',
              'share_pct': int.tryParse(s['sharePct']?.toString() ?? '') ?? 0,
            },
          )
          .toList(),
      'distribution_frequency_days':
          int.tryParse(row['distributionFrequencyDays']?.toString() ?? '') ?? 7,
      'min_tip_tzs': int.tryParse(row['minTipTzs']?.toString() ?? '') ?? 0,
    };
  }

  static TipDistributionResult _distributionToLegacy(Map<String, dynamic> row) {
    return TipDistributionResult(
      distributionId: int.tryParse(row['distributionId']?.toString() ?? '') ?? 0,
      totalTipsTzs: int.tryParse(row['totalTipsTzs']?.toString() ?? '') ?? 0,
      platformFeeTzs: int.tryParse(row['platformFeeTzs']?.toString() ?? '') ?? 0,
      netDistributedTzs: int.tryParse(row['netDistributedTzs']?.toString() ?? '') ?? 0,
      breakdown: (row['breakdown'] as List<dynamic>? ?? [])
          .whereType<Map<String, dynamic>>()
          .map(
            (b) => TipBreakdown(
              userId: int.tryParse(b['userId']?.toString() ?? '') ?? 0,
              name: b['name']?.toString() ?? '',
              sharePct: int.tryParse(b['sharePct']?.toString() ?? '') ?? 0,
              amountTzs: int.tryParse(b['amountTzs']?.toString() ?? '') ?? 0,
            ),
          )
          .toList(),
    );
  }

  static Map<String, dynamic> _taxonomyToLegacy(Map<String, dynamic> row) {
    return {
      'id': int.tryParse(row['id']?.toString() ?? '') ?? 0,
      'level': row['level'] ?? 'service',
      if (row['parentId'] != null)
        'parent_id': int.tryParse(row['parentId'].toString()),
      'name_en': row['nameEn'] ?? '',
      'name_sw': row['nameSw'] ?? '',
      if (row['cluster'] != null) 'cluster': row['cluster'],
      if (row['skillCategory'] != null) 'skill_category': row['skillCategory'],
      'breadcrumb': row['breadcrumb'] ?? [],
    };
  }

  static Future<List<TipPoolRule>> listTipPools(int partnerUserId) async {
    try {
      final data = await TajiriGraphqlClient.instance.query(
        '''
        query TajirikaTipPools(\$partnerUserId: ID!) {
          tajirikaTipPools(partnerUserId: \$partnerUserId) {
            id
            partnerUserId
            skillCategory
            isActive
            tipSplitType
            staffShares { userId name sharePct }
            distributionFrequencyDays
            minTipTzs
          }
        }
        ''',
        variables: {'partnerUserId': partnerUserId.toString()},
      );
      final rows = data['tajirikaTipPools'] as List<dynamic>? ?? [];
      return rows
          .whereType<Map<String, dynamic>>()
          .map((row) => TipPoolRule.fromJson(_tipPoolToLegacy(row)))
          .toList();
    } catch (_) {
      return const [];
    }
  }

  static Future<int?> createTipPool({
    required int partnerUserId,
    String? skillCategory,
    int tipSplitType = 1,
    List<StaffShare>? staffShares,
    int distributionFrequencyDays = 7,
    int minTipTzs = 0,
  }) async {
    try {
      final data = await TajiriGraphqlClient.instance.mutate(
        '''
        mutation CreateTajirikaTipPool(\$input: CreateTajirikaTipPoolInput!) {
          createTajirikaTipPool(input: \$input) { id }
        }
        ''',
        variables: {
          'input': {
            'partnerUserId': partnerUserId.toString(),
            'tipSplitType': tipSplitType,
            'distributionFrequencyDays': distributionFrequencyDays,
            'minTipTzs': minTipTzs,
            if (skillCategory != null) 'skillCategory': skillCategory,
            if (staffShares != null)
              'staffShares': staffShares
                  .map(
                    (s) => {
                      'userId': s.userId.toString(),
                      'name': s.name,
                      'sharePct': s.sharePct,
                    },
                  )
                  .toList(),
          },
        },
        auth: true,
      );
      final row = data['createTajirikaTipPool'] as Map<String, dynamic>?;
      return int.tryParse(row?['id']?.toString() ?? '');
    } catch (_) {
      return null;
    }
  }

  static Future<bool> updateTipPool(int id, Map<String, dynamic> fields) async {
    try {
      final input = <String, dynamic>{};
      if (fields.containsKey('tip_split_type')) input['tipSplitType'] = fields['tip_split_type'];
      if (fields.containsKey('distribution_frequency_days')) {
        input['distributionFrequencyDays'] = fields['distribution_frequency_days'];
      }
      if (fields.containsKey('min_tip_tzs')) input['minTipTzs'] = fields['min_tip_tzs'];
      if (fields.containsKey('skill_category')) input['skillCategory'] = fields['skill_category'];
      if (fields.containsKey('is_active')) input['isActive'] = fields['is_active'];
      if (fields.containsKey('staff_shares')) {
        input['staffShares'] = (fields['staff_shares'] as List)
            .whereType<Map>()
            .map(
              (s) => {
                'userId': '${s['user_id']}',
                'name': s['name'],
                'sharePct': s['share_pct'],
              },
            )
            .toList();
      }
      await TajiriGraphqlClient.instance.mutate(
        '''
        mutation UpdateTajirikaTipPool(\$tipPoolId: ID!, \$input: UpdateTajirikaTipPoolInput!) {
          updateTajirikaTipPool(tipPoolId: \$tipPoolId, input: \$input)
        }
        ''',
        variables: {'tipPoolId': id.toString(), 'input': input},
        auth: true,
      );
      return true;
    } catch (_) {
      return false;
    }
  }

  static Future<TipDistributionResult?> distributeTipPool(int id) async {
    try {
      final data = await TajiriGraphqlClient.instance.mutate(
        '''
        mutation DistributeTajirikaTipPool(\$tipPoolId: ID!) {
          distributeTajirikaTipPool(tipPoolId: \$tipPoolId) {
            distributionId
            totalTipsTzs
            platformFeeTzs
            netDistributedTzs
            breakdown { userId name sharePct amountTzs }
          }
        }
        ''',
        variables: {'tipPoolId': id.toString()},
        auth: true,
      );
      final row = data['distributeTajirikaTipPool'] as Map<String, dynamic>?;
      if (row == null) return null;
      return _distributionToLegacy(row);
    } catch (_) {
      return null;
    }
  }

  static Future<List<TipDistributionResult>> listTipPoolDistributions(int id) async {
    try {
      final data = await TajiriGraphqlClient.instance.query(
        '''
        query TajirikaTipPoolDistributions(\$tipPoolId: ID!) {
          tajirikaTipPoolDistributions(tipPoolId: \$tipPoolId) {
            distributionId
            totalTipsTzs
            platformFeeTzs
            netDistributedTzs
            breakdown { userId name sharePct amountTzs }
          }
        }
        ''',
        variables: {'tipPoolId': id.toString()},
      );
      final rows = data['tajirikaTipPoolDistributions'] as List<dynamic>? ?? [];
      return rows
          .whereType<Map<String, dynamic>>()
          .map(_distributionToLegacy)
          .toList();
    } catch (_) {
      return const [];
    }
  }

  static Future<DeliveryFeeResult> calculateDeliveryFee({
    required double fromLat,
    required double fromLng,
    required double toLat,
    required double toLng,
    required int perKmTzs,
    required int maxFeeTzs,
  }) async {
    try {
      final data = await TajiriGraphqlClient.instance.query(
        '''
        query TajirikaDeliveryFee(
          \$fromLat: Float!,
          \$fromLng: Float!,
          \$toLat: Float!,
          \$toLng: Float!,
          \$perKmTzs: Int!,
          \$maxFeeTzs: Int!,
        ) {
          tajirikaDeliveryFee(
            fromLat: \$fromLat,
            fromLng: \$fromLng,
            toLat: \$toLat,
            toLng: \$toLng,
            perKmTzs: \$perKmTzs,
            maxFeeTzs: \$maxFeeTzs,
          ) {
            distanceKm
            feeTzs
            calculationMethod
          }
        }
        ''',
        variables: {
          'fromLat': fromLat,
          'fromLng': fromLng,
          'toLat': toLat,
          'toLng': toLng,
          'perKmTzs': perKmTzs,
          'maxFeeTzs': maxFeeTzs,
        },
      );
      final row = data['tajirikaDeliveryFee'] as Map<String, dynamic>?;
      if (row == null) {
        return DeliveryFeeResult(success: false, message: 'Empty response');
      }
      return DeliveryFeeResult(
        success: true,
        distanceKm: (row['distanceKm'] as num?)?.toDouble(),
        feeTzs: int.tryParse(row['feeTzs']?.toString() ?? ''),
        method: row['calculationMethod']?.toString(),
      );
    } catch (e) {
      return DeliveryFeeResult(success: false, message: 'Kosa: $e');
    }
  }

  static Future<List<TaxonomyNode>> listTaxonomyCategories() async {
    try {
      final data = await TajiriGraphqlClient.instance.query(
        '''
        query TajirikaServiceTaxonomyCategories {
          tajirikaServiceTaxonomyCategories {
            id level parentId nameEn nameSw cluster skillCategory breadcrumb
          }
        }
        ''',
      );
      final rows = data['tajirikaServiceTaxonomyCategories'] as List<dynamic>? ?? [];
      return rows
          .whereType<Map<String, dynamic>>()
          .map((row) => TaxonomyNode.fromJson(_taxonomyToLegacy(row)))
          .toList();
    } catch (_) {
      return const [];
    }
  }

  static Future<List<TaxonomyNode>> listTaxonomyChildren(int parentId) async {
    try {
      final data = await TajiriGraphqlClient.instance.query(
        '''
        query TajirikaServiceTaxonomyChildren(\$parentId: ID!) {
          tajirikaServiceTaxonomyChildren(parentId: \$parentId) {
            id level parentId nameEn nameSw cluster skillCategory breadcrumb
          }
        }
        ''',
        variables: {'parentId': parentId.toString()},
      );
      final rows = data['tajirikaServiceTaxonomyChildren'] as List<dynamic>? ?? [];
      return rows
          .whereType<Map<String, dynamic>>()
          .map((row) => TaxonomyNode.fromJson(_taxonomyToLegacy(row)))
          .toList();
    } catch (_) {
      return const [];
    }
  }

  static Future<List<TaxonomyNode>> searchTaxonomy(String q) async {
    try {
      final data = await TajiriGraphqlClient.instance.query(
        '''
        query TajirikaServiceTaxonomySearch(\$q: String!) {
          tajirikaServiceTaxonomySearch(q: \$q) {
            id level parentId nameEn nameSw cluster skillCategory breadcrumb
          }
        }
        ''',
        variables: {'q': q.trim()},
      );
      final rows = data['tajirikaServiceTaxonomySearch'] as List<dynamic>? ?? [];
      return rows
          .whereType<Map<String, dynamic>>()
          .map((row) => TaxonomyNode.fromJson(_taxonomyToLegacy(row)))
          .toList();
    } catch (_) {
      return const [];
    }
  }

  static Future<GeofenceCheckResult> checkGeofence({
    required int partnerUserId,
    required int orderId,
    required String orderSource,
    required double lat,
    required double lng,
  }) async {
    try {
      final data = await TajiriGraphqlClient.instance.mutate(
        '''
        mutation CheckTajirikaGeofence(\$input: CheckTajirikaGeofenceInput!) {
          checkTajirikaGeofence(input: \$input) {
            distanceMeters
            inside100m
            inside500m
            status
            eventId
          }
        }
        ''',
        variables: {
          'input': {
            'partnerUserId': partnerUserId.toString(),
            'orderId': orderId.toString(),
            'orderSource': orderSource,
            'lat': lat,
            'lng': lng,
          },
        },
      );
      final row = data['checkTajirikaGeofence'] as Map<String, dynamic>?;
      if (row == null) {
        return GeofenceCheckResult(success: false, message: 'Empty response');
      }
      return GeofenceCheckResult(
        success: true,
        distanceMeters: int.tryParse(row['distanceMeters']?.toString() ?? '') ?? 0,
        inside100m: row['inside100m'] == true,
        inside500m: row['inside500m'] == true,
        status: row['status']?.toString() ?? 'idle',
        eventId: int.tryParse(row['eventId']?.toString() ?? ''),
      );
    } catch (e) {
      return GeofenceCheckResult(success: false, message: 'Kosa: $e');
    }
  }

  static Future<EtaResult> geofenceEta({
    required double fromLat,
    required double fromLng,
    required double toLat,
    required double toLng,
  }) async {
    try {
      final data = await TajiriGraphqlClient.instance.query(
        '''
        query TajirikaGeofenceEta(
          \$fromLat: Float!,
          \$fromLng: Float!,
          \$toLat: Float!,
          \$toLng: Float!,
        ) {
          tajirikaGeofenceEta(
            fromLat: \$fromLat,
            fromLng: \$fromLng,
            toLat: \$toLat,
            toLng: \$toLng,
          ) {
            distanceMeters
            etaSeconds
            etaText
          }
        }
        ''',
        variables: {
          'fromLat': fromLat,
          'fromLng': fromLng,
          'toLat': toLat,
          'toLng': toLng,
        },
      );
      final row = data['tajirikaGeofenceEta'] as Map<String, dynamic>?;
      if (row == null) {
        return EtaResult(success: false, message: 'Empty response');
      }
      return EtaResult(
        success: true,
        distanceMeters: int.tryParse(row['distanceMeters']?.toString() ?? '') ?? 0,
        etaSeconds: int.tryParse(row['etaSeconds']?.toString() ?? '') ?? 0,
        etaText: row['etaText']?.toString() ?? '',
      );
    } catch (e) {
      return EtaResult(success: false, message: 'Kosa: $e');
    }
  }

  static Future<List<GeofenceEvent>> listGeofenceEvents({
    int? partnerUserId,
    int? orderId,
    int limit = 50,
  }) async {
    try {
      final data = await TajiriGraphqlClient.instance.query(
        '''
        query TajirikaGeofenceEvents(
          \$partnerUserId: ID,
          \$orderId: ID,
          \$limit: Int,
        ) {
          tajirikaGeofenceEvents(
            partnerUserId: \$partnerUserId,
            orderId: \$orderId,
            limit: \$limit,
          ) {
            id
            partnerUserId
            orderId
            orderSource
            distanceMeters
            createdAt
          }
        }
        ''',
        variables: {
          if (partnerUserId != null) 'partnerUserId': partnerUserId.toString(),
          if (orderId != null) 'orderId': orderId.toString(),
          'limit': limit,
        },
      );
      final rows = data['tajirikaGeofenceEvents'] as List<dynamic>? ?? [];
      return rows.whereType<Map<String, dynamic>>().map((row) {
        return GeofenceEvent.fromJson({
          'id': int.tryParse(row['id']?.toString() ?? '') ?? 0,
          'partner_user_id': int.tryParse(row['partnerUserId']?.toString() ?? '') ?? 0,
          'order_id': int.tryParse(row['orderId']?.toString() ?? '') ?? 0,
          'order_source': row['orderSource'] ?? '',
          'distance_meters': int.tryParse(row['distanceMeters']?.toString() ?? '') ?? 0,
          'created_at': row['createdAt'],
        });
      }).toList();
    } catch (_) {
      return const [];
    }
  }
}
