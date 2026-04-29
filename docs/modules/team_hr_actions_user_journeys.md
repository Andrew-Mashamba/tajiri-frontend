# Team — HR Actions User Journeys

**Module:** lib/team/
**Screen:** EmployeeDetailPage → AddHrActionSheet

Every feature must be: **Interactive** (notifications, reminders, prompts), **Connected** (calendar, wallet, budget, Shangazi AI), and **Insightful** (reports, trends, recommendations).

---

## 1. PROMOTE — Kukuza Cheo

**Entry:** Business Profile → Team tab → Employee card → "+ HR Action" FAB → "Promotion" / "Kukuza Cheo"
**Stage/Context:** Manager rewards high-performing employee with new title, department, and/or higher salary.

### User Journey
1. Manager taps employee card on the Team tab → opens `EmployeeDetailPage`.
2. Taps "+ HR Action" FAB (bottom-right) → `AddHrActionSheet` slides up.
3. Sheet shows 5 category rows (Employment, Compensation, Discipline, Leave, Performance, Document). Taps **Employment** → row expands showing Promotion, Transfer, Rehire, Terminate chips.
4. Taps **Promotion / Kukuza Cheo** chip → form fields appear below.
5. Fields (pre-filled from current employee record):
   - **New Position / Cheo Kipya** — TextField, pre-filled with current `position`.
   - **New Department / Idara Mpya** — TextField, pre-filled with current `department`.
   - **New Salary (TZS) / Mshahara Mpya** — number TextField, pre-filled with current `grossSalary`.
   - **Action Date / Tarehe** — date picker, defaults to today.
   - **Effective Date / Tarehe ya Kuanza** — optional date picker.
   - **Notes / Maelezo** — optional multiline TextField.
6. Manager updates fields as needed → taps **Save / Hifadhi**.
7. App calls:
   - `POST /api/businesses/{id}/employees/{id}/hr-actions` with `type=promote`.
   - `PUT /api/businesses/{id}/employees/{id}` with `position`, `department`, `gross_salary`.
8. On success: sheet dismisses, green SnackBar shows "Promotion recorded" / "Ukuzi wa cheo umehifadhiwa", `EmployeeDetailPage` reloads showing updated position badge.
9. On API failure: red SnackBar "Failed to save. Try again." / "Imeshindwa. Jaribu tena." Sheet stays open; data preserved.
10. Empty state (no employees yet): Team tab shows "Ongeza mfanyakazi wako wa kwanza" prompt — promotion flow is not accessible.

### CRUD Operations
- **Create:** Via AddHrActionSheet as described above.
- **Read:** HR action appears in employee's "History / Historia" timeline on EmployeeDetailPage, showing date, type badge (green "Promoted"), and notes.
- **Edit:** NOT AVAILABLE — delete the action and re-create if incorrect.
- **Delete:** NOT AVAILABLE — HR logs are immutable audit records.

### Notifications & Reminders
- 🎉 **Employee notification (push):** `"🎉 Hongera [Name]! Umekuzwa cheo hadi [New Position] kuanzia [Effective Date]."` — sent immediately to employee's TAJIRI account.
- 🔔 **Manager reminder (local):** `"📅 Kumbuka: Ukuzi wa cheo wa [Name] unaanza kesho ([Effective Date])."` — scheduled night before effective date.
- 📊 **Monthly summary (in-app):** Included in "Team Changes This Month" digest card on Business dashboard.
- 💡 **Prompt:** If new salary is more than 30% above previous: `"Mshahara mpya ni mkubwa zaidi kwa 30%. Hakikisha bajeti yako imesasishwa."` — in-app card only.

### Reports & Insights
- **Promotion History:** Timeline of all promotions for this employee — date, old position → new position, salary delta (TZS amount + %).
- **Team Promotion Rate:** Business-level report: "X employees promoted in last 12 months (Y% of team)".
- **Salary Growth Chart:** Line chart of this employee's gross salary over time, highlighting promotion events.
- **Department Headcount:** Auto-updated when employee transfers to a new department during promotion.

### Cross-Module Connections
- **Budget:** `POST ExpenditureService` — salary increase delta recorded as projected monthly cost change. Budget envelope "Mishahara" is flagged if increase exceeds envelope limit.
- **Calendar:** `CalendarService.createEvent()` — "Effective Date of Promotion" event created in business calendar with employee name. Reminder set for 1 day before.
- **Wallet:** No direct payment — but payroll run on next cycle should reflect new salary (link to Payroll tab).
- **Shangazi AI:** "Ask Shangazi about promotion best practices" button at bottom of confirmation sheet. Passes employee tenure, new role, and salary context.

---

## 2. TRANSFER — Uhamishaji

**Entry:** Business Profile → Team tab → Employee card → "+ HR Action" FAB → "Transfer" / "Uhamishaji"
**Stage/Context:** Manager reassigns an employee to a different department without changing title or salary.

### User Journey
1. Manager opens `EmployeeDetailPage` → taps "+ HR Action" FAB.
2. Selects **Transfer / Uhamishaji** chip under Employment.
3. Fields:
   - **New Department / Idara Mpya** — TextField, pre-filled with current `department`.
   - **Action Date / Tarehe** — date picker, defaults to today.
   - **Effective Date / Tarehe ya Kuanza** — optional.
   - **Notes / Maelezo** — optional (reason for transfer).
4. Manager updates department → taps **Save / Hifadhi**.
5. App calls:
   - `POST /hr-actions` with `type=transfer`.
   - `PUT /employees/{id}` with `department`.
