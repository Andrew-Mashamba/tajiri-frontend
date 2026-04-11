# Budget Plan A: Backend + Core Services

> **For agentic workers:** REQUIRED SUB-SKILL: Use superpowers:subagent-driven-development (recommended) or superpowers:executing-plans to implement this plan task-by-task.

**Goal:** Build the backend API and Flutter core services (IncomeService, ExpenditureService, BudgetService) for the budget module.

**Architecture:** Backend PostgreSQL tables + Laravel controllers serving REST API. Flutter services consume the API with SQLite local cache for offline-first. IncomeService and ExpenditureService are the central hub — all money movement flows through them.

**Tech Stack:** Laravel 12/PHP 8.3/PostgreSQL (backend), Flutter/Dart with sqflite + http (frontend)

---

## File Structure

| File | Action | Responsibility |
|---|---|---|
| **Backend** | | |
| `app/Http/Controllers/Api/IncomeController.php` | Create | Record + query income |
| `app/Http/Controllers/Api/ExpenditureController.php` | Create | Record + query expenditures |
| `app/Http/Controllers/Api/BudgetController.php` | Create | Envelopes, goals, periods |
| `routes/api.php` | Modify | Wire budget/income/expenditure routes |
| **Frontend** | | |
| `lib/models/budget_models.dart` | Rewrite | All budget models with API fromJson |
| `lib/services/income_service.dart` | Create | All income API calls |
| `lib/services/expenditure_service.dart` | Create | All expenditure API calls |
| `lib/services/budget_service.dart` | Rewrite | API-backed budget service |
| `lib/services/budget_database.dart` | Rewrite | SQLite local cache (SQLITE_ADOPTION_ROADMAP pattern) |

---

## Task 1: Backend — Create Database Tables

**Server:** `root@172.240.241.180`
**Project:** `/var/www/tajiri.zimasystems.com`

- [ ] **Step 1: SSH into the server and create all 6 tables via artisan tinker**

```bash
sshpass -p 'ZimaBlueApps' ssh -o StrictHostKeyChecking=no root@172.240.241.180 "cd /var/www/tajiri.zimasystems.com && php artisan tinker --execute=\"
DB::statement('
CREATE TABLE IF NOT EXISTS income_records (
    id BIGSERIAL PRIMARY KEY,
    user_id BIGINT NOT NULL,
    amount DECIMAL(15,2) NOT NULL,
    source VARCHAR(50) NOT NULL,
    source_module VARCHAR(50),
    description TEXT NOT NULL DEFAULT \\'\\',
    reference_id VARCHAR(100),
    metadata JSONB,
    date TIMESTAMP NOT NULL DEFAULT NOW(),
    is_recurring BOOLEAN NOT NULL DEFAULT FALSE,
    created_at TIMESTAMP NOT NULL DEFAULT NOW(),
    updated_at TIMESTAMP NOT NULL DEFAULT NOW()
)');
DB::statement('CREATE INDEX IF NOT EXISTS idx_income_user ON income_records(user_id)');
DB::statement('CREATE INDEX IF NOT EXISTS idx_income_date ON income_records(date)');
DB::statement('CREATE INDEX IF NOT EXISTS idx_income_source ON income_records(source)');
DB::statement('CREATE INDEX IF NOT EXISTS idx_income_ref ON income_records(reference_id)');
DB::statement('CREATE UNIQUE INDEX IF NOT EXISTS idx_income_ref_unique ON income_records(reference_id) WHERE reference_id IS NOT NULL');
echo 'income_records created';
\""
```

```bash
sshpass -p 'ZimaBlueApps' ssh -o StrictHostKeyChecking=no root@172.240.241.180 "cd /var/www/tajiri.zimasystems.com && php artisan tinker --execute=\"
DB::statement('
CREATE TABLE IF NOT EXISTS expenditure_records (
    id BIGSERIAL PRIMARY KEY,
    user_id BIGINT NOT NULL,
    amount DECIMAL(15,2) NOT NULL,
    category VARCHAR(50) NOT NULL,
    source_module VARCHAR(50),
    description TEXT NOT NULL DEFAULT \\'\\',
    reference_id VARCHAR(100),
    envelope_tag VARCHAR(50),
    metadata JSONB,
    date TIMESTAMP NOT NULL DEFAULT NOW(),
    is_recurring BOOLEAN NOT NULL DEFAULT FALSE,
    created_at TIMESTAMP NOT NULL DEFAULT NOW(),
    updated_at TIMESTAMP NOT NULL DEFAULT NOW()
)');
DB::statement('CREATE INDEX IF NOT EXISTS idx_exp_user ON expenditure_records(user_id)');
DB::statement('CREATE INDEX IF NOT EXISTS idx_exp_date ON expenditure_records(date)');
DB::statement('CREATE INDEX IF NOT EXISTS idx_exp_category ON expenditure_records(category)');
DB::statement('CREATE INDEX IF NOT EXISTS idx_exp_ref ON expenditure_records(reference_id)');
DB::statement('CREATE UNIQUE INDEX IF NOT EXISTS idx_exp_ref_unique ON expenditure_records(reference_id) WHERE reference_id IS NOT NULL');
echo 'expenditure_records created';
\""
```

```bash
sshpass -p 'ZimaBlueApps' ssh -o StrictHostKeyChecking=no root@172.240.241.180 "cd /var/www/tajiri.zimasystems.com && php artisan tinker --execute=\"
DB::statement('
CREATE TABLE IF NOT EXISTS budget_envelope_defaults (
    id BIGSERIAL PRIMARY KEY,
    name_en VARCHAR(100) NOT NULL,
    name_sw VARCHAR(100) NOT NULL,
    icon VARCHAR(100) NOT NULL,
    color VARCHAR(10) NOT NULL DEFAULT \\'1A1A1A\\',
    sort_order INTEGER NOT NULL DEFAULT 0,
    group_name VARCHAR(50) NOT NULL DEFAULT \\'essential\\',
    module_tag VARCHAR(50) NOT NULL,
    is_active BOOLEAN NOT NULL DEFAULT TRUE,
    created_at TIMESTAMP NOT NULL DEFAULT NOW(),
    updated_at TIMESTAMP NOT NULL DEFAULT NOW()
)');
echo 'budget_envelope_defaults created';
\""
```

```bash
sshpass -p 'ZimaBlueApps' ssh -o StrictHostKeyChecking=no root@172.240.241.180 "cd /var/www/tajiri.zimasystems.com && php artisan tinker --execute=\"
DB::statement('
CREATE TABLE IF NOT EXISTS budget_user_envelopes (
    id BIGSERIAL PRIMARY KEY,
    user_id BIGINT NOT NULL,
    default_envelope_id BIGINT,
    name VARCHAR(100) NOT NULL,
    icon VARCHAR(100) NOT NULL DEFAULT \\'circle\\',
    color VARCHAR(10) NOT NULL DEFAULT \\'1A1A1A\\',
    allocated_amount DECIMAL(15,2) NOT NULL DEFAULT 0,
    sort_order INTEGER NOT NULL DEFAULT 0,
    module_tag VARCHAR(50),
    is_hidden BOOLEAN NOT NULL DEFAULT FALSE,
    rollover BOOLEAN NOT NULL DEFAULT FALSE,
    rolled_over_amount DECIMAL(15,2) NOT NULL DEFAULT 0,
    budget_year INTEGER NOT NULL,
    budget_month INTEGER NOT NULL,
    created_at TIMESTAMP NOT NULL DEFAULT NOW(),
    updated_at TIMESTAMP NOT NULL DEFAULT NOW(),
    FOREIGN KEY (default_envelope_id) REFERENCES budget_envelope_defaults(id) ON DELETE SET NULL
)');
DB::statement('CREATE INDEX IF NOT EXISTS idx_ue_user ON budget_user_envelopes(user_id)');
DB::statement('CREATE INDEX IF NOT EXISTS idx_ue_period ON budget_user_envelopes(budget_year, budget_month)');
DB::statement('CREATE INDEX IF NOT EXISTS idx_ue_user_period ON budget_user_envelopes(user_id, budget_year, budget_month)');
echo 'budget_user_envelopes created';
\""
```

```bash
sshpass -p 'ZimaBlueApps' ssh -o StrictHostKeyChecking=no root@172.240.241.180 "cd /var/www/tajiri.zimasystems.com && php artisan tinker --execute=\"
DB::statement('
CREATE TABLE IF NOT EXISTS budget_goals (
    id BIGSERIAL PRIMARY KEY,
    user_id BIGINT NOT NULL,
    name VARCHAR(200) NOT NULL,
    icon VARCHAR(100) NOT NULL DEFAULT \\'flag\\',
    target_amount DECIMAL(15,2) NOT NULL,
    saved_amount DECIMAL(15,2) NOT NULL DEFAULT 0,
    deadline DATE,
    is_complete BOOLEAN NOT NULL DEFAULT FALSE,
    created_at TIMESTAMP NOT NULL DEFAULT NOW(),
    updated_at TIMESTAMP NOT NULL DEFAULT NOW()
)');
DB::statement('CREATE INDEX IF NOT EXISTS idx_bg_user ON budget_goals(user_id)');
echo 'budget_goals created';
\""
```

```bash
sshpass -p 'ZimaBlueApps' ssh -o StrictHostKeyChecking=no root@172.240.241.180 "cd /var/www/tajiri.zimasystems.com && php artisan tinker --execute=\"
DB::statement('
CREATE TABLE IF NOT EXISTS budget_periods (
    id BIGSERIAL PRIMARY KEY,
    user_id BIGINT NOT NULL,
    year INTEGER NOT NULL,
    month INTEGER NOT NULL,
    total_income DECIMAL(15,2) NOT NULL DEFAULT 0,
    total_allocated DECIMAL(15,2) NOT NULL DEFAULT 0,
    total_spent DECIMAL(15,2) NOT NULL DEFAULT 0,
    created_at TIMESTAMP NOT NULL DEFAULT NOW(),
    updated_at TIMESTAMP NOT NULL DEFAULT NOW(),
    UNIQUE(user_id, year, month)
)');
DB::statement('CREATE INDEX IF NOT EXISTS idx_bp_user ON budget_periods(user_id)');
echo 'budget_periods created';
\""
```

- [ ] **Step 2: Seed the 19 default envelopes**

```bash
sshpass -p 'ZimaBlueApps' ssh -o StrictHostKeyChecking=no root@172.240.241.180 "cd /var/www/tajiri.zimasystems.com && php artisan tinker --execute=\"
\\\$envelopes = [
    ['name_en' => 'Rent/Housing', 'name_sw' => 'Kodi', 'icon' => 'home_rounded', 'color' => '1A1A1A', 'sort_order' => 0, 'group_name' => 'essential', 'module_tag' => 'housing'],
    ['name_en' => 'Food & Groceries', 'name_sw' => 'Chakula', 'icon' => 'restaurant_rounded', 'color' => '4CAF50', 'sort_order' => 1, 'group_name' => 'essential', 'module_tag' => 'food'],
    ['name_en' => 'Transport', 'name_sw' => 'Usafiri', 'icon' => 'directions_car_rounded', 'color' => '2196F3', 'sort_order' => 2, 'group_name' => 'essential', 'module_tag' => 'transport'],
    ['name_en' => 'Electricity & Water', 'name_sw' => 'Umeme na Maji', 'icon' => 'bolt_rounded', 'color' => 'FF9800', 'sort_order' => 3, 'group_name' => 'essential', 'module_tag' => 'utilities'],
    ['name_en' => 'Phone & Internet', 'name_sw' => 'Simu na Intaneti', 'icon' => 'phone_android_rounded', 'color' => '607D8B', 'sort_order' => 4, 'group_name' => 'essential', 'module_tag' => 'telecom'],
    ['name_en' => 'Health', 'name_sw' => 'Afya', 'icon' => 'medical_services_rounded', 'color' => 'E53935', 'sort_order' => 5, 'group_name' => 'essential', 'module_tag' => 'health'],
    ['name_en' => 'School & Education', 'name_sw' => 'Ada/Shule', 'icon' => 'school_rounded', 'color' => 'FF9800', 'sort_order' => 6, 'group_name' => 'family', 'module_tag' => 'education'],
    ['name_en' => 'Children', 'name_sw' => 'Watoto', 'icon' => 'child_care_rounded', 'color' => 'EC407A', 'sort_order' => 7, 'group_name' => 'family', 'module_tag' => 'children'],
    ['name_en' => 'Family Support', 'name_sw' => 'Familia', 'icon' => 'family_restroom_rounded', 'color' => '8D6E63', 'sort_order' => 8, 'group_name' => 'family', 'module_tag' => 'family'],
    ['name_en' => 'Clothing & Shoes', 'name_sw' => 'Mavazi', 'icon' => 'checkroom_rounded', 'color' => '9C27B0', 'sort_order' => 9, 'group_name' => 'lifestyle', 'module_tag' => 'clothing'],
    ['name_en' => 'Personal Care', 'name_sw' => 'Urembo', 'icon' => 'spa_rounded', 'color' => 'F06292', 'sort_order' => 10, 'group_name' => 'lifestyle', 'module_tag' => 'beauty'],
    ['name_en' => 'Entertainment', 'name_sw' => 'Burudani', 'icon' => 'sports_esports_rounded', 'color' => '795548', 'sort_order' => 11, 'group_name' => 'lifestyle', 'module_tag' => 'entertainment'],
    ['name_en' => 'Faith & Giving', 'name_sw' => 'Dini', 'icon' => 'volunteer_activism_rounded', 'color' => '5C6BC0', 'sort_order' => 12, 'group_name' => 'community', 'module_tag' => 'faith'],
    ['name_en' => 'Contributions', 'name_sw' => 'Michango', 'icon' => 'handshake_rounded', 'color' => '26A69A', 'sort_order' => 13, 'group_name' => 'community', 'module_tag' => 'michango'],
    ['name_en' => 'Savings', 'name_sw' => 'Akiba', 'icon' => 'savings_rounded', 'color' => '009688', 'sort_order' => 14, 'group_name' => 'financial', 'module_tag' => 'savings'],
    ['name_en' => 'Debt & Loans', 'name_sw' => 'Deni', 'icon' => 'account_balance_wallet_rounded', 'color' => 'F44336', 'sort_order' => 15, 'group_name' => 'financial', 'module_tag' => 'debt'],
    ['name_en' => 'Insurance', 'name_sw' => 'Bima', 'icon' => 'health_and_safety_rounded', 'color' => '1565C0', 'sort_order' => 16, 'group_name' => 'financial', 'module_tag' => 'insurance'],
    ['name_en' => 'Emergency Fund', 'name_sw' => 'Dharura', 'icon' => 'warning_rounded', 'color' => 'FF5722', 'sort_order' => 17, 'group_name' => 'financial', 'module_tag' => 'emergency'],
    ['name_en' => 'Business Expenses', 'name_sw' => 'Biashara', 'icon' => 'business_center_rounded', 'color' => '455A64', 'sort_order' => 18, 'group_name' => 'business', 'module_tag' => 'business'],
];
foreach (\\\$envelopes as \\\$env) {
    \\\$exists = DB::table('budget_envelope_defaults')->where('module_tag', \\\$env['module_tag'])->exists();
    if (!\\\$exists) {
        DB::table('budget_envelope_defaults')->insert(array_merge(\\\$env, [
            'is_active' => true,
            'created_at' => now(),
            'updated_at' => now(),
        ]));
    }
}
echo 'Seeded ' . DB::table('budget_envelope_defaults')->count() . ' envelope defaults';
\""
```

- [ ] **Step 3: Verify tables exist**

```bash
sshpass -p 'ZimaBlueApps' ssh -o StrictHostKeyChecking=no root@172.240.241.180 "cd /var/www/tajiri.zimasystems.com && php artisan tinker --execute=\"
\\\$tables = ['income_records', 'expenditure_records', 'budget_envelope_defaults', 'budget_user_envelopes', 'budget_goals', 'budget_periods'];
foreach (\\\$tables as \\\$t) {
    \\\$exists = DB::select(\\\"SELECT to_regclass('public.\\\$t') AS exists\\\");
    echo \\\$t . ': ' . (\\\$exists[0]->exists ? 'OK' : 'MISSING') . PHP_EOL;
}
echo 'Envelope defaults count: ' . DB::table('budget_envelope_defaults')->count();
\""
```

---

## Task 2: Backend — IncomeController

**File:** `app/Http/Controllers/Api/IncomeController.php` on `172.240.241.180:/var/www/tajiri.zimasystems.com`

- [ ] **Step 1: Create IncomeController.php**

