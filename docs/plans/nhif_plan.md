# NHIF (Health Insurance) — Implementation Plan

## Overview
Health insurance management module for Tanzania's National Health Insurance Fund. Provides membership verification, digital member card with QR code, accredited facility finder with ratings, benefits guide, claims history, premium payment via M-Pesa, dependents management, drug formulary search, pre-authorization requests, coverage gap alerts, and iNHIF enrollment for informal sector workers.

---

## 1. Frontend Architecture

### Directory Structure
```
lib/nhif/
├── nhif_module.dart
├── models/
│   ├── membership_models.dart
│   ├── facility_models.dart
│   └── claim_models.dart
├── services/
│   └── nhif_service.dart
├── pages/
│   ├── nhif_home_page.dart
│   ├── member_card_page.dart
│   ├── facility_finder_page.dart
│   ├── benefits_page.dart
│   ├── claims_history_page.dart
│   ├── pay_premium_page.dart
│   ├── dependents_page.dart
│   ├── drug_list_page.dart
│   ├── complaints_page.dart
│   └── enrollment_page.dart
└── widgets/
    ├── member_card_widget.dart
    ├── facility_card.dart
    ├── benefit_tile.dart
    ├── claim_tile.dart
    ├── dependent_card.dart
    └── coverage_alert.dart
```

### Data Models
- `NhifMembership` — id, userId, memberNumber, status (active/lapsed/expired), validFrom, validTo, plan, employerName, contributionAmount
- `Dependent` — id, membershipId, name, relationship (spouse/child), dateOfBirth, nidaNumber, status
- `AccreditedFacility` — id, name, type (hospital/clinic/pharmacy/lab), services, address, phone, lat, lng, rating, nhifServices
- `Claim` — id, memberNumber, facilityId, facilityName, serviceDate, services, amount, status
- `Benefit` — id, category, name, description, limits, exclusions, preAuthRequired
- `Drug` — id, genericName, brandNames, classification, coverageLevel, restrictions

### Service Layer
```dart
Dio get _dio => AuthenticatedDio.instance;
```
| Method | Verb | Endpoint | Return |
|--------|------|----------|--------|
| `verifyMembership(memberOrNida)` | GET | `/api/nhif/verify` | `SingleResult<NhifMembership>` |
| `getDigitalCard()` | GET | `/api/nhif/card` | `SingleResult<DigitalCard>` |
| `findFacilities(location, type)` | GET | `/api/nhif/facilities` | `PaginatedResult<AccreditedFacility>` |
| `rateFacility(facilityId, data)` | POST | `/api/nhif/facilities/{id}/rate` | `SingleResult<Rating>` |
| `getBenefits(plan)` | GET | `/api/nhif/benefits` | `PaginatedResult<Benefit>` |
| `getClaimsHistory()` | GET | `/api/nhif/claims` | `PaginatedResult<Claim>` |
| `payPremium(data)` | POST | `/api/nhif/payments` | `SingleResult<Payment>` |
| `getContributionHistory()` | GET | `/api/nhif/contributions` | `PaginatedResult<Contribution>` |
| `manageDependents(action, data)` | POST | `/api/nhif/dependents` | `SingleResult<Dependent>` |
| `getDependents()` | GET | `/api/nhif/dependents` | `PaginatedResult<Dependent>` |
| `searchDrugs(query)` | GET | `/api/nhif/drugs` | `PaginatedResult<Drug>` |
| `submitComplaint(data)` | POST | `/api/nhif/complaints` | `SingleResult<Complaint>` |
| `enrollInhif(data)` | POST | `/api/nhif/enroll` | `SingleResult<Enrollment>` |

### Pages
- **NhifHomePage** — Digital card, coverage status, quick find facility, payment due alert
- **MemberCardPage** — Full-screen QR-enabled card with member and dependents
- **FacilityFinderPage** — Map with facilities, filters (type, specialty, distance)
- **BenefitsPage** — Categorized coverage guide with search
- **ClaimsHistoryPage** — Chronological claims with facility, service, amount
- **PayPremiumPage** — Balance, amount due, M-Pesa payment, receipt
- **DependentsPage** — Family member cards with add/edit/remove
- **DrugListPage** — Searchable formulary with coverage indicators
- **EnrollmentPage** — Package comparison, contribution calculator, sign-up

