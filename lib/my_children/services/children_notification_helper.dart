// lib/my_children/services/children_notification_helper.dart
import 'package:flutter/material.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:timezone/timezone.dart' as tz;
import 'package:timezone/data/latest.dart' as tz_data;

/// Centralized notification helper for the My Children module.
///
/// Uses the existing 'baby' notification channel (channelId: 'baby',
/// channelName: 'Mtoto Wangu') and [FlutterLocalNotificationsPlugin] to
/// schedule all child-related local notifications.
///
/// ID scheme: `childId * 1000 + typeOffset`
///   0-9   feeding
///   10-19 sleep
///   20-29 growth
///   30-39 health / medication
///   40-49 academic / homework
///   50-59 chores
///   60-69 reading
///   70-79 checkups
///   80-89 birthday
///   90-99 daily summary / stage transition
class ChildrenNotificationHelper {
  ChildrenNotificationHelper._();

  static final _plugin = FlutterLocalNotificationsPlugin();
  static bool _tzInitialized = false;

  // ── Shared constants ──────────────────────────────────────────

  static const _androidDetails = AndroidNotificationDetails(
    'baby',
    'Mtoto Wangu',
    channelDescription: 'Arifa za chanjo, kulisha, na maendeleo ya mtoto',
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

  static int _id(int childId, int offset) => childId * 1000 + offset;

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

  // ── Feeding (offsets 0-9) ─────────────────────────────────────

  /// Schedule a reminder at [nextFeedTime].
  static Future<void> scheduleNextFeedReminder(
    int childId,
    String childName,
    DateTime nextFeedTime,
    bool isSwahili,
  ) async {
    final hoursGap =
        nextFeedTime.difference(DateTime.now()).inMinutes / 60;
    final hrs = hoursGap.toStringAsFixed(1);

    await _schedule(
      _id(childId, 0),
      isSwahili
          ? 'Wakati wa Kulisha $childName'
          : 'Feeding Time for $childName',
      isSwahili
          ? 'Imepita masaa $hrs tangu mlo wa mwisho wa $childName'
          : "It's been $hrs hours since $childName's last feed",
      nextFeedTime,
    );
  }

  static Future<void> cancelFeedReminder(int childId) async {
    await _plugin.cancel(_id(childId, 0));
  }

  // ── Sleep (offsets 10-19) ─────────────────────────────────────

  /// Nap reminder at [napTime] based on wake window.
  static Future<void> scheduleNapReminder(
    int childId,
    String childName,
    DateTime napTime,
    bool isSwahili,
  ) async {
    final awakeHrs =
        napTime.difference(DateTime.now()).inMinutes.abs() / 60;
    final hrs = awakeHrs.toStringAsFixed(1);

    await _schedule(
      _id(childId, 10),
      isSwahili
          ? 'Wakati wa Kulala - $childName'
          : 'Nap Time - $childName',
      isSwahili
          ? '$childName amekuwa macho kwa masaa $hrs — wakati wa kulala unakaribia'
          : '$childName has been awake for $hrs hours — nap time approaching',
      napTime,
    );
  }

  /// Bedtime reminder at [bedtime] every day.
  static Future<void> scheduleBedtimeReminder(
    int childId,
    String childName,
    TimeOfDay bedtime,
    bool isSwahili,
  ) async {
    await _scheduleDaily(
      _id(childId, 11),
      isSwahili
          ? 'Wakati wa Kulala - $childName'
          : 'Bedtime - $childName',
      isSwahili
          ? 'Wakati wa kulala wa $childName unakaribia. Anza taratibu za usiku'
          : "$childName's usual bedtime is approaching. Start the bedtime routine",
      bedtime.hour,
      bedtime.minute,
    );
  }

  // ── Growth (offsets 20-29) ────────────────────────────────────

  /// Schedules a reminder on the 1st of next month.
  static Future<void> scheduleMonthlyMeasurementReminder(
    int childId,
    String childName,
    bool isSwahili,
  ) async {
    final now = DateTime.now();
    final nextMonth = DateTime(
      now.month == 12 ? now.year + 1 : now.year,
      now.month == 12 ? 1 : now.month + 1,
      1,
      9, // 9:00 AM
    );

    await _schedule(
      _id(childId, 20),
      isSwahili
          ? 'Kipimo cha $childName'
          : 'Measure $childName',
      isSwahili
          ? 'Wakati wa kupima $childName! Pima uzito na urefu'
          : "Time to measure $childName! Record weight and height",
      nextMonth,
    );
  }

  // ── Health / Medication (offsets 30-39) ────────────────────────

  /// Schedule a medication reminder at [time].
  static Future<void> scheduleMedicationReminder(
    int childId,
    String childName,
    String medication,
    String dosage,
    DateTime time,
    bool isSwahili,
  ) async {
    // Use offset 30-34 for up to 5 concurrent medications.
    // Hash the medication name to pick a slot.
    final slot = medication.hashCode.abs() % 5;
    await _schedule(
      _id(childId, 30 + slot),
      isSwahili
          ? 'Dawa ya $childName'
          : 'Medication for $childName',
      isSwahili
          ? 'Wakati wa $medication ya $childName — $dosage sasa'
          : "Time for $childName's $medication — $dosage due now",
      time,
    );
  }

  /// Schedule a follow-up appointment reminder 1 day before [followUpDate].
  static Future<void> scheduleFollowUpReminder(
    int childId,
    String childName,
    DateTime followUpDate,
    bool isSwahili,
  ) async {
    final oneDayBefore = followUpDate.subtract(const Duration(days: 1));

    await _schedule(
      _id(childId, 35),
      isSwahili
          ? 'Ufuatiliaji wa Daktari'
          : 'Follow-up Reminder',
      isSwahili
          ? 'Miadi ya ufuatiliaji wa $childName ni kesho'
          : "$childName's follow-up appointment is tomorrow",
      oneDayBefore,
    );

    // Also schedule on the morning of the appointment
    final morningOf = DateTime(
      followUpDate.year,
      followUpDate.month,
      followUpDate.day,
      8, // 8:00 AM
    );
    await _schedule(
      _id(childId, 36),
      isSwahili
          ? 'Miadi ya Daktari Leo'
          : 'Doctor Appointment Today',
      isSwahili
          ? '$childName ana miadi ya daktari leo'
          : '$childName has a doctor appointment today',
      morningOf,
    );
  }

  // ── Academic / Homework (offsets 40-49) ────────────────────────

  /// Schedule a homework reminder 1 day before [dueDate].
  static Future<void> scheduleHomeworkReminder(
    int childId,
    String childName,
    String subject,
    DateTime dueDate,
    bool isSwahili,
  ) async {
    final oneDayBefore = dueDate.subtract(const Duration(days: 1));
    final reminderTime = DateTime(
      oneDayBefore.year,
      oneDayBefore.month,
      oneDayBefore.day,
      17, // 5:00 PM
    );

    // Use offset 40-44 for up to 5 concurrent homework items.
    final slot = subject.hashCode.abs() % 5;
    await _schedule(
      _id(childId, 40 + slot),
      isSwahili
          ? 'Kazi ya Nyumbani - $childName'
          : 'Homework Due - $childName',
      isSwahili
          ? 'Kazi ya $subject ya $childName inatakiwa kesho'
          : "$childName's $subject homework is due tomorrow",
      reminderTime,
    );
  }

  // ── Chores (offsets 50-59) ────────────────────────────────────

  /// Daily at 9 AM: "[name] has [X] chores to complete today"
  static Future<void> scheduleDailyChoreReminder(
    int childId,
    String childName,
    int choreCount,
    bool isSwahili,
  ) async {
    if (choreCount <= 0) {
      await _plugin.cancel(_id(childId, 50));
      return;
    }
    await _scheduleDaily(
      _id(childId, 50),
      isSwahili
          ? 'Kazi za Nyumbani - $childName'
          : 'Chores - $childName',
      isSwahili
          ? '$childName ana kazi $choreCount za kukamilisha leo'
          : '$childName has $choreCount chores to complete today',
      9,
      0,
    );
  }

  // ── Reading (offsets 60-69) ───────────────────────────────────

  /// Daily at 7 PM: reading time reminder with streak.
  static Future<void> scheduleReadingReminder(
    int childId,
    String childName,
    int streakDays,
    bool isSwahili,
  ) async {
    await _scheduleDaily(
      _id(childId, 60),
      isSwahili
          ? 'Wakati wa Kusoma!'
          : 'Reading Time!',
      isSwahili
          ? 'Wakati wa kusoma! $childName yuko siku ya $streakDays ya msururu wake wa kusoma'
          : 'Reading time! $childName is on day $streakDays of their reading streak',
      19,
      0,
    );
  }

  // ── Checkups (offsets 70-79) ──────────────────────────────────

  /// Schedule reminders 1 month before and 1 week before [dueDate].
  static Future<void> scheduleAnnualCheckupReminder(
    int childId,
    String childName,
    DateTime dueDate,
    bool isSwahili,
  ) async {
    // 1 month before
    final oneMonthBefore = DateTime(
      dueDate.month == 1 ? dueDate.year - 1 : dueDate.year,
      dueDate.month == 1 ? 12 : dueDate.month - 1,
      dueDate.day,
      9,
    );
    await _schedule(
      _id(childId, 70),
      isSwahili
          ? 'Ukaguzi wa Afya - $childName'
          : 'Health Checkup - $childName',
      isSwahili
          ? 'Ukaguzi wa afya wa mwaka wa $childName unapaswa kufanywa mwezi ujao'
          : "$childName's annual health checkup is due next month",
      oneMonthBefore,
    );

    // 1 week before
    final oneWeekBefore = dueDate.subtract(const Duration(days: 7));
    await _schedule(
      _id(childId, 71),
      isSwahili
          ? 'Ukaguzi wa Afya - $childName'
          : 'Health Checkup - $childName',
      isSwahili
          ? 'Ukaguzi wa afya wa $childName unapaswa kufanywa wiki ijayo'
          : "$childName's health checkup is due next week",
      DateTime(oneWeekBefore.year, oneWeekBefore.month, oneWeekBefore.day, 9),
    );
  }

  // ── Birthday (offsets 80-89) ──────────────────────────────────

  /// Schedule 7 days before + on the day.
  static Future<void> scheduleBirthdayReminder(
    int childId,
    String childName,
    DateTime birthday,
    bool isSwahili,
  ) async {
    // Calculate next birthday
    final now = DateTime.now();
    var nextBirthday = DateTime(now.year, birthday.month, birthday.day, 8);
    if (nextBirthday.isBefore(now)) {
      nextBirthday = DateTime(now.year + 1, birthday.month, birthday.day, 8);
    }

    final age = nextBirthday.year - birthday.year;

    // 7 days before
    final sevenBefore = nextBirthday.subtract(const Duration(days: 7));
    await _schedule(
      _id(childId, 80),
      isSwahili
          ? 'Siku ya Kuzaliwa Inakaribia!'
          : 'Birthday Coming Up!',
      isSwahili
          ? '$childName anakuwa na miaka $age wiki ijayo!'
          : "$childName turns $age in one week!",
      sevenBefore,
    );

    // On the day
    await _schedule(
      _id(childId, 81),
      isSwahili
          ? 'Heri ya Siku ya Kuzaliwa! 🎂'
          : 'Happy Birthday! 🎂',
      isSwahili
          ? 'Leo $childName anakuwa na miaka $age! Hongera!'
          : '$childName turns $age today! Congratulations!',
      nextBirthday,
    );
  }

  // ── Daily Summary (offset 90) ─────────────────────────────────

  /// Every day at 8 PM: "[name]'s day summary is ready"
  static Future<void> scheduleDailySummary(
    int childId,
    String childName,
    bool isSwahili,
  ) async {
    await _scheduleDaily(
      _id(childId, 90),
      isSwahili
          ? 'Muhtasari wa Siku'
          : 'Daily Summary',
      isSwahili
          ? 'Muhtasari wa siku ya $childName upo tayari. Gusa kuona'
          : "$childName's day summary is ready. Tap to view",
      20,
      0,
    );
  }

  // ── Stage Transition (offsets 91-94) ──────────────────────────

  /// Schedule notifications when child crosses 2, 5, 12, 18 year boundaries.
  static Future<void> scheduleStageTransition(
    int childId,
    String childName,
    DateTime dob,
    bool isSwahili,
  ) async {
    final now = DateTime.now();
    final milestoneYears = [2, 5, 12, 18];

    for (var i = 0; i < milestoneYears.length; i++) {
      final year = milestoneYears[i];
      final milestoneDate = DateTime(dob.year + year, dob.month, dob.day, 9);
      if (milestoneDate.isAfter(now)) {
        final stageNames = isSwahili
            ? ['Mtoto Mdogo', 'Mtoto wa Shule', 'Kijana Mdogo', 'Mtu Mzima']
            : ['Toddler', 'School Age', 'Teenager', 'Young Adult'];

        await _schedule(
          _id(childId, 91 + i),
          isSwahili
              ? 'Hatua Mpya - $childName'
              : 'New Stage - $childName',
          isSwahili
              ? '$childName anakuwa na miaka $year leo! Anaendelea kwenye hatua ya ${stageNames[i]}'
              : '$childName turns $year today! Moving to ${stageNames[i]} stage',
          milestoneDate,
        );
        break; // Only schedule the next upcoming transition
      }
    }
  }

  // ── Diaper Alerts (offsets 100-109) ────────────────────────────

  /// If wet diaper count < 6 after 6PM, schedule a dehydration alert.
  static Future<void> scheduleDiaperAlert(
    int childId,
    String childName,
    int wetCount, {
    bool isSwahili = false,
  }) async {
    final now = DateTime.now();
    if (now.hour < 18 || wetCount >= 6) return;

    await _plugin.show(
      _id(childId, 100),
      isSwahili
          ? '⚠️ Tahadhari ya Nepi - $childName'
          : '⚠️ Diaper Alert - $childName',
      isSwahili
          ? '⚠️ $childName amekuwa na nepi $wetCount tu za mkojo leo. Mpe maji zaidi'
          : '⚠️ $childName has had only $wetCount wet diapers today. Offer more fluids',
      _details,
    );
  }

  // ── Vaccine Overdue (offsets 110-119) ─────────────────────────

  /// Alert when a vaccine is overdue by [daysOverdue] days.
  static Future<void> scheduleVaccineOverdueAlert(
    int childId,
    String childName,
    String vaccineName,
    int daysOverdue, {
    bool isSwahili = false,
  }) async {
    if (daysOverdue <= 0) return;

    // Use a slot based on vaccine name hash to avoid collisions
    final slot = vaccineName.hashCode.abs() % 10;
    await _plugin.show(
      _id(childId, 110 + slot),
      isSwahili
          ? 'Chanjo Imechelewa - $childName'
          : 'Vaccine Overdue - $childName',
      isSwahili
          ? '$childName: $vaccineName imechelewa kwa siku $daysOverdue. Tembelea kliniki haraka'
          : '$childName: $vaccineName is overdue by $daysOverdue days. Visit a clinic soon',
      _details,
    );
  }

  // ── Milestone Monthly (offsets 120-129) ───────────────────────

  /// On 1st of month, remind to check milestones for the child's current age.
  static Future<void> scheduleMilestoneMonthlyAlert(
    int childId,
    String childName,
    int ageMonths, {
    bool isSwahili = false,
  }) async {
    final now = DateTime.now();
    // Schedule for the 1st of next month at 9:00 AM
    final nextMonth = DateTime(
      now.month == 12 ? now.year + 1 : now.year,
      now.month == 12 ? 1 : now.month + 1,
      1,
      9,
    );

    await _schedule(
      _id(childId, 120),
      isSwahili
          ? '🎯 Hatua za Maendeleo - $childName'
          : '🎯 Milestones - $childName',
      isSwahili
          ? '🎯 $childName ana miezi $ageMonths! Angalia hatua za maendeleo za mwezi huu'
          : '🎯 $childName is $ageMonths months! Check this month\'s milestones',
      nextMonth,
    );
  }

  // ── Grade Alerts (offsets 130-139) ────────────────────────────

  /// Alert when a subject score has dropped.
  static Future<void> scheduleGradeAlert(
    int childId,
    String childName,
    String subject,
    double oldScore,
    double newScore, {
    bool isSwahili = false,
  }) async {
    if (newScore >= oldScore) return;

    final slot = subject.hashCode.abs() % 10;
    await _plugin.show(
      _id(childId, 130 + slot),
      isSwahili
          ? '📉 Matokeo Yameshuka - $childName'
          : '📉 Grade Drop - $childName',
      isSwahili
          ? '📉 Matokeo ya $subject ya $childName yameshuka kutoka ${oldScore.toStringAsFixed(0)} hadi ${newScore.toStringAsFixed(0)}'
          : '📉 $childName\'s $subject dropped from ${oldScore.toStringAsFixed(0)} to ${newScore.toStringAsFixed(0)}',
      _details,
    );
  }

  // ── Profile Incomplete (offset 140) ───────────────────────────

  /// Remind to complete a child's profile with missing fields.
  static Future<void> scheduleProfileIncomplete(
    int childId,
    String childName,
    List<String> missingFields, {
    bool isSwahili = false,
  }) async {
    if (missingFields.isEmpty) return;

    final fields = missingFields.take(3).join(', ');
    await _plugin.show(
      _id(childId, 140),
      isSwahili
          ? 'Kamilisha Wasifu - $childName'
          : 'Complete Profile - $childName',
      isSwahili
          ? 'Kamilisha wasifu wa $childName — ongeza $fields'
          : 'Complete $childName\'s profile — add $fields',
      _details,
    );
  }

  // ── Fee Due (offset 141) ──────────────────────────────────────

  /// Alert when an activity fee is due.
  static Future<void> scheduleFeeDueAlert(
    int childId,
    String childName,
    String feeType,
    double amount, {
    bool isSwahili = false,
  }) async {
    if (amount <= 0) return;

    await _plugin.show(
      _id(childId, 141),
      isSwahili
          ? '💳 Ada Inahitajika - $childName'
          : '💳 Fee Due - $childName',
      isSwahili
          ? '💳 Ada ya $feeType ya TZS ${amount.toStringAsFixed(0)} inahitajika kwa $childName'
          : '💳 $feeType fee of TZS ${amount.toStringAsFixed(0)} is due for $childName',
      _details,
    );
  }

  // ── Medical Expense (offset 142) ──────────────────────────────

  /// Alert after recording a medical expense.
  static Future<void> scheduleMedicalExpenseAlert(
    int childId,
    String childName,
    double amount, {
    bool isSwahili = false,
  }) async {
    if (amount <= 0) return;

    await _plugin.show(
      _id(childId, 142),
      isSwahili
          ? '💰 Gharama ya Matibabu - $childName'
          : '💰 Medical Expense - $childName',
      isSwahili
          ? '💰 Gharama ya matibabu ya TZS ${amount.toStringAsFixed(0)} imerekodiwa kwa $childName'
          : '💰 Medical expense of TZS ${amount.toStringAsFixed(0)} recorded for $childName',
      _details,
    );
  }

  // ── Weekly Teen Prompts (offsets 150-159) ─────────────────────

  /// Weekly career exploration prompt (every Monday at 10 AM).
  static Future<void> scheduleWeeklyCareerPrompt(
    int childId,
    String childName, {
    bool isSwahili = false,
  }) async {
    _ensureTz();
    final now = tz.TZDateTime.now(tz.local);
    // Next Monday at 10 AM
    var nextMonday = now.add(Duration(days: (DateTime.monday - now.weekday + 7) % 7));
    if (nextMonday.isBefore(now) || nextMonday == now) {
      nextMonday = nextMonday.add(const Duration(days: 7));
    }
    final scheduled = tz.TZDateTime(
      tz.local, nextMonday.year, nextMonday.month, nextMonday.day, 10, 0,
    );

    try {
      await _plugin.zonedSchedule(
        _id(childId, 150),
        isSwahili
            ? '🎯 Mwongozo wa Kazi - $childName'
            : '🎯 Career Guidance - $childName',
        isSwahili
            ? '🎯 Msaidie $childName kuchunguza fursa za kazi!'
            : '🎯 Help $childName explore career options!',
        scheduled,
        _details,
        androidScheduleMode: AndroidScheduleMode.inexactAllowWhileIdle,
        uiLocalNotificationDateInterpretation:
            UILocalNotificationDateInterpretation.absoluteTime,
        matchDateTimeComponents: DateTimeComponents.dayOfWeekAndTime,
      );
    } catch (_) {}
  }

  /// Weekly financial tip (every Wednesday at 10 AM).
  static Future<void> scheduleWeeklyFinancialTip(
    int childId,
    String childName, {
    bool isSwahili = false,
  }) async {
    _ensureTz();
    final now = tz.TZDateTime.now(tz.local);
    // Next Wednesday at 10 AM
    var nextWed = now.add(Duration(days: (DateTime.wednesday - now.weekday + 7) % 7));
    if (nextWed.isBefore(now) || nextWed == now) {
      nextWed = nextWed.add(const Duration(days: 7));
    }
    final scheduled = tz.TZDateTime(
      tz.local, nextWed.year, nextWed.month, nextWed.day, 10, 0,
    );

    try {
      await _plugin.zonedSchedule(
        _id(childId, 151),
        isSwahili
            ? '💡 Kidokezo cha Fedha - $childName'
            : '💡 Money Tip - $childName',
        isSwahili
            ? '💡 Kidokezo cha fedha kwa $childName: Weka akiba kabla ya kutumia!'
            : '💡 Money tip for $childName: Save before you spend!',
        scheduled,
        _details,
        androidScheduleMode: AndroidScheduleMode.inexactAllowWhileIdle,
        uiLocalNotificationDateInterpretation:
            UILocalNotificationDateInterpretation.absoluteTime,
        matchDateTimeComponents: DateTimeComponents.dayOfWeekAndTime,
      );
    } catch (_) {}
  }

  /// Weekly life skill prompt (every Friday at 10 AM).
  static Future<void> scheduleWeeklyLifeSkillPrompt(
    int childId,
    String childName, {
    bool isSwahili = false,
  }) async {
    _ensureTz();
    final now = tz.TZDateTime.now(tz.local);
    // Next Friday at 10 AM
    var nextFri = now.add(Duration(days: (DateTime.friday - now.weekday + 7) % 7));
    if (nextFri.isBefore(now) || nextFri == now) {
      nextFri = nextFri.add(const Duration(days: 7));
    }
    final scheduled = tz.TZDateTime(
      tz.local, nextFri.year, nextFri.month, nextFri.day, 10, 0,
    );

    try {
      await _plugin.zonedSchedule(
        _id(childId, 152),
        isSwahili
            ? '💡 Ujuzi wa Maisha - $childName'
            : '💡 Life Skill - $childName',
        isSwahili
            ? '💡 Ujuzi wa wiki hii kwa $childName: fanya mazoezi ya kusimamia wakati'
            : '💡 This week\'s life skill for $childName: practice time management',
        scheduled,
        _details,
        androidScheduleMode: AndroidScheduleMode.inexactAllowWhileIdle,
        uiLocalNotificationDateInterpretation:
            UILocalNotificationDateInterpretation.absoluteTime,
        matchDateTimeComponents: DateTimeComponents.dayOfWeekAndTime,
      );
    } catch (_) {}
  }

  // ── University Prep (offset 155) ──────────────────────────────

  /// Monthly reminder to check university preparation progress.
  static Future<void> scheduleUniPrepReminder(
    int childId,
    String childName, {
    bool isSwahili = false,
  }) async {
    final now = DateTime.now();
    // Schedule for the 15th of next month at 9 AM
    final nextMonth = DateTime(
      now.month == 12 ? now.year + 1 : now.year,
      now.month == 12 ? 1 : now.month + 1,
      15,
      9,
    );

    await _schedule(
      _id(childId, 155),
      isSwahili
          ? '🎓 Maandalizi ya Chuo - $childName'
          : '🎓 University Prep - $childName',
      isSwahili
          ? '🎓 Angalia maendeleo ya maandalizi ya chuo ya $childName'
          : '🎓 Check $childName\'s university preparation progress',
      nextMonth,
    );
  }

  // ── Caregiver Activity (offsets 160-169) ──────────────────────

  /// Alert when a caregiver logs an action for a child.
  /// Placeholder for future backend push notification integration.
  static Future<void> scheduleCaregiverActivityAlert(
    int childId,
    String childName,
    String caregiverName,
    String action, {
    bool isSwahili = false,
  }) async {
    final slot = action.hashCode.abs() % 10;
    await _plugin.show(
      _id(childId, 160 + slot),
      isSwahili
          ? 'Shughuli ya Mlezi - $childName'
          : 'Caregiver Activity - $childName',
      isSwahili
          ? '$caregiverName amerekodi $action kwa $childName'
          : '$caregiverName logged $action for $childName',
      _details,
    );
  }

  // ── Cancel All ────────────────────────────────────────────────

  /// Cancel all scheduled notifications for a specific child.
  static Future<void> cancelAllForChild(int childId) async {
    // Cancel original range 0-99 plus extended range 100-169
    for (var offset = 0; offset < 170; offset++) {
      await _plugin.cancel(_id(childId, offset));
    }
  }
}
