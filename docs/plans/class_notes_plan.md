# Class Notes / Maelezo — Implementation Plan

## Overview
Centralized notes sharing platform organized by institution, course, and topic. Students upload notes (PDF, images, docs), rate quality, request missing notes, and browse by subject/week. Features OCR search for handwritten notes, contributor leaderboards, collaborative editing, and offline download library.

---

## 1. Frontend Architecture

### Directory Structure
```
lib/class_notes/
├── class_notes_module.dart
├── models/
│   ├── note.dart
│   ├── note_request.dart
│   ├── note_rating.dart
│   └── contributor.dart
├── services/
│   └── class_notes_service.dart     — AuthenticatedDio.instance
├── pages/
│   ├── notes_home_page.dart
│   ├── subject_notes_page.dart
│   ├── upload_notes_page.dart
│   ├── note_viewer_page.dart
│   ├── note_requests_page.dart
│   ├── my_uploads_page.dart
│   ├── my_downloads_page.dart
│   ├── leaderboard_page.dart
│   └── notes_search_page.dart
└── widgets/
    ├── note_card.dart
    ├── rating_stars.dart
    ├── contributor_tile.dart
    ├── request_card.dart
    ├── upload_progress.dart
    └── subject_chip.dart
```

### Data Models
```dart
class Note {
  final int id, uploaderId;
  final String title, subject, courseCode, uploaderName;
  final String? description, weekNumber, topic;
  final String fileUrl, fileType;   // pdf, image, docx, pptx
  final double avgRating;
  final int downloadCount, viewCount, ratingCount;
  final DateTime createdAt;
  factory Note.fromJson(Map<String, dynamic> j) => Note(
    id: _parseInt(j['id']),
    title: j['title'] ?? '',
    subject: j['subject'] ?? '',
    courseCode: j['course_code'] ?? '',
    fileUrl: j['file_url'] ?? '',
    fileType: j['file_type'] ?? 'pdf',
    avgRating: _parseDouble(j['avg_rating']) ?? 0.0,
    downloadCount: _parseInt(j['download_count']),
    viewCount: _parseInt(j['view_count']),
  );
}

class NoteRequest { int id; String subject, description; String requesterName; DateTime createdAt; bool fulfilled; }
class NoteRating { int id, noteId; int stars; String? review; }
class Contributor { int id; String name; int uploadCount; double avgRating; List<String> badges; }
```

### Service Layer
```dart
class ClassNotesService {
  static Future<List<Note>> getNotes(String token, {String? subject, String? week, String? sort}); // GET /api/notes
  static Future<Note> uploadNote(String token, File file, Map metadata);     // POST /api/notes (multipart)
  static Future<Note> getNoteDetail(String token, int id);                   // GET /api/notes/{id}
  static Future<void> rateNote(String token, int id, int stars, String? review); // POST /api/notes/{id}/rate
  static Future<void> downloadNote(String token, int id);                    // GET /api/notes/{id}/download
  static Future<List<NoteRequest>> getRequests(String token);                // GET /api/notes/requests
  static Future<NoteRequest> createRequest(String token, Map body);          // POST /api/notes/requests
  static Future<void> fulfillRequest(String token, int reqId, int noteId);   // POST /api/notes/requests/{id}/fulfill
  static Future<List<Note>> searchNotes(String token, String query);         // GET /api/notes/search?q=
  static Future<List<Contributor>> getLeaderboard(String token);             // GET /api/notes/leaderboard
  static Future<List<Note>> getMyUploads(String token);                      // GET /api/notes/my-uploads
}
```

### Pages & Widgets
- **NotesHomePage**: browse by subject with recently added, most popular, highest rated sections
- **SubjectNotesPage**: all notes for a course, organized by week/topic, sort by rating/date
- **UploadNotesPage**: multi-step — select files, tag subject/week/topic, add description
- **NoteViewerPage**: in-app PDF/image viewer with zoom, page nav, highlight tools
- **NoteRequestsPage**: feed of unfulfilled requests with subject/date filters
- **LeaderboardPage**: top contributors ranked by uploads, ratings, helpfulness

