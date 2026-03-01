# Video & Audio Calls — Gap Analysis

**Product:** Tajiri  
**Date:** 2025-02-16  
**Scope:** What the docs say should be implemented vs what exists in the Flutter repo.

Use with: [implementation-plan.md](implementation-plan.md), [implementation-steps.md](implementation-steps.md), [backend-requirements/](backend-requirements/README.md).

---

## Summary

| Area | Spec (supposed to) | Implemented | Gap |
|------|--------------------|-------------|-----|
| **Phase 0 (Flutter)** | Deps, permissions, TURN client, auth on API | ✅ Done | None |
| **Phase 1 – API & WebRTC** | New REST + WS + WebRTC flow | ✅ Done (in new services/screens) | Legacy CallService not aligned; new flow used when authToken set |
| **Phase 1 – Incoming trigger** | Show incoming UI on CallIncoming (WS or push) | ✅ Done | FCM `call_incoming` → CallIncomingEvent → IncomingCallFlowScreen; accept/reject via CallSignalingService + authToken |
| **Phase 1 – Voice/Video UI** | Per 02-ui-spec (speaker, PiP, zoom) | ✅ Done | Speaker → Helper.setSpeakerphoneOn; PiP draggable; tap-to-swap; pinch-zoom (InteractiveViewer) |
| **Phase 1 – Entry points** | Start call from chat/history; receive from push/WS | ✅ Done | Chat/Conversations use OutgoingCallFlowScreen when authToken exists; FCM uses IncomingCallFlowScreen |
| **Phase 1 – Reconnect** | ICE failure → iceRestart + “Reconnecting…” | ✅ Done | onIceConnectionState Disconnected/Failed → createOfferIceRestart; banner + status text |
| **Phases 2–4** | Group, screen share, reactions | ⚠️ Partial | Add/Leave API + screen share + send reaction/raise hand; no group call UI, no ParticipantAdded handling, no incoming reaction/hand display, no missed-call voice message, no scheduled calls |
| **Remaining** | See features-not-implemented.md | — | CallService alignment, group call UI, incoming reaction/hand UI, missed-call voice message, scheduled calls, overlay auto-hide, switch camera, etc. |

---

## Phase 0 — Foundation (Flutter)

| Step | Spec | Implemented | Gap |
|------|------|-------------|-----|
| 0.F.1 | Add `flutter_webrtc` | ✅ `pubspec.yaml`: flutter_webrtc | — |
| 0.F.2 | Android: RECORD_AUDIO, CAMERA, INTERNET, MODIFY_AUDIO_SETTINGS | ✅ AndroidManifest has all | — |
| 0.F.3 | iOS: NSMicrophoneUsageDescription, NSCameraUsageDescription | ✅ Info.plist | — |
| 0.F.4 | TURN credentials API (GET with auth) | ✅ `CallSignalingService.getTurnCredentials()` | — |
| 0.F.5 | Auth token on all call API requests | ✅ Token passed in CallSignalingService | — |

**Verdict:** No gap.

---

## Phase 1 — Core 1:1 Voice & Video

### 1. API & signaling (1.F.1, 1.F.2)

| Step | Spec | Implemented | Gap |
|------|------|-------------|-----|
| 1.F.1 | Align **CallService** with new API (POST /api/calls, accept, reject, end; call_id, ice_servers) | **CallSignalingService** implements new API. **CallService** unchanged: still uses `/calls/initiate`, `/answer`, `/decline`, `/end`, `/status`, `/history`. | **Gap:** Two parallel paths. CallService not aligned; any code using CallService still talks to old backend. |
| 1.F.2 | sendSignaling(callId, type, sdp \| candidate) → POST /api/calls/{id}/signaling | ✅ `CallSignalingService.sendSignaling()` | — |

**Recommendation:** Either deprecate CallService for 1:1 and migrate all entry points to CallSignalingService, or add a “new API mode” (e.g. when authToken is set) inside CallService that delegates to the new endpoints.

---

### 2. WebSocket & state (1.F.3, 1.F.4)

