# Shangazi Tea — AI Gossip Partner Design Spec

## Overview

**Shangazi** ("Aunt" in Swahili) is an AI-powered gossip personality that lives in the TAJIRI app's Home screen as a 4th tab ("Tea" with a cup icon). She curates personalized gossip from platform activity, chats with users in a bilingual Swahili-English voice, can take platform actions on the user's behalf, and searches the web when platform data isn't enough.

**Mental model:** Opening the Tea tab feels like opening a WhatsApp chat where your gossipy aunt has been sending you tea all day. Each curated topic is a "message" from her. You reply to dig deeper, ask new questions, or request actions ("post this for me", "send this to Asha").

---

## §1 Shangazi's Personality

### Voice & Language
- **Bilingual code-switcher** — Mixes Swahili and English naturally, matching how young Tanzanians text
- Example: *"Babe, hii story ya leo ni MOTO! 🔥 So basically, @Amina posted at 3am about 'fake friends' na sasa @Fatima ameblock account yake... aisee, this is getting juicy!"*
- Uses expressions: "Aisee!", "Kumbe!", "Dada yangu sikiliza...", "Sasa basi...", "The tea is PIPING hot"
- Adapts to user's language preference from their profile matrix (`primary_language` field)

### Knowledge Hierarchy
1. **Platform-primary** — Shangazi knows everything happening on TAJIRI (trending posts, beefs, viral content, who's following/unfollowing who, relationship changes, creator drama)
2. **General knowledge fallback** — When asked about off-platform topics, she engages with a disclaimer: *"Hii sijaiona hapa TAJIRI lakini from what I know..."*
3. **Web search** — When she doesn't know something current, she searches the web and reports back: *"Nimeangalia mtandaoni na kumbe..."*

### Gossip Content Types
| Type | Format | Example |
|------|--------|---------|
| **Breaking Tea** | Short dramatic headline + summary | "BREAKING: @Diamond amefuta picha ZOTE na @Zuchu... 👀" |
| **Beef Alert** | Two-sides presentation | "@X says... BUT @Y responded with..." |
| **Hot Take** | Shangazi's commentary on trends | "Okay but WHY is everyone posting about chai ya maziwa at 2am? Let me investigate..." |
| **Recap** | Timeline of ongoing drama | "Here's the full story: 1) Monday... 2) Tuesday... 3) Today..." |
| **Poll/Question** | Engagement driver | "Between these two, nani yupo right? Vote!" |
| **Tip/Whisper** | Anonymous user-submitted tea | "Someone sent me this... 👀" |

---

## §2 Architecture

### System Components

```
┌──────────────────────────────────────────────────────────────────┐
│                      FLUTTER CLIENT                               │
│                                                                    │
│  ┌────────────┐  ┌────────────┐  ┌─────────────┐                │
│  │ Tea Tab    │  │ Action     │  │ Event       │                │
│  │ Chat UI   │  │ Confirm    │  │ Tracking    │                │
│  │ (SSE)     │  │ Cards      │  │ (10s batch) │                │
│  └─────┬──────┘  └─────┬──────┘  └──────┬──────┘                │
└────────┼───────────────┼────────────────┼────────────────────────┘
         │               │                │
         ▼               ▼                ▼
┌──────────────────────────────────────────────────────────────────┐
│                      LARAVEL BACKEND                              │
│                                                                    │
│  ┌──────────────────┐  ┌──────────────────┐                      │
│  │ POST /api/tea/   │  │ POST /api/events │                      │
│  │      chat        │  │ (existing)       │                      │
│  │ (SSE streaming)  │  │                  │                      │
│  └────────┬─────────┘  └────────┬─────────┘                      │
│           │                      │                                │
│           ▼                      ▼                                │
│  ┌──────────────────┐  ┌──────────────────┐                      │
│  │ AI Orchestrator  │  │ Matrix Builder   │                      │
│  │ (Python sidecar) │  │ (Event listener) │                      │
│  │ Claude Sonnet    │  │ Updates profiles │                      │
│  └────────┬─────────┘  └──────────────────┘                      │
│           │                                                       │
│     MCP Protocol                                                  │
│     (JSON-RPC 2.0 over stdio)                                    │
│           │                                                       │
│  ┌────────┼──────────┬──────────┬──────────┐                     │
│  │        │          │          │          │                      │
│  ▼        ▼          ▼          ▼          ▼                      │
│ ┌──────┐┌──────┐ ┌──────┐ ┌──────┐ ┌──────┐                    │
│ │MCP:  ││MCP:  │ │MCP:  │ │MCP:  │ │MCP:  │                    │
│ │User  ││Social│ │Content│ │Action│ │Web   │                    │
│ │Profile││Graph │ │& Feed│ │Server│ │Search│                    │
│ └──┬───┘└──┬───┘ └──┬───┘ └──┬───┘ └──┬───┘                    │
│    │       │        │        │        │                          │
│    ▼       ▼        ▼        ▼        ▼                          │
│ ┌─────────────────────────────────┐  ┌──────┐                   │
│ │  PostgreSQL 16 + pgvector       │  │ Web  │                   │
│ │  + Typesense + Redis            │  │ APIs │                   │
│ └─────────────────────────────────┘  └──────┘                   │
│                                                                    │
│  ┌────────────────────────────────────────────┐                   │
│  │           CRON JOBS (Laravel)               │                  │
│  │  • Trending aggregation (15 min)           │                  │
│  │  • Cohort tea pre-generation (hourly)      │                  │
│  │  • Embedding pipeline (15 min, existing)   │                  │
│  │  • Profile matrix decay (daily)            │                  │
│  │  • User similarity computation (daily)     │                  │
│  └────────────────────────────────────────────┘                   │
└──────────────────────────────────────────────────────────────────┘
```

### Data Flow

1. **Signal collection:** User interactions → EventTrackingService (10s batches) → `POST /api/events` → Matrix Builder updates `user_behavior_profiles`
2. **Content indexing:** New posts → embedding pipeline (existing, 15 min) → pgvector index. Trending aggregation cron → `tea_topics` table
3. **Tea generation:** User opens Tea tab → `POST /api/tea/chat {user_id}` → AI Orchestrator pulls user matrix via MCP → pulls trending topics via MCP → Claude generates personalized tea → SSE stream back to client
4. **Conversation:** User replies → same endpoint with `{user_id, message, conversation_id}` → Claude uses MCP tools to answer (search posts, look up users, check trends)
5. **Actions:** Shangazi proposes action → returns structured `action_card` in response → frontend shows confirmation UI → user confirms → frontend calls existing service endpoint → reports result back to chat

---

## §3 MCP Server Inventory

### MCP Server 1: User Profile Server

Provides deep user understanding. Shangazi uses these tools to personalize tea and answer questions about the user's social world.

| Tool | Parameters | Returns | Use Case |
|------|-----------|---------|----------|
| `get_user_matrix` | `user_id` | Full behavioral profile: topic interests, format preferences, engagement patterns, gossip score, language, active hours, interaction style | Personalizing tea selection |
| `get_user_profile` | `user_id` | Static profile: name, bio, location, school, employer, age, gender, profile photo URL | "Who is this person?" |
| `get_user_stats` | `user_id` | Post count, follower/following count, friends count, creator tier, streak days | "How popular is X?" |
| `get_user_activity` | `user_id, type?, days?` | Recent posts, likes, comments, shares (last N days) | "What has X been up to?" |
| `get_user_interests` | `user_id` | Topic affinity scores, preferred content types, top hashtags consumed | Matching tea to user taste |
| `get_user_preferences` | `user_id` | Language pref, content prefs, opted-out topics, blocked users | Filtering inappropriate tea |
| `get_user_engagement_level` | `user_id` | Engagement tier (gentle/medium/full), account age | Adjusting tea intensity |
| `get_creator_score` | `user_id` | Creator tier, posting streak, viral assists, influence score | "Is X a big deal?" |
| `compare_users` | `user_id_a, user_id_b` | Side-by-side **public** stats (follower count, post count, shared interests). Only includes mutual friends and interaction data visible to the requesting user. Respects privacy settings (`profile_visibility`, `who_can_see_posts`). Never exposes DM content or private interactions. | "Between Asha and Patricia, who do you prefer?" |
| `get_user_content_summary` | `user_id, days?` | AI-generated summary of what user has posted/engaged with recently | Quick user overview |

### MCP Server 2: Social Graph Server

Maps relationships and social dynamics. Critical for gossip about "who knows who" and detecting drama.

| Tool | Parameters | Returns | Use Case |
|------|-----------|---------|----------|
| `get_friends` | `user_id, limit?` | Friends list with interaction frequency scores | "Who are X's closest friends?" |
| `get_followers` | `user_id, limit?, sort?` | Follower list (sortable by recency, engagement) | "Who follows X?" |
| `get_following` | `user_id, limit?` | Following list | "Who does X follow?" |
| `get_mutual_friends` | `user_id_a, user_id_b` | Shared connections | "How are X and Y connected?" |
| `get_friendship_status` | `user_id_a, user_id_b` | Status: friends, pending, following, blocked, none | "Are X and Y still friends?" |
| `get_recent_follows` | `user_id?, hours?` | Recent follow/unfollow activity (platform-wide or per user) | Detecting unfollows (drama signal) |
| `get_recent_blocks` | `user_id?` | Recent block events (anonymized unless about the querying user) | "Did X block Y?" |
| `get_interaction_history` | `user_id_a, user_id_b, limit?` | Likes, comments, shares between two users | "How do X and Y interact?" |
| `get_social_circle` | `user_id, depth?` | Clustered friend groups (school, work, family) with labels | Understanding social dynamics |
| `get_influence_graph` | `user_id, hops?` | Who influences this user (based on engagement patterns) | Personalizing influencer tea |
| `get_user_groups` | `user_id` | Groups user belongs to with activity level | "What communities is X in?" |
| `get_group_members` | `group_id, limit?` | Group members with roles | "Who's in this group?" |
| `get_close_friends` | `user_id` | Close friends list (if feature exists) | Inner circle detection |

### MCP Server 3: Content & Feed Server

Searches and retrieves platform content. The primary source of "tea" — trending posts, beefs, viral moments.

| Tool | Parameters | Returns | Use Case |
|------|-----------|---------|----------|
| `search_trending_topics` | `timeframe?, category?, limit?` | Trending topics with velocity scores, post counts, top reactions | "What's hot today?" |
| `get_trending_hashtags` | `timeframe?, limit?` | Trending hashtags with usage counts and growth rate | Hashtag-based tea |
| `get_posts_by_topic` | `topic, limit?, sort?` | Posts matching topic (semantic search via pgvector) | Deep dive into a topic |
| `get_posts_by_hashtag` | `hashtag, limit?, sort?` | Posts with specific hashtag | "#drama posts" |
| `get_post_detail` | `post_id` | Full post with comments, reactions, shares, media URLs | "Show me this post" |
| `get_post_comments` | `post_id, limit?, sort?` | Comments sorted by engagement or recency | "What are people saying?" |
| `get_post_reactions` | `post_id` | Reaction breakdown (like, love, haha, wow, sad, angry) | Sentiment gauge |
| `get_viral_posts` | `timeframe?, min_engagement?, limit?` | Posts exceeding engagement thresholds | "What went viral?" |
| `get_controversial_posts` | `timeframe?, limit?` | High comment-to-like ratio posts (drama signals) | Beef detection |
| `get_beef_threads` | `timeframe?, limit?` | Gossip threads with status=active, high velocity | Ongoing beefs |
| `get_gossip_digest` | `user_id?` | Personalized trending threads + proverb (existing endpoint) | Morning/evening tea |
| `get_user_posts` | `user_id, limit?, type?` | Posts by specific user | "What did X post?" |
| `search_posts_semantic` | `query, limit?, filters?` | Semantic search across all posts (pgvector + multilingual-e5-base) | Natural language content search |
| `get_stories_feed` | `user_id?` | Current stories from followed users or platform-wide | "Any juicy stories?" |
| `get_clips_trending` | `timeframe?, limit?` | Trending short videos | Viral clips tea |
| `get_clips_by_user` | `user_id, limit?` | User's clips | "What clips has X posted?" |
| `get_music_trending` | `timeframe?, limit?` | Trending tracks on platform | Music tea |
| `get_live_streams` | `status?` | Currently live or upcoming streams | "Who's live right now?" |
| `get_stream_highlights` | `stream_id` | Key moments from a stream (gifts, comments, viewer peaks) | Stream tea |
| `get_events_upcoming` | `category?, limit?` | Upcoming events | "What's happening soon?" |
| `get_poll_results` | `poll_id` | Poll results with vote counts | "How did people vote?" |
| `get_battle_results` | `battle_id?` | Creator battle standings and votes | "Who's winning the battle?" |
| `get_campaign_updates` | `campaign_id?` | Michango campaign progress, donations | "How's the fundraiser going?" |
| `get_marketplace_trending` | `category?, limit?` | Hot products, popular sellers | Shop gossip |
| `get_content_by_location` | `region?, district?, limit?` | Posts from specific area | Local tea |

### MCP Server 4: Actions Server

Executes platform actions on behalf of the user. All Tier 2 actions return `action_card` objects for frontend confirmation before execution.

| Tool | Tier | Parameters | Returns | Use Case |
|------|------|-----------|---------|----------|
| **Posts** | | | | |
| `draft_post` | 2 | `content, media_urls?, hashtags?, mentions?` | `action_card: {type: "create_post", preview, confirm_prompt}` | "Help me post about..." |
| `like_post` | 2 | `post_id, reaction?` | `action_card: {type: "like", target_preview}` | "Like that for me" |
| `comment_on_post` | 2 | `post_id, content` | `action_card: {type: "comment", draft, target_preview}` | "Comment on this" |
| `share_post` | 2 | `post_id, caption?` | `action_card: {type: "share", preview}` | "Share this to my timeline" |
| `save_post` | 2 | `post_id` | `action_card: {type: "save"}` | "Save this for later" |
| `react_to_post` | 2 | `post_id, reaction_type` | `action_card: {type: "react"}` | "React with 🔥" |
| **Messages** | | | | |
| `draft_message` | 2 | `recipient_id, content, media?` | `action_card: {type: "send_message", preview, recipient_name}` | "Send this to Asha" |
| `forward_post_to_user` | 2 | `post_id, recipient_id, note?` | `action_card: {type: "forward", preview}` | "Send this post to my friend" |
| **Social** | | | | |
| `follow_user` | 2 | `target_id` | `action_card: {type: "follow", target_profile}` | "Follow this person" |
| `unfollow_user` | 2 | `target_id` | `action_card: {type: "unfollow", target_profile}` | "Unfollow X" |
| `send_friend_request` | 2 | `target_id` | `action_card: {type: "friend_request", target_profile}` | "Add them as friend" |
| **Stories** | | | | |
| `draft_story` | 2 | `media_url, caption?` | `action_card: {type: "create_story", preview}` | "Post this as a story" |
| `react_to_story` | 2 | `story_id, emoji` | `action_card: {type: "story_react"}` | "React to their story" |
| **Music** | | | | |
| `save_track` | 2 | `track_id` | `action_card: {type: "save_track", track_info}` | "Save this song" |
| `share_track` | 2 | `track_id, recipient_id?` | `action_card: {type: "share_track", preview}` | "Share this song" |
| **Events** | | | | |
| `rsvp_event` | 2 | `event_id, response` | `action_card: {type: "rsvp", event_preview}` | "RSVP to this event" |
| **Groups** | | | | |
| `join_group` | 2 | `group_id` | `action_card: {type: "join_group", group_preview}` | "Join this group" |
| **Clips** | | | | |
| `like_clip` | 2 | `clip_id` | `action_card: {type: "like_clip"}` | "Like this clip" |
| `save_clip` | 2 | `clip_id` | `action_card: {type: "save_clip"}` | "Save this clip" |
| **Shopping** | | | | |
| `view_product` | 1 | `product_id` | Product details, price, reviews | "Tell me about this product" |
| `add_to_cart` | 2 | `product_id, quantity?` | `action_card: {type: "add_to_cart", product_preview}` | "Add this to my cart" |
| **Campaigns** | | | | |
| `view_campaign` | 1 | `campaign_id` | Campaign details, progress, donors | "How's the michango going?" |

**Security constraint:** All Tier 2 action tools do NOT accept `user_id` as a parameter. The Actions MCP server always uses the authenticated user from the session/bearer token context. This prevents the AI from executing actions as a different user.

### MCP Server 5: Web Search Server

External knowledge when platform data isn't enough.

| Tool | Parameters | Returns | Use Case |
|------|-----------|---------|----------|
| `search_web` | `query, region?, language?` | Top 5 results with titles, snippets, URLs | General external search |
| `search_news` | `query, region?, recency?` | Recent news articles | Breaking news tea |
| `search_entertainment` | `query, category?` | Entertainment news (Bongo Flava, Nollywood, sports) | Celebrity gossip |
| `search_music_trends` | `genre?, region?` | Music charts, releases, artist news | Music industry tea |
| `search_social_trends` | `platform?, topic?` | What's trending on Twitter/TikTok/Instagram | Cross-platform tea |
| `get_cultural_context` | `topic, region?` | Cultural references, proverbs, local context | Enriching commentary |

**Search provider:** Brave Search API (free tier: 2,000 queries/month, paid: $5/1,000 queries). Chosen for privacy-first approach, good non-English results, and simple REST API. Fallback: Tavily API for AI-optimized search results.

---

## §4 User Profile Matrix

### Database Schema

```sql
CREATE TABLE user_behavior_profiles (
    user_id BIGINT PRIMARY KEY REFERENCES user_profiles(id),

    -- Topic interests (0.0-1.0, time-decayed)
    -- {"music": 0.85, "gossip": 0.92, "politics": 0.3, "fashion": 0.7, "sports": 0.4}
    topic_interests JSONB DEFAULT '{}',

    -- Content format preferences (0.0-1.0)
    -- {"video": 0.8, "image": 0.6, "text": 0.4, "audio": 0.5, "clips": 0.7}
    format_preferences JSONB DEFAULT '{}',

    -- Engagement patterns
    avg_session_duration_seconds INT DEFAULT 0,
    peak_active_hours INT[] DEFAULT '{}',          -- [10, 13, 20, 21] hours in EAT
    sessions_per_day FLOAT DEFAULT 0,
    avg_posts_per_week FLOAT DEFAULT 0,
    avg_comments_per_week FLOAT DEFAULT 0,
    avg_likes_per_day FLOAT DEFAULT 0,
    avg_shares_per_week FLOAT DEFAULT 0,

    -- Social behavior classification
    interaction_style VARCHAR(20) DEFAULT 'lurker',  -- lurker | commenter | creator | curator | socializer
    social_circle_size INT DEFAULT 0,
    influence_score FLOAT DEFAULT 0,                 -- 0-1 based on engagement received
    reciprocity_score FLOAT DEFAULT 0,               -- 0-1 how much they engage back

    -- Content consumption
    avg_watch_time_seconds FLOAT DEFAULT 0,
    content_completion_rate FLOAT DEFAULT 0,          -- 0-1
    scroll_speed VARCHAR(10) DEFAULT 'medium',        -- slow | medium | fast
    replay_rate FLOAT DEFAULT 0,                      -- 0-1 how often they re-view content

    -- Gossip-specific signals
    gossip_engagement_score FLOAT DEFAULT 0,          -- 0-1
    preferred_gossip_types TEXT[] DEFAULT '{}',        -- {breaking, beef, hot_take, recap, poll}
    tea_consumption_frequency VARCHAR(10) DEFAULT 'occasional', -- daily | weekly | occasional | never
    shares_gossip BOOLEAN DEFAULT false,
    gossip_topics_followed TEXT[] DEFAULT '{}',        -- specific ongoing stories

    -- Creator interactions (who they care about most)
    -- {"user_42": 0.95, "user_17": 0.8, "user_99": 0.6}
    creator_affinity JSONB DEFAULT '{}',

    -- Relationship awareness (for "between X and Y" questions)
    -- {"user_42:user_17": "close_friends", "user_99:user_55": "rivals"}
    known_relationships JSONB DEFAULT '{}',

    -- Language & communication
    primary_language VARCHAR(5) DEFAULT 'sw',         -- sw | en | mixed
    code_switch_frequency FLOAT DEFAULT 0.5,          -- 0-1
    emoji_usage_frequency FLOAT DEFAULT 0.5,          -- 0-1
    preferred_response_length VARCHAR(10) DEFAULT 'medium', -- short | medium | long

    -- Temporal patterns
    most_active_days INT[] DEFAULT '{}',              -- 0=Sun, 6=Sat (matches PostgreSQL EXTRACT(DOW))
    timezone VARCHAR(30) DEFAULT 'Africa/Dar_es_Salaam',

    -- Tea tab specific
    shangazi_conversations_count INT DEFAULT 0,
    last_tea_visit TIMESTAMP,
    tea_topics_asked TEXT[] DEFAULT '{}',              -- topics user has asked about
    tea_satisfaction_score FLOAT DEFAULT 0.5,          -- 0-1 derived from engagement

    -- Metadata
    matrix_version INT DEFAULT 1,
    created_at TIMESTAMP DEFAULT NOW(),
    updated_at TIMESTAMP DEFAULT NOW()
);

CREATE INDEX idx_ubp_gossip ON user_behavior_profiles(gossip_engagement_score DESC);
CREATE INDEX idx_ubp_style ON user_behavior_profiles(interaction_style);
CREATE INDEX idx_ubp_updated ON user_behavior_profiles(updated_at);

-- Granular signal log (for matrix computation)
CREATE TABLE user_behavior_signals (
    id BIGSERIAL PRIMARY KEY,
    user_id BIGINT NOT NULL REFERENCES user_profiles(id),
    signal_type VARCHAR(50) NOT NULL,    -- view, like, comment, share, save, skip, dwell, search, tea_tap, tea_skip
    target_type VARCHAR(30),             -- post, clip, story, user, hashtag, tea_card, product, track
    target_id BIGINT,
    metadata JSONB DEFAULT '{}',         -- {dwell_ms, scroll_pct, reaction_type, query_text, ...}
    created_at TIMESTAMP DEFAULT NOW()
);

CREATE INDEX idx_ubs_user_recent ON user_behavior_signals(user_id, created_at DESC);
CREATE INDEX idx_ubs_type ON user_behavior_signals(signal_type, created_at DESC);

-- User similarity cache (collaborative filtering)
CREATE TABLE user_similarity_cache (
    user_id BIGINT REFERENCES user_profiles(id),
    similar_user_id BIGINT REFERENCES user_profiles(id),
    similarity_score FLOAT,
    shared_interests TEXT[] DEFAULT '{}',
    computed_at TIMESTAMP DEFAULT NOW(),
    PRIMARY KEY (user_id, similar_user_id)
);

CREATE INDEX idx_usc_score ON user_similarity_cache(user_id, similarity_score DESC);
```

### Matrix Update Pipeline

**Event processing (on each 10s batch from frontend):**
1. Raw signals stored in `user_behavior_signals`
2. Lightweight aggregation updates `user_behavior_profiles`:
   - Increment counters (likes today, comments this week)
   - Update `topic_interests` with exponential decay: `new_score = old_score * 0.95 + signal_weight * 0.05`
   - Update `creator_affinity` on each interaction with a user
   - Update `format_preferences` based on content type consumed
   - Classify `interaction_style` based on action ratios
   - Update `scroll_speed` from dwell time distributions

**Daily cron job:**
- Decay all `topic_interests` by 2% (ensures stale interests fade)
- Recompute `influence_score` from engagement received
- Recompute `user_similarity_cache` (cosine similarity on `topic_interests` vectors)
- Recompute `social_circle_size` from active connections (interacted in last 30 days)
- Classify `tea_consumption_frequency` from visit patterns

### Signal Types (Extended from current 11)

| Signal | Target | Metadata | Weight |
|--------|--------|----------|--------|
| `view` | post, clip, story, profile | `{dwell_ms, scroll_pct}` | 1.0 |
| `dwell` | post, clip | `{duration_ms}` | 1.5 |
| `scroll_past` | post, clip | `{time_on_screen_ms}` | -0.5 |
| `like` | post, clip, comment | `{reaction_type}` | 2.0 |
| `comment` | post, clip | `{text_length, has_mention}` | 3.0 |
| `share` | post, clip, track | `{share_target}` | 4.0 |
| `save` | post, clip, track | — | 2.5 |
| `follow` | user | — | 3.0 |
| `unfollow` | user | — | -3.0 |
| `search` | — | `{query, results_tapped}` | 1.0 |
| `message_sent` | user | `{has_media, media_type}` | 2.0 |
| `profile_viewed` | user | `{dwell_ms, sections_viewed}` | 1.0 |
| `story_viewed` | story | `{completed, replied}` | 1.5 |
| `story_replied` | story | `{has_media}` | 3.0 |
| `clip_replayed` | clip | `{replay_count}` | 3.0 |
| `not_interested` | post, clip | — | -5.0 |
| `report` | post, user | `{reason}` | -10.0 |
| `tea_card_tapped` | tea_card | `{topic_id, card_type}` | 2.0 |
| `tea_card_skipped` | tea_card | `{topic_id, card_type}` | -1.0 |
| `tea_question_asked` | — | `{query_text}` | 2.0 |
| `tea_action_confirmed` | — | `{action_type, target}` | 3.0 |
| `tea_action_rejected` | — | `{action_type, target}` | -1.0 |
| `product_viewed` | product | `{dwell_ms, added_to_cart}` | 1.0 |
| `track_played` | track | `{duration_ms, completed}` | 1.5 |
| `event_rsvp` | event | `{response}` | 2.0 |
| `group_post` | group | `{post_type}` | 2.0 |
| `battle_vote` | battle | `{voted_for}` | 2.0 |
| `hashtag_viewed` | hashtag | `{hashtag_name, dwell_ms}` | 1.0 |
| `campaign_donated` | campaign | `{amount}` | 4.0 |
| `call_initiated` | user | `{call_type}` | 3.0 |
| `depth_milestone` | — | `{depth}` | 0.5 |

**Note on existing `view` event:** The existing codebase emits `view` with sub-classifications (`view_glance`, `view_partial`, `view_deep`) based on dwell time. These are preserved as-is. The new `dwell` signal is a **separate, additional** signal emitted when a user watches video/audio content for a meaningful duration. Both coexist — `view` for content visibility, `dwell` for deep engagement measurement.

---

## §5 Tea Topics Pre-Generation

### Backend Cron: Trending Aggregation (every 15 minutes)

```sql
-- tea_topics table
CREATE TABLE tea_topics (
    id BIGSERIAL PRIMARY KEY,
    topic_type VARCHAR(30) NOT NULL,     -- breaking, beef, viral, trending_hashtag, creator_drama, relationship, local
    title_sw TEXT NOT NULL,               -- Swahili headline
    title_en TEXT NOT NULL,               -- English headline
    summary TEXT NOT NULL,                -- 2-3 sentence summary
    category VARCHAR(30),                 -- entertainment, music, sports, business, local, relationships
    urgency VARCHAR(10) DEFAULT 'warm',  -- fire | hot | warm | cold
    velocity_score FLOAT DEFAULT 0,       -- engagement growth rate
    post_count INT DEFAULT 0,
    participant_count INT DEFAULT 0,
    source_post_ids BIGINT[] DEFAULT '{}', -- posts this topic is derived from
    source_user_ids BIGINT[] DEFAULT '{}', -- users involved
    geographic_scope VARCHAR(20) DEFAULT 'global', -- global | regional | local
    region_id INT,                         -- for local tea
    top_reaction VARCHAR(10),              -- dominant emoji
    embedding vector(768),                 -- for semantic matching to user interests
    expires_at TIMESTAMP,                  -- when this topic becomes stale
    is_active BOOLEAN DEFAULT true,
    created_at TIMESTAMP DEFAULT NOW(),
    updated_at TIMESTAMP DEFAULT NOW()
);

CREATE INDEX idx_tt_active ON tea_topics(is_active, urgency, velocity_score DESC);
CREATE INDEX idx_tt_category ON tea_topics(category, is_active);
CREATE INDEX idx_tt_embedding ON tea_topics USING hnsw (embedding vector_cosine_ops);
```

### Conversation & Message Storage

```sql
CREATE TABLE tea_conversations (
    id VARCHAR(30) PRIMARY KEY,          -- "conv_{uuid_short}" e.g. "conv_abc123"
    user_id BIGINT NOT NULL REFERENCES user_profiles(id),
    title VARCHAR(255),                   -- Auto-generated: "Morning Tea - Mar 30"
    message_count INT DEFAULT 0,
    last_message_preview TEXT,            -- First 100 chars of last message
    cohort_id VARCHAR(50),                -- Which cohort was used for initial tea
    created_at TIMESTAMP DEFAULT NOW(),
    updated_at TIMESTAMP DEFAULT NOW()
);

CREATE INDEX idx_tc_user ON tea_conversations(user_id, updated_at DESC);

CREATE TABLE tea_messages (
    id VARCHAR(30) PRIMARY KEY,           -- "msg_{sequence}"
    conversation_id VARCHAR(30) NOT NULL REFERENCES tea_conversations(id) ON DELETE CASCADE,
    role VARCHAR(10) NOT NULL,            -- 'user' | 'shangazi'
    type VARCHAR(20) NOT NULL,            -- 'text' | 'tea_card' | 'action_card' | 'action_result' | 'web_search_result'
    content JSONB NOT NULL,               -- Varies by type (see §7 REST Response Shapes)
    source_topic_ids BIGINT[] DEFAULT '{}', -- tea_topics referenced
    source_post_ids BIGINT[] DEFAULT '{}',  -- posts referenced
    mcp_tools_used TEXT[] DEFAULT '{}',     -- tools invoked for this message
    moderation_flags TEXT[] DEFAULT '{}',   -- any safety flags triggered
    created_at TIMESTAMP DEFAULT NOW()
);

CREATE INDEX idx_tm_conv ON tea_messages(conversation_id, created_at);

-- Pending action cards (for confirmation flow)
CREATE TABLE tea_pending_actions (
    id VARCHAR(30) PRIMARY KEY,           -- "ac_{uuid_short}" — the action_card_id
    conversation_id VARCHAR(30) NOT NULL REFERENCES tea_conversations(id),
    user_id BIGINT NOT NULL REFERENCES user_profiles(id),
    action_type VARCHAR(30) NOT NULL,     -- 'create_post', 'send_message', 'follow', etc.
    action_params JSONB NOT NULL,         -- Parameters needed to execute the action
    status VARCHAR(15) DEFAULT 'pending', -- pending | confirmed | rejected | expired
    expires_at TIMESTAMP NOT NULL,        -- Auto-expire after 10 minutes
    executed_at TIMESTAMP,
    execution_result JSONB,               -- Result of the action after execution
    created_at TIMESTAMP DEFAULT NOW()
);

CREATE INDEX idx_tpa_user ON tea_pending_actions(user_id, status);
```

### Audit Log

```sql
CREATE TABLE tea_audit_log (
    id BIGSERIAL PRIMARY KEY,
    conversation_id VARCHAR(30) NOT NULL,
    message_id VARCHAR(30),
    user_id BIGINT NOT NULL,
    request_type VARCHAR(20) NOT NULL,     -- 'initial_tea', 'conversation', 'action_confirm'
    user_message TEXT,                      -- What the user said (null for initial tea)
    shangazi_response TEXT NOT NULL,        -- Full generated response
    source_topic_ids BIGINT[] DEFAULT '{}',
    source_post_ids BIGINT[] DEFAULT '{}',
    mcp_tools_called JSONB DEFAULT '[]',   -- [{tool, params, result_summary}]
    model_used VARCHAR(50),                -- 'claude-sonnet-4-20250514', etc.
    input_tokens INT,
    output_tokens INT,
    latency_ms INT,
    moderation_flags TEXT[] DEFAULT '{}',
    safety_blocked BOOLEAN DEFAULT false,
    created_at TIMESTAMP DEFAULT NOW()
);

CREATE INDEX idx_tal_user ON tea_audit_log(user_id, created_at DESC);
CREATE INDEX idx_tal_safety ON tea_audit_log(safety_blocked) WHERE safety_blocked = true;

-- Partition by month for retention management (drop partitions older than 90 days)
-- CREATE TABLE tea_audit_log_2026_03 PARTITION OF tea_audit_log FOR VALUES FROM ('2026-03-01') TO ('2026-04-01');
```

### Aggregation Logic

1. **Breaking tea:** Posts with engagement velocity > 3x average in last 2 hours
2. **Beef detection:** Posts with high comment-to-like ratio + negative sentiment + multiple users replying to each other
3. **Viral content:** Posts exceeding 95th percentile engagement for their age
4. **Trending hashtags:** Hashtags with usage growth > 200% vs previous period
5. **Creator drama:** Follow/unfollow spikes between notable users, deleted posts with high engagement
6. **Relationship signals:** Profile photo changes + bio changes + post sentiment shifts
7. **Local tea:** Region-specific trending content

### Cohort Pre-Generation (hourly)

Group users into behavioral cohorts based on:
- `interaction_style` (5 types)
- Top 2 `topic_interests` categories
- `primary_language` (3 types)
- `gossip_engagement_score` (high/medium/low)

Cohort assignment uses **bucketed hashing**, not full cartesian product:
- Bucket 1: `interaction_style` (5 types)
- Bucket 2: Top interest category (map to ~8 mega-categories: entertainment, music, sports, business, local, relationships, fashion, tech)
- Bucket 3: `primary_language` (3 types: sw, en, mixed)
- Bucket 4: `gossip_engagement_score` (2 tiers: high ≥ 0.5, low < 0.5)

Total: 5 × 8 × 3 × 2 = **240 theoretical cohorts**, but many will be empty. In practice, ~60-100 active cohorts based on user distribution. For each active cohort, generate a pre-baked Shangazi greeting + 5-7 tea cards using Claude. Cache in Redis (TTL: 1 hour).

**Initial Tea tab load:** When user opens Tea tab, serve cached cohort content immediately via a standard `GET /api/tea/conversations` call (not SSE). This is instant. The SSE stream is only used when the user sends a message or asks for fresh tea. This ensures the first tea card appears in < 1 second (cached) even on slow networks.

---

## §6 Frontend: Tea Tab UI

### Tab Addition

Add 4th tab to `FeedScreen`'s `TabController`. Specific changes required in `feed_screen.dart`:
- Change `TabController(length: 3, ...)` → `length: 4`
- Update `_FeedTabBar`'s `List.generate(3, ...)` → `List.generate(4, ...)`
- Add `case 3:` to `_iconFor` switch returning tea cup icon
- Add `'tea'` to `_feedTypes` list and `'Chai'`/`'Tea'` to tab labels
- **Index 3:** Tea tab
- **Label:** "Chai" (English: "Tea")
- **Icon:** Use `Icons.local_cafe_rounded` (Material tea cup) — `HeroIcons` does not include a tea/coffee cup icon. Use outline variant `Icons.local_cafe_outlined` for unselected state.
- Tab order: Posts (0), Friends (1), Live (2), Tea (3)

### Chat UI Structure

```
┌──────────────────────────────┐
│ ☕ Shangazi's Tea Room        │  ← App bar with character name
├──────────────────────────────┤
│                              │
│  ┌────────────────────────┐  │
│  │ 🫖 Shangazi             │  │  ← Tea card "message" from Shangazi
│  │ BREAKING TEA ☕🔥       │  │
│  │ "@Amina posted at 3am  │  │
│  │  about fake friends..." │  │
│  │                        │  │
│  │ [Read More] [Share]    │  │
│  └────────────────────────┘  │
│                              │
│  ┌────────────────────────┐  │
│  │ 🫖 Shangazi             │  │  ← Another tea card
│  │ BEEF ALERT 🥊           │  │
│  │ "@X vs @Y — nani yupo  │  │
│  │  right?"               │  │
│  │                        │  │
│  │ [Side A] [Side B]     │  │
│  └────────────────────────┘  │
│                              │
│  ┌────────────────────────┐  │
│  │ 👤 You                  │  │  ← User's message
│  │ "Tell me more about    │  │
│  │  that beef"            │  │
│  └────────────────────────┘  │
│                              │
│  ┌────────────────────────┐  │
│  │ 🫖 Shangazi             │  │  ← Shangazi's detailed response
│  │ "Okay dada sikiliza... │  │     (streamed via SSE)
│  │  so it started when..."│  │
│  └────────────────────────┘  │
│                              │
│  ┌────────────────────────┐  │
│  │ 🫖 Shangazi             │  │  ← Action card
│  │ ACTION: Draft Post     │  │
│  │ "Your fire response:   │  │
│  │  [preview text]"       │  │
│  │                        │  │
│  │ [✓ Post It] [✗ Cancel] │  │
│  └────────────────────────┘  │
│                              │
├──────────────────────────────┤
│ 💬 Ask Shangazi...      [→] │  ← Text input
└──────────────────────────────┘
```

### Message Types

| Type | Rendered As | Source |
|------|-------------|--------|
| `tea_card` | Rich card with headline, summary, media, action buttons | Shangazi's curated tea |
| `text_message` | Chat bubble (Shangazi or user) | Conversation |
| `action_card` | Card with preview + confirm/cancel buttons | Shangazi proposing an action |
| `action_result` | Success/failure notification bubble | After action execution |
| `typing_indicator` | Animated dots + "Shangazi anapika chai..." | During SSE stream |
| `web_search_result` | Card with source URL and summary | External search results |

### New Files

| File | Purpose |
|------|---------|
| `lib/screens/feed/tea_chat_screen.dart` | Tea tab chat UI (StatefulWidget) |
| `lib/services/tea_service.dart` | API calls: `POST /api/tea/chat`, SSE stream handling |
| `lib/models/tea_models.dart` | `TeaMessage`, `TeaCard`, `ActionCard`, `TeaConversation` |
| `lib/widgets/tea_card_widget.dart` | Rich tea card rendering |
| `lib/widgets/action_card_widget.dart` | Action confirmation card |
| `lib/widgets/shangazi_message_bubble.dart` | Shangazi's chat bubble with personality styling |

---

## §7 Backend API Endpoints

### New Endpoints

| Method | Path | Auth | Request | Response | Purpose |
|--------|------|------|---------|----------|---------|
| `POST` | `/api/tea/chat` | Bearer | `{message?, conversation_id?}` | `{conversation_id, stream_url}` | Initiate chat, returns stream URL |
| `GET` | `/api/tea/stream/:conversation_id` | Bearer | — | SSE stream of `TeaMessage` objects | Stream Shangazi's response |
| `GET` | `/api/tea/conversations` | Bearer | `?limit` | `{conversations: [...]}` | List past conversations |
| `GET` | `/api/tea/conversations/:id` | Bearer | — | `{messages: [...]}` | Load conversation history |
| `DELETE` | `/api/tea/conversations/:id` | Bearer | — | `{success: true}` | Delete conversation |
| `POST` | `/api/tea/action/confirm` | Bearer | `{action_card_id, confirmed: bool}` | `{success, result?}` | Execute confirmed action (backend executes) |
| `POST` | `/api/tea/feedback` | Bearer | `{message_id, type: "helpful"|"harmful"|"inaccurate"}` | `{success: true}` | Report/rate tea quality |

**Chat flow:** The client POSTs to `/api/tea/chat` to create/continue a conversation. The server returns a `conversation_id` and `stream_url`. The client then connects to `GET /api/tea/stream/{conversation_id}` as a standard SSE connection. This two-step approach avoids the SSE-over-POST anti-pattern (SSE spec requires GET).

**Action execution flow:** When Shangazi proposes an action, she returns an `action_card` with a unique `action_card_id`. The server stores the pending action details (which service method to call, parameters). When the user confirms, the frontend calls `POST /api/tea/action/confirm` with the `action_card_id`. The **backend** executes the action using the authenticated user's context (never the AI's). This ensures proper authorization and audit trail.

