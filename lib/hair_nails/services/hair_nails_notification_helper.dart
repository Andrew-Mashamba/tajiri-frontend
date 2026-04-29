// Local reminders for Hair & Nails — uses [FcmService] zoned schedule (same plugin as FCM foreground).
import 'package:flutter/foundation.dart';
import 'package:timezone/data/latest.dart' as tz_data;
import 'package:timezone/timezone.dart' as tz;

import '../../services/fcm_service.dart';

/// IDs derived from [bookingId] so cancel/reschedule is stable.
class HairNailsNotificationHelper {
  HairNailsNotificationHelper._();

  static bool _tzInitialized = false;

  static void _ensureTz() {
    if (!_tzInitialized) {
      tz_data.initializeTimeZones();
      _tzInitialized = true;
    }
  }

  static int _id24(int bookingId) => 8_000_000 + (bookingId % 100_000) * 2;
  static int _id1h(int bookingId) => _id24(bookingId) + 1;

  static int _growthMonthlyId(int userId) => 8_200_000 + (userId % 50_000);

  /// Cancel T-24h and T-1h reminders for this booking (e.g. after cancel).
  static Future<void> cancelBookingReminders(int bookingId) async {
    final fcm = FcmService.instance;
    await fcm.cancelNotification(_id24(bookingId));
    await fcm.cancelNotification(_id1h(bookingId));
  }

  /// Schedules local notifications before [appointmentLocal] (device local time).
  static Future<void> scheduleBookingReminders({
    required int bookingId,
    required String salonName,
    required String serviceName,
    required DateTime appointmentLocal,
  }) async {
    _ensureTz();
    await cancelBookingReminders(bookingId);
    final fcm = FcmService.instance;

    final t24 = appointmentLocal.subtract(const Duration(hours: 24));
    final t1 = appointmentLocal.subtract(const Duration(hours: 1));
    final now = DateTime.now();

    if (t24.isAfter(now)) {
      final z = tz.TZDateTime.from(t24, tz.local);
      await fcm.scheduleHairNailsZonedNotification(
        notificationId: _id24(bookingId),
        title: 'Miadi kesho',
        body: '$serviceName @ $salonName — bonyeza kwa maelezo.',
        scheduledLocal: z,
      );
    }

    if (t1.isAfter(now)) {
      final z = tz.TZDateTime.from(t1, tz.local);
      await fcm.scheduleHairNailsZonedNotification(
        notificationId: _id1h(bookingId),
        title: 'Ndani ya saa 1',
        body: '$serviceName katika $salonName.',
        scheduledLocal: z,
      );
    }
  }

  /// One-shot nudge to measure hair length (first of next month 09:00 if no log in 28+ days).
  static Future<void> rescheduleGrowthMeasureIfStale({
    required int userId,
    required bool isSwahili,
    DateTime? lastLogTime,
  }) async {
    _ensureTz();
    final fcm = FcmService.instance;
    final nid = _growthMonthlyId(userId);
    await fcm.cancelNotification(nid);

    if (lastLogTime != null && DateTime.now().difference(lastLogTime).inDays < 28) {
      return;
    }

    final now = tz.TZDateTime.now(tz.local);
    var next = tz.TZDateTime(tz.local, now.year, now.month, 1, 9, 0);
    if (!next.isAfter(now)) {
      next = tz.TZDateTime(tz.local, now.year, now.month + 1, 1, 9, 0);
    }

    await fcm.scheduleHairNailsZonedNotification(
      notificationId: nid,
      title: isSwahili ? 'Pima urefu wa nywele' : 'Log your hair length',
      body: isSwahili
          ? 'Ni wakati wa kuandika urefu (cm) katika Ukuaji wa Nywele.'
          : 'Time to log your length (cm) in Hair Growth.',
      scheduledLocal: next,
    );
    if (kDebugMode) debugPrint('[HairNailsNotif] Scheduled growth nudge at $next');
  }
}
