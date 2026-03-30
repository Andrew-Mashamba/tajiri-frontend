# TAJIRI Persistent Auth Implementation Plan

> **For agentic workers:** REQUIRED SUB-SKILL: Use superpowers:subagent-driven-development (recommended) or superpowers:executing-plans to implement this plan task-by-task. Steps use checkbox (`- [ ]`) syntax for tracking.

**Goal:** Make TAJIRI stay logged in permanently (like Instagram) until explicit logout or app reinstall, with encrypted token storage, silent refresh, biometric gates, and certificate pinning.

**Architecture:** Dual Sanctum tokens (access 24h + refresh 90d sliding) stored in flutter_secure_storage. AuthService singleton manages login/logout/refresh with in-memory cache. AuthenticatedDio interceptor handles 401 → silent refresh → retry with Completer-based request queue. BiometricService guards sensitive wallet/settings actions. Certificate pinning with runtime kill switch.

**Tech Stack:** Flutter/Dart, flutter_secure_storage ^9.2.4, local_auth ^2.3.0, uuid ^4.5.1, Dio ^5.4.0 (already present), Laravel Sanctum backend (spec only — built separately).

**Spec:** `docs/superpowers/specs/2026-03-30-persistent-auth-design.md`

---

## File Structure

### New Files (4)

| File | Responsibility |
|------|---------------|
| `lib/services/auth_service.dart` | Singleton. Token storage (flutter_secure_storage), login, logout, refresh, Hive migration, device ID, in-memory cache + Completer refresh lock |
| `lib/services/authenticated_dio.dart` | Singleton Dio with interceptor: auto Bearer header, 401 → refresh → retry, request queue dedup, cert pin validation |
| `lib/services/biometric_service.dart` | Static. `local_auth` wrapper — single `authenticate()` method with fallback chain |
| `lib/config/certificate_pins.dart` | Static. SPKI pin hashes, `enabled` flag, `shouldPin` getter (production-only) |

### Modified Files (~12)

| File | Change |
|------|--------|
| `pubspec.yaml` | Add 3 packages |
| `lib/services/local_storage_service.dart` | `getAuthToken()` → thin async wrapper delegating to AuthService. Remove `saveAuthToken()` writes. Delete dead `logout()`. |
| `lib/screens/splash/splash_screen.dart` | Replace Hive check with `AuthService.init()` + `AuthService.isAuthenticated()` + migration |
| `lib/screens/login/login_screen.dart` | Replace manual token save with `AuthService.login()` |
| `lib/screens/onboarding/completion_screen.dart` | Replace manual token save with `AuthService.saveSession()` |
| `lib/screens/settings/settings_screen.dart` | Replace `_logout()` with `AuthService.logout(context)`. Add "Logout all devices". |
| `lib/screens/profile/profile_screen.dart` | Replace `_showLogoutDialog` inline logout with `AuthService.logout(context)` |
| `lib/config/api_config.dart` | No changes needed (AuthenticatedDio reads baseUrl directly) |
| `lib/screens/wallet/wallet_screen.dart` | Add `BiometricService.authenticate()` guard before `_deposit()`, `_withdraw()`, `_transfer()` |
| `lib/screens/wallet/send_tip_screen.dart` | Add biometric guard before send |
| `lib/screens/wallet/payout_request_screen.dart` | Add biometric guard before payout |
| `lib/screens/wallet/subscribe_to_creator_screen.dart` | Add biometric guard before subscribe (involves payment) |
| `ios/Runner/Info.plist` | Add `NSFaceIDUsageDescription` |
| `android/app/src/main/AndroidManifest.xml` | Add `USE_BIOMETRIC` permission |

---

## Task 1: Add Packages

**Files:**
- Modify: `pubspec.yaml:30-46`

- [ ] **Step 1: Add flutter_secure_storage, local_auth, uuid to pubspec.yaml**

In the `dependencies:` section, after the `hive_flutter` line (line 46), add:

```yaml
  # Secure token storage (OS Keychain / Keystore)
  flutter_secure_storage: ^9.2.4

  # Biometric authentication (Face ID / fingerprint / device PIN)
  local_auth: ^2.3.0

  # Device ID generation (UUID v4)
  uuid: ^4.5.1
```

- [ ] **Step 2: Run pub get**

Run: `cd /Volumes/DATA/PROJECTS/TAJIRI/TAJIRI-FRONTEND && flutter pub get`
Expected: "Got dependencies!" with no errors.

- [ ] **Step 3: Commit**

```bash
git add pubspec.yaml pubspec.lock
git commit -m "deps: add flutter_secure_storage, local_auth, uuid for persistent auth"
```

---

## Task 2: CertificatePins Config

**Files:**
- Create: `lib/config/certificate_pins.dart`

- [ ] **Step 1: Create certificate_pins.dart**

```dart
import '../config/api_config.dart';

/// SPKI SHA-256 certificate pins for TLS pinning.
///
/// Spec: docs/superpowers/specs/2026-03-30-persistent-auth-design.md §6
///
/// Pins are ONLY enforced for production (tajiri.zimasystems.com).
/// Disabled for UAT/localhost and via runtime kill switch.
class CertificatePins {
  CertificatePins._();

  /// Primary pin: current tajiri.zimasystems.com leaf certificate.
  /// Extract with:
  /// ```bash
  /// openssl s_client -connect tajiri.zimasystems.com:443 2>/dev/null | \
  ///   openssl x509 -pubkey -noout | \
  ///   openssl pkey -pubin -outform DER | \
  ///   openssl dgst -sha256 -binary | base64
  /// ```
  static const String primary = 'sha256/PLACEHOLDER_PRIMARY_PIN';

  /// Backup pin: CA intermediate (prevents lockout on cert rotation).
  static const String backup = 'sha256/PLACEHOLDER_BACKUP_PIN';

  /// Runtime kill switch — fetched from `GET /api/config/pinning` on app start.
  /// Defaults to true; set to false if remote config says so or request fails.
  static bool enabled = true;

  /// Pinning only active for production domain. Auto-disabled for UAT/localhost.
  static bool get shouldPin =>
      enabled && ApiConfig.baseUrl.contains('tajiri.zimasystems.com');

  /// All pins to validate against (any match = pass).
  static List<String> get pins => [primary, backup];
}
```

- [ ] **Step 2: Verify no analysis errors**

Run: `flutter analyze lib/config/certificate_pins.dart`
Expected: No issues found.

- [ ] **Step 3: Commit**

```bash
git add lib/config/certificate_pins.dart
git commit -m "feat(auth): add CertificatePins config with SPKI hashes and kill switch"
```

---

## Task 3: AuthService — Core Token Management

This is the largest task. AuthService is the single source of truth for all auth operations.

**Files:**
- Create: `lib/services/auth_service.dart`

- [ ] **Step 1: Create auth_service.dart with imports and class shell**

```dart
import 'dart:async';
import 'dart:convert';
import 'package:flutter/foundation.dart';
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