---

## 2. UI Design
- Monochromatic: #1A1A1A / #666666 / #FAFAFA / #FFFFFF
- 48dp touch targets, maxLines + ellipsis, _rounded icons
- Note cards show file type icon, rating stars, download count
- Dark hero card: "Top Contributor This Week" with avatar and stats

### Main Screen Wireframe
```
┌──────────────────────────────┐
│  Notes              [🔍 ↑]  │
├──────────────────────────────┤
│ [CS201] [MA101] [EN100] [+] │
├──────────────────────────────┤
│ RECENTLY ADDED               │
│ ┌──────────────────────────┐ │
│ │ 📄 DSA Week 5 — Trees   │ │
│ │    ★★★★☆  45 downloads   │ │
│ ├──────────────────────────┤ │
│ │ 📸 Calculus Ch.3 Notes   │ │
│ │    ★★★★★  89 downloads   │ │
│ └──────────────────────────┘ │
│                              │
│ REQUESTS (3 open)            │
│ ┌──────────────────────────┐ │
│ │ Need CS201 Week 6 notes  │ │
│ │ on Graph Algorithms      │ │
│ └──────────────────────────┘ │
└──────────────────────────────┘
```

---

## 3. Performance Strategy

### SQLite
```sql
CREATE TABLE notes(id INTEGER PRIMARY KEY, subject TEXT, course_code TEXT, week_number TEXT, avg_rating REAL, json_data TEXT, synced_at TEXT);
CREATE INDEX idx_notes_subject ON notes(course_code);
CREATE INDEX idx_notes_rating ON notes(avg_rating);

CREATE TABLE note_downloads(id INTEGER PRIMARY KEY, note_id INTEGER, local_path TEXT, downloaded_at TEXT);
CREATE TABLE note_requests(id INTEGER PRIMARY KEY, fulfilled INTEGER, json_data TEXT, synced_at TEXT);
```
- SQLite first, API background refresh (stale-while-revalidate)
- Offline read: YES — downloaded notes available offline with local search
- Offline write: pending_queue for uploads (resume on reconnect via Dio chunked)

---

## 4. Backend Implementation

### Database (PostgreSQL)
```sql
CREATE TABLE notes(
  id SERIAL PRIMARY KEY, uploader_id INT REFERENCES users(id),
  title VARCHAR(255), description TEXT, subject VARCHAR(255),
  course_code VARCHAR(50), week_number VARCHAR(20), topic VARCHAR(255),
  file_url TEXT, file_type VARCHAR(20), file_size BIGINT,
  institution VARCHAR(255), semester VARCHAR(50),
  avg_rating DECIMAL(2,1) DEFAULT 0, download_count INT DEFAULT 0,
  view_count INT DEFAULT 0, status VARCHAR(20) DEFAULT 'active',
  created_at TIMESTAMP DEFAULT NOW()
);
CREATE TABLE note_ratings(
  id SERIAL PRIMARY KEY, note_id INT REFERENCES notes(id),
  user_id INT REFERENCES users(id), stars SMALLINT CHECK(stars BETWEEN 1 AND 5),
  review TEXT, created_at TIMESTAMP DEFAULT NOW(), UNIQUE(note_id, user_id)
);
CREATE TABLE note_requests(
  id SERIAL PRIMARY KEY, requester_id INT REFERENCES users(id),
  subject VARCHAR(255), description TEXT,
  fulfilled BOOLEAN DEFAULT FALSE, fulfilled_note_id INT REFERENCES notes(id),
  created_at TIMESTAMP DEFAULT NOW()
);
```

