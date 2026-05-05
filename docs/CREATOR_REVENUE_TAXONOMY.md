# Creator Revenue Taxonomy

> Canonical model for how a user earns money on TAJIRI. Two top-level
> classes — **Creator** revenue (content-driven) and **Non-Creator**
> revenue (business / partnership / contributions) — each with its
> own module and primary surface.

**Status:** locked 2026-05-03
**Owner:** @andrew

---

## 1. Two top-level classes

| Class | Module | Primary screen | Question answered |
|---|---|---|---|
| **Creator Revenue** | `lib/creator/` | `CreatorRevenueScreen` | "How is my content earning?" |
| **Non-Creator Revenue** | `lib/revenue/` | `RevenueIndexPage` | "What other money is flowing in?" |

A user can have both. The split is by *origin of money*, not by user
type — every TAJIRI user is potentially both creator and merchant /
campaign-runner / partner.

---

## 2. Creator Revenue Sources (9)

Each source has its own home. Categories 1–5 live in `lib/creator/`.
Categories 6–9 are first-class top-level **modules** with their own
infrastructure (gallery widgets, services, upload flows) — not
engagement-pool slices.

| # | Category | Module | What it earns from |
|---|---|---|---|
| 1 | **Posts** | `lib/creator/` | Text + mixed posts: views, reactions, comments, shares, saves, watch-time, tips, PPV unlocks, in-post affiliate links |
| 2 | **Streams** | `lib/creator/` | Live-stream monetization: gifts, super-chats, live commerce sales |
| 3 | **Subscribers** | `lib/creator/` | Recurring monthly fan subscriptions |
| 4 | **Brand Deals** | `lib/creator/` | TAJIRI-mediated sponsored content |
| 5 | **Ad Revenue** | `lib/creator/` | Platform ad revenue share (Phase 2 of Creators Fund) |
| 6 | **My Photos** | **`lib/myphotos/`** | Engagement on the creator's photo content (views, reactions, comments, shares, saves, view-time, tips) — distinct from generic Posts |
| 7 | **My Videos** | **`lib/myvideos/`** | Engagement on the creator's video content (views, reactions, comments, shares, saves, watch-time, tips) — distinct from generic Posts |
| 8 | **My Music** | **`lib/mymusic/`** | Engagement on the creator's music tracks (plays, reactions, comments, shares, saves, listen-time, tips) — distinct from generic Posts |
| 9 | **My Files** | **`lib/myfiles/`** | Engagement on the creator's uploaded files / documents (views, reactions, comments, shares, saves, read-time, tips) — distinct from generic Posts |

**Posts ≠ My Photos / My Videos / My Music / My Files.** Posts is a
short-form social primitive (text + mixed-media). The four media
modules are dedicated content surfaces with their own galleries,
upload flows, players / viewers, and (eventually) earnings backends.
A creator thinks of "my videos" as a distinct body of work — not as
"posts that happen to have video media attached."

The four media modules each expose a top-level page reachable from:

- The Creator Revenue grid card (`lib/creator/screens/creator_revenue_screen.dart`)
- A direct route (`/my-photos`, `/my-videos`, `/my-music`, `/my-files`)
- The corresponding profile tab (Photos / Videos / Music)

---

## 3. Non-Creator Revenue Sources (4)

Located in `lib/revenue/`. Each routes to its own dedicated surface.

| # | Category | What it is | Existing screen |
|---|---|---|---|
| 1 | **My Shop** | Marketplace product sales (physical + digital goods sold via storefront) | `lib/screens/shop/seller_analytics_screen.dart` (extend) |
| 2 | **Other Businesses** | Revenue across the user's registered businesses | `lib/revenue/pages/revenue_overview_page.dart` (existing) |
| 3 | **Contributions** | Michango campaign disbursements (the user as campaign owner receiving funds) | `lib/screens/campaigns/campaign_withdraw_screen.dart` + roll-up |
| 4 | **Tajirika Partnership** | Tajirika+ partner revenue (service bookings, VIP slots, retainers) | `lib/tajirika/pages/` partner-revenue page (to build) |

These are categorically distinct from creator income — they don't
flow through the Creators Fund engine, don't have settlement
windows, and aren't multiplier-affected.

---

## 4. Why this split

### 4.1 Different mental models

A creator thinking "did my reels earn?" doesn't want shop sales mixed
in. A merchant thinking "what did my business take?" doesn't want
post tips mixed in. The split forces clarity at the index level.

### 4.2 Different settlement mechanics

| Creator side | Non-creator side |
|---|---|
| 30-day pending → cleared window | Real-time settle on each transaction |
| Multiplier-based (tier × streak × …) | Fixed take-rate (platform commission) |
| Pool-based for engagement (Phase 1) | Pass-through always |
| Anti-abuse rules apply | No anti-abuse layer (commerce primitives) |

### 4.3 Different audiences

Creator tab in profile = content creators. Non-creator revenue is
discovered from the Wallet hub or the user's business profile.

---

## 5. Information architecture

