# Reminders Module Design

**Date:** 2026-04-18  
**Location:** `lib/reminders/`  
**Entry point:** Profile → Business category

---

## Overview

A dedicated module that aggregates 24 notification event types from all 23 business modules plus calendar into a single unified view. Users can also create standalone reminders with recurrence, local push notifications, and SQLite + remote persistence.

---

## Architecture

**Approach:** Pull-based aggregator. Each source module exposes an adapter method returning normalized `ReminderItem` objects. The reminders module calls all adapters in parallel, merges, sorts, and displays results. Standalone reminders are stored in SQLite locally and synced to the backend API.

```
lib/reminders/
├── reminders_module.dart
├── models/
│   └── reminder_models.dart
├── services/
│   ├── reminders_service.dart              # CRUD — SQLite + API sync
│   ├── reminders_db.dart                   # SQLite schema & queries
│   ├── reminders_aggregator.dart           # Merges all source adapters
│   └── reminders_notification_service.dart # Local notification scheduling
├── pages/
│   ├── reminders_home_page.dart            # Main list (Today / Upcoming / Done)
│   └── add_reminder_page.dart              # Create / edit standalone reminder
└── widgets/
    └── reminder_card.dart                  # Swipeable reminder row
```

---

## Data Models (`reminder_models.dart`)

### `ReminderItem`

```dart
class ReminderItem {
  final String id;           // "cal_42", "biz_appt_7", "standalone_{uuid}"
  final String title;
  final String? subtitle;    // e.g. salon name, supplier name
  final DateTime dueAt;
  final ReminderCategory category;
  final ReminderRepeat repeat;
  final bool isDone;
  final bool isStandalone;   // true = user-created, editable/deletable
  final String? sourceRoute; // deep-link to originating module (e.g. "/calendar")
}
```

### `ReminderCategory` enum

Values: `calendar`, `appointment`, `quote`, `invoice`, `transaction`, `revenue`, `recurring`, `debt`, `document`, `expense`, `tax`, `credit`, `employee`, `payroll`, `purchaseOrder`, `tender`, `general`

*(17 categories covering all 24 event types)*

Each value exposes:
- `displayName` — Swahili label
- `subtitle` — English label
- `icon` — `IconData`

### `ReminderRepeat` enum

Values: `none`, `daily`, `weekly`, `monthly`, `yearly` — mirrors `EventRepeat` in `calendar_models.dart`.

Each value exposes `displayName` (Swahili) and `subtitle` (English).

### Result wrappers

```dart
class ReminderResult<T> { bool success; T? data; String? message; }
class ReminderListResult<T> { bool success; List<T> items; String? message; }
```

---

## Services

### `RemindersDb`

SQLite table `reminders`:

| Column | Type | Notes |
|--------|------|-------|
| id | TEXT PRIMARY KEY | UUID |
| user_id | INTEGER | |
| title | TEXT | |
| subtitle | TEXT | nullable |
| due_at | TEXT | ISO 8601 |
| category | TEXT | enum name |
| repeat | TEXT | enum name |
| is_done | INTEGER | 0/1 |
| source_route | TEXT | nullable |
| synced_at | TEXT | nullable, last API sync |
| server_id | INTEGER | nullable, backend ID |

Methods: `insert`, `update`, `delete`, `getAll(userId)`, `markDone(id)`.

### `RemindersService`

CRUD for standalone reminders. Offline-first: write SQLite immediately, sync API in background.

- `create(item, token)` → SQLite insert → POST `/api/reminders` → schedule notification
- `update(item, token)` → SQLite update → PATCH `/api/reminders/{id}` → reschedule notification
- `delete(id, token)` → SQLite delete → DELETE `/api/reminders/{id}` → cancel notification
- `getAll(userId, token)` → GET `/api/reminders` → reconcile with SQLite (API wins on conflict: if `server_id` matches but fields differ, overwrite local row) → return list
- `markDone(id, token)` → SQLite update → PATCH `/api/reminders/{id}` → cancel notification

### `RemindersAggregator`

