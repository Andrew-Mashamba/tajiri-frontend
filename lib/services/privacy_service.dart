import 'dart:convert';
import 'package:http/http.dart' as http;
import '../config/api_config.dart';
import '../models/privacy_settings_model.dart';
import 'local_storage_service.dart';

String get _baseUrl => ApiConfig.baseUrl;

class PrivacyService {
  /// Retrieve auth token from local storage.
  Future<String?> _getToken() async {
    final storage = await LocalStorageService.getInstance();
    return storage.getAuthToken();
  }

  /// Get privacy settings for the current user.
  Future<PrivacySettingsResult> getPrivacySettings(int userId) async {
    try {
      final token = await _getToken();
      final response = await http.get(
        Uri.parse('$_baseUrl/users/$userId/privacy-settings'),
        headers: token != null ? ApiConfig.authHeaders(token) : ApiConfig.headers,
      );

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        if (data['success'] == true && data['data'] != null) {
          return PrivacySettingsResult(
            success: true,
            settings: PrivacySettings.fromJson(
              data['data'] as Map<String, dynamic>,
            ),
          );
        }
        // Some endpoints return data directly without success wrapper
        if (data['data'] != null || data['profile_visibility'] != null) {
          final settingsData = data['data'] as Map<String, dynamic>? ?? data;
          return PrivacySettingsResult(
            success: true,
            settings: PrivacySettings.fromJson(settingsData),
          );
        }
        return PrivacySettingsResult(
          success: false,
          message: data['message'] as String? ?? 'Imeshindwa kupakia mipangilio',
        );
      }
      return PrivacySettingsResult(
        success: false,
        message: 'Imeshindwa kupakia mipangilio',
      );
    } catch (e) {
      return PrivacySettingsResult(
        success: false,
        message: 'Hitilafu: $e',
      );
    }
  }

  /// Update all privacy settings at once.
  Future<PrivacySettingsResult> updatePrivacySettings(
    int userId,
    PrivacySettings settings,
  ) async {
    try {
      final token = await _getToken();
      final response = await http.put(
        Uri.parse('$_baseUrl/users/$userId/privacy-settings'),
        headers: token != null ? ApiConfig.authHeaders(token) : ApiConfig.headers,
        body: jsonEncode(settings.toJson()),
      );

      final data = jsonDecode(response.body);

      if (response.statusCode == 200 && (data['success'] == true || response.statusCode == 200)) {
        return PrivacySettingsResult(
          success: true,
          settings: data['data'] != null
              ? PrivacySettings.fromJson(
                  data['data'] as Map<String, dynamic>,
                )
              : settings,
          message: data['message'] as String?,
        );
      }
      return PrivacySettingsResult(
        success: false,
        message: data['message'] as String? ?? 'Imeshindwa kuhifadhi mipangilio',
      );
    } catch (e) {
      return PrivacySettingsResult(
        success: false,
        message: 'Hitilafu: $e',
      );
    }
  }

  /// Update a single privacy preference by key.
  /// Uses PATCH for granular updates (same pattern as notification preferences).
  Future<bool> updateSinglePreference(int userId, String key, dynamic value) async {
    try {
      final token = await _getToken();
      final response = await http.patch(
        Uri.parse('$_baseUrl/users/$userId/privacy-settings'),
        headers: token != null ? ApiConfig.authHeaders(token) : ApiConfig.headers,
        body: jsonEncode({key: value}),
      );

      return response.statusCode == 200;
    } catch (_) {
      return false;
    }
  }
}

class PrivacySettingsResult {
  final bool success;
  final PrivacySettings? settings;
  final String? message;

  PrivacySettingsResult({
    required this.success,
    this.settings,
    this.message,
  });
}
