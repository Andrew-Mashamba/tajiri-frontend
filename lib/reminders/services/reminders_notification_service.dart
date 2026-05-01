// lib/reminders/services/reminders_notification_service.dart
import 'dart:convert';

import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:timezone/data/latest.dart' as tz_data;
import 'package:timezone/timezone.dart' as tz;

import '../../services/local_storage_service.dart';
import '../models/reminder_event_kind.dart';
import '../models/reminder_models.dart';
import '../reminders_module.dart';
import 'reminders_notification_schedule_store.dart';
import 'reminder_detail_prefs.dart';
import 'reminders_dismissed_store.dart';
import 'reminders_snooze_override_store.dart';

class RemindersNotificationService {
  static final FlutterLocalNotificationsPlugin _plugin =
      FlutterLocalNotificationsPlugin();
  static bool _initialized = false;
  static bool _coldStartReminderHandled = false;

  static const _channelId = 'reminders';
  /// English default — shown in system notification settings (matches app language policy).
  static const _channelName = 'Reminders';
  static const _channelDesc = 'Business and calendar reminders';

  /// Android only — must match [cancel] / pending teardown or the OS keeps the notification.
  static const String _androidTag = 'tajiri_vik';

  /// Default daily nag time for overdue invoice/debt (local wall clock).
  static const int _overdueHour = 8;
  static const int _overdueMinute = 0;

  /// Timezone + Android channel only. Does **not** call [FlutterLocalNotificationsPlugin.initialize]
  /// — [FcmService] owns the singleton plugin init and notification tap routing.
  static Future<void> init() async {
    if (_initialized) return;
    tz_data.initializeTimeZones();
    try {
      tz.setLocalLocation(tz.getLocation('Africa/Dar_es_Salaam'));
    } catch (e) {
      debugPrint('[RemindersNotificationService] setLocalLocation: $e');
    }
    if (!kIsWeb) {
      final android = _plugin.resolvePlatformSpecificImplementation<
          AndroidFlutterLocalNotificationsPlugin>();
      const channel = AndroidNotificationChannel(
        _channelId,
        _channelName,
        description: _channelDesc,
        importance: Importance.high,
        playSound: true,
      );
      await android?.createNotificationChannel(channel);
    }
    _initialized = true;
  }

