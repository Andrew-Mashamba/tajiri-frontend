# Backend API contract: post actions (like, save, comment, delete, share)

This document describes how the **Laravel backend** is expected to handle the actions used by the full-screen post viewer and feed (like, save, comment, share, delete). The Flutter app already implements loading states, error SnackBars with Retry, and tap feedback; the backend must provide the following endpoints and response shapes.

**Base URL:** `ApiConfig.baseUrl` (e.g. `https://zima-uat.site:8003/api`).  
All request/response bodies are **JSON**. Use **Bearer token** auth if the app sends `Authorization: Bearer <token>`; the app may also send `user_id` in the body where noted.

---

## 1. Like / Unlike

### Like

- **Method:** `POST`
- **URL:** `/posts/{postId}/like`
- **Headers:** `Content-Type: application/json`
- **Body:**
  ```json
  {
    "user_id": 123,
    "reaction_type": "like"
  }
  ```
- **Success:** `200 OK`
- **Response:**
  ```json
  {
    "success": true,
    "data": {
      "likes_count": 42
    }
  }
  ```
- **On failure:** Return non-200 or `success: false` so the app can show the error SnackBar and Retry.

### Unlike

- **Method:** `DELETE`
- **URL:** `/posts/{postId}/like`
- **Headers:** `Content-Type: application/json`
- **Body:**
  ```json
  {
    "user_id": 123
  }
  ```
- **Success:** `200 OK`
- **Response:** Same as like:
  ```json
  {
    "success": true,
    "data": {
      "likes_count": 41
    }
  }
  ```

**Backend expectations:**

- Idempotent: liking again is a no-op (return current `likes_count`); unliking when not liked is a no-op.
- Return updated `likes_count` so the UI can stay in sync after retries or slow networks.
- On duplicate like/remove: still return `success: true` and current `likes_count`.

---

## 2. Save / Unsave (bookmark)

### Save

- **Method:** `POST`
- **URL:** `/posts/{postId}/save`
- **Headers:** `Content-Type: application/json`
- **Body:**
  ```json
  {
    "user_id": 123
  }
  ```
- **Success:** `200 OK`
- **Response:**
  ```json
  {
    "success": true,
    "data": {
      "saves_count": 10
    }
  }
  ```
- **On failure:** Return non-200 or `success: false` and optionally a user-facing **message** (e.g. validation or permission error). The app shows this in the SnackBar and uses it for Retry.

### Unsave

- **Method:** `DELETE`
- **URL:** `/posts/{postId}/save`
- **Headers:** `Content-Type: application/json`
- **Body:**
  ```json
  {
    "user_id": 123
  }
  ```
- **Success:** `200 OK`
- **Response:**
  ```json
  {
    "success": true,
    "data": {
      "saves_count": 9
    }
  }
  ```

**Backend expectations:**

- Return `saves_count` so the UI can show the correct count after save/unsave/retry.
- On error, return a short `message` (e.g. in `data` or top-level); the app displays it and offers Retry.

---

## 3. Comments

### List comments

- **Method:** `GET`
- **URL:** `/posts/{postId}/comments?page=1&per_page=20`
- **Success:** `200 OK`
- **Response:**
  ```json
  {
    "success": true,
    "data": [
      {
        "id": 1,
        "post_id": 5,
        "user_id": 10,
        "parent_id": null,
        "content": "Nice post!",
        "likes_count": 0,
        "created_at": "2025-02-14T12:00:00.000000Z",
        "updated_at": "2025-02-14T12:00:00.000000Z",
        "user": {
          "id": 10,
          "first_name": "Jane",
          "last_name": "Doe",
          "profile_photo_path": "users/avatar.jpg"
        },
        "replies": []
      }
    ],
    "meta": {
      "current_page": 1,
      "per_page": 20,
      "total": 50
    }
  }
  ```

### Add comment