```bash
sshpass -p 'ZimaBlueApps' ssh -o StrictHostKeyChecking=no root@172.240.241.180 "cat > /var/www/tajiri.zimasystems.com/app/Http/Controllers/Api/IncomeController.php << 'PHPEOF'
<?php

namespace App\Http\Controllers\Api;

use App\Http\Controllers\Controller;
use Illuminate\Http\Request;
use Illuminate\Support\Facades\DB;
use Illuminate\Support\Facades\Validator;

class IncomeController extends Controller
{
    /**
     * POST /api/income
     * Record a new income event.
     */
    public function store(Request $request)
    {
        $validator = Validator::make($request->all(), [
            'amount'        => 'required|numeric|min:0.01',
            'source'        => 'required|string|max:50',
            'description'   => 'required|string|max:500',
            'source_module' => 'nullable|string|max:50',
            'reference_id'  => 'nullable|string|max:100',
            'metadata'      => 'nullable|array',
            'date'          => 'nullable|date',
            'is_recurring'  => 'nullable|boolean',
        ]);

        if ($validator->fails()) {
            return response()->json([
                'success' => false,
                'message' => 'Validation failed',
                'errors'  => $validator->errors(),
            ], 422);
        }

        $userId = $request->user()->id;

        // Deduplicate by reference_id
        if ($request->reference_id) {
            $existing = DB::table('income_records')
                ->where('reference_id', $request->reference_id)
                ->where('user_id', $userId)
                ->first();
            if ($existing) {
                return response()->json([
                    'success' => true,
                    'message' => 'Income already recorded (duplicate reference_id)',
                    'data'    => $existing,
                ]);
            }
        }

        $id = DB::table('income_records')->insertGetId([
            'user_id'       => $userId,
            'amount'        => $request->amount,
            'source'        => $request->source,
            'source_module' => $request->source_module,
            'description'   => $request->description,
            'reference_id'  => $request->reference_id,
            'metadata'      => $request->metadata ? json_encode($request->metadata) : null,
            'date'          => $request->date ?? now(),
            'is_recurring'  => $request->is_recurring ?? false,
            'created_at'    => now(),
            'updated_at'    => now(),
        ]);

        $record = DB::table('income_records')->find($id);

        return response()->json([
            'success' => true,
            'message' => 'Income recorded successfully',
            'data'    => $record,
        ], 201);
    }

    /**
     * GET /api/income
     * List income records for the authenticated user.
     * Query params: source, source_module, from, to, page, per_page
     */
    public function index(Request $request)
    {
        $userId  = $request->user()->id;
        $perPage = min((int) ($request->per_page ?? 50), 100);
        $page    = max((int) ($request->page ?? 1), 1);
        $offset  = ($page - 1) * $perPage;

        $query = DB::table('income_records')->where('user_id', $userId);

        if ($request->source) {
            $query->where('source', $request->source);
        }
        if ($request->source_module) {
            $query->where('source_module', $request->source_module);
        }
        if ($request->from) {
            $query->where('date', '>=', $request->from);
        }
        if ($request->to) {
            $query->where('date', '<=', $request->to);
        }

        $total = $query->count();
        $records = $query->orderBy('date', 'desc')
            ->offset($offset)
            ->limit($perPage)
            ->get();

        return response()->json([
            'success' => true,
            'data'    => [
                'records'  => $records,
                'total'    => $total,
                'page'     => $page,
                'per_page' => $perPage,
                'has_more' => ($offset + $perPage) < $total,
            ],
        ]);
    }

    /**
     * GET /api/income/summary
     * Income summary for a period (daily, weekly, monthly).
     * Query params: period (required)
     */
    public function summary(Request $request)
    {
        $userId = $request->user()->id;
        $period = $request->period ?? 'monthly';

        // Calculate date range
        $now = now();
        switch ($period) {
            case 'daily':
                $from = $now->copy()->startOfDay();
                $to   = $now->copy()->endOfDay();
                $prevFrom = $now->copy()->subDay()->startOfDay();
                $prevTo   = $now->copy()->subDay()->endOfDay();
                break;
            case 'weekly':
                $from = $now->copy()->startOfWeek();
                $to   = $now->copy()->endOfWeek();
                $prevFrom = $now->copy()->subWeek()->startOfWeek();
                $prevTo   = $now->copy()->subWeek()->endOfWeek();
                break;
            default: // monthly
                $from = $now->copy()->startOfMonth();
                $to   = $now->copy()->endOfMonth();
                $prevFrom = $now->copy()->subMonth()->startOfMonth();
                $prevTo   = $now->copy()->subMonth()->endOfMonth();
                break;
        }

        // Current period totals
        $currentTotal = DB::table('income_records')
            ->where('user_id', $userId)
            ->whereBetween('date', [$from, $to])
            ->sum('amount');

        $currentCount = DB::table('income_records')
            ->where('user_id', $userId)
            ->whereBetween('date', [$from, $to])
            ->count();

        // By source
        $bySource = DB::table('income_records')
            ->where('user_id', $userId)
            ->whereBetween('date', [$from, $to])
            ->select('source', DB::raw('SUM(amount) as total'))
            ->groupBy('source')
            ->pluck('total', 'source')
            ->toArray();

        // By module
        $byModule = DB::table('income_records')
            ->where('user_id', $userId)
            ->whereBetween('date', [$from, $to])
            ->whereNotNull('source_module')
            ->select('source_module', DB::raw('SUM(amount) as total'))
            ->groupBy('source_module')
            ->pluck('total', 'source_module')
            ->toArray();

        // Previous period for trend calculation
        $prevTotal = DB::table('income_records')
            ->where('user_id', $userId)
            ->whereBetween('date', [$prevFrom, $prevTo])
            ->sum('amount');

        $trend = $prevTotal > 0
            ? round((($currentTotal - $prevTotal) / $prevTotal) * 100, 1)
            : ($currentTotal > 0 ? 100.0 : 0.0);

        return response()->json([
            'success' => true,
            'data'    => [
                'total_income'      => (float) $currentTotal,
                'transaction_count' => $currentCount,
                'by_source'         => $bySource,
                'by_module'         => $byModule,
                'trend'             => $trend,
                'period'            => $period,
                'from'              => $from->toISOString(),
                'to'                => $to->toISOString(),
            ],
        ]);
    }

    /**
     * GET /api/income/by-source
     * Income grouped by source for a specific month.
     * Query params: year (required), month (required)
     */
    public function bySource(Request $request)
    {
        $validator = Validator::make($request->all(), [
            'year'  => 'required|integer|min:2020|max:2099',
            'month' => 'required|integer|min:1|max:12',
        ]);

        if ($validator->fails()) {
            return response()->json([
                'success' => false,
                'message' => 'Validation failed',
                'errors'  => $validator->errors(),
            ], 422);
        }

        $userId = $request->user()->id;
        $from = "{$request->year}-" . str_pad($request->month, 2, '0', STR_PAD_LEFT) . "-01 00:00:00";
        $to   = date('Y-m-t 23:59:59', strtotime($from));

        $bySource = DB::table('income_records')
            ->where('user_id', $userId)
            ->whereBetween('date', [$from, $to])
            ->select('source', DB::raw('SUM(amount) as total'))
            ->groupBy('source')
            ->pluck('total', 'source')
            ->toArray();

        return response()->json([
            'success' => true,
            'data'    => $bySource,
        ]);
    }

    /**
     * GET /api/income/recurring
     * Detect recurring income patterns.
     */
    public function recurring(Request $request)
    {
        $userId = $request->user()->id;

        // Find income sources that appear 2+ times with similar amounts
        $recurring = DB::table('income_records')
            ->where('user_id', $userId)
            ->where('date', '>=', now()->subMonths(3))
            ->select(
                'source',
                'source_module',
                'description',
                DB::raw('COUNT(*) as occurrence_count'),
                DB::raw('AVG(amount) as avg_amount'),
                DB::raw('MIN(amount) as min_amount'),
                DB::raw('MAX(amount) as max_amount'),
                DB::raw('MAX(date) as last_date')
            )
            ->groupBy('source', 'source_module', 'description')
            ->having(DB::raw('COUNT(*)'), '>=', 2)
            ->orderBy('avg_amount', 'desc')
            ->get();

        // Also include records explicitly flagged as recurring
        $flagged = DB::table('income_records')
            ->where('user_id', $userId)
            ->where('is_recurring', true)
            ->where('date', '>=', now()->subMonths(3))
            ->select(
                'source',
                'source_module',
                'description',
                DB::raw('COUNT(*) as occurrence_count'),
                DB::raw('AVG(amount) as avg_amount'),
                DB::raw('MIN(amount) as min_amount'),
                DB::raw('MAX(amount) as max_amount'),
                DB::raw('MAX(date) as last_date')
            )
            ->groupBy('source', 'source_module', 'description')
            ->get();

        // Merge, dedup by source+description
        $all = collect($recurring)->merge($flagged)->unique(function ($item) {
            return $item->source . '|' . $item->description;
        })->values();

        return response()->json([
            'success' => true,
            'data'    => $all,
        ]);
    }
}
PHPEOF"
```

- [ ] **Step 2: Verify file was created**

```bash
sshpass -p 'ZimaBlueApps' ssh -o StrictHostKeyChecking=no root@172.240.241.180 "head -5 /var/www/tajiri.zimasystems.com/app/Http/Controllers/Api/IncomeController.php"
```

---

## Task 3: Backend — ExpenditureController

**File:** `app/Http/Controllers/Api/ExpenditureController.php` on `172.240.241.180:/var/www/tajiri.zimasystems.com`

- [ ] **Step 1: Create ExpenditureController.php**

```bash
sshpass -p 'ZimaBlueApps' ssh -o StrictHostKeyChecking=no root@172.240.241.180 "cat > /var/www/tajiri.zimasystems.com/app/Http/Controllers/Api/ExpenditureController.php << 'PHPEOF'
<?php

namespace App\Http\Controllers\Api;

use App\Http\Controllers\Controller;
use Illuminate\Http\Request;
use Illuminate\Support\Facades\DB;
use Illuminate\Support\Facades\Validator;

class ExpenditureController extends Controller
{
    /**
     * POST /api/expenditures
     * Record a new expenditure event.
     */
    public function store(Request $request)
    {
        $validator = Validator::make($request->all(), [
            'amount'        => 'required|numeric|min:0.01',
            'category'      => 'required|string|max:50',
            'description'   => 'required|string|max:500',
            'source_module' => 'nullable|string|max:50',
            'reference_id'  => 'nullable|string|max:100',
            'envelope_tag'  => 'nullable|string|max:50',
            'metadata'      => 'nullable|array',
            'date'          => 'nullable|date',
            'is_recurring'  => 'nullable|boolean',
        ]);

        if ($validator->fails()) {
            return response()->json([
                'success' => false,
                'message' => 'Validation failed',
                'errors'  => $validator->errors(),
            ], 422);
        }

        $userId = $request->user()->id;

        // Deduplicate by reference_id
        if ($request->reference_id) {
            $existing = DB::table('expenditure_records')
                ->where('reference_id', $request->reference_id)
                ->where('user_id', $userId)
                ->first();
            if ($existing) {
                return response()->json([
                    'success' => true,
                    'message' => 'Expenditure already recorded (duplicate reference_id)',
                    'data'    => $existing,
                ]);
            }
        }

        $envelopeTag = $request->envelope_tag ?? $request->category;

        $id = DB::table('expenditure_records')->insertGetId([
            'user_id'       => $userId,
            'amount'        => $request->amount,
            'category'      => $request->category,
            'source_module' => $request->source_module,
            'description'   => $request->description,
            'reference_id'  => $request->reference_id,
            'envelope_tag'  => $envelopeTag,
            'metadata'      => $request->metadata ? json_encode($request->metadata) : null,
            'date'          => $request->date ?? now(),
            'is_recurring'  => $request->is_recurring ?? false,
            'created_at'    => now(),
            'updated_at'    => now(),
        ]);

        $record = DB::table('expenditure_records')->find($id);

        return response()->json([
            'success' => true,
            'message' => 'Expenditure recorded successfully',
            'data'    => $record,
        ], 201);
    }

    /**
     * GET /api/expenditures
     * List expenditure records for the authenticated user.
     * Query params: category, source_module, from, to, page, per_page
     */
    public function index(Request $request)
    {
        $userId  = $request->user()->id;
        $perPage = min((int) ($request->per_page ?? 50), 100);
        $page    = max((int) ($request->page ?? 1), 1);
        $offset  = ($page - 1) * $perPage;

        $query = DB::table('expenditure_records')->where('user_id', $userId);

        if ($request->category) {
            $query->where('category', $request->category);
        }
        if ($request->source_module) {
            $query->where('source_module', $request->source_module);
        }
        if ($request->from) {
            $query->where('date', '>=', $request->from);
        }
        if ($request->to) {
            $query->where('date', '<=', $request->to);
        }

        $total = $query->count();
        $records = $query->orderBy('date', 'desc')
            ->offset($offset)
            ->limit($perPage)
            ->get();

        return response()->json([
            'success' => true,
            'data'    => [
                'records'  => $records,
                'total'    => $total,
                'page'     => $page,
                'per_page' => $perPage,
                'has_more' => ($offset + $perPage) < $total,
            ],
        ]);
    }

    /**
     * GET /api/expenditures/summary
     * Expenditure summary for a period (daily, weekly, monthly).
     * Query params: period (required)
     */
    public function summary(Request $request)
    {
        $userId = $request->user()->id;
        $period = $request->period ?? 'monthly';

        $now = now();
        switch ($period) {
            case 'daily':
                $from = $now->copy()->startOfDay();
                $to   = $now->copy()->endOfDay();
                $prevFrom = $now->copy()->subDay()->startOfDay();
                $prevTo   = $now->copy()->subDay()->endOfDay();
                break;
            case 'weekly':
                $from = $now->copy()->startOfWeek();
                $to   = $now->copy()->endOfWeek();
                $prevFrom = $now->copy()->subWeek()->startOfWeek();
                $prevTo   = $now->copy()->subWeek()->endOfWeek();
                break;
            default:
                $from = $now->copy()->startOfMonth();
                $to   = $now->copy()->endOfMonth();
                $prevFrom = $now->copy()->subMonth()->startOfMonth();
                $prevTo   = $now->copy()->subMonth()->endOfMonth();
                break;
        }

        $currentTotal = DB::table('expenditure_records')
            ->where('user_id', $userId)
            ->whereBetween('date', [$from, $to])
            ->sum('amount');

        $currentCount = DB::table('expenditure_records')
            ->where('user_id', $userId)
            ->whereBetween('date', [$from, $to])
            ->count();

        $byCategory = DB::table('expenditure_records')
            ->where('user_id', $userId)
            ->whereBetween('date', [$from, $to])
            ->select('category', DB::raw('SUM(amount) as total'))
            ->groupBy('category')
            ->pluck('total', 'category')
            ->toArray();

        $byModule = DB::table('expenditure_records')
            ->where('user_id', $userId)
            ->whereBetween('date', [$from, $to])
            ->whereNotNull('source_module')
            ->select('source_module', DB::raw('SUM(amount) as total'))
            ->groupBy('source_module')
            ->pluck('total', 'source_module')
            ->toArray();

        $prevTotal = DB::table('expenditure_records')
            ->where('user_id', $userId)
            ->whereBetween('date', [$prevFrom, $prevTo])
            ->sum('amount');

        $trend = $prevTotal > 0
            ? round((($currentTotal - $prevTotal) / $prevTotal) * 100, 1)
            : ($currentTotal > 0 ? 100.0 : 0.0);

        return response()->json([
            'success' => true,
            'data'    => [
                'total_spent'       => (float) $currentTotal,
                'transaction_count' => $currentCount,
                'by_category'       => $byCategory,
                'by_module'         => $byModule,
                'trend'             => $trend,
                'period'            => $period,
                'from'              => $from->toISOString(),
                'to'                => $to->toISOString(),
            ],
        ]);
    }

    /**
     * GET /api/expenditures/by-category
     * Expenditures grouped by category for a specific month.
     * Query params: year (required), month (required)
     */
    public function byCategory(Request $request)
    {
        $validator = Validator::make($request->all(), [
            'year'  => 'required|integer|min:2020|max:2099',
            'month' => 'required|integer|min:1|max:12',
        ]);

        if ($validator->fails()) {
            return response()->json([
                'success' => false,
                'message' => 'Validation failed',
                'errors'  => $validator->errors(),
            ], 422);
        }

        $userId = $request->user()->id;
        $from = "{$request->year}-" . str_pad($request->month, 2, '0', STR_PAD_LEFT) . "-01 00:00:00";
        $to   = date('Y-m-t 23:59:59', strtotime($from));

        $byCategory = DB::table('expenditure_records')
            ->where('user_id', $userId)
            ->whereBetween('date', [$from, $to])
            ->select('category', DB::raw('SUM(amount) as total'))
            ->groupBy('category')
            ->pluck('total', 'category')
            ->toArray();

        return response()->json([
            'success' => true,
            'data'    => $byCategory,
        ]);
    }

    /**
     * GET /api/expenditures/recurring
     * Detect recurring expenditure patterns.
     */
    public function recurring(Request $request)
    {
        $userId = $request->user()->id;

        $recurring = DB::table('expenditure_records')
            ->where('user_id', $userId)
            ->where('date', '>=', now()->subMonths(3))
            ->select(
                'category',
                'source_module',
                'description',
                DB::raw('COUNT(*) as occurrence_count'),
                DB::raw('AVG(amount) as avg_amount'),
                DB::raw('MIN(amount) as min_amount'),
                DB::raw('MAX(amount) as max_amount'),
                DB::raw('MAX(date) as last_date'),
                DB::raw('BOOL_OR(is_recurring) as is_confirmed')
            )
            ->groupBy('category', 'source_module', 'description')
            ->having(DB::raw('COUNT(*)'), '>=', 2)
            ->orderBy('avg_amount', 'desc')
            ->get();

        $flagged = DB::table('expenditure_records')
            ->where('user_id', $userId)
            ->where('is_recurring', true)
            ->where('date', '>=', now()->subMonths(3))
            ->select(
                'category',
                'source_module',
                'description',
                DB::raw('COUNT(*) as occurrence_count'),
                DB::raw('AVG(amount) as avg_amount'),
                DB::raw('MIN(amount) as min_amount'),
                DB::raw('MAX(amount) as max_amount'),
                DB::raw('MAX(date) as last_date'),
                DB::raw('TRUE as is_confirmed')
            )
            ->groupBy('category', 'source_module', 'description')
            ->get();

        $all = collect($recurring)->merge($flagged)->unique(function ($item) {
            return $item->category . '|' . $item->description;
        })->values();

        return response()->json([
            'success' => true,
            'data'    => $all,
        ]);
    }

    /**
     * GET /api/expenditures/upcoming
     * Predict upcoming expenses based on recurring patterns.
     */
    public function upcoming(Request $request)
    {
        $userId = $request->user()->id;
        $now = now();

        // Get confirmed recurring expenses with their last occurrence
        $recurring = DB::table('expenditure_records')
            ->where('user_id', $userId)
            ->where('date', '>=', $now->copy()->subMonths(3))
            ->select(
                'category',
                'description',
                DB::raw('AVG(amount) as expected_amount'),
                DB::raw('MAX(date) as last_date'),
                DB::raw('COUNT(*) as occurrences')
            )
            ->groupBy('category', 'description')
            ->having(DB::raw('COUNT(*)'), '>=', 2)
            ->get();

        $upcoming = [];
        foreach ($recurring as $rec) {
            $lastDate = \Carbon\Carbon::parse($rec->last_date);
            // Estimate next occurrence: roughly 30 days after last
            $nextDate = $lastDate->copy()->addMonth();

            // Only include if next date is within the next 30 days
            if ($nextDate->isBetween($now, $now->copy()->addDays(30))) {
                $upcoming[] = [
                    'category'        => $rec->category,
                    'description'     => $rec->description,
                    'expected_amount' => round((float) $rec->expected_amount, 2),
                    'expected_date'   => $nextDate->toDateString(),
                    'last_date'       => $rec->last_date,
                    'occurrences'     => $rec->occurrences,
                ];
            }
        }

        // Sort by expected_date
        usort($upcoming, fn($a, $b) => strcmp($a['expected_date'], $b['expected_date']));

        return response()->json([
            'success' => true,
            'data'    => $upcoming,
        ]);
    }

    /**
     * GET /api/expenditures/spending-pace
     * Calculate spending pace for a specific category in a month.
     * Query params: category (required), year (required), month (required)
     */
    public function spendingPace(Request $request)
    {
        $validator = Validator::make($request->all(), [
            'category' => 'required|string|max:50',
            'year'     => 'required|integer|min:2020|max:2099',
            'month'    => 'required|integer|min:1|max:12',
        ]);

        if ($validator->fails()) {
            return response()->json([
                'success' => false,
                'message' => 'Validation failed',
                'errors'  => $validator->errors(),
            ], 422);
        }

        $userId = $request->user()->id;
        $year   = $request->year;
        $month  = $request->month;
        $from   = "{$year}-" . str_pad($month, 2, '0', STR_PAD_LEFT) . "-01 00:00:00";
        $to     = date('Y-m-t 23:59:59', strtotime($from));
        $daysInMonth = (int) date('t', strtotime($from));
        $now = now();

        // Days elapsed and remaining
        $startOfMonth = \Carbon\Carbon::parse($from);
        $endOfMonth   = \Carbon\Carbon::parse($to);

        if ($now->lt($startOfMonth)) {
            $daysElapsed  = 0;
            $daysRemaining = $daysInMonth;
        } elseif ($now->gt($endOfMonth)) {
            $daysElapsed  = $daysInMonth;
            $daysRemaining = 0;
        } else {
            $daysElapsed  = $now->diffInDays($startOfMonth);
            $daysRemaining = $daysInMonth - $daysElapsed;
        }

        // Spent this month for this category
        $spent = (float) DB::table('expenditure_records')
            ->where('user_id', $userId)
            ->where('category', $request->category)
            ->whereBetween('date', [$from, $to])
            ->sum('amount');

        // User's envelope allocation for this category/month
        $envelope = DB::table('budget_user_envelopes')
            ->where('user_id', $userId)
            ->where('module_tag', $request->category)
            ->where('budget_year', $year)
            ->where('budget_month', $month)
            ->first();

        $allocated = $envelope ? (float) $envelope->allocated_amount : 0;
        $remaining = $allocated - $spent;
        $dailyAllowance = $daysRemaining > 0 ? $remaining / $daysRemaining : 0;

        // Projected total if current pace continues
        $projectedTotal = $daysElapsed > 0
            ? ($spent / $daysElapsed) * $daysInMonth
            : 0;

        // Status determination
        if ($spent > $allocated && $allocated > 0) {
            $status = 'over_budget';
        } elseif ($projectedTotal > $allocated && $allocated > 0) {
            $status = 'caution';
        } else {
            $status = 'on_track';
        }

        return response()->json([
            'success' => true,
            'data'    => [
                'category'        => $request->category,
                'allocated'       => $allocated,
                'spent'           => $spent,
                'remaining'       => round($remaining, 2),
                'days_remaining'  => $daysRemaining,
                'daily_allowance' => round(max($dailyAllowance, 0), 2),
                'projected_total' => round($projectedTotal, 2),
                'status'          => $status,
            ],
        ]);
    }
}
PHPEOF"
```