  /// Schedule notifications for a list of items.
  /// Cancels **only** pending requests whose payload is a Vikumbusho reminder
  /// (`type: reminder`) — the plugin is shared with chat, FCM, and other features.
  static Future<void> scheduleAll(List<ReminderItem> items) async {
    await init();
    final storage = await LocalStorageService.getInstance();
    final useSwahili =
        storage.getLanguageCode().toLowerCase().startsWith('sw');
    String categoryTitle(ReminderCategory c) => c.labelForLocale(swahili: useSwahili);

    final pending = await _plugin.pendingNotificationRequests();
    final reminderPendingIds = pending
        .where((r) => _isReminderPayload(r.payload))
        .map((r) => r.id)
        .toSet();
    final newIds = <int>{};
    final activeIds = <String>{};
    final dismissedAggregated = await RemindersDismissedStore.getAll();
    final snoozeOverrides = await RemindersSnoozeOverrideStore.getAll();
    final effectiveItems = items.map((i) {
      final o = snoozeOverrides[i.id];
      if (o != null) return i.copyWith(dueAt: o);
      return i;
    }).toList();

    for (final item in effectiveItems) {
      if (item.isDone) continue;
      if (!item.isStandalone && dismissedAggregated.contains(item.id)) {
        continue;
      }
      if (!await ReminderDetailPrefsStore.notificationsEnabledFor(item.id)) {
        continue;
      }
      activeIds.add(item.id);

      final playSound = await ReminderDetailPrefsStore.playSoundFor(item.id);
      final androidSoundUri = !kIsWeb &&
              defaultTargetPlatform == TargetPlatform.android
          ? await ReminderDetailPrefsStore.androidNotificationSoundUri(item.id)
          : null;
      final kind = _effectiveEventKind(item);

      // Overdue invoices/debts: daily at fixed morning time until marked done.
      if (kind == ReminderEventKind.invoiceOverdue ||
          kind == ReminderEventKind.debtOverdue) {
        final first = _nextDailyAtHour(_overdueHour, _overdueMinute);
        final notifId = _notifId(item.id, 0);
        newIds.add(notifId);
        await _scheduleOne(
          id: notifId,
          title: categoryTitle(item.category),
          body: item.title,
          fireAt: first,
          payload: _payloadFor(item.id),
          matchDateTimeComponents: DateTimeComponents.time,
          playSound: playSound,
          androidSoundUri: androidSoundUri,
        );
        continue;
      }

      // One-shot “as soon as sensible” (status changes, confirmations, failures).
      if (_isImmediateKind(kind)) {
        final notifId = _notifId(item.id, 0);
        final shouldFire =
            await RemindersNotificationScheduleStore.shouldScheduleImmediate(
                item.id);
        if (!shouldFire) {
          newIds.add(notifId);
          continue;
        }
        final fire = _immediateFireTime(item.dueAt);
        newIds.add(notifId);
        await _scheduleOne(
          id: notifId,
          title: categoryTitle(item.category),
          body: item.title,
          fireAt: fire,
          payload: _payloadFor(item.id),
          playSound: playSound,
          androidSoundUri: androidSoundUri,
        );
        await RemindersNotificationScheduleStore.markImmediateScheduled(item.id);
        continue;
      }

      // User-defined repeat on standalone rows.
      if (item.repeat != ReminderRepeat.none) {
        final first = _nextRepeatFire(item.dueAt, item.repeat);
        if (first == null || !first.isAfter(DateTime.now())) continue;
        final match = _matchComponents(item.repeat);
        if (match == null) continue;
        final notifId = _notifId(item.id, 0);
        newIds.add(notifId);
        await _scheduleOne(
          id: notifId,
          title: categoryTitle(item.category),
          body: item.title,
          fireAt: first,
          payload: _payloadFor(item.id),
          matchDateTimeComponents: match,
          playSound: playSound,
          androidSoundUri: androidSoundUri,
        );
        continue;
      }

      final fireTimes = _leadTimesFor(item, kindOverride: kind);
      for (var i = 0; i < fireTimes.length; i++) {
        final fireTime = fireTimes[i];
        if (fireTime.isBefore(DateTime.now())) continue;
        final notifId = _notifId(item.id, i);
        newIds.add(notifId);
        await _scheduleOne(
          id: notifId,
          title: categoryTitle(item.category),
          body: item.title,
          fireAt: fireTime,
          payload: _payloadFor(item.id),
          playSound: playSound,
          androidSoundUri: androidSoundUri,
        );
      }
    }

    for (final oldId in reminderPendingIds.difference(newIds)) {
      await _cancelScheduledId(oldId);
    }
    await RemindersNotificationScheduleStore.pruneInactive(activeIds);
    await _cancelOrphanShownVikumbusho(newIds);
  }

  static bool _isReminderPayload(String? payload) {
    if (payload == null || payload.isEmpty) return false;
    try {
      final m = jsonDecode(payload);
      if (m is Map) {
        if (m['vik'] == 1 || m['vik'] == true) return true;
        if (m['type'] == 'reminder') return true;
      }
    } catch (_) {
      // ignore
    }
    return payload.contains('"type"') &&
        payload.contains('reminder') &&
        payload.contains('id');
  }

  static String _payloadFor(String itemId) =>
      jsonEncode({'type': 'reminder', 'id': itemId, 'vik': 1});

  static Future<void> _cancelScheduledId(int id) async {
    if (kIsWeb) return;
    if (defaultTargetPlatform == TargetPlatform.android) {
      await _plugin.cancel(id, tag: _androidTag);
    } else {
      await _plugin.cancel(id);
    }
  }

  /// Drops stale **shown** Vikumbusho notifications (Android) whose ids are
  /// no longer scheduled — [message_reminders] and other channels untouched.
  static Future<void> _cancelOrphanShownVikumbusho(Set<int> scheduledIds) async {
    if (kIsWeb) return;
    try {
      final active = await _plugin.getActiveNotifications();
      for (final n in active) {
        if (n.channelId != _channelId) continue;
        if (!_isReminderPayload(n.payload)) continue;
        final pid = n.id;
        if (pid != null && !scheduledIds.contains(pid)) {
          if (defaultTargetPlatform == TargetPlatform.android) {
            await _plugin.cancel(pid, tag: n.tag ?? _androidTag);
          } else {
            await _plugin.cancel(pid);
          }
        }
      }
    } catch (e) {
      debugPrint('[RemindersNotificationService] orphan active cleanup: $e');
    }
  }

