# Work Management & My Job — Complete User Journeys

**Module:** lib/team/ (manager side) + lib/myjob/ (employee side)
**Source spec:** docs/superpowers/specs/2026-04-20-work-myjob-design.md

Every feature must be: **Interactive** (notifications, reminders, prompts), **Connected** (Budget, Calendar, Wallet, Shangazi AI), and **Insightful** (reports, trends, recommendations).

---

## 1. JOB DESCRIPTION — CREATE / EDIT

**Entry:** Business Profile → Team tab → Tap employee card → Employee Detail Page → "Work Profile" card → "View / Edit" / "Tazama / Hariri"
**Stage/Context:** Manager sets up or updates a job description for any active employee.

### User Journey
1. Manager opens Employee Detail Page — sees a **Work Profile** card between the Compensation card and the Tasks card.
2. Card shows: role summary (1 line, grey if empty — "Not set" / "Haijawekwa"), KPI count chip (e.g. "3 KPIs"), and "View / Edit" button.
3. Manager taps "View / Edit" → `JobDescriptionPage` pushes.
4. AppBar: employee name + pencil icon (edit action).
5. **View mode** — four card sections rendered:
   - **Role Summary:** Paragraph text or empty-state italics "No summary yet" / "Hakuna muhtasari bado".
   - **Responsibilities:** Numbered bullet list (1. 2. 3. …) or empty italics.
   - **Reporting To:** Non-editable grey chip showing owner name.
   - **KPIs:** List of `KpiCard` widgets + "Add KPI" / "Ongeza KPI" button. If empty: "No KPIs set" / "Hakuna KPI".
6. Manager taps pencil icon → AppBar changes to "Save" / "Hifadhi" action.
7. **Edit mode:**
   - Role Summary → full-screen TextField (multiline).
   - Responsibilities → reorderable list; each item has a delete icon; "Add Responsibility" / "Ongeza Jukumu" button at bottom appends a new text field.
   - Reporting To → remains a non-editable chip.
   - KPIs section → not editable here (use Add KPI button or tap KpiCard).
8. Manager taps "Save" → `PUT /business/employees/{id}/job-description` → success snackbar "Job description saved" / "Maelezo ya kazi yamehifadhiwa" → returns to view mode.
9. **API failure:** Red snackbar "Failed to save. Try again." / "Imeshindwa kuhifadhi. Jaribu tena."
10. **Empty responsibilities on save:** Allowed — role summary alone is valid.

### CRUD Operations
- **Create:** First-time save of role summary + responsibilities via PUT (upsert on backend).
- **Read:** View mode on `JobDescriptionPage`. Preview 1-line summary shown on Employee Detail Page Work Profile card.
- **Edit:** Pencil icon in AppBar → inline editing of role summary and responsibilities list.
- **Delete:** NOT AVAILABLE for job description as a whole — manager clears content manually. Individual responsibilities deleted via delete icon per item.

### Notifications & Reminders
- 💡 **Prompt — incomplete profile:** If employee has no job description 7 days after being added: "📋 [Employee name] has no job description yet. Set up their role so they know what's expected."
- 💡 **Prompt — annual review nudge:** Every 12 months since last update: "📋 [Employee name]'s job description was last updated [date]. Consider reviewing it."
- 🔔 **Reminder — employee notification on assignment:** When manager saves a job description for the first time: push to employee — "📋 Your manager has set up your job description. Tap to view your role and responsibilities."
- 🔔 **Update notification to employee:** When manager edits an existing job description: "📋 Your job description has been updated. Review what's changed in My Job → My Role."

### Reports & Insights
- **Team Coverage Report** (Work Board): Percentage of active employees who have a job description assigned. "8 of 10 employees have job descriptions set. 2 remaining: [names]."
- **Description Age Report:** Shows for each employee how many days since their job description was last updated. Flag descriptions older than 365 days as "Needs review".

### Cross-Module Connections
- **Calendar:** When a job description is first created, prompt manager: "Add a 3-month review date to Calendar?" → `CalendarService.createEvent()` with title "[Name] Role Review" and date 90 days out.
- **Shangazi AI:** Manager can tap "Ask Shangazi" from `JobDescriptionPage` with context: employee role + responsibilities → AI suggests additional responsibilities or KPIs relevant to the role.

---

## 2. KPI SETUP — CREATE / EDIT / DELETE

**Entry:** Business Profile → Team tab → Employee card → Employee Detail Page → Work Profile card → "View / Edit" → `JobDescriptionPage` → "Add KPI" / "Ongeza KPI"
**Stage/Context:** Manager defines measurable performance targets for an employee.

### User Journey
1. Manager is on `JobDescriptionPage` in view mode and taps "Add KPI" / "Ongeza KPI".
2. A bottom sheet slides up: "Add KPI" / "Ongeza KPI" title.
3. Form fields:
   - **KPI Name** (TextField, required): e.g. "Customer Satisfaction Score"
   - **Target Value** (number field, required): e.g. `95`
   - **Unit** (dropdown: `%` / `TZS` / `count` / `hrs` / `Custom`): if Custom selected, an additional TextField appears.
   - **Review Period** (segmented control: `Monthly` / `Quarterly` / `Annual`).