- **Method:** `POST`
- **URL:** `/posts/{postId}/comments`
- **Headers:** `Content-Type: application/json`
- **Body (new top-level comment):**
  ```json
  {
    "user_id": 123,
    "content": "Great post!"
  }
  ```
- **Body (reply):**
  ```json
  {
    "user_id": 123,
    "content": "I agree.",
    "parent_id": 5
  }
  ```
- **Body (optional @mentions):** Include `mention_ids` (array of user IDs) when the user tags people in the comment:
  ```json
  {
    "user_id": 123,
    "content": "Hey @jane what do you think?",
    "mention_ids": [10, 42]
  }
  ```
- **Success:** `201 Created`
- **Response:**
  ```json
  {
    "success": true,
    "data": {
      "id": 99,
      "post_id": 5,
      "user_id": 123,
      "parent_id": null,
      "content": "Great post!",
      "likes_count": 0,
      "created_at": "2025-02-14T12:00:00.000000Z",
      "updated_at": "2025-02-14T12:00:00.000000Z",
      "user": { "id": 123, "first_name": "...", "last_name": "...", "profile_photo_path": null },
      "replies": []
    }
  }
  ```
- **On failure:** Non-201 or `success: false` and optional `message` for the UI.

### Delete comment

- **Method:** `DELETE`
- **URL:** `/comments/{commentId}`
- **Success:** `200 OK` (body can be minimal; app only checks status).

### Like comment

- **Method:** `POST`
- **URL:** `/comments/{commentId}/like`
- **Headers:** `Content-Type: application/json`
- **Body:** `{ "user_id": 123 }`
- **Success:** `200 OK`
- **Response:** `{ "success": true, "data": { "likes_count": 1 } }` (and optionally `is_liked: true`). App uses `likes_count` to update the comment tile.

### Unlike comment

- **Method:** `DELETE`
- **URL:** `/comments/{commentId}/like`
- **Headers:** `Content-Type: application/json`
- **Body:** `{ "user_id": 123 }` (optional; some servers omit body for DELETE)
- **Success:** `200 OK`
- **Response:** `{ "success": true, "data": { "likes_count": 0 } }`

### Update (edit) comment

- **Method:** `PATCH`
- **URL:** `/comments/{commentId}`
- **Headers:** `Content-Type: application/json`
- **Body:** `{ "content": "Updated text", "mention_ids": [10, 42] }` (mention_ids optional)
- **Success:** `200 OK`
- **Response:** `{ "success": true, "data": { ...full comment object... } }` with `edited_at` set when applicable.

### Pin comment (post author only)

- **Method:** `POST`
- **URL:** `/posts/{postId}/comments/{commentId}/pin`
- **Success:** `200 OK`
- **Response:** `{ "success": true, "data": { ...comment with is_pinned: true } }`. Only one comment per post may be pinned; pinning another unpins the previous.

### Unpin comment

- **Method:** `DELETE`
- **URL:** `/posts/{postId}/comments/pin`
- **Success:** `200 OK`

### Report comment

- **Method:** `POST`
- **URL:** `/comments/{commentId}/report`
- **Headers:** `Content-Type: application/json`
- **Body:** `{ "reason": "Spam", "category": "optional" }`
- **Success:** `200 OK` (or 202). App shows “Imesafirishwa” on success.

### Get replies (paginated)

- **Method:** `GET`
- **URL:** `/posts/{postId}/comments?parent_id={parentCommentId}&page=1&per_page=20`
- **Success:** `200 OK`
- **Response:** Same shape as list comments; returns only replies for that parent. Used for “Load more replies” in the UI.

**Comment object (for both list and add):**

- `id`, `post_id`, `user_id`, `parent_id` (null for top-level), `content`, `likes_count`
- `created_at`, `updated_at` (ISO 8601)
- `user`: object with `id`, `first_name`, `last_name`, `username` (optional), `profile_photo_path` (nullable)
- `replies`: array of same comment shape (optional; can be empty)
- **Optional (recommended):** `is_pinned` (boolean), `is_liked` (boolean for current user), `edited_at` (ISO 8601 or null), `reply_count` (total number of replies), `mentioned_user_ids` (array of user IDs)

