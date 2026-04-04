import 'dart:convert';
import 'package:flutter/foundation.dart';
import 'package:http/http.dart' as http;
import '../config/api_config.dart';
import '../models/content_engine_models.dart';
import 'local_storage_service.dart';
import 'etag_cache_service.dart';
import 'perf_logger.dart';

String get _baseUrl => ApiConfig.baseUrl;

/// Service wrapping the Content Engine v2 API.
class ContentEngineService {

  /// Fetch a personalized feed via the Content Engine v2 pipeline.
  static Future<ContentEngineResult> feed({
    required String feedType,
    required int userId,
    int page = 1,
    int perPage = 20,
  }) async {
    final token = await _getToken();
    if (token == null) return _emptyResult();

    try {
      final uri = Uri.parse('$_baseUrl/v2/feed').replace(queryParameters: {
        'feed_type': feedType,
        'page': page.toString(),
        'per_page': perPage.toString(),
      });

      // ETag conditional request support
      final urlString = uri.toString();
      final headers = Map<String, String>.from(ApiConfig.authHeaders(token));
      try {
        final cachedEtag = await ETagCacheService.instance.getETag(urlString);
        if (cachedEtag != null) {
          headers['If-None-Match'] = cachedEtag;
        }
      } catch (_) {}

      final response = await http.get(uri, headers: headers)
          .timeout(const Duration(seconds: 10));

      // 304 Not Modified — use cached body
      if (response.statusCode == 304) {
        try {
          final cachedBody = await ETagCacheService.instance.getCachedBody(urlString);
          if (cachedBody != null) {
            final data = json.decode(cachedBody) as Map<String, dynamic>;
            if (data['success'] == true) {
              PerfLogger.etagHits++;
              PerfLogger.log('etag_304', {'url': urlString});
              return ContentEngineResult.fromJson(data);
            }
          }
        } catch (_) {}
        // If cached body missing/corrupt, fall through to empty result
      }

      if (response.statusCode == 200) {
        // Store ETag if present
        final etag = response.headers['etag'];
        if (etag != null) {
          ETagCacheService.instance.store(urlString, etag, response.body);
          PerfLogger.etagMisses++;
          PerfLogger.log('etag_200_stored', {'url': urlString});
        }

        final data = json.decode(response.body) as Map<String, dynamic>;
        if (data['success'] == true) {
          return ContentEngineResult.fromJson(data);
        }
      }

      if (kDebugMode) debugPrint('[ContentEngineService] feed returned ${response.statusCode}');
      return _emptyResult();
    } catch (e) {
      if (kDebugMode) debugPrint('[ContentEngineService] feed error: $e');
      return _emptyResult();
    }
  }

  /// Search content via the Content Engine v2 pipeline.
  static Future<ContentEngineResult> search({
    required String query,
    required int userId,
    List<String>? types,
    String? category,
    String? region,
    String sort = 'relevance',
    int page = 1,
    int perPage = 20,
  }) async {
    final token = await _getToken();
    if (token == null) return _emptyResult();

    try {
      final params = <String, String>{
        'q': query,
        'sort': sort,
        'page': page.toString(),
        'per_page': perPage.toString(),
      };
      if (types != null && types.isNotEmpty) params['types'] = types.join(',');
      if (category != null) params['category'] = category;
      if (region != null) params['region'] = region;

      final uri = Uri.parse('$_baseUrl/v2/search').replace(queryParameters: params);
      final response = await http.get(uri, headers: ApiConfig.authHeaders(token))
          .timeout(const Duration(seconds: 10));

      if (response.statusCode == 200) {
        final data = json.decode(response.body) as Map<String, dynamic>;
        if (data['success'] == true) {
          return ContentEngineResult.fromJson(data);
        }
      }

      return _emptyResult();
    } catch (e) {
      debugPrint('[ContentEngineService] search error: $e');
      return _emptyResult();
    }
  }

  /// Fetch the latest AI-generated trending digest.
  /// Tries v2 endpoint first, falls back to gossip/digest.
  static Future<TrendingDigest?> getTrendingDigest() async {
    final token = await _getToken();
    try {
      // Try v2 first (Content Engine AI digest)
      final uri = Uri.parse('$_baseUrl/v2/trending-digest');
      final headers = token != null ? ApiConfig.authHeaders(token) : ApiConfig.headers;
      final response = await http.get(uri, headers: headers)
          .timeout(const Duration(seconds: 5));

      if (response.statusCode == 200) {
        final data = json.decode(response.body) as Map<String, dynamic>;
        final digestJson = data['data'] is Map<String, dynamic>
            ? data['data'] as Map<String, dynamic>
            : data;
        return TrendingDigest.fromJson(digestJson);
      }
      return null;
    } catch (e) {
      debugPrint('[ContentEngineService] getTrendingDigest error: $e');
      return null;
    }
  }

  /// Fetch "more like this" similar content for a document.
  static Future<ContentEngineResult> similar({
    required int documentId,
    required int userId,
    int limit = 10,
  }) async {
    final token = await _getToken();
    if (token == null) return _emptyResult();

    try {
      final uri = Uri.parse('$_baseUrl/v2/similar').replace(queryParameters: {
        'document_id': documentId.toString(),
        'limit': limit.toString(),
      });
      final response = await http.get(uri, headers: ApiConfig.authHeaders(token))
          .timeout(const Duration(seconds: 5));

      if (response.statusCode == 200) {
        final data = json.decode(response.body) as Map<String, dynamic>;
        if (data['success'] == true) {
          return ContentEngineResult.fromJson(data);
        }
      }
      return _emptyResult();
    } catch (e) {
      debugPrint('[ContentEngineService] similar error: $e');
      return _emptyResult();
    }
  }

  /// Mark content as "not interested" — sends negative signal to Content Engine.
  static Future<void> markNotInterested({
    required int documentId,
    required int userId,
  }) async {
    final token = await _getToken();
    if (token == null) return;

    try {
      final uri = Uri.parse('$_baseUrl/v2/not-interested');
      await http.post(
        uri,
        headers: ApiConfig.authHeaders(token),
        body: json.encode({'document_id': documentId}),
      ).timeout(const Duration(seconds: 5));
    } catch (e) {
      debugPrint('[ContentEngineService] markNotInterested error: $e');
    }
  }

  // --- Private helpers ---

  static ContentEngineResult _emptyResult() {
    return ContentEngineResult(items: [], meta: ContentEngineMeta());
  }

  static Future<String?> _getToken() async {
    try {
      final storage = await LocalStorageService.getInstance();
      return storage.getAuthToken();
    } catch (_) {
      return null;
    }
  }
}
