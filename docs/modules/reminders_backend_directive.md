# TAJIRI User Reminders — Backend Implementation Directive

> **Audience:** Backend coding agent (Laravel / TAJIRI API)  
> **Frontend reference:** `lib/reminders/services/reminders_service.dart`, `lib/reminders/models/reminder_models.dart`  
> **Design spec:** `docs/superpowers/specs/2026-04-18-reminders-module-design.md`

---

## 1. Goal

Implement a **user-scoped REST API** for **standalone reminders** created in the mobile app: create, list, update, delete, and mark done. The Flutter client is **offline-first** (SQLite): it writes locally immediately, then syncs to this API. Aggregated reminders from other modules (business, calendar, tenders) are **not** stored here—only **user-created standalone** reminders need persistence on the server.

**Base path (relative to API root):** `reminders`  
**Full URL pattern:** `{API_BASE}/reminders` where `API_BASE` is typically `https://<host>/api` (same as `ApiConfig.baseUrl` in the app).

---

## 2. Authentication & authorization

| Requirement | Detail |
|-------------|--------|
| Auth | `Authorization: Bearer <token>` (same as rest of TAJIRI API) |
| User identity | Resolve authenticated user from token; **do not** trust `user_id` in the body alone for authorization |
| Scoping | Every row belongs to **one user** (`user_id`). Users may only read/write their own reminders |

The client sends `user_id` as a query param on **GET** and in the **POST** JSON body.

**TAJIRI convention (implemented backend):** `user_id` is the **Tajiri profile id** (`user_profiles.id`), resolved from the Sanctum token the same way as other profile-scoped APIs (e.g. transaction ledger). It must match the authenticated profile; arbitrary body values must not bypass authorization.

---

## 3. JSON envelope (recommended)

Align with the rest of TAJIRI APIs:

```json
{
  "success": true,
  "data": { ... },
  "message": "optional"
}
```

The Flutter list fetch accepts **`data` as a JSON array** of reminder objects:

```json
{
  "success": true,
  "data": [ { ... }, { ... } ]
}
```

**GET** success response: HTTP **200** with `data` = array (may be empty).

---

## 4. Reminder resource shape (snake_case)

The client parses each item with `ReminderItem.fromJson`. Support these fields:

| Field | Type | Required | Notes |
|-------|------|----------|--------|
| `id` | string or number | yes | Serialized to string on client. See **§5 ID strategy**. |
| `title` | string | yes | |
| `subtitle` | string \| null | no | |
| `due_at` | string (ISO 8601) | yes | e.g. `2026-05-01T09:00:00.000Z` |
| `category` | string | yes | One of **§6** enum names |
| `repeat` | string | yes | One of **§7** enum names |
| `is_done` | int or bool | yes | Client sends `0`/`1`; accepts bool too |
| `is_standalone` | int or bool | yes | For this API, typically `1` / `true` |
| `source_route` | string \| null | no | Usually null for server-backed standalone rows |
| `server_id` | int | optional | Client can store; not required for MVP |
| `synced_at` | string (ISO 8601) | optional | Informational |

---

## 5. ID strategy (critical for offline sync)

The mobile app generates client IDs:

- Format: `standalone_<uuid>` (example: `standalone_550e8400-e29b-41d4-a716-446655440000`)

**POST body** includes:

- `id`: that client string  
- `user_id`: integer  

**PATCH** and **DELETE** use the **path**:

- `PATCH /api/reminders/{id}`
- `DELETE /api/reminders/{id}`

where `{id}` is the **same string** the client stored locally (`standalone_...`), **not** only the numeric database PK.

**Implementation guidance:**

1. Add a **unique string column** e.g. `client_id` (nullable for legacy) **or** use a string primary key that stores `standalone_*` for app-created rows.
2. Route binding must resolve `{id}` whether it is numeric or `standalone_<uuid>` (use a single route parameter; avoid assuming integer-only).

**POST response (create):**

- HTTP **201** (preferred) or **200**
- Body must include a **numeric** primary key so the client can mark the row synced:

```json
{
  "success": true,
  "data": {
    "id": 98765
  }
}
```

The client reads `data.id` as integer and stores it in SQLite as `server_id` via `markSynced(localClientId, serverId)`.  
If you only return string IDs, the client’s `int.tryParse` may never set `server_id`—**prefer returning integer PK in `data.id`** (or add a dedicated `server_id` field the client can be updated to read later).

**Reconciliation note:** On **GET**, if each row’s `id` in JSON is the numeric PK stringified (`"98765"`) while the local row still uses `standalone_xxx`, the client may insert **duplicate** rows until you align IDs or add a `client_id` field in GET responses for merge. **Recommended:** include `client_id` in API responses when present, or return `id` as the client id for app-origin rows.

---

## 6. `category` allowed values

Must match Dart enum **names** (camelCase where applicable):

`calendar`, `appointment`, `quote`, `invoice`, `transaction`, `revenue`, `recurring`, `debt`, `document`, `expense`, `tax`, `credit`, `employee`, `payroll`, `purchaseOrder`, `tender`, `general`

Invalid values: reject with **422** or map to `general` (document the choice).

---

