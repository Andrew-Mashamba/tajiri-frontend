# People Ranking V2 — Smarter Discovery + Performance

> **For agentic workers:** REQUIRED SUB-SKILL: Use superpowers:subagent-driven-development (recommended) or superpowers:executing-plans to implement this plan task-by-task. Steps use checkbox (`- [ ]`) syntax for tracking.

**Goal:** Upgrade the people discovery algorithm from 7-signal/130-point scoring to 11-signal/200-point scoring with age-proximity, gender-preference, interests-matching, and engagement-history signals. Add Redis caching, database indexes, and frontend intelligence to make discovery feel instant and personally relevant.

**Current State:** Discovery uses a composite ORDER BY with 7 CASE expressions + day-seeded randomness. No caching (every request hits PostgreSQL). No age/gender/interests in scoring. Correlated subqueries run per-row.

**Target State:** A 20-year-old single male sees mostly women his age in his area who share his interests — but also active users, friends-of-friends, and verified profiles. Results load in <200ms with Redis caching. Frontend tracks which profiles were viewed/skipped to feed back into ranking.

**Server:** `root@172.240.241.180` (password `ZimaBlueApps`), Laravel at `/var/www/tajiri.zimasystems.com`

**SSH pattern:** `sshpass -p 'ZimaBlueApps' ssh -o StrictHostKeyChecking=no root@172.240.241.180 '<command>'`

---

## Scoring Model: Before vs After

### Current (V1) — 130 points max + 0-14 random

| Signal | Points | Method |
|--------|--------|--------|
| Friends-of-friends | 30 | Correlated subquery on `friendships` |
| Same district | 20 | Exact match on `district_name` |
| Same region | 10 | Exact match on `region_name` |
| Same university | 15 | Case-insensitive match on `university_name` |
| Same secondary school | 15 | Case-insensitive match on `secondary_school_name` |
| Same employer | 15 | Case-insensitive match on `employer_name` |
| Recently active (7 days) | 10 | EXISTS on `user_presence` |
| Has profile photo | 5 | NOT NULL check |
| Is verified | 5 | Boolean check |
| Has bio | 5 | NOT NULL check |
| Day-seeded random | 0-14 | `hashtext(id || date) % 15` |

### Proposed (V2) — 200 points max + 0-14 random

| Signal | Points | Method | Rationale |
|--------|--------|--------|-----------|
| Friends-of-friends | 30 | **Pre-computed set** (Redis) | Keep — strongest social signal |
| Same district | 20 | Exact match | Keep — geography matters in TZ |
| Same region | 10 | Exact match | Keep — fallback geo signal |
| **Age proximity** | **0-20** | `20 - MIN(20, ABS(my_age - their_age))` | **NEW** — same-age preference |
| **Gender preference** | **0-20** | Relationship-status-aware boost | **NEW** — single users see preferred gender higher |
| **Shared interests** | **0-15** | Count overlap × 3, cap 15 | **NEW** — topic affinity |
| Same university | 15 | Case-insensitive match | Keep |
| Same secondary school | 15 | Case-insensitive match | Keep |
| Same employer | 15 | Case-insensitive match | Keep |
| Recently active (7 days) | 10 | EXISTS on `user_presence` | Keep |
| **Engagement score** | **0-10** | `posts_count + photos_count` brackets | **NEW** — reward active creators |
| **Profile completeness** | **0-10** | Count of filled fields | **NEW** — replaces has_photo + has_bio + verified |
| Has profile photo | ~~5~~ | Folded into profile completeness | Merged |
| Is verified | ~~5~~ | Folded into profile completeness | Merged |
| Has bio | ~~5~~ | Folded into profile completeness | Merged |
| Day-seeded random | 0-14 | `hashtext(id || date) % 15` | Keep |

---

## Phase 1: Backend — New Scoring Signals

**Goal:** Add 4 new scoring signals to `applyDiscoverySort()` in `PeopleController.php`

### Task 1.1: Age Proximity Signal (20 points max)

**File:** `app/Http/Controllers/Api/PeopleController.php` — `applyDiscoverySort()` method

- [ ] Resolve the logged-in user's age from `date_of_birth` (use Carbon `->age`)
- [ ] Add SQL CASE expression:
  ```sql
  + CASE
      WHEN date_of_birth IS NOT NULL THEN
        GREATEST(0, 20 - ABS(EXTRACT(YEAR FROM AGE(date_of_birth)) - :myAge))
      ELSE 0
    END
  ```
