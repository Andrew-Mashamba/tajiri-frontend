import '../../my_circle/models/my_circle_models.dart';
import 'tajiri_graphql_client.dart';

/// GraphQL my circle / cycle tracking (Phase 77 — backend rev 211).
/// Settings, partner sharing, stop/resume tracking, and notifications remain REST-only.
class GraphqlMyCircleService {
  static const _cycleDayFields = r'''
    id
    date
    flowIntensity
    symptoms
    mood
    notes
  ''';

  static const _predictionFields = r'''
    nextPeriodDate
    fertileWindowStart
    fertileWindowEnd
    ovulationDate
    cycleLength
    periodLength
    totalCyclesLogged
  ''';

  static const _statsFields = r'''
    averageCycleLength
    averagePeriodLength
    longestCycle
    shortestCycle
    totalCyclesLogged
    cycleLengthHistory
    symptomFrequency
    moodFrequency
  ''';

  static const _reminderFields = r'''
    id
    type
    startDate
    nextDueDate
    intervalDays
    active
  ''';

  static Map<String, dynamic> _cycleDayToLegacy(Map<String, dynamic> row) {
    return {
      'id': int.tryParse(row['id']?.toString() ?? '') ?? 0,
      'user_id': 0,
      'date': row['date'],
      'flow_intensity': row['flowIntensity'],
      'symptoms': row['symptoms'] ?? [],
      'mood': row['mood'],
      'notes': row['notes'],
    };
  }

  static Map<String, dynamic> _predictionToLegacy(Map<String, dynamic> row) {
    return {
      'next_period_date': row['nextPeriodDate'],
      'fertile_window_start': row['fertileWindowStart'],
      'fertile_window_end': row['fertileWindowEnd'],
      'ovulation_date': row['ovulationDate'],
      'cycle_length': row['cycleLength'],
      'period_length': row['periodLength'],
      'total_cycles_logged': row['totalCyclesLogged'],
    };
  }

  static Map<String, dynamic> _statsToLegacy(Map<String, dynamic> row) {
    return {
      'average_cycle_length': row['averageCycleLength'],
      'average_period_length': row['averagePeriodLength'],
      'longest_cycle': row['longestCycle'],
      'shortest_cycle': row['shortestCycle'],
      'total_cycles_logged': row['totalCyclesLogged'],
      'cycle_length_history': row['cycleLengthHistory'] ?? [],
      'symptom_frequency': row['symptomFrequency'] ?? {},
      'mood_frequency': row['moodFrequency'] ?? {},
    };
  }

  static Map<String, dynamic> _reminderToLegacy(Map<String, dynamic> row) {
    return {
      'id': int.tryParse(row['id']?.toString() ?? '') ?? 0,
      'user_id': 0,
      'type': row['type'],
      'start_date': row['startDate'],
      'next_due_date': row['nextDueDate'],
      'interval_days': row['intervalDays'],
    };
  }

  static String _formatDate(DateTime d) =>
      '${d.year}-${d.month.toString().padLeft(2, '0')}-${d.day.toString().padLeft(2, '0')}';

  static Future<CircleResult<CycleDay>> logCycleDay({
    required DateTime date,
    required FlowIntensity flowIntensity,
    List<Symptom> symptoms = const [],
    Mood? mood,
    String? notes,
  }) async {
    try {
      final data = await TajiriGraphqlClient.instance.mutate(
        '''
        mutation LogCycleDay(\$input: LogCycleDayInput!) {
          logCycleDay(input: \$input) {
            $_cycleDayFields
          }
        }
        ''',
        variables: {
          'input': {
            'date': _formatDate(date),
            'flowIntensity': flowIntensity.name,
            'symptoms': symptoms.map((s) => s.name).toList(),
            if (mood != null) 'mood': mood.name,
            if (notes != null && notes.isNotEmpty) 'notes': notes,
          },
        },
        auth: true,
      );
      final row = data['logCycleDay'] as Map<String, dynamic>?;
      if (row == null) {
        return CircleResult(success: false, message: 'Imeshindwa kuhifadhi');
      }
      return CircleResult(
        success: true,
        data: CycleDay.fromJson(_cycleDayToLegacy(row)),
      );
    } catch (e) {
      return CircleResult(success: false, message: 'Kosa: $e');
    }
  }

