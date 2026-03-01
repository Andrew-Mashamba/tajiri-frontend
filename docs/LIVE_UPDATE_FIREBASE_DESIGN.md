# Live Update of Data & UI via Firebase (Design)

## 1. Current system summary

- **Backend**: REST API (e.g. `https://zima-uat.site:8003/api`) — source of truth for posts, feed, users, comments, etc.
- **Data flow**: Pull-only. Screens call `FeedService`, `PostService`, etc.; user triggers refresh (pull-to-refresh, tab change, or after an action).
- **Real-time today**: WebSockets (`WebSocketService`) are used **only for livestreams** (viewer count, comments, gifts). No real-time for feed, posts, or profile.
- **State**: Local `setState` in screens; no global cache layer. Theme/language use `ChangeNotifier`-style notifiers.
- **Firebase**: Not used yet.

**Goal**: When the backend database changes (new post, new like, comment, follow, etc.), the app should update data and UI in near real time, using Firebase as the delivery mechanism while keeping the existing backend as source of truth.

---

## 2. Options

| Approach | How it works | Pros | Cons |
|----------|--------------|------|------|
| **A. FCM only** | Backend sends FCM data message on DB change → app (foreground/background) receives and refetches from API | Simple backend: one “notify” call. Works when app killed. | Not true real-time; FCM can be delayed. Foreground still needs a trigger. |
| **B. Firestore as event bus** | Backend writes a tiny doc (e.g. `updates/{userId}` or `updates/{userId}/feed`) on DB change; app listens with `snapshots()`. On event → refetch from REST API. | Real-time listener, auto-reconnect, works with existing REST API. | Backend must integrate Firestore Admin SDK and write on each change. |
| **C. Realtime Database as event bus** | Same as B but Firebase RTDB path e.g. `updates/{userId}/lastEvent`. | Simple, low cost, real-time. | Same backend integration; RTDB is key-value, less structure. |
| **D. Backend WebSocket (no Firebase)** | Extend current WebSocket to channels for feed/post/user events; backend pushes on DB change. | Single transport, no Firebase. | You asked for Firebase; scaling WS (sticky sessions, etc.) is more work. |
| **E. Hybrid** | Foreground: Firestore/RTDB listener. Background/killed: FCM so user gets notified and can open app. | Best UX: instant in-app + push when away. | Two paths to maintain. |

---

## 3. Recommended approach: **Firestore as change-notification channel (with optional FCM)**

Use **Cloud Firestore** as a lightweight “something changed” channel. The app does **not** store business data in Firestore; the backend remains the single source of truth.

- **Backend**: On relevant DB changes (post created, like, comment, follow, etc.), write a small **event document** (or update a single “cursor” doc) in Firestore (e.g. under `updates/{userId}` or per-resource paths).
- **App**: Subscribes to Firestore `snapshots()` for that user (and optionally per screen). On each snapshot/change, the app **refetches only what’s needed** from your existing REST API and updates UI (e.g. refresh feed, refresh one post, invalidate profile).
- **Optional**: Add **FCM** for when the app is in background or killed — e.g. “New like on your post” — so the user can open the app; once open, Firestore listener handles live updates.

Why Firestore over RTDB here: clearer structure (collections/documents), good Flutter SDK (`snapshots()`), and you can later add per-resource paths (e.g. `updates/{userId}/feed`, `updates/{userId}/notifications`) if you want finer-grained invalidation.

---

## 4. Backend contract (what to write to Firestore)

Keep the payload minimal: **event type + optional IDs**. Full data always comes from your API.

Suggested structure:

**Collection**: `updates`  
**Document per user**: `updates/{userId}` (one doc per user, overwritten or merged on each event)

**Fields** (example):

```json
{
  "ts": 1739123456789,
  "event": "feed_updated",
  "payload": { "post_id": 123, "type": "new_post" }
}
```

Or use **subcollections** for a small event log (optional, if you want multiple events per user):

- `updates/{userId}/events/{eventId}` with `ts`, `event`, `payload`.

**When to write** (backend, after DB commit):

- New post (by user or by someone they follow) → `event: "feed_updated"`.
- Like / comment / share on a post → `event: "post_updated"`, `payload: { "post_id": 123 }`.
- New follower / follow accepted → `event: "profile_updated"` or `"followers_updated"`.
- New message (if you want live chat) → `event: "messages_updated"`, `payload: { "conversation_id": 456 }`.

You can start with a **single document** `updates/{userId}` and a single field `lastEvent` (or `ts` + `event` + `payload`) that you overwrite on every change; the app only needs to know “something changed” and for which scope (feed, post, profile, etc.).

**Security**: Use Firestore rules so each user can only read `updates/{userId}` where `userId == request.auth.uid` (if you use Firebase Auth) or use a server-generated token. If the app does not use Firebase Auth, the backend can write with Admin SDK; the app can still listen if you use secure token or restrict by app + custom auth.

---

## 5. App-side design

### 5.1 Packages

- `firebase_core` — init Firebase.
- `cloud_firestore` — listen to `updates/{userId}` (and optional subcollections).
- Optional: `firebase_messaging` — for background/killed push; later.

### 5.2 Single “live update” service

Introduce a **`LiveUpdateService`** (singleton or provided at app root) that:

