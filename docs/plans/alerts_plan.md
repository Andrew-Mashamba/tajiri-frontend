# Alerts (Tahadhari) — Implementation Plan

## Overview
Emergency alert system for Tanzania with weather warnings (TMA), flood/earthquake notifications, government announcements, location-based alerts, family "I'm safe" check-in, evacuation guides, shelter finder, and first aid tips. Addresses gap in timely disaster communication.

---

## 1. Frontend Architecture

### Directory Structure
```
lib/alerts/
├── alerts_module.dart
├── models/
│   ├── alert.dart
│   ├── alert_severity.dart
│   ├── evacuation_route.dart
│   ├── shelter.dart
│   └── family_checkin.dart
├── services/
│   └── alerts_service.dart          — AuthenticatedDio.instance
├── pages/
│   ├── alerts_home_page.dart
│   ├── alert_detail_page.dart
│   ├── alert_map_page.dart
│   ├── emergency_contacts_page.dart
│   ├── first_aid_page.dart
│   ├── evacuation_map_page.dart
│   ├── family_checkin_page.dart
│   ├── preparedness_page.dart
│   ├── alert_history_page.dart
│   └── alert_settings_page.dart
└── widgets/
    ├── alert_card.dart
    ├── severity_badge.dart
    ├── alert_map_overlay.dart
    ├── im_safe_button.dart
    ├── shelter_card.dart
    ├── first_aid_card.dart
    ├── checkin_status.dart
    └── preparedness_checklist.dart
```

### Data Models
- **Alert** — `id`, `type` (weather/flood/earthquake/government/power/water/disease/road), `title`, `description`, `severity` (advisory/watch/warning/emergency), `affectedArea`, `lat`, `lng`, `radius`, `instructions`, `source`, `isActive`, `createdAt`, `expiresAt`. `_parseDouble`, `_parseBool`.
- **EvacuationRoute** — `id`, `name`, `startLat`, `startLng`, `endLat`, `endLng`, `waypoints` (List), `assemblyPoint`. `_parseDouble`.
- **Shelter** — `id`, `name`, `address`, `lat`, `lng`, `capacity`, `type` (shelter/hospital/safe_zone), `phone`, `isOpen`. `_parseInt`, `_parseDouble`, `_parseBool`.
- **FamilyCheckin** — `id`, `userId`, `userName`, `status` (safe/needs_help/no_response), `lat`, `lng`, `checkedAt`. `_parseDouble`.

### Service Layer
```dart
Dio get _dio => AuthenticatedDio.instance;
```
- `getActiveAlerts({double? lat, double? lng})` — `GET /api/alerts/active`
- `getAlert(int id)` — `GET /api/alerts/{id}`
- `getAlertMap()` — `GET /api/alerts/map`
- `markSafe(Map data)` — `POST /api/alerts/checkin/safe`
- `getFamilyStatus()` — `GET /api/alerts/checkin/family`
- `getShelters(double lat, double lng)` — `GET /api/alerts/shelters`
- `getEvacuationRoutes(double lat, double lng)` — `GET /api/alerts/evacuation`
- `getFirstAidGuide(String type)` — `GET /api/alerts/first-aid/{type}`
- `getAlertHistory({String? type, String? dateRange})` — `GET /api/alerts/history`
- `updateAlertSettings(Map data)` — `PUT /api/alerts/settings`
- `getPreparednessChecklists()` — `GET /api/alerts/preparedness`

### Pages
- **AlertsHomePage** — Active alerts sorted by severity, location-based, "I'm safe" status
- **AlertDetailPage** — Full alert: type, severity, affected area, instructions, map
- **AlertMapPage** — Geographic visualization of active alerts and zones
- **EmergencyContactsPage** — One-tap dial (112, 114, 199) and local contacts
- **FirstAidPage** — Categorized instructions with illustrations
- **EvacuationMapPage** — Local routes, assembly points, shelter locations
- **FamilyCheckinPage** — "I'm safe" broadcast with delivery confirmation
- **PreparednessPage** — Disaster checklists and educational content
- **AlertHistoryPage** — Past alerts by type, date, location
- **AlertSettingsPage** — Alert types, severity threshold, location radius

### Widgets
- `ImSafeButton` — Large green button for family check-in broadcast
- `SeverityBadge` — Color-coded: blue (advisory), yellow (watch), orange (warning), red (emergency)

