import 'dart:convert';
import 'package:http/http.dart' as http;
import '../config/api_config.dart';
import '../models/privacy_settings_model.dart';
import 'local_storage_service.dart';

String get _baseUrl => ApiConfig.baseUrl;

class PrivacyService {
  Future<String?> _token() async {
    final storage = await LocalStorageService.getInstance();
    return storage.getAuthToken();
  }

  Future<Map<String, String>> _headers() async {
    final t = await _token();
    return t != null ? ApiConfig.authHeaders(t) : ApiConfig.headers;
  }

  // ── Privacy preferences (the canonical settings doc) ──────────────────────

  Future<PrivacySettingsResult> getPrivacySettings(int userId) async {
    try {
      final r = await http.get(
        Uri.parse('$_baseUrl/users/$userId/privacy-settings'),
        headers: await _headers(),
      );
      if (r.statusCode == 200) {
        final body = jsonDecode(r.body);
        final data = (body is Map && body['data'] is Map)
            ? body['data'] as Map<String, dynamic>
            : (body is Map ? body.cast<String, dynamic>() : <String, dynamic>{});
        return PrivacySettingsResult(
          success: true,
          settings: PrivacySettings.fromJson(data),
        );
      }
      return PrivacySettingsResult(success: false, message: 'load_failed');
    } catch (_) {
      return PrivacySettingsResult(success: false, message: 'load_failed');
    }
  }

  /// PATCH a single field. Returns the authoritative server response.
  Future<PrivacySettings?> patch(int userId, Map<String, dynamic> patch) async {
    try {
      final r = await http.patch(
        Uri.parse('$_baseUrl/users/$userId/privacy-settings'),
        headers: {...await _headers(), 'Content-Type': 'application/json'},
        body: jsonEncode(patch),
      );
      if (r.statusCode >= 200 && r.statusCode < 300) {
        final body = jsonDecode(r.body) as Map<String, dynamic>;
        final data = (body['data'] as Map<String, dynamic>?) ?? const {};
        return PrivacySettings.fromJson(data);
      }
      return null;
    } catch (_) {
      return null;
    }
  }

  // ── Blocked users ─────────────────────────────────────────────────────────

  Future<List<BlockedUserItem>> blockedUsers(int userId) async {
    try {
      final r = await http.get(
        Uri.parse('$_baseUrl/users/blocked?user_id=$userId'),
        headers: await _headers(),
      );
      if (r.statusCode != 200) return [];
      final body = jsonDecode(r.body) as Map<String, dynamic>;
      final list = (body['data'] as List?) ?? const [];
      return list
          .whereType<Map>()
          .map((m) => BlockedUserItem.fromJson(m.cast<String, dynamic>()))
          .toList();
    } catch (_) {
      return [];
    }
  }

  Future<bool> unblock(int userId, int blockedUserId) async {
    try {
      final r = await http.post(
        Uri.parse('$_baseUrl/users/unblock'),
        headers: {...await _headers(), 'Content-Type': 'application/json'},
        body: jsonEncode({'user_id': userId, 'blocked_user_id': blockedUserId}),
      );
      return r.statusCode == 200;
    } catch (_) {
      return false;
    }
  }

  // ── Close friends ─────────────────────────────────────────────────────────

  Future<List<CloseFriendItem>> closeFriends(int userId) async {
    try {
      final r = await http.get(
        Uri.parse('$_baseUrl/users/$userId/close-friends'),
        headers: await _headers(),
      );
      if (r.statusCode != 200) return [];
      final body = jsonDecode(r.body) as Map<String, dynamic>;
      final list = (body['data'] as List?) ?? const [];
      return list
          .whereType<Map>()
          .map((m) => CloseFriendItem.fromJson(m.cast<String, dynamic>()))
          .toList();
    } catch (_) {
      return [];
    }
  }

  Future<bool> addCloseFriend(int userId, int friendId) async {
    try {
      final r = await http.post(
        Uri.parse('$_baseUrl/users/$userId/close-friends'),
        headers: {...await _headers(), 'Content-Type': 'application/json'},
        body: jsonEncode({'friend_id': friendId}),
      );
      return r.statusCode == 200;
    } catch (_) {
      return false;
    }
  }

