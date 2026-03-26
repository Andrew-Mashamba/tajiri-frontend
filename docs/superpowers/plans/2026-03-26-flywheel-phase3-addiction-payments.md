# Flywheel Phase 3: Addiction Loops + Creator Payments — Implementation Plan

> **For agentic workers:** REQUIRED SUB-SKILL: Use superpowers:subagent-driven-development (recommended) or superpowers:executing-plans to implement this plan task-by-task. Steps use checkbox (`- [ ]`) syntax for tracking.

**Goal:** Complete the Flywheel loop — creators earn from engagement, viewers get hooked with streaks/digests/rabbit holes, notifications bring users back.

**Architecture:** Backend adds `creator_fund_pools`, `creator_fund_payouts`, `notification_templates` tables with monthly distribution job, multiplier calculation, digest push jobs, and weekly report endpoint. Frontend adds streak indicators, tier badges, milestone overlays, creator dashboard, digest screen, weekly report screen, and rabbit hole mechanics (teaser cards, depth milestones).

**Tech Stack:** Flutter/Dart, http package, existing PostCard/FeedService/CreatorService patterns, AppStrings bilingual, Material 3 monochromatic design system, FCM push notifications

**Spec:** `docs/superpowers/specs/2026-03-26-tajiri-flywheel-growth-engine-design.md` (Sections 4, 6, 7, 8 — Phase 3)

---

## File Structure

### New Files (Create)

| File | Responsibility |
|------|---------------|
| `lib/widgets/streak_indicator.dart` | Flame icon + day count badge. Used on profile and creator stats. Shows viewer or creator streak. |
| `lib/widgets/creator_tier_badge.dart` | Rising/Established/Star/Legend tier badge. Monochromatic with tier label. |
| `lib/widgets/milestone_overlay.dart` | Full-screen animated celebration overlay for follower milestones (100, 500, 1K, etc.). |
| `lib/widgets/teaser_card.dart` | "Someone you follow just went viral" curiosity gap card injected in feed every 8-12 posts. |
| `lib/screens/feed/digest_screen.dart` | Morning/evening digest: proverb, top threads, unfinished threads. Opened from push notification. |
| `lib/screens/profile/weekly_report_screen.dart` | Creator weekly summary: earnings, best post, trend arrows, follower change. |
| `lib/screens/profile/creator_dashboard_section.dart` | Reusable widget: tier badge, streak, multiplier breakdown, fund pool projection. Embedded in ProfileScreen. |
| `lib/models/payment_models.dart` | CreatorFundPool, CreatorFundPayout, WeeklyReport, NotificationTemplate models. |
| `lib/services/payment_service.dart` | Instance-based. getWeeklyReport(), getFundPool(), requestPayout(). |
| `test/models/payment_models_test.dart` | Unit tests for payment models. |
| `test/services/payment_service_test.dart` | Unit test for PaymentService instantiation. |

### Modified Files

| File | Change |
|------|--------|
| `lib/main.dart` | Add routes `/digest`, `/weekly-report/:userId`. |
| `lib/screens/profile/profile_screen.dart` | Embed CreatorDashboardSection below profile info when viewing own profile. |
| `lib/screens/feed/feed_screen.dart` | Inject teaser cards every 8-12 posts. Add depth milestone logic. |
| `lib/screens/feed/full_screen_post_viewer_screen.dart` | Add autoplay countdown overlay after 3+ posts. |
| `lib/services/fcm_service.dart` | Route `digest` → `/digest`, `weekly_report` → `/weekly-report/:userId`, `milestone` → show MilestoneOverlay. |
| `lib/l10n/app_strings.dart` | Add ~30 addiction/payment bilingual strings. |
| `lib/services/creator_service.dart` | Add `getWeeklyReport()` method. |

---

## Task 1: Backend — Payment Tables, Distribution Job, Notification Templates, Weekly Report

**Files:**
- Backend SSH: migrations, models, controller, commands, routes, seeder

- [ ] **Step 1: Create payment tables migration**

SSH to `root@zima-uat.site`, create migration for:
- `creator_fund_pools`: id, total_amount (decimal 12,2), currency (default 'TZS'), month (string YYYY-MM, unique), min_followers (int default 0), min_posts (int default 1), min_views (int default 0), is_distributed (bool default false), distributed_at (datetime nullable), timestamps
- `creator_fund_payouts`: id, pool_id (FK), user_id (FK, indexed), base_score (decimal 12,4), tier_multiplier (decimal 4,2), streak_multiplier (decimal 4,2), community_multiplier (decimal 4,2), virality_multiplier (decimal 4,2), effective_multiplier (decimal 6,2), final_score (decimal 14,4), payout_amount (decimal 12,2), payout_currency (default 'TZS'), status (pending/processing/completed/failed, default pending), paid_at (datetime nullable), timestamps. Index on (pool_id, user_id unique).
- `notification_templates`: id, key (string unique), template_en, template_sw, slots (json), category (digest/fomo/streak/milestone/report), max_per_day (int default 3), priority (int default 5), is_active (bool default true), timestamps

- [ ] **Step 2: Run migration**

- [ ] **Step 3: Create models (GossipThread pattern)**

Create `CreatorFundPool.php`, `CreatorFundPayout.php`, `NotificationTemplate.php` Eloquent models.

- [ ] **Step 4: Seed notification templates (~20 bilingual templates)**

Categories: digest (morning/evening), fomo (thread trending, post viral), streak (warning, frozen, resumed), milestone (followers), report (weekly).

