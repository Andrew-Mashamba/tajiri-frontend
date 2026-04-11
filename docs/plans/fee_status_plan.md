# Fee Status / Ada — Implementation Plan

## Overview
Fee balance tracker with M-Pesa payment integration, HESLB loan status monitoring, payment history, clearance checklist, and sponsor management. Displays fee breakdown by category, payment receipts, installment planning, deadline reminders, and emergency alerts when balance blocks exam entry or registration.

---

## 1. Frontend Architecture

### Directory Structure
```
lib/fee_status/
├── fee_status_module.dart
├── models/
│   ├── fee_balance.dart
│   ├── payment.dart
│   ├── heslb_status.dart
│   ├── clearance_item.dart
│   └── fee_sponsor.dart
├── services/
│   └── fee_status_service.dart      — AuthenticatedDio.instance
├── pages/
│   ├── fee_dashboard_page.dart
│   ├── balance_breakdown_page.dart
│   ├── payment_history_page.dart
│   ├── make_payment_page.dart
│   ├── heslb_status_page.dart
│   ├── payment_plan_page.dart
│   ├── clearance_page.dart
│   ├── fee_statement_page.dart
│   ├── sponsor_management_page.dart
│   └── fee_reminders_page.dart
└── widgets/
    ├── balance_card.dart
    ├── payment_tile.dart
    ├── clearance_checklist.dart
    ├── payment_progress_bar.dart
    ├── deadline_countdown.dart
    └── sponsor_chip.dart
```

### Data Models
```dart
class FeeBalance {
  final double totalFee, totalPaid, balance;
  final List<FeeComponent> breakdown;
  final String? nextDeadline;
  factory FeeBalance.fromJson(Map<String, dynamic> j) => FeeBalance(
    totalFee: _parseDouble(j['total_fee']) ?? 0,
    totalPaid: _parseDouble(j['total_paid']) ?? 0,
    balance: _parseDouble(j['balance']) ?? 0,
    breakdown: (j['breakdown'] as List?)?.map((b) => FeeComponent.fromJson(b)).toList() ?? [],
  );
}

class FeeComponent { String category; double amount, paid; }  // tuition, accommodation, exam, union, medical
class Payment { int id; double amount; String method, reference; DateTime date; String? receiptUrl; }
class HeslbStatus { double allocated, disbursed, remaining; DateTime? lastDisbursement; String status; }
class ClearanceItem { String department; bool cleared; String? note; }  // finance, library, accommodation, student_affairs
class FeeSponsor { int id; String name, type; double amount; }  // heslb, family, bursary, self
```

### Service Layer
```dart
class FeeStatusService {
  static Future<FeeBalance> getBalance(String token);                         // GET /api/fees/balance
  static Future<List<Payment>> getPaymentHistory(String token);               // GET /api/fees/payments
  static Future<Map> initiateMpesaPayment(String token, Map body);            // POST /api/fees/pay/mpesa
  static Future<String> downloadReceipt(String token, int paymentId);         // GET /api/fees/payments/{id}/receipt
  static Future<HeslbStatus> getHeslbStatus(String token);                    // GET /api/fees/heslb
  static Future<List<ClearanceItem>> getClearanceStatus(String token);         // GET /api/fees/clearance
  static Future<Map> getPaymentPlan(String token, double remaining, int inst); // GET /api/fees/plan?remaining=&installments=
  static Future<String> generateStatement(String token);                       // GET /api/fees/statement (PDF URL)
  static Future<List<FeeSponsor>> getSponsors(String token);                   // GET /api/fees/sponsors
  static Future<void> addSponsor(String token, Map body);                      // POST /api/fees/sponsors
}
```

### Pages & Widgets
- **FeeDashboardPage**: total balance hero card, next deadline, recent payments, clearance status, quick pay
- **BalanceBreakdownPage**: detailed table of fee components with paid/unpaid per category
- **PaymentHistoryPage**: scrollable list with receipt download button per transaction
- **MakePaymentPage**: method selection (M-Pesa, bank), amount input, auto-filled paybill, confirmation
- **HeslbStatusPage**: loan allocation, disbursement history, remaining entitlement
- **PaymentPlanPage**: installment calculator with suggested dates and amounts
- **ClearancePage**: department checklist with completion indicators
- **FeeStatementPage**: formatted statement preview with download/share