| Step | Spec | Implemented | Gap |
|------|------|-------------|-----|
| 1.F.3 | WS: subscribe to `private-call.{callId}`; listen for CallIncoming, CallAccepted, CallRejected, CallEnded, SignalingOffer/Answer/IceCandidate | ✅ `CallChannelService`: Reverb connect, /broadcasting/auth, subscribe, all events parsed | — |
| 1.F.4 | Single state holder: callId, status, isCaller, remoteUser, type, local/remote stream, etc. | ✅ `CallState` (ChangeNotifier) | — |

**Verdict:** No gap.

---

### 3. WebRTC (1.F.5–1.F.9)

| Step | Spec | Implemented | Gap |
|------|------|-------------|-----|
| 1.F.5 | Create PC with TURN/STUN from create/accept response | ✅ `CallWebRTCService.initPeerConnection(iceServers)` | — |
| 1.F.6 | getUserMedia: voice = audio only; video = audio + video | ✅ `getUserMedia(video: bool)` | — |
| 1.F.7 | Offer/answer flow (caller offer → callee answer) | ✅ createOffer, setRemoteOfferAndCreateAnswer, setRemoteAnswer; used in flows | — |
| 1.F.8 | ICE: send candidates via signaling; add on receive | ✅ onIceCandidate → sendSignaling; onSignalingIceCandidate → addIceCandidate | — |
| 1.F.9 | onTrack → remoteStream; notify UI; RTCVideoRenderer for video | ✅ onRemoteStream; ActiveCallScreen uses RTCVideoView | — |

**Verdict:** No gap.

---

### 4. Outgoing call flow (1.F.10)

| Step | Spec | Implemented | Gap |
|------|------|-------------|-----|
| 1.F.10 | Screen: pick user → **request permissions** → POST create → subscribe WS → create PC + offer → send offer → wait for answer/ICE → connected UI | ✅ `OutgoingCallFlowScreen`: create → subscribe → PC → offer → ICE; no explicit **pre-request** of mic/camera (getUserMedia triggers system prompt). | **Minor:** No explicit permission request before starting (optional per spec). |

**Entry points:**

- **Call history (Messages → Simu):** When `authToken != null`, uses `OutgoingCallFlowScreen` (new flow). ✅  
- **Chat screen (call button):** When `authToken != null`, uses `OutgoingCallFlowScreen` (new flow) with calleeId, calleeName, calleeAvatarUrl, type; otherwise falls back to CallService. ✅  
- **Conversations screen:** Same as Chat; when token exists uses OutgoingCallFlowScreen with callee name/avatar. ✅

---

### 5. Incoming call flow (1.F.11)

| Step | Spec | Implemented | Gap |
|------|------|-------------|-----|
| 1.F.11 | **On CallIncoming (WS or push):** show full-screen incoming UI (name, avatar, Accept/Decline). Accept → POST accept → subscribe → create PC → on offer set remote, create answer, send → bind streams. | **UI:** `IncomingCallFlowScreen` implements accept/reject with `CallSignalingService`. **Trigger:** FCM `call_incoming` builds `CallIncomingEvent` from payload (call_id, caller_id, caller_name, caller_avatar_url, type), gets authToken from LocalStorageService, and opens `IncomingCallFlowScreen` with incoming + authToken; Accept/Decline use `CallSignalingService.acceptCall` / `rejectCall`. | ✅ Implemented. Optional: “Message” shortcut on incoming screen not done. |

**Notes:**

- Backend broadcasts CallIncoming on `private-call.{call_id}`; callee must already be subscribed to that channel to receive it over WS. In practice, callee is notified via **push** (call_id + caller info); app then subscribes after opening the incoming screen. So “receive via WS” is only after we have call_id from push (or a user-level channel if backend adds one).
- Push payload should include at least: `call_id`, `caller_id`, `caller_name`, `caller_avatar_url`, `type` so the app can build `CallIncomingEvent` and open `IncomingCallFlowScreen` without a separate GET.

---

### 6. Voice call UI (1.F.12)

| Spec (02-ui-spec) | Implemented | Gap |
|-------------------|-------------|-----|
| Header: name, status/timer | ✅ ActiveCallScreen voice layout | — |
| Center avatar | ✅ | — |
| Bottom: Mute, Speaker, Add, End (red) | ✅ | — |
| Bind mute to audio track enable/disable | ✅ setMicrophoneEnabled | — |
| **Bind speaker to audio route (earpiece/speaker)** | ✅ `Helper.setSpeakerphoneOn(next)` from flutter_webrtc in ActiveCallScreen | — |

