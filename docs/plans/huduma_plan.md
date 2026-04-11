# Huduma (Sermons) — Implementation Plan

## Overview
Sermon discovery and streaming platform for Tanzanian preachers. Upload, browse, and listen to audio/video sermons organized by speaker, topic, series, and scripture. Background playback, offline downloads, and sermon notes.

---

## 1. Frontend Architecture

### Directory Structure
```
lib/huduma/
├── huduma_module.dart
├── models/
│   ├── sermon.dart
│   ├── speaker.dart
│   ├── sermon_series.dart
│   ├── sermon_note.dart
│   └── sermon_bookmark.dart
├── services/
│   └── sermon_service.dart          — AuthenticatedDio.instance
├── pages/
│   ├── sermons_home_page.dart
│   ├── browse_discover_page.dart
│   ├── speaker_profile_page.dart
│   ├── sermon_player_page.dart
│   ├── series_view_page.dart
│   ├── search_results_page.dart
│   ├── my_library_page.dart
│   └── sermon_notes_page.dart
└── widgets/
    ├── sermon_card.dart
    ├── speaker_avatar.dart
    ├── sermon_mini_player.dart
    ├── topic_chip.dart
    ├── bookmark_timestamp.dart
    └── sermon_of_day_card.dart
```

### Data Models
- **Sermon** — `id`, `title`, `speakerId`, `seriesId`, `topic`, `scriptureRef`, `audioUrl`, `videoUrl`, `duration`, `thumbnailUrl`, `playCount`, `downloadCount`, `transcriptUrl`, `createdAt`. `_parseInt`, `_parseDouble`.
- **Speaker** — `id`, `name`, `bio`, `photoUrl`, `churchAffiliation`, `sermonCount`, `followerCount`. `_parseInt`.
- **SermonSeries** — `id`, `title`, `description`, `sermonCount`, `coverUrl`. `_parseInt`.
- **SermonNote** — `id`, `sermonId`, `userId`, `content`, `createdAt`.
- **SermonBookmark** — `id`, `sermonId`, `timestampSeconds`, `label`. `_parseInt`.

### Service Layer
```dart
Dio get _dio => AuthenticatedDio.instance;
```
- `getHome()` — `GET /api/sermons/home`
- `browse({String? topic, int? speakerId, String? scripture})` — `GET /api/sermons/browse`
- `getSermon(int id)` — `GET /api/sermons/{id}`
- `getSpeaker(int id)` — `GET /api/sermons/speakers/{id}`
- `getSeries(int id)` — `GET /api/sermons/series/{id}`
- `search(String query)` — `GET /api/sermons/search?q={query}`
- `followSpeaker(int speakerId)` — `POST /api/sermons/speakers/{id}/follow`
- `saveNote(int sermonId, Map data)` — `POST /api/sermons/{id}/notes`
- `downloadSermon(int id)` — `GET /api/sermons/{id}/download`

### Pages
- **SermonsHomePage** — Featured sermon, recently added, trending, continue listening
- **BrowseDiscoverPage** — Filter by topic, speaker, series, scripture, denomination
- **SpeakerProfilePage** — Photo, bio, church, sermon list, follow button
- **SermonPlayerPage** — Audio/video player with notes panel, bookmark, share
- **MyLibraryPage** — Downloads, bookmarks, recently played, followed speakers

### Widgets
- `SermonMiniPlayer` — Persistent bottom bar with play/pause and title
- `SermonOfDayCard` — Featured daily sermon with speaker and topic

---

## 2. UI Design
- #1A1A1A/#666666/#FAFAFA/#FFFFFF monochromatic
- 48dp touch, maxLines+ellipsis, _rounded icons
- Dark stat cards for listening time and sermon count
- Cards: radius 12-16, subtle shadow

### Main Screen Wireframe
```
┌─────────────────────────────┐
│ ← Huduma               🔍   │
├─────────────────────────────┤
│ ┌─────────────────────────┐ │
│ │ Sermon of the Day       │ │
│ │ "Faith in Hard Times"   │ │
│ │ Bishop Kakobe • 45 min  │ │
│ │              [▶ Play]   │ │
│ └─────────────────────────┘ │
│                             │
│  Continue Listening         │
│  "Marriage Series" Part 3   │
│  ████████░░░  25:30 / 52:00│
│                             │
│  Topics                     │
│ [Prayer][Marriage][Finance] │
│ [Healing][Salvation][Youth] │
│                             │
│  Recently Added             │
│ ┌─────────────────────────┐ │
│ │ 🎙 Pastor J. • 38 min  │ │
│ │ 🎙 Bishop M. • 55 min  │ │
│ └─────────────────────────┘ │
└─────────────────────────────┘
```

---

## 3. Performance Strategy

### SQLite
```sql
CREATE TABLE sermons(id INTEGER PRIMARY KEY, title TEXT, speaker_id INTEGER, topic TEXT, duration INTEGER, json_data TEXT, synced_at TEXT);
CREATE TABLE sermon_downloads(id INTEGER PRIMARY KEY, sermon_id INTEGER, file_path TEXT, downloaded_at TEXT);
CREATE INDEX idx_sermons_topic ON sermons(topic);
CREATE INDEX idx_sermons_speaker ON sermons(speaker_id);
```
- Stale-while-revalidate: SQLite first, API background
- TTL: sermon list — 1 hour, sermon detail — 6 hours
- Offline: read YES (downloaded sermons), write notes via pending_queue

