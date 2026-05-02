import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;

import '../config/api_config.dart';
import '../l10n/app_strings.dart';
import 'local_storage_service.dart';

/// Notification preferences — model + HTTP client.
///
/// Mirrors the backend `notification_preferences.category_channels` JSONB
/// matrix (12 categories × 4 channels) plus the global toggles
/// (sound, vibrate, quiet hours).

class ArifaChannel {
  static const push = 'push';
  static const email = 'email';
  static const sms = 'sms';
  static const inApp = 'in_app';
  static const all = [push, email, sms, inApp];
}

class ArifaCategory {
  static const messaging = 'messaging';
  static const groups = 'groups';
  static const calls = 'calls';
  static const social = 'social';
  static const marketplace = 'marketplace';
  static const bookings = 'bookings';
  static const clientsCrm = 'clients_crm';
  static const creator = 'creator';
  static const streams = 'streams';
  static const health = 'health';
  static const money = 'money';
  static const system = 'system';

  static const orderedList = [
    messaging, groups, calls, social, marketplace, bookings,
    clientsCrm, creator, streams, health, money, system,
  ];
}

/// Cluster groupings for the home page. Each cluster opens a sub-page
/// rendering its categories with the per-channel toggles.
class ArifaCluster {
  final String key;
  final List<String> categories;
  const ArifaCluster({required this.key, required this.categories});

  static const communication = ArifaCluster(key: 'communication', categories: [
    ArifaCategory.messaging,
    ArifaCategory.groups,
    ArifaCategory.calls,
    ArifaCategory.social,
  ]);
  static const business = ArifaCluster(key: 'business', categories: [
    ArifaCategory.marketplace,
    ArifaCategory.bookings,
    ArifaCategory.clientsCrm,
  ]);
  static const creator = ArifaCluster(key: 'creator', categories: [
    ArifaCategory.creator,
    ArifaCategory.streams,
  ]);
  static const sensitive = ArifaCluster(key: 'sensitive', categories: [
    ArifaCategory.health,
    ArifaCategory.money,
  ]);
  static const system = ArifaCluster(key: 'system', categories: [
    ArifaCategory.system,
  ]);

  static const all = [communication, business, creator, sensitive, system];
}

/// Visual + bilingual metadata for each category, used by the cluster screen.
class ArifaCategoryMeta {
  final String key;
  final IconData icon;
  final String Function(AppStrings s) title;
  final String Function(AppStrings s) subtitle;
  const ArifaCategoryMeta(this.key, this.icon, this.title, this.subtitle);

  static const all = [
    ArifaCategoryMeta(ArifaCategory.messaging, Icons.message_outlined,
        _titleMessaging, _subMessaging),
    ArifaCategoryMeta(ArifaCategory.groups, Icons.group_outlined,
        _titleGroups, _subGroups),
    ArifaCategoryMeta(ArifaCategory.calls, Icons.call_outlined,
        _titleCalls, _subCalls),
    ArifaCategoryMeta(ArifaCategory.social, Icons.favorite_outline,
        _titleSocial, _subSocial),
    ArifaCategoryMeta(ArifaCategory.marketplace, Icons.storefront_outlined,
        _titleMarketplace, _subMarketplace),
    ArifaCategoryMeta(ArifaCategory.bookings, Icons.event_available_outlined,
        _titleBookings, _subBookings),
    ArifaCategoryMeta(ArifaCategory.clientsCrm, Icons.people_alt_outlined,
        _titleClients, _subClients),
    ArifaCategoryMeta(ArifaCategory.creator, Icons.auto_awesome_outlined,
        _titleCreator, _subCreator),
    ArifaCategoryMeta(ArifaCategory.streams, Icons.live_tv_outlined,
        _titleStreams, _subStreams),
    ArifaCategoryMeta(ArifaCategory.health, Icons.health_and_safety_outlined,
        _titleHealth, _subHealth),
    ArifaCategoryMeta(ArifaCategory.money, Icons.account_balance_wallet_outlined,
        _titleMoney, _subMoney),
    ArifaCategoryMeta(ArifaCategory.system, Icons.shield_outlined,
        _titleSystem, _subSystem),
  ];

