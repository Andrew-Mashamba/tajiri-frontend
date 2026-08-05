import 'dart:convert';
import 'package:http/http.dart' as http;
import '../config/api_config.dart';
import 'http_retry.dart';
import 'local_storage_service.dart';

/// Security-related API calls: 2FA, wallet PIN, recovery codes.
class SecurityService {
  final http.Client _client;

  SecurityService({http.Client? client}) : _client = client ?? http.Client();

  Future<String?> _token() async {
    final storage = await LocalStorageService.getInstance();
    return storage.getAuthToken();
  }

  Map<String, String> _headers(String? token) {
    return {
      ...(token != null ? ApiConfig.authHeaders(token) : ApiConfig.headers),
      'Content-Type': 'application/json',
    };
  }

  // ── 2FA ───────────────────────────────────────────────────────────────────

  Future<({bool success, bool enabled, String? error})> check2FAStatus(int userId) async {
    try {
      final token = await _token();
      final resp = await httpClientGetWithRetry(
        _client,
        Uri.parse('${ApiConfig.baseUrl}/2fa/status?user_id=$userId'),
        headers: token != null ? ApiConfig.authHeaders(token) : ApiConfig.headers,
      );
      if (resp.statusCode == 200) {
        final data = jsonDecode(resp.body);
        return (success: true, enabled: data['enabled'] == true, error: null);
      }
      return (success: false, enabled: false, error: 'Failed to check 2FA status');
    } catch (e) {
      return (success: false, enabled: false, error: 'Network error');
    }
  }

  Future<({bool success, String? qrUrl, List<String> recoveryCodes, String? error})> enable2FA(int userId) async {
    try {
      final token = await _token();
      final resp = await _client.post(
        Uri.parse('${ApiConfig.baseUrl}/2fa/enable'),
        headers: _headers(token),
        body: jsonEncode({'user_id': userId}),
      );
      if (resp.statusCode == 200) {
        final data = jsonDecode(resp.body);
        final codes = (data['recovery_codes'] as List?)
                ?.map((c) => c.toString())
                .toList() ??
            [];
        return (success: true, qrUrl: data['qr_url'] as String?, recoveryCodes: codes, error: null);
      }
      return (success: false, qrUrl: null, recoveryCodes: <String>[], error: 'Failed to enable 2FA');
    } catch (e) {
      return (success: false, qrUrl: null, recoveryCodes: <String>[], error: 'Network error');
    }
  }

  Future<({bool success, String? error})> confirm2FA(int userId, String code) async {
    try {
      final token = await _token();
      final resp = await _client.post(
        Uri.parse('${ApiConfig.baseUrl}/2fa/confirm'),
        headers: _headers(token),
        body: jsonEncode({'user_id': userId, 'code': code}),
      );
      if (resp.statusCode == 200) {
        return (success: true, error: null);
      }
      return (success: false, error: 'Invalid code. Please try again.');
    } catch (e) {
      return (success: false, error: 'Network error');
    }
  }

  Future<({bool success, String? error})> disable2FA(int userId) async {
    try {
      final token = await _token();
      final resp = await _client.delete(
        Uri.parse('${ApiConfig.baseUrl}/2fa/disable'),
        headers: _headers(token),
        body: jsonEncode({'user_id': userId}),
      );
      if (resp.statusCode == 200) {
        return (success: true, error: null);
      }
      return (success: false, error: 'Failed to disable 2FA');
    } catch (e) {
      return (success: false, error: 'Network error');
    }
  }

  Future<({bool success, List<String> codes, String? error})> regenerateRecoveryCodes(int userId) async {
    try {
      final token = await _token();
      final resp = await _client.post(
        Uri.parse('${ApiConfig.baseUrl}/2fa/recovery-codes'),
        headers: _headers(token),
        body: jsonEncode({'user_id': userId}),
      );
      if (resp.statusCode == 200) {
        final data = jsonDecode(resp.body);
        final codes = (data['recovery_codes'] as List?)
                ?.map((c) => c.toString())
                .toList() ??
            [];
        return (success: true, codes: codes, error: null);
      }
      return (success: false, codes: <String>[], error: 'Failed to regenerate codes');
    } catch (e) {
      return (success: false, codes: <String>[], error: 'Network error');
    }
  }

  // ── Wallet PIN ────────────────────────────────────────────────────────────

