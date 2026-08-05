import 'dart:convert';
import 'package:flutter/foundation.dart';
import 'package:http/http.dart' as http;
import 'http_retry.dart';
import '../config/api_config.dart';
import '../models/sponsored_post_models.dart';
import 'graphql/graphql_sponsored_post_service.dart';

String get _baseUrl => ApiConfig.baseUrl;

class SponsoredPostService {
  Future<List<SponsoredPost>> getActiveSponsoredPosts({required String token}) async {
    if (ApiConfig.useGraphqlBackend) {
      return GraphqlSponsoredPostService.getActiveSponsoredPosts();
    }
    try {
      final response = await httpGetWithRetry(
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
    if (ApiConfig.useGraphqlBackend) {
      return GraphqlSponsoredPostService.browseSponsorableCreators();
    }
    try {
      final response = await httpGetWithRetry(
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
    if (ApiConfig.useGraphqlBackend) {
      return GraphqlSponsoredPostService.createSponsoredPost(
        postId: postId,
        creatorUserId: creatorUserId,
        budget: budget,
        impressionsTarget: impressionsTarget,
      );
    }
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
    if (ApiConfig.useGraphqlBackend) {
      return GraphqlSponsoredPostService.getCreatorSponsored(creatorId);
    }
    try {
      final response = await httpGetWithRetry(
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
