# RC (Regional Commissioner) — Implementation Plan

## Overview
Regional-level government transparency module for Tanzania's 31 regions. Provides RC profile, regional development plans and mega projects, cross-district budget visualization, regional statistics dashboard, complaint escalation from DC level, emergency coordination, investment opportunities, and historical data.

---

## 1. Frontend Architecture

### Directory Structure
```
lib/rc/
├── rc_module.dart
├── models/
│   ├── region_models.dart
│   ├── mega_project_models.dart
│   └── investment_models.dart
├── services/
│   └── rc_service.dart
├── pages/
│   ├── region_home_page.dart
│   ├── rc_profile_page.dart
│   ├── districts_overview_page.dart
│   ├── development_dashboard_page.dart
│   ├── regional_stats_page.dart
│   ├── report_page.dart
│   ├── emergency_center_page.dart
│   ├── investment_portal_page.dart
│   └── regional_news_page.dart
└── widgets/
    ├── rc_card.dart
    ├── district_comparison_chart.dart
    ├── mega_project_card.dart
    └── budget_breakdown_chart.dart
```

### Data Models
- `RegionalCommissioner` — id, name, photo, bio, appointmentDate, careerHistory, contact, officeLocation
- `Region` — id, name, population, districtCount, area, gdpContribution, majorIndustries, demographics
- `MegaProject` — id, name, budget, contractors, startDate, endDate, progressPercent, photos, satellite, type
- `RegionalBudget` — regionId, year, sectors (list of SectorAllocation: name, allocated, disbursed, spent)
- `InvestmentOpportunity` — id, title, sector, description, land, incentives, contactInfo

### Service Layer
```dart
Dio get _dio => AuthenticatedDio.instance;
```
| Method | Verb | Endpoint | Return |
|--------|------|----------|--------|
| `getRegion(id)` | GET | `/api/rc/regions/{id}` | `SingleResult<Region>` |
| `getRcProfile(regionId)` | GET | `/api/rc/regions/{id}/commissioner` | `SingleResult<RegionalCommissioner>` |
| `getDistricts(regionId)` | GET | `/api/rc/regions/{id}/districts` | `PaginatedResult<District>` |
| `getMegaProjects(regionId)` | GET | `/api/rc/projects` | `PaginatedResult<MegaProject>` |
| `getBudget(regionId, year)` | GET | `/api/rc/regions/{id}/budget` | `SingleResult<RegionalBudget>` |
| `getStats(regionId)` | GET | `/api/rc/regions/{id}/stats` | `SingleResult<RegionalStats>` |
| `submitReport(data)` | POST | `/api/rc/reports` | `SingleResult<Report>` |
| `escalateComplaint(complaintId)` | POST | `/api/rc/escalate/{id}` | `SingleResult<Report>` |
| `getInvestments(regionId)` | GET | `/api/rc/investments` | `PaginatedResult<InvestmentOpportunity>` |

### Pages
- **RegionHomePage** — RC card, region map, key stats, active alerts, recent news
- **RcProfilePage** — Full bio, office details, photo gallery
- **DistrictsOverviewPage** — Map and list of districts with key metrics and DC info
- **DevelopmentDashboardPage** — Regional plan progress, mega projects, budget charts
- **RegionalStatsPage** — Interactive data visualization with sector filters
- **ReportPage** — Complaint/suggestion submission with escalation option
- **EmergencyCenterPage** — Active alerts map across districts, safety resources
- **InvestmentPortalPage** — Opportunities, economic data, contact forms

### Widgets
- `RcCard` — Photo, name, region, appointment date
- `DistrictComparisonChart` — Horizontal bar chart comparing district metrics
- `MegaProjectCard` — Photo, budget, progress, contractor, timeline
- `BudgetBreakdownChart` — Pie/bar chart for sector allocation

---

## 2. UI Design
- Palette: #1A1A1A / #666666 / #FAFAFA / #FFFFFF
- Cards: BorderRadius.circular(12-16), subtle shadow
- 48dp touch targets, maxLines+ellipsis, _rounded icons
- Loading: CircularProgressIndicator(strokeWidth: 2, color: _kPrimary)

### Main Screen Wireframe
```
┌─────────────────────────┐
│ ◀  Mkoa: Dar es Salaam 🔔│
├─────────────────────────┤
│ ┌─────────────────────┐ │
│ │ RC: Hon. A. Makonda │ │
│ │ [View Profile]      │ │
│ └─────────────────────┘ │
│ Districts: 5  Pop: 6.4M │
│                         │
│ [Districts] [Projects]  │
│ [Stats]    [Invest]     │
│                         │
│ Mega Projects           │
│ ├─ BRT Phase 4  78%    │
│ ├─ Kigamboni Br. 95%   │
│ └─ Water Phase 3 42%   │
│                         │
│ Regional News ›         │
│ Emergency Center ›      │
└─────────────────────────┘
```

---

## 3. Performance Strategy

### SQLite Local Storage
```sql
CREATE TABLE rc_regions(id INTEGER PRIMARY KEY, json_data TEXT, synced_at TEXT);
CREATE TABLE rc_mega_projects(id INTEGER PRIMARY KEY, region_id INTEGER, json_data TEXT, synced_at TEXT);
CREATE INDEX idx_rc_projects_region ON rc_mega_projects(region_id);
CREATE TABLE rc_investments(id INTEGER PRIMARY KEY, region_id INTEGER, sector TEXT, json_data TEXT, synced_at TEXT);
```

