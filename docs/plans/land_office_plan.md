# Ardhi (Land/Property Services) — Implementation Plan

## Overview
Land registry and property services module for Tanzania's Ministry of Lands. Provides title/plot search and verification, ownership history, interactive plot maps, land purchase safety checklist, transfer of ownership guide, fee calculator, surveyor/lawyer directory, fraud alert system, village land (CCRO) guide, women's land rights section, dispute resolution guide, and land office finder.

---

## 1. Frontend Architecture

### Directory Structure
```
lib/land_office/
├── land_office_module.dart
├── models/
│   ├── plot_models.dart
│   ├── transfer_models.dart
│   └── professional_models.dart
├── services/
│   └── land_office_service.dart
├── pages/
│   ├── land_home_page.dart
│   ├── plot_search_page.dart
│   ├── title_verification_page.dart
│   ├── plot_map_page.dart
│   ├── purchase_guide_page.dart
│   ├── transfer_guide_page.dart
│   ├── fee_calculator_page.dart
│   ├── professional_directory_page.dart
│   ├── fraud_alerts_page.dart
│   ├── land_laws_page.dart
│   ├── womens_rights_page.dart
│   ├── dispute_guide_page.dart
│   └── office_finder_page.dart
└── widgets/
    ├── plot_card.dart
    ├── ownership_timeline.dart
    ├── verification_badge.dart
    ├── fraud_alert_banner.dart
    └── fee_breakdown.dart
```

### Data Models
- `Plot` — id, plotNumber, location (region/district/ward), registeredOwner, titleType (granted/deemed/ccro), encumbrances, area, zoning, status
- `TitleDeed` — id, plotId, certificateNumber, ownerName, issueDate, titleType, qrCode, verified
- `OwnershipTransfer` — id, plotId, fromOwner, toOwner, transferDate, type (sale/inheritance/gift), documents
- `FraudAlert` — id, plotNumber, location, alertType, description, reportedAt, status
- `Surveyor` — id, name, licenceNumber, location, rating, feeRange, phone, specialization
- `LandApplication` — id, userId, type (title/transfer/subdivision/changeOfUse), plotId, status, trackingNumber

### Service Layer
```dart
Dio get _dio => AuthenticatedDio.instance;
```
| Method | Verb | Endpoint | Return |
|--------|------|----------|--------|
| `searchPlot(plotNumber, location)` | GET | `/api/land/search` | `PaginatedResult<Plot>` |
| `verifyTitle(certificateNo)` | GET | `/api/land/verify` | `SingleResult<TitleDeed>` |
| `getOwnershipHistory(plotId)` | GET | `/api/land/plots/{id}/history` | `PaginatedResult<OwnershipTransfer>` |
| `calculateFees(transactionType, value)` | GET | `/api/land/fees` | `SingleResult<FeeBreakdown>` |
| `getSurveyors(districtId)` | GET | `/api/land/surveyors` | `PaginatedResult<Surveyor>` |
| `getLawyers(districtId)` | GET | `/api/land/lawyers` | `PaginatedResult<Lawyer>` |
| `getFraudAlerts(districtId)` | GET | `/api/land/fraud-alerts` | `PaginatedResult<FraudAlert>` |
| `reportFraud(data)` | POST | `/api/land/fraud-alerts` | `SingleResult<FraudAlert>` |
| `trackApplication(trackingNo)` | GET | `/api/land/applications/{no}` | `SingleResult<LandApplication>` |
| `getOffices(districtId)` | GET | `/api/land/offices` | `PaginatedResult<Office>` |
| `submitComplaint(data)` | POST | `/api/land/complaints` | `SingleResult<Complaint>` |

### Pages
- **LandHomePage** — Search bar, quick verification, recent searches, fraud alerts banner
- **PlotSearchPage** — Plot number/location input, results with owner and map view
- **TitleVerificationPage** — Certificate number input, verification result display
- **PlotMapPage** — Interactive map with plot boundaries, ownership indicators
- **PurchaseGuidePage** — Step-by-step wizard with checklist and red flags
- **TransferGuidePage** — Complete process: documents, offices, fees, timeline
- **FeeCalculatorPage** — Transaction details input, itemized fees
- **ProfessionalDirectoryPage** — Surveyors and lawyers with map/list, filters
- **FraudAlertsPage** — Active alerts by area, report fraud form
- **WomensRightsPage** — Information cards, legal protections, where to get help
- **DisputeGuidePage** — Decision tree for choosing resolution forum