---

## 2. UI Design
- Monochromatic: #1A1A1A / #666666 / #FAFAFA / #FFFFFF
- 48dp touch targets, maxLines + ellipsis, _rounded icons
- Dark hero card: balance amount large text, progress bar paid vs total
- Emergency alert: red border when balance blocks registration/exams

### Main Screen Wireframe
```
┌──────────────────────────────┐
│  Fee Status             [⋮] │
├──────────────────────────────┤
│ ┌──────────────────────────┐ │
│ │   Balance Due             │ │
│ │   TZS 450,000            │ │
│ │   ████████░░░░ 70% paid  │ │
│ │   Next: Exam entry Apr 20│ │
│ └──────────────────────────┘ │
│                              │
│ [Pay Now] [Statement] [HESLB]│
│                              │
│ CLEARANCE                    │
│ ✅ Finance   ✅ Library       │
│ ❌ Accommodation  ✅ Student  │
│                              │
│ RECENT PAYMENTS              │
│ ┌──────────────────────────┐ │
│ │ M-Pesa  TZS 200,000     │ │
│ │ Mar 15  Ref: XY12345     │ │
│ ├──────────────────────────┤ │
│ │ HESLB   TZS 1,050,000   │ │
│ │ Feb 1   Disbursement     │ │
│ └──────────────────────────┘ │
└──────────────────────────────┘
```

---

## 3. Performance Strategy

### SQLite
```sql
CREATE TABLE fee_balance(id INTEGER PRIMARY KEY, total_fee REAL, total_paid REAL, balance REAL, json_data TEXT, synced_at TEXT);
CREATE TABLE payments(id INTEGER PRIMARY KEY, amount REAL, method TEXT, reference TEXT, date TEXT, json_data TEXT, synced_at TEXT);
CREATE INDEX idx_payments_date ON payments(date);

CREATE TABLE clearance_items(id INTEGER PRIMARY KEY, department TEXT, cleared INTEGER, json_data TEXT, synced_at TEXT);
```
- SQLite first, API background refresh (stale-while-revalidate)
- Offline read: YES — balance, payment history, clearance status cached
- Offline write: NO — payments require live API; queue payment intent only

---

## 4. Backend Implementation

### Database (PostgreSQL)
```sql
CREATE TABLE fee_accounts(
  id SERIAL PRIMARY KEY, user_id INT REFERENCES users(id),
  institution VARCHAR(255), program VARCHAR(255),
  total_fee DECIMAL(12,2), academic_year VARCHAR(20),
  created_at TIMESTAMP DEFAULT NOW()
);
CREATE TABLE fee_components(
  id SERIAL PRIMARY KEY, account_id INT REFERENCES fee_accounts(id),
  category VARCHAR(100), amount DECIMAL(12,2)
);
CREATE TABLE fee_payments(
  id SERIAL PRIMARY KEY, account_id INT REFERENCES fee_accounts(id),
  amount DECIMAL(12,2), method VARCHAR(30),  -- mpesa, bank, heslb
  reference VARCHAR(100), receipt_url TEXT,
  paid_at TIMESTAMP DEFAULT NOW()
);
CREATE TABLE heslb_records(
  id SERIAL PRIMARY KEY, user_id INT REFERENCES users(id),
  allocated DECIMAL(12,2), disbursed DECIMAL(12,2),
  status VARCHAR(30), last_disbursement TIMESTAMP
);
CREATE TABLE clearance_status(
  id SERIAL PRIMARY KEY, user_id INT REFERENCES users(id),
  department VARCHAR(100), cleared BOOLEAN DEFAULT FALSE,
  note TEXT, updated_at TIMESTAMP DEFAULT NOW(),
  UNIQUE(user_id, department)
);
CREATE TABLE fee_sponsors(
  id SERIAL PRIMARY KEY, user_id INT REFERENCES users(id),
  name VARCHAR(255), type VARCHAR(50), amount DECIMAL(12,2)
);
```

