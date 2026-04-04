# TAJIRI Performance Strategy — Implementation Plan

## Context
TAJIRI shows a loading spinner on every app open because there's zero feed persistence between sessions. All 5 tabs load simultaneously on login (15+ API calls). Images show grey boxes while loading. No background sync, no HTTP caching, no profile/shop caching. This plan eliminates these gaps across 5 phases (~6 weeks), making TAJIRI feel as instant as Instagram.

Reference: `docs/PERFORMANCE_STRATEGY.md`

---

## Phase 1: Feed Cache + Quick Wins (Week 1)
**Goal: Eliminate the loading spinner for returning users**

### 1.1 Complete Post serialization (prerequisite for any caching)

**File: `lib/models/post_models.dart`**

`Post.toJson()` (line 294) is incomplete — missing `user`, `media`, `hashtags`, `isLiked`, `isSaved`, `createdAt`, `originalPost`, and 15+ other fields present in `fromJson`. Add them all.

Add `toJson()` to three classes that lack it:
- `PostMedia` (line ~726) — id, postId, mediaType, filePath, thumbnailPath, dominantColor, width, height, duration, order
- `PostUser` (line ~845) — id, firstName, lastName, username, profilePhotoPath, isFollowing
- `Hashtag` (line ~580) — id, name, postsCount, isTrending

### 1.2 Create FeedCacheService

**New file: `lib/services/feed_cache_service.dart`**

Follow `MessageCacheService` pattern (singleton, `Box<String>`, JSON strings):
- Hive box: `'feed_cache'`
- `savePosts(feedType, List<Post>)` → `jsonEncode(posts.map(toJson))`, key `'feed_$feedType'`
- `getPosts(feedType)` → decode JSON, `Post.fromJson()` each
- `getLastFetchTime(feedType)` → timestamp from meta key
- `clear()` → called on logout
- Max 100 posts per feed type, 3 types = ~300KB

### 1.3 Modify FeedScreen for stale-while-revalidate

**File: `lib/screens/feed/feed_screen.dart`**

