# Past Papers / Mitihani ya Zamani — Implementation Plan

## Overview
Centralized past exam paper repository serving all education levels (PSLE through Masters). Browse by level, subject, year, and institution. Features in-app PDF viewer, marking schemes, community-contributed worked solutions, difficulty ratings, practice mode with timer, topic-based browsing, and contributor rewards. Targets both NECTA national exams and university papers.

---

## 1. Frontend Architecture

### Directory Structure
```
lib/past_papers/
├── past_papers_module.dart
├── models/
│   ├── past_paper.dart
│   ├── marking_scheme.dart
│   ├── paper_discussion.dart
│   └── paper_request.dart
├── services/
│   └── past_papers_service.dart     — AuthenticatedDio.instance
├── pages/
│   ├── past_papers_home_page.dart
│   ├── subject_browser_page.dart
│   ├── paper_list_page.dart
│   ├── paper_viewer_page.dart
│   ├── marking_scheme_page.dart
│   ├── upload_paper_page.dart
│   ├── my_library_page.dart
│   ├── discussion_page.dart
│   ├── paper_request_page.dart
│   └── contributor_dashboard_page.dart
└── widgets/
    ├── paper_card.dart
    ├── level_chip.dart
    ├── difficulty_badge.dart
    ├── filter_sheet.dart
    ├── practice_timer.dart
    └── contributor_badge.dart
```

### Data Models
```dart
class PastPaper {
  final int id, uploaderId;
  final String title, subject, level;     // primary, form4, form6, diploma, degree, masters
  final String? institution, examType;    // mid_semester, end_semester, supplementary, necta, mock
  final int year;
  final String fileUrl;
  final String? markingSchemeUrl;
  final String difficulty;                // easy, medium, hard
  final int downloadCount, viewCount;
  final double avgDifficulty;
  factory PastPaper.fromJson(Map<String, dynamic> j) => PastPaper(
    id: _parseInt(j['id']),
    title: j['title'] ?? '',
    subject: j['subject'] ?? '',
    level: j['level'] ?? '',
    year: _parseInt(j['year']),
    fileUrl: j['file_url'] ?? '',
    downloadCount: _parseInt(j['download_count']),
  );
}

class MarkingScheme { int id, paperId; String fileUrl; String type; } // official, community, ai_generated
class PaperDiscussion { int id, paperId; String body, authorName; DateTime createdAt; }
class PaperRequest { int id; String subject, level, description; int year; bool fulfilled; }
```

### Service Layer
```dart
class PastPapersService {
  static Future<List<PastPaper>> getPapers(String token, {String? level, String? subject, int? year, String? institution}); // GET /api/past-papers
  static Future<PastPaper> getPaperDetail(String token, int id);               // GET /api/past-papers/{id}
  static Future<void> downloadPaper(String token, int id);                     // GET /api/past-papers/{id}/download
  static Future<void> uploadPaper(String token, File file, Map metadata);      // POST /api/past-papers (multipart)
  static Future<void> rateDifficulty(String token, int id, String difficulty);  // POST /api/past-papers/{id}/rate
  static Future<void> bookmarkPaper(String token, int id);                     // POST /api/past-papers/{id}/bookmark
  static Future<List<PaperDiscussion>> getDiscussion(String token, int id);    // GET /api/past-papers/{id}/discussion
  static Future<void> postComment(String token, int id, Map body);             // POST /api/past-papers/{id}/discussion
  static Future<List<PaperRequest>> getRequests(String token);                 // GET /api/past-papers/requests
  static Future<void> createRequest(String token, Map body);                   // POST /api/past-papers/requests
  static Future<List<PastPaper>> getBookmarked(String token);                  // GET /api/past-papers/bookmarked
  static Future<List<PastPaper>> getMyLibrary(String token);                   // GET /api/past-papers/library (downloaded)
}
```

### Pages & Widgets
- **PastPapersHomePage**: browse by level (chips), popular subjects, recently added papers
- **SubjectBrowserPage**: grid of subjects with paper counts, filter chips for year/level/institution
- **PaperListPage**: filtered list with year, type, difficulty rating, download count
- **PaperViewerPage**: full-screen PDF viewer with download, bookmark, share, discuss toolbar
- **MarkingSchemePage**: side-by-side or tabbed view with question paper and marking scheme
- **UploadPaperPage**: multi-step — upload file, tag metadata (level, subject, year, institution, type)
- **MyLibraryPage**: downloaded papers organized by subject with local search

