import 'dart:convert';
import 'dart:io';
import 'package:http/http.dart' as http;
import '../models/profile_models.dart';
import '../config/api_config.dart';

String get _baseUrl => ApiConfig.baseUrl;

class ProfileService {
  /// Get full profile for a user
  Future<ProfileResult> getProfile({
    required int userId,
    int? currentUserId,
  }) async {
    try {
      String url = '$_baseUrl/users/$userId';
      if (currentUserId != null) {
        url += '?current_user_id=$currentUserId';
      }

      print('[ProfileService] Fetching profile from: $url');
      final response = await http.get(Uri.parse(url));
      print('[ProfileService] Response status: ${response.statusCode}');

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        print('[ProfileService] Response success: ${data['success']}');
        if (data['success'] == true) {
          return ProfileResult(
            success: true,
            profile: FullProfile.fromJson(data['data']),
          );
        }
        return ProfileResult(success: false, message: data['message'] ?? 'Failed to load profile');
      }
      print('[ProfileService] Non-200 response: ${response.body}');
      return ProfileResult(success: false, message: 'Profile not found');
    } catch (e) {
      print('[ProfileService] Error: $e');
      return ProfileResult(success: false, message: 'Error: $e');
    }
  }

  /// Update profile photo
  Future<PhotoUpdateResult> updateProfilePhoto({
    required int userId,
    required File photo,
  }) async {
    try {
      var request = http.MultipartRequest(
        'POST',
        Uri.parse('$_baseUrl/users/$userId/profile-photo'),
      );

      request.files.add(await http.MultipartFile.fromPath('photo', photo.path));

      final streamedResponse = await request.send();
      final response = await http.Response.fromStream(streamedResponse);
      final data = jsonDecode(response.body);

      if (response.statusCode == 200 && data['success'] == true) {
        return PhotoUpdateResult(
          success: true,
          photoUrl: data['data']['profile_photo_url'],
          message: data['message'],
        );
      }
      return PhotoUpdateResult(success: false, message: data['message'] ?? 'Failed to update photo');
    } catch (e) {
      return PhotoUpdateResult(success: false, message: 'Error: $e');
    }
  }

  /// Update cover photo
  Future<PhotoUpdateResult> updateCoverPhoto({
    required int userId,
    required File photo,
  }) async {
    try {
      var request = http.MultipartRequest(
        'POST',
        Uri.parse('$_baseUrl/users/$userId/cover-photo'),
      );

      request.files.add(await http.MultipartFile.fromPath('photo', photo.path));

      final streamedResponse = await request.send();
      final response = await http.Response.fromStream(streamedResponse);
      final data = jsonDecode(response.body);

      if (response.statusCode == 200 && data['success'] == true) {
        return PhotoUpdateResult(
          success: true,
          photoUrl: data['data']['cover_photo_url'],
          message: data['message'],
        );
      }
      return PhotoUpdateResult(success: false, message: data['message'] ?? 'Failed to update cover photo');
    } catch (e) {
      return PhotoUpdateResult(success: false, message: 'Error: $e');
    }
  }

  /// Update bio and interests
  Future<BioUpdateResult> updateBio({
    required int userId,
    String? bio,
    List<String>? interests,
    String? relationshipStatus,
  }) async {
    try {
      final response = await http.put(
        Uri.parse('$_baseUrl/users/$userId/bio'),
        headers: {'Content-Type': 'application/json'},
        body: jsonEncode({
          if (bio != null) 'bio': bio,
          if (interests != null) 'interests': interests,
          if (relationshipStatus != null) 'relationship_status': relationshipStatus,
        }),
      );

      final data = jsonDecode(response.body);

      if (response.statusCode == 200 && data['success'] == true) {
        return BioUpdateResult(
          success: true,
          bio: data['data']['bio'],
          interests: data['data']['interests'] != null
              ? List<String>.from(data['data']['interests'])
              : null,
          relationshipStatus: data['data']['relationship_status'],
          message: data['message'],
        );
      }
      return BioUpdateResult(success: false, message: data['message'] ?? 'Failed to update bio');
    } catch (e) {
      return BioUpdateResult(success: false, message: 'Error: $e');
    }
  }

  /// Update username
  Future<UsernameUpdateResult> updateUsername({
    required int userId,
    required String username,
  }) async {
    try {
      final response = await http.put(
        Uri.parse('$_baseUrl/users/$userId/username'),
        headers: {'Content-Type': 'application/json'},
        body: jsonEncode({'username': username}),
      );

      final data = jsonDecode(response.body);

      if (response.statusCode == 200 && data['success'] == true) {
        return UsernameUpdateResult(
          success: true,
          username: data['data']['username'],
          message: data['message'],
        );
      }
      return UsernameUpdateResult(success: false, message: data['message'] ?? 'Failed to update username');
    } catch (e) {
      return UsernameUpdateResult(success: false, message: 'Error: $e');
    }
  }
}

// Result classes
class ProfileResult {
  final bool success;
  final FullProfile? profile;
  final String? message;

  ProfileResult({required this.success, this.profile, this.message});
}

class PhotoUpdateResult {
  final bool success;
  final String? photoUrl;
  final String? message;

  PhotoUpdateResult({required this.success, this.photoUrl, this.message});
}

class BioUpdateResult {
  final bool success;
  final String? bio;
  final List<String>? interests;
  final String? relationshipStatus;
  final String? message;

  BioUpdateResult({
    required this.success,
    this.bio,
    this.interests,
    this.relationshipStatus,
    this.message,
  });
}

class UsernameUpdateResult {
  final bool success;
  final String? username;
  final String? message;

  UsernameUpdateResult({required this.success, this.username, this.message});
}