- [ ] Users without DOB get 0 points (not penalized beyond missing the boost)
- [ ] If logged-in user has no DOB, skip this signal entirely (add 0)

**Logic:** A 20-year-old gets 20 pts for another 20-year-old, 15 pts for a 25-year-old, 0 pts for anyone 20+ years apart.

### Task 1.2: Gender Preference Signal (20 points max)

**File:** `app/Http/Controllers/Api/PeopleController.php` — `applyDiscoverySort()` method

- [ ] Resolve logged-in user's `gender` and `relationship_status`
- [ ] Apply gender boost ONLY when user is single-ish (`single`, `divorced`, `widowed`, `complicated`) AND has a gender set
- [ ] Boost the opposite gender:
  ```sql
  + CASE
      WHEN :isSingleish = true AND :myGender = 'male' AND gender = 'female' THEN 20
      WHEN :isSingleish = true AND :myGender = 'female' AND gender = 'male' THEN 20
      ELSE 0
    END
  ```
- [ ] If user is `in_relationship`, `engaged`, or `married` — no gender boost (0 for all)
- [ ] If user has no gender or no relationship_status — no gender boost (0 for all)
- [ ] **Privacy guard:** This signal only affects ORDER, not filtering — all genders still appear in results

**Rationale:** A single 20-year-old male naturally wants to discover women his age. But we're boosting, not filtering — same-gender friends-of-friends with high scores still rank well.

### Task 1.3: Shared Interests Signal (15 points max)

**File:** `app/Http/Controllers/Api/PeopleController.php` — `applyDiscoverySort()`

The `user_profiles.interests` column is JSON. The `user_interests` table has per-topic rows.

- [ ] Pre-load logged-in user's interest values: `$myInterests = UserInterest::where('user_id', $userId)->pluck('interest_value')->toArray()`
- [ ] If user has interests, add a subquery-based signal:
  ```sql
  + LEAST(15, (
      SELECT COUNT(*) * 3 FROM user_interests ui
      WHERE ui.user_id = user_profiles.id
        AND ui.interest_value IN (:myInterestsList)
    ))
  ```
- [ ] If user has no interests, skip signal (add 0)
- [ ] Cap at 15 points (5+ shared interests all score equally)

### Task 1.4: Engagement Score Signal (10 points max)

**File:** `app/Http/Controllers/Api/PeopleController.php` — `applyDiscoverySort()`

- [ ] Use existing `posts_count` and `photos_count` columns (no joins needed):
  ```sql
  + CASE
      WHEN posts_count + photos_count >= 50 THEN 10
      WHEN posts_count + photos_count >= 20 THEN 7
      WHEN posts_count + photos_count >= 5 THEN 4
      WHEN posts_count + photos_count >= 1 THEN 2
      ELSE 0
    END
  ```
- [ ] This rewards active creators without a correlated subquery

### Task 1.5: Profile Completeness Signal (10 points max)

**File:** `app/Http/Controllers/Api/PeopleController.php` — `applyDiscoverySort()`

Replace the 3 separate 5-point signals (has_photo, verified, has_bio) with a unified completeness score:

- [ ] Score 1 point each for (cap at 10):
  ```sql
  + (
      CASE WHEN profile_photo_path IS NOT NULL AND profile_photo_path != '' THEN 2 ELSE 0 END
      + CASE WHEN bio IS NOT NULL AND bio != '' THEN 2 ELSE 0 END
      + CASE WHEN is_verified = true THEN 2 ELSE 0 END
      + CASE WHEN date_of_birth IS NOT NULL THEN 1 ELSE 0 END
      + CASE WHEN gender IS NOT NULL THEN 1 ELSE 0 END
      + CASE WHEN district_name IS NOT NULL AND district_name != '' THEN 1 ELSE 0 END
      + CASE WHEN interests IS NOT NULL THEN 1 ELSE 0 END
    )
  ```
- [ ] Max 10 points: photo(2) + bio(2) + verified(2) + dob(1) + gender(1) + location(1) + interests(1)

### Task 1.6: Update Max Score Documentation

- [ ] Update any comments/docs referencing "max 130 points" to "max 200 points"
- [ ] Log the composite score in debug mode for tuning