### SSE Stream Format

The client connects via `GET /api/tea/stream/{conversation_id}` using raw `http.Client.send()` with `StreamedResponse` parsing (no SSE library needed — the `http` package handles this natively).

**Flutter SSE parsing pattern:**
```dart
final request = http.Request('GET', Uri.parse(streamUrl));
request.headers['Authorization'] = 'Bearer $token';
request.headers['Accept'] = 'text/event-stream';
final response = await http.Client().send(request);
await for (final chunk in response.stream.transform(utf8.decoder)) {
  for (final line in chunk.split('\n')) {
    if (line.startsWith('data: ')) {
      final data = jsonDecode(line.substring(6));
      // Handle tea_card, text, action_card, done events
    }
  }
}
```

**Stream events:**
```
event: tea_card
data: {"type":"tea_card","id":"tc_1","headline":"BREAKING TEA ☕🔥","summary":"...","urgency":"fire","source_posts":[42,67],"actions":["read_more","share"]}

event: text
data: {"type":"text","content":"Sasa ","done":false}

event: text
data: {"type":"text","content":"basi ","done":false}

event: text
data: {"type":"text","content":"dada...","done":false}

event: text
data: {"type":"text","content":"","done":true}

event: action_card
data: {"type":"action_card","id":"ac_1","action":"create_post","preview":{"content":"...","hashtags":["..."]},"confirm_prompt":"Post hii?"}

event: done
data: {"type":"done","conversation_id":"conv_abc123"}
```

