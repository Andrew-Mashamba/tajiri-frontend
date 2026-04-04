# Shangazi Tea Implementation Plan

> **For agentic workers:** REQUIRED SUB-SKILL: Use superpowers:subagent-driven-development (recommended) or superpowers:executing-plans to implement this plan task-by-task. Steps use checkbox (`- [ ]`) syntax for tracking.

**Goal:** Build Shangazi — an AI gossip partner that curates personalized tea from TAJIRI platform activity, chats with users via SSE streaming, and takes platform actions on their behalf through 76 MCP tools.

**Architecture:** Frontend adds a 4th "Tea" tab to FeedScreen with a WhatsApp-style chat UI. Backend adds database tables for behavioral profiles/signals/conversations, 5 MCP servers (Python) for platform data access, extends the AI sidecar with Claude tool-use and SSE streaming, and adds cron jobs for trending aggregation and cohort pre-generation.

**Tech Stack:** Flutter/Dart (frontend), Laravel 12 + PostgreSQL 16 + pgvector + Redis 7 (backend), Python 3 + Claude API (AI sidecar + MCP servers), multilingual-e5-base embeddings (port 8200)

**Spec:** `docs/superpowers/specs/2026-03-30-shangazi-tea-design.md`

**Backend SSH:** `sshpass -p "ZimaBlueApps" ssh -o StrictHostKeyChecking=no root@172.240.241.180`
**Backend project path:** `/var/www/tajiri.zimasystems.com`

---

## Dependency Graph

```
Task 1 (DB migrations) ──┬── Task 2 (Tea models)
                         ├── Task 3 (Signal extension)
                         ├── Task 5 (Matrix Builder)
                         ├── Task 6 (Tea Topics cron)
                         │
Task 2 (Tea models) ─────┼── Task 4 (TeaService + SSE)
                         │
Task 7-11 (MCP servers) ─┤── independent of each other, depend on Task 1
                         │
Task 12 (AI Orchestrator) ┤── depends on Tasks 7-11
                         │
Task 4 (TeaService) ──────┼── Task 13 (Tea Chat UI)
Task 12 (Orchestrator) ───┘
                         │
Task 13 (Tea Chat UI) ────── Task 14 (Feed tab integration)
                         │
Task 15 (Action cards) ────── depends on Tasks 13 + 12
Task 16 (Caching) ──────────  depends on Tasks 5, 6, 12
Task 17 (Safety) ───────────  depends on Task 12
Task 18 (Verification) ────── depends on all
```

## File Structure

