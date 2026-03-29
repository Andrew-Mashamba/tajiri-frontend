# TAJIRI Commercial Monetization Layer — Implementation Plan

> **For agentic workers:** REQUIRED SUB-SKILL: Use superpowers:subagent-driven-development (recommended) or superpowers:executing-plans to implement this plan task-by-task. Steps use checkbox (`- [ ]`) syntax for tracking.

**Goal:** Build TAJIRI's revenue engine — platform fees on all transactions, self-serve ad platform with AdMob fallback across 11 surfaces, and a Laravel Blade admin dashboard for financial monitoring.

**Architecture:** Backend-first approach: fees → ad data model → ad serving → admin dashboard → frontend ad screens → ad surface integration. Each phase is independently deployable. Backend is Laravel 12 on PostgreSQL 16 at `root@172.240.241.180`. Frontend is Flutter/Dart at `/Volumes/DATA/PROJECTS/TAJIRI/TAJIRI-FRONTEND`.

**Tech Stack:** PHP 8.3, Laravel 12, PostgreSQL 16, Flutter 3.x/Dart, google_mobile_ads SDK, Chart.js v4, Tailwind CSS, Alpine.js.

**Spec:** `docs/superpowers/specs/2026-03-29-commercial-monetization-design.md`

**Server access:** `sshpass -p ZimaBlueApps ssh -o StrictHostKeyChecking=no root@172.240.241.180`
**Laravel root:** `/var/www/tajiri.zimasystems.com`

---

## Phase 1: Platform Fee System (Backend)

### Task 1: Migrations — platform_settings + platform_revenue_ledger

**Files:**
- Create: `database/migrations/2026_03_29_600001_create_platform_settings_table.php`
- Create: `database/migrations/2026_03_29_600002_create_platform_revenue_ledger_table.php`
- Create: `database/seeders/PlatformSettingsSeeder.php`

**Context:** All work on server at `/var/www/tajiri.zimasystems.com`. Connect via `sshpass -p ZimaBlueApps ssh -o StrictHostKeyChecking=no root@172.240.241.180`.

- [ ] **Step 1: Create platform_settings migration**

```php
<?php
// database/migrations/2026_03_29_600001_create_platform_settings_table.php
use Illuminate\Database\Migrations\Migration;
use Illuminate\Database\Schema\Blueprint;
use Illuminate\Support\Facades\Schema;

return new class extends Migration {
    public function up(): void
    {
        Schema::create('platform_settings', function (Blueprint $table) {
            $table->string('key', 100)->primary();
            $table->string('value', 255);
            $table->text('description')->nullable();
            $table->timestamp('updated_at')->useCurrent();
        });
    }

    public function down(): void
    {
        Schema::dropIfExists('platform_settings');
    }
};
```

- [ ] **Step 2: Create platform_revenue_ledger migration**

```php
<?php
// database/migrations/2026_03_29_600002_create_platform_revenue_ledger_table.php
use Illuminate\Database\Migrations\Migration;
use Illuminate\Database\Schema\Blueprint;
use Illuminate\Support\Facades\Schema;
use Illuminate\Support\Facades\DB;

return new class extends Migration {
    public function up(): void
    {
        Schema::create('platform_revenue_ledger', function (Blueprint $table) {
            $table->id();
            $table->string('transaction_type', 20);
            $table->unsignedBigInteger('reference_id');
            $table->string('reference_type', 50);
            $table->decimal('gross_amount', 12, 2);
            $table->decimal('fee_percentage', 5, 2);
            $table->decimal('fee_amount', 12, 2);
            $table->decimal('net_amount', 12, 2);
            $table->string('currency', 3)->default('TZS');
            $table->timestamp('created_at')->useCurrent();

            $table->index(['transaction_type', 'created_at']);
            $table->index(['reference_type', 'reference_id']);
            $table->index('created_at');
        });

        DB::statement("ALTER TABLE platform_revenue_ledger ADD CONSTRAINT chk_transaction_type CHECK (transaction_type IN ('subscription','tip','marketplace','michango','sponsored','ad_deposit','ad_cpm','ad_cpc','ad_admob'))");
    }

    public function down(): void
    {
        Schema::dropIfExists('platform_revenue_ledger');
    }
};
```

- [ ] **Step 3: Create seeder with default settings**

```php
<?php
// database/seeders/PlatformSettingsSeeder.php
namespace Database\Seeders;

use Illuminate\Database\Seeder;
use Illuminate\Support\Facades\DB;

class PlatformSettingsSeeder extends Seeder
{
    public function run(): void
    {
        $settings = [
            ['key' => 'fee_subscription_pct', 'value' => '15.0', 'description' => '% deducted from subscription payments'],
            ['key' => 'fee_tip_pct', 'value' => '10.0', 'description' => '% deducted from tips'],
            ['key' => 'fee_marketplace_pct', 'value' => '10.0', 'description' => '% deducted from marketplace sales'],
            ['key' => 'fee_michango_pct', 'value' => '5.0', 'description' => '% deducted from crowdfunding withdrawals'],
            ['key' => 'fee_sponsored_pct', 'value' => '25.0', 'description' => '% deducted from legacy sponsored post budgets'],
            ['key' => 'fee_ad_deposit_pct', 'value' => '25.0', 'description' => '% deducted from Biashara ad escrow deposits'],
            ['key' => 'fund_allocation_pct', 'value' => '30.0', 'description' => '% of platform revenue allocated to Creator Fund'],
            ['key' => 'operations_allocation_pct', 'value' => '40.0', 'description' => '% of platform revenue allocated to operations'],
            ['key' => 'margin_allocation_pct', 'value' => '30.0', 'description' => '% of platform revenue retained as margin'],
            ['key' => 'last_fund_distribution_at', 'value' => '', 'description' => 'ISO 8601 timestamp of last Creator Fund distribution'],
            ['key' => 'ad_feed_frequency', 'value' => '10', 'description' => 'Posts between feed ads'],
            ['key' => 'ad_story_frequency', 'value' => '3', 'description' => 'Story groups between ads'],
            ['key' => 'ad_music_frequency', 'value' => '4', 'description' => 'Tracks between music ads'],
            ['key' => 'ad_clips_frequency', 'value' => '5', 'description' => 'Clips between ads'],
            ['key' => 'ad_conversations_frequency', 'value' => '5', 'description' => 'Conversations between ads'],
            ['key' => 'ad_frequency_cap_per_campaign', 'value' => '3', 'description' => 'Max impressions per user per campaign per day'],
            ['key' => 'admob_native_unit_id', 'value' => 'ca-app-pub-3940256099942544/2247696110', 'description' => 'AdMob native ad unit ID (test)'],
            ['key' => 'admob_interstitial_unit_id', 'value' => 'ca-app-pub-3940256099942544/1033173712', 'description' => 'AdMob interstitial ad unit ID (test)'],
        ];

        foreach ($settings as $setting) {
            DB::table('platform_settings')->updateOrInsert(
                ['key' => $setting['key']],
                $setting
            );
        }
    }
}
```

