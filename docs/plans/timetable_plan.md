# Timetable / Ratiba — Implementation Plan

## Overview
Personal and shared class schedule manager. Weekly/daily views with color-coded subjects, exam overlay, free period finder, clash detection, and push reminders. CR-set timetables auto-push to class members. Supports Mon-Sat (Tanzanian university standard), multi-campus, and offline access.

---

## 1. Frontend Architecture

### Directory Structure
```
lib/timetable/
├── timetable_module.dart
├── models/
│   ├── timetable_entry.dart
│   ├── semester.dart
│   └── exam_schedule.dart
├── services/
│   └── timetable_service.dart       — AuthenticatedDio.instance
├── pages/
│   ├── week_view_page.dart
│   ├── day_view_page.dart
│   ├── add_edit_class_page.dart
│   ├── semester_manager_page.dart
│   ├── exam_schedule_page.dart
│   ├── free_rooms_page.dart
│   ├── share_timetable_page.dart
│   └── timetable_settings_page.dart
└── widgets/
    ├── week_grid.dart
    ├── time_block_card.dart
    ├── day_timeline.dart
    ├── today_widget.dart
    ├── exam_overlay.dart
    └── clash_indicator.dart
```

### Data Models
```dart
class TimetableEntry {
  final int id;
  final String subject, courseCode, room, building, lecturerName;
  final int dayOfWeek;          // 1=Mon .. 6=Sat
  final TimeOfDay startTime, endTime;
  final Color color;
  final int semesterId;
  final List<int> recurrenceDays;
  factory TimetableEntry.fromJson(Map<String, dynamic> j) => TimetableEntry(
    id: _parseInt(j['id']),
    subject: j['subject'] ?? '',
    courseCode: j['course_code'] ?? '',
    room: j['room'] ?? '',
    building: j['building'] ?? '',
    dayOfWeek: _parseInt(j['day_of_week']),
    startTime: _parseTime(j['start_time']),
    endTime: _parseTime(j['end_time']),
  );
}

class Semester { int id; String name; DateTime startDate, endDate; bool active; }
class ExamSchedule { int id; String subject, venue; DateTime examDate; TimeOfDay startTime; }
```

### Service Layer
```dart
class TimetableService {
  static Future<List<TimetableEntry>> getEntries(String token, int semesterId); // GET /api/timetable?semester_id=
  static Future<TimetableEntry> createEntry(String token, Map body);            // POST /api/timetable
  static Future<TimetableEntry> updateEntry(String token, int id, Map body);    // PUT /api/timetable/{id}
  static Future<void> deleteEntry(String token, int id);                        // DELETE /api/timetable/{id}
  static Future<List<Semester>> getSemesters(String token);                     // GET /api/semesters
  static Future<Semester> createSemester(String token, Map body);               // POST /api/semesters
  static Future<List<ExamSchedule>> getExamSchedule(String token, int semId);   // GET /api/exams?semester_id=
  static Future<void> importFromClass(String token, int classId);               // POST /api/timetable/import/{classId}
}
```

### Pages & Widgets
- **WeekViewPage**: 6-column Mon-Sat grid, colored blocks, swipe between weeks, FAB to add
- **DayViewPage**: vertical timeline with detailed cards (room, lecturer, building description)
- **AddEditClassPage**: form with subject, code, lecturer, room, building, day picker, time pickers, color, recurrence
- **SemesterManagerPage**: list of semesters, create/activate/archive
- **ExamSchedulePage**: exam list with countdown, toggle overlay on week view
- **TodayWidget**: compact card for home screen — current/next class with countdown

---

## 2. UI Design
- Monochromatic: #1A1A1A / #666666 / #FAFAFA / #FFFFFF
- 48dp touch targets, maxLines + ellipsis, _rounded icons
- Color-coded subject blocks (auto-assigned from palette, user-overridable)
- Dark card for "Today" hero — current class + next class countdown

### Main Screen Wireframe
```
┌─────────────────────────────────┐
│  Week 12        < Apr 2026 >    │
├────┬────┬────┬────┬────┬────────┤
│Mon │Tue │Wed │Thu │Fri │Sat     │
├────┼────┼────┼────┼────┼────────┤
│8:00│    │8:00│    │8:00│        │
│ CS │    │ CS │    │ CS │        │
│201 │    │201 │    │201 │        │
├────┤    ├────┤    ├────┤        │
│    │10  │    │10  │    │10:00   │
│    │MA  │    │MA  │    │PHY201  │
│    │101 │    │101 │    │Lab     │
├────┼────┼────┼────┼────┼────────┤
│14  │    │14  │    │    │        │
│EN  │    │EN  │    │    │        │
│100 │    │100 │    │    │        │
└────┴────┴────┴────┴────┴────────┘
```

---

## 3. Performance Strategy

