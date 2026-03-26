# TAJIRI Flywheel Growth Engine — Design Specification

**Date:** 2026-03-26
**Status:** Approved
**Scope:** Addiction Engine + Gossip-Virality Engine + Creator Incentive/Payment System

---

## 1. Executive Summary

TAJIRI's growth engine is a single self-reinforcing **Flywheel** where three strategies — addiction loops, gossip virality, and creator payments — are not separate features but interconnected stages of one cycle:

**Creators post → AI packages into gossip threads → Viewers get hooked → Engagement flows → Creators earn → Creators post more.**

Each revolution makes the next faster. The gossip engine is the feed algorithm itself, not a separate tab.

### Target Audiences

- **Young urban creators (18-25):** Clout-driven, want followers and money
- **Community traders & hustlers (25-40):** Marketplace-first, want customers and sales
- Both audiences served equally with dual reward paths (attention + money)

---

## 2. The Flywheel Architecture

### 5 Stages

1. **Creators Post** — Motivated by earnings + community status. Posting streaks earn bonus multipliers. Content calendar nudges remind them to post.
2. **AI Packages** — Algorithm detects engagement velocity spikes. Claude CLI groups related posts into gossip threads. Generates bilingual titles via templates. Creates morning/evening digests. Identifies developing narratives.
3. **Viewers Get Hooked** — Gossip threads create rabbit holes. "This thread has 47 new posts" pulls them deeper. Daily digest notification brings them back. "Trending near you" adds local urgency.
4. **Engagement Flows** — Viewers like, comment, share, save. Each action feeds back into trending algorithm. Shares spread content beyond the platform. Comments create sub-threads that pull more viewers in.
5. **Creators Earn** — Base fund pool distributed by engagement. Virality bonus: posts that trigger gossip threads earn 2-5x multiplier. Tips and subscriptions from loyal audience. Transparent earnings panel shows exactly what's working — creators optimize.

### Key Insight

The gossip engine is not a feature tab — it's the feed algorithm itself. Every post enters the Flywheel. The ones that generate conversation velocity get packaged into gossip threads and amplified. The existing Trending and Discover tabs become powered by the gossip engine.

---

## 3. AI Personalization Layer

### The Rule: AI is the Curator, Never the Creator

Claude CLI on the backend observes, scores, and arranges. It never adds text to posts, never writes captions, never generates comments, never creates content. All text in TAJIRI is human-written. AI only decides **what to show, in what order, to whom.**

### What Claude Studies Per User

**Behavioral Signals:**
- Posts liked, saved, shared (explicit interest)
- Dwell time per post (implicit interest)
- Posts scrolled past quickly (disinterest)
- Creators followed and unfollowed
- Hashtags engaged with
- Time of day activity patterns
- Session depth patterns

**Content Signals:**
- Post type preference (video > image > text?)
- Content topics (food, music, fashion, business)
- Language preference (Swahili vs English posts)
- Media length preference (short clips vs long videos)
- Engagement type (lurker vs commenter vs sharer)
- Geographic relevance (local vs national vs global)
- Social graph overlap (friends-of-friends content)

**Gossip Affinity:**
- Which gossip threads they entered
- How deep they went (read 3 posts vs all 40)
- Which thread categories they prefer
- Do they comment on drama or just watch?
- Share patterns (share gossip to chat vs externally)
- Thread completion rate

**Commerce Signals:**
- Products browsed and saved
- Price range preferences
- Shop categories visited
- Creator shops followed
- Purchase history
- Campaign donations (what causes they support)

### What Claude Outputs (Structured Data Only, No Text)

**Per-Post Relevance Score:**
For each post in the candidate pool, Claude assigns a 0-100 relevance score for the specific user. Score combines: topic match, creator affinity, content type preference, recency, social graph proximity, trending velocity. Feed is sorted by this score.

```json
{ "post_id": 4521, "relevance": 87, "reason_code": "topic_match+trending+friend_shared" }
```

**Gossip Thread Grouping:**
Claude identifies clusters of related posts that form a "story." Groups them into threads and assigns: thread_id, seed_post_id, related_post_ids[], category_tag, velocity_score. Assigns a `title_key` that maps to a pre-written template — NOT freeform text.

```json
{ "thread_id": "t_891", "posts": [4521, 4530, 4533, 4540], "category": "entertainment", "velocity": 92, "title_key": "trending_bongo" }
```

