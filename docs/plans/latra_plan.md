# LATRA (Land Transport Regulatory Authority) — Implementation Plan

## Overview

The LATRA module provides Tanzanian citizens a digital interface to the Land Transport Regulatory Authority. It covers browsing approved transport routes with official fare caps, a fare checker to detect overcharging on daladala/boda-boda/bajaji/ride-hailing trips, complaint filing against reckless or abusive drivers with evidence upload, operator license verification, intercity bus schedules with safety ratings, and driver/conductor rating. It replaces paper-heavy bureaucratic processes with mobile-first access to transport regulation information.

---

## 1. Frontend Architecture

### Directory Structure
```
lib/latra/
├── latra_module.dart                  — Entry point & route registration
├── models/
│   ├── route_models.dart              — TransportRoute, FareCap, RouteType
│   ├── complaint_models.dart          — Complaint, ComplaintType, Status
│   ├── operator_models.dart           — Operator, LicenceStatus, Vehicle
│   └── bus_schedule_models.dart       — BusRoute, BusOperator, Schedule
├── services/
│   └── latra_service.dart             — API service using AuthenticatedDio
├── pages/
│   ├── latra_home_page.dart           — Quick fare check, complaints, alerts
│   ├── route_fare_browser_page.dart   — Searchable routes with fare caps
│   ├── fare_checker_page.dart         — Origin/destination fare lookup
│   ├── complaint_form_page.dart       — Multi-step with evidence upload
│   ├── my_complaints_page.dart        — Filed complaints with status
│   ├── operator_search_page.dart      — Verify operator/vehicle licence
│   ├── safety_hub_page.dart           — Tips, statistics, emergency contacts
│   └── bus_schedule_page.dart         — Intercity bus timetable
└── widgets/
    ├── fare_result_widget.dart         — Approved fare with overcharge alert
    ├── complaint_status_widget.dart    — Status timeline for filed complaint
    ├── operator_badge_widget.dart      — Licensed/unlicensed indicator
    ├── safety_alert_widget.dart        — Warning banner for road alerts
    └── route_card_widget.dart          — Route with fare and transport type
```

### Data Models
- **TransportRoute**: id, origin, destination, routeType (daladala/bus/boda/bajaji/ridehail), fareCap, distance, operators[], updatedAt. `factory TransportRoute.fromJson()`.
- **Complaint**: id, userId, plateNumber, routeDescription, type (overcharging/reckless/harassment/refusal), description, evidencePhotos[], evidenceVideo, status (submitted/reviewing/resolved/dismissed), resolution, referenceNumber, createdAt. `factory Complaint.fromJson()`.
- **Operator**: id, name, licenceNumber, licenceStatus (active/suspended/revoked/expired), vehicleCount, complianceRating, routes[]. `factory Operator.fromJson()`.
- **BusRoute**: id, origin, destination, operator, departureTime, arrivalTime, fare, safetyRating, frequency. `factory BusRoute.fromJson()`.

### Service Layer
- `searchRoutes(Map params)` — GET `/api/latra/routes`
- `checkFare(Map originDest)` — GET `/api/latra/fare-check`
- `fileComplaint(Map data)` — POST `/api/latra/complaints`
- `getMyComplaints()` — GET `/api/latra/complaints`
- `getComplaint(int id)` — GET `/api/latra/complaints/{id}`
- `verifyOperator(String licenceOrPlate)` — GET `/api/latra/operators/verify`
- `getBusSchedules(Map params)` — GET `/api/latra/bus-schedules`
- `getSafetyAlerts()` — GET `/api/latra/safety-alerts`
- `rateDriver(Map ratingData)` — POST `/api/latra/ratings`

### Pages & Screens
- **LATRA Home**: Fare checker shortcut, recent safety alerts banner, quick complaint button, stats cards.
- **Route & Fare Browser**: Search by origin/destination, filterable by transport type, fare caps listed.
- **Fare Checker**: Two-field origin/destination, result shows approved fare + alert if being overcharged.
- **Complaint Form**: Steps -- plate number, incident type, description, evidence photo/video, location.
- **Operator Search**: Enter plate or licence number, verify status, view compliance history.
- **Bus Schedule**: Route list with departure/arrival times, safety ratings, operator info.

