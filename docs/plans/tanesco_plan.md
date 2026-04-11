# TANESCO (Electricity Services) — Implementation Plan

## Overview
Electricity utility module for TANESCO (Tanzania Electric Supply Company). Provides LUKU prepaid token purchase via M-Pesa, multiple meter management, consumption analytics, usage alerts with auto-recharge, outage reporting and map, planned maintenance schedule, postpaid bill management, new connection applications, tariff/appliance calculators, energy saving tips, and error code troubleshooting.

---

## 1. Frontend Architecture

### Directory Structure
```
lib/tanesco/
├── tanesco_module.dart
├── models/
│   ├── meter_models.dart
│   ├── token_models.dart
│   └── outage_models.dart
├── services/
│   └── tanesco_service.dart
├── pages/
│   ├── tanesco_home_page.dart
│   ├── buy_tokens_page.dart
│   ├── consumption_dashboard_page.dart
│   ├── my_meters_page.dart
│   ├── outage_center_page.dart
│   ├── bills_page.dart
│   ├── new_connection_page.dart
│   ├── tariff_calculator_page.dart
│   ├── energy_tips_page.dart
│   └── help_page.dart
└── widgets/
    ├── meter_card.dart
    ├── token_display.dart
    ├── consumption_chart.dart
    ├── outage_map.dart
    ├── bill_card.dart
    └── appliance_slider.dart
```

### Data Models
- `Meter` — id, userId, meterNumber, type (prepaid/postpaid), alias, balance, lastPurchase, tariffCategory
- `TokenPurchase` — id, meterNumber, amount, units, token, paymentMethod, purchasedAt, status
- `ConsumptionRecord` — meterNumber, period, unitsUsed, cost, date
- `Outage` — id, location, reportedAt, affectedArea, status (reported/acknowledged/crewDispatched/fixed), reporterCount
- `PlannedMaintenance` — id, area, startDate, endDate, affectedZones, description
- `Bill` — id, meterNumber, billingPeriod, consumption, amount, dueDate, status (unpaid/paid/overdue)
- `ConnectionApplication` — id, userId, type (domestic/commercial), status (applied/surveyed/approved/materials/connected), location, documents

### Service Layer
```dart
Dio get _dio => AuthenticatedDio.instance;
```
| Method | Verb | Endpoint | Return |
|--------|------|----------|--------|
| `buyTokens(meterNumber, amount, method)` | POST | `/api/tanesco/tokens` | `SingleResult<TokenPurchase>` |
| `getTokenHistory(meterNumber)` | GET | `/api/tanesco/tokens` | `PaginatedResult<TokenPurchase>` |
| `getBalance(meterNumber)` | GET | `/api/tanesco/meters/{number}/balance` | `SingleResult<Balance>` |
| `getMyMeters()` | GET | `/api/tanesco/meters` | `PaginatedResult<Meter>` |
| `addMeter(meterNumber, alias)` | POST | `/api/tanesco/meters` | `SingleResult<Meter>` |
| `getConsumption(meterNumber, period)` | GET | `/api/tanesco/consumption` | `PaginatedResult<ConsumptionRecord>` |
| `reportOutage(data)` | POST | `/api/tanesco/outages` | `SingleResult<Outage>` |
| `getOutages(districtId)` | GET | `/api/tanesco/outages` | `PaginatedResult<Outage>` |
| `getMaintenance(districtId)` | GET | `/api/tanesco/maintenance` | `PaginatedResult<PlannedMaintenance>` |
| `getBills(meterNumber)` | GET | `/api/tanesco/bills` | `PaginatedResult<Bill>` |
| `payBill(billId, data)` | POST | `/api/tanesco/bills/{id}/pay` | `SingleResult<Payment>` |
| `applyConnection(data)` | POST | `/api/tanesco/connections` | `SingleResult<ConnectionApplication>` |
| `setAutoRecharge(meterNumber, threshold, amount)` | POST | `/api/tanesco/auto-recharge` | `SingleResult<AutoRecharge>` |

### Pages
- **TanescoHomePage** — Meter cards with balance, quick buy, outage banner, recent purchases
- **BuyTokensPage** — Meter selection, amount input, payment method, token display
- **ConsumptionDashboardPage** — Usage charts (daily/weekly/monthly), cost trends
- **MyMetersPage** — List of saved meters with balances and quick actions
- **OutageCenterPage** — Map of outages, report form, planned maintenance
- **BillsPage** — Postpaid bills with amounts, due dates, pay button
- **NewConnectionPage** — Application form, document checklist, fee calc, tracking
- **TariffCalculatorPage** — Appliance picker with hours/day sliders, monthly estimate
- **EnergyTipsPage** — Illustrated saving recommendations
- **HelpPage** — Error code troubleshooting, FAQ, TANESCO contacts

