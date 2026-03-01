# TAJIRI Navigation Map

This document describes how users reach every feature in the TAJIRI app. Every story in the PRD has a `navigation_path`—use this map as the source of truth.

**Design Reference:** All screens follow [DOCS/DESIGN.md](DESIGN.md) (layout, colors, touch targets, overflow prevention).

---

## App Entry & Auth

| Path | Screen | Stories |
|------|--------|---------|
| **App Launch** | SplashScreen | STORY-003 |
| **No user** | Splash → Login → RegistrationScreen | STORY-001 |
| **Has user** | Splash → HomeScreen | STORY-071 |

### Registration Flow (multi-step)
```
Splash → Login → RegistrationScreen
  → Step 0: Bio (Taarifa Binafsi)           STORY-073
  → Step 1: Phone (Thibitisha Simu)         STORY-074, STORY-002
  → Step 2: Location (Mahali Unapoishi)     STORY-004
  → Step 3: Primary School                  STORY-005
  → Step 4: Secondary School                STORY-006
  → Step 5: Education Path (A-Level yes/no) STORY-075
  → Step 6: A-Level (conditional)           STORY-007
  → Step 7: Post-secondary / University     STORY-008
  → Step 8: Employer                        STORY-009
  → Complete → ProfileScreen
```

---

## Home Screen (5 Bottom Tabs)

| Tab | Label | Screen | Primary Stories |
|-----|-------|--------|-----------------|
| 0 | Nyumbani | FeedScreen | 26, 27, 28, 29, 88, 51 |
| 1 | Marafiki | FriendsScreen | 36, 34, 35, 37 |
| 2 | Ujumbe | ConversationsScreen | 38, 39, 40, 59, 60 |
| 3 | Picha | PhotosScreen | 33, 31, 32 |
| 4 | Mimi | ProfileScreen | 10, 11, 12, 13, 14, 55, 56, 57, 61, 69, 77–81, 87 |

---

## Feed (Nyumbani) – Tab 0

```
Home → Feed
  ├── Tab: Friends      → STORY-027
  ├── Tab: Discover     → STORY-029
  ├── Tab: Live         → STORY-088 (LiveStreamsGrid)
  ├── Stories row (top) → STORY-051
  └── FAB (+)           → CreatePostScreen STORY-92
        ├── Text        → STORY-15
        ├── Photo       → STORY-16
        ├── Audio       → STORY-17
        ├── Short Video → STORY-18
        └── Poll        → STORY-48
```

**Post actions (from feed):** View STORY-19, Edit STORY-20, Delete STORY-21, Like STORY-22, Comment STORY-23, Share STORY-24, Save STORY-25, Schedule STORY-85, @mentions #hashtags STORY-86.

---

## Friends (Marafiki) – Tab 1

```
Home → Friends
  ├── Friends list      → STORY-36
  ├── Send request      → STORY-34 (from other profile)
  ├── Accept/Decline    → STORY-35
  └── Suggestions       → STORY-37
```

---

## Messages (Ujumbe) – Tab 2

```
Home → Messages → Tap conversation
  → ChatScreen          → STORY-39
  → Typing indicator    → STORY-40
  → Call icon           → STORY-59
  → Group call          → STORY-60
```

---

## Photos (Picha) – Tab 3

```
Home → Photos
  ├── Grid/Gallery      → STORY-33, STORY-97
  ├── Upload            → STORY-31
  └── Albums            → STORY-32
```

---

## Profile (Mimi) – Tab 4

```
Home → Profile
  ├── View profile      → STORY-10
  ├── Edit profile      → STORY-11
  ├── Profile photo     → STORY-12
  ├── Cover photo       → STORY-13
  ├── Username          → STORY-14
  │
  ├── ⋮ Menu (top-right)
  │   ├── Tajiri Pay    → WalletScreen STORY-61
  │   ├── Simu          → CallHistoryScreen STORY-87
  │   └── Toka          → Logout
  │
  ├── ⚙ Settings       → SettingsScreen STORY-69
  │   └── Profile Tabs  → STORY-76, STORY-70
  │
  ├── FAB (+)           → Create Post STORY-92
  │
  └── Tabs (profile content)
      ├── Machapisho    → Posts         STORY-10
      ├── Picha         → PhotoGallery  STORY-33, STORY-97
      ├── Video         → VideoGallery  STORY-77
      ├── Muziki        → MusicGallery  STORY-78 → Music library STORY-55
      │   └── Upload    → STORY-56
      ├── Live          → LiveGallery   STORY-79 → Go Live STORY-57
      ├── Michango      → MichangoGallery STORY-81
      │   ├── Create    → STORY-80
      │   ├── Donate    → STORY-82
      │   └── Withdraw  → STORY-83
      ├── Vikundi       → Groups        STORY-91
      └── ...
```

---

## Reachability Summary

| Story Type | Reachable From |
|------------|----------------|
| **Root** (parent_story_id: null) | Splash, Home tabs, direct route |
| **Child** | Parent story's screen or flow |
| **API-only** | Embedded in parent (e.g. Check Phone in Registration) |
| **Infrastructure** | Used by all media views (e.g. Media Caching) |

**No story is orphaned:** Every story has either `parent_story_id: null` (root) or a valid `parent_story_id` linking to a reachable parent.

---

## Quick Path Lookup (Example Journeys)

| Goal | Path |
|------|------|
| **Upload Music** | Splash → Home → Profile [Mimi] → Tab Muziki → Upload → MusicUploadScreen |
| **Go Live** | Splash → Home → Profile → Tab Live → Go Live → BackstageScreen → StandbyScreen → Live |
| **Create Michango Campaign** | Splash → Home → Profile → Tab Michango → Create campaign |
| **View/Join Live Stream** | Splash → Home → Feed → Tab Live → Tap stream |
| **Upload Photo** | Splash → Home → Photos [Picha] → Upload |
| **Create Story** | Splash → Home → Feed → Stories row → Your ring → Create Story |
| **Edit Profile** | Splash → Home → Profile → ⋮ menu → Edit profile |
| **Wallet / Tajiri Pay** | Splash → Home → Profile → ⋮ menu → Tajiri Pay |
| **Call History** | Splash → Home → Profile → ⋮ menu → Simu |
| **Settings** | Splash → Home → Profile → ⚙ Settings |
| **Create Post** | Splash → Home → Feed → FAB (+) → CreatePostScreen |
| **View Clips/Shorts** | Splash → Home → Feed → Tab Shorts OR Profile → Tab Video |
| **Search Users** | Splash → Home → Search (global) → Users tab |
| **Hashtag Explore** | Splash → Home → Search → Hashtags OR tap #hashtag in post |

---

## Design Reference

**Every story references [DOCS/DESIGN.md](DESIGN.md).** Before implementing any story:

- **Layout** – Standard page structure, overflow prevention
- **Touch targets** – Minimum 48dp for tap areas
- **Colors** – Primary #1A1A1A, background #FAFAFA, accent per DESIGN.md
- **Low bandwidth** – Compress images, lazy-load, cache (MediaCacheService)

---

## Implementation Checklist

When implementing a story:

1. **Verify navigation_path** – Can the user actually reach this screen?
2. **Add route if missing** – Update `main.dart` `onGenerateRoute` or ensure `Navigator.push` exists.
3. **Apply DOCS/DESIGN.md** – Colors, touch targets (48dp min), overflow handling.
4. **Reference social apps** – See `social_media_reference` in PRD for behavior patterns.
5. **Use implementation_notes** – Stories with implementation_notes include UX/behavior details (e.g. Stories tap-through, Chat bubbles, Live overlay).
