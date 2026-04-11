# Study Groups / Vikundi vya Kusoma — Implementation Plan

## Overview
Collaborative study group platform built on TAJIRI groups. Create/join study groups by subject, schedule sessions with location and topic, synchronized Pomodoro timers, shared notes, contribution tracking, group quiz battles, leaderboard, voice/video study rooms, digital whiteboard, and nearby study partner discovery.

---

## 1. Frontend Architecture

### Directory Structure
```
lib/study_groups/
├── study_groups_module.dart
├── models/
│   ├── study_group.dart
│   ├── study_session.dart
│   ├── member_contribution.dart
│   └── study_stats.dart
├── services/
│   └── study_groups_service.dart    — AuthenticatedDio.instance
├── pages/
│   ├── study_groups_home_page.dart
│   ├── group_detail_page.dart
│   ├── create_group_page.dart
│   ├── discover_groups_page.dart
│   ├── schedule_session_page.dart
│   ├── session_view_page.dart
│   ├── group_chat_page.dart
│   ├── shared_materials_page.dart
│   ├── leaderboard_page.dart
│   └── find_partners_page.dart
└── widgets/
    ├── group_card.dart
    ├── session_card.dart
    ├── contribution_tile.dart
    ├── sync_timer.dart
    ├── topic_checklist.dart
    ├── member_avatar_row.dart
    └── partner_card.dart
```

### Data Models
```dart
class StudyGroup {
  final int id;
  final String name, subject, description;
  final int memberCount, maxMembers;
  final bool isPrivate;
  final String? institution;
  final int sessionCount;
  final int streakDays;
  factory StudyGroup.fromJson(Map<String, dynamic> j) => StudyGroup(
    id: _parseInt(j['id']),
    name: j['name'] ?? '',
    subject: j['subject'] ?? '',
    description: j['description'] ?? '',
    memberCount: _parseInt(j['member_count']),
    maxMembers: _parseInt(j['max_members']),
    isPrivate: _parseBool(j['is_private']),
    streakDays: _parseInt(j['streak_days']),
  );
}

class StudySession {
  int id, groupId; String topic, location;
  DateTime scheduledAt; int durationMinutes;
  List<int> attendeeIds; bool isVirtual;
}

class MemberContribution {
  int userId; String name; int notesShared, questionsAsked, questionsAnswered;
  int sessionsAttended; double participationScore;
}

class StudyStats { int totalHours, sessionsCompleted, topicsCovered, streakDays; }
```

### Service Layer
```dart
class StudyGroupsService {
  static Future<List<StudyGroup>> getMyGroups(String token);                   // GET /api/study-groups
  static Future<StudyGroup> createGroup(String token, Map body);               // POST /api/study-groups
  static Future<StudyGroup> getGroupDetail(String token, int id);              // GET /api/study-groups/{id}
  static Future<void> joinGroup(String token, int id);                         // POST /api/study-groups/{id}/join
  static Future<void> leaveGroup(String token, int id);                        // POST /api/study-groups/{id}/leave
  static Future<List<StudySession>> getSessions(String token, int groupId);    // GET /api/study-groups/{id}/sessions
  static Future<StudySession> scheduleSession(String token, int id, Map body); // POST /api/study-groups/{id}/sessions
  static Future<void> checkInSession(String token, int sessionId);             // POST /api/study-groups/sessions/{id}/check-in
  static Future<List<MemberContribution>> getContributions(String token, int id); // GET /api/study-groups/{id}/contributions
  static Future<List<StudyGroup>> discoverGroups(String token, {String? subject, String? institution}); // GET /api/study-groups/discover
  static Future<List<Map>> findPartners(String token, String subject);         // GET /api/study-groups/find-partners?subject=
  static Future<void> archiveGroup(String token, int id);                      // POST /api/study-groups/{id}/archive
}
```

### Pages & Widgets
- **StudyGroupsHomePage**: my groups list with next session info, discover section, FAB to create
- **GroupDetailPage**: overview with members, next session, shared notes, chat preview, stats
- **CreateGroupPage**: form with name, subject, description, max members, privacy toggle
- **DiscoverGroupsPage**: browse/search with filters for subject, institution, group size
- **ScheduleSessionPage**: set date, time, location (physical/virtual), topic, send invites
- **SessionViewPage**: active session with synced timer, attendance check-in, topic checklist
- **LeaderboardPage**: member rankings by contributions, attendance, quiz performance
- **FindPartnersPage**: list of nearby students studying the same subject

---