**Digest Selection:**
For morning/evening digests, Claude selects top 3-5 threads personalized per user. Push notification text uses templates with slot-filling — AI picks the template and fills slots, doesn't write prose.

```json
{ "user_id": 42, "digest": ["t_891", "t_903", "t_887"], "template": "morning_trending_city", "slots": { "count": 3, "city": "Dar" } }
```

**Creator Insights:**
Claude analyzes a creator's audience and content performance. Outputs: best_posting_time, audience_demographics, content_type_performance, suggested_category_tags. All structured data — no written advice.

```json
{ "creator_id": 15, "best_time": "19:00", "top_format": "short_video", "audience_city": "Dar es Salaam", "growth_trend": "up" }
```

### Backend Architecture: Claude CLI Integration

1. **Event Collection (Real-time):** Every user action (view, like, scroll-past, dwell, share, save) logged to `user_events` table. Lightweight INSERT, no processing.
2. **Profile Builder (Scheduled, every 15 min):** Laravel job sends user event batch to Claude CLI. Claude outputs `user_interest_profile` JSON. Stored in Redis for fast access.
3. **Feed Ranking (On Request):** When user opens feed, backend fetches candidate posts. Sends candidates + user_interest_profile to Claude CLI. Returns ranked post_ids. Cached 5 min per user. **Fallback:** if Claude is slow/down, use chronological + trending_score sort.
4. **Thread Detection (Scheduled, every 5 min):** Claude CLI scans posts with rising engagement velocity. Groups related posts into threads. Assigns category tags and title_keys. Stores in `gossip_threads` table.

### Hard Boundaries

**AI DOES:** Rank posts per user, group posts into threads, select digest content, pick notification templates, score creator performance, detect trending velocity, analyze audience patterns.

**AI NEVER:** Write post captions or text, generate comments or replies, create gossip thread titles (uses templates), write notification copy (uses templates), suggest what creators should say, fabricate engagement metrics, impersonate users in any way.

---

## 4. Addiction Engine

### Casual Viewer Loops

**Priority: Session Depth → Daily Opens → Social Actions**

#### Loop 1: The Rabbit Hole (Session Depth)

**Gossip Threads:** When a user opens a trending post, show "This is part of a thread with 23 posts" banner. Tap enters a curated thread of related posts. Each thread has a template-generated title. Auto-advances to next post after 3s pause.

**Engagement Cliff-hangers:** Between every 5-7 posts in the feed, inject a "teaser card": "A creator you follow just posted something that's going viral — 1.2K people are watching right now." Creates curiosity gaps that prevent closing the app.

**Autoplay Chains:** In full-screen post viewer, after watching 3+ posts, show a subtle "Up Next" preview. Swipe physics become slightly easier. Video posts auto-advance after completion with 2s countdown overlay.

**Depth Milestones (Invisible):** After 10 posts: subtly improve content quality (show higher-engagement posts). After 25 posts: unlock "Deep Dive" gossip thread recommendation. After 50 posts: show "You're in the top 5% of active users today." No visible progress bar — these feel organic, not gamified.

#### Loop 2: The Daily Pull (Daily Opens)

**Morning Gossip Digest:** Push notification at user's typical wake time (learned from usage patterns): "Asubuhi Njema! 3 threads trending in Dar today." Opens directly into a curated "Morning Digest" screen showing top 3-5 gossip threads.

**Evening Recap:** Push at typical evening time: "Here's what happened today — the biggest thread got 5K reactions." Shows a "Today on TAJIRI" summary card. Includes threads the user started reading but didn't finish.

**Streak Counter (Soft):** Small flame icon on profile showing consecutive days active. No punishment for breaking — streak pauses and shows "Welcome back! Resume your 12-day streak?" Burns brighter at milestones (7, 30, 100 days). Visible to others on profile.

**FOMO Triggers:** When user hasn't opened app in 6+ hours and a gossip thread is spiking: "This thread has 2K new comments since you left." Frequency-capped to max 3 per day. Personalized to topics the user has engaged with before.

#### Loop 3: The Social Pull (Social Actions)

**Reaction Prompts:** After viewing a post for 3+ seconds without acting, show a subtle pulsing reaction bar. After the 10th passive view in a session, show "You've been quiet today — what do you think about this one?" with quick-react emojis. Contextual and spaced out.

