import 'dart:convert';
import 'dart:io';
import 'package:flutter/foundation.dart';
import 'package:http/http.dart' as http;
import '../models/ad_models.dart';
import '../config/api_config.dart';
import 'expenditure_service.dart';
import 'income_service.dart';
import 'local_storage_service.dart';

void _log(String message) {
  if (kDebugMode) debugPrint('[AdService] $message');
}

/// Service for the Tajiri ad system — serving, recording events, campaign CRUD,
/// creative upload, status actions, performance and balance management.
class AdService {
  static String get _baseUrl => ApiConfig.baseUrl;

  // ---------------------------------------------------------------------------
  // Ad serving
  // ---------------------------------------------------------------------------

  /// Fetch a list of ads to serve in [placement] (e.g. 'feed', 'story').
  static Future<List<ServedAd>> getServedAds(
    String? token,
    String placement,
    int count,
  ) async {
    try {
      // Resolve user_id — backend requires it
      final storage = await LocalStorageService.getInstance();
      final userId = storage.getUser()?.userId;

      final params = <String, String>{
        'placement': placement,
        'count': count.toString(),
      };
      if (userId != null) params['user_id'] = userId.toString();

      final uri = Uri.parse('$_baseUrl/ads/serve').replace(queryParameters: params);
      final response = await http.get(
        uri,
        headers: token != null ? ApiConfig.authHeaders(token) : ApiConfig.headers,
      );
      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        final raw = data['data'] ?? data['ads'] ?? data;
        if (raw is List) {
          return raw
              .whereType<Map<String, dynamic>>()
              .map(ServedAd.fromJson)
              .toList();
        }
      }
      if (response.statusCode != 404) {
        _log('getServedAds failed: ${response.statusCode}');
      }
      return [];
    } catch (e) {
      _log('getServedAds error: $e');
      return [];
    }
  }

  /// Record an impression or click event for an ad.
  static Future<bool> recordAdEvent(
    String? token,
    int campaignId,
    int creativeId,
    int userId,
    String placement,
    String eventType,
  ) async {
    try {
      final uri = Uri.parse('$_baseUrl/ads/event');
      final response = await http.post(
        uri,
        headers: token != null
            ? ApiConfig.authHeaders(token)
            : ApiConfig.headers,
        body: jsonEncode({
          'campaign_id': campaignId,
          'creative_id': creativeId,
          'user_id': userId,
          'placement': placement,
          'event_type': eventType,
        }),
      );
      return response.statusCode == 200 || response.statusCode == 201;
    } catch (e) {
      _log('recordAdEvent error: $e');
      return false;
    }
  }

  /// Report AdMob revenue earned for a placement so the platform can track it.
  static Future<bool> reportAdMobRevenue(
    String? token,
    int userId,
    String placement,
    double revenue,
  ) async {
    try {
      final uri = Uri.parse('$_baseUrl/ads/admob-revenue');
      final response = await http.post(
        uri,
        headers: token != null
            ? ApiConfig.authHeaders(token)
            : ApiConfig.headers,
        body: jsonEncode({
          'user_id': userId,
          'placement': placement,
          'revenue': revenue,
        }),
      );
      final success = response.statusCode == 200 || response.statusCode == 201;
      // Fire-and-forget: record ad revenue as income in budget system
      if (success && token != null) {
        IncomeService.recordIncome(
          token: token,
          amount: revenue,
          source: 'ad_revenue',
          description: 'AdMob revenue: $placement',
          referenceId: 'admob_${DateTime.now().millisecondsSinceEpoch}',
          sourceModule: 'ad',
        ).catchError((_) => null);
      }
      return success;
    } catch (e) {
      _log('reportAdMobRevenue error: $e');
      return false;
    }
  }

  // ---------------------------------------------------------------------------
  // Campaign CRUD
  // ---------------------------------------------------------------------------

  /// List all campaigns belonging to the authenticated advertiser.
  static Future<List<AdCampaign>> getCampaigns(String? token) async {
    try {
      final uri = Uri.parse('$_baseUrl/biashara/campaigns');
      final response = await http.get(
        uri,
        headers: token != null ? ApiConfig.authHeaders(token) : ApiConfig.headers,
      );
      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        final raw = data['data'] ?? data['campaigns'] ?? data;
        if (raw is List) {
          return raw
              .whereType<Map<String, dynamic>>()
              .map(AdCampaign.fromJson)
              .toList();
        }
      }
      _log('getCampaigns failed: ${response.statusCode}');
      return [];
    } catch (e) {
      _log('getCampaigns error: $e');
      return [];
    }
  }

  /// Create a new ad campaign.
  static Future<AdCampaign?> createCampaign(
    String? token,
    Map<String, dynamic> data,
  ) async {
    try {
      final uri = Uri.parse('$_baseUrl/biashara/campaigns');
      final response = await http.post(
        uri,
        headers: token != null
            ? ApiConfig.authHeaders(token)
            : ApiConfig.headers,
        body: jsonEncode(data),
      );
      if (response.statusCode == 200 || response.statusCode == 201) {
        final body = jsonDecode(response.body);
        final raw = body['data'] ?? body['campaign'] ?? body;
        if (raw is Map<String, dynamic>) return AdCampaign.fromJson(raw);
      }
      _log('createCampaign failed: ${response.statusCode} ${response.body}');
      return null;
    } catch (e) {
      _log('createCampaign error: $e');
      return null;
    }
  }

  /// Fetch a single campaign by [id].
  static Future<AdCampaign?> getCampaign(String? token, int id) async {
    try {
      final uri = Uri.parse('$_baseUrl/biashara/campaigns/$id');
      final response = await http.get(
        uri,
        headers: token != null ? ApiConfig.authHeaders(token) : ApiConfig.headers,
      );
      if (response.statusCode == 200) {
        final body = jsonDecode(response.body);
        final raw = body['data'] ?? body['campaign'] ?? body;
        if (raw is Map<String, dynamic>) return AdCampaign.fromJson(raw);
      }
      _log('getCampaign failed: ${response.statusCode}');
      return null;
    } catch (e) {
      _log('getCampaign error: $e');
      return null;
    }
  }

  /// Update campaign fields. Returns the updated campaign on success.
  static Future<AdCampaign?> updateCampaign(
    String? token,
    int id,
    Map<String, dynamic> data,
  ) async {
    try {
      final uri = Uri.parse('$_baseUrl/biashara/campaigns/$id');
      final response = await http.put(
        uri,
        headers: token != null
            ? ApiConfig.authHeaders(token)
            : ApiConfig.headers,
        body: jsonEncode(data),
      );
      if (response.statusCode == 200) {
        final body = jsonDecode(response.body);
        final raw = body['data'] ?? body['campaign'] ?? body;
        if (raw is Map<String, dynamic>) return AdCampaign.fromJson(raw);
      }
      _log('updateCampaign failed: ${response.statusCode} ${response.body}');
      return null;
    } catch (e) {
      _log('updateCampaign error: $e');
      return null;
    }
  }

  // ---------------------------------------------------------------------------
  // Creative upload
  // ---------------------------------------------------------------------------

  /// Upload a creative for a campaign. Optionally attach a [mediaFile].
  static Future<AdCreative?> uploadCreative(
    String? token,
    int campaignId,
    Map<String, dynamic> data, {
    File? mediaFile,
  }) async {
    try {
      final uri = Uri.parse('$_baseUrl/biashara/campaigns/$campaignId/creatives');
      final request = http.MultipartRequest('POST', uri);

      if (token != null) {
        request.headers.addAll(ApiConfig.authHeaders(token)
          ..remove('Content-Type')); // multipart sets its own
      }

      // Add string fields
      data.forEach((key, value) {
        if (value != null) request.fields[key] = value.toString();
      });

      // Attach media file if provided
      if (mediaFile != null) {
        final stream = http.ByteStream(mediaFile.openRead());
        final length = await mediaFile.length();
        final fileName = mediaFile.path.split(Platform.pathSeparator).last;
        request.files.add(http.MultipartFile(
          'media_file',
          stream,
          length,
          filename: fileName,
        ));
      }

      final streamed = await request.send();
      final response = await http.Response.fromStream(streamed);

      if (response.statusCode == 200 || response.statusCode == 201) {
        final body = jsonDecode(response.body);
        final raw = body['data'] ?? body['creative'] ?? body;
        if (raw is Map<String, dynamic>) return AdCreative.fromJson(raw);
      }
      _log('uploadCreative failed: ${response.statusCode} ${response.body}');
      return null;
    } catch (e) {
      _log('uploadCreative error: $e');
      return null;
    }
  }

  // ---------------------------------------------------------------------------
  // Status actions
  // ---------------------------------------------------------------------------

  /// Submit a draft campaign for review.
  static Future<bool> submitCampaign(String? token, int id) async =>
      _postAction(token, '$_baseUrl/biashara/campaigns/$id/submit');

  /// Pause an active campaign.
  static Future<bool> pauseCampaign(String? token, int id) async =>
      _postAction(token, '$_baseUrl/biashara/campaigns/$id/pause');

  /// Resume a paused campaign.
  static Future<bool> resumeCampaign(String? token, int id) async =>
      _postAction(token, '$_baseUrl/biashara/campaigns/$id/resume');

  /// Cancel a campaign.
  static Future<bool> cancelCampaign(String? token, int id) async =>
      _postAction(token, '$_baseUrl/biashara/campaigns/$id/cancel');

  static Future<bool> _postAction(String? token, String url) async {
    try {
      final response = await http.post(
        Uri.parse(url),
        headers: token != null
            ? ApiConfig.authHeaders(token)
            : ApiConfig.headers,
      );
      return response.statusCode == 200 || response.statusCode == 201;
    } catch (e) {
      _log('_postAction error ($url): $e');
      return false;
    }
  }

  // ---------------------------------------------------------------------------
  // Performance
  // ---------------------------------------------------------------------------

  /// Fetch aggregated performance metrics for a campaign.
  static Future<AdPerformance?> getCampaignPerformance(
    String? token,
    int id,
  ) async {
    try {
      final uri = Uri.parse('$_baseUrl/biashara/campaigns/$id/performance');
      final response = await http.get(
        uri,
        headers: token != null ? ApiConfig.authHeaders(token) : ApiConfig.headers,
      );
      if (response.statusCode == 200) {
        final body = jsonDecode(response.body);
        final raw = body['data'] ?? body['performance'] ?? body;
        if (raw is Map<String, dynamic>) return AdPerformance.fromJson(raw);
      }
      _log('getCampaignPerformance failed: ${response.statusCode}');
      return null;
    } catch (e) {
      _log('getCampaignPerformance error: $e');
      return null;
    }
  }

  // ---------------------------------------------------------------------------
  // Balance
  // ---------------------------------------------------------------------------

  /// Get the current ad account balance for the authenticated user.
  static Future<double> getAdBalance(String? token) async {
    try {
      final uri = Uri.parse('$_baseUrl/biashara/balance');
      final response = await http.get(
        uri,
        headers: token != null ? ApiConfig.authHeaders(token) : ApiConfig.headers,
      );
      if (response.statusCode == 200) {
        final body = jsonDecode(response.body);
        final raw = body['data'] ?? body;
        if (raw is Map<String, dynamic>) {
          return (raw['ad_balance'] as num?)?.toDouble() ?? 0.0;
        }
      }
      _log('getAdBalance failed: ${response.statusCode}');
      return 0.0;
    } catch (e) {
      _log('getAdBalance error: $e');
      return 0.0;
    }
  }

  /// Deposit funds into the ad account balance.
  static Future<Map<String, dynamic>> depositAdBalance(
    String? token,
    double amount,
  ) async {
    try {
      final uri = Uri.parse('$_baseUrl/biashara/balance/deposit');
      final response = await http.post(
        uri,
        headers: token != null
            ? ApiConfig.authHeaders(token)
            : ApiConfig.headers,
        body: jsonEncode({'amount': amount}),
      );
      final body = jsonDecode(response.body) as Map<String, dynamic>? ?? {};
      // Fire-and-forget: record ad deposit as expenditure in budget system
      if (body['success'] == true && token != null) {
        ExpenditureService.recordExpenditure(
          token: token,
          amount: amount,
          category: 'biashara',
          description: 'Ad budget top-up',
          referenceId: 'ad_deposit_${DateTime.now().millisecondsSinceEpoch}',
          sourceModule: 'ad',
        ).catchError((_) => null);
      }
      return body;
    } catch (e) {
      _log('depositAdBalance error: $e');
      return {'success': false, 'message': e.toString()};
    }
  }

  // ---------------------------------------------------------------------------
  // Settings
  // ---------------------------------------------------------------------------

  /// Fetch client-facing ad settings (frequency caps, enabled placements, etc.).
  static Future<Map<String, dynamic>> getClientSettings(String? token) async {
    try {
      final uri = Uri.parse('$_baseUrl/ads/client-settings');
      final response = await http.get(
        uri,
        headers: token != null ? ApiConfig.authHeaders(token) : ApiConfig.headers,
      );
      if (response.statusCode == 200) {
        final body = jsonDecode(response.body);
        if (body is Map<String, dynamic>) {
          return body['data'] is Map<String, dynamic>
              ? body['data'] as Map<String, dynamic>
              : body;
        }
      }
      _log('getClientSettings failed: ${response.statusCode}');
      return {};
    } catch (e) {
      _log('getClientSettings error: $e');
      return {};
    }
  }
}