1. **Initializes** after user login (needs `userId`).
2. **Subscribes** to Firestore `updates/{userId}` (or `updates/{userId}/events`) with `snapshots()`.
3. **Maps** snapshot changes to app events (e.g. `FeedUpdate`, `PostUpdate`, `ProfileUpdate`).
4. **Exposes** a single `Stream<LiveUpdateEvent>` (or a broadcast stream) that screens/widgets can listen to.
5. **Stops** subscription on logout.

No business data is read from Firestore — only “event type + payload”. The service does **not** call your REST API; it only emits events. Other layers (see below) react to events and call existing services (`FeedService`, `PostService`, etc.).

### 5.3 Event types (app-side)

Define a small sealed type or enum, for example:

- `FeedUpdate` — refresh feed (and optionally stories).
- `PostUpdate(postId)` — refresh that post (e.g. like count, comments).
- `ProfileUpdate(userId?)` — refresh profile (or current user).
- `MessagesUpdate(conversationId?)` — refresh conversation list or a single chat.

Payload can be parsed from Firestore `event` + `payload` and converted into these types.

### 5.4 Who refetches and updates UI

- **Option A (recommended for minimal change)**: Screens that are already mounted listen to `LiveUpdateService` stream. On `FeedUpdate` they call `_loadFeed()` (or equivalent); on `PostUpdate(postId)` they call your existing “fetch post” and `setState`. No shared cache yet.
- **Option B (cleaner long-term)**: Introduce a small “cache/invalidation” layer (e.g. a `FeedCache` that holds the current list and exposes `invalidate()` + `refresh()`). `LiveUpdateService` only emits events; a single place (e.g. a `LiveUpdateHandler` in the widget tree or in main) listens and calls `FeedService` / `PostService` and updates the cache; screens listen to the cache (or get it via InheritedWidget/Provider). That way refetch logic lives in one place and UI stays dumb.

Start with **Option A**; refactor to B when you add a proper cache.

### 5.5 Where to plug in

- **Feed screen**: Listen for `FeedUpdate` → call `_loadFeed()` (and optionally `_loadStories()`).
- **Post detail / full-screen viewer**: Listen for `PostUpdate(postId)` for the current post → refetch that post and `setState`.
- **Profile screen**: Listen for `ProfileUpdate` (or `ProfileUpdate(profileUserId)`) → refetch profile or posts.
- **Conversations / chat**: Listen for `MessagesUpdate` → refresh list or conversation.

You can subscribe once in the service and broadcast; each screen subscribes to the stream and filters by event type (or by `postId` / `userId`) so only the relevant screen reacts.

### 5.6 Auth and Firestore path

- You need a **stable userId** for the path `updates/{userId}`. That should come from your existing auth (e.g. after login, you have `currentUserId`).
- Firestore **security rules** must allow read only for that user. If you don’t use Firebase Auth, you have two options:  
  - Use Firebase Anonymous Auth or a custom token generated by your backend (backend calls Admin Auth to create custom token for `userId`), then rules can use `request.auth.uid == userId`.  
  - Or keep the `updates` collection restricted (e.g. only backend writes with Admin SDK; allow read if `request.auth.token.user_id == userId` with custom claims).  
Detailed rule design can be a short follow-up once you choose auth strategy.

---

## 6. Optional: FCM for background/killed

- When app is in **background or killed**, Firestore listeners may not run. Use **FCM** so the backend sends a data message (e.g. “type: feed_updated”) when something changes.
- On FCM receive, the app can:  
  - If in background: set a flag or store “pending refresh” and, when the user opens the app, run the same refetch logic (e.g. `FeedUpdate` → `_loadFeed()`).  
  - Optionally show a local notification (“New post from …”) using `firebase_messaging` + local notifications.
- Backend: on same DB events, call both “write to Firestore” and “send FCM to user’s device(s)” (FCM topic per user or device tokens stored in your DB).

---

## 7. Implementation steps (high level)

1. **Firebase project**: Create project, add Android/iOS apps, get configs.
2. **Flutter**: Run `flutterfire configure`, add `firebase_core` and `cloud_firestore`, init in `main.dart` before `runApp`.
3. **Backend**: Install Firebase Admin SDK; on DB change (post, like, comment, etc.) write to `updates/{userId}` (and optionally send FCM). Define a small “event schema” (e.g. `event`, `ts`, `payload`).
4. **App**: Implement `LiveUpdateService` (subscribe to `updates/{userId}.snapshots()`, parse into `LiveUpdateEvent`, expose `Stream<LiveUpdateEvent>`).
5. **App**: In feed screen (and optionally post detail, profile), listen to the stream and call existing load/refetch methods on the right events.
6. **Security**: Add Firestore rules so only the owning user can read `updates/{userId}` (and optionally FCM for backend-only write).
7. **Optional**: Add FCM + “on message” handler to trigger the same refresh when app is in background.

---

## 8. Summary

- **Best modern approach**: Use **Firebase Firestore** as a **lightweight change-notification channel**: backend writes minimal event docs on DB change, app listens with `snapshots()` and refetches from your existing REST API. Optionally add **FCM** for background/killed so the user is notified and the app can refresh on open.
- **Backend stays source of truth**; no duplication of business data in Firebase.
- **App**: One `LiveUpdateService`, one stream of events, and existing screens react by calling current services and `setState` (or a future cache layer). This keeps the change set small and compatible with your current architecture.

If you want, next step can be a concrete **backend event schema** (exact field names and when to write) and a **minimal `LiveUpdateService` + Firestore path** code sketch in Dart for the app.
