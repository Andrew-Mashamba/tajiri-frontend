# Creator IA Redesign — Design Spec

> Reorganize the 12 creator screens around the creator's mental model
> rather than the data model. Replace 4 overlapping "earnings landings"
> with 3 focused hubs answering one clear question each. Unify 3
> incompatible settlement vocabularies into a single money-journey.

**Status:** drafted 2026-05-03, awaiting review
**Author:** @andrew
**Replaces:** ad-hoc layout in `lib/creator/screens/{creator_earnings_dashboard, creator_stats, creator_tier, dashboard_section, earnings_provenance, income_activity, income_source_detail, income_sources, post_earnings, settings, sponsored_posts, weekly_report}_screen.dart`

---

## 1. Problems with the current IA

The current creator surface has 12 screens that **show overlapping
data in conflicting forms**. Audit findings (from the IA inventory):

### 1.1 Four overlapping "earnings landings"
- `IncomeSourcesView` — wallet balance + period KPIs + source list
- `CreatorEarningsDashboardScreen` — total cleared/pending + 6-stream breakdown
- `WeeklyReportScreen` — single-week trend + best post
- `PostEarningsScreen` — single-post breakdown

All four claim to show "your earnings". A creator landing on any one
sees *some* of the picture; needs to bounce between three to get the
whole.

### 1.2 Three incompatible settlement vocabularies
- Earnings: **cleared / pending**
- Wallet activity: **completed / settled / processing / failed**
- Provenance ledger: **cleared / pending / reversed**

A creator can't tell whether "pending" in earnings = "pending" in
wallet activity. They aren't.

### 1.3 No money-journey timeline
No screen explains: *event → earned → clearing → available → withdrawn → settled to bank*.
The 30-day clearing window is mentioned only on the dashboard hero
sub-line. The relationship between earnings clearing and wallet
withdrawal is implicit.

### 1.4 Multipliers hidden across 3 screens
`tier × streak × community × virality` shown in `dashboard_section`.
Rate-per-metric in `creator_tier_screen` rate card. Per-event applied
multiplier in `earnings_provenance_screen` math row. To answer "why
did this view earn 1.0 TZS not 0.5?" the creator must navigate three
screens.

### 1.5 No "what should I do next" answer
Weekly tip card on `WeeklyReportScreen` is a generic blurb. Nothing
shows: "your community multiplier would double if you replied to 10
more comments this week."

### 1.6 No tier-progression visibility
`CreatorTierScreen` shows tier blurbs ("Unlocks Discovery Mode") but
not the gates. Creator can't see "you need 50 more followers to reach
Verified."

### 1.7 Sponsored Posts is misplaced
`SponsoredPostsScreen` is a brand-discovery surface for *advertisers
browsing creators* — not a creator self-view. It sits in the creator
hub but answers a buyer's question, not the creator's.

---

## 2. The creator's actual mental model

A creator opens the app asking one of three questions:

| Question | What they want to see |
|---|---|
| **"How much have I earned and when do I get paid?"** | Money flow: total earned, pending clearing, available to withdraw, journey timeline |
| **"What's working and what could work better?"** | Performance: trends, best post, multipliers, levers I can pull |
| **"What's locked and how do I unlock it?"** | Progression: tier gates, source eligibility, accelerators |

The current 12 screens are a data-model decomposition (one screen per
table). The redesign is a question-model decomposition (one hub per
mental model).

---

## 3. New information architecture

### 3.1 Three primary hubs

| Hub | Question answered | Replaces |
|---|---|---|
| **MAPATO** ("Money") | How much / when paid? | IncomeSourcesView + CreatorEarningsDashboardScreen + IncomeActivityScreen + EarningsProvenanceScreen |
| **MAFANIKIO** ("Performance") | What's working / how to grow? | CreatorStatsScreen + DashboardSection + WeeklyReportScreen + CreatorTierScreen (tier-progress portion) |
| **MIONGOZO** ("Rules" / "How it works") | What are the rates and rules? | CreatorTierScreen (rate card) + a new "money journey" explainer |

`SponsoredPostsScreen` moves OUT of the creator module (it's a buyer
surface, belongs under brand-deals or marketplace).

`PostEarningsScreen` stays as a per-post detail reachable from
`PostDetailScreen` (good UX, one tap from the post).

`SettingsScreen` stays as creator preferences, reachable from each
hub via a shared "Preferences" entry.

### 3.2 MAPATO — the Money hub

**One screen. One question: where's my money?**

