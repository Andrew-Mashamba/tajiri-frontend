# Followers Manager — Design Spec

**Status:** Approved (2026-05-02)
**Owner:** Profile module
**Conforms to:** `docs/ENGINEERING_PLAYBOOK.md`

---

## 1. Goal

Give a profile owner a dedicated, full‑page tool to **manage** their
followers — search, sort, filter by audience signals, mute, remove,
block, bulk‑act, and export — without leaving the app. Visitors keep
the existing read‑only `ProfileStatsBottomSheet`.

Non‑goals (v1):
- Categories / Close Friends / Lists / Tags. Followers are a flat list.
  Friends and other groups have their own tabs and pages.
- Downstream feed/comment filtering of muted users (table + flag only;
  read‑side enforcement is a separate spec).
- Deep linking from outside the app to the manager.
- Async/email export for >50k follower lists (flagged for v2).

## 2. Design principles

1. **Owner‑only surface.** The visitor sheet is unchanged. The page is
   reachable only when `_isOwnProfile` is true.
2. **Insights are the filter.** A single dark stat card up top doubles
   as the data story and the filter control. No separate chip strip.
3. **Server‑side everything.** Search, filter, sort, paging — all
   server‑driven. Lists can be 50k+; client filtering would be wrong.
4. **Long‑press for actions.** Tap a row → view profile (the common
   case). Long‑press → action menu. Mirrors the rest of TAJIRI.
5. **No SnackBars.** Confirm dialogs for destructive actions; inline
   row badges and AppBar count for transient feedback.
6. **Idempotent endpoints.** Mute, unmute, remove, block — all safe to
   call when already in target state.
7. **Playbook compliance.** Monochrome `#1A1A1A` / `#666666` / `#FAFAFA`,
   48dp targets, `_rounded` icons, `ListView.builder`, bilingual.

## 3. Information architecture

### 3.1 Entry point

`profile_screen.dart` line 1118 — the `Followers` `_StatChip`. Branch
on `_isOwnProfile`:

```dart
onTap: () => _isOwnProfile
    ? Navigator.pushNamed(context, '/followers/manage')
    : _openStatsBottomSheet(ProfileStatsType.followers, followersCount),
```

Visitors continue to see the bottom sheet as before.

### 3.2 Route

`/followers/manage` registered in `lib/main.dart` `onGenerateRoute`.
The page reads `currentUserId` from `LocalStorageService` via
`FutureBuilder<int>`. Not signed in → pop to feed.

No `userId` in the path — only the owner can ever land here.

### 3.3 Back behavior

Standard back arrow returns to the profile. No deep links in v1.

## 4. Page anatomy

```
┌──────────────────────────────────────────────┐
│ ← Followers · 1,234                      ⋯  │  AppBar
├──────────────────────────────────────────────┤
│ ┌──────────────────────────────────────────┐ │
│ │ Total 1,234   New +47   Inactive 120  …  │ │  Insights card (dark #1A1A1A)
│ │ ↑ tappable filter pills                  │ │
│ └──────────────────────────────────────────┘ │
│ 🔍 Search by name or @handle                 │  Search field
├──────────────────────────────────────────────┤
│ ◯ avatar  Full Name             [Muted]     │  64dp row
│            @handle · 3d ago                  │
│ ◯ avatar  Full Name             [New]       │
│            @handle · just now                │
│ ...                                          │  ListView.builder
└──────────────────────────────────────────────┘
```

### 4.1 AppBar

- `elevation: 0`, `scrolledUnderElevation: 1`, white surface.
- Leading: back arrow.
- Title: `"Followers"` `w600 16`. Subtitle: `"{count} total"` /
  `"jumla {count}"`, `12 #666666`.
- Trailing: `IconButton(Icons.more_horiz_rounded)` → `PopupMenuButton`:
  - **Sort** → submenu (Newest · Oldest · A–Z; default Newest).
  - **Select** → toggles bulk mode.
  - **Export CSV** → see §6.

### 4.2 Insights card

