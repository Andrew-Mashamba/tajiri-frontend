# Police (Polisi) — Implementation Plan

## Overview
Emergency and police services module with one-tap emergency calling (112/114), nearest station finder, digital crime reporting, case tracking, traffic fine payment via M-Pesa, SOS alerts, incident mapping, and legal rights information for Tanzanian citizens.

---

## 1. Frontend Architecture

### Directory Structure
```
lib/police/
├── police_module.dart
├── models/
│   ├── police_station.dart
│   ├── crime_report.dart
│   ├── traffic_fine.dart
│   ├── incident.dart
│   └── emergency_contact.dart
├── services/
│   └── police_service.dart          — AuthenticatedDio.instance
├── pages/
│   ├── police_home_page.dart
│   ├── emergency_page.dart
│   ├── station_finder_page.dart
│   ├── station_detail_page.dart
│   ├── report_crime_page.dart
│   ├── my_reports_page.dart
│   ├── traffic_fines_page.dart
│   ├── safety_tips_page.dart
│   ├── sos_settings_page.dart
│   └── incident_map_page.dart
└── widgets/
    ├── emergency_call_button.dart
    ├── station_card.dart
    ├── report_status_badge.dart
    ├── fine_card.dart
    ├── sos_button.dart
    ├── incident_pin.dart
    └── safety_tip_card.dart
```

### Data Models
- **PoliceStation** — `id`, `name`, `address`, `lat`, `lng`, `distance`, `phone`, `ocdName`, `ocdPhone`, `operatingHours`, `regionName`, `districtName`. `_parseDouble`, `_parseInt`.
- **CrimeReport** — `id`, `userId`, `incidentType`, `description`, `location`, `lat`, `lng`, `dateTime`, `photos` (List), `caseNumber`, `status` (received/investigating/resolved), `createdAt`. `_parseDouble`.
- **TrafficFine** — `id`, `plateNumber`, `licenseNumber`, `offense`, `amount`, `dueDate`, `isPaid`, `transactionRef`. `_parseDouble`, `_parseBool`.
- **Incident** — `id`, `type`, `description`, `lat`, `lng`, `severity`, `reportedAt`, `isResolved`. `_parseDouble`, `_parseBool`.
- **EmergencyContact** — `id`, `name`, `phone`, `relationship`, `isPrimary`. `_parseBool`.

### Service Layer
```dart
Dio get _dio => AuthenticatedDio.instance;
```
- `getNearestStations(double lat, double lng)` — `GET /api/police/stations?lat={lat}&lng={lng}`
- `getStation(int id)` — `GET /api/police/stations/{id}`
- `reportCrime(Map data)` — `POST /api/police/reports`
- `getMyReports()` — `GET /api/police/reports`
- `getReportStatus(int id)` — `GET /api/police/reports/{id}`
- `lookupFines(String plateNumber)` — `GET /api/police/fines?plate={plateNumber}`
- `payFine(int fineId, Map paymentData)` — `POST /api/police/fines/{id}/pay`
- `triggerSOS(Map data)` — `POST /api/police/sos`
- `getIncidentMap(double lat, double lng, double radius)` — `GET /api/police/incidents`
- `getEmergencyContacts()` — `GET /api/police/emergency-contacts`
- `saveEmergencyContact(Map data)` — `POST /api/police/emergency-contacts`

### Pages
- **PoliceHomePage** — Emergency call button (prominent), nearest station, alerts, quick actions
- **EmergencyPage** — Large SOS button, auto-location, emergency contact dial, countdown
- **StationFinderPage** — Map with police station pins, list view with distance and phone
- **StationDetailPage** — Address, contacts, OCD info, operating hours, directions
- **ReportCrimePage** — Incident type, date/time, location, description, photo upload
- **MyReportsPage** — Filed reports with status (received, investigating, resolved)
- **TrafficFinesPage** — Lookup by plate/license, fine details, M-Pesa payment
- **SOSSettingsPage** — Emergency contacts, alert preferences, auto-location
- **IncidentMapPage** — Heat map and pins showing recent incidents

