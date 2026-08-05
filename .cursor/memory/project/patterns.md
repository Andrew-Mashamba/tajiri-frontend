# TAJIRI Project Patterns

## Laravel backend repo location #pattern
**Date**: 2026-05-05  
**Path**: `/Volumes/DATA/PROJECTS/TAJIRI/TAJIRI-BACKEND/`  
**Context**: Marketplace HTTP routes live in `routes/api.php` under `Route::prefix('shop')` and the duplicated `foreach (['shop', 'v1/shop'])` block. Shop controllers: `app/Http/Controllers/Api/V1/Shop/`. Align Flutter `ShopService` / `ShopExtendedApi` paths with `/api/shop/...` on this codebase.

---

## Local Storage Pattern #pattern
**Date**: 2026-01-28
**Context**: Hive-based local storage with singleton service

**What happened**: Project uses `LocalStorageService` singleton with Hive for all local data. Access via `await LocalStorageService.getInstance()` then call methods like `getUser()`, `saveUser()`, `getCachedFeed()`, etc. Initialized in main.dart with `await Hive.initFlutter()`.

**Key lesson**: Always use LocalStorageService singleton, never access Hive directly. Cache API responses for offline support.
**Files**: `lib/services/local_storage_service.dart`, `lib/main.dart`
**Tags**: #storage #hive #singleton #pattern

---

## Route ID Parsing Pattern #pattern
**Date**: 2026-01-28
**Context**: Dynamic routing with IDs in URL

**What happened**: Routes like `/chat/123` or `/profile/456` are parsed in `onGenerateRoute` using `Uri.parse()` and `pathSegments`. First segment is route name, second is ID. IDs parsed with `int.tryParse()` with fallback to 0.

**Key lesson**: All dynamic routes follow pattern `/routeName/id`. Always provide fallback for invalid IDs.
**Files**: `lib/main.dart:48-186`
**Tags**: #routing #pattern #navigation

---

## CurrentUserId Pattern #pattern
**Date**: 2026-01-28
**Context**: Getting logged-in user ID for screens

**What happened**: Routes use `FutureBuilder` with helper function `getCurrentUserId()` that fetches from LocalStorageService. This ensures user is loaded before rendering screens that need authentication.

**Key lesson**: Wrap authenticated screens in FutureBuilder with getCurrentUserId. Show CircularProgressIndicator while loading.
**Files**: `lib/main.dart:54-57`
**Tags**: #auth #pattern #futurebuilder

---

## Offline-First Pattern #success
**Date**: 2026-01-28
**Context**: App works offline with sync when online

**What happened**: All features cache data locally via Hive. When offline, read from cache. When online, fetch fresh data and update cache. Queue pending actions (posts, likes, messages) and sync when connected.

**Key lesson**: Every API call should have corresponding cache read/write. Implement optimistic updates for instant feedback.
**Expected files**: `lib/services/cache_service.dart`, `lib/services/sync_service.dart`
**Tags**: #offline #cache #sync #pattern

---

## Optimistic Updates Pattern #pattern
**Date**: 2026-01-28
**Context**: Instant UI feedback for user actions

**What happened**: Following social media best practices - when user likes a post, immediately update UI, then call API. If API fails, rollback the change. This provides instant feedback while maintaining data consistency.

**Key lesson**: Update state first, call API second, rollback on error. Users should never wait for network round-trip for simple actions.
**Tags**: #optimistic #ux #pattern

---

## Feed Pagination Pattern #pattern
**Date**: 2026-01-28
**Context**: Infinite scroll in feed screens

**What happened**: Feed screens use ScrollController listening at 80% scroll position. When threshold reached, trigger `loadMore()`. Use cursor-based pagination (last item ID) instead of page numbers for consistency.

**Key lesson**: Load more content when user is 80% scrolled. Use cursor pagination to handle real-time insertions.
**Expected implementation**: tajiri-platform skill patterns
**Tags**: #pagination #feed #scroll #pattern

---

## Material 3 Input Pattern #pattern
**Date**: 2026-01-28
**Context**: Consistent input field styling

**What happened**: Global InputDecorationTheme in main.dart sets border radius to 12px and padding to 16px. All TextFields automatically inherit this styling.

**Key lesson**: Don't override input decoration unless necessary. Use global theme for consistency.
**Files**: `lib/main.dart:37-45`
**Tags**: #theme #inputs #material3 #pattern

---

## Service Initialization Pattern #pattern
**Date**: 2026-01-28
**Context**: Async initialization in main()

**What happened**: main() is async to initialize services before app starts. Uses `WidgetsFlutterBinding.ensureInitialized()` then initializes Hive and other services.

**Key lesson**: Always call ensureInitialized() before any async operations in main(). Initialize all services before runApp().
**Files**: `lib/main.dart:14-21`
**Tags**: #initialization #async #pattern

---

## Screen Navigation Pattern #pattern
**Date**: 2026-01-28
**Context**: Named routes vs Navigator.push

**What happened**: App uses named routes via Navigator.pushNamed(context, '/routeName'). For routes with IDs, format as '/routeName/123'. onGenerateRoute handles parsing and screen instantiation.

**Key lesson**: Prefer named routes for maintainability. Use Navigator.pushNamed('/route/id') pattern consistently.
**Tags**: #navigation #routes #pattern

