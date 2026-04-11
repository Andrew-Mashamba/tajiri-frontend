# My Class / Darasa Langu — Implementation Plan

## Overview
Class management hub replacing WhatsApp chaos. Students create/join classes with codes, view rosters, manage roles (CR, lecturer), post announcements, share photos, track attendance via QR, and coordinate across semesters. Each class auto-creates a TAJIRI group with integrated chat.

---

## 1. Frontend Architecture

### Directory Structure
```
lib/my_class/
├── my_class_module.dart
├── models/
│   ├── classroom.dart
│   ├── class_member.dart
│   ├── announcement.dart
│   └── attendance_record.dart
├── services/
│   └── my_class_service.dart        — AuthenticatedDio.instance
├── pages/
│   ├── my_classes_page.dart
│   ├── class_home_page.dart
│   ├── class_roster_page.dart
│   ├── join_class_page.dart
│   ├── create_class_page.dart
│   ├── class_settings_page.dart
│   ├── lecturer_directory_page.dart
│   ├── attendance_page.dart
│   └── class_album_page.dart
└── widgets/
    ├── class_card.dart
    ├── member_tile.dart
    ├── announcement_card.dart
    ├── role_badge.dart
    └── qr_attendance_widget.dart
```

### Data Models
```dart
class Classroom {
  final int id;
  final String name, courseCode, joinCode;
  final int semesterId, memberCount;
  final String? description;
  factory Classroom.fromJson(Map<String, dynamic> j) => Classroom(
    id: _parseInt(j['id']),
    name: j['name'] ?? '',
    courseCode: j['course_code'] ?? '',
    joinCode: j['join_code'] ?? '',
    semesterId: _parseInt(j['semester_id']),
    memberCount: _parseInt(j['member_count']),
  );
}

class ClassMember { int id, userId; String name, role; String? avatarUrl, phone; }
class Announcement { int id; String title, body; int authorId; DateTime createdAt; bool pinned; }
class AttendanceRecord { int id, classId; DateTime date; int presentCount, totalCount; }
```

### Service Layer
```dart
class MyClassService {
  static Future<List<Classroom>> getMyClasses(String token);           // GET /api/classes
  static Future<Classroom> createClass(String token, Map body);        // POST /api/classes
  static Future<Classroom> joinClass(String token, String code);       // POST /api/classes/join
  static Future<List<ClassMember>> getRoster(String token, int id);    // GET /api/classes/{id}/members
  static Future<void> updateRole(String token, int id, int uid, String role); // PUT /api/classes/{id}/members/{uid}/role
  static Future<List<Announcement>> getAnnouncements(String token, int id);   // GET /api/classes/{id}/announcements
  static Future<void> postAnnouncement(String token, int id, Map body);       // POST /api/classes/{id}/announcements
  static Future<void> checkInAttendance(String token, int id, String qr);     // POST /api/classes/{id}/attendance
  static Future<void> archiveClass(String token, int id);              // POST /api/classes/{id}/archive
}
```

### Pages & Widgets
- **MyClassesPage**: grid/list toggle of joined classes with unread badges, FAB to create/join
- **ClassHomePage**: hero card with member count, next class, announcements feed, quick-action row
- **ClassRosterPage**: searchable list with role badges, tap to view profile
- **JoinClassPage**: text field for 6-char code + QR scanner
- **CreateClassPage**: form with course code, name, semester picker, department
- **AttendancePage**: calendar heatmap + QR generation (CR) / scanning (student)

---

## 2. UI Design
- Monochromatic: #1A1A1A / #666666 / #FAFAFA / #FFFFFF
- 48dp touch targets, maxLines + ellipsis on all dynamic text, _rounded icons
- Dark hero card showing member count, attendance rate, gender ratio

### Main Screen Wireframe
```
┌─────────────────────────────┐
│  My Classes          [+ ⋮]  │
├─────────────────────────────┤
│ ┌───────────┐ ┌───────────┐ │
│ │ CS 201    │ │ MA 101    │ │
│ │ Data Str. │ │ Calculus  │ │
│ │ 45 members│ │ 120 memb. │ │
│ │ ● 3 new   │ │           │ │
│ └───────────┘ └───────────┘ │
│ ┌───────────┐ ┌───────────┐ │
│ │ EN 100    │ │ PHY 201   │ │
│ │ English   │ │ Physics   │ │
│ └───────────┘ └───────────┘ │
└─────────────────────────────┘
```

---

## 3. Performance Strategy

### SQLite
```sql
CREATE TABLE classrooms(id INTEGER PRIMARY KEY, course_code TEXT, join_code TEXT UNIQUE, json_data TEXT, synced_at TEXT);
CREATE INDEX idx_classrooms_code ON classrooms(join_code);

CREATE TABLE class_members(id INTEGER PRIMARY KEY, class_id INTEGER, user_id INTEGER, role TEXT, json_data TEXT, synced_at TEXT);
CREATE INDEX idx_members_class ON class_members(class_id);

CREATE TABLE announcements(id INTEGER PRIMARY KEY, class_id INTEGER, pinned INTEGER, json_data TEXT, synced_at TEXT);
```
- SQLite first, API background refresh (stale-while-revalidate)
- Offline read: YES — roster, announcements, timetable cached
- Offline write: pending_queue for announcements, attendance check-ins

