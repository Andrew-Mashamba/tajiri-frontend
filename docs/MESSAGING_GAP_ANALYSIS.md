# TAJIRI Messaging — WhatsApp Gap Analysis

> Prioritized by user impact. Based on deep research of WhatsApp's architecture and a thorough audit of TAJIRI's current messaging implementation.

---

## High-Impact Gaps (users notice immediately)

| Feature | WhatsApp | TAJIRI | Effort |
|---------|----------|--------|--------|
| **Message status icons** (clock → ✓ → ✓✓ → blue ✓✓) | Full 4-state: pending, sent, delivered, read — each with distinct icon and timestamp | Only `isRead` boolean — no sent/delivered distinction, no pending state | Medium |
| **Online / Last seen** | Real-time presence via heartbeat (~10s interval), Redis TTL ~30s, shown in chat header | None — no presence API, no last seen timestamp | Medium |
| **Swipe-to-reply** | Swipe right on any message bubble to quote-reply | Long-press → menu → Reply (3 taps vs 1 gesture) | Small |
| **Message search** | Full-text search across all chats (SQLite FTS), jump-to-message, highlight matches | "Coming soon" stub — no backend endpoint, no FTS index | Medium |
| **Read receipts in groups** | Per-member delivery + read timestamps (visible in Message Info) | Conversation-level `markAsRead` only — no per-member tracking | Medium |
| **Link previews** | Auto-generated inline card (thumbnail, title, domain) — fetched client-side before send, embedded in message payload | None — URLs render as plain text | Small |

---

## Medium-Impact Gaps

| Feature | WhatsApp | TAJIRI | Effort |
|---------|----------|--------|--------|
| **Server-synced mute/archive/pins** | Persisted on server, syncs across devices | Local SharedPreferences only — lost on reinstall/new device | Small |
| **Disappearing messages** | Configurable timer (24h, 7d, 90d) per conversation | None | Medium |
| **Starred/saved messages** | Cross-chat bookmarks, accessible from settings | None | Small |
| **Forward label** ("Forwarded") | Shows "Forwarded" / "Forwarded many times" indicator | No indicator — forwarded messages look identical to original | Tiny |
| **Emoji reaction picker** | Full emoji keyboard with search, 6 quick-access shortcuts | Fixed 6 hardcoded emojis, no search | Small |
| **Voice message speed** (1x / 1.5x / 2x) | Yes — speed toggle during playback | No — fixed 1x playback only | Small |

---

## Architecture Gaps

| Area | WhatsApp | TAJIRI |
|------|----------|--------|
| **Real-time delivery** | Persistent TCP socket with custom binary protocol (FunXMPP). Sub-100ms message delivery. Erlang processes handle 1-2M concurrent connections per server. | Firestore listener → REST API refetch. 1-3 second latency per message. No WebSocket for message delivery. |
| **Message storage** | Local SQLite is the source of truth. Server is a relay — deletes messages after delivery confirmation. App works fully offline for reading history. | Server is source of truth. Hive is a cache (max 500 msgs/conversation). Messages must be re-fetched if cache is cleared. |
| **Optimistic send** | Message written to local SQLite immediately → appears in UI with clock icon → encrypted and sent in background → status updates as server/recipient acknowledge. Retry with idempotent `client_message_id` on failure. | `PendingMessageStore` shows preview text while API responds. No local persistence of pending messages. Preview lost on app restart. No retry mechanism. |
| **Connection management** | Automatic reconnection with exponential backoff. Background keepalive (Android foreground service / iOS silent push). Queued messages delivered immediately on reconnect. | No persistent connection. Relies on Firestore listener + FCM push. No offline message queue beyond cache. |
| **Typing indicators** | Real-time via WebSocket. Rate-limited, batched. | HTTP polling every 2 seconds for top 5 conversations. |

---

## What TAJIRI Already Does Well

| Feature | Status |
|---------|--------|
| Rich message types (text, image, video, audio, doc, location, contact, shared post) | 8 types |
| Group chat with @mentions and @all | Working |
| Message reactions (emoji toggle) | Working |
| Reply-to with quoted preview | Working (via long-press) |
| Message edit and delete | Working |
| Message forwarding | Working |
| Voice recording in-chat | Working (3s min, AAC codec) |
| Media upload with progress | Working (auto Dio for >5MB) |
| Conversation caching (Hive) | Working (instant load) |
| Typing/recording indicators | Working (polling) |
| Draft auto-save | Working (SharedPreferences, 800ms debounce) |
| Pinned conversations (up to 3) | Working (local) |
| Archived conversations | Working (local) |
| Conversation folders (Work, Friends, Personal) | Working (local) |
| 1:1 and group video/voice calls (WebRTC) | Working |

---

## Recommended Implementation Order

### Sprint 1: Core Messaging UX (highest user impact, mostly frontend)
1. **Message delivery states** — backend adds `status` enum (pending/sent/delivered/read) + timestamps; frontend renders clock/✓/✓✓/blue ✓✓ icons
2. **Swipe-to-reply** — frontend Dismissible gesture on message bubbles
3. **Forward label** — frontend shows "Forwarded" on `forwardMessageId != null`
4. **Link previews** — frontend fetches OG metadata before send; backend stores preview in message payload

### Sprint 2: Presence + Search (medium effort, high impact)
5. **Online / Last seen** — backend heartbeat endpoint + Redis TTL; frontend shows in chat header
6. **Message search** — backend FTS index on messages table + search endpoint; frontend search UI in chat and conversation list
7. **Server-synced mute/archive/pins** — backend CRUD on conversation_participants; frontend syncs on load

### Sprint 3: Polish (small effort, noticeable quality)
8. **Starred messages** — backend pivot table; frontend star action + starred messages screen
9. **Emoji reaction picker** — frontend full emoji keyboard with search
10. **Voice message speed control** — frontend playback rate toggle (1x/1.5x/2x)
11. **Read receipts in groups** — backend per-participant read tracking; frontend Message Info screen

### Future: Architecture Evolution
12. **WebSocket for message delivery** (Laravel Reverb already deployed for calls — extend to messaging)
13. **Optimistic send with local persistence** (write to Hive first, sync in background, retry on failure)
14. **Disappearing messages** (backend TTL + scheduled cleanup; frontend timer UI)

---

## Server Reference

- **Server:** `root@172.240.241.180`
- **Laravel app:** `/var/www/tajiri.zimasystems.com`
- **SSH:** `sshpass -p 'ZimaBlueApps' ssh -o StrictHostKeyChecking=no root@172.240.241.180 '<command>'`
- **Backend AI assistant:** `./scripts/ask_backend.sh "your prompt"`

---

*Generated 2026-03-31 from WhatsApp architecture research + TAJIRI codebase audit.*
