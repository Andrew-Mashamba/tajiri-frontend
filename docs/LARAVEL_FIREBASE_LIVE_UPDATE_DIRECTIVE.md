# Laravel Backend: Firebase Live-Update Notifications (Directive)

The Flutter app listens to **Firestore** at `updates/{userId}`. When your Laravel backend **writes** to that document after a database change, the app **refetches data** and the **UI updates instantly**. This document defines **which API actions must trigger a Firestore write** and **for which user(s)**.

---

## 1. Firestore document shape (contract)

- **Collection**: `updates`
- **Document ID**: `{userId}` (integer as string, e.g. `"42"`)
- **Fields** (write/merge these on each notification):

| Field     | Type    | Required | Description |
|-----------|---------|----------|-------------|
| `ts`      | number  | Yes      | Server timestamp (e.g. `now()->timestamp` or milliseconds). |
| `event`   | string  | Yes      | One of: `feed_updated`, `post_updated`, `profile_updated`, `followers_updated`, `messages_updated`, `stories_updated`. |
| `payload` | object  | No       | Extra data. For `post_updated`: `{"post_id": 123}`. For `messages_updated`: `{"conversation_id": 456}`. |

**Important**: Overwrite or merge the document for each target user. The app only needs to know “something changed”; it will then refetch from your REST API. Do **not** store business data in Firestore.

---

## 2. Laravel implementation (high level)

1. **Install Firebase Admin SDK** for Laravel (e.g. `kreait/firebase-php-sdk`).
2. **Obtain a service account key** from Firebase Console → Project Settings → Service accounts → Generate new private key. Store the JSON path in `.env` (e.g. `FIREBASE_CREDENTIALS=/path/to/key.json`).
3. **Create a small helper** (e.g. `FirebaseLiveUpdateService` or trait) that:
   - Initializes Firestore with the service account.
   - Exposes a method: `notifyUser(int $userId, string $event, array $payload = [])` that writes/merges to `updates/{userId}` with `ts`, `event`, `payload`.
   - Optionally: `notifyUsers(array $userIds, string $event, array $payload = [])` to loop and notify multiple users.
4. **Call this helper** from your existing controllers/services **after** the DB transaction (or after the HTTP response is prepared) for each action listed below.

---

## 3. Actions that MUST trigger a notification

Below, “notify” means: call your Firestore helper to write to the document `updates/{userId}` with the given `event` (and optional `payload`) for **each** listed user.

---

### 3.1 Posts

| API action (Laravel) | When (after DB change) | Notify whom | Event | Payload |
|----------------------|-------------------------|-------------|--------|---------|
| **Create post** (POST /api/posts) | New post saved | All **followers** of the author (or friends, depending on your feed logic); and the **author** | `feed_updated` | `{}` |
| **Update post** (PUT /api/posts/{id}) | Post updated | **Author**; optionally users who have the post in recent feed (can keep it simple: author only) | `post_updated` | `{"post_id": <id>}` |
| **Delete post** (DELETE /api/posts/{id}) | Post deleted | **Author**; optionally all followers (so feed refreshes) | `feed_updated` and/or `post_updated` with that id so open screens refresh | `{"post_id": <id>}` for post_updated |
| **Like post** (POST /api/posts/{id}/like) | Like saved | **Post author** (so they see updated like count) | `post_updated` | `{"post_id": <id>}` |
| **Unlike post** (DELETE /api/posts/{id}/like) | Like removed | **Post author** | `post_updated` | `{"post_id": <id>}` |
| **Add comment** (POST /api/posts/{id}/comments) | Comment saved | **Post author** (so comment count and list refresh) | `post_updated` | `{"post_id": <id>}` |
| **Delete comment** (DELETE /api/comments/{id}) | Comment deleted | **Post author** (and optionally comment author) | `post_updated` | `{"post_id": <post_id>}` |
| **Update comment** (PATCH /api/comments/{id}) | Comment updated | **Post author** | `post_updated` | `{"post_id": <post_id>}` |
| **Like / unlike comment** | Comment like saved/removed | **Post author** (so comment like count can refresh) | `post_updated` | `{"post_id": <post_id>}` |
| **Pin / unpin comment** (POST/DELETE .../comments/pin) | Pin state changed | **Post author** | `post_updated` | `{"post_id": <id>}` |
| **Share post** (POST /api/posts/{id}/share) | New “shared” post created | **Author of the new share**; and **followers of that author** (same as create post) | `feed_updated` | `{}`; and for the shared post’s author: `post_updated` with **original** post id if you want original post’s share count to refresh |
| **Save post** (POST /api/posts/{id}/save) | Save record created | **Saver** (optional: so “saved” list refreshes) | `feed_updated` (or skip) | — |
| **Unsave post** (DELETE /api/posts/{id}/save) | Save record removed | **User who unsaved** (optional) | `feed_updated` (or skip) | — |

---

### 3.2 Friends / follow

| API action (Laravel) | When | Notify whom | Event | Payload |
|----------------------|------|-------------|--------|---------|
| **Send friend request** (POST /api/friends/request) | Request created | **Recipient** (`friend_id`) | `profile_updated` or `followers_updated` | `{}` |
| **Accept friend request** (POST /api/friends/accept/{requesterId}) | Friendship created | **Requester**; and **accepter** (so both see updated friends list and feed) | `profile_updated` and `feed_updated` | `{}` |
| **Decline friend request** (POST /api/friends/decline/{requesterId}) | Request declined | **Requester** (so pending list updates) | `profile_updated` | `{}` |
| **Cancel friend request** (POST /api/friends/cancel/{friendId}) | Request cancelled | **Recipient** (`friendId`) | `profile_updated` | `{}` |
| **Remove friend** (DELETE /api/friends/{friendId}) | Friendship removed | **Other user** (`friendId`) | `profile_updated` and `feed_updated` | `{}` |

