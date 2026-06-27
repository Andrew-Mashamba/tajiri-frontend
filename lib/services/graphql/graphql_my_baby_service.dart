import '../../my_baby/models/my_baby_models.dart';
import 'tajiri_graphql_client.dart';

/// GraphQL my baby tracking (Phase 72 — backend rev 209).
/// Vaccinations, milestones, photos, caregivers, summary remain REST-only.
class GraphqlMyBabyService {
  static const _babyFields = r'''
    id
    name
    dateOfBirth
    gender
    birthWeightGrams
    birthLengthCm
    createdAt
  ''';

  static const _feedingFields = r'''
    id
    babyId
    type
    side
    durationMinutes
    amountMl
    foodDescription
    loggedAt
  ''';

  static const _sleepFields = r'''
    id
    babyId
    startTime
    endTime
    durationMinutes
    type
    notes
  ''';

  static const _diaperFields = r'''
    id
    babyId
    type
    color
    notes
    loggedAt
  ''';

  static const _growthFields = r'''
    id
    babyId
    weightKg
    heightCm
    headCm
    measuredAt
    notes
  ''';

  static Map<String, dynamic> _babyToLegacy(Map<String, dynamic> row) {
    return {
      'id': int.tryParse(row['id']?.toString() ?? '') ?? 0,
      'user_id': 0,
      'name': row['name'],
      'date_of_birth': row['dateOfBirth'],
      'gender': row['gender'],
      'birth_weight_grams': row['birthWeightGrams'],
      'birth_length_cm': row['birthLengthCm'],
    };
  }

  static Map<String, dynamic> _feedingToLegacy(Map<String, dynamic> row) {
    return {
      'id': int.tryParse(row['id']?.toString() ?? '') ?? 0,
      'baby_id': row['babyId'],
      'type': row['type'],
      'side': row['side'],
      'duration_minutes': row['durationMinutes'],
      'amount_ml': row['amountMl'],
      'food_description': row['foodDescription'],
      'date': row['loggedAt'],
    };
  }

  static Map<String, dynamic> _sleepToLegacy(Map<String, dynamic> row) {
    return {
      'id': row['id'],
      'baby_id': row['babyId'],
      'start_time': row['startTime'],
      'end_time': row['endTime'],
      'duration_minutes': row['durationMinutes'],
      'type': row['type'],
      'notes': row['notes'],
    };
  }

  static Map<String, dynamic> _diaperToLegacy(Map<String, dynamic> row) {
    return {
      'id': row['id'],
      'baby_id': row['babyId'],
      'type': row['type'],
      'color': row['color'],
      'notes': row['notes'],
      'logged_at': row['loggedAt'],
    };
  }

  static Map<String, dynamic> _growthToLegacy(Map<String, dynamic> row) {
    return {
      'id': row['id'],
      'baby_id': row['babyId'],
      'weight_kg': row['weightKg'],
      'height_cm': row['heightCm'],
      'head_cm': row['headCm'],
      'measured_at': row['measuredAt'],
      'notes': row['notes'],
    };
  }

  static bool _sameDay(DateTime a, DateTime b) {
    return a.year == b.year && a.month == b.month && a.day == b.day;
  }

  static Future<MyBabyListResult<Baby>> getMyBabies() async {
    try {
      final data = await TajiriGraphqlClient.instance.query(
        '''
        query MyBabies {
          myBabies {
            $_babyFields
          }
        }
        ''',
        auth: true,
      );
      final rows = data['myBabies'] as List<dynamic>? ?? [];
      final items = rows
          .whereType<Map<String, dynamic>>()
          .map((row) => Baby.fromJson(_babyToLegacy(row)))
          .toList();
      return MyBabyListResult(success: true, items: items);
    } catch (e) {
      return MyBabyListResult(success: false, message: '$e');
    }
  }

  static Future<MyBabyResult<Baby>> registerBaby({
    required String name,
    required DateTime dateOfBirth,
    String? gender,
    int? birthWeightGrams,
    double? birthLengthCm,
  }) async {
    try {
      final result = await TajiriGraphqlClient.instance.mutate(
        '''
        mutation CreateBaby(\$input: CreateBabyInput!) {
          createBaby(input: \$input) {
            $_babyFields
          }
        }
        ''',
        variables: {
          'input': {
            'name': name,
            'dateOfBirth': dateOfBirth.toIso8601String(),
            if (gender != null) 'gender': gender,
            if (birthWeightGrams != null) 'birthWeightGrams': birthWeightGrams,
            if (birthLengthCm != null) 'birthLengthCm': birthLengthCm,
          },
        },
        auth: true,
      );
      final row = result['createBaby'] as Map<String, dynamic>?;
      if (row == null) {
        return MyBabyResult(success: false, message: 'Imeshindwa kusajili');
      }
      return MyBabyResult(
        success: true,
        data: Baby.fromJson(_babyToLegacy(row)),
      );
    } catch (e) {
      return MyBabyResult(success: false, message: '$e');
    }
  }