**Comment Bait:** On gossip threads, show polarizing comment previews: "Top comment: 'Hii ni uongo kabisa' — 340 replies." Curiosity drives tap → reading comments → joining the conversation. Show "X people are typing right now" on hot threads.

**Share Rewards:** When a user shares a post that later goes viral: "A post you shared is now trending — you helped it go viral!" Track "viral assists" on profile.

### Creator Loops

**Priority: Community Building → Quality Over Quantity → Consistent Posting**

#### Loop 1: The Tribe (Community Building)

**Reply-to-Comment Earnings Boost:** Creators who reply to 50%+ of comments on their posts get a 1.5x earnings multiplier on that post. Shown in Creator Stats Panel: "Community bonus: 1.5x (replied to 34 of 45 comments)."

**Follower Milestone Celebrations:** At 100, 500, 1K, 5K, 10K, 50K, 100K followers: animated celebration screen + push notification to all followers ("@creator just hit 10K — you were one of the first 500!"). Badge appears on profile permanently.

**Collaboration Radar:** When two creators in similar niches both have growing audiences, suggest collaboration: "You and @other_creator both post about Dar street food — collab?" Posts with two creators get 2x algorithm boost.

#### Loop 2: The Craft (Quality Over Quantity)

**Engagement Rate Multiplier:** Earnings formula weights engagement rate (interactions / impressions) heavily. A post with 500 views and 100 likes earns MORE than a post with 5000 views and 200 likes.

**Gossip Thread Trigger Bonus:** When a creator's post becomes the seed of a gossip thread: 2x virality bonus. Thread reaches 50+ posts: 3x. Thread reaches 200+ posts: 5x. This is the highest-value action — makes creators think "what will people talk about?"

**Creator Score:** Rolling 30-day score combining: avg engagement rate, gossip threads triggered, community reply rate, follower growth velocity. Tiers: Rising (0-30), Established (30-60), Star (60-85), Legend (85-100). Higher tier = higher base earnings rate. Recalculated weekly (every Monday). For monthly fund distribution, the last weekly snapshot of the month is used. Historical snapshots stored in `creator_score_history` for trend analysis.

#### Loop 3: The Rhythm (Consistent Posting)

**Creator Posting Streak:** Post at least once every 48 hours to maintain streak. Streak multiplier on earnings: 7-day = 1.1x, 30-day = 1.25x, 90-day = 1.5x. Missing a post doesn't reset — it freezes. Bank 1 skip day every 7 days of streak.

**Smart Posting Nudges:** Based on creator's audience activity patterns: "Your followers are most active at 7PM — post in the next 2 hours for best reach." If streak about to expire: "You have 6 hours left on your 23-day streak — quick post to keep it alive." Shows draft count as escape hatch.

**Weekly Performance Report:** Every Monday morning: push notification with "Your Week on TAJIRI" card. Shows: total earnings, best performing post, engagement trend, follower change, gossip threads triggered. Comparison to previous week. Ends with a posting tip.

### Intensity Graduation

The system starts gentle and graduates based on each user's response:

- **Week 1-2 (Gentle):** Daily digest, organic feed, milestone celebrations only
- **Week 3-6 (Medium):** FOMO triggers, streak visibility, teaser cards, reaction prompts
- **Week 7+ (Full):** All loops active, personalized timing, loss aversion (streak freeze warnings), competitive elements

Users who don't respond to aggressive loops stay at Medium. The system adapts per-user, not globally.

---

## 5. Gossip-Virality Engine

### How a Gossip Thread Is Born

1. **Velocity Spike Detection:** Every 5 minutes, backend calculates engagement velocity: `(likes + comments×2 + shares×3) / hours_since_posted`. Posts exceeding 2x their creator's average velocity are flagged.
2. **Claude CLI Clusters Related Posts:** Same hashtags? Same topic? Response posts to each other? Groups them into a `gossip_thread`. Assigns seed post and category tag.
3. **Template Title Assignment:** Claude picks a title template from a predefined bilingual library and fills slots. Example: `"trending_{category}_hot"` → "🔥 {category} Imewaka" / "🔥 {category} Is On Fire". **No freeform text generation.**
4. **Thread Goes Live:** Appears in Trending tab, personalized digests, and as inline cards in the main feed. As new related posts appear, Claude adds them.