6. Success: SnackBar "Transfer recorded" / "Uhamishaji umehifadhiwa". Detail page reloads with new department label.
7. Failure: SnackBar error, sheet stays open.

### CRUD Operations
- **Create:** Via AddHrActionSheet.
- **Read:** Appears in History timeline as orange "Transferred" badge with old department → new department arrow.
- **Edit:** NOT AVAILABLE.
- **Delete:** NOT AVAILABLE.

### Notifications & Reminders
- 🔔 **Employee notification (push):** `"📋 [Name], umehamishwa kwenda idara ya [New Department] kuanzia [Date]."` — sent immediately.
- 🔔 **Effective date reminder (local):** `"📅 Uhamishaji wa [Name] kwenda [New Department] unaanza leo."` — morning of effective date.
- 📊 **Department headcount change:** In-app card on Business dashboard: "[Old Dept]: -1 employee, [New Dept]: +1 employee".

### Reports & Insights
- **Transfer History:** All department moves for this employee in a timeline.
- **Department Headcount Report:** Bar chart of employees per department, updated in real-time after transfers.
- **Cross-Department Movement:** Business-level: "5 transfers happened this quarter — most movement into [Dept X]".

### Cross-Module Connections
- **Calendar:** Effective date synced as "Transfer effective" event.
- **Budget:** If departments have separate cost centers, budget automatically reassigns employee cost.
- **Shangazi AI:** "Ask Shangazi: Is this the right team structure?" — passes current org structure context.

---

## 3. TERMINATE — Maliza Mkataba

**Entry:** Business Profile → Team tab → Employee card → "+ HR Action" FAB → "Terminate" / "Maliza Mkataba"
**Stage/Context:** Manager ends employment, either voluntarily or involuntarily.

### User Journey
1. Manager opens `EmployeeDetailPage` → taps "+ HR Action" FAB.
2. Selects **Terminate / Maliza Mkataba** chip.
3. App shows a **red-tinted warning banner**: "Hatua hii itafunga akaunti ya mfanyakazi. Je, una uhakika?" — requires intentional scroll to see form fields.
4. Fields:
   - **Termination Date / Tarehe ya Kuacha** — date picker (required), defaults to today.
   - **Reason / Sababu** — multiline TextField (required). Hint: "Resignation, redundancy, misconduct..."
   - **Notes / Maelezo** — optional additional context.
5. Manager fills fields → taps **Terminate / Maliza** (red button).
6. Confirmation dialog: "Una uhakika wa kumaliza mkataba wa [Name]? Hatua hii itaweka `is_active = false`." → two buttons: **Cancel / Ghairi** (outline) and **Confirm / Thibitisha** (red filled).
7. On confirm:
   - `POST /hr-actions` with `type=terminate`.
   - `PUT /employees/{id}` with `is_active=false`, `termination_date`.
8. Success: sheet dismisses, employee card on Team tab shows "Ameacha" / "Inactive" badge in grey. SnackBar: "Employment terminated" / "Mkataba umemalizika".
9. Failure: dialog closes to sheet; error SnackBar shown.

### CRUD Operations
- **Create:** Via AddHrActionSheet with confirmation dialog.
- **Read:** Red "Terminated" badge in History timeline; employee card grayed out in Team list.
- **Edit:** NOT AVAILABLE — immutable HR record.
- **Delete:** NOT AVAILABLE — audit trail protected.

### Notifications & Reminders
- ⚠️ **Employee notification (push):** `"📋 Mkataba wako na [Business Name] umeisha kuanzia [Termination Date]. Wasiliana na ofisi kwa maswali."` — sent on save.
- ⚠️ **Manager alert (in-app):** "Kumbuka kukamilisha mchakato wa kutoka kwa [Name]: rejesha vifaa, futa ufikiaji." — checklist card shown on Business dashboard.
- 🔔 **Final payroll reminder (local, scheduled for termination date):** `"💰 Leo ni siku ya mwisho ya kazi ya [Name]. Hakikisha malipo ya mwisho yamekamilika."`.
- 📊 **Monthly turnover summary:** Included in "Team Changes This Month" — shows terminations vs hires ratio.

### Reports & Insights
- **Turnover Rate:** "X employees left in last 12 months (Y% turnover rate)". Benchmark against industry average.
- **Termination Reasons Report:** Pie chart of termination reasons — resignation, redundancy, misconduct, etc.
- **Cost of Turnover:** Estimated cost to replace = 1.5× annual salary; shown as insight card after termination.
- **Tenure at Exit:** Average employee tenure at termination across all leavers.

### Cross-Module Connections
- **Budget:** Salary cost removed from "Mishahara" envelope starting termination month. Projected savings shown.
- **Calendar:** "Last day of work for [Name]" event created automatically.
- **Wallet:** Prompt: "Calculate final salary payment?" — navigates to Payroll tab with employee pre-selected.
- **Shangazi AI:** "Ask Shangazi about offboarding checklist" — passes business type and employee role.

---

## 4. REHIRE — Kuajiri Tena

**Entry:** Business Profile → Team tab → (inactive employee) → "+ HR Action" FAB → "Rehire" / "Kuajiri Tena"
**Stage/Context:** Manager brings back a previously terminated employee.

### User Journey
1. Manager finds the inactive employee (grayed card on Team tab, filtered via "Show Inactive" toggle).
2. Opens `EmployeeDetailPage` → taps "+ HR Action" FAB.
3. Selects **Rehire / Kuajiri Tena** chip under Employment.
4. Fields (pre-filled from last active record):
   - **New Position / Cheo** — TextField, pre-filled with last known position.
   - **New Salary (TZS) / Mshahara** — number TextField, pre-filled with last known salary.
   - **Start Date / Tarehe ya Kuanza** — date picker (required).
   - **Notes / Maelezo** — optional (e.g., "Returning from maternity leave gap").
