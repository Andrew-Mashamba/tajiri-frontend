# Work Management & My Job — Design Spec

**Date:** 2026-04-20
**Modules:** `lib/team/` (manager side) + `lib/myjob/` (employee side)
**Status:** Approved for implementation

---

## Overview

Two related subsystems extending the existing Team module:

1. **Work Management (manager side)** — job descriptions, KPI tracking, daily task assignment, and a team-wide work board. Lives in `lib/team/`.
2. **My Job (employee side)** — an employee's personal view of their role, tasks, and KPI targets. New module at `lib/myjob/`, accessed via Profile → Commerce → "My Job" tab.

---

## Architecture

### Option chosen: A — Extend `lib/team/` + new `lib/myjob/`

Manager-facing features (job descriptions, KPIs, daily/standing tasks, board) extend `lib/team/`. Employee-facing features are a separate module with a thin read-heavy service layer and a single write endpoint (task updates). This mirrors the existing TAJIRI pattern of business-owner modules vs user-facing modules.

### Hierarchy

Flat org structure only — all employees report to the business owner. No tree depth, no middle management. "Reporting To" is always the owner's name.

---

## Section 1: Data Models

### `lib/team/models/work_models.dart` (new)

All models use `_parseInt`, `_parseDouble`, `_parseDate` helpers (same pattern as `team_models.dart`).

#### `JobDescription`

```dart
class JobDescription {
  final int? id;
  final int employeeId;
  final int businessId;
  final String roleSummary;
  final List<String> responsibilities; // ordered bullet list
  final String reportingTo;            // owner name — always flat
  final DateTime? updatedAt;
}
```

Factory: `JobDescription.fromJson(Map<String, dynamic> json)`

Backend fields: `id`, `employee_id`, `business_id`, `role_summary`, `responsibilities` (JSON array of strings), `reporting_to`, `updated_at`

#### `Kpi`

```dart
class Kpi {
  final int? id;
  final int employeeId;
  final int businessId;
  final String name;
  final double targetValue;
  final String unit;          // "%" | "TZS" | "count" | "hrs" | custom
  final String reviewPeriod;  // "monthly" | "quarterly" | "annual"
}
```

#### `KpiEntry`

```dart
class KpiEntry {
  final int? id;
  final int kpiId;
  final double actualValue;
  final String periodLabel;  // e.g. "April 2026", "Q1 2026"
  final DateTime recordedAt;
  final String? note;
}
```

### `lib/team/models/task_models.dart` (new)

#### `WorkTask`

```dart
class WorkTask {
  final int? id;
  final int employeeId;
  final int businessId;
  final String title;
  final String? description;
  final String taskType;          // "standing" | "adhoc"
  final String? recurrence;       // "daily" | "weekly" | "weekdays" | "custom"
  final List<int> recurrenceDays; // 1=Mon…7=Sun; empty for non-custom
  final DateTime? dueDate;        // required for adhoc; null for standing
  final String status;            // "pending" | "in_progress" | "done"
  final int progress;             // 0–100
  final DateTime assignedDate;
  final String? assigneeName;     // denormalized for display
}
```

Validation rules:
- `taskType == 'standing'` → `recurrence` required, `dueDate` null
- `taskType == 'adhoc'` → `dueDate` required, `recurrence` null

#### `TaskUpdate`

```dart
class TaskUpdate {
  final int? id;
  final int taskId;
  final String status;
  final int progress;      // 0–100
  final String? comment;
  final DateTime createdAt;
  final int createdBy;     // userId
}
```

---

## Section 2: Manager Side — Job Description & KPIs

### Entry point

`EmployeeDetailPage` gets a **"Work Profile"** card below the Compensation card. Shows role summary (1 line) + KPI count chip + "View / Edit" button → pushes `JobDescriptionPage`.

### `lib/team/pages/job_description_page.dart` (new)

AppBar: employee name + pencil edit action.

Four card sections:

