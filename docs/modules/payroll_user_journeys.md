# Payroll Module — Complete User Journeys

**Module:** `lib/payroll/`
**Source spec:** `docs/superpowers/specs/2026-04-20-payroll-module-design.md`

Every feature must be: **Interactive** (notifications, reminders, prompts), **Connected** (team, accounting, wallet, calendar, tax), and **Insightful** (reports, trends, statutory summaries).

---

## 1. RUN MONTHLY PAYROLL

**Entry:** Profile → Business section → "Payroll" tab → `PayrollHomePage`
**Stage/Context:** Every month, typically on the last working day or first day of the next month

### User Journey

1. User opens the Payroll tab. `PayrollHomePage` loads with `_loading = true`, then fetches payroll history from `PayrollService.getHistory(token, businessId)`.
2. **If no employees exist:** Empty state shows — large person icon, "Add employees first" / "Ongeza wafanyakazi kwanza", and a hint "Go to the Employees page / Nenda ukurasa wa Wafanyakazi". Page is otherwise unusable.
3. **If employees exist:** Month/year picker row is shown. Defaults to current month/year. User can tap the month dropdown to choose a different month and the year dropdown to go back up to 4 years.
4. User taps **"Calculate Payroll" / "Hesabu Mishahara"** (full-width dark button).
   - Button becomes disabled and shows spinner + "Calculating... / Inahesabu..."
   - `PayrollService.calculate(token, businessId, month, year)` is called.
   - **If API succeeds:** `PayrollRun` returned, `_currentRun` is set, stats strip appears.
   - **If API fails (4xx/5xx/network):** Falls back silently to `TanzaniaPAYE.buildPayrollEntry(employee)` for every active employee, builds a local `PayrollRun` with `id = null` and `status = draft`.
5. **Stats strip** appears below the button: 4 dark chips — **Gross / Jumla Mshahara**, **Net / Mshahara Halisi**, **PAYE**, **NSSF**. All formatted as `TZS 1,234,567`.
6. A **"View Full Payroll / Tazama Mishahara Yote"** card appears → taps to `PayrollRunPage`.
7. User taps the card to review the full run before approving (see Journey 2).
8. User can **recalculate** by changing month/year and tapping the button again. If a `_currentRun` already exists for that period in history, the existing run is shown directly without triggering a new calculation.

### CRUD Operations
- **Create:** Tapping "Calculate Payroll" creates a draft `PayrollRun` on the server (or locally if offline).
- **Read:** Stats strip + "View Full Payroll" card shows the calculated run. History list shows past runs.
- **Edit:** NOT AVAILABLE — payroll entries are recalculated from employee salaries. To change the result, the manager must update the employee's gross salary in the Team module, then recalculate.
- **Delete:** NOT AVAILABLE — once approved, a payroll run is permanent record. Draft runs (local-only, `id = null`) are discarded when the page is left.

### Notifications & Reminders
- 🔔 **Monthly payroll reminder:** Push notification on the 25th of every month: `"📅 It's time to run [business name]'s payroll for [Month] [Year]. [X] employees are waiting."`
- 🔔 **Reminder if no payroll run by month end:** On the last day of the month at 9am: `"⚠️ You haven't run payroll for [Month] yet. Employees are waiting for their salary."`
- 💡 **First payroll prompt:** When a business adds their first employee: `"💡 You have your first employee! Head to the Payroll tab to run your first salary calculation."`
- 📊 **Monthly summary (after approval):** `"📊 [Month] payroll approved. Total paid: TZS [amount] to [X] employees. PAYE due by [date]."`

### Reports & Insights
- **Month-over-month comparison:** On the stats strip, show a tiny `+3.2%` or `-1.1%` delta vs previous month's total net, with green/red color.
- **Payroll cost trend:** In `PayrollHistoryPage`, a small line sparkline above the list showing total gross trend over the last 6 months.
- **Biggest cost driver insight:** "PAYE accounts for [X]% of your total payroll cost this month."
- **Headcount vs cost:** "You have [X] employees. Average cost per employee: TZS [amount]."

