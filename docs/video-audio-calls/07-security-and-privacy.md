# Video & Audio Calls — Security and Privacy

**Audience:** Backend, security, product  
**Source:** `../VIDEO_AUDIO_CALLS.md`

---

## 1. End-to-end encryption (E2EE)

- **Goal:** Only the participants can decrypt call media; the server (and TURN) should not have keys.
- **Approach:** Use WebRTC with DTLS-SRTP (standard for WebRTC). Keys are negotiated between peers (via SDP/signaling). Laravel only forwards encrypted SDP/ICE; it never has media keys.
- **TURN:** Relays encrypted packets; cannot decrypt if E2EE is done between endpoints.
- **Optional:** For stronger guarantees, add a second layer (e.g. Double Ratchet / Signal-style) on top of WebRTC; key exchange over signaling (Laravel still does not need to see keys).

---

## 2. Signaling security

- **Auth:** All signaling endpoints (REST and WebSocket) require authenticated user (e.g. Laravel Sanctum token or session).
- **Authorization:** Validate that the user is caller, callee, or invited participant for the given `call_id` before returning or forwarding any signaling data.
- **Integrity:** Use HTTPS and WSS only; avoid exposing SDP/ICE on unencrypted channels.
- **Rate limiting:** Limit call creation and signaling messages per user to reduce abuse and DoS.

---

## 3. TURN credentials

- **Short-lived:** Issue TURN username/password valid for the call duration or a few hours max (e.g. via TURN REST API or signed token).
- **Per-user or per-session:** Do not reuse long-lived shared credentials; revoke when call ends if possible.
- **Storage:** Laravel must not log TURN passwords; generate on demand and return in API response.

---

## 4. Privacy

- **No media storage:** Laravel (and your infrastructure) must not record or store audio/video. Only call metadata (who, when, duration, type) for call log and billing if needed.
- **Permissions:** Flutter must request microphone (and camera for video) with clear rationale; respect user denial and do not start the call without permission.
- **UI indicators:** Show camera/mic in-use indicator (system or in-app) so users know when they are exposed.
- **Optional:** Brief “Call is end-to-end encrypted” message or icon when call connects to set expectations.

---

## 5. Hardening (summary)

- **Certificate pinning:** In Flutter, pin backend and TURN TLS certificates in production to reduce MITM risk.
- **Replay protection:** Signaling messages should be bound to call session and (if possible) sequence or nonce so old SDP/ICE cannot be replayed.
- **No SDP/ICE logging:** Avoid logging full SDP or ICE candidates in production; use only for real-time forwarding.

---

*Back to [README.md](README.md)*
