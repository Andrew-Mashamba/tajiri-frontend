# Flywheel Backend Phase 4: Sponsored Posts, Battles, Collaboration & Analytics

> **For agentic workers:** REQUIRED SUB-SKILL: Use superpowers:subagent-driven-development (recommended) or superpowers:executing-plans to implement this plan task-by-task. Steps use checkbox (`- [ ]`) syntax for tracking.

**Goal:** Implement the Laravel backend for Phase 4 of the Flywheel Growth Engine — sponsored posts marketplace, creator battles, collaboration suggestions, engagement levels, and analytics dashboard endpoints.

**Architecture:** All implementation follows existing Laravel patterns: Eloquent models with `$fillable`/`$casts`, controllers returning `response()->json(["data" => ...])`, anonymous-class migrations with Blueprint, and Artisan commands with `$signature`/`handle(): int`. Routes registered in `routes/api.php` under existing middleware groups.

**Tech Stack:** Laravel 12, PHP 8.2+, PostgreSQL, Eloquent ORM, Artisan Commands, Laravel Scheduler

**Server Access:** SSH as root to `zima-uat.site`, backend at `/var/www/html/tajiri/`

**Execution:** All tasks executed via SSH: `sshpass -p 'ZimaBlueApps' ssh root@zima-uat.site "cd /var/www/html/tajiri && ..."`

---

## File Structure

### New Files to Create

| File | Responsibility |
|------|---------------|
| `database/migrations/2026_03_26_300000_create_phase4_flywheel_tables.php` | 5 tables: sponsored_posts, collaboration_suggestions, creator_battles, creator_battle_votes, user_engagement_levels |
| `app/Models/SponsoredPost.php` | Eloquent model for sponsored posts |
| `app/Models/CollaborationSuggestion.php` | Eloquent model for collaboration suggestions |
| `app/Models/CreatorBattle.php` | Eloquent model for creator battles |
| `app/Models/CreatorBattleVote.php` | Eloquent model for battle votes |
| `app/Models/UserEngagementLevel.php` | Eloquent model for engagement levels |
| `app/Http/Controllers/Api/SponsoredPostController.php` | CRUD + browse for sponsored posts |
| `app/Http/Controllers/Api/CollaborationController.php` | Suggestions + respond |
| `app/Http/Controllers/Api/CreatorBattleController.php` | Battles + voting |
| `app/Http/Controllers/Api/AnalyticsController.php` | Dashboard + post performance + audience |
| `app/Console/Commands/UpdateEngagementLevels.php` | Daily command to recalculate engagement tiers |
| `app/Console/Commands/DetectCollaborations.php` | Daily command to generate collaboration suggestions |

### Files to Modify

| File | Change |
|------|--------|
| `routes/api.php` | Add Phase 4 route group (~25 lines) |
| `app/Console/Kernel.php` | Register 2 new scheduled commands |

---

### Task 1: Migration — Create Phase 4 Tables

**Files:**
- Create: `database/migrations/2026_03_26_300000_create_phase4_flywheel_tables.php`

- [ ] **Step 1: Create the migration file**