  Future<bool> removeCloseFriend(int userId, int friendId) async {
    try {
      final r = await http.delete(
        Uri.parse('$_baseUrl/users/$userId/close-friends/$friendId'),
        headers: await _headers(),
      );
      return r.statusCode == 200;
    } catch (_) {
      return false;
    }
  }

  // ── Face-data consent ─────────────────────────────────────────────────────

  Future<int> setFaceConsent(int userId, bool consented) async {
    try {
      final r = await http.post(
        Uri.parse('$_baseUrl/users/$userId/face-consent'),
        headers: {...await _headers(), 'Content-Type': 'application/json'},
        body: jsonEncode({'consented': consented}),
      );
      if (r.statusCode != 200) return -1;
      final body = jsonDecode(r.body) as Map<String, dynamic>;
      return ((body['data'] as Map?)?['embeddings_purged'] as num?)?.toInt() ?? 0;
    } catch (_) {
      return -1;
    }
  }

  // ── Data export (returns raw JSON bundle as string for client to save) ───

  Future<String?> dataExportJson(int userId) async {
    try {
      final r = await http.get(
        Uri.parse('$_baseUrl/users/$userId/data-export'),
        headers: await _headers(),
      );
      if (r.statusCode == 200) return r.body;
      return null;
    } catch (_) {
      return null;
    }
  }

  // ── Account deletion ──────────────────────────────────────────────────────

  Future<bool> requestDeletion(int userId) async {
    try {
      final r = await http.delete(
        Uri.parse('$_baseUrl/users/$userId/data'),
        headers: {...await _headers(), 'Content-Type': 'application/json'},
        body: jsonEncode({'user_id': userId}),
      );
      return r.statusCode >= 200 && r.statusCode < 300;
    } catch (_) {
      return false;
    }
  }
}

class PrivacySettingsResult {
  final bool success;
  final PrivacySettings? settings;
  final String? message;
  PrivacySettingsResult({required this.success, this.settings, this.message});
}

class BlockedUserItem {
  final int blockedUserId;
  final String? firstName;
  final String? lastName;
  final String? username;
  final String? avatarPath;
  BlockedUserItem({
    required this.blockedUserId,
    this.firstName,
    this.lastName,
    this.username,
    this.avatarPath,
  });
  factory BlockedUserItem.fromJson(Map<String, dynamic> json) {
    final user = (json['user'] as Map?)?.cast<String, dynamic>();
    return BlockedUserItem(
      blockedUserId: (json['blocked_user_id'] as num?)?.toInt() ?? 0,
      firstName: user?['first_name'] as String?,
      lastName: user?['last_name'] as String?,
      username: user?['username'] as String?,
      avatarPath: user?['profile_photo_path'] as String?,
    );
  }
  String get displayName {
    final f = (firstName ?? '').trim();
    final l = (lastName ?? '').trim();
    final n = '$f $l'.trim();
    if (n.isNotEmpty) return n;
    return username ?? 'Unknown';
  }
}

class CloseFriendItem {
  final int friendId;
  final String? firstName;
  final String? lastName;
  final String? username;
  final String? avatarPath;
  CloseFriendItem({
    required this.friendId,
    this.firstName,
    this.lastName,
    this.username,
    this.avatarPath,
  });
  factory CloseFriendItem.fromJson(Map<String, dynamic> json) {
    final user = (json['user'] as Map?)?.cast<String, dynamic>();
    return CloseFriendItem(
      friendId: (json['friend_id'] as num?)?.toInt() ?? 0,
      firstName: user?['first_name'] as String?,
      lastName: user?['last_name'] as String?,
      username: user?['username'] as String?,
      avatarPath: user?['profile_photo_path'] as String?,
    );
  }
  String get displayName {
    final f = (firstName ?? '').trim();
    final l = (lastName ?? '').trim();
    final n = '$f $l'.trim();
    if (n.isNotEmpty) return n;
    return username ?? 'Unknown';
  }
}