  /// When the OS launched the app from a Vikumbusho local notification (killed state).
  /// Call once after the root navigator exists (e.g. first frame of [HomeScreen]).
  static Future<void> handleColdStartReminderIfAny(
      NavigatorState navigator) async {
    if (_coldStartReminderHandled) return;
    await init();
    try {
      final details = await _plugin.getNotificationAppLaunchDetails();
      if (details?.didNotificationLaunchApp != true) return;
      final p = details!.notificationResponse?.payload;
      if (!_isReminderPayload(p)) return;
      _coldStartReminderHandled = true;
      final storage = await LocalStorageService.getInstance();
      final uid = storage.getUser()?.userId ?? 0;
      if (uid <= 0 || !navigator.mounted) return;
      navigator.push(MaterialPageRoute<void>(
        builder: (_) => RemindersModule(userId: uid),
      ));
    } catch (e) {
      debugPrint('[RemindersNotificationService] cold start: $e');
    }
  }

  /// API [event_kind] if set; else inferred for aggregated invoice/debt rows.
  static String? _effectiveEventKind(ReminderItem item) {
    if (item.eventKind != null && item.eventKind!.isNotEmpty) {
      return item.eventKind;
    }
    if (item.isStandalone) return null;
    return _inferAggregatedEventKind(item);
  }

  /// When adapters omit [eventKind], still route invoice/debt by calendar due date.
  static String? _inferAggregatedEventKind(ReminderItem item) {
    switch (item.category) {
      case ReminderCategory.invoice:
        return _inferInvoiceDebtKind(isInvoice: true, dueAt: item.dueAt);
      case ReminderCategory.debt:
        return _inferInvoiceDebtKind(isInvoice: false, dueAt: item.dueAt);
      default:
        return null;
    }
  }

  static String _inferInvoiceDebtKind(
      {required bool isInvoice, required DateTime dueAt}) {
    final now = DateTime.now();
    final today = DateTime(now.year, now.month, now.day);
    final dueDay = DateTime(dueAt.year, dueAt.month, dueAt.day);
    if (dueDay.isBefore(today)) {
      return isInvoice
          ? ReminderEventKind.invoiceOverdue
          : ReminderEventKind.debtOverdue;
    }
    if (dueDay == today && _isEndOfDueDayOverdue(dueAt, now)) {
      return isInvoice
          ? ReminderEventKind.invoiceOverdue
          : ReminderEventKind.debtOverdue;
    }
    return isInvoice
        ? ReminderEventKind.invoiceUpcoming
        : ReminderEventKind.debtUpcoming;
  }

  /// Date-only due times: treat as overdue after 17:00 local; clock times: after [dueAt].
  static bool _isEndOfDueDayOverdue(DateTime due, DateTime now) {
    final hasTime = due.hour != 0 ||
        due.minute != 0 ||
        due.second != 0 ||
        due.millisecond != 0;
    if (hasTime) return now.isAfter(due);
    return now.hour >= 17;
  }

  static bool _isImmediateKind(String? kind) {
    if (kind == null || kind.isEmpty) return false;
    return kind == ReminderEventKind.immediate ||
        kind == ReminderEventKind.quoteStatus ||
        kind == ReminderEventKind.invoicePaid ||
        kind == ReminderEventKind.poStatus ||
        kind == ReminderEventKind.tenderOutcome ||
        kind == ReminderEventKind.failedTransaction ||
        kind == ReminderEventKind.crbPastDue;
  }

  static DateTime _immediateFireTime(DateTime dueAt) {
    final now = DateTime.now();
    if (dueAt.isAfter(now)) return dueAt;
    return now.add(const Duration(seconds: 45));
  }

  static DateTime _nextDailyAtHour(int hour, int minute) {
    final now = DateTime.now();
    var c = DateTime(now.year, now.month, now.day, hour, minute);
    if (!c.isAfter(now)) {
      c = c.add(const Duration(days: 1));
    }
    return c;
  }

  static Future<void> cancel(String itemId) async {
    await init();
    const maxSlots = 8;
    for (var i = 0; i < maxSlots; i++) {
      await _cancelScheduledId(_notifId(itemId, i));
    }
    await RemindersNotificationScheduleStore.clearImmediateFor(itemId);
  }

