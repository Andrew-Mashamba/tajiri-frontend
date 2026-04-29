# TAJIRI Vikumbusho (Reminders) — Backend Verification & Implementation Directive

> **Audience:** Backend coding agent (Laravel / TAJIRI API + Tenders API)  
> **Purpose:** Confirm that **all** APIs required by the Flutter Vikumbusho module are implemented, shaped correctly, and return success under normal conditions. **Ask for a written report back** using §7.  
> **Frontend references:**  
> - Aggregator: `lib/reminders/services/reminders_aggregator.dart`  
> - Standalone sync: `lib/reminders/services/reminders_service.dart`  
> - Business adapters: `lib/business/services/business_service.dart`  
> - Calendar: `lib/calendar/services/calendar_service.dart`  
> - Tenders: `lib/tenders/services/tender_service.dart`  
> - Event kinds: `lib/reminders/models/reminder_event_kind.dart`  
> **Related spec (standalone CRUD):** `docs/modules/reminders_backend_directive.md`

---

## 1. Executive summary

The mobile **Vikumbusho** screen merges **17 parallel data sources** into one list, then schedules **local notifications** on the device. There is **no** server-side “reminder queue” for aggregated business/calendar/tender rows—only **HTTP responses** drive what appears.

Two backend surfaces matter:

| Surface | Role |
|---------|------|
| **A. Standalone reminders API** | Persists user-created reminders (`GET/POST/PATCH/DELETE /api/reminders`). |
| **B. Aggregation feeds** | Read-only JSON from business, calendar, tenders, etc. Each feed must be **consistent** so the client can map rows to `ReminderItem` + optional `event_kind`. |

**Critical (2026 frontend behaviour):** The app loads Vikumbusho using **`getAllStrictWithRetries`**. Every aggregation call runs in **strict** mode: **non-200 HTTP** (or tenders “failure” result) causes the **entire** Vikumbusho load to fail after retries—not a partial list. Backends must return **200** with a valid JSON body for each endpoint in normal operation.

---

## 2. Part A — Standalone reminders API (`/api/reminders`)

**Single source of truth:** `docs/modules/reminders_backend_directive.md` (sections 1–15).

### A.1 Verification checklist (backend agent)

- [ ] `GET /api/reminders?user_id=` — 200, `success: true`, `data` is array, fields match directive §4.
- [ ] `POST /api/reminders` — 201/200, `data.id` numeric (or documented merge strategy with `client_id`).
- [ ] `PATCH /api/reminders/{id}` — resolves `standalone_*` and numeric id; `{ "is_done": 1 }` supported.
- [ ] `DELETE /api/reminders/{id}` — 200/204.
- [ ] Authorization: `user_id` matches Sanctum-resolved **profile** (`user_profiles.id`).

If any box is unchecked, note **route**, **observed status**, and **sample response** in the report (§7).

---

## 3. Part B — Aggregation endpoints (must exist + succeed)

The following table lists **exact URL paths as used by the Flutter client** (relative to `ApiConfig.baseUrl` = `{origin}/api` unless noted). Query params are **required** where shown.

| # | Method | Path (under `/api` unless stated) | Purpose in app |
|---|--------|-------------------------------------|----------------|
| 1 | GET | `calendar/events?user_id=&year=&month=&with_reminders=1` | Calendar events with reminder metadata |
| 2 | GET | `business/appointments/upcoming?user_id=` | Salon/business appointments |
| 3 | GET | `business/documents/expiring?user_id=&days=30` | Document / licence expiry |
| 4 | GET | `business/quotes/upcoming?user_id=` | Quotes (valid-until + terminal status rows) |
| 5 | GET | `business/quotes/status-events?user_id=&days=14` | Optional quote status events |
| 6 | GET | `business/invoices/upcoming?user_id=` | Invoices (upcoming / overdue / paid-in-window) |
| 7 | GET | `business/invoices/paid-notifications?user_id=&days=7` | Paid-notification rows |
| 8 | GET | `transactions?user_id=&status=failed&limit=10` | Failed transactions |
| 9 | GET | `business/revenue/digest?user_id=` | Next revenue digest datetime |
| 10 | GET | `business/recurring/upcoming?user_id=` | Recurring invoice schedule |
| 11 | GET | `business/debts/upcoming?user_id=` | Debts (upcoming vs overdue) |
| 12 | GET | `business/expenses/upcoming?user_id=` | Upcoming expenses |
| 13 | GET | `business/tax/deadlines?user_id=` | Tax deadlines |
| 14 | GET | `debts/crb/past-due?user_id=` | CRB past-due entries |
| 15 | GET | `business/employees/expiring?user_id=&days=30` | Employee contracts |
| 16 | GET | `business/payroll/upcoming?user_id=` | Payroll periods |
| 17 | GET | `business/purchase-orders/upcoming?user_id=` | Purchase orders |
| 18 | GET | `business/purchase-orders/status-events?user_id=&days=14` | PO status events |
| 19 | — | **Tenders API** (separate base URL in app: `https://tenders.zimasystems.com/api`) | Active tenders + `GET` user applications |

### B.1 Expected JSON shape (general)

- Prefer envelope: `{ "success": true, "data": [ ... ] }` or `{ "data": { ... } }` as already used per module.
- **Lists:** `data` should be a JSON **array** where the client iterates rows (or a documented object key the client already parses—match **existing** `BusinessService` code).
- **HTTP status:** **200** for successful read. Empty lists are OK.

