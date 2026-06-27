import '../../fitness/models/fitness_models.dart';
import 'tajiri_graphql_client.dart';

/// GraphQL fitness workouts (Phase 72 — backend rev 208).
/// Gym/membership/class marketplace remains REST-only.
class GraphqlFitnessService {
  static const _workoutFields = r'''
    id
    type
    durationMinutes
    caloriesBurned
    notes
    workoutDate
    gymId
    classId
  ''';

  static const _statsFields = r'''
    totalWorkouts
    totalMinutes
    totalCalories
    currentStreak
    bestStreak
    thisWeekWorkouts
    thisWeekMinutes
    weeklyGoalMinutes
  ''';

  static final Map<int, String?> _workoutCursors = {};

  static Map<String, dynamic> _workoutToLegacy(Map<String, dynamic> row) {
    return {
      'id': int.tryParse(row['id']?.toString() ?? '') ?? 0,
      'user_id': 0,
      'type': row['type'],
      'duration_minutes': row['durationMinutes'],
      'calories_burned': row['caloriesBurned'],
      'notes': row['notes'],
      'date': row['workoutDate'],
      if (row['gymId'] != null) 'gym_id': row['gymId'],
      if (row['classId'] != null) 'class_id': row['classId'],
    };
  }

  static Map<String, dynamic> _statsToLegacy(Map<String, dynamic> row) {
    return {
      'total_workouts': row['totalWorkouts'],
      'total_minutes': row['totalMinutes'],
      'total_calories': row['totalCalories'],
      'current_streak': row['currentStreak'],
      'best_streak': row['bestStreak'],
      'this_week_workouts': row['thisWeekWorkouts'],
      'this_week_minutes': row['thisWeekMinutes'],
      'weekly_goal_minutes': row['weeklyGoalMinutes'],
    };
  }

  static Future<FitnessResult<WorkoutLog>> logWorkout({
    required WorkoutType type,
    required int durationMinutes,
    int? caloriesBurned,
    String? notes,
    int? gymId,
    int? classId,
    DateTime? date,
  }) async {
    try {
      final result = await TajiriGraphqlClient.instance.mutate(
        '''
        mutation LogWorkout(\$input: LogWorkoutInput!) {
          logWorkout(input: \$input) {
            $_workoutFields
          }
        }
        ''',
        variables: {
          'input': {
            'type': type.name,
            'durationMinutes': durationMinutes,
            if (caloriesBurned != null) 'caloriesBurned': caloriesBurned,
            if (notes != null) 'notes': notes,
            if (gymId != null) 'gymId': gymId.toString(),
            if (classId != null) 'classId': classId.toString(),
            if (date != null) 'date': date.toIso8601String(),
          },
        },
        auth: true,
      );
      final row = result['logWorkout'] as Map<String, dynamic>?;
      if (row == null) {
        return FitnessResult(success: false, message: 'Imeshindwa kurekodi');
      }
      return FitnessResult(
        success: true,
        data: WorkoutLog.fromJson(_workoutToLegacy(row)),
      );
    } catch (e) {
      return FitnessResult(success: false, message: '$e');
    }
  }

  static Future<FitnessListResult<WorkoutLog>> getWorkoutHistory({
    int page = 1,
  }) async {
    try {
      if (page == 1) _workoutCursors.clear();
      final cursor = page > 1 ? _workoutCursors[page] : null;
      if (page > 1 && cursor == null) {
        return FitnessListResult(success: true, items: const []);
      }

      final data = await TajiriGraphqlClient.instance.query(
        '''
        query MyWorkouts(\$cursor: String) {
          myWorkouts(cursor: \$cursor) {
            items { $_workoutFields }
            nextCursor
            hasMore
          }
        }
        ''',
        variables: {if (cursor != null) 'cursor': cursor},
        auth: true,
      );
      final conn = data['myWorkouts'] as Map<String, dynamic>? ?? {};
      final rows = conn['items'] as List<dynamic>? ?? [];
      final items = rows
          .whereType<Map<String, dynamic>>()
          .map((row) => WorkoutLog.fromJson(_workoutToLegacy(row)))
          .toList();
      final hasMore = conn['hasMore'] == true;
      final nextCursor = conn['nextCursor']?.toString();
      if (hasMore && nextCursor != null) _workoutCursors[page + 1] = nextCursor;
      return FitnessListResult(success: true, items: items);
    } catch (e) {
      return FitnessListResult(success: false, message: '$e');
    }
  }

  static Future<FitnessResult<FitnessStats>> getStats() async {
    try {
      final data = await TajiriGraphqlClient.instance.query(
        '''
        query MyFitnessStats {
          myFitnessStats {
            $_statsFields
          }
        }
        ''',
        auth: true,
      );
      final row = data['myFitnessStats'] as Map<String, dynamic>?;
      if (row == null) {
        return FitnessResult(success: false, message: 'Hakuna takwimu');
      }
      return FitnessResult(
        success: true,
        data: FitnessStats.fromJson(_statsToLegacy(row)),
      );
    } catch (e) {
      return FitnessResult(success: false, message: '$e');
    }
  }
}