- Container: `Color(0xFF1A1A1A)`, `BorderRadius.circular(16)`,
  `padding: EdgeInsets.fromLTRB(16, 12, 16, 8)`, margins
  `EdgeInsets.fromLTRB(16, 12, 16, 8)`.
- 4 inline tappable pills:
  | Pill | Label | Server filter |
  |---|---|---|
  | Total | `Total {n}` | none (default) |
  | New | `+{n} this week` | `followed_at >= now() - 7d` |
  | Inactive | `{n} inactive` | `last_interaction_at IS NULL OR < now() - 60d` |
  | Mutual gap | `{n} not followed back` | owner does not follow them |
- Pills are radio‑style: tapping a pill activates it; tapping the
  active pill clears back to `Total`. Active pill = bold + 1px white
  outline.
- Loading: pills render `–`, taps disabled until insights resolve.
- Network failure on insights: pills stay `–`, list continues with
  `Total` filter.

### 4.3 Search field

- `padding: EdgeInsets.symmetric(horizontal: 16, vertical: 8)`.
- `TextField`, `filled: true`, `fillColor: Colors.white`,
  `BorderRadius.circular(12)`, prefix `Icons.search_rounded`, suffix
  clear button when non‑empty.
- Placeholder: `"Search by name or @handle"` /
  `"Tafuta kwa jina au @handle"`.
- Debounced 300ms; sends `q` to the followers endpoint.

### 4.4 List

- `RefreshIndicator(color: Color(0xFF1A1A1A))` wrapping
  `ListView.builder(itemExtent: 64)`.
- Each row 64dp, white surface,
  `padding: EdgeInsets.symmetric(horizontal: 16, vertical: 12)`.
- Layout: 40dp circular avatar — title (full name, `w600 14`) —
  subtitle (`@handle · last seen 3d ago`, `12 #999999`).
- Right slot: status badge (`Muted` / `New` / `Mutual`), single‑slot,
  priority `Muted > New > Mutual`. Playbook badge style: `padding
  EdgeInsets.symmetric(horizontal: 8, vertical: 3)`,
  `borderRadius: 8`, bg = badge color @ 10% opacity.
- **Tap row** → `Navigator.pushNamed('/profile/{id}')`.
- **Long‑press row** → `follower_actions_sheet.dart`:
  View profile · Mute / Unmute · Remove follower · Block.
- Pagination: 30 per page, infinite scroll trigger at 80%.

### 4.5 Bulk mode

Entered via AppBar overflow → `Select`. Effects:

- Row layout swaps: 40dp avatar shrinks to 32dp; a `Checkbox` appears
  on the left.
- AppBar title becomes `"{n} selected"` /
  `"{n} wamechaguliwa"`, leading icon swaps to `X` (exits bulk mode).
- Long‑press disabled. Tap toggles selection.
- Bottom action bar slides in (`AnimatedSlide`, 80dp, white, top
  hairline shadow): three text buttons — `Remove` · `Mute` · `Block`.
  Hidden when 0 selected; shown when ≥1.
- Selecting a 51st row: row tap is a no‑op; the action bar shows an
  inline hint `"Up to 50 at a time"` for 2s.
- Pull‑to‑refresh disabled while in bulk mode.
- Exiting bulk mode clears `_selectedIds`.

### 4.6 Confirm dialogs

| Action | Dialog body | Confirm label |
|---|---|---|
| Remove (single) | `"Remove @{handle}? They won't be notified, but they can follow you again."` | `Remove` (red) |
| Block (single) | `"Block @{handle}? They won't be able to find your profile or content. You won't see theirs."` | `Block` (red) |
| Remove (bulk) | `"Remove {n} followers? They won't be notified."` | `Remove` (red) |
| Mute (bulk) | `"Mute {n} followers?"` | `Mute` |
| Block (bulk) | `"Block {n} followers? They won't be able to find your profile."` | `Block` (red) |

Mute (single) **does not** show a confirm dialog — instant, with the
row badge updating to `Muted`.

