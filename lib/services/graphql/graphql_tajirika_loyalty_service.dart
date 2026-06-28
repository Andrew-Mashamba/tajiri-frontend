import '../../tajirika/models/loyalty_bundle.dart';
import '../../tajirika/models/partner_vip_slot.dart';
import '../../tajirika/services/loyalty_stamp_service.dart';
import '../../tajirika/services/partner_c2b_metrics_service.dart';
import 'tajiri_graphql_client.dart';

/// GraphQL Tajirika C2B loyalty (Phases 155–158).
class GraphqlTajirikaLoyaltyService {
  static Map<String, dynamic> _vipSlotToLegacy(Map<String, dynamic> row) {
    return {
      'id': int.tryParse(row['id']?.toString() ?? '') ?? 0,
      'partner_user_id': int.tryParse(row['partnerUserId']?.toString() ?? '') ?? 0,
      'customer_user_id': int.tryParse(row['customerUserId']?.toString() ?? '') ?? 0,
      if (row['skillCategory'] != null) 'skill_category': row['skillCategory'],
      'weekday': int.tryParse(row['weekday']?.toString() ?? '') ?? 0,
      'slot_time': row['slotTime'] ?? '00:00',
      'is_active': row['isActive'] == true,
    };
  }

  static Map<String, dynamic> _bundleToLegacy(Map<String, dynamic> row) {
    return {
      'id': int.tryParse(row['id']?.toString() ?? '') ?? 0,
      'partner_user_id': int.tryParse(row['partnerUserId']?.toString() ?? '') ?? 0,
      'name': row['name'] ?? '',
      if (row['description'] != null) 'description': row['description'],
      'services_count': int.tryParse(row['servicesCount']?.toString() ?? '') ?? 1,
      'validity_days': int.tryParse(row['validityDays']?.toString() ?? '') ?? 30,
      'price_tzs': int.tryParse(row['priceTzs']?.toString() ?? '') ?? 0,
      if (row['originalPriceTzs'] != null)
        'original_price_tzs': int.tryParse(row['originalPriceTzs'].toString()),
      'is_active': row['isActive'] == true,
      if (row['createdAt'] != null) 'created_at': row['createdAt'],
    };
  }

  static Map<String, dynamic> _stampToLegacy(Map<String, dynamic> row) {
    return {
      'id': int.tryParse(row['id']?.toString() ?? '') ?? 0,
      'partner_id': int.tryParse(row['partnerId']?.toString() ?? '') ?? 0,
      'customer_user_id': int.tryParse(row['customerUserId']?.toString() ?? '') ?? 0,
      'stamps_earned': int.tryParse(row['stampsEarned']?.toString() ?? '') ?? 0,
      'target': int.tryParse(row['target']?.toString() ?? '') ?? 10,
      if (row['expiresAt'] != null) 'expires_at': row['expiresAt'],
      if (row['createdAt'] != null) 'created_at': row['createdAt'],
      if (row['updatedAt'] != null) 'updated_at': row['updatedAt'],
    };
  }

  static Map<String, dynamic> _metricToLegacy(Map<String, dynamic> row) {
    return {
      'date': row['date'] ?? '',
      'role': row['role'] ?? '',
      'source_type': row['sourceType'] ?? '',
      'count_new': int.tryParse(row['countNew']?.toString() ?? '') ?? 0,
      'count_active': int.tryParse(row['countActive']?.toString() ?? '') ?? 0,
      'count_completed': int.tryParse(row['countCompleted']?.toString() ?? '') ?? 0,
      'count_cancelled': int.tryParse(row['countCancelled']?.toString() ?? '') ?? 0,
      'revenue_tzs': int.tryParse(row['revenueTzs']?.toString() ?? '') ?? 0,
      if (row['avgRating'] != null) 'avg_rating': row['avgRating'],
      'reviews_count': int.tryParse(row['reviewsCount']?.toString() ?? '') ?? 0,
    };
  }

  static Future<List<PartnerVipSlot>> listPartnerVipSlots(int partnerUserId) async {
    try {
      final data = await TajiriGraphqlClient.instance.query(
        '''
        query TajirikaPartnerVipSlots(\$partnerUserId: ID!) {
          tajirikaPartnerVipSlots(partnerUserId: \$partnerUserId) {
            id
            partnerUserId
            customerUserId
            skillCategory
            weekday
            slotTime
            isActive
          }
        }
        ''',
        variables: {'partnerUserId': partnerUserId.toString()},
      );
      final rows = data['tajirikaPartnerVipSlots'] as List<dynamic>? ?? [];
      return rows
          .whereType<Map<String, dynamic>>()
          .map((row) => PartnerVipSlot.fromJson(_vipSlotToLegacy(row)))
          .toList();
    } catch (_) {
      return const [];
    }
  }

