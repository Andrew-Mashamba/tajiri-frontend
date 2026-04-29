import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:timezone/timezone.dart' as tz;
import 'package:timezone/data/latest.dart' as tz_data;

import '../models/food_preferences.dart';

/// Local-notification helper for the Food module.
///
/// Channels follow `docs/modules/food_user_journeys.md` §20 (10 channels):
///
///   food_order      — order updates, pickup reminders, cart abandonment
///   food_chef       — chef listing drops aimed at homemade-buyers
///   food_rescue     — saidia listings (donor side)
///   food_donation   — donation receipts and tax tags
///   food_beneficiary — beneficiary org alerts (server-driven)
///   food_seasonal   — Ramadhan/Christmas/Easter/Sunday surfaces
///   food_emergency  — community emergency feedings (overrides quiet hours)
///   food_runner     — delivery runner tasks
///   food_review     — review nudges after delivery
///   system          — generic / fallback
///
/// ID scheme: `entityId * 10 + offset`
///   0 = pickup reminder (-1h before pickup window start)
///   1 = review nudge (+2h after delivery)
///   2 = pickup reminder final (-15min)
///   3 = cart abandonment (+30min after add)
class FoodNotificationHelper {
  FoodNotificationHelper._();

  // Channel IDs (must match `food_settings_page` category keys where applicable).
  static const channelOrder = 'food_order';
  static const channelChef = 'food_chef';
  static const channelRescue = 'food_rescue';
  static const channelDonation = 'food_donation';
  static const channelBeneficiary = 'food_beneficiary';
  static const channelSeasonal = 'food_seasonal';
  static const channelEmergency = 'food_emergency';
  static const channelRunner = 'food_runner';
  static const channelReview = 'food_review';
  static const channelSystem = 'system';

  static final _plugin = FlutterLocalNotificationsPlugin();
  static bool _tzInitialized = false;

  static const _iosDetails = DarwinNotificationDetails(
    presentAlert: true,
    presentSound: true,
  );

  /// Build AndroidNotificationDetails for a given channel. Emergency channel
  /// uses MAX importance so it punches through DND on supported devices.
  static AndroidNotificationDetails _android(String channelId) {
    final cfg = _channelConfig(channelId);
    return AndroidNotificationDetails(
      channelId,
      cfg.name,
      channelDescription: cfg.description,
      importance: cfg.importance,
      priority: cfg.priority,
    );
  }

  static NotificationDetails _details(String channelId) => NotificationDetails(
        android: _android(channelId),
        iOS: _iosDetails,
      );

  static _ChannelConfig _channelConfig(String id) {
    switch (id) {
      case channelOrder:
        return const _ChannelConfig(
          name: 'Maagizo ya chakula',
          description: 'Maagizo, kuchukua, na ukumbusho wa toroli',
          importance: Importance.high,
          priority: Priority.high,
        );
      case channelChef:
        return const _ChannelConfig(
          name: 'Wapishi wa nyumbani',
          description: 'Vyakula vipya kutoka kwa wapishi wa karibu',
          importance: Importance.defaultImportance,
          priority: Priority.defaultPriority,
        );
      case channelRescue:
        return const _ChannelConfig(
          name: 'Saidia chakula',
          description: 'Vyakula vya kuokolewa au kutoa kwa wenye uhitaji',
          importance: Importance.high,
          priority: Priority.high,
        );
      case channelDonation:
        return const _ChannelConfig(
          name: 'Risiti za michango',
          description: 'Uthibitisho wa michango na ushuru',
          importance: Importance.defaultImportance,
          priority: Priority.defaultPriority,
        );
      case channelBeneficiary:
        return const _ChannelConfig(
          name: 'Mashirika yanayopokea',
          description: 'Taarifa kutoka kwa mashirika ya wenye uhitaji',
          importance: Importance.defaultImportance,
          priority: Priority.defaultPriority,
        );
      case channelSeasonal:
        return const _ChannelConfig(
          name: 'Misimu ya kulisha',
          description: 'Ramadhani, Krismasi, Pasaka, Jumapili',
          importance: Importance.defaultImportance,
          priority: Priority.defaultPriority,
        );
      case channelEmergency:
        return const _ChannelConfig(
          name: 'Dharura ya chakula',
          description: 'Wito wa dharura — utapita masaa ya utulivu',
          importance: Importance.max,
          priority: Priority.max,
        );
      case channelRunner:
        return const _ChannelConfig(
          name: 'Mlinzi wa usafirishaji',
          description: 'Kazi za usafirishaji wa chakula',
          importance: Importance.high,
          priority: Priority.high,
        );
      case channelReview:
        return const _ChannelConfig(
          name: 'Ukaguzi wa huduma',
          description: 'Ukumbusho wa kutoa ukaguzi baada ya kupokea chakula',
          importance: Importance.low,
          priority: Priority.low,
        );
      case channelSystem:
      default:
        return const _ChannelConfig(
          name: 'Mfumo',
          description: 'Arifa za jumla za mfumo',
          importance: Importance.defaultImportance,
          priority: Priority.defaultPriority,
        );
    }
  }