- [ ] **Step 2: Verify file was created**

```bash
sshpass -p 'ZimaBlueApps' ssh -o StrictHostKeyChecking=no root@172.240.241.180 "head -5 /var/www/tajiri.zimasystems.com/app/Http/Controllers/Api/ExpenditureController.php"
```

---

## Task 4: Backend — BudgetController

**File:** `app/Http/Controllers/Api/BudgetController.php` on `172.240.241.180:/var/www/tajiri.zimasystems.com`

- [ ] **Step 1: Create BudgetController.php**

```bash
sshpass -p 'ZimaBlueApps' ssh -o StrictHostKeyChecking=no root@172.240.241.180 "cat > /var/www/tajiri.zimasystems.com/app/Http/Controllers/Api/BudgetController.php << 'PHPEOF'
<?php

namespace App\Http\Controllers\Api;

use App\Http\Controllers\Controller;
use Illuminate\Http\Request;
use Illuminate\Support\Facades\DB;
use Illuminate\Support\Facades\Validator;

class BudgetController extends Controller
{
    /**
     * GET /api/budget/envelope-defaults
     * Returns all active default envelope templates.
     * Public (but auth required) — cached on device.
     */
    public function envelopeDefaults(Request $request)
    {
        $defaults = DB::table('budget_envelope_defaults')
            ->where('is_active', true)
            ->orderBy('sort_order')
            ->get();

        return response()->json([
            'success' => true,
            'data'    => $defaults,
        ]);
    }

    /**
     * GET /api/budget/envelopes
     * Returns authenticated user's envelopes for a given month.
     * Query params: year (required), month (required)
     * If no envelopes exist for that month, seeds from defaults.
     */
    public function userEnvelopes(Request $request)
    {
        $validator = Validator::make($request->all(), [
            'year'  => 'required|integer|min:2020|max:2099',
            'month' => 'required|integer|min:1|max:12',
        ]);

        if ($validator->fails()) {
            return response()->json([
                'success' => false,
                'message' => 'Validation failed',
                'errors'  => $validator->errors(),
            ], 422);
        }

        $userId = $request->user()->id;
        $year   = $request->year;
        $month  = $request->month;

        // Check if user has envelopes for this month
        $count = DB::table('budget_user_envelopes')
            ->where('user_id', $userId)
            ->where('budget_year', $year)
            ->where('budget_month', $month)
            ->count();

        if ($count === 0) {
            $this->seedUserEnvelopes($userId, $year, $month);
        }

        // Fetch envelopes with spent amounts from expenditure_records
        $from = "{$year}-" . str_pad($month, 2, '0', STR_PAD_LEFT) . "-01 00:00:00";
        $to   = date('Y-m-t 23:59:59', strtotime($from));

        $envelopes = DB::table('budget_user_envelopes as e')
            ->leftJoin(DB::raw("(
                SELECT envelope_tag, SUM(amount) as spent_amount
                FROM expenditure_records
                WHERE user_id = {$userId}
                  AND date >= '{$from}' AND date <= '{$to}'
                GROUP BY envelope_tag
            ) as s"), 'e.module_tag', '=', 's.envelope_tag')
            ->where('e.user_id', $userId)
            ->where('e.budget_year', $year)
            ->where('e.budget_month', $month)
            ->select(
                'e.*',
                DB::raw('COALESCE(s.spent_amount, 0) as spent_amount')
            )
            ->orderBy('e.sort_order')
            ->get();

        return response()->json([
            'success' => true,
            'data'    => $envelopes,
        ]);
    }

    /**
     * Seed user envelopes from defaults for a new month.
     * Copies allocations from previous month if available, otherwise 0.
     */
    private function seedUserEnvelopes(int $userId, int $year, int $month)
    {
        // Look for previous month's envelopes to carry over allocations
        $prevMonth = $month === 1 ? 12 : $month - 1;
        $prevYear  = $month === 1 ? $year - 1 : $year;

        $prevEnvelopes = DB::table('budget_user_envelopes')
            ->where('user_id', $userId)
            ->where('budget_year', $prevYear)
            ->where('budget_month', $prevMonth)
            ->get()
            ->keyBy('module_tag');

        $defaults = DB::table('budget_envelope_defaults')
            ->where('is_active', true)
            ->orderBy('sort_order')
            ->get();

        $now = now();
        $inserts = [];

        foreach ($defaults as $def) {
            $prev = $prevEnvelopes->get($def->module_tag);
            $allocation = $prev ? $prev->allocated_amount : 0;
            $rolloverAmount = 0;

            // If previous month had rollover enabled and leftover funds
            if ($prev && $prev->rollover) {
                // Calculate spent in previous month
                $prevFrom = "{$prevYear}-" . str_pad($prevMonth, 2, '0', STR_PAD_LEFT) . "-01 00:00:00";
                $prevTo   = date('Y-m-t 23:59:59', strtotime($prevFrom));
                $prevSpent = (float) DB::table('expenditure_records')
                    ->where('user_id', $userId)
                    ->where('envelope_tag', $def->module_tag)
                    ->whereBetween('date', [$prevFrom, $prevTo])
                    ->sum('amount');
                $leftover = $prev->allocated_amount - $prevSpent;
                if ($leftover > 0) {
                    $rolloverAmount = $leftover;
                }
            }

            $inserts[] = [
                'user_id'              => $userId,
                'default_envelope_id'  => $def->id,
                'name'                 => $prev ? $prev->name : $def->name_sw,
                'icon'                 => $prev ? $prev->icon : $def->icon,
                'color'                => $prev ? $prev->color : $def->color,
                'allocated_amount'     => $allocation,
                'sort_order'           => $prev ? $prev->sort_order : $def->sort_order,
                'module_tag'           => $def->module_tag,
                'is_hidden'            => $prev ? $prev->is_hidden : false,
                'rollover'             => $prev ? $prev->rollover : false,
                'rolled_over_amount'   => $rolloverAmount,
                'budget_year'          => $year,
                'budget_month'         => $month,
                'created_at'           => $now,
                'updated_at'           => $now,
            ];
        }

        // Also carry over any custom envelopes (no default_envelope_id)
        if ($prevEnvelopes->isNotEmpty()) {
            $customPrev = $prevEnvelopes->filter(fn($e) => is_null($e->default_envelope_id));
            foreach ($customPrev as $custom) {
                $inserts[] = [
                    'user_id'              => $userId,
                    'default_envelope_id'  => null,
                    'name'                 => $custom->name,
                    'icon'                 => $custom->icon,
                    'color'                => $custom->color,
                    'allocated_amount'     => $custom->allocated_amount,
                    'sort_order'           => $custom->sort_order,
                    'module_tag'           => $custom->module_tag,
                    'is_hidden'            => $custom->is_hidden,
                    'rollover'             => $custom->rollover,
                    'rolled_over_amount'   => 0,
                    'budget_year'          => $year,
                    'budget_month'         => $month,
                    'created_at'           => $now,
                    'updated_at'           => $now,
                ];
            }
        }

        if (!empty($inserts)) {
            DB::table('budget_user_envelopes')->insert($inserts);
        }
    }

    /**
     * POST /api/budget/envelopes
     * Create a custom envelope for the authenticated user.
     */
    public function createEnvelope(Request $request)
    {
        $validator = Validator::make($request->all(), [
            'name'             => 'required|string|max:100',
            'icon'             => 'nullable|string|max:100',
            'color'            => 'nullable|string|max:10',
            'allocated_amount' => 'nullable|numeric|min:0',
            'module_tag'       => 'nullable|string|max:50',
            'year'             => 'required|integer|min:2020|max:2099',
            'month'            => 'required|integer|min:1|max:12',
        ]);

        if ($validator->fails()) {
            return response()->json([
                'success' => false,
                'message' => 'Validation failed',
                'errors'  => $validator->errors(),
            ], 422);
        }

        $userId = $request->user()->id;

        // Determine sort_order (place at end)
        $maxOrder = DB::table('budget_user_envelopes')
            ->where('user_id', $userId)
            ->where('budget_year', $request->year)
            ->where('budget_month', $request->month)
            ->max('sort_order') ?? -1;

        $id = DB::table('budget_user_envelopes')->insertGetId([
            'user_id'              => $userId,
            'default_envelope_id'  => null,
            'name'                 => $request->name,
            'icon'                 => $request->icon ?? 'circle',
            'color'                => $request->color ?? '1A1A1A',
            'allocated_amount'     => $request->allocated_amount ?? 0,
            'sort_order'           => $maxOrder + 1,
            'module_tag'           => $request->module_tag ?? strtolower(str_replace(' ', '_', $request->name)),
            'is_hidden'            => false,
            'rollover'             => false,
            'rolled_over_amount'   => 0,
            'budget_year'          => $request->year,
            'budget_month'         => $request->month,
            'created_at'           => now(),
            'updated_at'           => now(),
        ]);

        $envelope = DB::table('budget_user_envelopes')->find($id);

        return response()->json([
            'success' => true,
            'message' => 'Envelope created successfully',
            'data'    => $envelope,
        ], 201);
    }

    /**
     * PUT /api/budget/envelopes/{id}
     * Update a user envelope (allocation, visibility, order, name, etc.).
     */
    public function updateEnvelope(Request $request, int $id)
    {
        $userId = $request->user()->id;

        $envelope = DB::table('budget_user_envelopes')
            ->where('id', $id)
            ->where('user_id', $userId)
            ->first();

        if (!$envelope) {
            return response()->json([
                'success' => false,
                'message' => 'Envelope not found',
            ], 404);
        }

        $updates = [];
        $fillable = ['name', 'icon', 'color', 'allocated_amount', 'sort_order', 'module_tag', 'is_hidden', 'rollover'];

        foreach ($fillable as $field) {
            if ($request->has($field)) {
                $updates[$field] = $request->$field;
            }
        }

        if (empty($updates)) {
            return response()->json([
                'success' => false,
                'message' => 'No fields to update',
            ], 422);
        }

        $updates['updated_at'] = now();

        DB::table('budget_user_envelopes')
            ->where('id', $id)
            ->update($updates);

        $updated = DB::table('budget_user_envelopes')->find($id);

        return response()->json([
            'success' => true,
            'message' => 'Envelope updated successfully',
            'data'    => $updated,
        ]);
    }

    /**
     * GET /api/budget/period
     * Get budget period summary for a month.
     * Query params: year (required), month (required)
     */
    public function period(Request $request)
    {
        $validator = Validator::make($request->all(), [
            'year'  => 'required|integer|min:2020|max:2099',
            'month' => 'required|integer|min:1|max:12',
        ]);

        if ($validator->fails()) {
            return response()->json([
                'success' => false,
                'message' => 'Validation failed',
                'errors'  => $validator->errors(),
            ], 422);
        }

        $userId = $request->user()->id;
        $year   = $request->year;
        $month  = $request->month;
        $from   = "{$year}-" . str_pad($month, 2, '0', STR_PAD_LEFT) . "-01 00:00:00";
        $to     = date('Y-m-t 23:59:59', strtotime($from));

        $totalIncome = (float) DB::table('income_records')
            ->where('user_id', $userId)
            ->whereBetween('date', [$from, $to])
            ->sum('amount');

        $totalSpent = (float) DB::table('expenditure_records')
            ->where('user_id', $userId)
            ->whereBetween('date', [$from, $to])
            ->sum('amount');

        $totalAllocated = (float) DB::table('budget_user_envelopes')
            ->where('user_id', $userId)
            ->where('budget_year', $year)
            ->where('budget_month', $month)
            ->where('is_hidden', false)
            ->sum('allocated_amount');

        // Upsert budget_periods row
        DB::table('budget_periods')->updateOrInsert(
            ['user_id' => $userId, 'year' => $year, 'month' => $month],
            [
                'total_income'    => $totalIncome,
                'total_allocated' => $totalAllocated,
                'total_spent'     => $totalSpent,
                'updated_at'      => now(),
            ]
        );

        return response()->json([
            'success' => true,
            'data'    => [
                'year'            => $year,
                'month'           => $month,
                'total_income'    => $totalIncome,
                'total_allocated' => $totalAllocated,
                'total_spent'     => $totalSpent,
                'unallocated'     => $totalIncome - $totalAllocated,
                'remaining'       => $totalAllocated - $totalSpent,
            ],
        ]);
    }

    /**
     * GET /api/budget/goals
     * List all savings goals for the authenticated user.
     */
    public function goals(Request $request)
    {
        $userId = $request->user()->id;

        $goals = DB::table('budget_goals')
            ->where('user_id', $userId)
            ->orderBy('created_at', 'desc')
            ->get();

        return response()->json([
            'success' => true,
            'data'    => $goals,
        ]);
    }

    /**
     * POST /api/budget/goals
     * Create a new savings goal.
     */
    public function createGoal(Request $request)
    {
        $validator = Validator::make($request->all(), [
            'name'          => 'required|string|max:200',
            'icon'          => 'nullable|string|max:100',
            'target_amount' => 'required|numeric|min:1',
            'deadline'      => 'nullable|date|after:today',
        ]);

        if ($validator->fails()) {
            return response()->json([
                'success' => false,
                'message' => 'Validation failed',
                'errors'  => $validator->errors(),
            ], 422);
        }

        $userId = $request->user()->id;

        $id = DB::table('budget_goals')->insertGetId([
            'user_id'       => $userId,
            'name'          => $request->name,
            'icon'          => $request->icon ?? 'flag',
            'target_amount' => $request->target_amount,
            'saved_amount'  => 0,
            'deadline'      => $request->deadline,
            'is_complete'   => false,
            'created_at'    => now(),
            'updated_at'    => now(),
        ]);

        $goal = DB::table('budget_goals')->find($id);

        return response()->json([
            'success' => true,
            'message' => 'Goal created successfully',
            'data'    => $goal,
        ], 201);
    }

    /**
     * PUT /api/budget/goals/{id}
     * Update a savings goal (name, target, deadline, saved_amount).
     */
    public function updateGoal(Request $request, int $id)
    {
        $userId = $request->user()->id;

        $goal = DB::table('budget_goals')
            ->where('id', $id)
            ->where('user_id', $userId)
            ->first();

        if (!$goal) {
            return response()->json([
                'success' => false,
                'message' => 'Goal not found',
            ], 404);
        }

        $updates = [];
        $fillable = ['name', 'icon', 'target_amount', 'saved_amount', 'deadline', 'is_complete'];

        foreach ($fillable as $field) {
            if ($request->has($field)) {
                $updates[$field] = $request->$field;
            }
        }

        // If adding to saved_amount incrementally
        if ($request->has('add_amount') && is_numeric($request->add_amount)) {
            $updates['saved_amount'] = $goal->saved_amount + $request->add_amount;
            if ($updates['saved_amount'] >= $goal->target_amount) {
                $updates['is_complete'] = true;
            }
        }

        if (empty($updates)) {
            return response()->json([
                'success' => false,
                'message' => 'No fields to update',
            ], 422);
        }

        $updates['updated_at'] = now();

        DB::table('budget_goals')
            ->where('id', $id)
            ->update($updates);

        $updated = DB::table('budget_goals')->find($id);

        return response()->json([
            'success' => true,
            'message' => 'Goal updated successfully',
            'data'    => $updated,
        ]);
    }

    /**
     * DELETE /api/budget/goals/{id}
     * Delete a savings goal.
     */
    public function deleteGoal(Request $request, int $id)
    {
        $userId = $request->user()->id;

        $deleted = DB::table('budget_goals')
            ->where('id', $id)
            ->where('user_id', $userId)
            ->delete();

        if (!$deleted) {
            return response()->json([
                'success' => false,
                'message' => 'Goal not found',
            ], 404);
        }

        return response()->json([
            'success' => true,
            'message' => 'Goal deleted successfully',
        ]);
    }
}
PHPEOF"
```

