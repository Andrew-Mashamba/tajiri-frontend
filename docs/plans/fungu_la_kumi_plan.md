# Fungu la Kumi (Tithe & Offering) — Implementation Plan

## Overview
Digital tithe and offering management for Tanzanian churches. Supports M-Pesa payments, categorized giving (sadaka, zaka, michango), recurring gifts, annual statements, pledge tracking, and church fund transparency.

---

## 1. Frontend Architecture

### Directory Structure
```
lib/fungu_la_kumi/
├── fungu_la_kumi_module.dart
├── models/
│   ├── giving_record.dart
│   ├── pledge.dart
│   ├── giving_category.dart
│   ├── recurring_gift.dart
│   └── annual_summary.dart
├── services/
│   └── tithe_service.dart           — AuthenticatedDio.instance
├── pages/
│   ├── giving_dashboard_page.dart
│   ├── give_now_page.dart
│   ├── giving_history_page.dart
│   ├── annual_statement_page.dart
│   ├── pledge_manager_page.dart
│   ├── recurring_gifts_page.dart
│   ├── church_giving_page.dart
│   └── income_calculator_page.dart
└── widgets/
    ├── giving_summary_card.dart
    ├── category_chip.dart
    ├── mpesa_payment_sheet.dart
    ├── pledge_progress_bar.dart
    └── giving_chart.dart
```

### Data Models
- **GivingRecord** — `id`, `userId`, `amount`, `category` (tithe/sadaka/zaka/michango/shukrani), `churchId`, `paymentMethod`, `transactionRef`, `createdAt`. `_parseDouble`, `_parseInt`.
- **Pledge** — `id`, `userId`, `campaignId`, `totalAmount`, `paidAmount`, `dueDate`. `_parseDouble`.
- **RecurringGift** — `id`, `userId`, `amount`, `category`, `frequency` (weekly/monthly), `churchId`, `isActive`. `_parseBool`.
- **AnnualSummary** — `year`, `totalGiven`, `categoryBreakdown` (Map), `monthlyTotals` (List).

### Service Layer
```dart
Dio get _dio => AuthenticatedDio.instance;
```
- `getDashboard()` — `GET /api/tithe/dashboard`
- `recordGiving(Map data)` — `POST /api/tithe/give`
- `getHistory({String? category, String? dateRange})` — `GET /api/tithe/history`
- `getAnnualSummary(int year)` — `GET /api/tithe/summary/{year}`
- `createPledge(Map data)` — `POST /api/tithe/pledges`
- `getPledges()` — `GET /api/tithe/pledges`
- `setupRecurring(Map data)` — `POST /api/tithe/recurring`
- `initiateMpesaPayment(Map data)` — `POST /api/tithe/mpesa/initiate`

### Pages
- **GivingDashboardPage** — Total given this month/year, giving streak, next reminder
- **GiveNowPage** — Amount entry, category selector, church selector, M-Pesa flow
- **GivingHistoryPage** — Filterable list by date, category, church
- **AnnualStatementPage** — Summary cards by category, monthly chart, PDF download
- **PledgeManagerPage** — Active pledges with progress bars

### Widgets
- `MpesaPaymentSheet` — Bottom sheet with phone number entry and payment confirmation
- `GivingChart` — Monthly bar chart of giving by category

---

## 2. UI Design
- #1A1A1A/#666666/#FAFAFA/#FFFFFF monochromatic
- 48dp touch, maxLines+ellipsis, _rounded icons
- Dark stat cards for total given, streak, and goals
- Cards: radius 12-16, subtle shadow

### Main Screen Wireframe
```
┌─────────────────────────────┐
│ ← Fungu la Kumi         ⚙️   │
├─────────────────────────────┤
│ ┌───────────┐ ┌───────────┐ │
│ │ This Month│ │ This Year │ │
│ │ TZS 150K  │ │ TZS 1.8M  │ │
│ └───────────┘ └───────────┘ │
│                             │
│  [  Give Now  ]  ← primary  │
│                             │
│  Recent Giving              │
│ ┌─────────────────────────┐ │
│ │ Tithe    TZS 100,000    │ │
│ │ Mar 30   Kanisa la Moshi│ │
│ ├─────────────────────────┤ │
│ │ Sadaka   TZS 50,000     │ │
│ │ Mar 23   Kanisa la Moshi│ │
│ └─────────────────────────┘ │
│                             │
│  Active Pledges             │
│  Building Fund ████░░ 60%   │
│                             │
│ [History] [Pledges] [Report]│
└─────────────────────────────┘
```

---

## 3. Performance Strategy