## 2. UI Design
- Monochromatic: #1A1A1A / #666666 / #FAFAFA / #FFFFFF
- 48dp touch targets, maxLines + ellipsis, _rounded icons
- Group cards show member avatars (stacked), subject, next session, streak badge
- Dark hero card: "Next session in 2h — Binary Trees" with group name

### Main Screen Wireframe
```
┌──────────────────────────────┐
│  Study Groups        [+ 🔍] │
├──────────────────────────────┤
│ ┌──────────────────────────┐ │
│ │ Next: CS201 Study Group  │ │
│ │ Binary Trees · in 2h     │ │
│ │ Library Room 3 · 4 going │ │
│ └──────────────────────────┘ │
│                              │
│ MY GROUPS                    │
│ ┌──────────────────────────┐ │
│ │ CS201 Study Group        │ │
│ │ 👤👤👤👤 6/8 · 🔥 8-day  │ │
│ │ Next: Today 3PM          │ │
│ ├──────────────────────────┤ │
│ │ MA101 Calculus Crew      │ │
│ │ 👤👤👤 4/6 · 🔥 3-day    │ │
│ │ Next: Tomorrow 10AM      │ │
│ └──────────────────────────┘ │
│                              │
│ DISCOVER                     │
│ ┌──────────────────────────┐ │
│ │ PHY201 Physics Lab Prep  │ │
│ │ 3/8 members · Open       │ │
│ └──────────────────────────┘ │
└──────────────────────────────┘
```

---

## 3. Performance Strategy

### SQLite
```sql
CREATE TABLE study_groups(id INTEGER PRIMARY KEY, name TEXT, subject TEXT, member_count INTEGER, json_data TEXT, synced_at TEXT);
CREATE INDEX idx_sg_subject ON study_groups(subject);

CREATE TABLE study_sessions(id INTEGER PRIMARY KEY, group_id INTEGER, scheduled_at TEXT, topic TEXT, json_data TEXT, synced_at TEXT);
CREATE INDEX idx_ss_group ON study_sessions(group_id);
CREATE INDEX idx_ss_date ON study_sessions(scheduled_at);

CREATE TABLE member_contributions(id INTEGER PRIMARY KEY, group_id INTEGER, user_id INTEGER, json_data TEXT, synced_at TEXT);
```
- SQLite first, API background refresh (stale-while-revalidate)
- Offline read: YES — group details, sessions, shared materials cached
- Offline write: pending_queue for session check-ins, material uploads

---

## 4. Backend Implementation

### Database (PostgreSQL)
```sql
CREATE TABLE study_groups(
  id SERIAL PRIMARY KEY, name VARCHAR(255), subject VARCHAR(255),
  description TEXT, institution VARCHAR(255),
  max_members SMALLINT DEFAULT 8, is_private BOOLEAN DEFAULT FALSE,
  creator_id INT REFERENCES users(id), group_id INT REFERENCES groups(id),
  streak_days INT DEFAULT 0, archived_at TIMESTAMP,
  created_at TIMESTAMP DEFAULT NOW()
);
CREATE TABLE study_group_members(
  id SERIAL PRIMARY KEY, study_group_id INT REFERENCES study_groups(id),
  user_id INT REFERENCES users(id), role VARCHAR(30) DEFAULT 'member',
  joined_at TIMESTAMP DEFAULT NOW(), UNIQUE(study_group_id, user_id)
);
CREATE TABLE study_sessions(
  id SERIAL PRIMARY KEY, study_group_id INT REFERENCES study_groups(id),
  topic VARCHAR(255), location VARCHAR(255), is_virtual BOOLEAN DEFAULT FALSE,
  scheduled_at TIMESTAMP, duration_minutes INT DEFAULT 120,
  created_by INT REFERENCES users(id), created_at TIMESTAMP DEFAULT NOW()
);
CREATE TABLE session_check_ins(
  id SERIAL PRIMARY KEY, session_id INT REFERENCES study_sessions(id),
  user_id INT REFERENCES users(id), checked_in_at TIMESTAMP DEFAULT NOW(),
  UNIQUE(session_id, user_id)
);
CREATE TABLE member_contributions(
  id SERIAL PRIMARY KEY, study_group_id INT REFERENCES study_groups(id),
  user_id INT REFERENCES users(id),
  notes_shared INT DEFAULT 0, questions_asked INT DEFAULT 0,
  questions_answered INT DEFAULT 0, sessions_attended INT DEFAULT 0,
  participation_score DECIMAL(5,2) DEFAULT 0
);
CREATE TABLE study_group_materials(
  id SERIAL PRIMARY KEY, study_group_id INT REFERENCES study_groups(id),
  uploader_id INT REFERENCES users(id), title VARCHAR(255),
  file_url TEXT, file_type VARCHAR(50), created_at TIMESTAMP DEFAULT NOW()
);
```

