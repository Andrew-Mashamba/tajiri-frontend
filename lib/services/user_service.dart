import 'dart:convert';
import 'package:http/http.dart' as http;
import '../models/registration_models.dart';
import '../config/api_config.dart';

String get _baseUrl => ApiConfig.baseUrl;

class UserService {
  /// Register a new user profile on the server
  Future<UserRegistrationResult> register(RegistrationState profile) async {
    try {
      late final http.Response response;

      if (profile.profilePhotoPath != null) {
        // Multipart request when photo is provided
        var request = http.MultipartRequest(
          'POST',
          Uri.parse('$_baseUrl/users/register'),
        );

        final jsonData = profile.toJson();
        jsonData.forEach((key, value) {
          if (value != null && key != 'profile_photo_path' && key != 'face_bbox') {
            request.fields[key] = value is String ? value : jsonEncode(value);
          }
        });

        request.files.add(await http.MultipartFile.fromPath(
          'profile_photo',
          profile.profilePhotoPath!,
        ));

        if (profile.faceBbox != null) {
          request.fields['face_bbox'] = jsonEncode(profile.faceBbox);
        }

        final streamedResponse = await request.send();
        response = await http.Response.fromStream(streamedResponse);
      } else {
        response = await http.post(
          Uri.parse('$_baseUrl/users/register'),
          headers: {'Content-Type': 'application/json'},
          body: jsonEncode(profile.toJson()),
        );
      }

      final data = jsonDecode(response.body);

      if (response.statusCode == 201 && data['success'] == true) {
        final responseData = data['data'];
        final id = responseData is Map ? responseData['id'] : null;
        final userId = id is int ? id : (id is num ? id.toInt() : null);
        final Map<String, dynamic>? profileMap = responseData is Map<String, dynamic>
            ? Map<String, dynamic>.from(responseData)
            : null;
        final accessToken = profileMap?['access_token'] ?? profileMap?['token'] ?? data['access_token'] ?? data['token'];
        return UserRegistrationResult(
          success: true,
          userId: userId,
          message: data['message'] as String?,
          profileData: profileMap,
          accessToken: accessToken is String ? accessToken : accessToken?.toString(),
        );
      } else if (response.statusCode == 422) {
        final errors = data['errors'] as Map<String, dynamic>?;
        String errorMessage = data['message'] ?? 'Validation failed';
        if (errors != null && errors.containsKey('phone_number')) {
          errorMessage = 'Nambari hii ya simu imeshasajiliwa';
        }
        return UserRegistrationResult(
          success: false,
          message: errorMessage,
          errors: errors,
        );
      } else {
        return UserRegistrationResult(
          success: false,
          message: data['message'] ?? 'Registration failed',
        );
      }
    } catch (e) {
      return UserRegistrationResult(
        success: false,
        message: 'Imeshindwa kuwasiliana na seva: $e',
      );
    }
  }

  /// Check if a phone number is available for registration (uniqueness).
  /// POST /api/users/check-phone validates uniqueness; returns available/unavailable status.
  Future<PhoneAvailabilityResult> checkPhoneAvailability(String phoneNumber) async {
    try {
      final response = await http.post(
        Uri.parse('$_baseUrl/users/check-phone'),
        headers: {'Content-Type': 'application/json'},
        body: jsonEncode({'phone_number': phoneNumber}),
      );

      final body = response.body;
      if (body.isEmpty) {
        return const PhoneAvailabilityResult(
          available: false,
          message: 'Hakuna majibu kutoka kwa seva',
        );
      }

      final data = jsonDecode(body) as Map<String, dynamic>;

      if (response.statusCode == 200) {
        // Support both "available" and "exists" for backend flexibility
        bool available;
        if (data['available'] != null) {
          available = data['available'] == true;
        } else if (data['exists'] != null) {
          available = data['exists'] != true; // exists true => taken => unavailable
        } else {
          available = false;
        }
        return PhoneAvailabilityResult(
          available: available,
          message: data['message'] as String?,
        );
      }

      final message = data['message'] as String? ?? 'Imeshindwa kuthibitisha nambari';
      return PhoneAvailabilityResult(available: false, message: message);
    } catch (e) {
      return PhoneAvailabilityResult(
        available: false,
        message: 'Imeshindwa kuwasiliana na seva: $e',
      );
    }
  }

