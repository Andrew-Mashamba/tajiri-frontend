import '../../my_pregnancy/models/my_pregnancy_models.dart';
import 'tajiri_graphql_client.dart';

/// GraphQL my pregnancy tracking (Phase 75 — backend rev 210).
/// Week info, symptoms, contractions, weight, birth plan, journal remain REST-only.
class GraphqlMyPregnancyService {
  static const _pregnancyFields = r'''
    id
    lastPeriodDate
    dueDate
    currentWeek
    trimester
    status
    babyName
    babyGender
    deliveryType
    deliveryDate
    babyWeightGrams
    prePregnancyWeightKg
  ''';

  static const _ancFields = r'''
    id
    pregnancyId
    visitNumber
    scheduledDate
    completedDate
    facility
    notes
    isDone
  ''';

  static const _kickFields = r'''
    id
    pregnancyId
    date
    count
    durationMinutes
    startTime
  ''';

  static Map<String, dynamic> _pregnancyToLegacy(Map<String, dynamic> row) {
    return {
      'id': int.tryParse(row['id']?.toString() ?? '') ?? 0,
      'user_id': 0,
      'last_period_date': row['lastPeriodDate'],
      'due_date': row['dueDate'],
      'current_week': row['currentWeek'],
      'trimester': row['trimester'],
      'status': row['status'],
      'baby_name': row['babyName'],
      'baby_gender': row['babyGender'],
      'delivery_type': row['deliveryType'],
      'delivery_date': row['deliveryDate'],
      'baby_weight_grams': row['babyWeightGrams'],
      'pre_pregnancy_weight_kg': row['prePregnancyWeightKg'],
    };
  }

  static Map<String, dynamic> _ancToLegacy(Map<String, dynamic> row) {
    return {
      'id': int.tryParse(row['id']?.toString() ?? '') ?? 0,
      'pregnancy_id': row['pregnancyId'],
      'visit_number': row['visitNumber'],
      'scheduled_date': row['scheduledDate'],
      'completed_date': row['completedDate'],
      'facility': row['facility'],
      'notes': row['notes'],
      'is_done': row['isDone'],
    };
  }

  static Map<String, dynamic> _kickToLegacy(Map<String, dynamic> row) {
    return {
      'id': int.tryParse(row['id']?.toString() ?? '') ?? 0,
      'pregnancy_id': row['pregnancyId'],
      'date': row['date'],
      'count': row['count'],
      'duration_minutes': row['durationMinutes'],
      'start_time': row['startTime'],
    };
  }

  static Future<MyPregnancyResult<Pregnancy>> createPregnancy({
    required DateTime lastPeriodDate,
    String? babyName,
    String? babyGender,
    double? prePregnancyWeightKg,
  }) async {
    try {
      final result = await TajiriGraphqlClient.instance.mutate(
        '''
        mutation CreatePregnancy(\$input: CreatePregnancyInput!) {
          createPregnancy(input: \$input) {
            $_pregnancyFields
          }
        }
        ''',
        variables: {
          'input': {
            'lastPeriodDate': lastPeriodDate.toIso8601String(),
            if (babyName != null) 'babyName': babyName,
            if (babyGender != null) 'babyGender': babyGender,
            if (prePregnancyWeightKg != null)
              'prePregnancyWeightKg': prePregnancyWeightKg,
          },
        },
        auth: true,
      );
      final row = result['createPregnancy'] as Map<String, dynamic>?;
      if (row == null) {
        return MyPregnancyResult(success: false, message: 'Imeshindwa kuanza');
      }
      return MyPregnancyResult(
        success: true,
        data: Pregnancy.fromJson(_pregnancyToLegacy(row)),
      );
    } catch (e) {
      return MyPregnancyResult(success: false, message: '$e');
    }
  }

  static Future<MyPregnancyResult<Pregnancy>> getMyPregnancy() async {
    try {
      final data = await TajiriGraphqlClient.instance.query(
        '''
        query MyPregnancy {
          myPregnancy {
            $_pregnancyFields
          }
        }
        ''',
        auth: true,
      );
      final row = data['myPregnancy'] as Map<String, dynamic>?;
      if (row == null) {
        return MyPregnancyResult(success: false);
      }
      return MyPregnancyResult(
        success: true,
        data: Pregnancy.fromJson(_pregnancyToLegacy(row)),
      );
    } catch (e) {
      return MyPregnancyResult(success: false, message: '$e');
    }
  }

