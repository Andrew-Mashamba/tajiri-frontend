# Katiba (Constitution) — Implementation Plan

## Overview
Mobile-friendly reader for the Constitution of Tanzania (1977, as amended) and Zanzibar Constitution (1984). Features full-text search, plain-language article summaries in Swahili/English, Bill of Rights focus with real-life examples, Know Your Rights guides, amendment history timeline, 2014 draft comparison, bookmarks/highlights, quizzes, audio narration, and offline access.

---

## 1. Frontend Architecture

### Directory Structure
```
lib/katiba/
├── katiba_module.dart
├── models/
│   ├── constitution_models.dart
│   └── quiz_models.dart
├── services/
│   └── katiba_service.dart
├── pages/
│   ├── katiba_home_page.dart
│   ├── chapter_browser_page.dart
│   ├── article_reader_page.dart
│   ├── search_results_page.dart
│   ├── bill_of_rights_page.dart
│   ├── know_your_rights_page.dart
│   ├── amendments_timeline_page.dart
│   ├── quiz_page.dart
│   └── bookmarks_page.dart
└── widgets/
    ├── article_card.dart
    ├── chapter_tile.dart
    ├── rights_card.dart
    ├── highlight_toolbar.dart
    └── quiz_question_widget.dart
```

### Data Models
- `Chapter` — id, number, titleSw, titleEn, parts (list of Part), articleCount
- `Article` — id, number, chapterId, textSw, textEn, summarySw, summaryEn, audioUrl
- `Bookmark` — id, articleId, createdAt, note
- `Highlight` — id, articleId, startOffset, endOffset, color, note
- `Amendment` — id, number, year, description, changedArticles
- `QuizQuestion` — id, questionSw, questionEn, options, correctIndex, explanation

### Service Layer
```dart
Dio get _dio => AuthenticatedDio.instance;
```
| Method | Verb | Endpoint | Return |
|--------|------|----------|--------|
| `getChapters()` | GET | `/api/katiba/chapters` | `PaginatedResult<Chapter>` |
| `getArticle(id)` | GET | `/api/katiba/articles/{id}` | `SingleResult<Article>` |
| `searchArticles(query)` | GET | `/api/katiba/search` | `PaginatedResult<Article>` |
| `getAmendments()` | GET | `/api/katiba/amendments` | `PaginatedResult<Amendment>` |
| `getQuiz(chapterId)` | GET | `/api/katiba/quiz` | `PaginatedResult<QuizQuestion>` |
| `submitQuizScore(data)` | POST | `/api/katiba/quiz/score` | `SingleResult<QuizResult>` |
| `getDailyArticle()` | GET | `/api/katiba/daily` | `SingleResult<Article>` |
| `getGlossary()` | GET | `/api/katiba/glossary` | `PaginatedResult<GlossaryTerm>` |

### Pages
- **KatibaHomePage** — Chapter list, search bar, daily article card, quick links
- **ChapterBrowserPage** — Expandable chapters with article counts
- **ArticleReaderPage** — Clean text with highlight, bookmark, note, share, audio play
- **SearchResultsPage** — Filtered results with context snippets
- **BillOfRightsPage** — Rights cards with real-life examples, violation guides
- **KnowYourRightsPage** — Thematic guides: arrest, work, land, women, children
- **AmendmentsTimelinePage** — Visual timeline of constitutional changes
- **QuizPage** — Multiple choice questions with score tracking

### Widgets
- `ArticleCard` — Article number, title, first line preview, bookmark icon
- `RightsCard` — Right name, icon, brief description, "Learn More" action
- `HighlightToolbar` — Color picker, note, share actions on text selection
- `QuizQuestionWidget` — Question text, radio options, submit, explanation reveal

---

## 2. UI Design
- Palette: #1A1A1A / #666666 / #FAFAFA / #FFFFFF
- Cards: BorderRadius.circular(12-16), subtle shadow
- 48dp touch targets, maxLines+ellipsis, _rounded icons
- Loading: CircularProgressIndicator(strokeWidth: 2, color: _kPrimary)

### Main Screen Wireframe
```
┌─────────────────────────┐
│ ◀  Katiba ya Tanzania   │
├─────────────────────────┤
│ 🔍 Search articles...   │
├─────────────────────────┤
│ 📖 Article of the Day   │
│ ┌─────────────────────┐ │
│ │ Art. 15: Right to   │ │
│ │ Life & Personal...  │ │
│ │ [Read More]         │ │
│ └─────────────────────┘ │
│                         │
│ Chapters                │
│ ├─ 1. The Republic (11)│
│ ├─ 2. Bill of Rights ★ │
│ ├─ 3. Executive (28)   │
│ └─ ...                  │
│                         │
│ [Know Rights] [Quiz]    │
│ [Amendments] [Glossary] │
│ [Bookmarks]             │
└─────────────────────────┘
```

---

## 3. Performance Strategy