  /// Check if a phone number is already registered (convenience wrapper).
  Future<bool> isPhoneRegistered(String phoneNumber) async {
    final result = await checkPhoneAvailability(phoneNumber);
    return !result.available;
  }

  /// Get user profile by phone number
  Future<RegistrationState?> getByPhone(String phoneNumber) async {
    try {
      final response = await http.get(
        Uri.parse('$_baseUrl/users/phone/$phoneNumber'),
      );

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        if (data['success'] == true && data['data'] != null) {
          return _mapServerResponseToRegistrationState(data['data']);
        }
      }
      return null;
    } catch (e) {
      return null;
    }
  }

  /// Update profile by phone (PUT /api/users/phone/{phone}).
  /// [phone] must be E.164 or +255XXXXXXXXX. [payload] is profile fields in snake_case.
  Future<ProfileUpdateResult> updateProfileByPhone(
    String phone,
    Map<String, dynamic> payload,
  ) async {
    try {
      final encodedPhone = Uri.encodeComponent(phone);
      final response = await http.put(
        Uri.parse('$_baseUrl/users/phone/$encodedPhone'),
        headers: {'Content-Type': 'application/json'},
        body: jsonEncode(payload),
      );

      final body = response.body;
      if (body.isEmpty) {
        return ProfileUpdateResult(
          success: false,
          message: 'Hakuna majibu kutoka kwa seva',
        );
      }

      final data = jsonDecode(body) as Map<String, dynamic>;
      final success = response.statusCode == 200 && data['success'] == true;

      if (success) {
        return ProfileUpdateResult(
          success: true,
          message: data['message'] as String?,
          data: data['data'] is Map<String, dynamic>
              ? Map<String, dynamic>.from(data['data'] as Map)
              : null,
        );
      }

      return ProfileUpdateResult(
        success: false,
        message: data['message'] as String? ?? 'Imeshindwa kusasisha wasifu',
        errors: data['errors'] is Map<String, dynamic>
            ? Map<String, dynamic>.from(data['errors'] as Map)
            : null,
      );
    } catch (e) {
      return ProfileUpdateResult(
        success: false,
        message: 'Imeshindwa kuwasiliana na seva: $e',
      );
    }
  }

  /// Delete user account. DELETE /api/account
  Future<bool> deleteAccount(int userId) async {
    try {
      final response = await http.delete(
        Uri.parse('$_baseUrl/account'),
        headers: {'Content-Type': 'application/json'},
        body: jsonEncode({'user_id': userId}),
      );

      final data = jsonDecode(response.body);
      return response.statusCode == 200 && data['success'] == true;
    } catch (e) {
      return false;
    }
  }

  /// Map server response to RegistrationState
  RegistrationState _mapServerResponseToRegistrationState(Map<String, dynamic> data) {
    return RegistrationState(
      firstName: data['first_name'],
      lastName: data['last_name'],
      dateOfBirth: data['date_of_birth'] != null
          ? DateTime.parse(data['date_of_birth'])
          : null,
      gender: data['gender'] != null
          ? Gender.values.firstWhere(
              (g) => g.name == data['gender'],
              orElse: () => Gender.male,
            )
          : null,
      phoneNumber: data['phone_number'],
      isPhoneVerified: data['is_phone_verified'] ?? false,
      location: data['region_id'] != null
          ? LocationSelection(
              regionId: data['region_id'],
              regionName: data['region_name'],
              districtId: data['district_id'],
              districtName: data['district_name'],
              wardId: data['ward_id'],
              wardName: data['ward_name'],
              streetId: data['street_id'],
              streetName: data['street_name'],
            )
          : null,
      primarySchool: data['primary_school_id'] != null
          ? EducationEntry(
              schoolId: data['primary_school_id'],
              schoolCode: data['primary_school_code'],
              schoolName: data['primary_school_name'],
              schoolType: data['primary_school_type'],
              startYear: data['primary_start_year'],
              graduationYear: data['primary_graduation_year'],
            )
          : null,
      secondarySchool: data['secondary_school_id'] != null
          ? EducationEntry(
              schoolId: data['secondary_school_id'],
              schoolCode: data['secondary_school_code'],
              schoolName: data['secondary_school_name'],
              schoolType: data['secondary_school_type'],
              startYear: data['secondary_start_year'],
              graduationYear: data['secondary_graduation_year'],
            )
          : null,
      alevelEducation: data['alevel_school_id'] != null
          ? AlevelEducation(
              schoolId: data['alevel_school_id'],
              schoolCode: data['alevel_school_code'],
              schoolName: data['alevel_school_name'],
              schoolType: data['alevel_school_type'],
              startYear: data['alevel_start_year'],
              graduationYear: data['alevel_graduation_year'],
              combinationCode: data['alevel_combination_code'],
              combinationName: data['alevel_combination_name'],
              subjects: data['alevel_subjects'] != null
                  ? List<String>.from(data['alevel_subjects'])
                  : null,
            )
          : null,
      postsecondaryEducation: data['postsecondary_id'] != null
          ? EducationEntry(
              schoolId: data['postsecondary_id'],
              schoolCode: data['postsecondary_code'],
              schoolName: data['postsecondary_name'],
              schoolType: data['postsecondary_type'],
              startYear: data['postsecondary_start_year'],
              graduationYear: data['postsecondary_graduation_year'],
            )
          : null,
      universityEducation: data['university_id'] != null
          ? UniversityEducation(
              universityId: data['university_id'],
              universityCode: data['university_code'],
              universityName: data['university_name'],
              programmeId: data['programme_id'],
              programmeName: data['programme_name'],
              degreeLevel: data['degree_level'],
              startYear: data['university_start_year'],
              graduationYear: data['university_graduation_year'],
              isCurrentStudent: data['is_current_student'] ?? false,
            )
          : null,
      currentEmployer: data['employer_id'] != null || data['employer_name'] != null
          ? EmployerEntry(
              employerId: data['employer_id'],
              employerCode: data['employer_code'],
              employerName: data['employer_name'],
              sector: data['employer_sector'],
              ownership: data['employer_ownership'],
              isCustomEmployer: data['is_custom_employer'] ?? false,
            )
          : null,
    );
  }
}

class UserRegistrationResult {
  final bool success;
  final int? userId;
  final String? message;
  final Map<String, dynamic>? errors;
  /// Profile data returned by POST /api/users/register (user id and profile data).
  final Map<String, dynamic>? profileData;
  /// Bearer token if backend returns it (e.g. Laravel Sanctum). Persist via LocalStorageService.saveAuthToken.
  final String? accessToken;

  UserRegistrationResult({
    required this.success,
    this.userId,
    this.message,
    this.errors,
    this.profileData,
    this.accessToken,
  });
}

/// Result of POST /api/users/check-phone: available or unavailable status.
class PhoneAvailabilityResult {
  final bool available;
  final String? message;

  const PhoneAvailabilityResult({
    required this.available,
    this.message,
  });
}

/// Result of PUT /api/users/phone/{phone}: profile update success/failure.
class ProfileUpdateResult {
  final bool success;
  final String? message;
  final Map<String, dynamic>? data;
  final Map<String, dynamic>? errors;

  ProfileUpdateResult({
    required this.success,
    this.message,
    this.data,
    this.errors,
  });
}
