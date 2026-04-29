# Transactions Backend Directive

## Objective

Implement a **central money-activity ledger** that:

1. **Records** lifecycle events for financial operations (`pending` → `success` | `failed`) keyed by **`trace_id`**, fed by the mobile app’s `POST /api/transactions/record` calls.
2. **Lists** unified transaction rows for a user and optionally a **business**, with filters and pagination, via **`GET /api/transactions`**.
3. **Correlates** downstream domain API calls with the same logical operation using the **`X-Txn-Trace-Id`** HTTP header (optional but recommended for auditing and support).

The Flutter client lives under `lib/transactions/` (`TransactionService`, `CentralTransactionService`, `BusinessTransactionsPage`). This document is the backend contract for parity with that implementation.

**Non-goals for v1:** replacing domain-specific tables (invoices, wallet ledger, shop orders); this service is an **append/update-by-trace** event log plus a **read model** for the UI.

---

## Implementation status (Laravel backend)

The API described below is **implemented** in the Laravel app with:

- **Auth:** `auth:sanctum` — `Authorization: Bearer {token}`.
- **User identity:** The Sanctum `User` is mapped to `user_profiles.id` via `{phone}@tajiri.local`, matching **`user_businesses.user_id`** (same pattern as `ResolvesUserProfileFromSanctumUser`).
- **Table:** `transaction_ledger`, unique `trace_id` (migration `2026_04_17_230000_create_transaction_ledger_table.php` or equivalent).
- **Code (backend repo):** `App\Models\TransactionLedger`, `App\Http\Controllers\Api\TransactionLedgerController`, `routes/api.php` (`transactions` group), concern `App\Http\Controllers\Api\Concerns\ResolvesUserProfileFromSanctumUser` (or equivalent resolver trait).
- **Tests:** `tests/Feature/TransactionLedgerApiTest.php` (**7** tests, all passing) — e.g. `./vendor/bin/phpunit tests/Feature/TransactionLedgerApiTest.php`. Covers idempotent success without `completed_at` on second call (metadata merge), and index validation envelope for invalid `per_page` (e.g. `> 100`). SQLite test schema migration if present.

Run `php artisan migrate` on new environments to create `transaction_ledger`.

---

## 1) API envelope

Success:

```json
{
  "success": true,
  "message": "Optional human text",
  "data": {},
  "meta": {}
}
```

Failure (validation / semantics):

```json
{
  "success": false,
  "message": "First field error text, or exception message if the validator is missing",
  "code": "VALIDATION_ERROR",
  "errors": {}
}
```

**`jsonValidationError()` (implemented):** All validation responses for these endpoints use this **Tajiri envelope**: `success: false`, `code: VALIDATION_ERROR`, `errors` (Laravel-style field map), and a **readable** `message` (typically the first field error).

All routes below are under the **`/api`** prefix (same as existing `ApiConfig.baseUrl`).

---

## 2) HTTP header: `X-Txn-Trace-Id`

- **Name:** `X-Txn-Trace-Id`
- **Value:** Same string as `trace_id` for the in-flight operation (see §3).
- **Client:** Flutter sends this on subsequent API calls **after** `CentralTransactionService.start` (see `ApiConfig.authHeaders`). The **first** `POST /api/transactions/record` with `status: pending` uses **Bearer only** (no trace header) so bootstrap stays clean.
- **Ledger routes:** `POST /api/transactions/record` and `GET /api/transactions` **do not require** this header.
- **Domain routes:** Not wired globally on the backend; individual controllers may read `request()->header('X-Txn-Trace-Id')` for logging or future correlation when needed.

---

## 3) `POST /api/transactions/record`

**Purpose:** Upsert a ledger row by **`trace_id`**. The client calls this:

- Once with `status: pending` (+ `started_at`) when a money operation begins.
- Again with `status: success` (+ `completed_at`, optional `reference_id`, optional `metadata`) or `status: failed` (+ `failed_at`, optional `error_code`, `message`, `metadata`).

**Auth:** `Authorization: Bearer {token}` (required).

**Body (JSON):** Client sends a **subset** of fields per call; server should **merge** into the row identified by `trace_id` (create on first sight, update on subsequent).

