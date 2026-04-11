# NSSF (Social Security) — Implementation Plan

## Overview
Social security management module for Tanzania's National Social Security Fund. Provides contribution statement viewing, employer verification, projected pension calculator, benefits overview and claims, digital member card, nomination management, self-employment registration with M-Pesa payments, multi-fund consolidated view, retirement readiness score, investment performance visibility, and NSSF office finder.

---

## 1. Frontend Architecture

### Directory Structure
```
lib/nssf/
├── nssf_module.dart
├── models/
│   ├── contribution_models.dart
│   ├── benefit_models.dart
│   └── pension_models.dart
├── services/
│   └── nssf_service.dart
├── pages/
│   ├── nssf_home_page.dart
│   ├── contribution_history_page.dart
│   ├── retirement_calculator_page.dart
│   ├── benefits_guide_page.dart
│   ├── apply_benefit_page.dart
│   ├── claim_tracker_page.dart
│   ├── employer_check_page.dart
│   ├── nominations_page.dart
│   ├── self_employed_page.dart
│   └── office_finder_page.dart
└── widgets/
    ├── member_card.dart
    ├── contribution_chart.dart
    ├── pension_projection.dart
    ├── benefit_card.dart
    ├── nominee_card.dart
    └── readiness_gauge.dart
```

### Data Models
- `NssfMembership` — id, userId, memberNumber, totalContributions, monthsContributed, employerName, employerCompliant, registrationDate
- `Contribution` — id, memberNumber, month, year, employeeAmount, employerAmount, employerName, status
- `PensionProjection` — currentAge, retirementAge, totalContributions, projectedMonthly, projectedLump, assumptions
- `BenefitClaim` — id, memberNumber, benefitType (oldAge/invalidity/survivors/maternity/funeral/withdrawal), status (submitted/verification/approval/payment), documents, amount
- `Nominee` — id, memberNumber, name, relationship, percentage, idNumber, phone
- `EmployerCompliance` — employerName, tin, registered, contributing, lastContribution, monthsOwed

### Service Layer
```dart
Dio get _dio => AuthenticatedDio.instance;
```
| Method | Verb | Endpoint | Return |
|--------|------|----------|--------|
| `getMembership()` | GET | `/api/nssf/membership` | `SingleResult<NssfMembership>` |
| `getContributions(year)` | GET | `/api/nssf/contributions` | `PaginatedResult<Contribution>` |
| `calculatePension(params)` | POST | `/api/nssf/pension-calc` | `SingleResult<PensionProjection>` |
| `getBenefits()` | GET | `/api/nssf/benefits` | `PaginatedResult<BenefitInfo>` |
| `applyForBenefit(data)` | POST | `/api/nssf/claims` | `SingleResult<BenefitClaim>` |
| `trackClaim(claimId)` | GET | `/api/nssf/claims/{id}` | `SingleResult<BenefitClaim>` |
| `checkEmployer(nameOrTin)` | GET | `/api/nssf/employer-check` | `SingleResult<EmployerCompliance>` |
| `getNominees()` | GET | `/api/nssf/nominees` | `PaginatedResult<Nominee>` |
| `updateNominees(data)` | PUT | `/api/nssf/nominees` | `PaginatedResult<Nominee>` |
| `registerSelfEmployed(data)` | POST | `/api/nssf/self-employed` | `SingleResult<Registration>` |
| `payVoluntary(data)` | POST | `/api/nssf/payments` | `SingleResult<Payment>` |
| `getOffices(regionId)` | GET | `/api/nssf/offices` | `PaginatedResult<Office>` |

### Pages
- **NssfHomePage** — Member card, total contributions, projected pension, employer status
- **ContributionHistoryPage** — Monthly statement filterable by year/employer
- **RetirementCalculatorPage** — Sliders for age, salary growth, rate with projection graph
- **BenefitsGuidePage** — Cards per benefit type with eligibility and how-to-claim
- **ApplyBenefitPage** — Multi-step claim form with document upload
- **ClaimTrackerPage** — Status timeline with estimated processing dates
- **EmployerCheckPage** — Search employer, see registration and compliance
- **NominationsPage** — Nominee list with add/edit/remove and percentage allocation
- **SelfEmployedPage** — Registration, payment schedule, contribution history

