// lib/my_parents/services/parents_notification_helper.dart
import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:timezone/timezone.dart' as tz;
import 'package:timezone/data/latest.dart' as tz_data;

/// Centralized notification helper for the My Parents (Wazazi Wangu) module.
///
/// Uses a dedicated 'wazazi' notification channel and
/// [FlutterLocalNotificationsPlugin] to schedule all parent-care notifications.
///
/// ID scheme: `parentId * 1000 + typeOffset`
///   0-4    medication dose reminders
///   5-9    missed-dose alerts
///   10-19  appointment reminders
///   20-29  wellness check-in
///   30-39  financial / support reminders
///   40-49  health reading alerts
///   50-59  birthday / NHIF renewal
///   60     weekly health summary
///   61-69  care task notifications
///   70-74  medication refill alerts
class ParentsNotificationHelper {
  ParentsNotificationHelper._();

  static final _plugin = FlutterLocalNotificationsPlugin();
  static bool _tzInitialized = false;

  // ── Shared constants ──────────────────────────────────────────

  static const _androidDetails = AndroidNotificationDetails(
    'wazazi',
    'Wazazi Wangu',
    channelDescription: 'Parent care notifications: medication, appointments & wellness',
    importance: Importance.high,
    priority: Priority.high,
  );

  static const _iosDetails = DarwinNotificationDetails(
    presentAlert: true,
    presentSound: true,
  );

  static const _details = NotificationDetails(
    android: _androidDetails,
    iOS: _iosDetails,
  );

  // ── Helpers ───────────────────────────────────────────────────

  static int _id(int parentId, int offset) => parentId * 1000 + offset;

  static void _ensureTz() {
    if (!_tzInitialized) {
      tz_data.initializeTimeZones();
      _tzInitialized = true;
    }
  }

  static tz.TZDateTime _tzFrom(DateTime dt) =>
      tz.TZDateTime.from(dt, tz.local);

  /// Schedule a notification only if [when] is in the future.
  static Future<void> _schedule(
    int id,
    String title,
    String body,
    DateTime when, {
    String? payload,
  }) async {
    if (!when.isAfter(DateTime.now())) return;
    _ensureTz();
    try {
      await _plugin.zonedSchedule(
        id,
        title,
        body,
        _tzFrom(when),
        _details,
        androidScheduleMode: AndroidScheduleMode.inexactAllowWhileIdle,
        uiLocalNotificationDateInterpretation:
            UILocalNotificationDateInterpretation.absoluteTime,
        payload: payload,
      );
    } catch (_) {
      // Silently ignore scheduling errors (e.g. exact-alarm permission)
    }
  }

  /// Schedule a daily repeating notification at the given [hour]:[minute].
  static Future<void> _scheduleDaily(
    int id,
    String title,
    String body,
    int hour,
    int minute,
  ) async {
    _ensureTz();
    final now = tz.TZDateTime.now(tz.local);
    var scheduled =
        tz.TZDateTime(tz.local, now.year, now.month, now.day, hour, minute);
    if (scheduled.isBefore(now)) {
      scheduled = scheduled.add(const Duration(days: 1));
    }
    try {
      await _plugin.zonedSchedule(
        id,
        title,
        body,
        scheduled,
        _details,
        androidScheduleMode: AndroidScheduleMode.inexactAllowWhileIdle,
        uiLocalNotificationDateInterpretation:
            UILocalNotificationDateInterpretation.absoluteTime,
        matchDateTimeComponents: DateTimeComponents.time,
      );
    } catch (_) {}
  }

  /// Schedule a monthly repeating notification on a given [day] at [hour]:[minute].
  static Future<void> _scheduleMonthly(
    int id,
    String title,
    String body,
    int day,
    int hour,
    int minute,
  ) async {
    _ensureTz();
    final now = tz.TZDateTime.now(tz.local);
    var scheduled =
        tz.TZDateTime(tz.local, now.year, now.month, day, hour, minute);
    if (scheduled.isBefore(now)) {
      // Next month
      final nextMonth = now.month == 12 ? 1 : now.month + 1;
      final nextYear = now.month == 12 ? now.year + 1 : now.year;
      scheduled = tz.TZDateTime(tz.local, nextYear, nextMonth, day, hour, minute);
    }
    try {
      await _plugin.zonedSchedule(
        id,
        title,
        body,
        scheduled,
        _details,
        androidScheduleMode: AndroidScheduleMode.inexactAllowWhileIdle,
        uiLocalNotificationDateInterpretation:
            UILocalNotificationDateInterpretation.absoluteTime,
        matchDateTimeComponents: DateTimeComponents.dayOfMonthAndTime,
      );
    } catch (_) {}
  }

