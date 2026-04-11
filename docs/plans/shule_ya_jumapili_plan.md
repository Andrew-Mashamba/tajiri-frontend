# Shule ya Jumapili (Sunday School) — Implementation Plan

## Overview
Sunday School management for Tanzanian churches with age-grouped lesson plans, curriculum library, teacher resources, attendance tracking, memory verses, parent notifications, and child progress tracking.

---

## 1. Frontend Architecture

### Directory Structure
```
lib/shule_ya_jumapili/
├── shule_ya_jumapili_module.dart
├── models/
│   ├── lesson_plan.dart
│   ├── curriculum.dart
│   ├── child_profile.dart
│   ├── attendance.dart
│   ├── memory_verse.dart
│   └── teacher_schedule.dart
├── services/
│   └── sunday_school_service.dart   — AuthenticatedDio.instance
├── pages/
│   ├── sunday_school_home_page.dart
│   ├── lesson_viewer_page.dart
│   ├── curriculum_browser_page.dart
│   ├── attendance_dashboard_page.dart
│   ├── memory_verse_tracker_page.dart
│   ├── activity_library_page.dart
│   ├── teacher_dashboard_page.dart
│   ├── parent_view_page.dart
│   └── child_profile_page.dart
└── widgets/
    ├── lesson_card.dart
    ├── age_group_chip.dart
    ├── attendance_grid.dart
    ├── verse_practice_card.dart
    ├── achievement_badge.dart
    └── teacher_schedule_tile.dart
```

### Data Models
- **LessonPlan** — `id`, `title`, `ageGroup` (watoto_wadogo/watoto_wakubwa/vijana), `curriculumId`, `weekDate`, `bibleStory`, `objective`, `activities`, `memoryVerse`. Uses `fromJson`.
- **Curriculum** — `id`, `title`, `description`, `ageGroup`, `durationWeeks`, `lessonCount`, `coverUrl`. `_parseInt`.
- **ChildProfile** — `id`, `name`, `ageGroup`, `parentUserId`, `attendanceCount`, `versesMemorized`, `badges` (List). `_parseInt`.
- **Attendance** — `id`, `classId`, `childId`, `date`, `isPresent`. `_parseBool`.
- **MemoryVerse** — `id`, `verseRef`, `text`, `weekDate`, `isMemorized`. `_parseBool`.
- **TeacherSchedule** — `id`, `teacherUserId`, `classId`, `date`, `ageGroup`.

### Service Layer
```dart
Dio get _dio => AuthenticatedDio.instance;
```
- `getThisWeekLesson(String ageGroup)` — `GET /api/sunday-school/lessons/current?age={ageGroup}`
- `getCurricula()` — `GET /api/sunday-school/curricula`
- `checkInAttendance(int classId, List<int> childIds)` — `POST /api/sunday-school/attendance`
- `getAttendance(int classId, {String? date})` — `GET /api/sunday-school/attendance/{classId}`
- `getChildProfile(int childId)` — `GET /api/sunday-school/children/{childId}`
- `markVerseMemorized(int childId, int verseId)` — `PUT /api/sunday-school/verses/{verseId}/memorized`
- `getTeacherSchedule(int userId)` — `GET /api/sunday-school/teachers/{userId}/schedule`
- `getParentSummary(int parentId)` — `GET /api/sunday-school/parents/{parentId}/summary`

### Pages
- **SundaySchoolHomePage** — This week's lesson, teacher schedule, quick attendance
- **LessonViewerPage** — Structured lesson: opening, Bible story, discussion, activity, closing
- **CurriculumBrowserPage** — Series cards with age group, duration, preview
- **AttendanceDashboardPage** — Class list with check-in buttons, history
- **MemoryVerseTrackerPage** — Verse display, practice mode, child progress
- **TeacherDashboardPage** — My classes, upcoming lessons, assigned dates
- **ParentViewPage** — Child's progress, attendance, this week's summary

### Widgets
- `AgeGroupChip` — Color-coded chip for watoto wadogo/wakubwa/vijana
- `AchievementBadge` — Circular badge for verse memorization and attendance

---

## 2. UI Design
- #1A1A1A/#666666/#FAFAFA/#FFFFFF monochromatic
- 48dp touch, maxLines+ellipsis, _rounded icons
- Dark stat cards for attendance rate and verses memorized
- Cards: radius 12-16, subtle shadow

### Main Screen Wireframe
```
┌─────────────────────────────┐
│ ← Shule ya Jumapili     ⚙️   │
├─────────────────────────────┤
│  This Week's Lesson         │
│ ┌─────────────────────────┐ │
│ │ Daudi na Goliathi       │ │
│ │ 1 Samuel 17             │ │
│ │ Age: Watoto Wakubwa     │ │
│ │              [View]     │ │
│ └─────────────────────────┘ │
│                             │
│  Memory Verse               │
│ ┌─────────────────────────┐ │
│ │ "The Lord is my..."     │ │
│ │ Zaburi 23:1  [Practice] │ │
│ └─────────────────────────┘ │
│                             │
│  Quick Attendance           │
│  Class: Watoto Wakubwa      │
│  Present: 12/15  [Check In] │
│                             │
│ [Lessons][Teachers][Parents]│
└─────────────────────────────┘
```

---

## 3. Performance Strategy