---

## 2. UI Design
- Monochromatic: #1A1A1A / #666666 / #FAFAFA / #FFFFFF
- 48dp touch targets, maxLines + ellipsis, _rounded icons
- Level chips color-coded subtly (NECTA = slight accent, University = default)
- Dark hero card: "234 NECTA papers available" with popular subjects

### Main Screen Wireframe
```
┌──────────────────────────────┐
│  Past Papers         [🔍 ↑] │
├──────────────────────────────┤
│ [NECTA] [University] [All]   │
├──────────────────────────────┤
│ POPULAR SUBJECTS             │
│ ┌──────┐ ┌──────┐ ┌──────┐  │
│ │ Math │ │Physic│ │ Chem │  │
│ │ 156  │ │  98  │ │  87  │  │
│ └──────┘ └──────┘ └──────┘  │
│                              │
│ RECENTLY ADDED               │
│ ┌──────────────────────────┐ │
│ │ CSEE Mathematics 2025    │ │
│ │ NECTA · Hard · 234 ↓    │ │
│ ├──────────────────────────┤ │
│ │ CS201 End-Sem 2025       │ │
│ │ UDSM · Medium · 45 ↓   │ │
│ └──────────────────────────┘ │
│                              │
│ REQUESTS (5 open)            │
│ ┌──────────────────────────┐ │
│ │ Need PHY Form6 2024      │ │
│ └──────────────────────────┘ │
└──────────────────────────────┘
```

---

## 3. Performance Strategy

### SQLite
```sql
CREATE TABLE past_papers(id INTEGER PRIMARY KEY, subject TEXT, level TEXT, year INTEGER, institution TEXT, json_data TEXT, synced_at TEXT);
CREATE INDEX idx_pp_subject ON past_papers(subject);
CREATE INDEX idx_pp_level ON past_papers(level);
CREATE INDEX idx_pp_year ON past_papers(year);

CREATE TABLE paper_downloads(id INTEGER PRIMARY KEY, paper_id INTEGER, local_path TEXT, downloaded_at TEXT);
CREATE TABLE paper_bookmarks(id INTEGER PRIMARY KEY, paper_id INTEGER, created_at TEXT);
```
- SQLite first, API background refresh (stale-while-revalidate)
- Offline read: YES — downloaded papers with local search
- Offline write: pending_queue for uploads, ratings, comments

---

## 4. Backend Implementation

### Database (PostgreSQL)
```sql
CREATE TABLE past_papers(
  id SERIAL PRIMARY KEY, uploader_id INT REFERENCES users(id),
  title VARCHAR(255), subject VARCHAR(255), level VARCHAR(30),
  year SMALLINT, institution VARCHAR(255), exam_type VARCHAR(30),
  file_url TEXT, file_size BIGINT,
  marking_scheme_url TEXT, difficulty VARCHAR(10),
  download_count INT DEFAULT 0, view_count INT DEFAULT 0,
  status VARCHAR(20) DEFAULT 'pending',  -- pending, approved, rejected
  created_at TIMESTAMP DEFAULT NOW()
);
CREATE TABLE paper_difficulty_votes(
  id SERIAL PRIMARY KEY, paper_id INT REFERENCES past_papers(id),
  user_id INT REFERENCES users(id), difficulty VARCHAR(10),
  UNIQUE(paper_id, user_id)
);
CREATE TABLE paper_discussions(
  id SERIAL PRIMARY KEY, paper_id INT REFERENCES past_papers(id),
  user_id INT REFERENCES users(id), body TEXT, created_at TIMESTAMP DEFAULT NOW()
);
CREATE TABLE paper_bookmarks(
  id SERIAL PRIMARY KEY, paper_id INT REFERENCES past_papers(id),
  user_id INT REFERENCES users(id), UNIQUE(paper_id, user_id)
);
CREATE TABLE paper_requests(
  id SERIAL PRIMARY KEY, requester_id INT REFERENCES users(id),
  subject VARCHAR(255), level VARCHAR(30), year SMALLINT,
  description TEXT, fulfilled BOOLEAN DEFAULT FALSE,
  created_at TIMESTAMP DEFAULT NOW()
);
```

