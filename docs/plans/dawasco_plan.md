# DAWASCO (Water Services) — Implementation Plan

## Overview
Water utility module for DAWASCO (Dar es Salaam Water and Sewerage Corporation) and regional water utilities. Provides bill payment via M-Pesa, bill history with consumption analytics, meter reading submission, water supply schedule (community-sourced), leak/sewerage issue reporting with tracking, new connection applications, tariff information, bill disputes, water quality reports, tank level monitoring, and water tanker service directory.

---

## 1. Frontend Architecture

### Directory Structure
```
lib/dawasco/
├── dawasco_module.dart
├── models/
│   ├── account_models.dart
│   ├── bill_models.dart
│   └── issue_models.dart
├── services/
│   └── dawasco_service.dart
├── pages/
│   ├── dawasco_home_page.dart
│   ├── pay_bill_page.dart
│   ├── bill_history_page.dart
│   ├── consumption_dashboard_page.dart
│   ├── supply_schedule_page.dart
│   ├── report_issue_page.dart
│   ├── my_reports_page.dart
│   ├── new_connection_page.dart
│   ├── meter_reading_page.dart
│   └── water_tips_page.dart
└── widgets/
    ├── account_card.dart
    ├── bill_card.dart
    ├── supply_indicator.dart
    ├── consumption_chart.dart
    ├── issue_timeline.dart
    └── meter_reader.dart
```

### Data Models
- `WaterAccount` — id, userId, accountNumber, meterNumber, connectionType (domestic/commercial/institutional), balance, lastBillDate, status
- `WaterBill` — id, accountNumber, billingPeriod, consumption (m3), standingCharge, consumptionCharge, totalAmount, dueDate, status (unpaid/paid/overdue/disputed)
- `SupplySchedule` — dayOfWeek, startHour, endHour, area, source (official/community), reliability
- `WaterIssue` — id, reporterId, type (leak/sewerage/quality/pressure), location, description, photoUrls, severity, status (reported/acknowledged/crewDispatched/fixed)
- `MeterReading` — id, accountNumber, reading, photoUrl, submittedAt
- `ConnectionApplication` — id, userId, type, location, status (applied/surveyed/approved/connected), documents

### Service Layer
```dart
Dio get _dio => AuthenticatedDio.instance;
```
| Method | Verb | Endpoint | Return |
|--------|------|----------|--------|
| `getAccount()` | GET | `/api/dawasco/account` | `SingleResult<WaterAccount>` |
| `getBills(accountNumber)` | GET | `/api/dawasco/bills` | `PaginatedResult<WaterBill>` |
| `payBill(billId, data)` | POST | `/api/dawasco/bills/{id}/pay` | `SingleResult<Payment>` |
| `getConsumption(accountNumber, period)` | GET | `/api/dawasco/consumption` | `PaginatedResult<ConsumptionRecord>` |
| `submitMeterReading(data)` | POST | `/api/dawasco/meter-readings` | `SingleResult<MeterReading>` |
| `getSupplySchedule(wardId)` | GET | `/api/dawasco/supply-schedule` | `PaginatedResult<SupplySchedule>` |
| `reportSupplyStatus(data)` | POST | `/api/dawasco/supply-status` | `SingleResult<SupplyReport>` |
| `reportIssue(data)` | POST | `/api/dawasco/issues` | `SingleResult<WaterIssue>` |
| `getMyReports()` | GET | `/api/dawasco/issues/mine` | `PaginatedResult<WaterIssue>` |
| `applyConnection(data)` | POST | `/api/dawasco/connections` | `SingleResult<ConnectionApplication>` |
| `disputeBill(billId, data)` | POST | `/api/dawasco/bills/{id}/dispute` | `SingleResult<Dispute>` |
| `getTariffs()` | GET | `/api/dawasco/tariffs` | `PaginatedResult<Tariff>` |
| `getOffices(districtId)` | GET | `/api/dawasco/offices` | `PaginatedResult<Office>` |

### Pages
- **DawascoHomePage** — Account card with balance, supply status, quick pay, leak alert
- **PayBillPage** — Amount due, payment method, M-Pesa flow, confirmation
- **BillHistoryPage** — Monthly bills with consumption bars, amount, status
- **ConsumptionDashboardPage** — Usage charts, cost trends, month comparison
- **SupplySchedulePage** — Weekly calendar with expected water hours
- **ReportIssuePage** — Photo + GPS + category + severity + description
- **MyReportsPage** — Submitted reports with status tracking
- **NewConnectionPage** — Application wizard: location > type > docs > payment > track
- **MeterReadingPage** — Camera-based meter photo with manual input