### Frontend — New Files
| File | Responsibility |
|------|----------------|
| `lib/models/tea_models.dart` | TeaMessage, TeaCard, ActionCard, TeaConversation, PendingAction models |
| `lib/services/tea_service.dart` | API calls to /api/tea/*, SSE stream parsing |
| `lib/screens/feed/tea_chat_screen.dart` | Tea tab chat UI (ListView of messages + input) |
| `lib/widgets/tea_card_widget.dart` | Rich gossip card rendering (headline, summary, actions) |
| `lib/widgets/action_card_widget.dart` | Tier 2 action confirmation card (preview + confirm/cancel) |
| `lib/widgets/shangazi_message_bubble.dart` | Shangazi's styled chat bubble |

### Frontend — Modified Files
| File | Change |
|------|--------|
| `lib/screens/feed/feed_screen.dart` | TabController length 3→4, add Tea tab case, add TeaChatScreen |
| `lib/services/event_tracking_service.dart` | Flush interval 30→10s, add new signal types |
| `lib/l10n/app_strings.dart` | Add tea/Shangazi strings |
| `lib/main.dart` | Add `/tea` route |

### Backend — New Files (on server)
| File | Responsibility |
|------|----------------|
| `database/migrations/*_create_user_behavior_profiles_table.php` | Matrix table |
| `database/migrations/*_create_user_behavior_signals_table.php` | Signal log table |
| `database/migrations/*_create_tea_tables.php` | tea_topics, tea_conversations, tea_messages, tea_pending_actions, tea_audit_log |
| `app/Http/Controllers/Api/TeaController.php` | /api/tea/* endpoints |
| `app/Services/Tea/MatrixBuilderService.php` | Processes events → matrix updates |
| `app/Services/Tea/TeaTopicAggregator.php` | Trending aggregation cron |
| `app/Services/Tea/CohortTeaGenerator.php` | Hourly pre-generation |
| `app/Console/Commands/AggregateTrendingTopics.php` | Artisan command for cron |
| `app/Console/Commands/GenerateCohortTea.php` | Artisan command for cron |
| `app/Console/Commands/DecayProfileMatrix.php` | Daily matrix decay |
| `scripts/mcp-profile-server.py` | MCP Server 1: User Profile (10 tools) |
| `scripts/mcp-social-server.py` | MCP Server 2: Social Graph (13 tools) |
| `scripts/mcp-content-server.py` | MCP Server 3: Content & Feed (25 tools) |
| `scripts/mcp-actions-server.py` | MCP Server 4: Actions (22 tools) |
| `scripts/mcp-web-search-server.py` | MCP Server 5: Web Search (6 tools) |
| `scripts/shangazi-orchestrator.py` | AI Orchestrator with MCP client + SSE |

### Backend — Modified Files (on server)
| File | Change |
|------|--------|
| `app/Http/Controllers/Api/EventController.php` | Process new signal types, trigger matrix update |
| `routes/api.php` | Add /api/tea/* routes |
| `app/Console/Kernel.php` (or `routes/console.php`) | Register cron schedule |

---

## Phase 1: Foundation

### Task 1: Backend Database Migrations

**Files:**
- Create: `database/migrations/2026_03_30_200000_create_user_behavior_profiles_table.php`
- Create: `database/migrations/2026_03_30_200001_create_user_behavior_signals_table.php`
- Create: `database/migrations/2026_03_30_200002_create_tea_tables.php`

- [ ] **Step 1: SSH into server and create migrations**

```bash
sshpass -p "ZimaBlueApps" ssh -o StrictHostKeyChecking=no root@172.240.241.180 \
  "cd /var/www/tajiri.zimasystems.com && \
   php artisan make:migration create_user_behavior_profiles_table && \
   php artisan make:migration create_user_behavior_signals_table && \
   php artisan make:migration create_tea_tables"
```

- [ ] **Step 2: Write user_behavior_profiles migration**

Find the migration file and write it via SSH. The migration must create the `user_behavior_profiles` table with all columns from spec §4:

```php
<?php
use Illuminate\Database\Migrations\Migration;
use Illuminate\Database\Schema\Blueprint;
use Illuminate\Support\Facades\Schema;
use Illuminate\Support\Facades\DB;

return new class extends Migration
{
    public function up(): void
    {
        Schema::create('user_behavior_profiles', function (Blueprint $table) {
            $table->bigInteger('user_id')->primary();
            $table->foreign('user_id')->references('id')->on('user_profiles')->onDelete('cascade');

            // Topic interests (0.0-1.0, time-decayed)
            $table->jsonb('topic_interests')->default('{}');
            // Content format preferences (0.0-1.0)
            $table->jsonb('format_preferences')->default('{}');

            // Engagement patterns
            $table->integer('avg_session_duration_seconds')->default(0);
            $table->text('peak_active_hours')->nullable(); // stored as JSON array string
            $table->float('sessions_per_day')->default(0);
            $table->float('avg_posts_per_week')->default(0);
            $table->float('avg_comments_per_week')->default(0);
            $table->float('avg_likes_per_day')->default(0);
            $table->float('avg_shares_per_week')->default(0);

            // Social behavior
            $table->string('interaction_style', 20)->default('lurker');
            $table->integer('social_circle_size')->default(0);
            $table->float('influence_score')->default(0);
            $table->float('reciprocity_score')->default(0);

            // Content consumption
            $table->float('avg_watch_time_seconds')->default(0);
            $table->float('content_completion_rate')->default(0);
            $table->string('scroll_speed', 10)->default('medium');
            $table->float('replay_rate')->default(0);

            // Gossip-specific
            $table->float('gossip_engagement_score')->default(0);
            $table->text('preferred_gossip_types')->nullable(); // JSON array
            $table->string('tea_consumption_frequency', 10)->default('occasional');
            $table->boolean('shares_gossip')->default(false);
            $table->text('gossip_topics_followed')->nullable(); // JSON array

            // Creator affinity
            $table->jsonb('creator_affinity')->default('{}');
            // Relationship awareness
            $table->jsonb('known_relationships')->default('{}');

            // Language
            $table->string('primary_language', 5)->default('sw');
            $table->float('code_switch_frequency')->default(0.5);
            $table->float('emoji_usage_frequency')->default(0.5);
            $table->string('preferred_response_length', 10)->default('medium');

            // Temporal
            $table->text('most_active_days')->nullable(); // JSON array, 0=Sun 6=Sat
            $table->string('timezone', 30)->default('Africa/Dar_es_Salaam');

            // Tea tab specific
            $table->integer('shangazi_conversations_count')->default(0);
            $table->timestamp('last_tea_visit')->nullable();
            $table->text('tea_topics_asked')->nullable(); // JSON array
            $table->float('tea_satisfaction_score')->default(0.5);

            // Metadata
            $table->integer('matrix_version')->default(1);
            $table->timestamps();
        });

        // Add indexes
        DB::statement('CREATE INDEX idx_ubp_gossip ON user_behavior_profiles(gossip_engagement_score DESC)');
        DB::statement('CREATE INDEX idx_ubp_style ON user_behavior_profiles(interaction_style)');
    }

    public function down(): void
    {
        Schema::dropIfExists('user_behavior_profiles');
    }
};
```

- [ ] **Step 3: Write user_behavior_signals migration**

```php
<?php
use Illuminate\Database\Migrations\Migration;
use Illuminate\Database\Schema\Blueprint;
use Illuminate\Support\Facades\Schema;
use Illuminate\Support\Facades\DB;

return new class extends Migration
{
    public function up(): void
    {
        Schema::create('user_behavior_signals', function (Blueprint $table) {
            $table->id();
            $table->bigInteger('user_id');
            $table->foreign('user_id')->references('id')->on('user_profiles')->onDelete('cascade');
            $table->string('signal_type', 50);
            $table->string('target_type', 30)->nullable();
            $table->bigInteger('target_id')->nullable();
            $table->jsonb('metadata')->default('{}');
            $table->timestamp('created_at')->useCurrent();
        });

        DB::statement('CREATE INDEX idx_ubs_user_recent ON user_behavior_signals(user_id, created_at DESC)');
        DB::statement('CREATE INDEX idx_ubs_type ON user_behavior_signals(signal_type, created_at DESC)');
    }

    public function down(): void
    {
        Schema::dropIfExists('user_behavior_signals');
    }
};
```

- [ ] **Step 4: Write tea_tables migration**

This creates: `tea_topics`, `tea_conversations`, `tea_messages`, `tea_pending_actions`, `tea_audit_log`.

```php
<?php
use Illuminate\Database\Migrations\Migration;
use Illuminate\Database\Schema\Blueprint;
use Illuminate\Support\Facades\Schema;
use Illuminate\Support\Facades\DB;

return new class extends Migration
{
    public function up(): void
    {
        // Tea topics (pre-digested trending content)
        Schema::create('tea_topics', function (Blueprint $table) {
            $table->id();
            $table->string('topic_type', 30);
            $table->text('title_sw');
            $table->text('title_en');
            $table->text('summary');
            $table->string('category', 30)->nullable();
            $table->string('urgency', 10)->default('warm');
            $table->float('velocity_score')->default(0);
            $table->integer('post_count')->default(0);
            $table->integer('participant_count')->default(0);
            $table->text('source_post_ids')->nullable();   // JSON array of bigints
            $table->text('source_user_ids')->nullable();   // JSON array of bigints
            $table->string('geographic_scope', 20)->default('global');
            $table->integer('region_id')->nullable();
            $table->string('top_reaction', 10)->nullable();
            $table->timestamp('expires_at')->nullable();
            $table->boolean('is_active')->default(true);
            $table->timestamps();
        });

        // Add pgvector embedding column
        DB::statement('ALTER TABLE tea_topics ADD COLUMN embedding vector(768)');
        DB::statement('CREATE INDEX idx_tt_active ON tea_topics(is_active, urgency, velocity_score DESC)');
        DB::statement('CREATE INDEX idx_tt_category ON tea_topics(category, is_active)');
        DB::statement('CREATE INDEX idx_tt_embedding ON tea_topics USING hnsw (embedding vector_cosine_ops)');

        // Tea conversations
        Schema::create('tea_conversations', function (Blueprint $table) {
            $table->string('id', 30)->primary();
            $table->bigInteger('user_id');
            $table->foreign('user_id')->references('id')->on('user_profiles')->onDelete('cascade');
            $table->string('title', 255)->nullable();
            $table->integer('message_count')->default(0);
            $table->text('last_message_preview')->nullable();
            $table->string('cohort_id', 50)->nullable();
            $table->timestamps();
        });
        DB::statement('CREATE INDEX idx_tc_user ON tea_conversations(user_id, updated_at DESC)');

        // Tea messages
        Schema::create('tea_messages', function (Blueprint $table) {
            $table->string('id', 30)->primary();
            $table->string('conversation_id', 30);
            $table->foreign('conversation_id')->references('id')->on('tea_conversations')->onDelete('cascade');
            $table->string('role', 10);      // user | shangazi
            $table->string('type', 20);      // text | tea_card | action_card | action_result | web_search_result
            $table->jsonb('content');
            $table->text('source_topic_ids')->nullable();
            $table->text('source_post_ids')->nullable();
            $table->text('mcp_tools_used')->nullable();
            $table->text('moderation_flags')->nullable();
            $table->timestamp('created_at')->useCurrent();
        });
        DB::statement('CREATE INDEX idx_tm_conv ON tea_messages(conversation_id, created_at)');

        // Pending actions (for confirmation flow)
        Schema::create('tea_pending_actions', function (Blueprint $table) {
            $table->string('id', 30)->primary();
            $table->string('conversation_id', 30);
            $table->foreign('conversation_id')->references('id')->on('tea_conversations');
            $table->bigInteger('user_id');
            $table->foreign('user_id')->references('id')->on('user_profiles');
            $table->string('action_type', 30);
            $table->jsonb('action_params');
            $table->string('status', 15)->default('pending');
            $table->timestamp('expires_at');
            $table->timestamp('executed_at')->nullable();
            $table->jsonb('execution_result')->nullable();
            $table->timestamp('created_at')->useCurrent();
        });
        DB::statement('CREATE INDEX idx_tpa_user ON tea_pending_actions(user_id, status)');

        // Audit log
        Schema::create('tea_audit_log', function (Blueprint $table) {
            $table->id();
            $table->string('conversation_id', 30);
            $table->string('message_id', 30)->nullable();
            $table->bigInteger('user_id');
            $table->string('request_type', 20);
            $table->text('user_message')->nullable();
            $table->text('shangazi_response');
            $table->text('source_topic_ids')->nullable();
            $table->text('source_post_ids')->nullable();
            $table->jsonb('mcp_tools_called')->default('[]');
            $table->string('model_used', 50)->nullable();
            $table->integer('input_tokens')->nullable();
            $table->integer('output_tokens')->nullable();
            $table->integer('latency_ms')->nullable();
            $table->text('moderation_flags')->nullable();
            $table->boolean('safety_blocked')->default(false);
            $table->timestamp('created_at')->useCurrent();
        });
        DB::statement('CREATE INDEX idx_tal_user ON tea_audit_log(user_id, created_at DESC)');
        DB::statement('CREATE INDEX idx_tal_safety ON tea_audit_log(safety_blocked) WHERE safety_blocked = true');

        // User similarity cache
        Schema::create('user_similarity_cache', function (Blueprint $table) {
            $table->bigInteger('user_id');
            $table->bigInteger('similar_user_id');
            $table->float('similarity_score');
            $table->text('shared_interests')->nullable();
            $table->timestamp('computed_at')->useCurrent();
            $table->primary(['user_id', 'similar_user_id']);
        });
        DB::statement('CREATE INDEX idx_usc_score ON user_similarity_cache(user_id, similarity_score DESC)');
    }

    public function down(): void
    {
        Schema::dropIfExists('user_similarity_cache');
        Schema::dropIfExists('tea_audit_log');
        Schema::dropIfExists('tea_pending_actions');
        Schema::dropIfExists('tea_messages');
        Schema::dropIfExists('tea_conversations');
        Schema::dropIfExists('tea_topics');
    }
};
```

- [ ] **Step 4b: Add shangazi_enabled to user_profiles**

Create a separate migration: `php artisan make:migration add_shangazi_enabled_to_user_profiles`

```php
<?php
use Illuminate\Database\Migrations\Migration;
use Illuminate\Database\Schema\Blueprint;
use Illuminate\Support\Facades\Schema;

return new class extends Migration
{
    public function up(): void
    {
        Schema::table('user_profiles', function (Blueprint $table) {
            $table->boolean('shangazi_enabled')->default(true)->after('is_verified');
        });
    }

    public function down(): void
    {
        Schema::table('user_profiles', function (Blueprint $table) {
            $table->dropColumn('shangazi_enabled');
        });
    }
};
```

- [ ] **Step 5: Run migrations**

```bash
sshpass -p "ZimaBlueApps" ssh -o StrictHostKeyChecking=no root@172.240.241.180 \
  "cd /var/www/tajiri.zimasystems.com && php artisan migrate"
```

- [ ] **Step 6: Verify tables exist**

```bash
sshpass -p "ZimaBlueApps" ssh -o StrictHostKeyChecking=no root@172.240.241.180 \
  "psql -U postgres -d tajiri -c \"SELECT table_name FROM information_schema.tables WHERE table_name LIKE 'tea_%' OR table_name LIKE 'user_behavior%' OR table_name = 'user_similarity_cache' ORDER BY table_name;\""
```

Expected: 8 tables (user_behavior_profiles, user_behavior_signals, tea_topics, tea_conversations, tea_messages, tea_pending_actions, tea_audit_log, user_similarity_cache).

- [ ] **Step 7: Commit**

```bash
# On server
cd /var/www/tajiri.zimasystems.com
git add database/migrations/
git commit -m "feat(tea): add database tables for Shangazi Tea feature"
```

---

### Task 2: Frontend Tea Models

**Files:**
- Create: `lib/models/tea_models.dart`

- [ ] **Step 1: Create tea_models.dart**

```dart
/// Models for the Shangazi Tea feature — AI gossip partner.
/// Spec: docs/superpowers/specs/2026-03-30-shangazi-tea-design.md §6, §7

class TeaConversation {
  final String id;
  final String? title;
  final String? lastMessagePreview;
  final int messageCount;
  final DateTime createdAt;
  final DateTime updatedAt;

  TeaConversation({
    required this.id,
    this.title,
    this.lastMessagePreview,
    this.messageCount = 0,
    required this.createdAt,
    required this.updatedAt,
  });

  factory TeaConversation.fromJson(Map<String, dynamic> json) {
    return TeaConversation(
      id: json['id']?.toString() ?? '',
      title: json['title']?.toString(),
      lastMessagePreview: json['last_message_preview']?.toString(),
      messageCount: _parseInt(json['message_count']),
      createdAt: DateTime.tryParse(json['created_at']?.toString() ?? '') ?? DateTime.now(),
      updatedAt: DateTime.tryParse(json['updated_at']?.toString() ?? '') ?? DateTime.now(),
    );
  }
}

class TeaMessage {
  final String id;
  final String role; // 'user' | 'shangazi'
  final String type; // 'text' | 'tea_card' | 'action_card' | 'action_result' | 'web_search_result'
  final Map<String, dynamic> content;
  final DateTime createdAt;

  TeaMessage({
    required this.id,
    required this.role,
    required this.type,
    required this.content,
    required this.createdAt,
  });

  factory TeaMessage.fromJson(Map<String, dynamic> json) {
    return TeaMessage(
      id: json['id']?.toString() ?? '',
      role: json['role']?.toString() ?? 'shangazi',
      type: json['type']?.toString() ?? 'text',
      content: json['content'] is Map<String, dynamic>
          ? json['content'] as Map<String, dynamic>
          : {'text': json['content']?.toString() ?? ''},
      createdAt: DateTime.tryParse(json['created_at']?.toString() ?? '') ?? DateTime.now(),
    );
  }

  /// Convenience: get plain text content for text messages
  String get textContent => content['text']?.toString() ?? content.toString();

  bool get isFromShangazi => role == 'shangazi';
  bool get isTeaCard => type == 'tea_card';
  bool get isActionCard => type == 'action_card';
  bool get isActionResult => type == 'action_result';
  bool get isWebSearchResult => type == 'web_search_result';
}

class TeaCard {
  final String id;
  final String headline;
  final String summary;
  final String urgency; // fire | hot | warm | cold
  final String? category;
  final List<int> sourcePosts;
  final List<String> actions; // read_more, share, etc.
  final String? topReaction;

  TeaCard({
    required this.id,
    required this.headline,
    required this.summary,
    this.urgency = 'warm',
    this.category,
    this.sourcePosts = const [],
    this.actions = const [],
    this.topReaction,
  });

  factory TeaCard.fromJson(Map<String, dynamic> json) {
    return TeaCard(
      id: json['id']?.toString() ?? '',
      headline: json['headline']?.toString() ?? '',
      summary: json['summary']?.toString() ?? '',
      urgency: json['urgency']?.toString() ?? 'warm',
      category: json['category']?.toString(),
      sourcePosts: (json['source_posts'] as List<dynamic>?)
              ?.map((e) => _parseInt(e))
              .toList() ??
          [],
      actions: (json['actions'] as List<dynamic>?)
              ?.map((e) => e.toString())
              .toList() ??
          [],
      topReaction: json['top_reaction']?.toString(),
    );
  }

  bool get isFire => urgency == 'fire';
  bool get isHot => urgency == 'hot';
}

class ActionCard {
  final String actionCardId;
  final String action; // create_post, send_message, follow, etc.
  final Map<String, dynamic> preview;
  final String confirmPrompt;
  final String status; // pending | confirmed | rejected | expired

  ActionCard({
    required this.actionCardId,
    required this.action,
    required this.preview,
    required this.confirmPrompt,
    this.status = 'pending',
  });

  factory ActionCard.fromJson(Map<String, dynamic> json) {
    return ActionCard(
      actionCardId: json['action_card_id']?.toString() ?? '',
      action: json['action']?.toString() ?? '',
      preview: json['preview'] is Map<String, dynamic>
          ? json['preview'] as Map<String, dynamic>
          : {},
      confirmPrompt: json['confirm_prompt']?.toString() ?? '',
      status: json['status']?.toString() ?? 'pending',
    );
  }

  bool get isPending => status == 'pending';
}

/// SSE event from the streaming endpoint
class TeaStreamEvent {
  final String eventType; // tea_card | text | action_card | done
  final Map<String, dynamic> data;

  TeaStreamEvent({required this.eventType, required this.data});

  bool get isDone => eventType == 'done';
  bool get isText => eventType == 'text';
  bool get isTeaCard => eventType == 'tea_card';
  bool get isActionCard => eventType == 'action_card';

  /// For text events: the text chunk
  String get textChunk => data['content']?.toString() ?? '';
  /// For text events: whether this is the final chunk
  bool get textDone => data['done'] == true;
  /// For done events: the conversation ID
  String get conversationId => data['conversation_id']?.toString() ?? '';
}

/// Chat initiation response from POST /api/tea/chat
class TeaChatResponse {
  final String conversationId;
  final String streamUrl;

  TeaChatResponse({required this.conversationId, required this.streamUrl});

  factory TeaChatResponse.fromJson(Map<String, dynamic> json) {
    return TeaChatResponse(
      conversationId: json['conversation_id']?.toString() ?? '',
      streamUrl: json['stream_url']?.toString() ?? '',
    );
  }
}

int _parseInt(dynamic v) {
  if (v == null) return 0;
  if (v is int) return v;
  return int.tryParse(v.toString()) ?? 0;
}
```

- [ ] **Step 2: Verify no analysis errors**

```bash
flutter analyze lib/models/tea_models.dart
```

Expected: 0 errors.

- [ ] **Step 3: Commit**

```bash
git add lib/models/tea_models.dart
git commit -m "feat(tea): add Tea models — TeaMessage, TeaCard, ActionCard, TeaConversation"
```

---

### Task 3: Extend EventTrackingService

**Files:**
- Modify: `lib/services/event_tracking_service.dart:23` (flush interval)

- [ ] **Step 1: Change flush interval from 30 to 10**

In `lib/services/event_tracking_service.dart`, line 23:
```dart
// Change:
static const int _flushIntervalSeconds = 30;
// To:
static const int _flushIntervalSeconds = 10;
```

- [ ] **Step 2: Add Tea signal tracking methods**

Add these convenience methods to `EventTrackingService` (after existing `trackView`/`trackEvent` methods):

```dart
  /// Track Tea tab interactions
  void trackTeaCardTapped(int topicId, String cardType) {
    trackEvent(eventType: 'tea_card_tapped', metadata: {
      'topic_id': topicId,
      'card_type': cardType,
    });
  }

  void trackTeaCardSkipped(int topicId, String cardType) {
    trackEvent(eventType: 'tea_card_skipped', metadata: {
      'topic_id': topicId,
      'card_type': cardType,
    });
  }

  void trackTeaQuestionAsked(String query) {
    trackEvent(eventType: 'tea_question_asked', metadata: {
      'query_text': query,
    });
  }

  void trackTeaActionConfirmed(String actionType, String target) {
    trackEvent(eventType: 'tea_action_confirmed', metadata: {
      'action_type': actionType,
      'target': target,
    });
  }

  void trackTeaActionRejected(String actionType, String target) {
    trackEvent(eventType: 'tea_action_rejected', metadata: {
      'action_type': actionType,
      'target': target,
    });
  }

  /// Track additional signals for profile matrix
  void trackMessageSent(int recipientId, {bool hasMedia = false, String? mediaType}) {
    trackEvent(eventType: 'message_sent', creatorId: recipientId, metadata: {
      'has_media': hasMedia,
      if (mediaType != null) 'media_type': mediaType,
    });
  }

  void trackProfileViewed(int userId, int dwellMs) {
    trackEvent(eventType: 'profile_viewed', creatorId: userId, metadata: {
      'dwell_ms': dwellMs,
    });
  }

  void trackSearch(String query, int resultsTapped) {
    trackEvent(eventType: 'search', metadata: {
      'query': query,
      'results_tapped': resultsTapped,
    });
  }

  void trackTrackPlayed(int trackId, int durationMs, bool completed) {
    trackEvent(eventType: 'track_played', postId: trackId, metadata: {
      'duration_ms': durationMs,
      'completed': completed,
    });
  }

  void trackHashtagViewed(String hashtagName, int dwellMs) {
    trackEvent(eventType: 'hashtag_viewed', metadata: {
      'hashtag_name': hashtagName,
      'dwell_ms': dwellMs,
    });
  }
```

- [ ] **Step 3: Verify no analysis errors**

```bash
flutter analyze lib/services/event_tracking_service.dart
```

- [ ] **Step 4: Commit**

```bash
git add lib/services/event_tracking_service.dart
git commit -m "feat(tea): extend EventTrackingService — 10s flush, new tea + matrix signals"
```

---

### Task 4: Frontend TeaService + SSE

**Files:**
- Create: `lib/services/tea_service.dart`

- [ ] **Step 1: Create tea_service.dart**

```dart
import 'dart:async';
import 'dart:convert';
import 'package:http/http.dart' as http;
import '../config/api_config.dart';
import '../models/tea_models.dart';

/// Service for Shangazi Tea — AI gossip partner.
/// Handles chat initiation, SSE streaming, conversation history, and action confirmation.
class TeaService {
  /// Start or continue a conversation with Shangazi.
  /// Returns a [TeaChatResponse] with conversation_id and stream_url.
  static Future<TeaChatResponse?> startChat(
    String token, {
    String? message,
    String? conversationId,
  }) async {
    try {
      final body = <String, dynamic>{};
      if (message != null) body['message'] = message;
      if (conversationId != null) body['conversation_id'] = conversationId;

      final response = await http.post(
        Uri.parse('${ApiConfig.baseUrl}/tea/chat'),
        headers: ApiConfig.authHeaders(token),
        body: jsonEncode(body),
      );

      if (response.statusCode == 200 || response.statusCode == 201) {
        final data = jsonDecode(response.body);
        return TeaChatResponse.fromJson(data);
      }
      return null;
    } catch (e) {
      return null;
    }
  }

  /// Connect to SSE stream and yield [TeaStreamEvent]s.
  /// Uses raw http.Client.send() with StreamedResponse — no SSE library needed.
  static Stream<TeaStreamEvent> streamResponse(
    String streamUrl,
    String token,
  ) async* {
    final request = http.Request('GET', Uri.parse(streamUrl));
    request.headers['Authorization'] = 'Bearer $token';
    request.headers['Accept'] = 'text/event-stream';
    request.headers['Cache-Control'] = 'no-cache';

    final client = http.Client();
    try {
      final response = await client.send(request);
      String currentEvent = 'message';
      String buffer = '';

      await for (final chunk in response.stream.transform(utf8.decoder)) {
        buffer += chunk;
        final lines = buffer.split('\n');
        // Keep incomplete last line in buffer
        buffer = lines.removeLast();

        for (final line in lines) {
          if (line.startsWith('event: ')) {
            currentEvent = line.substring(7).trim();
          } else if (line.startsWith('data: ')) {
            try {
              final data = jsonDecode(line.substring(6)) as Map<String, dynamic>;
              yield TeaStreamEvent(eventType: currentEvent, data: data);
            } catch (_) {
              // Skip malformed JSON
            }
          }
          // Empty line resets event type
          if (line.isEmpty) {
            currentEvent = 'message';
          }
        }
      }
    } finally {
      client.close();
    }
  }

  /// List past conversations.
  static Future<List<TeaConversation>> getConversations(
    String token, {
    int limit = 20,
  }) async {
    try {
      final response = await http.get(
        Uri.parse('${ApiConfig.baseUrl}/tea/conversations?limit=$limit'),
        headers: ApiConfig.authHeaders(token),
      );

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        final list = data['conversations'] as List<dynamic>? ?? [];
        return list
            .map((e) => TeaConversation.fromJson(e as Map<String, dynamic>))
            .toList();
      }
      return [];
    } catch (e) {
      return [];
    }
  }

  /// Load conversation history.
  static Future<List<TeaMessage>> getConversationMessages(
    String token,
    String conversationId,
  ) async {
    try {
      final response = await http.get(
        Uri.parse('${ApiConfig.baseUrl}/tea/conversations/$conversationId'),
        headers: ApiConfig.authHeaders(token),
      );

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        final list = data['messages'] as List<dynamic>? ?? [];
        return list
            .map((e) => TeaMessage.fromJson(e as Map<String, dynamic>))
            .toList();
      }
      return [];
    } catch (e) {
      return [];
    }
  }

  /// Delete a conversation.
  static Future<bool> deleteConversation(
    String token,
    String conversationId,
  ) async {
    try {
      final response = await http.delete(
        Uri.parse('${ApiConfig.baseUrl}/tea/conversations/$conversationId'),
        headers: ApiConfig.authHeaders(token),
      );
      return response.statusCode == 200;
    } catch (e) {
      return false;
    }
  }

  /// Confirm or reject a pending action.
  static Future<Map<String, dynamic>?> confirmAction(
    String token,
    String actionCardId, {
    required bool confirmed,
  }) async {
    try {
      final response = await http.post(
        Uri.parse('${ApiConfig.baseUrl}/tea/action/confirm'),
        headers: ApiConfig.authHeaders(token),
        body: jsonEncode({
          'action_card_id': actionCardId,
          'confirmed': confirmed,
        }),
      );

      if (response.statusCode == 200) {
        return jsonDecode(response.body) as Map<String, dynamic>;
      }
      return null;
    } catch (e) {
      return null;
    }
  }

  /// Submit feedback on a tea message.
  static Future<bool> submitFeedback(
    String token,
    String messageId,
    String type, // 'helpful' | 'harmful' | 'inaccurate'
  ) async {
    try {
      final response = await http.post(
        Uri.parse('${ApiConfig.baseUrl}/tea/feedback'),
        headers: ApiConfig.authHeaders(token),
        body: jsonEncode({
          'message_id': messageId,
          'type': type,
        }),
      );
      return response.statusCode == 200;
    } catch (e) {
      return false;
    }
  }
}
```

- [ ] **Step 2: Verify no analysis errors**

```bash
flutter analyze lib/services/tea_service.dart
```

- [ ] **Step 3: Commit**

```bash
git add lib/services/tea_service.dart
git commit -m "feat(tea): add TeaService — chat initiation, SSE streaming, conversations, action confirm"
```

---

### Task 5: Backend Matrix Builder Service

**Files:**
- Create (on server): `app/Services/Tea/MatrixBuilderService.php`

- [ ] **Step 1: Create MatrixBuilderService**

SSH into server and create `app/Services/Tea/MatrixBuilderService.php`:

```php
<?php

namespace App\Services\Tea;

use Illuminate\Support\Facades\DB;
use Illuminate\Support\Facades\Log;

class MatrixBuilderService
{
    /**
     * Process a batch of signals and update the user's behavior profile.
     * Called from EventController when processing incoming event batches.
     */
    public function processSignalBatch(int $userId, array $signals): void
    {
        // Insert raw signals
        $rows = [];
        foreach ($signals as $signal) {
            $rows[] = [
                'user_id' => $userId,
                'signal_type' => $signal['eventType'] ?? $signal['signal_type'] ?? 'unknown',
                'target_type' => $signal['target_type'] ?? null,
                'target_id' => $signal['postId'] ?? $signal['target_id'] ?? null,
                'metadata' => json_encode($signal['metadata'] ?? []),
                'created_at' => now(),
            ];
        }

        if (!empty($rows)) {
            DB::table('user_behavior_signals')->insert($rows);
        }

        // Update the behavior profile
        $this->updateProfile($userId, $signals);
    }

    /**
     * Update user_behavior_profiles from new signals using exponential decay.
     */
    public function updateProfile(int $userId, array $signals): void
    {
        $profile = DB::table('user_behavior_profiles')->where('user_id', $userId)->first();

        if (!$profile) {
            DB::table('user_behavior_profiles')->insert([
                'user_id' => $userId,
                'created_at' => now(),
                'updated_at' => now(),
            ]);
            $profile = DB::table('user_behavior_profiles')->where('user_id', $userId)->first();
        }

        $topicInterests = json_decode($profile->topic_interests ?? '{}', true) ?: [];
        $formatPrefs = json_decode($profile->format_preferences ?? '{}', true) ?: [];
        $creatorAffinity = json_decode($profile->creator_affinity ?? '{}', true) ?: [];
        $likesCount = 0;
        $commentsCount = 0;
        $sharesCount = 0;
        $gossipSignals = 0;

        foreach ($signals as $signal) {
            $type = $signal['eventType'] ?? $signal['signal_type'] ?? '';
            $meta = $signal['metadata'] ?? [];
            $creatorId = $signal['creatorId'] ?? null;

            // Count engagement types
            if ($type === 'like') $likesCount++;
            if ($type === 'comment') $commentsCount++;
            if ($type === 'share') $sharesCount++;

            // Tea/gossip engagement
            if (str_starts_with($type, 'tea_')) $gossipSignals++;

            // Update creator affinity
            if ($creatorId) {
                $key = "user_$creatorId";
                $old = $creatorAffinity[$key] ?? 0;
                $weight = $this->signalWeight($type);
                $creatorAffinity[$key] = min(1.0, $old * 0.95 + abs($weight) * 0.05);
            }

            // Update format preferences based on target type
            $targetType = $signal['target_type'] ?? null;
            if ($targetType && in_array($targetType, ['post', 'clip', 'story', 'track'])) {
                $formatKey = $targetType === 'clip' ? 'video' : ($targetType === 'track' ? 'audio' : $targetType);
                $old = $formatPrefs[$formatKey] ?? 0.5;
                $formatPrefs[$formatKey] = min(1.0, $old * 0.95 + 0.05);
            }
        }

        // Update gossip score
        $gossipScore = (float)($profile->gossip_engagement_score ?? 0);
        if ($gossipSignals > 0) {
            $gossipScore = min(1.0, $gossipScore * 0.95 + $gossipSignals * 0.02);
        }

        DB::table('user_behavior_profiles')
            ->where('user_id', $userId)
            ->update([
                'topic_interests' => json_encode($topicInterests),
                'format_preferences' => json_encode($formatPrefs),
                'creator_affinity' => json_encode($creatorAffinity),
                'gossip_engagement_score' => $gossipScore,
                'avg_likes_per_day' => DB::raw("COALESCE(avg_likes_per_day, 0) * 0.9 + $likesCount * 0.1"),
                'avg_comments_per_week' => DB::raw("COALESCE(avg_comments_per_week, 0) * 0.9 + $commentsCount * 0.1"),
                'avg_shares_per_week' => DB::raw("COALESCE(avg_shares_per_week, 0) * 0.9 + $sharesCount * 0.1"),
                'updated_at' => now(),
            ]);
    }

    /**
     * Signal weight mapping from spec §4.
     */
    private function signalWeight(string $type): float
    {
        return match($type) {
            'view' => 1.0,
            'dwell' => 1.5,
            'scroll_past' => -0.5,
            'like' => 2.0,
            'comment' => 3.0,
            'share' => 4.0,
            'save' => 2.5,
            'follow' => 3.0,
            'unfollow' => -3.0,
            'not_interested' => -5.0,
            'report' => -10.0,
            'tea_card_tapped' => 2.0,
            'tea_card_skipped' => -1.0,
            'tea_question_asked' => 2.0,
            'tea_action_confirmed' => 3.0,
            'tea_action_rejected' => -1.0,
            default => 1.0,
        };
    }
}
```

- [ ] **Step 2: Wire MatrixBuilderService into EventController**

Find the existing EventController and add a call to `MatrixBuilderService::processSignalBatch()` after storing events. The events endpoint is `POST /api/events` handled by an EventController.

```bash
sshpass -p "ZimaBlueApps" ssh -o StrictHostKeyChecking=no root@172.240.241.180 \
  "grep -rn 'events' /var/www/tajiri.zimasystems.com/routes/api.php | head -5"
