# My Kikoba — VICOBA Integration Design

## Overview

Integrate the existing VICOBA savings group app (164 Dart files at `/Volumes/DATA/VICOBA/`) into TAJIRI as the "My Kikoba" module. Uses a **module drop-in** approach — copy VICOBA source into `lib/kikoba/` with an auth bridge, sharing TAJIRI's Firebase config.

## Architecture

**Strategy:** Module drop-in with auth bridge. VICOBA code lives self-contained in `lib/kikoba/`, keeping its own screens, models, services, and state. TAJIRI provides an entry point (profile tab "Kikoba") that launches the module, passing the current user's auth context.

**Backend:** VICOBA backend migrated to `https://vicoba.zimasystems.com/api` on the same server as TAJIRI (172.240.241.180). Separate MySQL database, separate user tables. TAJIRI users auto-register on VICOBA backend on first Kikoba access.

## Key Decisions

1. **Separate user databases** — TAJIRI (PostgreSQL) and VICOBA (MySQL) maintain independent user tables
2. **Seamless auto-registration** — When a TAJIRI user opens Kikoba for the first time, the app silently registers them on the VICOBA backend using their phone number, then caches the VICOBA auth credentials locally
3. **Share TAJIRI Firebase** — Remove VICOBA's `firebase_options.dart` and `Firebase.initializeApp()` call; use TAJIRI's existing Firebase instance
4. **Keep VICOBA chat** — VICOBA's Firebase Realtime DB chat stays as-is (separate from TAJIRI messaging)

## Module Structure

```
lib/kikoba/
├── kikoba_module.dart          # Entry point, auth bridge, module init
├── data_store.dart             # Adapted DataStore (bridges TAJIRI auth)
├── http_service.dart           # HttpService pointing to vicoba.zimasystems.com
├── offline_database.dart       # VICOBA SQLite (separate DB file)
├── models/
│   ├── vicoba.dart
│   ├── userx.dart
│   ├── voting_models.dart
│   ├── loan_models.dart
│   └── chat/
│       ├── chat_message.dart
│       ├── conversation.dart
│       ├── chat_participant.dart
│       ├── chat_models.dart
│       └── message_type.dart
├── services/
│   ├── fcm_service.dart
│   ├── firebase_chat_service.dart
│   ├── offline_chat_service.dart
│   ├── voting_firestore_service.dart
│   ├── offline_vote_queue.dart
│   ├── chat_notification_service.dart
│   ├── loan_service.dart
│   ├── riba_manager.dart
│   └── cache/
│       ├── vikoba_list_cache_service.dart
│       ├── dashboard_cache_service.dart
│       ├── baraza_cache_service.dart
│       ├── mahesabu_cache_service.dart
│       ├── katiba_cache_service.dart
│       ├── members_cache_service.dart
│       └── page_cache_service.dart
├── screens/
│   ├── tabs_home.dart          # Main Kikoba hub (5 tabs)
│   ├── vikoba_list.dart        # User's groups list
│   ├── dashboard_screen.dart
│   ├── members.dart
│   ├── baraza.dart
│   ├── katiba.dart
│   ├── mahesabu.dart
│   ├── majukumu.dart
│   ├── bank_transfer_screen.dart
│   ├── loan_request.dart
│   ├── loan_info.dart
│   ├── camera_screen.dart
│   └── ... (all other VICOBA screens)
├── pages/
│   ├── ada_page.dart
│   ├── hisa_page.dart
│   ├── akiba_page.dart
│   ├── mikopo_page.dart
│   ├── michango_page.dart
│   ├── uongozi_page.dart
│   ├── voting_list_screen.dart
│   ├── voting_detail_screens.dart
│   ├── chat_page.dart
│   ├── conversations_page.dart
│   ├── new_chat_screen.dart
│   ├── loan_detail_page.dart
│   ├── mchango_detail_page.dart
│   ├── my_loans_list_page.dart
│   └── udhamini_wa_mikopo.dart
└── widgets/
    └── ... (shared widgets from VICOBA)
```

## Auth Bridge

### Flow
1. User taps "Kikoba" tab on TAJIRI profile → `KikobaModule.launch(context, tajiriUser)`
2. Module checks local cache for VICOBA credentials
3. If not cached: auto-register on VICOBA backend via `POST /api/register-mobile` using TAJIRI phone number
4. Skip OTP (backend auto-confirms for TAJIRI-bridged registrations, or use a special bridge endpoint)
5. Cache VICOBA `userId` and session data in `OfflineDatabase`
6. Launch `VikobaListPage` as the module's home screen