### Widgets
- `AccountCard` — Account number, balance, connection type, supply status
- `BillCard` — Period, consumption (m3), amount, due date, status, pay action
- `SupplyIndicator` — Green (water on), red (off), grey (unknown), with time
- `ConsumptionChart` — Bar chart of monthly m3 consumption with cost overlay
- `IssueTimeline` — Reported > Acknowledged > Crew Dispatched > Fixed
- `MeterReader` — Camera overlay with manual reading input field

---

## 2. UI Design
- Palette: #1A1A1A / #666666 / #FAFAFA / #FFFFFF
- Cards: BorderRadius.circular(12-16), subtle shadow
- 48dp touch targets, maxLines+ellipsis, _rounded icons
- Loading: CircularProgressIndicator(strokeWidth: 2, color: _kPrimary)

### Main Screen Wireframe
```
┌─────────────────────────┐
│ ◀  DAWASCO           🔔 │
├─────────────────────────┤
│ 💧 Supply: ON (since 6am)│
├─────────────────────────┤
│ ┌─────────────────────┐ │
│ │ Account: DAW-12345  │ │
│ │ Balance: TZS 45,200 │ │
│ │ Due: Apr 15, 2026   │ │
│ │ [Pay Bill]          │ │
│ └─────────────────────┘ │
│                         │
│ This Month: 12.5 m³    │
│ ▓▓▓▓▓▓▓░░░ vs 15 m³ avg│
│                         │
│ [Usage] [Schedule]      │
│ [Report Leak] [Meter]   │
│                         │
│ Supply Schedule         │
│ ├─ Mon-Fri: 6am-2pm   │
│ └─ Sat-Sun: 6am-10am  │
│                         │
│ [Tariffs] [Connection]  │
│ [Tips]  [Offices]       │
└─────────────────────────┘
```

---

## 3. Performance Strategy

### SQLite Local Storage
```sql
CREATE TABLE dawasco_bills(id INTEGER PRIMARY KEY, account_number TEXT, status TEXT, json_data TEXT, synced_at TEXT);
CREATE INDEX idx_dawasco_bills_account ON dawasco_bills(account_number);
CREATE TABLE dawasco_schedule(id INTEGER PRIMARY KEY, ward_id INTEGER, json_data TEXT, synced_at TEXT);
CREATE TABLE dawasco_issues(id INTEGER PRIMARY KEY, user_id INTEGER, status TEXT, json_data TEXT, synced_at TEXT);
```

### Caching
- Load from SQLite first (<5ms) then API background refresh
- TTL: Bills 1h, supply schedule 6h, outages 5min, tariffs 7d
- Offline read: YES — water tips, tariff schedules, emergency contacts, supply schedule
- Offline write: pending_queue for issue reports, meter readings

---

## 4. Backend Implementation

### Database (PostgreSQL)
```sql
CREATE TABLE dawasco_accounts (
    id BIGSERIAL PRIMARY KEY, user_id BIGINT REFERENCES users(id),
    account_number TEXT UNIQUE, meter_number TEXT,
    connection_type TEXT DEFAULT 'domestic', status TEXT DEFAULT 'active',
    created_at TIMESTAMP DEFAULT NOW(), updated_at TIMESTAMP DEFAULT NOW()
);

CREATE TABLE dawasco_bills (
    id BIGSERIAL PRIMARY KEY, account_number TEXT NOT NULL,
    billing_period TEXT, consumption_m3 DECIMAL(10,2),
    standing_charge DECIMAL(10,2), consumption_charge DECIMAL(10,2),
    total_amount DECIMAL(10,2), due_date DATE, status TEXT DEFAULT 'unpaid',
    created_at TIMESTAMP DEFAULT NOW()
);

CREATE TABLE dawasco_issues (
    id BIGSERIAL PRIMARY KEY, reporter_id BIGINT REFERENCES users(id),
    type TEXT NOT NULL, location TEXT, description TEXT,
    photo_urls JSONB, severity TEXT, status TEXT DEFAULT 'reported',
    lat DOUBLE PRECISION, lng DOUBLE PRECISION,
    created_at TIMESTAMP DEFAULT NOW(), updated_at TIMESTAMP DEFAULT NOW()
);

CREATE TABLE dawasco_supply_schedule (
    id BIGSERIAL PRIMARY KEY, ward_id BIGINT NOT NULL,
    day_of_week INTEGER, start_hour INTEGER, end_hour INTEGER,
    source TEXT DEFAULT 'official', reliability TEXT,
    updated_at TIMESTAMP DEFAULT NOW()
);
```

