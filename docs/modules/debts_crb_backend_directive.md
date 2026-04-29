# TAJIRI Debts — Credit Reference Bureau (CRB / Creditinfo) Sync — Backend Implementation Directive

## Goal

Allow each business to **keep manual debts** (existing `POST /business/debts` flow) while **importing or refreshing facility balances** from the **Credit Reference Bureau** feed exposed via **Creditinfo Tanzania** (MultiConnector SOAP → parsed JSON as in `docs/crb.md`). The Flutter app calls a single **authenticated JSON endpoint**; **CRB credentials never ship to mobile clients**.

> **Naming:** If product copy referred to “BRELA”, that is a different registry (business registration). This feature is **CRB / Creditinfo** credit-report data, documented in `docs/crb.md`.

## Business Outcome

- Shopkeepers see **bank and non-bank credit facilities** alongside **informal customer debts** they enter by hand.
- **CRB-sourced rows** are clearly tagged (`source: crb`) and can be reconciled locally with **Record Payment** (same as manual debts).
- **Idempotent sync** avoids duplicate rows when the user taps “Sync CRB” repeatedly.

## Server Details

| Item | Value |
|------|-------|
| Framework | Laravel 12, PHP 8.3 |
| API base | `https://tajiri.zimasystems.com/api` (see `lib/config/api_config.dart`) |
| Auth | `auth:sanctum` (Bearer token) |
| Portfolio controller | `CreditBureauController` (`activeLoansOverview`, `syncActiveLoans`) |
| Debt sync service | `CrbDebtSyncService` — `fetchReportData`, `sync` (single business), `syncPersonal`, `syncPortfolio` |
| Routes | `routes/api.php` |

### Implemented routes (portfolio hub)

| Method | Path | Controller |
|--------|------|------------|
| `GET` | `/api/credit-bureau/active-loans-overview` | `CreditBureauController@activeLoansOverview` |
| `POST` | `/api/credit-bureau/active-loans/sync` | `CreditBureauController@syncActiveLoans` |

Per-business sync (unchanged for clients that only call this):

| Method | Path | Notes |
|--------|------|--------|
| `POST` | `/api/business/{businessId}/debts/sync-crb` | One Creditinfo fetch per request; same contract mapping as portfolio business leg |

## Frontend Contract (already implemented)

| Concern | Location |
|---------|----------|
| Model | `lib/business/models/business_models.dart` — `Debt.source`, `Debt.externalRef` |
| Loan DTO | `lib/debts/models/loans_overview_models.dart` — `CrbActiveLoan`, `LoansOverview` |
| Portfolio | `BusinessService.getActiveLoansOverview` → `GET /credit-bureau/active-loans-overview?user_id={profileId}` (Bearer optional; fallback needs auth) |
| Sync all | `BusinessService.syncActiveLoansFromCrb` → `POST /credit-bureau/active-loans/sync` (fallback: per-business `sync-crb`) |
| Hub UI | `lib/debts/pages/debts_overview_page.dart` — personal + each business’s active bureau loans; drill-down to `DebtsPage` |
| Per-business | `lib/debts/pages/debts_page.dart` — “Sync CRB” for one business; manual debts |

**List debts** must return `source` and `external_ref` on each debt so the app can show the **CRB** badge and hide **Remind** for bureau-backed rows.

---

## Security & Configuration

1. **Never** embed CRB username, password, strategy ID, or endpoint URLs in the Flutter app or in committed docs. If `docs/crb.md` contains real credentials, **rotate them** in Creditinfo and store new values only in server `.env`.
2. Server-side only:
   - `CRB_IDM_USERNAME`
   - `CRB_IDM_PASSWORD`
   - `CRB_STRATEGY_ID` (UUID, e.g. `2e1a9e93-0489-40e7-8fc2-185a21ae171a` for staging)
   - `CRB_ENDPOINT` (WSDL/SOAP URL)
   - `CRB_SOAP_ACTION` (see `docs/crb.md`)
3. Log **request id / MessageId** for support, not raw national ID in client-visible errors.

---

## Subject Identity (who is queried?)

The SOAP request in `docs/crb.md` uses **individual** fields: `FirstName`, `FullName`, `DateOfBirth`, `IdNumbers` (NIN type + number), etc.

**Directive:** Resolve the **data subject** for the business’s CRB pull from stored profile data, for example:

- Primary: **business owner / director** linked to `user_businesses` (or equivalent) with **verified NIN + DOB + legal name** on file.
- If the business is not an individual, define a single **authorized signatory** record used for CRB consent (document the chosen rule in API docs).

If required fields are missing, return `422` with a clear `message` (e.g. “Add national ID and date of birth in business profile to sync CRB debts”).

