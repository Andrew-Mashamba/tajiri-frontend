# Creators Fund / Post Earnings Engine Implementation Plan

> **For agentic workers:** REQUIRED SUB-SKILL: Use superpowers:subagent-driven-development (recommended) or superpowers:executing-plans to implement this plan task-by-task. Steps use checkbox (`- [ ]`) syntax for tracking.

**Goal:** Replace today's read-time `posts.*_count × creator_earnings_rates` formula in `app/Http/Controllers/Api/PostEarningsController.php` with an event-driven Creators Fund engine that pays creators and content contributors from a TAJIRI-controlled fund (Phase 1) or 70/30 ad rev-share (Phase 2), posts every credit to COA/journal_lines, surfaces full per-event provenance, and disburses to mobile money via Tajiri Pay — making TAJIRI 9× better for African creators than YouTube / TikTok / Instagram / Twitch.

**Architecture:** A central `EarningsEngine` service owns one entrypoint (`recordEvent`) that every existing engagement endpoint (view / like / comment / share / save / follow / subscribe / live-gift / marketplace-order / derivative-content) calls. Each call writes one immutable row to `earning_events` with full provenance (rate × multipliers × actor_role × stream × is_chargeable), increments `creators_fund_points` for the active `creators_fund_periods` row, and posts a real-time COA `journal_lines` entry into a per-stream "Pending Creator Earnings" liability bucket. A weekly `CreatorsFundPeriodSettlementJob` closes the period, computes `fund_per_point = fund_size / total_points`, and resolves estimates to actuals; a daily `SettlementSweepJob` moves rows ≥30 days old (45 days for fan-funding) from pending → cleared, deducts TRA Section 83B WHT, and a daily `PayoutDisbursementJob` credits Tajiri Pay wallets for any creator whose cleared balance ≥ TZS 5,000. Multipliers (watch-completion, originality, Mwanzo boost, streak, discovery, tier-boost) are applied at event-write by `MultiplierEngine`, anti-abuse rules by `AbuseGuard`. Phase 1 (treasury-funded CAC) and Phase 2 (70/30 ad rev-share) share the same plumbing — only the fund-size formula on `creators_fund_periods` changes.

**Tech Stack:** Laravel 12 + PostgreSQL 16 (backend), Flutter 3.10+ Dart (frontend), Tajiri Pay (payouts), TRA digital portal (tax remittance).

**Status:** drafted 2026-05-03 from `docs/post_earnings_tajiri_strategy.md` v3.

---

## Pre-flight: current state inventory

### What exists today (read-only — do not touch unless modifying)

| File / table | Description |
|---|---|
| `app/Http/Controllers/Api/PostEarningsController.php` | Single `earnings(int $postId)` method that multiplies `posts.*_count × creator_earnings_rates.rate` and returns a JSON estimate. No persistence, no per-event ledger, no payout. |
| `database/migrations/2026_03_25_155714_create_creator_earnings_rates_table.php` | Six rates seeded: `view=0.5`, `like=2.0`, `share=5.0`, `save=3.0`, `comment=2.5`, `watch_second=0.1`. Schema: `id`, `metric` (unique), `rate decimal(10,4)`, `is_active bool`, timestamps. |
| `database/migrations/2026_01_09_173401_create_posts_table.php` | `posts` table includes `comments_count`. Hybrid-feed enhancement (below) adds `views_count`, `likes_count`, `shares_count`, `saves_count`, `watch_time_seconds`, `impressions_count`. |
| `database/migrations/2026_01_10_100001_enhance_posts_for_hybrid_feed.php` | Creates `post_views` and `post_saves` tables; adds counters on `posts`. These remain the read-model counters. |
| `database/migrations/2026_01_09_173402_create_post_likes_table.php` | `post_likes(post_id, user_id, reaction_type ENUM('like','love','haha','wow','sad','angry'))`. Six reaction types per strategy §2.4 — flat-rate. |
| `database/migrations/2026_01_09_173403_create_comments_table.php` | `comments` table with optional `parent_id` for replies. |
| `database/migrations/2026_02_14_120000_create_comment_likes_table.php` | `comment_likes(comment_id, user_id)`. |
| `database/migrations/2026_02_17_100000_create_user_follows_table.php` | `user_follows(follower_id, following_id)`. No `origin_post_id` column yet — added in this plan. |
| `database/migrations/2026_01_09_210103_create_livestream_tables.php` | `stream_gifts` table for live gifts. |
| `database/migrations/2026_01_10_100001_create_subscriptions_tables.php` | Subscriptions table; references `stream_gifts.gift_id`. |
| `database/migrations/2026_01_10_100003_create_tajiri_pay_tables.php` | Creates `wallets`, `mobile_money_accounts`, `wallet_transactions` tables. Wallet-credit pattern is the payout target. |
| `database/migrations/2026_03_01_100000_create_shop_tables.php` | Shop / `shop_orders` table — marketplace stream funding source. |
| `app/Http/Controllers/Api/PostController.php` | Has `like`, `unlike`, `share`, `recordView`, `savePost`, `unsavePost`, `store` (with optional `reply_to_post_id`/`stitch_from_post_id`/`quote_from_post_id`). Hook target. |
| `app/Http/Controllers/Api/CommentController.php` | Has `store` (with `parent_id`), `like`, `unlike`. Hook target. |
| `app/Http/Controllers/Api/FollowController.php` | `follow`, `unfollow`. Hook target — needs `origin_post_id` request param. |
| `app/Http/Controllers/Api/SubscriptionController.php` | Hook target for fan_funding stream. |
| `app/Http/Controllers/Api/LiveStreamController.php` | `sendGift`, route at `streams/{id}/gifts`. Hook target. |
| `app/Http/Controllers/Api/AdvancedStreamController.php` | `storeReaction` at `streams/{id}/reactions`. Hook target for live-stream metric. |
| `app/Http/Controllers/Api/V1/Shop/ShopOrderController.php` | `store` at `marketplace/orders` (also exposed at `shop/orders`). Hook target for marketplace stream. |
| `app/Http/Controllers/Api/WalletController.php` | Wallet credit / withdrawal pattern — payout target. |
| `routes/api.php` | All the engagement endpoints listed above are under `posts/`, `comments/`, `follows/`, `streams/`, `shop/orders`. |

### What we extend (existing files modified)

| File | What we add |
|---|---|
| `database/migrations/2026_03_25_155714_create_creator_earnings_rates_table.php` (via NEW migration) | Add columns: `actor_role`, `stream`, `effective_from`, `effective_until`, `tier_minimum`, `max_cap_tsh`. Re-seed expanded rate matrix. |
| `app/Http/Controllers/Api/PostEarningsController.php` | Replace `earnings()` body to read from `earning_events`. Add `earningsEvents()`, `enableDiscoveryMode()`. |
| `app/Http/Controllers/Api/PostController.php` | Inject `EarningsEngine` calls into `recordView`, `like`, `unlike`, `share`, `savePost`, `unsavePost`, `store` (derivative branches). |
| `app/Http/Controllers/Api/CommentController.php` | Inject `EarningsEngine` calls into `store` (comment + reply branches), `like`, `unlike`. |
| `app/Http/Controllers/Api/FollowController.php` | Add `origin_post_id` request param; on follow, fire `metric=follow_from_post` if set. |
| `app/Http/Controllers/Api/SubscriptionController.php` | Same, with `origin_post_id`. |
| `app/Http/Controllers/Api/LiveStreamController.php` | `sendGift` → `EarningsEngine::recordEvent` for `metric=live_gift`. |
| `app/Http/Controllers/Api/AdvancedStreamController.php` | `storeReaction` → `EarningsEngine::recordEvent` for `metric=live_reaction`. |
| `app/Http/Controllers/Api/V1/Shop/ShopOrderController.php` | After order creation, if `post_id` present, fire `metric=marketplace_sale`. |
| `routes/api.php` | Add `posts/{id}/earnings/events`, `posts/{id}/discovery-mode`, `users/me/earnings`, `users/me/earnings/events`, `users/me/earnings/tax`, `users/me/earnings/disputes`, `creators/rate-card` routes. |
| `app/Console/Kernel.php` (or `routes/console.php`) | Schedule the 6 background jobs. |
| `lib/screens/profile/profile_screen.dart` (Flutter) | Wire new earnings-tab navigation. |
| `lib/main.dart` (Flutter) | Add 4 new routes (`/creator-earnings`, `/post-earnings-v2`, `/earnings-provenance`, `/creator-tier`). |

### What's net new (created by this plan)

| File | Purpose |
|---|---|
| `database/migrations/2026_05_03_000001_extend_creator_earnings_rates.php` | Adds actor_role / stream / effective_from / effective_until / tier_minimum / max_cap_tsh columns and re-seeds. |
| `database/migrations/2026_05_03_000002_create_earning_events_table.php` | Immutable per-event ledger keyed for idempotency (strategy §12.1). |
| `database/migrations/2026_05_03_000003_create_creator_tiers_table.php` | One row per creator: tier, mwanzo_expires_at, strike_count, payout_preference. |
| `database/migrations/2026_05_03_000004_create_creators_fund_periods_table.php` | Weekly fund-period rows; phase + fund-size + fund_per_point + settlement state. |
| `database/migrations/2026_05_03_000005_create_creators_fund_points_table.php` | Per-creator points accumulator within an active period. |
| `database/migrations/2026_05_03_000006_create_earnings_reserve_ledger_table.php` | Reserve-fund delta log (5% accrual + drawdowns). |
| `database/migrations/2026_05_03_000007_create_earnings_coa_accounts.php` | Idempotent insert of accounts 2105 / 2110-2114 / 2120 / 2130 / 2140 / 4115 / 4120-4150 / 5110 / 5111 into `chart_of_accounts`. |
| `database/migrations/2026_05_03_000008_create_post_share_attributions_table.php` | Tracks the sharer chain so downstream views/reactions credit the sharer (B+C). |
| `database/migrations/2026_05_03_000009_add_origin_post_id_to_user_follows.php` | Origin attribution for discovery credit on follow. |
| `database/migrations/2026_05_03_000010_add_origin_post_id_to_subscriptions.php` | Same for subscriptions. |
| `database/migrations/2026_05_03_000011_add_discovery_mode_to_posts.php` | `is_discovery_mode bool` and `discovery_mode_until timestamp` on posts. |
| `app/Models/EarningEvent.php` | Eloquent model. |
| `app/Models/CreatorTier.php` | Eloquent model with `forUser()` factory + `isAtLeast()` helper. |
| `app/Models/CreatorsFundPeriod.php` | Model with `currentOpen()` / `openNextPeriod()` static helpers. |
| `app/Models/CreatorsFundPoint.php` | Model. |
| `app/Services/CreatorEarningsRateRegistry.php` | Single source for resolving (metric, actor_role, stream, tier) → rate + cap. |
| `app/Services/MultiplierEngine.php` | Computes the 6 multipliers; exposes `combined()`. |
| `app/Services/EarningsEngine.php` | Central `recordEvent` entrypoint — anti-abuse → multipliers → points → journal. |
| `app/Services/CreatorTierService.php` | `evaluate`, `promote`, `demote`, `checkInactivity`, `forUser`. |
| `app/Services/AbuseGuard.php` | All v1 anti-abuse rules. |
| `app/Services/PayoutService.php` | Wallet-credit wrapper. |
| `app/Services/TaxInvoiceService.php` | Stub digital-tax-invoice JSON generator. |
| `app/Services/Earnings/EarningEventDto.php` | Request DTO into `recordEvent`. |
| `app/Jobs/CreatorsFundPeriodSettlementJob.php` | Weekly. |
| `app/Jobs/SettlementSweepJob.php` | Daily. |
| `app/Jobs/MwanzoExpiryJob.php` | Daily. |
| `app/Jobs/TierReviewJob.php` | Daily — covered in partial Task 44. |
| `app/Jobs/PayoutDisbursementJob.php` | Daily — covered in partial Task 45. |
| `app/Jobs/TRARemittanceJob.php` | Monthly — covered in partial Task 46. |
| `app/Http/Controllers/Api/CreatorEarningsController.php` | New endpoints: dashboard / events / rate-card / tax / disputes. |
| `database/seeders/CreatorsFundCoaSeeder.php` | Idempotent COA-account seeder (referenced in Task 7). |
| `database/seeders/CreatorsFundInitialPeriodSeeder.php` | Opens the very first `creators_fund_periods` row at deploy time. |
| `config/earnings.php` | WHT rate, min payout, soft caps, window days. |
| `config/earnings_multipliers.php` | Watch-completion table. |
| `config/creator_tiers.php` | Tier gates. |
| `lib/models/creator_earnings_models.dart` | Flutter models. |
| `lib/services/creator_earnings_service.dart` | Flutter service. |
| `lib/screens/profile/creator_earnings_dashboard_screen.dart` | Cross-stream dashboard. |
| `lib/screens/profile/earnings_provenance_screen.dart` | Per-event ledger. |
| `lib/screens/profile/creator_tier_screen.dart` | Tier ladder + Mwanzo countdown. |

---

## v1 — Creators Fund (Phase 1) + payouts (target: 6 weeks)

Ships in **Phase 1 mode** per strategy §1.2: no advertiser revenue assumed; creators paid from a TAJIRI-treasury-funded weekly committed budget (TZS 50M / week initial). All plumbing also supports Phase 2; only the period's fund-size formula differs.

### Task-group overview

| Group | Tasks | Theme |
|---|---|---|
| Backend schema + COA | 1–10 | All migrations + Eloquent models |
| Rate registry + multipliers | 11–15 | Rate lookup + 6 multipliers |
| EarningsEngine core | 16–22 | Central `recordEvent` service + DTO + AbuseGuard + tests scaffold |
| Tier service | 23–25 | `CreatorTierService` + tier-resolution trait |
| Event-hook integration | 26–40 | Wire `EarningsEngine::recordEvent` into 15 existing endpoints |
| Settlement / sweep jobs | 41–43 | Weekly fund settlement + daily pending→cleared sweep + Mwanzo expiry |
| Background jobs (tier / payout / tax) | 44–46 | TierReviewJob, PayoutDisbursementJob, TRARemittanceJob |
| Read endpoints | 47–52 | Rewritten earnings reads + dashboard + rate card + disputes + discovery |
| Payout + TRA wires | 53–59 | PayoutService, mobile-money rails, WHT config + auto-deduct + tax invoice |
| Frontend | 60–76 | Flutter models, services, screens, navigation wiring |
| Tests + deploy | 77–84 | Backfill policy, unit + feature + widget tests, deploy checklist, rollout |

---

### Backend schema + COA setup (Tasks 1–10)

---

#### Task 1 — Migration: extend `creator_earnings_rates`

**Files:**
- Create: `database/migrations/2026_05_03_000001_extend_creator_earnings_rates.php`

Add the columns required by strategy §12.1 (`actor_role`, `stream`, `effective_from`, `effective_until`, `tier_minimum`) plus a `max_cap_tsh` column for the per-event caps in §10.3, then re-seed the expanded rate matrix that includes secondary-earner rows (sharer / host_share / comment_author / parent_thread / original_creator_royalty) per the §2 attribution table.

- [ ] Create the migration:

```php
<?php
use Illuminate\Database\Migrations\Migration;
use Illuminate\Database\Schema\Blueprint;
use Illuminate\Support\Facades\DB;
use Illuminate\Support\Facades\Schema;

return new class extends Migration
{
    public function up(): void
    {
        Schema::table('creator_earnings_rates', function (Blueprint $table) {
            // Drop the unique on metric — composite (metric, actor_role, stream, effective_from) becomes the new natural key
            $table->dropUnique(['metric']);

            $table->string('actor_role')->default('author')->after('metric');
            $table->string('stream')->default('engagement')->after('actor_role');
            $table->timestampTz('effective_from')->default(DB::raw('CURRENT_TIMESTAMP'))->after('rate');
            $table->timestampTz('effective_until')->nullable()->after('effective_from');
            $table->string('tier_minimum')->nullable()->after('effective_until');     // 'mwanzo'|'standard'|'verified'|'partner'
            $table->decimal('max_cap_tsh', 10, 4)->nullable()->after('tier_minimum'); // §10.3 per-event cap

            $table->unique(['metric', 'actor_role', 'stream', 'effective_from'], 'cer_natural_key');
            $table->index(['stream', 'metric', 'is_active']);
        });

        // Re-seed expanded matrix (per strategy §2 attribution + §10.3 caps).
        $now = now();
        $rows = [
            // Engagement stream — primary author rates
            ['metric'=>'view',         'actor_role'=>'author',         'stream'=>'engagement', 'rate'=>0.50, 'max_cap_tsh'=>5.00,   'tier_minimum'=>'mwanzo'],
            ['metric'=>'reaction',     'actor_role'=>'author',         'stream'=>'engagement', 'rate'=>2.00, 'max_cap_tsh'=>50.00,  'tier_minimum'=>'mwanzo'],
            ['metric'=>'comment',      'actor_role'=>'author',         'stream'=>'engagement', 'rate'=>2.50, 'max_cap_tsh'=>100.00, 'tier_minimum'=>'mwanzo'],
            ['metric'=>'reply',        'actor_role'=>'author',         'stream'=>'engagement', 'rate'=>2.50, 'max_cap_tsh'=>100.00, 'tier_minimum'=>'mwanzo'],
            ['metric'=>'share',        'actor_role'=>'author',         'stream'=>'engagement', 'rate'=>5.00, 'max_cap_tsh'=>200.00, 'tier_minimum'=>'mwanzo'],
            ['metric'=>'save',         'actor_role'=>'author',         'stream'=>'engagement', 'rate'=>3.00, 'max_cap_tsh'=>50.00,  'tier_minimum'=>'mwanzo'],
            ['metric'=>'watch_second', 'actor_role'=>'author',         'stream'=>'engagement', 'rate'=>0.10, 'max_cap_tsh'=>1.00,   'tier_minimum'=>'mwanzo'],

            // Engagement stream — comment_author secondary credit (§2.1 reaction-on-comment)
            ['metric'=>'comment_reaction', 'actor_role'=>'comment_author', 'stream'=>'engagement', 'rate'=>1.00, 'max_cap_tsh'=>30.00, 'tier_minimum'=>'mwanzo'],
            ['metric'=>'reply',            'actor_role'=>'comment_author', 'stream'=>'engagement', 'rate'=>0.75, 'max_cap_tsh'=>30.00, 'tier_minimum'=>'mwanzo'],

            // Engagement stream — host_share (post author when their comment section earns) (§2.1)
            ['metric'=>'comment_reaction', 'actor_role'=>'host',           'stream'=>'engagement', 'rate'=>0.25, 'max_cap_tsh'=>10.00, 'tier_minimum'=>'mwanzo'],

            // Engagement stream — sharer discovery credits (§2.1)
            ['metric'=>'view',     'actor_role'=>'sharer', 'stream'=>'engagement', 'rate'=>0.10, 'max_cap_tsh'=>2.00,   'tier_minimum'=>'mwanzo'],
            ['metric'=>'reaction', 'actor_role'=>'sharer', 'stream'=>'engagement', 'rate'=>0.40, 'max_cap_tsh'=>10.00,  'tier_minimum'=>'mwanzo'],
            ['metric'=>'share',    'actor_role'=>'sharer', 'stream'=>'engagement', 'rate'=>1.00, 'max_cap_tsh'=>40.00,  'tier_minimum'=>'mwanzo'],

            // Engagement stream — derivative royalty (§2.2)
            ['metric'=>'derivative_royalty', 'actor_role'=>'original_creator_royalty', 'stream'=>'engagement', 'rate'=>0.30, 'max_cap_tsh'=>500.00, 'tier_minimum'=>'mwanzo'],

            // Engagement stream — discovery (§2.1: follow / subscribe from post)
            ['metric'=>'follow_from_post',    'actor_role'=>'author', 'stream'=>'engagement', 'rate'=>10.0,  'max_cap_tsh'=>50.00,  'tier_minimum'=>'mwanzo'],
            ['metric'=>'subscribe_from_post', 'actor_role'=>'author', 'stream'=>'engagement', 'rate'=>50.0,  'max_cap_tsh'=>200.00, 'tier_minimum'=>'mwanzo'],

            // Live gifts stream — 90/10 (§1.1 stream 5)
            ['metric'=>'live_gift',     'actor_role'=>'author', 'stream'=>'live_gifts', 'rate'=>0.90, 'max_cap_tsh'=>null, 'tier_minimum'=>'standard'],
            ['metric'=>'super_chat',    'actor_role'=>'author', 'stream'=>'live_gifts', 'rate'=>0.90, 'max_cap_tsh'=>null, 'tier_minimum'=>'standard'],
            ['metric'=>'live_reaction', 'actor_role'=>'author', 'stream'=>'engagement', 'rate'=>1.50, 'max_cap_tsh'=>20.00, 'tier_minimum'=>'mwanzo'],

            // Marketplace stream — 100% Mwanzo (first 90 days), 95% after (§1.1 stream 3)
            ['metric'=>'marketplace_sale', 'actor_role'=>'author', 'stream'=>'marketplace', 'rate'=>1.00, 'max_cap_tsh'=>null, 'tier_minimum'=>'mwanzo'],

            // Fan-funding stream — 95/5 (§1.1 stream 2)
            ['metric'=>'subscription', 'actor_role'=>'author', 'stream'=>'fan_funding', 'rate'=>0.95, 'max_cap_tsh'=>null, 'tier_minimum'=>'mwanzo'],
            ['metric'=>'tip',          'actor_role'=>'author', 'stream'=>'fan_funding', 'rate'=>0.95, 'max_cap_tsh'=>null, 'tier_minimum'=>'mwanzo'],
            ['metric'=>'michango',     'actor_role'=>'author', 'stream'=>'fan_funding', 'rate'=>0.95, 'max_cap_tsh'=>null, 'tier_minimum'=>'mwanzo'],

            // Brand-deal stream — 90/10 (§1.1 stream 4)
            ['metric'=>'brand_deal', 'actor_role'=>'author', 'stream'=>'brand_deal', 'rate'=>0.90, 'max_cap_tsh'=>null, 'tier_minimum'=>'verified'],
        ];

        // Wipe the v0 seed (which only had `metric` populated) and write the new matrix
        DB::table('creator_earnings_rates')->truncate();
        foreach ($rows as $r) {
            DB::table('creator_earnings_rates')->insert(array_merge($r, [
                'is_active'      => true,
                'effective_from' => $now,
                'created_at'     => $now,
                'updated_at'     => $now,
            ]));
        }
    }

    public function down(): void
    {
        Schema::table('creator_earnings_rates', function (Blueprint $table) {
            $table->dropUnique('cer_natural_key');
            $table->dropIndex(['stream', 'metric', 'is_active']);
            $table->dropColumn(['actor_role', 'stream', 'effective_from', 'effective_until', 'tier_minimum', 'max_cap_tsh']);
            $table->unique('metric');
        });
    }
};
```

- [ ] Verify with `php artisan migrate --pretend`.
- [ ] Verify with `php artisan migrate && php artisan tinker --execute="echo DB::table('creator_earnings_rates')->count();"` — expect ≥ 22 rows.
- [ ] Commit: `feat(earnings): extend creator_earnings_rates with actor_role, stream, effective windows, caps`

---

#### Task 2 — Migration: create `earning_events`

**Files:**
- Create: `database/migrations/2026_05_03_000002_create_earning_events_table.php`

This is the immutable per-event log keyed for idempotency (strategy §12.1). Every chargeable engagement gets one row.

- [ ] Create:

```php
<?php
use Illuminate\Database\Migrations\Migration;
use Illuminate\Database\Schema\Blueprint;
use Illuminate\Support\Facades\Schema;

return new class extends Migration
{
    public function up(): void
    {
        Schema::create('earning_events', function (Blueprint $table) {
            $table->id();
            $table->string('event_uid')->unique();              // deterministic dedupe key (sha256 of source)
            $table->timestampTz('occurred_at')->index();
            $table->unsignedBigInteger('post_id')->nullable()->index();
            $table->unsignedBigInteger('comment_id')->nullable();
            $table->string('source_type');                       // 'post'|'comment'|'reply'|'live_stream'|'marketplace_order'|...
            $table->unsignedBigInteger('source_id');
            $table->unsignedBigInteger('actor_user_id')->nullable();
            $table->unsignedBigInteger('target_user_id')->index();
            $table->string('actor_role');                        // 'author'|'comment_author'|'reply_author'|'host'|'parent_thread'|'sharer'|'original_creator_royalty'|'fan_buyer'
            $table->string('stream');                            // 'engagement'|'fan_funding'|'marketplace'|'brand_deal'|'live_gifts'|'affiliate'
            $table->string('metric');                            // 'view'|'reaction'|'comment'|'watch_second'|...
            $table->unsignedInteger('raw_count')->default(1);
            $table->decimal('rate_tsh', 12, 4);
            $table->jsonb('multipliers');                        // {"watch_completion":2.0,"originality":1.0,...}
            $table->decimal('gross_credit', 12, 2);
            $table->decimal('platform_take', 12, 2)->default(0);
            $table->decimal('tra_wht_held', 12, 2)->default(0);
            $table->decimal('net_to_creator', 12, 2);
            $table->boolean('is_chargeable')->default(true);
            $table->string('charge_reason')->nullable();         // when is_chargeable=false, why
            $table->string('funding_source')->nullable();        // ad_impression_id|sponsor_id|fan_user_id|treasury
            $table->string('settlement_status')->default('pending'); // pending|cleared|reversed
            $table->timestampTz('cleared_at')->nullable();
            $table->timestampTz('reversed_at')->nullable();
            $table->string('reversal_reason')->nullable();
            $table->unsignedBigInteger('journal_line_pending_id')->nullable();
            $table->unsignedBigInteger('journal_line_cleared_id')->nullable();
            $table->unsignedBigInteger('journal_line_reversal_id')->nullable();
            $table->timestampsTz();

            $table->index(['target_user_id', 'settlement_status', 'occurred_at']);
            $table->index(['post_id', 'occurred_at']);
            $table->index(['actor_user_id', 'target_user_id', 'occurred_at']); // for AbuseGuard daily caps
            $table->index(['stream', 'metric', 'occurred_at']);
        });

        // Partial index for the daily sweep (settlement_status='pending')
        \Illuminate\Support\Facades\DB::statement(
            "CREATE INDEX earning_events_pending_idx ON earning_events (occurred_at) WHERE settlement_status = 'pending'"
        );
    }

    public function down(): void
    {
        \Illuminate\Support\Facades\DB::statement('DROP INDEX IF EXISTS earning_events_pending_idx');
        Schema::dropIfExists('earning_events');
    }
};
```

- [ ] Verify with `php artisan migrate --pretend`.
- [ ] Verify post-migrate: `\d+ earning_events` in `psql` shows the partial index.
- [ ] Commit: `feat(earnings): create earning_events immutable ledger table`

---

#### Task 3 — Migration: create `creator_tiers`

**Files:**
- Create: `database/migrations/2026_05_03_000003_create_creator_tiers_table.php`

One row per creator. Auto-created by `CreatorTier::forUser()` (Task 9). Mwanzo by default with a 30-day boost window.