  // ── Medication Dose Reminders (offsets 0-9) ───────────────────

  /// Schedule a medication dose reminder at a specific [time].
  static Future<void> scheduleMedicationDoseReminder(
    int parentId,
    String parentName,
    String medName,
    String dosage,
    DateTime time,
    bool isSwahili,
  ) async {
    final slot = medName.hashCode.abs() % 5;
    await _schedule(
      _id(parentId, 0 + slot),
      isSwahili
          ? 'Dawa ya $parentName'
          : 'Medication for $parentName',
      isSwahili
          ? 'Wakati wa $medName ya $parentName — $dosage sasa'
          : "Time for $parentName's $medName — $dosage due now",
      time,
    );
  }

  /// Schedule a missed-dose alert 30 minutes after [doseTime].
  static Future<void> scheduleMissedDoseAlert(
    int parentId,
    String parentName,
    String medName,
    bool isSwahili, {
    DateTime? doseTime,
  }) async {
    final slot = medName.hashCode.abs() % 5;
    final alertTime = doseTime != null
        ? doseTime.add(const Duration(minutes: 30))
        : DateTime.now().add(const Duration(minutes: 30));
    await _schedule(
      _id(parentId, 5 + slot),
      isSwahili
          ? 'Dawa Imesahauliwa - $parentName'
          : 'Missed Dose - $parentName',
      isSwahili
          ? '$parentName bado hajameza $medName. Tafadhali mkumbushe'
          : '$parentName has not taken $medName yet. Please remind them',
      alertTime,
    );
  }

  /// Schedule a refill alert when pills are running low.
  static Future<void> scheduleRefillAlert(
    int parentId,
    String parentName,
    String medName,
    int pillsLeft,
    bool isSwahili,
  ) async {
    // Show immediately (fire-and-forget)
    // Uses offsets 70-74 to avoid collision with missed-dose alerts (5-9)
    final slot = medName.hashCode.abs() % 5;
    try {
      await _plugin.show(
        _id(parentId, 70 + slot),
        isSwahili
            ? 'Dawa Zinaisha - $parentName'
            : 'Refill Needed - $parentName',
        isSwahili
            ? '$medName ya $parentName zimebaki $pillsLeft tu. Nunua zaidi'
            : "$parentName's $medName has only $pillsLeft pills left. Time to refill",
        _details,
      );
    } catch (_) {}
  }

  // ── Appointment Reminders (offsets 10-19) ─────────────────────

  /// Schedule appointment reminders: 3 days before, 1 day before, 2 hours before.
  static Future<void> scheduleAppointmentReminder(
    int parentId,
    String parentName,
    String doctorName,
    DateTime date,
    bool isSwahili,
  ) async {
    // 3 days before
    final threeDaysBefore = date.subtract(const Duration(days: 3));
    await _schedule(
      _id(parentId, 10),
      isSwahili
          ? 'Miadi ya Daktari - $parentName'
          : 'Doctor Appointment - $parentName',
      isSwahili
          ? '$parentName ana miadi na $doctorName siku 3 zijazo'
          : '$parentName has an appointment with $doctorName in 3 days',
      DateTime(threeDaysBefore.year, threeDaysBefore.month,
          threeDaysBefore.day, 9),
    );

    // 1 day before
    final oneDayBefore = date.subtract(const Duration(days: 1));
    await _schedule(
      _id(parentId, 11),
      isSwahili
          ? 'Miadi ya Daktari Kesho - $parentName'
          : 'Appointment Tomorrow - $parentName',
      isSwahili
          ? '$parentName ana miadi na $doctorName kesho'
          : '$parentName has an appointment with $doctorName tomorrow',
      DateTime(
          oneDayBefore.year, oneDayBefore.month, oneDayBefore.day, 9),
    );

    // 2 hours before
    final twoHoursBefore = date.subtract(const Duration(hours: 2));
    await _schedule(
      _id(parentId, 12),
      isSwahili
          ? 'Miadi Inakaribia - $parentName'
          : 'Appointment Soon - $parentName',
      isSwahili
          ? 'Miadi ya $parentName na $doctorName ni baada ya masaa 2'
          : "$parentName's appointment with $doctorName is in 2 hours",
      twoHoursBefore,
    );
  }

  // ── Wellness Check-In (offsets 20-29) ─────────────────────────

  /// Schedule daily wellness check-in prompt at 9 AM.
  static Future<void> scheduleWellnessCheckInPrompt(
    int parentId,
    String parentName,
    bool isSwahili,
  ) async {
    await _scheduleDaily(
      _id(parentId, 20),
      isSwahili
          ? 'Hali ya $parentName'
          : 'Check on $parentName',
      isSwahili
          ? 'Wakati wa kuangalia hali ya $parentName. Je, amekula? Amemeza dawa?'
          : "Time to check on $parentName. Have they eaten? Taken medication?",
      9,
      0,
    );
  }

