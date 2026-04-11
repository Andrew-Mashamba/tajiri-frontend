# Car Insurance — Implementation Plan

## Overview

The Car Insurance module enables Tanzanian drivers to compare quotes from 10+ local insurance providers, purchase policies digitally, manage active policies, file claims with photo evidence, and track claim resolution -- all without visiting a broker's office. It supports TPO, TPFT, and comprehensive coverage types with M-Pesa payment, TIRA policy verification, installment options, and integration with the My Cars module for auto-populated vehicle details.

---

## 1. Frontend Architecture

### Directory Structure
```
lib/car_insurance/
├── car_insurance_module.dart          — Entry point & route registration
├── models/
│   ├── quote_models.dart              — InsuranceQuote, QuoteComparison
│   ├── policy_models.dart             — Policy, PolicyStatus, Coverage
│   └── claim_models.dart              — Claim, ClaimStatus, ClaimStep
├── services/
│   └── car_insurance_service.dart     — API service using AuthenticatedDio
├── pages/
│   ├── insurance_home_page.dart       — Active policies, renewal alerts
│   ├── get_quotes_page.dart           — Vehicle input, quote request
│   ├── quote_comparison_page.dart     — Side-by-side comparison grid
│   ├── policy_purchase_page.dart      — Checkout with payment
│   ├── policy_detail_page.dart        — Coverage, documents, claims
│   ├── file_claim_page.dart           — Step-by-step claim wizard
│   ├── claim_tracker_page.dart        — Status timeline
│   ├── documents_page.dart            — Policy documents by vehicle
│   ├── renewal_center_page.dart       — Expiring policies
│   └── insurance_education_page.dart  — Guides, FAQ, glossary
└── widgets/
    ├── quote_card_widget.dart         — Provider quote with price/coverage
    ├── policy_status_widget.dart      — Active/expiring/expired indicator
    ├── coverage_comparison_widget.dart — Side-by-side feature grid
    └── claim_timeline_widget.dart     — Step progress indicator
```

### Data Models
- **InsuranceQuote**: id, providerId, providerName, providerLogo, coverageType, premium, excess, inclusions[], exclusions[], addOns[], rating. `factory InsuranceQuote.fromJson()` with `_parseDouble`.
- **Policy**: id, vehicleId, providerId, providerName, policyNumber, coverageType, premium, startDate, endDate, daysUntilExpiry, status, documents[], noClaimsYears. `factory Policy.fromJson()`.
- **Claim**: id, policyId, type, description, photos[], policeReportRef, status, steps[], assessorId, settlementAmount, createdAt. `factory Claim.fromJson()`.

### Service Layer
- `getQuotes(Map vehicleData)` — POST `/api/car-insurance/quotes`
- `purchasePolicy(Map purchaseData)` — POST `/api/car-insurance/policies`
- `getPolicies()` — GET `/api/car-insurance/policies`
- `getPolicy(int id)` — GET `/api/car-insurance/policies/{id}`
- `renewPolicy(int id)` — POST `/api/car-insurance/policies/{id}/renew`
- `fileClaim(int policyId, Map claimData)` — POST `/api/car-insurance/claims`
- `getClaimStatus(int claimId)` — GET `/api/car-insurance/claims/{id}`
- `verifyPolicy(String policyNumber)` — GET `/api/car-insurance/verify/{policyNumber}`

### Pages & Screens
- **Insurance Home**: Active policy cards with countdown timers, renewal alerts banner, quick actions (get quotes, file claim).
- **Get Quotes**: Vehicle details form (auto-filled from My Cars), coverage type selector, submit for quotes.
- **Quote Comparison**: Horizontal scrollable cards with price, coverage matrix, sort/filter controls.
- **File Claim**: Multi-step wizard -- incident type, photos, police report, third-party details, witnesses.
- **Claim Tracker**: Timeline with steps (submitted, under review, assessed, approved, settled).

### Widgets
- `QuoteCardWidget` — Provider logo, premium amount, coverage type badge, key inclusions
- `PolicyStatusWidget` — Color-coded circle with days countdown
- `CoverageComparisonWidget` — Check/cross grid comparing features across providers
- `ClaimTimelineWidget` — Vertical stepper with status per step

