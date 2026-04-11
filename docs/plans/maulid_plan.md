# Maulid (Maulid Events) — Implementation Plan

## Overview
Maulid celebration platform with event discovery, qaswida recordings and live streaming, Prophet's biography (sira), event RSVP, photo galleries, and Zanzibar Maulid specials. Celebrates Tanzania's distinctive East African Maulid tradition.

---

## 1. Frontend Architecture

### Directory Structure
```
lib/maulid/
├── maulid_module.dart
├── models/
│   ├── maulid_event.dart
│   ├── qaswida_recording.dart
│   ├── qaswida_group.dart
│   ├── sira_chapter.dart
│   └── maulid_photo.dart
├── services/
│   └── maulid_service.dart          — AuthenticatedDio.instance
├── pages/
│   ├── maulid_home_page.dart
│   ├── events_list_page.dart
│   ├── event_detail_page.dart
│   ├── qaswida_library_page.dart
│   ├── qaswida_player_page.dart
│   ├── group_profile_page.dart
│   ├── sira_reader_page.dart
│   ├── live_stream_page.dart
│   └── photo_gallery_page.dart
└── widgets/
    ├── maulid_countdown.dart
    ├── event_card.dart
    ├── qaswida_tile.dart
    ├── group_card.dart
    ├── sira_chapter_card.dart
    └── gallery_grid.dart
```

### Data Models
- **MaulidEvent** — `id`, `title`, `venueName`, `location`, `lat`, `lng`, `date`, `startTime`, `endTime`, `organizerName`, `qaswidaGroupIds` (List), `program`, `rsvpCount`, `isLive`. `_parseInt`, `_parseDouble`, `_parseBool`.
- **QaswidaRecording** — `id`, `title`, `groupId`, `audioUrl`, `videoUrl`, `duration`, `year`, `coverUrl`, `playCount`. `_parseInt`.
- **QaswidaGroup** — `id`, `name`, `bio`, `photoUrl`, `memberCount`, `recordingCount`. `_parseInt`.
- **SiraChapter** — `id`, `title`, `titleSwahili`, `content`, `order`, `illustrationUrl`. `_parseInt`.
- **MaulidPhoto** — `id`, `eventId`, `photoUrl`, `caption`, `uploadedBy`, `year`. `_parseInt`.

### Service Layer
```dart
Dio get _dio => AuthenticatedDio.instance;
```
- `getHome()` — `GET /api/maulid/home`
- `getEvents({double? lat, double? lng})` — `GET /api/maulid/events`
- `getEvent(int id)` — `GET /api/maulid/events/{id}`
- `rsvpEvent(int eventId)` — `POST /api/maulid/events/{id}/rsvp`
- `getQaswidaLibrary({int? groupId})` — `GET /api/maulid/qaswida`
- `getQaswidaGroup(int id)` — `GET /api/maulid/groups/{id}`
- `getSiraChapters()` — `GET /api/maulid/sira`
- `getPhotoGallery({int? eventId, int? year})` — `GET /api/maulid/photos`
- `getMaulidCountdown()` — `GET /api/maulid/countdown`

### Pages
- **MaulidHomePage** — Countdown to next Maulid, featured events, latest qaswida, history
- **EventsListPage** — Upcoming events by location with date, venue, organizer
- **EventDetailPage** — Full program, qaswida groups, RSVP, directions, share
- **QaswidaLibraryPage** — Browsable audio/video recordings by group, year, style
- **QaswidaPlayerPage** — Audio/video player with lyrics (Arabic and Swahili)
- **GroupProfilePage** — Group info, members, recordings, upcoming performances
- **SiraReaderPage** — Biography chapters with illustrations and timeline
- **LiveStreamPage** — Real-time video/audio of active Maulid events
- **PhotoGalleryPage** — Celebration photos organized by event and year

### Widgets
- `MaulidCountdown` — Days until 12 Rabi ul-Awwal with decorative display
- `QaswidaTile` — Audio/video tile with play button, group name, duration

---

## 2. UI Design
- #1A1A1A/#666666/#FAFAFA/#FFFFFF monochromatic
- 48dp touch, maxLines+ellipsis, _rounded icons
- Dark stat cards for countdown and event count
- Cards: radius 12-16, subtle shadow

### Main Screen Wireframe
```
┌─────────────────────────────┐
│ ← Maulid                ⚙️   │
├─────────────────────────────┤
│ ┌─────────────────────────┐ │
│ │  Maulid un-Nabi         │ │
│ │  12 Rabi ul-Awwal       │ │
│ │  ⏱ 45 days remaining    │ │
│ └─────────────────────────┘ │
│                             │
│  Featured Events            │
│ ┌─────────────────────────┐ │
│ │ Maulid Zanzibar 2026    │ │
│ │ Stone Town • Dec 15     │ │
│ │ 124 attending    [RSVP] │ │
│ └─────────────────────────┘ │
│                             │
│  Latest Qaswida             │
│ ┌─────────────────────────┐ │
│ │ ▶ Kijitonyama Youth     │ │
│ │   "Ya Nabi Salam"  8:32 │ │
│ │ ▶ Qaswida Ensemble      │ │
│ │   "Maulid Nuru"   12:15 │ │
│ └─────────────────────────┘ │
│                             │
│ [Events][Qaswida][Sira][📸] │
└─────────────────────────────┘
```

---

## 3. Performance Strategy