- [ ] **Step 5: Create PaymentController with endpoints**

- `GET /api/creators/{id}/weekly-report` — earnings this week, best post, engagement trend, follower change, gossip threads triggered. Returns structured JSON.
- `GET /api/fund-pool/current` — current month's fund pool info (total, distributed flag, creator's projected share).
- `POST /api/creators/{id}/payout/request` — request mobile money payout (placeholder — returns success with message).

- [ ] **Step 6: Create DistributeCreatorFund command**

Monthly (1st of month) job:
1. Get or create fund pool for current month
2. Calculate each qualifying creator's final_score = base_score × tier_mult × streak_mult × community_mult × virality_mult (cap at 15x)
3. Distribute proportionally: payout = (final_score / total_final_scores) × pool_amount
4. Create CreatorFundPayout records
5. Mark pool as distributed

- [ ] **Step 7: Add routes and schedule**

Routes under auth:sanctum middleware. Schedule: `fund:distribute` monthly on 1st at 00:00.

- [ ] **Step 8: Verify routes and test command**

- [ ] **Step 9: Commit backend**

---

## Task 2: Payment Models (Flutter)

**Files:**
- Create: `lib/models/payment_models.dart`
- Create: `test/models/payment_models_test.dart`

- [ ] **Step 1: Write the failing test**

```dart
import 'package:flutter_test/flutter_test.dart';
import 'package:tajiri/models/payment_models.dart';

void main() {
  group('CreatorFundPool', () {
    test('fromJson parses correctly', () {
      final pool = CreatorFundPool.fromJson({
        'id': 1,
        'total_amount': 10000000.0,
        'currency': 'TZS',
        'month': '2026-03',
        'is_distributed': false,
      });
      expect(pool.id, 1);
      expect(pool.totalAmount, 10000000.0);
      expect(pool.currency, 'TZS');
      expect(pool.month, '2026-03');
      expect(pool.isDistributed, false);
    });
  });

  group('CreatorFundPayout', () {
    test('fromJson parses all multipliers', () {
      final payout = CreatorFundPayout.fromJson({
        'id': 1,
        'user_id': 42,
        'base_score': 500.0,
        'tier_multiplier': 2.0,
        'streak_multiplier': 1.25,
        'community_multiplier': 1.5,
        'virality_multiplier': 3.0,
        'effective_multiplier': 11.25,
        'final_score': 5625.0,
        'payout_amount': 500000.0,
        'payout_currency': 'TZS',
        'status': 'completed',
      });
      expect(payout.userId, 42);
      expect(payout.baseScore, 500.0);
      expect(payout.effectiveMultiplier, 11.25);
      expect(payout.payoutAmount, 500000.0);
      expect(payout.status, 'completed');
    });
  });

  group('WeeklyReport', () {
    test('fromJson parses report data', () {
      final report = WeeklyReport.fromJson({
        'total_earnings': 45000.0,
        'earnings_change_percent': 12.5,
        'best_post_id': 123,
        'best_post_likes': 340,
        'engagement_trend': 'up',
        'follower_change': 45,
        'threads_triggered': 2,
        'total_views': 8500,
        'total_likes': 620,
        'week_start': '2026-03-16',
        'week_end': '2026-03-22',
      });
      expect(report.totalEarnings, 45000.0);
      expect(report.earningsChangePercent, 12.5);
      expect(report.engagementTrend, 'up');
      expect(report.followerChange, 45);
      expect(report.threadsTriggered, 2);
    });
  });
}
```

- [ ] **Step 2: Run test to verify it fails**

- [ ] **Step 3: Write the models**