- [ ] Create:

```php
<?php
use Illuminate\Database\Migrations\Migration;
use Illuminate\Database\Schema\Blueprint;
use Illuminate\Support\Facades\Schema;

return new class extends Migration
{
    public function up(): void
    {
        Schema::create('creator_tiers', function (Blueprint $table) {
            $table->unsignedBigInteger('user_id')->primary();
            $table->string('tier')->default('mwanzo');                          // 'mwanzo'|'standard'|'verified'|'partner'
            $table->timestampTz('promoted_at')->useCurrent();
            $table->timestampTz('mwanzo_expires_at')->nullable();               // set to +30 days on first earning event
            $table->timestampTz('next_review_at')->nullable();
            $table->unsignedInteger('strike_count')->default(0);
            $table->boolean('monetization_paused')->default(false);             // §8 inactivity rule
            $table->timestampTz('last_active_at')->nullable();
            $table->boolean('is_id_verified')->default(false);
            $table->string('payout_preference')->default('auto_daily');        // 'auto_daily'|'weekly_batch'
            $table->timestampsTz();

            $table->index(['tier', 'next_review_at']);
            $table->index(['monetization_paused', 'last_active_at']);
        });
    }

    public function down(): void
    {
        Schema::dropIfExists('creator_tiers');
    }
};
```

- [ ] Verify with `php artisan migrate --pretend`.
- [ ] Commit: `feat(earnings): create creator_tiers table`

---

#### Task 4 — Migration: create `creators_fund_periods`

**Files:**
- Create: `database/migrations/2026_05_03_000004_create_creators_fund_periods_table.php`

One row per weekly settlement period. Strategy §12.1 — supports both Phase 1 and Phase 2 inputs.

- [ ] Create:

```php
<?php
use Illuminate\Database\Migrations\Migration;
use Illuminate\Database\Schema\Blueprint;
use Illuminate\Support\Facades\Schema;

return new class extends Migration
{
    public function up(): void
    {
        Schema::create('creators_fund_periods', function (Blueprint $table) {
            $table->id();
            $table->timestampTz('period_start');
            $table->timestampTz('period_end');
            $table->string('status')->default('open');      // 'open'|'distributing'|'settled'|'reversed'
            $table->string('phase');                        // 'phase_1'|'phase_2'

            // Phase 1 inputs
            $table->decimal('phase_1_committed_budget_tsh', 14, 2)->nullable();

            // Phase 2 inputs
            $table->decimal('ad_revenue_tsh', 14, 2)->nullable();
            $table->decimal('fan_funding_take_tsh', 14, 2)->nullable();
            $table->decimal('marketplace_take_tsh', 14, 2)->nullable();
            $table->decimal('brand_deal_take_tsh', 14, 2)->nullable();
            $table->decimal('live_gifts_take_tsh', 14, 2)->nullable();
            $table->decimal('ad_share_pct', 5, 4)->nullable();          // 0.70 in Phase 2
            $table->decimal('pass_through_share_pct', 5, 4)->nullable(); // 0.10 in Phase 2
            $table->decimal('treasury_topup_tsh', 14, 2)->nullable();

            // Computed
            $table->decimal('floor_tsh', 14, 2);
            $table->decimal('fund_size_tsh', 14, 2);
            $table->decimal('reserve_topup_tsh', 14, 2)->default(0);

            // Distribution
            $table->decimal('total_points', 20, 4)->nullable();
            $table->decimal('fund_per_point', 20, 8)->nullable();
            $table->unsignedInteger('eligible_creator_count')->nullable();
            $table->timestampTz('settled_at')->nullable();
            $table->unsignedBigInteger('settlement_journal_batch_id')->nullable();
            $table->timestampsTz();

            $table->unique(['period_start', 'period_end']);
            $table->index(['status', 'period_end']);
        });
    }

    public function down(): void
    {
        Schema::dropIfExists('creators_fund_periods');
    }
};
```

- [ ] Verify with `php artisan migrate --pretend`.
- [ ] Commit: `feat(earnings): create creators_fund_periods table`

---

#### Task 5 — Migration: create `creators_fund_points`

**Files:**
- Create: `database/migrations/2026_05_03_000005_create_creators_fund_points_table.php`

Per-creator points accumulator within an active period. `EarningsEngine::accruePoints` upserts into this table.

- [ ] Create:

```php
<?php
use Illuminate\Database\Migrations\Migration;
use Illuminate\Database\Schema\Blueprint;
use Illuminate\Support\Facades\Schema;

return new class extends Migration
{
    public function up(): void
    {
        Schema::create('creators_fund_points', function (Blueprint $table) {
            $table->id();
            $table->unsignedBigInteger('period_id');
            $table->unsignedBigInteger('user_id');
            $table->decimal('points', 20, 4)->default(0);
            $table->unsignedInteger('events_count')->default(0);
            $table->timestampTz('last_event_at')->nullable();
            $table->decimal('payout_tsh', 14, 2)->nullable();   // null until period settles
            $table->timestampsTz();

            $table->foreign('period_id')->references('id')->on('creators_fund_periods')->cascadeOnDelete();
            $table->unique(['period_id', 'user_id']);
            $table->index(['period_id', 'points']);
        });
    }

    public function down(): void
    {
        Schema::dropIfExists('creators_fund_points');
    }
};
```

- [ ] Verify with `php artisan migrate --pretend`.
- [ ] Commit: `feat(earnings): create creators_fund_points accumulator table`

---

#### Task 6 — Migration: create `earnings_reserve_ledger`

**Files:**
- Create: `database/migrations/2026_05_03_000006_create_earnings_reserve_ledger_table.php`

Tracks the 5%-of-platform-revenue reserve fund (§10.2). Drawn down to (a) top up Phase 2 fund to floor, (b) absorb 30-day reversals, (c) subsidize Mwanzo Boost.

- [ ] Create:

```php
<?php
use Illuminate\Database\Migrations\Migration;
use Illuminate\Database\Schema\Blueprint;
use Illuminate\Support\Facades\Schema;

return new class extends Migration
{
    public function up(): void
    {
        Schema::create('earnings_reserve_ledger', function (Blueprint $table) {
            $table->id();
            $table->timestampTz('occurred_at')->useCurrent();
            $table->decimal('delta_tsh', 14, 2);              // + accrual / – drawdown
            $table->decimal('balance_after_tsh', 14, 2);      // running balance for fast latest-balance queries
            $table->string('reason');                          // 'accrual_5pct'|'phase2_floor_topup'|'reversal'|'mwanzo_subsidy'
            $table->unsignedBigInteger('journal_line_id')->nullable();
            $table->timestampsTz();

            $table->index('occurred_at');
        });
    }

    public function down(): void
    {
        Schema::dropIfExists('earnings_reserve_ledger');
    }
};
```

- [ ] Verify with `php artisan migrate --pretend`.
- [ ] Commit: `feat(earnings): create earnings_reserve_ledger table`

---

#### Task 7 — Migration + seeder: COA accounts

**Files:**
- Create: `database/migrations/2026_05_03_000007_create_earnings_coa_accounts.php`
- Create: `database/seeders/CreatorsFundCoaSeeder.php`

The accounting plan in strategy §12.2 adds 14 new accounts. Idempotent insert — runs as part of migration so deploy is single-shot, plus exposed as a seeder for re-runs.

- [ ] Create migration that calls the seeder:

```php
<?php
use Illuminate\Database\Migrations\Migration;
use Illuminate\Support\Facades\Artisan;

return new class extends Migration
{
    public function up(): void
    {
        Artisan::call('db:seed', ['--class' => 'CreatorsFundCoaSeeder', '--force' => true]);
    }

    public function down(): void
    {
        // Removing COA rows in down() risks data loss — leave them in place.
    }
};
```

- [ ] Create `database/seeders/CreatorsFundCoaSeeder.php`:

```php
<?php
namespace Database\Seeders;

use Illuminate\Database\Seeder;
use Illuminate\Support\Facades\DB;

class CreatorsFundCoaSeeder extends Seeder
{
    public function run(): void
    {
        // Strategy §12.2 — full account map.
        $accounts = [
            ['code'=>'2105', 'name'=>'Creators Fund — Pending Distribution',     'type'=>'liability'],
            ['code'=>'2110', 'name'=>'Pending Creator Earnings — Engagement',    'type'=>'liability'],
            ['code'=>'2111', 'name'=>'Pending Creator Earnings — Fan-Funding',   'type'=>'liability'],
            ['code'=>'2112', 'name'=>'Pending Creator Earnings — Marketplace',   'type'=>'liability'],
            ['code'=>'2113', 'name'=>'Pending Creator Earnings — Brand-Deal',    'type'=>'liability'],
            ['code'=>'2114', 'name'=>'Pending Creator Earnings — Live-Gifts',    'type'=>'liability'],
            ['code'=>'2120', 'name'=>'Cleared Creator Earnings (Payable)',       'type'=>'liability'],
            ['code'=>'2130', 'name'=>'Creator Earnings Reserve Fund',            'type'=>'liability'],
            ['code'=>'2140', 'name'=>'TRA WHT Payable',                          'type'=>'liability'],
            ['code'=>'4115', 'name'=>'Ad Revenue (Phase 2)',                     'type'=>'revenue'],
            ['code'=>'4120', 'name'=>'Platform Revenue — Fan-Funding Take',      'type'=>'revenue'],
            ['code'=>'4130', 'name'=>'Platform Revenue — Marketplace Take',      'type'=>'revenue'],
            ['code'=>'4140', 'name'=>'Platform Revenue — Brand-Deal Take',       'type'=>'revenue'],
            ['code'=>'4150', 'name'=>'Platform Revenue — Live-Gifts Take',       'type'=>'revenue'],
            ['code'=>'5110', 'name'=>'Creators Fund Outflow — Phase 1 CAC',      'type'=>'expense'],
            ['code'=>'5111', 'name'=>'Creators Fund Outflow — Phase 2 Rev-Share','type'=>'expense'],
        ];

        $now = now();
        foreach ($accounts as $a) {
            DB::table('chart_of_accounts')->updateOrInsert(
                ['code' => $a['code']],
                array_merge($a, [
                    'is_active'  => true,
                    'created_at' => $now,
                    'updated_at' => $now,
                ])
            );
        }
    }
}
```

- [ ] If `chart_of_accounts` table does not yet exist on the deploy target, this seeder will fail loudly — that is intentional. The COA module ships separately; if missing on a given environment, the deploy must be staged behind that one.
- [ ] Verify post-migrate: `SELECT code, name FROM chart_of_accounts WHERE code IN ('2105','5110','5111') ORDER BY code;`
- [ ] Commit: `feat(earnings): seed Creators Fund COA accounts`

---

#### Task 8 — Eloquent model: `EarningEvent`

**Files:**
- Create: `app/Models/EarningEvent.php`

- [ ] Create:

```php
<?php
namespace App\Models;

use Illuminate\Database\Eloquent\Model;

class EarningEvent extends Model
{
    protected $table = 'earning_events';

    protected $fillable = [
        'event_uid','occurred_at','post_id','comment_id','source_type','source_id',
        'actor_user_id','target_user_id','actor_role','stream','metric','raw_count',
        'rate_tsh','multipliers','gross_credit','platform_take','tra_wht_held',
        'net_to_creator','is_chargeable','charge_reason','funding_source',
        'settlement_status','cleared_at','reversed_at','reversal_reason',
        'journal_line_pending_id','journal_line_cleared_id','journal_line_reversal_id',
    ];

    protected $casts = [
        'occurred_at'    => 'datetime',
        'cleared_at'     => 'datetime',
        'reversed_at'    => 'datetime',
        'multipliers'    => 'array',
        'rate_tsh'       => 'float',
        'gross_credit'   => 'float',
        'platform_take'  => 'float',
        'tra_wht_held'   => 'float',
        'net_to_creator' => 'float',
        'is_chargeable'  => 'boolean',
    ];

    public function scopePending($q)  { return $q->where('settlement_status', 'pending'); }
    public function scopeCleared($q)  { return $q->where('settlement_status', 'cleared'); }
    public function scopeChargeable($q) { return $q->where('is_chargeable', true); }
    public function scopeForCreator($q, int $userId) { return $q->where('target_user_id', $userId); }
    public function scopeForPost($q, int $postId)    { return $q->where('post_id', $postId); }
}
```

- [ ] Verify with `php artisan tinker --execute="echo App\\Models\\EarningEvent::class;"`.
- [ ] Commit: `feat(earnings): add EarningEvent model`

---

#### Task 9 — Eloquent model: `CreatorTier`

**Files:**
- Create: `app/Models/CreatorTier.php`

Includes the `forUser()` factory used everywhere the tier is needed (auto-creates the row in Mwanzo state on first call), and the `isAtLeast()` helper used by the rate registry and Discovery-Mode endpoint.

- [ ] Create:

```php
<?php
namespace App\Models;

use Illuminate\Database\Eloquent\Model;

class CreatorTier extends Model
{
    protected $table = 'creator_tiers';
    protected $primaryKey = 'user_id';
    public $incrementing = false;
    protected $keyType = 'int';

    protected $fillable = [
        'user_id','tier','promoted_at','mwanzo_expires_at','next_review_at',
        'strike_count','monetization_paused','last_active_at','is_id_verified',
        'payout_preference',
    ];

    protected $casts = [
        'promoted_at'         => 'datetime',
        'mwanzo_expires_at'   => 'datetime',
        'next_review_at'      => 'datetime',
        'last_active_at'      => 'datetime',
        'monetization_paused' => 'boolean',
        'is_id_verified'      => 'boolean',
        'strike_count'        => 'int',
    ];

    public const TIERS = ['mwanzo', 'standard', 'verified', 'partner'];
    public const TIER_RANK = ['mwanzo' => 0, 'standard' => 1, 'verified' => 2, 'partner' => 3];

    /**
     * Find-or-create the tier row for a user. New rows default to mwanzo with a 30-day boost.
     */
    public static function forUser(int $userId): self
    {
        return self::firstOrCreate(
            ['user_id' => $userId],
            [
                'tier'              => 'mwanzo',
                'promoted_at'       => now(),
                'mwanzo_expires_at' => now()->addDays(30),
                'next_review_at'    => now()->addDays(7),
                'last_active_at'    => now(),
            ]
        );
    }

    public function isAtLeast(string $tier): bool
    {
        return (self::TIER_RANK[$this->tier] ?? -1) >= (self::TIER_RANK[$tier] ?? 99);
    }

    public function isMwanzoActive(): bool
    {
        return $this->mwanzo_expires_at && $this->mwanzo_expires_at->isFuture();
    }
}
```

- [ ] Commit: `feat(earnings): add CreatorTier model`

---

#### Task 10 — Eloquent models: `CreatorsFundPeriod` + `CreatorsFundPoint`

**Files:**
- Create: `app/Models/CreatorsFundPeriod.php`
- Create: `app/Models/CreatorsFundPoint.php`

The `currentOpen()` helper is used by `EarningsEngine::accruePoints` and the dashboard endpoint to find the active fund period. `openNextPeriod()` is used by the settlement job.

- [ ] Create `CreatorsFundPeriod`:

```php
<?php
namespace App\Models;

use Illuminate\Database\Eloquent\Model;

class CreatorsFundPeriod extends Model
{
    protected $table = 'creators_fund_periods';
    protected $guarded = [];

    protected $casts = [
        'period_start'                  => 'datetime',
        'period_end'                    => 'datetime',
        'settled_at'                    => 'datetime',
        'phase_1_committed_budget_tsh'  => 'float',
        'ad_revenue_tsh'                => 'float',
        'fan_funding_take_tsh'          => 'float',
        'marketplace_take_tsh'          => 'float',
        'brand_deal_take_tsh'           => 'float',
        'live_gifts_take_tsh'           => 'float',
        'ad_share_pct'                  => 'float',
        'pass_through_share_pct'        => 'float',
        'treasury_topup_tsh'            => 'float',
        'floor_tsh'                     => 'float',
        'fund_size_tsh'                 => 'float',
        'reserve_topup_tsh'             => 'float',
        'total_points'                  => 'float',
        'fund_per_point'                => 'float',
    ];

    public static function currentOpen(): ?self
    {
        return self::where('status', 'open')
            ->where('period_start', '<=', now())
            ->where('period_end', '>', now())
            ->first();
    }

    /**
     * Open the next weekly period anchored to Monday 00:00 UTC+3.
     * Strategy §1.2 fund replenishment cycle.
     */
    public static function openNextPeriod(string $phase = 'phase_1'): self
    {
        $start = now()->setTimezone('Africa/Nairobi')->startOfWeek()->setTimezone('UTC');
        $end   = $start->copy()->addWeek();
        return self::create([
            'period_start'                 => $start,
            'period_end'                   => $end,
            'status'                       => 'open',
            'phase'                        => $phase,
            'phase_1_committed_budget_tsh' => $phase === 'phase_1' ? config('earnings.phase_1_weekly_fund_tsh', 50_000_000) : null,
            'floor_tsh'                    => config('earnings.phase_1_weekly_fund_tsh', 50_000_000),
            'fund_size_tsh'                => $phase === 'phase_1' ? config('earnings.phase_1_weekly_fund_tsh', 50_000_000) : 0,
        ]);
    }

    public function points()
    {
        return $this->hasMany(CreatorsFundPoint::class, 'period_id');
    }
}
```

- [ ] Create `CreatorsFundPoint`:

```php
<?php
namespace App\Models;

use Illuminate\Database\Eloquent\Model;

class CreatorsFundPoint extends Model
{
    protected $table = 'creators_fund_points';
    protected $guarded = [];

    protected $casts = [
        'points'        => 'float',
        'events_count'  => 'int',
        'last_event_at' => 'datetime',
        'payout_tsh'    => 'float',
    ];

    public function period()
    {
        return $this->belongsTo(CreatorsFundPeriod::class, 'period_id');
    }
}
```

- [ ] Commit: `feat(earnings): add CreatorsFundPeriod + CreatorsFundPoint models`

---

### Backend rate registry + multiplier engine (Tasks 11–15)

---

#### Task 11 — Service: `CreatorEarningsRateRegistry`

**Files:**
- Create: `app/Services/CreatorEarningsRateRegistry.php`

Single source of truth for "what's the current rate for (metric, actor_role, stream, tier)?". Cached for 5 minutes — rate changes are a 30-day-notice event, so a 5-minute cache is fine.

- [ ] Create:

```php
<?php
namespace App\Services;

use Illuminate\Support\Facades\Cache;
use Illuminate\Support\Facades\DB;

class CreatorEarningsRateRegistry
{
    public const CACHE_KEY = 'earnings:rates:active:v1';
    public const CACHE_TTL = 300; // 5 min

    /**
     * Look up the active rate for a (metric, actor_role, stream) tuple.
     * Returns null if no row matches or if the creator's tier is below tier_minimum.
     *
     * @return array{rate: float, max_cap_tsh: ?float, tier_minimum: ?string}|null
     */
    public static function rateFor(string $metric, string $actorRole, string $stream, string $creatorTier): ?array
    {
        $rates = self::activeRates();
        $key = "{$metric}|{$actorRole}|{$stream}";
        $row = $rates[$key] ?? null;
        if (!$row) return null;

        // Tier gate per strategy §4.
        $tierMin = $row['tier_minimum'] ?? 'mwanzo';
        $rank = ['mwanzo' => 0, 'standard' => 1, 'verified' => 2, 'partner' => 3];
        if (($rank[$creatorTier] ?? -1) < ($rank[$tierMin] ?? 0)) {
            return null;
        }

        return [
            'rate'         => (float) $row['rate'],
            'max_cap_tsh'  => $row['max_cap_tsh'] !== null ? (float) $row['max_cap_tsh'] : null,
            'tier_minimum' => $row['tier_minimum'],
        ];
    }

    /** @return array<string, array{rate: float|string, max_cap_tsh: ?float, tier_minimum: ?string}> */
    public static function activeRates(): array
    {
        return Cache::remember(self::CACHE_KEY, self::CACHE_TTL, function () {
            $rows = DB::table('creator_earnings_rates')
                ->where('is_active', true)
                ->where('effective_from', '<=', now())
                ->where(fn ($q) => $q->whereNull('effective_until')->orWhere('effective_until', '>', now()))
                ->get();
            $out = [];
            foreach ($rows as $r) {
                $out["{$r->metric}|{$r->actor_role}|{$r->stream}"] = (array) $r;
            }
            return $out;
        });
    }

    public static function flush(): void { Cache::forget(self::CACHE_KEY); }
}
```

- [ ] Verify: `php artisan tinker --execute="var_dump(App\\Services\\CreatorEarningsRateRegistry::rateFor('view','author','engagement','mwanzo'));"` — expect `['rate' => 0.5, 'max_cap_tsh' => 5.0, 'tier_minimum' => 'mwanzo']`.
- [ ] Commit: `feat(earnings): add CreatorEarningsRateRegistry`

---

#### Task 12 — Service: `MultiplierEngine`

**Files:**
- Create: `app/Services/MultiplierEngine.php`

Computes the 6 multipliers from strategy §3 + §4. Pure functions — easy to unit-test (Task 79).

- [ ] Create:

```php
<?php
namespace App\Services;

use App\Models\CreatorTier;
use Illuminate\Support\Facades\DB;

class MultiplierEngine
{
    /**
     * Compute all applicable multipliers for an event.
     *
     * @param array $context {
     *   target_user_id: int,
     *   metric: string,
     *   stream: string,
     *   post_id: ?int,
     *   watch_completion_pct: ?float,   // 0.0–1.0; null for non-video metrics
     *   originality_flag: ?string,      // 'original'|'derivative_substantial'|'derivative_minimal'|'reused'
     *   discovery_mode_active: bool,
     * }
     * @return array{watch_completion: ?float, originality: ?float, mwanzo_boost: ?float, streak: ?float, discovery_mode: ?float, tier_boost: ?float}
     */
    public static function compute(array $context): array
    {
        $tier = CreatorTier::forUser($context['target_user_id']);
        return [
            'watch_completion' => self::watchCompletion($context['watch_completion_pct'] ?? null, $context['metric']),
            'originality'      => self::originality($context['originality_flag'] ?? 'original'),
            'mwanzo_boost'     => self::mwanzoBoost($tier),
            'streak'           => self::streak($context['target_user_id']),
            'discovery_mode'   => self::discoveryMode($context['discovery_mode_active'] ?? false),
            'tier_boost'       => self::tierBoost($tier->tier),
        ];
    }

    public static function combined(array $multipliers): float
    {
        return array_reduce(
            $multipliers,
            fn ($acc, $m) => $acc * ($m === null ? 1.0 : (float) $m),
            1.0
        );
    }

    /** §3.1 — applies only to video metrics (view + watch_second). */
    public static function watchCompletion(?float $pct, string $metric): ?float
    {
        if ($pct === null || !in_array($metric, ['view', 'watch_second'], true)) return null;
        if ($pct < 0.25) return 0.5;
        if ($pct < 0.50) return 1.0;
        if ($pct < 0.70) return 1.5;
        if ($pct < 0.90) return 2.0;
        return 2.5;
    }

    /** §3.3 — originality. */
    public static function originality(string $flag): float
    {
        return match ($flag) {
            'original'                => 1.0,
            'derivative_substantial'  => 0.7,
            'derivative_minimal'      => 0.4,
            'reused'                  => 0.0,
            default                   => 1.0,
        };
    }

    /** §3.2 — Mwanzo Boost: 2× during first 30 days. */
    public static function mwanzoBoost(CreatorTier $tier): ?float
    {
        return $tier->isMwanzoActive() ? 2.0 : null;
    }

    /** §3.4 — +10% if posted ≥ 5 of last 7 days. */
    public static function streak(int $userId): ?float
    {
        $days = DB::table('posts')
            ->where('user_id', $userId)
            ->where('created_at', '>=', now()->subDays(7))
            ->selectRaw('COUNT(DISTINCT DATE(created_at)) as d')
            ->value('d');
        return ((int) $days >= 5) ? 1.10 : null;
    }

    /** §3.5 — Discovery Mode. */
    public static function discoveryMode(bool $active): ?float
    {
        return $active ? 0.70 : null;
    }

    /** §4 — Partner gets +5pts on engagement pool only; others 1.00. */
    public static function tierBoost(string $tier): ?float
    {
        return $tier === 'partner' ? 1.05 : null;
    }
}
```

- [ ] Verify: `php artisan tinker --execute="var_dump(App\\Services\\MultiplierEngine::watchCompletion(0.95, 'view'));"` — expect `2.5`.
- [ ] Commit: `feat(earnings): add MultiplierEngine`

---

#### Task 13 — Watch-completion multiplier table in config

**Files:**
- Create: `config/earnings_multipliers.php`

Pure config so it's reviewable without code changes. Read-only — `MultiplierEngine` already hardcodes the same values for hot-path performance; this config exists for observability and v3 A/B testing.

- [ ] Create:

```php
<?php
return [
    // §3.1 — applied to view + watch_second metrics only.
    'watch_completion' => [
        ['min_pct' => 0.00, 'max_pct' => 0.25, 'mult' => 0.5],
        ['min_pct' => 0.25, 'max_pct' => 0.50, 'mult' => 1.0],
        ['min_pct' => 0.50, 'max_pct' => 0.70, 'mult' => 1.5],
        ['min_pct' => 0.70, 'max_pct' => 0.90, 'mult' => 2.0],
        ['min_pct' => 0.90, 'max_pct' => 1.01, 'mult' => 2.5],
    ],
    // §3.3 — originality.
    'originality' => [
        'original'               => 1.0,
        'derivative_substantial' => 0.7,
        'derivative_minimal'     => 0.4,
        'reused'                 => 0.0,
    ],
    // §3.2 — Mwanzo boost.
    'mwanzo_boost'   => 2.0,
    'mwanzo_window_days' => 30,
    // §3.4 — streak.
    'streak_bonus'   => 1.10,
    'streak_min_days_in_7' => 5,
    // §3.5 — discovery.
    'discovery_mode' => 0.70,
    'discovery_window_days' => 30,
    // §4 — tier boost.
    'tier_boost'     => ['mwanzo' => 1.0, 'standard' => 1.0, 'verified' => 1.0, 'partner' => 1.05],
];
```

- [ ] Commit: `feat(earnings): add earnings_multipliers config`

---

#### Task 14 — Originality detector v1 (heuristic)

**Files:**
- Create: `app/Services/OriginalityDetector.php`

V1 is heuristic — flags reused / template / AI-voice content. v3 brings perceptual-hash + audio-fingerprint detection (deferred). The detector returns a flag string consumed by `MultiplierEngine::originality`.

- [ ] Create:

