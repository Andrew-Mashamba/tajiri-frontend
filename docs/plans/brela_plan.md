# BRELA (Business Registration) — Implementation Plan

## Overview
Business registration and compliance module for BRELA (Business Registrations and Licensing Agency). Provides company/business name search, name reservation, guided registration for sole proprietorships and companies, annual returns filing, compliance calendar, trademark management, certificate downloads, fee calculator, and company profile management.

---

## 1. Frontend Architecture

### Directory Structure
```
lib/brela/
├── brela_module.dart
├── models/
│   ├── company_models.dart
│   ├── trademark_models.dart
│   └── compliance_models.dart
├── services/
│   └── brela_service.dart
├── pages/
│   ├── brela_home_page.dart
│   ├── name_search_page.dart
│   ├── registration_wizard_page.dart
│   ├── my_businesses_page.dart
│   ├── business_detail_page.dart
│   ├── annual_returns_page.dart
│   ├── compliance_calendar_page.dart
│   ├── trademark_center_page.dart
│   ├── certificate_viewer_page.dart
│   └── fee_calculator_page.dart
└── widgets/
    ├── business_card.dart
    ├── compliance_indicator.dart
    ├── name_availability.dart
    ├── registration_step.dart
    └── trademark_status.dart
```

### Data Models
- `Business` — id, userId, name, type (soleProprietorship/partnership/privateLtd/publicLtd), registrationNumber, status, directors, shareholders, registeredOffice, filingHistory
- `NameSearch` — query, results (list of NameResult: name, available, registeredBy)
- `NameReservation` — id, name, reservedAt, expiresAt, status
- `AnnualReturn` — id, businessId, year, financialSummary, directorChanges, status, dueDate
- `Trademark` — id, name, logoUrl, classes, owner, status (applied/examination/publication/registered), applicationDate
- `ComplianceItem` — id, businessId, type, dueDate, status (upcoming/due/overdue/completed)

### Service Layer
```dart
Dio get _dio => AuthenticatedDio.instance;
```
| Method | Verb | Endpoint | Return |
|--------|------|----------|--------|
| `searchName(query)` | GET | `/api/brela/names/search` | `PaginatedResult<NameResult>` |
| `reserveName(name)` | POST | `/api/brela/names/reserve` | `SingleResult<NameReservation>` |
| `registerBusiness(data)` | POST | `/api/brela/register` | `SingleResult<Business>` |
| `getMyBusinesses()` | GET | `/api/brela/businesses/mine` | `PaginatedResult<Business>` |
| `getBusiness(id)` | GET | `/api/brela/businesses/{id}` | `SingleResult<Business>` |
| `fileAnnualReturns(businessId, data)` | POST | `/api/brela/returns` | `SingleResult<AnnualReturn>` |
| `getComplianceItems(businessId)` | GET | `/api/brela/compliance` | `PaginatedResult<ComplianceItem>` |
| `applyTrademark(data)` | POST | `/api/brela/trademarks` | `SingleResult<Trademark>` |
| `searchTrademarks(query)` | GET | `/api/brela/trademarks/search` | `PaginatedResult<Trademark>` |
| `getCertificate(businessId, type)` | GET | `/api/brela/certificates/{id}` | `SingleResult<Certificate>` |
| `calculateFees(type, params)` | GET | `/api/brela/fees` | `SingleResult<FeeBreakdown>` |

### Pages
- **BrelaHomePage** — Quick actions (search, register, file returns), my businesses, compliance alerts
- **NameSearchPage** — Real-time search with availability indicator, reserve button
- **RegistrationWizardPage** — Multi-step: type > name > directors > shareholders > docs > pay
- **MyBusinessesPage** — List of registered businesses with compliance badges
- **BusinessDetailPage** — Company profile, directors, shareholders, filings, certificates
- **AnnualReturnsPage** — Guided form with financial data, director updates, payment
- **ComplianceCalendarPage** — Timeline of deadlines with status indicators
- **TrademarkCenterPage** — Search, apply, track trademarks