### API Endpoints
| Method | Endpoint | Description | Auth |
|--------|----------|-------------|------|
| GET | /api/study-groups | My groups | Bearer |
| POST | /api/study-groups | Create group | Bearer |
| GET | /api/study-groups/{id} | Group detail | Bearer |
| POST | /api/study-groups/{id}/join | Join group | Bearer |
| POST | /api/study-groups/{id}/leave | Leave group | Bearer |
| GET | /api/study-groups/{id}/sessions | Group sessions | Bearer |
| POST | /api/study-groups/{id}/sessions | Schedule session | Bearer |
| POST | /api/study-groups/sessions/{id}/check-in | Check in | Bearer |
| GET | /api/study-groups/{id}/contributions | Leaderboard | Bearer |
| GET | /api/study-groups/discover | Browse groups | Bearer |
| GET | /api/study-groups/find-partners | Nearby partners | Bearer |
| POST | /api/study-groups/{id}/archive | Archive group | Bearer |

### Controller
`app/Http/Controllers/Api/StudyGroupsController.php`

---

## 5. Integration Wiring
- GroupService — study group = TAJIRI group; create, join, manage with roles
- MessageService — group chat powered by TAJIRI messaging
- CalendarService — study sessions sync to personal calendar
- NotificationService + FCM — session reminders, new material alerts, quiz invites
- ProfileService — membership, contribution stats, badges on profile
- FriendService — find study partners among friends and mutual connections
- my_class module — study groups created from class membership
- class_notes module — shared notes link to notes repository
- exam_prep module — group quiz battles use exam prep quiz engine
- timetable module — sessions during free periods
- newton module — AI joins sessions to answer questions

---

## 6. Implementation Phases

### Phase 1 — Core Groups (Week 1-2)
- [ ] StudyGroup model, service, SQLite cache
- [ ] Create group with name, subject, max members, privacy
- [ ] Study groups home page with my groups list
- [ ] Group detail page with members and stats

### Phase 2 — Sessions (Week 3)
- [ ] Schedule session with date, time, location, topic
- [ ] Session view with attendance check-in
- [ ] Synchronized Pomodoro timer
- [ ] Topic checklist tracking

### Phase 3 — Community (Week 4)
- [ ] Discover groups with search/filters
- [ ] Find study partners nearby
- [ ] Contribution tracking and leaderboard
- [ ] Shared materials upload and browsing

### Phase 4 — Advanced (Week 5-6)
- [ ] Group quiz battles
- [ ] Voice/video study room integration
- [ ] Digital whiteboard
- [ ] Study streak tracking with badges
- [ ] Group recommendations (AI-suggested)
- [ ] End-of-semester archiving

---

## 7. External APIs & Integrations

| API | Provider | Purpose | Pricing | Integration Notes |
|-----|----------|---------|---------|-------------------|
| TAJIRI GroupService (internal) | TAJIRI | Group management, membership, roles | N/A | Already built. Study group = TAJIRI group. Create, join, manage with roles. **No external API needed.** |
| TAJIRI MessageService (internal) | TAJIRI | Group chat powered by TAJIRI messaging | N/A | Already built. Real-time messaging within study groups. |
| Firebase Realtime Database | Google | Real-time collaboration, shared state (synced timers) | Free: 1GB stored, 10GB/mo transfer | Already in TAJIRI stack. Good for real-time synchronized Pomodoro timers and session state. |
| Firebase Firestore | Google | Structured data, real-time sync | Free tier generous | Already used by TAJIRI for live updates. Model study group activities and contribution tracking. |
| Miro API | Miro | Collaborative whiteboard for study sessions | Free: 3 boards; Paid from $8/user/mo | REST API. Visual collaboration for study sessions. Consider for digital whiteboard feature. |

**Recommendation:** Use TAJIRI's existing groups + Firebase infrastructure. No external API needed for core functionality.

### Integration Priority
1. **Immediate** -- TAJIRI GroupService + MessageService + Firebase (all internal, already built and integrated)
2. **Short-term** -- Firebase Realtime Database for synchronized Pomodoro timers and session state
3. **Partnership** -- Miro API (for collaborative whiteboard feature, free tier limited to 3 boards)
