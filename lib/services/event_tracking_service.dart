import 'dart:async';
import 'dart:convert';
import 'dart:math' as math;
import 'package:flutter/foundation.dart';
import 'package:flutter/widgets.dart';
import 'package:hive_flutter/hive_flutter.dart';
import 'package:http/http.dart' as http;
import '../config/api_config.dart';
import '../models/flywheel_models.dart';
import 'local_storage_service.dart';

/// Singleton service that captures user behavior events for the Flywheel engine.
///
/// Pattern: same as [LocalStorageService] — private constructor, async getInstance().
/// - Maintains in-memory event buffer
/// - Flushes to POST /api/events every 30 seconds
/// - On app background: immediate flush via WidgetsBindingObserver
/// - Offline: queues to Hive, flushes on reconnect
/// - Max batch: 100 events per flush
/// - Discards events older than 24 hours
class EventTrackingService with WidgetsBindingObserver {
  static const String _hiveBoxName = 'event_queue';
  static const int _flushIntervalSeconds = 10;
  static const int _maxBatchSize = 100;
  static const int _maxEventAgeHours = 24;

  static EventTrackingService? _instance;

  final List<UserEvent> _buffer = [];
  late final String _sessionId;
  Timer? _flushTimer;
  Box? _offlineBox;
  bool _isInitialized = false;
  bool _isFlushing = false;
  final bool _isTestMode;

  EventTrackingService._() : _isTestMode = false {
    _sessionId = _generateSessionId();
  }

  EventTrackingService._testing() : _isTestMode = true {
    _sessionId = _generateSessionId();
    _isInitialized = true;
  }

  /// Get the singleton instance. Call after Hive.initFlutter().
  static Future<EventTrackingService> getInstance() async {
    if (_instance == null) {
      _instance = EventTrackingService._();
      await _instance!._init();
    }
    return _instance!;
  }

  /// Create a test-only instance (no Hive, no timer, no lifecycle observer).
  factory EventTrackingService.createForTesting() {
    return EventTrackingService._testing();
  }

  Future<void> _init() async {
    if (_isInitialized) return;
    _offlineBox = await Hive.openBox(_hiveBoxName);

    // Restore any offline-queued events
    _restoreOfflineEvents();

    // Start periodic flush
    _flushTimer = Timer.periodic(
      const Duration(seconds: _flushIntervalSeconds),
      (_) => flush(),
    );

    // Observe app lifecycle for background flush
    WidgetsBinding.instance.addObserver(this);
    _isInitialized = true;
  }

  String get sessionId => _sessionId;

  int get bufferSize => _buffer.length;

  /// Track a user behavior event.
  void trackEvent({
    required String eventType,
    int? postId,
    int? creatorId,
    int durationMs = 0,
    Map<String, dynamic>? metadata,
  }) {
    final event = UserEvent(
      eventType: eventType,
      postId: postId,
      creatorId: creatorId,
      timestamp: DateTime.now(),
      durationMs: durationMs,
      sessionId: _sessionId,
      metadata: metadata,
    );
    _buffer.add(event);
  }

  /// Track a content view with dwell time measurement.
  void trackView({required int postId, required int creatorId, required int dwellMs}) {
    final eventType = dwellMs < 500 ? 'view_glance' : (dwellMs < 3000 ? 'view_partial' : 'view_deep');
    trackEvent(eventType: eventType, postId: postId, creatorId: creatorId, durationMs: dwellMs);
  }

  /// Track when a user scrolls past content quickly (< 500ms visible).
  void trackScrollPast({required int postId, required int creatorId}) {
    trackEvent(eventType: 'scroll_past', postId: postId, creatorId: creatorId);
  }

  /// Track explicit "not interested" signal.
  void trackNotInterested({required int postId, required int creatorId}) {
    trackEvent(eventType: 'not_interested', postId: postId, creatorId: creatorId);
  }

  /// For testing: add an event directly.
  void addEventDirectly(UserEvent event) {
    _buffer.add(event);
  }

  /// Drain up to [maxBatch] events from the buffer, discarding events older than 24h.
  List<UserEvent> drainBuffer({int maxBatch = _maxBatchSize}) {
    final cutoff = DateTime.now().subtract(const Duration(hours: _maxEventAgeHours));
    _buffer.removeWhere((e) => e.timestamp.isBefore(cutoff));

    if (_buffer.isEmpty) return [];

    final count = _buffer.length < maxBatch ? _buffer.length : maxBatch;
    final drained = _buffer.sublist(0, count);
    _buffer.removeRange(0, count);
    return drained;
  }

  /// Flush buffered events to the backend.
  Future<void> flush() async {
    if (_isFlushing || _buffer.isEmpty) return;
    _isFlushing = true;

    try {
      final events = drainBuffer();
      if (events.isEmpty) return;

      final storage = await LocalStorageService.getInstance();
      final token = storage.getAuthToken();
      if (token == null) {
        _queueOffline(events);
        return;
      }

      final success = await _postEvents(events, token);
      if (!success) {
        _queueOffline(events);
      }
    } catch (e) {
      if (kDebugMode) debugPrint('[EventTracking] Flush error: $e');
    } finally {
      _isFlushing = false;
    }
  }