### SQLite
```sql
CREATE TABLE timetable_entries(id INTEGER PRIMARY KEY, semester_id INTEGER, day_of_week INTEGER, start_time TEXT, course_code TEXT, json_data TEXT, synced_at TEXT);
CREATE INDEX idx_tt_semester ON timetable_entries(semester_id);
CREATE INDEX idx_tt_day ON timetable_entries(day_of_week);

CREATE TABLE semesters(id INTEGER PRIMARY KEY, name TEXT, active INTEGER, json_data TEXT, synced_at TEXT);
CREATE TABLE exam_schedules(id INTEGER PRIMARY KEY, semester_id INTEGER, exam_date TEXT, json_data TEXT, synced_at TEXT);
```
- SQLite first, API background refresh (stale-while-revalidate)
- Offline read: YES — full timetable cached locally
- Offline write: pending_queue for entry creation/edits

---

## 4. Backend Implementation

### Database (PostgreSQL)
```sql
CREATE TABLE semesters(
  id SERIAL PRIMARY KEY, user_id INT REFERENCES users(id),
  name VARCHAR(100), start_date DATE, end_date DATE,
  active BOOLEAN DEFAULT FALSE, created_at TIMESTAMP DEFAULT NOW()
);
CREATE TABLE timetable_entries(
  id SERIAL PRIMARY KEY, user_id INT REFERENCES users(id),
  semester_id INT REFERENCES semesters(id),
  subject VARCHAR(255), course_code VARCHAR(50),
  lecturer_name VARCHAR(255), room VARCHAR(100), building VARCHAR(255),
  day_of_week SMALLINT CHECK(day_of_week BETWEEN 1 AND 7),
  start_time TIME, end_time TIME, color VARCHAR(7),
  classroom_id INT REFERENCES classrooms(id), created_at TIMESTAMP DEFAULT NOW()
);
CREATE TABLE exam_schedules(
  id SERIAL PRIMARY KEY, user_id INT REFERENCES users(id),
  semester_id INT REFERENCES semesters(id),
  subject VARCHAR(255), venue VARCHAR(255),
  exam_date DATE, start_time TIME, end_time TIME,
  created_at TIMESTAMP DEFAULT NOW()
);
```

### API Endpoints
| Method | Endpoint | Description | Auth |
|--------|----------|-------------|------|
| GET | /api/timetable | List entries for semester | Bearer |
| POST | /api/timetable | Create entry | Bearer |
| PUT | /api/timetable/{id} | Update entry | Bearer |
| DELETE | /api/timetable/{id} | Delete entry | Bearer |
| POST | /api/timetable/import/{classId} | Import from class | Bearer |
| GET | /api/semesters | List semesters | Bearer |
| POST | /api/semesters | Create semester | Bearer |
| GET | /api/exams | Exam schedule | Bearer |
| POST | /api/exams | Add exam | Bearer |

### Controller
`app/Http/Controllers/Api/TimetableController.php`

---

## 5. Integration Wiring
- CalendarService — timetable entries and exams sync to personal calendar
- NotificationService + FCM — 15-min class reminders, room change alerts
- my_class module — CR-set timetable auto-pushes to all class members
- exam_prep module — exam schedule overlay pulled from exam countdown data
- study_groups module — free period finder suggests study session slots
- campus_news module — room/schedule change announcements update timetable

---

## 6. Implementation Phases

### Phase 1 — Core Views (Week 1-2)
- [ ] TimetableEntry model, service, SQLite cache
- [ ] Semester model and management
- [ ] Week view grid (Mon-Sat) with colored blocks
- [ ] Day view with detailed time cards
- [ ] Add/edit class entry form

### Phase 2 — Smart Features (Week 3)
- [ ] Clash detection with visual warning
- [ ] Free period finder
- [ ] Color auto-assignment per subject
- [ ] Recurring schedule support

### Phase 3 — Exam & Sharing (Week 4)
- [ ] Exam schedule page and overlay toggle
- [ ] Import timetable from class (CR push)
- [ ] Export as image / PDF for WhatsApp sharing
- [ ] Push notifications (configurable timing)

### Phase 4 — Polish (Week 5)
- [ ] Today widget with current/next class
- [ ] Multi-campus support
- [ ] Building/room descriptions with landmarks
- [ ] Dark mode matching TAJIRI design system

---

## 7. External APIs & Integrations

| API | Provider | Purpose | Pricing | Integration Notes |
|-----|----------|---------|---------|-------------------|
| Google Calendar API | Google | Calendar CRUD, recurring events, reminders | Free (quota limits) | REST v3. OAuth 2.0. Model class schedules as recurring calendar events. Sync timetable to student's Google Calendar. Flutter package: `googleapis ^14.0.0`. |
| Microsoft Graph Calendar API | Microsoft | Outlook calendar integration | Free tier available | For institutions using Office 365 Education. |
| Cronofy Calendar API | Cronofy | Unified calendar access (Google, Outlook, iCloud) | Free tier: 5 users; Paid from $49/mo | Unified API across calendar providers. |
| UniTime API | UniTime (open-source) | University timetabling, exam scheduling | Free (open-source) | Java-based. Purpose-built for university scheduling. Complex setup. |

**Tanzania context:** No Tanzania-specific timetable API. Build custom with Google Calendar as sync backend.

### Integration Priority
1. **Immediate** -- Google Calendar API (free, sync timetable entries as calendar events with reminders)
2. **Short-term** -- Microsoft Graph Calendar API (for Office 365 Education institutions)
3. **Partnership** -- UniTime (requires institutional deployment), university portal timetable scraping