---

## 4. Delete post

- **Method:** `DELETE`
- **URL:** `/posts/{postId}`
- **Success:** `200 OK`
- **On failure:** Non-200. The app shows “Could not delete post. Try again.” (no Retry for delete).

**Backend expectations:**

- Only the post author (or admin) can delete; return 403/404 with a clear status so the app can show a generic error.

---

## 5. Share post

Used when the user shares a post (e.g. to create a new post with shared content).

- **Method:** `POST`
- **URL:** `/posts/{postId}/share`
- **Headers:** `Content-Type: application/json`
- **Body:**
  ```json
  {
    "user_id": 123,
    "content": "Optional caption",
    "privacy": "public"
  }
  ```
- **Success:** `201 Created`
- **Response:**
  ```json
  {
    "success": true,
    "message": "Optional message",
    "data": { ... post object ... }
  }
  ```
- **On failure:** Non-201 or `success: false` and optional `message`.

---

## 6. Get saved posts (for “Saved” screen)

- **Method:** `GET`
- **URL:** `/posts/saved?user_id=123&page=1&per_page=20`
- **Success:** `200 OK`
- **Response:** Same paginated post list shape as feed (e.g. `success`, `data` array of posts, `meta` for pagination). Each post should have `is_saved: true` and correct `saves_count`.

---

## Error handling (for like/save/comment)

- **Connection / timeout:** Handled on the client; backend just needs to respond in a reasonable time or the app will show “Request took too long” and Retry.
- **Validation / business errors:** Return appropriate HTTP status (e.g. 422, 403) and a JSON body with a short `message` (and optionally `errors`). The app uses the message in the SnackBar; for save it also shows Retry.
- **Server errors (5xx):** App shows “Something went wrong. Try again.” and Retry for like/save.

---

## Summary table

| Action       | Method | Endpoint                      | Success | Key response fields              |
|-------------|--------|-------------------------------|---------|----------------------------------|
| Like        | POST   | `/posts/{id}/like`            | 200     | `data.likes_count`               |
| Unlike      | DELETE | `/posts/{id}/like`            | 200     | `data.likes_count`               |
| Save        | POST   | `/posts/{id}/save`            | 200     | `data.saves_count`               |
| Unsave      | DELETE | `/posts/{id}/save`            | 200     | `data.saves_count`               |
| List comments | GET  | `/posts/{id}/comments`        | 200     | `data[]`, `meta`                 |
| Add comment | POST   | `/posts/{id}/comments`        | 201     | `data` (full comment)            |
| Delete comment | DELETE | `/comments/{id}`           | 200     | —                                |
| Like comment | POST   | `/comments/{id}/like`         | 200     | `data.likes_count`               |
| Unlike comment | DELETE | `/comments/{id}/like`       | 200     | `data.likes_count`               |
| Update comment | PATCH  | `/comments/{id}`            | 200     | `data` (full comment)            |
| Pin comment | POST   | `/posts/{id}/comments/{id}/pin` | 200  | `data` (comment)                 |
| Unpin comment | DELETE | `/posts/{id}/comments/pin`  | 200     | —                                |
| Report comment | POST  | `/comments/{id}/report`      | 200     | —                                |
| Get replies | GET    | `/posts/{id}/comments?parent_id=` | 200 | `data[]`, `meta`               |
| Delete post | DELETE | `/posts/{id}`                 | 200     | —                                |
| Share post  | POST   | `/posts/{id}/share`           | 201     | `data` (post), `message`         |
| Saved posts | GET    | `/posts/saved?user_id=...`    | 200     | `data[]` (posts), `meta`         |

With this contract, the Laravel backend will support the existing Flutter behavior: loading indicators on like/save, floating SnackBars with Retry on failure, and correct counts and state after retries.