5. Manager confirms details → taps **Rehire / Ajiri Tena** (green button).
6. App calls:
   - `POST /hr-actions` with `type=rehire`.
   - `PUT /employees/{id}` with `is_active=true`, `position`, `gross_salary`, `start_date`.
7. Success: employee card re-activates (color restored), SnackBar "Employee rehired" / "Mfanyakazi ameajiriwa tena".

### CRUD Operations
- **Create:** Via AddHrActionSheet on inactive employee.
- **Read:** Green "Rehired" badge in History timeline; active badge restored on card.
- **Edit:** NOT AVAILABLE.
- **Delete:** NOT AVAILABLE.

### Notifications & Reminders
- 🎉 **Employee notification (push):** `"🎉 Karibu tena [Name]! Unaanza kazi [Business Name] tena tarehe [Start Date]."`.
- 🔔 **Manager reminder (local):** `"📅 [Name] anaanza kazi tena leo. Msalimie na umpa mwongozo."` — morning of start date.
- 📊 **Re-hire included in "New Joiners This Month"** digest on dashboard.

### Reports & Insights
- **Rehire Rate:** "X of Y former employees rehired (Z%)".
- **Gap Analysis:** Average months between termination and rehire.
- **Salary Change on Rehire:** "Rehired at TZS X — Y% above/below last salary".

### Cross-Module Connections
- **Budget:** Salary cost re-added to "Mishahara" envelope from start date.
- **Calendar:** "First day back — [Name]" event created.
- **Shangazi AI:** "Ask Shangazi: Onboarding checklist for returning employees."

---

## 5. SALARY REVIEW — Pitia Mshahara

**Entry:** Business Profile → Team tab → Employee card → "+ HR Action" FAB → "Salary Review" / "Pitia Mshahara"
**Stage/Context:** Manager adjusts salary outside of a promotion cycle (e.g., cost-of-living adjustment, market correction).

### User Journey
1. Opens `EmployeeDetailPage` → taps "+ HR Action" FAB → selects **Salary Review / Pitia Mshahara** under Compensation.
2. Fields:
   - **New Salary (TZS) / Mshahara Mpya** — number TextField, pre-filled with current `grossSalary`. Shows "Current: TZS [X]" as hint.
   - **Effective Date / Tarehe ya Kuanza** — date picker (required).
   - **Notes / Maelezo** — optional (e.g., "Annual cost-of-living adjustment").
3. Manager updates salary → taps **Save / Hifadhi**.
4. App calls:
   - `POST /hr-actions` with `type=salary_review`.
   - `PUT /employees/{id}` with `gross_salary`.
5. Success: SnackBar "Salary updated" / "Mshahara umesasishwa". Salary field on detail page updates.

### CRUD Operations
- **Create:** Via AddHrActionSheet.
- **Read:** Blue "Salary Review" badge in History timeline; shows old TZS → new TZS delta.
- **Edit:** NOT AVAILABLE — re-create with corrected values.
- **Delete:** NOT AVAILABLE.

### Notifications & Reminders
- 🔔 **Employee notification (push):** `"💰 Mshahara wako umesasishwa hadi TZS [Amount] kuanzia [Date]."`.
- ⚠️ **Budget alert (in-app):** If new salary exceeds payroll budget envelope: `"⚠️ Ongezeko la mshahara wa [Name] linazidi bajeti ya mishahara kwa TZS [Amount]."`.
- 📊 **Annual review prompt (local, every 12 months):** `"📅 Imepita mwaka mmoja tangu mshahara wa [Name] ulisasishwa. Je, ni wakati wa mapitio?"`.

### Reports & Insights
- **Salary History Chart:** Line chart of salary changes over employee's tenure.
- **Team Salary Distribution:** Box plot or bar chart of salary ranges across all employees.
- **Market Comparison:** "TZS [X] for [Position] — average for this role in Tanzania is TZS [Y]" (if market data available).
- **Payroll Cost Trend:** Monthly payroll total trend across all employees.

### Cross-Module Connections
- **Budget:** Salary delta flagged in "Mishahara" envelope; projected monthly payroll recalculated.
- **Calendar:** Effective date saved as "Salary Review effective — [Name]".
- **Shangazi AI:** "Ask Shangazi: Is TZS [amount] competitive for a [position] in Tanzania?"

---

## 6. BONUS — Bonasi

**Entry:** Business Profile → Team tab → Employee card → "+ HR Action" FAB → "Bonus" / "Bonasi"
**Stage/Context:** Manager records a one-time bonus payment (does not change base salary).

### User Journey
1. Opens `EmployeeDetailPage` → taps "+ HR Action" FAB → selects **Bonus / Bonasi** under Compensation.
2. Fields:
   - **Bonus Amount (TZS) / Kiasi cha Bonasi** — number TextField (required).
   - **Description / Maelezo** — TextField (required). Examples: "Q4 performance bonus", "Holiday gift".
   - **Action Date / Tarehe** — date picker, defaults to today.
3. Taps **Save / Hifadhi**.
4. App calls `POST /hr-actions` with `type=bonus`, `amount`, `description`. No employee record update.
5. Success: SnackBar "Bonus recorded" / "Bonasi imehifadhiwa".

