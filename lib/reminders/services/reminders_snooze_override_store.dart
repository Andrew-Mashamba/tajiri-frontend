// lib/reminders/services/reminders_snooze_override_store.dart
// Local due-at overrides for aggregated reminders (swipe snooze has no API row).
import 'dart:convert';

import '../../services/local_storage_service.dart';

const String _kKey = 'reminder_snooze_due_override_v1';

class RemindersSnoozeOverrideStore {
  static Future<Map<String, DateTime>> getAll() async {
    final s = await LocalStorageService.getInstance();
    final raw = s.getString(_kKey);
    if (raw == null || raw.isEmpty) return {};
    try {
      final decoded = jsonDecode(raw);
      if (decoded is! Map) return {};
      final out = <String, DateTime>{};
      decoded.forEach((k, v) {
        if (k is String) {
          final d = DateTime.tryParse(v?.toString() ?? '');
          if (d != null) out[k] = d;
        }
      });
      return out;
    } catch (_) {
      return {};
    }
  }

  static Future<void> _save(Map<String, DateTime> m) async {
    final storage = await LocalStorageService.getInstance();
    final encoded = jsonEncode(
      m.map((k, v) => MapEntry(k, v.toIso8601String())),
    );
    await storage.setString(_kKey, encoded);
  }

  static Future<void> replaceAll(Map<String, DateTime> m) async =>
      _save(Map<String, DateTime>.from(m));

  static Future<void> put(String id, DateTime dueAt) async {
    final m = await getAll();
    m[id] = dueAt;
    await _save(m);
  }

  static Future<void> remove(String id) async {
    final m = await getAll();
    if (m.remove(id) != null) await _save(m);
  }
}
