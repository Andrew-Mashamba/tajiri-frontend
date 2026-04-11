# TIRA (Tanzania Insurance Regulatory Authority) — Implementation Plan

## Overview

The TIRA module provides Tanzanian consumers a digital interface to the insurance regulator. Its killer feature is real-time insurance policy verification -- scanning or entering a motor vehicle sticker number to check if it is genuine, active, or fake. It also covers a licensed insurers directory, broker/agent verification, complaint filing against insurers for claim denials or fraud, premium rate reference, product comparison across providers, fraud reporting, consumer education on insurance rights, and an insurer performance dashboard showing claim settlement ratios.

---

## 1. Frontend Architecture

### Directory Structure
```
lib/tira/
├── tira_module.dart                   — Entry point & route registration
├── models/
│   ├── policy_verify_models.dart      — PolicyVerification, VerifyStatus
│   ├── insurer_models.dart            — Insurer, InsurerProduct, Branch
│   ├── broker_models.dart             — Broker, BrokerLicence
│   ├── complaint_models.dart          — InsuranceComplaint, ComplaintType
│   └── rate_models.dart               — PremiumRate, ProductComparison
├── services/
│   └── tira_service.dart              — API service using AuthenticatedDio
├── pages/
│   ├── tira_home_page.dart            — Quick verify, find insurer, complain
│   ├── verify_policy_page.dart        — Input policy/sticker number
│   ├── insurers_directory_page.dart   — Searchable licensed companies
│   ├── broker_lookup_page.dart        — Search broker/agent licence
│   ├── complaint_form_page.dart       — Multi-step complaint wizard
│   ├── my_complaints_page.dart        — Complaints with status tracking
│   ├── insurance_guide_page.dart      — Educational content by type
│   └── compare_products_page.dart     — Side-by-side product comparison
└── widgets/
    ├── verify_result_widget.dart       — Genuine/fake/expired result card
    ├── insurer_card_widget.dart        — Logo, name, rating, products
    ├── broker_status_widget.dart       — Licensed/unlicensed indicator
    ├── complaint_timeline_widget.dart  — Status progression
    └── performance_chart_widget.dart   — Claim settlement ratio bars
```

### Data Models
- **PolicyVerification**: policyNumber, insurerName, vehiclePlate, status (genuine/fake/expired/not_found), coverageType, startDate, endDate, verifiedAt. `factory PolicyVerification.fromJson()`.
- **Insurer**: id, name, logo, type, branches[], products[], rating, complaintCount, claimSettlementRatio, financialStrength, contactInfo. `factory Insurer.fromJson()`.
- **Broker**: id, name, licenceNumber, licenceStatus (active/suspended/revoked), authorizedInsurers[], disciplinaryHistory[], contactInfo. `factory Broker.fromJson()`.
- **InsuranceComplaint**: id, userId, insurerName, policyNumber, claimRef, type (claim_denial/delay/mis_selling/fraud), description, documents[], status, resolution, referenceNumber, createdAt. `factory InsuranceComplaint.fromJson()`.
- **PremiumRate**: insuranceType, minRate, maxRate, factors[], effectiveDate. `factory PremiumRate.fromJson()`.

### Service Layer
- `verifyPolicy(String policyNumber, {String? insurerName})` — GET `/api/tira/verify`
- `getInsurers({String? search})` — GET `/api/tira/insurers`
- `getInsurer(int id)` — GET `/api/tira/insurers/{id}`
- `verifyBroker(String licenceOrName)` — GET `/api/tira/brokers/verify`
- `fileComplaint(Map data)` — POST `/api/tira/complaints`
- `getMyComplaints()` — GET `/api/tira/complaints`
- `getPremiumRates({String? insuranceType})` — GET `/api/tira/rates`
- `compareProducts(Map params)` — GET `/api/tira/compare`
- `reportFraud(Map data)` — POST `/api/tira/fraud-reports`
- `getEducationContent({String? category})` — GET `/api/tira/education`

### Pages & Screens
- **TIRA Home**: Three prominent action cards -- Verify Policy, Find Insurer, File Complaint. Recent fraud alerts banner.
- **Verify Policy**: Input field for policy/sticker number, scanner button, result card (genuine=green, fake=red, expired=yellow).
- **Insurers Directory**: Searchable list with logo, name, products, claim settlement ratio, branch count.
- **Broker Lookup**: Search by name or licence number, result shows licence status and authorized insurers.
- **Complaint Form**: Steps -- insurer, policy, claim ref, complaint type, description, evidence upload.
- **Compare Products**: Select insurance type, side-by-side comparison table across providers.