### Widgets
- `MeterCard` — Meter number, alias, balance, type badge, quick buy action
- `TokenDisplay` — Large token number with copy button
- `ConsumptionChart` — Bar/line chart with period selector
- `OutageMap` — Map with outage pins, color-coded status
- `BillCard` — Period, consumption, amount, due date, status, pay action
- `ApplianceSlider` — Appliance icon, hours/day slider, estimated cost

---

## 2. UI Design
- Palette: #1A1A1A / #666666 / #FAFAFA / #FFFFFF
- Cards: BorderRadius.circular(12-16), subtle shadow
- 48dp touch targets, maxLines+ellipsis, _rounded icons
- Loading: CircularProgressIndicator(strokeWidth: 2, color: _kPrimary)

### Main Screen Wireframe
```
┌─────────────────────────┐
│ ◀  TANESCO           🔔 │
├─────────────────────────┤
│ ⚡ Outage: Kinondoni area│
├─────────────────────────┤
│ ┌─────────────────────┐ │
│ │ 🔌 Home Meter       │ │
│ │ No: 12345678901     │ │
│ │ Balance: 42.5 kWh   │ │
│ │ [Buy Tokens]        │ │
│ └─────────────────────┘ │
│ ┌─────────────────────┐ │
│ │ 🏢 Office Meter     │ │
│ │ No: 98765432109     │ │
│ │ Balance: 8.2 kWh ⚠  │ │
│ │ [Buy Tokens]        │ │
│ └─────────────────────┘ │
│                         │
│ [Usage] [Outages]       │
│ [Bills] [New Connection]│
│                         │
│ Recent Purchases        │
│ ├─ Apr 5 · TZS 20K · ✓│
│ └─ Mar 28· TZS 15K · ✓│
│                         │
│ [Tariff Calc] [Tips]    │
└─────────────────────────┘
```

---

## 3. Performance Strategy

### SQLite Local Storage
```sql
CREATE TABLE tanesco_meters(id INTEGER PRIMARY KEY, user_id INTEGER, meter_number TEXT, json_data TEXT, synced_at TEXT);
CREATE INDEX idx_tanesco_meters_user ON tanesco_meters(user_id);
CREATE TABLE tanesco_tokens(id INTEGER PRIMARY KEY, meter_number TEXT, json_data TEXT, synced_at TEXT);
CREATE TABLE tanesco_outages(id INTEGER PRIMARY KEY, district_id INTEGER, status TEXT, json_data TEXT, synced_at TEXT);
```

### Caching
- Load from SQLite first (<5ms) then API background refresh
- TTL: Meter balance 15min, token history 1h, outages 5min, maintenance 6h
- Offline read: YES — error codes, energy tips, tariff calculator, emergency contacts
- Offline write: pending_queue for outage reports

---

## 4. Backend Implementation

### Database (PostgreSQL)
```sql
CREATE TABLE tanesco_meters (
    id BIGSERIAL PRIMARY KEY, user_id BIGINT REFERENCES users(id),
    meter_number TEXT NOT NULL, type TEXT DEFAULT 'prepaid',
    alias TEXT, tariff_category TEXT,
    created_at TIMESTAMP DEFAULT NOW(), updated_at TIMESTAMP DEFAULT NOW()
);

CREATE TABLE tanesco_token_purchases (
    id BIGSERIAL PRIMARY KEY, meter_number TEXT NOT NULL,
    amount DECIMAL(10,2) NOT NULL, units DECIMAL(10,2),
    token TEXT, payment_method TEXT, status TEXT DEFAULT 'completed',
    purchased_at TIMESTAMP DEFAULT NOW()
);

CREATE TABLE tanesco_outages (
    id BIGSERIAL PRIMARY KEY, reporter_id BIGINT REFERENCES users(id),
    location TEXT, district_id BIGINT,
    affected_area TEXT, status TEXT DEFAULT 'reported',
    reporter_count INTEGER DEFAULT 1, lat DOUBLE PRECISION, lng DOUBLE PRECISION,
    created_at TIMESTAMP DEFAULT NOW(), updated_at TIMESTAMP DEFAULT NOW()
);

CREATE TABLE tanesco_bills (
    id BIGSERIAL PRIMARY KEY, meter_number TEXT NOT NULL,
    billing_period TEXT, consumption DECIMAL(10,2),
    amount DECIMAL(10,2), due_date DATE, status TEXT DEFAULT 'unpaid',
    created_at TIMESTAMP DEFAULT NOW()
);
```

