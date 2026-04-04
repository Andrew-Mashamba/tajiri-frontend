import 'package:flutter/foundation.dart';

/// Centralized performance logger for tracking cache hits, timing, and
/// optimization effectiveness. Only logs in debug mode.
///
/// Usage: `PerfLogger.log('feed_cache_hit', {'posts': 42, 'age_sec': 120});`
///
/// All logs are prefixed with [PERF] for easy filtering:
///   `flutter logs | grep "\[PERF\]"`
class PerfLogger {
  PerfLogger._();

  // Session-level counters (reset on app restart)
  static int feedCacheHits = 0;
  static int feedCacheMisses = 0;
  static int etagHits = 0; // 304 responses
  static int etagMisses = 0; // 200 responses with new ETag
  static int profileCacheHits = 0;
  static int profileCacheMisses = 0;
  static int prefetchHits = 0; // Used prefetched next page
  static int prefetchMisses = 0; // Had to fetch normally
  static int conversationCacheHits = 0;
  static int conversationCacheMisses = 0;
  static int categoryCacheHits = 0;
  static int categoryCacheMisses = 0;
  static int peopleCacheHits = 0;
  static int peopleCacheMisses = 0;
  static int lazyTabsDeferred = 0; // Tabs that didn't load on startup
  static int blurhashRendered = 0;

  /// Log a performance event with optional data.
  static void log(String event, [Map<String, dynamic>? data]) {
    if (!kDebugMode) return;
    final dataStr = data != null ? ' $data' : '';
    debugPrint('[PERF] $event$dataStr');
  }

  /// Start a timer, returns a Stopwatch. Call [endTiming] with it.
  static Stopwatch startTiming() => Stopwatch()..start();

  /// End a timer and log the result.
  static int endTiming(Stopwatch sw, String label, [Map<String, dynamic>? extra]) {
    sw.stop();
    final ms = sw.elapsedMilliseconds;
    final data = <String, dynamic>{'ms': ms};
    if (extra != null) data.addAll(extra);
    log(label, data);
    return ms;
  }

  /// Print a summary of all session counters.
  static void printSummary() {
    if (!kDebugMode) return;
    debugPrint('');
    debugPrint('[PERF] ══════════ SESSION SUMMARY ══════════');
    debugPrint('[PERF] Feed cache:         $feedCacheHits hits / $feedCacheMisses misses');
    debugPrint('[PERF] ETag (304):         $etagHits hits / $etagMisses misses');
    debugPrint('[PERF] Profile cache:      $profileCacheHits hits / $profileCacheMisses misses');
    debugPrint('[PERF] Prefetch used:      $prefetchHits hits / $prefetchMisses misses');
    debugPrint('[PERF] Conversation cache: $conversationCacheHits hits / $conversationCacheMisses misses');
    debugPrint('[PERF] Category cache:     $categoryCacheHits hits / $categoryCacheMisses misses');
    debugPrint('[PERF] People cache:       $peopleCacheHits hits / $peopleCacheMisses misses');
    debugPrint('[PERF] Lazy tabs deferred: $lazyTabsDeferred');
    debugPrint('[PERF] BlurHash rendered:  $blurhashRendered');
    final totalCacheHits = feedCacheHits + etagHits + profileCacheHits +
        prefetchHits + conversationCacheHits + categoryCacheHits + peopleCacheHits;
    final totalCacheMisses = feedCacheMisses + etagMisses + profileCacheMisses +
        prefetchMisses + conversationCacheMisses + categoryCacheMisses + peopleCacheMisses;
    final total = totalCacheHits + totalCacheMisses;
    final hitRate = total > 0 ? (totalCacheHits / total * 100).toStringAsFixed(1) : '0.0';
    debugPrint('[PERF] Overall hit rate:   $hitRate% ($totalCacheHits/$total)');
    debugPrint('[PERF] ════════════════════════════════════');
    debugPrint('');
  }

  /// Reset all counters.
  static void reset() {
    feedCacheHits = 0;
    feedCacheMisses = 0;
    etagHits = 0;
    etagMisses = 0;
    profileCacheHits = 0;
    profileCacheMisses = 0;
    prefetchHits = 0;
    prefetchMisses = 0;
    conversationCacheHits = 0;
    conversationCacheMisses = 0;
    categoryCacheHits = 0;
    categoryCacheMisses = 0;
    peopleCacheHits = 0;
    peopleCacheMisses = 0;
    lazyTabsDeferred = 0;
    blurhashRendered = 0;
  }
}
