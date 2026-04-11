# Library / Maktaba — Implementation Plan

## Overview
Digital library with e-book catalog, in-app reader, research paper search, citation generator, course reading lists, and offline downloads. Features book borrowing (time-limited), OER collection (OpenStax, MIT OCW), dissertation repository, reading progress tracking, book reviews, physical library QR card, and book availability checker.

---

## 1. Frontend Architecture

### Directory Structure
```
lib/library/
├── library_module.dart
├── models/
│   ├── book.dart
│   ├── reading_list.dart
│   ├── research_paper.dart
│   ├── citation.dart
│   └── book_review.dart
├── services/
│   └── library_service.dart         — AuthenticatedDio.instance
├── pages/
│   ├── library_home_page.dart
│   ├── book_detail_page.dart
│   ├── e_reader_page.dart
│   ├── search_results_page.dart
│   ├── my_bookshelf_page.dart
│   ├── reading_lists_page.dart
│   ├── research_papers_page.dart
│   ├── citation_generator_page.dart
│   ├── physical_library_page.dart
│   └── book_request_page.dart
└── widgets/
    ├── book_card.dart
    ├── book_cover.dart
    ├── reading_progress_bar.dart
    ├── review_card.dart
    ├── citation_tile.dart
    ├── category_chip.dart
    └── reading_list_tile.dart
```

### Data Models
```dart
class Book {
  final int id;
  final String title, author, category;
  final String? isbn, description, coverUrl, fileUrl;
  final String format;            // epub, pdf
  final double avgRating;
  final int reviewCount, pageCount;
  final bool borrowed, downloaded;
  final DateTime? borrowExpiry;
  factory Book.fromJson(Map<String, dynamic> j) => Book(
    id: _parseInt(j['id']),
    title: j['title'] ?? '',
    author: j['author'] ?? '',
    category: j['category'] ?? '',
    format: j['format'] ?? 'pdf',
    avgRating: _parseDouble(j['avg_rating']) ?? 0,
    reviewCount: _parseInt(j['review_count']),
    pageCount: _parseInt(j['page_count']),
  );
}

class ReadingList { int id; String name; int? classId; List<Book> books; int completedCount; }
class ResearchPaper { int id; String title, authors, journal, abstractText; int year, citationCount; String? url; bool openAccess; }
class Citation { String formatted; String style; }  // apa, mla, harvard, chicago
class BookReview { int id, bookId; int stars; String? review; String reviewerName; DateTime createdAt; }
```

### Service Layer
```dart
class LibraryService {
  static Future<List<Book>> getBooks(String token, {String? category, String? query}); // GET /api/library/books
  static Future<Book> getBookDetail(String token, int id);                     // GET /api/library/books/{id}
  static Future<void> borrowBook(String token, int id);                        // POST /api/library/books/{id}/borrow
  static Future<String> downloadBook(String token, int id);                    // GET /api/library/books/{id}/download
  static Future<void> reviewBook(String token, int id, int stars, String? r);  // POST /api/library/books/{id}/review
  static Future<List<ReadingList>> getReadingLists(String token);              // GET /api/library/reading-lists
  static Future<List<ResearchPaper>> searchPapers(String token, String query); // GET /api/library/papers?q=
  static Future<Citation> generateCitation(String token, int bookId, String style); // GET /api/library/books/{id}/cite?style=
  static Future<List<Book>> getMyBookshelf(String token);                      // GET /api/library/bookshelf
  static Future<void> updateProgress(String token, int id, int page);          // PUT /api/library/books/{id}/progress
  static Future<void> requestBook(String token, Map body);                     // POST /api/library/requests
}
```

### Pages & Widgets
- **LibraryHomePage**: search bar, featured books, course reading lists, recently viewed, category grid
- **BookDetailPage**: cover, title, author, description, reviews, borrow/download, citation button
- **EReaderPage**: full-screen reading with adjustable font, night mode, bookmarks, highlights, notes
- **SearchResultsPage**: filtered list with cover thumbnails, relevance sort, format indicators
- **MyBookshelfPage**: downloaded and borrowed books with reading progress indicators
- **ReadingListsPage**: course-organized lists with completion checkboxes
- **ResearchPapersPage**: paper search with abstract preview, citation count, access type
- **CitationGeneratorPage**: select books, choose style (APA/MLA/Harvard), copy or export
- **PhysicalLibraryPage**: campus map, hours, QR library card, book availability

---

## 2. UI Design
- Monochromatic: #1A1A1A / #666666 / #FAFAFA / #FFFFFF
- 48dp touch targets, maxLines + ellipsis, _rounded icons
- Book cards show cover image, title (2-line max), author, rating stars
- Dark hero card: "Currently Reading" with book cover, title, progress bar

