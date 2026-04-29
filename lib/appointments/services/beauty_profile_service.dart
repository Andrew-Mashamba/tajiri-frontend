import 'dart:convert';

import 'package:flutter/foundation.dart';
import 'package:http/http.dart' as http;

import '../../config/api_config.dart';

/// Spec line 614+ — customer beauty profile (skin type / hair type / allergies / concerns).
/// Stored on user_profiles.beauty_profile jsonb. Partner reads at booking time.
class BeautyProfile {
  final String? skinType;
  final String? hairType;
  final List<String> allergies;
  final List<String> concerns;
  BeautyProfile({this.skinType, this.hairType, this.allergies = const [], this.concerns = const []});
  factory BeautyProfile.fromJson(Map<String, dynamic> json) => BeautyProfile(
        skinType: json['skin_type']?.toString(),
        hairType: json['hair_type']?.toString(),
        allergies: (json['allergies'] is List)
            ? (json['allergies'] as List).map((e) => e.toString()).toList()
            : const [],
        concerns: (json['concerns'] is List)
            ? (json['concerns'] as List).map((e) => e.toString()).toList()
            : const [],
      );
  bool get isEmpty =>
      (skinType == null || skinType!.isEmpty) &&
      (hairType == null || hairType!.isEmpty) &&
      allergies.isEmpty &&
      concerns.isEmpty;
}

class BeautyProfileService {
  static String get _baseUrl => ApiConfig.baseUrl;

  static Future<BeautyProfile?> get(int userId) async {
    final uri = Uri.parse('$_baseUrl/users/$userId/beauty-profile');
    debugPrint('[BeautyProfileService] GET $uri');
    try {
      final res = await http.get(uri);
      if (res.statusCode == 200) {
        final body = jsonDecode(res.body);
        if (body['success'] == true && body['data'] is Map) {
          return BeautyProfile.fromJson((body['data'] as Map).cast<String, dynamic>());
        }
      }
      return null;
    } catch (_) {
      return null;
    }
  }

  static Future<bool> save(int userId, BeautyProfile profile) async {
    final uri = Uri.parse('$_baseUrl/users/beauty-profile');
    final body = <String, dynamic>{'user_id': userId};
    if (profile.skinType != null) body['skin_type'] = profile.skinType;
    if (profile.hairType != null) body['hair_type'] = profile.hairType;
    body['allergies'] = profile.allergies;
    body['concerns'] = profile.concerns;
    try {
      final res = await http.post(
        uri,
        headers: const {'Content-Type': 'application/json'},
        body: jsonEncode(body),
      );
      return res.statusCode == 200;
    } catch (_) {
      return false;
    }
  }
}
