# HESLB (Higher Education Students' Loans Board) — Implementation Plan

## Overview

The HESLB module provides Tanzanian students and graduates a mobile interface to the Higher Education Students' Loans Board. It tracks OLAS loan application status, monitors disbursement schedules (tuition and living allowance), displays current loan balance with interest, calculates repayment at 15% of gross salary, enables M-Pesa loan repayment, shows payment history with downloadable statements, and manages clearance letter requests. It addresses the critical pain of OLAS portal crashes and loan balance opacity.

---

## 1. Frontend Architecture

### Directory Structure
```
lib/heslb/
├── heslb_module.dart                  — Entry point & route registration
├── models/
│   ├── loan_models.dart               — LoanSummary, LoanBalance, Interest
│   ├── application_models.dart        — ApplicationStatus, Allocation
│   ├── disbursement_models.dart       — Disbursement, DisbursementType
│   ├── repayment_models.dart          — Repayment, RepaymentSchedule
│   └── clearance_models.dart          — ClearanceRequest, ClearanceStatus
├── services/
│   └── heslb_service.dart             — API service using AuthenticatedDio
├── pages/
│   ├── heslb_dashboard_page.dart      — Balance, next payment, disbursement
│   ├── application_status_page.dart   — Multi-step progress tracker
│   ├── disbursement_timeline_page.dart — Expected vs actual dates
│   ├── balance_repayment_page.dart    — Balance, monthly amount, projection
│   ├── pay_now_page.dart              — M-Pesa payment screen
│   ├── payment_history_page.dart      — Chronological payments list
│   ├── application_guide_page.dart    — Document checklist, walkthrough
│   └── clearance_request_page.dart    — Request form and status tracker
└── widgets/
    ├── loan_summary_widget.dart        — Balance, repaid, remaining
    ├── disbursement_card_widget.dart   — Component with status indicator
    ├── repayment_calculator_widget.dart — Salary input with calculation
    ├── progress_tracker_widget.dart    — Application step indicator
    └── payment_card_widget.dart        — Payment entry with type badge
```

### Data Models
- **LoanSummary**: totalBorrowed, totalRepaid, remainingBalance, interestAccrued, monthlyPayment, expectedClearanceDate, repaymentStreak. `factory LoanSummary.fromJson()` with `_parseDouble`.
- **ApplicationStatus**: id, applicantName, examNumber, institution, program, status (submitted/under_review/means_testing/approved/denied), allocation (tuition, meals, accommodation, books, fieldWork), appealStatus. `factory ApplicationStatus.fromJson()`.
- **Disbursement**: id, type (tuition/living_allowance/books/field), amount, expectedDate, actualDate, status (pending/processing/paid), recipient (university/student). `factory Disbursement.fromJson()`.
- **Repayment**: id, amount, type (employer_deduction/self_payment/mpesa), date, referenceNumber, balanceAfter. `factory Repayment.fromJson()`.
- **ClearanceRequest**: id, status (submitted/processing/ready/collected), submittedAt, readyAt. `factory ClearanceRequest.fromJson()`.

### Service Layer
- `getLoanSummary()` — GET `/api/heslb/summary`
- `getApplicationStatus()` — GET `/api/heslb/application`
- `getDisbursements()` — GET `/api/heslb/disbursements`
- `getRepaymentHistory()` — GET `/api/heslb/repayments`
- `calculateRepayment(double salary)` — POST `/api/heslb/calculate`
- `makePayment(Map paymentData)` — POST `/api/heslb/pay`
- `getPaymentSchedule()` — GET `/api/heslb/schedule`
- `requestClearance()` — POST `/api/heslb/clearance`
- `getClearanceStatus()` — GET `/api/heslb/clearance`
- `checkEligibility(Map params)` — POST `/api/heslb/eligibility`
- `getApplicationGuide()` — GET `/api/heslb/guide`
- `checkOlasStatus()` — GET `/api/heslb/olas-status`

### Pages & Screens
- **Dashboard**: Loan balance prominently displayed, progress bar (repaid vs total), next payment due, disbursement status, repayment streak.
- **Application Status**: Step tracker (submitted > under review > means testing > approved/denied), allocation breakdown by component.
- **Disbursement Timeline**: Visual timeline with expected vs actual dates, status per component, university fee status.
- **Balance & Repayment**: Current balance, salary-based calculator, payoff projection chart, monthly amount.
- **Pay Now**: Amount options (minimum, custom), M-Pesa/Tigo/Airtel picker, payment confirmation.
- **Payment History**: Chronological list with type badges (employer/self/mpesa), downloadable statement.
- **Application Guide**: Numbered steps with document checklist, eligibility criteria, OLAS link with status indicator.

