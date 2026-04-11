// lib/my_baby/services/my_baby_service.dart
import 'dart:convert';
import 'package:http/http.dart' as http;
import '../../config/api_config.dart';
import '../models/my_baby_models.dart';

String get _baseUrl => ApiConfig.baseUrl;

class MyBabyService {
  // ─── Baby ──────────────────────────────────────────────────────

  Future<MyBabyResult<Baby>> registerBaby({
    required String token,
    required int userId,
    required String name,
    required DateTime dateOfBirth,
    String? gender,
    int? birthWeightGrams,
    double? birthLengthCm,
  }) async {
    try {
      final response = await http.post(
        Uri.parse('$_baseUrl/my-baby/babies'),
        headers: ApiConfig.authHeaders(token),
        body: jsonEncode({
          'user_id': userId,
          'name': name,
          'date_of_birth': dateOfBirth.toIso8601String(),
          if (gender != null) 'gender': gender,
          if (birthWeightGrams != null) 'birth_weight_grams': birthWeightGrams,
          if (birthLengthCm != null) 'birth_length_cm': birthLengthCm,
        }),
      );
      final data = jsonDecode(response.body);
      if (response.statusCode == 200 && data['success'] == true) {
        return MyBabyResult(success: true, data: Baby.fromJson(data['data']));
      }
      return MyBabyResult(
          success: false,
          message: data['message'] ?? 'Failed to register baby');
    } catch (e) {
      return MyBabyResult(success: false, message: 'Error: $e');
    }
  }

