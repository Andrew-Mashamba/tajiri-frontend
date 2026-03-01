# Video & Audio Calls — Implementation Steps (Detailed)

**Product:** Tajiri  
**Stack:** Flutter (this repo), Laravel (backend), Ubuntu + Nginx  
**Use with:** [implementation-plan.md](implementation-plan.md), [backend-requirements/](backend-requirements/README.md)

This document breaks the implementation plan into **concrete, ordered steps** with file paths and checkpoints. Follow in order; mark steps done as you go.

---

## Implementation status (Flutter)

| Step | Status | Notes |
|------|--------|--------|
| 0.F.1 | Done | `flutter_webrtc` added in pubspec.yaml |
| 0.F.2 | Done | Android: MODIFY_AUDIO_SETTINGS added |
| 0.F.3 | Done | iOS: mic/camera already in Info.plist |
| 0.F.4 | Done | `CallSignalingService.getTurnCredentials()` |
| 0.F.5 | Done | Auth token passed per request in signaling service |
| 1.F.1 | Done | `CallSignalingService`: create, accept, reject, end, getTurnCredentials, getCallLog (new API paths) |
| 1.F.2 | Done | `CallSignalingService.sendSignaling()` for offer/answer/ICE |
| 1.F.5–1.F.9 | Done | `CallWebRTCService`: initPeerConnection, getUserMedia, addLocalStreamToPeerConnection, createOffer, setRemoteOfferAndCreateAnswer, setRemoteAnswer, addIceCandidate, onRemoteStream, onIceCandidate, mute/camera, dispose |
| 1.F.3, 1.F.4 | Done | `CallChannelService` (private-call.{callId}, Reverb auth); `CallState` (ChangeNotifier) |
| 1.F.10–1.F.15 | Done | `OutgoingCallFlowScreen`, `IncomingCallFlowScreen`, `ActiveCallScreen` (voice/video UI), end call; call log uses `getCallLog` when authToken set |
| FCM incoming | Done | `call_incoming` → `CallIncomingEvent` from payload, open `IncomingCallFlowScreen` with authToken |
| Chat/Conv new flow | Done | When authToken present, use `OutgoingCallFlowScreen`; token from `LocalStorageService.getAuthToken()` |
| Speaker | Done | `Helper.setSpeakerphoneOn()` in ActiveCallScreen |
| Video polish | Done | Draggable PiP, tap-to-swap main/PiP, pinch-to-zoom (InteractiveViewer) |
| Reconnect | Done | ICE failure → iceRestart offer, send via signaling; "Reconnecting…" banner |
| 2.F.1–2.F.4 | Done | `createGroupCall`, `addParticipant`, `leaveCall`, `getParticipants`; Add sheet, Leave button |
| 3.F.1 | Done | Screen share: `startScreenShare`/`stopScreenShare` in webrtc; More → Share screen; renegotiation via offer/answer |
| 4.F.1–4.F.2 | Done | `sendReaction`, `sendRaiseHand`; More → Raise hand, Send reaction; `CallReactionEvent`, `RaiseHandEvent` in channel |

---

## How to use this doc

- **Backend steps** — Implement on the Laravel repo (server). Each step references the exact backend-requirements section.
- **Frontend steps** — Implement in this Flutter repo (`lib/`). Paths are relative to project root.
- **Checkpoint** — Verify the step before moving on.
- **Optional** — Can be deferred or skipped for MVP.

---

# Phase 0 — Foundation

## Backend (Laravel server)

| Step | Action | Details | Doc ref |
|------|--------|---------|--------|
| 0.B.1 | Ensure auth returns user id | Sanctum or session must provide `auth()->id()` for all call endpoints. | — |
| 0.B.2 | Define "can A call B" | Implement rule (e.g. friends, same group). Use in call create validation. | 01 § 1 |
| 0.B.3 | Install Laravel Reverb (or Soketi) | `composer require laravel/reverb`; configure in `.env`; run `php artisan reverb:install`. | 01 § 3 |
| 0.B.4 | Register private channel for calls | In `routes/channels.php`: channel `call.{callId}` (or `private-call.{callId}`) authorized if user is participant. | 01 § 3.2 |
| 0.B.5 | Install & configure Coturn | On Ubuntu: `apt install coturn`; configure realm, ports 3478; enable TURN REST API or shared secret. | 01 § 5 |
| 0.B.6 | TURN credentials in Laravel | Create service that generates short-lived TURN username/password (Coturn REST or HMAC). | 01 § 5.2 |