**Thread Lifecycle:**
- **Active:** Velocity score > 10 (above baseline). Promoted in trending, included in digests.
- **Cooling:** Velocity drops below 10 for 6+ hours. Still visible but not promoted. No new posts added.
- **Archived:** Cooling for 48+ hours. Accessible via direct link only. Thread posts released back to normal feed ranking.

**Thread Detection Fallback:** If Claude CLI is unavailable, fall back to hashtag co-occurrence + velocity threshold to create basic threads without semantic clustering. These "basic threads" group posts sharing 2+ common hashtags with combined velocity > 20. No template title assigned — shows "Trending: #{hashtag}" instead.

### Three Gossip Layers

**Layer 1: Global Trending (Primary — Highest Priority)**

Algorithm-driven, platform-wide trending.

- **Trending Topics:** Hashtag velocity spikes across all users. Shows post count and velocity indicator.
- **Viral Chains:** Posts shared 50+ times/hour tracked as repost chains. "Challenge" posts that spawn response videos auto-thread.
- **Creator Battles:** Two creators post opposing takes on same topic → Claude creates "Side A vs Side B" split-thread. Users take sides.
- **Milestone Moments:** Creator hits follower milestone, first 1M-view post, livestream viewer record → auto-generates celebration thread.

**Layer 2: East African Culture (Secondary — Flavor Layer)**

Cultural context that makes TAJIRI feel Tanzanian.

- **Kumekucha Digest:** Morning push: "Kumekucha! Hizi ndio habari za leo..." Evening: "Usiku Mwema — here's what you missed." Bilingual based on user's language setting.
- **Bongo Categories:** Thread categories that resonate locally: Bongo Flava, Mitumba & Biashara, Michezo, Siasa Light, Burudani, Uhusiano.
- **Local Celebrity Tracking:** When verified/popular creators are mentioned across multiple posts, Claude detects a "personality trend" and groups all posts about that person.
- **Swahili Proverb of the Day:** Daily cultural anchor in the digest. Pre-written library of ~365 proverbs with English translations. Human-curated, not AI-generated.

**Layer 3: Hyperlocal (Discovery Layer)**

What's happening in your area — powered by existing "Nearby" feed endpoint.

- **Neighborhood Threads:** Posts geotagged within 5km radius that spike in engagement. Drives foot traffic for marketplace sellers.
- **Local Business Buzz:** Multiple posts mention/tag same shop → "Business Spotlight" thread. Bridges social → commerce.
- **Community Alerts:** High-velocity local posts get "Alert" treatment: traffic, events, weather, scam warnings.
- **Nearby Creator Discovery:** Surface creators popular in user's area but not yet followed.

### Feed Integration

- **Thread Cards in Main Feed:** Every 8-12 regular posts, inject a "Gossip Thread Card" showing title, post count, top reaction, velocity indicator. Tap opens thread viewer.
- **Trending Tab (Powered by Gossip Engine):** Existing Discover → Trending tab becomes thread-first. Filter chips: All, Entertainment, Business, Music, Sports, Local.
- **Thread Viewer Screen:** Thread title, seed post at top, related posts in engagement-ranked order. Live counter. Pull-to-refresh. Swipe between threads.
- **Digest Screen:** Opened from push notification. 3-5 personalized thread summaries. Swahili proverb of the day. "Threads you left unfinished" section.

### Safety Rails

- **Auto-suppress:** 10+ reports in 1 hour → auto-hide from trending until manual review
- **No hate amplification:** Claude checks thread sentiment — harassment/hate threads don't get promoted
- **Cooldown:** Same topic can't trend more than 3 times in 24 hours
- **Creator opt-out:** Toggle "Don't include my posts in gossip threads" in settings

---

## 6. Creator Incentive & Payment System

### Three Revenue Tiers

#### Tier 1: Creator Fund Pool (Base Income)

TAJIRI allocates a monthly fund (configurable, starts at TSh 10M). Every qualifying creator gets a share proportional to their weighted engagement score relative to all other qualifying creators that month.

**Qualification Threshold (Testing/Launch):**
- 0 followers (production: 100)
- 1 post/month (production: 4)
- 0 views (production: 1K)

Thresholds configurable in `creator_fund_pools` table per month.

**Engagement-Weighted Formula (Already Built):**
Uses existing `creator_earnings_rates` table and `PostEarningsController`:

```
base_score = (views × view_rate) + (likes × like_rate) + (shares × share_rate)
           + (saves × save_rate) + (comments × comment_rate) + (watch_seconds × watch_rate)
```

Rates configurable in backend. Shares and saves weighted highest.

#### Tier 2: Direct Monetization

- **Subscriptions (EXISTS):** Creator sets price, offers exclusive content. 15% platform commission.
- **Tips & Gifts (EXISTS):** One-time tips. Predefined amounts (TSh 500, 1K, 5K, 10K) + custom. 10% commission.
- **Livestream Gifts (EXISTS):** Real-time gifts during livestream. 20% commission.
- **Sponsored Posts (NEW — requires separate detailed spec before Phase 4):** Marketplace where businesses pay creators. Creator sets rate based on tier. "Sponsored" tag on posts with business attribution. 20% commission. Star/Legend tiers only. Key flows to design: business discovery of creators (browse by niche/tier/audience), creator approval workflow, payment escrow (business pays TAJIRI upfront, creator paid on post publication), content guidelines, and "Sponsored" disclosure UI. Full spec required before Phase 4 implementation.

#### Tier 3: Ad Revenue Share (Future)

When TAJIRI introduces advertising: 55% creator / 45% platform. Ads only on posts with 1K+ views. Creator can opt out.

### Flywheel Multipliers (Stack on Base Score)

**Creator Score Tier Multiplier (1.0x — 2.5x):**
- Rising (score 0-30): 1.0x
- Established (30-60): 1.5x
- Star (60-85): 2.0x
- Legend (85-100): 2.5x

**Posting Streak Multiplier (1.0x — 1.5x):**
- No streak: 1.0x
- 7-day: 1.1x
- 30-day: 1.25x
- 90-day: 1.5x

Post every 48hrs. Bank 1 skip day per 7-day streak. Streak freezes (not resets) on miss.

**Community Bonus (1.0x — 1.5x):**
Reply to 50%+ of comments on a post → 1.5x on that post. Per-post, not global.

**Virality Bonus (1.0x — 5.0x):**
- Post triggers gossip thread: 2x
- Thread reaches 50+ posts: 3x
- Thread reaches 200+ posts: 5x

### Multiplier Rules

- Multipliers are **multiplicative** (they stack by multiplication, not addition)
- Multipliers apply **ONLY to fund pool base_score** — tips, subscriptions, and sponsored post payments are NOT multiplied
- **Maximum effective multiplier cap: 15x** — if the stacked multiplier exceeds 15x, it is clamped to 15x (prevents edge-case runaway)
- The `base_score` is in **arbitrary engagement units**, not currency. It only converts to TSh when the monthly fund pool is distributed proportionally: `creator_payout = (creator_final_score / sum_all_final_scores) × pool_total_amount`
- For monthly distribution, the **last weekly Creator Score snapshot** of the month is used as the tier multiplier

**Example Calculation:**
```
base_score = 500 units (from engagement formula)
× Star tier = 2.0x
× 30-day streak = 1.25x
× Community bonus = 1.5x
× Virality bonus = 3.0x
= effective multiplier: 11.25x (under 15x cap)
= final_score: 5,625 units for this post

Monthly payout (if this creator's total final_score is 5% of all creators):
= 5% × TSh 10,000,000 pool = TSh 500,000
```

### Payout System

- **Mobile Money First:** M-Pesa, Tigo Pesa, Airtel Money, Halo Pesa. Minimum payout: TSh 5,000. Processing: within 48 hours.
- **Fund pool:** Distributed on 1st of each month
- **Tips/gifts:** Available immediately (instant payout)
- **Subscriptions:** Monthly on renewal date
- **Sponsored posts:** On campaign completion

### Creator Journey

- **Week 1 (New):** First post. "You earned TSh 12 from 45 views." Small but real — proves system works.
- **Month 1 (Rising):** Hits thresholds, enters fund pool. First payout: ~TSh 2,500. Starts posting streak.
- **Month 3 (Star):** Score 60+, tier 2.0x. First gossip thread trigger (3x bonus). Monthly: TSh 45K+.
- **Month 6+ (Legend):** Score 85+, 2.5x tier, 90-day streak (1.5x). Multiple streams: fund (~TSh 80K) + subscriptions (~TSh 120K) + tips (~TSh 30K) + sponsored (~TSh 200K).

---

## 7. Data Model

