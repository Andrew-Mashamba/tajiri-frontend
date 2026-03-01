# Call entry points (audio & video)

Entry points for starting audio and video calls are implemented in **private chats**, **group chats**, and the **Messages → Calls** tab.

---

## 1. Private chat (1:1)

**File:** `lib/screens/messages/chat_screen.dart`

- **Where:** App bar when `_otherParticipantUserId != null` (1:1 conversation).
- **UI:**
  - **Voice:** `IconButton` with `Icons.phone` → `_initiateCall('voice')` (line ~1597).
  - **Video:** `IconButton` with `Icons.videocam` → `_initiateCall('video')` (line ~1601).
- **Flow:** `_initiateCall(String type)` (lines 607–650): if `LocalStorageService.getAuthToken()` exists → push `OutgoingCallFlowScreen`; else → `CallService.initiateCall` then `OutgoingCallScreen`.

---

## 2. Group chat

**File:** `lib/screens/messages/chat_screen.dart`

- **Where:** When `_conversation?.isGroup == true`:
  - **App bar:** Video icon opens group call: `onPressed: _openGroupCall` (line ~1603). Voice icon is **not** shown for groups (only 1:1).
  - **Menu (⋮):** "Simu ya kikundi" (`value: 'group_call'`) → `_startGroupCall()` (line ~1622).
- **Flow:** `_startGroupCall()` (lines 1255–1370): bottom sheet to choose members + type (voice/video) → `CallSignalingService.createGroupCall` → push `OutgoingCallFlowScreen` with `existingCallId` / `existingIceServers`.

---

## 3. Messages → Calls tab

**File:** `lib/screens/messages/conversations_screen.dart`

- **Where:** Messages has three sub-tabs: **Chats** (0), **Groups** (1), **Calls** (2). The Calls tab body is `_buildCallsBody(s)` (lines 1256–1305).
- **UI:**
  - List of call logs (`_filteredCalls`) with All / Missed filter.
  - Each row is `_CallLogTile` (lines 1761–1843):
    - **Tap row** → `_showCallOptions(call)` (voice / video / “Leave voice message” for missed).
    - **Tap trailing call icon** → `onCall` → `_initiateCall(call.otherUserId!, call.type, …)` (same type as the log).
- **Flow:** `_initiateCall(calleeId, type, …)` (lines 588–630): same as chat — auth token → `OutgoingCallFlowScreen`, else `CallService.initiateCall` + `OutgoingCallScreen`.

**Reaching the Calls tab:**

- **From Home:** Bottom nav “Messages” (index 1) → ConversationsScreen with `initialTabIndex`. Then user switches to “Calls” pill (index 2).
- **Deep link:** `/home?messages_tab=calls` or `/messages?tab=calls` (see `lib/main.dart` lines 192–197, 323–327) opens Messages with Calls tab selected (`initialMessagesTab: 2`).
- **Profile:** Profile menu “Simu” opens a **separate** `CallHistoryScreen` (`lib/screens/messages/callhistory_screen.dart`), which also has `_initiateCall` and call options (voice/video/missed voice message). So there are two UIs for call history: inline Calls tab in Messages, and full-screen CallHistoryScreen from Profile.

---

## 4. Conversations list (Chats / Groups tabs)

**File:** `lib/screens/messages/conversations_screen.dart`

- **Chats / Groups:** `_ConversationTile` only has `onTap: () => _openChat(conversation)`. There are **no** quick-call buttons on the list tile; starting a call is done **inside the chat** (see sections 1 and 2).
- **Search results:** Tapping a user opens chat (or similar); no direct call from the list.

---

## 5. Summary table

| Location              | Voice entry              | Video entry               | File(s)                    |
|-----------------------|--------------------------|---------------------------|-----------------------------|
| Private chat app bar  | ✅ Phone icon            | ✅ Videocam icon          | `chat_screen.dart`          |
| Group chat app bar    | ❌                       | ✅ Videocam → group call  | `chat_screen.dart`          |
| Group chat menu       | ✅ “Simu ya kikundi”     | ✅ (same flow, type pick) | `chat_screen.dart`          |
| Messages → Calls tab  | ✅ Row tap options + icon| ✅ Row tap options + icon | `conversations_screen.dart` |
| Profile → Simu        | ✅ Options + icon        | ✅ Options + icon         | `callhistory_screen.dart`   |

---

## 6. Shared flow

- **1:1:** `_initiateCall(calleeId, type)` (in both `chat_screen.dart` and `conversations_screen.dart` / `callhistory_screen.dart`) → token ? `OutgoingCallFlowScreen` : `CallService.initiateCall` + `OutgoingCallScreen`.
- **Group:** Only from chat: `_startGroupCall()` → create group call via signaling → `OutgoingCallFlowScreen` with `existingCallId`.

All of the above entry points are present in the codebase; no extra files were added for this summary.
