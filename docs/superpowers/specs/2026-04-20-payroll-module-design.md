# Payroll Module Design Spec

**Date:** 2026-04-20  
**Module:** `lib/payroll/`  
**Replaces:** `lib/business/pages/payroll_page.dart`

---

## Goal

Extract the existing payroll tab into a dedicated, full-featured `lib/payroll/` module that follows the same conventions as `lib/team/` and `lib/myjob/`. The module handles monthly payroll runs, per-employee payslips, and statutory obligation tracking (PAYE, NSSF, SDL, WCF) for Tanzanian businesses.

---

## Architecture

### Module Structure

```
lib/payroll/
├── models/
│   └── payroll_models.dart       — PayrollRun, PayrollEntry, PayrollStatus,
│                                    TanzaniaPAYE, StatutoryObligation
├── services/
│   └── payroll_service.dart      — all payroll API calls
├── pages/
│   ├── payroll_home_page.dart    — hub page (tab-embedded, no AppBar)
│   ├── payroll_run_page.dart     — single run detail
│   ├── payslip_page.dart         — per-employee payslip
│   ├── statutory_page.dart       — PAYE/NSSF/SDL/WCF obligations tracker
│   └── payroll_history_page.dart — full paginated history
├── widgets/
│   ├── payslip_card.dart         — reusable per-employee row widget
│   └── tax_summary_widget.dart   — PAYE bracket reference widget
└── payroll.dart                  — barrel export
```

### Conventions (same as lib/team/ and lib/myjob/)

- **State:** `setState()` only — no Provider/Bloc/Riverpod
- **Services:** Static methods, token as parameter
- **Colors per file:** `_kPrimary=0xFF1A1A1A`, `_kSecondary=0xFF666666`, `_kBg=0xFFFAFAFA`, `_kCard=0xFFFFFFFF`
- **i18n:** `final sw = AppStringsScope.of(context)?.isSwahili ?? false;`
- **No AppBar** on `PayrollHomePage` — it is rendered inside `_ProfileTabPage`
- All other pages (run, payslip, statutory, history) have their own `Scaffold` + `AppBar`

---

## Models (`payroll_models.dart`)

Move from `lib/business/models/business_models.dart` and extend:

### Existing (move verbatim)
- `PayrollStatus` enum — `draft | approved | paid`
- `PayrollEntry` — per-employee row: `employeeId`, `employeeName`, `grossSalary`, `paye`, `nssfEmployee`, `nssfEmployer`, `sdl`, `wcf`, `netSalary`, `totalEmployerCost`
- `PayrollRun` — a monthly run: `id?`, `businessId`, `month`, `year`, `employees`, `totalGross`, `totalNet`, `totalPaye`, `totalNssf`, `totalSdl`, `totalWcf`, `status`
- `TanzaniaPAYE` — static calculator: `paye()`, `nssf()`, `sdl()`, `wcf()`, `netSalary()`, `buildPayrollEntry(Employee)`

### New
```dart
class StatutoryObligation {
  final String type;        // 'PAYE' | 'NSSF' | 'SDL' | 'WCF'
  final int month;
  final int year;
  final double amount;
  final bool remitted;      // has it been paid to TRA/NSSF?
  final DateTime? dueDate;
  final DateTime? remittedAt;
}
```

### `business_models.dart` migration
After moving the classes, add re-exports so existing callers don't break:
```dart
export 'package:tajiri/payroll/models/payroll_models.dart'
    show PayrollRun, PayrollEntry, PayrollStatus, TanzaniaPAYE;
```

---

## Service (`payroll_service.dart`)

Static methods, token as first param. Mirrors `WorkService` pattern.

### Methods

| Method | HTTP | Endpoint | Notes |
|--------|------|----------|-------|
| `getHistory(token, businessId)` | GET | `/business/{id}/payroll` | Returns `List<PayrollRun>` |
| `calculate(token, businessId, month, year)` | POST | `/business/{id}/payroll/calculate` | Returns `PayrollRun`; falls back to local if 4xx |
| `approve(token, payrollId)` | POST | `/business/payroll/{id}/approve` | Returns success/message |
| `getStatutory(token, businessId)` | GET | `/business/{id}/payroll/statutory` | **NEW** — returns `List<StatutoryObligation>` |
| `markRemitted(token, obligationId)` | POST | `/business/payroll/statutory/{id}/remit` | **NEW** — marks obligation paid |

