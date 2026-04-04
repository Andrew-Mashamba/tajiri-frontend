import 'dart:convert';
import 'package:http/http.dart' as http;
import '../config/api_config.dart';
import '../models/notification_models.dart';
import 'local_storage_service.dart';

/// Service for fetching and managing notifications.
/// Static-method class — token resolved from LocalStorageService.
class NotificationService {
  /// Resolve auth token for the given userId.
  static String? _token() {
    return LocalStorageService.instanceSync?.getAuthToken();
  }

  /// GET /api/notifications?page=X
  static Future<NotificationListResult> getNotifications(
    int userId, {
    int page = 1,
  }) async {
    try {
      final token = _token();
      if (token == null) {
        return const NotificationListResult(
          notifications: [],
          unreadCount: 0,
          hasMore: false,
        );
      }
      final response = await http.get(
        Uri.parse('${ApiConfig.baseUrl}/notifications?page=$page'),
        headers: ApiConfig.authHeaders(token),
      );
      if (response.statusCode == 200) {
        final data = jsonDecode(response.body) as Map<String, dynamic>;
        return NotificationListResult.fromJson(data);
      }
      return const NotificationListResult(
        notifications: [],
        unreadCount: 0,
        hasMore: false,
      );
    } catch (e) {
      return const NotificationListResult(
        notifications: [],
        unreadCount: 0,
        hasMore: false,
      );
    }
  }

  /// POST /api/notifications/{id}/read
  static Future<bool> markRead(int notificationId, int userId) async {
    try {
      final token = _token();
      if (token == null) return false;
      final response = await http.post(
        Uri.parse('${ApiConfig.baseUrl}/notifications/$notificationId/read'),
        headers: ApiConfig.authHeaders(token),
      );
      return response.statusCode == 200;
    } catch (e) {
      return false;
    }
  }

  /// POST /api/notifications/mark-all-read
  static Future<bool> markAllRead(int userId) async {
    try {
      final token = _token();
      if (token == null) return false;
      final response = await http.post(
        Uri.parse('${ApiConfig.baseUrl}/notifications/mark-all-read'),
        headers: ApiConfig.authHeaders(token),
      );
      return response.statusCode == 200;
    } catch (e) {
      return false;
    }
  }

  /// GET /api/notifications/unread-count
  static Future<int> getUnreadCount(int userId) async {
    try {
      final token = _token();
      if (token == null) return 0;
      final response = await http.get(
        Uri.parse('${ApiConfig.baseUrl}/notifications/unread-count'),
        headers: ApiConfig.authHeaders(token),
      );
      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        if (data is Map<String, dynamic>) {
          return (data['count'] as int?) ??
              (data['unread_count'] as int?) ??
              0;
        }
        if (data is int) return data;
      }
      return 0;
    } catch (e) {
      return 0;
    }
  }

  /// DELETE /api/notifications/{id}
  static Future<bool> deleteNotification(
    int notificationId,
    int userId,
  ) async {
    try {
      final token = _token();
      if (token == null) return false;
      final response = await http.delete(
        Uri.parse('${ApiConfig.baseUrl}/notifications/$notificationId'),
        headers: ApiConfig.authHeaders(token),
      );
      return response.statusCode == 200;
    } catch (e) {
      return false;
    }
  }

  /// GET /api/notification-preferences
  static Future<NotificationPreferences?> getPreferences(int userId) async {
    try {
      final token = _token();
      if (token == null) return null;
      final response = await http.get(
        Uri.parse('${ApiConfig.baseUrl}/notification-preferences'),
        headers: ApiConfig.authHeaders(token),
      );
      if (response.statusCode == 200) {
        final data = jsonDecode(response.body) as Map<String, dynamic>;
        return NotificationPreferences.fromJson(
          data['data'] as Map<String, dynamic>? ?? data,
        );
      }
      return null;
    } catch (e) {
      return null;
    }
  }

  /// PATCH /api/notification-preferences
  static Future<bool> updatePreferences(
    int userId,
    Map<String, dynamic> updates,
  ) async {
    try {
      final token = _token();
      if (token == null) return false;
      final response = await http.patch(
        Uri.parse('${ApiConfig.baseUrl}/notification-preferences'),
        headers: ApiConfig.authHeaders(token),
        body: jsonEncode(updates),
      );
      return response.statusCode == 200;
    } catch (e) {
      return false;
    }
  }
}
