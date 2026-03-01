# TAJIRI Skills Summary

Updated: 2026-01-28

## Overview

This document summarizes all Claude Code skills configured for the TAJIRI platform, including their triggers and purposes.

## Active Skills

### 1. tajiri-platform
**Purpose**: Core social platform patterns and implementations
**Triggers**:
- TAJIRI, Tajiri
- feed, habari
- stories, hadithi
- posts, maandishi
- clips, reels, shorts
- livestream, mubashara
- messages, ujumbe
- friends, marafiki
- photos, picha
- music, muziki
- groups, makundi
- pages, kurasa
- events, matukio
- polls, kura
- michango, crowdfunding, contributions
- wallet, pochi
- engagement, reactions, penda, upendo
- comments, shares
- algorithmic ranking, trending, viral score

**Key Features**:
- Feed system with algorithmic ranking
- Stories & ephemeral content
- Short-form videos (clips)
- Real-time messaging
- Engagement mechanisms
- Content creation workflows
- User discovery
- Notifications
- Live streaming
- Media handling
- "Michango" crowdfunding system

---

### 2. flutter-expert
**Purpose**: Flutter and Dart development expertise
**Triggers**:
- Flutter, Dart
- widget, StatefulWidget, StatelessWidget
- video_player, chewie
- audioplayers, just_audio, audio_service
- cached_network_image
- image_picker, file_picker
- permission_handler
- visibility_detector
- MaterialApp
- navigation, routing
- performance, optimization
- build method, setState

**Key Features**:
- Widget development and patterns
- State management
- Navigation and routing
- Media playback (audio/video)
- Image handling and caching
- Permissions management
- Performance optimization

---

### 3. mobile-offline-support
**Purpose**: Offline-first architecture and data sync
**Triggers**:
- offline, offline-first
- cache, caching
- local storage, Hive, LocalStorageService
- sync, background sync
- resumable upload
- media cache, audio cache, video cache
- flutter_cache_manager
- no internet, connectivity
- queue, pending actions

**Key Features**:
- Hive-based local storage
- Media caching strategies
- Resumable uploads
- Background synchronization
- Offline queue management
- Connectivity handling

---

### 4. design-guidelines
**Purpose**: TAJIRI UI/UX design system
**Triggers**:
- design, UI, theme
- Material 3
- colors, styling, layout
- Swahili
- typography, spacing
- components, buttons, cards, forms

**Key Features**:
- Material 3 design system
- Primary color: #1E88E5 (Blue)
- 12px border radius standard
- Swahili UI terminology
- Consistent spacing (multiples of 8px)
- Accessibility guidelines

**Swahili UI Terms**:
- Nyumbani (Home), Habari (Feed)
- Marafiki (Friends), Ujumbe (Messages)
- Picha (Photos), Muziki (Music)
- Wasifu (Profile), Mipangilio (Settings)

---

### 5. session-memory
**Purpose**: Session context restoration
**Triggers**:
- session start
- restore context
- checkpoint
- remember
- previous session
- what was I doing
- continue work
- session state

**Key Features**:
- Automatic context restoration
- Session checkpoints
- Progress tracking
- Active task recovery

---

### 6. project-memory-store
**Purpose**: Long-term project knowledge storage
**Triggers**:
- learn
- remember this
- save pattern
- store insight
- project-store
- lesson learned
- important pattern
- remember pattern
- save knowledge

**Key Features**:
- Pattern recognition and storage
- Domain knowledge capture
- Success/failure tracking
- Architecture decisions

---

## How Skills Work

### Automatic Activation
Skills are automatically considered when conversation keywords match the triggers. For example:
- Mention "feed" or "habari" → **tajiri-platform** activates
- Mention "Hive" or "cache" → **mobile-offline-support** activates
- Mention "Swahili" or "design" → **design-guidelines** activates
- Mention "video_player" or "widget" → **flutter-expert** activates

### Explicit Invocation
You can also explicitly reference skills:
- "Use the tajiri-platform patterns for this"
- "Follow design-guidelines for Swahili UI"
- "Apply flutter-expert optimization techniques"

### Combined Usage
Multiple skills work together automatically:
- Building a feed screen → tajiri-platform + flutter-expert + design-guidelines + mobile-offline-support
- Creating a music player → flutter-expert + tajiri-platform + design-guidelines
- Implementing Michango → tajiri-platform + mobile-offline-support

## TAJIRI-Specific Context

### Unique Features
1. **Michango (Crowdfunding)** - GoFundMe-like system integrated into social feed
2. **Full Swahili UI** - Native Tanzanian language throughout
3. **Mobile Money Integration** - M-Pesa, Tigo Pesa, Airtel Money, Halo Pesa
4. **Education Tracking** - Complete educational history from primary to university
5. **Multi-format Posts** - 9 post types: text, photo, video, audio, short_video, audio_text, image_text, poll, shared

### Technology Stack
- **Language**: Dart 3.10+
- **Framework**: Flutter 3+
- **Storage**: Hive (local NoSQL)
- **HTTP**: Dio + http
- **Video**: video_player + chewie
- **Audio**: just_audio + audio_service + audioplayers
- **Images**: cached_network_image + flutter_cache_manager
- **Design**: Material 3

### Project Structure
```
lib/
├── main.dart              # App entry, routing
├── models/                # 24 data models
├── screens/               # 59 screen files (22 categories)
├── services/              # 32 service classes
├── widgets/               # 17 reusable components
└── config/                # Configuration
```

### API Endpoint
- Base URL: `https://zima-uat.site:8003/api`
- Environment: UAT (User Acceptance Testing)

## Memory System

Persistent knowledge stored in `.claude/memory/`:
- `session-state.md` - Current session checkpoint
- `project/domain-knowledge.md` - TAJIRI concepts and features
- `project/patterns.md` - Code patterns and best practices
- `project/architecture.md` - System design and data flow
- `project/troubleshooting.md` - Common issues and solutions

## Best Practices

1. **Always use Swahili** for user-facing UI text
2. **Follow Material 3** design patterns with 12px border radius
3. **Implement offline-first** - cache everything, sync when online
4. **Use optimistic updates** - instant UI feedback, API call second
5. **Apply industry patterns** - from social media leaders without naming them
6. **Test on low-end devices** - optimize for Tanzanian market
7. **Handle mobile money** - integrate with local payment providers
8. **Respect Swahili terminology** - Marafiki not Friends, Ujumbe not Messages

## Success Metrics

When building TAJIRI features, optimize for:
- Daily Active Users (DAU)
- Time spent in app
- Post creation rate
- Engagement rate (likes/views)
- Message send rate
- Video completion rate
- Feed refresh frequency
- Michango campaign success rate
- Mobile money transaction completion

---

**Note**: Skills work transparently in the background. Claude automatically applies relevant patterns, constraints, and best practices based on the conversation context.