```dart
// Payment and earnings models for the Flywheel creator incentive system.

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

bool _parseBool(dynamic value, [bool defaultValue = false]) {
  if (value == null) return defaultValue;
  if (value is bool) return value;
  if (value is int) return value != 0;
  if (value is String) return value.toLowerCase() == 'true' || value == '1';
  return defaultValue;
}

class CreatorFundPool {
  final int id;
  final double totalAmount;
  final String currency;
  final String month;
  final bool isDistributed;
  final DateTime? distributedAt;

  CreatorFundPool({
    required this.id,
    required this.totalAmount,
    required this.currency,
    required this.month,
    required this.isDistributed,
    this.distributedAt,
  });

  factory CreatorFundPool.fromJson(Map<String, dynamic> json) {
    return CreatorFundPool(
      id: _parseInt(json['id']),
      totalAmount: _parseDouble(json['total_amount']),
      currency: (json['currency'] as String?) ?? 'TZS',
      month: (json['month'] as String?) ?? '',
      isDistributed: _parseBool(json['is_distributed']),
      distributedAt: json['distributed_at'] != null
          ? DateTime.tryParse(json['distributed_at'].toString())
          : null,
    );
  }
}

class CreatorFundPayout {
  final int id;
  final int userId;
  final double baseScore;
  final double tierMultiplier;
  final double streakMultiplier;
  final double communityMultiplier;
  final double viralityMultiplier;
  final double effectiveMultiplier;
  final double finalScore;
  final double payoutAmount;
  final String payoutCurrency;
  final String status;
  final DateTime? paidAt;

  CreatorFundPayout({
    required this.id,
    required this.userId,
    required this.baseScore,
    required this.tierMultiplier,
    required this.streakMultiplier,
    required this.communityMultiplier,
    required this.viralityMultiplier,
    required this.effectiveMultiplier,
    required this.finalScore,
    required this.payoutAmount,
    required this.payoutCurrency,
    required this.status,
    this.paidAt,
  });

  factory CreatorFundPayout.fromJson(Map<String, dynamic> json) {
    return CreatorFundPayout(
      id: _parseInt(json['id']),
      userId: _parseInt(json['user_id']),
      baseScore: _parseDouble(json['base_score']),
      tierMultiplier: _parseDouble(json['tier_multiplier'], 1.0),
      streakMultiplier: _parseDouble(json['streak_multiplier'], 1.0),
      communityMultiplier: _parseDouble(json['community_multiplier'], 1.0),
      viralityMultiplier: _parseDouble(json['virality_multiplier'], 1.0),
      effectiveMultiplier: _parseDouble(json['effective_multiplier'], 1.0),
      finalScore: _parseDouble(json['final_score']),
      payoutAmount: _parseDouble(json['payout_amount']),
      payoutCurrency: (json['payout_currency'] as String?) ?? 'TZS',
      status: (json['status'] as String?) ?? 'pending',
      paidAt: json['paid_at'] != null
          ? DateTime.tryParse(json['paid_at'].toString())
          : null,
    );
  }
}

class WeeklyReport {
  final double totalEarnings;
  final double earningsChangePercent;
  final int bestPostId;
  final int bestPostLikes;
  final String engagementTrend;
  final int followerChange;
  final int threadsTriggered;
  final int totalViews;
  final int totalLikes;
  final String weekStart;
  final String weekEnd;

  WeeklyReport({
    required this.totalEarnings,
    required this.earningsChangePercent,
    required this.bestPostId,
    required this.bestPostLikes,
    required this.engagementTrend,
    required this.followerChange,
    required this.threadsTriggered,
    required this.totalViews,
    required this.totalLikes,
    required this.weekStart,
    required this.weekEnd,
  });

  factory WeeklyReport.fromJson(Map<String, dynamic> json) {
    return WeeklyReport(
      totalEarnings: _parseDouble(json['total_earnings']),
      earningsChangePercent: _parseDouble(json['earnings_change_percent']),
      bestPostId: _parseInt(json['best_post_id']),
      bestPostLikes: _parseInt(json['best_post_likes']),
      engagementTrend: (json['engagement_trend'] as String?) ?? 'stable',
      followerChange: _parseInt(json['follower_change']),
      threadsTriggered: _parseInt(json['threads_triggered']),
      totalViews: _parseInt(json['total_views']),
      totalLikes: _parseInt(json['total_likes']),
      weekStart: (json['week_start'] as String?) ?? '',
      weekEnd: (json['week_end'] as String?) ?? '',
    );
  }
}
```

- [ ] **Step 4: Run test to verify it passes**
- [ ] **Step 5: Commit**

---

## Task 3: Payment Service + Weekly Report in CreatorService

**Files:**
- Create: `lib/services/payment_service.dart`
- Create: `test/services/payment_service_test.dart`
- Modify: `lib/services/creator_service.dart`

- [ ] **Step 1: Write test for PaymentService**

```dart
import 'package:flutter_test/flutter_test.dart';
import 'package:tajiri/services/payment_service.dart';

void main() {
  group('PaymentService', () {
    test('instance can be created', () {
      final service = PaymentService();
      expect(service, isNotNull);
    });
  });
}
```

- [ ] **Step 2: Create PaymentService**

```dart
import 'dart:convert';
import 'package:flutter/foundation.dart';
import 'package:http/http.dart' as http;
import '../config/api_config.dart';
import '../models/payment_models.dart';

String get _baseUrl => ApiConfig.baseUrl;

class PaymentService {
  Future<CreatorFundPool?> getCurrentPool({required String token}) async {
    try {
      final response = await http.get(
        Uri.parse('$_baseUrl/fund-pool/current'),
        headers: ApiConfig.authHeaders(token),
      );
      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        if (data['data'] is Map<String, dynamic>) {
          return CreatorFundPool.fromJson(data['data']);
        }
      }
      return null;
    } catch (e) {
      debugPrint('[PaymentService] getCurrentPool error: $e');
      return null;
    }
  }

  Future<List<CreatorFundPayout>> getPayoutHistory({
    required String token,
    required int creatorId,
  }) async {
    try {
      final response = await http.get(
        Uri.parse('$_baseUrl/creators/$creatorId/payouts'),
        headers: ApiConfig.authHeaders(token),
      );
      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        final rawList = data['data'] is List ? data['data'] as List : [];
        return rawList
            .whereType<Map<String, dynamic>>()
            .map((e) => CreatorFundPayout.fromJson(e))
            .toList();
      }
      return [];
    } catch (e) {
      debugPrint('[PaymentService] getPayoutHistory error: $e');
      return [];
    }
  }

  Future<bool> requestPayout({
    required String token,
    required int creatorId,
  }) async {
    try {
      final response = await http.post(
        Uri.parse('$_baseUrl/creators/$creatorId/payout/request'),
        headers: ApiConfig.authHeaders(token),
      );
      return response.statusCode == 200;
    } catch (e) {
      debugPrint('[PaymentService] requestPayout error: $e');
      return false;
    }
  }
}
```

- [ ] **Step 3: Add getWeeklyReport to CreatorService**

Add method to existing `lib/services/creator_service.dart`:

```dart
Future<WeeklyReport?> getWeeklyReport(int creatorId, String token) async {
  try {
    final response = await http.get(
      Uri.parse('$_baseUrl/creators/$creatorId/weekly-report'),
      headers: ApiConfig.authHeaders(token),
    );
    if (response.statusCode == 200) {
      final body = jsonDecode(response.body);
      final data = body['data'] ?? body;
      if (data is Map<String, dynamic>) {
        return WeeklyReport.fromJson(data);
      }
    }
    return null;
  } catch (e) {
    debugPrint('[CreatorService] getWeeklyReport error: $e');
    return null;
  }
}
```

Import `payment_models.dart` at top of creator_service.dart.

- [ ] **Step 4: Run tests**
- [ ] **Step 5: Commit**

---

## Task 4: Bilingual Strings for Addiction + Payments

**Files:**
- Modify: `lib/l10n/app_strings.dart`

- [ ] **Step 1: Add strings section**

Add `// ——— Creator Payments & Addiction ———` section:

```dart
  // ——— Creator Payments & Addiction ———
  String get creatorDashboard => isSwahili ? 'Dashibodi ya Muundaji' : 'Creator Dashboard';
  String get earnings => isSwahili ? 'Mapato' : 'Earnings';
  String get thisWeek => isSwahili ? 'Wiki Hii' : 'This Week';
  String get thisMonth => isSwahili ? 'Mwezi Huu' : 'This Month';
  String get weeklyReport => isSwahili ? 'Ripoti ya Wiki' : 'Weekly Report';
  String get totalEarnings => isSwahili ? 'Jumla ya Mapato' : 'Total Earnings';
  String get bestPost => isSwahili ? 'Chapisho Bora' : 'Best Post';
  String get engagementTrend => isSwahili ? 'Mwenendo wa Ushiriki' : 'Engagement Trend';
  String get followerChange => isSwahili ? 'Mabadiliko ya Wafuasi' : 'Follower Change';
  String get threadsTriggered => isSwahili ? 'Mada Zilizoanzishwa' : 'Threads Triggered';
  String get fundPool => isSwahili ? 'Mfuko wa Waundaji' : 'Creator Fund';
  String get projectedPayout => isSwahili ? 'Malipo Yanayotarajiwa' : 'Projected Payout';
  String get requestPayout => isSwahili ? 'Omba Malipo' : 'Request Payout';
  String get payoutRequested => isSwahili ? 'Ombi la malipo limetumwa' : 'Payout request submitted';
  String get tierRising => isSwahili ? 'Anayeinuka' : 'Rising';
  String get tierEstablished => isSwahili ? 'Imara' : 'Established';
  String get tierStar => isSwahili ? 'Nyota' : 'Star';
  String get tierLegend => isSwahili ? 'Hadithi' : 'Legend';
  String get streakDays => isSwahili ? 'siku mfululizo' : 'day streak';
  String get postingStreak => isSwahili ? 'Mfululizo wa Kuchapisha' : 'Posting Streak';
  String get viewingStreak => isSwahili ? 'Mfululizo wa Kutazama' : 'Viewing Streak';
  String get streakFrozen => isSwahili ? 'Mfululizo umegandishwa' : 'Streak frozen';
  String get multipliers => isSwahili ? 'Vizidishi' : 'Multipliers';
  String get tierMultiplier => isSwahili ? 'Kizidishi cha Ngazi' : 'Tier Multiplier';
  String get streakMultiplier => isSwahili ? 'Kizidishi cha Mfululizo' : 'Streak Multiplier';
  String get digest => isSwahili ? 'Muhtasari' : 'Digest';
  String get goodMorning => isSwahili ? 'Asubuhi Njema!' : 'Good Morning!';
  String get goodEvening => isSwahili ? 'Usiku Mwema!' : 'Good Evening!';
  String get topThreadsToday => isSwahili ? 'Mada Kuu za Leo' : 'Top Threads Today';
  String get milestone => isSwahili ? 'Hatua Muhimu!' : 'Milestone!';
  String get followersReached => isSwahili ? 'wafuasi umefika!' : 'followers reached!';
  String get keepGoing => isSwahili ? 'Endelea hivyo!' : 'Keep going!';
  String get trendUp => isSwahili ? 'Inaongezeka' : 'Trending Up';
  String get trendDown => isSwahili ? 'Inapungua' : 'Trending Down';
  String get trendStable => isSwahili ? 'Imara' : 'Stable';
  String get viralAlert => isSwahili ? 'Chapisho kinachoenea!' : 'Post going viral!';
  String get viralPostAlert => isSwahili ? 'Chapisho kinachoenea sasa!' : 'A post is going viral right now!';
```

- [ ] **Step 2: Run analyze**
- [ ] **Step 3: Commit**

---

## Task 5: StreakIndicator + CreatorTierBadge Widgets

**Files:**
- Create: `lib/widgets/streak_indicator.dart`
- Create: `lib/widgets/creator_tier_badge.dart`

- [ ] **Step 1: Create StreakIndicator**

Flame icon with day count. Small, inline widget.

```dart
import 'package:flutter/material.dart';

class StreakIndicator extends StatelessWidget {
  final int days;
  final bool isFrozen;
  final double size;

  const StreakIndicator({
    super.key,
    required this.days,
    this.isFrozen = false,
    this.size = 14,
  });

  @override
  Widget build(BuildContext context) {
    if (days <= 0) return const SizedBox.shrink();
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Icon(
          Icons.local_fire_department_rounded,
          size: size,
          color: isFrozen ? const Color(0xFF999999) : const Color(0xFF1A1A1A),
        ),
        const SizedBox(width: 3),
        Text(
          '$days',
          style: TextStyle(
            fontSize: size - 2,
            fontWeight: FontWeight.w700,
            color: isFrozen ? const Color(0xFF999999) : const Color(0xFF1A1A1A),
          ),
        ),
      ],
    );
  }
}
```

