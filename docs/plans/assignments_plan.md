# Assignments / Kazi — Implementation Plan

## Overview
Assignment tracker with deadline management, file submission, group work coordination, grade recording, and smart reminders. Students create assignments linked to classes, attach briefs (PDF, photo, voice memo), track status through submission, and record grades for running CA averages.

---

## 1. Frontend Architecture

### Directory Structure
```
lib/assignments/
├── assignments_module.dart
├── models/
│   ├── assignment.dart
│   ├── assignment_group.dart
│   ├── submission.dart
│   └── grade_entry.dart
├── services/
│   └── assignment_service.dart      — AuthenticatedDio.instance
├── pages/
│   ├── assignment_dashboard_page.dart
│   ├── create_assignment_page.dart
│   ├── assignment_detail_page.dart
│   ├── assignment_calendar_page.dart
│   ├── group_assignment_page.dart
│   ├── grades_summary_page.dart
│   └── reminders_settings_page.dart
└── widgets/
    ├── assignment_card.dart
    ├── deadline_countdown.dart
    ├── priority_badge.dart
    ├── status_chip.dart
    ├── checklist_widget.dart
    └── grade_chart.dart
```

### Data Models
```dart
class Assignment {
  final int id;
  final String title, description;
  final int? classId;
  final String subject, status;         // not_started, in_progress, submitted, graded, late
  final String priority;                // low, medium, high, critical
  final DateTime dueDate;
  final double? grade, maxGrade;
  final List<String> attachmentUrls;
  final List<ChecklistItem> checklist;
  factory Assignment.fromJson(Map<String, dynamic> j) => Assignment(
    id: _parseInt(j['id']),
    title: j['title'] ?? '',
    status: j['status'] ?? 'not_started',
    priority: j['priority'] ?? 'medium',
    dueDate: DateTime.parse(j['due_date']),
    grade: _parseDouble(j['grade']),
    maxGrade: _parseDouble(j['max_grade']),
  );
}

class Submission { int id, assignmentId; DateTime submittedAt; List<String> fileUrls; }
class GradeEntry { int id; String subject; double grade, maxGrade; double weight; }
```

### Service Layer
```dart
class AssignmentService {
  static Future<List<Assignment>> getAssignments(String token, {String? status, int? classId}); // GET /api/assignments
  static Future<Assignment> createAssignment(String token, Map body);       // POST /api/assignments
  static Future<Assignment> updateAssignment(String token, int id, Map b);  // PUT /api/assignments/{id}
  static Future<void> deleteAssignment(String token, int id);               // DELETE /api/assignments/{id}
  static Future<void> submitAssignment(String token, int id, List<File> f); // POST /api/assignments/{id}/submit
  static Future<void> recordGrade(String token, int id, Map body);          // POST /api/assignments/{id}/grade
  static Future<Map> getGradesSummary(String token, {int? classId});        // GET /api/assignments/grades-summary
}
```

### Pages & Widgets
- **AssignmentDashboardPage**: three sections — upcoming (sorted by urgency), overdue (red), recently completed
- **CreateAssignmentPage**: form with title, description, subject picker, due date/time, priority, file attachments, checklist builder
- **AssignmentDetailPage**: full view with description, attachments, status toggle, submission area, grade display
- **AssignmentCalendarPage**: month view with deadline dots, tap date to see assignments due
- **GroupAssignmentPage**: member list, task delegation, group chat link
- **GradesSummaryPage**: table by subject with running CA average and bar chart

---

## 2. UI Design
- Monochromatic: #1A1A1A / #666666 / #FAFAFA / #FFFFFF
- 48dp touch targets, maxLines + ellipsis, _rounded icons
- Priority color accents: critical = red outline, high = orange, medium = default, low = muted
- Dark hero card: "3 due this week" with countdown to nearest deadline

### Main Screen Wireframe
```
┌──────────────────────────────┐
│  Assignments         [+ ⋮]  │
├──────────────────────────────┤
│ ┌──────────────────────────┐ │
│ │ ■ 3 due this week        │ │
│ │   Next: CS201 Lab — 2d   │ │
│ └──────────────────────────┘ │
│                              │
│ UPCOMING                     │
│ ┌──────────────────────────┐ │
│ │ ● CS201 Lab Report    HI │ │
│ │   Due: Apr 9 · 2 days   │ │
│ ├──────────────────────────┤ │
│ │ ● MA101 Problem Set   MD │ │
│ │   Due: Apr 12 · 5 days  │ │
│ └──────────────────────────┘ │
│ OVERDUE                      │
│ ┌──────────────────────────┐ │
│ │ ● EN100 Essay        RED │ │
│ │   Was due: Apr 5         │ │
│ └──────────────────────────┘ │
└──────────────────────────────┘
```

---

## 3. Performance Strategy

### SQLite
```sql
CREATE TABLE assignments(id INTEGER PRIMARY KEY, class_id INTEGER, status TEXT, priority TEXT, due_date TEXT, json_data TEXT, synced_at TEXT);
CREATE INDEX idx_assign_status ON assignments(status);
CREATE INDEX idx_assign_due ON assignments(due_date);

CREATE TABLE submissions(id INTEGER PRIMARY KEY, assignment_id INTEGER, json_data TEXT, synced_at TEXT);
```
- SQLite first, API background refresh (stale-while-revalidate)
- Offline read: YES — assignments, grades, checklists cached
- Offline write: pending_queue for create/update/submit (files queued for upload)