  static Future<CircleListResult<CycleDay>> getCycleDays({
    required int month,
    required int year,
  }) async {
    try {
      final dateFrom = DateTime(year, month, 1);
      final dateTo = DateTime(year, month + 1, 0);
      final data = await TajiriGraphqlClient.instance.query(
        '''
        query MyCycleDays(\$dateFrom: String, \$dateTo: String) {
          myCycleDays(dateFrom: \$dateFrom, dateTo: \$dateTo) {
            $_cycleDayFields
          }
        }
        ''',
        variables: {
          'dateFrom': _formatDate(dateFrom),
          'dateTo': _formatDate(dateTo),
        },
        auth: true,
      );
      final rows = data['myCycleDays'] as List<dynamic>? ?? [];
      final items = rows
          .whereType<Map<String, dynamic>>()
          .map((row) => CycleDay.fromJson(_cycleDayToLegacy(row)))
          .toList();
      return CircleListResult(success: true, items: items);
    } catch (e) {
      return CircleListResult(success: false, message: 'Kosa: $e');
    }
  }

  static Future<CircleResult<CyclePrediction>> getPredictions() async {
    try {
      final data = await TajiriGraphqlClient.instance.query(
        '''
        query CyclePredictions {
          cyclePredictions {
            $_predictionFields
          }
        }
        ''',
        auth: true,
      );
      final row = data['cyclePredictions'] as Map<String, dynamic>?;
      if (row == null) {
        return CircleResult(success: false, message: 'Imeshindwa kupakia utabiri');
      }
      return CircleResult(
        success: true,
        data: CyclePrediction.fromJson(_predictionToLegacy(row)),
      );
    } catch (e) {
      return CircleResult(success: false, message: 'Kosa: $e');
    }
  }

  static Future<CircleResult<CycleStats>> getStats() async {
    try {
      final data = await TajiriGraphqlClient.instance.query(
        '''
        query CycleStats {
          cycleStats {
            $_statsFields
          }
        }
        ''',
        auth: true,
      );
      final row = data['cycleStats'] as Map<String, dynamic>?;
      if (row == null) {
        return CircleResult(success: false, message: 'Imeshindwa kupakia takwimu');
      }
      return CircleResult(
        success: true,
        data: CycleStats.fromJson(_statsToLegacy(row)),
      );
    } catch (e) {
      return CircleResult(success: false, message: 'Kosa: $e');
    }
  }

  static Future<CircleResult<ContraceptionReminder>> setContraceptionReminder({
    required ContraceptionType type,
    required DateTime startDate,
    required int intervalDays,
  }) async {
    try {
      final data = await TajiriGraphqlClient.instance.mutate(
        '''
        mutation CreateContraceptionReminder(\$input: CreateContraceptionReminderInput!) {
          createContraceptionReminder(input: \$input) {
            $_reminderFields
          }
        }
        ''',
        variables: {
          'input': {
            'type': type.name,
            'startDate': _formatDate(startDate),
            'intervalDays': intervalDays,
          },
        },
        auth: true,
      );
      final row = data['createContraceptionReminder'] as Map<String, dynamic>?;
      if (row == null) {
        return CircleResult(success: false, message: 'Imeshindwa kuhifadhi');
      }
      return CircleResult(
        success: true,
        data: ContraceptionReminder.fromJson(_reminderToLegacy(row)),
      );
    } catch (e) {
      return CircleResult(success: false, message: 'Kosa: $e');
    }
  }

  static Future<CircleListResult<ContraceptionReminder>> getContraceptionReminders() async {
    try {
      final data = await TajiriGraphqlClient.instance.query(
        '''
        query MyContraceptionReminders {
          myContraceptionReminders {
            $_reminderFields
          }
        }
        ''',
        auth: true,
      );
      final rows = data['myContraceptionReminders'] as List<dynamic>? ?? [];
      final items = rows
          .whereType<Map<String, dynamic>>()
          .map((row) => ContraceptionReminder.fromJson(_reminderToLegacy(row)))
          .toList();
      return CircleListResult(success: true, items: items);
    } catch (e) {
      return CircleListResult(success: false, message: 'Kosa: $e');
    }
  }
}