Two new backend endpoints are required (see Backend section).

---

## Pages

### 1. `PayrollHomePage` — Hub (no AppBar, tab-embedded)

**State:** `_history`, `_loading`, `_selectedMonth`, `_selectedYear`, `_currentRun`, `_calculating`

**Layout (top to bottom):**
1. **Month/Year picker row** — DropdownButton month + DropdownButton year
2. **"Calculate Payroll" / "Calculating..." button** (full width, dark) — calls `_calculate()` which tries API then falls back to local `TanzaniaPAYE`
3. **Stats strip** (only shown when `_currentRun != null`) — 4 dark chips: Gross / Net / PAYE / NSSF
4. **"View Full Payroll" card** → `PayrollRunPage` (only when `_currentRun != null`)
5. **"Statutory Obligations" shortcut card** → `StatutoryPage`
6. **"Payroll History" header + last 3 runs** → each taps to `PayrollRunPage`; "View All" → `PayrollHistoryPage`

**Empty state:** If no employees: icon + "Add employees first" + link hint.

---

### 2. `PayrollRunPage` — Single Run Detail

**Constructor:** `PayrollRun run, String token`

**Layout:**
1. **Dark summary card** — month/year label, Gross / Net in large text, PAYE / NSSF / SDL / WCF in smaller row below divider; status badge (Draft/Approved/Paid)
2. **"Per-Employee Breakdown" section header**
3. **Employee list** — `PayslipCard` per entry, tap → `PayslipPage`
4. **PAYE bracket reference** (`TaxSummaryWidget`)
5. **Action row** (only for `draft` status):
   - "Approve & Disburse" button (full width, dark)
   - "View Payment Details" outlined button → `_showDisburseSheet()`
6. **Share/Export row** — "Share Summary" icon button (shares text summary via `Share.share`)

**Disburse sheet** (existing logic, moved here): lists each employee name + net, total, "Approve Payments" button.

---

### 3. `PayslipPage` — Per-Employee Payslip

**Constructor:** `PayrollEntry entry, int month, int year, String businessName` — `businessName` passed from `PayrollRunPage`; callers that don't have it pass `''` and the header omits the business name line

**Layout:**
1. **Header** — business name, "PAYSLIP", month/year, employee name + avatar initial
2. **Earnings card** — Basic Salary row + any allowance rows (from `entry`) + subtotal
3. **Deductions card** — PAYE row, NSSF (Employee 10%) row + subtotal
4. **Net Pay hero** — large dark card: "Net Pay / Mshahara Halisi", amount in big text
5. **Employer costs footnote** — NSSF employer + SDL + WCF + total employer cost
6. **Share button** (full width outlined) — shares formatted text payslip via `Share.share`

---

### 4. `StatutoryPage` — Obligations Tracker

**Constructor:** `int businessId, String token`

**State:** `_obligations`, `_loading`, grouped by type (PAYE / NSSF / SDL / WCF)

**Layout:**
1. **Tab bar** — PAYE | NSSF | SDL | WCF
2. **Each tab:** Monthly list rows — month/year, amount (TZS), due date, status badge (Due/Remitted/Overdue)
3. **Long-press row** → "Mark as Remitted" option
4. **Empty state per tab:** "No obligations recorded yet"
5. **Info card at bottom** — links: "TRA e-Filing" (web), "NSSF Portal" (web), "SDL via TRA" (web)

**If backend returns 404 on the NEW endpoint:** degrade gracefully — derive obligations from payroll history locally (each approved run generates PAYE/NSSF/SDL/WCF rows).

---

### 5. `PayrollHistoryPage` — Full History

**Constructor:** `int businessId, String token`

**State:** `_history`, `_loading`, `_selectedYear` filter

**Layout:**
1. **Year filter chips** — current year ± 2
2. **List of `PayrollRun`** — month/year, employee count, net total, status badge
3. **Tap** → `PayrollRunPage`
4. **Empty state:** icon + "No payroll runs yet. Calculate your first payroll."

---

## Widgets

### `PayslipCard` (`payslip_card.dart`)

Reusable row widget used in `PayrollRunPage` employee list:
- Left: avatar circle (initial letter)
- Middle: employee name, gross salary label
- Right: net salary bold, PAYE deduction in red smaller text
- Tap → navigates to `PayslipPage`

### `TaxSummaryWidget` (`tax_summary_widget.dart`)

