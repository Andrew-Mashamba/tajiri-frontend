# Leseni (Driving Licence) — Implementation Plan

## Overview
Driving licence management module for LATRA (Land Transport Regulatory Authority). Features licence application guide, driving school directory, theory test preparation with road sign flashcards, mock exams, document checklist, application tracking, licence renewal, fine/points check and payment, road safety tips, traffic rules reference, and LATRA office finder.

---

## 1. Frontend Architecture

### Directory Structure
```
lib/driving_licence/
├── driving_licence_module.dart
├── models/
│   ├── licence_models.dart
│   ├── theory_models.dart
│   └── fine_models.dart
├── services/
│   └── driving_licence_service.dart
├── pages/
│   ├── licence_home_page.dart
│   ├── application_guide_page.dart
│   ├── driving_schools_page.dart
│   ├── theory_prep_page.dart
│   ├── road_signs_page.dart
│   ├── mock_exam_page.dart
│   ├── track_application_page.dart
│   ├── fines_page.dart
│   ├── renewal_page.dart
│   ├── traffic_rules_page.dart
│   └── office_finder_page.dart
└── widgets/
    ├── licence_card.dart
    ├── road_sign_card.dart
    ├── exam_question.dart
    ├── fine_tile.dart
    ├── school_card.dart
    └── driving_log_entry.dart
```

### Data Models
- `DrivingLicence` — id, userId, licenceNumber, classes (list of LicenceClass), issueDate, expiryDate, status (provisional/full), points
- `LicenceClass` — classCode (A/B/C/D/E/F), type (provisional/full), obtainedDate
- `DrivingSchool` — id, name, location, rating, priceRange, classesOffered, phone, lat, lng
- `TheoryQuestion` — id, questionSw, questionEn, options, correctIndex, explanation, category
- `RoadSign` — id, name, imageUrl, meaning, category (warning/regulatory/informational)
- `TrafficFine` — id, licenceNumber, violation, amount, date, location, status (outstanding/paid), points

### Service Layer
```dart
Dio get _dio => AuthenticatedDio.instance;
```
| Method | Verb | Endpoint | Return |
|--------|------|----------|--------|
| `getLicence(userId)` | GET | `/api/licence/mine` | `SingleResult<DrivingLicence>` |
| `getSchools(districtId, classCode)` | GET | `/api/licence/schools` | `PaginatedResult<DrivingSchool>` |
| `getTheoryQuestions(category)` | GET | `/api/licence/theory` | `PaginatedResult<TheoryQuestion>` |
| `getMockExam()` | GET | `/api/licence/mock-exam` | `SingleResult<MockExam>` |
| `submitMockScore(data)` | POST | `/api/licence/mock-exam/score` | `SingleResult<ExamResult>` |
| `getRoadSigns(category)` | GET | `/api/licence/signs` | `PaginatedResult<RoadSign>` |
| `trackApplication(appId)` | GET | `/api/licence/applications/{id}` | `SingleResult<Application>` |
| `getFines(licenceNumber)` | GET | `/api/licence/fines` | `PaginatedResult<TrafficFine>` |
| `payFine(fineId, data)` | POST | `/api/licence/fines/{id}/pay` | `SingleResult<Payment>` |
| `initiateRenewal(data)` | POST | `/api/licence/renew` | `SingleResult<RenewalApplication>` |
| `getOffices(regionId)` | GET | `/api/licence/offices` | `PaginatedResult<Office>` |

### Pages
- **LicenceHomePage** — Licence card, expiry countdown, fine alerts, quick actions
- **ApplicationGuidePage** — Step-by-step per class with timeline and costs
- **DrivingSchoolsPage** — Map/list with filters (location, price, class, rating)
- **TheoryPrepPage** — Topic browser, practice questions, progress tracker
- **RoadSignsPage** — Categorized gallery with quiz mode
- **MockExamPage** — Timed exam simulating LATRA format
- **FinesPage** — Outstanding violations with payment action
- **RenewalPage** — Expiry check, document update, fee payment
- **TrafficRulesPage** — Browseable reference with search

