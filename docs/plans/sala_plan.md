# Sala (Prayer) — Implementation Plan

## Overview
Christian prayer management module with personal journal, shared prayer requests, prayer chains, devotionals, fasting tracker, and community intercession. Designed for Tanzania's communal prayer culture.

---

## 1. Frontend Architecture

### Directory Structure
```
lib/sala/
├── sala_module.dart
├── models/
│   ├── prayer_entry.dart
│   ├── prayer_request.dart
│   ├── prayer_chain.dart
│   ├── devotional.dart
│   └── fast_record.dart
├── services/
│   └── prayer_service.dart          — AuthenticatedDio.instance
├── pages/
│   ├── prayer_home_page.dart
│   ├── prayer_journal_page.dart
│   ├── create_request_page.dart
│   ├── prayer_feed_page.dart
│   ├── prayer_chain_page.dart
│   ├── answered_prayers_page.dart
│   ├── devotional_reader_page.dart
│   ├── prayer_reminders_page.dart
│   └── fasting_tracker_page.dart
└── widgets/
    ├── prayer_streak_card.dart
    ├── request_card.dart
    ├── praying_button.dart
    ├── devotional_card.dart
    ├── fast_countdown.dart
    └── prayer_calendar.dart
```

### Data Models
- **PrayerEntry** — `id`, `userId`, `title`, `content`, `scriptureRef`, `category`, `createdAt`. `fromJson` with `_parseInt`.
- **PrayerRequest** — `id`, `userId`, `title`, `description`, `urgency` (low/medium/high), `category`, `scope` (private/jumuiya/church/public), `prayerCount`, `isAnswered`, `testimony`. `_parseBool`, `_parseInt`.
- **PrayerChain** — `id`, `requestId`, `slots` (List of time slots with participant names).
- **Devotional** — `id`, `title`, `content`, `scriptureRef`, `prayerPrompt`, `type` (morning/evening), `date`.
- **FastRecord** — `id`, `startDate`, `endDate`, `prayerFocus`, `isActive`. `_parseBool`.

### Service Layer
```dart
Dio get _dio => AuthenticatedDio.instance;
```
- `getJournalEntries({int page})` — `GET /api/prayer/journal`
- `createJournalEntry(Map data)` — `POST /api/prayer/journal`
- `getRequests({String scope})` — `GET /api/prayer/requests`
- `createRequest(Map data)` — `POST /api/prayer/requests`
- `markPraying(int requestId)` — `POST /api/prayer/requests/{id}/pray`
- `markAnswered(int requestId, String testimony)` — `PUT /api/prayer/requests/{id}/answered`
- `getDevotional(String date)` — `GET /api/prayer/devotional?date={date}`
- `startFast(Map data)` — `POST /api/prayer/fasts`
- `getChain(int requestId)` — `GET /api/prayer/chains/{requestId}`

### Pages
- **PrayerHomePage** — Today's devotional card, active requests summary, prayer streak
- **PrayerJournalPage** — Chronological entries with scripture refs, search bar
- **CreateRequestPage** — Title, description, category, urgency, scope selector
- **PrayerFeedPage** — Shared requests with "I'm praying" buttons and counters
- **AnsweredPrayersPage** — Celebration feed with testimonies
- **FastingTrackerPage** — Active fast countdown, prayer focus, hydration reminder

### Widgets
- `PrayingButton` — Animated button showing prayer count, tap to increment
- `PrayerCalendar` — Calendar view with prayer consistency streaks

---

## 2. UI Design
- #1A1A1A/#666666/#FAFAFA/#FFFFFF monochromatic
- 48dp touch, maxLines+ellipsis, _rounded icons
- Dark stat cards for prayer streaks and answered count
- Cards: radius 12-16, subtle shadow

### Main Screen Wireframe
```
┌─────────────────────────────┐
│ ← Sala                  ⚙️   │
├─────────────────────────────┤
│  🔥 Prayer Streak: 14 days  │
│                             │
│ ┌─────────────────────────┐ │
│ │ Morning Devotional      │ │
│ │ "Pray without ceasing"  │ │
│ │ 1 Thess 5:17    [Read]  │ │
│ └─────────────────────────┘ │
│                             │
│  Active Requests        (5) │
│ ┌─────────────────────────┐ │
│ │ Healing for mama  🙏 12  │ │
│ │ Job interview     🙏 8   │ │
│ └─────────────────────────┘ │
│                             │
│ [Journal] [Requests] [Fast] │
└─────────────────────────────┘
```

---

## 3. Performance Strategy

