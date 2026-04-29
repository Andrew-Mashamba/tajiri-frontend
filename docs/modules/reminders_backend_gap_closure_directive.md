# TAJIRI Vikumbusho — Backend Gap Closure Directive

> **Audience:** Backend team (Laravel API at `{API_BASE}` = `https://<host>/api`)  
> **Why this exists:** Route audit (2026-04-18) found **most Vikumbusho aggregation URLs used by the Flutter app are not registered**; live routes are often **`/api/business/{businessId}/...`** while the mobile client calls **user-scoped** **`/api/business/<resource>/...?user_id=`** endpoints. That breaks **strict** Vikumbusho load (`getAllStrictWithRetries`).  
> **Goal:** Implement missing routes **or** add **thin aggregator** endpoints that match the client contract below—without changing every business screen to multi-fetch.  
> **Client source of truth for URLs:** `lib/business/services/business_service.dart` (search `getExpiringDocuments`, `getUpcomingInvoicesForReminders`, etc.), `lib/calendar/services/calendar_service.dart`, `lib/tenders/services/tender_service.dart`.  
> **Related:** `docs/modules/reminders_backend_verification_directive.md` (verification checklist), `docs/modules/reminders_backend_directive.md` (standalone `/reminders` CRUD — assumed working).

---

## 1. Design principle

**Preferred approach:** Add **`auth:sanctum`** routes that accept **`user_id` (Tajiri profile id)** matching the Sanctum-resolved profile, then **internally**:

1. Resolve all `user_businesses` (or equivalent) for that user.
2. Reuse existing services/repos that already power `GET /api/business/{businessId}/...`.
3. Merge, dedupe, and return **`{ "success": true, "data": [ ... ] }`** (array).

This avoids duplicating business logic in the mobile app and matches what `RemindersAggregator` expects (parallel HTTP calls, one list per feed).

**Optional enhancement:** On each row in `data[]`, set **`event_kind`** or **`reminder_kind`** (strings aligned with Flutter `ReminderEventKind` in `lib/reminders/models/reminder_event_kind.dart`) so notification behaviour is explicit.

---

## 2. Authentication & `user_id`

| Rule | Detail |
|------|--------|
| Middleware | `auth:sanctum` on all routes in §3–§4 |
| `user_id` query | Must equal **`user_profiles.id`** resolved from the Bearer token (same pattern as `UserReminderController` / `ResolvesUserProfileFromSanctumUser`) |
| Mismatch | **403** if query/body `user_id` ≠ authenticated profile |

---

## 3. Routes to implement (or alias to aggregators)

Each row is the **exact path under `/api`** the Flutter client calls today (`ApiConfig.baseUrl` includes `/api`). Implement **GET** unless stated.

| Priority | Path | Query params (client) | Purpose |
|----------|------|------------------------|---------|
| P0 | `business/documents/expiring` | `user_id`, `days` (default 30) | Licence/document expiry rows |
| P0 | `business/quotes/upcoming` | `user_id` | Quotes for reminder (valid-until + status) |
| P0 | `business/quotes/status-events` | `user_id`, `days` (14) | Quote status-change events |
| P0 | `business/invoices/upcoming` | `user_id` | Invoices: upcoming / overdue / paid window |
| P0 | `business/invoices/paid-notifications` | `user_id`, `days` (7) | Paid confirmation rows |
| P0 | `business/debts/upcoming` | `user_id` | Debts upcoming vs overdue |
| P0 | `business/recurring/upcoming` | `user_id` | Recurring invoice schedule |
| P0 | `business/expenses/upcoming` | `user_id` | Upcoming expenses |
| P0 | `business/tax/deadlines` | `user_id` | TRA / tax deadlines |
| P0 | `business/employees/expiring` | `user_id`, `days` (30) | Contract expiry |
| P0 | `business/payroll/upcoming` | `user_id` | Payroll periods / draft / unpaid |
| P0 | `business/purchase-orders/upcoming` | `user_id` | Open POs + delivery |
| P0 | `business/purchase-orders/status-events` | `user_id`, `days` (14) | PO status events |
| P0 | `business/appointments/upcoming` | `user_id` | Business appointments |
| P1 | `business/revenue/digest` | `user_id` | Next revenue digest datetime (see §5) |
| P1 | `debts/crb/past-due` | `user_id` | CRB past-due entries for reminders |
| P2 | `transactions` | `user_id`, `status=failed`, `limit=10` | Failed ledger rows (see §4) |

**Implementation note:** If internal code is per-`businessId`, the aggregator should loop businesses, call the same queries, tag rows with `business_id` / `business_name` if needed, and concatenate `data`.

---

## 4. Transactions endpoint alignment

**Client today:**  
`GET /api/transactions?user_id={userId}&status=failed&limit=10`

**Gap:** Backend may ignore `user_id` (user from token only) and use **`per_page`** instead of **`limit`**.

**Fix (choose one, document in API changelog):**

1. **Accept both:** Honor `limit` (cap e.g. 50) as alias for page size when `per_page` absent; keep token-scoped user resolution.
2. **Strict:** Return **400** with message if `limit` unsupported **and** update Flutter to send `per_page` — *only if* you explicitly reject mobile contract change.

**Response:** Must remain parseable as JSON with a **`data`** list of transaction objects (fields used in mapper: failure time, amount, id/trace for `ReminderItem`).

---

## 5. Revenue digest vs existing `revenue/summary`