PAYE brackets reference card extracted from `PayrollPage`. Shows:
- 5 bracket rows (range → rate)
- Footer: NSSF 10%+10% | SDL 3.5% | WCF 0.5%

---

## Backend Requirements

### Existing endpoints (no change needed)
- `GET  /business/{id}/payroll` — history
- `POST /business/{id}/payroll/calculate` — calculate run
- `POST /business/payroll/{id}/approve` — approve run

### New endpoints required

#### GET `/business/{id}/payroll/statutory`
Returns statutory obligations derived from approved payroll runs:
```json
{
  "data": [
    { "id": 1, "type": "PAYE", "month": 4, "year": 2026,
      "amount": 450000, "due_date": "2026-05-07",
      "remitted": false, "remitted_at": null }
  ]
}
```
**Implementation:** Query `payroll_runs` where `business_id = ?` and `status = 'approved'`. For each run compute PAYE/NSSF/SDL/WCF from totals stored on the run. Due dates: PAYE day 7 next month, NSSF day 15, SDL day 7, WCF annual.

#### POST `/business/payroll/statutory/{id}/remit`
Marks an obligation as remitted. Needs a `statutory_obligations` table:
```sql
CREATE TABLE statutory_obligations (
  id BIGSERIAL PRIMARY KEY,
  business_id INTEGER NOT NULL,
  payroll_run_id INTEGER REFERENCES payroll_runs(id),
  type VARCHAR(10) NOT NULL,   -- PAYE | NSSF | SDL | WCF
  month SMALLINT, year SMALLINT,
  amount NUMERIC(15,2),
  due_date DATE,
  remitted BOOLEAN DEFAULT FALSE,
  remitted_at TIMESTAMPTZ,
  created_at TIMESTAMPTZ DEFAULT NOW(),
  updated_at TIMESTAMPTZ DEFAULT NOW()
);
```

**Fallback:** If this table/endpoint doesn't exist, `StatutoryPage` derives obligations from local payroll history and the "Mark as Remitted" action is disabled with a tooltip "Sync required".

---

## Navigation Wiring

### Profile tab
- Tab ID: `biz_payroll` (already exists in `profile_tab_config.dart`)
- Current widget: `PayrollPage` from `lib/business/pages/payroll_page.dart`
- After migration: replace with `PayrollHomePage` from `lib/payroll/payroll.dart`
- Update the `biz_payroll` case in `profile_screen.dart`

### No new profile tab needed — reuses existing `biz_payroll` slot.

---

## Migration Plan

1. Copy `PayrollRun`, `PayrollEntry`, `PayrollStatus`, `TanzaniaPAYE` from `business_models.dart` → `payroll_models.dart`
2. Add re-exports in `business_models.dart` so no other file breaks
3. Extract `calculatePayroll`, `approvePayroll`, `getPayrollHistory` from `BusinessService` → `PayrollService` (keep stubs in `BusinessService` that delegate to `PayrollService` for backward compat)
4. Build new pages/widgets
5. Update `profile_screen.dart` `biz_payroll` case to use `PayrollHomePage`
6. Delete `lib/business/pages/payroll_page.dart`

---

## User Journeys

To be generated via `docs/generate_user_journeys.md` into `docs/modules/payroll_user_journeys.md`.

Key journeys to cover:
1. **Run Monthly Payroll** — month/year selection → calculate → review per-employee → approve → disburse
2. **View Payslip** — from run detail, tap employee → payslip detail → share
3. **Track Statutory Obligations** — PAYE tab → see what's owed → mark as remitted
4. **Payroll History** — browse past runs → drill into any run → compare month-over-month
5. **Salary Adjustment** — manager updates employee gross salary in Team module → next payroll reflects the change
6. **First Payroll Setup** — new business with no employees → guided empty state → link to Employees page

---

## Design Notes

- `PayrollHomePage` has **no AppBar** (tab-embedded like all other `biz_*` pages)
- All money formatted as `TZS 1,234,567` using `NumberFormat('#,###', 'en')`
- Approval is irreversible — confirm dialog required before `approve()` call
- Local PAYE calculation (`TanzaniaPAYE`) is the fallback when API is unavailable — always works offline
- Tanzania statutory rates hardcoded (accurate as of 2026): PAYE per brackets, NSSF 10%/10%, SDL 3.5%, WCF 0.5%
