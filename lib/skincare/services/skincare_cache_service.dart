// Hive-backed cache for Skin Care home data — stale-while-revalidate (see docs/PERFORMANCE_STRATEGY.md).
// Not SQLite: docs/SQLITE_ADOPTION_ROADMAP.md — profile-sized payloads suit Hive + TTL, not relational SQLite.
import 'dart:convert';

import 'package:flutter/foundation.dart';
import 'package:hive_flutter/hive_flutter.dart';

import '../models/skincare_models.dart';

class SkincareHomeSnapshot {
  SkincareHomeSnapshot({
    required this.cachedAt,
    this.profile,
    this.routines = const [],
    this.diaryMonthEntries = const [],
    this.recommendations = const [],
  });

  final DateTime cachedAt;
  final SkinProfile? profile;
  final List<SkincareRoutine> routines;
  final List<SkinDiaryEntry> diaryMonthEntries;
  final List<SkinProduct> recommendations;
}

/// TTL after which UI should prefer refreshing from network (still shows cache immediately).
const Duration skincareCacheTtl = Duration(minutes: 5);

class SkincareCacheService {
  SkincareCacheService._();
  static final SkincareCacheService instance = SkincareCacheService._();

  static const String _boxName = 'skincare_cache';
  static const String _homeKeyPrefix = 'skincare_home_v1_';
  static const String _prefsKeyPrefix = 'skincare_prefs_v1_';
  static const String _pendingProfilePrefix = 'skincare_pending_profile_v1_';
  static const String _ingredientHistoryKey = 'skincare_ingredient_history_v1';
  static const String _routineStreakPrefix = 'skincare_routine_streak_v1_';

  Box<String>? _box;

  Future<Box<String>> _getBox() async {
    _box ??= await Hive.openBox<String>(_boxName);
    return _box!;
  }

  String _homeKey(int userId) => '$_homeKeyPrefix$userId';

  Future<void> saveHomeSnapshot({
    required int userId,
    SkinProfile? profile,
    required List<SkincareRoutine> routines,
    required List<SkinDiaryEntry> diaryMonthEntries,
    required List<SkinProduct> recommendations,
  }) async {
    try {
      final box = await _getBox();
      final map = <String, dynamic>{
        'cached_at': DateTime.now().toIso8601String(),
        'profile': profile == null ? null : _profileToMap(profile),
        'routines': routines.map(_routineToMap).toList(),
        'diary': diaryMonthEntries.map(_diaryToMap).toList(),
        'recommendations': recommendations.map(_productToMap).toList(),
      };
      await box.put(_homeKey(userId), jsonEncode(map));
      if (kDebugMode) {
        debugPrint('[SkincareCache] Saved home snapshot for user $userId');
      }
    } catch (e) {
      if (kDebugMode) debugPrint('[SkincareCache] Save error: $e');
    }
  }

  Future<SkincareHomeSnapshot?> loadHomeSnapshot(int userId) async {
    try {
      final box = await _getBox();
      final json = box.get(_homeKey(userId));
      if (json == null || json.isEmpty) return null;
      final map = jsonDecode(json) as Map<String, dynamic>?;
      if (map == null) return null;
      final cachedAt = DateTime.tryParse(map['cached_at'] as String? ?? '') ?? DateTime.now();
      SkinProfile? profile;
      final p = map['profile'];
      if (p is Map<String, dynamic>) {
        profile = SkinProfile.fromJson(p);
      }
      final routines = <SkincareRoutine>[];
      final rList = map['routines'] as List<dynamic>?;
      if (rList != null) {
        for (final e in rList) {
          if (e is Map<String, dynamic>) {
            try {
              routines.add(SkincareRoutine.fromJson(e));
            } catch (_) {}
          }
        }
      }
      final diary = <SkinDiaryEntry>[];
      final dList = map['diary'] as List<dynamic>?;
      if (dList != null) {
        for (final e in dList) {
          if (e is Map<String, dynamic>) {
            try {
              diary.add(SkinDiaryEntry.fromJson(e));
            } catch (_) {}
          }
        }
      }
      final recs = <SkinProduct>[];
      final recList = map['recommendations'] as List<dynamic>?;
      if (recList != null) {
        for (final e in recList) {
          if (e is Map<String, dynamic>) {
            try {
              recs.add(SkinProduct.fromJson(e));
            } catch (_) {}
          }
        }
      }
      return SkincareHomeSnapshot(
        cachedAt: cachedAt,
        profile: profile,
        routines: routines,
        diaryMonthEntries: diary,
        recommendations: recs,
      );
    } catch (e) {
      if (kDebugMode) debugPrint('[SkincareCache] Load error: $e');
      return null;
    }
  }