- [ ] **Step 4: Run migrations and seeder**

```bash
cd /var/www/tajiri.zimasystems.com
php artisan migrate
php artisan db:seed --class=PlatformSettingsSeeder
```

- [ ] **Step 5: Verify**

```bash
php artisan tinker --execute="echo DB::table('platform_settings')->count() . ' settings seeded';"
php artisan tinker --execute="echo DB::table('platform_revenue_ledger')->count() . ' ledger rows (should be 0)';"
```

- [ ] **Step 6: Commit**

```bash
git add database/migrations/2026_03_29_60000* database/seeders/PlatformSettingsSeeder.php
git commit -m "feat: add platform_settings and platform_revenue_ledger tables with seed data"
```

---

### Task 2: Models — PlatformSetting + PlatformRevenueLedger

**Files:**
- Create: `app/Models/PlatformSetting.php`
- Create: `app/Models/PlatformRevenueLedger.php`

- [ ] **Step 1: Create PlatformSetting model**

```php
<?php
// app/Models/PlatformSetting.php
namespace App\Models;

use Illuminate\Database\Eloquent\Model;

class PlatformSetting extends Model
{
    protected $primaryKey = 'key';
    protected $keyType = 'string';
    public $incrementing = false;
    public $timestamps = false;

    protected $fillable = ['key', 'value', 'description', 'updated_at'];
}
```

- [ ] **Step 2: Create PlatformRevenueLedger model**

```php
<?php
// app/Models/PlatformRevenueLedger.php
namespace App\Models;

use Illuminate\Database\Eloquent\Model;

class PlatformRevenueLedger extends Model
{
    public $timestamps = false;

    protected $table = 'platform_revenue_ledger';

    protected $fillable = [
        'transaction_type', 'reference_id', 'reference_type',
        'gross_amount', 'fee_percentage', 'fee_amount', 'net_amount',
        'currency', 'created_at',
    ];

    protected $casts = [
        'gross_amount' => 'float',
        'fee_percentage' => 'float',
        'fee_amount' => 'float',
        'net_amount' => 'float',
        'created_at' => 'datetime',
    ];
}
```

- [ ] **Step 3: Commit**

```bash
git add app/Models/PlatformSetting.php app/Models/PlatformRevenueLedger.php
git commit -m "feat: add PlatformSetting and PlatformRevenueLedger Eloquent models"
```

---

### Task 3: PlatformFeeService

**Files:**
- Create: `app/Services/PlatformFeeService.php`

- [ ] **Step 1: Create PlatformFeeService**

```php
<?php
// app/Services/PlatformFeeService.php
namespace App\Services;

use App\Models\PlatformSetting;
use App\Models\PlatformRevenueLedger;
use Illuminate\Support\Facades\Cache;
use Illuminate\Support\Facades\DB;
use Carbon\Carbon;

class PlatformFeeService
{
    public static function getSetting(string $key): float
    {
        $value = Cache::remember("platform_settings.{$key}", 3600, function () use ($key) {
            return PlatformSetting::where('key', $key)->value('value');
        });

        return (float) ($value ?? 0);
    }

    public static function getSettingRaw(string $key): ?string
    {
        return Cache::remember("platform_settings.{$key}", 3600, function () use ($key) {
            return PlatformSetting::where('key', $key)->value('value');
        });
    }

    public static function applyFee(string $type, float $grossAmount, int $referenceId, string $referenceType): array
    {
        $feePct = self::getSetting("fee_{$type}_pct");
        $feeAmount = round($grossAmount * $feePct / 100, 2);
        $netAmount = round($grossAmount - $feeAmount, 2);

        PlatformRevenueLedger::create([
            'transaction_type' => $type,
            'reference_id' => $referenceId,
            'reference_type' => $referenceType,
            'gross_amount' => $grossAmount,
            'fee_percentage' => $feePct,
            'fee_amount' => $feeAmount,
            'net_amount' => $netAmount,
            'currency' => 'TZS',
            'created_at' => now(),
        ]);

        return [
            'gross' => $grossAmount,
            'fee' => $feeAmount,
            'net' => $netAmount,
            'fee_pct' => $feePct,
        ];
    }

    public static function getRevenueReport(Carbon $from, Carbon $to, ?string $type = null): array
    {
        $query = PlatformRevenueLedger::whereBetween('created_at', [$from, $to]);

        if ($type) {
            $query->where('transaction_type', $type);
        }

        $byType = (clone $query)
            ->select('transaction_type', DB::raw('SUM(gross_amount) as total_gross'), DB::raw('SUM(fee_amount) as total_fees'), DB::raw('COUNT(*) as count'))
            ->groupBy('transaction_type')
            ->get()
            ->keyBy('transaction_type')
            ->toArray();

        $totals = (clone $query)
            ->select(DB::raw('SUM(gross_amount) as total_gross'), DB::raw('SUM(fee_amount) as total_fees'), DB::raw('COUNT(*) as count'))
            ->first();

        return [
            'total_gross' => (float) ($totals->total_gross ?? 0),
            'total_fees' => (float) ($totals->total_fees ?? 0),
            'count' => (int) ($totals->count ?? 0),
            'by_type' => $byType,
        ];
    }

    public static function updateSetting(string $key, string $value): void
    {
        PlatformSetting::where('key', $key)->update([
            'value' => $value,
            'updated_at' => now(),
        ]);

        Cache::forget("platform_settings.{$key}");
    }
}
```

- [ ] **Step 2: Verify syntax**

```bash
cd /var/www/tajiri.zimasystems.com
php -l app/Services/PlatformFeeService.php
```
Expected: `No syntax errors detected`

- [ ] **Step 3: Quick smoke test**

```bash
php artisan tinker --execute="
use App\Services\PlatformFeeService;
echo 'Subscription fee: ' . PlatformFeeService::getSetting('fee_subscription_pct') . '%\n';
\$result = PlatformFeeService::applyFee('subscription', 10000, 1, 'App\\\Models\\\SubscriptionPayment');
echo 'Gross: ' . \$result['gross'] . ', Fee: ' . \$result['fee'] . ', Net: ' . \$result['net'] . '\n';
echo 'Ledger rows: ' . \App\Models\PlatformRevenueLedger::count() . '\n';
"
```
Expected: `Subscription fee: 15%`, `Gross: 10000, Fee: 1500, Net: 8500`, `Ledger rows: 1`