4. Manager taps "Save" / "Hifadhi" → `POST /business/kpis` → sheet closes → KpiCard appears in list with name, target, and period chip.
5. **Edit existing KPI:** Long-press `KpiCard` → bottom sheet pre-filled with current values → edit fields → "Update" / "Sasisha" → `PUT /business/kpis/{id}`.
6. **Delete KPI:** Long-press `KpiCard` → "Delete KPI" option → confirmation dialog "Delete [name]? All logged entries will also be removed." / "Futa [jina]? Rekodi zote zitafutwa pia." → "Delete" / "Futa" → `DELETE /business/kpis/{id}`.
7. **Validation:** name empty → red border + "Enter KPI name"; target empty → "Enter target value"; unit not selected → "Select a unit".
8. **Empty state on `JobDescriptionPage` KPIs section:** "No KPI targets set. Tap + to add the first one." / "Hakuna malengo ya KPI. Gonga + kuongeza."

### CRUD Operations
- **Create:** "Add KPI" bottom sheet → POST /business/kpis.
- **Read:** `KpiCard` list on `JobDescriptionPage`. Each card shows name · target (formatted with unit) · review period chip · mini sparkline of last 6 entries.
- **Edit:** Long-press `KpiCard` → pre-filled bottom sheet → PUT /business/kpis/{id}.
- **Delete:** Long-press `KpiCard` → confirmation → DELETE /business/kpis/{id}.

