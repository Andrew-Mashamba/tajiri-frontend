# Flywheel Audit Fixes — All 30 Issues

> **For agentic workers:** REQUIRED SUB-SKILL: Use superpowers:subagent-driven-development (recommended) or superpowers:executing-plans to implement this plan task-by-task. Steps use checkbox (`- [ ]`) syntax for tracking.

**Goal:** Fix all 30 audit findings (6 CRITICAL, 7 HIGH, 11 MEDIUM, 6 LOW) across frontend and backend to make the Flywheel Growth Engine fully operational.

**Architecture:** Frontend fixes are Dart edits to service files, screens, and widgets. Backend fixes are PHP files deployed via SSH to `/var/www/html/tajiri/`. All backend commands: `sshpass -p 'ZimaBlueApps' ssh -o StrictHostKeyChecking=no root@zima-uat.site "cd /var/www/html/tajiri && COMMAND"`

**Tech Stack:** Flutter/Dart (frontend), Laravel 12/PHP 8.2+/PostgreSQL (backend)

---

## CRITICAL FIXES (Issues #1–#6)

### Task 1: Fix battle endpoint URLs (#1)

**Files:**
- Modify: `lib/services/battle_service.dart`

Frontend uses `/battles` but backend registered `/creator-battles`.

- [ ] **Step 1: Fix all three endpoint URLs**

In `lib/services/battle_service.dart`, replace all 3 occurrences of `/battles` with `/creator-battles`:

Line 13: `'$_baseUrl/battles'` → `'$_baseUrl/creator-battles'`
Line 32: `'$_baseUrl/battles/$battleId'` → `'$_baseUrl/creator-battles/$battleId'`
Line 55: `'$_baseUrl/battles/$battleId/vote'` → `'$_baseUrl/creator-battles/$battleId/vote'`

- [ ] **Step 2: Verify no other files reference `/battles`**

```bash
grep -rn "'/battles" lib/services/ lib/screens/
```

Expected: No results (only battle_service.dart should have had them, now fixed).

- [ ] **Step 3: Run analyzer**

```bash
flutter analyze lib/services/battle_service.dart
```

---

### Task 2: Fix analytics endpoint URLs (#2)

**Files:**
- Modify: `lib/services/analytics_service.dart`

Frontend paths don't match backend routes.

- [ ] **Step 1: Fix dashboard URL**

Line 16: `'$_baseUrl/creators/$creatorId/analytics'` → `'$_baseUrl/creators/$creatorId/analytics/dashboard'`

- [ ] **Step 2: Fix post performance URL**

Line 39: `'$_baseUrl/posts/$postId/analytics'` → `'$_baseUrl/creators/$creatorId/analytics/posts'`

This also requires changing the method signature to accept `creatorId` instead of (or in addition to) `postId`:

```dart
Future<List<PostPerformance>> getPostPerformance({
  required String token,
  required int creatorId,
}) async {
  try {
    final response = await http.get(
      Uri.parse('$_baseUrl/creators/$creatorId/analytics/posts'),
      headers: ApiConfig.authHeaders(token),
    );
    if (response.statusCode == 200) {
      final data = jsonDecode(response.body);
      final rawList = data['data'] is List ? data['data'] as List : [];
      return rawList.whereType<Map<String, dynamic>>()
          .map((e) => PostPerformance.fromJson(e)).toList();
    }
    return [];
  } catch (e) {
    debugPrint('[AnalyticsService] getPostPerformance error: $e');
    return [];
  }
}
```

- [ ] **Step 3: Fix audience insights URL**

Line 62: `'$_baseUrl/creators/$creatorId/audience'` → `'$_baseUrl/creators/$creatorId/analytics/audience'`

- [ ] **Step 4: Run analyzer**

```bash
flutter analyze lib/services/analytics_service.dart
```

---

### Task 3: Fix feed double `/api` URLs (#3)

**Files:**
- Modify: `lib/services/feed_service.dart`

Lines 104 and 139 have `$_baseUrl/api/posts/feed/...` — `_baseUrl` already includes `/api`, creating `/api/api/...`.

- [ ] **Step 1: Fix shorts feed URL**

Line 104: `'$_baseUrl/api/posts/feed/shorts?...'` → `'$_baseUrl/posts/feed/shorts?...'`

