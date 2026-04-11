# NIDA (National ID) — Implementation Plan

## Overview
NIDA service companion module for Tanzania's National Identification Authority. Provides application status tracking, NIDA office finder with queue estimates, document checklists, pre-registration form, appointment booking, NIDA number lookup, verification service, data correction requests, lost card reporting, mobile registration unit tracking, and family registration management.

---

## 1. Frontend Architecture

### Directory Structure
```
lib/nida/
├── nida_module.dart
├── models/
│   ├── nida_models.dart
│   └── office_models.dart
├── services/
│   └── nida_service.dart
├── pages/
│   ├── nida_home_page.dart
│   ├── status_tracker_page.dart
│   ├── office_finder_page.dart
│   ├── document_checklist_page.dart
│   ├── pre_registration_page.dart
│   ├── appointment_page.dart
│   ├── digital_id_page.dart
│   ├── correction_request_page.dart
│   ├── complaint_page.dart
│   └── help_center_page.dart
└── widgets/
    ├── status_timeline.dart
    ├── office_card.dart
    ├── checklist_item.dart
    ├── id_card_preview.dart
    └── queue_indicator.dart
```

### Data Models
- `NidaApplication` — id, userId, receiptNumber, nidaNumber, status (registered/biometrics/printing/atOffice/collected), currentStage, estimatedDate
- `NidaOffice` — id, name, districtId, address, phone, hours, services, queueEstimate, lat, lng
- `MobileUnit` — id, location, schedule (list of ScheduleEntry), currentLat, currentLng
- `CorrectionRequest` — id, userId, field, currentValue, correctedValue, documents, status
- `FamilyMember` — id, name, relationship, nidaStatus, nidaNumber, dateOfBirth

### Service Layer
```dart
Dio get _dio => AuthenticatedDio.instance;
```
| Method | Verb | Endpoint | Return |
|--------|------|----------|--------|
| `checkStatus(receiptOrNida)` | GET | `/api/nida/status` | `SingleResult<NidaApplication>` |
| `getOffices(districtId)` | GET | `/api/nida/offices` | `PaginatedResult<NidaOffice>` |
| `getQueueEstimate(officeId)` | GET | `/api/nida/offices/{id}/queue` | `SingleResult<QueueInfo>` |
| `submitPreRegistration(data)` | POST | `/api/nida/pre-register` | `SingleResult<PreRegistration>` |
| `bookAppointment(officeId, date)` | POST | `/api/nida/appointments` | `SingleResult<Appointment>` |
| `lookupNumber(birthCertNo)` | GET | `/api/nida/lookup` | `SingleResult<NidaLookup>` |
| `verifyNida(nidaNumber)` | GET | `/api/nida/verify` | `SingleResult<VerificationResult>` |
| `submitCorrection(data)` | POST | `/api/nida/corrections` | `SingleResult<CorrectionRequest>` |
| `reportLost(data)` | POST | `/api/nida/lost` | `SingleResult<LostReport>` |
| `getMobileUnits(regionId)` | GET | `/api/nida/mobile-units` | `PaginatedResult<MobileUnit>` |

### Pages
- **NidaHomePage** — Status check input, nearest office, quick actions
- **StatusTrackerPage** — Visual timeline: Registered > Biometrics > Printing > At Office > Collected
- **OfficeFinderPage** — Map with offices, distance, wait times, hours
- **DocumentChecklistPage** — Interactive checklist with descriptions
- **PreRegistrationPage** — Multi-step form matching NIDA fields
- **AppointmentPage** — Calendar with available slots
- **DigitalIdPage** — Card-style display of registered details (reference only)
- **CorrectionRequestPage** — Form for data corrections with document upload

### Widgets
- `StatusTimeline` — Vertical stepper with 5 stages, current highlighted
- `OfficeCard` — Name, distance, queue indicator, hours, directions button
- `ChecklistItem` — Document name, description, check/uncheck, "where to get" link
- `IdCardPreview` — Card-style layout mimicking physical NIDA card
- `QueueIndicator` — Color-coded wait time (green <1h, yellow 1-3h, red 3h+)

---

## 2. UI Design
- Palette: #1A1A1A / #666666 / #FAFAFA / #FFFFFF
- Cards: BorderRadius.circular(12-16), subtle shadow
- 48dp touch targets, maxLines+ellipsis, _rounded icons
- Loading: CircularProgressIndicator(strokeWidth: 2, color: _kPrimary)

### Main Screen Wireframe
```
┌─────────────────────────┐
│ ◀  NIDA Services    🔔  │
├─────────────────────────┤
│ Check Application Status│
│ ┌─────────────────────┐ │
│ │ Receipt / NIDA No.  │ │
│ │ [Check Status]      │ │
│ └─────────────────────┘ │
│                         │
│ Nearest Office          │
│ ┌─────────────────────┐ │
│ │ NIDA Ilala  · 2.3km │ │
│ │ Queue: ~45min  ●🟡  │ │
│ │ [Directions] [Book] │ │
│ └─────────────────────┘ │
│                         │
│ [Pre-Register] [Docs]   │
│ [Report Lost] [Correct] │
│ [Mobile Units] [FAQ]    │
│                         │
│ Family Registration     │
│ ├─ Son (17) - Due 2027 │
│ └─ Spouse - Collected ✓│
└─────────────────────────┘
```

---

## 3. Performance Strategy

### SQLite Local Storage
```sql
CREATE TABLE nida_offices(id INTEGER PRIMARY KEY, district_id INTEGER, json_data TEXT, synced_at TEXT);
CREATE INDEX idx_nida_offices_district ON nida_offices(district_id);
CREATE TABLE nida_applications(id INTEGER PRIMARY KEY, user_id INTEGER, status TEXT, json_data TEXT, synced_at TEXT);
CREATE TABLE nida_checklist(id INTEGER PRIMARY KEY, type TEXT, json_data TEXT, synced_at TEXT);
```

