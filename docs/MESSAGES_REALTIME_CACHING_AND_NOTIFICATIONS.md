# Messages Module: Live Updates, Notifications, Caching & Performance

This document describes how the Messages module integrates with the **backend changes notifier** (LiveUpdateService), how **Firebase push notifications** are received and open the right screen, how **live unread count** and **message/image caching and syncing** work, and how to approach **WhatsApp-like performance**.

---

## 1. Backend changes notifier (LiveUpdateService)

### 1.1 How it works

- **Backend** (Laravel) writes to Firestore `updates/{userId}` when messages/conversations change (e.g. new message, new conversation, message read). Payload: `event: "messages_updated"`, `payload: { "conversation_id": <int> }` (see [BACKEND_LIVE_UPDATE_CONTRACT.md](BACKEND_LIVE_UPDATE_CONTRACT.md)).
- **LiveUpdateService** (singleton) listens to `updates/{userId}` with Firestore `snapshots()`. It parses the document and emits **MessagesUpdateEvent(conversationId)** to a broadcast stream.
- **Screens** that care about messages must **subscribe** to `LiveUpdateService.instance.stream` and, on `MessagesUpdateEvent`, refetch data from the REST API (source of truth) and update UI.

### 1.2 Current integration

- **HomeScreen** starts `LiveUpdateService.instance.start(currentUserId)` on init and stops on dispose. It does **not** listen to the stream; it only loads unread count on init and when user taps the Messages tab.
- **ConversationsScreen** and **ChatScreen** did **not** subscribe to the stream, so conversation list and open chat did not refresh when a new message arrived (backend still writes `messages_updated`).

### 1.3 Required app-side behaviour (implemented)

- **ConversationsScreen**: Subscribe to `LiveUpdateService.instance.stream`. On `MessagesUpdateEvent` (any or matching conversation): call `_loadConversations()` so the list (and per-conversation unread) updates.
- **ChatScreen**: Subscribe to the stream. On `MessagesUpdateEvent(conversationId)` where `conversationId == widget.conversationId`: call `_loadMessages()` (or incremental fetch; see §4) so new messages appear without leaving the screen.
- **HomeScreen** (optional but recommended): On `MessagesUpdateEvent`, call `_loadUnreadCount()` so the Messages tab badge updates in real time even when the user is on another tab.

This gives **live** conversation list and open chat without polling; backend remains source of truth.

---

## 2. Firebase push notifications (FCM)

### 2.1 Current state (implemented)

- **firebase_messaging** is in `pubspec.yaml`; the app handles FCM via **FcmService** (`lib/services/fcm_service.dart`). On init: permission, token, `onMessage`, `onMessageOpenedApp`, `getInitialMessage()`. Token is sent to backend via **POST /users/fcm-token** (body: `user_id`, `token`). See [MESSAGES_BACKEND_IMPLEMENTATION_DIRECTIVE.md](MESSAGES_BACKEND_IMPLEMENTATION_DIRECTIVE.md) §3.11.
- **Foreground:** `onMessage` logs data; LiveUpdateService can still refresh if backend writes to Firestore.
- **Background/terminated:** `onMessageOpenedApp` and `getInitialMessage()` parse payload and navigate via global **navigator key** to ChatScreen or IncomingCallScreen.

### 2.2 How notifications should be received and processed

**Add** `firebase_messaging` and configure:

1. **Token**: On login, send the FCM token to the backend (e.g. `POST /users/me/fcm-token` or similar) so the backend can target this device for message/call notifications.
2. **Foreground**: `FirebaseMessaging.onMessage` — when a data message arrives and the app is in foreground, you can either show an in-app banner or rely on LiveUpdateService (if the backend also wrote to Firestore) to refresh; optionally show a local notification via `flutter_local_notifications`.
3. **Background / Terminated**: `FirebaseMessaging.onMessageOpenedApp` (user tapped notification while app was in background) and `FirebaseMessaging.instance.getInitialMessage()` (user opened app from notification from killed state). In both cases, read the **payload** and navigate to the right screen.

**Payload contract** (agree with backend):

