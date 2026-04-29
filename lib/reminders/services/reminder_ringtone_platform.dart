// lib/reminders/services/reminder_ringtone_platform.dart
// Android: opens the system notification sound picker (RingtoneManager).
import 'dart:io';

import 'package:flutter/foundation.dart';
import 'package:flutter/services.dart';

/// Returns a `content://` URI string for the chosen notification sound, or null.
class ReminderRingtonePlatform {
  static const _channel = MethodChannel('tajiri.app/ringtone_picker');

  static Future<String?> pickNotificationSound({String? existingUri}) async {
    if (!Platform.isAndroid) return null;
    try {
      final r = await _channel.invokeMethod<String>(
        'pickNotificationSound',
        <String, dynamic>{
          if (existingUri != null && existingUri.isNotEmpty)
            'existing_uri': existingUri,
        },
      );
      return r;
    } catch (e, st) {
      debugPrint('[ReminderRingtonePlatform] $e\n$st');
      return null;
    }
  }
}