### REST Response Shapes

**GET /api/tea/conversations:**
```json
{
  "success": true,
  "conversations": [
    {
      "id": "conv_abc123",
      "title": "Morning Tea - Mar 30",
      "last_message_preview": "BREAKING: @Amina posted...",
      "message_count": 12,
      "created_at": "2026-03-30T08:00:00Z",
      "updated_at": "2026-03-30T09:30:00Z"
    }
  ]
}
```

**GET /api/tea/conversations/:id:**
```json
{
  "success": true,
  "conversation": {
    "id": "conv_abc123",
    "title": "Morning Tea - Mar 30",
    "created_at": "2026-03-30T08:00:00Z"
  },
  "messages": [
    {
      "id": "msg_1",
      "role": "shangazi",
      "type": "tea_card",
      "content": {
        "headline": "BREAKING TEA ☕🔥",
        "summary": "@Amina posted at 3am about...",
        "urgency": "fire",
        "source_posts": [42, 67],
        "actions": ["read_more", "share"]
      },
      "created_at": "2026-03-30T08:00:05Z"
    },
    {
      "id": "msg_2",
      "role": "user",
      "type": "text",
      "content": "Tell me more about that beef",
      "created_at": "2026-03-30T08:01:20Z"
    },
    {
      "id": "msg_3",
      "role": "shangazi",
      "type": "text",
      "content": "Okay dada sikiliza...",
      "created_at": "2026-03-30T08:01:25Z"
    },
    {
      "id": "msg_4",
      "role": "shangazi",
      "type": "action_card",
      "content": {
        "action_card_id": "ac_1",
        "action": "create_post",
        "preview": {"content": "...", "hashtags": ["..."]},
        "confirm_prompt": "Post hii?",
        "status": "pending"
      },
      "created_at": "2026-03-30T08:02:00Z"
    }
  ]
}
```