  bool isStale(DateTime cachedAt) {
    return DateTime.now().difference(cachedAt) > skincareCacheTtl;
  }

  Future<void> clear() async {
    try {
      final box = await _getBox();
      await box.deleteAll(box.keys);
      if (kDebugMode) debugPrint('[SkincareCache] Cleared');
    } catch (e) {
      if (kDebugMode) debugPrint('[SkincareCache] Clear error: $e');
    }
  }

  Map<String, dynamic> _profileToMap(SkinProfile p) => {
        'id': p.id,
        'user_id': p.userId,
        'skin_type': p.skinType.name,
        'skin_tone': p.skinTone,
        'concerns': p.concerns.map((c) => c.name).toList(),
        'score': p.score,
        'climate_zone': p.climateZone.name,
        'budget': p.budget,
        'last_analysis_date': p.lastAnalysisDate?.toIso8601String(),
      };

  Map<String, dynamic> _routineToMap(SkincareRoutine r) => {
        'id': r.id,
        'user_id': r.userId,
        'name': r.name,
        'type': r.type.name,
        'steps': r.steps.map((s) => s.toJson()).toList(),
        'is_active': r.isActive,
      };

  Map<String, dynamic> _diaryToMap(SkinDiaryEntry e) => {
        'id': e.id,
        'user_id': e.userId,
        'date': e.date.toIso8601String().split('T').first,
        'mood': e.mood,
        'tags': e.tags,
        'products_used': e.productsUsed,
        'notes': e.notes,
        'photo_url': e.photoUrl,
      };

  String _prefsKey(int userId) => '$_prefsKeyPrefix$userId';
  String _pendingProfileKey(int userId) => '$_pendingProfilePrefix$userId';
  String _streakKey(int userId) => '$_routineStreakPrefix$userId';

  // ─── Reminder prefs (Hive JSON) ───────────────────────────────

  Future<SkincareReminderPrefs> loadReminderPrefs(int userId) async {
    try {
      final box = await _getBox();
      final raw = box.get(_prefsKey(userId));
      if (raw == null || raw.isEmpty) return const SkincareReminderPrefs();
      final map = jsonDecode(raw) as Map<String, dynamic>?;
      if (map == null) return const SkincareReminderPrefs();
      return SkincareReminderPrefs.fromJson(map);
    } catch (_) {
      return const SkincareReminderPrefs();
    }
  }

  Future<void> saveReminderPrefs(int userId, SkincareReminderPrefs prefs) async {
    try {
      final box = await _getBox();
      await box.put(_prefsKey(userId), jsonEncode(prefs.toJson()));
    } catch (e) {
      if (kDebugMode) debugPrint('[SkincareCache] saveReminderPrefs: $e');
    }
  }

  // ─── Offline profile queue (POST body map) ──────────────────

  Future<void> enqueuePendingProfile(int userId, Map<String, dynamic> body) async {
    try {
      final box = await _getBox();
      await box.put(_pendingProfileKey(userId), jsonEncode(body));
    } catch (e) {
      if (kDebugMode) debugPrint('[SkincareCache] enqueuePendingProfile: $e');
    }
  }

