# WhatsApp-Like Messaging — Implementation Plan

> **For agentic workers:** REQUIRED SUB-SKILL: Use superpowers:subagent-driven-development (recommended) or superpowers:executing-plans to implement this plan task-by-task. Steps use checkbox (`- [ ]`) syntax for tracking.

**Goal:** Bring TAJIRI's messaging to WhatsApp-level UX: 4-state message delivery icons, online/last-seen presence, full-text message search, link previews, server-synced conversation settings, starred messages, forward labels, full emoji reaction picker, voice speed control, group read receipts, disappearing messages, and improved reply UX.

**Architecture:** Backend changes via `./scripts/ask_backend.sh` or SSH to `root@172.240.241.180` (Laravel at `/var/www/tajiri.zimasystems.com`). Frontend changes in Flutter/Dart with existing patterns (static service methods, Hive caching, LiveUpdateService for real-time, setState for UI).

**SSH pattern:** `sshpass -p 'ZimaBlueApps' ssh -o StrictHostKeyChecking=no root@172.240.241.180 '<command>'`

**Exclusions:** Swipe-to-reply gesture is excluded (keep long-press, but improve its look/feel). E2E encryption excluded. WebSocket migration excluded (keep Firestore+REST).

---

## Phase 1: Backend — Message Delivery States + Presence + Search + Settings

**Goal:** Add all backend APIs and database changes needed by the frontend phases.

### Task 1.1: Message Status Enum + Delivery Tracking

**Server:** `app/Http/Controllers/Api/ConversationMessageController.php` (or wherever `sendMessage` lives)

**Migration:** `database/migrations/2026_03_31_100001_add_message_status_fields.php`

- [ ] Add migration:
  ```php
  Schema::table('messages', function (Blueprint $table) {
      $table->string('status', 20)->default('sent')->after('is_read');
      // Values: 'pending', 'sent', 'delivered', 'read', 'failed'
      $table->timestamp('delivered_at')->nullable()->after('read_at');
      $table->boolean('is_forwarded')->default(false)->after('status');
      $table->timestamp('edited_at')->nullable()->after('updated_at');
      $table->boolean('is_starred')->default(false)->after('is_forwarded');
      $table->index(['conversation_id', 'status']);
  });
  ```
- [ ] Run migration: `php artisan migrate`
- [ ] In the message send handler: set `status = 'sent'` on creation (server received it)
- [ ] Add `POST /conversations/{id}/messages/{msgId}/delivered` endpoint:
  ```php
  public function markDelivered(Request $request, $conversationId, $messageId) {
      $message = Message::where('id', $messageId)
          ->where('conversation_id', $conversationId)
          ->first();
      if ($message && $message->status === 'sent') {
          $message->update([
              'status' => 'delivered',
              'delivered_at' => now(),
          ]);
      }
      return response()->json(['success' => true]);
  }
  ```
- [ ] Modify the existing `markAsRead` endpoint to also set `status = 'read'` on all unread messages in the conversation:
  ```php
  Message::where('conversation_id', $conversationId)
      ->where('sender_id', '!=', $userId)
      ->whereIn('status', ['sent', 'delivered'])
      ->update([
          'status' => 'read',
          'is_read' => true,
          'read_at' => now(),
      ]);
  ```
- [ ] Ensure message JSON response includes: `status`, `delivered_at`, `is_forwarded`, `edited_at`, `is_starred`
- [ ] When editing a message, set `edited_at = now()`
- [ ] When forwarding, set `is_forwarded = true` on the new message

### Task 1.2: Online Presence / Last Seen

**Migration:** `database/migrations/2026_03_31_100002_add_presence_fields.php`