  Future<({bool success, String? error})> setWalletPin(int userId, String pin, String confirmPin) async {
    try {
      final token = await _token();
      final resp = await _client.post(
        Uri.parse('${ApiConfig.baseUrl}/wallet/$userId/pin'),
        headers: _headers(token),
        body: jsonEncode({'pin': pin, 'confirm_pin': confirmPin}),
      );
      if (resp.statusCode == 200) {
        return (success: true, error: null);
      }
      final data = jsonDecode(resp.body) as Map<String, dynamic>;
      return (success: false, error: data['message'] as String? ?? 'Failed to set PIN');
    } catch (e) {
      return (success: false, error: 'Network error');
    }
  }

  Future<({bool success, String? error})> changeWalletPin(
    int userId,
    String currentPin,
    String newPin,
    String confirmPin,
  ) async {
    try {
      final token = await _token();
      final resp = await _client.put(
        Uri.parse('${ApiConfig.baseUrl}/wallet/$userId/pin'),
        headers: _headers(token),
        body: jsonEncode({
          'current_pin': currentPin,
          'new_pin': newPin,
          'confirm_pin': confirmPin,
        }),
      );
      if (resp.statusCode == 200) {
        return (success: true, error: null);
      }
      final data = jsonDecode(resp.body) as Map<String, dynamic>;
      return (success: false, error: data['message'] as String? ?? 'Failed to change PIN');
    } catch (e) {
      return (success: false, error: 'Network error');
    }
  }

  // ── App PIN ───────────────────────────────────────────────────────────────

  Future<({bool success, bool hasPin, bool biometricEnabled, int timeout, String? error})> checkAppLockStatus(int userId) async {
    try {
      final token = await _token();
      final resp = await httpClientGetWithRetry(
        _client,
        Uri.parse('${ApiConfig.baseUrl}/security/pin/status?user_id=$userId'),
        headers: token != null ? ApiConfig.authHeaders(token) : ApiConfig.headers,
      );
      if (resp.statusCode == 200) {
        final data = jsonDecode(resp.body) as Map<String, dynamic>;
        final d = data['data'] as Map<String, dynamic>?;
        return (
          success: true,
          hasPin: d?['has_pin'] == true,
          biometricEnabled: d?['biometric_enabled'] == true,
          timeout: d?['lock_timeout_seconds'] as int? ?? 300,
          error: null,
        );
      }
      return (success: false, hasPin: false, biometricEnabled: false, timeout: 300, error: 'Failed to check status');
    } catch (e) {
      return (success: false, hasPin: false, biometricEnabled: false, timeout: 300, error: 'Network error');
    }
  }

  /// Server-side PIN verification (POST /api/security/pin/verify).
  /// Used by sensitive flows that need to re-confirm the user just typed
  /// the right PIN — e.g. enabling biometric quick-login.
  Future<({bool success, String? error})> verifyAppLockPin(int userId, String pin) async {
    try {
      final token = await _token();
      final resp = await _client.post(
        Uri.parse('${ApiConfig.baseUrl}/security/pin/verify'),
        headers: _headers(token),
        body: jsonEncode({'user_id': userId, 'pin': pin}),
      );
      if (resp.statusCode == 200) {
        final body = jsonDecode(resp.body) as Map<String, dynamic>;
        if (body['success'] == true) return (success: true, error: null);
        return (success: false, error: body['message'] as String? ?? 'Incorrect PIN');
      }
      try {
        final body = jsonDecode(resp.body) as Map<String, dynamic>;
        return (success: false, error: body['message'] as String? ?? 'Incorrect PIN');
      } catch (_) {
        return (success: false, error: 'Incorrect PIN');
      }
    } catch (_) {
      return (success: false, error: 'Network error');
    }
  }

  Future<({bool success, String? error})> setAppLockPin(int userId, String pin) async {
    try {
      final token = await _token();
      final resp = await _client.post(
        Uri.parse('${ApiConfig.baseUrl}/security/pin'),
        headers: _headers(token),
        body: jsonEncode({'user_id': userId, 'pin': pin}),
      );
      if (resp.statusCode == 200) {
        return (success: true, error: null);
      }
      final data = jsonDecode(resp.body) as Map<String, dynamic>;
      return (success: false, error: data['message'] as String? ?? 'Failed to set PIN');
    } catch (e) {
      return (success: false, error: 'Network error');
    }
  }

