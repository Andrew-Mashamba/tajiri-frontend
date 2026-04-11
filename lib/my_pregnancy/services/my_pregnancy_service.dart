// lib/my_pregnancy/services/my_pregnancy_service.dart
import 'dart:convert';
import 'dart:io';
import 'package:http/http.dart' as http;
import '../../config/api_config.dart';
import '../models/my_pregnancy_models.dart';

String get _baseUrl => ApiConfig.baseUrl;

Map<String, String> _headers(String? token) {
  if (token != null) return ApiConfig.authHeaders(token);
  return {'Content-Type': 'application/json', 'Accept': 'application/json'};
}

class MyPregnancyService {
  // ─── Pregnancy CRUD ────────────────────────────────────────────

  Future<MyPregnancyResult<Pregnancy>> createPregnancy({
    required int userId,
    required DateTime lastPeriodDate,
    String? babyName,
    String? babyGender,
    double? prePregnancyWeightKg,
    String? token,
  }) async {
    try {
      final response = await http.post(
        Uri.parse('$_baseUrl/my-baby/pregnancy'),
        headers: _headers(token),
        body: jsonEncode({
          'user_id': userId,
          'last_period_date': lastPeriodDate.toIso8601String(),
          if (babyName != null) 'baby_name': babyName,
          if (babyGender != null) 'baby_gender': babyGender,
          if (prePregnancyWeightKg != null)
            'pre_pregnancy_weight_kg': prePregnancyWeightKg,
        }),
      );
      final data = jsonDecode(response.body);
      if (response.statusCode == 200 && data['success'] == true) {
        return MyPregnancyResult(
            success: true, data: Pregnancy.fromJson(data['data']));
      }
      return MyPregnancyResult(
          success: false,
          message: data['message'] ?? 'Failed to start tracking');
    } catch (e) {
      return MyPregnancyResult(success: false, message: 'Error: $e');
    }
  }

