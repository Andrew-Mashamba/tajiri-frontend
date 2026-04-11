# Traffic (Trafiki) — Implementation Plan

## Overview
Community-driven traffic information platform for Tanzania with live congestion maps, accident/road closure reports, alternative routes, commute planner, BRT/DART status, fuel station locator, and flood alerts. Focused on Dar es Salaam's severe congestion.

---

## 1. Frontend Architecture

### Directory Structure
```
lib/traffic/
├── traffic_module.dart
├── models/
│   ├── traffic_segment.dart
│   ├── traffic_report.dart
│   ├── commute_route.dart
│   ├── fuel_station.dart
│   └── brt_status.dart
├── services/
│   └── traffic_service.dart         — AuthenticatedDio.instance
├── pages/
│   ├── traffic_map_page.dart
│   ├── my_commute_page.dart
│   ├── reports_feed_page.dart
│   ├── submit_report_page.dart
│   ├── route_planner_page.dart
│   ├── fuel_stations_page.dart
│   ├── alerts_settings_page.dart
│   ├── traffic_history_page.dart
│   ├── brt_status_page.dart
│   └── parking_finder_page.dart
└── widgets/
    ├── traffic_map_overlay.dart
    ├── congestion_legend.dart
    ├── report_card.dart
    ├── route_option_card.dart
    ├── fuel_price_card.dart
    ├── brt_route_card.dart
    └── commute_eta.dart
```

### Data Models
- **TrafficSegment** — `roadName`, `startLat`, `startLng`, `endLat`, `endLng`, `congestionLevel` (free/moderate/heavy/gridlock), `speedKmh`, `updatedAt`. `_parseDouble`.
- **TrafficReport** — `id`, `userId`, `type` (jam/accident/closure/police/flood), `description`, `lat`, `lng`, `severity` (low/medium/high), `photoUrl`, `upvotes`, `createdAt`. `_parseDouble`, `_parseInt`.
- **CommuteRoute** — `id`, `name`, `originLat`, `originLng`, `destLat`, `destLng`, `currentEta`, `normalEta`, `congestionLevel`. `_parseDouble`, `_parseInt`.
- **FuelStation** — `id`, `name`, `brand`, `lat`, `lng`, `distance`, `petrolPrice`, `dieselPrice`, `updatedAt`. `_parseDouble`.
- **BrtStatus** — `routeName`, `direction`, `estimatedArrival`, `stationName`, `isDelayed`. `_parseBool`.

### Service Layer
```dart
Dio get _dio => AuthenticatedDio.instance;
```
- `getTrafficMap(double lat, double lng, double radius)` — `GET /api/traffic/map`
- `getReports({double? lat, double? lng})` — `GET /api/traffic/reports`
- `submitReport(Map data)` — `POST /api/traffic/reports`
- `upvoteReport(int reportId)` — `POST /api/traffic/reports/{id}/upvote`
- `getRouteOptions(double oLat, double oLng, double dLat, double dLng)` — `GET /api/traffic/routes`
- `saveCommute(Map data)` — `POST /api/traffic/commutes`
- `getCommutes()` — `GET /api/traffic/commutes`
- `getFuelStations(double lat, double lng)` — `GET /api/traffic/fuel-stations`
- `getBrtStatus(String route)` — `GET /api/traffic/brt?route={route}`
- `getTrafficHistory(String roadName)` — `GET /api/traffic/history?road={roadName}`

### Pages
- **TrafficMapPage** — Interactive map with color-coded traffic, incident pins, report button
- **MyCommutePage** — Saved routes with current conditions, best departure, ETA
- **ReportsFeedPage** — Chronological community reports by area
- **SubmitReportPage** — Type, location, severity, description, photo
- **RoutePlannerPage** — Origin/destination with route options and time comparison
- **FuelStationsPage** — Map of stations with prices and distance
- **BrtStatusPage** — BRT route map, station list, estimated arrivals
- **TrafficHistoryPage** — Historical congestion charts by road and time
- **ParkingFinderPage** — Commercial area parking with availability