---

### 7. Video call UI (1.F.13)

| Spec (02-ui-spec) | Implemented | Gap |
|-------------------|-------------|-----|
| Full-screen remote video | ✅ | — |
| **Self PiP: draggable, e.g. top-right** | ✅ PiP in Positioned with state; onPanUpdate drag, clamped to screen | — |
| **Tap to swap main/PiP (optional)** | ✅ onTap on main and PiP toggles _mainIsRemote | — |
| Overlay: name, timer | ✅ | — |
| Bottom: Mute, Camera, End, Add, More | ✅ | — |
| Bind camera to video track | ✅ setCameraEnabled | — |
| **Primary canvas: pinch-to-zoom** (02 § 3.2) | ✅ InteractiveViewer on main video (min 0.5, max 4) | — |
| **Primary canvas: double-tap focus** (02 § 3.2) | ❌ Not implemented | **Gap:** See features-not-implemented.md. |

---

### 8. End call (1.F.14)

| Spec | Implemented | Gap |
|------|-------------|-----|
| On End tap: POST end, close PC, dispose renderers, clear state, pop | ✅ ActiveCallScreen._endCall → signaling.endCall; _cleanupAndPop | — |
| On CallEnded from WS: same cleanup | ✅ channel.onCallEnded → _cleanupAndPop | — |

**Verdict:** No gap.

---

### 9. Call log screen (1.F.15)

| Spec | Implemented | Gap |
|------|-------------|-----|
| GET /api/calls with pagination; list other party, type, direction, duration, date | ✅ When `authToken != null`, call history uses `CallSignalingService.getCallLog` and shows list; reuses `call_history_screen` (messages) / list in Call history tab | — |

**Verdict:** No gap (when authToken is provided).

---

## Phase 2 — Group Calls & Add Participant

| Step | Spec | Implemented | Gap |
|------|------|-------------|-----|
| 2.B.1–2.B.6 | Backend: group_id, participants, POST with group, add/leave, GET participants, optional SFU | — | Backend: not in Flutter scope. |
| 2.F.1 | Create group call (group_id + invited_user_ids) | ⚠️ API: `createGroupCall()` exists. No UI to start group call from group chat (select members → create). | **Gap:** No create-group-call UI. |
| 2.F.2 | Add participant button → POST participants; handle ParticipantAdded | ⚠️ Add button opens sheet, picks user, calls `addParticipant`. No handling of ParticipantAdded (no new peer/tile). | **Gap:** ParticipantAdded not handled; no multi-peer. |
| 2.F.3 | Group call UI: grid of tiles (stream/avatar, name, mute state) | ❌ ActiveCallScreen is 1:1 only (one remote stream). | **Gap:** No grid layout. |
| 2.F.4 | Leave vs End (POST leave vs POST end) | ✅ Leave button calls `leaveCall` then _cleanupAndPop; End calls endCall. | — |

**Verdict:** Partial. Add/Leave API + UI; no group call creation UI, no ParticipantAdded handling, no group grid. See features-not-implemented.md.

---

## Phase 3 — Screen Share & Pinch-Zoom

| Step | Spec | Implemented | Gap |
|------|------|-------------|-----|
| 3.F.1 | getDisplayMedia; add track; signal screen on/off | ✅ CallWebRTCService startScreenShare/stopScreenShare; ActiveCallScreen More → Share screen / Stop sharing; renegotiation via onSignalingOffer | — |
| 3.F.2 | Pinch-to-zoom on remote video | ✅ InteractiveViewer on main video | — |
| 3.F.2 (partial) | Double-tap focus on remote video (02 § 3.2) | ❌ | **Gap.** See features-not-implemented.md. |
| More: Switch camera (02 § 3.4) | Front/back camera switch | ❌ Not in More menu | **Gap.** |

**Verdict:** Screen share and pinch-zoom done; double-tap focus and switch camera not implemented.

---

## Phase 4 — Reactions, Raise Hand, Missed-Call, Scheduled