```php
<?php

use Illuminate\Database\Migrations\Migration;
use Illuminate\Database\Schema\Blueprint;
use Illuminate\Support\Facades\Schema;

return new class extends Migration
{
    public function up(): void
    {
        Schema::create('sponsored_posts', function (Blueprint $table) {
            $table->id();
            $table->foreignId('post_id')->constrained('posts')->cascadeOnDelete();
            $table->foreignId('sponsor_user_id')->constrained('users')->cascadeOnDelete();
            $table->foreignId('creator_user_id')->constrained('users')->cascadeOnDelete();
            $table->decimal('budget', 12, 2)->default(0);
            $table->string('currency', 10)->default('TSh');
            $table->string('status', 20)->default('draft'); // draft, pending, active, completed, cancelled
            $table->string('tier_required', 20)->default('star');
            $table->integer('impressions_target')->default(0);
            $table->integer('impressions_delivered')->default(0);
            $table->timestamps();

            $table->index('sponsor_user_id');
            $table->index('creator_user_id');
            $table->index('status');
        });

        Schema::create('collaboration_suggestions', function (Blueprint $table) {
            $table->id();
            $table->foreignId('user_id')->constrained('users')->cascadeOnDelete();
            $table->foreignId('suggested_user_id')->constrained('users')->cascadeOnDelete();
            $table->string('reason')->default('');
            $table->decimal('compatibility_score', 5, 2)->default(0);
            $table->string('status', 20)->default('pending'); // pending, accepted, dismissed
            $table->timestamps();

            $table->index('user_id');
            $table->index(['user_id', 'status']);
            $table->unique(['user_id', 'suggested_user_id']);
        });

        Schema::create('creator_battles', function (Blueprint $table) {
            $table->id();
            $table->foreignId('creator_a_id')->constrained('users')->cascadeOnDelete();
            $table->foreignId('creator_b_id')->constrained('users')->cascadeOnDelete();
            $table->foreignId('post_a_id')->nullable()->constrained('posts')->nullOnDelete();
            $table->foreignId('post_b_id')->nullable()->constrained('posts')->nullOnDelete();
            $table->string('topic')->default('');
            $table->string('status', 20)->default('active'); // active, completed
            $table->integer('votes_a')->default(0);
            $table->integer('votes_b')->default(0);
            $table->timestamp('ends_at')->nullable();
            $table->timestamps();

            $table->index('status');
        });

        Schema::create('creator_battle_votes', function (Blueprint $table) {
            $table->id();
            $table->foreignId('battle_id')->constrained('creator_battles')->cascadeOnDelete();
            $table->foreignId('user_id')->constrained('users')->cascadeOnDelete();
            $table->string('side', 1); // 'a' or 'b'
            $table->timestamps();

            $table->unique(['battle_id', 'user_id']);
        });

        Schema::create('user_engagement_levels', function (Blueprint $table) {
            $table->id();
            $table->foreignId('user_id')->constrained('users')->cascadeOnDelete();
            $table->string('level', 20)->default('casual'); // casual, regular, engaged, super_fan
            $table->integer('weekly_actions')->default(0);
            $table->integer('streak_days')->default(0);
            $table->timestamps();

            $table->unique('user_id');
            $table->index('level');
        });
    }

    public function down(): void
    {
        Schema::dropIfExists('creator_battle_votes');
        Schema::dropIfExists('creator_battles');
        Schema::dropIfExists('collaboration_suggestions');
        Schema::dropIfExists('sponsored_posts');
        Schema::dropIfExists('user_engagement_levels');
    }
};
```

- [ ] **Step 2: Upload and run the migration**

```bash
# Upload file via SSH heredoc, then run migrate
sshpass -p 'ZimaBlueApps' ssh root@zima-uat.site "cd /var/www/html/tajiri && php artisan migrate"
```

Expected: 5 tables created successfully.

- [ ] **Step 3: Verify tables exist**

```bash
sshpass -p 'ZimaBlueApps' ssh root@zima-uat.site "cd /var/www/html/tajiri && php artisan tinker --execute=\"echo implode(', ', array_filter(Schema::getTableListing(), fn(\$t) => str_contains(\$t, 'sponsored') || str_contains(\$t, 'collaboration') || str_contains(\$t, 'battle') || str_contains(\$t, 'engagement')));\""
```

Expected: `sponsored_posts, collaboration_suggestions, creator_battles, creator_battle_votes, user_engagement_levels`

- [ ] **Step 4: Commit**

```bash
git add database/migrations/2026_03_26_300000_create_phase4_flywheel_tables.php
git commit -m "feat: add Phase 4 flywheel tables migration"
```

---

### Task 2: Models — SponsoredPost & CollaborationSuggestion

**Files:**
- Create: `app/Models/SponsoredPost.php`
- Create: `app/Models/CollaborationSuggestion.php`

- [ ] **Step 1: Create SponsoredPost model**

```php
<?php

namespace App\Models;

use Illuminate\Database\Eloquent\Model;

class SponsoredPost extends Model
{
    protected $fillable = [
        'post_id', 'sponsor_user_id', 'creator_user_id',
        'budget', 'currency', 'status', 'tier_required',
        'impressions_target', 'impressions_delivered',
    ];

    protected $casts = [
        'budget' => 'decimal:2',
        'impressions_target' => 'integer',
        'impressions_delivered' => 'integer',
    ];

    public function post()
    {
        return $this->belongsTo(Post::class);
    }

    public function sponsor()
    {
        return $this->belongsTo(User::class, 'sponsor_user_id');
    }

    public function creator()
    {
        return $this->belongsTo(User::class, 'creator_user_id');
    }
}
```

- [ ] **Step 2: Create CollaborationSuggestion model**

```php
<?php

namespace App\Models;

use Illuminate\Database\Eloquent\Model;

class CollaborationSuggestion extends Model
{
    protected $fillable = [
        'user_id', 'suggested_user_id', 'reason',
        'compatibility_score', 'status',
    ];

    protected $casts = [
        'compatibility_score' => 'decimal:2',
    ];

    public function user()
    {
        return $this->belongsTo(User::class);
    }

    public function suggestedUser()
    {
        return $this->belongsTo(User::class, 'suggested_user_id');
    }
}
```

- [ ] **Step 3: Upload both files and verify**

```bash
php artisan tinker --execute="new \App\Models\SponsoredPost(); new \App\Models\CollaborationSuggestion(); echo 'OK';"
```

Expected: `OK`

- [ ] **Step 4: Commit**

