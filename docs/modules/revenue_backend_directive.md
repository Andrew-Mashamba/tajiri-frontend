# Revenue Backend Directive

## Objective

Give the **Revenue** experience in the Flutter app (`lib/revenue/`) a **single authoritative, fast read model** so that an owner with **multiple businesses** (same identity model as `BizTabWrapper` / `BusinessNotifier` / `user_businesses`) can:

1. See **portfolio totals** (gross billed, collected, outstanding) in **one request**, not N parallel `GET /business/{id}/invoices` calls.
2. See **per-business breakdown** with identical semantics to the portfolio row (no client-side drift).
3. Optionally align a second line of metrics with **`GET /api/transactions`** (see [transactions_backend_directive.md](./transactions_backend_directive.md)) for **ledger-recognized** incoming amounts when the central ledger is the source of truth.

**Non-goals for v1:** replacing invoice tables; invoices remain source of truth for **billed / collected / AR** until product explicitly switches KPIs to ledger-only.

---

## Problem statement (current client)

`RevenueService.loadPortfolio` loads **every business’s full invoice list** in parallel (`BusinessService.getInvoices` per `business_id`). That:

- Does not scale with business count or invoice volume.
- Recomputes aggregation in Dart (duplicated rules vs SQL).
- Cannot use DB indexes as effectively as a grouped query.
- Risks **semantic drift** if the backend later changes which invoice statuses count toward revenue.

---

## Implementation status

### Laravel (backend)

Implemented: **`GET /api/revenue/summary`** (Sanctum, profile resolution consistent with other business APIs), **`RevenueSummaryService`** (grouped SQL over owned businesses + `business_invoices`), **`RevenueSummaryController`**, **`config/revenue.php`** (`summary_cache_ttl_seconds`), composite index migration, **`tests/Feature/RevenueSummaryApiTest.php`**. Query params include `period`, `date_from` / `date_to` (custom), `basis` (`ledger_incoming` may 422 until implemented), optional `business_id`, `include_ledger_hint`. Response: `data.totals`, `data.by_business`, optional `data.ledger_hint`, `meta` (`computed_at`, `cache_ttl_seconds`, `timezone`).

### Flutter (frontend)

**`RevenueService.loadPortfolio`** (`lib/revenue/services/revenue_service.dart`) calls **`GET {ApiConfig.baseUrl}/revenue/summary`** with **`include_ledger_hint=1`**, **`basis=invoice_created`**, and period **`all` \| `this_month` \| `last_30_days`**. Uses **`ApiConfig.authHeadersWithoutTrace`**. On **HTTP 404** only, falls back to parallel **`BusinessService.getInvoices`** per business. Merges **`by_business`** with the local business list so businesses missing from the payload still appear (zeros). Optional **`RevenueLedgerHint`** is shown on **`RevenueOverviewPage`** when present.

**`RevenueService.loadBusinessTotals`** calls **`GET …/revenue/summary?business_id={id}`** with the same period/basis/hint flags; on **404** only, falls back to **`getInvoices`** + client **`computeTotals`**. **`BusinessRevenuePage`** uses **`loadBusinessTotals`** and shows **`ledgerHint`** when present.

---

## 1) API envelope

Use the same **Tajiri JSON envelope** as other business APIs (see [transactions_backend_directive.md](./transactions_backend_directive.md) §1):

- Success: `success: true`, `data`, optional `meta`.
- Validation: `success: false`, `code: VALIDATION_ERROR`, `message`, `errors`.

All routes under **`/api`**, auth **`Authorization: Bearer {token}`** (`auth:sanctum`), user resolved to **`user_profiles.id`** the same way as business modules (`user_businesses.user_id`).

---

## 2) Recommended endpoint: portfolio + per-business summary

### `GET /api/revenue/summary` (or `GET /api/business/revenue-summary`)

**Purpose:** One round-trip for the **Revenue overview** screen (`RevenueOverviewPage`).

**Auth:** Required. Scope = all businesses the profile **owns** (same join as `GET /business?user_id=` merged shops list — **single rule**: only businesses linked to the authenticated profile).

**Query parameters:**

| Parameter | Type | Required | Description |
|-----------|------|----------|--------------|
| `period` | string | no | `all` (default) \| `this_month` \| `last_30_days` \| `custom` |
| `date_from` | date (Y-m-d) | if `period=custom` | Inclusive; interpreted in **business/account timezone** or **UTC** — pick one, document it, and use consistently with invoices. |
| `date_to` | date (Y-m-d) | if `period=custom` | Inclusive end date for filtering. |
| `basis` | string | no | `invoice_created` (default) — see §4. Future: `invoice_paid`, `ledger_incoming`. |