  Future<MyPregnancyResult<Pregnancy>> getMyPregnancy(int userId,
      {String? token}) async {
    try {
      final response = await http.get(
        Uri.parse('$_baseUrl/my-baby/pregnancy?user_id=$userId'),
        headers: _headers(token),
      );
      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        if (data['success'] == true && data['data'] != null) {
          return MyPregnancyResult(
              success: true, data: Pregnancy.fromJson(data['data']));
        }
      }
      return MyPregnancyResult(success: false);
    } catch (e) {
      return MyPregnancyResult(success: false, message: 'Error: $e');
    }
  }

  Future<MyPregnancyResult<Pregnancy>> updatePregnancy({
    required int pregnancyId,
    String? babyName,
    String? babyGender,
    String? status,
    String? deliveryType,
    DateTime? deliveryDate,
    int? babyWeightGrams,
    String? token,
  }) async {
    try {
      final response = await http.put(
        Uri.parse('$_baseUrl/my-baby/pregnancy/$pregnancyId'),
        headers: _headers(token),
        body: jsonEncode({
          if (babyName != null) 'baby_name': babyName,
          if (babyGender != null) 'baby_gender': babyGender,
          if (status != null) 'status': status,
          if (deliveryType != null) 'delivery_type': deliveryType,
          if (deliveryDate != null)
            'delivery_date': deliveryDate.toIso8601String(),
          if (babyWeightGrams != null) 'baby_weight_grams': babyWeightGrams,
        }),
      );
      final data = jsonDecode(response.body);
      if (response.statusCode == 200 && data['success'] == true) {
        return MyPregnancyResult(
            success: true, data: Pregnancy.fromJson(data['data']));
      }
      return MyPregnancyResult(
          success: false,
          message: data['message'] ?? 'Failed to update');
    } catch (e) {
      return MyPregnancyResult(success: false, message: 'Error: $e');
    }
  }

  // ─── Week Info ─────────────────────────────────────────────────

  Future<MyPregnancyResult<WeekInfo>> getWeekInfo(int weekNumber,
      {String? token}) async {
    try {
      final response = await http.get(
        Uri.parse('$_baseUrl/my-baby/week-info/$weekNumber'),
        headers: _headers(token),
      );
      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        if (data['success'] == true) {
          return MyPregnancyResult(
              success: true, data: WeekInfo.fromJson(data['data']));
        }
      }
      return MyPregnancyResult(
          success: false, message: 'Failed to load week info');
    } catch (e) {
      return MyPregnancyResult(success: false, message: 'Error: $e');
    }
  }

  // ─── ANC Visits ────────────────────────────────────────────────

  Future<MyPregnancyListResult<AncVisit>> getAncSchedule(int pregnancyId,
      {String? token}) async {
    try {
      final response = await http.get(
        Uri.parse('$_baseUrl/my-baby/anc-visits?pregnancy_id=$pregnancyId'),
        headers: _headers(token),
      );
      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        if (data['success'] == true) {
          final items = (data['data'] as List)
              .map((j) => AncVisit.fromJson(j))
              .toList();
          return MyPregnancyListResult(success: true, items: items);
        }
      }
      return MyPregnancyListResult(
          success: false, message: 'Failed to load ANC schedule');
    } catch (e) {
      return MyPregnancyListResult(success: false, message: 'Error: $e');
    }
  }

  Future<MyPregnancyResult<AncVisit>> markAncVisitDone(int visitId,
      {String? notes, String? facility, String? token}) async {
    try {
      final response = await http.post(
        Uri.parse('$_baseUrl/my-baby/anc-visits/$visitId/complete'),
        headers: _headers(token),
        body: jsonEncode({
          'completed_date': DateTime.now().toIso8601String(),
          if (notes != null) 'notes': notes,
          if (facility != null) 'facility': facility,
        }),
      );
      final data = jsonDecode(response.body);
      if (response.statusCode == 200 && data['success'] == true) {
        return MyPregnancyResult(
            success: true, data: AncVisit.fromJson(data['data']));
      }
      return MyPregnancyResult(
          success: false,
          message: data['message'] ?? 'Failed to complete visit');
    } catch (e) {
      return MyPregnancyResult(success: false, message: 'Error: $e');
    }
  }

  // ─── Kick Counter ──────────────────────────────────────────────

  Future<MyPregnancyResult<KickCount>> saveKickCount({
    required int pregnancyId,
    required int count,
    required int durationMinutes,
    required DateTime startTime,
    String? token,
  }) async {
    try {
      final response = await http.post(
        Uri.parse('$_baseUrl/my-baby/kick-counts'),
        headers: _headers(token),
        body: jsonEncode({
          'pregnancy_id': pregnancyId,
          'count': count,
          'duration_minutes': durationMinutes,
          'start_time': startTime.toIso8601String(),
          'date': DateTime.now().toIso8601String(),
        }),
      );
      final data = jsonDecode(response.body);
      if (response.statusCode == 200 && data['success'] == true) {
        return MyPregnancyResult(
            success: true, data: KickCount.fromJson(data['data']));
      }
      return MyPregnancyResult(
          success: false, message: data['message'] ?? 'Failed to save');
    } catch (e) {
      return MyPregnancyResult(success: false, message: 'Error: $e');
    }
  }

  Future<MyPregnancyListResult<KickCount>> getKickHistory(int pregnancyId,
      {String? token}) async {
    try {
      final response = await http.get(
        Uri.parse(
            '$_baseUrl/my-baby/kick-counts?pregnancy_id=$pregnancyId'),
        headers: _headers(token),
      );
      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        if (data['success'] == true) {
          final items = (data['data'] as List)
              .map((j) => KickCount.fromJson(j))
              .toList();
          return MyPregnancyListResult(success: true, items: items);
        }
      }
      return MyPregnancyListResult(
          success: false, message: 'Failed to load history');
    } catch (e) {
      return MyPregnancyListResult(success: false, message: 'Error: $e');
    }
  }

  // ─── Symptoms ──────────────────────────────────────────────────

  Future<MyPregnancyResult<Map<String, dynamic>>> saveSymptoms({
    required int pregnancyId,
    required int weekNumber,
    required List<String> symptoms,
    String? notes,
    int? userId,
    String? token,
  }) async {
    try {
      final response = await http.post(
        Uri.parse('$_baseUrl/my-baby/symptoms'),
        headers: _headers(token),
        body: jsonEncode({
          'pregnancy_id': pregnancyId,
          'week_number': weekNumber,
          'symptoms': symptoms,
          if (notes != null) 'notes': notes,
          if (userId != null) 'user_id': userId,
        }),
      );
      final data = jsonDecode(response.body);
      if (response.statusCode == 200 && data['success'] == true) {
        return MyPregnancyResult(success: true, data: data['data']);
      }
      return MyPregnancyResult(
          success: false,
          message: data['message'] ?? 'Failed to save symptoms');
    } catch (e) {
      return MyPregnancyResult(success: false, message: 'Error: $e');
    }
  }

  Future<MyPregnancyListResult<Map<String, dynamic>>> getSymptoms({
    required int pregnancyId,
    int? weekNumber,
    String? token,
  }) async {
    try {
      var url = '$_baseUrl/my-baby/symptoms?pregnancy_id=$pregnancyId';
      if (weekNumber != null) url += '&week_number=$weekNumber';
      final response = await http.get(
        Uri.parse(url),
        headers: _headers(token),
      );
      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        if (data['success'] == true) {
          final items = (data['data'] as List)
              .map((j) => j as Map<String, dynamic>)
              .toList();
          return MyPregnancyListResult(success: true, items: items);
        }
      }
      return MyPregnancyListResult(
          success: false, message: 'Failed to load symptoms');
    } catch (e) {
      return MyPregnancyListResult(success: false, message: 'Error: $e');
    }
  }

  // ─── Contractions ──────────────────────────────────────────────

  Future<MyPregnancyResult<void>> saveContraction({
    required int pregnancyId,
    required DateTime startTime,
    required DateTime endTime,
    required int durationSeconds,
    required String sessionId,
    int? intervalSeconds,
    String? token,
  }) async {
    try {
      final response = await http.post(
        Uri.parse('$_baseUrl/my-baby/contractions'),
        headers: _headers(token),
        body: jsonEncode({
          'pregnancy_id': pregnancyId,
          'start_time': startTime.toIso8601String(),
          'end_time': endTime.toIso8601String(),
          'duration_seconds': durationSeconds,
          'session_id': sessionId,
          if (intervalSeconds != null) 'interval_seconds': intervalSeconds,
        }),
      );
      final data = jsonDecode(response.body);
      if (response.statusCode == 200 && data['success'] == true) {
        return MyPregnancyResult(success: true);
      }
      return MyPregnancyResult(
          success: false,
          message: data['message'] ?? 'Failed to save contraction');
    } catch (e) {
      return MyPregnancyResult(success: false, message: 'Error: $e');
    }
  }

  Future<MyPregnancyListResult<Map<String, dynamic>>> getContractions({
    required int pregnancyId,
    String? sessionId,
    String? token,
  }) async {
    try {
      String url =
          '$_baseUrl/my-baby/contractions?pregnancy_id=$pregnancyId';
      if (sessionId != null) url += '&session_id=$sessionId';
      final response = await http.get(
        Uri.parse(url),
        headers: _headers(token),
      );
      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        if (data['success'] == true) {
          final items = (data['data'] as List)
              .map((j) => j as Map<String, dynamic>)
              .toList();
          return MyPregnancyListResult(success: true, items: items);
        }
      }
      return MyPregnancyListResult(
          success: false, message: 'Failed to load contractions');
    } catch (e) {
      return MyPregnancyListResult(success: false, message: 'Error: $e');
    }
  }

  // ─── Weight Tracker ────────────────────────────────────────────

  Future<MyPregnancyResult<void>> saveWeightEntry({
    required int pregnancyId,
    required double weightKg,
    required DateTime date,
    int? weekNumber,
    int? userId,
    String? notes,
    String? token,
  }) async {
    try {
      final response = await http.post(
        Uri.parse('$_baseUrl/my-baby/weights'),
        headers: _headers(token),
        body: jsonEncode({
          'pregnancy_id': pregnancyId,
          'weight_kg': weightKg,
          'measured_at': date.toIso8601String(),
          if (weekNumber != null) 'week_number': weekNumber,
          if (userId != null) 'user_id': userId,
          if (notes != null) 'notes': notes,
        }),
      );
      final data = jsonDecode(response.body);
      if (response.statusCode == 200 && data['success'] == true) {
        return MyPregnancyResult(success: true);
      }
      return MyPregnancyResult(
          success: false,
          message: data['message'] ?? 'Failed to save weight');
    } catch (e) {
      return MyPregnancyResult(success: false, message: 'Error: $e');
    }
  }

  Future<MyPregnancyListResult<Map<String, dynamic>>> getWeightEntries({
    required int pregnancyId,
    String? token,
  }) async {
    try {
      final response = await http.get(
        Uri.parse('$_baseUrl/my-baby/weights?pregnancy_id=$pregnancyId'),
        headers: _headers(token),
      );
      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        if (data['success'] == true) {
          final items = (data['data'] as List)
              .map((j) => j as Map<String, dynamic>)
              .toList();
          return MyPregnancyListResult(success: true, items: items);
        }
      }
      return MyPregnancyListResult(
          success: false, message: 'Failed to load weights');
    } catch (e) {
      return MyPregnancyListResult(success: false, message: 'Error: $e');
    }
  }

  Future<MyPregnancyResult<void>> deleteWeightEntry({
    required int entryId,
    String? token,
  }) async {
    try {
      final response = await http.delete(
        Uri.parse('$_baseUrl/my-baby/weights/$entryId'),
        headers: _headers(token),
      );
      final data = jsonDecode(response.body);
      if (response.statusCode == 200 && data['success'] == true) {
        return MyPregnancyResult(success: true);
      }
      return MyPregnancyResult(
          success: false,
          message: data['message'] ?? 'Failed to delete');
    } catch (e) {
      return MyPregnancyResult(success: false, message: 'Error: $e');
    }
  }

  // ─── Birth Plan ────────────────────────────────────────────────

  Future<MyPregnancyResult<Map<String, dynamic>>> getBirthPlan(
      int pregnancyId,
      {String? token}) async {
    try {
      final response = await http.get(
        Uri.parse('$_baseUrl/my-baby/birth-plan?pregnancy_id=$pregnancyId'),
        headers: _headers(token),
      );
      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        if (data['success'] == true && data['data'] != null) {
          return MyPregnancyResult(
            success: true,
            data: Map<String, dynamic>.from(data['data'] as Map),
          );
        }
      }
      return MyPregnancyResult(success: false);
    } catch (e) {
      return MyPregnancyResult(success: false, message: 'Error: $e');
    }
  }

  Future<MyPregnancyResult<void>> saveBirthPlan({
    required int pregnancyId,
    required int userId,
    required Map<String, dynamic> data,
    String? token,
  }) async {
    try {
      final response = await http.post(
        Uri.parse('$_baseUrl/my-baby/birth-plan'),
        headers: _headers(token),
        body: jsonEncode({
          'pregnancy_id': pregnancyId,
          'user_id': userId,
          ...data,
        }),
      );
      final body = jsonDecode(response.body);
      if (response.statusCode == 200 && body['success'] == true) {
        return MyPregnancyResult(success: true);
      }
      return MyPregnancyResult(
        success: false,
        message: body['message'] ?? 'Failed to save birth plan',
      );
    } catch (e) {
      return MyPregnancyResult(success: false, message: 'Error: $e');
    }
  }

  // ─── Mood Tracker ──────────────────────────────────────────────

  Future<MyPregnancyListResult<Map<String, dynamic>>> getMoods(
      int pregnancyId,
      {String? token}) async {
    try {
      final response = await http.get(
        Uri.parse('$_baseUrl/my-baby/moods?pregnancy_id=$pregnancyId'),
        headers: _headers(token),
      );
      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        if (data['success'] == true) {
          final items = (data['data'] as List)
              .map((j) => Map<String, dynamic>.from(j as Map))
              .toList();
          return MyPregnancyListResult(success: true, items: items);
        }
      }
      return MyPregnancyListResult(
        success: false,
        message: 'Failed to load moods',
      );
    } catch (e) {
      return MyPregnancyListResult(success: false, message: 'Error: $e');
    }
  }

  Future<MyPregnancyResult<void>> saveMood({
    required int pregnancyId,
    required int userId,
    required String mood,
    String? notes,
    String? token,
  }) async {
    try {
      final response = await http.post(
        Uri.parse('$_baseUrl/my-baby/moods'),
        headers: _headers(token),
        body: jsonEncode({
          'pregnancy_id': pregnancyId,
          'user_id': userId,
          'mood': mood,
          if (notes != null && notes.isNotEmpty) 'notes': notes,
          'date': DateTime.now().toIso8601String(),
        }),
      );
      final body = jsonDecode(response.body);
      if (response.statusCode == 200 && body['success'] == true) {
        return MyPregnancyResult(success: true);
      }
      return MyPregnancyResult(
        success: false,
        message: body['message'] ?? 'Failed to save mood',
      );
    } catch (e) {
      return MyPregnancyResult(success: false, message: 'Error: $e');
    }
  }

  // ─── Journal ───────────────────────────────────────────────────

  Future<MyPregnancyResult<void>> saveJournalEntry({
    required int pregnancyId,
    required int userId,
    required String notes,
    required DateTime date,
    File? photo,
    String? token,
  }) async {
    try {
      if (photo != null) {
        // Use multipart request when photo is attached
        final request = http.MultipartRequest(
          'POST',
          Uri.parse('$_baseUrl/my-baby/journal'),
        );
        if (token != null) {
          request.headers['Authorization'] = 'Bearer $token';
          request.headers['Accept'] = 'application/json';
        }
        request.fields['pregnancy_id'] = pregnancyId.toString();
        request.fields['user_id'] = userId.toString();
        request.fields['notes'] = notes;
        request.fields['date'] = date.toIso8601String();
        request.files.add(
          await http.MultipartFile.fromPath('photo', photo.path),
        );
        final streamedResponse = await request.send();
        final responseBody = await streamedResponse.stream.bytesToString();
        final data = jsonDecode(responseBody);
        if (streamedResponse.statusCode == 200 && data['success'] == true) {
          return MyPregnancyResult(success: true);
        }
        return MyPregnancyResult(
            success: false,
            message: data['message'] ?? 'Failed to save journal entry');
      } else {
        final response = await http.post(
          Uri.parse('$_baseUrl/my-baby/journal'),
          headers: _headers(token),
          body: jsonEncode({
            'pregnancy_id': pregnancyId,
            'user_id': userId,
            'notes': notes,
            'date': date.toIso8601String(),
          }),
        );
        final data = jsonDecode(response.body);
        if (response.statusCode == 200 && data['success'] == true) {
          return MyPregnancyResult(success: true);
        }
        return MyPregnancyResult(
            success: false,
            message: data['message'] ?? 'Failed to save journal entry');
      }
    } catch (e) {
      return MyPregnancyResult(success: false, message: 'Error: $e');
    }
  }

  Future<MyPregnancyListResult<Map<String, dynamic>>> getJournalEntries(
    int pregnancyId, {
    String? token,
  }) async {
    try {
      final response = await http.get(
        Uri.parse('$_baseUrl/my-baby/journal?pregnancy_id=$pregnancyId'),
        headers: _headers(token),
      );
      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        if (data['success'] == true) {
          final items = (data['data'] as List)
              .map((j) => j as Map<String, dynamic>)
              .toList();
          return MyPregnancyListResult(success: true, items: items);
        }
      }
      return MyPregnancyListResult(
          success: false, message: 'Failed to load journal entries');
    } catch (e) {
      return MyPregnancyListResult(success: false, message: 'Error: $e');
    }
  }

  // ─── Notifications ─────────────────────────────────────────────

  /// Fire-and-forget: ask backend to check/send pregnancy notifications.
  Future<void> checkPregnancyNotifications(int userId, {String? token}) async {
    try {
      await http.post(
        Uri.parse('$_baseUrl/my-baby/check-notifications'),
        headers: _headers(token),
        body: jsonEncode({'user_id': userId}),
      );
    } catch (_) {}
  }

  // ─── Nutrition Guide ───────────────────────────────────────────

  Future<MyPregnancyListResult<Map<String, dynamic>>> getNutritionGuide({
    String? trimester,
    String? category,
    String? token,
  }) async {
    try {
      var url = '$_baseUrl/my-baby/nutrition-guide?';
      if (trimester != null) url += 'trimester=$trimester&';
      if (category != null) url += 'category=$category&';
      final response = await http.get(
        Uri.parse(url),
        headers: _headers(token),
      );
      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        if (data['success'] == true) {
          final items = (data['data'] as List)
              .map((j) => j as Map<String, dynamic>)
              .toList();
          return MyPregnancyListResult(success: true, items: items);
        }
      }
      return MyPregnancyListResult(
          success: false, message: 'Failed to load nutrition guide');
    } catch (e) {
      return MyPregnancyListResult(success: false, message: 'Error: $e');
    }
  }
}