| Section | View | Edit |
|---|---|---|
| Role Summary | Paragraph text | Full-screen text field |
| Responsibilities | Numbered bullet list | Reorderable list, add/delete per item |
| Reporting To | Non-editable chip (owner name) | — |
| KPIs | List of `KpiCard` + "Add KPI" button | Inline add sheet |

Empty state: "No job description set. Tap edit to add one."

Save triggers `PUT /business/employees/{id}/job-description`.

### `KpiCard` widget

Shows: name · target (`95 %` / `TZS 500,000`) · review period · mini sparkline of last 6 `KpiEntry` values. Tap → `KpiDetailPage`.

### `lib/team/pages/kpi_detail_page.dart` (new)

- Header: KPI name + target + unit + period chip
- Line chart: x = period labels, y = actual values, horizontal dashed line at target value
- "Log Actual" FAB → bottom sheet: period label (TextField), actual value (number field), optional note
- History list: each `KpiEntry` as a row — period · actual value · delta vs target (green if met, red if missed) · note
- Long-press entry → delete confirmation

### `lib/team/services/work_service.dart` (new) — Job Description & KPI methods

```
getJobDescription(token, employeeId)     GET  /business/employees/{id}/job-description
saveJobDescription(token, id, body)      PUT  /business/employees/{id}/job-description
getKpis(token, employeeId)               GET  /business/employees/{id}/kpis
createKpi(token, body)                   POST /business/kpis
updateKpi(token, kpiId, body)            PUT  /business/kpis/{id}
deleteKpi(token, kpiId)                  DELETE /business/kpis/{id}
getKpiEntries(token, kpiId)              GET  /business/kpis/{id}/entries
logKpiEntry(token, kpiId, body)          POST /business/kpis/{id}/entries
deleteKpiEntry(token, entryId)           DELETE /business/kpi-entries/{id}
```

All return `WorkResult<T>` / `WorkListResult<T>` wrappers (same pattern as `TeamResult`).

---

## Section 3: Manager Side — Daily Task Assignment & Team Board

### Entry point 1 — `EmployeeDetailPage` Tasks card

Below the Work Profile card. Shows:
- Status count chips: `Pending (N)` · `In Progress (N)` · `Done (N)`
- Last 3 active tasks as compact rows: title + status dot + due date or "Standing" label
- "See All / Assign" → pushes `EmployeeTasksPage`

### `lib/team/pages/employee_tasks_page.dart` (new)

- AppBar: employee name + "Assign Task" icon action
- `DefaultTabController` — 3 tabs: **Pending · In Progress · Done**
- Each tab: list of `WorkTaskCard` widgets

**`WorkTaskCard`:**
- Title
- Type badge: "Standing" (outlined) or "Ad-hoc" (filled)
- Recurrence label (e.g. "Every weekday") or due date
- Linear progress bar (0–100%)
- Last comment snippet (1 line, grey)
- Long-press → reassign dialog (dropdown of active employees in this business)
- Tap → `TaskDetailPage`

### `lib/team/widgets/add_work_task_sheet.dart` (new)

| Field | UI | Notes |
|---|---|---|
| Title | TextField | Required |
| Description | Multiline TextField | Optional |
| Task Type | Segmented control | Standing / Ad-hoc |
| Recurrence (Standing) | Chips: Daily · Weekly · Weekdays · Custom | Shown only when Standing |
| Custom Days | Mon–Sun toggle row | Shown only when Custom selected |
| Due Date (Ad-hoc) | Date picker | Required for Ad-hoc |
| Assigned To | Pre-filled from context OR employee dropdown | Dropdown enabled on board view |

Validation: standing requires recurrence selection; ad-hoc requires due date.

Save → `POST /business/tasks` → snackbar → reload.

### Entry point 2 — Work Board tab

New **"Board"** tab on Business Profile (alongside Team, Payroll tabs).

### `lib/team/pages/work_board_page.dart` (new)