### SQLite
```sql
CREATE TABLE giving_records(id INTEGER PRIMARY KEY, user_id INTEGER, amount REAL, category TEXT, church_id INTEGER, json_data TEXT, synced_at TEXT);
CREATE TABLE pledges(id INTEGER PRIMARY KEY, user_id INTEGER, total_amount REAL, paid_amount REAL, json_data TEXT, synced_at TEXT);
CREATE INDEX idx_giving_category ON giving_records(category);
```
- Stale-while-revalidate: SQLite first, API background
- TTL: dashboard — 30 minutes, history — 1 hour
- Offline: read YES, write via pending_queue (sync when online)

---

## 4. Backend Implementation

### Database
```sql
CREATE TABLE giving_records(id BIGSERIAL PRIMARY KEY, user_id BIGINT, amount DECIMAL(15,2), category VARCHAR(30), church_id BIGINT, payment_method VARCHAR(20), transaction_ref VARCHAR(100), notes TEXT, created_at TIMESTAMP DEFAULT NOW());

CREATE TABLE pledges(id BIGSERIAL PRIMARY KEY, user_id BIGINT, campaign_id BIGINT, total_amount DECIMAL(15,2), paid_amount DECIMAL(15,2) DEFAULT 0, due_date DATE, created_at TIMESTAMP DEFAULT NOW());

CREATE TABLE recurring_gifts(id BIGSERIAL PRIMARY KEY, user_id BIGINT, amount DECIMAL(15,2), category VARCHAR(30), frequency VARCHAR(20), church_id BIGINT, is_active BOOLEAN DEFAULT TRUE, next_date DATE, created_at TIMESTAMP DEFAULT NOW());
```

### API Endpoints
| Method | Endpoint | Description | Auth |
|--------|----------|-------------|------|
| GET | /api/tithe/dashboard | Giving dashboard stats | Bearer |
| POST | /api/tithe/give | Record giving | Bearer |
| GET | /api/tithe/history | Giving history | Bearer |
| GET | /api/tithe/summary/{year} | Annual summary | Bearer |
| POST | /api/tithe/pledges | Create pledge | Bearer |
| GET | /api/tithe/pledges | List pledges | Bearer |
| POST | /api/tithe/recurring | Setup recurring gift | Bearer |
| POST | /api/tithe/mpesa/initiate | Initiate M-Pesa payment | Bearer |

### Controller
`app/Http/Controllers/Api/TitheController.php` — DB facade with M-Pesa callback handling for payment confirmation.

---

## 5. Integration Wiring
- **WalletService** — M-Pesa payment channel for all transactions
- **ContributionService** — church building fund campaigns
- **NotificationService** — pay day reminders, pledge reminders, payment confirmations
- **CalendarService** — pay day reminders synced with giving schedule
- **Kanisa Langu** — church-specific giving campaigns and acknowledgments
- **LiveUpdateService** — real-time offering totals during services

---

## 6. Implementation Phases
### Phase 1: Foundation (Week 1)
- Data models, service layer, SQLite schema
- Backend tables and giving CRUD
- M-Pesa payment integration

### Phase 2: Core UI (Week 2)
- Giving dashboard with stats cards
- Give Now flow with category selection
- Giving history with filters

### Phase 3: Integration (Week 3)
- Pledge tracking with progress bars
- Recurring gifts management
- Annual statement with PDF export

### Phase 4: Polish (Week 4)
- Income calculator (auto 10%)
- Church fund transparency view
- Offline queue, notifications, analytics

---

## 7. External APIs & Integrations

| API | Provider | Purpose | Pricing | Integration Notes |
|-----|----------|---------|---------|-------------------|
| Flutterwave API | Flutterwave | African payment processing (M-Pesa, cards, bank) | ~1.4% local, 3.8% intl | Ideal for East Africa; supports KES, TZS, UGX; flutterwave.com/docs |
| Stripe Connect | Stripe | Custom payment processing for church giving | 2.9% + $0.30/txn | Platform model via Stripe Connect; stripe.com/docs |
| Tithe.ly API | Tithe.ly | Church giving, transactions, categories | Paid (church subscription) | API access by request; tithelydev.com/api |
| Planning Center Giving API | Planning Center | Donation tracking, fund management | Free for small churches | OAuth2; developer.planning.center/docs |
| Breeze Giving API | Breeze/Tithely | Contribution tracking, donor records | Paid ($0-99/month) | API key auth; 20 req/min limit |

### Integration Priority
1. **Immediate** — Flutterwave (East Africa M-Pesa/Airtel Money support, best regional fit)
2. **Short-term** — Stripe Connect (international giving, card payments)
3. **Partnership** — Tithe.ly, Planning Center (require church subscriptions)
