# Kalenda Hijri (Islamic Calendar) — Implementation Plan

## Overview
Islamic (Hijri) calendar with dual Hijri-Gregorian display, Islamic event dates, moon sighting reports, BAKWATA official announcements, event reminders, and date converter. Essential for Tanzania's Muslim community.

---

## 1. Frontend Architecture

### Directory Structure
```
lib/kalenda_hijri/
├── kalenda_hijri_module.dart
├── models/
│   ├── hijri_date.dart
│   ├── islamic_event.dart
│   ├── moon_sighting.dart
│   └── bakwata_announcement.dart
├── services/
│   └── hijri_calendar_service.dart  — AuthenticatedDio.instance
├── pages/
│   ├── calendar_home_page.dart
│   ├── monthly_calendar_page.dart
│   ├── events_list_page.dart
│   ├── event_detail_page.dart
│   ├── date_converter_page.dart
│   ├── moon_sighting_page.dart
│   └── settings_page.dart
└── widgets/
    ├── hijri_date_card.dart
    ├── moon_phase_widget.dart
    ├── event_countdown.dart
    ├── dual_date_display.dart
    ├── calendar_grid.dart
    └── announcement_card.dart
```

### Data Models
- **HijriDate** — `day`, `month`, `year`, `monthName`, `monthNameSwahili`, `gregorianDate`. `_parseInt`.
- **IslamicEvent** — `id`, `name`, `nameSwahili`, `hijriMonth`, `hijriDay`, `description`, `practices`, `duas`, `gregorianDate`. `_parseInt`.
- **MoonSighting** — `id`, `hijriMonth`, `hijriYear`, `reportedBy`, `location`, `isOfficial`, `confirmedAt`. `_parseBool`.
- **BakwataAnnouncement** — `id`, `title`, `content`, `type`, `publishedAt`.

### Service Layer
```dart
Dio get _dio => AuthenticatedDio.instance;
```
- `getTodayHijri()` — `GET /api/hijri/today`
- `convertDate(String date, String direction)` — `GET /api/hijri/convert?date={date}&direction={direction}`
- `getMonthCalendar(int hijriMonth, int hijriYear)` — `GET /api/hijri/month/{year}/{month}`
- `getUpcomingEvents()` — `GET /api/hijri/events/upcoming`
- `getEventDetail(int id)` — `GET /api/hijri/events/{id}`
- `getMoonSightings(int month, int year)` — `GET /api/hijri/moon-sighting/{year}/{month}`
- `submitSighting(Map data)` — `POST /api/hijri/moon-sighting`
- `getAnnouncements()` — `GET /api/hijri/announcements`

### Pages
- **CalendarHomePage** — Today's Hijri/Gregorian date, moon phase, next event countdown
- **MonthlyCalendarPage** — Dual calendar with Hijri primary, Gregorian secondary
- **EventsListPage** — Chronological upcoming Islamic events with descriptions
- **EventDetailPage** — Full description, significance, recommended practices, duas
- **DateConverterPage** — Interactive converter with date pickers
- **MoonSightingPage** — Latest reports, official announcements, submit sighting

### Widgets
- `MoonPhaseWidget` — Current moon phase visualization with percentage
- `EventCountdown` — Days remaining to next major Islamic event
- `DualDateDisplay` — Side-by-side Hijri and Gregorian date

---

## 2. UI Design
- #1A1A1A/#666666/#FAFAFA/#FFFFFF monochromatic
- 48dp touch, maxLines+ellipsis, _rounded icons
- Dark stat cards for today's Hijri date and next event
- Cards: radius 12-16, subtle shadow

### Main Screen Wireframe
```
┌─────────────────────────────┐
│ ← Kalenda Hijri         ⚙️   │
├─────────────────────────────┤
│ ┌─────────────────────────┐ │
│ │  12 Rabi ul-Awwal 1447  │ │
│ │  7 April 2026           │ │
│ │      🌙 Waxing 45%      │ │
│ └─────────────────────────┘ │
│                             │
│  Next Event                 │
│ ┌─────────────────────────┐ │
│ │ Eid al-Fitr             │ │
│ │ 1 Shawwal • in 45 days  │ │
│ │              [Details]  │ │
│ └─────────────────────────┘ │
│                             │
│  BAKWATA                    │
│ ┌─────────────────────────┐ │
│ │ Tangazo: Mwezi wa...    │ │
│ └─────────────────────────┘ │
│                             │
│ [Calendar][Convert][Events] │
└─────────────────────────────┘
```

---

## 3. Performance Strategy