### Widgets
- `TrafficMapOverlay` — Color-coded polylines (green/yellow/red) on map
- `CommuteEta` — Current vs normal ETA comparison display

---

## 2. UI Design
- #1A1A1A/#666666/#FAFAFA/#FFFFFF monochromatic
- 48dp touch, maxLines+ellipsis, _rounded icons
- Dark stat cards for commute ETA and report count
- Cards: radius 12-16, subtle shadow
- Traffic colors on map: #4CAF50 free, #FFC107 moderate, #F44336 heavy

### Main Screen Wireframe
```
┌─────────────────────────────┐
│  🔍 Search destination...   │
│ [Report] [My Routes] [BRT] │
├─────────────────────────────┤
│ ┌─────────────────────────┐ │
│ │                         │ │
│ │   [TRAFFIC MAP]         │ │
│ │  ═══green═══            │ │
│ │     ══red══             │ │
│ │  ═══yellow══  📍 ⚠️     │ │
│ │                         │ │
│ └─────────────────────────┘ │
│                             │
│  My Commute                 │
│ ┌─────────────────────────┐ │
│ │ Home → Office           │ │
│ │ ETA: 55 min (norm: 25)  │ │
│ │ Status: 🔴 Heavy        │ │
│ │ Best depart: 6:15 AM    │ │
│ └─────────────────────────┘ │
│                             │
│  Recent Reports             │
│ ┌─────────────────────────┐ │
│ │ ⚠️ Accident Morogoro Rd │ │
│ │ 🚧 Closure Bagamoyo Rd  │ │
│ └─────────────────────────┘ │
└─────────────────────────────┘
```

---

## 3. Performance Strategy

### SQLite
```sql
CREATE TABLE traffic_reports(id INTEGER PRIMARY KEY, type TEXT, lat REAL, lng REAL, severity TEXT, json_data TEXT, synced_at TEXT);
CREATE TABLE commute_routes(id INTEGER PRIMARY KEY, name TEXT, origin_lat REAL, origin_lng REAL, dest_lat REAL, dest_lng REAL, json_data TEXT, synced_at TEXT);
CREATE TABLE fuel_stations(id INTEGER PRIMARY KEY, name TEXT, lat REAL, lng REAL, petrol_price REAL, json_data TEXT, synced_at TEXT);
```
- Stale-while-revalidate: SQLite first, API background
- TTL: traffic map — 5 minutes (real-time), reports — 10 minutes, fuel — 6 hours
- Offline: read cached routes YES, write reports via pending_queue

---

## 4. Backend Implementation

### Database
```sql
CREATE TABLE traffic_segments(id BIGSERIAL PRIMARY KEY, road_name VARCHAR(200), start_lat DOUBLE PRECISION, start_lng DOUBLE PRECISION, end_lat DOUBLE PRECISION, end_lng DOUBLE PRECISION, congestion_level VARCHAR(20), speed_kmh INTEGER, updated_at TIMESTAMP DEFAULT NOW());

CREATE TABLE traffic_reports(id BIGSERIAL PRIMARY KEY, user_id BIGINT, type VARCHAR(20), description TEXT, lat DOUBLE PRECISION, lng DOUBLE PRECISION, severity VARCHAR(10), photo_url VARCHAR(500), upvotes INTEGER DEFAULT 0, expires_at TIMESTAMP, created_at TIMESTAMP DEFAULT NOW());

CREATE TABLE commute_routes(id BIGSERIAL PRIMARY KEY, user_id BIGINT, name VARCHAR(100), origin_lat DOUBLE PRECISION, origin_lng DOUBLE PRECISION, dest_lat DOUBLE PRECISION, dest_lng DOUBLE PRECISION, created_at TIMESTAMP DEFAULT NOW());

CREATE TABLE fuel_stations(id BIGSERIAL PRIMARY KEY, name VARCHAR(200), brand VARCHAR(100), lat DOUBLE PRECISION, lng DOUBLE PRECISION, petrol_price DECIMAL(10,2), diesel_price DECIMAL(10,2), updated_at TIMESTAMP DEFAULT NOW());

CREATE TABLE brt_status(id BIGSERIAL PRIMARY KEY, route_name VARCHAR(100), station_name VARCHAR(200), direction VARCHAR(20), estimated_arrival TIME, is_delayed BOOLEAN DEFAULT FALSE, updated_at TIMESTAMP DEFAULT NOW());

CREATE TABLE report_upvotes(report_id BIGINT, user_id BIGINT, PRIMARY KEY(report_id, user_id));
```

