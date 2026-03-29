# TAJIRI Commercial Monetization Layer — Design Spec

## Overview

Three subsystems that together form TAJIRI's revenue engine:

1. **Platform Fee System** — configurable percentage fees on all monetizable transactions
2. **Ad Revenue System** — hybrid self-serve ad platform + AdMob fallback across 5 surfaces
3. **Revenue Admin Dashboard** — Laravel Blade web panel for financial monitoring and settings

**Tech stack:** Laravel 12 (PHP 8.3), PostgreSQL 16, Flutter/Dart, Google Mobile Ads SDK, Chart.js, Tailwind CSS, Alpine.js.

**Server:** root@172.240.241.180, Laravel at `/var/www/tajiri.zimasystems.com`.
**Frontend:** `/Volumes/DATA/PROJECTS/TAJIRI/TAJIRI-FRONTEND`.

---

## 1. Platform Fee System

### Goal

Deduct configurable platform fees from every monetizable transaction before crediting creator earnings. Fees fund the Creator Fund pool, operations, and margin.

### 1.1 Data Model

#### `platform_settings` table (new)

General-purpose key-value config table for all platform-level settings.

| Column | Type | Constraints | Description |
|--------|------|-------------|-------------|
| key | varchar(100) | PRIMARY KEY | Setting identifier |
| value | varchar(255) | NOT NULL | Setting value (cast by consumer) |
| description | text | nullable | Human-readable description |
| updated_at | timestamp | DEFAULT NOW() | Last modification |

**Default fee settings seeded on migration:**

| Key | Default Value | Description |
|-----|---------------|-------------|
| `fee_subscription_pct` | `15.0` | % deducted from subscription payments |
| `fee_tip_pct` | `10.0` | % deducted from tips |
| `fee_marketplace_pct` | `10.0` | % deducted from marketplace sales |
| `fee_michango_pct` | `5.0` | % deducted from crowdfunding withdrawals |
| `fee_sponsored_pct` | `25.0` | % deducted from legacy sponsored post budgets |
| `fee_ad_deposit_pct` | `25.0` | % deducted from Biashara ad escrow deposits |
| `fund_allocation_pct` | `30.0` | % of platform revenue allocated to Creator Fund |
| `operations_allocation_pct` | `40.0` | % of platform revenue allocated to operations |
| `margin_allocation_pct` | `30.0` | % of platform revenue retained as margin |
| `last_fund_distribution_at` | `null` | ISO 8601 timestamp of last Creator Fund distribution (parsed via `Carbon::parse()`, compared against current month start to guard against double-distribution) |

#### `platform_revenue_ledger` table (new)

Append-only financial ledger recording every fee collection event.

| Column | Type | Constraints | Description |
|--------|------|-------------|-------------|
| id | bigint | PK, auto-increment | |
| transaction_type | varchar(20) | NOT NULL, CHECK IN ('subscription','tip','marketplace','michango','sponsored','ad_deposit','ad_cpm','ad_cpc','ad_admob') | Revenue source category |
| reference_id | bigint | NOT NULL | ID of the source record (payment, order, campaign, etc.) |
| reference_type | varchar(50) | NOT NULL | Polymorphic type (e.g., 'App\Models\SubscriptionPayment') |
| gross_amount | decimal(12,2) | NOT NULL | Full transaction amount |
| fee_percentage | decimal(5,2) | NOT NULL | Fee % applied at time of transaction |
| fee_amount | decimal(12,2) | NOT NULL | Platform's cut (gross × fee_pct / 100) |
| net_amount | decimal(12,2) | NOT NULL | Creator's cut (gross - fee) |
| currency | varchar(3) | NOT NULL, DEFAULT 'TZS' | |
| created_at | timestamp | DEFAULT NOW() | |

**Indexes:**
- `(transaction_type, created_at)` — dashboard queries by type and date range
- `(reference_type, reference_id)` — lookup by source transaction
- `(created_at)` — time-range scans

### 1.2 PlatformFeeService

New static-method Laravel service at `app/Services/PlatformFeeService.php`.

```
PlatformFeeService::getSetting(string $key): float
```
- Reads from `platform_settings`, casts to float
- Cached via Laravel Cache for 1 hour (`cache.platform_settings.{key}`)
- Cache busted on update via admin dashboard

```
PlatformFeeService::applyFee(string $type, float $grossAmount, int $referenceId, string $referenceType): array
```
- Looks up fee percentage: `getSetting("fee_{$type}_pct")`
- Calculates: `fee = gross × pct / 100`, `net = gross - fee`
- Inserts row into `platform_revenue_ledger`
- Returns: `['gross' => float, 'fee' => float, 'net' => float, 'fee_pct' => float]`

```
PlatformFeeService::getRevenueReport(Carbon $from, Carbon $to, ?string $type = null): array
```
- Aggregates `platform_revenue_ledger` by `transaction_type` for date range
- Returns: `['total_gross' => X, 'total_fees' => Y, 'by_type' => [...]]`

```
PlatformFeeService::updateSetting(string $key, string $value): void
```
- Updates `platform_settings` row
- Busts cache for that key

### 1.3 Integration Points

Fee deduction is applied at the **point of payment confirmation** in existing controllers/services. The fee must be applied BEFORE crediting creator earnings.

| Transaction | Where to integrate | Call |
|-------------|-------------------|------|
| Subscription payment confirmed | Subscription payment handler | `applyFee('subscription', $amount, $paymentId, SubscriptionPayment::class)` |
| Tip sent | Tip handler | `applyFee('tip', $amount, $tipId, Tip::class)` |
| Shop order completed | Order completion handler | `applyFee('marketplace', $amount, $orderId, Order::class)` |
| Michango withdrawal approved | Withdrawal handler | `applyFee('michango', $amount, $withdrawalId, CampaignWithdrawal::class)` |
| Sponsored post budget deposited | Sponsored post activation | `applyFee('sponsored', $budget, $campaignId, SponsoredPost::class)` |

**Frontend impact:** None. The existing `CreatorEarning` model already has `platformFee`, `grossAmount`, and `netAmount` fields parsed from the backend response. The backend will now populate these correctly instead of returning zeroes.

---

## 2. Ad Revenue System

### Goal

Hybrid advertising platform: self-serve for Tanzanian SMEs (100% revenue retained) with Google AdMob as fallback fill (60-70% revenue retained). Ads served across 5 surfaces. Advertisers manage campaigns in-app via a "Biashara" (Business) section.

