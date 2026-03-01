# Video & Audio Calls — Full Implementation Plan

**Product:** Tajiri  
**Stack:** Flutter (frontend), Laravel (backend), Ubuntu + Nginx  
**Backend requirements:** See [backend-requirements/README.md](backend-requirements/README.md) — one document per feature area with detailed API, DB, WebSocket events, validation, and rate limits for backend developers to implement.

---

## 1. Overview

This plan breaks implementation into **phases** aligned with feature priority (P0 → P1 → P2 → P3). Each phase lists **features**, **frontend tasks**, **backend tasks**, and **dependencies**. Backend work is specified in detail in the `backend-requirements/` folder; this document gives the order and high-level tasks.

---

## 2. Phase 0 — Foundation (Do First)

Foundation work required before any call feature.

| # | Task | Owner | Description | Backend requirements |
|---|------|--------|-------------|----------------------|
| 0.1 | Auth & user context | Backend | Ensure Laravel has authenticated user (e.g. Sanctum), user ID, and a way to resolve "can user A call user B" (e.g. contacts table or chat membership). | N/A (existing auth) |
| 0.2 | WebSocket server | Backend | Install and configure Laravel Reverb (or Soketi) for real-time signaling; private channels; auth for channel subscription. | [01-call-signaling-and-turn.md](backend-requirements/01-call-signaling-and-turn.md) § WebSocket |
| 0.3 | TURN/STUN server | Backend/DevOps | Install Coturn on Ubuntu; configure realm and TURN REST API or shared secret; Nginx if needed. | [01-call-signaling-and-turn.md](backend-requirements/01-call-signaling-and-turn.md) § TURN |
| 0.4 | Flutter WebRTC + HTTP client | Frontend | Add `flutter_webrtc`, HTTP client, WebSocket client (or Echo); permissions (mic, camera). | — |

**Deliverables:** Auth in place; WebSocket server running; TURN credentials endpoint working; Flutter can open WebSocket and get TURN config.

---

## 3. Phase 1 — P0: Core 1:1 Voice & Video

**Features:** CC-1 (Call signaling), CC-2 (NAT traversal), CC-4 (Permissions), CC-5 (Call log), VC-1, VC-2, VC-3, VC-4, VC-9 (Voice: 1:1, E2EE, mute, speaker, quality), VD-1, VD-2, VD-3, VD-4, VD-8 (Video: 1:1, E2EE, camera toggle, PiP, adaptive quality).

| # | Task | Owner | Description | Backend requirements |
|---|------|--------|-------------|----------------------|
| 1.1 | Call session model & migrations | Backend | Create `call_sessions` and (optional for Phase 1) `call_participants` tables; model and relationships. | [01-call-signaling-and-turn.md](backend-requirements/01-call-signaling-and-turn.md) § Database |
| 1.2 | Create call (REST + broadcast) | Backend | `POST /api/calls`: validate caller/callee, create session, broadcast `CallIncoming` to callee, return `call_id` and TURN credentials. | [01-call-signaling-and-turn.md](backend-requirements/01-call-signaling-and-turn.md) § Create call |
| 1.3 | Accept / Reject call | Backend | `POST /api/calls/{id}/accept`, `POST /api/calls/{id}/reject`: only callee; update session; broadcast to caller. | [01-call-signaling-and-turn.md](backend-requirements/01-call-signaling-and-turn.md) § Accept / Reject |
| 1.4 | End call | Backend | `POST /api/calls/{id}/end`: either party; set `ended_at`, duration; broadcast `CallEnded`. | [01-call-signaling-and-turn.md](backend-requirements/01-call-signaling-and-turn.md) § End call |
| 1.5 | Signaling (SDP / ICE) | Backend | WebSocket or `POST /api/calls/{id}/signaling`: receive offer/answer/ICE from one peer, forward to other(s) in same call. | [01-call-signaling-and-turn.md](backend-requirements/01-call-signaling-and-turn.md) § Signaling |
| 1.6 | TURN credentials endpoint | Backend | `GET /api/calls/turn-credentials`: return ICE server list with short-lived TURN username/password. | [01-call-signaling-and-turn.md](backend-requirements/01-call-signaling-and-turn.md) § TURN credentials |
| 1.7 | Private channel authorization | Backend | Only caller and callee can subscribe to `private-call.{call_id}`. | [01-call-signaling-and-turn.md](backend-requirements/01-call-signaling-and-turn.md) § WebSocket |
| 1.8 | Flutter: Outgoing call flow | Frontend | UI to start call → POST create → subscribe channel → create peer connection → send offer → handle answer/ICE. | — |
| 1.9 | Flutter: Incoming call flow | Frontend | On `CallIncoming` (or push), show screen; Accept → POST accept → subscribe → send answer/ICE; Reject → POST reject. | — |
| 1.10 | Flutter: Voice call UI | Frontend | Layout: header, avatar, bottom bar (mute, speaker, end); bind mute/speaker to track and audio route. | 02-ui-specification-flutter.md |
| 1.11 | Flutter: Video call UI | Frontend | Layout: remote full-screen, self PiP, overlay, bottom bar (mute, camera, end); bind camera on/off. | 02-ui-specification-flutter.md |
| 1.12 | Call log (list/history) | Backend + Frontend | Backend: expose `GET /api/calls` or `/api/users/me/calls` with pagination. Frontend: show list. | [01-call-signaling-and-turn.md](backend-requirements/01-call-signaling-and-turn.md) § Call log |