---

## Widget Reusability Pattern #pattern
**Date**: 2026-01-28
**Context**: Shared widgets in lib/widgets/

**What happened**: Common UI components (buttons, cards, etc.) extracted to `lib/widgets/` for reuse across screens. Keeps screens lean and maintains consistency.

**Key lesson**: Extract repeated UI patterns to widgets/ directory. Don't duplicate widget code.
**Files**: `lib/widgets/`
**Tags**: #widgets #reusability #pattern

---

## Feature-Based Organization #pattern
**Date**: 2026-01-28
**Context**: Code organization by feature

**What happened**: Code organized by feature domain (models/, screens/, services/) rather than by layer. Each feature's models, screens, and services are in their respective directories with clear naming (e.g., post_models.dart, feed_screen.dart, api_service.dart).

**Key lesson**: Group related files by feature prefix. Makes finding and maintaining code easier.
**Files**: `lib/models/`, `lib/screens/`, `lib/services/`
**Tags**: #organization #architecture #pattern

---

## Real-Time Updates Pattern #pattern
**Date**: 2026-01-28
**Context**: Live updates for messages, notifications

**What happened**: Real-time features use WebSocket or SSE for live updates. Messages update instantly, notifications appear in real-time. Implement reconnection logic and handle offline gracefully.

**Key lesson**: Use WebSocket for bi-directional real-time (messaging), SSE for server-push (notifications). Always implement reconnection.
**Expected files**: `lib/services/message_service.dart`, `lib/services/notification_service.dart`
**Tags**: #realtime #websocket #pattern

---

## Error Handling Pattern #pattern
**Date**: 2026-01-28
**Context**: Graceful error handling

**What happened**: Show user-friendly error messages, never expose raw exceptions. Handle network errors separately (offline state). Log errors for debugging but show simple messages to users.

**Key lesson**: Catch specific exceptions (NetworkException, AuthException). Show contextual error messages. Always provide retry action.
**Tags**: #errors #ux #pattern

---

## State Management Approach #pattern
**Date**: 2026-01-28
**Context**: State management strategy for TAJIRI

**What happened**: Project structure suggests StatefulWidget with local state for simple screens. For complex state (feed, messages), implement Riverpod providers as suggested in tajiri-platform skill.

**Key lesson**: Use local state for simple screens, Riverpod for complex shared state. Follow patterns in tajiri-platform skill.
**Tags**: #state #riverpod #pattern

---

## Media Upload Pattern #pattern
**Date**: 2026-01-28
**Context**: Photo/video upload workflow

**What happened**: Media picked from gallery/camera, compressed, uploaded with progress indicator. Show preview before upload. Support multiple images. Generate thumbnails for videos.

**Key lesson**: Always compress images before upload. Show upload progress. Support cancellation. Generate thumbnails for better UX.
**Expected files**: `lib/services/media_service.dart`
**Tags**: #media #upload #pattern

---

## Backend SSH Access (safe) #procedural
**Date**: 2026-05-05
**Context**: Running Laravel commands on the backend server.

**What happened**: SSH to the Tajiri Laravel host using credentials in **local** `.env` (`TAJIRI_BACKEND_SSH_*`, gitignored). Laravel root on the server: `/var/www/tajiri.zimasystems.com`. Verified with interactive/key-only attempt, then `sshpass` + `SSHPASS` for non-interactive checks.
**Key lesson**: Do **not** store plaintext SSH passwords in the repo. Use `.env` locally or SSH keys; full steps are in `docs/BACKEND_SSH_ACCESS.md`.
**How to connect**: See **canonical doc** `docs/BACKEND_SSH_ACCESS.md` (interactive SSH, `sshpass -e` pattern, remote Artisan examples).
**Common ops** (after connecting): `cd /var/www/tajiri.zimasystems.com` → `php artisan route:list`, `php artisan tinker`, `php artisan cache:clear && php artisan config:clear`, `php artisan queue:work`.
**DB**: `sudo -u postgres psql -d tajiri`
**Notes**: `php artisan migrate` may be broken due to legacy migration conflicts; use the “drop-in PHP script + scp + ssh” pattern when needed.
**Files**: `docs/BACKEND_SSH_ACCESS.md`, `docs/ENGINEERING_PLAYBOOK.md`
**Tags**: #backend #ssh #laravel #procedural

---

## Project-wide: discover in-repo first #operating
**Date**: 2026-05-05 (updated: applies to **whole project**, not shop only)
**Context**: Any substantial feature, refactor, or roadmap (shop, feed, messages, streams, wallet, etc.).

**Key lesson**: Treat the **Flutter codebase + Laravel backend** as the primary source of truth. Search Dart (`lib/services/`, feature folders under `lib/`, `lib/models/`, `main.dart` routing) and the backend over SSH when needed (`routes/api.php`, controllers, validation, migrations) before asking the user open questions. If something is still underspecified after that, **brief** external research on how comparable social / marketplace apps solve the same problem is acceptable — then **adapt to existing TAJIRI patterns** (`setState`, `ValueNotifier` singletons where used, Hive/`LocalStorageService`, service classes, `ApiConfig`), and avoid introducing new state-management frameworks unless the user explicitly requests them (`CLAUDE.md` / engineering playbook).
**Tags**: #research #architecture #operating #procedural #discovery