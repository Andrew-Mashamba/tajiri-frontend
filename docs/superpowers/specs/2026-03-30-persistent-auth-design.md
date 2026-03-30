# TAJIRI Persistent Auth — Instagram-Grade Session Management

## Goal

Make TAJIRI stay logged in permanently (like Instagram) until explicit logout or app reinstall, while hardening security with encrypted storage, refresh token rotation, biometric gates on sensitive actions, and certificate pinning.

## Current State

- Single Sanctum bearer token stored in **plaintext Hive** box (`user_box`, key `auth_token`)
- Token never expires (`config/sanctum.php` → `expiration: null`)
- No refresh token endpoint on backend
- No global 401 interceptor — each service handles (or ignores) 401 independently
- Inconsistent logout: ProfileScreen doesn't wipe token, SettingsScreen does
- `LocalStorageService.logout()` is dead code (never called)
- FCM token not registered on login (only on HomeScreen init)
- No biometric re-auth, no certificate pinning

## Architecture Overview

Dual-token Sanctum model with silent refresh, encrypted OS-level storage, biometric gates for sensitive actions, and TLS certificate pinning.

```
┌─────────────────────────────────────────────────────────┐
│ Flutter App                                             │
│                                                         │
│  AuthService (login, logout, refresh, migration)        │
│       │                                                 │
│       ├── flutter_secure_storage (tokens, device ID)    │
│       ├── Hive (user profile, preferences — non-sensitive)│
│       │                                                 │
│  AuthenticatedDio (singleton)                           │
│       ├── Auto-attaches Bearer header                   │
│       ├── Pre-emptive refresh (token expires < 5min)    │
│       ├── 401 interceptor → silent refresh → retry      │
│       ├── Request queue (dedup during refresh)          │
│       └── Certificate pinning (SPKI hash validation)    │
│                                                         │
│  BiometricService (local_auth wrapper)                  │
│       └── Guards: wallet, phone change, PIN change,     │
│           account deletion, payout requests             │
└─────────────────────────────────────────────────────────┘
         │
         ▼
┌─────────────────────────────────────────────────────────┐
│ Laravel Backend                                         │
│                                                         │
│  POST /api/users/login-by-phone                         │
│       → returns { access_token, refresh_token,          │
│                   access_expires_in, refresh_expires_in }│
│                                                         │
│  POST /api/auth/refresh   (Bearer: refresh_token)       │
│       → validates refresh token + device_id             │
│       → revokes old refresh token                       │
│       → issues new access + refresh pair                │
│       → if revoked token reused: revoke ALL user tokens │
│                                                         │
│  POST /api/auth/logout    (Bearer: access_token)        │
│       → revokes tokens for this device_id               │
│                                                         │
│  POST /api/auth/logout-all (Bearer: access_token)       │
│       → revokes ALL tokens for this user                │
│                                                         │
│  POST /api/auth/exchange  (Bearer: legacy single token)  │
│       → exchanges old single token for new dual pair     │
│       → one-time migration endpoint                      │
│                                                         │
│  personal_access_tokens table                           │
│       → new columns: device_id, is_refresh, expires_at  │
│       → config/sanctum.php expiration: null (managed     │
│         manually via expires_at column per token)        │
└─────────────────────────────────────────────────────────┘
```

---

## Section 1: Token Architecture

### Token Types

| Token | Sanctum Ability | TTL | Storage |
|---|---|---|---|
| Access token | `["access"]` | 1 day (24h) | `flutter_secure_storage` |
| Refresh token | `["refresh"]` | 90 days (sliding) | `flutter_secure_storage` |

"Sliding" means the 90-day clock resets every time the refresh token is used. A user who opens the app at least once every 90 days never logs out.

### Login/Register Response

```json
{
  "success": true,
  "access_token": "1|abc...",
  "refresh_token": "2|xyz...",
  "access_expires_in": 86400,
  "refresh_expires_in": 7776000,
  "user": { ... }
}
```

### Refresh Token Rotation

On every refresh call, the server:
1. Validates the refresh token and checks `device_id` matches
2. Revokes the used refresh token
3. Issues a new access token + new refresh token
4. Returns the new pair