```php
<?php
namespace App\Services;

use Illuminate\Support\Facades\DB;

class OriginalityDetector
{
    /**
     * Classify the post per strategy §3.3.
     * @return string one of 'original'|'derivative_substantial'|'derivative_minimal'|'reused'
     */
    public static function classify(int $postId): string
    {
        $p = DB::table('posts')->where('id', $postId)->first();
        if (!$p) return 'original';

        // Derivative branches first.
        if (!empty($p->reply_to_post_id) || !empty($p->stitch_from_post_id) || !empty($p->quote_from_post_id)) {
            $hasNewBytes = !empty($p->content) && strlen((string) $p->content) >= 50;
            return $hasNewBytes ? 'derivative_substantial' : 'derivative_minimal';
        }

        // Heuristic: same user posting >= 8 posts/day with identical thumbnails or no audio track is "reused".
        $recentSameThumb = DB::table('post_media')
            ->join('posts', 'posts.id', '=', 'post_media.post_id')
            ->where('posts.user_id', $p->user_id)
            ->where('post_media.thumbnail_url', '!=', '')
            ->whereNotNull('post_media.thumbnail_url')
            ->where('posts.created_at', '>=', now()->subDay())
            ->selectRaw('post_media.thumbnail_url, COUNT(*) as c')
            ->groupBy('post_media.thumbnail_url')
            ->having('c', '>=', 4)
            ->exists();
        if ($recentSameThumb) return 'reused';

        return 'original';
    }
}
```

- [ ] Verify: `php artisan tinker --execute="var_dump(App\\Services\\OriginalityDetector::classify(1));"` (returns one of the four strings).
- [ ] Commit: `feat(earnings): add OriginalityDetector v1 heuristic`

---

#### Task 15 — Streak tracker (already in MultiplierEngine; verify perf)

**Files:**
- (no new file — `MultiplierEngine::streak` already implements it)

`MultiplierEngine::streak` runs a `COUNT(DISTINCT DATE)` per event. At v1 throughput (≤ 10k engagement events/min) this is a 200-row scan on the index `posts(user_id, created_at)` and is fine. v3 will move this to a precomputed column on `creator_tiers` refreshed nightly (see partial plan v3 task: "Performance: has_active_streak cache").

- [ ] Verify the index `posts (user_id, created_at)` exists. If absent, add migration:

```php
Schema::table('posts', function (Blueprint $table) {
    $table->index(['user_id', 'created_at'], 'posts_user_id_created_at_idx');
});
```

- [ ] Verify: `EXPLAIN ANALYZE SELECT COUNT(DISTINCT DATE(created_at)) FROM posts WHERE user_id=1 AND created_at >= now() - interval '7 days';` — must use the index.
- [ ] Commit (only if migration added): `perf(earnings): add posts(user_id, created_at) index for streak tracker`

---

### Backend EarningsEngine service (Tasks 16–22)

---

#### Task 16 — Service skeleton: `EarningsEngine`

**Files:**
- Create: `app/Services/EarningsEngine.php`

This is the central entrypoint every event hook calls. The skeleton wires the steps; subsequent tasks fill in each method.

- [ ] Create:

```php
<?php
namespace App\Services;

use App\Models\CreatorsFundPeriod;
use App\Models\CreatorTier;
use App\Models\EarningEvent;
use App\Services\Earnings\EarningEventDto;
use Illuminate\Support\Facades\DB;
use Illuminate\Support\Facades\Log;

class EarningsEngine
{
    /**
     * Single entrypoint called by every engagement endpoint.
     * Idempotent: same event_uid → returns existing row, no duplicate insert.
     *
     * Pipeline:
     *   1. attribution: figure out (target_user_id, actor_role) tuples for this event
     *   2. for each tuple:
     *        a. abuse-guard: chargeable yes/no + charge_reason
     *        b. lookup rate
     *        c. compute multipliers
     *        d. compute gross / platform_take / wht / net
     *        e. insert earning_events row (idempotent on event_uid)
     *        f. write journal_lines pending entry
     *        g. accrue points to active fund period
     */
    public static function recordEvent(EarningEventDto $dto): array
    {
        $rows = [];
        foreach (self::applyAttribution($dto) as $attr) {
            $rows[] = self::recordOneCredit($dto, $attr);
        }
        return $rows;
    }

    /** Build deterministic event_uid for idempotency. */
    public static function makeEventUid(EarningEventDto $dto, array $attribution): string
    {
        return hash('sha256', implode('|', [
            $dto->sourceType,
            $dto->sourceId,
            $dto->actorUserId ?? 'anonymous',
            $attribution['target_user_id'],
            $attribution['actor_role'],
            $dto->metric,
        ]));
    }

    // applyAttribution / computeChargeable / accruePoints / recordOneCredit defined in subsequent tasks.
    public static function applyAttribution(EarningEventDto $dto): array { /* Task 18 */ return []; }
    public static function computeChargeable(EarningEventDto $dto, array $attribution): array { /* Task 19 */ return ['is_chargeable' => true, 'charge_reason' => null]; }
    public static function accruePoints(EarningEvent $event): void { /* Task 20 */ }
    public static function recordOneCredit(EarningEventDto $dto, array $attribution): ?EarningEvent { /* Task 17 */ return null; }
}
```

- [ ] Commit: `feat(earnings): add EarningsEngine service skeleton`

---

#### Task 17 — Method: `recordEvent`/`recordOneCredit` (idempotent insert)

**Files:**
- Modify: `app/Services/EarningsEngine.php`

The full `recordOneCredit` implementation. Idempotent on `event_uid`. Writes a `journal_lines` pending entry to one of `2110-2114` based on stream.

- [ ] Replace the stub `recordOneCredit` with:

```php
public static function recordOneCredit(EarningEventDto $dto, array $attribution): ?EarningEvent
{
    $eventUid = self::makeEventUid($dto, $attribution);

    // Idempotency: short-circuit if we already recorded this credit.
    $existing = EarningEvent::where('event_uid', $eventUid)->first();
    if ($existing) return $existing;

    $tier = CreatorTier::forUser($attribution['target_user_id']);
    if ($tier->monetization_paused) {
        return self::insertNonChargeable($dto, $attribution, $eventUid, 'creator_inactive_paused');
    }

    $rate = CreatorEarningsRateRegistry::rateFor(
        $dto->metric,
        $attribution['actor_role'],
        $dto->stream,
        $tier->tier
    );
    if (!$rate) {
        return self::insertNonChargeable($dto, $attribution, $eventUid, 'no_rate_for_tier_or_role');
    }

    $check = self::computeChargeable($dto, $attribution);
    if (!$check['is_chargeable']) {
        return self::insertNonChargeable($dto, $attribution, $eventUid, $check['charge_reason']);
    }

    $multipliers = MultiplierEngine::compute([
        'target_user_id'        => $attribution['target_user_id'],
        'metric'                => $dto->metric,
        'stream'                => $dto->stream,
        'post_id'               => $dto->postId,
        'watch_completion_pct'  => $dto->watchCompletionPct,
        'originality_flag'      => $dto->originalityFlag,
        'discovery_mode_active' => $dto->discoveryModeActive,
    ]);
    $combinedMult = MultiplierEngine::combined($multipliers);

    $rawCount = max(1, $dto->rawCount);
    $gross = round($rate['rate'] * $rawCount * $combinedMult, 2);
    if ($rate['max_cap_tsh'] !== null) {
        $gross = min($gross, (float) $rate['max_cap_tsh'] * $rawCount);
    }

    // Per-stream platform take. WHT only at clear-time, so 0 on insert (sweep job applies it).
    $platformTake = self::platformTakeFor($dto->stream, $gross);
    $netToCreator = max(0.0, round($gross - $platformTake, 2));

    return DB::transaction(function () use ($dto, $attribution, $eventUid, $rate, $multipliers, $rawCount, $gross, $platformTake, $netToCreator) {
        $event = EarningEvent::create([
            'event_uid'         => $eventUid,
            'occurred_at'       => $dto->occurredAt ?? now(),
            'post_id'           => $dto->postId,
            'comment_id'        => $dto->commentId,
            'source_type'       => $dto->sourceType,
            'source_id'         => $dto->sourceId,
            'actor_user_id'     => $dto->actorUserId,
            'target_user_id'    => $attribution['target_user_id'],
            'actor_role'        => $attribution['actor_role'],
            'stream'            => $dto->stream,
            'metric'            => $dto->metric,
            'raw_count'         => $rawCount,
            'rate_tsh'          => $rate['rate'],
            'multipliers'       => $multipliers,
            'gross_credit'      => $gross,
            'platform_take'     => $platformTake,
            'tra_wht_held'      => 0,
            'net_to_creator'    => $netToCreator,
            'is_chargeable'     => true,
            'funding_source'    => $dto->fundingSource ?? 'treasury',
            'settlement_status' => 'pending',
        ]);

        // §5.1 — Pending journal entry. For engagement (Phase 1) the COA debit is
        // 5110 (Phase 1 CAC) credited to 2110 (Pending Engagement). For pass-through
        // streams the credit is to 2111-2114.
        $accountCredit = match ($dto->stream) {
            'engagement'   => '2110',
            'fan_funding'  => '2111',
            'marketplace'  => '2112',
            'brand_deal'   => '2113',
            'live_gifts'   => '2114',
            default        => '2110',
        };
        // Real money flows for pass-through streams happen in their own controllers
        // (e.g. WalletController for tips). Here we only record the creator-credit side.
        // For engagement: the period-settlement job is what posts the Dr. 5110 / Cr. 2105
        // batch entry; the per-event accrual is informational (estimate) until then.
        $journalId = DB::table('journal_lines')->insertGetId([
            'account_code'   => $accountCredit,
            'debit'          => 0,
            'credit'         => $netToCreator,
            'description'    => "Earning credit (estimate) — event {$event->id}",
            'reference_type' => 'earning_event',
            'reference_id'   => $event->id,
            'created_at'     => now(),
            'updated_at'     => now(),
        ]);
        $event->update(['journal_line_pending_id' => $journalId]);

        self::accruePoints($event);

        return $event;
    });
}

private static function insertNonChargeable(EarningEventDto $dto, array $attribution, string $uid, string $reason): EarningEvent
{
    return EarningEvent::create([
        'event_uid'      => $uid,
        'occurred_at'    => $dto->occurredAt ?? now(),
        'post_id'        => $dto->postId,
        'comment_id'     => $dto->commentId,
        'source_type'    => $dto->sourceType,
        'source_id'      => $dto->sourceId,
        'actor_user_id'  => $dto->actorUserId,
        'target_user_id' => $attribution['target_user_id'],
        'actor_role'     => $attribution['actor_role'],
        'stream'         => $dto->stream,
        'metric'         => $dto->metric,
        'raw_count'      => max(1, $dto->rawCount),
        'rate_tsh'       => 0,
        'multipliers'    => [],
        'gross_credit'   => 0,
        'platform_take'  => 0,
        'tra_wht_held'   => 0,
        'net_to_creator' => 0,
        'is_chargeable'  => false,
        'charge_reason'  => $reason,
        'settlement_status' => 'pending',
    ]);
}

private static function platformTakeFor(string $stream, float $gross): float
{
    // §1.1 stream cuts — for engagement the "take" is captured at fund-distribution time, not per event.
    return match ($stream) {
        'engagement'  => 0,         // fund is distributed in full; no per-event take
        'fan_funding' => round($gross / 0.95 * 0.05, 2),  // 5% on gross-up
        'marketplace' => 0,         // Mwanzo: 0% first 90 days. After: 5% — handled by ShopOrderController, not here.
        'brand_deal'  => round($gross / 0.90 * 0.10, 2),
        'live_gifts'  => round($gross / 0.90 * 0.10, 2),
        'affiliate'   => 0,
        default       => 0,
    };
}
```

- [ ] Verify with a tinker invocation:

```bash
php artisan tinker --execute="
\$dto = new App\\Services\\Earnings\\EarningEventDto();
\$dto->stream='engagement'; \$dto->metric='view'; \$dto->sourceType='post'; \$dto->sourceId=1;
\$dto->postId=1; \$dto->actorUserId=2; \$dto->rawCount=1;
var_dump(App\\Services\\EarningsEngine::recordEvent(\$dto));
"
```

- [ ] Commit: `feat(earnings): implement EarningsEngine::recordOneCredit`

---

#### Task 18 — Method: `applyAttribution` (B+C rules)

**Files:**
- Modify: `app/Services/EarningsEngine.php`

Implements the strategy §2.1 + §2.2 attribution table. Returns one or more `(target_user_id, actor_role)` tuples — one row per earner.

- [ ] Replace the stub:

```php
public static function applyAttribution(EarningEventDto $dto): array
{
    $tuples = [];
    $authorId = $dto->postAuthorId; // resolved upstream by the controller (always required when post_id present)

    // 1. Primary author always gets credit (B-rule).
    if ($authorId) {
        $tuples[] = ['target_user_id' => $authorId, 'actor_role' => 'author'];
    }

    // 2. Sharer secondary credit (B+C). If this view/reaction came in via a share
    //    chain, credit the sharer at a reduced rate.
    if ($dto->sharerUserId && in_array($dto->metric, ['view','reaction','share','save','comment'], true)) {
        $tuples[] = ['target_user_id' => $dto->sharerUserId, 'actor_role' => 'sharer'];
    }

    // 3. Comment-author / reply-author credits.
    if ($dto->metric === 'reply' && $dto->commentAuthorId) {
        $tuples[] = ['target_user_id' => $dto->commentAuthorId, 'actor_role' => 'comment_author'];
    }
    if ($dto->metric === 'comment_reaction') {
        if ($dto->commentAuthorId) {
            $tuples[] = ['target_user_id' => $dto->commentAuthorId, 'actor_role' => 'comment_author'];
        }
        if ($authorId && $authorId !== $dto->commentAuthorId) {
            $tuples[] = ['target_user_id' => $authorId, 'actor_role' => 'host'];
        }
    }

    // 4. Derivative royalty — the original creator earns when a stitch/quote/reply post is created.
    if ($dto->metric === 'derivative_royalty' && $dto->originalCreatorId) {
        $tuples = [['target_user_id' => $dto->originalCreatorId, 'actor_role' => 'original_creator_royalty']];
    }

    // 5. Self-action exclusion — strip any tuple where target == actor.
    if ($dto->actorUserId) {
        $tuples = array_values(array_filter($tuples, fn ($t) => $t['target_user_id'] !== $dto->actorUserId));
    }

    // 6. Dedupe.
    $seen = [];
    return array_values(array_filter($tuples, function ($t) use (&$seen) {
        $k = $t['target_user_id'] . '|' . $t['actor_role'];
        if (isset($seen[$k])) return false;
        $seen[$k] = true;
        return true;
    }));
}
```

- [ ] Commit: `feat(earnings): implement EarningsEngine::applyAttribution (B+C rules)`

---

#### Task 19 — Method: `computeChargeable` (anti-abuse v1)

**Files:**
- Create: `app/Services/AbuseGuard.php`
- Modify: `app/Services/EarningsEngine.php` — replace `computeChargeable` stub to delegate

Wraps strategy §8 v1 rules. v2 adds sock-puppet / engagement-ring detection.

- [ ] Create `AbuseGuard`:

```php
<?php
namespace App\Services;

use App\Services\Earnings\EarningEventDto;
use Illuminate\Support\Facades\DB;

class AbuseGuard
{
    /**
     * @return array{is_chargeable: bool, charge_reason: ?string}
     */
    public static function check(EarningEventDto $dto, array $attribution): array
    {
        // §8 — Self-action exclusion.
        if ($dto->actorUserId && $attribution['target_user_id'] === $dto->actorUserId) {
            return ['is_chargeable' => false, 'charge_reason' => 'self_action'];
        }

        // §8 — Per-viewer view dedupe (1 chargeable view per (viewer, post) per 1h video / 1 per session non-video).
        if ($dto->metric === 'view' && $dto->actorUserId && $dto->postId) {
            $exists = DB::table('earning_events')
                ->where('actor_user_id', $dto->actorUserId)
                ->where('post_id', $dto->postId)
                ->where('metric', 'view')
                ->where('is_chargeable', true)
                ->where('occurred_at', '>=', now()->subHour())
                ->exists();
            if ($exists) return ['is_chargeable' => false, 'charge_reason' => 'duplicate_view_within_1h'];
        }

        // §8 — Watch-second cap (≤ video_duration per (viewer, post, day)).
        if ($dto->metric === 'watch_second' && $dto->actorUserId && $dto->postId) {
            $secondsToday = (int) DB::table('earning_events')
                ->where('actor_user_id', $dto->actorUserId)
                ->where('post_id', $dto->postId)
                ->where('metric', 'watch_second')
                ->where('is_chargeable', true)
                ->whereDate('occurred_at', now()->toDateString())
                ->sum('raw_count');
            $videoDuration = (int) ($dto->videoDurationSeconds ?? PHP_INT_MAX);
            if ($secondsToday + $dto->rawCount > $videoDuration) {
                return ['is_chargeable' => false, 'charge_reason' => 'watch_second_cap_exceeded'];
            }
        }

        // §8 — Reaction churn cap (1 credit per (actor, target, metric, day)).
        if (in_array($dto->metric, ['reaction','save','comment_reaction'], true) && $dto->actorUserId) {
            $exists = DB::table('earning_events')
                ->where('actor_user_id', $dto->actorUserId)
                ->where('target_user_id', $attribution['target_user_id'])
                ->where('metric', $dto->metric)
                ->where('is_chargeable', true)
                ->whereDate('occurred_at', now()->toDateString())
                ->exists();
            if ($exists) return ['is_chargeable' => false, 'charge_reason' => 'reaction_churn'];
        }

        // §8 — Daily per-actor-per-creator cap (50 chargeable engagements/day).
        if ($dto->actorUserId) {
            $count = DB::table('earning_events')
                ->where('actor_user_id', $dto->actorUserId)
                ->where('target_user_id', $attribution['target_user_id'])
                ->where('is_chargeable', true)
                ->whereDate('occurred_at', now()->toDateString())
                ->count();
            if ($count >= 50) {
                return ['is_chargeable' => false, 'charge_reason' => 'daily_actor_creator_cap_50'];
            }
        }

        // §10.4 — Daily per-creator soft ceiling on engagement (TZS 500k).
        if ($dto->stream === 'engagement') {
            $todayCleared = (float) DB::table('earning_events')
                ->where('target_user_id', $attribution['target_user_id'])
                ->where('stream', 'engagement')
                ->where('is_chargeable', true)
                ->whereDate('occurred_at', now()->toDateString())
                ->sum('net_to_creator');
            if ($todayCleared >= config('earnings.daily_soft_cap_tsh', 500_000)) {
                return ['is_chargeable' => false, 'charge_reason' => 'daily_creator_soft_cap_500k'];
            }
        }

        return ['is_chargeable' => true, 'charge_reason' => null];
    }
}
```

- [ ] In `EarningsEngine`, replace the stub:

```php
public static function computeChargeable(EarningEventDto $dto, array $attribution): array
{
    return AbuseGuard::check($dto, $attribution);
}
```

- [ ] Commit: `feat(earnings): add AbuseGuard with v1 anti-abuse rules`

---

#### Task 20 — Method: `accruePoints` (active-period upsert)

**Files:**
- Modify: `app/Services/EarningsEngine.php`

Increments the creator's points for the open `creators_fund_periods` row. The "points" total for a creator equals the sum of `gross_credit` for engagement-stream events in the period — `fund_per_point × points = payout` per strategy §1.2.

- [ ] Replace the stub:

```php
public static function accruePoints(EarningEvent $event): void
{
    if ($event->stream !== 'engagement' || !$event->is_chargeable) return;

    $period = CreatorsFundPeriod::currentOpen() ?? CreatorsFundPeriod::openNextPeriod('phase_1');

    DB::table('creators_fund_points')->upsert(
        [[
            'period_id'     => $period->id,
            'user_id'       => $event->target_user_id,
            'points'        => $event->gross_credit,
            'events_count'  => 1,
            'last_event_at' => $event->occurred_at,
            'created_at'    => now(),
            'updated_at'    => now(),
        ]],
        ['period_id', 'user_id'],
        []
    );
    // Atomic increment — Postgres UPDATE on conflict.
    DB::statement(
        'UPDATE creators_fund_points SET points = points + ?, events_count = events_count + 1, last_event_at = ?, updated_at = now()
         WHERE period_id = ? AND user_id = ? AND created_at < ?',
        [$event->gross_credit, $event->occurred_at, $period->id, $event->target_user_id, now()->subSecond()]
    );
}
```

- [ ] Verify: insert one event via `EarningsEngine::recordEvent`, then `SELECT * FROM creators_fund_points WHERE user_id = X` shows the increment.
- [ ] Commit: `feat(earnings): implement EarningsEngine::accruePoints`

---

#### Task 21 — `EarningEventDto` class

**Files:**
- Create: `app/Services/Earnings/EarningEventDto.php`

The single argument shape into `recordEvent`. All event hooks construct a DTO, never call the engine with an associative array.

- [ ] Create:

```php
<?php
namespace App\Services\Earnings;

use Carbon\CarbonInterface;

class EarningEventDto
{
    // Identity
    public string $sourceType = 'post';   // 'post'|'comment'|'reply'|'live_stream'|'marketplace_order'
    public int $sourceId = 0;
    public ?int $postId = null;
    public ?int $commentId = null;

    // Actors
    public ?int $actorUserId = null;       // who fired the event (viewer / liker / commenter)
    public ?int $postAuthorId = null;      // resolved upstream by controller
    public ?int $commentAuthorId = null;
    public ?int $sharerUserId = null;      // populated if the actor came in via a share link
    public ?int $originalCreatorId = null; // for derivative_royalty events

    // Metric
    public string $stream = 'engagement';  // 'engagement'|'fan_funding'|'marketplace'|'brand_deal'|'live_gifts'|'affiliate'
    public string $metric = 'view';        // 'view'|'reaction'|'comment'|'reply'|'share'|'save'|'watch_second'|'follow_from_post'|'subscribe_from_post'|'live_gift'|'super_chat'|'live_reaction'|'derivative_royalty'|'subscription'|'tip'|'michango'|'marketplace_sale'|'brand_deal'|'comment_reaction'
    public int $rawCount = 1;

    // Multiplier inputs
    public ?float $watchCompletionPct = null;   // 0.0–1.0
    public ?int $videoDurationSeconds = null;
    public string $originalityFlag = 'original';
    public bool $discoveryModeActive = false;

    // Provenance + timing
    public ?string $fundingSource = null;
    public ?CarbonInterface $occurredAt = null;
}
```

- [ ] Commit: `feat(earnings): add EarningEventDto`

---

#### Task 22 — Service unit-test scaffolding

**Files:**
- Create: `tests/Unit/EarningsEngineTest.php` (skeleton only — full tests in Task 78)

- [ ] Create the empty scaffold so subsequent tasks can iterate:

```php
<?php
namespace Tests\Unit;

use Tests\TestCase;
use Illuminate\Foundation\Testing\RefreshDatabase;

class EarningsEngineTest extends TestCase
{
    use RefreshDatabase;

    /** @test (skeleton — full assertions in Task 78) */
    public function it_loads_the_engine_class(): void
    {
        $this->assertTrue(class_exists(\App\Services\EarningsEngine::class));
        $this->assertTrue(class_exists(\App\Services\Earnings\EarningEventDto::class));
    }
}
```

- [ ] Verify: `php artisan test --filter EarningsEngineTest::it_loads_the_engine_class` passes.
- [ ] Commit: `test(earnings): add EarningsEngine unit-test scaffold`

---

### Backend tier service (Tasks 23–25)

---

#### Task 23 — Service: `CreatorTierService`

**Files:**
- Create: `app/Services/CreatorTierService.php`

Promotes / demotes / pauses creators based on the tier gates in strategy §4 + the inactivity rule in §8.

- [ ] Create:

```php
<?php
namespace App\Services;

use App\Models\CreatorTier;
use Illuminate\Support\Facades\DB;
use Illuminate\Support\Facades\Log;

class CreatorTierService
{
    /**
     * Re-evaluate a creator's tier per strategy §4 gates.
     * Promotes if next-tier gates met; doesn't auto-demote (manual review only).
     */
    public static function evaluate(int $userId): void
    {
        $tier = CreatorTier::forUser($userId);
        $followers = (int) DB::table('user_follows')->where('following_id', $userId)->count();
        $views30d  = (int) DB::table('earning_events')
            ->where('target_user_id', $userId)
            ->where('metric', 'view')
            ->where('is_chargeable', true)
            ->where('occurred_at', '>=', now()->subDays(30))
            ->sum('raw_count');
        $strikes90d = (int) $tier->strike_count;
        $daysActive = (int) DB::table('earning_events')
            ->where('target_user_id', $userId)
            ->selectRaw('COUNT(DISTINCT DATE(occurred_at)) as d')
            ->value('d');

        $newTier = $tier->tier;
        if ($tier->tier === 'mwanzo' && $followers >= 100 && $daysActive >= 30 && $strikes90d === 0) {
            $newTier = 'standard';
        } elseif ($tier->tier === 'standard'
            && $followers >= 1000 && $views30d >= 50_000
            && $tier->is_id_verified && $strikes90d === 0) {
            $newTier = 'verified';
        } elseif ($tier->tier === 'verified'
            && $followers >= 10_000 && $views30d >= 500_000
            && $tier->promoted_at <= now()->subDays(90)) {
            // Partner is gated on manual review — flag for admin.
            $tier->update(['next_review_at' => now()->subSecond()]); // surface to admin
            return;
        }

        if ($newTier !== $tier->tier) {
            self::promote($userId, $newTier);
        } else {
            $tier->update(['next_review_at' => now()->addDays(7)]);
        }
    }

    public static function promote(int $userId, string $newTier): void
    {
        $tier = CreatorTier::forUser($userId);
        $tier->update([
            'tier'           => $newTier,
            'promoted_at'    => now(),
            'next_review_at' => now()->addDays(7),
        ]);
        Log::info("[CreatorTier] Promoted user #{$userId} to {$newTier}");
    }

    public static function demote(int $userId, string $newTier, string $reason): void
    {
        $tier = CreatorTier::forUser($userId);
        $tier->update(['tier' => $newTier, 'promoted_at' => now()]);
        Log::warning("[CreatorTier] Demoted user #{$userId} to {$newTier}: {$reason}");
    }

    /** §8 — pause monetization after 90 days of inactivity. */
    public static function checkInactivity(int $userId): void
    {
        $tier = CreatorTier::forUser($userId);
        $lastEvent = DB::table('earning_events')
            ->where('target_user_id', $userId)
            ->max('occurred_at');
        $lastPost = DB::table('posts')
            ->where('user_id', $userId)
            ->max('created_at');
        $latest = max($lastEvent, $lastPost);

        if ($latest && $latest <= now()->subDays(90)->toDateTimeString() && !$tier->monetization_paused) {
            $tier->update(['monetization_paused' => true]);
            Log::info("[CreatorTier] Monetization paused for user #{$userId} (90d inactive)");
        }
    }
}
```

- [ ] Verify with `php artisan tinker --execute="App\\Services\\CreatorTierService::evaluate(1);"` — should not throw.
- [ ] Commit: `feat(earnings): add CreatorTierService`

---

#### Task 24 — Tier gate config

**Files:**
- Create: `config/creator_tiers.php`

Pure config so tier gates can be tweaked without code changes (still 30-day-notice protected per §11.4).

- [ ] Create:

