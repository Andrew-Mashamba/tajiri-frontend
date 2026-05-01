// Spec wave-I — Dart clients for the 13 wave-4 backend controllers.

import 'dart:convert';

import 'package:http/http.dart' as http;

import '../config/api_config.dart';

class _W4 {
  static Uri _u(String path) =>
      Uri.parse(ApiConfig.sanitizeUrl('${ApiConfig.baseUrl}/api$path')!);

  static Future<Map<String, dynamic>?> get(String path,
      {Map<String, String>? query}) async {
    var uri = _u(path);
    if (query != null && query.isNotEmpty) uri = uri.replace(queryParameters: query);
    final res = await http.get(uri);
    if (res.statusCode != 200) return null;
    final body = jsonDecode(res.body);
    return body is Map<String, dynamic> ? body : null;
  }

  static Future<Map<String, dynamic>?> post(String path, Map<String, dynamic> body) async {
    final res = await http.post(_u(path),
        headers: {'Content-Type': 'application/json'}, body: jsonEncode(body));
    final decoded = res.body.isEmpty ? null : jsonDecode(res.body);
    return decoded is Map<String, dynamic> ? decoded : null;
  }

  static Future<bool> delete(String path) async =>
      (await http.delete(_u(path))).statusCode == 200;
}

// === #6 Sample photos per skill ===
class SamplePhotoService {
  static Future<List<String>> show(String skill) async {
    final body = await _W4.get('/sample-photos/$skill');
    final list = body?['samples'];
    return list is List ? list.map((e) => e.toString()).toList() : const [];
  }
}

// === Refund photo similarity ===
class RefundPhotoSimilarityService {
  static Future<({double score, bool flagReview})?> check({
    required String orderPhotoUrl,
    required String refundPhotoUrl,
  }) async {
    final body = await _W4.post('/refund-photo/similarity', {
      'order_photo_url': orderPhotoUrl,
      'refund_photo_url': refundPhotoUrl,
    });
    if (body == null) return null;
    return (
      score: (body['similarity_score'] as num?)?.toDouble() ?? 0.0,
      flagReview: body['flag_review'] == true,
    );
  }
}

// === KPI score ===
class PartnerKpiService {
  static Future<Map<String, dynamic>?> show(int partnerUserId) =>
      _W4.get('/partner-kpi/$partnerUserId');
}

// === Garage warranty claims ===
class GarageWarrantyClaimService {
  static Future<int?> file({
    required int userId,
    required int garageBookingId,
    required String issue,
    List<String>? photos,
  }) async {
    final res = await _W4.post('/garage-warranty-claims', {
      'user_id': userId,
      'garage_booking_id': garageBookingId,
      'issue': issue,
      if (photos != null) 'photos': photos,
    });
    return (res?['claim_id'] as num?)?.toInt();
  }
  static Future<List<Map<String, dynamic>>> mine(int userId) async {
    final body = await _W4.get('/garage-warranty-claims/mine',
        query: {'user_id': '$userId'});
    final list = body?['claims'];
    return list is List
        ? list.whereType<Map>().map((m) => m.cast<String, dynamic>()).toList()
        : const [];
  }
}

// === Symptom checker ===
class SymptomCheckerService {
  static Future<List<Map<String, dynamic>>> predict(String text) async {
    final body = await _W4.post('/symptom-checker', {'text': text});
    final list = body?['predicted'];
    return list is List
        ? list.whereType<Map>().map((m) => m.cast<String, dynamic>()).toList()
        : const [];
  }
}

// === Health profile ===
class HealthProfileService {
  static Future<Map<String, dynamic>?> show(int userId) async {
    final body = await _W4.get('/health-profile', query: {'user_id': '$userId'});
    final p = body?['profile'];
    return p is Map<String, dynamic> ? p : null;
  }
  static Future<bool> save({
    required int userId,
    List<String>? allergies,
    List<String>? chronicConditions,
    DateTime? dateOfBirth,
    String? bloodType,
  }) async {
    final res = await _W4.post('/health-profile', {
      'user_id': userId,
      if (allergies != null) 'allergies': allergies,
      if (chronicConditions != null) 'chronic_conditions': chronicConditions,
      if (dateOfBirth != null)
        'date_of_birth': dateOfBirth.toIso8601String().substring(0, 10),
      if (bloodType != null) 'blood_type': bloodType,
    });
    return res?['ok'] == true;
  }
}

// === Peer endorsements ===
class PeerEndorsementService {
  static Future<bool> endorse({
    required int endorserUserId,
    required int endorseeUserId,
    required String skillCategory,
    String? text,
  }) async {
    final res = await _W4.post('/peer-endorsements', {
      'endorser_user_id': endorserUserId,
      'endorsee_user_id': endorseeUserId,
      'skill_category': skillCategory,
      if (text != null) 'text': text,
    });
    return res?['ok'] == true;
  }
  static Future<List<Map<String, dynamic>>> listForPartner(int partnerUserId) async {
    final body = await _W4.get('/peer-endorsements/$partnerUserId');
    final list = body?['endorsements'];
    return list is List
        ? list.whereType<Map>().map((m) => m.cast<String, dynamic>()).toList()
        : const [];
  }
}

// === VIP standing slots ===
class VipSlotService {
  static Future<List<Map<String, dynamic>>> partnerList(int userId) async {
    final body = await _W4.get('/vip-slots', query: {'user_id': '$userId'});
    final list = body?['slots'];
    return list is List
        ? list.whereType<Map>().map((m) => m.cast<String, dynamic>()).toList()
        : const [];
  }
  static Future<int?> save({
    required int userId,
    required int vipUserId,
    required String dayOfWeek,
    required String startsAt,
    required int durationMinutes,
  }) async {
    final res = await _W4.post('/vip-slots', {
      'user_id': userId,
      'vip_user_id': vipUserId,
      'day_of_week': dayOfWeek,
      'starts_at': startsAt,
      'duration_minutes': durationMinutes,
    });
    return (res?['id'] as num?)?.toInt();
  }
}

