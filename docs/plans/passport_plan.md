# Passport (Pasipoti) — Implementation Plan

## Overview
Passport services companion module for Tanzania's Immigration Department. Features application guide, document checklist, AI-powered passport photo tool, form pre-fill, application tracking, fee calculator, immigration office finder, appointment booking, visa requirements checker, renewal reminders, embassy directory, and family passport management.

---

## 1. Frontend Architecture

### Directory Structure
```
lib/passport/
├── passport_module.dart
├── models/
│   ├── passport_models.dart
│   ├── visa_models.dart
│   └── embassy_models.dart
├── services/
│   └── passport_service.dart
├── pages/
│   ├── passport_home_page.dart
│   ├── application_guide_page.dart
│   ├── document_checklist_page.dart
│   ├── photo_tool_page.dart
│   ├── track_application_page.dart
│   ├── fee_calculator_page.dart
│   ├── office_finder_page.dart
│   ├── visa_checker_page.dart
│   ├── family_passports_page.dart
│   └── embassy_directory_page.dart
└── widgets/
    ├── passport_card.dart
    ├── expiry_countdown.dart
    ├── photo_compliance.dart
    ├── visa_status_badge.dart
    └── application_timeline.dart
```

### Data Models
- `PassportApplication` — id, userId, type (ordinary/diplomatic/service), pages (32/64), validity (5/10), status (submitted/processing/printing/ready), applicationNumber, submissionOffice
- `PassportInfo` — id, userId, passportNumber, type, issueDate, expiryDate, pages
- `VisaRequirement` — countryCode, countryName, status (visaFree/visaOnArrival/visaRequired), details, stayDuration
- `Embassy` — id, country, city, address, phone, email, hours, emergencyPhone
- `PhotoCompliance` — headPositionOk, backgroundOk, expressionOk, glassesOk, overallPass

### Service Layer
```dart
Dio get _dio => AuthenticatedDio.instance;
```
| Method | Verb | Endpoint | Return |
|--------|------|----------|--------|
| `trackApplication(appNumber)` | GET | `/api/passport/track/{number}` | `SingleResult<PassportApplication>` |
| `getChecklist(type)` | GET | `/api/passport/checklist/{type}` | `SingleResult<Checklist>` |
| `calculateFees(type, pages, speed)` | GET | `/api/passport/fees` | `SingleResult<FeeBreakdown>` |
| `getOffices(regionId)` | GET | `/api/passport/offices` | `PaginatedResult<Office>` |
| `bookAppointment(officeId, date)` | POST | `/api/passport/appointments` | `SingleResult<Appointment>` |
| `checkPhotoCompliance(imageBytes)` | POST | `/api/passport/photo-check` | `SingleResult<PhotoCompliance>` |
| `getVisaRequirements(countryCode)` | GET | `/api/passport/visa/{code}` | `SingleResult<VisaRequirement>` |
| `getAllVisaRequirements()` | GET | `/api/passport/visa` | `PaginatedResult<VisaRequirement>` |
| `getEmbassies(countryCode)` | GET | `/api/passport/embassies` | `PaginatedResult<Embassy>` |
| `getFamilyPassports()` | GET | `/api/passport/family` | `PaginatedResult<PassportInfo>` |

### Pages
- **PassportHomePage** — Application status card, renewal countdown, quick actions
- **ApplicationGuidePage** — Illustrated step-by-step with timeline
- **DocumentChecklistPage** — Interactive checklist with item descriptions
- **PhotoToolPage** — Camera with face detection overlay, compliance checker
- **TrackApplicationPage** — Timeline: Submitted > Processing > Printing > Ready
- **FeeCalculatorPage** — Select options, itemized fees, proceed to payment
- **OfficeFinderPage** — Map with immigration offices, distances, wait times
- **VisaCheckerPage** — Country selector with visa status and requirements
- **FamilyPassportsPage** — Family members' passport cards with expiry indicators

### Widgets
- `PassportCard` — Passport number, type, expiry, renewal indicator
- `ExpiryCountdown` — Days remaining with color coding (red <30d, yellow <90d)
- `PhotoCompliance` — Checkmarks for each requirement, retake prompt
- `VisaStatusBadge` — Green (free), yellow (on arrival), red (required)

---

## 2. UI Design
- Palette: #1A1A1A / #666666 / #FAFAFA / #FFFFFF
- Cards: BorderRadius.circular(12-16), subtle shadow
- 48dp touch targets, maxLines+ellipsis, _rounded icons
- Loading: CircularProgressIndicator(strokeWidth: 2, color: _kPrimary)

### Main Screen Wireframe
```
┌─────────────────────────┐
│ ◀  Passport Services 🔔 │
├─────────────────────────┤
│ ┌─────────────────────┐ │
│ │ 🛂 Passport AB12345 │ │
│ │ Expires: Dec 2027   │ │
│ │ ⏰ 618 days left     │ │
│ └─────────────────────┘ │
│                         │
│ Application: Processing │
│ ▓▓▓▓▓▓░░░░ Stage 2/4   │
│                         │
│ [Apply Guide] [Track]   │
│ [Photo Tool] [Fees]     │
│                         │
│ Quick Links             │
│ ├─ Visa Requirements   │
│ ├─ Find Office         │
│ ├─ Embassy Directory   │
│ └─ Child Passport Guide│
│                         │
│ Family Passports        │
│ ├─ Spouse - Valid ✓    │
│ └─ Child  - Expiring ⚠│
└─────────────────────────┘
```

---

## 3. Performance Strategy