---

## 2. UI Design
- #1A1A1A/#666666/#FAFAFA/#FFFFFF monochromatic
- 48dp touch ("I'm safe" button 72dp), maxLines+ellipsis, _rounded icons
- Dark stat cards for active alert count
- Cards: radius 12-16, subtle shadow
- Severity colors on alert cards only (blue/yellow/orange/red borders)

### Main Screen Wireframe
```
┌─────────────────────────────┐
│ ← Tahadhari             ⚙️   │
├─────────────────────────────┤
│ ┌─────────────────────────┐ │
│ │ 🔴 FLOOD WARNING        │ │
│ │ Msimbazi River basin    │ │
│ │ Heavy rain expected     │ │
│ │ Evacuate low areas      │ │
│ │              [Details]  │ │
│ └─────────────────────────┘ │
│ ┌─────────────────────────┐ │
│ │ 🟡 POWER OUTAGE         │ │
│ │ Kinondoni district      │ │
│ │ Est. restoration: 4PM   │ │
│ └─────────────────────────┘ │
│                             │
│  [   ✅ I'M SAFE   ]       │
│  Family: 3/4 safe           │
│                             │
│ ┌──────┐┌──────┐┌──────┐   │
│ │ Map  ││First ││Evacua│   │
│ │      ││ Aid  ││tion  │   │
│ └──────┘└──────┘└──────┘   │
│                             │
│ [Contacts][Prepare][History]│
└─────────────────────────────┘
```

---

## 3. Performance Strategy

### SQLite
```sql
CREATE TABLE alerts(id INTEGER PRIMARY KEY, type TEXT, severity TEXT, is_active INTEGER, lat REAL, lng REAL, json_data TEXT, synced_at TEXT);
CREATE TABLE shelters(id INTEGER PRIMARY KEY, name TEXT, lat REAL, lng REAL, is_open INTEGER, json_data TEXT, synced_at TEXT);
CREATE TABLE family_checkins(id INTEGER PRIMARY KEY, user_id INTEGER, status TEXT, checked_at TEXT, json_data TEXT, synced_at TEXT);
CREATE INDEX idx_alerts_active ON alerts(is_active, severity);
```
- Stale-while-revalidate: SQLite first, API background
- TTL: active alerts — 2 minutes (near real-time), shelters — 1 hour, first aid — infinite
- Offline: read cached alerts YES, write check-ins via pending_queue (critical)

---

## 4. Backend Implementation

### Database
```sql
CREATE TABLE alerts(id BIGSERIAL PRIMARY KEY, type VARCHAR(30), title VARCHAR(300), description TEXT, severity VARCHAR(20), affected_area TEXT, lat DOUBLE PRECISION, lng DOUBLE PRECISION, radius DOUBLE PRECISION, instructions TEXT, source VARCHAR(100), is_active BOOLEAN DEFAULT TRUE, created_at TIMESTAMP DEFAULT NOW(), expires_at TIMESTAMP);

CREATE TABLE shelters(id BIGSERIAL PRIMARY KEY, name VARCHAR(200), address TEXT, lat DOUBLE PRECISION, lng DOUBLE PRECISION, capacity INTEGER, type VARCHAR(30), phone VARCHAR(20), is_open BOOLEAN DEFAULT TRUE);

CREATE TABLE evacuation_routes(id BIGSERIAL PRIMARY KEY, name VARCHAR(200), start_lat DOUBLE PRECISION, start_lng DOUBLE PRECISION, end_lat DOUBLE PRECISION, end_lng DOUBLE PRECISION, waypoints JSONB, assembly_point VARCHAR(200), area VARCHAR(100));

CREATE TABLE family_checkins(id BIGSERIAL PRIMARY KEY, user_id BIGINT, alert_id BIGINT, status VARCHAR(20) DEFAULT 'safe', lat DOUBLE PRECISION, lng DOUBLE PRECISION, checked_at TIMESTAMP DEFAULT NOW());

CREATE TABLE alert_settings(id BIGSERIAL PRIMARY KEY, user_id BIGINT UNIQUE, alert_types JSONB, min_severity VARCHAR(20) DEFAULT 'watch', location_radius DOUBLE PRECISION DEFAULT 10.0);

CREATE TABLE first_aid_guides(id BIGSERIAL PRIMARY KEY, type VARCHAR(50), title VARCHAR(200), content TEXT, illustrations JSONB, sort_order INTEGER);

CREATE TABLE preparedness_checklists(id BIGSERIAL PRIMARY KEY, disaster_type VARCHAR(50), title VARCHAR(200), items JSONB);
```

