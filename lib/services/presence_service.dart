import 'dart:convert';
import 'package:http/http.dart' as http;
import '../config/api_config.dart';
import 'local_storage_service.dart';

class PresenceService {
  static String get _baseUrl => ApiConfig.baseUrl;

  /// Send a heartbeat to signal this user is online.
  /// Respects the user's online_status_visibility privacy preference:
  /// if set to 'nobody', the heartbeat is skipped so the backend does not
  /// mark the user as online.
  static Future<void> heartbeat(int userId) async {
    try {
      // Check if user has opted out of showing online status
      final storage = await LocalStorageService.getInstance();
      final onlineVisibility = storage.getString('privacy_online_status_visibility');
      if (onlineVisibility == 'nobody') return;

      final token = storage.getAuthToken();
      await http.post(
        Uri.parse('$_baseUrl/presence/heartbeat'),
        headers: token != null ? ApiConfig.authHeaders(token) : ApiConfig.headers,
        body: jsonEncode({'user_id': userId}),
      );
    } catch (_) {}
  }

  static Future<PresenceInfo?> getPresence(int userId) async {
    try {
      final storage = await LocalStorageService.getInstance();
      final token = storage.getAuthToken();
      final resp = await http.get(
        Uri.parse('$_baseUrl/presence/$userId'),
        headers: token != null ? ApiConfig.authHeaders(token) : ApiConfig.headers,
      );
      if (resp.statusCode == 200) {
        final data = jsonDecode(resp.body);
        return PresenceInfo(
          isOnline: data['is_online'] == true,
          lastSeenAt: data['last_seen_at'] != null
              ? DateTime.tryParse(data['last_seen_at'].toString()) : null,
        );
      }
    } catch (_) {}
    return null;
  }

  static Future<Map<int, PresenceInfo>> batchPresence(List<int> userIds) async {
    if (userIds.isEmpty) return {};
    try {
      final storage = await LocalStorageService.getInstance();
      final token = storage.getAuthToken();
      final resp = await http.post(
        Uri.parse('$_baseUrl/presence/batch'),
        headers: token != null ? ApiConfig.authHeaders(token) : ApiConfig.headers,
        body: jsonEncode({'user_ids': userIds}),
      );
      if (resp.statusCode == 200) {
        final data = jsonDecode(resp.body);
        final presences = data['presences'] as Map<String, dynamic>? ?? {};
        return presences.map((k, v) => MapEntry(
          int.parse(k),
          PresenceInfo(
            isOnline: v['is_online'] == true,
            lastSeenAt: v['last_seen_at'] != null
                ? DateTime.tryParse(v['last_seen_at'].toString()) : null,
          ),
        ));
      }
    } catch (_) {}
    return {};
  }

  /// Cache the online status visibility setting locally so heartbeat can
  /// check it synchronously without a network call.
  static Future<void> cacheOnlineStatusVisibility(String visibility) async {
    final storage = await LocalStorageService.getInstance();
    await storage.setString('privacy_online_status_visibility', visibility);
  }
}

class PresenceInfo {
  final bool isOnline;
  final DateTime? lastSeenAt;
  const PresenceInfo({required this.isOnline, this.lastSeenAt});

  String get lastSeenLabel {
    if (isOnline) return 'Online';
    if (lastSeenAt == null) return '';
    final diff = DateTime.now().difference(lastSeenAt!);
    if (diff.inMinutes < 1) return 'Last seen just now';
    if (diff.inMinutes < 60) return 'Last seen ${diff.inMinutes}m ago';
    if (diff.inHours < 24) return 'Last seen ${diff.inHours}h ago';
    if (diff.inDays < 7) return 'Last seen ${diff.inDays}d ago';
    return 'Last seen ${lastSeenAt!.day}/${lastSeenAt!.month}';
  }
}