### API Endpoints
| Method | Endpoint | Description | Auth |
|--------|----------|-------------|------|
| GET | /api/fees/balance | Current balance + breakdown | Bearer |
| GET | /api/fees/payments | Payment history | Bearer |
| POST | /api/fees/pay/mpesa | Initiate M-Pesa payment | Bearer |
| GET | /api/fees/payments/{id}/receipt | Download receipt PDF | Bearer |
| GET | /api/fees/heslb | HESLB loan status | Bearer |
| GET | /api/fees/clearance | Clearance checklist | Bearer |
| GET | /api/fees/plan | Payment plan calculator | Bearer |
| GET | /api/fees/statement | Generate fee statement PDF | Bearer |
| GET | /api/fees/sponsors | List sponsors | Bearer |
| POST | /api/fees/sponsors | Add sponsor | Bearer |

### Controller
`app/Http/Controllers/Api/FeeStatusController.php`

---

## 5. Integration Wiring
- WalletService — M-Pesa payments flow through TAJIRI wallet infrastructure
- NotificationService + FCM — deadline reminders, HESLB disbursement alerts, emergency warnings
- CalendarService — payment deadlines synced to personal calendar
- MessageService — share fee statement with parents/sponsors via chat
- results module — GPA linked to HESLB eligibility; low GPA triggers funding risk alert
- my_class module — fee clearance affects class registration visibility
- campus_news module — fee deadline announcements linked to fee payment
- my_wallet module — fee payments integrated with budget tracking

---

## 6. Implementation Phases

### Phase 1 — Balance & Payments (Week 1-2)
- [ ] FeeBalance, Payment models, service, SQLite cache
- [ ] Fee dashboard with balance hero card
- [ ] Balance breakdown by category
- [ ] Payment history with receipts

### Phase 2 — M-Pesa & HESLB (Week 3)
- [ ] M-Pesa payment integration (auto-fill paybill + reference)
- [ ] HESLB status page with disbursement tracking
- [ ] Payment receipt download (PDF)
- [ ] Emergency balance alerts

### Phase 3 — Planning & Clearance (Week 4)
- [ ] Payment plan calculator with installments
- [ ] Clearance checklist page
- [ ] Fee statement generator (PDF)
- [ ] Deadline reminders via push notifications

### Phase 4 — Advanced (Week 5)
- [ ] Sponsor management (multiple funding sources)
- [ ] Share fee status with parents (secure link)
- [ ] Historical fee records by semester
- [ ] Fee increase alerts
- [ ] Auto-payment scheduling

---

## 7. External APIs & Integrations

| API | Provider | Purpose | Pricing | Integration Notes |
|-----|----------|---------|---------|-------------------|
| M-Pesa API (Vodacom TZ) | Vodacom Tanzania | Mobile money fee payments, C2B collection | Transaction-based fees | Open API with sandbox. C2B (collection), B2C (refunds). Register at business.m-pesa.com. **Essential for Tanzania -- most students pay fees via M-Pesa.** |
| Tigo Pesa API | MIC Tanzania | Mobile money payments | Transaction-based fees | Alternative mobile money for broader coverage. |
| Airtel Money API | Airtel Tanzania | Mobile money payments | Transaction-based fees | Third mobile money option for coverage. |
| Flutterwave API | Flutterwave | Payment aggregation (M-Pesa, cards, bank transfers) | 1.4% per transaction (Africa) | Single integration for multiple payment methods. Good aggregator. |
| DPO Group / Network International | DPO | Payment gateway, card and mobile money | Transaction-based | Card and mobile money processing with Tanzania presence. |
| HESLB OLAS Portal | HESLB (heslb.go.tz) | Student loan status, allocation tracking | No public API | Web portal at olas.heslb.go.tz. **No API -- would need web scraping or partnership.** HESLB allocated TZS 426.5B to 135,240 students in 2025/26. |

**Tanzania context:** HESLB has NO public API. Students check loan status via OLAS web portal. For fee payments, M-Pesa API (Vodacom) is essential. Consider building HESLB status scraper with user consent.

### Integration Priority
1. **Immediate** -- M-Pesa Open API (Vodacom Tanzania, essential for fee collection with sandbox for testing)
2. **Short-term** -- Flutterwave API (payment aggregation for M-Pesa + cards + bank), Tigo Pesa/Airtel Money (broader mobile money coverage)
3. **Partnership** -- HESLB official data access (formal partnership for loan status API), university fee portal integration (per-institution)