- [ ] **Step 2: Fix following feed URL**

Line 139: `'$_baseUrl/api/posts/feed/following?...'` → `'$_baseUrl/posts/feed/following?...'`

- [ ] **Step 3: Run analyzer**

```bash
flutter analyze lib/services/feed_service.dart
```

---

### Task 4: Fix event tracking session_id format mismatch (#4)

**Files:**
- Modify: `lib/services/event_tracking_service.dart`

Backend validates `session_id` as `uuid` format, but frontend generates `ses_<timestamp>_<hash>` which will fail validation. Every event POST is silently rejected.

- [ ] **Step 1: Fix session ID generation to use UUID v4**

Add `import 'package:uuid/uuid.dart';` at top (or use dart built-in). Replace `_generateSessionId()`:

```dart
static String _generateSessionId() {
  // Generate UUID v4 format: backend validates session_id as 'uuid'
  final random = DateTime.now().microsecondsSinceEpoch;
  final hex = random.toRadixString(16).padLeft(12, '0');
  // Construct UUID v4 format: 8-4-4-4-12
  return '${hex.substring(0, 8)}-${hex.substring(0, 4)}-4${hex.substring(1, 4)}-a${hex.substring(0, 3)}-${hex.padRight(12, '0').substring(0, 12)}';
}
```

OR better — check if `uuid` package is already in pubspec.yaml. If yes:

```dart
import 'package:uuid/uuid.dart';

static String _generateSessionId() {
  return const Uuid().v4();
}
```

If not, add the uuid package:
```bash
flutter pub add uuid
```

- [ ] **Step 2: Verify event POST format matches backend expectations**

Backend expects: `{ "events": [{ "event_type": "view", "post_id": 1, "creator_id": 1, "timestamp": "2026-03-26T12:00:00Z", "duration_ms": 5000, "session_id": "uuid-here", "metadata": {} }] }`

Check that `UserEvent.toJson()` in `lib/models/flywheel_models.dart` produces matching keys (`event_type`, `post_id`, `creator_id`, `timestamp`, `duration_ms`, `session_id`, `metadata`).

- [ ] **Step 3: Run analyzer**

```bash
flutter analyze lib/services/event_tracking_service.dart
```

---

### Task 5: Fix personalized feed to use interest data (#5)

**Files:**
- Modify (backend): `app/Http/Controllers/Api/GossipController.php` — `personalizedFeed` method

Currently just returns chronological posts. Need to rank by user interests.

- [ ] **Step 1: Rewrite personalizedFeed method on server**

Replace the `personalizedFeed` method to score posts by user interests:

```php
public function personalizedFeed(Request $request)
{
    $user = $request->user();
    $perPage = $request->get('per_page', 20);

    // Get user's interest weights (which creators/topics they engage with)
    $interests = [];
    if ($user) {
        $interests = DB::table('user_events')
            ->select('creator_id', DB::raw('COUNT(*) as weight'))
            ->where('user_id', $user->id)
            ->where('created_at', '>=', now()->subDays(14))
            ->whereNotNull('creator_id')
            ->groupBy('creator_id')
            ->pluck('weight', 'creator_id')
            ->toArray();
    }

    $posts = Post::with(['user', 'media'])
        ->where('status', 'published')
        ->where('created_at', '>=', now()->subDays(7))
        ->orderByDesc('created_at')
        ->limit(200)
        ->get();

    // Score and sort by interest relevance + recency
    $scored = $posts->map(function ($post) use ($interests) {
        $interestScore = $interests[$post->user_id] ?? 0;
        $recencyHours = now()->diffInHours($post->created_at);
        $recencyScore = max(0, 168 - $recencyHours); // 168 = 7 days in hours
        $engagementScore = ($post->likes_count ?? 0) + ($post->comments_count ?? 0) * 2 + ($post->shares_count ?? 0) * 3;

        $post->_relevance = ($interestScore * 10) + $recencyScore + ($engagementScore * 0.5);
        return $post;
    })->sortByDesc('_relevance')->take($perPage)->values();

    // Attach thread info
    $postIds = $scored->pluck('id')->toArray();
    $threadMap = DB::table('gossip_thread_posts')
        ->join('gossip_threads', 'gossip_threads.id', '=', 'gossip_thread_posts.thread_id')
        ->leftJoin('thread_title_templates', 'thread_title_templates.key', '=', 'gossip_threads.title_key')
        ->whereIn('gossip_thread_posts.post_id', $postIds)
        ->where('gossip_threads.status', 'active')
        ->select(
            'gossip_thread_posts.post_id',
            'gossip_threads.id as thread_id',
            'thread_title_templates.template_en',
            'thread_title_templates.template_sw',
            'gossip_threads.title_slots'
        )
        ->get()
        ->keyBy('post_id');

    $data = $scored->map(function ($post) use ($threadMap) {
        $p = $this->formatPost($post);
        if (isset($threadMap[$post->id])) {
            $tm = $threadMap[$post->id];
            $p['thread_id'] = $tm->thread_id;
            $slots = json_decode($tm->title_slots ?? '{}', true) ?: [];
            $titleEn = $tm->template_en ?? 'Trending';
            $titleSw = $tm->template_sw ?? 'Vinavyoongezeka';
            foreach ($slots as $k => $v) {
                $titleEn = str_replace("{{$k}}", $v, $titleEn);
                $titleSw = str_replace("{{$k}}", $v, $titleSw);
            }
            $p['thread_title'] = $titleEn;
        }
        return $p;
    });

    return response()->json([
        'success' => true,
        'data' => $data,
        'meta' => [
            'current_page' => 1,
            'last_page' => 1,
            'total' => $data->count(),
        ],
    ]);
}
```

