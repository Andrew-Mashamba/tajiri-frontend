# Barozi Wangu (My Councillor) — Implementation Plan

## Overview
Ward-level civic engagement module connecting citizens with their elected Ward Councillors (Madiwani). Features councillor discovery by GPS/ward, direct messaging, issue reporting with tracking, campaign promise accountability, performance scorecards, ward forums, and development project transparency across Tanzania's 3,900+ wards.

---

## 1. Frontend Architecture

### Directory Structure
```
lib/barozi_wangu/
├── barozi_wangu_module.dart
├── models/
│   ├── councillor_models.dart
│   ├── issue_models.dart
│   └── promise_models.dart
├── services/
│   └── barozi_wangu_service.dart
├── pages/
│   ├── ward_home_page.dart
│   ├── councillor_profile_page.dart
│   ├── issue_report_page.dart
│   ├── issue_tracker_page.dart
│   ├── promise_tracker_page.dart
│   ├── ward_forum_page.dart
│   ├── council_meetings_page.dart
│   └── development_projects_page.dart
└── widgets/
    ├── councillor_card.dart
    ├── issue_status_timeline.dart
    ├── promise_status_badge.dart
    └── scorecard_widget.dart
```

### Data Models
- `Councillor` — id, name, photo, party, ward, contact, termStart, termEnd, committees; `fromJson` with `_parseInt`, `_parseBool`
- `WardIssue` — id, reporterId, category (enum: roads/water/sanitation/electricity/security), description, photoUrls, gpsLat, gpsLng, status (enum: submitted/acknowledged/inProgress/resolved), priority, timeline
- `CampaignPromise` — id, councillorId, description, status (kept/inProgress/broken/notStarted), evidenceLinks, communityVotes
- `PerformanceScore` — responsiveness, presence, development, aggregateScore
- `DevelopmentProject` — id, name, budget, contractor, timeline, progressPercent, photos

### Service Layer
```dart
Dio get _dio => AuthenticatedDio.instance;
```
| Method | Verb | Endpoint | Return |
|--------|------|----------|--------|
| `getCouncillor(wardId)` | GET | `/api/barozi/councillor/{wardId}` | `SingleResult<Councillor>` |
| `reportIssue(data)` | POST | `/api/barozi/issues` | `SingleResult<WardIssue>` |
| `getIssues(wardId, filters)` | GET | `/api/barozi/issues` | `PaginatedResult<WardIssue>` |
| `updateIssueStatus(id, status)` | PUT | `/api/barozi/issues/{id}/status` | `SingleResult<WardIssue>` |
| `getPromises(councillorId)` | GET | `/api/barozi/promises` | `PaginatedResult<CampaignPromise>` |
| `rateCouncillor(id, scores)` | POST | `/api/barozi/councillors/{id}/rate` | `SingleResult<PerformanceScore>` |
| `getProjects(wardId)` | GET | `/api/barozi/projects` | `PaginatedResult<DevelopmentProject>` |
| `createPetition(data)` | POST | `/api/barozi/petitions` | `SingleResult<Petition>` |

### Pages
- **WardHomePage** — Map-based ward finder, councillor card overlay, recent notices
- **CouncillorProfilePage** — Bio, scorecard, contact, activity feed
- **IssueReportPage** — Photo capture, GPS pin, category picker, description
- **IssueTrackerPage** — List/map of issues with status filters and timeline
- **PromiseTrackerPage** — Promise list with community verification voting
- **WardForumPage** — Threaded discussions via GroupService integration
- **DevelopmentProjectsPage** — Project cards with budget, timeline, progress bar

### Widgets
- `CouncillorCard` — Photo, name, party, ward, quick-contact actions
- `IssueStatusTimeline` — Vertical stepper: Submitted > Acknowledged > In Progress > Resolved
- `PromiseStatusBadge` — Color-coded badge (green/yellow/red/grey)
- `ScorecardWidget` — Radar chart for responsiveness, presence, development

---

## 2. UI Design
- Palette: #1A1A1A / #666666 / #FAFAFA / #FFFFFF
- Cards: BorderRadius.circular(12-16), subtle shadow
- 48dp touch targets, maxLines+ellipsis, _rounded icons
- Loading: CircularProgressIndicator(strokeWidth: 2, color: _kPrimary)

### Main Screen Wireframe
```
┌─────────────────────────┐
│ ◀  Barozi Wangu    🔔  │
├─────────────────────────┤
│ ┌─────────────────────┐ │
│ │   [Ward Map View]   │ │
│ │   📍 Kata: Mikocheni│ │
│ └─────────────────────┘ │
│ ┌─────────────────────┐ │
│ │ 👤 Cllr. J. Mushi   │ │
│ │ CCM · Term: 2025-30 │ │
│ │ ⭐ 4.2  [Message]   │ │
│ └─────────────────────┘ │
│ [Report Issue] [Promises]│
│ [Projects]  [Forum]     │
│                         │
│ Recent Issues           │
│ ├─ 🔴 Broken road...   │
│ ├─ 🟡 Water shortage.. │
│ └─ 🟢 Street light...  │
└─────────────────────────┘
```

---

## 3. Performance Strategy

### SQLite Local Storage
```sql
CREATE TABLE barozi_councillors(id INTEGER PRIMARY KEY, ward_id INTEGER, json_data TEXT, synced_at TEXT);
CREATE INDEX idx_barozi_councillors_ward ON barozi_councillors(ward_id);

CREATE TABLE barozi_issues(id INTEGER PRIMARY KEY, ward_id INTEGER, status TEXT, json_data TEXT, synced_at TEXT);
CREATE INDEX idx_barozi_issues_ward ON barozi_issues(ward_id);
```