**Deliverables:** User can start and receive 1:1 voice and video calls; mute, speaker, camera toggle work; call appears in history. No media stored on server.

---

## 4. Phase 2 — P1: Group Calls & Add Participant

**Features:** VC-5, VD-6 (Add participants), GC-1, GC-2, GC-4, GC-6 (Group voice/video, participant selection, grid, add/remove mid-call).

| # | Task | Owner | Description | Backend requirements |
|---|------|--------|-------------|----------------------|
| 2.1 | Group call model | Backend | Support `call_sessions` with multiple participants; `call_participants` with joined_at, left_at, role. Optional: `group_id` or `invited_user_ids` for "call from group". | [02-group-calls-and-participants.md](backend-requirements/02-group-calls-and-participants.md) § Database |
| 2.2 | Create group call / invite list | Backend | `POST /api/calls` with `participant_ids[]` or `group_id` + `invited_user_ids[]`; create session and participants; broadcast to all invited. | [02-group-calls-and-participants.md](backend-requirements/02-group-calls-and-participants.md) § Create group call |
| 2.3 | Add participant mid-call | Backend | `POST /api/calls/{id}/participants`: add user to existing session; broadcast `ParticipantAdded` to existing participants and `CallIncoming` to new participant. | [02-group-calls-and-participants.md](backend-requirements/02-group-calls-and-participants.md) § Add participant |
| 2.4 | Leave / remove participant | Backend | `POST /api/calls/{id}/leave` or `participants/{participant_id}/remove`; update left_at; broadcast so others know who left. | [02-group-calls-and-participants.md](backend-requirements/02-group-calls-and-participants.md) § Leave / remove |
| 2.5 | SFU room (optional) | Backend/DevOps | For >2 participants, create SFU room (e.g. mediasoup) and return `sfu_room_id` / `sfu_url` in accept or create response. | [02-group-calls-and-participants.md](backend-requirements/02-group-calls-and-participants.md) § SFU |
| 2.6 | Flutter: Add participant UI | Frontend | Button "Add" → pick contact or group members → call API; handle `ParticipantAdded` and new peer connection or SFU stream. | — |
| 2.7 | Flutter: Group call UI | Frontend | Grid/list of participants; speaker spotlight (from client-side or SFU dominant speaker); leave vs end-for-all. | 02-ui-specification-flutter.md |
| 2.8 | Flutter: Participant selection | Frontend | When starting from group chat, show member list to select who to invite (no ring-all). | — |

**Deliverables:** User can start a group call with selected participants; add/remove participants mid-call; group call UI shows all participants.

---

## 5. Phase 3 — P1: Screen Share & Quality

**Features:** VD-7 (Screen sharing), VD-5 (Pinch-to-zoom — frontend only).

| # | Task | Owner | Description | Backend requirements |
|---|------|--------|-------------|----------------------|
| 3.1 | Screen share signaling | Backend | Optional: new track type or flag in signaling so other peer knows "screen" vs "camera". May be client-only (second track in same PC). | [06-push-notifications-and-reconnect.md](backend-requirements/06-push-notifications-and-reconnect.md) or minimal in 01 |
| 3.2 | Flutter: Screen share | Frontend | Use getDisplayMedia (or platform channel); add track to peer connection; signal "screen on/off" so remote shows in correct layout. | — |
| 3.3 | Flutter: Pinch-to-zoom | Frontend | Gesture on remote video; no backend. | — |

**Deliverables:** User can share screen in video call; pinch-to-zoom on remote video.

---

## 6. Phase 4 — P2: Reactions, Raise Hand, Missed-Call, Scheduled

**Features:** VC-6, VD-9 (Call reactions), GC-5 (Raise hand), VC-7 (Missed-call messaging), VC-8 (Scheduled calls).