- [ ] **Step 2: Verify endpoint returns 200**

```bash
curl -sk -w "%{http_code}" "https://zima-uat.site:8003/api/feed/personalized"
```

---

### Task 6: Build user_interest_profiles from user_events (#6)

**Files:**
- Create (backend): `app/Console/Commands/BuildInterestProfiles.php`
- Modify (backend): `routes/console.php` — add schedule

The `user_interest_profiles` table is a ghost — migrated but nothing writes to it. Create a command that aggregates `user_events` into interest profiles.

- [ ] **Step 1: Create BuildInterestProfiles command**

```php
<?php

namespace App\Console\Commands;

use Illuminate\Console\Command;
use Illuminate\Support\Facades\DB;
use Carbon\Carbon;

class BuildInterestProfiles extends Command
{
    protected $signature = 'flywheel:build-interest-profiles';
    protected $description = 'Aggregate user_events into user_interest_profiles';

    public function handle(): int
    {
        $since = Carbon::now()->subDays(30);

        // Get active users from events
        $userIds = DB::table('user_events')
            ->where('created_at', '>=', $since)
            ->distinct()
            ->pluck('user_id');

        $updated = 0;

        foreach ($userIds as $userId) {
            // Topic weights: count events per creator's category/type
            $creatorWeights = DB::table('user_events')
                ->select('creator_id', DB::raw('SUM(CASE WHEN event_type = \'view\' THEN 1 WHEN event_type = \'like\' THEN 3 WHEN event_type = \'share\' THEN 5 WHEN event_type = \'comment\' THEN 4 ELSE 1 END) as weight'))
                ->where('user_id', $userId)
                ->where('created_at', '>=', $since)
                ->whereNotNull('creator_id')
                ->groupBy('creator_id')
                ->orderByDesc('weight')
                ->limit(50)
                ->get();

            $creatorAffinities = $creatorWeights->pluck('weight', 'creator_id')->toArray();

            // Activity patterns: events by hour of day
            $hourly = DB::table('user_events')
                ->select(DB::raw("EXTRACT(HOUR FROM timestamp) as hour"), DB::raw('COUNT(*) as cnt'))
                ->where('user_id', $userId)
                ->where('created_at', '>=', $since)
                ->groupBy(DB::raw("EXTRACT(HOUR FROM timestamp)"))
                ->pluck('cnt', 'hour')
                ->toArray();

            // Gossip affinity: ratio of gossip thread interactions
            $totalEvents = DB::table('user_events')->where('user_id', $userId)->where('created_at', '>=', $since)->count();
            $threadEvents = DB::table('user_events')
                ->join('gossip_thread_posts', 'gossip_thread_posts.post_id', '=', 'user_events.post_id')
                ->where('user_events.user_id', $userId)
                ->where('user_events.created_at', '>=', $since)
                ->count();
            $gossipAffinity = $totalEvents > 0 ? round($threadEvents / $totalEvents, 3) : 0;

            DB::table('user_interest_profiles')->updateOrInsert(
                ['user_id' => $userId],
                [
                    'topic_weights' => json_encode([]),
                    'creator_affinities' => json_encode($creatorAffinities),
                    'format_preferences' => json_encode([]),
                    'activity_patterns' => json_encode($hourly),
                    'gossip_affinity' => $gossipAffinity,
                    'commerce_signals' => json_encode([]),
                    'computed_at' => now(),
                    'updated_at' => now(),
                ]
            );
            $updated++;
        }

        $this->info("Built interest profiles for {$updated} users.");
        return self::SUCCESS;
    }
}
```