```
┌─────────────────────────────────────────────────────┐
│ Mapato                              [⋯ Preferences] │
├─────────────────────────────────────────────────────┤
│  ┌─ MONEY-JOURNEY HERO ────────────────────────┐   │
│  │  Available now    TSh 12,450                │   │
│  │  Clearing soon    TSh  3,200 ▸ 5 days       │   │
│  │  Pending earning  TSh    180 ▸ Mon midnight │   │
│  │                                              │   │
│  │  [ Withdraw ]   [ Activity ]                 │   │
│  └──────────────────────────────────────────────┘   │
├─────────────────────────────────────────────────────┤
│  Period: [ Week ] Month  Quarter  All               │
├─────────────────────────────────────────────────────┤
│  THIS WEEK   12,450 TZS   ▲ 18% vs prev             │
│  Top source: Engagement Pool · 62%                  │
│  Active: 4 of 12 sources                            │
├─────────────────────────────────────────────────────┤
│  EARNING NOW                                         │
│  ⚡ Engagement Pool      8,200 ▸                    │
│  ❤️ Fan Funding          2,100 ▸                    │
│  🛍️ Marketplace          1,400 ▸                    │
│  🎁 Live Gifts             750 ▸                    │
├─────────────────────────────────────────────────────┤
│  LOCKED — UNLOCK AVAILABLE                           │
│  💎 Subscriptions  47% ▸ "verify account"           │
│  🤝 Brand Deals    33% ▸ "1,000 followers"          │
├─────────────────────────────────────────────────────┤
│  [ See all events / disputes ]   [ How it works ]   │
└─────────────────────────────────────────────────────┘
```

**Money-journey hero** replaces the dual hero (current
`CreatorEarningsDashboardScreen` "Cleared / Pending / Estimated" +
`IncomeSourcesView` wallet balance). One unified flow:

- **Available now** = `walletBalance` from IncomeSummary (cleared +
  withdrawn-to-wallet, ready to disburse)
- **Clearing soon** = `totalPending` from CreatorEarningsDashboard
  (events in 30-day pending window) + countdown to next sweep
- **Pending earning** = `estimatedThisPeriodTsh` (current fund period
  estimates, not yet finalized) + countdown to Monday midnight

This single hero answers the #1 creator question: *where's my money?*
Three buckets, each with a date — clear timeline, not just numbers.

**Period KPI row** — kept from IncomeSourcesView (this period delta,
top source, active count).

**Source list** — kept from IncomeSourcesView, but split into two
explicit groups: "Earning now" (active) and "Locked — unlock
available" (locked) with progress %. Removes the filter-chip indirection
("All / Active / Locked") which forces the creator to think about the
filter; the new layout shows both groups by default.

**Footer links**:
- `[ See all events / disputes ]` → existing `EarningsProvenanceScreen` (rename header to "Tukio kwa tukio" / "Event by event")
- `[ How it works ]` → MIONGOZO hub