### Notifications & Reminders
- 🔔 **Review period reminder:** At the start of each review period (monthly = 1st of month, quarterly = 1st of Jan/Apr/Jul/Oct, annual = employee's start-date anniversary): "📊 Time to log [KPI name] actual for [period] for [employee name]."
- ⚠️ **Missing entry alert:** If a review period ends with no entry logged: "⚠️ [Employee name]'s [KPI name] has no entry for [period]. Log it now before the period closes."
- 🎉 **Target met celebration:** When a logged entry meets or exceeds target: "🎉 [Employee name] hit their [KPI name] target for [period]! [actual] / [target] [unit]."
- ⚠️ **Target missed alert (to manager):** When logged entry falls below target: "⚠️ [Employee name] missed [KPI name] for [period]: [actual] vs target [target] [unit]."

### Reports & Insights
- **KPI Summary Card** on Employee Detail Page: "3 KPIs — 2 on track, 1 below target" with green/red chip summary.
- **KPI trend chart** on `KpiDetailPage`: Line chart over last 12 entries — shows if employee is improving, stable, or declining.
- **Period-over-period delta:** Each `KpiEntry` row shows Δ vs previous period (e.g. "+5%" or "−TZS 30,000").

### Cross-Module Connections
- **Budget:** When a KPI has unit TZS (revenue/sales KPI), offer: "View in Business Reports" → Budget module income summary filtered to this employee.
- **Shangazi AI:** From `KpiDetailPage`, "Ask Shangazi" with context: KPI name + trend data → AI suggests coaching strategies if below target, or recommends stretching the target if consistently above.
- **Calendar:** When a review period reminder fires, offer "Add to Calendar" → `CalendarService.createEvent()` with title "[Name] — [KPI] review due".

---

## 3. KPI ENTRY LOGGING

**Entry:** `JobDescriptionPage` → tap `KpiCard` → `KpiDetailPage` → "Log Actual" FAB / "Ingiza Thamani Halisi" FAB
**Stage/Context:** Manager records the actual achieved value for a KPI at the end of a review period.

### User Journey
1. Manager opens `KpiDetailPage` — sees:
   - Header: KPI name + "Target: [value] [unit]" chip + review period chip.
   - Line chart: x-axis = period labels, y-axis = actual values, horizontal dashed target line.
   - History list: each entry as a row — period label · actual value · Δ vs target (green if met, red if missed) · note snippet.
   - "Log Actual" / "Ingiza Thamani Halisi" FAB (bottom right).
2. Manager taps FAB → bottom sheet:
   - **Period Label** (TextField, required): e.g. "April 2026" or "Q1 2026" — pre-filled with current period based on `reviewPeriod`.
   - **Actual Value** (number field, required).
   - **Note** (multiline TextField, optional): e.g. "Sick leave impacted performance".
3. Manager taps "Log" / "Ingiza" → `POST /business/kpis/{id}/entries` → sheet closes → chart updates + new row appears at top of history.
4. **Validation:** period label empty → "Enter period label"; actual value empty → "Enter actual value".
5. **Edit entry:** NOT AVAILABLE — delete and re-enter.
6. **Delete entry:** Long-press history row → confirmation dialog "Delete this entry?" / "Futa rekodi hii?" → `DELETE /business/kpi-entries/{id}` → row removed + chart updates.
7. **Empty state:** "No entries logged yet. Tap the button to log the first actual." / "Hakuna rekodi bado. Gonga kitufe kuingiza ya kwanza."

### CRUD Operations
- **Create:** "Log Actual" FAB → POST /business/kpis/{id}/entries.
- **Read:** Line chart + history list on `KpiDetailPage`.
- **Edit:** NOT AVAILABLE — delete and re-create.
- **Delete:** Long-press history row → confirmation → DELETE /business/kpi-entries/{id}.

### Notifications & Reminders
- 🔔 **Log reminder:** At period end (calculated from `reviewPeriod`): "📊 Don't forget to log [employee name]'s [KPI name] for [period]. Period ends today."
- 🎉 **Streak celebration:** When employee meets target 3 periods in a row: "🎉 [Name] has hit [KPI name] for 3 consecutive periods! Consider raising the target."
- ⚠️ **Declining trend alert:** If actual values trend down for 3 periods: "⚠️ [Name]'s [KPI name] has declined for 3 consecutive periods. Time to intervene?"

### Reports & Insights
- **Achievement rate:** "Hit target X out of Y periods (Z%)".
- **Best/worst period:** "Best: [period] at [value]. Worst: [period] at [value]."
- **Average actual vs target:** "Average: [avg] vs target [target] ([+/-]%)."

### Cross-Module Connections
- **Shangazi AI:** After logging a below-target entry, offer: "Ask Shangazi for a performance improvement plan template" with KPI context pre-filled.
- **Calendar:** After logging, offer: "Schedule a performance review conversation" → `CalendarService.createEvent()` with title "[Name] — [KPI] review chat".

---

## 4. TASK ASSIGNMENT (MANAGER)

**Entry — Employee view:** Business Profile → Team tab → Employee card → Employee Detail Page → Tasks card → "See All / Assign" → `EmployeeTasksPage` → "Assign Task" icon / "Gawanya Kazi" icon
**Entry — Board view:** Business Profile → Board tab → FAB
**Stage/Context:** Manager assigns a standing (recurring) or ad-hoc task to an employee.

### User Journey
1. Manager taps "Assign Task" icon (AppBar of `EmployeeTasksPage`) OR FAB on `WorkBoardPage`.
2. `AddWorkTaskSheet` slides up with title "Assign Task" / "Gawanya Kazi".
3. Form fields in order:
   - **Title** (TextField, required): e.g. "Daily Cash Reconciliation".
   - **Description** (multiline TextField, optional): additional context.
   - **Task Type** (segmented control): "Standing" / "Kawaida" | "Ad-hoc" / "Maalum".
   - **IF Standing selected:**
     - **Recurrence** (choice chips): "Daily" / "Kila Siku" · "Weekly" / "Kila Wiki" · "Weekdays" / "Siku za Kazi" · "Custom" / "Maalum".
     - **IF Custom:** Mon–Sun toggle row (tappable day chips: M T W T F S S).
   - **IF Ad-hoc selected:**
     - **Due Date** (date picker, required): minimum today.
   - **Assigned To** (pre-filled from employee context if opened from `EmployeeTasksPage`; employee dropdown if opened from `WorkBoardPage`).
4. Manager taps "Assign" / "Gawanya" → validation → `POST /business/tasks` → sheet closes → task appears in appropriate tab.
5. **Validation:**
   - Title empty → red border + "Enter task title" / "Weka kichwa cha kazi".
   - Standing + no recurrence selected → "Select recurrence pattern" / "Chagua mpangilio wa kurudia".
   - Ad-hoc + no due date → "Select a due date" / "Chagua tarehe ya mwisho".
6. **API failure:** Red snackbar "Failed to assign task. Try again." / "Imeshindwa kugawanya kazi. Jaribu tena."

### CRUD Operations
- **Create:** `AddWorkTaskSheet` → POST /business/tasks.
- **Read:** `EmployeeTasksPage` (tabs: Pending / In Progress / Done) + `WorkBoardPage` (all employees, filterable).
- **Edit:** Tap `WorkTaskCard` → `TaskDetailPage` → NOT directly editable. Title/description edit NOT AVAILABLE in v1 — delete and reassign.
- **Delete:** AppBar delete icon on `TaskDetailPage` → confirmation dialog "Delete this task?" / "Futa kazi hii?" → `DELETE /business/tasks/{id}` → pops back to list.

### Notifications & Reminders
- 🔔 **Assignment notification to employee:** Immediately on POST success: push to employee "📋 New task assigned: [title]. Due [date]." / "Kazi mpya: [title]. Muda wa mwisho: [tarehe]."
- 🔔 **Standing task daily reminder to employee:** Every morning at 7am for active standing tasks: "🔁 Today's standing task: [title]. Tap to update progress."
- 🔔 **Ad-hoc due date reminder:** 1 day before due date: "⏰ Task due tomorrow: [title]. Update your progress now."
- ⚠️ **Overdue alert to manager:** Ad-hoc task 1 day past due date with status not Done: "⚠️ [Employee name]'s task '[title]' is overdue since [date]. Check status."
- ⚠️ **Stale standing task alert:** Standing task with no update in 3 days: "⚠️ [Employee name] hasn't updated '[title]' in 3 days. Is it still active?"
- 🎉 **Task completed celebration:** When employee marks status Done: "✅ [Employee name] completed '[title]'!"

### Reports & Insights
- **Employee Tasks Summary** (Employee Detail Tasks card): Status count chips — Pending (N) · In Progress (N) · Done (N).
- **Completion rate:** On `EmployeeTasksPage` header: "Completion this week: X of Y ad-hoc tasks done (Z%)."
- **Standing task health:** "All [N] standing tasks updated today" or "⚠️ [N] standing tasks have no update today."

### Cross-Module Connections
- **Calendar:** Ad-hoc tasks with due dates → prompt "Add to Calendar?" → `CalendarService.createEvent()` with title "[task title] — due".
- **Budget:** If task involves a spend (e.g. "Purchase office supplies — TZS 50,000 budget"), add an optional budget field; on task completion, offer "Log this expense to Budget?"
- **Shangazi AI:** Manager can tap "Ask Shangazi" on `WorkBoardPage` with team task load context → AI suggests workload redistribution if one employee has too many pending tasks.

---

## 5. TASK REASSIGNMENT (MANAGER)

**Entry:** `EmployeeTasksPage` → long-press `WorkTaskCard` → reassign dialog
**Entry (alt):** `TaskDetailPage` → "Reassign" / "Gawanya Upya" button
**Stage/Context:** Manager moves a task from one employee to another.

### User Journey
1. Manager long-presses a `WorkTaskCard` → context bottom sheet appears with "Reassign Task" / "Gawanya Upya Kazi" option.
2. OR manager opens `TaskDetailPage` → taps "Reassign" button (below the progress ring).
3. A dialog opens: title "Reassign Task" / "Gawanya Upya Kazi".
4. **Assigned To** dropdown: list of all active employees in this business (excluding current assignee).
5. Manager selects new employee → "Reassign" / "Gawanya Upya" button.
6. → `PUT /business/tasks/{id}/reassign` with `{employee_id: newId}` → dialog closes → success snackbar "Task reassigned to [name]" / "Kazi imegawiwa kwa [jina]."
7. Task disappears from previous employee's `EmployeeTasksPage` and appears in new employee's list.
8. **Validation:** No employee selected → button stays disabled.
9. **API failure:** Red snackbar "Failed to reassign. Try again." / "Imeshindwa kugawanya upya. Jaribu tena."

### CRUD Operations
- **Create:** N/A — reassign is an update.
- **Read:** Current assignee visible in `TaskDetailPage` header as assignee chip.
- **Edit:** PUT /business/tasks/{id}/reassign.
- **Delete:** N/A.

### Notifications & Reminders
- 🔔 **New assignee notification:** Push to new employee: "📋 A task has been assigned to you: '[title]'. Previously assigned to [old name]."
- 🔔 **Old assignee notification:** Push to previous employee: "📋 Task '[title]' has been reassigned to [new name]."
- 💡 **Workload balance prompt:** If new assignee already has 5+ pending tasks: "⚠️ [New employee name] already has [N] pending tasks. Are you sure you want to reassign?"

### Reports & Insights
- **Reassignment history** visible in `TaskDetailPage` update history (TaskUpdate entries with `comment: "Reassigned from [old] to [new]"`).

### Cross-Module Connections
- **Calendar:** If ad-hoc task had a calendar event, update event → notify new assignee via calendar.
- **Shangazi AI:** "Ask Shangazi about workload balance" → AI analysis of team task distribution.

---

## 6. WORK BOARD (MANAGER)

**Entry:** Business Profile → "Board" / "Ubao" tab (alongside Team, Payroll)
**Stage/Context:** Manager needs a team-wide view of all tasks across all employees.

### User Journey
1. Manager taps "Board" tab → `WorkBoardPage` loads.
2. Top: search bar (searches task title and employee name).
3. Filter row:
   - **Employee** dropdown: "All Employees" / "Wafanyakazi Wote" + individual employee names.
   - **Status** chips: All · Pending / Inasubiri · In Progress / Inaendelea · Done / Imekamilika.
   - **Type** toggle: All · Standing / Kawaida · Ad-hoc / Maalum.
4. Filtered list of all `WorkTask` records. Each row shows:
   - Employee avatar + name (left).
   - Task title (bold).
   - Status dot (grey=pending, amber=in progress, green=done).
   - Progress % (right of title).
   - Due date (ad-hoc) or recurrence label (standing) — grey small text below title.
5. Manager taps a row → `TaskDetailPage`.
6. FAB (bottom right): "Assign Task" / "Gawanya Kazi" → `AddWorkTaskSheet` with employee dropdown active.
7. **Empty state (no tasks at all):** "No tasks assigned yet. Tap + to assign the first task." / "Hakuna kazi bado. Gonga + kugawanya kazi ya kwanza."
8. **Empty state (filtered):** "No tasks match your filters." / "Hakuna kazi zinazofanana na vichujio vyako."

### CRUD Operations
- **Create:** FAB → `AddWorkTaskSheet`.
- **Read:** Filterable task list.
- **Edit:** NOT directly on board — tap row → `TaskDetailPage` → Reassign or Delete only.
- **Delete:** Via `TaskDetailPage`.

### Notifications & Reminders
- 📊 **Daily board summary (morning, manager only):** "📊 Today's team: [N] pending tasks, [N] in progress, [N] due today."
- ⚠️ **Overdue digest:** If 3+ tasks are overdue: "⚠️ You have [N] overdue team tasks. Open the Board to review."
- 📊 **Weekly summary (Monday morning):** "📊 Last week: [N] tasks completed, [N] still pending. Team completion rate: [X]%."

### Reports & Insights
- **Board summary bar:** Always-visible count strip at top: Pending: [N] · In Progress: [N] · Done: [N] · Overdue: [N] (red if > 0).
- **Employee workload comparison:** Sort by employee → see task count per person → quickly identify who is overloaded.
- **Overdue list:** Filter by status + sort by due date → see oldest overdue first.

### Cross-Module Connections
- **Budget:** Tasks with a budget field show total committed vs spent across the board.
- **Calendar:** "View team calendar" button → Calendar with all task due dates shown as events.
- **Shangazi AI:** "Ask Shangazi" from board → AI analyzes task distribution and recommends reassignments or deadline adjustments.

---

## 7. TASK DETAIL — MANAGER VIEW

**Entry:** `WorkBoardPage` → tap task row → `TaskDetailPage`
**Entry (alt):** `EmployeeTasksPage` → tap `WorkTaskCard` → `TaskDetailPage`
**Stage/Context:** Manager reviews full task history and progress updates from employee.

### User Journey
1. `TaskDetailPage` loads with:
   - **Header:** Task title (large) · Type badge (Standing outlined / Ad-hoc filled) · Assignee chip (employee name) · Due date or recurrence label.
   - **Progress ring** (centre, large): current progress % as a circular arc.
   - **Status badge** below ring: "Pending" / "In Progress" / "Done" with coloured background.
   - **Reassign button:** Outlined button below status badge.
   - **Update History section:** Chronological list of `TaskUpdate` entries (oldest at bottom, latest at top).
     - Each entry: status badge · progress % · comment text · timestamp · "by [name]" (employee or manager).
2. Manager can **Reassign**: tap "Reassign" / "Gawanya Upya" → dropdown dialog → PUT reassign.
3. Manager can **Delete** task: trash icon in AppBar → confirmation dialog → DELETE /business/tasks/{id} → pops to previous screen.
4. No direct progress update by manager — only employees update progress.
5. **Empty update history:** "No updates yet. Employee hasn't logged progress." / "Hakuna masasisho bado."

### CRUD Operations
- **Create:** N/A (task already exists).
- **Read:** Full detail view including all `TaskUpdate` history.
- **Edit (Reassign):** PUT /business/tasks/{id}/reassign.
- **Delete:** DELETE /business/tasks/{id} with confirmation.

### Notifications & Reminders
- 🔔 **Progress update notification (to manager):** When employee logs an update: "📝 [Employee name] updated '[task title]': [progress]% — [comment snippet]."
- ⚠️ **No progress alert:** If ad-hoc task is more than 50% past its duration with progress < 25%: "⚠️ '[Task title]' is behind schedule for [employee name]. Check in."

### Reports & Insights
- **Timeline view** of update history showing progress over time — how quickly employee moved from 0% to 100%.
- **Average time-to-complete** for ad-hoc tasks across all employees: shown on `WorkBoardPage` summary.

### Cross-Module Connections
- **Shangazi AI:** "Ask Shangazi about this employee's performance" with task history context → coaching suggestions.
- **Calendar:** Completed task with due date → offer "Log actual completion date vs due date" for deadline tracking.

---

## 8. MY JOB OVERVIEW (EMPLOYEE)

**Entry:** Profile → Commerce Section → "My Job" / "Kazi Yangu" tab → `MyJobPage`
**Stage/Context:** Employee checks their role, tasks, and KPIs in one scrollable home screen.

### User Journey
1. Employee taps "My Job" tab in their own profile's Commerce section.
2. `MyJobPage` loads — scrollable page with three cards:
   - **My Role** card:
     - Role summary (2 lines, truncated with ellipsis).
     - Position + department chips (if set).
     - "Reporting to: [owner name]" text.
     - Tap → `MyJobDescriptionPage`.
   - **Today's Tasks** card:
     - Pending task count (large number).
     - Progress ring: % of today's tasks that are Done.
     - "X of Y tasks done today" / "Kazi X kati ya Y zimekamilika leo".
     - Tap → `MyTasksPage`.
   - **My KPIs** card:
     - KPI mini list (max 3 shown): name · mini horizontal progress bar (actual/target) · period label.
     - "View all" link if more than 3.
     - Tap → `MyKpisPage`.
3. **Empty state (no job description assigned by manager):** Full-page empty state illustration + "Your manager hasn't set up your job profile yet." / "Meneja wako hajaweka wasifu wako wa kazi bado."
4. **Pull-to-refresh:** Reloads all three sections.

### CRUD Operations
- **Create:** N/A — employee is read-only in this module.
- **Read:** GET /my/job-description, GET /my/tasks?date=today, GET /my/kpis.
- **Edit:** NOT AVAILABLE — employee cannot edit job description or KPIs.
- **Delete:** NOT AVAILABLE.

### Notifications & Reminders
- 🔔 **Morning briefing (daily, 7am):** "☀️ Good morning! You have [N] tasks today. Standing: [N], Due today: [N]."
- 📊 **Evening summary (daily, 6pm):** "📊 Your day: [X] of [Y] tasks done. [Z] still pending."
- 💡 **KPI period reminder:** At start of each review period: "📊 New [period] started. Your [KPI name] target is [value] [unit]. Let's go!"

### Reports & Insights
- **Daily task completion ring** on Today's Tasks card — visual at-a-glance.
- **KPI progress bars** on My KPIs card — last actual vs target for each KPI.

### Cross-Module Connections
- **Shangazi AI:** "Ask Shangazi" floating button on `MyJobPage` → employee asks career questions with their role context: "How can I improve my [KPI name]?" or "What skills should I develop for my role?"
- **Calendar:** Tasks with due dates shown as events in personal calendar.
- **Wallet:** If a task involves expense, link to Wallet for payment.

---

## 9. MY JOB DESCRIPTION — EMPLOYEE VIEW

**Entry:** `MyJobPage` → "My Role" card → `MyJobDescriptionPage`
**Stage/Context:** Employee reads their assigned role summary, responsibilities, and reporting line.

### User Journey
1. Employee taps "My Role" card → `MyJobDescriptionPage` pushes.
2. Page shows read-only content:
   - **Role Summary** paragraph (full text, not truncated).
   - **Responsibilities** bulleted numbered list.
   - **Reporting To** chip: owner name.
   - **Last Updated** footer: "Last updated [date]" / "Imesasishwa [tarehe]".
3. No edit controls anywhere on this page — explicitly manager-only.
4. **Empty state:** "Your job description hasn't been set yet." / "Maelezo yako ya kazi hayajawekwa bado."
5. Back button returns to `MyJobPage`.

### CRUD Operations
- **Create:** NOT AVAILABLE (employee).
- **Read:** GET /my/job-description.
- **Edit:** NOT AVAILABLE (employee).
- **Delete:** NOT AVAILABLE (employee).

### Notifications & Reminders
- 🔔 **New description notification:** When manager creates description: "📋 Your job description has been set. Check My Job to see your role and responsibilities."
- 🔔 **Updated description notification:** When manager edits: "📋 Your job description has been updated. Review the changes in My Job."

### Reports & Insights
- **Description age indicator:** "Last updated X days ago" — prompts employee to check if still accurate and request an update from manager.

### Cross-Module Connections
- **Shangazi AI:** "Ask Shangazi about career development" with role + responsibilities context → career advice tailored to their position.

---

## 10. MY TASKS — DAILY VIEW (EMPLOYEE)

**Entry:** `MyJobPage` → "Today's Tasks" card → `MyTasksPage`
**Stage/Context:** Employee reviews their task list for a selected day and logs progress.

### User Journey
1. Employee taps "Today's Tasks" → `MyTasksPage` pushes.
2. **Horizontal date strip** at top: scrollable day selector defaulting to today.
   - Each day chip shows: day label (Mon, Tue, …) + date number + small dot if tasks exist.
   - Tapping a chip loads tasks for that day.
3. Below date strip: two sections for the selected day:
   - **Standing Duties** / "Majukumu ya Kawaida": recurring tasks active on that day of week.
   - **Assigned Tasks** / "Kazi Zilizopewa": ad-hoc tasks with due date matching selected day.
4. Each task row:
   - Task title (bold).
   - Status dot (grey/amber/green).
   - Linear progress bar (0–100%).
   - Last comment snippet in grey italic (1 line).
5. Employee taps a task row → `UpdateTaskSheet` slides up.
6. **Empty state for both sections:** "No tasks for this day." / "Hakuna kazi siku hii."
7. **Past day view:** Tasks shown read-only; "Update" button disabled with tooltip "Updates not allowed for past days" / "Masasisho hayaruhusiwi kwa siku zilizopita."

### CRUD Operations
- **Create:** NOT AVAILABLE (employee cannot create tasks).
- **Read:** GET /my/tasks?date={YYYY-MM-DD}.
- **Edit:** Employee taps task → `UpdateTaskSheet` → POST /business/tasks/{id}/updates.
- **Delete:** NOT AVAILABLE (employee cannot delete tasks).

### Notifications & Reminders
- 🔔 **Daily morning reminder (7am):** "☀️ You have [N] standing duties and [N] ad-hoc tasks today. Start your day!"
- ⚠️ **Incomplete at day end (5pm):** "⏰ You still have [N] tasks pending today. Update your progress before end of day."
- 🔔 **Standing task nudge (midday, if not updated):** "🔁 Don't forget to update '[standing task name]' today."
- 🎉 **All tasks done celebration:** When last pending task is marked Done: "🎉 All done for today! Great work, [name]."

### Reports & Insights
- **Day completion ring** at top of page (below date strip): % done for selected day.
- **Week view summary:** On date strip, show a small completion indicator (e.g. green dot) for days where all tasks were completed.
- **Streak counter:** "You've completed all tasks for X days in a row!" shown as a motivational banner.

### Cross-Module Connections
- **Calendar:** Tapping a task's due date chip on the date strip → opens Calendar day view for that date.
- **Budget:** If a task row has a spend field, link "Log expense" → Budget expenditure entry.
- **Shangazi AI:** "Ask Shangazi" on `MyTasksPage` → employee asks for task productivity tips with their current task load as context.

---

## 11. TASK UPDATE (EMPLOYEE)

**Entry:** `MyTasksPage` → tap task row → `UpdateTaskSheet`
**Stage/Context:** Employee logs their progress on a task.

### User Journey
1. Employee taps a task row → bottom sheet slides up: "Update Task" / "Sasisha Kazi".
2. Task title shown as sheet title (non-editable).
3. Form fields:
   - **Status** (segmented control): "Not Started" / "Haijaanza" · "In Progress" / "Inaendelea" · "Done" / "Imekamilika".
   - **Progress** (slider, 0–100%): large slider with percentage label. Auto-jumps to 100% when "Done" selected; auto-sets to at least 1% when "In Progress" selected.
   - **Comment** (multiline TextField): hint "What's the update?" / "Kuna nini kipya?". Optional but encouraged.
4. Employee taps "Save" / "Hifadhi" → `POST /business/tasks/{id}/updates` → sheet closes → optimistic update: task row immediately reflects new status dot + progress bar + comment snippet.
5. **API failure:** Sheet stays open, red snackbar "Failed to save update. Try again." / "Imeshindwa kuhifadhi. Jaribu tena." Optimistic update is rolled back.
6. **Validation:** Status must be selected (defaults to current status so always valid). Comment is optional.
7. Multiple updates per day are allowed — each is a new `TaskUpdate` entry in history.

### CRUD Operations
- **Create:** POST /business/tasks/{id}/updates (each save creates a new entry).
- **Read:** Update history visible on manager's `TaskDetailPage`. Employee sees last comment on task row in `MyTasksPage`.
- **Edit:** NOT AVAILABLE — updates are immutable history entries.
- **Delete:** NOT AVAILABLE (employee).

### Notifications & Reminders
- 🔔 **Manager notification:** Push to manager on update: "📝 [Employee name] updated '[task title]': [progress]% complete. Comment: [snippet]."
- 🎉 **Done celebration:** When status set to Done: confetti animation on sheet close + "🎉 Task complete!" toast.
- 💡 **Comment prompt:** If employee saves without comment: snackbar with "Add a comment next time to keep your manager informed." (non-blocking).

### Reports & Insights
- **Update frequency:** Manager can see how often employee updates tasks — a signal of engagement.
- **Progress velocity:** `TaskDetailPage` shows time from 0% → 100% for completed tasks.

### Cross-Module Connections
- **Shangazi AI:** After marking Done, offer: "Ask Shangazi to reflect on what went well with this task" → AI helps employee build a progress log.

---

## 12. MY KPIS — EMPLOYEE VIEW

**Entry:** `MyJobPage` → "My KPIs" card → `MyKpisPage`
**Stage/Context:** Employee tracks their KPI performance over time in a read-only view.

### User Journey
1. Employee taps "My KPIs" card → `MyKpisPage` pushes.
2. List of KPI cards, each showing:
   - KPI name (bold).
   - Target + unit chip: "Target: 95 %" or "Target: TZS 500,000".
   - Review period chip: "Monthly" / "Quarterly" / "Annual".
   - Line chart of last 6 `KpiEntry` actual values (same chart widget as manager `KpiDetailPage`, read-only).
   - "Last updated: [period label]" footer.
   - Δ from last period: "+5%" in green or "−TZS 30,000" in red.
3. Employee **cannot log entries** — "Log Actual" FAB is NOT present. A subtle note: "Your manager updates KPI values." / "Meneja wako anasasisha thamani za KPI."
4. **Empty state:** "No KPI targets set yet. Your manager will add them." / "Hakuna malengo ya KPI bado. Meneja wako ataongeza."
5. Tap a KPI card → expanded view (inline accordion, same card expands) showing full entry history table: period · actual · Δ vs target · note.

### CRUD Operations
- **Create:** NOT AVAILABLE (employee).
- **Read:** GET /my/kpis + GET /my/kpis/{id}/entries per KPI.
- **Edit:** NOT AVAILABLE (employee).
- **Delete:** NOT AVAILABLE (employee).

### Notifications & Reminders
- 🎉 **Target met notification:** Push to employee when manager logs a met entry: "🎉 You hit your [KPI name] target for [period]! [actual] / [target] [unit]. Keep it up!"
- ⚠️ **Below target notification:** When manager logs below-target entry: "📊 [KPI name] for [period]: [actual] vs target [target]. See My KPIs for details."
- 💡 **Review period start prompt:** "📊 New [period] started. Work towards your [KPI name] target of [target] [unit]."

### Reports & Insights
- **Personal achievement rate:** "You've hit your KPI targets [X] of [Y] periods (Z%)." — shown as a banner at top of `MyKpisPage`.
- **Best period:** "Your best period was [period] at [value]."
- **Trend indicator:** Arrow icon next to KPI name — ↑ improving, → stable, ↓ declining (based on last 3 entries).

### Cross-Module Connections
- **Shangazi AI:** "Ask Shangazi how to improve my [KPI name]" → AI gives role-specific productivity advice based on KPI type (%, TZS, count, hrs).
- **Budget (TZS KPIs):** If KPI unit is TZS (e.g. sales revenue), offer "View in Wallet" → Wallet transaction history filtered by date + amount.

---

## Notification Channel Summary

| Trigger | Recipient | Type | Timing | Channel |
|---------|-----------|------|---------|---------|
| Job description created | Employee | 🔔 Reminder | Immediate | Push |
| Job description updated | Employee | 🔔 Reminder | Immediate | Push |
| No job description 7 days after hire | Manager | 💡 Prompt | +7 days | Push |
| Job description not reviewed 12 months | Manager | 💡 Prompt | Annual | Push |
| KPI review period starts | Manager | 🔔 Reminder | Period start | Push |
| KPI entry not logged at period end | Manager | ⚠️ Alert | Period end | Push |
| KPI target met | Manager + Employee | 🎉 Celebration | On log | Push |
| KPI target missed | Manager | ⚠️ Alert | On log | Push |
| KPI met 3 periods in a row | Manager | 🎉 Celebration | On 3rd log | Push |
| KPI declining 3 periods in a row | Manager | ⚠️ Alert | On 3rd log | Push |
| KPI review period start (employee) | Employee | 💡 Prompt | Period start | Push |
| Task assigned | Employee | 🔔 Reminder | Immediate | Push |
| Standing task daily nudge | Employee | 🔔 Reminder | 7am daily | Local |
| Ad-hoc task due tomorrow | Employee | 🔔 Reminder | -1 day | Push |
| Ad-hoc task overdue | Manager | ⚠️ Alert | +1 day past due | Push |
| Standing task not updated 3 days | Manager | ⚠️ Alert | +3 days | Push |
| Task completed | Manager | 🎉 Celebration | Immediate | Push |
| Task reassigned (new assignee) | Employee (new) | 🔔 Reminder | Immediate | Push |
| Task reassigned (old assignee) | Employee (old) | 🔔 Reminder | Immediate | Push |
| Task progress update | Manager | 🔔 Reminder | Immediate | Push |
| Task behind schedule (50% time, <25% progress) | Manager | ⚠️ Alert | Calculated | Push |
| Board daily summary | Manager | 📊 Summary | 8am daily | Push |
| Board overdue digest (3+ overdue) | Manager | ⚠️ Alert | Daily check | Push |
| Board weekly summary | Manager | 📊 Summary | Monday 8am | Push |
| My Job morning briefing | Employee | 🔔 Reminder | 7am daily | Local |
| My Job evening summary | Employee | 📊 Summary | 6pm daily | Local |
| All tasks done today | Employee | 🎉 Celebration | On last Done | Local |
| Tasks incomplete at 5pm | Employee | ⚠️ Alert | 5pm daily | Local |
| Standing task midday nudge | Employee | 🔔 Reminder | 12pm | Local |
| Task completion streak (3+ days) | Employee | 🎉 Celebration | On streak | In-app |
| Task update saved (Done) | Employee | 🎉 Celebration | Immediate | Local |

---

## Cross-Module Integration Map

| This Module | Other Module | Data Flow | Direction | Trigger |
|-------------|--------------|-----------|-----------|---------|
| Job Description | Calendar | "3-month review" event | → Calendar | First job description save |
| Job Description | Shangazi AI | Role + responsibilities context | → AI | "Ask Shangazi" tap |
| KPI (TZS unit) | Budget | Revenue/sales KPI values | → Budget | Manager views KPI detail |
| KPI | Calendar | Review period due date event | → Calendar | Period reminder fires |
| KPI | Shangazi AI | KPI name + trend data | → AI | "Ask Shangazi" tap |
| Task (ad-hoc) | Calendar | Due date event | → Calendar | Task creation |
| Task | Budget | Optional spend field + log expense | ↔ Budget | Task creation + completion |
| Task | Shangazi AI | Team workload context | → AI | "Ask Shangazi" on board |
| My Tasks | Calendar | Task due dates as events | → Calendar | Employee views date strip |
| My Tasks | Budget | Task expense log | → Budget | Employee marks task done |
| My Tasks | Shangazi AI | Current task load context | → AI | "Ask Shangazi" tap |
| My KPIs (TZS) | Wallet | Sales/revenue transaction history | → Wallet | Employee views KPI card |
| My KPIs | Shangazi AI | KPI type + trend context | → AI | "Ask Shangazi" tap |
| Task Update (Done) | Shangazi AI | Task title + completion context | → AI | "Ask Shangazi" after Done |