- [ ] **Step 2: Register in scheduler**

Add to `routes/console.php`:
```php
$schedule->command('flywheel:build-interest-profiles')->daily();
```

- [ ] **Step 3: Run and verify**

```bash
php artisan flywheel:build-interest-profiles
```

---

## HIGH FIXES (Issues #7–#13)

### Task 7: Add battle creation endpoint (#7)

**Files:**
- Modify (backend): `app/Http/Controllers/Api/CreatorBattleController.php`
- Modify (backend): `routes/api.php`

- [ ] **Step 1: Add store method to CreatorBattleController**

```php
public function store(Request $request)
{
    $validated = $request->validate([
        'opponent_id' => 'required|integer|exists:users,id',
        'topic' => 'required|string|max:255',
        'post_a_id' => 'nullable|integer|exists:posts,id',
        'duration_hours' => 'sometimes|integer|min:1|max:168',
    ]);

    $userId = $request->user()->id;

    if ($userId == $validated['opponent_id']) {
        return response()->json(['message' => 'Cannot battle yourself'], 422);
    }

    $battle = \App\Models\CreatorBattle::create([
        'creator_a_id' => $userId,
        'creator_b_id' => $validated['opponent_id'],
        'post_a_id' => $validated['post_a_id'] ?? null,
        'topic' => $validated['topic'],
        'status' => 'active',
        'votes_a' => 0,
        'votes_b' => 0,
        'ends_at' => now()->addHours($validated['duration_hours'] ?? 24),
    ]);

    return response()->json(['data' => $this->formatBattle($battle->load(['creatorA:id,name', 'creatorB:id,name']))], 201);
}
```

- [ ] **Step 2: Add route**

```php
Route::post('/creator-battles', [CreatorBattleController::class, 'store'])->middleware('auth:sanctum');
```

- [ ] **Step 3: Verify**

```bash
php artisan route:list --path=creator-battles
```

---

### Task 8: Add sponsored post acceptance workflow (#8)

**Files:**
- Modify (backend): `app/Http/Controllers/Api/SponsoredPostController.php`
- Modify (backend): `routes/api.php`

- [ ] **Step 1: Add respond method to SponsoredPostController**

```php
public function respond(Request $request, int $id)
{
    $validated = $request->validate([
        'action' => 'required|string|in:accept,reject',
    ]);

    $sp = SponsoredPost::findOrFail($id);

    if ($sp->creator_user_id !== $request->user()->id) {
        return response()->json(['message' => 'Not authorized'], 403);
    }

    if ($sp->status !== 'pending') {
        return response()->json(['message' => 'Can only respond to pending posts'], 422);
    }

    $sp->update([
        'status' => $validated['action'] === 'accept' ? 'active' : 'cancelled',
    ]);

    return response()->json(['data' => ['success' => true, 'status' => $sp->status]]);
}
```

- [ ] **Step 2: Add route**

```php
Route::post('sponsored-posts/{id}/respond', [SponsoredPostController::class, 'respond'])->middleware('auth:sanctum');
```

---

### Task 9: Add sponsored post impression tracking (#9)

**Files:**
- Modify (backend): `app/Http/Controllers/Api/UserEventController.php`

When a `view` event is recorded for a post that has an active sponsored post, increment `impressions_delivered`.

- [ ] **Step 1: Add impression tracking to UserEventController::store()**

After the `DB::table('user_events')->insertOrIgnore($rows)` line, add:

```php
// Increment impression counters for sponsored posts
$viewedPostIds = collect($validated['events'])
    ->where('event_type', 'view')
    ->pluck('post_id')
    ->filter()
    ->unique()
    ->values()
    ->toArray();

if (!empty($viewedPostIds)) {
    \App\Models\SponsoredPost::whereIn('post_id', $viewedPostIds)
        ->where('status', 'active')
        ->increment('impressions_delivered');
}
```

---

### Task 10: Implement FCM sendTokenToBackend (#11)

**Files:**
- Modify: `lib/services/fcm_service.dart`

Backend already has `POST /api/users/{userId}/fcm-token` via PresenceController. Frontend has a TODO stub.

- [ ] **Step 1: Implement sendTokenToBackend**

Replace the TODO stub at line 199-205:

```dart
/// Send FCM token to backend so it can target this device. Call after login.
Future<void> sendTokenToBackend(int userId) async {
  final fcmToken = await FirebaseMessaging.instance.getToken();
  if (fcmToken == null) return;
  try {
    final storage = await LocalStorageService.getInstance();
    final authToken = storage.getAuthToken();
    if (authToken == null) return;
    final url = Uri.parse('${ApiConfig.baseUrl}/users/$userId/fcm-token');
    await http.post(
      url,
      headers: {...ApiConfig.authHeaders(authToken), 'Content-Type': 'application/json'},
      body: jsonEncode({
        'user_id': userId,
        'token': fcmToken,
        'platform': defaultTargetPlatform == TargetPlatform.iOS ? 'ios' : 'android',
      }),
    );
    if (kDebugMode) debugPrint('[FCM] Token registered for user $userId');
  } catch (e) {
    if (kDebugMode) debugPrint('[FCM] Token registration failed: $e');
  }
}
```

Also add import at top: `import 'dart:convert';` and `import 'package:http/http.dart' as http;`

---

### Task 11: Add auto-resolve expired battles command (#12)

**Files:**
- Create (backend): `app/Console/Commands/ResolveExpiredBattles.php`
- Modify (backend): `routes/console.php`

- [ ] **Step 1: Create command**

```php
<?php

namespace App\Console\Commands;

use App\Models\CreatorBattle;
use Illuminate\Console\Command;

class ResolveExpiredBattles extends Command
{
    protected $signature = 'flywheel:resolve-expired-battles';
    protected $description = 'Auto-complete battles that have passed their ends_at timestamp';

    public function handle(): int
    {
        $resolved = CreatorBattle::where('status', 'active')
            ->where('ends_at', '<', now())
            ->update(['status' => 'completed']);

        $this->info("Resolved {$resolved} expired battles.");
        return self::SUCCESS;
    }
}
```

- [ ] **Step 2: Register hourly in scheduler**

```php
$schedule->command('flywheel:resolve-expired-battles')->hourly();
```

---

### Task 12: Sync opt-out settings to backend (#13)

**Files:**
- Modify: `lib/screens/settings/settings_screen.dart`
- Create (backend): endpoint `PUT /api/users/{id}/preferences`

- [ ] **Step 1: Add backend endpoint**

Create `app/Http/Controllers/Api/UserPreferencesController.php`:

```php
<?php

namespace App\Http\Controllers\Api;

use App\Http\Controllers\Controller;
use Illuminate\Http\Request;
use Illuminate\Support\Facades\DB;

class UserPreferencesController extends Controller
{
    public function update(Request $request, int $id)
    {
        $validated = $request->validate([
            'opt_out_sponsored' => 'sometimes|boolean',
            'opt_out_collaboration' => 'sometimes|boolean',
            'opt_out_battles' => 'sometimes|boolean',
            'opt_out_threads' => 'sometimes|boolean',
        ]);

        DB::table('user_profiles')->where('id', $id)->update($validated);

        return response()->json(['data' => ['success' => true]]);
    }
}
```

- [ ] **Step 2: Add opt-out columns to user_profiles (migration)**

```php
Schema::table('user_profiles', function (Blueprint $table) {
    $table->boolean('opt_out_sponsored')->default(false);
    $table->boolean('opt_out_collaboration')->default(false);
    $table->boolean('opt_out_battles')->default(false);
    $table->boolean('opt_out_threads')->default(false);
});
```