### API Endpoints
| Method | Endpoint | Description | Auth |
|--------|----------|-------------|------|
| GET | /api/dawasco/account | My account | Yes |
| GET | /api/dawasco/bills | Bill history | Yes |
| POST | /api/dawasco/bills/{id}/pay | Pay bill | Yes |
| GET | /api/dawasco/consumption | Consumption data | Yes |
| POST | /api/dawasco/meter-readings | Submit reading | Yes |
| GET | /api/dawasco/supply-schedule | Supply schedule | Yes |
| POST | /api/dawasco/supply-status | Report supply status | Yes |
| POST | /api/dawasco/issues | Report leak/issue | Yes |
| GET | /api/dawasco/issues/mine | My reports | Yes |
| POST | /api/dawasco/connections | New connection | Yes |
| POST | /api/dawasco/bills/{id}/dispute | Dispute bill | Yes |
| GET | /api/dawasco/tariffs | Tariff schedule | No |
| GET | /api/dawasco/offices | DAWASCO offices | Yes |

### Controller
- `app/Http/Controllers/Api/DawascoController.php`
- DB facade, try/catch, `{"success": true/false, "data": ..., "message": "..."}`

---

## 5. Integration Wiring
- **WalletService** — Bill payments, arrears, reconnection fees via M-Pesa
- **MessageService** — Contact DAWASCO support, leak report communications
- **NotificationService + FCMService** — Bill due dates, supply changes, issue status, outage alerts
- **CalendarService** — Bill due dates, supply schedule synced to calendar
- **LocationService** — GPS-based leak reporting, nearest office, area supply schedule
- **GroupService** — Neighborhood groups for supply status sharing
- **PhotoService** — Leak photos with GPS, meter reading photos, dispute evidence
- **LiveUpdateService** — Real-time issue tracking and supply status via Firestore
- **FriendService** — Family water accounts across properties
- **Cross-module: tanesco** — Combined utility dashboard (water + electricity)
- **Cross-module: bills/** — Water in consolidated bill management

---

## 6. Implementation Phases
### Phase 1: Foundation (Week 1)
- Data models, service layer, SQLite schema, module scaffold
- Account display, bill history and payment APIs

### Phase 2: Core UI (Week 2)
- Home with account card and supply indicator, pay bill flow
- Consumption dashboard, bill history with charts

### Phase 3: Integration (Week 3)
- Supply schedule (official + community), leak/issue reporting with map
- WalletService payments, FCM bill and outage alerts

### Phase 4: Polish (Week 4)
- Meter reading submission with camera, new connection flow
- Bill dispute, water tips, tariff info, offline caching

---

## 7. External APIs & Integrations

| API | Provider | Purpose | Pricing | Integration Notes |
|-----|----------|---------|---------|-------------------|
| Selcom Utility Payments API | Selcom | DAWASCO bill payment via API | Commission-based | developers.selcommobile.com — supports utility bill payments |
| AzamPay API | AzamPay (Bakhresa Group) | Mobile money payments for water bills | Per-transaction | Dart SDK on pub.dev (azampaytanzania) — **recommended for Flutter** |
| ClickPesa BillPay API | ClickPesa | Bill payment with GePG control number support | Contact for pricing | docs.clickpesa.com — automates control number generation |
| Beem Africa Payments API | Beem | Utility bill payments via mobile money | Tier-based pricing | beem.africa — USSD and API options |
| DAWASA App | DAWASA, Tanzania | View bills, report issues, apply for connections | Free for customers | mportal.ega.go.tz — no public developer API |

### Integration Priority
1. **Immediate** — AzamPay API (has Dart/Flutter SDK on pub.dev, supports DAWASCO bill reference numbers), Selcom API (documented REST API for utility payments)
2. **Short-term** — ClickPesa for GePG control number automation, Beem Africa for additional mobile money channels
3. **Partnership** — DAWASCO/DAWASA direct integration for meter data, bill details, and outage notifications (no public developer API; use payment aggregators)