- [ ] **Step 2: Create CreatorTierBadge**

```dart
import 'package:flutter/material.dart';
import '../l10n/app_strings.dart';
import '../l10n/app_strings_scope.dart';

class CreatorTierBadge extends StatelessWidget {
  final String tier;
  final double? multiplier;

  const CreatorTierBadge({
    super.key,
    required this.tier,
    this.multiplier,
  });

  @override
  Widget build(BuildContext context) {
    final strings = AppStringsScope.of(context);
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
      decoration: BoxDecoration(
        color: _tierColor,
        borderRadius: BorderRadius.circular(12),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Text(
            _tierLabel(strings),
            style: const TextStyle(
              color: Colors.white,
              fontSize: 11,
              fontWeight: FontWeight.w700,
            ),
          ),
          if (multiplier != null) ...[
            const SizedBox(width: 4),
            Text(
              '${multiplier!.toStringAsFixed(1)}x',
              style: const TextStyle(
                color: Colors.white70,
                fontSize: 10,
                fontWeight: FontWeight.w600,
              ),
            ),
          ],
        ],
      ),
    );
  }

  Color get _tierColor {
    switch (tier.toLowerCase()) {
      case 'legend': return const Color(0xFF1A1A1A);
      case 'star': return const Color(0xFF333333);
      case 'established': return const Color(0xFF555555);
      default: return const Color(0xFF888888);
    }
  }

  String _tierLabel(AppStrings? strings) {
    switch (tier.toLowerCase()) {
      case 'legend': return strings?.tierLegend ?? 'Legend';
      case 'star': return strings?.tierStar ?? 'Star';
      case 'established': return strings?.tierEstablished ?? 'Established';
      default: return strings?.tierRising ?? 'Rising';
    }
  }
}
```

- [ ] **Step 3: Run analyze**
- [ ] **Step 4: Commit**

---

## Task 6: MilestoneOverlay Widget

**Files:**
- Create: `lib/widgets/milestone_overlay.dart`

- [ ] **Step 1: Create MilestoneOverlay**

Full-screen overlay with animated celebration. Shows milestone text (e.g. "10K followers reached!"). Auto-dismisses after 4 seconds or on tap.

```dart
import 'package:flutter/material.dart';
import '../l10n/app_strings_scope.dart';

class MilestoneOverlay extends StatefulWidget {
  final String milestone;
  final VoidCallback? onDismiss;

  const MilestoneOverlay({
    super.key,
    required this.milestone,
    this.onDismiss,
  });

  static void show(BuildContext context, {required String milestone}) {
    final overlay = Overlay.of(context);
    late OverlayEntry entry;
    entry = OverlayEntry(
      builder: (_) => MilestoneOverlay(
        milestone: milestone,
        onDismiss: () => entry.remove(),
      ),
    );
    overlay.insert(entry);
  }

  @override
  State<MilestoneOverlay> createState() => _MilestoneOverlayState();
}

class _MilestoneOverlayState extends State<MilestoneOverlay>
    with SingleTickerProviderStateMixin {
  late AnimationController _controller;
  late Animation<double> _scaleAnim;
  late Animation<double> _fadeAnim;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 600),
    );
    _scaleAnim = CurvedAnimation(parent: _controller, curve: Curves.elasticOut);
    _fadeAnim = CurvedAnimation(parent: _controller, curve: Curves.easeIn);
    _controller.forward();
    Future.delayed(const Duration(seconds: 4), () {
      if (mounted) _dismiss();
    });
  }

  void _dismiss() {
    _controller.reverse().then((_) => widget.onDismiss?.call());
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final strings = AppStringsScope.of(context);
    return GestureDetector(
      onTap: _dismiss,
      child: FadeTransition(
        opacity: _fadeAnim,
        child: Container(
          color: const Color(0xCC1A1A1A),
          child: Center(
            child: ScaleTransition(
              scale: _scaleAnim,
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  const Icon(Icons.emoji_events_rounded, size: 64, color: Colors.white),
                  const SizedBox(height: 16),
                  Text(
                    strings?.milestone ?? 'Milestone!',
                    style: const TextStyle(
                      color: Colors.white,
                      fontSize: 28,
                      fontWeight: FontWeight.w800,
                      decoration: TextDecoration.none,
                    ),
                  ),
                  const SizedBox(height: 8),
                  Text(
                    widget.milestone,
                    textAlign: TextAlign.center,
                    style: const TextStyle(
                      color: Colors.white70,
                      fontSize: 18,
                      fontWeight: FontWeight.w500,
                      decoration: TextDecoration.none,
                    ),
                  ),
                  const SizedBox(height: 24),
                  Text(
                    strings?.keepGoing ?? 'Keep going!',
                    style: const TextStyle(
                      color: Colors.white54,
                      fontSize: 14,
                      decoration: TextDecoration.none,
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}
```

- [ ] **Step 2: Run analyze**
- [ ] **Step 3: Commit**

---

## Task 7: TeaserCard Widget

**Files:**
- Create: `lib/widgets/teaser_card.dart`

- [ ] **Step 1: Create TeaserCard**

Curiosity-gap card injected in feed. "Someone you follow just posted something going viral" style.

