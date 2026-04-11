# DC (District Commissioner) — Implementation Plan

## Overview
District-level government transparency and citizen engagement module. Provides access to DC profile, district development projects with budget tracking, complaint submission with tracking, emergency alerts, district statistics dashboard, government department directory, and service information across Tanzania's 169 districts.

---

## 1. Frontend Architecture

### Directory Structure
```
lib/dc/
├── dc_module.dart
├── models/
│   ├── district_models.dart
│   ├── project_models.dart
│   └── complaint_models.dart
├── services/
│   └── dc_service.dart
├── pages/
│   ├── district_home_page.dart
│   ├── dc_profile_page.dart
│   ├── projects_page.dart
│   ├── report_page.dart
│   ├── my_reports_page.dart
│   ├── district_stats_page.dart
│   ├── emergency_center_page.dart
│   ├── department_directory_page.dart
│   └── district_news_page.dart
└── widgets/
    ├── dc_card.dart
    ├── project_card.dart
    ├── budget_chart.dart
    ├── complaint_timeline.dart
    └── emergency_banner.dart
```

### Data Models
- `DistrictCommissioner` — id, name, photo, bio, appointmentDate, previousPositions, contact, officeLocation
- `District` — id, name, regionId, population, wardCount, schools, healthFacilities, economicIndicators
- `DistrictProject` — id, name, budget, funder, contractor, startDate, endDate, progressPercent, photos, sector
- `DistrictComplaint` — id, reporterId, category, description, attachments, status (received/assigned/investigating/resolved), trackingNumber
- `EmergencyAlert` — id, type (flood/disease/security/weather), title, description, severity, districtId, active

### Service Layer
```dart
Dio get _dio => AuthenticatedDio.instance;
```
| Method | Verb | Endpoint | Return |
|--------|------|----------|--------|
| `getDistrict(id)` | GET | `/api/dc/districts/{id}` | `SingleResult<District>` |
| `getDcProfile(districtId)` | GET | `/api/dc/districts/{id}/commissioner` | `SingleResult<DistrictCommissioner>` |
| `getProjects(districtId, filters)` | GET | `/api/dc/projects` | `PaginatedResult<DistrictProject>` |
| `submitComplaint(data)` | POST | `/api/dc/complaints` | `SingleResult<DistrictComplaint>` |
| `getMyComplaints()` | GET | `/api/dc/complaints/mine` | `PaginatedResult<DistrictComplaint>` |
| `getAlerts(districtId)` | GET | `/api/dc/alerts` | `PaginatedResult<EmergencyAlert>` |
| `getStats(districtId)` | GET | `/api/dc/districts/{id}/stats` | `SingleResult<DistrictStats>` |
| `getDepartments(districtId)` | GET | `/api/dc/districts/{id}/departments` | `PaginatedResult<Department>` |

### Pages
- **DistrictHomePage** — DC card, quick stats, recent news, emergency banner
- **DcProfilePage** — Full bio, office details, contact options
- **ProjectsPage** — Filterable project list/map with budget and progress indicators
- **ReportPage** — Category, description, photo/document upload, location pin
- **MyReportsPage** — Submitted complaints with status tracking
- **DistrictStatsPage** — Interactive charts for education, health, economy
- **EmergencyCenterPage** — Active alerts, emergency contacts, safety guidelines
- **DepartmentDirectoryPage** — Departments with contact info and services

### Widgets
- `DcCard` — Photo, name, appointment date, quick contact
- `ProjectCard` — Name, budget bar, progress indicator, sector icon
- `BudgetChart` — Allocated vs disbursed vs spent bar chart
- `EmergencyBanner` — Red banner for active emergencies with dismiss

---

## 2. UI Design
- Palette: #1A1A1A / #666666 / #FAFAFA / #FFFFFF
- Cards: BorderRadius.circular(12-16), subtle shadow
- 48dp touch targets, maxLines+ellipsis, _rounded icons
- Loading: CircularProgressIndicator(strokeWidth: 2, color: _kPrimary)

### Main Screen Wireframe
```
┌─────────────────────────┐
│ ◀  Wilaya: Ilala    🔔  │
├─────────────────────────┤
│ ⚠️ Flood Alert - Jangwani│
├─────────────────────────┤
│ ┌─────────────────────┐ │
│ │ DC: Hon. M. Kileo   │ │
│ │ Appointed: 2024     │ │
│ │ [View Profile]      │ │
│ └─────────────────────┘ │
│ Pop: 1.2M  Wards: 34   │
│                         │
│ [Report] [Projects]     │
│ [Stats]  [Departments]  │
│                         │
│ District News           │
│ ├─ New road project...  │
│ ├─ Health campaign...   │
│ └─ Budget update...     │
└─────────────────────────┘
```

---

## 3. Performance Strategy

### SQLite Local Storage
```sql
CREATE TABLE dc_districts(id INTEGER PRIMARY KEY, region_id INTEGER, json_data TEXT, synced_at TEXT);
CREATE TABLE dc_projects(id INTEGER PRIMARY KEY, district_id INTEGER, sector TEXT, json_data TEXT, synced_at TEXT);
CREATE INDEX idx_dc_projects_district ON dc_projects(district_id);
CREATE TABLE dc_complaints(id INTEGER PRIMARY KEY, user_id INTEGER, status TEXT, json_data TEXT, synced_at TEXT);
```