### SQLite Local Storage
```sql
CREATE TABLE katiba_articles(id INTEGER PRIMARY KEY, chapter_id INTEGER, number INTEGER, json_data TEXT, synced_at TEXT);
CREATE INDEX idx_katiba_articles_chapter ON katiba_articles(chapter_id);

CREATE TABLE katiba_bookmarks(id INTEGER PRIMARY KEY, article_id INTEGER, note TEXT, json_data TEXT, synced_at TEXT);
CREATE TABLE katiba_highlights(id INTEGER PRIMARY KEY, article_id INTEGER, json_data TEXT, synced_at TEXT);
```

### Caching
- Load from SQLite first (<5ms) then API background refresh
- TTL: Constitution text 30d (rarely changes), quiz 7d, daily article 24h
- Offline read: YES — full constitution text, bookmarks, highlights, glossary
- Offline write: pending_queue for quiz scores, bookmarks sync

---

## 4. Backend Implementation

### Database (PostgreSQL)
```sql
CREATE TABLE katiba_chapters (
    id BIGSERIAL PRIMARY KEY, number INTEGER NOT NULL,
    title_sw TEXT NOT NULL, title_en TEXT NOT NULL,
    created_at TIMESTAMP DEFAULT NOW()
);

CREATE TABLE katiba_articles (
    id BIGSERIAL PRIMARY KEY, chapter_id BIGINT REFERENCES katiba_chapters(id),
    number INTEGER NOT NULL, text_sw TEXT NOT NULL, text_en TEXT NOT NULL,
    summary_sw TEXT, summary_en TEXT, audio_url TEXT,
    created_at TIMESTAMP DEFAULT NOW(), updated_at TIMESTAMP DEFAULT NOW()
);

CREATE TABLE katiba_user_bookmarks (
    id BIGSERIAL PRIMARY KEY, user_id BIGINT REFERENCES users(id),
    article_id BIGINT REFERENCES katiba_articles(id),
    note TEXT, created_at TIMESTAMP DEFAULT NOW()
);
```

### API Endpoints
| Method | Endpoint | Description | Auth |
|--------|----------|-------------|------|
| GET | /api/katiba/chapters | All chapters | No |
| GET | /api/katiba/articles/{id} | Single article | No |
| GET | /api/katiba/search | Full-text search | No |
| GET | /api/katiba/amendments | Amendment history | No |
| GET | /api/katiba/quiz | Quiz questions | Yes |
| POST | /api/katiba/quiz/score | Submit quiz score | Yes |
| GET | /api/katiba/daily | Daily article | No |
| GET | /api/katiba/glossary | Legal glossary | No |

### Controller
- `app/Http/Controllers/Api/KatibaController.php`
- DB facade, try/catch, `{"success": true/false, "data": ..., "message": "..."}`

---

## 5. Integration Wiring
- **MessageService** — Share articles in TAJIRI chats with rich preview
- **PostService** — Daily constitutional article posts and awareness content
- **NotificationService + FCMService** — Daily article of the day push notifications
- **LocalStorageService** — Full offline constitution text, bookmarks, highlights
- **MediaCacheService** — Audio article versions for offline listening
- **ProfileService** — "Constitutional Scholar" badges from quiz completion
- **Cross-module: legal_gpt** — AI explains constitutional provisions in context
- **Cross-module: barozi_wangu** — Government structure understanding at ward level

---

## 6. Implementation Phases
### Phase 1: Foundation (Week 1)
- Data models, service layer, SQLite schema, seed constitution data
- Chapter browser and article reader with font controls

### Phase 2: Core UI (Week 2)
- Search with highlighting, Bill of Rights section, bookmarks/highlights
- Know Your Rights themed guides

### Phase 3: Integration (Week 3)
- Quiz system with scoring and badges, daily article FCM push
- Share articles via MessageService, PostService

### Phase 4: Polish (Week 4)
- Audio narration player, amendments timeline, 2014 draft comparison
- Full offline download, glossary, dark mode reader

---

## 7. External APIs & Integrations

| API | Provider | Purpose | Pricing | Integration Notes |
|-----|----------|---------|---------|-------------------|
| Laws.Africa Content API | Laws.Africa / Open Law Africa | Tanzania Constitution & legislation in Akoma Ntoso XML | Free (non-commercial) | laws.africa/api/ — structured legal data, supports RAG workflows |
| Laws.Africa Knowledge Base API | Laws.Africa | Legal data retrieval for search and AI features | Free (non-commercial), paid commercial | developers.laws.africa/ai-api/knowledge-bases |
| SAFLII | Southern African Legal Information Institute | Tanzania case law and legislation from 16 countries | Free | saflii.org — includes Tanzania court decisions |
| OpenLaws API | OpenLaws | Legislation data for legal tech | Paid (contact) | openlaws.us/api/ — primarily US law, reference only |
| CourtListener API | Free Law Project | Case law and court opinions reference | Free (non-profit) | courtlistener.com/help/api/ — US-focused |

### Integration Priority
1. **Immediate** — Laws.Africa Content API (free, has Tanzania Constitution in machine-readable format), SAFLII (free, Tanzania case law)
2. **Short-term** — Laws.Africa Knowledge Base API for AI-powered search and article cross-referencing
3. **Partnership** — Tanzania Law Reform Commission for authoritative amendment data, Parliament of Tanzania for bill tracking