  /// Change the app-lock / sign-in PIN.
  ///
  /// If `stepUpToken` is provided AND not the `BiometricStepUp.skipStepUp`
  /// sentinel, it's forwarded as `X-Step-Up-Token`. The backend's
  /// `BiometricStepUp::consume` gate requires a fresh signed challenge
  /// for any user who has biometric armed, so the screen MUST call
  /// `BiometricStepUp.confirm(purpose: 'pin_change')` before this and
  /// pass the result through.
  Future<({bool success, String? error, bool requiresStepUp})> changeAppLockPin(
    int userId,
    String currentPin,
    String newPin, {
    String? stepUpToken,
  }) async {
    try {
      final token = await _token();
      final headers = {..._headers(token)};
      if (stepUpToken != null && stepUpToken != _kSkipStepUpSentinel) {
        headers['X-Step-Up-Token'] = stepUpToken;
      }
      final resp = await _client.put(
        Uri.parse('${ApiConfig.baseUrl}/security/pin'),
        headers: headers,
        body: jsonEncode({'user_id': userId, 'current_pin': currentPin, 'new_pin': newPin}),
      );
      if (resp.statusCode == 200) {
        return (success: true, error: null, requiresStepUp: false);
      }
      final data = jsonDecode(resp.body) as Map<String, dynamic>;
      final needsStepUp = data['requires_step_up'] == true;
      return (
        success: false,
        error: data['message'] as String? ?? 'Failed to change PIN',
        requiresStepUp: needsStepUp,
      );
    } catch (e) {
      return (success: false, error: 'Network error', requiresStepUp: false);
    }
  }

  Future<({bool success, String? error, bool requiresStepUp})> removeAppLockPin(
    int userId,
    String currentPin, {
    String? stepUpToken,
  }) async {
    try {
      final token = await _token();
      final headers = {..._headers(token)};
      if (stepUpToken != null && stepUpToken != _kSkipStepUpSentinel) {
        headers['X-Step-Up-Token'] = stepUpToken;
      }
      final resp = await _client.delete(
        Uri.parse('${ApiConfig.baseUrl}/security/pin'),
        headers: headers,
        body: jsonEncode({'user_id': userId, 'current_pin': currentPin}),
      );
      if (resp.statusCode == 200) {
        return (success: true, error: null, requiresStepUp: false);
      }
      final data = jsonDecode(resp.body) as Map<String, dynamic>;
      final needsStepUp = data['requires_step_up'] == true;
      return (
        success: false,
        error: data['message'] as String? ?? 'Failed to remove PIN',
        requiresStepUp: needsStepUp,
      );
    } catch (e) {
      return (success: false, error: 'Network error', requiresStepUp: false);
    }
  }

  // Mirrors BiometricStepUp.skipStepUp; duplicated to avoid the
  // service depending on the helper file.
  static const String _kSkipStepUpSentinel = '__bio_step_up_not_enrolled__';

  // ── Security activity log ────────────────────────────────────────────────

  Future<List<SecurityActivityItem>> activityLog(int userId, {int limit = 50}) async {
    try {
      final token = await _token();
      final resp = await httpClientGetWithRetry(
        _client,
        Uri.parse('${ApiConfig.baseUrl}/users/$userId/security-activity?limit=$limit'),
        headers: token != null ? ApiConfig.authHeaders(token) : ApiConfig.headers,
      );
      if (resp.statusCode != 200) return const [];
      final body = jsonDecode(resp.body) as Map<String, dynamic>;
      final list = (body['data'] as List?) ?? const [];
      return list
          .whereType<Map>()
          .map((m) => SecurityActivityItem.fromJson(m.cast<String, dynamic>()))
          .toList();
    } catch (_) {
      return const [];
    }
  }

  // ── Active sessions ──────────────────────────────────────────────────────

  Future<List<SessionInfo>> sessions(int userId) async {
    try {
      final token = await _token();
      final resp = await httpClientGetWithRetry(
        _client,
        Uri.parse('${ApiConfig.baseUrl}/sessions?user_id=$userId'),
        headers: token != null ? ApiConfig.authHeaders(token) : ApiConfig.headers,
      );
      if (resp.statusCode != 200) return const [];
      final body = jsonDecode(resp.body);
      final list = body is Map ? (body['sessions'] ?? body['data'] ?? const []) : const [];
      return (list as List)
          .whereType<Map>()
          .map((m) => SessionInfo.fromJson(m.cast<String, dynamic>()))
          .toList();
    } catch (_) {
      return const [];
    }
  }