```dart
import 'package:flutter/material.dart';
import '../l10n/app_strings_scope.dart';

class TeaserCard extends StatelessWidget {
  final String text;
  final int? viewerCount;
  final VoidCallback? onTap;

  const TeaserCard({
    super.key,
    required this.text,
    this.viewerCount,
    this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 6),
      child: Material(
        color: const Color(0xFF1A1A1A),
        borderRadius: BorderRadius.circular(16),
        child: InkWell(
          onTap: onTap,
          borderRadius: BorderRadius.circular(16),
          child: Padding(
            padding: const EdgeInsets.all(20),
            child: Row(
              children: [
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        text,
                        maxLines: 2,
                        overflow: TextOverflow.ellipsis,
                        style: const TextStyle(
                          color: Colors.white,
                          fontSize: 15,
                          fontWeight: FontWeight.w600,
                          height: 1.3,
                        ),
                      ),
                      if (viewerCount != null) ...[
                        const SizedBox(height: 6),
                        Text(
                          '$viewerCount ${AppStringsScope.of(context)?.peopleTalking ?? "people talking"}',
                          style: const TextStyle(
                            color: Colors.white54,
                            fontSize: 12,
                          ),
                        ),
                      ],
                    ],
                  ),
                ),
                const SizedBox(width: 12),
                const Icon(Icons.chevron_right_rounded, color: Colors.white54, size: 24),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
```

- [ ] **Step 2: Run analyze**
- [ ] **Step 3: Commit**

---

## Task 8: DigestScreen

**Files:**
- Create: `lib/screens/feed/digest_screen.dart`

- [ ] **Step 1: Create DigestScreen**

```dart
import 'package:flutter/material.dart';
import '../../models/gossip_models.dart';
import '../../services/gossip_service.dart';
import '../../services/local_storage_service.dart';
import '../../widgets/gossip_thread_card.dart';
import '../../l10n/app_strings_scope.dart';

class DigestScreen extends StatefulWidget {
  final int currentUserId;

  const DigestScreen({super.key, required this.currentUserId});

  @override
  State<DigestScreen> createState() => _DigestScreenState();
}

class _DigestScreenState extends State<DigestScreen> {
  final GossipService _gossipService = GossipService();
  DigestResponse? _digest;
  bool _loading = true;
  String? _error;

  @override
  void initState() {
    super.initState();
    _loadDigest();
  }

  bool get _isMorning {
    final hour = DateTime.now().hour;
    return hour >= 5 && hour < 17;
  }

  Future<void> _loadDigest() async {
    setState(() { _loading = true; _error = null; });
    try {
      final storage = await LocalStorageService.getInstance();
      final token = storage.getAuthToken();
      if (token == null) {
        if (mounted) setState(() { _error = 'Not authenticated'; _loading = false; });
        return;
      }
      final digest = await _gossipService.getDigest(token: token);
      if (mounted) {
        setState(() {
          _digest = digest;
          _loading = false;
          if (digest == null) _error = 'Could not load digest';
        });
      }
    } catch (e) {
      if (mounted) setState(() { _error = 'Error: $e'; _loading = false; });
    }
  }

  @override
  Widget build(BuildContext context) {
    final strings = AppStringsScope.of(context);
    final isSwahili = strings?.isSwahili ?? false;

    return Scaffold(
      backgroundColor: const Color(0xFFFAFAFA),
      appBar: AppBar(
        backgroundColor: Colors.white,
        foregroundColor: const Color(0xFF1A1A1A),
        elevation: 0,
        title: Text(
          strings?.digest ?? 'Digest',
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
                      TextButton(onPressed: _loadDigest, child: Text(strings?.retry ?? 'Retry')),
                    ],
                  ),
                )
              : RefreshIndicator(
                  onRefresh: _loadDigest,
                  color: const Color(0xFF1A1A1A),
                  child: ListView(
                    padding: const EdgeInsets.only(bottom: 32),
                    children: [
                      // Greeting
                      Padding(
                        padding: const EdgeInsets.fromLTRB(16, 20, 16, 8),
                        child: Text(
                          _isMorning
                              ? (strings?.goodMorning ?? 'Good Morning!')
                              : (strings?.goodEvening ?? 'Good Evening!'),
                          style: const TextStyle(
                            fontSize: 24,
                            fontWeight: FontWeight.w800,
                            color: Color(0xFF1A1A1A),
                          ),
                        ),
                      ),
                      // Proverb card
                      if (_digest?.proverbEn != null || _digest?.proverbSw != null)
                        Padding(
                          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                          child: Container(
                            padding: const EdgeInsets.all(16),
                            decoration: BoxDecoration(
                              color: const Color(0xFF1A1A1A),
                              borderRadius: BorderRadius.circular(16),
                            ),
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  strings?.proverbOfTheDay ?? 'Proverb of the Day',
                                  style: const TextStyle(color: Colors.white54, fontSize: 12, fontWeight: FontWeight.w600),
                                ),
                                const SizedBox(height: 8),
                                Text(
                                  _digest!.proverb(isSwahili: isSwahili),
                                  style: const TextStyle(color: Colors.white, fontSize: 16, fontWeight: FontWeight.w600, height: 1.4),
                                ),
                              ],
                            ),
                          ),
                        ),
                      // Top threads header
                      Padding(
                        padding: const EdgeInsets.fromLTRB(16, 16, 16, 8),
                        child: Text(
                          strings?.topThreadsToday ?? 'Top Threads Today',
                          style: const TextStyle(fontSize: 15, fontWeight: FontWeight.w600, color: Color(0xFF1A1A1A)),
                        ),
                      ),
                      // Thread cards
                      if (_digest != null && _digest!.threads.isEmpty)
                        Padding(
                          padding: const EdgeInsets.symmetric(vertical: 24),
                          child: Center(
                            child: Text(
                              strings?.noThreadsYet ?? 'No threads yet',
                              style: const TextStyle(color: Color(0xFF999999), fontSize: 13),
                            ),
                          ),
                        )
                      else if (_digest != null)
                        ..._digest!.threads.map((thread) => GossipThreadCard(
                              key: ValueKey('digest_thread_${thread.id}'),
                              thread: thread,
                              onTap: () => Navigator.pushNamed(context, '/thread/${thread.id}'),
                            )),
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

## Task 9: WeeklyReportScreen

**Files:**
- Create: `lib/screens/profile/weekly_report_screen.dart`

- [ ] **Step 1: Create WeeklyReportScreen**

```dart
import 'package:flutter/material.dart';
import '../../models/payment_models.dart';
import '../../services/creator_service.dart';
import '../../services/local_storage_service.dart';
import '../../l10n/app_strings_scope.dart';

