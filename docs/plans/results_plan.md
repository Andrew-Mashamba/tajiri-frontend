# Results / Matokeo — Implementation Plan

## Overview
Academic results tracker supporting multiple grading scales (5.0 Tanzanian, 4.0 international, percentage). Semester-by-semester grade entry, GPA calculation, performance trend charts, what-if calculator, HESLB threshold alerts, transcript generation, NECTA results checker, supplementary exam tracking, and graduation progress visualization.

---

## 1. Frontend Architecture

### Directory Structure
```
lib/results/
├── results_module.dart
├── models/
│   ├── course_grade.dart
│   ├── semester_result.dart
│   ├── gpa_calculation.dart
│   └── necta_result.dart
├── services/
│   └── results_service.dart         — AuthenticatedDio.instance
├── pages/
│   ├── results_dashboard_page.dart
│   ├── semester_view_page.dart
│   ├── add_edit_grade_page.dart
│   ├── gpa_calculator_page.dart
│   ├── performance_charts_page.dart
│   ├── what_if_calculator_page.dart
│   ├── transcript_page.dart
│   ├── necta_results_page.dart
│   ├── graduation_progress_page.dart
│   └── results_settings_page.dart
└── widgets/
    ├── gpa_card.dart
    ├── grade_tile.dart
    ├── trend_chart.dart
    ├── subject_bar_chart.dart
    ├── progress_ring.dart
    ├── heslb_alert.dart
    └── transcript_preview.dart
```

### Data Models
```dart
class CourseGrade {
  final int id;
  final String courseName, courseCode, grade;
  final int creditHours, semesterId;
  final double? gradePoints;
  final String status;    // pass, fail, incomplete, supplementary
  factory CourseGrade.fromJson(Map<String, dynamic> j) => CourseGrade(
    id: _parseInt(j['id']),
    courseName: j['course_name'] ?? '',
    courseCode: j['course_code'] ?? '',
    grade: j['grade'] ?? '',
    creditHours: _parseInt(j['credit_hours']),
    gradePoints: _parseDouble(j['grade_points']),
    status: j['status'] ?? 'pass',
  );
}

class SemesterResult {
  int id; String name; double gpa; int totalCredits;
  List<CourseGrade> courses; bool isDeanslist;
}

class GpaCalculation { double semesterGpa, cumulativeGpa; int totalCredits, earnedCredits; String scale; }
class NectaResult { String examNumber, division; int points; List<SubjectResult> subjects; int year; }
class SubjectResult { String subject, grade; }
```

### Service Layer
```dart
class ResultsService {
  static Future<List<SemesterResult>> getSemesters(String token);              // GET /api/results/semesters
  static Future<SemesterResult> getSemesterDetail(String token, int id);       // GET /api/results/semesters/{id}
  static Future<CourseGrade> addGrade(String token, Map body);                 // POST /api/results/grades
  static Future<CourseGrade> updateGrade(String token, int id, Map body);      // PUT /api/results/grades/{id}
  static Future<void> deleteGrade(String token, int id);                       // DELETE /api/results/grades/{id}
  static Future<GpaCalculation> calculateGpa(String token, {String scale});    // GET /api/results/gpa?scale=
  static Future<Map> whatIfCalculation(String token, Map hypothetical);         // POST /api/results/what-if
  static Future<Map> getPerformanceCharts(String token);                       // GET /api/results/analytics
  static Future<String> generateTranscript(String token);                      // GET /api/results/transcript (PDF URL)
  static Future<NectaResult> checkNectaResults(String token, String examNum);  // GET /api/results/necta?exam_number=
  static Future<Map> getGraduationProgress(String token);                      // GET /api/results/graduation-progress
}
```