  static int _id(int entityId, int offset) => entityId * 10 + offset;

  static void _ensureTz() {
    if (!_tzInitialized) {
      tz_data.initializeTimeZones();
      _tzInitialized = true;
    }
  }

  /// Returns true if [when] falls inside the user's quiet hours window.
  /// Quiet hours strings are "HH:mm". A wrap-around window (e.g. 22:00–06:00)
  /// is supported.
  static bool _isQuiet(DateTime when, FoodPreferences? prefs) {
    final start = _parseHm(prefs?.quietHoursStart);
    final end = _parseHm(prefs?.quietHoursEnd);
    if (start == null || end == null) return false;
    final mins = when.hour * 60 + when.minute;
    if (start == end) return false;
    if (start < end) return mins >= start && mins < end;
    return mins >= start || mins < end;
  }

  static int? _parseHm(String? s) {
    if (s == null || s.isEmpty) return null;
    final parts = s.split(':');
    if (parts.length < 2) return null;
    final h = int.tryParse(parts[0]);
    final m = int.tryParse(parts[1]);
    if (h == null || m == null) return null;
    return h * 60 + m;
  }

  /// If [when] lands in the quiet window, push it to the next occurrence of
  /// quietEnd. Otherwise return [when] unchanged.
  static DateTime _shiftIfQuiet(DateTime when, FoodPreferences? prefs) {
    if (!_isQuiet(when, prefs)) return when;
    final endMin = _parseHm(prefs?.quietHoursEnd)!;
    var shifted = DateTime(when.year, when.month, when.day, endMin ~/ 60, endMin % 60);
    if (!shifted.isAfter(when)) {
      shifted = shifted.add(const Duration(days: 1));
    }
    return shifted;
  }

  static bool _isCategoryEnabled(FoodPreferences? prefs, String category) {
    if (prefs == null) return true;
    return prefs.notificationCategories.contains(category);
  }

  /// Schedule a notification on [channelId] at [when].
  ///
  /// If [bypassQuietHours] is false (default), the firing time is shifted to
  /// quietEnd when it lands inside the user's quiet window. Emergency callers
  /// pass true to override.
  static Future<void> _schedule({
    required int id,
    required String title,
    required String body,
    required DateTime when,
    required String channelId,
    bool bypassQuietHours = false,
  }) async {
    if (!when.isAfter(DateTime.now())) return;
    _ensureTz();
    try {
      await _plugin.zonedSchedule(
        id,
        title,
        body,
        tz.TZDateTime.from(when, tz.local),
        _details(channelId),
        androidScheduleMode: AndroidScheduleMode.inexactAllowWhileIdle,
        uiLocalNotificationDateInterpretation:
            UILocalNotificationDateInterpretation.absoluteTime,
      );
    } catch (_) {}
  }

