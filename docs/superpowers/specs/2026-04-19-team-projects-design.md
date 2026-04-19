# Enhanced Team & Projects Module Design

## Overview

Two related subsystems for business management in TAJIRI:

1. **Enhanced Team** — richer employee records (linked to platform users, compensation breakdown, allowances, deduction toggles)
2. **Projects & Tasks** — project tracking per business with tasks assignable to team members

---

## Subsystem 1: Enhanced Team Module

### Goal

Allow a business owner to manage their team by picking existing Tajiri platform users, configuring their compensation (gross salary + optional PAYE/NSSF/NHIF deductions + named allowances), and viewing a per-employee net-pay breakdown.

### Architecture

All code stays in `lib/team/`. No new top-level module. Barrel (`lib/team/team.dart`) already exists and will be updated.

### Data Models (`lib/team/models/team_models.dart`)

**`Allowance`** — a named monetary addition to an employee's pay:
```
name: String      // e.g. "Transport", "Housing", "Airtime"
amount: double
```

**`Employee`** (enhanced from current):
```
id: int
businessId: int
userId: int           // platform user ID — links to Tajiri user account
name: String
phone: String
position: String
department: String    // NEW
contractType: String  // NEW — "permanent" | "contract" | "part_time"
grossSalary: double
applyPAYE: bool       // NEW — auto-compute PAYE if true
applyNSSF: bool       // NEW — auto-compute NSSF if true
applyNHIF: bool       // NEW — auto-compute NHIF if true
allowances: List<Allowance>  // NEW
startDate: DateTime?
bankAccount: String
bankName: String
isActive: bool
```

**`PlatformUser`** — lightweight model for the user-picker:
```
id: int
name: String
username: String
avatarUrl: String?
```

### Services (`lib/team/services/team_service.dart`)

New methods added alongside existing CRUD:

- `TeamService.searchPlatformUsers(token, query)` → `GET /users/search?q={query}` → `List<PlatformUser>`
- `TeamService.getEmployee(token, employeeId)` → `GET /business/employees/{id}` → `Employee`

Existing `addEmployee` / `updateEmployee` bodies will now include the new fields: `userId`, `department`, `contractType`, `applyPAYE`, `applyNSSF`, `applyNHIF`, `allowances`.

### Compensation Computation (client-side, `lib/team/services/compensation_service.dart`)

A pure utility class (no network calls) that computes deductions from gross salary:

```
NSSF (2026 rates):
  Employee contribution: 10% of gross, max TZS 20,000
  Employer contribution: 10% of gross, max TZS 20,000

NHIF (2026 rates, employee contribution only):
  Gross ≤ 100,000      → 0
  100,001 – 200,000    → 5,000
  200,001 – 300,000    → 7,500
  300,001 – 400,000    → 10,000
  400,001 – 500,000    → 12,500
  500,001 – 1,000,000  → 15,000
  > 1,000,000          → 20,000

PAYE:
  Uses existing TanzaniaPAYE.computePAYE() logic in business_models.dart

Net pay = grossSalary + sum(allowances) - PAYE (if on) - NSSF employee (if on) - NHIF (if on)
```

This class is stateless and tested independently.

### Pages

**`employees_page.dart`** (modified):
- "Add Member" button opens `UserSearchSheet` first
- After user picked, opens `CompensationSheet` pre-filled with selected user's name/phone
- List items tap to `EmployeeDetailPage`

**`employee_detail_page.dart`** (NEW):
- AppBar with user name, edit/delete actions
- Avatar + name + username + phone
- Role chip, department chip, contract type chip
- Compensation card:
  - Gross salary row
  - PAYE row (computed, shown only if `applyPAYE`)
  - NSSF row (computed, shown only if `applyNSSF`)
  - NHIF row (computed, shown only if `applyNHIF`)
  - Allowance rows (each named allowance)
  - Divider + **Net Pay** total (bold)
- Active/inactive status badge

### Widgets

**`user_search_sheet.dart`** (NEW):
- Modal bottom sheet
- Search TextField → debounce 400ms → calls `TeamService.searchPlatformUsers`
- Scrollable list of `PlatformUser` tiles (avatar + name + username)
- On tap → closes sheet, passes `PlatformUser` to callback

**`compensation_sheet.dart`** (NEW, handles both add and edit — pass `Employee?` to pre-fill; null means add mode):
- Pre-filled with user info (read-only name row)
- Fields: position, department, contract type (dropdown: Permanent / Contract / Part-time)
- Gross salary text field
- Toggle row: PAYE | NSSF | NHIF (each a labeled Switch)
- Allowances section: existing allowance chips + "Add Allowance" button → mini dialog (name + amount)
- Start date picker, bank account, bank name
- Save button

### Navigation wiring

No new tab needed — existing "Team" tab (`/biz_employees`) in `profile_screen.dart` already shows `EmployeesPage`. Tapping an employee card pushes `EmployeeDetailPage`.

---

## Subsystem 2: Projects Module (`lib/projects/`)

### Goal

Allow a business owner to create projects, manage tasks within them, assign tasks to team members, and track progress by status.

### Architecture

New module `lib/projects/` following the same pattern as `lib/team/` and `lib/crb/`.

### Data Models (`lib/projects/models/project_models.dart`)

**`ProjectStatus`**: `active | completed | on_hold`

**`TaskStatus`**: `todo | in_progress | done`

