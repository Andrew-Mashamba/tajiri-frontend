// lib/fitness/services/fitness_service.dart
import 'dart:convert';
import 'package:http/http.dart' as http;
import '../../config/api_config.dart';
import '../models/fitness_models.dart';

String get _baseUrl => ApiConfig.baseUrl;

class FitnessService {
  // ─── Gyms ──────────────────────────────────────────────────────

  Future<FitnessListResult<Gym>> findGyms({
    String? search,
    String? workoutType,
    bool? hasStreaming,
    double? latitude,
    double? longitude,
    int page = 1,
  }) async {
    try {
      final params = <String, String>{'page': '$page'};
      if (search != null && search.isNotEmpty) params['search'] = search;
      if (workoutType != null) params['workout_type'] = workoutType;
      if (hasStreaming == true) params['streaming'] = '1';
      if (latitude != null) params['latitude'] = '$latitude';
      if (longitude != null) params['longitude'] = '$longitude';

      final uri = Uri.parse('$_baseUrl/fitness/gyms').replace(queryParameters: params);
      final response = await http.get(uri);
      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        if (data['success'] == true) {
          return FitnessListResult(success: true, items: (data['data'] as List).map((j) => Gym.fromJson(j)).toList());
        }
      }
      return FitnessListResult(success: false, message: 'Imeshindwa kupakia gym');
    } catch (e) {
      return FitnessListResult(success: false, message: 'Kosa: $e');
    }
  }

  Future<FitnessResult<Gym>> getGymDetail(int gymId) async {
    try {
      final response = await http.get(Uri.parse('$_baseUrl/fitness/gyms/$gymId'));
      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        if (data['success'] == true) return FitnessResult(success: true, data: Gym.fromJson(data['data']));
      }
      return FitnessResult(success: false);
    } catch (e) {
      return FitnessResult(success: false);
    }
  }

  // ─── Memberships ───────────────────────────────────────────────

  Future<FitnessResult<GymMembership>> subscribe({
    required int userId,
    required int gymId,
    required String frequency,
    required String paymentMethod,
    String? phoneNumber,
  }) async {
    try {
      final response = await http.post(
        Uri.parse('$_baseUrl/fitness/memberships'),
        headers: {'Content-Type': 'application/json'},
        body: jsonEncode({
          'user_id': userId, 'gym_id': gymId, 'frequency': frequency,
          'payment_method': paymentMethod, if (phoneNumber != null) 'phone_number': phoneNumber,
        }),
      );
      final data = jsonDecode(response.body);
      if (response.statusCode == 200 && data['success'] == true) {
        return FitnessResult(success: true, data: GymMembership.fromJson(data['data']));
      }
      return FitnessResult(success: false, message: data['message'] ?? 'Imeshindwa kujisajili');
    } catch (e) {
      return FitnessResult(success: false, message: 'Kosa: $e');
    }
  }

  Future<FitnessListResult<GymMembership>> getMyMemberships(int userId) async {
    try {
      final response = await http.get(Uri.parse('$_baseUrl/fitness/memberships?user_id=$userId'));
      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        if (data['success'] == true) {
          return FitnessListResult(success: true, items: (data['data'] as List).map((j) => GymMembership.fromJson(j)).toList());
        }
      }
      return FitnessListResult(success: false);
    } catch (e) {
      return FitnessListResult(success: false);
    }
  }

  Future<FitnessResult<void>> cancelMembership(int membershipId) async {
    try {
      final response = await http.post(Uri.parse('$_baseUrl/fitness/memberships/$membershipId/cancel'), headers: {'Content-Type': 'application/json'});
      final data = jsonDecode(response.body);
      if (response.statusCode == 200 && data['success'] == true) return FitnessResult(success: true);
      return FitnessResult(success: false, message: data['message'] ?? 'Imeshindwa');
    } catch (e) {
      return FitnessResult(success: false, message: 'Kosa: $e');
    }
  }

  // ─── Classes (Live & On-Demand) ────────────────────────────────

  Future<FitnessListResult<FitnessClass>> getClasses({
    int? gymId,
    String? workoutType,
    bool? liveOnly,
    bool? recordedOnly,
    int page = 1,
  }) async {
    try {
      final params = <String, String>{'page': '$page'};
      if (gymId != null) params['gym_id'] = '$gymId';
      if (workoutType != null) params['workout_type'] = workoutType;
      if (liveOnly == true) params['live'] = '1';
      if (recordedOnly == true) params['recorded'] = '1';

      final uri = Uri.parse('$_baseUrl/fitness/classes').replace(queryParameters: params);
      final response = await http.get(uri);
      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        if (data['success'] == true) {
          return FitnessListResult(success: true, items: (data['data'] as List).map((j) => FitnessClass.fromJson(j)).toList());
        }
      }
      return FitnessListResult(success: false);
    } catch (e) {
      return FitnessListResult(success: false);
    }
  }

  Future<FitnessListResult<FitnessClass>> getUpcomingClasses(int userId) async {
    try {
      final response = await http.get(Uri.parse('$_baseUrl/fitness/classes/upcoming?user_id=$userId'));
      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        if (data['success'] == true) {
          return FitnessListResult(success: true, items: (data['data'] as List).map((j) => FitnessClass.fromJson(j)).toList());
        }
      }
      return FitnessListResult(success: false);
    } catch (e) {
      return FitnessListResult(success: false);
    }
  }

  // ─── Workout Logging & Stats ───────────────────────────────────

  Future<FitnessResult<WorkoutLog>> logWorkout({
    required int userId,
    required WorkoutType type,
    required int durationMinutes,
    int? caloriesBurned,
    String? notes,
    int? gymId,
    int? classId,
  }) async {
    try {
      final response = await http.post(
        Uri.parse('$_baseUrl/fitness/workouts'),
        headers: {'Content-Type': 'application/json'},
        body: jsonEncode({
          'user_id': userId, 'type': type.name, 'duration_minutes': durationMinutes,
          if (caloriesBurned != null) 'calories_burned': caloriesBurned,
          if (notes != null) 'notes': notes,
          if (gymId != null) 'gym_id': gymId,
          if (classId != null) 'class_id': classId,
        }),
      );
      final data = jsonDecode(response.body);
      if (response.statusCode == 200 && data['success'] == true) {
        return FitnessResult(success: true, data: WorkoutLog.fromJson(data['data']));
      }
      return FitnessResult(success: false, message: data['message'] ?? 'Imeshindwa kuhifadhi');
    } catch (e) {
      return FitnessResult(success: false, message: 'Kosa: $e');
    }
  }

  Future<FitnessListResult<WorkoutLog>> getWorkoutHistory(int userId, {int page = 1}) async {
    try {
      final response = await http.get(Uri.parse('$_baseUrl/fitness/workouts?user_id=$userId&page=$page'));
      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        if (data['success'] == true) {
          return FitnessListResult(success: true, items: (data['data'] as List).map((j) => WorkoutLog.fromJson(j)).toList());
        }
      }
      return FitnessListResult(success: false);
    } catch (e) {
      return FitnessListResult(success: false);
    }
  }

  Future<FitnessResult<FitnessStats>> getStats(int userId) async {
    try {
      final response = await http.get(Uri.parse('$_baseUrl/fitness/stats?user_id=$userId'));
      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        if (data['success'] == true) return FitnessResult(success: true, data: FitnessStats.fromJson(data['data']));
      }
      return FitnessResult(success: false);
    } catch (e) {
      return FitnessResult(success: false);
    }
  }
}