### Caching
- Load from SQLite first (<5ms) then API background refresh
- TTL: District info 24h, projects 1h, alerts 5min, stats 6h
- Offline read: YES — district info, emergency contacts, department directory
- Offline write: pending_queue for complaints

---

## 4. Backend Implementation

### Database (PostgreSQL)
```sql
CREATE TABLE dc_commissioners (
    id BIGSERIAL PRIMARY KEY, user_id BIGINT REFERENCES users(id),
    district_id BIGINT NOT NULL, bio TEXT, appointment_date DATE,
    previous_positions JSONB, phone TEXT, email TEXT,
    created_at TIMESTAMP DEFAULT NOW(), updated_at TIMESTAMP DEFAULT NOW()
);

CREATE TABLE dc_projects (
    id BIGSERIAL PRIMARY KEY, district_id BIGINT NOT NULL,
    name TEXT NOT NULL, budget DECIMAL(15,2), funder TEXT, contractor TEXT,
    start_date DATE, end_date DATE, progress_percent INTEGER DEFAULT 0,
    sector TEXT, photos JSONB,
    created_at TIMESTAMP DEFAULT NOW(), updated_at TIMESTAMP DEFAULT NOW()
);

CREATE TABLE dc_complaints (
    id BIGSERIAL PRIMARY KEY, reporter_id BIGINT REFERENCES users(id),
    district_id BIGINT NOT NULL, category TEXT, description TEXT,
    attachments JSONB, status TEXT DEFAULT 'received', tracking_number TEXT UNIQUE,
    created_at TIMESTAMP DEFAULT NOW(), updated_at TIMESTAMP DEFAULT NOW()
);
```

### API Endpoints
| Method | Endpoint | Description | Auth |
|--------|----------|-------------|------|
| GET | /api/dc/districts/{id} | District overview | Yes |
| GET | /api/dc/districts/{id}/commissioner | DC profile | Yes |
| GET | /api/dc/projects | District projects | Yes |
| POST | /api/dc/complaints | Submit complaint | Yes |
| GET | /api/dc/complaints/mine | My complaints | Yes |
| GET | /api/dc/alerts | Emergency alerts | Yes |
| GET | /api/dc/districts/{id}/stats | District statistics | Yes |
| GET | /api/dc/districts/{id}/departments | Department directory | Yes |

### Controller
- `app/Http/Controllers/Api/DcController.php`
- DB facade, try/catch, `{"success": true/false, "data": ..., "message": "..."}`

---

## 5. Integration Wiring
- **WalletService** — Government service fee payments at district level
- **MessageService** — Structured communication to DC office
- **NotificationService + FCMService** — Emergency alerts, report status, announcements
- **LiveUpdateService** — Real-time complaint tracking via Firestore
- **LocationService** — GPS-based district detection, content filtering
- **PhotoService** — Project photos, issue report attachments
- **ContributionService** — District-level community fundraising
- **Cross-module: barozi_wangu** — Ward issues escalated to DC
- **Cross-module: rc** — Escalation from DC to Regional Commissioner

---

## 6. Implementation Phases
### Phase 1: Foundation (Week 1)
- Data models, service layer, SQLite schema, module scaffold
- District overview and DC profile APIs

### Phase 2: Core UI (Week 2)
- District home, DC profile, complaint form with tracking
- Development projects list with budget visualization

### Phase 3: Integration (Week 3)
- Emergency alerts with FCM push, LiveUpdateService tracking
- District statistics dashboard with charts

### Phase 4: Polish (Week 4)
- Ward performance comparison, department directory
- Offline caching for emergency contacts and service directory

---

## 7. External APIs & Integrations

| API | Provider | Purpose | Pricing | Integration Notes |
|-----|----------|---------|---------|-------------------|
| Tanzania Open Data Portal | Government of Tanzania | District-level statistics and development data | Free | CKAN API at opendata.go.tz |
| NBS Data Portals | National Bureau of Statistics | District-disaggregated census, economic, social data | Free | TASIS portal at nbs.go.tz/portals |
| HDX Administrative Boundaries | UN OCHA | District boundary shapefiles (admin level 2) | Free | GeoJSON/KML from data.humdata.org |
| World Bank Projects API | World Bank | Development project tracking in Tanzania | Free | REST API at projects.worldbank.org |
| Tanzania Data Portal | Open Data for Africa | District-level economic indicators | Free | REST API via Open Data for Africa platform |
| OpenStreetMap / Nominatim | OSM Foundation | District mapping, geocoding | Free (1 req/sec public) | Self-hostable; good Tanzania coverage |
| AzamPay API | AzamPay | Mobile money payments for district services | Per-transaction | Dart SDK on pub.dev (azampaytanzania) |
| Smile ID | Smile Identity | Identity verification for service access | Pay-per-verification | docs.usesmileid.com — Pan-African KYC |

### Integration Priority
1. **Immediate** — Tanzania Open Data Portal (free), NBS portals (free), HDX boundaries (free), World Bank API (free, no auth), OpenStreetMap (free)
2. **Short-term** — AzamPay for district service payments (has Dart SDK), Smile ID for citizen verification
3. **Partnership** — Direct district government data feeds, GePG for government fee payments