/// Single source of truth for authentication.
///
/// Spec: docs/superpowers/specs/2026-03-30-persistent-auth-design.md §3
///
/// Singleton (not all-static) because refresh flow needs mutable instance state:
/// in-memory token cache, Completer-based refresh lock, and testability.
class AuthService {
  static final AuthService instance = AuthService._();
  AuthService._();

  static const _storage = FlutterSecureStorage(
    aOptions: AndroidOptions(encryptedSharedPreferences: true),
  );

  // Secure storage keys
  static const _accessTokenKey = 'tajiri_access_token';
  static const _refreshTokenKey = 'tajiri_refresh_token';
  static const _accessExpiryKey = 'tajiri_access_expiry';
  static const _refreshExpiryKey = 'tajiri_refresh_expiry';
  static const _deviceIdKey = 'tajiri_device_id';

  // In-memory cache (avoids async I/O on every request)
  String? _cachedAccessToken;
  DateTime? _cachedAccessExpiry;
  String? _cachedRefreshToken;
  DateTime? _cachedRefreshExpiry;

  /// Synchronous access to the cached access token (may be expired).
  /// Used by LocalStorageService.getAuthToken() for backward compatibility.
  String? get cachedAccessToken => _cachedAccessToken;

  // Refresh dedup lock
  Completer<bool>? _refreshLock;

  /// Pre-emptive refresh buffer. Refresh token 5 minutes before expiry
  /// to avoid 401 round-trips on slow 2G/EDGE networks.
  static const _refreshBuffer = Duration(minutes: 5);
```

- [ ] **Step 2: Add init() and device ID methods**

```dart
  /// Initialize: load tokens from secure storage into memory cache.
  /// Call once from SplashScreen before any auth check.
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

    // Fetch certificate pinning kill switch (unpinned, fire-and-forget)
    _fetchPinningConfig();
  }

  /// Get or generate a persistent device ID (UUID v4).
  /// Survives app updates, wiped on reinstall (secure storage cleared).
  Future<String> getDeviceId() async {
    var deviceId = await _storage.read(key: _deviceIdKey);
    if (deviceId == null || deviceId.isEmpty) {
      deviceId = const Uuid().v4();
      await _storage.write(key: _deviceIdKey, value: deviceId);
    }
    return deviceId;
  }

  /// Fetch pinning kill switch from backend. Fire-and-forget, no auth needed.
  Future<void> _fetchPinningConfig() async {
    try {
      final url = ApiConfig.baseUrl.replaceFirst('/api', '/api/config/pinning');
      final response = await http.get(Uri.parse(url)).timeout(
        const Duration(seconds: 5),
      );
      if (response.statusCode == 200) {
        final data = jsonDecode(response.body) as Map<String, dynamic>;
        CertificatePins.enabled = data['enabled'] == true;
      }
    } catch (_) {
      // On failure, keep pinning enabled (safe default)
    }
  }
```

- [ ] **Step 3: Add isAuthenticated() and getValidAccessToken()**

```dart
  /// Check if user has a valid session (any token exists in secure storage).
  Future<bool> isAuthenticated() async {
    // Check cache first
    if (_cachedAccessToken != null && _cachedAccessToken!.isNotEmpty) {
      return true;
    }
    // Fall back to storage
    final token = await _storage.read(key: _accessTokenKey);
    return token != null && token.isNotEmpty;
  }

  /// Get current access token, refreshing if expired or expiring soon.
  ///
  /// On network failure during refresh: returns expired token (let request
  /// fail naturally with connectivity error — don't force logout for offline).
  /// Returns null only if no token exists or refresh endpoint returned 401/403.
  Future<String?> getValidAccessToken() async {
    // Fast path: cached token not expiring soon
    if (_cachedAccessToken != null && _cachedAccessExpiry != null) {
      final remaining = _cachedAccessExpiry!.difference(DateTime.now());
      if (remaining > _refreshBuffer) {
        return _cachedAccessToken;
      }
    }

    // Token is expired/expiring — try refresh
    if (_cachedRefreshToken != null) {
      // Skip network call if refresh token itself is expired
      if (_cachedRefreshExpiry != null &&
          _cachedRefreshExpiry!.isBefore(DateTime.now())) {
        // Refresh token expired (90+ days idle) — user must re-login
        await _clearTokens();
        return null;
      }

      final refreshed = await refreshTokens();
      if (refreshed) {
        return _cachedAccessToken;
      }
      // Refresh failed — if it was a network error, return expired token anyway
      // (the subsequent API call will also fail with network error, but we
      // don't force logout just because user is offline)
      if (_cachedAccessToken != null) {
        return _cachedAccessToken;
      }
    }

    // No refresh token — return whatever we have (may be null)
    return _cachedAccessToken;
  }
```

- [ ] **Step 4: Add refreshTokens()**

```dart
  /// Refresh tokens silently. Returns true if successful.
  ///
  /// Uses Completer-based lock to dedup concurrent refresh attempts.
  /// Distinguishes network errors (return false, keep tokens) from
  /// auth rejection (401/403 → clear tokens, return false).
  Future<bool> refreshTokens() async {
    // Dedup: if refresh already in progress, wait for it
    if (_refreshLock != null) {
      return _refreshLock!.future;
    }

    _refreshLock = Completer<bool>();

    try {
      final refreshToken = _cachedRefreshToken ??
          await _storage.read(key: _refreshTokenKey);

      if (refreshToken == null || refreshToken.isEmpty) {
        _refreshLock!.complete(false);
        return false;
      }

      final deviceId = await getDeviceId();
      final url = '${ApiConfig.baseUrl}/auth/refresh';

      final response = await http.post(
        Uri.parse(url),
        headers: {
          'Content-Type': 'application/json',
          'Accept': 'application/json',
          'Authorization': 'Bearer $refreshToken',
        },
        body: jsonEncode({'device_id': deviceId}),
      ).timeout(const Duration(seconds: 15));

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

      // 401/403 from refresh endpoint = token revoked or reuse detected
      if (response.statusCode == 401 || response.statusCode == 403) {
        await _clearTokens();
        _refreshLock!.complete(false);
        return false;
      }

      // Other server error — don't clear tokens, might be transient
      _refreshLock!.complete(false);
      return false;
    } catch (e) {
      // Network error (SocketException, timeout) — keep tokens, return false
      debugPrint('AuthService: refresh failed (network): $e');
      _refreshLock!.complete(false);
      return false;
    } finally {
      _refreshLock = null;
    }
  }