**Drill-down**: tap any source → existing `IncomeSourceDetailScreen` (no change to that screen — it's well-designed).

**Tap "Activity"** → existing `IncomeActivityScreen` for wallet-side transaction log (different concept from earnings; explicit label clarifies).

### 3.3 MAFANIKIO — the Performance hub

**One screen. One question: how do I grow?**

```
┌─────────────────────────────────────────────────────┐
│ Mafanikio                          [⋯ Preferences] │
├─────────────────────────────────────────────────────┤
│  ┌─ TIER & MWANZO ─────────────────────────────┐   │
│  │  ★ Standard tier                             │   │
│  │  Mwanzo Boost: 12 days left · 2× active     │   │
│  │                                              │   │
│  │  Next tier: Verified                         │   │
│  │  ━━━━━━━━━━━━━━░░ 73% — 50 followers to go  │   │
│  │                                              │   │
│  │  At Verified you unlock:                     │   │
│  │  • Brand-deal marketplace                    │   │
│  │  • 92.5/7.5 split on live gifts              │   │
│  └──────────────────────────────────────────────┘   │
├─────────────────────────────────────────────────────┤
│  THIS WEEK                                           │
│  +12,450 TZS  ▲ 18%   Engagement up                 │
│  Best post:   "Tuko Live..."  ▸                     │
├─────────────────────────────────────────────────────┤
│  YOUR MULTIPLIERS                                    │
│  Tier         1.0×    standard tier                 │
│  Streak       1.10×   ▴ post 5/7 days locked it     │
│  Community    1.30×   reply to 10 more comments →   │
│  Virality     0.85×   one shareable post away       │
│  Total combined: 1.22×                              │
├─────────────────────────────────────────────────────┤
│  COLLABORATION RADAR                                 │
│  [ existing CollaborationCard widgets ]             │
├─────────────────────────────────────────────────────┤
│  CONTENT CALENDAR                                    │
│  3 drafts · 5 posts this week · 2 scheduled         │
│  Best time to post: 8:00 PM Friday                  │
├─────────────────────────────────────────────────────┤
│  [ Weekly report ]   [ Analytics ]                  │
└─────────────────────────────────────────────────────┘
```

**Tier card** — Tier badge (existing `CreatorTierBadge` widget) +
Mwanzo countdown (NEW: from `mwanzoExpiresAt`) + **explicit next-tier
progress bar with what's needed** (NEW field requirement on backend)
+ "what unlocks" list. Solves Gap #1.7 from the audit.

**This-week summary** — Pulled from `WeeklyReport` model. Shows
`totalEarnings`, `earningsChangePercent`, `engagementTrend`,
`bestPostId` ▸ best-post link. Replaces the entire `WeeklyReportScreen` —
the data was already small enough to fit inline.

**Multipliers section** — Currently in `dashboard_section.dart`. Keep
the structure but **enrich each row with a "lever"** (NEW): "post 5/7
days" for streak, "reply to 10 more comments" for community. Solves
Gap #2.

**Collaboration radar** — Kept from `dashboard_section.dart`.

**Content calendar** — Kept from `dashboard_section.dart`.

**Footer**:
- `[ Weekly report ]` → DEPRECATE `WeeklyReportScreen` since data is now inline. (Keep route for FCM deep-links — render this hub.)
- `[ Analytics ]` → existing `/analytics/{userId}` (untouched).

### 3.4 MIONGOZO — the Rules hub

**Reference page. Static-ish.**

```
┌─────────────────────────────────────────────────────┐
│ Miongozo — How earnings work                        │
├─────────────────────────────────────────────────────┤
│  THE MONEY JOURNEY                                   │
│  ┌──────┐  ┌────────┐  ┌─────────┐  ┌──────────┐   │
│  │EARNED│→ │PENDING │→ │AVAILABLE│→ │WITHDRAWN │   │
│  │      │  │30 days │  │         │  │ to bank  │   │
│  └──────┘  └────────┘  └─────────┘  └──────────┘   │
│  Caption explaining each stage with examples         │
├─────────────────────────────────────────────────────┤
│  YOUR FOUR TIERS                                     │
│  [ existing tier cards from CreatorTierScreen ]     │
├─────────────────────────────────────────────────────┤
│  RATE CARD                                           │
│  By stream:                                          │
│   ⚡ Engagement   view 0.5 · reaction 2.0 · …       │
│   ❤️ Fan Funding  subscription 95% · tip 95% · …    │
│   …                                                  │
├─────────────────────────────────────────────────────┤
│  HOW MULTIPLIERS WORK                                │
│  Tier · Streak · Community · Virality · Mwanzo      │
│  Worked example                                      │
└─────────────────────────────────────────────────────┘
```

**Money-journey diagram** — NEW. Single graphic explaining the four
stages with concrete examples. Solves the #1 mental-model gap.

**Tier cards** — From existing `CreatorTierScreen`.

**Rate card** — From existing `CreatorTierScreen` (`rates_by_stream`
section).

**How multipliers work** — NEW. One worked example: "1 view × 0.5
TZS × 2× Mwanzo × 1.10× streak × 1.5× watch-completion = 1.65 TZS net".

Reachable only via the "How it works" link in MAPATO and a "Rules"
link in MAFANIKIO. Not a primary nav target.

### 3.5 Settlement taxonomy unification

Single vocabulary across all screens:

| Stage | What it means | Was called |
|---|---|---|
| **Earning** | Active period, not yet final | "Pending earning" / "Estimated" |
| **Clearing** | Final but in 30-day window | "Pending" (earnings) / "Pending" (wallet) |
| **Available** | Cleared, ready to withdraw | "Cleared" / "Completed" (wallet) |
| **Withdrawn** | Sent to creator's wallet/bank | "Settled" |
| **Reversed** | Disputed and rolled back | "Reversed" |

Five stages. One color-coded set of pills used everywhere. Solves
Problem 1.2.

### 3.6 Navigation tree

```
Profile
  └── Creator tab
       └── ★ MAPATO  (was IncomeSourcesView, restructured)
            ├── Activity     → IncomeActivityScreen   (kept)
            ├── Source detail → IncomeSourceDetailScreen (kept)
            ├── See all events → EarningsProvenanceScreen (kept)
            └── How it works  → MIONGOZO

  └── Profile button row
       └── ★ MAFANIKIO (new screen, consolidates Stats + Dashboard + WeeklyReport)
            ├── Weekly report → MAFANIKIO itself (route maps here)
            └── Analytics    → /analytics/:id (kept)

  └── Settings
       └── Creator preferences → SettingsScreen (kept)

(Deprecated)
  CreatorEarningsDashboardScreen — content folded into MAPATO hero
  CreatorTierScreen              — content folded into MAFANIKIO + MIONGOZO
  CreatorStatsScreen             — content folded into MAFANIKIO
  CreatorDashboardSection        — embedded into MAFANIKIO
  WeeklyReportScreen             — content folded into MAFANIKIO

(Moved out)
  SponsoredPostsScreen — moves to brands/marketplace section
                         (not a creator self-view)

(Per-post)
  PostEarningsScreen — kept, reachable from PostDetailScreen
```

### 3.7 Screen-by-screen migration

| Old screen | New home |
|---|---|
| IncomeSourcesView | MAPATO landing (refactored hero + grouped sources) |
| IncomeSourcesScreen | MAPATO standalone wrapper for `/creator` deep-link |
| IncomeSourceDetailScreen | Drill-down from MAPATO source row (no change) |
| IncomeActivityScreen | Drill-down from MAPATO "Activity" button (no change) |
| EarningsProvenanceScreen | Drill-down from MAPATO "See all events" (rename header) |
| CreatorEarningsDashboardScreen | DEPRECATE — content → MAPATO hero |
| CreatorStatsScreen | RENAME → MafanikioScreen (reorganize content) |
| CreatorDashboardSection | DEPRECATE — content → MAFANIKIO sections |
| CreatorTierScreen | DEPRECATE — tier-progress → MAFANIKIO; rate card → MIONGOZO |
| WeeklyReportScreen | DEPRECATE — content → MAFANIKIO; route still resolves there |
| PostEarningsScreen | KEEP unchanged |
| SponsoredPostsScreen | MOVE to brand-deals section (out of creator module) |
| SettingsScreen | KEEP, accessible from each hub |

### 3.8 Backend additions required

To populate the new MAFANIKIO tier card with progression:

```
GET /api/users/me/tier-progress?user_id=...
{
  "current_tier": "standard",
  "next_tier": "verified",
  "gates": [
    {
      "key": "followers", "label": "Followers",
      "current": 950, "target": 1000, "done": false
    },
    {
      "key": "views_30d", "label": "Views (30 days)",
      "current": 53000, "target": 50000, "done": true
    },
    {
      "key": "is_id_verified", "label": "ID verified",
      "current": null, "target": null, "done": false
    },
    {
      "key": "max_strikes_90d", "label": "No strikes (90 days)",
      "current": 0, "target": 0, "done": true
    }
  ],
  "completion_pct": 75.0,
  "primary_blocker_key": "is_id_verified",
  "unlocks_at_next_tier": [
    "Brand-deal marketplace",
    "92.5/7.5 split on live gifts"
  ]
}
```

To populate the multiplier "lever" hints:

```
GET /api/users/me/multiplier-levers?user_id=...
{
  "tier":      { "value": 1.0,  "lever": null },
  "streak":    { "value": 1.10, "lever": "Post 5 of last 7 days · already locked" },
  "community": { "value": 1.30, "lever": "Reply to 10 more comments to reach 1.5×" },
  "virality":  { "value": 0.85, "lever": "One shareable post would push this to 1.0×" },
  "mwanzo_boost": { "value": 2.0, "lever": "Active for 12 more days" },
  "combined":  1.22
}
```

Both endpoints are net-new. Backend implementation is mechanical:
read existing tier rows + recent engagement + recent posts, format
into the gate / lever shape.

---

## 4. Open questions

1. **Should MAFANIKIO be a tab in profile, or a separate route?** —
   Current proposal: separate route reachable from profile +
   `/creator-stats` deep-link (the existing `CreatorStatsScreen` route).

2. **Should `CreatorEarningsDashboardScreen` be deleted or kept as a
   redirect?** — Recommend redirect to MAPATO for FCM payloads
   already in flight.

3. **`SponsoredPostsScreen` new home?** — Out of scope for this spec;
   flag for partner-c2b owner to decide.

4. **Should the "money journey" diagram be interactive?** — V1: static
   diagram with worked example. V2: tap a stage → highlight events
   currently in that stage.

5. **MAFANIKIO multipliers section — show levers always, or only
   when user opts in?** — Recommend always-on; the levers are the
   actionable insight. Hiding them defeats the purpose.

---

## 5. What this is NOT

- Not a backend rewrite — existing API contracts mostly preserved,
  two net-new endpoints added.
- Not a redesign of the per-source `IncomeSourceDetailScreen` —
  that screen is well-designed; just changing its entry point.
- Not removing the per-post earnings drill-down — keeping
  `PostEarningsScreen` exactly as-is.
- Not changing `SettingsScreen` content — only its discoverability.