**Reuse detection:** If a revoked refresh token is presented (indicating theft), the server revokes ALL tokens for that user across all devices → forced logout everywhere.

### Backend API Contract

| Endpoint | Method | Auth | Request Body | Response |
|---|---|---|---|---|
| `/api/users/login-by-phone` | POST | None | `{ phone_number, pin, device_id }` | `{ success, access_token, refresh_token, access_expires_in, refresh_expires_in, user }` |
| `/api/users/register` | POST | None | `{ ...registration_data, device_id }` | Same shape as login |
| `/api/auth/refresh` | POST | Bearer (refresh token) | `{ device_id }` | `{ access_token, refresh_token, access_expires_in, refresh_expires_in }` |
| `/api/auth/logout` | POST | Bearer (access token) | `{ device_id }` | `{ success: true }` |
| `/api/auth/logout-all` | POST | Bearer (access token) | — | `{ success: true }` |
| `/api/auth/exchange` | POST | Bearer (legacy token) | `{ device_id }` | `{ access_token, refresh_token, access_expires_in, refresh_expires_in }` |

**`/api/auth/exchange`** is a one-time migration endpoint. It accepts a valid legacy single Sanctum token (pre-update) and returns a new dual-token pair. The old token is revoked. This enables transparent migration for existing users without forcing re-login.

### Backend Database Changes

Add to `personal_access_tokens` table:
- `device_id` — VARCHAR(36), nullable (UUID from client)
- `is_refresh` — BOOLEAN, default false