**Checkpoint:** Backend can authorize a private channel and return TURN credentials (endpoint can be added in Phase 1).

---

## Frontend (Flutter)

| Step | Action | File(s) | Checkpoint |
|------|--------|---------|------------|
| 0.F.1 | Add `flutter_webrtc` | `pubspec.yaml`: `flutter_webrtc: ^0.11.0` (or latest compatible). Run `flutter pub get`. | Build succeeds. |
| 0.F.2 | Android permissions | `android/app/src/main/AndroidManifest.xml`: `RECORD_AUDIO`, `CAMERA`, `INTERNET`, `MODIFY_AUDIO_SETTINGS`. `minSdkVersion` 21+. | — |
| 0.F.3 | iOS permissions | `ios/Runner/Info.plist`: `NSMicrophoneUsageDescription`, `NSCameraUsageDescription`. Optional: `UIBackgroundModes` → `voip`. | — |
| 0.F.4 | Call TURN credentials API | Add method in `CallService` or new `CallSignalingService`: GET `$baseUrl/calls/turn-credentials` with auth headers; parse `ice_servers` (urls, username, credential). | Returns list of RTCIceServer-compatible maps. |
| 0.F.5 | Auth token for API | Ensure `ApiConfig.authHeaders(token)` is used for all call endpoints; token from your auth storage (e.g. Hive, SharedPreferences). | — |

**Checkpoint:** App has WebRTC dependency; permissions set; can request TURN credentials with auth (once backend exposes endpoint).

---

# Phase 1 — P0: Core 1:1 Voice & Video

## Backend (Laravel)

| Step | Action | Details | Doc ref |
|------|--------|---------|--------|
| 1.B.1 | Migrations | Create `call_sessions` (id, caller_id, callee_id, group_id, type, status, started_at, ended_at, duration_seconds, timestamps) and `call_participants` (id, call_session_id, user_id, role, joined_at, left_at, timestamps). | 01 § 2 |
| 1.B.2 | Models | `CallSession`, `CallParticipant` with relationships and scope/helper `userIsParticipant($callId, $userId)`. | 01 § 2 |
| 1.B.3 | POST /api/calls | Create call: validate callee_id + type; create session + 2 participant rows; broadcast `CallIncoming` to callee; return call_id, status, ice_servers, created_at. | 01 § 4.1 |
| 1.B.4 | POST /api/calls/{id}/accept | Callee only; set status=connected, started_at, participant joined_at; broadcast `CallAccepted`; optional sdp_answer in body forwarded. | 01 § 4.2 |
| 1.B.5 | POST /api/calls/{id}/reject | Callee only; status=rejected; broadcast `CallRejected`. | 01 § 4.3 |
| 1.B.6 | POST /api/calls/{id}/end | Either party; status=ended, ended_at, duration_seconds; broadcast `CallEnded`. | 01 § 4.4 |
| 1.B.7 | POST /api/calls/{id}/signaling | Body: type (offer/answer/ice_candidate) + sdp or candidate; broadcast to other participant(s); exclude sender. | 01 § 4.5 |
| 1.B.8 | GET /api/calls/turn-credentials | Return ice_servers (STUN + TURN with short-lived creds). | 01 § 5 |
| 1.B.9 | GET /api/calls (call log) | Paginated list for auth user (caller or callee); include other_party, direction, duration, etc. | 01 § 4.6 |
| 1.B.10 | Ring timeout job | Optional: dispatch job with delay 45s on create; if still pending, set no_answer and broadcast CallEnded. | 01 § 6 |
| 1.B.11 | Rate limits | Create call 30/min; signaling 200/min per call per user. | 01 § 7 |

**Checkpoint:** Backend accepts create/accept/reject/end/signaling and returns responses per spec; WebSocket broadcasts to private channel.

---

## Frontend (Flutter)

