# Wakati wa Sala (Prayer Times) — Implementation Plan

## Overview
Accurate Islamic prayer time calculator for Tanzania with adhan alerts, prayer tracking/streaks, Fajr alarm, Qibla mini-compass, and monthly timetables. Uses GPS for location-based calculation with Shafi'i Asr default.

---

## 1. Frontend Architecture

### Directory Structure
```
lib/wakati_wa_sala/
├── wakati_wa_sala_module.dart
├── models/
│   ├── prayer_time.dart
│   ├── prayer_log.dart
│   ├── prayer_settings.dart
│   └── monthly_timetable.dart
├── services/
│   └── prayer_time_service.dart     — AuthenticatedDio.instance
├── pages/
│   ├── prayer_times_home_page.dart
│   ├── prayer_tracker_page.dart
│   ├── daily_prayer_view_page.dart
│   ├── settings_page.dart
│   ├── monthly_timetable_page.dart
│   ├── fajr_alarm_page.dart
│   ├── statistics_page.dart
│   └── qibla_quick_page.dart
└── widgets/
    ├── prayer_time_card.dart
    ├── countdown_timer.dart
    ├── prayer_status_icon.dart
    ├── streak_counter.dart
    ├── adhan_selector.dart
    └── qibla_mini_compass.dart
```

### Data Models
- **PrayerTime** — `fajr`, `dhuhr`, `asr`, `maghrib`, `isha` (all DateTime), `sunrise`, `date`, `calculationMethod`, `lat`, `lng`. `_parseDouble`.
- **PrayerLog** — `id`, `userId`, `prayer` (fajr/dhuhr/asr/maghrib/isha), `date`, `status` (onTime/late/qada/missed), `loggedAt`.
- **PrayerSettings** — `calculationMethod`, `asrJurisprudence`, `adhanSounds` (Map), `manualAdjustments` (Map), `silentModeDuringPrayer`. `_parseBool`.
- **MonthlyTimetable** — `month`, `year`, `days` (List of PrayerTime objects).

### Service Layer
```dart
Dio get _dio => AuthenticatedDio.instance;
```
- `getPrayerTimes(double lat, double lng, {String? method})` — `GET /api/prayer-times?lat={lat}&lng={lng}`
- `getMonthlyTimetable(double lat, double lng, int month, int year)` — `GET /api/prayer-times/monthly`
- `logPrayer(Map data)` — `POST /api/prayer-times/log`
- `getPrayerStats({String? period})` — `GET /api/prayer-times/stats`
- `getStreak()` — `GET /api/prayer-times/streak`
- `updateSettings(Map data)` — `PUT /api/prayer-times/settings`

### Pages
- **PrayerTimesHomePage** — Current/next prayer highlighted, all five times, countdown
- **PrayerTrackerPage** — Calendar grid showing completion by day, streak counter
- **DailyPrayerViewPage** — Expandable cards for each prayer with log button
- **SettingsPage** — Calculation method, adhan selection, notification preferences
- **MonthlyTimetablePage** — Table view of all prayer times for the month
- **FajrAlarmPage** — Alarm time, sound selection, snooze settings
- **StatisticsPage** — Weekly/monthly completion rates, charts, streak history

### Widgets
- `CountdownTimer` — Live countdown to next prayer time
- `QiblaMiniCompass` — Small compass widget in corner of prayer times screen

---

## 2. UI Design
- #1A1A1A/#666666/#FAFAFA/#FFFFFF monochromatic
- 48dp touch, maxLines+ellipsis, _rounded icons
- Dark stat cards for prayer streak and completion rate
- Cards: radius 12-16, subtle shadow

### Main Screen Wireframe
```
┌─────────────────────────────┐
│ ← Wakati wa Sala        ⚙️   │
├─────────────────────────────┤
│  Next Prayer: Asr           │
│  ⏱  1h 23m remaining       │
│                             │
│ ┌─────────────────────────┐ │
│ │ Fajr     05:12  ✅       │ │
│ │ Dhuhr    12:15  ✅       │ │
│ │ Asr      15:38  ⏳ next  │ │
│ │ Maghrib  18:22  ○       │ │
│ │ Isha     19:35  ○       │ │
│ └─────────────────────────┘ │
│                             │
│  🔥 Streak: 21 days         │
│  This week: ██████░ 85%     │
│                             │
│  [🧭 Qibla]                │
│                             │
│ [Tracker] [Monthly] [Stats] │
└─────────────────────────────┘
```

---

## 3. Performance Strategy