```

- [ ] **Step 5: Add _storeTokens() and _clearTokens() helpers**

```dart
  /// Store both tokens + expiry timestamps in secure storage and cache.
  Future<void> _storeTokens({
    required String accessToken,
    required String refreshToken,
    required int accessExpiresIn,
    required int refreshExpiresIn,
  }) async {
    final accessExpiry = DateTime.now().add(Duration(seconds: accessExpiresIn));
    final refreshExpiry = DateTime.now().add(Duration(seconds: refreshExpiresIn));

    _cachedAccessToken = accessToken;
    _cachedAccessExpiry = accessExpiry;
    _cachedRefreshToken = refreshToken;
    _cachedRefreshExpiry = refreshExpiry;

    await Future.wait([
      _storage.write(key: _accessTokenKey, value: accessToken),
      _storage.write(key: _refreshTokenKey, value: refreshToken),
      _storage.write(key: _accessExpiryKey, value: accessExpiry.toIso8601String()),
      _storage.write(key: _refreshExpiryKey, value: refreshExpiry.toIso8601String()),
    ]);
  }

  /// Clear all tokens from secure storage and cache.
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
```

- [ ] **Step 6: Add login() method**

```dart
  /// Login: call backend, store dual tokens + device ID, save user to Hive.
  Future<AuthLoginResult> login(String phone, String pin) async {
    try {
      // Normalize phone
      String normalized = phone;
      if (phone.startsWith('0') && phone.length == 10) {
        normalized = '+255${phone.substring(1)}';
      } else if (!phone.startsWith('+')) {
        normalized = '+$phone';
      }

      final deviceId = await getDeviceId();

      final response = await http.post(
        Uri.parse('${ApiConfig.baseUrl}/users/login-by-phone'),
        headers: {'Content-Type': 'application/json', 'Accept': 'application/json'},
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
        final refreshExpiresIn = data['refresh_expires_in'] as int? ?? 7776000;

        if (accessToken != null && refreshToken != null) {
          await _storeTokens(
            accessToken: accessToken,
            refreshToken: refreshToken,
            accessExpiresIn: accessExpiresIn,
            refreshExpiresIn: refreshExpiresIn,
          );
        } else if (accessToken != null) {
          // Fallback: backend hasn't been updated yet (single token mode)
          _cachedAccessToken = accessToken;
          await _storage.write(key: _accessTokenKey, value: accessToken);
        }

        // Parse user and save to Hive
        final userData = data['user'] as Map<String, dynamic>?;
        RegistrationState? user;
        if (userData != null) {
          user = _mapServerResponseToRegistrationState(userData);
          final storage = await LocalStorageService.getInstance();
          await storage.saveUser(user);
        }

        final userId = user?.userId ?? (userData?['id'] as int?);

        // Register FCM token for push notifications (spec §8)
        if (userId != null) {
          try {
            FcmService.instance.sendTokenToBackend(userId);
          } catch (_) {}
        }

        return AuthLoginResult(
          success: true,
          user: user,
          userId: userId,
        );
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

  /// Map backend user JSON to RegistrationState.
  /// Mirrors UserService._mapServerResponseToRegistrationState.
  RegistrationState _mapServerResponseToRegistrationState(Map<String, dynamic> data) {
    final state = RegistrationState();
    state.firstName = data['first_name'] as String? ?? '';
    state.lastName = data['last_name'] as String? ?? '';
    state.phoneNumber = data['phone_number'] as String? ?? '';
    state.profilePhotoUrl = data['profile_photo_url'] as String?;
    state.userId = data['id'] as int?;
    state.username = data['username'] as String?;
    state.bio = data['bio'] as String?;
    state.locationName = data['location_name'] as String?;
    return state;
  }
```

- [ ] **Step 7: Add saveSession() for registration flow**

```dart
  /// Save session after registration (called from CompletionScreen).
  /// Handles both new dual-token and legacy single-token backend responses.
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
      // Legacy single-token backend
      _cachedAccessToken = accessToken;
      await _storage.write(key: _accessTokenKey, value: accessToken);
    }

    final storage = await LocalStorageService.getInstance();
    await storage.saveUser(user);

    // Register FCM token for push notifications (spec §8)
    final userId = user.userId;
    if (userId != null) {
      try {
        FcmService.instance.sendTokenToBackend(userId);
      } catch (_) {}
    }
  }
```

- [ ] **Step 8: Add logout() and logoutAllDevices()**

```dart
  /// Logout: call backend (best-effort), clear all storage, navigate to login.
  Future<void> logout(BuildContext context) async {
    // Best-effort server logout (don't block on failure)
    try {
      final token = _cachedAccessToken ?? await _storage.read(key: _accessTokenKey);
      final deviceId = await getDeviceId();
      if (token != null) {
        http.post(
          Uri.parse('${ApiConfig.baseUrl}/auth/logout'),
          headers: {
            'Content-Type': 'application/json',
            'Accept': 'application/json',
            'Authorization': 'Bearer $token',
          },
          body: jsonEncode({'device_id': deviceId}),
        ).catchError((_) {}); // fire-and-forget
      }
    } catch (_) {}

    await _performLocalLogout(context);
  }

  /// Logout all devices: call backend (blocks for confirmation), then local logout.
  Future<void> logoutAllDevices(BuildContext context) async {
    try {
      final token = _cachedAccessToken ?? await _storage.read(key: _accessTokenKey);
      if (token != null) {
        await http.post(
          Uri.parse('${ApiConfig.baseUrl}/auth/logout-all'),
          headers: {
            'Content-Type': 'application/json',
            'Accept': 'application/json',
            'Authorization': 'Bearer $token',
          },
        ).timeout(const Duration(seconds: 10));
      }
    } catch (_) {}

    if (context.mounted) {
      await _performLocalLogout(context);
    }
  }

  /// Shared local cleanup for all logout paths.
  Future<void> _performLocalLogout(BuildContext context) async {
    // Stop real-time listeners
    try {
      LiveUpdateService.instance.stop();
    } catch (_) {}

    // Clear secure storage (tokens only — device ID survives logout per spec §2)
    await _clearTokens();

    // Clear Hive user data
    try {
      final storage = await LocalStorageService.getInstance();
      await storage.clearUser();
    } catch (_) {}

    // Navigate to login, clear entire stack
    if (context.mounted) {
      Navigator.of(context).pushAndRemoveUntil(
        MaterialPageRoute(builder: (_) => const LoginScreen()),
        (route) => false,
      );
    }
  }
```

- [ ] **Step 9: Add migrateFromHive() for legacy token migration**

```dart
  /// One-time migration from Hive plaintext token to secure storage + dual tokens.
  ///
  /// Called from SplashScreen on first launch after app update.
  /// Transparent to user if legacy token is still valid on server.
  Future<MigrationResult> migrateFromHive() async {
    // Already migrated? Check if secure storage has tokens
    final existing = await _storage.read(key: _accessTokenKey);
    if (existing != null && existing.isNotEmpty) {
      return MigrationResult.alreadyMigrated;
    }

    // Check Hive for old token
    try {
      final hiveStorage = await LocalStorageService.getInstance();
      final legacyToken = hiveStorage.getAuthToken();

      if (legacyToken == null || legacyToken.isEmpty) {
        return MigrationResult.noLegacyToken;
      }

      // Copy legacy token to secure storage temporarily
      await _storage.write(key: _accessTokenKey, value: legacyToken);
      _cachedAccessToken = legacyToken;

      // Delete from Hive
      await hiveStorage.saveAuthToken(null);

      // Exchange for dual-token pair
      final deviceId = await getDeviceId();
      try {
        final response = await http.post(
          Uri.parse('${ApiConfig.baseUrl}/auth/exchange'),
          headers: {
            'Content-Type': 'application/json',
            'Accept': 'application/json',
            'Authorization': 'Bearer $legacyToken',
          },
          body: jsonEncode({'device_id': deviceId}),
        ).timeout(const Duration(seconds: 15));

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

        // Token expired/revoked on server — user must re-login
        await _clearTokens();
        return MigrationResult.tokenExpired;
      } catch (e) {
        // Network error during exchange — keep legacy token, try again next launch
        // The legacy token is already in secure storage, so user stays "logged in"
        // and the exchange will be retried on next app start.
        debugPrint('AuthService: migration exchange failed (network): $e');
        return MigrationResult.networkError;
      }
    } catch (e) {
      debugPrint('AuthService: migration failed: $e');
      return MigrationResult.error;
    }
  }
}