### 2.1 Data Model

#### `ad_campaigns` table (new)

| Column | Type | Constraints | Description |
|--------|------|-------------|-------------|
| id | bigint | PK, auto-increment | |
| advertiser_id | bigint | FK→users, NOT NULL | Campaign owner |
| title | varchar(100) | NOT NULL | Campaign name |
| description | text | nullable | Internal notes |
| campaign_type | varchar(10) | NOT NULL, CHECK IN ('cpm','cpc') | Pricing model |
| status | varchar(20) | NOT NULL, DEFAULT 'draft', CHECK IN ('draft','pending_review','active','paused','completed','rejected') | |
| daily_budget | decimal(12,2) | NOT NULL | Max daily spend (TZS) |
| total_budget | decimal(12,2) | NOT NULL | Lifetime budget cap (TZS) |
| spent_amount | decimal(12,2) | NOT NULL, DEFAULT 0 | Running total spent |
| bid_amount | decimal(8,2) | NOT NULL | CPM rate per 1000 impressions or CPC rate per click (TZS) |
| start_date | date | NOT NULL | Campaign start |
| end_date | date | nullable | Campaign end (null = runs until budget exhausted) |
| targeting | jsonb | NOT NULL, DEFAULT '{}' | `{"regions": [...], "age_min": int, "age_max": int, "interests": [...], "gender": "all"|"male"|"female"}` |
| placements | jsonb | NOT NULL | `["feed","stories","music","search","marketplace","clips","video_preroll","conversations","comments","live_stream","hashtag"]` |
| rejection_reason | text | nullable | Admin reason for rejection |
| created_at | timestamp | DEFAULT NOW() | |
| updated_at | timestamp | DEFAULT NOW() | |

**Indexes:**
- `(advertiser_id)` — advertiser's campaigns list
- `(status, start_date, end_date)` — active campaign queries for ad serving
- `(status, updated_at)` — review queue + ordering

#### `ad_creatives` table (new)

| Column | Type | Constraints | Description |
|--------|------|-------------|-------------|
| id | bigint | PK, auto-increment | |
| campaign_id | bigint | FK→ad_campaigns, NOT NULL, ON DELETE CASCADE | |
| format | varchar(20) | NOT NULL, CHECK IN ('image','video','audio','promoted_product','promoted_search') | Creative type |
| media_url | varchar(500) | nullable | Uploaded creative asset path (storage) |
| headline | varchar(50) | NOT NULL | Ad headline |
| body_text | varchar(150) | nullable | Ad body text |
| cta_type | varchar(20) | NOT NULL, CHECK IN ('learn_more','shop_now','visit','download','call') | Call-to-action type |
| cta_url | varchar(500) | NOT NULL | Destination URL or deep link |
| product_id | bigint | nullable, FK→products | For marketplace promoted listings |
| approved | boolean | NOT NULL, DEFAULT false | Admin review status |
| created_at | timestamp | DEFAULT NOW() | |

**Indexes:**
- `(campaign_id)` — campaign's creatives

#### `ad_impressions` table (new, partitioned)

High-volume event log. Partitioned by month on `created_at` using PostgreSQL range partitioning.

| Column | Type | Constraints | Description |
|--------|------|-------------|-------------|
| id | bigint | GENERATED ALWAYS AS IDENTITY | Auto-increment |
| created_at | timestamp | NOT NULL, DEFAULT NOW() | Partition key |
| campaign_id | bigint | NOT NULL | Self-serve campaign ID (0 for AdMob) |
| creative_id | bigint | NOT NULL | Self-serve creative ID (0 for AdMob) |
| user_id | bigint | NOT NULL | Viewer |
| placement | varchar(20) | NOT NULL, CHECK IN ('feed','stories','music','search','marketplace','clips','video_preroll','conversations','comments','live_stream','hashtag') | Where shown |
| event_type | varchar(15) | NOT NULL, CHECK IN ('impression','click','skip','mute') | Event type |
| revenue | decimal(8,4) | NOT NULL, DEFAULT 0 | Platform revenue for this event |
| source | varchar(15) | NOT NULL, CHECK IN ('self_serve','admob') | Which system served it |

**Primary key:** `(id, created_at)` — composite PK required for PostgreSQL range partitioning (partition key must be in PK).

**Indexes (per partition):**
- `(campaign_id, created_at)` — campaign performance queries
- `(user_id, campaign_id, created_at)` — frequency capping lookups
- `(placement, created_at)` — placement breakdown queries
- `(source, created_at)` — self-serve vs AdMob split

**Partition strategy:** Monthly range on `created_at`. Create partitions 3 months ahead via scheduled job. Partitions older than 12 months can be detached and archived.

#### Ad escrow balance

Add `ad_balance` column to the existing `wallets` table (confirmed: `wallet_models.dart` has `Wallet` with `balance` and `pendingBalance`):

| Column | Type | Description |
|--------|------|-------------|
| ad_balance | decimal(12,2) NOT NULL DEFAULT 0 | Prepaid ad escrow balance |

**Frontend:** Update `Wallet.fromJson()` in `lib/models/wallet_models.dart` to parse `ad_balance` field.

### 2.2 Ad Serving Engine

#### AdServingService (Laravel)

New static-method service at `app/Services/AdServingService.php`.

**`serve(string $placement, int $userId, int $count = 1): array`**

Selection algorithm:
1. Query `ad_campaigns` WHERE `status = 'active'` AND `placements @> '["<placement>"]'` AND `start_date <= today` AND (`end_date IS NULL OR end_date >= today`) AND `spent_amount < total_budget`
2. Filter by daily budget: join with today's `ad_impressions` SUM(revenue) grouped by campaign_id, exclude campaigns where daily spend >= daily_budget
3. Filter by targeting: match user's region (from profile), age (from DOB), interests, gender against campaign `targeting` jsonb
4. Filter by frequency cap: exclude campaigns where user has >= 3 impressions today (query `ad_impressions` for `user_id + campaign_id + today`)
5. Rank by `bid_amount` DESC (highest bidder wins — simple first-price auction)
6. Take top N campaigns, join with `ad_creatives` WHERE `approved = true` AND format matches placement
7. If fewer than `count` results: mark remaining slots as `source: 'admob'` (frontend handles AdMob SDK call)
8. Return array of ad objects