### SQLite
```sql
CREATE TABLE prayer_entries(id INTEGER PRIMARY KEY, user_id INTEGER, title TEXT, category TEXT, json_data TEXT, synced_at TEXT);
CREATE TABLE prayer_requests(id INTEGER PRIMARY KEY, user_id INTEGER, scope TEXT, is_answered INTEGER, prayer_count INTEGER, json_data TEXT, synced_at TEXT);
CREATE INDEX idx_requests_scope ON prayer_requests(scope);
```
- Stale-while-revalidate: SQLite first, API background
- TTL: journal entries — 6 hours, requests — 5 minutes (live count)
- Offline: read YES, write via pending_queue

---

## 4. Backend Implementation

### Database
```sql
CREATE TABLE prayer_entries(id BIGSERIAL PRIMARY KEY, user_id BIGINT, title VARCHAR(200), content TEXT, scripture_ref VARCHAR(100), category VARCHAR(50), created_at TIMESTAMP DEFAULT NOW());

CREATE TABLE prayer_requests(id BIGSERIAL PRIMARY KEY, user_id BIGINT, title VARCHAR(200), description TEXT, urgency VARCHAR(20), category VARCHAR(50), scope VARCHAR(20), prayer_count INTEGER DEFAULT 0, is_answered BOOLEAN DEFAULT FALSE, testimony TEXT, created_at TIMESTAMP DEFAULT NOW());

CREATE TABLE prayer_interactions(id BIGSERIAL PRIMARY KEY, user_id BIGINT, request_id BIGINT, created_at TIMESTAMP DEFAULT NOW(), UNIQUE(user_id, request_id));

CREATE TABLE fasts(id BIGSERIAL PRIMARY KEY, user_id BIGINT, start_date TIMESTAMP, end_date TIMESTAMP, prayer_focus TEXT, is_active BOOLEAN DEFAULT TRUE);

CREATE TABLE devotionals(id BIGSERIAL PRIMARY KEY, title VARCHAR(200), content TEXT, scripture_ref VARCHAR(100), prayer_prompt TEXT, type VARCHAR(20), publish_date DATE);
```

### API Endpoints
| Method | Endpoint | Description | Auth |
|--------|----------|-------------|------|
| GET | /api/prayer/journal | List journal entries | Bearer |
| POST | /api/prayer/journal | Create entry | Bearer |
| GET | /api/prayer/requests | List requests by scope | Bearer |
| POST | /api/prayer/requests | Create request | Bearer |
| POST | /api/prayer/requests/{id}/pray | Mark praying | Bearer |
| PUT | /api/prayer/requests/{id}/answered | Mark answered | Bearer |
| GET | /api/prayer/devotional | Get daily devotional | Bearer |
| POST | /api/prayer/fasts | Start a fast | Bearer |
| GET | /api/prayer/chains/{requestId} | Get prayer chain | Bearer |

### Controller
`app/Http/Controllers/Api/PrayerController.php` — DB facade, `prayer_count` incremented atomically.

---

## 5. Integration Wiring
- **Biblia** — scripture references link to Bible reader
- **Jumuiya** — prayer requests shared within small group
- **Kanisa Langu** — church-wide prayer wall
- **NotificationService** — prayer reminders, "someone is praying" alerts
- **CalendarService** — prayer times and fasting periods synced
- **PostService** — answered prayer testimonies shared to feed

---

## 6. Implementation Phases
### Phase 1: Foundation (Week 1)
- Data models, service layer, SQLite schema
- Backend tables and CRUD endpoints
- Prayer journal CRUD

### Phase 2: Core UI (Week 2)
- Prayer request creation and feed
- "I'm praying" button with live counter
- Daily devotional reader

### Phase 3: Integration (Week 3)
- Prayer chain coordination
- Fasting tracker with countdown
- Bible cross-references

### Phase 4: Polish (Week 4)
- Answered prayers celebration feed
- Prayer calendar with streaks
- Offline support, push notifications

---

## 7. External APIs & Integrations

| API | Provider | Purpose | Pricing | Integration Notes |
|-----|----------|---------|---------|-------------------|
| API.Bible (VOTD) | American Bible Society | Daily verse selection for devotional content | Free (API key) | Tutorial at docs.api.bible/tutorials/verse-of-the-day |
| Devotionalium API | Max Melzer | Daily devotional verses from Abrahamic scriptures | Free | Multi-faith daily verses; devotionalium.com/api/docs |
| bible-api.com | Open source | Simple verse lookup for prayer references | Free, no auth | GET /VERSE returns JSON; no rate limits |
| YouVersion/Faith.tools | Life.Church | Bible reader, verse of the day, reading plans | Free (developer account) | SDKs for Swift, Kotlin, JS, React Native |
| ESV API | Crossway | ESV daily verse and passage retrieval | Free for non-commercial | Build custom VOTD with passage endpoint |

### Integration Priority
1. **Immediate** — Free APIs (bible-api.com, Devotionalium for daily verses)
2. **Short-term** — Freemium APIs (API.Bible VOTD, YouVersion/Faith.tools)
3. **Partnership** — Church-specific devotional content providers