### API Endpoints
| Method | Endpoint | Description | Auth |
|--------|----------|-------------|------|
| GET | /api/notes | List with filters | Bearer |
| POST | /api/notes | Upload note (multipart) | Bearer |
| GET | /api/notes/{id} | Note detail | Bearer |
| GET | /api/notes/{id}/download | Download file | Bearer |
| POST | /api/notes/{id}/rate | Rate note | Bearer |
| GET | /api/notes/search | Full-text + OCR search | Bearer |
| GET | /api/notes/requests | List requests | Bearer |
| POST | /api/notes/requests | Create request | Bearer |
| POST | /api/notes/requests/{id}/fulfill | Fulfill request | Bearer |
| GET | /api/notes/leaderboard | Top contributors | Bearer |
| GET | /api/notes/my-uploads | User's uploads | Bearer |

### Controller
`app/Http/Controllers/Api/ClassNotesController.php`

---

## 5. Integration Wiring
- PhotoService — upload note photos at original quality (no compression)
- my_class module — notes auto-organize by class enrollment
- class_chat module — files shared in chat can be "promoted" to notes repository
- assignments module — link relevant notes to assignments for reference
- exam_prep module — notes feed into flashcard and quiz generation via Newton AI
- newton module — AI summarizes notes, generates questions, explains difficult concepts
- study_groups module — members share and collaborate on notes within group
- past_papers module — link notes to relevant past paper questions

---

## 6. Implementation Phases

### Phase 1 — Core Upload/Browse (Week 1-2)
- [ ] Note model, service, SQLite cache
- [ ] Upload notes with metadata tagging (subject, week, topic)
- [ ] Notes home page with subject browsing
- [ ] Subject notes page with sort/filter

### Phase 2 — Viewing & Rating (Week 3)
- [ ] In-app PDF/image viewer with zoom and navigation
- [ ] Rating system (1-5 stars with review)
- [ ] Download for offline access
- [ ] My downloads library page

### Phase 3 — Community (Week 4)
- [ ] Note requests board (create/fulfill)
- [ ] Contributor leaderboard with badges
- [ ] My uploads dashboard with stats
- [ ] Share notes via messaging/feed

### Phase 4 — Advanced (Week 5)
- [ ] Full-text search (OCR for handwritten)
- [ ] Batch upload for multiple files
- [ ] Version history (better notes for same lecture)
- [ ] Highlight and annotate within viewer
- [ ] Report low-quality notes

---

## 7. External APIs & Integrations

| API | Provider | Purpose | Pricing | Integration Notes |
|-----|----------|---------|---------|-------------------|
| Google ML Kit Text Recognition | Google | On-device OCR for handwritten/printed notes | Free | Flutter package: `google_mlkit_text_recognition ^0.15.0`. Works offline, iOS/Android only. Best option for note scanning. |
| Google Cloud Vision API | Google | Cloud-based OCR with handwriting recognition | Free: 1,000 units/mo; $1.50/1K after | Better accuracy than on-device for complex handwriting. $300 free credits for new users. |
| Tesseract OCR | Open-source | On-device OCR, 100+ languages | Free (open-source) | Flutter packages: `flutter_tesseract_ocr`, `tesseract_ocr`. Slower than ML Kit but fully offline. |
| Mathpix OCR API | Mathpix | Math equation OCR from handwriting | Free: 20 req/mo; $9.99/mo for 1K | Specialized for STEM -- converts handwritten math to LaTeX. Useful for math/science notes. |
| Firebase Storage | Google | File storage for uploaded notes | Free: 5GB; Pay-as-you-go after | Already in TAJIRI stack. Good for storing scanned/uploaded notes. |
| Google Drive API | Google | Cloud document storage, sharing | Free (15GB per user) | Upload, organize, share notes. Google Docs viewer integration. |

**Recommendation:** Google ML Kit for on-device OCR (free, fast, offline). Firebase Storage for note uploads (already integrated).

### Integration Priority
1. **Immediate** -- Google ML Kit Text Recognition (free, on-device OCR via `google_mlkit_text_recognition` on pub.dev), Firebase Storage (already in TAJIRI stack)
2. **Short-term** -- Mathpix OCR API (for STEM math equation recognition), Google Cloud Vision API (for higher accuracy cloud OCR)
3. **Partnership** -- Google Drive API (for cloud document storage and sharing integration)