| Step | Action | File(s) | Checkpoint |
|------|--------|---------|------------|
| 1.F.1 | Align CallService with new API | Use `POST /api/calls` (body: callee_id, type); `POST /api/calls/{id}/accept`, `reject`, `end`; auth header from token. Map response to existing `Call` model or extend with call_id (string), ice_servers. | CallService matches backend-requirements 01 § 4.1–4.4. |
| 1.F.2 | Call signaling over REST | Add `sendSignaling(callId, type, sdp | candidate)` → POST `/api/calls/$callId/signaling` with type + sdp or candidate. | Can send offer/answer/ICE via REST. |
| 1.F.3 | WebSocket for call channel | New service or extend existing: connect to Reverb (WSS), subscribe to `private-call.{callId}` (auth as per backend). Listen for CallIncoming, CallAccepted, CallRejected, CallEnded, SignalingOffer, SignalingAnswer, SignalingIceCandidate. | Receives events for a call. |
| 1.F.4 | Call state holder | Single place (e.g. ChangeNotifier or Riverpod) for: callId, status (pending/ringing/connected/ended), isCaller, remoteUser, type (voice/video), localStream, remoteStream, peerConnection. | UI can react to state. |
| 1.F.5 | WebRTC: create peer connection | Use TURN credentials from create/accept response; build RTCConfiguration; createPeerConnection(config). | PC created with iceServers. |
| 1.F.6 | WebRTC: get user media | For voice: audio only; for video: audio + video (facingMode user). Add tracks to PC. | localStream has tracks. |
| 1.F.7 | WebRTC: offer/answer | Caller: createOffer → setLocalDescription → send via signaling. Callee: on SignalingOffer → setRemoteDescription → createAnswer → setLocalDescription → send answer. | SDP exchange works. |
| 1.F.8 | WebRTC: ICE | On iceCandidate, send via signaling. On SignalingIceCandidate, addIceCandidate. | ICE exchange works. |
| 1.F.9 | WebRTC: remote stream | onTrack → set remoteStream; notify UI. Attach to RTCVideoRenderer for video; audio plays automatically. | Remote video/audio visible. |
| 1.F.10 | Outgoing call flow | Screen: pick user → request permissions → POST create → subscribe WS → create PC + offer → send offer → wait for answer/ICE → show connected UI. | Can place 1:1 call. |
| 1.F.11 | Incoming call flow | On CallIncoming (WS or push): show full-screen incoming UI (name, avatar, Accept/Decline). Accept → POST accept → subscribe → create PC → on offer set remote, create answer, send → bind streams. | Can receive and accept call. |
| 1.F.12 | Voice call UI | Per 02-ui-spec: header (name, status/timer), center avatar, bottom bar: Mute, Speaker, Add, End (red). Bind mute to audio track enable/disable; speaker to audio route. | Voice call screen matches spec. |
| 1.F.13 | Video call UI | Per 02-ui-spec: full-screen remote video, draggable self PiP (top-right), overlay (name, timer), bottom bar: Mute, Camera, End, Add, More. Bind camera to video track enable/disable. | Video call screen matches spec. |
| 1.F.14 | End call | On End tap: POST end, close PC, dispose renderers, clear state, pop to previous screen. On CallEnded from WS: same cleanup. | Call ends cleanly both sides. |
| 1.F.15 | Call log screen | GET /api/calls with pagination; show list (other party, type, direction, duration, date). Reuse or adapt `call_history_screen.dart`. | History displays. |

**Checkpoint:** User can start and receive 1:1 voice and video calls; mute/speaker/camera work; call appears in history.

---

# Phase 2 — Group Calls & Add Participant

## Backend

| Step | Action | Doc ref |
|------|--------|--------|
| 2.B.1 | Extend call_sessions | group_id, max_participants. Extend call_participants: invited_at. | 02 § 2 |
| 2.B.2 | POST /api/calls with group | Body: group_id, invited_user_ids[], type. Create session + participants; broadcast CallIncoming to each invitee. | 02 § 3 |
| 2.B.3 | POST /api/calls/{id}/participants | Body: user_id. Add participant row; broadcast ParticipantAdded to existing, CallIncoming to new user. | 02 § 5 |
| 2.B.4 | POST /api/calls/{id}/leave | Set left_at for user; broadcast ParticipantLeft; if last, end call and CallEnded. | 02 § 6 |
| 2.B.5 | GET /api/calls/{id}/participants | List participants with joined_at, left_at, user info. | 02 § 8 |
| 2.B.6 | (Optional) SFU | Create room on SFU; return sfu_room_id, sfu_url, sfu_token in accept/create. | 02 § 10 |

## Frontend

| Step | Action | File(s) |
|------|--------|---------|
| 2.F.1 | Create group call | When starting from group: select members → POST /api/calls with group_id + invited_user_ids. | CallService, start-call UI |
| 2.F.2 | Add participant button | In call screen: Add → pick contact → POST participants → handle ParticipantAdded; for 1:1-style mesh, new peer connection or SFU client. | call screen, CallService |
| 2.F.3 | Group call UI | Grid of participant tiles (≤4: 2×2; more: scroll). Each tile: remote stream or avatar, name, mute/speaker state. | new or existing group call screen |
| 2.F.4 | Leave vs End | Leave: POST leave, close own PC, pop. End (for all): POST end if caller; broadcast closes for everyone. | call screen |

