# Ramadan — Implementation Plan

## Overview
Comprehensive Ramadan companion with suhoor/iftar times, fasting tracker, Quran khatm plan, Taraweeh tracker, goals dashboard, iftar recipes, Zakat al-Fitr calculator, community iftar finder, and Laylat al-Qadr guide for Tanzanian Muslims.

---

## 1. Frontend Architecture

### Directory Structure
```
lib/ramadan/
├── ramadan_module.dart
├── models/
│   ├── ramadan_day.dart
│   ├── fasting_record.dart
│   ├── khatm_progress.dart
│   ├── ramadan_goal.dart
│   ├── iftar_recipe.dart
│   └── community_iftar.dart
├── services/
│   └── ramadan_service.dart         — AuthenticatedDio.instance
├── pages/
│   ├── ramadan_home_page.dart
│   ├── daily_view_page.dart
│   ├── fasting_calendar_page.dart
│   ├── khatm_tracker_page.dart
│   ├── iftar_recipes_page.dart
│   ├── zakat_calculator_page.dart
│   ├── goals_dashboard_page.dart
│   ├── community_iftar_page.dart
│   └── laylat_al_qadr_page.dart
└── widgets/
    ├── iftar_countdown.dart
    ├── fasting_day_card.dart
    ├── khatm_juz_grid.dart
    ├── goal_progress_card.dart
    ├── recipe_card.dart
    ├── suhoor_alarm_card.dart
    └── ramadan_dua_card.dart
```

### Data Models
- **RamadanDay** — `dayNumber`, `hijriDate`, `suhoorTime`, `iftarTime`, `isFasted`, `taraweehCompleted`, `juzAssigned`. `_parseInt`, `_parseBool`.
- **FastingRecord** — `id`, `userId`, `date`, `isFasted`, `isMakeup`. `_parseBool`.
- **KhatmProgress** — `id`, `userId`, `currentJuz`, `completedJuz` (List<int>), `targetDate`. `_parseInt`.
- **RamadanGoal** — `id`, `title`, `type` (prayer/charity/quran/dhikr), `targetValue`, `currentValue`. `_parseDouble`.
- **IftarRecipe** — `id`, `title`, `description`, `ingredients` (List), `prepTime`, `photoUrl`, `category`. `_parseInt`.
- **CommunityIftar** — `id`, `venueName`, `location`, `lat`, `lng`, `date`, `organizerName`, `capacity`. `_parseDouble`, `_parseInt`.

### Service Layer
```dart
Dio get _dio => AuthenticatedDio.instance;
```
- `getRamadanDashboard()` — `GET /api/ramadan/dashboard`
- `getDayDetail(int dayNumber)` — `GET /api/ramadan/days/{dayNumber}`
- `logFasting(int dayNumber, bool fasted)` — `POST /api/ramadan/fasting`
- `getKhatmProgress()` — `GET /api/ramadan/khatm`
- `updateKhatm(int juz)` — `PUT /api/ramadan/khatm/{juz}`
- `getGoals()` — `GET /api/ramadan/goals`
- `updateGoal(int id, double value)` — `PUT /api/ramadan/goals/{id}`
- `getRecipes({String? category})` — `GET /api/ramadan/recipes`
- `getCommunityIftars({double? lat, double? lng})` — `GET /api/ramadan/community-iftars`
- `calculateZakatFitr(int familySize, String foodType)` — `GET /api/ramadan/zakat-fitr`

### Pages
- **RamadanHomePage** — Day counter, suhoor/iftar times, today's dua, Quran progress, goals
- **DailyViewPage** — Expanded day with all trackers and activities
- **FastingCalendarPage** — Month view marking fasted/missed with makeup tracker
- **KhatmTrackerPage** — Juz checklist with daily reading progress
- **IftarRecipesPage** — Recipe cards with ingredients, prep time, photos
- **ZakatCalculatorPage** — Family member count, food price, amount per person
- **GoalsDashboardPage** — Personal Ramadan goals with progress
- **CommunityIftarPage** — Map of communal iftar locations
- **LaylatAlQadrPage** — Last 10 nights devotion schedule and tracker

