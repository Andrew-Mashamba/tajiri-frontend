// lib/reminders/services/reminders_dismissed_store.dart
// Local ids for aggregated reminders marked "Done" (no server is_done).
import 'dart:convert';

import 'package:flutter/foundation.dart';

import '../../services/local_storage_service.dart';

const String _kKey = 'reminder_aggregated_dismissed_ids_v1';

class RemindersDismissedStore {
  static Future<Set<String>> getAll() async {
    final s = await LocalStorageService.getInstance();
    final raw = s.getString(_kKey);
    if (raw == null || raw.isEmpty) return {};
    try {
      final decoded = jsonDecode(raw);
      if (decoded is List) {
        return decoded.map((e) => e.toString()).toSet();
      }
    } catch (e, st) {
      debugPrint('[RemindersDismissedStore] getAll parse: $e\n$st');
    }
    return {};
  }

  static Future<void> _save(Set<String> ids) async {
    final storage = await LocalStorageService.getInstance();
    await storage.setString(_kKey, jsonEncode(ids.toList()));
  }

  static Future<void> replaceAll(Set<String> ids) async => _save(ids);

  static Future<void> add(String id) async {
    final m = await getAll();
    if (m.add(id)) await _save(m);
  }

  static Future<void> remove(String id) async {
    final m = await getAll();
    if (m.remove(id)) await _save(m);
  }
}