### Widgets
- `MemberCardWidget` — QR code, member number, name, plan, validity
- `FacilityCard` — Name, type, distance, rating, NHIF services indicator
- `BenefitTile` — Category icon, benefit name, limits, pre-auth badge
- `DependentCard` — Name, relationship, DOB, status badge
- `CoverageAlert` — Red banner when contributions late or coverage expiring

---

## 2. UI Design
- Palette: #1A1A1A / #666666 / #FAFAFA / #FFFFFF
- Cards: BorderRadius.circular(12-16), subtle shadow
- 48dp touch targets, maxLines+ellipsis, _rounded icons
- Loading: CircularProgressIndicator(strokeWidth: 2, color: _kPrimary)

### Main Screen Wireframe
```
┌─────────────────────────┐
│ ◀  NHIF Services    🔔  │
├─────────────────────────┤
│ ┌─────────────────────┐ │
│ │ NHIF Member Card    │ │
│ │ No: 12345678        │ │
│ │ Plan: iNHIF Premium │ │
│ │ Valid to: Dec 2026  │ │
│ │      [QR Code]      │ │
│ └─────────────────────┘ │
│                         │
│ ⚠ Payment Due: TZS 30K │
│ [Pay Now]               │
│                         │
│ [Find Hospital] [Benefits]│
│ [Claims]    [Dependents]│
│                         │
│ Dependents (3/5)        │
│ ├─ Spouse - Active ✓   │
│ ├─ Child 1 - Active ✓  │
│ └─ Child 2 - Active ✓  │
│                         │
│ [Drug List] [Complaints]│
└─────────────────────────┘
```

---

## 3. Performance Strategy

### SQLite Local Storage
```sql
CREATE TABLE nhif_facilities(id INTEGER PRIMARY KEY, type TEXT, district_id INTEGER, json_data TEXT, synced_at TEXT);
CREATE INDEX idx_nhif_facilities_type ON nhif_facilities(type);
CREATE TABLE nhif_claims(id INTEGER PRIMARY KEY, member_number TEXT, json_data TEXT, synced_at TEXT);
CREATE TABLE nhif_drugs(id INTEGER PRIMARY KEY, generic_name TEXT, json_data TEXT, synced_at TEXT);
CREATE TABLE nhif_benefits(id INTEGER PRIMARY KEY, category TEXT, json_data TEXT, synced_at TEXT);
```

### Caching
- Load from SQLite first (<5ms) then API background refresh
- TTL: Facilities 24h, benefits 7d, drugs 7d, claims 1h, membership 1h
- Offline read: YES — drug formulary, benefits guide, facility list, emergency contacts
- Offline write: pending_queue for complaints

---

## 4. Backend Implementation

### Database (PostgreSQL)
```sql
CREATE TABLE nhif_memberships (
    id BIGSERIAL PRIMARY KEY, user_id BIGINT REFERENCES users(id),
    member_number TEXT UNIQUE, status TEXT DEFAULT 'active',
    plan TEXT, employer_name TEXT, contribution_amount DECIMAL(10,2),
    valid_from DATE, valid_to DATE,
    created_at TIMESTAMP DEFAULT NOW(), updated_at TIMESTAMP DEFAULT NOW()
);

CREATE TABLE nhif_dependents (
    id BIGSERIAL PRIMARY KEY, membership_id BIGINT REFERENCES nhif_memberships(id),
    name TEXT NOT NULL, relationship TEXT, date_of_birth DATE,
    nida_number TEXT, status TEXT DEFAULT 'active',
    created_at TIMESTAMP DEFAULT NOW()
);

CREATE TABLE nhif_claims (
    id BIGSERIAL PRIMARY KEY, member_number TEXT NOT NULL,
    facility_id BIGINT, facility_name TEXT,
    service_date DATE, services JSONB, amount DECIMAL(10,2),
    status TEXT DEFAULT 'processed',
    created_at TIMESTAMP DEFAULT NOW()
);
```