  /// Schedule both pickup reminders (-1h and -15m) for a chef-listing
  /// reservation. Skipped entirely if `reservation_reminders` is disabled.
  /// Per-firing time is shifted out of quiet hours.
  static Future<void> schedulePickupReminder({
    required int reservationId,
    required String listingTitle,
    required DateTime pickupWindowStart,
    FoodPreferences? prefs,
  }) async {
    if (!_isCategoryEnabled(prefs, 'reservation_reminders')) return;

    final hourBefore = _shiftIfQuiet(
      pickupWindowStart.subtract(const Duration(hours: 1)),
      prefs,
    );
    await _schedule(
      id: _id(reservationId, 0),
      title: 'Uhifadhi: $listingTitle',
      body: 'Saa moja imebakia kabla ya muda wa kuchukua chakula chako',
      when: hourBefore,
      channelId: channelRescue,
    );

    final fifteenBefore = _shiftIfQuiet(
      pickupWindowStart.subtract(const Duration(minutes: 15)),
      prefs,
    );
    await _schedule(
      id: _id(reservationId, 2),
      title: 'Karibu kuchukua: $listingTitle',
      body: 'Dakika 15 zimebaki — anza safari yako',
      when: fifteenBefore,
      channelId: channelRescue,
    );
  }

  static Future<void> cancelPickupReminder(int reservationId) async {
    await _plugin.cancel(_id(reservationId, 0));
    await _plugin.cancel(_id(reservationId, 2));
  }

  /// Schedule a review nudge 2 hours after delivery. Skipped if `reviews`
  /// category is disabled or firing time hits quiet hours (shifted forward).
  static Future<void> scheduleReviewNudge({
    required int reservationId,
    required String listingTitle,
    DateTime? deliveredAt,
    FoodPreferences? prefs,
  }) async {
    if (!_isCategoryEnabled(prefs, 'reviews')) return;
    final base = deliveredAt ?? DateTime.now();
    var when = base.add(const Duration(hours: 2));
    when = _shiftIfQuiet(when, prefs);
    await _schedule(
      id: _id(reservationId, 1),
      title: 'Tafadhali toa ukaguzi',
      body: 'Vipi $listingTitle? Toa nyota na maoni mafupi',
      when: when,
      channelId: channelReview,
    );
  }

  static Future<void> cancelReviewNudge(int reservationId) async {
    await _plugin.cancel(_id(reservationId, 1));
  }

  /// Schedule a cart-abandonment nudge 2 hours after the user added items
  /// without checking out (per `food_user_journeys.md` §3). Cancel via
  /// [cancelCartAbandonment] on checkout or cart clear. Gated by
  /// `order_updates` category.
  static Future<void> scheduleCartAbandonment({
    required int cartId,
    required String summary,
    Duration after = const Duration(hours: 2),
    FoodPreferences? prefs,
  }) async {
    if (!_isCategoryEnabled(prefs, 'order_updates')) return;
    final when = _shiftIfQuiet(DateTime.now().add(after), prefs);
    await _schedule(
      id: _id(cartId, 3),
      title: 'Toroli yako inakusubiri',
      body: summary.isEmpty ? 'Maliza agizo lako' : summary,
      when: when,
      channelId: channelOrder,
    );
  }

  static Future<void> cancelCartAbandonment(int cartId) async {
    await _plugin.cancel(_id(cartId, 3));
  }

  /// Schedule an emergency feeding alert. Bypasses quiet hours per doc §20.
  /// Gated by `emergencies` category.
  static Future<void> scheduleEmergencyAlert({
    required int alertId,
    required String title,
    required String body,
    required DateTime when,
    FoodPreferences? prefs,
  }) async {
    if (!_isCategoryEnabled(prefs, 'emergencies')) return;
    await _schedule(
      id: _id(alertId, 0),
      title: title,
      body: body,
      when: when,
      channelId: channelEmergency,
      bypassQuietHours: true,
    );
  }

  /// Cancel everything scheduled for a reservation (e.g. on cancellation).
  static Future<void> cancelAllForReservation(int reservationId) async {
    for (var offset = 0; offset < 10; offset++) {
      await _plugin.cancel(_id(reservationId, offset));
    }
  }
}

class _ChannelConfig {
  final String name;
  final String description;
  final Importance importance;
  final Priority priority;
  const _ChannelConfig({
    required this.name,
    required this.description,
    required this.importance,
    required this.priority,
  });
}
