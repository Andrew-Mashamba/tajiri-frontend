# TAJIRI — SQLite Adoption Roadmap

> Features that would benefit from local-first SQLite storage, following the same pattern as `MessageDatabase`. Generated 2026-03-31.

---

## High Impact (do these first)

| # | Feature | Current State | Why SQLite | Offline Need |
|---|---------|--------------|-----------|-------------|
| 1 | **Wallet Transactions** | API fetch every open, paginated | Instant history, local filtering by type/status, immutable past data | High — users check balance/history offline |
| 2 | **Notifications** | API fetch every open, paginated | Already has growing history + read/unread state, perfect for local-first | High — scroll history offline |
| 3 | **Shop Products & Cart** | API fetch + 1hr in-memory category cache, cart is API round-trip every time | Local product search (FTS5), persistent cart survives restart, offline browse | High — commerce must work offline |

---

## Medium-High Impact

| # | Feature | Current State | Why SQLite |
|---|---------|--------------|-----------|
| 4 | **Friends List & Requests** | Paginated API, no cache | Pre-cache all friends for instant browse, local name search, offline request status |
| 5 | **Clips Feed** | Paginated API (10/page) | Cache clip metadata for instant scroll restore, track downloaded videos, prefetch |

---

## Medium Impact

| # | Feature | Current State | Why SQLite |
|---|---------|--------------|-----------|
| 6 | **Music Library** | Paginated API per category | Local FTS search (artist/title/genre), offline playlist management, listening history |
| 7 | **Events** | Paginated API, filterable | Local time-based queries (upcoming only), offline RSVP state, category filter |
| 8 | **Groups & Posts** | Paginated API per group | Cache group list + per-group posts, offline membership view |
| 9 | **People Search** | Hive cache (40 item limit) | Upgrade to unlimited cache, local FTS on names/interests, offline filter |
| 10 | **Saved Posts** | Paginated API | Offline browse of user's saved collection, local FTS on content |

---

## Not Worth SQLite

| Feature | Why Not |
|---------|---------|
| Tea/Gossip chat | Streaming/ephemeral, Messages table handles it |
| Real-time (WebSocket/FCM) | Event-driven, not relational |
| Media files | File system + media cache, not relational |
| User profile | Small, in-memory cache with 5min TTL sufficient |
| Content engine feed | ETag cache works well, ML rankings change constantly |

---

## Recommended Implementation Order

### Phase 1: Wallet + Notifications + Shop
Highest user-facing impact, commerce critical.

### Phase 2: Friends + Clips
Social core.

### Phase 3: Music + Events + Groups
Feature completeness.

### Phase 4: People Search + Saved Posts
Polish.

---

## Implementation Pattern

All follow the same pattern as `MessageDatabase` (`lib/services/message_database.dart`):

- **Singleton** database service with lazy initialization
- **`json_data` TEXT column** on each table for flexible field storage and lossless reconstruction
- **Indexed columns** for fast queries (foreign keys, timestamps, status enums, starred/pinned flags)
- **`sync_state` table** to track `last_synced_id` and `last_sync_timestamp` per entity
- **Pending queue table** for offline mutations (create/update/delete) with retry count
- **Delta sync service** — fetch only changed records since last checkpoint
- **Local-first UI** — load from SQLite instantly, sync from server in background

---

## Server Reference

- **Server:** `root@172.240.241.180`
- **Laravel app:** `/var/www/tajiri.zimasystems.com`
- **SSH:** `sshpass -p 'ZimaBlueApps' ssh -o StrictHostKeyChecking=no root@172.240.241.180 '<command>'`
- **Backend AI assistant:** `./scripts/ask_backend.sh "your prompt"`

---

*Generated 2026-03-31 from codebase analysis*