### Widgets
- `LoanSummaryWidget` — Circular progress: repaid/total with balance in center
- `DisbursementCardWidget` — Component name, amount, date, status dot (green/yellow/red)
- `RepaymentCalculatorWidget` — Salary input slider, monthly deduction auto-calculated
- `ProgressTrackerWidget` — Horizontal stepper with labeled steps
- `PaymentCardWidget` — Date, amount, type badge (employer=blue, mpesa=green, self=grey)

---

## 2. UI Design

- Dashboard: Balance as hero number, progress arc below
- Disbursement: Timeline with dots and connecting lines
- Calculator: Slider with live result update
- Payment: Large amount input, payment method cards

### Key Screen Mockup — Dashboard
```
┌─────────────────────────────┐
│  SafeArea                   │
│  My HESLB Loan              │
│  ┌───────────────────────┐  │
│  │    ╭──────────╮       │  │
│  │    │ TZS      │       │  │
│  │    │ 4,250,000│       │  │
│  │    │ remaining│       │  │
│  │    ╰──────────╯       │  │
│  │  ████████░░░░ 62%     │  │
│  │  Repaid: TZS 6.9M    │  │
│  └───────────────────────┘  │
│  Next Payment: TZS 187,500 │
│  Due: 30 April 2026        │
│  [Pay Now]                  │
│                             │
│  ── Disbursement Status ──  │
│  ✓ Tuition: Paid to UDSM  │
│  ⏳ Living: Processing     │
│  ── Repayment Streak ────  │
│  12 months consecutive     │
└─────────────────────────────┘
```

---

## 3. Performance Strategy

### Local-First with SQLite
```dart
// Table: heslb_loan
// Columns: id INTEGER PRIMARY KEY, user_id INTEGER, json_data TEXT, synced_at TEXT
// Table: heslb_payments
// Columns: id INTEGER PRIMARY KEY, amount REAL, type TEXT, payment_date TEXT, json_data TEXT, synced_at TEXT
// Indexes: payment_date
```

### Stale-While-Revalidate
- Loan summary: cache TTL 1 hour
- Disbursements: cache TTL 6 hours
- Payment history: cache TTL 1 hour
- Application status: cache TTL 30 minutes (during application season)
- OLAS status: cache TTL 5 minutes

### Offline Support
- Read: Loan summary, payment history, application guide, disbursement timeline
- Write: Payment requests require connectivity
- Sync: Balance refresh on reconnect

### Media Caching
- Application document photos: cached locally until upload
- Guide illustrations: pre-cached

---

## 4. Backend Implementation

### Database Tables
```sql
CREATE TABLE heslb_loans (
    id BIGSERIAL PRIMARY KEY,
    user_id BIGINT REFERENCES users(id) UNIQUE,
    exam_number VARCHAR(50),
    institution VARCHAR(255),
    program VARCHAR(255),
    total_borrowed DECIMAL(15,2),
    total_repaid DECIMAL(15,2),
    interest_accrued DECIMAL(15,2),
    monthly_payment DECIMAL(12,2),
    application_status VARCHAR(30),
    allocation JSONB,
    expected_clearance_date DATE,
    created_at TIMESTAMP DEFAULT NOW(),
    updated_at TIMESTAMP DEFAULT NOW()
);

CREATE TABLE heslb_disbursements (
    id BIGSERIAL PRIMARY KEY,
    loan_id BIGINT REFERENCES heslb_loans(id),
    type VARCHAR(30),
    amount DECIMAL(12,2),
    expected_date DATE,
    actual_date DATE,
    status VARCHAR(20) DEFAULT 'pending',
    recipient VARCHAR(100),
    created_at TIMESTAMP DEFAULT NOW()
);

CREATE TABLE heslb_repayments (
    id BIGSERIAL PRIMARY KEY,
    loan_id BIGINT REFERENCES heslb_loans(id),
    amount DECIMAL(12,2),
    type VARCHAR(30),
    payment_date DATE,
    reference_number VARCHAR(50),
    balance_after DECIMAL(15,2),
    created_at TIMESTAMP DEFAULT NOW()
);

CREATE TABLE heslb_clearance_requests (
    id BIGSERIAL PRIMARY KEY,
    loan_id BIGINT REFERENCES heslb_loans(id),
    status VARCHAR(20) DEFAULT 'submitted',
    submitted_at TIMESTAMP DEFAULT NOW(),
    ready_at TIMESTAMP
);
```

### API Endpoints
| Method | Endpoint | Description | Auth |
|--------|----------|-------------|------|
| GET | /api/heslb/summary | Loan summary | Yes |
| GET | /api/heslb/application | Application status | Yes |
| GET | /api/heslb/disbursements | Disbursement list | Yes |
| GET | /api/heslb/repayments | Payment history | Yes |
| POST | /api/heslb/calculate | Calculate repayment | Yes |
| POST | /api/heslb/pay | Make payment | Yes |
| GET | /api/heslb/schedule | Payment schedule | Yes |
| POST | /api/heslb/clearance | Request clearance | Yes |
| GET | /api/heslb/clearance | Clearance status | Yes |
| POST | /api/heslb/eligibility | Check eligibility | No |
| GET | /api/heslb/guide | Application guide | No |
| GET | /api/heslb/olas-status | OLAS portal status | No |

