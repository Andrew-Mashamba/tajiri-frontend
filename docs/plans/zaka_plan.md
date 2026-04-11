# Zaka (Zakat Calculator) — Implementation Plan

## Overview
Comprehensive Zakat management with guided calculation wizard, asset categories (cash, gold, livestock, agriculture), M-Pesa payment, recipient directory, annual tracking, and educational content tailored for Tanzanian Muslims.

---

## 1. Frontend Architecture

### Directory Structure
```
lib/zaka/
├── zaka_module.dart
├── models/
│   ├── zakat_calculation.dart
│   ├── zakat_asset.dart
│   ├── zakat_payment.dart
│   ├── zakat_recipient.dart
│   └── nisab_threshold.dart
├── services/
│   └── zakat_service.dart           — AuthenticatedDio.instance
├── pages/
│   ├── zakat_home_page.dart
│   ├── calculator_page.dart
│   ├── asset_entry_page.dart
│   ├── calculation_result_page.dart
│   ├── pay_zakat_page.dart
│   ├── payment_history_page.dart
│   ├── find_recipients_page.dart
│   ├── zakat_fitr_page.dart
│   └── education_page.dart
└── widgets/
    ├── nisab_status_card.dart
    ├── asset_category_card.dart
    ├── calculation_summary.dart
    ├── recipient_card.dart
    ├── payment_tile.dart
    └── asnaf_display.dart
```

### Data Models
- **ZakatCalculation** — `id`, `userId`, `totalWealth`, `totalDeductions`, `nisabAmount`, `zakatDue`, `calculatedAt`, `assets` (List<ZakatAsset>). `_parseDouble`.
- **ZakatAsset** — `category` (cash/gold/silver/business/investments/livestock/agriculture/rental), `amount`, `description`. `_parseDouble`.
- **ZakatPayment** — `id`, `userId`, `amount`, `recipientId`, `recipientType` (mosque/organization/individual), `transactionRef`, `paymentMethod`, `paidAt`. `_parseDouble`.
- **ZakatRecipient** — `id`, `name`, `type`, `category` (one of 8 asnaf), `location`, `isVerified`, `description`. `_parseBool`.
- **NisabThreshold** — `goldPricePerGram`, `silverPricePerGram`, `nisabGold`, `nisabSilver`, `currency`, `updatedAt`. `_parseDouble`.

### Service Layer
```dart
Dio get _dio => AuthenticatedDio.instance;
```
- `getDashboard()` — `GET /api/zakat/dashboard`
- `getNisab()` — `GET /api/zakat/nisab`
- `calculateZakat(Map assets)` — `POST /api/zakat/calculate`
- `payZakat(Map data)` — `POST /api/zakat/pay`
- `getPaymentHistory()` — `GET /api/zakat/payments`
- `getRecipients({String? category, double? lat, double? lng})` — `GET /api/zakat/recipients`
- `calculateZakatFitr(int familySize, String foodType)` — `GET /api/zakat/fitr`
- `getEducation()` — `GET /api/zakat/education`
- `generateReceipt(int paymentId)` — `GET /api/zakat/payments/{id}/receipt`

### Pages
- **ZakatHomePage** — Nisab status, estimated Zakat due, last payment, due date countdown
- **CalculatorPage** — Step-by-step wizard: cash > gold > business > investments > livestock > debts > result
- **AssetEntryPage** — Input forms per category with helpful descriptions
- **CalculationResultPage** — Total wealth, deductions, Nisab comparison, Zakat amount
- **PayZakatPage** — Select recipient, M-Pesa payment flow
- **PaymentHistoryPage** — Timeline of payments with recipient, amount, date
- **FindRecipientsPage** — Verified recipients by category and location
- **ZakatFitrPage** — Family count, local food price, amount per person
- **EducationPage** — FAQs, articles, video explanations

### Widgets
- `NisabStatusCard` — Shows wealth vs Nisab threshold with visual indicator
- `AsnafDisplay` — 8 categories of eligible Zakat recipients with icons

---

## 2. UI Design
- #1A1A1A/#666666/#FAFAFA/#FFFFFF monochromatic
- 48dp touch, maxLines+ellipsis, _rounded icons
- Dark stat cards for Zakat due and payment history
- Cards: radius 12-16, subtle shadow

### Main Screen Wireframe
```
┌─────────────────────────────┐
│ ← Zaka                  ⚙️   │
├─────────────────────────────┤
│ ┌─────────────────────────┐ │
│ │ Nisab Status: Above ✅   │ │
│ │ Current Nisab: TZS 4.2M │ │
│ └─────────────────────────┘ │
│                             │
│ ┌───────────┐ ┌───────────┐ │
│ │ Zakat Due │ │ Last Paid │ │
│ │ TZS 185K  │ │ TZS 150K  │ │
│ │           │ │ Jan 2026  │ │
│ └───────────┘ └───────────┘ │
│                             │
│  [  Calculate Zakat  ]      │
│  [  Pay Zakat Now    ]      │
│                             │
│  Due Date: 15 Sha'ban       │
│  ⏱ 120 days remaining       │
│                             │
│ [History] [Recipients] [📖] │
└─────────────────────────────┘
```

---

## 3. Performance Strategy

