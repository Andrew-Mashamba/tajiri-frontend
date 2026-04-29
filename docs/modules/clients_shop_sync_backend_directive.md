# Clients-Shop Sync Backend Directive

## Objective

Implement a reliable backend integration so that:

1. Any buyer who purchases from a seller is automatically created/linked as a client.
2. The client is attached to the **correct business** in a multi-business setup.
3. Sync is idempotent and auditable.

This directive is a focused add-on to:
- `docs/modules/clients_backend_directive.md`
- `docs/modules/clients_user_journeys.md`

---

## Current Frontend Context

Frontend currently performs a best-effort sync in `ClientsPage` by reading seller orders and creating customers in the selected business. This is not sufficient for production because:

- It runs only when user opens clients tab.
- It cannot reliably infer `seller_business_id` from current order payload.
- It lacks server-grade idempotency guarantees.

Backend must own the canonical auto-sync.

---

## Required Data Contract Changes

## 1) Shop Order -> Business Mapping

Ensure each order has explicit business ownership:

- `seller_business_id` (required)
- `buyer_user_id` (required)
- buyer identity fields (phone/name/email) resolvable

If legacy rows miss `seller_business_id`, add backfill strategy.

## 2) Customer Source Metadata

For auto-created customers, persist:

- `source_module = "shop"`
- `source_order_id`
- `source_order_number`
- `source_synced_at`

Recommended:
- `source_external_ref` unique index candidate.

---

## Auto-Sync Trigger Rules

Trigger client sync server-side on order lifecycle events:

- minimum: `confirmed`
- recommended: on transition to `paid`/`completed` (business policy decision)

Event handler:

1. Resolve `seller_business_id`.
2. Resolve buyer profile fields.
3. Upsert customer in `user_business_customers`.
4. Attach source metadata.
5. Write audit log row.

---

## Idempotency Rules

Must prevent duplicate customers from retries/replays.

Priority matching:

1. `(business_id, buyer_user_id)` if stored.
2. `(business_id, normalized_phone)` when phone available.
3. Fallback `(business_id, normalized_name)` with caution.

Behavior:

- if existing match found -> update enrichment fields only.
- if no match -> create new customer.

---

## API Endpoints

## A) Manual/repair sync endpoint

`POST /api/business/{businessId}/clients/sync-from-shop`

Purpose:
- backfill old orders
- recover from failed async jobs
- support explicit admin/user action

Body:

```json
{
  "user_id": 123,
  "from_order_id": 1000,
  "to_order_id": 2000,
  "from_date": "2026-01-01",
  "to_date": "2026-12-31",
  "dry_run": false
}
```

Response:

```json
{
  "success": true,
  "message": "Sync complete",
  "data": {
    "scanned_orders": 320,
    "created_customers": 42,
    "updated_customers": 78,
    "skipped": 200,
    "errors": 0
  }
}
```

## B) Optional status endpoint

`GET /api/business/{businessId}/clients/sync-from-shop/status`

Returns latest run summary and last processed checkpoint.

---

## Customers API Enhancements

Extend existing customer endpoints to support source filtering:

- `GET /api/business/{businessId}/customers?source=shop`
- `GET /api/business/{businessId}/customers?tag=VIP&source=shop`

This enables frontend to show “Imported from Shop” segments.

---

## Validation & Security

- Auth required (`auth:sanctum`).
- `user_id` (if supplied) must equal authenticated actor.
- Actor must own `businessId`.
- Order rows used for sync must belong to same `businessId`.

Failure codes:

- `FORBIDDEN_OWNER_MISMATCH`
- `VALIDATION_ERROR`
- `NOT_FOUND`
- `SYNC_CONFLICT`

---

## Observability

Add structured logs and audit rows for each sync run:

- `business_id`
- actor user id
- trigger type (`order_event`, `manual_sync`, `retry`)
- counts (created/updated/skipped/errors)
- duration
- request id

Recommended metrics:

- `clients_shop_sync_runs_total`
- `clients_shop_sync_customers_created_total`
- `clients_shop_sync_failures_total`
- `clients_shop_sync_duration_ms`

---

## Migration / Rollout Plan

1. Add schema fields/indexes.
2. Implement server-side sync job/listener.
3. Add manual sync endpoint.
4. Backfill historic orders by business batches.
5. Enable source filter on customers list.
6. Remove dependency on frontend-tab-triggered sync over time.

---

## Definition of Done

- New shop orders auto-create/update clients under the correct business.
- No duplicate clients from repeated events/retries.
- Multi-business sellers sync only into matching business.
- Manual sync endpoint works for backfill and returns summary stats.
- Source metadata is queryable (`source=shop`).
- Audit logs and metrics are visible for support/ops.

