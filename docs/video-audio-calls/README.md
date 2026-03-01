# Video & Audio Calls — Generated Documentation

This folder contains documentation for implementing WhatsApp-style voice and video calling in **Tajiri**, derived from `../VIDEO_AUDIO_CALLS.md`.

## Tech stack

| Layer        | Technology |
|-------------|------------|
| **Frontend** | Flutter (this repo) |
| **Backend**  | Laravel (Ubuntu server) |
| **Web server** | Nginx |
| **Media**    | WebRTC (clients), TURN/STUN + SFU (server-side as needed) |

You can install any additional programs on the Ubuntu server (e.g. Coturn, Node.js for SFU).

---

## Documents in this folder

| # | Document | Audience | Description |
|---|----------|----------|-------------|
| 1 | [01-feature-specification.md](01-feature-specification.md) | Product, QA | Scope, user stories, and acceptance criteria for voice/video calls |
| 2 | [02-ui-specification-flutter.md](02-ui-specification-flutter.md) | Flutter devs, Design | Layouts, components, states, gestures for Flutter UI |
| 3 | [03-architecture-overview.md](03-architecture-overview.md) | All engineers | End-to-end architecture: Flutter ↔ Laravel ↔ WebRTC/TURN/SFU |
| 4 | [04-backend-implementation-laravel.md](04-backend-implementation-laravel.md) | Backend (Laravel) | Signaling API, storage, TURN/SFU deployment on Ubuntu/Nginx |
| 5 | [05-flutter-webrtc-implementation.md](05-flutter-webrtc-implementation.md) | Flutter devs | Implementing calls in Flutter with Laravel signaling |
| 6 | [06-performance-targets.md](06-performance-targets.md) | All engineers, DevOps | Latency, bandwidth, and reliability targets |
| 7 | [07-security-and-privacy.md](07-security-and-privacy.md) | Backend, Security | E2EE, permissions, and privacy considerations |
| — | [implementation-plan.md](implementation-plan.md) | All | Full implementation plan by phase (P0→P3) with tasks and dependencies |
| — | [implementation-steps.md](implementation-steps.md) | All | **Step-by-step implementation:** ordered tasks with file paths and status |
| — | [gap-analysis.md](gap-analysis.md) | All | **Spec vs implementation:** what is done, partial, or missing (Phases 0–5) |
| — | [backend-directive.md](backend-directive.md) | **Backend (Laravel)** | **Directive for backend:** single source of truth for REST, WebSocket, FCM contracts so Flutter app works end-to-end |
| — | [backend-requirements/](backend-requirements/README.md) | Backend (Laravel) | **Detailed backend specs per feature:** API, DB, WebSocket, validation, rate limits |

---

## Suggested reading order

1. **01-feature-specification.md** — Agree on scope.
2. **03-architecture-overview.md** — Understand the full system.
3. **02-ui-specification-flutter.md** + **05-flutter-webrtc-implementation.md** — Frontend implementation.
4. **implementation-plan.md** — Phases and task order; then **backend-requirements/** for each feature’s backend spec.
5. **04-backend-implementation-laravel.md** — Backend and server setup.
6. **06-performance-targets.md** + **07-security-and-privacy.md** — Non-functional requirements.

Source: `../VIDEO_AUDIO_CALLS.md`.