// === Saved partners (per-persona favorites) ===
class SavedPartnerService {
  static Future<bool> save({
    required int userId,
    required int partnerUserId,
    String? skillCategory,
  }) async {
    final res = await _W4.post('/saved-partners', {
      'user_id': userId,
      'partner_user_id': partnerUserId,
      if (skillCategory != null) 'skill_category': skillCategory,
    });
    return res?['ok'] == true;
  }
  static Future<bool> unsave({
    required int userId,
    required int partnerUserId,
    String? skillCategory,
  }) async {
    final res = await _W4.post('/saved-partners/unsave', {
      'user_id': userId,
      'partner_user_id': partnerUserId,
      if (skillCategory != null) 'skill_category': skillCategory,
    });
    return res?['ok'] == true;
  }
  static Future<List<Map<String, dynamic>>> mine(int userId) async {
    final body =
        await _W4.get('/saved-partners/mine', query: {'user_id': '$userId'});
    final list = body?['saved'];
    return list is List
        ? list.whereType<Map>().map((m) => m.cast<String, dynamic>()).toList()
        : const [];
  }
}

// === Training plans ===
class TrainingPlanService {
  static Future<int?> create({
    required int coachUserId,
    required int clientUserId,
    required String title,
    required Map<String, dynamic> weeklySchedule,
    required DateTime startsOn,
    required int durationWeeks,
    required int priceTzs,
  }) async {
    final res = await _W4.post('/training-plans', {
      'coach_user_id': coachUserId,
      'client_user_id': clientUserId,
      'title': title,
      'weekly_schedule': weeklySchedule,
      'starts_on': startsOn.toIso8601String().substring(0, 10),
      'duration_weeks': durationWeeks,
      'price_tzs': priceTzs,
    });
    return (res?['plan_id'] as num?)?.toInt();
  }
  static Future<List<Map<String, dynamic>>> mine(int userId) async {
    final body = await _W4.get('/training-plans/mine',
        query: {'user_id': '$userId'});
    final list = body?['plans'];
    return list is List
        ? list.whereType<Map>().map((m) => m.cast<String, dynamic>()).toList()
        : const [];
  }
}

// === Fitness tracker ===
class FitnessTrackerService {
  static Future<bool> addPhoto({
    required int userId,
    required String photoUrl,
    String? angle,
  }) async {
    final res = await _W4.post('/fitness-tracker/photo', {
      'user_id': userId,
      'photo_url': photoUrl,
      if (angle != null) 'angle': angle,
    });
    return res?['ok'] == true;
  }
  static Future<bool> addMeasurement({
    required int userId,
    double? weightKg,
    double? waistCm,
    double? chestCm,
    double? hipCm,
    double? armCm,
    double? thighCm,
    double? bodyFatPct,
  }) async {
    final res = await _W4.post('/fitness-tracker/measurement', {
      'user_id': userId,
      if (weightKg != null) 'weight_kg': weightKg,
      if (waistCm != null) 'waist_cm': waistCm,
      if (chestCm != null) 'chest_cm': chestCm,
      if (hipCm != null) 'hip_cm': hipCm,
      if (armCm != null) 'arm_cm': armCm,
      if (thighCm != null) 'thigh_cm': thighCm,
      if (bodyFatPct != null) 'body_fat_pct': bodyFatPct,
    });
    return res?['ok'] == true;
  }
  static Future<bool> logPr({
    required int userId,
    required String exerciseName,
    required double value,
    required String unit,
  }) async {
    final res = await _W4.post('/fitness-tracker/pr', {
      'user_id': userId,
      'exercise_name': exerciseName,
      'value': value,
      'unit': unit,
    });
    return res?['is_pr'] == true;
  }
  static Future<Map<String, dynamic>?> summary(int userId) =>
      _W4.get('/fitness-tracker/summary', query: {'user_id': '$userId'});
}

// === Service variants ===
class ServiceVariantService {
  static Future<List<Map<String, dynamic>>> listForProduct(int productId) async {
    final body = await _W4.get('/service-variants/$productId');
    final list = body?['variants'];
    return list is List
        ? list.whereType<Map>().map((m) => m.cast<String, dynamic>()).toList()
        : const [];
  }
  static Future<int?> save({
    int? id,
    required int partnerProductId,
    required String labelEn,
    required String labelSw,
    required int priceTzs,
    int? durationMinutes,
    int? leadTimeMinutes,
    int? displayOrder,
  }) async {
    final res = await _W4.post('/service-variants', {
      if (id != null) 'id': id,
      'partner_product_id': partnerProductId,
      'label_en': labelEn,
      'label_sw': labelSw,
      'price_tzs': priceTzs,
      if (durationMinutes != null) 'duration_minutes': durationMinutes,
      if (leadTimeMinutes != null) 'lead_time_minutes': leadTimeMinutes,
      if (displayOrder != null) 'display_order': displayOrder,
    });
    return (res?['id'] as num?)?.toInt();
  }
  static Future<bool> remove(int variantId) =>
      _W4.delete('/service-variants/$variantId');
}

// === AI hiring brief ===
class AiHiringBriefService {
  static Future<String?> generate(String oneLiner) async {
    final body =
        await _W4.post('/ai-hiring-brief', {'one_liner': oneLiner});
    return body?['brief']?.toString();
  }
}