  /// Lead times: [event_kind] when set, else [ReminderCategory].
  static List<DateTime> _leadTimesFor(ReminderItem item,
      {String? kindOverride}) {
    final due = item.dueAt;
    final k = kindOverride ?? item.eventKind;
    if (k != null && k.isNotEmpty) {
      switch (k) {
        case ReminderEventKind.documentExpiry:
        case ReminderEventKind.taxDeadline:
          return [
            due.subtract(const Duration(days: 30)),
            due.subtract(const Duration(days: 7)),
            due.subtract(const Duration(days: 1)),
          ];
        case ReminderEventKind.quoteValidUntil:
          return [
            due.subtract(const Duration(days: 3)),
            due.subtract(const Duration(days: 1)),
          ];
        case ReminderEventKind.invoiceUpcoming:
        case ReminderEventKind.debtUpcoming:
          return [
            due.subtract(const Duration(days: 7)),
            due.subtract(const Duration(days: 3)),
            due.subtract(const Duration(days: 1)),
          ];
        case ReminderEventKind.tenderClosing:
        case ReminderEventKind.tenderApplication:
          return [
            due.subtract(const Duration(days: 7)),
            due.subtract(const Duration(days: 3)),
            due.subtract(const Duration(days: 1)),
          ];
        case ReminderEventKind.employeeContract:
          return [
            due.subtract(const Duration(days: 30)),
            due.subtract(const Duration(days: 7)),
          ];
        case ReminderEventKind.appointmentUpcoming:
          return [
            due.subtract(const Duration(hours: 24)),
            due.subtract(const Duration(hours: 1)),
          ];
        case ReminderEventKind.recurringExpense:
        case ReminderEventKind.recurringInvoiceDue:
        case ReminderEventKind.poDelivery:
          return [due.subtract(const Duration(days: 1))];
        case ReminderEventKind.payrollDraft:
        case ReminderEventKind.payrollUnpaid:
        case ReminderEventKind.revenueDigest:
        case ReminderEventKind.calendarEvent:
          return [due];
        default:
          break;
      }
    }
    return _categoryLeadTimes(item);
  }

  static List<DateTime> _categoryLeadTimes(ReminderItem item) {
    final due = item.dueAt;
    switch (item.category) {
      case ReminderCategory.document:
      case ReminderCategory.tax:
        return [
          due.subtract(const Duration(days: 30)),
          due.subtract(const Duration(days: 7)),
          due.subtract(const Duration(days: 1)),
        ];
      case ReminderCategory.invoice:
      case ReminderCategory.debt:
        return [
          due.subtract(const Duration(days: 7)),
          due.subtract(const Duration(days: 3)),
          due.subtract(const Duration(days: 1)),
        ];
      case ReminderCategory.quote:
        return [
          due.subtract(const Duration(days: 3)),
          due.subtract(const Duration(days: 1)),
        ];
      case ReminderCategory.tender:
        return [
          due.subtract(const Duration(days: 7)),
          due.subtract(const Duration(days: 3)),
          due.subtract(const Duration(days: 1)),
        ];
      case ReminderCategory.employee:
        return [
          due.subtract(const Duration(days: 30)),
          due.subtract(const Duration(days: 7)),
        ];
      case ReminderCategory.appointment:
        return [
          due.subtract(const Duration(hours: 24)),
          due.subtract(const Duration(hours: 1)),
        ];
      case ReminderCategory.purchaseOrder:
      case ReminderCategory.recurring:
      case ReminderCategory.expense:
        return [due.subtract(const Duration(days: 1))];
      case ReminderCategory.payroll:
      case ReminderCategory.transaction:
      case ReminderCategory.credit:
      case ReminderCategory.revenue:
      case ReminderCategory.calendar:
      case ReminderCategory.general:
        return [due];
    }
  }

  static DateTimeComponents? _matchComponents(ReminderRepeat r) {
    switch (r) {
      case ReminderRepeat.none:
        return null;
      case ReminderRepeat.daily:
        return DateTimeComponents.time;
      case ReminderRepeat.weekly:
        return DateTimeComponents.dayOfWeekAndTime;
      case ReminderRepeat.monthly:
        return DateTimeComponents.dayOfMonthAndTime;
      case ReminderRepeat.yearly:
        return DateTimeComponents.dateAndTime;
    }
  }

  /// Next local wall-clock fire time for a repeating reminder (for [zonedSchedule] anchor).
  static DateTime? _nextRepeatFire(DateTime due, ReminderRepeat repeat) {
    switch (repeat) {
      case ReminderRepeat.none:
        return null;
      case ReminderRepeat.daily:
        return _nextDailySameTime(due);
      case ReminderRepeat.weekly:
        return _nextWeeklySameWeekday(due);
      case ReminderRepeat.monthly:
        return _nextMonthlySameDay(due);
      case ReminderRepeat.yearly:
        return _nextYearlySameDate(due);
    }
  }

