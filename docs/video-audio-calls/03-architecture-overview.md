# Video & Audio Calls — Architecture Overview

**Audience:** All engineers (Flutter + Laravel)  
**Stack:** Flutter, Laravel, Ubuntu, Nginx, WebRTC, TURN/STUN, optional SFU  
**Source:** `../VIDEO_AUDIO_CALLS.md`

---

## 1. High-level architecture

```
┌─────────────────┐         Signaling (HTTPS/WSS)         ┌─────────────────┐
│  Flutter Client │ ◄────────────────────────────────────► │ Laravel Backend │
│  (iOS/Android)  │                                        │ (Ubuntu+Nginx)  │
└────────┬────────┘                                        └────────┬────────┘
         │                                                          │
         │ WebRTC (UDP)                                             │ Config / TURN
         │ (media: audio/video)                                     │ credentials
         ▼                                                          ▼
┌─────────────────┐                                        ┌─────────────────┐
│  Other peer(s)  │   OR   via TURN relay                   │ TURN/STUN       │
│  or SFU         │ ◄─────────────────────────────────────►│ (e.g. Coturn)   │
└─────────────────┘                                        └────────┬────────┘
                                                                    │
                                    Group calls (optional)          ▼
                                                           ┌─────────────────┐
                                                           │ SFU (e.g.       │
                                                           │ mediasoup/Node) │
                                                           └─────────────────┘
```

- **Signaling:** Flutter ↔ Laravel (REST + WebSockets or long polling).
- **Media:** Flutter ↔ peer(s) via WebRTC (UDP). If P2P fails, media goes via TURN.
- **Group calls:** Clients send to SFU; SFU forwards to other participants (optional phase).

---

## 2. Component roles

| Component | Role |
|-----------|------|
| **Flutter app** | UI, capture mic/camera, encode/decode, WebRTC peer connection, signaling client. |
| **Laravel** | Auth, call signaling (create/ring/accept/reject/end), push notifications, TURN credentials, optional SFU orchestration. |
| **Nginx** | Reverse proxy for Laravel, HTTPS, optional WSS upgrade for WebSockets. |
| **STUN/TURN (e.g. Coturn)** | NAT discovery (STUN) and media relay (TURN) when P2P fails. |
| **SFU (optional)** | For group calls: receive streams from clients, forward to others without decoding. |

---

## 3. Call flow (1:1 simplified)

1. **Caller (Flutter)** → Laravel: “Start call to user B” (with callee id).
2. **Laravel** → Callee: Push notification “Incoming call from A”; store pending call.
3. **Callee (Flutter)** → Laravel: “Accept” or “Reject”.
4. **Laravel** → Both: “Proceed with call” and e.g. room/session id; optionally TURN credentials.
5. **Both clients** exchange SDP and ICE candidates (via Laravel as signaling channel).
6. **WebRTC** establishes peer connection (P2P or via TURN); media flows directly (or via TURN).
7. **Hangup:** Either side sends “End” to Laravel; Laravel notifies the other; both close `RTCPeerConnection`.

---

## 4. Signaling (Laravel responsibilities)

- **REST/WebSocket events:** Create call, Ring, Accept, Reject, End, Add participant (group), ICE candidate, SDP offer/answer.
- **Auth:** Only authenticated users; caller and callee must be allowed to talk (e.g. contacts / same group).
- **State:** Track call state (pending, ringing, connected, ended) for the session.
- **No media:** Laravel never receives or stores audio/video; only signaling and metadata.

---

## 5. Media path

- **1:1:** Prefer P2P (UDP). If NAT/firewall blocks, use TURN (Coturn) relay. Media remains E2EE if implemented in the client.
- **Group:** Use SFU. Each client sends one stream to SFU and receives N−1 streams from SFU. SFU does not need to decrypt; encryption can be end-to-end between clients (with key exchange over signaling).

---

## 6. Deployment (Ubuntu + Nginx)

- **Laravel:** PHP-FPM behind Nginx; WebSocket server (e.g. Laravel Reverb, Soketi, or Redis + Socket.io) for real-time signaling.
- **Coturn:** Installed on same server or separate; Laravel generates short-lived TURN credentials via TURN REST API.
- **SFU:** Optional; e.g. Node.js (mediasoup) on same machine or separate; Laravel tells clients the SFU URL and room id.

---

## 7. Flutter ↔ Laravel contract (summary)

- **Flutter** sends: call request, accept/reject, end, SDP offer/answer, ICE candidates.
- **Laravel** sends: incoming call, call accepted/rejected/ended, SDP and ICE from peer, TURN credentials, SFU room info (if used).

Detailed API and WebSocket events belong in `04-backend-implementation-laravel.md` and `05-flutter-webrtc-implementation.md`.

---

*Next: [04-backend-implementation-laravel.md](04-backend-implementation-laravel.md) | [05-flutter-webrtc-implementation.md](05-flutter-webrtc-implementation.md)*