  Future<MyBabyListResult<Baby>> getMyBabies(String token, int userId) async {
    try {
      final response = await http.get(
        Uri.parse('$_baseUrl/my-baby/babies?user_id=$userId'),
        headers: ApiConfig.authHeaders(token),
      );
      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        if (data['success'] == true) {
          final items =
              (data['data'] as List).map((j) => Baby.fromJson(j)).toList();
          return MyBabyListResult(success: true, items: items);
        }
      }
      return MyBabyListResult(
          success: false, message: 'Failed to load babies');
    } catch (e) {
      return MyBabyListResult(success: false, message: 'Error: $e');
    }
  }

  Future<MyBabyResult<Baby>> updateBaby({
    required String token,
    required int babyId,
    String? name,
    String? gender,
    int? birthWeightGrams,
    String? photoUrl,
  }) async {
    try {
      final response = await http.put(
        Uri.parse('$_baseUrl/my-baby/babies/$babyId'),
        headers: ApiConfig.authHeaders(token),
        body: jsonEncode({
          if (name != null) 'name': name,
          if (gender != null) 'gender': gender,
          if (birthWeightGrams != null) 'birth_weight_grams': birthWeightGrams,
          if (photoUrl != null) 'photo_url': photoUrl,
        }),
      );
      final data = jsonDecode(response.body);
      if (response.statusCode == 200 && data['success'] == true) {
        return MyBabyResult(success: true, data: Baby.fromJson(data['data']));
      }
      return MyBabyResult(
          success: false, message: data['message'] ?? 'Failed to update');
    } catch (e) {
      return MyBabyResult(success: false, message: 'Error: $e');
    }
  }

  // ─── Vaccination ───────────────────────────────────────────────

  Future<MyBabyListResult<Vaccination>> getVaccinationSchedule(
      String token, int babyId) async {
    try {
      final response = await http.get(
        Uri.parse('$_baseUrl/my-baby/vaccinations?baby_id=$babyId'),
        headers: ApiConfig.authHeaders(token),
      );
      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        if (data['success'] == true) {
          final items = (data['data'] as List)
              .map((j) => Vaccination.fromJson(j))
              .toList();
          return MyBabyListResult(success: true, items: items);
        }
      }
      return MyBabyListResult(
          success: false, message: 'Failed to load vaccinations');
    } catch (e) {
      return MyBabyListResult(success: false, message: 'Error: $e');
    }
  }

  Future<MyBabyResult<Vaccination>> markVaccinationDone(
      String token, int vaccinationId, DateTime givenDate) async {
    try {
      final response = await http.post(
        Uri.parse(
            '$_baseUrl/my-baby/vaccinations/$vaccinationId/complete'),
        headers: ApiConfig.authHeaders(token),
        body: jsonEncode({
          'given_date': givenDate.toIso8601String(),
        }),
      );
      final data = jsonDecode(response.body);
      if (response.statusCode == 200 && data['success'] == true) {
        return MyBabyResult(
            success: true, data: Vaccination.fromJson(data['data']));
      }
      return MyBabyResult(
          success: false,
          message: data['message'] ?? 'Failed to complete vaccination');
    } catch (e) {
      return MyBabyResult(success: false, message: 'Error: $e');
    }
  }

  // ─── Milestones ────────────────────────────────────────────────

  Future<MyBabyListResult<BabyMilestone>> getMilestones(
      String token, int babyId) async {
    try {
      final response = await http.get(
        Uri.parse('$_baseUrl/my-baby/milestones?baby_id=$babyId'),
        headers: ApiConfig.authHeaders(token),
      );
      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        if (data['success'] == true) {
          final items = (data['data'] as List)
              .map((j) => BabyMilestone.fromJson(j))
              .toList();
          return MyBabyListResult(success: true, items: items);
        }
      }
      return MyBabyListResult(
          success: false, message: 'Failed to load milestones');
    } catch (e) {
      return MyBabyListResult(success: false, message: 'Error: $e');
    }
  }

  Future<MyBabyResult<BabyMilestone>> markMilestoneDone(
      String token, int milestoneId) async {
    try {
      final response = await http.post(
        Uri.parse(
            '$_baseUrl/my-baby/milestones/$milestoneId/complete'),
        headers: ApiConfig.authHeaders(token),
        body: jsonEncode({
          'completed_date': DateTime.now().toIso8601String(),
        }),
      );
      final data = jsonDecode(response.body);
      if (response.statusCode == 200 && data['success'] == true) {
        return MyBabyResult(
            success: true, data: BabyMilestone.fromJson(data['data']));
      }
      return MyBabyResult(
          success: false, message: data['message'] ?? 'Failed to complete');
    } catch (e) {
      return MyBabyResult(success: false, message: 'Error: $e');
    }
  }

  Future<MyBabyResult<BabyMilestone>> undoMilestone(
      String token, int milestoneId) async {
    try {
      final response = await http.post(
        Uri.parse(
            '$_baseUrl/my-baby/milestones/$milestoneId/undo'),
        headers: ApiConfig.authHeaders(token),
        body: jsonEncode({}),
      );
      final data = jsonDecode(response.body);
      if (response.statusCode == 200 && data['success'] == true) {
        return MyBabyResult(
            success: true, data: BabyMilestone.fromJson(data['data']));
      }
      return MyBabyResult(
          success: false, message: data['message'] ?? 'Failed to undo');
    } catch (e) {
      return MyBabyResult(success: false, message: 'Error: $e');
    }
  }

  // ─── Feeding ───────────────────────────────────────────────────

  Future<MyBabyResult<FeedingLog>> logFeeding({
    required String token,
    required int babyId,
    required FeedingType type,
    BreastSide? side,
    int? durationMinutes,
    double? amountMl,
    String? foodDescription,
  }) async {
    try {
      final response = await http.post(
        Uri.parse('$_baseUrl/my-baby/feedings'),
        headers: ApiConfig.authHeaders(token),
        body: jsonEncode({
          'baby_id': babyId,
          'type': type.name,
          if (side != null) 'side': side.name,
          if (durationMinutes != null) 'duration_minutes': durationMinutes,
          if (amountMl != null) 'amount_ml': amountMl,
          if (foodDescription != null) 'food_description': foodDescription,
          'date': DateTime.now().toIso8601String(),
        }),
      );
      final data = jsonDecode(response.body);
      if (response.statusCode == 200 && data['success'] == true) {
        return MyBabyResult(
            success: true, data: FeedingLog.fromJson(data['data']));
      }
      return MyBabyResult(
          success: false,
          message: data['message'] ?? 'Failed to save');
    } catch (e) {
      return MyBabyResult(success: false, message: 'Error: $e');
    }
  }

  Future<MyBabyListResult<FeedingLog>> getFeedingHistory(
      String token, int babyId, DateTime date) async {
    try {
      final dateStr =
          '${date.year}-${date.month.toString().padLeft(2, '0')}-${date.day.toString().padLeft(2, '0')}';
      final response = await http.get(
        Uri.parse(
            '$_baseUrl/my-baby/feedings?baby_id=$babyId&date=$dateStr'),
        headers: ApiConfig.authHeaders(token),
      );
      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        if (data['success'] == true) {
          final items = (data['data'] as List)
              .map((j) => FeedingLog.fromJson(j))
              .toList();
          return MyBabyListResult(success: true, items: items);
        }
      }
      return MyBabyListResult(
          success: false, message: 'Failed to load feeding history');
    } catch (e) {
      return MyBabyListResult(success: false, message: 'Error: $e');
    }
  }

  // ─── Sleep ─────────────────────────────────────────────────────

  Future<MyBabyResult<SleepSession>> logSleep({
    required String token,
    required int babyId,
    required DateTime startTime,
    DateTime? endTime,
    String type = 'nap',
    String? notes,
  }) async {
    try {
      final response = await http.post(
        Uri.parse('$_baseUrl/my-baby/sleep'),
        headers: ApiConfig.authHeaders(token),
        body: jsonEncode({
          'baby_id': babyId,
          'start_time': startTime.toIso8601String(),
          if (endTime != null) 'end_time': endTime.toIso8601String(),
          'type': type,
          if (notes != null) 'notes': notes,
        }),
      );
      final data = jsonDecode(response.body);
      if (response.statusCode == 200 && data['success'] == true) {
        return MyBabyResult(
            success: true, data: SleepSession.fromJson(data['data']));
      }
      return MyBabyResult(
          success: false,
          message: data['message'] ?? 'Failed to log sleep');
    } catch (e) {
      return MyBabyResult(success: false, message: 'Error: $e');
    }
  }

  Future<MyBabyResult<SleepSession>> updateSleep({
    required String token,
    required int sessionId,
    DateTime? endTime,
    String? notes,
  }) async {
    try {
      final response = await http.put(
        Uri.parse('$_baseUrl/my-baby/sleep/$sessionId'),
        headers: ApiConfig.authHeaders(token),
        body: jsonEncode({
          if (endTime != null) 'end_time': endTime.toIso8601String(),
          if (notes != null) 'notes': notes,
        }),
      );
      final data = jsonDecode(response.body);
      if (response.statusCode == 200 && data['success'] == true) {
        return MyBabyResult(
            success: true, data: SleepSession.fromJson(data['data']));
      }
      return MyBabyResult(
          success: false,
          message: data['message'] ?? 'Failed to update sleep');
    } catch (e) {
      return MyBabyResult(success: false, message: 'Error: $e');
    }
  }

  Future<MyBabyListResult<SleepSession>> getSleepHistory(
      String token, int babyId, {DateTime? date}) async {
    try {
      String url = '$_baseUrl/my-baby/sleep?baby_id=$babyId';
      if (date != null) {
        final dateStr =
            '${date.year}-${date.month.toString().padLeft(2, '0')}-${date.day.toString().padLeft(2, '0')}';
        url += '&date=$dateStr';
      }
      final response = await http.get(
        Uri.parse(url),
        headers: ApiConfig.authHeaders(token),
      );
      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        if (data['success'] == true) {
          final items = (data['data'] as List)
              .map((j) => SleepSession.fromJson(j))
              .toList();
          return MyBabyListResult(success: true, items: items);
        }
      }
      return MyBabyListResult(
          success: false, message: 'Failed to load sleep history');
    } catch (e) {
      return MyBabyListResult(success: false, message: 'Error: $e');
    }
  }

  // ─── Diapers ───────────────────────────────────────────────────

  Future<MyBabyResult<DiaperLog>> logDiaper({
    required String token,
    required int babyId,
    required String type,
    String? color,
    String? notes,
  }) async {
    try {
      final response = await http.post(
        Uri.parse('$_baseUrl/my-baby/diapers'),
        headers: ApiConfig.authHeaders(token),
        body: jsonEncode({
          'baby_id': babyId,
          'type': type,
          if (color != null) 'color': color,
          if (notes != null) 'notes': notes,
        }),
      );
      final data = jsonDecode(response.body);
      if (response.statusCode == 200 && data['success'] == true) {
        return MyBabyResult(
            success: true, data: DiaperLog.fromJson(data['data']));
      }
      return MyBabyResult(
          success: false,
          message: data['message'] ?? 'Failed to log diaper');
    } catch (e) {
      return MyBabyResult(success: false, message: 'Error: $e');
    }
  }

  Future<MyBabyListResult<DiaperLog>> getDiaperHistory(
      String token, int babyId, {DateTime? date}) async {
    try {
      String url = '$_baseUrl/my-baby/diapers?baby_id=$babyId';
      if (date != null) {
        final dateStr =
            '${date.year}-${date.month.toString().padLeft(2, '0')}-${date.day.toString().padLeft(2, '0')}';
        url += '&date=$dateStr';
      }
      final response = await http.get(
        Uri.parse(url),
        headers: ApiConfig.authHeaders(token),
      );
      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        if (data['success'] == true) {
          final items = (data['data'] as List)
              .map((j) => DiaperLog.fromJson(j))
              .toList();
          return MyBabyListResult(success: true, items: items);
        }
      }
      return MyBabyListResult(
          success: false, message: 'Failed to load diaper history');
    } catch (e) {
      return MyBabyListResult(success: false, message: 'Error: $e');
    }
  }

  // ─── Growth ────────────────────────────────────────────────────

  Future<MyBabyResult<GrowthMeasurement>> logGrowth({
    required String token,
    required int babyId,
    double? weightKg,
    double? heightCm,
    double? headCm,
    required DateTime measuredAt,
    String? notes,
  }) async {
    try {
      final response = await http.post(
        Uri.parse('$_baseUrl/my-baby/growth'),
        headers: ApiConfig.authHeaders(token),
        body: jsonEncode({
          'baby_id': babyId,
          if (weightKg != null) 'weight_kg': weightKg,
          if (heightCm != null) 'height_cm': heightCm,
          if (headCm != null) 'head_cm': headCm,
          'measured_at': measuredAt.toIso8601String(),
          if (notes != null) 'notes': notes,
        }),
      );
      final data = jsonDecode(response.body);
      if (response.statusCode == 200 && data['success'] == true) {
        return MyBabyResult(
            success: true, data: GrowthMeasurement.fromJson(data['data']));
      }
      return MyBabyResult(
          success: false,
          message: data['message'] ?? 'Failed to save growth');
    } catch (e) {
      return MyBabyResult(success: false, message: 'Error: $e');
    }
  }

  Future<MyBabyListResult<GrowthMeasurement>> getGrowthHistory(
      String token, int babyId) async {
    try {
      final response = await http.get(
        Uri.parse('$_baseUrl/my-baby/growth?baby_id=$babyId'),
        headers: ApiConfig.authHeaders(token),
      );
      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        if (data['success'] == true) {
          final items = (data['data'] as List)
              .map((j) => GrowthMeasurement.fromJson(j))
              .toList();
          return MyBabyListResult(success: true, items: items);
        }
      }
      return MyBabyListResult(
          success: false, message: 'Failed to load growth data');
    } catch (e) {
      return MyBabyListResult(success: false, message: 'Error: $e');
    }
  }

  // ─── Health Logs ───────────────────────────────────────────────

  Future<MyBabyResult<HealthLog>> logHealth({
    required String token,
    required int babyId,
    required String type,
    required String title,
    String? value,
    String? description,
    DateTime? loggedAt,
  }) async {
    try {
      final response = await http.post(
        Uri.parse('$_baseUrl/my-baby/health-logs'),
        headers: ApiConfig.authHeaders(token),
        body: jsonEncode({
          'baby_id': babyId,
          'type': type,
          'title': title,
          if (value != null) 'value': value,
          if (description != null) 'description': description,
          'logged_at': (loggedAt ?? DateTime.now()).toIso8601String(),
        }),
      );
      final data = jsonDecode(response.body);
      if (response.statusCode == 200 && data['success'] == true) {
        return MyBabyResult(
            success: true, data: HealthLog.fromJson(data['data']));
      }
      return MyBabyResult(
          success: false,
          message: data['message'] ?? 'Failed to log health entry');
    } catch (e) {
      return MyBabyResult(success: false, message: 'Error: $e');
    }
  }

  Future<MyBabyListResult<HealthLog>> getHealthHistory(
      String token, int babyId, {String? type}) async {
    try {
      String url = '$_baseUrl/my-baby/health-logs?baby_id=$babyId';
      if (type != null) url += '&type=$type';
      final response = await http.get(
        Uri.parse(url),
        headers: ApiConfig.authHeaders(token),
      );
      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        if (data['success'] == true) {
          final items = (data['data'] as List)
              .map((j) => HealthLog.fromJson(j))
              .toList();
          return MyBabyListResult(success: true, items: items);
        }
      }
      return MyBabyListResult(
          success: false, message: 'Failed to load health history');
    } catch (e) {
      return MyBabyListResult(success: false, message: 'Error: $e');
    }
  }

  // ─── Photos ────────────────────────────────────────────────────

  Future<MyBabyListResult<BabyPhoto>> getPhotos(
      String token, int babyId, {String? type}) async {
    try {
      String url = '$_baseUrl/my-baby/photos?baby_id=$babyId';
      if (type != null) url += '&type=$type';
      final response = await http.get(
        Uri.parse(url),
        headers: ApiConfig.authHeaders(token),
      );
      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        if (data['success'] == true) {
          final items = (data['data'] as List)
              .map((j) => BabyPhoto.fromJson(j))
              .toList();
          return MyBabyListResult(success: true, items: items);
        }
      }
      return MyBabyListResult(
          success: false, message: 'Failed to load photos');
    } catch (e) {
      return MyBabyListResult(success: false, message: 'Error: $e');
    }
  }

  Future<MyBabyResult<BabyPhoto>> uploadPhoto({
    required String token,
    required int babyId,
    required String filePath,
    String type = 'memory',
    int? monthNumber,
    String? caption,
    String? milestoneKey,
  }) async {
    try {
      final uri = Uri.parse('$_baseUrl/my-baby/photos');
      final request = http.MultipartRequest('POST', uri)
        ..headers.addAll(ApiConfig.authHeaders(token))
        ..fields['baby_id'] = '$babyId'
        ..fields['type'] = type
        ..files.add(await http.MultipartFile.fromPath('photo', filePath));
      if (monthNumber != null) request.fields['month_number'] = '$monthNumber';
      if (caption != null) request.fields['caption'] = caption;
      if (milestoneKey != null) request.fields['milestone_key'] = milestoneKey;

      final streamed = await request.send();
      final responseBody = await streamed.stream.bytesToString();
      final data = jsonDecode(responseBody);
      if (streamed.statusCode == 200 && data['success'] == true) {
        return MyBabyResult(
            success: true, data: BabyPhoto.fromJson(data['data']));
      }
      return MyBabyResult(
          success: false,
          message: data['message'] ?? 'Failed to upload photo');
    } catch (e) {
      return MyBabyResult(success: false, message: 'Error: $e');
    }
  }

  // ─── Caregiver Sharing ─────────────────────────────────────────

  Future<MyBabyResult<CaregiverShare>> inviteCaregiver({
    required String token,
    required int babyId,
    required int ownerUserId,
    String role = 'caregiver',
  }) async {
    try {
      final response = await http.post(
        Uri.parse('$_baseUrl/my-baby/caregivers/invite'),
        headers: ApiConfig.authHeaders(token),
        body: jsonEncode({
          'baby_id': babyId,
          'owner_user_id': ownerUserId,
          'role': role,
        }),
      );
      final data = jsonDecode(response.body);
      if (response.statusCode == 200 && data['success'] == true) {
        return MyBabyResult(
            success: true, data: CaregiverShare.fromJson(data['data']));
      }
      return MyBabyResult(
          success: false,
          message: data['message'] ?? 'Failed to create invite');
    } catch (e) {
      return MyBabyResult(success: false, message: 'Error: $e');
    }
  }

  Future<MyBabyResult<CaregiverShare>> acceptInvite({
    required String token,
    required String inviteCode,
    required int caregiverUserId,
  }) async {
    try {
      final response = await http.post(
        Uri.parse('$_baseUrl/my-baby/caregivers/accept'),
        headers: ApiConfig.authHeaders(token),
        body: jsonEncode({
          'invite_code': inviteCode,
          'caregiver_user_id': caregiverUserId,
        }),
      );
      final data = jsonDecode(response.body);
      if (response.statusCode == 200 && data['success'] == true) {
        return MyBabyResult(
            success: true, data: CaregiverShare.fromJson(data['data']));
      }
      return MyBabyResult(
          success: false,
          message: data['message'] ?? 'Invalid invite code');
    } catch (e) {
      return MyBabyResult(success: false, message: 'Error: $e');
    }
  }

  Future<MyBabyListResult<CaregiverShare>> listCaregivers(
      String token, int babyId) async {
    try {
      final response = await http.get(
        Uri.parse('$_baseUrl/my-baby/caregivers?baby_id=$babyId'),
        headers: ApiConfig.authHeaders(token),
      );
      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        if (data['success'] == true) {
          final items = (data['data'] as List)
              .map((j) => CaregiverShare.fromJson(j))
              .toList();
          return MyBabyListResult(success: true, items: items);
        }
      }
      return MyBabyListResult(
          success: false, message: 'Failed to load caregivers');
    } catch (e) {
      return MyBabyListResult(success: false, message: 'Error: $e');
    }
  }

  Future<MyBabyResult<void>> revokeCaregiver(String token, int shareId) async {
    try {
      final response = await http.delete(
        Uri.parse('$_baseUrl/my-baby/caregivers/$shareId'),
        headers: ApiConfig.authHeaders(token),
      );
      final data = jsonDecode(response.body);
      if (response.statusCode == 200 && data['success'] == true) {
        return MyBabyResult(success: true);
      }
      return MyBabyResult(
          success: false,
          message: data['message'] ?? 'Failed to revoke access');
    } catch (e) {
      return MyBabyResult(success: false, message: 'Error: $e');
    }
  }

  // ─── Feeding Reminders ─────────────────────────────────────────

  Future<void> scheduleNextFeedReminder(int babyId, DateTime nextFeedTime,
      {String? token}) async {
    try {
      await http.post(
        Uri.parse('$_baseUrl/my-baby/reminders/feeding'),
        headers: ApiConfig.authHeaders(token ?? ''),
        body: jsonEncode({
          'baby_id': babyId,
          'remind_at': nextFeedTime.toIso8601String(),
        }),
      );
    } catch (_) {}
  }

  // ─── Summary ───────────────────────────────────────────────────

  Future<Map<String, dynamic>?> getDailySummary(
      String token, int babyId, {DateTime? date}) async {
    try {
      String url = '$_baseUrl/my-baby/summary?baby_id=$babyId';
      if (date != null) {
        final dateStr =
            '${date.year}-${date.month.toString().padLeft(2, '0')}-${date.day.toString().padLeft(2, '0')}';
        url += '&date=$dateStr';
      }
      final response = await http.get(
        Uri.parse(url),
        headers: ApiConfig.authHeaders(token),
      );
      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        if (data['success'] == true) {
          return data['data'] as Map<String, dynamic>;
        }
      }
      return null;
    } catch (e) {
      return null;
    }
  }
}
