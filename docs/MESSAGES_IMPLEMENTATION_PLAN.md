# Messages Implementation Plan

This plan covers: (1) adding pill tabs **Chats | Groups | Calls** to the Messages screen (mirroring Posts → Live), and (2) implementing features from [MESSAGES.md](MESSAGES.md) one after another, following [DESIGN.md](DESIGN.md).

---

## Reference: Pill Tabs (Posts → Live)

**Location:** `lib/screens/clips/streams_screen.dart`

- **Widget:** `_LiveTabSegments` — custom segment control; pills wrap label content only (no TabBar indicator).
- **State:** `TabController(length: 2, vsync: this)` with `SingleTickerProviderStateMixin`; `TabBarView(controller, children: [...])`.
- **Pill styling (DESIGN.md aligned):**
  - Constants: `_pillPaddingH = 14`, `_pillPaddingV = 6`, `_pillRadius = 20`, `_gap = 8`.
  - Selected: `Material(color: _kPrimaryText.withOpacity(0.08), borderRadius: 20)`; text 14px, w600, `_kPrimaryText`.
  - Unselected: transparent background; text w500, `_kSecondaryText`.
  - Touch: `InkWell` with same borderRadius; text `maxLines: 1`, `overflow: ellipsis`.
- **AppBar:** `TajiriAppBar(titleWidget: Padding(..., _LiveTabSegments(controller, labels: ['Live now', 'All'])))`.
- **Body:** Single loading/error state; content is `TabBarView` with one child per tab.

---

## Phase 1: Add Pill Tabs to Messages (Chats | Groups | Calls)

**Target:** `lib/screens/messages/conversations_screen.dart`

1. **State and controller**
   - Add `SingleTickerProviderStateMixin`.
   - Add `TabController _tabController` with `length: 3`; init in `initState`, dispose in `dispose`.

2. **Pill widget (reuse Live pattern)**
   - Either:
     - **Option A:** Extract a shared widget (e.g. `lib/widgets/pill_tab_segments.dart`) used by both Streams and Conversations, or
     - **Option B:** Add a private `_MessagesTabSegments` + `_Segment` in `conversations_screen.dart` with the same styling as `_LiveTabSegments` (DESIGN.md colors: background `#FAFAFA`, primaryText `#1A1A1A`, secondaryText `#666666`; 48dp min touch target via InkWell padding).

3. **Labels**
   - Use l10n: Chats, Groups, Calls (e.g. add `chats` / use existing `groups` and `calls` from `app_strings.dart`). Labels: **Chats** | **Groups** | **Calls**.

4. **AppBar**
   - Replace current `AppBar` with `TajiriAppBar` (DESIGN.md §5):
     - `titleWidget`: center-aligned row with the three pill segments (same layout as Live: `Row(mainAxisSize: min, children: pills)`).
     - `actions`: keep search (Heroicons + 48dp per DESIGN.md).

5. **Body**
   - Keep existing loading/error handling; content becomes:
     - **Tab 0 (Chats):** Current conversation list (existing `_buildBody` content for conversations).
     - **Tab 1 (Groups):** List of group conversations only (filter `_conversations.where((c) => c.isGroup)`); reuse `_ConversationTile`; empty state “No groups” with CTA to create group.
     - **Tab 2 (Calls):** Embed or navigate to call history. Prefer embedding: use the same data as `CallHistoryScreen` (e.g. `CallService.getCallHistory`) and build a list similar to `lib/screens/messages/callhistory_screen.dart` so the user stays on Messages with pills (DESIGN.md: one screen, TabBarView).

6. **Data**
   - **Chats:** Existing `_messageService.getConversations`; split in UI into private (Chats) vs group (Groups).
   - **Groups:** Same list, filtered by `conversation.isGroup`.
   - **Calls:** In ConversationsScreen state, add `List<CallLog> _callLogs`, load via `CallService().getCallHistory(currentUserId)` when tab index is 2 or on init; reuse `CallLog` and styling from `callhistory_screen.dart` (list tile with avatar, name, call type, time, missed state).

7. **FAB**
   - Keep FAB; behavior can stay “new conversation” on Chats; on Groups tab could open “Create group” (or keep one FAB that opens bottom sheet: New chat / Create group). Same FAB for all tabs is acceptable; bottom sheet options already include “New message” and “Create group”.