Destructive confirm buttons use semantic red `#D32F2F`.

### 4.7 Empty / loading / error

- **Loading:** `CircularProgressIndicator(strokeWidth: 2, color:
  Color(0xFF1A1A1A))` centered.
- **Empty (no followers at all):** `Icons.group_outlined` 64px
  `grey.shade300` + `"No followers yet"` 16 `grey.shade500` +
  `"Share your profile to get started"` 13 `grey.shade400`.
- **Empty (filter returned 0):** same treatment, contextual subtitle
  per filter (`"No inactive followers"` / `"Everyone follows you back"`),
  + an outlined `Clear filter` button.
- **Error:** icon + message + outlined `Retry` button.

## 5. Data contracts

### 5.1 Follower row

```json
{
  "id": 42,
  "name": "Jane Doe",
  "username": "jane",
  "photo_url": "https://.../avatar.jpg",
  "followed_at": "2026-04-29T10:11:12Z",
  "last_interaction_at": "2026-04-15T08:00:00Z",
  "is_mutual": true,
  "is_muted": false
}
```

`last_interaction_at` = `MAX(timestamp)` across `post_likes`,
`post_comments`, `post_reactions`, `post_shares` filtered to posts
owned by the page owner and actor = the follower. `null` ⇒ never
interacted.

### 5.2 Insights

```json
{
  "total": 1234,
  "new_this_week": 47,
  "inactive_60d": 120,
  "mutual_gap": 89
}
```

### 5.3 Sort

| `sort` | ORDER BY |
|---|---|
| `newest` (default) | `followed_at DESC` |
| `oldest` | `followed_at ASC` |
| `name` | `coalesce(first_name,'')||last_name ASC, username ASC` |

### 5.4 Search

`q` is `ilike`‑matched on `username` (prefix) OR
`concat(coalesce(first_name,''), ' ', coalesce(last_name,''))`
(substring). Leading `@` stripped. Same pattern as
`PartnerController::search`.

## 6. Backend contract

### 6.1 Reused

- `POST /api/users/block` — single block.
- `POST /api/users/unblock` — single unblock.
- `GET /api/users/{id}/followers` — backs the visitor bottom sheet
  when no filter/sort/q is supplied.

### 6.2 Extended

`GET /api/users/{id}/followers` gains optional query params:

| Param | Values |
|---|---|
| `q` | string ≤64, leading `@` stripped |
| `filter` | `new` \| `inactive` \| `mutual_gap` |
| `sort` | `newest` \| `oldest` \| `name` |
| `page`, `per_page` | already exist |

Each row now carries `last_interaction_at`, `is_mutual`, `is_muted`.
**Owner‑only when any of `q`/`filter`/`sort` is passed** (other
callers continue to use it without filters).

### 6.3 New endpoints

| Method | Path | Body / Notes |
|---|---|---|
| GET | `/users/{id}/followers/insights` | → `{total, new_this_week, inactive_60d, mutual_gap}`. Owner‑only. |
| DELETE | `/users/{id}/followers/{followerId}` | Idempotent remove. Owner‑only. |
| POST | `/users/{id}/followers/bulk-remove` | `{ids: [int]}` ≤50 → `{removed: N}`. Transactional. |
| POST | `/users/{id}/mutes` | `{muted_user_id}` → idempotent insert. |
| DELETE | `/users/{id}/mutes/{mutedUserId}` | Idempotent. |
| POST | `/users/{id}/mutes/bulk` | `{ids: [int]}` ≤50 → `{muted: N}`. |
| POST | `/users/block-bulk` | `{user_id, blocked_user_ids: [int]}` ≤50 → `{blocked: N}`. |
| GET | `/users/{id}/followers/export.csv` | `Content-Disposition: attachment; filename="followers-YYYY-MM-DD.csv"`. Owner‑only. v1 cap 50k rows. |

All return the standard envelope `{success, data, message}` (CSV
endpoint excepted — returns raw `text/csv`).

### 6.4 Auth