### Widgets
- `LicenceCard` — Licence number, classes, expiry, points indicator
- `RoadSignCard` — Sign image, name, meaning, quiz flip
- `ExamQuestion` — Question, radio options, timer, submit
- `FineTile` — Violation, amount, date, pay button
- `SchoolCard` — Name, rating, price, classes, distance

---

## 2. UI Design
- Palette: #1A1A1A / #666666 / #FAFAFA / #FFFFFF
- Cards: BorderRadius.circular(12-16), subtle shadow
- 48dp touch targets, maxLines+ellipsis, _rounded icons
- Loading: CircularProgressIndicator(strokeWidth: 2, color: _kPrimary)

### Main Screen Wireframe
```
┌─────────────────────────┐
│ ◀  Driving Licence  🔔  │
├─────────────────────────┤
│ ┌─────────────────────┐ │
│ │ 🪪 Licence B-12345  │ │
│ │ Class: A, B · Full  │ │
│ │ Expires: Mar 2028   │ │
│ │ Points: 2/12        │ │
│ └─────────────────────┘ │
│                         │
│ ⚠ 1 Outstanding Fine    │
│ TZS 50,000 · Speeding  │
│ [Pay Now]               │
│                         │
│ [Apply] [Schools]       │
│ [Theory Prep] [Renew]   │
│                         │
│ Quick Links             │
│ ├─ Road Signs Study    │
│ ├─ Mock Exam           │
│ ├─ Traffic Rules       │
│ ├─ Safety Tips         │
│ └─ Find LATRA Office   │
└─────────────────────────┘
```

---

## 3. Performance Strategy

### SQLite Local Storage
```sql
CREATE TABLE dl_theory(id INTEGER PRIMARY KEY, category TEXT, json_data TEXT, synced_at TEXT);
CREATE INDEX idx_dl_theory_cat ON dl_theory(category);
CREATE TABLE dl_signs(id INTEGER PRIMARY KEY, category TEXT, json_data TEXT, synced_at TEXT);
CREATE TABLE dl_fines(id INTEGER PRIMARY KEY, licence_number TEXT, status TEXT, json_data TEXT, synced_at TEXT);
CREATE TABLE dl_rules(id INTEGER PRIMARY KEY, section TEXT, json_data TEXT, synced_at TEXT);
```

### Caching
- Load from SQLite first (<5ms) then API background refresh
- TTL: Theory questions 7d, road signs 30d, fines 1h, traffic rules 30d
- Offline read: YES — road signs, theory questions, traffic rules, safety tips
- Offline write: pending_queue for mock exam scores

---

## 4. Backend Implementation

### Database (PostgreSQL)
```sql
CREATE TABLE driving_licences (
    id BIGSERIAL PRIMARY KEY, user_id BIGINT REFERENCES users(id),
    licence_number TEXT UNIQUE, classes JSONB,
    issue_date DATE, expiry_date DATE,
    status TEXT DEFAULT 'provisional', points INTEGER DEFAULT 0,
    created_at TIMESTAMP DEFAULT NOW(), updated_at TIMESTAMP DEFAULT NOW()
);

CREATE TABLE driving_schools (
    id BIGSERIAL PRIMARY KEY, name TEXT NOT NULL,
    district_id BIGINT, location TEXT, rating DECIMAL(3,2),
    price_range TEXT, classes_offered JSONB, phone TEXT,
    lat DOUBLE PRECISION, lng DOUBLE PRECISION,
    created_at TIMESTAMP DEFAULT NOW()
);

CREATE TABLE traffic_fines (
    id BIGSERIAL PRIMARY KEY, licence_number TEXT NOT NULL,
    violation TEXT, amount DECIMAL(10,2), fine_date DATE,
    location TEXT, status TEXT DEFAULT 'outstanding', points INTEGER DEFAULT 0,
    created_at TIMESTAMP DEFAULT NOW(), updated_at TIMESTAMP DEFAULT NOW()
);
```

