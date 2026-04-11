# NECTA (National Examinations Council of Tanzania) — Implementation Plan

## Overview

The NECTA module provides Tanzanian students, parents, and teachers mobile access to national examination services. Its killer feature is instant push notifications when PSLE/FTNA/CSEE/ACSEE results are published -- eliminating the need to crash necta.go.tz. It also covers result lookup by exam number with clean formatting, results history storage for tracking academic progression, a downloadable past papers library organized by exam/subject/year, certificate verification, exam timetables synced to calendar, school performance statistics, and exam day preparation checklists.

---

## 1. Frontend Architecture

### Directory Structure
```
lib/necta/
├── necta_module.dart                  — Entry point & route registration
├── models/
│   ├── result_models.dart             — ExamResult, SubjectGrade, Division
│   ├── past_paper_models.dart         — PastPaper, Subject, ExamType
│   ├── school_models.dart             — SchoolPerformance, RegionalStats
│   ├── timetable_models.dart          — ExamTimetable, ExamSession
│   └── certificate_models.dart        — CertificateVerification
├── services/
│   └── necta_service.dart             — API service using AuthenticatedDio
├── pages/
│   ├── necta_home_page.dart           — Quick lookup, upcoming exams
│   ├── results_checker_page.dart      — Input exam number, display results
│   ├── my_results_page.dart           — Stored results history
│   ├── past_papers_page.dart          — Browse/search/download library
│   ├── certificate_verify_page.dart   — Certificate number verification
│   ├── exam_timetable_page.dart       — Calendar/list of upcoming exams
│   ├── school_stats_page.dart         — School performance dashboard
│   └── regional_rankings_page.dart    — Map/list of regional performance
└── widgets/
    ├── result_card_widget.dart         — Clean result display with grades
    ├── subject_grade_widget.dart       — Subject name with grade badge
    ├── past_paper_card_widget.dart     — Paper title, subject, year, download
    ├── exam_countdown_widget.dart      — Days until next exam
    └── school_rank_widget.dart         — School with pass rate bar
```

### Data Models
- **ExamResult**: examNumber, examType (PSLE/FTNA/CSEE/ACSEE), year, candidateName, schoolName, subjects[] (name, grade), division, points, passStatus, overallPerformance. `factory ExamResult.fromJson()`.
- **PastPaper**: id, examType, subject, year, paperNumber, title, fileUrl, markingSchemeUrl, downloadCount. `factory PastPaper.fromJson()`.
- **SchoolPerformance**: schoolId, schoolName, region, district, examType, year, totalCandidates, passRate, divisionDistribution (I/II/III/IV/0), subjectPerformance[]. `factory SchoolPerformance.fromJson()`.
- **ExamTimetable**: id, examType, subject, date, startTime, duration, venue, instructions. `factory ExamTimetable.fromJson()`.
- **CertificateVerification**: certificateNumber, candidateName, examType, year, status (verified/not_found/invalid), details. `factory CertificateVerification.fromJson()`.

### Service Layer
- `checkResults(String examNumber, String examType)` — GET `/api/necta/results`
- `registerForAlerts(Map examNumbers)` — POST `/api/necta/alerts`
- `getMyResults()` — GET `/api/necta/my-results`
- `saveResult(Map resultData)` — POST `/api/necta/my-results`
- `getPastPapers(Map filters)` — GET `/api/necta/past-papers`
- `downloadPastPaper(int id)` — GET `/api/necta/past-papers/{id}/download`
- `verifyCertificate(String certNumber)` — GET `/api/necta/verify`
- `getExamTimetable(String examType)` — GET `/api/necta/timetable`
- `getSchoolPerformance(Map params)` — GET `/api/necta/schools`
- `getRegionalStats(Map params)` — GET `/api/necta/regions`

### Pages & Screens
- **NECTA Home**: Quick result lookup with exam number field, upcoming exam countdown, recent results announcements, past papers shortcut.
- **Results Checker**: Exam type selector (PSLE/CSEE/ACSEE), exam number input, clean result card with subject grades and division.
- **My Results**: Stored results for registered exam numbers, progression view (PSLE > CSEE > ACSEE).
- **Past Papers**: Browse by exam type > subject > year. Download with offline access. Search by keyword.
- **Exam Timetable**: Calendar view with exam dates, list view with subject/time/duration. Add to phone calendar.
- **School Stats**: Search school, see pass rate, division distribution chart, subject breakdown, year-over-year trend.
- **Regional Rankings**: Map with color-coded regions by performance, list view with sortable columns.

### Widgets
- `ResultCardWidget` — Student name, school, subjects with grade badges, division prominently displayed
- `SubjectGradeWidget` — Subject name left, grade badge right (A=green, B=blue, C=yellow, D/F=red)
- `PastPaperCardWidget` — Title, subject chip, year, download button with size
- `ExamCountdownWidget` — Days/hours until next exam with subject name
- `SchoolRankWidget` — School name, pass rate progress bar, division distribution

---

## 2. UI Design

