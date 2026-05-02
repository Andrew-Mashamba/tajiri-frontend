# TAJIRI Engineering Playbook

> Single canonical reference. Merges and supersedes:
> `PERFORMANCE_STRATEGY.md`, `PERFORMANCE_IMPLEMENTATION_PLAN.md`,
> `SQLITE_ADOPTION_ROADMAP.md`, `super_prompt.md`.

---

## Table of Contents

- [Part I — Standing Orders](#part-i--standing-orders)
  - [Codebase conventions](#codebase-conventions)
  - [Design system](#design-system)
  - [Language rules (English + Swahili)](#language-rules-english--swahili)
  - [Tanzanian business logic](#tanzanian-business-logic)
  - [Backend infrastructure](#backend-infrastructure)
- [Part II — Audit & Fix Methodology](#part-ii--audit--fix-methodology)
  - [Deep crawl protocol (10 levels deep)](#deep-crawl-protocol-10-levels-deep)
  - [12 issue types](#12-issue-types-to-find-and-fix)
  - [Backend verification protocol](#backend-verification-protocol)
  - [Testing directives](#testing-directives)
  - [Output format](#crawl-report-output-format)
- [Part III — Performance Roadmap](#part-iii--performance-roadmap)
  - [Current state gaps](#current-state-gaps)
  - [Phase 1 — Feed cache + quick wins](#phase-1--feed-cache--quick-wins-week-1)
  - [Phase 2 — BlurHash placeholders](#phase-2--blurhash-image-placeholders-week-2)
  - [Phase 3 — Lazy tabs + service caches](#phase-3--lazy-tabs--service-caches-week-3)
  - [Phase 4 — Prefetch & pagination](#phase-4--prefetch--pagination-week-4)
  - [Phase 5 — Background sync + HTTP caching](#phase-5--background-sync--http-caching-weeks-5-6)
  - [Quick wins (< 1 hour each)](#quick-wins--1-hour-each)
  - [Priority matrix](#priority-matrix)
  - [Architecture target state](#architecture-target-state)
  - [Success metrics](#success-metrics)
- [Part IV — Storage Strategy](#part-iv--storage-strategy)
  - [Storage decision tree](#storage-decision-tree)
  - [SQLite candidates (priority-ranked)](#sqlite-candidates-priority-ranked)
  - [SQLite pattern](#sqlite-pattern)
  - [Not worth SQLite](#not-worth-sqlite)
- [Part V — References](#part-v--references)
  - [Module file paths](#module-file-paths-for-deep-crawl-entry)
  - [Files index by phase](#files-index-by-phase)
- [Part VI — Motion & Interaction](#part-vi--motion--interaction)
  - [Gesture & interaction inventory](#gesture--interaction-inventory)
  - [Motion tokens (durations + curves)](#motion-tokens-durations--curves)
  - [Animation patterns](#animation-patterns)
  - [UI manipulation rules](#ui-manipulation-rules)
    - [Inline feedback, never toasts](#inline-feedback-never-toasts)
    - [Save → pop → refresh chain](#save--pop--refresh-chain-project-wide)
    - [CRUD directives](#crud-directives-project-wide)
  - [Implementation patterns](#implementation-patterns)
  - [Performance & lifecycle](#motion-performance--lifecycle)
  - [Anti-patterns](#motion-anti-patterns)
- [Part VII — Usability & Inclusivity](#part-vii--usability--inclusivity)
  - [Highest-impact wins](#highest-impact-wins)
  - [Accessibility & inclusivity](#accessibility--inclusivity)
  - [Form input UX](#form-input-ux)
  - [Microcopy & button labels](#microcopy--button-labels)
  - [Haptic feedback](#haptic-feedback)
  - [Loading-state taxonomy](#loading-state-taxonomy)
  - [Toast / Snackbar / Dialog / Banner / Sheet](#toast--snackbar--dialog--banner--sheet)
  - [Search UX](#search-ux)
  - [Permissions & disclosure](#permissions--disclosure)
  - [One-handed reachability](#one-handed-reachability)
  - [Network state](#network-state-ui)
  - [Onboarding & empty states](#onboarding--empty-states)
  - [Undo patterns](#undo-patterns)
  - [Flutter pitfalls](#flutter-pitfalls)
  - [Microinteractions](#microinteractions)

---

# Part I — Standing Orders

## Codebase conventions

- **State management:** `setState()` in StatefulWidgets. No Provider/Bloc/Riverpod. Globals via `ValueNotifier` singletons (`ThemeNotifier`, `LanguageNotifier`, `CallState`).
- **Persistence:** Hive via `LocalStorageService` for auth tokens, user object, preferences. SQLite (sqflite) for relational/queryable data — see [Part IV](#part-iv--storage-strategy).
- **Services:** Instance-based classes in `lib/services/`. Methods take `auth token` or `userId` as parameters.
- **Auth:** `LocalStorageService.getInstance().getAuthToken()` → bearer token via `ApiConfig.authHeaders(token)`.
- **API config:** `ApiConfig.baseUrl` for HTTP, `ApiConfig.storageUrl` for media URLs. `ApiConfig.sanitizeUrl()` enforces HTTPS.
- **Models:** `factory Model.fromJson()` with null-safe parsers (`_parseInt`, `_parseDouble`, `_parseBool`).
- **Routing:** Named routes via `Navigator.pushNamed(context, '/feature/$id')`, defined in `lib/main.dart`'s `onGenerateRoute`. Pattern `/feature/:id`.
- **Real-time:** Firestore listeners (`LiveUpdateService`) for UI invalidation; Reverb WebSocket for call signaling; `flutter_webrtc` for voice/video.
- **Strings:** Bilingual via `AppStringsScope.of(context)?.someGetter ?? 'English fallback'`. See [Language rules](#language-rules-english--swahili).
- **Lint:** `package:flutter_lints/flutter.yaml` (see `analysis_options.yaml`). `flutter analyze` must pass with zero new errors before any change is considered complete.

## Design system

Single source of truth: `docs/DESIGN.md`. Highlights:

- **Palette (monochromatic):** `#1A1A1A` (primary dark), `#666666` (secondary text), `#999999` (tertiary), `#FAFAFA` (background), `#FFFFFF` (card surfaces). NO colorful buttons. Color is reserved for semantic meaning: **green** = success, **red** = error/danger, **orange** = warning, **blue** = info.
- **Typography:** System font. Weights `w700`/`w600`/`w500`/`w400`. Sizes 24-32 (hero numbers), 18-20 (page titles), 15-16 (section headings), 13-14 (body), 11-12 (captions).
- **Spacing:** Multiples of 4 — `4, 8, 12, 16, 20, 24, 32`. Standard padding 16 horizontal; section spacing 16-24.
- **Cards:** `BorderRadius.circular(12-16)`, white surface, subtle shadow (`Colors.black.withValues(alpha: 0.04-0.08)`, blurRadius 10-12). NO heavy borders — use shadow or `Colors.grey.shade100`.
- **Touch targets:** Minimum 48dp height for ALL interactive elements (accessibility requirement).
- **Text overflow:** ALWAYS `maxLines` + `TextOverflow.ellipsis` on dynamic text (usernames, titles, descriptions).
- **Icons:** Material `_rounded` variants (`Icons.home_rounded`). Sizes 18-24 inline, 28-32 feature tiles, 48-64 empty states.
- **Loading states:** `CircularProgressIndicator(strokeWidth: 2, color: Color(0xFF1A1A1A))`. Never blank screen.
- **Empty states:** Icon (64px, `grey.shade300`) + title (16px, `grey.shade500`) + subtitle (13px, `grey.shade400`). Centered.
- **Error states:** Icon + message + retry button. Never raw error strings.

### Specific beautification rules

- **List items:** Icon/avatar left (40-48px, rounded, tinted bg), title+subtitle middle, value/action right. Consistent 14px vertical padding.
- **Stat cards:** Dark `#1A1A1A` background + white text for hero metrics. Light cards for secondary stats.
- **Action buttons:** Primary = `FilledButton(backgroundColor: #1A1A1A)`, `borderRadius: 12-14`. Secondary = `OutlinedButton(foregroundColor: #1A1A1A)`. No colorful buttons except semantic.
- **NO Floating Action Buttons (FABs):** Do not use `FloatingActionButton`. Prefer a **pill button** placed at the **top right corner** of the page (inside the `AppBar` actions or directly below it, right-aligned). FABs break the monochromatic visual rhythm and are inconsistent with the TAJIRI design language.
- **Forms:** Labels above fields (not floating). `filled: true, fillColor: Colors.white`, `BorderRadius.circular(12)`.
- **Bottom sheets:** Drag handle (40x4, `grey.shade300`, centered), 16px padding, `BorderRadius.vertical(top: Radius.circular(16))`.
- **Pill buttons:** `BorderRadius.circular(20)`, `padding: EdgeInsets.symmetric(horizontal: 14, vertical: 8)`, dark bg + white text + 12px font.
- **Status badges:** `padding: EdgeInsets.symmetric(horizontal: 8, vertical: 3)`, `borderRadius: 6-8`. Background = status color @ 10% opacity, text = full color.
- **Scaffold:** `backgroundColor: Color(0xFFFAFAFA)`. AppBar: `elevation: 0, scrolledUnderElevation: 1`.
- **Lists:** `RefreshIndicator(color: Color(0xFF1A1A1A))`. Use `ListView.builder` (not `Column` w/ children) for 50+ items.

### UI/UX research directive

Before building or significantly modifying any screen:

1. **Research best apps** in that domain (invoicing → QuickBooks/FreshBooks; email → Outlook/Gmail; health → Flo/BabyCenter; fitness → Apple Fitness+/Strava).
2. **Identify 3 patterns** to adopt — information hierarchy, action placement, empty states, loading transitions, micro-interactions.
3. **Apply within our monochromatic system** — adapt colors, keep the layout patterns.
4. **Scannability:** Users find purpose + primary CTA within 2 seconds. Most important info above the fold.
5. **Progressive disclosure:** Summary first, details on tap. Expandable sections, bottom sheets, drill-downs over cramming everything onto one screen.

## Language rules (English + Swahili)

**English is the default. Swahili is secondary, toggled via `LanguageNotifier`.**

### Mechanism
`AppStrings` class (`lib/l10n/app_strings.dart`) uses ternary getters:
```dart
String get save => isSwahili ? 'Hifadhi' : 'Save';
```
Access via `AppStringsScope.of(context)` from any widget.

### Rules

1. **Default text must be English.** When `AppStrings` lacks a getter, English fallback is the second arg of the null coalesce:
   ```dart
   Text(s?.save ?? 'Save')
   ```

2. **Never hardcode Swahili-only text.** Always provide English as default:
   ```dart
   // WRONG: Text('Hifadhi')
   // OK:    Text(isSwahili ? 'Hifadhi' : 'Save')
   // BEST:  Text(AppStringsScope.of(context)?.save ?? 'Save')
   ```

3. **Tab labels and category headers** in `profile_tab_config.dart` are English. Swahili comes from `AppStrings.profileTabLabel(id)` and `AppStrings.profileTabLabelOwn(id)`.

4. **Existing Swahili-first modules** (business, doctor, pharmacy, etc.) get bilingualized when touched for other reasons — no mass find-replace.

5. **Priority order:** button labels → section titles → error messages → placeholder hints → long descriptions.

6. **Brand names stay as-is:** "TAJIRI Boost", "Duka la Dawa Tajiri", "Doctor Tajiri", "Kikoba", "Michango".

7. **`profileTabLabelOwn`** prefixes "My" only on social tabs (posts, photos, videos). Service tabs reuse `profileTabLabel`.

## Tanzanian business logic

- **Currency:** Always TZS. Format `1,500,000` (comma separators). Stats use K/M abbreviations: `1.5M`, `450K`.
- **Phone numbers:** `0712 345 678` or `+255 712 345 678`. Support both in input fields.
- **Dates:** Display `dd/MM/yyyy`. Recent items use relative: "Leo" (today), "Jana" (yesterday), "Siku 3 zilizopita".
- **Tax calculations:** Use accurate Tanzania PAYE/NSSF rates from the business module — businesses rely on these.
- **Payment:** Every payment touchpoint should support the default platform wallet Tajiri Pay (95% of users).
- **Auto-numbering:** Invoices `INV-YYYY-NNNN`, quotes `QT-YYYY-NNNN`, POs `PO-YYYY-NNNN`. Count + 1, pad to 4 digits.

## Backend infrastructure

| Item | Value |
|---|---|
| Server | `172.240.241.180` |
| SSH | `sshpass -p 'ZimaBlueApps' ssh -o StrictHostKeyChecking=no root@172.240.241.180` |
| Project path | `/var/www/tajiri.zimasystems.com` |
| Domain | `tajiri.zimasystems.com` |
| Framework | Laravel 12, PHP 8.3 |
| Database | PostgreSQL 16 (user: `postgres`, password: `postgres`, db: `tajiri`) |
| Frontend base URL | `https://tajiri.zimasystems.com/api` |
| Backend AI assistant | `./scripts/ask_backend.sh "your prompt"` (fall back to SSH if it fails) |
| Tenders API | `tenders.zimaservices.com:8010` (FastAPI + PostgreSQL + JWT) |
| Email (planned) | Mailcow — not yet deployed |

### Backend response conventions

- **Always:** `{"success": true/false, "data": ..., "message": "..."}`
- **List:** `{"success": true, "data": [...]}`
- **Create:** `{"success": true, "data": {"id": N}}`
- **Error:** `{"success": false, "message": "..."}` with appropriate HTTP status

### Backend code conventions

- Controllers: `App\Http\Controllers\Api\*` (e.g., `MyBusinessController` for all business endpoints).
- DB queries: `DB::table('table_name')` facade, NOT Eloquent — keeps controllers simple.
- Validation: `$r->validate([...])` at the start of POST/PUT methods.
- Try/catch around all logic; return `{"success": false, "message": "..."}` on failure.

### URL consistency

Frontend uses `ApiConfig.baseUrl = 'https://tajiri.zimasystems.com/api'`. All business endpoints use `/business/` (singular, NOT `/businesses/`). Verify every URL in services matches Laravel routes.

---

# Part II — Audit & Fix Methodology

> Use this when auditing/fixing a screen, building a new feature, or
> verifying changes before merge. Successor to `super_prompt.md`.

## Deep crawl protocol (10 levels deep)

Starting from any entry screen file (e.g., `lib/screens/feed/feed_screen.dart`):

**Level 1 — Map every interactive element:**
- Every `onTap`, `onPressed`, `onLongPress`, `GestureDetector`, `InkWell`, `IconButton`, `TextButton`, `ElevatedButton`, `OutlinedButton`, `PopupMenuButton`
- Every `Navigator.push`, `Navigator.pushNamed`, `showModalBottomSheet`, `showDialog`, `showMenu`
- Every API/service call (`_service.methodName()`)
- Every callback passed to child widgets

For each, record what it does, where it navigates, what file/widget opens, what service method it calls.

**Levels 2-10:** Read each new destination from the previous level. Same full analysis. Continue until terminal pages or Level 10.

**Deduplicate:** If a destination was already crawled (e.g. ProfileScreen at L2 and L3), skip on subsequent encounters.

## 12 issue types to find and fix

| # | Type | What to look for | How to fix |
|---|---|---|---|
| 1 | **Empty handlers** | `onTap: () {}`, `onPressed: () {}`, callbacks doing nothing | Implement using existing patterns from sibling screens. Verify the service method exists; add if missing. |
| 2 | **Stubs / placeholders** | "coming soon" snackbars, `// TODO`-only bodies, placeholder text instead of real content | Build the feature using existing services + backend APIs. |
| 3 | **Broken navigation** | Routes not registered in `main.dart` `onGenerateRoute`; wrong path patterns; arguments via `arguments:` instead of path segments | Read `main.dart` to find correct pattern; fix the caller. |
| 4 | **Missing child callbacks** | `PostCard`, `PostGridCell`, `CommentTile` rendered without required callbacks (`onLike`, `onComment`, `onShare`, `onSave`, `onUserTap`, `onHashtagTap`, `onMentionTap`, `onSubscribe`, `onMenuTap`, `onThreadTap`, `onReaction`) | Search codebase for the same widget wired up correctly; copy the pattern. |
| 5 | **Compile errors** | `widget.x` in `StatelessWidget`; wrong variable names; missing imports; type mismatches; ambiguous imports | Add imports (use `hide` for collisions); fix `widget.x` → field; correct types. |
| 6 | **Logic bugs** | Init guards preventing first load (e.g., `bool _loading = true` + `if (_loading) return;` in load method called from `initState`); wrong assignment order; state not updating | Fix root cause — initialization, variable order, or state update. No workarounds. |
| 7 | **Misleading UX** | Success feedback ("Done!", "Sent!", "Blocked!") without an API call; confirmation dialogs that confirm but take no action | Wire success messages to actual successful API responses. Make confirmations actually act. |
| 8 | **Dead pages** | Empty/loading state forever — load method never fires, or calls a non-existent service method | Fix the load method. Add the missing service call. Wire data flow. |
| 9 | **Unimplemented features** | Visible buttons/icons/tabs rendered but inert | Implement or remove. |
| 10 | **Missing error handling** | API calls without try/catch, no loading state, no error feedback | Wrap in try/catch; add loading flag; surface failures inline on the current screen with a retry affordance — never a SnackBar (see *Inline feedback, never toasts*). |
| 11 | **Double titles / Double AppBars** | Pages rendered inside `_ProfileTabPage` (via the profile tab grid) already have a parent `AppBar` with the tab title and back button. If the page ALSO has its own `Scaffold` with `appBar:`, the user sees **two** titles and **two** back buttons stacked. | When a page is used as tab content inside `_ProfileTabPage`, it must NOT have its own `AppBar`. Remove `appBar:` from the inner `Scaffold`, or replace `Scaffold` with just the body widget. Applies to ALL module home pages opened from profile tabs. |
| 12 | **Swahili-only text** | Hardcoded Swahili without an English alternative | Use `AppStringsScope.of(context)?.getter ?? 'English fallback'` or inline ternary on `isSwahili`. Check page titles, section headers, button labels, inline error banners, empty states, error messages, form labels, placeholders. |

## Backend verification protocol

Every service call MUST have a working backend endpoint. When you hit a service method, verify the chain: Flutter service → HTTP call → Laravel route → Controller method → DB table.

### Verify a route exists
```bash
sshpass -p "ZimaBlueApps" ssh -o StrictHostKeyChecking=no root@172.240.241.180
cd /var/www/tajiri.zimasystems.com
php artisan route:list --path=business    # or whatever path prefix
```

### Test with curl
```bash
curl -s "https://tajiri.zimasystems.com/api/business?user_id=38" | python3 -m json.tool
```

### Verify table columns
```bash
php artisan tinker --execute="echo json_encode(Schema::getColumnListing('table_name'));"
```

### When the endpoint is missing — create it

**Step 1 — Migration:**
```bash
php artisan tinker --execute="
Schema::create('table_name', function (\$t) {
    \$t->id();
    \$t->foreignId('user_business_id')->constrained()->cascadeOnDelete();
    \$t->timestamps();
});
echo 'Table created';
"
```

**Step 2 — Add controller method** (`app/Http/Controllers/Api/MyBusinessController.php` or appropriate). Use `DB::table()`, follow existing method patterns in the same controller.

**Step 3 — Register route** (`routes/api.php`):
```php
Route::prefix('business')->controller(MyBusinessController::class)->group(function () {
    Route::get('/{businessId}/feature', 'list');
    Route::post('/feature', 'create');
    // ...
});
```

**Step 4 — Test:**
```bash
curl -s "https://tajiri.zimasystems.com/api/new-endpoint" | python3 -m json.tool
```

## Testing directives

After fixing any feature, verify it actually works end-to-end — not just that it compiles.

### Frontend

**Static analysis (mandatory):**
```bash
flutter analyze [every_modified_file]
```
Zero errors required. Only pre-existing `info`-level warnings acceptable.

**Widget structure:**
- Scaffold has `backgroundColor: Color(0xFFFAFAFA)` (or equivalent).
- AppBar has `elevation: 0, scrolledUnderElevation: 1`.
- Lists have `RefreshIndicator(color: Color(0xFF1A1A1A))`.
- Forms have `_formKey` with validation.
- Async buttons show loading spinner and are disabled during operation.

**State / lifecycle:**
- `setState()` only called when `mounted == true` — check after every async gap.
- Controllers disposed in `dispose()`.
- Listeners removed in `dispose()`.
- No leaks from un-cancelled subscriptions.

### Backend

**Endpoint coverage with curl:**
```bash
# List
curl -s "https://tajiri.zimasystems.com/api/business/{businessId}/{feature}" | python3 -m json.tool

# Create
curl -s -X POST "https://tajiri.zimasystems.com/api/business/{feature}" \
  -H "Content-Type: application/json" \
  -d '{"field": "value"}' | python3 -m json.tool

# Verify response is {"success": true, "data": ...}
```

**Error cases:**
```bash
# Missing required field → expect {"success": false, "message": "..."}
curl -s -X POST "..." -H "Content-Type: application/json" -d '{}' | python3 -m json.tool

# Non-existent resource → expect 404 or {"success": false}
curl -s ".../99999/{feature}" | python3 -m json.tool
```

**Data integrity:** Create → Read → verify match. Update → Read → verify applied. Delete → Read → verify gone.

### Integration (cross-module)

| Integration | Test |
|---|---|
| Invoice → Email | Create invoice → tap email button → compose screen pre-fills correctly |
| Debt → Reminder | Create debt → tap remind → SMS/WhatsApp URI opens with correct message |
| Quote → Invoice | Create quote → convert → matching data |
| Tender → Documents | Apply → document attachment sheet shows business docs |
| Payroll → Tax | Run payroll → tax page shows matching PAYE/NSSF totals |
| Expense → Budget | Add expense → appears in expense list with correct category/amount |

### Performance check

- Screens load within 2 seconds on stable connection.
- Lists with 50+ items use `ListView.builder` (not `Column` w/ children).
- Images use `CachedMediaImage` (not raw `Image.network`).
- Large datasets use pagination — infinite scroll w/ 70% prefetch.

## Cross-module wiring

Before marking a screen complete, ask:

1. **Can this data be useful elsewhere?** (business expenses → personal budget; doctor prescriptions → pharmacy orders; invoice data → tax calculations)
2. **Can the user take action from here?** (customer page → call/message/view profile; invoice → send via email; debt → send reminder via WhatsApp)
3. **Are there contextual upsells?** (after doctor visit → suggest health insurance; after loan approval → suggest credit life insurance; after business registration → suggest business email)

## Data integrity rules

- **Validate inputs at the UI** before API calls. Inline errors only — no SnackBars (see *Inline feedback, never toasts* in Part VI).
- **Optimistic updates** for non-critical actions (like/unlike, mark read, toggle). Revert on failure.
- **Confirm destructive actions** with `AlertDialog` before: delete, cancel, unfriend, unfollow, logout.
- **Loading on buttons** during API calls — disable + spinner inside button. Never let users double-tap submit.
- **Pagination:** infinite scroll, 70% prefetch threshold. Bottom loading indicator.

## Crawl report output format

For each level:

```
## Level N: [ScreenName] ([file_path])

### Interactive Elements
1. [Element] → [Destination/Action] — [Status: OK / ISSUE]
2. ...

### Issues Found & Fixed
| # | Line | Type | Description | Fix Applied |
|---|------|------|-------------|-------------|
| 1 | 142  | Empty handler | `onComment: () {}` does nothing | Implemented: opens CommentBottomSheet |
| 2 | 305  | Missing callback | PostCard missing `onHashtagTap` | Added: navigates to HashtagScreen |

### Navigation Links → Level N+1
- [Element] → [DestinationScreen] ([file_path])
```

Final summary:

```
## Summary

### Files Modified
- [file_path] — [description]

### Backend Changes (if any)
- [endpoint created/modified]

### Total Issues: X found, Y fixed
| Severity | Count |
|----------|-------|
| Blocking | N     |
| Moderate | N     |
| Minor    | N     |
```

---

# Part III — Performance Roadmap

> Goal: TAJIRI feels as instant as Instagram. Eliminate spinners, grey
> boxes, redundant API calls, and bandwidth waste.

## Current state gaps

### What works
- **Media caching** — `MediaCacheManager` (30-day disk cache, 200 files) + `CachedNetworkImage` for images.
- **Video/Audio prefetching** — YouTube-style priority queue (±2 clips, ±3 audio tracks).
- **Feed media preloading** — 1500px viewport buffer.
- **Optimistic UI** — like, reaction, save update immediately, revert on failure.
- **Message caching** — `MessageCacheService` stores 500 messages per conversation in Hive.
- **Profile tab persistence** — tab order/enabled state survives restarts.
- **Profile in-memory cache** — 5-min TTL, max 50 entries, with `invalidate(userId)` after edits (added 2026-05-01).

### What's broken

| Problem | Impact | Root cause |
|---|---|---|
| Feed shows spinner on every app open | **Critical** — feels slow vs Instagram | No feed persistence to disk; in-memory cache only |
| All 5 tabs load simultaneously on login | Wasted bandwidth/CPU; delays visible tab | `IndexedStack` builds all children eagerly |
| Shop loads 4 parallel API calls every mount | Network churn | No product/category cache |
| Images show grey box + spinner while loading | Unpolished | No BlurHash placeholders |
| No background feed refresh | Cache always cold on app open | No `WorkManager`/`BGTaskScheduler` |
| No HTTP-level caching (ETag/304) | Every request downloads full response | No `If-None-Match` |
| Search has no history/suggestion cache | Users re-type queries | No persistence |
| Stories/Friends load fresh every time | Unnecessary API calls | No staleness check |
| NotificationsScreen is a stub | Missing feature | Unimplemented |

## Phase 1 — Feed cache + quick wins (Week 1)
**Goal: Eliminate the loading spinner for returning users. Single most impactful change. Instagram, TikTok, Twitter all do this.**

### 1.1 Complete `Post.toJson()` — prerequisite for caching
**File:** `lib/models/post_models.dart`

`Post.toJson()` (line 294) is incomplete — missing `user`, `media`, `hashtags`, `isLiked`, `isSaved`, `createdAt`, `originalPost`, and 15+ other fields present in `fromJson`. Add them all.

Add `toJson()` to three classes lacking it:
- `PostMedia` (~line 726): id, postId, mediaType, filePath, thumbnailPath, dominantColor, width, height, duration, order
- `PostUser` (~line 845): id, firstName, lastName, username, profilePhotoPath, isFollowing
- `Hashtag` (~line 580): id, name, postsCount, isTrending

### 1.2 New `FeedCacheService`
**File:** `lib/services/feed_cache_service.dart` (NEW)

Follow `MessageCacheService` pattern (singleton, `Box<String>`, JSON strings):
- Hive box: `'feed_cache'`
- `savePosts(feedType, List<Post>)` → `jsonEncode(posts.map(toJson))`, key `'feed_$feedType'`
- `getPosts(feedType)` → decode JSON, `Post.fromJson()` each
- `getLastFetchTime(feedType)` → timestamp from meta key
- `clear()` → called on logout
- Per feed type: page 1 only, 20-100 posts. 3 types × 100 = ~300KB max.
- TTL: display stale immediately, mark as needing refresh after 5 min.

### 1.3 Modify FeedScreen for stale-while-revalidate
**File:** `lib/screens/feed/feed_screen.dart`

Change `_loadFeed()` (line 603):
1. Load cached posts from `FeedCacheService` → `setState` immediately (0ms).
2. Fire `ContentEngineService.feed()` in parallel.
3. On API success: compare new post IDs with displayed.
4. If different → show "New posts" pill at top (don't disrupt scroll).
5. On pill tap → swap in new data, scroll to top.
6. Save fresh posts to cache.

New state fields: `bool _hasNewPosts`, `List<Post>? _pendingPosts`.

### 1.4 Clear cache on logout
**File:** `lib/services/auth_service.dart` — Add `FeedCacheService.instance.clear()` and `ProfileService.clearCache()` in `_performLocalLogout()`.

### 1.5 Quick wins (< 1 hour each — see also [Quick wins](#quick-wins--1-hour-each))

| Fix | File | Line | Change |
|---|---|---|---|
| Bump media cache | `lib/services/media_cache_service.dart` | 18 | `maxNrOfCacheObjects: 200` → `1000` |
| Earlier scroll trigger | `lib/screens/feed/feed_screen.dart` | 531 | `maxScrollExtent - 500` → `- 1000` |
| Fix FriendsScreen rebuild | `lib/screens/home/home_screen.dart` | 110 | Use `_screens[2]` instead of `new FriendsScreen(...)` on every build |

### Verification
- Cold-start app → feed renders instantly from cache (no spinner).
- Fresh data arrives → "New posts" pill appears.
- `Post.fromJson(post.toJson())` round-trip unit test for posts with media, user, hashtags.
- `flutter analyze` passes.

## Phase 2 — BlurHash image placeholders (Week 2)
**Goal: Replace grey boxes with beautiful blurred previews.**

### 2.1 Backend — BlurHash generation

Server: `172.240.241.180` (`/var/www/tajiri.zimasystems.com`)

1. `composer require kornrunner/php-blurhash`
2. Migration: add `blurhash VARCHAR(50) NULLABLE` to `post_media` (after `dominant_color`).
3. Migration: add `avatar_blurhash VARCHAR(50) NULLABLE` to `user_profiles` (after `profile_photo_path`).
4. `ImageProcessingService` (`app/Services/ImageProcessingService.php`): after `extractDominantColor()`, resize to 32×32, compute `Blurhash::encode($pixels, 4, 3)`, save to `$media->blurhash`.
5. Backfill artisan command: process existing `post_media` rows missing blurhash (batch 100).

### 2.2 Backend — Fix V2 feed hydration (CRITICAL)
V2 feed `hydrate()` calls `toArray()` WITHOUT eager loading `media`. Means `dominant_color`, `blurhash`, `thumbnail_path` are NOT in v2 feed responses.

**Fix:** add `->load('media')` in the hydration step.

### 2.3 Frontend — BlurHash rendering

1. `pubspec.yaml`: add `flutter_blurhash: ^1.2.1`.
2. `PostMedia` model: add `String? blurhash` to constructor, `fromJson`, `toJson`.
3. `CachedMediaImage` (`lib/widgets/cached_media_image.dart`):
   - Add `String? blurhash` and `String? dominantColor` params.
   - In `_buildPlaceholder()`: blurhash non-null → `BlurHash(hash: blurhash)`. Else if `dominantColor` → `Container(color: parsedColor)`. Else → grey box.
4. `PostCard` / media widgets: pass `media.blurhash` and `media.dominantColor`.

### 2.4 Fix CachedAvatarImage memory leak
**File:** `lib/widgets/cached_media_image.dart` (~line 135)

Add `memCacheWidth` and `memCacheHeight`:
```dart
memCacheWidth: (radius * 6).toInt(),  // 3x pixel ratio
memCacheHeight: (radius * 6).toInt(),
```

### Verification
- Upload new image → API response includes `blurhash`.
- Feed: blurred preview shows instantly, resolves to full image.
- Backfill → existing posts get blurhash.
- DevTools: avatar memory usage decreases.

## Phase 3 — Lazy tabs + service caches (Week 3)
**Goal: Cut startup API calls from 15+ to 3-5.**

### 3.1 New `LazyIndexedStack` widget
**File:** `lib/widgets/lazy_indexed_stack.dart` (NEW)

```dart
class LazyIndexedStack extends StatefulWidget {
  final int index;
  final List<Widget Function()> builders;
}
// Tracks Set<int> _activatedIndices.
// Only builds children that have been selected at least once.
```

### 3.2 Apply in HomeScreen
**File:** `lib/screens/home/home_screen.dart`

Replace `IndexedStack` (line 105) with `LazyIndexedStack`. Convert `_screens` list to builder functions. On login, only Feed builds + fires APIs.

Also: `FriendsScreen` at line 110 creates a new instance every `setState`. Use `_screens[2]` from cached list instead.

### 3.3 ProfileService in-memory cache
**File:** `lib/services/profile_service.dart` ✅ DONE

5-min TTL, max 50 entries, LRU eviction, `invalidate(userId)` for post-edit, `clearCache()` on logout. (Implemented 2026-05-01.)

### 3.4 ShopService category cache
**File:** `lib/services/shop_service.dart`

Categories are near-static. Static cache w/ 1-hour TTL:
```dart
static List<ShopCategory>? _categoriesCache;
static DateTime? _categoriesFetchedAt;
```

### Verification
- Login → only Feed tab fires APIs (network panel).
- Tap Messages tab → loads on first visit, instant on return.
- Same profile twice → second instant (debug print confirms cache hit).
- Shop categories → no re-fetch on tab return.

## Phase 4 — Prefetch & pagination (Week 4)
**Goal: Eliminate "loading more" spinners, smoother scroll.**

### 4.1 Feed next-page prefetch
**File:** `lib/screens/feed/feed_screen.dart`

In `_onScroll()` (line 526): at 60% scroll depth, prefetch next page in background. Store in `_prefetchedNextPage`. When `_loadMore()` fires, use prefetched data instantly.

```dart
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

### 4.2 Reduce media preload stagger
**File:** `lib/services/media_cache_service.dart` (~line 162)

`Duration(milliseconds: 100)` → `Duration(milliseconds: 30)` in `preloadMediaList()`.

### 4.3 Conversation list cache
**File:** `lib/services/conversation_cache_service.dart` (NEW)

Hive-backed cache following `MessageCacheService` pattern. Show cached conversations immediately, refresh in background. Requires `Conversation.toJson()` (verify/add).

**File:** `lib/screens/messages/conversations_screen.dart` — load from cache first; refresh on `MessagesUpdateEvent` without spinner.

### 4.4 Story thumbnail prefetch
**File:** `lib/screens/feed/feed_screen.dart`

After `_loadStories()` completes: `ImagePreloader.precacheImages()` for first 5-10 story thumbnail URLs.

### Verification
- Slow scroll → next page loads with zero delay at bottom.
- Messages tab opens instantly on return visits.
- Story thumbnails appear without flicker.

## Phase 5 — Background sync + HTTP caching (Weeks 5-6)
**Goal: Cache is warm before user opens app; less bandwidth.**

### 5.1 Background feed refresh

1. `pubspec.yaml`: add `workmanager: ^0.5.2`
2. **New file:** `lib/services/background_sync_service.dart` — register periodic task (15 min on iOS minimum), fetch feed page 1, write to `FeedCacheService`.
3. `lib/main.dart`: call `BackgroundSyncService.initialize()` after Hive init.

```dart
Workmanager().registerPeriodicTask(
  'feedRefresh',
  'refreshFeed',
  frequency: Duration(minutes: 15),
  constraints: Constraints(networkType: NetworkType.connected),
);
```

### 5.2 Backend — ETag middleware
Server: create `app/Http/Middleware/ETagMiddleware.php`
- Compute `md5` of response body, set `ETag` header.
- Check `If-None-Match` → return 304 if matches.
- Apply to: `/v2/feed`, `/users/{id}`, `/shop/categories`.

### 5.3 Frontend — ETag client
**File:** `lib/services/etag_cache_service.dart` (NEW)

Hive box `'etag_cache'` storing ETags + response bodies per URL. Sends `If-None-Match` header, uses cached body on 304.

`ApiConfig.authHeaders()`:
```dart
static Map<String, String> authHeaders(String token, {String? etag}) => {
  ...headers,
  'Authorization': 'Bearer $token',
  if (etag != null) 'If-None-Match': etag,
};
```

Integrate into `ContentEngineService.feed()` and `ProfileService.getProfile()` first.

### 5.4 Search history
**File:** `lib/services/search_history_service.dart` (NEW)

Hive-backed list, max 20 queries. Show as suggestion chips in `universal_search_screen.dart` when query is empty.

### Verification
- Kill app, wait 15 min, reopen → feed shows background-refreshed content.
- Network tab shows 304 responses on repeated profile/category loads.
- Search screen shows recent queries as chips.

## Quick wins (< 1 hour each)

1. **Bump `MediaCacheManager.maxNrOfCacheObjects`** from 200 → 1000 (current limit is too low for a feed-heavy app).
2. **Add `Gapless` playback** — when video clip ends, start next without black frame.
3. **Reduce scroll trigger** from 500px to 1000px for earlier pagination fetch.
4. **Cache conversation unread count** in Hive to show correct badge without API call on startup.
5. **Remove duplicate `FcmService.sendTokenToBackend`** — currently called in both `HomeScreen.initState` and login flow.

## Priority matrix

| Phase | Change | Effort | Impact | Dependency |
|---|---|---|---|---|
| **1** | Feed cache (stale-while-revalidate) | 2 days | **Critical** | None |
| **2** | BlurHash placeholders | 3 days | **High** | Backend migration |
| **3a** | Lazy tab loading | 0.5 day | **High** | None |
| **3b** | Profile cache | 1 day | Medium | None ✅ DONE |
| **3c** | Shop cache | 1 day | Medium | None |
| **4a** | Feed page prefetch | 1 day | Medium | Phase 1 |
| **4b** | Story thumbnail prefetch | 0.5 day | Low | None |
| **4c** | Conversation list cache | 1 day | Medium | None |
| **5a** | Background sync | 2 days | Medium | Phase 1 |
| **5b** | ETag support | 2 days | Medium | Backend |
| **5c** | Search history | 0.5 day | Low | None |

### Parallel execution

```
Week 1: Phase 1 (frontend) + Phase 2.1-2.2 (backend BlurHash + hydration fix)
Week 2: Phase 2.3-2.4 (frontend BlurHash) + Phase 3 (lazy tabs + caches)
Week 3: Phase 4 (prefetch + conversation cache)
Week 4: Phase 5 (background sync + ETag)
```

Phases 1 and 3 have no dependencies. Phase 2 frontend depends on Phase 2 backend. Phase 4 depends on Phase 1's `FeedCacheService`. Phase 5 depends on Phases 1 + 2 backend.

## Architecture target state

```
App Opens (returning user)
  ├── Frame 0:   Cached feed from Hive (instant)
  ├── Frame 1:   BlurHash placeholders for images not in disk cache
  ├── Frame 2:   Cached images from MediaCacheManager (disk)
  ├── Background: API fetch for fresh feed
  ├── Background: Prefetch next page
  └── 2-5s later: Fresh data diffed in silently

App Opens (first install)
  ├── Frame 0:    Skeleton shimmer screen
  ├── Frame 1-3:  API fetch completes, feed renders
  └── Frame 4+:   Images load BlurHash → thumbnail → full-res

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

## Success metrics

| Metric | Before | Target | How to measure |
|---|---|---|---|
| Time to first post (returning user) | 2-5s | <100ms | EventTracking timestamp from initState to first post render |
| Feed API calls per session | 5-10 (every tab switch) | 1-2 (initial + refresh) | Server-side analytics |
| Image placeholder duration | 500ms-2s (grey box) | 0ms (BlurHash instant) | Visual inspection |
| Simultaneous API calls on startup | 15+ (all tabs) | 3-5 (feed only) | Network profiler |
| App storage for cache | ~0 MB | 10-50 MB | Device storage settings |
| Feed cache hit rate | 0% | >80% (returning users) | `FeedCacheService` logging |

---

# Part IV — Storage Strategy

## Storage decision tree

```
Need to store data on device?
├─ Auth token, user object, simple preferences?
│   → Hive (LocalStorageService)
├─ Small payload, OK to refetch from API on staleness, no offline browse?
│   → In-memory cache (Map<K, (Value, DateTime)>) with TTL
│   Examples: ProfileService (5 min, 50 entries), ShopService categories (1 hour)
├─ Page-1 cache for feed/list with JSON-shaped objects, no relational queries?
│   → Hive box of JSON strings
│   Examples: FeedCacheService, MessageCacheService, ConversationCacheService
├─ Relational, large dataset, FTS or filtered queries, must work offline?
│   → SQLite (sqflite) — see candidates below
└─ Media files (images, video, audio)?
    → File system (CachedNetworkImage, MediaCacheManager)
```

## SQLite candidates (priority-ranked)

### High impact (do first)

| # | Feature | Current state | Why SQLite | Offline need |
|---|---|---|---|---|
| 1 | **Wallet Transactions** | API fetch every open, paginated | Instant history, local filtering by type/status, immutable past data | High — users check balance/history offline |
| 2 | **Notifications** | API fetch every open, paginated | Already has growing history + read/unread state, perfect for local-first | High — scroll history offline |
| 3 | **Shop Products & Cart** | API fetch + 1hr in-memory category cache; cart is API round-trip every time | Local product search (FTS5), persistent cart survives restart, offline browse | High — commerce must work offline |

### Medium-high impact

| # | Feature | Current state | Why SQLite |
|---|---|---|---|
| 4 | **Friends List & Requests** | Paginated API, no cache | Pre-cache all friends for instant browse; local name search; offline request status |
| 5 | **Clips Feed** | Paginated API (10/page) | Cache clip metadata for instant scroll restore; track downloaded videos; prefetch |

### Medium impact

| # | Feature | Current state | Why SQLite |
|---|---|---|---|
| 6 | **Music Library** | Paginated API per category | Local FTS search (artist/title/genre); offline playlist management; listening history |
| 7 | **Events** | Paginated API, filterable | Local time-based queries (upcoming only); offline RSVP state; category filter |
| 8 | **Groups & Posts** | Paginated API per group | Cache group list + per-group posts; offline membership view |
| 9 | **People Search** | Hive cache (40-item limit) | Upgrade to unlimited cache; local FTS on names/interests; offline filter |
| 10 | **Saved Posts** | Paginated API | Offline browse of user's saved collection; local FTS on content |

### Recommended implementation order

1. **Wallet + Notifications + Shop** (commerce critical, highest user-facing impact).
2. **Friends + Clips** (social core).
3. **Music + Events + Groups** (feature completeness).
4. **People Search + Saved Posts** (polish).

## SQLite pattern

All SQLite databases follow the same pattern as `MessageDatabase` (`lib/services/message_database.dart`):

- **Singleton** database service with lazy initialization.
- **`json_data` TEXT column** on each table for flexible field storage and lossless reconstruction.
- **Indexed columns** for fast queries (foreign keys, timestamps, status enums, starred/pinned flags).
- **`sync_state` table** to track `last_synced_id` and `last_sync_timestamp` per entity.
- **Pending queue table** for offline mutations (create/update/delete) with retry count.
- **Delta sync service** — fetch only changed records since last checkpoint.
- **Local-first UI** — load from SQLite instantly, sync from server in background.

## Not worth SQLite

| Feature | Why not |
|---|---|
| Tea/Gossip chat | Streaming/ephemeral; Messages table handles it |
| Real-time (WebSocket/FCM) | Event-driven, not relational |
| Media files | File system + media cache, not relational |
| **User profile** | Small payload; in-memory cache w/ 5-min TTL is sufficient — see `ProfileService` |
| Content engine feed | ETag cache works well; ML rankings change constantly |

---

# Part V — References

## Module file paths (for deep crawl entry)

Common entry points to launch the deep crawl protocol:

```
lib/screens/feed/feed_screen.dart
lib/screens/feed/full_screen_post_viewer_screen.dart
lib/screens/messages/conversations_screen.dart
lib/screens/shop/shop_screen.dart
lib/screens/wallet/wallet_screen.dart
lib/screens/settings/settings_screen.dart
lib/screens/profile/profile_screen.dart
lib/screens/clips/clips_screen.dart
lib/screens/groups/groups_screen.dart
lib/screens/music/music_player_sheet.dart

lib/business/pages/business_home_page.dart
lib/doctor/pages/doctor_home_page.dart
lib/pharmacy/pages/pharmacy_home_page.dart
lib/insurance/pages/insurance_home_page.dart
lib/fitness/pages/fitness_home_page.dart
lib/my_circle/pages/my_circle_home_page.dart
lib/my_baby/pages/my_baby_home_page.dart
lib/my_family/pages/family_home_page.dart
lib/skincare/pages/skincare_home_page.dart
lib/hair_nails/pages/hair_nails_home_page.dart
lib/investments/pages/investments_home_page.dart
lib/loans/pages/loans_home_page.dart
lib/my_wallet/pages/wallet_home_page.dart
lib/tenders/pages/tenders_home_page.dart
```

## Files index by phase

### New files (frontend)

| File | Phase | Purpose |
|---|---|---|
| `lib/services/feed_cache_service.dart` | 1 | Hive-backed feed persistence |
| `lib/widgets/lazy_indexed_stack.dart` | 3 | Lazy tab builder |
| `lib/services/conversation_cache_service.dart` | 4 | Hive-backed conversation list cache |
| `lib/services/background_sync_service.dart` | 5 | WorkManager background refresh |
| `lib/services/etag_cache_service.dart` | 5 | ETag HTTP cache client |
| `lib/services/search_history_service.dart` | 5 | Search query persistence |

### Modified files (frontend)

| File | Phase | Change |
|---|---|---|
| `lib/models/post_models.dart` | 1, 2 | Complete `toJson()`, add `blurhash` field |
| `lib/screens/feed/feed_screen.dart` | 1, 4 | Stale-while-revalidate, prefetch, story prefetch |
| `lib/services/auth_service.dart` | 1 | Clear feed + profile cache on logout |
| `lib/services/media_cache_service.dart` | 1, 4 | Bump limit to 1000, reduce stagger |
| `lib/screens/home/home_screen.dart` | 1, 3 | Fix FriendsScreen rebuild, lazy tabs |
| `lib/widgets/cached_media_image.dart` | 2 | BlurHash placeholder, avatar memCache fix |
| `lib/services/profile_service.dart` | 3 | In-memory LRU cache + invalidate ✅ |
| `lib/services/shop_service.dart` | 3 | Category cache |
| `lib/screens/messages/conversations_screen.dart` | 4 | Cache-first loading |
| `lib/screens/search/universal_search_screen.dart` | 5 | Search history |
| `pubspec.yaml` | 2, 5 | `flutter_blurhash`, `workmanager` |
| `lib/main.dart` | 5 | Background sync init |

### Backend changes

| Change | Phase | Location |
|---|---|---|
| `composer require kornrunner/php-blurhash` | 2 | Server |
| Migration: `post_media.blurhash` column | 2 | Server |
| Migration: `user_profiles.avatar_blurhash` column | 2 | Server |
| `ImageProcessingService` BlurHash compute | 2 | `app/Services/ImageProcessingService.php` |
| Backfill artisan command | 2 | Server |
| Fix V2 feed hydration to include media relations | 2 | `ServingPipelineService` or `FeedController` |
| `ETagMiddleware` | 5 | `app/Http/Middleware/ETagMiddleware.php` |
| Register ETag middleware for API routes | 5 | `Kernel.php` or route group |

---

---

# Part VI — Motion & Interaction

> Motion is part of the design system. Interactions should feel deliberate
> — fast where the user is in control, slow enough to be readable when
> something appears or rearranges. The rules below are the canonical set
> for new TAJIRI UI work.

## Gesture & interaction inventory

Flutter has no DOM events. Map web/JS interactions to their Flutter
equivalents — both for translating prior knowledge and for picking the
right widget when wiring an interaction.

### Pointer & touch

| Web concept | Flutter equivalent | Notes |
|---|---|---|
| `click` | `InkWell.onTap`, `GestureDetector.onTap`, `IconButton.onPressed`, `*.onPressed` | Prefer `InkWell` for ripple feedback; `GestureDetector` if no Material context. |
| `dblclick` | `GestureDetector.onDoubleTap` | Like-on-double-tap is a feed pattern. |
| `mousedown` / `pointerdown` | `GestureDetector.onTapDown`, `onPanDown` | Use to capture press position for ripples or context menus. |
| `mouseup` / `pointerup` | `GestureDetector.onTapUp` | Pair with `onTapDown` to compute drag deltas. |
| `mousemove` / `pointermove` | `GestureDetector.onPanUpdate`, `Listener.onPointerMove` | `Listener` exposes raw pointer events without gesture arbitration. |
| `mouseenter` / `mouseleave` (hover) | `MouseRegion.onEnter` / `onExit` | Web/desktop only — guard with `kIsWeb` or check platform. |
| `contextmenu` | `GestureDetector.onLongPress` (mobile), `MenuAnchor` (desktop) | Long-press is the mobile equivalent; show a `showMenu` or context popup. |
| `wheel` | `Listener.onPointerSignal` (handles `PointerScrollEvent`) | For custom scroll handling on web/desktop. |
| `touchstart` / `touchmove` / `touchend` | `GestureDetector` family + `*Drag*` callbacks | Flutter abstracts mouse/touch into pointer events. |
| `dragstart` / `drop` (drag-and-drop) | `Draggable` + `DragTarget` | Use for reorderable lists, kanban-style boards. |

### Keyboard & focus

| Web concept | Flutter equivalent |
|---|---|
| `keydown` / `keyup` | `Focus(onKeyEvent: ...)`, `RawKeyboardListener`, or `Shortcuts` + `Actions` for app-level bindings. |
| `keypress` (deprecated) | Don't use — use `onKeyEvent`. |
| `focus` / `blur` | `FocusNode.addListener`, `Focus(autofocus: true)`. |
| `focusin` / `focusout` | `Focus(onFocusChange: ...)`. |

### Forms & input

| Web concept | Flutter equivalent |
|---|---|
| `input` (every keystroke) | `TextEditingController.addListener` or `TextField.onChanged`. |
| `change` (committed) | `TextField.onSubmitted`, dropdown `onChanged`, switch `onChanged`. |
| `submit` | `TextField.onSubmitted`, `Form.onChanged`/`_formKey.currentState!.validate()`. |
| `invalid` | `Form` validators. Show inline errors via `validator:` returning a string. |
| `select` (text selection) | `TextField.onChanged` + `controller.selection`. |

### Clipboard

| Web | Flutter |
|---|---|
| `copy` / `cut` / `paste` | `Clipboard.setData(ClipboardData(text: '...'))`, `Clipboard.getData('text/plain')`. `TextField` handles all three natively in its context menu. |

### Window / lifecycle

| Web | Flutter |
|---|---|
| `load` / `DOMContentLoaded` | `initState`, `WidgetsBinding.instance.addPostFrameCallback`. |
| `beforeunload` / `unload` | `WidgetsBindingObserver.didChangeAppLifecycleState` (paused/detached), or `dispose`. |
| `resize` | `LayoutBuilder`, `MediaQuery`, `WidgetsBindingObserver.didChangeMetrics`. |
| `scroll` | `ScrollController.addListener`, `NotificationListener<ScrollNotification>`. |
| `online` / `offline` | `connectivity_plus` package (`Connectivity().onConnectivityChanged`). |
| `hashchange` / `popstate` | `Navigator.didPop` / `RouteObserver`. |
| `storage` | Hive listeners (`box.watch()`), or your own `ValueNotifier`. |
| `visibilitychange` | `WidgetsBindingObserver.didChangeAppLifecycleState`. Pause video/audio when `paused`. |

### Media

| Web | Flutter |
|---|---|
| `play` / `pause` | `VideoPlayerController.value.isPlaying`, `AudioPlayer` state stream. |
| `ended` | `*.addListener` checking `position == duration`. |
| `timeupdate` / `seeking` | Player controller's value stream. |

### Network & fetch

Web `fetch`/`XHR` events (`abort`, `timeout`, `progress`, `loadstart`, `loadend`) map to Dart `http`/`dio`:
- Aborts: cancel via `http.Client().close()` or `dio.CancelToken`.
- Timeouts: `.timeout(Duration)`.
- Progress: `dio.onSendProgress` / `onReceiveProgress`.

### Best-practice translations

- **Prefer `onChanged` (input) over `onKeyEvent` (keydown) for typing-driven UI** — same as web's "prefer `input` over `keyup`".
- **Pointer events for cross-device** — `Listener` works for mouse, touch, and stylus uniformly.
- **Event delegation** — Flutter doesn't bubble like the DOM. Use a single `GestureDetector` parent or `NotificationListener` for hierarchical events (e.g., scroll).
- **Always `dispose()`** — `AnimationController`, `ScrollController`, `TextEditingController`, `FocusNode`, timers, subscriptions.
- **Debounce scroll/resize handlers** — wrap with a `Timer? _debounce` that you cancel on every event and reschedule.

## Motion tokens (durations + curves)

A small, named palette so motion stays consistent across screens. Reach for these constants instead of inventing per-widget durations.

```dart
class MotionTokens {
  // Durations — pick by intent, not vibe.
  static const Duration micro   = Duration(milliseconds: 100);  // tiny acks: ripple, checkbox
  static const Duration short   = Duration(milliseconds: 180);  // hover, focus, swap a value
  static const Duration medium  = Duration(milliseconds: 280);  // sheet open/close, chip animate
  static const Duration long    = Duration(milliseconds: 420);  // route push, hero, expand a card
  static const Duration emph    = Duration(milliseconds: 520);  // big celebrations, splash
  static const Duration page    = Duration(milliseconds: 320);  // standard page transition

  // Curves — semantically named.
  static const Curve standard   = Curves.easeOutCubic;          // 90% of cases
  static const Curve enter      = Curves.easeOutCubic;          // appearing on screen
  static const Curve exit       = Curves.easeInCubic;           // leaving the screen
  static const Curve emphasized = Curves.easeOutQuint;          // material 3 emphasized
  static const Curve smooth     = Curves.fastOutSlowIn;         // page-level transitions
  static const Curve bounce     = Curves.elasticOut;            // playful — sparingly
  static const Curve overshoot  = Curves.easeOutBack;           // small bounce at the end
  static const Curve linear     = Curves.linear;                // progress bars, scrubbing
  static const Curve decelerate = Curves.decelerate;            // incoming pages
  static const Curve sharp      = Cubic(0.4, 0.0, 0.6, 1.0);    // material "sharp" — tabs, snackbars
}
```

### Selection rules

- **Default everything to `MotionTokens.standard` (≈280ms).** Don't go faster than 100ms (looks janky) or slower than ~500ms (feels laggy) without a reason.
- **Bounce/elastic is a budget item.** One playful animation per screen — usually a success state. Never on routine transitions.
- **Match curve to direction.** `easeOut` for incoming (snaps into place), `easeIn` for outgoing (gathers speed before leaving).
- **Reduce motion sensitivity:** respect `MediaQuery.disableAnimations` (and `accessibilityFeatures.disableAnimations`) — fall back to instant or 50ms transitions.

## Animation patterns

### 1. Slide (transform.translate)

```dart
SlideTransition(
  position: Tween<Offset>(
    begin: const Offset(0, 0.05),  // 5% below
    end: Offset.zero,
  ).animate(CurvedAnimation(parent: ctrl, curve: MotionTokens.enter)),
  child: child,
)
```

Use for content arriving from the bottom (sheets, banners, toast-style cards). For full-page slides, prefer the platform `PageTransitionsBuilder` rather than hand-rolling.

### 2. Fade

```dart
FadeTransition(
  opacity: CurvedAnimation(parent: ctrl, curve: MotionTokens.standard),
  child: child,
)
```

Use whenever the spatial relationship doesn't matter — replacing a loading skeleton with content, switching empty/full states.

### 3. Scale + fade (combined for "appearing")

```dart
ScaleTransition(
  scale: Tween(begin: 0.96, end: 1.0).animate(
    CurvedAnimation(parent: ctrl, curve: MotionTokens.standard),
  ),
  child: FadeTransition(
    opacity: ctrl,
    child: child,
  ),
)
```

The 4% scale lift makes a fade feel intentional rather than ghostly.

### 4. Bounce (controlled overshoot)

```dart
ScaleTransition(
  scale: Tween(begin: 0.0, end: 1.0).animate(
    CurvedAnimation(parent: ctrl, curve: MotionTokens.overshoot),
  ),
  child: child,
)
```

Use `overshoot` for quick acks (bookmark saved, item added to cart). Use `bounce` (elasticOut) only for celebratory moments — confetti, milestone-reached badges. Never on every list item.

### 5. Smooth height (reveal/collapse)

Use `AnimatedSize` for a container that needs to grow/shrink with its content (e.g., a comment that expands to show replies):

```dart
AnimatedSize(
  duration: MotionTokens.medium,
  curve: MotionTokens.smooth,
  child: expanded
      ? const _ExpandedDetails()
      : const SizedBox.shrink(),
)
```

For switching between two distinct widgets (skeleton → content), use `AnimatedSwitcher`:

```dart
AnimatedSwitcher(
  duration: MotionTokens.short,
  switchInCurve: MotionTokens.enter,
  switchOutCurve: MotionTokens.exit,
  child: loading
      ? const _Skeleton(key: ValueKey('skel'))
      : _Content(key: ValueKey('content'), data: data),
)
```

The `key` on each child is mandatory — `AnimatedSwitcher` uses key equality to know whether to animate.

### 6. Shake (validation error)

```dart
TweenAnimationBuilder<double>(
  key: ValueKey(errorTrigger),  // bump on each error
  tween: Tween(begin: 0, end: 1),
  duration: MotionTokens.medium,
  builder: (_, t, child) {
    final dx = sin(t * pi * 4) * 6 * (1 - t);  // damped 4-cycle shake
    return Transform.translate(offset: Offset(dx, 0), child: child);
  },
  child: field,
)
```

For wrong PIN, invalid input. Pair with a red border that fades back to normal.

### 7. Hero (shared element across routes)

```dart
Hero(
  tag: 'post-image-${post.id}',  // SAME tag on both screens
  child: image,
)
```

Use for opening images, posts, products into a detail screen. Tag must be unique per item, identical on source and destination.

### 8. Staggered list entry

For a fresh list of items, animate them in sequence (delayed by index):

```dart
AnimatedList(
  initialItemCount: items.length,
  itemBuilder: (ctx, i, anim) => SlideTransition(
    position: Tween<Offset>(
      begin: const Offset(0, 0.15),
      end: Offset.zero,
    ).animate(CurvedAnimation(parent: anim, curve: MotionTokens.enter)),
    child: FadeTransition(opacity: anim, child: _Tile(items[i])),
  ),
)
```

Cap the stagger at ≤ 6 items — beyond that the user is waiting on animation, not data.

### 9. Page transitions

Don't fight the platform. Default Material/Cupertino route transitions are correct most of the time:

```dart
Navigator.push(context, MaterialPageRoute(builder: (_) => const Page()));
```

For a custom transition (e.g., a fade for a modal-like push):

```dart
Navigator.push(
  context,
  PageRouteBuilder(
    pageBuilder: (_, __, ___) => const Page(),
    transitionDuration: MotionTokens.page,
    reverseTransitionDuration: MotionTokens.page,
    transitionsBuilder: (_, anim, __, child) =>
        FadeTransition(opacity: anim, child: child),
  ),
);
```

### 10. Bottom sheet / dialog

Use the platform helpers — they already handle the right curves and durations:

```dart
showModalBottomSheet(
  context: context,
  showDragHandle: true,
  isScrollControlled: true,
  shape: const RoundedRectangleBorder(
    borderRadius: BorderRadius.vertical(top: Radius.circular(16)),
  ),
  builder: (_) => _Sheet(),
);
```

If you need a fully custom presentation, follow the [DraggableScrollableSheet] pattern with `MotionTokens.medium`.

## UI manipulation rules

These are TAJIRI's house rules for *how content rearranges itself* in response to user input. Pattern names match the canonical Material/iOS behaviors where possible.

### Page chrome — required on every screen

Non-negotiable structural elements. If you're building or auditing a screen and it's missing any of these, fix before merge.

#### 1. Every page has a top bar

Every screen must render a top bar — `AppBar`, `SliverAppBar`, or `TajiriAppBar`. No exceptions for "minimalist" screens. The top bar carries:
- The screen **title** (or context — e.g. a hero image with overlaid name on the profile cover).
- A **leading widget** — the system back button (`Navigator.canPop()` true) or the menu button (root tabs).
- Optional **trailing actions** (settings cog, share, more menu).

Standard properties:
```dart
AppBar(
  title: Text(s?.someTitle ?? 'Title'),
  backgroundColor: Colors.white,
  foregroundColor: const Color(0xFF1A1A1A),
  elevation: 0,
  scrolledUnderElevation: 1,
)
```

For tab content rendered inside `_ProfileTabPage` (the profile module hub), do NOT add a second `AppBar` — the parent already owns the chrome. See Part II → Issue type 11 (*Double titles / Double AppBars*).

#### 2. Every page wraps content in `SafeArea`

```dart
Scaffold(
  appBar: ...,
  body: SafeArea(
    child: ...,
  ),
)
```

`SafeArea` insets for the notch, status bar (when no AppBar), home indicator, and rounded corners. Even with an `AppBar` (which already insets the top), wrap the body to protect the bottom (home indicator on iPhone X+, gesture nav bar on Android).

Exceptions where you intentionally want edge-to-edge content:
- Full-screen photo/video viewers (use `SafeArea(top: false, bottom: false)` on the immersive layer, but inset overlay controls separately).
- Feed cards (the card itself goes edge-to-edge but the scroll-view should still respect the top/bottom safe area).

When inside a nested route, `SafeArea` is harmless even if the parent already wrapped — `SafeArea` is idempotent.

#### 3. Every screen with a `TextField` provides keyboard dismissal

The system keyboard appears on focus and stays until explicitly dismissed. Without escape paths, users get stuck. Provide **at minimum two** dismissal mechanisms on any screen with text input:

**a) Tap-outside-to-dismiss** — the universal escape:

```dart
return GestureDetector(
  behavior: HitTestBehavior.opaque,
  onTap: () => FocusScope.of(context).unfocus(),
  child: Scaffold(
    appBar: ...,
    body: SafeArea(child: ...),
  ),
);
```

`HitTestBehavior.opaque` is required so the gesture fires on transparent regions. Place this above `Scaffold`, not below — taps inside `Scaffold` propagate up and trigger the dismiss.

**b) Submit / Done IME action** — moves focus along the form:

```dart
TextField(
  textInputAction: TextInputAction.next,    // last field uses TextInputAction.done
  onSubmitted: (_) => _focusNext.requestFocus(),  // or _save() on done
)
```

**c) Drag-to-dismiss on long lists** — for scrollable forms, dismiss on scroll start so the keyboard doesn't fight the list:

```dart
ListView(
  keyboardDismissBehavior: ScrollViewKeyboardDismissBehavior.onDrag,
  children: ...,
)
```

**d) Auto-dismiss on route navigation** — handled by Flutter when `Navigator.push`/`pop` runs, but verify with cases like opening a bottom sheet (which doesn't always dismiss). When in doubt, call `FocusScope.of(context).unfocus()` before showing a sheet/dialog.

**e) `Scaffold(resizeToAvoidBottomInset: true)`** — the default. Don't disable it; it's what lifts the body above the keyboard so the focused field stays visible. Wrap forms in `SingleChildScrollView` so they can scroll behind the keyboard.

**f) Auto-dismiss on save success** — explicit `unfocus` before `Navigator.pop` makes the transition feel cleaner:

```dart
if (result.success) {
  FocusScope.of(context).unfocus();
  ProfileService.invalidate(...);
  Navigator.pop(context, true);
}
```

#### 4. Every page has a way back

Three layers, in order of fallback:

**a) System back button** (Android/gesture) — `Navigator.pop` fires automatically. Don't intercept unless you have a real reason (unsaved-data warning).

**b) AppBar leading icon** — `AppBar` shows it automatically when `Navigator.canPop()` is true. For root tabs (Feed, Messages, Friends, Shop, Me) where `canPop()` is false, replace it with a menu icon, the user's avatar, or the brand mark.

**c) Pop-with-result** — when the screen saved data, pop with `true`; when it didn't, pop with `false` or `null`. See [Save → pop → refresh chain](#save--pop--refresh-chain). Default system-back gives `null`, which hubs treat as "no change" — that's correct.

**Unsaved-changes guard** — for screens with edits-in-progress, intercept system-back via `PopScope` and warn:

```dart
PopScope(
  canPop: !_hasUnsavedChanges,
  onPopInvokedWithResult: (didPop, _) async {
    if (didPop) return;
    final discard = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        content: Text(s?.discardUnsavedChanges ?? 'Discard unsaved changes?'),
        actions: [
          TextButton(onPressed: () => Navigator.pop(ctx, false), child: Text(s?.cancel ?? 'Cancel')),
          TextButton(
            onPressed: () => Navigator.pop(ctx, true),
            child: Text(s?.discard ?? 'Discard', style: const TextStyle(color: Colors.red)),
          ),
        ],
      ),
    );
    if (discard == true && mounted) Navigator.pop(context);
  },
  child: Scaffold(...),
)
```

Reserve this for screens where losing changes would frustrate the user (compose post, long form). Don't add it to trivial screens — it's friction.

**No `WillPopScope`** — that widget is deprecated. Use `PopScope` (Flutter 3.16+).

#### 5. Page skeleton template

The boilerplate every new screen starts from. Drop in domain-specific bits, keep the chrome:

```dart
@override
Widget build(BuildContext context) {
  final s = AppStringsScope.of(context);
  return GestureDetector(
    behavior: HitTestBehavior.opaque,
    onTap: () => FocusScope.of(context).unfocus(),
    child: Scaffold(
      backgroundColor: const Color(0xFFFAFAFA),
      appBar: AppBar(
        title: Text(s?.thisScreenTitle ?? 'Title'),
        backgroundColor: Colors.white,
        foregroundColor: const Color(0xFF1A1A1A),
        elevation: 0,
        scrolledUnderElevation: 1,
      ),
      body: SafeArea(
        child: _loading
            ? const Center(child: CircularProgressIndicator(color: Color(0xFF1A1A1A)))
            : _error != null
                ? _ErrorState(message: _error!, onRetry: _load)
                : RefreshIndicator(
                    color: const Color(0xFF1A1A1A),
                    onRefresh: _load,
                    child: ListView(
                      keyboardDismissBehavior:
                          ScrollViewKeyboardDismissBehavior.onDrag,
                      padding: const EdgeInsets.all(16),
                      children: [/* content */],
                    ),
                  ),
      ),
    ),
  );
}
```

This template covers: keyboard dismiss-on-tap, AppBar with title + back, SafeArea inset, monochrome scaffold colour, loading/error/content states, pull-to-refresh, scroll-driven keyboard dismiss. The first thing reviewers should look for in a new screen file.

### Inline feedback, never toasts

> **Project-wide rule. Overrides any prior guidance about SnackBars in this playbook.**

TAJIRI does not use `SnackBar`, `Toast`, `Fluttertoast`, or any transient overlay widget. Backend responses, validation messages, and quick notifications are shown **inline at the proper place on the screen the user is currently looking at**.

> **If the action causes navigation, show nothing.** The new screen is the confirmation.

#### Why

- Toasts vanish before older users (and reduce-motion users) can read them.
- Toasts overlap the keyboard, the bottom nav bar, and the FAB — covering the very controls the user just touched.
- Toasts don't survive screen rotation or app backgrounding.
- A toast saying *"Saved"* plus a navigation transition is double feedback — one is enough, and the navigation is more reliable.
- Inline feedback is announced by screen readers in the user's reading order; toasts require `liveRegion` to be announced at all.

#### Replacement patterns by use case

| Old pattern (banned) | Required replacement |
|---|---|
| `SnackBar('Saved')` after a save that pops | Nothing — `Navigator.pop(context, true)` IS the confirmation |
| `SnackBar('Posted')` after navigating to a feed | Nothing — the new post appearing in the feed IS the confirmation |
| `SnackBar('Failed to save')` after API failure | Inline error banner at the top of the form, ABOVE the primary CTA |
| `SnackBar('Pick a school first')` validation | Inline `errorText` on the relevant `TextField` / form validator, OR an inline banner if the missing thing isn't a single field |
| `SnackBar('Copied!')` after copy-to-clipboard | The icon briefly switches to a check (200ms) — visual ack at the spot the user tapped |
| `SnackBar('Archived. Undo')` for undo flows | A `MaterialBanner` at the top of the list OR an inline ghost row — see Undo patterns in Part VII |
| `SnackBar('No connection')` | Persistent `MaterialBanner` below the AppBar — see Network state UI in Part VII |
| `SnackBar(error.message)` after server error | Inline error banner above the form's primary CTA, or an error widget replacing the failed list section |
| Long-press → `SnackBar('Phone copied')` | Brief icon change at the long-press target |

#### Where exactly to place inline feedback

| Trigger | Where the inline message goes |
|---|---|
| Form-level error after submit | Red-bordered card at the top of the `Form`, immediately below the AppBar / header, above the first field |
| Field-level error | `TextFormField`'s `errorText:` (handled by `Form` validator) |
| List-section failure (feed couldn't load) | Replace that section with the standard error widget (icon + message + retry button) — same triumvirate as empty state |
| Per-row action failure (e.g. like fails) | Revert the optimistic update and play a brief 1.2s shake on the row's failed control |
| Network state | `MaterialBanner` directly under the AppBar |
| Background-task results (upload finished) | Inline pill in the relevant module — e.g. an upload chip in the feed AppBar updates from "Uploading…" to "Uploaded ✓" then disappears after 2s |
| Cross-screen "I did something" (e.g. shared a post from a sheet) | The sheet pops; the source screen reflects the new state. No toast on either side. |

#### "Navigation is the confirmation"

When the success path triggers `Navigator.pop(context, true)`, `Navigator.push`, `pushReplacement`, or any navigation, **render nothing**. The user moving is the signal. The destination screen — parent list now reflecting the change, next step in a flow, etc. — is itself the confirmation.

#### Code: required canonical save flow

```dart
Future<void> _save() async {
  final s = AppStringsScope.of(context);
  if (!_formKey.currentState!.validate()) return;
  if (_picked == null) {
    setState(() => _formError = s?.pleaseSelectSchool ?? 'Please pick a school first');
    return;
  }
  setState(() {
    _saving = true;
    _formError = null;        // clear any previous error
  });
  final result = await <DataService>.update(<payload>);
  if (!mounted) return;
  setState(() => _saving = false);
  if (result.success) {
    <Service>.invalidate(<id>);
    // No SnackBar. Navigation is the confirmation.
    Navigator.pop(context, true);
  } else {
    setState(() => _formError = result.message ?? s?.saveFailed ?? 'Could not save — try again.');
  }
}

// In build(), above the first field:
if (_formError != null) _InlineErrorBanner(message: _formError!),
```

#### Code: the canonical inline error banner

```dart
class InlineErrorBanner extends StatelessWidget {
  final String message;
  final VoidCallback? onRetry;
  const InlineErrorBanner({super.key, required this.message, this.onRetry});

  @override
  Widget build(BuildContext context) {
    final s = AppStringsScope.of(context);
    return Semantics(
      liveRegion: true,
      child: Container(
        margin: const EdgeInsets.only(bottom: 12),
        padding: const EdgeInsets.all(12),
        decoration: BoxDecoration(
          color: Colors.red.shade50,
          border: Border.all(color: Colors.red.shade200),
          borderRadius: BorderRadius.circular(12),
        ),
        child: Row(
          children: [
            const Icon(Icons.error_outline, size: 20, color: Colors.red),
            const SizedBox(width: 8),
            Expanded(
              child: Text(
                message,
                style: const TextStyle(fontSize: 13, color: Colors.red),
                maxLines: 3,
                overflow: TextOverflow.ellipsis,
              ),
            ),
            if (onRetry != null)
              TextButton(
                onPressed: onRetry,
                child: Text(s?.retry ?? 'Retry'),
              ),
          ],
        ),
      ),
    );
  }
}
```

`liveRegion: true` is required so screen readers announce the message when it appears.

#### Acceptance checks

1. **Grep is empty:** `rg 'showSnackBar|SnackBar\(|Fluttertoast|Toast\(' lib/` returns zero results (excluding deprecated screens scheduled for removal).
2. **Every error path renders inline somewhere on the current screen** — never as a transient overlay.
3. **Every successful action either:** (a) navigates and shows no further confirmation, or (b) updates inline state visibly (the row reflects the change, the count increments, the icon switches).

#### Allowed exceptions

- **`MaterialBanner`** for persistent system-level state (offline, app update available) — see Part VII → Network state UI. This is *not* a toast — it stays until dismissed or condition resolves.
- **`Dialog`** when the user genuinely needs to make a decision (confirm-before-destructive). Dialogs are not in scope of this rule.
- **Stand-alone overlay widgets** for ephemeral *visual-only* affordances (the briefly-flashing check on copy, the 1.2s shake on a failed control). These don't carry text — they're motion ack, not notification.

### Collapse-on-selection

When a multi-step picker yields a single result, collapse the picker UI and show only the chosen value with an X to undo.

**Reference implementation:** `lib/widgets/school_picker.dart` (after 2026-05-01 rewrite). When `_selectedSchool != null`, the toggle, dropdowns, and search field disappear; only the selected card remains. Tapping its X calls `_clearSelection()` which nulls the selection — the conditional flips and the picker UI returns.

```dart
@override
Widget build(BuildContext context) {
  if (_selected != null) {
    return _SelectedCard(value: _selected!, onClear: _clear);
  }
  return _PickerInputs(/* dropdowns, search, etc. */);
}
```

Apply to: any cascading picker (region → district → item), any "browse vs search" toggle, multi-step wizards.

### Progressive disclosure

Show summary first, details on tap. Don't dump every available field on a single screen.

- **About card** in the profile header shows 4–6 key rows; the full About tab shows everything.
- **Settings hub** with sub-tiles (matches the Username / Profile tabs / Education-hub pattern) instead of one mega-screen with collapsible sections.
- **Bottom sheets** instead of dialogs when revealing more content (sheets read as "more from below"; dialogs read as "interruption").

### Optimistic UI

For non-critical actions (like, save, follow), update the UI immediately and reconcile with the server in the background.

```dart
setState(() => _liked = true);              // immediate
final ok = await api.like(postId);
if (!ok && mounted) {
  setState(() => _liked = false);           // revert on failure
  _shakeController.forward(from: 0);        // brief inline shake on the heart icon
  // No SnackBar. The revert + shake IS the failure signal.
}
```

Use for: like, react, save/bookmark, mark-read, toggle, follow/unfollow, expand/collapse, mute. Do NOT use for: payment, account changes, content posting, deletes.

### Confirm before destructive

Delete, cancel, unfriend, unfollow-creator, logout, clear-data — always behind an `AlertDialog`. The destructive action label is **red**, the cancel label is **default**.

```dart
final ok = await showDialog<bool>(
  context: context,
  builder: (ctx) => AlertDialog(
    content: Text(s?.removeConfirm ?? 'Remove this item?'),
    actions: [
      TextButton(onPressed: () => Navigator.pop(ctx, false), child: Text(s?.cancel ?? 'Cancel')),
      TextButton(
        onPressed: () => Navigator.pop(ctx, true),
        child: Text(s?.delete ?? 'Delete', style: const TextStyle(color: Colors.red)),
      ),
    ],
  ),
);
if (ok != true) return;
```

### Save → pop → refresh chain (project-wide)

The canonical completion flow for **every** screen in the app that mutates server state — profile edits, post creation, comment posting, message send, shop cart updates, kikoba contributions, group invites, settings of any kind. Every sub-screen, every hub, every parent up the navigation stack follows these rules so a save propagates fresh data automatically with no manual refresh, no signal-passing, no event bus.

> **Scope:** this section applies to ALL features, not just the profile-edit examples cited at the bottom. The rules are written generically — substitute your domain's service for `<DataService>` and your domain's load method for `<reload()>`.

#### Where to invalidate, by domain

Every cached service in the app exposes (or should expose) an `invalidate(...)` or `clear()` hook. The leaf screen calls the appropriate one before popping. Reference list — keep up to date as new caches land:

| Domain | Service / cache | Invalidation API |
|---|---|---|
| User profile | `ProfileService` | `ProfileService.invalidate(userId)` per user; `ProfileService.clearCache()` on logout |
| Feed | `FeedCacheService` *(Phase 1)* | `FeedCacheService.instance.clear(feedType)` after post/delete; `clear()` on logout |
| Messages | `MessageCacheService` | `MessageCacheService.invalidateConversation(id)` after send/edit/delete |
| Conversations list | `ConversationCacheService` *(Phase 4)* | `invalidate()` after new conversation, mute, archive |
| Shop categories | `ShopService` | `invalidateCategories()` after admin add/remove |
| Shop cart | local cart cache | `clearCart()` after order placed |
| Search history | `SearchHistoryService` *(Phase 5)* | n/a — append-only |
| HTTP ETag | `EtagCacheService` *(Phase 5)* | `invalidate(url)` after any PUT/POST/DELETE on the same resource |
| Notifications | `NotificationDb` *(SQLite Phase 1)* | `markRead(id)` / `clearAll()` |
| Wallet transactions | `WalletDb` *(SQLite Phase 1)* | `invalidate()` after deposit/withdraw |

If a feature has no cache, **the rules still apply** — substitute "invalidate" with "no-op". The pop-with-true and parent-reload contract is unchanged.

#### Sub-screen rules (the leaf doing the actual save)

```dart
Future<void> _save() async {
  final s = AppStringsScope.of(context);
  // 1. Validate inputs (form validators, picker presence, etc.)
  if (!_formKey.currentState!.validate()) return;
  if (_somePrecondition == null) {
    setState(() => _formError = s?.someValidationMsg ?? 'Pick X first');
    return;
  }
  // 2. Lock the UI for the duration of the request.
  setState(() {
    _saving = true;
    _formError = null;
  });
  final result = await <DataService>.update(<payload>);
  // 3. Mounted guard after every await before touching context/setState.
  if (!mounted) return;
  setState(() => _saving = false);
  if (result.success) {
    // 4. INVALIDATE every cache that holds this data so parents fetch fresh.
    //    Pick the right service for your domain (see the table above).
    <DataService>.invalidate(<id>);
    // 5. Pop with `true` so callers can branch on it.
    //    NO SnackBar — navigation IS the confirmation. See "Inline
    //    feedback, never toasts" earlier in this Part.
    Navigator.pop(context, true);
  } else {
    // 6. On failure: stay on screen, surface the error inline.
    setState(() => _formError = result.message ?? (s?.saveFailed ?? 'Could not save — try again.'));
  }
}
// In build(), above the form's first field:
//   if (_formError != null) _InlineErrorBanner(message: _formError!),
```

Same pattern for **clear / delete / cancel-action**: confirmation dialog → `setState(_saving = true)` → API → invalidate → `Navigator.pop(context, true)` on success, or inline error banner on failure. Never a SnackBar.

Same pattern for **post creation, comment, message send, shop checkout, etc.** — even when the screen exits via `pushReplacement` instead of `pop`, the invalidate-before-navigate ordering is identical.

#### Hub rules (parent showing summaries of child screens)

A hub displays summaries of one or more child edit screens — `SettingsScreen → Profile`, `EducationSettingsScreen → 5 sub-screens`, `ShopScreen → cart sheet`, `WalletScreen → deposit/withdraw modals`, etc. After any child pops with `true`, the hub reloads:

```dart
Future<void> _openEdit(Widget Function() builder) async {
  final updated = await Navigator.push<bool>(
    context,
    MaterialPageRoute(builder: (_) => builder()),
  );
  if (updated == true && mounted) {
    <reload()>;            // calls the hub's existing load function
  }
}
```

The hub does NOT invalidate the cache — the leaf already did. The hub just calls its load function, which hits the now-empty cache and fetches fresh.

#### Grandparent rules (screens above the hub)

Top-level screens that surface mutable data (Profile, Home tabs, Wallet, Shop, Conversations) reload when the user returns from any nested flow. Chain a `.then(...)` onto the navigator push:

```dart
Navigator.push(
  context,
  MaterialPageRoute(builder: (_) => <ChildScreen>()),
).then((_) {
  if (!mounted) return;
  <reload()>;
});
```

Always guard with `if (!mounted) return;` — by the time the user returns, the State might already be disposed.

If the grandparent has multiple things to refresh (e.g. profile + tab config), call them all:

```dart
.then((_) {
  if (!mounted) return;
  _refreshTabs();
  _loadProfile();
});
```

Reload is **unconditional** at the grandparent level — you don't know which descendants saved what. Cache invalidation at the leaf makes redundant reloads cheap (a cache hit is ~0ms; a miss reaches the network only when something actually changed).

#### Why this works without signal-passing

```
Leaf edit screen     Hub               Mid-list             Grandparent
       │              │                  │                       │
       │ save →       │                  │                       │
       │   invalidate │                  │                       │
       ▼ pop(true)    │                  │                       │
       ───────────────▶                  │                       │
                  updated==true          │                       │
                  → reload()             │                       │
                  → cache miss → API ✓   │                       │
                       │                  │                       │
                       ▼                  │                       │
                       ──────────────────▶                       │
                       (no reload — list of tiles, no live data)
                                          │                       │
                                          ▼                       │
                                          ───────────────────────▶
                                                          .then(_) →
                                                          reload()
                                                          → cache miss → API ✓
```

Each layer has one responsibility:
- **Leaf:** invalidate caches, then `pop(true)` on success or inline error on failure. **Never a SnackBar.**
- **Hub:** reload only when child popped `true`.
- **Mid-list (settings menu, tab grid, etc.):** no reload — it doesn't display live data.
- **Grandparent:** reload unconditionally on every return from a nested flow.

No layer needs to know the intermediate steps. The cache miss propagates truth without any explicit message.

#### Rules to follow strictly (apply to every feature)

1. **Always invalidate before pop** — `<Service>.invalidate(...)` runs *before* `Navigator.pop(context, true)`. If you pop first, the parent may rebuild from stale cache while the invalidate races.
2. **Pop with `true` only on real success** — never on validation failure, network error, "Nothing to save", or back-button. Reserve `true` for "the server confirmed the change."
3. **Hubs check `updated == true && mounted`** — `null`, `false`, or back-button pop must be no-ops.
4. **Don't invalidate at the hub** — leaf only. Invalidating everywhere causes redundant API calls.
5. **No success SnackBars on save** — the navigation IS the confirmation (see *Inline feedback, never toasts* in this Part). On failure, surface the error inline on the current screen and don't pop.
6. **Mid-stack screens (settings menus, tab grids) don't reload** — they show static tiles. Only screens displaying live data need to reload.
7. **Add an `invalidate(...)` hook to every service that caches** — even a no-op stub if you don't have caching yet. Future cache layers slot in without callers needing to change.
8. **Logout clears every cache** — every cached service exposes `clearCache()` (or `clear()`); `AuthService._performLocalLogout()` calls them all.
9. **Optimistic UI is the exception, not the rule** — if you used optimistic update (Part VI → *Optimistic UI*), you've already updated UI before the API completed; the save→pop chain still applies for confirmation/revert, but the parent's reload is decorative rather than load-bearing.

#### Reference implementations

| Layer | Files |
|---|---|
| Leaf (sub-screen) | `lib/screens/settings/email_settings_screen.dart`, `lib/screens/settings/work_settings_screen.dart`, `lib/screens/settings/location_settings_screen.dart`, `lib/screens/settings/education/edit_*.dart` (5 files), `lib/screens/profile/edit_profile_screen.dart` |
| Hub | `lib/screens/settings/education_settings_screen.dart` |
| Grandparent | `lib/screens/profile/profile_screen.dart` (cog icon + Settings tab + Edit profile dialog paths) |
| Cache invalidation | `lib/services/profile_service.dart` (`invalidate(userId)`, `clearCache()`) |

When you build a new feature with a save flow, copy the leaf pattern from the closest existing reference — don't reinvent. If the new feature has its own cache, mirror `ProfileService` and add an `invalidate(...)` static method to the cached service before wiring the leaf to call it.

### CRUD directives (project-wide)

Every editable resource in TAJIRI — username, email, profile fields, posts, photos, addresses, kikoba memberships, michango contributions, shop products, etc. — must support all four operations: **C**reate, **R**ead, **U**pdate, **D**elete. Skipping any of them is a defect, not a feature gap.

> Reference implementation: `lib/screens/settings/username_settings_screen.dart` (after the 2026-05-01 rewrite). All four ops + live availability check + uniqueness verification end-to-end.

#### Backend rules

1. **Use `nullable` to enable delete.** Don't add a separate `DELETE` endpoint when a `PUT` with `null` does the job. Laravel example:
   ```php
   $validator = Validator::make($request->all(), [
     'username' => 'nullable|string|min:3|max:20|regex:/^[a-z][a-z0-9_]{2,19}$/|unique:user_profiles,username,' . $id,
   ]);
   $newValue = $request->input('username');
   $profile->update([
     'username' => $newValue === null ? null : strtolower($newValue),
   ]);
   ```
   Use a dedicated `DELETE` route only when removing the resource also detaches relations or runs side effects (e.g., post → cascade comments → cleanup media). Single-field clears use `PUT … null`.

2. **Validation rules must align across endpoints.** If you have an availability/uniqueness check endpoint AND a save endpoint for the same resource, **use the same regex, length, and case rules in both**. A live check that says "available" but a save that rejects with 422 because the rules differ is a real production bug we shipped once and will not ship again.
   ```php
   // BAD — these disagreed before 2026-05-01:
   //  checkHandle:    /^[a-z][a-z0-9_]{2,19}$/
   //  updateUsername: /^[a-zA-Z0-9_]+$/  + min:3|max:30
   // GOOD: identical regex + identical min/max in both validators.
   ```

3. **Uniqueness via `Rule::unique()->ignore($id)`** so a user re-saving their own value doesn't conflict with themselves:
   ```php
   'email' => [
     'nullable', 'email', 'max:255',
     Rule::unique('user_profiles', 'email')->ignore($profile->id),
   ],
   ```

4. **Normalise on the way in.** Lowercase email/username, trim whitespace, strip control characters. Do this in the controller, not the database. The frontend can mirror with `inputFormatters` for snappy UX, but the server is the source of truth.

5. **Return 422 + `errors.{field}: [...]` on validation failure.**
   ```php
   if ($validator->fails()) {
     return response()->json([
       'success' => false,
       'message' => 'Validation failed',
       'errors' => $validator->errors(),  // {username: ["The username has already been taken"]}
     ], 422);
   }
   ```
   Frontend services surface `errors.{field}[0]` as the inline banner message — see *Inline feedback, never toasts* earlier in this Part.

6. **Trigger group/index/cache rebuilds** if the field affects them. The `UserProfileController::update()` pattern:
   - Snapshot the old profile,
   - Apply the update,
   - Detect whether any group-relevant field changed,
   - Dispatch `AssignUserToDefaultGroups($id, $oldProfile)` to the queue.

   Adopt the same pattern for any resource with derivative state (search index, leaderboard, embeddings).

#### Frontend service rules

1. **Update methods accept nullable values.**
   ```dart
   Future<UsernameUpdateResult> updateUsername({
     required int userId,
     required String? username,   // null = delete
   }) async { ... }
   ```

2. **Live availability/format checks** for any constrained, unique, or limited-namespace field (username, slug, custom-URL, group-name). Pattern:
   ```dart
   Future<bool?> checkHandleAvailability(String handle) async {
     try {
       final r = await http.post(...);
       if (r.statusCode == 200 && data['success'] == true) {
         return data['available'] == true;
       }
       return null;   // unknown — UI must NOT show a red error on null
     } catch (_) {
       return null;
     }
   }
   ```
   Returning `null` on network error is required: it lets the UI fall back to "ask later" instead of falsely declaring the value taken/invalid.

3. **Surface field-level validation errors** from the 422 response. Service maps `errors[field][0]` into `result.message` so the inline banner shows the actual reason, not a generic "Failed to save".

#### Frontend UI rules

1. **All four ops are reachable from the same screen** — Update + Delete via the form, Create handled by the same Update path (server-side `update or insert`). Read happens in `_loadProfile`. Don't fragment CRUD across multiple screens unless the resource is a list (post, photo) where Create is "compose" and Delete lives in a per-row menu.

2. **Live availability indicator with debounce** for any field that has a check endpoint. Standard cadence: 350 ms debounce after `onChanged`, then call the check. Show three states inline:
   - `Checking…` — small spinner suffix-icon + "Checking…" hint below
   - ✓ `Available` — green check + "Available" hint
   - ✗ `Already taken` — red X + "Already taken" hint
   Wrap the hint in `Semantics(liveRegion: true)` so screen readers announce changes (per Part VII → Accessibility).
   ```dart
   Timer? _debounce;
   void _onChanged(String v) {
     setState(() { _available = null; _checking = false; });
     _debounce?.cancel();
     if (v.isEmpty || !_localFormatValid(v)) return;
     setState(() => _checking = true);
     _debounce = Timer(const Duration(milliseconds: 350), () async {
       final available = await _service.checkAvailability(v);
       if (!mounted || _controller.text.trim() != v) return;
       setState(() { _checking = false; _available = available; _lastChecked = v; });
       _formKey.currentState?.validate();   // re-runs validator with new state
     });
   }
   ```

3. **Skip the network check if local format is invalid.** Saves the round-trip and avoids confusing the user when they're mid-typing.

4. **`inputFormatters` enforce server rules at the keystroke level.** If the backend regex is `^[a-z][a-z0-9_]{2,19}$`, the frontend uses `_LowercaseFormatter` + `FilteringTextInputFormatter.allow(RegExp(r'[a-z0-9_]'))` + `LengthLimitingTextInputFormatter(20)` so users can't type characters that would fail validation.

5. **Delete button styling.** Red `TextButton.icon` with a trash icon and the resource name ("Remove username", "Remove email"). Only render it when there's a current value to remove (don't show a delete affordance for empty state). Always behind an `AlertDialog` confirmation per *Confirm before destructive*.

6. **Validator distinguishes between distinct error causes.** Don't conflate "must start with a letter" with "use only letters/numbers/underscore" — they're different things to fix. The user knows what to do when the error names the rule precisely.

#### Acceptance checklist (per resource)

A new editable resource is **not** complete until:

- [ ] **Create** path works (or is implicitly handled by `update or insert` server-side).
- [ ] **Read** path returns the field in the relevant `show` endpoint and the frontend model parses it.
- [ ] **Update** path PUT returns 200 with the new value in `data.{field}` on success.
- [ ] **Delete** path: `PUT … null` (or dedicated `DELETE`) returns 200 and the field is `null` on next read.
- [ ] **Validation** rejects malformed/illegal values with 422 + `errors.{field}` and the frontend surfaces the message inline.
- [ ] **Uniqueness** (where applicable) — saving a value already held by another user returns 422; the same user re-saving their own value returns 200 (use `Rule::unique()->ignore($id)`).
- [ ] **Availability check** endpoint exists (where applicable) and uses **the same regex** as the save endpoint — verified by grep.
- [ ] **Live availability** wired on the frontend with 350ms debounce and three-state indicator.
- [ ] **`inputFormatters`** enforce the server's character/length rules at the keystroke level.
- [ ] **Cache invalidation** — `<RelevantService>.invalidate(...)` runs before `Navigator.pop(true)`.
- [ ] **Group/index reassignment** dispatched if the field is group-relevant (per the *Save → pop → refresh chain* table).
- [ ] **End-to-end test** via real HTTP confirms all four ops + uniqueness + at least 4 validation rejections.

#### Reference test pattern

For each new resource, a PHP test file (run on the backend host with curl) should exercise:

```
1. CREATE      PUT /resource → 200 (was null)
2. READ        GET /resource → returns the value
3. AVAIL CHECK POST /check  → matches DB state
4. VALIDATION  PUT bad-format → 422 (run for each rule)
5. UPDATE      PUT new value → 200, db reflects
6. UNIQUENESS  PUT same value from another user → 422
7. DELETE      PUT null → 200, db = NULL
```

Reference: the username CRUD test in this commit verified all 7 paths against `https://tajiri.zimasystems.com` in ~5 seconds.

### Loading on buttons

Disable + spinner inside the button during async work. Never let the user double-tap submit.

```dart
ElevatedButton(
  onPressed: _saving ? null : _save,
  child: _saving
      ? const SizedBox(width: 24, height: 24, child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white))
      : Text(s?.save ?? 'Save'),
)
```

### Inline validation

- Validate field-by-field on `Form.validator` — show inline error text under the field.
- Server-side failures (save failed, network error) also go inline — see *Inline feedback, never toasts* earlier in this Part. **No SnackBars** anywhere.

### Pull-to-refresh

Every list screen has `RefreshIndicator(color: Color(0xFF1A1A1A))`. The pull-down arc is part of the design language; don't replace it with custom spinners.

### Keyboard handling

- Use `Scaffold(resizeToAvoidBottomInset: true)` — default. Don't fight it.
- Wrap forms in `SingleChildScrollView` so the focused field stays visible.
- Use `TextInputAction.next` + `FocusNode.requestFocus` to chain inputs.
- Dismiss the keyboard on tap-outside in long forms: `GestureDetector(onTap: () => FocusScope.of(context).unfocus(), behavior: HitTestBehavior.opaque)`.

### Empty / error / loading triumvirate

Every async screen handles three states explicitly. Skeletons (or shimmer) for loading, an icon+title+subtitle for empty, an icon+message+retry for error. **Never a blank screen.**

### Stale-while-revalidate

For cached data: show the stale view immediately, refresh silently in the background, surface a small "New" pill if anything changed. Never show a full-screen spinner over data the user has seen before.

## Implementation patterns

### Implicit vs explicit animations

- **Implicit** (`AnimatedContainer`, `AnimatedOpacity`, `AnimatedAlign`, `AnimatedPositioned`, `AnimatedSize`, `AnimatedSwitcher`) — when you change a value with `setState`, Flutter tweens to the new value.
  - Use for: state-driven UI changes (selected/unselected, expanded/collapsed).
  - **No `AnimationController` to manage.** Set `duration:` and `curve:`, done.

- **Explicit** (`AnimationController` + `Tween` + `XxxTransition`) — when you need direct control: replay, reverse on demand, drive multiple things from one timeline.
  - Use for: shake on error, bounce on success, complex sequences.
  - **Always dispose** the controller in `dispose()`. Always check `mounted` before any `setState` driven from the controller.

### Single-controller multi-value (Tween chains)

```dart
class _State extends State<X> with SingleTickerProviderStateMixin {
  late final AnimationController _ctrl = AnimationController(
    vsync: this, duration: MotionTokens.medium,
  );
  late final Animation<double> _fade = CurvedAnimation(
    parent: _ctrl, curve: const Interval(0.0, 0.6, curve: MotionTokens.standard));
  late final Animation<Offset> _slide = Tween<Offset>(
    begin: const Offset(0, 0.06), end: Offset.zero,
  ).animate(CurvedAnimation(
    parent: _ctrl, curve: const Interval(0.2, 1.0, curve: MotionTokens.smooth)));

  @override
  void dispose() { _ctrl.dispose(); super.dispose(); }
}
```

`Interval` lets one controller drive a fade + a slide on slightly different timings — feels richer than synchronized motion.

### Hero between routes

```dart
// Source
Hero(tag: 'post-${post.id}', child: image)
// Destination — same widget tree shape; use SingleChildScrollView around it.
Hero(tag: 'post-${post.id}', child: image)
```

Use unique IDs in the tag. If multiple Heroes share a tag on the same screen, you'll see a flicker — guarantee uniqueness.

### Transform on scroll (parallax)

```dart
return AnimatedBuilder(
  animation: _scrollCtrl,
  builder: (_, __) {
    final offset = _scrollCtrl.hasClients ? _scrollCtrl.offset : 0.0;
    return Transform.translate(
      offset: Offset(0, offset * 0.3),  // parallax: half-speed
      child: cover,
    );
  },
);
```

For app-bar headers that shrink/blur, `SliverAppBar(flexibleSpace:)` does this for free — prefer it.

### Drag handle

For modal bottom sheets, use `showDragHandle: true` on `showModalBottomSheet`. For custom sheets, draw a 40×4 pill with `Colors.grey.shade300` centered, top-padded 8px. The drag itself is handled by the sheet; the pill is signalling.

### Long-press → context menu

```dart
GestureDetector(
  onLongPress: () => showMenu(
    context: context,
    position: RelativeRect.fromLTRB(/* tap position */),
    items: [
      PopupMenuItem(child: Text(s?.copy ?? 'Copy'), onTap: _copy),
      PopupMenuItem(child: Text(s?.share ?? 'Share'), onTap: _share),
    ],
  ),
  child: child,
)
```

For lists, `ListTile.onLongPress` is built in.

## Motion performance & lifecycle

### Always dispose

`AnimationController`, `ScrollController`, `TextEditingController`, `FocusNode`, `Timer`, `StreamSubscription`, page route observers — every long-lived object initialised in `initState` must be released in `dispose`.

```dart
@override
void dispose() {
  _ctrl.dispose();
  _scrollCtrl.dispose();
  _focus.dispose();
  _debounce?.cancel();
  _sub?.cancel();
  super.dispose();
}
```

### Mounted guards across async gaps

After every `await`, check `if (!mounted) return;` before touching `setState` or `context`.

```dart
final result = await api.fetch();
if (!mounted) return;
setState(() => _data = result);
```

### Debounce scroll & resize handlers

```dart
Timer? _debounce;
void _onScroll() {
  _debounce?.cancel();
  _debounce = Timer(const Duration(milliseconds: 80), () {
    // do the heavy work
  });
}
```

### Passive scroll listeners

Flutter's scroll callbacks don't have a "passive" flag like JS does, but the equivalent rule holds: keep the synchronous portion of the scroll listener tiny. Defer any rebuilds to the next frame:

```dart
void _onScroll() {
  if (_pending) return;
  _pending = true;
  WidgetsBinding.instance.addPostFrameCallback((_) {
    _pending = false;
    if (!mounted) return;
    setState(() => _atTop = _ctrl.offset < 8);
  });
}
```

### `RepaintBoundary` for animated subtrees

Wrap an animated widget in `RepaintBoundary` if it sits inside a static parent. Prevents the parent from re-rasterising every frame.

### Avoid setState during build / scroll

Never call `setState` from a `build` method or a synchronous scroll listener — it'll throw "setState during build". Defer with `addPostFrameCallback`.

### Animations on hidden tabs

When a tab goes off-screen (`Offstage`, hidden in `IndexedStack`), pause its animations:

```dart
@override
void didChangeDependencies() {
  super.didChangeDependencies();
  final visible = TickerMode.of(context);
  if (!visible) _ctrl.stop();
}
```

`TickerMode.of(context)` reflects whether this subtree should tick.

### Reduce-motion support

```dart
final reduceMotion = MediaQuery.of(context).disableAnimations;
final duration = reduceMotion ? Duration.zero : MotionTokens.medium;
```

Apply across all animation widgets — accessibility users should never see motion they didn't ask for.

## Motion anti-patterns

| Anti-pattern | Why it's bad | Fix |
|---|---|---|
| **Bounce on every list item** | Reads as toy / unprofessional. | Standard slide+fade. Reserve bounce for milestones. |
| **Long page transitions (> 500ms)** | App feels sluggish. | Stick to platform defaults (≈300ms). |
| **Spinning forever after data loaded** | Often a `_loading = true` you forgot to flip. | Verify all branches set `_loading = false` (success AND failure paths). |
| **Animations that block scroll** | Heavy `AnimatedContainer` in a scrolled list janks. | `RepaintBoundary` around the animated subtree, or precompute the value. |
| **`setState` from a `build`** | Crashes with assertion error. | `addPostFrameCallback` if state must change after layout. |
| **Hero on a non-image, non-card item** | Distracting morph. | Heroes are for media + cards, not titles or chips. |
| **Tween from `null`** | Throws when running. | Default `begin`/`end` to non-null values. |
| **Forgetting `key` on `AnimatedSwitcher` children** | The transition skips. | Always supply distinct `ValueKey`s. |
| **Custom curves per widget** | Inconsistent feel across screens. | Use `MotionTokens.*` exclusively. |
| **Driving an animation from a rebuilding `Tween`** | New Tween every frame, no animation. | Construct Tweens in `initState` or in a late `final`. |
| **Any `SnackBar` or toast** | TAJIRI bans them — they vanish, overlap controls, and don't survive rotation. | Show feedback inline on the current screen (form-level error banner, field `errorText`, `MaterialBanner` for persistent state). Navigation IS the success confirmation. |
| **Forgetting to `dispose` controllers** | Memory leak; ticker keeps running. | Run a checklist on every Stateful screen. |
| **`AnimationController` without `vsync`** | Throws at runtime. | Use `SingleTickerProviderStateMixin` (or `TickerProviderStateMixin` for multiple). |
| **Reading `MediaQuery` in `initState`** | Crashes — context not ready. | Read in `didChangeDependencies` or `build`. |
| **Pop without `true` after a real save** | Hub doesn't know to refresh; user sees stale data. | Always `Navigator.pop(context, true)` after a confirmed-success API call. |
| **Pop with `true` on validation failure** | Hub does an unnecessary refetch and looks like the save worked. | Only `pop(true)` when the server confirmed the change. |
| **Forgetting `ProfileService.invalidate(userId)` before pop** | Hub reloads but hits the cache → shows stale data. | Invalidate the cache at the leaf, before `pop`. |
| **Invalidating cache in the hub** | Causes redundant API calls — leaf already invalidated. | Cache invalidation belongs at the leaf only. |
| **Showing a success message after pop** | Banned — navigation IS the confirmation. | Just `pop(true)`. The parent's reload reflects the change visibly. |
| **Reloading hub data unconditionally on every `.then`** | Spurious API calls when the user backs out without saving. | Gate on `if (updated == true && mounted)`. |
| **CRUD without Delete** | "Set value" without "clear value" — users can't undo a typo or remove obsolete data. | `nullable` on the validator + `PUT … null` clears. Surface a red "Remove X" button when a value exists. |
| **Validator rules differ between availability check and save endpoint** | Live check says "available" but save returns 422. | Same regex / min / max in both validators. Verified by grep + the reference test pattern. |
| **`required` validator on a nullable resource** | Backend can't accept `null` to clear → no Delete path. | `nullable` rule, then `if (value === null) save null else normalise & save`. |
| **Live availability check that returns "taken" on network error** | Falsely blocks legitimate handles when offline. | Service returns `bool?` — `null` = "couldn't check", UI doesn't show ✗ on `null`. |
| **Forgetting `Rule::unique()->ignore($id)`** | User re-saving their own value gets a 422 ("already taken — by themselves"). | Always `->ignore($currentResourceId)` on uniqueness rules. |
| **Page without an `AppBar`** | No title, no back, no context — user is lost. | Every screen renders `AppBar` / `SliverAppBar` / `TajiriAppBar`. |
| **Body without `SafeArea`** | Content under the home indicator or notch. | Wrap `body:` with `SafeArea`. |
| **Scaffold child of a Scaffold** | Two AppBars stack; doubled back buttons. | Tab content shouldn't have its own `Scaffold` — use just the body widget. |
| **`TextField` with no escape from the keyboard** | User stuck typing forever. | Tap-outside dismiss + `TextInputAction.next/done`. |
| **`resizeToAvoidBottomInset: false`** without reason | Keyboard covers the focused field. | Leave the default `true`; wrap forms in `SingleChildScrollView`. |
| **Using `WillPopScope`** | Deprecated in Flutter 3.16+. | Use `PopScope` with `onPopInvokedWithResult`. |
| **Intercepting back without an unsaved-changes reason** | Friction for no benefit; users think the back button is broken. | Reserve `PopScope` for screens with real losable state (compose, long forms). |

---

---

# Part VII — Usability & Inclusivity

> Concrete, Flutter-specific rules sourced from Apple HIG, Material 3,
> NN/g, WCAG 2.2, and the Flutter docs. These complement Part VI:
> Part VI is *what* the UI does; Part VII is *who* it works for and
> *how it feels*. Each rule has a one-line acceptance check so reviewers
> can verify it during code review.

## Highest-impact wins

If you only adopt 5 things from this Part, do these:

1. **Wrap interactive groups in `Semantics(merge: true, label: ...)`** — `IconButton`s without a label, like-icon-plus-count clusters, and avatar+name+role tiles must read as one phrase to a screen reader, not three.
2. **Set `autofillHints` and `keyboardType` on every `TextField`** — `[AutofillHints.email]` + `TextInputType.emailAddress`, `[AutofillHints.oneTimeCode]` for OTPs, plus `textInputAction: TextInputAction.next` on every field except the last.
3. **Clamp text scaling at the root** with `MediaQuery.withClampedTextScaling(minScaleFactor: 0.85, maxScaleFactor: 1.4, child: child!)` — large-font users get bigger text without breaking layout.
4. **Pick the loading affordance by latency** — < 100ms nothing, 100ms-1s spinner-in-button or shimmer, 1s+ skeleton matching the final layout, 10s+ determinate progress with cancel.
5. **Just-in-time permission asks** — never trigger an OS permission dialog from app launch; always show a custom pre-prompt with the *why* before the OS dialog fires.

## Accessibility & inclusivity

### Merge compound controls into one Semantics node
**Source:** [Flutter accessibility docs](https://docs.flutter.dev/ui/accessibility), [Somnio — Mastering Accessibility in Flutter](https://somniosoftware.com/blog/mastering-accessibility-in-flutter-a-deep-dive-into-semantics)

Screen readers read each child as a separate node by default — *"heart icon"* *"42"* *"button"* instead of *"Like, 42 likes, button"* — which is incomprehensible.

**Rule:** For compound widgets (icon + count + label, avatar + name + role, chip + badge), wrap with `MergeSemantics()` or `Semantics(container: true, label: '...')`. Apply to every `PostCard` footer button, every list-tile combining icon/title/subtitle, every chip with a count badge.

```dart
MergeSemantics(
  child: Row(children: [
    const Icon(Icons.favorite_outline),
    const SizedBox(width: 4),
    Text('$likeCount'),
  ]),
)
// or:
Semantics(
  container: true,
  label: '$likeCount likes',
  button: true,
  child: Row(children: [...]),
)
```

**Acceptance check:** Enable TalkBack/VoiceOver, swipe through the screen — each tappable region is one announcement, not three.

### Every icon-only button has a label
**Source:** [Flutter assistive technologies](https://docs.flutter.dev/ui/accessibility/assistive-technologies)

`IconButton` with no `tooltip` reads as just *"button"* to a screen reader.

**Rule:** Every `IconButton`, `GestureDetector`-on-icon, and `InkWell`-on-icon needs either `tooltip:` (which doubles as a Semantics label) or a `Semantics(label: ...)` wrapper.

**Acceptance check:** Long-press any icon shows a tooltip; VoiceOver announces a meaningful name. Grep `IconButton(` should show `tooltip:` on every match.

### Clamp `TextScaler` at the app root
**Source:** [Flutter — Deprecate textScaleFactor](https://docs.flutter.dev/release/breaking-changes/deprecate-textscalefactor), [Android 14 nonlinear text scaling migration](https://docs.flutter.dev/release/breaking-changes/android-14-nonlinear-text-scaling-migration)

iOS allows up to 3.1× text scaling; without a clamp, AppBars and tab bars overflow, buttons clip, and the app becomes unusable for high-vision-need users.

**Rule:** Wrap the `MaterialApp.builder` with:

```dart
MaterialApp(
  builder: (context, child) => MediaQuery.withClampedTextScaling(
    minScaleFactor: 0.85,
    maxScaleFactor: 1.4,
    child: child!,
  ),
)
```

Never set `textScaleFactor: 1.0` — that *defeats* accessibility. Clamp; don't disable. Replace any remaining `textScaleFactor` reads with `MediaQuery.textScalerOf(context)`.

**Acceptance check:** Set OS font to *Largest*; every screen still readable, no truncation in primary CTAs.

### Colour contrast: 4.5:1 text, 3:1 UI components
**Source:** [WCAG 2.2 §1.4.3](https://www.w3.org/WAI/WCAG22/Understanding/contrast-minimum.html), [WCAG 2.2 §1.4.11](https://www.w3.org/TR/WCAG22/)

TAJIRI's monochrome palette is high-contrast for primary text but low for secondary greys — disabled states and helper text often fail.

**Rule:** Body text against any background ≥ **4.5:1**. Large text (≥18pt or ≥14pt bold) and non-text UI (icons, borders, focus rings) ≥ **3:1**. Disabled state colours must still meet 3:1 against the surface — don't dim past `Colors.black38`.

**Acceptance check:** Run `theme.colorScheme.onSurfaceVariant` against `surface` through the WebAIM Contrast Checker; ≥ 4.5:1.

### Live regions for async UI updates
**Source:** [Flutter Semantics — liveRegion](https://api.flutter.dev/flutter/widgets/Semantics/liveRegion.html)

When a SnackBar appears or a count updates, screen readers don't announce it unless told.

**Rule:** Wrap toast/snackbar text and dynamic counts (unread badge, "3 new posts") with `Semantics(liveRegion: true, child: ...)`.

**Acceptance check:** With VoiceOver on, trigger a save success — the success message is read aloud without manual focus.

## Form input UX

### `autofillHints` is mandatory on credential fields
**Source:** [Flutter AutofillHints](https://api.flutter.dev/flutter/services/AutofillHints-class.html)

Without it, iOS Keychain and Android password managers can't fill credentials — measurable drop-off on sign-in.

**Rule:**

| Field | `autofillHints` | `keyboardType` |
|---|---|---|
| Email | `[AutofillHints.email]` | `emailAddress` |
| Password (login) | `[AutofillHints.password]` + `obscureText: true` | default |
| Password (signup) | `[AutofillHints.newPassword]` | default |
| Phone | `[AutofillHints.telephoneNumber]` | `phone` |
| OTP | `[AutofillHints.oneTimeCode]` | `number` |

Wrap a login form's two fields in `AutofillGroup` so password managers see them as a credential pair.

**Acceptance check:** On iOS, after receiving an SMS code, the keyboard suggestion bar shows the code on tap of the OTP field.

### Pair `TextInputType` with `TextInputAction`
**Source:** [Flutter TextInputAction](https://api.flutter.dev/flutter/services/TextInputAction.html)

A *Done* key on the last field and *Next* on intermediate ones saves a tap per field across every form.

**Rule:** Every `TextField` sets *both* `keyboardType` and `textInputAction`. Use `next` for intermediate fields, `done`/`send` for the last. On `onSubmitted`, advance focus or submit the form.

```dart
TextField(
  textInputAction: TextInputAction.next,
  onSubmitted: (_) => FocusScope.of(context).nextFocus(),
)
// last field:
TextField(
  textInputAction: TextInputAction.done,
  onSubmitted: (_) => _save(),
)
```

For numeric input on iOS (no return key on the numeric pad), add a keyboard accessory bar via the `keyboard_actions` package.

**Acceptance check:** Pressing the keyboard's blue button advances or submits without tapping the screen.

### Helper text for rules, error text on invalidation, hint text for example only
**Source:** [Material 3 — Text fields](https://m3.material.io/components/text-fields/guidelines)

People mix these three roles. *"Min 8 chars"* in `hintText` disappears the moment they start typing — exactly when they need it.

**Rule:**
- `labelText`: persistent name of the field. Always present.
- `helperText`: rules ("8+ chars, 1 number") — stays visible while typing.
- `hintText`: example value only ("e.g. jane@tajiri.com"); disappears on input.
- `errorText`: only after blur or submit; replaces `helperText` until resolved.

**Acceptance check:** Code review rejects any `hintText` containing *must*, *required*, or *minimum*.

### Real-time validation only after first blur
**Source:** [NN/g — Errors in Forms](https://www.nngroup.com/articles/errors-forms-design-guidelines/)

Showing *"invalid email"* while the user is on letter 3 is hostile.

**Rule:** Track a `_touched` flag per field; flip on first `FocusNode.unfocus`. Validate only when `_touched`. Re-validate live *after* the first error clears, so the user sees confirmation as they fix it.

**Acceptance check:** Type *j* in an email field — no error. Tab away — error appears. Type the rest — error clears live.

## Microcopy & button labels

### Verbs match the destination, not the action
**Source:** [Toptal — Microcopy](https://www.toptal.com/designers/ui/microcopy), [Marvel — Cancellation/Confirmation](https://marvelapp.com/blog/microcopyist-cancellation-confirmation-conflagration/)

*OK* and *Submit* force re-reading the dialog. *Delete post* / *Keep editing* are scannable.

**Rule:** Confirm button restates the action: `Delete post`, `Discard draft`, `Send Tsh 5,000`. Cancel restates the safe path: `Keep editing`, `Don't send`. Never *OK*/*Cancel* for destructive actions.

**Acceptance check:** Cover the dialog title — can a user still tell which button is destructive? If no, rename.

### Errors: specific + actionable, no "Oops"
**Source:** [UX Content Collective — error messages](https://uxcontent.com/how-to-write-error-messages/), [UX Writing Hub — error message examples](https://uxwritinghub.com/error-message-examples/)

*"Something went wrong"* gives no path forward — users retry blindly or quit.

**Rule:** Error template: `<what happened> + <why> + <what to do>`.

| Bad | Good |
|---|---|
| "Error" | "Couldn't load posts — check your connection and try again." |
| "Invalid" | "Phone must start with +255 or 0." |
| "Failed to upload" | "Upload failed — file is over 50 MB. Try a shorter clip." |

Banned words in error copy: *Oops*, *Whoops*, *Sorry*, *Something went wrong* without a follow-up.

**Acceptance check:** Every catch block surfaces an error string that names the thing that failed and a next step.

## Haptic feedback

### Map intensity to event semantics, not enthusiasm
**Source:** [Flutter HapticFeedback](https://api.flutter.dev/flutter/services/HapticFeedback-class.html), [Apple HIG — Playing Haptics](https://developer.apple.com/design/human-interface-guidelines/playing-haptics)

Over-haptic-ing every tap fatigues the user and drains battery; under-haptic-ing makes async confirmations feel ghosted.

**Rule:**

| API | Use for |
|---|---|
| `selectionClick()` | Discrete value changes — slider tick, segmented control, picker spin, sheet snap point, **drag-and-reorder start** |
| `lightImpact()` | Confirmation of a small action — toggle, like, save bookmark |
| `mediumImpact()` | Confirmation of a meaningful submit — post sent, payment confirmed, draft saved |
| `heavyImpact()` | Boundary events — pull-to-refresh trigger, drag-and-drop **drop**, long-press menu open |
| `vibrate()` | Errors only (failed login, validation). Pair with shake animation. |
| **Never** | Plain navigation (push/pop) or scroll. |

**Implementation pattern — `ReorderableList`:**
```dart
ReorderableList(
  onReorder: _handleReorder,
  onReorderStart: (_) => HapticFeedback.selectionClick(), // lift
  onReorderEnd: (_) => HapticFeedback.heavyImpact(),      // drop
  // ...
)
```

**Acceptance check:** A 30-second session through the app produces 3-8 haptic events, not 30.

## Loading-state taxonomy

### Pick affordance by expected latency, not aesthetic
**Source:** [NN/g — Response Time Limits](https://www.nngroup.com/articles/response-times-3-important-limits/), [Flutter shimmer cookbook](https://docs.flutter.dev/cookbook/effects/shimmer-loading)

Spinners feel slower than skeletons of the same duration; skeletons that don't match the final layout feel jarring.

**Rule:**

| Latency | Affordance |
|---|---|
| < 100ms | Nothing. Don't show a spinner that flashes for 50ms. |
| 100ms – 1s | Inline spinner (in button, in search bar) or shimmer placeholder. |
| 1s – 10s | Skeleton matching the final layout (use `skeletonizer` package). Disable affected interactive elements. |
| > 10s | Determinate `LinearProgressIndicator(value: ...)` with a Cancel control. |
| Streaming / unknown | Indeterminate progress + descriptive text ("Uploading 3 of 7"). |

Skeletons must use the *real* widget tree wrapped in `Skeletonizer(enabled: _loading, child: realWidget)` — not hand-drawn rectangles that diverge from the loaded layout.

**Acceptance check:** Throttle network to 3G — the skeleton matches the loaded layout pixel-for-pixel in column structure.

### Optimistic UI for like/save/follow, never for money
**Source:** TAJIRI playbook + NN/g

Users tolerate optimistic rollback on a like (it'll just un-fill); on a payment, rollback erodes trust.

**Rule:**

| Optimistic | Always-spinner |
|---|---|
| like, react, save, follow | payment, michango contribution |
| mute, block, hide | post publish |
| toggle, expand/collapse | profile change persistence |
| mark read/unread | password change, account deletion |

**Acceptance check:** Tap a like with airplane mode — UI flips, then reverts with a brief shake on the heart icon (no toast). Tap *Send Tsh 1,000* with airplane mode — spinner, then inline error banner above the submit button, no money state changed visually.

## Toast / Snackbar / Dialog / Banner / Sheet

### Pick by interruption budget × priority
**Source:** [Material 3 — Dialogs](https://m3.material.io/components/dialogs/guidelines), [Material 3 — Banner](https://m3.material.io/components/banners), [Material 3 — Bottom sheets](https://m3.material.io/components/bottom-sheets/guidelines)

> **TAJIRI bans SnackBars and Toasts entirely.** See [Inline feedback, never toasts](#inline-feedback-never-toasts) in Part VI. The matrix below has been pruned to the surfaces we actually use.

Dialogs hijack the user; banners persist; sheets host short forms. Picking the wrong one either disrupts flow or hides important info.

**Rule:**

| Surface | Use when | Duration | Action? |
|---|---|---|---|
| ~~SnackBar~~ | **Banned** — show feedback inline on the current screen, or use `MaterialBanner` for persistent states | — | — |
| ~~Toast / `Fluttertoast`~~ | **Banned** — same reason | — | — |
| **`MaterialBanner`** (top, persistent) | System-wide non-blocking state ("You're offline", "App update available", "Showing cached data"); *also* the canonical surface for undo flows that previously used SnackBars | Until dismissed or the condition resolves | Optional — typically dismiss + a contextual action |
| **`Dialog`** | Decision required, blocks flow (confirm-before-destructive, OS permission rationale) | Indefinite | At least confirm + cancel |
| **Modal `BottomSheet`** | Choices/forms with > 2 options or content > dialog height (share sheet, picker, short composer) | Indefinite | Drag-to-dismiss + close button |
| **Inline error/banner widget on the page** | Form save failure, list section couldn't load, validation errors | Until the user resolves it | Retry, dismiss, or inline action |
| **Stand-alone overlay (visual only, no text)** | Brief check-mark on copy, 1.2s shake on a failed control | < 1.5s | None |

**Acceptance check:** Grep `rg 'SnackBar\(|showSnackBar|Fluttertoast' lib/` returns zero matches in shipping code.

## Search UX

### Debounce search input at 250ms
**Source:** [Algolia — debouncing sources](https://www.algolia.com/doc/ui-libraries/autocomplete/guides/debouncing-sources)

0ms hammers the API; > 300ms feels broken.

**Rule:** Wrap `TextField.onChanged` in a debouncer. Cancel the timer in `dispose()`. Cancel any *in-flight* request when a new keystroke arrives — don't let stale results overwrite fresh ones (compare a request id).

```dart
Timer? _debounce;
void _onChanged(String q) {
  _debounce?.cancel();
  _debounce = Timer(const Duration(milliseconds: 250), () => _search(q));
}
```

**Acceptance check:** Typing *andrew* rapidly fires one request, not six.

### Zero-results state has refinements
**Source:** [Pencil & Paper — empty states](https://www.pencilandpaper.io/articles/empty-states)

*"No results"* with nothing else is a dead end.

**Rule:** Zero-result UI shows: (1) the query that failed, (2) suggestions ("Check spelling", "Try fewer words"), (3) a fallback CTA ("Browse popular" or "Clear filters"). If filter chips are active, surface a one-tap "Clear all filters".

**Acceptance check:** Search *asdfqwer* — page shows the query echoed, two suggestions, and a clear-filters affordance if filters are active.

## Permissions & disclosure

### Pre-prompt before every OS permission dialog
**Source:** [NN/g — App Permission Requests](https://www.nngroup.com/articles/permission-requests/), [Apple HIG — Privacy](https://developer.apple.com/design/human-interface-guidelines/privacy), [Adjust — ATT pre-prompt](https://www.adjust.com/blog/opt-in-design-for-apple-app-tracking-transparency-att-ios14/)

Once denied at the OS level, you can't ask again — the user must go to Settings. A pre-prompt costs one screen and roughly doubles grant rate.

**Rule:** Before calling `permission_handler` for camera/microphone/location/contacts/notifications/ATT, show a custom screen or sheet with:
- (a) the icon of the resource,
- (b) one sentence describing what TAJIRI does with it,
- (c) two buttons: primary *Continue* triggers the OS dialog; secondary *Not now* returns the user where they were.

Never trigger an OS dialog at app launch — only from the feature that needs it (tap camera button, tap *Use my location*). For ATT specifically, the pre-prompt must not bias toward *Allow* with thumbs-up emoji or visual cues.

**Acceptance check:** Cold-launch the app — no system permission dialogs. Tap *Take photo* — pre-prompt explains why, then OS dialog.

### Recovery path for denied permissions
**Source:** [permission_handler](https://pub.dev/packages/permission_handler)

`permanentlyDenied` leaves users stuck.

**Rule:** When `status.isPermanentlyDenied`, show a dialog with `openAppSettings()` as the primary action and copy that explains the toggle ("Settings → TAJIRI → Camera").

**Acceptance check:** Deny camera permission twice; tapping *Take photo* routes to Settings, not into a silent failure.

## One-handed reachability

### Primary actions in the bottom 1/3 of the screen
**Source:** [Smashing Magazine — Thumb Zone](https://www.smashingmagazine.com/2016/09/the-thumb-zone-designing-for-mobile-users/) (Steven Hoober research)

75% of phone interactions are thumb-driven; top-corner CTAs require a grip change on devices > 6.5".

**Rule:** Primary CTA lives in `bottomNavigationBar`, a `Padding`-anchored `FilledButton` at the bottom of the body, or a FAB. Never use an `AppBar` action as the *primary* affordance for a screen's main task — AppBar is for navigation/secondary actions only. On long forms, the submit button stays pinned to the bottom — don't make users scroll back down to confirm.

**Acceptance check:** Hold the device one-handed; the primary CTA on every screen is reachable without a regrip.

### FAB placement: bottom-right (LTR), 16dp margin
**Source:** [Material 3 — FAB](https://m3.material.io/components/floating-action-button/guidelines)

**Rule:** `FloatingActionButtonLocation.endFloat` (default) for primary screens, `endContained` when there's a `BottomAppBar`. Never `centerFloat` (clutters the centre tab). Hide FAB on scroll-down, restore on scroll-up via `NotificationListener<ScrollUpdateNotification>`.

**Acceptance check:** FAB is bottom-right on every screen that uses one; never overlaps a list item's primary tap target.

## Network state UI

### Offline banner is a `MaterialBanner`, not a SnackBar
**Source:** [connectivity_plus](https://pub.dev/packages/connectivity_plus), [Material 3 — Banner](https://m3.material.io/components/banners)

Offline state persists; SnackBars auto-dismiss and the user forgets.

**Rule:** Listen on `Connectivity().onConnectivityChanged` at the root. When offline, show a `MaterialBanner` *below the AppBar* with copy *"You're offline. Showing cached data."* Re-fetch on reconnection and remove the banner. **Caveat:** connection type ≠ internet access — wrap actual network calls in retry-with-backoff; don't gate them on the connectivity flag alone.

**Acceptance check:** Toggle airplane mode — banner appears within 1s, persists, disappears on reconnect.

### Last-synced timestamp on cache-backed lists
**Source:** TAJIRI playbook (stale-while-revalidate)

Trust signal — users know whether the data is fresh.

**Rule:** Cache-backed feeds (feed, messages, michango) show a small caption *"Updated 2 min ago"* near the top, with a tap-to-refresh affordance. Use `timeago` package, locale-aware (en + sw).

**Acceptance check:** Open the app offline — feed shows cached posts and *"Updated 12 min ago"*.

### Modal decision tree
**Source:** [Material 3 — Bottom sheets](https://m3.material.io/components/bottom-sheets/guidelines)

| Surface | Use when |
|---|---|
| **Dialog** (`showDialog`) | Single yes/no decision, ≤ 2 actions, no input or one-line input. Always dismissible by tapping scrim *and* a Cancel button. **Don't** scrim-dismiss for destructive confirmations — force an explicit Cancel. |
| **Modal bottom sheet** (`showModalBottomSheet`) | List of options (3+), short form, share/details pickers. Always include a drag handle and close button. Use `isScrollControlled: true` whenever there's a `TextField`. Set `useSafeArea: true`. |
| **Full-screen route** (`fullscreenDialog: true`) | Multi-step form, content creation (compose post, edit profile), anything > one screen of inputs. Close icon top-left LTR, action button top-right. |

**Acceptance check:** Any modal with a `TextField` opens with `isScrollControlled: true` and the field stays visible above the keyboard.

### Bottom-sheet snap points for draggable content
**Rule:** `DraggableScrollableSheet(initialChildSize: 0.5, minChildSize: 0.25, maxChildSize: 0.95, snap: true, snapSizes: [0.5, 0.95])`. Trigger `HapticFeedback.selectionClick()` when crossing a snap point.

**Acceptance check:** Dragging the sheet feels stepped, not slippery; haptic ticks on each snap.

## Onboarding & empty states

### First-run vs first-empty are different patterns
**Source:** [Pencil & Paper — empty states](https://www.pencilandpaper.io/articles/empty-states)

A first-run user needs orientation; a returning user with an empty list needs a single CTA.

**Rule:**
- **First-run onboarding:** max 3 screens, each with one value-prop sentence, *Skip* in the top-right *and* *Next*/*Get started* at the bottom. Persist completion to Hive.
- **First-empty** (e.g., empty saved posts, empty followed list): one illustration + one sentence + one primary CTA ("Browse posts to save"). Never show *Get started* and *Maybe later* with equal visual weight — the encouraging path is primary.

**Acceptance check:** Saved-posts screen with zero items shows the empty pattern, not a spinner.

### Multi-step flows show progress
**Source:** [NN/g — Progress indicators](https://www.nngroup.com/articles/progress-indicators/)

**Rule:** Any flow > 2 screens shows a step counter ("Step 2 of 4") or a `LinearProgressIndicator` with discrete `value`. Back must always go back one step (use `PopScope` to confirm if data would be lost — see Part VI → Page chrome).

**Acceptance check:** KYC, michango setup, post-creation flows all show step n of m.

## Undo patterns

### Default to undo, escalate to confirm only when irreversible
**Source:** [Material 3 — Snackbar](https://m3.material.io/components/snackbar/guidelines)

A confirm dialog before every delete is the slow tax of a paranoid app; Gmail-style undo is faster *and* safer (undo is one tap, dialog is two).

**Rule:**

| Reversible-with-undo (no dialog) | Confirm dialog required |
|---|---|
| archive, hide, mute | delete account |
| mark read/unread | delete a post others may have engaged with |
| delete a draft | send money |
| remove from saved | leave a group |
|   | sign out |

**Undo affordance is NOT a SnackBar.** TAJIRI uses one of two inline patterns instead:

1. **`MaterialBanner` at the top of the affected list** — appears immediately under the AppBar, copy *"Archived. Undo"*, action button on the right. Auto-dismisses after 8s (longer than the old 5s SnackBar window because it doesn't cover content). Tapping `Undo` restores the row to its original index and the banner slides away.
2. **Inline ghost row** — the archived/deleted row stays in the list rendered at 30% opacity with a small *Undo* link in place of its primary action. Auto-collapses after 8s. This is the better pattern for messaging-style lists where the user's eye is already on the row.

Pick (1) for sparse lists (saved posts, mailbox-like). Pick (2) for dense, high-frequency lists (notifications, chat archive).

On undo: re-insert at the original index and restore scroll position.

**Acceptance check:** Swipe-to-archive shows the inline undo affordance for 8s; undo restores the row in place. No SnackBar appears at the bottom of the screen.

## Flutter pitfalls

### Hero tags must be unique within a route stack
**Source:** [Flutter — Hero](https://api.flutter.dev/flutter/widgets/Hero-class.html)

Two Heroes with the same tag throw at runtime — a common bug in feeds where every card has `Hero(tag: 'avatar')`.

**Rule:** Hero tag must include the entity id: `Hero(tag: 'post-${post.id}-avatar', ...)`. For lists across multiple feeds (search, chat, feed), prefix with the list context to avoid collisions when the same user appears in multiple feeds in a tab swap.

**Acceptance check:** Open the same profile from feed, search, and chat in succession — no Hero exception in logs.

### `AnimatedSwitcher` children need distinguishing keys
**Source:** [Flutter — AnimatedSwitcher](https://api.flutter.dev/flutter/widgets/AnimatedSwitcher-class.html)

Without a key, swapping `Text("Loading")` for `Text("Loaded")` triggers no transition — Flutter sees the same widget type and reuses the element.

**Rule:** Always set `Key`s on AnimatedSwitcher children: `Text('Loading', key: ValueKey('loading'))`. For numeric counters, use `ValueKey(count)`.

**Acceptance check:** Like-count animates; loading-to-content cross-fades.

### `RepaintBoundary` only around things that animate independently
**Source:** [Flutter — Performance best practices](https://docs.flutter.dev/perf/best-practices)

Wrapping every widget in `RepaintBoundary` *increases* GPU memory because each boundary creates a new layer.

**Rule:** Use `RepaintBoundary` around: an animating progress ring next to static content, a video player in a feed, a typing-indicator dot. Don't blanket-wrap list items — `ListView.builder` already inserts boundaries around its children. Profile with the GPU rasterizer overlay before and after.

**Acceptance check:** Performance overlay shows the boundary's contents repainting in isolation, not its parent.

### `ListView.builder` with `itemExtent` for fixed-height rows
**Source:** [Flutter — Performance best practices](https://docs.flutter.dev/perf/best-practices)

**Rule:** When list rows have fixed/predictable height (chat list, contacts), pass `itemExtent: 72` (or `prototypeItem:` for variable but uniform). Skips a layout pass per item. Never use `shrinkWrap: true` + `NeverScrollableScrollPhysics` to embed a list in a scroll view — use `SliverList` inside a `CustomScrollView`.

**Acceptance check:** Long lists scroll at locked 60/120 fps in profile builds.

## Microinteractions

### Pull-to-refresh haptic at trigger threshold

**Rule:** In a custom `RefreshIndicator` or `CupertinoSliverRefreshControl`, fire `HapticFeedback.mediumImpact()` exactly when the indicator crosses the trigger threshold (not on release, not on completion). Confirms the action has armed without requiring the user to look.

**Acceptance check:** Pulling down on the feed produces one haptic tick when the spinner appears, not on every pixel of drag.

### Swipe-to-archive threshold at 40% with leave-behind reveal
**Source:** [Flutter Dismissible cookbook](https://docs.flutter.dev/cookbook/gestures/dismissible)

**Rule:** Default `dismissThresholds` of 40% is correct for archive (low-cost, undoable). For destructive-without-undo, use `confirmDismiss` returning a dialog. Always provide a coloured `background:` (red for delete, grey for archive) with the action icon — the leave-behind tells the user what will happen.

**Acceptance check:** Half-swipe reveals the icon and label; full swipe past 40% commits the action.

### Long-press preview + haptic

**Rule:** Any long-press on a content card (post, message, contact) fires `HapticFeedback.heavyImpact()` at trigger and reveals a context menu (`showMenu` or a custom sheet). Use `Feedback.forLongPress(context)` to also play the system sound.

**Acceptance check:** Long-pressing a post triggers a single haptic and a menu within 500ms.

---

*Last updated: 2026-05-01. Supersedes `PERFORMANCE_STRATEGY.md`, `PERFORMANCE_IMPLEMENTATION_PLAN.md`, `SQLITE_ADOPTION_ROADMAP.md`, `super_prompt.md`.*