```bash
git add app/Models/SponsoredPost.php app/Models/CollaborationSuggestion.php
git commit -m "feat: add SponsoredPost and CollaborationSuggestion models"
```

---

### Task 3: Models — CreatorBattle, CreatorBattleVote, UserEngagementLevel

**Files:**
- Create: `app/Models/CreatorBattle.php`
- Create: `app/Models/CreatorBattleVote.php`
- Create: `app/Models/UserEngagementLevel.php`

- [ ] **Step 1: Create CreatorBattle model**

```php
<?php

namespace App\Models;

use Illuminate\Database\Eloquent\Model;

class CreatorBattle extends Model
{
    protected $fillable = [
        'creator_a_id', 'creator_b_id',
        'post_a_id', 'post_b_id',
        'topic', 'status', 'votes_a', 'votes_b', 'ends_at',
    ];

    protected $casts = [
        'votes_a' => 'integer',
        'votes_b' => 'integer',
        'ends_at' => 'datetime',
    ];

    public function creatorA()
    {
        return $this->belongsTo(User::class, 'creator_a_id');
    }

    public function creatorB()
    {
        return $this->belongsTo(User::class, 'creator_b_id');
    }

    public function postA()
    {
        return $this->belongsTo(Post::class, 'post_a_id');
    }

    public function postB()
    {
        return $this->belongsTo(Post::class, 'post_b_id');
    }

    public function votes()
    {
        return $this->hasMany(CreatorBattleVote::class, 'battle_id');
    }
}
```

- [ ] **Step 2: Create CreatorBattleVote model**

```php
<?php

namespace App\Models;

use Illuminate\Database\Eloquent\Model;

class CreatorBattleVote extends Model
{
    protected $fillable = ['battle_id', 'user_id', 'side'];

    public function battle()
    {
        return $this->belongsTo(CreatorBattle::class, 'battle_id');
    }

    public function user()
    {
        return $this->belongsTo(User::class);
    }
}
```

- [ ] **Step 3: Create UserEngagementLevel model**

```php
<?php

namespace App\Models;

use Illuminate\Database\Eloquent\Model;

class UserEngagementLevel extends Model
{
    protected $fillable = ['user_id', 'level', 'weekly_actions', 'streak_days'];

    protected $casts = [
        'weekly_actions' => 'integer',
        'streak_days' => 'integer',
    ];

    public function user()
    {
        return $this->belongsTo(User::class);
    }
}
```

- [ ] **Step 4: Upload all three files and verify**

```bash
php artisan tinker --execute="new \App\Models\CreatorBattle(); new \App\Models\CreatorBattleVote(); new \App\Models\UserEngagementLevel(); echo 'OK';"
```

Expected: `OK`

- [ ] **Step 5: Commit**

```bash
git add app/Models/CreatorBattle.php app/Models/CreatorBattleVote.php app/Models/UserEngagementLevel.php
git commit -m "feat: add CreatorBattle, CreatorBattleVote, UserEngagementLevel models"
```

---

### Task 4: SponsoredPostController

**Files:**
- Create: `app/Http/Controllers/Api/SponsoredPostController.php`

- [ ] **Step 1: Create controller**

