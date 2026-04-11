# Biblia (Bible) — Implementation Plan

## Overview
Full-featured digital Bible reader with Swahili SUV and English translations, audio narration, reading plans, bookmarks, highlights, notes, search, and verse sharing. Offline-first for rural Tanzania.

---

## 1. Frontend Architecture

### Directory Structure
```
lib/biblia/
├── biblia_module.dart
├── models/
│   ├── bible_book.dart
│   ├── bible_chapter.dart
│   ├── bible_verse.dart
│   ├── reading_plan.dart
│   ├── bookmark.dart
│   ├── highlight.dart
│   └── verse_note.dart
├── services/
│   └── bible_service.dart           — AuthenticatedDio.instance
├── pages/
│   ├── bible_home_page.dart
│   ├── bible_reader_page.dart
│   ├── book_selector_page.dart
│   ├── search_results_page.dart
│   ├── reading_plans_page.dart
│   ├── reading_plan_tracker_page.dart
│   ├── bookmarks_highlights_page.dart
│   └── verse_share_page.dart
└── widgets/
    ├── verse_card.dart
    ├── verse_of_day_card.dart
    ├── reading_plan_card.dart
    ├── audio_mini_player.dart
    ├── highlight_toolbar.dart
    └── book_grid.dart
```

### Data Models
- **BibleBook** — `id`, `name`, `nameSwahili`, `testament` (OT/NT), `chapterCount`, `order`. `fromJson` with `_parseInt`.
- **BibleVerse** — `id`, `bookId`, `chapter`, `verseNumber`, `textSuv`, `textEnglish`, `audioUrl`. `_parseInt` helpers.
- **ReadingPlan** — `id`, `title`, `description`, `durationDays`, `currentDay`, `isActive`. `_parseBool`.
- **Bookmark** — `id`, `verseId`, `label`, `createdAt`.
- **Highlight** — `id`, `verseId`, `color` (5 options), `createdAt`.

### Service Layer
```dart
Dio get _dio => AuthenticatedDio.instance;
```
- `getBooks()` — `GET /api/bible/books`
- `getChapter(int bookId, int chapter, String translation)` — `GET /api/bible/chapters/{bookId}/{chapter}`
- `searchVerses(String query, {String? testament})` — `GET /api/bible/search?q={query}`
- `getVerseOfDay()` — `GET /api/bible/verse-of-day`
- `getReadingPlans()` — `GET /api/bible/plans`
- `updatePlanProgress(int planId, int day)` — `PUT /api/bible/plans/{planId}/progress`
- `saveBookmark(Map data)` — `POST /api/bible/bookmarks`
- `saveHighlight(Map data)` — `POST /api/bible/highlights`
- `saveNote(Map data)` — `POST /api/bible/notes`

### Pages
- **BibleHomePage** — Verse of day card, continue reading button, active plan progress
- **BibleReaderPage** — Chapter text with tap-to-select verse actions (highlight/note/share)
- **BookSelectorPage** — Grid of 66 books grouped OT/NT, then chapter picker
- **SearchResultsPage** — Verse results with context snippets and filter chips
- **ReadingPlansPage** — Plan cards with duration and start button

### Widgets
- `VerseOfDayCard` — Styled verse image with translation toggle
- `AudioMiniPlayer` — Persistent bottom player for Bible audio
- `HighlightToolbar` — 5 color dots for highlighting selected verse

---

## 2. UI Design
- #1A1A1A/#666666/#FAFAFA/#FFFFFF monochromatic
- 48dp touch, maxLines+ellipsis, _rounded icons
- Dark stat cards for reading streaks and plan progress
- Cards: radius 12-16, subtle shadow

### Main Screen Wireframe
```
┌─────────────────────────────┐
│ ← Biblia               🔍   │
├─────────────────────────────┤
│ ┌─────────────────────────┐ │
│ │ Verse of the Day        │ │
│ │ "Bwana ni mchungaji..." │ │
│ │  Zaburi 23:1 (SUV)      │ │
│ │           [Share] [Save] │ │
│ └─────────────────────────┘ │
│                             │
│  Continue Reading           │
│  Yohana 3 • verse 12       │
│  [Continue →]               │
│                             │
│  Reading Plan      Day 15/90│
│  ████████████░░░░░░  45%    │
│                             │
│  [📖 Books] [🔖 Saved] [🎧]│
└─────────────────────────────┘
```

---

## 3. Performance Strategy

### SQLite
```sql
CREATE TABLE bible_verses(id INTEGER PRIMARY KEY, book_id INTEGER, chapter INTEGER, verse_number INTEGER, text_suv TEXT, text_english TEXT, audio_url TEXT, synced_at TEXT);
CREATE TABLE bookmarks(id INTEGER PRIMARY KEY, verse_id INTEGER, label TEXT, json_data TEXT, synced_at TEXT);
CREATE TABLE highlights(id INTEGER PRIMARY KEY, verse_id INTEGER, color TEXT, synced_at TEXT);
CREATE INDEX idx_verses_book_chapter ON bible_verses(book_id, chapter);
```
- Stale-while-revalidate: SQLite first, API background
- TTL: Bible text — infinite (static content), plans — 1 hour
- Offline: read YES (downloaded translations), write via pending_queue for bookmarks/highlights

