# Flywheel Phase 4: Advanced + Optimization — Implementation Plan

> **For agentic workers:** REQUIRED SUB-SKILL: Use superpowers:subagent-driven-development (recommended) or superpowers:executing-plans to implement this plan task-by-task. Steps use checkbox (`- [ ]`) syntax for tracking.

**Goal:** Complete the Flywheel with sponsored posts marketplace, collaboration radar, intensity graduation, creator battles, and an analytics dashboard — bringing all 3 revenue tiers online.

**Architecture:** Backend adds `sponsored_posts`, `collaboration_suggestions`, `user_engagement_levels`, `creator_battles` tables with detection jobs. Frontend adds sponsored post badge + creation flow, collaboration radar widget, intensity-aware feed behavior, battle thread viewer, and a full analytics dashboard screen. Settings gain creator opt-out toggles.

**Tech Stack:** Flutter/Dart, http package, existing PostCard/CreatorService/GossipService patterns, AppStrings bilingual, Material 3 monochromatic design system, FCM push notifications

**Spec:** `docs/superpowers/specs/2026-03-26-tajiri-flywheel-growth-engine-design.md` (Phase 4 + Sections 4.3, 5.1, 6.2)

---

## File Structure

### New Files (Create)

| File | Responsibility |
|------|---------------|
| `lib/models/sponsored_post_models.dart` | SponsoredPost, SponsorshipCampaign, SponsorshipTier models |
| `lib/models/collaboration_models.dart` | CollaborationSuggestion, CreatorPair models |
| `lib/models/battle_models.dart` | CreatorBattle, BattleSide, BattleVote models |
| `lib/models/analytics_models.dart` | AnalyticsDashboard, PostPerformance, AudienceInsight, EngagementMetrics models |
| `lib/services/sponsored_post_service.dart` | CRUD for sponsored posts, campaign management |
| `lib/services/collaboration_service.dart` | Fetch collaboration suggestions, accept/dismiss |
| `lib/services/battle_service.dart` | Create/join battles, vote, get battle threads |
| `lib/services/analytics_service.dart` | Fetch dashboard metrics, post performance, audience data |
| `lib/widgets/sponsored_badge.dart` | Small "Sponsored" label badge for PostCard |
| `lib/widgets/collaboration_card.dart` | Card showing suggested collaborator with action buttons |
| `lib/widgets/battle_thread_card.dart` | Split card showing Side A vs Side B with vote counts |
| `lib/screens/sponsored/create_sponsored_post_screen.dart` | Business creates sponsored post campaign |
| `lib/screens/sponsored/sponsored_posts_screen.dart` | Browse available creators for sponsorship |
| `lib/screens/analytics/analytics_dashboard_screen.dart` | Full analytics: DAU, session depth, engagement, earnings |
| `lib/screens/feed/battle_thread_screen.dart` | Split-thread viewer: Side A vs Side B |
| `test/models/sponsored_post_models_test.dart` | Unit tests for sponsored post models |
| `test/models/collaboration_models_test.dart` | Unit tests for collaboration models |
| `test/models/battle_models_test.dart` | Unit tests for battle models |
| `test/models/analytics_models_test.dart` | Unit tests for analytics models |

### Modified Files

| File | Changes |
|------|---------|
| `lib/models/post_models.dart` | Add `isSponsored`, `sponsorId`, `sponsorName` fields to Post |
| `lib/models/gossip_models.dart` | Add `threadType` field (normal/battle) to GossipThread |
| `lib/services/gossip_service.dart` | Add `getBattleThreads()` method |
| `lib/widgets/post_card.dart` | Show SponsoredBadge when `post.isSponsored` |
| `lib/screens/profile/creator_dashboard_section.dart` | Add collaboration radar + analytics link |
| `lib/screens/settings/settings_screen.dart` | Add Creator Settings section with opt-out toggles |
| `lib/services/fcm_service.dart` | Add routing for `collaboration_suggestion`, `battle_invitation` |
| `lib/l10n/app_strings.dart` | Add ~40 bilingual strings for Phase 4 features |
| `lib/main.dart` | Add routes for analytics, sponsored, battle screens |

---

## Task 1: Backend — Sponsored Posts, Battles, Collaboration, Analytics tables + endpoints

**Files (SSH to zima-uat.site):**
- Create: `database/migrations/2026_03_26_220000_create_phase4_tables.php`
- Create: `app/Models/SponsoredPost.php`
- Create: `app/Models/CollaborationSuggestion.php`
- Create: `app/Models/CreatorBattle.php`
- Create: `app/Models/UserEngagementLevel.php`
- Create: `app/Http/Controllers/Api/SponsoredPostController.php`
- Create: `app/Http/Controllers/Api/CollaborationController.php`
- Create: `app/Http/Controllers/Api/BattleController.php`
- Create: `app/Http/Controllers/Api/AnalyticsController.php`
- Create: `app/Console/Commands/DetectCollaborations.php`
- Create: `app/Console/Commands/UpdateEngagementLevels.php`
- Modify: `routes/api.php`
- Modify: `routes/console.php`

- [ ] **Step 1: Create migration with all Phase 4 tables**

```php
// sponsored_posts: id, post_id, sponsor_user_id, creator_user_id, budget, currency, status (draft/pending/active/completed/cancelled), tier_required (star/legend), impressions_target, impressions_delivered, created_at, updated_at
// collaboration_suggestions: id, creator_a_id, creator_b_id, shared_category, affinity_score, status (suggested/accepted/dismissed), created_at, updated_at
// creator_battles: id, thread_id, creator_a_id, creator_b_id, topic, votes_a, votes_b, status (open/voting/closed), started_at, ends_at, created_at, updated_at
// creator_battle_votes: id, battle_id, user_id, side (a/b), created_at
// user_engagement_levels: id, user_id, level (gentle/medium/full), account_age_days, response_score, last_evaluated_at, created_at, updated_at
```

- [ ] **Step 2: Create models**
- [ ] **Step 3: Create controllers**

SponsoredPostController:
- `index(Request)` — GET /api/sponsored-posts — list active sponsored posts
- `store(Request)` — POST /api/sponsored-posts — create sponsored post campaign
- `creatorsForSponsor(Request)` — GET /api/sponsored-posts/creators — browse Star/Legend creators
- `mySponsored(Request, $creatorId)` — GET /api/creators/{id}/sponsored — creator's sponsored posts

CollaborationController:
- `suggestions(Request, $creatorId)` — GET /api/creators/{id}/collaborations — suggested partners
- `respond(Request, $id)` — POST /api/collaborations/{id}/respond — accept/dismiss

BattleController:
- `index(Request)` — GET /api/battles — list active battles
- `show(Request, $id)` — GET /api/battles/{id} — battle detail
- `vote(Request, $id)` — POST /api/battles/{id}/vote — cast vote

AnalyticsController:
- `dashboard(Request, $creatorId)` — GET /api/creators/{id}/analytics — full dashboard metrics
- `postPerformance(Request, $postId)` — GET /api/posts/{id}/analytics — single post metrics
- `audienceInsights(Request, $creatorId)` — GET /api/creators/{id}/audience — audience demographics

- [ ] **Step 4: Create DetectCollaborations command (daily at 02:00)**

Finds creator pairs with: same top category, both growing audiences (follower_change > 0 last 30 days), no existing suggestion in last 90 days. Inserts into `collaboration_suggestions`.

- [ ] **Step 5: Create UpdateEngagementLevels command (daily at 03:00)**

