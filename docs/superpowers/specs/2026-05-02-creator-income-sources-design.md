# Creator Income Sources — Design Spec

**Date:** 2026-05-02
**Owner:** Andrew Mashamba
**Status:** Approved (ready for implementation plan)
**Companion docs:**
- `docs/Creators_Streamers_tajiri_strategy.md`
- `docs/Creators_Streamers_implementation_plan.md`
- `docs/ENGINEERING_PLAYBOOK.md`

---

## 1. Goal

Make every way a creator earns money on TAJIRI **clear, transparent, and discoverable** in a single panoramic surface. A creator opening this surface should walk away knowing:

1. **Backward-looking:** how much they made this period, broken down by source.
2. **Forward-looking:** what additional sources exist and exactly how to unlock them.
3. **Educational:** the math behind every shilling — gross, fees, net.

Replaces the existing `lib/creator/screens/earnings_ledger_screen.dart` (which today only addresses #1 with a flat transaction list).

## 2. Design principles

1. **Backend owns eligibility.** Frontend never hardcodes "100 followers" or "Tier 2+". Every lock state, threshold, and unlock rule comes from the backend. Frontend is a pure renderer.
2. **One unified list.** Active and locked sources appear in the same scroll, separated only by state badges. No "earning" tab + "earn more" tab.
3. **State labels on every figure.** Per industry research, every monetary number must carry a state: `EARNING · LIVE · PENDING · LOCKED · READY · PAUSED`.
4. **Net-first display.** Top-line numbers show net (after platform fee). Drill-in shows gross → fee → net breakdown.
5. **Tajiri Pay is the default rail.** "Toa pesa kwa Tajiri Pay" is the primary withdraw CTA on every monetary surface. M-Pesa/Tigo Pesa/Airtel Money may appear as secondary rails in the rail picker, never as the headline.
6. **No competitor comparisons.** Copy states TAJIRI's value directly ("Unabaki na 95%") — never compares to YouTube/Twitch/etc.
7. **Bilingual default.** Swahili is the default user-facing language (since Tanzanian creators are the primary audience). English appears in parens after Swahili tech terms on first use.
8. **Monochrome palette + Engineering Playbook.** `#1A1A1A` / `#FAFAFA` / `#666666` / `#FFFFFF`. 48dp minimum touch targets. SafeArea everywhere. `keyboardDismissBehavior: ScrollViewKeyboardDismissBehavior.onDrag`.

## 3. Mental model & IA decision

**Mental model:** Banking-App Hybrid (M-Pesa / Wise feel — the "C" approach from brainstorming).

```
┌─────────────────────────────────┐
│  Topbar: ‹ Mapato ⚙             │
├─────────────────────────────────┤
│  WALLET HERO (Tajiri Pay)        │
│  Balance · Pending · Lifetime    │
│  [Toa Pesa] [Shughuli]           │
├─────────────────────────────────┤
│  Period pills: Wiki Mwezi Robo Yote │
├─────────────────────────────────┤
│  KPI tiles: Net | Top source | Unlocked count │
├─────────────────────────────────┤
│  Filter chips: Yote · Hai · Lala │
├─────────────────────────────────┤
│  SOURCE LIST (12 rows, mixed states) │
│  · Tips · 142 · EARNING · 86,450  ›  │
│  · Live gifts · LIVE NOW · 60,990  ›  │
│  · Creator Fund · PENDING · 53,300  ›  │
│  · Super Chat · EARNING · 39,500  ›  │
│  · Subscriptions · LOCKED · 47/100 →  │
│  · …                                │
├─────────────────────────────────┤
│  📖 Jifunze: vyanzo vinafanyaje  │
└─────────────────────────────────┘
```

Tapping a row opens the **source detail screen** (active or locked variant — see §6).

**Routing:**
- New route: `/creator/mapato` → `IncomeSourcesScreen`
- Source detail: `/creator/mapato/source/:id` → `IncomeSourceDetailScreen`
- Existing `/creator/dashboard` keeps its tier/streak/multipliers cards but its "View earnings" link redirects to `/creator/mapato`.
- Existing `lib/creator/screens/earnings_ledger_screen.dart` is **deleted**. Its content is now the "Shughuli" (Activity) tab pushed by the wallet hero.

## 4. The canonical 12 sources

| # | ID | Display name (Swahili / English) | Category | Phase | Default unlock criteria (backend-evaluated) |
|---|---|---|---|---|---|
| 1 | `tips` | Tips kwenye posts | Tips | P1 | None — active for everyone |
| 2 | `live_gifts` | Zawadi za Live | Live gifts | P1 | None — active when streaming |
| 3 | `super_chat` | Super Chat | Chat purchases | P1 | None — active when streaming |
| 4 | `creator_fund` | Creator Fund | Pooled fund | Wired | Tier-based (already implemented) |
| 5 | `subscriptions` | Wafuasi wa kulipia | Recurring subs | P2 | 100 followers + verified + recent posting |
| 6 | `ppv_unlocks` | Posts za kufungua | PPV | P2 | 50 followers + verified |
| 7 | `brand_deals` | Kazi za brand (Tajirika) | Sponsored mktplc | P2 | 1k followers + tier ≥2 + content quality gate |
| 8 | `live_commerce` | Biashara live (Tajirika) | Live shopping | P2 | Active Tajirika business + tier ≥1 |
| 9 | `affiliate` | Viungo vya Affiliate | Affiliate | P3 | Tier ≥2 + 500 followers |
| 10 | `paid_services` | Huduma za 1:1 | Service / time | P3 | Tier ≥3 + verified |
| 11 | `digital_goods` | Bidhaa za digital (beats, ebooks, presets) | Digital goods | P3 | Tier ≥2 + 200 followers |
| 12 | `ad_share` | Mgawanyo wa matangazo (Tajirika ads) | Ad revenue share | P3 | 5k followers + tier ≥3 + content quality gate |

**Important:** All criteria above are *defaults seeded into the backend config table*. They are not hardcoded in the frontend or backend code — they live in `income_source_definitions` (see §8) and can be tuned per environment, per region, or per-user via override.

## 5. Source-row anatomy (data contract)

**Money convention:** all monetary fields use `_minor` suffix and are integer minor units (1 TSh = 100 minor units). The frontend divides by 100 for display. This avoids float precision issues end-to-end.

Every source row in the home list and every detail screen consumes the same `IncomeSource` payload from the backend:

```json
{
  "id": "tips",
  "display_name": { "sw": "Tips kwenye posts", "en": "Tips on posts" },
  "category": "tips",
  "icon": "💛",
  "state": "earning",  // earning | live | pending | locked | ready | paused
  "state_label": { "sw": "EARNING", "en": "EARNING" },
  "phase": "p1",
  "current_period": {
    "period": "month",
    "starts_at": "2026-05-01T00:00:00+03:00",
    "ends_at": "2026-05-31T23:59:59+03:00",
    "gross_minor": 9100000,
    "platform_fee_minor": 455000,
    "processing_fee_minor": 0,
    "net_minor": 8645000,
    "currency": "TZS",
    "count": 142,
    "count_label": { "sw": "tips", "en": "tips" },
    "average_minor": 64100,
    "delta_pct_vs_prev": 18
  },
  "math": {
    "formula": "net = gross × (1 - platform_rate) - processing_fee",
    "platform_rate": 0.05,
    "platform_rate_label": { "sw": "Tajiri platform · 5%", "en": "Tajiri platform · 5%" },
    "components": [
      { "key": "gross", "label_sw": "Gross", "label_en": "Gross", "amount_minor": 9100000 },
      { "key": "platform_fee", "label_sw": "Tajiri platform · 5%", "label_en": "Tajiri platform · 5%", "amount_minor": -455000 },
      { "key": "processing_fee", "label_sw": "Tajiri Pay processing", "label_en": "Tajiri Pay processing", "amount_minor": 0 },
      { "key": "net", "label_sw": "Net kwa wallet", "label_en": "Net to wallet", "amount_minor": 8645000, "is_total": true }
    ],
    "own_statement": { "sw": "Unabaki na 95% ya kila tip.", "en": "You keep 95% of every tip." }
  },
  "eligibility": null,            // populated only when state == 'locked' | 'ready'
  "estimate": null,                // populated only when state == 'locked'
  "accelerators": null,            // populated only when state == 'locked'
  "insights": [...],
  "history_endpoint": "/api/creators/{id}/sources/tips/history",
  "settings": [...],
  "primary_cta": { "label_sw": "Toa pesa kwa Tajiri Pay", "label_en": "Withdraw to Tajiri Pay", "action": "withdraw" },
  "secondary_cta": { "label_sw": "Wapi tunaweza kuongeza tips?", "label_en": "Where can we increase tips?", "action": "open_growth_tips" }
}
```

**Locked source variant** populates `eligibility`, `estimate`, `accelerators` instead:

```json
{
  "id": "subscriptions",
  "state": "locked",
  "current_period": null,
  "eligibility": {
    "completion_pct": 50,
    "primary_blocker": "followers_min_100",
    "estimated_unlock_at": null,
    "rules": [
      {
        "key": "verified_account",
        "label_sw": "Akaunti imethibitishwa",
        "label_en": "Account verified",
        "done": true,
        "completed_at": "2026-04-12T09:30:00+03:00",
        "current_value": null,
        "target_value": null
      },
      {
        "key": "followers_min_100",
        "label_sw": "Wafuasi 100",
        "label_en": "100 followers",
        "done": false,
        "current_value": 47,
        "target_value": 100,
        "progress_pct": 47,
        "blocking_reason": null
      },
      {
        "key": "posted_in_last_30_days",
        "label_sw": "Umechapisha mwezi huu",
        "label_en": "Posted in last 30 days",
        "done": true,
        "current_value": 12,
        "target_value": 1
      },
      {
        "key": "tajiri_pay_account_verified",
        "label_sw": "Akaunti ya Tajiri Pay imefunguliwa",
        "label_en": "Tajiri Pay account verified",
        "done": false,
        "blocking_reason": "verifying"
      }
    ]
  },
  "estimate": {
    "amount_per_month_minor": 23750000,
    "currency": "TZS",
    "assumptions_sw": "Kwa wafuasi 50 wanaolipia TSh 5,000",
    "assumptions_en": "For 50 subscribers paying TSh 5,000"
  },
  "accelerators": [
    {
      "key": "post_frequency",
      "icon": "📈",
      "title_sw": "Chapisha angalau mara 4 / wiki",
      "title_en": "Post at least 4× a week",
      "subtitle_sw": "Wafuasi wapya 23% kwa wenye streak",
      "subtitle_en": "23% more new followers for streak holders",
      "deeplink": "/creator/streak-tips"
    },
    ...
  ],
  "primary_cta": { "label_sw": "Niarifu nikifungua", "label_en": "Notify me when unlocked", "action": "subscribe_to_unlock" }
}
```

## 6. State machine

Six states, evaluated by backend per source per request:

| State | When | Visual treatment | Hero amount |
|---|---|---|---|
| `earning` | Source is unlocked & received money in current period | Black hero, badge `EARNING` | Net of period |
| `live` | Source is currently producing money in real-time (live gifts during a stream) | Black hero, badge `LIVE NOW`, pulse animation | Real-time tally |
| `pending` | Money is finalized but not yet paid out (Creator Fund cycle) | Black hero, badge `PENDING`, expected payout date | Expected amount |
| `paused` | Creator manually disabled the source (toggle off) | Grey hero, badge `PAUSED` | Last period net |
| `ready` | All eligibility met but not yet activated/applied | Grey hero, badge `READY`, primary CTA = activate | Estimated potential |
| `locked` | One or more eligibility rules unmet | Grey hero, progress bar, badge `LOCKED` | Progress fraction (e.g. `47 / 100`) |

**State transitions** (all backend-driven):
- `locked → ready`: last eligibility rule passes
- `ready → earning`: creator activates / first transaction
- `earning ↔ live`: stream session starts/ends (only for live_gifts, super_chat)
- `earning → pending`: cycle close (only for creator_fund, ad_share, brand_deals)
- `pending → earning`: payout settles
- `earning ↔ paused`: creator toggles in source settings

## 7. Backend-controlled eligibility (the locks rule)

**Architecture:**

```
[Frontend]                          [Backend]
GET /api/creators/{id}/income/sources
                  ───────────────────►
                                     IncomeSourcesService::forCreator($id)
                                       ├─ load creator stats (followers, tier, posts, tajirika, etc.)
                                       ├─ load income_source_definitions (12 rows)
                                       ├─ for each definition:
                                       │   ├─ EligibilityEvaluator::evaluate(rules, stats)
                                       │   ├─ EarningsAggregator::currentPeriod(creator_id, source_id)
                                       │   ├─ MathBuilder::build(definition, period)
                                       │   └─ assemble IncomeSource payload
                                       └─ return { sources: [...], summary: {...} }
                  ◄───────────────────
[Frontend renders array]
```

**The eligibility rule engine** uses a small DSL stored as JSON in `income_source_definitions.eligibility_rules`:

```json
[
  { "key": "verified_account", "type": "boolean", "field": "user.verified", "expected": true },
  { "key": "followers_min_100", "type": "threshold", "field": "user.followers_count", "operator": ">=", "value": 100 },
  { "key": "posted_in_last_30_days", "type": "count", "field": "posts", "where": "created_at > now - 30d", "operator": ">=", "value": 1 },
  { "key": "tier_min_2", "type": "threshold", "field": "creator_score.tier_rank", "operator": ">=", "value": 2 },
  { "key": "tajirika_business_active", "type": "boolean", "field": "user.has_tajirika_business", "expected": true },
  { "key": "tajiri_pay_account_verified", "type": "enum", "field": "user.tajiri_pay_status", "expected": "verified" },
  { "key": "content_quality_gate", "type": "external", "service": "ContentQualityScorer", "method": "isEligible" }
]
```

Rule types:
- `boolean` — flag check
- `threshold` — numeric comparison
- `count` — count of related records with optional WHERE clause
- `enum` — string equality
- `external` — delegate to a named PHP service (used for things like AI-driven content quality scoring)

**Per-user overrides:**
- `creator_eligibility_overrides` table: `(creator_id, source_id, override_state, override_reason, expires_at)`. Lets ops grant beta access, partnerships, or remove eligibility for ToS violations.

**Per-region tuning:**
- `income_source_definitions` is keyed by `(source_id, region_code)`. Default region `TZ` for now; lets us ship looser thresholds in new markets later.

## 8. Backend contract — endpoints

### 8.1 Get all income sources for a creator

```
GET /api/creators/{creator_id}/income/sources?period=month&locale=sw
Response 200:
{
  "summary": {
    "wallet_balance_minor": 18430000,
    "wallet_pending_minor": 6420000,
    "wallet_lifetime_minor": 240000000,
    "currency": "TZS",
    "this_period_net_minor": 24850000,
    "this_period_delta_pct": 18,
    "top_source_id": "tips",
    "top_source_share_pct": 37,
    "unlocked_count": 4,
    "total_count": 12
  },
  "period": { "type": "month", "starts_at": "...", "ends_at": "..." },
  "sources": [ {IncomeSource}, ... ]
}
```

Period values: `week` (trailing 7d), `month` (calendar month), `quarter` (trailing 90d), `all` (lifetime).

### 8.2 Get one source's full detail

```
GET /api/creators/{creator_id}/income/sources/{source_id}?period=month&locale=sw
Response 200: { IncomeSource } with full insights, history page 1, settings, accelerators
```

### 8.3 Get source's history (paginated)

```
GET /api/creators/{creator_id}/income/sources/{source_id}/history?cursor=...&limit=20
Response 200: { items: [...], next_cursor: "..." }
```

Each history item is normalized:
```json
{
  "id": "tx_abc123",
  "occurred_at": "2026-05-02T18:30:00+03:00",
  "actor": { "id": 451, "username": "nyamiti", "avatar_url": "..." },
  "gross_minor": 100000,
  "net_minor": 95000,
  "currency": "TZS",
  "message": "Asante!",
  "post_id": null,
  "stream_id": null,
  "metadata": {}
}
```

### 8.4 Source-specific settings

```
PATCH /api/creators/{creator_id}/income/sources/{source_id}/settings
Body: { "enabled": true, "min_amount_minor": 10000, "presets_minor": [50000, 100000, ...] }
Response 200: { settings: {...} }
```

Settings shape varies per source (Tips has min/presets; Subs has tier prices; Ad share has opt-in only). Backend validates per-source schema.

### 8.5 Activate a "ready" source

```
POST /api/creators/{creator_id}/income/sources/{source_id}/activate
Response 200: { source: {IncomeSource} }   // state transitions ready → earning
```

### 8.6 Subscribe to unlock notification

```
POST /api/creators/{creator_id}/income/sources/{source_id}/notify-on-unlock
Response 200: { subscribed: true }
```

When the rule engine flips the source to `ready`, FCM fires `creator.source.unlocked` to the creator.

## 9. Existing infrastructure mapping

What's already in place that this spec consumes:

| Need | Existing infrastructure | Notes |
|---|---|---|
| Tips ledger | `creator_tips` table, `POST /subscriptions/tips` | Wired |
| Live gifts ledger | `stream_gifts`, `virtual_gifts`, `POST /streams/{id}/gifts` | Wired |
| Creator Fund pool | `creator_fund_pools`, `creator_fund_payouts`, `GET /api/fund-pool/current` | Wired |
| Subscriptions | `subscriptions` table, `subscription_models.dart` | Schema needs verification (see §10) |
| Wallet | `wallets`, `wallet_transactions`, `Wallet.adBalance` field | Wired |
| Earnings rates | `creator_earnings_rates` (per-source % config) | Wired (verify rates seeded at 5%) |
| Unified earnings | `creator_earnings` table with `type` enum | Wired |
| Sponsored posts | `SponsoredPost` model, `lib/models/sponsored_post_models.dart` | Used by ad_share computation |
| Creator score / tier | `creator_scores`, `CreatorService.getCreatorScore()` | Wired |
| Streaks | `creator_streaks` | Wired (used by accelerators) |

## 10. New backend work

### 10.1 New tables

```sql
-- The 12 source definitions, region-keyed
CREATE TABLE income_source_definitions (
  id BIGSERIAL PRIMARY KEY,
  source_id VARCHAR(64) NOT NULL,           -- 'tips', 'subscriptions', etc.
  region_code VARCHAR(8) NOT NULL DEFAULT 'TZ',
  display_name JSONB NOT NULL,              -- { "sw": "...", "en": "..." }
  category VARCHAR(64) NOT NULL,
  icon VARCHAR(8),
  phase VARCHAR(8),                         -- 'p1' | 'p2' | 'p3'
  eligibility_rules JSONB NOT NULL,         -- DSL array (see §7)
  math_template JSONB NOT NULL,             -- formula + components template
  primary_cta JSONB,
  secondary_cta JSONB,
  enabled BOOLEAN DEFAULT true,
  sort_order INTEGER DEFAULT 0,
  created_at TIMESTAMPTZ DEFAULT NOW(),
  updated_at TIMESTAMPTZ DEFAULT NOW(),
  UNIQUE(source_id, region_code)
);

-- Per-creator overrides for ops/partnership flexibility
CREATE TABLE creator_eligibility_overrides (
  id BIGSERIAL PRIMARY KEY,
  creator_id BIGINT NOT NULL REFERENCES users(id),
  source_id VARCHAR(64) NOT NULL,
  override_state VARCHAR(16),               -- forces a specific state, NULL = use computed
  override_reason TEXT,
  granted_by BIGINT REFERENCES users(id),
  expires_at TIMESTAMPTZ,
  created_at TIMESTAMPTZ DEFAULT NOW()
);
CREATE INDEX idx_eligibility_overrides_creator_source
  ON creator_eligibility_overrides (creator_id, source_id);

-- Notify-me-on-unlock subscriptions
CREATE TABLE creator_unlock_notifications (
  id BIGSERIAL PRIMARY KEY,
  creator_id BIGINT NOT NULL REFERENCES users(id),
  source_id VARCHAR(64) NOT NULL,
  notified_at TIMESTAMPTZ,
  created_at TIMESTAMPTZ DEFAULT NOW(),
  UNIQUE(creator_id, source_id)
);
```

### 10.2 New services

- `IncomeSourcesService` — orchestrator, returns the unified payload.
- `EligibilityEvaluator` — runs the rule DSL against a creator's stats.
- `EarningsAggregator` — period-bucketed sums from `creator_earnings`.
- `MathBuilder` — instantiates the math template with real numbers per source.
- `ContentQualityScorer` (stub for v1) — returns true/false; later wires to AI moderation.

### 10.3 New controllers / routes

- `IncomeSourcesController` — handles all 6 endpoints in §8.
- Background job: `ProcessUnlockNotifications` runs hourly, checks `creator_unlock_notifications` for newly-eligible creators, fires FCM.

### 10.4 Seed data

`income_source_definitions` seeded with all 12 rows + default `TZ` thresholds from §4.

## 11. Streamer-specific behavior

When the creator is currently live streaming (detected via `live_streams` table where `ended_at IS NULL` AND `host_id = creator_id`):

1. **Pinned LIVE card** at the very top of the source list, above all 12 rows.
   - Title: "🔴 Unalipwa sasa hivi" (You're earning right now)
   - Real-time accumulating: gifts received + super chats received this session.
   - Tap → unified live earnings detail (combines `live_gifts` + `super_chat` for this session).
2. **`live_gifts` and `super_chat` rows** show state `LIVE` instead of `EARNING`, with pulse animation on the badge.
3. **Real-time updates** via the existing Reverb WebSocket — `creator.live.earnings.updated` channel pushes incremental gross/net deltas every ~5 seconds during a stream.
4. **Post-stream**: when stream ends (`ended_at` set), pinned card morphs into a "Stream summary" card for ~24h showing total earned that session, then disappears.

This is the only meaningful difference between "creator" and "streamer" UX — both are creators in the data model, but an active stream changes 2 rows + adds 1 pinned card.

## 12. Bilingual strings

All copy is bilingual via `AppStringsScope`. Default language per `LanguageNotifier`. New keys to add to `AppStrings`:

```dart
String get incomeSourcesTitle => isSwahili ? 'Mapato' : 'Income';
String get walletLabel => isSwahili ? 'TAJIRI PAY · WALLET' : 'TAJIRI PAY · WALLET';
String get withdrawToTajiriPay => isSwahili ? 'Toa pesa kwa Tajiri Pay' : 'Withdraw to Tajiri Pay';
String get activityLabel => isSwahili ? 'Shughuli' : 'Activity';
String get periodWeek => isSwahili ? 'Wiki' : 'Week';
String get periodMonth => isSwahili ? 'Mwezi' : 'Month';
String get periodQuarter => isSwahili ? 'Robo' : 'Quarter';
String get periodAll => isSwahili ? 'Yote' : 'All time';
String get thisMonthKpi => isSwahili ? 'MWEZI HUU' : 'THIS MONTH';
String get topSourceKpi => isSwahili ? 'CHANZO BORA' : 'TOP SOURCE';
String get unlockedCountKpi => isSwahili ? 'VIMEFUNGULIWA' : 'UNLOCKED';
String get sourcesHeader => isSwahili ? 'Vyanzo vya Mapato' : 'Income Sources';
String get filterAll => isSwahili ? 'Yote' : 'All';
String get filterActive => isSwahili ? 'Hai' : 'Active';
String get filterLocked => isSwahili ? 'Lala' : 'Locked';
String get howItWorksLink => isSwahili ? 'Jifunze: vyanzo vyote vinafanyaje kazi' : 'Learn how each source works';
String get mathSectionTitle => isSwahili ? 'Hesabu' : 'Math';
String get insightsSectionTitle => isSwahili ? 'Maarifa' : 'Insights';
String get recentSectionTitle => isSwahili ? 'Hivi karibuni' : 'Recent';
String get settingsSectionTitle => isSwahili ? 'Mipangilio' : 'Settings';
String get whatIsItSectionTitle => isSwahili ? 'Ni nini?' : 'What is it?';
String get unlockCriteriaTitle => isSwahili ? 'Vigezo vya kufungua' : 'Unlock criteria';
String get acceleratorsTitle => isSwahili ? 'Jinsi ya kufungua haraka' : 'How to unlock faster';
String get estimateLabel => isSwahili ? 'UKADIRIO WAKO' : 'YOUR ESTIMATE';
String get notifyOnUnlock => isSwahili ? 'Niarifu nikifungua' : 'Notify me when unlocked';
String get learnHow => isSwahili ? 'Soma jinsi inafanya kazi' : 'Read how it works';
String get liveNow => isSwahili ? 'LIVE NOW' : 'LIVE NOW';
String get earningRightNow => isSwahili ? 'Unalipwa sasa hivi' : 'You\'re earning right now';

// State badges (capitalized labels — kept in English for visual consistency)
String get stateEarning => 'EARNING';
String get statePending => 'PENDING';
String get stateLocked => 'LOCKED';
String get stateReady => 'READY';
String get statePaused => 'PAUSED';
```

Source display names and labels are returned by the backend (in `display_name.sw` / `display_name.en`), so they don't go in `AppStrings`.

## 13. Empty states

- **No earnings yet** (state = earning, gross=0): Hero shows TSh 0 with "Anza kupata Tips kwenye post yako ya kwanza" subtitle. Settings still accessible.
- **All sources locked** (new creator): Top of list shows a pinned banner: "Karibu! Tips ni chanzo cha kwanza — anza sasa." Filter chips default to "All".
- **No active stream** (live_gifts state = earning, count=0): row shows "Anza live ili kupokea zawadi" subtitle.
- **No history**: detail screen shows skeleton with "Hapana shughuli bado" (No activity yet).

## 14. Engineering Playbook compliance checklist

For every file touched/created:

- [ ] `SafeArea` wraps every screen.
- [ ] `keyboardDismissBehavior: ScrollViewKeyboardDismissBehavior.onDrag` on all scrollables.
- [ ] `scrolledUnderElevation: 1` on all `AppBar`s.
- [ ] All dynamic text has `maxLines` + `TextOverflow.ellipsis`.
- [ ] All buttons ≥ 48dp tall.
- [ ] All tappable elements wrapped in `Material(color: Colors.transparent)` + `InkWell` for ripple feedback.
- [ ] All controllers (`ScrollController`, `TextEditingController`, `AnimationController`) disposed in `dispose()`.
- [ ] All state-changing setState calls guarded by `if (mounted)`.
- [ ] Inline feedback patterns: error chips inline (not SnackBars), success states render in-place.
- [ ] Optimistic-with-revert for settings toggles (Tips on/off, etc.) — flip the toggle immediately, revert + show inline error on backend failure.
- [ ] Monochrome only — no colored accents. State badges use semantic background tints (`#E8F5E9`/`#FFF8E1`/`#F2F2F2`/`#E3F2FD`/`#FCE4EC`) but text stays grey/black.
- [ ] Bilingual via `AppStringsScope.of(context)` — never hardcoded literals.
- [ ] Currency rendered through a single `formatTzs()` helper — same throughout.
- [ ] All network calls wrapped in try/catch with `if (!mounted) return` after await.

## 15. Files plan

**New files:**
- `lib/creator/screens/income_sources_screen.dart` — home view (§3 IA).
- `lib/creator/screens/income_source_detail_screen.dart` — detail view (active + locked variants, §6).
- `lib/creator/screens/income_activity_screen.dart` — full Tajiri Pay wallet activity (replaces earnings_ledger_screen functionality).
- `lib/creator/widgets/source_row_card.dart` — single row in the list.
- `lib/creator/widgets/wallet_hero_card.dart` — Tajiri Pay hero block.
- `lib/creator/widgets/period_pill_selector.dart` — week/month/quarter/all pills.
- `lib/creator/widgets/kpi_tile.dart` — the 3 KPI tiles.
- `lib/creator/widgets/state_badge.dart` — EARNING/LIVE/PENDING/LOCKED/READY/PAUSED pill.
- `lib/creator/widgets/math_card.dart` — gross→fee→net with formula + own_statement.
- `lib/creator/widgets/eligibility_checklist.dart` — done/todo rule list.
- `lib/creator/widgets/estimate_card.dart` — locked-source earnings estimate hero.
- `lib/creator/widgets/accelerator_row.dart` — "post 4× a week", "collab", etc.
- `lib/creator/widgets/live_pinned_card.dart` — streamer-only pinned card (§11).
- `lib/creator/models/income_source.dart` — `IncomeSource`, `EligibilityRule`, `MathComponent`, `Accelerator`, `IncomeSummary`, `Period`.
- `lib/creator/services/income_sources_service.dart` — thin client for `/api/creators/{id}/income/...` endpoints.

**Modified files:**
- `lib/creator/screens/dashboard_section.dart` — "View earnings" link now navigates to `/creator/mapato`.
- `lib/main.dart` — register `/creator/mapato` and `/creator/mapato/source/:id` routes.
- `lib/l10n/app_strings.dart` — add the keys in §12.
- `lib/services/fcm_service.dart` — handle `creator.source.unlocked` payload → deep-link to `/creator/mapato/source/{id}`.

**Deleted files:**
- `lib/creator/screens/earnings_ledger_screen.dart` — superseded.

## 16. Decisions deferred to the implementation plan

- **Real-time tally cadence** for live streams (5s polling vs Reverb push) — depends on scaling tests.
- **Math template evaluation** — server-side templating language vs hardcoded per-source math methods. Lean toward hardcoded methods in v1 to ship faster; abstract in v2 if more sources arrive.
- **Charting library** — sparkline can be CustomPainter (no dep). Detail-screen charts (post-MVP nice-to-have) can defer to fl_chart only if needed.
- **Caching strategy** — sources payload TTL (suggested 60s for active sources, 5min for locked).
- **Activity feed migration** — does the new `IncomeActivityScreen` reuse any of the deleted `earnings_ledger_screen.dart` code or rebuild fresh? Plan stage decides.

## 17. Acceptance criteria

For sign-off:

1. Creator opens Mapato → sees wallet hero, KPI tiles, all 12 source rows in correct state.
2. Tapping any active row → drill-in shows hero net, math, insights, history, settings, CTA. All copy is bilingual.
3. Tapping any locked row → drill-in shows progress hero, eligibility checklist with current vs target, estimate card, accelerators.
4. Backend can flip a source's eligibility threshold via `income_source_definitions` update — frontend reflects the new threshold on next request without a deploy.
5. Per-creator override in `creator_eligibility_overrides` correctly grants/revokes access.
6. Tajiri Pay primary CTA navigates to existing withdraw flow.
7. Active stream → pinned LIVE card appears; stream ends → card morphs to "Stream summary" for 24h.
8. State badges match the 6-state machine.
9. No M-Pesa text appears anywhere outside the rail-picker subscreen.
10. No competitor names appear anywhere in user-facing copy.
11. Engineering Playbook checklist passes for every new file.