| Field | Type | Required | Notes |
|--------|------|----------|--------|
| `trace_id` | string | yes | Unique per operation; client format `txn_{micros}_{hex}` |
| `status` | string | yes | `pending` \| `success` \| `failed` |
| `module` | string | if creating | e.g. `wallet`, `shop`, `business`, `subscription`, `michango` |
| `action` | string | if creating | e.g. `deposit`, `checkout`, `create_invoice` |
| `direction` | string | if creating | `incoming` \| `outgoing` |
| `amount` | number | if creating | >= 0 |
| `currency` | string | no | Default `TZS` |
| `actor_id` | string | no | Client user id as string when relevant |
| `business_id` | integer | no | **Must be integer in JSON** when present |
| `metadata` | object | no | Arbitrary JSON; merge shallow or replace per policy |
| `reference_id` | string | no | Domain id after success (invoice id, order id, etc.) |
| `started_at` | ISO8601 UTC | with pending | |
| `completed_at` | ISO8601 UTC | with success | |
| `failed_at` | ISO8601 UTC | with failed | |
| `error_code` | string | no | Machine-readable on failure |
| `message` | string | no | Human-readable on failure |

**Request pipeline (implemented):**

1. **Outer validation:** `$request->validate(...)` is wrapped in **try/catch** so bad JSON types / format returns the **Tajiri validation envelope** (see §1), not an uncaught exception.
2. **Row lock** on `trace_id`, then **`validateRecordSemantics()`** (replaces ad-hoc `empty()` checks). Uses `match` / `Validator::make` / **date** rules where appropriate.
3. **`createLedgerRow()`** assumes semantics are already **validated**; it only **persists** fields (no second validator block).

**Semantics (implemented):**

- **Create** (first sight of `trace_id`): `module`, `action`, `direction`, `amount` required; **`started_at` / `completed_at` / `failed_at`** required according to **initial** `status` (pending → `started_at`, success → `completed_at`, failed → `failed_at`).
- **`business_id`:** If sent, must reference a business that **exists** and **belongs** to the authenticated profile; otherwise validation fails.
- **Merge:** `metadata` is **shallow-merged** on updates; other scalar fields update when provided. Row updates use locking where implemented.
- **Updates (transition rules):**
  - **pending → pending:** `started_at` required only if the row has **no** `started_at` yet **and** the body does not supply one.
  - **pending → success:** `completed_at` required.
  - **pending → failed:** `failed_at` required.
  - **success → success** / **failed → failed** (idempotent terminal): **no** re-required timestamps — e.g. a second success call may **omit** `completed_at` and only merge `metadata`.
- **Idempotency:** Repeating the same **terminal** `success` or `failed` updates the same row (no duplicate rows).
- **Transitions:** From `success` or `failed`, only the **same** terminal status may repeat. Disallowed: `success` ↔ `failed` cross-over, or moving back to `pending` → **`422`**, `VALIDATION_ERROR`, `errors.status` (or equivalent).
- **Wrong owner:** If `trace_id` already exists for **another** profile → **`403`** (`FORBIDDEN`).
- **Failure tolerance (client):** Flutter does not block core flows if this endpoint fails; server should still return consistent status/body for logs.

**Response `data`:** Persisted row (same shape as §4) on success.

**HTTP errors:** `401` unauthenticated; `403` forbidden (wrong business or `trace_id` owner); `422` validation / transition (`VALIDATION_ERROR` + `errors` object).

---

## 4) `GET /api/transactions`

**Purpose:** Paginated list of ledger rows for the authenticated user, with optional **business** scope and filters.

**Auth:** `Authorization: Bearer {token}` (required).

**Query validation (implemented):** `$request->validate(...)` for query parameters is wrapped in **try/catch** so invalid values (e.g. **`per_page` > 100**) return the same **Tajiri envelope** as POST (`success: false`, `code: VALIDATION_ERROR`, `errors`, readable `message`).

**Query parameters:**

| Parameter | Type | Description |
|-----------|------|-------------|
| `page` | int | Default `1` |
| `per_page` | int | Default `40` (client may send `30`); cap server-side e.g. 100 |
| `business_id` | int | Optional; when set, return rows for that business **and** enforce ownership |
| `status` | string | Optional: `pending`, `success`, `failed` |
| `direction` | string | Optional: `incoming`, `outgoing` |
| `module` | string | Optional filter |

**Authorization:**

- Without `business_id`: rows owned by the authenticated profile.
- With `business_id`: user must **own** that business (same rules as other business modules) → **`403`** if not.

**Response `success: true`:**

**Primary (implemented):** flat array + `meta`:

```json
{
  "success": true,
  "data": [ { "...row..." } ],
  "meta": {
    "current_page": 1,
    "last_page": 3,
    "total": 42,
    "per_page": 40
  }
}
```