### Cross-Module Connections
- **Team:** `TeamService.getEmployees(token, businessId)` feeds `PayrollHomePage`. If an employee's `grossSalary` has changed since last month, a banner shows: "⚠️ [N] employee salaries changed since last payroll. Recalculate to update."
- **Calendar:** On successful calculation, offer "Add PAYE due date to calendar / Ongeza kwenye Kalenda" → `CalendarService.createEvent()` with title "PAYE Payment Due — [Month]" and date = 7th of next month.
- **Accounting/Budget:** After payroll approval, prompt "Record as expense? / Rekodi kama gharama?" → `ExpenditureService.recordExpense(totalGross, category: 'Payroll', date: today)`.
- **Shangazi AI:** "Ask Shangazi about Tanzania payroll taxes" link in the PAYE bracket reference card.

---

## 2. VIEW PAYROLL RUN DETAIL

**Entry:** `PayrollHomePage` → "View Full Payroll" card → `PayrollRunPage`  
**Also:** `PayrollHistoryPage` → tap any history row → `PayrollRunPage`  
**Stage/Context:** After calculating payroll, or reviewing any past run

### User Journey

1. `PayrollRunPage` opens with the `PayrollRun` object passed in. No additional API call needed for the run itself.
2. **Dark summary card** at top shows:
   - Month/year label: "April 2026"
   - Status badge: "Draft / Rasimu" (orange) | "Approved / Imeidhinishwa" (blue) | "Paid / Imelipwa" (green)
   - Two big numbers: **Total Gross / Jumla Mshahara Ghafi** and **Total Net / Jumla Mshahara Halisi**
   - Divider, then 4 smaller figures in a row: PAYE / NSSF / SDL / WCF
3. **"Per-Employee Breakdown / Maelezo kwa Mfanyakazi"** section header.
4. List of `PayslipCard` widgets — one per employee. Each card shows:
   - Avatar circle (first letter of name)
   - Employee name + gross salary label
   - Net salary (bold right side) + PAYE amount in red below it
   - Tap → `PayslipPage` for that employee
5. **PAYE Bracket Reference** (`TaxSummaryWidget`) — collapsible section at bottom showing all 5 brackets and rates.
6. **Action row** (shown only when `status == draft`):
   - **"Approve & Disburse Payroll / Idhinisha na Lipa Mishahara"** — full-width dark button
   - **"View Payment Details / Tazama Maelezo ya Malipo"** — outlined button → disburse sheet
7. **Share row** — "Share Summary / Shiriki Muhtasari" icon button → shares formatted text via `Share.share()`.

### CRUD Operations
- **Create:** NOT AVAILABLE from this page — created from `PayrollHomePage`.
- **Read:** Full payroll run displayed — summary + per-employee breakdown.
- **Edit:** NOT AVAILABLE — payroll is immutable once created. Manager must recalculate from `PayrollHomePage`.
- **Delete:** NOT AVAILABLE — approved runs are permanent. Draft runs are discarded automatically.

### Notifications & Reminders
- ⚠️ **Pending approval alert:** If a payroll run has been in `draft` status for more than 3 days: `"⚠️ [Month] payroll is still unapproved. Employees haven't been paid yet."`
- 🎉 **Approval confirmation (in-app):** After successful approval: Snackbar — "✅ Payroll approved! TZS [amount] approved for [X] employees."

### Reports & Insights
- **Employer total cost** shown at bottom of each `PayslipCard`: "Total employer cost: TZS [amount]" = gross + NSSF employer + SDL + WCF.
- **Largest deduction highlight:** "PAYE is [X]% of gross this month — [employee name] has the highest deduction at TZS [amount]."
- **Share text format:**
  ```
  PAYROLL SUMMARY — April 2026
  [Business Name]
  ─────────────────────
  Total Gross:   TZS 3,450,000
  Total Net:     TZS 2,890,000
  PAYE:          TZS  310,000
  NSSF:          TZS  172,500
  SDL:           TZS   86,250
  WCF:           TZS   17,250
  Employees: 4
  Status: Draft
  ─────────────────────
  Generated by TAJIRI
  ```

