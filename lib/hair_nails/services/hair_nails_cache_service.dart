// Hive-backed cache for Hair & Nails home — stale-while-revalidate (docs/PERFORMANCE_STRATEGY.md).
// Not SQLite: docs/SQLITE_ADOPTION_ROADMAP.md — dashboard-sized JSON suits Hive + TTL, not relational SQLite.
import 'dart:convert';

import 'package:flutter/foundation.dart';
import 'package:hive_flutter/hive_flutter.dart';

import '../models/hair_nails_models.dart';

/// TTL after which UI should still show cache but mark refresh as preferred.
const Duration hairNailsCacheTtl = Duration(minutes: 5);

class HairNailsHomeSnapshot {
  HairNailsHomeSnapshot({
    required this.cachedAt,
    this.profile,
    this.bookings = const [],
    this.styles = const [],
    this.salons = const [],
  });

  final DateTime cachedAt;
  final HairProfile? profile;
  final List<Booking> bookings;
  final List<StyleInspiration> styles;
  final List<Salon> salons;
}

class HairNailsCacheService {
  HairNailsCacheService._();
  static final HairNailsCacheService instance = HairNailsCacheService._();

  static const String _boxName = 'hair_nails_cache';
  static const String _homeKeyPrefix = 'hair_nails_home_v1_';
  static const String _prefsKeyPrefix = 'hair_nails_prefs_v1_';
  static const String _pendingProfilePrefix = 'hair_nails_pending_profile_v1_';

  Box<String>? _box;

  Future<Box<String>> _getBox() async {
    _box ??= await Hive.openBox<String>(_boxName);
    return _box!;
  }

  String _homeKey(int userId) => '$_homeKeyPrefix$userId';

  Future<void> saveHomeSnapshot({
    required int userId,
    HairProfile? profile,
    required List<Booking> bookings,
    required List<StyleInspiration> styles,
    required List<Salon> salons,
  }) async {
    try {
      final box = await _getBox();
      final map = <String, dynamic>{
        'cached_at': DateTime.now().toIso8601String(),
        'profile': profile?.toJson(),
        'bookings': bookings.map((b) => b.toJson()).toList(),
        'styles': styles.map((s) => s.toJson()).toList(),
        'salons': salons.map((s) => s.toJson()).toList(),
      };
      await box.put(_homeKey(userId), jsonEncode(map));
      if (kDebugMode) debugPrint('[HairNailsCache] Saved home snapshot for user $userId');
    } catch (e) {
      if (kDebugMode) debugPrint('[HairNailsCache] Save error: $e');
    }
  }

  Future<HairNailsHomeSnapshot?> loadHomeSnapshot(int userId) async {
    try {
      final box = await _getBox();
      final json = box.get(_homeKey(userId));
      if (json == null || json.isEmpty) return null;
      final map = jsonDecode(json) as Map<String, dynamic>?;
      if (map == null) return null;
      final cachedAt = DateTime.tryParse(map['cached_at'] as String? ?? '') ?? DateTime.now();
      HairProfile? profile;
      final p = map['profile'];
      if (p is Map<String, dynamic>) {
        profile = HairProfile.fromJson(p);
      }
      final bookings = (map['bookings'] as List?)
              ?.map((e) => Booking.fromJson(Map<String, dynamic>.from(e as Map)))
              .toList() ??
          [];
      final styles = (map['styles'] as List?)
              ?.map((e) => StyleInspiration.fromJson(Map<String, dynamic>.from(e as Map)))
              .toList() ??
          [];
      final salons = (map['salons'] as List?)
              ?.map((e) => Salon.fromJson(Map<String, dynamic>.from(e as Map)))
              .toList() ??
          [];
      return HairNailsHomeSnapshot(
        cachedAt: cachedAt,
        profile: profile,
        bookings: bookings,
        styles: styles,
        salons: salons,
      );
    } catch (e) {
      if (kDebugMode) debugPrint('[HairNailsCache] Load error: $e');
      return null;
    }
  }

  Future<void> setLastGrowthLogIso(int userId, String? iso) async {
    try {
      final box = await _getBox();
      await box.put('$_prefsKeyPrefix${userId}_last_growth', iso ?? '');
    } catch (_) {}
  }

  String _pendingProfileKey(int userId) => '$_pendingProfilePrefix$userId';

  /// Offline queue: POST body for [HairNailsService.saveHairProfile].
  Future<void> enqueuePendingProfile(int userId, Map<String, dynamic> body) async {
    try {
      final box = await _getBox();
      await box.put(_pendingProfileKey(userId), jsonEncode(body));
    } catch (e) {
      if (kDebugMode) debugPrint('[HairNailsCache] enqueuePendingProfile: $e');
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

  Future<void> setGrowthPhotosPrivate(int userId, bool value) async {
    try {
      final box = await _getBox();
      await box.put('$_prefsKeyPrefix${userId}_growth_privacy', value ? '1' : '0');
    } catch (_) {}
  }

  Future<bool> getGrowthPhotosPrivate(int userId) async {
    try {
      final box = await _getBox();
      final s = box.get('$_prefsKeyPrefix${userId}_growth_privacy');
      return s == '1';
    } catch (_) {
      return false;
    }
  }

  Future<DateTime?> getLastGrowthLogTime(int userId) async {
    try {
      final box = await _getBox();
      final s = box.get('$_prefsKeyPrefix${userId}_last_growth');
      if (s == null || s.isEmpty) return null;
      return DateTime.tryParse(s);
    } catch (_) {
      return null;
    }
  }

  Future<void> clear(int userId) async {
    try {
      final box = await _getBox();
      await box.delete(_homeKey(userId));
    } catch (_) {}
  }

  /// Called on logout (same pattern as [SkincareCacheService.clear]).
  Future<void> clearAll() async {
    try {
      final box = await _getBox();
      await box.deleteAll(box.keys);
      if (kDebugMode) debugPrint('[HairNailsCache] Cleared all');
    } catch (e) {
      if (kDebugMode) debugPrint('[HairNailsCache] Clear error: $e');
    }
  }
}