Every owner‑only route enforces `auth()->user()->id ===
path_user_id`, else `403 {success:false, message:"Forbidden"}`.

### 6.5 New table

```
user_mutes
  id              bigint pk
  muter_user_id   bigint  fk user_profiles(id) ON DELETE CASCADE
  muted_user_id   bigint  fk user_profiles(id) ON DELETE CASCADE
  created_at      timestamp
  UNIQUE(muter_user_id, muted_user_id)
  INDEX(muter_user_id)
  INDEX(muted_user_id)
```

### 6.6 Performance notes

`last_interaction_at` is derived live as a `MAX()` over four
interaction tables, computed only for the 30 paginated rows on a
page. Adequate up to ~10k followers per owner. First creator past
that threshold triggers denormalization (a `user_engagement_summary`
table updated by triggers/jobs) — out of scope here.

CSV export streams rows directly with `fputcsv`; cap 50k. Beyond that
we shift to an async job + email link — flagged for v2.

## 7. Frontend file layout

```
lib/screens/profile/followers/
  followers_manage_screen.dart        # page shell + state
  followers_insights_card.dart        # dark stat card with tappable pills
  follower_row.dart                   # 64dp row, bulk-mode aware
  follower_actions_sheet.dart         # long-press menu, returns enum
```

`lib/services/friend_service.dart` gains:

```
getOwnerFollowers({userId, page, perPage, q, filter, sort})
getFollowerInsights({userId})
removeFollower({userId, followerId})
bulkRemoveFollowers({userId, ids})
muteUser({userId, mutedUserId})
unmuteUser({userId, mutedUserId})
bulkMuteUsers({userId, ids})
bulkBlockUsers({userId, ids})
exportFollowersCsv({userId})  // Dio download → temp file path
```

`lib/models/friend_models.dart`:
- Extend the existing follower row model with `DateTime?
  lastInteractionAt`, `bool isMutual`, `bool isMuted` (defaults when
  fields absent — backwards compatible with the visitor sheet).
- Add `class FollowerInsights({total, newThisWeek, inactive60d, mutualGap})`.

`lib/main.dart` — add `case '/followers/manage':` to
`onGenerateRoute`, resolving `currentUserId` via `FutureBuilder<int>`
the same way other user‑id‑gated routes do.

`lib/screens/profile/profile_screen.dart` — change the `Followers`
`_StatChip.onTap` (line 1118) to branch on `_isOwnProfile`.

## 8. State machine (page)

```
initial
  → fetching insights + followers (page=1, no filter)
  → idle

idle
  ── row tap ──────────────────────> push /profile/{id}
  ── row long-press ──────────────> action sheet (view/mute/remove/block)
  ── search edit (debounced 300ms) ──> reset page=1, refetch
  ── filter pill tap ──────────────> reset page=1, refetch
  ── sort change ─────────────────> reset page=1, refetch
  ── pull-to-refresh ─────────────> refetch insights + followers
  ── scroll 80% ──────────────────> append next page
  ── overflow Select ─────────────> bulkMode = true, selectedIds = {}

bulkMode
  ── row tap ──────────────────────> toggle selectedIds (cap 50)
  ── action button ────────────────> confirm dialog → call bulk endpoint → refetch
  ── close X ──────────────────────> bulkMode = false, selectedIds = {}
```

In‑flight requests are cancelled when the user changes filter/sort/q.

## 9. Bilingual strings

Inline ternaries (`isSwahili ? sw : en`) matching the partner row
pattern. Adding `AppStrings` getters only for strings reused
elsewhere.