### Widgets
- `MemberCard` — Member number, total contributions, months, employer
- `ContributionChart` — Monthly bar chart with employee/employer split
- `PensionProjection` — Line graph projecting pension growth to retirement
- `BenefitCard` — Benefit type, eligibility criteria, amount formula
- `NomineeCard` — Name, relationship, percentage, edit/remove actions
- `ReadinessGauge` — Circular gauge 0-100% retirement readiness

---

## 2. UI Design
- Palette: #1A1A1A / #666666 / #FAFAFA / #FFFFFF
- Cards: BorderRadius.circular(12-16), subtle shadow
- 48dp touch targets, maxLines+ellipsis, _rounded icons
- Loading: CircularProgressIndicator(strokeWidth: 2, color: _kPrimary)

### Main Screen Wireframe
```
┌─────────────────────────┐
│ ◀  NSSF Services    🔔  │
├─────────────────────────┤
│ ┌─────────────────────┐ │
│ │ NSSF Member 987654  │ │
│ │ Total: TZS 12.4M    │ │
│ │ Months: 96 / 180    │ │
│ │ Employer: ● Paying ✓│ │
│ └─────────────────────┘ │
│                         │
│ Retirement Readiness    │
│ ┌──────────┐            │
│ │   53%    │ On track   │
│ │  ◠◠◠◠◠   │ for TZS    │
│ │          │ 450K/month │
│ └──────────┘            │
│                         │
│ [Contributions] [Calc]  │
│ [Benefits]  [Nominees]  │
│                         │
│ Quick Links             │
│ ├─ Check Employer      │
│ ├─ Apply for Benefit   │
│ ├─ Self-Employed Portal│
│ └─ Find NSSF Office    │
└─────────────────────────┘
```

---

## 3. Performance Strategy

### SQLite Local Storage
```sql
CREATE TABLE nssf_contributions(id INTEGER PRIMARY KEY, member_number TEXT, year INTEGER, json_data TEXT, synced_at TEXT);
CREATE INDEX idx_nssf_contrib_member ON nssf_contributions(member_number);
CREATE TABLE nssf_nominees(id INTEGER PRIMARY KEY, member_number TEXT, json_data TEXT, synced_at TEXT);
CREATE TABLE nssf_benefits(id INTEGER PRIMARY KEY, type TEXT, json_data TEXT, synced_at TEXT);
```

### Caching
- Load from SQLite first (<5ms) then API background refresh
- TTL: Contributions 1h, membership 1h, benefits guide 7d, nominees 6h
- Offline read: YES — contribution statements, benefits guide, nomination forms
- Offline write: pending_queue for benefit claims, voluntary payments

---

## 4. Backend Implementation

### Database (PostgreSQL)
```sql
CREATE TABLE nssf_memberships (
    id BIGSERIAL PRIMARY KEY, user_id BIGINT REFERENCES users(id),
    member_number TEXT UNIQUE, employer_name TEXT,
    total_contributions DECIMAL(15,2) DEFAULT 0,
    months_contributed INTEGER DEFAULT 0,
    registration_date DATE,
    created_at TIMESTAMP DEFAULT NOW(), updated_at TIMESTAMP DEFAULT NOW()
);

CREATE TABLE nssf_contributions (
    id BIGSERIAL PRIMARY KEY, member_number TEXT NOT NULL,
    month INTEGER, year INTEGER,
    employee_amount DECIMAL(12,2), employer_amount DECIMAL(12,2),
    employer_name TEXT, status TEXT DEFAULT 'confirmed',
    created_at TIMESTAMP DEFAULT NOW()
);

CREATE TABLE nssf_nominees (
    id BIGSERIAL PRIMARY KEY, member_number TEXT NOT NULL,
    name TEXT NOT NULL, relationship TEXT, percentage DECIMAL(5,2),
    id_number TEXT, phone TEXT,
    created_at TIMESTAMP DEFAULT NOW(), updated_at TIMESTAMP DEFAULT NOW()
);

CREATE TABLE nssf_claims (
    id BIGSERIAL PRIMARY KEY, member_number TEXT NOT NULL,
    benefit_type TEXT NOT NULL, status TEXT DEFAULT 'submitted',
    documents JSONB, amount DECIMAL(15,2),
    created_at TIMESTAMP DEFAULT NOW(), updated_at TIMESTAMP DEFAULT NOW()
);
```