---

## Creditinfo Integration (server)

### SOAP request

Reuse the envelope pattern in `docs/crb.md`:

- WS-Security UsernameToken with env credentials.
- `MessageId` UUID per request.
- `Strategy.Id` from env.
- `Consent` must be `true` where regulations require stored consent — if the app already captures consent on credit report, **reuse** that audit trail for sync.

### Response handling

After SOAP, normalize to the JSON structure illustrated in `docs/crb.md` (nested `TzaCb5_data`, `ContractOverview`, etc.).

**Primary debt list:** `TzaCb5_data.ContractOverview.ContractList.Contract`

Each `Contract` object includes (examples from the doc):

| Field | Use |
|-------|-----|
| `Sector` | Creditor sector label (e.g. `Banks`, `Others`) |
| `StartDate` | Facility start (ISO string) |
| `PastDueDays` | Arrears age |
| `TotalAmount.Value` | Facility size (TZS) |
| `PastDueAmount.Value` | Amount past due (TZS) |
| `RoleOfClient` | Expect `MainDebtor` for primary exposure |
| `ContractStatus` | e.g. `GrantedAndActivated` |
| `TypeOfContract` | e.g. `Installment`, `NotSpecified` |
| `PhaseOfContract` | e.g. `Open` |

**Outstanding for UI:** Prefer **`PastDueAmount`** when representing “what hurts now”; if zero, use **`TotalAmount`** for open facilities, or follow product policy (document in response `sync_policy` field).

---

## Database

**Portfolio migration (example):** `database/migrations/2026_04_17_270000_credit_bureau_portfolio.php`

### `user_business_debts` (business debts)

- `source` — `manual` \| `crb`
- `external_ref` — idempotent key for CRB upserts
- **`crb_meta`** — JSON copy of the parsed Creditinfo contract (overview filtering + display; use to exclude paid/closed phases when present)

### `user_profile_crb_loans` (personal bureau facilities)

Stores **personal** active facilities aligned with the Flutter `CrbActiveLoan` DTO (`lender_label`, amounts, `past_due_days`, etc.). Overview **`personal[]`** is driven by rows where **`is_active = true`** (open/active contracts from the last personal sync).

### Audit

- **`profile_crb_syncs`** — personal CRB sync audit trail
- **`business_crb_syncs`** (or equivalent) — per-business sync timestamps; **`data.synced_at`** on the overview is the **latest** of profile vs business sync times (or `null` if never synced)

**Rules**

- `source = 'manual'` for user-created debts (default).
- `source = 'crb'` for imported rows; **do not** require `customer_id` if not linked to a CRM customer.
- **Idempotency:** `external_ref` = deterministic hash from stable contract keys (see Creditinfo XML); **`crb_meta`** holds the full parsed contract for filtering and legacy compatibility.

---

## API

### `GET /credit-bureau/active-loans-overview` (implemented)

**Query:** **`user_id`** — profile / user id (required for the Flutter client).

**Auth:** Bearer is **optional** for this GET; the app sends `Authorization` when a token exists, otherwise only `Accept` / `Content-Type` headers.

**Behaviour (server):**

- **`data.personal`:** Rows from **`user_profile_crb_loans`** with **`is_active = true`** (open/active contracts from the last personal sync).
- **`data.businesses[]`:** Each owned business with **`loans`** built from **`user_business_debts`** where **`source = 'crb'`**, excluding paid/closed phases when **`crb_meta`** is present; **legacy** CRB rows **without** `crb_meta` still appear (fallback).
- **`data.synced_at`:** Latest timestamp among **`profile_crb_syncs`** and **`business_crb_syncs`** (or `null` if never synced).

**Success (200):**

```json
{
  "success": true,
  "data": {
    "synced_at": "2026-04-17T12:00:00Z",
    "personal": [
      {
        "lender_label": "Banks — Installment",
        "sector": "Banks",
        "type_of_contract": "Installment",
        "phase_of_contract": "Open",
        "contract_status": "GrantedAndActivated",
        "total_amount": 29495,
        "past_due_amount": 33000,
        "past_due_days": 1,
        "start_date": "2019-07-21T21:00:00Z",
        "description": "Optional human-readable line",
        "external_ref": "…"
      }
    ],
    "businesses": [
      {
        "business_id": 12,
        "business_name": "My Shop",
        "loans": [...]
      }
    ]
  }
}
```

**Flutter:** If this route returns **404**, the app **falls back** to composing the overview from **`GET /business/{id}/debts`** (CRB rows only) per business — **no personal list** in that mode.

---

### `POST /credit-bureau/active-loans/sync` (implemented)

**Auth:** Bearer (`auth:sanctum`).