### Cross-Module Connections
- **Tax page:** If a `TaxSummary` exists for this business, PAYE from this payroll run pre-fills into the Tax module's monthly PAYE field.
- **Accounting:** "Add to accounting records / Ongeza kwenye hesabu" button → navigates to business accounting with payroll expense pre-filled.
- **Wallet:** Future M-Pesa disbursement integration — "Disburse via M-Pesa / Lipa kwa M-Pesa" button (placeholder, shows "Coming soon / Inakuja hivi karibuni").

---

## 3. VIEW & SHARE PAYSLIP

**Entry:** `PayrollRunPage` → tap any employee card → `PayslipPage`
**Stage/Context:** Manager checking an employee's pay breakdown; employee viewing their own payslip (via My Job module in future)

### User Journey

1. `PayslipPage` opens with `PayrollEntry`, `month`, `year`, `businessName` passed in.
2. **Payslip header card:**
   - Business name (or "Your Business" if empty)
   - Bold label: **"PAYSLIP / SLIP YA MSHAHARA"**
   - Month/Year: "April 2026"
   - Employee name + avatar initial circle
3. **Earnings card** (`_kCard`, rounded):
   - Section title: "Earnings / Mapato"
   - Row: Basic Salary / Mshahara wa Msingi — `TZS [grossSalary]`
   - Row per allowance (if `entry` has allowances): allowance name — `TZS [amount]`
   - **Subtotal row** (bold): Total Earnings / Jumla Mapato
4. **Deductions card:**
   - Section title: "Deductions / Makato"
   - Row: PAYE (Income Tax) — `- TZS [paye]` (red)
   - Row: NSSF (Employee 10%) / NSSF (Mfanyakazi 10%) — `- TZS [nssfEmployee]` (red)
   - **Subtotal row** (bold, red): Total Deductions / Jumla Makato
5. **Net Pay hero card** (dark background):
   - Label: "Net Pay / Mshahara Halisi"
   - Large bold amount: `TZS [netSalary]`
6. **Employer costs footnote** (small, grey):
   - "Employer pays additionally / Mwajiri analipa zaidi:"
   - NSSF Employer 10%: `TZS [nssfEmployer]`
   - SDL 3.5%: `TZS [sdl]`
   - WCF 0.5%: `TZS [wcf]`
   - **Total employer cost: TZS [totalEmployerCost]**
7. **"Share Payslip / Shiriki Slip"** — full-width outlined button → `Share.share()` with formatted text (see Reports section).

### CRUD Operations
- **Create:** NOT AVAILABLE — payslip is auto-generated from `PayrollEntry`.
- **Read:** Full payslip displayed as described above.
- **Edit:** NOT AVAILABLE — to change, update employee salary in Team module and recalculate payroll.
- **Delete:** NOT AVAILABLE — payslip is part of the payroll run record.

### Notifications & Reminders
- 💡 **Payslip ready prompt:** After payroll approval, for each employee who has a user account: `"💼 Your payslip for [Month] [Year] is ready. Net pay: TZS [amount]. Tap to view."` (future — when employee accounts are linked)
- 🔔 **Salary change reminder:** If gross salary changed vs previous month: a banner on the payslip — "⚠️ Salary changed from TZS [old] to TZS [new] this month."

### Reports & Insights
- **Year-to-date summary** (shown at bottom of payslip if history exists): "Year-to-date [Year]: Total earned TZS [sum], Total PAYE TZS [sum]"
- **Share text format:**
  ```
  ─────────────────────────────
  PAYSLIP — April 2026
  [Business Name]
  Employee: [Name]
  ─────────────────────────────
  EARNINGS
  Basic Salary:       TZS 1,000,000
  Housing Allowance:  TZS   150,000
  ─────────────────────────────
  DEDUCTIONS
  PAYE:              -TZS    87,500
  NSSF (Employee):   -TZS   115,000
  ─────────────────────────────
  NET PAY:            TZS   947,500
  ─────────────────────────────
  Employer also pays:
  NSSF (Employer):    TZS   115,000
  SDL:                TZS    40,250
  WCF:                TZS     5,750
  Total cost to employer: TZS 1,161,000
  ─────────────────────────────
  Generated by TAJIRI Payroll
  ```