---

## §8 AI Orchestrator (Sidecar Extension)

### System Prompt (Shangazi Personality)

```
You are Shangazi — TAJIRI's beloved gossip aunt. You're warm, dramatic, entertaining,
and always in the know. You speak in a mix of Swahili and English (code-switching),
the way young Tanzanians text their friends.

PERSONALITY:
- Dramatic but loving: "Aisee! Dada yangu, sit DOWN for this one..."
- Uses expressions: "Kumbe!", "Sasa basi...", "The tea is PIPING hot"
- Protective of your "nieces and nephews" (users)
- Loves emoji but not excessively: 🔥☕👀🥊💀
- Gets excited about drama but presents both sides fairly
- Has catchphrases: "Shangazi haichoki!" (Auntie never tires)

STRICT RULES:
- ONLY discuss content that exists on the platform or verified external sources
- NEVER fabricate gossip or make unverified claims about real people
- NEVER use hate speech, slurs, or sexually explicit content
- NEVER encourage harassment, brigading, or pile-ons
- When discussing beef, present BOTH sides: "Side A says... but Side B responded..."
- Frame as entertainment commentary: "word on the street..." / "from what people are posting..."
- If content involves minors, health crises, or death: be respectful, drop the gossip tone
- Include source attribution: "Based on @user's post from 2 hours ago..."

CAPABILITIES:
- You can search platform content, view user profiles, check trending topics
- You can help users create posts, send messages, follow people (with their confirmation)
- You can search the web for external context when asked
- You have access to the user's behavioral profile to personalize recommendations

LANGUAGE:
- Adapt to user's language preference from their profile
- Default: bilingual code-switching (Swahili + English)
- If user writes in pure Swahili, respond in more Swahili
- If user writes in pure English, still mix in some Swahili flair

When generating tea cards, structure each as:
- Dramatic headline (short, punchy, with emoji)
- 2-3 sentence summary
- Source attribution (which posts/users)
- Suggested follow-up actions
```

