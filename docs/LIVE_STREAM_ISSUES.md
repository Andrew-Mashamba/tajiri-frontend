# Live stream / WebSocket log issues

Summary of what the logs mean and what to fix.

**Update (API guide):** The app now follows the Frontend API Guide for livestreams:
- **WebSocket:** Uses the URL and channel from the API (`response.websocket.url` and `response.websocket.channel`), e.g. `wss://zima-uat.site:8003/app/tajiri-reverb-key-2026` with Pusher protocol (subscribe to `stream.{id}`).
- **Join flow:** `POST /streams/{id}/join` is called first; on 200 we use `playback_url` and `websocket` from the response; on 404/409/410 we show "Stream not found", "Scheduled", or "Stream ended".
- **Playback:** Video uses `playback_url` from the join response (full absolute HLS URL). See `lib/services/websocket_service.dart` (`connectToPusher`), `lib/services/livestream_service.dart` (join, check, getStream), and `lib/screens/clips/streamviewer_screen.dart`.

---

## 1. WebSocket: "Connection was not upgraded to websocket"

**Log:**  
`WebSocketException: Connection to 'https://zima-uat.site:8003/streams/10?user_id=4#' was not upgraded to websocket`

**Meaning:**  
The client connects to `wss://zima-uat.site:8003/streams/10?user_id=4`, but the server never completes the WebSocket handshake (no `101 Switching Protocols`). The error sometimes shows `https://` and a trailing `#` (how the client or server reports the URL), but the real issue is: **the connection is not upgraded to WebSocket**.

**Likely causes (server-side):**

- No WebSocket endpoint at `GET /streams/:id` (or path differs).
- Server or reverse proxy strips the `Upgrade: websocket` header or blocks WebSocket.
- Server redirects `wss://` to `https://` (so you get an HTTP response instead of a WebSocket upgrade).
- Wrong port: WebSocket might need a different port than the REST API (e.g. 8003 for API, another for WS).

**What to do:**

- Confirm the backend exposes a WebSocket route (e.g. `/streams/:id` or `/ws/streams/:id`) and that it responds with `101 Switching Protocols` and the right `Sec-WebSocket-Accept` header.
- If WebSocket is on another path/port, add a dedicated `wsBaseUrl` in app config and use it only for WebSocket (see `lib/config/api_config.dart` and `lib/services/websocket_service.dart`).
- Check nginx/proxy config: ensure WebSocket upgrade is allowed for that path and port.

---

## 2. Duplicate "Connecting to WebSocket" (two connections for same stream)

**Log:**  
Two lines like `Connecting to WebSocket: wss://zima-uat.site:8003/streams/10?user_id=4` a few ms apart.

**Meaning:**  
`connectToStream(streamId, userId)` is being called more than once (e.g. two connection attempts for the same stream).

**Causes in the app:**

- `StreamViewerScreen` calls `_connectWebSocket()` in `initState` and also schedules a manual reconnect in the `connectionStream` listener (e.g. after 3s). The service already has its own reconnection timer, so both can fire.
- Widget/screen can be built twice (e.g. route or parent rebuild), so `initState` may run twice and trigger two connects.

**What we did in code:**

- WebSocket service: idempotent `connectToStream` – if already connected to the same `streamId`/`userId`, return without opening a new connection.
- Stream viewer screen: removed the extra delayed `connectToStream` from the `connectionStream` listener so only the service handles reconnection (no duplicate timers).

---

## 3. ExoPlayer: "Response code: 404"

**Log:**  
`HttpDataSource$InvalidResponseCodeException: Response code: 404`

**Meaning:**  
The playback URL (HLS or similar) that ExoPlayer requests returns HTTP 404. The stream file or manifest does not exist at that URL.

**Likely causes:**

- Backend returns a wrong or placeholder URL for the stream (e.g. wrong path, missing segment/manifest).
- Stream not started or already ended, so the URL is invalid.
- Storage/base URL misconfigured (e.g. wrong domain or path).

