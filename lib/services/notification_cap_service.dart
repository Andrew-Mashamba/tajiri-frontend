import 'dart:convert';
import 'package:shared_preferences/shared_preferences.dart';

/// Spec §C.11 — notification cap per module per day.
///
/// Client-side rate limiter. Tracks how many notifications of each
/// [module] have been shown today. Silently drops pushes beyond the cap.
/// Caps are generous (10–20/day) to avoid genuine notifications being lost.
class NotificationCapService {
  static const String _key = 'notification_cap_tracker';
  static final Map<String, int> _defaultCaps = {
    'partner_orders': 15,
    'customer_orders': 15,
    'partner_summaries': 3,
    'customer_summaries': 3,
    'appointments': 10,
    'consultations': 10,
    'events': 10,
    'engagements': 10,
    'reviews': 5,
    'availability': 5,
    'system': 10,
  };

  /// Returns true if this notification should be allowed through.
  static Future<bool> allow(String module) async {
    final cap = _defaultCaps[module] ?? 10;
    final prefs = await SharedPreferences.getInstance();
    final raw = prefs.getString(_key);

    final today = _today();
    Map<String, Map<String, int>> tracker;
    if (raw != null && raw.isNotEmpty) {
      try {
        final decoded = jsonDecode(raw) as Map<String, dynamic>;
        tracker = decoded.map((k, v) => MapEntry(k, (v as Map<String, dynamic>).map((kk, vv) => MapEntry(kk, vv as int))));
      } catch (_) {
        tracker = {};
      }
    } else {
      tracker = {};
    }

    // Reset counts if date rolled over.
    if (tracker['__date']?['today'] != today) {
      tracker = {'__date': {'today': today}};
    }

    final count = tracker[module]?['count'] ?? 0;
    if (count >= cap) return false;

    tracker[module] = {'count': count + 1};
    await prefs.setString(_key, jsonEncode(tracker));
    return true;
  }

  /// Emergency reset (e.g. user toggles a setting).
  static Future<void> reset() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.remove(_key);
  }

  static int _today() {
    final now = DateTime.now();
    return now.year * 10000 + now.month * 100 + now.day;
  }
}
