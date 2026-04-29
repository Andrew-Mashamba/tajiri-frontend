import 'dart:convert';

import 'food_season.dart';

class FoodPreferences {
  final int userId;
  final List<String> dietaryTags;
  final List<String> allergens;
  final String? defaultWard;
  final double? maxDeliveryRadiusKm;
  final String defaultPaymentMethod;
  final List<String> notificationCategories;
  final String? quietHoursStart;
  final String? quietHoursEnd;
  final bool showSaidiaRail;
  final String autoTagZakat;
  final String autoTagFungu;
  final bool hideOnLeaderboard;
  final bool hideFromCommunityFeed;

  FoodPreferences({
    required this.userId,
    required this.dietaryTags,
    required this.allergens,
    required this.defaultWard,
    required this.maxDeliveryRadiusKm,
    required this.defaultPaymentMethod,
    required this.notificationCategories,
    required this.quietHoursStart,
    required this.quietHoursEnd,
    required this.showSaidiaRail,
    required this.autoTagZakat,
    required this.autoTagFungu,
    required this.hideOnLeaderboard,
    required this.hideFromCommunityFeed,
  });

  FoodPreferences copyWith({
    List<String>? dietaryTags,
    List<String>? allergens,
    String? defaultWard,
    double? maxDeliveryRadiusKm,
    String? defaultPaymentMethod,
    List<String>? notificationCategories,
    String? quietHoursStart,
    String? quietHoursEnd,
    bool? showSaidiaRail,
    String? autoTagZakat,
    String? autoTagFungu,
    bool? hideOnLeaderboard,
    bool? hideFromCommunityFeed,
  }) {
    return FoodPreferences(
      userId: userId,
      dietaryTags: dietaryTags ?? this.dietaryTags,
      allergens: allergens ?? this.allergens,
      defaultWard: defaultWard ?? this.defaultWard,
      maxDeliveryRadiusKm: maxDeliveryRadiusKm ?? this.maxDeliveryRadiusKm,
      defaultPaymentMethod: defaultPaymentMethod ?? this.defaultPaymentMethod,
      notificationCategories: notificationCategories ?? this.notificationCategories,
      quietHoursStart: quietHoursStart ?? this.quietHoursStart,
      quietHoursEnd: quietHoursEnd ?? this.quietHoursEnd,
      showSaidiaRail: showSaidiaRail ?? this.showSaidiaRail,
      autoTagZakat: autoTagZakat ?? this.autoTagZakat,
      autoTagFungu: autoTagFungu ?? this.autoTagFungu,
      hideOnLeaderboard: hideOnLeaderboard ?? this.hideOnLeaderboard,
      hideFromCommunityFeed: hideFromCommunityFeed ?? this.hideFromCommunityFeed,
    );
  }

  /// Resolve `auto_tag_zakat` ('yes'|'ramadan_only'|'ask'|'no') to a prefill
  /// bool. `seasonDefault` is the context-driven default (e.g. true on the
  /// Ramadhan seasonal page) used when the user setting is 'ask'.
  bool resolveAutoTagZakat({DateTime? now, bool seasonDefault = false}) {
    switch (autoTagZakat) {
      case 'yes':
        return true;
      case 'no':
        return false;
      case 'ramadan_only':
        return FoodSeasonDetector.detect(now) == FoodSeason.ramadhan;
      default:
        return seasonDefault;
    }
  }

  /// Resolve `auto_tag_fungu` ('yes'|'sunday_only'|'ask'|'no') to a prefill
  /// bool. `seasonDefault` covers Christmas/Easter/Sunday surfaces where
  /// fungu la kumi is the natural default.
  bool resolveAutoTagFungu({DateTime? now, bool seasonDefault = false}) {
    switch (autoTagFungu) {
      case 'yes':
        return true;
      case 'no':
        return false;
      case 'sunday_only':
        return (now ?? DateTime.now()).weekday == DateTime.sunday;
      default:
        return seasonDefault;
    }
  }

  factory FoodPreferences.fromJson(Map<String, dynamic> json) {
    return FoodPreferences(
      userId: _parseInt(json['user_id']) ?? 0,
      dietaryTags: _parseStringList(json['dietary_tags']),
      allergens: _parseStringList(json['allergens']),
      defaultWard: json['default_ward']?.toString(),
      maxDeliveryRadiusKm: _parseDouble(json['max_delivery_radius_km']),
      defaultPaymentMethod: json['default_payment_method']?.toString() ?? 'wallet',
      notificationCategories: _parseStringList(json['notification_categories']),
      quietHoursStart: json['quiet_hours_start']?.toString(),
      quietHoursEnd: json['quiet_hours_end']?.toString(),
      showSaidiaRail: _parseBool(json['show_saidia_rail'], defaultValue: true),
      autoTagZakat: json['auto_tag_zakat']?.toString() ?? 'ask',
      autoTagFungu: json['auto_tag_fungu']?.toString() ?? 'ask',
      hideOnLeaderboard: _parseBool(json['hide_on_leaderboard']),
      hideFromCommunityFeed: _parseBool(json['hide_from_community_feed']),
    );
  }
}

int? _parseInt(dynamic v) {
  if (v == null) return null;
  if (v is int) return v;
  if (v is num) return v.toInt();
  if (v is String) return int.tryParse(v);
  return null;
}

double? _parseDouble(dynamic v) {
  if (v == null) return null;
  if (v is double) return v;
  if (v is num) return v.toDouble();
  if (v is String) return double.tryParse(v);
  return null;
}

bool _parseBool(dynamic v, {bool defaultValue = false}) {
  if (v == null) return defaultValue;
  if (v is bool) return v;
  if (v is num) return v != 0;
  if (v is String) return v == '1' || v.toLowerCase() == 'true' || v == 't';
  return defaultValue;
}

List<String> _parseStringList(dynamic v) {
  if (v == null) return <String>[];
  if (v is List) return v.map((e) => e.toString()).toList();
  if (v is String) {
    if (v.isEmpty) return <String>[];
    try {
      final decoded = jsonDecode(v);
      if (decoded is List) return decoded.map((e) => e.toString()).toList();
    } catch (_) {
      return <String>[];
    }
  }
  return <String>[];
}