---

## Phase 2: Backend — Performance & Caching

**Goal:** Eliminate correlated subqueries, add Redis caching, add missing indexes

### Task 2.1: Pre-compute Friends-of-Friends Set

**File:** `app/Http/Controllers/Api/PeopleController.php`

The current friends-of-friends signal runs a correlated subquery per row. Replace with a pre-computed set:

- [ ] Before the main query, compute the full friends-of-friends set:
  ```php
  // Get user's direct friend IDs
  $friendIds = Friendship::where('status', 'accepted')
      ->where(fn($q) => $q->where('user_id', $userId)->orWhere('friend_id', $userId))
      ->get()
      ->map(fn($f) => $f->user_id == $userId ? $f->friend_id : $f->user_id)
      ->unique()
      ->values()
      ->toArray();

  // Get friends-of-friends (excluding self and direct friends)
  $fofIds = Friendship::where('status', 'accepted')
      ->where(fn($q) => $q->whereIn('user_id', $friendIds)->orWhereIn('friend_id', $friendIds))
      ->get()
      ->map(fn($f) => in_array($f->user_id, $friendIds) ? $f->friend_id : $f->user_id)
      ->unique()
      ->reject(fn($id) => $id == $userId || in_array($id, $friendIds))
      ->values()
      ->toArray();
  ```
- [ ] Replace the correlated subquery with `CASE WHEN user_profiles.id IN (:fofIds) THEN 30 ELSE 0 END`
- [ ] This runs 2 queries upfront instead of N correlated subqueries

### Task 2.2: Redis Cache for Discovery Results

**File:** `app/Http/Controllers/Api/PeopleController.php`

- [ ] Cache discovery results per-user with 2-minute TTL:
  ```php
  $cacheKey = "people:discovery:{$userId}:page:{$page}";
  $cached = Cache::get($cacheKey);
  if ($cached) return response()->json($cached);

  // ... compute results ...

  Cache::put($cacheKey, $responseData, now()->addMinutes(2));
  ```
- [ ] Cache friends-of-friends set per-user with 5-minute TTL:
  ```php
  $fofKey = "people:fof:{$userId}";
  $fofIds = Cache::remember($fofKey, now()->addMinutes(5), fn() => $this->computeFofIds($userId));
  ```
- [ ] Invalidate on friendship changes: clear `people:fof:{$userId}` and `people:discovery:{$userId}:*` when a friendship is accepted/removed
- [ ] Do NOT cache search results (only discovery) — search queries are too varied

### Task 2.3: Database Indexes

**Migration file:** `database/migrations/2026_03_31_000001_add_people_search_indexes.php`

- [ ] Add indexes for text columns used in scoring/filtering:
  ```php
  Schema::table('user_profiles', function (Blueprint $table) {
      // Scoring columns
      $table->index('date_of_birth');
      $table->index('gender');
      $table->index('relationship_status');

      // Text search — trigram GIN indexes for ILIKE
      // (requires pg_trgm extension)
      DB::statement("CREATE INDEX IF NOT EXISTS idx_up_first_name_trgm ON user_profiles USING gin (first_name gin_trgm_ops)");
      DB::statement("CREATE INDEX IF NOT EXISTS idx_up_last_name_trgm ON user_profiles USING gin (last_name gin_trgm_ops)");
      DB::statement("CREATE INDEX IF NOT EXISTS idx_up_username_trgm ON user_profiles USING gin (username gin_trgm_ops)");

      // Location text columns used in scoring
      DB::statement("CREATE INDEX IF NOT EXISTS idx_up_district_name ON user_profiles (district_name) WHERE district_name IS NOT NULL");
      DB::statement("CREATE INDEX IF NOT EXISTS idx_up_region_name ON user_profiles (region_name) WHERE region_name IS NOT NULL");

      // Employer/school text columns used in scoring
      DB::statement("CREATE INDEX IF NOT EXISTS idx_up_employer_name ON user_profiles (LOWER(employer_name)) WHERE employer_name IS NOT NULL");
      DB::statement("CREATE INDEX IF NOT EXISTS idx_up_university_name ON user_profiles (LOWER(university_name)) WHERE university_name IS NOT NULL");
      DB::statement("CREATE INDEX IF NOT EXISTS idx_up_secondary_school ON user_profiles (LOWER(secondary_school_name)) WHERE secondary_school_name IS NOT NULL");
  });
  ```