### Cross-Module Connections
- **My Job (employee self-view):** Future integration — employee sees their own payslip via `MyJobPage` without needing manager access.
- **Budget:** "Add net salary to income / Ongeza mshahara kwa mapato" link → `IncomeService.recordIncome(netSalary, category: 'Salary', date: today)` — useful for employees who also use TAJIRI personally.
- **Shangazi AI:** "Ask Shangazi to explain my deductions" link → opens Shangazi chat with payslip context: `"My gross is TZS [X], PAYE is TZS [Y], NSSF is TZS [Z]. Explain my deductions."`.

---

## 4. APPROVE & DISBURSE PAYROLL

**Entry:** `PayrollRunPage` → "Approve & Disburse Payroll" button (only shown for `draft` status)
**Stage/Context:** After reviewing the calculated payroll, manager authorises payment

### User Journey

1. Manager reviews the run in `PayrollRunPage` and taps **"Approve & Disburse Payroll / Idhinisha na Lipa Mishahara"**.
2. **Confirmation dialog** (required — approval is irreversible):
   - Title: "Approve Payroll? / Idhinisha Mishahara?"
   - Body: "This will approve the [Month] [Year] payroll of TZS [totalNet] for [N] employees. This cannot be undone. / Hii itaidhinisha mishahara ya [Mwezi] [Mwaka] ya TZS [jumla] kwa wafanyakazi [N]. Haiwezi kubatilishwa."
   - Buttons: "Cancel / Ghairi" (text) | "Approve / Idhinisha" (dark filled)
3. On confirm: button shows spinner + "Approving... / Inaidhinisha..."
4. `PayrollService.approve(token, payrollId)` is called.
   - **If `id == null` (local-only run):** No API call possible. Snackbar: "Payroll calculated locally but not saved to server. Connect to internet and recalculate to save. / Mishahara imehesabiwa bila mtandao. Unganisha mtandao na uhesabu tena." Status stays `draft`.
   - **If API succeeds:** Status updates to `approved`. Snackbar: "✅ Payroll approved! / Mishahara imeidhinishwa!" Page refreshes.
   - **If API fails:** Snackbar with error: "Approval failed: [message] / Imeshindikana: [ujumbe]". Status stays `draft`.
5. After approval, **Disburse sheet** can be opened via "View Payment Details / Tazama Maelezo ya Malipo" outlined button.
6. **Disburse sheet** shows:
   - Drag handle
   - Title: "Disburse Salaries / Lipa Mishahara"
   - Subtitle: "M-Pesa disbursement coming soon / M-Pesa inakuja hivi karibuni"
   - List: each employee name + net salary
   - Total row
   - "Approve Payments / Idhinisha Malipo" button (marks as paid when M-Pesa is ready; currently shows "Coming soon" snackbar)

### CRUD Operations
- **Create:** NOT AVAILABLE.
- **Read:** Status badge on summary card updates to "Approved / Imeidhinishwa".
- **Edit:** NOT AVAILABLE — approved payroll is immutable.
- **Delete:** NOT AVAILABLE — once approved, permanent record.

### Notifications & Reminders
- 🎉 **Approval celebration:** Push to manager: `"🎉 Payroll approved! TZS [totalNet] has been approved for [N] employees for [Month] [Year]."`
- 🔔 **PAYE due date alert:** Immediately after approval, schedule a local notification for the 7th of next month: `"📅 PAYE of TZS [amount] is due to TRA on [date]. Don't miss the deadline."`
- 🔔 **NSSF due date alert:** Schedule for the 15th of next month: `"📅 NSSF remittance of TZS [amount] is due on [date]."`
- ⚠️ **Overdue PAYE alert:** If 7th passes without marking as remitted: `"⚠️ PAYE of TZS [amount] for [Month] is overdue. File immediately to avoid TRA penalties."`
- 💡 **M-Pesa prompt (future):** `"💡 Save time — disburse all salaries at once via M-Pesa. Coming soon in TAJIRI Payroll."` (shown once per month max)