**Response format:**
```json
[
  {
    "id": 123,
    "creative_id": 456,
    "source": "self_serve",
    "format": "image",
    "media_url": "https://storage.../ad_creative.jpg",
    "headline": "Nunua sasa!",
    "body_text": "Bidhaa bora kwa bei nzuri",
    "cta_type": "shop_now",
    "cta_url": "https://...",
    "campaign_type": "cpm",
    "product_id": null,
    "placement": "feed"
  },
  {
    "id": 0,
    "source": "admob",
    "placement": "feed"
  }
]
```

**`recordEvent(int $campaignId, int $creativeId, int $userId, string $placement, string $eventType, string $source): void`**

1. Insert into `ad_impressions`
2. If `source = 'self_serve'`:
   - Calculate revenue: CPM → `bid_amount / 1000` for impressions. CPC → `bid_amount` for clicks only.
   - **Atomic budget update** (prevents overspend race condition):
     ```sql
     UPDATE ad_campaigns
     SET spent_amount = spent_amount + :revenue
     WHERE id = :campaign_id
       AND spent_amount + :revenue <= total_budget
     RETURNING spent_amount, total_budget;
     ```
     If no rows affected (budget exhausted), skip billing and set `status = 'completed'`.
   - **Atomic balance deduction** (prevents negative balance):
     ```sql
     UPDATE wallets
     SET ad_balance = ad_balance - :revenue
     WHERE user_id = :advertiser_id
       AND ad_balance >= :revenue;
     ```
     If no rows affected, skip (campaign auto-pauses on next serve cycle).
   - Insert into `platform_revenue_ledger` with type `ad_cpm` or `ad_cpc`
3. If `spent_amount >= total_budget` after update: set `status = 'completed'`

**`recordAdMobRevenue(int $userId, string $placement, float $estimatedRevenue): void`**

1. Insert into `ad_impressions` with `source = 'admob'`, `campaign_id = 0`
2. Insert into `platform_revenue_ledger` with type `ad_admob` (distinct from `ad_cpm`/`ad_cpc` which are self-serve only)

#### API Endpoints

| Method | Path | Auth | Description |
|--------|------|------|-------------|
| GET | `/api/ads/serve` | Bearer token | `?placement=feed&count=3` — returns ads for placement |
| POST | `/api/ads/event` | Bearer token | `{creative_id, campaign_id, event_type, placement, source}` — record event |
| POST | `/api/ads/admob-revenue` | Bearer token | `{placement, estimated_revenue}` — record AdMob revenue callback |

#### Biashara API Endpoints (BiasharaController)

| Method | Path | Auth | Description |
|--------|------|------|-------------|
| GET | `/api/biashara/campaigns` | Bearer token | List advertiser's campaigns |
| POST | `/api/biashara/campaigns` | Bearer token | Create draft campaign |
| GET | `/api/biashara/campaigns/{id}` | Bearer token | Campaign detail with creatives |
| PUT | `/api/biashara/campaigns/{id}` | Bearer token | Update draft campaign |
| POST | `/api/biashara/campaigns/{id}/creatives` | Bearer token | Upload creative (multipart) |
| POST | `/api/biashara/campaigns/{id}/submit` | Bearer token | Submit for review |
| POST | `/api/biashara/campaigns/{id}/pause` | Bearer token | Pause active campaign |
| POST | `/api/biashara/campaigns/{id}/resume` | Bearer token | Resume paused campaign |
| POST | `/api/biashara/campaigns/{id}/cancel` | Bearer token | Cancel and refund remaining budget |
| GET | `/api/biashara/campaigns/{id}/performance` | Bearer token | Get impressions, clicks, spend |
| GET | `/api/biashara/balance` | Bearer token | Get current ad_balance |
| POST | `/api/biashara/deposit` | Bearer token | Deposit funds to ad escrow. Request: `{amount: float, payment_method: "wallet"|"mobile_money"}`. Response: `{success: true, gross: float, fee: float, fee_pct: float, net_credited: float, new_balance: float}`. The response includes the fee breakdown so the frontend can show confirmation before final submission (use a two-step flow: preview then confirm). |
| GET | `/api/biashara/settings` | Bearer token | Get client-facing ad settings (frequencies, etc.) |

**Validation rules for campaign creation:**

| Field | Rule |
|-------|------|
| title | Required, max 100 chars |
| campaign_type | Required, in: cpm, cpc |
| daily_budget | Required, min 1000 TZS |
| total_budget | Required, min 5000 TZS, >= daily_budget |
| bid_amount | Required, min 100 TZS (CPM) or min 50 TZS (CPC) |
| start_date | Required, >= today |
| end_date | Nullable, > start_date |
| placements | Required, non-empty array, values in: feed, stories, music, search, marketplace |
| targeting | Optional, validated: age_min 13-100, age_max > age_min, regions array of valid TZ regions |

**Campaign status transitions (state machine):**
```
draft → pending_review (on submit, requires at least 1 approved creative)
pending_review → active (admin approve)
pending_review → rejected (admin reject)
rejected → draft (advertiser edits and resubmits)
active → paused (advertiser or auto when daily budget hit)
paused → active (advertiser resume, or next day for daily budget pause)
active → completed (spent_amount >= total_budget or end_date passed)
draft|pending_review|active|paused → cancelled (advertiser cancel)
```

**Campaign cancellation refund:**
- Refund `total_budget - spent_amount` back to `ad_balance` (not original payment method)
- Platform fee on initial deposit is NOT refunded
- Only `draft`, `pending_review`, `active`, `paused` can be cancelled
- `completed` and `rejected` cannot be cancelled

### 2.3 Advertiser In-App Experience ("Biashara")

New screens in the Flutter app under `lib/screens/biashara/`.

#### Models

**`lib/models/ad_models.dart`** (new):