8. **Design compliance**
   - Colors: `#FAFAFA` background, `#1A1A1A` primary, `#666666` secondary, `#999999` tertiary.
   - Typography: title 15–16px w600, body 12–14px, `maxLines` + `overflow: ellipsis` on all dynamic text.
   - Touch targets: 48dp minimum; IconButtons and pill taps use proper padding/constraints.
   - Spacing: 16px horizontal padding, 12px between list items; section padding per DESIGN.md.

---

## Phase 2: Core Messaging (MESSAGES.md §1)

Implement in order; each bullet can be a small step (UI and/or backend contract).

### 2.1 Text Messaging
- One-to-one chat — **done** (existing chat screen).
- Group chats — **done** (conversations include groups; Groups pill shows them).
- Message editing after sending — **new:** in `chat_screen.dart` (or message bubble widget), add long-press/edit action; API: e.g. `PATCH /messages/:id` with `content`; update local list on success.
- Unsent message deletion — **new:** long-press → Delete; API: `DELETE /messages/:id` or flag `deleted_at`; show “Message deleted” or hide in UI.
- Message drafts saved automatically — **new:** persist draft per conversation (e.g. `DraftService` or local storage keyed by `conversationId`); on opening chat, restore draft; save on text change (debounced).
- Reply, quote, forward — **new:** reply/quote: add `replyToMessageId` and show quoted block in composer and in bubble; forward: new screen or bottom sheet “Forward to…” (select conversation), then POST message with `forwarded_from_id` or equivalent.

### 2.2 Voice & Video Messages
- Send voice notes — **new:** record button in chat input; record audio, upload file, send as `MessageType.audio` (or voice subtype); playback in bubble.
- Auto-transcription (on-device, privacy-preserving) — **new:** after recording, run local speech-to-text (e.g. plugin); attach transcript as metadata or separate field; show in bubble (collapsible).
- In-chat recording with visual indicators — **new:** while recording, show waveform or timer and “Recording…” in input area; DESIGN.md 48dp and feedback.
- Video messages (short videos like voice notes) — **new:** record short video (e.g. max 60s), upload, send as video message; play inline in bubble.
- Missed call message (send audio/video note if call not answered) — **new:** when call ends unanswered, show option “Send voice note” / “Send video note” and attach to conversation.

### 2.3 Media Sharing
- Photos, videos, contacts, locations — **partial:** photos/videos likely exist; add “Share contact” and “Share location” (picker + message type).
- Live Photos / Motion Photos — **new:** detect and send as single asset with motion; playback in viewer.
- Animated and seasonal stickers — **new:** sticker picker (grid); send as sticker message type.
- GIFs and custom animated stickers — **new:** GIF search/picker; custom stickers from app assets or user uploads.

### 2.4 Files & Attachments
- Documents (PDF, DOCX, ZIP, etc.) — **partial:** ensure document type supported in `MessageType` and upload; list in chat.
- Built-in document scanning (scan/crop) — **new:** use device camera or file picker + crop; create PDF/image and attach.
- Drag-and-drop on web/desktop — **new:** in chat or composer, accept drag-and-drop of files; same upload + send flow.

---

## Phase 3: Calling (MESSAGES.md §2)

- One-to-one voice/video — **done** (Story 59; chat screen call button).
- Add participants during a call — **new:** in-call UI “Add participant” → select contact → add to call (backend: multi-party call or upgrade).
- Improved video quality & adaptive bandwidth — **new:** integrate with call SDK/backend (e.g. bitrate adaptation, resolution scaling).
- Pinch-to-zoom in video calls — **new:** in `OutgoingCallScreen` / viewer, wrap video in `InteractiveViewer` or gesture detector for pinch-to-zoom.
- Scheduled calls & guest links — **new:** create “Schedule call” from chat; generate link for users not on app; join via link.
- Group calls (up to ~32, voice rooms, speaker spotlight, emoji reactions) — **partial:** group call screen exists; add speaker spotlight (highlight dominant speaker), in-call emoji reactions (send as ephemeral or overlay).
- Favorite contacts and call filters — **new:** settings or call tab: mark contacts as favorite; in Calls tab, filter by All / Missed / Favorites.

---

## Phase 4: Groups & Communities (MESSAGES.md §3)