**`TaskPriority`**: `low | medium | high`

**`Project`**:
```
id: int
businessId: int
title: String
description: String
status: ProjectStatus
startDate: DateTime?
endDate: DateTime?
taskCount: int        // summary count from API
completedCount: int
```

**`Task`**:
```
id: int
projectId: int
title: String
description: String
assigneeId: int?      // Employee.id
assigneeName: String? // denormalized for display
dueDate: DateTime?
priority: TaskPriority
status: TaskStatus
```

### Services (`lib/projects/services/project_service.dart`)

Result wrappers: `ProjectResult<T>` and `ProjectListResult<T>` (same pattern as `TeamResult`).

Methods:
- `getProjects(token, businessId)` → `GET /business/{id}/projects` → `List<Project>`
- `createProject(token, body)` → `POST /business/projects`
- `updateProject(token, projectId, body)` → `PUT /business/projects/{id}`
- `deleteProject(token, projectId)` → `DELETE /business/projects/{id}`
- `getTasks(token, projectId)` → `GET /business/projects/{id}/tasks` → `List<Task>`
- `createTask(token, body)` → `POST /business/tasks`
- `updateTask(token, taskId, body)` → `PUT /business/tasks/{id}`
- `deleteTask(token, taskId)` → `DELETE /business/tasks/{id}`

### Pages

**`projects_page.dart`**:
- List of `ProjectCard` widgets grouped by status
- FAB → `AddProjectSheet`
- Tap project → pushes `ProjectDetailPage`

**`project_detail_page.dart`**:
- AppBar with project title + edit/delete actions
- Project description + date range + status chip
- `DefaultTabController` with 3 tabs: **To-Do | In Progress | Done**
- Each tab shows filtered `TaskCard` list
- FAB → `AddTaskSheet`
- Tap task card → `EditTaskSheet`

### Widgets

**`project_card.dart`**:
- Title, description (1 line ellipsis), status chip
- Progress indicator: `completedCount / taskCount` linear bar
- End date with overdue highlight if past

**`task_card.dart`**:
- Title, assignee name, due date
- Priority dot (low=grey, medium=amber, high=red) — monochromatic except these semantic dots
- Tap opens edit sheet

**`add_project_sheet.dart`**: title, description, start/end date pickers, status dropdown

**`add_task_sheet.dart`** / **`edit_task_sheet.dart`**: title, description, assignee picker (dropdown of business employees), due date, priority dropdown, status dropdown

### Navigation wiring

`profile_screen.dart` — add a "Projects" tab case `/biz_projects` in the business tab list:
```dart
case '/biz_projects':
  page = BizTabWrapper(
    userId: profileUserId,
    builder: (uid, all, first, fId) =>
        fId != null ? ProjectsPage(businessId: fId) : const SizedBox.shrink(),
  );
```

`reminder_navigation.dart` — add `/biz_projects` case.

### Barrel (`lib/projects/projects.dart`)
```dart
export 'models/project_models.dart';
export 'pages/projects_page.dart' show ProjectsPage;
export 'services/project_service.dart' show ProjectService;
```

---

## Backend Requirements

Both subsystems require new Laravel routes. Use `./scripts/ask_backend.sh` to request:

**Team:**
- `GET /users/search?q={query}` — search platform users by name/username (returns id, name, username, avatar)
- `GET /business/employees/{id}` — single employee detail
- Updated `POST/PUT /business/employees` to accept: `userId`, `department`, `contractType`, `applyPAYE`, `applyNSSF`, `applyNHIF`, `allowances` (JSON array of `{name, amount}`)

**Projects:**
- `GET /business/{id}/projects`
- `POST /business/projects`
- `PUT /business/projects/{id}`
- `DELETE /business/projects/{id}`
- `GET /business/projects/{id}/tasks`
- `POST /business/tasks`
- `PUT /business/tasks/{id}`
- `DELETE /business/tasks/{id}`

---

## Testing Strategy

- `CompensationService` — unit tests for PAYE/NSSF/NHIF computations and net-pay totals
- `TeamService` / `ProjectService` — integration tests against UAT backend
- Widget smoke tests for `UserSearchSheet`, `EmployeeDetailPage`, `ProjectDetailPage`

---

## File Map

### Modified
- `lib/team/models/team_models.dart` — add `Allowance`, `PlatformUser`, enhance `Employee`
- `lib/team/services/team_service.dart` — add `searchPlatformUsers`, `getEmployee`
- `lib/team/pages/employees_page.dart` — add user-pick step to add flow
- `lib/team/team.dart` — export new pages/widgets
- `lib/screens/profile/profile_screen.dart` — add `/biz_projects` tab
- `lib/reminders/reminder_navigation.dart` — add `/biz_projects` case

### Created
- `lib/team/services/compensation_service.dart`
- `lib/team/pages/employee_detail_page.dart`
- `lib/team/widgets/user_search_sheet.dart`
- `lib/team/widgets/compensation_sheet.dart`
- `lib/projects/models/project_models.dart`
- `lib/projects/services/project_service.dart`
- `lib/projects/pages/projects_page.dart`
- `lib/projects/pages/project_detail_page.dart`
- `lib/projects/widgets/project_card.dart`
- `lib/projects/widgets/task_card.dart`
- `lib/projects/widgets/add_project_sheet.dart`
- `lib/projects/widgets/add_task_sheet.dart`
- `lib/projects/projects.dart`
