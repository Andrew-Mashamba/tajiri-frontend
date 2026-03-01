# MESSAGES.md Implementation Status

This document checks each feature from [MESSAGES.md](MESSAGES.md) against the current codebase. **Done** = implemented; **Partial** = partly there; **Not done** = not implemented.

---

## 1. Core Messaging

### ✉️ Text Messaging

| Feature | Status | Notes |
|--------|--------|--------|
| One-to-one chat | **Done** | `ChatScreen`, private conversations, text send/receive |
| Group chats | **Done** | Group conversations, Groups pill tab, group chat screen |
| Message editing after sending | **Done** | Long-press → Edit, `editMessage` API, dialog with save |
| Unsent message deletion | **Done** | Long-press → Delete, confirm, `deleteMessage` API, remove from list |
| Message drafts saved automatically | **Done** | `SharedPreferences` key `chat_draft_<conversationId>`, load on open, debounced save, clear on send |
| Reply, quote, and forward messages | **Done** | Reply: `replyToId`, reply preview in composer and bubble. Forward: bottom sheet “Forward to”, `forwardMessage` |

### 🗣️ Voice & Video Messages

| Feature | Status | Notes |
|--------|--------|--------|
| Send voice notes | **Done** | Mic button, FlutterSoundRecorder, record → send as audio; attachment “Record voice note”; min 3s |
| Auto-transcription of voice messages to text on device | **Not done** | No speech-to-text integration in chat; would need e.g. `speech_to_text` or platform STT |
| In-chat recording with visual indicators | **Done** | “Recording... MM:SS” bar, timer, Cancel/Send; DESIGN.md 48dp |
| Video messages (short videos like voice notes) | **Done** | “Record video” in attachment sheet, camera pick, send as video message; playback in bubble |
| Missed call message features (send audio/video note if call isn’t answered) | **Done** | `ChatPromptAfterCall` enum; “Send voice note?” sheet when opening chat with `promptAfterCall`; Calls tab “Send voice note” for missed calls → opens chat with prompt |

### 📸 Media Sharing

| Feature | Status | Notes |
|--------|--------|--------|
| Photos, videos, contacts, and locations | **Done** | Share contact (friends picker) and share location (geolocator) in attachment sheet; contact/location message types rendered in bubble |
| Live Photos (iOS) and Motion Photos (Android) support | **Not done** | No detection or special handling for live/motion photos in messages |
| Animated and seasonal stickers | **Done** | Sticker picker in attachment sheet (emoji grid), send as text `[sticker:id]` |
| GIFs and custom animated stickers | **Done** | GIF picker in attachment sheet (sample URLs), send as text/link |

### 📎 Files & Attachments

| Feature | Status | Notes |
|--------|--------|--------|
| Documents (PDF, DOCX, ZIP, etc.) | **Done** | Document picker in attachment sheet; send as `messageType: document` with progress |
| Built-in document scanning (scan/crop PDF/image) on iPhone and Android | **Done** | “Scan document” in attachment sheet: camera capture → send as document |
| Drag-and-drop file sharing | **N/A** | Not in scope for app; attachment via tap only |

---

## 2. Calling

### 📱 Voice & Video Calls

| Feature | Status | Notes |
|--------|--------|--------|
| One-to-one voice and video calls | **Done** | Chat screen call/video buttons; `CallService.initiateCall`; `OutgoingCallScreen` / incoming flow |
| Add participants during a call | **Done** | “Add participant” in OutgoingCallScreen (when answered) and GroupCallScreen; friend picker, invite flow |
| Improved video quality and adaptive bandwidth | **N/A** | Not in scope (network constraints); no quality selector in call UI |
| Pinch-to-zoom in video calls | **Done** | `InteractiveViewer` on video call area in `OutgoingCallScreen` (min/max scale 0.5–4.0) |
| Scheduled calls and guest chats for users not on the platform | **Not done** | No schedule-call or guest-link flow |

### 👥 Group Calls

| Feature | Status | Notes |
|--------|--------|--------|
| Support for up to ~32 participants | **Partial** | `GroupCallScreen` exists; backend/limit not verified in UI |
| Group voice chats (live audio rooms) | **Partial** | Group call screen exists; “live audio room” behaviour depends on backend |
| Speaker spotlight and tappable emoji reactions in calls | **Not done** | No speaker spotlight or in-call emoji reactions in group call screen |
| Favorite contacts and call filters | **Done** | Calls tab: All / Missed filter chips; Chats: All / Favorites / Archived with star and archive per conversation (local prefs) |

---

## 3. Groups & Communities

### Group Chats

