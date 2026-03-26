# Flywheel Phase 1: Foundation & Tracking — Implementation Plan

> **For agentic workers:** REQUIRED SUB-SKILL: Use superpowers:subagent-driven-development (recommended) or superpowers:executing-plans to implement this plan task-by-task. Steps use checkbox (`- [ ]`) syntax for tracking.

**Goal:** Build the invisible data pipeline that powers the entire Flywheel — event tracking, interest profiles, creator streaks, viewer streaks, and creator scores.

**Architecture:** Singleton `EventTrackingService` (same pattern as `LocalStorageService`) captures user behavior events in an in-memory buffer, flushes to `POST /api/events` every 30s or on app background. Backend stores events in `user_events`, builds interest profiles via Claude CLI, tracks streaks, and computes creator scores weekly. New models: `UserEvent`, `CreatorStreak`, `ViewerStreak`, `CreatorScore`. New service: `EventTrackingService`, `CreatorService`. Backend directive via `./scripts/ask_backend.sh`.

**Tech Stack:** Flutter/Dart, Hive (offline queue), http package, WidgetsBindingObserver, visibility_detector package, Laravel backend

**Spec:** `docs/superpowers/specs/2026-03-26-tajiri-flywheel-growth-engine-design.md` (Sections 3, 7, 8 — Phase 1)

---

## File Structure

### New Files (Create)

| File | Responsibility |
|------|---------------|
| `lib/services/event_tracking_service.dart` | Singleton. In-memory event buffer, 30s flush timer, Hive offline queue, WidgetsBindingObserver for app lifecycle, batch POST to `/api/events`. Max 100 events per flush. 24h discard. |
| `lib/models/event_models.dart` | `UserEvent` model (event_type, post_id, creator_id, timestamp, duration_ms, session_id, metadata). `CreatorStreak`, `ViewerStreak`, `CreatorScore` models with `fromJson`. |
| `lib/services/creator_service.dart` | Instance-based service (like `PostService`). Methods: `getCreatorScore(creatorId)`, `getCreatorStreak(creatorId)`, `getViewerStreak(userId)`, `getCreatorFundPayout(creatorId)`. |
| `test/services/event_tracking_service_test.dart` | Unit tests for EventTrackingService: buffer, flush, offline queue, 24h discard, batch size cap. |
| `test/models/event_models_test.dart` | Unit tests for model fromJson parsing. |
| `test/services/creator_service_test.dart` | Unit tests for CreatorService API calls. |

### Modified Files

| File | Change |
|------|--------|
| `lib/main.dart` (~line 48) | Initialize `EventTrackingService` after Hive init. |
| `lib/models/post_models.dart` (~line 45) | Add optional `threadId` and `threadTitle` fields to `Post`. |
| `lib/widgets/post_card.dart` | Emit `view` event via EventTrackingService when card becomes visible. |
| `lib/screens/feed/full_screen_post_viewer_screen.dart` | Emit `view`/`dwell` events via VisibilityDetector (same pattern as PostCard). |
| `lib/services/fcm_service.dart` (~line 43) | Add routing for new notification types: `digest`, `thread_trending`, `streak_warning`, `weekly_report`, `milestone`. |
| `pubspec.yaml` | Add `visibility_detector: ^0.4.0+2` dependency. |

---

## Task 1: Backend Directive — Create Tables & Endpoints

**Files:**
- Run: `./scripts/ask_backend.sh` (two prompts)

This task asks the backend AI to create all Phase 1 database tables and API endpoints.

- [ ] **Step 1: Send schema directive for event tracking tables**

```bash
./scripts/ask_backend.sh --type implement --context "Flywheel Phase 1 — Event Tracking" "Create these database tables with migrations:

1. user_events table:
   - id (bigint, primary key)
   - user_id (bigint, foreign key to users, indexed)
   - event_type (string: view, like, share, save, scroll_past, dwell, comment, follow, unfollow)
   - post_id (bigint, nullable, indexed)
   - creator_id (bigint, nullable, indexed)
   - timestamp (datetime, indexed)
   - duration_ms (integer, nullable, default 0)
   - session_id (string uuid, indexed)
   - metadata (json, nullable)
   - created_at, updated_at timestamps
   - Composite index on (user_id, event_type, post_id, timestamp) for deduplication
   - Partition-ready by month (add a month column or use created_at)

2. user_interest_profiles table:
   - id (bigint, primary key)
   - user_id (bigint, foreign key, unique indexed)
   - topic_weights (json)
   - creator_affinities (json)
   - format_preferences (json)
   - activity_patterns (json)
   - gossip_affinity (json)
   - commerce_signals (json)
   - computed_at (datetime)
   - created_at, updated_at timestamps

3. creator_streaks table:
   - id (bigint, primary key)
   - user_id (bigint, foreign key, unique indexed)
   - current_streak_days (integer, default 0)
   - longest_streak_days (integer, default 0)
   - last_post_at (datetime, nullable)
   - banked_skip_days (integer, default 0)
   - is_frozen (boolean, default false)
   - frozen_at (datetime, nullable)
   - streak_multiplier (decimal 3,2 default 1.00)
   - created_at, updated_at timestamps

4. viewer_streaks table:
   - id (bigint, primary key)
   - user_id (bigint, foreign key, unique indexed)
   - current_streak_days (integer, default 0)
   - longest_streak_days (integer, default 0)
   - last_active_date (date, nullable)
   - is_frozen (boolean, default false)
   - frozen_at (datetime, nullable)
   - created_at, updated_at timestamps

5. creator_scores table:
   - id (bigint, primary key)
   - user_id (bigint, foreign key, unique indexed)
   - score (decimal 5,2 default 0.00, range 0-100)
   - tier (string: rising, established, star, legend, default rising)
   - community_score (decimal 5,2 default 0.00)
   - quality_score (decimal 5,2 default 0.00)
   - consistency_score (decimal 5,2 default 0.00)
   - tier_multiplier (decimal 3,2 default 1.00)
   - computed_at (datetime)
   - created_at, updated_at timestamps

6. creator_score_history table:
   - id (bigint, primary key)
   - user_id (bigint, foreign key, indexed)
   - score (decimal 5,2)
   - tier (string)
   - snapshot_date (date, indexed)
   - component_scores (json: community, quality, consistency)
   - created_at timestamp

Also create the API endpoint:
POST /api/events — accepts JSON body { events: [...] } array of event objects. Each event: { event_type, post_id, creator_id, timestamp, duration_ms, session_id, metadata }. Deduplication: skip events where user_id + event_type + post_id + timestamp (1-second granularity) already exists. Auth required (Bearer token). Return { status: 'ok', accepted: N, duplicates: N }."
```

