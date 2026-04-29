// Local reminders for Skin Care — uses [FcmService] plugin so taps route like FCM.
import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:timezone/data/latest.dart' as tz_data;
import 'package:timezone/timezone.dart' as tz;

import '../../services/fcm_service.dart';
import 'skincare_cache_service.dart';

/// Notification IDs: `userId * 100 + slot` where slot 0–4.
class SkincareNotificationHelper {
  SkincareNotificationHelper._();

  static bool _tzInitialized = false;

  /// [tz.local] is only valid after [tz_data.initializeTimeZones]. Must run
  /// before [_nextDailyLocal] — not only inside [FcmService.scheduleSkincareZonedNotification].
  static void _ensureTz() {
    if (!_tzInitialized) {
      tz_data.initializeTimeZones();
      _tzInitialized = true;
    }
  }

  static int _nid(int userId, int slot) => userId * 100 + slot;

  static Future<void> cancelAllForUser(int userId) async {
    final fcm = FcmService.instance;
    for (var i = 0; i < 5; i++) {
      await fcm.cancelNotification(_nid(userId, i));
    }
  }

  /// Apply prefs: cancel old IDs then schedule enabled reminders.
  static Future<void> rescheduleForUser({
    required int userId,
    required SkincareReminderPrefs prefs,
    required bool isSwahili,
  }) async {
    _ensureTz();
    await cancelAllForUser(userId);
    final fcm = FcmService.instance;

    if (prefs.morningRoutine) {
      final next = _nextDailyLocal(prefs.morningHour, prefs.morningMinute);
      await fcm.scheduleSkincareZonedNotification(
        notificationId: _nid(userId, 0),
        title: isSwahili ? 'Routine ya asubuhi' : 'Morning routine',
        body: isSwahili
            ? 'Dakika 5 za ngozi — safisha na moisturizer.'
            : '5 min for your skin — cleanse and moisturize.',
        scheduledLocal: next,
        target: 'routine',
        match: DateTimeComponents.time,
      );
    }

    if (prefs.eveningRoutine) {
      final next = _nextDailyLocal(prefs.eveningHour, prefs.eveningMinute);
      await fcm.scheduleSkincareZonedNotification(
        notificationId: _nid(userId, 1),
        title: isSwahili ? 'Routine ya jioni' : 'Evening routine',
        body: isSwahili
            ? 'Jioni: umesafisha na uka moisturizer?'
            : 'Evening: did you cleanse and moisturize?',
        scheduledLocal: next,
        target: 'routine',
        match: DateTimeComponents.time,
      );
    }

    if (prefs.diaryNudge) {
      final next = _nextDailyLocal(prefs.diaryHour, prefs.diaryMinute);
      await fcm.scheduleSkincareZonedNotification(
        notificationId: _nid(userId, 2),
        title: isSwahili ? 'Diary ya ngozi' : 'Skin diary',
        body: isSwahili
            ? 'Ngozi yako leo? Andika kwa sekunde 10.'
            : 'How is your skin today? Log in 10 seconds.',
        scheduledLocal: next,
        target: 'diary',
        match: DateTimeComponents.time,
      );
    }

    if (prefs.weeklyDigest) {
      final next = _nextWeeklyLocal(
        prefs.weeklyDigestWeekday,
        prefs.weeklyDigestHour,
        prefs.weeklyDigestMinute,
      );
      await fcm.scheduleSkincareZonedNotification(
        notificationId: _nid(userId, 3),
        title: isSwahili ? 'Muhtasari wa wiki — ngozi' : 'Weekly skin summary',
        body: isSwahili
            ? 'Angalia diary, routine, na mwenendo wa wiki hii.'
            : 'Review your diary, routines, and trends this week.',
        scheduledLocal: next,
        target: 'home',
        match: DateTimeComponents.dayOfWeekAndTime,
      );
    }

    if (prefs.sunscreenReminder) {
      final sun = _nextDailyLocal(10, 30);
      await fcm.scheduleSkincareZonedNotification(
        notificationId: _nid(userId, 4),
        title: isSwahili ? 'SPF leo' : 'SPF today',
        body: isSwahili
            ? 'Hata panapokuwa na mawingu — tumia SPF 30+ kulingana na eneo lako.'
            : 'Even on cloudy days — use SPF 30+ for your climate.',
        scheduledLocal: sun,
        target: 'home',
        match: DateTimeComponents.time,
      );
    }
  }

  static tz.TZDateTime _nextDailyLocal(int hour, int minute) {
    final now = tz.TZDateTime.now(tz.local);
    var t = tz.TZDateTime(tz.local, now.year, now.month, now.day, hour, minute);
    if (!t.isAfter(now)) {
      t = t.add(const Duration(days: 1));
    }
    return t;
  }

  /// Next occurrence of [weekday] (DateTime.monday..sunday) at hour:minute.
  static tz.TZDateTime _nextWeeklyLocal(int weekday, int hour, int minute) {
    final now = tz.TZDateTime.now(tz.local);
    var daysAhead = (weekday - now.weekday) % 7;
    if (daysAhead < 0) daysAhead += 7;
    var t = tz.TZDateTime(
      tz.local,
      now.year,
      now.month,
      now.day + daysAhead,
      hour,
      minute,
    );
    if (daysAhead == 0 && !t.isAfter(now)) {
      t = t.add(const Duration(days: 7));
    }
    return t;
  }
}