### API Endpoints
| Method | Endpoint | Description | Auth |
|--------|----------|-------------|------|
| POST | /api/tanesco/tokens | Buy LUKU tokens | Yes |
| GET | /api/tanesco/tokens | Token history | Yes |
| GET | /api/tanesco/meters/{no}/balance | Check balance | Yes |
| GET | /api/tanesco/meters | My meters | Yes |
| POST | /api/tanesco/meters | Add meter | Yes |
| GET | /api/tanesco/consumption | Consumption data | Yes |
| POST | /api/tanesco/outages | Report outage | Yes |
| GET | /api/tanesco/outages | Area outages | Yes |
| GET | /api/tanesco/maintenance | Planned maintenance | Yes |
| GET | /api/tanesco/bills | Postpaid bills | Yes |
| POST | /api/tanesco/bills/{id}/pay | Pay bill | Yes |
| POST | /api/tanesco/connections | New connection | Yes |
| POST | /api/tanesco/auto-recharge | Set auto-recharge | Yes |

### Controller
- `app/Http/Controllers/Api/TanescoController.php`
- DB facade, try/catch, `{"success": true/false, "data": ..., "message": "..."}`

---

## 5. Integration Wiring
- **WalletService** — LUKU token purchases, postpaid bill payments, auto-recharge
- **MessageService** — Send LUKU tokens to family via TAJIRI messaging
- **NotificationService + FCMService** — Low balance alerts, outage notifications, maintenance, bill due
- **CalendarService** — Maintenance dates, bill due dates
- **LocationService** — GPS-based outage reporting, nearest TANESCO office
- **GroupService** — Neighborhood outage reporting groups
- **PhotoService** — Meter reading photos, bill dispute evidence
- **LiveUpdateService** — Real-time outage status and connection tracking
- **FriendService** — Family meter management and top-ups
- **Cross-module: dawasco** — Combined utility dashboard (electricity + water)
- **Cross-module: bills/** — TANESCO in consolidated bill management

---

## 6. Implementation Phases
### Phase 1: Foundation (Week 1)
- Data models, service layer, SQLite schema, module scaffold
- Meter management, token purchase API

### Phase 2: Core UI (Week 2)
- Home with meter cards, buy tokens flow with token display
- Consumption dashboard with charts, bill management

### Phase 3: Integration (Week 3)
- Outage center with map and reporting, planned maintenance
- WalletService payments, FCM low balance and outage alerts

### Phase 4: Polish (Week 4)
- New connection application flow, tariff/appliance calculator
- Auto-recharge setup, energy tips, error code help, offline caching

---

## 7. External APIs & Integrations

| API | Provider | Purpose | Pricing | Integration Notes |
|-----|----------|---------|---------|-------------------|
| Selcom Utility Payments API | Selcom | TANESCO LUKU token purchase via API | Commission-based | developers.selcommobile.com — REST API, PHP/Java/Shell SDKs; largest LUKU vending agent |
| AzamPay API | AzamPay (Bakhresa Group) | Mobile money payments for LUKU tokens | Per-transaction | Dart SDK on pub.dev (azampaytanzania) — **recommended for Flutter** |
| ClickPesa BillPay API | ClickPesa | Utility bill payments with GePG control number | Contact for pricing | docs.clickpesa.com — supports GePG control numbers |
| Beem Africa Payments API | Beem | Mobile money collection, utility payments | Tier-based pricing | beem.africa — 22 country coverage |
| elipapower (reference) | Community / GitHub | Prepaid electricity token integration reference | Free (open source) | github.com/jkikuyu/elipapower — reference implementation |

### Integration Priority
1. **Immediate** — AzamPay API (has Dart/Flutter SDK on pub.dev, direct TANESCO integration), Selcom API (largest LUKU vending agent, documented REST API)
2. **Short-term** — ClickPesa for GePG control number generation, Beem Africa for additional mobile money options
3. **Partnership** — TANESCO direct integration for meter data, outage notifications, and new connection APIs (no public developer API)