| # | Task | Owner | Description | Backend requirements |
|---|------|--------|-------------|----------------------|
| 4.1 | Call reactions | Backend | WebSocket: client sends `CallReaction` (emoji, call_id); server broadcasts to other participants in same call. Optional: throttle per user. | [03-call-reactions-and-raise-hand.md](backend-requirements/03-call-reactions-and-raise-hand.md) § Reactions |
| 4.2 | Raise hand | Backend | WebSocket: client sends `RaiseHand` (up/down); server broadcasts to others; optionally store in `call_participants.raised_hand_at`. | [03-call-reactions-and-raise-hand.md](backend-requirements/03-call-reactions-and-raise-hand.md) § Raise hand |
| 4.3 | Flutter: Reactions UI | Frontend | Button to pick emoji; send event; show incoming reaction as short animation on sender tile. | — |
| 4.4 | Flutter: Raise hand UI | Frontend | Toggle button; send event; show hand icon on participant tile. | — |
| 4.5 | Missed-call voice message | Backend | After call ends with "no answer", caller can POST voice message (e.g. multipart) to chat/conversation; store as message with type "missed_call_voice". | [04-missed-call-messaging.md](backend-requirements/04-missed-call-messaging.md) |
| 4.6 | Flutter: Missed-call message | Frontend | After missed call, show "Leave voice message"; record and upload; call messages API. | — |
| 4.7 | Scheduled calls model | Backend | New table `scheduled_calls` (or fields on `call_sessions`): scheduled_at, invitee_ids, reminder_sent_at. | [05-scheduled-calls.md](backend-requirements/05-scheduled-calls.md) § Database |
| 4.8 | Schedule call API | Backend | `POST /api/scheduled-calls`: create; notify invitees. `GET /api/scheduled-calls`: list upcoming. | [05-scheduled-calls.md](backend-requirements/05-scheduled-calls.md) § APIs |
| 4.9 | Reminder job | Backend | Cron: before scheduled_at (e.g. 5 min), send push or in-app notification "Call in 5 minutes"; mark reminder_sent_at. | [05-scheduled-calls.md](backend-requirements/05-scheduled-calls.md) § Reminders |
| 4.10 | Flutter: Schedule call UI | Frontend | "Schedule call" → pick time and participants → POST; show upcoming; at time, open call screen or prompt to start. | — |

**Deliverables:** Reactions and raise hand in calls; missed-call voice message in chat; scheduled calls with reminders.

---

## 7. Phase 5 — P2/P3: Push, Reconnect, Polish

**Features:** CC-3 (Reconnect), push notifications for incoming calls, VD-10 (Effects — frontend only if any).

| # | Task | Owner | Description | Backend requirements |
|---|------|--------|-------------|----------------------|
| 5.1 | Push for incoming call | Backend | On create call, send FCM/APNs to callee with call_id, caller name, type (voice/video). Store device tokens per user. | [06-push-notifications-and-reconnect.md](backend-requirements/06-push-notifications-and-reconnect.md) § Push |
| 5.2 | Flutter: Handle push | Frontend | On push, show native incoming-call UI; on accept open app and run accept flow. | — |
| 5.3 | Re-signaling / rejoin | Backend | Allow same user to send new offer (e.g. ICE restart) after disconnect; do not treat as new call. Idempotent signaling. | [06-push-notifications-and-reconnect.md](backend-requirements/06-push-notifications-and-reconnect.md) § Reconnect |
| 5.4 | Flutter: Reconnect | Frontend | On ICE disconnected/failed, create new offer with iceRestart; send via signaling; re-exchange ICE. | — |
| 5.5 | Rate limiting & abuse | Backend | Rate limit: create call (e.g. 30/min), signaling messages (e.g. 100/min per call). | All backend-requirements § Security |
| 5.6 | Effects (optional) | Frontend | Video effects/filters: client-only; no backend unless you store "preferred filter" in user settings. | — |

**Deliverables:** Incoming call push when app in background; reconnection without dropping call; rate limits in place.

---

## 8. Implementation order summary

| Phase | Focus | Backend docs |
|-------|--------|--------------|
| 0 | Foundation (WebSocket, TURN, Flutter deps) | 01 § WebSocket, TURN |
| 1 | 1:1 voice & video, signaling, call log | 01 (full) |
| 2 | Group calls, add/remove participants, SFU | 02 |
| 3 | Screen share, pinch-zoom | 01/06 (minimal) |
| 4 | Reactions, raise hand, missed-call message, scheduled calls | 03, 04, 05 |
| 5 | Push, reconnect, rate limits | 06 |

---

## 9. Dependency graph (high level)

```
Phase 0 (Foundation)
    → Phase 1 (1:1 calls)
    → Phase 2 (Group calls) [depends on 1]
    → Phase 3 (Screen share) [depends on 1]
Phase 1
    → Phase 4 (Reactions, missed-call, scheduled) [depends on 1]
    → Phase 5 (Push, reconnect) [depends on 1]
```

---

## 10. Backend requirements index

Each feature area has a dedicated backend requirements file for implementers:

| Document | Covers |
|----------|--------|
| [01-call-signaling-and-turn.md](backend-requirements/01-call-signaling-and-turn.md) | Create/accept/reject/end, SDP/ICE signaling, TURN credentials, call log, WebSocket channels |
| [02-group-calls-and-participants.md](backend-requirements/02-group-calls-and-participants.md) | Group call creation, participant selection, add/remove mid-call, SFU room |
| [03-call-reactions-and-raise-hand.md](backend-requirements/03-call-reactions-and-raise-hand.md) | Real-time reactions, raise hand broadcast |
| [04-missed-call-messaging.md](backend-requirements/04-missed-call-messaging.md) | Voice message after missed call (chat integration) |
| [05-scheduled-calls.md](backend-requirements/05-scheduled-calls.md) | Schedule, invitees, reminders (cron) |
| [06-push-notifications-and-reconnect.md](backend-requirements/06-push-notifications-and-reconnect.md) | FCM/APNs incoming call, re-signaling support, rate limits |

---

*Back to [README.md](README.md)*