  /// Alert when wellness check-in has been missed for [daysMissed] days.
  static Future<void> scheduleMissedCheckInAlert(
    int parentId,
    String parentName,
    int daysMissed,
    bool isSwahili,
  ) async {
    // Show immediately
    try {
      await _plugin.show(
        _id(parentId, 21),
        isSwahili
            ? 'Ukaguzi Umekosekana - $parentName'
            : 'Missed Check-In - $parentName',
        isSwahili
            ? 'Hujafanya ukaguzi wa $parentName kwa siku $daysMissed. Angalia hali yake'
            : "You haven't checked on $parentName for $daysMissed days. Please check in",
        _details,
      );
    } catch (_) {}
  }

  // ── Financial / Support Reminders (offsets 30-39) ─────────────

  /// Schedule monthly support reminder on the 1st of each month at 9 AM.
  static Future<void> scheduleMonthlySupportReminder(
    int parentId,
    String parentName,
    bool isSwahili,
  ) async {
    await _scheduleMonthly(
      _id(parentId, 30),
      isSwahili
          ? 'Msaada wa Kila Mwezi - $parentName'
          : 'Monthly Support - $parentName',
      isSwahili
          ? 'Wakati wa kutuma msaada wa kila mwezi kwa $parentName'
          : "Time to send monthly support to $parentName",
      1, // 1st of month
      9,
      0,
    );
  }

  /// Schedule monthly health check reminder on the 15th at 9 AM.
  static Future<void> scheduleMonthlyHealthCheck(
    int parentId,
    String parentName,
    bool isSwahili,
  ) async {
    await _scheduleMonthly(
      _id(parentId, 35),
      isSwahili
          ? 'Ukaguzi wa Afya - $parentName'
          : 'Health Check - $parentName',
      isSwahili
          ? 'Wakati wa kufanya ukaguzi wa afya wa kila mwezi kwa $parentName'
          : "Time for $parentName's monthly health check",
      15, // 15th of month
      9,
      0,
    );
  }

  // ── Health Reading Alerts (offsets 40-49) ──────────────────────

  /// Alert when an abnormal health reading is recorded.
  static Future<void> scheduleAbnormalReadingAlert(
    int parentId,
    String parentName,
    String readingType,
    double value,
    bool isSwahili,
  ) async {
    final slot = readingType.hashCode.abs() % 10;
    try {
      await _plugin.show(
        _id(parentId, 40 + slot),
        isSwahili
            ? 'Tahadhari ya Afya - $parentName'
            : 'Health Alert - $parentName',
        isSwahili
            ? 'Kipimo cha $readingType cha $parentName ($value) si cha kawaida. Wasiliana na daktari'
            : "$parentName's $readingType reading ($value) is abnormal. Contact a doctor",
        _details,
      );
    } catch (_) {}
  }

  // ── Birthday & NHIF (offsets 50-59) ───────────────────────────

  /// Schedule birthday reminder: 7 days before + on the day.
  static Future<void> scheduleBirthdayReminder(
    int parentId,
    String parentName,
    DateTime birthday,
    bool isSwahili,
  ) async {
    final now = DateTime.now();
    var nextBirthday = DateTime(now.year, birthday.month, birthday.day, 8);
    if (nextBirthday.isBefore(now)) {
      nextBirthday = DateTime(now.year + 1, birthday.month, birthday.day, 8);
    }

    final age = nextBirthday.year - birthday.year;

    // 7 days before
    final sevenBefore = nextBirthday.subtract(const Duration(days: 7));
    await _schedule(
      _id(parentId, 50),
      isSwahili
          ? 'Siku ya Kuzaliwa Inakaribia!'
          : 'Birthday Coming Up!',
      isSwahili
          ? '$parentName anakuwa na miaka $age wiki ijayo!'
          : "$parentName turns $age in one week!",
      sevenBefore,
    );

    // On the day
    await _schedule(
      _id(parentId, 51),
      isSwahili
          ? 'Heri ya Siku ya Kuzaliwa!'
          : 'Happy Birthday!',
      isSwahili
          ? 'Leo $parentName anakuwa na miaka $age! Mpigie simu kumtakia heri'
          : '$parentName turns $age today! Call to wish them well',
      nextBirthday,
    );
  }