- **New message**: `{ "type": "new_message", "conversation_id": 123, "message_id": 456 }`. App: navigate to `ChatScreen(conversationId: 123)` (and optionally scroll to or highlight `message_id`).
- **Incoming call**: `{ "type": "call_incoming", "call_id": "uuid", "caller_id": 1 }`. App: show incoming-call UI (full-screen or overlay) and pass `call_id` to accept/decline.
- **Group call invite**: `{ "type": "group_call_invite", "call_id": "uuid", "conversation_id": 123 }`. App: show “Join group call?” and open GroupCallScreen on accept.

**Processing flow**:

- In `main.dart` (or a dedicated `FcmHandler`), after `WidgetsBinding.instance.ensureInitialized()` and Firebase init:
  - Call `getInitialMessage()`. If not null, parse payload and schedule navigation (e.g. after first frame to the home route, then push ChatScreen or call screen).
  - Subscribe `onMessageOpenedApp`. When fired, parse payload and `Navigator.push` to ChatScreen or call UI with the right ids.
- Use a **global navigator key** (e.g. `navigatorKey` on `MaterialApp`) so FCM handlers can navigate even when no screen has context (e.g. from background).

Result: user taps “New message from X” → app opens (if needed) and lands on that conversation; taps “Incoming call” → call screen.

---

## 3. Live unread count

### 3.1 Current behaviour (implemented)

- **HomeScreen** calls `_messageService.getUnreadCount(userId)` on init and when the user taps the Messages tab. It also **subscribes** to `LiveUpdateService.instance.stream` and, on **MessagesUpdateEvent**, calls `_loadUnreadCount()` so the bottom nav badge updates in real time.
- **ConversationsScreen** subscribes to the stream and refetches the list on **MessagesUpdateEvent**; the list response includes updated `unread_count` per conversation.

### 3.2 Making it “live”

- **Option A (recommended, minimal)**: When **MessagesUpdateEvent** is received, **refetch the conversation list** in ConversationsScreen (already done in §1.3). The list response includes updated `unread_count` per conversation. For the **global badge** on the bottom nav, either:
  - **HomeScreen** listens to `MessagesUpdateEvent` and calls `getUnreadCount(userId)` so the badge updates without opening Messages tab; or
  - After refetching the list, compute total unread from the list and pass it up (e.g. via a callback or shared state) to the nav bar. Simpler: HomeScreen subscribes and refreshes unread on every `MessagesUpdateEvent`.
- **Option B**: Backend includes `unread_count` in the Firestore payload for `messages_updated` so the app can update the badge without refetching the full list. Requires backend change; then LiveUpdateService or a small handler updates a global “unread count” stream/notifier that the nav bar reads.

Implementing **Option A** is enough for a live badge: ConversationsScreen refetches list on `MessagesUpdateEvent`; HomeScreen subscribes and calls `_loadUnreadCount()` on `MessagesUpdateEvent`.

---

## 4. Image caching and message caching / syncing

### 4.1 Image caching (already in place)

- **CachedMediaImage** uses **MediaCacheManager** (flutter_cache_manager): 30-day stale period, 200 files, disk cache. Same as feed/clips.
- Chat screen uses **CachedMediaImage** for message images (e.g. thumbnails, shared photos). So images are **not** re-downloaded every time; they are cached on disk and reused.
- **Recommendation**: Use **CachedMediaImage** for all message images. For **audio** in chat, **\_VoiceMessagePlayer** uses **MediaCacheService().getCachedMediaPath(url)** before playing; if a cached path is returned, playback uses **DeviceFileSource(cached)**, otherwise **UrlSource(url)**. Video in chat currently shows a thumbnail only; when a full video player is added, use `getCachedMediaPath` for playback similarly.

### 4.2 Message caching and syncing (implemented)