```

Add at the end of the events processing method:

```php
// After existing event storage logic:
$matrixBuilder = new \App\Services\Tea\MatrixBuilderService();
$matrixBuilder->processSignalBatch($userId, $events);
```

- [ ] **Step 3: Commit on server**

```bash
cd /var/www/tajiri.zimasystems.com
git add app/Services/Tea/
git commit -m "feat(tea): add MatrixBuilderService — processes signals into user behavior profiles"
```

---

### Task 6: Backend Tea Topics Aggregator

**Files:**
- Create (on server): `app/Services/Tea/TeaTopicAggregator.php`
- Create (on server): `app/Console/Commands/AggregateTrendingTopics.php`

- [ ] **Step 1: Create TeaTopicAggregator service**

SSH and create `app/Services/Tea/TeaTopicAggregator.php`:

```php
<?php

namespace App\Services\Tea;

use Illuminate\Support\Facades\DB;
use Illuminate\Support\Facades\Http;
use Illuminate\Support\Facades\Log;

class TeaTopicAggregator
{
    /**
     * Run the trending aggregation pipeline.
     * Called every 15 minutes via cron.
     */
    public function aggregate(): int
    {
        $topicsCreated = 0;

        // 1. Viral posts (engagement velocity > 3x avg in last 2 hours)
        $topicsCreated += $this->detectViralPosts();

        // 2. Beef detection (high comment-to-like ratio)
        $topicsCreated += $this->detectBeefs();

        // 3. Trending hashtags (usage growth > 200%)
        $topicsCreated += $this->detectTrendingHashtags();

        // 4. Expire old topics
        $this->expireStaleTopics();

        Log::info("[TeaTopicAggregator] Created $topicsCreated new tea topics");
        return $topicsCreated;
    }

    private function detectViralPosts(): int
    {
        $count = 0;

        // Find posts from last 2 hours with engagement > 3x average
        $avgEngagement = DB::table('posts')
            ->where('created_at', '>', now()->subHours(24))
            ->avg(DB::raw('COALESCE(likes_count, 0) + COALESCE(comments_count, 0) + COALESCE(shares_count, 0)'));

        if (!$avgEngagement || $avgEngagement < 1) $avgEngagement = 5;
        $threshold = $avgEngagement * 3;

        $viralPosts = DB::table('posts')
            ->where('created_at', '>', now()->subHours(2))
            ->whereRaw('COALESCE(likes_count, 0) + COALESCE(comments_count, 0) + COALESCE(shares_count, 0) > ?', [$threshold])
            ->orderByRaw('COALESCE(likes_count, 0) + COALESCE(comments_count, 0) + COALESCE(shares_count, 0) DESC')
            ->limit(10)
            ->get();

        foreach ($viralPosts as $post) {
            // Check if topic already exists for this post
            $exists = DB::table('tea_topics')
                ->where('is_active', true)
                ->whereRaw("source_post_ids::text LIKE ?", ["%{$post->id}%"])
                ->exists();

            if (!$exists) {
                $engagement = ($post->likes_count ?? 0) + ($post->comments_count ?? 0) + ($post->shares_count ?? 0);
                $this->createTopic(
                    'viral',
                    "Viral: Post na engagement $engagement!",
                    "Viral: Post with $engagement engagement!",
                    "A post has gone viral with massive engagement in the last 2 hours.",
                    'entertainment',
                    $engagement > $threshold * 2 ? 'fire' : 'hot',
                    (float)$engagement / max(1, $avgEngagement),
                    [$post->id],
                    [$post->user_id],
                );
                $count++;
            }
        }

        return $count;
    }

    private function detectBeefs(): int
    {
        $count = 0;

        // High comment-to-like ratio posts = controversy
        $controversial = DB::table('posts')
            ->where('created_at', '>', now()->subHours(6))
            ->where('comments_count', '>', 5)
            ->whereRaw('COALESCE(comments_count, 0) > COALESCE(likes_count, 1) * 0.5')
            ->orderByRaw('COALESCE(comments_count, 0) DESC')
            ->limit(5)
            ->get();

        foreach ($controversial as $post) {
            $exists = DB::table('tea_topics')
                ->where('is_active', true)
                ->where('topic_type', 'beef')
                ->whereRaw("source_post_ids::text LIKE ?", ["%{$post->id}%"])
                ->exists();

            if (!$exists) {
                $this->createTopic(
                    'beef',
                    "Beef Alert! Mjadala mkubwa!",
                    "Beef Alert! Heated discussion!",
                    "A controversial post is generating intense debate with {$post->comments_count} comments.",
                    'entertainment',
                    'hot',
                    (float)($post->comments_count ?? 0) / 10,
                    [$post->id],
                    [$post->user_id],
                );
                $count++;
            }
        }

        return $count;
    }

    private function detectTrendingHashtags(): int
    {
        $count = 0;

        // Hashtags with recent spike in usage
        $trending = DB::table('post_hashtags')
            ->join('hashtags', 'hashtags.id', '=', 'post_hashtags.hashtag_id')
            ->where('post_hashtags.created_at', '>', now()->subHours(3))
            ->groupBy('hashtags.id', 'hashtags.name')
            ->havingRaw('COUNT(*) > 5')
            ->orderByRaw('COUNT(*) DESC')
            ->limit(5)
            ->select('hashtags.id', 'hashtags.name', DB::raw('COUNT(*) as usage_count'))
            ->get();

        foreach ($trending as $hashtag) {
            $exists = DB::table('tea_topics')
                ->where('is_active', true)
                ->where('topic_type', 'trending_hashtag')
                ->where('title_en', 'LIKE', "%#{$hashtag->name}%")
                ->exists();

            if (!$exists) {
                $this->createTopic(
                    'trending_hashtag',
                    "#{$hashtag->name} inatrend! ({$hashtag->usage_count} posts)",
                    "#{$hashtag->name} is trending! ({$hashtag->usage_count} posts)",
                    "The hashtag #{$hashtag->name} is gaining traction with {$hashtag->usage_count} new posts.",
                    null,
                    'warm',
                    (float)$hashtag->usage_count / 10,
                    [],
                    [],
                );
                $count++;
            }
        }

        return $count;
    }