### Reports & Insights
- **Approval timestamp** shown on `PayrollRunPage` when status is `approved`: "Approved on [date] at [time]"
- **Year-to-date payroll cost:** After each approval, show "Year-to-date payroll: TZS [sum] across [total runs] months."
- **Cost growth alert:** If total payroll increased by more than 10% vs last month: `"📈 Payroll cost increased by [X]% this month. Main driver: [employee name]'s salary adjustment."` or "new hire".

### Cross-Module Connections
- **Calendar:** After approval, create two calendar events: "PAYE Due — [Month]" (7th next month) + "NSSF Due — [Month]" (15th next month) → `CalendarService.createEvent()`.
- **Accounting:** Prompt: "Record TZS [totalGross] as Payroll Expense / Rekodi kama Gharama?" → `ExpenditureService` with `category = 'Salaries & Wages'`, `date = today`.
- **Tax module:** PAYE total from this run contributes to the monthly PAYE field in the Tax module's statutory summary.
- **Wallet:** Future: "Pay via M-Pesa Business / Lipa kwa M-Pesa" → `WalletService.initiateB2C()` for each employee mobile number.

---

## 5. TRACK STATUTORY OBLIGATIONS (PAYE / NSSF / SDL / WCF)

**Entry:** `PayrollHomePage` → "Statutory Obligations / Majukumu ya Kisheria" shortcut card → `StatutoryPage`
**Stage/Context:** Monthly — after payroll runs are approved, manager must remit taxes to TRA and NSSF

### User Journey

1. `StatutoryPage` loads, calls `PayrollService.getStatutory(token, businessId)`.
   - **If endpoint exists:** Returns `List<StatutoryObligation>` from server.
   - **If endpoint returns 404 (not yet deployed):** Derives obligations locally from approved payroll runs in `_history`. Computes PAYE/NSSF/SDL/WCF from each `PayrollRun.total*` field, assigns standard due dates.
2. **Tab bar** with 4 tabs: **PAYE | NSSF | SDL | WCF**
3. Each tab shows a scrollable list of monthly rows:
   - Left: "April 2026", due date subtitle "Due: 07 May 2026"
   - Right: amount `TZS [amount]` + status badge
     - **Due** (orange): due date is in the future
     - **Overdue** (red): due date has passed, not remitted
     - **Remitted** (green): marked as paid
4. **Long-press any row** → bottom sheet: "Mark as Remitted / Weka kama Imelipwa" option
   - On confirm: `PayrollService.markRemitted(token, obligationId)` is called.
   - **If no server endpoint:** "Mark as Remitted" is disabled. Tooltip: "Server sync required / Inahitajika muunganiko wa seva".
5. **Info card at bottom** of each tab:
   - PAYE tab: "File via TRA e-Filing (tra.go.tz)" — opens `url_launcher`
   - NSSF tab: "Remit via NSSF portal (nssf.or.tz)" — opens `url_launcher`
   - SDL tab: "SDL is filed together with PAYE via TRA e-Filing"
   - WCF tab: "WCF is an annual contribution filed by 31 March"
6. **Empty state per tab:** "No obligations yet. Run and approve payroll to track obligations. / Hakuna majukumu bado. Hesabu na idhinisha mishahara kwanza."

### CRUD Operations
- **Create:** Auto-created when payroll runs are approved (server-side) or derived locally.
- **Read:** Tab list showing monthly obligations with amounts and status.
- **Edit:** "Mark as Remitted" via long-press — the only edit operation.
- **Delete:** NOT AVAILABLE — statutory obligations are permanent audit trail.

