# TAJIRI Performance Strategy

## Current State Assessment

### What TAJIRI Does Well
- **Media caching** — `MediaCacheManager` (30-day disk cache, 200 files) + `CachedNetworkImage` for images
- **Video/Audio prefetching** — YouTube-style priority queue (±2 clips ahead, ±3 audio tracks)
- **Feed media preloading** — 1500px viewport buffer pre-downloads images as user scrolls
- **Optimistic UI** — like, reaction, and save update immediately with revert-on-failure
- **Message caching** — `MessageCacheService` stores 500 messages per conversation in Hive
- **Profile tab persistence** — tab order/enabled state survives restarts

### What TAJIRI Does Poorly (The Gaps)

| Problem | Impact | Root Cause |
|---------|--------|------------|
| Feed shows spinner on every app open | **Critical** — makes app feel slow vs Instagram | No feed persistence to disk; `_postsCache` is in-memory only |
| All 5 tabs load simultaneously on login | Wasted bandwidth/CPU; delays the visible tab | `IndexedStack` builds all children eagerly |
| Profile fetched fresh on every visit | Repeated API calls for same data | No profile cache |
| Shop loads 4 parallel API calls on every mount | Unnecessary network churn | No product/category cache |
| Images show grey box + spinner while loading | App feels unpolished | No BlurHash placeholders |
| No background feed refresh | Cache is always cold on app open | No `WorkManager`/`BGTaskScheduler` |
| No HTTP-level caching (ETag/304) | Every request downloads full response | No `If-None-Match` headers |
| Search has no history or suggestion cache | Users re-type the same queries | No persistence |
| Stories/Friends load fresh every time | Unnecessary API calls | No staleness check |
| NotificationsScreen is a stub | Missing feature | Unimplemented |

---

## Strategy: 5 Phases

### Phase 1: Stale-While-Revalidate Feed Cache (Week 1)
**Impact: Eliminates the loading spinner for returning users**

The single most impactful change. Instagram, TikTok, Twitter all do this.

#### What to build

**New: `lib/services/feed_cache_service.dart`**
```
FeedCacheService (singleton)
├── Hive box: 'feed_cache'
├── save(feedType, List<Post>, meta) → serialize to JSON, store with timestamp
├── load(feedType) → deserialize, return (posts, meta, cachedAt)
├── isStale(feedType) → cachedAt > 5 minutes ago
└── clear() → called on logout
```

**Modify: `lib/screens/feed/feed_screen.dart`**
```
initState:
  1. Load cached feed from Hive → setState with cached posts (0ms)
  2. Fire ContentEngineService.feed() in background
  3. When API responds:
     - If new posts at top → show "New posts" pill, don't disrupt scroll
     - If counts changed → update in-place silently
     - If identical → do nothing
  4. Save fresh response to cache
```

#### What to cache per feed type
- Post JSON (text, media URLs, counts, user snippet)
- Feed meta (hasMore, cursor/page)
- Timestamp of cache write
- Separate keys: `feed_posts_page1`, `feed_friends_page1`, `feed_live_page1`

#### Cache limits
- Store page 1 only (20 posts per feed type)
- Max 3 feed types × 20 posts = ~60 post objects
- Estimated storage: 100-200KB (negligible)
- TTL: display stale immediately, mark as needing refresh after 5 min

#### Files to modify
- `lib/services/feed_cache_service.dart` (NEW)
- `lib/screens/feed/feed_screen.dart` (_loadFeed, initState)
- `lib/services/auth_service.dart` (clear cache on logout)

---

### Phase 2: BlurHash Image Placeholders (Week 2)
**Impact: Eliminates grey boxes, app feels polished**

#### Backend work required
- At image upload time, generate a BlurHash string (4×3 components, ~30 chars)
- Store in `posts.blurhash`, `user_profiles.avatar_blurhash` columns
- Return in API responses alongside image URLs

#### Frontend work
- Add `flutter_blurhash` package
- Modify `CachedMediaImage` widget to accept optional `blurhash` parameter
- Render BlurHash as placeholder instead of grey box + spinner
- Modify `Post` model to parse `blurhash` field from JSON