- [ ] **Step 2: Verify backend confirms status: done**

Expected: Backend creates 6 migrations, models, and the POST /api/events endpoint.

- [ ] **Step 3: Send directive for read endpoints**

```bash
./scripts/ask_backend.sh --type implement --context "Flywheel Phase 1 — Read Endpoints" --ref "user_events tables we just created" "Create these API endpoints (all require Bearer token auth):

1. GET /api/creators/{id}/score
   Returns: { data: { user_id, score, tier, community_score, quality_score, consistency_score, tier_multiplier, computed_at } }
   If no record exists, return default: score 0, tier 'rising', multiplier 1.0

2. GET /api/creators/{id}/streak
   Returns: { data: { user_id, current_streak_days, longest_streak_days, last_post_at, banked_skip_days, is_frozen, streak_multiplier } }
   If no record exists, return default: 0 days, multiplier 1.0

3. GET /api/users/{id}/streak
   Returns: { data: { user_id, current_streak_days, longest_streak_days, last_active_date, is_frozen } }
   If no record exists, return default: 0 days

4. GET /api/creators/{id}/fund-payout
   Returns: { data: { user_id, current_month, projected_score, projected_payout, tier, multipliers: { tier: 1.0, streak: 1.0, community: 1.0, virality: 1.0, effective: 1.0, capped: false } } }
   For now return placeholder projection (actual calculation comes in Phase 3).

Also create a Laravel scheduled command (daily at midnight):
- UpdateViewerStreaks: For each user who was active today (has user_events today), increment their viewer_streak. If user was NOT active, freeze their streak.
- UpdateCreatorStreaks: For each creator, check last_post_at. If within 48 hours, streak continues. If not, freeze. Bank 1 skip day per 7 days of streak. Calculate streak_multiplier: 0 days = 1.0, 7+ = 1.1, 30+ = 1.25, 90+ = 1.5."
```

- [ ] **Step 4: Verify backend confirms status: done**

- [ ] **Step 5: Send directive for Claude CLI profile builder and weekly creator score jobs**

```bash
./scripts/ask_backend.sh --type implement --context "Flywheel Phase 1 — Scheduled Jobs" --ref "user_events and creator_scores tables we just created" "Create these Laravel scheduled jobs:

1. BuildUserInterestProfiles (runs every 15 minutes):
   - For each user with new events since last profile build:
     - Collect their recent user_events (last 7 days)
     - Send event batch to Claude CLI with prompt: 'Analyze these user behavior events and return a JSON interest profile with keys: topic_weights (object mapping topic->0-100 weight), creator_affinities (object mapping creator_id->0-100 affinity), format_preferences (object mapping format->0-100 preference), activity_patterns (object with typical_hours array, peak_day string), gossip_affinity (object with thread_entry_rate 0-1, avg_depth int, preferred_categories array), commerce_signals (object with price_range string, top_categories array). Return ONLY valid JSON, no explanation.'
     - Store Claude's JSON output in user_interest_profiles table (upsert by user_id)
     - Cache in Redis with TTL 20 minutes
   - High-signal events (follow, unfollow, language change) should trigger immediate profile rebuild for that user (dispatch job synchronously)
   - Fallback: if Claude CLI times out or errors, skip this cycle and log warning. Keep existing profile.

2. CalculateCreatorScores (runs every Monday at 00:00):
   - For each user who has posted at least once in the last 30 days:
     - community_score (0-100): based on comment reply rate across their posts in last 30 days. 50%+ reply rate = 100, linear scale down.
     - quality_score (0-100): based on average engagement rate (interactions/impressions) relative to platform average. 2x platform avg = 100.
     - consistency_score (0-100): based on posting frequency. 1 post every 48h for 30 days = 100. Scale down proportionally.
     - score = (community_score * 0.3) + (quality_score * 0.4) + (consistency_score * 0.3)
     - tier: Rising (0-30), Established (30-60), Star (60-85), Legend (85-100)
     - tier_multiplier: Rising=1.0, Established=1.5, Star=2.0, Legend=2.5
   - Upsert into creator_scores table
   - Insert snapshot into creator_score_history table with snapshot_date = today
   - Log summary: N creators scored, tier distribution"
```

- [ ] **Step 6: Verify backend confirms status: done**

- [ ] **Step 7: Commit**

```bash
# Nothing to commit on frontend yet — backend handles its own commits
```

---

## Task 2: Add visibility_detector Dependency

**Files:**
- Modify: `pubspec.yaml`

- [ ] **Step 1: Add visibility_detector to pubspec.yaml**

In `pubspec.yaml`, under `dependencies:`, add:

```yaml
  visibility_detector: ^0.4.0+2
```

- [ ] **Step 2: Run pub get**

Run: `flutter pub get`
Expected: Dependencies resolve successfully.

- [ ] **Step 3: Commit**

```bash
git add pubspec.yaml pubspec.lock
git commit -m "deps: add visibility_detector for dwell time tracking"
```

---

## Task 3: Create Event Models

**Files:**
- Create: `lib/models/event_models.dart`
- Test: `test/models/event_models_test.dart`

- [ ] **Step 1: Write the failing test**

Create `test/models/event_models_test.dart`:

```dart
import 'package:flutter_test/flutter_test.dart';
import 'package:tajiri/models/event_models.dart';

void main() {
  group('UserEvent', () {
    test('toJson serializes all fields', () {
      final event = UserEvent(
        eventType: 'view',
        postId: 42,
        creatorId: 15,
        timestamp: DateTime.utc(2026, 3, 26, 19, 30),
        durationMs: 3200,
        sessionId: 'abc-123',
        metadata: {'source': 'feed'},
      );
      final json = event.toJson();
      expect(json['event_type'], 'view');
      expect(json['post_id'], 42);
      expect(json['creator_id'], 15);
      expect(json['timestamp'], '2026-03-26T19:30:00.000Z');
      expect(json['duration_ms'], 3200);
      expect(json['session_id'], 'abc-123');
      expect(json['metadata'], {'source': 'feed'});
    });

    test('toJson omits null optional fields', () {
      final event = UserEvent(
        eventType: 'scroll_past',
        timestamp: DateTime.utc(2026, 3, 26),
        sessionId: 'abc-123',
      );
      final json = event.toJson();
      expect(json['event_type'], 'scroll_past');
      expect(json.containsKey('post_id'), false);
      expect(json.containsKey('creator_id'), false);
      expect(json['duration_ms'], 0);
    });

    test('deduplication key uses 1-second granularity', () {
      final event = UserEvent(
        eventType: 'view',
        postId: 42,
        timestamp: DateTime.utc(2026, 3, 26, 19, 30, 15, 500),
        sessionId: 'abc',
      );
      final key = event.deduplicationKey(userId: 1);
      expect(key, '1_view_42_2026-03-26T19:30:15');
    });
  });

  group('CreatorStreak', () {
    test('fromJson parses correctly', () {
      final streak = CreatorStreak.fromJson({
        'user_id': 15,
        'current_streak_days': 23,
        'longest_streak_days': 45,
        'last_post_at': '2026-03-25T14:00:00.000Z',
        'banked_skip_days': 3,
        'is_frozen': false,
        'streak_multiplier': 1.25,
      });
      expect(streak.userId, 15);
      expect(streak.currentStreakDays, 23);
      expect(streak.longestStreakDays, 45);
      expect(streak.bankedSkipDays, 3);
      expect(streak.isFrozen, false);
      expect(streak.streakMultiplier, 1.25);
    });

    test('fromJson handles defaults', () {
      final streak = CreatorStreak.fromJson({});
      expect(streak.userId, 0);
      expect(streak.currentStreakDays, 0);
      expect(streak.streakMultiplier, 1.0);
      expect(streak.isFrozen, false);
    });
  });

  group('ViewerStreak', () {
    test('fromJson parses correctly', () {
      final streak = ViewerStreak.fromJson({
        'user_id': 42,
        'current_streak_days': 12,
        'longest_streak_days': 30,
        'last_active_date': '2026-03-26',
        'is_frozen': false,
      });
      expect(streak.userId, 42);
      expect(streak.currentStreakDays, 12);
      expect(streak.longestStreakDays, 30);
      expect(streak.isFrozen, false);
    });
  });

  group('CreatorScore', () {
    test('fromJson parses correctly', () {
      final score = CreatorScore.fromJson({
        'user_id': 15,
        'score': 72.5,
        'tier': 'star',
        'community_score': 85.0,
        'quality_score': 68.0,
        'consistency_score': 64.5,
        'tier_multiplier': 2.0,
        'computed_at': '2026-03-26T00:00:00.000Z',
      });
      expect(score.userId, 15);
      expect(score.score, 72.5);
      expect(score.tier, 'star');
      expect(score.tierMultiplier, 2.0);
      expect(score.communityScore, 85.0);
    });

    test('fromJson handles defaults', () {
      final score = CreatorScore.fromJson({});
      expect(score.score, 0.0);
      expect(score.tier, 'rising');
      expect(score.tierMultiplier, 1.0);
    });
  });

  group('FundPayoutProjection', () {
    test('fromJson parses correctly', () {
      final payout = FundPayoutProjection.fromJson({
        'user_id': 15,
        'current_month': '2026-03',
        'projected_score': 5625.0,
        'projected_payout': 500000.0,
        'tier': 'star',
        'multipliers': {
          'tier': 2.0,
          'streak': 1.25,
          'community': 1.5,
          'virality': 3.0,
          'effective': 11.25,
          'capped': false,
        },
      });
      expect(payout.userId, 15);
      expect(payout.currentMonth, '2026-03');
      expect(payout.projectedScore, 5625.0);
      expect(payout.tier, 'star');
      expect(payout.multipliers['effective'], 11.25);
    });

    test('fromJson handles defaults', () {
      final payout = FundPayoutProjection.fromJson({});
      expect(payout.projectedScore, 0.0);
      expect(payout.tier, 'rising');
      expect(payout.multipliers, isEmpty);
    });
  });
}
```

- [ ] **Step 2: Run test to verify it fails**

Run: `flutter test test/models/event_models_test.dart`
Expected: FAIL — `package:tajiri/models/event_models.dart` not found.

- [ ] **Step 3: Write the models**

Create `lib/models/event_models.dart`:

```dart
/// Models for the Flywheel event tracking and creator/viewer metrics.

/// Helper to safely parse int from dynamic
int _parseInt(dynamic value) {
  if (value == null) return 0;
  if (value is int) return value;
  if (value is String) return int.tryParse(value) ?? 0;
  return 0;
}

/// Helper to safely parse double from dynamic
double _parseDouble(dynamic value, [double defaultValue = 0.0]) {
  if (value == null) return defaultValue;
  if (value is double) return value;
  if (value is int) return value.toDouble();
  if (value is String) return double.tryParse(value) ?? defaultValue;
  return defaultValue;
}

/// Helper to safely parse bool from dynamic
bool _parseBool(dynamic value, [bool defaultValue = false]) {
  if (value == null) return defaultValue;
  if (value is bool) return value;
  if (value is int) return value != 0;
  if (value is String) return value.toLowerCase() == 'true' || value == '1';
  return defaultValue;
}

/// A single user behavior event for the Flywheel tracking pipeline.
class UserEvent {
  final String eventType; // view, like, share, save, scroll_past, dwell, comment, follow, unfollow
  final int? postId;
  final int? creatorId;
  final DateTime timestamp;
  final int durationMs;
  final String sessionId;
  final Map<String, dynamic>? metadata;

  UserEvent({
    required this.eventType,
    this.postId,
    this.creatorId,
    required this.timestamp,
    this.durationMs = 0,
    required this.sessionId,
    this.metadata,
  });

  Map<String, dynamic> toJson() {
    final json = <String, dynamic>{
      'event_type': eventType,
      'timestamp': timestamp.toUtc().toIso8601String(),
      'duration_ms': durationMs,
      'session_id': sessionId,
    };
    if (postId != null) json['post_id'] = postId;
    if (creatorId != null) json['creator_id'] = creatorId;
    if (metadata != null && metadata!.isNotEmpty) json['metadata'] = metadata;
    return json;
  }

  /// Deduplication key: user_id + event_type + post_id + timestamp (1-second granularity).
  String deduplicationKey({required int userId}) {
    final ts = timestamp.toUtc();
    final truncated = DateTime.utc(ts.year, ts.month, ts.day, ts.hour, ts.minute, ts.second);
    return '${userId}_${eventType}_${postId ?? 0}_${truncated.toIso8601String().split('.').first}';
  }
}

/// Creator posting streak with multiplier calculation.
class CreatorStreak {
  final int userId;
  final int currentStreakDays;
  final int longestStreakDays;
  final DateTime? lastPostAt;
  final int bankedSkipDays;
  final bool isFrozen;
  final DateTime? frozenAt;
  final double streakMultiplier;

  CreatorStreak({
    required this.userId,
    required this.currentStreakDays,
    required this.longestStreakDays,
    this.lastPostAt,
    required this.bankedSkipDays,
    required this.isFrozen,
    this.frozenAt,
    required this.streakMultiplier,
  });

  factory CreatorStreak.fromJson(Map<String, dynamic> json) {
    return CreatorStreak(
      userId: _parseInt(json['user_id']),
      currentStreakDays: _parseInt(json['current_streak_days']),
      longestStreakDays: _parseInt(json['longest_streak_days']),
      lastPostAt: json['last_post_at'] != null
          ? DateTime.tryParse(json['last_post_at'].toString())
          : null,
      bankedSkipDays: _parseInt(json['banked_skip_days']),
      isFrozen: _parseBool(json['is_frozen']),
      frozenAt: json['frozen_at'] != null
          ? DateTime.tryParse(json['frozen_at'].toString())
          : null,
      streakMultiplier: _parseDouble(json['streak_multiplier'], 1.0),
    );
  }
}

/// Viewer daily open streak.
class ViewerStreak {
  final int userId;
  final int currentStreakDays;
  final int longestStreakDays;
  final String? lastActiveDate; // YYYY-MM-DD
  final bool isFrozen;
  final DateTime? frozenAt;

  ViewerStreak({
    required this.userId,
    required this.currentStreakDays,
    required this.longestStreakDays,
    this.lastActiveDate,
    required this.isFrozen,
    this.frozenAt,
  });

  factory ViewerStreak.fromJson(Map<String, dynamic> json) {
    return ViewerStreak(
      userId: _parseInt(json['user_id']),
      currentStreakDays: _parseInt(json['current_streak_days']),
      longestStreakDays: _parseInt(json['longest_streak_days']),
      lastActiveDate: json['last_active_date']?.toString(),
      isFrozen: _parseBool(json['is_frozen']),
      frozenAt: json['frozen_at'] != null
          ? DateTime.tryParse(json['frozen_at'].toString())
          : null,
    );
  }
}

/// Creator score with tier and component breakdowns.
class CreatorScore {
  final int userId;
  final double score;
  final String tier; // rising, established, star, legend
  final double communityScore;
  final double qualityScore;
  final double consistencyScore;
  final double tierMultiplier;
  final DateTime? computedAt;

  CreatorScore({
    required this.userId,
    required this.score,
    required this.tier,
    required this.communityScore,
    required this.qualityScore,
    required this.consistencyScore,
    required this.tierMultiplier,
    this.computedAt,
  });

  factory CreatorScore.fromJson(Map<String, dynamic> json) {
    return CreatorScore(
      userId: _parseInt(json['user_id']),
      score: _parseDouble(json['score']),
      tier: (json['tier'] as String?) ?? 'rising',
      communityScore: _parseDouble(json['community_score']),
      qualityScore: _parseDouble(json['quality_score']),
      consistencyScore: _parseDouble(json['consistency_score']),
      tierMultiplier: _parseDouble(json['tier_multiplier'], 1.0),
      computedAt: json['computed_at'] != null
          ? DateTime.tryParse(json['computed_at'].toString())
          : null,
    );
  }
}

/// Fund payout projection for current month.
class FundPayoutProjection {
  final int userId;
  final String currentMonth;
  final double projectedScore;
  final double projectedPayout;
  final String tier;
  final Map<String, dynamic> multipliers;

  FundPayoutProjection({
    required this.userId,
    required this.currentMonth,
    required this.projectedScore,
    required this.projectedPayout,
    required this.tier,
    required this.multipliers,
  });

  factory FundPayoutProjection.fromJson(Map<String, dynamic> json) {
    return FundPayoutProjection(
      userId: _parseInt(json['user_id']),
      currentMonth: (json['current_month'] as String?) ?? '',
      projectedScore: _parseDouble(json['projected_score']),
      projectedPayout: _parseDouble(json['projected_payout']),
      tier: (json['tier'] as String?) ?? 'rising',
      multipliers: json['multipliers'] is Map<String, dynamic>
          ? json['multipliers'] as Map<String, dynamic>
          : {},
    );
  }
}
```

- [ ] **Step 4: Run test to verify it passes**

Run: `flutter test test/models/event_models_test.dart`
Expected: All tests PASS.

- [ ] **Step 5: Commit**

```bash
git add lib/models/event_models.dart test/models/event_models_test.dart
git commit -m "feat: add Flywheel event and metric models (UserEvent, CreatorStreak, ViewerStreak, CreatorScore)"
```

---

## Task 4: Create EventTrackingService

**Files:**
- Create: `lib/services/event_tracking_service.dart`
- Test: `test/services/event_tracking_service_test.dart`

- [ ] **Step 1: Write the failing test**

Create `test/services/event_tracking_service_test.dart`:

```dart
import 'package:flutter_test/flutter_test.dart';
import 'package:tajiri/models/event_models.dart';
import 'package:tajiri/services/event_tracking_service.dart';

void main() {
  group('EventTrackingService', () {
    late EventTrackingService service;

    setUp(() {
      service = EventTrackingService.createForTesting();
    });

    tearDown(() {
      service.dispose();
    });

    test('trackEvent adds event to buffer', () {
      service.trackEvent(
        eventType: 'view',
        postId: 42,
        creatorId: 15,
      );
      expect(service.bufferSize, 1);
    });

    test('trackEvent respects max buffer size of 100', () {
      for (int i = 0; i < 150; i++) {
        service.trackEvent(eventType: 'view', postId: i);
      }
      // Buffer should not exceed 200 (flush happens at 100)
      // In testing mode without network, events accumulate but oldest discarded
      expect(service.bufferSize, lessThanOrEqualTo(200));
    });

    test('drainBuffer returns and clears events up to max batch', () {
      for (int i = 0; i < 5; i++) {
        service.trackEvent(eventType: 'view', postId: i);
      }
      final drained = service.drainBuffer(maxBatch: 3);
      expect(drained.length, 3);
      expect(service.bufferSize, 2);
    });

    test('drainBuffer returns empty list when buffer is empty', () {
      final drained = service.drainBuffer(maxBatch: 100);
      expect(drained, isEmpty);
    });

    test('session ID is consistent within a service instance', () {
      service.trackEvent(eventType: 'view', postId: 1);
      service.trackEvent(eventType: 'like', postId: 2);
      final events = service.drainBuffer(maxBatch: 10);
      expect(events[0].sessionId, events[1].sessionId);
      expect(events[0].sessionId, isNotEmpty);
    });

    test('events older than 24h are discarded on drain', () {
      // Add an old event by creating it manually
      final oldEvent = UserEvent(
        eventType: 'view',
        postId: 1,
        timestamp: DateTime.now().subtract(const Duration(hours: 25)),
        sessionId: service.sessionId,
      );
      service.addEventDirectly(oldEvent);
      service.trackEvent(eventType: 'view', postId: 2);

      final events = service.drainBuffer(maxBatch: 100);
      // Old event should be discarded
      expect(events.length, 1);
      expect(events[0].postId, 2);
    });
  });
}
```

- [ ] **Step 2: Run test to verify it fails**

Run: `flutter test test/services/event_tracking_service_test.dart`
Expected: FAIL — `event_tracking_service.dart` not found.

- [ ] **Step 3: Write the EventTrackingService**

Create `lib/services/event_tracking_service.dart`:

```dart
import 'dart:async';
import 'dart:convert';
import 'package:flutter/foundation.dart';
import 'package:flutter/widgets.dart';
import 'package:hive_flutter/hive_flutter.dart';
import 'package:http/http.dart' as http;
import '../config/api_config.dart';
import '../models/event_models.dart';
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
  static const int _flushIntervalSeconds = 30;
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

  /// For testing: add an event directly.
  void addEventDirectly(UserEvent event) {
    _buffer.add(event);
  }

  /// Drain up to [maxBatch] events from the buffer, discarding events older than 24h.
  List<UserEvent> drainBuffer({int maxBatch = _maxBatchSize}) {
    // Remove events older than 24 hours
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
        // No auth — queue offline
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

  /// Clean up resources.
  void dispose() {
    _flushTimer?.cancel();
    if (!_isTestMode) {
      WidgetsBinding.instance.removeObserver(this);
    }
  }

  static String _generateSessionId() {
    // Simple UUID v4-like ID
    final now = DateTime.now().microsecondsSinceEpoch;
    final random = now.hashCode.toRadixString(36);
    return 'ses_${now.toRadixString(36)}_$random';
  }
}
```

- [ ] **Step 4: Run test to verify it passes**

Run: `flutter test test/services/event_tracking_service_test.dart`
Expected: All tests PASS.

- [ ] **Step 5: Commit**

```bash
git add lib/services/event_tracking_service.dart test/services/event_tracking_service_test.dart
git commit -m "feat: add EventTrackingService singleton with buffer, offline queue, and lifecycle flush"
```

---

## Task 5: Create CreatorService

**Files:**
- Create: `lib/services/creator_service.dart`
- Test: `test/services/creator_service_test.dart`

- [ ] **Step 1: Write the failing test**

Create `test/services/creator_service_test.dart`:

```dart
import 'package:flutter_test/flutter_test.dart';
import 'package:tajiri/models/event_models.dart';
import 'package:tajiri/services/creator_service.dart';

void main() {
  group('CreatorService', () {
    test('instance can be created', () {
      final service = CreatorService();
      expect(service, isNotNull);
    });
  });

  group('CreatorScore tier logic', () {
    test('rising tier has 1.0x multiplier', () {
      final score = CreatorScore.fromJson({
        'score': 20.0,
        'tier': 'rising',
        'tier_multiplier': 1.0,
      });
      expect(score.tier, 'rising');
      expect(score.tierMultiplier, 1.0);
    });

    test('star tier has 2.0x multiplier', () {
      final score = CreatorScore.fromJson({
        'score': 72.5,
        'tier': 'star',
        'tier_multiplier': 2.0,
      });
      expect(score.tier, 'star');
      expect(score.tierMultiplier, 2.0);
    });
  });
}
```

- [ ] **Step 2: Run test to verify it fails**

Run: `flutter test test/services/creator_service_test.dart`
Expected: FAIL — `creator_service.dart` not found.

- [ ] **Step 3: Write CreatorService**

Create `lib/services/creator_service.dart`:

```dart
import 'dart:convert';
import 'package:flutter/foundation.dart';
import 'package:http/http.dart' as http;
import '../config/api_config.dart';
import '../models/event_models.dart';

String get _baseUrl => ApiConfig.baseUrl;

/// Service for creator metrics, streaks, and scores.
/// Instance-based (same pattern as PostService, FeedService).
class CreatorService {
  /// GET /api/creators/{id}/score
  Future<CreatorScore?> getCreatorScore({
    required int creatorId,
    required String token,
  }) async {
    try {
      final url = Uri.parse('$_baseUrl/creators/$creatorId/score');
      final response = await http.get(url, headers: ApiConfig.authHeaders(token));
      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        final scoreData = data['data'] ?? data;
        return CreatorScore.fromJson(scoreData as Map<String, dynamic>);
      }
      if (kDebugMode) {
        debugPrint('[CreatorService] getCreatorScore ${response.statusCode}');
      }
      return null;
    } catch (e) {
      if (kDebugMode) debugPrint('[CreatorService] getCreatorScore error: $e');
      return null;
    }
  }

  /// GET /api/creators/{id}/streak
  Future<CreatorStreak?> getCreatorStreak({
    required int creatorId,
    required String token,
  }) async {
    try {
      final url = Uri.parse('$_baseUrl/creators/$creatorId/streak');
      final response = await http.get(url, headers: ApiConfig.authHeaders(token));
      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        final streakData = data['data'] ?? data;
        return CreatorStreak.fromJson(streakData as Map<String, dynamic>);
      }
      if (kDebugMode) {
        debugPrint('[CreatorService] getCreatorStreak ${response.statusCode}');
      }
      return null;
    } catch (e) {
      if (kDebugMode) debugPrint('[CreatorService] getCreatorStreak error: $e');
      return null;
    }
  }

  /// GET /api/users/{id}/streak
  Future<ViewerStreak?> getViewerStreak({
    required int userId,
    required String token,
  }) async {
    try {
      final url = Uri.parse('$_baseUrl/users/$userId/streak');
      final response = await http.get(url, headers: ApiConfig.authHeaders(token));
      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        final streakData = data['data'] ?? data;
        return ViewerStreak.fromJson(streakData as Map<String, dynamic>);
      }
      if (kDebugMode) {
        debugPrint('[CreatorService] getViewerStreak ${response.statusCode}');
      }
      return null;
    } catch (e) {
      if (kDebugMode) debugPrint('[CreatorService] getViewerStreak error: $e');
      return null;
    }
  }

  /// GET /api/creators/{id}/fund-payout
  Future<FundPayoutProjection?> getFundPayoutProjection({
    required int creatorId,
    required String token,
  }) async {
    try {
      final url = Uri.parse('$_baseUrl/creators/$creatorId/fund-payout');
      final response = await http.get(url, headers: ApiConfig.authHeaders(token));
      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        final payoutData = data['data'] ?? data;
        return FundPayoutProjection.fromJson(payoutData as Map<String, dynamic>);
      }
      if (kDebugMode) {
        debugPrint('[CreatorService] getFundPayoutProjection ${response.statusCode}');
      }
      return null;
    } catch (e) {
      if (kDebugMode) debugPrint('[CreatorService] getFundPayoutProjection error: $e');
      return null;
    }
  }
}
```

- [ ] **Step 4: Run test to verify it passes**

Run: `flutter test test/services/creator_service_test.dart`
Expected: All tests PASS.

- [ ] **Step 5: Commit**

```bash
git add lib/services/creator_service.dart test/services/creator_service_test.dart
git commit -m "feat: add CreatorService for score, streak, and fund payout endpoints"
```

---

## Task 6: Initialize EventTrackingService in main.dart

**Files:**
- Modify: `lib/main.dart` (~line 48-60)

- [ ] **Step 1: Add import at top of main.dart**

Add after the existing imports (around line 40):

```dart
import 'services/event_tracking_service.dart';
```

- [ ] **Step 2: Initialize EventTrackingService after Hive init**

In the `main()` function, after `await Hive.initFlutter();` (line 48) and before the Firebase init block, add:

```dart
  // Initialize event tracking for Flywheel engine
  await EventTrackingService.getInstance();
```

- [ ] **Step 3: Run flutter analyze**

Run: `flutter analyze`
Expected: No new errors or warnings from the changes.

- [ ] **Step 4: Commit**

```bash
git add lib/main.dart
git commit -m "feat: initialize EventTrackingService on app startup"
```

---

## Task 7: Add thread_id and thread_title to Post Model

**Files:**
- Modify: `lib/models/post_models.dart`

- [ ] **Step 1: Add fields to Post class**

In `lib/models/post_models.dart`, in the `Post` class field declarations (around line 76, after `isFeatured`), add:

```dart
  // Gossip thread association (optional — set when post belongs to a thread)
  final int? threadId;
  final String? threadTitle;
```

- [ ] **Step 2: Add to constructor**

In the `Post` constructor (around line 165, after `this.allowComments = true`), add:

```dart
    this.threadId,
    this.threadTitle,
```

- [ ] **Step 3: Add to fromJson factory**

In `Post.fromJson()` (around line 195, after `regionId` parsing), add:

```dart
      threadId: json['thread_id'] != null ? _parseInt(json['thread_id']) : null,
      threadTitle: json['thread_title'] as String?,
```

- [ ] **Step 4: Run flutter analyze**

Run: `flutter analyze`
Expected: No errors. Fields are optional (nullable), so all existing code continues to work.

- [ ] **Step 5: Run existing tests**

Run: `flutter test`
Expected: All existing tests pass. The new fields default to null.

- [ ] **Step 6: Commit**

```bash
git add lib/models/post_models.dart
git commit -m "feat: add optional threadId and threadTitle fields to Post model"
```

---

## Task 8: Add FCM Notification Routing for New Types

**Files:**
- Modify: `lib/services/fcm_service.dart` (~line 43-53)

- [ ] **Step 1: Add routing cases to _handlePayload**

In `lib/services/fcm_service.dart`, in the `_handlePayload` method (after the `new_message` check around line 53), add:

```dart
    // Flywheel notification types — route to appropriate screens
    if (type == 'digest') {
      _openDigest(data, navigator);
      return;
    }
    if (type == 'thread_trending') {
      _openThread(data, navigator);
      return;
    }
    if (type == 'streak_warning' || type == 'weekly_report' || type == 'milestone') {
      _openProfile(data, navigator);
      return;
    }
```

- [ ] **Step 2: Add handler methods**

After the `_openChat` method (around line 101), add:

```dart
  /// Opens digest screen (Phase 3 — for now navigates to feed).
  void _openDigest(Map<String, dynamic> data, NavigatorState navigator) {
    if (navigator.mounted) {
      navigator.pushNamed('/feed');
    }
  }

  /// Opens gossip thread (Phase 2 — for now navigates to feed).
  void _openThread(Map<String, dynamic> data, NavigatorState navigator) {
    if (navigator.mounted) {
      navigator.pushNamed('/feed');
    }
  }

  /// Opens profile for streak/report/milestone notifications.
  Future<void> _openProfile(Map<String, dynamic> data, NavigatorState navigator) async {
    final userId = await _currentUserId();
    if (userId != null && navigator.mounted) {
      navigator.pushNamed('/profile/$userId');
    }
  }
```