### New Database Tables

**AI Personalization:**

| Table | Purpose |
|-------|---------|
| `user_events` | Behavioral tracking (view, like, dwell, scroll_past, etc.). Partitioned by month, pruned after 90 days. |
| `user_interest_profiles` | Computed by Claude CLI every 15 min. One row per user. Cached in Redis (TTL 20 min, auto-refresh). High-signal events (follow, unfollow, language change) trigger immediate profile rebuild to avoid 15-min staleness. Contains topic_weights, creator_affinities, format_preferences, activity_patterns, gossip_affinity, commerce_signals (all JSON). |

**Gossip Engine:**

| Table | Purpose |
|-------|---------|
| `gossip_threads` | Thread metadata: seed_post_id, title_key, title_slots (JSON), category, velocity_score, post_count, participant_count, status (active/cooling/archived), geographic_scope, location fields. |
| `gossip_thread_posts` | Post-to-thread mapping with relevance_score. A post can belong to multiple threads. |
| `thread_title_templates` | Bilingual templates: key, template_en, template_sw, slots (JSON), category, tone (hot/breaking/milestone/battle/local). ~50-100 human-written templates. |

**Creator Payments:**

| Table | Purpose |
|-------|---------|
| `creator_scores` | Rolling 30-day score (0-100), tier, component scores (community, quality, consistency), recalculated weekly. |
| `creator_streaks` | Posting streak: current_streak_days, longest, last_post_at, banked_skip_days, frozen state, multiplier. |
| `creator_fund_pools` | Monthly pool config: total_amount, currency, qualification thresholds (0 for testing), distributed flag. |
| `creator_fund_payouts` | Individual payout records with every multiplier recorded for transparency. |

**Addiction Engine:**

| Table | Purpose |
|-------|---------|
| `viewer_streaks` | Daily open streak: current_streak_days, longest, last_active_date, frozen state. |
| `notification_templates` | Bilingual push notification templates with slots, category, max_per_day, priority. |

### New API Endpoints

| Method | Endpoint | Purpose |
|--------|----------|---------|
| POST | `/api/events` | Log user behavior events (batch) |
| GET | `/api/feed/personalized` | AI-ranked feed for current user |
| GET | `/api/gossip/threads` | List active gossip threads (personalized, paginated) |
| GET | `/api/gossip/threads/{id}` | Thread detail with posts |
| GET | `/api/gossip/digest` | Personalized morning/evening digest |
| GET | `/api/creators/{id}/score` | Creator score, tier, multipliers |
| GET | `/api/creators/{id}/streak` | Posting streak status and multiplier |
| GET | `/api/creators/{id}/fund-payout` | Current month fund pool projection |
| GET | `/api/creators/{id}/weekly-report` | Weekly performance summary |
| GET | `/api/users/{id}/streak` | Viewer daily open streak |
| POST | `/api/creators/{id}/payout/request` | Request mobile money payout |

### Changes to Existing Infrastructure

- **Feed endpoints:** Existing `/api/feed/discover` and `/api/feed/trending` gain optional `?personalized=true` param. Non-breaking. Frontend integration point: existing `FeedService.getPersonalizedFeed()` method in `lib/services/feed_service.dart`.
- **Post model:** Gains optional `thread_id` and `thread_title` fields.
- **PostCard:** Shows small "Part of trending thread" badge when thread_id present.
- **Creator Stats Panel:** Enhanced with tier badge, streak indicator, multiplier breakdown, gossip thread count.
- **FCM routing:** New notification types: `digest`, `thread_trending`, `streak_warning`, `weekly_report`, `milestone`.

### New Flutter Screens & Widgets

| Screen/Widget | Purpose |
|---------------|---------|
| `ThreadViewerScreen` | Full gossip thread: title, seed post, related posts, live counter, swipe between threads |
| `DigestScreen` | Morning/evening digest: proverb, top threads, unfinished threads |
| `WeeklyReportScreen` | Creator weekly summary: earnings, best post, trend arrows, tip |
| `GossipThreadCard` | Widget: stacked-cards visual, injected into feed every 8-12 posts |
| `StreakIndicatorWidget` | Flame icon with day count, used on profile and creator stats |
| `CreatorTierBadge` | Rising/Established/Star/Legend badge with tier color |
| `MilestoneOverlay` | Full-screen animated celebration for milestones |
### New Flutter Service