```php
<?php

namespace App\Http\Controllers\Api;

use App\Http\Controllers\Controller;
use App\Models\SponsoredPost;
use App\Models\CreatorScore;
use Illuminate\Http\Request;

class SponsoredPostController extends Controller
{
    /**
     * GET /api/sponsored-posts/active
     * Active sponsored posts (for feed injection).
     */
    public function active(Request $request)
    {
        $posts = SponsoredPost::where('status', 'active')
            ->with(['sponsor:id,name', 'creator:id,name', 'post'])
            ->orderByDesc('budget')
            ->limit(20)
            ->get()
            ->map(fn ($sp) => [
                'id' => $sp->id,
                'post_id' => $sp->post_id,
                'sponsor_user_id' => $sp->sponsor_user_id,
                'creator_user_id' => $sp->creator_user_id,
                'budget' => (float) $sp->budget,
                'currency' => $sp->currency,
                'status' => $sp->status,
                'tier_required' => $sp->tier_required,
                'impressions_target' => $sp->impressions_target,
                'impressions_delivered' => $sp->impressions_delivered,
                'sponsor_name' => $sp->sponsor->name ?? null,
                'creator_name' => $sp->creator->name ?? null,
                'created_at' => $sp->created_at?->toISOString(),
            ]);

        return response()->json(['data' => $posts]);
    }

    /**
     * GET /api/sponsored-posts/creators
     * Browse creators available for sponsorship.
     */
    public function creators(Request $request)
    {
        $tier = $request->query('tier', 'star');

        $creators = CreatorScore::where('tier', '>=', $tier)
            ->with('user:id,name')
            ->orderByDesc('total_score')
            ->limit(50)
            ->get()
            ->map(fn ($cs) => [
                'user_id' => $cs->user_id,
                'name' => $cs->user->name ?? '',
                'avatar_url' => null,
                'tier' => $cs->tier ?? 'star',
                'follower_count' => $cs->follower_count ?? 0,
                'avg_engagement_rate' => round(($cs->engagement_score ?? 0) / 100, 2),
                'top_category' => $cs->top_category ?? '',
            ]);

        return response()->json(['data' => $creators]);
    }

    /**
     * POST /api/sponsored-posts
     * Create a new sponsored post campaign.
     */
    public function store(Request $request)
    {
        $validated = $request->validate([
            'post_id' => 'required|integer|exists:posts,id',
            'creator_user_id' => 'required|integer|exists:users,id',
            'budget' => 'required|numeric|min:1000',
            'currency' => 'sometimes|string|max:10',
            'tier_required' => 'sometimes|string|in:star,legend',
            'impressions_target' => 'sometimes|integer|min:100',
        ]);

        $validated['sponsor_user_id'] = $request->user()->id;
        $validated['status'] = 'pending';

        $sp = SponsoredPost::create($validated);

        return response()->json(['data' => $sp], 201);
    }

    /**
     * GET /api/creators/{id}/sponsored
     * Sponsored posts for a specific creator.
     */
    public function creatorSponsored(int $id)
    {
        $posts = SponsoredPost::where('creator_user_id', $id)
            ->with(['sponsor:id,name'])
            ->orderByDesc('created_at')
            ->limit(20)
            ->get()
            ->map(fn ($sp) => [
                'id' => $sp->id,
                'post_id' => $sp->post_id,
                'sponsor_user_id' => $sp->sponsor_user_id,
                'creator_user_id' => $sp->creator_user_id,
                'budget' => (float) $sp->budget,
                'currency' => $sp->currency,
                'status' => $sp->status,
                'tier_required' => $sp->tier_required,
                'impressions_target' => $sp->impressions_target,
                'impressions_delivered' => $sp->impressions_delivered,
                'sponsor_name' => $sp->sponsor->name ?? null,
                'creator_name' => null,
                'created_at' => $sp->created_at?->toISOString(),
            ]);

        return response()->json(['data' => $posts]);
    }
}
```

- [ ] **Step 2: Upload and verify class loads**

```bash
php artisan tinker --execute="new \App\Http\Controllers\Api\SponsoredPostController(); echo 'OK';"
```

- [ ] **Step 3: Commit**

```bash
git add app/Http/Controllers/Api/SponsoredPostController.php
git commit -m "feat: add SponsoredPostController with active, creators, store, creatorSponsored"
```

---

### Task 5: CollaborationController

**Files:**
- Create: `app/Http/Controllers/Api/CollaborationController.php`

- [ ] **Step 1: Create controller**

```php
<?php

namespace App\Http\Controllers\Api;

use App\Http\Controllers\Controller;
use App\Models\CollaborationSuggestion;
use Illuminate\Http\Request;

class CollaborationController extends Controller
{
    /**
     * GET /api/creators/{id}/collaborations
     * Get pending collaboration suggestions for a creator.
     */
    public function suggestions(int $id)
    {
        $suggestions = CollaborationSuggestion::where('user_id', $id)
            ->where('status', 'pending')
            ->with('suggestedUser:id,name')
            ->orderByDesc('compatibility_score')
            ->limit(10)
            ->get()
            ->map(fn ($s) => [
                'id' => $s->id,
                'user_id' => $s->user_id,
                'suggested_user_id' => $s->suggested_user_id,
                'suggested_user_name' => $s->suggestedUser->name ?? '',
                'suggested_user_avatar_url' => null,
                'reason' => $s->reason,
                'compatibility_score' => (float) $s->compatibility_score,
                'status' => $s->status,
                'created_at' => $s->created_at?->toISOString(),
            ]);

        return response()->json(['data' => $suggestions]);
    }

    /**
     * POST /api/collaborations/{id}/respond
     * Accept or dismiss a collaboration suggestion.
     */
    public function respond(Request $request, int $id)
    {
        $validated = $request->validate([
            'action' => 'required|string|in:accept,dismiss',
        ]);

        $suggestion = CollaborationSuggestion::findOrFail($id);
        $suggestion->update([
            'status' => $validated['action'] === 'accept' ? 'accepted' : 'dismissed',
        ]);

        return response()->json(['data' => ['success' => true]]);
    }
}
```

- [ ] **Step 2: Upload and verify**

```bash
php artisan tinker --execute="new \App\Http\Controllers\Api\CollaborationController(); echo 'OK';"
```

- [ ] **Step 3: Commit**

```bash
git add app/Http/Controllers/Api/CollaborationController.php
git commit -m "feat: add CollaborationController with suggestions and respond"
```

---

### Task 6: CreatorBattleController