#### Files to modify
- `pubspec.yaml` (add flutter_blurhash)
- `lib/widgets/cached_media_image.dart` (BlurHash placeholder)
- `lib/models/post.dart` (add blurhash field)
- `lib/widgets/post_card.dart` (pass blurhash to image widget)
- Backend: migration + upload pipeline

---

### Phase 3: Lazy Tab Loading + Profile/Shop Cache (Week 3)
**Impact: Faster startup, fewer wasted API calls**

#### 3a. Lazy Tab Loading

Currently `IndexedStack` builds all 5 screens on app open — Messages, Friends, Shop, and Profile all fire API calls even though the user is looking at Feed.

**Fix:** Replace `IndexedStack` with lazy-building wrapper:
```dart
class _LazyTab extends StatefulWidget {
  final bool active;       // true when tab is selected
  final Widget Function() builder;
  bool _built = false;

  Widget build(context) {
    if (active || _built) {
      _built = true;
      return builder();
    }
    return const SizedBox.shrink();
  }
}
```

Or use `Offstage` + a `_hasBeenVisible` flag per tab. First visit builds the screen; subsequent visits keep it alive.

#### 3b. Profile Cache

**New: Simple in-memory LRU cache in ProfileService**
```dart
static final _cache = <int, (UserProfile, DateTime)>{};  // userId → (profile, fetchedAt)
static const _ttl = Duration(minutes: 10);

static Future<UserProfile?> getProfile(int userId, ...) {
  final cached = _cache[userId];
  if (cached != null && DateTime.now().difference(cached.$2) < _ttl) {
    // Return cached immediately, refresh in background
    _refreshInBackground(userId, ...);
    return cached.$1;
  }
  // Fetch fresh
}
```

#### 3c. Shop Cache

Same pattern — cache categories (rarely change) with 1-hour TTL. Cache page-1 products with 5-min TTL.

#### Files to modify
- `lib/screens/home/home_screen.dart` (lazy tab wrapper)
- `lib/services/profile_service.dart` (LRU cache)
- `lib/services/shop_service.dart` (category + product cache)

---

### Phase 4: Prefetch & Pagination Improvements (Week 4)
**Impact: Eliminates "loading more" spinners, smoother infinite scroll**

#### 4a. Prefetch next feed page
When user scrolls past 60% of current page, prefetch the next page in background. Store in memory, append seamlessly when user reaches bottom.

```dart
// In feed scroll listener
if (scrollPercent > 0.6 && !_prefetchingNext && _hasMore) {
  _prefetchingNext = true;
  _nextPagePosts = await ContentEngineService.feed(page: _currentPage + 1);
}

// In _loadMore (existing)
if (_nextPagePosts != null) {
  _posts.addAll(_nextPagePosts!);  // instant, no spinner
  _nextPagePosts = null;
  _prefetchingNext = false;
}
```

#### 4b. Story prefetch
When stories load, immediately download thumbnails for the first 5 stories via `MediaCacheService.preloadMediaList()`.

#### 4c. Conversation list cache
Cache conversation list in Hive (like messages). Show cached list on open, refresh in background.

#### Files to modify
- `lib/screens/feed/feed_screen.dart` (prefetch logic)
- `lib/screens/feed/feed_screen.dart` (story thumbnail prefetch)
- `lib/services/message_service.dart` or new `conversation_cache_service.dart`

---

### Phase 5: Background Sync & HTTP Caching (Week 5-6)
**Impact: Cache is warm before user opens app; less bandwidth usage**

#### 5a. Background feed refresh
```yaml
# pubspec.yaml
dependencies:
  workmanager: ^0.5.2
```

Register periodic task (minimum 15 min on iOS, configurable on Android):
```dart
Workmanager().registerPeriodicTask(
  'feedRefresh',
  'refreshFeed',
  frequency: Duration(minutes: 15),
  constraints: Constraints(networkType: NetworkType.connected),
);
```

Callback: fetch feed page 1, write to `FeedCacheService`. When user opens app, cache is already fresh.