### Controller
- File: `app/Http/Controllers/Api/HeslbController.php`
- Pattern: DB facade, try/catch, `{"success": true, "data": ...}` responses
- Requires MOU with HESLB for loan data access

### Background Jobs
- Monthly repayment reminder notifications (5 days before due)
- Disbursement processing notification
- OLAS availability monitoring (every 5 minutes during application season)
- Interest recalculation (monthly)
- Employer deduction verification reconciliation

---

## 5. Integration Wiring

- **Wallet**: Loan repayment via M-Pesa/Tigo/Airtel STK push. Scheduled auto-payments. GePG integration.
- **Notifications**: Disbursement alerts, repayment reminders, OLAS status, application updates.
- **Groups**: University student groups, alumni groups, HESLB tips communities.
- **Messaging**: HESLB correspondence, university financial office communication.
- **Calendar**: OLAS deadlines, repayment due dates, disbursement expected dates.
- **Profile**: Student/graduate badge, university enrollment, clearance badge.
- **Bills**: Loan repayment as recurring bill with due dates and progress.
- **My Family**: Parents track children's application and disbursement.
- **NECTA**: ACSEE results linked to HESLB eligibility.
- **Budget**: Student living allowance budgeting, graduate repayment planning.

---

## 6. Implementation Phases

### Phase 1: Foundation (Week 1)
- [ ] Create directory structure and heslb_module.dart
- [ ] LoanSummary, ApplicationStatus, Disbursement, Repayment models
- [ ] HeslbService with AuthenticatedDio
- [ ] Backend: migrations + summary, disbursements, repayments endpoints
- [ ] SQLite tables for loan data and payments

### Phase 2: Core UI (Week 2)
- [ ] Dashboard with balance, progress, next payment
- [ ] Application Status tracker
- [ ] Disbursement Timeline
- [ ] Balance & Repayment with calculator
- [ ] Pay Now with M-Pesa

### Phase 3: Integration (Week 3)
- [ ] Wire to WalletService for payments
- [ ] Wire to NotificationService for reminders
- [ ] Wire to CalendarService for due dates
- [ ] Wire to Bills module for recurring tracking

### Phase 4: Polish (Week 4)
- [ ] Payment History with downloadable statement
- [ ] Application Guide with checklist
- [ ] Clearance Request and tracking
- [ ] OLAS status indicator
- [ ] Eligibility Checker
- [ ] Offline loan summary viewing

---

## 7. External APIs & Integrations

| API | Provider | Purpose | Pricing | Integration Notes |
|-----|----------|---------|---------|-------------------|
| [HESLB OLAS Portal](https://olas.heslb.go.tz/) | HESLB (Higher Education Students' Loans Board) | Student loan status, allocation, repayment info | No public API | Web portal only. No programmatic access — would need web scraping or partnership. Allocated TZS 426.5B to 135,240 students in 2025/26 |
| [M-Pesa Open API](https://openapiportal.m-pesa.com) | Vodacom Tanzania | Loan repayments, fee payments | Transaction fees | Dart SDK: `mpesa_sdk` on pub.dev. Most TZ students pay via mobile money |
| [AzamPay API](https://developers.azampay.co.tz/) | AzamPay (Bakhresa Group) | Payment gateway for loan repayments | Transaction fees | Flutter SDK: `azampaytanzania` on pub.dev |
| [ClickPesa API](https://docs.clickpesa.com/) | ClickPesa | Unified payment collection for repayments | Transaction fees | Aggregates M-Pesa, Tigo Pesa, Airtel Money, HaloPesa |
| [Flutterwave API](https://developer.flutterwave.com/) | Flutterwave | Payment processing, cards, mobile money | 1.4% per transaction (Africa) | Supports M-Pesa, cards, bank transfers. Good payment aggregator |
| [DPO Pay API](https://docs.dpopay.com/api/index.html) | DPO Group (Network International) | Card + mobile money payments | Transaction fees | Tanzania presence. Card and mobile money processing |
| [Africa's Talking](https://developers.africastalking.com/) | Africa's Talking | SMS notifications for loan status, repayment reminders | Pay-as-you-go | Supports all 3 major TZ telcos |
| [Firebase Cloud Messaging](https://firebase.google.com/docs/cloud-messaging) | Google | Loan disbursement alerts, repayment reminders | Free | Already integrated in TAJIRI app |