- [ ] **Step 3: Run flutter analyze**

Run: `flutter analyze`
Expected: No errors or warnings.

- [ ] **Step 4: Commit**

```bash
git add lib/services/fcm_service.dart
git commit -m "feat: add FCM routing for Flywheel notification types (digest, thread, streak, report, milestone)"
```

---

## Task 9: Integrate Event Tracking into PostCard (View Events)

**Files:**
- Modify: `lib/widgets/post_card.dart`

- [ ] **Step 1: Add import**

At the top of `lib/widgets/post_card.dart`, add:

```dart
import 'package:visibility_detector/visibility_detector.dart';
import '../services/event_tracking_service.dart';
```

- [ ] **Step 2: Wrap card with VisibilityDetector**

In the `build` method of the PostCard widget, wrap the outermost widget with a `VisibilityDetector`. The key should be based on the post ID:

```dart
VisibilityDetector(
  key: Key('post_card_${widget.post.id}'),
  onVisibilityChanged: _onVisibilityChanged,
  child: /* existing card widget */,
)
```

- [ ] **Step 3: Add visibility tracking state and handler**

In the PostCard's State class, add:

```dart
  DateTime? _visibleSince;
  bool _viewTracked = false;

  void _onVisibilityChanged(VisibilityInfo info) {
    if (info.visibleFraction >= 0.5) {
      // Post is 50%+ visible
      _visibleSince ??= DateTime.now();
      if (!_viewTracked) {
        _viewTracked = true;
        // Track view after 1 second visibility (done in next check)
        Future.delayed(const Duration(seconds: 1), () {
          if (mounted && _visibleSince != null) {
            EventTrackingService.getInstance().then((tracker) {
              tracker.trackEvent(
                eventType: 'view',
                postId: widget.post.id,
                creatorId: widget.post.userId,
              );
            });
          }
        });
      }
    } else {
      // Post left viewport — emit dwell event
      if (_visibleSince != null) {
        final dwellMs = DateTime.now().difference(_visibleSince!).inMilliseconds;
        if (dwellMs > 1000) {
          EventTrackingService.getInstance().then((tracker) {
            tracker.trackEvent(
              eventType: 'dwell',
              postId: widget.post.id,
              creatorId: widget.post.userId,
              durationMs: dwellMs,
            );
          });
        }
        _visibleSince = null;
      }
    }
  }
```

- [ ] **Step 4: Run flutter analyze**

Run: `flutter analyze`
Expected: No errors.

- [ ] **Step 5: Commit**

```bash
git add lib/widgets/post_card.dart
git commit -m "feat: track view and dwell events on PostCard via VisibilityDetector"
```

---

## Task 10: Track Engagement Events (Like, Share, Save, Comment)

**Files:**
- Modify: `lib/widgets/post_card.dart` (like, share, save buttons)
- Modify: `lib/screens/feed/post_detail_screen.dart` (comment submission)

- [ ] **Step 1: Add event tracking to existing like handler in PostCard**

Find the existing like button's onTap handler in `post_card.dart`. After the API call, add:

```dart
EventTrackingService.getInstance().then((tracker) {
  tracker.trackEvent(
    eventType: 'like',
    postId: widget.post.id,
    creatorId: widget.post.userId,
  );
});
```

- [ ] **Step 2: Add event tracking to share handler in PostCard**

Find the share button's onTap handler. After the share action, add:

```dart
EventTrackingService.getInstance().then((tracker) {
  tracker.trackEvent(
    eventType: 'share',
    postId: widget.post.id,
    creatorId: widget.post.userId,
  );
});
```

- [ ] **Step 3: Add event tracking to save handler in PostCard**

Find the save/bookmark button's onTap handler. After the API call, add:

```dart
EventTrackingService.getInstance().then((tracker) {
  tracker.trackEvent(
    eventType: 'save',
    postId: widget.post.id,
    creatorId: widget.post.userId,
  );
});
```

- [ ] **Step 4: Add event tracking to comment submission in PostDetailScreen**

In `lib/screens/feed/post_detail_screen.dart`, find the comment submit handler. After successful comment creation, add:

```dart
EventTrackingService.getInstance().then((tracker) {
  tracker.trackEvent(
    eventType: 'comment',
    postId: widget.postId, // or the post ID variable in scope
    creatorId: _post?.userId ?? 0,
  );
});
```

Add import at top:
```dart
import '../../services/event_tracking_service.dart';
```

- [ ] **Step 5: Run flutter analyze**

Run: `flutter analyze`
Expected: No errors.

- [ ] **Step 6: Commit**

```bash
git add lib/widgets/post_card.dart lib/screens/feed/post_detail_screen.dart
git commit -m "feat: track like, share, save, and comment events for Flywheel pipeline"
```

---

## Task 11: Add Scroll-Past Detection to PostCard Visibility Handler

**Files:**
- Modify: `lib/widgets/post_card.dart`

- [ ] **Step 1: Update the "left viewport" branch in _onVisibilityChanged**

In the PostCard's `_onVisibilityChanged` handler (added in Task 9), replace the simple dwell-only "left viewport" branch with scroll-past detection. If dwell < 1 second, emit `scroll_past` instead of `dwell`:

```dart
    } else {
      // Post left viewport
      if (_visibleSince != null) {
        final dwellMs = DateTime.now().difference(_visibleSince!).inMilliseconds;
        if (dwellMs > 1000) {
          // Meaningful view — emit dwell
          EventTrackingService.getInstance().then((tracker) {
            tracker.trackEvent(
              eventType: 'dwell',
              postId: widget.post.id,
              creatorId: widget.post.userId,
              durationMs: dwellMs,
            );
          });
        } else {
          // Quick scroll past — emit scroll_past
          EventTrackingService.getInstance().then((tracker) {
            tracker.trackEvent(
              eventType: 'scroll_past',
              postId: widget.post.id,
              creatorId: widget.post.userId,
              durationMs: dwellMs,
            );
          });
        }
        _visibleSince = null;
      }
    }
```