### Widgets
- `BusinessCard` — Name, type, reg number, compliance badge
- `ComplianceIndicator` — Green/yellow/red dot with due date
- `NameAvailability` — Checkmark/cross with name and status text
- `RegistrationStep` — Step number, title, description, completion state

---

## 2. UI Design
- Palette: #1A1A1A / #666666 / #FAFAFA / #FFFFFF
- Cards: BorderRadius.circular(12-16), subtle shadow
- 48dp touch targets, maxLines+ellipsis, _rounded icons
- Loading: CircularProgressIndicator(strokeWidth: 2, color: _kPrimary)

### Main Screen Wireframe
```
┌─────────────────────────┐
│ ◀  BRELA Services   🔔  │
├─────────────────────────┤
│ [Name Search] [Register]│
├─────────────────────────┤
│ My Businesses           │
│ ┌─────────────────────┐ │
│ │ Tajiri Ltd · Pvt Ltd│ │
│ │ Reg: 12345  ● OK    │ │
│ │ Returns due: Jun 30 │ │
│ └─────────────────────┘ │
│ ┌─────────────────────┐ │
│ │ Juma Store · Sole   │ │
│ │ Reg: 67890  ● Due ⚠ │ │
│ └─────────────────────┘ │
│                         │
│ Compliance Calendar     │
│ ├─ 🔴 Returns Jun 30  │
│ ├─ 🟡 Trademark renew │
│ └─ 🟢 License valid ✓ │
│                         │
│ [Trademarks] [Fees]     │
│ [Templates] [Offices]   │
└─────────────────────────┘
```

---

## 3. Performance Strategy

### SQLite Local Storage
```sql
CREATE TABLE brela_businesses(id INTEGER PRIMARY KEY, user_id INTEGER, type TEXT, json_data TEXT, synced_at TEXT);
CREATE INDEX idx_brela_biz_user ON brela_businesses(user_id);
CREATE TABLE brela_compliance(id INTEGER PRIMARY KEY, business_id INTEGER, due_date TEXT, json_data TEXT, synced_at TEXT);
CREATE TABLE brela_templates(id INTEGER PRIMARY KEY, category TEXT, json_data TEXT, synced_at TEXT);
```

### Caching
- Load from SQLite first (<5ms) then API background refresh
- TTL: Business profiles 1h, compliance items 6h, templates 7d, fees 7d
- Offline read: YES — fee calculators, document templates, registration guides
- Offline write: pending_queue for registration drafts

---

## 4. Backend Implementation

### Database (PostgreSQL)
```sql
CREATE TABLE brela_businesses (
    id BIGSERIAL PRIMARY KEY, user_id BIGINT REFERENCES users(id),
    name TEXT NOT NULL, type TEXT NOT NULL, registration_number TEXT UNIQUE,
    status TEXT DEFAULT 'active', directors JSONB, shareholders JSONB,
    registered_office TEXT, filing_history JSONB,
    created_at TIMESTAMP DEFAULT NOW(), updated_at TIMESTAMP DEFAULT NOW()
);

CREATE TABLE brela_name_reservations (
    id BIGSERIAL PRIMARY KEY, user_id BIGINT REFERENCES users(id),
    name TEXT NOT NULL, reserved_at TIMESTAMP DEFAULT NOW(),
    expires_at TIMESTAMP, status TEXT DEFAULT 'active'
);

CREATE TABLE brela_trademarks (
    id BIGSERIAL PRIMARY KEY, user_id BIGINT REFERENCES users(id),
    name TEXT NOT NULL, logo_url TEXT, classes JSONB,
    status TEXT DEFAULT 'applied', application_date DATE,
    created_at TIMESTAMP DEFAULT NOW(), updated_at TIMESTAMP DEFAULT NOW()
);
```

