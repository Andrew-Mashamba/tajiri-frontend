# TRA (Tax Services) — Implementation Plan

## Overview
Tax management module for Tanzania Revenue Authority. Provides TIN registration/lookup, multi-type tax calculators (PAYE, VAT, corporate, presumptive, capital gains), guided return filing, M-Pesa tax payments, compliance dashboard, TCC applications, deadline calendar with reminders, small business tax guides, EFD receipt verification, and import duty calculator.

---

## 1. Frontend Architecture

### Directory Structure
```
lib/tra/
├── tra_module.dart
├── models/
│   ├── tax_models.dart
│   ├── return_models.dart
│   └── payment_models.dart
├── services/
│   └── tra_service.dart
├── pages/
│   ├── tra_home_page.dart
│   ├── tax_calculator_page.dart
│   ├── file_return_page.dart
│   ├── payment_page.dart
│   ├── payment_history_page.dart
│   ├── compliance_dashboard_page.dart
│   ├── deadline_calendar_page.dart
│   ├── small_business_guide_page.dart
│   ├── tcc_page.dart
│   └── tax_news_page.dart
└── widgets/
    ├── tin_card.dart
    ├── compliance_badge.dart
    ├── tax_breakdown.dart
    ├── deadline_tile.dart
    └── efd_scanner.dart
```

### Data Models
- `TaxProfile` — userId, tin, complianceStatus (compliant/pending/overdue), registeredTaxTypes, tccStatus
- `TaxReturn` — id, tin, taxType, period, incomeData, deductions, calculatedTax, status (draft/submitted/assessed), submittedAt
- `TaxPayment` — id, tin, taxType, amount, referenceNumber, paymentMethod, paidAt, receiptUrl
- `TaxDeadline` — id, taxType, dueDate, period, status (upcoming/due/overdue/filed)
- `TccApplication` — id, tin, status (applied/processing/issued/expired), issuedDate, expiryDate, downloadUrl

### Service Layer
```dart
Dio get _dio => AuthenticatedDio.instance;
```
| Method | Verb | Endpoint | Return |
|--------|------|----------|--------|
| `registerTin(data)` | POST | `/api/tra/tin` | `SingleResult<TinRegistration>` |
| `lookupTin(nidaOrPassport)` | GET | `/api/tra/tin/lookup` | `SingleResult<TaxProfile>` |
| `calculateTax(type, params)` | POST | `/api/tra/calculate` | `SingleResult<TaxBreakdown>` |
| `fileReturn(data)` | POST | `/api/tra/returns` | `SingleResult<TaxReturn>` |
| `getReturns(tin, year)` | GET | `/api/tra/returns` | `PaginatedResult<TaxReturn>` |
| `makePayment(data)` | POST | `/api/tra/payments` | `SingleResult<TaxPayment>` |
| `getPaymentHistory(tin)` | GET | `/api/tra/payments` | `PaginatedResult<TaxPayment>` |
| `getCompliance(tin)` | GET | `/api/tra/compliance` | `SingleResult<ComplianceStatus>` |
| `applyTcc(tin)` | POST | `/api/tra/tcc` | `SingleResult<TccApplication>` |
| `getDeadlines(tin)` | GET | `/api/tra/deadlines` | `PaginatedResult<TaxDeadline>` |
| `verifyEfd(qrData)` | GET | `/api/tra/efd/verify` | `SingleResult<EfdVerification>` |

### Pages
- **TraHomePage** — TIN card, compliance badge, upcoming deadlines, quick pay
- **TaxCalculatorPage** — Select type, input parameters, detailed breakdown with rates
- **FileReturnPage** — Multi-step wizard: period > income > deductions > review > submit
- **PaymentPage** — Amount, tax type, M-Pesa STK push, confirmation
- **PaymentHistoryPage** — Filterable transaction list with receipts
- **ComplianceDashboardPage** — Traffic light per tax type, outstanding items, TCC status
- **DeadlineCalendarPage** — Month view with due dates, filed/unfiled indicators
- **SmallBusinessGuidePage** — Decision tree: business type questions > applicable taxes