For each user: calculate `account_age_days` from created_at. `response_score` = (notifications_opened / notifications_sent) over last 14 days. Level assignment:
- Week 1-2 (age < 15 days): gentle
- Week 3-6 (age 15-42 days) AND response_score > 0.3: medium
- Week 7+ (age > 42 days) AND response_score > 0.3: full
- Users with response_score < 0.3 at any age: stay at previous level (don't escalate)

- [ ] **Step 6: Register routes + schedules**

Routes:
```php
Route::get('sponsored-posts', [SponsoredPostController::class, 'index']);
Route::post('sponsored-posts', [SponsoredPostController::class, 'store']);
Route::get('sponsored-posts/creators', [SponsoredPostController::class, 'creatorsForSponsor']);
Route::get('creators/{id}/sponsored', [SponsoredPostController::class, 'mySponsored']);
Route::get('creators/{id}/collaborations', [CollaborationController::class, 'suggestions']);
Route::post('collaborations/{id}/respond', [CollaborationController::class, 'respond']);
Route::get('battles', [BattleController::class, 'index']);
Route::get('battles/{id}', [BattleController::class, 'show']);
Route::post('battles/{id}/vote', [BattleController::class, 'vote']);
Route::get('creators/{id}/analytics', [AnalyticsController::class, 'dashboard']);
Route::get('posts/{id}/analytics', [AnalyticsController::class, 'postPerformance']);
Route::get('creators/{id}/audience', [AnalyticsController::class, 'audienceInsights']);
Route::get('users/{id}/engagement-level', fn($id) => response()->json(['data' => ['level' => UserEngagementLevel::where('user_id', $id)->first()?->level ?? 'gentle']]));
```

Schedules:
```php
Schedule::command('collaborations:detect')->dailyAt('02:00');
Schedule::command('engagement:update-levels')->dailyAt('03:00');
```

- [ ] **Step 7: Run migrations, verify routes**
- [ ] **Step 8: Commit backend**

---

## Task 2: Sponsored Post Models (Flutter)

**Files:**
- Create: `lib/models/sponsored_post_models.dart`
- Test: `test/models/sponsored_post_models_test.dart`

- [ ] **Step 1: Create models**

```dart
// Models for sponsored posts marketplace.

/// Helper to safely parse int from dynamic
int _parseInt(dynamic value) {
  if (value == null) return 0;
  if (value is int) return value;
  if (value is String) return int.tryParse(value) ?? 0;
  return 0;
}

/// Helper to safely parse double from dynamic
double _parseDouble(dynamic value, [double defaultValue = 0.0]) {
  if (value == null) return defaultValue;
  if (value is double) return value;
  if (value is int) return value.toDouble();
  if (value is String) return double.tryParse(value) ?? defaultValue;
  return defaultValue;
}

/// Helper to safely parse bool from dynamic
bool _parseBool(dynamic value, [bool defaultValue = false]) {
  if (value == null) return defaultValue;
  if (value is bool) return value;
  if (value is int) return value != 0;
  if (value is String) return value.toLowerCase() == 'true' || value == '1';
  return defaultValue;
}

/// Status of a sponsored post campaign.
enum SponsoredPostStatus {
  draft, pending, active, completed, cancelled;

  factory SponsoredPostStatus.fromString(String? s) {
    switch (s?.toLowerCase()) {
      case 'pending': return SponsoredPostStatus.pending;
      case 'active': return SponsoredPostStatus.active;
      case 'completed': return SponsoredPostStatus.completed;
      case 'cancelled': return SponsoredPostStatus.cancelled;
      default: return SponsoredPostStatus.draft;
    }
  }
}

/// A sponsored post campaign linking a business sponsor to a creator's post.
class SponsoredPost {
  final int id;
  final int postId;
  final int sponsorUserId;
  final int creatorUserId;
  final double budget;
  final String currency;
  final SponsoredPostStatus status;
  final String tierRequired;
  final int impressionsTarget;
  final int impressionsDelivered;
  final String? sponsorName;
  final String? creatorName;
  final DateTime createdAt;

  SponsoredPost({
    required this.id,
    required this.postId,
    required this.sponsorUserId,
    required this.creatorUserId,
    required this.budget,
    required this.currency,
    required this.status,
    required this.tierRequired,
    required this.impressionsTarget,
    required this.impressionsDelivered,
    this.sponsorName,
    this.creatorName,
    required this.createdAt,
  });

  factory SponsoredPost.fromJson(Map<String, dynamic> json) {
    return SponsoredPost(
      id: _parseInt(json['id']),
      postId: _parseInt(json['post_id']),
      sponsorUserId: _parseInt(json['sponsor_user_id']),
      creatorUserId: _parseInt(json['creator_user_id']),
      budget: _parseDouble(json['budget']),
      currency: (json['currency'] as String?) ?? 'TSh',
      status: SponsoredPostStatus.fromString(json['status'] as String?),
      tierRequired: (json['tier_required'] as String?) ?? 'star',
      impressionsTarget: _parseInt(json['impressions_target']),
      impressionsDelivered: _parseInt(json['impressions_delivered']),
      sponsorName: json['sponsor_name'] as String?,
      creatorName: json['creator_name'] as String?,
      createdAt: json['created_at'] != null
          ? DateTime.tryParse(json['created_at'].toString()) ?? DateTime.now()
          : DateTime.now(),
    );
  }

  double get deliveryPercent => impressionsTarget > 0
      ? (impressionsDelivered / impressionsTarget * 100).clamp(0, 100)
      : 0;
}

/// A creator available for sponsorship (browse result).
class SponsorableCreator {
  final int userId;
  final String name;
  final String? avatarUrl;
  final String tier;
  final int followerCount;
  final double avgEngagementRate;
  final String topCategory;

  SponsorableCreator({
    required this.userId,
    required this.name,
    this.avatarUrl,
    required this.tier,
    required this.followerCount,
    required this.avgEngagementRate,
    required this.topCategory,
  });

  factory SponsorableCreator.fromJson(Map<String, dynamic> json) {
    return SponsorableCreator(
      userId: _parseInt(json['user_id']),
      name: (json['name'] as String?) ?? '',
      avatarUrl: json['avatar_url'] as String?,
      tier: (json['tier'] as String?) ?? 'star',
      followerCount: _parseInt(json['follower_count']),
      avgEngagementRate: _parseDouble(json['avg_engagement_rate']),
      topCategory: (json['top_category'] as String?) ?? '',
    );
  }
}
```

- [ ] **Step 2: Write tests**

```dart
import 'package:flutter_test/flutter_test.dart';
import 'package:tajiri/models/sponsored_post_models.dart';

void main() {
  group('SponsoredPostStatus', () {
    test('fromString parses valid statuses', () {
      expect(SponsoredPostStatus.fromString('active'), SponsoredPostStatus.active);
      expect(SponsoredPostStatus.fromString('completed'), SponsoredPostStatus.completed);
      expect(SponsoredPostStatus.fromString(null), SponsoredPostStatus.draft);
    });
  });

  group('SponsoredPost', () {
    test('fromJson parses full sponsored post', () {
      final sp = SponsoredPost.fromJson({
        'id': 1, 'post_id': 42, 'sponsor_user_id': 10, 'creator_user_id': 20,
        'budget': 50000.0, 'currency': 'TSh', 'status': 'active',
        'tier_required': 'star', 'impressions_target': 10000, 'impressions_delivered': 5000,
        'sponsor_name': 'Biz', 'creator_name': 'Creator', 'created_at': '2026-03-26T00:00:00Z',
      });
      expect(sp.id, 1);
      expect(sp.budget, 50000.0);
      expect(sp.status, SponsoredPostStatus.active);
      expect(sp.deliveryPercent, 50.0);
    });

    test('fromJson handles minimal data', () {
      final sp = SponsoredPost.fromJson({});
      expect(sp.id, 0);
      expect(sp.status, SponsoredPostStatus.draft);
      expect(sp.currency, 'TSh');
    });
  });

  group('SponsorableCreator', () {
    test('fromJson parses creator', () {
      final c = SponsorableCreator.fromJson({
        'user_id': 5, 'name': 'TestCreator', 'tier': 'legend',
        'follower_count': 50000, 'avg_engagement_rate': 8.5, 'top_category': 'music',
      });
      expect(c.name, 'TestCreator');
      expect(c.tier, 'legend');
      expect(c.avgEngagementRate, 8.5);
    });
  });
}
```

- [ ] **Step 3: Run tests**
- [ ] **Step 4: Commit**

---

## Task 3: Collaboration + Battle + Analytics Models (Flutter)

**Files:**
- Create: `lib/models/collaboration_models.dart`
- Create: `lib/models/battle_models.dart`
- Create: `lib/models/analytics_models.dart`
- Test: `test/models/collaboration_models_test.dart`
- Test: `test/models/battle_models_test.dart`
- Test: `test/models/analytics_models_test.dart`

- [ ] **Step 1: Create collaboration models**

```dart
// Models for collaboration radar suggestions.

int _parseInt(dynamic value) {
  if (value == null) return 0;
  if (value is int) return value;
  if (value is String) return int.tryParse(value) ?? 0;
  return 0;
}

double _parseDouble(dynamic value, [double defaultValue = 0.0]) {
  if (value == null) return defaultValue;
  if (value is double) return value;
  if (value is int) return value.toDouble();
  if (value is String) return double.tryParse(value) ?? defaultValue;
  return defaultValue;
}

/// A suggested collaboration between two creators.
class CollaborationSuggestion {
  final int id;
  final int creatorAId;
  final int creatorBId;
  final String sharedCategory;
  final double affinityScore;
  final String status; // suggested, accepted, dismissed
  final String? partnerName;
  final String? partnerAvatarUrl;
  final String? partnerTier;
  final int? partnerFollowerCount;

  CollaborationSuggestion({
    required this.id,
    required this.creatorAId,
    required this.creatorBId,
    required this.sharedCategory,
    required this.affinityScore,
    required this.status,
    this.partnerName,
    this.partnerAvatarUrl,
    this.partnerTier,
    this.partnerFollowerCount,
  });

  factory CollaborationSuggestion.fromJson(Map<String, dynamic> json) {
    return CollaborationSuggestion(
      id: _parseInt(json['id']),
      creatorAId: _parseInt(json['creator_a_id']),
      creatorBId: _parseInt(json['creator_b_id']),
      sharedCategory: (json['shared_category'] as String?) ?? '',
      affinityScore: _parseDouble(json['affinity_score']),
      status: (json['status'] as String?) ?? 'suggested',
      partnerName: json['partner_name'] as String?,
      partnerAvatarUrl: json['partner_avatar_url'] as String?,
      partnerTier: json['partner_tier'] as String?,
      partnerFollowerCount: json['partner_follower_count'] != null
          ? _parseInt(json['partner_follower_count']) : null,
    );
  }
}
```

- [ ] **Step 2: Create battle models**

```dart
// Models for creator battles (split-thread debates).

int _parseInt(dynamic value) {
  if (value == null) return 0;
  if (value is int) return value;
  if (value is String) return int.tryParse(value) ?? 0;
  return 0;
}

/// Status of a creator battle.
enum BattleStatus {
  open, voting, closed;

  factory BattleStatus.fromString(String? s) {
    switch (s?.toLowerCase()) {
      case 'voting': return BattleStatus.voting;
      case 'closed': return BattleStatus.closed;
      default: return BattleStatus.open;
    }
  }
}

/// A creator battle: two creators, opposing takes, audience votes.
class CreatorBattle {
  final int id;
  final int? threadId;
  final int creatorAId;
  final int creatorBId;
  final String topic;
  final int votesA;
  final int votesB;
  final BattleStatus status;
  final DateTime? startsAt;
  final DateTime? endsAt;
  final String? creatorAName;
  final String? creatorBName;
  final String? creatorAAvatarUrl;
  final String? creatorBAvatarUrl;
  final String? userVote; // null, 'a', or 'b'

  CreatorBattle({
    required this.id,
    this.threadId,
    required this.creatorAId,
    required this.creatorBId,
    required this.topic,
    required this.votesA,
    required this.votesB,
    required this.status,
    this.startsAt,
    this.endsAt,
    this.creatorAName,
    this.creatorBName,
    this.creatorAAvatarUrl,
    this.creatorBAvatarUrl,
    this.userVote,
  });

  factory CreatorBattle.fromJson(Map<String, dynamic> json) {
    return CreatorBattle(
      id: _parseInt(json['id']),
      threadId: json['thread_id'] != null ? _parseInt(json['thread_id']) : null,
      creatorAId: _parseInt(json['creator_a_id']),
      creatorBId: _parseInt(json['creator_b_id']),
      topic: (json['topic'] as String?) ?? '',
      votesA: _parseInt(json['votes_a']),
      votesB: _parseInt(json['votes_b']),
      status: BattleStatus.fromString(json['status'] as String?),
      startsAt: json['started_at'] != null ? DateTime.tryParse(json['started_at'].toString()) : null,
      endsAt: json['ends_at'] != null ? DateTime.tryParse(json['ends_at'].toString()) : null,
      creatorAName: json['creator_a_name'] as String?,
      creatorBName: json['creator_b_name'] as String?,
      creatorAAvatarUrl: json['creator_a_avatar_url'] as String?,
      creatorBAvatarUrl: json['creator_b_avatar_url'] as String?,
      userVote: json['user_vote'] as String?,
    );
  }

  int get totalVotes => votesA + votesB;
  double get percentA => totalVotes > 0 ? votesA / totalVotes * 100 : 50;
  double get percentB => totalVotes > 0 ? votesB / totalVotes * 100 : 50;
}
```

- [ ] **Step 3: Create analytics models**

```dart
// Models for creator analytics dashboard.

int _parseInt(dynamic value) {
  if (value == null) return 0;
  if (value is int) return value;
  if (value is String) return int.tryParse(value) ?? 0;
  return 0;
}

double _parseDouble(dynamic value, [double defaultValue = 0.0]) {
  if (value == null) return defaultValue;
  if (value is double) return value;
  if (value is int) return value.toDouble();
  if (value is String) return double.tryParse(value) ?? defaultValue;
  return defaultValue;
}

/// Full analytics dashboard data for a creator.
class AnalyticsDashboard {
  final int totalViews;
  final int totalLikes;
  final int totalShares;
  final int totalComments;
  final double avgEngagementRate;
  final int followerCount;
  final int followerChange30d;
  final int threadsTriggered30d;
  final int postsCount30d;
  final double sessionDepthAvg;
  final String bestPostingTime;
  final String topContentFormat;
  final String topCategory;
  final String engagementTrend; // up, down, stable
  final List<DailyMetric> dailyMetrics;

  AnalyticsDashboard({
    required this.totalViews,
    required this.totalLikes,
    required this.totalShares,
    required this.totalComments,
    required this.avgEngagementRate,
    required this.followerCount,
    required this.followerChange30d,
    required this.threadsTriggered30d,
    required this.postsCount30d,
    required this.sessionDepthAvg,
    required this.bestPostingTime,
    required this.topContentFormat,
    required this.topCategory,
    required this.engagementTrend,
    required this.dailyMetrics,
  });

  factory AnalyticsDashboard.fromJson(Map<String, dynamic> json) {
    final rawMetrics = json['daily_metrics'] is List ? json['daily_metrics'] as List : [];
    return AnalyticsDashboard(
      totalViews: _parseInt(json['total_views']),
      totalLikes: _parseInt(json['total_likes']),
      totalShares: _parseInt(json['total_shares']),
      totalComments: _parseInt(json['total_comments']),
      avgEngagementRate: _parseDouble(json['avg_engagement_rate']),
      followerCount: _parseInt(json['follower_count']),
      followerChange30d: _parseInt(json['follower_change_30d']),
      threadsTriggered30d: _parseInt(json['threads_triggered_30d']),
      postsCount30d: _parseInt(json['posts_count_30d']),
      sessionDepthAvg: _parseDouble(json['session_depth_avg']),
      bestPostingTime: (json['best_posting_time'] as String?) ?? '',
      topContentFormat: (json['top_content_format'] as String?) ?? '',
      topCategory: (json['top_category'] as String?) ?? '',
      engagementTrend: (json['engagement_trend'] as String?) ?? 'stable',
      dailyMetrics: rawMetrics
          .whereType<Map<String, dynamic>>()
          .map((e) => DailyMetric.fromJson(e))
          .toList(),
    );
  }
}

/// Single day's metric point for charts.
class DailyMetric {
  final String date;
  final int views;
  final int likes;
  final int followers;

  DailyMetric({
    required this.date,
    required this.views,
    required this.likes,
    required this.followers,
  });

  factory DailyMetric.fromJson(Map<String, dynamic> json) {
    return DailyMetric(
      date: (json['date'] as String?) ?? '',
      views: _parseInt(json['views']),
      likes: _parseInt(json['likes']),
      followers: _parseInt(json['followers']),
    );
  }
}

/// Per-post analytics.
class PostPerformance {
  final int postId;
  final int views;
  final int likes;
  final int comments;
  final int shares;
  final int saves;
  final double engagementRate;
  final int avgDwellMs;
  final String? threadTitle;

  PostPerformance({
    required this.postId,
    required this.views,
    required this.likes,
    required this.comments,
    required this.shares,
    required this.saves,
    required this.engagementRate,
    required this.avgDwellMs,
    this.threadTitle,
  });

  factory PostPerformance.fromJson(Map<String, dynamic> json) {
    return PostPerformance(
      postId: _parseInt(json['post_id']),
      views: _parseInt(json['views']),
      likes: _parseInt(json['likes']),
      comments: _parseInt(json['comments']),
      shares: _parseInt(json['shares']),
      saves: _parseInt(json['saves']),
      engagementRate: _parseDouble(json['engagement_rate']),
      avgDwellMs: _parseInt(json['avg_dwell_ms']),
      threadTitle: json['thread_title'] as String?,
    );
  }
}

/// Audience demographic insights.
class AudienceInsight {
  final String topCity;
  final String topAgeRange;
  final double malePercent;
  final double femalePercent;
  final int activeFollowersCount;
  final String peakActivityTime;

  AudienceInsight({
    required this.topCity,
    required this.topAgeRange,
    required this.malePercent,
    required this.femalePercent,
    required this.activeFollowersCount,
    required this.peakActivityTime,
  });

  factory AudienceInsight.fromJson(Map<String, dynamic> json) {
    return AudienceInsight(
      topCity: (json['top_city'] as String?) ?? '',
      topAgeRange: (json['top_age_range'] as String?) ?? '',
      malePercent: _parseDouble(json['male_percent']),
      femalePercent: _parseDouble(json['female_percent']),
      activeFollowersCount: _parseInt(json['active_followers_count']),
      peakActivityTime: (json['peak_activity_time'] as String?) ?? '',
    );
  }
}
```

- [ ] **Step 4: Write tests for all three model files**

Tests should cover: full JSON parsing, minimal/empty data with defaults, enum parsing, computed properties (deliveryPercent, percentA/B, totalVotes).

- [ ] **Step 5: Run tests**
- [ ] **Step 6: Commit**

---

## Task 4: Services — SponsoredPostService, CollaborationService, BattleService, AnalyticsService

**Files:**
- Create: `lib/services/sponsored_post_service.dart`
- Create: `lib/services/collaboration_service.dart`
- Create: `lib/services/battle_service.dart`
- Create: `lib/services/analytics_service.dart`

- [ ] **Step 1: Create SponsoredPostService**

```dart
import 'dart:convert';
import 'package:flutter/foundation.dart';
import 'package:http/http.dart' as http;
import '../config/api_config.dart';
import '../models/sponsored_post_models.dart';

String get _baseUrl => ApiConfig.baseUrl;

class SponsoredPostService {
  Future<List<SponsoredPost>> getActiveSponsoredPosts({required String token}) async {
    try {
      final response = await http.get(
        Uri.parse('$_baseUrl/sponsored-posts'),
        headers: ApiConfig.authHeaders(token),
      );
      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        final rawList = data['data'] is List ? data['data'] as List : [];
        return rawList.whereType<Map<String, dynamic>>()
            .map((e) => SponsoredPost.fromJson(e)).toList();
      }
      return [];
    } catch (e) {
      debugPrint('[SponsoredPostService] getActive error: $e');
      return [];
    }
  }

  Future<List<SponsorableCreator>> browseSponsorableCreators({required String token}) async {
    try {
      final response = await http.get(
        Uri.parse('$_baseUrl/sponsored-posts/creators'),
        headers: ApiConfig.authHeaders(token),
      );
      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        final rawList = data['data'] is List ? data['data'] as List : [];
        return rawList.whereType<Map<String, dynamic>>()
            .map((e) => SponsorableCreator.fromJson(e)).toList();
      }
      return [];
    } catch (e) {
      debugPrint('[SponsoredPostService] browseCreators error: $e');
      return [];
    }
  }

  Future<bool> createSponsoredPost({
    required String token,
    required int postId,
    required int creatorUserId,
    required double budget,
    required int impressionsTarget,
  }) async {
    try {
      final response = await http.post(
        Uri.parse('$_baseUrl/sponsored-posts'),
        headers: {...ApiConfig.authHeaders(token), 'Content-Type': 'application/json'},
        body: jsonEncode({
          'post_id': postId,
          'creator_user_id': creatorUserId,
          'budget': budget,
          'impressions_target': impressionsTarget,
        }),
      );
      return response.statusCode == 200 || response.statusCode == 201;
    } catch (e) {
      debugPrint('[SponsoredPostService] create error: $e');
      return false;
    }
  }

  Future<List<SponsoredPost>> getCreatorSponsored({required String token, required int creatorId}) async {
    try {
      final response = await http.get(
        Uri.parse('$_baseUrl/creators/$creatorId/sponsored'),
        headers: ApiConfig.authHeaders(token),
      );
      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        final rawList = data['data'] is List ? data['data'] as List : [];
        return rawList.whereType<Map<String, dynamic>>()
            .map((e) => SponsoredPost.fromJson(e)).toList();
      }
      return [];
    } catch (e) {
      debugPrint('[SponsoredPostService] getCreatorSponsored error: $e');
      return [];
    }
  }
}
```

- [ ] **Step 2: Create CollaborationService**

```dart
import 'dart:convert';
import 'package:flutter/foundation.dart';
import 'package:http/http.dart' as http;
import '../config/api_config.dart';
import '../models/collaboration_models.dart';

String get _baseUrl => ApiConfig.baseUrl;

class CollaborationService {
  Future<List<CollaborationSuggestion>> getSuggestions({
    required String token,
    required int creatorId,
  }) async {
    try {
      final response = await http.get(
        Uri.parse('$_baseUrl/creators/$creatorId/collaborations'),
        headers: ApiConfig.authHeaders(token),
      );
      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        final rawList = data['data'] is List ? data['data'] as List : [];
        return rawList.whereType<Map<String, dynamic>>()
            .map((e) => CollaborationSuggestion.fromJson(e)).toList();
      }
      return [];
    } catch (e) {
      debugPrint('[CollaborationService] getSuggestions error: $e');
      return [];
    }
  }

  Future<bool> respond({
    required String token,
    required int suggestionId,
    required String action, // 'accepted' or 'dismissed'
  }) async {
    try {
      final response = await http.post(
        Uri.parse('$_baseUrl/collaborations/$suggestionId/respond'),
        headers: {...ApiConfig.authHeaders(token), 'Content-Type': 'application/json'},
        body: jsonEncode({'action': action}),
      );
      return response.statusCode == 200;
    } catch (e) {
      debugPrint('[CollaborationService] respond error: $e');
      return false;
    }
  }
}
```

- [ ] **Step 3: Create BattleService**

```dart
import 'dart:convert';
import 'package:flutter/foundation.dart';
import 'package:http/http.dart' as http;
import '../config/api_config.dart';
import '../models/battle_models.dart';

String get _baseUrl => ApiConfig.baseUrl;

class BattleService {
  Future<List<CreatorBattle>> getActiveBattles({required String token}) async {
    try {
      final response = await http.get(
        Uri.parse('$_baseUrl/battles'),
        headers: ApiConfig.authHeaders(token),
      );
      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        final rawList = data['data'] is List ? data['data'] as List : [];
        return rawList.whereType<Map<String, dynamic>>()
            .map((e) => CreatorBattle.fromJson(e)).toList();
      }
      return [];
    } catch (e) {
      debugPrint('[BattleService] getActiveBattles error: $e');
      return [];
    }
  }

  Future<CreatorBattle?> getBattle({required String token, required int battleId}) async {
    try {
      final response = await http.get(
        Uri.parse('$_baseUrl/battles/$battleId'),
        headers: ApiConfig.authHeaders(token),
      );
      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        if (data['data'] is Map<String, dynamic>) {
          return CreatorBattle.fromJson(data['data'] as Map<String, dynamic>);
        }
      }
      return null;
    } catch (e) {
      debugPrint('[BattleService] getBattle error: $e');
      return null;
    }
  }

  Future<bool> vote({
    required String token,
    required int battleId,
    required String side, // 'a' or 'b'
  }) async {
    try {
      final response = await http.post(
        Uri.parse('$_baseUrl/battles/$battleId/vote'),
        headers: {...ApiConfig.authHeaders(token), 'Content-Type': 'application/json'},
        body: jsonEncode({'side': side}),
      );
      return response.statusCode == 200;
    } catch (e) {
      debugPrint('[BattleService] vote error: $e');
      return false;
    }
  }
}
```

- [ ] **Step 4: Create AnalyticsService**

```dart
import 'dart:convert';
import 'package:flutter/foundation.dart';
import 'package:http/http.dart' as http;
import '../config/api_config.dart';
import '../models/analytics_models.dart';

String get _baseUrl => ApiConfig.baseUrl;

class AnalyticsService {
  Future<AnalyticsDashboard?> getDashboard({
    required String token,
    required int creatorId,
  }) async {
    try {
      final response = await http.get(
        Uri.parse('$_baseUrl/creators/$creatorId/analytics'),
        headers: ApiConfig.authHeaders(token),
      );
      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        final dashData = data['data'] ?? data;
        if (dashData is Map<String, dynamic>) {
          return AnalyticsDashboard.fromJson(dashData);
        }
      }
      return null;
    } catch (e) {
      debugPrint('[AnalyticsService] getDashboard error: $e');
      return null;
    }
  }

  Future<PostPerformance?> getPostPerformance({
    required String token,
    required int postId,
  }) async {
    try {
      final response = await http.get(
        Uri.parse('$_baseUrl/posts/$postId/analytics'),
        headers: ApiConfig.authHeaders(token),
      );
      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        final perfData = data['data'] ?? data;
        if (perfData is Map<String, dynamic>) {
          return PostPerformance.fromJson(perfData);
        }
      }
      return null;
    } catch (e) {
      debugPrint('[AnalyticsService] getPostPerformance error: $e');
      return null;
    }
  }

  Future<AudienceInsight?> getAudienceInsights({
    required String token,
    required int creatorId,
  }) async {
    try {
      final response = await http.get(
        Uri.parse('$_baseUrl/creators/$creatorId/audience'),
        headers: ApiConfig.authHeaders(token),
      );
      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        final insightData = data['data'] ?? data;
        if (insightData is Map<String, dynamic>) {
          return AudienceInsight.fromJson(insightData);
        }
      }
      return null;
    } catch (e) {
      debugPrint('[AnalyticsService] getAudienceInsights error: $e');
      return null;
    }
  }

  /// Get user's engagement level (gentle/medium/full).
  Future<String> getEngagementLevel({
    required String token,
    required int userId,
  }) async {
    try {
      final response = await http.get(
        Uri.parse('$_baseUrl/users/$userId/engagement-level'),
        headers: ApiConfig.authHeaders(token),
      );
      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        return (data['data']?['level'] as String?) ?? 'gentle';
      }
      return 'gentle';
    } catch (e) {
      debugPrint('[AnalyticsService] getEngagementLevel error: $e');
      return 'gentle';
    }
  }
}
```

- [ ] **Step 5: Run analyze**
- [ ] **Step 6: Commit**

---

## Task 5: Bilingual Strings for Phase 4

**Files:**
- Modify: `lib/l10n/app_strings.dart`

- [ ] **Step 1: Add strings section**

Add `// ——— Phase 4: Sponsored, Battles, Collaboration, Analytics ———` section. Check for existing strings before adding to avoid duplicates (e.g., `analytics` already exists).

```dart
  // ——— Phase 4: Sponsored, Battles, Collaboration, Analytics ———
  String get sponsored => isSwahili ? 'Imedhaminiwa' : 'Sponsored';
  String get sponsoredPost => isSwahili ? 'Chapisho cha Udhamini' : 'Sponsored Post';
  String get createSponsoredPost => isSwahili ? 'Unda Chapisho cha Udhamini' : 'Create Sponsored Post';
  String get browseSponsorableCreators => isSwahili ? 'Tafuta Waundaji' : 'Browse Creators';
  String get sponsorshipBudget => isSwahili ? 'Bajeti ya Udhamini' : 'Sponsorship Budget';
  String get impressionsTarget => isSwahili ? 'Lengo la Maonyesho' : 'Impressions Target';
  String get impressionsDelivered => isSwahili ? 'Maonyesho Yaliyofikiwa' : 'Impressions Delivered';
  String get starLegendOnly => isSwahili ? 'Star na Legend tu' : 'Star & Legend only';
  String get collaborationRadar => isSwahili ? 'Rada ya Ushirikiano' : 'Collaboration Radar';
  String get suggestedCollaborators => isSwahili ? 'Washirika Wanaopendekezwa' : 'Suggested Collaborators';
  String get collaborate => isSwahili ? 'Shirikiana' : 'Collaborate';
  String get dismissSuggestion => isSwahili ? 'Ondoa' : 'Dismiss';
  String get sharedCategory => isSwahili ? 'Aina Inayoshirikiana' : 'Shared Category';
  String get creatorBattles => isSwahili ? 'Mashindano ya Waundaji' : 'Creator Battles';
  String get battleTopic => isSwahili ? 'Mada ya Mashindano' : 'Battle Topic';
  String get sideA => isSwahili ? 'Upande A' : 'Side A';
  String get sideB => isSwahili ? 'Upande B' : 'Side B';
  String get castVote => isSwahili ? 'Piga Kura' : 'Cast Vote';
  String get voteCast => isSwahili ? 'Kura imepigwa!' : 'Vote cast!';
  String get battleOpen => isSwahili ? 'Wazi' : 'Open';
  String get battleVoting => isSwahili ? 'Kupigia Kura' : 'Voting';
  String get battleClosed => isSwahili ? 'Imefungwa' : 'Closed';
  String get analyticsDashboard => isSwahili ? 'Dashibodi ya Takwimu' : 'Analytics Dashboard';
  String get avgEngagement => isSwahili ? 'Wastani wa Ushiriki' : 'Avg Engagement';
  String get postsThisMonth => isSwahili ? 'Machapisho Mwezi Huu' : 'Posts This Month';
  String get bestTime => isSwahili ? 'Muda Bora' : 'Best Time';
  String get topFormat => isSwahili ? 'Umbizo Bora' : 'Top Format';
  String get audienceInsights => isSwahili ? 'Maoni ya Hadhira' : 'Audience Insights';
  String get topCity => isSwahili ? 'Jiji Kuu' : 'Top City';
  String get activeFollowers => isSwahili ? 'Wafuasi Hai' : 'Active Followers';
  String get peakActivity => isSwahili ? 'Kilele cha Shughuli' : 'Peak Activity';
  String get last30Days => isSwahili ? 'Siku 30 Zilizopita' : 'Last 30 Days';
  String get viewAnalytics => isSwahili ? 'Tazama Takwimu' : 'View Analytics';
  String get creatorSettings => isSwahili ? 'Mipangilio ya Muundaji' : 'Creator Settings';
  String get optOutSponsored => isSwahili ? 'Sitaki machapisho ya udhamini' : 'Opt out of sponsored posts';
  String get optOutCollaboration => isSwahili ? 'Sitaki mapendekezo ya ushirikiano' : 'Opt out of collaboration suggestions';
  String get optOutBattles => isSwahili ? 'Sitaki mashindano' : 'Opt out of battles';
  String get optOutThreads => isSwahili ? 'Sitaki machapisho yangu kwenye mada' : 'Don\'t include my posts in threads';
  String get votes => isSwahili ? 'kura' : 'votes';
  String get vs => 'vs';
```

- [ ] **Step 2: Run analyze**
- [ ] **Step 3: Commit**

---

## Task 6: SponsoredBadge + CollaborationCard + BattleThreadCard Widgets

**Files:**
- Create: `lib/widgets/sponsored_badge.dart`
- Create: `lib/widgets/collaboration_card.dart`
- Create: `lib/widgets/battle_thread_card.dart`

- [ ] **Step 1: Create SponsoredBadge**

```dart
import 'package:flutter/material.dart';
import '../l10n/app_strings_scope.dart';

/// Small "Sponsored" label shown on sponsored posts.
class SponsoredBadge extends StatelessWidget {
  final String? sponsorName;

  const SponsoredBadge({super.key, this.sponsorName});

  @override
  Widget build(BuildContext context) {
    final strings = AppStringsScope.of(context);
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
      decoration: BoxDecoration(
        color: const Color(0xFFF0F0F0),
        borderRadius: BorderRadius.circular(6),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          const Icon(Icons.campaign_rounded, size: 12, color: Color(0xFF666666)),
          const SizedBox(width: 4),
          Text(
            sponsorName != null
                ? '${strings?.sponsored ?? "Sponsored"} · $sponsorName'
                : strings?.sponsored ?? 'Sponsored',
            style: const TextStyle(fontSize: 10, fontWeight: FontWeight.w600, color: Color(0xFF666666)),
          ),
        ],
      ),
    );
  }
}
```

- [ ] **Step 2: Create CollaborationCard**

```dart
import 'package:flutter/material.dart';
import '../models/collaboration_models.dart';
import '../widgets/creator_tier_badge.dart';
import '../l10n/app_strings_scope.dart';

/// Card showing a suggested collaboration partner with accept/dismiss actions.
class CollaborationCard extends StatelessWidget {
  final CollaborationSuggestion suggestion;
  final VoidCallback? onAccept;
  final VoidCallback? onDismiss;

  const CollaborationCard({
    super.key,
    required this.suggestion,
    this.onAccept,
    this.onDismiss,
  });

  @override
  Widget build(BuildContext context) {
    final strings = AppStringsScope.of(context);
    return Container(
      margin: const EdgeInsets.only(bottom: 8),
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: const Color(0xFFE0E0E0), width: 0.5),
      ),
      child: Row(
        children: [
          // Avatar
          CircleAvatar(
            radius: 22,
            backgroundColor: const Color(0xFFE0E0E0),
            backgroundImage: suggestion.partnerAvatarUrl != null
                ? NetworkImage(suggestion.partnerAvatarUrl!)
                : null,
            child: suggestion.partnerAvatarUrl == null
                ? const Icon(Icons.person_rounded, size: 22, color: Color(0xFF999999))
                : null,
          ),
          const SizedBox(width: 12),
          // Info
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Flexible(
                      child: Text(
                        suggestion.partnerName ?? 'Creator',
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: const TextStyle(fontSize: 14, fontWeight: FontWeight.w600, color: Color(0xFF1A1A1A)),
                      ),
                    ),
                    if (suggestion.partnerTier != null) ...[
                      const SizedBox(width: 6),
                      CreatorTierBadge(tier: suggestion.partnerTier!),
                    ],
                  ],
                ),
                const SizedBox(height: 2),
                Text(
                  '${strings?.sharedCategory ?? "Shared"}: ${suggestion.sharedCategory}',
                  style: const TextStyle(fontSize: 12, color: Color(0xFF666666)),
                ),
              ],
            ),
          ),
          // Actions
          IconButton(
            onPressed: onDismiss,
            icon: const Icon(Icons.close_rounded, size: 20, color: Color(0xFF999999)),
            constraints: const BoxConstraints(minWidth: 40, minHeight: 40),
          ),
          SizedBox(
            height: 36,
            child: ElevatedButton(
              onPressed: onAccept,
              style: ElevatedButton.styleFrom(
                backgroundColor: const Color(0xFF1A1A1A),
                foregroundColor: Colors.white,
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                padding: const EdgeInsets.symmetric(horizontal: 14),
              ),
              child: Text(strings?.collaborate ?? 'Collaborate', style: const TextStyle(fontSize: 12)),
            ),
          ),
        ],
      ),
    );
  }
}
```

- [ ] **Step 3: Create BattleThreadCard**

```dart
import 'package:flutter/material.dart';
import '../models/battle_models.dart';
import '../l10n/app_strings_scope.dart';

/// Split card showing Side A vs Side B with vote progress bars.
class BattleThreadCard extends StatelessWidget {
  final CreatorBattle battle;
  final VoidCallback? onTap;

  const BattleThreadCard({super.key, required this.battle, this.onTap});

  @override
  Widget build(BuildContext context) {
    final strings = AppStringsScope.of(context);
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 6),
      child: Material(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        child: InkWell(
          onTap: onTap,
          borderRadius: BorderRadius.circular(16),
          child: Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(16),
              border: Border.all(color: const Color(0xFFE0E0E0), width: 0.5),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Topic
                Text(
                  battle.topic,
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                  style: const TextStyle(fontSize: 15, fontWeight: FontWeight.w700, color: Color(0xFF1A1A1A)),
                ),
                const SizedBox(height: 12),
                // Side A vs Side B
                Row(
                  children: [
                    Expanded(
                      child: _buildSide(
                        name: battle.creatorAName ?? (strings?.sideA ?? 'Side A'),
                        percent: battle.percentA,
                        isLeft: true,
                      ),
                    ),
                    Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 8),
                      child: Text(
                        strings?.vs ?? 'vs',
                        style: const TextStyle(fontSize: 12, fontWeight: FontWeight.w700, color: Color(0xFF999999)),
                      ),
                    ),
                    Expanded(
                      child: _buildSide(
                        name: battle.creatorBName ?? (strings?.sideB ?? 'Side B'),
                        percent: battle.percentB,
                        isLeft: false,
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 8),
                // Vote bar
                ClipRRect(
                  borderRadius: BorderRadius.circular(4),
                  child: Row(
                    children: [
                      Expanded(
                        flex: battle.percentA.round().clamp(1, 99),
                        child: Container(height: 6, color: const Color(0xFF1A1A1A)),
                      ),
                      Expanded(
                        flex: battle.percentB.round().clamp(1, 99),
                        child: Container(height: 6, color: const Color(0xFFCCCCCC)),
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 6),
                // Vote count
                Text(
                  '${battle.totalVotes} ${strings?.votes ?? "votes"}',
                  style: const TextStyle(fontSize: 11, color: Color(0xFF999999)),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildSide({required String name, required double percent, required bool isLeft}) {
    return Column(
      crossAxisAlignment: isLeft ? CrossAxisAlignment.start : CrossAxisAlignment.end,
      children: [
        Text(
          name,
          maxLines: 1,
          overflow: TextOverflow.ellipsis,
          style: TextStyle(
            fontSize: 13,
            fontWeight: FontWeight.w600,
            color: isLeft ? const Color(0xFF1A1A1A) : const Color(0xFF666666),
          ),
        ),
        Text(
          '${percent.toStringAsFixed(0)}%',
          style: TextStyle(
            fontSize: 18,
            fontWeight: FontWeight.w800,
            color: isLeft ? const Color(0xFF1A1A1A) : const Color(0xFF666666),
          ),
        ),
      ],
    );
  }
}
```

- [ ] **Step 4: Run analyze**
- [ ] **Step 5: Commit**

---

## Task 7: Post Model — Add Sponsored Fields + PostCard Badge

**Files:**
- Modify: `lib/models/post_models.dart`
- Modify: `lib/widgets/post_card.dart`

- [ ] **Step 1: Add sponsored fields to Post model**

In `lib/models/post_models.dart`, add three fields to the Post class:

After `final bool allowComments;` (line 119), add:
```dart
  // Sponsored post fields
  final bool isSponsored;
  final int? sponsorId;
  final String? sponsorName;
```

Add to constructor (after `this.allowComments = true,`):
```dart
    this.isSponsored = false,
    this.sponsorId,
    this.sponsorName,
```

Add to `fromJson` (after the `allowComments` line):
```dart
      isSponsored: _parseBool(json['is_sponsored']),
      sponsorId: json['sponsor_id'] != null ? _parseInt(json['sponsor_id']) : null,
      sponsorName: json['sponsor_name'] as String?,
```

Add to `copyWith` parameters and body (after `allowComments`):
```dart
    bool? isSponsored,
    int? sponsorId,
    String? sponsorName,
```
```dart
      isSponsored: isSponsored ?? this.isSponsored,
      sponsorId: sponsorId ?? this.sponsorId,
      sponsorName: sponsorName ?? this.sponsorName,
```

Add to `toJson` (after `allow_comments`):
```dart
      'is_sponsored': isSponsored,
      if (sponsorId != null) 'sponsor_id': sponsorId,
      if (sponsorName != null) 'sponsor_name': sponsorName,
```

- [ ] **Step 2: Add SponsoredBadge to PostCard**

In `lib/widgets/post_card.dart`, add import:
```dart
import 'sponsored_badge.dart';
```

In the `_buildCardBody` method, find where the thread badge is shown (when `post.threadId != null`). After the thread badge block, add:
```dart
        if (widget.post.isSponsored)
          Padding(
            padding: const EdgeInsets.only(bottom: 6),
            child: SponsoredBadge(sponsorName: widget.post.sponsorName),
          ),
```

- [ ] **Step 3: Run analyze**
- [ ] **Step 4: Commit**

---

## Task 8: Analytics Dashboard Screen

**Files:**
- Create: `lib/screens/analytics/analytics_dashboard_screen.dart`

- [ ] **Step 1: Create AnalyticsDashboardScreen**

```dart
import 'package:flutter/material.dart';
import '../../models/analytics_models.dart';
import '../../services/analytics_service.dart';
import '../../services/local_storage_service.dart';
import '../../l10n/app_strings_scope.dart';

class AnalyticsDashboardScreen extends StatefulWidget {
  final int userId;

  const AnalyticsDashboardScreen({super.key, required this.userId});

  @override
  State<AnalyticsDashboardScreen> createState() => _AnalyticsDashboardScreenState();
}

class _AnalyticsDashboardScreenState extends State<AnalyticsDashboardScreen> {
  final AnalyticsService _analyticsService = AnalyticsService();
  AnalyticsDashboard? _dashboard;
  AudienceInsight? _audience;
  bool _loading = true;
  String? _error;

  @override
  void initState() {
    super.initState();
    _loadData();
  }

  Future<void> _loadData() async {
    setState(() { _loading = true; _error = null; });
    try {
      final storage = await LocalStorageService.getInstance();
      final token = storage.getAuthToken();
      if (token == null) {
        if (mounted) setState(() { _error = 'Not authenticated'; _loading = false; });
        return;
      }
      final results = await Future.wait([
        _analyticsService.getDashboard(token: token, creatorId: widget.userId),
        _analyticsService.getAudienceInsights(token: token, creatorId: widget.userId),
      ]);
      if (mounted) {
        setState(() {
          _dashboard = results[0] as AnalyticsDashboard?;
          _audience = results[1] as AudienceInsight?;
          _loading = false;
          if (_dashboard == null) _error = 'No analytics data';
        });
      }
    } catch (e) {
      if (mounted) setState(() { _error = 'Error: $e'; _loading = false; });
    }
  }

  @override
  Widget build(BuildContext context) {
    final strings = AppStringsScope.of(context);
    return Scaffold(
      backgroundColor: const Color(0xFFFAFAFA),
      appBar: AppBar(
        backgroundColor: Colors.white,
        foregroundColor: const Color(0xFF1A1A1A),
        elevation: 0,
        title: Text(
          strings?.analyticsDashboard ?? 'Analytics Dashboard',
          style: const TextStyle(fontSize: 18, fontWeight: FontWeight.w700),
        ),
      ),
      body: _loading
          ? const Center(child: CircularProgressIndicator(color: Color(0xFF1A1A1A)))
          : _error != null
              ? Center(
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Text(_error!, style: const TextStyle(color: Color(0xFF666666))),
                      const SizedBox(height: 16),
                      TextButton(onPressed: _loadData, child: Text(strings?.retry ?? 'Retry')),
                    ],
                  ),
                )
              : RefreshIndicator(
                  onRefresh: _loadData,
                  color: const Color(0xFF1A1A1A),
                  child: ListView(
                    padding: const EdgeInsets.all(16),
                    children: [
                      Text(strings?.last30Days ?? 'Last 30 Days',
                          style: const TextStyle(color: Color(0xFF999999), fontSize: 13)),
                      const SizedBox(height: 12),
                      // Overview stats grid
                      _buildStatsGrid(strings),
                      const SizedBox(height: 16),
                      // Engagement trend
                      _buildCard(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(strings?.avgEngagement ?? 'Avg Engagement',
                                style: const TextStyle(color: Color(0xFF666666), fontSize: 13)),
                            const SizedBox(height: 8),
                            Row(
                              crossAxisAlignment: CrossAxisAlignment.end,
                              children: [
                                Text(
                                  '${_dashboard!.avgEngagementRate.toStringAsFixed(1)}%',
                                  style: const TextStyle(fontSize: 28, fontWeight: FontWeight.w800, color: Color(0xFF1A1A1A)),
                                ),
                                const SizedBox(width: 8),
                                Icon(
                                  _dashboard!.engagementTrend == 'up' ? Icons.trending_up_rounded
                                      : _dashboard!.engagementTrend == 'down' ? Icons.trending_down_rounded
                                      : Icons.trending_flat_rounded,
                                  size: 20,
                                  color: const Color(0xFF666666),
                                ),
                              ],
                            ),
                          ],
                        ),
                      ),
                      const SizedBox(height: 12),
                      // Best posting time + format
                      Row(
                        children: [
                          Expanded(child: _buildInfoTile(
                            strings?.bestTime ?? 'Best Time',
                            _dashboard!.bestPostingTime.isNotEmpty ? _dashboard!.bestPostingTime : '—',
                            Icons.schedule_rounded,
                          )),
                          const SizedBox(width: 12),
                          Expanded(child: _buildInfoTile(
                            strings?.topFormat ?? 'Top Format',
                            _dashboard!.topContentFormat.isNotEmpty ? _dashboard!.topContentFormat : '—',
                            Icons.videocam_rounded,
                          )),
                        ],
                      ),
                      // Audience section
                      if (_audience != null) ...[
                        const SizedBox(height: 20),
                        Text(strings?.audienceInsights ?? 'Audience Insights',
                            style: const TextStyle(fontSize: 15, fontWeight: FontWeight.w600, color: Color(0xFF1A1A1A))),
                        const SizedBox(height: 12),
                        Row(
                          children: [
                            Expanded(child: _buildInfoTile(
                              strings?.topCity ?? 'Top City',
                              _audience!.topCity.isNotEmpty ? _audience!.topCity : '—',
                              Icons.location_on_rounded,
                            )),
                            const SizedBox(width: 12),
                            Expanded(child: _buildInfoTile(
                              strings?.peakActivity ?? 'Peak Activity',
                              _audience!.peakActivityTime.isNotEmpty ? _audience!.peakActivityTime : '—',
                              Icons.show_chart_rounded,
                            )),
                          ],
                        ),
                        const SizedBox(height: 12),
                        _buildCard(
                          child: Row(
                            mainAxisAlignment: MainAxisAlignment.spaceBetween,
                            children: [
                              Text(strings?.activeFollowers ?? 'Active Followers',
                                  style: const TextStyle(color: Color(0xFF666666), fontSize: 13)),
                              Text(
                                _formatCount(_audience!.activeFollowersCount),
                                style: const TextStyle(fontSize: 16, fontWeight: FontWeight.w700, color: Color(0xFF1A1A1A)),
                              ),
                            ],
                          ),
                        ),
                      ],
                      // Daily metrics mini chart (text-based sparkline)
                      if (_dashboard!.dailyMetrics.isNotEmpty) ...[
                        const SizedBox(height: 20),
                        Text('Views (30 days)',
                            style: const TextStyle(fontSize: 15, fontWeight: FontWeight.w600, color: Color(0xFF1A1A1A))),
                        const SizedBox(height: 12),
                        _buildMiniChart(),
                      ],
                    ],
                  ),
                ),
    );
  }

  Widget _buildStatsGrid(dynamic strings) {
    return Column(
      children: [
        Row(
          children: [
            Expanded(child: _buildStatTile('Views', _formatCount(_dashboard!.totalViews), Icons.visibility_outlined)),
            const SizedBox(width: 12),
            Expanded(child: _buildStatTile('Likes', _formatCount(_dashboard!.totalLikes), Icons.favorite_outline_rounded)),
          ],
        ),
        const SizedBox(height: 12),
        Row(
          children: [
            Expanded(child: _buildStatTile('Shares', _formatCount(_dashboard!.totalShares), Icons.share_rounded)),
            const SizedBox(width: 12),
            Expanded(child: _buildStatTile(strings?.postsThisMonth ?? 'Posts', '${_dashboard!.postsCount30d}', Icons.article_outlined)),
          ],
        ),
      ],
    );
  }

  Widget _buildStatTile(String label, String value, IconData icon) {
    return _buildCard(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(icon, size: 18, color: const Color(0xFF999999)),
          const SizedBox(height: 8),
          Text(value, style: const TextStyle(fontSize: 20, fontWeight: FontWeight.w700, color: Color(0xFF1A1A1A))),
          const SizedBox(height: 2),
          Text(label, style: const TextStyle(fontSize: 11, color: Color(0xFF999999))),
        ],
      ),
    );
  }

  Widget _buildInfoTile(String label, String value, IconData icon) {
    return _buildCard(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(icon, size: 18, color: const Color(0xFF999999)),
          const SizedBox(height: 8),
          Text(value, style: const TextStyle(fontSize: 15, fontWeight: FontWeight.w600, color: Color(0xFF1A1A1A))),
          const SizedBox(height: 2),
          Text(label, style: const TextStyle(fontSize: 11, color: Color(0xFF999999))),
        ],
      ),
    );
  }

  Widget _buildCard({required Widget child}) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: const Color(0xFFE0E0E0), width: 0.5),
      ),
      child: child,
    );
  }

  /// Simple bar chart using containers.
  Widget _buildMiniChart() {
    final metrics = _dashboard!.dailyMetrics;
    final maxViews = metrics.fold<int>(0, (max, m) => m.views > max ? m.views : max);
    if (maxViews == 0) return const SizedBox.shrink();
    return _buildCard(
      child: SizedBox(
        height: 80,
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.end,
          children: metrics.map((m) {
            final ratio = m.views / maxViews;
            return Expanded(
              child: Padding(
                padding: const EdgeInsets.symmetric(horizontal: 1),
                child: Container(
                  height: (ratio * 60).clamp(2, 60),
                  decoration: BoxDecoration(
                    color: const Color(0xFF1A1A1A).withValues(alpha: 0.2 + ratio * 0.8),
                    borderRadius: BorderRadius.circular(2),
                  ),
                ),
              ),
            );
          }).toList(),
        ),
      ),
    );
  }

  String _formatCount(int count) {
    if (count >= 1000000) return '${(count / 1000000).toStringAsFixed(1)}M';
    if (count >= 1000) return '${(count / 1000).toStringAsFixed(1)}K';
    return '$count';
  }
}
```

- [ ] **Step 2: Run analyze**
- [ ] **Step 3: Commit**

---

## Task 9: Battle Thread Screen

**Files:**
- Create: `lib/screens/feed/battle_thread_screen.dart`

- [ ] **Step 1: Create BattleThreadScreen**

Screen showing a creator battle with the topic, two sides, vote bars, and associated thread posts. Uses `BattleService.getBattle()` for battle data and `GossipService.getThread()` for the thread posts. Includes a vote button that calls `BattleService.vote()`. Layout: AppBar with topic, battle card (Side A vs Side B with animated vote bars), then thread posts below. Design: monochromatic, 16dp radius, 48dp touch targets.

```dart
import 'package:flutter/material.dart';
import '../../models/battle_models.dart';
import '../../models/gossip_models.dart';
import '../../services/battle_service.dart';
import '../../services/gossip_service.dart';
import '../../services/local_storage_service.dart';
import '../../widgets/post_card.dart';
import '../../l10n/app_strings_scope.dart';

class BattleThreadScreen extends StatefulWidget {
  final int battleId;
  final int currentUserId;

  const BattleThreadScreen({super.key, required this.battleId, required this.currentUserId});

  @override
  State<BattleThreadScreen> createState() => _BattleThreadScreenState();
}

class _BattleThreadScreenState extends State<BattleThreadScreen> {
  final BattleService _battleService = BattleService();
  final GossipService _gossipService = GossipService();
  CreatorBattle? _battle;
  GossipThreadDetail? _threadDetail;
  bool _loading = true;
  String? _error;
  bool _voting = false;

  @override
  void initState() {
    super.initState();
    _loadData();
  }

  Future<void> _loadData() async {
    setState(() { _loading = true; _error = null; });
    try {
      final storage = await LocalStorageService.getInstance();
      final token = storage.getAuthToken();
      if (token == null) {
        if (mounted) setState(() { _error = 'Not authenticated'; _loading = false; });
        return;
      }
      final battle = await _battleService.getBattle(token: token, battleId: widget.battleId);
      GossipThreadDetail? thread;
      if (battle?.threadId != null) {
        thread = await _gossipService.getThread(token: token, threadId: battle!.threadId!);
      }
      if (mounted) {
        setState(() {
          _battle = battle;
          _threadDetail = thread;
          _loading = false;
          if (battle == null) _error = 'Battle not found';
        });
      }
    } catch (e) {
      if (mounted) setState(() { _error = 'Error: $e'; _loading = false; });
    }
  }

  Future<void> _vote(String side) async {
    if (_voting || _battle == null) return;
    setState(() => _voting = true);
    final storage = await LocalStorageService.getInstance();
    final token = storage.getAuthToken();
    if (token == null) { setState(() => _voting = false); return; }
    final success = await _battleService.vote(token: token, battleId: _battle!.id, side: side);
    if (mounted) {
      setState(() => _voting = false);
      if (success) {
        _loadData(); // Refresh to get updated counts
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(AppStringsScope.of(context)?.voteCast ?? 'Vote cast!')),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final strings = AppStringsScope.of(context);
    return Scaffold(
      backgroundColor: const Color(0xFFFAFAFA),
      appBar: AppBar(
        backgroundColor: Colors.white,
        foregroundColor: const Color(0xFF1A1A1A),
        elevation: 0,
        title: Text(
          strings?.creatorBattles ?? 'Creator Battle',
          style: const TextStyle(fontSize: 18, fontWeight: FontWeight.w700),
        ),
      ),
      body: _loading
          ? const Center(child: CircularProgressIndicator(color: Color(0xFF1A1A1A)))
          : _error != null
              ? Center(child: Text(_error!, style: const TextStyle(color: Color(0xFF666666))))
              : RefreshIndicator(
                  onRefresh: _loadData,
                  color: const Color(0xFF1A1A1A),
                  child: ListView(
                    padding: const EdgeInsets.only(bottom: 32),
                    children: [
                      // Battle header
                      Padding(
                        padding: const EdgeInsets.all(16),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(_battle!.topic,
                                style: const TextStyle(fontSize: 20, fontWeight: FontWeight.w800, color: Color(0xFF1A1A1A))),
                            const SizedBox(height: 16),
                            // Vote section
                            Row(
                              children: [
                                Expanded(child: _buildVoteSide(
                                  name: _battle!.creatorAName ?? (strings?.sideA ?? 'Side A'),
                                  percent: _battle!.percentA,
                                  side: 'a',
                                  isSelected: _battle!.userVote == 'a',
                                )),
                                Padding(
                                  padding: const EdgeInsets.symmetric(horizontal: 12),
                                  child: Text(strings?.vs ?? 'vs',
                                      style: const TextStyle(fontSize: 16, fontWeight: FontWeight.w800, color: Color(0xFF999999))),
                                ),
                                Expanded(child: _buildVoteSide(
                                  name: _battle!.creatorBName ?? (strings?.sideB ?? 'Side B'),
                                  percent: _battle!.percentB,
                                  side: 'b',
                                  isSelected: _battle!.userVote == 'b',
                                )),
                              ],
                            ),
                            const SizedBox(height: 12),
                            // Progress bar
                            ClipRRect(
                              borderRadius: BorderRadius.circular(4),
                              child: Row(
                                children: [
                                  Expanded(
                                    flex: _battle!.percentA.round().clamp(1, 99),
                                    child: Container(height: 8, color: const Color(0xFF1A1A1A)),
                                  ),
                                  Expanded(
                                    flex: _battle!.percentB.round().clamp(1, 99),
                                    child: Container(height: 8, color: const Color(0xFFCCCCCC)),
                                  ),
                                ],
                              ),
                            ),
                            const SizedBox(height: 8),
                            Center(
                              child: Text('${_battle!.totalVotes} ${strings?.votes ?? "votes"}',
                                  style: const TextStyle(fontSize: 12, color: Color(0xFF999999))),
                            ),
                          ],
                        ),
                      ),
                      // Thread posts
                      if (_threadDetail != null)
                        ..._threadDetail!.posts.map((post) => PostCard(
                              key: ValueKey('battle_post_${post.id}'),
                              post: post,
                              currentUserId: widget.currentUserId,
                            )),
                    ],
                  ),
                ),
    );
  }

  Widget _buildVoteSide({
    required String name,
    required double percent,
    required String side,
    required bool isSelected,
  }) {
    final canVote = _battle!.userVote == null && _battle!.status == BattleStatus.open;
    return GestureDetector(
      onTap: canVote && !_voting ? () => _vote(side) : null,
      child: Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: isSelected ? const Color(0xFF1A1A1A) : Colors.white,
          borderRadius: BorderRadius.circular(16),
          border: Border.all(
            color: isSelected ? const Color(0xFF1A1A1A) : const Color(0xFFE0E0E0),
            width: isSelected ? 2 : 0.5,
          ),
        ),
        child: Column(
          children: [
            Text(name,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                textAlign: TextAlign.center,
                style: TextStyle(
                  fontSize: 14, fontWeight: FontWeight.w600,
                  color: isSelected ? Colors.white : const Color(0xFF1A1A1A),
                )),
            const SizedBox(height: 4),
            Text('${percent.toStringAsFixed(0)}%',
                style: TextStyle(
                  fontSize: 24, fontWeight: FontWeight.w800,
                  color: isSelected ? Colors.white : const Color(0xFF1A1A1A),
                )),
            if (canVote) ...[
              const SizedBox(height: 6),
              Text(AppStringsScope.of(context)?.castVote ?? 'Tap to vote',
                  style: TextStyle(
                    fontSize: 10,
                    color: isSelected ? Colors.white70 : const Color(0xFF999999),
                  )),
            ],
          ],
        ),
      ),
    );
  }
}
```

- [ ] **Step 2: Run analyze**
- [ ] **Step 3: Commit**

---

## Task 10: Creator Dashboard — Add Collaboration Radar + Analytics Link

**Files:**
- Modify: `lib/screens/profile/creator_dashboard_section.dart`

- [ ] **Step 1: Add collaboration suggestions and analytics link**

Import CollaborationService, CollaborationCard, and collaboration_models. Fetch collaboration suggestions alongside existing data. Add a horizontal scroll of CollaborationCards below the multiplier section. Add a "View Analytics" button next to the existing "Weekly Report" button.

Add imports:
```dart
import '../../services/collaboration_service.dart';
import '../../models/collaboration_models.dart';
import '../../widgets/collaboration_card.dart';
```

Add field: `List<CollaborationSuggestion> _collaborations = [];`

In `_loadData`, add to Future.wait:
```dart
CollaborationService().getSuggestions(token: token, creatorId: widget.userId),
```

After multiplier section, add collaboration section:
```dart
if (_collaborations.isNotEmpty) ...[
  const SizedBox(height: 12),
  Text(strings?.collaborationRadar ?? 'Collaboration Radar', ...),
  const SizedBox(height: 8),
  ..._collaborations.take(2).map((c) => CollaborationCard(
    suggestion: c,
    onAccept: () => _respondToCollab(c.id, 'accepted'),
    onDismiss: () => _respondToCollab(c.id, 'dismissed'),
  )),
],
```

Change button row to have two buttons:
```dart
Row(
  children: [
    Expanded(child: OutlinedButton(onPressed: () => Navigator.pushNamed(context, '/weekly-report/${widget.userId}'), ...)),
    const SizedBox(width: 8),
    Expanded(child: OutlinedButton(onPressed: () => Navigator.pushNamed(context, '/analytics/${widget.userId}'), ...)),
  ],
),
```

Add `_respondToCollab` method that calls `CollaborationService().respond()` and refreshes.

- [ ] **Step 2: Run analyze**
- [ ] **Step 3: Commit**

---

## Task 11: Settings — Creator Opt-out Toggles

**Files:**
- Modify: `lib/screens/settings/settings_screen.dart`

- [ ] **Step 1: Add Creator Settings section**

After the Account section and before Notifications, add a "Creator Settings" section with 4 toggles using the existing `_buildSwitchTile` pattern:

1. Opt out of sponsored posts
2. Opt out of collaboration suggestions
3. Opt out of creator battles
4. Don't include my posts in gossip threads

Store preferences in Hive via `LocalStorageService`. Add fields:
```dart
bool _optOutSponsored = false;
bool _optOutCollaboration = false;
bool _optOutBattles = false;
bool _optOutThreads = false;
```

Load from LocalStorageService in `_loadPreferences`. Save on toggle change.

The section should only show when viewing settings for a user who has created content (for now, always show — all users are potential creators).

- [ ] **Step 2: Run analyze**
- [ ] **Step 3: Commit**

---

## Task 12: Routes + FCM Updates

**Files:**
- Modify: `lib/main.dart`
- Modify: `lib/services/fcm_service.dart`

- [ ] **Step 1: Add routes to main.dart**

Add imports:
```dart
import 'screens/analytics/analytics_dashboard_screen.dart';
import 'screens/feed/battle_thread_screen.dart';
import 'screens/sponsored/sponsored_posts_screen.dart';
```

Add cases in onGenerateRoute switch:
```dart
case 'analytics':
  if (pathSegments.length > 1) {
    final userId = int.tryParse(pathSegments[1]) ?? 0;
    if (userId > 0) {
      return MaterialPageRoute(builder: (_) => AnalyticsDashboardScreen(userId: userId));
    }
  }
  break;

case 'battle':
  if (pathSegments.length > 1) {
    final battleId = int.tryParse(pathSegments[1]) ?? 0;
    if (battleId > 0) {
      return MaterialPageRoute(
        builder: (_) => FutureBuilder<int>(
          future: getCurrentUserId(),
          builder: (context, snapshot) {
            if (!snapshot.hasData) return const Center(child: CircularProgressIndicator());
            return BattleThreadScreen(battleId: battleId, currentUserId: snapshot.data!);
          },
        ),
      );
    }
  }
  break;

case 'sponsored-posts':
  return MaterialPageRoute(
    builder: (_) => FutureBuilder<int>(
      future: getCurrentUserId(),
      builder: (context, snapshot) {
        if (!snapshot.hasData) return const Center(child: CircularProgressIndicator());
        return SponsoredPostsScreen(currentUserId: snapshot.data!);
      },
    ),
  );
```

- [ ] **Step 2: Update FCM routing**

In `_handlePayload`, add:
```dart
if (type == 'battle_invitation') {
  _openBattle(data, navigator);
  return;
}
if (type == 'collaboration_suggestion') {
  _openProfile(data, navigator);
  return;
}
```

Add method:
```dart
void _openBattle(Map<String, dynamic> data, NavigatorState navigator) {
  final battleId = _intFrom(data, 'battle_id');
  if (battleId != null && battleId > 0 && navigator.mounted) {
    navigator.pushNamed('/battle/$battleId');
  }
}
```

- [ ] **Step 3: Run analyze**
- [ ] **Step 4: Commit**

---

## Task 13: Sponsored Posts Browse Screen

**Files:**
- Create: `lib/screens/sponsored/sponsored_posts_screen.dart`

- [ ] **Step 1: Create SponsoredPostsScreen**

A screen for businesses to browse Star/Legend creators available for sponsorship. Shows a list of `SponsorableCreator` cards with tier badge, follower count, engagement rate, and top category. Tap to view creator profile.

Pattern: same as other list screens — loading/error/list states, pull-to-refresh, monochromatic design.

```dart
import 'package:flutter/material.dart';
import '../../models/sponsored_post_models.dart';
import '../../services/sponsored_post_service.dart';
import '../../services/local_storage_service.dart';
import '../../widgets/creator_tier_badge.dart';
import '../../l10n/app_strings_scope.dart';

class SponsoredPostsScreen extends StatefulWidget {
  final int currentUserId;

  const SponsoredPostsScreen({super.key, required this.currentUserId});

  @override
  State<SponsoredPostsScreen> createState() => _SponsoredPostsScreenState();
}

class _SponsoredPostsScreenState extends State<SponsoredPostsScreen> {
  final SponsoredPostService _service = SponsoredPostService();
  List<SponsorableCreator> _creators = [];
  bool _loading = true;
  String? _error;

  @override
  void initState() {
    super.initState();
    _loadCreators();
  }

  Future<void> _loadCreators() async {
    setState(() { _loading = true; _error = null; });
    try {
      final storage = await LocalStorageService.getInstance();
      final token = storage.getAuthToken();
      if (token == null) {
        if (mounted) setState(() { _error = 'Not authenticated'; _loading = false; });
        return;
      }
      final creators = await _service.browseSponsorableCreators(token: token);
      if (mounted) {
        setState(() { _creators = creators; _loading = false; });
      }
    } catch (e) {
      if (mounted) setState(() { _error = 'Error: $e'; _loading = false; });
    }
  }

  @override
  Widget build(BuildContext context) {
    final strings = AppStringsScope.of(context);
    return Scaffold(
      backgroundColor: const Color(0xFFFAFAFA),
      appBar: AppBar(
        backgroundColor: Colors.white,
        foregroundColor: const Color(0xFF1A1A1A),
        elevation: 0,
        title: Text(
          strings?.browseSponsorableCreators ?? 'Browse Creators',
          style: const TextStyle(fontSize: 18, fontWeight: FontWeight.w700),
        ),
      ),
      body: _loading
          ? const Center(child: CircularProgressIndicator(color: Color(0xFF1A1A1A)))
          : _error != null
              ? Center(child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Text(_error!, style: const TextStyle(color: Color(0xFF666666))),
                    const SizedBox(height: 16),
                    TextButton(onPressed: _loadCreators, child: Text(strings?.retry ?? 'Retry')),
                  ],
                ))
              : RefreshIndicator(
                  onRefresh: _loadCreators,
                  color: const Color(0xFF1A1A1A),
                  child: _creators.isEmpty
                      ? ListView(children: [
                          const SizedBox(height: 100),
                          Center(child: Text(
                            strings?.starLegendOnly ?? 'Star & Legend only',
                            style: const TextStyle(color: Color(0xFF999999), fontSize: 14),
                          )),
                        ])
                      : ListView.builder(
                          padding: const EdgeInsets.all(16),
                          itemCount: _creators.length,
                          itemBuilder: (context, index) {
                            final creator = _creators[index];
                            return _buildCreatorCard(creator, strings);
                          },
                        ),
                ),
    );
  }

  Widget _buildCreatorCard(SponsorableCreator creator, dynamic strings) {
    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: const Color(0xFFE0E0E0), width: 0.5),
      ),
      child: InkWell(
        onTap: () => Navigator.pushNamed(context, '/profile/${creator.userId}'),
        child: Row(
          children: [
            CircleAvatar(
              radius: 24,
              backgroundColor: const Color(0xFFE0E0E0),
              backgroundImage: creator.avatarUrl != null ? NetworkImage(creator.avatarUrl!) : null,
              child: creator.avatarUrl == null
                  ? const Icon(Icons.person_rounded, size: 24, color: Color(0xFF999999))
                  : null,
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Flexible(
                        child: Text(creator.name, maxLines: 1, overflow: TextOverflow.ellipsis,
                            style: const TextStyle(fontSize: 15, fontWeight: FontWeight.w600, color: Color(0xFF1A1A1A))),
                      ),
                      const SizedBox(width: 6),
                      CreatorTierBadge(tier: creator.tier),
                    ],
                  ),
                  const SizedBox(height: 4),
                  Text(
                    '${_formatCount(creator.followerCount)} followers · ${creator.avgEngagementRate.toStringAsFixed(1)}% engagement · ${creator.topCategory}',
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: const TextStyle(fontSize: 12, color: Color(0xFF666666)),
                  ),
                ],
              ),
            ),
            const Icon(Icons.chevron_right_rounded, color: Color(0xFF999999)),
          ],
        ),
      ),
    );
  }

  String _formatCount(int count) {
    if (count >= 1000000) return '${(count / 1000000).toStringAsFixed(1)}M';
    if (count >= 1000) return '${(count / 1000).toStringAsFixed(1)}K';
    return '$count';
  }
}
```

- [ ] **Step 2: Run analyze**
- [ ] **Step 3: Commit**

---

## Task 14: Final Verification

- [ ] **Step 1: Run flutter analyze** — expect 0 errors, 0 warnings
- [ ] **Step 2: Run all tests** — expect all passing (including new model tests)
- [ ] **Step 3: Verify git log** — all commits present
- [ ] **Step 4: Ship gate checklist:**
  - [ ] Sponsored post models + service + badge on PostCard
  - [ ] SponsoredPostsScreen for browsing creators
  - [ ] Collaboration models + service + CollaborationCard in dashboard
  - [ ] Battle models + service + BattleThreadScreen
  - [ ] Analytics models + service + AnalyticsDashboardScreen
  - [ ] Intensity graduation backend (user_engagement_levels table + update command)
  - [ ] Creator Settings in settings screen (4 opt-out toggles)
  - [ ] Routes: `/analytics/:userId`, `/battle/:battleId`, `/sponsored-posts`
  - [ ] FCM: `battle_invitation`, `collaboration_suggestion` handled
  - [ ] All bilingual strings added
  - [ ] Backend: all Phase 4 tables, controllers, routes, scheduled commands