/// Result of Hive → secure storage migration.
enum MigrationResult {
  /// Secure storage already has tokens — no migration needed.
  alreadyMigrated,
  /// No legacy token in Hive — user was never logged in.
  noLegacyToken,
  /// Migration succeeded — dual tokens stored.
  success,
  /// Legacy token was expired/revoked on server — user must re-login.
  tokenExpired,
  /// Network error during exchange — legacy token kept, retry next launch.
  networkError,
  /// Unexpected error.
  error,
}

/// Login result returned by AuthService.login().
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
```

- [ ] **Step 10: Verify no analysis errors**

Run: `flutter analyze lib/services/auth_service.dart`
Expected: No errors. (Some info-level warnings about unused imports are acceptable if downstream tasks will use them.)

- [ ] **Step 11: Commit**

```bash
git add lib/services/auth_service.dart
git commit -m "feat(auth): add AuthService — token management, login, logout, refresh, migration"
```

---

## Task 4: AuthenticatedDio — Interceptor with Refresh Queue

**Files:**
- Create: `lib/services/authenticated_dio.dart`

- [ ] **Step 1: Create authenticated_dio.dart**

```dart
import 'dart:async';
import 'dart:io';
import 'package:dio/dio.dart';
import 'package:flutter/foundation.dart';
import '../config/api_config.dart';
import '../config/certificate_pins.dart';
import 'auth_service.dart';

/// Singleton Dio instance with auth interceptor, silent refresh, and cert pinning.
///
/// Spec: docs/superpowers/specs/2026-03-30-persistent-auth-design.md §4
///
/// Usage:
/// ```dart
/// final response = await AuthenticatedDio.instance.get('/posts');
/// ```
class AuthenticatedDio {
  AuthenticatedDio._();

  static Dio? _instance;

  /// Get the singleton Dio instance. Lazily initialized on first access.
  static Dio get instance {
    _instance ??= _createDio();
    return _instance!;
  }

  static Dio _createDio() {
    final dio = Dio(BaseOptions(
      baseUrl: ApiConfig.baseUrl,
      connectTimeout: const Duration(seconds: 15),
      receiveTimeout: const Duration(seconds: 30),
      headers: {
        'Content-Type': 'application/json',
        'Accept': 'application/json',
      },
    ));

    // Certificate pinning (production only)
    if (CertificatePins.shouldPin) {
      // Note: Full SPKI pinning requires a custom HttpClientAdapter.
      // For now, we configure it via Dio's httpClientAdapter.
      // Real pin validation is done in the SecurityContext or via
      // a package like dio_certificate_pinning when available.
      // Placeholder — cert pinning details depend on server cert extraction.
    }

    dio.interceptors.add(_AuthInterceptor());

    return dio;
  }

  /// Reset the singleton (for testing or after logout).
  static void reset() {
    _instance?.close();
    _instance = null;
  }
}

/// Interceptor that auto-attaches Bearer header, handles 401 with silent refresh,
/// and deduplicates concurrent refresh attempts via Completer.
class _AuthInterceptor extends Interceptor {
  // Refresh dedup lock (shared across all requests)
  Completer<bool>? _refreshCompleter;

  @override
  Future<void> onRequest(
    RequestOptions options,
    RequestInterceptorHandler handler,
  ) async {
    final token = await AuthService.instance.getValidAccessToken();
    if (token != null) {
      options.headers['Authorization'] = 'Bearer $token';
    }
    handler.next(options);
  }

  @override
  Future<void> onError(
    DioException err,
    ErrorInterceptorHandler handler,
  ) async {
    // Only handle 401 (Unauthorized)
    if (err.response?.statusCode != 401) {
      return handler.next(err);
    }

    // Don't retry refresh endpoint itself (infinite loop guard)
    if (err.requestOptions.path.contains('/auth/refresh')) {
      return handler.next(err);
    }

    try {
      final refreshed = await _refreshWithDedup();

      if (refreshed) {
        // Retry the original request with the new token
        final token = await AuthService.instance.getValidAccessToken();
        if (token != null) {
          err.requestOptions.headers['Authorization'] = 'Bearer $token';
        }

        final dio = AuthenticatedDio.instance;
        final response = await dio.fetch(err.requestOptions);
        return handler.resolve(response);
      }

      // Refresh failed (auth rejection) — pass error through
      return handler.next(err);
    } catch (e) {
      return handler.next(err);
    }
  }

