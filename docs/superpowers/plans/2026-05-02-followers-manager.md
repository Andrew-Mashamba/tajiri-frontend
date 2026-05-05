# Followers Manager Implementation Plan

> **For agentic workers:** REQUIRED SUB-SKILL: Use superpowers:subagent-driven-development (recommended) or superpowers:executing-plans to implement this plan task-by-task. Steps use checkbox (`- [ ]`) syntax for tracking.

**Goal:** Build a full‑page Followers manager for profile owners — search, sort, filter (new / inactive / mutual gap), per‑row actions (view, mute, remove, block), bulk multi‑select, and CSV export — backed by 8 new endpoints and a `user_mutes` table.

**Architecture:** Owner‑only Flutter screen at `/followers/manage`, gated by `_isOwnProfile` on `profile_screen.dart`. Visitor bottom sheet stays unchanged. Backend extends `FollowController` for list / insights / remove / bulk‑remove / CSV; new `UserMuteController` for mute endpoints; `BlockController` gains a bulk endpoint. Filters / sort / search are server‑side; pagination 30/page; live `MAX(...)` over four interaction tables for `last_interaction_at` (denormalize past 10k followers).

**Tech Stack:** Flutter 3.10.1 (Dart, `setState`, `ValueNotifier`), `cached_network_image`, `dio`, `share_plus`, `http`. Laravel 12 + PostgreSQL 16 backend (Eloquent models matching `FollowController` style).

**Spec:** `docs/superpowers/specs/2026-05-02-followers-manager-design.md`

**House rules carried forward:**
- No git commits in any task — user rule (per `feedback_no_git_stuff.md`).
- Backend changes deploy via `./scripts/ask_backend.sh` first, falling back to SSH (`sshpass -p 'ZimaBlueApps' ssh -o StrictHostKeyChecking=no root@172.240.241.180`, project at `/var/www/tajiri.zimasystems.com`) per playbook §169.
- Every backend endpoint must be verified with `curl` before frontend wiring.
- `flutter analyze` must report zero new errors after every frontend task.
- Bilingual via inline `isSwahili ? sw : en` ternaries; no new `AppStrings` getters unless reused elsewhere.

---

## Task 1: Backend — `user_mutes` migration

**Files:**
- Create: `/var/www/tajiri.zimasystems.com/database/migrations/2026_05_02_210000_create_user_mutes_table.php` (on server)

- [ ] **Step 1: Author the migration**

```php
<?php

use Illuminate\Database\Migrations\Migration;
use Illuminate\Database\Schema\Blueprint;
use Illuminate\Support\Facades\Schema;

return new class extends Migration {
    public function up(): void
    {
        Schema::create('user_mutes', function (Blueprint $table) {
            $table->id();
            $table->unsignedBigInteger('muter_user_id');
            $table->unsignedBigInteger('muted_user_id');
            $table->timestamp('created_at')->useCurrent();

            $table->unique(['muter_user_id', 'muted_user_id']);
            $table->index('muter_user_id');
            $table->index('muted_user_id');

            $table->foreign('muter_user_id')->references('id')->on('user_profiles')->onDelete('cascade');
            $table->foreign('muted_user_id')->references('id')->on('user_profiles')->onDelete('cascade');
        });
    }

    public function down(): void
    {
        Schema::dropIfExists('user_mutes');
    }
};
```

- [ ] **Step 2: Deploy & run migration**

Try `./scripts/ask_backend.sh "Create migration database/migrations/2026_05_02_210000_create_user_mutes_table.php with the contents I'll paste, then run php artisan migrate"`. If that fails, SSH to the server, write the file, and run:

```bash
sshpass -p 'ZimaBlueApps' ssh -o StrictHostKeyChecking=no root@172.240.241.180 \
  "cd /var/www/tajiri.zimasystems.com && php artisan migrate"
```

Expected output includes: `Migrating: 2026_05_02_210000_create_user_mutes_table` then `Migrated`.

- [ ] **Step 3: Verify table exists**

```bash
sshpass -p 'ZimaBlueApps' ssh -o StrictHostKeyChecking=no root@172.240.241.180 \
  "PGPASSWORD=postgres psql -U postgres -h localhost -d tajiri -c '\\d user_mutes'"
```

Expected: prints columns `id`, `muter_user_id`, `muted_user_id`, `created_at` and the two indexes + unique.

---

## Task 2: Backend — extend `FollowController::followers` with `q`, `filter`, `sort`, new fields

**Files:**
- Modify: `/var/www/tajiri.zimasystems.com/app/Http/Controllers/Api/FollowController.php` (`followers()` method, currently line 109)

- [ ] **Step 1: Replace `followers()` with the extended version**

The existing method ignores `q`, `filter`, `sort` and omits `last_interaction_at`, `is_mutual`, `is_muted`. Replace its body with:

```php
public function followers(int $userId, Request $request): JsonResponse
{
    $profile = UserProfile::find($userId);
    if (!$profile) {
        return response()->json(['success' => false, 'message' => 'User not found'], 404);
    }

    $currentUserId = $request->input('current_user_id');
    $perPage = min((int) $request->input('per_page', 20), 50);
    $q = ltrim(trim((string) $request->input('q', '')), '@');
    $filter = $request->input('filter');           // new | inactive | mutual_gap | null
    $sort = $request->input('sort', 'newest');     // newest | oldest | name

    // Owner-only: any of q/filter/sort requires the caller to be the owner.
    $authedId = optional($request->user())->id;
    if (($q !== '' || $filter || in_array($sort, ['oldest', 'name'], true))
        && (int) $authedId !== $userId) {
        return response()->json(['success' => false, 'message' => 'Forbidden'], 403);
    }

    $blockedIds = $currentUserId ? BlockedUser::getAllBlockedIds((int) $currentUserId) : [];

    $base = UserFollow::where('following_id', $userId)
        ->when(!empty($blockedIds), fn ($qry) => $qry->whereNotIn('follower_id', $blockedIds));

    // Join user_profiles for q + name sort.
    $base->join('user_profiles as p', 'p.id', '=', 'user_follows.follower_id');

    if ($q !== '') {
        $base->where(function ($qry) use ($q) {
            $qry->where('p.username', 'ilike', $q . '%')
                ->orWhereRaw("concat(coalesce(p.first_name,''), ' ', coalesce(p.last_name,'')) ilike ?", ['%' . $q . '%']);
        });
    }

    // filter: new (7d), inactive (60d), mutual_gap (owner does not follow them back)
    if ($filter === 'new') {
        $base->where('user_follows.created_at', '>=', now()->subDays(7));
    } elseif ($filter === 'mutual_gap') {
        $base->whereNotExists(function ($qry) use ($userId) {
            $qry->select(DB::raw(1))
                ->from('user_follows as uf2')
                ->whereColumn('uf2.following_id', 'user_follows.follower_id')
                ->where('uf2.follower_id', $userId);
        });
    } elseif ($filter === 'inactive') {
        // 60d-no-interaction filter is applied AFTER hydration since
        // last_interaction_at is computed per-row (see below).
    }

    // sort
    if ($sort === 'oldest') {
        $base->orderBy('user_follows.created_at', 'asc');
    } elseif ($sort === 'name') {
        $base->orderByRaw("coalesce(p.first_name,'') || ' ' || coalesce(p.last_name,'') asc")
             ->orderBy('p.username', 'asc');
    } else {
        $base->orderBy('user_follows.created_at', 'desc');
    }

    $base->select('user_follows.*', 'p.id as p_id');
    $followers = $base->paginate($perPage);

    $followerIds = $followers->getCollection()->pluck('follower_id');

    $followerProfiles = UserProfile::whereIn('id', $followerIds)
        ->get(['id', 'first_name', 'last_name', 'username', 'profile_photo_path'])
        ->keyBy('id');

    // last_interaction_at = MAX over likes/comments/reactions/shares
    // where post owner = $userId and actor in $followerIds.
    $interaction = collect();
    if ($followerIds->isNotEmpty()) {
        $interaction = DB::table('posts')
            ->where('posts.user_id', $userId)
            ->leftJoin('post_likes', 'post_likes.post_id', '=', 'posts.id')
            ->leftJoin('post_comments', 'post_comments.post_id', '=', 'posts.id')
            ->leftJoin('post_reactions', 'post_reactions.post_id', '=', 'posts.id')
            ->leftJoin('post_shares', 'post_shares.post_id', '=', 'posts.id')
            ->select(DB::raw(<<<SQL
                COALESCE(post_likes.user_id,
                         post_comments.user_id,
                         post_reactions.user_id,
                         post_shares.user_id) as actor_id,
                GREATEST(
                  COALESCE(post_likes.created_at,     '1970-01-01'::timestamp),
                  COALESCE(post_comments.created_at,  '1970-01-01'::timestamp),
                  COALESCE(post_reactions.created_at, '1970-01-01'::timestamp),
                  COALESCE(post_shares.created_at,    '1970-01-01'::timestamp)
                ) as last_at
            SQL))
            ->whereIn(DB::raw('COALESCE(post_likes.user_id, post_comments.user_id, post_reactions.user_id, post_shares.user_id)'), $followerIds)
            ->get()
            ->groupBy('actor_id')
            ->map(fn ($rows) => $rows->max('last_at'));
    }

    // mutual: owner follows the follower back?
    $mutualIds = UserFollow::where('follower_id', $userId)
        ->whereIn('following_id', $followerIds)
        ->pluck('following_id')
        ->all();
    $mutualSet = array_flip($mutualIds);

    // muted by owner?
    $mutedIds = DB::table('user_mutes')
        ->where('muter_user_id', $userId)
        ->whereIn('muted_user_id', $followerIds)
        ->pluck('muted_user_id')
        ->all();
    $mutedSet = array_flip($mutedIds);

    $rows = $followers->getCollection()->map(function ($follow) use ($followerProfiles, $interaction, $mutualSet, $mutedSet) {
        $profile = $followerProfiles->get($follow->follower_id);
        if (!$profile) return null;
        $lastAt = $interaction->get($profile->id);
        return [
            'id' => $profile->id,
            'name' => trim(($profile->first_name ?? '') . ' ' . ($profile->last_name ?? '')),
            'username' => $profile->username,
            'photo_url' => $profile->profile_photo_url,
            'followed_at' => $follow->created_at?->toIso8601String(),
            'last_interaction_at' => $lastAt,
            'is_mutual' => isset($mutualSet[$profile->id]),
            'is_muted' => isset($mutedSet[$profile->id]),
        ];
    })->filter();

    if ($filter === 'inactive') {
        $cutoff = now()->subDays(60)->toIso8601String();
        $rows = $rows->filter(fn ($r) => $r['last_interaction_at'] === null || $r['last_interaction_at'] < $cutoff);
    }

    return response()->json([
        'success' => true,
        'data' => $rows->values(),
        'message' => 'Followers retrieved',
        'meta' => [
            'pagination' => [
                'current_page' => $followers->currentPage(),
                'last_page' => $followers->lastPage(),
                'per_page' => $followers->perPage(),
                'total' => $followers->total(),
            ],
        ],
    ]);
}
```

