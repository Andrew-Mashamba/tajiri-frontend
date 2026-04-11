# Ibada (Worship Music) — Implementation Plan

## Overview
Worship music hub with digital hymnals (Nyimbo za Injili, Tenzi za Rohoni), gospel music streaming, chord charts, worship setlist builder, and choir management tools. Built for Tanzanian church worship teams.

---

## 1. Frontend Architecture

### Directory Structure
```
lib/ibada/
├── ibada_module.dart
├── models/
│   ├── hymn.dart
│   ├── gospel_song.dart
│   ├── setlist.dart
│   ├── chord_chart.dart
│   └── choir_group.dart
├── services/
│   └── worship_service.dart         — AuthenticatedDio.instance
├── pages/
│   ├── ibada_home_page.dart
│   ├── hymn_book_page.dart
│   ├── hymn_viewer_page.dart
│   ├── gospel_library_page.dart
│   ├── music_player_page.dart
│   ├── playlist_manager_page.dart
│   ├── chord_chart_page.dart
│   ├── setlist_builder_page.dart
│   └── choir_section_page.dart
└── widgets/
    ├── hymn_tile.dart
    ├── song_card.dart
    ├── lyrics_display.dart
    ├── chord_overlay.dart
    ├── transpose_control.dart
    ├── setlist_item.dart
    └── metronome_widget.dart
```

### Data Models
- **Hymn** — `id`, `hymnNumber`, `title`, `titleSwahili`, `book` (nyimbo_za_injili/tenzi/tumwabudu), `verses` (List), `chordKey`, `audioUrl`. `_parseInt`.
- **GospelSong** — `id`, `title`, `artist`, `albumId`, `genre`, `audioUrl`, `lyricsText`, `duration`, `coverUrl`. `_parseInt`.
- **Setlist** — `id`, `title`, `serviceDate`, `churchId`, `songs` (List of ordered song refs), `notes`.
- **ChordChart** — `id`, `songId`, `key`, `chordsAboveLyrics` (structured text), `capoPosition`. `_parseInt`.
- **ChoirGroup** — `id`, `name`, `churchId`, `memberCount`, `type` (youth/main/praise). `_parseInt`.

### Service Layer
```dart
Dio get _dio => AuthenticatedDio.instance;
```
- `getHymns(String book, {String? search})` — `GET /api/worship/hymns?book={book}`
- `getHymn(int id)` — `GET /api/worship/hymns/{id}`
- `getGospelSongs({String? artist, String? genre})` — `GET /api/worship/songs`
- `getChordChart(int songId, String key)` — `GET /api/worship/chords/{songId}?key={key}`
- `createSetlist(Map data)` — `POST /api/worship/setlists`
- `getSetlists(int churchId)` — `GET /api/worship/setlists?church={churchId}`
- `createPlaylist(Map data)` — `POST /api/worship/playlists`
- `getChoirGroups(int churchId)` — `GET /api/worship/choirs?church={churchId}`

### Pages
- **IbadaHomePage** — Featured songs, recently played, Sunday setlist, hymnal quick access
- **HymnBookPage** — Book selector, number/search browse
- **HymnViewerPage** — Large text display with verse nav, chord toggle, audio play
- **GospelLibraryPage** — Browsable library by artist, album, genre
- **MusicPlayerPage** — Full player with lyrics, queue, repeat, shuffle
- **SetlistBuilderPage** — Drag-and-drop song ordering for worship planning
- **ChordChartPage** — Chords above lyrics with transpose and scroll speed

### Widgets
- `TransposeControl` — Key selector with +/- semitone buttons
- `MetronomeWidget` — Tap-tempo metronome with BPM display

---

## 2. UI Design
- #1A1A1A/#666666/#FAFAFA/#FFFFFF monochromatic
- 48dp touch, maxLines+ellipsis, _rounded icons
- Dark stat cards for songs played, hymns favorited
- Cards: radius 12-16, subtle shadow

### Main Screen Wireframe
```
┌─────────────────────────────┐
│ ← Ibada                🔍   │
├─────────────────────────────┤
│  Hymnals                    │
│ ┌────────┐┌────────┐┌─────┐│
│ │Nyimbo  ││ Tenzi  ││Tumwa││
│ │za Injil││za Roho.││budu ││
│ └────────┘└────────┘└─────┘│
│                             │
│  Sunday Setlist (Apr 6)     │
│ ┌─────────────────────────┐ │
│ │ 1. Bwana Yesu Asifiwe   │ │
│ │ 2. Nyimbo #145          │ │
│ │ 3. Mungu ni Mwema       │ │
│ │           [Edit Setlist] │ │
│ └─────────────────────────┘ │
│                             │
│  Gospel Music               │
│ ┌──────┐ ┌──────┐ ┌──────┐ │
│ │Rose M││Christ.││Goodlu.│ │
│ └──────┘ └──────┘ └──────┘ │
│                             │
│  [Playlists] [Choir] [♫]   │
└─────────────────────────────┘
```

---

## 3. Performance Strategy