### SQLite
```sql
CREATE TABLE maulid_events(id INTEGER PRIMARY KEY, title TEXT, venue TEXT, date TEXT, lat REAL, lng REAL, json_data TEXT, synced_at TEXT);
CREATE TABLE qaswida_recordings(id INTEGER PRIMARY KEY, title TEXT, group_id INTEGER, duration INTEGER, json_data TEXT, synced_at TEXT);
CREATE TABLE qaswida_downloads(id INTEGER PRIMARY KEY, recording_id INTEGER, file_path TEXT, downloaded_at TEXT);
```
- Stale-while-revalidate: SQLite first, API background
- TTL: events — 1 hour, qaswida library — 6 hours
- Offline: read YES (downloaded qaswida), write RSVP via pending_queue

---

## 4. Backend Implementation

### Database
```sql
CREATE TABLE maulid_events(id BIGSERIAL PRIMARY KEY, title VARCHAR(300), venue_name VARCHAR(200), location TEXT, lat DOUBLE PRECISION, lng DOUBLE PRECISION, event_date DATE, start_time TIME, end_time TIME, organizer_id BIGINT, program TEXT, rsvp_count INTEGER DEFAULT 0, is_live BOOLEAN DEFAULT FALSE, created_at TIMESTAMP DEFAULT NOW());

CREATE TABLE maulid_event_groups(event_id BIGINT, group_id BIGINT, PRIMARY KEY(event_id, group_id));

CREATE TABLE qaswida_recordings(id BIGSERIAL PRIMARY KEY, title VARCHAR(300), group_id BIGINT, audio_url VARCHAR(500), video_url VARCHAR(500), duration INTEGER, year INTEGER, cover_url VARCHAR(500), play_count INTEGER DEFAULT 0, created_at TIMESTAMP DEFAULT NOW());

CREATE TABLE qaswida_groups(id BIGSERIAL PRIMARY KEY, name VARCHAR(200), bio TEXT, photo_url VARCHAR(500), member_count INTEGER DEFAULT 0, recording_count INTEGER DEFAULT 0);

CREATE TABLE sira_chapters(id BIGSERIAL PRIMARY KEY, title VARCHAR(200), title_swahili VARCHAR(200), content TEXT, sort_order INTEGER, illustration_url VARCHAR(500));

CREATE TABLE maulid_photos(id BIGSERIAL PRIMARY KEY, event_id BIGINT, photo_url VARCHAR(500), caption TEXT, uploaded_by BIGINT, year INTEGER, created_at TIMESTAMP DEFAULT NOW());

CREATE TABLE maulid_rsvps(id BIGSERIAL PRIMARY KEY, event_id BIGINT, user_id BIGINT, created_at TIMESTAMP DEFAULT NOW(), UNIQUE(event_id, user_id));
```

### API Endpoints
| Method | Endpoint | Description | Auth |
|--------|----------|-------------|------|
| GET | /api/maulid/home | Maulid home feed | Bearer |
| GET | /api/maulid/events | Event listings | Bearer |
| GET | /api/maulid/events/{id} | Event detail | Bearer |
| POST | /api/maulid/events/{id}/rsvp | RSVP to event | Bearer |
| GET | /api/maulid/qaswida | Qaswida library | Bearer |
| GET | /api/maulid/groups/{id} | Group profile | Bearer |
| GET | /api/maulid/sira | Sira chapters | Bearer |
| GET | /api/maulid/photos | Photo gallery | Bearer |
| GET | /api/maulid/countdown | Days to Maulid | Bearer |

### Controller
`app/Http/Controllers/Api/MaulidController.php` — DB facade with proximity search for events and RSVP management.

---

## 5. Integration Wiring
- **MusicService** — qaswida through TAJIRI music player
- **LivestreamService** — live stream Maulid celebrations
- **PostService** — Maulid event shares and celebration posts
- **MessageService** — event invitations and qaswida links
- **CalendarService** — 12 Rabi ul-Awwal countdown on calendar
- **NotificationService** — event reminders, live stream alerts
- **PhotoService** — celebration photos
- **ClipService** — short qaswida clips
- **Kalenda Hijri** — Maulid date from Islamic calendar
- **Tafuta Msikiti** — mosques hosting Maulid events

---

## 6. Implementation Phases
### Phase 1: Foundation (Week 1)
- Data models, service layer, SQLite schema
- Backend tables and CRUD
- Maulid countdown from Hijri calendar

### Phase 2: Core UI (Week 2)
- Maulid home with countdown
- Event listings with RSVP
- Qaswida library and player

### Phase 3: Integration (Week 3)
- Qaswida group profiles
- Sira reader with chapters
- Live streaming integration

### Phase 4: Polish (Week 4)
- Photo gallery by event and year
- Zanzibar Maulid special section
- Offline downloads, push notifications

---

## 7. External APIs & Integrations

| API | Provider | Purpose | Pricing | Integration Notes |
|-----|----------|---------|---------|-------------------|
| Aladhan Hijri Calendar | Islamic Network | Islamic holidays and events by Hijri date | Free, no auth | Calculate Maulid (12 Rabi ul-Awal), Eid dates |
| Calendarific API | Calendarific | Global holiday API including Islamic holidays | Free (1000 req/month) | Islamic holidays for any country; calendarific.com |
| hijri_date Dart Package | pub.dev | Islamic events with Hijri date support | Free | Built-in Islamic event tracking; multi-language |
| Nager.Date API | Nager.Date | Public holidays with Islamic observances | Free, open source | date.nager.at; Islamic holidays by country |

### Flutter Packages
- `hijri_date` — Islamic events and Hijri date support with multi-language
- `hijri_calendar` — Hijri date conversion for event date calculations

### Integration Priority
1. **Immediate** — Free APIs (Aladhan Hijri Calendar -- no auth, calculate all Islamic event dates)
2. **Short-term** — Freemium APIs (Calendarific for country-specific Islamic holidays)
3. **Partnership** — Nager.Date (supplementary holiday data, open source)