### Widgets
- `TinCard` — TIN number display, copy action, compliance indicator
- `ComplianceBadge` — Green/yellow/red status with label
- `TaxBreakdown` — Tiered rate table with calculated amounts
- `DeadlineTile` — Tax type, due date, status, file/pay action
- `EfdScanner` — QR code scanner for EFD receipt verification

---

## 2. UI Design
- Palette: #1A1A1A / #666666 / #FAFAFA / #FFFFFF
- Cards: BorderRadius.circular(12-16), subtle shadow
- 48dp touch targets, maxLines+ellipsis, _rounded icons
- Loading: CircularProgressIndicator(strokeWidth: 2, color: _kPrimary)

### Main Screen Wireframe
```
┌─────────────────────────┐
│ ◀  TRA Services     🔔  │
├─────────────────────────┤
│ ┌─────────────────────┐ │
│ │ TIN: 123-456-789    │ │
│ │ Status: ● Compliant │ │
│ │ TCC: Valid to Dec 26 │ │
│ └─────────────────────┘ │
│                         │
│ Upcoming Deadlines      │
│ ├─ 🔴 VAT Apr - Due 20│
│ ├─ 🟡 PAYE - Due 7th  │
│ └─ 🟢 Income Tax ✓    │
│                         │
│ [Calculate] [File]      │
│ [Pay]    [History]      │
│                         │
│ Quick Links             │
│ ├─ Small Business Guide│
│ ├─ EFD Receipt Check   │
│ ├─ Import Duty Calc    │
│ └─ Tax News            │
└─────────────────────────┘
```

---

## 3. Performance Strategy

### SQLite Local Storage
```sql
CREATE TABLE tra_payments(id INTEGER PRIMARY KEY, tin TEXT, tax_type TEXT, json_data TEXT, synced_at TEXT);
CREATE INDEX idx_tra_payments_tin ON tra_payments(tin);
CREATE TABLE tra_deadlines(id INTEGER PRIMARY KEY, tin TEXT, due_date TEXT, json_data TEXT, synced_at TEXT);
CREATE TABLE tra_guides(id INTEGER PRIMARY KEY, category TEXT, json_data TEXT, synced_at TEXT);
```

### Caching
- Load from SQLite first (<5ms) then API background refresh
- TTL: Payment history 1h, compliance 1h, deadlines 6h, guides 7d
- Offline read: YES — calculators, small business guides, tariff schedules
- Offline write: pending_queue for return drafts

---

## 4. Backend Implementation

### Database (PostgreSQL)
```sql
CREATE TABLE tra_profiles (
    id BIGSERIAL PRIMARY KEY, user_id BIGINT REFERENCES users(id),
    tin TEXT UNIQUE NOT NULL, registered_tax_types JSONB,
    compliance_status TEXT DEFAULT 'pending',
    created_at TIMESTAMP DEFAULT NOW(), updated_at TIMESTAMP DEFAULT NOW()
);

CREATE TABLE tra_returns (
    id BIGSERIAL PRIMARY KEY, tin TEXT NOT NULL,
    tax_type TEXT NOT NULL, period TEXT NOT NULL,
    income_data JSONB, deductions JSONB, calculated_tax DECIMAL(15,2),
    status TEXT DEFAULT 'draft', submitted_at TIMESTAMP,
    created_at TIMESTAMP DEFAULT NOW(), updated_at TIMESTAMP DEFAULT NOW()
);

CREATE TABLE tra_payments (
    id BIGSERIAL PRIMARY KEY, tin TEXT NOT NULL,
    tax_type TEXT NOT NULL, amount DECIMAL(15,2) NOT NULL,
    reference_number TEXT UNIQUE, payment_method TEXT,
    receipt_url TEXT, paid_at TIMESTAMP DEFAULT NOW()
);
```