| Service | Purpose |
|---------|---------|
| `EventTrackingService` | Singleton instance (like `LocalStorageService`). Maintains in-memory event buffer + periodic flush timer. Batches user events locally, flushes to `POST /api/events` every 30s or on app background via `WidgetsBindingObserver`. When offline, queues events in Hive and flushes on reconnect. Discards events older than 24 hours. Max batch size: 100 events per flush. |

#### Event Payload Schema

Each event in the batch contains:
```json
{
  "event_type": "view|like|share|save|scroll_past|dwell|comment|follow|unfollow",
  "post_id": 4521,
  "creator_id": 15,
  "timestamp": "2026-03-26T19:30:00Z",
  "duration_ms": 3200,
  "session_id": "uuid-v4",
  "metadata": {}
}
```

`duration_ms` is populated for `view` and `dwell` events. `session_id` groups events within a single app session. Deduplication key: `user_id + event_type + post_id + timestamp` (1-second granularity).

#### Dwell Time Implementation

Use `VisibilityDetector` (or equivalent) with 50% visibility threshold. A post visible for 1+ seconds counts as a `view` event. Time accumulates while the post is visible and pauses on app background (detected via `WidgetsBindingObserver.didChangeAppLifecycleState`). Final `dwell` event emitted when post leaves viewport.

---

## 8. Implementation Phases

### Phase 1: Foundation & Tracking

Invisible to users. Lays the data pipeline.

- **BE:** `user_events` table + `POST /api/events` endpoint
- **FE:** `EventTrackingService` — captures view, dwell, scroll_past, like, share, save. Batches locally, flushes every 30s.
- **BE:** `user_interest_profiles` table + Claude CLI profile builder (scheduled every 15 min)
- **BE:** `creator_streaks` + `viewer_streaks` tables with calculation logic
- **BE:** `creator_scores` table + weekly calculation job + `GET /api/creators/{id}/score`

**Ship gate:** Events flowing, profiles computing, streaks tracking.

### Phase 2: Gossip Engine + Personalized Feed

First user-visible changes.

- **BE:** `gossip_threads` + `thread_title_templates` tables. Seed ~50 bilingual templates. Thread CRUD. `GET /api/gossip/threads` and `/threads/{id}`.
- **BE:** Thread detection job (Claude CLI, every 5 min). Velocity spike detection, clustering, template assignment, lifecycle management.
- **BE:** Personalized feed ranking (Claude CLI). `GET /api/feed/personalized`. 5-min cache. Fallback to trending_score.
- **FE:** `GossipThreadCard` widget + `ThreadViewerScreen`
- **FE:** Feed switches to personalized endpoint
- **FE:** Thread indicator badge on PostCard

**Ship gate:** Gossip threads appearing, feed personalized, users can browse threads.

### Phase 3: Addiction Loops + Creator Payments

Hooks that keep users coming back and creators posting.

- **BE:** `creator_fund_pools` + `creator_fund_payouts` tables. Monthly distribution job. Multiplier calculation.
- **BE:** `notification_templates` table + digest/FOMO push jobs. Morning/evening digest (Claude CLI selects threads). FOMO triggers (max 3/day). Streak warnings.
- **BE:** `GET /api/gossip/digest` + weekly report endpoints
- **FE:** `DigestScreen` + `WeeklyReportScreen`
- **FE:** `StreakIndicatorWidget` + `CreatorTierBadge` + `MilestoneOverlay`
- **FE:** Enhanced Creator Stats Panel + Earnings Dashboard (tier, streak, multipliers, fund pool projection)
- **FE:** FCM notification routing for new types
- **FE:** Rabbit hole mechanics (teaser cards, autoplay chains, depth milestones)

**Ship gate:** Flywheel spinning. Creators earning, viewers hooked, gossip driving engagement.

### Phase 4: Advanced + Optimization

Polish and monetization expansion.

- Sponsored posts marketplace (Star/Legend tiers only)
- Collaboration radar (Claude CLI detects creator pairs)
- Intensity graduation system (per-user gentle → medium → full)
- Creator battles / split threads
- Ad revenue share (when ads launch, 55/45 split)
- Analytics & A/B testing framework (DAU/MAU, session depth, streak retention, feed CTR, thread entry rate)

**Ship gate:** Full Flywheel with all 3 revenue tiers and data-driven optimization.