### Notifications & Reminders
- 🔔 **PAYE due reminder (7 days before):** `"📅 PAYE of TZS [amount] for [Month] is due in 7 days (by [date]). File via TRA e-Filing."`
- 🔔 **NSSF due reminder (7 days before):** `"📅 NSSF of TZS [amount] for [Month] is due in 7 days (by [date]). Remit via the NSSF portal."`
- ⚠️ **PAYE overdue alert:** Day after due date if not remitted: `"🚨 PAYE of TZS [amount] for [Month] is OVERDUE. File immediately to avoid TRA penalties and interest."`
- ⚠️ **NSSF overdue alert:** `"🚨 NSSF of TZS [amount] for [Month] is OVERDUE. Late payment attracts a 5% penalty."`
- ⚠️ **WCF annual reminder:** March 24th each year: `"📅 WCF annual contribution of TZS [amount] is due by 31 March. File via OSHA."`
- 📊 **Monthly statutory digest** (1st of each month): `"📊 Statutory obligations this month: PAYE TZS [X], NSSF TZS [Y], SDL TZS [Z]. Total: TZS [sum]."`
- 💡 **First-time education prompt:** When user opens `StatutoryPage` for the first time: `"💡 Tanzania law requires PAYE remittance by 7th, NSSF by 15th each month. SDL is remitted together with PAYE."`

### Reports & Insights
- **Compliance rate:** "You have remitted [X] of [Y] obligations on time this year ([Z]% compliance rate)."
- **Total statutory paid YTD:** "Year-to-date statutory payments: PAYE TZS [X] | NSSF TZS [Y] | SDL TZS [Z] | WCF TZS [W]"
- **Penalty risk alert:** If any obligation is overdue: "⚠️ You have [N] overdue obligations totalling TZS [sum]. TRA/NSSF penalties may apply."
- **Monthly obligation forecast:** "Next month's estimated obligations based on current payroll: PAYE ~TZS [X], NSSF ~TZS [Y]."

### Cross-Module Connections
- **Calendar:** "Add all due dates to calendar / Ongeza tarehe kwenye Kalenda" button → creates events for every upcoming obligation.
- **Tax module:** PAYE data syncs to the Tax module's monthly PAYE field. The Tax page shows a "From Payroll / Kutoka Mishahara" auto-fill badge when this data is present.
- **Accounting:** Prompt when marking remitted: "Record as expense? / Rekodi kama gharama?" → `ExpenditureService` with `category = 'Tax & Statutory'`.
- **Shangazi AI:** "Ask Shangazi about PAYE penalties" or "Explain SDL to me" → opens Shangazi with obligation context.
- **Notifications service:** All due-date reminders scheduled via `FlutterLocalNotificationsPlugin` when obligations are created (after payroll approval).

---

## 6. PAYROLL HISTORY

**Entry:** `PayrollHomePage` → "View All History / Tazama Historia Yote" → `PayrollHistoryPage`
**Stage/Context:** Manager reviewing past payroll runs, comparing costs, auditing records

### User Journey

1. `PayrollHistoryPage` loads. Calls `PayrollService.getHistory(token, businessId)`.
2. **Year filter chips** appear at the top: current year and up to 2 years back (e.g., "2026 | 2025 | 2024"). Tapping filters the list.
3. **List of payroll run rows**, each showing:
   - Left: Month name + year ("April 2026"), employee count subtitle ("[N] employees")
   - Right: Total net (`TZS [amount]`) bold, status badge (Draft/Approved/Paid)
4. Tap any row → `PayrollRunPage` for that run.
5. **Empty state** (no history): Large history icon, "No payroll runs yet. / Hakuna rekodi ya mishahara bado." + "Calculate your first payroll / Hesabu mishahara ya kwanza" button → pops back to `PayrollHomePage`.
6. **Loading state:** `CircularProgressIndicator` centred.
7. **Error state:** Error icon + error message + "Retry / Jaribu Tena" button.

### CRUD Operations
- **Create:** NOT AVAILABLE from this page — new runs are started from `PayrollHomePage`.
- **Read:** Full list with year filter. Tap → `PayrollRunPage` detail.
- **Edit:** NOT AVAILABLE — payroll history is immutable.
- **Delete:** NOT AVAILABLE.

### Notifications & Reminders
- 📊 **Annual summary (December 31st):** `"📊 [Business name] payroll year in review: [N] payrolls run, TZS [total] paid out to employees. View your annual report."`