- [ ] Add migration (if `user_presence` table doesn't have `is_online`):
  ```php
  // user_presence table may already exist — check first
  // If it exists, add:
  Schema::table('user_presence', function (Blueprint $table) {
      if (!Schema::hasColumn('user_presence', 'is_online')) {
          $table->boolean('is_online')->default(false)->after('user_id');
      }
  });
  ```
- [ ] Add `POST /presence/heartbeat` endpoint:
  ```php
  public function heartbeat(Request $request) {
      $userId = $request->input('user_id');
      UserPresence::updateOrCreate(
          ['user_id' => $userId],
          ['is_online' => true, 'last_seen_at' => now()]
      );
      return response()->json(['success' => true]);
  }
  ```
- [ ] Add `GET /presence/{userId}` endpoint:
  ```php
  public function show($userId) {
      $presence = UserPresence::where('user_id', $userId)->first();
      $isOnline = $presence && $presence->last_seen_at->diffInSeconds(now()) < 30;
      return response()->json([
          'success' => true,
          'is_online' => $isOnline,
          'last_seen_at' => $presence?->last_seen_at?->toIso8601String(),
      ]);
  }
  ```
- [ ] Add `GET /presence/batch` endpoint (for conversation list — check multiple users):
  ```php
  public function batch(Request $request) {
      $userIds = $request->input('user_ids', []);
      $presences = UserPresence::whereIn('user_id', $userIds)->get();
      $result = [];
      foreach ($presences as $p) {
          $result[$p->user_id] = [
              'is_online' => $p->last_seen_at->diffInSeconds(now()) < 30,
              'last_seen_at' => $p->last_seen_at->toIso8601String(),
          ];
      }
      return response()->json(['success' => true, 'presences' => $result]);
  }
  ```
- [ ] Add scheduled command to mark offline users (cron every minute):
  ```php
  // Mark users as offline if no heartbeat for 60 seconds
  UserPresence::where('last_seen_at', '<', now()->subSeconds(60))
      ->where('is_online', true)
      ->update(['is_online' => false]);
  ```
- [ ] Register routes

### Task 1.3: Full-Text Message Search

**Migration:** `database/migrations/2026_03_31_100003_add_message_search_index.php`

- [ ] Add full-text search index:
  ```php
  DB::statement("CREATE INDEX IF NOT EXISTS idx_messages_content_fts ON messages USING gin (to_tsvector('english', COALESCE(content, '')))");
  ```
- [ ] Add `GET /conversations/search-messages` endpoint:
  ```php
  public function searchMessages(Request $request) {
      $userId = $request->input('user_id');
      $query = $request->input('q');
      $conversationId = $request->input('conversation_id'); // optional: search within one chat

      $messagesQuery = Message::whereHas('conversation.participants', function ($q) use ($userId) {
              $q->where('user_id', $userId);
          })
          ->whereRaw("to_tsvector('english', COALESCE(content, '')) @@ plainto_tsquery('english', ?)", [$query])
          ->with(['sender:id,first_name,last_name,username,profile_photo_path', 'conversation:id,name,type'])
          ->orderBy('created_at', 'desc')
          ->limit(50);

      if ($conversationId) {
          $messagesQuery->where('conversation_id', $conversationId);
      }

      $messages = $messagesQuery->get();

      return response()->json([
          'success' => true,
          'messages' => $messages,
      ]);
  }
  ```
- [ ] Register route: `GET /conversations/search-messages?user_id=X&q=term&conversation_id=Y`

### Task 1.4: Server-Synced Conversation Settings (Mute, Pin, Archive)

**Migration:** `database/migrations/2026_03_31_100004_add_conversation_settings.php`

- [ ] Add columns to `conversation_participants` pivot:
  ```php
  Schema::table('conversation_participants', function (Blueprint $table) {
      if (!Schema::hasColumn('conversation_participants', 'is_pinned')) {
          $table->boolean('is_pinned')->default(false);
      }
      if (!Schema::hasColumn('conversation_participants', 'is_archived')) {
          $table->boolean('is_archived')->default(false);
      }
      if (!Schema::hasColumn('conversation_participants', 'muted_until')) {
          $table->timestamp('muted_until')->nullable(); // null = not muted
      }
      if (!Schema::hasColumn('conversation_participants', 'is_starred')) {
          $table->boolean('is_starred')->default(false); // "favorite"
      }
  });
  ```
- [ ] Add `PATCH /conversations/{id}/settings` endpoint:
  ```php
  public function updateSettings(Request $request, $conversationId) {
      $userId = $request->input('user_id');
      $participant = ConversationParticipant::where('conversation_id', $conversationId)
          ->where('user_id', $userId)->first();

      $fields = $request->only(['is_pinned', 'is_archived', 'muted_until', 'is_starred']);
      $participant->update($fields);

      return response()->json(['success' => true, 'participant' => $participant]);
  }
  ```
- [ ] Ensure conversation list response includes `is_pinned`, `is_archived`, `muted_until`, `is_starred` per participant
- [ ] Register route

### Task 1.5: Starred Messages

- [ ] Add `POST /conversations/{id}/messages/{msgId}/star` endpoint:
  ```php
  public function toggleStar(Request $request, $conversationId, $messageId) {
      $message = Message::where('id', $messageId)
          ->where('conversation_id', $conversationId)->first();
      $message->update(['is_starred' => !$message->is_starred]);
      return response()->json(['success' => true, 'is_starred' => $message->is_starred]);
  }
  ```
- [ ] Add `GET /messages/starred?user_id=X` endpoint:
  ```php
  public function starredMessages(Request $request) {
      $userId = $request->input('user_id');
      $messages = Message::where('is_starred', true)
          ->whereHas('conversation.participants', fn($q) => $q->where('user_id', $userId))
          ->with(['sender', 'conversation:id,name,type'])
          ->orderBy('created_at', 'desc')
          ->paginate(20);
      return response()->json(['success' => true, 'messages' => $messages]);
  }
  ```
- [ ] Register routes

### Task 1.6: Link Preview Metadata Storage

**Migration:** `database/migrations/2026_03_31_100005_add_link_preview_fields.php`

- [ ] Add columns to `messages`:
  ```php
  Schema::table('messages', function (Blueprint $table) {
      $table->string('link_preview_url', 500)->nullable();
      $table->string('link_preview_title', 300)->nullable();
      $table->string('link_preview_description', 500)->nullable();
      $table->string('link_preview_image', 500)->nullable();
      $table->string('link_preview_domain', 100)->nullable();
  });
  ```
- [ ] In the message send handler, if `link_preview` JSON object is present in request, save the fields
- [ ] Ensure message JSON response includes link_preview fields
- [ ] Register: accept `link_preview` object in `sendMessage` request body

### Task 1.7: Disappearing Messages

**Migration:** `database/migrations/2026_03_31_100006_add_disappearing_messages.php`

- [ ] Add columns:
  ```php
  Schema::table('conversations', function (Blueprint $table) {
      $table->integer('disappearing_timer')->nullable(); // seconds: 86400(24h), 604800(7d), 7776000(90d), null=off
  });
  Schema::table('messages', function (Blueprint $table) {
      $table->timestamp('expires_at')->nullable();
      $table->index('expires_at');
  });
  ```
- [ ] Add `PATCH /conversations/{id}/disappearing` endpoint:
  ```php
  public function setDisappearingTimer(Request $request, $conversationId) {
      $timer = $request->input('timer'); // null to disable, or seconds
      Conversation::where('id', $conversationId)->update(['disappearing_timer' => $timer]);
      return response()->json(['success' => true]);
  }
  ```
- [ ] In send message handler: if conversation has `disappearing_timer`, set `expires_at = now()->addSeconds($timer)`
- [ ] Add artisan command (cron every 5 min): delete expired messages
  ```php
  Message::whereNotNull('expires_at')->where('expires_at', '<', now())->delete();
  ```
- [ ] Register routes

### Task 1.8: Group Read Receipts

- [ ] Add `GET /conversations/{id}/messages/{msgId}/receipts` endpoint:
  ```php
  public function messageReceipts($conversationId, $messageId) {
      $message = Message::where('id', $messageId)->first();
      $participants = ConversationParticipant::where('conversation_id', $conversationId)->with('user')->get();

      $receipts = $participants->map(function ($p) use ($message) {
          return [
              'user_id' => $p->user_id,
              'user' => $p->user,
              'delivered_at' => $message->delivered_at, // same for all for now
              'read_at' => $p->last_read_at && $p->last_read_at >= $message->created_at
                  ? $p->last_read_at : null,
          ];
      });

      return response()->json(['success' => true, 'receipts' => $receipts]);
  }
  ```
- [ ] Register route

### Task 1.9: Run All Migrations

- [ ] SSH to server, run: `php artisan migrate`
- [ ] Clear caches: `php artisan cache:clear && php artisan config:clear`
- [ ] Verify: `php artisan route:list --path=conversations | head -30`

---

## Phase 2: Frontend — Message Delivery States (clock → ✓ → ✓✓ → blue ✓✓)

**Goal:** Show real-time message status in chat bubbles and conversation list.

### Task 2.1: Update Message Model

**File:** `lib/models/message_models.dart`

- [ ] Add `MessageStatus` enum after `MessageType` (around line 387):
  ```dart
  enum MessageStatus {
    pending,
    sent,
    delivered,
    read,
    failed;

    factory MessageStatus.fromString(String? s) {
      switch (s) {
        case 'sent': return MessageStatus.sent;
        case 'delivered': return MessageStatus.delivered;
        case 'read': return MessageStatus.read;
        case 'failed': return MessageStatus.failed;
        default: return MessageStatus.pending;
      }
    }
  }
  ```
- [ ] Add fields to `Message` class constructor (line ~180):
  ```dart
  final MessageStatus status;
  final DateTime? deliveredAt;
  final bool isForwarded;
  final DateTime? editedAt;
  final bool isStarred;
  final String? linkPreviewUrl;
  final String? linkPreviewTitle;
  final String? linkPreviewDescription;
  final String? linkPreviewImage;
  final String? linkPreviewDomain;
  final DateTime? expiresAt;
  ```
- [ ] Update `Message.fromJson` (line ~201) to parse new fields:
  ```dart
  status: MessageStatus.fromString(json['status'] as String?),
  deliveredAt: json['delivered_at'] != null ? DateTime.tryParse(json['delivered_at'].toString()) : null,
  isForwarded: json['is_forwarded'] == true || json['is_forwarded'] == 1,
  editedAt: json['edited_at'] != null ? DateTime.tryParse(json['edited_at'].toString()) : null,
  isStarred: json['is_starred'] == true || json['is_starred'] == 1,
  linkPreviewUrl: json['link_preview_url'] as String?,
  linkPreviewTitle: json['link_preview_title'] as String?,
  linkPreviewDescription: json['link_preview_description'] as String?,
  linkPreviewImage: json['link_preview_image'] as String?,
  linkPreviewDomain: json['link_preview_domain'] as String?,
  expiresAt: json['expires_at'] != null ? DateTime.tryParse(json['expires_at'].toString()) : null,
  ```
- [ ] Update `Message.toJson` (line ~244) with all new fields
- [ ] Update `Message.copyWith` (line ~300) with all new fields
- [ ] Update `_messageToJsonShallow` (line ~272) with new fields
- [ ] Add getter `bool get hasLinkPreview => linkPreviewUrl != null && linkPreviewUrl!.isNotEmpty;`

### Task 2.2: Update Conversation Model for Server Settings

**File:** `lib/models/message_models.dart`

- [ ] Add to `ConversationParticipant` class (line ~399):
  ```dart
  final bool isPinned;
  final bool isArchived;
  final DateTime? mutedUntil;
  final bool isStarred; // "favorite"
  ```
- [ ] Parse in `ConversationParticipant.fromJson` from both standard and pivot formats:
  ```dart
  isPinned: pivot?['is_pinned'] == true || pivot?['is_pinned'] == 1,
  isArchived: pivot?['is_archived'] == true || pivot?['is_archived'] == 1,
  mutedUntil: pivot?['muted_until'] != null ? DateTime.tryParse(pivot!['muted_until'].toString()) : null,
  isStarred: pivot?['is_starred'] == true || pivot?['is_starred'] == 1,
  ```
- [ ] Add to `Conversation` class:
  ```dart
  final int? disappearingTimer; // seconds or null
  ```
- [ ] Parse `disappearingTimer` in `Conversation.fromJson`:
  ```dart
  disappearingTimer: json['disappearing_timer'] as int?,
  ```
- [ ] Add helper getters on `Conversation`:
  ```dart
  bool get hasDisappearingMessages => disappearingTimer != null && disappearingTimer! > 0;
  String get disappearingLabel {
    if (disappearingTimer == null) return '';
    if (disappearingTimer! <= 86400) return '24h';
    if (disappearingTimer! <= 604800) return '7d';
    return '90d';
  }
  ```

### Task 2.3: Message Status Icons Widget

**File:** `lib/screens/messages/chat_screen.dart` — add inside the file or as a private widget

- [ ] Create `_MessageStatusIcon` widget in `chat_screen.dart`:
  ```dart
  class _MessageStatusIcon extends StatelessWidget {
    final MessageStatus status;
    final bool isMe;
    const _MessageStatusIcon({required this.status, required this.isMe});

    @override
    Widget build(BuildContext context) {
      if (!isMe) return const SizedBox.shrink();
      switch (status) {
        case MessageStatus.pending:
          return const Icon(Icons.access_time, size: 14, color: Color(0xFF999999));
        case MessageStatus.sent:
          return const Icon(Icons.check, size: 14, color: Color(0xFF999999));
        case MessageStatus.delivered:
          return const Icon(Icons.done_all, size: 14, color: Color(0xFF999999));
        case MessageStatus.read:
          return const Icon(Icons.done_all, size: 14, color: Color(0xFF2196F3));
        case MessageStatus.failed:
          return const Icon(Icons.error_outline, size: 14, color: Color(0xFFE53935));
      }
    }
  }
  ```
- [ ] Replace the existing read-status icon in the message bubble with `_MessageStatusIcon(status: message.status, isMe: isMe)`
- [ ] In `_sendMessage()`: create a local `Message` with `status: MessageStatus.pending` and insert into `_messages` immediately (true optimistic UI). On API success, update to `MessageStatus.sent`. On failure, update to `MessageStatus.failed`.
- [ ] Add retry mechanism: if `status == failed`, show a tap-to-retry icon that re-calls `_sendMessage()`

### Task 2.4: Message Status in Conversation List

**File:** `lib/screens/messages/conversations_screen.dart`

- [ ] In the conversation list item, show the status icon next to the last message preview (only for messages sent by the current user):
  ```dart
  if (conv.lastMessage != null && conv.lastMessage!.senderId == widget.currentUserId)
    _MessageStatusIcon(status: conv.lastMessage!.status, isMe: true),
  ```
- [ ] Import or inline the `_MessageStatusIcon` widget

### Task 2.5: Mark Delivered on App Open

**File:** `lib/services/message_service.dart`

- [ ] Add `markDelivered` method:
  ```dart
  static Future<bool> markDelivered(int conversationId, int messageId, int userId) async {
    try {
      final url = '$_baseUrl/conversations/$conversationId/messages/$messageId/delivered';
      final resp = await http.post(Uri.parse(url), headers: ApiConfig.headers,
          body: jsonEncode({'user_id': userId}));
      return resp.statusCode == 200;
    } catch (_) { return false; }
  }
  ```
- [ ] In `ChatScreen._loadMessages()`: after fetching messages, batch-mark any `status: sent` messages (not from current user) as delivered:
  ```dart
  for (final msg in newMessages) {
    if (msg.senderId != widget.currentUserId && msg.status == MessageStatus.sent) {
      MessageService.markDelivered(widget.conversationId, msg.id, widget.currentUserId);
    }
  }
  ```

---

## Phase 3: Frontend — Online Presence / Last Seen

**Goal:** Show green dot + "Online" or "Last seen X" in chat header and conversation list.

### Task 3.1: Presence Service

**New file:** `lib/services/presence_service.dart`

- [ ] Create `PresenceService` with static methods:
  ```dart
  import 'dart:convert';
  import 'package:http/http.dart' as http;
  import '../config/api_config.dart';

  class PresenceService {
    static String get _baseUrl => ApiConfig.baseUrl;

    /// Send heartbeat every 10 seconds while app is active
    static Future<void> heartbeat(int userId) async {
      try {
        await http.post(Uri.parse('$_baseUrl/presence/heartbeat'),
            headers: ApiConfig.headers,
            body: jsonEncode({'user_id': userId}));
      } catch (_) {}
    }

    /// Get single user's presence
    static Future<PresenceInfo?> getPresence(int userId) async {
      try {
        final resp = await http.get(
            Uri.parse('$_baseUrl/presence/$userId'),
            headers: ApiConfig.headers);
        if (resp.statusCode == 200) {
          final data = jsonDecode(resp.body);
          return PresenceInfo(
            isOnline: data['is_online'] == true,
            lastSeenAt: data['last_seen_at'] != null
                ? DateTime.tryParse(data['last_seen_at']) : null,
          );
        }
      } catch (_) {}
      return null;
    }

    /// Batch presence for conversation list
    static Future<Map<int, PresenceInfo>> batchPresence(List<int> userIds) async {
      if (userIds.isEmpty) return {};
      try {
        final resp = await http.post(
            Uri.parse('$_baseUrl/presence/batch'),
            headers: ApiConfig.headers,
            body: jsonEncode({'user_ids': userIds}));
        if (resp.statusCode == 200) {
          final data = jsonDecode(resp.body);
          final presences = data['presences'] as Map<String, dynamic>? ?? {};
          return presences.map((k, v) => MapEntry(
            int.parse(k),
            PresenceInfo(
              isOnline: v['is_online'] == true,
              lastSeenAt: v['last_seen_at'] != null
                  ? DateTime.tryParse(v['last_seen_at'].toString()) : null,
            ),
          ));
        }
      } catch (_) {}
      return {};
    }
  }

  class PresenceInfo {
    final bool isOnline;
    final DateTime? lastSeenAt;
    const PresenceInfo({required this.isOnline, this.lastSeenAt});

    String get lastSeenLabel {
      if (isOnline) return 'Online';
      if (lastSeenAt == null) return '';
      final diff = DateTime.now().difference(lastSeenAt!);
      if (diff.inMinutes < 1) return 'Last seen just now';
      if (diff.inMinutes < 60) return 'Last seen ${diff.inMinutes}m ago';
      if (diff.inHours < 24) return 'Last seen ${diff.inHours}h ago';
      if (diff.inDays < 7) return 'Last seen ${diff.inDays}d ago';
      return 'Last seen ${lastSeenAt!.day}/${lastSeenAt!.month}';
    }
  }
  ```

### Task 3.2: Heartbeat Timer in HomeScreen

**File:** `lib/screens/home/home_screen.dart`

- [ ] Import `PresenceService`
- [ ] In `initState`, start a 10-second periodic timer:
  ```dart
  _heartbeatTimer = Timer.periodic(const Duration(seconds: 10), (_) {
    PresenceService.heartbeat(widget.currentUserId);
  });
  ```
- [ ] Send one immediate heartbeat on init: `PresenceService.heartbeat(widget.currentUserId);`
- [ ] Cancel in `dispose()`

### Task 3.3: Presence in Chat Header

**File:** `lib/screens/messages/chat_screen.dart`

- [ ] Add state: `PresenceInfo? _otherUserPresence;`
- [ ] In `initState`, if 1:1 chat, fetch presence for the other user:
  ```dart
  if (!_conversation!.isGroup) {
    final otherUserId = _conversation!.participants
        .firstWhere((p) => p.userId != widget.currentUserId).userId;
    PresenceService.getPresence(otherUserId).then((info) {
      if (mounted && info != null) setState(() => _otherUserPresence = info);
    });
  }
  ```
- [ ] In the AppBar subtitle, replace the participant count with presence:
  ```dart
  subtitle: _conversation!.isGroup
      ? Text('${_conversation!.participants.length} members')
      : Text(
          _otherUserPresence?.lastSeenLabel ?? '',
          style: TextStyle(
            fontSize: 12,
            color: _otherUserPresence?.isOnline == true
                ? const Color(0xFF25D366) : const Color(0xFF999999),
          ),
        ),
  ```

### Task 3.4: Online Dot in Conversation List

**File:** `lib/screens/messages/conversations_screen.dart`

- [ ] Add state: `Map<int, PresenceInfo> _presences = {};`
- [ ] After loading conversations, extract 1:1 partner user IDs and batch-fetch presence:
  ```dart
  final partnerIds = _conversations
      .where((c) => c.isPrivate)
      .map((c) => c.participants.firstWhere((p) => p.userId != widget.currentUserId).userId)
      .toSet().toList();
  PresenceService.batchPresence(partnerIds).then((map) {
    if (mounted) setState(() => _presences = map);
  });
  ```
- [ ] In conversation list item avatar: overlay green dot if partner is online:
  ```dart
  // On the avatar Stack, add:
  if (isOnline)
    Positioned(right: 0, bottom: 0, child: Container(
      width: 12, height: 12,
      decoration: BoxDecoration(
        color: const Color(0xFF25D366),
        shape: BoxShape.circle,
        border: Border.all(color: Colors.white, width: 2),
      ),
    )),
  ```

---

## Phase 4: Frontend — Message Search

**Goal:** Full-text search across all chats and within a single chat.

### Task 4.1: Message Search Service Method

**File:** `lib/services/message_service.dart`

- [ ] Add `searchMessages` method:
  ```dart
  static Future<MessageListResult> searchMessages({
    required int userId,
    required String query,
    int? conversationId,
  }) async {
    try {
      var url = '$_baseUrl/conversations/search-messages?user_id=$userId&q=${Uri.encodeComponent(query)}';
      if (conversationId != null) url += '&conversation_id=$conversationId';
      final resp = await http.get(Uri.parse(url), headers: ApiConfig.headers);
      if (resp.statusCode == 200) {
        final data = jsonDecode(resp.body);
        final messages = (data['messages'] as List? ?? [])
            .map((m) => Message.fromJson(m)).toList();
        return MessageListResult(success: true, messages: messages);
      }
      return MessageListResult(success: false, messages: [], message: 'Search failed');
    } catch (e) {
      return MessageListResult(success: false, messages: [], message: e.toString());
    }
  }
  ```

### Task 4.2: Global Message Search Screen

**File:** `lib/screens/messages/search_conversations_screen.dart` (modify existing or replace)

- [ ] Add a "Messages" tab to the search results showing matching messages grouped by conversation
- [ ] Each result shows: conversation name/avatar, message sender, message preview with highlighted query match, timestamp
- [ ] Tapping a result opens ChatScreen and scrolls to the matching message

### Task 4.3: In-Chat Message Search

**File:** `lib/screens/messages/chat_screen.dart`

- [ ] Replace the "Coming soon" stub (line ~1679) with actual search functionality
- [ ] Add search bar at top of chat (slides down, like WhatsApp)
- [ ] State: `bool _showSearchBar`, `String _searchQuery`, `List<Message> _searchResults`, `int _searchIndex`
- [ ] Up/down arrows to navigate between matches
- [ ] Matching messages highlighted with yellow background
- [ ] Close search → return to normal view

---

## Phase 5: Frontend — Link Previews

**Goal:** Auto-detect URLs in messages and show rich preview cards.

### Task 5.1: Link Preview Fetcher

**New file:** `lib/services/link_preview_service.dart`

- [ ] Create service that fetches OG metadata from a URL:
  ```dart
  import 'package:http/http.dart' as http;

  class LinkPreviewService {
    static final Map<String, LinkPreviewData?> _cache = {};

    static Future<LinkPreviewData?> fetchPreview(String url) async {
      if (_cache.containsKey(url)) return _cache[url];
      try {
        final resp = await http.get(Uri.parse(url)).timeout(const Duration(seconds: 5));
        if (resp.statusCode != 200) return null;
        final body = resp.body;
        final title = _extractMeta(body, 'og:title') ?? _extractTitle(body);
        final description = _extractMeta(body, 'og:description');
        final image = _extractMeta(body, 'og:image');
        final domain = Uri.parse(url).host;
        final preview = LinkPreviewData(url: url, title: title, description: description, image: image, domain: domain);
        _cache[url] = preview;
        return preview;
      } catch (_) {
        _cache[url] = null;
        return null;
      }
    }

    static String? _extractMeta(String html, String property) {
      final regex = RegExp('<meta[^>]+property=["\']$property["\'][^>]+content=["\']([^"\']+)["\']', caseSensitive: false);
      final match = regex.firstMatch(html);
      if (match != null) return match.group(1);
      // Try name= attribute too
      final regex2 = RegExp('<meta[^>]+name=["\']$property["\'][^>]+content=["\']([^"\']+)["\']', caseSensitive: false);
      return regex2.firstMatch(html)?.group(1);
    }

    static String? _extractTitle(String html) {
      final regex = RegExp('<title>([^<]+)</title>', caseSensitive: false);
      return regex.firstMatch(html)?.group(1)?.trim();
    }
  }

  class LinkPreviewData {
    final String url;
    final String? title;
    final String? description;
    final String? image;
    final String? domain;
    const LinkPreviewData({required this.url, this.title, this.description, this.image, this.domain});

    Map<String, dynamic> toJson() => {
      'url': url, 'title': title, 'description': description, 'image': image, 'domain': domain,
    };
  }
  ```

### Task 5.2: Link Preview in Send Flow

**File:** `lib/screens/messages/chat_screen.dart`

- [ ] Add state: `LinkPreviewData? _linkPreview;`
- [ ] In `_onTypingChanged`, detect URLs using regex: `RegExp(r'https?://\S+')`
- [ ] When URL detected, fetch preview in background (debounced 500ms)
- [ ] Show preview card above the input bar (dismissible with X)
- [ ] On send: include `link_preview` object in the API call
- [ ] Clear preview after send

### Task 5.3: Link Preview in Message Bubble

**File:** `lib/screens/messages/chat_screen.dart`

- [ ] In the message bubble, if `message.hasLinkPreview`, render a card below the text:
  ```dart
  Container(
    margin: const EdgeInsets.only(top: 8),
    decoration: BoxDecoration(
      border: Border(top: BorderSide(color: Colors.grey.shade300)),
    ),
    child: Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        if (message.linkPreviewImage != null)
          ClipRRect(
            borderRadius: BorderRadius.circular(8),
            child: CachedMediaImage(imageUrl: message.linkPreviewImage!, height: 150, width: double.infinity, fit: BoxFit.cover),
          ),
        if (message.linkPreviewTitle != null)
          Padding(padding: EdgeInsets.only(top: 6),
            child: Text(message.linkPreviewTitle!, style: TextStyle(fontWeight: FontWeight.w600, fontSize: 13), maxLines: 2, overflow: TextOverflow.ellipsis)),
        if (message.linkPreviewDescription != null)
          Text(message.linkPreviewDescription!, style: TextStyle(fontSize: 12, color: Color(0xFF666666)), maxLines: 2, overflow: TextOverflow.ellipsis),
        if (message.linkPreviewDomain != null)
          Text(message.linkPreviewDomain!, style: TextStyle(fontSize: 11, color: Color(0xFF999999))),
      ],
    ),
  )
  ```
- [ ] Make the preview tappable → `launchUrl(message.linkPreviewUrl)`

---

## Phase 6: Frontend — Conversation Settings (Server-Synced)

**Goal:** Migrate pin/archive/mute/favorite from SharedPreferences to server.

### Task 6.1: Settings Service Methods

**File:** `lib/services/message_service.dart`

- [ ] Add `updateConversationSettings` method:
  ```dart
  static Future<bool> updateConversationSettings({
    required int conversationId,
    required int userId,
    bool? isPinned,
    bool? isArchived,
    String? mutedUntil, // ISO8601 or null to unmute
    bool? isStarred,
  }) async {
    try {
      final body = <String, dynamic>{'user_id': userId};
      if (isPinned != null) body['is_pinned'] = isPinned;
      if (isArchived != null) body['is_archived'] = isArchived;
      if (mutedUntil != null) body['muted_until'] = mutedUntil;
      if (isStarred != null) body['is_starred'] = isStarred;
      final resp = await http.patch(
        Uri.parse('$_baseUrl/conversations/$conversationId/settings'),
        headers: ApiConfig.headers,
        body: jsonEncode(body),
      );
      return resp.statusCode == 200;
    } catch (_) { return false; }
  }
  ```

### Task 6.2: Migrate ConversationsScreen

**File:** `lib/screens/messages/conversations_screen.dart`

- [ ] Remove SharedPreferences-based `_pinnedIds`, `_archivedIds`, `_favoriteIds` (lines 75-78)
- [ ] Instead, derive from `ConversationParticipant` fields:
  ```dart
  bool _isPinned(Conversation c) => c.participants
      .any((p) => p.userId == widget.currentUserId && p.isPinned);
  bool _isArchived(Conversation c) => c.participants
      .any((p) => p.userId == widget.currentUserId && p.isArchived);
  bool _isFavorite(Conversation c) => c.participants
      .any((p) => p.userId == widget.currentUserId && p.isStarred);
  bool _isMuted(Conversation c) {
    final p = c.participants.where((p) => p.userId == widget.currentUserId).firstOrNull;
    return p?.mutedUntil != null && p!.mutedUntil!.isAfter(DateTime.now());
  }
  ```
- [ ] Update `_togglePin`, `_toggleArchived`, `_toggleFavorite` to call `MessageService.updateConversationSettings()` then refresh
- [ ] Add mute options: 8 hours, 1 week, Always (set `mutedUntil` accordingly)
- [ ] Remove `_loadChatPrefs()` and related SharedPreferences logic (keep drafts in SharedPreferences — those are local-only)

---

## Phase 7: Frontend — Starred Messages, Forward Label, Disappearing Messages

### Task 7.1: Star/Unstar in Chat

**File:** `lib/screens/messages/chat_screen.dart`

- [ ] Add `toggleStar` method in `MessageService`:
  ```dart
  static Future<bool> toggleStar(int conversationId, int messageId, int userId) async {
    try {
      final resp = await http.post(
        Uri.parse('$_baseUrl/conversations/$conversationId/messages/$messageId/star'),
        headers: ApiConfig.headers,
        body: jsonEncode({'user_id': userId}),
      );
      return resp.statusCode == 200;
    } catch (_) { return false; }
  }
  ```
- [ ] In the long-press menu, add "Star" / "Unstar" option with star icon
- [ ] Optimistic toggle: update local message `isStarred`, then call API

### Task 7.2: Starred Messages Screen

**New file:** `lib/screens/messages/starred_messages_screen.dart`

- [ ] Create screen that fetches `GET /messages/starred?user_id=X`
- [ ] Display list of starred messages grouped by conversation
- [ ] Each item shows: conversation name, message content, timestamp
- [ ] Tap → navigate to ChatScreen at that message
- [ ] Access from conversations screen menu (3-dot → Starred messages)

### Task 7.3: Forward Label

**File:** `lib/screens/messages/chat_screen.dart`

- [ ] In the message bubble, if `message.isForwarded`, show a label above the content:
  ```dart
  if (message.isForwarded)
    Padding(
      padding: const EdgeInsets.only(bottom: 4),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(Icons.shortcut, size: 13, color: Color(0xFF999999)),
          const SizedBox(width: 4),
          Text('Forwarded', style: TextStyle(fontSize: 11, color: Color(0xFF999999), fontStyle: FontStyle.italic)),
        ],
      ),
    ),
  ```

### Task 7.4: Edited Label

**File:** `lib/screens/messages/chat_screen.dart`

- [ ] In the message bubble timestamp area, if `message.editedAt != null`, show "Edited" next to time:
  ```dart
  if (message.editedAt != null)
    Text('Edited ', style: TextStyle(fontSize: 10, color: Color(0xFF999999), fontStyle: FontStyle.italic)),
  ```

### Task 7.5: Disappearing Messages UI

**File:** `lib/screens/messages/chat_screen.dart`

- [ ] In the 3-dot menu, add "Disappearing messages" option
- [ ] Show bottom sheet with options: Off, 24 hours, 7 days, 90 days
- [ ] Call `PATCH /conversations/{id}/disappearing` with selected timer
- [ ] Show a small timer icon in the chat header if disappearing is enabled
- [ ] Show system message in chat when setting changes: "Disappearing messages set to 24h"

---

## Phase 8: Frontend — Emoji Reaction Picker + Voice Speed

### Task 8.1: Full Emoji Reaction Picker

**File:** `lib/screens/messages/chat_screen.dart`

- [ ] Replace the hardcoded 6-emoji list with a proper picker:
  - Keep 6 quick-access emojis in a top row
  - Add a "+" button that opens full emoji grid (use `emoji_picker_flutter` package or build a simple grid)
  - Group by category: Smileys, People, Animals, Food, Activities, Travel, Objects, Symbols
  - Search bar at top of picker
- [ ] Add `emoji_picker_flutter: ^3.1.0` to `pubspec.yaml` (or build a simple grid with common emojis)
- [ ] The picker appears as a bottom sheet anchored below the long-pressed message

### Task 8.2: Voice Message Speed Control

**File:** `lib/screens/messages/chat_screen.dart`

- [ ] In the audio message playback widget, add a speed toggle button:
  ```dart
  TextButton(
    onPressed: () => setState(() {
      _playbackSpeed = _playbackSpeed == 1.0 ? 1.5 : _playbackSpeed == 1.5 ? 2.0 : 1.0;
      _audioPlayer?.setSpeed(_playbackSpeed);
    }),
    child: Text('${_playbackSpeed}x', style: TextStyle(fontSize: 11, fontWeight: FontWeight.w600)),
  )
  ```
- [ ] State: `double _playbackSpeed = 1.0;`
- [ ] Display speeds: 1x → 1.5x → 2x → cycle back to 1x

---

## Phase 9: Frontend — Group Read Receipts + Improved Reply UX

### Task 9.1: Message Info Screen (Group Read Receipts)

**New file:** `lib/screens/messages/message_info_screen.dart`

- [ ] Create screen showing per-member delivery and read status for a group message
- [ ] Fetch `GET /conversations/{id}/messages/{msgId}/receipts`
- [ ] Show two sections: "Read by" (with timestamps) and "Delivered to" (with timestamps)
- [ ] Each row: avatar, name, timestamp
- [ ] Access from long-press menu → "Info" (only for sent messages in groups)

### Task 9.2: Add `getMessageReceipts` to MessageService

**File:** `lib/services/message_service.dart`

- [ ] Add method:
  ```dart
  static Future<List<MessageReceipt>> getMessageReceipts(int conversationId, int messageId, int userId) async {
    try {
      final resp = await http.get(
        Uri.parse('$_baseUrl/conversations/$conversationId/messages/$messageId/receipts?user_id=$userId'),
        headers: ApiConfig.headers,
      );
      if (resp.statusCode == 200) {
        final data = jsonDecode(resp.body);
        return (data['receipts'] as List? ?? [])
            .map((r) => MessageReceipt.fromJson(r)).toList();
      }
    } catch (_) {}
    return [];
  }
  ```

### Task 9.3: MessageReceipt Model

**File:** `lib/models/message_models.dart`

- [ ] Add class:
  ```dart
  class MessageReceipt {
    final int userId;
    final PostUser? user;
    final DateTime? deliveredAt;
    final DateTime? readAt;

    const MessageReceipt({required this.userId, this.user, this.deliveredAt, this.readAt});

    factory MessageReceipt.fromJson(Map<String, dynamic> json) => MessageReceipt(
      userId: json['user_id'] as int? ?? 0,
      user: json['user'] != null ? PostUser.fromJson(json['user']) : null,
      deliveredAt: json['delivered_at'] != null ? DateTime.tryParse(json['delivered_at'].toString()) : null,
      readAt: json['read_at'] != null ? DateTime.tryParse(json['read_at'].toString()) : null,
    );
  }
  ```

### Task 9.4: Improved Reply UX (Long-Press Menu Redesign)

**File:** `lib/screens/messages/chat_screen.dart`

- [ ] Replace the current `showModalBottomSheet` long-press menu with a **context menu** that appears near the message:
  - Background dims slightly
  - Menu appears above or below the message bubble (depending on position)
  - Quick-reaction emoji row at top (6 emojis + "+" for full picker)
  - Below: Reply, Forward, Copy, Star, Edit (if own), Delete (if own), Info (if group)
  - Each action has an icon + label in a clean grid/list
  - Smooth animation (fade + scale from message)
- [ ] Style the menu with rounded corners, subtle shadow, white background, monochromatic icons
- [ ] The reply preview bar (when replying) should show:
  - Colored vertical bar (sender's color)
  - Sender name in bold
  - Message preview (truncated)
  - X to cancel
  - Slide-in animation from bottom

---

## Execution Order & Dependencies

```
Phase 1 (Backend)     ← Start here — all frontend phases depend on these APIs
Phase 2 (Status)      ← Depends on Task 1.1 (status fields)
Phase 3 (Presence)    ← Depends on Task 1.2 (presence endpoints)
Phase 4 (Search)      ← Depends on Task 1.3 (search endpoint)
Phase 5 (Link Preview)← Depends on Task 1.6 (link preview fields)
Phase 6 (Settings)    ← Depends on Task 1.4 (settings columns)
Phase 7 (Star/Fwd/Disappear) ← Depends on Tasks 1.1, 1.5, 1.7
Phase 8 (Emoji/Voice) ← No backend dependency (frontend-only)
Phase 9 (Receipts/UX) ← Depends on Task 1.8 (receipts endpoint)
```

**Recommended parallel execution:**
- Phase 1 (backend) first
- Then Phases 2+3+8 in parallel (independent frontend work)
- Then Phases 4+5+6 in parallel
- Then Phases 7+9

---

## Files Summary

### New Files (Frontend)
| File | Phase | Purpose |
|------|-------|---------|
| `lib/services/presence_service.dart` | 3 | Heartbeat + presence queries |
| `lib/services/link_preview_service.dart` | 5 | OG metadata fetcher with cache |
| `lib/screens/messages/starred_messages_screen.dart` | 7 | Cross-chat starred messages |
| `lib/screens/messages/message_info_screen.dart` | 9 | Per-member read receipts |

### Modified Files (Frontend)
| File | Phase | Change |
|------|-------|--------|
| `lib/models/message_models.dart` | 2,9 | MessageStatus enum, new fields, MessageReceipt class |
| `lib/services/message_service.dart` | 2,4,6,7,9 | markDelivered, searchMessages, updateSettings, toggleStar, getReceipts |
| `lib/screens/messages/chat_screen.dart` | 2,3,4,5,7,8,9 | Status icons, presence, search, link preview, star, reactions, reply UX |
| `lib/screens/messages/conversations_screen.dart` | 2,3,6 | Status in list, online dot, server-synced settings |
| `lib/screens/home/home_screen.dart` | 3 | Heartbeat timer |
| `pubspec.yaml` | 8 | emoji_picker_flutter |

### Backend Changes
| Change | Phase | Detail |
|--------|-------|--------|
| 6 migrations | 1 | status/presence/FTS/settings/link_preview/disappearing |
| ~10 new endpoints | 1 | delivered, presence, search, settings, star, disappearing, receipts |
| Cron jobs | 1 | Offline marker, expired message cleanup |