- Search bar
- Filter row: Employee dropdown · Status chips (All/Pending/In Progress/Done) · Type toggle (All/Standing/Ad-hoc)
- Filtered list of all `WorkTask` records across all employees
- Each row: employee avatar + name · task title · status dot · progress % · due date or recurrence label
- FAB → `AddWorkTaskSheet` (employee dropdown active)
- Tap row → `TaskDetailPage`

### `lib/team/pages/task_detail_page.dart` (new)

- Header: task title · type badge · assignee chip · due date or recurrence label
- Large progress ring (centre) with current %
- **Reassign** button → employee dropdown dialog → `PUT /business/tasks/{id}/reassign`
- **Update History** section: chronological list of `TaskUpdate` entries
  - Each entry: status badge · progress % · comment · timestamp
- Delete task: icon in AppBar → confirmation dialog → `DELETE /business/tasks/{id}`

### `lib/team/services/work_service.dart` — Task methods (added to same file)

```
getEmployeeTasks(token, employeeId)       GET    /business/employees/{id}/tasks
getAllBusinessTasks(token, businessId)    GET    /business/{id}/tasks
createTask(token, body)                  POST   /business/tasks
updateTask(token, taskId, body)          PUT    /business/tasks/{id}
reassignTask(token, taskId, empId)       PUT    /business/tasks/{id}/reassign
deleteTask(token, taskId)                DELETE /business/tasks/{id}
getTaskUpdates(token, taskId)            GET    /business/tasks/{id}/updates
```

---

## Section 4: Employee Side — My Job Module

### Navigation

Profile → Commerce Section → **"My Job"** tab (`/my_job` route).

Visible to employees on their own profile. Business owners who are also employees see it on their personal profile (not the business profile).

### `lib/myjob/pages/my_job_page.dart` — Tab root

Scrollable home screen with three cards:

| Card | Content | On Tap |
|---|---|---|
| My Role | Role summary (2 lines), position + department chips, reporting-to name | `MyJobDescriptionPage` |
| Today's Tasks | Pending count + progress ring (% of today's tasks done) | `MyTasksPage` |
| My KPIs | KPI list with mini progress bars (last actual vs target) | `MyKpisPage` |

Empty state (no job description assigned): "Your manager hasn't set up your job profile yet."

### `lib/myjob/pages/my_job_description_page.dart` (new)

Read-only view of manager-assigned job description:
- Role summary paragraph
- Responsibilities bulleted list
- Reporting to chip

No edit controls — manager-only.

### `lib/myjob/pages/my_tasks_page.dart` (new)

- Horizontal date strip at top — scroll left/right by day, defaults to today
- Two sections per selected day:
  - **Standing Duties** — recurring tasks active on that day of the week
  - **Assigned Tasks** — ad-hoc tasks with due date matching selected day
- Each task row: title · status dot · linear progress bar
- Tap → `UpdateTaskSheet`

### `lib/myjob/widgets/update_task_sheet.dart` (new)

The single employee write surface:

| Field | UI | Notes |
|---|---|---|
| Status | Segmented control | Not Started · In Progress · Done |
| Progress | Slider 0–100% | Auto-sets to 100 when Done selected |
| Comment | Multiline TextField | "What's the update?" hint |

Save → `POST /business/tasks/{id}/updates` → sheet closes → task row updates inline (optimistic update).

### `lib/myjob/pages/my_kpis_page.dart` (new)

Read-only KPI tracker:
- Each KPI as a card: name · target · unit · review period
- Line chart of logged `KpiEntry` values (same chart widget as manager `KpiDetailPage` — read-only)
- "Last updated: [date]" footer
- Empty state: "No KPI targets set yet"

Employees cannot log actual values — manager controls KPI entries.

### `lib/myjob/services/my_job_service.dart` (new)