### Widgets
- `EmergencyCallButton` — Large red circular button with 112/114 dial
- `SOSButton` — Silent panic button with countdown and GPS broadcast

---

## 2. UI Design
- #1A1A1A/#666666/#FAFAFA/#FFFFFF monochromatic
- 48dp touch (emergency buttons larger: 72dp), maxLines+ellipsis, _rounded icons
- Dark stat cards for nearest station distance
- Cards: radius 12-16, subtle shadow
- Emergency elements use high-contrast styling for quick access

### Main Screen Wireframe
```
┌─────────────────────────────┐
│ ← Polisi                ⚙️   │
├─────────────────────────────┤
│ ┌─────────────────────────┐ │
│ │    ┌──────────────┐     │ │
│ │    │  🚨 DHARURA  │     │ │
│ │    │  Piga 112    │     │ │
│ │    └──────────────┘     │ │
│ └─────────────────────────┘ │
│                             │
│  Nearest Station            │
│ ┌─────────────────────────┐ │
│ │ Polisi Ilala • 1.2 km   │ │
│ │ 📞 022-211-XXXX         │ │
│ │ [Call] [Directions]     │ │
│ └─────────────────────────┘ │
│                             │
│ ┌──────┐┌──────┐┌──────┐   │
│ │Report││Fines ││ SOS  │   │
│ │Crime ││      ││Alert │   │
│ └──────┘└──────┘└──────┘   │
│ ┌──────┐┌──────┐┌──────┐   │
│ │My    ││Safety││Incid.│   │
│ │Cases ││ Tips ││ Map  │   │
│ └──────┘└──────┘└──────┘   │
└─────────────────────────────┘
```

---

## 3. Performance Strategy

### SQLite
```sql
CREATE TABLE police_stations(id INTEGER PRIMARY KEY, name TEXT, lat REAL, lng REAL, phone TEXT, json_data TEXT, synced_at TEXT);
CREATE TABLE crime_reports(id INTEGER PRIMARY KEY, user_id INTEGER, status TEXT, case_number TEXT, json_data TEXT, synced_at TEXT);
CREATE TABLE emergency_contacts(id INTEGER PRIMARY KEY, name TEXT, phone TEXT, is_primary INTEGER, synced_at TEXT);
CREATE INDEX idx_stations_location ON police_stations(lat, lng);
```
- Stale-while-revalidate: SQLite first, API background
- TTL: stations — 24 hours, reports — 15 minutes, incidents — 30 minutes
- Offline: read stations YES, emergency call works offline, reports via pending_queue

---

## 4. Backend Implementation

### Database
```sql
CREATE TABLE police_stations(id BIGSERIAL PRIMARY KEY, name VARCHAR(200), address TEXT, lat DOUBLE PRECISION, lng DOUBLE PRECISION, phone VARCHAR(20), ocd_name VARCHAR(200), ocd_phone VARCHAR(20), operating_hours VARCHAR(100), region_name VARCHAR(100), district_name VARCHAR(100), created_at TIMESTAMP DEFAULT NOW());

CREATE TABLE crime_reports(id BIGSERIAL PRIMARY KEY, user_id BIGINT, incident_type VARCHAR(50), description TEXT, location TEXT, lat DOUBLE PRECISION, lng DOUBLE PRECISION, incident_datetime TIMESTAMP, photos JSONB, case_number VARCHAR(50), status VARCHAR(20) DEFAULT 'received', assigned_station_id BIGINT, created_at TIMESTAMP DEFAULT NOW(), updated_at TIMESTAMP DEFAULT NOW());

CREATE TABLE traffic_fines(id BIGSERIAL PRIMARY KEY, plate_number VARCHAR(20), license_number VARCHAR(50), offense VARCHAR(200), amount DECIMAL(12,2), due_date DATE, is_paid BOOLEAN DEFAULT FALSE, transaction_ref VARCHAR(100), created_at TIMESTAMP DEFAULT NOW());

CREATE TABLE incidents(id BIGSERIAL PRIMARY KEY, type VARCHAR(50), description TEXT, lat DOUBLE PRECISION, lng DOUBLE PRECISION, severity VARCHAR(20), reported_by BIGINT, is_resolved BOOLEAN DEFAULT FALSE, reported_at TIMESTAMP DEFAULT NOW());

CREATE TABLE emergency_contacts(id BIGSERIAL PRIMARY KEY, user_id BIGINT, name VARCHAR(200), phone VARCHAR(20), relationship VARCHAR(50), is_primary BOOLEAN DEFAULT FALSE);

CREATE TABLE sos_alerts(id BIGSERIAL PRIMARY KEY, user_id BIGINT, lat DOUBLE PRECISION, lng DOUBLE PRECISION, triggered_at TIMESTAMP DEFAULT NOW(), resolved_at TIMESTAMP);
```