#### 5b. ETag / If-None-Match support

Modify `ApiConfig.authHeaders()` to support conditional requests:
```dart
static Map<String, String> authHeaders(String token, {String? etag}) => {
  ...headers,
  'Authorization': 'Bearer $token',
  if (etag != null) 'If-None-Match': etag,
};
```

Store ETag per endpoint in Hive. On 304 response, skip parsing — use cached data. Saves bandwidth and server load for unchanged data.

#### 5c. Search history
Persist last 20 search queries in Hive. Show as suggestions before user types.

#### Files to modify
- `pubspec.yaml` (workmanager)
- `lib/main.dart` (register background tasks)
- `lib/config/api_config.dart` (ETag headers)
- `lib/services/content_engine_service.dart` (ETag storage/checking)
- `lib/screens/search/universal_search_screen.dart` (search history)

---

## Implementation Priority Matrix

| Phase | Change | Effort | Impact | Dependency |
|-------|--------|--------|--------|------------|
| **1** | Feed cache (stale-while-revalidate) | 2 days | **Critical** | None |
| **2** | BlurHash placeholders | 3 days | **High** | Backend migration |
| **3a** | Lazy tab loading | 0.5 day | **High** | None |
| **3b** | Profile cache | 1 day | Medium | None |
| **3c** | Shop cache | 1 day | Medium | None |
| **4a** | Feed page prefetch | 1 day | Medium | Phase 1 |
| **4b** | Story thumbnail prefetch | 0.5 day | Low | None |
| **4c** | Conversation list cache | 1 day | Medium | None |
| **5a** | Background sync | 2 days | Medium | Phase 1 |
| **5b** | ETag support | 2 days | Medium | Backend support |
| **5c** | Search history | 0.5 day | Low | None |

---

## Quick Wins (< 1 hour each)

1. **Increase MediaCacheManager.maxNrOfCacheObjects** from 200 → 1000 (current limit is too low for a feed-heavy app)
2. **Add `Gapless` playback** — when video clip ends, start next one without black frame
3. **Reduce scroll trigger** from 500px to 1000px for earlier pagination fetch
4. **Cache conversation unread count** in Hive to show correct badge without API call on startup
5. **Remove duplicate FcmService.sendTokenToBackend** — called in both `HomeScreen.initState` and login flow

---

## Architecture Target State

```
App Opens (returning user)
  ├── Frame 0: Cached feed from Hive (instant)
  ├── Frame 1: BlurHash placeholders for images not in disk cache
  ├── Frame 2: Cached images from MediaCacheManager (disk)
  ├── Background: API fetch for fresh feed
  ├── Background: Prefetch next page
  └── 2-5s later: Fresh data diffed in silently

App Opens (first install)
  ├── Frame 0: Skeleton shimmer screen
  ├── Frame 1-3: API fetch completes, feed renders
  └── Frame 4+: Images load with BlurHash → thumbnail → full-res

Tab Switch (first visit)
  ├── Lazy build: screen constructed on first tap
  └── API calls fire only when tab first becomes visible

Tab Switch (return visit)
  ├── Cached screen from IndexedStack (instant)
  └── Background refresh if stale

Background (app minimized)
  ├── WorkManager: refresh feed cache every 15 min
  └── Pre-warm feed so next open is instant
```

---

## Metrics to Track

| Metric | Current (est.) | Target | How to Measure |
|--------|----------------|--------|----------------|
| Time to first post visible | 2-5s | <100ms (cached) | EventTracking: timestamp from initState to first post render |
| Feed API calls per session | 5-10 (every tab switch) | 1-2 (initial + refresh) | Server-side analytics |
| Image placeholder duration | 500ms-2s (grey box) | 0ms (BlurHash instant) | Visual inspection |
| Simultaneous API calls on startup | 15+ (all tabs) | 3-5 (feed tab only) | Network profiler |
| App storage for cache | ~0 MB (no cache) | 10-50 MB | Device storage settings |
| Feed cache hit rate | 0% | >80% for returning users | FeedCacheService logging |
