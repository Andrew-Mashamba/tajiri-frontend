# Strategy Alignment — `docs/creators/strategy.md`

Per-item status of the implementation against the 12 strategy points.
Date: 2026-05-04. Source of truth: `docs/creators/strategy.md`.

Where this doc and `docs/post_earnings_tajiri_strategy.md` diverge,
this doc wins (per strategic re-pivot 2026-05-04).

---

## Status legend

| Tag         | Meaning                                              |
| ----------- | ---------------------------------------------------- |
| ✅ Aligned   | Implementation matches the strategy.                  |
| 🟡 Partial  | Some surface; gaps documented below.                  |
| 🔧 Backend  | Frontend ready; backend work outstanding.             |
| 🚧 Deferred | Multi-week infra; planned, not yet started.           |

---

## 1) Three earning layers (direct / context-chain / derivative)

**Status:** 🟡 Partial → ✅ Aligned (frontend)

**Done (this pass):**
- `PayoutLayer` enum added to `lib/creator/models/creator_earnings_models.dart`
  with `direct | context | derivative | distribution` plus bilingual labels
  + descriptions + share-band labels.
- `payoutLayerFor(actorRole, metric)` classifier wired into
  `EarningEventItem.layer` and `MetricBreakdownRow.layer` extensions.
- `AttributionLayersCard` widget renders the four layers as an
  educational card on `PostEarningsScreen` and
  `CreatorEarningsDashboardScreen`.

**Remaining:**
- 🔧 Backend should emit a `payout_layer` field directly on
  `earning_events` so the frontend doesn't need to compute it.
  Migration: `ALTER TABLE earning_events ADD COLUMN payout_layer
  text` + backfill from `actor_role`.

---

## 2) Engagement payout vs. royalty payout separation

**Status:** ✅ Aligned (frontend)

**Done:**
- `PayoutKind` enum (`engagement | royalty | distribution`).
- `payoutKindFor(actorRole, metric)` classifier on
  `EarningEventItem` + `MetricBreakdownRow`.
- `_PayoutKindChip` rendered on every row of
  `EarningsProvenanceScreen`.

**Remaining:**
- 🔧 Backend treats both as `earning_events` rows today. Add
  `payout_kind` column + COA segregation: split into
  `4101 — Engagement payouts` vs `4102 — Royalty payouts` so they
  age and clear with separate windows (royalties are recursive and
  longer-lived per strategy §2).

---

## 3) Provenance graph (`parent_post_id` / `root_post_id` / `relationship_type`)

**Status:** ✅ Shipped (2026-05-04)

**Required:**
- `posts` table additions:
  ```sql
  ALTER TABLE posts ADD COLUMN parent_post_id BIGINT NULL
    REFERENCES posts(id) ON DELETE SET NULL;
  ALTER TABLE posts ADD COLUMN root_post_id BIGINT NULL
    REFERENCES posts(id) ON DELETE SET NULL;
  ALTER TABLE posts ADD COLUMN relationship_type VARCHAR(24)
    NOT NULL DEFAULT 'original';
  -- 'original' | 'quote' | 'stitch' | 'reply_post' | 'remix' | 'duet'
  CREATE INDEX idx_posts_parent ON posts(parent_post_id);
  CREATE INDEX idx_posts_root ON posts(root_post_id);
  ```
- Backfill: `relationship_type = 'original'`, `root_post_id = id`
  for all existing rows.
- Post creation pipelines (quote/stitch/remix/duet flows) must
  populate `parent_post_id` and propagate `root_post_id` from
  the parent.
- Post model in `lib/models/post_models.dart` gains the same
  fields (already mapped, will surface in attribution UI).

**Risk:** Without this, derivative royalty (Layer C) cannot fire
correctly — there's no lineage to trace.

---

## 4) Bounded royalty propagation (direct 100% / parent 10–20% / root 2–5%)

**Status:** ✅ Shipped (2026-05-04)

