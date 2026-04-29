// lib/reminders/services/reminder_detail_prefs.dart
// Local-only preferences per reminder id (sound, default snooze) — not synced to Tajiri API.
import 'dart:convert';

import '../../services/local_storage_service.dart';

const String _kPrefsKey = 'reminder_detail_prefs_v1';

bool _parseBoolPref(dynamic v, [bool fallback = true]) {
  if (v is bool) return v;
  if (v is int) return v != 0;
  if (v is String) return v == '1' || v == 'true';
  return fallback;
}

class ReminderDetailPrefs {
  /// `default` | `silent` | `system` (Android: [androidSoundUri] holds `content://` from RingtoneManager).
  final String sound;
  final int defaultSnoozeMinutes;

  /// Android notification sound URI from the system picker; ignored unless [sound] == `system`.
  final String? androidSoundUri;

  /// When `false`, local Vikumbusho schedules are skipped for this id (reminder may still appear in the list).
  final bool notificationsEnabled;

  const ReminderDetailPrefs({
    this.sound = 'default',
    this.defaultSnoozeMinutes = 15,
    this.androidSoundUri,
    this.notificationsEnabled = true,
  });

  Map<String, dynamic> toJson() => {
        'sound': sound,
        'snooze_minutes': defaultSnoozeMinutes,
        if (androidSoundUri != null && androidSoundUri!.isNotEmpty)
          'android_sound_uri': androidSoundUri,
        if (!notificationsEnabled) 'notifications_enabled': 0,
      };

  factory ReminderDetailPrefs.fromJson(Map<String, dynamic> json) {
    var s = json['sound']?.toString() ?? 'default';
    final uri = json['android_sound_uri']?.toString();
    if (s == 'system' && (uri == null || uri.isEmpty)) {
      s = 'default';
    }
    final ne = json['notifications_enabled'];
    return ReminderDetailPrefs(
      sound: s,
      defaultSnoozeMinutes:
          int.tryParse(json['snooze_minutes']?.toString() ?? '') ?? 15,
      androidSoundUri: (uri != null && uri.isNotEmpty) ? uri : null,
      notificationsEnabled: ne == null ? true : _parseBoolPref(ne, true),
    );
  }
}

class ReminderDetailPrefsStore {
  static Future<Map<String, ReminderDetailPrefs>> _loadMap() async {
    final s = await LocalStorageService.getInstance();
    final raw = s.getString(_kPrefsKey);
    if (raw == null || raw.isEmpty) return {};
    try {
      final decoded = jsonDecode(raw);
      if (decoded is! Map) return {};
      final out = <String, ReminderDetailPrefs>{};
      decoded.forEach((k, v) {
        if (k is String && v is Map) {
          out[k] = ReminderDetailPrefs.fromJson(Map<String, dynamic>.from(v));
        }
      });
      return out;
    } catch (_) {
      return {};
    }
  }

  static Future<ReminderDetailPrefs?> get(String reminderId) async {
    final m = await _loadMap();
    return m[reminderId];
  }

  static Future<void> put(String reminderId, ReminderDetailPrefs prefs) async {
    final m = await _loadMap();
    m[reminderId] = prefs;
    final s = await LocalStorageService.getInstance();
    final encoded = jsonEncode(
      m.map((k, v) => MapEntry(k, v.toJson())),
    );
    await s.setString(_kPrefsKey, encoded);
  }

  static Future<void> remove(String reminderId) async {
    final m = await _loadMap();
    if (!m.containsKey(reminderId)) return;
    m.remove(reminderId);
    final s = await LocalStorageService.getInstance();
    final encoded = jsonEncode(
      m.map((k, v) => MapEntry(k, v.toJson())),
    );
    await s.setString(_kPrefsKey, encoded);
  }

  static Future<bool> notificationsEnabledFor(String reminderId) async {
    final p = await get(reminderId);
    if (p == null) return true;
    return p.notificationsEnabled;
  }

  /// Whether notifications for this id should play sound (false when silent).
  static Future<bool> playSoundFor(String reminderId) async {
    final p = await get(reminderId);
    return p?.sound != 'silent';
  }

  /// Android `content://` URI for [UriAndroidNotificationSound], or null for channel default.
  static Future<String?> androidNotificationSoundUri(String reminderId) async {
    final p = await get(reminderId);
    if (p == null || p.sound != 'system') return null;
    final u = p.androidSoundUri;
    if (u == null || u.isEmpty) return null;
    return u;
  }
}