---

## 4. Backend Implementation

### Database
```sql
CREATE TABLE bible_books(id BIGSERIAL PRIMARY KEY, name VARCHAR(100), name_swahili VARCHAR(100), testament VARCHAR(2), chapter_count INTEGER, sort_order INTEGER);

CREATE TABLE bible_verses(id BIGSERIAL PRIMARY KEY, book_id BIGINT REFERENCES bible_books(id), chapter INTEGER, verse_number INTEGER, text_suv TEXT, text_niv TEXT, text_kjv TEXT, audio_url VARCHAR(500));

CREATE TABLE bible_bookmarks(id BIGSERIAL PRIMARY KEY, user_id BIGINT, verse_id BIGINT, label VARCHAR(200), created_at TIMESTAMP DEFAULT NOW());

CREATE TABLE bible_highlights(id BIGSERIAL PRIMARY KEY, user_id BIGINT, verse_id BIGINT, color VARCHAR(20), created_at TIMESTAMP DEFAULT NOW());

CREATE TABLE reading_plans(id BIGSERIAL PRIMARY KEY, title VARCHAR(200), description TEXT, duration_days INTEGER, is_custom BOOLEAN DEFAULT FALSE);

CREATE TABLE user_reading_progress(id BIGSERIAL PRIMARY KEY, user_id BIGINT, plan_id BIGINT, current_day INTEGER DEFAULT 1, started_at TIMESTAMP, completed_at TIMESTAMP);
```

### API Endpoints
| Method | Endpoint | Description | Auth |
|--------|----------|-------------|------|
| GET | /api/bible/books | List all 66 books | Bearer |
| GET | /api/bible/chapters/{bookId}/{chapter} | Get chapter verses | Bearer |
| GET | /api/bible/search | Full-text search | Bearer |
| GET | /api/bible/verse-of-day | Daily verse | Bearer |
| GET | /api/bible/plans | Browse reading plans | Bearer |
| PUT | /api/bible/plans/{id}/progress | Update plan day | Bearer |
| POST | /api/bible/bookmarks | Save bookmark | Bearer |
| POST | /api/bible/highlights | Save highlight | Bearer |
| POST | /api/bible/notes | Save note | Bearer |

### Controller
`app/Http/Controllers/Api/BibleController.php` — DB facade pattern with full-text search on `bible_verses`.

---

## 5. Integration Wiring
- **PostService** — share verse cards to feed with #BibleVerse hashtag
- **MessageService** — send verses in chat and jumuiya group
- **NotificationService** — daily verse push, reading plan reminders
- **MusicService** — worship songs tagged with scripture references link back
- **Sala** — scripture-linked prayers reference Bible passages
- **Jumuiya** — weekly study passages linked from group schedule

---

## 6. Implementation Phases
### Phase 1: Foundation (Week 1)
- Data models, service layer, SQLite schema
- Bible text import (SUV, NIV, KJV)
- Backend tables and verse API

### Phase 2: Core UI (Week 2)
- Bible reader with book/chapter navigation
- Search with OT/NT filters
- Verse of the day

### Phase 3: Integration (Week 3)
- Bookmarks, highlights, notes
- Reading plans with progress tracking
- Audio player integration

### Phase 4: Polish (Week 4)
- Offline download for full translations
- Verse share cards (styled images)
- Cross-module links (Sala, Jumuiya, Huduma)

---

## 7. External APIs & Integrations

| API | Provider | Purpose | Pricing | Integration Notes |
|-----|----------|---------|---------|-------------------|
| bible-api.com | Open source | Simple Bible verse lookup (KJV, WEB) | Free, no auth | Minimal REST; GET /VERSE returns JSON; simplest to integrate |
| API.Bible | American Bible Society | 1500+ Bible versions in 1000+ languages | Free (API key, 5k/day) | docs.api.bible; most comprehensive Bible API |
| ESV API | Crossway | English Standard Version text retrieval | Free for non-commercial (API key) | 5,000 queries/day; register at api.esv.org |
| Bible Brain (DBP v4) | Faith Comes By Hearing | Audio + text Bible; 1000+ languages | Free for non-commercial (API key) | Signed URLs for audio/video playback |
| Free Bible API (wldeh) | GitHub community | 200+ versions, multiple languages | Free, no auth | No rate limits; open source; hosted on GitHub |

### Integration Priority
1. **Immediate** — Free APIs (bible-api.com for quick verse lookup, no auth needed)
2. **Short-term** — Freemium APIs (API.Bible for 1500+ versions, ESV API)
3. **Partnership** — Bible Brain for audio Bible content
