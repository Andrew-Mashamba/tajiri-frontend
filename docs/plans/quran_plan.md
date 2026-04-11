# Quran — Implementation Plan

## Overview
Complete Quran reader with Arabic Uthmani script, Swahili translation (Sheikh Farsy), audio recitation by renowned reciters, Tajweed color coding, word-by-word analysis, memorization tools, reading plans, and offline support.

---

## 1. Frontend Architecture

### Directory Structure
```
lib/quran/
├── quran_module.dart
├── models/
│   ├── surah.dart
│   ├── ayah.dart
│   ├── juz.dart
│   ├── reciter.dart
│   ├── quran_bookmark.dart
│   └── memorization_progress.dart
├── services/
│   └── quran_service.dart           — AuthenticatedDio.instance
├── pages/
│   ├── quran_home_page.dart
│   ├── surah_list_page.dart
│   ├── juz_browser_page.dart
│   ├── reading_view_page.dart
│   ├── word_by_word_page.dart
│   ├── audio_player_page.dart
│   ├── search_results_page.dart
│   ├── memorization_tracker_page.dart
│   ├── memorization_practice_page.dart
│   └── bookmark_manager_page.dart
└── widgets/
    ├── ayah_card.dart
    ├── tajweed_text.dart
    ├── surah_info_card.dart
    ├── reciter_selector.dart
    ├── memorization_grid.dart
    ├── ayah_audio_controls.dart
    └── daily_ayah_card.dart
```

### Data Models
- **Surah** — `id`, `number`, `nameArabic`, `nameSwahili`, `nameEnglish`, `revelationType` (makki/madani), `ayahCount`, `juzStart`. `_parseInt`.
- **Ayah** — `id`, `surahId`, `ayahNumber`, `textArabic`, `textSwahili`, `textEnglish`, `juz`, `page`, `audioUrl`, `tajweedData`. `_parseInt`.
- **Juz** — `number`, `startSurah`, `startAyah`, `endSurah`, `endAyah`. `_parseInt`.
- **Reciter** — `id`, `name`, `style`, `audioBaseUrl`.
- **QuranBookmark** — `id`, `surahId`, `ayahNumber`, `label`, `createdAt`. `_parseInt`.
- **MemorizationProgress** — `surahId`, `status` (not_started/in_progress/memorized), `lastPracticed`.

### Service Layer
```dart
Dio get _dio => AuthenticatedDio.instance;
```
- `getSurahs()` — `GET /api/quran/surahs`
- `getAyahs(int surahId, {String? translation})` — `GET /api/quran/surahs/{id}/ayahs`
- `getJuz(int juzNumber)` — `GET /api/quran/juz/{number}`
- `searchQuran(String query)` — `GET /api/quran/search?q={query}`
- `getReciters()` — `GET /api/quran/reciters`
- `getAyahAudio(int surahId, int ayahNumber, int reciterId)` — `GET /api/quran/audio/{surahId}/{ayahNumber}`
- `getDailyAyah()` — `GET /api/quran/daily-ayah`
- `saveBookmark(Map data)` — `POST /api/quran/bookmarks`
- `updateMemorization(int surahId, String status)` — `PUT /api/quran/memorization/{surahId}`
- `saveLastRead(int surahId, int ayahNumber)` — `PUT /api/quran/last-read`

### Pages
- **QuranHomePage** — Last read position, daily ayah, memorization progress, reading plan
- **SurahListPage** — All 114 surahs with revelation type and ayah count
- **JuzBrowserPage** — 30 juz with associated surahs and pages
- **ReadingViewPage** — Arabic text with optional translation, audio controls, Tajweed
- **WordByWordPage** — Interactive Arabic text with pop-up word details
- **MemorizationTrackerPage** — Surah/juz grid showing status
- **MemorizationPracticePage** — Hide/reveal mode with audio playback

### Widgets
- `TajweedText` — Color-coded Arabic text (idgham, ikhfa, qalqalah rules)
- `DailyAyahCard` — Styled ayah with Arabic and Swahili translation

---

## 2. UI Design
- #1A1A1A/#666666/#FAFAFA/#FFFFFF monochromatic
- 48dp touch, maxLines+ellipsis, _rounded icons
- Dark stat cards for memorization progress and reading streak
- Cards: radius 12-16, subtle shadow

### Main Screen Wireframe
```
┌─────────────────────────────┐
│ ← Quran                🔍   │
├─────────────────────────────┤
│ ┌─────────────────────────┐ │
│ │ Daily Ayah              │ │
│ │ بِسْمِ ٱللَّهِ ٱلرَّحْمَٰنِ│ │
│ │ "Kwa jina la Mwenyezi"  │ │
│ │ Al-Fatiha 1:1    [Share]│ │
│ └─────────────────────────┘ │
│                             │
│  Continue Reading           │
│  Al-Baqarah • Ayah 142     │
│  [Continue →]               │
│                             │
│  Memorization     12/114    │
│  ████████░░░░░░░░░░ 10%    │
│                             │
│  [Surahs] [Juz] [Bookmark] │
│                             │
│  ▶ Now Playing: Al-Sudais   │
└─────────────────────────────┘
```

---

## 3. Performance Strategy

