import 'dart:convert';
import 'package:http/http.dart' as http;
import '../config/api_config.dart';
import '../models/privacy_settings_model.dart';

String get _baseUrl => ApiConfig.baseUrl;

class PrivacyService {
  /// Get privacy settings for the current user
  Future<PrivacySettingsResult> getPrivacySettings(int userId) async {
    try {
      final response = await http.get(
        Uri.parse('$_baseUrl/users/$userId/privacy-settings'),
        headers: ApiConfig.headers,
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

  /// Update privacy settings
  Future<PrivacySettingsResult> updatePrivacySettings(
    int userId,
    PrivacySettings settings,
  ) async {
    try {
      final response = await http.put(
        Uri.parse('$_baseUrl/users/$userId/privacy-settings'),
        headers: ApiConfig.headers,
        body: jsonEncode(settings.toJson()),
      );

      final data = jsonDecode(response.body);

      if (response.statusCode == 200 && data['success'] == true) {
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