- [ ] **Step 4: Commit**

```bash
git add app/Services/PlatformFeeService.php
git commit -m "feat: add PlatformFeeService with getSetting, applyFee, getRevenueReport, updateSetting"
```

---

### Task 4: Integrate fees into existing payment handlers

**Files:**
- Modify: Existing payment controllers/services on the server (find the actual handler files)

**Context:** The implementer must SSH in and find the exact files where subscription payments, tips, marketplace orders, michango withdrawals, and sponsored posts are processed. Look in `app/Http/Controllers/Api/` and `app/Services/` for handlers that credit creator earnings. Add `PlatformFeeService::applyFee(...)` calls BEFORE earnings are credited.

- [ ] **Step 1: Find existing payment handlers**

```bash
cd /var/www/tajiri.zimasystems.com
grep -rn "earning\|payout\|credit.*creator\|tip.*send\|order.*complete\|withdraw.*approve" app/Http/Controllers/Api/ app/Services/ --include="*.php" -l
```

- [ ] **Step 2: For each handler found, add fee deduction**

Add `use App\Services\PlatformFeeService;` at top.

Before the line that credits the creator, insert:
```php
$feeResult = PlatformFeeService::applyFee('<type>', $amount, $referenceId, <Model>::class);
// Use $feeResult['net'] instead of $amount for creator credit
```

Where `<type>` is: `subscription`, `tip`, `marketplace`, `michango`, or `sponsored`.

- [ ] **Step 3: Verify no syntax errors**

```bash
find app/Http/Controllers/Api app/Services -name "*.php" -newer app/Services/PlatformFeeService.php -exec php -l {} \;
```

- [ ] **Step 4: Commit**

```bash
git add -A
git commit -m "feat: integrate PlatformFeeService into subscription, tip, marketplace, michango, and sponsored post handlers"
```

---

## Phase 2: Ad System Backend

### Task 5: Ad migrations — campaigns, creatives, impressions, ad_balance

**Files:**
- Create: `database/migrations/2026_03_29_600003_create_ad_campaigns_table.php`
- Create: `database/migrations/2026_03_29_600004_create_ad_creatives_table.php`
- Create: `database/migrations/2026_03_29_600005_create_ad_impressions_table.php`
- Create: `database/migrations/2026_03_29_600006_add_ad_balance_to_wallets.php`

- [ ] **Step 1: Create ad_campaigns migration**

```php
<?php
use Illuminate\Database\Migrations\Migration;
use Illuminate\Database\Schema\Blueprint;
use Illuminate\Support\Facades\Schema;
use Illuminate\Support\Facades\DB;

return new class extends Migration {
    public function up(): void
    {
        Schema::create('ad_campaigns', function (Blueprint $table) {
            $table->id();
            $table->unsignedBigInteger('advertiser_id');
            $table->string('title', 100);
            $table->text('description')->nullable();
            $table->string('campaign_type', 10);
            $table->string('status', 20)->default('draft');
            $table->decimal('daily_budget', 12, 2);
            $table->decimal('total_budget', 12, 2);
            $table->decimal('spent_amount', 12, 2)->default(0);
            $table->decimal('bid_amount', 8, 2);
            $table->date('start_date');
            $table->date('end_date')->nullable();
            $table->jsonb('targeting')->default('{}');
            $table->jsonb('placements');
            $table->text('rejection_reason')->nullable();
            $table->timestamps();

            $table->foreign('advertiser_id')->references('id')->on('users');
            $table->index('advertiser_id');
            $table->index(['status', 'start_date', 'end_date']);
            $table->index(['status', 'updated_at']);
        });

        DB::statement("ALTER TABLE ad_campaigns ADD CONSTRAINT chk_campaign_type CHECK (campaign_type IN ('cpm','cpc'))");
        DB::statement("ALTER TABLE ad_campaigns ADD CONSTRAINT chk_campaign_status CHECK (status IN ('draft','pending_review','active','paused','completed','rejected','cancelled'))");
    }

    public function down(): void
    {
        Schema::dropIfExists('ad_campaigns');
    }
};
```

- [ ] **Step 2: Create ad_creatives migration**

```php
<?php
use Illuminate\Database\Migrations\Migration;
use Illuminate\Database\Schema\Blueprint;
use Illuminate\Support\Facades\Schema;
use Illuminate\Support\Facades\DB;

return new class extends Migration {
    public function up(): void
    {
        Schema::create('ad_creatives', function (Blueprint $table) {
            $table->id();
            $table->unsignedBigInteger('campaign_id');
            $table->string('format', 20);
            $table->string('media_url', 500)->nullable();
            $table->string('headline', 50);
            $table->string('body_text', 150)->nullable();
            $table->string('cta_type', 20);
            $table->string('cta_url', 500);
            $table->unsignedBigInteger('product_id')->nullable();
            $table->boolean('approved')->default(false);
            $table->timestamp('created_at')->useCurrent();

            $table->foreign('campaign_id')->references('id')->on('ad_campaigns')->onDelete('cascade');
            $table->index('campaign_id');
        });

        DB::statement("ALTER TABLE ad_creatives ADD CONSTRAINT chk_creative_format CHECK (format IN ('image','video','audio','promoted_product','promoted_search'))");
        DB::statement("ALTER TABLE ad_creatives ADD CONSTRAINT chk_cta_type CHECK (cta_type IN ('learn_more','shop_now','visit','download','call'))");
    }

    public function down(): void
    {
        Schema::dropIfExists('ad_creatives');
    }
};
```

- [ ] **Step 3: Create ad_impressions partitioned migration**