```php
<?php
return [
    // Strategy §4 — tier gates.
    'mwanzo' => [
        'rank'  => 0,
        'gates' => [
            'followers' => 0,
            'days_active' => 0,
        ],
        'features' => [
            'engagement_pool'      => true,
            'fan_funding'          => true,
            'marketplace'          => true,
            'live_gifts'           => false,
            'brand_deal_marketplace' => false,
            'discovery_mode'       => false,
        ],
        'mwanzo_window_days' => 30,
        'mwanzo_boost_mult' => 2.0,
    ],
    'standard' => [
        'rank'  => 1,
        'gates' => [
            'followers'   => 100,
            'days_active' => 30,
            'max_strikes' => 0,
        ],
        'features' => [
            'live_gifts'     => true,
            'discovery_mode' => true,
        ],
    ],
    'verified' => [
        'rank'  => 2,
        'gates' => [
            'followers'      => 1000,
            'views_30d'      => 50_000,
            'is_id_verified' => true,
            'max_strikes_90d'=> 0,
        ],
        'features' => [
            'brand_deal_marketplace' => true,
        ],
    ],
    'partner' => [
        'rank'  => 3,
        'gates' => [
            'followers'             => 10_000,
            'views_30d'             => 500_000,
            'days_as_verified'      => 90,
            'manual_review_required'=> true,
        ],
        'features' => [
            'engagement_split_75_25'   => true,
            'live_gifts_split_92_5_7_5'=> true,
            'brand_deal_split_92_5_7_5'=> true,
        ],
    ],
];
```

- [ ] Commit: `feat(earnings): add creator_tiers config`

---

#### Task 25 — `ResolvesUserProfileFromSanctumUser` trait

**Files:**
- Create: `app/Http/Controllers/Api/Concerns/ResolvesUserProfileFromSanctumUser.php`

The codebase pattern is to read `user_id` from request body, but the new earnings endpoints need a creator-resolution trait so the same logic isn't repeated. Match existing controller patterns: services accept the resolved user_id directly.

- [ ] Create:

```php
<?php
namespace App\Http\Controllers\Api\Concerns;

use Illuminate\Http\Request;
use Illuminate\Support\Facades\DB;

trait ResolvesUserProfileFromSanctumUser
{
    /**
     * Resolve the creator user_id for the request.
     * Order of precedence:
     *   1. ?user_id query/body param (existing pattern in this codebase)
     *   2. authenticated Sanctum user → look up user_profile.id
     *
     * Returns null if neither is present.
     */
    protected function resolveCreatorUserId(Request $request): ?int
    {
        if ($request->filled('user_id')) {
            return (int) $request->input('user_id');
        }
        if ($request->user()) {
            $profile = DB::table('user_profiles')
                ->where('phone_number', $request->user()->phone)
                ->first();
            return $profile ? (int) $profile->id : null;
        }
        return null;
    }
}
```

- [ ] Commit: `feat(earnings): add ResolvesUserProfileFromSanctumUser trait`

---

### Event-hook integration (Tasks 26–40)

Each task wires `EarningsEngine::recordEvent` into one existing controller method. The pattern is identical: build a `EarningEventDto`, fire-and-forget. Wrapped in `try/catch` so an earnings failure never breaks the engagement endpoint.

A reusable wrapper helper appears once and is reused:

```php
private function fireEarning(\Closure $build): void
{
    try {
        \App\Services\EarningsEngine::recordEvent($build());
    } catch (\Throwable $e) {
        \Log::warning('[Earnings] hook failed', ['error' => $e->getMessage()]);
    }
}
```

This helper is added to `app/Http/Controllers/Api/Concerns/FiresEarningEvents.php` (one trait, used everywhere):

- [ ] Create the helper trait once before any of the hook tasks (Task 26 is the right place):

```php
<?php
namespace App\Http\Controllers\Api\Concerns;

use App\Services\EarningsEngine;
use App\Services\Earnings\EarningEventDto;
use Closure;
use Illuminate\Support\Facades\Log;

trait FiresEarningEvents
{
    protected function fireEarning(Closure $build): void
    {
        try {
            EarningsEngine::recordEvent($build());
        } catch (\Throwable $e) {
            Log::warning('[Earnings] hook failed', ['error' => $e->getMessage(), 'class' => static::class]);
        }
    }
}
```

---

#### Task 26 — Hook `POST /posts/{id}/view`

**Files:**
- Create: `app/Http/Controllers/Api/Concerns/FiresEarningEvents.php` (trait above)
- Modify: `app/Http/Controllers/Api/PostController.php` — `recordView()`

- [ ] Add the `use FiresEarningEvents;` to `PostController`.
- [ ] Inside `recordView(int $id, Request $request)`, after the existing view-counter increment, append:

```php
$post = \App\Models\Post::select(['id','user_id','duration_seconds','is_discovery_mode','reply_to_post_id','stitch_from_post_id','quote_from_post_id'])->find($id);
if ($post) {
    $sharerUserId = $request->input('sharer_user_id') ? (int) $request->input('sharer_user_id') : null;
    $watchPct = $request->filled('watch_completion_pct') ? (float) $request->input('watch_completion_pct') : null;
    $this->fireEarning(function () use ($post, $request, $sharerUserId, $watchPct) {
        $dto = new EarningEventDto();
        $dto->sourceType = 'post';
        $dto->sourceId = (int) $post->id;
        $dto->postId = (int) $post->id;
        $dto->postAuthorId = (int) $post->user_id;
        $dto->actorUserId = $request->input('user_id') ? (int) $request->input('user_id') : null;
        $dto->sharerUserId = $sharerUserId;
        $dto->stream = 'engagement';
        $dto->metric = 'view';
        $dto->watchCompletionPct = $watchPct;
        $dto->videoDurationSeconds = $post->duration_seconds ? (int) $post->duration_seconds : null;
        $dto->originalityFlag = \App\Services\OriginalityDetector::classify((int) $post->id);
        $dto->discoveryModeActive = (bool) ($post->is_discovery_mode ?? false);
        return $dto;
    });
}
```

- [ ] Verify with `curl -X POST localhost/api/posts/1/view -H 'Authorization: Bearer ...' -d '{"user_id":2}'` — confirm a row in `earning_events` with `metric='view'`.
- [ ] Commit: `feat(earnings): hook view event into PostController::recordView`

---

#### Task 27 — Hook `POST/DELETE /posts/{id}/like` (reaction)

**Files:**
- Modify: `app/Http/Controllers/Api/PostController.php` — `like()` and `unlike()`

`like` fires `metric=reaction`. `unlike` does NOT reverse the credit (the reaction-churn rule prevents new credits, but a removed reaction never credit-rolls back the original). Strategy §8 is silent on retroactive un-credit and the implementation choice is "preserve the original earning."

- [ ] Inside `like(int $id, Request $request)`, after persisting the like row:

```php
$post = \App\Models\Post::select(['id','user_id'])->find($id);
if ($post) {
    $reactionType = $request->input('reaction_type', 'like');
    $this->fireEarning(function () use ($post, $request, $reactionType) {
        $dto = new EarningEventDto();
        $dto->sourceType = 'post';
        $dto->sourceId = (int) $post->id;
        $dto->postId = (int) $post->id;
        $dto->postAuthorId = (int) $post->user_id;
        $dto->actorUserId = (int) $request->input('user_id');
        $dto->stream = 'engagement';
        $dto->metric = 'reaction';
        $dto->fundingSource = "reaction_type:{$reactionType}";
        return $dto;
    });
}
```

- [ ] `unlike()` requires no earnings hook (per design — credit not reversed).
- [ ] Commit: `feat(earnings): hook reaction event into PostController::like`

---

#### Task 28 — Hook `POST/DELETE /posts/{id}/save`

**Files:**
- Modify: `app/Http/Controllers/Api/PostController.php` — `savePost()`

- [ ] Inside `savePost(int $id, Request $request)`, after persisting the save:

```php
$post = \App\Models\Post::select(['id','user_id'])->find($id);
if ($post) {
    $this->fireEarning(function () use ($post, $request) {
        $dto = new EarningEventDto();
        $dto->sourceType = 'post';
        $dto->sourceId = (int) $post->id;
        $dto->postId = (int) $post->id;
        $dto->postAuthorId = (int) $post->user_id;
        $dto->actorUserId = (int) $request->input('user_id');
        $dto->stream = 'engagement';
        $dto->metric = 'save';
        return $dto;
    });
}
```

- [ ] Commit: `feat(earnings): hook save event into PostController::savePost`

---

#### Task 29 — Hook `POST /posts/{id}/share` + sharer attribution chain

**Files:**
- Create: `database/migrations/2026_05_03_000008_create_post_share_attributions_table.php`
- Modify: `app/Http/Controllers/Api/PostController.php` — `share()`

A view that arrives "via" a share needs to credit the sharer (B+C). We track this with a `post_share_attributions` row tagged with a UUID — the share URL embeds the UUID; when a viewer hits `/posts/{id}/view?via=<uuid>`, the controller looks up the sharer.

- [ ] Create migration:

```php
Schema::create('post_share_attributions', function (Blueprint $table) {
    $table->id();
    $table->uuid('share_uid')->unique();
    $table->unsignedBigInteger('post_id');
    $table->unsignedBigInteger('sharer_user_id');
    $table->timestampTz('expires_at');         // 30 days
    $table->timestampsTz();
    $table->index(['post_id', 'sharer_user_id']);
});
```

- [ ] Inside `share(int $id, Request $request)`:

```php
$post = \App\Models\Post::select(['id','user_id'])->find($id);
if (!$post) return response()->json(['success'=>false,'message'=>'Post not found'], 404);

$shareUid = (string) \Illuminate\Support\Str::uuid();
DB::table('post_share_attributions')->insert([
    'share_uid'      => $shareUid,
    'post_id'        => (int) $post->id,
    'sharer_user_id' => (int) $request->input('user_id'),
    'expires_at'     => now()->addDays(30),
    'created_at'     => now(),
    'updated_at'     => now(),
]);

$this->fireEarning(function () use ($post, $request) {
    $dto = new EarningEventDto();
    $dto->sourceType = 'post';
    $dto->sourceId = (int) $post->id;
    $dto->postId = (int) $post->id;
    $dto->postAuthorId = (int) $post->user_id;
    $dto->actorUserId = (int) $request->input('user_id');
    $dto->stream = 'engagement';
    $dto->metric = 'share';
    return $dto;
});

return response()->json(['success'=>true,'data'=>['share_uid'=>$shareUid]]);
```

- [ ] In `recordView` (Task 26), if `?via=<uuid>` present, look up the sharer and pass `sharerUserId` to the DTO.
- [ ] Commit: `feat(earnings): hook share event + sharer-attribution chain`

---

#### Task 30 — Hook `POST /posts/{id}/comments` (comment + reply)

**Files:**
- Modify: `app/Http/Controllers/Api/CommentController.php` — `store()`

If `parent_id` is set, the event is `metric=reply` (which credits both the post author and the parent-comment author per strategy §2.1). Otherwise it's `metric=comment`.

- [ ] Add `use FiresEarningEvents;` to `CommentController`.
- [ ] Inside `store(int $id, Request $request)`, after creating the comment:

```php
$post = \App\Models\Post::select(['id','user_id'])->find($id);
if ($post) {
    $parentCommentId = $request->filled('parent_id') ? (int) $request->input('parent_id') : null;
    $parentCommentAuthorId = null;
    if ($parentCommentId) {
        $parentCommentAuthorId = (int) DB::table('comments')->where('id', $parentCommentId)->value('user_id');
    }
    $this->fireEarning(function () use ($post, $request, $comment, $parentCommentId, $parentCommentAuthorId) {
        $dto = new EarningEventDto();
        $dto->sourceType = $parentCommentId ? 'reply' : 'comment';
        $dto->sourceId = (int) $comment->id;
        $dto->postId = (int) $post->id;
        $dto->commentId = (int) $comment->id;
        $dto->postAuthorId = (int) $post->user_id;
        $dto->commentAuthorId = $parentCommentAuthorId;
        $dto->actorUserId = (int) $request->input('user_id');
        $dto->stream = 'engagement';
        $dto->metric = $parentCommentId ? 'reply' : 'comment';
        return $dto;
    });
}
```

- [ ] Commit: `feat(earnings): hook comment + reply events into CommentController::store`

---

#### Task 31 — Hook `POST /comments/{id}/like` (comment_reaction)

**Files:**
- Modify: `app/Http/Controllers/Api/CommentController.php` — `like()`

Strategy §2.1 — a reaction on a comment credits BOTH the comment_author (primary) and the post author (host share).

- [ ] Inside `like(int $id, Request $request)`:

```php
$comment = DB::table('comments')->where('id', $id)->first();
if ($comment) {
    $post = \App\Models\Post::select(['id','user_id'])->find($comment->post_id);
    $this->fireEarning(function () use ($comment, $post, $request) {
        $dto = new EarningEventDto();
        $dto->sourceType = 'comment';
        $dto->sourceId = (int) $comment->id;
        $dto->postId = $post ? (int) $post->id : null;
        $dto->commentId = (int) $comment->id;
        $dto->postAuthorId = $post ? (int) $post->user_id : null;
        $dto->commentAuthorId = (int) $comment->user_id;
        $dto->actorUserId = (int) $request->input('user_id');
        $dto->stream = 'engagement';
        $dto->metric = 'comment_reaction';
        return $dto;
    });
}
```

- [ ] Commit: `feat(earnings): hook comment_reaction event into CommentController::like`

---

#### Task 32 — Hook reply-post derivative-content royalty

**Files:**
- Modify: `app/Http/Controllers/Api/PostController.php` — `store()`

Strategy §2.2 — when a creator creates a "reply post" (a new post, not a comment, with `reply_to_post_id` set), the original post author gets a derivative_royalty event.

- [ ] In `store()`, after the new post is created, if `reply_to_post_id` is set:

```php
if ($request->filled('reply_to_post_id')) {
    $original = \App\Models\Post::select(['id','user_id'])->find((int) $request->input('reply_to_post_id'));
    if ($original) {
        $this->fireEarning(function () use ($post, $original, $request) {
            $dto = new EarningEventDto();
            $dto->sourceType = 'post';
            $dto->sourceId = (int) $post->id;
            $dto->postId = (int) $post->id;
            $dto->postAuthorId = (int) $post->user_id;       // creator of the reply post
            $dto->originalCreatorId = (int) $original->user_id;
            $dto->actorUserId = (int) $post->user_id;
            $dto->stream = 'engagement';
            $dto->metric = 'derivative_royalty';
            $dto->originalityFlag = 'derivative_substantial';
            return $dto;
        });
    }
}
```

- [ ] Commit: `feat(earnings): hook reply-post derivative royalty`

---

#### Task 33 — Hook stitch derivative royalty

**Files:**
- Modify: `app/Http/Controllers/Api/PostController.php` — `store()`

Same shape as Task 32 but `stitch_from_post_id`.

- [ ] In `store()`:

```php
if ($request->filled('stitch_from_post_id')) {
    $original = \App\Models\Post::select(['id','user_id'])->find((int) $request->input('stitch_from_post_id'));
    if ($original) {
        $this->fireEarning(function () use ($post, $original) {
            $dto = new EarningEventDto();
            $dto->sourceType = 'post';
            $dto->sourceId = (int) $post->id;
            $dto->postId = (int) $post->id;
            $dto->postAuthorId = (int) $post->user_id;
            $dto->originalCreatorId = (int) $original->user_id;
            $dto->actorUserId = (int) $post->user_id;
            $dto->stream = 'engagement';
            $dto->metric = 'derivative_royalty';
            $dto->originalityFlag = 'derivative_substantial';
            return $dto;
        });
    }
}
```

- [ ] Commit: `feat(earnings): hook stitch derivative royalty`

---

#### Task 34 — Hook quote-post derivative royalty

**Files:**
- Modify: `app/Http/Controllers/Api/PostController.php` — `store()`

Same shape with `quote_from_post_id`.

- [ ] In `store()`:

```php
if ($request->filled('quote_from_post_id')) {
    $original = \App\Models\Post::select(['id','user_id'])->find((int) $request->input('quote_from_post_id'));
    if ($original) {
        $this->fireEarning(function () use ($post, $original) {
            $dto = new EarningEventDto();
            $dto->sourceType = 'post';
            $dto->sourceId = (int) $post->id;
            $dto->postId = (int) $post->id;
            $dto->postAuthorId = (int) $post->user_id;
            $dto->originalCreatorId = (int) $original->user_id;
            $dto->actorUserId = (int) $post->user_id;
            $dto->stream = 'engagement';
            $dto->metric = 'derivative_royalty';
            $dto->originalityFlag = 'derivative_substantial';
            return $dto;
        });
    }
}
```

- [ ] Commit: `feat(earnings): hook quote-post derivative royalty`

---

#### Task 35 — Hook `POST /follows` discovery credit

**Files:**
- Create: `database/migrations/2026_05_03_000009_add_origin_post_id_to_user_follows.php`
- Modify: `app/Http/Controllers/Api/FollowController.php` — `follow()`

A follow that originated from a specific post (e.g. user clicked "follow" on a post detail screen) credits the post author with `metric=follow_from_post`.

- [ ] Create migration:

```php
Schema::table('user_follows', function (Blueprint $table) {
    $table->unsignedBigInteger('origin_post_id')->nullable()->after('following_id');
    $table->index('origin_post_id');
});
```

- [ ] Add `use FiresEarningEvents;` to `FollowController`.
- [ ] In `follow(Request $request)`, persist `origin_post_id` if present, and after the follow is created:

```php
if ($request->filled('origin_post_id')) {
    $post = \App\Models\Post::select(['id','user_id'])->find((int) $request->input('origin_post_id'));
    if ($post && $post->user_id !== (int) $request->input('follower_id')) {
        $this->fireEarning(function () use ($post, $request) {
            $dto = new EarningEventDto();
            $dto->sourceType = 'post';
            $dto->sourceId = (int) $post->id;
            $dto->postId = (int) $post->id;
            $dto->postAuthorId = (int) $post->user_id;
            $dto->actorUserId = (int) $request->input('follower_id');
            $dto->stream = 'engagement';
            $dto->metric = 'follow_from_post';
            return $dto;
        });
    }
}
```

- [ ] Commit: `feat(earnings): hook follow_from_post discovery credit`

---

#### Task 36 — Hook subscribe discovery credit

**Files:**
- Create: `database/migrations/2026_05_03_000010_add_origin_post_id_to_subscriptions.php`
- Modify: `app/Http/Controllers/Api/SubscriptionController.php` — wherever `subscribe`/`store` lives

- [ ] Create migration:

```php
Schema::table('subscriptions', function (Blueprint $table) {
    $table->unsignedBigInteger('origin_post_id')->nullable();
    $table->index('origin_post_id');
});
```

- [ ] In subscription create flow, after the subscription row is persisted:

```php
if ($request->filled('origin_post_id')) {
    $post = \App\Models\Post::select(['id','user_id'])->find((int) $request->input('origin_post_id'));
    if ($post) {
        $this->fireEarning(function () use ($post, $request) {
            $dto = new EarningEventDto();
            $dto->sourceType = 'post';
            $dto->sourceId = (int) $post->id;
            $dto->postId = (int) $post->id;
            $dto->postAuthorId = (int) $post->user_id;
            $dto->actorUserId = (int) $request->input('subscriber_id');
            $dto->stream = 'engagement';
            $dto->metric = 'subscribe_from_post';
            return $dto;
        });
    }
}
```

Note — the actual subscription pass-through credit (95% of subscription price → fan_funding stream) is fired separately at the same point with `stream='fan_funding'`, `metric='subscription'`.

- [ ] Commit: `feat(earnings): hook subscribe_from_post discovery credit + fan_funding pass-through`

---

#### Task 37 — Hook `POST /streams/{id}/gifts` (live gift)

**Files:**
- Modify: `app/Http/Controllers/Api/LiveStreamController.php` — `sendGift()`

- [ ] Add `use FiresEarningEvents;` to `LiveStreamController`.
- [ ] Inside `sendGift(int $id, Request $request)` after the gift row is persisted:

```php
$stream = DB::table('live_streams')->where('id', $id)->first();
if ($stream) {
    $giftValueTsh = (float) $request->input('value_tsh', 0);
    $this->fireEarning(function () use ($stream, $request, $giftValueTsh) {
        $dto = new EarningEventDto();
        $dto->sourceType = 'live_stream';
        $dto->sourceId = (int) $stream->id;
        $dto->postAuthorId = (int) $stream->host_user_id;
        $dto->actorUserId = (int) $request->input('sender_user_id');
        $dto->stream = 'live_gifts';
        $dto->metric = 'live_gift';
        $dto->rawCount = max(1, (int) round($giftValueTsh));   // raw_count = TSh value; rate is 0.90
        $dto->fundingSource = "fan:{$request->input('sender_user_id')}";
        return $dto;
    });
}
```

- [ ] Commit: `feat(earnings): hook live_gift event into LiveStreamController::sendGift`

---

#### Task 38 — Hook `POST /streams/{id}/super-chats`

**Files:**
- Modify: `app/Http/Controllers/Api/LiveStreamController.php` — `sendSuperChat()` (or equivalent — confirm method name)

If the controller does not yet have a super-chat endpoint, this task is deferred to v2 and a TODO note is added in the controller.

- [ ] Same shape as Task 37 with `metric='super_chat'`.
- [ ] Commit: `feat(earnings): hook super_chat event` (or skip if endpoint absent — note in v2 backlog)

---

#### Task 39 — Hook `POST /streams/{id}/reactions` (live_reaction)

**Files:**
- Modify: `app/Http/Controllers/Api/AdvancedStreamController.php` — `storeReaction()`

- [ ] Add `use FiresEarningEvents;` to `AdvancedStreamController`.
- [ ] After the reaction is persisted:

```php
$liveStream = DB::table('live_streams')->where('id', $id)->first();
if ($liveStream) {
    $this->fireEarning(function () use ($liveStream, $request) {
        $dto = new EarningEventDto();
        $dto->sourceType = 'live_stream';
        $dto->sourceId = (int) $liveStream->id;
        $dto->postAuthorId = (int) $liveStream->host_user_id;
        $dto->actorUserId = (int) $request->input('user_id');
        $dto->stream = 'engagement';
        $dto->metric = 'live_reaction';
        return $dto;
    });
}
```

- [ ] Commit: `feat(earnings): hook live_reaction event`

---

#### Task 40 — Hook `POST /shop/orders` (marketplace_sale)

**Files:**
- Modify: `app/Http/Controllers/Api/V1/Shop/ShopOrderController.php` — `store()`

Strategy §1.1 stream 3 — Marketplace: 0% fee for first 90 days (Mwanzo), 5% after. The controller already collects payment; here we only fire the creator-credit event for any order with a `post_id` linkage.

- [ ] Add `use FiresEarningEvents;`.
- [ ] After the order is persisted, if the order references a post:

```php
$postId = (int) $request->input('post_id', 0);
if ($postId > 0) {
    $post = \App\Models\Post::select(['id','user_id'])->find($postId);
    if ($post) {
        $this->fireEarning(function () use ($post, $order, $request) {
            $dto = new EarningEventDto();
            $dto->sourceType = 'marketplace_order';
            $dto->sourceId = (int) $order->id;
            $dto->postId = (int) $post->id;
            $dto->postAuthorId = (int) $post->user_id;
            $dto->actorUserId = (int) $request->input('buyer_id');
            $dto->stream = 'marketplace';
            $dto->metric = 'marketplace_sale';
            $dto->rawCount = max(1, (int) round((float) $order->total_amount));
            $dto->fundingSource = "buyer:{$request->input('buyer_id')}";
            return $dto;
        });
    }
}
```

- [ ] Commit: `feat(earnings): hook marketplace_sale event into ShopOrderController::store`

---

### Backend settlement + sweep jobs (Tasks 41–43)

---

#### Task 41 — Job: `CreatorsFundPeriodSettlementJob` (weekly)

**Files:**
- Create: `app/Jobs/CreatorsFundPeriodSettlementJob.php`

The weekly fund-replenishment + distribution job per strategy §1.2. Closes the prior period, computes `fund_size` per the active phase formula, aggregates points, computes `fund_per_point`, writes per-creator settlement events + journal_lines, then opens the next period.

- [ ] Create:

```php
<?php
namespace App\Jobs;

use App\Models\CreatorsFundPeriod;
use App\Models\CreatorsFundPoint;
use App\Models\EarningEvent;
use Illuminate\Bus\Queueable;
use Illuminate\Contracts\Queue\ShouldQueue;
use Illuminate\Foundation\Bus\Dispatchable;
use Illuminate\Support\Facades\DB;
use Illuminate\Support\Facades\Log;

class CreatorsFundPeriodSettlementJob implements ShouldQueue
{
    use Dispatchable, Queueable;

    public function handle(): void
    {
        // Close every open period whose period_end has passed.
        $periods = CreatorsFundPeriod::where('status', 'open')
            ->where('period_end', '<=', now())
            ->get();

        foreach ($periods as $period) {
            $this->settle($period);
        }

        // Always make sure there is an open period for "now".
        if (!CreatorsFundPeriod::currentOpen()) {
            CreatorsFundPeriod::openNextPeriod($this->activePhase());
        }
    }

    private function activePhase(): string
    {
        // Phase 2 transition — strategy §1.3 — gated by board flag in config.
        return config('earnings.phase', 'phase_1');
    }

    private function settle(CreatorsFundPeriod $period): void
    {
        DB::transaction(function () use ($period) {
            $period->update(['status' => 'distributing']);

            $fundSize = $this->computeFundSize($period);
            $totalPoints = (float) DB::table('creators_fund_points')
                ->where('period_id', $period->id)
                ->sum('points');

            $fundPerPoint = $totalPoints > 0 ? round($fundSize / $totalPoints, 8) : 0.0;
            $eligibleCount = (int) DB::table('creators_fund_points')
                ->where('period_id', $period->id)
                ->where('points', '>', 0)
                ->count();

            // Phase 1 batch journal: Dr. 5110 (CAC) Cr. 2105 (Pending Distribution).
            $batchAccountDebit = $period->phase === 'phase_1' ? '5110' : '5111';
            $batchJournalId = DB::table('journal_lines')->insertGetId([
                'account_code' => $batchAccountDebit,
                'debit'        => $fundSize,
                'credit'       => 0,
                'description'  => "Creators Fund commitment — period #{$period->id} ({$period->phase})",
                'reference_type' => 'creators_fund_period',
                'reference_id'   => $period->id,
                'created_at'   => now(),
                'updated_at'   => now(),
            ]);
            DB::table('journal_lines')->insert([
                'account_code' => '2105',
                'debit'        => 0,
                'credit'       => $fundSize,
                'description'  => "Creators Fund commitment — period #{$period->id}",
                'reference_type' => 'creators_fund_period',
                'reference_id'   => $period->id,
                'created_at'   => now(),
                'updated_at'   => now(),
            ]);

            // Per-creator settlement.
            $creators = DB::table('creators_fund_points')
                ->where('period_id', $period->id)
                ->where('points', '>', 0)
                ->get();
            foreach ($creators as $row) {
                $payout = round((float) $row->points * $fundPerPoint, 2);
                DB::table('creators_fund_points')->where('id', $row->id)->update(['payout_tsh' => $payout]);

                // Single "period_settlement" earning event row resolves the period to TZS.
                $event = EarningEvent::create([
                    'event_uid'      => "settle:{$period->id}:user:{$row->user_id}",
                    'occurred_at'    => now(),
                    'source_type'    => 'creators_fund_period',
                    'source_id'      => $period->id,
                    'target_user_id' => $row->user_id,
                    'actor_role'     => 'author',
                    'stream'         => 'engagement',
                    'metric'         => 'period_settlement',
                    'raw_count'      => 1,
                    'rate_tsh'       => $fundPerPoint,
                    'multipliers'    => [],
                    'gross_credit'   => $payout,
                    'platform_take'  => 0,
                    'tra_wht_held'   => 0,
                    'net_to_creator' => $payout,
                    'is_chargeable'  => true,
                    'funding_source' => "creators_fund_period:{$period->id}",
                    'settlement_status' => 'pending',
                ]);

                // Dr. 2105 Cr. 2110 — move from "Pending Distribution" to "Pending Engagement Earnings".
                DB::table('journal_lines')->insert([[
                    'account_code' => '2105', 'debit' => $payout, 'credit' => 0,
                    'description' => "Distribute to user #{$row->user_id} — period #{$period->id}",
                    'reference_type' => 'earning_event', 'reference_id' => $event->id,
                    'created_at' => now(), 'updated_at' => now(),
                ], [
                    'account_code' => '2110', 'debit' => 0, 'credit' => $payout,
                    'description' => "Distribute to user #{$row->user_id} — period #{$period->id}",
                    'reference_type' => 'earning_event', 'reference_id' => $event->id,
                    'created_at' => now(), 'updated_at' => now(),
                ]]);
                $event->update(['journal_line_pending_id' => DB::getPdo()->lastInsertId()]);
            }

            $period->update([
                'status'                  => 'settled',
                'fund_size_tsh'           => $fundSize,
                'total_points'            => $totalPoints,
                'fund_per_point'          => $fundPerPoint,
                'eligible_creator_count'  => $eligibleCount,
                'settled_at'              => now(),
                'settlement_journal_batch_id' => $batchJournalId,
            ]);

            Log::info("[CreatorsFundSettlement] Period #{$period->id} ({$period->phase}) settled: fund TZS {$fundSize}, {$eligibleCount} creators, fund/point {$fundPerPoint}");
        });
    }

    /** §1.2 — fund-size formulas. */
    private function computeFundSize(CreatorsFundPeriod $period): float
    {
        if ($period->phase === 'phase_1') {
            return (float) ($period->phase_1_committed_budget_tsh ?? config('earnings.phase_1_weekly_fund_tsh', 50_000_000));
        }
        $adRev    = (float) ($period->ad_revenue_tsh ?? 0);
        $passThru = (float) ($period->fan_funding_take_tsh ?? 0)
                  + (float) ($period->marketplace_take_tsh ?? 0)
                  + (float) ($period->brand_deal_take_tsh ?? 0)
                  + (float) ($period->live_gifts_take_tsh ?? 0);
        $topup    = (float) ($period->treasury_topup_tsh ?? 0);
        $floor    = (float) $period->floor_tsh;
        return max($floor, ($period->ad_share_pct ?? 0.70) * $adRev + ($period->pass_through_share_pct ?? 0.10) * $passThru + $topup);
    }
}
```

- [ ] Schedule weekly Monday 00:00 UTC+3 in `app/Console/Kernel.php` (or `routes/console.php`):
  ```php
  Schedule::job(new \App\Jobs\CreatorsFundPeriodSettlementJob())
      ->weeklyOn(1, '00:00')
      ->timezone('Africa/Nairobi');
  ```
- [ ] Verify dispatch: `php artisan tinker --execute="dispatch_sync(new App\\Jobs\\CreatorsFundPeriodSettlementJob());"`
- [ ] Commit: `feat(earnings): add CreatorsFundPeriodSettlementJob`

---

#### Task 42 — Job: `SettlementSweepJob` (daily pending → cleared)

**Files:**
- Create: `app/Jobs/SettlementSweepJob.php`

Daily. Sweeps `earning_events` rows ≥30 days old (45 for fan_funding) from `pending` → `cleared`. Auto-deducts TRA Section 83B WHT (5%) for TZ-resident creators per §7.1. Writes a Dr. 2110/2111/.../2114 → Cr. 2120 journal pair plus the WHT entries.

- [ ] Create:

```php
<?php
namespace App\Jobs;

use App\Models\EarningEvent;
use Illuminate\Bus\Queueable;
use Illuminate\Contracts\Queue\ShouldQueue;
use Illuminate\Foundation\Bus\Dispatchable;
use Illuminate\Support\Facades\DB;
use Illuminate\Support\Facades\Log;

class SettlementSweepJob implements ShouldQueue
{
    use Dispatchable, Queueable;

    public function handle(): void
    {
        $whtRate = (float) config('earnings.wht_rate', 0.05);
        $window  = (int) config('earnings.settlement_window_days', 30);
        $fundingWindow = (int) config('earnings.fan_funding_window_days', 45);

        $events = EarningEvent::query()
            ->where('settlement_status', 'pending')
            ->where('is_chargeable', true)
            ->where(function ($q) use ($window, $fundingWindow) {
                $q->where(function ($q1) use ($window) {
                    $q1->where('stream', '!=', 'fan_funding')
                       ->where('occurred_at', '<=', now()->subDays($window));
                })->orWhere(function ($q2) use ($fundingWindow) {
                    $q2->where('stream', 'fan_funding')
                       ->where('occurred_at', '<=', now()->subDays($fundingWindow));
                });
            })
            ->limit(5000)
            ->get();

        $cleared = 0;
        foreach ($events as $event) {
            DB::transaction(function () use ($event, $whtRate, &$cleared) {
                // Tax residency lookup — TZ residents get 5% WHT.
                $isTzResident = (string) DB::table('user_profiles')
                    ->where('id', $event->target_user_id)
                    ->value('tax_residency') !== 'NON_TZ';

                $wht = $isTzResident ? round($event->net_to_creator * $whtRate, 2) : 0.0;
                $netAfterWht = max(0.0, round($event->net_to_creator - $wht, 2));

                $pendingAccount = match ($event->stream) {
                    'engagement'  => '2110',
                    'fan_funding' => '2111',
                    'marketplace' => '2112',
                    'brand_deal'  => '2113',
                    'live_gifts'  => '2114',
                    default       => '2110',
                };

                // Dr. pending → Cr. cleared (gross net)
                DB::table('journal_lines')->insert([
                    ['account_code'=>$pendingAccount,'debit'=>$event->net_to_creator,'credit'=>0,
                     'description'=>"Sweep clear — event {$event->id}",
                     'reference_type'=>'earning_event','reference_id'=>$event->id,
                     'created_at'=>now(),'updated_at'=>now()],
                    ['account_code'=>'2120','debit'=>0,'credit'=>$netAfterWht,
                     'description'=>"Sweep clear — event {$event->id}",
                     'reference_type'=>'earning_event','reference_id'=>$event->id,
                     'created_at'=>now(),'updated_at'=>now()],
                ]);

                if ($wht > 0) {
                    DB::table('journal_lines')->insert([
                        'account_code'=>'2140','debit'=>0,'credit'=>$wht,
                        'description'=>"WHT 5% — event {$event->id}",
                        'reference_type'=>'earning_event','reference_id'=>$event->id,
                        'created_at'=>now(),'updated_at'=>now(),
                    ]);
                }

                $event->update([
                    'settlement_status'      => 'cleared',
                    'cleared_at'             => now(),
                    'tra_wht_held'           => $wht,
                    'net_to_creator'         => $netAfterWht,
                    'journal_line_cleared_id'=> DB::getPdo()->lastInsertId(),
                ]);
                $cleared++;
            });
        }

        Log::info("[SettlementSweep] Cleared {$cleared} events");
    }
}
```

- [ ] Schedule daily at 02:00:
  ```php
  Schedule::job(new \App\Jobs\SettlementSweepJob())->dailyAt('02:00');
  ```
- [ ] Verify with `php artisan schedule:list` shows the job.
- [ ] Commit: `feat(earnings): add SettlementSweepJob (pending→cleared with WHT)`

---

#### Task 43 — Job: `MwanzoExpiryJob` (daily Mwanzo→Standard transition)

**Files:**
- Create: `app/Jobs/MwanzoExpiryJob.php`

Strategy §3.2 + §4 — at day 31, Mwanzo → Standard if base gates met, else stays Mwanzo. The Mwanzo row simply has `mwanzo_expires_at` set; this job evaluates the gate and either promotes (delegating to `CreatorTierService`) or extends the boost to a "graceful catch-up" of one more week if the user is one gate short.

- [ ] Create:

```php
<?php
namespace App\Jobs;

use App\Models\CreatorTier;
use App\Services\CreatorTierService;
use Illuminate\Bus\Queueable;
use Illuminate\Contracts\Queue\ShouldQueue;
use Illuminate\Foundation\Bus\Dispatchable;
use Illuminate\Support\Facades\Log;

class MwanzoExpiryJob implements ShouldQueue
{
    use Dispatchable, Queueable;

    public function handle(): void
    {
        $expiring = CreatorTier::where('tier', 'mwanzo')
            ->whereNotNull('mwanzo_expires_at')
            ->where('mwanzo_expires_at', '<=', now())
            ->limit(2000)
            ->get();

        foreach ($expiring as $tier) {
            CreatorTierService::evaluate($tier->user_id);
            // After evaluate, the tier may now be 'standard'. If still mwanzo, simply mark the boost as expired.
            $tier->refresh();
            if ($tier->tier === 'mwanzo') {
                // Boost done — expire it (multiplier returns null going forward).
                $tier->update(['mwanzo_expires_at' => $tier->mwanzo_expires_at]);
            }
        }

        Log::info("[MwanzoExpiry] Evaluated " . $expiring->count() . " creators at Mwanzo expiry");
    }
}
```

- [ ] Schedule daily at 04:00:
  ```php
  Schedule::job(new \App\Jobs\MwanzoExpiryJob())->dailyAt('04:00');
  ```
- [ ] Commit: `feat(earnings): add MwanzoExpiryJob`

---

### Backend payout + TRA WHT integration (Tasks 54–59 — overrides default 53→59 numbering due to partial-plan 53)

> Note: Task 53 (PayoutService wrapper) is in the partial plan immediately following Task 52. Tasks 54–59 below are payout / WHT policy wires that build on top of Task 53. Task 54–56 in the partial plan covers mobile-money rails / fee-free / payout-preference; Tasks 57–59 cover WHT config, auto-deduct, and tax invoice. Those task definitions live in /tmp/creators_fund_plan_part2.md and are appended verbatim below.
>
> The tasks listed in this section are the build-order versions; if duplicated by partial-plan numbering, the partial wins (read-only).

---

## Notes for tasks 44 onwards

The remaining tasks (44 through 84) cover background jobs (TierReview, PayoutDisbursement, TRARemittance), the read endpoints (rewriting `GET /posts/{id}/earnings` to read from `earning_events`, new dashboard / events / rate-card / tax / disputes / discovery-mode endpoints), the PayoutService wrapper, mobile-money / fee-free / preference policy wires, WHT config + auto-deduct + tax invoice stub, the entire frontend (Flutter models, services, dashboard / provenance / tier screens, navigation wiring), backfill policy, unit + feature + widget tests, deploy checklist, and rollout announcement.

These tasks are appended verbatim below from the second half of the plan and pick up at "Task 44 — Background job: TierReviewJob".

---

#### Task 44 — Background job: `TierReviewJob`

**Files:**
- Create: `app/Jobs/TierReviewJob.php`

- [ ] Create:

```php
<?php
namespace App\Jobs;

use App\Models\CreatorTier;
use App\Services\CreatorTierService;
use Illuminate\Bus\Queueable;
use Illuminate\Contracts\Queue\ShouldQueue;
use Illuminate\Foundation\Bus\Dispatchable;
use Illuminate\Support\Facades\Log;

class TierReviewJob implements ShouldQueue
{
    use Dispatchable, Queueable;

    public function handle(): void
    {
        // Review all Standard creators who haven't been checked in 7 days
        $candidates = CreatorTier::whereIn('tier', ['standard', 'verified'])
            ->where(function ($q) {
                $q->whereNull('next_review_at')->orWhere('next_review_at', '<=', now());
            })
            ->pluck('user_id');

        foreach ($candidates as $userId) {
            CreatorTierService::evaluate((int) $userId);
            CreatorTierService::checkInactivity((int) $userId);
        }
        Log::info("[TierReview] Reviewed " . count($candidates) . " creators.");
    }
}
```

- [ ] Schedule daily at 03:30: `Schedule::job(new \App\Jobs\TierReviewJob())->dailyAt('03:30');`
- [ ] Commit: `feat(earnings): add TierReviewJob`

---

#### Task 45 — Background job: `PayoutDisbursementJob`

**Files:**
- Create: `app/Jobs/PayoutDisbursementJob.php`

Daily job. Aggregates cleared balances per creator from `earning_events` where `settlement_status='cleared'` and no prior disbursement. For any creator with total cleared ≥ TZS 5,000, initiates a Tajiri Pay wallet credit. Writes to `wallet_transactions` directly (same mechanism as `WalletController`).

- [ ] Create:

```php
<?php
namespace App\Jobs;

use Illuminate\Bus\Queueable;
use Illuminate\Contracts\Queue\ShouldQueue;
use Illuminate\Foundation\Bus\Dispatchable;
use Illuminate\Support\Facades\DB;
use Illuminate\Support\Facades\Log;

class PayoutDisbursementJob implements ShouldQueue
{
    use Dispatchable, Queueable;

    // §6.2 Minimum payout threshold
    const MIN_PAYOUT_TSH = 5000.0;

    public function handle(): void
    {
        // Aggregate cleared, undisbursed earnings per creator
        $creatorBalances = DB::table('earning_events')
            ->where('settlement_status', 'cleared')
            ->whereNull('disbursed_at')  // column added in Task 45b below
            ->where('is_chargeable', true)
            ->groupBy('target_user_id')
            ->selectRaw('target_user_id, SUM(net_to_creator) as total_cleared')
            ->having('total_cleared', '>=', self::MIN_PAYOUT_TSH)
            ->get();

        foreach ($creatorBalances as $row) {
            $this->disburseTo((int) $row->target_user_id, (float) $row->total_cleared);
        }

        Log::info("[PayoutDisbursement] Processed " . count($creatorBalances) . " creator payouts.");
    }

    private function disburseTo(int $userId, float $amount): void
    {
        DB::transaction(function () use ($userId, $amount) {
            // Credit the creator's Tajiri Pay wallet
            $wallet = DB::table('wallets')->where('user_id', $userId)->first();
            if (!$wallet) {
                Log::warning("[PayoutDisbursement] No wallet for user #{$userId}");
                return;
            }

            $txId = 'EARN-' . strtoupper(uniqid());
            $balanceBefore = (float) $wallet->balance;
            $balanceAfter  = $balanceBefore + $amount;

            DB::table('wallet_transactions')->insert([
                'transaction_id'  => $txId,
                'wallet_id'       => $wallet->id,
                'user_id'         => $userId,
                'type'            => 'creator_earnings',
                'amount'          => $amount,
                'fee'             => 0,
                'balance_before'  => $balanceBefore,
                'balance_after'   => $balanceAfter,
                'status'          => 'completed',
                'payment_method'  => 'wallet',
                'description'     => 'Creator earnings disbursement',
                'completed_at'    => now(),
                'created_at'      => now(),
                'updated_at'      => now(),
            ]);

            DB::table('wallets')->where('id', $wallet->id)->update([
                'balance'    => $balanceAfter,
                'updated_at' => now(),
            ]);

            // Mark the events as disbursed
            DB::table('earning_events')
                ->where('target_user_id', $userId)
                ->where('settlement_status', 'cleared')
                ->whereNull('disbursed_at')
                ->update(['disbursed_at' => now()]);

            // Dr. 2120 Cleared → Cr. wallet (no new COA account; wallet is the asset)
            DB::table('journal_lines')->insert([
                'account_code'   => '2120',
                'debit'          => $amount,
                'credit'         => 0,
                'description'    => "Disbursement to wallet — user #{$userId} tx {$txId}",
                'reference_type' => 'wallet_transaction',
                'reference_id'   => DB::getPdo()->lastInsertId(),
                'created_at'     => now(),
                'updated_at'     => now(),
            ]);
        });
    }
}
```

- [ ] Add `disbursed_at` column to `earning_events`:
  Create `database/migrations/2026_05_03_000012_add_disbursed_at_to_earning_events.php`:
  ```php
  Schema::table('earning_events', function (Blueprint $table) {
      $table->timestampTz('disbursed_at')->nullable()->after('reversed_at');
      $table->index(['target_user_id', 'settlement_status', 'disbursed_at']);
  });
  ```
- [ ] Schedule daily at 06:00: `Schedule::job(new \App\Jobs\PayoutDisbursementJob())->dailyAt('06:00');`
- [ ] Commit: `feat(earnings): add PayoutDisbursementJob + disbursed_at column`

---

#### Task 46 — Background job: `TRARemittanceJob`

**Files:**
- Create: `app/Jobs/TRARemittanceJob.php`

Monthly job that totals `tra_wht_held` across all cleared events in the prior month and logs the remittance record. Full TRA API integration is v3 scope; this job produces the remittance report and marks WHT as remitted.

- [ ] Create:

```php
<?php
namespace App\Jobs;

use Illuminate\Bus\Queueable;
use Illuminate\Contracts\Queue\ShouldQueue;
use Illuminate\Foundation\Bus\Dispatchable;
use Illuminate\Support\Facades\DB;
use Illuminate\Support\Facades\Log;
use Carbon\Carbon;

class TRARemittanceJob implements ShouldQueue
{
    use Dispatchable, Queueable;

    public function handle(): void
    {
        $lastMonth = Carbon::now()->subMonth();
        $start = $lastMonth->copy()->startOfMonth();
        $end   = $lastMonth->copy()->endOfMonth();

        $totalWht = DB::table('earning_events')
            ->where('settlement_status', 'cleared')
            ->whereBetween('cleared_at', [$start, $end])
            ->sum('tra_wht_held');

        if ((float) $totalWht <= 0) {
            Log::info('[TRARemittance] No WHT to remit for ' . $lastMonth->format('Y-m'));
            return;
        }

        // Dr. 2140 TRA WHT Payable → Cr. (TRA settlement — wire/bank transfer, manual in v1)
        DB::table('journal_lines')->insert([
            'account_code'   => '2140',
            'debit'          => $totalWht,
            'credit'         => 0,
            'description'    => 'TRA WHT Section 83B remittance — ' . $lastMonth->format('Y-m'),
            'reference_type' => 'tra_remittance',
            'reference_id'   => 0,
            'created_at'     => now(),
            'updated_at'     => now(),
        ]);

        Log::info("[TRARemittance] Remittance record created for {$lastMonth->format('Y-m')}: TZS {$totalWht}");
        // TODO v3: push to TRA digital portal API
    }
}
```

- [ ] Schedule monthly on 5th at 08:00: `Schedule::job(new \App\Jobs\TRARemittanceJob())->monthlyOn(5, '08:00');`
- [ ] Commit: `feat(earnings): add TRARemittanceJob`

---

#### Task 47 — Rewrite `GET /api/posts/{postId}/earnings`

**Files:**
- Modify: `app/Http/Controllers/Api/PostEarningsController.php` — replace `earnings()` method entirely

The old formula reads from raw `posts.*_count`. The new version reads from `earning_events` and projects forward using the current `fund_per_point` from the active period.

- [ ] Replace the method:

```php
public function earnings(int $postId): JsonResponse
{
    $post = \App\Models\Post::select(['id', 'user_id'])->find($postId);
    if (!$post) {
        return response()->json(['success' => false, 'message' => 'Post not found'], 404);
    }

    // Actuals from settled events
    $actuals = DB::table('earning_events')
        ->where('post_id', $postId)
        ->where('target_user_id', $post->user_id)
        ->where('is_chargeable', true)
        ->selectRaw("
            metric,
            SUM(CASE WHEN settlement_status IN ('cleared') THEN net_to_creator ELSE 0 END) as cleared_tsh,
            SUM(CASE WHEN settlement_status = 'pending' THEN net_to_creator ELSE 0 END) as pending_tsh,
            SUM(raw_count) as total_count
        ")
        ->groupBy('metric')
        ->get()
        ->keyBy('metric');

    // Real-time estimate from current fund period
    $period = \App\Models\CreatorsFundPeriod::currentOpen();
    $fundPerPoint = $period ? (float) $period->fund_per_point : null;

    // Pending points in current period for this post
    $postPoints = DB::table('earning_events')
        ->where('post_id', $postId)
        ->where('target_user_id', $post->user_id)
        ->where('is_chargeable', true)
        ->where('stream', 'engagement')
        ->where('settlement_status', 'pending')
        ->selectRaw("SUM(gross_credit) as total_points")
        ->value('total_points');

    $estimatedFromPool = $fundPerPoint && $postPoints
        ? round((float) $postPoints * $fundPerPoint, 2)
        : null;

    $breakdown = [];
    foreach (['view', 'reaction', 'comment', 'share', 'save', 'watch_second', 'derivative_royalty', 'follow', 'subscribe'] as $metric) {
        $row = $actuals->get($metric);
        $breakdown[$metric] = [
            'count'       => $row ? (int) $row->total_count : 0,
            'cleared_tsh' => $row ? (float) $row->cleared_tsh : 0.0,
            'pending_tsh' => $row ? (float) $row->pending_tsh : 0.0,
        ];
    }

    $totalCleared = collect($breakdown)->sum('cleared_tsh');
    $totalPending = collect($breakdown)->sum('pending_tsh');

    return response()->json([
        'success' => true,
        'data'    => [
            'post_id'               => $postId,
            'total_cleared_tsh'     => round($totalCleared, 2),
            'total_pending_tsh'     => round($totalPending, 2),
            'estimated_pool_tsh'    => $estimatedFromPool,
            'fund_per_point'        => $fundPerPoint,
            'currency'              => 'TSh',
            'settlement_note'       => 'Pending amounts settle after 30 days. Pool estimates update weekly.',
            'breakdown'             => $breakdown,
        ],
    ]);
}
```

- [ ] Verify with `curl /api/posts/1/earnings | jq .`
- [ ] Commit: `feat(earnings): rewrite GET /posts/{id}/earnings to read from earning_events`

---

#### Task 48 — New endpoint: `GET /api/posts/{postId}/earnings/events`

**Files:**
- Modify: `app/Http/Controllers/Api/PostEarningsController.php` — add `earningsEvents()` method
- Modify: `routes/api.php` — add route

- [ ] Add method to `PostEarningsController`:

```php
public function earningsEvents(int $postId): JsonResponse
{
    $post = \App\Models\Post::select(['id', 'user_id'])->find($postId);
    if (!$post) {
        return response()->json(['success' => false, 'message' => 'Post not found'], 404);
    }

    $page    = (int) request('page', 1);
    $perPage = min((int) request('per_page', 20), 100);

    $events = DB::table('earning_events')
        ->where('post_id', $postId)
        ->where('target_user_id', $post->user_id)
        ->orderByDesc('occurred_at')
        ->paginate($perPage, ['*'], 'page', $page);

    $items = collect($events->items())->map(fn($e) => [
        'event_id'         => $e->id,
        'occurred_at'      => $e->occurred_at,
        'metric'           => $e->metric,
        'actor_role'       => $e->actor_role,
        'raw_count'        => $e->raw_count,
        'rate_tsh'         => (float) $e->rate_tsh,
        'multipliers'      => json_decode($e->multipliers, true),
        'gross_credit'     => (float) $e->gross_credit,
        'platform_take'    => (float) $e->platform_take,
        'tra_wht_held'     => (float) $e->tra_wht_held,
        'net_to_creator'   => (float) $e->net_to_creator,
        'is_chargeable'    => (bool) $e->is_chargeable,
        'charge_reason'    => $e->charge_reason,
        'settlement_status'=> $e->settlement_status,
        'cleared_at'       => $e->cleared_at,
        'funding_source'   => $e->funding_source,
    ]);

    return response()->json([
        'success' => true,
        'data'    => $items,
        'meta'    => [
            'current_page' => $events->currentPage(),
            'last_page'    => $events->lastPage(),
            'per_page'     => $perPage,
            'total'        => $events->total(),
        ],
    ]);
}
```

- [ ] Add route in `routes/api.php` inside the `posts` prefix group after the existing earnings route:
  ```php
  Route::get('/{postId}/earnings/events', [PostEarningsController::class, 'earningsEvents']);
  ```
- [ ] Commit: `feat(earnings): add GET /posts/{id}/earnings/events provenance endpoint`

---

#### Task 49 — New endpoint: `GET /api/users/me/earnings`

**Files:**
- Create: `app/Http/Controllers/Api/CreatorEarningsController.php`
- Modify: `routes/api.php`

- [ ] Create controller with `dashboard()` method:

