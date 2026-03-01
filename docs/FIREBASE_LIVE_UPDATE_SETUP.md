# Firebase live update – setup (FlutterFire CLI)

So that **changes instantly reflect on the user UI**, the app listens to Firestore and refetches from your REST API when the backend writes an update. Follow these steps once.

## 1. Prerequisites

- **Firebase CLI** installed and logged in:
  ```bash
  npm install -g firebase-tools
  firebase login
  ```
- **Flutter SDK** installed.
- A **Flutter project** (this repo).

## 2. FlutterFire CLI

Install and run the configurator from your project root:

```bash
dart pub global activate flutterfire_cli
cd /path/to/TAJIRI-FRONTEND
flutterfire configure
```

- Select or create a **Firebase project**.
- Choose platforms (e.g. Android, iOS).
- The CLI will **overwrite** `lib/firebase_options.dart` with your real project keys and IDs.

After this, `DefaultFirebaseOptions.currentPlatform.projectId` will no longer be `tajiri-placeholder`, so `main.dart` will initialize Firebase and live updates will work.

## 3. Firestore structure and rules

Create a collection **`updates`** with one document per user: **`updates/{userId}`**.

**Document fields (backend writes these):**

| Field     | Type   | Description |
|----------|--------|-------------|
| `ts`     | number | Timestamp (e.g. milliseconds since epoch). |
| `event`  | string | One of: `feed_updated`, `post_updated`, `profile_updated`, `followers_updated`, `messages_updated`. |
| `payload`| map    | Optional. For `post_updated`: `{"post_id": 123}`. For `messages_updated`: `{"conversation_id": 456}`. |

**Security rules** (Firestore Console → Rules): each user may only read their own document:

```
rules_version = '2';
service cloud.firestore {
  match /databases/{database}/documents {
    match /updates/{userId} {
      allow read, write: if request.auth != null && request.auth.uid == userId;
      // If you don't use Firebase Auth, use your own auth (e.g. only backend writes with Admin SDK, and allow read for the app with careful rules or app check).
    }
  }
}
```

If your app does **not** use Firebase Auth, the backend can write with the **Firebase Admin SDK**; then you can allow read for the app by restricting to your app (e.g. App Check) or by using a custom token that encodes `userId` and matching it in rules.

## 4. Backend: when to write to Firestore

On any relevant **database change**, update the user’s doc so the app can refetch and refresh the UI:

- **New post** (or post by someone the user follows) → write `event: "feed_updated"` to **each follower’s** `updates/{userId}` (or a single “global” feed doc if you prefer).
- **Like / comment / share** on a post → write `event: "post_updated"`, `payload: { "post_id": <id> }` to the **post author** and/or **relevant viewers** (e.g. users who have the post open).
- **Profile / followers change** → write `event: "profile_updated"` or `"followers_updated"` to the affected user’s `updates/{userId}`.
- **New message** → write `event: "messages_updated"`, `payload: { "conversation_id": <id> }` to the participants’ `updates/{userId}`.

The app **only** uses these events to trigger refetch from your existing REST API; it does not read business data from Firestore.

## 5. App behavior after setup

- **Home** (and thus **Feed**) starts `LiveUpdateService` with `currentUserId` and subscribes to `updates/{userId}`.
- **Feed screen** listens for `FeedUpdateEvent` → calls `_loadFeed()` (and stories on Friends tab) so the list **updates instantly**.
- **Post detail screen** listens for `PostUpdateEvent(postId)` → calls `_loadPost()` so that post **updates instantly**.

Once Firebase is configured and the backend writes to `updates/{userId}` on changes, the UI will reflect updates in real time.