  Future<bool> _postEvents(List<UserEvent> events, String token) async {
    if (_isTestMode) return true;

    try {
      final url = Uri.parse('${ApiConfig.baseUrl}/events');
      final response = await http.post(
        url,
        headers: ApiConfig.authHeaders(token),
        body: jsonEncode({
          'events': events.map((e) => e.toJson()).toList(),
        }),
      );
      if (kDebugMode) {
        debugPrint('[EventTracking] Flushed ${events.length} events — ${response.statusCode}');
      }
      return response.statusCode == 200 || response.statusCode == 201;
    } catch (e) {
      if (kDebugMode) debugPrint('[EventTracking] POST failed: $e');
      return false;
    }
  }

  void _queueOffline(List<UserEvent> events) {
    if (_offlineBox == null) return;
    for (final event in events) {
      _offlineBox!.add(jsonEncode(event.toJson()));
    }
    if (kDebugMode) {
      debugPrint('[EventTracking] Queued ${events.length} events offline');
    }
  }

  void _restoreOfflineEvents() {
    if (_offlineBox == null || _offlineBox!.isEmpty) return;
    final cutoff = DateTime.now().subtract(const Duration(hours: _maxEventAgeHours));
    int restored = 0;

    for (int i = 0; i < _offlineBox!.length; i++) {
      try {
        final jsonStr = _offlineBox!.getAt(i) as String?;
        if (jsonStr == null) continue;
        final json = jsonDecode(jsonStr) as Map<String, dynamic>;
        final ts = DateTime.tryParse(json['timestamp']?.toString() ?? '');
        if (ts != null && ts.isAfter(cutoff)) {
          _buffer.add(UserEvent(
            eventType: json['event_type'] as String? ?? 'unknown',
            postId: json['post_id'] as int?,
            creatorId: json['creator_id'] as int?,
            timestamp: ts,
            durationMs: (json['duration_ms'] as int?) ?? 0,
            sessionId: json['session_id'] as String? ?? _sessionId,
            metadata: json['metadata'] as Map<String, dynamic>?,
          ));
          restored++;
        }
      } catch (e) {
        if (kDebugMode) debugPrint('[EventTracking] Restore error at $i: $e');
      }
    }

    _offlineBox!.clear();
    if (kDebugMode && restored > 0) {
      debugPrint('[EventTracking] Restored $restored offline events');
    }
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    if (state == AppLifecycleState.paused ||
        state == AppLifecycleState.inactive) {
      flush();
    }
  }

  void dispose() {
    _flushTimer?.cancel();
    if (!_isTestMode) {
      WidgetsBinding.instance.removeObserver(this);
    }
  }

  /// Track Tea tab interactions
  void trackTeaCardTapped(int topicId, String cardType) {
    trackEvent(eventType: 'tea_card_tapped', metadata: {
      'topic_id': topicId,
      'card_type': cardType,
    });
  }

  void trackTeaCardSkipped(int topicId, String cardType) {
    trackEvent(eventType: 'tea_card_skipped', metadata: {
      'topic_id': topicId,
      'card_type': cardType,
    });
  }

  void trackTeaQuestionAsked(String query) {
    trackEvent(eventType: 'tea_question_asked', metadata: {
      'query_text': query,
    });
  }

  void trackTeaActionConfirmed(String actionType, String target) {
    trackEvent(eventType: 'tea_action_confirmed', metadata: {
      'action_type': actionType,
      'target': target,
    });
  }

  void trackTeaActionRejected(String actionType, String target) {
    trackEvent(eventType: 'tea_action_rejected', metadata: {
      'action_type': actionType,
      'target': target,
    });
  }

  /// Track additional signals for profile matrix
  void trackMessageSent(int recipientId, {bool hasMedia = false, String? mediaType}) {
    trackEvent(eventType: 'message_sent', creatorId: recipientId, metadata: {
      'has_media': hasMedia,
      if (mediaType != null) 'media_type': mediaType,
    });
  }

  void trackProfileViewed(int userId, int dwellMs) {
    trackEvent(eventType: 'profile_viewed', creatorId: userId, metadata: {
      'dwell_ms': dwellMs,
    });
  }

  void trackSearch(String query, int resultsTapped) {
    trackEvent(eventType: 'search', metadata: {
      'query': query,
      'results_tapped': resultsTapped,
    });
  }

  void trackTrackPlayed(int trackId, int durationMs, bool completed) {
    trackEvent(eventType: 'track_played', postId: trackId, metadata: {
      'duration_ms': durationMs,
      'completed': completed,
    });
  }

  void trackHashtagViewed(String hashtagName, int dwellMs) {
    trackEvent(eventType: 'hashtag_viewed', metadata: {
      'hashtag_name': hashtagName,
      'dwell_ms': dwellMs,
    });
  }

  /// Generate a UUID v4 string. Backend validates session_id as 'uuid'.
  static String _generateSessionId() {
    final rng = math.Random.secure();
    final bytes = List<int>.generate(16, (_) => rng.nextInt(256));
    // Set version (4) and variant (RFC 4122)
    bytes[6] = (bytes[6] & 0x0f) | 0x40;
    bytes[8] = (bytes[8] & 0x3f) | 0x80;
    final hex = bytes.map((b) => b.toRadixString(16).padLeft(2, '0')).join();
    return '${hex.substring(0, 8)}-${hex.substring(8, 12)}-${hex.substring(12, 16)}-${hex.substring(16, 20)}-${hex.substring(20, 32)}';
  }
}