| Step | Spec | Implemented | Gap |
|------|------|-------------|-----|
| 4.F.1 | Send reaction; show incoming reaction as animation on tile | ⚠️ Send: emoji picker + sendReaction; channel parses CallReaction. No UI subscription to onCallReaction or animation on tile. | **Gap:** Incoming reaction not shown. |
| 4.F.2 | Raise hand; show hand icon on participant tile | ⚠️ Send: toggle + sendRaiseHand; channel parses RaiseHand. No UI subscription to onRaiseHand or hand icon on tile. | **Gap:** Hand icon not shown. |
| 4.F.3 | Missed-call voice message (record + POST) | ❌ | **Gap.** |
| 4.F.4 | Scheduled calls (API + Schedule UI + list + Start at time) | ❌ | **Gap.** |

**Verdict:** Send reaction/raise hand done; display of incoming reaction/hand and missed-call/scheduled not implemented. See features-not-implemented.md.

---

## Phase 5 — Push, Reconnect, Polish

| Step | Spec | Implemented | Gap |
|------|------|-------------|-----|
| 5.F.1 | Incoming-call push: show native UI; on accept open app and run **new** accept flow | ✅ FCM call_incoming → CallIncomingEvent → IncomingCallFlowScreen; accept/reject via CallSignalingService + authToken | — |
| 5.F.2 | ICE disconnected/failed → offer with iceRestart; re-exchange ICE; “Reconnecting…” | ✅ _iceReconnectListen + _channelSignalingForReconnect; createOfferIceRestart on Disconnected/Failed; “Reconnecting…” banner + status | — |
| 5.F.3 | Optional video effects | ❌ | Optional; see features-not-implemented.md. |

---

## File-level checklist (spec vs code)

| Spec path / area | Exists | Notes |
|-----------------|--------|-------|
| `lib/services/call_signaling_service.dart` | ✅ | New API (create, accept, reject, end, signaling, turn-credentials, getCallLog). |
| `lib/services/call_service.dart` | ✅ | **Unchanged;** old endpoints only. |
| `lib/calls/call_channel_service.dart` | ✅ | WS for private-call.{callId}. |
| `lib/calls/call_state.dart` | ✅ | ChangeNotifier state. |
| `lib/services/call_webrtc_service.dart` | ✅ | PC, getUserMedia, offer/answer/ICE, mute/camera, dispose, createOfferIceRestart. |
| `lib/screens/calls/outgoing_call_flow_screen.dart` | ✅ | New outgoing flow. |
| `lib/screens/calls/incoming_call_flow_screen.dart` | ✅ | New incoming UI + accept/reject; used from FCM when call_incoming. |
| `lib/screens/calls/active_call_screen.dart` | ✅ | Voice + video; speaker bound; PiP draggable; tap-to-swap; pinch-zoom; reconnect; screen share; reaction/raise hand (send). Gaps: no incoming reaction/hand display, no switch camera, no double-tap focus. |
| `lib/screens/calls/call_history_screen.dart` | ✅ | Old OutgoingCallScreen (polling). |
| `lib/screens/messages/callhistory_screen.dart` | ✅ | Uses getCallLog + OutgoingCallFlowScreen when authToken set. |
| FCM → incoming call | ✅ | CallIncomingEvent → IncomingCallFlowScreen + CallSignalingService; authToken from LocalStorageService. |
| Chat / Conversations → start call | ✅ | OutgoingCallFlowScreen when authToken exists; fallback to CallService when not. |

---

## Recommended next steps (priority)

See **[features-not-implemented.md](features-not-implemented.md)** for the full list. Summary:

1. **Persist auth token on login:** Call `LocalStorageService.saveAuthToken(token)` after login so FCM and new call flow use the new API.

2. **Align or deprecate CallService:** CallService still uses old endpoints; migrate or add “new API” path when token is present.

3. **Group call:** Create group call UI (from group chat, select members); handle ParticipantAdded; add group call grid layout (multi-participant tiles).

4. **Incoming reaction / raise hand display:** Subscribe to onCallReaction and onRaiseHand in ActiveCallScreen; show animation and hand icon on participant tile(s).

5. **Missed-call voice message and scheduled calls:** Implement per backend-requirements (04, 05).

---

*Back to [README.md](README.md) | [implementation-steps.md](implementation-steps.md) | [features-not-implemented.md](features-not-implemented.md)*
