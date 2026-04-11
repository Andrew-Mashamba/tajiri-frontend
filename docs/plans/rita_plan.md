# RITA (Birth/Death/Marriage Certificates) — Implementation Plan

## Overview
Civil registration service module for RITA (Registration Insolvency and Trusteeship Agency). Enables citizens to apply for birth, death, and marriage certificates online, track application status, find RITA offices, calculate fees, manage family records, submit name corrections, and access registration guides — addressing Tanzania's 26% birth registration rate.

---

## 1. Frontend Architecture

### Directory Structure
```
lib/rita/
├── rita_module.dart
├── models/
│   ├── certificate_models.dart
│   └── registration_models.dart
├── services/
│   └── rita_service.dart
├── pages/
│   ├── rita_home_page.dart
│   ├── apply_certificate_page.dart
│   ├── track_application_page.dart
│   ├── document_checklist_page.dart
│   ├── office_finder_page.dart
│   ├── fee_calculator_page.dart
│   ├── family_records_page.dart
│   ├── registration_guides_page.dart
│   ├── corrections_page.dart
│   └── complaints_page.dart
└── widgets/
    ├── certificate_card.dart
    ├── application_timeline.dart
    ├── fee_breakdown.dart
    ├── family_member_card.dart
    └── guide_step.dart
```

### Data Models
- `CertificateApplication` — id, userId, type (birth/death/marriage), status (submitted/processing/printing/ready), details, documents, feeAmount, trackingNumber
- `Certificate` — id, type, certificateNumber, holderName, dateOfEvent, placeOfEvent, registrationDate, qrCode
- `FamilyRecord` — id, memberId, name, relationship, certificates (list), pendingApplications
- `RitaOffice` — id, name, type (headquarters/regional/district), address, phone, hours, services, lat, lng
- `RegistrationGuide` — id, type, steps (list of GuideStep), requiredDocs, fees, timeline

### Service Layer
```dart
Dio get _dio => AuthenticatedDio.instance;
```
| Method | Verb | Endpoint | Return |
|--------|------|----------|--------|
| `applyForCertificate(data)` | POST | `/api/rita/applications` | `SingleResult<CertificateApplication>` |
| `trackApplication(trackingNo)` | GET | `/api/rita/applications/{no}` | `SingleResult<CertificateApplication>` |
| `getMyApplications()` | GET | `/api/rita/applications/mine` | `PaginatedResult<CertificateApplication>` |
| `getChecklist(type)` | GET | `/api/rita/checklists/{type}` | `SingleResult<Checklist>` |
| `getOffices(districtId)` | GET | `/api/rita/offices` | `PaginatedResult<RitaOffice>` |
| `calculateFees(type, params)` | GET | `/api/rita/fees` | `SingleResult<FeeBreakdown>` |
| `getFamilyRecords()` | GET | `/api/rita/family` | `PaginatedResult<FamilyRecord>` |
| `verifyCertificate(certNo)` | GET | `/api/rita/verify` | `SingleResult<VerificationResult>` |
| `submitCorrection(data)` | POST | `/api/rita/corrections` | `SingleResult<CorrectionRequest>` |
| `submitComplaint(data)` | POST | `/api/rita/complaints` | `SingleResult<Complaint>` |

### Pages
- **RitaHomePage** — Quick actions (apply, track, find office), recent apps, family summary
- **ApplyCertificatePage** — Multi-step: type > details > documents > pay > confirm
- **TrackApplicationPage** — Status timeline with estimated dates and collection location
- **DocumentChecklistPage** — Interactive checklist per certificate type
- **OfficeFinderPage** — Map with RITA offices and District Registrars
- **FeeCalculatorPage** — Input parameters, itemized fees, proceed to payment
- **FamilyRecordsPage** — Cards per family member with certificate statuses
- **RegistrationGuidesPage** — Step-by-step guides with illustrations

### Widgets
- `CertificateCard` — Type icon, holder name, cert number, status badge
- `ApplicationTimeline` — Submitted > Processing > Printing > Ready
- `FeeBreakdown` — Itemized fee table with total
- `FamilyMemberCard` — Name, relationship, certificates list, pending items

---

## 2. UI Design
- Palette: #1A1A1A / #666666 / #FAFAFA / #FFFFFF
- Cards: BorderRadius.circular(12-16), subtle shadow
- 48dp touch targets, maxLines+ellipsis, _rounded icons
- Loading: CircularProgressIndicator(strokeWidth: 2, color: _kPrimary)

### Main Screen Wireframe
```
┌─────────────────────────┐
│ ◀  RITA Services    🔔  │
├─────────────────────────┤
│ [Apply] [Track] [Office]│
├─────────────────────────┤
│ Recent Applications     │
│ ┌─────────────────────┐ │
│ │ 📄 Birth Certificate│ │
│ │ John M. · Printing  │ │
│ │ Est: Apr 15, 2026   │ │
│ └─────────────────────┘ │
│                         │
│ Family Records          │
│ ├─ 👶 Baby M. - Birth ✓│
│ ├─ 👩 Wife  - Marriage ✓│
│ └─ 👴 Father - Death ⏳ │
│                         │
│ Quick Links             │
│ ├─ Late Birth Reg Guide│
│ ├─ Fee Calculator      │
│ ├─ Marriage Reg Guide  │
│ └─ Name Correction     │
└─────────────────────────┘
```

---

## 3. Performance Strategy

