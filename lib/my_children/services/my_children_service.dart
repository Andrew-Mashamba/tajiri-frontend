// lib/my_children/services/my_children_service.dart
import 'dart:convert';
import 'package:http/http.dart' as http;
import '../../config/api_config.dart';
import '../models/my_children_models.dart';
import '../models/school_age_models.dart';

String get _baseUrl => ApiConfig.baseUrl;

class MyChildrenService {
  // ─── Baby ──────────────────────────────────────────────────────

  Future<MyBabyResult<Baby>> registerBaby({
    required String token,
    required int userId,
    required String name,
    required DateTime dateOfBirth,
    String? gender,
    int? birthWeightGrams,
    double? birthLengthCm,
    String? bloodType,
    String? schoolName,
    String? grade,
    List<String>? allergies,
    List<Map<String, String>>? emergencyContacts,
    String? insuranceNumber,
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
          if (bloodType != null) 'blood_type': bloodType,
          if (schoolName != null) 'school_name': schoolName,
          if (grade != null) 'grade': grade,
          if (allergies != null && allergies.isNotEmpty) 'allergies': allergies,
          if (emergencyContacts != null && emergencyContacts.isNotEmpty)
            'emergency_contacts': emergencyContacts,
          if (insuranceNumber != null) 'insurance_number': insuranceNumber,
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
    double? birthLengthCm,
    String? photoUrl,
    String? schoolName,
    String? grade,
    String? bloodType,
    List<String>? allergies,
    List<Map<String, String>>? emergencyContacts,
    String? insuranceNumber,
  }) async {
    try {
      final response = await http.put(
        Uri.parse('$_baseUrl/my-baby/babies/$babyId'),
        headers: ApiConfig.authHeaders(token),
        body: jsonEncode({
          if (name != null) 'name': name,
          if (gender != null) 'gender': gender,
          if (birthWeightGrams != null) 'birth_weight_grams': birthWeightGrams,
          if (birthLengthCm != null) 'birth_length_cm': birthLengthCm,
          if (photoUrl != null) 'photo_url': photoUrl,
          if (schoolName != null) 'school_name': schoolName,
          if (grade != null) 'grade': grade,
          if (bloodType != null) 'blood_type': bloodType,
          if (allergies != null) 'allergies': allergies,
          if (emergencyContacts != null) 'emergency_contacts': emergencyContacts,
          if (insuranceNumber != null) 'insurance_number': insuranceNumber,
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

  Future<MyBabyResult<Vaccination>> undoVaccination(
      String token, int vaccinationId) async {
    try {
      final response = await http.post(
        Uri.parse(
            '$_baseUrl/my-baby/vaccinations/$vaccinationId/undo'),
        headers: ApiConfig.authHeaders(token),
      );
      final data = jsonDecode(response.body);
      if (response.statusCode == 200 && data['success'] == true) {
        return MyBabyResult(
            success: true, data: Vaccination.fromJson(data['data']));
      }
      return MyBabyResult(
          success: false,
          message: data['message'] ?? 'Failed to undo vaccination');
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

  // ─── Chores ────────────────────────────────────────────────────

  Future<MyBabyResult<ChoreAssignment>> createChore({
    required String token,
    required int childId,
    required String title,
    String? titleSwahili,
    required String frequency,
    double rewardAmount = 0,
  }) async {
    try {
      final response = await http.post(
        Uri.parse('$_baseUrl/my-baby/chores'),
        headers: ApiConfig.authHeaders(token),
        body: jsonEncode({
          'child_id': childId,
          'title': title,
          if (titleSwahili != null) 'title_swahili': titleSwahili,
          'frequency': frequency,
          'reward_amount': rewardAmount,
        }),
      );
      final data = jsonDecode(response.body);
      if (response.statusCode == 200 && data['success'] == true) {
        return MyBabyResult(
            success: true, data: ChoreAssignment.fromJson(data['data']));
      }
      return MyBabyResult(
          success: false,
          message: data['message'] ?? 'Failed to create chore');
    } catch (e) {
      return MyBabyResult(success: false, message: 'Error: $e');
    }
  }

  Future<MyBabyListResult<ChoreAssignment>> getChores(
      String token, int childId) async {
    try {
      final response = await http.get(
        Uri.parse('$_baseUrl/my-baby/chores?child_id=$childId'),
        headers: ApiConfig.authHeaders(token),
      );
      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        if (data['success'] == true) {
          final items = (data['data'] as List)
              .map((j) => ChoreAssignment.fromJson(j))
              .toList();
          return MyBabyListResult(success: true, items: items);
        }
      }
      return MyBabyListResult(
          success: false, message: 'Failed to load chores');
    } catch (e) {
      return MyBabyListResult(success: false, message: 'Error: $e');
    }
  }

  Future<MyBabyResult<ChoreAssignment>> completeChore(
      String token, int choreId) async {
    try {
      final response = await http.post(
        Uri.parse('$_baseUrl/my-baby/chores/$choreId/complete'),
        headers: ApiConfig.authHeaders(token),
        body: jsonEncode({
          'completed_at': DateTime.now().toIso8601String(),
        }),
      );
      final data = jsonDecode(response.body);
      if (response.statusCode == 200 && data['success'] == true) {
        return MyBabyResult(
            success: true, data: ChoreAssignment.fromJson(data['data']));
      }
      return MyBabyResult(
          success: false,
          message: data['message'] ?? 'Failed to complete chore');
    } catch (e) {
      return MyBabyResult(success: false, message: 'Error: $e');
    }
  }

  Future<MyBabyResult<void>> deleteChore(String token, int choreId) async {
    try {
      final response = await http.delete(
        Uri.parse('$_baseUrl/my-baby/chores/$choreId'),
        headers: ApiConfig.authHeaders(token),
      );
      final data = jsonDecode(response.body);
      if (response.statusCode == 200 && data['success'] == true) {
        return MyBabyResult(success: true);
      }
      return MyBabyResult(
          success: false,
          message: data['message'] ?? 'Failed to delete chore');
    } catch (e) {
      return MyBabyResult(success: false, message: 'Error: $e');
    }
  }

  // ─── Allowance ─────────────────────────────────────────────────

  Future<MyBabyResult<AllowanceTransaction>> logAllowance({
    required String token,
    required int childId,
    required double amount,
    required String type,
    String? description,
    String? source,
  }) async {
    try {
      final response = await http.post(
        Uri.parse('$_baseUrl/my-baby/allowance'),
        headers: ApiConfig.authHeaders(token),
        body: jsonEncode({
          'child_id': childId,
          'amount': amount,
          'type': type,
          if (description != null) 'description': description,
          if (source != null) 'source': source,
          'date': DateTime.now().toIso8601String(),
        }),
      );
      final data = jsonDecode(response.body);
      if (response.statusCode == 200 && data['success'] == true) {
        return MyBabyResult(
            success: true, data: AllowanceTransaction.fromJson(data['data']));
      }
      return MyBabyResult(
          success: false,
          message: data['message'] ?? 'Failed to log allowance');
    } catch (e) {
      return MyBabyResult(success: false, message: 'Error: $e');
    }
  }

  Future<MyBabyListResult<AllowanceTransaction>> getAllowanceHistory(
      String token, int childId) async {
    try {
      final response = await http.get(
        Uri.parse('$_baseUrl/my-baby/allowance?child_id=$childId'),
        headers: ApiConfig.authHeaders(token),
      );
      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        if (data['success'] == true) {
          final items = (data['data'] as List)
              .map((j) => AllowanceTransaction.fromJson(j))
              .toList();
          return MyBabyListResult(success: true, items: items);
        }
      }
      return MyBabyListResult(
          success: false, message: 'Failed to load allowance history');
    } catch (e) {
      return MyBabyListResult(success: false, message: 'Error: $e');
    }
  }

  Future<MyBabyResult<AllowanceBalance>> getAllowanceBalance(
      String token, int childId) async {
    try {
      final response = await http.get(
        Uri.parse('$_baseUrl/my-baby/allowance/balance?child_id=$childId'),
        headers: ApiConfig.authHeaders(token),
      );
      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        if (data['success'] == true) {
          return MyBabyResult(
              success: true, data: AllowanceBalance.fromJson(data['data']));
        }
      }
      return MyBabyResult(
          success: false, message: 'Failed to load balance');
    } catch (e) {
      return MyBabyResult(success: false, message: 'Error: $e');
    }
  }

  Future<MyBabyResult<void>> deleteAllowance(
      String token, int transactionId) async {
    try {
      final response = await http.delete(
        Uri.parse('$_baseUrl/my-baby/allowance/$transactionId'),
        headers: ApiConfig.authHeaders(token),
      );
      final data = jsonDecode(response.body);
      if (response.statusCode == 200 && data['success'] == true) {
        return MyBabyResult(success: true);
      }
      return MyBabyResult(
          success: false,
          message: data['message'] ?? 'Failed to delete transaction');
    } catch (e) {
      return MyBabyResult(success: false, message: 'Error: $e');
    }
  }

  // ─── Academics ─────────────────────────────────────────────────

  Future<MyBabyResult<AcademicRecord>> addAcademicRecord({
    required String token,
    required int childId,
    required int term,
    required int year,
    required String subject,
    String? grade,
    double? score,
    String? teacherNotes,
  }) async {
    try {
      final response = await http.post(
        Uri.parse('$_baseUrl/my-baby/academics'),
        headers: ApiConfig.authHeaders(token),
        body: jsonEncode({
          'child_id': childId,
          'term': term,
          'year': year,
          'subject': subject,
          if (grade != null) 'grade': grade,
          if (score != null) 'score': score,
          if (teacherNotes != null) 'teacher_notes': teacherNotes,
        }),
      );
      final data = jsonDecode(response.body);
      if (response.statusCode == 200 && data['success'] == true) {
        return MyBabyResult(
            success: true, data: AcademicRecord.fromJson(data['data']));
      }
      return MyBabyResult(
          success: false,
          message: data['message'] ?? 'Failed to add record');
    } catch (e) {
      return MyBabyResult(success: false, message: 'Error: $e');
    }
  }

  Future<MyBabyListResult<AcademicRecord>> getAcademicRecords(
      String token, int childId,
      {int? year, int? term}) async {
    try {
      String url = '$_baseUrl/my-baby/academics?child_id=$childId';
      if (year != null) url += '&year=$year';
      if (term != null) url += '&term=$term';
      final response = await http.get(
        Uri.parse(url),
        headers: ApiConfig.authHeaders(token),
      );
      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        if (data['success'] == true) {
          final items = (data['data'] as List)
              .map((j) => AcademicRecord.fromJson(j))
              .toList();
          return MyBabyListResult(success: true, items: items);
        }
      }
      return MyBabyListResult(
          success: false, message: 'Failed to load academic records');
    } catch (e) {
      return MyBabyListResult(success: false, message: 'Error: $e');
    }
  }

  Future<MyBabyResult<AcademicRecord>> updateAcademicRecord({
    required String token,
    required int recordId,
    String? grade,
    double? score,
    String? teacherNotes,
  }) async {
    try {
      final response = await http.put(
        Uri.parse('$_baseUrl/my-baby/academics/$recordId'),
        headers: ApiConfig.authHeaders(token),
        body: jsonEncode({
          if (grade != null) 'grade': grade,
          if (score != null) 'score': score,
          if (teacherNotes != null) 'teacher_notes': teacherNotes,
        }),
      );
      final data = jsonDecode(response.body);
      if (response.statusCode == 200 && data['success'] == true) {
        return MyBabyResult(
            success: true, data: AcademicRecord.fromJson(data['data']));
      }
      return MyBabyResult(
          success: false,
          message: data['message'] ?? 'Failed to update record');
    } catch (e) {
      return MyBabyResult(success: false, message: 'Error: $e');
    }
  }

  Future<MyBabyResult<void>> deleteAcademicRecord(
      String token, int recordId) async {
    try {
      final response = await http.delete(
        Uri.parse('$_baseUrl/my-baby/academics/$recordId'),
        headers: ApiConfig.authHeaders(token),
      );
      final data = jsonDecode(response.body);
      if (response.statusCode == 200 && data['success'] == true) {
        return MyBabyResult(success: true);
      }
      return MyBabyResult(
          success: false,
          message: data['message'] ?? 'Failed to delete record');
    } catch (e) {
      return MyBabyResult(success: false, message: 'Error: $e');
    }
  }

  // ─── Activities ────────────────────────────────────────────────

  Future<MyBabyResult<ActivityEnrollment>> enrollActivity({
    required String token,
    required int childId,
    required String activityName,
    required String category,
    String? schedule,
    double feeAmount = 0,
    String? feeFrequency,
    DateTime? startDate,
  }) async {
    try {
      final response = await http.post(
        Uri.parse('$_baseUrl/my-baby/activities'),
        headers: ApiConfig.authHeaders(token),
        body: jsonEncode({
          'child_id': childId,
          'activity_name': activityName,
          'category': category,
          if (schedule != null) 'schedule': schedule,
          'fee_amount': feeAmount,
          if (feeFrequency != null) 'fee_frequency': feeFrequency,
          if (startDate != null) 'start_date': startDate.toIso8601String(),
        }),
      );
      final data = jsonDecode(response.body);
      if (response.statusCode == 200 && data['success'] == true) {
        return MyBabyResult(
            success: true, data: ActivityEnrollment.fromJson(data['data']));
      }
      return MyBabyResult(
          success: false,
          message: data['message'] ?? 'Failed to enroll');
    } catch (e) {
      return MyBabyResult(success: false, message: 'Error: $e');
    }
  }

  Future<MyBabyListResult<ActivityEnrollment>> getActivities(
      String token, int childId) async {
    try {
      final response = await http.get(
        Uri.parse('$_baseUrl/my-baby/activities?child_id=$childId'),
        headers: ApiConfig.authHeaders(token),
      );
      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        if (data['success'] == true) {
          final items = (data['data'] as List)
              .map((j) => ActivityEnrollment.fromJson(j))
              .toList();
          return MyBabyListResult(success: true, items: items);
        }
      }
      return MyBabyListResult(
          success: false, message: 'Failed to load activities');
    } catch (e) {
      return MyBabyListResult(success: false, message: 'Error: $e');
    }
  }

  Future<MyBabyResult<void>> deleteActivity(
      String token, int activityId) async {
    try {
      final response = await http.delete(
        Uri.parse('$_baseUrl/my-baby/activities/$activityId'),
        headers: ApiConfig.authHeaders(token),
      );
      final data = jsonDecode(response.body);
      if (response.statusCode == 200 && data['success'] == true) {
        return MyBabyResult(success: true);
      }
      return MyBabyResult(
          success: false,
          message: data['message'] ?? 'Failed to delete activity');
    } catch (e) {
      return MyBabyResult(success: false, message: 'Error: $e');
    }
  }

  // ─── Reading Log ───────────────────────────────────────────────

  Future<MyBabyResult<ReadingLogEntry>> logReading({
    required String token,
    required int childId,
    required String bookTitle,
    String? author,
    required int pagesRead,
    int? totalPages,
    DateTime? startDate,
    DateTime? finishDate,
  }) async {
    try {
      final response = await http.post(
        Uri.parse('$_baseUrl/my-baby/reading'),
        headers: ApiConfig.authHeaders(token),
        body: jsonEncode({
          'child_id': childId,
          'book_title': bookTitle,
          if (author != null) 'author': author,
          'pages_read': pagesRead,
          if (totalPages != null) 'total_pages': totalPages,
          if (startDate != null) 'start_date': startDate.toIso8601String(),
          if (finishDate != null) 'finish_date': finishDate.toIso8601String(),
        }),
      );
      final data = jsonDecode(response.body);
      if (response.statusCode == 200 && data['success'] == true) {
        return MyBabyResult(
            success: true, data: ReadingLogEntry.fromJson(data['data']));
      }
      return MyBabyResult(
          success: false,
          message: data['message'] ?? 'Failed to log reading');
    } catch (e) {
      return MyBabyResult(success: false, message: 'Error: $e');
    }
  }

  Future<MyBabyListResult<ReadingLogEntry>> getReadingHistory(
      String token, int childId) async {
    try {
      final response = await http.get(
        Uri.parse('$_baseUrl/my-baby/reading?child_id=$childId'),
        headers: ApiConfig.authHeaders(token),
      );
      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        if (data['success'] == true) {
          final items = (data['data'] as List)
              .map((j) => ReadingLogEntry.fromJson(j))
              .toList();
          return MyBabyListResult(success: true, items: items);
        }
      }
      return MyBabyListResult(
          success: false, message: 'Failed to load reading history');
    } catch (e) {
      return MyBabyListResult(success: false, message: 'Error: $e');
    }
  }

  Future<MyBabyResult<void>> deleteReading(
      String token, int readingId) async {
    try {
      final response = await http.delete(
        Uri.parse('$_baseUrl/my-baby/reading/$readingId'),
        headers: ApiConfig.authHeaders(token),
      );
      final data = jsonDecode(response.body);
      if (response.statusCode == 200 && data['success'] == true) {
        return MyBabyResult(success: true);
      }
      return MyBabyResult(
          success: false,
          message: data['message'] ?? 'Failed to delete reading');
    } catch (e) {
      return MyBabyResult(success: false, message: 'Error: $e');
    }
  }

  // ─── Potty Training ─────────────────────────────────────────────

  Future<MyChildrenResult<void>> logPotty(
    int childId,
    String type, {
    String? notes,
    String? token,
  }) async {
    try {
      final response = await http.post(
        Uri.parse('$_baseUrl/my-children/potty'),
        headers: ApiConfig.authHeaders(token ?? ''),
        body: jsonEncode({
          'child_id': childId,
          'type': type,
          if (notes != null) 'notes': notes,
          'logged_at': DateTime.now().toIso8601String(),
        }),
      );
      final data = jsonDecode(response.body);
      if (response.statusCode == 200 && data['success'] == true) {
        return MyChildrenResult(success: true);
      }
      return MyChildrenResult(
          success: false,
          message: data['message'] ?? 'Failed to log potty');
    } catch (e) {
      return MyChildrenResult(success: false, message: 'Error: $e');
    }
  }

  Future<MyChildrenListResult<Map<String, dynamic>>> getPottyHistory(
    int childId, {
    String? date,
    String? token,
  }) async {
    try {
      String url = '$_baseUrl/my-children/potty?child_id=$childId';
      if (date != null) url += '&date=$date';
      final response = await http.get(
        Uri.parse(url),
        headers: ApiConfig.authHeaders(token ?? ''),
      );
      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        if (data['success'] == true) {
          final items = (data['data'] as List)
              .map((j) => Map<String, dynamic>.from(j as Map))
              .toList();
          return MyChildrenListResult(success: true, items: items);
        }
      }
      return MyChildrenListResult(
          success: false, message: 'Failed to load potty history');
    } catch (e) {
      return MyChildrenListResult(success: false, message: 'Error: $e');
    }
  }