### SQLite
```sql
CREATE TABLE quran_ayahs(id INTEGER PRIMARY KEY, surah_id INTEGER, ayah_number INTEGER, text_arabic TEXT, text_swahili TEXT, text_english TEXT, juz INTEGER, synced_at TEXT);
CREATE TABLE quran_bookmarks(id INTEGER PRIMARY KEY, surah_id INTEGER, ayah_number INTEGER, label TEXT, synced_at TEXT);
CREATE TABLE memorization(surah_id INTEGER PRIMARY KEY, status TEXT, last_practiced TEXT);
CREATE INDEX idx_ayahs_surah ON quran_ayahs(surah_id);
```
- Stale-while-revalidate: SQLite first, API background
- TTL: Quran text — infinite (static), bookmarks — 1 hour
- Offline: read YES (downloaded text and audio), write via pending_queue

---

## 4. Backend Implementation

### Database
```sql
CREATE TABLE quran_surahs(id BIGSERIAL PRIMARY KEY, number INTEGER, name_arabic VARCHAR(100), name_swahili VARCHAR(200), name_english VARCHAR(200), revelation_type VARCHAR(10), ayah_count INTEGER, juz_start INTEGER);

CREATE TABLE quran_ayahs(id BIGSERIAL PRIMARY KEY, surah_id BIGINT, ayah_number INTEGER, text_arabic TEXT, text_swahili TEXT, text_english TEXT, juz INTEGER, page INTEGER, tajweed_data JSONB);

CREATE TABLE quran_audio(id BIGSERIAL PRIMARY KEY, surah_id BIGINT, ayah_number INTEGER, reciter_id BIGINT, audio_url VARCHAR(500));

CREATE TABLE quran_reciters(id BIGSERIAL PRIMARY KEY, name VARCHAR(200), style VARCHAR(50), audio_base_url VARCHAR(500));

CREATE TABLE quran_bookmarks(id BIGSERIAL PRIMARY KEY, user_id BIGINT, surah_id BIGINT, ayah_number INTEGER, label VARCHAR(200), created_at TIMESTAMP DEFAULT NOW());

CREATE TABLE quran_memorization(id BIGSERIAL PRIMARY KEY, user_id BIGINT, surah_id BIGINT, status VARCHAR(20) DEFAULT 'not_started', last_practiced TIMESTAMP, UNIQUE(user_id, surah_id));

CREATE TABLE quran_last_read(user_id BIGINT PRIMARY KEY, surah_id BIGINT, ayah_number INTEGER, updated_at TIMESTAMP DEFAULT NOW());
```

### API Endpoints
| Method | Endpoint | Description | Auth |
|--------|----------|-------------|------|
| GET | /api/quran/surahs | List all surahs | Bearer |
| GET | /api/quran/surahs/{id}/ayahs | Surah ayahs | Bearer |
| GET | /api/quran/juz/{number} | Juz content | Bearer |
| GET | /api/quran/search | Search Quran | Bearer |
| GET | /api/quran/reciters | Available reciters | Bearer |
| GET | /api/quran/audio/{surahId}/{ayahNumber} | Ayah audio | Bearer |
| GET | /api/quran/daily-ayah | Daily ayah | Bearer |
| POST | /api/quran/bookmarks | Save bookmark | Bearer |
| PUT | /api/quran/memorization/{surahId} | Update progress | Bearer |
| PUT | /api/quran/last-read | Save position | Bearer |

### Controller
`app/Http/Controllers/Api/QuranController.php` — DB facade with full-text search on Arabic and Swahili text.

---

## 5. Integration Wiring
- **PostService** — share ayah cards to feed with #QuranAyah hashtag
- **StoryService** — daily ayah as story
- **MessageService** — send ayahs in chat and mosque groups
- **MusicService** — recitation audio through TAJIRI player
- **Wakati wa Sala** — suggested surahs for each prayer
- **Dua** — Quranic duas link to full context
- **Ramadan** — khatm plan with daily juz assignment
- **Hadith** — cross-references between hadith and Quran

---

## 6. Implementation Phases
### Phase 1: Foundation (Week 1)
- Data models, service layer, SQLite schema
- Quran text import (Arabic, Swahili Farsy, English)
- Backend tables and surah/ayah API

### Phase 2: Core UI (Week 2)
- Reading view with Arabic and translation
- Surah list and juz browser
- Audio recitation player

### Phase 3: Integration (Week 3)
- Tajweed color coding
- Word-by-word analysis
- Bookmarks and search

### Phase 4: Polish (Week 4)
- Memorization tracker and practice mode
- Reading plans (khatm schedules)
- Offline download, share cards

---

## 7. External APIs & Integrations

| API | Provider | Purpose | Pricing | Integration Notes |
|-----|----------|---------|---------|-------------------|
| Al Quran Cloud API | alquran.cloud | Quran text, translations, audio recitations | Free, no auth | 77+ editions; JSON; alquran.cloud/api |
| Quran.com API v4 | Quran Foundation | Chapters, verses, recitations, translations, tafsir | Free (OAuth2 required) | Client credentials flow; 1hr tokens; api-docs.quran.foundation |
| Fawaz Ahmed Quran API | GitHub | 90+ languages, 400+ translations | Free, no auth | CDN-hosted JSON files; no rate limits |
| GlobalQuran API | GlobalQuran.com | Quran text with translations and audio | Free | JSON/JSONP format; globalquran.com |
| Tanzil.net | Tanzil | Verified Quran text in multiple scripts | Free (download) | Unicode text files; tanzil.net/download |

### Integration Priority
1. **Immediate** — Free APIs (Al Quran Cloud -- no auth, 77+ editions, production-ready)
2. **Short-term** — Quran.com API v4 (richer features, tafsir, requires OAuth2)
3. **Partnership** — Tanzil.net for verified text downloads; Fawaz Ahmed for offline bundles