If `DB` is not yet imported at the top of the file, add `use Illuminate\Support\Facades\DB;`.

- [ ] **Step 2: Smoke test (visitor mode — no filters)**

```bash
TOKEN=$(curl -s -X POST 'https://tajiri.zimasystems.com/api/auth/login' \
  -H 'Content-Type: application/json' \
  -d '{"email":"andrew.s.mashamba@gmail.com","password":"password"}' | jq -r .data.token)

curl -s "https://tajiri.zimasystems.com/api/users/1/followers?per_page=2" \
  -H "Authorization: Bearer $TOKEN" | jq '.data[0]'
```

Expected: each row contains the new fields `last_interaction_at`, `is_mutual`, `is_muted` (plus the existing `id`, `name`, `username`, `photo_url`, `followed_at`).

- [ ] **Step 3: Smoke test (owner mode — filter + sort)**

```bash
# Replace OWNER_ID with the auth'd user's id from $TOKEN.
OWNER_ID=1
curl -s "https://tajiri.zimasystems.com/api/users/$OWNER_ID/followers?filter=new&sort=oldest&q=jane&per_page=5" \
  -H "Authorization: Bearer $TOKEN" | jq '.success, .data | length'
```

Expected: `true` and a number ≤5; result rows all have `followed_at >= now-7d`.

- [ ] **Step 4: Smoke test (forbidden — non-owner with filter)**

```bash
# Hit OTHER user's followers with filter; should 403.
curl -s -o /dev/null -w "%{http_code}\n" \
  "https://tajiri.zimasystems.com/api/users/9999/followers?filter=new" \
  -H "Authorization: Bearer $TOKEN"
```

Expected: `403`.

---

## Task 3: Backend — `GET /users/{id}/followers/insights`

**Files:**
- Modify: `/var/www/tajiri.zimasystems.com/app/Http/Controllers/Api/FollowController.php`
- Modify: `/var/www/tajiri.zimasystems.com/routes/api.php`

- [ ] **Step 1: Add `followerInsights()` method to `FollowController`**

Place directly under `followers()`:

```php
public function followerInsights(int $userId, Request $request): JsonResponse
{
    if ((int) optional($request->user())->id !== $userId) {
        return response()->json(['success' => false, 'message' => 'Forbidden'], 403);
    }

    $total = UserFollow::where('following_id', $userId)->count();

    $newThisWeek = UserFollow::where('following_id', $userId)
        ->where('created_at', '>=', now()->subDays(7))
        ->count();

    // mutual gap = followers I do NOT follow back
    $mutualGap = UserFollow::where('user_follows.following_id', $userId)
        ->whereNotExists(function ($q) use ($userId) {
            $q->select(DB::raw(1))
              ->from('user_follows as uf2')
              ->whereColumn('uf2.following_id', 'user_follows.follower_id')
              ->where('uf2.follower_id', $userId);
        })
        ->count();

    // inactive = followers with no like/comment/reaction/share on my posts in 60d
    $cutoff = now()->subDays(60);
    $followerIds = UserFollow::where('following_id', $userId)->pluck('follower_id');
    $activeIds = DB::table('posts')
        ->where('posts.user_id', $userId)
        ->leftJoin('post_likes',     'post_likes.post_id',     '=', 'posts.id')
        ->leftJoin('post_comments',  'post_comments.post_id',  '=', 'posts.id')
        ->leftJoin('post_reactions', 'post_reactions.post_id', '=', 'posts.id')
        ->leftJoin('post_shares',    'post_shares.post_id',    '=', 'posts.id')
        ->where(function ($q) use ($cutoff) {
            $q->where('post_likes.created_at',     '>=', $cutoff)
              ->orWhere('post_comments.created_at',  '>=', $cutoff)
              ->orWhere('post_reactions.created_at', '>=', $cutoff)
              ->orWhere('post_shares.created_at',    '>=', $cutoff);
        })
        ->select(DB::raw('DISTINCT COALESCE(post_likes.user_id, post_comments.user_id, post_reactions.user_id, post_shares.user_id) as actor_id'))
        ->pluck('actor_id')
        ->filter();
    $inactive = $followerIds->diff($activeIds)->count();

    return response()->json([
        'success' => true,
        'data' => [
            'total' => $total,
            'new_this_week' => $newThisWeek,
            'inactive_60d' => $inactive,
            'mutual_gap' => $mutualGap,
        ],
        'message' => 'Insights retrieved',
    ]);
}
```

- [ ] **Step 2: Register the route**

Find the existing `Route::get('/{userId}/followers', ...)` line in `routes/api.php` (line 429) and add immediately after, inside the same group:

```php
Route::get('/{userId}/followers/insights', [FollowController::class, 'followerInsights']);
```

- [ ] **Step 3: Smoke test**

```bash
curl -s "https://tajiri.zimasystems.com/api/users/$OWNER_ID/followers/insights" \
  -H "Authorization: Bearer $TOKEN" | jq
```

Expected: `{success:true, data:{total:N, new_this_week:N, inactive_60d:N, mutual_gap:N}}`.

- [ ] **Step 4: Smoke test (forbidden)**

```bash
curl -s -o /dev/null -w "%{http_code}\n" \
  "https://tajiri.zimasystems.com/api/users/9999/followers/insights" \
  -H "Authorization: Bearer $TOKEN"
```

Expected: `403`.

---

## Task 4: Backend — remove follower (single + bulk)

**Files:**
- Modify: `/var/www/tajiri.zimasystems.com/app/Http/Controllers/Api/FollowController.php`
- Modify: `/var/www/tajiri.zimasystems.com/routes/api.php`

- [ ] **Step 1: Add the two methods to `FollowController`**

```php
public function removeFollower(int $userId, int $followerId, Request $request): JsonResponse
{
    if ((int) optional($request->user())->id !== $userId) {
        return response()->json(['success' => false, 'message' => 'Forbidden'], 403);
    }

    UserFollow::where('following_id', $userId)
        ->where('follower_id', $followerId)
        ->delete(); // idempotent

    return response()->json(['success' => true, 'message' => 'Follower removed']);
}

public function bulkRemoveFollowers(int $userId, Request $request): JsonResponse
{
    if ((int) optional($request->user())->id !== $userId) {
        return response()->json(['success' => false, 'message' => 'Forbidden'], 403);
    }

    $ids = (array) $request->input('ids', []);
    if (count($ids) === 0)  return response()->json(['success' => false, 'message' => 'No ids supplied'], 422);
    if (count($ids) > 50)   return response()->json(['success' => false, 'message' => 'Up to 50 at a time'], 422);
    $ids = array_values(array_unique(array_map('intval', $ids)));

    $removed = 0;
    DB::transaction(function () use ($userId, $ids, &$removed) {
        $removed = UserFollow::where('following_id', $userId)
            ->whereIn('follower_id', $ids)
            ->delete();
    });

    return response()->json([
        'success' => true,
        'data' => ['removed' => $removed],
        'message' => "$removed follower(s) removed",
    ]);
}
```

- [ ] **Step 2: Register the routes**

In `routes/api.php` under the same group as the existing followers route:

```php
Route::delete('/{userId}/followers/{followerId}', [FollowController::class, 'removeFollower']);
Route::post('/{userId}/followers/bulk-remove',    [FollowController::class, 'bulkRemoveFollowers']);
```

- [ ] **Step 3: Smoke test single remove**

Pick a known follower id (`FID`) for `OWNER_ID` from the list endpoint, then:

```bash
curl -s -X DELETE "https://tajiri.zimasystems.com/api/users/$OWNER_ID/followers/$FID" \
  -H "Authorization: Bearer $TOKEN" | jq
```

Expected: `{success:true,...}`. Re-running returns the same — idempotent.

- [ ] **Step 4: Smoke test bulk remove**

```bash
curl -s -X POST "https://tajiri.zimasystems.com/api/users/$OWNER_ID/followers/bulk-remove" \
  -H "Authorization: Bearer $TOKEN" -H "Content-Type: application/json" \
  -d '{"ids":[101,102,103]}' | jq
```

Expected: `{success:true, data:{removed:N}}`.

- [ ] **Step 5: Smoke test cap**

```bash
# 51 ids → 422
curl -s -X POST "https://tajiri.zimasystems.com/api/users/$OWNER_ID/followers/bulk-remove" \
  -H "Authorization: Bearer $TOKEN" -H "Content-Type: application/json" \
  -d "$(jq -nc '{ids: ([range(51)] | map(. + 1000))}')" | jq .message
```