  // ─── Speech Development ────────────────────────────────────────

  Future<MyChildrenResult<void>> logSpeech(
    int childId,
    String type,
    String content,
    String language, {
    String? token,
  }) async {
    try {
      final response = await http.post(
        Uri.parse('$_baseUrl/my-children/speech'),
        headers: ApiConfig.authHeaders(token ?? ''),
        body: jsonEncode({
          'child_id': childId,
          'type': type,
          'content': content,
          'language': language,
          'logged_at': DateTime.now().toIso8601String(),
        }),
      );
      final data = jsonDecode(response.body);
      if (response.statusCode == 200 && data['success'] == true) {
        return MyChildrenResult(success: true);
      }
      return MyChildrenResult(
          success: false,
          message: data['message'] ?? 'Failed to log speech');
    } catch (e) {
      return MyChildrenResult(success: false, message: 'Error: $e');
    }
  }

  Future<MyChildrenListResult<Map<String, dynamic>>> getSpeechHistory(
    int childId, {
    String? token,
  }) async {
    try {
      final response = await http.get(
        Uri.parse('$_baseUrl/my-children/speech?child_id=$childId'),
        headers: ApiConfig.authHeaders(token ?? ''),
      );
      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        if (data['success'] == true) {
          final items = (data['data'] as List)
              .map((j) => Map<String, dynamic>.from(j as Map))
              .toList();
          return MyChildrenListResult(success: true, items: items);
        }
      }
      return MyChildrenListResult(
          success: false, message: 'Failed to load speech history');
    } catch (e) {
      return MyChildrenListResult(success: false, message: 'Error: $e');
    }
  }

  // ─── Emergency Card ─────────────────────────────────────────────

  Future<MyChildrenResult<Map<String, dynamic>>> getEmergencyCard(
      int childId, {String? token}) async {
    try {
      final response = await http.get(
        Uri.parse('$_baseUrl/my-baby/emergency-card?child_id=$childId'),
        headers: ApiConfig.authHeaders(token ?? ''),
      );
      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        if (data['success'] == true && data['data'] != null) {
          return MyChildrenResult(
            success: true,
            data: Map<String, dynamic>.from(data['data'] as Map),
          );
        }
      }
      return MyChildrenResult(
          success: false, message: 'Failed to load emergency card');
    } catch (e) {
      return MyChildrenResult(success: false, message: 'Error: $e');
    }
  }

  Future<MyChildrenResult<dynamic>> saveEmergencyCard(
      int childId, Map<String, dynamic> cardData, {String? token}) async {
    try {
      final body = <String, dynamic>{
        'child_id': childId,
        ...cardData,
      };
      final response = await http.post(
        Uri.parse('$_baseUrl/my-baby/emergency-card'),
        headers: ApiConfig.authHeaders(token ?? ''),
        body: jsonEncode(body),
      );
      final data = jsonDecode(response.body);
      if (response.statusCode == 200 && data['success'] == true) {
        return MyChildrenResult(success: true, data: data['data']);
      }
      return MyChildrenResult(
          success: false,
          message: data['message'] ?? 'Failed to save emergency card');
    } catch (e) {
      return MyChildrenResult(success: false, message: 'Error: $e');
    }
  }

  // ─── Summary ───────────────────────────────────────────────────

  // ─── Shangazi AI Context ────────────────────────────────────────

  /// Returns a summary of the user's children for the Shangazi AI assistant.
  Future<Map<String, dynamic>> getChildSummaryForAI(
      String token, int userId) async {
    try {
      final result = await getMyBabies(token, userId);
      if (!result.success) return {'has_children': false};

      final children = result.items;
      return {
        'has_children': children.isNotEmpty,
        'children_count': children.length,
        'children': children
            .map((c) => {
                  'name': c.name,
                  'age_years': c.ageInYears,
                  'age_months': c.ageInMonths,
                  'stage': c.stage,
                  'gender': c.gender,
                })
            .toList(),
      };
    } catch (_) {
      return {'has_children': false};
    }
  }

  // ─── Daily Summary ────────────────────────────────────────────

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

  // ─── Delete Methods ─────────────────────────────────────────────

  Future<MyBabyResult<void>> deleteBaby(String token, int babyId) async {
    try {
      final response = await http.delete(
        Uri.parse('$_baseUrl/my-baby/babies/$babyId'),
        headers: ApiConfig.authHeaders(token),
      );
      final data = jsonDecode(response.body);
      if (response.statusCode == 200 && data['success'] == true) {
        return MyBabyResult(success: true);
      }
      return MyBabyResult(
          success: false,
          message: data['message'] ?? 'Failed to delete baby');
    } catch (e) {
      return MyBabyResult(success: false, message: 'Error: $e');
    }
  }

  Future<MyBabyResult<void>> deleteFeeding(String token, int feedingId) async {
    try {
      final response = await http.delete(
        Uri.parse('$_baseUrl/my-baby/feedings/$feedingId'),
        headers: ApiConfig.authHeaders(token),
      );
      final data = jsonDecode(response.body);
      if (response.statusCode == 200 && data['success'] == true) {
        return MyBabyResult(success: true);
      }
      return MyBabyResult(
          success: false,
          message: data['message'] ?? 'Failed to delete feeding');
    } catch (e) {
      return MyBabyResult(success: false, message: 'Error: $e');
    }
  }

  Future<MyBabyResult<void>> deleteDiaper(String token, int diaperId) async {
    try {
      final response = await http.delete(
        Uri.parse('$_baseUrl/my-baby/diapers/$diaperId'),
        headers: ApiConfig.authHeaders(token),
      );
      final data = jsonDecode(response.body);
      if (response.statusCode == 200 && data['success'] == true) {
        return MyBabyResult(success: true);
      }
      return MyBabyResult(
          success: false,
          message: data['message'] ?? 'Failed to delete diaper');
    } catch (e) {
      return MyBabyResult(success: false, message: 'Error: $e');
    }
  }

  Future<MyBabyResult<void>> deleteSleep(String token, int sessionId) async {
    try {
      final response = await http.delete(
        Uri.parse('$_baseUrl/my-baby/sleep/$sessionId'),
        headers: ApiConfig.authHeaders(token),
      );
      final data = jsonDecode(response.body);
      if (response.statusCode == 200 && data['success'] == true) {
        return MyBabyResult(success: true);
      }
      return MyBabyResult(
          success: false,
          message: data['message'] ?? 'Failed to delete sleep session');
    } catch (e) {
      return MyBabyResult(success: false, message: 'Error: $e');
    }
  }

  Future<MyBabyResult<void>> deleteGrowth(String token, int growthId) async {
    try {
      final response = await http.delete(
        Uri.parse('$_baseUrl/my-baby/growth/$growthId'),
        headers: ApiConfig.authHeaders(token),
      );
      final data = jsonDecode(response.body);
      if (response.statusCode == 200 && data['success'] == true) {
        return MyBabyResult(success: true);
      }
      return MyBabyResult(
          success: false,
          message: data['message'] ?? 'Failed to delete growth record');
    } catch (e) {
      return MyBabyResult(success: false, message: 'Error: $e');
    }
  }

  Future<MyBabyResult<void>> deleteHealthLog(String token, int logId) async {
    try {
      final response = await http.delete(
        Uri.parse('$_baseUrl/my-baby/health-logs/$logId'),
        headers: ApiConfig.authHeaders(token),
      );
      final data = jsonDecode(response.body);
      if (response.statusCode == 200 && data['success'] == true) {
        return MyBabyResult(success: true);
      }
      return MyBabyResult(
          success: false,
          message: data['message'] ?? 'Failed to delete health log');
    } catch (e) {
      return MyBabyResult(success: false, message: 'Error: $e');
    }
  }

  Future<MyBabyResult<void>> deletePhoto(String token, int photoId) async {
    try {
      final response = await http.delete(
        Uri.parse('$_baseUrl/my-baby/photos/$photoId'),
        headers: ApiConfig.authHeaders(token),
      );
      final data = jsonDecode(response.body);
      if (response.statusCode == 200 && data['success'] == true) {
        return MyBabyResult(success: true);
      }
      return MyBabyResult(
          success: false,
          message: data['message'] ?? 'Failed to delete photo');
    } catch (e) {
      return MyBabyResult(success: false, message: 'Error: $e');
    }
  }

  Future<MyBabyResult<void>> deletePotty(String token, int pottyId) async {
    try {
      final response = await http.delete(
        Uri.parse('$_baseUrl/my-children/potty/$pottyId'),
        headers: ApiConfig.authHeaders(token),
      );
      final data = jsonDecode(response.body);
      if (response.statusCode == 200 && data['success'] == true) {
        return MyBabyResult(success: true);
      }
      return MyBabyResult(
          success: false,
          message: data['message'] ?? 'Failed to delete potty record');
    } catch (e) {
      return MyBabyResult(success: false, message: 'Error: $e');
    }
  }

  Future<MyBabyResult<void>> deleteSpeech(String token, int speechId) async {
    try {
      final response = await http.delete(
        Uri.parse('$_baseUrl/my-children/speech/$speechId'),
        headers: ApiConfig.authHeaders(token),
      );
      final data = jsonDecode(response.body);
      if (response.statusCode == 200 && data['success'] == true) {
        return MyBabyResult(success: true);
      }
      return MyBabyResult(
          success: false,
          message: data['message'] ?? 'Failed to delete speech record');
    } catch (e) {
      return MyBabyResult(success: false, message: 'Error: $e');
    }
  }

}