---

## 2. UI Design

- Quote cards: White with provider logo header, premium in large bold text
- Comparison grid: Alternating row colors for readability
- Claim wizard: Stepper with numbered circles, current step highlighted
- Status colors: Green (active), Yellow (expiring <30d), Red (expired)

### Key Screen Mockup — Quote Comparison
```
┌─────────────────────────────┐
│  SafeArea                   │
│  Compare 4 Quotes           │
│  [Sort: Price ▼] [Filter]   │
│  ┌────────┐ ┌────────┐     │
│  │ NIC    │ │Jubilee │ ←→  │
│  │Compreh.│ │Compreh.│     │
│  │TZS 850K│ │TZS 920K│     │
│  │────────│ │────────│     │
│  │✓ Own   │ │✓ Own   │     │
│  │✓ Third │ │✓ Third │     │
│  │✓ Fire  │ │✓ Fire  │     │
│  │✗ Wind. │ │✓ Wind. │     │
│  │────────│ │────────│     │
│  │[Select]│ │[Select]│     │
│  └────────┘ └────────┘     │
└─────────────────────────────┘
```

---

## 3. Performance Strategy

### Local-First with SQLite
```dart
// Table: insurance_policies
// Columns: id INTEGER PRIMARY KEY, vehicle_id INTEGER, provider TEXT, status TEXT, expiry_date TEXT, json_data TEXT, synced_at TEXT
// Indexes: vehicle_id, status, expiry_date
```

### Stale-While-Revalidate
- Policies: cache TTL 1 hour
- Quotes: no cache (always fresh from providers)
- Claims: cache TTL 30 minutes
- Education content: cache TTL 7 days

### Offline Support
- Read: Active policies, claim history, education content
- Write: Claim drafts saved locally before submission
- Sync: Policy status refresh on reconnect

### Media Caching
- Provider logos: cached indefinitely
- Claim photos: cached locally until upload confirmed
- BlurHash for provider profile images

---

## 4. Backend Implementation

### Database Tables
```sql
CREATE TABLE insurance_policies (
    id BIGSERIAL PRIMARY KEY,
    user_id BIGINT REFERENCES users(id),
    vehicle_id BIGINT REFERENCES vehicles(id),
    provider_id INTEGER,
    provider_name VARCHAR(100),
    policy_number VARCHAR(50) UNIQUE,
    coverage_type VARCHAR(30),
    premium DECIMAL(12,2),
    excess_amount DECIMAL(12,2),
    start_date DATE,
    end_date DATE,
    status VARCHAR(20) DEFAULT 'active',
    no_claims_years INTEGER DEFAULT 0,
    created_at TIMESTAMP DEFAULT NOW(),
    updated_at TIMESTAMP DEFAULT NOW()
);

CREATE TABLE insurance_claims (
    id BIGSERIAL PRIMARY KEY,
    policy_id BIGINT REFERENCES insurance_policies(id),
    claim_type VARCHAR(50),
    description TEXT,
    photos JSONB DEFAULT '[]',
    police_report_ref VARCHAR(50),
    third_party_details JSONB,
    status VARCHAR(30) DEFAULT 'submitted',
    settlement_amount DECIMAL(12,2),
    created_at TIMESTAMP DEFAULT NOW(),
    updated_at TIMESTAMP DEFAULT NOW()
);
```

### API Endpoints
| Method | Endpoint | Description | Auth |
|--------|----------|-------------|------|
| POST | /api/car-insurance/quotes | Get quotes from providers | Yes |
| POST | /api/car-insurance/policies | Purchase policy | Yes |
| GET | /api/car-insurance/policies | List user policies | Yes |
| GET | /api/car-insurance/policies/{id} | Policy detail | Yes |
| POST | /api/car-insurance/policies/{id}/renew | Renew policy | Yes |
| POST | /api/car-insurance/claims | File a claim | Yes |
| GET | /api/car-insurance/claims/{id} | Claim status | Yes |
| GET | /api/car-insurance/verify/{number} | Verify policy via TIRA | Yes |