### Widgets
- `PlotCard` — Plot number, location, owner, title type, area
- `OwnershipTimeline` — Vertical timeline of ownership transfers
- `VerificationBadge` — Green (verified), red (unverified/flagged), yellow (pending)
- `FraudAlertBanner` — Red banner with alert count and view action

---

## 2. UI Design
- Palette: #1A1A1A / #666666 / #FAFAFA / #FFFFFF
- Cards: BorderRadius.circular(12-16), subtle shadow
- 48dp touch targets, maxLines+ellipsis, _rounded icons
- Loading: CircularProgressIndicator(strokeWidth: 2, color: _kPrimary)

### Main Screen Wireframe
```
┌─────────────────────────┐
│ ◀  Land Services    🔔  │
├─────────────────────────┤
│ ⚠ 3 Fraud Alerts Nearby│
├─────────────────────────┤
│ Search Plot / Title     │
│ ┌─────────────────────┐ │
│ │ Plot No. or Cert No.│ │
│ │ [Search] [Verify]   │ │
│ └─────────────────────┘ │
│                         │
│ [Purchase Guide]        │
│ [Transfer Guide]        │
│ [Fee Calculator]        │
│                         │
│ Find Professionals      │
│ ├─ Licensed Surveyors  │
│ └─ Land Lawyers        │
│                         │
│ Resources               │
│ ├─ Women's Land Rights │
│ ├─ Village Land (CCRO) │
│ ├─ Dispute Resolution  │
│ ├─ Land Laws Reference │
│ └─ Find Land Office    │
└─────────────────────────┘
```

---

## 3. Performance Strategy

### SQLite Local Storage
```sql
CREATE TABLE land_searches(id INTEGER PRIMARY KEY, plot_number TEXT, json_data TEXT, synced_at TEXT);
CREATE INDEX idx_land_searches_plot ON land_searches(plot_number);
CREATE TABLE land_fraud_alerts(id INTEGER PRIMARY KEY, district_id INTEGER, json_data TEXT, synced_at TEXT);
CREATE TABLE land_guides(id INTEGER PRIMARY KEY, type TEXT, json_data TEXT, synced_at TEXT);
```

### Caching
- Load from SQLite first (<5ms) then API background refresh
- TTL: Plot searches 1h, fraud alerts 15min, guides 7d, professional directory 24h
- Offline read: YES — purchase guide, land laws, fee calculator, women's rights
- Offline write: pending_queue for fraud reports and complaints

---

## 4. Backend Implementation

### Database (PostgreSQL)
```sql
CREATE TABLE land_plots (
    id BIGSERIAL PRIMARY KEY, plot_number TEXT UNIQUE NOT NULL,
    region_id BIGINT, district_id BIGINT, ward_id BIGINT,
    registered_owner TEXT, title_type TEXT, area_sqm DOUBLE PRECISION,
    zoning TEXT, encumbrances JSONB, status TEXT DEFAULT 'active',
    created_at TIMESTAMP DEFAULT NOW(), updated_at TIMESTAMP DEFAULT NOW()
);

CREATE TABLE land_titles (
    id BIGSERIAL PRIMARY KEY, plot_id BIGINT REFERENCES land_plots(id),
    certificate_number TEXT UNIQUE, owner_name TEXT, issue_date DATE,
    title_type TEXT, qr_code TEXT, verified BOOLEAN DEFAULT false,
    created_at TIMESTAMP DEFAULT NOW()
);

CREATE TABLE land_fraud_alerts (
    id BIGSERIAL PRIMARY KEY, reporter_id BIGINT REFERENCES users(id),
    plot_number TEXT, district_id BIGINT, alert_type TEXT,
    description TEXT, status TEXT DEFAULT 'active',
    created_at TIMESTAMP DEFAULT NOW()
);
```