---

## 4. Backend Implementation

### Database
```sql
CREATE TABLE sermons(id BIGSERIAL PRIMARY KEY, title VARCHAR(300), speaker_id BIGINT, series_id BIGINT, topic VARCHAR(100), scripture_ref VARCHAR(100), audio_url VARCHAR(500), video_url VARCHAR(500), duration INTEGER, thumbnail_url VARCHAR(500), play_count INTEGER DEFAULT 0, transcript_url VARCHAR(500), created_at TIMESTAMP DEFAULT NOW());

CREATE TABLE speakers(id BIGSERIAL PRIMARY KEY, user_id BIGINT, name VARCHAR(200), bio TEXT, photo_url VARCHAR(500), church_affiliation VARCHAR(200), sermon_count INTEGER DEFAULT 0, follower_count INTEGER DEFAULT 0);

CREATE TABLE sermon_series(id BIGSERIAL PRIMARY KEY, title VARCHAR(200), description TEXT, cover_url VARCHAR(500), sermon_count INTEGER DEFAULT 0);

CREATE TABLE sermon_notes(id BIGSERIAL PRIMARY KEY, sermon_id BIGINT, user_id BIGINT, content TEXT, created_at TIMESTAMP DEFAULT NOW());

CREATE TABLE sermon_bookmarks(id BIGSERIAL PRIMARY KEY, sermon_id BIGINT, user_id BIGINT, timestamp_seconds INTEGER, label VARCHAR(200), created_at TIMESTAMP DEFAULT NOW());

CREATE TABLE speaker_follows(id BIGSERIAL PRIMARY KEY, user_id BIGINT, speaker_id BIGINT, created_at TIMESTAMP DEFAULT NOW(), UNIQUE(user_id, speaker_id));
```

### API Endpoints
| Method | Endpoint | Description | Auth |
|--------|----------|-------------|------|
| GET | /api/sermons/home | Home feed | Bearer |
| GET | /api/sermons/browse | Browse with filters | Bearer |
| GET | /api/sermons/{id} | Sermon detail | Bearer |
| GET | /api/sermons/speakers/{id} | Speaker profile | Bearer |
| GET | /api/sermons/series/{id} | Series detail | Bearer |
| GET | /api/sermons/search | Full-text search | Bearer |
| POST | /api/sermons/speakers/{id}/follow | Follow speaker | Bearer |
| POST | /api/sermons/{id}/notes | Save note | Bearer |
| GET | /api/sermons/{id}/download | Download audio | Bearer |

### Controller
`app/Http/Controllers/Api/SermonController.php` — DB facade with play_count increment and full-text search.

---

## 5. Integration Wiring
- **MusicService** — sermon audio streamed through TAJIRI audio player
- **ClipService** — short sermon clips for sharing
- **PostService** — share sermons to social feed
- **Kanisa Langu** — sermons appear in church profile library
- **Biblia** — tap scripture references to open Bible passage
- **Jumuiya** — assign sermons for group discussion

---

## 6. Implementation Phases
### Phase 1: Foundation (Week 1)
- Data models, service layer, SQLite schema
- Backend tables and CRUD endpoints
- Sermon upload and storage

### Phase 2: Core UI (Week 2)
- Sermon player (audio/video) with background playback
- Browse/discover with topic and speaker filters
- Speaker profile pages

### Phase 3: Integration (Week 3)
- Series organization and progress tracking
- Sermon notes and timestamp bookmarks
- Offline downloads

### Phase 4: Polish (Week 4)
- Sermon of the day, recommended sermons
- Transcript generation (Swahili)
- Cross-module Bible and church links

---

## 7. External APIs & Integrations

| API | Provider | Purpose | Pricing | Integration Notes |
|-----|----------|---------|---------|-------------------|
| Bible Brain Audio API | Faith Comes By Hearing | Audio Bible content, signed URLs for playback | Free for non-commercial | RESTful; CDN signed URLs; 1000+ languages |
| Spotify Web API | Spotify | Podcast/sermon search, playback, playlists | Free (OAuth) | Search podcasts, get episodes; developer.spotify.com |
| Apple Podcasts API | Apple | Podcast search, episode metadata | Free | iTunes search endpoint; metadata only |
| Podbean API | Podbean | Podcast hosting, episode management, analytics | Freemium (5hrs free) | REST API for episode CRUD; popular with churches |
| bible-api.com | Open source | Bible verse references in sermons | Free, no auth | Link sermon points to scripture passages |

### Integration Priority
1. **Immediate** — Free APIs (Bible Brain Audio for audio sermons, bible-api.com for verse refs)
2. **Short-term** — Freemium APIs (Spotify Web API for sermon podcasts, Podbean)
3. **Partnership** — MyChurch Media, Transistor (paid sermon hosting)