### API Endpoints
| Method | Endpoint | Description | Auth |
|--------|----------|-------------|------|
| GET | /api/traffic/map | Traffic map data | Bearer |
| GET | /api/traffic/reports | Community reports | Bearer |
| POST | /api/traffic/reports | Submit report | Bearer |
| POST | /api/traffic/reports/{id}/upvote | Upvote report | Bearer |
| GET | /api/traffic/routes | Route options | Bearer |
| POST | /api/traffic/commutes | Save commute | Bearer |
| GET | /api/traffic/commutes | My commutes | Bearer |
| GET | /api/traffic/fuel-stations | Fuel stations | Bearer |
| GET | /api/traffic/brt | BRT status | Bearer |
| GET | /api/traffic/history | Historical data | Bearer |

### Controller
`app/Http/Controllers/Api/TrafficController.php` — DB facade with report expiry (auto-expire after 4 hours) and upvote aggregation.

---

## 5. Integration Wiring
- **LocationService** — GPS traffic map, fuel stations, route directions
- **NotificationService** — commute alerts, accident reports, flood warnings
- **CalendarService** — commute time estimates for calendar events
- **PostService** — share traffic reports to feed
- **GroupService** — local traffic reporting groups
- **WalletService** — parking fees, fuel payments, fine settlement
- **alerts** — rain/flood alerts affect traffic warnings
- **vehicle** — fuel and parking linked to registered vehicles
- **police** — traffic fines and speed camera locations

---

## 6. Implementation Phases
### Phase 1: Foundation (Week 1)
- Data models, service layer, SQLite schema
- Backend tables and traffic data ingestion
- Traffic map with color-coded overlay

### Phase 2: Core UI (Week 2)
- Community report submission and feed
- Route planner with alternatives
- My Commute with ETA tracking

### Phase 3: Integration (Week 3)
- Fuel station locator with prices
- BRT/DART status page
- Historical traffic patterns

### Phase 4: Polish (Week 4)
- Parking finder
- Commute notifications
- Offline cached routes, flood alerts

---

## 7. External APIs & Integrations

| API | Provider | Purpose | Pricing | Integration Notes |
|-----|----------|---------|---------|-------------------|
| TomTom Traffic API | TomTom | Real-time traffic flow, incidents, routing | Freemium (2.5k free/day) | 80+ countries; developer.tomtom.com |
| Google Maps Routes API | Google | Directions, traffic-aware routing, ETAs | Freemium (free tier + $10/1k) | Real-time traffic; replaced legacy Directions API |
| HERE Traffic API v7 | HERE Technologies | Real-time traffic flow, incidents, speed data | Freemium (5k free/month) | $2.50/1k after free; global coverage |
| Mapbox Directions API | Mapbox | Traffic-aware routing, navigation, ETAs | Freemium (100k free/month) | Great mobile SDKs; mapbox.com |
| OpenStreetMap + OSRM | OpenStreetMap | Open-source routing (no live traffic) | Free, open source | Self-hosted routing; project-osrm.org |

### Integration Priority
1. **Immediate** — Free APIs (OpenStreetMap + OSRM for basic routing)
2. **Short-term** — Freemium APIs (TomTom for real-time traffic, Google Routes, Mapbox)
3. **Partnership** — Waze for Cities (government partnership for traffic data)