| Context | English | Swahili |
|---|---|---|
| Page title | Followers | Wafuasi |
| Search placeholder | Search by name or @handle | Tafuta kwa jina au @handle |
| Sort menu | Newest / Oldest / A–Z | Mpya / Wa zamani / A–Z |
| Overflow — Select | Select | Chagua |
| Overflow — Export CSV | Export CSV | Hamisha CSV |
| Bulk title | `{n} selected` | `{n} wamechaguliwa` |
| Bulk cap hint | Up to 50 at a time | Hadi 50 kwa wakati mmoja |
| Action — View profile | View profile | Tazama wasifu |
| Action — Mute / Unmute | Mute / Unmute | Nyamazisha / Achilia |
| Action — Remove follower | Remove follower | Ondoa mfuasi |
| Action — Block | Block | Zuia |
| Empty (no followers) | No followers yet | Hujapata wafuasi bado |
| Empty (no followers sub) | Share your profile to get started | Shiriki wasifu wako kuanza |
| Badge — New / Mutual / Muted | New / Mutual / Muted | Mpya / Pande zote / Imenyamazishwa |
| Confirm Remove | Remove `@x`? They won't be notified, but they can follow you again. | Ondoa `@x`? Hawatajulishwa, lakini wanaweza kukufuata tena. |
| Confirm Block | Block `@x`? They won't be able to find your profile or content. You won't see theirs. | Zuia `@x`? Hawataweza kupata wasifu au maudhui yako. Wewe pia hutaona yao. |

## 10. Edge cases

- Filter / sort / search change → cancel in‑flight, reset page=1.
- Bulk selections survive paginated loads (`Set<int>`); cleared on
  bulk‑mode exit.
- 51st row select: row tap no‑op; action bar shows cap hint inline 2s.
- Bulk action partial failure: backend wraps each batch in a
  transaction; on failure returns `{success:false, message}`; FE shows
  retry confirm and refetches.
- Already muted/blocked: idempotent endpoints.
- Self in result set: backend filters `auth_user_id` defensively.
- Insights network failure: pills `–`, non‑tappable; list still loads.
- Pull‑to‑refresh while bulk mode: disabled.

## 11. Performance

- `ListView.builder` `itemExtent: 64`.
- Avatars via `CachedNetworkImage` `memCacheWidth: 80` (40dp × 2 DPR).
- Insights cached page lifetime; refetched on pull‑to‑refresh.
- Search debounce 300ms.
- 30 rows per page; next fetch at 80% scroll.

## 12. Playbook compliance checklist

- [x] Monochrome palette (`#1A1A1A` / `#666666` / `#999999` / `#FAFAFA`)
- [x] Semantic red `#D32F2F` only on destructive confirm buttons
- [x] 48dp+ touch targets on every interactive element
- [x] `_rounded` Material icons
- [x] `maxLines` + `TextOverflow.ellipsis` on every dynamic string
- [x] `Scaffold.backgroundColor: #FAFAFA`
- [x] `AppBar(elevation: 0, scrolledUnderElevation: 1)`
- [x] `BorderRadius.circular(12-16)` on cards & inputs
- [x] No FAB — overflow menu instead
- [x] No SnackBars — confirm dialogs + inline cap hint
- [x] `RefreshIndicator(color: #1A1A1A)`
- [x] Dark `CircularProgressIndicator(strokeWidth: 2)`
- [x] Empty + error states with retry
- [x] Bilingual (English default, Swahili via `isSwahili` ternaries)
- [x] `ListView.builder` (lists exceed 50)
- [x] `{success, data, message}` envelope on every JSON endpoint
- [x] Service is instance‑based, takes `userId` parameter

## 13. Build sequence

1. Backend migration (`user_mutes`).
2. Backend `FollowersController` with the 8 new endpoints + extended
   list endpoint. Smoke‑test via curl.
3. Frontend models + service methods. Unit‑smoke via a throwaway
   screen.
4. Frontend `followers_manage_screen.dart` shell with insights +
   list + search; no actions yet.
5. Per‑row long‑press menu + single‑item actions (view, mute,
   remove, block) wired to confirm dialogs.
6. Bulk mode (multi‑select + bottom action bar + bulk endpoints).
7. Export CSV (Dio download + share sheet).
8. Empty / error / loading polish; copy review (English + Swahili).
9. Self‑audit against §12.

Each step ships independently and leaves the page in a working state.