```php
<?php
use Illuminate\Database\Migrations\Migration;
use Illuminate\Support\Facades\DB;

return new class extends Migration {
    public function up(): void
    {
        // Create partitioned table using raw SQL (Laravel Schema doesn't support partitioning)
        DB::statement("
            CREATE TABLE ad_impressions (
                id BIGINT GENERATED ALWAYS AS IDENTITY,
                created_at TIMESTAMP NOT NULL DEFAULT NOW(),
                campaign_id BIGINT NOT NULL,
                creative_id BIGINT NOT NULL,
                user_id BIGINT NOT NULL,
                placement VARCHAR(20) NOT NULL,
                event_type VARCHAR(15) NOT NULL,
                revenue DECIMAL(8,4) NOT NULL DEFAULT 0,
                source VARCHAR(15) NOT NULL,
                PRIMARY KEY (id, created_at),
                CONSTRAINT chk_placement CHECK (placement IN ('feed','stories','music','search','marketplace','clips','video_preroll','conversations','comments','live_stream','hashtag')),
                CONSTRAINT chk_event_type CHECK (event_type IN ('impression','click','skip','mute')),
                CONSTRAINT chk_source CHECK (source IN ('self_serve','admob'))
            ) PARTITION BY RANGE (created_at);
        ");

        // Create partitions for current month + 3 months ahead
        $start = now()->startOfMonth();
        for ($i = 0; $i < 4; $i++) {
            $from = $start->copy()->addMonths($i)->format('Y-m-d');
            $to = $start->copy()->addMonths($i + 1)->format('Y-m-d');
            $suffix = $start->copy()->addMonths($i)->format('Y_m');
            DB::statement("CREATE TABLE ad_impressions_{$suffix} PARTITION OF ad_impressions FOR VALUES FROM ('{$from}') TO ('{$to}');");
        }

        // Create indexes on each partition (PostgreSQL auto-creates on partitions if created on parent)
        DB::statement("CREATE INDEX idx_impressions_campaign ON ad_impressions (campaign_id, created_at);");
        DB::statement("CREATE INDEX idx_impressions_freq_cap ON ad_impressions (user_id, campaign_id, created_at);");
        DB::statement("CREATE INDEX idx_impressions_placement ON ad_impressions (placement, created_at);");
        DB::statement("CREATE INDEX idx_impressions_source ON ad_impressions (source, created_at);");
    }

    public function down(): void
    {
        DB::statement("DROP TABLE IF EXISTS ad_impressions CASCADE;");
    }
};
```

- [ ] **Step 4: Create ad_balance migration**

First find the wallets table name:
```bash
grep -rn "wallets\|wallet" database/migrations/ --include="*.php" -l | head -5
```

Then create migration:
```php
<?php
use Illuminate\Database\Migrations\Migration;
use Illuminate\Database\Schema\Blueprint;
use Illuminate\Support\Facades\Schema;

return new class extends Migration {
    public function up(): void
    {
        // Adjust table name if wallets table has a different name
        Schema::table('wallets', function (Blueprint $table) {
            $table->decimal('ad_balance', 12, 2)->default(0);
        });
    }

    public function down(): void
    {
        Schema::table('wallets', function (Blueprint $table) {
            $table->dropColumn('ad_balance');
        });
    }
};
```

- [ ] **Step 5: Run migrations**

```bash
cd /var/www/tajiri.zimasystems.com
php artisan migrate
```

- [ ] **Step 6: Verify**

```bash
php artisan tinker --execute="
echo 'ad_campaigns: ' . \Illuminate\Support\Facades\Schema::hasTable('ad_campaigns') . '\n';
echo 'ad_creatives: ' . \Illuminate\Support\Facades\Schema::hasTable('ad_creatives') . '\n';
echo 'ad_impressions: ' . \Illuminate\Support\Facades\Schema::hasTable('ad_impressions') . '\n';
echo 'ad_balance column: ' . \Illuminate\Support\Facades\Schema::hasColumn('wallets', 'ad_balance') . '\n';
"
```

- [ ] **Step 7: Commit**

```bash
git add database/migrations/2026_03_29_60000*
git commit -m "feat: add ad_campaigns, ad_creatives, ad_impressions (partitioned), and ad_balance column"
```

---

### Task 6: Ad models — AdCampaign, AdCreative, AdImpression

**Files:**
- Create: `app/Models/AdCampaign.php`
- Create: `app/Models/AdCreative.php`
- Create: `app/Models/AdImpression.php`

- [ ] **Step 1: Create AdCampaign model**

```php
<?php
namespace App\Models;

use Illuminate\Database\Eloquent\Model;

class AdCampaign extends Model
{
    protected $fillable = [
        'advertiser_id', 'title', 'description', 'campaign_type', 'status',
        'daily_budget', 'total_budget', 'spent_amount', 'bid_amount',
        'start_date', 'end_date', 'targeting', 'placements', 'rejection_reason',
    ];

    protected $casts = [
        'daily_budget' => 'float',
        'total_budget' => 'float',
        'spent_amount' => 'float',
        'bid_amount' => 'float',
        'targeting' => 'array',
        'placements' => 'array',
        'start_date' => 'date',
        'end_date' => 'date',
    ];

    public function advertiser() { return $this->belongsTo(User::class, 'advertiser_id'); }
    public function creatives() { return $this->hasMany(AdCreative::class, 'campaign_id'); }
    public function impressions() { return $this->hasMany(AdImpression::class, 'campaign_id'); }

    public function getRemainingBudgetAttribute(): float
    {
        return $this->total_budget - $this->spent_amount;
    }
}
```

- [ ] **Step 2: Create AdCreative model**

```php
<?php
namespace App\Models;

use Illuminate\Database\Eloquent\Model;

class AdCreative extends Model
{
    public $timestamps = false;

    protected $fillable = [
        'campaign_id', 'format', 'media_url', 'headline', 'body_text',
        'cta_type', 'cta_url', 'product_id', 'approved', 'created_at',
    ];

    protected $casts = [
        'approved' => 'boolean',
        'created_at' => 'datetime',
    ];

    public function campaign() { return $this->belongsTo(AdCampaign::class, 'campaign_id'); }
}
```

- [ ] **Step 3: Create AdImpression model**

```php
<?php
namespace App\Models;

use Illuminate\Database\Eloquent\Model;

class AdImpression extends Model
{
    public $timestamps = false;

    protected $fillable = [
        'campaign_id', 'creative_id', 'user_id', 'placement',
        'event_type', 'revenue', 'source', 'created_at',
    ];

    protected $casts = [
        'revenue' => 'float',
        'created_at' => 'datetime',
    ];
}
```

- [ ] **Step 4: Commit**

```bash
git add app/Models/AdCampaign.php app/Models/AdCreative.php app/Models/AdImpression.php
git commit -m "feat: add AdCampaign, AdCreative, AdImpression Eloquent models"
```

---

### Task 7: AdServingService

**Files:**
- Create: `app/Services/AdServingService.php`

- [ ] **Step 1: Create AdServingService**

Full implementation of `serve()`, `recordEvent()`, and `recordAdMobRevenue()` per spec Section 2.2. Key points:
- `serve()`: query active campaigns with jsonb `@>` operator for placement matching, filter by daily budget + targeting + frequency cap, rank by bid_amount DESC
- `recordEvent()`: atomic `UPDATE ... WHERE spent_amount + :revenue <= total_budget` and `UPDATE wallets SET ad_balance = ad_balance - :revenue WHERE ad_balance >= :revenue`
- `recordAdMobRevenue()`: insert into ad_impressions with source='admob', campaign_id=0, and ledger with type='ad_admob'

