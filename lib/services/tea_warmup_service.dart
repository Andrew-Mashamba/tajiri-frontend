import 'dart:async';
import 'package:flutter/material.dart';
import '../models/tea_models.dart';
import 'tea_service.dart';
import 'local_storage_service.dart';

/// Pre-warms Shangazi Tea conversations so the first response is ready
/// when the user opens the Tea tab.
class TeaWarmupService {
  TeaWarmupService._();
  static final TeaWarmupService instance = TeaWarmupService._();

  TeaChatResponse? _cachedResponse;
  DateTime? _cachedAt;
  Timer? _refreshTimer;
  bool _warming = false;

  static const _staleAfter = Duration(minutes: 5);
  static const _refreshInterval = Duration(minutes: 5);

  /// Fire-and-forget: starts a background chat request and caches the result.
  /// Safe to call multiple times — skips if already warming.
  void warmUp() {
    if (_warming) return;
    _warming = true;
    _fetchAndCache().whenComplete(() => _warming = false);

    // Periodic refresh so cache stays fresh
    _refreshTimer?.cancel();
    _refreshTimer = Timer.periodic(_refreshInterval, (_) {
      if (!_warming && _cachedResponse != null) {
        _warming = true;
        _fetchAndCache().whenComplete(() => _warming = false);
      }
    });
  }

  Future<void> _fetchAndCache() async {
    try {
      final storage = await LocalStorageService.getInstance();
      final token = storage.getAuthToken();
      if (token == null) return;
      final userId = storage.getUser()?.userId;

      final response = await TeaService.startChat(token, userId: userId);
      if (response != null) {
        _cachedResponse = response;
        _cachedAt = DateTime.now();
        debugPrint('[TeaWarmup] cached response conv=${response.conversationId}');
      }
    } catch (e) {
      debugPrint('[TeaWarmup] warmUp failed: $e');
    }
  }

  /// Returns cached response if fresh, then clears cache.
  /// Returns null if no cache or cache is stale.
  TeaChatResponse? consume() {
    if (_cachedResponse == null || _cachedAt == null) return null;

    final age = DateTime.now().difference(_cachedAt!);
    if (age > _staleAfter) {
      debugPrint('[TeaWarmup] cache stale (${age.inSeconds}s), discarding');
      _cachedResponse = null;
      _cachedAt = null;
      return null;
    }

    final response = _cachedResponse;
    _cachedResponse = null;
    _cachedAt = null;
    _refreshTimer?.cancel();
    _refreshTimer = null;
    debugPrint('[TeaWarmup] consumed cached response');
    return response;
  }

  /// Clear cache and stop refresh timer. Call on logout.
  void reset() {
    _cachedResponse = null;
    _cachedAt = null;
    _refreshTimer?.cancel();
    _refreshTimer = null;
    _warming = false;
    debugPrint('[TeaWarmup] reset');
  }
}