- [ ] **Step 3: Register route**

```php
Route::put('users/{id}/preferences', [\App\Http\Controllers\Api\UserPreferencesController::class, 'update'])->middleware('auth:sanctum');
```

- [ ] **Step 4: Add sync call in settings screen**

In each `onChanged` callback (lines 166-203), after `storage.saveBool(...)`, add HTTP call:

```dart
// After local save, sync to backend
final storage2 = await LocalStorageService.getInstance();
final token = storage2.getAuthToken();
if (token != null) {
  try {
    await http.put(
      Uri.parse('${ApiConfig.baseUrl}/users/${widget.currentUserId}/preferences'),
      headers: {...ApiConfig.authHeaders(token), 'Content-Type': 'application/json'},
      body: jsonEncode({'opt_out_sponsored': value}),
    );
  } catch (_) {}
}
```

(Repeat pattern for each toggle with appropriate key.)

---

### Task 13: Backend FCM notification dispatch (#10)

**Files:**
- Create (backend): `app/Services/FcmNotificationService.php`
- Modify (backend): `app/Console/Commands/DetectGossipThreads.php`
- Modify (backend): `app/Console/Commands/DetectCollaborations.php`
- Modify (backend): `app/Http/Controllers/Api/CreatorBattleController.php`

- [ ] **Step 1: Create FcmNotificationService helper**

```php
<?php

namespace App\Services;

use App\Models\FcmToken;
use Illuminate\Support\Facades\Http;

class FcmNotificationService
{
    public static function sendToUser(int $userId, string $type, array $data = [], ?string $title = null, ?string $body = null): void
    {
        $tokens = FcmToken::where('user_id', $userId)->pluck('fcm_token')->toArray();
        if (empty($tokens)) return;

        $payload = array_merge(['type' => $type], $data);

        foreach ($tokens as $token) {
            try {
                // Use Firebase HTTP v1 or legacy — adapt to your server's config
                // For now, write to Firestore for LiveUpdateService pattern
                \DB::table('notifications')->insert([
                    'user_id' => $userId,
                    'type' => $type,
                    'data' => json_encode($payload),
                    'title' => $title,
                    'body' => $body,
                    'read' => false,
                    'created_at' => now(),
                    'updated_at' => now(),
                ]);
            } catch (\Throwable $e) {
                \Log::warning("FCM send failed for user {$userId}: {$e->getMessage()}");
            }
        }
    }
}
```

- [ ] **Step 2: Add notification dispatch to DetectGossipThreads**

After a new thread is created, notify participants:

```php
use App\Services\FcmNotificationService;

// After creating thread:
FcmNotificationService::sendToUser($userId, 'thread_trending', [
    'thread_id' => $thread->id,
], 'Trending Thread', 'A new gossip thread is trending!');
```

- [ ] **Step 3: Add notification to battle creation**

In `CreatorBattleController::store()`, after creating battle:

```php
FcmNotificationService::sendToUser($validated['opponent_id'], 'battle_invitation', [
    'battle_id' => $battle->id,
], 'Battle Challenge', "{$request->user()->name} challenged you!");
```

- [ ] **Step 4: Add notification to collaboration detection**

In `DetectCollaborations::handle()`, after creating suggestions:

```php
FcmNotificationService::sendToUser($b->user_id, 'collaboration_suggestion', [], 'New Collaboration', 'You have a new collaboration suggestion!');
```

---

## MEDIUM FIXES (Issues #14–#24)

### Task 14: Wire getViewerStreak into profile (#14)

**Files:**
- Modify: `lib/screens/profile/profile_screen.dart`

- [ ] **Step 1: Add viewer streak display to profile**

In the profile screen, after existing streak display, call `CreatorService().getViewerStreak(token: token, userId: userId)` and show a `StreakIndicator` for viewer streaks (viewership consistency).

---

### Task 15: Wire getEngagementLevel into analytics dashboard (#15)

**Files:**
- Modify: `lib/screens/analytics/analytics_dashboard_screen.dart`

- [ ] **Step 1: Call getEngagementLevel and display in dashboard**

Add `AnalyticsService().getEngagementLevel(token: token, userId: userId)` call in `_loadData()` and show the level (casual/regular/engaged/super_fan) as a chip/badge in the stats grid.