class WeeklyReportScreen extends StatefulWidget {
  final int userId;

  const WeeklyReportScreen({super.key, required this.userId});

  @override
  State<WeeklyReportScreen> createState() => _WeeklyReportScreenState();
}

class _WeeklyReportScreenState extends State<WeeklyReportScreen> {
  final CreatorService _creatorService = CreatorService();
  WeeklyReport? _report;
  bool _loading = true;
  String? _error;

  @override
  void initState() {
    super.initState();
    _loadReport();
  }

  Future<void> _loadReport() async {
    setState(() { _loading = true; _error = null; });
    try {
      final storage = await LocalStorageService.getInstance();
      final token = storage.getAuthToken();
      if (token == null) {
        if (mounted) setState(() { _error = 'Not authenticated'; _loading = false; });
        return;
      }
      final report = await _creatorService.getWeeklyReport(widget.userId, token);
      if (mounted) {
        setState(() {
          _report = report;
          _loading = false;
          if (report == null) _error = 'No report available';
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
          strings?.weeklyReport ?? 'Weekly Report',
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
                      TextButton(onPressed: _loadReport, child: Text(strings?.retry ?? 'Retry')),
                    ],
                  ),
                )
              : RefreshIndicator(
                  onRefresh: _loadReport,
                  color: const Color(0xFF1A1A1A),
                  child: ListView(
                    padding: const EdgeInsets.all(16),
                    children: [
                      // Week range
                      Text(
                        '${_report!.weekStart} — ${_report!.weekEnd}',
                        style: const TextStyle(color: Color(0xFF999999), fontSize: 13),
                      ),
                      const SizedBox(height: 16),
                      // Earnings card
                      _buildCard(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(strings?.totalEarnings ?? 'Total Earnings',
                                style: const TextStyle(color: Color(0xFF666666), fontSize: 13)),
                            const SizedBox(height: 8),
                            Row(
                              crossAxisAlignment: CrossAxisAlignment.end,
                              children: [
                                Text(
                                  'TSh ${_formatAmount(_report!.totalEarnings)}',
                                  style: const TextStyle(fontSize: 28, fontWeight: FontWeight.w800, color: Color(0xFF1A1A1A)),
                                ),
                                const SizedBox(width: 8),
                                _buildTrendChip(_report!.earningsChangePercent),
                              ],
                            ),
                          ],
                        ),
                      ),
                      const SizedBox(height: 12),
                      // Stats grid
                      Row(
                        children: [
                          Expanded(child: _buildStatTile(strings?.engagementTrend ?? 'Trend',
                              _trendLabel(_report!.engagementTrend, strings), _trendIcon(_report!.engagementTrend))),
                          const SizedBox(width: 12),
                          Expanded(child: _buildStatTile(strings?.followerChange ?? 'Followers',
                              '${_report!.followerChange >= 0 ? "+" : ""}${_report!.followerChange}', Icons.people_outline_rounded)),
                        ],
                      ),
                      const SizedBox(height: 12),
                      Row(
                        children: [
                          Expanded(child: _buildStatTile(strings?.threadsTriggered ?? 'Threads',
                              '${_report!.threadsTriggered}', Icons.local_fire_department_rounded)),
                          const SizedBox(width: 12),
                          Expanded(child: _buildStatTile('Views',
                              _formatAmount(_report!.totalViews.toDouble()), Icons.visibility_outlined)),
                        ],
                      ),
                      const SizedBox(height: 16),
                      // Best post
                      if (_report!.bestPostId > 0)
                        _buildCard(
                          child: InkWell(
                            onTap: () => Navigator.pushNamed(context, '/post/${_report!.bestPostId}'),
                            child: Row(
                              children: [
                                const Icon(Icons.emoji_events_rounded, size: 24, color: Color(0xFF1A1A1A)),
                                const SizedBox(width: 12),
                                Expanded(
                                  child: Column(
                                    crossAxisAlignment: CrossAxisAlignment.start,
                                    children: [
                                      Text(strings?.bestPost ?? 'Best Post',
                                          style: const TextStyle(color: Color(0xFF666666), fontSize: 12)),
                                      Text('${_report!.bestPostLikes} likes',
                                          style: const TextStyle(fontSize: 15, fontWeight: FontWeight.w600, color: Color(0xFF1A1A1A))),
                                    ],
                                  ),
                                ),
                                const Icon(Icons.chevron_right_rounded, color: Color(0xFF999999)),
                              ],
                            ),
                          ),
                        ),
                    ],
                  ),
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

  Widget _buildTrendChip(double percent) {
    final isUp = percent >= 0;
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
      decoration: BoxDecoration(
        color: isUp ? const Color(0xFFE8F5E9) : const Color(0xFFFFEBEE),
        borderRadius: BorderRadius.circular(8),
      ),
      child: Text(
        '${isUp ? "+" : ""}${percent.toStringAsFixed(1)}%',
        style: TextStyle(
          fontSize: 12,
          fontWeight: FontWeight.w600,
          color: isUp ? const Color(0xFF2E7D32) : const Color(0xFFC62828),
        ),
      ),
    );
  }