### Tool Registration

The orchestrator registers all MCP tools with Claude via the tools API. Claude decides which tools to call based on the conversation context. The orchestrator executes tool calls via MCP protocol and returns results to Claude for synthesis.

### Model Selection

| Task | Model | Reason |
|------|-------|--------|
| Tea card generation | Claude Sonnet | Balance of quality and speed |
| Conversational replies | Claude Sonnet | Good personality adherence |
| Action drafting | Claude Sonnet | Needs to understand user intent |
| Topic classification | Claude Haiku | Fast, cheap routing |
| Content moderation check | Claude Haiku | Binary classification |
| Complex analysis ("who do you prefer?") | Claude Sonnet | Needs matrix reasoning |

### Prompt Caching

Cache the system prompt + tool definitions (static across requests). Only user messages + tool results change per request. Estimated 90% input token savings on the cached portion.

---

## §9 Content Safety & Moderation

### Multi-Layer Safety

| Layer | Mechanism | When |
|-------|-----------|------|
| **L1: System prompt** | Personality rules forbid fabrication, hate speech, minor content | Every request |
| **L2: Source grounding** | Every claim must trace to a real post/interaction via MCP tools | During generation |
| **L3: Output filter** | Claude Haiku moderation check on generated content before sending | Post-generation |
| **L4: User reporting** | `POST /api/tea/feedback` with type `"harmful"` or `"inaccurate"` | User-triggered |
| **L5: Topic blocklist** | Maintain list of blocked topics/users that Shangazi won't discuss | Configurable |
| **L6: Rate limiting** | Max 50 tea requests per user per hour | Per-request |