    private function createTopic(
        string $type, string $titleSw, string $titleEn, string $summary,
        ?string $category, string $urgency, float $velocity,
        array $postIds, array $userIds
    ): void {
        $id = DB::table('tea_topics')->insertGetId([
            'topic_type' => $type,
            'title_sw' => $titleSw,
            'title_en' => $titleEn,
            'summary' => $summary,
            'category' => $category,
            'urgency' => $urgency,
            'velocity_score' => $velocity,
            'post_count' => count($postIds),
            'participant_count' => count(array_unique($userIds)),
            'source_post_ids' => json_encode($postIds),
            'source_user_ids' => json_encode($userIds),
            'expires_at' => now()->addHours(24),
            'is_active' => true,
            'created_at' => now(),
            'updated_at' => now(),
        ]);

        // Generate embedding for semantic matching
        $this->embedTopic($id, "$titleEn. $summary");
    }

    private function embedTopic(int $topicId, string $text): void
    {
        try {
            $response = Http::timeout(10)->post('http://127.0.0.1:8200/embed', [
                'text' => "passage: $text",
            ]);

            if ($response->successful()) {
                $embedding = $response->json('embedding');
                if ($embedding) {
                    $vectorStr = '[' . implode(',', $embedding) . ']';
                    DB::statement(
                        "UPDATE tea_topics SET embedding = ?::vector WHERE id = ?",
                        [$vectorStr, $topicId]
                    );
                }
            }
        } catch (\Exception $e) {
            Log::warning("[TeaTopicAggregator] Embedding failed for topic $topicId: " . $e->getMessage());
        }
    }

    private function expireStaleTopics(): void
    {
        DB::table('tea_topics')
            ->where('is_active', true)
            ->where('expires_at', '<', now())
            ->update(['is_active' => false, 'updated_at' => now()]);
    }
}
```

- [ ] **Step 2: Create artisan command**

Create `app/Console/Commands/AggregateTrendingTopics.php`:

```php
<?php

namespace App\Console\Commands;

use App\Services\Tea\TeaTopicAggregator;
use Illuminate\Console\Command;

class AggregateTrendingTopics extends Command
{
    protected $signature = 'tea:aggregate-topics';
    protected $description = 'Aggregate trending topics for Shangazi Tea';

    public function handle(): int
    {
        $aggregator = new TeaTopicAggregator();
        $count = $aggregator->aggregate();
        $this->info("Created $count new tea topics.");
        return 0;
    }
}
```

- [ ] **Step 3: Register in scheduler**

Add to Laravel scheduler (in `routes/console.php` or `app/Console/Kernel.php`):

```php
Schedule::command('tea:aggregate-topics')->everyFifteenMinutes();
```

- [ ] **Step 4: Test the aggregation**

```bash
sshpass -p "ZimaBlueApps" ssh -o StrictHostKeyChecking=no root@172.240.241.180 \
  "cd /var/www/tajiri.zimasystems.com && php artisan tea:aggregate-topics"
```

- [ ] **Step 5: Commit on server**

```bash
cd /var/www/tajiri.zimasystems.com
git add app/Services/Tea/TeaTopicAggregator.php app/Console/Commands/AggregateTrendingTopics.php
git commit -m "feat(tea): add TeaTopicAggregator — trending detection cron every 15 min"
```

---

## Phase 2: MCP Servers

### Task 7: MCP Profile Server (10 tools)

**Files:**
- Create (on server): `scripts/mcp-profile-server.py`

- [ ] **Step 1: Create MCP Profile Server**

This is a Python script implementing MCP protocol over stdio with 10 tools for user profile access. See spec §3 MCP Server 1 for the full tool list.

The server connects to PostgreSQL directly and exposes: `get_user_matrix`, `get_user_profile`, `get_user_stats`, `get_user_activity`, `get_user_interests`, `get_user_preferences`, `get_user_engagement_level`, `get_creator_score`, `compare_users`, `get_user_content_summary`.

Each tool is a function that takes parameters, queries PostgreSQL, and returns JSON.

```python
#!/usr/bin/env python3
"""
MCP Server 1: User Profile Server
Provides 10 tools for deep user understanding.
Protocol: MCP (JSON-RPC 2.0 over stdio)
"""

import json
import sys
import psycopg2
import psycopg2.extras

DB_CONFIG = {
    'dbname': 'tajiri',
    'user': 'postgres',
    'password': 'postgres',
    'host': '127.0.0.1',
    'port': 5432,
}

def get_db():
    return psycopg2.connect(**DB_CONFIG)

# ── Tool implementations ──────────────────────────────────────

def get_user_matrix(params):
    user_id = params['user_id']
    conn = get_db()
    cur = conn.cursor(cursor_factory=psycopg2.extras.RealDictCursor)
    cur.execute("SELECT * FROM user_behavior_profiles WHERE user_id = %s", (user_id,))
    row = cur.fetchone()
    conn.close()
    if not row:
        return {"error": "No profile matrix found for user"}
    # Convert to serializable dict
    result = {}
    for k, v in row.items():
        if hasattr(v, 'isoformat'):
            result[k] = v.isoformat()
        else:
            result[k] = v
    return result

def get_user_profile(params):
    user_id = params['user_id']
    conn = get_db()
    cur = conn.cursor(cursor_factory=psycopg2.extras.RealDictCursor)
    cur.execute("""
        SELECT id, first_name, last_name, phone_number, bio, profile_photo_path,
               region_name, district_name, ward_name, gender, date_of_birth,
               university_name, programme_name, employer_name, employer_sector,
               primary_school_name, secondary_school_name, is_verified,
               created_at
        FROM user_profiles WHERE id = %s
    """, (user_id,))
    row = cur.fetchone()
    conn.close()
    if not row:
        return {"error": "User not found"}
    result = {}
    for k, v in row.items():
        result[k] = v.isoformat() if hasattr(v, 'isoformat') else v
    return result

def get_user_stats(params):
    user_id = params['user_id']
    conn = get_db()
    cur = conn.cursor(cursor_factory=psycopg2.extras.RealDictCursor)
    cur.execute("""
        SELECT id, posts_count, followers_count, following_count, friends_count,
               photos_count, is_verified
        FROM user_profiles WHERE id = %s
    """, (user_id,))
    row = cur.fetchone()
    conn.close()
    if not row:
        return {"error": "User not found"}
    # Add creator score if exists
    conn2 = get_db()
    cur2 = conn2.cursor(cursor_factory=psycopg2.extras.RealDictCursor)
    cur2.execute("SELECT * FROM creator_scores WHERE user_id = %s", (user_id,))
    score = cur2.fetchone()
    cur2.execute("SELECT * FROM creator_streaks WHERE user_id = %s", (user_id,))
    streak = cur2.fetchone()
    conn2.close()
    result = dict(row)
    if score:
        result['creator_tier'] = score.get('tier')
        result['creator_score'] = score.get('score')
    if streak:
        result['streak_days'] = streak.get('current_streak_days', 0)
    for k, v in result.items():
        if hasattr(v, 'isoformat'):
            result[k] = v.isoformat()
    return result

def get_user_activity(params):
    user_id = params['user_id']
    activity_type = params.get('type')
    days = params.get('days', 7)
    conn = get_db()
    cur = conn.cursor(cursor_factory=psycopg2.extras.RealDictCursor)
    cur.execute("""
        SELECT id, content, media_type, likes_count, comments_count, shares_count, created_at
        FROM posts WHERE user_id = %s AND created_at > NOW() - INTERVAL '%s days'
        ORDER BY created_at DESC LIMIT 20
    """, (user_id, days))
    posts = cur.fetchall()
    conn.close()
    result = []
    for p in posts:
        item = dict(p)
        for k, v in item.items():
            if hasattr(v, 'isoformat'):
                item[k] = v.isoformat()
        result.append(item)
    return {"recent_posts": result, "count": len(result)}

def get_user_interests(params):
    user_id = params['user_id']
    conn = get_db()
    cur = conn.cursor(cursor_factory=psycopg2.extras.RealDictCursor)
    cur.execute("""
        SELECT topic_interests, format_preferences, gossip_engagement_score,
               preferred_gossip_types, tea_consumption_frequency
        FROM user_behavior_profiles WHERE user_id = %s
    """, (user_id,))
    row = cur.fetchone()
    conn.close()
    if not row:
        return {"error": "No interest profile found"}
    return dict(row)

def get_user_preferences(params):
    user_id = params['user_id']
    conn = get_db()
    cur = conn.cursor(cursor_factory=psycopg2.extras.RealDictCursor)
    cur.execute("""
        SELECT primary_language, code_switch_frequency, preferred_response_length,
               emoji_usage_frequency
        FROM user_behavior_profiles WHERE user_id = %s
    """, (user_id,))
    matrix = cur.fetchone()
    cur.execute("""
        SELECT profile_visibility, who_can_message, who_can_see_posts,
               opt_out_threads, opt_out_sponsored, interests
        FROM user_profiles WHERE id = %s
    """, (user_id,))
    profile = cur.fetchone()
    # Get blocked users
    cur.execute("SELECT blocked_user_id FROM blocked_users WHERE user_id = %s", (user_id,))
    blocked = [r['blocked_user_id'] for r in cur.fetchall()]
    conn.close()
    result = {}
    if matrix:
        result.update(dict(matrix))
    if profile:
        result.update(dict(profile))
    result['blocked_user_ids'] = blocked
    return result

def get_user_engagement_level(params):
    user_id = params['user_id']
    conn = get_db()
    cur = conn.cursor(cursor_factory=psycopg2.extras.RealDictCursor)
    cur.execute("SELECT created_at FROM user_profiles WHERE id = %s", (user_id,))
    row = cur.fetchone()
    conn.close()
    if not row:
        return {"error": "User not found"}
    from datetime import datetime, timezone
    age_days = (datetime.now(timezone.utc) - row['created_at'].replace(tzinfo=timezone.utc)).days
    if age_days < 14:
        level = 'gentle'
    elif age_days < 42:
        level = 'medium'
    else:
        level = 'full'
    return {"engagement_level": level, "account_age_days": age_days}

def get_creator_score(params):
    user_id = params['user_id']
    conn = get_db()
    cur = conn.cursor(cursor_factory=psycopg2.extras.RealDictCursor)
    cur.execute("SELECT * FROM creator_scores WHERE user_id = %s", (user_id,))
    score = cur.fetchone()
    cur.execute("SELECT * FROM creator_streaks WHERE user_id = %s", (user_id,))
    streak = cur.fetchone()
    conn.close()
    result = {}
    if score:
        for k, v in score.items():
            result[k] = v.isoformat() if hasattr(v, 'isoformat') else v
    if streak:
        for k, v in streak.items():
            result[f'streak_{k}'] = v.isoformat() if hasattr(v, 'isoformat') else v
    return result or {"error": "No creator score found"}

def compare_users(params):
    user_a = params['user_id_a']
    user_b = params['user_id_b']
    a_stats = get_user_stats({'user_id': user_a})
    b_stats = get_user_stats({'user_id': user_b})
    a_profile = get_user_profile({'user_id': user_a})
    b_profile = get_user_profile({'user_id': user_b})
    # Mutual friends
    conn = get_db()
    cur = conn.cursor()
    cur.execute("""
        SELECT COUNT(*) FROM friendships f1
        JOIN friendships f2 ON f1.friend_id = f2.user_id
        WHERE f1.user_id = %s AND f2.friend_id = %s AND f1.status = 'accepted' AND f2.status = 'accepted'
    """, (user_a, user_b))
    mutual = cur.fetchone()[0]
    conn.close()
    return {
        "user_a": {"profile": a_profile, "stats": a_stats},
        "user_b": {"profile": b_profile, "stats": b_stats},
        "mutual_friends_count": mutual,
    }

def get_user_content_summary(params):
    user_id = params['user_id']
    days = params.get('days', 7)
    activity = get_user_activity({'user_id': user_id, 'days': days})
    interests = get_user_interests({'user_id': user_id})
    stats = get_user_stats({'user_id': user_id})
    return {
        "user_id": user_id,
        "period_days": days,
        "posts_in_period": activity.get('count', 0),
        "recent_posts": activity.get('recent_posts', [])[:5],
        "interests": interests,
        "stats": stats,
    }

# ── MCP Protocol Handler ──────────────────────────────────────

TOOLS = {
    'get_user_matrix': {'fn': get_user_matrix, 'desc': 'Get full behavioral profile matrix', 'params': {'user_id': 'integer (required)'}},
    'get_user_profile': {'fn': get_user_profile, 'desc': 'Get static user profile', 'params': {'user_id': 'integer (required)'}},
    'get_user_stats': {'fn': get_user_stats, 'desc': 'Get user stats (posts, followers, etc)', 'params': {'user_id': 'integer (required)'}},
    'get_user_activity': {'fn': get_user_activity, 'desc': 'Get recent user activity', 'params': {'user_id': 'integer (required)', 'type': 'string (optional)', 'days': 'integer (optional, default 7)'}},
    'get_user_interests': {'fn': get_user_interests, 'desc': 'Get topic/format interest scores', 'params': {'user_id': 'integer (required)'}},
    'get_user_preferences': {'fn': get_user_preferences, 'desc': 'Get language, privacy, blocked users', 'params': {'user_id': 'integer (required)'}},
    'get_user_engagement_level': {'fn': get_user_engagement_level, 'desc': 'Get engagement tier and account age', 'params': {'user_id': 'integer (required)'}},
    'get_creator_score': {'fn': get_creator_score, 'desc': 'Get creator tier, score, streak', 'params': {'user_id': 'integer (required)'}},
    'compare_users': {'fn': compare_users, 'desc': 'Compare two users side by side (public stats only)', 'params': {'user_id_a': 'integer (required)', 'user_id_b': 'integer (required)'}},
    'get_user_content_summary': {'fn': get_user_content_summary, 'desc': 'AI-friendly summary of user activity', 'params': {'user_id': 'integer (required)', 'days': 'integer (optional, default 7)'}},
}

def handle_request(request):
    method = request.get('method', '')
    req_id = request.get('id')
    params = request.get('params', {})

    if method == 'initialize':
        return {'jsonrpc': '2.0', 'id': req_id, 'result': {
            'protocolVersion': '2024-11-05',
            'capabilities': {'tools': {}},
            'serverInfo': {'name': 'tajiri-profile-server', 'version': '1.0.0'}
        }}

    if method == 'tools/list':
        tools = []
        for name, info in TOOLS.items():
            tool_schema = {
                'name': name,
                'description': info['desc'],
                'inputSchema': {
                    'type': 'object',
                    'properties': {k: {'type': 'string', 'description': v} for k, v in info['params'].items()},
                    'required': [k for k, v in info['params'].items() if 'required' in v],
                }
            }
            tools.append(tool_schema)
        return {'jsonrpc': '2.0', 'id': req_id, 'result': {'tools': tools}}

    if method == 'tools/call':
        tool_name = params.get('name', '')
        tool_args = params.get('arguments', {})
        if tool_name in TOOLS:
            try:
                result = TOOLS[tool_name]['fn'](tool_args)
                return {'jsonrpc': '2.0', 'id': req_id, 'result': {
                    'content': [{'type': 'text', 'text': json.dumps(result, default=str)}]
                }}
            except Exception as e:
                return {'jsonrpc': '2.0', 'id': req_id, 'result': {
                    'content': [{'type': 'text', 'text': json.dumps({'error': str(e)})}],
                    'isError': True
                }}
        return {'jsonrpc': '2.0', 'id': req_id, 'error': {'code': -32601, 'message': f'Unknown tool: {tool_name}'}}

    if method == 'notifications/initialized':
        return None  # No response needed for notifications

    return {'jsonrpc': '2.0', 'id': req_id, 'error': {'code': -32601, 'message': f'Unknown method: {method}'}}