If you have a separate **follow** (one-way) model (e.g. for “following” feed): on follow/unfollow, notify the **followed user** with `followers_updated` (and optionally `profile_updated`). Notify the **follower** with `feed_updated` so their following feed refreshes.

---

### 3.3 Stories

| API action (Laravel) | When | Notify whom | Event | Payload |
|----------------------|------|-------------|--------|---------|
| **Create story** (POST /api/stories) | Story saved | **Followers** of the story author (so Friends-tab stories row refreshes) | `feed_updated` or `stories_updated` | `{}` |
| **Delete story** (DELETE /api/stories/{id}) | Story deleted | **Followers** of the story author | `feed_updated` or `stories_updated` | `{}` |

(If the app treats stories as part of feed refresh, `feed_updated` is enough; the Flutter app already refetches stories when it receives `FeedUpdateEvent` on the Friends tab.)

---

### 3.4 Messages / conversations

| API action (Laravel) | When | Notify whom | Event | Payload |
|----------------------|------|-------------|--------|---------|
| **Create group conversation** (POST /api/conversations) | Conversation + participants saved | All **participants** (except creator if you prefer) | `messages_updated` | `{"conversation_id": <id>}` |
| **Send message** (POST /api/conversations/{id}/messages) | Message saved | All **other participants** in that conversation | `messages_updated` | `{"conversation_id": <id>}` |
| **Leave conversation** (DELETE /api/conversations/{id}) | Participant removed | **Other participants** (so their conversation list updates) | `messages_updated` | `{"conversation_id": <id>}` |

Mark-as-read does not need to trigger a notification for other users (only local state).

---

### 3.5 Profile / user

| API action (Laravel) | When | Notify whom | Event | Payload |
|----------------------|------|-------------|--------|---------|
| **Update profile** (PUT /api/users/{id} or similar) | Profile updated | **That user** (so their profile screen refreshes); optionally **followers** if name/photo changed (so profile_updated for viewers) | `profile_updated` | `{}` |

---

### 3.6 Optional: Clips (shorts)

If the app shows clips in a feed or detail screen and you want them to update live:

| API action | When | Notify whom | Event | Payload |
|------------|------|-------------|--------|---------|
| Create clip, like clip, comment on clip, share clip | After DB write | **Clip author**; or **followers** for new clip | Same pattern as posts: `feed_updated` for new clip, or a dedicated event if you add it in the app | — |

---

## 4. Who to notify for “feed” (global / following / friends)

- **feed_updated** should be sent to users whose **feed list** might have changed:
  - **New post**: notify the **post author** and every user who **follows** (or is friends with) the author, so their feed refetches and shows the new post.
  - **New story**: notify every **follower** of the story author.
  - **Share post**: same as new post for the user who shared (their followers + themselves).
  - **Accept friend / remove friend**: notify both users so their “friends” or “following” feed can refresh.

Implement “get followers/friends for user X” in Laravel (you likely already have this for building the feed) and loop over those IDs to call `notifyUser($userId, 'feed_updated', [])`.

---

## 5. Summary table (quick reference)

| Event               | Meaning for the app | Typical triggers |
|---------------------|---------------------|-------------------|
| `feed_updated`      | Refetch feed (and on Friends tab: stories) | New/delete post, new/delete story, share post, friend accept/remove |
| `post_updated`      | Refetch a specific post (likes, comments, etc.) | Like/unlike post, add/edit/delete comment, pin comment, update/delete post |
| `profile_updated`   | Refetch profile (and friends/followers list) | Profile edit, friend request/accept/decline/cancel/remove |
| `followers_updated` | Same as profile or follow list changed | Follow/unfollow, friend request/accept |
| `messages_updated`  | Refetch conversations or a conversation | New message, new group, leave conversation |
| `stories_updated`   | Refetch stories (if you use it) | New/delete story; or use `feed_updated` |

---

## 6. Implementation checklist (Laravel)

- [ ] Add Firebase PHP SDK and service account key; create `FirebaseLiveUpdateService` (or equivalent) that writes to `updates/{userId}` with `ts`, `event`, `payload`.
- [ ] After **create/update/delete post**, **like/unlike post**, **add/edit/delete comment**, **share post**: call the service for the relevant user(s) with `feed_updated` and/or `post_updated` as above.
- [ ] After **friend request/accept/decline/cancel/remove**: call for the relevant user(s) with `profile_updated` / `feed_updated`.
- [ ] After **create/delete story**: call for followers with `feed_updated` (or `stories_updated`).
- [ ] After **send message**, **create group**, **leave conversation**: call for the other participants with `messages_updated` and `conversation_id` in payload.
- [ ] After **profile update**: call for the user (and optionally followers) with `profile_updated`.
- [ ] Ensure Firestore **security rules** allow only your backend (service account) to write, and each user’s app can only read `updates/{userId}` for their own `userId` (see `docs/FIREBASE_LIVE_UPDATE_SETUP.md`).

Once these are in place, the Flutter app will receive Firestore updates and refetch the corresponding data from your existing APIs, so the UI updates instantly for all affected users.