Expected: `"Up to 50 at a time"`.

---

## Task 5: Backend — mute system (`UserMuteController` + 3 routes)

**Files:**
- Create: `/var/www/tajiri.zimasystems.com/app/Http/Controllers/Api/UserMuteController.php`
- Modify: `/var/www/tajiri.zimasystems.com/routes/api.php`

- [ ] **Step 1: Author the controller**

```php
<?php

namespace App\Http\Controllers\Api;

use App\Http\Controllers\Controller;
use Illuminate\Http\JsonResponse;
use Illuminate\Http\Request;
use Illuminate\Support\Facades\DB;

/**
 * UserMuteController — owner-only mute / unmute / bulk-mute.
 *
 * Mute = the muter doesn't see the muted user's posts/comments on their
 * content. Distinct from block. Idempotent. Downstream feed/comment
 * filtering of muted users is a separate concern (see spec §1).
 */
class UserMuteController extends Controller
{
    public function store(int $userId, Request $request): JsonResponse
    {
        if ((int) optional($request->user())->id !== $userId) {
            return response()->json(['success' => false, 'message' => 'Forbidden'], 403);
        }

        $request->validate(['muted_user_id' => 'required|integer|exists:user_profiles,id|different:'.$userId]);
        $mutedId = (int) $request->input('muted_user_id');

        DB::table('user_mutes')->updateOrInsert(
            ['muter_user_id' => $userId, 'muted_user_id' => $mutedId],
            ['created_at' => now()],
        );

        return response()->json(['success' => true, 'message' => 'Muted']);
    }

    public function destroy(int $userId, int $mutedUserId, Request $request): JsonResponse
    {
        if ((int) optional($request->user())->id !== $userId) {
            return response()->json(['success' => false, 'message' => 'Forbidden'], 403);
        }

        DB::table('user_mutes')
            ->where('muter_user_id', $userId)
            ->where('muted_user_id', $mutedUserId)
            ->delete();

        return response()->json(['success' => true, 'message' => 'Unmuted']);
    }

    public function bulkStore(int $userId, Request $request): JsonResponse
    {
        if ((int) optional($request->user())->id !== $userId) {
            return response()->json(['success' => false, 'message' => 'Forbidden'], 403);
        }

        $ids = (array) $request->input('ids', []);
        if (count($ids) === 0) return response()->json(['success' => false, 'message' => 'No ids supplied'], 422);
        if (count($ids) > 50)  return response()->json(['success' => false, 'message' => 'Up to 50 at a time'], 422);

        $ids = array_values(array_unique(array_filter(array_map('intval', $ids), fn ($i) => $i !== $userId)));
        $now = now();
        $rows = array_map(fn ($id) => [
            'muter_user_id' => $userId,
            'muted_user_id' => $id,
            'created_at' => $now,
        ], $ids);

        // ON CONFLICT DO NOTHING via upsert with composite unique.
        DB::table('user_mutes')->upsert($rows, ['muter_user_id', 'muted_user_id'], ['created_at']);

        return response()->json([
            'success' => true,
            'data' => ['muted' => count($ids)],
            'message' => count($ids).' muted',
        ]);
    }
}
```

- [ ] **Step 2: Register routes**

Inside the `auth:api` group in `routes/api.php` near the followers routes:

```php
Route::post('/users/{userId}/mutes',                       [UserMuteController::class, 'store']);
Route::delete('/users/{userId}/mutes/{mutedUserId}',       [UserMuteController::class, 'destroy']);
Route::post('/users/{userId}/mutes/bulk',                  [UserMuteController::class, 'bulkStore']);
```

Add `use App\Http\Controllers\Api\UserMuteController;` if absent.

- [ ] **Step 3: Smoke test single mute**

```bash
curl -s -X POST "https://tajiri.zimasystems.com/api/users/$OWNER_ID/mutes" \
  -H "Authorization: Bearer $TOKEN" -H "Content-Type: application/json" \
  -d "{\"muted_user_id\": $FID}" | jq
```

Expected: `{success:true, message:"Muted"}`. Repeat — same response (idempotent).

Verify in DB:
```bash
sshpass -p 'ZimaBlueApps' ssh -o StrictHostKeyChecking=no root@172.240.241.180 \
  "PGPASSWORD=postgres psql -U postgres -h localhost -d tajiri -c \"select * from user_mutes where muter_user_id=$OWNER_ID;\""
```

- [ ] **Step 4: Smoke test unmute**

```bash
curl -s -X DELETE "https://tajiri.zimasystems.com/api/users/$OWNER_ID/mutes/$FID" \
  -H "Authorization: Bearer $TOKEN" | jq
```

Expected: `{success:true, message:"Unmuted"}`. DB row gone.

- [ ] **Step 5: Smoke test bulk mute**

```bash
curl -s -X POST "https://tajiri.zimasystems.com/api/users/$OWNER_ID/mutes/bulk" \
  -H "Authorization: Bearer $TOKEN" -H "Content-Type: application/json" \
  -d '{"ids":[101,102,103]}' | jq
```

Expected: `{success:true, data:{muted:3}}`.

---

## Task 6: Backend — bulk block

**Files:**
- Modify: existing block controller (find via `grep -rn "function block(" /var/www/tajiri.zimasystems.com/app/Http/Controllers/Api/`)
- Modify: `/var/www/tajiri.zimasystems.com/routes/api.php`

- [ ] **Step 1: Identify the block controller**

```bash
sshpass -p 'ZimaBlueApps' ssh -o StrictHostKeyChecking=no root@172.240.241.180 \
  "grep -rn 'public function block(' /var/www/tajiri.zimasystems.com/app/Http/Controllers/Api/"
```

Note the file path — call it `BLOCK_CTRL`. (Likely `BlockedUserController.php` or similar.)

- [ ] **Step 2: Add `bulkBlock()` method**

```php
public function bulkBlock(Request $request): JsonResponse
{
    $request->validate([
        'user_id' => 'required|integer',
        'blocked_user_ids' => 'required|array|min:1|max:50',
        'blocked_user_ids.*' => 'integer',
    ]);

    $userId = (int) $request->input('user_id');
    if ((int) optional($request->user())->id !== $userId) {
        return response()->json(['success' => false, 'message' => 'Forbidden'], 403);
    }

    $ids = array_values(array_unique(array_filter(
        array_map('intval', $request->input('blocked_user_ids', [])),
        fn ($i) => $i !== $userId,
    )));

    $now = now();
    $rows = array_map(fn ($id) => [
        'user_id' => $userId,
        'blocked_user_id' => $id,
        'created_at' => $now,
        'updated_at' => $now,
    ], $ids);

    DB::table('blocked_users')->upsert($rows, ['user_id', 'blocked_user_id'], ['updated_at']);

    // Drop reciprocal follow edges so the blocked users can't see content.
    DB::table('user_follows')
        ->where('follower_id', $userId)->whereIn('following_id', $ids)
        ->delete();
    DB::table('user_follows')
        ->where('following_id', $userId)->whereIn('follower_id', $ids)
        ->delete();

    return response()->json([
        'success' => true,
        'data' => ['blocked' => count($ids)],
        'message' => count($ids).' blocked',
    ]);
}
```

(Adjust column names if the existing single-`block()` shows different column names — match it.)

- [ ] **Step 3: Register the route**

```php
Route::post('/users/block-bulk', [BlockedUserController::class, 'bulkBlock']);
```

(Use the actual controller class identified in Step 1.)

- [ ] **Step 4: Smoke test**

```bash
curl -s -X POST "https://tajiri.zimasystems.com/api/users/block-bulk" \
  -H "Authorization: Bearer $TOKEN" -H "Content-Type: application/json" \
  -d "{\"user_id\":$OWNER_ID,\"blocked_user_ids\":[201,202]}" | jq
```

Expected: `{success:true, data:{blocked:2}}`.

---

## Task 7: Backend — `GET /users/{id}/followers/export.csv`

**Files:**
- Modify: `/var/www/tajiri.zimasystems.com/app/Http/Controllers/Api/FollowController.php`
- Modify: `/var/www/tajiri.zimasystems.com/routes/api.php`

- [ ] **Step 1: Add `exportFollowersCsv()` to `FollowController`**

```php
public function exportFollowersCsv(int $userId, Request $request)
{
    if ((int) optional($request->user())->id !== $userId) {
        return response()->json(['success' => false, 'message' => 'Forbidden'], 403);
    }

    $cap = 50000;
    $rows = UserFollow::where('user_follows.following_id', $userId)
        ->join('user_profiles as p', 'p.id', '=', 'user_follows.follower_id')
        ->orderBy('user_follows.created_at', 'desc')
        ->limit($cap)
        ->get(['user_follows.follower_id', 'user_follows.created_at', 'p.first_name', 'p.last_name', 'p.username']);

    $mutualIds = UserFollow::where('follower_id', $userId)
        ->whereIn('following_id', $rows->pluck('follower_id'))
        ->pluck('following_id')->all();
    $mutualSet = array_flip($mutualIds);

    $mutedIds = DB::table('user_mutes')
        ->where('muter_user_id', $userId)
        ->whereIn('muted_user_id', $rows->pluck('follower_id'))
        ->pluck('muted_user_id')->all();
    $mutedSet = array_flip($mutedIds);

    $today = now()->format('Y-m-d');
    $filename = "followers-{$today}.csv";

    return response()->stream(function () use ($rows, $mutualSet, $mutedSet) {
        $out = fopen('php://output', 'w');
        fputcsv($out, ['id', 'name', 'username', 'followed_at', 'is_mutual', 'is_muted']);
        foreach ($rows as $r) {
            fputcsv($out, [
                $r->follower_id,
                trim(($r->first_name ?? '').' '.($r->last_name ?? '')),
                $r->username,
                $r->created_at?->toIso8601String(),
                isset($mutualSet[$r->follower_id]) ? 'true' : 'false',
                isset($mutedSet[$r->follower_id]) ? 'true' : 'false',
            ]);
        }
        fclose($out);
    }, 200, [
        'Content-Type' => 'text/csv',
        'Content-Disposition' => "attachment; filename=\"$filename\"",
    ]);
}
```