- [ ] **Step 2: Verify file was created**

```bash
sshpass -p 'ZimaBlueApps' ssh -o StrictHostKeyChecking=no root@172.240.241.180 "head -5 /var/www/tajiri.zimasystems.com/app/Http/Controllers/Api/BudgetController.php"
```

---

## Task 5: Backend — Routes + Verification

**File:** `routes/api.php` on `172.240.241.180:/var/www/tajiri.zimasystems.com`

- [ ] **Step 1: Add routes to api.php**

First check the current end of the file to find where to append:

```bash
sshpass -p 'ZimaBlueApps' ssh -o StrictHostKeyChecking=no root@172.240.241.180 "tail -10 /var/www/tajiri.zimasystems.com/routes/api.php"
```

Then append the budget/income/expenditure routes inside the auth:sanctum middleware group. The exact insertion depends on the file structure, but the routes to add are:

```php
// ── Budget / Income / Expenditure ──────────────────────────────────
// Income
Route::get('/income',            [App\Http\Controllers\Api\IncomeController::class, 'index']);
Route::post('/income',           [App\Http\Controllers\Api\IncomeController::class, 'store']);
Route::get('/income/summary',    [App\Http\Controllers\Api\IncomeController::class, 'summary']);
Route::get('/income/by-source',  [App\Http\Controllers\Api\IncomeController::class, 'bySource']);
Route::get('/income/recurring',  [App\Http\Controllers\Api\IncomeController::class, 'recurring']);

// Expenditures
Route::get('/expenditures',              [App\Http\Controllers\Api\ExpenditureController::class, 'index']);
Route::post('/expenditures',             [App\Http\Controllers\Api\ExpenditureController::class, 'store']);
Route::get('/expenditures/summary',      [App\Http\Controllers\Api\ExpenditureController::class, 'summary']);
Route::get('/expenditures/by-category',  [App\Http\Controllers\Api\ExpenditureController::class, 'byCategory']);
Route::get('/expenditures/recurring',    [App\Http\Controllers\Api\ExpenditureController::class, 'recurring']);
Route::get('/expenditures/upcoming',     [App\Http\Controllers\Api\ExpenditureController::class, 'upcoming']);
Route::get('/expenditures/spending-pace',[App\Http\Controllers\Api\ExpenditureController::class, 'spendingPace']);

// Budget
Route::get('/budget/envelope-defaults',  [App\Http\Controllers\Api\BudgetController::class, 'envelopeDefaults']);
Route::get('/budget/envelopes',          [App\Http\Controllers\Api\BudgetController::class, 'userEnvelopes']);
Route::post('/budget/envelopes',         [App\Http\Controllers\Api\BudgetController::class, 'createEnvelope']);
Route::put('/budget/envelopes/{id}',     [App\Http\Controllers\Api\BudgetController::class, 'updateEnvelope']);
Route::get('/budget/period',             [App\Http\Controllers\Api\BudgetController::class, 'period']);
Route::get('/budget/goals',              [App\Http\Controllers\Api\BudgetController::class, 'goals']);
Route::post('/budget/goals',             [App\Http\Controllers\Api\BudgetController::class, 'createGoal']);
Route::put('/budget/goals/{id}',         [App\Http\Controllers\Api\BudgetController::class, 'updateGoal']);
Route::delete('/budget/goals/{id}',      [App\Http\Controllers\Api\BudgetController::class, 'deleteGoal']);
```

Use `sed` or a PHP script to insert these routes inside the `auth:sanctum` middleware group:

```bash
sshpass -p 'ZimaBlueApps' ssh -o StrictHostKeyChecking=no root@172.240.241.180 "cd /var/www/tajiri.zimasystems.com && php artisan tinker --execute=\"
// Find a safe place to inject — read last 20 lines to find the closing bracket
\\\$content = file_get_contents(base_path('routes/api.php'));
echo substr(\\\$content, -500);
\""
```

Then inject (adapt the injection point based on what you find):

```bash
sshpass -p 'ZimaBlueApps' ssh -o StrictHostKeyChecking=no root@172.240.241.180 "cd /var/www/tajiri.zimasystems.com && php -r \"
\\\$file = 'routes/api.php';
\\\$content = file_get_contents(\\\$file);

// Check if routes already exist
if (strpos(\\\$content, 'IncomeController') !== false) {
    echo 'Routes already exist, skipping.';
    exit(0);
}

\\\$routes = '
    // ── Budget / Income / Expenditure ──────────────────────────────────
    // Income
    Route::get(\\\"/income\\\",            [App\\\Http\\\Controllers\\\Api\\\IncomeController::class, \\\"index\\\"]);
    Route::post(\\\"/income\\\",           [App\\\Http\\\Controllers\\\Api\\\IncomeController::class, \\\"store\\\"]);
    Route::get(\\\"/income/summary\\\",    [App\\\Http\\\Controllers\\\Api\\\IncomeController::class, \\\"summary\\\"]);
    Route::get(\\\"/income/by-source\\\",  [App\\\Http\\\Controllers\\\Api\\\IncomeController::class, \\\"bySource\\\"]);
    Route::get(\\\"/income/recurring\\\",  [App\\\Http\\\Controllers\\\Api\\\IncomeController::class, \\\"recurring\\\"]);

    // Expenditures
    Route::get(\\\"/expenditures\\\",              [App\\\Http\\\Controllers\\\Api\\\ExpenditureController::class, \\\"index\\\"]);
    Route::post(\\\"/expenditures\\\",             [App\\\Http\\\Controllers\\\Api\\\ExpenditureController::class, \\\"store\\\"]);
    Route::get(\\\"/expenditures/summary\\\",      [App\\\Http\\\Controllers\\\Api\\\ExpenditureController::class, \\\"summary\\\"]);
    Route::get(\\\"/expenditures/by-category\\\",  [App\\\Http\\\Controllers\\\Api\\\ExpenditureController::class, \\\"byCategory\\\"]);
    Route::get(\\\"/expenditures/recurring\\\",    [App\\\Http\\\Controllers\\\Api\\\ExpenditureController::class, \\\"recurring\\\"]);
    Route::get(\\\"/expenditures/upcoming\\\",     [App\\\Http\\\Controllers\\\Api\\\ExpenditureController::class, \\\"upcoming\\\"]);
    Route::get(\\\"/expenditures/spending-pace\\\", [App\\\Http\\\Controllers\\\Api\\\ExpenditureController::class, \\\"spendingPace\\\"]);

    // Budget
    Route::get(\\\"/budget/envelope-defaults\\\",  [App\\\Http\\\Controllers\\\Api\\\BudgetController::class, \\\"envelopeDefaults\\\"]);
    Route::get(\\\"/budget/envelopes\\\",          [App\\\Http\\\Controllers\\\Api\\\BudgetController::class, \\\"userEnvelopes\\\"]);
    Route::post(\\\"/budget/envelopes\\\",         [App\\\Http\\\Controllers\\\Api\\\BudgetController::class, \\\"createEnvelope\\\"]);
    Route::put(\\\"/budget/envelopes/{id}\\\",     [App\\\Http\\\Controllers\\\Api\\\BudgetController::class, \\\"updateEnvelope\\\"]);
    Route::get(\\\"/budget/period\\\",             [App\\\Http\\\Controllers\\\Api\\\BudgetController::class, \\\"period\\\"]);
    Route::get(\\\"/budget/goals\\\",              [App\\\Http\\\Controllers\\\Api\\\BudgetController::class, \\\"goals\\\"]);
    Route::post(\\\"/budget/goals\\\",             [App\\\Http\\\Controllers\\\Api\\\BudgetController::class, \\\"createGoal\\\"]);
    Route::put(\\\"/budget/goals/{id}\\\",         [App\\\Http\\\Controllers\\\Api\\\BudgetController::class, \\\"updateGoal\\\"]);
    Route::delete(\\\"/budget/goals/{id}\\\",      [App\\\Http\\\Controllers\\\Api\\\BudgetController::class, \\\"deleteGoal\\\"]);

';

// Find the last closing of middleware group (last });) and insert before it
// Strategy: insert before the very last line that has });
\\\$lines = explode(\\\"\\n\\\", \\\$content);
\\\$lastClosingIndex = -1;
for (\\\$i = count(\\\$lines) - 1; \\\$i >= 0; \\\$i--) {
    if (trim(\\\$lines[\\\$i]) === '});') {
        \\\$lastClosingIndex = \\\$i;
        break;
    }
}

if (\\\$lastClosingIndex > 0) {
    array_splice(\\\$lines, \\\$lastClosingIndex, 0, [\\\$routes]);
    file_put_contents(\\\$file, implode(\\\"\\n\\\", \\\$lines));
    echo 'Routes injected successfully before line ' . \\\$lastClosingIndex;
} else {
    echo 'ERROR: Could not find closing }); in api.php';
}
\""
```

- [ ] **Step 2: Clear route cache**

```bash
sshpass -p 'ZimaBlueApps' ssh -o StrictHostKeyChecking=no root@172.240.241.180 "cd /var/www/tajiri.zimasystems.com && php artisan route:clear && php artisan route:list --path=income --columns=method,uri 2>/dev/null; php artisan route:list --path=expenditure --columns=method,uri 2>/dev/null; php artisan route:list --path=budget --columns=method,uri 2>/dev/null"
```

- [ ] **Step 3: Get a valid auth token for testing**

```bash
sshpass -p 'ZimaBlueApps' ssh -o StrictHostKeyChecking=no root@172.240.241.180 "cd /var/www/tajiri.zimasystems.com && php artisan tinker --execute=\"
\\\$user = DB::table('users')->first();
\\\$token = \\\$user ? App\\\Models\\\User::find(\\\$user->id)->createToken('test')->plainTextToken : 'NO_USER';
echo \\\$token;
\""
```

- [ ] **Step 4: Test each endpoint with curl**

Replace `TOKEN` with the token from step 3.

```bash
# Test: Record income
curl -s -X POST https://tajiri.zimasystems.com/api/income \
  -H "Authorization: Bearer TOKEN" \
  -H "Content-Type: application/json" \
  -d '{"amount": 50000, "source": "top_up", "description": "M-Pesa deposit", "source_module": "wallet", "reference_id": "test_income_001"}' | python3 -m json.tool

# Test: Get income list
curl -s "https://tajiri.zimasystems.com/api/income?page=1&per_page=5" \
  -H "Authorization: Bearer TOKEN" | python3 -m json.tool

# Test: Income summary
curl -s "https://tajiri.zimasystems.com/api/income/summary?period=monthly" \
  -H "Authorization: Bearer TOKEN" | python3 -m json.tool

# Test: Income by source
curl -s "https://tajiri.zimasystems.com/api/income/by-source?year=2026&month=4" \
  -H "Authorization: Bearer TOKEN" | python3 -m json.tool

# Test: Recurring income
curl -s "https://tajiri.zimasystems.com/api/income/recurring" \
  -H "Authorization: Bearer TOKEN" | python3 -m json.tool

# Test: Record expenditure
curl -s -X POST https://tajiri.zimasystems.com/api/expenditures \
  -H "Authorization: Bearer TOKEN" \
  -H "Content-Type: application/json" \
  -d '{"amount": 15000, "category": "chakula", "description": "Chakula cha mchana", "source_module": "food", "reference_id": "test_exp_001"}' | python3 -m json.tool

# Test: Get expenditures list
curl -s "https://tajiri.zimasystems.com/api/expenditures?page=1&per_page=5" \
  -H "Authorization: Bearer TOKEN" | python3 -m json.tool

# Test: Expenditure summary
curl -s "https://tajiri.zimasystems.com/api/expenditures/summary?period=monthly" \
  -H "Authorization: Bearer TOKEN" | python3 -m json.tool

# Test: Expenditure by category
curl -s "https://tajiri.zimasystems.com/api/expenditures/by-category?year=2026&month=4" \
  -H "Authorization: Bearer TOKEN" | python3 -m json.tool

# Test: Recurring expenditures
curl -s "https://tajiri.zimasystems.com/api/expenditures/recurring" \
  -H "Authorization: Bearer TOKEN" | python3 -m json.tool

# Test: Upcoming expenditures
curl -s "https://tajiri.zimasystems.com/api/expenditures/upcoming" \
  -H "Authorization: Bearer TOKEN" | python3 -m json.tool

# Test: Spending pace
curl -s "https://tajiri.zimasystems.com/api/expenditures/spending-pace?category=chakula&year=2026&month=4" \
  -H "Authorization: Bearer TOKEN" | python3 -m json.tool

# Test: Envelope defaults
curl -s "https://tajiri.zimasystems.com/api/budget/envelope-defaults" \
  -H "Authorization: Bearer TOKEN" | python3 -m json.tool

# Test: User envelopes (auto-seeds from defaults)
curl -s "https://tajiri.zimasystems.com/api/budget/envelopes?year=2026&month=4" \
  -H "Authorization: Bearer TOKEN" | python3 -m json.tool

# Test: Create custom envelope
curl -s -X POST https://tajiri.zimasystems.com/api/budget/envelopes \
  -H "Authorization: Bearer TOKEN" \
  -H "Content-Type: application/json" \
  -d '{"name": "Masomo ya Ziada", "icon": "menu_book_rounded", "year": 2026, "month": 4}' | python3 -m json.tool

# Test: Update envelope allocation
curl -s -X PUT https://tajiri.zimasystems.com/api/budget/envelopes/1 \
  -H "Authorization: Bearer TOKEN" \
  -H "Content-Type: application/json" \
  -d '{"allocated_amount": 150000}' | python3 -m json.tool

# Test: Budget period
curl -s "https://tajiri.zimasystems.com/api/budget/period?year=2026&month=4" \
  -H "Authorization: Bearer TOKEN" | python3 -m json.tool

# Test: Create goal
curl -s -X POST https://tajiri.zimasystems.com/api/budget/goals \
  -H "Authorization: Bearer TOKEN" \
  -H "Content-Type: application/json" \
  -d '{"name": "Laptop", "icon": "laptop", "target_amount": 800000, "deadline": "2026-12-31"}' | python3 -m json.tool

# Test: Get goals
curl -s "https://tajiri.zimasystems.com/api/budget/goals" \
  -H "Authorization: Bearer TOKEN" | python3 -m json.tool

# Test: Update goal (add to saved)
curl -s -X PUT https://tajiri.zimasystems.com/api/budget/goals/1 \
  -H "Authorization: Bearer TOKEN" \
  -H "Content-Type: application/json" \
  -d '{"add_amount": 50000}' | python3 -m json.tool

# Test: Delete goal
curl -s -X DELETE https://tajiri.zimasystems.com/api/budget/goals/1 \
  -H "Authorization: Bearer TOKEN" | python3 -m json.tool
```

- [ ] **Step 5: Clean up test data**

```bash
sshpass -p 'ZimaBlueApps' ssh -o StrictHostKeyChecking=no root@172.240.241.180 "cd /var/www/tajiri.zimasystems.com && php artisan tinker --execute=\"
DB::table('income_records')->where('reference_id', 'like', 'test_%')->delete();
DB::table('expenditure_records')->where('reference_id', 'like', 'test_%')->delete();
echo 'Test data cleaned';
\""
```

---

## Task 6: Frontend — Models

**File:** `lib/models/budget_models.dart` (rewrite)

- [ ] **Step 1: Rewrite budget_models.dart with all new models**

Replace the entire contents of `lib/models/budget_models.dart` with:

```dart
// lib/models/budget_models.dart
// Budget module models — all backend-driven via API.
// Replaces the old local-only models.

// ── Parsing helpers ──────────────────────────────────────────────────
int? _parseInt(dynamic v) {
  if (v == null) return null;
  if (v is int) return v;
  if (v is double) return v.toInt();
  if (v is String) return int.tryParse(v);
  return null;
}

double _parseDouble(dynamic v) {
  if (v == null) return 0.0;
  if (v is double) return v;
  if (v is int) return v.toDouble();
  if (v is String) return double.tryParse(v) ?? 0.0;
  return 0.0;
}

bool _parseBool(dynamic v) {
  if (v == null) return false;
  if (v is bool) return v;
  if (v is int) return v == 1;
  if (v is String) return v == 'true' || v == '1';
  return false;
}

// ── IncomeRecord ─────────────────────────────────────────────────────

class IncomeRecord {
  final int? id;
  final int userId;
  final double amount;
  final String source;
  final String? sourceModule;
  final String description;
  final String? referenceId;
  final Map<String, dynamic>? metadata;
  final DateTime date;
  final bool isRecurring;
  final DateTime createdAt;

  IncomeRecord({
    this.id,
    required this.userId,
    required this.amount,
    required this.source,
    this.sourceModule,
    required this.description,
    this.referenceId,
    this.metadata,
    required this.date,
    this.isRecurring = false,
    DateTime? createdAt,
  }) : createdAt = createdAt ?? DateTime.now();

  factory IncomeRecord.fromJson(Map<String, dynamic> json) {
    Map<String, dynamic>? meta;
    if (json['metadata'] is Map) {
      meta = Map<String, dynamic>.from(json['metadata'] as Map);
    } else if (json['metadata'] is String && (json['metadata'] as String).isNotEmpty) {
      try {
        meta = Map<String, dynamic>.from(
          _jsonDecode(json['metadata'] as String) as Map,
        );
      } catch (_) {}
    }

    return IncomeRecord(
      id: _parseInt(json['id']),
      userId: _parseInt(json['user_id']) ?? 0,
      amount: _parseDouble(json['amount']),
      source: json['source'] as String? ?? 'manual',
      sourceModule: json['source_module'] as String?,
      description: json['description'] as String? ?? '',
      referenceId: json['reference_id'] as String?,
      metadata: meta,
      date: json['date'] != null
          ? DateTime.parse(json['date'] as String)
          : DateTime.now(),
      isRecurring: _parseBool(json['is_recurring']),
      createdAt: json['created_at'] != null
          ? DateTime.parse(json['created_at'] as String)
          : DateTime.now(),
    );
  }

  Map<String, dynamic> toJson() => {
        if (id != null) 'id': id,
        'user_id': userId,
        'amount': amount,
        'source': source,
        'source_module': sourceModule,
        'description': description,
        'reference_id': referenceId,
        'metadata': metadata,
        'date': date.toIso8601String(),
        'is_recurring': isRecurring,
      };
}

// ── ExpenditureRecord ────────────────────────────────────────────────

class ExpenditureRecord {
  final int? id;
  final int userId;
  final double amount;
  final String category;
  final String? sourceModule;
  final String description;
  final String? referenceId;
  final String? envelopeTag;
  final Map<String, dynamic>? metadata;
  final DateTime date;
  final bool isRecurring;
  final DateTime createdAt;

  ExpenditureRecord({
    this.id,
    required this.userId,
    required this.amount,
    required this.category,
    this.sourceModule,
    required this.description,
    this.referenceId,
    this.envelopeTag,
    this.metadata,
    required this.date,
    this.isRecurring = false,
    DateTime? createdAt,
  }) : createdAt = createdAt ?? DateTime.now();

  factory ExpenditureRecord.fromJson(Map<String, dynamic> json) {
    Map<String, dynamic>? meta;
    if (json['metadata'] is Map) {
      meta = Map<String, dynamic>.from(json['metadata'] as Map);
    } else if (json['metadata'] is String && (json['metadata'] as String).isNotEmpty) {
      try {
        meta = Map<String, dynamic>.from(
          _jsonDecode(json['metadata'] as String) as Map,
        );
      } catch (_) {}
    }

    return ExpenditureRecord(
      id: _parseInt(json['id']),
      userId: _parseInt(json['user_id']) ?? 0,
      amount: _parseDouble(json['amount']),
      category: json['category'] as String? ?? 'other',
      sourceModule: json['source_module'] as String?,
      description: json['description'] as String? ?? '',
      referenceId: json['reference_id'] as String?,
      envelopeTag: json['envelope_tag'] as String?,
      metadata: meta,
      date: json['date'] != null
          ? DateTime.parse(json['date'] as String)
          : DateTime.now(),
      isRecurring: _parseBool(json['is_recurring']),
      createdAt: json['created_at'] != null
          ? DateTime.parse(json['created_at'] as String)
          : DateTime.now(),
    );
  }

  Map<String, dynamic> toJson() => {
        if (id != null) 'id': id,
        'user_id': userId,
        'amount': amount,
        'category': category,
        'source_module': sourceModule,
        'description': description,
        'reference_id': referenceId,
        'envelope_tag': envelopeTag,
        'metadata': metadata,
        'date': date.toIso8601String(),
        'is_recurring': isRecurring,
      };
}

// ── BudgetEnvelope ───────────────────────────────────────────────────

class BudgetEnvelope {
  final int? id;
  final int? defaultEnvelopeId;
  final String name;
  final String icon;
  final String color;
  final double allocatedAmount;
  final double spentAmount;
  final int order;
  final String? moduleTag;
  final bool isHidden;
  final bool rollover;
  final double rolledOverAmount;
  final int budgetYear;
  final int budgetMonth;
  final DateTime createdAt;

  BudgetEnvelope({
    this.id,
    this.defaultEnvelopeId,
    required this.name,
    required this.icon,
    required this.color,
    this.allocatedAmount = 0,
    this.spentAmount = 0,
    this.order = 0,
    this.moduleTag,
    this.isHidden = false,
    this.rollover = false,
    this.rolledOverAmount = 0,
    this.budgetYear = 0,
    this.budgetMonth = 0,
    DateTime? createdAt,
  }) : createdAt = createdAt ?? DateTime.now();

  double get remainingAmount => allocatedAmount - spentAmount;
  double get percentUsed =>
      allocatedAmount > 0 ? (spentAmount / allocatedAmount * 100) : 0;
  bool get isOverBudget => spentAmount > allocatedAmount;
  double get effectiveAllocation => allocatedAmount + rolledOverAmount;

  factory BudgetEnvelope.fromJson(Map<String, dynamic> json) {
    return BudgetEnvelope(
      id: _parseInt(json['id']),
      defaultEnvelopeId: _parseInt(json['default_envelope_id']),
      name: json['name'] as String? ?? '',
      icon: json['icon'] as String? ?? 'circle',
      color: json['color'] as String? ?? '1A1A1A',
      allocatedAmount: _parseDouble(json['allocated_amount']),
      spentAmount: _parseDouble(json['spent_amount']),
      order: _parseInt(json['sort_order']) ?? 0,
      moduleTag: json['module_tag'] as String?,
      isHidden: _parseBool(json['is_hidden']),
      rollover: _parseBool(json['rollover']),
      rolledOverAmount: _parseDouble(json['rolled_over_amount']),
      budgetYear: _parseInt(json['budget_year']) ?? 0,
      budgetMonth: _parseInt(json['budget_month']) ?? 0,
      createdAt: json['created_at'] != null
          ? DateTime.parse(json['created_at'] as String)
          : DateTime.now(),
    );
  }

  Map<String, dynamic> toJson() => {
        if (id != null) 'id': id,
        'default_envelope_id': defaultEnvelopeId,
        'name': name,
        'icon': icon,
        'color': color,
        'allocated_amount': allocatedAmount,
        'sort_order': order,
        'module_tag': moduleTag,
        'is_hidden': isHidden,
        'rollover': rollover,
        'rolled_over_amount': rolledOverAmount,
        'budget_year': budgetYear,
        'budget_month': budgetMonth,
      };

  BudgetEnvelope copyWith({
    int? id,
    int? defaultEnvelopeId,
    String? name,
    String? icon,
    String? color,
    double? allocatedAmount,
    double? spentAmount,
    int? order,
    String? moduleTag,
    bool? isHidden,
    bool? rollover,
    double? rolledOverAmount,
    int? budgetYear,
    int? budgetMonth,
  }) {
    return BudgetEnvelope(
      id: id ?? this.id,
      defaultEnvelopeId: defaultEnvelopeId ?? this.defaultEnvelopeId,
      name: name ?? this.name,
      icon: icon ?? this.icon,
      color: color ?? this.color,
      allocatedAmount: allocatedAmount ?? this.allocatedAmount,
      spentAmount: spentAmount ?? this.spentAmount,
      order: order ?? this.order,
      moduleTag: moduleTag ?? this.moduleTag,
      isHidden: isHidden ?? this.isHidden,
      rollover: rollover ?? this.rollover,
      rolledOverAmount: rolledOverAmount ?? this.rolledOverAmount,
      budgetYear: budgetYear ?? this.budgetYear,
      budgetMonth: budgetMonth ?? this.budgetMonth,
      createdAt: createdAt,
    );
  }
}

// ── EnvelopeDefault (server-side template) ───────────────────────────

class EnvelopeDefault {
  final int id;
  final String nameEn;
  final String nameSw;
  final String icon;
  final String color;
  final int sortOrder;
  final String groupName;
  final String moduleTag;
  final bool isActive;

  EnvelopeDefault({
    required this.id,
    required this.nameEn,
    required this.nameSw,
    required this.icon,
    required this.color,
    required this.sortOrder,
    required this.groupName,
    required this.moduleTag,
    this.isActive = true,
  });

  factory EnvelopeDefault.fromJson(Map<String, dynamic> json) {
    return EnvelopeDefault(
      id: _parseInt(json['id']) ?? 0,
      nameEn: json['name_en'] as String? ?? '',
      nameSw: json['name_sw'] as String? ?? '',
      icon: json['icon'] as String? ?? 'circle',
      color: json['color'] as String? ?? '1A1A1A',
      sortOrder: _parseInt(json['sort_order']) ?? 0,
      groupName: json['group_name'] as String? ?? 'essential',
      moduleTag: json['module_tag'] as String? ?? '',
      isActive: _parseBool(json['is_active']),
    );
  }
}

// ── BudgetGoal ───────────────────────────────────────────────────────

class BudgetGoal {
  final int? id;
  final int userId;
  final String name;
  final String icon;
  final double targetAmount;
  final double savedAmount;
  final DateTime? deadline;
  final bool isComplete;
  final DateTime createdAt;

  BudgetGoal({
    this.id,
    this.userId = 0,
    required this.name,
    this.icon = 'flag',
    required this.targetAmount,
    this.savedAmount = 0,
    this.deadline,
    this.isComplete = false,
    DateTime? createdAt,
  }) : createdAt = createdAt ?? DateTime.now();

  double get percentComplete =>
      targetAmount > 0 ? (savedAmount / targetAmount * 100).clamp(0, 100) : 0;
  double get remainingAmount =>
      (targetAmount - savedAmount).clamp(0, double.infinity);

  int? get monthsRemaining {
    if (deadline == null) return null;
    final now = DateTime.now();
    return (deadline!.year - now.year) * 12 + deadline!.month - now.month;
  }

  double? get monthlyTarget {
    final months = monthsRemaining;
    if (months == null || months <= 0) return null;
    return remainingAmount / months;
  }

  factory BudgetGoal.fromJson(Map<String, dynamic> json) {
    return BudgetGoal(
      id: _parseInt(json['id']),
      userId: _parseInt(json['user_id']) ?? 0,
      name: json['name'] as String? ?? '',
      icon: json['icon'] as String? ?? 'flag',
      targetAmount: _parseDouble(json['target_amount']),
      savedAmount: _parseDouble(json['saved_amount']),
      deadline: json['deadline'] != null
          ? DateTime.tryParse(json['deadline'] as String)
          : null,
      isComplete: _parseBool(json['is_complete']),
      createdAt: json['created_at'] != null
          ? DateTime.parse(json['created_at'] as String)
          : DateTime.now(),
    );
  }

  Map<String, dynamic> toJson() => {
        if (id != null) 'id': id,
        'name': name,
        'icon': icon,
        'target_amount': targetAmount,
        'saved_amount': savedAmount,
        'deadline': deadline?.toIso8601String(),
      };

  BudgetGoal copyWith({
    int? id,
    String? name,
    String? icon,
    double? targetAmount,
    double? savedAmount,
    DateTime? deadline,
    bool? isComplete,
  }) {
    return BudgetGoal(
      id: id ?? this.id,
      userId: userId,
      name: name ?? this.name,
      icon: icon ?? this.icon,
      targetAmount: targetAmount ?? this.targetAmount,
      savedAmount: savedAmount ?? this.savedAmount,
      deadline: deadline ?? this.deadline,
      isComplete: isComplete ?? this.isComplete,
      createdAt: createdAt,
    );
  }
}

// ── BudgetPeriod ─────────────────────────────────────────────────────

class BudgetPeriod {
  final int year;
  final int month;
  final double totalIncome;
  final double totalAllocated;
  final double totalSpent;

  BudgetPeriod({
    required this.year,
    required this.month,
    required this.totalIncome,
    required this.totalAllocated,
    required this.totalSpent,
  });

  double get unallocated => totalIncome - totalAllocated;
  double get remaining => totalAllocated - totalSpent;

  factory BudgetPeriod.fromJson(Map<String, dynamic> json) {
    return BudgetPeriod(
      year: _parseInt(json['year']) ?? DateTime.now().year,
      month: _parseInt(json['month']) ?? DateTime.now().month,
      totalIncome: _parseDouble(json['total_income']),
      totalAllocated: _parseDouble(json['total_allocated']),
      totalSpent: _parseDouble(json['total_spent']),
    );
  }
}

// ── IncomeSummary ────────────────────────────────────────────────────

class IncomeSummary {
  final double totalIncome;
  final int transactionCount;
  final Map<String, double> bySource;
  final Map<String, double> byModule;
  final double trend;
  final String period;

  IncomeSummary({
    required this.totalIncome,
    required this.transactionCount,
    required this.bySource,
    required this.byModule,
    required this.trend,
    required this.period,
  });

  factory IncomeSummary.fromJson(Map<String, dynamic> json) {
    return IncomeSummary(
      totalIncome: _parseDouble(json['total_income']),
      transactionCount: _parseInt(json['transaction_count']) ?? 0,
      bySource: _parseDoubleMap(json['by_source']),
      byModule: _parseDoubleMap(json['by_module']),
      trend: _parseDouble(json['trend']),
      period: json['period'] as String? ?? 'monthly',
    );
  }
}

// ── ExpenditureSummary ───────────────────────────────────────────────

class ExpenditureSummary {
  final double totalSpent;
  final int transactionCount;
  final Map<String, double> byCategory;
  final Map<String, double> byModule;
  final double trend;
  final String period;

  ExpenditureSummary({
    required this.totalSpent,
    required this.transactionCount,
    required this.byCategory,
    required this.byModule,
    required this.trend,
    required this.period,
  });

  factory ExpenditureSummary.fromJson(Map<String, dynamic> json) {
    return ExpenditureSummary(
      totalSpent: _parseDouble(json['total_spent']),
      transactionCount: _parseInt(json['transaction_count']) ?? 0,
      byCategory: _parseDoubleMap(json['by_category']),
      byModule: _parseDoubleMap(json['by_module']),
      trend: _parseDouble(json['trend']),
      period: json['period'] as String? ?? 'monthly',
    );
  }
}

// ── SpendingPace ─────────────────────────────────────────────────────

class SpendingPace {
  final String category;
  final double allocated;
  final double spent;
  final double remaining;
  final int daysRemaining;
  final double dailyAllowance;
  final double projectedTotal;
  final String status; // on_track, caution, over_budget

  SpendingPace({
    required this.category,
    required this.allocated,
    required this.spent,
    required this.remaining,
    required this.daysRemaining,
    required this.dailyAllowance,
    required this.projectedTotal,
    required this.status,
  });

  factory SpendingPace.fromJson(Map<String, dynamic> json) {
    return SpendingPace(
      category: json['category'] as String? ?? '',
      allocated: _parseDouble(json['allocated']),
      spent: _parseDouble(json['spent']),
      remaining: _parseDouble(json['remaining']),
      daysRemaining: _parseInt(json['days_remaining']) ?? 0,
      dailyAllowance: _parseDouble(json['daily_allowance']),
      projectedTotal: _parseDouble(json['projected_total']),
      status: json['status'] as String? ?? 'on_track',
    );
  }
}

// ── RecurringExpense ─────────────────────────────────────────────────

class RecurringExpense {
  final String category;
  final String? sourceModule;
  final String description;
  final int occurrenceCount;
  final double avgAmount;
  final double minAmount;
  final double maxAmount;
  final DateTime lastDate;
  final bool isConfirmed;

  RecurringExpense({
    required this.category,
    this.sourceModule,
    required this.description,
    required this.occurrenceCount,
    required this.avgAmount,
    required this.minAmount,
    required this.maxAmount,
    required this.lastDate,
    this.isConfirmed = false,
  });

  factory RecurringExpense.fromJson(Map<String, dynamic> json) {
    return RecurringExpense(
      category: json['category'] as String? ?? '',
      sourceModule: json['source_module'] as String?,
      description: json['description'] as String? ?? '',
      occurrenceCount: _parseInt(json['occurrence_count']) ?? 0,
      avgAmount: _parseDouble(json['avg_amount']),
      minAmount: _parseDouble(json['min_amount']),
      maxAmount: _parseDouble(json['max_amount']),
      lastDate: json['last_date'] != null
          ? DateTime.parse(json['last_date'] as String)
          : DateTime.now(),
      isConfirmed: _parseBool(json['is_confirmed']),
    );
  }
}

// ── RecurringIncome ──────────────────────────────────────────────────

class RecurringIncome {
  final String source;
  final String? sourceModule;
  final String description;
  final int occurrenceCount;
  final double avgAmount;
  final double minAmount;
  final double maxAmount;
  final DateTime lastDate;

  RecurringIncome({
    required this.source,
    this.sourceModule,
    required this.description,
    required this.occurrenceCount,
    required this.avgAmount,
    required this.minAmount,
    required this.maxAmount,
    required this.lastDate,
  });

  factory RecurringIncome.fromJson(Map<String, dynamic> json) {
    return RecurringIncome(
      source: json['source'] as String? ?? '',
      sourceModule: json['source_module'] as String?,
      description: json['description'] as String? ?? '',
      occurrenceCount: _parseInt(json['occurrence_count']) ?? 0,
      avgAmount: _parseDouble(json['avg_amount']),
      minAmount: _parseDouble(json['min_amount']),
      maxAmount: _parseDouble(json['max_amount']),
      lastDate: json['last_date'] != null
          ? DateTime.parse(json['last_date'] as String)
          : DateTime.now(),
    );
  }
}

// ── UpcomingExpense ──────────────────────────────────────────────────

class UpcomingExpense {
  final String category;
  final String description;
  final double expectedAmount;
  final DateTime expectedDate;
  final DateTime lastDate;
  final int occurrences;

  UpcomingExpense({
    required this.category,
    required this.description,
    required this.expectedAmount,
    required this.expectedDate,
    required this.lastDate,
    required this.occurrences,
  });

  factory UpcomingExpense.fromJson(Map<String, dynamic> json) {
    return UpcomingExpense(
      category: json['category'] as String? ?? '',
      description: json['description'] as String? ?? '',
      expectedAmount: _parseDouble(json['expected_amount']),
      expectedDate: json['expected_date'] != null
          ? DateTime.parse(json['expected_date'] as String)
          : DateTime.now(),
      lastDate: json['last_date'] != null
          ? DateTime.parse(json['last_date'] as String)
          : DateTime.now(),
      occurrences: _parseInt(json['occurrences']) ?? 0,
    );
  }
}

// ── Result classes for service calls ─────────────────────────────────

class IncomeListResult {
  final bool success;
  final List<IncomeRecord> records;
  final int total;
  final bool hasMore;
  final String? error;

  IncomeListResult({
    required this.success,
    this.records = const [],
    this.total = 0,
    this.hasMore = false,
    this.error,
  });
}

class ExpenditureListResult {
  final bool success;
  final List<ExpenditureRecord> records;
  final int total;
  final bool hasMore;
  final String? error;

  ExpenditureListResult({
    required this.success,
    this.records = const [],
    this.total = 0,
    this.hasMore = false,
    this.error,
  });
}

class EnvelopeListResult {
  final bool success;
  final List<BudgetEnvelope> envelopes;
  final String? error;

  EnvelopeListResult({
    required this.success,
    this.envelopes = const [],
    this.error,
  });
}

class GoalListResult {
  final bool success;
  final List<BudgetGoal> goals;
  final String? error;

  GoalListResult({
    required this.success,
    this.goals = const [],
    this.error,
  });
}

// ── Private helpers ──────────────────────────────────────────────────

Map<String, double> _parseDoubleMap(dynamic v) {
  if (v == null) return {};
  if (v is Map) {
    return v.map((key, value) => MapEntry(key.toString(), _parseDouble(value)));
  }
  return {};
}

dynamic _jsonDecode(String s) {
  // Avoid importing dart:convert at top level in case caller already has it
  // ignore: avoid_dynamic_calls
  return (const _JsonCodec()).decode(s);
}

class _JsonCodec {
  const _JsonCodec();
  dynamic decode(String s) {
    // Use dart:convert inline
    return _doDecode(s);
  }
}

dynamic _doDecode(String s) {
  // We import dart:convert at file level instead
  throw UnimplementedError('replaced by import');
}
```