Change `_loadFeed()` (line 603):
1. Load cached posts from `FeedCacheService` → `setState` immediately (0ms)
2. Fire `ContentEngineService.feed()` in parallel
3. On API success: compare new post IDs with displayed
4. If different → show "New posts" pill at top (don't disrupt scroll)
5. On pill tap → swap in new data, scroll to top
6. Save fresh posts to cache

New state fields: `bool _hasNewPosts`, `List<Post>? _pendingPosts`

### 1.4 Clear cache on logout

**File: `lib/services/auth_service.dart`** — Add `FeedCacheService.instance.clear()` in `_performLocalLogout()`

### 1.5 Quick Wins (< 1 hour each)

| Fix | File | Line | Change |
|-----|------|------|--------|
| Bump media cache limit | `lib/services/media_cache_service.dart` | 18 | `maxNrOfCacheObjects: 200` → `1000` |
| Earlier scroll trigger | `lib/screens/feed/feed_screen.dart` | 531 | `maxScrollExtent - 500` → `maxScrollExtent - 1000` |
| Fix FriendsScreen rebuild | `lib/screens/home/home_screen.dart` | 110 | Use `_screens[2]` instead of `new FriendsScreen(...)` on every build |

### Verification
- Cold-start app → feed renders instantly from cache (no spinner)
- Fresh data arrives → "New posts" pill appears
- `Post.fromJson(post.toJson())` round-trip unit test for posts with media, user, hashtags
- `flutter analyze` passes

---

## Phase 2: BlurHash Image Placeholders (Week 2)
**Goal: Replace grey boxes with beautiful blurred previews**

### 2.1 Backend — BlurHash generation

**Server: `172.240.241.180` (`/var/www/tajiri.zimasystems.com`)**

1. `composer require kornrunner/php-blurhash`
2. Migration: add `blurhash VARCHAR(50) NULLABLE` to `post_media` (after `dominant_color`)
3. Migration: add `avatar_blurhash VARCHAR(50) NULLABLE` to `user_profiles` (after `profile_photo_path`)
4. `ImageProcessingService` (`app/Services/ImageProcessingService.php`): after `extractDominantColor()`, resize to 32×32, compute `Blurhash::encode($pixels, 4, 3)`, save to `$media->blurhash`
5. Backfill artisan command: process existing `post_media` rows missing blurhash (batch 100)

### 2.2 Backend — Fix V2 feed hydration (CRITICAL)

V2 feed `hydrate()` calls `toArray()` WITHOUT eager loading `media` relation. This means `dominant_color`, `blurhash`, `thumbnail_path` are NOT in v2 feed responses.

Fix: add `->load('media')` in the hydration step so media data is included.

### 2.3 Frontend — BlurHash rendering

1. `pubspec.yaml`: add `flutter_blurhash: ^1.2.1`
2. `PostMedia` model: add `String? blurhash` field to constructor, `fromJson`, `toJson`
3. `CachedMediaImage` (`lib/widgets/cached_media_image.dart`):
   - Add `String? blurhash` and `String? dominantColor` params
   - In `_buildPlaceholder()`: if blurhash non-null → `BlurHash(hash: blurhash)`. If only dominantColor → `Container(color: parsedColor)`. Else → current grey box.
4. `PostCard` / media widgets: pass `media.blurhash` and `media.dominantColor` through

### 2.4 Fix CachedAvatarImage memory leak

**File: `lib/widgets/cached_media_image.dart` (line ~135)**

Add `memCacheWidth` and `memCacheHeight` to `CachedNetworkImage` (currently decodes avatars at full resolution):
```dart
memCacheWidth: (radius * 6).toInt(),  // 3x pixel ratio
memCacheHeight: (radius * 6).toInt(),
```

### Verification
- Upload new image → API response includes `blurhash`
- Feed: blurred preview shows instantly, resolves to full image
- Run backfill → existing posts get blurhash
- DevTools: avatar memory usage decreases

---

## Phase 3: Lazy Tab Loading + Service Caching (Week 3)
**Goal: Cut startup API calls from 15+ to 3-5**

### 3.1 LazyIndexedStack widget

**New file: `lib/widgets/lazy_indexed_stack.dart`**

```dart
class LazyIndexedStack extends StatefulWidget {
  final int index;
  final List<Widget Function()> builders;
}
// State tracks Set<int> _activatedIndices
// Only builds children that have been selected at least once
```

### 3.2 Apply to HomeScreen

**File: `lib/screens/home/home_screen.dart`**

Replace `IndexedStack` (line 105) with `LazyIndexedStack`. Convert `_screens` list to builder functions. On login, only Feed tab builds and fires API calls.

Also fix: `FriendsScreen` at line 110 creates a new instance every `setState`. Use `_screens[2]` from the cached list instead.

### 3.3 ProfileService in-memory cache

**File: `lib/services/profile_service.dart`**

Add static `Map<int, (FullProfile, DateTime)> _cache` with 5-min TTL, max 50 entries. `getProfile()` returns cached if fresh, refreshes in background. LRU eviction when full.

### 3.4 ShopService category cache

**File: `lib/services/shop_service.dart`**

Categories are near-static. Add static cache with 1-hour TTL:
```dart
static List<ShopCategory>? _categoriesCache;
static DateTime? _categoriesFetchedAt;
```

### Verification
- Login → only Feed tab fires API calls (check network panel)
- Tap Messages tab → loads on first visit, instant on return
- Visit same profile twice → second is instant (debug print confirms cache hit)
- Shop categories → no re-fetch on tab return

---

## Phase 4: Prefetch & Pagination (Week 4)
**Goal: Eliminate "loading more" spinners, smoother scroll**

### 4.1 Feed next-page prefetch

**File: `lib/screens/feed/feed_screen.dart`**

In `_onScroll()` (line 526): at 60% scroll depth, prefetch next page in background. Store in `_prefetchedNextPage`. When `_loadMore()` fires, use prefetched data instantly.

### 4.2 Reduce media preload stagger

**File: `lib/services/media_cache_service.dart` (line ~162)**

Change `Duration(milliseconds: 100)` → `Duration(milliseconds: 30)` in `preloadMediaList()`.

### 4.3 Conversation list cache

**New file: `lib/services/conversation_cache_service.dart`**

Hive-backed cache following `MessageCacheService` pattern. Show cached conversations immediately, refresh in background. Requires `Conversation.toJson()` (verify/add if missing).

**File: `lib/screens/messages/conversations_screen.dart`** — load from cache first, then refresh on `MessagesUpdateEvent` without showing spinner.

### 4.4 Story thumbnail prefetch

**File: `lib/screens/feed/feed_screen.dart`**

After `_loadStories()` completes, call `ImagePreloader.precacheImages()` for first 5-10 story thumbnail URLs.

### Verification
- Scroll feed slowly → next page loads with zero delay at bottom
- Messages tab opens instantly on return visits
- Story thumbnails appear without flicker

---

## Phase 5: Background Sync & HTTP Caching (Weeks 5-6)
**Goal: Cache is warm before user opens app, less bandwidth**

### 5.1 Background feed refresh

1. `pubspec.yaml`: add `workmanager: ^0.5.2`
2. **New file: `lib/services/background_sync_service.dart`** — register periodic task (15 min), fetch feed page 1, write to `FeedCacheService`
3. `lib/main.dart`: call `BackgroundSyncService.initialize()` after Hive init

### 5.2 Backend — ETag middleware

**Server: create `ETagMiddleware`**
- Compute `md5` of response body, set `ETag` header
- Check `If-None-Match` → return 304 if matches
- Apply to: `/v2/feed`, `/users/{id}`, `/shop/categories`

### 5.3 Frontend — ETag client

**New file: `lib/services/etag_cache_service.dart`**

Hive box `'etag_cache'` storing ETags + response bodies per URL. Sends `If-None-Match` header, uses cached body on 304.

Integrate into `ContentEngineService.feed()` and `ProfileService.getProfile()` first.

### 5.4 Search history

**New file: `lib/services/search_history_service.dart`**

Hive-backed list, max 20 queries. Show as suggestion chips in `universal_search_screen.dart` when query is empty.

### Verification
- Kill app, wait 15 min, reopen → feed shows background-refreshed content
- Network tab shows 304 responses on repeated profile/category loads
- Search screen shows recent queries as chips

---

## Parallel Execution Plan

```
Week 1: Phase 1 (frontend) + Phase 2.1-2.2 (backend BlurHash + hydration fix)
Week 2: Phase 2.3-2.4 (frontend BlurHash) + Phase 3 (lazy tabs + caches)
Week 3: Phase 4 (prefetch + conversation cache)
Week 4: Phase 5 (background sync + ETag)
```

Phases 1 and 3 have no dependencies. Phase 2 frontend depends on Phase 2 backend. Phase 4 depends on Phase 1's `FeedCacheService`. Phase 5 depends on Phase 1 + Phase 2 backend.

---

## Files Summary

### New Files (Frontend)
| File | Phase | Purpose |
|------|-------|---------|
| `lib/services/feed_cache_service.dart` | 1 | Hive-backed feed persistence |
| `lib/widgets/lazy_indexed_stack.dart` | 3 | Lazy tab builder |
| `lib/services/conversation_cache_service.dart` | 4 | Hive-backed conversation list cache |
| `lib/services/background_sync_service.dart` | 5 | WorkManager background refresh |
| `lib/services/etag_cache_service.dart` | 5 | ETag HTTP cache client |
| `lib/services/search_history_service.dart` | 5 | Search query persistence |

### Modified Files (Frontend)
| File | Phase | Change |
|------|-------|--------|
| `lib/models/post_models.dart` | 1,2 | Complete toJson(), add blurhash field |
| `lib/screens/feed/feed_screen.dart` | 1,4 | Stale-while-revalidate, prefetch, story prefetch |
| `lib/services/auth_service.dart` | 1 | Clear feed cache on logout |
| `lib/services/media_cache_service.dart` | 1,4 | Bump limit to 1000, reduce stagger |
| `lib/screens/home/home_screen.dart` | 1,3 | Fix FriendsScreen rebuild, lazy tabs |
| `lib/widgets/cached_media_image.dart` | 2 | BlurHash placeholder, avatar memCache fix |
| `lib/services/profile_service.dart` | 3 | In-memory LRU cache |
| `lib/services/shop_service.dart` | 3 | Category cache |
| `lib/screens/messages/conversations_screen.dart` | 4 | Cache-first loading |
| `lib/screens/search/universal_search_screen.dart` | 5 | Search history |
| `pubspec.yaml` | 2,5 | flutter_blurhash, workmanager |
| `lib/main.dart` | 5 | Background sync init |

### Backend Changes
| Change | Phase | Location |
|--------|-------|----------|
| `composer require kornrunner/php-blurhash` | 2 | Server |
| Migration: `post_media.blurhash` column | 2 | Server |
| Migration: `user_profiles.avatar_blurhash` column | 2 | Server |
| `ImageProcessingService`: add BlurHash compute | 2 | `app/Services/ImageProcessingService.php` |
| Backfill artisan command | 2 | Server |
| Fix V2 feed hydration to include media relations | 2 | `ServingPipelineService` or `FeedController` |
| `ETagMiddleware` | 5 | `app/Http/Middleware/ETagMiddleware.php` |
| Register ETag middleware for API routes | 5 | `Kernel.php` or route group |

---

## Success Metrics

| Metric | Before | After |
|--------|--------|-------|
| Time to first post (returning user) | 2-5s | <100ms |
| Startup API calls | 15+ | 3-5 |
| Image placeholder | Grey box + spinner | BlurHash instant |
| "Loading more" at scroll bottom | 0.5-2s spinner | 0ms (prefetched) |
| Feed cache hit rate | 0% | >80% |