  Future<Map<String, dynamic>?> peekPendingProfile(int userId) async {
    try {
      final box = await _getBox();
      final raw = box.get(_pendingProfileKey(userId));
      if (raw == null || raw.isEmpty) return null;
      return Map<String, dynamic>.from(jsonDecode(raw) as Map);
    } catch (_) {
      return null;
    }
  }

  Future<void> clearPendingProfile(int userId) async {
    try {
      final box = await _getBox();
      await box.delete(_pendingProfileKey(userId));
    } catch (_) {}
  }

  // ─── Ingredient check history (device) ───────────────────────

  Future<List<IngredientHistoryItem>> loadIngredientHistory({int limit = 30}) async {
    try {
      final box = await _getBox();
      final raw = box.get(_ingredientHistoryKey);
      if (raw == null || raw.isEmpty) return [];
      final list = jsonDecode(raw) as List<dynamic>? ?? [];
      final out = <IngredientHistoryItem>[];
      for (final e in list) {
        if (e is Map<String, dynamic>) {
          out.add(IngredientHistoryItem.fromJson(e));
        }
      }
      if (out.length > limit) return out.sublist(0, limit);
      return out;
    } catch (_) {
      return [];
    }
  }

  Future<void> prependIngredientHistory(IngredientHistoryItem item) async {
    try {
      final existing = await loadIngredientHistory(limit: 100);
      final next = [item, ...existing.where((x) => x.query != item.query || x.checkedAt.difference(item.checkedAt).inSeconds.abs() > 2)];
      final box = await _getBox();
      await box.put(
        _ingredientHistoryKey,
        jsonEncode(next.take(50).map((e) => e.toJson()).toList()),
      );
    } catch (e) {
      if (kDebugMode) debugPrint('[SkincareCache] prependIngredientHistory: $e');
    }
  }

  // ─── Routine completion streak ───────────────────────────────

  Future<void> recordRoutineCompletion(int userId, int routineId) async {
    try {
      final box = await _getBox();
      final key = _streakKey(userId);
      final raw = box.get(key);
      Map<String, dynamic> map = {};
      if (raw != null && raw.isNotEmpty) {
        map = Map<String, dynamic>.from(jsonDecode(raw) as Map);
      }
      final today = _dayKey(DateTime.now());
      map[today] = {
        'routine_id': routineId,
        'completed_at': DateTime.now().toIso8601String(),
      };
      await box.put(key, jsonEncode(map));
    } catch (e) {
      if (kDebugMode) debugPrint('[SkincareCache] recordRoutineCompletion: $e');
    }
  }

  /// Consecutive days (including today) with at least one completion recorded.
  Future<int> currentRoutineStreakDays(int userId) async {
    try {
      final box = await _getBox();
      final raw = box.get(_streakKey(userId));
      if (raw == null || raw.isEmpty) return 0;
      final map = Map<String, dynamic>.from(jsonDecode(raw) as Map);
      var streak = 0;
      var d = DateTime.now();
      for (var i = 0; i < 400; i++) {
        final k = _dayKey(d);
        if (map.containsKey(k)) {
          streak++;
          d = d.subtract(const Duration(days: 1));
        } else {
          break;
        }
      }
      return streak;
    } catch (_) {
      return 0;
    }
  }

  String _dayKey(DateTime d) =>
      '${d.year.toString().padLeft(4, '0')}-${d.month.toString().padLeft(2, '0')}-${d.day.toString().padLeft(2, '0')}';

  Map<String, dynamic> _productToMap(SkinProduct p) => {
        'id': p.id,
        'name': p.name,
        'brand': p.brand,
        'category': p.category,
        'skin_types': p.skinTypes.map((t) => t.name).toList(),
        'concerns': p.concerns.map((c) => c.name).toList(),
        'price': p.price,
        'rating': p.rating,
        'image_url': p.imageUrl,
        'ingredients': p.ingredients,
        'is_tmda_approved': p.isTmdaApproved,
        'description': p.description,
      };
}

