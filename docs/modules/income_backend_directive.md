# Income (business net) Backend Directive

## Objective

Provide a **single read model** for **business net income** in the Flutter app (`lib/income/`): **collected invoice payments** (eligible invoices, period on issue date) **minus** **expenses** (period on expense `date` / `created_at`), across **all businesses** the profile owns — same ownership model as [revenue_backend_directive.md](./revenue_backend_directive.md) and `BizTabWrapper` / `user_businesses`.

The UI: **`IncomeOverviewPage`** (portfolio) and **`BusinessIncomePage`** (per `business_id`), mirroring the revenue module pattern.

**Non-goals for v1:** replacing `business_invoices` / expenses tables; this is a **read aggregation** endpoint.

---

## Problem statement (current / fallback client)

Without the endpoint, the client calls **`GET /business/{id}/invoices`** and **`GET /business/{id}/expenses`** per business and aggregates in Dart (`IncomeSummaryService.computeFromInvoicesAndExpenses`), duplicating rules and costing N round-trips.

---

## Implementation status

### Laravel (backend)

Implemented: **`GET /api/business/income-summary`** (Sanctum, `ResolvesUserProfileFromSanctumUser`), **`IncomeSummaryService`** (read model: two aggregated subqueries for invoices + expenses, `LEFT JOIN` to owned businesses — no N+1), **`IncomeSummaryController`**, route in **`routes/api.php`**, cache TTL from **`config('revenue.summary_cache_ttl_seconds')`** (same as revenue summary), migration **`2026_04_17_250000_user_business_expenses_business_date_index`** on **`user_business_expenses`**, SQLite test schema **`2099_01_06_000000_income_summary_expenses_test_schema`**, **`tests/Feature/IncomeSummaryApiTest.php`**.

**Aggregation (server):** Invoice leg matches **`RevenueSummaryService::EXCLUDED_INVOICE_STATUSES`**; collected = **`SUM(amount_paid)`** with **`created_at`** window (non-`all` excludes `created_at IS NULL`). Expenses: **`SUM(amount)`** with effective time **COALESCE(date at start of day, created_at)**; non-`all` requires **`date IS NOT NULL OR created_at IS NOT NULL`** plus range filter. **`by_business`:** all owned businesses, sorted by **`net_income` DESC**, then **`business_id` DESC** tie-break. **`totals`:** sum of per-business figures (2-decimal rounding).

### Flutter (frontend)

**`IncomeSummaryService`** calls **`GET {ApiConfig.baseUrl}/business/income-summary`** with **`basis=invoice_expense`** and **`period`**. **404** → parallel **`getInvoices` / `getExpenses`** per business (or single business). Fallback expense period uses **start-of-day** on **`Expense.date`** when present, else **`createdAt`**, aligned with the server rule above.

---

## 1) API envelope

Same Tajiri JSON envelope as revenue/transactions: `success`, `data`, `meta`; validation `success: false`, `code`, `message`, `errors`.

**Auth:** `Authorization: Bearer {token}` (`auth:sanctum`), profile id resolution identical to other business APIs.

---

## 2) Endpoint

### `GET /api/business/income-summary`

**Do not use `GET /api/income/summary` for this feature** — the Flutter app already uses that path for **personal / budget** income (`lib/services/income_service.dart`, `IncomeService.getIncomeSummary`) with different `period` semantics (`daily` / `weekly` / `monthly`). The business net-income read model **must** live on a separate route to avoid collisions.

**Query parameters:**

| Parameter | Type | Required | Description |
|-----------|------|----------|-------------|
| `period` | string | no | `all` (default) \| `this_month` \| `last_30_days` \| `custom` |
| `date_from`, `date_to` | Y-m-d | if `period=custom` | Inclusive range; same timezone policy as [revenue_backend_directive.md](./revenue_backend_directive.md). |
| `basis` | string | no | `invoice_expense` (**default and only** accepted value; other values → validation error). |
| `business_id` | int | no | When set, scope to one business; **`403`** if not owned. |

**Response `data` (contract for Flutter):**