- [ ] **Step 2: Register the route**

```php
Route::get('/{userId}/followers/export.csv', [FollowController::class, 'exportFollowersCsv']);
```

- [ ] **Step 3: Smoke test**

```bash
curl -s -o /tmp/followers.csv -w "%{http_code} %{content_type}\n" \
  "https://tajiri.zimasystems.com/api/users/$OWNER_ID/followers/export.csv" \
  -H "Authorization: Bearer $TOKEN"
head -3 /tmp/followers.csv
```

Expected: `200 text/csv;...`, file starts with header `id,name,username,followed_at,is_mutual,is_muted`.

---

## Task 8: Frontend — model extensions

**Files:**
- Modify: `lib/models/friend_models.dart`

- [ ] **Step 1: Locate `FollowerProfile` (or whatever name the existing follower row class uses) and the `FollowListResult` class**

Run `grep -n "class Follower\|class FollowList" lib/models/friend_models.dart`. Add three fields to the row class and a parser block in its `fromJson`:

```dart
final DateTime? lastInteractionAt;
final bool isMutual;
final bool isMuted;

// in constructor:
this.lastInteractionAt,
this.isMutual = false,
this.isMuted = false,

// in fromJson:
lastInteractionAt: json['last_interaction_at'] != null
    ? DateTime.tryParse(json['last_interaction_at'].toString())
    : null,
isMutual: (json['is_mutual'] ?? false) == true,
isMuted: (json['is_muted'] ?? false) == true,
```

- [ ] **Step 2: Append `FollowerInsights` class to the same file**

```dart
class FollowerInsights {
  final int total;
  final int newThisWeek;
  final int inactive60d;
  final int mutualGap;

  const FollowerInsights({
    required this.total,
    required this.newThisWeek,
    required this.inactive60d,
    required this.mutualGap,
  });

  factory FollowerInsights.fromJson(Map<String, dynamic> json) => FollowerInsights(
        total: (json['total'] as num?)?.toInt() ?? 0,
        newThisWeek: (json['new_this_week'] as num?)?.toInt() ?? 0,
        inactive60d: (json['inactive_60d'] as num?)?.toInt() ?? 0,
        mutualGap: (json['mutual_gap'] as num?)?.toInt() ?? 0,
      );

  static const empty = FollowerInsights(total: 0, newThisWeek: 0, inactive60d: 0, mutualGap: 0);
}
```

- [ ] **Step 3: Verify**

```bash
flutter analyze lib/models/friend_models.dart
```

Expected: no new errors.

---

## Task 9: Frontend — `FriendService` method additions

**Files:**
- Modify: `lib/services/friend_service.dart`

- [ ] **Step 1: Add the 9 new methods**

Place them grouped in a `// region Followers manager` block:

```dart
// region Followers manager ──────────────────────────────────────────

/// Owner-mode followers list — includes filter / sort / search.
Future<FollowListResult> getOwnerFollowers({
  required int userId,
  int page = 1,
  int perPage = 30,
  String? q,
  String? filter,        // 'new' | 'inactive' | 'mutual_gap' | null
  String? sort,          // 'newest' | 'oldest' | 'name' | null
}) async {
  final token = await LocalStorageService.getInstance().getAuthToken();
  final params = <String, String>{
    'page': '$page',
    'per_page': '$perPage',
    if (q != null && q.isNotEmpty) 'q': q,
    if (filter != null) 'filter': filter,
    if (sort != null) 'sort': sort,
  };
  final uri = Uri.parse('$_baseUrl/users/$userId/followers')
      .replace(queryParameters: params);
  final response = await http.get(uri, headers: ApiConfig.authHeaders(token));
  if (response.statusCode == 200) {
    final body = jsonDecode(response.body) as Map<String, dynamic>;
    return FollowListResult.fromJson(body);
  }
  return FollowListResult(success: false, message: 'Failed to load followers');
}

Future<FollowerInsights?> getFollowerInsights({required int userId}) async {
  final token = await LocalStorageService.getInstance().getAuthToken();
  final response = await http.get(
    Uri.parse('$_baseUrl/users/$userId/followers/insights'),
    headers: ApiConfig.authHeaders(token),
  );
  if (response.statusCode == 200) {
    final body = jsonDecode(response.body) as Map<String, dynamic>;
    if (body['success'] == true) {
      return FollowerInsights.fromJson(body['data'] as Map<String, dynamic>);
    }
  }
  return null;
}

Future<bool> removeFollower({required int userId, required int followerId}) async {
  final token = await LocalStorageService.getInstance().getAuthToken();
  final response = await http.delete(
    Uri.parse('$_baseUrl/users/$userId/followers/$followerId'),
    headers: ApiConfig.authHeaders(token),
  );
  return response.statusCode == 200 && jsonDecode(response.body)['success'] == true;
}

Future<int> bulkRemoveFollowers({required int userId, required List<int> ids}) async {
  final token = await LocalStorageService.getInstance().getAuthToken();
  final response = await http.post(
    Uri.parse('$_baseUrl/users/$userId/followers/bulk-remove'),
    headers: {...ApiConfig.authHeaders(token), 'Content-Type': 'application/json'},
    body: jsonEncode({'ids': ids}),
  );
  if (response.statusCode == 200) {
    final body = jsonDecode(response.body) as Map<String, dynamic>;
    if (body['success'] == true) return (body['data']?['removed'] as num?)?.toInt() ?? 0;
  }
  return 0;
}

Future<bool> muteUser({required int userId, required int mutedUserId}) async {
  final token = await LocalStorageService.getInstance().getAuthToken();
  final response = await http.post(
    Uri.parse('$_baseUrl/users/$userId/mutes'),
    headers: {...ApiConfig.authHeaders(token), 'Content-Type': 'application/json'},
    body: jsonEncode({'muted_user_id': mutedUserId}),
  );
  return response.statusCode == 200 && jsonDecode(response.body)['success'] == true;
}

Future<bool> unmuteUser({required int userId, required int mutedUserId}) async {
  final token = await LocalStorageService.getInstance().getAuthToken();
  final response = await http.delete(
    Uri.parse('$_baseUrl/users/$userId/mutes/$mutedUserId'),
    headers: ApiConfig.authHeaders(token),
  );
  return response.statusCode == 200 && jsonDecode(response.body)['success'] == true;
}

Future<int> bulkMuteUsers({required int userId, required List<int> ids}) async {
  final token = await LocalStorageService.getInstance().getAuthToken();
  final response = await http.post(
    Uri.parse('$_baseUrl/users/$userId/mutes/bulk'),
    headers: {...ApiConfig.authHeaders(token), 'Content-Type': 'application/json'},
    body: jsonEncode({'ids': ids}),
  );
  if (response.statusCode == 200) {
    final body = jsonDecode(response.body) as Map<String, dynamic>;
    if (body['success'] == true) return (body['data']?['muted'] as num?)?.toInt() ?? 0;
  }
  return 0;
}

Future<int> bulkBlockUsers({required int userId, required List<int> ids}) async {
  final token = await LocalStorageService.getInstance().getAuthToken();
  final response = await http.post(
    Uri.parse('$_baseUrl/users/block-bulk'),
    headers: {...ApiConfig.authHeaders(token), 'Content-Type': 'application/json'},
    body: jsonEncode({'user_id': userId, 'blocked_user_ids': ids}),
  );
  if (response.statusCode == 200) {
    final body = jsonDecode(response.body) as Map<String, dynamic>;
    if (body['success'] == true) return (body['data']?['blocked'] as num?)?.toInt() ?? 0;
  }
  return 0;
}

/// Downloads `followers-YYYY-MM-DD.csv` to a temp file via Dio and
/// returns the file path. Caller hands it to share_plus.
Future<String?> exportFollowersCsv({required int userId}) async {
  final token = await LocalStorageService.getInstance().getAuthToken();
  final dio = Dio();
  final dir = await getTemporaryDirectory();
  final today = DateTime.now().toIso8601String().substring(0, 10);
  final path = '${dir.path}/followers-$today.csv';
  try {
    await dio.download(
      '$_baseUrl/users/$userId/followers/export.csv',
      path,
      options: Options(headers: ApiConfig.authHeaders(token)),
    );
    return path;
  } catch (_) {
    return null;
  }
}

// endregion ────────────────────────────────────────────────────────
```

Add imports at the top of the file if absent: `import 'package:dio/dio.dart';`, `import 'package:path_provider/path_provider.dart';` (verify both exist in `pubspec.yaml`).

- [ ] **Step 2: Verify**

```bash
flutter analyze lib/services/friend_service.dart
```

Expected: no new errors.

---

## Task 10: Frontend — register route + branch profile entry

**Files:**
- Modify: `lib/main.dart` (`onGenerateRoute`)
- Modify: `lib/screens/profile/profile_screen.dart` (line 1118)

- [ ] **Step 1: Register route in `main.dart`**

Inside `onGenerateRoute`, add a case alongside existing user‑id‑gated routes:

```dart
case '/followers/manage':
  return MaterialPageRoute(
    builder: (_) => FutureBuilder<int>(
      future: LocalStorageService.getInstance().getCurrentUserId(),
      builder: (ctx, snap) {
        if (!snap.hasData) {
          return const Scaffold(body: Center(child: CircularProgressIndicator(strokeWidth: 2, color: Color(0xFF1A1A1A))));
        }
        return FollowersManageScreen(currentUserId: snap.data!);
      },
    ),
    settings: settings,
  );
```