## 7. `repeat` allowed values

`none`, `daily`, `weekly`, `monthly`, `yearly`

---

## 8. Endpoints (contract)

### 8.1 `GET /api/reminders?user_id={userId}`

- **Purpose:** Full list for sync and refresh.
- **Auth:** Required.
- **Query:** `user_id` — must match authenticated user (or derive from auth only).
- **Response:** 200 + `data`: array of reminder objects (§4).
- **Ordering:** Prefer `due_at` ascending (client also sorts).

### 8.2 `POST /api/reminders`

- **Purpose:** Create from client after offline insert; body includes `user_id` and full reminder fields (§4), including `id: "standalone_<uuid>"`.
- **Response:** 201 or 200; **`data.id`** = integer primary key (§5).

### 8.3 `PATCH /api/reminders/{id}`

- **Purpose:** Partial update.
- **Path `{id}`:** Client’s reminder id — **string** `standalone_...` or numeric string.
- **Bodies observed in client:**
  - Full update: JSON from `toJson()` — `id`, `title`, `subtitle`, `due_at`, `category`, `repeat`, `is_done`, `is_standalone`, `source_route`.
  - Mark done only: `{ "is_done": 1 }`
- **Response:** 200 with updated resource or minimal success payload.

### 8.4 `DELETE /api/reminders/{id}`

- **Purpose:** Remove reminder on server when deleted locally.
- **Path `{id}`:** Same as PATCH.
- **Response:** 200 or 204.

---

## 9. Validation rules (suggested)

- `title`: required, max length reasonable (e.g. 500).
- `due_at`: required, valid datetime.
- `category` / `repeat`: enum validation (§6, §7).
- `is_done` / `is_standalone`: boolean or 0/1.

---

## 10. Errors

- **401** — missing/invalid token  
- **403** — resource belongs to another user  
- **404** — unknown `{id}` for PATCH/DELETE  
- **422** — validation errors (return Laravel-style `errors` + message)  
- **429** — optional rate limit for sync storms  

The mobile app **does not** surface most API errors for reminders (logs only); still return consistent JSON for debugging.

---

## 11. Out of scope for this resource

- Business module “upcoming” feeds (quotes, invoices, debts, etc.) — separate endpoints already called by `BusinessService` adapters.
- Calendar / tender aggregation — separate services.
- Push from server (FCM) — optional future; client uses **local notifications** for scheduling.

---

## 12. Verification checklist (backend agent)

- [x] Routes registered under `api` prefix with same middleware as other user APIs *(done)*  
- [x] `GET` returns `data` as array; shape matches §4 *(done)*  
- [x] `POST` accepts `standalone_*` `id` + `user_id`; returns numeric `data.id` *(done)*  
- [x] `PATCH` / `DELETE` resolve `{id}` by numeric PK **or** `client_id` / `standalone_*` *(done)*  
- [x] Mark-done payload `{ "is_done": 1 }` works *(done)*  
- [x] Feature tests: create → list → patch (client id + numeric id) → delete; wrong `user_id` on GET → 403; invalid category → 422; user isolation *(done)*  

---

## 12a. Implemented backend (summary — 2026-04-18)

This section records what was deployed so the app team and future agents stay aligned.

| Area | Detail |
|------|--------|
| **Migration** | `2026_04_18_100000_create_user_reminders_table` — table `user_reminders`: `user_id` → **`user_profiles`**, `client_id` (for `standalone_*`), `title`, `subtitle`, `due_at` (`timestampTz`), `category`, `recurrence` (stores repeat), `is_done`, `is_standalone`, `source_route`, timestamps. Indexes: `(user_id, due_at)`, **unique** `(user_id, client_id)`. |
| **Model** | `App\Models\UserReminder` — fillable, casts, `userProfile()` relation. |
| **Controller** | `App\Http\Controllers\Api\UserReminderController` — uses **`ResolvesUserProfileFromSanctumUser`** (same pattern as `TransactionLedger`): Sanctum user → profile id. |
| **Validation** | `category`: must be one of §6 — **422** if invalid (**not** mapped to `general`). `repeat`: `none`, `daily`, `weekly`, `monthly`, `yearly`. |
| **GET list** | Each item: `id` is the **client id** when set (so Flutter can merge with `standalone_*`); **`server_id`** = numeric PK; `client_id` echoed when present; `repeat` in JSON is derived from stored `recurrence`. |
| **POST** | **Idempotent** on `(user_id, client_id)`: duplicate create returns **200** and existing row’s numeric `data.id` (not 201). |
| **PATCH / DELETE** | `{id}` resolves by **numeric PK** or **client_id**; wrong user → **403**; missing → **404**. |
| **401** | When profile cannot be resolved from token (same as other Sanctum APIs). |
| **Routes** | `GET /api/reminders`, `POST /api/reminders`, `PATCH /api/reminders/{id}`, `DELETE /api/reminders/{id}` — `{id}` route constraint allows `standalone_<uuid>`. |

**Typo note:** Any spec that said `GET /api/reminds` was wrong; the live path is **`/api/reminders`**.

**Tests:** `tests/Feature/UserReminderApiTest.php` (+ test schema migration under `tests/Database/Migrations/`).