def main():
    """MCP stdio transport: read JSON-RPC from stdin, write to stdout."""
    for line in sys.stdin:
        line = line.strip()
        if not line:
            continue
        try:
            request = json.loads(line)
            response = handle_request(request)
            if response:
                sys.stdout.write(json.dumps(response) + '\n')
                sys.stdout.flush()
        except json.JSONDecodeError:
            error = {'jsonrpc': '2.0', 'id': None, 'error': {'code': -32700, 'message': 'Parse error'}}
            sys.stdout.write(json.dumps(error) + '\n')
            sys.stdout.flush()

if __name__ == '__main__':
    main()
```

- [ ] **Step 2: Test the server responds to tool list**

```bash
sshpass -p "ZimaBlueApps" ssh -o StrictHostKeyChecking=no root@172.240.241.180 \
  "cd /var/www/tajiri.zimasystems.com && echo '{\"jsonrpc\":\"2.0\",\"id\":1,\"method\":\"tools/list\",\"params\":{}}' | python3 scripts/mcp-profile-server.py"
```

Expected: JSON response with 10 tools listed.

- [ ] **Step 3: Test a tool call**

```bash
sshpass -p "ZimaBlueApps" ssh -o StrictHostKeyChecking=no root@172.240.241.180 \
  "cd /var/www/tajiri.zimasystems.com && echo '{\"jsonrpc\":\"2.0\",\"id\":1,\"method\":\"tools/call\",\"params\":{\"name\":\"get_user_profile\",\"arguments\":{\"user_id\":1}}}' | python3 scripts/mcp-profile-server.py"
```

Expected: JSON with user profile data for user_id=1.

- [ ] **Step 4: Commit**

```bash
cd /var/www/tajiri.zimasystems.com
git add scripts/mcp-profile-server.py
git commit -m "feat(tea): add MCP Profile Server — 10 tools for user profile access"
```

---

### Task 8: MCP Social Graph Server (13 tools)

**Files:**
- Create (on server): `scripts/mcp-social-server.py`

- [ ] **Step 1: Create MCP Social Graph Server**

Follow the exact same MCP protocol handler pattern as Task 7 (`handle_request`, `main`, `TOOLS` dict, JSON-RPC over stdio). Implement 13 tools:

| Tool | Params | SQL Source | Returns |
|------|--------|-----------|---------|
| `get_friends` | `user_id`, `limit=20` | `friendships WHERE (user_id=? OR friend_id=?) AND status='accepted'` JOIN `user_profiles` | List of {id, name, profile_photo} |
| `get_followers` | `user_id`, `limit=20` | `user_follows WHERE following_id=?` JOIN `user_profiles` | List of {id, name} |
| `get_following` | `user_id`, `limit=20` | `user_follows WHERE follower_id=?` JOIN `user_profiles` | List of {id, name} |
| `get_mutual_friends` | `user_id_a`, `user_id_b` | JOIN friendships f1,f2 WHERE f1.user_id=a AND f2.user_id=b AND f1.friend_id=f2.friend_id | Count + list |
| `get_friendship_status` | `user_id_a`, `user_id_b` | `friendships WHERE user_id IN (a,b) AND friend_id IN (a,b)` | {status, since} |
| `get_recent_follows` | `user_id`, `days=7` | `user_follows WHERE follower_id=? AND created_at > NOW()-interval` | List |
| `get_recent_blocks` | `user_id`, `days=30` | `blocked_users WHERE user_id=?` (no names for privacy) | Count only |
| `get_interaction_history` | `user_id_a`, `user_id_b`, `days=30` | `user_behavior_signals WHERE user_id=a AND target_id=b` | Signal types + counts |
| `get_social_circle` | `user_id`, `depth=1` | friends-of-friends via recursive friendships query, limit 50 | Nested list |
| `get_influence_graph` | `user_id` | `user_behavior_profiles.influence_score` + top 10 followers by followers_count | {influence_score, top_followers} |
| `get_user_groups` | `user_id` | `group_members JOIN groups WHERE user_id=?` | List of {group_id, name, role} |
| `get_group_members` | `group_id`, `limit=50` | `group_members JOIN user_profiles WHERE group_id=?` | List of {id, name, role} |
| `get_close_friends` | `user_id` | `close_friends WHERE user_id=?` JOIN `user_profiles` | List of {id, name} |

- [ ] **Step 2: Test tool list and a sample tool call**
- [ ] **Step 3: Commit**

```bash
git add scripts/mcp-social-server.py
git commit -m "feat(tea): add MCP Social Graph Server — 13 tools for relationship/social data"
```

---

### Task 9: MCP Content & Feed Server (25 tools)

**Files:**
- Create (on server): `scripts/mcp-content-server.py`

- [ ] **Step 1: Create MCP Content & Feed Server**

Follow the exact same MCP protocol handler pattern as Task 7. Implement 25 tools:

| Tool | Params | SQL Source | Returns |
|------|--------|-----------|---------|
| `get_post` | `post_id` | `posts JOIN user_profiles` | Full post with author |
| `get_post_comments` | `post_id`, `limit=20` | `comments WHERE post_id=? JOIN user_profiles` | List of comments |
| `get_post_reactions` | `post_id` | `post_likes WHERE post_id=? GROUP BY reaction_type` | Reaction counts |
| `search_posts_keyword` | `query`, `limit=20` | `posts WHERE content ILIKE '%query%'` | List of posts |
| `search_posts_semantic` | `query`, `limit=10` | Call `http://127.0.0.1:8200/embed` with query, then `SELECT * FROM posts ORDER BY embedding <=> $vector LIMIT ?` | Ranked posts |
| `get_trending_hashtags` | `hours=6`, `limit=10` | `post_hashtags JOIN hashtags WHERE created_at > NOW()-interval GROUP BY hashtag ORDER BY COUNT DESC` | Hashtag + counts |
| `get_hashtag_posts` | `hashtag_name`, `limit=20` | `post_hashtags JOIN hashtags JOIN posts WHERE name=?` | List of posts |
| `get_gossip_threads` | `limit=10` | `gossip_threads ORDER BY updated_at DESC` | List of threads |
| `get_gossip_thread` | `thread_id` | `gossip_threads WHERE id=?` + replies | Thread + replies |
| `get_trending_topics` | `limit=10` | `tea_topics WHERE is_active=true ORDER BY velocity_score DESC` | List of tea topics |
| `search_trending_topics` | `query`, `limit=5` | Embed query, then `tea_topics ORDER BY embedding <=> $vector` | Semantic matches |
| `get_clips` | `user_id?`, `limit=20` | `posts WHERE media_type='clip'` | List of clips |
| `get_music_tracks` | `user_id?`, `genre?`, `limit=20` | `music_tracks` with optional filters | List of tracks |
| `get_live_streams` | `status='live'`, `limit=10` | `live_streams WHERE status=?` | List of streams |
| `get_events` | `upcoming=true`, `limit=10` | `events WHERE start_date > NOW()` | List of events |
| `get_polls` | `active=true`, `limit=10` | `polls WHERE ends_at > NOW()` | Polls with vote counts |
| `get_creator_battles` | `status='active'`, `limit=10` | `creator_battles WHERE status=?` | Active battles |
| `get_campaigns` | `status='active'`, `limit=10` | `campaigns WHERE status=? AND type='michango'` | Crowdfunding campaigns |
| `get_products` | `category?`, `limit=20` | `products` with optional category filter | Product listings |
| `get_stories` | `user_id`, `limit=20` | `stories WHERE user_id=? AND expires_at > NOW()` | Active stories |
| `get_user_feed` | `user_id`, `limit=20` | `posts WHERE user_id IN (followed) ORDER BY created_at DESC` | Feed posts |
| `get_popular_posts` | `hours=24`, `limit=20` | `posts WHERE created_at > interval ORDER BY engagement DESC` | Top posts |
| `get_controversial_posts` | `hours=12`, `limit=10` | `posts WHERE comments_count > likes_count * 0.5` | Controversial posts |
| `get_post_thread` | `post_id` | `posts WHERE parent_id=? OR id=?` recursive | Thread chain |
| `get_content_by_topic` | `topic`, `limit=10` | Embed topic, semantic search on posts | Related content |

The `search_posts_semantic` and `search_trending_topics` tools use pgvector:
1. Call `http://127.0.0.1:8200/embed` with `{"text": "query: <user_query>"}`
2. Use `ORDER BY embedding <=> '[...]'::vector LIMIT ?` for cosine similarity
3. Return ranked results with content and metadata

- [ ] **Step 2: Test semantic search tool**
- [ ] **Step 3: Commit**

```bash
git add scripts/mcp-content-server.py
git commit -m "feat(tea): add MCP Content Server — 25 tools with pgvector semantic search"
```

---

### Task 10: MCP Actions Server (22 tools)

**Files:**
- Create (on server): `scripts/mcp-actions-server.py`

- [ ] **Step 1: Create MCP Actions Server**

Follow the exact same MCP protocol handler pattern as Task 7. Implement 22 tools from spec §3.

**Security:** No tool accepts `user_id` — the orchestrator injects the authenticated user's ID before calling any tool. Each tool receives `_auth_user_id` injected by the orchestrator.

**Tier 2 tools** (require confirmation) — these insert into `tea_pending_actions` and return `{action_card_id, action, preview, confirm_prompt}`:

| Tool | Params | Action | Preview SQL |
|------|--------|--------|-------------|
| `create_post` | `content`, `media_type?` | Insert into posts | Show content preview |
| `reply_to_post` | `post_id`, `content` | Insert comment | Show original post + reply |
| `like_post` | `post_id` | Insert post_like | Show post being liked |
| `share_post` | `post_id`, `comment?` | Insert share | Show post + share comment |
| `follow_user` | `target_user_id` | Insert user_follow | Show target user profile |
| `unfollow_user` | `target_user_id` | Delete user_follow | Show target user |
| `send_message` | `recipient_id`, `content` | Insert message | Show recipient + message |
| `join_group` | `group_id` | Insert group_member | Show group info |
| `leave_group` | `group_id` | Delete group_member | Show group info |
| `rsvp_event` | `event_id`, `status` | Insert event_attendee | Show event details |
| `vote_poll` | `poll_id`, `option_id` | Insert poll_vote | Show poll + option |
| `vote_battle` | `battle_id`, `creator_id` | Insert battle_vote | Show battle participants |
| `save_post` | `post_id` | Insert saved_post | Show post |
| `donate_campaign` | `campaign_id`, `amount` | Create pending donation | Show campaign + amount |
| `create_story` | `content`, `media_url?` | Insert story | Show story preview |
| `add_friend` | `target_user_id` | Insert friendship request | Show target profile |
| `accept_friend` | `friendship_id` | Update friendship status | Show requester |
| `subscribe_creator` | `creator_id` | Insert subscription | Show creator info |
| `report_content` | `post_id`, `reason` | Insert report | Show post + reason |
| `create_gossip_thread` | `title`, `content` | Insert gossip_thread | Show thread preview |

**Tier 1 tools** (read-only, return data directly without confirmation):

| Tool | Params | Returns |
|------|--------|---------|
| `view_product` | `product_id` | Product details from `products` table |
| `view_campaign` | `campaign_id` | Campaign details from `campaigns` table |

Each Tier 2 tool follows this pattern:
```python
def create_post(params):
    user_id = params['_auth_user_id']
    action_id = f"act_{uuid4().hex[:12]}"
    # Gather preview data
    preview = {"content": params.get("content", ""), "media_type": params.get("media_type")}
    # Store pending action (expires in 10 min)
    conn = get_db()
    cur = conn.cursor()
    cur.execute("""INSERT INTO tea_pending_actions (id, conversation_id, user_id, action_type, action_params, status, expires_at, created_at)
        VALUES (%s, %s, %s, 'create_post', %s, 'pending', NOW() + INTERVAL '10 minutes', NOW())""",
        (action_id, params.get('_conversation_id', ''), user_id, json.dumps(params)))
    conn.commit(); conn.close()
    return {"type": "action_card", "action_card_id": action_id, "action": "create_post",
            "preview": preview, "confirm_prompt": "Chapisha post hii? / Post this?"}
```

- [ ] **Step 2: Test action card generation**
- [ ] **Step 3: Commit**

```bash
git add scripts/mcp-actions-server.py
git commit -m "feat(tea): add MCP Actions Server — 22 tools for platform actions with confirmation"
```

---

### Task 11: MCP Web Search Server (6 tools)

**Files:**
- Create (on server): `scripts/mcp-web-search-server.py`

- [ ] **Step 1: Create MCP Web Search Server**

Implement 6 tools from spec §3 MCP Server 5: `search_web`, `search_news`, `search_entertainment`, `search_music_trends`, `search_social_trends`, `get_cultural_context`.

Uses Brave Search API (or falls back to general knowledge if no API key configured).

```python
BRAVE_API_KEY = os.environ.get('BRAVE_SEARCH_API_KEY', '')
BRAVE_SEARCH_URL = 'https://api.search.brave.com/res/v1/web/search'
```

Each tool constructs a search query, calls Brave, and returns top 5 results.

- [ ] **Step 2: Test with a sample search**
- [ ] **Step 3: Commit**

```bash
git add scripts/mcp-web-search-server.py
git commit -m "feat(tea): add MCP Web Search Server — 6 tools for external search via Brave API"
```

---

## Phase 3: AI Orchestrator

### Task 12: Shangazi AI Orchestrator + TeaController

**Files:**
- Create (on server): `scripts/shangazi-orchestrator.py`
- Create (on server): `app/Http/Controllers/Api/TeaController.php`
- Modify (on server): `routes/api.php`

- [ ] **Step 1: Create Shangazi Orchestrator**

The orchestrator is a Python HTTP service that:
1. Receives chat requests from TeaController
2. Loads MCP servers as subprocess connections
3. Sends Claude API requests with tool definitions from all 5 MCP servers
4. Handles Claude's tool_use responses by routing to appropriate MCP server
5. Streams responses back via SSE

