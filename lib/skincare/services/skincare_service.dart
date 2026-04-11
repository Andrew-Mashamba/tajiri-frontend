// lib/skincare/services/skincare_service.dart
import 'dart:convert';
import 'package:http/http.dart' as http;
import '../../config/api_config.dart';
import '../models/skincare_models.dart';

String get _baseUrl => ApiConfig.baseUrl;

class SkincareService {
  // ─── Skin Profile ─────────────────────────────────────────────

  Future<SkincareResult<SkinProfile>> getSkinProfile(int userId) async {
    try {
      final response = await http.get(Uri.parse('$_baseUrl/skincare/profile?user_id=$userId'));
      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        if (data['success'] == true) {
          return SkincareResult(success: true, data: SkinProfile.fromJson(data['data']));
        }
      }
      return SkincareResult(success: false, message: 'Imeshindwa kupakia profaili ya ngozi');
    } catch (e) {
      return SkincareResult(success: false, message: 'Kosa: $e');
    }
  }

  Future<SkincareResult<SkinProfile>> saveSkinProfile({
    required int userId,
    required SkinType skinType,
    String? skinTone,
    required List<SkinConcern> concerns,
    required ClimateZone climateZone,
    String? budget,
  }) async {
    try {
      final response = await http.post(
        Uri.parse('$_baseUrl/skincare/profile'),
        headers: {'Content-Type': 'application/json'},
        body: jsonEncode({
          'user_id': userId,
          'skin_type': skinType.name,
          'skin_tone': skinTone,
          'concerns': concerns.map((c) => c.name).toList(),
          'climate_zone': climateZone.name,
          'budget': budget,
        }),
      );
      final data = jsonDecode(response.body);
      if (response.statusCode == 200 && data['success'] == true) {
        return SkincareResult(success: true, data: SkinProfile.fromJson(data['data']));
      }
      return SkincareResult(success: false, message: data['message'] ?? 'Imeshindwa kuhifadhi');
    } catch (e) {
      return SkincareResult(success: false, message: 'Kosa: $e');
    }
  }

  // ─── Routines ─────────────────────────────────────────────────

  Future<SkincareListResult<SkincareRoutine>> getRoutines(int userId) async {
    try {
      final response = await http.get(Uri.parse('$_baseUrl/skincare/routines?user_id=$userId'));
      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        if (data['success'] == true) {
          return SkincareListResult(
            success: true,
            items: (data['data'] as List).map((j) => SkincareRoutine.fromJson(j)).toList(),
          );
        }
      }
      return SkincareListResult(success: false, message: 'Imeshindwa kupakia routine');
    } catch (e) {
      return SkincareListResult(success: false, message: 'Kosa: $e');
    }
  }

  Future<SkincareResult<SkincareRoutine>> saveRoutine({
    required int userId,
    required String name,
    required RoutineType type,
    required List<RoutineStep> steps,
    bool isActive = true,
  }) async {
    try {
      final response = await http.post(
        Uri.parse('$_baseUrl/skincare/routines'),
        headers: {'Content-Type': 'application/json'},
        body: jsonEncode({
          'user_id': userId,
          'name': name,
          'type': type.name,
          'steps': steps.map((s) => s.toJson()).toList(),
          'is_active': isActive,
        }),
      );
      final data = jsonDecode(response.body);
      if (response.statusCode == 200 && data['success'] == true) {
        return SkincareResult(success: true, data: SkincareRoutine.fromJson(data['data']));
      }
      return SkincareResult(success: false, message: data['message'] ?? 'Imeshindwa kuhifadhi routine');
    } catch (e) {
      return SkincareResult(success: false, message: 'Kosa: $e');
    }
  }

  Future<SkincareResult<void>> deleteRoutine(int routineId) async {
    try {
      final response = await http.delete(Uri.parse('$_baseUrl/skincare/routines/$routineId'));
      final data = jsonDecode(response.body);
      if (response.statusCode == 200 && data['success'] == true) {
        return SkincareResult(success: true);
      }
      return SkincareResult(success: false, message: data['message'] ?? 'Imeshindwa kufuta');
    } catch (e) {
      return SkincareResult(success: false, message: 'Kosa: $e');
    }
  }

  // ─── Diary ────────────────────────────────────────────────────

  Future<SkincareListResult<SkinDiaryEntry>> getDiaryEntries(int userId, {int? month, int? year}) async {
    try {
      final params = <String, String>{'user_id': '$userId'};
      if (month != null) params['month'] = '$month';
      if (year != null) params['year'] = '$year';

      final uri = Uri.parse('$_baseUrl/skincare/diary').replace(queryParameters: params);
      final response = await http.get(uri);
      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        if (data['success'] == true) {
          return SkincareListResult(
            success: true,
            items: (data['data'] as List).map((j) => SkinDiaryEntry.fromJson(j)).toList(),
          );
        }
      }
      return SkincareListResult(success: false, message: 'Imeshindwa kupakia diary');
    } catch (e) {
      return SkincareListResult(success: false, message: 'Kosa: $e');
    }
  }

  Future<SkincareResult<SkinDiaryEntry>> logDiaryEntry({
    required int userId,
    required DateTime date,
    required int mood,
    List<String> tags = const [],
    List<String> productsUsed = const [],
    String? notes,
    String? photoPath,
  }) async {
    try {
      final response = await http.post(
        Uri.parse('$_baseUrl/skincare/diary'),
        headers: {'Content-Type': 'application/json'},
        body: jsonEncode({
          'user_id': userId,
          'date': date.toIso8601String().split('T').first,
          'mood': mood,
          'tags': tags,
          'products_used': productsUsed,
          'notes': notes,
        }),
      );
      final data = jsonDecode(response.body);
      if (response.statusCode == 200 && data['success'] == true) {
        return SkincareResult(success: true, data: SkinDiaryEntry.fromJson(data['data']));
      }
      return SkincareResult(success: false, message: data['message'] ?? 'Imeshindwa kuhifadhi');
    } catch (e) {
      return SkincareResult(success: false, message: 'Kosa: $e');
    }
  }

  // ─── Products ─────────────────────────────────────────────────

  Future<SkincareListResult<SkinProduct>> getProducts({
    String? category,
    String? skinType,
    String? concern,
    String? search,
    int page = 1,
  }) async {
    try {
      final params = <String, String>{'page': '$page'};
      if (category != null && category.isNotEmpty) params['category'] = category;
      if (skinType != null && skinType.isNotEmpty) params['skin_type'] = skinType;
      if (concern != null && concern.isNotEmpty) params['concern'] = concern;
      if (search != null && search.isNotEmpty) params['search'] = search;

      final uri = Uri.parse('$_baseUrl/skincare/products').replace(queryParameters: params);
      final response = await http.get(uri);
      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        if (data['success'] == true) {
          return SkincareListResult(
            success: true,
            items: (data['data'] as List).map((j) => SkinProduct.fromJson(j)).toList(),
          );
        }
      }
      return SkincareListResult(success: false, message: 'Imeshindwa kupakia bidhaa');
    } catch (e) {
      return SkincareListResult(success: false, message: 'Kosa: $e');
    }
  }

  Future<SkincareResult<SkinProduct>> getProductDetail(int productId) async {
    try {
      final response = await http.get(Uri.parse('$_baseUrl/skincare/products/$productId'));
      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        if (data['success'] == true) {
          return SkincareResult(success: true, data: SkinProduct.fromJson(data['data']));
        }
      }
      return SkincareResult(success: false);
    } catch (e) {
      return SkincareResult(success: false);
    }
  }

  // ─── Dangerous Ingredients (TMDA) ─────────────────────────────

  Future<SkincareListResult<DangerousIngredient>> getDangerousIngredients() async {
    try {
      final response = await http.get(Uri.parse('$_baseUrl/skincare/dangerous-ingredients'));
      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        if (data['success'] == true) {
          return SkincareListResult(
            success: true,
            items: (data['data'] as List).map((j) => DangerousIngredient.fromJson(j)).toList(),
          );
        }
      }
      return SkincareListResult(success: false, message: 'Imeshindwa kupakia orodha');
    } catch (e) {
      return SkincareListResult(success: false, message: 'Kosa: $e');
    }
  }

  // ─── AI Recommendations ───────────────────────────────────────

  Future<SkincareListResult<SkinProduct>> getRecommendations(int userId) async {
    try {
      final response = await http.get(Uri.parse('$_baseUrl/skincare/recommendations?user_id=$userId'));
      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        if (data['success'] == true) {
          return SkincareListResult(
            success: true,
            items: (data['data'] as List).map((j) => SkinProduct.fromJson(j)).toList(),
          );
        }
      }
      return SkincareListResult(success: false, message: 'Imeshindwa kupakia mapendekezo');
    } catch (e) {
      return SkincareListResult(success: false, message: 'Kosa: $e');
    }
  }
}