The implementer should read the spec Section 2.2 for the full algorithm. The service must use `DB::statement()` for the atomic UPDATE queries, NOT Eloquent (to get the WHERE guard).

- [ ] **Step 2: Verify syntax**

```bash
php -l app/Services/AdServingService.php
```

- [ ] **Step 3: Commit**

```bash
git add app/Services/AdServingService.php
git commit -m "feat: add AdServingService with serve, recordEvent, recordAdMobRevenue"
```

---

### Task 8: AdController + BiasharaController (API endpoints)

**Files:**
- Create: `app/Http/Controllers/Api/AdController.php`
- Create: `app/Http/Controllers/Api/BiasharaController.php`
- Modify: `routes/api.php`

- [ ] **Step 1: Create AdController**

3 endpoints per spec Section 2.2:
- `GET /api/ads/serve` → `serve(Request $request)` — calls `AdServingService::serve()`
- `POST /api/ads/event` → `recordEvent(Request $request)` — calls `AdServingService::recordEvent()`
- `POST /api/ads/admob-revenue` → `admobRevenue(Request $request)` — calls `AdServingService::recordAdMobRevenue()`

- [ ] **Step 2: Create BiasharaController**

13 endpoints per spec Section 2.2 Biashara API table:
- Campaign CRUD (index, store, show, update)
- Creative upload (multipart with storage)
- Status actions (submit, pause, resume, cancel with refund logic)
- Performance stats (aggregate ad_impressions)
- Balance (get ad_balance, deposit with PlatformFeeService::applyFee('ad_deposit', ...))
- Client settings (return ad frequencies + admob unit IDs from platform_settings)

Validation rules per spec: title max:100, daily_budget min:1000, total_budget min:5000, etc.

Campaign state machine per spec: draft→pending_review→active→paused→completed. Cancel refunds `total_budget - spent_amount` to ad_balance.

- [ ] **Step 3: Add routes to api.php**

```php
// Ad serving (public, auth required)
Route::middleware('auth:sanctum')->group(function () {
    Route::get('/ads/serve', [AdController::class, 'serve']);
    Route::post('/ads/event', [AdController::class, 'recordEvent']);
    Route::post('/ads/admob-revenue', [AdController::class, 'admobRevenue']);

    // Biashara (advertiser management)
    Route::prefix('biashara')->group(function () {
        Route::get('/campaigns', [BiasharaController::class, 'index']);
        Route::post('/campaigns', [BiasharaController::class, 'store']);
        Route::get('/campaigns/{id}', [BiasharaController::class, 'show']);
        Route::put('/campaigns/{id}', [BiasharaController::class, 'update']);
        Route::post('/campaigns/{id}/creatives', [BiasharaController::class, 'uploadCreative']);
        Route::post('/campaigns/{id}/submit', [BiasharaController::class, 'submit']);
        Route::post('/campaigns/{id}/pause', [BiasharaController::class, 'pause']);
        Route::post('/campaigns/{id}/resume', [BiasharaController::class, 'resume']);
        Route::post('/campaigns/{id}/cancel', [BiasharaController::class, 'cancel']);
        Route::get('/campaigns/{id}/performance', [BiasharaController::class, 'performance']);
        Route::get('/balance', [BiasharaController::class, 'balance']);
        Route::post('/deposit', [BiasharaController::class, 'deposit']);
        Route::get('/settings', [BiasharaController::class, 'settings']);
    });
});
```

- [ ] **Step 4: Verify routes**

```bash
php artisan route:list --path=api/ads
php artisan route:list --path=api/biashara
```

- [ ] **Step 5: Commit**

```bash
git add app/Http/Controllers/Api/AdController.php app/Http/Controllers/Api/BiasharaController.php routes/api.php
git commit -m "feat: add AdController (serve/event/admob) and BiasharaController (13 endpoints)"
```

---

## Phase 3: Revenue Admin Dashboard

### Task 9: Admin dashboard — RevenueController + Blade views

**Files:**
- Create: `app/Http/Controllers/Admin/RevenueController.php`
- Create: `resources/views/admin/layout.blade.php` (if not exists)
- Create: `resources/views/admin/revenue/overview.blade.php`
- Create: `resources/views/admin/revenue/fees.blade.php`
- Create: `resources/views/admin/revenue/ads.blade.php`
- Create: `resources/views/admin/revenue/fund.blade.php`
- Create: `resources/views/admin/revenue/settings.blade.php`
- Create: `resources/views/admin/revenue/review.blade.php`
- Modify: `routes/web.php`

- [ ] **Step 1: Create RevenueController**

11 methods per spec Section 3.4:
- `overview()` — queries `mv_daily_revenue` materialized view (or direct query), returns metric cards + chart data
- `fees()` — paginated `platform_revenue_ledger` with date/type filters
- `exportFees()` — CSV stream download
- `ads()` — ad_impressions aggregated by source, placement, top campaigns
- `fund()` — Creator Fund pool calculations, distribution history
- `distributeFund()` — POST, guarded by `last_fund_distribution_at` (409 if already distributed this month)
- `settings()` — GET all platform_settings grouped by category
- `updateSettings()` — PUT, updates settings and busts cache
- `reviewQueue()` — pending_review campaigns with creatives
- `approveCampaign($id)` — set status=active, creatives approved=true, send FCM
- `rejectCampaign($id)` — set status=rejected with reason, send FCM

- [ ] **Step 2: Create admin layout**

Check if an admin layout already exists:
```bash
find resources/views -name "layout*" -path "*/admin/*"
```

If not, create a minimal Blade layout with Tailwind CSS (via CDN), Chart.js v4 (via CDN), and Alpine.js (via CDN). Include sidebar navigation with revenue dashboard links.

- [ ] **Step 3: Create 6 Blade view templates**

Each view extends the admin layout. Key pages:
- `overview.blade.php`: 6 metric cards, 3 charts (line/donut/bar), uses Chart.js
- `fees.blade.php`: date range filter, type dropdown, paginated table, CSV export button
- `ads.blade.php`: 6 metric cards, 2 charts, top-10 campaigns table
- `fund.blade.php`: 4 metric cards, creator payouts table, "Distribute Fund" button (disabled if already distributed)
- `settings.blade.php`: grouped editable table with Alpine.js inline edit
- `review.blade.php`: campaigns table with preview modal, approve/reject buttons

- [ ] **Step 4: Create materialized view migration**

