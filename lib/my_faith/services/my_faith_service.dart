// lib/my_faith/services/my_faith_service.dart
import 'package:dio/dio.dart';
import '../../services/authenticated_dio.dart';
import '../models/my_faith_models.dart';

Dio get _dio => AuthenticatedDio.instance;

class MyFaithService {
  // ─── Get Profile ──────────────────────────────────────────────

  static Future<SingleResult<FaithProfile>> getProfile(int userId) async {
    try {
      final r = await _dio.get('/faith/profile/$userId');
      final data = r.data;
      if (data['success'] == true && data['data'] != null) {
        return SingleResult(
          success: true,
          data: FaithProfile.fromJson(data['data']),
        );
      }
      return SingleResult(success: false, message: data['message']);
    } catch (e) {
      return SingleResult(success: false, message: '$e');
    }
  }

  // ─── Save / Update Profile ────────────────────────────────────

  static Future<SingleResult<FaithProfile>> saveProfile(
      Map<String, dynamic> body) async {
    try {
      final r = await _dio.post('/faith/profile', data: body);
      final data = r.data;
      if (data['success'] == true && data['data'] != null) {
        return SingleResult(
          success: true,
          data: FaithProfile.fromJson(data['data']),
        );
      }
      return SingleResult(
          success: false, message: data['message'] ?? 'Imeshindwa kuhifadhi');
    } catch (e) {
      return SingleResult(success: false, message: '$e');
    }
  }

  // ─── Spiritual Goals ──────────────────────────────────────────

  static Future<PaginatedResult<SpiritualGoal>> getGoals(
      {int page = 1}) async {
    try {
      final r =
          await _dio.get('/faith/goals', queryParameters: {'page': page});
      final data = r.data;
      if (data['success'] == true) {
        final items = (data['data'] as List)
            .map((j) => SpiritualGoal.fromJson(j))
            .toList();
        return PaginatedResult(
          success: true,
          items: items,
          currentPage: data['meta']?['current_page'] ?? page,
          lastPage: data['meta']?['last_page'] ?? 1,
        );
      }
      return PaginatedResult(success: false, message: data['message']);
    } catch (e) {
      return PaginatedResult(success: false, message: '$e');
    }
  }

  static Future<SingleResult<SpiritualGoal>> createGoal(
      Map<String, dynamic> body) async {
    try {
      final r = await _dio.post('/faith/goals', data: body);
      final data = r.data;
      if (data['success'] == true) {
        return SingleResult(
            success: true, data: SpiritualGoal.fromJson(data['data']));
      }
      return SingleResult(success: false, message: data['message']);
    } catch (e) {
      return SingleResult(success: false, message: '$e');
    }
  }

  static Future<SingleResult<void>> markGoalDay(int goalId) async {
    try {
      final r = await _dio.post('/faith/goals/$goalId/mark');
      return SingleResult(success: r.data['success'] == true);
    } catch (e) {
      return SingleResult(success: false, message: '$e');
    }
  }
}