### API Endpoints
| Method | Endpoint | Description | Auth |
|--------|----------|-------------|------|
| GET | /api/nhif/verify | Verify membership | Yes |
| GET | /api/nhif/card | Digital member card | Yes |
| GET | /api/nhif/facilities | Find facilities | Yes |
| POST | /api/nhif/facilities/{id}/rate | Rate facility | Yes |
| GET | /api/nhif/benefits | Benefits guide | No |
| GET | /api/nhif/claims | Claims history | Yes |
| POST | /api/nhif/payments | Pay premium | Yes |
| GET | /api/nhif/contributions | Contribution history | Yes |
| POST | /api/nhif/dependents | Manage dependents | Yes |
| GET | /api/nhif/dependents | List dependents | Yes |
| GET | /api/nhif/drugs | Drug formulary | No |
| POST | /api/nhif/complaints | Submit complaint | Yes |
| POST | /api/nhif/enroll | Enroll iNHIF | Yes |

### Controller
- `app/Http/Controllers/Api/NhifController.php`
- DB facade, try/catch, `{"success": true/false, "data": ..., "message": "..."}`

---

## 5. Integration Wiring
- **WalletService** — Monthly premium payments (TZS 30K-150K), auto-pay setup
- **MessageService** — Contact NHIF support and accredited facilities
- **NotificationService + FCMService** — Payment due, coverage expiry, claim updates, gap alerts
- **CalendarService** — Premium payment reminders, appointment dates
- **LocationService** — GPS-based nearest accredited facility finder
- **ProfileService** — Health insurance badge on TAJIRI profile
- **LiveUpdateService** — Real-time claim status and pre-authorization updates
- **FriendService** — Family dependents management
- **Cross-module: doctor/** — NHIF-accredited doctors in TAJIRI doctor finder
- **Cross-module: pharmacy/** — NHIF pharmacies with drug availability
- **Cross-module: nssf** — Combined social protection dashboard

---

## 6. Implementation Phases
### Phase 1: Foundation (Week 1)
- Data models, service layer, SQLite schema, module scaffold
- Membership verification, digital card with QR

### Phase 2: Core UI (Week 2)
- Facility finder with map, benefits guide, claims history
- Premium payment flow, contribution history

### Phase 3: Integration (Week 3)
- Dependents management, drug formulary search
- WalletService auto-pay, FCM coverage gap alerts

### Phase 4: Polish (Week 4)
- Facility ratings, pre-authorization flow, iNHIF enrollment
- Offline caching for drug list and benefits, complaint system

---

## 7. External APIs & Integrations

| API | Provider | Purpose | Pricing | Integration Notes |
|-----|----------|---------|---------|-------------------|
| NHIF Verification API | NHIF (National Health Insurance Fund) | Member card status, verification code validity, payment status | Institutional access | verification.nhif.or.tz — API for institutional partners (hospitals, universities) |
| NHIF Self-Service Portal | NHIF, Tanzania | Member registration, contribution checking, benefit status | Free for members | selfservice.nhif.or.tz — web portal |
| GePG | Ministry of Finance, Tanzania | NHIF contribution payments via control numbers | Institutional access | Government payment gateway |
| AzamPay API | AzamPay | Mobile money payments for NHIF contributions | Per-transaction | Dart SDK on pub.dev (azampaytanzania) |
| Selcom API | Selcom | Payment aggregation for NHIF contributions | Commission-based | developers.selcommobile.com — REST API |
| ClickPesa BillPay API | ClickPesa | GePG control number generation for NHIF payments | Contact for pricing | docs.clickpesa.com |
| Smile ID | Smile Identity | Member identity verification | Pay-per-verification | docs.usesmileid.com |

### Integration Priority
1. **Immediate** — AzamPay for contribution payments (has Dart SDK), Selcom API for payment processing
2. **Short-term** — ClickPesa for GePG control number automation, Smile ID for member identity verification
3. **Partnership** — NHIF Verification API (institutional partners only; requires formal agreement), GePG direct integration, NHIF data feeds for benefit/facility lookups