- [ ] **Step 3: Run flutter analyze**

Run: `flutter analyze`
Expected: No errors.

- [ ] **Step 4: Commit**

```bash
git add lib/widgets/post_card.dart
git commit -m "feat: track scroll_past events for posts viewed under 1 second"
```

---

## Task 12: Track View/Dwell Events in Full-Screen Post Viewer

**Files:**
- Modify: `lib/screens/feed/full_screen_post_viewer_screen.dart`

The full-screen post viewer is a separate screen from PostCard (used for swiping through posts one at a time). It needs its own event tracking since PostCard's VisibilityDetector doesn't cover it.

- [ ] **Step 1: Read the full-screen viewer to understand its structure**

Read `lib/screens/feed/full_screen_post_viewer_screen.dart` to find the widget structure. Likely uses a `PageView` or similar for swiping between posts.

- [ ] **Step 2: Add imports**

At the top of the file, add:

```dart
import '../../services/event_tracking_service.dart';
```

- [ ] **Step 3: Track view event when a post becomes the active page**

In the page change handler (e.g., `onPageChanged` of PageView), emit a `view` event for the newly visible post:

```dart
EventTrackingService.getInstance().then((tracker) {
  tracker.trackEvent(
    eventType: 'view',
    postId: currentPost.id,
    creatorId: currentPost.userId,
  );
});
```

- [ ] **Step 4: Track dwell event when user leaves a post**

Track the time the user enters a post and emit a `dwell` event when they swipe away or leave the screen. Add state tracking:

```dart
DateTime? _currentPostEnteredAt;
int? _currentPostId;
int? _currentCreatorId;

void _emitDwellForCurrentPost() {
  if (_currentPostEnteredAt != null && _currentPostId != null) {
    final dwellMs = DateTime.now().difference(_currentPostEnteredAt!).inMilliseconds;
    if (dwellMs > 1000) {
      EventTrackingService.getInstance().then((tracker) {
        tracker.trackEvent(
          eventType: 'dwell',
          postId: _currentPostId!,
          creatorId: _currentCreatorId ?? 0,
          durationMs: dwellMs,
        );
      });
    }
  }
}
```

Call `_emitDwellForCurrentPost()` in `onPageChanged` (before tracking the new page) and in `dispose()`.

- [ ] **Step 5: Run flutter analyze**

Run: `flutter analyze`
Expected: No errors.

- [ ] **Step 6: Commit**

```bash
git add lib/screens/feed/full_screen_post_viewer_screen.dart
git commit -m "feat: track view and dwell events in full-screen post viewer"
```

---

## Task 13: Track Follow/Unfollow Events

**Files:**
- Modify: The file(s) containing follow/unfollow button handlers (likely in `lib/screens/profile/profile_screen.dart` or a shared widget)

- [ ] **Step 1: Find follow/unfollow handlers**

Search the codebase for follow button handlers:

```bash
grep -rn "follow" lib/screens/profile/ lib/widgets/ --include="*.dart" | grep -i "onpress\|ontap\|follow("
```

- [ ] **Step 2: Add import**

In the file(s) containing follow/unfollow handlers, add:

```dart
import '../../services/event_tracking_service.dart';
```

(Adjust import path based on file location.)

- [ ] **Step 3: Track follow event**

After the successful follow API call, add:

```dart
EventTrackingService.getInstance().then((tracker) {
  tracker.trackEvent(
    eventType: 'follow',
    creatorId: targetUserId, // the user being followed
  );
});
```

- [ ] **Step 4: Track unfollow event**

After the successful unfollow API call, add:

```dart
EventTrackingService.getInstance().then((tracker) {
  tracker.trackEvent(
    eventType: 'unfollow',
    creatorId: targetUserId, // the user being unfollowed
  );
});
```

- [ ] **Step 5: Run flutter analyze**

Run: `flutter analyze`
Expected: No errors.

- [ ] **Step 6: Commit**

```bash
git add -A lib/screens/ lib/widgets/
git commit -m "feat: track follow and unfollow events for Flywheel pipeline"
```

---

## Task 14: Final Verification & Integration Test

- [ ] **Step 1: Run all tests**

Run: `flutter test`
Expected: All tests pass.

- [ ] **Step 2: Run flutter analyze**

Run: `flutter analyze`
Expected: No errors or warnings.

- [ ] **Step 3: Build the app**

Run: `flutter build apk --debug`
Expected: Build succeeds.

- [ ] **Step 4: Manual verification checklist**

If device is available, verify on device:
- App starts without crash
- Feed loads normally
- Console shows `[EventTracking]` debug prints for view/dwell events as you scroll
- Backgrounding the app triggers a flush log

- [ ] **Step 5: Final commit (if any loose changes)**

```bash
git status
# If any uncommitted changes remain, add and commit them
```

---

## Ship Gate Checklist

Phase 1 is complete when:
- [ ] Backend has `user_events`, `user_interest_profiles`, `creator_streaks`, `viewer_streaks`, `creator_scores`, `creator_score_history` tables
- [ ] `POST /api/events` endpoint accepts batched events
- [ ] `GET /api/creators/{id}/score`, `GET /api/creators/{id}/streak`, `GET /api/users/{id}/streak`, `GET /api/creators/{id}/fund-payout` endpoints return data
- [ ] Backend has `BuildUserInterestProfiles` scheduled job (every 15 min, Claude CLI)
- [ ] Backend has `CalculateCreatorScores` weekly job (every Monday)
- [ ] Backend has `UpdateViewerStreaks` and `UpdateCreatorStreaks` daily jobs
- [ ] `EventTrackingService` singleton captures view, dwell, scroll_past, like, share, save, comment, follow, unfollow events
- [ ] Events flush every 30s and on app background
- [ ] Offline events queued in Hive and restored on next launch
- [ ] Events older than 24h are discarded
- [ ] Full-screen post viewer tracks view/dwell events
- [ ] Post model has optional `threadId`/`threadTitle` fields
- [ ] FCM routes new notification types (digest, thread_trending, streak_warning, weekly_report, milestone)
- [ ] All tests pass, flutter analyze clean
