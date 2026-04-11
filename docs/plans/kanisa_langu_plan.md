# Kanisa Langu (My Church) — Implementation Plan

## Overview
Comprehensive church engagement hub with profile, announcements, events, sermon library, member directory, groups, volunteer management, and giving integration. Central hub for church digital life in Tanzania.

---

## 1. Frontend Architecture

### Directory Structure
```
lib/kanisa_langu/
├── kanisa_langu_module.dart
├── models/
│   ├── church.dart
│   ├── church_announcement.dart
│   ├── church_event.dart
│   ├── church_group.dart
│   ├── service_schedule.dart
│   └── volunteer_slot.dart
├── services/
│   └── church_service.dart          — AuthenticatedDio.instance
├── pages/
│   ├── church_home_page.dart
│   ├── announcements_page.dart
│   ├── events_calendar_page.dart
│   ├── sermon_library_page.dart
│   ├── member_directory_page.dart
│   ├── groups_list_page.dart
│   ├── volunteer_board_page.dart
│   └── church_settings_page.dart
└── widgets/
    ├── church_banner.dart
    ├── announcement_card.dart
    ├── event_card.dart
    ├── sermon_tile.dart
    ├── member_tile.dart
    └── service_countdown.dart
```

### Data Models
- **Church** — `id`, `name`, `denomination`, `location`, `lat`, `lng`, `pastorName`, `phone`, `photoUrl`, `serviceTimes` (List), `memberCount`. `_parseDouble` for lat/lng, `_parseInt` for memberCount.
- **ChurchAnnouncement** — `id`, `churchId`, `title`, `content`, `authorName`, `isPinned`, `createdAt`. `_parseBool`.
- **ChurchEvent** — `id`, `churchId`, `title`, `description`, `startTime`, `endTime`, `location`, `rsvpCount`. `_parseInt`.
- **VolunteerSlot** — `id`, `churchId`, `role`, `date`, `assignedUserId`, `isFilled`. `_parseBool`.

### Service Layer
```dart
Dio get _dio => AuthenticatedDio.instance;
```
- `getChurch(int churchId)` — `GET /api/church/{churchId}`
- `getAnnouncements(int churchId)` — `GET /api/church/{churchId}/announcements`
- `getEvents(int churchId)` — `GET /api/church/{churchId}/events`
- `rsvpEvent(int eventId)` — `POST /api/church/events/{eventId}/rsvp`
- `getMembers(int churchId)` — `GET /api/church/{churchId}/members`
- `getGroups(int churchId)` — `GET /api/church/{churchId}/groups`
- `getVolunteerSlots(int churchId)` — `GET /api/church/{churchId}/volunteers`
- `signUpVolunteer(int slotId)` — `POST /api/church/volunteers/{slotId}/signup`

### Pages
- **ChurchHomePage** — Banner image, next service countdown, latest announcement, quick actions
- **AnnouncementsPage** — Chronological list with push notification badges
- **EventsCalendarPage** — Month/list view with event cards and RSVP
- **SermonLibraryPage** — Searchable grid with audio/video player
- **MemberDirectoryPage** — Alphabetical list with search, tap for profile
- **VolunteerBoardPage** — Available roles with sign-up buttons

### Widgets
- `ServiceCountdown` — Timer to next Sunday service
- `AnnouncementCard` — Pinnable card with title, preview, and timestamp

---

## 2. UI Design
- #1A1A1A/#666666/#FAFAFA/#FFFFFF monochromatic
- 48dp touch, maxLines+ellipsis, _rounded icons
- Dark stat cards for member count, next service
- Cards: radius 12-16, subtle shadow

### Main Screen Wireframe
```
┌─────────────────────────────┐
│ ← Kanisa Langu          ⚙️   │
├─────────────────────────────┤
│ ┌─────────────────────────┐ │
│ │  [Church Banner Photo]  │ │
│ │  Kanisa la ELCT Moshi   │ │
│ │  Next Service: Sun 9AM  │ │
│ │  ⏱ 2d 14h 32m          │ │
│ └─────────────────────────┘ │
│                             │
│  Latest Announcement        │
│ ┌─────────────────────────┐ │
│ │ 📢 Easter Service Plan  │ │
│ │ Join us for sunrise...  │ │
│ └─────────────────────────┘ │
│                             │
│ ┌──────┐┌──────┐┌──────┐   │
│ │Events││Groups││ Give │   │
│ └──────┘└──────┘└──────┘   │
│ ┌──────┐┌──────┐┌──────┐   │
│ │Sermon││Member││Volun.│   │
│ └──────┘└──────┘└──────┘   │
└─────────────────────────────┘
```

---

## 3. Performance Strategy