- Results: Clean card with large division display, subject grades in grid
- Grade badges: Color-coded (A=green, B=blue, C=yellow, D=orange, F=red)
- Past papers: List with download progress indicator
- School stats: Bar charts for division distribution, line chart for trends

### Key Screen Mockup — Results Checker
```
┌─────────────────────────────┐
│  SafeArea                   │
│  Check Exam Results         │
│  ┌───────────────────────┐  │
│  │ Exam: [CSEE      ▼]  │  │
│  │ Number: [__________]  │  │
│  │       [Check Results] │  │
│  └───────────────────────┘  │
│  ┌───────────────────────┐  │
│  │ John Mwalimu          │  │
│  │ Mzumbe Sec. School    │  │
│  │ CSEE 2025             │  │
│  │ ╔═══════════════════╗ │  │
│  │ ║ Division: I (7pts)║ │  │
│  │ ╚═══════════════════╝ │  │
│  │ Physics      [A]      │  │
│  │ Chemistry    [B]      │  │
│  │ Mathematics  [A]      │  │
│  │ Biology      [B]      │  │
│  │ English      [B]      │  │
│  │ Civics       [A]      │  │
│  │ Kiswahili    [B]      │  │
│  │ [Share] [Save] [📤]  │  │
│  └───────────────────────┘  │
└─────────────────────────────┘
```

---

## 3. Performance Strategy

### Local-First with SQLite
```dart
// Table: necta_results
// Columns: id INTEGER PRIMARY KEY, exam_number TEXT, exam_type TEXT, year INTEGER, json_data TEXT, synced_at TEXT
// Indexes: exam_number, exam_type, year
// Table: past_papers
// Columns: id INTEGER PRIMARY KEY, exam_type TEXT, subject TEXT, year INTEGER, file_path TEXT, json_data TEXT, synced_at TEXT
// Indexes: exam_type, subject, year
```