### CRUD Operations
- **Create:** Via AddHrActionSheet.
- **Read:** Gold "Bonus" badge in History timeline with amount and description.
- **Edit:** NOT AVAILABLE.
- **Delete:** NOT AVAILABLE.

### Notifications & Reminders
- 🎉 **Employee notification (push):** `"🎉 Hongera [Name]! Umepata bonasi ya TZS [Amount] kwa [Description]."`.
- 📊 **Monthly bonus summary (in-app):** "Jumla ya bonasi zilizolipwa mwezi huu: TZS [Total] kwa wafanyakazi [N]".
- 💡 **Year-end prompt (local, November):** `"📅 Mwaka unakwisha. Je, unataka kutoa bonasi za mwisho wa mwaka?"`.

### Reports & Insights
- **Bonus History:** All bonuses paid to this employee — date, amount, reason.
- **Total Bonus Cost YTD:** Running total of bonus payments across all employees this year.
- **Bonus vs Base Salary Ratio:** "Bonuses paid = X% of annual payroll" — business-level benchmark.

### Cross-Module Connections
- **Budget:** Bonus recorded as one-time expense in "Mishahara" or "Matumizi" envelope, prompting manager to confirm budget category.
- **Wallet:** Prompt: "Pay this bonus via M-Pesa?" → WalletService with amount pre-filled.
- **Shangazi AI:** "Ask Shangazi: What's a fair bonus structure for small businesses in Tanzania?"

---

## 7. WARNING — Onyo

**Entry:** Business Profile → Team tab → Employee card → "+ HR Action" FAB → "Warning" / "Onyo"
**Stage/Context:** Manager issues a formal verbal or written warning for misconduct or performance.

### User Journey
1. Opens `EmployeeDetailPage` → taps "+ HR Action" FAB → selects **Warning / Onyo** under Discipline.
2. Fields:
   - **Warning Date / Tarehe ya Onyo** — date picker (required), defaults to today.
   - **Reason / Sababu** — multiline TextField (required). Hint: "Describe the incident clearly."
   - **Notes / Maelezo** — optional additional context.
3. Taps **Save / Hifadhi**.
4. App calls `POST /hr-actions` with `type=warning`. No employee record change.
5. Success: SnackBar "Warning recorded" / "Onyo limehifadhiwa". Yellow "Warning" badge appears in History.

### CRUD Operations
- **Create:** Via AddHrActionSheet.
- **Read:** Yellow "Warning" badge in employee History timeline; detail screen shows count of warnings in "Discipline" section.
- **Edit:** NOT AVAILABLE.
- **Delete:** NOT AVAILABLE.

### Notifications & Reminders
- ⚠️ **Employee notification (push):** `"⚠️ [Name], umepewa onyo rasmi tarehe [Date]. Maelezo: [Reason]. Wasiliana na meneja wako."`.
- ⚠️ **Manager alert (in-app):** After 2nd warning: "⚠️ [Name] ana maonyo 2. Kama tatizo linaendelea, fikiria Onyo la Mwisho." — in-app card on employee detail page.
- 📊 **Discipline summary (monthly, in-app):** "Hatua za kinidhamu mwezi huu: Maonyo [N], Kusimamishwa [N]".

### Reports & Insights
- **Discipline Timeline:** All warnings, suspensions, PIPs in chronological order for this employee.
- **Repeat Offender Alert:** If 2+ warnings in 90 days: red banner on employee card "Angalizo: Maonyo mengi".
- **Team Discipline Rate:** "X% of team received discipline action this quarter" — business-level.

### Cross-Module Connections
- **Calendar:** "Warning issued — [Name]" event logged (private, manager-only visibility).
- **Shangazi AI:** "Ask Shangazi: How to handle repeated tardiness professionally in Tanzania."

---

## 8. FINAL WARNING — Onyo la Mwisho

**Entry:** Business Profile → Team tab → Employee card → "+ HR Action" FAB → "Final Warning" / "Onyo la Mwisho"
**Stage/Context:** Last formal notice before termination. Legally significant record.

### User Journey
1. Opens `EmployeeDetailPage` → taps "+ HR Action" FAB → selects **Final Warning / Onyo la Mwisho** under Discipline.
2. App shows **orange-tinted warning banner**: "Onyo la Mwisho ni hatua kubwa. Hakikisha umefuata mchakato sahihi wa kisheria."
3. Fields:
   - **Warning Date / Tarehe** — date picker (required).
   - **Reason / Sababu** — multiline TextField (required).
   - **Notes / Maelezo** — optional.
4. Taps **Save / Hifadhi**.
5. App calls `POST /hr-actions` with `type=final_warning`. No employee record change.
6. Success: SnackBar "Final warning recorded" / "Onyo la mwisho limehifadhiwa". Red "Final Warning" badge in History.

### CRUD Operations
- **Create:** Via AddHrActionSheet.
- **Read:** Red "Final Warning" badge in History; employee card shows discipline warning indicator.
- **Edit:** NOT AVAILABLE.
- **Delete:** NOT AVAILABLE.

### Notifications & Reminders
- ⚠️ **Employee notification (push):** `"🚨 [Name], umepewa Onyo la Mwisho tarehe [Date]. Sababu: [Reason]. Hii ni hatua ya mwisho kabla ya kuchukua hatua zaidi."`.
- ⚠️ **Manager prompt (in-app card):** "Kama tatizo linaendelea, unaweza kumaliza mkataba. Jitayarishe nyaraka za kisheria."
- 🔔 **30-day follow-up reminder (local):** `"📅 Imepita siku 30 tangu Onyo la Mwisho la [Name]. Je, hali imeboresha?"`.