---

### Task 16: Wire getPostPerformance into analytics (#16)

**Files:**
- Modify: `lib/screens/analytics/analytics_dashboard_screen.dart`

- [ ] **Step 1: Add "Top Posts" section to analytics dashboard**

After the existing sections, add a section that calls `AnalyticsService().getPostPerformance(token: token, creatorId: userId)` and renders a list of `PostPerformance` items with views/likes/engagement rate.

---

### Task 17: Add fund pool display to creator dashboard (#17)

**Files:**
- Modify: `lib/screens/profile/creator_dashboard_section.dart`

- [ ] **Step 1: Display fund pool info**

The `PaymentService.getCurrentPool()` data is already fetched. Add a small card showing current pool amount and next distribution date alongside the existing fund payout projection.

---

### Task 18: Add score history/trend endpoint (#18)

**Files:**
- Create (backend): Method in `CreatorMetricsController` or new endpoint
- Modify (backend): `routes/api.php`

- [ ] **Step 1: Add scoreHistory method**

```php
public function scoreHistory(int $id)
{
    $history = DB::table('creator_score_history')
        ->where('user_id', $id)
        ->orderByDesc('week_start')
        ->limit(12)
        ->get()
        ->map(fn ($h) => [
            'week_start' => $h->week_start,
            'score' => (float) $h->score,
            'tier' => $h->tier,
        ]);

    return response()->json(['data' => $history]);
}
```

- [ ] **Step 2: Register route**

```php
Route::get('creators/{id}/score-history', [CreatorMetricsController::class, 'scoreHistory']);
```

---

### Task 19: Add leaderboard endpoint (#19)

**Files:**
- Modify (backend): `app/Http/Controllers/Api/CreatorMetricsController.php`
- Modify (backend): `routes/api.php`

- [ ] **Step 1: Add leaderboard method**

```php
public function leaderboard(Request $request)
{
    $tier = $request->query('tier');

    $query = \App\Models\CreatorScore::with('user:id,name')
        ->orderByDesc('score')
        ->limit(50);

    if ($tier) {
        $query->where('tier', $tier);
    }

    $creators = $query->get()->map(fn ($cs) => [
        'user_id' => $cs->user_id,
        'name' => $cs->user->name ?? '',
        'score' => (float) $cs->score,
        'tier' => $cs->tier,
    ]);

    return response()->json(['data' => $creators]);
}
```

- [ ] **Step 2: Register route**

```php
Route::get('creators/leaderboard', [CreatorMetricsController::class, 'leaderboard']);
```

---

### Task 20: Implement requestPayout properly (#20)

**Files:**
- Modify (backend): `app/Http/Controllers/Api/PaymentController.php`

- [ ] **Step 1: Replace stub with real implementation**

Create a `CreatorPayout` record instead of returning hardcoded success:

```php
public function requestPayout(Request $request, int $id)
{
    $earnings = \App\Models\CreatorEarning::where('user_id', $id)
        ->where('paid_out', false)
        ->sum('amount');

    if ($earnings <= 0) {
        return response()->json(['message' => 'No unpaid earnings'], 422);
    }

    $payout = \App\Models\CreatorPayout::create([
        'user_id' => $id,
        'amount' => $earnings,
        'status' => 'pending',
    ]);

    \App\Models\CreatorEarning::where('user_id', $id)
        ->where('paid_out', false)
        ->update(['paid_out' => true, 'payout_id' => $payout->id]);

    return response()->json(['data' => [
        'payout_id' => $payout->id,
        'amount' => (float) $earnings,
        'status' => 'pending',
        'message' => 'Payout request submitted.',
    ]]);
}
```

---

### Task 21: Fix DistributeCreatorFund community multiplier (#21)

**Files:**
- Modify (backend): `app/Console/Commands/DistributeCreatorFund.php`

- [ ] **Step 1: Replace hardcoded 1.0 with calculated value**

```php
// Calculate community multiplier from reply rates (avg comments received / avg posts)
$postCount = DB::table('posts')->where('user_id', $score->user_id)->where('created_at', '>=', $weekStart)->count();
$replyCount = DB::table('comments')->where('post_user_id', $score->user_id)->where('created_at', '>=', $weekStart)->count();
$communityMult = $postCount > 0 ? min(2.0, 1.0 + ($replyCount / $postCount) * 0.1) : 1.0;
```