**Client expects:**  
`GET /api/business/revenue/digest?user_id=`  
Response shape used in Flutter:

```json
{
  "success": true,
  "data": {
    "next_digest": "<ISO8601 datetime string>",
    "period": "optional human-readable label"
  }
}
```

**Gap:** Audit reported only `GET …/revenue/summary` (KPI), not a digest datetime.

**Fix:** Either

- Implement **`business/revenue/digest`** as above (aggregate next digest across businesses), **or**
- Extend **`revenue/summary`** to include **`next_digest`** + **`period`** in `data`, **and** add a **redirect/alias** route `business/revenue/digest` → same controller method so the **path** matches the client without a Flutter release.

---

## 6. Calendar events

**Client:**  
`GET /api/calendar/events?user_id=&year=&month=&with_reminders=1`

**Gaps:**

1. **`with_reminders`** should filter or annotate events that have reminder settings (client maps only events with non-`none` reminder). If ignored, Vikumbusho shows extra noise or misses rows.
2. **Auth:** If calendar is public today, decide product policy: **require `auth:sanctum`** and scope by `user_id`, or document public read (and accept client empty list in strict mode when unauthenticated).

**Fix:** Implement controller logic for `with_reminders=1`; align route group with other profile APIs.

---

## 7. CRB past-due path

**Client:**  
`GET /api/debts/crb/past-due?user_id=`

**Gap:** Audit pointed to `credit-bureau/active-loans-overview` and `business/{id}/debts/sync-crb` instead.

**Fix:** Implement **`debts/crb/past-due`** as an aggregator that returns **`data[]`** of past-due rows with fields the client maps (`lender_label`, `past_due_days`, ids, etc.—see `getCrbPastDueEntries` in `business_service.dart`). Reuse existing CRB query logic internally.

---

## 8. JSON envelope & row fields

- Standard success: **`{ "success": true, "data": [ ... ] }`** or **`data: { ... }`** only where the Flutter parser expects an object (e.g. revenue digest).
- **HTTP 200** for success; **4xx/5xx** cause strict Vikumbusho to fail after retries.
- On each **list row**, include optional **`event_kind`** / **`reminder_kind`** (see `ReminderEventKind` in app repo).

---

## 9. Tenders API (out of main Laravel repo)

**Client:** `https://tenders.zimasystems.com/api` — JWT-based list + user applications.

**Fix:** Not in this codebase; tenders service must expose stable endpoints for **active tenders** (closing + application deadlines) and **user applications** (status, deadlines, outcomes). Track in a **separate** tenders deployment checklist.

---

## 10. Verification after implementation

Re-run the §7 table in `docs/modules/reminders_backend_verification_directive.md` with **HTTP 200** on each route using a real Sanctum token.

**Smoke test command pattern (replace host and token):**

```http
GET /api/business/invoices/upcoming?user_id=<profileId>
Authorization: Bearer <token>
```

Repeat for every path in §3.

---

## 11. Explicit “do not” list

- Do **not** require the mobile app to call **N × per-business** endpoints for Vikumbusho **unless** you explicitly drop strict aggregation and ship a Flutter refactor—product decision.
- Do **not** return HTML error pages on failure; JSON errors only.

---

## 12. Report back (backend agent)

When gaps are closed, return:

1. **PR / commit** hashes.  
2. **`routes/api.php` excerpt** (or route list) showing each path in §3–§7 registered.  
3. **Sample 200 JSON** (one per new aggregator) redacted.  
4. **Note** on transactions `limit` vs `per_page`.  
5. **Calendar** auth + `with_reminders` behaviour.

---

## 13. Frontend alignment (TAJIRI Flutter — this repo)

Implemented so the mobile client matches the deployed Vikumbusho aggregators and backend notes:

| Area | Implementation |
|------|----------------|
| **Base URL** | `lib/config/api_config.dart` — `baseUrl` must point at the API root that registers the §3 routes (e.g. `https://<host>/api`). Switch commented block for local vs UAT/production. |
| **Auth** | Every feed uses **`ApiConfig.authHeaders(token)`** once per request (`Authorization: Bearer` + optional `X-Txn-Trace-Id`). No Dio; no duplicate Bearer layers. |
| **`user_id`** | Passed as **Tajiri profile id** (`user_profiles.id`) on all `?user_id=` query strings — must match the profile resolved from the token (**403** if not). Wired from `RemindersModule` / `RemindersHomePage` / `AddReminderPage`. |
| **Paths** | `BusinessService` calls the **flat** user-scoped routes in §3 (e.g. `business/invoices/upcoming?user_id=`), not per-`businessId` resource URLs, matching `VikumbushoAggregationController`. |
| **Strict retries** | `RemindersAggregator.getAllStrictWithRetries` retries only **transient** errors (5xx, 408, 429, unknown); **does not** retry **4xx** [`RemindersSourceException`](../../lib/reminders/reminders_source_exception.dart) (wrong path/auth → fail fast). |
| **Calendar** | `CalendarService.getUpcomingWithReminders` sends `with_reminders=1`, `user_id`, `year`, `month` + Bearer — matches Sanctum-backed calendar. |
| **Transactions** | `GET …/transactions?user_id=&status=failed&limit=10` — backend maps `limit` to page size when `per_page` omitted. |

**Staging QA:** Run Vikumbusho on a build pointed at staging; confirm `getAllStrictWithRetries` completes without error. Backend automated analogue: `php artisan test tests/Feature/VikumbushoAggregationApiTest.php`.

---

**End of directive.**