### Reports & Insights
- **Discipline Escalation Path:** Timeline showing Warning → Final Warning for this employee — visible to manager only.
- **Legal Risk Indicator:** "This employee has a Final Warning on record — consult HR/legal before next disciplinary action."

### Cross-Module Connections
- **Calendar:** 30-day follow-up check-in event auto-created.
- **Shangazi AI:** "Ask Shangazi: What are my legal obligations after issuing a final warning in Tanzania?"

---

## 9. SUSPENSION — Simamisha

**Entry:** Business Profile → Team tab → Employee card → "+ HR Action" FAB → "Suspend" / "Simamisha"
**Stage/Context:** Manager temporarily removes employee from duty, pending investigation or as a disciplinary measure.

### User Journey
1. Opens `EmployeeDetailPage` → taps "+ HR Action" FAB → selects **Suspend / Simamisha** under Discipline.
2. App shows **orange-tinted banner**: "Kusimamishwa kutaweka `is_active = false` hadi tarehe ya kurudi."
3. Fields:
   - **Suspension Date / Tarehe ya Kusimamishwa** — date picker (required), defaults to today.
   - **Return Date / Tarehe ya Kurudi** — date picker (required, must be after suspension date).
   - **Reason / Sababu** — multiline TextField (required).
   - **Notes / Maelezo** — optional.
4. Taps **Suspend / Simamisha** (orange button).
5. App calls:
   - `POST /hr-actions` with `type=suspension`, `suspension_date`, `return_date`.
   - `PUT /employees/{id}` with `is_active=false`.
6. Success: employee card shows "Suspended" / "Amesimamishwa" badge in orange. SnackBar confirms.
7. On return date: system should prompt manager to "Reactivate employee" (in-app notification).

### CRUD Operations
- **Create:** Via AddHrActionSheet.
- **Read:** Orange "Suspended" badge in History; employee card shows suspension status and return date.
- **Edit:** NOT AVAILABLE — issue a Rehire action to reactivate early.
- **Delete:** NOT AVAILABLE.

### Notifications & Reminders
- ⚠️ **Employee notification (push):** `"🔴 [Name], umesimamishwa kazi kuanzia [Suspension Date] hadi [Return Date]. Sababu: [Reason]."`.
- 🔔 **Return date reminder (push, day before):** `"📅 [Name] anarudi kesho ([Return Date]). Je, uko tayari kumkaribisha?"` — sent to manager.
- 🔔 **Return date reminder (push, same day):** `"📅 [Name] anarudi leo. Kumbuka kuwezesha akaunti yake."` — sent to manager.
- ⚠️ **Payroll alert (in-app):** "Mfanyakazi aliyesimamishwa — angalia miongozo ya kulipa au kutolipa wakati wa kusimamishwa."

### Reports & Insights
- **Suspension Duration:** Days suspended vs return date — track if employee returned on schedule.
- **Active Suspensions:** Real-time count on Business dashboard of employees currently suspended.
- **Suspension Frequency:** "Y suspensions in last 12 months across all employees."

### Cross-Module Connections
- **Calendar:** Both suspension start and return date synced as events. Manager gets reminder on return date.
- **Budget:** Prompt: "Is this employee paid during suspension? Update payroll accordingly."
- **Shangazi AI:** "Ask Shangazi: What does Tanzanian labour law say about pay during suspension?"

---

## 10. LEAVE APPROVAL — Idhini Likizo

**Entry:** Business Profile → Team tab → Employee card → "+ HR Action" FAB → "Approve Leave" / "Idhini Likizo"
**Stage/Context:** Manager formally approves a leave request that may have come verbally or via TAJIRI messaging.

### User Journey
1. Opens `EmployeeDetailPage` → taps "+ HR Action" FAB → selects **Approve Leave / Idhini Likizo** under Leave.
2. Fields:
   - **Leave Start Date / Tarehe ya Kuanza Likizo** — date picker (required).
   - **Leave End Date / Tarehe ya Kumaliza Likizo** — date picker (required, must be ≥ start date). App auto-calculates "X days" below.
   - **Notes / Maelezo** — optional (leave type: annual, sick, maternity, etc.).
3. Taps **Approve / Idhini**.
4. App calls `POST /hr-actions` with `type=leave_approval`, `start_date`, `end_date`. No employee `is_active` change.
5. Success: SnackBar "Leave approved" / "Likizo imeidhinishwa". Green "Leave" badge in History timeline.

### CRUD Operations
- **Create:** Via AddHrActionSheet.
- **Read:** Green "Leave Approved" badge showing date range and duration in days.
- **Edit:** NOT AVAILABLE — reject and re-approve with correct dates.
- **Delete:** NOT AVAILABLE.

### Notifications & Reminders
- 🎉 **Employee notification (push):** `"✅ Likizo yako [Start Date] — [End Date] imeidhinishwa! Pumzika vizuri."`.
- 🔔 **Return reminder (push, day before return date):** `"📅 Likizo ya [Name] inaisha kesho. Je, wamejulisha kurudi?"` — to manager.
- 🔔 **Coverage reminder (push, day of leave start):** `"📅 [Name] anaanza likizo leo ([Start Date]). Kazi zake zimegawanywa?"` — to manager.
- ⚠️ **Overlapping leave alert (in-app):** If another employee already on leave same dates: "Angalizo: [Other Name] pia yuko likizoni wakati huo. Angalia mzigo wa kazi."