### SQLite
```sql
CREATE TABLE prayer_times_cache(id INTEGER PRIMARY KEY, date TEXT, lat REAL, lng REAL, fajr TEXT, dhuhr TEXT, asr TEXT, maghrib TEXT, isha TEXT, synced_at TEXT);
CREATE TABLE prayer_logs(id INTEGER PRIMARY KEY, prayer TEXT, date TEXT, status TEXT, json_data TEXT, synced_at TEXT);
CREATE INDEX idx_prayer_logs_date ON prayer_logs(date);
```
- Stale-while-revalidate: SQLite first, API background
- TTL: prayer times — 24 hours (recalculate daily), logs — 5 minutes
- Offline: read YES (calculated locally), write logs via pending_queue

---

## 4. Backend Implementation

### Database
```sql
CREATE TABLE prayer_time_logs(id BIGSERIAL PRIMARY KEY, user_id BIGINT, prayer VARCHAR(10), prayer_date DATE, status VARCHAR(10), logged_at TIMESTAMP DEFAULT NOW());

CREATE TABLE prayer_settings(id BIGSERIAL PRIMARY KEY, user_id BIGINT UNIQUE, calculation_method VARCHAR(30) DEFAULT 'egyptian', asr_jurisprudence VARCHAR(20) DEFAULT 'shafii', adhan_sounds JSONB, manual_adjustments JSONB, silent_mode BOOLEAN DEFAULT FALSE);

CREATE TABLE prayer_streaks(id BIGSERIAL PRIMARY KEY, user_id BIGINT, current_streak INTEGER DEFAULT 0, longest_streak INTEGER DEFAULT 0, last_complete_date DATE);
```

### API Endpoints
| Method | Endpoint | Description | Auth |
|--------|----------|-------------|------|
| GET | /api/prayer-times | Calculate prayer times | Bearer |
| GET | /api/prayer-times/monthly | Monthly timetable | Bearer |
| POST | /api/prayer-times/log | Log prayer completion | Bearer |
| GET | /api/prayer-times/stats | Prayer statistics | Bearer |
| GET | /api/prayer-times/streak | Current streak | Bearer |
| PUT | /api/prayer-times/settings | Update settings | Bearer |

### Controller
`app/Http/Controllers/Api/PrayerTimeController.php` — DB facade with astronomical prayer time calculation (sun position algorithms).

---

## 5. Integration Wiring
- **NotificationService** — adhan alerts for each prayer, Fajr alarm, Jumu'ah reminder
- **CalendarService** — prayer times visible on TAJIRI calendar
- **LocationService** — GPS-based calculation, auto-update when traveling
- **Qibla** — mini compass opens full Qibla compass
- **Quran** — suggested surahs for each prayer
- **Dua** — post-prayer duas after marking complete
- **Ramadan** — Fajr for suhoor, Maghrib for iftar countdown
- **Tafuta Msikiti** — find nearest mosque for congregational prayer

---

## 6. Implementation Phases
### Phase 1: Foundation (Week 1)
- Data models, prayer time calculation algorithm
- Service layer, SQLite schema
- Backend tables and API

### Phase 2: Core UI (Week 2)
- Prayer times home with countdown
- Prayer tracker with calendar grid
- Adhan notification system

### Phase 3: Integration (Week 3)
- Fajr alarm with snooze
- Monthly timetable (printable)
- Statistics and streak tracking

### Phase 4: Polish (Week 4)
- Qibla mini-compass integration
- Silent mode automation
- Offline calculation, location auto-update

---

## 7. External APIs & Integrations

| API | Provider | Purpose | Pricing | Integration Notes |
|-----|----------|---------|---------|-------------------|
| Aladhan API | Islamic Network | Prayer times by coordinates, address, or city | Free, no auth | Multiple calculation methods (MWL, ISNA, Egypt); aladhan.com/prayer-times-api |
| Aladhan Dart Package | pub.dev | Flutter/Dart prayer times integration | Free | `aladhan_prayer_times` on pub.dev; direct Dart integration |
| IslamicFinder API | IslamicFinder | Prayer times, Athan alerts | Free (limited) | islamicfinder.org; used by many Muslim apps |
| PrayTimes.org | Hamid Zarrabi-Zadeh | Open-source prayer time calculation library | Free, open source | JavaScript/Python library; client-side calculation |
| Open-Meteo API | Open-Meteo | Sunrise/sunset data for prayer time verification | Free, no auth | Supplement with astronomical data; open-meteo.com |

### Flutter Packages
- `aladhan_prayer_times` — Direct Dart wrapper for Aladhan API

### Integration Priority
1. **Immediate** — Free APIs (Aladhan API -- no auth, production-ready, well-documented)
2. **Short-term** — Flutter packages (aladhan_prayer_times on pub.dev for native integration)
3. **Partnership** — IslamicFinder (extended features)