### SQLite Local Storage
```sql
CREATE TABLE rita_applications(id INTEGER PRIMARY KEY, user_id INTEGER, type TEXT, status TEXT, json_data TEXT, synced_at TEXT);
CREATE INDEX idx_rita_apps_user ON rita_applications(user_id);
CREATE TABLE rita_offices(id INTEGER PRIMARY KEY, district_id INTEGER, json_data TEXT, synced_at TEXT);
CREATE TABLE rita_guides(id INTEGER PRIMARY KEY, type TEXT, json_data TEXT, synced_at TEXT);
```

### Caching
- Load from SQLite first (<5ms) then API background refresh
- TTL: Office locations 24h, checklists 7d, guides 7d, fees 7d
- Offline read: YES — checklists, guides, fee schedules, office locations
- Offline write: pending_queue for applications and corrections

---

## 4. Backend Implementation

### Database (PostgreSQL)
```sql
CREATE TABLE rita_applications (
    id BIGSERIAL PRIMARY KEY, user_id BIGINT REFERENCES users(id),
    type TEXT NOT NULL, status TEXT DEFAULT 'submitted',
    details JSONB, documents JSONB, fee_amount DECIMAL(10,2),
    tracking_number TEXT UNIQUE, collection_office_id BIGINT,
    created_at TIMESTAMP DEFAULT NOW(), updated_at TIMESTAMP DEFAULT NOW()
);

CREATE TABLE rita_certificates (
    id BIGSERIAL PRIMARY KEY, application_id BIGINT REFERENCES rita_applications(id),
    type TEXT NOT NULL, certificate_number TEXT UNIQUE,
    holder_name TEXT, date_of_event DATE, place_of_event TEXT,
    registration_date DATE, qr_code TEXT,
    created_at TIMESTAMP DEFAULT NOW()
);

CREATE TABLE rita_offices (
    id BIGSERIAL PRIMARY KEY, name TEXT NOT NULL, type TEXT,
    district_id BIGINT, address TEXT, phone TEXT, hours TEXT,
    services JSONB, lat DOUBLE PRECISION, lng DOUBLE PRECISION,
    created_at TIMESTAMP DEFAULT NOW()
);
```

### API Endpoints
| Method | Endpoint | Description | Auth |
|--------|----------|-------------|------|
| POST | /api/rita/applications | Apply for certificate | Yes |
| GET | /api/rita/applications/{no} | Track by tracking number | Yes |
| GET | /api/rita/applications/mine | My applications | Yes |
| GET | /api/rita/checklists/{type} | Document checklist | No |
| GET | /api/rita/offices | Find offices | Yes |
| GET | /api/rita/fees | Calculate fees | No |
| GET | /api/rita/family | Family records | Yes |
| GET | /api/rita/verify | Verify certificate | Yes |
| POST | /api/rita/corrections | Submit correction | Yes |
| POST | /api/rita/complaints | Submit complaint | Yes |

### Controller
- `app/Http/Controllers/Api/RitaController.php`
- DB facade, try/catch, `{"success": true/false, "data": ..., "message": "..."}`

---

## 5. Integration Wiring
- **WalletService** — Certificate fees (TZS 3,500-5,000) via M-Pesa
- **NotificationService + FCMService** — Application status updates, 90-day birth deadline reminders
- **LocationService** — GPS-based nearest RITA office finder
- **PhotoService** — Document uploads (affidavits, witness statements, existing certs)
- **CalendarService** — 90-day birth registration deadline, appointment dates
- **LiveUpdateService** — Real-time application status via Firestore
- **FriendService** — Family record tracking for spouse and children
- **Cross-module: nida** — Birth cert required for NIDA; cross-check status
- **Cross-module: passport** — Birth cert required for passport application

---

## 6. Implementation Phases
### Phase 1: Foundation (Week 1)
- Data models, service layer, SQLite schema, module scaffold
- Application submission and tracking APIs

### Phase 2: Core UI (Week 2)
- Apply wizard (multi-step), tracking timeline, office finder map
- Document checklists, fee calculator

### Phase 3: Integration (Week 3)
- WalletService payments, FCM status notifications
- Family records dashboard, certificate verification

### Phase 4: Polish (Week 4)
- Registration guides with illustrations, name correction flow
- Offline support for checklists and guides, complaint system

---

## 7. External APIs & Integrations

| API | Provider | Purpose | Pricing | Integration Notes |
|-----|----------|---------|---------|-------------------|
| eRITA Online Services | RITA (Registration Insolvency and Trusteeship Agency) | Birth/death certificate application, verification | Government fees apply | erita.rita.go.tz — web portal only, no public REST API |
| GePG | Ministry of Finance, Tanzania | Payment for RITA certificate fees via control numbers | Institutional access | Integrated with eRITA for fee collection via mobile money/bank |
| Smile ID | Smile Identity | Identity verification for certificate applicants | Pay-per-verification | docs.usesmileid.com — Pan-African KYC |
| AzamPay API | AzamPay | Mobile money payments for certificate fees | Per-transaction | Dart SDK on pub.dev (azampaytanzania) |
| ClickPesa BillPay API | ClickPesa | GePG control number generation for RITA fees | Contact for pricing | docs.clickpesa.com — automates control number workflows |
| NBS Data Portals | National Bureau of Statistics | Birth/death statistics for informational context | Free | nbs.go.tz/portals — demographic data |

### Integration Priority
1. **Immediate** — NBS portals for demographic context (free), AzamPay for fee payments (has Dart SDK)
2. **Short-term** — ClickPesa for GePG control number automation, Smile ID for applicant identity verification
3. **Partnership** — RITA direct integration (no public API; requires formal agreement), GePG institutional access for direct government payments