### SQLite
```sql
CREATE TABLE lessons(id INTEGER PRIMARY KEY, age_group TEXT, week_date TEXT, json_data TEXT, synced_at TEXT);
CREATE TABLE children(id INTEGER PRIMARY KEY, name TEXT, age_group TEXT, parent_id INTEGER, json_data TEXT, synced_at TEXT);
CREATE TABLE ss_attendance(id INTEGER PRIMARY KEY, class_id INTEGER, child_id INTEGER, date TEXT, is_present INTEGER, synced_at TEXT);
```
- Stale-while-revalidate: SQLite first, API background
- TTL: lessons — 24 hours, attendance — 15 minutes
- Offline: read YES, write attendance via pending_queue

---

## 4. Backend Implementation

### Database
```sql
CREATE TABLE ss_curricula(id BIGSERIAL PRIMARY KEY, title VARCHAR(200), description TEXT, age_group VARCHAR(30), duration_weeks INTEGER, lesson_count INTEGER, cover_url VARCHAR(500));

CREATE TABLE ss_lessons(id BIGSERIAL PRIMARY KEY, curriculum_id BIGINT, title VARCHAR(200), age_group VARCHAR(30), week_date DATE, bible_story VARCHAR(200), objective TEXT, activities JSONB, memory_verse VARCHAR(200), created_at TIMESTAMP DEFAULT NOW());

CREATE TABLE ss_children(id BIGSERIAL PRIMARY KEY, name VARCHAR(200), age_group VARCHAR(30), parent_user_id BIGINT, church_id BIGINT, created_at TIMESTAMP DEFAULT NOW());

CREATE TABLE ss_attendance(id BIGSERIAL PRIMARY KEY, lesson_id BIGINT, child_id BIGINT, attendance_date DATE, is_present BOOLEAN DEFAULT TRUE);

CREATE TABLE ss_memory_verses(id BIGSERIAL PRIMARY KEY, verse_ref VARCHAR(100), text TEXT, week_date DATE, child_id BIGINT, is_memorized BOOLEAN DEFAULT FALSE);

CREATE TABLE ss_teacher_schedules(id BIGSERIAL PRIMARY KEY, teacher_user_id BIGINT, class_age_group VARCHAR(30), scheduled_date DATE, church_id BIGINT);
```

### API Endpoints
| Method | Endpoint | Description | Auth |
|--------|----------|-------------|------|
| GET | /api/sunday-school/lessons/current | This week's lesson | Bearer |
| GET | /api/sunday-school/curricula | Browse curricula | Bearer |
| POST | /api/sunday-school/attendance | Check-in children | Bearer |
| GET | /api/sunday-school/attendance/{classId} | Attendance history | Bearer |
| GET | /api/sunday-school/children/{id} | Child profile | Bearer |
| PUT | /api/sunday-school/verses/{id}/memorized | Mark memorized | Bearer |
| GET | /api/sunday-school/teachers/{id}/schedule | Teacher schedule | Bearer |
| GET | /api/sunday-school/parents/{id}/summary | Parent summary | Bearer |

### Controller
`app/Http/Controllers/Api/SundaySchoolController.php` — DB facade with age-group filtering and parent access control.

---

## 5. Integration Wiring
- **Kanisa Langu** — Sunday School as ministry within church profile
- **MessageService** — teacher-parent communication channel
- **NotificationService** — parent lesson summaries, teacher reminders
- **Biblia** — memory verses and lesson scriptures link to Bible reader
- **Ibada** — children's worship song playlists
- **CalendarService** — class schedules and special events synced
- **my_family** — children's progress visible in family module

---

## 6. Implementation Phases
### Phase 1: Foundation (Week 1)
- Data models, service layer, SQLite schema
- Backend tables and CRUD endpoints
- Curriculum and lesson data structure

### Phase 2: Core UI (Week 2)
- Lesson viewer with structured sections
- Attendance dashboard with check-in
- Memory verse tracker

### Phase 3: Integration (Week 3)
- Teacher dashboard and scheduling
- Parent view with weekly summaries
- Bible cross-references

### Phase 4: Polish (Week 4)
- Achievement badges and certificates
- Activity library (printable worksheets)
- Offline support, push notifications

---

## 7. External APIs & Integrations

| API | Provider | Purpose | Pricing | Integration Notes |
|-----|----------|---------|---------|-------------------|
| API.Bible | American Bible Society | Bible text for children's lessons and quizzes | Free (API key) | Filter by version (NLT, ICB); build lesson content dynamically |
| bible-api.com | Open source | Simple verse lookup for lesson scriptures | Free, no auth | Minimal REST; easiest to integrate for kids content |
| Bible Brain (Kids audio) | Faith Comes By Hearing | Audio Bible for children's listening activities | Free for non-commercial | Audio content in multiple languages; great for listening exercises |
| Planning Center Services API | Planning Center | Schedule teachers, track attendance, manage rotas | Paid (subscription) | Manage Sunday School volunteer schedules |

**Note:** No dedicated Sunday School curriculum REST APIs exist. Best approach: use Bible APIs for scripture content and church management APIs for scheduling/attendance.

### Integration Priority
1. **Immediate** — Free APIs (bible-api.com for verse content, Bible Brain for audio)
2. **Short-term** — Freemium APIs (API.Bible for multi-version children's content)
3. **Partnership** — Planning Center Services (teacher scheduling), Group Publishing / Wonder Ink (curriculum)