### SQLite Local Storage
```sql
CREATE TABLE passport_applications(id INTEGER PRIMARY KEY, user_id INTEGER, status TEXT, json_data TEXT, synced_at TEXT);
CREATE TABLE passport_visa_reqs(id INTEGER PRIMARY KEY, country_code TEXT, json_data TEXT, synced_at TEXT);
CREATE INDEX idx_passport_visa_country ON passport_visa_reqs(country_code);
CREATE TABLE passport_embassies(id INTEGER PRIMARY KEY, country TEXT, json_data TEXT, synced_at TEXT);
```

### Caching
- Load from SQLite first (<5ms) then API background refresh
- TTL: Visa requirements 7d, embassies 30d, checklists 7d, offices 24h
- Offline read: YES — checklists, photo requirements, embassy directory, visa info
- Offline write: pending_queue for appointment bookings

---

## 4. Backend Implementation

### Database (PostgreSQL)
```sql
CREATE TABLE passport_applications (
    id BIGSERIAL PRIMARY KEY, user_id BIGINT REFERENCES users(id),
    type TEXT NOT NULL, pages INTEGER, validity_years INTEGER,
    status TEXT DEFAULT 'submitted', application_number TEXT UNIQUE,
    submission_office_id BIGINT, fee_amount DECIMAL(10,2),
    created_at TIMESTAMP DEFAULT NOW(), updated_at TIMESTAMP DEFAULT NOW()
);

CREATE TABLE passport_records (
    id BIGSERIAL PRIMARY KEY, user_id BIGINT REFERENCES users(id),
    passport_number TEXT, type TEXT, issue_date DATE, expiry_date DATE,
    pages INTEGER, created_at TIMESTAMP DEFAULT NOW()
);

CREATE TABLE passport_visa_requirements (
    id BIGSERIAL PRIMARY KEY, country_code TEXT UNIQUE NOT NULL,
    country_name TEXT NOT NULL, status TEXT NOT NULL,
    details TEXT, stay_duration TEXT,
    updated_at TIMESTAMP DEFAULT NOW()
);
```

### API Endpoints
| Method | Endpoint | Description | Auth |
|--------|----------|-------------|------|
| GET | /api/passport/track/{number} | Track application | Yes |
| GET | /api/passport/checklist/{type} | Document checklist | No |
| GET | /api/passport/fees | Fee calculator | No |
| GET | /api/passport/offices | Immigration offices | Yes |
| POST | /api/passport/appointments | Book appointment | Yes |
| POST | /api/passport/photo-check | Photo compliance AI | Yes |
| GET | /api/passport/visa/{code} | Visa requirements | No |
| GET | /api/passport/visa | All visa requirements | No |
| GET | /api/passport/embassies | Embassy directory | No |
| GET | /api/passport/family | Family passports | Yes |

### Controller
- `app/Http/Controllers/Api/PassportController.php`
- DB facade, try/catch, `{"success": true/false, "data": ..., "message": "..."}`

---

## 5. Integration Wiring
- **WalletService** — Passport fees (TZS 150,000-300,000)
- **NotificationService + FCMService** — Expiry reminders (6mo/3mo/1mo), status updates
- **CalendarService** — Expiry countdown, appointment dates, collection dates
- **PhotoService** — In-app passport photo capture with AI compliance
- **ProfileService** — Passport verification on TAJIRI platform
- **LocationService** — GPS-based nearest immigration office
- **LiveUpdateService** — Real-time application tracking via Firestore
- **FriendService** — Family passport expiry tracking
- **Cross-module: nida** — NIDA verification required before passport
- **Cross-module: rita** — Birth certificate required for passport
- **Cross-module: travel/** — Passport validity check with travel booking

---

## 6. Implementation Phases
### Phase 1: Foundation (Week 1)
- Data models, service layer, SQLite schema, module scaffold
- Application tracking API, office finder

### Phase 2: Core UI (Week 2)
- Passport home with expiry countdown, application guide
- Document checklist, fee calculator, tracking timeline

### Phase 3: Integration (Week 3)
- Photo compliance tool with AI, appointment booking
- WalletService payments, FCM expiry reminders

### Phase 4: Polish (Week 4)
- Visa requirements checker, embassy directory
- Family passports dashboard, offline caching

---

## 7. External APIs & Integrations

| API | Provider | Purpose | Pricing | Integration Notes |
|-----|----------|---------|---------|-------------------|
| Passport Index API | Arton Capital | Visa requirements between countries, passport rankings | Contact for API access | discover.passportindex.org — government agencies prioritized |
| Travel Buddy Visa API | Travel Buddy AI | Visa requirements, entry rules, duration of stay | Freemium (free tier) | RapidAPI: /v2/visa/check endpoint, daily updated |
| VisaDB API | VisaDB | Visa, entry, vaccination, customs requirements per country | Freemium | visadb.io/api — 5 data categories per country |
| passport-visa-api | Community / GitHub | Visa requirements matrix for 199 passports | Free (open source) | github.com/nickypangers/passport-visa-api |
| passport-index-dataset | Community / GitHub | CSV datasets of visa requirements (ISO codes) | Free (open source) | github.com/ilyankou/passport-index-dataset |
| Smile ID | Smile Identity | Passport document verification | Pay-per-verification | docs.usesmileid.com — supports Tanzania passport |
| AzamPay API | AzamPay | Mobile money payments for passport fees | Per-transaction | Dart SDK on pub.dev (azampaytanzania) |
| GePG | Ministry of Finance, Tanzania | Government fee payments for passport services | Institutional access | gepg.go.tz — control number-based payments |

### Integration Priority
1. **Immediate** — Travel Buddy Visa API (freemium, daily updated), VisaDB API (freemium), passport-visa-api/dataset (free open source), AzamPay (Dart SDK)
2. **Short-term** — Smile ID for passport document verification, Passport Index API (requires contact)
3. **Partnership** — Tanzania Immigration Department (no public API; portal only), GePG for government fee payments (institutional access)