```php
<?php
namespace App\Http\Controllers\Api;

use App\Http\Controllers\Controller;
use Illuminate\Http\JsonResponse;
use Illuminate\Http\Request;
use Illuminate\Support\Facades\DB;

class CreatorEarningsController extends Controller
{
    /**
     * GET /api/users/me/earnings
     * Cross-stream earnings dashboard for the authenticated creator.
     */
    public function dashboard(Request $request): JsonResponse
    {
        $userId = (int) $request->input('user_id');

        $streams = ['engagement', 'fan_funding', 'marketplace', 'brand_deal', 'live_gifts', 'affiliate'];
        $breakdown = [];
        foreach ($streams as $stream) {
            $row = DB::table('earning_events')
                ->where('target_user_id', $userId)
                ->where('stream', $stream)
                ->where('is_chargeable', true)
                ->selectRaw("
                    SUM(CASE WHEN settlement_status = 'cleared' THEN net_to_creator ELSE 0 END) as cleared_tsh,
                    SUM(CASE WHEN settlement_status = 'pending' THEN net_to_creator ELSE 0 END) as pending_tsh,
                    COUNT(*) as event_count
                ")
                ->first();
            $breakdown[$stream] = [
                'cleared_tsh' => $row ? round((float) $row->cleared_tsh, 2) : 0.0,
                'pending_tsh' => $row ? round((float) $row->pending_tsh, 2) : 0.0,
                'event_count' => $row ? (int) $row->event_count : 0,
            ];
        }

        $totalCleared = collect($breakdown)->sum('cleared_tsh');
        $totalPending = collect($breakdown)->sum('pending_tsh');

        // Current fund period estimate
        $period = \App\Models\CreatorsFundPeriod::currentOpen();
        $fundPoint = DB::table('creators_fund_points')
            ->where('period_id', $period?->id)
            ->where('user_id', $userId)
            ->first();
        $estimatedThisPeriod = null;
        if ($period && $fundPoint && $period->fund_per_point) {
            $estimatedThisPeriod = round((float) $fundPoint->points * (float) $period->fund_per_point, 2);
        }

        $tier = \App\Models\CreatorTier::forUser($userId);

        return response()->json([
            'success' => true,
            'data'    => [
                'user_id'                => $userId,
                'total_cleared_tsh'      => round($totalCleared, 2),
                'total_pending_tsh'      => round($totalPending, 2),
                'estimated_this_period_tsh' => $estimatedThisPeriod,
                'currency'               => 'TSh',
                'tier'                   => $tier->tier,
                'is_mwanzo_active'       => $tier->mwanzo_expires_at && $tier->mwanzo_expires_at->isFuture(),
                'mwanzo_expires_at'      => $tier->mwanzo_expires_at?->toISOString(),
                'monetization_paused'    => $tier->monetization_paused,
                'breakdown_by_stream'    => $breakdown,
                'current_period'         => $period ? [
                    'period_start'   => $period->period_start,
                    'period_end'     => $period->period_end,
                    'phase'          => $period->phase,
                    'fund_size_tsh'  => (float) $period->fund_size_tsh,
                    'fund_per_point' => $period->fund_per_point ? (float) $period->fund_per_point : null,
                    'your_points'    => $fundPoint ? (float) $fundPoint->points : 0.0,
                ] : null,
            ],
        ]);
    }

    /**
     * GET /api/users/me/earnings/events
     * Paginated per-event provenance ledger for the creator.
     */
    public function events(Request $request): JsonResponse
    {
        $userId  = (int) $request->input('user_id');
        $page    = (int) $request->input('page', 1);
        $perPage = min((int) $request->input('per_page', 20), 100);
        $stream  = $request->input('stream'); // optional filter
        $status  = $request->input('status'); // 'pending'|'cleared'

        $query = DB::table('earning_events')
            ->where('target_user_id', $userId)
            ->orderByDesc('occurred_at');

        if ($stream) $query->where('stream', $stream);
        if ($status) $query->where('settlement_status', $status);

        $events = $query->paginate($perPage, ['*'], 'page', $page);

        $items = collect($events->items())->map(fn($e) => [
            'event_id'          => $e->id,
            'occurred_at'       => $e->occurred_at,
            'post_id'           => $e->post_id,
            'stream'            => $e->stream,
            'metric'            => $e->metric,
            'actor_role'        => $e->actor_role,
            'raw_count'         => $e->raw_count,
            'rate_tsh'          => (float) $e->rate_tsh,
            'multipliers'       => json_decode($e->multipliers, true),
            'gross_credit'      => (float) $e->gross_credit,
            'platform_take'     => (float) $e->platform_take,
            'tra_wht_held'      => (float) $e->tra_wht_held,
            'net_to_creator'    => (float) $e->net_to_creator,
            'is_chargeable'     => (bool) $e->is_chargeable,
            'charge_reason'     => $e->charge_reason,
            'settlement_status' => $e->settlement_status,
            'cleared_at'        => $e->cleared_at,
            'disbursed_at'      => $e->disbursed_at ?? null,
            'funding_source'    => $e->funding_source,
        ]);

        return response()->json([
            'success' => true,
            'data'    => $items,
            'meta'    => [
                'current_page' => $events->currentPage(),
                'last_page'    => $events->lastPage(),
                'per_page'     => $perPage,
                'total'        => $events->total(),
            ],
        ]);
    }

    /**
     * GET /api/creators/rate-card
     * Public rate card per §10.5.
     */
    public function rateCard(): JsonResponse
    {
        $rates = DB::table('creator_earnings_rates')
            ->where('is_active', true)
            ->where('effective_from', '<=', now())
            ->where(function ($q) { $q->whereNull('effective_until')->orWhere('effective_until', '>', now()); })
            ->orderBy('stream')->orderBy('metric')->orderBy('actor_role')
            ->get(['metric', 'actor_role', 'stream', 'rate', 'max_cap_tsh', 'effective_from']);

        $period = \App\Models\CreatorsFundPeriod::currentOpen();

        return response()->json([
            'success' => true,
            'data'    => [
                'phase'                          => $period?->phase ?? 'phase_1',
                'phase_1_committed_budget_weekly_tsh' => 50_000_000,
                'floor_tsh'                      => (float) ($period?->floor_tsh ?? 50_000_000),
                'current_fund_size_tsh'          => (float) ($period?->fund_size_tsh ?? 50_000_000),
                'current_fund_per_point'         => $period?->fund_per_point ? (float) $period->fund_per_point : null,
                'min_payout_tsh'                 => 5000,
                'wht_rate_pct'                   => 5.0,
                'rates'                          => $rates,
                'last_updated'                   => now()->toISOString(),
                'notice'                         => 'Rates only change with 30-day public notice per §11.4',
            ],
        ]);
    }
}
```

- [ ] Add routes in `routes/api.php` inside the `users` prefix group:
  ```php
  Route::get('/me/earnings', [\App\Http\Controllers\Api\CreatorEarningsController::class, 'dashboard']);
  Route::get('/me/earnings/events', [\App\Http\Controllers\Api\CreatorEarningsController::class, 'events']);
  ```
- [ ] Add public rate-card route (no auth):
  ```php
  Route::prefix('creators')->group(function () {
      Route::get('/rate-card', [\App\Http\Controllers\Api\CreatorEarningsController::class, 'rateCard']);
  });
  ```
- [ ] Commit: `feat(earnings): add CreatorEarningsController with dashboard, events, rate-card endpoints`

---

#### Task 50 — New endpoint: `GET /api/users/me/earnings/tax`

**Files:**
- Modify: `app/Http/Controllers/Api/CreatorEarningsController.php` — add `taxSummary()` method
- Modify: `routes/api.php`

- [ ] Add method:

```php
public function taxSummary(Request $request): JsonResponse
{
    $userId = (int) $request->input('user_id');
    $year   = (int) $request->input('year', now()->year);

    $monthly = DB::table('earning_events')
        ->where('target_user_id', $userId)
        ->where('is_chargeable', true)
        ->whereYear('cleared_at', $year)
        ->whereNotNull('cleared_at')
        ->selectRaw("
            TO_CHAR(cleared_at, 'YYYY-MM') as month,
            SUM(net_to_creator + tra_wht_held) as gross_tsh,
            SUM(tra_wht_held) as wht_tsh,
            SUM(net_to_creator) as net_tsh
        ")
        ->groupByRaw("TO_CHAR(cleared_at, 'YYYY-MM')")
        ->orderByRaw("TO_CHAR(cleared_at, 'YYYY-MM')")
        ->get();

    $ytdGross = $monthly->sum('gross_tsh');
    $ytdWht   = $monthly->sum('wht_tsh');
    $ytdNet   = $monthly->sum('net_tsh');

    return response()->json([
        'success' => true,
        'data' => [
            'user_id'     => $userId,
            'year'        => $year,
            'ytd_gross_tsh' => round((float) $ytdGross, 2),
            'ytd_wht_tsh'   => round((float) $ytdWht,   2),
            'ytd_net_tsh'   => round((float) $ytdNet,    2),
            'wht_rate_pct'  => 5.0,
            'monthly'       => $monthly->map(fn($r) => [
                'month'      => $r->month,
                'gross_tsh'  => round((float) $r->gross_tsh, 2),
                'wht_tsh'    => round((float) $r->wht_tsh,   2),
                'net_tsh'    => round((float) $r->net_tsh,   2),
            ]),
        ],
    ]);
}
```

- [ ] Add route: `Route::get('/me/earnings/tax', [...'taxSummary']);`
- [ ] Commit: `feat(earnings): add GET /users/me/earnings/tax endpoint`

---

#### Task 51 — New endpoint: `POST /api/users/me/earnings/disputes`

**Files:**
- Modify: `app/Http/Controllers/Api/CreatorEarningsController.php` — add `fileDispute()` method
- Create: `database/migrations/2026_05_03_000013_create_earnings_disputes_table.php`

- [ ] Create migration for disputes table:

```php
Schema::create('earnings_disputes', function (Blueprint $table) {
    $table->id();
    $table->unsignedBigInteger('user_id');
    $table->unsignedBigInteger('earning_event_id');
    $table->string('status')->default('open'); // 'open'|'resolved'|'reversed'
    $table->text('reason');
    $table->text('resolution_note')->nullable();
    $table->string('resolved_by')->nullable();
    $table->timestampTz('resolved_at')->nullable();
    $table->timestamps();
    $table->foreign('user_id')->references('id')->on('user_profiles')->onDelete('cascade');
    $table->foreign('earning_event_id')->references('id')->on('earning_events')->onDelete('cascade');
});
```

- [ ] Add `fileDispute()` to controller:

```php
public function fileDispute(Request $request): JsonResponse
{
    $validated = $request->validate([
        'user_id'          => 'required|integer',
        'earning_event_id' => 'required|integer',
        'reason'           => 'required|string|max:1000',
    ]);

    $event = DB::table('earning_events')
        ->where('id', $validated['earning_event_id'])
        ->where('target_user_id', $validated['user_id'])
        ->first();

    if (!$event) {
        return response()->json(['success' => false, 'message' => 'Event not found'], 404);
    }

    $dispute = DB::table('earnings_disputes')->insertGetId([
        'user_id'          => $validated['user_id'],
        'earning_event_id' => $validated['earning_event_id'],
        'status'           => 'open',
        'reason'           => $validated['reason'],
        'created_at'       => now(),
        'updated_at'       => now(),
    ]);

    return response()->json(['success' => true, 'data' => ['dispute_id' => $dispute]], 201);
}
```

- [ ] Add route: `Route::post('/me/earnings/disputes', [...'fileDispute']);`
- [ ] Commit: `feat(earnings): add earnings dispute filing endpoint`

---

#### Task 52 — New endpoint: `POST /api/posts/{id}/discovery-mode`

**Files:**
- Modify: `app/Http/Controllers/Api/PostEarningsController.php` — add `enableDiscoveryMode()` method
- Modify: `routes/api.php`

- [ ] Add method:

```php
public function enableDiscoveryMode(int $postId, \Illuminate\Http\Request $request): JsonResponse
{
    $userId = (int) $request->input('user_id');
    $post   = \App\Models\Post::find($postId);

    if (!$post || (int) $post->user_id !== $userId) {
        return response()->json(['success' => false, 'message' => 'Not found or not owner'], 403);
    }
    $tier = \App\Models\CreatorTier::forUser($userId);
    if (!$tier->isAtLeast('standard')) {
        return response()->json(['success' => false, 'message' => 'Discovery Mode requires Standard tier or above'], 403);
    }
    $post->update([
        'is_discovery_mode'    => true,
        'discovery_mode_until' => now()->addDays(30),
    ]);

    return response()->json(['success' => true, 'data' => ['discovery_mode_until' => $post->discovery_mode_until]]);
}
```

- [ ] Add route inside `posts` prefix: `Route::post('/{id}/discovery-mode', [PostEarningsController::class, 'enableDiscoveryMode']);`
- [ ] Commit: `feat(earnings): add POST /posts/{id}/discovery-mode endpoint`

---

#### Task 53 — PayoutService wrapper

**Files:**
- Create: `app/Services/PayoutService.php`

Thin wrapper used by `PayoutDisbursementJob`. Abstracts wallet credit so the disbursement job can be unit-tested without touching wallet tables directly.

- [ ] Create:

```php
<?php
namespace App\Services;

use Illuminate\Support\Facades\DB;
use Illuminate\Support\Facades\Log;

class PayoutService
{
    /**
     * Credit creator's Tajiri Pay wallet with the given TZS amount.
     * Returns the wallet_transaction id, or null on failure.
     */
    public static function creditWallet(int $userId, float $amount, string $description = 'Creator earnings'): ?int
    {
        return DB::transaction(function () use ($userId, $amount, $description) {
            $wallet = DB::table('wallets')->where('user_id', $userId)->lockForUpdate()->first();
            if (!$wallet || !$wallet->is_active) {
                Log::warning("[PayoutService] No active wallet for user #{$userId}");
                return null;
            }
            $txId = 'EARN-' . strtoupper(uniqid('', true));
            $before = (float) $wallet->balance;
            $after  = $before + $amount;

            $txRowId = DB::table('wallet_transactions')->insertGetId([
                'transaction_id' => $txId,
                'wallet_id'      => $wallet->id,
                'user_id'        => $userId,
                'type'           => 'creator_earnings',
                'amount'         => $amount,
                'fee'            => 0,
                'balance_before' => $before,
                'balance_after'  => $after,
                'status'         => 'completed',
                'payment_method' => 'wallet',
                'description'    => $description,
                'completed_at'   => now(),
                'created_at'     => now(),
                'updated_at'     => now(),
            ]);

            DB::table('wallets')->where('id', $wallet->id)->update([
                'balance'    => $after,
                'updated_at' => now(),
            ]);

            return $txRowId;
        });
    }
}
```

- [ ] Update `PayoutDisbursementJob::disburseTo()` to call `PayoutService::creditWallet()` instead of writing wallet rows inline.
- [ ] Commit: `feat(earnings): add PayoutService wallet credit wrapper`

---

#### Tasks 54–56 — Mobile money payout, minimum threshold, fee-free rule

These are policy wires on top of `PayoutService`.

**Task 54 — Mobile money auto-disbursement**

- [ ] In `PayoutDisbursementJob`, after `PayoutService::creditWallet()` succeeds, check if the creator has a `primary` mobile money account in `mobile_money_accounts` and queue a mobile money push via the existing wallet withdrawal flow (`WalletController::withdraw` pattern). For v1 the wallet credit is the end state; the Tajiri Pay → mobile money network bridge is a separate infrastructure concern (use existing `WalletController` withdrawal path). Document this boundary in `docs/superpowers/plans/2026-05-03-creators-fund-engine.md`.

**Task 55 — Fee-free threshold enforcement**

- [ ] Add to `PayoutService::creditWallet()` a check: if `$amount <= 50000` (TZS 50k, §6.3), set fee = 0 in the `wallet_transactions` row. Above 50k, apply provider rate. For v1 both paths write fee = 0 since the fee is charged at mobile-money withdrawal, not at the wallet-credit step.

**Task 56 — Payout preference setting**

- [ ] Add `payout_preference` column to `creator_tiers` table:
  ```php
  // migration 2026_05_03_000014
  Schema::table('creator_tiers', function (Blueprint $table) {
      $table->string('payout_preference')->default('auto_daily'); // 'auto_daily'|'weekly_batch'
  });
  ```
- [ ] In `PayoutDisbursementJob`, skip weekly-batch creators during the daily run; add a separate weekly pass for them.
- [ ] Commit: `feat(earnings): payout preference + fee-free threshold`

---

#### Tasks 57–59 — TRA WHT compliance wires

**Task 57 — WHT rate stored in config**

- [ ] Add to `config/earnings.php` (create if absent):

```php
<?php
return [
    'wht_rate'               => 0.05,   // §7.1 Section 83B 5%
    'min_payout_tsh'         => 5000,
    'daily_soft_cap_tsh'     => 500_000,
    'phase_1_weekly_fund_tsh'=> 50_000_000,
    'settlement_window_days' => 30,
    'fan_funding_window_days'=> 45,
];
```

- [ ] Update `SettlementSweepJob` and `EarningsEngine` to read from `config('earnings.wht_rate')` instead of hardcoded `0.05`.

**Task 58 — WHT auto-deduction at sweep**

Already implemented in `SettlementSweepJob` (Task 42). Confirm the deduction applies only to TZ residents. Add a `tax_residency` column to `user_profiles` (default `'TZ'`) and skip WHT for non-TZ creators:

- [ ] Create migration:
  ```php
  Schema::table('user_profiles', function (Blueprint $table) {
      $table->string('tax_residency')->default('TZ')->after('is_id_verified');
  });
  ```
- [ ] Update `SettlementSweepJob`: `$whtAmount = $event->tax_residency === 'TZ' ? round($netAmount * config('earnings.wht_rate'), 2) : 0.0;` (join `user_profiles` on `target_user_id`).

**Task 59 — Digital tax invoice stub**

- [ ] Add `TaxInvoiceService::generate(int $userId, int $month, int $year): string` that queries cleared events for the month, totals gross/WHT/net, and returns a JSON payload suitable for PDF rendering. Full TRA-format PDF generation is v3; the JSON stub satisfies the data contract.
- [ ] Commit: `feat(earnings): WHT config, tax residency column, tax invoice stub`

---

### Frontend Implementation (Tasks 60–76)

---

#### Task 60 — Flutter model: `creator_earnings_models.dart`

**Files:**
- Create: `/Volumes/DATA/PROJECTS/TAJIRI/TAJIRI-FRONTEND/lib/models/creator_earnings_models.dart`

- [ ] Create with all required models. Follow project convention: `factory Model.fromJson()` with `_parseInt`, `_parseDouble`, `_parseBool` helpers, `_buildStorageUrl` pattern not needed here.

```dart
// lib/models/creator_earnings_models.dart

int _parseInt(dynamic v) {
  if (v == null) return 0;
  if (v is int) return v;
  if (v is String) return int.tryParse(v) ?? 0;
  return 0;
}

double _parseDouble(dynamic v, [double d = 0.0]) {
  if (v == null) return d;
  if (v is double) return v;
  if (v is int) return v.toDouble();
  if (v is String) return double.tryParse(v) ?? d;
  return d;
}

bool _parseBool(dynamic v, [bool d = false]) {
  if (v == null) return d;
  if (v is bool) return v;
  if (v is int) return v != 0;
  if (v is String) return v == 'true' || v == '1';
  return d;
}

class StreamBreakdown {
  final double clearedTsh;
  final double pendingTsh;
  final int eventCount;

  const StreamBreakdown({
    required this.clearedTsh,
    required this.pendingTsh,
    required this.eventCount,
  });

  factory StreamBreakdown.fromJson(Map<String, dynamic> j) => StreamBreakdown(
    clearedTsh: _parseDouble(j['cleared_tsh']),
    pendingTsh: _parseDouble(j['pending_tsh']),
    eventCount: _parseInt(j['event_count']),
  );
}

class FundPeriodSummary {
  final String periodStart;
  final String periodEnd;
  final String phase;
  final double fundSizeTsh;
  final double? fundPerPoint;
  final double yourPoints;

  const FundPeriodSummary({
    required this.periodStart,
    required this.periodEnd,
    required this.phase,
    required this.fundSizeTsh,
    this.fundPerPoint,
    required this.yourPoints,
  });

  factory FundPeriodSummary.fromJson(Map<String, dynamic> j) => FundPeriodSummary(
    periodStart: j['period_start'] as String? ?? '',
    periodEnd:   j['period_end']   as String? ?? '',
    phase:       j['phase']        as String? ?? 'phase_1',
    fundSizeTsh: _parseDouble(j['fund_size_tsh']),
    fundPerPoint: j['fund_per_point'] != null ? _parseDouble(j['fund_per_point']) : null,
    yourPoints:  _parseDouble(j['your_points']),
  );
}

class CreatorEarningsDashboard {
  final int userId;
  final double totalClearedTsh;
  final double totalPendingTsh;
  final double? estimatedThisPeriodTsh;
  final String currency;
  final String tier;
  final bool isMwanzoActive;
  final String? mwanzoExpiresAt;
  final bool monetizationPaused;
  final Map<String, StreamBreakdown> breakdownByStream;
  final FundPeriodSummary? currentPeriod;

  const CreatorEarningsDashboard({
    required this.userId,
    required this.totalClearedTsh,
    required this.totalPendingTsh,
    this.estimatedThisPeriodTsh,
    required this.currency,
    required this.tier,
    required this.isMwanzoActive,
    this.mwanzoExpiresAt,
    required this.monetizationPaused,
    required this.breakdownByStream,
    this.currentPeriod,
  });

  factory CreatorEarningsDashboard.fromJson(Map<String, dynamic> j) {
    final rawBreakdown = j['breakdown_by_stream'] as Map<String, dynamic>? ?? {};
    final breakdown = rawBreakdown.map(
      (k, v) => MapEntry(k, StreamBreakdown.fromJson(v as Map<String, dynamic>)),
    );
    return CreatorEarningsDashboard(
      userId:                   _parseInt(j['user_id']),
      totalClearedTsh:          _parseDouble(j['total_cleared_tsh']),
      totalPendingTsh:          _parseDouble(j['total_pending_tsh']),
      estimatedThisPeriodTsh:   j['estimated_this_period_tsh'] != null ? _parseDouble(j['estimated_this_period_tsh']) : null,
      currency:                 j['currency'] as String? ?? 'TSh',
      tier:                     j['tier']     as String? ?? 'mwanzo',
      isMwanzoActive:           _parseBool(j['is_mwanzo_active']),
      mwanzoExpiresAt:          j['mwanzo_expires_at'] as String?,
      monetizationPaused:       _parseBool(j['monetization_paused']),
      breakdownByStream:        breakdown,
      currentPeriod:            j['current_period'] != null
          ? FundPeriodSummary.fromJson(j['current_period'] as Map<String, dynamic>)
          : null,
    );
  }
}

class EarningEventItem {
  final int eventId;
  final String occurredAt;
  final int? postId;
  final String stream;
  final String metric;
  final String actorRole;
  final int rawCount;
  final double rateTsh;
  final Map<String, dynamic> multipliers;
  final double grossCredit;
  final double platformTake;
  final double traWhtHeld;
  final double netToCreator;
  final bool isChargeable;
  final String? chargeReason;
  final String settlementStatus;
  final String? clearedAt;
  final String? disbursedAt;
  final String? fundingSource;

  const EarningEventItem({
    required this.eventId,
    required this.occurredAt,
    this.postId,
    required this.stream,
    required this.metric,
    required this.actorRole,
    required this.rawCount,
    required this.rateTsh,
    required this.multipliers,
    required this.grossCredit,
    required this.platformTake,
    required this.traWhtHeld,
    required this.netToCreator,
    required this.isChargeable,
    this.chargeReason,
    required this.settlementStatus,
    this.clearedAt,
    this.disbursedAt,
    this.fundingSource,
  });

  factory EarningEventItem.fromJson(Map<String, dynamic> j) => EarningEventItem(
    eventId:          _parseInt(j['event_id']),
    occurredAt:       j['occurred_at'] as String? ?? '',
    postId:           j['post_id'] != null ? _parseInt(j['post_id']) : null,
    stream:           j['stream']     as String? ?? 'engagement',
    metric:           j['metric']     as String? ?? '',
    actorRole:        j['actor_role'] as String? ?? 'author',
    rawCount:         _parseInt(j['raw_count']),
    rateTsh:          _parseDouble(j['rate_tsh']),
    multipliers:      (j['multipliers'] as Map<String, dynamic>?) ?? {},
    grossCredit:      _parseDouble(j['gross_credit']),
    platformTake:     _parseDouble(j['platform_take']),
    traWhtHeld:       _parseDouble(j['tra_wht_held']),
    netToCreator:     _parseDouble(j['net_to_creator']),
    isChargeable:     _parseBool(j['is_chargeable'], true),
    chargeReason:     j['charge_reason'] as String?,
    settlementStatus: j['settlement_status'] as String? ?? 'pending',
    clearedAt:        j['cleared_at']   as String?,
    disbursedAt:      j['disbursed_at'] as String?,
    fundingSource:    j['funding_source'] as String?,
  );

  /// Human-readable multiplier summary, e.g. "1.0× base × 2.0× watch × 1.1× streak"
  String multiplierSummary() {
    final parts = <String>[];
    final wc = multipliers['watch_completion'];
    if (wc != null && wc != 1.0) parts.add('${wc}× watch');
    final mb = multipliers['mwanzo_boost'];
    if (mb != null && mb != 1.0) parts.add('${mb}× Mwanzo');
    final sk = multipliers['streak'];
    if (sk != null && sk != 1.0) parts.add('${sk}× streak');
    final dm = multipliers['discovery_mode'];
    if (dm != null && dm != 1.0) parts.add('${dm}× discovery');
    return parts.isEmpty ? 'no multipliers' : parts.join(' × ');
  }
}

class PostEarningsV2 {
  final int postId;
  final double totalClearedTsh;
  final double totalPendingTsh;
  final double? estimatedPoolTsh;
  final double? fundPerPoint;
  final String currency;
  final String settlementNote;
  final Map<String, PostMetricBreakdown> breakdown;

  const PostEarningsV2({
    required this.postId,
    required this.totalClearedTsh,
    required this.totalPendingTsh,
    this.estimatedPoolTsh,
    this.fundPerPoint,
    required this.currency,
    required this.settlementNote,
    required this.breakdown,
  });

  double get totalTsh => totalClearedTsh + totalPendingTsh;

  factory PostEarningsV2.fromJson(Map<String, dynamic> j) {
    final rawBreakdown = j['breakdown'] as Map<String, dynamic>? ?? {};
    final breakdown = rawBreakdown.map(
      (k, v) => MapEntry(k, PostMetricBreakdown.fromJson(v as Map<String, dynamic>)),
    );
    return PostEarningsV2(
      postId:           _parseInt(j['post_id']),
      totalClearedTsh:  _parseDouble(j['total_cleared_tsh']),
      totalPendingTsh:  _parseDouble(j['total_pending_tsh']),
      estimatedPoolTsh: j['estimated_pool_tsh'] != null ? _parseDouble(j['estimated_pool_tsh']) : null,
      fundPerPoint:     j['fund_per_point'] != null ? _parseDouble(j['fund_per_point']) : null,
      currency:         j['currency'] as String? ?? 'TSh',
      settlementNote:   j['settlement_note'] as String? ?? '',
      breakdown:        breakdown,
    );
  }
}

class PostMetricBreakdown {
  final int count;
  final double clearedTsh;
  final double pendingTsh;

  const PostMetricBreakdown({
    required this.count,
    required this.clearedTsh,
    required this.pendingTsh,
  });

  double get totalTsh => clearedTsh + pendingTsh;

  factory PostMetricBreakdown.fromJson(Map<String, dynamic> j) => PostMetricBreakdown(
    count:      _parseInt(j['count']),
    clearedTsh: _parseDouble(j['cleared_tsh']),
    pendingTsh: _parseDouble(j['pending_tsh']),
  );
}
```

- [ ] Run `flutter analyze` — zero new errors.
- [ ] Commit: `feat(earnings): add creator_earnings_models.dart`

---

#### Task 61 — Flutter service: `creator_earnings_service.dart`

**Files:**
- Create: `/Volumes/DATA/PROJECTS/TAJIRI/TAJIRI-FRONTEND/lib/services/creator_earnings_service.dart`

Per project conventions: instance-based class, methods take auth token or userId as parameters, uses `http` package, `ApiConfig.baseUrl`, no Provider/Bloc.

- [ ] Create:

```dart
// lib/services/creator_earnings_service.dart
import 'dart:convert';
import 'package:flutter/foundation.dart';
import 'package:http/http.dart' as http;
import '../config/api_config.dart';
import '../models/creator_earnings_models.dart';

class CreatorEarningsService {
  String get _base => ApiConfig.baseUrl;

  Future<CreatorEarningsDashboard> getDashboard({
    required int userId,
    required String token,
  }) async {
    final uri = Uri.parse('$_base/users/me/earnings?user_id=$userId');
    final resp = await http.get(uri, headers: ApiConfig.authHeaders(token));
    final body = jsonDecode(resp.body) as Map<String, dynamic>;
    if (resp.statusCode == 200 && body['success'] == true) {
      return CreatorEarningsDashboard.fromJson(body['data'] as Map<String, dynamic>);
    }
    throw Exception(body['message'] ?? 'Failed to load earnings dashboard');
  }

  Future<(List<EarningEventItem>, int lastPage)> getEvents({
    required int userId,
    required String token,
    int page = 1,
    int perPage = 20,
    String? stream,
    String? status,
  }) async {
    final params = <String, String>{
      'user_id': '$userId',
      'page': '$page',
      'per_page': '$perPage',
      if (stream != null) 'stream': stream,
      if (status != null) 'status': status,
    };
    final uri = Uri.parse('$_base/users/me/earnings/events').replace(queryParameters: params);
    final resp = await http.get(uri, headers: ApiConfig.authHeaders(token));
    final body = jsonDecode(resp.body) as Map<String, dynamic>;
    if (resp.statusCode == 200 && body['success'] == true) {
      final items = (body['data'] as List)
          .map((e) => EarningEventItem.fromJson(e as Map<String, dynamic>))
          .toList();
      final lastPage = (body['meta']?['last_page'] as int?) ?? 1;
      return (items, lastPage);
    }
    throw Exception(body['message'] ?? 'Failed to load events');
  }

  Future<PostEarningsV2> getPostEarnings(int postId, {String? token}) async {
    final uri = Uri.parse('$_base/posts/$postId/earnings');
    final headers = token != null ? ApiConfig.authHeaders(token) : <String, String>{};
    final resp = await http.get(uri, headers: headers);
    final body = jsonDecode(resp.body) as Map<String, dynamic>;
    if (resp.statusCode == 200 && body['success'] == true) {
      return PostEarningsV2.fromJson(body['data'] as Map<String, dynamic>);
    }
    throw Exception(body['message'] ?? 'Failed to load post earnings');
  }

  Future<(List<EarningEventItem>, int lastPage)> getPostEarningEvents({
    required int postId,
    required String token,
    int page = 1,
    int perPage = 20,
  }) async {
    final uri = Uri.parse('$_base/posts/$postId/earnings/events?page=$page&per_page=$perPage');
    final resp = await http.get(uri, headers: ApiConfig.authHeaders(token));
    final body = jsonDecode(resp.body) as Map<String, dynamic>;
    if (resp.statusCode == 200 && body['success'] == true) {
      final items = (body['data'] as List)
          .map((e) => EarningEventItem.fromJson(e as Map<String, dynamic>))
          .toList();
      final lastPage = (body['meta']?['last_page'] as int?) ?? 1;
      return (items, lastPage);
    }
    throw Exception(body['message'] ?? 'Failed to load post earning events');
  }

  Future<Map<String, dynamic>> getRateCard() async {
    final uri = Uri.parse('$_base/creators/rate-card');
    final resp = await http.get(uri);
    final body = jsonDecode(resp.body) as Map<String, dynamic>;
    if (resp.statusCode == 200 && body['success'] == true) {
      return body['data'] as Map<String, dynamic>;
    }
    throw Exception('Failed to load rate card');
  }

  Future<void> enableDiscoveryMode({
    required int postId,
    required int userId,
    required String token,
  }) async {
    final uri = Uri.parse('$_base/posts/$postId/discovery-mode');
    final resp = await http.post(
      uri,
      headers: ApiConfig.authHeaders(token),
      body: jsonEncode({'user_id': userId}),
    );
    final body = jsonDecode(resp.body) as Map<String, dynamic>;
    if (resp.statusCode != 200 || body['success'] != true) {
      throw Exception(body['message'] ?? 'Failed to enable Discovery Mode');
    }
  }

  Future<int> fileDispute({
    required int userId,
    required int earningEventId,
    required String reason,
    required String token,
  }) async {
    final uri = Uri.parse('$_base/users/me/earnings/disputes');
    final resp = await http.post(
      uri,
      headers: ApiConfig.authHeaders(token),
      body: jsonEncode({'user_id': userId, 'earning_event_id': earningEventId, 'reason': reason}),
    );
    final body = jsonDecode(resp.body) as Map<String, dynamic>;
    if (resp.statusCode == 201 && body['success'] == true) {
      return (body['data']?['dispute_id'] as int?) ?? 0;
    }
    throw Exception(body['message'] ?? 'Failed to file dispute');
  }
}
```

- [ ] Run `flutter analyze` — zero new errors.
- [ ] Commit: `feat(earnings): add CreatorEarningsService`

---

#### Task 62 — Add `CreatorEarningsService` cache layer (SWR pattern)

**Files:**
- Modify: `/Volumes/DATA/PROJECTS/TAJIRI/TAJIRI-FRONTEND/lib/services/creator_earnings_service.dart`

Per `ENGINEERING_PLAYBOOK.md` §"Local-first list pages — layered cache & SWR": serve stale data immediately from Hive, then fetch fresh in background and rebuild.

- [ ] Add Hive caching to `getDashboard` and `getPostEarnings`:

```dart
// Add to imports
import 'package:hive/hive.dart';

// Add inside CreatorEarningsService:

static const _boxName = 'creator_earnings_cache';

Future<Box> _box() => Hive.openBox(_boxName);

Future<CreatorEarningsDashboard?> getCachedDashboard(int userId) async {
  final box = await _box();
  final raw = box.get('dashboard_$userId');
  if (raw == null) return null;
  try {
    return CreatorEarningsDashboard.fromJson(
        jsonDecode(raw as String) as Map<String, dynamic>);
  } catch (_) { return null; }
}

Future<void> _cacheDashboard(int userId, CreatorEarningsDashboard d) async {
  final box = await _box();
  await box.put('dashboard_$userId', jsonEncode({
    'user_id': d.userId,
    'total_cleared_tsh': d.totalClearedTsh,
    'total_pending_tsh': d.totalPendingTsh,
    'estimated_this_period_tsh': d.estimatedThisPeriodTsh,
    'currency': d.currency,
    'tier': d.tier,
    'is_mwanzo_active': d.isMwanzoActive,
    'mwanzo_expires_at': d.mwanzoExpiresAt,
    'monetization_paused': d.monetizationPaused,
    'breakdown_by_stream': d.breakdownByStream.map((k, v) => MapEntry(k, {
      'cleared_tsh': v.clearedTsh,
      'pending_tsh': v.pendingTsh,
      'event_count': v.eventCount,
    })),
    'current_period': d.currentPeriod == null ? null : {
      'period_start': d.currentPeriod!.periodStart,
      'period_end': d.currentPeriod!.periodEnd,
      'phase': d.currentPeriod!.phase,
      'fund_size_tsh': d.currentPeriod!.fundSizeTsh,
      'fund_per_point': d.currentPeriod!.fundPerPoint,
      'your_points': d.currentPeriod!.yourPoints,
    },
  }));
}
```

- [ ] Commit: `feat(earnings): add Hive SWR cache to CreatorEarningsService`

---

#### Task 63 — Add routes for new earnings screens in `main.dart`

**Files:**
- Modify: `/Volumes/DATA/PROJECTS/TAJIRI/TAJIRI-FRONTEND/lib/main.dart`

- [ ] Add route cases inside `onGenerateRoute`:

```dart
case '/creator-earnings':
  final args = settings.arguments as Map<String, dynamic>?;
  return MaterialPageRoute(
    builder: (_) => FutureBuilder<int>(
      future: LocalStorageService.getInstance().getUserId(),
      builder: (ctx, snap) {
        if (!snap.hasData) return const Scaffold(body: Center(child: CircularProgressIndicator(strokeWidth: 2)));
        return CreatorEarningsDashboardScreen(currentUserId: snap.data!);
      },
    ),
  );

case '/post-earnings-v2':
  final args = settings.arguments as Map<String, dynamic>;
  final postId = args['postId'] as int;
  return MaterialPageRoute(
    builder: (_) => FutureBuilder<int>(
      future: LocalStorageService.getInstance().getUserId(),
      builder: (ctx, snap) {
        if (!snap.hasData) return const Scaffold(body: Center(child: CircularProgressIndicator(strokeWidth: 2)));
        return PostEarningsScreen(postId: postId, currentUserId: snap.data!);
      },
    ),
  );

case '/earnings-provenance':
  final args = settings.arguments as Map<String, dynamic>;
  return MaterialPageRoute(
    builder: (_) => FutureBuilder<int>(
      future: LocalStorageService.getInstance().getUserId(),
      builder: (ctx, snap) {
        if (!snap.hasData) return const Scaffold(body: Center(child: CircularProgressIndicator(strokeWidth: 2)));
        return EarningsProvenanceScreen(
          currentUserId: snap.data!,
          postId: args['postId'] as int?,
          stream: args['stream'] as String?,
        );
      },
    ),
  );

case '/creator-tier':
  return MaterialPageRoute(
    builder: (_) => FutureBuilder<int>(
      future: LocalStorageService.getInstance().getUserId(),
      builder: (ctx, snap) {
        if (!snap.hasData) return const Scaffold(body: Center(child: CircularProgressIndicator(strokeWidth: 2)));
        return CreatorTierScreen(currentUserId: snap.data!);
      },
    ),
  );
```

- [ ] Add imports for the four new screens at the top of `main.dart`.
- [ ] Commit: `feat(earnings): add earnings routes to main.dart`

---

#### Task 64 — Frontend screen: `CreatorEarningsDashboardScreen`

**Files:**
- Create: `/Volumes/DATA/PROJECTS/TAJIRI/TAJIRI-FRONTEND/lib/screens/profile/creator_earnings_dashboard_screen.dart`

Monochrome design per DESIGN.md. Dark hero card for total cleared, SWR load pattern.

- [ ] Create the screen with these sections:
  1. Dark hero card: Total Cleared + Total Pending side by side. Estimated this period below (labeled as estimate, per strategy §1.2).
  2. Current fund period pill: "Week of [date] · Fund TZS 50M · Your points: X · Est. TZS Y".
  3. Tier badge row: tier chip + Mwanzo countdown if active.
  4. Stream breakdown list: 6 rows (engagement, fan_funding, marketplace, brand_deal, live_gifts, affiliate) each with cleared + pending amounts.
  5. "View all events" button → `/earnings-provenance`.
  6. "Your tier" button → `/creator-tier`.

Key state fields:

```dart
class _CreatorEarningsDashboardScreenState extends State<CreatorEarningsDashboardScreen> {
  final _service = CreatorEarningsService();
  CreatorEarningsDashboard? _dashboard;
  bool _loading = true;
  String? _error;
  String? _token;
}
```

- [ ] `initState` loads token from `LocalStorageService`, calls `_service.getCachedDashboard(userId)` first (show stale immediately), then fires `_service.getDashboard(...)` in background and calls `setState` on result.
- [ ] Pull-to-refresh calls `getDashboard` fresh.
- [ ] All text uses `isSw ? 'Swahili' : 'English'` pattern; no hardcoded Swahili.
- [ ] `maxLines` + `TextOverflow.ellipsis` on all dynamic text.
- [ ] `dispose()` cancels nothing (no streams/controllers).
- [ ] Run `flutter analyze` — zero new errors.
- [ ] Commit: `feat(earnings): add CreatorEarningsDashboardScreen`

---

#### Task 65 — Stream breakdown row widget

**Files:**
- Create: `/Volumes/DATA/PROJECTS/TAJIRI/TAJIRI-FRONTEND/lib/screens/profile/creator_earnings_dashboard_screen.dart` (within same file as private widget)

- [ ] Add private `_StreamBreakdownRow` widget inside the dashboard screen file:

```dart
class _StreamBreakdownRow extends StatelessWidget {
  final String streamKey;       // 'engagement'|'fan_funding'|etc.
  final StreamBreakdown data;
  final bool isSw;
  final VoidCallback? onTap;

  const _StreamBreakdownRow({
    required this.streamKey,
    required this.data,
    required this.isSw,
    this.onTap,
  });

  static const _labels = {
    'engagement':  ('Engagement Pool',    'Mfuko wa Ushiriki'),
    'fan_funding': ('Fan Funding',        'Msaada wa Mashabiki'),
    'marketplace': ('Marketplace',        'Soko'),
    'brand_deal':  ('Brand Deals',        'Mikataba ya Brand'),
    'live_gifts':  ('Live Gifts',         'Zawadi za Moja kwa Moja'),
    'affiliate':   ('Affiliate',          'Mshauri'),
  };

  static const _icons = {
    'engagement':  Icons.bolt_rounded,
    'fan_funding': Icons.favorite_rounded,
    'marketplace': Icons.storefront_rounded,
    'brand_deal':  Icons.handshake_rounded,
    'live_gifts':  Icons.card_giftcard_rounded,
    'affiliate':   Icons.share_rounded,
  };

  @override
  Widget build(BuildContext context) {
    final label = _labels[streamKey];
    final name = isSw ? (label?.$2 ?? streamKey) : (label?.$1 ?? streamKey);
    final icon = _icons[streamKey] ?? Icons.attach_money_rounded;
    final cleared = data.clearedTsh;
    final pending = data.pendingTsh;

    return InkWell(
      onTap: onTap,
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
        child: Row(
          children: [
            Container(
              width: 40, height: 40,
              decoration: BoxDecoration(
                color: const Color(0xFFF5F5F5),
                borderRadius: BorderRadius.circular(10),
              ),
              child: Icon(icon, size: 20, color: const Color(0xFF1A1A1A)),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(name, style: const TextStyle(fontSize: 14, fontWeight: FontWeight.w600, color: Color(0xFF1A1A1A)), maxLines: 1, overflow: TextOverflow.ellipsis),
                  const SizedBox(height: 2),
                  Text(
                    isSw ? '${_fmt(pending)} inangoja · ${_fmt(cleared)} imeisha' : '${_fmt(pending)} pending · ${_fmt(cleared)} cleared',
                    style: const TextStyle(fontSize: 12, color: Color(0xFF666666)),
                    maxLines: 1, overflow: TextOverflow.ellipsis,
                  ),
                ],
              ),
            ),
            Text(_fmt(cleared + pending),
              style: const TextStyle(fontSize: 14, fontWeight: FontWeight.w700, color: Color(0xFF1A1A1A)),
            ),
          ],
        ),
      ),
    );
  }

  String _fmt(double v) {
    if (v >= 1000000) return '${(v / 1000000).toStringAsFixed(1)}M';
    if (v >= 1000) return '${(v / 1000).toStringAsFixed(0)}K';
    return v.toStringAsFixed(0);
  }
}
```

- [ ] Commit included in Task 64 commit.

---

#### Task 66 — Tier badge widget

**Files:**
- Create private `_TierBadge` widget in `creator_earnings_dashboard_screen.dart`

- [ ] Add:

```dart
class _TierBadge extends StatelessWidget {
  final String tier;
  final bool isMwanzoActive;
  final String? mwanzoExpiresAt;
  final bool isSw;

  const _TierBadge({
    required this.tier,
    required this.isMwanzoActive,
    this.mwanzoExpiresAt,
    required this.isSw,
  });

  @override
  Widget build(BuildContext context) {
    final tierLabel = {
      'mwanzo':   isSw ? 'Mwanzo'   : 'Starter',
      'standard': isSw ? 'Kawaida'  : 'Standard',
      'verified': isSw ? 'Iliyothibitishwa' : 'Verified',
      'partner':  isSw ? 'Mshirika' : 'Partner',
    }[tier] ?? tier;

    return Row(
      children: [
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
          decoration: BoxDecoration(
            color: const Color(0xFF1A1A1A),
            borderRadius: BorderRadius.circular(20),
          ),
          child: Text(tierLabel, style: const TextStyle(color: Colors.white, fontSize: 12, fontWeight: FontWeight.w600)),
        ),
        if (isMwanzoActive && mwanzoExpiresAt != null) ...[
          const SizedBox(width: 8),
          Text(
            isSw ? '2× Nguvu · Inaisha hivi karibuni' : '2× Boost active',
            style: const TextStyle(fontSize: 12, color: Color(0xFF666666)),
            maxLines: 1, overflow: TextOverflow.ellipsis,
          ),
        ],
      ],
    );
  }
}
```

- [ ] Commit included in Task 64.

---

#### Task 67 — Fund period info card widget

**Files:**
- Private `_FundPeriodCard` in `creator_earnings_dashboard_screen.dart`

- [ ] Add:

```dart
class _FundPeriodCard extends StatelessWidget {
  final FundPeriodSummary period;
  final bool isSw;

  const _FundPeriodCard({required this.period, required this.isSw});

  @override
  Widget build(BuildContext context) {
    final fundStr = period.fundSizeTsh >= 1000000
        ? 'TZS ${(period.fundSizeTsh / 1000000).toStringAsFixed(0)}M'
        : 'TZS ${period.fundSizeTsh.toStringAsFixed(0)}';

    final estimatedStr = period.fundPerPoint != null
        ? 'TZS ${(period.yourPoints * period.fundPerPoint!).toStringAsFixed(0)}'
        : '—';

    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(14),
        boxShadow: [BoxShadow(color: Colors.black.withValues(alpha: 0.04), blurRadius: 10, offset: const Offset(0, 2))],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(isSw ? 'Kipindi hiki cha mfuko' : 'This fund period',
            style: const TextStyle(fontSize: 12, fontWeight: FontWeight.w600, color: Color(0xFF999999), letterSpacing: 0.4)),
          const SizedBox(height: 8),
          Row(
            children: [
              Expanded(child: _InfoPill(label: isSw ? 'Mfuko' : 'Fund', value: fundStr)),
              const SizedBox(width: 8),
              Expanded(child: _InfoPill(label: isSw ? 'Pointi zako' : 'Your points', value: period.yourPoints.toStringAsFixed(1))),
              const SizedBox(width: 8),
              Expanded(child: _InfoPill(label: isSw ? 'Kadiriwa' : 'Estimated', value: estimatedStr)),
            ],
          ),
          const SizedBox(height: 8),
          Text(
            isSw
              ? 'Makadirio yanasettlika Jumatatu usiku wa manane.'
              : 'Estimates settle Monday at midnight.',
            style: const TextStyle(fontSize: 11, color: Color(0xFF999999), fontStyle: FontStyle.italic),
            maxLines: 2, overflow: TextOverflow.ellipsis,
          ),
        ],
      ),
    );
  }
}

class _InfoPill extends StatelessWidget {
  final String label;
  final String value;
  const _InfoPill({required this.label, required this.value});

  @override
  Widget build(BuildContext context) => Container(
    padding: const EdgeInsets.symmetric(vertical: 8, horizontal: 10),
    decoration: BoxDecoration(color: const Color(0xFFF5F5F5), borderRadius: BorderRadius.circular(10)),
    child: Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(label, style: const TextStyle(fontSize: 10, color: Color(0xFF999999)), maxLines: 1, overflow: TextOverflow.ellipsis),
        const SizedBox(height: 4),
        Text(value, style: const TextStyle(fontSize: 13, fontWeight: FontWeight.w700, color: Color(0xFF1A1A1A)), maxLines: 1, overflow: TextOverflow.ellipsis),
      ],
    ),
  );
}
```

- [ ] Commit included in Task 64.

---

#### Task 68 — Wire CreatorEarningsDashboardScreen into profile screen

**Files:**
- Modify: `/Volumes/DATA/PROJECTS/TAJIRI/TAJIRI-FRONTEND/lib/screens/profile/profile_screen.dart`

- [ ] Find the earnings/monetization entry point in the profile grid (the module tile that currently navigates to the old earnings screen). Change its `onTap` to:
  ```dart
  Navigator.pushNamed(context, '/creator-earnings');
  ```
- [ ] Commit: `feat(earnings): wire CreatorEarningsDashboardScreen from profile`

---

#### Task 69 — Rewrite `PostEarningsScreen` to consume new API

**Files:**
- Modify: `/Volumes/DATA/PROJECTS/TAJIRI/TAJIRI-FRONTEND/lib/screens/feed/post_earnings_screen.dart`

The existing screen has good bones (hero card, breakdown card, explainer). Rewrite the data layer to use `CreatorEarningsService.getPostEarnings()` returning `PostEarningsV2` instead of the old `PostEarningsResult`. Keep all existing UI structure; update the data bindings.

- [ ] Change state type: `PostEarningsV2? _earnings;`
- [ ] Replace `_postService.getPostEarnings(widget.postId)` with:
  ```dart
  final result = await CreatorEarningsService().getPostEarnings(widget.postId, token: _token);
  ```
- [ ] Update hero card to show:
  - Large number: `_earnings!.totalTsh` (cleared + pending combined)
  - Sub-label: "TZS [cleared] cleared · TZS [pending] pending"
  - If `estimatedPoolTsh != null`, show "Est. from pool: TZS [X]" in smaller text with italic "estimate" label
- [ ] Update breakdown card rows to read from `PostEarningsV2.breakdown` map instead of individual `EarningsMetric` fields. The 6 rows are: view, reaction, comment, share, save, watch_second.
- [ ] Add "View earning events →" `OutlinedButton` below breakdown that navigates to `/earnings-provenance` with `{'postId': widget.postId}`.
- [ ] Update explainer card to mention the 30-day pending → cleared cycle and the weekly fund distribution.
- [ ] Remove `PostService` import; use `CreatorEarningsService`.
- [ ] Run `flutter analyze` — zero new errors.
- [ ] Commit: `feat(earnings): rewrite PostEarningsScreen to use new PostEarningsV2 model`

---

#### Task 70 — Update `PostService.getPostEarnings` signature

**Files:**
- Modify: `/Volumes/DATA/PROJECTS/TAJIRI/TAJIRI-FRONTEND/lib/services/post_service.dart`

The existing `getPostEarnings` returns `PostEarningsResult`. Keep it as a shim that calls the new service for backward compatibility (any callers not yet migrated).

- [ ] Add a new method `getPostEarningsV2(int postId, {String? token})` that calls `CreatorEarningsService().getPostEarnings(postId, token: token)`.
- [ ] Mark `getPostEarnings` as deprecated with a `@Deprecated` annotation pointing to the new method.
- [ ] Commit: `feat(earnings): add getPostEarningsV2 shim in PostService`

---

#### Task 71 — Remove old `PostEarningsResult` model dependency

**Files:**
- Modify: `/Volumes/DATA/PROJECTS/TAJIRI/TAJIRI-FRONTEND/lib/models/post_models.dart`

The `PostEarningsResult` and `EarningsMetric` classes in `post_models.dart` are now superseded by `PostEarningsV2` and `PostMetricBreakdown`.

- [ ] Keep `PostEarningsResult` and `EarningsMetric` in place for now (do not delete — other parts of the codebase may reference them). Add a comment: `// Deprecated: use PostEarningsV2 from creator_earnings_models.dart`
- [ ] Commit: `chore(earnings): annotate PostEarningsResult as deprecated`

---

#### Task 72 — Frontend screen: `EarningsProvenanceScreen`

**Files:**
- Create: `/Volumes/DATA/PROJECTS/TAJIRI/TAJIRI-FRONTEND/lib/screens/profile/earnings_provenance_screen.dart`

Per-event ledger for a creator — can be scoped to a specific post or show all events. The trust moat surface (strategy §9).

- [ ] Create screen with:
  - AppBar: "Earnings Events" / "Matukio ya Mapato"
  - Optional filter row: "All streams / Engagement / Fan Funding / Live Gifts" horizontal scroll chip row
  - Status filter: "All / Pending / Cleared" segmented control
  - `ListView.builder` of `_ProvenanceEventTile` items
  - Pagination: load more on scroll-to-end
  - Pull-to-refresh
  - Empty state: icon + "No earning events yet" / "Bado hakuna matukio ya mapato"

Key state:

```dart
class _EarningsProvenanceScreenState extends State<EarningsProvenanceScreen> {
  final _service = CreatorEarningsService();
  final _events = <EarningEventItem>[];
  bool _loading = true;
  bool _loadingMore = false;
  String? _error;
  int _page = 1;
  int _lastPage = 1;
  String? _selectedStream; // null = all
  String? _selectedStatus; // null = all
  String? _token;
  late final ScrollController _scrollController;
}
```

- [ ] Wire `_scrollController` to trigger `_loadMore()` when nearing bottom (remaining pixels < 200).
- [ ] `initState` → load token → call `_loadPage(1)`.
- [ ] Commit: `feat(earnings): add EarningsProvenanceScreen`

---

#### Task 73 — `_ProvenanceEventTile` widget

**Files:**
- Private widget in `earnings_provenance_screen.dart`

Shows the full provenance line per strategy §9:
> "You earned TZS 0.73 at 2:33 PM from a view. TZS 0.50 base × 2.0× watch × 1.1× streak = TZS 1.10 gross. TZS 0.04 to TRA. Pending until..."

- [ ] Create:

```dart
class _ProvenanceEventTile extends StatelessWidget {
  final EarningEventItem event;
  final bool isSw;
  final VoidCallback? onDispute;

  const _ProvenanceEventTile({required this.event, required this.isSw, this.onDispute});

  @override
  Widget build(BuildContext context) {
    final isCleared  = event.settlementStatus == 'cleared';
    final isPending  = event.settlementStatus == 'pending';
    final isReversed = event.settlementStatus == 'reversed';

    final statusColor = isCleared ? Colors.green.shade600
        : isPending  ? const Color(0xFF999999)
        : Colors.red.shade400;

    final statusLabel = isCleared
        ? (isSw ? 'Imeisha' : 'Cleared')
        : isPending
            ? (isSw ? 'Inangoja' : 'Pending')
            : (isSw ? 'Imerudishwa' : 'Reversed');

    // Build explanation sentence
    final multSummary = event.multiplierSummary();
    final explanation = isSw
        ? 'TZS ${event.rateTsh.toStringAsFixed(2)} msingi × $multSummary = TZS ${event.grossCredit.toStringAsFixed(2)}'
        : 'TZS ${event.rateTsh.toStringAsFixed(2)} base × $multSummary = TZS ${event.grossCredit.toStringAsFixed(2)} gross';

    return Container(
      margin: const EdgeInsets.only(bottom: 8),
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: event.isChargeable ? Colors.white : const Color(0xFFFAFAFA),
        borderRadius: BorderRadius.circular(12),
        boxShadow: [BoxShadow(color: Colors.black.withValues(alpha: 0.04), blurRadius: 8, offset: const Offset(0, 2))],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Expanded(
                child: Text(
                  _metricLabel(event.metric, isSw),
                  style: TextStyle(
                    fontSize: 13,
                    fontWeight: FontWeight.w600,
                    color: event.isChargeable ? const Color(0xFF1A1A1A) : const Color(0xFF999999),
                  ),
                  maxLines: 1, overflow: TextOverflow.ellipsis,
                ),
              ),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                decoration: BoxDecoration(
                  color: statusColor.withValues(alpha: 0.10),
                  borderRadius: BorderRadius.circular(6),
                ),
                child: Text(statusLabel, style: TextStyle(fontSize: 11, color: statusColor, fontWeight: FontWeight.w600)),
              ),
            ],
          ),
          const SizedBox(height: 4),
          Text(
            'TZS ${event.netToCreator.toStringAsFixed(2)}',
            style: TextStyle(
              fontSize: 20,
              fontWeight: FontWeight.w700,
              color: event.isChargeable ? const Color(0xFF1A1A1A) : const Color(0xFF999999),
              fontFeatures: const [FontFeature.tabularFigures()],
            ),
          ),
          if (event.isChargeable) ...[
            const SizedBox(height: 4),
            Text(explanation,
              style: const TextStyle(fontSize: 11, color: Color(0xFF666666)),
              maxLines: 2, overflow: TextOverflow.ellipsis,
            ),
            if (event.traWhtHeld > 0)
              Text(
                isSw ? 'TZS ${event.traWhtHeld.toStringAsFixed(2)} kwa TRA (WHT 5%)' : 'TZS ${event.traWhtHeld.toStringAsFixed(2)} to TRA (WHT 5%)',
                style: const TextStyle(fontSize: 11, color: Color(0xFF999999)),
                maxLines: 1, overflow: TextOverflow.ellipsis,
              ),
          ] else ...[
            const SizedBox(height: 4),
            Text(
              isSw ? 'Haihusiki (${event.chargeReason ?? ""})'
                   : 'Not chargeable (${event.chargeReason ?? ""})',
              style: const TextStyle(fontSize: 11, color: Color(0xFF999999)),
              maxLines: 1, overflow: TextOverflow.ellipsis,
            ),
          ],
          const SizedBox(height: 8),
          Row(
            children: [
              Text(
                _formatTime(event.occurredAt, isSw),
                style: const TextStyle(fontSize: 11, color: Color(0xFF999999)),
              ),
              const Spacer(),
              if (event.isChargeable && isPending && onDispute != null)
                GestureDetector(
                  onTap: onDispute,
                  child: Text(
                    isSw ? 'Pinga' : 'Dispute',
                    style: const TextStyle(fontSize: 11, color: Color(0xFF1A1A1A), fontWeight: FontWeight.w600, decoration: TextDecoration.underline),
                  ),
                ),
            ],
          ),
        ],
      ),
    );
  }

  String _metricLabel(String metric, bool isSw) {
    const labels = {
      'view':              ('View', 'Mwoneko'),
      'reaction':          ('Reaction', 'Maoni ya Moyo'),
      'comment':           ('Comment', 'Maoni'),
      'share':             ('Share', 'Kushiriki'),
      'save':              ('Save', 'Kuhifadhi'),
      'watch_second':      ('Watch time', 'Muda wa kutazama'),
      'follow':            ('Follow discovery', 'Kufuata'),
      'subscribe':         ('Subscription', 'Usajili'),
      'gift':              ('Live gift', 'Zawadi'),
      'super_chat':        ('Super Chat', 'Super Chat'),
      'live_reaction':     ('Live reaction', 'Maoni ya Moja kwa Moja'),
      'derivative_royalty':('Derivative royalty', 'Mrabaha'),
      'period_settlement': ('Weekly settlement', 'Usuluhishi wa wiki'),
      'marketplace_sale':  ('Sale', 'Mauzo'),
    };
    final pair = labels[metric];
    return isSw ? (pair?.$2 ?? metric) : (pair?.$1 ?? metric);
  }

  String _formatTime(String iso, bool isSw) {
    try {
      final dt = DateTime.parse(iso).toLocal();
      return '${dt.day}/${dt.month}/${dt.year} ${dt.hour}:${dt.minute.toString().padLeft(2, '0')}';
    } catch (_) { return iso; }
  }
}
```

- [ ] Commit included in Task 72.

---

#### Task 74 — Dispute bottom sheet inside `EarningsProvenanceScreen`

- [ ] Inside `_EarningsProvenanceScreenState`, add `_showDisputeSheet(EarningEventItem event)`:

```dart
Future<void> _showDisputeSheet(EarningEventItem event) async {
  final reasonController = TextEditingController();
  final messenger = ScaffoldMessenger.of(context);
  final isSw = AppStringsScope.of(context)?.isSwahili ?? false;

  await showModalBottomSheet(
    context: context,
    isScrollControlled: true,
    shape: const RoundedRectangleBorder(borderRadius: BorderRadius.vertical(top: Radius.circular(16))),
    builder: (ctx) => Padding(
      padding: EdgeInsets.fromLTRB(16, 12, 16, MediaQuery.of(ctx).viewInsets.bottom + 24),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Center(child: Container(width: 40, height: 4, decoration: BoxDecoration(color: Colors.grey.shade300, borderRadius: BorderRadius.circular(2)))),
          const SizedBox(height: 16),
          Text(isSw ? 'Pinga Tukio' : 'Dispute Event',
            style: const TextStyle(fontSize: 16, fontWeight: FontWeight.w700, color: Color(0xFF1A1A1A))),
          const SizedBox(height: 12),
          TextField(
            controller: reasonController,
            maxLines: 3,
            decoration: InputDecoration(
              filled: true, fillColor: Colors.white,
              hintText: isSw ? 'Eleza sababu...' : 'Describe the issue...',
              border: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: const BorderSide(color: Color(0xFFE5E5E5))),
            ),
          ),
          const SizedBox(height: 16),
          SizedBox(
            width: double.infinity,
            child: FilledButton(
              style: FilledButton.styleFrom(backgroundColor: const Color(0xFF1A1A1A), shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12))),
              onPressed: () async {
                if (reasonController.text.trim().isEmpty) return;
                Navigator.pop(ctx);
                try {
                  await _service.fileDispute(
                    userId: widget.currentUserId,
                    earningEventId: event.eventId,
                    reason: reasonController.text.trim(),
                    token: _token ?? '',
                  );
                  if (!mounted) return;
                  messenger.showSnackBar(SnackBar(content: Text(isSw ? 'Malalamiko yamewasilishwa' : 'Dispute filed successfully')));
                } catch (e) {
                  if (!mounted) return;
                  messenger.showSnackBar(SnackBar(content: Text(isSw ? 'Imeshindwa' : 'Failed to file dispute')));
                }
              },
              child: Text(isSw ? 'Wasilisha' : 'Submit'),
            ),
          ),
        ],
      ),
    ),
  );
  reasonController.dispose();
}
```

- [ ] Pass `onDispute: () => _showDisputeSheet(event)` to each `_ProvenanceEventTile`.
- [ ] Commit included in Task 72.

---

#### Task 75 — Frontend screen: `CreatorTierScreen`

**Files:**
- Create: `/Volumes/DATA/PROJECTS/TAJIRI/TAJIRI-FRONTEND/lib/screens/profile/creator_tier_screen.dart`

Shows tier status, next tier requirements, and Mwanzo Boost countdown.

- [ ] Create screen with:
  - Hero: current tier name in a large dark card
  - Mwanzo boost countdown row (days remaining, "2× RPM multiplier active")
  - 4-tier progression ladder: Mwanzo → Standard → Verified → Partner. Each shows gate requirements. Current tier highlighted.
  - For Standard gate: "100 followers · 30 days active · 0 strikes" — show ✓/✗ per requirement (requires backend data in dashboard endpoint; extend if needed)
  - Rate card link button → opens rate card via `CreatorEarningsService.getRateCard()` in a bottom sheet

```dart
class CreatorTierScreen extends StatefulWidget {
  final int currentUserId;
  const CreatorTierScreen({super.key, required this.currentUserId});

  @override
  State<CreatorTierScreen> createState() => _CreatorTierScreenState();
}

class _CreatorTierScreenState extends State<CreatorTierScreen> {
  final _service = CreatorEarningsService();
  CreatorEarningsDashboard? _dashboard;
  bool _loading = true;
  String? _token;

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    try {
      _token = await LocalStorageService.getInstance().getAuthToken();
      final d = await _service.getDashboard(userId: widget.currentUserId, token: _token ?? '');
      if (!mounted) return;
      setState(() { _dashboard = d; _loading = false; });
    } catch (_) {
      if (!mounted) return;
      setState(() => _loading = false);
    }
  }
  // ...build with tier ladder
}
```

- [ ] `dispose()`: no controllers to dispose.
- [ ] Run `flutter analyze` — zero new errors.
- [ ] Commit: `feat(earnings): add CreatorTierScreen`

---

#### Task 76 — Wire CreatorTierScreen and rate card from profile modules grid

**Files:**
- Modify: `/Volumes/DATA/PROJECTS/TAJIRI/TAJIRI-FRONTEND/lib/screens/profile/profile_screen.dart`

- [ ] Find the "Tier" or "Monetization" profile module tile and wire:
  ```dart
  Navigator.pushNamed(context, '/creator-tier');
  ```
- [ ] Add a "Rate Card" tile if not present — taps open `CreatorEarningsService().getRateCard()` result in a modal bottom sheet showing the rate table.
- [ ] Commit: `feat(earnings): wire CreatorTierScreen from profile`

---

#### Task 77 — Migration and data backfill plan

Per strategy §14, backfill policy is **forward-only**. No historical events are to be created.

- [ ] On deploy, run all migrations in order (Tasks 1–10, 13b, 15, 24, 45b, 56, 58, 61).
- [ ] Run `CreatorsFundInitialPeriodSeeder` to open the first period.
- [ ] Run `CreatorsFundCoaSeeder` to seed COA accounts.
- [ ] All creators automatically get a `creator_tiers` row (Mwanzo) the first time `EarningsEngine::recordEvent` is called for them (via `CreatorTier::forUser()`).
- [ ] Do not run any job to seed `earning_events` from `posts.*_count` columns. The `posts.*_count` values remain on the `posts` table as read-model counters; the `earning_events` table starts fresh.
- [ ] Announce cutover date publicly on rate card and in the app's "What's New" section.
- [ ] Commit: `chore(earnings): document forward-only backfill policy`

---

#### Task 78 — Backend unit tests: `EarningsEngineTest`

**Files:**
- Create: `tests/Unit/EarningsEngineTest.php`

- [ ] Test cases:
  1. `test_view_event_credits_post_author` — view creates one chargeable `earning_events` row for the author.
  2. `test_self_action_is_not_chargeable` — actor_id = creator_id produces `is_chargeable=false`.
  3. `test_duplicate_view_within_1h_not_chargeable` — second view from same actor within 1h returns null.
  4. `test_daily_actor_creator_cap_enforced` — 51st event in a day is not chargeable.
  5. `test_mwanzo_boost_doubles_multiplier` — new creator gets 2.0 mwanzo_boost in multipliers.
  6. `test_watch_second_cap_enforced` — watched_seconds > video_duration caps at video_duration.
  7. `test_derivative_royalty_credits_original_author` — stitch post creation credits the original author.
  8. `test_fund_period_points_incremented` — after a chargeable event, `creators_fund_points.points` increases.

- [ ] Run: `php artisan test tests/Unit/EarningsEngineTest.php`
- [ ] All 8 tests pass.
- [ ] Commit: `test(earnings): add EarningsEngineTest unit tests`

---

#### Task 79 — Backend unit tests: `MultiplierEngineTest`

**Files:**
- Create: `tests/Unit/MultiplierEngineTest.php`

- [ ] Test all 5 multiplier branches with boundary values (e.g. completionPct=0.24 → 0.5×, 0.25 → 1.0×, 0.50 → 1.5×, 0.70 → 2.0×, 0.90 → 2.5×).
- [ ] Test `combined()` correctly multiplies all factors.
- [ ] Commit: `test(earnings): add MultiplierEngineTest`

---

#### Task 80 — Backend feature test: `SettlementSweepJobTest`

**Files:**
- Create: `tests/Feature/SettlementSweepJobTest.php`

- [ ] Seed a cleared-eligible pending event (occurred_at 31 days ago, is_chargeable=true).
- [ ] Run `SettlementSweepJob::dispatch()`.
- [ ] Assert event `settlement_status` is now `cleared`.
- [ ] Assert `journal_lines` contains the Dr. 2110 / Cr. 2120 pair.
- [ ] Assert `tra_wht_held` = 5% of `net_to_creator`.
- [ ] Commit: `test(earnings): add SettlementSweepJobTest`

---

#### Task 81 — Backend feature test: `CreatorsFundPeriodSettlementJobTest`

**Files:**
- Create: `tests/Feature/CreatorsFundPeriodSettlementJobTest.php`

- [ ] Seed an open period with `period_end = now() - 1 minute`.
- [ ] Seed 2 creators with different points totals.
- [ ] Run the job.
- [ ] Assert period `status = settled`.
- [ ] Assert each creator's `payout_tsh = points × fund_per_point`.
- [ ] Assert `journal_lines` has the COA 5110 debit entry.
- [ ] Assert a new period was opened.
- [ ] Commit: `test(earnings): add CreatorsFundPeriodSettlementJobTest`

---

#### Task 82 — Flutter widget tests

**Files:**
- Create: `/Volumes/DATA/PROJECTS/TAJIRI/TAJIRI-FRONTEND/test/screens/creator_earnings_dashboard_test.dart`

- [ ] Mock `CreatorEarningsService` to return a fixed `CreatorEarningsDashboard`.
- [ ] Verify total_cleared_tsh renders in the hero card.
- [ ] Verify all 6 stream breakdown rows render.
- [ ] Verify the fund period card renders.
- [ ] Verify "View all events" button navigates to `/earnings-provenance`.
- [ ] Run `flutter test test/screens/creator_earnings_dashboard_test.dart` — all pass.
- [ ] Commit: `test(earnings): add CreatorEarningsDashboardScreen widget test`

---

#### Task 83 — Deploy checklist

- [ ] SSH to backend server (`sshpass -p 'ZimaBlueApps' ssh -o StrictHostKeyChecking=no root@172.240.241.180`)
- [ ] `cd /var/www/tajiri.zimasystems.com && git pull origin main`
- [ ] `php artisan migrate --force`
- [ ] `php artisan db:seed --class=CreatorsFundCoaSeeder --force`
- [ ] `php artisan db:seed --class=CreatorsFundInitialPeriodSeeder --force`
- [ ] `php artisan config:cache && php artisan route:cache`
- [ ] Verify scheduler is running: `php artisan schedule:list` — confirm all 6 jobs appear.
- [ ] Test endpoint: `curl https://tajiri.zimasystems.com/api/creators/rate-card | jq .`
- [ ] Test earnings dashboard: `curl /api/users/me/earnings?user_id=1 | jq .`
- [ ] Build Flutter: `flutter build apk --release`
- [ ] Commit: `chore(earnings): deploy v1 creators fund engine`

---

#### Task 84 — Rollout announcement

- [ ] Update `GET /api/creators/rate-card` to include a `v1_launch_date` field with today's date.
- [ ] Add an in-app "What's New" banner in the feed screen pointing to `/creator-earnings`.
- [ ] Post the rate card URL on the public `tajiri.zimasystems.com/creators/rate-card` page (static or rendered from the API).
- [ ] Commit: `feat(earnings): add v1 launch announcement and rate card public URL`

---

## v2 — Tier features + trust (target: +4 weeks)

Still in Phase 1 mode. No advertiser dependency.

- [ ] **Brand-deal facilitation marketplace (Verified+)** — New `brand_deals` table and `BrandDealController`. Verified creators can list themselves for sponsorship enquiries. 90/10 split on deal value. Requires a deal-matching UI and contract acceptance flow.
- [ ] **Discovery Mode v1 opt-in UI** — Full rate-card A/B framing in the CreatorTierScreen. Show "additional impressions credited" metric on opted-in posts. Currently only the backend enablement is wired (Task 52).
- [ ] **Mwitiko collective tipping during LIVE** — Group tipping event on live streams where viewers can co-fund a tip goal. New `mwitiko_events` table + LIVE stream UI widget.
- [ ] **Streak bonus calc job** — `StreakBonusCalcJob` that stamps `has_active_streak=true` on `creator_tiers` nightly, so `EarningsEngine` can read it without a DB query per event (performance improvement).
- [ ] **Quarterly transparency report machinery** — `TransparencyReportJob` runs on quarter-end; aggregates stats (total payouts by stream, anonymized earner bands, avg RPM by niche, reserve fund balance) into a `transparency_reports` table; public endpoint `GET /api/creators/transparency-report`.
- [ ] **Sock-puppet detection v1** — `SockPuppetDetectionJob` hourly; flags accounts created within 24h of each other that have identical ASN + device fingerprint and have 50+ mutual engagement events. Sets `is_chargeable=false` retroactively on flagged events.
- [ ] **Public rate card UI screen** — `RateCardScreen` in Flutter. Reads `GET /api/creators/rate-card`. Shows all metrics, rates, caps, multiplier rules, and last-updated timestamp. Accessible from `CreatorTierScreen`.
- [ ] **Dispute resolution flow** — Admin-side dispute review dashboard (backend only — per `feedback_admin_actions_are_backend_only.md`). Auto-email creator on resolution. 5-day SLA timer on `earnings_disputes`.
- [ ] **Watch-completion tracking improvement** — Client sends `watch_completion_pct` with the view event. Currently the multiplier defaults to 1.0× when null. v2 adds client-side AVD calculation in the video player and passes it with the view event.
- [ ] **Originality detection v1** — Heuristic checks at post-creation: identical `original_post_id` reuse, slideshow-only video detection (no audio track), rapid upload cadence. Set `originality_flag='reused'` automatically.

---

## v3 — Optimization + cross-border (target: +6 weeks)

Still Phase 1 mode unless transition criteria met.

- [ ] **Engagement-ring graph detection** — Graph-anomaly analysis on like/follow networks using PostgreSQL recursive CTEs. Marks ring participants' earning events as non-chargeable.
- [ ] **Wise/Stripe Connect cross-border payouts** — For non-TZ creators. `PayoutService::creditCrossBorder()` method using Wise API for TZS → USD/EUR/KES. Disclosed-FX with 0.5% spread.
- [ ] **Multi-currency display** — Creator earnings dashboard shows TZS + local currency equivalent for cross-border earners.
- [ ] **Creator tax dashboard** — `GET /api/users/me/earnings/tax` already exists (Task 50). v3 adds: YTD CSV export, TRA-format PDF generation using a PHP PDF library, in-app download button.
- [ ] **Originality detection v2** — Perceptual hash comparison across post thumbnails (pHash using ImageMagick). AI-voice classifier (audio fingerprint) for voiceover-only content.
- [ ] **A/B framework for rate experiments** — `rate_experiments` table lets TAJIRI define a cohort split and alternate rate values. `RateRegistry` checks experiments before returning a rate. Full before/after analytics via transparency report.
- [ ] **Performance: `has_active_streak` cache** — Move streak check from per-event DB query to a pre-computed column on `creator_tiers`, refreshed by the nightly `StreakBonusCalcJob`.
- [ ] **`AbscanJob` retro-scan** — `AbuseScanJob` hourly; scans last 6 hours of `earning_events` for newly-detectable anti-abuse patterns (e.g. new IP clustering data) and retroactively marks events as `is_chargeable=false`.

---

## v4 — Phase 2 transition (timing: when advertiser criteria met)

Triggered when monthly ad revenue ≥ TZS 200M sustained 3 months, ≥ 50 active advertisers, and board approval (per strategy §1.3).

- [ ] **Ad revenue account** — Add COA account `4115 — Ad Revenue`. New migration adds `ad_revenue_tsh` input to `creators_fund_periods` (already has the column; ensure it's populated from the ad platform).
- [ ] **Switch `CreatorsFundPeriodSettlementJob` to Phase 2 formula** — Flip `phase` column on new periods to `phase_2`. Update `openNextPeriod()` to compute `MAX(floor_tsh, 0.70 × ad_revenue + 0.10 × pass_through_takes + treasury_topup)`. Journal entries hit `5111` instead of `5110`.
- [ ] **30-day public notice** — On the date the board approves Phase 2, call `RateCardNoticeService::publishPhase2Notice()` which sets a `phase_2_effective_date` on the rate card and emails every active creator with their current vs projected earnings.
- [ ] **`floor_tsh` carry-forward** — Ensure the `floor_tsh` on the first Phase 2 period equals the last Phase 1 `fund_size_tsh`. Creators never see an income drop at transition.
- [ ] **Reserve-fund top-up logic** — Activate `EarningsReserveService::topUpIfNeeded()` called by `CreatorsFundPeriodSettlementJob` at Phase 2: if `0.70 × ad_revenue + 0.10 × pass_through < floor_tsh`, draw down from `earnings_reserve_ledger` to cover the gap.
- [ ] **Post-transition transparency report** — First quarterly report after Phase 2 switch includes a side-by-side Phase 1 vs Phase 2 retrospective section with per-creator earnings comparison.
- [ ] **Phase 2 → Phase 1 reversion guard** — `CreatorsFundPeriodSettlementJob` enforces a 30-day notice check before allowing a Phase 2 → Phase 1 reversion (reads from a `phase_transition_notices` table).

---

## Open questions / risks

1. **Rate-card initial values are starting points** — `view=0.5 TSh`, `reaction=2.0 TSh`, `share=5.0 TSh`, `save=3.0 TSh`, `comment=2.5 TSh`, `watch_second=0.1 TSh` are seeded from the existing `creator_earnings_rates` table. The actual `fund_per_point` at settlement will scale these up or down depending on the total points pool. Initial `fund_per_point` is unknown until the first settlement run — monitor week 1 closely and adjust `phase_1_committed_budget` if per-creator payouts are far from TZS 10,000/week target.

2. **AbuseGuard DB queries per event** — In v1 every event triggers up to 4 COUNT/EXISTS queries on `earning_events`. At high throughput (10k views/min) this is a bottleneck. v3 mitigation: Redis-backed per-actor daily counters via `Cache::increment()` instead of DB queries.

3. **Tajiri Pay payout API contract** — `PayoutDisbursementJob` writes directly to `wallet_transactions` using the same pattern as `WalletController`. If a separate Tajiri Pay push API exists for mobile money disbursement (MPESA B2C), it must be integrated at Task 53–54 before the daily job fires live payouts. Confirm with the backend team whether wallet credit = automatic mobile money push or requires a separate step.

4. **TRA WHT remittance integration scope** — `TRARemittanceJob` creates the journal entry and logs the remittance. The TRA digital portal API integration (actual push of funds + submission of the return) is out of scope for v1. Manual remittance from the bank using the journal line amount is the v1 process. This is a compliance risk that must be resolved before TZS volumes exceed the reporting threshold.

5. **Sock-puppet fraud window** — Sock-puppet detection is deferred to v2. Between v1 launch and v2, the fund is vulnerable to coordinated engagement rings. The `daily_actor_creator_cap_50` rule (Task 13) and `daily_creator_soft_cap_500k` (strategy §10.4) provide partial protection, but sophisticated ring operators can stay under the caps. Monitor `earning_events` for anomalous `(actor_user_id, target_user_id)` concentration.

6. **`journal_lines` table schema assumptions** — Tasks 16, 41, 42 assume `journal_lines` has columns: `account_code`, `debit`, `credit`, `description`, `reference_type`, `reference_id`. If the actual schema differs (e.g. uses `account_id` FK instead of `account_code` string), the insert statements in `EarningsEngine` and the jobs must be updated to match.

7. **`PostController::recordView` auth context** — The view event hook (Task 26) reads `$request->input('user_id')` for the actor. If the route does not require auth, anonymous views will have `actor_user_id = null`. Anonymous views are recorded but not chargeable (AbuseGuard requires an actor to check caps). Confirm whether anonymous view endpoints should be auth-gated for the earning system to work properly.

8. **`creators_fund_points` upsert race condition** — The `DB::table()->upsert()` in `EarningsEngine` uses a raw SQL `points + $points` expression. Under high concurrency this is safe only if PostgreSQL advisory locks or `SELECT FOR UPDATE` are used. For v1 at low throughput this is acceptable; for v2 migrate to Redis atomic increments and batch-flush to Postgres.

---

## Glossary

- **actor_role** — The role of the target_user_id in relation to the engagement event. `author` = post author earns from someone interacting with their post. `comment_author` = the author of a comment earns when their comment is reacted to. `host` = the post/stream host receives a smaller secondary share (e.g. post author earns when a comment on their post gets liked). `sharer` = a user who shared a post earns secondary discovery credits when views arrive via their share. `original_creator_royalty` = the creator of an original post earns a royalty when a derivative post (stitch/quote/reply) is created from it.

- **stream** — One of six monetization streams: `engagement` (Creators Fund pool), `fan_funding` (subscriptions/tips/Michango), `marketplace` (product sales), `brand_deal` (sponsored content), `live_gifts` (gifts/super-chat), `affiliate` (referral bounties).

- **metric** — The specific engagement action within a stream: `view`, `reaction`, `comment`, `share`, `save`, `watch_second`, `follow`, `subscribe`, `gift`, `super_chat`, `live_reaction`, `derivative_royalty`, `period_settlement`, `marketplace_sale`.

- **earnable event** — Any engagement action recorded in `earning_events` with `is_chargeable=true` that contributes to a creator's `creators_fund_points` total or to a pass-through credit.

- **chargeable** — `is_chargeable=true` means the event passed all anti-abuse checks and counts toward earnings. `is_chargeable=false` means the event was recorded for audit purposes only and does not earn.

- **fund_per_point** — The TZS value of one point in the Creators Fund for a given settlement period. Computed at period close as `fund_size_tsh / total_points`. All creators' point totals are multiplied by `fund_per_point` to produce their actual TZS payout.

- **settlement period** — A weekly window (Monday 00:00 UTC+3 to following Monday 00:00 UTC+3) during which engagement events accumulate points. At period close, the fund is distributed proportional to points. Tracked in `creators_fund_periods`.

- **Phase 1 / Phase 2** — Phase 1: Creators Fund is treasury-funded as creator-acquisition spend (`fund = phase_1_committed_budget`). Active now. Phase 2: Fund switches to 70/30 ad rev-share (`fund = MAX(floor, 0.70 × ad_revenue + …)`). Triggered by advertiser criteria (strategy §1.3).

- **Mwanzo** — Tier 0. Every creator's starting tier. Benefits: 2× RPM multiplier for 30 days, 1,000 guaranteed first impressions per original post, full engagement pool + fan-funding + marketplace access. Gate: day 0.

- **Standard** — Tier 1. Gates: 100 followers + 30 days active + 0 strikes. Adds: Discovery Mode eligibility, Live Gifts access.

- **Verified** — Tier 2. Gates: 1,000 followers + 50k views/30d + ID verified + 0 strikes/90d. Adds: Brand-deal marketplace access.

- **Partner** — Tier 3. Gates: 10k followers + 500k views/30d + 90 days Verified + manual review. Benefits: 75/25 engagement pool split (vs 70/30), 92.5/7.5 on live gifts and brand deals.

- **host share** — When a post author's comment section generates engagement (e.g. someone likes a comment), the post author receives a small secondary credit called the host share, at a lower rate than the comment_author earns.

- **discovery credit** — When a follow or subscribe action is attributed to a specific post (via `origin_post_id`), the post author earns a discovery credit for driving that conversion.

- **derivative royalty** — When a creator stitches, quotes, or replies-with-video to another creator's post, the original post's author earns a royalty on the derivative post's engagement earnings.