### Controller
- File: `app/Http/Controllers/Api/CarInsuranceController.php`
- Pattern: DB facade, try/catch, `{"success": true, "data": ...}` responses

### Background Jobs
- Renewal reminder notifications (60/30/14/7 days before expiry)
- Quote aggregation from provider APIs (async)
- Claim status polling from provider systems

---

## 5. Integration Wiring

- **Wallet**: Premium payments, installments, claim payouts deposited to wallet.
- **My Cars**: Auto-populate vehicle details for quotes. Insurance status on dashboard.
- **Service Garage**: Authorized repair shops for claims. Repair cost estimates.
- **TIRA**: Policy verification, licensed insurer directory, premium rate reference.
- **Messaging**: Claims assessor chat, quote clarification conversations.
- **Notifications**: Renewal reminders, claim status updates, purchase confirmation.
- **Ambulance**: Emergency coordination after accident with auto-trigger.

---

## 6. Implementation Phases

### Phase 1: Foundation (Week 1)
- [ ] Create directory structure and car_insurance_module.dart
- [ ] Quote, Policy, Claim models with fromJson/toJson
- [ ] CarInsuranceService with AuthenticatedDio
- [ ] Backend: migrations + policies CRUD + quotes endpoint
- [ ] SQLite table for policy cache

### Phase 2: Core UI (Week 2)
- [ ] Insurance Home with active policies
- [ ] Get Quotes form with My Cars integration
- [ ] Quote Comparison with side-by-side grid
- [ ] Policy Detail view
- [ ] File Claim wizard

### Phase 3: Integration (Week 3)
- [ ] Wire to WalletService for premium payments
- [ ] Wire to My Cars for vehicle data
- [ ] Wire to TIRA for policy verification
- [ ] Wire to NotificationService for renewal alerts

### Phase 4: Polish (Week 4)
- [ ] Offline policy viewing
- [ ] Claim photo upload with compression
- [ ] Insurance education content
- [ ] Empty states and error handling
- [ ] QR code policy verification
- [ ] No-claims bonus tracking

---

## 7. External APIs & Integrations

| API | Provider | Purpose | Pricing | Integration Notes |
|-----|----------|---------|---------|-------------------|
| [BimaSokoni](https://www.bimasokoni.co.tz/) | BimaSokoni | Insurance comparison marketplace for Tanzania | Partnership | First TZ insurance aggregator. Compare quotes from multiple insurers. Contact for API access |
| [TIRA Verification](https://www.tira.go.tz/) | Tanzania Insurance Regulatory Authority | Insurance policy verification | Government portal | Verify active policies online. No public REST API — web-based verification |
| [AfricaBima API](http://africabima.com/api.html) | AfricaBima | Insurance quotation, claims, policy management | B2B partnership | Digital insurance gateway. Integrated with IPRS, NTSA, M-Pesa. Supports quotations, claims processing |
| [Qover API](https://www.qover.com/api) | Qover | Embedded insurance (motor, travel, liability) | Per-policy fees | White-label embedded insurance. RESTful API for quote, bind, claim |
| [Bolttech API](https://bolttech.io/sales/embedded-insurance-api/) | Bolttech | Embedded insurance distribution platform | Per-policy fees | Insurance exchange connecting 200+ insurers. Motor insurance supported |
| [M-Pesa Open API](https://openapiportal.m-pesa.com) | Vodacom Tanzania | Premium payments, claims disbursement | Transaction fees | Dart SDK: `mpesa_sdk` on pub.dev |
| [AzamPay API](https://developers.azampay.co.tz/) | AzamPay (Bakhresa Group) | Payment gateway for insurance premiums | Transaction fees | Flutter SDK: `azampaytanzania` on pub.dev |
| [ClickPesa API](https://docs.clickpesa.com/) | ClickPesa | Unified payment collection for premiums | Transaction fees | Aggregates M-Pesa, Tigo Pesa, Airtel Money, HaloPesa |
| [Firebase Cloud Messaging](https://firebase.google.com/docs/cloud-messaging) | Google | Renewal reminders, claim status notifications | Free | Already integrated in TAJIRI app |