`EarningsEngine::attributeForEvent` now adds `parent_creator_royalty`
and `root_creator_royalty` tuples for engagement events on derivative
posts. Per-tuple rates are seeded in `creator_earnings_rates` at 15%
of author rate (parent) and 5% (root). Cascade stops at depth 2 by
design — no recursion past root. No-op when post is `original` or
`shared`. Self-action / dupe filters apply.

**Done:**
- Layer share bands (`100% / 10–20% / 5–15%`) rendered on the
  `AttributionLayersCard`.
- `AttributionPropagationFooter` explains "royalties stop at the
  immediate parent and the root — they do not recurse".

**Remaining (backend):**
- `EarningsEngine` currently splits per-metric, not per-lineage-depth.
  Refactor: when an event lands on a derivative post, emit
  *three* journal entries:
  1. `direct_creator` row at 85% net (post author),
  2. `parent_creator` row at 10–15% net (immediate parent author),
  3. `root_creator` row at 2–5% net (root post author, if depth ≥ 2).
- Stop after depth 2 — strategy §4 explicitly forbids unbounded
  recursion.
- Configurable bands via `creators_fund_settings` table so the
  rate-card can tune without redeploy.

---

## 5) Weighted normalized scoring (Phase 2 ad rev-share)

**Status:** 🚧 Deferred — Phase 2 economy

**Strategy formula:**
```
creator_share = (event_weight / total_weight_pool) × revenue_pool
```

**Recommended weights (strategy §6):**

| Event              | Weight |
| ------------------ | ------ |
| Impression         | 1      |
| View > 5 sec       | 3      |
| Full watch         | 8      |
| Reaction           | 5      |
| Comment            | 12     |
| Reply              | 15     |
| Share              | 20     |
| Follow from post   | 30     |
| Subscribe from post| 100    |

**Required:**
- `event_weights` config table seeded with the table above.
- Daily/period rollup: `total_weight_pool = SUM(event.weight)`
  across all chargeable events per period.
- `revenue_pool` in Phase 2 = ad revenue net of platform take.
- Replace fixed-TZS-per-metric with the formula in
  `EarningsEngine::calculatePayout()`.
- Frontend: surface "your share of the weight pool" on
  `PostEarningsScreen` (`12 / 18,400 = 0.065%`) so creators
  understand they're in a competitive pool, not paid per-event.

**Blocker:** Phase 2 requires real ad revenue. Phase 1 stays on
fixed-rate fund payout until ads ship.

---

## 6) Sharer anti-spam constraints

**Status:** 🔧 Backend (frontend signaling ready)

**Required (backend) — strategy §5:**

| Constraint              | Rule                                          |
| ----------------------- | --------------------------------------------- |
| Unique viewer           | viewer must not have seen the post elsewhere  |
| Not the sharer          | viewer.id ≠ sharer.id                         |
| Meaningful watch        | watch_seconds ≥ 5                             |
| Attribution window      | event must occur within 7 days of share        |
| Real acquisition source | share was the first vector to that viewer     |

**Implementation plan:**
- Add `share_attribution_window_days = 7` and
  `min_watch_seconds_for_sharer_credit = 5` to
  `creators_fund_settings`.
- Backend `attributeShare()`:
  ```php
  if ($event->occurred_at > $share->created_at->addDays(7)) skip;
  if ($event->user_id === $share->user_id) skip;
  if ($event->watch_seconds < 5) skip;
  if (! is_first_acquisition($event->user_id, $share->post_id)) skip;
  ```
