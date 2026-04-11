# Hadith — Implementation Plan

## Overview
Authenticated hadith library with all six major collections (Bukhari, Muslim, Abu Dawud, Tirmidhi, Nasai, Ibn Majah) in Arabic with Swahili translation, authenticity grading, topic-based browsing, daily hadith, and the 40 Nawawi special collection.

---

## 1. Frontend Architecture

### Directory Structure
```
lib/hadith/
├── hadith_module.dart
├── models/
│   ├── hadith.dart
│   ├── hadith_collection.dart
│   ├── hadith_book.dart
│   ├── hadith_topic.dart
│   └── reading_progress.dart
├── services/
│   └── hadith_service.dart          — AuthenticatedDio.instance
├── pages/
│   ├── hadith_home_page.dart
│   ├── collections_browser_page.dart
│   ├── book_chapter_page.dart
│   ├── hadith_detail_page.dart
│   ├── topic_browser_page.dart
│   ├── search_results_page.dart
│   ├── favorites_library_page.dart
│   ├── forty_nawawi_page.dart
│   └── reading_tracker_page.dart
└── widgets/
    ├── hadith_card.dart
    ├── collection_cover.dart
    ├── grading_badge.dart
    ├── narrator_chain.dart
    ├── topic_icon_card.dart
    ├── daily_hadith_card.dart
    └── progress_bar.dart
```

### Data Models
- **Hadith** — `id`, `collectionId`, `bookNumber`, `chapterNumber`, `hadithNumber`, `arabicText`, `swahiliTranslation`, `englishTranslation`, `grade` (sahih/hasan/daif), `narrator`, `isnadChain`, `relatedHadithIds` (List), `quranRefs` (List). `_parseInt`.
- **HadithCollection** — `id`, `name`, `nameArabic`, `compiler`, `hadithCount`, `bookCount`, `coverUrl`. `_parseInt`.
- **HadithBook** — `id`, `collectionId`, `number`, `name`, `nameSwahili`, `hadithCount`. `_parseInt`.
- **HadithTopic** — `id`, `name`, `nameSwahili`, `iconName`, `hadithCount`. `_parseInt`.
- **ReadingProgress** — `collectionId`, `booksRead`, `totalBooks`, `lastReadHadithId`. `_parseInt`.

### Service Layer
```dart
Dio get _dio => AuthenticatedDio.instance;
```
- `getCollections()` — `GET /api/hadith/collections`
- `getBooks(int collectionId)` — `GET /api/hadith/collections/{id}/books`
- `getHadiths(int bookId, {int page})` — `GET /api/hadith/books/{id}/hadiths`
- `getHadith(int id)` — `GET /api/hadith/{id}`
- `searchHadiths(String query)` — `GET /api/hadith/search?q={query}`
- `getTopics()` — `GET /api/hadith/topics`
- `getHadithsByTopic(int topicId)` — `GET /api/hadith/topics/{id}/hadiths`
- `getDailyHadith()` — `GET /api/hadith/daily`
- `getFortyNawawi()` — `GET /api/hadith/forty-nawawi`
- `toggleFavorite(int hadithId)` — `POST /api/hadith/{id}/favorite`
- `getFavorites()` — `GET /api/hadith/favorites`
- `getProgress()` — `GET /api/hadith/progress`

### Pages
- **HadithHomePage** — Daily hadith card, continue reading, favorites count
- **CollectionsBrowserPage** — Six collection covers with hadith count and progress
- **BookChapterPage** — Books within a collection, then chapters
- **HadithDetailPage** — Arabic, translation, grading, narrator chain, related, share
- **TopicBrowserPage** — Thematic categories with icons
- **SearchResultsPage** — Matching hadith with collection source and grading badge
- **FavoritesLibraryPage** — Saved hadith by collection or custom tags
- **FortyNawawiPage** — All 40 hadith with commentary
- **ReadingTrackerPage** — Collection and book completion progress

### Widgets
- `GradingBadge` — Color-coded badge: green (sahih), amber (hasan), red (daif)
- `NarratorChain` — Expandable isnad chain display

---

## 2. UI Design
- #1A1A1A/#666666/#FAFAFA/#FFFFFF monochromatic
- 48dp touch, maxLines+ellipsis, _rounded icons
- Dark stat cards for hadith read and collections progress
- Cards: radius 12-16, subtle shadow

### Main Screen Wireframe
```
┌─────────────────────────────┐
│ ← Hadith               🔍   │
├─────────────────────────────┤
│ ┌─────────────────────────┐ │
│ │ Daily Hadith            │ │
│ │ عن أبي هريرة رضي الله   │ │
│ │ "Actions are judged..." │ │
│ │ Bukhari #1  [Sahih] 🟢  │ │
│ │              [Share]    │ │
│ └─────────────────────────┘ │
│                             │
│  Collections                │
│ ┌──────┐┌──────┐┌──────┐   │
│ │Bukhar││Muslim││Abu D.│   │
│ │2602  ││3033  ││5274  │   │
│ └──────┘└──────┘└──────┘   │
│ ┌──────┐┌──────┐┌──────┐   │
│ │Tirmid││Nasai ││Ibn M.│   │
│ │3956  ││5758  ││4341  │   │
│ └──────┘└──────┘└──────┘   │
│                             │
│  Topics                     │
│ [Prayer][Fasting][Charity]  │
│                             │
│  [40 Nawawi] [⭐ Favorites] │
└─────────────────────────────┘
```

---

## 3. Performance Strategy