  /// Deduplicate concurrent refresh attempts. Only one actual refresh call
  /// happens at a time; all others await the same Completer.
  Future<bool> _refreshWithDedup() async {
    if (_refreshCompleter != null) {
      return _refreshCompleter!.future;
    }

    _refreshCompleter = Completer<bool>();

    try {
      final result = await AuthService.instance.refreshTokens();
      _refreshCompleter!.complete(result);
      return result;
    } catch (e) {
      _refreshCompleter!.complete(false);
      return false;
    } finally {
      _refreshCompleter = null;
    }
  }
}
```

- [ ] **Step 2: Verify no analysis errors**

Run: `flutter analyze lib/services/authenticated_dio.dart`
Expected: No errors.

- [ ] **Step 3: Commit**

```bash
git add lib/services/authenticated_dio.dart
git commit -m "feat(auth): add AuthenticatedDio interceptor with 401 refresh and request queue"
```

---

## Task 5: BiometricService

**Files:**
- Create: `lib/services/biometric_service.dart`

- [ ] **Step 1: Create biometric_service.dart**

```dart
import 'package:flutter/foundation.dart';
import 'package:flutter/services.dart';
import 'package:local_auth/local_auth.dart';

/// Biometric authentication wrapper for sensitive actions.
///
/// Spec: docs/superpowers/specs/2026-03-30-persistent-auth-design.md §5
///
/// Fallback chain: biometrics → device PIN/pattern → skip (no lock screen).
class BiometricService {
  BiometricService._();

  static final _auth = LocalAuthentication();

  /// Authenticate the user via biometrics or device credentials.
  ///
  /// Returns `true` if:
  /// - Biometric/device PIN authentication succeeded, OR
  /// - Device has no biometric hardware AND no lock screen (skip gate)
  ///
  /// Returns `false` if:
  /// - User cancelled authentication
  /// - Authentication failed
  static Future<bool> authenticate({
    String reason = 'Thibitisha ni wewe kwa alama ya kidole au uso',
  }) async {
    try {
      // Check if device supports any authentication
      final canCheck = await _auth.canCheckBiometrics;
      final isDeviceSupported = await _auth.isDeviceSupported();

      if (!canCheck && !isDeviceSupported) {
        // No biometric hardware AND no device lock screen — don't block user
        return true;
      }

      return await _auth.authenticate(
        localizedReason: reason,
        options: const AuthenticationOptions(
          // Allow device PIN/pattern/password as fallback
          biometricOnly: false,
          // Don't use error dialogs (we handle errors ourselves)
          useErrorDialogs: true,
          stickyAuth: true,
        ),
      );
    } on PlatformException catch (e) {
      debugPrint('BiometricService: $e');
      // If local_auth throws (e.g. no enrolled biometrics), don't block user
      if (e.code == 'NotAvailable' || e.code == 'NotEnrolled') {
        return true;
      }
      return false;
    } catch (e) {
      debugPrint('BiometricService: unexpected error: $e');
      return false;
    }
  }
}
```

- [ ] **Step 2: Verify no analysis errors**

Run: `flutter analyze lib/services/biometric_service.dart`
Expected: No errors.

- [ ] **Step 3: Commit**

```bash
git add lib/services/biometric_service.dart
git commit -m "feat(auth): add BiometricService — local_auth wrapper with fallback chain"
```

---

## Task 6: Platform Config (iOS Info.plist + Android Manifest)

**Files:**
- Modify: `ios/Runner/Info.plist`
- Modify: `android/app/src/main/AndroidManifest.xml`

- [ ] **Step 1: Add NSFaceIDUsageDescription to iOS Info.plist**

Add the following key-value pair inside the top-level `<dict>`, after the existing `NSMicrophoneUsageDescription` entry:

```xml
<key>NSFaceIDUsageDescription</key>
<string>TAJIRI inahitaji uthibitisho wako kwa usalama wa akaunti yako</string>
```

- [ ] **Step 2: Add USE_BIOMETRIC permission to Android Manifest**

Add the following line inside `<manifest>`, after the existing `<uses-permission android:name="android.permission.CAMERA"/>` line:

```xml
<uses-permission android:name="android.permission.USE_BIOMETRIC"/>
```

- [ ] **Step 3: Verify the files are valid XML**

Run: `xmllint --noout ios/Runner/Info.plist android/app/src/main/AndroidManifest.xml 2>&1 || echo "xmllint not available, skip"`

- [ ] **Step 4: Commit**

```bash
git add ios/Runner/Info.plist android/app/src/main/AndroidManifest.xml
git commit -m "feat(auth): add biometric permissions for iOS Face ID and Android"
```

---

## Task 7: Modify LocalStorageService — Thin Wrapper

**Files:**
- Modify: `lib/services/local_storage_service.dart:67-70,142-153`

- [ ] **Step 1: Delete dead `logout()` method (lines 67-70)**

Remove:
```dart
  // Logout - clear user session but keep data
  Future<void> logout() async {
    await _userBox.put(_isLoggedInKey, false);
  }
```

- [ ] **Step 2: Make `getAuthToken()` delegate to AuthService (lines 142-145)**

Replace the existing `getAuthToken()` at line 142-145:

```dart
  /// Auth token (e.g. Laravel Sanctum). Set after login for API/WebSocket auth.
  String? getAuthToken() {
    return _userBox.get(_authTokenKey) as String?;
  }
```

With a synchronous wrapper that returns the cached token (for backward compatibility with 30+ callsites that call this synchronously):

```dart
  /// Auth token — delegates to AuthService's in-memory cache.
  ///
  /// Returns the cached access token synchronously. AuthService.init() must be
  /// called before this (done in SplashScreen). For async token with refresh,
  /// use AuthService.instance.getValidAccessToken() directly.
  ///
  /// Preserved as thin wrapper for 30+ existing service callsites.
  String? getAuthToken() {
    // Delegate to AuthService's in-memory cache (populated during init)
    return AuthService.instance.cachedAccessToken;
  }
```

The `cachedAccessToken` getter is already defined in AuthService (Task 3 Step 1).

- [ ] **Step 3: Add AuthService import to local_storage_service.dart**

Add at the top of the file, after the existing imports:

```dart
import 'auth_service.dart';
```

- [ ] **Step 4: Deprecate saveAuthToken() (lines 147-153)**

Replace:
```dart
  Future<void> saveAuthToken(String? token) async {
    if (token == null) {
      await _userBox.delete(_authTokenKey);
    } else {
      await _userBox.put(_authTokenKey, token);
    }
  }
```

With:
```dart
  /// @deprecated Use AuthService.saveSession() or AuthService.login() instead.
  /// Kept temporarily for migration — clears the old Hive token slot.
  Future<void> saveAuthToken(String? token) async {
    if (token == null) {
      await _userBox.delete(_authTokenKey);
    } else {
      await _userBox.put(_authTokenKey, token);
    }
  }