### Bridge Endpoint (Backend)
Need a new backend endpoint: `POST /api/tajiri-bridge-login`
- Input: `{ phone: "255...", tajiri_user_id: 123 }`
- If user exists: return VICOBA user data
- If not: create user silently, return VICOBA user data
- Auth: shared secret between TAJIRI and VICOBA backends

## Firebase Sharing

### Changes Required
1. **Remove** VICOBA's `firebase_options.dart` — TAJIRI's Firebase is already initialized
2. **Remove** `Firebase.initializeApp()` from VICOBA's main.dart (handled by TAJIRI)
3. **Keep** anonymous `FirebaseAuth.signInAnonymously()` for VICOBA's storage access
4. **Keep** Firestore voting service as-is (uses VICOBA's Firestore collections)
5. **Keep** Realtime DB chat as-is
6. **Merge** FCM handling — VICOBA FCM topics subscribe alongside TAJIRI's FCM

### Firebase Project Decision
VICOBA currently uses Firebase project `vicoba-c89a7`. Since we're sharing TAJIRI's Firebase config:
- VICOBA's Firestore collections and Realtime DB paths must be prefixed to avoid collision (e.g., `vicoba_voting/`, `vicoba_chat/`)
- OR keep VICOBA on its own Firebase project by initializing a secondary Firebase app: `Firebase.initializeApp(name: 'vicoba', options: vicobaFirebaseOptions)`

**Recommendation:** Use secondary Firebase app to avoid data collision. TAJIRI Firebase handles auth/FCM/analytics; VICOBA secondary app handles Firestore voting and Realtime DB chat.

## API Service Changes

### HttpService Modifications
- Change `_baseUrl` from `https://zima-uat.site:8001/api/` to `https://vicoba.zimasystems.com/api/`
- Remove ESB base URL (not needed in TAJIRI context)
- Add auth token header management bridged from TAJIRI

## State Bridge

### DataStore Adaptation
- Remove `userPresent` check — always true when launched from TAJIRI
- Populate `currentUserId`, `currentUserName`, `userNumber` from TAJIRI user data
- Keep VICOBA-specific state (kikobaId, lists, payment state) as-is

## Profile Tab Integration

TAJIRI's `ProfileScreen` shows tabs configured via `ProfileTabConfig`. Add a "Kikoba" tab that renders the module:

```dart
case 'kikoba': return KikobaModule(userId: userId);
```

Backend should include `kikoba` in the user's `profile_tab_config` response.

## Dependencies

### New Dependencies (from VICOBA not in TAJIRI)
Check TAJIRI's `pubspec.yaml` against VICOBA's. Likely additions:
- `pin_code_fields` (OTP input — may not need if bridging auth)
- `steel_crypt` (encryption)
- `record` / `audioplayers` (voice messages in chat)
- `flutter_contacts` (contact import for invites)
- `in_app_update` (probably not needed)
- `passcode_screen` (PIN — may not need)
- `group_button` (UI widget)
- `emoji_picker_flutter` (chat emoji)
- `bubble` (chat bubbles)
- `bottom_navy_bar` (already using own navigation)

### Dependencies to Skip
- `firebase_auth` (TAJIRI already has it)
- `firebase_core` (already has it)
- `flutter_checkout_payment` (payment handled differently in TAJIRI)

## Migration Scope

### Phase 1: Core Module (This Implementation)
- Copy all VICOBA files into `lib/kikoba/`
- Fix all import paths
- Create auth bridge (`kikoba_module.dart`)
- Update `HttpService` base URL
- Remove duplicate `Firebase.initializeApp()`
- Wire into profile tab
- Test basic flow: open Kikoba → see groups list

### Phase 2: Polish (Future)
- Align VICOBA UI to TAJIRI design system
- Bridge VICOBA notifications into TAJIRI notification center
- Cross-link VICOBA contributions with TAJIRI Budget module
- Replace VICOBA camera with TAJIRI media picker

## Testing Strategy

1. **Auth bridge**: Verify TAJIRI user can silently register and access VICOBA
2. **Navigation**: Profile → Kikoba tab → VICOBA groups list → group detail → back to profile
3. **Firebase**: Verify voting and chat work on shared/secondary Firebase
4. **Offline**: Verify VICOBA's offline cache works alongside TAJIRI's
5. **No regression**: Verify TAJIRI features unaffected by VICOBA module

## Success Criteria

- TAJIRI user taps "Kikoba" tab and sees their VICOBA groups without any registration flow
- Can create a new Kikoba group, invite members, manage contributions
- Chat within Kikoba groups works
- Voting on loan applications works in real-time
- No interference with TAJIRI's existing features