  static Future<bool> createPartnerVipSlot({
    required int partnerUserId,
    required int customerUserId,
    required int weekday,
    required String slotTime,
    String? skillCategory,
  }) async {
    try {
      await TajiriGraphqlClient.instance.mutate(
        '''
        mutation CreateTajirikaPartnerVipSlot(\$input: CreateTajirikaPartnerVipSlotInput!) {
          createTajirikaPartnerVipSlot(input: \$input) {
            id
          }
        }
        ''',
        variables: {
          'input': {
            'partnerUserId': partnerUserId.toString(),
            'customerUserId': customerUserId.toString(),
            'weekday': weekday,
            'slotTime': slotTime,
            if (skillCategory != null && skillCategory.isNotEmpty)
              'skillCategory': skillCategory,
          },
        },
        auth: true,
      );
      return true;
    } catch (_) {
      return false;
    }
  }

  static Future<bool> deletePartnerVipSlot(int id) async {
    try {
      await TajiriGraphqlClient.instance.mutate(
        '''
        mutation DeleteTajirikaPartnerVipSlot(\$vipSlotId: ID!) {
          deleteTajirikaPartnerVipSlot(vipSlotId: \$vipSlotId)
        }
        ''',
        variables: {'vipSlotId': id.toString()},
        auth: true,
      );
      return true;
    } catch (_) {
      return false;
    }
  }

  static Future<LoyaltyBundleListResult> listLoyaltyBundles(int partnerUserId) async {
    try {
      final data = await TajiriGraphqlClient.instance.query(
        '''
        query TajirikaLoyaltyBundles(\$partnerUserId: ID!) {
          tajirikaLoyaltyBundles(partnerUserId: \$partnerUserId) {
            id
            partnerUserId
            name
            description
            servicesCount
            validityDays
            priceTzs
            originalPriceTzs
            isActive
            createdAt
          }
        }
        ''',
        variables: {'partnerUserId': partnerUserId.toString()},
      );
      final rows = data['tajirikaLoyaltyBundles'] as List<dynamic>? ?? [];
      final items = rows
          .whereType<Map<String, dynamic>>()
          .map((row) => LoyaltyBundle.fromJson(_bundleToLegacy(row)))
          .toList();
      return LoyaltyBundleListResult(success: true, items: items);
    } catch (e) {
      return LoyaltyBundleListResult(success: false, message: 'Kosa: $e');
    }
  }

  static Future<bool> purchaseLoyaltyBundle(int bundleId) async {
    try {
      await TajiriGraphqlClient.instance.mutate(
        '''
        mutation PurchaseTajirikaLoyaltyBundle(\$bundleId: ID!) {
          purchaseTajirikaLoyaltyBundle(bundleId: \$bundleId)
        }
        ''',
        variables: {'bundleId': bundleId.toString()},
        auth: true,
      );
      return true;
    } catch (_) {
      return false;
    }
  }

  static Future<LoyaltyStampCard?> fetchLoyaltyStampCard({
    required int partnerId,
  }) async {
    try {
      final data = await TajiriGraphqlClient.instance.query(
        '''
        query MyTajirikaLoyaltyStampCard(\$partnerId: ID!) {
          myTajirikaLoyaltyStampCard(partnerId: \$partnerId) {
            id
            partnerId
            customerUserId
            stampsEarned
            target
            expiresAt
            createdAt
            updatedAt
          }
        }
        ''',
        variables: {'partnerId': partnerId.toString()},
        auth: true,
      );
      final row = data['myTajirikaLoyaltyStampCard'] as Map<String, dynamic>?;
      if (row == null) return null;
      return LoyaltyStampCard.fromJson(_stampToLegacy(row));
    } catch (_) {
      return null;
    }
  }

  static Future<List<PartnerC2BMetricsRow>> fetchC2bMetrics({
    required int userId,
    String? role,
    String? sourceType,
    DateTime? from,
    DateTime? to,
  }) async {
    try {
      final data = await TajiriGraphqlClient.instance.query(
        '''
        query TajirikaPartnerC2bMetrics(
          \$userId: ID!
          \$role: String
          \$sourceType: String
          \$fromDate: String
          \$toDate: String
        ) {
          tajirikaPartnerC2bMetrics(
            userId: \$userId
            role: \$role
            sourceType: \$sourceType
            fromDate: \$fromDate
            toDate: \$toDate
          ) {
            date
            role
            sourceType
            countNew
            countActive
            countCompleted
            countCancelled
            revenueTzs
            avgRating
            reviewsCount
          }
        }
        ''',
        variables: {
          'userId': userId.toString(),
          if (role != null) 'role': role,
          if (sourceType != null) 'sourceType': sourceType,
          if (from != null) 'fromDate': from.toIso8601String().split('T').first,
          if (to != null) 'toDate': to.toIso8601String().split('T').first,
        },
        auth: true,
      );
      final rows = data['tajirikaPartnerC2bMetrics'] as List<dynamic>? ?? [];
      return rows
          .whereType<Map<String, dynamic>>()
          .map((row) => PartnerC2BMetricsRow.fromJson(_metricToLegacy(row)))
          .toList();
    } catch (_) {
      return const [];
    }
  }
}