**Optional future scope:**

| Parameter | Type | Description |
|-----------|------|-------------|
| `business_id` | int | When set, return **only** that business’s row **and** portfolio totals equal that row (after ownership check). Enables same endpoint for single-business drill-down without shipping full invoice arrays. |

**Authorization:**

- Without `business_id`: aggregate over **all** owned businesses.
- With `business_id`: **`403`** if the business is not linked to the profile.

**Response `success: true` — `data` shape (contract for Flutter):**

```json
{
  "success": true,
  "data": {
    "currency": "TZS",
    "period": {
      "preset": "this_month",
      "date_from": null,
      "date_to": null
    },
    "basis": "invoice_created",
    "totals": {
      "gross_billed": "0.00",
      "collected": "0.00",
      "outstanding": "0.00",
      "invoice_count": 0
    },
    "by_business": [
      {
        "business_id": 1,
        "business_name": "Acme Salon",
        "gross_billed": "0.00",
        "collected": "0.00",
        "outstanding": "0.00",
        "invoice_count": 0
      }
    ],
    "ledger_hint": null
  },
  "meta": {
    "computed_at": "2026-04-17T12:00:00Z",
    "cache_ttl_seconds": 60
  }
}
```

**Numeric types:** Prefer **strings for decimals** (`"12345.67"`) in JSON to avoid float drift in PHP/JS clients; Flutter can `double.parse`. Alternatively return numbers if the API already standardizes on JSON numbers for money — **stay consistent** with `invoices` responses.

**`by_business` ordering:** Default **`gross_billed` DESC** (matches current client sort). Failed businesses should not appear as separate HTTP errors; each row should still return with `gross_billed` = 0 and an optional `error` string only if partial failure is possible (e.g. shard timeout) — ideally **never** for a single-DB query.

---

## 3) Optional second payload: ledger-aligned hint

When `basis` or a separate flag `include_ledger_hint=true`:

**`ledger_hint` object** (optional) — pre-aggregated from `transaction_ledger` for the same profile and period:

| Field | Description |
|-------|-------------|
| `incoming_success_total` | Sum of `amount` where `status = success`, `direction = incoming`, optional filter `module in (...)` for “revenue-like” actions. |
| `row_count` | For UI transparency. |

**Rules:**

- Must use the **same** `user_id` / business ownership rules as `GET /api/transactions`.
- Clearly **document** which `module` / `action` pairs count as “revenue” (e.g. `business` + `invoice` payment success) so product can compare **billed** vs **recognized**.

If ledger is empty or disabled, return `"ledger_hint": null` — do not fail the whole request.

---

## 4) Invoice aggregation semantics (must match Flutter)

Flutter (`RevenueService`) currently:

- **Excludes** invoices with status: **draft**, **cancelled**, **void** (and `voided` / `void_status` snake_case from API).
- **Includes** all other statuses in gross/collected sums.
- **Period:** For `this_month` / `last_30_days`, filters by **`created_at`** (invoice issue date). Invoices with **`created_at` null** are **excluded** from period modes (not from `all`).

**Backend must implement the same rules in SQL** (or a documented view) so the app can drop client-side recomputation when calling `GET /api/revenue/summary`.

**Suggested SQL filters (conceptual):**

```sql
WHERE invoices.user_or_business_scope = :profile
  AND invoices.status NOT IN ('draft', 'cancelled', 'void', 'voided', 'void_status')
  AND (:period = 'all' OR (
        invoices.created_at IS NOT NULL
        AND invoices.created_at >= :period_start
        AND invoices.created_at < :period_end_exclusive
      ))
```

Adjust table/column names to the real schema (`business_id`, `created_at`, `total_amount`, `amount_paid`, etc.).

**Outstanding:** `GREATEST(SUM(total_amount) - SUM(amount_paid), 0)` per bucket, or row-level then sum — **match** Flutter’s `(gross - collected).clamp(0, ∞)` per invoice then sum vs aggregate-first; document which you use (aggregate-first is fine if mathematically equivalent for non-negative line amounts).

---

## 5) Performance and correctness

