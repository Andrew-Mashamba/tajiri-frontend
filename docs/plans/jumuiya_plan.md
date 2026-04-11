# Jumuiya (Small Groups) — Implementation Plan

## Overview
Small Christian community (cell group) management with group discovery, weekly meetings, Bible study materials, attendance tracking, contribution management, and leader tools. Built for Tanzania's jumuiya ndogo ndogo tradition.

---

## 1. Frontend Architecture

### Directory Structure
```
lib/jumuiya/
├── jumuiya_module.dart
├── models/
│   ├── jumuiya_group.dart
│   ├── meeting.dart
│   ├── study_guide.dart
│   ├── attendance_record.dart
│   └── group_contribution.dart
├── services/
│   └── jumuiya_service.dart         — AuthenticatedDio.instance
├── pages/
│   ├── jumuiya_home_page.dart
│   ├── group_finder_page.dart
│   ├── group_profile_page.dart
│   ├── group_chat_page.dart
│   ├── meeting_view_page.dart
│   ├── bible_study_page.dart
│   ├── members_list_page.dart
│   ├── contribution_tracker_page.dart
│   └── group_calendar_page.dart
└── widgets/
    ├── group_card.dart
    ├── meeting_countdown.dart
    ├── attendance_check.dart
    ├── member_role_badge.dart
    ├── study_question_card.dart
    └── contribution_tile.dart
```

### Data Models
- **JumuiyaGroup** — `id`, `name`, `description`, `churchId`, `meetingDay`, `meetingTime`, `location`, `leaderId`, `memberCount`, `lat`, `lng`. `_parseInt`, `_parseDouble`.
- **Meeting** — `id`, `groupId`, `date`, `agenda`, `biblePassage`, `hostName`, `attendeeCount`. `_parseInt`.
- **StudyGuide** — `id`, `title`, `passage`, `questions` (List<String>), `notes`.
- **AttendanceRecord** — `id`, `meetingId`, `userId`, `isPresent`. `_parseBool`.
- **GroupContribution** — `id`, `groupId`, `userId`, `amount`, `purpose`, `date`. `_parseDouble`.

### Service Layer
```dart
Dio get _dio => AuthenticatedDio.instance;
```
- `getMyGroups()` — `GET /api/jumuiya/my-groups`
- `findGroups({double? lat, double? lng, int? churchId})` — `GET /api/jumuiya/find`
- `getGroup(int id)` — `GET /api/jumuiya/{id}`
- `joinGroup(int id)` — `POST /api/jumuiya/{id}/join`
- `getUpcomingMeeting(int groupId)` — `GET /api/jumuiya/{id}/next-meeting`
- `checkInAttendance(int meetingId, List<int> userIds)` — `POST /api/jumuiya/meetings/{id}/attendance`
- `getStudyGuide(int meetingId)` — `GET /api/jumuiya/meetings/{id}/study`
- `recordContribution(int groupId, Map data)` — `POST /api/jumuiya/{id}/contributions`
- `getContributions(int groupId)` — `GET /api/jumuiya/{id}/contributions`

### Pages
- **JumuiyaHomePage** — My groups list, next meeting countdown, recent messages
- **GroupFinderPage** — Map and list view of nearby groups with filters
- **GroupProfilePage** — Banner, description, schedule, members, join button
- **MeetingViewPage** — Agenda, Bible passage, discussion questions, attendance check-in
- **BibleStudyPage** — Guided study with passage, context, questions, notes space
- **ContributionTrackerPage** — Group fund balance, contribution history, member ledger

### Widgets
- `MeetingCountdown` — Timer to next group meeting
- `AttendanceCheck` — Check-in toggle per member with timestamp

---

## 2. UI Design
- #1A1A1A/#666666/#FAFAFA/#FFFFFF monochromatic
- 48dp touch, maxLines+ellipsis, _rounded icons
- Dark stat cards for attendance rate and group fund
- Cards: radius 12-16, subtle shadow

### Main Screen Wireframe
```
┌─────────────────────────────┐
│ ← Jumuiya              🔍   │
├─────────────────────────────┤
│  My Groups                  │
│ ┌─────────────────────────┐ │
│ │ Jumuiya ya Upendo       │ │
│ │ Wed 6PM • 12 members    │ │
│ │ Next: Tomorrow ⏱ 18h    │ │
│ └─────────────────────────┘ │
│ ┌─────────────────────────┐ │
│ │ Jumuiya ya Amani        │ │
│ │ Thu 7PM • 8 members     │ │
│ └─────────────────────────┘ │
│                             │
│  This Week's Study          │
│ ┌─────────────────────────┐ │
│ │ Mathayo 5:1-12          │ │
│ │ Beatitudes • 4 questions│ │
│ │              [Open]     │ │
│ └─────────────────────────┘ │
│                             │
│  [Find Groups] [Calendar]   │
└─────────────────────────────┘
```

---

## 3. Performance Strategy