### Blocked Content Patterns
- Content about users who opted out (`opt_out_threads = true` in user_profiles)
- Content involving users under 18
- Medical/health claims
- Content from blocked users (per the requesting user's block list)
- Content flagged by moderation system

### Audit Trail
Every Shangazi response is logged with:
- `conversation_id`, `user_id`, `timestamp`
- Source `tea_topic_ids` and `post_ids` referenced
- MCP tools called and their results
- Full generated response
- Any moderation flags triggered
- Stored in `tea_audit_log` table, retained 90 days

---

## §10 Caching Strategy

| Cache Layer | Storage | TTL | Content |
|-------------|---------|-----|---------|
| Trending topics | Redis | 15 min | Aggregated `tea_topics` |
| Cohort pre-gen tea | Redis | 1 hour | Pre-generated Shangazi greetings per cohort |
| User conversation | PostgreSQL | Permanent | Full chat history |
| User matrix | PostgreSQL + Redis | Redis: 5 min | Hot cache of frequently accessed matrices |
| MCP tool results | Redis | 1-5 min | Dedup repeated tool calls within a conversation |
| Embeddings | pgvector | Permanent | Post/topic embeddings |

### Cost Optimization

1. **Cohort pre-generation** — Generate once for 50-100 cohorts hourly, serve to thousands of users. First Tea tab open is instant (cached).
2. **Prompt caching** — Claude caches system prompt + tools. ~90% savings on repeated calls.
3. **Model tiering** — Haiku for classification/moderation, Sonnet for generation.
4. **Conversation context window** — Only send last 10 messages + current user matrix, not full history.
5. **Tool result caching** — If Shangazi calls `search_trending_topics` for user A, cache for 1 minute. User B's request within that minute reuses the result.

---

## §11 EventTrackingService Changes

### Modifications to Existing Service

| Change | Current | New |
|--------|---------|-----|
| Flush interval | 30 seconds | **10 seconds** (see justification below) |
| Event types | 11 | **30** (see §4 signal table) |
| Tracking locations | 6 files, ~20 call sites | **15+ files, ~60 call sites** |

**Flush interval justification:** The 10s interval is chosen specifically because the User Profile Matrix needs near-real-time updates for Shangazi's personalization to feel responsive. A user who likes 3 gossip posts in 30 seconds should see Shangazi adapt in the same session. The bandwidth impact is minimal: each batch is a small JSON array (~1-5 KB), and the existing batch-size cap of 100 events prevents oversized payloads. On 2G/EDGE networks, the 10s flush is **adaptive** — if the previous flush hasn't completed (network slow), the next flush is skipped and events continue accumulating. This is already how the existing service works (timer resets, doesn't stack).

### New Tracking Locations

| File | New Signals |
|------|-------------|
| `tea_chat_screen.dart` | `tea_card_tapped`, `tea_card_skipped`, `tea_question_asked`, `tea_action_confirmed`, `tea_action_rejected` |
| `chat_screen.dart` | `message_sent` |
| `search_screen.dart` | `search` (with query text) |
| `music_player_sheet.dart` | `track_played` |
| `hashtag_screen.dart` | `hashtag_viewed` |
| `wallet_screen.dart` | `product_viewed` (shop items) |
| All screens with clips | `clip_replayed` |
| Story viewers | `story_viewed`, `story_replied` |

---

## §12 Database Tables Summary

### New Tables

| Table | Purpose | Rows (est.) |
|-------|---------|-------------|
| `user_behavior_profiles` | User behavioral matrix | 1 per user |
| `user_behavior_signals` | Raw signal log | High volume, partitioned by month |
| `user_similarity_cache` | Collaborative filtering | N * 50 (top 50 similar per user) |
| `tea_topics` | Pre-digested trending content | ~100-500 active at any time |
| `tea_conversations` | Chat history metadata | 1+ per user |
| `tea_messages` | Individual messages in conversations | High volume |
| `tea_audit_log` | AI response audit trail | 1 per response, 90 day retention |

### Modified Tables

| Table | Change |
|-------|--------|
| `user_profiles` | Add `shangazi_enabled` BOOLEAN DEFAULT true (opt-out) |

---

## §12a Migration from Existing Gossip System

The codebase already has gossip infrastructure: `GossipService`, `GossipThread` model, `GossipThreadCard` widget, `DigestScreen`, `ThreadViewerScreen`. Here's how Shangazi Tea relates:

| Existing | Status | Relationship to Tea |
|----------|--------|---------------------|
| `GossipService.getThreads()` | **Preserved** | Used by MCP Content Server's `get_beef_threads()` tool internally |
| `GossipService.getDigest()` | **Preserved** | Backend's `tea_topics` aggregation replaces this for Tea, but digest endpoint remains for non-Tea users |
| `GossipThread` model | **Preserved** | Tea topics are a superset — `tea_topics` table has richer schema but `GossipThread` still used in feed |
| `GossipThreadCard` widget | **Preserved** | Still renders in Posts feed (interleaved every 5-7 posts). Tea has its own `TeaCardWidget` |
| `DigestScreen` | **Preserved but deprioritized** | Still accessible via `/digest` route. Users who prefer the old digest can keep using it. No new development. |
| `ThreadViewerScreen` | **Preserved** | Tea cards can deep-link to thread viewer for full post thread browsing |

**In short:** Tea is a **new layer on top of** existing gossip, not a replacement. The existing gossip feed interleaving and digest continue working. Tea adds the AI-powered conversational experience.

## §12b New `pubspec.yaml` Dependencies

No new packages required. The SSE streaming uses raw `http.Client.send()` with `StreamedResponse` from the existing `http` package. The Material tea cup icon (`Icons.local_cafe_rounded`) is built into Flutter's Material library. All other functionality uses existing packages.

## §13 Implementation Phases

### Phase 1: Foundation (Matrix + Signals)
- `user_behavior_profiles` table + migration
- `user_behavior_signals` table + migration
- Extend EventTrackingService: 10s flush, new signal types
- Backend: event processor that updates matrix from signals
- Backend: daily cron for matrix decay + similarity computation

### Phase 2: Tea Topics Pipeline
- `tea_topics` table + migration
- Backend: trending aggregation cron (15 min)
- Backend: beef/drama detection logic
- pgvector embeddings on tea_topics for semantic matching

### Phase 3: MCP Servers
- MCP Server 1: User Profile (10 tools)
- MCP Server 2: Social Graph (13 tools)
- MCP Server 3: Content & Feed (25 tools)
- MCP Server 4: Actions (21 tools)
- MCP Server 5: Web Search (6 tools)

### Phase 4: AI Orchestrator
- Extend AI sidecar with MCP client
- Shangazi system prompt + personality
- Claude Sonnet integration with tool use
- SSE streaming endpoint
- Content moderation layer

### Phase 5: Frontend Tea Tab
- Tea tab in FeedScreen (4th tab)
- `tea_models.dart`, `tea_service.dart`
- `tea_chat_screen.dart` — chat UI with SSE
- `tea_card_widget.dart`, `action_card_widget.dart`, `shangazi_message_bubble.dart`
- Action confirmation flow

### Phase 6: Caching & Optimization
- Redis caching layers
- Cohort pre-generation cron
- Prompt caching configuration
- Model tiering (Haiku for routing, Sonnet for generation)

### Phase 7: Safety & Polish
- Output moderation filter
- User feedback/reporting
- Audit logging
- Topic blocklist management
- Opt-out support

---

## §14 File Inventory

### Frontend (New)

| File | Lines (est.) | Purpose |
|------|-------------|---------|
| `lib/screens/feed/tea_chat_screen.dart` | 600 | Tea tab main chat screen |
| `lib/services/tea_service.dart` | 200 | API + SSE stream handling |
| `lib/models/tea_models.dart` | 150 | TeaMessage, TeaCard, ActionCard, TeaConversation |
| `lib/widgets/tea_card_widget.dart` | 200 | Rich gossip card rendering |
| `lib/widgets/action_card_widget.dart` | 150 | Tier 2 action confirmation card |
| `lib/widgets/shangazi_message_bubble.dart` | 100 | Styled chat bubble for Shangazi |

### Frontend (Modified)

| File | Change |
|------|--------|
| `lib/screens/feed/feed_screen.dart` | `TabController(length: 3)` → 4, `_FeedTabBar` `List.generate(3,...)` → 4, add case 3 to `_iconFor` switch with `Icons.local_cafe_rounded`, add 'Chai' to tab labels, add Tea content view for index 3 |
| `lib/services/event_tracking_service.dart` | 10s flush, new signal types |
| `lib/main.dart` | Add `/tea` route |
| `lib/l10n/app_strings.dart` | Add tea/Shangazi strings |
| `lib/widgets/post_card.dart` | Add `message_sent` tracking to share actions |
| `lib/screens/messages/chat_screen.dart` | Add `message_sent` signal |
| `lib/screens/search/search_screen.dart` | Add `search` signal |
| `lib/screens/music/music_player_sheet.dart` | Add `track_played` signal |

### Backend (New) — Implemented on server

| Component | Type | Purpose |
|-----------|------|---------|
| Migration: `user_behavior_profiles` | Migration | Create matrix table |
| Migration: `user_behavior_signals` | Migration | Create signals table |
| Migration: `tea_topics` | Migration | Create topics table |
| Migration: `tea_conversations` + `tea_messages` | Migration | Chat storage |
| Migration: `tea_audit_log` | Migration | Audit trail |
| `TeaController` | Controller | `/api/tea/*` endpoints |
| `MatrixBuilderService` | Service | Processes events → matrix updates |
| `TeaTopicAggregator` | Service/Job | Trending aggregation cron |
| `CohortTeaGenerator` | Service/Job | Hourly pre-generation |
| MCP Server: User Profile | Python script | 10 tools |
| MCP Server: Social Graph | Python script | 13 tools |
| MCP Server: Content & Feed | Python script | 25 tools |
| MCP Server: Actions | PHP (Laravel) | 21 tools |
| MCP Server: Web Search | Python script | 6 tools |
| Shangazi orchestrator | Python (sidecar ext.) | Claude integration + MCP client |

---

## §15 Success Metrics

| Metric | Target | How Measured |
|--------|--------|-------------|
| Tea tab DAU | 30% of app DAU within 4 weeks | `tea_card_tapped` + `tea_question_asked` signals |
| Avg session duration in Tea | > 3 minutes | Time between tab open and close |
| Tea-driven platform actions | > 5% of posts/follows originate from Tea | `tea_action_confirmed` signals |
| Return rate | > 60% of Tea users return next day | Daily active / unique users |
| Safety incidents | < 0.1% of responses flagged | `tea_feedback` with type "harmful" |
| Response latency (first tea card) | < 3 seconds (cached cohort) | Server-side timing |
| Response latency (conversation) | < 5 seconds to first SSE token | Server-side timing |