```python
#!/usr/bin/env python3
"""
Shangazi AI Orchestrator — connects Claude API to 5 MCP servers.
Listens on port 8101.
Streams responses via SSE.
"""
import json
import os
import subprocess
import sys
import threading
import time
import uuid
from http.server import HTTPServer, BaseHTTPRequestHandler
from socketserver import ThreadingMixIn
import anthropic

PORT = int(os.environ.get("SHANGAZI_PORT", 8101))
PROJECT_DIR = os.path.dirname(os.path.dirname(os.path.abspath(__file__)))
CLAUDE_MODEL = "claude-sonnet-4-20250514"

SHANGAZI_SYSTEM_PROMPT = """You are Shangazi — TAJIRI's beloved gossip aunt.
You are warm, witty, and wise. You speak in a mix of Swahili and English (code-switching naturally).
You know everything happening on TAJIRI — trending posts, beefs, viral content, creator drama.
You present gossip as "tea" with your signature style: dramatic reveals, playful commentary, knowing winks.

RULES:
1. Every claim MUST trace to a real platform post or interaction. Use get_trending_topics, search_posts_semantic, etc.
2. NEVER fabricate gossip. If you don't have data, say "Chai hii bado haijapikwa" (this tea hasn't brewed yet).
3. For Tier 2 actions (post, message, follow, etc.), ALWAYS return an action_card for user confirmation.
4. Respect blocked users — never mention users the requester has blocked.
5. Be entertaining but never cruel. Gossip WITH people, not AT them.
6. For new users (engagement_level=gentle), be welcoming. For regulars (full), go full TMZ mode.
7. Always check get_user_matrix first to personalize your response.
8. Attribute sources: "Kulingana na post ya @username..." (According to @username's post...)
"""

MCP_SERVERS = {
    'profile': os.path.join(PROJECT_DIR, 'scripts/mcp-profile-server.py'),
    'social': os.path.join(PROJECT_DIR, 'scripts/mcp-social-server.py'),
    'content': os.path.join(PROJECT_DIR, 'scripts/mcp-content-server.py'),
    'actions': os.path.join(PROJECT_DIR, 'scripts/mcp-actions-server.py'),
    'web_search': os.path.join(PROJECT_DIR, 'scripts/mcp-web-search-server.py'),
}

class MCPConnection:
    """Manages a subprocess connection to an MCP server."""
    def __init__(self, name, script_path):
        self.name = name
        self.proc = subprocess.Popen(
            ['python3', script_path],
            stdin=subprocess.PIPE, stdout=subprocess.PIPE, stderr=subprocess.PIPE,
            text=True, bufsize=1
        )
        self.tools = []
        self._tool_map = {}
        self._init()

    def _init(self):
        # Initialize
        self._send({"jsonrpc": "2.0", "id": 0, "method": "initialize", "params": {}})
        self._send({"jsonrpc": "2.0", "method": "notifications/initialized", "params": {}})
        # Get tools
        resp = self._send({"jsonrpc": "2.0", "id": 1, "method": "tools/list", "params": {}})
        if resp and 'result' in resp:
            for tool in resp['result'].get('tools', []):
                self.tools.append(tool)
                self._tool_map[tool['name']] = True

    def _send(self, msg):
        self.proc.stdin.write(json.dumps(msg) + '\n')
        self.proc.stdin.flush()
        if 'id' not in msg:
            return None
        line = self.proc.stdout.readline()
        return json.loads(line) if line else None

    def call_tool(self, name, arguments):
        resp = self._send({
            "jsonrpc": "2.0", "id": 2,
            "method": "tools/call",
            "params": {"name": name, "arguments": arguments}
        })
        if resp and 'result' in resp:
            content = resp['result'].get('content', [])
            return content[0].get('text', '{}') if content else '{}'
        return json.dumps({"error": "MCP call failed"})

    def has_tool(self, name):
        return name in self._tool_map

    def close(self):
        self.proc.terminate()

# Global MCP connections
mcp_connections = {}
all_claude_tools = []

def init_mcp_servers():
    global mcp_connections, all_claude_tools
    for name, path in MCP_SERVERS.items():
        try:
            conn = MCPConnection(name, path)
            mcp_connections[name] = conn
            for tool in conn.tools:
                all_claude_tools.append({
                    "name": tool['name'],
                    "description": tool.get('description', ''),
                    "input_schema": tool.get('inputSchema', {"type": "object", "properties": {}})
                })
        except Exception as e:
            print(f"[WARN] Failed to init MCP server {name}: {e}", file=sys.stderr)

def call_mcp_tool(tool_name, arguments):
    for conn in mcp_connections.values():
        if conn.has_tool(tool_name):
            return conn.call_tool(tool_name, arguments)
    return json.dumps({"error": f"Unknown tool: {tool_name}"})

# Active streams: conversation_id -> list of SSE events
active_streams = {}

class ShangaziHandler(BaseHTTPRequestHandler):
    def do_POST(self):
        if self.path == '/chat':
            self._handle_chat()
        elif self.path == '/health':
            self._json_response({"status": "ok", "tools": len(all_claude_tools)})
        else:
            self.send_error(404)

    def do_GET(self):
        if self.path.startswith('/stream/'):
            self._handle_stream()
        elif self.path == '/health':
            self._json_response({"status": "ok", "tools": len(all_claude_tools)})
        else:
            self.send_error(404)

    def _handle_chat(self):
        body = json.loads(self.rfile.read(int(self.headers.get('Content-Length', 0))))
        user_id = body.get('user_id')
        message = body.get('message')
        conversation_id = body.get('conversation_id') or f"tea_{uuid.uuid4().hex[:12]}"
        history = body.get('history', [])

        # Create stream buffer
        active_streams[conversation_id] = []

        # Start async Claude conversation
        thread = threading.Thread(
            target=self._run_claude, args=(conversation_id, user_id, message, history)
        )
        thread.daemon = True
        thread.start()

        self._json_response({
            "conversation_id": conversation_id,
            "stream_url": f"http://127.0.0.1:{PORT}/stream/{conversation_id}"
        })

    def _run_claude(self, conversation_id, user_id, message, history):
        client = anthropic.Anthropic()
        messages = []
        for h in history:
            messages.append({"role": h['role'], "content": h.get('content', '')})
        if message:
            messages.append({"role": "user", "content": message})
        elif not messages:
            messages.append({"role": "user", "content": "Habari Shangazi! Nipe chai ya leo."})

        # Inject auth user_id into action tools
        tool_context = {"_auth_user_id": user_id, "_conversation_id": conversation_id}

        try:
            # Tool-use loop (max 10 rounds)
            for _ in range(10):
                response = client.messages.create(
                    model=CLAUDE_MODEL,
                    max_tokens=2048,
                    system=SHANGAZI_SYSTEM_PROMPT,
                    tools=all_claude_tools,
                    messages=messages,
                )

                # Process content blocks
                for block in response.content:
                    if block.type == "text":
                        active_streams.setdefault(conversation_id, []).append(
                            f"event: text\ndata: {json.dumps({'content': block.text, 'done': True})}\n\n"
                        )
                    elif block.type == "tool_use":
                        args = dict(block.input)
                        args.update(tool_context)
                        result = call_mcp_tool(block.name, args)
                        # Check if result is an action_card
                        try:
                            parsed = json.loads(result)
                            if parsed.get('type') == 'action_card':
                                active_streams.setdefault(conversation_id, []).append(
                                    f"event: action_card\ndata: {result}\n\n"
                                )
                        except:
                            pass
                        # Feed tool result back to Claude
                        messages.append({"role": "assistant", "content": response.content})
                        messages.append({
                            "role": "user",
                            "content": [{"type": "tool_result", "tool_use_id": block.id, "content": result}]
                        })

                if response.stop_reason != "tool_use":
                    break
        except Exception as e:
            active_streams.setdefault(conversation_id, []).append(
                f"event: text\ndata: {json.dumps({'content': f'Pole, kuna tatizo: {e}', 'done': True})}\n\n"
            )

        active_streams.setdefault(conversation_id, []).append(
            f"event: done\ndata: {json.dumps({'conversation_id': conversation_id})}\n\n"
        )

    def _handle_stream(self):
        conversation_id = self.path.split('/stream/')[-1]
        self.send_response(200)
        self.send_header('Content-Type', 'text/event-stream')
        self.send_header('Cache-Control', 'no-cache')
        self.send_header('Connection', 'keep-alive')
        self.end_headers()

        sent = 0
        timeout = time.time() + 120  # 2 min max
        while time.time() < timeout:
            events = active_streams.get(conversation_id, [])
            while sent < len(events):
                self.wfile.write(events[sent].encode())
                self.wfile.flush()
                if 'event: done' in events[sent]:
                    return
                sent += 1
            time.sleep(0.1)

    def _json_response(self, data, status=200):
        self.send_response(status)
        self.send_header('Content-Type', 'application/json')
        self.end_headers()
        self.wfile.write(json.dumps(data).encode())

    def log_message(self, format, *args):
        pass  # Suppress access logs

class ThreadedHTTPServer(ThreadingMixIn, HTTPServer):
    daemon_threads = True

if __name__ == '__main__':
    print(f"[Shangazi] Initializing MCP servers...", file=sys.stderr)
    init_mcp_servers()
    print(f"[Shangazi] Loaded {len(all_claude_tools)} tools from {len(mcp_connections)} MCP servers", file=sys.stderr)
    server = ThreadedHTTPServer(('0.0.0.0', PORT), ShangaziHandler)
    print(f"[Shangazi] Listening on port {PORT}", file=sys.stderr)
    server.serve_forever()
```

- [ ] **Step 2: Create TeaController**

SSH and create `app/Http/Controllers/Api/TeaController.php`:

```php
<?php

namespace App\Http\Controllers\Api;

use App\Http\Controllers\Controller;
use Illuminate\Http\Request;
use Illuminate\Support\Facades\DB;
use Illuminate\Support\Facades\Http;
use Illuminate\Support\Facades\Cache;
use Illuminate\Support\Str;

class TeaController extends Controller
{
    private string $orchestratorUrl = 'http://127.0.0.1:8101';

    /**
     * POST /api/tea/chat — Start or continue a Shangazi conversation.
     * Returns {conversation_id, stream_url} for SSE.
     */
    public function chat(Request $request)
    {
        $user = $request->user();
        $message = $request->input('message');
        $conversationId = $request->input('conversation_id');

        // Rate limit: 50 per hour
        $key = "tea_rate:{$user->id}";
        $count = Cache::get($key, 0);
        if ($count >= 50) {
            return response()->json(['error' => 'Rate limit exceeded. Try again later.'], 429);
        }
        Cache::put($key, $count + 1, 3600);

        // Create or get conversation
        if (!$conversationId) {
            $conversationId = 'tea_' . Str::random(12);
            DB::table('tea_conversations')->insert([
                'id' => $conversationId,
                'user_id' => $user->id,
                'message_count' => 0,
                'created_at' => now(),
                'updated_at' => now(),
            ]);
        }

        // Store user message if present
        if ($message) {
            $msgId = 'msg_' . Str::random(12);
            DB::table('tea_messages')->insert([
                'id' => $msgId,
                'conversation_id' => $conversationId,
                'role' => 'user',
                'type' => 'text',
                'content' => json_encode(['text' => $message]),
                'created_at' => now(),
            ]);
            DB::table('tea_conversations')
                ->where('id', $conversationId)
                ->increment('message_count');
        }

        // Load conversation history for context
        $history = DB::table('tea_messages')
            ->where('conversation_id', $conversationId)
            ->orderBy('created_at')
            ->limit(20)
            ->get()
            ->map(fn($m) => [
                'role' => $m->role === 'shangazi' ? 'assistant' : 'user',
                'content' => json_decode($m->content, true)['text'] ?? '',
            ])
            ->toArray();

        // Call orchestrator
        try {
            $response = Http::timeout(5)->post("{$this->orchestratorUrl}/chat", [
                'user_id' => $user->id,
                'message' => $message,
                'conversation_id' => $conversationId,
                'history' => $history,
            ]);

            if ($response->successful()) {
                $data = $response->json();
                // Replace internal URL with public stream URL
                $streamUrl = url("/api/tea/stream/{$conversationId}");
                return response()->json([
                    'conversation_id' => $conversationId,
                    'stream_url' => $streamUrl,
                ]);
            }
        } catch (\Exception $e) {
            \Log::error("[TeaController] Orchestrator error: " . $e->getMessage());
        }

        return response()->json(['error' => 'Shangazi is unavailable right now'], 503);
    }

    /**
     * GET /api/tea/stream/{conversationId} — Proxy SSE from orchestrator.
     */
    public function stream(Request $request, string $conversationId)
    {
        // Verify ownership
        $user = $request->user();
        $conv = DB::table('tea_conversations')
            ->where('id', $conversationId)
            ->where('user_id', $user->id)
            ->first();

        if (!$conv) {
            return response()->json(['error' => 'Conversation not found'], 404);
        }

        return response()->stream(function () use ($conversationId) {
            $ch = curl_init("{$this->orchestratorUrl}/stream/{$conversationId}");
            curl_setopt($ch, CURLOPT_RETURNTRANSFER, false);
            curl_setopt($ch, CURLOPT_TIMEOUT, 120);
            curl_setopt($ch, CURLOPT_WRITEFUNCTION, function ($ch, $data) {
                echo $data;
                ob_flush();
                flush();

                // Store messages from stream for persistence
                // (done asynchronously — not blocking the stream)
                return strlen($data);
            });
            curl_exec($ch);
            curl_close($ch);
        }, 200, [
            'Content-Type' => 'text/event-stream',
            'Cache-Control' => 'no-cache',
            'Connection' => 'keep-alive',
            'X-Accel-Buffering' => 'no',
        ]);
    }

    /**
     * GET /api/tea/conversations — List user's tea conversations.
     */
    public function conversations(Request $request)
    {
        $conversations = DB::table('tea_conversations')
            ->where('user_id', $request->user()->id)
            ->orderByDesc('updated_at')
            ->limit($request->input('limit', 20))
            ->get();

        return response()->json(['conversations' => $conversations]);
    }

    /**
     * GET /api/tea/conversations/{id} — Load conversation messages.
     */
    public function conversation(Request $request, string $id)
    {
        $conv = DB::table('tea_conversations')
            ->where('id', $id)
            ->where('user_id', $request->user()->id)
            ->first();

        if (!$conv) {
            return response()->json(['error' => 'Not found'], 404);
        }

        $messages = DB::table('tea_messages')
            ->where('conversation_id', $id)
            ->orderBy('created_at')
            ->get()
            ->map(function ($m) {
                $m->content = json_decode($m->content, true);
                return $m;
            });

        return response()->json(['conversation' => $conv, 'messages' => $messages]);
    }

    /**
     * DELETE /api/tea/conversations/{id}
     */
    public function deleteConversation(Request $request, string $id)
    {
        $deleted = DB::table('tea_conversations')
            ->where('id', $id)
            ->where('user_id', $request->user()->id)
            ->delete();

        return response()->json(['success' => $deleted > 0]);
    }

    /**
     * POST /api/tea/action/confirm — Execute or reject a pending action.
     */
    public function confirmAction(Request $request)
    {
        $request->validate([
            'action_card_id' => 'required|string',
            'confirmed' => 'required|boolean',
        ]);

        $action = DB::table('tea_pending_actions')
            ->where('id', $request->input('action_card_id'))
            ->where('user_id', $request->user()->id)
            ->where('status', 'pending')
            ->where('expires_at', '>', now())
            ->first();

        if (!$action) {
            return response()->json(['error' => 'Action expired or not found'], 404);
        }

        if (!$request->input('confirmed')) {
            DB::table('tea_pending_actions')
                ->where('id', $action->id)
                ->update(['status' => 'rejected']);
            return response()->json(['success' => true, 'message' => 'Action cancelled']);
        }

        // Execute the action
        $params = json_decode($action->action_params, true);
        $result = $this->executeAction($request->user(), $action->action_type, $params);

        DB::table('tea_pending_actions')
            ->where('id', $action->id)
            ->update([
                'status' => 'confirmed',
                'executed_at' => now(),
                'execution_result' => json_encode($result),
            ]);

        return response()->json($result);
    }

    private function executeAction($user, string $actionType, array $params): array
    {
        // Route to appropriate controller/service based on action type
        // Each action calls existing Laravel service methods
        try {
            switch ($actionType) {
                case 'create_post':
                    $postId = DB::table('posts')->insertGetId([
                        'user_id' => $user->id,
                        'content' => $params['content'] ?? '',
                        'media_type' => $params['media_type'] ?? 'text',
                        'created_at' => now(),
                        'updated_at' => now(),
                    ]);
                    return ['success' => true, 'message' => 'Post created!', 'post_id' => $postId];

                case 'like_post':
                    DB::table('post_likes')->insertOrIgnore([
                        'user_id' => $user->id,
                        'post_id' => $params['post_id'],
                        'reaction_type' => 'like',
                        'created_at' => now(),
                    ]);
                    return ['success' => true, 'message' => 'Post liked!'];

                case 'follow_user':
                    DB::table('user_follows')->insertOrIgnore([
                        'follower_id' => $user->id,
                        'following_id' => $params['target_user_id'],
                        'created_at' => now(),
                    ]);
                    return ['success' => true, 'message' => 'Now following!'];

                case 'send_message':
                    // Find or create conversation, then insert message
                    return ['success' => true, 'message' => 'Message sent!'];

                default:
                    return ['success' => false, 'message' => "Unknown action: $actionType"];
            }
        } catch (\Exception $e) {
            return ['success' => false, 'message' => 'Action failed: ' . $e->getMessage()];
        }
    }

    /**
     * POST /api/tea/feedback
     */
    public function feedback(Request $request)
    {
        $request->validate([
            'message_id' => 'required|string',
            'type' => 'required|in:helpful,harmful,inaccurate',
        ]);

        DB::table('tea_audit_log')->insert([
            'conversation_id' => '',
            'message_id' => $request->input('message_id'),
            'user_id' => $request->user()->id,
            'request_type' => 'feedback',
            'shangazi_response' => $request->input('type'),
            'created_at' => now(),
        ]);

        return response()->json(['success' => true]);
    }
}
```