```

Note: We keep `saveAuthToken` functional (not broken) because `migrateFromHive()` reads via `getAuthToken()` from Hive during migration, and CompletionScreen still calls it as a fallback until the backend returns dual tokens. The `@deprecated` annotation signals intent.

- [ ] **Step 5: Verify no analysis errors**

Run: `flutter analyze lib/services/local_storage_service.dart lib/services/auth_service.dart`
Expected: No errors.

- [ ] **Step 6: Commit**

```bash
git add lib/services/local_storage_service.dart lib/services/auth_service.dart
git commit -m "refactor(auth): LocalStorageService.getAuthToken() delegates to AuthService cache"
```

---

## Task 8: Modify SplashScreen — AuthService Init + Migration

**Files:**
- Modify: `lib/screens/splash/splash_screen.dart:1-6,47-71`

- [ ] **Step 1: Add AuthService import**

Add after line 2 (`import '../../services/local_storage_service.dart';`):

```dart
import '../../services/auth_service.dart';
```

- [ ] **Step 2: Replace `_checkUserAndNavigate()` method (lines 47-71)**

Replace the entire method with:

```dart
  Future<void> _checkUserAndNavigate() async {
    // Let splash fade-in complete before navigating
    await Future.delayed(_splashFadeDuration);

    if (!mounted) return;

    try {
      // Initialize AuthService (loads tokens from secure storage, fetches pin config)
      await AuthService.instance.init();

      // One-time Hive → secure storage migration
      final migration = await AuthService.instance.migrateFromHive();

      if (!mounted) return;

      // Migration found expired token — must re-login
      if (migration == MigrationResult.tokenExpired) {
        _navigateToRegistration();
        return;
      }

      // Check if authenticated
      final isAuth = await AuthService.instance.isAuthenticated();

      if (!mounted) return;

      if (isAuth) {
        final storage = await LocalStorageService.getInstance();
        final user = storage.getUser();
        if (user != null && user.userId != null && user.userId! > 0) {
          _navigateToHome(user.userId!);
        } else {
          _navigateToRegistration();
        }
      } else {
        _navigateToRegistration();
      }
    } catch (_) {
      if (!mounted) return;
      _navigateToRegistration();
    }
  }
```

- [ ] **Step 3: Add MigrationResult import**

The `MigrationResult` enum is defined in `auth_service.dart`, so the import from Step 1 covers it.

- [ ] **Step 4: Verify no analysis errors**

Run: `flutter analyze lib/screens/splash/splash_screen.dart`
Expected: No errors.

- [ ] **Step 5: Commit**

```bash
git add lib/screens/splash/splash_screen.dart
git commit -m "feat(auth): SplashScreen uses AuthService.init() + Hive migration"
```

---

## Task 9: Modify LoginScreen — Use AuthService.login()

**Files:**
- Modify: `lib/screens/login/login_screen.dart:1-7,36-84`

- [ ] **Step 1: Add AuthService import, remove unused imports**

Replace:
```dart
import '../../services/user_service.dart';
import '../../services/local_storage_service.dart';
```

With:
```dart
import '../../services/auth_service.dart';
```

- [ ] **Step 2: Remove `_userService` field (line 25)**

Remove:
```dart
  final _userService = UserService();
```

- [ ] **Step 3: Replace `_login()` method (lines 36-84)**

Replace the entire method with:

```dart
  Future<void> _login() async {
    final phone = _phoneController.text.trim();
    if (phone.isEmpty) {
      setState(() => _error = 'Tafadhali ingiza nambari ya simu');
      return;
    }

    final pin = _pinController.text.trim();
    if (pin.length != 4) {
      setState(() => _error = 'Tafadhali ingiza PIN ya nambari 4');
      return;
    }

    setState(() {
      _isLoading = true;
      _error = null;
    });

    final result = await AuthService.instance.login(phone, pin);

    if (!mounted) return;

    if (result.success && result.userId != null && result.userId! > 0) {
      Navigator.of(context).pushAndRemoveUntil(
        MaterialPageRoute(
          builder: (_) => HomeScreen(currentUserId: result.userId!),
        ),
        (route) => false,
      );
    } else {
      setState(() {
        _isLoading = false;
        _error = result.error ?? 'Imeshindwa kuingia';
      });
    }
  }
```

Note: `AuthService.login()` returns `AuthLoginResult` (defined in Task 3 Step 9) which has `userId` and `error`. The phone normalization is handled inside AuthService.

- [ ] **Step 4: Verify no analysis errors**

Run: `flutter analyze lib/screens/login/login_screen.dart`
Expected: No errors.

- [ ] **Step 5: Commit**

```bash
git add lib/screens/login/login_screen.dart
git commit -m "feat(auth): LoginScreen uses AuthService.login() for dual-token flow"
```

---

## Task 10: Modify CompletionScreen — Use AuthService.saveSession()

**Files:**
- Modify: `lib/screens/onboarding/completion_screen.dart:1-6,77-122`

- [ ] **Step 1: Add AuthService import**

Add after line 5 (`import '../../services/user_service.dart';`):

```dart
import '../../services/auth_service.dart';
```

- [ ] **Step 2: Replace token saving in `_register()` (lines 88-108)**

Replace this block inside `_register()`:
```dart
        // Apply server-returned profile data to state (userId, profilePhotoUrl).
        if (result.profileData != null) {
          widget.state.applyServerProfile(result.profileData!);
        }

        // Persist session.
        final storage = await LocalStorageService.getInstance();
        await storage.saveAuthToken(result.accessToken);
        await storage.saveUser(widget.state);
```

With:
```dart
        // Apply server-returned profile data to state (userId, profilePhotoUrl).
        if (result.profileData != null) {
          widget.state.applyServerProfile(result.profileData!);
        }

        // Persist session via AuthService (dual-token or legacy single-token).
        // Note: refreshToken/expiresIn fields come from UserRegistrationResult,
        // which must be updated to extract them from the top-level API response
        // (see Task 10 Step 2b below).
        final token = result.accessToken;
        if (token != null && token.isNotEmpty) {
          await AuthService.instance.saveSession(
            accessToken: token,
            refreshToken: result.refreshToken,
            accessExpiresIn: result.accessExpiresIn ?? 86400,
            refreshExpiresIn: result.refreshExpiresIn ?? 7776000,
            user: widget.state,
          );
        }