### Main Screen Wireframe
```
┌──────────────────────────────┐
│  Library             [🔍]   │
├──────────────────────────────┤
│ ┌──────────────────────────┐ │
│ │ Currently Reading         │ │
│ │ 📚 Data Structures in C  │ │
│ │ ████████░░ 72% · pg 245  │ │
│ └──────────────────────────┘ │
│                              │
│ COURSE READING LISTS         │
│ CS201 (3/5) · MA101 (1/4)   │
│                              │
│ CATEGORIES                   │
│ ┌──────┐ ┌──────┐ ┌──────┐  │
│ │Scienc│ │ Arts │ │Engine│  │
│ │  234 │ │  156 │ │  189 │  │
│ └──────┘ └──────┘ └──────┘  │
│                              │
│ RECENTLY ADDED               │
│ ┌──────────────────────────┐ │
│ │ [img] Algorithms 4th Ed  │ │
│ │       ★★★★☆  Free        │ │
│ ├──────────────────────────┤ │
│ │ [img] Organic Chemistry  │ │
│ │       ★★★★★  Borrow      │ │
│ └──────────────────────────┘ │
└──────────────────────────────┘
```

---

## 3. Performance Strategy

### SQLite
```sql
CREATE TABLE books(id INTEGER PRIMARY KEY, title TEXT, author TEXT, category TEXT, avg_rating REAL, json_data TEXT, synced_at TEXT);
CREATE INDEX idx_books_category ON books(category);

CREATE TABLE book_downloads(id INTEGER PRIMARY KEY, book_id INTEGER, local_path TEXT, current_page INTEGER, total_pages INTEGER, downloaded_at TEXT);
CREATE TABLE reading_lists(id INTEGER PRIMARY KEY, name TEXT, class_id INTEGER, json_data TEXT, synced_at TEXT);
CREATE TABLE bookmarks(id INTEGER PRIMARY KEY, book_id INTEGER, page INTEGER, note TEXT);
```
- SQLite first, API background refresh (stale-while-revalidate)
- Offline read: YES — downloaded books fully readable offline
- Offline write: pending_queue for progress updates, reviews, bookmarks

---

## 4. Backend Implementation

### Database (PostgreSQL)
```sql
CREATE TABLE library_books(
  id SERIAL PRIMARY KEY, title VARCHAR(255), author VARCHAR(255),
  isbn VARCHAR(20), category VARCHAR(100), description TEXT,
  cover_url TEXT, file_url TEXT, format VARCHAR(10),
  page_count INT, avg_rating DECIMAL(2,1) DEFAULT 0,
  review_count INT DEFAULT 0, is_oer BOOLEAN DEFAULT FALSE,
  created_at TIMESTAMP DEFAULT NOW()
);
CREATE TABLE book_borrows(
  id SERIAL PRIMARY KEY, book_id INT REFERENCES library_books(id),
  user_id INT REFERENCES users(id), borrowed_at TIMESTAMP DEFAULT NOW(),
  expires_at TIMESTAMP, returned_at TIMESTAMP
);
CREATE TABLE book_reviews(
  id SERIAL PRIMARY KEY, book_id INT REFERENCES library_books(id),
  user_id INT REFERENCES users(id), stars SMALLINT CHECK(stars BETWEEN 1 AND 5),
  review TEXT, created_at TIMESTAMP DEFAULT NOW(), UNIQUE(book_id, user_id)
);
CREATE TABLE reading_progress(
  id SERIAL PRIMARY KEY, book_id INT REFERENCES library_books(id),
  user_id INT REFERENCES users(id), current_page INT, total_pages INT,
  updated_at TIMESTAMP DEFAULT NOW(), UNIQUE(book_id, user_id)
);
CREATE TABLE reading_lists(
  id SERIAL PRIMARY KEY, name VARCHAR(255),
  classroom_id INT REFERENCES classrooms(id),
  user_id INT REFERENCES users(id), created_at TIMESTAMP DEFAULT NOW()
);
CREATE TABLE reading_list_books(
  id SERIAL PRIMARY KEY, list_id INT REFERENCES reading_lists(id),
  book_id INT REFERENCES library_books(id), completed BOOLEAN DEFAULT FALSE
);
CREATE TABLE book_requests(
  id SERIAL PRIMARY KEY, user_id INT REFERENCES users(id),
  title VARCHAR(255), author VARCHAR(255), justification TEXT,
  status VARCHAR(20) DEFAULT 'pending', created_at TIMESTAMP DEFAULT NOW()
);
```