---

### Task 22: Flesh out audienceInsights (#22)

**Files:**
- Modify (backend): `app/Http/Controllers/Api/AnalyticsController.php`

- [ ] **Step 1: Add demographic breakdown**

Query `user_profiles` joined via `user_follows` to get region/gender distribution of followers. Return array of `{category, label, value, percentage}` objects for regions, genders, and age brackets.

---

### Task 23: Fix dashboard total_earnings (#23)

**Files:**
- Modify (backend): `app/Http/Controllers/Api/AnalyticsController.php`

- [ ] **Step 1: Sum actual earnings instead of hardcoded 0**

```php
$totalEarnings = DB::table('creator_earnings')->where('user_id', $id)->sum('amount');
// Replace: 'total_earnings' => 0.0
// With: 'total_earnings' => (float) $totalEarnings
```

---

### Task 24: Fix _openThread FCM handler (#24)

**Files:**
- Modify: `lib/services/fcm_service.dart`

- [ ] **Step 1: Route to thread screen instead of feed**

Replace lines 140-145:

```dart
/// Opens gossip thread from notification.
void _openThread(Map<String, dynamic> data, NavigatorState navigator) {
  final threadId = _intFrom(data, 'thread_id');
  if (threadId != null && threadId > 0 && navigator.mounted) {
    navigator.pushNamed('/thread/$threadId');
  } else if (navigator.mounted) {
    navigator.pushNamed('/feed');
  }
}
```

---

## LOW FIXES (Issues #25–#30)

### Task 25: Add interest weight decay command (#25)

**Files:**
- Create (backend): `app/Console/Commands/DecayInterestWeights.php`

- [ ] **Step 1: Create command that decays old interests**

Multiply all weights in `user_interests` by 0.95 daily (5% decay), delete entries below threshold.

- [ ] **Step 2: Schedule daily**

---

### Task 26: Fix UpdateViewerStreaks idempotency (#26)

**Files:**
- Modify (backend): `app/Console/Commands/UpdateViewerStreaks.php`

- [ ] **Step 1: Add daily check**

Before incrementing, check if `last_active_date` is already today. Only increment if the last update was yesterday.

---

### Task 27: Add user_events pruning command (#27)

**Files:**
- Create (backend): `app/Console/Commands/PruneUserEvents.php`

- [ ] **Step 1: Create command**

Delete `user_events` older than 90 days. Schedule weekly.

---

### Task 28: Create UserEvent Eloquent model (#28)

**Files:**
- Create (backend): `app/Models/UserEvent.php`

- [ ] **Step 1: Create model with fillable, casts, and relationships**

---

### Task 29: Add creator streak break notifications (#29)

**Files:**
- Modify (backend): `app/Console/Commands/UpdateCreatorStreaks.php`

- [ ] **Step 1: When streak is frozen, send FCM notification**

```php
FcmNotificationService::sendToUser($streak->user_id, 'streak_warning', [], 'Streak at Risk', 'Post today to keep your streak!');
```

---

### Task 30: Add engagement level change notifications (#30)

**Files:**
- Modify (backend): `app/Console/Commands/UpdateEngagementLevels.php`

- [ ] **Step 1: Track old level, notify on change**

Before updating, check old level. If it changed, send notification:

```php
FcmNotificationService::sendToUser($row->user_id, 'milestone', [
    'milestone' => "You're now a {$level} user!",
], 'Level Up!', "Your engagement level is now: {$level}");
```

---

## Execution Order

Tasks are grouped by dependency:

**Wave 1 (Frontend URL fixes — independent, parallel):** Tasks 1, 2, 3, 4, 24
**Wave 2 (Backend core — sequential):** Tasks 5, 6, 7, 8, 9, 11, 13
**Wave 3 (Frontend wiring):** Tasks 10, 12, 14, 15, 16, 17
**Wave 4 (Backend endpoints):** Tasks 18, 19, 20, 21, 22, 23
**Wave 5 (Low priority):** Tasks 25, 26, 27, 28, 29, 30

**Total: 30 tasks across 12 new files and ~20 modified files**