### Widgets
- `VerifyResultWidget` — Large status icon (checkmark/X/warning), policy details, color-coded background
- `InsurerCardWidget` — Logo, name, settlement ratio bar, product count
- `BrokerStatusWidget` — Green "Licensed" or red "Not Licensed" with licence details
- `ComplaintTimelineWidget` — Vertical steps: submitted > under review > resolved
- `PerformanceChartWidget` — Horizontal bars showing settlement ratio per insurer

---

## 2. UI Design

- Verification result: Full-width card with large status icon, green/red/yellow background
- Insurer directory: List with logos, sortable by settlement ratio
- Complaints: Step wizard with clear progress indicator
- Education: Card-based articles with category tabs

### Key Screen Mockup — Verify Policy
```
┌─────────────────────────────┐
│  SafeArea                   │
│  Verify Insurance Policy    │
│  ┌───────────────────────┐  │
│  │ Policy/Sticker Number │  │
│  │ [________________]    │  │
│  │ [📷 Scan] [Verify]   │  │
│  └───────────────────────┘  │
│  ┌───────────────────────┐  │
│  │  ✓ GENUINE            │  │
│  │  ─────────────────    │  │
│  │  Insurer: NIC         │  │
│  │  Type: Comprehensive  │  │
│  │  Vehicle: T-123-ABC   │  │
│  │  Expires: 15 Dec 2026 │  │
│  │  Status: Active       │  │
│  └───────────────────────┘  │
│  [Report Fake Policy]       │
└─────────────────────────────┘
```

---

## 3. Performance Strategy

### Local-First with SQLite
```dart
// Table: tira_insurers
// Columns: id INTEGER PRIMARY KEY, name TEXT, settlement_ratio REAL, json_data TEXT, synced_at TEXT
// Indexes: name
// Table: tira_complaints
// Columns: id INTEGER PRIMARY KEY, status TEXT, reference TEXT, json_data TEXT, synced_at TEXT
// Indexes: status
```

### Stale-While-Revalidate
- Insurers directory: cache TTL 7 days (rarely changes)
- Policy verification: always live (critical accuracy)
- Premium rates: cache TTL 30 days
- Complaints: cache TTL 30 minutes
- Education content: cache TTL 30 days

### Offline Support
- Read: Insurers directory, education content, premium rates, complaint history
- Write: Complaint drafts saved locally
- Sync: Policy verification requires connectivity (cannot cache verification results)

### Media Caching
- Insurer logos: cached indefinitely
- Complaint evidence photos: cached locally until upload confirmed
- Education illustrations: pre-cached

---

## 4. Backend Implementation

### Database Tables
```sql
CREATE TABLE tira_insurers (
    id BIGSERIAL PRIMARY KEY,
    name VARCHAR(255),
    logo_url TEXT,
    type VARCHAR(30),
    branches JSONB DEFAULT '[]',
    products JSONB DEFAULT '[]',
    claim_settlement_ratio DECIMAL(5,2),
    financial_strength VARCHAR(20),
    complaint_count INTEGER DEFAULT 0,
    contact_info JSONB,
    created_at TIMESTAMP DEFAULT NOW(),
    updated_at TIMESTAMP DEFAULT NOW()
);

CREATE TABLE tira_brokers (
    id BIGSERIAL PRIMARY KEY,
    name VARCHAR(255),
    licence_number VARCHAR(50),
    licence_status VARCHAR(20),
    authorized_insurers JSONB DEFAULT '[]',
    disciplinary_history JSONB DEFAULT '[]',
    contact_info JSONB,
    created_at TIMESTAMP DEFAULT NOW(),
    updated_at TIMESTAMP DEFAULT NOW()
);

CREATE TABLE tira_complaints (
    id BIGSERIAL PRIMARY KEY,
    user_id BIGINT REFERENCES users(id),
    insurer_name VARCHAR(255),
    policy_number VARCHAR(50),
    claim_reference VARCHAR(50),
    complaint_type VARCHAR(30),
    description TEXT,
    documents JSONB DEFAULT '[]',
    reference_number VARCHAR(20) UNIQUE,
    status VARCHAR(20) DEFAULT 'submitted',
    resolution TEXT,
    created_at TIMESTAMP DEFAULT NOW(),
    updated_at TIMESTAMP DEFAULT NOW()
);

CREATE TABLE tira_premium_rates (
    id BIGSERIAL PRIMARY KEY,
    insurance_type VARCHAR(50),
    min_rate DECIMAL(10,2),
    max_rate DECIMAL(10,2),
    factors JSONB DEFAULT '[]',
    effective_date DATE,
    created_at TIMESTAMP DEFAULT NOW()
);
```

