# Video & Audio Calls — Feature Specification

**Product:** Tajiri  
**Stack:** Flutter (frontend), Laravel (backend), Ubuntu + Nginx  
**Source:** `../VIDEO_AUDIO_CALLS.md`

---

## 1. Scope

This document defines the feature set for **voice** and **video** calling in Tajiri. It does not cover messaging, status, or channels unless they intersect with calls (e.g. missed-call messaging).

---

## 2. Voice call features

| ID | Feature | Description | Priority |
|----|---------|-------------|----------|
| VC-1 | **1:1 voice calls** | Initiate and receive one-to-one voice calls. | P0 |
| VC-2 | **End-to-end encryption** | All voice media encrypted; only caller and callee can decrypt. | P0 |
| VC-3 | **Mute microphone** | Toggle mute before answering or during call. | P0 |
| VC-4 | **Speaker / earpiece** | Switch audio output (speaker, earpiece, Bluetooth). | P0 |
| VC-5 | **Add participants** | Add more people to a 1:1 call to turn it into a group call. | P1 |
| VC-6 | **Call reactions** | Send emoji reactions (e.g. 👍, ❤️) during the call without muting. | P2 |
| VC-7 | **Missed-call messaging** | After a missed call, caller can leave a short voice message in chat. | P2 |
| VC-8 | **Scheduled calls** | Schedule a call and send invite; reminders before start. | P2 |
| VC-9 | **Audio quality** | Use Opus (or similar) codec; noise suppression, echo cancellation, stable under weak networks. | P0 |

---

## 3. Video call features

| ID | Feature | Description | Priority |
|----|---------|-------------|----------|
| VD-1 | **1:1 video calls** | Initiate and receive one-to-one video calls. | P0 |
| VD-2 | **End-to-end encryption** | All video (and audio) media encrypted end-to-end. | P0 |
| VD-3 | **Turn camera on/off** | Toggle local video before joining or during call. | P0 |
| VD-4 | **Self-view (PiP)** | Small, draggable self-preview (picture-in-picture). | P0 |
| VD-5 | **Pinch-to-zoom** | Pinch on remote video to zoom. | P1 |
| VD-6 | **Add participants** | Add participants to an ongoing video call (escalate to group). | P1 |
| VD-7 | **Screen sharing** | Share device screen (with optional audio) during video call. | P1 |
| VD-8 | **Adaptive quality** | Resolution/framerate adapt to network (e.g. 720p on Wi-Fi, lower on weak mobile). | P0 |
| VD-9 | **Emoji reactions** | Send emoji reactions during video call. | P2 |
| VD-10 | **Effects / filters** | Optional video effects (e.g. blur, stickers). | P3 |

---

## 4. Group call features

| ID | Feature | Description | Priority |
|----|---------|-------------|----------|
| GC-1 | **Group voice/video** | Support multi-participant voice and video calls (target: up to ~32). | P1 |
| GC-2 | **Participant selection** | When starting from a group, choose which members to invite (no full-group ring). | P1 |
| GC-3 | **Speaker spotlight** | Active speaker highlighted (larger tile or border). | P1 |
| GC-4 | **Grid layout** | Adaptive grid (e.g. 2×2 for ≤4, scrollable list for more). | P1 |
| GC-5 | **Raise hand** | Participant can raise hand; indicator on tile or in list. | P2 |
| GC-6 | **Add/remove mid-call** | Add or remove participants without ending the call. | P1 |

---

## 5. Cross-cutting features

| ID | Feature | Description | Priority |
|----|---------|-------------|----------|
| CC-1 | **Call signaling** | Laravel backend handles call setup, invite, ring, accept, reject, hangup. | P0 |
| CC-2 | **NAT traversal** | STUN/TURN for connectivity behind NAT/firewalls; media relay when P2P fails. | P0 |
| CC-3 | **Reconnect** | On network drop, attempt ICE restart / reconnection without dropping call. | P0 |
| CC-4 | **Permissions** | Request mic (voice) and camera (video) with clear rationale; respect user denial. | P0 |
| CC-5 | **Call log** | Store call metadata (who, when, duration, type) for history; no media stored. | P1 |

---

## 6. User stories (summary)

- **As a user**, I can start a voice or video call from a 1:1 or group chat so that I can talk in real time.
- **As a user**, I can mute my mic or turn off my camera so that I control what others see/hear.
- **As a user**, I can add someone to an ongoing call so that we don’t have to hang up and start a new call.
- **As a user**, I see who is speaking in group calls so that I can follow the conversation.
- **As a user**, I can share my screen during a video call so that I can present or get help.
- **As a user**, I get a reminder for scheduled calls so that I don’t miss them.
- **As a user**, I can leave a short voice message after a missed call so that the other person knows why I called.

---

## 7. Out of scope (for this spec)

- Third-party / federation interoperability.
- Guest users not on Tajiri.
- AI features (e.g. noise suppression is in-scope as standard DSP; AI assistants are not).
- Watch or other companion clients (can be added later).

---

## 8. Acceptance criteria (high level)

- Voice and video calls work on Flutter (iOS and Android) with Laravel as signaling backend.
- Media uses WebRTC; E2EE where specified; TURN/STUN and optional SFU on Ubuntu.
- UI follows the layouts and states described in `02-ui-specification-flutter.md`.
- Performance and security meet targets in `06-performance-targets.md` and `07-security-and-privacy.md`.

---

*Next: [02-ui-specification-flutter.md](02-ui-specification-flutter.md) | [03-architecture-overview.md](03-architecture-overview.md)*
