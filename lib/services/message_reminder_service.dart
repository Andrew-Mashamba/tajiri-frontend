import 'dart:convert';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:timezone/timezone.dart' as tz;
import 'package:timezone/data/latest.dart' as tz_data;

class MessageReminder {
  final int messageId;
  final int conversationId;
  final String messagePreview;
  final String senderName;
  final DateTime remindAt;
  final int notificationId;

  MessageReminder({
    required this.messageId,
    required this.conversationId,
    required this.messagePreview,
    required this.senderName,
    required this.remindAt,
    required this.notificationId,
  });

  Map<String, dynamic> toJson() => {
    'messageId': messageId,
    'conversationId': conversationId,
    'messagePreview': messagePreview,
    'senderName': senderName,
    'remindAt': remindAt.toIso8601String(),
    'notificationId': notificationId,
  };

  factory MessageReminder.fromJson(Map<String, dynamic> json) => MessageReminder(
    messageId: json['messageId'] as int,
    conversationId: json['conversationId'] as int,
    messagePreview: json['messagePreview'] as String,
    senderName: json['senderName'] as String,
    remindAt: DateTime.parse(json['remindAt'] as String),
    notificationId: json['notificationId'] as int,
  );
}

class MessageReminderService {
  static const String _storageKey = 'message_reminders';
  static final FlutterLocalNotificationsPlugin _notifications =
      FlutterLocalNotificationsPlugin();

  static Future<void> init() async {
    tz_data.initializeTimeZones();
  }

  /// Schedule a reminder notification for a message.
  static Future<void> scheduleReminder({
    required int messageId,
    required int conversationId,
    required String messagePreview,
    required String senderName,
    required DateTime remindAt,
  }) async {
    final notificationId = messageId.hashCode;

    // Schedule local notification via zonedSchedule for reliability.
    await _notifications.zonedSchedule(
      notificationId,
      'Kikumbusho: $senderName',
      messagePreview.length > 100
          ? '${messagePreview.substring(0, 100)}...'
          : messagePreview,
      tz.TZDateTime.from(remindAt, tz.local),
      NotificationDetails(
        android: AndroidNotificationDetails(
          'reminders',
          'Vikumbusho',
          channelDescription: 'Vikumbusho vya ujumbe',
          importance: Importance.high,
          priority: Priority.high,
        ),
        iOS: const DarwinNotificationDetails(
          presentAlert: true,
          presentSound: true,
        ),
      ),
      androidScheduleMode: AndroidScheduleMode.inexactAllowWhileIdle,
      uiLocalNotificationDateInterpretation:
          UILocalNotificationDateInterpretation.absoluteTime,
      payload: jsonEncode({
        'type': 'message_reminder',
        'conversationId': conversationId,
        'messageId': messageId,
      }),
    );

    // Persist to local storage.
    final reminder = MessageReminder(
      messageId: messageId,
      conversationId: conversationId,
      messagePreview: messagePreview,
      senderName: senderName,
      remindAt: remindAt,
      notificationId: notificationId,
    );

    final prefs = await SharedPreferences.getInstance();
    final existing = prefs.getStringList(_storageKey) ?? [];
    existing.add(jsonEncode(reminder.toJson()));
    await prefs.setStringList(_storageKey, existing);
  }

  /// Cancel a previously scheduled reminder.
  static Future<void> cancelReminder(int messageId) async {
    final notificationId = messageId.hashCode;
    await _notifications.cancel(notificationId);

    final prefs = await SharedPreferences.getInstance();
    final existing = prefs.getStringList(_storageKey) ?? [];
    existing.removeWhere((s) {
      try {
        final json = jsonDecode(s) as Map<String, dynamic>;
        return json['messageId'] == messageId;
      } catch (_) {
        return false;
      }
    });
    await prefs.setStringList(_storageKey, existing);
  }

  /// Get all active (future) reminders, cleaning up expired ones.
  static Future<List<MessageReminder>> getReminders() async {
    final prefs = await SharedPreferences.getInstance();
    final stored = prefs.getStringList(_storageKey) ?? [];
    final now = DateTime.now();
    final reminders = <MessageReminder>[];
    final active = <String>[];

    for (final s in stored) {
      try {
        final json = jsonDecode(s) as Map<String, dynamic>;
        final reminder = MessageReminder.fromJson(json);
        if (reminder.remindAt.isAfter(now)) {
          reminders.add(reminder);
          active.add(s);
        }
      } catch (_) {}
    }

    // Clean up expired reminders.
    if (active.length != stored.length) {
      await prefs.setStringList(_storageKey, active);
    }

    return reminders;
  }
}