Keep `config/sanctum.php`:
- `'expiration' => null` (Sanctum's built-in expiration applies globally to ALL tokens and cannot distinguish access vs refresh — setting it to 1440 would expire refresh tokens after 24h too)

**Both token expiries are managed manually** via an `expires_at` column on the `personal_access_tokens` table:
- Access tokens: `expires_at = now + 24 hours`
- Refresh tokens: `expires_at = now + 90 days`
- The refresh endpoint, login, and register all set `expires_at` explicitly when creating tokens
- A custom Sanctum middleware or guard checks `expires_at` instead of the global config
- Login should only revoke tokens for the same `device_id`, not all tokens (to support multi-device)

**Rate limiting:** The `/api/auth/refresh` endpoint should be rate-limited to 5 attempts per minute per `device_id` to prevent abuse.

---

## Section 2: Secure Storage Layer

### Two-Tier Split

| Data | Storage | Encrypted | Why |
|---|---|---|---|
| Access token | `flutter_secure_storage` | Yes (OS Keychain/Keystore) | Sensitive credential |
| Refresh token | `flutter_secure_storage` | Yes | Sensitive credential |
| Access expiry timestamp | `flutter_secure_storage` | Yes | Needed for pre-emptive refresh |
| Device ID (UUID v4) | `flutter_secure_storage` | Yes | Device binding, survives updates, wiped on reinstall |
| User profile (RegistrationState) | Hive | No | Non-sensitive, fast reads, offline display |
| Preferences (theme, language, tabs) | Hive | No | Non-sensitive |

### Device ID

Generated once on first launch via `uuid` package. Stored in `flutter_secure_storage`. Survives app updates but is wiped on reinstall — this is the "Instagram reinstall = re-login" behavior.

### Migration from Hive

On first launch after update:
1. Check if `flutter_secure_storage` has an access token
2. If not, check Hive for old `auth_token`
3. If found in Hive:
   a. Copy to `flutter_secure_storage` as a temporary legacy token
   b. Delete from Hive
   c. Call `POST /api/auth/exchange` with the legacy token + device_id
   d. If exchange succeeds: store the new dual-token pair, discard legacy token
   e. If exchange fails (token already expired/revoked on server): clear storage, redirect to LoginScreen with a friendly message ("Tafadhali ingia tena — tumeongeza usalama mpya" / "Please log in again — we've added new security")
4. One-time, transparent to user if token is still valid on server

### Secure Storage Keys

```dart
static const _accessTokenKey = 'tajiri_access_token';
static const _refreshTokenKey = 'tajiri_refresh_token';
static const _accessExpiryKey = 'tajiri_access_expiry';
static const _refreshExpiryKey = 'tajiri_refresh_expiry';
static const _deviceIdKey = 'tajiri_device_id';
```

---

## Section 3: AuthService

New file: `lib/services/auth_service.dart`

Single source of truth for all auth operations. Replaces scattered token handling across `LocalStorageService`, `LoginScreen`, `SettingsScreen`, and `ProfileScreen`.

**Singleton pattern** (not all-static) because the refresh flow needs mutable instance state: an in-memory token cache (avoids async I/O on every request), a `Completer`-based refresh lock, and testability via dependency injection.

### Public API

```dart
class AuthService {
  static final AuthService instance = AuthService._();
  AuthService._();

  // In-memory cache (populated from secure storage on init)
  String? _cachedAccessToken;
  DateTime? _cachedAccessExpiry;
  Completer<bool>? _refreshLock;

  /// Initialize: load tokens from secure storage into memory cache.
  Future<void> init() async

  /// Check if user has a valid session (token exists in secure storage).
  Future<bool> isAuthenticated() async

  /// Login: call backend, store both tokens + device ID, save user to Hive.
  Future<LoginResult> login(String phone, String pin) async

  /// Save session after registration (called from CompletionScreen).
  Future<void> saveSession({
    required String accessToken,
    required String refreshToken,
    required int accessExpiresIn,
    required int refreshExpiresIn,
    required RegistrationState user,
  }) async

  /// Get current access token (refreshes if expired/expiring soon).
  /// On network failure during refresh: returns expired token (let request
  /// fail naturally with connectivity error, don't force logout for offline).
  Future<String?> getValidAccessToken() async

  /// Refresh tokens silently. Returns true if successful.
  /// Distinguishes network errors from auth rejection (401/403).
  Future<bool> refreshTokens() async

  /// Logout: call backend (best-effort), clear all storage, navigate to login.
  Future<void> logout(BuildContext context) async

  /// Logout all devices: call backend, then local logout.
  Future<void> logoutAllDevices(BuildContext context) async

  /// Get device ID (generates on first call).
  Future<String> getDeviceId() async

  /// One-time migration from Hive to secure storage + token exchange.
  Future<void> migrateFromHive() async
}
```

### LoginResult

```dart
class LoginResult {
  final bool success;
  final String? error;
  final RegistrationState? user;
  final int? userId;

  const LoginResult({required this.success, this.error, this.user, this.userId});
}
```

### Token Refresh Logic

```
getValidAccessToken()
  → Check in-memory cache first (avoids async I/O)
  → If expires in > 5 minutes → return cached access token
  → If expires in < 5 minutes → call refreshTokens()
      → POST /api/auth/refresh with refresh token + device_id
      → Success: store new tokens, update cache, return new access token
      → Auth failure (401/403 from refresh endpoint): return null → interceptor redirects to login
      → Network failure (SocketException, timeout): return the expired token anyway
        (let the API request fail naturally with a connectivity error — do NOT force
        logout just because the user is offline)
```

The 5-minute buffer avoids the 401 round-trip on slow 2G/EDGE networks — refresh proactively before the token actually expires.

**Offline behavior:** If refresh fails due to no internet, the app returns the (possibly expired) token. The subsequent API call will also fail with a network error, and the UI shows "Hakuna mtandao" (no network). The user is NOT logged out — they can continue viewing cached data and retry when connectivity returns. Only an explicit 401/403 from the refresh endpoint triggers logout.

---

## Section 4: AuthenticatedDio (Interceptor)

New file: `lib/services/authenticated_dio.dart`

Singleton Dio instance that all API calls go through. Handles auth headers, silent refresh, request queuing, and certificate pinning.

### Interceptor Flow

```
Request phase:
  → Get valid access token from AuthService
  → If token is null → reject request (not authenticated)
  → Attach Authorization: Bearer {token}
  → Attach certificate pins

Response phase:
  → 2xx → pass through
  → 401 → enter refresh flow:
      ├─ Acquire refresh lock (Completer-based)
      ├─ If lock already held → queue this request, await lock
      ├─ If lock acquired → call AuthService.refreshTokens()
      │   ├─ Success → release lock, replay queued requests with new token
      │   └─ Failure → release lock, clear auth, navigate to LoginScreen
      └─ Return replayed response
  → Other errors → pass through
```

### Request Queue

A `Completer<void>` acts as the lock. When a 401 triggers refresh:
1. First 401 creates the Completer and starts refresh
2. Subsequent 401s during refresh `await` the same Completer
3. On refresh complete, Completer resolves and all queued requests retry

This prevents N simultaneous refresh calls when multiple API requests fail at once.

### Migration Strategy

Services migrate from `http` to `AuthenticatedDio` incrementally — not a big-bang rewrite.

```dart
// Before (in any service):
final response = await http.get(
  Uri.parse('$baseUrl/posts'),
  headers: ApiConfig.authHeaders(token),
);

// After:
final response = await AuthenticatedDio.instance.get('/posts');
// Token attached automatically, 401 handled automatically
```

Existing services continue working with old `http` + Hive token until migrated. The `AuthenticatedDio` and old approach coexist safely.

---

## Section 5: Biometric Re-authentication

New file: `lib/services/biometric_service.dart`

New package: `local_auth: ^2.3.0`

### Guarded Actions

| Screen | Action |
|---|---|
| WalletScreen | Deposit, withdraw, transfer |
| SendTipScreen | Send tip |
| PayoutRequestScreen | Request payout |
| SettingsScreen | Change phone number, change PIN |
| SettingsScreen | Delete account |
| SubscribeToCreatorScreen | Subscribe (involves payment) |

### Flow

```
User taps guarded action
  → BiometricService.authenticate(reason: "Thibitisha ni wewe...")
      ├─ Device has biometrics → prompt Face ID / fingerprint
      ├─ Device has no biometrics → fall back to device PIN/pattern/password
      └─ Neither available (no lock screen at all) → return true (don't block)
  → true → proceed with action
  → false → show snackbar "Uthibitisho umeshindwa", don't proceed
```

**Known tradeoff:** On devices with no biometric hardware AND no lock screen set up, the biometric gate is skipped entirely. This is acceptable for the Tanzanian market where many low-end Android devices lack biometric sensors. The `local_auth` package's `deviceSupportLevel` check handles this. A future enhancement could prompt the user to set up a device lock screen.

### Public API

```dart
class BiometricService {
  /// Returns true if authentication succeeded or biometrics unavailable.
  /// Returns false if user cancelled or failed.
  static Future<bool> authenticate({
    String reason = 'Thibitisha ni wewe kwa alama ya kidole au uso',
  }) async
}
```

### Platform Config

**iOS** — add to `ios/Runner/Info.plist`:
```xml
<key>NSFaceIDUsageDescription</key>
<string>TAJIRI inahitaji uthibitisho wako kwa usalama wa akaunti yako</string>
```

**Android** — add to `android/app/src/main/AndroidManifest.xml`:
```xml
<uses-permission android:name="android.permission.USE_BIOMETRIC"/>
```

---

## Section 6: Certificate Pinning

New file: `lib/config/certificate_pins.dart`

### Implementation

Pin SPKI (Subject Public Key Info) SHA-256 hashes at the Dio level. Two pins: primary (current cert) + backup (CA intermediate or next cert).

```dart
class CertificatePins {
  /// Primary pin: current tajiri.zimasystems.com certificate
  static const String primary = 'sha256/AAAA...base64...';

  /// Backup pin: CA intermediate (prevents lockout on cert rotation)
  static const String backup = 'sha256/BBBB...base64...';

  /// Runtime kill switch — fetched from backend on app start.
  /// Defaults to true; set to false if remote config says so.
  static bool enabled = true;

  /// Pinning is ONLY active for production (tajiri.zimasystems.com).
  /// Disabled automatically when ApiConfig.baseUrl points to UAT or localhost.
  static bool get shouldPin =>
      enabled &&
      ApiConfig.baseUrl.contains('tajiri.zimasystems.com');
}
```

**Kill switch implementation:** On app start (in `AuthService.init()`), make a single unpinned GET to `GET /api/config/pinning` (public, no auth). Returns `{ "enabled": true }`. If it returns `false` or the request fails, set `CertificatePins.enabled = false`. This allows disabling pinning server-side without an app update. The config endpoint itself is never pinned (chicken-and-egg).

### Pin Extraction (during implementation)

```bash
openssl s_client -connect tajiri.zimasystems.com:443 2>/dev/null | \
  openssl x509 -pubkey -noout | \
  openssl pkey -pubin -outform DER | \
  openssl dgst -sha256 -binary | base64
```

### Failure Behavior

If pin validation fails, the request is rejected with a network error. The app does NOT redirect to login — it shows a connectivity error. This prevents silent MITM without accidentally logging users out.

### Kill Switch

`CertificatePins.enabled` is controlled at runtime via the `GET /api/config/pinning` endpoint described above. On app start, `AuthService.init()` fetches this config (unpinned request) and sets the flag. If the endpoint is unreachable, pinning defaults to enabled.

---

## Section 7: Logout Consistency

### Current Bugs

1. `ProfileScreen._showLogoutDialog()` calls `storage.clearUser()` but does NOT clear auth token — token stays in Hive
2. `LocalStorageService.logout()` sets `is_logged_in = false` but is never called — dead code
3. No server-side token revocation on logout

### Fix: Single Unified Logout

Delete `LocalStorageService.logout()` (dead code). Both ProfileScreen and SettingsScreen call `AuthService.logout(context)`:

```
AuthService.logout(context):
  1. POST /api/auth/logout { device_id } (best-effort, don't await/block on failure)
  2. LiveUpdateService.instance.stop()
  3. Clear flutter_secure_storage (all keys)
  4. Clear Hive user data (storage.clearUser())
  5. Navigator.pushAndRemoveUntil → LoginScreen (clear entire stack)
```

### "Logout All Devices"

Available in SettingsScreen:
```
AuthService.logoutAllDevices(context):
  1. POST /api/auth/logout-all (blocks until response — user should see confirmation)
  2. Same local cleanup as regular logout
```

---

## Section 8: FCM Fix

### Current Bug

`FcmService.sendTokenToBackend(userId)` is called in `HomeScreen.initState()` but NOT after login in `LoginScreen._login()`. If a user logs in and the FCM token was already sent for a previous user, push notifications go to the wrong person (or nowhere).

### Fix

Call `FcmService.instance.sendTokenToBackend(userId)` inside `AuthService.login()` and `AuthService.saveSession()` — immediately after tokens are stored. This ensures FCM is registered for every login and registration.

---

## File Inventory

### New Files (4)

| File | Purpose |
|---|---|
| `lib/services/auth_service.dart` | Token management, login, logout, refresh, Hive migration |
| `lib/services/authenticated_dio.dart` | Dio singleton with interceptor, request queue, cert pinning |
| `lib/services/biometric_service.dart` | `local_auth` wrapper, single `authenticate()` method |
| `lib/config/certificate_pins.dart` | SPKI pin hashes, kill switch flag |

### Modified Files (~12)

| File | Change |
|---|---|
| `pubspec.yaml` | Add `flutter_secure_storage: ^9.2.4`, `local_auth: ^2.3.0`, `uuid: ^4.5.1` |
| `lib/services/local_storage_service.dart` | Remove `saveAuthToken` (writes), delete `logout()` (dead code). **Keep `getAuthToken()` as a thin wrapper** that delegates to `AuthService.instance.getValidAccessToken()` — this preserves compatibility with the 30+ service files that call it, allowing incremental migration to `AuthenticatedDio`. |
| `lib/screens/splash/splash_screen.dart` | Replace Hive check with `AuthService.isAuthenticated()` + `AuthService.migrateFromHive()` |
| `lib/screens/login/login_screen.dart` | Replace manual token save with `AuthService.login()` |
| `lib/screens/onboarding/completion_screen.dart` | Replace manual token save with `AuthService.saveSession()` |
| `lib/screens/settings/settings_screen.dart` | Replace manual logout with `AuthService.logout(context)`. Add "Logout all devices" option. |
| `lib/screens/profile/profile_screen.dart` | Replace manual logout with `AuthService.logout(context)` |
| `lib/config/api_config.dart` | Add `enableCertPinning` flag |
| `lib/screens/wallet/wallet_screen.dart` | Add biometric guard before deposit/withdraw/transfer |
| `lib/screens/wallet/send_tip_screen.dart` | Add biometric guard |
| `lib/screens/wallet/payout_request_screen.dart` | Add biometric guard |
| `ios/Runner/Info.plist` | Add `NSFaceIDUsageDescription` |
| `android/app/src/main/AndroidManifest.xml` | Add `USE_BIOMETRIC` permission |

### Backend Changes (spec only — built separately)

| Change | Detail |
|---|---|
| New endpoint `POST /api/auth/refresh` | Validate refresh token + device_id, rotate tokens, reuse detection. Rate limit: 5/min per device_id. |
| New endpoint `POST /api/auth/exchange` | Accept legacy single token + device_id, return dual-token pair, revoke old token. One-time migration. |
| New endpoint `POST /api/auth/logout` | Revoke tokens matching authenticated user AND provided device_id |
| New endpoint `POST /api/auth/logout-all` | Revoke all user tokens |
| New endpoint `GET /api/config/pinning` | Public (no auth). Returns `{ "enabled": true/false }`. Certificate pinning kill switch. |
| Migration | Add `device_id` (VARCHAR 36), `is_refresh` (BOOLEAN), `expires_at` (TIMESTAMP nullable) to `personal_access_tokens` |
| Config | Keep `config/sanctum.php` → `'expiration' => null` (managed manually via `expires_at` column) |
| Custom middleware | Check `expires_at` on token instead of Sanctum's global expiration |
| Modify login | Only revoke tokens for same `device_id` (not all). Return `access_token`, `refresh_token`, `access_expires_in`, `refresh_expires_in` |
| Modify register | Same response shape as login |

---

## Compatibility & Rollout

### Backward Compatibility

- Old app versions (pre-update) continue working: their Sanctum tokens still exist in the DB and never expire until config change is deployed
- Backend should deploy the new endpoints and custom expiry middleware FIRST, then ship the Flutter update. Sanctum `expiration` stays `null` — expiry is managed via the `expires_at` column.
- Migration logic in SplashScreen handles Hive → secure storage transparently

### Rollout Order

1. **Backend**: Deploy migration (add `device_id`, `is_refresh`, `expires_at` columns)
2. **Backend**: Deploy new endpoints (`/auth/refresh`, `/auth/exchange`, `/auth/logout`, `/auth/logout-all`, `/config/pinning`) + custom expiry middleware. Existing tokens continue working (no `expires_at` = treated as non-expiring).
3. **Backend**: Modify login/register to return dual tokens with `expires_at` set. Old app versions still work (they ignore the extra fields and use `access_token` as before).
4. **Frontend**: Ship app update with AuthService, interceptor, biometric, pinning.
5. On first launch after update: SplashScreen calls `migrateFromHive()` → exchanges legacy token via `/auth/exchange` → user gets dual tokens seamlessly. If token was already expired, user sees a friendly re-login prompt.

### Risk Mitigation

- Certificate pinning has a **runtime kill switch** (fetched from `/api/config/pinning` on app start). Pinning auto-disabled for UAT/localhost.
- Biometric gracefully skips on devices without hardware support or lock screen
- Auth rejection (401/403 from refresh) → clean redirect to login
- Network failure during refresh → keep expired token, show connectivity error (don't force logout offline)
- Pre-emptive refresh (5-min buffer) avoids 401 round-trips on slow 2G/EDGE
- `getAuthToken()` preserved as thin wrapper in `LocalStorageService` → 30+ existing service callsites continue working during incremental migration
- Legacy token exchange endpoint (`/auth/exchange`) ensures transparent migration for existing users