### Reports & Insights
- **Leave Balance Tracker:** If leave quotas are tracked: "Used X of Y annual leave days." (requires leave balance model — flag as future feature).
- **Team Leave Calendar:** Visual calendar of who is on leave when across all employees.
- **Leave Patterns:** "Peak leave months: December, August" — helps plan staffing.

### Cross-Module Connections
- **Calendar:** Leave period synced as a blocked event on business calendar. Employee appears as "Out of Office".
- **Shangazi AI:** "Ask Shangazi: How many annual leave days are employees entitled to under Tanzania's Employment Act?"

---

## 11. LEAVE REJECTION — Kataa Likizo

**Entry:** Business Profile → Team tab → Employee card → "+ HR Action" FAB → "Reject Leave" / "Kataa Likizo"
**Stage/Context:** Manager formally declines a leave request and provides a reason.

### User Journey
1. Opens `EmployeeDetailPage` → taps "+ HR Action" FAB → selects **Reject Leave / Kataa Likizo** under Leave.
2. Fields:
   - **Rejection Date / Tarehe** — date picker (required), defaults to today.
   - **Reason / Sababu** — multiline TextField (required). Hint: "Provide a clear reason — employee may dispute."
   - **Notes / Maelezo** — optional.
3. Taps **Reject / Kataa** (red outline button).
4. App calls `POST /hr-actions` with `type=leave_rejection`. No employee record change.
5. Success: SnackBar "Leave rejected" / "Likizo imekataliwa". Red "Leave Rejected" badge in History.

### CRUD Operations
- **Create:** Via AddHrActionSheet.
- **Read:** Red "Leave Rejected" badge with reason in History timeline.
- **Edit:** NOT AVAILABLE.
- **Delete:** NOT AVAILABLE.