**Important:** The `_jsonDecode` helper above is a placeholder. The real file must `import 'dart:convert';` at the top and use `jsonDecode` directly. Update the IncomeRecord and ExpenditureRecord `fromJson` methods to use `jsonDecode(json['metadata'] as String)` instead of `_jsonDecode`.

The actual file should start with:

```dart
import 'dart:convert';
```

And replace `_jsonDecode(...)` and the `_JsonCodec` class with direct `jsonDecode(...)` calls. Remove `_doDecode` and `_JsonCodec` entirely.

- [ ] **Step 2: Verify with flutter analyze**

```bash
cd /Volumes/DATA/PROJECTS/TAJIRI/TAJIRI-FRONTEND && flutter analyze lib/models/budget_models.dart
```

---

## Task 7: Frontend — IncomeService

**File:** `lib/services/income_service.dart` (create)

- [ ] **Step 1: Create income_service.dart**

```dart
// lib/services/income_service.dart
import 'dart:convert';
import 'package:flutter/foundation.dart';
import 'package:http/http.dart' as http;
import '../config/api_config.dart';
import '../models/budget_models.dart';

/// Central service for all income (money in) across the platform.
/// Static-method class — does not need instantiation.
///
/// Called by: BudgetService (summary, breakdown), BudgetHomeScreen (income total),
///           MonthlyReportScreen (income chart), ProfileScreen (earnings),
///           TeaService/Shangazi (AI budget insights).
class IncomeService {
  /// Record a new income event. Called by source modules when money comes in.
  ///
  /// Called from: WalletService.deposit(), SubscriptionService (tip/sub received),
  ///             ShopService (sale confirmed), TajirikaService (job completed),
  ///             ContributionService (withdrawal), LiveStreamService (gift received),
  ///             EventService (ticket sold), KikobaService (payout received).
  static Future<IncomeRecord?> recordIncome({
    required String token,
    required double amount,
    required String source,
    required String description,
    String? sourceModule,
    String? referenceId,
    Map<String, dynamic>? metadata,
    DateTime? date,
    bool isRecurring = false,
  }) async {
    try {
      final body = <String, dynamic>{
        'amount': amount,
        'source': source,
        'description': description,
      };
      if (sourceModule != null) body['source_module'] = sourceModule;
      if (referenceId != null) body['reference_id'] = referenceId;
      if (metadata != null) body['metadata'] = metadata;
      if (date != null) body['date'] = date.toIso8601String();
      if (isRecurring) body['is_recurring'] = true;

      final response = await http.post(
        Uri.parse('${ApiConfig.baseUrl}/income'),
        headers: ApiConfig.authHeaders(token),
        body: jsonEncode(body),
      );

      final json = jsonDecode(response.body) as Map<String, dynamic>;
      if (json['success'] == true && json['data'] != null) {
        return IncomeRecord.fromJson(
          Map<String, dynamic>.from(json['data'] as Map),
        );
      }
      debugPrint('[IncomeService] recordIncome failed: ${json['message']}');
      return null;
    } catch (e) {
      debugPrint('[IncomeService] recordIncome error: $e');
      return null;
    }
  }

  /// Get paginated income records for the authenticated user.
  ///
  /// Called from: BudgetHomeScreen (income list), IncomeBreakdownScreen,
  ///             EnvelopeDetailScreen (income transactions).
  static Future<IncomeListResult> getIncome({
    required String token,
    String? source,
    String? sourceModule,
    DateTime? from,
    DateTime? to,
    int page = 1,
    int perPage = 50,
  }) async {
    try {
      final params = <String, String>{
        'page': page.toString(),
        'per_page': perPage.toString(),
      };
      if (source != null) params['source'] = source;
      if (sourceModule != null) params['source_module'] = sourceModule;
      if (from != null) params['from'] = from.toIso8601String();
      if (to != null) params['to'] = to.toIso8601String();

      final uri = Uri.parse('${ApiConfig.baseUrl}/income')
          .replace(queryParameters: params);

      final response = await http.get(uri, headers: ApiConfig.authHeaders(token));
      final json = jsonDecode(response.body) as Map<String, dynamic>;

      if (json['success'] == true && json['data'] != null) {
        final data = json['data'] as Map<String, dynamic>;
        final records = (data['records'] as List? ?? [])
            .map((r) => IncomeRecord.fromJson(Map<String, dynamic>.from(r as Map)))
            .toList();
        return IncomeListResult(
          success: true,
          records: records,
          total: (data['total'] as num?)?.toInt() ?? 0,
          hasMore: data['has_more'] == true,
        );
      }

      return IncomeListResult(
        success: false,
        error: json['message'] as String?,
      );
    } catch (e) {
      debugPrint('[IncomeService] getIncome error: $e');
      return IncomeListResult(success: false, error: e.toString());
    }
  }

  /// Get income summary for a period (daily, weekly, monthly).
  ///
  /// Called from: BudgetHomeScreen (hero income number), BudgetService.getCurrentPeriod(),
  ///             MonthlyReportScreen, TeaService (Shangazi insights).
  static Future<IncomeSummary?> getIncomeSummary({
    required String token,
    required String period,
  }) async {
    try {
      final uri = Uri.parse('${ApiConfig.baseUrl}/income/summary')
          .replace(queryParameters: {'period': period});

      final response = await http.get(uri, headers: ApiConfig.authHeaders(token));
      final json = jsonDecode(response.body) as Map<String, dynamic>;

      if (json['success'] == true && json['data'] != null) {
        return IncomeSummary.fromJson(
          Map<String, dynamic>.from(json['data'] as Map),
        );
      }
      return null;
    } catch (e) {
      debugPrint('[IncomeService] getIncomeSummary error: $e');
      return null;
    }
  }

  /// Get income grouped by source for a specific month.
  ///
  /// Called from: IncomeBreakdownScreen (pie chart), MonthlyReportScreen.
  static Future<Map<String, double>> getIncomeBySource({
    required String token,
    required int year,
    required int month,
  }) async {
    try {
      final uri = Uri.parse('${ApiConfig.baseUrl}/income/by-source')
          .replace(queryParameters: {
        'year': year.toString(),
        'month': month.toString(),
      });

      final response = await http.get(uri, headers: ApiConfig.authHeaders(token));
      final json = jsonDecode(response.body) as Map<String, dynamic>;

      if (json['success'] == true && json['data'] != null) {
        final data = json['data'] as Map;
        return data.map(
          (key, value) => MapEntry(key.toString(), (value as num).toDouble()),
        );
      }
      return {};
    } catch (e) {
      debugPrint('[IncomeService] getIncomeBySource error: $e');
      return {};
    }
  }

  /// Get recurring income patterns (auto-detected).
  ///
  /// Called from: CashFlowForecastScreen (predicted income), RecurringExpensesScreen.
  static Future<List<RecurringIncome>> getRecurringIncome({
    required String token,
  }) async {
    try {
      final response = await http.get(
        Uri.parse('${ApiConfig.baseUrl}/income/recurring'),
        headers: ApiConfig.authHeaders(token),
      );
      final json = jsonDecode(response.body) as Map<String, dynamic>;

      if (json['success'] == true && json['data'] != null) {
        return (json['data'] as List)
            .map((r) => RecurringIncome.fromJson(Map<String, dynamic>.from(r as Map)))
            .toList();
      }
      return [];
    } catch (e) {
      debugPrint('[IncomeService] getRecurringIncome error: $e');
      return [];
    }
  }
}
```

- [ ] **Step 2: Verify with flutter analyze**

```bash
cd /Volumes/DATA/PROJECTS/TAJIRI/TAJIRI-FRONTEND && flutter analyze lib/services/income_service.dart
```

---

## Task 8: Frontend — ExpenditureService

**File:** `lib/services/expenditure_service.dart` (create)

- [ ] **Step 1: Create expenditure_service.dart**

```dart
// lib/services/expenditure_service.dart
import 'dart:convert';
import 'package:flutter/foundation.dart';
import 'package:http/http.dart' as http;
import '../config/api_config.dart';
import '../models/budget_models.dart';

/// Central service for all expenditures (money out) across the platform.
/// Static-method class — does not need instantiation.
///
/// Called by: BudgetService (spending by category, pace), BudgetHomeScreen (per-envelope spending),
///           EnvelopeDetailScreen (transaction list), MonthlyReportScreen (spending charts),
///           CashFlowForecastScreen (upcoming expenses), TeaService/Shangazi (spending alerts),
///           Other modules for budget context (Food, Transport, Shop checkout, etc.).
class ExpenditureService {
  /// Record a new expenditure event. Called by source modules when money goes out.
  ///
  /// Called from: WalletService.withdraw(), WalletService.transfer() (sent),
  ///             Housing module (rent), Food module (orders), Transport module (fare),
  ///             Bills module (TANESCO/DAWASCO/airtime), Doctor/Pharmacy modules,
  ///             ShopService (purchase), SubscriptionService.subscribe()/sendTip(),
  ///             ContributionService.donateToCampaign(), Insurance module, etc.
  static Future<ExpenditureRecord?> recordExpenditure({
    required String token,
    required double amount,
    required String category,
    required String description,
    String? sourceModule,
    String? referenceId,
    String? envelopeTag,
    Map<String, dynamic>? metadata,
    DateTime? date,
    bool isRecurring = false,
  }) async {
    try {
      final body = <String, dynamic>{
        'amount': amount,
        'category': category,
        'description': description,
      };
      if (sourceModule != null) body['source_module'] = sourceModule;
      if (referenceId != null) body['reference_id'] = referenceId;
      if (envelopeTag != null) body['envelope_tag'] = envelopeTag;
      if (metadata != null) body['metadata'] = metadata;
      if (date != null) body['date'] = date.toIso8601String();
      if (isRecurring) body['is_recurring'] = true;

      final response = await http.post(
        Uri.parse('${ApiConfig.baseUrl}/expenditures'),
        headers: ApiConfig.authHeaders(token),
        body: jsonEncode(body),
      );

      final json = jsonDecode(response.body) as Map<String, dynamic>;
      if (json['success'] == true && json['data'] != null) {
        return ExpenditureRecord.fromJson(
          Map<String, dynamic>.from(json['data'] as Map),
        );
      }
      debugPrint('[ExpenditureService] recordExpenditure failed: ${json['message']}');
      return null;
    } catch (e) {
      debugPrint('[ExpenditureService] recordExpenditure error: $e');
      return null;
    }
  }

  /// Get paginated expenditure records for the authenticated user.
  ///
  /// Called from: BudgetHomeScreen (recent transactions), EnvelopeDetailScreen (filtered by category),
  ///             AddTransactionScreen (recent for category suggestion).
  static Future<ExpenditureListResult> getExpenditures({
    required String token,
    String? category,
    String? sourceModule,
    DateTime? from,
    DateTime? to,
    int page = 1,
    int perPage = 50,
  }) async {
    try {
      final params = <String, String>{
        'page': page.toString(),
        'per_page': perPage.toString(),
      };
      if (category != null) params['category'] = category;
      if (sourceModule != null) params['source_module'] = sourceModule;
      if (from != null) params['from'] = from.toIso8601String();
      if (to != null) params['to'] = to.toIso8601String();

      final uri = Uri.parse('${ApiConfig.baseUrl}/expenditures')
          .replace(queryParameters: params);

      final response = await http.get(uri, headers: ApiConfig.authHeaders(token));
      final json = jsonDecode(response.body) as Map<String, dynamic>;

      if (json['success'] == true && json['data'] != null) {
        final data = json['data'] as Map<String, dynamic>;
        final records = (data['records'] as List? ?? [])
            .map((r) => ExpenditureRecord.fromJson(Map<String, dynamic>.from(r as Map)))
            .toList();
        return ExpenditureListResult(
          success: true,
          records: records,
          total: (data['total'] as num?)?.toInt() ?? 0,
          hasMore: data['has_more'] == true,
        );
      }

      return ExpenditureListResult(
        success: false,
        error: json['message'] as String?,
      );
    } catch (e) {
      debugPrint('[ExpenditureService] getExpenditures error: $e');
      return ExpenditureListResult(success: false, error: e.toString());
    }
  }

  /// Get expenditure summary for a period (daily, weekly, monthly).
  ///
  /// Called from: BudgetHomeScreen (hero spending number), BudgetService.getCurrentPeriod(),
  ///             MonthlyReportScreen, TeaService (Shangazi spending alerts).
  static Future<ExpenditureSummary?> getExpenditureSummary({
    required String token,
    required String period,
  }) async {
    try {
      final uri = Uri.parse('${ApiConfig.baseUrl}/expenditures/summary')
          .replace(queryParameters: {'period': period});

      final response = await http.get(uri, headers: ApiConfig.authHeaders(token));
      final json = jsonDecode(response.body) as Map<String, dynamic>;

      if (json['success'] == true && json['data'] != null) {
        return ExpenditureSummary.fromJson(
          Map<String, dynamic>.from(json['data'] as Map),
        );
      }
      return null;
    } catch (e) {
      debugPrint('[ExpenditureService] getExpenditureSummary error: $e');
      return null;
    }
  }

  /// Get expenditures grouped by category for a specific month.
  ///
  /// Called from: BudgetHomeScreen (per-envelope spent amounts), MonthlyReportScreen (breakdown chart).
  static Future<Map<String, double>> getExpenditureByCategory({
    required String token,
    required int year,
    required int month,
  }) async {
    try {
      final uri = Uri.parse('${ApiConfig.baseUrl}/expenditures/by-category')
          .replace(queryParameters: {
        'year': year.toString(),
        'month': month.toString(),
      });

      final response = await http.get(uri, headers: ApiConfig.authHeaders(token));
      final json = jsonDecode(response.body) as Map<String, dynamic>;

      if (json['success'] == true && json['data'] != null) {
        final data = json['data'] as Map;
        return data.map(
          (key, value) => MapEntry(key.toString(), (value as num).toDouble()),
        );
      }
      return {};
    } catch (e) {
      debugPrint('[ExpenditureService] getExpenditureByCategory error: $e');
      return {};
    }
  }

  /// Get recurring expenditure patterns (auto-detected + user-confirmed).
  ///
  /// Called from: RecurringExpensesScreen (list), CashFlowForecastScreen (upcoming bills),
  ///             BudgetHomeScreen (recurring expense summary).
  static Future<List<RecurringExpense>> getRecurringExpenses({
    required String token,
  }) async {
    try {
      final response = await http.get(
        Uri.parse('${ApiConfig.baseUrl}/expenditures/recurring'),
        headers: ApiConfig.authHeaders(token),
      );
      final json = jsonDecode(response.body) as Map<String, dynamic>;

      if (json['success'] == true && json['data'] != null) {
        return (json['data'] as List)
            .map((r) => RecurringExpense.fromJson(Map<String, dynamic>.from(r as Map)))
            .toList();
      }
      return [];
    } catch (e) {
      debugPrint('[ExpenditureService] getRecurringExpenses error: $e');
      return [];
    }
  }

  /// Get predicted upcoming expenses based on recurring patterns.
  ///
  /// Called from: CashFlowForecastScreen (projection graph), BudgetHomeScreen (safe-to-spend calc).
  static Future<List<UpcomingExpense>> getUpcomingExpenses({
    required String token,
  }) async {
    try {
      final response = await http.get(
        Uri.parse('${ApiConfig.baseUrl}/expenditures/upcoming'),
        headers: ApiConfig.authHeaders(token),
      );
      final json = jsonDecode(response.body) as Map<String, dynamic>;

      if (json['success'] == true && json['data'] != null) {
        return (json['data'] as List)
            .map((r) => UpcomingExpense.fromJson(Map<String, dynamic>.from(r as Map)))
            .toList();
      }
      return [];
    } catch (e) {
      debugPrint('[ExpenditureService] getUpcomingExpenses error: $e');
      return [];
    }
  }

  /// Get spending pace for a specific category in a month.
  ///
  /// Called from: EnvelopeDetailScreen (pace indicator), BudgetHomeScreen (envelope status badges),
  ///             Other modules for budget context at point of decision:
  ///             - Housing module: shows Kodi pace before rent payment
  ///             - Food module: shows Chakula pace when ordering
  ///             - Transport module: shows Usafiri pace after fare payment
  ///             - Shop: shows remaining budget at checkout
  ///             - Bills: shows if budget covers the bill
  ///             - Events: shows Burudani remaining before ticket purchase
  static Future<SpendingPace?> getSpendingPace({
    required String token,
    required String category,
    required int year,
    required int month,
  }) async {
    try {
      final uri = Uri.parse('${ApiConfig.baseUrl}/expenditures/spending-pace')
          .replace(queryParameters: {
        'category': category,
        'year': year.toString(),
        'month': month.toString(),
      });

      final response = await http.get(uri, headers: ApiConfig.authHeaders(token));
      final json = jsonDecode(response.body) as Map<String, dynamic>;

      if (json['success'] == true && json['data'] != null) {
        return SpendingPace.fromJson(
          Map<String, dynamic>.from(json['data'] as Map),
        );
      }
      return null;
    } catch (e) {
      debugPrint('[ExpenditureService] getSpendingPace error: $e');
      return null;
    }
  }
}
```

