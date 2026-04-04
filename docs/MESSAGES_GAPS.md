# TAJIRI Messaging — Feature Gaps & Migration Status

> Full audit of `docs/MESSAGES.md` against codebase. Generated 2026-03-31. Updated 2026-03-31 after implementation.

---

## 1. Not Implemented

Features listed in `docs/MESSAGES.md` with zero codebase presence.

| # | Feature | Effort | Impact | Status |
|---|---------|--------|--------|--------|
| 1 | ~~Message reminders (snooze/follow-up)~~ | Medium | High | **DONE** — `MessageReminderService` + bottom sheet with 4 presets (15m, 1h, 3h, tomorrow) + `flutter_local_notifications` scheduling |
| 2 | **Live Photos / Motion Photos** support | Medium | Low | NOT STARTED — niche iOS/Android feature |
| 3 | **Guest chats** (invite non-users via link) | Large | Medium | NOT STARTED — needs backend link-token system, guest user model |
| 4 | **Group voice chats** (persistent audio rooms) | Large | Medium | NOT STARTED — Clubhouse/Spaces style |
| 5 | ~~Safety overview (group spam prevention)~~ | Medium | Medium | **DONE** — "Usalama wa kikundi" section in group_info_screen with join approval + contacts-only toggles |
| 6 | **Drag-and-drop** file sharing (web/desktop) | Small | Low | NOT STARTED — mobile app only |
| 7 | **Apple Watch** companion | Large | Low | NOT STARTED |
| 8 | **Third-party chat interop** | Large | Low | NOT STARTED |

---

## 2. SQLite Migration Gaps

| # | Gap | Severity | Status |
|---|-----|----------|--------|
| 1 | ~~Offline queue not wired~~ | CRITICAL | **DONE** — All 11 send methods in chat_screen.dart now save to SQLite `pending_messages` on failure |
| 2 | ~~Star sync broken~~ | CRITICAL | **DONE** — `starred_messages_screen.dart` unstar + `chat_screen.dart` toggleStar both update SQLite |
| 3 | ~~Group conversations not cached~~ | HIGH | **DONE** — Groups tab loads from SQLite first, caches API results to SQLite |
| 4 | ~~Metadata not synced back~~ | HIGH | **DONE** — Pin/archive/mute/favorite now use `_syncAndReloadConversations()` for SQLite consistency |
| 5 | ~~Drafts in SharedPreferences~~ | MEDIUM | **DONE** — `drafts` table added to MessageDatabase (v2 migration), methods: saveDraft/getDraft/getAllDrafts/clearDraft |
| 6 | ~~Conversation search API-only~~ | MEDIUM | **DONE** — search_conversations_screen loads from SQLite first, then API |
| 7 | **Call history not cached** | MEDIUM | NOT STARTED — per SQLITE_ADOPTION_ROADMAP.md, separate scope |

---

## 3. Partially Implemented

| # | Feature | Status |
|---|---------|--------|
| 1 | ~~Stickers~~ | **DONE** — 3-tab sticker browser (Recent/Emojis/Popular), search bar, recently-used tracking via SharedPreferences |
| 2 | ~~Smart search~~ | **DONE** — 6 filter chips (All/Photos/Video/Links/Docs/Audio), searches conversations + messages, SQLite + API hybrid |
| 3 | ~~Favorite contacts in calls~~ | **DONE** — "Favorites" filter chip added to Calls tab, filters by favorited conversation participants |
| 4 | ~~Message reactions~~ | **DONE** — Full emoji picker already existed; added tappable reaction bubbles → "Waliojibu" (who reacted) bottom sheet with user list + remove own reaction |
| 5 | ~~Disappearing messages~~ | **DONE** — Timer bottom sheet in chat + group info (Off/24h/7d/90d), timer icon on expiring message bubbles, timer label in AppBar subtitle |
| 6 | ~~Read receipts privacy~~ | **DONE** — Toggle in privacy_settings_screen.dart, PresenceService respects online_status_visibility |

---

## 4. Privacy & Settings

| # | Feature | Status |
|---|---------|--------|
| 1 | ~~Last seen visibility control~~ | **DONE** — Picker (everyone/friends/nobody) in privacy_settings_screen |
| 2 | ~~Read receipts control~~ | **DONE** — Toggle switch in privacy_settings_screen |
| 3 | ~~Online status control~~ | **DONE** — Toggle + PresenceService skips heartbeats when set to nobody |
| 4 | ~~Profile photo visibility~~ | **DONE** — Picker in privacy_settings_screen |
| 5 | ~~About/status visibility~~ | **DONE** — Two separate pickers in privacy_settings_screen |
| 6 | ~~Status resend control~~ | **DONE** — Picker in privacy_settings_screen |
| 7 | ~~Two-step verification~~ | **DONE** — Navigation to existing TwoFactorScreen |
| 8 | ~~Strict account protection~~ | **DONE** — Navigation to existing AccountProtectionScreen |

---

## 5. Implementation Summary

