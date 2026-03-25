# CLAUDE.md

This file provides guidance to Claude Code (claude.ai/code) when working with code in this repository.

## Build & Run Commands

```bash
# Run the app (debug)
flutter run

# Build
flutter build apk          # Android
flutter build ios           # iOS

# Analyze code (lint)
flutter analyze

# Run all tests
flutter test

# Run a single test file
flutter test test/widget_test.dart

# Get dependencies
flutter pub get

# Ask the backend AI for changes (new endpoints, fields, etc.)
./scripts/ask_backend.sh "your prompt here"
```

## Architecture Overview

TAJIRI is a feature-rich social platform (Flutter/Dart, SDK ^3.10.1) with marketplace, messaging, music streaming, live streams, video calls, crowdfunding (Michango), and cloud file storage. The backend is a Laravel API configured at `lib/config/api_config.dart` — toggle between UAT (`zima-uat.site:8003`) and local (`127.0.0.1:1617`) by commenting/uncommenting.

### Code Organization

- **`lib/config/`** — API configuration (base URLs, auth headers, WebSocket config)
- **`lib/models/`** — Data models with `fromJson` factory constructors and type-safe parsing helpers
- **`lib/services/`** — API service layer (~53 files). Each feature has its own service (PostService, ShopService, MessageService, etc.)
- **`lib/screens/`** — Screen widgets organized by feature subdirectory (feed/, messages/, shop/, profile/, clips/, calls/, campaigns/, wallet/, streams/, groups/, events/, music/, registration/, settings/, etc.)
- **`lib/widgets/`** — Shared reusable widgets (post cards, video players, audio players, galleries)
- **`lib/l10n/`** — Bilingual strings (English + Swahili) via `AppStrings` class with `AppStringsScope` InheritedWidget
- **`lib/calls/`** — WebRTC call state management (ChangeNotifier-based)

### State Management

No external state management package (no Provider/Bloc/Riverpod). Uses:
- **Widget-level:** `setState()` in StatefulWidgets
- **Global state:** `ValueNotifier` singletons — `ThemeNotifier` (theme), `LanguageNotifier` (language), `CallState` (calls)
- **Persistence:** Hive via `LocalStorageService` singleton for auth tokens, user data, preferences

### Routing

Named routes defined in `lib/main.dart` with `onGenerateRoute` for dynamic parameters. Pattern: `/feature/:id` (e.g., `/profile/:userId`, `/post/:postId`, `/chat/:conversationId`). Routes use `FutureBuilder<int>` to resolve `currentUserId` from `LocalStorageService` before building screens.

### Networking

- `http` package for standard API calls; `Dio` for large file uploads (chunked, 10-min timeout)
- Bearer token auth stored in Hive, attached via `ApiConfig.authHeaders(token)`
- Backend URLs sanitized through `ApiConfig.sanitizeUrl()` to enforce HTTPS
- Model files include `_buildStorageUrl()` helper to resolve relative storage paths against `ApiConfig.storageUrl`

### Real-time Features

- **Firebase Firestore** listeners for live UI updates via `LiveUpdateService` — uses Dart sealed classes (`LiveUpdateEvent` subtypes: `FeedUpdateEvent`, `PostUpdateEvent`, `ProfileUpdateEvent`, `MessagesUpdateEvent`, etc.) as a notification channel; app refetches from REST API on change
- **Laravel Reverb** WebSocket for call signaling (config derived from `ApiConfig.baseUrl` or explicit `reverbWsUrl`)
- **WebRTC** (`flutter_webrtc` ^0.12.12) for voice/video calls
- **FCM** for push notifications with payload-based routing

### Internationalization

`AppStrings` class uses ternary getters: `isSwahili ? 'Swahili text' : 'English text'`. Access via `AppStringsScope.of(context)` from any widget. Language toggled via `LanguageNotifier`.

### Backend Communication

The backend exposes an AI Assistant Endpoint (`POST /api/ai/ask`) for requesting backend changes (new endpoints, fields, validation, response shape). Use `./scripts/ask_backend.sh "your prompt"` — see `docs/ASSISTANT_ENDPOINT_SKILL.md` and `docs/BACKEND_ASSISTANT_PROTOCOL.md`.

### Design System

`docs/DESIGN.md` is the single source of truth for all UI. Monochromatic palette (#1A1A1A dark, #FAFAFA light), Material 3, no colorful buttons. Key rules: SafeArea mandatory, 48dp minimum touch targets, `maxLines` + `TextOverflow.ellipsis` on all dynamic text, `_rounded` icon variants, dispose controllers.

## Key Conventions

- All models use `factory Model.fromJson(Map<String, dynamic> json)` with null-safe parsing helpers (`_parseInt`, `_parseDouble`, `_parseBool`) defined per model file
- Services are static-method classes (not instantiated), taking auth token as parameter
- Lint rules: `package:flutter_lints/flutter.yaml` (see `analysis_options.yaml`)
- `flutter_sound` has no macOS support — skip init on `Platform.isMacOS`

## Workflow Orchestration

### 1. Plan Mode Default
- Enter plan mode for ANY non-trivial task (3+ steps or architectural decisions)
- If something goes sideways, STOP and re-plan immediately
- Use plan mode for verification steps, not just building
- Write detailed specs upfront to reduce ambiguity

### 2. Subagent Strategy
- Use subagents liberally to keep main context window clean
- Offload research, exploration, and parallel analysis to subagents
- For complex problems, throw more compute at it via subagents
- One task per subagent for focused execution

### 3. Self-Improvement Loop
- After ANY correction from the user: update tasks/lessons.md with the pattern
- Write rules for yourself that prevent the same mistake
- Ruthlessly iterate on these lessons until mistake rate drops
- Review lessons at session start for relevant project

### 4. Verification Before Done
- Never mark a task complete without proving it works
- Diff behavior between main and your changes when relevant
- Ask yourself: "Would a staff engineer approve this?"
- Run tests, check logs, demonstrate correctness

### 5. Demand Elegance (Balanced)
- For non-trivial changes: pause and ask "is there a more elegant way?"
- If a fix feels hacky: "Knowing everything I know now, implement the elegant solution"
- Skip this for simple, obvious fixes — don't over-engineer
- Challenge your own work before presenting it

### 6. Autonomous Bug Fixing
- When given a bug report: just fix it. Don't ask for hand-holding
- Point at logs, errors, failing tests -> then resolve them
- Zero context switching required from the user
- Go fix failing CI tests without being told how

## Task Management

1. **Plan First:** Write plan to tasks/todo.md with checkable items
2. **Verify Plan:** Check in before starting implementation
3. **Track Progress:** Mark items complete as you go
4. **Explain Changes:** High-level summary at each step
5. **Document Results:** Add review section to tasks/todo.md
6. **Capture Lessons:** Update tasks/lessons.md after corrections

## Core Principles

- **Simplicity First:** Make every change as simple as possible. Impact minimal code.
- **No Laziness:** Find root causes. No temporary fixes. Senior developer standards.
- **Minimal Impact:** Only touch what's necessary. No side effects with new bugs.