### API Endpoints
| Method | Endpoint | Description | Auth |
|--------|----------|-------------|------|
| GET | /api/library/books | Browse/search books | Bearer |
| GET | /api/library/books/{id} | Book detail | Bearer |
| POST | /api/library/books/{id}/borrow | Borrow e-book | Bearer |
| GET | /api/library/books/{id}/download | Download file | Bearer |
| POST | /api/library/books/{id}/review | Rate and review | Bearer |
| GET | /api/library/books/{id}/cite | Generate citation | Bearer |
| PUT | /api/library/books/{id}/progress | Update reading progress | Bearer |
| GET | /api/library/bookshelf | User's borrowed/downloaded | Bearer |
| GET | /api/library/reading-lists | Course reading lists | Bearer |
| GET | /api/library/papers | Search research papers | Bearer |
| POST | /api/library/requests | Request book acquisition | Bearer |

### Controller
`app/Http/Controllers/Api/LibraryController.php`

---

## 5. Integration Wiring
- PostService — share book recommendations and reviews to feed
- MessageService — share books via TAJIRI chat
- WalletService — purchase premium e-books via M-Pesa
- CalendarService — book return deadlines and book club sessions synced
- GroupService — book clubs as TAJIRI groups with integrated chat
- class_notes module — highlights from books exported to notes
- newton module — "Explain this passage" from within e-reader
- assignments module — reading lists linked to assignments; cite books in work
- study_groups module — shared reading lists within study groups
- my_class module — lecturer-assigned reading lists in class library

---

## 6. Implementation Phases

### Phase 1 — Catalog & Browsing (Week 1-2)
- [ ] Book model, service, SQLite cache
- [ ] Library home with categories and search
- [ ] Book detail page with cover, description, reviews
- [ ] Search results with filters

### Phase 2 — Reading (Week 3-4)
- [ ] E-reader page (PDF/EPUB) with font, night mode, bookmarks
- [ ] Borrow/download functionality
- [ ] Reading progress tracking
- [ ] My bookshelf with progress indicators

### Phase 3 — Academic Tools (Week 5)
- [ ] Course reading lists (lecturer-assigned)
- [ ] Citation generator (APA, MLA, Harvard, Chicago)
- [ ] Research paper search with abstract preview
- [ ] Book reviews and ratings

### Phase 4 — Advanced (Week 6)
- [ ] OER collection (OpenStax, MIT OCW)
- [ ] Physical library info with QR card
- [ ] Book request system
- [ ] Dissertation repository browsing
- [ ] Audiobook section

---

## 7. External APIs & Integrations

| API | Provider | Purpose | Pricing | Integration Notes |
|-----|----------|---------|---------|-------------------|
| Open Library API | Internet Archive | Book search, covers, metadata (17M+ books) | Free, no API key | Search, Covers, Works/Editions APIs. JSON/YAML/RDF. Extensive catalog. No authentication needed. |
| Google Books API | Google | Book search, previews, metadata | Free (1,000 req/day default) | REST v1. Search by ISBN, title, author. Preview links. Some full-text access. |
| CrossRef API | CrossRef | Academic paper metadata, DOI lookup | Free (public); Polite (free + email) | 180M+ records. Search journals, papers by DOI. Great for citation generation. |
| Semantic Scholar API | Allen Institute | AI-powered academic paper search | Free: 100 req/5 min; API key for higher | 200M+ papers. Citation graphs, SPECTER2 embeddings. Excellent for research discovery. |
| OpenAlex API | OurResearch | Academic paper, author, institution data | Free, no API key | Successor to Microsoft Academic Graph. 250M+ works. Fast, well-documented. No authentication needed. |
| CORE API | Open University | Open access research papers | Free (API key required) | 300M+ metadata records, 40M+ full texts. Aggregates open access research. |
| Library of Congress API | US Library of Congress | Digital collections, cataloging | Free | loc.gov JSON/XML API. Books, maps, manuscripts, audio. |

**Recommendation:** Open Library + Google Books for general books. Semantic Scholar + CrossRef for academic papers. OpenAlex as free academic metadata backbone.

### Integration Priority
1. **Immediate** -- Open Library API (free, no key), Google Books API (free, 1K req/day), OpenAlex API (free, no key), CrossRef API (free public tier), Semantic Scholar API (free, 100 req/5 min)
2. **Short-term** -- CORE API (free with key, 40M+ full-text open access papers)
3. **Partnership** -- JSTOR XML Gateway (requires institutional license), university library system integration
