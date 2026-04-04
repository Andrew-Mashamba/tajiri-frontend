// Notification models for the TAJIRI notification system.

import 'package:flutter/material.dart';

/// Helper to safely parse int from String or int
int _parseInt(dynamic value) {
  if (value == null) return 0;
  if (value is int) return value;
  if (value is String) return int.tryParse(value) ?? 0;
  return 0;
}

/// Helper to safely parse bool from dynamic
bool _parseBool(dynamic value, [bool defaultValue = false]) {
  if (value == null) return defaultValue;
  if (value is bool) return value;
  if (value is int) return value != 0;
  if (value is String) return value.toLowerCase() == 'true' || value == '1';
  return defaultValue;
}

/// A single notification from the backend.
class AppNotification {
  final int id;
  final String type;
  final String? title;
  final String? body;
  final Map<String, dynamic> data;
  final DateTime? readAt;
  final DateTime createdAt;

  const AppNotification({
    required this.id,
    required this.type,
    this.title,
    this.body,
    this.data = const {},
    this.readAt,
    required this.createdAt,
  });

  bool get isRead => readAt != null;

  /// Icon based on notification type.
  IconData get icon {
    switch (type) {
      case 'new_message':
        return Icons.chat_bubble_rounded;
      case 'call_incoming':
      case 'call_missed':
        return Icons.phone_rounded;
      case 'reaction':
      case 'like':
        return Icons.favorite_rounded;
      case 'comment':
        return Icons.comment_rounded;
      case 'follow':
        return Icons.person_add_rounded;
      case 'mention':
        return Icons.alternate_email_rounded;
      case 'share':
        return Icons.share_rounded;
      case 'group_invite':
      case 'group_update':
        return Icons.group_rounded;
      case 'payment':
      case 'wallet':
        return Icons.account_balance_wallet_rounded;
      case 'post':
        return Icons.article_rounded;
      case 'live':
        return Icons.videocam_rounded;
      case 'system':
        return Icons.info_rounded;
      default:
        return Icons.notifications_rounded;
    }
  }

  /// Color accent for the notification type icon.
  Color get iconColor {
    switch (type) {
      case 'new_message':
        return const Color(0xFF1A1A1A);
      case 'call_incoming':
      case 'call_missed':
        return const Color(0xFF4CAF50);
      case 'reaction':
      case 'like':
        return const Color(0xFFE53935);
      case 'comment':
        return const Color(0xFF1A1A1A);
      case 'follow':
        return const Color(0xFF1A1A1A);
      case 'mention':
        return const Color(0xFF1565C0);
      case 'share':
        return const Color(0xFF1A1A1A);
      case 'payment':
      case 'wallet':
        return const Color(0xFF2E7D32);
      default:
        return const Color(0xFF666666);
    }
  }

  factory AppNotification.fromJson(Map<String, dynamic> json) {
    return AppNotification(
      id: _parseInt(json['id']),
      type: json['type']?.toString() ?? 'system',
      title: json['title']?.toString(),
      body: json['body']?.toString(),
      data: json['data'] is Map<String, dynamic>
          ? json['data'] as Map<String, dynamic>
          : <String, dynamic>{},
      readAt: json['read_at'] != null
          ? DateTime.tryParse(json['read_at'].toString())
          : null,
      createdAt: json['created_at'] != null
          ? DateTime.tryParse(json['created_at'].toString()) ?? DateTime.now()
          : DateTime.now(),
    );
  }
}

/// Paginated list of notifications returned by the API.
class NotificationListResult {
  final List<AppNotification> notifications;
  final int unreadCount;
  final bool hasMore;

  const NotificationListResult({
    required this.notifications,
    required this.unreadCount,
    required this.hasMore,
  });

  factory NotificationListResult.fromJson(Map<String, dynamic> json) {
    final list = json['data'] as List<dynamic>? ??
        json['notifications'] as List<dynamic>? ??
        [];
    final notifications = list
        .map((e) => AppNotification.fromJson(e as Map<String, dynamic>))
        .toList();

    // Pagination: check for next_page_url (Laravel) or has_more flag
    final bool hasMore = json['next_page_url'] != null ||
        _parseBool(json['has_more']);

    final int unreadCount = _parseInt(json['unread_count']);

    return NotificationListResult(
      notifications: notifications,
      unreadCount: unreadCount,
      hasMore: hasMore,
    );
  }
}

/// User notification preferences.
class NotificationPreferences {
  bool messagesEnabled;
  bool groupsEnabled;
  bool callsEnabled;
  bool reactionsEnabled;
  bool mentionsEnabled;
  bool socialEnabled;
  bool systemEnabled;
  String? globalSound;
  bool globalVibrate;
  bool quietHoursEnabled;
  String? quietHoursStart;
  String? quietHoursEnd;

  NotificationPreferences({
    this.messagesEnabled = true,
    this.groupsEnabled = true,
    this.callsEnabled = true,
    this.reactionsEnabled = true,
    this.mentionsEnabled = true,
    this.socialEnabled = true,
    this.systemEnabled = true,
    this.globalSound,
    this.globalVibrate = true,
    this.quietHoursEnabled = false,
    this.quietHoursStart,
    this.quietHoursEnd,
  });

  factory NotificationPreferences.fromJson(Map<String, dynamic> json) {
    return NotificationPreferences(
      messagesEnabled: _parseBool(json['messages_enabled'], true),
      groupsEnabled: _parseBool(json['groups_enabled'], true),
      callsEnabled: _parseBool(json['calls_enabled'], true),
      reactionsEnabled: _parseBool(json['reactions_enabled'], true),
      mentionsEnabled: _parseBool(json['mentions_enabled'], true),
      socialEnabled: _parseBool(json['social_enabled'], true),
      systemEnabled: _parseBool(json['system_enabled'], true),
      globalSound: json['global_sound']?.toString(),
      globalVibrate: _parseBool(json['global_vibrate'], true),
      quietHoursEnabled: _parseBool(json['quiet_hours_enabled']),
      quietHoursStart: json['quiet_hours_start']?.toString(),
      quietHoursEnd: json['quiet_hours_end']?.toString(),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'messages_enabled': messagesEnabled,
      'groups_enabled': groupsEnabled,
      'calls_enabled': callsEnabled,
      'reactions_enabled': reactionsEnabled,
      'mentions_enabled': mentionsEnabled,
      'social_enabled': socialEnabled,
      'system_enabled': systemEnabled,
      'global_sound': globalSound,
      'global_vibrate': globalVibrate,
      'quiet_hours_enabled': quietHoursEnabled,
      'quiet_hours_start': quietHoursStart,
      'quiet_hours_end': quietHoursEnd,
    };
  }
}