Calls all source adapters in parallel via `Future.wait`, normalizes to `ReminderItem`, merges with standalone reminders, sorts by `dueAt`.

**Sources (24 event types across 16 adapters):**

| Adapter method | Category | Events produced |
|---|---|---|
| `CalendarService.getUpcomingWithReminders` | `calendar` | Events with reminder set |
| `BusinessService.getUpcomingAppointments` | `appointment` | Pending/confirmed appointments |
| `BusinessService.getExpiringDocuments` | `document` | License, WCF, contract, insurance expiry |
| `BusinessService.getUpcomingQuotes` | `quote` | `valid_until` expiry; accepted/rejected status |
| `BusinessService.getUpcomingInvoices` | `invoice` | Due date approaching; overdue; paid |
| `BusinessService.getFailedTransactions` | `transaction` | Failed transactions |
| `BusinessService.getRevenueSummaryDigest` | `revenue` | Weekly/monthly digest |
| `BusinessService.getUpcomingRecurring` | `recurring` | Next recurring invoice generation |
| `BusinessService.getUpcomingDebts` | `debt` | Due date approaching; overdue |
| `BusinessService.getUpcomingExpenses` | `expense` | Recurring expense due |
| `BusinessService.getTaxDeadlines` | `tax` | TRA quarterly/annual filing deadlines |
| `BusinessService.getCrbPastDueEntries` | `credit` | New past-due CRB entries |
| `BusinessService.getExpiringEmployeeContracts` | `employee` | Contract end approaching |
| `BusinessService.getUpcomingPayroll` | `payroll` | Period due; approved-but-unpaid |
| `BusinessService.getUpcomingPurchaseOrders` | `purchaseOrder` | Delivery date; status changes |
| `TenderService.getUpcomingTenderDeadlines` | `tender` | Closing/application deadlines; won/lost |
| `RemindersService.getAll` | *(as stored)* | Standalone user-created reminders |

**Extensibility:** New modules plug in by adding one adapter call to `getAll()`.

### `RemindersNotificationService`

Wraps `flutter_local_notifications` (already in deps).

- `schedule(item)` → `zonedSchedule` with payload `{type: "reminder", id: item.id}`
- `cancel(id)` → cancel by notification ID (derived from `id.hashCode`)
- `scheduleRecurring(item)` → `RepeatInterval` for daily/weekly; manual re-schedule on completion for monthly/yearly
- `scheduleAll(items)` → called on aggregator refresh; cancels removed items, schedules new ones
- Notification channel: ID `reminders`, name `Vikumbusho`, description `Vikumbusho vya biashara`

**Notification timing rules by category:**

| Category | Lead time(s) |
|---|---|
| `document` | 30 days, 7 days, 1 day before expiry |
| `invoice` | 7 days, 3 days, 1 day before due; day-of if overdue |
| `quote` | 3 days, 1 day before `valid_until` |
| `debt` | 7 days, 3 days, 1 day before due date |
| `tax` | 30 days, 7 days, 1 day before deadline |
| `tender` | 7 days, 3 days, 1 day before closing/application deadline |
| `employee` | 30 days, 7 days before contract end |
| `payroll` | Day of pay period; day after approval if still unpaid |
| `purchaseOrder` | 1 day before expected delivery |
| `recurring` | 1 day before next generation date |
| `expense` | 1 day before recurring expense due |
| `appointment` | 24 hours before, 1 hour before |
| `transaction` | Immediate (failed transactions only) |
| `credit` | Immediate (new past-due CRB entry detected) |
| `revenue` | Scheduled weekly/monthly digest |
| `calendar` | Respects `EventReminder` value set on the event |
| `general` (standalone) | At exact `dueAt` time set by user |

---

## Notification Events Reference

All 24 notification event types the aggregator surfaces:

| # | Source Module | Event | Category | Timing |
|---|---|---|---|---|
| 1 | biz_profile / biz_docs | Business license expiry | `document` | 30/7/1 day before |
| 2 | biz_docs | Document expiry (WCF, contract, insurance, director ID) | `document` | 30/7/1 day before |
| 3 | biz_quotes | Quote `valid_until` expiring | `quote` | 3/1 day before |
| 4 | biz_quotes | Quote accepted or rejected | `quote` | Immediate |
| 5 | biz_invoices | Invoice due date approaching | `invoice` | 7/3/1 day before |
| 6 | biz_invoices | Invoice overdue | `invoice` | Day-of + daily until paid |
| 7 | biz_invoices | Invoice paid (confirmation) | `invoice` | Immediate |
| 8 | biz_transactions | Failed transaction | `transaction` | Immediate |
| 9 | biz_revenue / biz_income | Weekly/monthly revenue digest | `revenue` | Scheduled (Mon 8am / 1st of month) |
| 10 | biz_recurring | Recurring invoice generation due | `recurring` | 1 day before |
| 11 | biz_debts | Debt due date approaching | `debt` | 7/3/1 day before |
| 12 | biz_debts | Debt overdue | `debt` | Day-of |
| 13 | biz_credit | New past-due CRB entry | `credit` | Immediate |
| 14 | biz_expenses | Recurring expense due | `expense` | 1 day before |
| 15 | biz_tax | TRA tax filing deadline | `tax` | 30/7/1 day before |
| 16 | biz_employees | Employee contract end approaching | `employee` | 30/7 days before |
| 17 | biz_payroll | Payroll period due (status: draft) | `payroll` | Day of pay period |
| 18 | biz_payroll | Approved payroll not yet paid | `payroll` | Day after approval |
| 19 | biz_po | PO expected delivery approaching | `purchaseOrder` | 1 day before |
| 20 | biz_po | PO delivered or cancelled | `purchaseOrder` | Immediate |
| 21 | biz_tenders | Tender closing date approaching | `tender` | 7/3/1 day before |
| 22 | biz_tenders | Application deadline approaching | `tender` | 7/3/1 day before |
| 23 | biz_tenders | Application won or lost | `tender` | Immediate |
| 24 | biz_appointments | Appointment approaching | `appointment` | 24hr + 1hr before |

---

## Pages

### `RemindersHomePage`

Three tabs: **Leo** (Today) / **Ijayo** (Upcoming) / **Zilizokamilika** (Done).

- Today tab: reminders due today, sorted by time
- Upcoming tab: future reminders, grouped by date header
- Done tab: completed reminders (standalone and aggregated marked done)
- FAB: opens `AddReminderPage`
- Aggregated items show source badge chip; tap navigates to `sourceRoute`
- Standalone items: tap opens edit form

### `AddReminderPage`

Create / edit standalone reminders. Fields:
- Title (required)
- Note (optional)
- Date + time picker
- Category selector (icon grid)
- Repeat selector
- Notification toggle

### `ReminderCard` widget

Uses `flutter_slidable`:
- Swipe right → mark done / undo
- Swipe left → snooze options (15 min, 1 hr, tomorrow) or delete (standalone only)
- Source badge on aggregated items (e.g. "Kalenda", "Miadi")

---

## UI Conventions

Follows `docs/DESIGN.md`:
- Monochromatic palette: `#1A1A1A` dark, `#FAFAFA` background
- Material 3, no colorful buttons
- `SafeArea` mandatory
- 48dp minimum touch targets
- `maxLines` + `TextOverflow.ellipsis` on all dynamic text
- Bilingual labels throughout (Swahili primary, English subtitle)

---

## Error Handling

- API failures fall back to SQLite data silently — no error shown unless SQLite also fails
- Failed API sync queued for retry on next `getAll()` call (check `synced_at == null`)
- Notification scheduling failures logged but not surfaced to user

---

## Backend Dependency

Requires a `/api/reminders` REST resource on the backend (GET, POST, PATCH `{id}`, DELETE `{id}`). The app reconciles with this API when online; until the backend is available, the module operates offline using SQLite — rows with `synced_at == null` are queued for sync when the endpoint becomes available.

---

## Extensibility

Adding a new source module requires:
1. Add one adapter method to the source module's service
2. Add one `Future` call in `RemindersAggregator.getAll()`
3. Optionally add a new `ReminderCategory` value

No changes to models, pages, or notification service needed.