### SQLite
```sql
CREATE TABLE hijri_events(id INTEGER PRIMARY KEY, name TEXT, hijri_month INTEGER, hijri_day INTEGER, json_data TEXT, synced_at TEXT);
CREATE TABLE moon_sightings(id INTEGER PRIMARY KEY, hijri_month INTEGER, hijri_year INTEGER, is_official INTEGER, json_data TEXT, synced_at TEXT);
CREATE TABLE bakwata_announcements(id INTEGER PRIMARY KEY, title TEXT, json_data TEXT, synced_at TEXT);
```
- Stale-while-revalidate: SQLite first, API background
- TTL: events — 24 hours, moon sightings — 1 hour, announcements — 30 minutes
- Offline: read YES, write sighting submissions via pending_queue

---

## 4. Backend Implementation

### Database
```sql
CREATE TABLE islamic_events(id BIGSERIAL PRIMARY KEY, name VARCHAR(200), name_swahili VARCHAR(200), hijri_month INTEGER, hijri_day INTEGER, description TEXT, practices TEXT, duas TEXT, created_at TIMESTAMP DEFAULT NOW());

CREATE TABLE moon_sightings(id BIGSERIAL PRIMARY KEY, hijri_month INTEGER, hijri_year INTEGER, reported_by BIGINT, location VARCHAR(200), is_official BOOLEAN DEFAULT FALSE, confirmed_at TIMESTAMP, created_at TIMESTAMP DEFAULT NOW());

CREATE TABLE bakwata_announcements(id BIGSERIAL PRIMARY KEY, title VARCHAR(300), content TEXT, type VARCHAR(30), published_at TIMESTAMP DEFAULT NOW());

CREATE TABLE hijri_adjustments(id BIGSERIAL PRIMARY KEY, hijri_month INTEGER, hijri_year INTEGER, adjustment_days INTEGER DEFAULT 0, reason TEXT, country VARCHAR(10) DEFAULT 'TZ');
```

### API Endpoints
| Method | Endpoint | Description | Auth |
|--------|----------|-------------|------|
| GET | /api/hijri/today | Today's Hijri date | Bearer |
| GET | /api/hijri/convert | Date conversion | Bearer |
| GET | /api/hijri/month/{year}/{month} | Monthly calendar | Bearer |
| GET | /api/hijri/events/upcoming | Upcoming events | Bearer |
| GET | /api/hijri/events/{id} | Event detail | Bearer |
| GET | /api/hijri/moon-sighting/{year}/{month} | Moon sightings | Bearer |
| POST | /api/hijri/moon-sighting | Submit sighting | Bearer |
| GET | /api/hijri/announcements | BAKWATA news | Bearer |

### Controller
`app/Http/Controllers/Api/HijriCalendarController.php` — DB facade with Hijri-Gregorian conversion algorithm and moon phase calculation.

---

## 5. Integration Wiring
- **CalendarService** — Hijri events synced with TAJIRI calendar
- **NotificationService** — event reminders, moon sighting alerts, BAKWATA push
- **PostService** — Islamic occasion greetings to social feed
- **Ramadan** — Ramadan start/end from Hijri calendar
- **Wakati wa Sala** — special prayers on Islamic occasions
- **Quran** — recommended surahs for each occasion
- **Dua** — occasion-specific duas linked from events
- **Maulid** — 12 Rabi ul-Awwal date for Maulid countdown

---

## 6. Implementation Phases
### Phase 1: Foundation (Week 1)
- Hijri-Gregorian conversion algorithm
- Data models, service layer, SQLite schema
- Backend tables, Islamic events seed data

### Phase 2: Core UI (Week 2)
- Calendar home with dual date display
- Monthly calendar grid
- Events list with detail pages

### Phase 3: Integration (Week 3)
- Date converter tool
- Moon sighting reports and BAKWATA
- Event reminders and countdowns

### Phase 4: Polish (Week 4)
- Moon phase visualization
- Home screen widget
- Offline support, Tanzania-specific adjustments

---

## 7. External APIs & Integrations

| API | Provider | Purpose | Pricing | Integration Notes |
|-----|----------|---------|---------|-------------------|
| Aladhan Hijri Calendar API | Islamic Network | Hijri-Gregorian conversion, Islamic calendar | Free, no auth | Monthly calendar, date conversion; aladhan.com/islamic-calendar-api |
| hijri_calendar (Dart) | pub.dev | Dart library for Hijri dates | Free | fromGregorian(), toGregorian(); direct Flutter integration |
| hijri_date (Dart) | pub.dev | Hijri dates with moon phases, Islamic events | Free | Multi-language (ar, en, tr); moon phase calculations |
| Hijri Calendar Web API | hijri.habibur.com | REST API for today's Hijri date and conversions | Free | Simple GET requests; JSON responses |

### Flutter Packages
- `hijri_calendar` — Hijri date conversion (fromGregorian/toGregorian)
- `hijri_date` — Hijri dates with moon phases and Islamic event tracking

### Integration Priority
1. **Immediate** — Free APIs (Aladhan Hijri Calendar -- no auth, comprehensive date conversion)
2. **Short-term** — Flutter packages (hijri_calendar, hijri_date for native Dart integration)
3. **Partnership** — None needed; Hijri calendar is fully served by free APIs + Dart packages