```json
{
  "currency": "TZS",
  "period": { "preset": "this_month", "date_from": null, "date_to": null },
  "basis": "invoice_expense",
  "totals": {
    "collected_revenue": "0.00",
    "total_expenses": "0.00",
    "net_income": "0.00"
  },
  "by_business": [
    {
      "business_id": 1,
      "business_name": "Acme Salon",
      "collected_revenue": "0.00",
      "total_expenses": "0.00",
      "net_income": "0.00"
    }
  ]
}
```

**`meta` (implemented):** `computed_at` (UTC ISO8601), `cache_ttl_seconds`, `timezone` (same shape as revenue summary). Flutter may ignore `meta` for v1 UI.

**`by_business`:** Sorted by **`net_income` DESC**, then **`business_id` DESC** tie-break. All owned businesses included (zeros when no activity).

**Semantics (must match Flutter `IncomeSummaryService` fallback):**

- **Invoices:** Same excluded statuses as **`RevenueSummaryService::EXCLUDED_INVOICE_STATUSES`**. **Collected** = sum of **`amount_paid`** with **`created_at`** in range (non-`all` excludes `created_at IS NULL`).
- **Expenses:** **`SUM(amount)`** with effective timestamp **COALESCE(date at start of day, created_at)** in range; non-`all`: exclude rows where **`date` and `created_at` are both unusable** (see server query / tests).

**`totals`:** Should equal the sum of `by_business` rows (after rounding policy).

---

## 3) Performance

- Implemented: two aggregated subqueries (invoices + expenses) joined to **`user_businesses`** — no invoice×expense cross join, no N+1.
- Index: **`user_business_expenses`** **`(user_business_id, date)`** (migration `2026_04_17_250000_…`). Invoice indexes per revenue summary migration set.

---

## 4) Flutter integration (implemented)

- **`IncomeSummaryService.loadPortfolio`** → **`GET /api/business/income-summary`** with `basis=invoice_expense` and `period`; **404** → parallel invoice + expense fetches per business.
- **`IncomeSummaryService.loadBusinessTotals`** → same URL with **`business_id`**; **404** → legacy two-fetch for that id.
- **`IncomeOverviewPage`** / **`BusinessIncomePage`** under `lib/income/`; period enum **`RevenuePeriodScope`** shared with revenue for identical presets.

---

## 5) Acceptance checklist (backend)

- [x] `GET /api/business/income-summary` returns `totals` + `by_business` for the authenticated owner in one efficient query.
- [x] Invoice exclusions and period rules match revenue summary for the invoice leg.
- [x] Expense effective-time and range rules match §2 (see `IncomeSummaryService` / tests).
- [x] **`403`** for non-owned `business_id`.
- [x] Feature tests: portfolio + sort, `this_month` + draft exclusion + expense boundary, custom validation + 403, `business_id` scope (`tests/Feature/IncomeSummaryApiTest.php`).

---

## 6) References (frontend)

- `lib/income/services/income_summary_service.dart`
- `lib/income/pages/income_overview_page.dart`
- `lib/income/pages/business_income_page.dart`
- `lib/revenue/services/revenue_service.dart` — `invoiceMatchesPeriod` / countable invoice rules
- `lib/business/services/business_service.dart` — `getInvoices`, `getExpenses`

---

## 7) Suggested prompt for `POST /api/ai/ask`

```
[Type: implement]
[Context: TAJIRI Flutter business income — docs/modules/income_backend_directive.md]

Implement GET /api/business/income-summary (NOT /api/income/summary — reserved for budget IncomeService).
Sanctum auth, same business ownership as revenue summary. Query: period, date_from/date_to, basis=invoice_expense, optional business_id.
Response: data.totals (collected_revenue, total_expenses, net_income), data.by_business[], currency TZS, string decimals OK.
Invoice status exclusions and period on created_at must match revenue directive; expenses by date/created_at per income_backend_directive.md §2.
PHPUnit feature tests: portfolio, scoped business_id, 403 wrong business, period edge.
```
