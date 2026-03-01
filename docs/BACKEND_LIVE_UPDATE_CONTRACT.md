# Backend live-update contract (reference)

**Status**: Backend complete & tested (2026-02-14).  
**Firestore project**: `tajiri-6d6ae`.  
**Collection**: `updates`. **Document ID**: `{userId}` (user_profiles.id as string).

The Laravel backend writes to `updates/{userId}` after relevant DB changes. The Flutter app listens via `LiveUpdateService` and refetches from the REST API so the UI updates instantly.

## Event types (backend → app)

| Event               | App action |
|---------------------|------------|
| `feed_updated`      | Refetch feed; on Friends tab also refetch stories. |
| `post_updated`      | Refetch post by `payload.post_id`. |
| `profile_updated`   | Refetch profile / friends / requests. |
| `followers_updated` | Refetch followers/following. |
| `messages_updated`  | Refetch conversations; if chat open for `payload.conversation_id`, refetch messages. |
| `stories_updated`   | Refetch stories list. |

## Payload

- `post_updated`: `{"post_id": <int>}`  
- `messages_updated`: `{"conversation_id": <int>}`  
- Others: no payload or `{}`.

## Flutter implementation

- **Listen**: `LiveUpdateService.instance.start(userId)` after login; `stop()` on logout.
- **Screens**: Subscribe to `LiveUpdateService.instance.stream` and call existing load/refetch methods on the matching event type.
- **Deduplication**: Service ignores snapshots with the same `ts` to avoid duplicate refetches.
- **Never write**: The app only reads; only the backend writes to `updates/{userId}`.

Full backend mapping (which API actions trigger which events and who is notified) is in the **Backend Implementation Guide** from the Laravel team (Firebase Live-Update Notifications — Backend Implementation Guide, 2026-02-14).