  String _trendLabel(String trend, dynamic strings) {
    switch (trend) {
      case 'up': return strings?.trendUp ?? 'Trending Up';
      case 'down': return strings?.trendDown ?? 'Trending Down';
      default: return strings?.trendStable ?? 'Stable';
    }
  }

  IconData _trendIcon(String trend) {
    switch (trend) {
      case 'up': return Icons.trending_up_rounded;
      case 'down': return Icons.trending_down_rounded;
      default: return Icons.trending_flat_rounded;
    }
  }

  String _formatAmount(double amount) {
    if (amount >= 1000000) return '${(amount / 1000000).toStringAsFixed(1)}M';
    if (amount >= 1000) return '${(amount / 1000).toStringAsFixed(1)}K';
    return amount.toStringAsFixed(0);
  }
}
```

- [ ] **Step 2: Run analyze**
- [ ] **Step 3: Commit**

---

## Task 10: CreatorDashboardSection (Profile Integration)

**Files:**
- Create: `lib/screens/profile/creator_dashboard_section.dart`
- Modify: `lib/screens/profile/profile_screen.dart`

- [ ] **Step 1: Create CreatorDashboardSection widget**

A collapsible section showing:
- CreatorTierBadge (tier + multiplier)
- StreakIndicator (posting streak days)
- Multiplier breakdown (tier, streak, community, virality)
- Fund pool projection (projected payout this month)
- "View Weekly Report" button
- "Request Payout" button

Fetches data using existing Phase 1 CreatorService methods: `getCreatorScore()`, `getCreatorStreak()`, `getFundPayoutProjection()` — all already exist in `lib/services/creator_service.dart`.

- [ ] **Step 2: Embed in ProfileScreen**

In `profile_screen.dart`, find `_buildProfileInfo()` (around the follower stats area). After the existing stats row, add a conditional section:

```dart
// Show creator dashboard when viewing own profile
if (isOwnProfile) CreatorDashboardSection(userId: widget.currentUserId),
```

Import `creator_dashboard_section.dart`.

- [ ] **Step 3: Run analyze**
- [ ] **Step 4: Commit**

---

## Task 11: Routes + FCM Updates

**Files:**
- Modify: `lib/main.dart`
- Modify: `lib/services/fcm_service.dart`

- [ ] **Step 1: Add routes to main.dart**

Add to onGenerateRoute switch:
- `case 'digest':` → DigestScreen
- `case 'weekly-report':` → WeeklyReportScreen (with userId from path segments)

Add imports for DigestScreen and WeeklyReportScreen.

- [ ] **Step 2: Update FCM routing**

In `fcm_service.dart`:
- `digest` → navigate to `/digest`
- `weekly_report` → navigate to `/weekly-report/{userId}`
- `milestone` → show MilestoneOverlay with milestone text from payload

Import MilestoneOverlay.

- [ ] **Step 3: Run analyze**
- [ ] **Step 4: Commit**

---

## Task 12: Feed Rabbit Hole Mechanics

**Files:**
- Modify: `lib/screens/feed/feed_screen.dart`
- Modify: `lib/screens/feed/full_screen_post_viewer_screen.dart`

- [ ] **Step 1: Add teaser card injection in feed_screen.dart**

In the Posts tab ListView builder, every 10 posts inject a TeaserCard. Track a `_postsViewed` counter. When it reaches certain depth milestones (10, 25, 50), subtly improve content quality by sorting remaining posts by engagement score.

Add import for TeaserCard. Modify the item count and itemBuilder to account for injected cards.

- [ ] **Step 2: Add autoplay countdown in full_screen_post_viewer_screen.dart**

After viewing 3+ posts in the full-screen viewer, show a subtle "Up Next" text overlay with 2-second countdown before auto-advancing. Add state: `_autoPlayEnabled` (false initially, true after 3 posts), `_countdownTimer`.

- [ ] **Step 3: Run analyze**
- [ ] **Step 4: Commit**

---

## Task 13: Final Verification

- [ ] **Step 1: Run flutter analyze** — expect 0 errors, 0 warnings
- [ ] **Step 2: Run all tests** — expect all passing
- [ ] **Step 3: Verify git log** — all commits present
- [ ] **Step 4: Ship gate checklist:**
  - [ ] Payment models + service created
  - [ ] Weekly report endpoint connected
  - [ ] StreakIndicator shows on profile
  - [ ] CreatorTierBadge shows on profile
  - [ ] MilestoneOverlay can be triggered
  - [ ] TeaserCard injected in feed
  - [ ] DigestScreen accessible via `/digest`
  - [ ] WeeklyReportScreen accessible via `/weekly-report/:userId`
  - [ ] CreatorDashboardSection embedded in own profile
  - [ ] FCM routes updated for digest/report/milestone
  - [ ] Autoplay mechanics in full-screen viewer
  - [ ] Backend: fund pool tables, distribution job, notification templates, weekly report endpoint