**Files:**
- Create: `app/Http/Controllers/Api/CreatorBattleController.php`

- [ ] **Step 1: Create controller**

```php
<?php

namespace App\Http\Controllers\Api;

use App\Http\Controllers\Controller;
use App\Models\CreatorBattle;
use App\Models\CreatorBattleVote;
use Illuminate\Http\Request;

class CreatorBattleController extends Controller
{
    /**
     * GET /api/creator-battles
     * List active battles.
     */
    public function index()
    {
        $battles = CreatorBattle::where('status', 'active')
            ->with(['creatorA:id,name', 'creatorB:id,name'])
            ->orderByDesc('created_at')
            ->limit(20)
            ->get()
            ->map(fn ($b) => $this->formatBattle($b));

        return response()->json(['data' => $battles]);
    }

    /**
     * GET /api/creator-battles/{id}
     * Get a single battle.
     */
    public function show(int $id)
    {
        $battle = CreatorBattle::with(['creatorA:id,name', 'creatorB:id,name'])->findOrFail($id);

        return response()->json(['data' => $this->formatBattle($battle)]);
    }

    /**
     * POST /api/creator-battles/{id}/vote
     * Vote on a battle.
     */
    public function vote(Request $request, int $id)
    {
        $validated = $request->validate([
            'side' => 'required|string|in:a,b',
        ]);

        $battle = CreatorBattle::findOrFail($id);

        if ($battle->status !== 'active') {
            return response()->json(['message' => 'Battle is not active'], 422);
        }

        $userId = $request->user()->id;

        // Upsert vote (one vote per user per battle)
        $existing = CreatorBattleVote::where('battle_id', $id)->where('user_id', $userId)->first();

        if ($existing) {
            $oldSide = $existing->side;
            $existing->update(['side' => $validated['side']]);

            // Adjust counts
            if ($oldSide !== $validated['side']) {
                $battle->decrement('votes_' . $oldSide);
                $battle->increment('votes_' . $validated['side']);
            }
        } else {
            CreatorBattleVote::create([
                'battle_id' => $id,
                'user_id' => $userId,
                'side' => $validated['side'],
            ]);
            $battle->increment('votes_' . $validated['side']);
        }

        $battle->refresh();

        return response()->json(['data' => $this->formatBattle($battle)]);
    }

    private function formatBattle(CreatorBattle $b): array
    {
        return [
            'id' => $b->id,
            'creator_a_id' => $b->creator_a_id,
            'creator_b_id' => $b->creator_b_id,
            'creator_a_name' => $b->creatorA->name ?? '',
            'creator_b_name' => $b->creatorB->name ?? '',
            'post_a_id' => $b->post_a_id,
            'post_b_id' => $b->post_b_id,
            'topic' => $b->topic,
            'status' => $b->status,
            'votes_a' => $b->votes_a,
            'votes_b' => $b->votes_b,
            'ends_at' => $b->ends_at?->toISOString(),
            'created_at' => $b->created_at?->toISOString(),
        ];
    }
}
```

- [ ] **Step 2: Upload and verify**

```bash
php artisan tinker --execute="new \App\Http\Controllers\Api\CreatorBattleController(); echo 'OK';"
```

- [ ] **Step 3: Commit**

```bash
git add app/Http/Controllers/Api/CreatorBattleController.php
git commit -m "feat: add CreatorBattleController with index, show, vote"
```

---

### Task 7: AnalyticsController

**Files:**
- Create: `app/Http/Controllers/Api/AnalyticsController.php`

- [ ] **Step 1: Create controller**