```
getMyJobDescription(token, userId)   GET  /my/job-description
getMyKpis(token, userId)             GET  /my/kpis
getMyKpiEntries(token, kpiId)        GET  /my/kpis/{id}/entries
getMyTasks(token, userId, date?)     GET  /my/tasks?date={date}
postTaskUpdate(token, taskId, body)  POST /business/tasks/{id}/updates
```

### `lib/myjob/myjob.dart` barrel

```dart
export 'models/myjob_models.dart';
export 'pages/my_job_page.dart' show MyJobPage;
export 'services/my_job_service.dart' show MyJobService;
```

---

## Backend Requirements

Use `./scripts/ask_backend.sh` to request all endpoints.

### Job Description & KPIs

```
GET    /business/employees/{id}/job-description
PUT    /business/employees/{id}/job-description
GET    /business/employees/{id}/kpis
POST   /business/kpis              body: {employee_id, business_id, name, target_value, unit, review_period}
PUT    /business/kpis/{id}
DELETE /business/kpis/{id}
GET    /business/kpis/{id}/entries
POST   /business/kpis/{id}/entries body: {actual_value, period_label, note?}
DELETE /business/kpi-entries/{id}
```

### Tasks

```
GET    /business/employees/{id}/tasks
GET    /business/{id}/tasks         query: ?status=&type=&employee_id=
POST   /business/tasks              body: {employee_id, business_id, title, description?, task_type, recurrence?, recurrence_days?, due_date?, assigned_date}
PUT    /business/tasks/{id}
PUT    /business/tasks/{id}/reassign body: {employee_id}
DELETE /business/tasks/{id}
GET    /business/tasks/{id}/updates
POST   /business/tasks/{id}/updates body: {status, progress, comment?}
```

### Employee (My Job)

```
GET /my/job-description          — returns job description for the authenticated user's employee record
GET /my/kpis                     — returns KPIs for the authenticated user
GET /my/kpis/{id}/entries
GET /my/tasks?date={YYYY-MM-DD}  — returns standing tasks active on that weekday + ad-hoc tasks due that date
```

---

## File Map

### New files

```
lib/team/models/work_models.dart
lib/team/models/task_models.dart
lib/team/services/work_service.dart
lib/team/pages/job_description_page.dart
lib/team/pages/kpi_detail_page.dart
lib/team/pages/employee_tasks_page.dart
lib/team/pages/work_board_page.dart
lib/team/pages/task_detail_page.dart
lib/team/widgets/add_work_task_sheet.dart

lib/myjob/myjob.dart
lib/myjob/models/myjob_models.dart
lib/myjob/services/my_job_service.dart
lib/myjob/pages/my_job_page.dart
lib/myjob/pages/my_job_description_page.dart
lib/myjob/pages/my_tasks_page.dart
lib/myjob/pages/my_kpis_page.dart
lib/myjob/widgets/update_task_sheet.dart
```

### Modified files

```
lib/team/pages/employee_detail_page.dart   — add Work Profile card + Tasks card
lib/team/team.dart                         — export new pages/widgets
lib/screens/profile/profile_screen.dart   — add /my_job tab (employee) + /biz_board tab (manager)
```

---

## Bilingual Labels (key strings)

| EN | SW |
|---|---|
| My Job | Kazi Yangu |
| Job Description | Maelezo ya Kazi |
| Role Summary | Muhtasari wa Nafasi |
| Responsibilities | Majukumu |
| Reporting To | Anaripoti Kwa |
| KPIs | Viashiria vya Utendaji |
| Log Actual | Ingiza Thamani Halisi |
| Standing Task | Kazi ya Kawaida |
| Ad-hoc Task | Kazi Maalum |
| Work Board | Ubao wa Kazi |
| Assign Task | Gawanya Kazi |
| Reassign | Gawanya Upya |
| Progress | Maendeleo |
| Today's Tasks | Kazi za Leo |
| Not Started | Haijaanza |
| In Progress | Inaendelea |
| Done | Imekamilika |