  static Future<MyBabyResult<Baby>> updateBaby({
    required int babyId,
    String? name,
    String? gender,
    int? birthWeightGrams,
    double? birthLengthCm,
  }) async {
    try {
      final result = await TajiriGraphqlClient.instance.mutate(
        '''
        mutation UpdateBaby(
          \$babyId: ID!,
          \$name: String,
          \$gender: String,
          \$birthWeightGrams: Int,
          \$birthLengthCm: Float
        ) {
          updateBaby(
            babyId: \$babyId,
            name: \$name,
            gender: \$gender,
            birthWeightGrams: \$birthWeightGrams,
            birthLengthCm: \$birthLengthCm
          ) {
            $_babyFields
          }
        }
        ''',
        variables: {
          'babyId': babyId.toString(),
          if (name != null) 'name': name,
          if (gender != null) 'gender': gender,
          if (birthWeightGrams != null) 'birthWeightGrams': birthWeightGrams,
          if (birthLengthCm != null) 'birthLengthCm': birthLengthCm,
        },
        auth: true,
      );
      final row = result['updateBaby'] as Map<String, dynamic>?;
      if (row == null) return MyBabyResult(success: false);
      return MyBabyResult(
        success: true,
        data: Baby.fromJson(_babyToLegacy(row)),
      );
    } catch (e) {
      return MyBabyResult(success: false, message: '$e');
    }
  }

  static Future<MyBabyResult<FeedingLog>> logFeeding({
    required int babyId,
    required FeedingType type,
    BreastSide? side,
    int? durationMinutes,
    double? amountMl,
    String? foodDescription,
  }) async {
    try {
      final result = await TajiriGraphqlClient.instance.mutate(
        '''
        mutation LogBabyFeeding(\$input: LogFeedingInput!) {
          logBabyFeeding(input: \$input) {
            $_feedingFields
          }
        }
        ''',
        variables: {
          'input': {
            'babyId': babyId.toString(),
            'type': type.name,
            if (side != null) 'side': side.name,
            if (durationMinutes != null) 'durationMinutes': durationMinutes,
            if (amountMl != null) 'amountMl': amountMl,
            if (foodDescription != null) 'foodDescription': foodDescription,
          },
        },
        auth: true,
      );
      final row = result['logBabyFeeding'] as Map<String, dynamic>?;
      if (row == null) return MyBabyResult(success: false);
      return MyBabyResult(
        success: true,
        data: FeedingLog.fromJson(_feedingToLegacy(row)),
      );
    } catch (e) {
      return MyBabyResult(success: false, message: '$e');
    }
  }

  static Future<MyBabyListResult<FeedingLog>> getFeedingHistory(
    int babyId,
    DateTime date,
  ) async {
    try {
      final data = await TajiriGraphqlClient.instance.query(
        '''
        query BabyFeedings(\$babyId: ID!) {
          babyFeedings(babyId: \$babyId) {
            $_feedingFields
          }
        }
        ''',
        variables: {'babyId': babyId.toString()},
        auth: true,
      );
      final rows = (data['babyFeedings'] as List<dynamic>? ?? [])
          .whereType<Map<String, dynamic>>()
          .map((row) => FeedingLog.fromJson(_feedingToLegacy(row)))
          .where((f) => _sameDay(f.date, date))
          .toList();
      return MyBabyListResult(success: true, items: rows);
    } catch (e) {
      return MyBabyListResult(success: false, message: '$e');
    }
  }

  static Future<MyBabyResult<SleepSession>> logSleep({
    required int babyId,
    required DateTime startTime,
    DateTime? endTime,
    String type = 'nap',
    String? notes,
  }) async {
    try {
      final result = await TajiriGraphqlClient.instance.mutate(
        '''
        mutation LogBabySleep(\$input: LogSleepInput!) {
          logBabySleep(input: \$input) {
            $_sleepFields
          }
        }
        ''',
        variables: {
          'input': {
            'babyId': babyId.toString(),
            'startTime': startTime.toIso8601String(),
            if (endTime != null) 'endTime': endTime.toIso8601String(),
            'type': type,
            if (notes != null) 'notes': notes,
          },
        },
        auth: true,
      );
      final row = result['logBabySleep'] as Map<String, dynamic>?;
      if (row == null) return MyBabyResult(success: false);
      return MyBabyResult(
        success: true,
        data: SleepSession.fromJson(_sleepToLegacy(row)),
      );
    } catch (e) {
      return MyBabyResult(success: false, message: '$e');
    }
  }

  static Future<MyBabyResult<SleepSession>> updateSleep({
    required int sessionId,
    required DateTime endTime,
  }) async {
    try {
      final result = await TajiriGraphqlClient.instance.mutate(
        '''
        mutation EndBabySleep(\$sessionId: ID!, \$endTime: String!) {
          endBabySleep(sessionId: \$sessionId, endTime: \$endTime) {
            $_sleepFields
          }
        }
        ''',
        variables: {
          'sessionId': sessionId.toString(),
          'endTime': endTime.toIso8601String(),
        },
        auth: true,
      );
      final row = result['endBabySleep'] as Map<String, dynamic>?;
      if (row == null) return MyBabyResult(success: false);
      return MyBabyResult(
        success: true,
        data: SleepSession.fromJson(_sleepToLegacy(row)),
      );
    } catch (e) {
      return MyBabyResult(success: false, message: '$e');
    }
  }