### Widgets
- `IftarCountdown` — Live countdown timer to Maghrib with animated display
- `KhatmJuzGrid` — 30-cell grid showing completed/pending juz

---

## 2. UI Design
- #1A1A1A/#666666/#FAFAFA/#FFFFFF monochromatic
- 48dp touch, maxLines+ellipsis, _rounded icons
- Dark stat cards for fasting day count and khatm progress
- Cards: radius 12-16, subtle shadow

### Main Screen Wireframe
```
┌─────────────────────────────┐
│ ← Ramadan               ⚙️   │
├─────────────────────────────┤
│  Day 15 of 30    ████████░  │
│                             │
│ ┌───────────┐ ┌───────────┐ │
│ │ Suhoor    │ │ Iftar     │ │
│ │ 04:28 AM  │ │ 18:22 PM  │ │
│ │ [⏰ Alarm]│ │ ⏱ 3h 14m  │ │
│ └───────────┘ └───────────┘ │
│                             │
│  Today's Dua                │
│ ┌─────────────────────────┐ │
│ │ "Allahumma inni laka..."│ │
│ └─────────────────────────┘ │
│                             │
│  Quran Khatm    Juz 15/30   │
│  ████████████████░░░░░ 50%  │
│                             │
│  Goals                      │
│  Extra prayers  ████░ 80%   │
│  Daily sadaqah  ██░░░ 40%   │
│                             │
│ [Calendar][Recipes][Zakat]  │
└─────────────────────────────┘
```

---

## 3. Performance Strategy

### SQLite
```sql
CREATE TABLE ramadan_days(day_number INTEGER PRIMARY KEY, suhoor_time TEXT, iftar_time TEXT, is_fasted INTEGER, taraweeh INTEGER, juz_assigned INTEGER, synced_at TEXT);
CREATE TABLE ramadan_goals(id INTEGER PRIMARY KEY, title TEXT, target_value REAL, current_value REAL, json_data TEXT, synced_at TEXT);
CREATE TABLE khatm_progress(juz INTEGER PRIMARY KEY, is_completed INTEGER, completed_at TEXT);
```
- Stale-while-revalidate: SQLite first, API background
- TTL: daily times — 24 hours, goals — 30 minutes
- Offline: read YES, write fasting/goals via pending_queue

---

## 4. Backend Implementation

### Database
```sql
CREATE TABLE ramadan_fasting(id BIGSERIAL PRIMARY KEY, user_id BIGINT, ramadan_year INTEGER, day_number INTEGER, fasting_date DATE, is_fasted BOOLEAN DEFAULT TRUE, is_makeup BOOLEAN DEFAULT FALSE, created_at TIMESTAMP DEFAULT NOW(), UNIQUE(user_id, ramadan_year, day_number));

CREATE TABLE ramadan_khatm(id BIGSERIAL PRIMARY KEY, user_id BIGINT, ramadan_year INTEGER, juz_number INTEGER, is_completed BOOLEAN DEFAULT FALSE, completed_at TIMESTAMP, UNIQUE(user_id, ramadan_year, juz_number));

CREATE TABLE ramadan_goals(id BIGSERIAL PRIMARY KEY, user_id BIGINT, ramadan_year INTEGER, title VARCHAR(200), type VARCHAR(30), target_value DOUBLE PRECISION, current_value DOUBLE PRECISION DEFAULT 0);

CREATE TABLE iftar_recipes(id BIGSERIAL PRIMARY KEY, title VARCHAR(200), description TEXT, ingredients JSONB, prep_time INTEGER, photo_url VARCHAR(500), category VARCHAR(50));

CREATE TABLE community_iftars(id BIGSERIAL PRIMARY KEY, venue_name VARCHAR(200), location TEXT, lat DOUBLE PRECISION, lng DOUBLE PRECISION, iftar_date DATE, organizer_id BIGINT, capacity INTEGER, created_at TIMESTAMP DEFAULT NOW());
```