  static DateTime _nextDailySameTime(DateTime due) {
    final now = DateTime.now();
    var candidate = DateTime(now.year, now.month, now.day, due.hour, due.minute,
        due.second, due.millisecond, due.microsecond);
    if (!candidate.isAfter(now)) {
      candidate = candidate.add(const Duration(days: 1));
    }
    return candidate;
  }

  static DateTime _nextWeeklySameWeekday(DateTime due) {
    final now = DateTime.now();
    for (var i = 0; i < 14; i++) {
      final d = now.add(Duration(days: i));
      if (d.weekday != due.weekday) continue;
      final candidate = DateTime(d.year, d.month, d.day, due.hour, due.minute,
          due.second, due.millisecond, due.microsecond);
      if (candidate.isAfter(now)) return candidate;
    }
    final d = now.add(const Duration(days: 14));
    return DateTime(d.year, d.month, d.day, due.hour, due.minute, due.second,
        due.millisecond, due.microsecond);
  }

  static DateTime _nextMonthlySameDay(DateTime due) {
    final now = DateTime.now();
    var y = now.year;
    var m = now.month;
    var day = due.day;
    var lastDay = DateTime(y, m + 1, 0).day;
    if (day > lastDay) day = lastDay;
    var candidate = DateTime(y, m, day, due.hour, due.minute, due.second,
        due.millisecond, due.microsecond);
    if (!candidate.isAfter(now)) {
      m += 1;
      if (m > 12) {
        m = 1;
        y += 1;
      }
      lastDay = DateTime(y, m + 1, 0).day;
      day = due.day;
      if (day > lastDay) day = lastDay;
      candidate = DateTime(y, m, day, due.hour, due.minute, due.second,
          due.millisecond, due.microsecond);
    }
    return candidate;
  }

  static DateTime _nextYearlySameDate(DateTime due) {
    final now = DateTime.now();
    var lastDay = DateTime(now.year, due.month + 1, 0).day;
    var day = due.day;
    if (day > lastDay) day = lastDay;
    var candidate = DateTime(now.year, due.month, day, due.hour, due.minute,
        due.second, due.millisecond, due.microsecond);
    if (!candidate.isAfter(now)) {
      final y = now.year + 1;
      lastDay = DateTime(y, due.month + 1, 0).day;
      day = due.day;
      if (day > lastDay) day = lastDay;
      candidate = DateTime(y, due.month, day, due.hour, due.minute, due.second,
          due.millisecond, due.microsecond);
    }
    return candidate;
  }

  static int _notifId(String itemId, int slot) =>
      '${itemId}_$slot'.hashCode.abs() % 2147483647;

  static Future<void> _scheduleOne({
    required int id,
    required String title,
    required String body,
    required DateTime fireAt,
    required String payload,
    DateTimeComponents? matchDateTimeComponents,
    bool playSound = true,
    String? androidSoundUri,
  }) async {
    try {
      final AndroidNotificationSound? androidSound =
          playSound && androidSoundUri != null && androidSoundUri.isNotEmpty
              ? UriAndroidNotificationSound(androidSoundUri)
              : null;
      await _plugin.zonedSchedule(
        id,
        title,
        body,
        tz.TZDateTime.from(fireAt, tz.local),
        NotificationDetails(
          android: AndroidNotificationDetails(
            _channelId,
            _channelName,
            channelDescription: _channelDesc,
            importance:
                playSound ? Importance.high : Importance.defaultImportance,
            priority: playSound ? Priority.high : Priority.low,
            playSound: playSound,
            enableVibration: playSound,
            tag: _androidTag,
            sound: androidSound,
          ),
          iOS: DarwinNotificationDetails(
            presentAlert: true,
            presentSound: playSound,
          ),
        ),
        androidScheduleMode: AndroidScheduleMode.inexactAllowWhileIdle,
        uiLocalNotificationDateInterpretation:
            UILocalNotificationDateInterpretation.absoluteTime,
        payload: payload,
        matchDateTimeComponents: matchDateTimeComponents,
      );
    } catch (e) {
      debugPrint('[RemindersNotificationService] schedule error: $e');
    }
  }
}