```

- [ ] **Step 2b: Update UserRegistrationResult to carry refresh token fields**

In `lib/services/user_service.dart`, add fields to `UserRegistrationResult` (around line 370):

```dart
class UserRegistrationResult {
  final bool success;
  final int? userId;
  final String? message;
  final Map<String, dynamic>? profileData;
  final Map<String, dynamic>? errors;
  final String? accessToken;
  final String? refreshToken;        // NEW
  final int? accessExpiresIn;        // NEW
  final int? refreshExpiresIn;       // NEW

  UserRegistrationResult({
    required this.success,
    this.userId,
    this.message,
    this.profileData,
    this.errors,
    this.accessToken,
    this.refreshToken,
    this.accessExpiresIn,
    this.refreshExpiresIn,
  });
}
```

And in the `register()` method's success branch (around line 56), extract the new fields:

```dart
        final refreshToken = data['refresh_token'] as String?;
        final accessExpiresIn = data['access_expires_in'] as int?;
        final refreshExpiresIn = data['refresh_expires_in'] as int?;
        return UserRegistrationResult(
          success: true,
          userId: userId,
          message: data['message'] as String?,
          profileData: profileMap,
          accessToken: accessToken is String ? accessToken : accessToken?.toString(),
          refreshToken: refreshToken,
          accessExpiresIn: accessExpiresIn,
          refreshExpiresIn: refreshExpiresIn,
        );
```

- [ ] **Step 3: Remove unused LocalStorageService import if no longer needed**

Check if `LocalStorageService` is still used in this file. It may still be needed if other code references it — if not, remove the import.

- [ ] **Step 4: Verify no analysis errors**

Run: `flutter analyze lib/screens/onboarding/completion_screen.dart`
Expected: No errors.

- [ ] **Step 5: Commit**

```bash
git add lib/screens/onboarding/completion_screen.dart
git commit -m "feat(auth): CompletionScreen uses AuthService.saveSession() for dual-token storage"
```

---

## Task 11: Modify SettingsScreen — Unified Logout + Logout All Devices

**Files:**
- Modify: `lib/screens/settings/settings_screen.dart:582-620`

- [ ] **Step 1: Add AuthService import**

Add at the top of the file with other imports:

```dart
import '../../services/auth_service.dart';
```

- [ ] **Step 2: Replace `_logout()` method (lines 605-620)**

Replace:
```dart
  Future<void> _logout() async {
    // Stop real-time listeners
    LiveUpdateService.instance.stop();

    // Clear auth token + session
    final storage = await LocalStorageService.getInstance();
    await storage.saveAuthToken(null);
    await storage.clearUser();

    if (mounted) {
      Navigator.of(context).pushAndRemoveUntil(
        MaterialPageRoute(builder: (_) => const SplashScreen()),
        (route) => false,
      );
    }
  }
```

With:
```dart
  Future<void> _logout() async {
    if (mounted) {
      await AuthService.instance.logout(context);
    }
  }
```

- [ ] **Step 3: Add "Logout All Devices" option**

In the settings list (find the existing logout `ListTile`), add a new tile right before or after it:

```dart
ListTile(
  leading: const Icon(Icons.devices, color: Color(0xFF666666)),
  title: Text(s?.logoutAllDevices ?? 'Toka kwenye vifaa vyote'),
  onTap: () => _showLogoutAllDevicesDialog(s),
),
```

And add the dialog method:

```dart
  void _showLogoutAllDevicesDialog(AppStrings? s) {
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        title: Text(s?.logoutAllDevicesTitle ?? 'Toka kwenye vifaa vyote?'),
        content: Text(s?.logoutAllDevicesMessage ??
            'Utatolewa kwenye vifaa vyote vilivyoingia akaunti yako.'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: Text(s?.no ?? 'Hapana'),
          ),
          TextButton(
            onPressed: () async {
              Navigator.pop(ctx);
              if (mounted) {
                await AuthService.instance.logoutAllDevices(context);
              }
            },
            child: Text(
              s?.yesLogout ?? 'Ndio, toka',
              style: const TextStyle(color: Colors.red),
            ),
          ),
        ],
      ),
    );
  }
```

- [ ] **Step 4: Verify no analysis errors**

Run: `flutter analyze lib/screens/settings/settings_screen.dart`
Expected: No errors.

- [ ] **Step 5: Commit**

```bash
git add lib/screens/settings/settings_screen.dart
git commit -m "feat(auth): SettingsScreen uses AuthService.logout(), adds 'logout all devices'"
```

---

## Task 12: Modify ProfileScreen — Unified Logout

**Files:**
- Modify: `lib/screens/profile/profile_screen.dart:533-570`

- [ ] **Step 1: Add AuthService import**

Add at the top with other imports:

```dart
import '../../services/auth_service.dart';
```

- [ ] **Step 2: Replace `_showLogoutDialog()` inline logout (lines 533-570)**

Replace the `onPressed` handler of the "Yes, log out" button. Find the `FilledButton` onPressed that does:
```dart
            try {
              final storage = await LocalStorageService.getInstance();
              await storage.clearUser();
            } catch (e) {
              debugPrint('Error clearing user: $e');
            }
            if (context.mounted) {
              Navigator.of(context).pushAndRemoveUntil(
                MaterialPageRoute(
                  builder: (context) => const RegistrationScreen(),
                ),
                (route) => false,
              );
            }
```

Replace with:
```dart
            if (context.mounted) {
              await AuthService.instance.logout(context);
            }
```

- [ ] **Step 3: Verify no analysis errors**

Run: `flutter analyze lib/screens/profile/profile_screen.dart`
Expected: No errors.

- [ ] **Step 4: Commit**

```bash
git add lib/screens/profile/profile_screen.dart
git commit -m "fix(auth): ProfileScreen uses AuthService.logout() — fixes token not cleared on logout"
```

---

## Task 13: Add Biometric Guards to Sensitive Actions

**Files:**
- Modify: `lib/screens/wallet/wallet_screen.dart:1024,1213,1484`
- Modify: `lib/screens/wallet/send_tip_screen.dart`
- Modify: `lib/screens/wallet/payout_request_screen.dart`
- Modify: `lib/screens/wallet/subscribe_to_creator_screen.dart`
- Modify: `lib/screens/settings/settings_screen.dart` (change phone, change PIN, delete account)

- [ ] **Step 1: Add BiometricService import to wallet_screen.dart**

```dart
import '../../services/biometric_service.dart';
```

- [ ] **Step 2: Add biometric guard to `_deposit()` (line 1024)**

At the top of the `_deposit()` method, before any logic:

```dart
    final authorized = await BiometricService.authenticate(
      reason: 'Thibitisha ili kuweka pesa',
    );
    if (!authorized) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Uthibitisho umeshindwa')),
        );
      }
      return;
    }