**Alternate:** The Flutter client also accepts a **Laravel-style nested** `data.data` paginator (see `TransactionService._parseTransactionsPayload`); either shape is fine.

**Meta:** `current_page`, `last_page`, `total`, `per_page`; snake_case (and camelCase `currentPage` / `lastPage` in `meta` if dual support is kept).

**Row object (each item in `data` array):** Should be compatible with client `RecordedTransaction.fromJson`:

| Field | Type | Notes |
|-------|------|--------|
| `id` | string or int | Optional stable id |
| `trace_id` | string | Required for display |
| `status` | string | `pending` \| `success` \| `failed` |
| `module` | string | |
| `action` | string | |
| `direction` | string | `incoming` \| `outgoing` |
| `amount` | number | |
| `currency` | string | Default `TZS` |
| `reference_id` | string | optional |
| `business_id` | int | optional |
| `metadata` | object | optional; may include `title` for UI |
| `started_at` | ISO8601 | optional |
| `completed_at` | ISO8601 | optional |
| `failed_at` | ISO8601 | optional |
| `message` | string | optional (failure / info) |

Timestamps in responses are **ISO8601** strings.

**Empty list:** Returning `data: []` with `success: true` is valid. The Flutter client may **fall back** to a composite (invoices, expenses, debts, purchase orders) when `business_id` is set and the ledger is empty or unreachable.

---

## 5) Persistence

### Table: `transaction_ledger` (implemented)

- `id` bigIncrements
- `user_id` unsignedBigInteger, indexed (owner)
- `business_id` unsignedBigInteger nullable, indexed
- `trace_id` string(80) **unique**
- `status` enum/string: `pending`, `success`, `failed`
- `module` varchar(64)
- `action` varchar(64)
- `direction` varchar(16)
- `amount` decimal(15,2)
- `currency` char(3) default `TZS`
- `reference_id` varchar(64) nullable
- `actor_id` varchar(32) nullable (string as client sends)
- `metadata` json nullable
- `error_code` varchar(64) nullable
- `message` text nullable
- `started_at` timestamp nullable
- `completed_at` timestamp nullable
- `failed_at` timestamp nullable
- `created_at`, `updated_at`

**Indexes:**

- Unique(`trace_id`)
- Index(`user_id`, `created_at`)
- Index(`business_id`, `created_at`)
- Optional composite for filters: (`user_id`, `status`, `direction`, `module`)

---

## 6) Failure envelope (HTTP)

| HTTP | When |
|------|------|
| `401` | Missing/invalid Bearer token |
| `403` | `trace_id` belongs to another user; or `business_id` not owned |
| `422` | Request/query validation, **invalid status transition**, or bad types — body: `success: false`, `code: VALIDATION_ERROR`, `errors` object (e.g. `errors.status`, `errors.per_page`), plus `message` |

Validation responses (including caught validation exceptions) use **`jsonValidationError()`** so shape is consistent across `POST /api/transactions/record` and `GET /api/transactions`.

## 7) Observability and product notes

- **Support:** Look up rows by **`trace_id`** (unique) or **`reference_id`** in `transaction_ledger`.
- **Retention:** Policy (e.g. 24 months) is **not** enforced in code yet; can be a scheduled job later.
- **PII:** `metadata` may contain user-provided strings; apply same redaction rules as other logs.
- **Wallet / shop / business:** This ledger does **not** replace source-of-truth tables; it **complements** them for timelines and the business “Transactions” tab.

---

## 8) Acceptance checklist (backend)

- [x] `POST /api/transactions/record` upserts by `trace_id`, merge, idempotent terminal repeats, strict transitions, `403` for wrong owner.
- [x] `business_id` validated when present (exists + belongs to profile).
- [x] `GET /api/transactions` filters + pagination; `data` array + `meta` (`current_page`, `last_page`, `total`, `per_page`).
- [x] `business_id` query requires business ownership (`403` otherwise).
- [ ] Optional: domain routes read `X-Txn-Trace-Id` for logging/correlation.

---

## 9) References (frontend)

- `lib/transactions/services/central_transaction_service.dart` — `POST .../transactions/record`
- `lib/transactions/services/transaction_service.dart` — `GET .../transactions`
- `lib/transactions/models/transaction_models.dart` — row parsing
- `lib/config/api_config.dart` — `X-Txn-Trace-Id` header behavior
- `docs/transactions_points.md` — broader inventory of money-moving entry points in the app