### Widgets
- `FareResultWidget` — Large fare display, green "Within limit" or red "Overcharging!" alert
- `ComplaintStatusWidget` — Vertical timeline: submitted > reviewing > resolved
- `OperatorBadgeWidget` — Green checkmark "Licensed" or red X "Unlicensed"
- `SafetyAlertWidget` — Yellow/red warning banner with alert text
- `RouteCardWidget` — Origin > Destination, fare cap, transport type icon

---

## 2. UI Design

- Fare checker: Large input fields, prominent result with color-coded status
- Complaints: Step indicator, evidence upload grid
- Operator verification: Search bar with instant result card
- Safety alerts: Colored banner at top of home page

### Key Screen Mockup — Fare Checker
```
┌─────────────────────────────┐
│  SafeArea                   │
│  LATRA Fare Checker         │
│  ┌───────────────────────┐  │
│  │ From: [Mwenge       ] │  │
│  │ To:   [Kariakoo     ] │  │
│  │ Type: [Daladala  ▼ ] │  │
│  │       [Check Fare]    │  │
│  └───────────────────────┘  │
│  ┌───────────────────────┐  │
│  │ Approved Fare:        │  │
│  │   TZS 700             │  │
│  │ ✓ Within LATRA limit  │  │
│  │                       │  │
│  │ Paying more?          │  │
│  │ [File Complaint]      │  │
│  └───────────────────────┘  │
└─────────────────────────────┘
```

---

## 3. Performance Strategy

### Local-First with SQLite
```dart
// Table: latra_routes
// Columns: id INTEGER PRIMARY KEY, origin TEXT, destination TEXT, route_type TEXT, fare_cap REAL, json_data TEXT, synced_at TEXT
// Indexes: origin, destination, route_type
// Table: latra_complaints
// Columns: id INTEGER PRIMARY KEY, status TEXT, reference TEXT, json_data TEXT, synced_at TEXT
// Indexes: status
```

### Stale-While-Revalidate
- Routes/fares: cache TTL 7 days (fares update monthly)
- Complaints: cache TTL 30 minutes
- Bus schedules: cache TTL 24 hours
- Safety alerts: cache TTL 1 hour

### Offline Support
- Read: Route fares (critical for offline fare checking), complaint history, bus schedules
- Write: Complaint drafts saved locally, submitted on reconnect
- Sync: Route fares bulk-synced monthly

### Media Caching
- Complaint evidence photos: cached locally until upload confirmed
- Safety tip illustrations: pre-cached

---

## 4. Backend Implementation

### Database Tables
```sql
CREATE TABLE latra_routes (
    id BIGSERIAL PRIMARY KEY,
    origin VARCHAR(255),
    destination VARCHAR(255),
    route_type VARCHAR(30),
    fare_cap DECIMAL(10,2),
    distance_km DECIMAL(8,2),
    region VARCHAR(100),
    effective_date DATE,
    created_at TIMESTAMP DEFAULT NOW(),
    updated_at TIMESTAMP DEFAULT NOW()
);

CREATE TABLE latra_complaints (
    id BIGSERIAL PRIMARY KEY,
    user_id BIGINT REFERENCES users(id),
    plate_number VARCHAR(20),
    route_description TEXT,
    complaint_type VARCHAR(30),
    description TEXT,
    evidence_photos JSONB DEFAULT '[]',
    evidence_video TEXT,
    latitude DECIMAL(10,7),
    longitude DECIMAL(10,7),
    reference_number VARCHAR(20) UNIQUE,
    status VARCHAR(20) DEFAULT 'submitted',
    resolution TEXT,
    created_at TIMESTAMP DEFAULT NOW(),
    updated_at TIMESTAMP DEFAULT NOW()
);

CREATE TABLE latra_operators (
    id BIGSERIAL PRIMARY KEY,
    name VARCHAR(255),
    licence_number VARCHAR(50),
    licence_status VARCHAR(20),
    vehicle_count INTEGER,
    compliance_rating DECIMAL(3,2),
    routes JSONB DEFAULT '[]',
    created_at TIMESTAMP DEFAULT NOW(),
    updated_at TIMESTAMP DEFAULT NOW()
);
```

### API Endpoints
| Method | Endpoint | Description | Auth |
|--------|----------|-------------|------|
| GET | /api/latra/routes | Search routes | Yes |
| GET | /api/latra/fare-check | Check fare | Yes |
| POST | /api/latra/complaints | File complaint | Yes |
| GET | /api/latra/complaints | My complaints | Yes |
| GET | /api/latra/complaints/{id} | Complaint detail | Yes |
| GET | /api/latra/operators/verify | Verify operator | Yes |
| GET | /api/latra/bus-schedules | Bus schedules | Yes |
| GET | /api/latra/safety-alerts | Safety alerts | Yes |
| POST | /api/latra/ratings | Rate driver | Yes |

