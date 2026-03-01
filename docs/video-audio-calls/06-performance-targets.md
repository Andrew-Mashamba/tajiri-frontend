# Video & Audio Calls — Performance Targets

**Audience:** All engineers, DevOps  
**Source:** `../VIDEO_AUDIO_CALLS.md`

---

## 1. Latency

| Metric | Voice | Video |
|--------|--------|--------|
| **Call setup (signaling)** | &lt; 2 s | 2–4 s |
| **End-to-end media latency** | 150–400 ms | 200–500 ms |

- **Signaling:** Laravel + WebSocket should respond and deliver events in &lt; 500 ms under normal load.
- **Media:** Dominated by network and codec; aim for &lt; 400 ms one-way for voice, &lt; 500 ms for video when possible.

---

## 2. Bandwidth and data usage

| Metric | Voice | Video |
|--------|--------|--------|
| **Min bandwidth** | ~20 kbps | ~150 kbps |
| **Typical usage** | ~300 KB/min | 3–7 MB/min |

- Design for **weak networks:** voice should remain usable on 2G-like conditions; video should degrade (resolution/framerate) instead of freezing.
- **Adaptive bitrate:** Reduce resolution/framerate on congestion; prefer continuity over max quality.

---

## 3. Reliability

- **Reconnection:** On temporary network drop, attempt ICE restart and resume call within a few seconds instead of dropping.
- **TURN fallback:** When P2P fails (NAT/firewall), media should switch to TURN relay without user action.
- **Signaling:** WebSocket reconnect with exponential backoff; re-subscribe to call channel and resync state.

---

## 4. Scalability (backend)

- **Laravel:** Stateless signaling; scale horizontally behind Nginx/load balancer.
- **TURN (Coturn):** Scale by adding more TURN servers; Laravel returns different ICE servers per region or load.
- **SFU (group):** One SFU instance can handle many rooms; scale by adding SFU nodes and routing rooms across them.

---

## 5. Device and platform

- **Flutter:** Support iOS and Android with min SDK versions that support WebRTC (e.g. Android 21+, iOS 12+).
- **Battery:** Prefer hardware codecs and efficient encoding to limit CPU and battery drain during long calls.

---

## 6. Monitoring (suggested)

- **Signaling:** Latency and error rate for REST and WebSocket; call success rate (created → connected).
- **TURN:** Relay usage and latency per region.
- **Client (optional):** Report one-way delay or round-trip if available from WebRTC stats; use for SLO dashboards.

---

*Next: [07-security-and-privacy.md](07-security-and-privacy.md)*