### SQLite
```sql
CREATE TABLE zakat_calculations(id INTEGER PRIMARY KEY, total_wealth REAL, zakat_due REAL, json_data TEXT, synced_at TEXT);
CREATE TABLE zakat_payments(id INTEGER PRIMARY KEY, amount REAL, recipient_id INTEGER, json_data TEXT, synced_at TEXT);
CREATE TABLE nisab_cache(id INTEGER PRIMARY KEY, gold_price REAL, silver_price REAL, updated_at TEXT);
```
- Stale-while-revalidate: SQLite first, API background
- TTL: Nisab prices — 24 hours, calculations — 1 week, payments — 1 hour
- Offline: read YES, write payments via pending_queue

---

## 4. Backend Implementation

### Database
```sql
CREATE TABLE zakat_calculations(id BIGSERIAL PRIMARY KEY, user_id BIGINT, total_wealth DECIMAL(18,2), total_deductions DECIMAL(18,2), nisab_amount DECIMAL(18,2), zakat_due DECIMAL(18,2), assets JSONB, calculated_at TIMESTAMP DEFAULT NOW());

CREATE TABLE zakat_payments(id BIGSERIAL PRIMARY KEY, user_id BIGINT, amount DECIMAL(15,2), recipient_id BIGINT, recipient_type VARCHAR(30), transaction_ref VARCHAR(100), payment_method VARCHAR(20), paid_at TIMESTAMP DEFAULT NOW());

CREATE TABLE zakat_recipients(id BIGSERIAL PRIMARY KEY, name VARCHAR(200), type VARCHAR(30), asnaf_category VARCHAR(50), location VARCHAR(200), lat DOUBLE PRECISION, lng DOUBLE PRECISION, is_verified BOOLEAN DEFAULT TRUE, description TEXT, created_at TIMESTAMP DEFAULT NOW());

CREATE TABLE nisab_prices(id BIGSERIAL PRIMARY KEY, gold_price_per_gram DECIMAL(12,2), silver_price_per_gram DECIMAL(12,2), currency VARCHAR(5) DEFAULT 'TZS', updated_at TIMESTAMP DEFAULT NOW());

CREATE TABLE zakat_due_dates(id BIGSERIAL PRIMARY KEY, user_id BIGINT UNIQUE, hijri_month INTEGER, hijri_day INTEGER);
```

### API Endpoints
| Method | Endpoint | Description | Auth |
|--------|----------|-------------|------|
| GET | /api/zakat/dashboard | Zakat overview | Bearer |
| GET | /api/zakat/nisab | Current Nisab prices | Bearer |
| POST | /api/zakat/calculate | Calculate Zakat | Bearer |
| POST | /api/zakat/pay | Pay Zakat via M-Pesa | Bearer |
| GET | /api/zakat/payments | Payment history | Bearer |
| GET | /api/zakat/recipients | Find recipients | Bearer |
| GET | /api/zakat/fitr | Zakat al-Fitr calc | Bearer |
| GET | /api/zakat/education | Educational content | Bearer |
| GET | /api/zakat/payments/{id}/receipt | Payment receipt | Bearer |

### Controller
`app/Http/Controllers/Api/ZakatController.php` — DB facade with Nisab price feed integration and M-Pesa callback.

---

## 5. Integration Wiring
- **WalletService** — M-Pesa payment for Zakat distribution
- **ContributionService** — Zakat-eligible crowdfunding campaigns
- **NotificationService** — annual due date reminders, Zakat al-Fitr before Eid
- **Ramadan** — Zakat al-Fitr calculator linked during Ramadan
- **Kalenda Hijri** — annual due date on Islamic calendar
- **Tafuta Msikiti** — mosques accepting Zakat in listings
- **ProfileService** — private giving history on faith profile

---

## 6. Implementation Phases
### Phase 1: Foundation (Week 1)
- Data models, service layer, SQLite schema
- Nisab price feed integration
- Backend tables and calculation logic

### Phase 2: Core UI (Week 2)
- Calculator wizard (step-by-step asset entry)
- Calculation result with Nisab comparison
- Zakat dashboard with status cards

### Phase 3: Integration (Week 3)
- M-Pesa payment flow
- Recipient directory with verification
- Payment history and receipts

### Phase 4: Polish (Week 4)
- Zakat al-Fitr calculator
- Educational content (FAQs, articles)
- Offline support, livestock and agriculture calculators

---

## 7. External APIs & Integrations

| API | Provider | Purpose | Pricing | Integration Notes |
|-----|----------|---------|---------|-------------------|
| Halal Terminal API | Halal Terminal | Shariah screening, zakat calculation, purification | Freemium | 5 methodologies (AAOIFI, DJIM, FTSE, MSCI, S&P); halalterminal.com |
| Exchange Rate API | exchangerate-api.com | Currency conversion for zakat in local currency | Free (1500 req/month) | Convert zakat amounts to KES, TZS, UGX |
| Gold/Silver Price APIs | Various (metals-api.com) | Nisab threshold calculation (gold/silver prices) | Freemium | Nisab = 87.48g gold or 612.36g silver; real-time prices |
| Zoya Shariah Compliance API | Zoya Finance | Stock/ETF screening, per-company zakat | Paid (subscription) | 20k+ stocks/funds; zoya.finance/api |
| Flutterwave API | Flutterwave | Zakat payment processing (M-Pesa, bank) | ~1.4% local | East Africa payment support |

### Integration Priority
1. **Immediate** — Free APIs (Exchange Rate API for currency conversion, local zakat calculation)
2. **Short-term** — Freemium APIs (Halal Terminal for Shariah screening, metals API for Nisab)
3. **Partnership** — Zoya (paid stock screening), Flutterwave (payment processing)