```
Profile
  └── Creator tab
       └── ★ CreatorRevenueScreen  (lib/creator/screens/creator_revenue_screen.dart)
            ├── Posts          → IncomeSourceDetailScreen (creator_fund)
            ├── Streams        → IncomeSourceDetailScreen (live_gifts)
            ├── Subscribers    → IncomeSourceDetailScreen (subscriptions)
            ├── Brand Deals    → SponsoredPostsScreen
            ├── Ad Revenue     → IncomeSourceDetailScreen (ad_share)
            ├── My Photos      → MyPhotosPage   (lib/myphotos/pages/)    ── /my-photos
            ├── My Videos      → MyVideosPage   (lib/myvideos/pages/)    ── /my-videos
            ├── My Music       → MyMusicPage    (lib/mymusic/pages/)     ── /my-music
            └── My Files       → MyFilesPage    (lib/myfiles/pages/)     ── /my-files

Wallet hub (or shortcut from creator screen)
  └── ★ RevenueIndexPage  (lib/revenue/pages/revenue_index_page.dart)
       ├── My Shop                  → SellerAnalyticsScreen (existing)
       ├── Other Businesses         → RevenueOverviewPage (existing)
       ├── Contributions            → ContributionsRevenuePage (new — wraps campaigns)
       └── Tajirika Partnership     → TajirikaRevenuePage (new)
```

Each category screen shares the same vertical layout:
- **Hero**: this-period earnings + cleared/pending breakdown
- **History**: last N transactions
- **How it works**: rate, fees, settlement timeline

---

## 6. Migration map (existing → new)

| Existing screen | New role |
|---|---|
| `IncomeSourcesView` (Mapato landing) | RENAME → `CreatorRevenueScreen` (9-card grid replaces 12-source list) |
| `IncomeSourcesScreen` (route wrapper) | KEEP — wraps `CreatorRevenueScreen` for `/creator` deep-link |
| `IncomeSourceDetailScreen` | KEEP — drill-down for any of the 9 categories |
| `IncomeActivityScreen` | KEEP — wallet activity log |
| `EarningsProvenanceScreen` | KEEP — per-event ledger |
| `CreatorEarningsDashboardScreen` | KEEP — Creators Fund engine view (Phase 1 specific) |
| `CreatorTierScreen` | KEEP — tier progression / rate card |
| `CreatorStatsScreen` + `DashboardSection` | KEEP — performance / multipliers / collaboration |
| `WeeklyReportScreen` | KEEP — weekly summary |
| `PostEarningsScreen` | KEEP — per-post breakdown |
| `SponsoredPostsScreen` | KEEP — under Brand Deals category |
| `SettingsScreen` (creator) | KEEP — preferences |

The 12 backend income sources from `GET /api/creators/{id}/income/sources`
are now grouped into the 9 creator categories on the frontend. The
backend payload doesn't change in v1 — frontend aggregates by category
on the way in.

In v2, the backend can be refactored to return the 9-category structure
natively (with each category showing summed sub-source contributions),
removing the frontend grouping.

---

## 7. Backend mapping

### 7.1 v1 — client-side reads, all media types share `creator_fund`

The current backend `IncomeSource` rows are **monetization-mechanism
buckets**, not media-type buckets. Engagement on a photo post and
engagement on a video post both currently roll up into
`creator_fund`. The taxonomy needs a media-type breakdown to surface
the 4 media-specific categories distinctly.

v1 mapping (no backend changes):

```dart
const Map<CreatorRevenueCategory, List<String>> kCategorySources = {
  CreatorRevenueCategory.posts:        ['tips', 'creator_fund', 'ppv_unlocks', 'affiliate'],
  CreatorRevenueCategory.streams:      ['live_gifts', 'super_chat', 'live_commerce'],
  CreatorRevenueCategory.subscribers:  ['subscriptions'],
  CreatorRevenueCategory.brandDeals:   ['brand_deals'],
  CreatorRevenueCategory.adRevenue:    ['ad_share'],
  // v1: no per-media-type backend split exists yet.
  // Photos / Videos / Music / Files cards open a "coming soon"
  // modal that explains the breakdown is computed at backend v2.
  CreatorRevenueCategory.photos:       <String>[],
  CreatorRevenueCategory.videos:       <String>[],
  CreatorRevenueCategory.music:        <String>[],
  CreatorRevenueCategory.files:        <String>[],
};
```

In v1, **Posts** carries the entire `creator_fund` total — including
engagement on photo/video/audio/document posts. Cards 6–9 are visible
in the grid but show TZS 0 + a "coming soon" state until v2 backend
ships the per-media-type breakdown.

### 7.2 v2 — backend extension (planned)

Backend extends `IncomeSourcesController::index` to break
`creator_fund` into 5 sub-rows by post media type:

```
creator_fund        (mixed/text)
creator_fund_image
creator_fund_video
creator_fund_audio
creator_fund_document
```

Computed by joining `earning_events.post_id → posts.post_type` and
grouping by media type. The `IncomeSource` schema doesn't change —
just the IDs returned. Frontend mapping then becomes:

```dart
CreatorRevenueCategory.posts:    ['tips', 'creator_fund', 'ppv_unlocks', 'affiliate'],
CreatorRevenueCategory.photos:   ['creator_fund_image'],
CreatorRevenueCategory.videos:   ['creator_fund_video'],
CreatorRevenueCategory.music:    ['creator_fund_audio'],
CreatorRevenueCategory.files:    ['creator_fund_document'],
```

Tips on photo/video/audio/document posts also need the same media-type
filtering — handled with a sibling `tips_image`, `tips_video`, etc.
sub-source set, or by adding a `media_type` filter param to the
endpoint.

---

## 8. Out of scope

- Renaming the backend tables / sources (deferred — v2)
- Creator tier / multiplier UI changes (already covered by separate
  IA spec at `docs/superpowers/specs/2026-05-03-creator-ia-redesign-design.md`)
- Settlement vocabulary unification (separate spec)
