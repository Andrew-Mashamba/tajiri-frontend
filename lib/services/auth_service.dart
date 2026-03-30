import 'dart:async';
import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:http/http.dart' as http;
import 'package:uuid/uuid.dart';
import '../config/api_config.dart';
import '../config/certificate_pins.dart';
import '../models/registration_models.dart';
import '../services/local_storage_service.dart';
import '../services/fcm_service.dart';
import '../services/live_update_service.dart';
import '../screens/login/login_screen.dart';

class AuthService {
  static final AuthService instance = AuthService._();
  AuthService._();

  static const _storage = FlutterSecureStorage(
    aOptions: AndroidOptions(encryptedSharedPreferences: true),
  );

  static const _accessTokenKey = 'tajiri_access_token';
  static const _refreshTokenKey = 'tajiri_refresh_token';
  static const _accessExpiryKey = 'tajiri_access_expiry';
  static const _refreshExpiryKey = 'tajiri_refresh_expiry';
  static const _deviceIdKey = 'tajiri_device_id';

  String? _cachedAccessToken;
  DateTime? _cachedAccessExpiry;
  String? _cachedRefreshToken;
  DateTime? _cachedRefreshExpiry;

  String? get cachedAccessToken => _cachedAccessToken;

  Completer<bool>? _refreshLock;

  static const _refreshBuffer = Duration(minutes: 5);

  // --- init ---
  Future<void> init() async {
    _cachedAccessToken = await _storage.read(key: _accessTokenKey);
    _cachedRefreshToken = await _storage.read(key: _refreshTokenKey);
    final accessExpiryStr = await _storage.read(key: _accessExpiryKey);
    if (accessExpiryStr != null) {
      _cachedAccessExpiry = DateTime.tryParse(accessExpiryStr);
    }
    final refreshExpiryStr = await _storage.read(key: _refreshExpiryKey);
    if (refreshExpiryStr != null) {
      _cachedRefreshExpiry = DateTime.tryParse(refreshExpiryStr);
    }
    _fetchPinningConfig();
  }

  // --- device ID ---
  Future<String> getDeviceId() async {
    var deviceId = await _storage.read(key: _deviceIdKey);
    if (deviceId == null || deviceId.isEmpty) {
      deviceId = const Uuid().v4();
      await _storage.write(key: _deviceIdKey, value: deviceId);
    }
    return deviceId;
  }

  Future<void> _fetchPinningConfig() async {
    try {
      final url =
          ApiConfig.baseUrl.replaceFirst('/api', '/api/config/pinning');
      final response = await http
          .get(Uri.parse(url))
          .timeout(const Duration(seconds: 5));
      if (response.statusCode == 200) {
        final data = jsonDecode(response.body) as Map<String, dynamic>;
        CertificatePins.enabled = data['enabled'] == true;
      }
    } catch (_) {}
  }

  // --- isAuthenticated ---
  Future<bool> isAuthenticated() async {
    if (_cachedAccessToken != null && _cachedAccessToken!.isNotEmpty) {
      return true;
    }
    final token = await _storage.read(key: _accessTokenKey);
    return token != null && token.isNotEmpty;
  }

  // --- getValidAccessToken ---
  Future<String?> getValidAccessToken() async {
    if (_cachedAccessToken != null && _cachedAccessExpiry != null) {
      final remaining = _cachedAccessExpiry!.difference(DateTime.now());
      if (remaining > _refreshBuffer) return _cachedAccessToken;
    }
    if (_cachedRefreshToken != null) {
      if (_cachedRefreshExpiry != null &&
          _cachedRefreshExpiry!.isBefore(DateTime.now())) {
        await _clearTokens();
        return null;
      }
      final refreshed = await refreshTokens();
      if (refreshed) return _cachedAccessToken;
      if (_cachedAccessToken != null) return _cachedAccessToken;
    }
    return _cachedAccessToken;
  }

  // --- refreshTokens ---
  Future<bool> refreshTokens() async {
    if (_refreshLock != null) return _refreshLock!.future;
    _refreshLock = Completer<bool>();
    try {
      final refreshToken =
          _cachedRefreshToken ?? await _storage.read(key: _refreshTokenKey);
      if (refreshToken == null || refreshToken.isEmpty) {
        _refreshLock!.complete(false);
        return false;
      }
      final deviceId = await getDeviceId();
      final response = await http
          .post(
            Uri.parse('${ApiConfig.baseUrl}/auth/refresh'),
            headers: {
              'Content-Type': 'application/json',
              'Accept': 'application/json',
              'Authorization': 'Bearer $refreshToken',
            },
            body: jsonEncode({'device_id': deviceId}),
          )
          .timeout(const Duration(seconds: 15));
      if (response.statusCode == 200) {
        final data = jsonDecode(response.body) as Map<String, dynamic>;
        await _storeTokens(
          accessToken: data['access_token'] as String,
          refreshToken: data['refresh_token'] as String,
          accessExpiresIn: data['access_expires_in'] as int,
          refreshExpiresIn: data['refresh_expires_in'] as int,
        );
        _refreshLock!.complete(true);
        return true;
      }
      if (response.statusCode == 401 || response.statusCode == 403) {
        await _clearTokens();
        _refreshLock!.complete(false);
        return false;
      }
      _refreshLock!.complete(false);
      return false;
    } catch (e) {
      debugPrint('AuthService: refresh failed (network): $e');
      _refreshLock!.complete(false);
      return false;
    } finally {
      _refreshLock = null;
    }
  }