### Notifications & Reminders
- ⚠️ **Employee notification (push):** `"❌ [Name], ombi lako la likizo limekataliwa. Sababu: [Reason]. Wasiliana na meneja wako kwa maswali."`.
- 💡 **Alternative suggestion prompt (in-app, on manager's screen after save):** "Unaweza kupendekeza tarehe mbadala ya likizo kwa [Name]?" — one-tap to open Leave Approval for different dates.

### Reports & Insights
- **Rejection Rate:** "X of Y leave requests rejected this year — Y% rejection rate." High rates may signal understaffing.
- **Rejection Reasons:** Common reasons tracked for HR insight ("Peak season", "Staff shortage").

### Cross-Module Connections
- **Calendar:** No event created (leave rejected).
- **Shangazi AI:** "Ask Shangazi: What are acceptable grounds for rejecting leave under Tanzanian law?"

---

## 12. PERFORMANCE REVIEW — Tathmini ya Utendaji

**Entry:** Business Profile → Team tab → Employee card → "+ HR Action" FAB → "Perf. Review" / "Tathmini"
**Stage/Context:** Manager conducts a formal performance review — typically quarterly or annually.

### User Journey
1. Opens `EmployeeDetailPage` → taps "+ HR Action" FAB → selects **Perf. Review / Tathmini** under Performance.
2. Fields:
   - **Review Date / Tarehe ya Tathmini** — date picker (required).
   - **Rating / Tathmini** — segmented control or dropdown: "Bora Sana (5) / Excellent", "Nzuri (4) / Good", "Wastani (3) / Average", "Inabidi Kuboresha (2) / Needs Improvement", "Mbaya (1) / Poor".
   - **Notes / Maelezo** — multiline TextField (required). Detailed performance notes.
3. Taps **Save / Hifadhi**.
4. App calls `POST /hr-actions` with `type=performance_review`, `rating`, `notes`. No employee record change.
5. Success: SnackBar "Review recorded" / "Tathmini imehifadhiwa". Blue "Review" badge in History.

### CRUD Operations
- **Create:** Via AddHrActionSheet.
- **Read:** Blue "Review" badge with star rating (★★★★☆) and date in History timeline.
- **Edit:** NOT AVAILABLE — re-create if incorrect.
- **Delete:** NOT AVAILABLE.

### Notifications & Reminders
- 🔔 **Employee notification (push):** `"📋 Tathmini yako ya utendaji imekamilika. Rating: [X/5]. Ona maelezo na meneja wako."`.
- 🔔 **Quarterly review reminder (local, every 3 months):** `"📅 Ni wakati wa tathmini ya robo mwaka kwa [Name]. Fanya tathmini leo."` — to manager.
- ⚠️ **Low rating alert (in-app):** If rating ≤ 2: "Utendaji wa [Name] uko chini ya wastani. Fikiria kuunda Mpango wa Kuboresha (PIP)." — with quick action button to open PIP sheet.
- 📊 **Annual review summary (push, December):** `"📊 Tathmini za mwaka zimekamilika kwa wafanyakazi [N]. Angalia ripoti kamili."`.

### Reports & Insights
- **Performance Trend:** Line chart of ratings over time for this employee.
- **Team Performance Distribution:** Histogram of ratings across all employees — shows bell curve or skew.
- **High Performers:** "Top 20% of team this quarter: [Names]" — prompt to reward them.
- **Low Performers:** "Bottom 20%: [Names]" — prompt to create PIPs.
- **Review Completion Rate:** "X of Y employees reviewed this quarter (Z%)."

### Cross-Module Connections
- **Calendar:** "Performance Review — [Name]" event created on review date. Next review scheduled automatically in 3 months.
- **Shangazi AI:** "Ask Shangazi: How to give constructive feedback to an underperforming employee."

---

## 13. IMPROVEMENT PLAN — Mpango wa Kuboresha (PIP)

**Entry:** Business Profile → Team tab → Employee card → "+ HR Action" FAB → "Impr. Plan" / "Mpango"
**Stage/Context:** Formal structured plan to help an underperforming employee meet expectations within a set timeframe.

### User Journey
1. Opens `EmployeeDetailPage` → taps "+ HR Action" FAB → selects **Impr. Plan / Mpango** under Performance.
2. App shows **blue info banner**: "PIP ni mpango wa kukusaidia mfanyakazi kuboresha utendaji. Weka malengo wazi na kipindi cha wakati."
3. Fields:
   - **Plan Start Date / Tarehe ya Kuanza** — date picker (required).
   - **Plan End Date / Tarehe ya Kumaliza** — date picker (required, must be ≥ 30 days from start).
   - **Goals & Notes / Malengo na Maelezo** — multiline TextField (required). Detailed, measurable goals.
4. Taps **Save / Hifadhi**.
5. App calls `POST /hr-actions` with `type=pip`, `start_date`, `end_date`, `notes`. No employee record change.
6. Success: Orange "PIP Active" badge on employee card during PIP period. SnackBar confirmed.

### CRUD Operations
- **Create:** Via AddHrActionSheet.
- **Read:** Orange "PIP" badge in History; employee card shows "PIP Active" with countdown to end date.
- **Edit:** NOT AVAILABLE.
- **Delete:** NOT AVAILABLE.

### Notifications & Reminders
- ⚠️ **Employee notification (push):** `"📋 [Name], Mpango wa Kuboresha umewekwa kwa kipindi cha [Start Date] — [End Date]. Angalia malengo yako na meneja."`.
- 🔔 **Mid-point check-in (local, halfway through PIP):** `"📅 Nusu ya mpango wa [Name] imepita. Je, maendeleo yanaendeleaje? Fanya ukaguzi wa kati."` — to manager.
- 🔔 **PIP end reminder (push, 7 days before end):** `"📅 Mpango wa [Name] unaisha siku 7. Toa tathmini ya mwisho."`.
- ⚠️ **PIP expiry (push, on end date):** `"📅 Mpango wa [Name] umeisha leo. Thibitisha uamuzi: kukuza, kuendelea, au kumaliza mkataba."`.

### Reports & Insights
- **PIP Success Rate:** "X of Y PIPs resulted in improved performance — Z% success rate."
- **Active PIPs Dashboard:** Real-time count and list of employees currently on PIP on Business dashboard.
- **Average PIP Duration:** Benchmark for how long PIPs typically run.

### Cross-Module Connections
- **Calendar:** Start date, mid-point check-in, and end date all synced to business calendar.
- **Shangazi AI:** "Ask Shangazi: How to write an effective Performance Improvement Plan."

---

## 14. CERTIFICATE — Cheti

**Entry:** Business Profile → Team tab → Employee card → "+ HR Action" FAB → "Certificate" / "Cheti"
**Stage/Context:** Manager issues or records a certificate (service, appreciation, training completion, etc.).

### User Journey
1. Opens `EmployeeDetailPage` → taps "+ HR Action" FAB → selects **Certificate / Cheti** under Document.
2. Fields:
   - **Certificate Date / Tarehe ya Cheti** — date picker (required).
   - **Certificate Type / Aina ya Cheti** — dropdown: "Certificate of Service / Cheti cha Huduma", "Letter of Appreciation / Barua ya Shukrani", "Training Completion / Kukamilisha Mafunzo", "Award / Tuzo", "Other / Nyingine".
   - **Notes / Maelezo** — optional (e.g., training provider name, award description).
3. Taps **Save / Hifadhi**.
4. App calls `POST /hr-actions` with `type=certificate`, `certificate_type`, `action_date`, `notes`. No employee record change.
5. Success: Gold "Certificate" badge in History timeline. SnackBar confirmed.

### CRUD Operations
- **Create:** Via AddHrActionSheet.
- **Read:** Gold star "Certificate" badge with type and date in History.
- **Edit:** NOT AVAILABLE.
- **Delete:** NOT AVAILABLE.

### Notifications & Reminders
- 🎉 **Employee notification (push):** `"🏅 Hongera [Name]! Umepewa [Certificate Type] tarehe [Date]. Angalia akaunti yako kwa nakala."`.
- 💡 **Anniversary prompt (local, annual on issue date):** `"📅 Leo ni mwaka mmoja tangu [Name] alipewa [Certificate Type]. Mheshimu tena?"`.

### Reports & Insights
- **Certificates Issued:** Full list of all certificates across all employees — filterable by type and date.
- **Recognition Rate:** "X employees received appreciation certificates this year."

### Cross-Module Connections
- **Shangazi AI:** "Ask Shangazi: How to write a Certificate of Service in Tanzania."

---

## 15. CONTRACT RENEWAL — Fanya Upya Mkataba

**Entry:** Business Profile → Team tab → Employee card → "+ HR Action" FAB → "Renew Contract" / "Fanya Upya"
**Stage/Context:** Manager renews or changes the contract type and terms for an employee.

### User Journey
1. Opens `EmployeeDetailPage` → taps "+ HR Action" FAB → selects **Renew Contract / Fanya Upya** under Document.
2. Fields (pre-filled from current employee):
   - **Contract Type / Aina ya Mkataba** — segmented control: "Permanent / Kudumu", "Contract / Muda Maalum", "Part-time / Saa Chache". Pre-filled from current `contractType`.
   - **New Start Date / Tarehe ya Kuanza** — date picker (required).
   - **Contract End Date / Tarehe ya Kumalizika** — date picker (required if Contract/Part-time; hidden for Permanent).
   - **Notes / Maelezo** — optional.
3. Taps **Renew / Fanya Upya**.
4. App calls:
   - `POST /hr-actions` with `type=contract_renewal`, `contract_type`, `start_date`, `end_date`.
   - `PUT /employees/{id}` with `contract_type`, `start_date`.
5. Success: SnackBar "Contract renewed" / "Mkataba umefanywa upya". Contract details updated on detail page.

### CRUD Operations
- **Create:** Via AddHrActionSheet.
- **Read:** Purple "Contract Renewed" badge in History with new type and dates.
- **Edit:** NOT AVAILABLE — issue another renewal to override.
- **Delete:** NOT AVAILABLE.

### Notifications & Reminders
- 🔔 **Employee notification (push):** `"📄 [Name], mkataba wako umefanywa upya. Aina: [Contract Type]. Inaanza: [Start Date]."`.
- ⚠️ **Expiry alert (push, 30 days before contract end date):** `"⚠️ Mkataba wa [Name] unaisha siku 30. Fanya upya au mjulishe mfanyakazi."` — to manager.
- ⚠️ **Expiry alert (push, 7 days before end):** `"🚨 Mkataba wa [Name] unaisha siku 7! Chukua hatua sasa."`.
- ⚠️ **Expiry alert (push, on end date):** `"🔴 Mkataba wa [Name] umeisha leo. Fanya upya au maliza mkataba."`.
- 📊 **Contracts expiring this month (in-app card, 1st of each month):** "Mikataba inayoisha mwezi huu: [Names & dates]".

### Reports & Insights
- **Contract Expiry Calendar:** Visual timeline of all employee contract end dates — filterable by month.
- **Contract Type Distribution:** "Permanent: X%, Contract: Y%, Part-time: Z%" — pie chart on Business dashboard.
- **Renewal Rate:** "X of Y expiring contracts renewed — Z% retention."
- **Average Contract Duration:** For contract employees, average months before renewal or exit.

### Cross-Module Connections
- **Calendar:** Contract start date and end date both synced. Reminders at 30 days and 7 days before expiry created automatically.
- **Budget:** Contract type change (e.g., part-time → permanent) triggers payroll cost projection update.
- **Shangazi AI:** "Ask Shangazi: What are the differences between employment contract types under Tanzanian law?"

---

## Notification Channel Summary

| Trigger | Channel | Timing | Recipient |
|---------|---------|--------|-----------|
| Promotion saved | Push | Immediately | Employee |
| Promotion effective date | Local | Night before | Manager |
| Transfer saved | Push | Immediately | Employee |
| Termination saved | Push | Immediately | Employee |
| Termination date | Local | Morning of date | Manager |
| Rehire saved | Push | Immediately | Employee |
| Rehire start date | Local | Morning of start | Manager |
| Salary changed | Push | Immediately | Employee |
| Annual salary review due | Local | 12 months after last review | Manager |
| Bonus given | Push | Immediately | Employee |
| Year-end bonus prompt | Local | November | Manager |
| Warning issued | Push | Immediately | Employee |
| 2nd warning escalation | In-app | On save of 2nd warning | Manager |
| Final warning issued | Push | Immediately | Employee |
| 30-day follow-up after final warning | Local | 30 days later | Manager |
| Suspension start | Push | Immediately | Employee |
| Return from suspension (day before) | Push | 1 day before | Manager |
| Return from suspension (day of) | Push | Morning | Manager |
| Leave approved | Push | Immediately | Employee |
| Leave coverage prompt | Push | Day of leave start | Manager |
| Leave rejected | Push | Immediately | Employee |
| Quarterly performance review due | Local | Every 3 months | Manager |
| Low performance rating | In-app | On save | Manager |
| PIP started | Push | Immediately | Employee |
| PIP mid-point check-in | Local | Halfway through PIP | Manager |
| PIP ending in 7 days | Push | 7 days before end | Manager |
| PIP expired | Push | On end date | Manager |
| Certificate issued | Push | Immediately | Employee |
| Contract expiry 30 days | Push | 30 days before end | Manager |
| Contract expiry 7 days | Push | 7 days before end | Manager |
| Contract expired | Push | On end date | Manager |

---

## Cross-Module Integration Map

| HR Action | Budget | Calendar | Wallet | Shangazi AI |
|-----------|--------|----------|--------|-------------|
| Promote | Salary delta → payroll envelope | Effective date event | — | Promotion best practices |
| Transfer | Cost centre reassignment | Transfer effective event | — | Team structure advice |
| Terminate | Remove from payroll | Last day event | Final salary payment | Offboarding checklist |
| Rehire | Re-add to payroll | First day back event | — | Onboarding for returnees |
| Salary Review | Payroll projection update | Effective date event | — | Market salary benchmarking |
| Bonus | One-time expense | — | M-Pesa payment prompt | Bonus structure advice |
| Warning | — | Warning logged (private) | — | Discipline best practices |
| Final Warning | — | 30-day check-in event | — | Legal obligations in Tanzania |
| Suspension | Payroll query prompt | Suspension period blocked | — | Labour law on suspension pay |
| Leave Approval | — | Leave period blocked | — | Annual leave entitlements |
| Leave Rejection | — | — | — | Legal grounds for rejection |
| Performance Review | — | Review + next review event | — | Constructive feedback |
| Improvement Plan | — | Start/mid/end events | — | How to write a PIP |
| Certificate | — | — | — | Writing service certificates |
| Contract Renewal | Payroll cost update | Start + expiry events | — | Contract type legal differences |
