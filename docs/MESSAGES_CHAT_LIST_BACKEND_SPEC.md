# Messages Chat List — Exact Backend Implementation Spec

This document lists **exactly** what the backend must implement so the Flutter chat list (WhatsApp-style) works end-to-end. The app already calls these APIs and expects these response shapes.

**Base URL:** Same as rest of API (e.g. `https://your-domain.com/api`). All paths below are relative to that base.

---

## 1. Conversation list response: include these fields

When the app calls **GET** `/conversations?user_id={id}&page=1&per_page=20` (and with `type=group` for Groups tab), each conversation object in the response **must** include the following so the list can show mute icon, unread, and last message state.

### 1.1 Required fields on each conversation object

| Field (snake_case) | Type | Required | Description |
|--------------------|------|----------|-------------|
| `id` | int | Yes | Conversation ID |
| `type` | string | Yes | `"private"` or `"group"` |
| `group_id` | int \| null | No | When type is group, FK to groups table |
| `name` | string \| null | No | Group name (for groups) |
| `avatar_path` | string \| null | No | Relative path for group/chat avatar |
| `created_by` | int | Yes | User ID of creator |
| `last_message_id` | int \| null | No | ID of latest message |
| `last_message_at` | string \| null | No | ISO 8601 datetime of last message |
| `created_at` | string | Yes | ISO 8601 |
| `updated_at` | string | Yes | ISO 8601 |
| **`unread_count`** | **int** | **Yes** | Number of unread messages **for the requesting user** in this conversation. Used for badge and bold name. |
| **`is_muted`** | **boolean** | **Yes** | Whether **this user** has muted this conversation. Used to show mute icon next to time. Default `false` if not stored. |
| `is_admin` | boolean | No | Whether current user is admin in this conversation (default false) |
| `display_name` | string \| null | No | Preferred display name for the row (e.g. contact name or group name) |
| `display_photo` | string \| null | No | Preferred avatar path for the row |
| `participants` | array | No | List of participants (see participant shape below) |
| **`last_message`** | **object \| null** | **No but recommended** | Nested last message so the list can show preview and read state without extra request |

### 1.2 Last message object (for `last_message` in conversation)

When you include `last_message` in the conversation, it must have at least:

| Field | Type | Required | Description |
|-------|------|----------|-------------|
| `id` | int | Yes | Message ID |
| `conversation_id` | int | Yes | Conversation ID |
| `sender_id` | int | Yes | User ID who sent it |
| `content` | string \| null | No | Text body (null for media-only) |
| `message_type` | string | Yes | e.g. `"text"`, `"image"`, `"video"`, `"audio"`, `"document"`, `"location"`, `"contact"` |
| `media_path` | string \| null | No | Relative path if media |
| `media_type` | string \| null | No | Optional MIME hint |
| `reply_to_id` | int \| null | No | ID of message being replied to |
| **`is_read`** | **boolean** | **Yes** | Whether the message has been read **by the recipient(s)**. App uses this to show ✓ (sent) vs ✓✓ (blue, read). For 1:1: read by the other user. For groups: you can define “read” as “read by at least one other” or “read by all”; app just needs a boolean. |
| **`read_at`** | **string \| null** | No | ISO 8601 when the message was read (optional) |
| `created_at` | string | Yes | ISO 8601 |
| `updated_at` | string | Yes | ISO 8601 |
| `sender` | object \| null | No | User object `{ id, first_name, last_name, username, profile_photo_path }` for “Name: message” in group previews |

**Important:** If `last_message` is missing or `is_read` is missing, the app will not show read ticks (✓✓) correctly. The app expects `is_read` and `read_at` on every message object it parses.

### 1.3 Participant object (for `participants` array)

Each element can be either:

- **With pivot (Laravel-style):** `{ "id", "first_name", "last_name", "username", "profile_photo_path", "pivot": { "conversation_id", "user_id", "id", "is_admin", "last_read_at", "unread_count", "is_muted" } }`
- **Flat:** `{ "id", "conversation_id", "user_id", "user": { ... }, "is_admin", "last_read_at", "unread_count", "is_muted" } `

The app uses participants for display name and avatar when there is no `display_name` / `display_photo`.

---

## 2. Mark conversation as read

**Endpoint:** **PUT** `/conversations/{id}/read`

**Request:**

- Headers: `Content-Type: application/json`
- Body: `{ "user_id": <int> }` (the user who is marking as read)

**Response:**

- Status: **200**
- Body: `{ "success": true }` (or `{ "success": true, "message": "..." }`)

**Backend behaviour:**

- Update “last read” position for this user in this conversation (e.g. set `last_read_at` or “read up to message_id” for that participant).
- Optionally mark all messages up to that point as read for this user (so that when you return `last_message.is_read` in future, it reflects that).
- Return 200 and `success: true`. The app treats any other status or `success: false` as failure.

---

## 3. Leave / delete conversation

**Endpoint:** **DELETE** `/conversations/{id}`

**Request:**

- Headers: `Content-Type: application/json`
- Body: `{ "user_id": <int> }` (the user who is leaving)

**Response:**

- Status: **200**
- Body: `{ "success": true }`

**Backend behaviour:**

- For **group** conversations: remove this user from `conversation_participants` (or equivalent). Do not delete the conversation.
- For **private** conversations: you can either soft-delete the conversation for this user, remove the participant row, or archive; the app will remove the conversation from the list when the response is successful.
- Return 200 and `success: true`. The app assumes the conversation is left on success.

---

## 4. Typing indicator

### 4.1 Start typing

**Endpoint:** **POST** `/conversations/{id}/typing/start`

**Request:**

