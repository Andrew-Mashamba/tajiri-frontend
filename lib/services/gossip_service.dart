import 'dart:convert';
import 'package:flutter/foundation.dart';
import 'package:http/http.dart' as http;
import '../config/api_config.dart';
import '../models/gossip_models.dart';

String get _baseUrl => ApiConfig.baseUrl;

class GossipService {
  /// Get list of gossip threads, optionally filtered by status and category.
  Future<List<GossipThread>> getThreads({
    required String token,
    String status = 'active',
    String? category,
    int page = 1,
    int perPage = 20,
  }) async {
    try {
      var url = '$_baseUrl/gossip/threads?status=$status&page=$page&per_page=$perPage';
      if (category != null && category.isNotEmpty) {
        url += '&category=$category';
      }
      final response = await http.get(
        Uri.parse(url),
        headers: ApiConfig.authHeaders(token),
      );
      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        final rawList = data['data'] is List ? data['data'] as List : [];
        final threads = <GossipThread>[];
        for (final item in rawList) {
          if (item is Map<String, dynamic>) {
            try {
              threads.add(GossipThread.fromJson(item));
            } catch (e) {
              debugPrint('[GossipService] Skipping thread: $e');
            }
          }
        }
        return threads;
      }
      return [];
    } catch (e) {
      debugPrint('[GossipService] getThreads error: $e');
      return [];
    }
  }

  /// Get a single gossip thread with its posts.
  Future<GossipThreadDetail?> getThread({
    required String token,
    required int threadId,
  }) async {
    try {
      final response = await http.get(
        Uri.parse('$_baseUrl/gossip/threads/$threadId'),
        headers: ApiConfig.authHeaders(token),
      );
      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        if (data['data'] is Map<String, dynamic>) {
          return GossipThreadDetail.fromJson(data['data'] as Map<String, dynamic>);
        }
      }
      return null;
    } catch (e) {
      debugPrint('[GossipService] getThread error: $e');
      return null;
    }
  }

  /// Get personalized digest with top threads and proverb.
  Future<DigestResponse?> getDigest({required String token}) async {
    try {
      final response = await http.get(
        Uri.parse('$_baseUrl/gossip/digest'),
        headers: ApiConfig.authHeaders(token),
      );
      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        if (data['data'] is Map<String, dynamic>) {
          return DigestResponse.fromJson(data['data'] as Map<String, dynamic>);
        }
      }
      return null;
    } catch (e) {
      debugPrint('[GossipService] getDigest error: $e');
      return null;
    }
  }
}