### Caching
- Load from SQLite first (<5ms) then API background refresh
- TTL: Office locations 24h, queue estimates 5min, checklists 7d, FAQ 7d
- Offline read: YES — checklists, FAQ, photo requirements, office locations
- Offline write: pending_queue for pre-registration, corrections

---

## 4. Backend Implementation

### Database (PostgreSQL)
```sql
CREATE TABLE nida_applications (
    id BIGSERIAL PRIMARY KEY, user_id BIGINT REFERENCES users(id),
    receipt_number TEXT, nida_number TEXT, status TEXT DEFAULT 'registered',
    office_id BIGINT, estimated_date DATE,
    created_at TIMESTAMP DEFAULT NOW(), updated_at TIMESTAMP DEFAULT NOW()
);

CREATE TABLE nida_offices (
    id BIGSERIAL PRIMARY KEY, district_id BIGINT NOT NULL,
    name TEXT NOT NULL, address TEXT, phone TEXT, hours TEXT,
    services JSONB, lat DOUBLE PRECISION, lng DOUBLE PRECISION,
    created_at TIMESTAMP DEFAULT NOW()
);

CREATE TABLE nida_corrections (
    id BIGSERIAL PRIMARY KEY, user_id BIGINT REFERENCES users(id),
    field TEXT NOT NULL, current_value TEXT, corrected_value TEXT,
    documents JSONB, status TEXT DEFAULT 'submitted',
    created_at TIMESTAMP DEFAULT NOW(), updated_at TIMESTAMP DEFAULT NOW()
);
```

### API Endpoints
| Method | Endpoint | Description | Auth |
|--------|----------|-------------|------|
| GET | /api/nida/status | Check application status | Yes |
| GET | /api/nida/offices | Find NIDA offices | Yes |
| GET | /api/nida/offices/{id}/queue | Queue estimate | Yes |
| POST | /api/nida/pre-register | Pre-registration form | Yes |
| POST | /api/nida/appointments | Book appointment | Yes |
| GET | /api/nida/lookup | Lookup NIDA number | Yes |
| GET | /api/nida/verify | Verify NIDA number | Yes |
| POST | /api/nida/corrections | Submit correction | Yes |
| POST | /api/nida/lost | Report lost card | Yes |
| GET | /api/nida/mobile-units | Mobile unit tracker | Yes |

### Controller
- `app/Http/Controllers/Api/NidaController.php`
- DB facade, try/catch, `{"success": true/false, "data": ..., "message": "..."}`

---

## 5. Integration Wiring
- **WalletService** — Replacement card fees, express processing fees
- **NotificationService + FCMService** — Card production status, queue alerts, mobile unit schedules
- **LocationService** — GPS-based nearest office finder, mobile unit tracking
- **PhotoService** — In-app photo capture meeting NIDA specs, document uploads
- **ProfileService** — NIDA verification badge on TAJIRI profile
- **CalendarService** — Appointment reminders, mobile unit schedules
- **FriendService** — Family registration tracking for members approaching age 18
- **Cross-module: rita** — Birth certificate status check before NIDA application
- **Cross-module: passport** — NIDA required for passport; cross-check status

---

## 6. Implementation Phases
### Phase 1: Foundation (Week 1)
- Data models, service layer, SQLite schema, module scaffold
- Status check API, office finder with map

### Phase 2: Core UI (Week 2)
- Status tracker timeline, document checklist, pre-registration form
- Appointment booking calendar, queue indicators

### Phase 3: Integration (Week 3)
- Digital ID preview, NIDA verification service
- FCM notifications for status updates, mobile unit tracker

### Phase 4: Polish (Week 4)
- Family registration tracking, correction/lost card flows
- Offline support for checklists and FAQ, photo compliance tool

---

## 7. External APIs & Integrations

| API | Provider | Purpose | Pricing | Integration Notes |
|-----|----------|---------|---------|-------------------|
| NIDA Verification API | NIDA (National Identification Authority) | National ID verification, biometric matching | Institutional access only | services.nida.go.tz — PIN-based verification; restricted to banks/telecoms |
| Smile ID | Smile Identity | ID verification across 54 African countries incl. Tanzania NIN | Pay-per-verification | docs.usesmileid.com — supports Tanzania phone number verification, 8500+ ID types |
| uqudo | uqudo | Tanzania KYC/AML, ID document verification | Contact for pricing | docs.uqudo.com — Web SDK, Mobile SDK (8MB), REST API |
| Dojah | Dojah | Identity verification across 10+ African countries | Pay-per-verification | dojah.io — passport, driver's license, TIN verification |
| ID Analyzer | ID Analyzer | Tanzania ID document scanning and validation | Freemium | idanalyzer.com — supports TZ driver's license, passport |
| AzamPay API | AzamPay | Payment for NIDA service fees | Per-transaction | Dart SDK on pub.dev (azampaytanzania) |
| GePG | Ministry of Finance, Tanzania | Government fee payments for ID services | Institutional access | gepg.go.tz — control number-based payments |

### Integration Priority
1. **Immediate** — ID Analyzer (freemium, document scanning), Smile ID (established, broad coverage)
2. **Short-term** — uqudo (KYC/AML with mobile SDK), Dojah (multi-document verification), AzamPay for fee payments (Dart SDK)
3. **Partnership** — NIDA direct API (restricted to authorized institutions; requires formal agreement), GePG for government fee payments