- Frontend: surface eligibility on the share success toast
  ("You'll earn distribution credit if your share leads to a
  unique 5s+ view in the next 7 days").

---

## 7) Engagement quality multipliers

**Status:** 🟡 Partial → 🔧 Backend (penalties missing)

**What exists today (boosts):**
- `EarningEventItem.multipliers` carries `watch_completion`,
  `mwanzo_boost`, `streak`, `discovery_mode` (positive multipliers).
- `multiplierSummary()` renders them as "2.0× watch × 1.1× streak".

**What's missing (penalties — strategy §8):**

| Signal           | Effect   |
| ---------------- | -------- |
| Hides            | penalty  |
| Reports          | penalty  |
| Rapid bounce     | penalty  |
| Spam likelihood  | penalty  |

**Required (backend):**
- New `quality_signals` table aggregating per-post hide/report/bounce
  signals.
- `EarningsEngine` applies a **clamped** penalty multiplier (e.g.
  `0.7×` if hide_rate > 5%, floor at `0.3×`).
- Surface on `PostEarningsScreen` as
  `multipliers['quality_penalty'] = 0.7` and render via
  `multiplierSummary()` with a red dot if < 1.0.

---

## 8) Sybil defense layer

**Status:** 🚧 Deferred — multi-month infrastructure

**Strategy §10 defenses:**

| Defense              | Purpose                                        |
| -------------------- | ---------------------------------------------- |
| Trust scores         | identify quality users                         |
| Device fingerprinting| detect farms                                   |
| Payout delays        | fraud review window                            |
| Rolling reserves     | clawbacks                                      |
| Behavioral ML        | bot detection                                  |
| Diminishing returns  | prevent self-interaction loops                 |

**Phase plan:**
1. **M1 — basic gating:** account age ≥ 7 days, IP-rate-limit per
   action, diminishing returns on repeat-actor-on-same-post.
2. **M2 — fingerprinting:** device fingerprint stored per session;
   Sybil rings flagged if ≥ 5 accounts share fingerprint.
3. **M3 — trust scores:** rolling 30-day score per user
   (`good_engagements / total_engagements`); creators see only
   credits from users with `trust ≥ 0.6`.
4. **M4 — ML:** XGBoost classifier on
   `(burst_pattern, follow_graph, content_match)` →
   bot_probability score; events with bot_probability ≥ 0.8 skipped
   automatically.

**Today:** the 30-day clearing window (Phase 1) is the only
defense — fraud is reviewed manually before payout.

---

## 9) Naming uplift

**Status:** ✅ Aligned

| Old (strategy §11)      | New                                |
| ----------------------- | ---------------------------------- |
| Secondary earners       | Attribution beneficiaries          |
| Share initiation credit | Distribution credit                |
| Inspiration royalty     | Derivative royalty                 |
| Host share              | Context royalty                    |

Centralized in `actorRoleLabel(actorRole, isSw)` in
`lib/creator/models/creator_earnings_models.dart`. All
user-facing surfaces (`EarningsProvenanceScreen`,
`AttributionLayersCard`) consume this helper.

---

## 10) Creator analytics dashboard (revenue-source mix + downstream-inspired feed)

**Status:** 🟡 Partial

**Done:**
- `RevenueSourceMixCard` donut renders 6-stream proportional mix
  on `CreatorEarningsDashboardScreen`.

**Remaining:**

### 10a) Layer mix (true to strategy §12 example)

The strategy doc example
> 42% direct engagement / 28% shares / 18% derivative royalties / 12% follower conversions

is **layer mix**, not stream mix. Today's donut shows streams.
To render true layer mix:

1. Backend `/api/users/me/earnings/by-layer?period=month` returning
   `{direct, context, derivative, distribution, conversion}` totals.
2. Frontend swaps the donut data source from `breakdownByStream`
   to the new endpoint.

### 10b) Top downstream creators

> Top downstream creators inspired by you

Requires the provenance graph (item 3) before it can be built.
After (3) ships:

1. Backend query: top N creators where the user authored the
   `root_post_id` of their derivative posts, ordered by their
   resulting earnings.
2. New screen `lib/creator/screens/downstream_creators_screen.dart`.

---

## 11) (Same as 9 — naming) — see above

---

## 12) Engagement ledger architecture

**Status:** ✅ Aligned

The system already implements:

```
engagement_events          → ✅ earning_events table
attribution_results        → ✅ EarningsEngine writes journal_lines
journal_entries            → ✅ COA-backed via LedgerService
payout_batches             → ✅ Settlement job (30-day window)
wallet_balances            → ✅ COA wallet account per user
```

This is the strongest existing alignment with the strategy doc —
the architecture is correct; the gaps are in the *attribution*
inputs (items 3, 5, 6, 7) and the *fraud* layer (item 8).

---

# Roadmap (suggested sequence)

| Phase     | Items        | Effort     | Blockers                    |
| --------- | ------------ | ---------- | --------------------------- |
| **P0**    | 1, 2, 9, 12  | shipped    | —                           |
| **P1**    | 3            | 1 week     | post-creation flow audit    |
| **P2**    | 4            | 1 week     | depends on P1               |
| **P3**    | 6, 7         | 1 week     | quality_signals job design  |
| **P4**    | 10a, 10b     | 1 week     | depends on P1 (10b)         |
| **P5**    | 8 M1–M2      | 2–3 weeks  | fingerprint SDK choice      |
| **P6**    | 5            | 2 weeks    | requires ad revenue (Phase 2)|
| **P7**    | 8 M3–M4      | 4–6 weeks  | ML pipeline + labelling     |

---

# Provenance + bounded royalty cascade (2026-05-04, shipped)

The 4-pillar derivative system from strategy §1C is now live end-to-end:

**Schema** (`posts` table):
- Added `parent_post_id`, `root_post_id`, `relationship_type`
  ('original' | 'quote' | 'stitch' | 'reply_post' | 'remix' | 'duet' | 'shared'),
  `remix_from_post_id`, `duet_from_post_id`. All indexed for lineage
  traversal. Existing rows backfilled (originals → root_post_id = id).

**`PostController::store`** detects whichever derivative FK is set
(reply / stitch / quote / remix / duet) and sets `parent_post_id` +
`root_post_id` + `relationship_type` before creating the post. Then
fires a `derivative_royalty` event for each of the 5 kinds.

**`EarningsEngine`** bounded cascade (strategy §4):
- Direct creator: 100% via existing author tuple.
- Parent author: 15% via new `parent_creator_royalty` tuple.
- Root creator: 5% via new `root_creator_royalty` tuple.
- Stops at depth 2 — no recursion past root.

Per-tuple rates seeded in `creator_earnings_rates` for all 10
metrics × {parent_creator_royalty, root_creator_royalty}.

**Endpoints**:
- `GET /api/users/me/earnings/by-derivative-kind` — earnings split
  by `posts.relationship_type`. Optional `post_type` filter.
- `GET /api/users/me/downstream-creators` — top creators whose
  derivatives generated royalties for this user.

**Frontend** (Post model):
- Added `parentPostId`, `rootPostId`, `relationshipType`,
  `quoteFromPostId`, `remixFromPostId`, `duetFromPostId`.
- `post_service.dart` plumbs all 5 derivative FKs to the backend.
- `PostCard` renders a lineage badge ("Quote of @user", "Stitch of
  @user", etc.) for non-original posts.

**UI sections lit up**:
- Photo earnings page: new "BY DERIVATIVE KIND" section showing
  earnings per `original / quote / stitch / reply_post / remix /
  duet`. Always renders all 6 kinds — empty kinds show TZS 0.
- Revenue report §5 (Derivative royalties): live table fed by
  `/by-derivative-kind`.
- Revenue report §6 (Top downstream creators): live table fed by
  `/downstream-creators` (top 5).

**Remaining gaps** (composers — UX work):
- Quote post composer: backend ready (`quote_from_post_id`),
  frontend service plumbs the FK, no dedicated composer screen yet.
  Reply, stitch, and duet composers exist; quote and remix do not.
- Remix composer: same — FK plumbing complete, composer screen
  missing.

These two remaining items are pure UX deliverables (video editor /
text-on-image composer); they don't change the data model or the
engine. Adding them later won't disturb anything that shipped today.

---

# Creator surface map (2026-05-04, revised)

**Landing page** (the canonical entry to `lib/creator/`) =
**`CreatorRevenueScreen`** — the 9-card revenue-sources grid:

1. Posts
2. Streams
3. Subscribers
4. Brand Deals
5. Ad Revenue
6. My Photos
7. My Videos
8. My Music
9. My Files

| Entry point                  | Lands on                                        |
| ---------------------------- | ----------------------------------------------- |
| Profile → Creator tab        | `CreatorRevenueScreen` (9-card grid)             |
| Route `/creator`, `/mapato`  | `CreatorRevenueScreen` (9-card grid)             |
| Route `/creator-earnings`    | `CreatorRevenueReportScreen` (15-section report) |

The 15-section **Creator Revenue Report** is reachable from the
landing grid via a prominent dark-button link "Full revenue report"
rendered immediately below the 9 cards
(`_FullReportLink` in `creator_revenue_screen.dart`).

The report's "Other views" footer keeps the legacy cross-stream
dashboard, the events ledger, and the tier-detail screen one tap
away from the report. The grid is no longer in the footer (it's
upstream of the report now).

Tier badge + Phase-1 fund period card live on the report as
promoted public widgets in `lib/creator/widgets/fund_period_card.dart`.

---

# Creator Revenue Report (15 sections)

The strategy doc additions (2026-05-04) specify a 15-section
**Creator Revenue Report** answering 5 questions: how much / where
from / which content / who amplified / what next.

`lib/creator/screens/creator_revenue_report_screen.dart` ships
all 15 sections. Live sections render real data; deferred sections
render phase-tagged "Coming in Pn" cards linking to this roadmap.

| §    | Section                       | Status                          |
| ---- | ----------------------------- | ------------------------------- |
| 1    | Revenue summary               | ✅ live                          |
| 2    | Revenue by source             | ✅ live (computed from layer mix) |
| 3    | Top earning posts             | ✅ live (CTA → list screen)      |
| 4    | Engagement event revenue      | ✅ live                          |
| 5    | Derivative royalties          | ✅ live (`/by-derivative-kind`) |
| 6    | Top downstream creators       | ✅ live (`/downstream-creators`) |
| 7    | Share attribution             | 🔧 P3                            |
| 8    | Conversation revenue tree     | ✅ live                          |
| 9    | Audience conversion funnel    | 🔧 P3                            |
| 10   | Integrity adjustments         | 🚧 P5                            |
| 11   | Geographic revenue            | 🔧 P3                            |
| 12   | Revenue timeline              | 🔧 P3                            |
| 13   | Wallet & payouts              | 🟡 partial (next-payout & lifetime fields needed) |
| 14   | AI insights                   | 🚧 P6                            |
| 15   | Raw ledger CSV export         | 🔧 P4                            |

Reachable from `CreatorEarningsDashboardScreen` via the primary
"Full revenue report" button.

---

# Files touched in P0 (this pass)

| File                                                              | Change                                                |
| ----------------------------------------------------------------- | ----------------------------------------------------- |
| `lib/creator/models/creator_earnings_models.dart`                 | + `PayoutLayer`, `PayoutKind`, classifiers            |
| `lib/creator/screens/earnings_provenance_screen.dart`             | strategy-aligned role label + kind chip               |
| `lib/creator/screens/post_earnings_screen.dart`                   | + `AttributionLayersCard` section                     |
| `lib/creator/screens/creator_earnings_dashboard_screen.dart`      | + source-mix donut, + layers section, + report CTA    |
| `lib/creator/screens/creator_revenue_report_screen.dart`          | new — 15-section report                               |
| `lib/creator/widgets/attribution_layers_card.dart`                | new                                                   |
| `lib/creator/widgets/revenue_source_mix_card.dart`                | new                                                   |
| `docs/creators/STRATEGY_ALIGNMENT.md`                             | new (this file)                                       |