### Caching
- Load from SQLite first (<5ms) then API background refresh
- TTL: Region info 24h, mega projects 2h, stats 6h, alerts 5min
- Offline read: YES — region info, emergency contacts, investment data
- Offline write: pending_queue for reports

---

## 4. Backend Implementation

### Database (PostgreSQL)
```sql
CREATE TABLE rc_commissioners (
    id BIGSERIAL PRIMARY KEY, user_id BIGINT REFERENCES users(id),
    region_id BIGINT NOT NULL, bio TEXT, appointment_date DATE,
    career_history JSONB, phone TEXT, email TEXT,
    created_at TIMESTAMP DEFAULT NOW(), updated_at TIMESTAMP DEFAULT NOW()
);

CREATE TABLE rc_mega_projects (
    id BIGSERIAL PRIMARY KEY, region_id BIGINT NOT NULL,
    name TEXT NOT NULL, budget DECIMAL(15,2), contractors JSONB,
    start_date DATE, end_date DATE, progress_percent INTEGER DEFAULT 0,
    type TEXT, photos JSONB, satellite_url TEXT,
    created_at TIMESTAMP DEFAULT NOW(), updated_at TIMESTAMP DEFAULT NOW()
);

CREATE TABLE rc_investments (
    id BIGSERIAL PRIMARY KEY, region_id BIGINT NOT NULL,
    title TEXT, sector TEXT, description TEXT,
    land_info TEXT, incentives TEXT, contact_info JSONB,
    created_at TIMESTAMP DEFAULT NOW()
);
```

### API Endpoints
| Method | Endpoint | Description | Auth |
|--------|----------|-------------|------|
| GET | /api/rc/regions/{id} | Region overview | Yes |
| GET | /api/rc/regions/{id}/commissioner | RC profile | Yes |
| GET | /api/rc/regions/{id}/districts | Districts list | Yes |
| GET | /api/rc/projects | Mega projects | Yes |
| GET | /api/rc/regions/{id}/budget | Regional budget | Yes |
| GET | /api/rc/regions/{id}/stats | Regional statistics | Yes |
| POST | /api/rc/reports | Submit report | Yes |
| POST | /api/rc/escalate/{id} | Escalate DC complaint | Yes |
| GET | /api/rc/investments | Investment opportunities | Yes |

### Controller
- `app/Http/Controllers/Api/RcController.php`
- DB facade, try/catch, `{"success": true/false, "data": ..., "message": "..."}`

---

## 5. Integration Wiring
- **WalletService** — Regional government service payments
- **NotificationService + FCMService** — Regional emergencies, report updates, policy announcements
- **LiveUpdateService** — Complaint escalation tracking via Firestore
- **LocationService** — GPS-based region detection, content filtering
- **ContributionService** — Regional development fundraising
- **Cross-module: dc** — Aggregates district data; escalation from DC to RC
- **Cross-module: barozi_wangu** — Complete chain: Ward > DC > RC
- **Cross-module: business/** — Investment opportunities linked to TAJIRI business features

---

## 6. Implementation Phases
### Phase 1: Foundation (Week 1)
- Data models, service layer, SQLite schema, module scaffold
- Region overview and RC profile APIs

### Phase 2: Core UI (Week 2)
- Region home, districts overview with comparison charts
- Mega projects with progress tracking, budget visualization

### Phase 3: Integration (Week 3)
- Complaint escalation from DC module, emergency center
- Regional statistics dashboard with interactive charts

### Phase 4: Polish (Week 4)
- Investment portal, cross-district comparison
- Offline support, historical data timeline

---

## 7. External APIs & Integrations

| API | Provider | Purpose | Pricing | Integration Notes |
|-----|----------|---------|---------|-------------------|
| Tanzania Open Data Portal | Government of Tanzania | Regional statistics, development indicators | Free | CKAN API at opendata.go.tz |
| NBS Data Portals | National Bureau of Statistics | Regional census, demographic, health survey data | Free | nbs.go.tz/portals — TASIS, TNADA |
| HDX Administrative Boundaries | UN OCHA | Regional boundary shapefiles (admin level 1) | Free | data.humdata.org — includes Songwe region (TZ26) |
| World Bank Open Data API | World Bank | Regional development indicators for Tanzania | Free | REST API, JSON/XML, no auth required |
| Tanzania Data Portal | Open Data for Africa | Regional economic, social, demographic data | Free | REST API via Open Data for Africa |
| OpenStreetMap / Nominatim | OSM Foundation | Regional mapping, geocoding | Free (1 req/sec public) | Self-hostable; full Tanzania coverage |
| AzamPay API | AzamPay | Mobile money payments for regional services | Per-transaction | Dart SDK on pub.dev (azampaytanzania) |

### Integration Priority
1. **Immediate** — Tanzania Open Data Portal (free), NBS portals (free), HDX boundaries (free), World Bank API (free, no auth), OpenStreetMap (free)
2. **Short-term** — AzamPay for regional service payments (has Dart SDK)
3. **Partnership** — Regional government data feeds, GePG for government fee payments (institutional access)