```php
<?php

namespace App\Http\Controllers\Api;

use App\Http\Controllers\Controller;
use App\Models\CreatorScore;
use App\Models\Post;
use App\Models\UserEngagementLevel;
use App\Models\UserFollow;
use Illuminate\Http\Request;
use Illuminate\Support\Facades\DB;
use Carbon\Carbon;

class AnalyticsController extends Controller
{
    /**
     * GET /api/creators/{id}/analytics/dashboard
     * Main analytics dashboard data.
     */
    public function dashboard(int $id)
    {
        $score = CreatorScore::where('user_id', $id)->first();
        $engagementLevel = UserEngagementLevel::where('user_id', $id)->first();

        // Daily metrics for last 7 days
        $dailyMetrics = DB::table('post_views')
            ->select(
                DB::raw("DATE(created_at) as date"),
                DB::raw("COUNT(*) as views"),
                DB::raw("0 as likes"),
                DB::raw("0 as shares"),
                DB::raw("0 as comments")
            )
            ->where('post_id', 'in', function ($query) use ($id) {
                $query->select('id')->from('posts')->where('user_id', $id);
            })
            ->where('created_at', '>=', Carbon::now()->subDays(7))
            ->groupBy(DB::raw("DATE(created_at)"))
            ->orderBy('date')
            ->get()
            ->map(fn ($row) => [
                'date' => $row->date,
                'views' => (int) $row->views,
                'likes' => (int) $row->likes,
                'shares' => (int) $row->shares,
                'comments' => (int) $row->comments,
            ]);

        $totalFollowers = DB::table('user_follows')->where('followed_id', $id)->count();
        $totalPosts = Post::where('user_id', $id)->count();
        $totalViews = DB::table('post_views')
            ->whereIn('post_id', Post::where('user_id', $id)->pluck('id'))
            ->count();

        return response()->json(['data' => [
            'total_followers' => $totalFollowers,
            'total_posts' => $totalPosts,
            'total_views' => $totalViews,
            'total_earnings' => (float) ($score->total_earnings ?? 0),
            'engagement_rate' => round(($score->engagement_score ?? 0) / 100, 2),
            'engagement_level' => $engagementLevel->level ?? 'casual',
            'tier' => $score->tier ?? 'star',
            'daily_metrics' => $dailyMetrics,
        ]]);
    }

    /**
     * GET /api/creators/{id}/analytics/posts
     * Top-performing posts.
     */
    public function postPerformance(int $id)
    {
        $posts = Post::where('user_id', $id)
            ->orderByDesc('likes_count')
            ->limit(20)
            ->get()
            ->map(fn ($p) => [
                'post_id' => $p->id,
                'content' => mb_substr($p->content ?? '', 0, 100),
                'views' => $p->views_count ?? 0,
                'likes' => $p->likes_count ?? 0,
                'comments' => $p->comments_count ?? 0,
                'shares' => $p->shares_count ?? 0,
                'engagement_rate' => ($p->views_count ?? 0) > 0
                    ? round((($p->likes_count ?? 0) + ($p->comments_count ?? 0)) / ($p->views_count ?? 1) * 100, 2)
                    : 0,
                'created_at' => $p->created_at?->toISOString(),
            ]);

        return response()->json(['data' => $posts]);
    }

    /**
     * GET /api/creators/{id}/analytics/audience
     * Audience demographic insights.
     */
    public function audienceInsights(int $id)
    {
        // Aggregate follower regions/age from user_profiles
        $followers = DB::table('user_follows')
            ->join('user_profiles', 'user_follows.follower_id', '=', 'user_profiles.user_id')
            ->where('user_follows.followed_id', $id)
            ->select('user_profiles.region', 'user_profiles.gender')
            ->get();

        $regionCounts = $followers->groupBy('region')->map->count()->sortDesc()->take(5);
        $genderCounts = $followers->groupBy('gender')->map->count();

        $insights = [
            [
                'category' => 'top_regions',
                'label' => 'Top Regions',
                'value' => $regionCounts->keys()->first() ?? 'Unknown',
                'percentage' => $followers->count() > 0
                    ? round($regionCounts->first() / $followers->count() * 100, 1)
                    : 0,
            ],
        ];

        foreach ($genderCounts as $gender => $count) {
            $insights[] = [
                'category' => 'gender',
                'label' => ucfirst($gender ?? 'unknown'),
                'value' => (string) $count,
                'percentage' => $followers->count() > 0
                    ? round($count / $followers->count() * 100, 1)
                    : 0,
            ];
        }

        return response()->json(['data' => $insights]);
    }

    /**
     * GET /api/users/{id}/engagement-level
     * Get user's engagement level.
     */
    public function engagementLevel(int $id)
    {
        $level = UserEngagementLevel::where('user_id', $id)->first();

        return response()->json(['data' => [
            'level' => $level->level ?? 'casual',
            'weekly_actions' => $level->weekly_actions ?? 0,
            'streak_days' => $level->streak_days ?? 0,
        ]]);
    }
}
```

- [ ] **Step 2: Upload and verify**

```bash
php artisan tinker --execute="new \App\Http\Controllers\Api\AnalyticsController(); echo 'OK';"
```

- [ ] **Step 3: Commit**

```bash
git add app/Http/Controllers/Api/AnalyticsController.php
git commit -m "feat: add AnalyticsController with dashboard, posts, audience, engagementLevel"
```

---

### Task 8: UpdateEngagementLevels Command

**Files:**
- Create: `app/Console/Commands/UpdateEngagementLevels.php`

- [ ] **Step 1: Create command**