```php
<?php
// database/migrations/2026_03_29_600007_create_mv_daily_revenue.php
use Illuminate\Database\Migrations\Migration;
use Illuminate\Support\Facades\DB;

return new class extends Migration {
    public function up(): void
    {
        DB::statement('
            CREATE MATERIALIZED VIEW IF NOT EXISTS mv_daily_revenue AS
            SELECT
                DATE(created_at) as day,
                transaction_type,
                SUM(fee_amount) as total_fee,
                COUNT(*) as transaction_count
            FROM platform_revenue_ledger
            GROUP BY DATE(created_at), transaction_type
        ');
        DB::statement('CREATE UNIQUE INDEX idx_mv_daily_revenue ON mv_daily_revenue (day, transaction_type)');
    }

    public function down(): void
    {
        DB::statement('DROP MATERIALIZED VIEW IF EXISTS mv_daily_revenue');
    }
};
```

Run: `php artisan migrate`

- [ ] **Step 5: Add scheduled jobs for materialized view refresh + partition maintenance**

In `routes/console.php` (Laravel 12):
```php
use Illuminate\Support\Facades\DB;
use Illuminate\Support\Facades\Schedule;

// Refresh materialized view hourly
Schedule::call(function () {
    DB::statement('REFRESH MATERIALIZED VIEW CONCURRENTLY mv_daily_revenue');
})->hourly();

// Create ad_impressions partitions 3 months ahead (monthly)
Schedule::call(function () {
    $target = now()->addMonths(3)->startOfMonth();
    $from = $target->format('Y-m-d');
    $to = $target->copy()->addMonth()->format('Y-m-d');
    $suffix = $target->format('Y_m');
    DB::statement("CREATE TABLE IF NOT EXISTS ad_impressions_{$suffix} PARTITION OF ad_impressions FOR VALUES FROM ('{$from}') TO ('{$to}')");
})->monthly();
```

- [ ] **Step 6: Add admin routes to web.php**

```php
use App\Http\Controllers\Admin\RevenueController;

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

Note: If `role:admin` middleware doesn't exist, check existing auth middleware and adapt. May need `is_admin` column check.

- [ ] **Step 7: Verify admin pages load**

```bash
curl -s -o /dev/null -w "%{http_code}" http://127.0.0.1/admin/revenue
# Expected: 302 (redirect to login) or 200 (if auth bypassed for testing)
```

- [ ] **Step 8: Commit**

```bash
git add app/Http/Controllers/Admin/ resources/views/admin/ routes/web.php routes/console.php database/migrations/2026_03_29_600007*
git commit -m "feat: add Revenue Admin Dashboard — 6 Blade views, RevenueController, materialized view, partition maintenance"
```

---

## Phase 4: Ad Frontend — Biashara Screens

### Task 10: Flutter ad models + ad service

**Files:**
- Create: `lib/models/ad_models.dart`
- Create: `lib/services/ad_service.dart`
- Modify: `lib/models/wallet_models.dart` (add adBalance)

**Context:** All work at `/Volumes/DATA/PROJECTS/TAJIRI/TAJIRI-FRONTEND`.

- [ ] **Step 1: Create ad_models.dart**

Full implementation per spec Section 2.3 Models: AdCampaign, AdCreative, AdPerformance, DailyAdStat, ServedAd — each with `factory fromJson(Map<String, dynamic> json)` and `toJson()` (where applicable). Follow existing model patterns (use `_parseInt`, `_parseDouble` helpers per CLAUDE.md conventions).

- [ ] **Step 2: Create ad_service.dart**

Static-method service per spec Section 2.3 Service table: 15 methods including `getServedAds`, `recordAdEvent`, `reportAdMobRevenue`, campaign CRUD, balance operations. Follow existing service patterns (static methods, token param, http package).

- [ ] **Step 3: Update wallet_models.dart**

Add `adBalance` field to existing `Wallet` class:
```dart
final double adBalance;
```
Parse in `fromJson`:
```dart
adBalance: (json['ad_balance'] as num?)?.toDouble() ?? 0.0,
```

- [ ] **Step 4: Verify**

```bash
flutter analyze lib/models/ad_models.dart lib/services/ad_service.dart lib/models/wallet_models.dart
```
Expected: 0 errors (info-level warnings OK)

- [ ] **Step 5: Commit**

```bash
git add lib/models/ad_models.dart lib/services/ad_service.dart lib/models/wallet_models.dart
git commit -m "feat: add ad models, ad service (15 methods), and adBalance to Wallet"
```

---

### Task 11: Biashara screens (4 screens) + routes + strings

**Files:**
- Create: `lib/screens/biashara/biashara_home_screen.dart`
- Create: `lib/screens/biashara/create_ad_campaign_screen.dart`
- Create: `lib/screens/biashara/campaign_detail_screen.dart`
- Create: `lib/screens/biashara/deposit_ad_balance_screen.dart`
- Modify: `lib/main.dart` (add /biashara routes)
- Modify: `lib/l10n/app_strings.dart` (add ~20 Swahili strings)

- [ ] **Step 1: Add Swahili strings to AppStrings**

Add all strings from spec Section 2.3 Swahili UI Strings table. Follow existing pattern: `String get biashara => isSwahili ? 'Biashara' : 'Business';`

- [ ] **Step 2: Create BiasharaHomeScreen**

Per spec: ad balance card, today's summary metrics, campaign list with status badges, FAB for create, empty state with illustration. Follow design-guidelines skill (Material 3, #1A1A1A dark palette, 12px radius, 48dp touch targets).

- [ ] **Step 3: Create CreateAdCampaignScreen**

6-step PageView wizard per spec: campaign type → creative upload → targeting → placements → budget → review & submit. Uses `image_picker` for creative upload. Validates per spec rules.

- [ ] **Step 4: Create CampaignDetailScreen**

Per spec: status badge, metrics cards (impressions, clicks, CTR, spend), daily spend chart (custom paint or simple bar chart), pause/resume/cancel actions, creative preview.

- [ ] **Step 5: Create DepositAdBalanceScreen**

Per spec: amount input with presets (10K-100K), payment method picker, fee disclosure, two-step confirm flow.

- [ ] **Step 6: Add routes to main.dart**

```dart
'/biashara': (context) => const BiasharaHomeScreen(),
'/biashara/create': (context) => const CreateAdCampaignScreen(),
'/biashara/deposit': (context) => const DepositAdBalanceScreen(),
```
And in `onGenerateRoute` for `/biashara/campaign/:id`:
```dart
case 'biashara':
  if (pathSegments.length == 3 && pathSegments[1] == 'campaign') {
    final campaignId = int.tryParse(pathSegments[2]);
    if (campaignId != null) {
      return MaterialPageRoute(builder: (_) => CampaignDetailScreen(campaignId: campaignId));
    }
  }