```dart
class AdCampaign {
  final int id;
  final String title;
  final String? description;
  final String campaignType; // 'cpm' or 'cpc'
  final String status; // draft, pending_review, active, paused, completed, rejected
  final double dailyBudget;
  final double totalBudget;
  final double spentAmount;
  final double bidAmount;
  final String startDate;
  final String? endDate;
  final Map<String, dynamic> targeting;
  final List<String> placements;
  final String? rejectionReason;
  final List<AdCreative> creatives;
  final DateTime createdAt;

  // fromJson, toJson
}

class AdCreative {
  final int id;
  final int campaignId;
  final String format; // image, video, audio, promoted_product, promoted_search
  final String? mediaUrl;
  final String headline;
  final String? bodyText;
  final String ctaType;
  final String ctaUrl;
  final int? productId;
  final bool approved;

  // fromJson, toJson
}

class AdPerformance {
  final int impressions;
  final int clicks;
  final double ctr;
  final double spent;
  final double remainingBudget;
  final List<DailyAdStat> dailyStats;

  // fromJson
}

class DailyAdStat {
  final String date;
  final int impressions;
  final int clicks;
  final double spent;

  // fromJson
}

class ServedAd {
  final int id;
  final int creativeId;
  final String source; // 'self_serve' or 'admob'
  final String? format;
  final String? mediaUrl;
  final String? headline;
  final String? bodyText;
  final String? ctaType;
  final String? ctaUrl;
  final String? campaignType;
  final int? productId;
  final String placement;

  // fromJson
}
```

#### Service

**`lib/services/ad_service.dart`** (new):

Static methods following existing service patterns.

| Method | Description |
|--------|-------------|
| `getMyAdCampaigns(String token)` | List advertiser's campaigns |
| `getAdCampaign(String token, int id)` | Campaign detail with creatives |
| `createAdCampaign(String token, Map data)` | Create draft campaign |
| `updateAdCampaign(String token, int id, Map data)` | Update draft campaign |
| `uploadAdCreative(String token, int campaignId, File media, Map fields)` | Upload creative asset |
| `submitForReview(String token, int id)` | Change status to pending_review |
| `pauseCampaign(String token, int id)` | Pause active campaign |
| `resumeCampaign(String token, int id)` | Resume paused campaign |
| `cancelCampaign(String token, int id)` | Cancel and refund remaining budget |
| `getCampaignPerformance(String token, int id)` | Get impressions, clicks, spend stats |
| `getAdBalance(String token)` | Get current ad_balance |
| `depositAdBalance(String token, double amount, String paymentMethod)` | Add funds to ad escrow |
| `getServedAds(String token, String placement, int count)` | Fetch ads for a placement |
| `recordAdEvent(String token, Map eventData)` | Report impression/click/skip |
| `reportAdMobRevenue(String token, String placement, double revenue)` | Report AdMob callback revenue |

#### Screens

**`lib/screens/biashara/biashara_home_screen.dart`** — Main advertiser dashboard
- Ad balance card with "Ongeza Fedha" (Add Funds) button
- Today's summary: impressions, clicks, spend
- Campaign list with status badges (color-coded)
- FAB: "Unda Tangazo" (Create Ad)
- Route: `/biashara`

**`lib/screens/biashara/create_ad_campaign_screen.dart`** — Step-by-step wizard
- Step 1: Campaign type selector (CPM "Macho" / CPC "Kubofya")
- Step 2: Creative upload (image picker, video picker) + headline + body + CTA dropdown
- Step 3: Targeting (region multi-select from TZ regions, age range slider, interests chips, gender)
- Step 4: Placements (checkboxes with Swahili labels: Habari, Hadithi, Muziki, Tafuta, Duka, Klipu, Kabla ya Video, Ujumbe, Maoni, Matangazo ya Moja kwa Moja, Hashtag)
- Step 5: Budget (daily budget input, total budget input, bid amount input, date pickers)
- Step 6: Review summary + "Wasilisha" (Submit) button
- Payment: deducted from ad_balance. If insufficient, prompt to deposit first.
- Route: `/biashara/create`

**`lib/screens/biashara/campaign_detail_screen.dart`** — Campaign performance
- Status badge + pause/resume/cancel actions
- Performance cards: impressions, clicks, CTR, spend, remaining budget
- Daily spend bar chart (last 7/14/30 days toggle)
- Creative preview carousel
- Route: `/biashara/campaign/:id`

**`lib/screens/biashara/deposit_ad_balance_screen.dart`** — Fund ad wallet
- Amount input with preset buttons (10K, 25K, 50K, 100K TZS)
- Payment method: wallet transfer or mobile money
- Confirmation with fee disclosure (25% platform fee shown)
- Route: `/biashara/deposit`