**What to do:**

- Log the exact URL passed to the player and check it in a browser or with `curl`.
- Ensure the backend only returns a playback URL when the stream is live and the HLS (or other) manifest/segments exist at that URL.
- If the stream is offline, the app should show an “offline” or “ended” state and not try to play the URL.

---

## 4. BLASTBufferQueue: "Can't acquire next buffer"

**Log:**  
`BLASTBufferQueue: ... acquireNextBufferLocked: Can't acquire next buffer. Already acquired max frames 4 max:2 + 2`

**Meaning:**  
Android graphics/surface queue issue: the video surface is trying to acquire more buffers than allowed. Often happens when the video player is in an error state (e.g. after 404), the surface is released, or the view is disposed while still drawing.

**What to do:**

- Treat as a side effect of the ExoPlayer 404 (or other playback error). Fixing the 404 and properly releasing/resetting the player on error usually reduces or removes these logs.
- On playback error, release the player and clear the surface (and don’t keep calling `prepare`/`play` on invalid URLs).

---

## 5. Session ended or no session — proper response (app-side)

**Scenario:**  
The user has ended their session, or there is no session but the user forgot to end it (e.g. still on stream viewer with stale `user_id`). The server may reject the WebSocket (no upgrade, 401, etc.) or the app may have an invalid/stale session.

**What the app does:**

1. **Before connecting (StreamViewerScreen)**  
   On open, the app checks session via `LocalStorageService`: `hasUser()`, `isLoggedIn()`, and that `getUser()?.userId == currentUserId`. If there is no valid session, it does **not** call the WebSocket or start playback. It shows a full-screen message: **“Muda wako umekwisha”** (Your session has ended) with **“Tafadhali ingia tena”** (Please log in again) and buttons **“Ingia tena”** (Log in again) and **“Rudi”** (Back).

2. **When connection fails (WebSocket or network)**  
   The app listens to `WebSocketService.connectionErrorStream`. On connection failure (e.g. “Connection was not upgraded to websocket”, or max reconnection reached), it shows a dialog that explains the problem and adds: **“Ikiwa muda wako umekwisha au umeondoka, tafadhali ingia tena.”** (If your session has ended or you logged out elsewhere, please log in again.) with actions **“Funga”** (Close) and **“Ingia tena”** (Log in again). Choosing **“Ingia tena”** disconnects the WebSocket, pops the stream viewer, and navigates to the login screen.

**Files touched:**

- `lib/services/websocket_service.dart`: added `connectionErrorStream`; on connect failure or max reconnect, emit a user-friendly error key (`connection_not_upgraded`, `session_invalid`, `max_reconnect_reached`, `connection_failed`) so the UI can show a proper response.
- `lib/screens/clips/streamviewer_screen.dart`: `_checkSessionAndStart()` validates session before any connect/play; `_buildSessionEndedBody()` for no/invalid session; `_showConnectionErrorResponse()` for connection errors with session hint and “Ingia tena” navigation.

**Summary:**  
If the user has ended session or there is no session, the app returns a **proper response**: no silent failure, no raw “not upgraded” without explanation. The user sees a clear message and can go back or log in again.

---

## Summary

| Issue | Where | Fix |
|-------|--------|-----|
| WebSocket not upgraded | Server / proxy | Implement or fix WebSocket endpoint and upgrade for `wss://.../streams/:id`. |
| Duplicate WebSocket connects | App | Idempotent `connectToStream`; only service reconnects (no extra reconnect in viewer screen). |
| ExoPlayer 404 | Backend / stream URL | Return valid playback URL only when stream is live; fix path/domain. |
| BLASTBufferQueue | App (player lifecycle) | Release/reset player on error; fix 404 first. |
| Session ended / no session | App | Validate session before connect; on connection error, show “session ended, please log in again” and “Ingia tena”. |