  // --- _storeTokens ---
  Future<void> _storeTokens({
    required String accessToken,
    required String refreshToken,
    required int accessExpiresIn,
    required int refreshExpiresIn,
  }) async {
    final accessExpiry =
        DateTime.now().add(Duration(seconds: accessExpiresIn));
    final refreshExpiry =
        DateTime.now().add(Duration(seconds: refreshExpiresIn));
    _cachedAccessToken = accessToken;
    _cachedAccessExpiry = accessExpiry;
    _cachedRefreshToken = refreshToken;
    _cachedRefreshExpiry = refreshExpiry;
    await Future.wait([
      _storage.write(key: _accessTokenKey, value: accessToken),
      _storage.write(key: _refreshTokenKey, value: refreshToken),
      _storage.write(
          key: _accessExpiryKey, value: accessExpiry.toIso8601String()),
      _storage.write(
          key: _refreshExpiryKey, value: refreshExpiry.toIso8601String()),
    ]);
  }

  // --- _clearTokens ---
  Future<void> _clearTokens() async {
    _cachedAccessToken = null;
    _cachedAccessExpiry = null;
    _cachedRefreshToken = null;
    _cachedRefreshExpiry = null;
    await Future.wait([
      _storage.delete(key: _accessTokenKey),
      _storage.delete(key: _refreshTokenKey),
      _storage.delete(key: _accessExpiryKey),
      _storage.delete(key: _refreshExpiryKey),
    ]);
  }

  // --- login ---
  Future<AuthLoginResult> login(String phone, String pin) async {
    try {
      String normalized = phone;
      if (phone.startsWith('0') && phone.length == 10) {
        normalized = '+255${phone.substring(1)}';
      } else if (!phone.startsWith('+')) {
        normalized = '+$phone';
      }
      final deviceId = await getDeviceId();
      final response = await http.post(
        Uri.parse('${ApiConfig.baseUrl}/users/login-by-phone'),
        headers: {
          'Content-Type': 'application/json',
          'Accept': 'application/json',
        },
        body: jsonEncode({
          'phone_number': normalized,
          'pin': pin,
          'device_id': deviceId,
        }),
      );
      final data = jsonDecode(response.body) as Map<String, dynamic>;
      if (response.statusCode == 200 && data['success'] == true) {
        final accessToken = data['access_token'] as String?;
        final refreshToken = data['refresh_token'] as String?;
        final accessExpiresIn = data['access_expires_in'] as int? ?? 86400;
        final refreshExpiresIn =
            data['refresh_expires_in'] as int? ?? 7776000;
        if (accessToken != null && refreshToken != null) {
          await _storeTokens(
            accessToken: accessToken,
            refreshToken: refreshToken,
            accessExpiresIn: accessExpiresIn,
            refreshExpiresIn: refreshExpiresIn,
          );
        } else if (accessToken != null) {
          _cachedAccessToken = accessToken;
          await _storage.write(key: _accessTokenKey, value: accessToken);
        }
        final userData = data['user'] as Map<String, dynamic>?;
        RegistrationState? user;
        if (userData != null) {
          user = _mapServerResponseToRegistrationState(userData);
          final storage = await LocalStorageService.getInstance();
          await storage.saveUser(user);
        }
        final userId = user?.userId ?? (userData?['id'] as int?);
        // Register FCM token
        if (userId != null) {
          try {
            FcmService.instance.sendTokenToBackend(userId);
          } catch (_) {}
        }
        return AuthLoginResult(
            success: true, user: user, userId: userId);
      }
      return AuthLoginResult(
        success: false,
        error: data['message'] as String? ?? 'Imeshindwa kuingia',
      );
    } catch (e) {
      return AuthLoginResult(
        success: false,
        error: 'Imeshindwa kuwasiliana na seva: $e',
      );
    }
  }