### API Endpoints
| Method | Endpoint | Description | Auth |
|--------|----------|-------------|------|
| GET | /api/alerts/active | Active alerts | Bearer |
| GET | /api/alerts/{id} | Alert detail | Bearer |
| GET | /api/alerts/map | Alert map data | Bearer |
| POST | /api/alerts/checkin/safe | Mark safe | Bearer |
| GET | /api/alerts/checkin/family | Family status | Bearer |
| GET | /api/alerts/shelters | Nearby shelters | Bearer |
| GET | /api/alerts/evacuation | Evacuation routes | Bearer |
| GET | /api/alerts/first-aid/{type} | First aid guide | Bearer |
| GET | /api/alerts/history | Past alerts | Bearer |
| PUT | /api/alerts/settings | Alert preferences | Bearer |
| GET | /api/alerts/preparedness | Checklists | Bearer |

### Controller
`app/Http/Controllers/Api/AlertsController.php` — DB facade with FCM priority channel for emergency alerts and location-based filtering.

---

## 5. Integration Wiring
- **NotificationService + FCM** — priority push overriding Do Not Disturb for emergencies
- **LocationService** — area-based filtering, evacuation routes, shelters on map
- **MessageService** — "I'm safe" notifications, emergency broadcasts
- **GroupService** — emergency coordination within community groups
- **CalendarService** — preparedness drills on calendar
- **LiveUpdateService** — real-time alert delivery
- **police** — police safety alerts integrated
- **neighbourhood_watch** — community alerts feed into system
- **traffic** — road hazard and flood alerts shared
- **my_family** — family check-in targets closest connections
- **government** — official announcements channeled through alerts

---

## 6. Implementation Phases
### Phase 1: Foundation (Week 1)
- Data models, service layer, SQLite schema
- Backend tables, TMA weather alert integration
- FCM priority channel setup

### Phase 2: Core UI (Week 2)
- Alerts home with severity-sorted list
- Alert detail with instructions
- Alert map with geographic zones

### Phase 3: Integration (Week 3)
- Family "I'm safe" check-in system
- Emergency contacts with one-tap dial
- Shelter finder and evacuation routes

### Phase 4: Polish (Week 4)
- First aid guides with illustrations
- Preparedness checklists
- Alert history, settings, offline support

---

## 7. External APIs & Integrations

| API | Provider | Purpose | Pricing | Integration Notes |
|-----|----------|---------|---------|-------------------|
| Open-Meteo API | Open-Meteo | Weather forecasts, historical data, alerts | Free, no auth, open source | 1-11km resolution; SDKs for Dart; open-meteo.com |
| USGS Earthquake API | U.S. Geological Survey | Real-time earthquake data, alerts, feeds | Free, no auth | GeoJSON feeds; earthquake.usgs.gov; global coverage |
| GDACS API | UN/EC Joint Research Centre | Global disaster alerts (earthquakes, floods, cyclones) | Free | REST API; gdacs.org; worldwide disaster events |
| OpenWeatherMap API | OpenWeather | Current weather, forecasts, severe weather alerts | Freemium (1k calls/day free) | One Call API 3.0 includes alerts; openweathermap.org |
| WeatherAPI.com | WeatherAPI | Weather, astronomy, alerts, historical data | Free (1M calls/month) | Generous free tier; 14-day forecast |
| ReliefWeb API | UN OCHA | Humanitarian reports, disaster updates | Free, no auth | api.reliefweb.int; disaster reports and situation updates |
| NOAA Weather API | NOAA (US Gov) | US weather alerts, forecasts, observations | Free, no auth | api.weather.gov; US coverage only |

### Integration Priority
1. **Immediate** — Free APIs (Open-Meteo, USGS Earthquake, GDACS -- all free, no auth, global coverage)
2. **Short-term** — Freemium APIs (OpenWeatherMap, WeatherAPI.com for extended forecasts)
3. **Partnership** — AccuWeather (paid), local meteorological services for East Africa