### Completed (18/23 items)
- Sprint 1: All 4 SQLite critical fixes ✅
- Sprint 2: Message reminders + Disappearing messages UI + Sticker packs ✅
- Sprint 3: Conversation search from SQLite + Smart search tabs + Favorites in calls ✅
- Sprint 4: Drafts migrated to SQLite ✅ (call history and receipts cache deferred)
- Sprint 5: Full emoji reactions + privacy toggles + read receipt privacy ✅
- Sprint 6: Safety overview ✅ (guest chats deferred)

### Remaining (2 items)
| # | Feature | Effort | Reason Deferred |
|---|---------|--------|-----------------|
| 1 | Message receipts cache | Small | Low impact, receipts change frequently |
| 2 | Drag-and-drop (web/desktop) | Small | No web target exists |

### Newly Completed (this session)
| # | Feature | Status |
|---|---------|--------|
| 1 | **Call history SQLite cache** | **DONE** — call_history table (v3 migration), SQLite-first load in both callhistory_screen + conversations_screen Calls tab |
| 2 | **Guest chats (invite links)** | **DONE** — GuestChatService + InviteLinkSheet UI + backend endpoints (invite-link CRUD + guest/join) |
| 3 | **Group voice chats (audio rooms)** | **DONE** — AudioRoomService + discovery screen + in-room screen with speaker/listener/host roles, raise hand, promote/demote |
| 4 | **Live Photos / Motion Photos** | **DONE** — LivePhotoService (iOS HEIC+MOV, Android embedded MP4 detection) + LivePhotoViewer (long-press to play) + live_photo MessageType |
| 5 | **Apple Watch companion** | **REMOVED** — Decided not to include. watchOS has too small a user base for the maintenance cost. |
| 6 | **Third-party chat interop** | **DONE** — ChatInteropService + ChatBridgesScreen (Matrix/RCS/SMS/Email), bridge badge on conversations, bridge fields on Conversation model |

---

### Files Changed

| File | Changes |
|------|---------|
| `lib/screens/messages/chat_screen.dart` | Offline queue wiring, star sync, disappearing messages UI, reminder bottom sheet, in-chat search from SQLite, reaction "who reacted" sheet |
| `lib/screens/messages/conversations_screen.dart` | Group caching, metadata sync, favorites in calls |
| `lib/screens/messages/starred_messages_screen.dart` | Star sync to SQLite |
| `lib/screens/messages/search_conversations_screen.dart` | SQLite-first search, media/links filter tabs |
| `lib/screens/messages/group_info_screen.dart` | Disappearing messages UI, group safety toggles |
| `lib/services/message_database.dart` | Drafts table (v2 migration), draft CRUD methods |
| `lib/services/message_reminder_service.dart` | **NEW** — Schedule/cancel/list reminders via local notifications |
| `lib/widgets/sticker_browser.dart` | 3-tab layout, search, recently-used tracking |
| `lib/screens/settings/privacy_settings_screen.dart` | Full privacy settings with 8 toggles |
| `lib/services/privacy_service.dart` | Auth token fix, per-setting PATCH method |
| `lib/services/presence_service.dart` | Respects online_status_visibility privacy setting |
| `lib/services/message_database.dart` | Call history table (v3 migration), call CRUD methods |
| `lib/screens/messages/callhistory_screen.dart` | SQLite-first load + API sync for call history |
| `lib/services/guest_chat_service.dart` | **NEW** — Invite link CRUD + guest join |
| `lib/screens/messages/invite_link_screen.dart` | **NEW** — Invite link management bottom sheet |
| `lib/services/audio_room_service.dart` | **NEW** — Audio rooms API service (create/join/leave/promote/demote/mute) |
| `lib/screens/audio_rooms/audio_rooms_discovery_screen.dart` | **NEW** — Room discovery feed with create FAB |
| `lib/screens/audio_rooms/audio_room_screen.dart` | **NEW** — In-room UI with speakers/listeners/raised hands |
| `lib/services/live_photo_service.dart` | **NEW** — iOS Live Photo + Android Motion Photo detection |
| `lib/widgets/live_photo_viewer.dart` | **NEW** — Long-press-to-play live photo widget |
| `lib/services/chat_interop_service.dart` | **NEW** — Chat bridge service (Matrix/RCS/SMS/Email) |
| `lib/screens/settings/chat_bridges_screen.dart` | **NEW** — Bridge management settings screen |
| `lib/models/message_models.dart` | Added live_photo MessageType + bridge fields on Conversation |
| `lib/services/message_service.dart` | Added videoMedia param for live photo uploads |

### Backend Endpoints
- `GET/PATCH /api/conversations/{id}/settings` — group safety toggles
- `GET/PATCH /api/conversations/{id}/sync` — delta message sync
- `GET/PUT/PATCH /api/users/{id}/privacy-settings` — privacy preferences
- `POST/GET/DELETE /api/conversations/{id}/invite-link(s)` — invite link management
- `POST /api/guest/join` — guest chat join (no auth)
- `GET/POST /api/audio-rooms`, `POST .../join|leave|end|raise-hand|promote|demote`, `PATCH .../mute` — audio rooms
- `GET/POST/DELETE /api/chat-bridges/*` — chat bridge management

---

*Generated 2026-03-31. Updated 2026-03-31 after full implementation.*