### API Endpoints
| Method | Endpoint | Description | Auth |
|--------|----------|-------------|------|
| GET | /api/past-papers | List with filters | Bearer |
| POST | /api/past-papers | Upload paper (multipart) | Bearer |
| GET | /api/past-papers/{id} | Paper detail | Bearer |
| GET | /api/past-papers/{id}/download | Download file | Bearer |
| POST | /api/past-papers/{id}/rate | Rate difficulty | Bearer |
| POST | /api/past-papers/{id}/bookmark | Bookmark | Bearer |
| GET | /api/past-papers/{id}/discussion | Discussion thread | Bearer |
| POST | /api/past-papers/{id}/discussion | Post comment | Bearer |
| GET | /api/past-papers/requests | Paper requests | Bearer |
| POST | /api/past-papers/requests | Create request | Bearer |
| GET | /api/past-papers/bookmarked | User's bookmarks | Bearer |

### Controller
`app/Http/Controllers/Api/PastPapersController.php`

---

## 5. Integration Wiring
- exam_prep module — past paper questions feed into quiz mode and flashcard generation
- newton module — AI generates worked solutions, explains step-by-step
- class_notes module — link relevant notes to past paper topics
- study_groups module — groups discuss papers with shared viewer and timed practice
- class_chat module — share papers in class channels for discussion
- career module — professional exam past papers (CPA, ACCA) for career advancement
- ClipService — video solutions for past paper questions
- WalletService — purchase premium worked solutions

---

## 6. Implementation Phases

### Phase 1 — Core Browse/Download (Week 1-2)
- [ ] PastPaper model, service, SQLite cache
- [ ] Past papers home with level browsing
- [ ] Subject browser with paper counts
- [ ] Paper list with filters (level, subject, year, institution)

### Phase 2 — Viewing & Library (Week 3)
- [ ] In-app PDF viewer with toolbar
- [ ] Download for offline access
- [ ] My Library page with local search
- [ ] Bookmark functionality

### Phase 3 — Community (Week 4)
- [ ] Upload paper with metadata tagging
- [ ] Quality moderation workflow (pending/approved)
- [ ] Difficulty rating and voting
- [ ] Discussion threads per paper
- [ ] Paper request board

### Phase 4 — Advanced (Week 5-6)
- [ ] Marking scheme viewer (side-by-side)
- [ ] Practice mode with timer
- [ ] Topic-based browsing across years
- [ ] Contributor dashboard with badges
- [ ] AI-powered similar question finder (Newton)

---

## 7. External APIs & Integrations

| API | Provider | Purpose | Pricing | Integration Notes |
|-----|----------|---------|---------|-------------------|
| NECTA API (unofficial) | Community (Vincent Laizer) | Fetch CSEE/ACSEE results from NECTA | Free (open-source, PyPI: `nectaapi`) | Python package scraping necta.go.tz. Supports school lists, student results, performance comparisons. **Not official -- fragile, depends on HTML structure.** |
| NECTA Results Scraper (PHP) | Community (AlexLeoTz) | Scrape NECTA student results | Free (open-source) | PHP alternative. GitHub: AlexLeoTz/necta-results-scraper. |
| NECTA Website | NECTA (necta.go.tz) | Official results portal | Free (web scraping) | No official API. Results at matokeo.necta.go.tz. Would need custom scraper for past papers. |
| Anthropic Claude API | Anthropic | AI-generated worked solutions, similar question finder | Already in TAJIRI backend | Route through Newton AI service for step-by-step solutions to past paper questions. |

**Tanzania context:** NECTA has NO official API. Community packages scrape HTML results pages. For past papers, build a custom archive with PDFs sourced from NECTA publications. Consider partnering with NECTA for official data access. Backend scraper using `nectaapi` (PyPI) can feed data to TAJIRI API.

### Integration Priority
1. **Immediate** -- Community `nectaapi` Python package (free, backend scraper for NECTA results), Anthropic Claude API (already in backend, for AI worked solutions)
2. **Short-term** -- Custom NECTA past paper PDF scraper (build backend service to archive papers from necta.go.tz)
3. **Partnership** -- NECTA official data access (formal partnership for reliable API access to exam papers and results)
