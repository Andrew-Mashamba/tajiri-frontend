import 'dart:convert';
import 'package:flutter/foundation.dart';
import 'package:hive_flutter/hive_flutter.dart';
import '../models/people_search_models.dart';
import 'people_search_service.dart';
import 'perf_logger.dart';

/// Hive-backed cache for people discovery results.
/// Stores the initial discovery page so returning users see people instantly.
class PeopleCacheService {
  PeopleCacheService._();
  static final PeopleCacheService instance = PeopleCacheService._();

  static const String _boxName = 'people_cache';
  static const String _discoveryKey = 'discovery';
  static const String _metaKey = 'discovery_meta';
  static const int _maxCached = 40;

  Box<String>? _box;

  Future<Box<String>> _getBox() async {
    _box ??= await Hive.openBox<String>(_boxName);
    return _box!;
  }

  /// Save discovery results to cache.
  Future<void> saveDiscovery(List<PersonSearchResult> people) async {
    try {
      final box = await _getBox();
      final limited = people.take(_maxCached).toList();
      await box.put(_discoveryKey, jsonEncode(limited.map((p) => p.toJson()).toList()));
      await box.put(_metaKey, DateTime.now().toIso8601String());
      if (kDebugMode) debugPrint('[PeopleCache] Saved ${limited.length} discovery results');
    } catch (e) {
      if (kDebugMode) debugPrint('[PeopleCache] Save error: $e');
    }
  }

  /// Load cached discovery results. Returns null if no cache.
  Future<List<PersonSearchResult>?> getDiscovery() async {
    try {
      final box = await _getBox();
      final jsonStr = box.get(_discoveryKey);
      if (jsonStr == null) return null;
      final list = jsonDecode(jsonStr) as List<dynamic>;
      return list
          .map((e) => PersonSearchResult.fromJson(e as Map<String, dynamic>))
          .toList();
    } catch (e) {
      if (kDebugMode) debugPrint('[PeopleCache] Load error: $e');
      return null;
    }
  }

  /// When was the discovery cache last saved?
  Future<DateTime?> getLastFetchTime() async {
    try {
      final box = await _getBox();
      final ts = box.get(_metaKey);
      return ts != null ? DateTime.tryParse(ts) : null;
    } catch (_) {
      return null;
    }
  }

  /// Prefetch discovery page 1 in the background and save to cache.
  /// Only warms if the last fetch was more than 5 minutes ago.
  /// Call from app startup to ensure instant People tab load.
  Future<void> warmCache(int userId) async {
    try {
      final lastFetch = await getLastFetchTime();
      if (lastFetch != null) {
        final age = DateTime.now().difference(lastFetch);
        if (age.inMinutes < 5) {
          PerfLogger.log('people_cache_warm_skip', {'age_sec': age.inSeconds});
          return;
        }
      }

      PerfLogger.log('people_cache_warm_start');
      final sw = PerfLogger.startTiming();

      final service = PeopleSearchService();
      final result = await service.search(userId: userId, page: 1, perPage: 20);

      if (result.success && result.response != null && result.response!.people.isNotEmpty) {
        await saveDiscovery(result.response!.people);
        PerfLogger.endTiming(sw, 'people_cache_warm_done', {
          'count': result.response!.people.length,
        });
      } else {
        PerfLogger.endTiming(sw, 'people_cache_warm_empty');
      }
    } catch (e) {
      if (kDebugMode) debugPrint('[PeopleCache] warmCache error: $e');
    }
  }

  /// Clear all people caches.
  Future<void> clear() async {
    try {
      final box = await _getBox();
      await box.clear();
    } catch (_) {}
  }
}