### Pages & Widgets
- **ResultsDashboardPage**: current semester GPA, cumulative GPA, trend chart, HESLB alert, quick stats
- **SemesterViewPage**: table of courses with grades, credits, semester GPA
- **AddEditGradePage**: form with course name, code, grade, credit hours, semester picker
- **GpaCalculatorPage**: interactive calculator with scale switcher (5.0/4.0/percentage)
- **PerformanceChartsPage**: line graph (GPA trend), bar chart (by subject), pie (grade distribution)
- **WhatIfCalculatorPage**: hypothetical grade entry with projected GPA outcome
- **TranscriptPage**: formatted preview with download/share options
- **NectaResultsPage**: secondary school results with division and points
- **GraduationProgressPage**: visual progress bar with credits earned/required/remaining

---

## 2. UI Design
- Monochromatic: #1A1A1A / #666666 / #FAFAFA / #FFFFFF
- 48dp touch targets, maxLines + ellipsis, _rounded icons
- Dark hero card: cumulative GPA large text, semester GPA below, trend sparkline
- HESLB warning: subtle red border when GPA approaches minimum threshold

### Main Screen Wireframe
```
┌──────────────────────────────┐
│  Results                [⋮] │
├──────────────────────────────┤
│ ┌──────────────────────────┐ │
│ │   Cumulative GPA         │ │
│ │      3.72 / 5.0          │ │
│ │   Semester 1: 3.8        │ │
│ │   ▁▂▃▄▅▆▇ trend          │ │
│ └──────────────────────────┘ │
│                              │
│ [Calculator] [What-If] [📄]  │
│                              │
│ SEMESTER 1, 2026             │
│ ┌──────────────────────────┐ │
│ │ CS201  Data Structures B+│ │
│ │        3 credits    4.0  │ │
│ ├──────────────────────────┤ │
│ │ MA101  Calculus I     A  │ │
│ │        4 credits    5.0  │ │
│ ├──────────────────────────┤ │
│ │ EN100  English        B  │ │
│ │        2 credits    3.0  │ │
│ └──────────────────────────┘ │
│                              │
│ GRADUATION: 67% complete     │
│ ████████████░░░░░ 84/126 cr  │
└──────────────────────────────┘
```

---

## 3. Performance Strategy

### SQLite
```sql
CREATE TABLE semester_results(id INTEGER PRIMARY KEY, name TEXT, gpa REAL, total_credits INTEGER, json_data TEXT, synced_at TEXT);
CREATE TABLE course_grades(id INTEGER PRIMARY KEY, semester_id INTEGER, course_code TEXT, grade TEXT, credit_hours INTEGER, json_data TEXT, synced_at TEXT);
CREATE INDEX idx_grades_semester ON course_grades(semester_id);

CREATE TABLE necta_results(id INTEGER PRIMARY KEY, exam_number TEXT UNIQUE, json_data TEXT, synced_at TEXT);
```
- SQLite first, API background refresh (stale-while-revalidate)
- Offline read: YES — all grades, GPA, charts calculated locally
- Offline write: pending_queue for grade create/update

---

## 4. Backend Implementation

### Database (PostgreSQL)
```sql
CREATE TABLE result_semesters(
  id SERIAL PRIMARY KEY, user_id INT REFERENCES users(id),
  name VARCHAR(100), year SMALLINT, semester_number SMALLINT,
  gpa DECIMAL(3,2), total_credits INT, created_at TIMESTAMP DEFAULT NOW()
);
CREATE TABLE course_grades(
  id SERIAL PRIMARY KEY, semester_id INT REFERENCES result_semesters(id),
  user_id INT REFERENCES users(id),
  course_name VARCHAR(255), course_code VARCHAR(50),
  grade VARCHAR(5), grade_points DECIMAL(3,2),
  credit_hours SMALLINT, status VARCHAR(20) DEFAULT 'pass',
  created_at TIMESTAMP DEFAULT NOW()
);
CREATE TABLE necta_results(
  id SERIAL PRIMARY KEY, user_id INT REFERENCES users(id),
  exam_number VARCHAR(50), exam_type VARCHAR(10),  -- csee, acsee
  year SMALLINT, division VARCHAR(10), points INT,
  subjects JSONB, created_at TIMESTAMP DEFAULT NOW()
);
CREATE TABLE grading_scales(
  id SERIAL PRIMARY KEY, name VARCHAR(50),
  mappings JSONB  -- {"A": 5.0, "B+": 4.0, ...}
);
```