  static Future<MyPregnancyResult<Pregnancy>> updatePregnancy({
    required int pregnancyId,
    String? babyName,
    String? babyGender,
    String? status,
    String? deliveryType,
    DateTime? deliveryDate,
    int? babyWeightGrams,
  }) async {
    try {
      final result = await TajiriGraphqlClient.instance.mutate(
        '''
        mutation UpdatePregnancy(
          \$pregnancyId: ID!,
          \$babyName: String,
          \$babyGender: String,
          \$status: String,
          \$deliveryType: String,
          \$deliveryDate: String,
          \$babyWeightGrams: Int
        ) {
          updatePregnancy(
            pregnancyId: \$pregnancyId,
            babyName: \$babyName,
            babyGender: \$babyGender,
            status: \$status,
            deliveryType: \$deliveryType,
            deliveryDate: \$deliveryDate,
            babyWeightGrams: \$babyWeightGrams
          ) {
            $_pregnancyFields
          }
        }
        ''',
        variables: {
          'pregnancyId': pregnancyId.toString(),
          if (babyName != null) 'babyName': babyName,
          if (babyGender != null) 'babyGender': babyGender,
          if (status != null) 'status': status,
          if (deliveryType != null) 'deliveryType': deliveryType,
          if (deliveryDate != null)
            'deliveryDate': deliveryDate.toIso8601String(),
          if (babyWeightGrams != null) 'babyWeightGrams': babyWeightGrams,
        },
        auth: true,
      );
      final row = result['updatePregnancy'] as Map<String, dynamic>?;
      if (row == null) {
        return MyPregnancyResult(success: false, message: 'Imeshindwa kusasisha');
      }
      return MyPregnancyResult(
        success: true,
        data: Pregnancy.fromJson(_pregnancyToLegacy(row)),
      );
    } catch (e) {
      return MyPregnancyResult(success: false, message: '$e');
    }
  }

  static Future<MyPregnancyListResult<AncVisit>> getAncSchedule(
    int pregnancyId,
  ) async {
    try {
      final data = await TajiriGraphqlClient.instance.query(
        '''
        query PregnancyAncVisits(\$pregnancyId: ID!) {
          pregnancyAncVisits(pregnancyId: \$pregnancyId) {
            $_ancFields
          }
        }
        ''',
        variables: {'pregnancyId': pregnancyId.toString()},
        auth: true,
      );
      final rows = data['pregnancyAncVisits'] as List<dynamic>? ?? [];
      final items = rows
          .whereType<Map<String, dynamic>>()
          .map((row) => AncVisit.fromJson(_ancToLegacy(row)))
          .toList();
      return MyPregnancyListResult(success: true, items: items);
    } catch (e) {
      return MyPregnancyListResult(success: false, message: '$e');
    }
  }

  static Future<MyPregnancyResult<AncVisit>> markAncVisitDone(
    int visitId, {
    String? notes,
    String? facility,
  }) async {
    try {
      final result = await TajiriGraphqlClient.instance.mutate(
        '''
        mutation CompleteAncVisit(
          \$visitId: ID!,
          \$facility: String,
          \$notes: String
        ) {
          completeAncVisit(
            visitId: \$visitId,
            facility: \$facility,
            notes: \$notes
          ) {
            $_ancFields
          }
        }
        ''',
        variables: {
          'visitId': visitId.toString(),
          if (facility != null) 'facility': facility,
          if (notes != null) 'notes': notes,
        },
        auth: true,
      );
      final row = result['completeAncVisit'] as Map<String, dynamic>?;
      if (row == null) {
        return MyPregnancyResult(success: false, message: 'Imeshindwa');
      }
      return MyPregnancyResult(
        success: true,
        data: AncVisit.fromJson(_ancToLegacy(row)),
      );
    } catch (e) {
      return MyPregnancyResult(success: false, message: '$e');
    }
  }

  static Future<MyPregnancyResult<KickCount>> saveKickCount({
    required int pregnancyId,
    required int count,
    required int durationMinutes,
    required DateTime startTime,
  }) async {
    try {
      final result = await TajiriGraphqlClient.instance.mutate(
        '''
        mutation LogKickCount(\$input: LogKickCountInput!) {
          logKickCount(input: \$input) {
            $_kickFields
          }
        }
        ''',
        variables: {
          'input': {
            'pregnancyId': pregnancyId.toString(),
            'count': count,
            'durationMinutes': durationMinutes,
            'startTime': startTime.toIso8601String(),
          },
        },
        auth: true,
      );
      final row = result['logKickCount'] as Map<String, dynamic>?;
      if (row == null) {
        return MyPregnancyResult(success: false, message: 'Imeshindwa kuhifadhi');
      }
      return MyPregnancyResult(
        success: true,
        data: KickCount.fromJson(_kickToLegacy(row)),
      );
    } catch (e) {
      return MyPregnancyResult(success: false, message: '$e');
    }
  }

  static Future<MyPregnancyListResult<KickCount>> getKickHistory(
    int pregnancyId,
  ) async {
    try {
      final data = await TajiriGraphqlClient.instance.query(
        '''
        query PregnancyKickCounts(\$pregnancyId: ID!) {
          pregnancyKickCounts(pregnancyId: \$pregnancyId) {
            $_kickFields
          }
        }
        ''',
        variables: {'pregnancyId': pregnancyId.toString()},
        auth: true,
      );
      final rows = data['pregnancyKickCounts'] as List<dynamic>? ?? [];
      final items = rows
          .whereType<Map<String, dynamic>>()
          .map((row) => KickCount.fromJson(_kickToLegacy(row)))
          .toList();
      return MyPregnancyListResult(success: true, items: items);
    } catch (e) {
      return MyPregnancyListResult(success: false, message: '$e');
    }
  }
}
