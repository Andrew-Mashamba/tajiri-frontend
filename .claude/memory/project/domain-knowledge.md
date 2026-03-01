# TAJIRI Domain Knowledge

## Platform Overview #domain

**Date**: 2026-01-28
**Context**: TAJIRI is a comprehensive social media platform for Tanzania

**What is TAJIRI**:
TAJIRI is a Flutter-based social networking platform incorporating features from industry-leading platforms: news feeds, stories, short-form videos (clips), livestreaming, messaging, music sharing, and social connections. Built specifically for the Tanzanian market with full Swahili language support and local payment integration (M-Pesa, Tigo Pesa, Airtel Money, Halo Pesa).

**Scale**: 116 core files (24 models, 59 screens, 33 services), 12 major features, sophisticated architecture with offline-first design.

**Key lesson**: TAJIRI combines the best features of major social platforms into one unified experience for the African market.
**Tags**: #platform #overview #social-media

---

## Michango (Crowdfunding) #domain

**Date**: 2026-01-28
**Context**: Unique TAJIRI feature - integrated crowdfunding system

**What is Michango**:
"Michango" (Swahili for contributions/fundraising) is a GoFundMe-like crowdfunding system built directly into the TAJIRI social feed. Users can create campaigns, donate anonymously, track progress, and withdraw funds through mobile money.

**Features**:
- 11 campaign categories: Afya (medical), Elimu (education), Dharura (emergency), Mazishi (funeral), Harusi (wedding), Biashara (business), Jamii (community), Dini (religious), Michezo (sports), Sanaa (arts), Mazingira (environment)
- KYC verification for organizers
- Mobile money integration (4 providers)
- Anonymous donation support
- Campaign updates and donor tracking
- Withdrawal requests with banking details
- TZS currency (Tanzanian Shillings)

**Key lesson**: Michango is a core TAJIRI differentiator - social crowdfunding for the Tanzanian community.
**Files**: `lib/models/contribution_models.dart`, `lib/services/contribution_service.dart`, `lib/widgets/michango_gallery_widget.dart`
**Tags**: #michango #crowdfunding #unique-feature #domain

---

## Swahili Terminology #domain

**Date**: 2026-01-28
**Context**: UI uses Swahili terms for better local user experience

**Terms used**:
- Wasifu = Profile
- Marafiki = Friends
- Ujumbe = Messages
- Picha = Photos
- Habari = News/Feed
- Hadithi = Stories
- Simu = Calls
- Muziki = Music
- Mubashara = Livestream
- Makundi = Groups
- Kurasa = Pages
- Tukio = Event
- Mipangilio = Settings

**Key lesson**: Always use Swahili terms in UI for consistency with platform branding.
**Tags**: #swahili #terminology #ui

---

## Core Features #domain

**Date**: 2026-01-28
**Context**: TAJIRI's main feature set

**Features**:
1. **Feed (Habari)** - Algorithmic news feed with posts, photos, videos
2. **Stories (Hadithi)** - 24-hour ephemeral content
3. **Clips** - Short-form vertical videos (TikTok-style)
4. **Messages (Ujumbe)** - Real-time chat and conversations
5. **Friends (Marafiki)** - Social connections and friend requests
6. **Photos (Picha)** - Photo galleries and albums
7. **Music (Muziki)** - Music sharing and playback
8. **Livestream (Mubashara)** - Live video broadcasting
9. **Groups (Makundi)** - Community groups
10. **Pages (Kurasa)** - Business/celebrity pages
11. **Calls (Simu)** - Voice/video calling
12. **Events (Matukio)** - Event creation and management

**Key lesson**: TAJIRI is a full-featured social platform, not just a simple app.
**Tags**: #features #platform

---

## Data Models #domain

**Date**: 2026-01-28
**Context**: Core data structures in `lib/models/`

**Key models**:
- `user_models.dart` - User profiles and authentication
- `post_models.dart` - Feed posts and content
- `story_models.dart` - Stories/ephemeral content
- `clip_models.dart` - Short-form videos
- `message_models.dart` - Chat messages
- `conversation_models.dart` - Chat conversations
- `photo_models.dart` - Photo albums and images
- `music_models.dart` - Music tracks and playlists
- `livestream_models.dart` - Live broadcasts
- `group_models.dart` - Groups and membership
- `page_models.dart` - Business pages
- `event_models.dart` - Events
- `notification_models.dart` - Push notifications
- `comment_models.dart` - Post comments
- `draft_models.dart` - Draft content

**Key lesson**: Each major feature has its own model file with comprehensive data structure.
**Tags**: #models #architecture #data

---

## Services Architecture #domain

**Date**: 2026-01-28
**Context**: Business logic in `lib/services/`

**Key services**:
- `api_service.dart` - HTTP API client
- `local_storage_service.dart` - Hive-based local storage
- `auth_service.dart` - Authentication and session
- `feed_service.dart` - Feed data fetching
- `message_service.dart` - Real-time messaging
- `media_service.dart` - Photo/video upload
- `notification_service.dart` - Push notifications
- `sync_service.dart` - Offline sync
- `cache_service.dart` - Data caching

**Key lesson**: Services handle all business logic separate from UI.
**Tags**: #services #architecture #separation

---

## Storage Strategy #domain

**Date**: 2026-01-28
**Context**: Local data persistence using Hive

**Storage approach**:
- Hive for local database (NoSQL key-value store)
- `LocalStorageService` wrapper class
- Caches API responses for offline access
- Stores user session and preferences
- Offline queue for pending actions

**Key lesson**: TAJIRI is offline-first - all features work without internet, sync when connected.
**Tags**: #storage #hive #offline

---

## Navigation Pattern #domain

**Date**: 2026-01-28
**Context**: Routing configuration in `main.dart`

**Pattern**:
Uses MaterialApp's `onGenerateRoute` for dynamic routing. Route patterns like `/home`, `/feed`, `/create-post`, `/chat/123`, `/profile/456`. All routes check for currentUserId via LocalStorageService before rendering.

**Key lesson**: Always get currentUserId from LocalStorageService, never hardcode user IDs.
**Files**: `lib/main.dart`
**Tags**: #navigation #routing #pattern

---

## Theme Configuration #domain

**Date**: 2026-01-28
**Context**: Material 3 design system

**Theme details**:
- Primary color: `Color(0xFF1E88E5)` (Blue)
- Material 3 with `useMaterial3: true`
- Border radius: 12px standard
- Input padding: 16px horizontal and vertical
- Spacing: Multiples of 8px

**Key lesson**: Maintain consistent theming across all screens using these values.
**Tags**: #theme #design #material3

---

## Screen Structure #domain

**Date**: 2026-01-28
**Context**: UI screens in `lib/screens/`

**Organization**:
Screens organized by feature in subdirectories:
- `screens/home/` - Home and dashboard
- `screens/feed/` - News feed and post creation
- `screens/messages/` - Chat and conversations
- `screens/friends/` - Friend list and requests
- `screens/photos/` - Photo galleries
- `screens/music/` - Music player and library
- `screens/calls/` - Call history
- `screens/settings/` - App settings
- `screens/splash/` - Splash screen
- `screens/registration/` - Auth and onboarding

**Key lesson**: Group related screens in feature directories for maintainability.
**Tags**: #screens #organization #structure