Add at the top: `import 'screens/profile/followers/followers_manage_screen.dart';`.

(`getCurrentUserId()` already exists on `LocalStorageService` per other routes; verify with `grep getCurrentUserId lib/services/local_storage_service.dart`.)

- [ ] **Step 2: Branch the entry point**

In `profile_screen.dart` line 1118 (the `Followers` `_StatChip`), replace:

```dart
onTap: () => _openStatsBottomSheet(ProfileStatsType.followers, followersCount),
```

with:

```dart
onTap: () => _isOwnProfile
    ? Navigator.pushNamed(context, '/followers/manage')
    : _openStatsBottomSheet(ProfileStatsType.followers, followersCount),
```

- [ ] **Step 3: Verify**

```bash
flutter analyze lib/main.dart lib/screens/profile/profile_screen.dart
```

Expected: no new errors. (`FollowersManageScreen` doesn't exist yet — Task 14 creates a stub first to keep this task independently verifiable. If you want this task green now, defer Step 1's body to a placeholder route that pops; otherwise complete Task 14's stub before this analyze. Either order is fine — the dependency is one-directional.)

---

## Task 11: Frontend — `FollowersInsightsCard` widget

**Files:**
- Create: `lib/screens/profile/followers/followers_insights_card.dart`

- [ ] **Step 1: Author the widget**

```dart
import 'package:flutter/material.dart';
import '../../../l10n/app_strings_scope.dart';
import '../../../models/friend_models.dart';

enum FollowerFilter { total, newThisWeek, inactive, mutualGap }

/// Dark stat card with 4 tappable filter pills. Active filter has a
/// 1px white outline + bold text; tapping the active pill resets to
/// `total` (no filter).
class FollowersInsightsCard extends StatelessWidget {
  final FollowerInsights? insights; // null while loading
  final FollowerFilter active;
  final ValueChanged<FollowerFilter> onTap;

  const FollowersInsightsCard({
    super.key,
    required this.insights,
    required this.active,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final isSw = AppStringsScope.of(context)?.isSwahili ?? false;
    final loading = insights == null;
    return Container(
      margin: const EdgeInsets.fromLTRB(16, 12, 16, 8),
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
      decoration: BoxDecoration(
        color: const Color(0xFF1A1A1A),
        borderRadius: BorderRadius.circular(16),
      ),
      child: Wrap(
        spacing: 8,
        runSpacing: 8,
        children: [
          _pill(context, FollowerFilter.total,
              label: isSw ? 'Jumla' : 'Total',
              value: loading ? '–' : '${insights!.total}',
              loading: loading),
          _pill(context, FollowerFilter.newThisWeek,
              label: isSw ? 'wiki hii' : 'this week',
              value: loading ? '+–' : '+${insights!.newThisWeek}',
              loading: loading),
          _pill(context, FollowerFilter.inactive,
              label: isSw ? 'hawatumi' : 'inactive',
              value: loading ? '–' : '${insights!.inactive60d}',
              loading: loading),
          _pill(context, FollowerFilter.mutualGap,
              label: isSw ? 'hawajafuatwa nyuma' : 'not followed back',
              value: loading ? '–' : '${insights!.mutualGap}',
              loading: loading),
        ],
      ),
    );
  }

  Widget _pill(BuildContext context, FollowerFilter f,
      {required String label, required String value, required bool loading}) {
    final isActive = active == f;
    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: loading ? null : () => onTap(f),
        borderRadius: BorderRadius.circular(999),
        child: Container(
          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
          decoration: BoxDecoration(
            color: isActive ? Colors.white.withValues(alpha: 0.08) : Colors.transparent,
            borderRadius: BorderRadius.circular(999),
            border: Border.all(
              color: isActive ? Colors.white : Colors.white.withValues(alpha: 0.18),
              width: 1,
            ),
          ),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              Text(value,
                  style: TextStyle(
                    color: Colors.white,
                    fontWeight: isActive ? FontWeight.w700 : FontWeight.w600,
                    fontSize: 13,
                  )),
              const SizedBox(width: 6),
              Text(label,
                  style: TextStyle(
                    color: Colors.white.withValues(alpha: 0.75),
                    fontSize: 11,
                    fontWeight: FontWeight.w500,
                  )),
            ],
          ),
        ),
      ),
    );
  }
}
```

- [ ] **Step 2: Verify**

```bash
flutter analyze lib/screens/profile/followers/
```

Expected: no errors.

---

## Task 12: Frontend — `FollowerRow` widget

**Files:**
- Create: `lib/screens/profile/followers/follower_row.dart`

- [ ] **Step 1: Author the widget**

```dart
import 'package:flutter/material.dart';
import 'package:cached_network_image/cached_network_image.dart';
import '../../../l10n/app_strings_scope.dart';
import '../../../models/friend_models.dart';

/// 64dp follower row. In bulk mode, leading area becomes a Checkbox
/// and the avatar shrinks to 32dp.
class FollowerRow extends StatelessWidget {
  final FollowerProfile follower;   // ← whatever the row model is named in friend_models.dart
  final bool inBulkMode;
  final bool isSelected;
  final VoidCallback onTap;
  final VoidCallback? onLongPress;
  final ValueChanged<bool?>? onCheckboxChanged;

  const FollowerRow({
    super.key,
    required this.follower,
    required this.inBulkMode,
    required this.isSelected,
    required this.onTap,
    this.onLongPress,
    this.onCheckboxChanged,
  });

  @override
  Widget build(BuildContext context) {
    final isSw = AppStringsScope.of(context)?.isSwahili ?? false;
    final avatarRadius = inBulkMode ? 16.0 : 20.0;

    return Material(
      color: Colors.white,
      child: InkWell(
        onTap: onTap,
        onLongPress: inBulkMode ? null : onLongPress,
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
          child: Row(
            children: [
              if (inBulkMode) ...[
                Checkbox(
                  value: isSelected,
                  onChanged: onCheckboxChanged,
                  activeColor: const Color(0xFF1A1A1A),
                ),
                const SizedBox(width: 4),
              ],
              CircleAvatar(
                radius: avatarRadius,
                backgroundColor: const Color(0xFFF0F0F0),
                backgroundImage: (follower.profilePhotoUrl ?? '').isNotEmpty
                    ? CachedNetworkImageProvider(follower.profilePhotoUrl!)
                    : null,
                child: (follower.profilePhotoUrl ?? '').isEmpty
                    ? Text(
                        _initial(follower),
                        style: TextStyle(
                          fontSize: avatarRadius * 0.7,
                          fontWeight: FontWeight.w600,
                          color: const Color(0xFF1A1A1A),
                        ),
                      )
                    : null,
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      _displayName(follower),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: const TextStyle(
                        fontWeight: FontWeight.w600,
                        fontSize: 14,
                        color: Color(0xFF1A1A1A),
                      ),
                    ),
                    const SizedBox(height: 2),
                    Text(
                      _subtitle(follower, isSw),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: const TextStyle(
                        fontSize: 12,
                        color: Color(0xFF999999),
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(width: 8),
              if (_badge(follower, isSw) != null) _badge(follower, isSw)!,
            ],
          ),
        ),
      ),
    );
  }

  String _displayName(FollowerProfile f) {
    final n = '${f.firstName} ${f.lastName}'.trim();
    return n.isEmpty ? (f.username ?? '') : n;
  }

  String _initial(FollowerProfile f) {
    final n = _displayName(f);
    return n.isNotEmpty ? n[0].toUpperCase() : '?';
  }

  String _subtitle(FollowerProfile f, bool isSw) {
    final handle = (f.username ?? '').isNotEmpty ? '@${f.username}' : '';
    final last = f.lastInteractionAt;
    if (last == null) return handle;
    final diff = DateTime.now().difference(last);
    String ago;
    if (diff.inMinutes < 60) {
      ago = isSw ? 'sasa hivi' : 'just now';
    } else if (diff.inHours < 24) {
      ago = isSw ? 'saa ${diff.inHours} zilizopita' : '${diff.inHours}h ago';
    } else if (diff.inDays < 30) {
      ago = isSw ? 'siku ${diff.inDays} zilizopita' : '${diff.inDays}d ago';
    } else {
      final mo = (diff.inDays / 30).floor();
      ago = isSw ? 'miezi $mo iliyopita' : '${mo}mo ago';
    }
    return handle.isEmpty ? ago : '$handle · $ago';
  }

  Widget? _badge(FollowerProfile f, bool isSw) {
    // Priority: Muted > New > Mutual.
    if (f.isMuted) return _badgeBox(isSw ? 'Imenyamazishwa' : 'Muted', const Color(0xFF666666));
    final isNew = f.followedAt != null && DateTime.now().difference(f.followedAt!).inDays < 7;
    if (isNew) return _badgeBox(isSw ? 'Mpya' : 'New', const Color(0xFF1A1A1A));
    if (f.isMutual) return _badgeBox(isSw ? 'Pande zote' : 'Mutual', const Color(0xFF1A1A1A));
    return null;
  }

  Widget _badgeBox(String label, Color color) => Container(
        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
        decoration: BoxDecoration(
          color: color.withValues(alpha: 0.10),
          borderRadius: BorderRadius.circular(8),
        ),
        child: Text(
          label,
          style: TextStyle(fontSize: 10, fontWeight: FontWeight.w600, color: color),
        ),
      );
}
```

Adjust `FollowerProfile`, `firstName`, `lastName`, `profilePhotoUrl`, `followedAt` field names to match the actual model in `friend_models.dart` from Task 8.

- [ ] **Step 2: Verify**

```bash
flutter analyze lib/screens/profile/followers/follower_row.dart
```

Expected: no errors.

---

## Task 13: Frontend — `FollowerActionsSheet`

**Files:**
- Create: `lib/screens/profile/followers/follower_actions_sheet.dart`

- [ ] **Step 1: Author the sheet**

```dart
import 'package:flutter/material.dart';
import '../../../l10n/app_strings_scope.dart';

enum FollowerAction { view, mute, unmute, remove, block }

class FollowerActionsSheet {
  static Future<FollowerAction?> show(
    BuildContext context, {
    required bool isMuted,
  }) {
    final isSw = AppStringsScope.of(context)?.isSwahili ?? false;
    return showModalBottomSheet<FollowerAction>(
      context: context,
      backgroundColor: Colors.white,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(16)),
      ),
      builder: (sheetCtx) => SafeArea(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const SizedBox(height: 8),
            Container(
              width: 40, height: 4,
              decoration: BoxDecoration(
                color: const Color(0xFFE5E5E5),
                borderRadius: BorderRadius.circular(999),
              ),
            ),
            const SizedBox(height: 8),
            ListTile(
              leading: const Icon(Icons.person_outline_rounded, color: Color(0xFF1A1A1A)),
              title: Text(isSw ? 'Tazama wasifu' : 'View profile'),
              onTap: () => Navigator.of(sheetCtx).pop(FollowerAction.view),
            ),
            ListTile(
              leading: Icon(
                isMuted ? Icons.volume_up_rounded : Icons.volume_off_rounded,
                color: const Color(0xFF1A1A1A),
              ),
              title: Text(
                isMuted ? (isSw ? 'Achilia' : 'Unmute')
                        : (isSw ? 'Nyamazisha' : 'Mute'),
              ),
              onTap: () => Navigator.of(sheetCtx).pop(
                isMuted ? FollowerAction.unmute : FollowerAction.mute,
              ),
            ),
            ListTile(
              leading: const Icon(Icons.person_remove_outlined, color: Color(0xFFD32F2F)),
              title: Text(isSw ? 'Ondoa mfuasi' : 'Remove follower',
                  style: const TextStyle(color: Color(0xFFD32F2F))),
              onTap: () => Navigator.of(sheetCtx).pop(FollowerAction.remove),
            ),
            ListTile(
              leading: const Icon(Icons.block_rounded, color: Color(0xFFD32F2F)),
              title: Text(isSw ? 'Zuia' : 'Block',
                  style: const TextStyle(color: Color(0xFFD32F2F))),
              onTap: () => Navigator.of(sheetCtx).pop(FollowerAction.block),
            ),
            const SizedBox(height: 8),
          ],
        ),
      ),
    );
  }
}
```

- [ ] **Step 2: Verify**

```bash
flutter analyze lib/screens/profile/followers/follower_actions_sheet.dart
```

Expected: no errors.

---

## Task 14: Frontend — `FollowersManageScreen` shell (insights + search + list, no actions)

**Files:**
- Create: `lib/screens/profile/followers/followers_manage_screen.dart`

- [ ] **Step 1: Author the screen shell**

```dart
import 'dart:async';
import 'package:flutter/material.dart';
import '../../../l10n/app_strings_scope.dart';
import '../../../models/friend_models.dart';
import '../../../services/friend_service.dart';
import 'followers_insights_card.dart';
import 'follower_row.dart';

class FollowersManageScreen extends StatefulWidget {
  final int currentUserId;
  const FollowersManageScreen({super.key, required this.currentUserId});

  @override
  State<FollowersManageScreen> createState() => _FollowersManageScreenState();
}

class _FollowersManageScreenState extends State<FollowersManageScreen> {
  final FriendService _service = FriendService();
  final TextEditingController _searchCtrl = TextEditingController();
  final ScrollController _scroll = ScrollController();
  Timer? _debounce;

  FollowerInsights? _insights;
  FollowerFilter _filter = FollowerFilter.total;
  String _sort = 'newest';
  String _query = '';

  final List<FollowerProfile> _rows = [];
  int _page = 1;
  bool _loading = true;
  bool _appending = false;
  bool _hasMore = true;
  String? _error;

  bool _bulkMode = false;
  final Set<int> _selected = {};
  String? _bulkHint; // shown when 51st row tapped
  Timer? _bulkHintTimer;

  @override
  void initState() {
    super.initState();
    _scroll.addListener(_onScroll);
    _refreshAll();
  }

  @override
  void dispose() {
    _scroll.dispose();
    _searchCtrl.dispose();
    _debounce?.cancel();
    _bulkHintTimer?.cancel();
    super.dispose();
  }

  Future<void> _refreshAll() async {
    setState(() {
      _loading = _rows.isEmpty;
      _error = null;
      _page = 1;
      _hasMore = true;
    });
    final futures = await Future.wait([
      _service.getFollowerInsights(userId: widget.currentUserId),
      _service.getOwnerFollowers(
        userId: widget.currentUserId,
        page: 1, perPage: 30,
        q: _query.isEmpty ? null : _query,
        filter: _filterToParam(_filter),
        sort: _sort,
      ),
    ]);
    if (!mounted) return;
    final insights = futures[0] as FollowerInsights?;
    final list = futures[1] as FollowListResult;
    setState(() {
      _insights = insights;
      _rows
        ..clear()
        ..addAll(list.followers ?? []);
      _hasMore = (list.followers ?? []).length == 30;
      _loading = false;
      _error = list.success ? null : (list.message ?? 'Failed to load');
    });
  }

  void _onScroll() {
    if (_appending || !_hasMore) return;
    if (_scroll.position.pixels < _scroll.position.maxScrollExtent * 0.8) return;
    _appendNextPage();
  }

  Future<void> _appendNextPage() async {
    setState(() => _appending = true);
    final next = _page + 1;
    final list = await _service.getOwnerFollowers(
      userId: widget.currentUserId,
      page: next, perPage: 30,
      q: _query.isEmpty ? null : _query,
      filter: _filterToParam(_filter),
      sort: _sort,
    );
    if (!mounted) return;
    setState(() {
      _appending = false;
      if (list.success) {
        _page = next;
        final batch = list.followers ?? [];
        _rows.addAll(batch);
        _hasMore = batch.length == 30;
      }
    });
  }

  String? _filterToParam(FollowerFilter f) => switch (f) {
        FollowerFilter.total => null,
        FollowerFilter.newThisWeek => 'new',
        FollowerFilter.inactive => 'inactive',
        FollowerFilter.mutualGap => 'mutual_gap',
      };

  void _onSearchChanged(String text) {
    _debounce?.cancel();
    _debounce = Timer(const Duration(milliseconds: 300), () {
      _query = text.trim();
      _refreshAll();
    });
  }

  void _onFilterTap(FollowerFilter f) {
    setState(() => _filter = (f == _filter) ? FollowerFilter.total : f);
    _refreshAll();
  }

  @override
  Widget build(BuildContext context) {
    final isSw = AppStringsScope.of(context)?.isSwahili ?? false;
    final total = _insights?.total ?? 0;
    return Scaffold(
      backgroundColor: const Color(0xFFFAFAFA),
      appBar: AppBar(
        elevation: 0,
        scrolledUnderElevation: 1,
        backgroundColor: Colors.white,
        foregroundColor: const Color(0xFF1A1A1A),
        leading: _bulkMode
            ? IconButton(
                icon: const Icon(Icons.close_rounded),
                onPressed: () => setState(() {
                  _bulkMode = false;
                  _selected.clear();
                }),
              )
            : null,
        title: _bulkMode
            ? Text(
                isSw ? '${_selected.length} wamechaguliwa' : '${_selected.length} selected',
                style: const TextStyle(fontSize: 16, fontWeight: FontWeight.w600),
              )
            : Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                mainAxisSize: MainAxisSize.min,
                children: [
                  Text(isSw ? 'Wafuasi' : 'Followers',
                      style: const TextStyle(fontSize: 16, fontWeight: FontWeight.w600)),
                  Text(isSw ? 'jumla $total' : '$total total',
                      style: const TextStyle(fontSize: 12, color: Color(0xFF666666))),
                ],
              ),
        actions: _bulkMode ? const [] : [_overflowMenu(isSw)],
      ),
      body: RefreshIndicator(
        color: const Color(0xFF1A1A1A),
        onRefresh: _bulkMode ? () async {} : _refreshAll,
        child: ListView(
          controller: _scroll,
          children: [
            FollowersInsightsCard(
              insights: _insights,
              active: _filter,
              onTap: _onFilterTap,
            ),
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
              child: TextField(
                controller: _searchCtrl,
                onChanged: _onSearchChanged,
                decoration: InputDecoration(
                  hintText: isSw ? 'Tafuta kwa jina au @handle' : 'Search by name or @handle',
                  prefixIcon: const Icon(Icons.search_rounded, color: Color(0xFF999999)),
                  suffixIcon: _searchCtrl.text.isEmpty
                      ? null
                      : IconButton(
                          icon: const Icon(Icons.close_rounded, color: Color(0xFF999999)),
                          onPressed: () { _searchCtrl.clear(); _onSearchChanged(''); },
                        ),
                  filled: true,
                  fillColor: Colors.white,
                  border: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: BorderSide.none),
                ),
              ),
            ),
            if (_loading)
              const Padding(
                padding: EdgeInsets.symmetric(vertical: 64),
                child: Center(child: CircularProgressIndicator(strokeWidth: 2, color: Color(0xFF1A1A1A))),
              )
            else if (_error != null)
              _errorBlock(isSw)
            else if (_rows.isEmpty)
              _emptyBlock(isSw)
            else
              ..._rows.map(_rowFor),
            if (_appending) const Padding(
              padding: EdgeInsets.all(16),
              child: Center(child: CircularProgressIndicator(strokeWidth: 2, color: Color(0xFF1A1A1A))),
            ),
          ],
        ),
      ),
      // bulk action bar appears in Task 16
    );
  }

  Widget _overflowMenu(bool isSw) => PopupMenuButton<String>(
        icon: const Icon(Icons.more_horiz_rounded),
        onSelected: (v) {
          // Hooks wired in Tasks 15–17.
        },
        itemBuilder: (_) => [
          PopupMenuItem(value: 'sort_newest', child: Text(isSw ? 'Mpya' : 'Newest')),
          PopupMenuItem(value: 'sort_oldest', child: Text(isSw ? 'Wa zamani' : 'Oldest')),
          PopupMenuItem(value: 'sort_name',   child: const Text('A–Z')),
          const PopupMenuDivider(),
          PopupMenuItem(value: 'select',      child: Text(isSw ? 'Chagua' : 'Select')),
          PopupMenuItem(value: 'export',      child: Text(isSw ? 'Hamisha CSV' : 'Export CSV')),
        ],
      );

  Widget _rowFor(FollowerProfile f) => FollowerRow(
        follower: f,
        inBulkMode: _bulkMode,
        isSelected: _selected.contains(f.id),
        onTap: () {
          if (_bulkMode) {
            _toggleSelect(f.id);
          } else {
            Navigator.of(context).pushNamed('/profile/${f.id}');
          }
        },
        onLongPress: null,        // Task 15 wires this.
        onCheckboxChanged: (v) => _toggleSelect(f.id, force: v),
      );

  void _toggleSelect(int id, {bool? force}) {
    setState(() {
      final shouldAdd = force ?? !_selected.contains(id);
      if (shouldAdd) {
        if (_selected.length >= 50) {
          _bulkHint = AppStringsScope.of(context)?.isSwahili == true
              ? 'Hadi 50 kwa wakati mmoja' : 'Up to 50 at a time';
          _bulkHintTimer?.cancel();
          _bulkHintTimer = Timer(const Duration(seconds: 2), () => mounted ? setState(() => _bulkHint = null) : null);
          return;
        }
        _selected.add(id);
      } else {
        _selected.remove(id);
      }
    });
  }

  Widget _emptyBlock(bool isSw) => Padding(
        padding: const EdgeInsets.symmetric(vertical: 64, horizontal: 24),
        child: Column(
          children: [
            Icon(Icons.group_outlined, size: 64, color: Colors.grey.shade300),
            const SizedBox(height: 12),
            Text(
              _query.isNotEmpty || _filter != FollowerFilter.total
                  ? (isSw ? 'Hakuna wafuasi' : 'No followers')
                  : (isSw ? 'Hujapata wafuasi bado' : 'No followers yet'),
              style: TextStyle(fontSize: 16, color: Colors.grey.shade500),
            ),
            const SizedBox(height: 4),
            Text(
              _query.isEmpty && _filter == FollowerFilter.total
                  ? (isSw ? 'Shiriki wasifu wako kuanza' : 'Share your profile to get started')
                  : '',
              style: TextStyle(fontSize: 13, color: Colors.grey.shade400),
            ),
          ],
        ),
      );

  Widget _errorBlock(bool isSw) => Padding(
        padding: const EdgeInsets.symmetric(vertical: 64, horizontal: 24),
        child: Column(
          children: [
            Icon(Icons.error_outline, size: 64, color: Colors.grey.shade300),
            const SizedBox(height: 12),
            Text(_error ?? '', style: TextStyle(fontSize: 14, color: Colors.grey.shade600)),
            const SizedBox(height: 12),
            OutlinedButton(onPressed: _refreshAll, child: Text(isSw ? 'Jaribu tena' : 'Retry')),
          ],
        ),
      );
}
```

(`FollowListResult.followers` is the existing list field on the result model — adjust if it has a different name.)

- [ ] **Step 2: Verify**

```bash
flutter analyze lib/screens/profile/followers/
```

Expected: no errors. The `_overflowMenu` `onSelected` body is intentionally empty here — Task 15 wires sort, Task 16 wires Select, Task 17 wires Export.

- [ ] **Step 3: Manual sanity check**

Run the app, sign in, open your profile, tap the **Followers** chip. Page renders; insights pills load; search debounces; tapping a pill refreshes the list; pull‑to‑refresh works; row tap pushes `/profile/{id}`; overflow menu opens (no actions yet).

---

## Task 15: Frontend — wire single‑row long‑press actions + sort menu

**Files:**
- Modify: `lib/screens/profile/followers/followers_manage_screen.dart`

- [ ] **Step 1: Wire long‑press → action sheet**

In `_rowFor`, replace `onLongPress: null` with:

```dart
onLongPress: () => _onLongPressRow(f),
```

Add the handler on the state class:

```dart
Future<void> _onLongPressRow(FollowerProfile f) async {
  final action = await FollowerActionsSheet.show(context, isMuted: f.isMuted);
  if (action == null || !mounted) return;
  switch (action) {
    case FollowerAction.view:
      Navigator.of(context).pushNamed('/profile/${f.id}');
      break;
    case FollowerAction.mute:
      await _service.muteUser(userId: widget.currentUserId, mutedUserId: f.id);
      if (mounted) _refreshAll();
      break;
    case FollowerAction.unmute:
      await _service.unmuteUser(userId: widget.currentUserId, mutedUserId: f.id);
      if (mounted) _refreshAll();
      break;
    case FollowerAction.remove:
      await _confirmAndRemove(f);
      break;
    case FollowerAction.block:
      await _confirmAndBlock(f);
      break;
  }
}

Future<void> _confirmAndRemove(FollowerProfile f) async {
  final isSw = AppStringsScope.of(context)?.isSwahili ?? false;
  final ok = await _confirmDanger(
    title: isSw ? 'Ondoa mfuasi' : 'Remove follower',
    body: isSw
        ? "Ondoa @${f.username}? Hawatajulishwa, lakini wanaweza kukufuata tena."
        : "Remove @${f.username}? They won't be notified, but they can follow you again.",
    confirmLabel: isSw ? 'Ondoa' : 'Remove',
  );
  if (!ok) return;
  await _service.removeFollower(userId: widget.currentUserId, followerId: f.id);
  if (mounted) _refreshAll();
}

Future<void> _confirmAndBlock(FollowerProfile f) async {
  final isSw = AppStringsScope.of(context)?.isSwahili ?? false;
  final ok = await _confirmDanger(
    title: isSw ? 'Zuia' : 'Block',
    body: isSw
        ? "Zuia @${f.username}? Hawataweza kupata wasifu au maudhui yako. Wewe pia hutaona yao."
        : "Block @${f.username}? They won't be able to find your profile or content. You won't see theirs.",
    confirmLabel: isSw ? 'Zuia' : 'Block',
  );
  if (!ok) return;
  await _service.blockUser(widget.currentUserId, f.id);
  if (mounted) _refreshAll();
}

Future<bool> _confirmDanger({
  required String title,
  required String body,
  required String confirmLabel,
}) async {
  final result = await showDialog<bool>(
    context: context,
    builder: (ctx) => AlertDialog(
      title: Text(title),
      content: Text(body),
      actions: [
        TextButton(
          onPressed: () => Navigator.of(ctx).pop(false),
          child: Text(AppStringsScope.of(ctx)?.cancel ?? 'Cancel'),
        ),
        TextButton(
          onPressed: () => Navigator.of(ctx).pop(true),
          style: TextButton.styleFrom(foregroundColor: const Color(0xFFD32F2F)),
          child: Text(confirmLabel),
        ),
      ],
    ),
  );
  return result == true;
}
```

Add `import 'follower_actions_sheet.dart';` at the top.

- [ ] **Step 2: Wire sort + Select in `_overflowMenu` `onSelected`**

```dart
onSelected: (v) {
  switch (v) {
    case 'sort_newest': setState(() => _sort = 'newest'); _refreshAll(); break;
    case 'sort_oldest': setState(() => _sort = 'oldest'); _refreshAll(); break;
    case 'sort_name':   setState(() => _sort = 'name');   _refreshAll(); break;
    case 'select':      setState(() => _bulkMode = true); break;
    case 'export':      _onExport(); break;
  }
},
```

Add a stub `Future<void> _onExport() async { /* Task 17 */ }`.

- [ ] **Step 3: Verify**

```bash
flutter analyze lib/screens/profile/followers/
```

Expected: no errors. Manual: long‑press a row, run each action, confirm dialogs render with red destructive button, mute toggles inline badge after refresh.

---

## Task 16: Frontend — bulk mode + bottom action bar + bulk endpoints

**Files:**
- Modify: `lib/screens/profile/followers/followers_manage_screen.dart`

- [ ] **Step 1: Add the bottom action bar to `Scaffold.bottomNavigationBar`**

Add to the `Scaffold(...)` constructor (near the bottom):

```dart
bottomNavigationBar: !_bulkMode
    ? null
    : _BulkActionBar(
        count: _selected.length,
        hint: _bulkHint,
        onRemove: _selected.isEmpty ? null : _bulkConfirmRemove,
        onMute:   _selected.isEmpty ? null : _bulkConfirmMute,
        onBlock:  _selected.isEmpty ? null : _bulkConfirmBlock,
      ),
```

- [ ] **Step 2: Add the bulk action handlers**

```dart
Future<void> _bulkConfirmRemove() async {
  final isSw = AppStringsScope.of(context)?.isSwahili ?? false;
  final n = _selected.length;
  final ok = await _confirmDanger(
    title: isSw ? 'Ondoa wafuasi' : 'Remove followers',
    body: isSw ? 'Ondoa wafuasi $n? Hawatajulishwa.' : "Remove $n followers? They won't be notified.",
    confirmLabel: isSw ? 'Ondoa' : 'Remove',
  );
  if (!ok) return;
  final removed = await _service.bulkRemoveFollowers(userId: widget.currentUserId, ids: _selected.toList());
  if (!mounted) return;
  setState(() { _bulkMode = false; _selected.clear(); });
  await _refreshAll();
  debugPrint('bulk removed=$removed');
}

Future<void> _bulkConfirmMute() async {
  final isSw = AppStringsScope.of(context)?.isSwahili ?? false;
  final n = _selected.length;
  final ok = await _confirmDanger(
    title: isSw ? 'Nyamazisha' : 'Mute',
    body: isSw ? 'Nyamazisha wafuasi $n?' : 'Mute $n followers?',
    confirmLabel: isSw ? 'Nyamazisha' : 'Mute',
  );
  if (!ok) return;
  await _service.bulkMuteUsers(userId: widget.currentUserId, ids: _selected.toList());
  if (!mounted) return;
  setState(() { _bulkMode = false; _selected.clear(); });
  await _refreshAll();
}

Future<void> _bulkConfirmBlock() async {
  final isSw = AppStringsScope.of(context)?.isSwahili ?? false;
  final n = _selected.length;
  final ok = await _confirmDanger(
    title: isSw ? 'Zuia' : 'Block',
    body: isSw ? 'Zuia wafuasi $n? Hawataweza kupata wasifu wako.' : "Block $n followers? They won't be able to find your profile.",
    confirmLabel: isSw ? 'Zuia' : 'Block',
  );
  if (!ok) return;
  await _service.bulkBlockUsers(userId: widget.currentUserId, ids: _selected.toList());
  if (!mounted) return;
  setState(() { _bulkMode = false; _selected.clear(); });
  await _refreshAll();
}
```

- [ ] **Step 3: Add the `_BulkActionBar` widget at the bottom of the same file**

```dart
class _BulkActionBar extends StatelessWidget {
  final int count;
  final String? hint;
  final VoidCallback? onRemove;
  final VoidCallback? onMute;
  final VoidCallback? onBlock;
  const _BulkActionBar({
    required this.count,
    required this.hint,
    required this.onRemove,
    required this.onMute,
    required this.onBlock,
  });

  @override
  Widget build(BuildContext context) {
    final isSw = AppStringsScope.of(context)?.isSwahili ?? false;
    return Container(
      decoration: const BoxDecoration(
        color: Colors.white,
        border: Border(top: BorderSide(color: Color(0xFFE5E5E5))),
      ),
      child: SafeArea(
        top: false,
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            if (hint != null)
              Padding(
                padding: const EdgeInsets.only(top: 8),
                child: Text(hint!, style: const TextStyle(fontSize: 12, color: Color(0xFFD32F2F))),
              ),
            SizedBox(
              height: 64,
              child: Row(
                children: [
                  Expanded(child: TextButton(
                    onPressed: onRemove,
                    style: TextButton.styleFrom(foregroundColor: const Color(0xFFD32F2F)),
                    child: Text(isSw ? 'Ondoa' : 'Remove'),
                  )),
                  Expanded(child: TextButton(
                    onPressed: onMute,
                    style: TextButton.styleFrom(foregroundColor: const Color(0xFF1A1A1A)),
                    child: Text(isSw ? 'Nyamazisha' : 'Mute'),
                  )),
                  Expanded(child: TextButton(
                    onPressed: onBlock,
                    style: TextButton.styleFrom(foregroundColor: const Color(0xFFD32F2F)),
                    child: Text(isSw ? 'Zuia' : 'Block'),
                  )),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}
```

- [ ] **Step 4: Verify**

```bash
flutter analyze lib/screens/profile/followers/
```

Expected: no errors. Manual: tap overflow → Select → tap rows (avatar shrinks, checkbox appears) → bottom bar shows; try selecting 51 → cap hint flashes; tap each bulk action → confirm dialog → list refreshes after.

---

## Task 17: Frontend — CSV export + share

**Files:**
- Modify: `lib/screens/profile/followers/followers_manage_screen.dart`

- [ ] **Step 1: Implement `_onExport`**

Replace the stub:

```dart
Future<void> _onExport() async {
  final isSw = AppStringsScope.of(context)?.isSwahili ?? false;
  final path = await _service.exportFollowersCsv(userId: widget.currentUserId);
  if (!mounted) return;
  if (path == null) {
    showDialog<void>(
      context: context,
      builder: (ctx) => AlertDialog(
        content: Text(isSw ? 'Imeshindikana' : 'Export failed'),
        actions: [
          TextButton(onPressed: () => Navigator.of(ctx).pop(),
            child: Text(AppStringsScope.of(ctx)?.ok ?? 'OK')),
        ],
      ),
    );
    return;
  }
  await Share.shareXFiles([XFile(path)], text: isSw ? 'Wafuasi' : 'Followers');
}
```

Add at the top of the file:

```dart
import 'package:share_plus/share_plus.dart';
```

- [ ] **Step 2: Verify**

```bash
flutter analyze lib/screens/profile/followers/
```

Expected: no errors. Manual: tap overflow → Export CSV → wait → system share sheet opens with `followers-YYYY-MM-DD.csv` ready to save/email.

---

## Task 18: Final polish + audit

**Files:**
- Modify: `lib/screens/profile/followers/followers_manage_screen.dart` and the three sibling widgets as needed.

- [ ] **Step 1: Replace nested `ListView` with `ListView.builder` for performance**

In Task 14's Step 1 we used a single `ListView` containing the insights card, search field, and rows as children. For 50+ rows this defeats recycling. Refactor to a `CustomScrollView` with `SliverToBoxAdapter` for the header bits and a `SliverList.builder` for the rows.

```dart
body: RefreshIndicator(
  color: const Color(0xFF1A1A1A),
  onRefresh: _bulkMode ? () async {} : _refreshAll,
  child: CustomScrollView(
    controller: _scroll,
    slivers: [
      SliverToBoxAdapter(child: FollowersInsightsCard(insights: _insights, active: _filter, onTap: _onFilterTap)),
      SliverToBoxAdapter(child: _searchField(isSw)),
      if (_loading) SliverFillRemaining(child: _loadingBlock())
      else if (_error != null) SliverToBoxAdapter(child: _errorBlock(isSw))
      else if (_rows.isEmpty) SliverToBoxAdapter(child: _emptyBlock(isSw))
      else SliverList.builder(
        itemCount: _rows.length + (_appending ? 1 : 0),
        itemBuilder: (ctx, i) {
          if (i >= _rows.length) {
            return const Padding(padding: EdgeInsets.all(16),
              child: Center(child: CircularProgressIndicator(strokeWidth: 2, color: Color(0xFF1A1A1A))));
          }
          return _rowFor(_rows[i]);
        },
      ),
    ],
  ),
),
```

Extract the search field into a `_searchField(bool isSw)` helper. Add `_loadingBlock()` returning the centered spinner.

- [ ] **Step 2: Run the playbook compliance checklist (spec §12)**

For each unchecked item in spec §12, audit the screen and widgets. Fix in place.

- [ ] **Step 3: Final analyze**

```bash
flutter analyze lib/screens/profile/ lib/services/friend_service.dart lib/models/friend_models.dart lib/main.dart
```

Expected: no NEW errors compared to baseline. Pre‑existing `withOpacity` deprecation warnings are out of scope.

- [ ] **Step 4: End‑to‑end smoke**

Sign in with three test accounts. With Account A (the owner): open profile → tap Followers chip → page opens; tap each filter pill, search "@a", sort by name, mute a follower, remove another, bulk‑select 5 and block them; export CSV and verify the file in the share sheet.

With Account B (a visitor on A's profile): tap Followers chip → bottom sheet opens (unchanged behavior).

With Account C (signed in but trying URL `/users/A_ID/followers?filter=new` directly): receives 403.

---

## Self-review against the spec

- §1 Goal — full‑page manager for owners only: covered (Tasks 10, 14).
- §2 Design principles — owner‑only, server‑side filters, no SnackBar, idempotent endpoints: covered.
- §3.1 entry branch on `_isOwnProfile`: Task 10 Step 2.
- §3.2 route registration without userId in path: Task 10 Step 1.
- §4 page anatomy (AppBar + insights card + search + list + bulk bar + empty/error/loading): Tasks 11, 12, 13, 14, 16, 18.
- §4.6 confirm dialog copy: Task 15 Steps 1, Task 16 Step 2.
- §5 row data contract: Task 8.
- §6.1–6.5 endpoints + table + auth: Tasks 1–7.
- §6.6 perf notes: implemented as live subquery in Task 2; documented limit (10k) in spec for v2 denormalization.
- §7 file layout: Tasks 11–14.
- §8 state machine: Task 14 (`_filter`, `_sort`, `_query`, `_selected`, `_bulkMode`).
- §9 bilingual: inline ternaries throughout Tasks 11–17.
- §10 edge cases — debounced search cancels in‑flight (`Timer` reset in Task 14 Step 1), 50‑cap (Task 14 `_toggleSelect`), already‑muted/blocked idempotent (Tasks 4 / 5 / 6).
- §11 perf — `itemExtent` not strictly used; `SliverList.builder` retained. CachedNetworkImage with implicit caching in Task 12.
- §12 compliance — Task 18 Step 2.

---

**Plan complete and saved to `docs/superpowers/plans/2026-05-02-followers-manager.md`. Two execution options:**

**1. Subagent‑Driven (recommended)** — I dispatch a fresh subagent per task, review between tasks, fast iteration.

**2. Inline Execution** — Execute tasks in this session, batch with checkpoints for review.

Which approach?