### SQLite
```sql
CREATE TABLE hadiths(id INTEGER PRIMARY KEY, collection_id INTEGER, book_number INTEGER, arabic_text TEXT, swahili TEXT, grade TEXT, json_data TEXT, synced_at TEXT);
CREATE TABLE hadith_favorites(id INTEGER PRIMARY KEY, hadith_id INTEGER, user_id INTEGER, synced_at TEXT);
CREATE INDEX idx_hadiths_collection ON hadiths(collection_id, book_number);
CREATE INDEX idx_hadiths_grade ON hadiths(grade);
```
- Stale-while-revalidate: SQLite first, API background
- TTL: hadith text — infinite (static), favorites — 1 hour
- Offline: read YES (downloaded collections), write favorites via pending_queue

---

## 4. Backend Implementation

### Database
```sql
CREATE TABLE hadith_collections(id BIGSERIAL PRIMARY KEY, name VARCHAR(100), name_arabic VARCHAR(100), compiler VARCHAR(200), hadith_count INTEGER, book_count INTEGER, cover_url VARCHAR(500));

CREATE TABLE hadith_books(id BIGSERIAL PRIMARY KEY, collection_id BIGINT, book_number INTEGER, name VARCHAR(200), name_swahili VARCHAR(200), hadith_count INTEGER);

CREATE TABLE hadiths(id BIGSERIAL PRIMARY KEY, collection_id BIGINT, book_id BIGINT, hadith_number INTEGER, arabic_text TEXT, swahili_translation TEXT, english_translation TEXT, grade VARCHAR(10), narrator VARCHAR(200), isnad_chain TEXT, related_ids JSONB, quran_refs JSONB);

CREATE TABLE hadith_topics(id BIGSERIAL PRIMARY KEY, name VARCHAR(100), name_swahili VARCHAR(100), icon_name VARCHAR(50), hadith_count INTEGER DEFAULT 0);

CREATE TABLE hadith_topic_map(hadith_id BIGINT, topic_id BIGINT, PRIMARY KEY(hadith_id, topic_id));

CREATE TABLE hadith_favorites(id BIGSERIAL PRIMARY KEY, user_id BIGINT, hadith_id BIGINT, created_at TIMESTAMP DEFAULT NOW(), UNIQUE(user_id, hadith_id));

CREATE TABLE hadith_reading_progress(id BIGSERIAL PRIMARY KEY, user_id BIGINT, collection_id BIGINT, books_read INTEGER DEFAULT 0, last_read_hadith_id BIGINT, updated_at TIMESTAMP DEFAULT NOW(), UNIQUE(user_id, collection_id));
```

### API Endpoints
| Method | Endpoint | Description | Auth |
|--------|----------|-------------|------|
| GET | /api/hadith/collections | List collections | Bearer |
| GET | /api/hadith/collections/{id}/books | Books in collection | Bearer |
| GET | /api/hadith/books/{id}/hadiths | Hadiths in book | Bearer |
| GET | /api/hadith/{id} | Hadith detail | Bearer |
| GET | /api/hadith/search | Full-text search | Bearer |
| GET | /api/hadith/topics | Browse topics | Bearer |
| GET | /api/hadith/topics/{id}/hadiths | Hadiths by topic | Bearer |
| GET | /api/hadith/daily | Daily hadith | Bearer |
| GET | /api/hadith/forty-nawawi | 40 Nawawi | Bearer |
| POST | /api/hadith/{id}/favorite | Toggle favorite | Bearer |
| GET | /api/hadith/favorites | User favorites | Bearer |

### Controller
`app/Http/Controllers/Api/HadithController.php` — DB facade with full-text search, grading filters, and topic mapping.

---

## 5. Integration Wiring
- **PostService** — share hadith cards to feed with #HadithOfTheDay
- **MessageService** — send hadith in chat and mosque groups
- **NotificationService** — daily hadith push notification
- **Quran** — hadith explaining Quran verses link to reader
- **Dua** — prophetic duas link to source hadith
- **Ramadan** — Ramadan-specific hadith highlighted
- **Kalenda Hijri** — occasion-relevant hadith on Islamic dates
- Full offline support via LocalStorageService

---

## 6. Implementation Phases
### Phase 1: Foundation (Week 1)
- Data models, service layer, SQLite schema
- Hadith data import (6 major collections)
- Backend tables and CRUD

### Phase 2: Core UI (Week 2)
- Collections browser with covers
- Book/chapter navigation
- Hadith detail with grading badge

### Phase 3: Integration (Week 3)
- Topic-based browsing
- Search across all collections
- Daily hadith and 40 Nawawi

### Phase 4: Polish (Week 4)
- Favorites with tags
- Reading progress tracker
- Offline download, share cards

---

## 7. External APIs & Integrations

| API | Provider | Purpose | Pricing | Integration Notes |
|-----|----------|---------|---------|-------------------|
| Sunnah.com API | Sunnah.com | Official hadith API; Bukhari, Muslim, Abu Dawud, etc. | Free (API key) | Request key via GitHub; sunnah.stoplight.io; comprehensive collections |
| HadithAPI.com | HadithAPI | Hadith search and retrieval | Free | hadithapi.com; REST API with JSON |
| Hadith Dart Package | pub.dev | Dart package for hadith data | Free | Direct Flutter integration; pub.dev/packages/hadith |
| Al Quran Cloud (Hadith) | alquran.cloud | Hadith editions alongside Quran | Free, no auth | Limited hadith content; primarily Quran-focused |

### Flutter Packages
- `hadith` — Direct Dart package for hadith data on pub.dev

### Integration Priority
1. **Immediate** — Free APIs (Sunnah.com API -- free API key, most comprehensive hadith source)
2. **Short-term** — Flutter packages (hadith on pub.dev for native Dart integration)
3. **Partnership** — HadithAPI.com (supplementary search and retrieval)