- [ ] **Step 2: Verify with flutter analyze**

```bash
cd /Volumes/DATA/PROJECTS/TAJIRI/TAJIRI-FRONTEND && flutter analyze lib/services/expenditure_service.dart
```

---

## Task 9: Frontend — BudgetService (Rewrite)

**File:** `lib/services/budget_service.dart` (rewrite)

This replaces the old local-only BudgetService that directly talked to WalletService/SubscriptionService/ShopService/ContributionService. The new BudgetService talks to the backend Budget API + IncomeService + ExpenditureService.

- [ ] **Step 1: Rewrite budget_service.dart**

```dart
// lib/services/budget_service.dart
//
// API-backed budget service. Replaces the old local-only BudgetService.
// Talks to: Backend budget API, IncomeService, ExpenditureService.
// Does NOT talk to: WalletService, SubscriptionService, ShopService, etc.
//   (those now report to IncomeService/ExpenditureService directly).
//
// Called from: BudgetHomeScreen, EnvelopeDetailScreen, AllocateFundsScreen,
//             SavingsGoalsScreen, MonthlyReportScreen, ProfileScreen (budget tab).
import 'dart:convert';
import 'package:flutter/foundation.dart';
import 'package:http/http.dart' as http;
import '../config/api_config.dart';
import '../models/budget_models.dart';
import 'budget_database.dart';
import 'income_service.dart';
import 'expenditure_service.dart';

class BudgetService {
  // ── Envelope Defaults ──────────────────────────────────────────────

  /// Fetch all default envelope templates from backend.
  /// Called once on first budget open, cached locally.
  ///
  /// Called from: BudgetHomeScreen.initState() (first open).
  static Future<List<EnvelopeDefault>> getEnvelopeDefaults({
    required String token,
  }) async {
    try {
      final response = await http.get(
        Uri.parse('${ApiConfig.baseUrl}/budget/envelope-defaults'),
        headers: ApiConfig.authHeaders(token),
      );
      final json = jsonDecode(response.body) as Map<String, dynamic>;
      if (json['success'] == true && json['data'] != null) {
        final list = (json['data'] as List)
            .map((r) => EnvelopeDefault.fromJson(Map<String, dynamic>.from(r as Map)))
            .toList();

        // Cache locally
        await BudgetDatabase.instance.cacheEnvelopeDefaults(list);
        return list;
      }
      return [];
    } catch (e) {
      debugPrint('[BudgetService] getEnvelopeDefaults error: $e');
      // Fall back to local cache
      return BudgetDatabase.instance.getCachedEnvelopeDefaults();
    }
  }

  // ── User Envelopes ─────────────────────────────────────────────────

  /// Get user's envelopes for a specific month, with spent amounts.
  /// Backend auto-seeds from defaults if no envelopes exist for the month.
  ///
  /// Called from: BudgetHomeScreen (envelope list with progress bars),
  ///             AllocateFundsScreen (allocation editor).
  static Future<EnvelopeListResult> getEnvelopes({
    required String token,
    required int year,
    required int month,
  }) async {
    try {
      final uri = Uri.parse('${ApiConfig.baseUrl}/budget/envelopes')
          .replace(queryParameters: {
        'year': year.toString(),
        'month': month.toString(),
      });

      final response = await http.get(uri, headers: ApiConfig.authHeaders(token));
      final json = jsonDecode(response.body) as Map<String, dynamic>;

      if (json['success'] == true && json['data'] != null) {
        final envelopes = (json['data'] as List)
            .map((r) => BudgetEnvelope.fromJson(Map<String, dynamic>.from(r as Map)))
            .toList();

        // Cache locally for offline access
        await BudgetDatabase.instance.cacheEnvelopes(envelopes, year, month);

        return EnvelopeListResult(success: true, envelopes: envelopes);
      }

      return EnvelopeListResult(
        success: false,
        error: json['message'] as String?,
      );
    } catch (e) {
      debugPrint('[BudgetService] getEnvelopes error: $e');
      // Fall back to local cache
      final cached = await BudgetDatabase.instance.getCachedEnvelopes(year, month);
      if (cached.isNotEmpty) {
        return EnvelopeListResult(success: true, envelopes: cached);
      }
      return EnvelopeListResult(success: false, error: e.toString());
    }
  }

  /// Create a custom envelope.
  ///
  /// Called from: BudgetHomeScreen (add envelope FAB/button).
  static Future<BudgetEnvelope?> createEnvelope({
    required String token,
    required String name,
    required int year,
    required int month,
    String? icon,
    String? color,
    double? allocatedAmount,
    String? moduleTag,
  }) async {
    try {
      final body = <String, dynamic>{
        'name': name,
        'year': year,
        'month': month,
      };
      if (icon != null) body['icon'] = icon;
      if (color != null) body['color'] = color;
      if (allocatedAmount != null) body['allocated_amount'] = allocatedAmount;
      if (moduleTag != null) body['module_tag'] = moduleTag;

      final response = await http.post(
        Uri.parse('${ApiConfig.baseUrl}/budget/envelopes'),
        headers: ApiConfig.authHeaders(token),
        body: jsonEncode(body),
      );

      final json = jsonDecode(response.body) as Map<String, dynamic>;
      if (json['success'] == true && json['data'] != null) {
        return BudgetEnvelope.fromJson(
          Map<String, dynamic>.from(json['data'] as Map),
        );
      }
      debugPrint('[BudgetService] createEnvelope failed: ${json['message']}');
      return null;
    } catch (e) {
      debugPrint('[BudgetService] createEnvelope error: $e');
      return null;
    }
  }

  /// Update an envelope (allocation, visibility, order, name, etc.).
  ///
  /// Called from: EnvelopeDetailScreen (edit allocation), AllocateFundsScreen (sliders),
  ///             BudgetHomeScreen (reorder, hide).
  static Future<BudgetEnvelope?> updateEnvelope({
    required String token,
    required int envelopeId,
    String? name,
    String? icon,
    String? color,
    double? allocatedAmount,
    int? sortOrder,
    bool? isHidden,
    bool? rollover,
  }) async {
    try {
      final body = <String, dynamic>{};
      if (name != null) body['name'] = name;
      if (icon != null) body['icon'] = icon;
      if (color != null) body['color'] = color;
      if (allocatedAmount != null) body['allocated_amount'] = allocatedAmount;
      if (sortOrder != null) body['sort_order'] = sortOrder;
      if (isHidden != null) body['is_hidden'] = isHidden;
      if (rollover != null) body['rollover'] = rollover;

      final response = await http.put(
        Uri.parse('${ApiConfig.baseUrl}/budget/envelopes/$envelopeId'),
        headers: ApiConfig.authHeaders(token),
        body: jsonEncode(body),
      );

      final json = jsonDecode(response.body) as Map<String, dynamic>;
      if (json['success'] == true && json['data'] != null) {
        return BudgetEnvelope.fromJson(
          Map<String, dynamic>.from(json['data'] as Map),
        );
      }
      debugPrint('[BudgetService] updateEnvelope failed: ${json['message']}');
      return null;
    } catch (e) {
      debugPrint('[BudgetService] updateEnvelope error: $e');
      return null;
    }
  }

  // ── Budget Period ──────────────────────────────────────────────────

  /// Get budget period summary (income, allocated, spent) for a month.
  ///
  /// Called from: BudgetHomeScreen (hero cards: wallet balance, unallocated, safe-to-spend).
  static Future<BudgetPeriod?> getPeriod({
    required String token,
    required int year,
    required int month,
  }) async {
    try {
      final uri = Uri.parse('${ApiConfig.baseUrl}/budget/period')
          .replace(queryParameters: {
        'year': year.toString(),
        'month': month.toString(),
      });

      final response = await http.get(uri, headers: ApiConfig.authHeaders(token));
      final json = jsonDecode(response.body) as Map<String, dynamic>;

      if (json['success'] == true && json['data'] != null) {
        final period = BudgetPeriod.fromJson(
          Map<String, dynamic>.from(json['data'] as Map),
        );
        // Cache locally
        await BudgetDatabase.instance.cachePeriod(period);
        return period;
      }
      return null;
    } catch (e) {
      debugPrint('[BudgetService] getPeriod error: $e');
      // Fall back to cache
      return BudgetDatabase.instance.getCachedPeriod(year, month);
    }
  }

  // ── Goals ──────────────────────────────────────────────────────────

  /// Get all savings goals.
  ///
  /// Called from: SavingsGoalsScreen (goal list), BudgetHomeScreen (goals summary card).
  static Future<GoalListResult> getGoals({
    required String token,
  }) async {
    try {
      final response = await http.get(
        Uri.parse('${ApiConfig.baseUrl}/budget/goals'),
        headers: ApiConfig.authHeaders(token),
      );
      final json = jsonDecode(response.body) as Map<String, dynamic>;

      if (json['success'] == true && json['data'] != null) {
        final goals = (json['data'] as List)
            .map((r) => BudgetGoal.fromJson(Map<String, dynamic>.from(r as Map)))
            .toList();

        // Cache locally
        await BudgetDatabase.instance.cacheGoals(goals);

        return GoalListResult(success: true, goals: goals);
      }

      return GoalListResult(success: false, error: json['message'] as String?);
    } catch (e) {
      debugPrint('[BudgetService] getGoals error: $e');
      final cached = await BudgetDatabase.instance.getCachedGoals();
      if (cached.isNotEmpty) {
        return GoalListResult(success: true, goals: cached);
      }
      return GoalListResult(success: false, error: e.toString());
    }
  }

  /// Create a new savings goal.
  ///
  /// Called from: SavingsGoalsScreen (add goal form).
  static Future<BudgetGoal?> createGoal({
    required String token,
    required String name,
    required double targetAmount,
    String? icon,
    DateTime? deadline,
  }) async {
    try {
      final body = <String, dynamic>{
        'name': name,
        'target_amount': targetAmount,
      };
      if (icon != null) body['icon'] = icon;
      if (deadline != null) body['deadline'] = deadline.toIso8601String().split('T').first;

      final response = await http.post(
        Uri.parse('${ApiConfig.baseUrl}/budget/goals'),
        headers: ApiConfig.authHeaders(token),
        body: jsonEncode(body),
      );

      final json = jsonDecode(response.body) as Map<String, dynamic>;
      if (json['success'] == true && json['data'] != null) {
        return BudgetGoal.fromJson(
          Map<String, dynamic>.from(json['data'] as Map),
        );
      }
      debugPrint('[BudgetService] createGoal failed: ${json['message']}');
      return null;
    } catch (e) {
      debugPrint('[BudgetService] createGoal error: $e');
      return null;
    }
  }

  /// Update a savings goal.
  ///
  /// Called from: SavingsGoalsScreen (edit goal form).
  static Future<BudgetGoal?> updateGoal({
    required String token,
    required int goalId,
    String? name,
    String? icon,
    double? targetAmount,
    double? savedAmount,
    DateTime? deadline,
    double? addAmount,
  }) async {
    try {
      final body = <String, dynamic>{};
      if (name != null) body['name'] = name;
      if (icon != null) body['icon'] = icon;
      if (targetAmount != null) body['target_amount'] = targetAmount;
      if (savedAmount != null) body['saved_amount'] = savedAmount;
      if (deadline != null) body['deadline'] = deadline.toIso8601String().split('T').first;
      if (addAmount != null) body['add_amount'] = addAmount;

      final response = await http.put(
        Uri.parse('${ApiConfig.baseUrl}/budget/goals/$goalId'),
        headers: ApiConfig.authHeaders(token),
        body: jsonEncode(body),
      );

      final json = jsonDecode(response.body) as Map<String, dynamic>;
      if (json['success'] == true && json['data'] != null) {
        return BudgetGoal.fromJson(
          Map<String, dynamic>.from(json['data'] as Map),
        );
      }
      debugPrint('[BudgetService] updateGoal failed: ${json['message']}');
      return null;
    } catch (e) {
      debugPrint('[BudgetService] updateGoal error: $e');
      return null;
    }
  }

  /// Add money to a savings goal.
  ///
  /// Called from: SavingsGoalsScreen ("Add to Goal" button), BudgetHomeScreen (quick contribute).
  static Future<BudgetGoal?> addToGoal({
    required String token,
    required int goalId,
    required double amount,
  }) async {
    return updateGoal(token: token, goalId: goalId, addAmount: amount);
  }

  /// Delete a savings goal.
  ///
  /// Called from: SavingsGoalsScreen (delete action).
  static Future<bool> deleteGoal({
    required String token,
    required int goalId,
  }) async {
    try {
      final response = await http.delete(
        Uri.parse('${ApiConfig.baseUrl}/budget/goals/$goalId'),
        headers: ApiConfig.authHeaders(token),
      );

      final json = jsonDecode(response.body) as Map<String, dynamic>;
      return json['success'] == true;
    } catch (e) {
      debugPrint('[BudgetService] deleteGoal error: $e');
      return false;
    }
  }

  // ── Convenience: Full budget load ──────────────────────────────────

  /// Load everything needed for the budget home screen in parallel.
  /// Uses stale-while-revalidate: returns cached data immediately,
  /// then fetches fresh data in background.
  ///
  /// Called from: BudgetHomeScreen.initState().
  static Future<BudgetSnapshot> loadBudgetSnapshot({
    required String token,
    required int year,
    required int month,
  }) async {
    final results = await Future.wait([
      getEnvelopes(token: token, year: year, month: month),
      getPeriod(token: token, year: year, month: month),
      getGoals(token: token),
      ExpenditureService.getUpcomingExpenses(token: token),
    ]);

    final envelopeResult = results[0] as EnvelopeListResult;
    final period = results[1] as BudgetPeriod?;
    final goalResult = results[2] as GoalListResult;
    final upcoming = results[3] as List<UpcomingExpense>;

    return BudgetSnapshot(
      envelopes: envelopeResult.envelopes,
      period: period,
      goals: goalResult.goals,
      upcomingExpenses: upcoming,
    );
  }
}

/// Full snapshot of budget state for the home screen.
class BudgetSnapshot {
  final List<BudgetEnvelope> envelopes;
  final BudgetPeriod? period;
  final List<BudgetGoal> goals;
  final List<UpcomingExpense> upcomingExpenses;

  BudgetSnapshot({
    this.envelopes = const [],
    this.period,
    this.goals = const [],
    this.upcomingExpenses = const [],
  });

  double get safeToSpend {
    if (period == null) return 0;
    final upcomingTotal =
        upcomingExpenses.fold<double>(0, (sum, e) => sum + e.expectedAmount);
    return period!.unallocated - upcomingTotal;
  }
}
```

- [ ] **Step 2: Verify with flutter analyze**

```bash
cd /Volumes/DATA/PROJECTS/TAJIRI/TAJIRI-FRONTEND && flutter analyze lib/services/budget_service.dart
```

---

## Task 10: Frontend — BudgetDatabase (Rewrite)

**File:** `lib/services/budget_database.dart` (rewrite)

Follows `SQLITE_ADOPTION_ROADMAP` pattern: singleton, `json_data TEXT` column, indexed columns, `sync_state` table, `pending_queue` table.

- [ ] **Step 1: Rewrite budget_database.dart**