- Large groups with roles (admins, @all mentions) — **new:** backend + UI for admin role; @all mention in composer (trigger + send as special mention).
- Group metadata and member tags — **new:** group detail screen: list members, roles, tags; edit if admin.
- See who’s online — **new:** presence API; show green dot or “Online” next to members in group header or member list.
- Group polls and decision tools — **new:** “Create poll” in group chat; options, expiry; show results in thread.
- Safety overview (prevent unknown group spam) — **new:** group settings: who can add members, approval for join requests; report group.
- Event tools (events & RSVPs inside groups) — **new:** “Create event” in group; date, place, RSVP; list in group or events tab.

---

## Phase 5: Privacy & Safety (MESSAGES.md §4)

- Presence controls (last seen, read receipts, profile photo, about, status) — **new:** settings screen section “Presence”; toggles for each; “Who can resend your status” (options: everyone / contacts / nobody).
- Account protection (block & report, two-step verification, strict account protection) — **partial:** add two-step verification and “Strict account protection” toggle in settings; block & report may already exist (extend to messages).

---

## Phase 6: Chat Management (MESSAGES.md §5)

- Chat folders (e.g. Work, Friends) — **new:** folders model; assign conversation to folder; sidebar or filter by folder.
- Favorites tab for chats & calls — **new:** “Favorites” list (starred conversations/calls); show in Chats or separate top section.
- Archived chats — **new:** archive action on conversation; filter “Archived” in list or separate section; unarchive.
- Smart search (chats, media, links) — **new:** search screen: full-text in messages, filter by media type, links; DESIGN.md search field and list.
- Group chat name-based search — **new:** in search, filter by group name; show group conversations.
- Message reminders — **new:** long-press message → “Remind me”; set time; local notification or backend reminder; show in “Reminders” list or chat.

---

## Phase 7: User Experience (MESSAGES.md §6)

- Message reactions (long-press emoji) — **new:** long-press bubble → emoji bar; send reaction (backend: reaction table or message reaction field); show on bubble.
- Apple Watch companion — **new:** watch app: show conversations, send quick replies (optional).
- Third-party chat interoperability — **new:** backend/contract for bridging; in-app “Connect other app” or similar (in testing).

---

## Implementation Order (One Feature After Another)

1. **Phase 1** — Pill tabs (Chats | Groups | Calls) on Messages.
2. **Phase 2.1** — Message edit, delete, drafts, reply/quote, forward (one by one).
3. **Phase 2.2** — Voice notes, recording UI, transcription, video messages, missed-call note.
4. **Phase 2.3** — Media: contacts, locations, Live Photos, stickers, GIFs.
5. **Phase 2.4** — Documents, scan, drag-and-drop.
6. **Phase 3** — Call improvements (add participant, quality, pinch-zoom, scheduled, group enhancements, favorites/filters).
7. **Phase 4** — Groups: roles, @all, metadata, online, polls, safety, events.
8. **Phase 5** — Privacy & safety toggles.
9. **Phase 6** — Folders, favorites, archive, search, reminders.
10. **Phase 7** — Reactions, Watch, interoperability.

---

## Design Rules (DESIGN.md) — Checklist per Feature

- Background `#FAFAFA`, surface `#FFFFFF`, primary text `#1A1A1A`, secondary `#666666`, tertiary `#999999`.
- No colorful buttons (monochrome only).
- Border radius: 16px cards, 12px buttons/chips; 8px list tiles.
- Spacing: 16px container, 12px between cards, 8px icon-to-text.
- Min touch target 48x48dp; primary buttons 72–80px height where applicable.
- `maxLines` + `TextOverflow.ellipsis` on all dynamic text.
- Use `TajiriAppBar`, Heroicons, and existing components (Navigation Card, List Tile Card, etc.) where applicable.
- SafeArea, RefreshIndicator for lists; dispose controllers.

---

## Files to Touch (Phase 1)

| File | Change |
|------|--------|
| `lib/screens/messages/conversations_screen.dart` | Add TabController, pill segments (Chats/Groups/Calls), TabBarView; Chats = current list, Groups = filter isGroup, Calls = call history list (load CallService). |
| `lib/l10n/app_strings.dart` | Add `chats` (e.g. “Mazungumzo” / “Chats”) if not present; use `groups`, `calls` for pill labels. |
| `lib/widgets/tajiri_app_bar.dart` | No change (already supports titleWidget and actions). |
| Optional: `lib/widgets/pill_tab_segments.dart` | New shared widget for Live + Messages pills to avoid duplication. |

After Phase 1, proceed with Phase 2.1, then 2.2, and so on, one feature at a time, with small PRs or commits per feature.