  static ArifaCategoryMeta forKey(String key) =>
      all.firstWhere((m) => m.key == key, orElse: () => all.last);

  static String _titleMessaging(AppStrings s) => s.notifCatMessaging;
  static String _subMessaging(AppStrings s) => s.notifCatMessagingSub;
  static String _titleGroups(AppStrings s) => s.notifCatGroups;
  static String _subGroups(AppStrings s) => s.notifCatGroupsSub;
  static String _titleCalls(AppStrings s) => s.notifCatCalls;
  static String _subCalls(AppStrings s) => s.notifCatCallsSub;
  static String _titleSocial(AppStrings s) => s.notifCatSocial;
  static String _subSocial(AppStrings s) => s.notifCatSocialSub;
  static String _titleMarketplace(AppStrings s) => s.notifCatMarketplace;
  static String _subMarketplace(AppStrings s) => s.notifCatMarketplaceSub;
  static String _titleBookings(AppStrings s) => s.notifCatBookings;
  static String _subBookings(AppStrings s) => s.notifCatBookingsSub;
  static String _titleClients(AppStrings s) => s.notifCatClients;
  static String _subClients(AppStrings s) => s.notifCatClientsSub;
  static String _titleCreator(AppStrings s) => s.notifCatCreator;
  static String _subCreator(AppStrings s) => s.notifCatCreatorSub;
  static String _titleStreams(AppStrings s) => s.notifCatStreams;
  static String _subStreams(AppStrings s) => s.notifCatStreamsSub;
  static String _titleHealth(AppStrings s) => s.notifCatHealth;
  static String _subHealth(AppStrings s) => s.notifCatHealthSub;
  static String _titleMoney(AppStrings s) => s.notifCatMoney;
  static String _subMoney(AppStrings s) => s.notifCatMoneySub;
  static String _titleSystem(AppStrings s) => s.notifCatSystem;
  static String _subSystem(AppStrings s) => s.notifCatSystemSub;
}

class NotificationPreferences {
  final Map<String, Map<String, bool>> matrix;
  final bool vibrate;
  final String? sound; // null = device default; else 'chime'/'bell'/'silent'
  final bool quietEnabled;
  final TimeOfDay quietStart;
  final TimeOfDay quietEnd;

  const NotificationPreferences({
    this.matrix = const {},
    this.vibrate = true,
    this.sound,
    this.quietEnabled = false,
    this.quietStart = const TimeOfDay(hour: 22, minute: 0),
    this.quietEnd = const TimeOfDay(hour: 7, minute: 0),
  });

  factory NotificationPreferences.fromJson(Map<String, dynamic> prefs) {
    final raw = prefs['category_channels'];
    final asMap = raw is Map<String, dynamic> ? raw : <String, dynamic>{};
    final newMatrix = <String, Map<String, bool>>{};
    for (final cat in ArifaCategory.orderedList) {
      final row = asMap[cat] is Map<String, dynamic>
          ? asMap[cat] as Map<String, dynamic>
          : <String, dynamic>{};
      newMatrix[cat] = {
        for (final ch in ArifaChannel.all)
          ch: row[ch] is bool ? row[ch] as bool : true,
      };
    }
    TimeOfDay parseTime(String? value, TimeOfDay fallback) {
      if (value == null || value.isEmpty) return fallback;
      final parts = value.split(':');
      if (parts.length < 2) return fallback;
      final h = int.tryParse(parts[0]);
      final m = int.tryParse(parts[1]);
      if (h == null || m == null) return fallback;
      return TimeOfDay(hour: h, minute: m);
    }

    return NotificationPreferences(
      matrix: newMatrix,
      vibrate: prefs['global_vibrate'] is bool
          ? prefs['global_vibrate'] as bool
          : true,
      sound: prefs['global_sound'] as String?,
      quietEnabled: prefs['quiet_hours_enabled'] is bool
          ? prefs['quiet_hours_enabled'] as bool
          : false,
      quietStart: parseTime(
          prefs['quiet_hours_start'] as String?, const TimeOfDay(hour: 22, minute: 0)),
      quietEnd: parseTime(
          prefs['quiet_hours_end'] as String?, const TimeOfDay(hour: 7, minute: 0)),
    );
  }