### API Endpoints
| Method | Endpoint | Description | Auth |
|--------|----------|-------------|------|
| GET | /api/police/stations | Nearest stations | Bearer |
| GET | /api/police/stations/{id} | Station detail | Bearer |
| POST | /api/police/reports | File crime report | Bearer |
| GET | /api/police/reports | My reports | Bearer |
| GET | /api/police/reports/{id} | Report status | Bearer |
| GET | /api/police/fines | Lookup fines | Bearer |
| POST | /api/police/fines/{id}/pay | Pay fine | Bearer |
| POST | /api/police/sos | Trigger SOS | Bearer |
| GET | /api/police/incidents | Incident map | Bearer |
| GET | /api/police/emergency-contacts | My contacts | Bearer |
| POST | /api/police/emergency-contacts | Save contact | Bearer |

### Controller
`app/Http/Controllers/Api/PoliceController.php` — DB facade with proximity search and M-Pesa fine payment callback.

---

## 5. Integration Wiring
- **LocationService** — nearest station search, SOS GPS auto-send
- **MessageService** — SOS alerts to emergency contacts
- **WalletService** — traffic fine payment via M-Pesa
- **NotificationService** — SOS confirmations, case status updates
- **CalendarService** — court dates and follow-up appointments
- **ProfileService** — emergency contacts stored in profile
- **neighbourhood_watch** — community policing integration
- **alerts** — police safety alerts in alert system
- **traffic** — fine lookup linked to vehicles

---

## 6. Implementation Phases
### Phase 1: Foundation (Week 1)
- Data models, service layer, SQLite schema
- Backend tables, police station data import
- Emergency call page with 112/114

### Phase 2: Core UI (Week 2)
- Station finder with map
- Crime report submission with photos
- My reports with status tracking

### Phase 3: Integration (Week 3)
- Traffic fine lookup and M-Pesa payment
- SOS alert system with GPS broadcast
- Incident map

### Phase 4: Polish (Week 4)
- Safety tips content
- Legal rights information
- Offline emergency contacts, push notifications

---

## 7. External APIs & Integrations

| API | Provider | Purpose | Pricing | Integration Notes |
|-----|----------|---------|---------|-------------------|
| Google Places API | Google | Police station locations, details, contact info | Freemium (10k free/month) | type=police; place details; developers.google.com/maps |
| CrimeoMeter API | CrimeoMeter | Crime data, safety index, incident mapping | Freemium | Safety Quality Index; 50+ US states; crimeometer.com |
| Firebase Cloud Messaging | Google | Emergency alert push notifications | Free (with Firebase) | Topic-based messaging for area-specific alerts |
| OpenStreetMap Overpass | OpenStreetMap | Police station locations from OSM | Free, open source | amenity=police; global coverage |

**Note for East Africa:** No public crime data APIs exist for Tanzania/Kenya. Recommended: build custom incident reporting system with local police integration, use Google Places for station locations.

### Integration Priority
1. **Immediate** — Free APIs (OpenStreetMap for police station locations, Firebase for alerts)
2. **Short-term** — Freemium APIs (Google Places for rich station details, CrimeoMeter for crime context)
3. **Partnership** — Local police departments (custom integration for East Africa)