---

## 4. Backend Implementation

### Database (PostgreSQL)
```sql
CREATE TABLE assignments(
  id SERIAL PRIMARY KEY, user_id INT REFERENCES users(id),
  classroom_id INT REFERENCES classrooms(id),
  title VARCHAR(255), description TEXT, subject VARCHAR(255),
  status VARCHAR(30) DEFAULT 'not_started', priority VARCHAR(20) DEFAULT 'medium',
  due_date TIMESTAMP, grade DECIMAL(5,2), max_grade DECIMAL(5,2),
  is_group BOOLEAN DEFAULT FALSE, created_at TIMESTAMP DEFAULT NOW()
);
CREATE TABLE assignment_attachments(
  id SERIAL PRIMARY KEY, assignment_id INT REFERENCES assignments(id),
  file_url TEXT, file_type VARCHAR(50), is_submission BOOLEAN DEFAULT FALSE,
  uploaded_at TIMESTAMP DEFAULT NOW()
);
CREATE TABLE assignment_checklist(
  id SERIAL PRIMARY KEY, assignment_id INT REFERENCES assignments(id),
  text VARCHAR(500), completed BOOLEAN DEFAULT FALSE, sort_order INT
);
CREATE TABLE assignment_group_members(
  id SERIAL PRIMARY KEY, assignment_id INT REFERENCES assignments(id),
  user_id INT REFERENCES users(id), task TEXT
);
```

### API Endpoints
| Method | Endpoint | Description | Auth |
|--------|----------|-------------|------|
| GET | /api/assignments | List with filters | Bearer |
| POST | /api/assignments | Create assignment | Bearer |
| PUT | /api/assignments/{id} | Update | Bearer |
| DELETE | /api/assignments/{id} | Delete | Bearer |
| POST | /api/assignments/{id}/submit | Submit files | Bearer |
| POST | /api/assignments/{id}/grade | Record grade | Bearer |
| GET | /api/assignments/grades-summary | CA averages | Bearer |
| PUT | /api/assignments/{id}/checklist | Update checklist | Bearer |

### Controller
`app/Http/Controllers/Api/AssignmentController.php`

---

## 5. Integration Wiring
- CalendarService — deadlines auto-sync to personal calendar with reminders
- NotificationService + FCM — smart reminders at 1w, 3d, 1d, 12h, 2h before deadline
- my_class module — assignments link to classes; CR can create for all members
- class_notes module — link relevant notes to assignments for reference
- newton module — "Help me understand" opens Socratic mode (guides, doesn't solve)
- results module — CA grades feed into running average and GPA calculation
- PhotoService — capture whiteboard instructions, submit handwritten work

---

## 6. Implementation Phases

### Phase 1 — Core CRUD (Week 1-2)
- [ ] Assignment model, service, SQLite cache
- [ ] Create assignment with title, description, due date, priority
- [ ] Assignment dashboard with upcoming/overdue sections
- [ ] Assignment detail page with status tracking

### Phase 2 — Submissions & Grades (Week 3)
- [ ] File attachment (brief + submission)
- [ ] Photo capture of whiteboard/handwritten work
- [ ] Grade recording with running CA average
- [ ] Grades summary page with charts

### Phase 3 — Smart Features (Week 4)
- [ ] Smart reminders (configurable intervals)
- [ ] Calendar view with deadline dots
- [ ] Checklist within assignments
- [ ] Search and filter by subject/status/priority

### Phase 4 — Group & Advanced (Week 5)
- [ ] Group assignment support with member tasks
- [ ] Recurring assignments (weekly lab reports)
- [ ] Voice memo for verbal instructions
- [ ] Semester archiving

---

## 7. External APIs & Integrations

| API | Provider | Purpose | Pricing | Integration Notes |
|-----|----------|---------|---------|-------------------|
| Google Classroom API | Google | Create/grade courseWork, manage submissions, rubrics | Free (Google Workspace for Education) | Supports assignment creation, rubrics, student submissions with attachments. REST v1, OAuth 2.0. |
| Canvas LMS REST API | Instructure | Assignment CRUD, submission management, rubrics | Free (with Canvas instance) | Rich assignment types: online upload, URL, media. SpeedGrader integration. |
| Turnitin API | Turnitin | Plagiarism detection for submissions | Paid (institutional license) | Integration API for plagiarism checking. Requires institutional license. |
| Google Calendar API | Google | Deadline sync with reminders | Free (quota limits) | Auto-sync assignment deadlines to student's calendar with configurable reminders. |

### Integration Priority
1. **Immediate** -- Google Calendar API (free, sync deadlines as calendar events with smart reminders)
2. **Short-term** -- Google Classroom API (free, import assignments from Google Classroom courses)
3. **Partnership** -- Canvas/Moodle LMS (import assignments from institutional LMS), Turnitin (plagiarism detection, requires institutional license)