### Caching
- Load from SQLite first (<5ms) then API background refresh
- TTL: Councillor data 24h, issues 5min, promises 1h
- Offline read: YES — councillor info, issues, promises cached
- Offline write: pending_queue for issue reports and ratings

---

## 4. Backend Implementation

### Database (PostgreSQL)
```sql
CREATE TABLE barozi_councillors (
    id BIGSERIAL PRIMARY KEY, user_id BIGINT REFERENCES users(id),
    ward_id BIGINT NOT NULL, party TEXT, term_start DATE, term_end DATE,
    bio TEXT, office_location TEXT, phone TEXT, email TEXT,
    created_at TIMESTAMP DEFAULT NOW(), updated_at TIMESTAMP DEFAULT NOW()
);

CREATE TABLE barozi_issues (
    id BIGSERIAL PRIMARY KEY, reporter_id BIGINT REFERENCES users(id),
    ward_id BIGINT NOT NULL, category TEXT NOT NULL, description TEXT,
    photo_urls JSONB, gps_lat DOUBLE PRECISION, gps_lng DOUBLE PRECISION,
    status TEXT DEFAULT 'submitted', priority TEXT DEFAULT 'medium',
    created_at TIMESTAMP DEFAULT NOW(), updated_at TIMESTAMP DEFAULT NOW()
);

CREATE TABLE barozi_promises (
    id BIGSERIAL PRIMARY KEY, councillor_id BIGINT REFERENCES barozi_councillors(id),
    description TEXT NOT NULL, status TEXT DEFAULT 'not_started',
    evidence_links JSONB, created_at TIMESTAMP DEFAULT NOW()
);
```

### API Endpoints
| Method | Endpoint | Description | Auth |
|--------|----------|-------------|------|
| GET | /api/barozi/councillor/{wardId} | Get councillor for ward | Yes |
| POST | /api/barozi/issues | Report ward issue | Yes |
| GET | /api/barozi/issues | List issues with filters | Yes |
| PUT | /api/barozi/issues/{id}/status | Update issue status | Yes |
| GET | /api/barozi/promises | List campaign promises | Yes |
| POST | /api/barozi/councillors/{id}/rate | Rate councillor | Yes |
| GET | /api/barozi/projects | List development projects | Yes |
| POST | /api/barozi/petitions | Create petition | Yes |

### Controller
- `app/Http/Controllers/Api/BaroziController.php`
- DB facade, try/catch, `{"success": true/false, "data": ..., "message": "..."}`

---

## 5. Integration Wiring
- **WalletService** — `deposit()` for ward development donations; `transfer()` for community contributions
- **MessageService** — `sendMessage()` for direct councillor chat; `createGroup()` for ward conversations
- **GroupService** — Auto-create ward forum group; resident directory via `getMembers()`
- **PostService** — Councillor announcements in local feed
- **NotificationService + FCMService** — Issue status changes, councillor responses, meeting alerts
- **LiveUpdateService** — Real-time issue status via Firestore
- **LocationService** — GPS-based ward detection and councillor assignment
- **PhotoService** — Issue report photo/video attachments
- **Cross-module: ofisi_mtaa** — Escalation from Mtaa to Ward Councillor
- **Cross-module: dc** — Escalation from ward to District Commissioner

---

## 6. Implementation Phases
### Phase 1: Foundation (Week 1)
- Data models, service layer, SQLite schema, module scaffold
- Councillor lookup by ward API + frontend

### Phase 2: Core UI (Week 2)
- Ward home page with map, councillor profile, issue report form
- Issue tracker with status timeline, promise tracker

### Phase 3: Integration (Week 3)
- GroupService ward forum, MessageService councillor chat
- LiveUpdateService for real-time issue tracking, FCM push alerts

### Phase 4: Polish (Week 4)
- Performance scorecard with radar chart, petition system
- Development projects with budget visualization, offline support

---

## 7. External APIs & Integrations

| API | Provider | Purpose | Pricing | Integration Notes |
|-----|----------|---------|---------|-------------------|
| HDX Administrative Boundaries | UN OCHA | Ward/district/region boundary shapefiles (GeoJSON, KML) | Free | Download from data.humdata.org, render with flutter_map or google_maps_flutter |
| OpenStreetMap / Nominatim | OSM Foundation | Geocoding, reverse geocoding, ward-level mapping | Free (1 req/sec public) | Self-hostable; full Tanzania coverage via WikiProject Tanzania |
| Tanzania Open Data Portal | Government of Tanzania / eGA | Ward-level population data, government statistics | Free | CKAN API at opendata.go.tz for programmatic access |
| Tanzania Data Portal | Open Data for Africa / AfDB | Census, demographic, economic indicators by region | Free | REST API via Open Data for Africa platform |
| World Bank Open Data API | World Bank | Development indicators (governance, demographics) | Free, no auth | REST API, ~16,000 indicators, JSON/XML responses |
| M-Pesa API | Vodacom (via Selcom/AzamPay) | Payment for petition fees, donations to ward projects | Commission-based | Use AzamPay Dart SDK (pub.dev: azampaytanzania) for Flutter |
| Smile ID | Smile Identity | Councillor/citizen identity verification | Pay-per-verification | Pan-African KYC; docs.usesmileid.com |

### Integration Priority
1. **Immediate** — OpenStreetMap/Nominatim (free, self-hostable), HDX boundary data (free download), World Bank API (free, no auth), Tanzania Open Data Portal (free CKAN API)
2. **Short-term** — AzamPay for payment features (has Dart SDK), Smile ID for identity verification
3. **Partnership** — Tanzania Open Data Portal advanced datasets, NEC councillor data (no public API exists; must be maintained locally or scraped)