### SQLite
```sql
CREATE TABLE churches(id INTEGER PRIMARY KEY, name TEXT, denomination TEXT, json_data TEXT, synced_at TEXT);
CREATE TABLE announcements(id INTEGER PRIMARY KEY, church_id INTEGER, title TEXT, is_pinned INTEGER, json_data TEXT, synced_at TEXT);
CREATE TABLE church_events(id INTEGER PRIMARY KEY, church_id INTEGER, start_time TEXT, json_data TEXT, synced_at TEXT);
```
- Stale-while-revalidate: SQLite first, API background
- TTL: church profile — 24 hours, announcements — 15 minutes, events — 1 hour
- Offline: read YES, write via pending_queue

---

## 4. Backend Implementation

### Database
```sql
CREATE TABLE churches(id BIGSERIAL PRIMARY KEY, name VARCHAR(200), denomination VARCHAR(100), location TEXT, lat DOUBLE PRECISION, lng DOUBLE PRECISION, pastor_name VARCHAR(200), phone VARCHAR(20), photo_url VARCHAR(500), member_count INTEGER DEFAULT 0, created_at TIMESTAMP DEFAULT NOW());

CREATE TABLE church_service_times(id BIGSERIAL PRIMARY KEY, church_id BIGINT, day_of_week INTEGER, start_time TIME, label VARCHAR(100));

CREATE TABLE church_announcements(id BIGSERIAL PRIMARY KEY, church_id BIGINT, title VARCHAR(200), content TEXT, author_id BIGINT, is_pinned BOOLEAN DEFAULT FALSE, created_at TIMESTAMP DEFAULT NOW());

CREATE TABLE church_events(id BIGSERIAL PRIMARY KEY, church_id BIGINT, title VARCHAR(200), description TEXT, start_time TIMESTAMP, end_time TIMESTAMP, location TEXT, rsvp_count INTEGER DEFAULT 0, created_at TIMESTAMP DEFAULT NOW());

CREATE TABLE church_members(id BIGSERIAL PRIMARY KEY, church_id BIGINT, user_id BIGINT, role VARCHAR(50) DEFAULT 'member', joined_at TIMESTAMP DEFAULT NOW());

CREATE TABLE volunteer_slots(id BIGSERIAL PRIMARY KEY, church_id BIGINT, role VARCHAR(100), slot_date DATE, assigned_user_id BIGINT, is_filled BOOLEAN DEFAULT FALSE);
```

### API Endpoints
| Method | Endpoint | Description | Auth |
|--------|----------|-------------|------|
| GET | /api/church/{id} | Church profile | Bearer |
| GET | /api/church/{id}/announcements | Announcements | Bearer |
| GET | /api/church/{id}/events | Events list | Bearer |
| POST | /api/church/events/{id}/rsvp | RSVP to event | Bearer |
| GET | /api/church/{id}/members | Member directory | Bearer |
| GET | /api/church/{id}/groups | Church groups | Bearer |
| GET | /api/church/{id}/volunteers | Volunteer slots | Bearer |
| POST | /api/church/volunteers/{id}/signup | Sign up | Bearer |

### Controller
`app/Http/Controllers/Api/ChurchController.php` — DB facade with role-based access for announcements.

---

## 5. Integration Wiring
- **GroupService** — each church is a TAJIRI group with roles
- **MessageService** — church group chats, pastoral messaging
- **PostService** — church news feed posts
- **CalendarService** — service times and events synced
- **LivestreamService** — live stream Sunday services
- **Fungu la Kumi** — church-specific giving campaigns
- **Jumuiya** — small groups within the church
- **Tafuta Kanisa** — discovery leads to church profile

---

## 6. Implementation Phases
### Phase 1: Foundation (Week 1)
- Data models, service layer, SQLite schema
- Backend tables and church CRUD
- Church profile page

### Phase 2: Core UI (Week 2)
- Announcements with push notifications
- Events calendar with RSVP
- Member directory

### Phase 3: Integration (Week 3)
- Sermon library integration
- Groups list and volunteer board
- Giving integration with Fungu la Kumi

### Phase 4: Polish (Week 4)
- Multi-branch support
- Prayer wall integration
- Offline support, visitor welcome flow

---

## 7. External APIs & Integrations

| API | Provider | Purpose | Pricing | Integration Notes |
|-----|----------|---------|---------|-------------------|
| Planning Center API | Planning Center | People, services, check-ins, groups, calendar, giving | Free for <25 people | OAuth2; APIs for Calendar, Check-Ins, Giving, Groups, People, Services |
| Breeze ChMS API | Breeze/Tithely | Member management, contributions, events | Paid ($0-99/month) | REST API; API key auth; 20 req/min |
| ChurchSuite API | ChurchSuite | Contacts, small groups, children, giving, rotas | Paid (subscription) | Embed API and full developer API |
| Google Places API | Google | Church location, details, photos, hours | Freemium (10k free/month) | type=church; place details and photos |

### Integration Priority
1. **Immediate** — Planning Center API (free for small churches, comprehensive)
2. **Short-term** — Google Places (church location and details)
3. **Partnership** — Breeze, ChurchSuite, ChurchTools (require church subscriptions)