### Stale-While-Revalidate
- Results: cache indefinitely (results don't change after publication)
- Past papers: cache indefinitely after download
- Timetable: cache TTL 24 hours
- School stats: cache TTL 7 days
- Alert registrations: cache TTL 1 hour

### Offline Support
- Read: Saved results, downloaded past papers, exam timetable, school stats
- Write: Alert registration queued if offline
- Sync: Results publication alerts require connectivity

### Media Caching
- Past paper PDFs: cached permanently after download
- School photos: MediaCacheService (30-day TTL)
- Result card images for sharing: generated and cached locally

---

## 4. Backend Implementation

### Database Tables
```sql
CREATE TABLE necta_results_cache (
    id BIGSERIAL PRIMARY KEY,
    exam_number VARCHAR(50),
    exam_type VARCHAR(10),
    year INTEGER,
    candidate_name VARCHAR(255),
    school_name VARCHAR(255),
    subjects JSONB,
    division VARCHAR(10),
    points INTEGER,
    pass_status VARCHAR(20),
    created_at TIMESTAMP DEFAULT NOW(),
    UNIQUE(exam_number, exam_type, year)
);

CREATE TABLE necta_alert_registrations (
    id BIGSERIAL PRIMARY KEY,
    user_id BIGINT REFERENCES users(id),
    exam_number VARCHAR(50),
    exam_type VARCHAR(10),
    year INTEGER,
    notified BOOLEAN DEFAULT FALSE,
    created_at TIMESTAMP DEFAULT NOW()
);

CREATE TABLE necta_past_papers (
    id BIGSERIAL PRIMARY KEY,
    exam_type VARCHAR(10),
    subject VARCHAR(100),
    year INTEGER,
    paper_number INTEGER DEFAULT 1,
    title VARCHAR(255),
    file_url TEXT,
    marking_scheme_url TEXT,
    download_count INTEGER DEFAULT 0,
    created_at TIMESTAMP DEFAULT NOW()
);

CREATE TABLE necta_school_stats (
    id BIGSERIAL PRIMARY KEY,
    school_name VARCHAR(255),
    region VARCHAR(100),
    district VARCHAR(100),
    exam_type VARCHAR(10),
    year INTEGER,
    total_candidates INTEGER,
    pass_rate DECIMAL(5,2),
    division_distribution JSONB,
    subject_performance JSONB,
    created_at TIMESTAMP DEFAULT NOW(),
    UNIQUE(school_name, exam_type, year)
);
```

### API Endpoints
| Method | Endpoint | Description | Auth |
|--------|----------|-------------|------|
| GET | /api/necta/results | Check results | No |
| POST | /api/necta/alerts | Register for alerts | Yes |
| GET | /api/necta/my-results | Saved results | Yes |
| POST | /api/necta/my-results | Save result | Yes |
| GET | /api/necta/past-papers | Browse past papers | No |
| GET | /api/necta/past-papers/{id}/download | Download paper | No |
| GET | /api/necta/verify | Verify certificate | Yes |
| GET | /api/necta/timetable | Exam timetable | No |
| GET | /api/necta/schools | School performance | No |
| GET | /api/necta/regions | Regional statistics | No |

### Controller
- File: `app/Http/Controllers/Api/NectaController.php`
- Pattern: DB facade, try/catch, `{"success": true, "data": ...}` responses
- Results: Scraped from necta.go.tz and cached aggressively to avoid adding load

### Background Jobs
- NECTA results scraping when published (triggered manually or via monitoring)
- Results publication notification broadcasting to registered exam numbers
- Past papers indexing from NECTA archives
- School statistics aggregation after results publication
- NECTA website availability monitoring (every 5 minutes during results season)

---

## 5. Integration Wiring

- **Notifications**: Instant push alerts when results published. Exam day reminders. Timetable changes.
- **Groups**: School alumni groups, study groups, parent-teacher groups.
- **My Family**: Parents track children's results, multi-child comparison.
- **Messaging**: Share results, teacher-parent communication, study group coordination.
- **Profile**: Verified academic credentials on TAJIRI profile.
- **Calendar**: Exam dates synced to calendar, revision reminders.
- **HESLB**: ACSEE results linked to loan application eligibility.
- **Posts & Stories**: Results celebrations, top performer announcements.
- **Wallet**: Premium past papers, study material payments.
- **Content Discovery**: Personalized exam prep content, trending education hashtags.
- **Clips & LiveStream**: Educational video clips, live revision sessions.

---

## 6. Implementation Phases

### Phase 1: Foundation (Week 1)
- [ ] Create directory structure and necta_module.dart
- [ ] ExamResult, PastPaper, SchoolPerformance, Timetable models
- [ ] NectaService with AuthenticatedDio
- [ ] Backend: migrations + results cache + past papers endpoints
- [ ] SQLite tables for results and past papers
- [ ] NECTA results scraper for backend

### Phase 2: Core UI (Week 2)
- [ ] NECTA Home with quick lookup and countdown
- [ ] Results Checker with clean result card
- [ ] My Results with progression view
- [ ] Past Papers browser with download
- [ ] Exam Timetable with calendar sync

### Phase 3: Integration (Week 3)
- [ ] Wire to FCMService for results publication alerts
- [ ] Wire to CalendarService for exam dates
- [ ] Wire to My Family for parent tracking
- [ ] Wire to HESLB for eligibility linkage
- [ ] Results sharing via MessageService and PostService

### Phase 4: Polish (Week 4)
- [ ] Certificate Verification
- [ ] School Stats dashboard with charts
- [ ] Regional Rankings with map view
- [ ] Offline past papers viewing
- [ ] Result card image generation for sharing
- [ ] Exam Day Checklist with reminders

---

## 7. External APIs & Integrations

| API | Provider | Purpose | Pricing | Integration Notes |
|-----|----------|---------|---------|-------------------|
| [NECTA API (unofficial)](https://pypi.org/project/nectaapi/) | Community (Vincent Laizer) | Fetch CSEE/ACSEE results from NECTA | Free (open-source, PyPI: `nectaapi`) | Python package scraping necta.go.tz. School lists, student results, performance comparisons. Not official — fragile |
| [NECTA Results Scraper (PHP)](https://github.com/AlexLeoTz/necta-results-scraper) | Community (AlexLeoTz) | Scrape NECTA student results | Free (open-source) | PHP alternative to Python NECTA API |
| [NECTA Website](https://matokeo.necta.go.tz/) | NECTA | Official results portal | Free (web scraping) | No official API. Would need custom scraper for past papers and results |
| [Open Trivia Database API](https://opentdb.com/api_config.php) | OpenTDB | Free trivia/quiz questions for exam prep | Free, no API key | 4,000+ verified questions. Max 50/call. Session tokens prevent repeats |
| [Anthropic Claude API](https://docs.anthropic.com/) | Anthropic | AI-generated exam practice questions, explanations | From $1/M input tokens (Haiku) | Generate NECTA-aligned practice content. TAJIRI already uses AI backend |
| [Wolfram Alpha API](https://products.wolframalpha.com/api/) | Wolfram | Step-by-step math solutions for exam prep | Free: 2,000 calls/mo | Full Results API, Short Answers API. Excellent for STEM subjects |
| [Google ML Kit Text Recognition](https://developers.google.com/ml-kit/vision/text-recognition) | Google | On-device OCR for scanning past papers | Free | Flutter: `google_mlkit_text_recognition`. Works offline. iOS/Android only |
| [M-Pesa Open API](https://openapiportal.m-pesa.com) | Vodacom Tanzania | Exam fee payments | Transaction fees | Dart SDK: `mpesa_sdk` on pub.dev |
| [AzamPay API](https://developers.azampay.co.tz/) | AzamPay (Bakhresa Group) | Payment gateway for exam resources | Transaction fees | Flutter SDK: `azampaytanzania` on pub.dev |
| [Africa's Talking](https://developers.africastalking.com/) | Africa's Talking | SMS result notifications | Pay-as-you-go | Supports all 3 major TZ telcos |
| [Firebase Cloud Messaging](https://firebase.google.com/docs/cloud-messaging) | Google | Result release alerts, exam reminders | Free | Already integrated in TAJIRI app |