```

- [ ] **Step 7: Verify**

```bash
flutter analyze lib/screens/biashara/ lib/l10n/app_strings.dart lib/main.dart
```

- [ ] **Step 8: Commit**

```bash
git add lib/screens/biashara/ lib/l10n/app_strings.dart lib/main.dart
git commit -m "feat: add Biashara screens (home, create, detail, deposit) with routes and Swahili strings"
```

---

## Phase 5: Ad Surfaces (11 Placements)

### Task 12: AdMob integration + shared ad widgets

**Files:**
- Modify: `pubspec.yaml` (add google_mobile_ads)
- Create: `lib/services/admob_service.dart`
- Create: `lib/widgets/native_ad_card.dart`
- Create: `lib/widgets/story_ad_overlay.dart`
- Create: `lib/widgets/music_ad_overlay.dart`
- Create: `lib/widgets/video_preroll_overlay.dart`
- Create: `lib/widgets/conversation_ad_card.dart`
- Create: `lib/widgets/stream_sponsor_badge.dart`

- [ ] **Step 1: Add google_mobile_ads to pubspec.yaml**

```yaml
dependencies:
  google_mobile_ads: ^5.1.0
```

Run: `flutter pub get`

- [ ] **Step 2: Initialize AdMob in main.dart**

Add to `main()` before `runApp()`:
```dart
import 'package:google_mobile_ads/google_mobile_ads.dart';
// In main():
WidgetsFlutterBinding.ensureInitialized();
MobileAds.instance.initialize();
```

- [ ] **Step 3: Create AdMobService**

Per spec Section 2.5:
- `loadNativeAd(String placement)` → returns `NativeAd?`
- `loadInterstitialAd()` → returns `InterstitialAd?`
- `onAdRevenuePaid(Ad ad, String placement)` → calls `AdService.reportAdMobRevenue()`
- Ad unit IDs from LocalStorageService (cached from `/api/biashara/settings`)
- Uses test IDs in debug mode

- [ ] **Step 4: Create NativeAdCard widget**

Per spec Section 2.4.1: PostCard-like layout with "Tangazo" badge, creative image/video, headline, body text, CTA button. Records impression on visibility via `VisibilityDetector`, click on CTA tap. Handles both self-serve (ServedAd data) and AdMob (NativeAd widget) modes.

- [ ] **Step 5: Create StoryAdOverlay widget**

Per spec Section 2.4.2: Full-screen overlay, 5-second countdown, skip button, "Tangazo" label, CTA. Reused for clips (Section 2.4.7).

- [ ] **Step 6: Create MusicAdOverlay widget**

Per spec Section 2.4.3: Overlay on music player sheet, creative image, headline, CTA, 5s skip.

- [ ] **Step 7: Create VideoPrerollOverlay widget**

Per spec Section 2.4.6: Overlay before video plays, 3-5s countdown, "Video inaanza..." text, skip button.

- [ ] **Step 8: Create ConversationAdCard widget**

Per spec Section 2.4.8: Same structure as conversation tile (avatar, name, preview), "Tangazo" badge, CTA on tap.

- [ ] **Step 9: Create StreamSponsorBadge widget**

Per spec Section 2.4.10: Small semi-transparent card (120x40dp), positioned bottom-left, "Imetolewa na [Brand]", non-intrusive.

- [ ] **Step 10: Verify**

```bash
flutter analyze lib/services/admob_service.dart lib/widgets/native_ad_card.dart lib/widgets/story_ad_overlay.dart lib/widgets/music_ad_overlay.dart lib/widgets/video_preroll_overlay.dart lib/widgets/conversation_ad_card.dart lib/widgets/stream_sponsor_badge.dart
```

- [ ] **Step 11: Commit**

```bash
git add pubspec.yaml pubspec.lock lib/services/admob_service.dart lib/widgets/native_ad_card.dart lib/widgets/story_ad_overlay.dart lib/widgets/music_ad_overlay.dart lib/widgets/video_preroll_overlay.dart lib/widgets/conversation_ad_card.dart lib/widgets/stream_sponsor_badge.dart lib/main.dart
git commit -m "feat: add AdMob integration, 6 ad widgets (native card, story overlay, music overlay, video preroll, conversation card, stream badge)"
```

---

### Task 13: Ad surface integration — Feed + Discover + Hashtag

**Files:**
- Modify: `lib/screens/feed/feed_screen.dart`
- Modify: `lib/screens/feed/discover_feed_content.dart`
- Modify: `lib/screens/search/hashtag_screen.dart`

- [ ] **Step 1: Feed native ads**

In `feed_screen.dart`:
- Add `nativeAd` to `_FeedItemType` enum
- In `_buildFeedItems()`, insert `_FeedItemType.nativeAd` every N posts (N from cached settings). Skip if a `teaser` already occupies the slot.
- Prefetch ads: call `AdService.getServedAds(token, 'feed', count)` during `_loadFeed()`
- In itemBuilder switch, add `nativeAd` case: render `NativeAdCard` (self-serve) or AdMob native ad

- [ ] **Step 2: Discover promoted cards**

In `discover_feed_content.dart`:
- Refactor trending section to use `SliverList.builder` if currently using spread operator
- Insert promoted card at position 0 from `AdService.getServedAds(token, 'search', 1)`

- [ ] **Step 3: Hashtag feed ads**

In `hashtag_screen.dart`:
- In ListView.builder, insert `NativeAdCard` after every 6 posts
- Prefetch 2 ads on screen load

- [ ] **Step 4: Verify**

```bash
flutter analyze lib/screens/feed/feed_screen.dart lib/screens/feed/discover_feed_content.dart lib/screens/search/hashtag_screen.dart
```

- [ ] **Step 5: Commit**

```bash
git add lib/screens/feed/feed_screen.dart lib/screens/feed/discover_feed_content.dart lib/screens/search/hashtag_screen.dart
git commit -m "feat: integrate native ads in feed (every N posts), discover (promoted card), and hashtag feed"
```

---

### Task 14: Ad surface integration — Stories + Clips + Video pre-roll

**Files:**
- Modify: `lib/screens/clips/storyviewer_screen.dart`
- Modify: `lib/screens/clips/clips_screen.dart`
- Modify: `lib/widgets/video_player_widget.dart`

- [ ] **Step 1: Story ads between groups**

In `storyviewer_screen.dart`:
- Add `_groupsSinceLastAd` counter
- In `_nextGroup()`, check if counter >= N (from settings)
- If yes: fetch ad, show `StoryAdOverlay` (self-serve) or AdMob interstitial, reset counter

- [ ] **Step 2: Clips ads between reels**

In `clips_screen.dart`:
- Add `_clipsSinceLastAd` counter
- In `_onPageChanged()`, check if counter >= N (from settings)
- If yes: show `StoryAdOverlay` (reused, same full-screen format) or AdMob interstitial

- [ ] **Step 3: Video pre-roll ads**

In `video_player_widget.dart`:
- Add `_showPreroll` state and session-level counter (static `_videosThisSession`)
- On init, if counter % 3 == 0: fetch ad, show `VideoPrerollOverlay` before video starts
- After ad completes/skipped: proceed with video initialization

- [ ] **Step 4: Verify**

```bash
flutter analyze lib/screens/clips/storyviewer_screen.dart lib/screens/clips/clips_screen.dart lib/widgets/video_player_widget.dart
```

- [ ] **Step 5: Commit**

```bash
git add lib/screens/clips/storyviewer_screen.dart lib/screens/clips/clips_screen.dart lib/widgets/video_player_widget.dart
git commit -m "feat: integrate ads in stories (between groups), clips (between reels), and video pre-roll"
```

---

### Task 15: Ad surface integration — Music + Search + Marketplace

**Files:**
- Modify: `lib/screens/music/music_player_sheet.dart`
- Modify: `lib/screens/search/search_screen.dart`
- Modify: `lib/screens/shop/shop_screen.dart`

- [ ] **Step 1: Music interstitial ads**

In `music_player_sheet.dart`:
- Add `_tracksSinceLastAd` counter
- In `processingStateStream` listener on track complete: increment counter
- If counter >= N: pause playback, show `MusicAdOverlay`, reset counter, resume after ad

- [ ] **Step 2: Search promoted results**

In `search_screen.dart`:
- After search results load, fetch 2 ads: `AdService.getServedAds(token, 'search', 2)`
- Insert at positions 0 and 3 in results list
- Mark with "Imedhaminiwa" badge

- [ ] **Step 3: Marketplace promoted listings**

In `shop_screen.dart`:
- After products load, fetch 2 ads: `AdService.getServedAds(token, 'marketplace', 2)`
- Insert at positions 0 and 5 in product grid
- Products linked via `product_id`, "Imedhaminiwa" badge

- [ ] **Step 4: Verify**

```bash
flutter analyze lib/screens/music/music_player_sheet.dart lib/screens/search/search_screen.dart lib/screens/shop/shop_screen.dart
```

- [ ] **Step 5: Commit**

```bash
git add lib/screens/music/music_player_sheet.dart lib/screens/search/search_screen.dart lib/screens/shop/shop_screen.dart
git commit -m "feat: integrate ads in music player (between tracks), search (promoted results), and marketplace (promoted listings)"
```

---

### Task 16: Ad surface integration — Conversations + Comments + Live Stream

**Files:**
- Modify: `lib/screens/messages/conversations_screen.dart`
- Modify: `lib/screens/feed/comment_bottom_sheet.dart`
- Modify: `lib/screens/clips/streamviewer_screen.dart`

- [ ] **Step 1: Conversations list ads**

In `conversations_screen.dart`:
- In ListView.builder, insert `ConversationAdCard` after every 5 conversations
- Prefetch 2 ads on screen load: `AdService.getServedAds(token, 'conversations', 2)`

- [ ] **Step 2: Comments ads**

In `comment_bottom_sheet.dart`:
- In ListView.builder (line ~623), insert compact `NativeAdCard` after every 8 comments
- Prefetch 1 ad on sheet open

- [ ] **Step 3: Live stream ads**

In `streamviewer_screen.dart`:
- Before stream join: show `StoryAdOverlay` (3-5s) or AdMob interstitial
- During stream: position `StreamSponsorBadge` in overlay Stack (bottom-left)
- Fetch 1 ad on stream join: `AdService.getServedAds(token, 'live_stream', 1)`

- [ ] **Step 4: Verify**

```bash
flutter analyze lib/screens/messages/conversations_screen.dart lib/screens/feed/comment_bottom_sheet.dart lib/screens/clips/streamviewer_screen.dart
```

- [ ] **Step 5: Commit**

```bash
git add lib/screens/messages/conversations_screen.dart lib/screens/feed/comment_bottom_sheet.dart lib/screens/clips/streamviewer_screen.dart
git commit -m "feat: integrate ads in conversations (chat list), comments, and live streams (pre-join + sponsor badge)"
```

---

### Task 17: Client settings fetch + ad frequency caching

**Files:**
- Modify: `lib/services/local_storage_service.dart`
- Modify: `lib/main.dart` (or app initialization)

- [ ] **Step 1: Add ad settings cache to LocalStorageService**

Add methods to store/retrieve ad settings from Hive:
```dart
Future<void> saveAdSettings(Map<String, dynamic> settings);
Map<String, dynamic>? getAdSettings();
int getAdFrequency(String key, int defaultValue);
String? getAdMobUnitId(String key);
```

- [ ] **Step 2: Fetch settings on app startup**

In app initialization (after auth token loaded), call:
```dart
final settings = await AdService.getClientSettings(token);
await LocalStorageService.instance.saveAdSettings(settings);
```

Refresh every 24 hours (check `lastFetchedAt` timestamp).

- [ ] **Step 3: Update all ad surface code to read from LocalStorageService**

All ad frequency checks (feed, stories, music, clips, conversations) should read from `LocalStorageService.instance.getAdFrequency('ad_feed_frequency', 10)` instead of hardcoded values.

- [ ] **Step 4: Verify**

```bash
flutter analyze lib/services/local_storage_service.dart lib/main.dart
```

- [ ] **Step 5: Commit**

```bash
git add lib/services/local_storage_service.dart lib/main.dart
git commit -m "feat: fetch and cache ad settings from backend, use configurable frequencies across all ad surfaces"
```

---

## Verification

After all tasks complete:

```bash
# Backend
cd /var/www/tajiri.zimasystems.com
php artisan route:list --path=api/ads
php artisan route:list --path=api/biashara
php artisan route:list --path=admin/revenue
php artisan tinker --execute="echo 'Settings: ' . \App\Models\PlatformSetting::count(); echo '\nLedger: ' . \App\Models\PlatformRevenueLedger::count();"

# Frontend
cd /Volumes/DATA/PROJECTS/TAJIRI/TAJIRI-FRONTEND
flutter analyze
```

Zero errors required. Info-level warnings acceptable if pre-existing.
