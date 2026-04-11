// lib/community/services/community_service.dart
import 'dart:convert';
import 'package:http/http.dart' as http;
import '../../config/api_config.dart';
import '../models/community_models.dart';

String get _baseUrl => ApiConfig.baseUrl;

class CommunityService {
  // ─── Community Posts ───────────────────────────────────────────

  Future<CommunityListResult<CommunityPost>> getPosts({
    double? latitude,
    double? longitude,
    CommunityPostType? type,
    int page = 1,
    int perPage = 20,
  }) async {
    try {
      final params = <String, String>{
        'page': '$page',
        'per_page': '$perPage',
      };
      if (latitude != null) params['latitude'] = '$latitude';
      if (longitude != null) params['longitude'] = '$longitude';
      if (type != null) params['type'] = type.name;

      final uri = Uri.parse('$_baseUrl/community/posts')
          .replace(queryParameters: params);
      final response = await http.get(uri);

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        if (data['success'] == true) {
          final items = (data['data'] as List)
              .map((j) => CommunityPost.fromJson(j))
              .toList();
          return CommunityListResult(success: true, items: items);
        }
      }
      return CommunityListResult(
        success: false,
        message: 'Imeshindwa kupakia machapisho',
      );
    } catch (e) {
      return CommunityListResult(success: false, message: 'Kosa: $e');
    }
  }

  Future<CommunityResult<CommunityPost>> createPost({
    required int userId,
    required String content,
    required CommunityPostType type,
    String? location,
    double? latitude,
    double? longitude,
  }) async {
    try {
      final response = await http.post(
        Uri.parse('$_baseUrl/community/posts'),
        headers: ApiConfig.headers,
        body: jsonEncode({
          'user_id': userId,
          'content': content,
          'type': type.name,
          if (location != null) 'location': location,
          if (latitude != null) 'latitude': latitude,
          if (longitude != null) 'longitude': longitude,
        }),
      );
      if (response.statusCode == 200 || response.statusCode == 201) {
        final data = jsonDecode(response.body);
        if (data['success'] == true) {
          return CommunityResult(
            success: true,
            data: CommunityPost.fromJson(data['data']),
          );
        }
      }
      return CommunityResult(success: false, message: 'Imeshindwa kutuma');
    } catch (e) {
      return CommunityResult(success: false, message: 'Kosa: $e');
    }
  }

  Future<CommunityResult<void>> likePost(int postId, int userId) async {
    try {
      final response = await http.post(
        Uri.parse('$_baseUrl/community/posts/$postId/like'),
        headers: ApiConfig.headers,
        body: jsonEncode({'user_id': userId}),
      );
      if (response.statusCode == 200) {
        return CommunityResult(success: true);
      }
      return CommunityResult(success: false, message: 'Imeshindwa');
    } catch (e) {
      return CommunityResult(success: false, message: 'Kosa: $e');
    }
  }

  // ─── Local Services ────────────────────────────────────────────

  Future<CommunityListResult<LocalService>> getNearbyServices({
    required double latitude,
    required double longitude,
    LocalServiceType? type,
    int page = 1,
    int perPage = 20,
  }) async {
    try {
      final params = <String, String>{
        'latitude': '$latitude',
        'longitude': '$longitude',
        'page': '$page',
        'per_page': '$perPage',
      };
      if (type != null) params['type'] = type.name;

      final uri = Uri.parse('$_baseUrl/community/services')
          .replace(queryParameters: params);
      final response = await http.get(uri);

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        if (data['success'] == true) {
          final items = (data['data'] as List)
              .map((j) => LocalService.fromJson(j))
              .toList();
          return CommunityListResult(success: true, items: items);
        }
      }
      return CommunityListResult(
        success: false,
        message: 'Imeshindwa kupakia huduma',
      );
    } catch (e) {
      return CommunityListResult(success: false, message: 'Kosa: $e');
    }
  }
}