- **MessageCacheService** (`lib/services/message_cache_service.dart`): Hive box `message_cache`, key `conv_{conversationId}`, value JSON list of serialized **Message** (via `Message.toJson()`). Merge by id, sort by `created_at`, cap at 500 messages per conversation. **Current (obsolete)**: ChatScreen keeps `_messages` in memory only. Every time the user opens a chat, `_loadMessages()` fetches from the API (full page). No local persistence. So every app open = full re-download of visible messages.
- **WhatsApp-like behaviour**: Messages are stored **locally** (e.g. Hive box or SQLite table keyed by `conversation_id` + `message_id`). On opening a conversation:
  1. **Show cached messages immediately** (if any) so the screen paints fast.
  2. **Fetch from API** (e.g. latest page, or “messages since last sync”). Merge new/updated messages into the cache and update UI.
  3. **Pagination**: Load older messages on scroll-up (e.g. “load before first visible id”); store those in the same cache.
  4. **Sync strategy**: On **MessagesUpdateEvent(conversationId)**, fetch only **new** messages (e.g. `GET /conversations/{id}/messages?since_id={last_id}` if the API supports it) and append to cache; or refetch the latest page and merge by id to avoid duplicates.

**Implementation outline**:

- **Message cache**: Hive box `message_cache` with key `conv_{conversationId}` storing a list of message ids and a separate box or map `messages` with key `conv_{conversationId}_msg_{messageId}` storing serialized Message (or a small DTO). Alternatively one box per conversation: `messages_conv_{id}`.
- **On open chat**: Read from cache for that conversation, set `_messages = cached`, then call API. When API returns, merge (by id), write back to cache, setState.
- **On new message (send or receive)**: Append to in-memory list and write to cache. On MessagesUpdateEvent, fetch latest and merge.
- **Eviction**: Keep last N messages per conversation (e.g. 500) or last 30 days; drop older from cache when adding new.

This avoids re-downloading the same messages every time and gives instant open from cache.

---

## 5. Performance optimizations (WhatsApp-like)

- **List virtualization**: ChatScreen already uses **ListView.builder** for the message list, so only visible (and cache-extent) items are built. Keep it; avoid putting the whole list in a single child.
- **Cache extent**: Set **cacheExtent** on the ListView (e.g. 500–800 px) so a few off-screen items are built and image loading starts before they are visible. Reduces jank when scrolling fast.
- **Image decode size**: Use **cacheWidth** / **cacheHeight** (or memCacheWidth/Height) for message images so decoding is done at display size, not full resolution. **CachedMediaImage** already supports this; use it for all message images with bounds (e.g. bubble width).
- **Stable keys**: Give each list item a **Key** (e.g. `ValueKey(message.id)`) so Flutter can update only changed bubbles when new messages are appended or one is updated (e.g. reaction).
- **Avoid full list rebuild**: When appending one message, use **setState** with a list that’s updated in place (e.g. `_messages.add(newMsg)`) or use a list that’s replaced by a new list that shares most items; with keys, only the new bubble builds.
- **Typing / presence**: Prefer **LiveUpdate** or a light WebSocket for typing indicators rather than heavy polling. Backend already supports typing endpoints; if Firestore is used for “typing” per conversation, the app can listen there and avoid polling.
- **Local-first + incremental sync**: As in §4.2, show from cache first, then sync. This is the biggest lever for “instant open” and “no re-download every time”.
- **Unread badge**: Update only when needed (on MessagesUpdateEvent or when returning to Messages tab), not on a fixed timer, to avoid unnecessary API calls.

---

## 6. Summary table

| Area | Status |
|------|--------|
| Backend notifier | **Done.** ConversationsScreen, ChatScreen, and HomeScreen subscribe to LiveUpdateService; refetch list / messages / unread on MessagesUpdateEvent. |
| FCM | **Done.** firebase_messaging; FcmService with onMessage, onMessageOpenedApp, getInitialMessage; token sent to POST /users/fcm-token; payload → open ChatScreen or IncomingCallScreen via global navigator key. |
| Live unread | **Done.** HomeScreen subscribes and calls _loadUnreadCount() on MessagesUpdateEvent; ConversationsScreen refetches list. |
| Image caching | **Done.** CachedMediaImage for message images; MediaCacheService.getCachedMediaPath used for audio playback in _VoiceMessagePlayer. |
| Message cache | **Done.** MessageCacheService (Hive); show cache first, then sync and merge; _cacheMessage on send; cap 500 per conversation. |
| Performance | **Done.** ListView.builder with cacheExtent (800), ValueKey(message.id), local-first messages. |

This doc is the single reference for how Messages works with the backend notifier, FCM, live unread, and caching/syncing.