**Empty states:**
- BiasharaHomeScreen with 0 campaigns: illustration + "Huna matangazo bado" (No ads yet) + prominent "Unda Tangazo" CTA
- CampaignDetailScreen loading: skeleton shimmer cards for metrics + chart area
- CampaignDetailScreen with 0 impressions: "Tangazo lako bado halijaonyeshwa" (Your ad hasn't been shown yet) + explanation text

#### Swahili UI Strings (added to AppStrings)

| Key | Swahili | English |
|-----|---------|---------|
| biashara | Biashara | Business |
| tangaza | Tangaza Biashara Yako | Promote Your Business |
| undaTangazo | Unda Tangazo | Create Ad |
| macho | Macho (CPM) | Views (CPM) |
| kubofya | Kubofya (CPC) | Clicks (CPC) |
| bajeti | Bajeti ya Kila Siku | Daily Budget |
| bajetiJumla | Bajeti Jumla | Total Budget |
| wasilisha | Wasilisha kwa Uhakiki | Submit for Review |
| inasubiri | Inasubiri Uhakiki | Pending Review |
| tangazoHali | Hali ya Tangazo | Campaign Status |
| ongezaFedha | Ongeza Fedha za Matangazo | Add Ad Funds |
| imedhaminiwa | Imedhaminiwa | Sponsored |
| tangazo | Tangazo | Ad |
| habari | Habari | Feed |
| hadithi | Hadithi | Stories |
| muziki | Muziki | Music |
| tafuta | Tafuta | Search |
| duka | Duka | Shop |

### 2.4 Ad Surfaces (5 Placements)

#### 2.4.1 Feed Native Ads (`placement: 'feed'`)

**File:** `lib/screens/feed/feed_screen.dart`

**Changes:**
- Add `nativeAd` to the `_FeedItemType` enum
- In `_buildFeedItems()`, insert a `_FeedItemType.nativeAd` entry every N posts (N from `platform_settings` key `ad_feed_frequency`, default 10). **Note:** existing `teaser` items (rabbit hole mechanic) already interrupt every ~10 posts. Ads and teasers should not collide — if a teaser occupies a slot, skip the ad for that position and insert at the next eligible slot.
- On build, call `AdService.getServedAds(token, 'feed', count)` to prefetch ads
- In the `itemBuilder` switch, add case for `nativeAd`:
  - If `source == 'self_serve'`: render `NativeAdCard` widget
  - If `source == 'admob'`: render AdMob `NativeAd` widget

**New widget: `lib/widgets/native_ad_card.dart`**

Renders like a `PostCard` but with:
- "Tangazo" badge (top-right, subtle gray)
- Creative image/video (same aspect ratio as post media)
- Headline text (bold, 16sp)
- Body text (regular, 14sp, max 2 lines)
- CTA button (ElevatedButton, primary color, cta_type label)
- On impression: `AdService.recordAdEvent(...)` with `event_type: 'impression'`
- On tap/CTA: `AdService.recordAdEvent(...)` with `event_type: 'click'`, then launch URL

#### 2.4.2 Story Ads (`placement: 'stories'`)

**File:** `lib/screens/clips/storyviewer_screen.dart`

**Changes:**
- In `_nextGroup()`, before advancing to next group:
  - Check frequency: show ad every N group transitions (N from `ad_story_frequency`, default 3)
  - Call `AdService.getServedAds(token, 'stories', 1)`
  - If self-serve: push `StoryAdOverlay` widget (full-screen image/video)
  - If admob: show AdMob interstitial ad
- `StoryAdOverlay`: full-screen creative, "Tangazo" label top-left, 5-second countdown before skip button appears, CTA button bottom-center

**New widget: `lib/widgets/story_ad_overlay.dart`**

- Full-bleed image or video
- 5-second timer before "Ruka" (Skip) button appears
- "Tangazo" label (top-left, semi-transparent background)
- CTA button (bottom-center)
- Record impression on display, click on CTA tap, skip on skip

#### 2.4.3 Music Interstitials (`placement: 'music'`)

**File:** `lib/screens/music/music_player_sheet.dart`

**Changes:**
- Track a counter: `_tracksSinceLastAd`
- In `processingStateStream` listener, when track completes:
  - Increment counter
  - If counter >= N (N from `ad_music_frequency`, default 4):
    - Pause playback
    - Call `AdService.getServedAds(token, 'music', 1)`
    - If self-serve: show `MusicAdOverlay` (visual overlay on player sheet)
    - If admob: show AdMob interstitial
    - Reset counter to 0
    - Resume playback after ad completes/skipped

**New widget: `lib/widgets/music_ad_overlay.dart`**

- Overlay on top of music player sheet
- Creative image with headline and CTA
- 5-second countdown, then "Ruka" (Skip) button
- "Tangazo" badge
- Record impression/click/skip events

#### 2.4.4 Search/Discover Promoted Results (`placement: 'search'`)

**File:** `lib/screens/search/search_screen.dart`, `lib/screens/feed/discover_feed_content.dart`

**Changes to search_screen.dart:**
- After search results load, call `AdService.getServedAds(token, 'search', 2)`
- Insert promoted results at positions 0 and 3 in the results list
- Promoted results have "Imedhaminiwa" badge
- Uses `promoted_search` creative format

**Changes to discover_feed_content.dart:**
- Refactor trending section to use `SliverList.builder` instead of spread operator
- Insert promoted card at position 0 in discover grid
- Same "Imedhaminiwa" badge

#### 2.4.5 Marketplace Promoted Listings (`placement: 'marketplace'`)

**File:** `lib/screens/shop/shop_screen.dart`

**Changes:**
- After product list loads, call `AdService.getServedAds(token, 'marketplace', 2)`
- Insert promoted products at positions 0 and 5 in the product grid
- Promoted products linked via `product_id` to real shop products
- "Imedhaminiwa" badge on product card
- On tap: navigate to product detail (same as organic), record click event

#### 2.4.6 Video Pre-Roll Ads (`placement: 'video_preroll'`)

**File:** `lib/widgets/video_player_widget.dart`

**Changes:**
- Before video initialization completes (lines 119-134), check if a pre-roll ad is available
- Call `AdService.getServedAds(token, 'video_preroll', 1)` on widget init
- If ad available: show 3-5 second sponsor overlay before video plays (image + countdown)
- If admob: show AdMob interstitial before video
- After ad completes/skipped: proceed with video playback
- Frequency: max 1 pre-roll per 3 videos watched per session (tracked client-side)

**New widget: `lib/widgets/video_preroll_overlay.dart`**

- Overlay covering video player area
- Creative image/short video (max 5s)
- "Tangazo" label top-left
- Countdown timer (3s) then "Ruka" (Skip) button
- "Video inaanza..." (Video starting...) text below countdown
- Record impression on display, skip on skip

#### 2.4.7 Clips/Reels Ads (`placement: 'clips'`)

**File:** `lib/screens/clips/clips_screen.dart`

**Changes:**
- In PageView.builder (line 21-74), intercept `_onPageChanged`
- Every N clips (N from `ad_clips_frequency`, default 5): replace next page with full-screen ad
- Ad renders as a sponsored clip (same full-screen format)
- If admob: show interstitial between clips

**Reuses:** `StoryAdOverlay` widget (same full-screen format)

#### 2.4.8 Conversations List Ads (`placement: 'conversations'`)

**File:** `lib/screens/messages/conversations_screen.dart`

**Changes:**
- In ListView.builder (line 955), insert ad card after every N conversations (N from `ad_conversations_frequency`, default 5)
- Ad renders as a business/brand chat card with avatar, name, and "Tangazo" badge
- On tap: opens CTA URL (not a real chat)

**New widget: `lib/widgets/conversation_ad_card.dart`**

- Same visual structure as conversation tile (avatar, name, preview text)
- "Tangazo" badge instead of timestamp
- Brand avatar + headline as "message preview"
- CTA on tap (open URL)

#### 2.4.9 Comments Ads (`placement: 'comments'`)

**File:** `lib/screens/feed/comment_bottom_sheet.dart`

**Changes:**
- In ListView.builder (line 623), insert ad card after every N comments (N = 8, hardcoded)
- Ad renders as a native card slightly differentiated from comments (subtle background, "Tangazo" label)
- Must not look like a fake comment — use card format, not bubble format

**Reuses:** `NativeAdCard` widget (compact variant with reduced padding)

#### 2.4.10 Live Stream Ads (`placement: 'live_stream'`)

**File:** `lib/screens/clips/streamviewer_screen.dart`

**Changes:**
- Before joining stream (line 180+): show 3-5s full-screen ad ("Tangazo kabla ya kuangalia..." — Ad before watching)
- During stream: subtle sponsor badge overlay (bottom-left, semi-transparent, "Imetolewa na [Brand]" — Brought to you by [Brand])
- Badge loads from `AdService.getServedAds(token, 'live_stream', 1)` on stream join

**New widget: `lib/widgets/stream_sponsor_badge.dart`**

- Small semi-transparent card (120x40dp) positioned bottom-left
- Brand logo/name + "Imetolewa na" text
- Non-intrusive, does not block stream content
- On tap: opens CTA URL
- Impression recorded once on display

#### 2.4.11 Hashtag Feed Ads (`placement: 'hashtag'`)

**File:** `lib/screens/search/hashtag_screen.dart`

**Changes:**
- In ListView.builder (line 61-108), insert native ad card after every N posts (N = 6, hardcoded)
- Ad contextually labeled: "Tangazo katika #[hashtag]" (Ad in #[hashtag])

**Reuses:** `NativeAdCard` widget

### 2.5 AdMob Integration

**Package:** Add `google_mobile_ads: ^5.0.0` to `pubspec.yaml`.

**New service: `lib/services/admob_service.dart`**

```dart
class AdMobService {
  static const String _nativeAdUnitId = '...'; // From platform_settings or remote config
  static const String _interstitialAdUnitId = '...';

  static Future<NativeAd?> loadNativeAd(String placement);
  static Future<InterstitialAd?> loadInterstitialAd();
  static void onAdRevenuePaid(Ad ad, String placement);
  // onAdRevenuePaid calls AdService.reportAdMobRevenue() to track server-side
}
```

**Initialization:** In `main.dart`, call `MobileAds.instance.initialize()` on app start.

**Ad unit IDs:** Stored in `platform_settings` as `admob_native_unit_id` and `admob_interstitial_unit_id`. Fetched at app start and cached locally. For development, use AdMob test ad unit IDs.

**Revenue tracking:** AdMob SDK provides `onPaidEvent` callback with estimated revenue. This is sent to the backend via `/api/ads/admob-revenue` for ledger tracking.

**Important limitation:** `onPaidEvent` fires asynchronously and not for every impression. The platform_revenue_ledger will undercount AdMob revenue. The AdMob console dashboard is the source of truth for AdMob revenue; the ledger provides an approximation for the admin dashboard. Monthly reconciliation against the AdMob dashboard is recommended.

### 2.6a Client Settings Delivery

Ad frequency settings and AdMob unit IDs need to reach the Flutter frontend. The `/api/biashara/settings` endpoint returns client-facing settings:

```json
{
  "ad_feed_frequency": 10,
  "ad_story_frequency": 3,
  "ad_music_frequency": 4,
  "admob_native_unit_id": "ca-app-pub-xxx",
  "admob_interstitial_unit_id": "ca-app-pub-xxx",
  "ad_frequency_cap_per_campaign": 3
}
```

Frontend fetches these on app startup and caches locally via `LocalStorageService`. Refreshed every 24 hours or on force-refresh.

### 2.6 Frequency Capping & User Experience

| Rule | Value | Configurable |
|------|-------|-------------|
| Max impressions per user per campaign per day | 3 | `ad_frequency_cap_per_campaign` |
| Feed ad spacing | Every 10 posts | `ad_feed_frequency` |
| Story ad spacing | Every 3 group transitions | `ad_story_frequency` |
| Music ad spacing | Every 4 tracks | `ad_music_frequency` |
| Clips ad spacing | Every 5 clips | `ad_clips_frequency` |
| Conversations ad spacing | Every 5 chats | `ad_conversations_frequency` |
| Video pre-roll frequency | 1 per 3 videos/session | Client-side counter |
| Comments ad spacing | Every 8 comments | Hardcoded |
| Hashtag feed ad spacing | Every 6 posts | Hardcoded |
| Search promoted results | Max 2 per search | Hardcoded |
| Marketplace promoted products | Max 2 per page load | Hardcoded |
| Live stream pre-join ad | 1 per stream join | Hardcoded |
| Live stream sponsor badge | 1 per stream | Hardcoded |
| Story/clip/video ad skip delay | 5 seconds | Hardcoded |
| Music ad skip delay | 5 seconds | Hardcoded |

### 2.7 Ad Escrow Payment Flow

1. Advertiser navigates to "Ongeza Fedha za Matangazo" (Deposit Ad Balance)
2. Enters amount, selects payment method (wallet or mobile money)
3. Platform fee (25%) disclosed: "Kati ya 10,000 TZS, 2,500 TZS ni ada ya jukwaa" (Of 10,000 TZS, 2,500 TZS is platform fee)
4. Payment processed:
   - `PlatformFeeService::applyFee('ad_deposit', amount, ...)` records the fee (uses `fee_ad_deposit_pct`)
   - Net amount credited to user's `ad_balance`
5. When campaign runs, daily spend deducted from `ad_balance`
6. On campaign cancellation, remaining `ad_balance` portion for that campaign refunded

---

## 3. Revenue Admin Dashboard

### Goal

Server-rendered Laravel Blade web panel for monitoring platform revenue, managing settings, reviewing ad campaigns, and distributing the Creator Fund.

### 3.1 Tech Stack

- **Laravel Blade** templates with `@extends('admin.layout')`
- **Tailwind CSS** for styling (Laravel ships with it via Vite)
- **Chart.js v4** via CDN for interactive charts
- **Alpine.js** via CDN for date pickers, dropdowns, inline editing
- No SPA framework — server-rendered with progressive enhancement

### 3.2 Authentication & Access

- Route group: `Route::prefix('admin/revenue')->middleware(['auth:web', 'role:admin'])`
- Admin users identified by `is_admin` column on `users` table (or existing role mechanism)
- Session-based auth (standard Laravel web guard), not API tokens

### 3.3 Pages

#### 3.3.1 Revenue Overview (`/admin/revenue`)

**Metric cards (top row):**

| Card | Calculation |
|------|-------------|
| Total Revenue (this month) | `platform_revenue_ledger` SUM(fee_amount) WHERE created_at in current month |
| Creator Fund Pool | Total Revenue × `fund_allocation_pct / 100` |
| Operations Budget | Total Revenue × `operations_allocation_pct / 100` |
| Margin | Total Revenue × `margin_allocation_pct / 100` |
| Revenue vs Last Month | `((this_month - last_month) / last_month) × 100` % change |
| Active Ad Campaigns | `ad_campaigns` WHERE status='active' COUNT |

**Charts:**
- **Line chart:** Daily revenue over last 30 days, stacked by source (transaction fees, self-serve ads, AdMob)
- **Donut chart:** Revenue breakdown by transaction_type (subscription, tip, marketplace, michango, sponsored, ad_cpm, ad_cpc, ad_admob)
- **Bar chart:** Monthly revenue trend, last 12 months

**Data source:** Materialized view `mv_daily_revenue` refreshed hourly via Laravel scheduler:
```sql
CREATE MATERIALIZED VIEW mv_daily_revenue AS
SELECT
  DATE(created_at) as day,
  transaction_type,
  SUM(fee_amount) as total_fee,
  COUNT(*) as transaction_count
FROM platform_revenue_ledger
GROUP BY DATE(created_at), transaction_type;
```

#### 3.3.2 Fee Revenue Detail (`/admin/revenue/fees`)

**Filters:** Date range (last 7/30/90 days, custom), transaction type dropdown.

**Table:** Paginated `platform_revenue_ledger` entries:

| Date | Type | Gross (TZS) | Fee % | Fee Amount (TZS) | Net to Creator (TZS) | Reference |
|------|------|-------------|-------|-------------------|----------------------|-----------|

**Summary row:** Column totals for filtered results.

**Export:** CSV download via `/admin/revenue/fees/export?from=&to=&type=`.

#### 3.3.3 Ad Revenue Detail (`/admin/revenue/ads`)

**Top metric cards:**

| Metric | Source |
|--------|--------|
| Self-serve revenue (month) | `ad_impressions` WHERE source='self_serve' SUM(revenue) |
| AdMob revenue (month) | `ad_impressions` WHERE source='admob' SUM(revenue) |
| Fill rate | self_serve impressions / total ad slots served × 100 |
| Total impressions (month) | COUNT(*) WHERE event_type='impression' |
| Total clicks (month) | COUNT(*) WHERE event_type='click' |
| Average CTR | clicks / impressions × 100 |

**Charts:**
- **Line chart:** Daily ad revenue (self-serve vs AdMob, stacked)
- **Bar chart:** Revenue by placement (feed, stories, music, search, marketplace)

**Table:** Top 10 campaigns by spend this month (campaign title, advertiser, type, impressions, clicks, CTR, spend).

#### 3.3.4 Creator Fund (`/admin/revenue/fund`)

**Metric cards:**

| Metric | Calculation |
|--------|-------------|
| This month's pool size | Total month revenue × `fund_allocation_pct / 100` |
| Distributed this month | SUM of `creator_fund_payouts` this month WHERE status='paid' |
| Pending distribution | Pool size - distributed |
| Eligible creators | COUNT of creators with qualifying scores |

**Table:** Creator fund payouts with: creator name, tier, base score, multipliers (streak, community, virality), final score, payout amount, status.

**Action button:** "Distribute Fund" — POST to `/admin/revenue/fund/distribute`. Triggers the existing monthly fund distribution logic, allocating `fund_allocation_pct` of this month's total platform revenue across eligible creators based on their scores.

**Distribution guard:** The backend tracks `last_fund_distribution_at` in `platform_settings`. The "Distribute Fund" button is disabled if a distribution has already been run for the current month. The POST endpoint returns 409 Conflict if `last_fund_distribution_at` is within the current calendar month, preventing double-distribution.

#### 3.3.5 Platform Settings (`/admin/revenue/settings`)

Editable table of all `platform_settings` rows:

| Key | Value | Description | Last Updated | Action |
|-----|-------|-------------|-------------|--------|
| fee_subscription_pct | 15.0 | Subscription fee % | 2026-03-29 | [Edit] |
| ad_feed_frequency | 10 | Posts between feed ads | 2026-03-29 | [Edit] |
| admob_native_unit_id | ca-app-pub-xxx | AdMob native unit | 2026-03-29 | [Edit] |

Inline edit via Alpine.js: click [Edit], field becomes input, save button appears. On save: PUT to `/admin/revenue/settings`, cache busted.

**Setting categories** (grouped with headers):
- Fee Percentages (fee_*)
- Revenue Allocation (fund_*, operations_*, margin_*)
- Ad Frequency (ad_*_frequency)
- Ad Configuration (admob_*, ad_frequency_cap_*)

#### 3.3.6 Advertiser Review Queue (`/admin/revenue/review`)

**Table:** Campaigns with `status: pending_review`:

| Advertiser | Campaign | Type | Budget (TZS) | Placements | Creatives | Actions |
|-----------|----------|------|--------------|------------|-----------|---------|
| Name | Title | CPM | 50,000 | Feed, Stories | [Preview] | [Approve] [Reject] |

**[Preview]:** Opens modal showing creative assets with headline, body, CTA as they would appear in each selected placement.

**[Approve]:** POST sets `status = 'active'`, `ad_creatives.approved = true`. Sends push notification to advertiser.

**[Reject]:** Opens modal for rejection reason. POST sets `status = 'rejected'`, stores `rejection_reason`. Sends push notification to advertiser with reason.

### 3.4 Route Structure

```php
Route::prefix('admin/revenue')->middleware(['auth:web', 'role:admin'])->group(function () {
    Route::get('/', [RevenueController::class, 'overview']);
    Route::get('/fees', [RevenueController::class, 'fees']);
    Route::get('/fees/export', [RevenueController::class, 'exportFees']);
    Route::get('/ads', [RevenueController::class, 'ads']);
    Route::get('/fund', [RevenueController::class, 'fund']);
    Route::post('/fund/distribute', [RevenueController::class, 'distributeFund']);
    Route::get('/settings', [RevenueController::class, 'settings']);
    Route::put('/settings', [RevenueController::class, 'updateSettings']);
    Route::get('/review', [RevenueController::class, 'reviewQueue']);
    Route::post('/review/{id}/approve', [RevenueController::class, 'approveCampaign']);
    Route::post('/review/{id}/reject', [RevenueController::class, 'rejectCampaign']);
});
```

### 3.5 Controller

**`app/Http/Controllers/Admin/RevenueController.php`** (new)

Single controller with methods mapping to each route. Each method:
1. Queries relevant data (using `PlatformFeeService::getRevenueReport()` or direct DB queries)
2. Returns Blade view with data

### 3.6 Performance Considerations

- **Materialized view** `mv_daily_revenue` for overview page — refreshed hourly via `$schedule->command('db:refresh-revenue-views')->hourly()`
- **Ad impressions partitioned** by month — queries always include date range filter to enable partition pruning
- **Settings cached** 1 hour — admin updates bust cache immediately
- **Pagination** on all detail tables (25 rows per page)
- **CSV export** streams response (no memory bloat for large date ranges)

---

## 4. New Routes in main.dart

| Route | Screen | Description |
|-------|--------|-------------|
| `/biashara` | BiasharaHomeScreen | Advertiser dashboard |
| `/biashara/create` | CreateAdCampaignScreen | Create ad wizard |
| `/biashara/campaign/:id` | CampaignDetailScreen | Campaign performance |
| `/biashara/deposit` | DepositAdBalanceScreen | Add ad funds |

---

## 5. New Files Summary

### Backend (Laravel)

| File | Type | Description |
|------|------|-------------|
| `database/migrations/xxx_create_platform_settings_table.php` | Migration | Settings KV store |
| `database/migrations/xxx_create_platform_revenue_ledger_table.php` | Migration | Revenue ledger |
| `database/migrations/xxx_create_ad_campaigns_table.php` | Migration | Ad campaigns |
| `database/migrations/xxx_create_ad_creatives_table.php` | Migration | Ad creatives |
| `database/migrations/xxx_create_ad_impressions_table.php` | Migration | Partitioned impressions |
| `database/migrations/xxx_add_ad_balance_to_wallets.php` | Migration | Ad escrow balance column |
| `database/seeders/PlatformSettingsSeeder.php` | Seeder | Default fee/ad settings |
| `app/Models/PlatformSetting.php` | Model | |
| `app/Models/PlatformRevenueLedger.php` | Model | |
| `app/Models/AdCampaign.php` | Model | |
| `app/Models/AdCreative.php` | Model | |
| `app/Models/AdImpression.php` | Model | |
| `app/Services/PlatformFeeService.php` | Service | Fee calculation + settings |
| `app/Services/AdServingService.php` | Service | Ad selection + event recording |
| `app/Http/Controllers/Api/AdController.php` | Controller | API: serve, event, admob-revenue |
| `app/Http/Controllers/Api/BiasharaController.php` | Controller | API: campaign CRUD, deposit |
| `app/Http/Controllers/Admin/RevenueController.php` | Controller | Web: admin dashboard |
| `resources/views/admin/revenue/*.blade.php` | Views | 6 Blade templates |
| `routes/web.php` | Routes | Admin revenue routes |
| `routes/api.php` | Routes | Ad serving + biashara API routes |

### Frontend (Flutter)

| File | Type | Description |
|------|------|-------------|
| `lib/models/ad_models.dart` | Model | AdCampaign, AdCreative, ServedAd, etc. |
| `lib/services/ad_service.dart` | Service | Campaign CRUD + ad serving |
| `lib/services/admob_service.dart` | Service | Google AdMob SDK wrapper |
| `lib/screens/biashara/biashara_home_screen.dart` | Screen | Advertiser dashboard |
| `lib/screens/biashara/create_ad_campaign_screen.dart` | Screen | Create ad wizard |
| `lib/screens/biashara/campaign_detail_screen.dart` | Screen | Campaign performance |
| `lib/screens/biashara/deposit_ad_balance_screen.dart` | Screen | Fund ad wallet |
| `lib/widgets/native_ad_card.dart` | Widget | Feed/comments/hashtag native ad card |
| `lib/widgets/story_ad_overlay.dart` | Widget | Full-screen story/clips ad |
| `lib/widgets/music_ad_overlay.dart` | Widget | Music player ad overlay |
| `lib/widgets/video_preroll_overlay.dart` | Widget | Video pre-roll ad overlay |
| `lib/widgets/conversation_ad_card.dart` | Widget | Chat-list-style ad card |
| `lib/widgets/stream_sponsor_badge.dart` | Widget | Live stream sponsor badge |

### Modified Files

| File | Change |
|------|--------|
| `lib/screens/feed/feed_screen.dart` | Add nativeAd to _FeedItemType, insert ads |
| `lib/screens/clips/storyviewer_screen.dart` | Insert story ads in _nextGroup() |
| `lib/screens/music/music_player_sheet.dart` | Insert music ads between tracks |
| `lib/screens/search/search_screen.dart` | Insert promoted search results |
| `lib/screens/feed/discover_feed_content.dart` | Insert promoted discover cards |
| `lib/screens/shop/shop_screen.dart` | Insert promoted product listings |
| `lib/screens/clips/clips_screen.dart` | Insert ads between clips |
| `lib/widgets/video_player_widget.dart` | Insert video pre-roll ads |
| `lib/screens/messages/conversations_screen.dart` | Insert ads in chat list |
| `lib/screens/feed/comment_bottom_sheet.dart` | Insert ads in comments |
| `lib/screens/clips/streamviewer_screen.dart` | Pre-join ad + sponsor badge |
| `lib/screens/search/hashtag_screen.dart` | Insert ads in hashtag feed |
| `lib/l10n/app_strings.dart` | Add ~18 biashara/ad Swahili strings |
| `lib/main.dart` | Add /biashara routes |
| `pubspec.yaml` | Add google_mobile_ads dependency |

---

## 6. Implementation Phases

**Phase 1: Platform Fees** (backend only)
- Migrations, PlatformFeeService, integration into existing payment handlers
- Immediate revenue capture

**Phase 2: Ad System Backend**
- Ad data model, AdServingService, API endpoints, BiasharaController

**Phase 3: Admin Dashboard**
- Blade views, RevenueController, materialized views, settings UI, review queue

**Phase 4: Ad System Frontend — Biashara Screens**
- Models, service, 4 screens, routes

**Phase 5: Ad Surfaces**
- Feed native ads, story ads, music interstitials, search promoted, marketplace promoted
- AdMob integration

Each phase is independently deployable and testable.