**Behaviour (server):**

1. **Single** Creditinfo SOAP call via **`CrbDebtSyncService::fetchReportData`**.
2. **`syncPortfolio`:** upsert **personal** (`user_profile_crb_loans` + **`profile_crb_syncs`** audit) and **each** owned business’s CRB debts in **`user_business_debts`** (same contract list as the per-business sync path).

**Errors / limits:**

| Code | When |
|------|------|
| 422 | KYC rules — NIN, DOB, name (same as other CRB flows) |
| 429 | Rate limit key **`crb-portfolio-sync:{profileId}`** (uses existing `crb.sync_*` config) |

**Success (200/201):** — response shape may include counts per personal/business legs (align with `CreditBureauController`).

**Flutter:** If **404**, falls back to **`POST /business/{businessId}/debts/sync-crb`** for **each** business (no personal sync until aggregate route exists on that environment).

---

### `POST /business/{businessId}/debts/sync-crb`

**Auth:** Bearer token; user must own the business.

**Body:** empty JSON `{}` acceptable.

**Success response (200/201):**

```json
{
  "success": true,
  "message": "Imported 2 facilities, updated 1.",
  "data": {
    "imported": 2,
    "updated": 1,
    "unchanged": 0,
    "report_reference": "4401221-10051217",
    "synced_at": "2026-04-17T12:00:00Z"
  }
}
```

**Error examples**

| Code | When |
|------|------|
| 401 | Invalid token |
| 403 | Not owner of business |
| 422 | Missing NIN/DOB/name for CRB query |
| 502 / 503 | Creditinfo timeout or SOAP fault |
| 429 | Rate limit (per user or per business per day) |

**Side effects**

- Upsert `source = crb` rows.
- **Do not** delete manual debts.
- Optional: soft-delete CRB rows that disappeared from latest report (`PhaseOfContract` closed) — if implemented, set `status` to `paid` or a dedicated `closed_externally` with `paid_amount = amount` **or** hide from default list; document the rule.

### `GET /business/{businessId}/debts` (existing)

Ensure each row includes:

```json
{
  "id": 1,
  "business_id": 12,
  "customer_id": null,
  "customer_name": "Banks — Installment",
  "customer_phone": null,
  "amount": 33000.0,
  "paid_amount": 0,
  "description": "CRB facility · Sector: Banks · Past due days: 1 · Phase: Open",
  "due_date": null,
  "status": "overdue",
  "created_at": "...",
  "source": "crb",
  "external_ref": "a1b2c3...",
  "crb_meta": { "PhaseOfContract": "Open", "Sector": "Banks" }
}
```

(`crb_meta` is optional on legacy rows; server uses it to filter overview when present.)

### `GET /business/{businessId}/debts/summary` (existing)

Include CRB rows in `total_outstanding`, `overdue_count`, etc., consistent with list filters.

### `POST /business/debts` (manual create)

Force `source = 'manual'` server-side; ignore client-supplied `source`.

### `POST /business/debts/{id}/pay`

Allowed for `crb` rows (local reconciliation). Do not send payments to Creditinfo from this endpoint unless a separate bank integration exists.

---

## Compliance & Product Copy

- Reuse or mirror consent language from **Credit Report** (`CreditReportPage`) — user must understand **fees** and **credit inquiry** implications.
- **Audit:** `profile_crb_syncs` (personal) and business-side CRB sync logs (`business_crb_syncs` or equivalent).

## Backend tests (reference)

- `tests/Feature/CreditBureauApiTest.php`
- `tests/Database/Migrations/2099_01_08_000000_credit_bureau_portfolio_test_schema.php`

---

## Testing Checklist

1. Business with full KYC → sync returns `imported` > 0 when Creditinfo returns contracts.
2. Second sync → same `external_ref` updates amounts, no duplicate rows.
3. Manual debt unchanged after sync.
4. Flutter: `DebtsPage` shows **CRB** badge and no **Remind** on CRB rows.
5. `DebtsOverviewPage` shows **personal** loans + **per-business** loans; **Refresh CRB** hits **`POST /credit-bureau/active-loans/sync`** (portfolio); older builds fall back to per-business **`sync-crb`** if the aggregate route returns **404**.

---

## References

- `docs/crb.md` — SOAP envelope, sample JSON (`ContractOverview`, `PastDueInformation`, etc.)
- `lib/debts/pages/debts_overview_page.dart` — portfolio hub (personal + businesses)
- `lib/debts/pages/debts_page.dart` — per-business manual + CRB debts
- `lib/business/services/business_service.dart` — `getActiveLoansOverview`, `syncActiveLoansFromCrb`, `syncDebtsFromCrb`