```php
<?php

namespace App\Console\Commands;

use App\Models\UserEngagementLevel;
use Illuminate\Console\Command;
use Illuminate\Support\Facades\DB;
use Carbon\Carbon;

class UpdateEngagementLevels extends Command
{
    protected $signature = 'flywheel:update-engagement-levels';
    protected $description = 'Recalculate user engagement levels based on weekly activity';

    public function handle(): int
    {
        $since = Carbon::now()->subDays(7);

        // Count actions per user in last 7 days
        $actions = DB::table('user_events')
            ->select('user_id', DB::raw('COUNT(*) as action_count'))
            ->where('created_at', '>=', $since)
            ->groupBy('user_id')
            ->get();

        $updated = 0;

        foreach ($actions as $row) {
            $level = match (true) {
                $row->action_count >= 50 => 'super_fan',
                $row->action_count >= 20 => 'engaged',
                $row->action_count >= 7 => 'regular',
                default => 'casual',
            };

            UserEngagementLevel::updateOrCreate(
                ['user_id' => $row->user_id],
                [
                    'level' => $level,
                    'weekly_actions' => $row->action_count,
                ]
            );
            $updated++;
        }

        $this->info("Updated engagement levels for {$updated} users.");
        return self::SUCCESS;
    }
}
```

- [ ] **Step 2: Upload and test**

```bash
php artisan flywheel:update-engagement-levels
```

Expected: `Updated engagement levels for N users.`

- [ ] **Step 3: Commit**

```bash
git add app/Console/Commands/UpdateEngagementLevels.php
git commit -m "feat: add UpdateEngagementLevels artisan command"
```

---

### Task 9: DetectCollaborations Command

**Files:**
- Create: `app/Console/Commands/DetectCollaborations.php`

- [ ] **Step 1: Create command**

```php
<?php

namespace App\Console\Commands;

use App\Models\CollaborationSuggestion;
use App\Models\CreatorScore;
use Illuminate\Console\Command;
use Illuminate\Support\Facades\DB;

class DetectCollaborations extends Command
{
    protected $signature = 'flywheel:detect-collaborations';
    protected $description = 'Generate collaboration suggestions between creators with complementary audiences';

    public function handle(): int
    {
        // Get active creators (score > 0)
        $creators = CreatorScore::where('total_score', '>', 0)
            ->orderByDesc('total_score')
            ->limit(100)
            ->get();

        $created = 0;

        foreach ($creators as $i => $a) {
            foreach ($creators as $j => $b) {
                if ($i >= $j) continue; // Avoid duplicates and self-match

                // Simple compatibility: different top categories = complementary
                if ($a->top_category !== $b->top_category && $a->top_category && $b->top_category) {
                    $score = min(100, ($a->total_score + $b->total_score) / 2);

                    // Skip if suggestion already exists
                    $exists = CollaborationSuggestion::where('user_id', $a->user_id)
                        ->where('suggested_user_id', $b->user_id)
                        ->exists();

                    if (!$exists) {
                        CollaborationSuggestion::create([
                            'user_id' => $a->user_id,
                            'suggested_user_id' => $b->user_id,
                            'reason' => "Complementary audiences: {$a->top_category} + {$b->top_category}",
                            'compatibility_score' => $score,
                            'status' => 'pending',
                        ]);

                        // Create reverse suggestion too
                        CollaborationSuggestion::firstOrCreate(
                            ['user_id' => $b->user_id, 'suggested_user_id' => $a->user_id],
                            [
                                'reason' => "Complementary audiences: {$b->top_category} + {$a->top_category}",
                                'compatibility_score' => $score,
                                'status' => 'pending',
                            ]
                        );

                        $created += 2;
                    }
                }
            }
        }

        $this->info("Created {$created} collaboration suggestions.");
        return self::SUCCESS;
    }
}
```

- [ ] **Step 2: Upload and test**

```bash
php artisan flywheel:detect-collaborations
```

Expected: `Created N collaboration suggestions.`

- [ ] **Step 3: Commit**

```bash
git add app/Console/Commands/DetectCollaborations.php
git commit -m "feat: add DetectCollaborations artisan command"
```

---

### Task 10: Register Routes in api.php

**Files:**
- Modify: `routes/api.php` (append Phase 4 routes)

- [ ] **Step 1: Add Phase 4 routes**

Append to the end of `routes/api.php`:

```php
// ── Phase 4: Flywheel — Sponsored Posts, Battles, Collaboration, Analytics ──

use App\Http\Controllers\Api\SponsoredPostController;
use App\Http\Controllers\Api\CollaborationController;
use App\Http\Controllers\Api\CreatorBattleController;
use App\Http\Controllers\Api\AnalyticsController;

Route::prefix('sponsored-posts')->group(function () {
    Route::get('/active', [SponsoredPostController::class, 'active']);
    Route::get('/creators', [SponsoredPostController::class, 'creators']);
    Route::post('/', [SponsoredPostController::class, 'store'])->middleware('auth:sanctum');
});

Route::get('creators/{id}/sponsored', [SponsoredPostController::class, 'creatorSponsored']);

Route::get('creators/{id}/collaborations', [CollaborationController::class, 'suggestions']);
Route::post('collaborations/{id}/respond', [CollaborationController::class, 'respond'])->middleware('auth:sanctum');

Route::prefix('creator-battles')->group(function () {
    Route::get('/', [CreatorBattleController::class, 'index']);
    Route::get('/{id}', [CreatorBattleController::class, 'show']);
    Route::post('/{id}/vote', [CreatorBattleController::class, 'vote'])->middleware('auth:sanctum');
});

Route::prefix('creators/{id}/analytics')->group(function () {
    Route::get('/dashboard', [AnalyticsController::class, 'dashboard']);
    Route::get('/posts', [AnalyticsController::class, 'postPerformance']);
    Route::get('/audience', [AnalyticsController::class, 'audienceInsights']);
});

Route::get('users/{id}/engagement-level', [AnalyticsController::class, 'engagementLevel']);
```