### SQLite
```sql
CREATE TABLE jumuiya_groups(id INTEGER PRIMARY KEY, name TEXT, church_id INTEGER, meeting_day TEXT, json_data TEXT, synced_at TEXT);
CREATE TABLE meetings(id INTEGER PRIMARY KEY, group_id INTEGER, date TEXT, json_data TEXT, synced_at TEXT);
CREATE TABLE contributions(id INTEGER PRIMARY KEY, group_id INTEGER, amount REAL, json_data TEXT, synced_at TEXT);
```
- Stale-while-revalidate: SQLite first, API background
- TTL: group list — 1 hour, meetings — 30 minutes
- Offline: read YES, write attendance/contributions via pending_queue

---

## 4. Backend Implementation

### Database
```sql
CREATE TABLE jumuiya_groups(id BIGSERIAL PRIMARY KEY, name VARCHAR(200), description TEXT, church_id BIGINT, meeting_day VARCHAR(20), meeting_time TIME, location TEXT, leader_id BIGINT, lat DOUBLE PRECISION, lng DOUBLE PRECISION, member_count INTEGER DEFAULT 0, created_at TIMESTAMP DEFAULT NOW());

CREATE TABLE jumuiya_members(id BIGSERIAL PRIMARY KEY, group_id BIGINT, user_id BIGINT, role VARCHAR(30) DEFAULT 'member', joined_at TIMESTAMP DEFAULT NOW());

CREATE TABLE jumuiya_meetings(id BIGSERIAL PRIMARY KEY, group_id BIGINT, meeting_date DATE, agenda TEXT, bible_passage VARCHAR(100), host_name VARCHAR(200), attendee_count INTEGER DEFAULT 0);

CREATE TABLE jumuiya_attendance(id BIGSERIAL PRIMARY KEY, meeting_id BIGINT, user_id BIGINT, is_present BOOLEAN DEFAULT TRUE, checked_at TIMESTAMP DEFAULT NOW());

CREATE TABLE jumuiya_contributions(id BIGSERIAL PRIMARY KEY, group_id BIGINT, user_id BIGINT, amount DECIMAL(15,2), purpose VARCHAR(200), contribution_date DATE, created_at TIMESTAMP DEFAULT NOW());

CREATE TABLE jumuiya_study_guides(id BIGSERIAL PRIMARY KEY, title VARCHAR(200), passage VARCHAR(100), questions JSONB, notes TEXT, week_date DATE);
```

### API Endpoints
| Method | Endpoint | Description | Auth |
|--------|----------|-------------|------|
| GET | /api/jumuiya/my-groups | User's groups | Bearer |
| GET | /api/jumuiya/find | Find nearby groups | Bearer |
| GET | /api/jumuiya/{id} | Group detail | Bearer |
| POST | /api/jumuiya/{id}/join | Join group | Bearer |
| GET | /api/jumuiya/{id}/next-meeting | Next meeting | Bearer |
| POST | /api/jumuiya/meetings/{id}/attendance | Check in | Bearer |
| GET | /api/jumuiya/meetings/{id}/study | Study guide | Bearer |
| POST | /api/jumuiya/{id}/contributions | Record contribution | Bearer |
| GET | /api/jumuiya/{id}/contributions | Contribution history | Bearer |

### Controller
`app/Http/Controllers/Api/JumuiyaController.php` — DB facade with proximity search and role-based access.

---

## 5. Integration Wiring
- **GroupService** — each jumuiya is a TAJIRI group with roles
- **MessageService** — group chat for Bible study discussion and prayer requests
- **CalendarService** — weekly meeting schedule and host rotation synced
- **ContributionService** — emergency fund and church project contributions
- **Biblia** — study passages open in Bible reader
- **Sala** — prayer requests shared between group and journal
- **Kanisa Langu** — jumuiya linked to parent church

---

## 6. Implementation Phases
### Phase 1: Foundation (Week 1)
- Data models, service layer, SQLite schema
- Backend tables and group CRUD
- Group finder with proximity search

### Phase 2: Core UI (Week 2)
- Group profile with meeting schedule
- Meeting view with agenda and Bible study
- Attendance tracking

### Phase 3: Integration (Week 3)
- Group chat integration
- Contribution tracker with member ledger
- Bible study cross-references

### Phase 4: Polish (Week 4)
- Leader tools (manage members, reports)
- Host rotation calendar
- Offline support, photo sharing

---

## 7. External APIs & Integrations

| API | Provider | Purpose | Pricing | Integration Notes |
|-----|----------|---------|---------|-------------------|
| Planning Center Groups API | Planning Center | Group creation, membership, events, attendance | Free for small churches | Part of Planning Center API suite; developer.planning.center |
| ChurchSuite Small Groups API | ChurchSuite | Group management, signups, attendance tracking | Paid (subscription) | Embed API for group listings; developer API for full CRUD |
| Elvanto Groups API | Elvanto | Group management, member assignment, scheduling | Paid (subscription) | Part of Elvanto API; elvanto.com/api |
| bible-api.com | Open source | Bible study verse lookup for group discussions | Free, no auth | Simple verse retrieval for study materials |

### Integration Priority
1. **Immediate** — Free APIs (bible-api.com for group Bible study content)
2. **Short-term** — Planning Center Groups (free for small churches)
3. **Partnership** — ChurchSuite, Elvanto, FellowshipOne (require subscriptions)