  /// Schedule NHIF renewal reminder 30 days before [expiryDate].
  static Future<void> scheduleNhifRenewalReminder(
    int parentId,
    String parentName,
    DateTime expiryDate,
    bool isSwahili,
  ) async {
    final reminderDate = expiryDate.subtract(const Duration(days: 30));
    await _schedule(
      _id(parentId, 55),
      isSwahili
          ? 'NHIF Inaisha - $parentName'
          : 'NHIF Expiring - $parentName',
      isSwahili
          ? 'Bima ya NHIF ya $parentName inaisha baada ya siku 30. Fanya upya mapema'
          : "$parentName's NHIF insurance expires in 30 days. Renew early",
      DateTime(reminderDate.year, reminderDate.month, reminderDate.day, 9),
    );

    // Also remind 7 days before
    final weekBefore = expiryDate.subtract(const Duration(days: 7));
    await _schedule(
      _id(parentId, 56),
      isSwahili
          ? 'NHIF Inaisha Hivi Karibuni - $parentName'
          : 'NHIF Expiring Soon - $parentName',
      isSwahili
          ? 'Bima ya NHIF ya $parentName inaisha wiki ijayo! Fanya upya sasa'
          : "$parentName's NHIF expires next week! Renew now",
      DateTime(weekBefore.year, weekBefore.month, weekBefore.day, 9),
    );
  }

  // ── Weekly Health Summary (offset 60) ─────────────────────────

  /// Schedule a weekly health summary notification every Sunday at 8 PM.
  static Future<void> scheduleWeeklyHealthSummary(
    int parentId,
    String parentName,
    bool isSwahili,
  ) async {
    _ensureTz();
    final now = tz.TZDateTime.now(tz.local);
    // Find next Sunday at 20:00
    var nextSunday = tz.TZDateTime(
        tz.local, now.year, now.month, now.day, 20, 0);
    while (nextSunday.weekday != DateTime.sunday || nextSunday.isBefore(now)) {
      nextSunday = nextSunday.add(const Duration(days: 1));
    }
    try {
      await _plugin.zonedSchedule(
        _id(parentId, 60),
        isSwahili
            ? 'Muhtasari wa Afya - $parentName'
            : 'Health Summary - $parentName',
        isSwahili
            ? 'Angalia muhtasari wa afya ya $parentName wiki hii'
            : "Review $parentName's health summary for this week",
        nextSunday,
        _details,
        androidScheduleMode: AndroidScheduleMode.inexactAllowWhileIdle,
        uiLocalNotificationDateInterpretation:
            UILocalNotificationDateInterpretation.absoluteTime,
        matchDateTimeComponents: DateTimeComponents.dayOfWeekAndTime,
      );
    } catch (_) {}
  }

  // ── Care Task Notifications (offsets 61-69) ──────────────────

  /// Immediate notification when a care task is overdue.
  static Future<void> scheduleCareTaskOverdue(
    int parentId,
    String parentName,
    String taskTitle,
    bool isSwahili,
  ) async {
    try {
      await _plugin.show(
        _id(parentId, 61),
        isSwahili
            ? 'Kazi Imechelewa - $parentName'
            : 'Task Overdue - $parentName',
        isSwahili
            ? 'Kazi "$taskTitle" ya $parentName imechelewa. Tafadhali ikamilishe'
            : '"$taskTitle" for $parentName is overdue. Please complete it',
        _details,
      );
    } catch (_) {}
  }

  /// Immediate notification when a care task is completed.
  static Future<void> scheduleCareTaskCompleted(
    int parentId,
    String parentName,
    String taskTitle,
    String completedBy,
    bool isSwahili,
  ) async {
    try {
      await _plugin.show(
        _id(parentId, 62),
        isSwahili
            ? 'Kazi Imekamilika - $parentName'
            : 'Task Completed - $parentName',
        isSwahili
            ? '$completedBy amekamilisha "$taskTitle" ya $parentName'
            : '$completedBy completed "$taskTitle" for $parentName',
        _details,
      );
    } catch (_) {}
  }

  /// Immediate notification when a new care team member joins.
  static Future<void> scheduleCareTeamNewMember(
    int parentId,
    String parentName,
    String memberName,
    bool isSwahili,
  ) async {
    try {
      await _plugin.show(
        _id(parentId, 63),
        isSwahili
            ? 'Mshiriki Mpya - $parentName'
            : 'New Team Member - $parentName',
        isSwahili
            ? '$memberName amejiunga na timu ya utunzaji wa $parentName'
            : '$memberName has joined $parentName\'s care team',
        _details,
      );
    } catch (_) {}
  }

  // ── Cancel All ────────────────────────────────────────────────

  /// Cancel all scheduled notifications for a specific parent.
  static Future<void> cancelAllForParent(int parentId) async {
    // Extended range to include all offsets (0-79)
    for (var offset = 0; offset < 80; offset++) {
      await _plugin.cancel(_id(parentId, offset));
    }
  }
}