### Controller
- File: `app/Http/Controllers/Api/LatraController.php`
- Pattern: DB facade, try/catch, `{"success": true, "data": ...}` responses
- Routes data: Scraped/parsed from latra.go.tz and cached in DB

### Background Jobs
- Monthly fare cap update from LATRA publications
- Complaint status polling (if LATRA provides tracking)
- Safety alert publication
- Bus schedule sync

---

## 5. Integration Wiring

- **Wallet**: PSV licence fees, traffic fine payments, registration fees.
- **Transport**: Fare verification during ride-hailing trips. Route planning with approved fares.
- **Messaging**: Complaint resolution updates, LATRA officer communication.
- **Groups**: Transport operator groups, driver safety communities, passenger rights.
- **Notifications**: Fare cap updates, complaint status changes, safety warnings.
- **My Cars**: LATRA inspection certificate storage, roadworthiness status.
- **Location**: Route-based fare lookup, nearest LATRA office, accident reporting GPS.
- **Rent Car**: Rental company LATRA licence verification.
- **EWURA**: Cross-reference fuel prices with transport fare structures.
- **Profile**: Licensed operator badge on transport provider profiles.

---

## 6. Implementation Phases

### Phase 1: Foundation (Week 1)
- [ ] Create directory structure and latra_module.dart
- [ ] Route, Complaint, Operator, BusRoute models
- [ ] LatraService with AuthenticatedDio
- [ ] Backend: migrations + routes/complaints endpoints
- [ ] SQLite table for routes (offline fare checking)

### Phase 2: Core UI (Week 2)
- [ ] LATRA Home with quick actions
- [ ] Fare Checker with result display
- [ ] Route & Fare Browser with search
- [ ] Complaint Form with evidence upload
- [ ] My Complaints with status tracking

### Phase 3: Integration (Week 3)
- [ ] Wire to WalletService for payments
- [ ] Wire to Transport for fare verification
- [ ] Wire to NotificationService for alerts
- [ ] Wire to LocationService for route lookup

### Phase 4: Polish (Week 4)
- [ ] Operator Verification search
- [ ] Bus Schedule timetable
- [ ] Safety Hub with tips and statistics
- [ ] Offline fare lookup
- [ ] Driver/conductor rating
- [ ] Empty states and error handling

---

## 7. External APIs & Integrations

| API | Provider | Purpose | Pricing | Integration Notes |
|-----|----------|---------|---------|-------------------|
| [LATRA VTS](https://vts.latra.go.tz/) | Land Transport Regulatory Authority | Commercial vehicle GPS tracking, compliance verification | Government system | GPS-based tracking for intercity buses. Contact LATRA for integration |
| [LATRA RRIMS](https://rrims.latra.go.tz/) | Land Transport Regulatory Authority | Railway & Road Information Management | Government system | Route and operator data. No public API — partnership required |
| [Google Maps Platform](https://developers.google.com/maps) | Google | Route display, bus stop locations, directions | Freemium (10K free/month) | Routes API for public transport routing. Places API for stops |
| [Mapbox](https://docs.mapbox.com/) | Mapbox | Maps, transit route visualization | Freemium (100K free directions/month) | Good for displaying bus routes on map |
| [OpenRouteService](https://openrouteservice.org/) | HeiGIT | Routing, isochrones for coverage analysis | Free (open source) | Uses OpenStreetMap data. Self-hostable via Docker |
| [M-Pesa Open API](https://openapiportal.m-pesa.com) | Vodacom Tanzania | Fare payments, ticket purchases | Transaction fees | Dart SDK: `mpesa_sdk` on pub.dev |
| [AzamPay API](https://developers.azampay.co.tz/) | AzamPay (Bakhresa Group) | Payment gateway for transport fares | Transaction fees | Flutter SDK: `azampaytanzania` on pub.dev |
| [Africa's Talking](https://developers.africastalking.com/) | Africa's Talking | SMS alerts for schedule changes, safety reports | Pay-as-you-go | Supports all 3 major TZ telcos |
| [Firebase Cloud Messaging](https://firebase.google.com/docs/cloud-messaging) | Google | Schedule notifications, safety alerts | Free | Already integrated in TAJIRI app |