/// Local notification toggles + default times (hour local).
class SkincareReminderPrefs {
  const SkincareReminderPrefs({
    this.morningRoutine = true,
    this.eveningRoutine = true,
    this.diaryNudge = true,
    this.weeklyDigest = true,
    this.sunscreenReminder = true,
    this.morningHour = 7,
    this.morningMinute = 0,
    this.eveningHour = 21,
    this.eveningMinute = 0,
    this.diaryHour = 20,
    this.diaryMinute = 0,
    this.weeklyDigestWeekday = DateTime.sunday,
    this.weeklyDigestHour = 18,
    this.weeklyDigestMinute = 0,
  });

  final bool morningRoutine;
  final bool eveningRoutine;
  final bool diaryNudge;
  final bool weeklyDigest;
  final bool sunscreenReminder;
  final int morningHour;
  final int morningMinute;
  final int eveningHour;
  final int eveningMinute;
  final int diaryHour;
  final int diaryMinute;
  final int weeklyDigestWeekday;
  final int weeklyDigestHour;
  final int weeklyDigestMinute;

  factory SkincareReminderPrefs.fromJson(Map<String, dynamic> json) {
    return SkincareReminderPrefs(
      morningRoutine: json['morning_routine'] as bool? ?? true,
      eveningRoutine: json['evening_routine'] as bool? ?? true,
      diaryNudge: json['diary_nudge'] as bool? ?? true,
      weeklyDigest: json['weekly_digest'] as bool? ?? true,
      sunscreenReminder: json['sunscreen'] as bool? ?? true,
      morningHour: (json['morning_h'] as num?)?.toInt() ?? 7,
      morningMinute: (json['morning_m'] as num?)?.toInt() ?? 0,
      eveningHour: (json['evening_h'] as num?)?.toInt() ?? 21,
      eveningMinute: (json['evening_m'] as num?)?.toInt() ?? 0,
      diaryHour: (json['diary_h'] as num?)?.toInt() ?? 20,
      diaryMinute: (json['diary_m'] as num?)?.toInt() ?? 0,
      weeklyDigestWeekday: (json['digest_wd'] as num?)?.toInt() ?? DateTime.sunday,
      weeklyDigestHour: (json['digest_h'] as num?)?.toInt() ?? 18,
      weeklyDigestMinute: (json['digest_m'] as num?)?.toInt() ?? 0,
    );
  }

  Map<String, dynamic> toJson() => {
        'morning_routine': morningRoutine,
        'evening_routine': eveningRoutine,
        'diary_nudge': diaryNudge,
        'weekly_digest': weeklyDigest,
        'sunscreen': sunscreenReminder,
        'morning_h': morningHour,
        'morning_m': morningMinute,
        'evening_h': eveningHour,
        'evening_m': eveningMinute,
        'diary_h': diaryHour,
        'diary_m': diaryMinute,
        'digest_wd': weeklyDigestWeekday,
        'digest_h': weeklyDigestHour,
        'digest_m': weeklyDigestMinute,
      };
}

class IngredientHistoryItem {
  IngredientHistoryItem({
    required this.query,
    required this.checkedAt,
    required this.dangerCount,
    required this.cautionCount,
  });

  final String query;
  final DateTime checkedAt;
  final int dangerCount;
  final int cautionCount;

  factory IngredientHistoryItem.fromJson(Map<String, dynamic> json) {
    return IngredientHistoryItem(
      query: json['query']?.toString() ?? '',
      checkedAt: DateTime.tryParse(json['at']?.toString() ?? '') ?? DateTime.now(),
      dangerCount: (json['d'] as num?)?.toInt() ?? 0,
      cautionCount: (json['c'] as num?)?.toInt() ?? 0,
    );
  }

  Map<String, dynamic> toJson() => {
        'query': query,
        'at': checkedAt.toIso8601String(),
        'd': dangerCount,
        'c': cautionCount,
      };
}