  Future<bool> revokeSession(int sessionId) async {
    try {
      final token = await _token();
      final resp = await _client.delete(
        Uri.parse('${ApiConfig.baseUrl}/sessions/$sessionId'),
        headers: token != null ? ApiConfig.authHeaders(token) : ApiConfig.headers,
      );
      return resp.statusCode == 200;
    } catch (_) {
      return false;
    }
  }

  Future<bool> revokeAllSessions(int userId) async {
    try {
      final token = await _token();
      final resp = await _client.post(
        Uri.parse('${ApiConfig.baseUrl}/sessions/revoke-all'),
        headers: _headers(token),
        body: jsonEncode({'user_id': userId}),
      );
      return resp.statusCode == 200;
    } catch (_) {
      return false;
    }
  }

  Future<({bool success, String? error})> updateAppLockSettings(
    int userId, {
    bool? biometricEnabled,
    int? timeoutSeconds,
  }) async {
    try {
      final token = await _token();
      final body = <String, dynamic>{'user_id': userId};
      if (biometricEnabled != null) body['biometric_enabled'] = biometricEnabled;
      if (timeoutSeconds != null) body['lock_timeout_seconds'] = timeoutSeconds;
      final resp = await _client.put(
        Uri.parse('${ApiConfig.baseUrl}/security/settings'),
        headers: _headers(token),
        body: jsonEncode(body),
      );
      if (resp.statusCode == 200) {
        return (success: true, error: null);
      }
      final data = jsonDecode(resp.body) as Map<String, dynamic>;
      return (success: false, error: data['message'] as String? ?? 'Failed to update settings');
    } catch (e) {
      return (success: false, error: 'Network error');
    }
  }
}

class SecurityActivityItem {
  final int id;
  final String eventType;
  final String? ipAddress;
  final String? userAgent;
  final String? geoCountry;
  final Map<String, dynamic>? meta;
  final DateTime? createdAt;

  SecurityActivityItem({
    required this.id,
    required this.eventType,
    this.ipAddress,
    this.userAgent,
    this.geoCountry,
    this.meta,
    this.createdAt,
  });

  factory SecurityActivityItem.fromJson(Map<String, dynamic> json) {
    Map<String, dynamic>? meta;
    final raw = json['meta'];
    if (raw is Map) {
      meta = raw.cast<String, dynamic>();
    } else if (raw is String && raw.isNotEmpty) {
      try {
        meta = jsonDecode(raw) as Map<String, dynamic>;
      } catch (_) {
        meta = null;
      }
    }
    return SecurityActivityItem(
      id: (json['id'] as num?)?.toInt() ?? 0,
      eventType: json['event_type'] as String? ?? 'unknown',
      ipAddress: json['ip_address'] as String?,
      userAgent: json['user_agent'] as String?,
      geoCountry: json['geo_country'] as String?,
      meta: meta,
      createdAt: json['created_at'] != null
          ? DateTime.tryParse(json['created_at'].toString())
          : null,
    );
  }
}

class SessionInfo {
  final int id;
  final String deviceName;
  final DateTime? lastActiveAt;
  final bool isCurrent;
  final bool isMobile;
  final String? ipAddress;

  SessionInfo({
    required this.id,
    required this.deviceName,
    this.lastActiveAt,
    this.isCurrent = false,
    this.isMobile = false,
    this.ipAddress,
  });

  factory SessionInfo.fromJson(Map<String, dynamic> json) {
    final ua = (json['device_name'] ?? json['user_agent'] ?? '').toString().toLowerCase();
    return SessionInfo(
      id: json['id'] is int ? json['id'] as int : int.tryParse(json['id'].toString()) ?? 0,
      deviceName: json['device_name'] as String? ?? json['user_agent'] as String? ?? 'Unknown device',
      lastActiveAt: json['last_active_at'] != null
          ? DateTime.tryParse(json['last_active_at'].toString())
          : null,
      isCurrent: json['is_current'] == true,
      isMobile: json['is_mobile'] == true ||
          ua.contains(RegExp(r'android|iphone|mobile').pattern),
      ipAddress: json['ip_address'] as String?,
    );
  }
}