### API Endpoints
| Method | Endpoint | Description | Auth |
|--------|----------|-------------|------|
| GET | /api/results/semesters | List semesters | Bearer |
| GET | /api/results/semesters/{id} | Semester detail with grades | Bearer |
| POST | /api/results/grades | Add grade | Bearer |
| PUT | /api/results/grades/{id} | Update grade | Bearer |
| DELETE | /api/results/grades/{id} | Delete grade | Bearer |
| GET | /api/results/gpa | Calculate GPA (with scale param) | Bearer |
| POST | /api/results/what-if | What-if calculation | Bearer |
| GET | /api/results/analytics | Performance charts data | Bearer |
| GET | /api/results/transcript | Generate transcript PDF | Bearer |
| GET | /api/results/necta | Check NECTA results | Bearer |
| GET | /api/results/graduation-progress | Credits progress | Bearer |

### Controller
`app/Http/Controllers/Api/ResultsController.php`

---

## 5. Integration Wiring
- ProfileService — GPA and education history on TAJIRI profile (privacy-controlled)
- NotificationService + FCM — grade posting alerts, HESLB threshold warnings
- CalendarService — supplementary exam dates synced to calendar
- WalletService — pay supplementary exam fees and transcript fees via M-Pesa
- fee_status module — GPA linked to HESLB loan eligibility
- my_class module — auto-populate course list from class enrollment
- assignments module — CA grades feed into grade prediction
- career module — GPA and transcript for job applications
- newton module — "What GPA do I need?" calculations

---

## 6. Implementation Phases

### Phase 1 — Grade Entry & GPA (Week 1-2)
- [ ] CourseGrade, SemesterResult models, service, SQLite cache
- [ ] Add/edit grade form with course, grade, credits
- [ ] Semester view with grade table
- [ ] GPA calculator with 5.0/4.0/percentage scale support

### Phase 2 — Dashboard & Charts (Week 3)
- [ ] Results dashboard with cumulative GPA hero card
- [ ] Performance trend line chart
- [ ] Subject strength bar chart
- [ ] Dean's list tracking

### Phase 3 — Tools (Week 4)
- [ ] What-if calculator
- [ ] Graduation progress tracker
- [ ] HESLB GPA threshold alert
- [ ] Supplementary exam tracker

### Phase 4 — Export & NECTA (Week 5)
- [ ] Transcript generator (PDF)
- [ ] Share results with parents/sponsors
- [ ] NECTA results checker and storage
- [ ] Export results as PDF/image

---

## 7. External APIs & Integrations

| API | Provider | Purpose | Pricing | Integration Notes |
|-----|----------|---------|---------|-------------------|
| NECTA API (unofficial) | Community (Vincent Laizer) | Fetch CSEE/ACSEE/FTNA national exam results | Free (open-source, PyPI: `nectaapi`) | Python package scraping necta.go.tz. Supports school summaries, individual results, year comparisons. **Not official -- fragile.** |
| Google Classroom API | Google | Gradebook access, student submissions, rubrics | Free (Google Workspace for Education) | Access grades programmatically. Calculate GPA, generate reports. For institutions using Google Classroom. |
| Canvas LMS REST API | Instructure | Gradebook API, grade passback (LTI) | Free (with Canvas instance) | Comprehensive grading: weighted, curved, letter grades. |
| TCU Central Admission System | TCU (tcu.go.tz) | University admission data | No public API | Web portal only. Would need partnership for data access. |

**Tanzania context:** No official government API for academic results. NECTA unofficial scraper is the only programmatic option. For university results, each institution has its own portal (ARIS, SARIS, OSIM) with no unified API.

### Integration Priority
1. **Immediate** -- NECTA unofficial API via `nectaapi` (free, backend scraper for CSEE/ACSEE results checking)
2. **Short-term** -- Google Classroom API (free, import grades from Google Classroom courses)
3. **Partnership** -- TCU admission data (requires formal partnership), university portal integration (ARIS/SARIS per-institution agreements)