  bool channel(String category, String channel) =>
      matrix[category]?[channel] ?? true;

  NotificationPreferences withCell(String category, String channel, bool value) {
    final next = {
      for (final entry in matrix.entries) entry.key: {...entry.value},
    };
    next[category] = {...?next[category], channel: value};
    return NotificationPreferences(
      matrix: next,
      vibrate: vibrate,
      sound: sound,
      quietEnabled: quietEnabled,
      quietStart: quietStart,
      quietEnd: quietEnd,
    );
  }

  NotificationPreferences withGlobals({
    bool? vibrate,
    Object? sound = _unset,
    bool? quietEnabled,
    TimeOfDay? quietStart,
    TimeOfDay? quietEnd,
  }) =>
      NotificationPreferences(
        matrix: matrix,
        vibrate: vibrate ?? this.vibrate,
        sound: identical(sound, _unset) ? this.sound : sound as String?,
        quietEnabled: quietEnabled ?? this.quietEnabled,
        quietStart: quietStart ?? this.quietStart,
        quietEnd: quietEnd ?? this.quietEnd,
      );

  static const _unset = Object();
}

class NotificationPreferencesResult {
  final bool success;
  final NotificationPreferences? prefs;
  final String? message;
  NotificationPreferencesResult({required this.success, this.prefs, this.message});
}

class NotificationPreferencesService {
  final int currentUserId;
  NotificationPreferencesService(this.currentUserId);

  Future<String?> _token() async {
    final storage = await LocalStorageService.getInstance();
    return storage.getAuthToken();
  }

  Future<Map<String, String>> _headers() async {
    final t = await _token();
    return t != null ? ApiConfig.authHeaders(t) : ApiConfig.headers;
  }

  Future<NotificationPreferencesResult> load() async {
    try {
      final token = await _token();
      if (token == null) {
        return NotificationPreferencesResult(success: false, message: 'not_signed_in');
      }
      final r = await http.get(
        Uri.parse(
          '${ApiConfig.baseUrl}/notification-preferences?user_id=$currentUserId',
        ),
        headers: ApiConfig.authHeaders(token),
      );
      if (r.statusCode == 200) {
        final body = jsonDecode(r.body) as Map<String, dynamic>;
        final data = (body['data'] as Map<String, dynamic>?) ?? const {};
        return NotificationPreferencesResult(
          success: true,
          prefs: NotificationPreferences.fromJson(data),
        );
      }
      return NotificationPreferencesResult(success: false, message: 'load_failed');
    } catch (_) {
      return NotificationPreferencesResult(success: false, message: 'load_failed');
    }
  }

  /// PATCH any field set; returns the authoritative server state.
  Future<NotificationPreferences?> patch(Map<String, dynamic> fields) async {
    try {
      final r = await http.patch(
        Uri.parse('${ApiConfig.baseUrl}/notification-preferences'),
        headers: {
          ...await _headers(),
          'Content-Type': 'application/json',
        },
        body: jsonEncode({
          'user_id': currentUserId,
          ...fields,
        }),
      );
      if (r.statusCode >= 200 && r.statusCode < 300) {
        final body = jsonDecode(r.body) as Map<String, dynamic>;
        final data = (body['data'] as Map<String, dynamic>?) ?? const {};
        return NotificationPreferences.fromJson(data);
      }
      return null;
    } catch (_) {
      return null;
    }
  }

  Future<NotificationPreferences?> resetToDefaults() async {
    try {
      final r = await http.post(
        Uri.parse('${ApiConfig.baseUrl}/notification-preferences/reset'),
        headers: {
          ...await _headers(),
          'Content-Type': 'application/json',
        },
        body: jsonEncode({'user_id': currentUserId}),
      );
      if (r.statusCode >= 200 && r.statusCode < 300) {
        final body = jsonDecode(r.body) as Map<String, dynamic>;
        final data = (body['data'] as Map<String, dynamic>?) ?? const {};
        return NotificationPreferences.fromJson(data);
      }
      return null;
    } catch (_) {
      return null;
    }
  }
}

String formatHHmm(TimeOfDay t) =>
    '${t.hour.toString().padLeft(2, '0')}:${t.minute.toString().padLeft(2, '0')}';