### API Endpoints
| Method | Endpoint | Description | Auth |
|--------|----------|-------------|------|
| GET | /api/licence/mine | My licence | Yes |
| GET | /api/licence/schools | Driving schools | Yes |
| GET | /api/licence/theory | Theory questions | Yes |
| GET | /api/licence/mock-exam | Mock exam | Yes |
| POST | /api/licence/mock-exam/score | Submit mock score | Yes |
| GET | /api/licence/signs | Road signs | No |
| GET | /api/licence/applications/{id} | Track application | Yes |
| GET | /api/licence/fines | Outstanding fines | Yes |
| POST | /api/licence/fines/{id}/pay | Pay fine | Yes |
| POST | /api/licence/renew | Initiate renewal | Yes |
| GET | /api/licence/offices | LATRA offices | Yes |

### Controller
- `app/Http/Controllers/Api/DrivingLicenceController.php`
- DB facade, try/catch, `{"success": true/false, "data": ..., "message": "..."}`

---

## 5. Integration Wiring
- **WalletService** — Licence fees (TZS 40-60K), fine payments, school payments
- **NotificationService + FCMService** — Expiry reminders (3mo/1mo/2wk), fine alerts, test reminders
- **CalendarService** — Test dates, renewal deadlines, school schedules
- **LocationService** — GPS-based nearest LATRA office and school finder
- **ProfileService** — Verified driver status on TAJIRI platform
- **LiveUpdateService** — Application tracking via Firestore
- **GroupService** — Driving learner communities, road safety forums
- **Cross-module: nida** — NIDA card required for licence application
- **Cross-module: insurance/** — Vehicle insurance cross-reference
- **Cross-module: legal_gpt** — Traffic law questions, fine dispute guidance

---

## 6. Implementation Phases
### Phase 1: Foundation (Week 1)
- Data models, service layer, SQLite schema, module scaffold
- Licence display, driving school directory

### Phase 2: Core UI (Week 2)
- Theory prep with questions and progress, road signs flashcards
- Mock exam with timer, application guide and tracking

### Phase 3: Integration (Week 3)
- Fine check and WalletService payment, renewal flow
- FCM expiry reminders, LATRA office finder

### Phase 4: Polish (Week 4)
- Driving log for learners, traffic rules reference
- Road safety tips, offline theory content caching

---

## 7. External APIs & Integrations

| API | Provider | Purpose | Pricing | Integration Notes |
|-----|----------|---------|---------|-------------------|
| TRA CDLS | Tanzania Revenue Authority | Digital driving licence issuance and verification | Government service | Part of IDRAS initiative; uses TIN, SMS/email notifications |
| LATRA RRIMS | LATRA (Land Transport Regulatory Authority) | Railway & road information management | Government portal | rrims.latra.go.tz — regulatory data |
| ID Analyzer | ID Analyzer | Tanzania driver's license document scanning/validation | Freemium | idanalyzer.com — supports TZ driver's license |
| Smile ID | Smile Identity | Driver's license verification across Africa | Pay-per-verification | docs.usesmileid.com — document verification |
| KYC Chain | KYC Chain | Tanzania driver's license, passport verification | Contact for pricing | kyc-chain.com/coverage/tanzania/ |
| AzamPay API | AzamPay | Mobile money payments for licence fees | Per-transaction | Dart SDK on pub.dev (azampaytanzania) |
| GePG | Ministry of Finance, Tanzania | Government fee payments for licence services | Institutional access | gepg.go.tz — control number-based payments |

### Integration Priority
1. **Immediate** — ID Analyzer (freemium, document scanning), AzamPay for fee payments (has Dart SDK)
2. **Short-term** — Smile ID for licence document verification, KYC Chain for multi-document verification
3. **Partnership** — TRA CDLS direct integration (government portal only, no public REST API), LATRA RRIMS data feeds, GePG for government fee payments