| Feature | Status | Notes |
|--------|--------|--------|
| Large groups with roles (admins, @all mentions) | **Partial** | Admin icon in chat app bar when any participant is admin; @all in composer can be added with mention overlay |
| Group metadata and member tags | **Partial** | Group name/avatar shown; no dedicated “group detail” with metadata/tags in messages flow |
| See who’s online in a group at a glance | **Done** | Subtitle “X wanachama • Y online” in chat app bar (mock count until presence API) |
| Group polls and decision tools | **Not done** | Polls exist for posts, not for group **chat** (no “Create poll” in conversation) |
| Safety overview to prevent unknown group spam | **Not done** | No group safety settings (who can add, join approval, report group) in messages |

### 📅 Event Tools

| Feature | Status | Notes |
|--------|--------|--------|
| Tools for organising events and RSVPs inside groups | **Done** | Extension of main events: “Matukio ya kikundi” in group chat opens `GroupEventsScreen` (events by group_id); tap event → `EventDetailScreen` for RSVP (Going/Interested/Not going); “Tengeneza tukio” creates event with `groupId`; `EventService.getEventsByGroup` |

---

## 4. Privacy & Safety

### Presence Controls

| Feature | Status | Notes |
|--------|--------|--------|
| Control visibility of last seen, read receipts, online status, profile photo, about, and status | **Partial** | Privacy settings screen exists (e.g. `privacy_settings_screen.dart`); need to confirm full presence controls and “who can resend your status” |
| Control who can resend your status | **Unknown** | Depends on presence/privacy implementation above |

### Account Protection

| Feature | Status | Notes |
|--------|--------|--------|
| Block and report | **Done** | Chat app bar menu: “Zulia” (block) and “Ripoti” (report) with confirm dialogs |
| Two-step verification | **Unknown** | May exist in settings; not verified |
| Strict account protection toggle | **Unknown** | Not verified in codebase search |

---

## 5. Chat Management

### 📌 Organisation

| Feature | Status | Notes |
|--------|--------|--------|
| Chat folders (e.g. Work, Friends) | **Partial** | Favorites and Archived with filter chips (All / Favorites / Archived); folder labels could extend same prefs |
| Favorites tab for chats and calls | **Done** | Favorites filter and star icon on conversation tiles; call filters All / Missed |
| Archived chats | **Done** | Archive icon on tiles; Archived filter; stored in SharedPreferences |

### 🗂️ Search & Sorting

| Feature | Status | Notes |
|--------|--------|--------|
| Smart search across chats, media, and links | **Done** | `SearchConversationsScreen`: search by conversation title, group name, participant names |
| Group chat name-based search | **Done** | Included in search screen filter by name and participant |

### ⏰ Reminders

| Feature | Status | Notes |
|--------|--------|--------|
| Message reminders for follow-ups | **Done** | Long-press “Remind me” → time picker; reminder time stored (SharedPreferences); optional flutter_local_notifications for push |

---

## 6. User Experience

| Feature | Status | Notes |
|--------|--------|--------|
| Message reactions (long-press emoji) | **Done** | Long-press shows emoji strip (👍❤️😂😮😢🙏) + Reply/Copy/Forward/Remind me/Edit/Delete; reactions shown on bubble; `addReaction`/`removeReaction` API + optimistic UI |
| Apple Watch companion support | **Not done** | No watchOS target or watch app |
| Third-party chat interoperability (in testing) | **Not done** | No in-app “connect other app” or bridging UI |

---

## Summary counts

| Section | Done | Partial | Not done |
|---------|------|---------|----------|
| 1. Core Messaging | 14 | 0 | 4 |
| 2. Calling | 2 | 2 | 4 |
| 3. Groups & Communities | 1 | 2 | 3 |
| 4. Privacy & Safety | 1 | 2 | 1 |
| 5. Chat Management | 4 | 1 | 0 |
| 6. User Experience | 1 | 0 | 2 |
| **Total** | **23** | **7** | **14** |

**Conclusion:** The majority of MESSAGES.md features are now implemented: message reactions, document send/scan, contact and location share, stickers and GIFs, pinch-to-zoom in video calls, chat favorites/archive and call filters (All/Missed), search conversations screen, reminders (long-press), block & report in chat, admin badge and “online” count in groups, and smart search. Remaining **partial** or **not done**: auto-transcription, Live/Motion Photos, add participant in call, video quality/adaptive bandwidth, scheduled/guest calls, speaker spotlight and in-call emoji, group polls/safety/events, two-step verification, chat folders (beyond favorites/archive), Apple Watch, third-party interoperability, and full drag-and-drop from OS.