### API Endpoints
| Method | Endpoint | Description | Auth |
|--------|----------|-------------|------|
| GET | /api/land/search | Search plots | Yes |
| GET | /api/land/verify | Verify title | Yes |
| GET | /api/land/plots/{id}/history | Ownership history | Yes |
| GET | /api/land/fees | Fee calculator | No |
| GET | /api/land/surveyors | Surveyor directory | Yes |
| GET | /api/land/lawyers | Land lawyers | Yes |
| GET | /api/land/fraud-alerts | Fraud alerts | Yes |
| POST | /api/land/fraud-alerts | Report fraud | Yes |
| GET | /api/land/applications/{no} | Track application | Yes |
| GET | /api/land/offices | Land offices | Yes |
| POST | /api/land/complaints | Submit complaint | Yes |

### Controller
- `app/Http/Controllers/Api/LandOfficeController.php`
- DB facade, try/catch, `{"success": true/false, "data": ..., "message": "..."}`

---

## 5. Integration Wiring
- **WalletService** — Stamp duty (1%+1%), registration/survey/valuation fees
- **MessageService** — Connect with surveyors and land lawyers
- **NotificationService + FCMService** — Application updates, fraud alerts, fee reminders
- **LiveUpdateService** — Real-time application tracking via Firestore
- **LocationService** — GPS plot identification, office/surveyor proximity
- **PhotoService** — Title deed scans, survey plans, beacon photos
- **CalendarService** — Application deadlines, court hearing dates
- **Cross-module: housing/** — Property listings linked to verified titles
- **Cross-module: legal_gpt** — Land law questions, dispute advice
- **Cross-module: tra** — Stamp duty + capital gains on transfers
- **Cross-module: nida** — Identity verification for ownership checks

---

## 6. Implementation Phases
### Phase 1: Foundation (Week 1)
- Data models, service layer, SQLite schema, module scaffold
- Plot search and title verification APIs

### Phase 2: Core UI (Week 2)
- Land home, plot search/verification, ownership history
- Purchase guide, transfer guide, fee calculator

### Phase 3: Integration (Week 3)
- Fraud alert system, professional directory with map
- WalletService payments, LiveUpdateService tracking

### Phase 4: Polish (Week 4)
- Plot map viewer, women's rights section, dispute guide
- Land laws reference, offline caching, complaint system

---

## 7. External APIs & Integrations

| API | Provider | Purpose | Pricing | Integration Notes |
|-----|----------|---------|---------|-------------------|
| ILMIS | Ministry of Lands (MLHHSD), Tanzania | Land title verification, cadastral management, CRO issuance | Institutional access | ilmis.lands.go.tz — PostgreSQL/GeoServer/QGIS, 6.5M documents, 80+ transaction types |
| OpenStreetMap / Nominatim | OSM Foundation | Geocoding, address lookup, land parcel mapping | Free (1 req/sec public) | Self-hostable; Ramani Huria project has detailed Dar es Salaam data |
| HDX Administrative Boundaries | UN OCHA | Ward/district/region boundary shapefiles | Free | data.humdata.org — GeoJSON, KML formats |
| Google Maps Platform | Google | Geocoding, mapping, satellite imagery for plot viewing | $200/mo free credit, then pay-per-use | Static Maps, Geocoding, Places APIs |
| Mapbox API | Mapbox | Custom maps, geocoding, satellite imagery | Free tier (50K map loads/mo) | docs.mapbox.com — good Africa coverage |
| AzamPay API | AzamPay | Mobile money payments for land fees | Per-transaction | Dart SDK on pub.dev (azampaytanzania) |
| GePG | Ministry of Finance, Tanzania | Government fee payments for land services | Institutional access | gepg.go.tz — integrated with ILMIS |
| Smile ID | Smile Identity | Owner identity verification for land transactions | Pay-per-verification | docs.usesmileid.com |

### Integration Priority
1. **Immediate** — OpenStreetMap/Nominatim (free, self-hostable, Ramani Huria data), HDX boundaries (free), Mapbox (free tier 50K loads/mo)
2. **Short-term** — AzamPay for land fee payments (has Dart SDK), Google Maps Platform ($200 free credit), Smile ID for identity verification
3. **Partnership** — ILMIS direct integration (institutional access required; 80+ transaction types), GePG for government fee payments, NIDA for owner verification
