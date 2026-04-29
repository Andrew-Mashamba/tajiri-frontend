// lib/reminders/services/reminders_notification_schedule_store.dart
import 'package:hive_flutter/hive_flutter.dart';

/// Prevents immediate-type local notifications from being re-scheduled on every
/// [RemindersNotificationService.scheduleAll] run the same calendar day.
class RemindersNotificationScheduleStore {
  static const _boxName = 'reminder_notif_schedule';
  static Box<dynamic>? _box;

  static Future<Box<dynamic>> _ensure() async {
    if (_box != null && _box!.isOpen) return _box!;
    _box = await Hive.openBox<dynamic>(_boxName);
    return _box!;
  }

  static String _dayStr(DateTime d) =>
      '${d.year.toString().padLeft(4, '0')}-${d.month.toString().padLeft(2, '0')}-${d.day.toString().padLeft(2, '0')}';

  /// `true` if we should call [zonedSchedule] for this immediate item today.
  static Future<bool> shouldScheduleImmediate(String itemId) async {
    final box = await _ensure();
    final last = box.get(_key(itemId)) as String?;
    final today = _dayStr(DateTime.now());
    return last != today;
  }

  static Future<void> markImmediateScheduled(String itemId) async {
    final box = await _ensure();
    await box.put(_key(itemId), _dayStr(DateTime.now()));
  }

  static Future<void> pruneInactive(Set<String> activeItemIds) async {
    final box = await _ensure();
    final prefix = 'im_';
    for (final k in List<dynamic>.from(box.keys)) {
      if (k is! String || !k.startsWith(prefix)) continue;
      final id = k.substring(prefix.length);
      if (!activeItemIds.contains(id)) {
        await box.delete(k);
      }
    }
  }

  static Future<void> clearImmediateFor(String itemId) async {
    final box = await _ensure();
    await box.delete(_key(itemId));
  }

  static String _key(String itemId) => 'im_$itemId';
}