### API Endpoints
| Method | Endpoint | Description | Auth |
|--------|----------|-------------|------|
| GET | /api/brela/names/search | Search name availability | Yes |
| POST | /api/brela/names/reserve | Reserve name (30 days) | Yes |
| POST | /api/brela/register | Register business | Yes |
| GET | /api/brela/businesses/mine | My businesses | Yes |
| GET | /api/brela/businesses/{id} | Business detail | Yes |
| POST | /api/brela/returns | File annual returns | Yes |
| GET | /api/brela/compliance | Compliance calendar | Yes |
| POST | /api/brela/trademarks | Apply for trademark | Yes |
| GET | /api/brela/trademarks/search | Search trademarks | Yes |
| GET | /api/brela/certificates/{id} | Download certificate | Yes |
| GET | /api/brela/fees | Fee calculator | No |

### Controller
- `app/Http/Controllers/Api/BrelaController.php`
- DB facade, try/catch, `{"success": true/false, "data": ..., "message": "..."}`

---

## 5. Integration Wiring
- **WalletService** — Registration fees, annual returns, name reservation, trademark fees
- **NotificationService + FCMService** — Annual returns deadlines, trademark milestones, name reservation expiry
- **CalendarService** — Filing deadlines synced to TAJIRI calendar
- **ProfileService** — Business verification badge for marketplace sellers
- **LiveUpdateService** — Real-time registration status via Firestore
- **ShopService** — Verified business badge in TAJIRI marketplace
- **Cross-module: tra** — Auto-prompt TIN after company registration
- **Cross-module: nida** — Director/shareholder NIDA verification
- **Cross-module: legal_gpt** — Company types, compliance, director liabilities guidance

---

## 6. Implementation Phases
### Phase 1: Foundation (Week 1)
- Data models, service layer, SQLite schema, module scaffold
- Name search and reservation APIs

### Phase 2: Core UI (Week 2)
- Registration wizard (multi-step), my businesses list
- Business detail page, annual returns form

### Phase 3: Integration (Week 3)
- WalletService payments, compliance calendar with FCM reminders
- Certificate download, LiveUpdateService tracking

### Phase 4: Polish (Week 4)
- Trademark center (search, apply, track), fee calculator
- Document templates, offline caching, BRELA office finder

---

## 7. External APIs & Integrations

| API | Provider | Purpose | Pricing | Integration Notes |
|-----|----------|---------|---------|-------------------|
| BRELA ORS | BRELA (Business Registrations and Licensing Agency) | Business name search, company registration, trademark | Government fees apply | ors.brela.go.tz — web portal, public search at orsreg/searchbusinesspublic |
| GePG | Ministry of Finance, Tanzania | Payment for BRELA registration fees | Institutional access | Integrated with BRELA ORS for control number payments |
| Tanzania Business Portal (TNBP) | Government of Tanzania | Business registration guidance and links | Free | business.go.tz/register-a-business |
| org-id.guide | Open Data Services | Tanzania business registration identifier lookup | Free | org-id.guide/list/TZ-BRLA — identifier scheme reference |
| Smile ID | Smile Identity | Director/shareholder identity verification | Pay-per-verification | docs.usesmileid.com — Pan-African KYC |
| AzamPay API | AzamPay | Mobile money payments for registration fees | Per-transaction | Dart SDK on pub.dev (azampaytanzania) |
| ClickPesa BillPay API | ClickPesa | GePG control number generation for BRELA fees | Contact for pricing | docs.clickpesa.com |
| NIDA Verification API | NIDA | Director identity verification via national ID | Institutional access | services.nida.go.tz — restricted; use Smile ID as intermediary |

### Integration Priority
1. **Immediate** — BRELA ORS public business name search (free, web-based), org-id.guide (free identifier lookup), Tanzania Business Portal (free guidance)
2. **Short-term** — AzamPay for fee payments (has Dart SDK), Smile ID for director identity verification, ClickPesa for GePG control numbers
3. **Partnership** — BRELA ORS direct API integration (no public REST API; requires formal agreement with BRELA), GePG institutional access, NIDA for national ID verification
