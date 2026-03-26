import 'dart:convert';
import 'package:flutter/foundation.dart';
import 'package:http/http.dart' as http;
import '../config/api_config.dart';
import '../models/sponsored_post_models.dart';

String get _baseUrl => ApiConfig.baseUrl;

class SponsoredPostService {
  Future<List<SponsoredPost>> getActiveSponsoredPosts({required String token}) async {
    try {
      final response = await http.get(
        Uri.parse('$_baseUrl/sponsored-posts'),
        headers: ApiConfig.authHeaders(token),
      );
      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        final rawList = data['data'] is List ? data['data'] as List : [];
        return rawList.whereType<Map<String, dynamic>>()
            .map((e) => SponsoredPost.fromJson(e)).toList();
      }
      return [];
    } catch (e) {
      debugPrint('[SponsoredPostService] getActive error: $e');
      return [];
    }
  }

  Future<List<SponsorableCreator>> browseSponsorableCreators({required String token}) async {
    try {
      final response = await http.get(
        Uri.parse('$_baseUrl/sponsored-posts/creators'),
        headers: ApiConfig.authHeaders(token),
      );
      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        final rawList = data['data'] is List ? data['data'] as List : [];
        return rawList.whereType<Map<String, dynamic>>()
            .map((e) => SponsorableCreator.fromJson(e)).toList();
      }
      return [];
    } catch (e) {
      debugPrint('[SponsoredPostService] browseCreators error: $e');
      return [];
    }
  }

  Future<bool> createSponsoredPost({
    required String token,
    required int postId,
    required int creatorUserId,
    required double budget,
    required int impressionsTarget,
  }) async {
    try {
      final response = await http.post(
        Uri.parse('$_baseUrl/sponsored-posts'),
        headers: {...ApiConfig.authHeaders(token), 'Content-Type': 'application/json'},
        body: jsonEncode({
          'post_id': postId,
          'creator_user_id': creatorUserId,
          'budget': budget,
          'impressions_target': impressionsTarget,
        }),
      );
      return response.statusCode == 200 || response.statusCode == 201;
    } catch (e) {
      debugPrint('[SponsoredPostService] create error: $e');
      return false;
    }
  }

  Future<List<SponsoredPost>> getCreatorSponsored({required String token, required int creatorId}) async {
    try {
      final response = await http.get(
        Uri.parse('$_baseUrl/creators/$creatorId/sponsored'),
        headers: ApiConfig.authHeaders(token),
      );
      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        final rawList = data['data'] is List ? data['data'] as List : [];
        return rawList.whereType<Map<String, dynamic>>()
            .map((e) => SponsoredPost.fromJson(e)).toList();
      }
      return [];
    } catch (e) {
      debugPrint('[SponsoredPostService] getCreatorSponsored error: $e');
      return [];
    }
  }
}