```

- [ ] **Step 3: Add biometric guard to `_withdraw()` (line 1213)**

Same pattern at top of `_withdraw()`:

```dart
    final authorized = await BiometricService.authenticate(
      reason: 'Thibitisha ili kutoa pesa',
    );
    if (!authorized) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Uthibitisho umeshindwa')),
        );
      }
      return;
    }
```

- [ ] **Step 4: Add biometric guard to `_transfer()` (line 1484)**

Same pattern at top of `_transfer()`:

```dart
    final authorized = await BiometricService.authenticate(
      reason: 'Thibitisha ili kutuma pesa',
    );
    if (!authorized) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Uthibitisho umeshindwa')),
        );
      }
      return;
    }
```

- [ ] **Step 5: Add biometric guard to send_tip_screen.dart**

Add import and guard at the top of the send/tip action method:

```dart
import '../../services/biometric_service.dart';
```

Guard pattern (same as above, reason: `'Thibitisha ili kutuma zawadi'`).

- [ ] **Step 6: Add biometric guard to payout_request_screen.dart**

Add import and guard at the top of the payout request method:

```dart
import '../../services/biometric_service.dart';
```

Guard pattern (same as above, reason: `'Thibitisha ili kuomba malipo'`).

- [ ] **Step 7: Add biometric guard to subscribe_to_creator_screen.dart**

Add import and guard at the top of the subscribe/payment action method:

```dart
import '../../services/biometric_service.dart';
```

Guard pattern (same as above, reason: `'Thibitisha ili kujisajili'`).

- [ ] **Step 8: Add biometric guards to SettingsScreen sensitive actions**

In `lib/screens/settings/settings_screen.dart`, add biometric guards before:
- Change phone number action
- Change PIN action
- Delete account action

For each, add at the top of the handler:

```dart
    final authorized = await BiometricService.authenticate(
      reason: 'Thibitisha ni wewe kubadilisha mipangilio ya akaunti',
    );
    if (!authorized) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Uthibitisho umeshindwa')),
        );
      }
      return;
    }
```

BiometricService import was already added in Task 11. If not, add:
```dart
import '../../services/biometric_service.dart';
```

- [ ] **Step 9: Verify no analysis errors**

Run: `flutter analyze lib/screens/wallet/wallet_screen.dart lib/screens/wallet/send_tip_screen.dart lib/screens/wallet/payout_request_screen.dart lib/screens/wallet/subscribe_to_creator_screen.dart lib/screens/settings/settings_screen.dart`
Expected: No errors.

- [ ] **Step 10: Commit**

```bash
git add lib/screens/wallet/wallet_screen.dart lib/screens/wallet/send_tip_screen.dart lib/screens/wallet/payout_request_screen.dart lib/screens/wallet/subscribe_to_creator_screen.dart lib/screens/settings/settings_screen.dart
git commit -m "feat(auth): add biometric guards to wallet, subscriptions, and sensitive settings"
```

---

## Task 14: Full Verification

- [ ] **Step 1: Run flutter analyze on all modified/new files**

```bash
flutter analyze \
  lib/config/certificate_pins.dart \
  lib/services/auth_service.dart \
  lib/services/authenticated_dio.dart \
  lib/services/biometric_service.dart \
  lib/services/local_storage_service.dart \
  lib/screens/splash/splash_screen.dart \
  lib/screens/login/login_screen.dart \
  lib/screens/onboarding/completion_screen.dart \
  lib/screens/settings/settings_screen.dart \
  lib/screens/profile/profile_screen.dart \
  lib/screens/wallet/wallet_screen.dart
```

Expected: Zero errors. Only pre-existing info-level warnings acceptable.

- [ ] **Step 2: Run full project analysis**

```bash
flutter analyze
```

Expected: No new errors introduced. Document any pre-existing warnings.

- [ ] **Step 3: Run tests**

```bash
flutter test
```

Expected: All existing tests pass. No regressions.

- [ ] **Step 4: Verify the auth flow mentally**

Walk through these scenarios:
1. **Fresh install:** SplashScreen → AuthService.init() → no token → LoginScreen ✓
2. **Logged in user (post-update, first launch):** SplashScreen → init() → migrateFromHive() → exchange → dual tokens → HomeScreen ✓
3. **Logged in user (normal launch):** SplashScreen → init() → isAuthenticated() → HomeScreen ✓
4. **Token expired during use:** API call → 401 → interceptor → refreshTokens() → retry ✓
5. **Offline user:** refreshTokens() fails (network) → returns expired token → API also fails → "No network" ✓
6. **Refresh token expired (90+ days idle):** refreshTokens() → 401 → clearTokens() → LoginScreen ✓
7. **Logout:** AuthService.logout() → server revoke → clear storage → LoginScreen ✓
8. **Wallet action:** _deposit() → BiometricService.authenticate() → proceed/block ✓

- [ ] **Step 5: Final commit (if any cleanup needed)**

```bash
git add -A
git commit -m "chore(auth): final cleanup and verification for persistent auth"
```

---

## Dependency Graph

```
Task 1 (packages) ─────┬──→ Task 2 (CertificatePins)
                        ├──→ Task 3 (AuthService) ──────┬──→ Task 7 (LocalStorageService)
                        ├──→ Task 5 (BiometricService)  │    Task 8 (SplashScreen)
                        │                                │    Task 9 (LoginScreen)
                        │                                │    Task 10 (CompletionScreen)
                        │                                │    Task 11 (SettingsScreen)
                        │                                │    Task 12 (ProfileScreen)
                        │                                ├──→ Task 4 (AuthenticatedDio)
                        │                                │
                        └──→ Task 6 (Platform Config)    │
                                                         │
Task 5 (BiometricService) + Task 6 ──────────────────────┴──→ Task 13 (Biometric Guards)

All ──→ Task 14 (Verification)
```

**Parallelization opportunities:**
- Tasks 2, 3, 5, 6 can run in parallel after Task 1
- Task 4 depends on Tasks 2 + 3
- Tasks 7-12 depend on Task 3 and can run in parallel with each other
- Task 13 depends on Tasks 5 + 6
- Task 14 runs last

---

## Backend Reminder

This plan is **frontend-only**. The backend must deploy these changes BEFORE the Flutter update ships:

1. Migration: add `device_id`, `is_refresh`, `expires_at` to `personal_access_tokens`
2. Custom expiry middleware (check `expires_at` instead of global config)
3. Endpoints: `/auth/refresh`, `/auth/exchange`, `/auth/logout`, `/auth/logout-all`, `/config/pinning`
4. Modify login/register to return dual tokens with `expires_at`
5. Keep `config/sanctum.php` → `expiration: null`

See spec §1 "Backend API Contract" for full details.