```dart
// lib/services/budget_database.dart
//
// SQLite local cache for budget data. Follows MessageDatabase pattern:
// - Singleton with lazy init
// - json_data TEXT column for flexible field storage
// - Indexed columns for fast queries
// - sync_state table for delta sync
// - pending_queue for offline mutations
//
// Called from: BudgetService (cache reads/writes on every API call),
//             BudgetHomeScreen (offline-first: load from cache, then refresh).
import 'dart:convert';
import 'package:flutter/foundation.dart';
import 'package:sqflite/sqflite.dart';
import 'package:path/path.dart' as p;
import '../models/budget_models.dart';

class BudgetDatabase {
  static BudgetDatabase? _instance;
  static Database? _database;

  BudgetDatabase._();

  static BudgetDatabase get instance {
    _instance ??= BudgetDatabase._();
    return _instance!;
  }

  Future<Database> get database async {
    _database ??= await _initDatabase();
    return _database!;
  }

  Future<Database> _initDatabase() async {
    final dbPath = await getDatabasesPath();
    final path = p.join(dbPath, 'tajiri_budget_v2.db');
    debugPrint('[BudgetDB] Opening database at $path');
    return openDatabase(
      path,
      version: 1,
      onCreate: _onCreate,
    );
  }

  Future<void> _onCreate(Database db, int version) async {
    debugPrint('[BudgetDB] Creating tables (v$version)');

    // Envelope defaults cache
    await db.execute('''
      CREATE TABLE envelope_defaults (
        id INTEGER PRIMARY KEY,
        name_en TEXT NOT NULL,
        name_sw TEXT NOT NULL,
        icon TEXT NOT NULL,
        color TEXT NOT NULL DEFAULT '1A1A1A',
        sort_order INTEGER NOT NULL DEFAULT 0,
        group_name TEXT NOT NULL DEFAULT 'essential',
        module_tag TEXT NOT NULL,
        is_active INTEGER NOT NULL DEFAULT 1,
        json_data TEXT
      )
    ''');

    // User envelopes cache (per month)
    await db.execute('''
      CREATE TABLE envelopes (
        id INTEGER PRIMARY KEY,
        default_envelope_id INTEGER,
        name TEXT NOT NULL,
        icon TEXT NOT NULL DEFAULT 'circle',
        color TEXT NOT NULL DEFAULT '1A1A1A',
        allocated_amount REAL NOT NULL DEFAULT 0,
        spent_amount REAL NOT NULL DEFAULT 0,
        sort_order INTEGER NOT NULL DEFAULT 0,
        module_tag TEXT,
        is_hidden INTEGER NOT NULL DEFAULT 0,
        rollover INTEGER NOT NULL DEFAULT 0,
        rolled_over_amount REAL NOT NULL DEFAULT 0,
        budget_year INTEGER NOT NULL,
        budget_month INTEGER NOT NULL,
        created_at TEXT NOT NULL,
        json_data TEXT
      )
    ''');
    await db.execute('CREATE INDEX idx_env_period ON envelopes(budget_year, budget_month)');

    // Income records cache
    await db.execute('''
      CREATE TABLE income_records (
        id INTEGER PRIMARY KEY,
        user_id INTEGER NOT NULL,
        amount REAL NOT NULL,
        source TEXT NOT NULL,
        source_module TEXT,
        description TEXT NOT NULL DEFAULT '',
        reference_id TEXT,
        date TEXT NOT NULL,
        is_recurring INTEGER NOT NULL DEFAULT 0,
        created_at TEXT NOT NULL,
        json_data TEXT
      )
    ''');
    await db.execute('CREATE INDEX idx_inc_date ON income_records(date)');
    await db.execute('CREATE INDEX idx_inc_source ON income_records(source)');
    await db.execute('CREATE UNIQUE INDEX idx_inc_ref ON income_records(reference_id) WHERE reference_id IS NOT NULL');

    // Expenditure records cache
    await db.execute('''
      CREATE TABLE expenditure_records (
        id INTEGER PRIMARY KEY,
        user_id INTEGER NOT NULL,
        amount REAL NOT NULL,
        category TEXT NOT NULL,
        source_module TEXT,
        description TEXT NOT NULL DEFAULT '',
        reference_id TEXT,
        envelope_tag TEXT,
        date TEXT NOT NULL,
        is_recurring INTEGER NOT NULL DEFAULT 0,
        created_at TEXT NOT NULL,
        json_data TEXT
      )
    ''');
    await db.execute('CREATE INDEX idx_exp_date ON expenditure_records(date)');
    await db.execute('CREATE INDEX idx_exp_category ON expenditure_records(category)');
    await db.execute('CREATE UNIQUE INDEX idx_exp_ref ON expenditure_records(reference_id) WHERE reference_id IS NOT NULL');

    // Goals cache
    await db.execute('''
      CREATE TABLE goals (
        id INTEGER PRIMARY KEY,
        user_id INTEGER NOT NULL,
        name TEXT NOT NULL,
        icon TEXT NOT NULL DEFAULT 'flag',
        target_amount REAL NOT NULL,
        saved_amount REAL NOT NULL DEFAULT 0,
        deadline TEXT,
        is_complete INTEGER NOT NULL DEFAULT 0,
        created_at TEXT NOT NULL,
        json_data TEXT
      )
    ''');

    // Budget periods cache
    await db.execute('''
      CREATE TABLE periods (
        id INTEGER PRIMARY KEY AUTOINCREMENT,
        year INTEGER NOT NULL,
        month INTEGER NOT NULL,
        total_income REAL NOT NULL DEFAULT 0,
        total_allocated REAL NOT NULL DEFAULT 0,
        total_spent REAL NOT NULL DEFAULT 0,
        json_data TEXT,
        UNIQUE(year, month)
      )
    ''');

    // Sync state — tracks last sync per entity type
    await db.execute('''
      CREATE TABLE sync_state (
        entity_type TEXT PRIMARY KEY,
        last_synced_id INTEGER DEFAULT 0,
        last_sync_timestamp TEXT,
        full_sync_complete INTEGER DEFAULT 0
      )
    ''');

    // Pending queue — offline mutations to push when online
    await db.execute('''
      CREATE TABLE pending_queue (
        local_id TEXT PRIMARY KEY,
        entity_type TEXT NOT NULL,
        action TEXT NOT NULL,
        payload TEXT NOT NULL,
        created_at TEXT NOT NULL,
        retry_count INTEGER DEFAULT 0,
        last_retry_at TEXT
      )
    ''');

    debugPrint('[BudgetDB] All tables created');
  }

  // ── Envelope Defaults Cache ────────────────────────────────────────

  Future<void> cacheEnvelopeDefaults(List<EnvelopeDefault> defaults) async {
    final db = await database;
    final batch = db.batch();
    batch.delete('envelope_defaults');
    for (final d in defaults) {
      batch.insert('envelope_defaults', {
        'id': d.id,
        'name_en': d.nameEn,
        'name_sw': d.nameSw,
        'icon': d.icon,
        'color': d.color,
        'sort_order': d.sortOrder,
        'group_name': d.groupName,
        'module_tag': d.moduleTag,
        'is_active': d.isActive ? 1 : 0,
      });
    }
    await batch.commit(noResult: true);
    await _updateSyncState('envelope_defaults');
  }

  Future<List<EnvelopeDefault>> getCachedEnvelopeDefaults() async {
    final db = await database;
    final rows = await db.query('envelope_defaults', orderBy: 'sort_order ASC');
    return rows.map((r) => EnvelopeDefault.fromJson(r)).toList();
  }

  // ── Envelopes Cache ────────────────────────────────────────────────

  Future<void> cacheEnvelopes(List<BudgetEnvelope> envelopes, int year, int month) async {
    final db = await database;
    final batch = db.batch();
    // Delete old cache for this month
    batch.delete('envelopes',
        where: 'budget_year = ? AND budget_month = ?', whereArgs: [year, month]);
    for (final e in envelopes) {
      batch.insert('envelopes', {
        'id': e.id,
        'default_envelope_id': e.defaultEnvelopeId,
        'name': e.name,
        'icon': e.icon,
        'color': e.color,
        'allocated_amount': e.allocatedAmount,
        'spent_amount': e.spentAmount,
        'sort_order': e.order,
        'module_tag': e.moduleTag,
        'is_hidden': e.isHidden ? 1 : 0,
        'rollover': e.rollover ? 1 : 0,
        'rolled_over_amount': e.rolledOverAmount,
        'budget_year': e.budgetYear,
        'budget_month': e.budgetMonth,
        'created_at': e.createdAt.toIso8601String(),
        'json_data': jsonEncode(e.toJson()),
      });
    }
    await batch.commit(noResult: true);
    await _updateSyncState('envelopes');
  }

  Future<List<BudgetEnvelope>> getCachedEnvelopes(int year, int month) async {
    final db = await database;
    final rows = await db.query(
      'envelopes',
      where: 'budget_year = ? AND budget_month = ?',
      whereArgs: [year, month],
      orderBy: 'sort_order ASC',
    );
    return rows.map((r) => BudgetEnvelope.fromJson(r)).toList();
  }

  // ── Goals Cache ────────────────────────────────────────────────────

  Future<void> cacheGoals(List<BudgetGoal> goals) async {
    final db = await database;
    final batch = db.batch();
    batch.delete('goals');
    for (final g in goals) {
      batch.insert('goals', {
        'id': g.id,
        'user_id': g.userId,
        'name': g.name,
        'icon': g.icon,
        'target_amount': g.targetAmount,
        'saved_amount': g.savedAmount,
        'deadline': g.deadline?.toIso8601String(),
        'is_complete': g.isComplete ? 1 : 0,
        'created_at': g.createdAt.toIso8601String(),
        'json_data': jsonEncode(g.toJson()),
      });
    }
    await batch.commit(noResult: true);
    await _updateSyncState('goals');
  }

  Future<List<BudgetGoal>> getCachedGoals() async {
    final db = await database;
    final rows = await db.query('goals', orderBy: 'created_at DESC');
    return rows.map((r) => BudgetGoal.fromJson(r)).toList();
  }

  // ── Period Cache ───────────────────────────────────────────────────

  Future<void> cachePeriod(BudgetPeriod period) async {
    final db = await database;
    await db.insert(
      'periods',
      {
        'year': period.year,
        'month': period.month,
        'total_income': period.totalIncome,
        'total_allocated': period.totalAllocated,
        'total_spent': period.totalSpent,
      },
      conflictAlgorithm: ConflictAlgorithm.replace,
    );
  }

  Future<BudgetPeriod?> getCachedPeriod(int year, int month) async {
    final db = await database;
    final rows = await db.query(
      'periods',
      where: 'year = ? AND month = ?',
      whereArgs: [year, month],
      limit: 1,
    );
    if (rows.isEmpty) return null;
    return BudgetPeriod.fromJson(rows.first);
  }

  // ── Income Records Cache ───────────────────────────────────────────

  Future<void> cacheIncomeRecords(List<IncomeRecord> records) async {
    final db = await database;
    final batch = db.batch();
    for (final r in records) {
      batch.insert('income_records', {
        'id': r.id,
        'user_id': r.userId,
        'amount': r.amount,
        'source': r.source,
        'source_module': r.sourceModule,
        'description': r.description,
        'reference_id': r.referenceId,
        'date': r.date.toIso8601String(),
        'is_recurring': r.isRecurring ? 1 : 0,
        'created_at': r.createdAt.toIso8601String(),
        'json_data': jsonEncode(r.toJson()),
      }, conflictAlgorithm: ConflictAlgorithm.replace);
    }
    await batch.commit(noResult: true);
  }

  Future<List<IncomeRecord>> getCachedIncome({
    String? source,
    DateTime? from,
    DateTime? to,
    int limit = 50,
  }) async {
    final db = await database;
    final where = <String>[];
    final args = <dynamic>[];

    if (source != null) {
      where.add('source = ?');
      args.add(source);
    }
    if (from != null) {
      where.add('date >= ?');
      args.add(from.toIso8601String());
    }
    if (to != null) {
      where.add('date <= ?');
      args.add(to.toIso8601String());
    }

    final rows = await db.query(
      'income_records',
      where: where.isNotEmpty ? where.join(' AND ') : null,
      whereArgs: args.isNotEmpty ? args : null,
      orderBy: 'date DESC',
      limit: limit,
    );
    return rows.map((r) => IncomeRecord.fromJson(r)).toList();
  }

  // ── Expenditure Records Cache ──────────────────────────────────────

  Future<void> cacheExpenditureRecords(List<ExpenditureRecord> records) async {
    final db = await database;
    final batch = db.batch();
    for (final r in records) {
      batch.insert('expenditure_records', {
        'id': r.id,
        'user_id': r.userId,
        'amount': r.amount,
        'category': r.category,
        'source_module': r.sourceModule,
        'description': r.description,
        'reference_id': r.referenceId,
        'envelope_tag': r.envelopeTag,
        'date': r.date.toIso8601String(),
        'is_recurring': r.isRecurring ? 1 : 0,
        'created_at': r.createdAt.toIso8601String(),
        'json_data': jsonEncode(r.toJson()),
      }, conflictAlgorithm: ConflictAlgorithm.replace);
    }
    await batch.commit(noResult: true);
  }

  Future<List<ExpenditureRecord>> getCachedExpenditures({
    String? category,
    DateTime? from,
    DateTime? to,
    int limit = 50,
  }) async {
    final db = await database;
    final where = <String>[];
    final args = <dynamic>[];

    if (category != null) {
      where.add('category = ?');
      args.add(category);
    }
    if (from != null) {
      where.add('date >= ?');
      args.add(from.toIso8601String());
    }
    if (to != null) {
      where.add('date <= ?');
      args.add(to.toIso8601String());
    }

    final rows = await db.query(
      'expenditure_records',
      where: where.isNotEmpty ? where.join(' AND ') : null,
      whereArgs: args.isNotEmpty ? args : null,
      orderBy: 'date DESC',
      limit: limit,
    );
    return rows.map((r) => ExpenditureRecord.fromJson(r)).toList();
  }

  // ── Pending Queue (offline mutations) ──────────────────────────────

  Future<void> addToPendingQueue({
    required String localId,
    required String entityType,
    required String action,
    required Map<String, dynamic> payload,
  }) async {
    final db = await database;
    await db.insert('pending_queue', {
      'local_id': localId,
      'entity_type': entityType,
      'action': action,
      'payload': jsonEncode(payload),
      'created_at': DateTime.now().toIso8601String(),
      'retry_count': 0,
    }, conflictAlgorithm: ConflictAlgorithm.replace);
  }

  Future<List<Map<String, dynamic>>> getPendingQueue() async {
    final db = await database;
    return db.query('pending_queue', orderBy: 'created_at ASC');
  }

  Future<void> removePendingItem(String localId) async {
    final db = await database;
    await db.delete('pending_queue', where: 'local_id = ?', whereArgs: [localId]);
  }

  Future<void> incrementRetryCount(String localId) async {
    final db = await database;
    await db.rawUpdate('''
      UPDATE pending_queue
      SET retry_count = retry_count + 1, last_retry_at = ?
      WHERE local_id = ?
    ''', [DateTime.now().toIso8601String(), localId]);
  }

  // ── Sync State ─────────────────────────────────────────────────────

  Future<void> _updateSyncState(String entityType) async {
    final db = await database;
    await db.insert('sync_state', {
      'entity_type': entityType,
      'last_sync_timestamp': DateTime.now().toIso8601String(),
      'full_sync_complete': 1,
    }, conflictAlgorithm: ConflictAlgorithm.replace);
  }

  Future<DateTime?> getLastSyncTime(String entityType) async {
    final db = await database;
    final rows = await db.query(
      'sync_state',
      where: 'entity_type = ?',
      whereArgs: [entityType],
      limit: 1,
    );
    if (rows.isEmpty || rows.first['last_sync_timestamp'] == null) return null;
    return DateTime.tryParse(rows.first['last_sync_timestamp'] as String);
  }

  // ── Cleanup ────────────────────────────────────────────────────────

  /// Clear all budget data (called on logout).
  Future<void> clearAll() async {
    final db = await database;
    final batch = db.batch();
    batch.delete('envelope_defaults');
    batch.delete('envelopes');
    batch.delete('income_records');
    batch.delete('expenditure_records');
    batch.delete('goals');
    batch.delete('periods');
    batch.delete('sync_state');
    batch.delete('pending_queue');
    await batch.commit(noResult: true);
    debugPrint('[BudgetDB] All data cleared');
  }
}
```

- [ ] **Step 2: Verify with flutter analyze**

```bash
cd /Volumes/DATA/PROJECTS/TAJIRI/TAJIRI-FRONTEND && flutter analyze lib/services/budget_database.dart
```

---

## Task 11: Frontend — Verify Everything Compiles

- [ ] **Step 1: Check for import issues in files that reference old budget_models.dart types**

The old `BudgetDefaults` class and `BudgetTransaction`, `BudgetTransactionType`, `BudgetSource` types have been removed. Search for imports/references:

```bash
cd /Volumes/DATA/PROJECTS/TAJIRI/TAJIRI-FRONTEND && grep -r "BudgetDefaults\|BudgetTransactionType\|BudgetSource\|BudgetTransaction" lib/ --include="*.dart" -l
```

Update any files that reference the removed types. The key changes:
- `BudgetDefaults.defaultEnvelopes` no longer exists (envelope defaults come from API)
- `BudgetTransactionType` and `BudgetSource` enums are removed (replaced by String-based source/category from API)
- `BudgetTransaction` is replaced by `IncomeRecord` and `ExpenditureRecord`

- [ ] **Step 2: Check the budget home screen for broken references**

```bash
cd /Volumes/DATA/PROJECTS/TAJIRI/TAJIRI-FRONTEND && flutter analyze lib/screens/budget/
```

The budget home screen (`lib/screens/budget/budget_home_screen.dart`) will need updates to use the new BudgetService static methods instead of the old instance methods. This is a UI task for Plan B, but at minimum ensure it doesn't prevent compilation.

- [ ] **Step 3: Run full flutter analyze**

```bash
cd /Volumes/DATA/PROJECTS/TAJIRI/TAJIRI-FRONTEND && flutter analyze lib/models/budget_models.dart lib/services/income_service.dart lib/services/expenditure_service.dart lib/services/budget_service.dart lib/services/budget_database.dart
```

Fix any issues until all 5 files pass analysis with no errors.

- [ ] **Step 4: Run flutter analyze on the whole project to check for regressions**

```bash
cd /Volumes/DATA/PROJECTS/TAJIRI/TAJIRI-FRONTEND && flutter analyze
```

Note: the project may have pre-existing analysis issues. Only fix issues introduced by the budget changes (references to removed types, broken imports, etc.).

---

## Summary: What Each Component Does

| Component | Role | Consumed By |
|---|---|---|
| **Backend: income_records table** | Stores all income events | IncomeController |
| **Backend: expenditure_records table** | Stores all expenditure events | ExpenditureController |
| **Backend: budget_envelope_defaults** | 19 default envelope templates | BudgetController |
| **Backend: budget_user_envelopes** | Per-user, per-month envelope allocations | BudgetController |
| **Backend: budget_goals** | Savings goals | BudgetController |
| **Backend: budget_periods** | Monthly summary snapshots | BudgetController |
| **Backend: IncomeController** | CRUD + summary + recurring detection for income | Flutter IncomeService |
| **Backend: ExpenditureController** | CRUD + summary + recurring + pace for spending | Flutter ExpenditureService |
| **Backend: BudgetController** | Envelopes, goals, periods | Flutter BudgetService |
| **Flutter: IncomeService** | API client for income | BudgetService, BudgetHomeScreen, MonthlyReportScreen, TeaService |
| **Flutter: ExpenditureService** | API client for expenditures | BudgetService, BudgetHomeScreen, EnvelopeDetailScreen, other modules for budget context |
| **Flutter: BudgetService** | Orchestrator for envelopes, goals, periods | All budget UI screens |
| **Flutter: BudgetDatabase** | SQLite offline cache | BudgetService (cache fallback), offline-first UI |
| **Flutter: budget_models.dart** | All data models | Every budget file |

## What Comes Next (Plan B)

Plan B will cover:
- UI screens (BudgetHomeScreen rewrite, EnvelopeDetailScreen, AddTransactionScreen, AllocateFundsScreen, SavingsGoalsScreen, MonthlyReportScreen, IncomeBreakdownScreen, CashFlowForecastScreen, RecurringExpensesScreen)
- Wiring budget tab in ProfileScreen
- Cross-module budget context integration (showing budget info in Food, Transport, Shop, etc.)
- Routing in main.dart
- Event tracking
