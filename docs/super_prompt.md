# Deep Crawl & Fix: [ENTRY_SCREEN] — 4 Levels Deep

You are auditing and fixing the TAJIRI Flutter app at `/Volumes/DATA/PROJECTS/TAJIRI/TAJIRI-FRONTEND`. Starting from `[ENTRY_FILE_PATH]`, crawl every interactive element and navigation link, follow each to its destination, then repeat on the destination — at least 4 levels deep. At each level, identify and fix all issues.

## What to Look For (at every level)

1. **Empty handlers** — `onTap: () {}`, `onPressed: () {}`, callbacks that do nothing
2. **Stubs & placeholders** — Methods showing "coming soon" snackbars, bodies with only `// TODO` comments, placeholder text instead of real content
3. **Broken navigation routes** — Routes not registered in `lib/main.dart` `onGenerateRoute`, wrong path patterns (e.g. `/profile` instead of `/profile/{id}`), arguments passed via `arguments:` instead of path segments when the route expects path segments
4. **Missing callbacks on child widgets** — Widg ets like `PostCard`, `PostGridCell`, `CommentTile` rendered without required callbacks (`onLike`, `onComment`, `onShare`, `onSave`, `onUserTap`, `onHashtagTap`, `onMentionTap`, `onSubscribe`, `onMenuTap`, `onThreadTap`, `onReaction`) — any nullable callback left as `null` that should be wired up
5. **Compile errors** — `widget.x` used inside `StatelessWidget` (should use class field directly), wrong variable names, missing imports, type mismatches, ambiguous imports
6. **Logic bugs** — Guards preventing initialization (e.g. `bool _loading = true` + `if (_loading) return;` in the load method called from `initState`), wrong variable assignment order, state not updating after API calls
7. **Misleading UX** — Showing success feedback ("Done!", "Sent!", "Blocked!") without making any API call, confirmation dialogs that confirm but take no action
8. **Dead pages** — Screens showing empty/loading state forever because load method never fires, or calls a service method that doesn't exist
9. **Unimplemented features** — Visible UI buttons/icons/tabs that are rendered but do nothing when interacted with
10. **Missing error handling** — API calls with no try/catch, no loading states, no error feedback to user

## Crawl Method

**Level 1:** Read the entry screen file completely. Map every interactive element:
- Every `onTap`, `onPressed`, `onLongPress`, `GestureDetector`, `InkWell`, `IconButton`, `TextButton`, `ElevatedButton`, `OutlinedButton`, `PopupMenuButton`
- Every `Navigator.push`, `Navigator.pushNamed`, `showModalBottomSheet`, `showDialog`, `showMenu`
- Every API/service call (`_service.methodName()`)
- Every callback passed to child widgets

For each, record: what it does, where it navigates, what file/widget it opens, what service method it calls.

**Level 2:** Read each destination file/widget from Level 1. Repeat the same full analysis. Verify every handler is real (not empty/stub), every route exists in `main.dart`, every service method exists with correct parameter signature and return type.

**Level 3:** Read each new destination from Level 2. Same full analysis.

**Level 4:** Read each new destination from Level 3. Same full analysis.

**Deduplication:** If a destination was already crawled at a previous level (e.g. ProfileScreen appears at both Level 2 and Level 3), skip it on subsequent encounters — don't re-crawl the same file.

## How to Fix Each Issue Type

1. **Empty handlers → Implement them.** Find a working example of the same callback in another screen and replicate the pattern. If it needs a service method, verify it exists in `lib/services/`. If the service method doesn't exist, check the backend (`ssh root@zima-uat.site`, password `ZimaBlueApps`, Laravel at `/var/www/html/tajiri`) — run `php artisan route:list --path=relevant_path` to check if the API endpoint exists. If it exists, add the Flutter service method and wire it up. If the endpoint doesn't exist either, create it on the backend following existing controller patterns.
2. **Missing callbacks → Wire them.** Search codebase for other places where the same widget is used with callbacks wired up. Copy that pattern.
3. **Broken routes → Fix the path.** Read `lib/main.dart` `onGenerateRoute` to find the correct route pattern and fix the caller.
4. **Compile errors → Fix directly.** Add missing imports (with `hide` for name collisions), fix `widget.x` → field access in StatelessWidget, correct types.
5. **Logic bugs → Fix root cause.** Don't add workarounds — fix the actual initialization, variable order, or state update.
6. **Stubs → Build the feature.** Use existing services and backend APIs. Follow codebase patterns: `setState` for state, `LocalStorageService` for auth tokens, `AppStringsScope.of(context)` for i18n strings, Swahili as primary language.
7. **Dead pages → Make them load.** Fix the load method, add the missing service call, wire up the data flow.

## Codebase Conventions (follow these)

- **State management:** `setState()` in StatefulWidgets, no Provider/Bloc/Riverpod
- **Services:** Instance-based classes in `lib/services/`, methods take auth token or userId as parameter
- **Auth:** Token from `LocalStorageService.getInstance().getAuthToken()`
- **Strings:** Via `AppStringsScope.of(context)` — bilingual English/Swahili
- **Design:** Monochromatic palette (#1A1A1A dark, #FAFAFA light), 48dp min touch targets, `maxLines` + `TextOverflow.ellipsis` on dynamic text
- **Models:** `factory Model.fromJson()` with null-safe parsing helpers
- **API config:** Base URL from `ApiConfig.baseUrl`, storage URLs from `ApiConfig.storageUrl`
- **Routing:** Named routes via `Navigator.pushNamed(context, '/feature/$id')`, defined in `lib/main.dart`

## Verification

After ALL fixes are applied, run:
```bash
flutter analyze [every_modified_file]
```
**Zero errors required.** Only pre-existing `info`-level warnings are acceptable.

## Output Format

For each level, produce:

```
## Level N: [ScreenName] ([file_path])

### Interactive Elements
1. [Element] → [Destination/Action] — [Status: OK / ISSUE]
2. ...

### Issues Found & Fixed
| # | Line | Type | Description | Fix Applied |
|---|------|------|-------------|-------------|
| 1 | 142  | Empty handler | onComment: () {} does nothing | Implemented: opens CommentBottomSheet |
| 2 | 305  | Missing callback | PostCard missing onHashtagTap | Added: navigates to HashtagScreen |

### Navigation Links → Level N+1
- [Element] → [DestinationScreen] ([file_path])
```

At the end, produce a final summary:

```
## Summary

### Files Modified
- [file_path] — [brief description of changes]

### Backend Changes (if any)
- [endpoint created/modified]

### Total Issues: [X] found, [Y] fixed
| Severity | Count |
|----------|-------|
| Blocking | N     |
| Moderate | N     |
| Minor    | N     |
```

---

## Usage

Replace `[ENTRY_FILE_PATH]` with any screen file path, e.g.:
- `lib/screens/feed/feed_screen.dart`
- `lib/screens/feed/full_screen_post_viewer_screen.dart`
- `lib/screens/messages/conversations_screen.dart`
- `lib/screens/shop/shop_screen.dart`
- `lib/screens/wallet/wallet_screen.dart`
- `lib/screens/settings/settings_screen.dart`
- `lib/screens/profile/profile_screen.dart`
- `lib/screens/clips/clips_screen.dart`
- `lib/screens/groups/groups_screen.dart`
- `lib/screens/music/music_player_sheet.dart`