  static Future<MyBabyListResult<SleepSession>> getSleepHistory(
    int babyId, {
    DateTime? date,
  }) async {
    try {
      final data = await TajiriGraphqlClient.instance.query(
        '''
        query BabySleepSessions(\$babyId: ID!) {
          babySleepSessions(babyId: \$babyId) {
            $_sleepFields
          }
        }
        ''',
        variables: {'babyId': babyId.toString()},
        auth: true,
      );
      var rows = (data['babySleepSessions'] as List<dynamic>? ?? [])
          .whereType<Map<String, dynamic>>()
          .map((row) => SleepSession.fromJson(_sleepToLegacy(row)))
          .toList();
      if (date != null) {
        rows = rows.where((s) => _sameDay(s.startTime, date)).toList();
      }
      return MyBabyListResult(success: true, items: rows);
    } catch (e) {
      return MyBabyListResult(success: false, message: '$e');
    }
  }

  static Future<MyBabyResult<DiaperLog>> logDiaper({
    required int babyId,
    required String type,
    String? color,
    String? notes,
  }) async {
    try {
      final result = await TajiriGraphqlClient.instance.mutate(
        '''
        mutation LogBabyDiaper(\$input: LogDiaperInput!) {
          logBabyDiaper(input: \$input) {
            $_diaperFields
          }
        }
        ''',
        variables: {
          'input': {
            'babyId': babyId.toString(),
            'type': type,
            if (color != null) 'color': color,
            if (notes != null) 'notes': notes,
          },
        },
        auth: true,
      );
      final row = result['logBabyDiaper'] as Map<String, dynamic>?;
      if (row == null) return MyBabyResult(success: false);
      return MyBabyResult(
        success: true,
        data: DiaperLog.fromJson(_diaperToLegacy(row)),
      );
    } catch (e) {
      return MyBabyResult(success: false, message: '$e');
    }
  }

  static Future<MyBabyListResult<DiaperLog>> getDiaperHistory(
    int babyId, {
    DateTime? date,
  }) async {
    try {
      final data = await TajiriGraphqlClient.instance.query(
        '''
        query BabyDiapers(\$babyId: ID!) {
          babyDiapers(babyId: \$babyId) {
            $_diaperFields
          }
        }
        ''',
        variables: {'babyId': babyId.toString()},
        auth: true,
      );
      var rows = (data['babyDiapers'] as List<dynamic>? ?? [])
          .whereType<Map<String, dynamic>>()
          .map((row) => DiaperLog.fromJson(_diaperToLegacy(row)))
          .toList();
      if (date != null) {
        rows = rows.where((d) => _sameDay(d.loggedAt, date)).toList();
      }
      return MyBabyListResult(success: true, items: rows);
    } catch (e) {
      return MyBabyListResult(success: false, message: '$e');
    }
  }

  static Future<MyBabyResult<GrowthMeasurement>> logGrowth({
    required int babyId,
    double? weightKg,
    double? heightCm,
    double? headCm,
    required DateTime measuredAt,
    String? notes,
  }) async {
    try {
      final result = await TajiriGraphqlClient.instance.mutate(
        '''
        mutation LogBabyGrowth(\$input: LogGrowthInput!) {
          logBabyGrowth(input: \$input) {
            $_growthFields
          }
        }
        ''',
        variables: {
          'input': {
            'babyId': babyId.toString(),
            if (weightKg != null) 'weightKg': weightKg,
            if (heightCm != null) 'heightCm': heightCm,
            if (headCm != null) 'headCm': headCm,
            'measuredAt': measuredAt.toIso8601String(),
            if (notes != null) 'notes': notes,
          },
        },
        auth: true,
      );
      final row = result['logBabyGrowth'] as Map<String, dynamic>?;
      if (row == null) return MyBabyResult(success: false);
      return MyBabyResult(
        success: true,
        data: GrowthMeasurement.fromJson(_growthToLegacy(row)),
      );
    } catch (e) {
      return MyBabyResult(success: false, message: '$e');
    }
  }

  static Future<MyBabyListResult<GrowthMeasurement>> getGrowthHistory(
    int babyId,
  ) async {
    try {
      final data = await TajiriGraphqlClient.instance.query(
        '''
        query BabyGrowth(\$babyId: ID!) {
          babyGrowth(babyId: \$babyId) {
            $_growthFields
          }
        }
        ''',
        variables: {'babyId': babyId.toString()},
        auth: true,
      );
      final rows = (data['babyGrowth'] as List<dynamic>? ?? [])
          .whereType<Map<String, dynamic>>()
          .map((row) => GrowthMeasurement.fromJson(_growthToLegacy(row)))
          .toList();
      return MyBabyListResult(success: true, items: rows);
    } catch (e) {
      return MyBabyListResult(success: false, message: '$e');
    }
  }
}