### B.2 Optional but valuable: `event_kind` / `reminder_kind`

For any row in `data[]`, the backend **may** include:

- `event_kind` **or** `reminder_kind` (alias)

Allowed string values must match Flutter `ReminderEventKind` in `lib/reminders/models/reminder_event_kind.dart`, e.g.:

`document_expiry`, `quote_valid_until`, `quote_status`, `invoice_upcoming`, `invoice_overdue`, `invoice_paid`, `debt_upcoming`, `debt_overdue`, `recurring_invoice`, `recurring_expense`, `revenue_digest`, `failed_transaction`, `crb_past_due`, `tax_deadline`, `employee_contract`, `payroll_draft`, `payroll_unpaid`, `po_delivery`, `po_status`, `tender_closing`, `tender_application`, `tender_outcome`, `appointment_upcoming`, `calendar_event`, `immediate`.

If omitted, the client **infers** behaviour from `category`, dates, and status fields—**but** explicit `event_kind` reduces misclassification.

### B.3 Module-specific fields (minimum expectations)

Backends should expose enough fields for the client to distinguish **upcoming vs overdue vs paid** (invoices/debts), **terminal quote/PO status**, **payroll draft vs unpaid**, etc. The Flutter mappers read common names such as:

- Invoices: `due_date`, `paid_at`, `status`, payment flags  
- Debts: `due_date`, settlement / paid helpers  
- Quotes/POs: `valid_until`, `expected_delivery_date`, `updated_at`, `status`  
- Payroll: `pay_date`, `remind_at`, `payroll_reminder_kind` / `status`  
- Tenders: `closing_date`, `application_deadline`, application `status` and `deadline`  

Exact field names are defined implicitly by `BusinessService` / `TenderService` in the repo—backend agent should **grep** those files for `Uri.parse` and `['field']` access when in doubt.

### B.4 Calendar endpoint success flag

`GET calendar/events` must return **`success: true`** in strict mode when events are loaded; otherwise Vikumbusho treats the calendar feed as failed.

---

## 4. Part C — Tenders API (external)

- Flutter uses **JWT** obtained via Tenders API auth (see `lib/tenders/services/tender_service.dart`).
- Required capabilities:
  - List **active** tenders (closing + optional application deadline).
  - List **current user’s applications** with statuses and deadlines for outcomes.

If tenders are down or return error, **strict** Vikumbusho load fails entirely.

---

## 5. Part D — What the backend does *not* need to implement for Vikumbusho

- **FCM push** for each upcoming invoice row (client uses **local notifications**).
- A single SQL table that “stores all reminders” for business modules (aggregation is **read-time**).
- Duplicate REST resources under `/reminders/*` for invoices/quotes/etc.

---

## 6. Suggested verification procedure (backend agent)

1. Run automated tests or manual HTTP calls with a valid Sanctum token and profile `user_id`.
2. For each row in §3 table, confirm **200** and parseable JSON.
3. Confirm `GET /api/reminders` matches §2 / `reminders_backend_directive.md`.
4. Confirm Tenders API flows used by `TenderService.getAllTenderRemindersForAggregator`.
5. Fill **§7 report template** and return it to the app team.

---

## 7. Report back (required — copy and complete)

**Agent / date / branch or commit:**

**Environment verified:** `staging` / `production` / `local` (which base URL):

### 7.1 Standalone `/api/reminders`

| Check | Pass / Fail | Notes |
|-------|-------------|-------|
| GET list | | |
| POST create | | |
| PATCH update / mark done | | |
| DELETE | | |
| `user_id` = profile id + auth | | |

### 7.2 Aggregation endpoints (§3 table)

For each endpoint, fill **Pass** if **200** + expected shape under auth; **Fail** otherwise; **N/A** if intentionally not deployed.

| # | Endpoint | Pass / Fail / N/A | HTTP code | Notes |
|---|----------|-------------------|-----------|-------|
| 1 | calendar/events | | | |
| 2 | business/appointments/upcoming | | | |
| 3 | business/documents/expiring | | | |
| 4 | business/quotes/upcoming | | | |
| 5 | business/quotes/status-events | | | |
| 6 | business/invoices/upcoming | | | |
| 7 | business/invoices/paid-notifications | | | |
| 8 | transactions (failed) | | | |
| 9 | business/revenue/digest | | | |
| 10 | business/recurring/upcoming | | | |
| 11 | business/debts/upcoming | | | |
| 12 | business/expenses/upcoming | | | |
| 13 | business/tax/deadlines | | | |
| 14 | debts/crb/past-due | | | |
| 15 | business/employees/expiring | | | |
| 16 | business/payroll/upcoming | | | |
| 17 | business/purchase-orders/upcoming | | | |
| 18 | business/purchase-orders/status-events | | | |
| 19 | Tenders API (list + applications) | | | |

### 7.3 `event_kind` support

- [ ] Documented which resources return `event_kind` / `reminder_kind`  
- [ ] Values align with `ReminderEventKind` (see repo)  

**Notes:**

### 7.4 Blockers for strict Vikumbusho load

List any endpoint that returns **non-200**, **500**, or invalid JSON in prod/staging:

### 7.5 Sign-off

**Name / role:**  
**Date:**  
**Recommendation:** Ready for mobile QA / Not ready — reasons:

---

**End of directive.**