- [ ] Enable `pg_trgm` extension: `CREATE EXTENSION IF NOT EXISTS pg_trgm`
- [ ] Add index on `user_interests`:
  ```php
  Schema::table('user_interests', function (Blueprint $table) {
      $table->index(['user_id', 'interest_value']);
  });
  ```
- [ ] Add index on `user_presence`:
  ```php
  Schema::table('user_presence', function (Blueprint $table) {
      $table->index(['user_id', 'last_seen_at']);
  });
  ```
- [ ] Drop redundant `user_profiles_phone_number_index` (the `_unique` index already covers it)

### Task 2.4: Optimize Text Search

**File:** `app/Http/Controllers/Api/PeopleController.php` — text search section

- [ ] Replace `ILIKE '%term%'` with trigram similarity for multi-word queries:
  ```php
  // Before (slow, no index):
  $query->where(function ($q) use ($term) {
      $q->where('first_name', 'ILIKE', "%{$term}%")
        ->orWhere('last_name', 'ILIKE', "%{$term}%")
        ->orWhere('username', 'ILIKE', "%{$term}%");
  });

  // After (uses GIN trigram index):
  $query->where(function ($q) use ($term) {
      $q->whereRaw("first_name % ?", [$term])
        ->orWhereRaw("last_name % ?", [$term])
        ->orWhereRaw("username % ?", [$term]);
  });
  ```
- [ ] For prefix searches (2-3 chars), keep `ILIKE 'term%'` (btree-friendly)
- [ ] Set trigram similarity threshold: `SET pg_trgm.similarity_threshold = 0.3`

---

## Phase 3: Backend — Feedback Loop Integration

**Goal:** Use event tracking data to refine ranking over time

### Task 3.1: Profile View Signal

**File:** `app/Http/Controllers/Api/PeopleController.php` — `applyDiscoverySort()`

