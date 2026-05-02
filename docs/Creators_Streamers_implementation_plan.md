# Creators & Streamers — Implementation Plan

> Companion to [`Creators_Streamers_tajiri_strategy.md`](./Creators_Streamers_tajiri_strategy.md).
> Strategy = the **why** and the **what**. This doc = the **how**, **in what order**, and **what's already done**.

Date: 2026-05-02
Status: ready for execution
Engineering Playbook: [`docs/ENGINEERING_PLAYBOOK.md`](./ENGINEERING_PLAYBOOK.md)

---

## Table of Contents

1. [Executive summary](#1-executive-summary)
2. [Audit results — what's already built](#2-audit-results--whats-already-built)
3. [Dependency graph](#3-dependency-graph)
4. [Phase 1 — foundations (Q3 2026)](#4-phase-1--foundations-q3-2026)
5. [Phase 2 — moats (Q4 2026)](#5-phase-2--moats-q4-2026)
6. [Phase 3 — differentiators (Q1 2027)](#6-phase-3--differentiators-q1-2027)
7. [Cross-cutting work](#7-cross-cutting-work)
8. [External blockers](#8-external-blockers)
9. [Sequencing & calendar](#9-sequencing--calendar)
10. [Telemetry to ship alongside features](#10-telemetry-to-ship-alongside-features)
11. [Risk register](#11-risk-register)
12. [Definition of done](#12-definition-of-done)

---

## 1. Executive summary

The strategy doc lists **12 levers across 19 features in 3 phases**. The audit (§2) found that the backend infrastructure is **~70% built** — the missing 30% is mostly user-facing UI, glue endpoints, and rate configuration. This shifts the plan materially:

- **5 features** flip from "build from zero" to "wire UI" — we can ship them in days, not weeks
- **4 features** need partial backend work plus full UI
- **3 features** are genuinely greenfield (cross-post, AI tools, live commerce overlay) — the long ones
- **3 features** are infrastructure (mobile streaming hardening, simulcast, stream loops) requiring partner contracts (CDN, Cloudflare Stream Live or Mux)
- **4 features** are policy/wellness primitives — small code, large UX/copy work

**Realistic Phase 1 target: 8 weeks.** Phase 2: 12 weeks. Phase 3: 8 weeks. Total to full-strategy: **~7 months for one focused team of 2-3 engineers + 1 designer.**

The single biggest unlock — and the recommended starting feature — is **Phase 1.1 + 1.2 + 1.3 combined: tipping + same-day payout dashboard + 95% split**. The backend exists; this is a 2-week shippable that delivers Lever 1, 2, and 10 simultaneously.

## 2. Audit results — what's already built

Verified via SSH inspection of `tajiri.zimasystems.com` PostgreSQL + Laravel codebase, 2026-05-02.

### Database tables (creator/streamer-relevant)

| Table | Status | Notes |
|---|---|---|
| `creator_earnings` | ✅ exists | `creator_id, type, gross_amount, platform_fee, net_amount, subscription_id, tip_id, gift_id, status, paid_at`. **Unified ledger model already in place.** |
| `creator_earnings_rates` | ✅ exists | `metric, rate, is_active`. Configurable per-source platform fee — means **95/5 is a row update, not a code change** |
| `creator_tips` | ✅ exists | `sender_id, creator_id, amount, message, payment_method, transaction_id, status` |
| `creator_payouts` | ✅ exists | `creator_id, amount, payment_method, account_number, account_name, provider, status, transaction_id, processed_at` |
| `creator_fund_pools` | ✅ exists | Monthly pool with `total_amount, currency, month, min_followers, min_posts, min_views, is_distributed` |
| `creator_fund_payouts` | ✅ exists | Per-creator share with all 4 multipliers (tier/streak/community/virality) |
| `creator_scores` + `creator_score_history` | ✅ exists | Tier + scoring infrastructure |
| `creator_streaks` | ✅ exists | Streak with `isFrozen` grace state |
| `creator_battles` + `creator_battle_votes` | ✅ exists | Battle infrastructure |
| `creator_coaching` | ✅ exists | Coaching/recommendation system |
| `tip_pool_rules` + `tip_pool_distributions` | ✅ exists | Multi-creator tip pool (e.g. for collab streams) |
| `wallets` | ✅ exists | `balance, pending_balance, currency, pin_hash, locked_until, ad_balance` |
| `wallet_transactions` | ✅ exists | Full ledger including `journal_entry_id` for double-entry accounting |
| `wallet_transfers` | ✅ exists | Inter-wallet transfer infrastructure |
| `partner_delivery_tips` | ✅ exists | Tipping for delivery partners (separate flow) |
| `subscriptions` | ✅ exists (referenced) | Subscription infrastructure (need to inspect) |
| `stream_gifts` | ✅ exists (referenced) | Gift records on streams |
| `virtual_gifts` | ✅ exists (referenced) | Gift catalog (price, image, etc.) |

### API endpoints (creator/streamer-relevant)

| Endpoint | Status | Notes |
|---|---|---|
| `POST /api/subscriptions/tips` | ✅ live | `SubscriptionController::sendTip` — validates, blocks self-tipping, checks BlockedUser, creates `CreatorTip`, calls `CreatorEarning::createFromTip` |
| `GET /api/subscriptions/earnings/{creatorId}` | ✅ live | Returns earnings for a creator |
| `POST /api/live-streams/{id}/gifts` | ✅ live | `LiveStreamController::sendGift` — validates, checks `allow_gifts`, creates `StreamGift` |
| `GET /api/live-streams/{id}/gifts/received` | ✅ live | Returns gifts on a stream |
| `GET /api/live-streams/gifts` | ✅ live | Returns virtual gift catalog |
| `GET /api/posts/{postId}/earnings` | ✅ live | Per-post earnings aggregation |
| `GET /api/creators/{id}/score` | ✅ live | Creator score + tier |
| `GET /api/creators/{id}/streak` | ✅ live | Posting streak |
| `GET /api/creators/{id}/fund-projection` | ✅ live | Projected payout |
| `GET /api/creators/{id}/content-calendar` | ✅ live | Calendar with best-time-to-post |
| `GET /api/creators/{id}/collaborations` | ✅ live | Collab radar |
| `GET /api/creators/{id}/viral-assists` | ✅ live | (seen in earlier app logs) |
| `POST /api/tip-pools` etc. | ✅ live | Multi-creator pool infrastructure |
| `GET /api/auth/biometric-*` | ✅ live | Biometric step-up for sensitive actions (just shipped) |

### Frontend (creator/streamer-relevant)

| Surface | Status | Notes |
|---|---|---|
| `lib/creator/screens/dashboard_section.dart` | ✅ live | Tier badge, streak, multipliers, projected payout, fund pool, collab radar, content calendar, weekly report + analytics buttons. **Earnings ledger entry-point added.** |
| `lib/creator/screens/settings_screen.dart` | ✅ live | 4 opt-out toggles. Three-way coordinated with Faragha + Settings |
| `lib/creator/screens/weekly_report_screen.dart` | ✅ live (legacy) | Weekly performance report — ages out of session scope |
| `lib/creator/screens/sponsored_posts_screen.dart` | ✅ live (legacy) | Boost UI |
| `lib/creator/services/creator_service.dart` | ✅ live | All 7 dashboard endpoints wired |
| `lib/creator/services/collaboration_service.dart` | ✅ live | Collab CRUD + accept/dismiss |
| `lib/creator/widgets/creator_tier_badge.dart` | ✅ live | |
| `lib/creator/widgets/streak_indicator.dart` | ✅ live | |
| `lib/creator/widgets/collaboration_card.dart` | ✅ live | |
| `lib/creator/widgets/posting_nudge_card.dart` | ✅ live | |
| **Tip button on PostCard** | ❌ missing | Foundation for Lever 1 |
| **Tip sheet** (bottom-sheet picker + Tajiri Pay flow) | ❌ missing | Reusable across post + stream |
| **Earnings ledger screen** | ❌ missing (entry-point added) | Phase 1.3 — `lib/creator/screens/earnings_ledger_screen.dart` |
| **Live tip overlay** during streaming | ❌ missing | Phase 1, on stream player |
| **Cross-post composer toggle** | ❌ missing | Phase 2.2 |
| **Live commerce overlay** | ❌ missing | Phase 2.4 |
| **AI thumbnail / caption generator** | ❌ missing | Phase 2.3 |
| **Algorithm transparency overlay** | ❌ missing | Phase 1.5 — backend events exist, UI doesn't |
| **Subscriber-only post tier UI** | ❌ missing | Phase 2.1 — backend `subscriptions` table likely exists |
| **Brand marketplace UI** | ❌ missing | Phase 2.5 |
| **Adaptive bitrate / disconnect protection** | ❌ missing | Phase 1.6 — needs RTMP/CDN partner |

### What needs verification (not yet inspected, but high-leverage)

- [ ] Is `creator_earnings_rates.rate` actually set to 0.05 (5% platform fee) for `tip` and `gift` metrics? Or is the default still 30%?
- [ ] Does `LiveStreamController::sendGift` write to `creator_earnings` like `sendTip` does? (The audit caught the head of the function but not the `CreatorEarning::createFromGift` call)
- [ ] Does `sendTip` actually move money from sender's `wallet` to creator's `wallet`? Or is `payment_method=manual` bypassing the wallet today?
- [ ] Same-day payout cron — does it exist? Where (`app/Console/Commands/`)?
- [ ] Subscription tier infrastructure — what columns does `subscriptions` have?

These five questions block confidence in Phase 1 estimates. Resolve in Day 1 of Phase 1.

## 3. Dependency graph

```
                                ┌─────────────────────┐
                                │ creator_earnings    │ ✅ exists
                                │ ledger              │
                                └──────────┬──────────┘
                                           │ feeds
              ┌────────────────────────────┼────────────────────────────┐
              │                            │                            │
              ▼                            ▼                            ▼
       ┌──────────────┐            ┌──────────────┐            ┌──────────────┐
       │ Lever 1      │            │ Lever 2      │            │ Lever 10     │
       │ Tip on post  │            │ Same-day     │            │ 95% split    │
       │ (Phase 1.1)  │            │ payout (1.3) │            │ (rate cfg)   │
       └──────┬───────┘            └──────┬───────┘            └──────┬───────┘
              │                           │                           │
              │                           ▼                           │
              │                    ┌──────────────┐                   │
              │                    │ Wallet flow  │ ✅ exists         │
              │                    │ debit/credit │                   │
              │                    └──────────────┘                   │
              ▼                                                       ▼
       ┌──────────────┐                                        ┌──────────────┐
       │ Tip on live  │                                        │ Subscriber   │
       │ stream       │                                        │ tiers (2.1)  │
       └──────┬───────┘                                        └──────────────┘
              │
              ▼
       ┌──────────────┐    ┌──────────────────────┐    ┌──────────────────┐
       │ Brand mktplc │ ◄──│ Tajirika auto-       │ ◄──│ Lever 7          │
       │ (2.5)        │    │ provisioning (1.4)   │    │ Creator=business │
       └──────────────┘    └──────────────────────┘    └──────────────────┘

       ┌──────────────┐    ┌──────────────────────┐
       │ Algorithm    │ ◄──│ event_tracking_      │ ✅ exists
       │ transparency │    │ service              │
       │ (1.5)        │    └──────────────────────┘
       └──────────────┘

       ┌──────────────┐    ┌──────────────────────┐
       │ Cross-post   │ ◄──│ Sanctioned APIs:     │ external (auth required)
       │ (2.2)        │    │ TikTok / IG / YT     │
       └──────────────┘    └──────────────────────┘

       ┌──────────────┐    ┌──────────────────────┐
       │ AI tools     │ ◄──│ Shangazi (already    │ ✅ exists
       │ (2.3)        │    │ integrated)          │
       └──────────────┘    └──────────────────────┘

       ┌──────────────┐    ┌──────────────────────┐
       │ Live commerce│ ◄──│ Tajirika catalog     │ ✅ exists
       │ overlay (2.4)│    │ Tajiri Pay           │
       └──────────────┘    └──────────────────────┘

       ┌──────────────┐    ┌──────────────────────┐
       │ Stream       │ ◄──│ CDN partner          │ external blocker
       │ hardening    │    │ (Cloudflare/Mux)     │
       │ (1.6, 1.7,   │    └──────────────────────┘
       │  2.6, 2.7)   │
       └──────────────┘
```

**Critical path:** verify creator_earnings_rates → tip-on-post UI → same-day payout dashboard → tajirika auto-provision. Everything else can run in parallel once these four are done.

## 4. Phase 1 — foundations (Q3 2026)

**Goal:** by end of Phase 1, every TAJIRI user can earn from day 1, sees a live ledger of their earnings, gets paid the same day, and has a Tajirika business waiting for them. Streaming is reliable on cellular.

**Calendar:** 8 weeks. 2 engineers + 1 designer.

### 1.1 — Tip on any post (Lever 1, Lever 10)

**Status:** backend exists, frontend missing. Wire-UI work primarily.

**Backend tasks** (~2 days)
- [ ] Verify `creator_earnings_rates` row exists for `metric='tip'` with `rate=0.05`. Insert if missing.
- [ ] Verify `sendTip` actually debits the sender's wallet. If using `payment_method='manual'`, add a `wallet` payment_method that wraps `WalletService::debit` → `WalletService::credit` on the creator's wallet, in a transaction.
- [ ] Add idempotency-key support on `POST /api/subscriptions/tips` (use `transaction_id` field that already exists)
- [ ] Add a `post_id` column to `creator_tips` so a tip is attributable to a specific post (currently it's only attributable to a creator). Migration + model + sendTip param.

**Frontend tasks** (~3 days)
- [ ] `lib/creator/widgets/tip_sheet.dart` — bottom-sheet picker. Preset amounts (500, 1000, 2000, 5000 TSh) + custom. Optional message field (max 200 chars). Tajiri Pay confirmation. Optimistic-with-revert.
- [ ] `lib/creator/services/tip_service.dart` — wraps `POST /api/subscriptions/tips` with idempotency.
- [ ] `lib/widgets/post_card.dart` — add tip button next to like/comment. Wire to TipSheet.
- [ ] Bilingual strings (~8 new): `tipCta`, `tipAmount`, `tipMessageHint`, `tipSent`, `tipFailed`, `tipBlockedSelf`, `tipPresetSmall/Medium/Large`, `tipCustom`.

**Acceptance criteria**
- ✅ Logged-in user can tip any post-author. Self-tipping blocked. Blocked-relationship blocked.
- ✅ Tip deducts from sender's Tajiri Pay wallet, credits 95% to creator's wallet, 5% to platform.
- ✅ Tip writes to `creator_tips`, then `creator_earnings` (via `CreatorEarning::createFromTip`).
- ✅ Tip is attributed to the post (`creator_tips.post_id`).
- ✅ Optimistic UI: tip count on post increments instantly; reverts on failure with inline banner.
- ✅ Idempotent: tapping "Send" twice in quick succession sends one tip.
- ✅ Bilingual strings throughout. No SnackBars.
- ✅ Playbook compliance: `GestureDetector(opaque)`, `SafeArea`, `keyboardDismissBehavior`, inline error banner.

**Effort:** 5 dev-days + 2 design-days. **Est. ship: end week 1.**

### 1.2 — Tip + Gift on live stream (Lever 1, Lever 10)

**Status:** gift backend exists, may need wallet integration; frontend missing for UI overlay.

**Backend tasks** (~3 days)
- [ ] Verify `LiveStreamController::sendGift` writes to `creator_earnings` at the configured rate. If not, add `CreatorEarning::createFromGift($streamGift)` call.
- [ ] Insert `creator_earnings_rates` row for `metric='gift'` with `rate=0.05`.
- [ ] `POST /api/live-streams/{id}/tip` — direct cash tip mid-stream (not a virtual gift). Same wallet flow as 1.1, attributed to stream.
- [ ] Reverb broadcast: emit `tip.received` event on `stream.{id}` channel so the streamer sees the tip animate in real time.

**Frontend tasks** (~4 days)
- [ ] Live stream player: tip button overlaid on the stream UI. Tap → `TipSheet` (reused from 1.1).
- [ ] Live stream player: virtual gift drawer (catalog of `virtual_gifts` with prices). Tap a gift → quantity picker → confirm → animate.
- [ ] Streamer-side: real-time tip/gift toaster (top-of-stream banner that animates in for 3s). Subscribed to `stream.{id}` Reverb channel.
- [ ] Streamer-side: live "earned this stream" counter visible only to the streamer.

**Acceptance criteria**
- ✅ Viewer can tip cash OR send a virtual gift mid-stream.
- ✅ Both flows debit viewer's wallet, credit 95% to streamer's wallet.
- ✅ Streamer sees real-time animation when each tip/gift lands.
- ✅ Streamer sees a live total of stream earnings, only visible to them (not to viewers).
- ✅ Gifts respect `live_streams.allow_gifts` flag (already wired).
- ✅ Tip + gift events are written to `creator_earnings` as separate rows for clean ledger.
- ✅ Playbook compliance.

**Effort:** 7 dev-days + 3 design-days. **Est. ship: end week 3.**

### 1.3 — Same-day payout dashboard (Lever 2)

**Status:** backend partial (creator_earnings + creator_payouts exist), payout cron unknown, dashboard UI missing.

**Backend tasks** (~5 days)
- [ ] Verify if a `creator:settle-payouts` Artisan command exists. If not, create one.
- [ ] Cron logic: nightly job picks up `creator_earnings.status='pending'` rows older than 6 hours, groups by creator, totals net_amount, creates a `creator_payouts` row, transfers from platform's escrow wallet to the creator's wallet, marks earnings as `status='paid', paid_at=now()`.
- [ ] Settlement is **same-day** (or nearly): default cron runs every 6 hours. Faster cycles configurable per environment.
- [ ] `GET /api/creators/{userId}/earnings/ledger?since=YYYY-MM-DD&limit=N` — paginated ledger entries, with eager-loaded source detail (tip → message + sender, gift → virtual_gift, sub → subscriber).
- [ ] `GET /api/creators/{userId}/earnings/summary?period=day|week|month` — aggregated breakdown by source.

**Frontend tasks** (~5 days)
- [ ] `lib/creator/screens/earnings_ledger_screen.dart` — full-screen ledger (entry-point already added to dashboard).
  - Header: total earned this month + last payout amount + next payout ETA.
  - Tabbed views: All / Tips / Gifts / Subs / Fund / Commerce / Brand.
  - Per-row: source icon, attribution (e.g., "From @andrew on Post 1234"), gross → net split, status badge.
  - Pull-to-refresh.
  - Pagination via `before_id`.
- [ ] `lib/creator/widgets/earnings_summary_card.dart` — replaces (or wraps) the existing FundPayoutProjection card on the dashboard with live-updating earnings data.

**Acceptance criteria**
- ✅ Creator opens dashboard → sees total earned this month, last payout amount, next payout ETA.
- ✅ Tap "View ledger" → full transparent ledger with every TSh accounted for.
- ✅ Each row shows gross / platform_fee / net.
- ✅ Settlement happens within 24 hours of the earning event for ≥95% of cases.
- ✅ Settled rows show `paid_at` timestamp + Tajiri Pay transaction reference.

**Effort:** 10 dev-days + 2 design-days. **Est. ship: end week 5.**

### 1.4 — Tajirika business auto-provisioning (Lever 7)

**Status:** Tajirika business infrastructure exists, auto-provisioning logic missing.

**Backend tasks** (~3 days)
- [ ] Hook on first creator earning event (any of: first tip received, first gift received, first sub received, first fund payout) → check if `user_businesses` row exists for that user. If not, auto-create with sensible defaults (name = user's display_name, sector = "creator", inactive_status = false).
- [ ] Audit: emit `tajirika_auto_provisioned` to `security_activity_log`.

**Frontend tasks** (~2 days)
- [ ] On first earning, show a one-time inline banner on the dashboard: "🎉 You're now a Tajirika business — invoices, RFQs, and bookings are ready for you. [Open Tajirika]"
- [ ] Banner dismissible; persists until dismissed or until user opens Tajirika once.

**Acceptance criteria**
- ✅ Any creator who earns their first TSh through any channel is auto-provisioned with a Tajirika business row.
- ✅ Banner appears on Creator Dashboard exactly once per user.
- ✅ Tajirika business is fully functional (invoice, RFQ, booking) immediately — no extra setup screens.

**Effort:** 5 dev-days + 1 design-day. **Est. ship: week 6.**

### 1.5 — Algorithm transparency overlay (Lever 8)

**Status:** event-tracking backend exists, attribution analysis missing, UI missing.

**Backend tasks** (~5 days)
- [ ] New endpoint: `GET /api/posts/{postId}/insights` — returns:
  - `reach`: total impressions
  - `top_reach_drivers`: array of { source: 'group_share'|'feed'|'follower'|'hashtag'|'discovery', count }
  - `watch_time_decay`: array of { second: int, retention_pct: float } for video posts
  - `engagement_score`: a normalized 0-100
  - `comparison`: `reach` vs creator's `avg_reach_30d`, expressed as % delta
  - `predicted_earnings`: TSh, derived from current scoring rate × engagement_score
- [ ] Logic pulls from `event_tracking_service` data + post analytics.

**Frontend tasks** (~4 days)
- [ ] On a creator's own post (long-press OR action sheet), reveal an "Insights" view.
- [ ] `lib/creator/widgets/post_insights_sheet.dart` — bottom sheet with hero number (reach), comparison delta, top reach drivers as horizontal bar chart, watch-time decay as line chart, predicted earnings.
- [ ] Auto-generated coaching text ("Viewers drop at 8s — try a stronger hook" or "Group shares are your top driver — share to 2 more groups next time"). Use Shangazi if available; else hardcode the rule-based heuristic.

**Acceptance criteria**
- ✅ Creator can see, for each of their posts, a transparent breakdown of why it performed.
- ✅ Coaching text appears for posts where the heuristic detects a fixable pattern.
- ✅ Performance: insights view loads in <1s on 3G (cache aggressively).

**Effort:** 9 dev-days + 3 design-days. **Est. ship: week 7.**

### 1.6 — Mobile streaming hardening (Lever 11)

**Status:** basic streaming works, hardening features missing.

**Backend tasks** (~4 days)
- [ ] Adaptive bitrate streaming (ABR) — needs RTMP/HLS encoder that supports multiple ladders. Most likely **partner with Cloudflare Stream Live** (~$1/1000 minutes delivered, includes ABR, low-latency, transcoding). Replace direct Reverb broadcasting with Cloudflare ingest URL.
- [ ] Disconnect protection: 90-second grace period — when broadcaster disconnects, hold the stream "paused" with a banner; resume when they reconnect within 90s.
- [ ] Data-cost telemetry: track bytes uploaded per stream session, expose via `GET /api/live-streams/{id}/data-usage`.

**Frontend tasks** (~5 days)
- [ ] Broadcaster-side: data-cost meter visible in the broadcast UI ("This stream: 47 MB").
- [ ] Resume-after-call handler: detect call-state change via `flutter_callkit_incoming` or platform channel, pause broadcast, show "Paused — resuming after call..." banner, auto-resume.
- [ ] Adaptive quality dropdown (Auto / 720p / 480p / 360p / 240p) + on-screen indicator of current encode bitrate.
- [ ] One-tap moderation: long-press on any chat message → Mute / Ban / Delete.
- [ ] Picture-in-picture: when minimized, the broadcast continues + chat stays visible in a small overlay.

**External blocker:** Cloudflare Stream Live (or Mux) account + API integration. Decide partner in week 1, kick off contract by week 2.

**Acceptance criteria**
- ✅ Stream automatically degrades to lower bitrate on bad cellular without dropping.
- ✅ Stream resumes within 90s of a transient network drop.
- ✅ Broadcaster sees their data usage in real time.
- ✅ Incoming phone call pauses (does not kill) the broadcast.
- ✅ Moderator actions (mute/ban/delete) are 1-tap.

**Effort:** 9 dev-days + 4 design-days + ~3 days for partner integration. **Est. ship: week 8.**

### 1.7 — Creator wellness foundations (Lever 9 partial)

**Status:** `CreatorStreak.isFrozen` exists, off-day mode + burnout signal don't.

**Backend tasks** (~2 days)
- [ ] Add `user_profiles.creator_off_day_mode` boolean, default false.
- [ ] When `off_day_mode=true`, suppress all push notifications of type `streak_warning`, `weekly_report`, `viral_assist`, `milestone`, `creator_milestone` for that user.

**Frontend tasks** (~2 days)
- [ ] Add an "Off-day mode" toggle to `lib/creator/screens/settings_screen.dart` (we just built that screen).
- [ ] Streak grace status display: "You have 2 grace days left this month" on the dashboard.

**Acceptance criteria**
- ✅ Toggling off-day mode silences all creator-economy nudges for the day.
- ✅ Creator can see how many grace days they have remaining.
- ✅ Bilingual.

**Effort:** 4 dev-days + 1 design-day. **Est. ship: week 8 (parallel with 1.6).**

## 5. Phase 2 — moats (Q4 2026)

**Goal:** by end of Phase 2, TAJIRI is the creator's home base — they post here first, then cross-distribute. Live commerce works. Brand marketplace is matching local businesses to local creators.

**Calendar:** 12 weeks. 3 engineers + 1 designer + 1 partnerships lead (for cross-post, brand mktplc, CDN).

### 2.1 — Subscriber-only posts + tier system (Lever 1)

**Status:** `subscriptions` table referenced, full state unknown.

**Audit needed:** what columns does `subscriptions` have today? Is there a `tier` concept?

**Estimated work** (~10 days backend + 8 days frontend)
- Backend: `subscription_tiers` table (creator_id, name, price, perks_jsonb), recurring billing job (monthly cycle via Tajiri Pay), gating middleware on post visibility.
- Frontend: tier-creation UI in `lib/creator/screens/subscription_tiers_screen.dart`. Subscriber-only badge on posts. Subscriber-side: subscribe button on profile + manage-subscriptions screen.

**Effort:** 18 dev-days. **Est. ship: end week 12.**

### 2.2 — Cross-post publisher (Lever 4)

**Status:** none. Full greenfield (per earlier WhatsApp/IG/TikTok/YT research).

**Estimated work** (~15 days backend + 10 days frontend)
- Backend: OAuth integration for TikTok Content Posting API, IG Graph API, YouTube Data API. Token storage (`oauth_creator_tokens` table). Per-platform publish handlers.
- Frontend: composer toggle "Also post to: [TikTok][IG][YouTube]". Post-mortem screen showing which platforms succeeded/failed. Cross-platform stats consolidation in Analytics.

**External blockers:** TikTok app review (~2-3 weeks), IG app review (~1-2 weeks), YouTube quota increase (~1 week).

**Effort:** 25 dev-days + external review wait. **Est. ship: end week 14 (assuming reviews start in Phase 1).**

### 2.3 — AI captions + thumbnails + scripts (Lever 3)

**Status:** Shangazi infrastructure exists, AI generators don't.

**Estimated work** (~12 days backend + 10 days frontend)
- Backend: `POST /api/creator/ai/captions` (whisper-style, on-device or server), `POST /api/creator/ai/thumbnails` (4 variants per post), `POST /api/creator/ai/script-from-prompt` (delegates to Shangazi). All gated by `face_embedding_consent`-style new consent toggle for AI tooling.
- Frontend: composer integration: "Generate captions" button after recording, "Generate thumbnail variants" with A/B picker, "Ask Shangazi for a script" entry-point.

**Effort:** 22 dev-days + design-heavy work. **Est. ship: week 16.**

### 2.4 — Live commerce overlay (Lever 5)

**Status:** Tajirika catalog exists, live overlay doesn't.

**Estimated work** (~8 days backend + 8 days frontend)
- Backend: `POST /api/live-streams/{id}/pin-product` — broadcaster pins a product from their (or affiliated) Tajirika catalog. Reverb broadcast to viewers. `POST /api/orders/from-stream` — purchase via Tajiri Pay during stream. Affiliate commission auto-split via journal-line accounting.
- Frontend: broadcaster pin-product picker; viewer "Buy now" overlay; checkout sheet (pre-fills delivery address from user_profiles).

**Effort:** 16 dev-days. **Est. ship: week 18.**

### 2.5 — Brand marketplace for nano + micro (Lever 6)

**Status:** Tajirika businesses exist, marketplace + matching doesn't.

**Estimated work** (~12 days backend + 10 days frontend)
- Backend: `brand_briefs` table (business_id, payload, payout_amount, brand_safety_checkpoints, region_filter, status). Matching algorithm. Escrow on Tajiri Pay (hold on brief creation, release on completion). Verification (impression count + audience match).
- Frontend: business-side brief composer; creator-side "Available briefs near you" feed; application flow; submission verification.

**Effort:** 22 dev-days. **Est. ship: week 20.**

### 2.6 — Native simulcast (Lever 11)

**Status:** none. Greenfield.

**Estimated work** (~6 days backend + 4 days frontend)
- Backend: simulcast handler that pipes Cloudflare Stream Live ingest to TikTok Live RTMP + IG Live RTMP + YouTube Live RTMP simultaneously. Per-platform auth (RTMP key management, OAuth token reuse from 2.2).
- Frontend: composer toggle "Go live to: [TAJIRI][TikTok][IG][YouTube]".

**Note:** depends on platform partner contracts allowing 3rd-party RTMP ingest. TikTok requires separate "RTMP creator" partner approval; IG Live blocks 3rd-party RTMP in many markets.

**Effort:** 10 dev-days + heavy partner work. **Est. ship: week 22 if partnerships clear.**

### 2.7 — Stream loops (Lever 11)

**Status:** none. Greenfield.

**Estimated work** (~5 days backend + 5 days frontend)
- Backend: pre-recorded video upload + scheduled-loop service (FFmpeg loop into Cloudflare Stream input). Chat + gifts continue working as if creator is live; broadcaster sees viewer activity log.
- Frontend: "Schedule a loop" UI; broadcaster live-chat-only mode (chat without camera).

**Effort:** 10 dev-days. **Est. ship: week 24 (end of Phase 2).**

## 6. Phase 3 — differentiators (Q1 2027)

**Goal:** Tajiri pulls ahead on creator wellness, transparency, and the "every income stream in one stream" moment.

**Calendar:** 8 weeks. 2 engineers + 1 designer.

### 3.1 — AI Shangazi script-to-video (Lever 3 deep)

Builds on 2.3. Single prompt → AI scene plan → AI footage suggestions → AI narration → AI subtitles → final video. ~15 dev-days.

### 3.2 — Wellness pings + burnout detection (Lever 9 deep)

Detect doom-scrolling-own-analytics patterns (e.g., > 50 analytics opens per day). Shangazi prompt: "Take a 24h break — your streak is safe." ~6 dev-days.

### 3.3 — Algorithm transparency for community drivers (Lever 8 deep)

Multipliers explained per-creator, per-post. "Your 'Community' multiplier is 1.4× this month because you replied to 12 of 18 comments. Reply to 5 more to hit 1.5×." ~6 dev-days.

### 3.4 — Multi-revenue stream overlay during live (Lever 12)

Single broadcaster surface combining gifts + tips + commerce + super-chat + booking-prompt during a live stream. ~10 dev-days.

### 3.5 — Recorded live → VOD with shoppable timestamps (Lever 5 deep)

After a live stream ends, the recording becomes a VOD with the product-pin events preserved as shoppable hotspots in the timeline. ~8 dev-days.

**Phase 3 total:** ~45 dev-days.

## 7. Cross-cutting work

These apply across every feature in every phase. Don't skip them.

### Engineering Playbook compliance (per [`docs/ENGINEERING_PLAYBOOK.md`](./ENGINEERING_PLAYBOOK.md))

For every new screen we ship, the playbook checklist:
- ✅ `GestureDetector(behavior: HitTestBehavior.opaque, onTap: () => FocusScope.of(context).unfocus())` wrapping `Scaffold`
- ✅ `SafeArea` body wrapper
- ✅ `AppBar` with `scrolledUnderElevation: 1`
- ✅ `keyboardDismissBehavior: ScrollViewKeyboardDismissBehavior.onDrag` on every `ListView` / `SingleChildScrollView`
- ✅ Inline error banner — **never SnackBar**
- ✅ Optimistic UI with revert-on-failure for any mutation
- ✅ Bilingual via `AppStringsScope.of(context)?.someGetter ?? 'English fallback'`
- ✅ `maxLines` + `TextOverflow.ellipsis` on every dynamic text
- ✅ 48dp minimum touch target
- ✅ Monochrome palette only (`#1A1A1A`, `#666666`, `#FAFAFA`, `#FFFFFF`)
- ✅ `RefreshIndicator(color: Color(0xFF1A1A1A))` on every list
- ✅ Material `_rounded` icons

**Don't:**
- ❌ FloatingActionButton (use a pill button at top-right)
- ❌ Hardcoded Swahili-only strings
- ❌ Untracked async state (every Future call must surface success/failure to the user)
- ❌ Skip the loading state (CircularProgressIndicator(strokeWidth: 2))

### Bilingual strings strategy

For each feature, add **all** new strings to `lib/l10n/app_strings.dart` as bilingual ternaries — even ones that "feel English-only" like "Send" → "Tuma". Add as we go; don't batch at end.

### Backend response convention

Every new endpoint follows the existing pattern:
```php
return response()->json([
    'success' => true,
    'data' => [...],
    'message' => 'optional_user_facing_string',
]);
```

Errors return `success: false, message: '...'` with the appropriate HTTP status.

### Activity log

Every state-changing creator action emits a `security_activity_log` entry (the table we just built). Specifically:
- `creator_first_earning` — fired by 1.4
- `creator_payout_settled` — fired by 1.3
- `creator_subscriber_tier_created` — fired by 2.1
- `creator_brand_brief_accepted` — fired by 2.5
- `creator_off_day_enabled` — fired by 1.7

This gives us per-user audit + telemetry without separate logging.

### Module structure

All new creator/streamer code goes in `lib/creator/` (we just consolidated this). Subdirectories:
- `models/` — data shapes
- `services/` — HTTP clients
- `widgets/` — reusable UI components
- `screens/` — full-screen surfaces

Cross-module imports allowed (e.g., `lib/widgets/post_card.dart` importing from `lib/creator/widgets/tip_sheet.dart`).

### Testing

- Each new endpoint: 1 happy-path tinker smoke test before merging.
- Each new screen: `flutter analyze` clean (zero new lints) before merging.
- Each user-money flow: end-to-end test against `creator_earnings` ledger to verify split is correctly 95/5.

## 8. External blockers

These can't be coded around. Start them in week 1.

| Blocker | Owner | ETA | Blocks |
|---|---|---|---|
| **Cloudflare Stream Live contract** (or Mux) | partnerships | 2-3 weeks | 1.6, 2.6, 2.7 |
| **TikTok Content Posting API approval** | partnerships | 2-3 weeks | 2.2 |
| **Instagram Graph API app review** | partnerships | 1-2 weeks | 2.2, 2.6 |
| **YouTube Data API quota increase** | partnerships | 1 week | 2.2, 2.6 |
| **TikTok Live RTMP partner approval** (if pursuing simulcast to TikTok) | partnerships | uncertain | 2.6 |
| **Tajiri Pay payout-to-mobile-money rails** (M-Pesa, Tigo Pesa, Airtel Money) | finance + ops | uncertain | 1.3 actual settlement |
| **AI compute provider** for thumbnail/caption generation (OpenAI, Replicate, or self-hosted) | infra | 1 week | 2.3 |
| **Brand-side onboarding** for marketplace (need 10+ TZ businesses ready as launch partners) | sales | 4-6 weeks | 2.5 |

## 9. Sequencing & calendar

Assumes 2 engineers + 1 designer + 1 partnerships lead. Calendar weeks numbered from Phase 1 start.

```
Week 1  ─ Eng A: Audit Day 1 questions + Phase 1.1 backend
        ─ Eng B: Cloudflare partner discovery; TikTok/IG/YT review submissions
        ─ Design: Tip sheet + dashboard ledger card
        
Week 2  ─ Eng A: Phase 1.1 frontend (TipSheet, PostCard button)
        ─ Eng B: Phase 1.6 backend (Cloudflare integration POC)
        ─ Design: Stream broadcaster overlay + mod tools
        
Week 3  ─ Eng A: Phase 1.2 (live tip + gift) backend + frontend
        ─ Eng B: Phase 1.6 frontend (data meter, ABR, disconnect)
        ─ Design: Earnings ledger screen + insights overlay
        
Week 4  ─ Eng A: Phase 1.2 finishing; merge tip + gift flows
        ─ Eng B: Phase 1.3 backend (settle-payouts cron, ledger endpoint)
        ─ Design: Brand marketplace concept (parallel for Phase 2.5)
        
Week 5  ─ Eng A: Phase 1.3 frontend (earnings ledger screen + summary card)
        ─ Eng B: Phase 1.5 backend (insights endpoint)
        
Week 6  ─ Eng A: Phase 1.4 (Tajirika auto-prov)
        ─ Eng B: Phase 1.5 frontend (insights sheet)
        
Week 7  ─ Eng A: Phase 1.7 (wellness foundations)
        ─ Eng B: Polish, telemetry instrumentation, end-to-end testing
        
Week 8  ─ Both: Phase 1 hardening, bug-bash, public soft-launch with 50 invited creators
        
Week 9-12  ─ Phase 2.1 (subs), 2.4 (live commerce overlay) — both eng tracks
        
Week 13-16 ─ Phase 2.2 (cross-post), 2.3 (AI tools) — assuming reviews pass
        
Week 17-20 ─ Phase 2.5 (brand mktplc), 2.6 (simulcast) — partner-dependent
        
Week 21-24 ─ Phase 2.7 (stream loops), Phase 2 hardening
        
Week 25-32 ─ Phase 3 (5 features in parallel)
```

**Recommended public milestones:**
- **Week 4:** "First TSh" beta — 50 creators can tip + receive tips on TAJIRI
- **Week 8:** Phase 1 complete — official "Earn from Day 1" launch
- **Week 16:** Phase 2 mid-checkpoint — cross-post live, AI tools shipping
- **Week 24:** Phase 2 complete — "TAJIRI as Creator Home Base" press push
- **Week 32:** Phase 3 complete — full strategy realized

## 10. Telemetry to ship alongside features

Without instrumentation we can't measure §7 success metrics. **Every feature ships with its telemetry.** Reuse the existing `event_tracking_service`.

| Event | Triggered when | Used for |
|---|---|---|
| `creator.tip_sent` (sender) + `creator.tip_received` (creator) | Phase 1.1 | Avg time-to-first-earnings |
| `creator.gift_sent` + `creator.gift_received` | Phase 1.2 | Streamer earnings curve |
| `creator.payout_settled` | Phase 1.3 | Payout settlement time |
| `creator.tajirika_auto_provisioned` | Phase 1.4 | Creator → business conversion rate |
| `creator.insights_viewed` | Phase 1.5 | Algorithm transparency engagement |
| `creator.off_day_enabled` | Phase 1.7 | Wellness adoption |
| `stream.disconnect_recovered` | Phase 1.6 | Disconnect rate per hour |
| `creator.subscription_started` (subscriber) + `creator.subscriber_added` (creator) | Phase 2.1 | Recurring revenue growth |
| `creator.cross_posted` | Phase 2.2 | Cross-post adoption % |
| `creator.ai_tool_used` (with tool id) | Phase 2.3 | AI feature engagement |
| `commerce.product_pinned` + `commerce.live_purchase` | Phase 2.4 | Live GMV |
| `brand.brief_published` + `brand.brief_applied` + `brand.brief_completed` | Phase 2.5 | Marketplace velocity |

All events written to existing `event_tracking_service` + replicated to Firebase Analytics for dashboarding.

## 11. Risk register

(In addition to the strategy doc's §8.)

| # | Risk | Probability | Impact | Mitigation |
|---|---|---|---|---|
| R1 | `creator_earnings_rates` not actually configured at 5% — defaults to 30% | Medium | High | Day 1 audit task; SQL `INSERT … ON CONFLICT DO UPDATE` to force rate=0.05 |
| R2 | `LiveStreamController::sendGift` doesn't write to creator_earnings | Medium | High | Day 1 audit task; if true, add `CreatorEarning::createFromGift` call (1-line fix) |
| R3 | Wallet integration in `sendTip` is `payment_method=manual` (i.e., no actual money movement) | High | Critical | Day 1 audit task; if true, must fix in Phase 1.1 — block ship until wallet flow works |
| R4 | Settle-payouts cron doesn't exist | High | High | Day 1 audit task; build in Phase 1.3 |
| R5 | TikTok / IG app reviews take longer than expected | Medium | High (Phase 2) | Submit reviews in Week 1, before Phase 2 work starts |
| R6 | Cloudflare Stream Live too expensive at scale | Low | Medium | Negotiate volume tier; alternative: AWS IVS, Mux |
| R7 | Tajiri Pay → mobile money rails (M-Pesa) blocked by regulator | Medium | Critical (the whole 9× thesis) | Engage TZ Bank of Tanzania + mobile money providers in week 1; have legal counsel review |
| R8 | AI compute costs explode at scale | Low | Medium | Use on-device inference (TFLite, Whisper.cpp) for captions; only thumbnails go server-side |
| R9 | Creator opt-in to Tajirika auto-provisioning has friction (e.g., requires NIN) | Medium | High (Phase 1.4) | Auto-provision a "lite" business profile that doesn't require NIN until first invoice |
| R10 | Brand marketplace gets 0 brands at launch | Medium | High (Phase 2.5) | Sales team commits 10+ TZ businesses as launch partners before week 17 |
| R11 | Cross-post API ToS violations get tokens revoked | Low | High (Phase 2.2) | Strict rate-limiting; user-initiated only; no scraping |
| R12 | Creator burnout on US (engineering team) trying to ship 19 features in 7 months | High | High | Hard-prioritize Phase 1; cut Phase 3 if needed |

## 12. Definition of done

A feature is **done** when:
1. ✅ Backend endpoint(s) deployed to `tajiri.zimasystems.com` and tinker-smoke-tested
2. ✅ Frontend screen/widget compiles clean (`flutter analyze` zero new lints)
3. ✅ Playbook compliance verified (§7 checklist)
4. ✅ Bilingual strings added for every user-facing text
5. ✅ Telemetry event(s) firing
6. ✅ Activity log entries (where applicable)
7. ✅ One end-to-end smoke test passes against production database
8. ✅ Per-platform smoke test on real Android device + iOS simulator
9. ✅ 24h soak with internal team before invited beta

A **phase is done** when all its features are done **and** the phase metric (§7 of strategy doc) hits target on a 7-day rolling average.

---

## Appendix: Phase 1 Day-1 audit checklist

Before doing any new work, verify these. Each is a single SQL or grep query.

```bash
# R1: Is the platform fee rate configured at 5% for tips?
PGPASSWORD=postgres psql -h 127.0.0.1 -U postgres -d tajiri -c \
  "SELECT * FROM creator_earnings_rates WHERE metric IN ('tip','gift','sub','sub_renewal') ORDER BY metric;"
# If rows missing or rate ≠ 0.05 → write the migration.

# R2: Does sendGift write to creator_earnings?
grep -A 50 'public function sendGift' app/Http/Controllers/Api/LiveStreamController.php | grep -i 'creator_earning\|CreatorEarning'
# If empty → add the call.

# R3: Does sendTip actually move money via wallet?
grep -A 80 'public function sendTip' app/Http/Controllers/Api/SubscriptionController.php | grep -i 'wallet\|debit\|credit'
# If empty → integrate WalletService.

# R4: Does the settle-payouts cron exist?
ls app/Console/Commands/ | grep -i 'payout\|settle'
# If empty → build it in Phase 1.3.

# R5: What's in the subscriptions table?
PGPASSWORD=postgres psql -h 127.0.0.1 -U postgres -d tajiri -c "\d subscriptions"
# Determines Phase 2.1 scope.
```

Run these in week 1 day 1. They take ~30 minutes total and answer ~80% of the "what's actually built" question.

---

**End of plan.**