---

## 4. Backend Implementation

### Database (PostgreSQL)
```sql
CREATE TABLE classrooms(
  id SERIAL PRIMARY KEY, name VARCHAR(255), course_code VARCHAR(50),
  join_code VARCHAR(6) UNIQUE, semester_id INT REFERENCES semesters(id),
  department VARCHAR(255), description TEXT, created_by INT REFERENCES users(id),
  archived_at TIMESTAMP, created_at TIMESTAMP DEFAULT NOW()
);
CREATE TABLE class_members(
  id SERIAL PRIMARY KEY, classroom_id INT REFERENCES classrooms(id),
  user_id INT REFERENCES users(id), role VARCHAR(30) DEFAULT 'member',
  joined_at TIMESTAMP DEFAULT NOW(), UNIQUE(classroom_id, user_id)
);
CREATE TABLE class_announcements(
  id SERIAL PRIMARY KEY, classroom_id INT REFERENCES classrooms(id),
  author_id INT REFERENCES users(id), title VARCHAR(255), body TEXT,
  pinned BOOLEAN DEFAULT FALSE, created_at TIMESTAMP DEFAULT NOW()
);
CREATE TABLE attendance_records(
  id SERIAL PRIMARY KEY, classroom_id INT REFERENCES classrooms(id),
  user_id INT REFERENCES users(id), session_date DATE,
  checked_in_at TIMESTAMP, qr_code VARCHAR(64), UNIQUE(classroom_id, user_id, session_date)
);
```

### API Endpoints
| Method | Endpoint | Description | Auth |
|--------|----------|-------------|------|
| GET | /api/classes | List user's classes | Bearer |
| POST | /api/classes | Create class | Bearer |
| POST | /api/classes/join | Join by code | Bearer |
| GET | /api/classes/{id} | Class detail | Bearer |
| GET | /api/classes/{id}/members | Roster | Bearer |
| PUT | /api/classes/{id}/members/{uid}/role | Update role | Bearer (CR) |
| GET | /api/classes/{id}/announcements | Announcements | Bearer |
| POST | /api/classes/{id}/announcements | Post announcement | Bearer (CR/Lecturer) |
| POST | /api/classes/{id}/attendance | QR check-in | Bearer |
| POST | /api/classes/{id}/archive | Archive class | Bearer (CR) |

### Controller
`app/Http/Controllers/Api/ClassroomController.php`

---

## 5. Integration Wiring
- GroupService.createGroup() — auto-create TAJIRI group on class creation
- CalendarService — class schedule and exam dates sync to personal calendar
- NotificationService + FCM — announcements, room changes, emergency broadcasts
- timetable module — CR-set timetable pushes to all members
- class_chat module — auto-created conversation per class
- study_groups module — create study groups from class membership
- ContributionService — collect class contributions via M-Pesa

---

## 6. Implementation Phases

### Phase 1 — Core (Week 1-2)
- [ ] Classroom model, service, SQLite cache
- [ ] Create class with join code generation
- [ ] Join class via code
- [ ] My Classes list page
- [ ] Class home page with member count

### Phase 2 — Roster & Roles (Week 3)
- [ ] Class roster page with search
- [ ] Role assignment (CR, Assistant CR, Lecturer)
- [ ] Lecturer directory cards
- [ ] Member profile tap → TAJIRI profile

### Phase 3 — Communication (Week 4)
- [ ] Announcements board (post, pin, comment)
- [ ] Push notifications for announcements
- [ ] Emergency broadcast (bypass mute)
- [ ] Auto-create TAJIRI group on class creation

### Phase 4 — Advanced (Week 5-6)
- [ ] QR attendance (generate + scan)
- [ ] Class album (photo upload/grid)
- [ ] Semester archiving and carry-forward
- [ ] Export roster to PDF
- [ ] CR election/voting feature

---

## 7. External APIs & Integrations

| API | Provider | Purpose | Pricing | Integration Notes |
|-----|----------|---------|---------|-------------------|
| Google Classroom API | Google | Course CRUD, roster management, grading periods, announcements | Free (Google Workspace for Education) | OAuth 2.0, REST v1. Requires Google Workspace admin approval. Could sync TAJIRI classes with Google Classroom. |
| Canvas LMS REST API | Instructure | Full LMS: courses, modules, enrollments, grades | Free (with Canvas instance) | OpenAPI 3.0 spec. OAuth2. For universities already using Canvas. |
| Moodle Web Services API | Moodle | Course management, user enrollment, grade book | Free (self-hosted Moodle) | REST endpoint at `/webservice/rest/server.php`. 400+ API functions. |
| TAJIRI GroupService (internal) | TAJIRI | Auto-create group on class creation | N/A | Already built. Each class auto-creates a TAJIRI group with integrated chat. |

**Tanzania context:** Most Tanzanian universities use custom portals (ARIS, SARIS, OSIM). No standardized API exists -- would need web scraping or institutional partnerships for roster import.

### Integration Priority
1. **Immediate** -- TAJIRI GroupService (internal, already built), QR code generation (`qr_flutter` package on pub.dev)
2. **Short-term** -- Google Classroom API (free, good for institutions using Google Workspace)
3. **Partnership** -- Canvas/Moodle LMS integration (requires institutional instance), university portal scraping (ARIS/SARIS)