- [ ] Demote profiles the user has already viewed recently (don't show the same people every day):
  ```sql
  - CASE WHEN EXISTS (
      SELECT 1 FROM events
      WHERE events.user_id = :userId
        AND events.event_type = 'profile_viewed'
        AND events.properties->>'target_user_id' = user_profiles.id::text
        AND events.created_at > NOW() - INTERVAL '3 days'
    ) THEN 10 ELSE 0 END
  ```
- [ ] This subtracts 10 points from recently-viewed profiles, pushing fresh faces up
- [ ] Only apply if `events` table has an index on `(user_id, event_type, created_at)`

### Task 3.2: Events Table Index

**Migration:** `database/migrations/2026_03_31_000002_add_events_indexes.php`

- [ ] Add composite index:
  ```php
  Schema::table('events', function (Blueprint $table) {
      $table->index(['user_id', 'event_type', 'created_at']);
  });
  ```

### Task 3.3: Track Discovery Impressions

**File:** `app/Http/Controllers/Api/PeopleController.php`

- [ ] After returning discovery results, fire a lightweight event recording which user IDs were shown:
  ```php
  // Fire-and-forget (queue job, don't block response)
  dispatch(fn() => Event::create([
      'user_id' => $userId,
      'event_type' => 'discovery_impression',
      'properties' => json_encode(['shown_user_ids' => $resultIds]),
  ]))->afterResponse();
  ```
- [ ] This feeds the "already viewed" demotion signal without requiring user interaction

---

## Phase 4: Frontend — Smart Discovery UI

**Goal:** Make the frontend leverage the improved ranking and feed signals back to the backend

### Task 4.1: Discovery Mode Indicator

**File:** `lib/screens/friends/people_search_tab.dart`

- [ ] Show a subtle header when in discovery mode (no search query): "People you might like"
- [ ] Show sorting context: "Based on your location, interests, and connections"
- [ ] When user has search query: show "Search results for '{query}'"

### Task 4.2: Filter Quick-Chips

**File:** `lib/screens/friends/people_search_tab.dart`

- [ ] Add horizontal chip row below search bar with quick filters:
  - "Nearby" → `location: user's district`
  - "My Age" → `age_min: myAge-3, age_max: myAge+3`
  - "Online" → `online: true`
  - "With Photo" → `has_photo: true`
  - "Students" → `student: true`
  - "Business" → `has_business: true`
- [ ] Chips are toggleable — multiple can be active simultaneously
- [ ] Active chips are visually highlighted (filled vs outlined)
- [ ] Chip selection triggers re-search with updated filters
- [ ] Persist last-used chips in Hive for returning users

### Task 4.3: Profile Card Enhancements

**File:** `lib/screens/friends/people_search_tab.dart` — `_buildPersonCard()`

- [ ] Show mutual friends count badge (already in `PersonSearchResult.mutualFriendsCount`)
- [ ] Show "X shared interests" if `inCommon` list is non-empty
- [ ] Show online indicator dot (green) if `isOnline == true`
- [ ] Show distance/location tag: "Same area" if same district, "Nearby" if same region
- [ ] Show age if available (from `dateOfBirth`)

### Task 4.4: Swipe-to-Skip Gesture

**File:** `lib/screens/friends/people_search_tab.dart`

- [ ] Add `Dismissible` wrapper on profile cards with horizontal swipe
- [ ] Left swipe = "Not interested" → track `not_interested` event with target_user_id
- [ ] Card animates out, removed from current list
- [ ] Backend uses this signal to demote in future discovery (Phase 3.1 demotion)

### Task 4.5: Pull-to-Refresh with Shuffle

**File:** `lib/screens/friends/people_search_tab.dart`

- [ ] Add `RefreshIndicator` for pull-to-refresh
- [ ] On refresh: clear prefetched pages, fetch fresh discovery results
- [ ] Backend's day-seeded randomness means same-day refreshes return same order
- [ ] Add optional `shuffle=1` query param support on backend to force re-randomization within same day

### Task 4.6: Track Profile Interactions

**File:** `lib/screens/friends/people_search_tab.dart`

Ensure all user interactions are tracked via `EventTrackingService`:

- [ ] `profile_viewed` — when user taps a profile card (already done)
- [ ] `search` — when user submits a search query (already done)
- [ ] `follow` / `unfollow` — on friend request/remove (already done)
- [ ] `not_interested` — on swipe-to-skip (Task 4.4)
- [ ] `discovery_scroll_depth` — track how far user scrolls in discovery (every 10 profiles)

---

## Phase 5: Frontend — Advanced Performance

**Goal:** Sub-100ms perceived load time for all discovery interactions

### Task 5.1: Optimistic Cache Warming

**File:** `lib/services/people_cache_service.dart`

- [ ] On app startup (if user has been active in last 24h), prefetch discovery page 1 in background
- [ ] Store with timestamp — serve from cache if <5 minutes old
- [ ] Background refresh doesn't block UI

### Task 5.2: Infinite Scroll with Page Cache

**File:** `lib/screens/friends/people_search_tab.dart`

- [ ] Cache loaded pages in memory: `Map<int, List<PersonSearchResult>> _pageCache`
- [ ] When scrolling back up, render from page cache (no re-fetch)
- [ ] Prefetch page N+1 at 60% scroll depth of page N (already implemented)
- [ ] Clear page cache on filter change or pull-to-refresh

### Task 5.3: Avatar Preload Pipeline

**File:** `lib/screens/friends/people_search_tab.dart`

- [ ] On page load, precache avatars for visible + next-10 profiles (already implemented)
- [ ] Use `memCacheWidth: 150, memCacheHeight: 150` to avoid full-res decode
- [ ] Track preload hits/misses in PerfLogger

### Task 5.4: Search Debounce Optimization

**File:** `lib/screens/friends/people_search_tab.dart`

- [ ] Current debounce: 500ms after typing stops
- [ ] Show local results from page cache immediately while API debounce runs
- [ ] If query matches prefix of cached results, filter client-side for instant feedback
- [ ] Cancel in-flight HTTP request when new query arrives (`CancelToken` pattern)

---

## Phase 6: Backend — Sort Variants Powered by V2 Scoring

**Goal:** Leverage the new signals for specialized sort modes

### Task 6.1: Update `similar_to_me` Sort

**File:** `app/Http/Controllers/Api/PeopleController.php`

The existing `similar_to_me` sort should use the V2 signals:

- [ ] Weight: age_proximity(30) + same_district(20) + shared_interests(20) + same_school(15) + same_employer(15) + same_gender(0)
- [ ] This is a different weighting than discovery — it's about similarity, not attraction

### Task 6.2: New Sort: `for_you`

**File:** `app/Http/Controllers/Api/PeopleController.php`

- [ ] Add `for_you` sort option that uses the full V2 composite scoring
- [ ] This becomes the default sort for discovery mode (replacing `relevance`)
- [ ] Keep `relevance` as an alias for backward compatibility

### Task 6.3: Backend `shuffle` Parameter

**File:** `app/Http/Controllers/Api/PeopleController.php`

- [ ] Accept `shuffle=1` query parameter
- [ ] When set, use `hashtext(id || timestamp_minutes)` instead of `hashtext(id || date)` for intra-day randomness
- [ ] This supports the frontend pull-to-refresh shuffle (Phase 4.5)

---

## Execution Order & Dependencies

```
Phase 1 (Backend scoring)     ← No dependencies, start here
Phase 2 (Backend performance) ← Independent of Phase 1, can run in parallel
Phase 3 (Backend feedback)    ← Depends on events tracking (already deployed)
Phase 4 (Frontend UI)         ← Depends on Phase 1 (new signals in API response)
Phase 5 (Frontend perf)       ← Independent, can run anytime
Phase 6 (Backend sorts)       ← Depends on Phase 1
```

**Recommended parallel execution:**
- Week 1: Phase 1 + Phase 2 (backend, independent)
- Week 2: Phase 3 + Phase 4 (backend feedback + frontend UI)
- Week 3: Phase 5 + Phase 6 (frontend perf + backend sorts)

---

## Files Summary

### Modified Files (Backend)

| File | Phase | Change |
|------|-------|--------|
| `app/Http/Controllers/Api/PeopleController.php` | 1,2,3,6 | New scoring signals, pre-computed FoF, Redis cache, shuffle param, for_you sort |
| `database/migrations/2026_03_31_000001_add_people_search_indexes.php` | 2 | New indexes on user_profiles, user_interests, user_presence |
| `database/migrations/2026_03_31_000002_add_events_indexes.php` | 3 | Composite index on events table |

### Modified Files (Frontend)

| File | Phase | Change |
|------|-------|--------|
| `lib/screens/friends/people_search_tab.dart` | 4,5 | Filter chips, card enhancements, swipe-to-skip, pull-to-refresh, scroll tracking, search debounce |
| `lib/services/people_search_service.dart` | 4 | Add shuffle param, for_you sort support |
| `lib/services/people_cache_service.dart` | 5 | Startup prefetch, page cache |
| `lib/models/people_search_models.dart` | 4 | Ensure all new response fields are parsed |

---

## Success Metrics

| Metric | Before (V1) | After (V2) |
|--------|-------------|------------|
| Scoring signals | 7 | 11 |
| Max composite score | 130 | 200 |
| Age-aware ranking | No | Yes — same-age users ranked higher |
| Gender-preference ranking | No | Yes — single users see preferred gender |
| Interests matching | No | Yes — shared interests boost ranking |
| Discovery API response time (p50) | ~300ms (uncached) | <50ms (Redis hit), <200ms (miss) |
| Text search index support | No (ILIKE %%) | Yes (pg_trgm GIN) |
| Friends-of-friends query | Correlated subquery | Pre-computed set |
| Frontend filter options | 0 quick-chips | 6 one-tap filters |
| Profile interaction tracking | Partial | Full (view, skip, scroll depth) |
| Already-viewed demotion | No | Yes — seen profiles demoted for 3 days |

---

## Edge Cases & Guards

1. **New users with no profile data:** All new signals gracefully degrade to 0 points — user still sees results ranked by existing signals (location, activity, verification)
2. **Users with no DOB:** Age proximity signal returns 0, not a penalty
3. **Users with no interests:** Interests signal returns 0; fallback to location/social signals
4. **Same-gender preference:** The gender boost only applies to single-ish users. Users in relationships or without relationship_status see no gender-based reordering
5. **Privacy:** Gender preference affects ORDER only, never filters out profiles. All genders always appear in results
6. **Small user base (30 users):** Redis TTL of 2 minutes is appropriate — results don't change fast. As user base grows, consider reducing TTL
7. **Cache invalidation:** Friendship changes invalidate FoF cache. Profile updates invalidate discovery cache for users in same district
