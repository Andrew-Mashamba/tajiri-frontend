# Video & Audio Calls — Backend Implementation (Laravel)

**Audience:** Backend developers  
**Stack:** Laravel on Ubuntu, Nginx, optional Coturn (TURN/STUN), optional SFU  
**Source:** `../VIDEO_AUDIO_CALLS.md`

---

## 1. Responsibilities

- **Call signaling:** Create, ring, accept, reject, end, add participant.
- **Auth & authorization:** Ensure caller and callee are allowed to call (e.g. contacts, same group).
- **TURN credentials:** Issue short-lived credentials for Coturn (or other TURN server).
- **Real-time delivery:** WebSockets or long polling so clients get signaling events instantly.
- **Call metadata:** Store call log (who, when, duration, type); no media storage.

---

## 2. Suggested Laravel structure

```
app/
  Http/Controllers/Api/
    CallSignalingController.php   # REST: create call, accept, reject, end
  Services/
    CallSignalingService.php      # Business logic
    TurnCredentialsService.php    # TURN REST API
  Events/
    CallIncoming.php
    CallAccepted.php
    CallRejected.php
    CallEnded.php
    CallSignaling.php             # SDP / ICE exchange
  Models/
    CallSession.php
    CallParticipant.php
database/migrations/
  create_call_sessions_table.php
  create_call_participants_table.php
routes/
  api.php                         # REST routes
  channels.php                    # WebSocket channels
```

---

## 3. REST API (summary)

| Method | Endpoint | Purpose |
|--------|----------|---------|
| POST | `/api/calls` | Create call (caller → callee); returns `call_id`, optional TURN credentials |
| POST | `/api/calls/{id}/accept` | Callee accepts; body may include SDP answer |
| POST | `/api/calls/{id}/reject` | Callee rejects |
| POST | `/api/calls/{id}/end` | Either party ends call |
| POST | `/api/calls/{id}/signaling` | Send SDP offer/answer or ICE candidate (or use WebSocket) |
| POST | `/api/calls/{id}/participants` | Add participant (group) |
| GET | `/api/calls/turn-credentials` | Get TURN credentials (short-lived) |

All under auth middleware (`sanctum` or session). Validate that the user is caller or callee (or invited participant) for that `call_id`.

---

## 4. WebSocket events (recommended)

Use Laravel Reverb, Soketi, or Redis + Laravel Echo so Flutter can subscribe to private channels.

**Channels:**

- `private-call.{call_id}` — only participants join.

**Events (server → client):**

- `CallIncoming` — callee: caller info, call_id, voice/video.
- `CallAccepted` — caller: callee joined, optional SDP/ICE from callee.
- `CallRejected` — caller: callee rejected.
- `CallEnded` — other side ended or left.
- `SignalingOffer` / `SignalingAnswer` / `SignalingIceCandidate` — SDP and ICE from peer.
- `ParticipantAdded` — new participant joined (group).

**Client → server:**

- Same events in reverse: accept, reject, end, SDP, ICE, add participant. Emit to `private-call.{call_id}` so the other participant(s) receive them.

---

## 5. Database (calls metadata only)

**call_sessions**

- id, caller_id, callee_id (or group_id for group), type (voice/video), status (pending/ringing/connected/ended), started_at, ended_at, duration_seconds.

**call_participants** (for group)

- id, call_session_id, user_id, joined_at, left_at, role.

No tables for media or recording; only signaling and call log.

---

## 6. TURN server (Coturn) on Ubuntu

**Install:**

```bash
sudo apt update
sudo apt install coturn
```

**Enable and configure** (e.g. `/etc/turnserver.conf`):

- Listening ports (e.g. 3478 UDP/TCP for TURN/STUN).
- Realm and TURN REST API for temporary credentials.
- Laravel calls TURN REST API (or uses shared secret) to generate username/password valid for 1–24 hours.

**Laravel:** Expose an endpoint that returns ICE servers list, e.g.:

```json
{
  "iceServers": [
    { "urls": "stun:your-domain.com:3478" },
    {
      "urls": "turn:your-domain.com:3478",
      "username": "generated",
      "credential": "generated"
    }
  ]
}
```

Flutter uses this in `RTCConfiguration` for `RTCPeerConnection`.

---

## 7. Nginx

- Proxy `/api` and WebSocket upgrade (e.g. `/reverb`) to Laravel.
- HTTPS required for production (WebRTC often requires secure context).
- Optional: separate server block or upstream for Coturn if on same host.

---

## 8. Group calls and SFU (optional)

For >2 participants, use an SFU (e.g. mediasoup, Janus, or a managed service). Laravel:

- Creates a “room” on the SFU (via SFU admin API or your own Node service).
- Returns room id and SFU URL/ws to clients in “accept” or “create group call” response.
- Flutter connects to SFU and joins the room; media goes Flutter ↔ SFU ↔ Flutter(s).

SFU can run on the same Ubuntu server or a separate one; Nginx can proxy to it.

---

## 9. Push notifications

For incoming calls when app is in background:

- Laravel triggers push via FCM (Firebase) / APNs using device tokens stored per user.
- Payload: call_id, caller name, type (voice/video), so Flutter can show native “Incoming call” UI and open the app to the call screen.

---

## 10. Security checklist

- All signaling endpoints require authentication.
- Validate caller/callee relationship (e.g. both in same group or contacts).
- Rate limit call creation and signaling to avoid abuse.
- TURN credentials short-lived and scoped to user/session.
- Do not log or store SDP/ICE content long-term; use only for real-time forwarding.

---

*Next: [05-flutter-webrtc-implementation.md](05-flutter-webrtc-implementation.md) | [07-security-and-privacy.md](07-security-and-privacy.md)*