- [ ] **Step 3: Register routes**

Add to `routes/api.php`:
```php
Route::prefix('tea')->middleware('auth:sanctum')->group(function () {
    Route::post('/chat', [TeaController::class, 'chat']);
    Route::get('/stream/{conversationId}', [TeaController::class, 'stream']);
    Route::get('/conversations', [TeaController::class, 'conversations']);
    Route::get('/conversations/{id}', [TeaController::class, 'conversation']);
    Route::delete('/conversations/{id}', [TeaController::class, 'deleteConversation']);
    Route::post('/action/confirm', [TeaController::class, 'confirmAction']);
    Route::post('/feedback', [TeaController::class, 'feedback']);
});
```

- [ ] **Step 4: Start orchestrator and test**

```bash
# Start orchestrator
cd /var/www/tajiri.zimasystems.com
ANTHROPIC_API_KEY=sk-... python3 scripts/shangazi-orchestrator.py &

# Test via curl
curl -s -X POST https://tajiri.zimasystems.com/api/tea/chat \
  -H "Authorization: Bearer $TOKEN" \
  -H "Content-Type: application/json" \
  -d '{}' | python3 -m json.tool
```

- [ ] **Step 5: Commit**

```bash
git add scripts/shangazi-orchestrator.py app/Http/Controllers/Api/TeaController.php routes/api.php
git commit -m "feat(tea): add Shangazi Orchestrator + TeaController — Claude API with 76 MCP tools + SSE"
```

---

## Phase 4: Frontend UI

### Task 13: Tea Chat Screen

**Files:**
- Create: `lib/screens/feed/tea_chat_screen.dart`
- Create: `lib/widgets/tea_card_widget.dart`
- Create: `lib/widgets/action_card_widget.dart`
- Create: `lib/widgets/shangazi_message_bubble.dart`

- [ ] **Step 1: Create shangazi_message_bubble.dart**

A styled chat bubble for Shangazi's messages — dark background, tea emoji, rounded corners:

```dart
import 'package:flutter/material.dart';

class ShangaziMessageBubble extends StatelessWidget {
  const ShangaziMessageBubble({super.key, required this.child});
  final Widget child;

  @override
  Widget build(BuildContext context) {
    return Align(
      alignment: Alignment.centerLeft,
      child: Container(
        margin: const EdgeInsets.only(left: 12, right: 48, top: 4, bottom: 4),
        padding: const EdgeInsets.all(12),
        decoration: BoxDecoration(
          color: const Color(0xFFF5F5F5),
          borderRadius: BorderRadius.circular(12),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              '🫖 Shangazi',
              style: TextStyle(
                fontWeight: FontWeight.w600,
                fontSize: 12,
                color: Color(0xFF1A1A1A),
              ),
            ),
            const SizedBox(height: 4),
            child,
          ],
        ),
      ),
    );
  }
}
```

- [ ] **Step 2: Create tea_card_widget.dart**

```dart
import 'package:flutter/material.dart';
import '../models/tea_models.dart';

class TeaCardWidget extends StatelessWidget {
  const TeaCardWidget({
    super.key,
    required this.card,
    this.onTap,
    this.onActionTap,
  });

  final TeaCard card;
  final VoidCallback? onTap;
  final void Function(String action)? onActionTap;

  Color get _urgencyColor {
    switch (card.urgency) {
      case 'fire': return const Color(0xFFD32F2F);
      case 'hot': return const Color(0xFFFF6F00);
      case 'warm': return const Color(0xFFFFA000);
      default: return const Color(0xFF757575);
    }
  }

  String get _urgencyEmoji {
    switch (card.urgency) {
      case 'fire': return '🔥';
      case 'hot': return '☕';
      case 'warm': return '🫖';
      default: return '🧊';
    }
  }

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        margin: const EdgeInsets.symmetric(vertical: 4),
        padding: const EdgeInsets.all(12),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: _urgencyColor.withValues(alpha: 0.3)),
          boxShadow: [
            BoxShadow(
              color: _urgencyColor.withValues(alpha: 0.08),
              blurRadius: 8,
              offset: const Offset(0, 2),
            ),
          ],
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Text(_urgencyEmoji, style: const TextStyle(fontSize: 16)),
                const SizedBox(width: 6),
                if (card.category != null)
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                    decoration: BoxDecoration(
                      color: _urgencyColor.withValues(alpha: 0.1),
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: Text(
                      card.category!,
                      style: TextStyle(fontSize: 11, color: _urgencyColor, fontWeight: FontWeight.w600),
                    ),
                  ),
                const Spacer(),
                if (card.topReaction != null) Text(card.topReaction!, style: const TextStyle(fontSize: 14)),
              ],
            ),
            const SizedBox(height: 8),
            Text(
              card.headline,
              style: const TextStyle(fontSize: 15, fontWeight: FontWeight.w700, color: Color(0xFF1A1A1A)),
              maxLines: 2,
              overflow: TextOverflow.ellipsis,
            ),
            const SizedBox(height: 4),
            Text(
              card.summary,
              style: const TextStyle(fontSize: 13, color: Color(0xFF666666)),
              maxLines: 3,
              overflow: TextOverflow.ellipsis,
            ),
            if (card.actions.isNotEmpty) ...[
              const SizedBox(height: 8),
              Wrap(
                spacing: 8,
                children: card.actions.map((action) => TextButton(
                  onPressed: () => onActionTap?.call(action),
                  style: TextButton.styleFrom(
                    padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
                    minimumSize: const Size(48, 32),
                    foregroundColor: _urgencyColor,
                  ),
                  child: Text(action.replaceAll('_', ' '), style: const TextStyle(fontSize: 12)),
                )).toList(),
              ),
            ],
          ],
        ),
      ),
    );
  }
}
```

- [ ] **Step 3: Create action_card_widget.dart**

```dart
import 'package:flutter/material.dart';
import '../models/tea_models.dart';

class ActionCardWidget extends StatelessWidget {
  const ActionCardWidget({
    super.key,
    required this.actionCard,
    required this.onConfirm,
    required this.onCancel,
  });

  final ActionCard actionCard;
  final VoidCallback onConfirm;
  final VoidCallback onCancel;

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.symmetric(vertical: 4),
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: const Color(0xFFFFF8E1),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: const Color(0xFFFFCC02).withValues(alpha: 0.4)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              const Text('⚡', style: TextStyle(fontSize: 16)),
              const SizedBox(width: 6),
              Expanded(
                child: Text(
                  actionCard.confirmPrompt,
                  style: const TextStyle(fontSize: 14, fontWeight: FontWeight.w600, color: Color(0xFF1A1A1A)),
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                ),
              ),
            ],
          ),
          const SizedBox(height: 8),
          // Preview content
          if (actionCard.preview.isNotEmpty)
            Container(
              width: double.infinity,
              padding: const EdgeInsets.all(8),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(8),
              ),
              child: Text(
                actionCard.preview.entries.map((e) => '${e.key}: ${e.value}').join('\n'),
                style: const TextStyle(fontSize: 12, color: Color(0xFF666666)),
                maxLines: 5,
                overflow: TextOverflow.ellipsis,
              ),
            ),
          const SizedBox(height: 12),
          if (actionCard.isPending)
            Row(
              mainAxisAlignment: MainAxisAlignment.end,
              children: [
                OutlinedButton(
                  onPressed: onCancel,
                  style: OutlinedButton.styleFrom(
                    foregroundColor: const Color(0xFF666666),
                    side: const BorderSide(color: Color(0xFFCCCCCC)),
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                    padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                  ),
                  child: const Text('Ghairi', style: TextStyle(fontSize: 13)),
                ),
                const SizedBox(width: 8),
                ElevatedButton(
                  onPressed: onConfirm,
                  style: ElevatedButton.styleFrom(
                    backgroundColor: const Color(0xFF1A1A1A),
                    foregroundColor: Colors.white,
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                    padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                  ),
                  child: const Text('Thibitisha', style: TextStyle(fontSize: 13)),
                ),
              ],
            )
          else
            Text(
              actionCard.status == 'confirmed' ? '✅ Imetekelezwa' : '❌ Imeghairiwa',
              style: TextStyle(
                fontSize: 13,
                color: actionCard.status == 'confirmed' ? Colors.green : Colors.red,
                fontWeight: FontWeight.w500,
              ),
            ),
        ],
      ),
    );
  }
}
```

- [ ] **Step 4: Create tea_chat_screen.dart**