### Reports & Insights
- **Cost trend sparkline:** Small line chart above the list showing total gross per month for the filtered year.
- **Year total:** Sticky footer: "Total for [Year]: TZS [sum] across [N] payroll runs."
- **Average monthly payroll:** "[Year] average monthly payroll: TZS [average]."
- **Largest payroll month:** "Highest payroll month: [Month] at TZS [amount]" — shown as a highlight chip.
- **Annual payroll export:** "Export [Year] Payroll Report" button → shares formatted text summary of all 12 months.

### Cross-Module Connections
- **Accounting:** "Export to accounting / Hamisha kwa hesabu" button → creates expense records for all approved runs in the selected year.
- **Tax module:** Annual payroll total feeds into the year-end P9 form (employer declaration of PAYE deducted per employee — future feature).
- **Shangazi AI:** "Ask Shangazi to compare this year vs last year" → passes YTD data as context.

---

## 7. FIRST PAYROLL SETUP (ONBOARDING)

**Entry:** Profile → Payroll tab (first time, no employees added yet)
**Stage/Context:** New business owner who just registered and added no employees yet

### User Journey

1. User opens the Payroll tab for the first time.
2. `PayrollHomePage` loads. `TeamService.getEmployees()` returns empty list.
3. **Guided empty state** is shown (full-screen, vertically centred):
   - Large icon: `Icons.people_outline_rounded` (64px, grey)
   - Title: "Add employees first / Ongeza wafanyakazi kwanza"
   - Subtitle: "Go to the Employees section to add your team before running payroll. / Nenda sehemu ya Wafanyakazi kuongeza timu yako."
   - **"Go to Employees / Nenda Wafanyakazi"** — dark button → navigates to the Employees tab (profile screen tab switch to `biz_employees`)
4. Once the user adds at least one employee and returns to the Payroll tab, the normal `PayrollHomePage` with the month selector and calculate button is shown.
5. **First-run tip banner** (shown once, dismissed and persisted in `LocalStorageService`):
   - "💡 TAJIRI calculates PAYE, NSSF, SDL, and WCF automatically using Tanzania's official tax tables. No manual calculation needed."

### CRUD Operations
- **Create:** NOT AVAILABLE until employees exist.
- **Read:** Empty state with guidance.
- **Edit:** NOT AVAILABLE.
- **Delete:** NOT AVAILABLE.

### Notifications & Reminders
- 💡 **Setup nudge (3 days after first employee added):** `"💡 You have [N] employees in TAJIRI. Run your first payroll calculation in the Payroll tab — it takes under a minute."`
- 💡 **Salary data incomplete prompt:** If an employee has `grossSalary == 0`: `"⚠️ [Name] has no salary recorded. Update their salary in the Team module before running payroll."`

### Reports & Insights
- No reports available until first run is completed.

### Cross-Module Connections
- **Team:** Direct link to Employees tab. `TeamService.getEmployees()` is the gate — no employees = no payroll.
- **Shangazi AI:** "Ask Shangazi how to set up payroll in Tanzania" → opens Shangazi with context: "I'm setting up payroll for my Tanzanian business. I have [N] employees. What do I need to know?"

---

## 8. SALARY CHANGE IMPACT

**Entry:** Team module → Employee Detail → Compensation → update gross salary → return to Payroll tab
**Stage/Context:** Manager gives an employee a raise, or corrects a wrong salary, before the next payroll run

### User Journey

1. Manager updates an employee's `grossSalary` in the Team module (via `EmployeeDetailPage` → Compensation card).
2. On returning to the Payroll tab, `PayrollHomePage._loadAll()` re-fetches the employee list.
3. If a payroll run already exists in `_currentRun` for the current month using the old salary, a **"Salary changed" banner** appears:
   - "⚠️ [N] employee salary(ies) changed since last calculation. Recalculate to update. / Mshahara wa wafanyakazi [N] umebadilika. Hesabu tena."
   - "Recalculate / Hesabu Tena" button re-triggers `_calculateViaApi()` (or local fallback).