### API Endpoints
| Method | Endpoint | Description | Auth |
|--------|----------|-------------|------|
| GET | /api/nssf/membership | My membership | Yes |
| GET | /api/nssf/contributions | Contribution history | Yes |
| POST | /api/nssf/pension-calc | Pension projection | Yes |
| GET | /api/nssf/benefits | Benefits guide | No |
| POST | /api/nssf/claims | Apply for benefit | Yes |
| GET | /api/nssf/claims/{id} | Track claim | Yes |
| GET | /api/nssf/employer-check | Employer compliance | Yes |
| GET | /api/nssf/nominees | List nominees | Yes |
| PUT | /api/nssf/nominees | Update nominees | Yes |
| POST | /api/nssf/self-employed | Register self-employed | Yes |
| POST | /api/nssf/payments | Voluntary payment | Yes |
| GET | /api/nssf/offices | NSSF offices | Yes |

### Controller
- `app/Http/Controllers/Api/NssfController.php`
- DB facade, try/catch, `{"success": true/false, "data": ..., "message": "..."}`

---

## 5. Integration Wiring
- **WalletService** — Voluntary contributions (min TZS 20K/month) via M-Pesa
- **MessageService** — Contact NSSF support, claim communications
- **NotificationService + FCMService** — Contribution confirmations, claim status, 180-month milestone, employer alerts
- **CalendarService** — Contribution due dates, retirement countdown
- **ProfileService** — Social security status on TAJIRI profile
- **LiveUpdateService** — Real-time claim tracking via Firestore
- **FriendService** — Dependents/nominees linked to family module
- **Cross-module: nhif** — Combined social protection dashboard (health + pension)
- **Cross-module: my_wallet/** — Pension in overall financial planning
- **Cross-module: investments/** — NSSF fund performance alongside personal investments

---

## 6. Implementation Phases
### Phase 1: Foundation (Week 1)
- Data models, service layer, SQLite schema, module scaffold
- Membership display, contribution history API

### Phase 2: Core UI (Week 2)
- NSSF home with member card, contribution chart
- Retirement calculator with projection graph, benefits guide

### Phase 3: Integration (Week 3)
- Benefit claim submission and tracking, employer compliance check
- WalletService voluntary payments, FCM milestone notifications

### Phase 4: Polish (Week 4)
- Nomination management, self-employed portal
- Retirement readiness gauge, multi-fund view, office finder

---

## 7. External APIs & Integrations

| API | Provider | Purpose | Pricing | Integration Notes |
|-----|----------|---------|---------|-------------------|
| NSSF Portal | NSSF (National Social Security Fund) | Contribution tracking, account statements, claims | Free for members | portal.nssf.go.tz — "One Portal, One Account" |
| NSSF Mobile App | NSSF, Tanzania | Real-time contribution tracking, statements, claims | Free | Available on Google Play and App Store |
| NSSF SMS Service | NSSF, Tanzania | Balance checking via SMS | Free (standard SMS rates) | Send "REGISTER" + membership number to 15747, then "SALIO" for balance |
| AzamPay API | AzamPay | Mobile money payments for NSSF contributions | Per-transaction | Dart SDK on pub.dev (azampaytanzania) |
| Selcom API | Selcom | Payment aggregation for NSSF contributions | Commission-based | developers.selcommobile.com — REST API |
| ClickPesa BillPay API | ClickPesa | GePG control number generation for NSSF payments | Contact for pricing | docs.clickpesa.com |
| GePG | Ministry of Finance, Tanzania | Government payment gateway for NSSF contributions | Institutional access | gepg.go.tz |
| Smile ID | Smile Identity | Member/beneficiary identity verification | Pay-per-verification | docs.usesmileid.com |

### Integration Priority
1. **Immediate** — AzamPay for contribution payments (has Dart SDK), Selcom API for payment processing
2. **Short-term** — ClickPesa for GePG control number automation, Smile ID for member verification
3. **Partnership** — NSSF direct API integration (no public developer API; portal/app/SMS only; requires formal agreement), GePG institutional access