### SQLite
```sql
CREATE TABLE hymns(id INTEGER PRIMARY KEY, hymn_number INTEGER, title TEXT, book TEXT, json_data TEXT, synced_at TEXT);
CREATE TABLE gospel_songs(id INTEGER PRIMARY KEY, title TEXT, artist TEXT, duration INTEGER, json_data TEXT, synced_at TEXT);
CREATE INDEX idx_hymns_book_number ON hymns(book, hymn_number);
```
- Stale-while-revalidate: SQLite first, API background
- TTL: hymns — infinite (static), songs — 6 hours
- Offline: read YES (downloaded hymns and songs), write via pending_queue

---

## 4. Backend Implementation

### Database
```sql
CREATE TABLE hymns(id BIGSERIAL PRIMARY KEY, hymn_number INTEGER, title VARCHAR(200), title_swahili VARCHAR(200), book VARCHAR(50), verses JSONB, chord_key VARCHAR(10), audio_url VARCHAR(500));

CREATE TABLE gospel_songs(id BIGSERIAL PRIMARY KEY, title VARCHAR(200), artist VARCHAR(200), album_id BIGINT, genre VARCHAR(50), audio_url VARCHAR(500), lyrics_text TEXT, duration INTEGER, cover_url VARCHAR(500), created_at TIMESTAMP DEFAULT NOW());

CREATE TABLE worship_setlists(id BIGSERIAL PRIMARY KEY, title VARCHAR(200), service_date DATE, church_id BIGINT, songs JSONB, notes TEXT, created_by BIGINT, created_at TIMESTAMP DEFAULT NOW());

CREATE TABLE chord_charts(id BIGSERIAL PRIMARY KEY, song_id BIGINT, song_type VARCHAR(20), original_key VARCHAR(10), chords_data JSONB, capo_position INTEGER DEFAULT 0);

CREATE TABLE choir_groups(id BIGSERIAL PRIMARY KEY, name VARCHAR(200), church_id BIGINT, type VARCHAR(30), member_count INTEGER DEFAULT 0);
```

### API Endpoints
| Method | Endpoint | Description | Auth |
|--------|----------|-------------|------|
| GET | /api/worship/hymns | Browse hymns | Bearer |
| GET | /api/worship/hymns/{id} | Hymn detail | Bearer |
| GET | /api/worship/songs | Gospel songs | Bearer |
| GET | /api/worship/chords/{songId} | Chord chart | Bearer |
| POST | /api/worship/setlists | Create setlist | Bearer |
| GET | /api/worship/setlists | Church setlists | Bearer |
| POST | /api/worship/playlists | Create playlist | Bearer |
| GET | /api/worship/choirs | Choir groups | Bearer |

### Controller
`app/Http/Controllers/Api/WorshipController.php` — DB facade with hymn full-text search and transposition logic.

---

## 5. Integration Wiring
- **MusicService** — gospel/worship content in TAJIRI music player
- **LivestreamService** — live stream worship sessions
- **PostService** — share songs to feed with #Worship hashtag
- **Kanisa Langu** — setlists linked to church services, choir within church
- **Jumuiya** — worship songs for small group devotional
- **Biblia** — scripture-tagged songs link back to Bible reader
- **Huduma** — worship from same service linked to sermon

---

## 6. Implementation Phases
### Phase 1: Foundation (Week 1)
- Data models, service layer, SQLite schema
- Hymn data import (Nyimbo za Injili, Tenzi)
- Backend tables and hymn API

### Phase 2: Core UI (Week 2)
- Hymn book browser with search
- Gospel music library and player
- Lyrics display with large text

### Phase 3: Integration (Week 3)
- Chord charts with transpose
- Setlist builder for worship teams
- Playlist manager

### Phase 4: Polish (Week 4)
- Choir section and rehearsal recordings
- Metronome and performance scroll
- Offline downloads, cross-module links

---

## 7. External APIs & Integrations

| API | Provider | Purpose | Pricing | Integration Notes |
|-----|----------|---------|---------|-------------------|
| Spotify Web API | Spotify | Music search, playlists, playback, artist data | Free (OAuth) | Full catalog search; playlist management; 30s previews; developer.spotify.com |
| Apple Music API / MusicKit | Apple | Music catalog, playlists, playback | Free (Apple Developer account) | MusicKit for iOS/Android/Web; OAuth |
| Musixmatch API | Musixmatch | Lyrics database, synced lyrics, music metadata | Freemium (2k calls/day free) | Largest lyrics database; developer.musixmatch.com |
| Genius API | Genius | Song lyrics, annotations, artist info | Free (API key) | Lyrics search and metadata; docs.genius.com |
| CCLI SongSelect API | CCLI | Worship song lyrics, chord charts, sheet music | Paid (partnership) | 100k+ songs; NDA may be required |

### Integration Priority
1. **Immediate** — Free APIs (Genius for lyrics metadata)
2. **Short-term** — Freemium APIs (Spotify Web API for music catalog, Musixmatch for lyrics)
3. **Partnership** — CCLI SongSelect (worship-specific, requires partnership), Apple MusicKit