### API Endpoints
| Method | Endpoint | Description | Auth |
|--------|----------|-------------|------|
| GET | /api/tira/verify | Verify policy | Yes |
| GET | /api/tira/insurers | Insurers directory | Yes |
| GET | /api/tira/insurers/{id} | Insurer detail | Yes |
| GET | /api/tira/brokers/verify | Verify broker | Yes |
| POST | /api/tira/complaints | File complaint | Yes |
| GET | /api/tira/complaints | My complaints | Yes |
| GET | /api/tira/rates | Premium rates | Yes |
| GET | /api/tira/compare | Compare products | Yes |
| POST | /api/tira/fraud-reports | Report fraud | Yes |
| GET | /api/tira/education | Education content | No |

### Controller
- File: `app/Http/Controllers/Api/TiraController.php`
- Pattern: DB facade, try/catch, `{"success": true, "data": ...}` responses
- Policy verification: Requires MOU with TIRA for database access

### Background Jobs
- Insurer directory sync from TIRA portal (weekly)
- Premium rate update (quarterly)
- Complaint status polling
- Fraud alert broadcasting

---

## 5. Integration Wiring

- **Car Insurance**: Policy verification from quote/purchase flow. Licensed insurer powers provider selection. Premium rate reference for pricing validation. Fraud reporting from claims.
- **My Cars**: Auto-verify vehicle insurance when adding car. Status on vehicle dashboard.
- **Wallet**: Premium payments, complaint filing fees.
- **Notifications**: Policy expiry reminders, complaint updates, fraud alerts.
- **Messaging**: Complaint resolution correspondence, broker communication.
- **Groups**: Insurance discussion groups, provider reviews, consumer rights.
- **Ambulance**: Insurance verification during emergency dispatch.
- **Profile**: Licensed broker badge, consumer literacy badges.

---

## 6. Implementation Phases

### Phase 1: Foundation (Week 1)
- [ ] Create directory structure and tira_module.dart
- [ ] PolicyVerification, Insurer, Broker, Complaint models
- [ ] TiraService with AuthenticatedDio
- [ ] Backend: migrations + verify, insurers, complaints endpoints
- [ ] SQLite tables for insurers and complaints

### Phase 2: Core UI (Week 2)
- [ ] TIRA Home with action cards
- [ ] Verify Policy with scan and result display
- [ ] Insurers Directory with search
- [ ] Broker Lookup with status display
- [ ] Complaint Form wizard

### Phase 3: Integration (Week 3)
- [ ] Wire to Car Insurance for verification integration
- [ ] Wire to My Cars for vehicle insurance check
- [ ] Wire to NotificationService for alerts
- [ ] Wire to MessageService for complaint correspondence

### Phase 4: Polish (Week 4)
- [ ] Compare Products side-by-side view
- [ ] Insurance Guide educational content
- [ ] Insurer Performance Dashboard
- [ ] Fraud reporting flow
- [ ] Offline insurers directory
- [ ] Camera-based sticker scanner

---

## 7. External APIs & Integrations

| API | Provider | Purpose | Pricing | Integration Notes |
|-----|----------|---------|---------|-------------------|
| [TIRA Verification](https://www.tira.go.tz/) | Tanzania Insurance Regulatory Authority | Insurance policy verification, insurer registry | Government portal | Verify active policies online. No public REST API — web-based verification |
| [BimaSokoni](https://www.bimasokoni.co.tz/) | BimaSokoni | Insurance comparison marketplace for Tanzania | Partnership | First TZ insurance aggregator. Contact for API access |
| [AfricaBima API](http://africabima.com/api.html) | AfricaBima | Insurance quotation, claims, policy management | B2B partnership | Digital insurance gateway. Supports quotations, claims processing, payments |
| [Qover API](https://www.qover.com/api) | Qover | Embedded insurance (motor, travel, liability) | Per-policy fees | White-label embedded insurance. RESTful API for quote, bind, claim |
| [Bolttech API](https://bolttech.io/sales/embedded-insurance-api/) | Bolttech | Embedded insurance distribution platform | Per-policy fees | Insurance exchange connecting 200+ insurers |
| [M-Pesa Open API](https://openapiportal.m-pesa.com) | Vodacom Tanzania | Insurance premium payments | Transaction fees | Dart SDK: `mpesa_sdk` on pub.dev |
| [AzamPay API](https://developers.azampay.co.tz/) | AzamPay (Bakhresa Group) | Payment gateway for insurance premiums | Transaction fees | Flutter SDK: `azampaytanzania` on pub.dev |
| [Africa's Talking](https://developers.africastalking.com/) | Africa's Talking | SMS notifications for policy expiry, claims | Pay-as-you-go | Supports all 3 major TZ telcos |
| [Firebase Cloud Messaging](https://firebase.google.com/docs/cloud-messaging) | Google | Policy renewal reminders, fraud alerts | Free | Already integrated in TAJIRI app |