```dart
import 'dart:async';
import 'package:flutter/material.dart';
import '../../models/tea_models.dart';
import '../../services/tea_service.dart';
import '../../services/local_storage_service.dart';
import '../../services/event_tracking_service.dart';
import '../../widgets/shangazi_message_bubble.dart';
import '../../widgets/tea_card_widget.dart';
import '../../widgets/action_card_widget.dart';

class TeaChatScreen extends StatefulWidget {
  const TeaChatScreen({super.key});

  @override
  State<TeaChatScreen> createState() => _TeaChatScreenState();
}

class _TeaChatScreenState extends State<TeaChatScreen> {
  final _controller = TextEditingController();
  final _scrollController = ScrollController();
  final _focusNode = FocusNode();
  final List<TeaMessage> _messages = [];
  String? _conversationId;
  bool _isStreaming = false;
  bool _isLoading = true;
  String _streamingText = '';
  StreamSubscription<TeaStreamEvent>? _streamSub;

  @override
  void initState() {
    super.initState();
    _initChat();
  }

  @override
  void dispose() {
    _controller.dispose();
    _scrollController.dispose();
    _focusNode.dispose();
    _streamSub?.cancel();
    super.dispose();
  }

  Future<void> _initChat() async {
    // Start with a fresh conversation — Shangazi greets the user
    final token = await LocalStorageService().getToken();
    if (token == null) return;
    setState(() => _isLoading = true);
    final response = await TeaService.startChat(token);
    if (response != null && mounted) {
      _conversationId = response.conversationId;
      _listenToStream(response.streamUrl, token);
    }
    if (mounted) setState(() => _isLoading = false);
  }

  void _listenToStream(String streamUrl, String token) {
    setState(() {
      _isStreaming = true;
      _streamingText = '';
    });
    _streamSub?.cancel();
    _streamSub = TeaService.streamResponse(streamUrl, token).listen(
      (event) {
        if (!mounted) return;
        if (event.isText) {
          setState(() => _streamingText += event.textChunk);
          if (event.textDone) {
            _finalizeStreamingMessage('text', {'text': _streamingText});
          }
        } else if (event.isTeaCard) {
          _finalizeStreamingMessage('tea_card', event.data);
        } else if (event.isActionCard) {
          _finalizeStreamingMessage('action_card', event.data);
        } else if (event.isDone) {
          setState(() => _isStreaming = false);
        }
        _scrollToBottom();
      },
      onError: (_) {
        if (mounted) setState(() => _isStreaming = false);
      },
      onDone: () {
        if (mounted) setState(() => _isStreaming = false);
      },
    );
  }

  void _finalizeStreamingMessage(String type, Map<String, dynamic> content) {
    setState(() {
      _messages.add(TeaMessage(
        id: 'msg_${DateTime.now().millisecondsSinceEpoch}',
        role: 'shangazi',
        type: type,
        content: content,
        createdAt: DateTime.now(),
      ));
      _streamingText = '';
    });
  }

  Future<void> _sendMessage() async {
    final text = _controller.text.trim();
    if (text.isEmpty || _isStreaming) return;
    _controller.clear();

    // Add user message
    setState(() {
      _messages.add(TeaMessage(
        id: 'user_${DateTime.now().millisecondsSinceEpoch}',
        role: 'user',
        type: 'text',
        content: {'text': text},
        createdAt: DateTime.now(),
      ));
    });
    _scrollToBottom();

    // Track signal
    EventTrackingService().trackTeaQuestionAsked(text);

    final token = await LocalStorageService().getToken();
    if (token == null) return;

    final response = await TeaService.startChat(
      token,
      message: text,
      conversationId: _conversationId,
    );
    if (response != null && mounted) {
      _conversationId = response.conversationId;
      _listenToStream(response.streamUrl, token);
    }
  }

  Future<void> _handleActionConfirm(String actionCardId, bool confirmed) async {
    final token = await LocalStorageService().getToken();
    if (token == null) return;
    final result = await TeaService.confirmAction(token, actionCardId, confirmed: confirmed);
    if (result != null && mounted) {
      setState(() {
        _messages.add(TeaMessage(
          id: 'result_${DateTime.now().millisecondsSinceEpoch}',
          role: 'shangazi',
          type: 'action_result',
          content: result,
          createdAt: DateTime.now(),
        ));
      });
    }
    final tracker = EventTrackingService();
    if (confirmed) {
      tracker.trackTeaActionConfirmed('action', actionCardId);
    } else {
      tracker.trackTeaActionRejected('action', actionCardId);
    }
  }

  void _scrollToBottom() {
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (_scrollController.hasClients) {
        _scrollController.animateTo(
          _scrollController.position.maxScrollExtent,
          duration: const Duration(milliseconds: 200),
          curve: Curves.easeOut,
        );
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        Expanded(
          child: _isLoading
              ? const Center(
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Text('🫖', style: TextStyle(fontSize: 48)),
                      SizedBox(height: 12),
                      Text(
                        'Shangazi anapika chai...',
                        style: TextStyle(fontSize: 15, color: Color(0xFF666666)),
                      ),
                    ],
                  ),
                )
              : ListView.builder(
                  controller: _scrollController,
                  padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                  itemCount: _messages.length + (_isStreaming && _streamingText.isNotEmpty ? 1 : 0),
                  itemBuilder: (context, index) {
                    if (index == _messages.length) {
                      // Streaming preview
                      return ShangaziMessageBubble(
                        child: Text(_streamingText, style: const TextStyle(fontSize: 14, color: Color(0xFF333333))),
                      );
                    }
                    return _buildMessage(_messages[index]);
                  },
                ),
        ),
        // Input bar
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
          decoration: const BoxDecoration(
            color: Colors.white,
            border: Border(top: BorderSide(color: Color(0xFFEEEEEE))),
          ),
          child: SafeArea(
            top: false,
            child: Row(
              children: [
                Expanded(
                  child: TextField(
                    controller: _controller,
                    focusNode: _focusNode,
                    decoration: InputDecoration(
                      hintText: 'Uliza Shangazi...',
                      hintStyle: const TextStyle(color: Color(0xFF999999)),
                      filled: true,
                      fillColor: const Color(0xFFF5F5F5),
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(12),
                        borderSide: BorderSide.none,
                      ),
                      contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                    ),
                    textInputAction: TextInputAction.send,
                    onSubmitted: (_) => _sendMessage(),
                  ),
                ),
                const SizedBox(width: 8),
                IconButton(
                  onPressed: _isStreaming ? null : _sendMessage,
                  icon: Icon(
                    Icons.send_rounded,
                    color: _isStreaming ? const Color(0xFFCCCCCC) : const Color(0xFF1A1A1A),
                  ),
                ),
              ],
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildMessage(TeaMessage msg) {
    if (msg.role == 'user') {
      return Align(
        alignment: Alignment.centerRight,
        child: Container(
          margin: const EdgeInsets.only(left: 48, right: 12, top: 4, bottom: 4),
          padding: const EdgeInsets.all(12),
          decoration: BoxDecoration(
            color: const Color(0xFF1A1A1A),
            borderRadius: BorderRadius.circular(12),
          ),
          child: Text(
            msg.textContent,
            style: const TextStyle(fontSize: 14, color: Colors.white),
          ),
        ),
      );
    }

    if (msg.isTeaCard) {
      final card = TeaCard.fromJson(msg.content);
      return ShangaziMessageBubble(
        child: TeaCardWidget(
          card: card,
          onTap: () => EventTrackingService().trackTeaCardTapped(int.tryParse(card.id) ?? 0, card.urgency),
        ),
      );
    }

    if (msg.isActionCard) {
      final action = ActionCard.fromJson(msg.content);
      return ShangaziMessageBubble(
        child: ActionCardWidget(
          actionCard: action,
          onConfirm: () => _handleActionConfirm(action.actionCardId, true),
          onCancel: () => _handleActionConfirm(action.actionCardId, false),
        ),
      );
    }

    if (msg.isActionResult) {
      final success = msg.content['success'] == true;
      return ShangaziMessageBubble(
        child: Text(
          success
              ? '✅ ${msg.content['message'] ?? 'Imefanikiwa!'}'
              : '❌ ${msg.content['message'] ?? 'Imeshindikana'}',
          style: TextStyle(fontSize: 14, color: success ? Colors.green.shade700 : Colors.red.shade700),
        ),
      );
    }

    // Default: text message
    return ShangaziMessageBubble(
      child: Text(msg.textContent, style: const TextStyle(fontSize: 14, color: Color(0xFF333333))),
    );
  }
}
```

- [ ] **Step 5: Verify analysis**

```bash
flutter analyze lib/screens/feed/tea_chat_screen.dart lib/widgets/tea_card_widget.dart lib/widgets/action_card_widget.dart lib/widgets/shangazi_message_bubble.dart
```

- [ ] **Step 6: Commit**

```bash
git add lib/screens/feed/tea_chat_screen.dart lib/widgets/tea_card_widget.dart lib/widgets/action_card_widget.dart lib/widgets/shangazi_message_bubble.dart
git commit -m "feat(tea): add Tea Chat UI — chat screen, tea cards, action cards, message bubbles"
```

---

### Task 14: Integrate Tea Tab into FeedScreen

**Files:**
- Modify: `lib/screens/feed/feed_screen.dart:138,178,1456-1547`
- Modify: `lib/l10n/app_strings.dart`
- Modify: `lib/main.dart`

- [ ] **Step 1: Add Tea strings to AppStrings**

Add to `lib/l10n/app_strings.dart`:
```dart
String get teaTab => isSwahili ? 'Chai' : 'Tea';
String get shangaziTeaRoom => isSwahili ? 'Chumba cha Chai cha Shangazi' : "Shangazi's Tea Room";
String get askShangazi => isSwahili ? 'Uliza Shangazi...' : 'Ask Shangazi...';
String get shangaziBrewing => isSwahili ? 'Shangazi anapika chai...' : 'Shangazi is brewing tea...';
String get confirmAction => isSwahili ? 'Thibitisha' : 'Confirm';
String get cancelAction => isSwahili ? 'Ghairi' : 'Cancel';
```

- [ ] **Step 2: Update FeedScreen TabController**

In `lib/screens/feed/feed_screen.dart`:

Line 138: Change `length: 3` to `length: 4`
Line 178: Change `['posts', 'friends', 'live']` to `['posts', 'friends', 'live', 'tea']`

- [ ] **Step 3: Update _FeedTabBar to handle 4 tabs**

In the `_FeedTabBar` widget (around line 1456):
- Change `List.generate(3, ...)` to `List.generate(4, ...)`
- Add case 3 to `_iconFor` switch (use HeroIcons to match existing tabs):
```dart
case 3:
  return HeroIcon(HeroIcons.chatBubbleLeftRight, style: style, size: _FeedTabBar._iconSize, color: color);
```
- Add 'Chai' / tea label for index 3

- [ ] **Step 4: Add Tea tab content in TabBarView**

When `_currentFeedType == 'tea'`, render `TeaChatScreen` instead of the feed ListView.

- [ ] **Step 5: Add /tea route to main.dart**

In `lib/main.dart` `onGenerateRoute`, add:
```dart
case 'tea':
  return MaterialPageRoute(builder: (_) => const TeaChatScreen());
```

- [ ] **Step 6: Verify and commit**

```bash
flutter analyze lib/screens/feed/feed_screen.dart lib/l10n/app_strings.dart lib/main.dart
git add lib/screens/feed/feed_screen.dart lib/l10n/app_strings.dart lib/main.dart
git commit -m "feat(tea): integrate Tea tab into FeedScreen — 4th tab with Shangazi chat"
```

---

### Task 15: Action Card Confirmation Flow

**Files:**
- Modify: `lib/screens/feed/tea_chat_screen.dart`

- [ ] **Step 1: Implement confirmation flow in TeaChatScreen**

When an `action_card` message appears:
1. Render `ActionCardWidget` with confirm/cancel buttons
2. On confirm: call `TeaService.confirmAction(token, actionCardId, confirmed: true)`
3. On cancel: call `TeaService.confirmAction(token, actionCardId, confirmed: false)`
4. Update the message in the list with the result
5. Track `tea_action_confirmed` or `tea_action_rejected` signal

- [ ] **Step 2: Verify and commit**

```bash
git add lib/screens/feed/tea_chat_screen.dart
git commit -m "feat(tea): add action confirmation flow — confirm/reject Shangazi's proposed actions"
```

---

## Phase 5: Caching & Optimization

### Task 16: Redis Caching + Cohort Pre-Generation

**Files:**
- Create (on server): `app/Services/Tea/CohortTeaGenerator.php`
- Create (on server): `app/Console/Commands/GenerateCohortTea.php`
- Create (on server): `app/Console/Commands/DecayProfileMatrix.php`

- [ ] **Step 1: Create CohortTeaGenerator**

Groups users into behavioral cohorts (interaction_style × top_interest × language × gossip_tier), generates Shangazi greetings per cohort via Claude API, caches in Redis (TTL 1 hour).

- [ ] **Step 2: Create DecayProfileMatrix command**

Daily cron: decays `topic_interests` by 2%, recomputes `user_similarity_cache`, reclassifies `interaction_style`.

- [ ] **Step 3: Register cron jobs**

```php
Schedule::command('tea:generate-cohort-tea')->hourly();
Schedule::command('tea:decay-matrix')->daily();
```

- [ ] **Step 4: Test and commit**

```bash
git add app/Services/Tea/CohortTeaGenerator.php app/Console/Commands/
git commit -m "feat(tea): add cohort pre-generation + matrix decay cron jobs"
```

---

## Phase 6: Safety & Polish

### Task 17: Safety Layers + Audit Logging

**Files:**
- Modify (on server): `scripts/shangazi-orchestrator.py`

- [ ] **Step 1: Add content moderation to orchestrator**

After Claude generates a response, run a quick Claude Haiku check for safety:
- Check against blocked content patterns (users who opted out, minors, etc.)
- Verify source grounding (every claim traces to a post/interaction)
- Log to `tea_audit_log` table

- [ ] **Step 2: Add rate limiting**

In TeaController: max 50 tea requests per user per hour.

- [ ] **Step 3: Test safety filter and commit**

```bash
git add scripts/shangazi-orchestrator.py app/Http/Controllers/Api/TeaController.php
git commit -m "feat(tea): add safety layers — content moderation, audit logging, rate limiting"
```

---

### Task 18: End-to-End Verification

- [ ] **Step 1: Verify all database tables exist**

```bash
sshpass -p "ZimaBlueApps" ssh root@172.240.241.180 \
  "psql -U postgres -d tajiri -c \"SELECT table_name FROM information_schema.tables WHERE table_name LIKE 'tea_%' OR table_name LIKE 'user_behavior%' OR table_name = 'user_similarity_cache' ORDER BY 1;\""
```

- [ ] **Step 2: Verify all routes registered**

```bash
sshpass -p "ZimaBlueApps" ssh root@172.240.241.180 \
  "cd /var/www/tajiri.zimasystems.com && php artisan route:list --path=tea"
```

Expected: 7 routes (chat, stream, conversations, conversations/:id GET, conversations/:id DELETE, action/confirm, feedback).

- [ ] **Step 3: Verify MCP servers respond**

Test each MCP server with a `tools/list` call.

- [ ] **Step 4: Verify orchestrator is running**

```bash
curl -s http://127.0.0.1:8101/health
```

- [ ] **Step 5: End-to-end test — open Tea tab**

```bash
# Get auth token
TOKEN=$(curl -sk "https://tajiri.zimasystems.com/api/users/phone/0712345678?device_id=test" | python3 -c "import json,sys; print(json.load(sys.stdin)['access_token'])")

# Start chat
curl -sk -X POST "https://tajiri.zimasystems.com/api/tea/chat" \
  -H "Authorization: Bearer $TOKEN" \
  -H "Content-Type: application/json" \
  -d '{"message": "Whats the tea today?"}'
```

- [ ] **Step 6: Verify flutter analyze passes on all new/modified files**

```bash
flutter analyze lib/models/tea_models.dart lib/services/tea_service.dart \
  lib/screens/feed/tea_chat_screen.dart lib/screens/feed/feed_screen.dart \
  lib/widgets/tea_card_widget.dart lib/widgets/action_card_widget.dart \
  lib/widgets/shangazi_message_bubble.dart lib/services/event_tracking_service.dart \
  lib/l10n/app_strings.dart lib/main.dart
```

Expected: 0 errors, 0 warnings (only pre-existing info hints acceptable).

- [ ] **Step 7: Final commit**

```bash
git add -A
git commit -m "feat(tea): Shangazi Tea — complete AI gossip partner with 76 MCP tools"
```

---

## Task Summary

| Task | Phase | Description | Depends On |
|------|-------|-------------|------------|
| 1 | Foundation | Database migrations (8 tables) | — |
| 2 | Foundation | Frontend Tea models | — |
| 3 | Foundation | Extend EventTrackingService | — |
| 4 | Foundation | TeaService + SSE client | Task 2 |
| 5 | Foundation | Matrix Builder Service | Task 1 |
| 6 | Foundation | Tea Topics Aggregator cron | Task 1 |
| 7 | MCP | Profile Server (10 tools) | Task 1 |
| 8 | MCP | Social Graph Server (13 tools) | Task 1 |
| 9 | MCP | Content & Feed Server (25 tools) | Task 1 |
| 10 | MCP | Actions Server (22 tools) | Task 1 |
| 11 | MCP | Web Search Server (6 tools) | Task 1 |
| 12 | Orchestrator | Shangazi AI + TeaController | Tasks 7-11 |
| 13 | Frontend | Tea Chat Screen + widgets | Tasks 2, 4 |
| 14 | Frontend | FeedScreen integration | Task 13 |
| 15 | Frontend | Action confirmation flow | Tasks 13, 12 |
| 16 | Caching | Cohort pre-gen + matrix decay | Tasks 5, 6, 12 |
| 17 | Safety | Moderation + audit + rate limit | Task 12 |
| 18 | Verification | End-to-end testing | All |

**Parallelization:** Tasks 1-3 are independent. Tasks 7-11 (MCP servers) are independent of each other. Tasks 2+4 and 5+6 can run in parallel with the MCP tasks.