---

## 13. Laravel hints (if applicable)

- `routes/api.php`: registered with project Sanctum middleware  
- **Implemented:** `Api\UserReminderController`, model `UserReminder`, FK `user_id` → **`user_profiles`**, unique `(user_id, client_id)`  

---

## 14. Reference — client HTTP snippets

```http
GET /api/reminders?user_id=123
Authorization: Bearer …
```

```http
POST /api/reminders
Content-Type: application/json
Authorization: Bearer …

{"id":"standalone_…","title":"…","subtitle":null,"due_at":"2026-05-01T09:00:00.000Z","category":"general","repeat":"none","is_done":0,"is_standalone":1,"source_route":null,"user_id":123}
```

```http
PATCH /api/reminders/standalone_…
Content-Type: application/json
Authorization: Bearer …

{"is_done":1}
```

```http
DELETE /api/reminders/standalone_…
Authorization: Bearer …
```

---

## 15. App team — `user_id` (implemented)

The reminders API expects **`user_id` = `user_profiles.id`**. The Flutter app wires **`RemindersModule(userId: currentUserId)`** from the profile tab (own profile only; other users see a lock message). That matches Sanctum-resolved profile id for GET/POST. Aggregated deep-links use `ReminderNavigation` + `profileUserId` (same id).

**SQLite GET reconcile:** After `GET /reminders`, rows are upserted with **`synced_at` set** so they are not retried as pending `POST` creates.

---

## 16. Aggregated business feeds — `event_kind` (2026-04-18)

The Flutter app merges **business / calendar / tenders** into Vikumbusho. Each row may include **`event_kind`** (alias **`reminder_kind`**) so the client can schedule **24+ distinct notification behaviours** (see `lib/reminders/models/reminder_event_kind.dart`).  
If omitted, the client infers behaviour from **`category`** and dates (e.g. overdue invoice vs upcoming).

### 16.1 Core fields (optional on any `data[]` item)

| Field | Type | Notes |
|-------|------|--------|
| `event_kind` | string | One of the `ReminderEventKind` constants (see app repo). |
| `reminder_kind` | string | Accepted alias for `event_kind`. |

### 16.2 Endpoints the app calls (existing + optional)

| Endpoint | Purpose |
|----------|---------|
| `GET /api/business/documents/expiring` | Document / licence expiry (rows 1–2). |
| `GET /api/business/quotes/upcoming` | Should include `status`, `updated_at`, `valid_until` so the client can split **valid_until** vs **accepted/rejected** (rows 3–4). |
| `GET /api/business/quotes/status-events?user_id=&days=14` | **Optional.** Extra rows when `upcoming` does not return status changes. |
| `GET /api/business/invoices/upcoming` | Should include `due_date`, `status`, `paid_at`, `is_paid` / `is_fully_paid` so the client can split **upcoming**, **overdue**, **paid** (rows 5–7). |
| `GET /api/business/invoices/paid-notifications?user_id=&days=7` | **Optional.** Paid confirmations when not derivable from `upcoming`. |
| `GET /api/business/transactions?status=failed` | Failed transactions (row 8). |
| `GET /api/business/revenue/digest` | Revenue digest schedule (row 9). |
| `GET /api/business/recurring/upcoming` | Recurring invoice generation (row 10). |
| `GET /api/business/debts/upcoming` | Should include settlement fields so unpaid overdue vs upcoming can be split (rows 11–12). |
| `GET /api/business/expenses/upcoming` | Recurring expense (row 14). |
| `GET /api/business/tax/deadlines` | TRA deadlines (row 15). |
| `GET /api/debts/crb/past-due` | CRB past-due (row 13). |
| `GET /api/business/employees/expiring` | Contracts (row 16). |
| `GET /api/business/payroll/upcoming` | Should include `payroll_reminder_kind` or `kind` (`draft` / `approved_unpaid`) + `status`, `pay_date`, `remind_at` (rows 17–18). |
| `GET /api/business/purchase-orders/upcoming` | Should include `status`, `updated_at`, `expected_delivery_date` for delivery vs delivered/cancelled (rows 19–20). |
| `GET /api/business/purchase-orders/status-events?user_id=&days=14` | **Optional.** PO status events. |
| `GET /api/business/appointments/upcoming` | Appointments (row 24). |

### 16.3 Tenders API (external catalogue)

- List JSON may include **`application_deadline`** (or **`submission_deadline`**) in addition to **`closing_date`** (rows 21–22).
- User **`GET /me/applications`** supplies **application deadlines** and **won/lost** outcomes for rows 22–23.

### 16.4 Notification semantics (client)

- **Overdue invoice / debt** (`invoice_overdue`, `debt_overdue`): **daily** local notification at **08:00** until cleared or paid (client-side).  
- **Immediate** kinds (`quote_status`, `invoice_paid`, `po_status`, `tender_outcome`, `failed_transaction`, `crb_past_due`, …): fire as soon as sensible after `due_at`.  
- **Lead times** (e.g. 7/3/1, 3/1, 30/7/1) are applied when `event_kind` matches or when only `category` is present.

---

**End of directive.**