### API Endpoints
| Method | Endpoint | Description | Auth |
|--------|----------|-------------|------|
| GET | /api/ramadan/dashboard | Ramadan overview | Bearer |
| GET | /api/ramadan/days/{number} | Day detail | Bearer |
| POST | /api/ramadan/fasting | Log fasting day | Bearer |
| GET | /api/ramadan/khatm | Khatm progress | Bearer |
| PUT | /api/ramadan/khatm/{juz} | Mark juz complete | Bearer |
| GET | /api/ramadan/goals | Ramadan goals | Bearer |
| PUT | /api/ramadan/goals/{id} | Update goal | Bearer |
| GET | /api/ramadan/recipes | Iftar recipes | Bearer |
| GET | /api/ramadan/community-iftars | Community iftars | Bearer |
| GET | /api/ramadan/zakat-fitr | Calculate Zakat Fitr | Bearer |

### Controller
`app/Http/Controllers/Api/RamadanController.php` — DB facade with prayer time integration for suhoor/iftar calculation.

---

## 5. Integration Wiring
- **WalletService** — Zakat al-Fitr payment and daily sadaqah via M-Pesa
- **ContributionService** — Ramadan charity campaigns
- **NotificationService** — suhoor alarm, iftar alert, dua push, khatm reminder
- **CalendarService** — fasting days, Taraweeh, community iftars on calendar
- **Wakati wa Sala** — Fajr for suhoor, Maghrib for iftar
- **Quran** — daily juz reading in Quran reader
- **Dua** — Ramadan-specific duas (iftar, suhoor, Laylat al-Qadr)
- **Zaka** — Zakat al-Fitr calculation and payment
- **Kalenda Hijri** — Ramadan dates from Islamic calendar
- **food** — iftar recipes crosslinked

---

## 6. Implementation Phases
### Phase 1: Foundation (Week 1)
- Data models, service layer, SQLite schema
- Suhoor/iftar time calculation (from prayer times)
- Backend tables and CRUD

### Phase 2: Core UI (Week 2)
- Ramadan home with day counter and countdown
- Fasting calendar with daily tracking
- Suhoor alarm and iftar notification

### Phase 3: Integration (Week 3)
- Quran khatm tracker (30-day plan)
- Ramadan goals dashboard
- Iftar recipes

### Phase 4: Polish (Week 4)
- Zakat al-Fitr calculator
- Community iftar finder
- Laylat al-Qadr guide, Eid preparation

---

## 7. External APIs & Integrations

| API | Provider | Purpose | Pricing | Integration Notes |
|-----|----------|---------|---------|-------------------|
| Aladhan API (Ramadan) | Islamic Network | Suhoor/Iftar times (Fajr and Maghrib prayer times) | Free, no auth | Fajr=Suhoor end, Maghrib=Iftar time; aladhan.com/prayer-times-api |
| Aladhan Hijri Calendar | Islamic Network | Ramadan calendar for any year | Free, no auth | GET /v1/hijriCalendar?month=9&year=YYYY for Ramadan |
| Open-Meteo API | Open-Meteo | Precise sunset times for Iftar verification | Free, no auth | High-accuracy astronomical data; open-meteo.com |
| IslamicFinder Ramadan | IslamicFinder | Ramadan timetables, iftar/suhoor schedules | Free (limited) | islamicfinder.org/ramadan-calendar |

**Note:** Ramadan times are derived from prayer times APIs (Fajr for Suhoor, Maghrib for Iftar). No separate "Ramadan API" exists -- use Aladhan with Hijri month 9.

### Flutter Packages
- `aladhan_prayer_times` — Prayer times including Fajr/Maghrib for Ramadan
- `hijri_calendar` — Determine Ramadan dates programmatically

### Integration Priority
1. **Immediate** — Free APIs (Aladhan API -- no auth, covers both prayer times and Hijri calendar)
2. **Short-term** — Open-Meteo (sunset verification for Iftar accuracy)
3. **Partnership** — IslamicFinder (extended Ramadan features)
