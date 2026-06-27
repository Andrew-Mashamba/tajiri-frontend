import 'dart:convert';
import 'dart:io';

import 'package:flutter/foundation.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:http/http.dart' as http;

import '../../config/api_config.dart';

/// Multipart upload to greenfield backend `POST /media/upload`.
class GraphqlMediaService {
  static const _storage = FlutterSecureStorage(
    aOptions: AndroidOptions(encryptedSharedPreferences: true),
  );
  static const _accessTokenKey = 'tajiri_access_token';

  static Future<Map<String, dynamic>?> uploadFile(
    File file, {
    String mediaType = 'image',
    String? blurhash,
    int? width,
    int? height,
  }) async {
    if (!file.existsSync()) return null;
    final token = await _storage.read(key: _accessTokenKey);
    if (token == null || token.isEmpty) return null;

    try {
      final request = http.MultipartRequest(
        'POST',
        Uri.parse(ApiConfig.graphqlMediaUploadUrl),
      );
      request.headers['Authorization'] = 'Bearer $token';
      request.headers['Accept'] = 'application/json';
      request.fields['media_type'] = mediaType;
      if (blurhash != null) request.fields['blurhash'] = blurhash;
      if (width != null) request.fields['width'] = width.toString();
      if (height != null) request.fields['height'] = height.toString();
      request.files.add(await http.MultipartFile.fromPath('file', file.path));

      final streamed = await request.send().timeout(const Duration(minutes: 5));
      final response = await http.Response.fromStream(streamed);
      if (response.statusCode != 200) {
        if (kDebugMode) {
          debugPrint('[GraphqlMediaService] upload ${response.statusCode}: ${response.body}');
        }
        return null;
      }
      final body = jsonDecode(response.body) as Map<String, dynamic>;
      if (body['success'] != true) return null;
      return body['data'] as Map<String, dynamic>?;
    } catch (e) {
      if (kDebugMode) debugPrint('[GraphqlMediaService] upload: $e');
      return null;
    }
  }
}