1. **Single query (preferred):** `GROUP BY business_id` with a join to `businesses` / `user_businesses` for name + ownership filter — **one** round-trip to the DB.
2. **Indexes:** Composite index on `(business_id, created_at, status)` or whatever supports the filter + group (measure with `EXPLAIN`).
3. **No unbounded invoice fetch** for this endpoint — aggregation only.
4. **Caching:** Short TTL (e.g. 30–120s) or `ETag` based on `MAX(updated_at)` from invoices in scope — optional but recommended for profile tabs that users flip often.
5. **Rate limiting:** Same class as other heavy GETs if needed.

---

## 6) Relationship to existing routes

| Existing | Role after this directive |
|----------|---------------------------|
| `GET /business/{id}/invoices` | Still used for **invoice lists**, editing, PDF — not removed. |
| `GET /api/transactions` | **Ledger timeline**; optional input to `ledger_hint` or future `basis=ledger_incoming`. |
| **`GET /api/revenue/summary`** (new) | **Portfolio KPIs** for `RevenueOverviewPage` + drill-down header. |

Flutter follow-up (not blocking backend): switch `RevenueService.loadPortfolio` to call `GET /api/revenue/summary` when `success`, and **fallback** to current parallel invoice fetch if `404` / old server (same pattern as transaction composite fallback).

---

## 7) Future extensions (document now, implement later)

| Feature | Notes |
|---------|--------|
| **`basis=invoice_paid`** | Collected in period by `paid_at` / payment rows, not `created_at`. |
| **Credit notes** | Subtract from gross or show as separate line — product decision. |
| **Multi-currency** | Per-invoice `currency` with FX snapshot — out of scope until invoices support it consistently. |
| **Export CSV/PDF** | `GET /api/revenue/export?...` with async job for large tenants. |
| **Budget / tax modules** | Consume same summary service internally to avoid duplicate SQL. |

---

## 8) Failure envelope (HTTP)

| HTTP | When |
|------|------|
| `401` | Missing/invalid Bearer |
| `403` | `business_id` not owned by profile |
| `422` | Invalid `period`, dates, or `basis` — `VALIDATION_ERROR` + `errors` |

---

## 9) Acceptance checklist (backend)

- [ ] `GET /api/revenue/summary` returns `totals` + `by_business` for authenticated owner in **one** DB round-trip (or documented minimal round-trips).
- [ ] Invoice **status** exclusions match §4 (draft / cancelled / void family excluded).
- [ ] **Period** presets `all`, `this_month`, `last_30_days`, and `custom` match §4 (`created_at`; null excluded for non-`all`).
- [ ] **403** when `business_id` is not owned; without `business_id`, only owned businesses appear in `by_business`.
- [ ] Amounts stable for UI: documented type (string decimal vs number) and currency field.
- [ ] Optional `ledger_hint` documented and consistent with [transactions_backend_directive.md](./transactions_backend_directive.md).
- [ ] Feature tests: multi-business user with mixed invoices; void/draft excluded; period boundary; unauthorized `business_id`.

---

## 10) References (frontend)

- `lib/revenue/services/revenue_service.dart` — current aggregation + parallel fetch.
- `lib/revenue/models/revenue_models.dart` — `RevenuePeriodScope`, `RevenueTotals`, `BusinessRevenueRow`, `PortfolioRevenueLoadResult`.
- `lib/revenue/pages/revenue_overview_page.dart` — portfolio UI; pull refresh uses `BusinessNotifier.instance.refresh`.
- `lib/revenue/pages/business_revenue_page.dart` — single-business KPIs + link to `BusinessTransactionsPage`.
- `lib/business/services/business_service.dart` — `getInvoices`, `getMyBusinesses`.
- `docs/modules/transactions_backend_directive.md` — ledger for drill-down and optional revenue reconciliation.

---

## 11) Suggested prompt for `POST /api/ai/ask`

```
[Type: implement]
[Context: TAJIRI Flutter Revenue module — docs/modules/revenue_backend_directive.md]

Implement GET /api/revenue/summary per revenue_backend_directive.md:
- Sanctum auth, user_profiles ownership via user_businesses
- Query: period=all|this_month|last_30_days|custom + date_from/date_to
- data.totals + data.by_business, currency TZS, amounts as strings
- SQL aggregation matching Flutter RevenueService invoice rules (exclude draft/cancelled/void; period on created_at; null created_at excluded for period modes)
- PHPUnit feature tests for multi-business + period edge + 403 for wrong business_id
```