---

# Phase 3 — Screen Share & Pinch-Zoom

## Backend

| Step | Action |
|------|--------|
| 3.B.1 | Optional: signaling flag for "screen" track type so remote can show screen in separate region. |

## Frontend

| Step | Action | File(s) |
|------|--------|---------|
| 3.F.1 | Screen share | getDisplayMedia (if available on platform); add track to PC or second PC; signal "screen on/off" so remote shows in layout. | video call screen, signaling |
| 3.F.2 | Pinch-to-zoom | GestureDetector on remote video: scale/zoom transform. | video call widget |

---

# Phase 4 — Reactions, Raise Hand, Missed-Call, Scheduled

## Backend

| Step | Action | Doc ref |
|------|--------|--------|
| 4.B.1 | POST /api/calls/{id}/reactions | Body: emoji. Broadcast CallReaction to others; rate limit. | 03 § 2 |
| 4.B.2 | POST /api/calls/{id}/raise-hand | Body: raised (bool). Update call_participants.hand_raised_at; broadcast RaiseHand. | 03 § 3 |
| 4.B.3 | GET participants include hand_raised | 03 § 3.4 |
| 4.B.4 | POST /api/calls/{id}/missed-call-voice-message | Multipart voice file; create message in conversation; type missed_call_voice. | 04 |
| 4.B.5 | scheduled_calls + scheduled_call_invitees tables | 05 § 2 |
| 4.B.6 | POST/GET/DELETE /api/scheduled-calls; POST start | 05 § 3 |
| 4.B.7 | Cron: reminder 5 min before scheduled_at | 05 § 4 |

## Frontend

| Step | Action |
|------|--------|
| 4.F.1 | Reactions button; send reaction; show incoming as animation on tile. |
| 4.F.2 | Raise hand toggle; show hand icon on participant tile. |
| 4.F.3 | After missed call: "Leave voice message" → record → upload to missed-call-voice-message. |
| 4.F.4 | Schedule call: pick time + invitees → POST scheduled-calls; list upcoming; at time, "Start" → POST start → join call. |

---

# Phase 5 — Push, Reconnect, Polish

## Backend

| Step | Action | Doc ref |
|------|--------|--------|
| 5.B.1 | Store device tokens; on create call send FCM/APNs to callee (call_id, caller_name, type). | 06 § 1 |
| 5.B.2 | Allow re-signaling (offer with iceRestart) for connected call; no extra endpoint. | 06 § 2 |
| 5.B.3 | Apply all rate limits from backend-requirements. | 06 § 3 |

## Frontend

| Step | Action |
|------|--------|
| 5.F.1 | Handle incoming-call push: show native UI; on accept open app and run accept flow. |
| 5.F.2 | On ICE disconnected/failed: create new offer (iceRestart), send via signaling, re-exchange ICE; show "Reconnecting…". |
| 5.F.3 | Optional: video effects (client-only). |

---

# File / module map (Flutter)

| Area | Suggested path |
|------|----------------|
| API / signaling | `lib/services/call_service.dart` (extend), `lib/services/call_signaling_service.dart` (new, WS + REST signaling) |
| WebRTC | `lib/services/call_webrtc_service.dart` or `lib/calls/webrtc_manager.dart` |
| State | `lib/calls/call_state.dart` or Provider/Riverpod notifier |
| Models | `lib/models/call_models.dart` (extend with ice_servers, call_id string) |
| Screens | `lib/screens/calls/` — incoming_call_screen, active_call_screen (voice + video), call_history_screen |
| Config | `lib/config/api_config.dart` (already has baseUrl, authHeaders) |

---

# Order of execution (summary)

1. **Phase 0** — Backend: auth, Reverb, channel auth, Coturn, TURN service. Frontend: flutter_webrtc, permissions, TURN API client.
2. **Phase 1** — Backend: migrations, all 1:1 REST + WebSocket. Frontend: API alignment, WS subscription, WebRTC flow, voice/video UI, call log.
3. **Phase 2** — Group calls and add participant (backend + frontend).
4. **Phase 3** — Screen share + pinch-zoom (frontend-focused).
5. **Phase 4** — Reactions, raise hand, missed-call message, scheduled calls.
6. **Phase 5** — Push, reconnect, rate limits.

---

*Back to [README.md](README.md) | [implementation-plan.md](implementation-plan.md)*