- Body: `{ "user_id": <int> }`

**Response:** **200** `{ "success": true }`

**Backend:** Store that this user is typing in this conversation (e.g. in Redis or DB with a short TTL, e.g. 10 seconds). Refresh TTL on each start call if needed.

### 4.2 Stop typing

**Endpoint:** **POST** `/conversations/{id}/typing/stop`

**Request:**

- Body: `{ "user_id": <int> }`

**Response:** **200** `{ "success": true }`

**Backend:** Remove this user from the “typing” set for this conversation.

### 4.3 Get typing status

**Endpoint:** **GET** `/conversations/{id}/typing?user_id={id}`

**Response:** **200** with body:

```json
{
  "success": true,
  "data": {
    "typing_users": [
      { "id": 1, "first_name": "John", "last_name": "Doe" }
    ]
  }
}
```

- `typing_users`: array of users **currently typing** in this conversation (excluding the requesting user if you prefer). Each object must have **`id`**, **`first_name`**, **`last_name`** (snake_case). The app uses these for “Typing...” in the list and in the chat header.

---

## 5. Voice recording indicator (for “Recording audio...” in list)

### 5.1 Start recording

**Endpoint:** **POST** `/conversations/{id}/recording/start`

**Request:**

- Body: `{ "user_id": <int> }`

**Response:** **200** `{ "success": true }`

**Backend:** Store that this user is “recording” in this conversation (e.g. same pattern as typing, with a short TTL, e.g. 30 seconds).

### 5.2 Stop recording

**Endpoint:** **POST** `/conversations/{id}/recording/stop`

**Request:**

- Body: `{ "user_id": <int> }`

**Response:** **200** `{ "success": true }`

**Backend:** Remove this user from the “recording” set for this conversation.

### 5.3 Expose recording in typing response

**Same endpoint as 4.3:** **GET** `/conversations/{id}/typing?user_id={id}`

**Response** must also include `recording_users` in `data`:

```json
{
  "success": true,
  "data": {
    "typing_users": [ { "id": 1, "first_name": "John", "last_name": "Doe" } ],
    "recording_users": [ { "id": 2, "first_name": "Jane", "last_name": "Smith" } ]
  }
}
```

- `recording_users`: array of users currently in “recording” state in this conversation. Same shape as `typing_users`: **`id`**, **`first_name`**, **`last_name`** (snake_case). If no one is recording, return `recording_users: []`.

---

## 6. Mute per conversation (for mute icon in list)

The app expects **`is_muted`** on the conversation object (see section 1.1). This is **per user per conversation**.

**Options:**

- **A. Store in `conversation_participants`:** Add column `is_muted` (boolean). When you return a conversation for a given user, set `is_muted` from that user’s participant row.
- **B. Separate table:** e.g. `user_conversation_settings (user_id, conversation_id, is_muted)`. When building the conversation list for a user, join or lookup and set `is_muted` on each conversation.

You also need an API so the user can **toggle** mute (the app may add a “Mute” action in the future). Suggested:

**Endpoint:** **PUT** `/conversations/{id}/mute`  
**Body:** `{ "user_id": <int>, "muted": true | false }`  
**Response:** **200** `{ "success": true }`

(If the app does not call this yet, you can still add it so the backend is ready.)

---

## 7. Summary checklist

| # | What | Endpoint / place | Purpose in app |
|---|------|------------------|----------------|
| 1 | Conversation list includes `unread_count`, `is_muted`, `last_message` with `is_read` | GET `/conversations` response | Unread badge, bold name, mute icon, last preview, ✓/✓✓ |
| 2 | Mark as read | PUT `/conversations/{id}/read` | Swipe right “Mark as read” |
| 3 | Leave conversation | DELETE `/conversations/{id}` | Swipe left “Leave” / “Delete” |
| 4 | Typing start/stop | POST `.../typing/start`, `.../typing/stop` | “Typing...” in list and chat |
| 5 | Typing status + recording | GET `.../typing?user_id=` with `typing_users` and `recording_users` | “Typing...” and “Recording audio...” in list |
| 6 | Recording start/stop | POST `.../recording/start`, `.../recording/stop` | App notifies backend when user starts/stops voice recording |
| 7 | Mute flag and optional mute API | `is_muted` on conversation; optional PUT `.../mute` | Mute icon in list; future mute action |

---

## 8. Example: minimal conversation object for list

```json
{
  "id": 1,
  "type": "private",
  "group_id": null,
  "name": null,
  "avatar_path": null,
  "created_by": 1,
  "last_message_id": 42,
  "last_message_at": "2025-02-14T12:00:00.000000Z",
  "created_at": "2025-01-01T00:00:00.000000Z",
  "updated_at": "2025-02-14T12:00:00.000000Z",
  "unread_count": 2,
  "is_muted": false,
  "is_admin": false,
  "display_name": "John Doe",
  "display_photo": "users/2/avatar.jpg",
  "participants": [],
  "last_message": {
    "id": 42,
    "conversation_id": 1,
    "sender_id": 2,
    "content": "See you tomorrow",
    "message_type": "text",
    "media_path": null,
    "media_type": null,
    "reply_to_id": null,
    "is_read": true,
    "read_at": "2025-02-14T12:00:05.000000Z",
    "created_at": "2025-02-14T12:00:00.000000Z",
    "updated_at": "2025-02-14T12:00:00.000000Z",
    "sender": {
      "id": 2,
      "first_name": "John",
      "last_name": "Doe",
      "username": "johndoe",
      "profile_photo_path": "users/2/avatar.jpg"
    }
  }
}
```

This document is the single source of truth for what the backend must implement for the chat list to work as designed.