4. New calculation reflects the updated `grossSalary`, new PAYE/NSSF/SDL/WCF are computed.
5. The stats strip updates with the new figures.

### CRUD Operations
- **Create:** Recalculation creates a new draft `PayrollRun` (or overwrites the current draft).
- **Read:** Updated stats strip shows new totals.
- **Edit:** NOT AVAILABLE for individual payroll entries — the only way to change is recalculating.
- **Delete:** NOT AVAILABLE.

### Notifications & Reminders
- 💡 **Salary change reminder before payroll:** If salary changed and payroll hasn't been run yet: `"💡 [Name]'s salary was updated to TZS [new]. Run payroll to apply the change."`
- 🔔 **Recalculate reminder:** If salary changed after payroll was calculated (but not yet approved): `"⚠️ [Name]'s salary changed after this month's payroll was calculated. Recalculate before approving."`

### Reports & Insights
- **Salary change log** (shown on payslip): "Salary changed from TZS [old] to TZS [new] this month."
- **Impact summary after recalculation:** "Salary update increased total payroll by TZS [delta] (+[X]%). New PAYE liability: TZS [new]."

### Cross-Module Connections
- **Team:** `TeamService.getEmployee()` + `CompensationService` are the sources of truth for salary data.
- **Accounting:** Any salary increase triggers a note: "Budget impact: payroll cost increased by TZS [delta]/month. Update your payroll budget category."
- **Accounting/Budget:** `ExpenditureService` — prompt to update the payroll budget envelope if it exists.

---

## Notification Channel Summary

| Trigger | Type | Channel | Timing | Frequency |
|---------|------|---------|--------|-----------|
| 25th of every month | 🔔 Reminder | Push (FCM) | 9am on 25th | Monthly |
| Last day of month (no payroll run) | ⚠️ Alert | Push (FCM) | 9am | Monthly if no run |
| Payroll approved | 🎉 Celebration | Push (FCM) | Immediately | Per approval |
| PAYE due (7 days before) | 🔔 Reminder | Push + Local | 7 days before 7th | Monthly |
| NSSF due (7 days before) | 🔔 Reminder | Push + Local | 7 days before 15th | Monthly |
| PAYE overdue | ⚠️ Alert | Push (FCM) | Day after 7th | Until remitted |
| NSSF overdue | ⚠️ Alert | Push (FCM) | Day after 15th | Until remitted |
| WCF annual due | 🔔 Reminder | Push (FCM) | 24 March | Annual |
| Monthly statutory digest | 📊 Summary | Push (FCM) | 1st of month, 8am | Monthly |
| First employee added + 3 days | 💡 Prompt | Push (FCM) | One-time | Once |
| Salary changed, not recalculated | ⚠️ Alert | In-app banner | On tab open | Until recalculated |
| Draft payroll > 3 days old | ⚠️ Alert | Push (FCM) | Day 4 | Once per draft |
| December 31st annual summary | 📊 Summary | Push (FCM) | 10am | Annual |

---

## Cross-Module Integration Map

| From Payroll | To Module | Data / Action | Trigger |
|-------------|-----------|---------------|---------|
| Payroll approved | Calendar | Create PAYE due date event (7th next month) | Auto on approval |
| Payroll approved | Calendar | Create NSSF due date event (15th next month) | Auto on approval |
| Payroll approved | Accounting/Budget | Record total gross as Payroll Expense | User prompted |
| PAYE total from run | Tax module | Pre-fill monthly PAYE field | Auto sync |
| Obligation marked remitted | Accounting | Record statutory payment as expense | User prompted |
| Employee list | Team module | Read `grossSalary`, `allowances`, `isActive` | On every calculate |
| Net salary | Budget (employee) | Record net salary as monthly income | User prompted from PayslipPage |
| Any debt/obligation | Shangazi AI | Pass context for advice | User-initiated |
| Payroll history | Accounting | Export all approved runs as expense records | User-initiated from HistoryPage |
| First payroll setup | Team module | Navigate to Employees tab to add staff | Empty state button |
| Disburse (future) | Wallet | M-Pesa B2C bulk payment per employee | After approval |