### API Endpoints
| Method | Endpoint | Description | Auth |
|--------|----------|-------------|------|
| POST | /api/tra/tin | Register TIN | Yes |
| GET | /api/tra/tin/lookup | Lookup TIN | Yes |
| POST | /api/tra/calculate | Calculate tax | Yes |
| POST | /api/tra/returns | File return | Yes |
| GET | /api/tra/returns | Return history | Yes |
| POST | /api/tra/payments | Make payment | Yes |
| GET | /api/tra/payments | Payment history | Yes |
| GET | /api/tra/compliance | Compliance status | Yes |
| POST | /api/tra/tcc | Apply for TCC | Yes |
| GET | /api/tra/deadlines | Tax deadlines | Yes |
| GET | /api/tra/efd/verify | Verify EFD receipt | Yes |

### Controller
- `app/Http/Controllers/Api/TraController.php`
- DB facade, try/catch, `{"success": true/false, "data": ..., "message": "..."}`

---

## 5. Integration Wiring
- **WalletService** — Primary payment for all tax types; payment history with TRA references
- **NotificationService + FCMService** — Filing deadline reminders, payment confirmations, compliance alerts
- **CalendarService** — Filing/payment deadlines synced to calendar with recurring reminders
- **ProfileService** — Tax compliance badge for marketplace businesses
- **LiveUpdateService** — Real-time TCC application status via Firestore
- **Cross-module: brela** — Auto-prompt TIN after company registration
- **Cross-module: nida** — NIDA number for TIN registration
- **Cross-module: land_office** — Stamp duty + capital gains on property transfers

---

## 6. Implementation Phases
### Phase 1: Foundation (Week 1)
- Data models, service layer, SQLite schema, module scaffold
- TIN registration/lookup, tax calculator engine

### Phase 2: Core UI (Week 2)
- TRA home with TIN card, compliance dashboard, deadline calendar
- Tax calculator UI, return filing wizard

### Phase 3: Integration (Week 3)
- WalletService payment integration, FCM deadline reminders
- EFD receipt scanner, TCC application flow

### Phase 4: Polish (Week 4)
- Small business guide decision tree, import duty calculator
- PAYE verification, offline calculator caching, tax news feed

---

## 7. External APIs & Integrations

| API | Provider | Purpose | Pricing | Integration Notes |
|-----|----------|---------|---------|-------------------|
| TRA VFD API | Tanzania Revenue Authority | Virtual Fiscal Device integration, Z-reports, receipt verification | Free (for registered taxpayers) | tra-docs.netlify.app — XML-based (not REST), token auth, registration via TIN |
| TRA E-Filing Portal | Tanzania Revenue Authority | Electronic tax return filing reference | Free for taxpayers | efiling.tra.go.tz — web portal only, SMS verification |
| TaxDo TIN Validation | TaxDo | Tanzania TIN format validation (9 digits) | Free (validation rules) | taxdo.com — format validation only, not live verification |
| AzamPay API | AzamPay | Mobile money payments for tax obligations | Per-transaction | Dart SDK on pub.dev (azampaytanzania) |
| Selcom API | Selcom | Payment aggregation for tax-related payments | Commission-based | developers.selcommobile.com — REST API |
| ClickPesa BillPay API | ClickPesa | GePG control number for tax payments | Contact for pricing | docs.clickpesa.com |
| Smile ID | Smile Identity | Taxpayer identity verification | Pay-per-verification | docs.usesmileid.com |

### Integration Priority
1. **Immediate** — TRA VFD API (free for registered taxpayers, documented), TaxDo TIN validation (free format rules), AzamPay (Dart SDK)
2. **Short-term** — Selcom API for payment processing, ClickPesa for GePG control numbers, Smile ID for taxpayer verification
3. **Partnership** — TRA direct API for E-Filing integration (web portal only, no public REST API), TRA CDLS/CMVRS systems