  /// Map server user JSON to RegistrationState.
  /// Replicates the logic from UserService._mapServerResponseToRegistrationState.
  RegistrationState _mapServerResponseToRegistrationState(
      Map<String, dynamic> data) {
    final rawId = data['id'];
    final userId = rawId is int ? rawId : (rawId is num ? rawId.toInt() : null);
    final state = RegistrationState(
      userId: userId,
      profilePhotoUrl: data['profile_photo_url'] as String?,
      firstName: data['first_name'] as String?,
      lastName: data['last_name'] as String?,
      dateOfBirth: data['date_of_birth'] != null
          ? DateTime.tryParse(data['date_of_birth'].toString())
          : null,
      gender: data['gender'] != null
          ? Gender.values.firstWhere(
              (g) => g.name == data['gender'],
              orElse: () => Gender.male,
            )
          : null,
      phoneNumber: data['phone_number'] as String?,
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
      currentEmployer:
          data['employer_id'] != null || data['employer_name'] != null
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
    return state;
  }

  // --- saveSession ---
  Future<void> saveSession({
    required String accessToken,
    String? refreshToken,
    int accessExpiresIn = 86400,
    int refreshExpiresIn = 7776000,
    required RegistrationState user,
  }) async {
    if (refreshToken != null) {
      await _storeTokens(
        accessToken: accessToken,
        refreshToken: refreshToken,
        accessExpiresIn: accessExpiresIn,
        refreshExpiresIn: refreshExpiresIn,
      );
    } else {
      _cachedAccessToken = accessToken;
      await _storage.write(key: _accessTokenKey, value: accessToken);
    }
    final storage = await LocalStorageService.getInstance();
    await storage.saveUser(user);
    final userId = user.userId;
    if (userId != null) {
      try {
        FcmService.instance.sendTokenToBackend(userId);
      } catch (_) {}
    }
  }

  // --- logout ---
  Future<void> logout(BuildContext context) async {
    try {
      final token =
          _cachedAccessToken ?? await _storage.read(key: _accessTokenKey);
      final deviceId = await getDeviceId();
      if (token != null) {
        http
            .post(
              Uri.parse('${ApiConfig.baseUrl}/auth/logout'),
              headers: {
                'Content-Type': 'application/json',
                'Accept': 'application/json',
                'Authorization': 'Bearer $token',
              },
              body: jsonEncode({'device_id': deviceId}),
            )
            .catchError((_) => http.Response('', 500));
      }
    } catch (_) {}
    if (!context.mounted) return;
    await _performLocalLogout(context);
  }

  // --- logoutAllDevices ---
  Future<void> logoutAllDevices(BuildContext context) async {
    try {
      final token =
          _cachedAccessToken ?? await _storage.read(key: _accessTokenKey);
      if (token != null) {
        await http
            .post(
              Uri.parse('${ApiConfig.baseUrl}/auth/logout-all'),
              headers: {
                'Content-Type': 'application/json',
                'Accept': 'application/json',
                'Authorization': 'Bearer $token',
              },
            )
            .timeout(const Duration(seconds: 10));
      }
    } catch (_) {}
    if (!context.mounted) return;
    await _performLocalLogout(context);
  }

  // --- _performLocalLogout ---
  Future<void> _performLocalLogout(BuildContext context) async {
    try {
      LiveUpdateService.instance.stop();
    } catch (_) {}
    await _clearTokens();
    try {
      final storage = await LocalStorageService.getInstance();
      await storage.clearUser();
    } catch (_) {}
    if (context.mounted) {
      Navigator.of(context).pushAndRemoveUntil(
        MaterialPageRoute(builder: (_) => const LoginScreen()),
        (route) => false,
      );
    }
  }

  // --- migrateFromHive ---
  Future<MigrationResult> migrateFromHive() async {
    final existing = await _storage.read(key: _accessTokenKey);
    if (existing != null && existing.isNotEmpty) {
      return MigrationResult.alreadyMigrated;
    }
    try {
      final hiveStorage = await LocalStorageService.getInstance();
      final legacyToken = hiveStorage.getAuthToken();
      if (legacyToken == null || legacyToken.isEmpty) {
        return MigrationResult.noLegacyToken;
      }
      await _storage.write(key: _accessTokenKey, value: legacyToken);
      _cachedAccessToken = legacyToken;
      await hiveStorage.saveAuthToken(null);
      final deviceId = await getDeviceId();
      try {
        final response = await http
            .post(
              Uri.parse('${ApiConfig.baseUrl}/auth/exchange'),
              headers: {
                'Content-Type': 'application/json',
                'Accept': 'application/json',
                'Authorization': 'Bearer $legacyToken',
              },
              body: jsonEncode({'device_id': deviceId}),
            )
            .timeout(const Duration(seconds: 15));
        if (response.statusCode == 200) {
          final data = jsonDecode(response.body) as Map<String, dynamic>;
          await _storeTokens(
            accessToken: data['access_token'] as String,
            refreshToken: data['refresh_token'] as String,
            accessExpiresIn: data['access_expires_in'] as int,
            refreshExpiresIn: data['refresh_expires_in'] as int,
          );
          return MigrationResult.success;
        }
        await _clearTokens();
        return MigrationResult.tokenExpired;
      } catch (e) {
        debugPrint('AuthService: migration exchange failed (network): $e');
        return MigrationResult.networkError;
      }
    } catch (e) {
      debugPrint('AuthService: migration failed: $e');
      return MigrationResult.error;
    }
  }
}

enum MigrationResult {
  alreadyMigrated,
  noLegacyToken,
  success,
  tokenExpired,
  networkError,
  error,
}

class AuthLoginResult {
  final bool success;
  final String? error;
  final RegistrationState? user;
  final int? userId;
  const AuthLoginResult({
    required this.success,
    this.error,
    this.user,
    this.userId,
  });
}