- [ ] **Step 2: Verify routes registered**

```bash
php artisan route:list --path=sponsored
php artisan route:list --path=creator-battles
php artisan route:list --path=collaborat
php artisan route:list --path=analytics
php artisan route:list --path=engagement
```

Expected: All 12 routes listed.

- [ ] **Step 3: Commit on server**

```bash
git add routes/api.php
git commit -m "feat: register Phase 4 flywheel routes"
```

---

### Task 11: Register Scheduled Commands

**Files:**
- Modify: `app/Console/Kernel.php` (or `routes/console.php` if Laravel 11+ style)

- [ ] **Step 1: Check scheduler location**

```bash
grep -l 'schedule' app/Console/Kernel.php routes/console.php 2>/dev/null
```

- [ ] **Step 2: Add scheduled commands**

Add to the scheduler:

```php
$schedule->command('flywheel:update-engagement-levels')->daily();
$schedule->command('flywheel:detect-collaborations')->daily();
```

- [ ] **Step 3: Verify schedule**

```bash
php artisan schedule:list | grep flywheel
```

Expected: Both commands listed as daily.

- [ ] **Step 4: Commit**

```bash
git add app/Console/Kernel.php  # or routes/console.php
git commit -m "feat: schedule Phase 4 flywheel commands daily"
```

---

### Task 12: Smoke Test All Endpoints

- [ ] **Step 1: Test GET endpoints return 200**

```bash
curl -s -o /dev/null -w "%{http_code}" https://zima-uat.site:8003/api/sponsored-posts/active
curl -s -o /dev/null -w "%{http_code}" https://zima-uat.site:8003/api/sponsored-posts/creators
curl -s -o /dev/null -w "%{http_code}" https://zima-uat.site:8003/api/creators/1/sponsored
curl -s -o /dev/null -w "%{http_code}" https://zima-uat.site:8003/api/creators/1/collaborations
curl -s -o /dev/null -w "%{http_code}" https://zima-uat.site:8003/api/creator-battles
curl -s -o /dev/null -w "%{http_code}" https://zima-uat.site:8003/api/creators/1/analytics/dashboard
curl -s -o /dev/null -w "%{http_code}" https://zima-uat.site:8003/api/creators/1/analytics/posts
curl -s -o /dev/null -w "%{http_code}" https://zima-uat.site:8003/api/creators/1/analytics/audience
curl -s -o /dev/null -w "%{http_code}" https://zima-uat.site:8003/api/users/1/engagement-level
```

Expected: All return `200`.

- [ ] **Step 2: Test response structure**

```bash
curl -s https://zima-uat.site:8003/api/sponsored-posts/active | python3 -c "import sys,json; d=json.load(sys.stdin); print('OK' if 'data' in d else 'FAIL')"
curl -s https://zima-uat.site:8003/api/creator-battles | python3 -c "import sys,json; d=json.load(sys.stdin); print('OK' if 'data' in d else 'FAIL')"
curl -s https://zima-uat.site:8003/api/creators/1/analytics/dashboard | python3 -c "import sys,json; d=json.load(sys.stdin); print('OK' if 'data' in d else 'FAIL')"
```

Expected: All print `OK`.

- [ ] **Step 3: Run artisan commands**

```bash
php artisan flywheel:update-engagement-levels
php artisan flywheel:detect-collaborations
```

Expected: Both complete without errors.

---

## Summary

| Task | What | Files |
|------|------|-------|
| 1 | Migration (5 tables) | 1 new |
| 2 | Models: SponsoredPost, CollaborationSuggestion | 2 new |
| 3 | Models: CreatorBattle, CreatorBattleVote, UserEngagementLevel | 3 new |
| 4 | SponsoredPostController | 1 new |
| 5 | CollaborationController | 1 new |
| 6 | CreatorBattleController | 1 new |
| 7 | AnalyticsController | 1 new |
| 8 | UpdateEngagementLevels command | 1 new |
| 9 | DetectCollaborations command | 1 new |
| 10 | Route registration | 1 modified |
| 11 | Scheduler registration | 1 modified |
| 12 | Smoke test all endpoints | 0 |

**Total: 12 new files, 2 modified files, 12 tasks**
