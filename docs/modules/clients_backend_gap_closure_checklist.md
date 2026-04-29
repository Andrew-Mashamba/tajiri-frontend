# Clients Backend Gap-Closure Checklist

This checklist defines backend work required after the latest frontend updates to Clients, Client Profile, and Shop->Client sync wiring.

## 1) Shop -> Client Sync Endpoint

- [ ] Add endpoint: `POST /business/{businessId}/clients/sync-from-shop`
- [ ] Accept payload:
  - `user_id` (required)
  - `from_order_id` (optional)
  - `to_order_id` (optional)
  - `from_date` (optional, `YYYY-MM-DD`)
  - `to_date` (optional, `YYYY-MM-DD`)
  - `dry_run` (optional, boolean)
- [ ] Return summary payload:
  - `created_count`
  - `updated_count`
  - `skipped_count`
  - `failed_count`
  - `failures[]` with machine-readable reason codes

## 2) Sync Rules (Idempotent + Business Safe)

- [ ] Enforce business ownership isolation (`seller_business_id` / equivalent).
- [ ] Ensure idempotency (same order cannot create duplicate customers).
- [ ] Dedup strategy (priority):
  1. Existing customer linked to buyer user id
  2. Phone exact/normalized match
  3. Email exact match
  4. Name fallback (safe mode)
- [ ] Persist source metadata:
  - `source = shop_order_auto_client`
  - `source_order_id`
  - `source_order_number`
  - `synced_at`

## 3) Customer Write Contract (Structured Fields)

- [ ] Ensure create/update customer APIs accept and persist:
  - `tags: string[]`
  - `date_of_birth: YYYY-MM-DD`
  - `anniversary_date: YYYY-MM-DD`
- [ ] Return those fields in customer list/detail responses.
- [ ] Keep backward compatibility with `notes` metadata while migrating.

## 4) Client Notes APIs (Server Backed)

- [ ] `GET /business/clients/{clientId}/notes?user_id=...`
- [ ] `POST /business/clients/{clientId}/notes`
- [ ] `PUT /business/clients/notes/{noteId}`
- [ ] `DELETE /business/clients/notes/{noteId}?user_id=...`
- [ ] Canonical response fields:
  - `id`
  - `client_id`
  - `type`
  - `note`
  - `created_at`
  - `updated_at`
  - `created_by`

## 5) Client Reminders APIs (Server Backed)

- [ ] `GET /business/clients/{clientId}/reminders?user_id=...&status=...`
- [ ] `POST /business/clients/{clientId}/reminders`
- [ ] `PUT /business/clients/reminders/{reminderId}`
- [ ] `DELETE /business/clients/reminders/{reminderId}?user_id=...`
- [ ] Canonical response fields:
  - `id`
  - `client_id`
  - `title`
  - `message`
  - `remind_at`
  - `status` (`pending|sent|done|cancelled|overdue`)
  - `created_at`
  - `updated_at`

## 6) Statements Date-Range Contract

- [ ] Ensure statement endpoint applies `from` and `to` exactly.
- [ ] Include opening balance and running-balance-safe ordering.
- [ ] Use stable timezone handling (explicit server timezone or UTC normalization).

## 7) Validation and Error Contract

- [ ] Standardize validation errors (422):
  - `message`
  - `errors: { field: [messages...] }`
- [ ] Standardize authz/authn errors (401/403) across all client endpoints.
- [ ] Add machine-readable `code` in error responses for sync/note/reminder failures.

## 8) Background Jobs and Observability

- [ ] Add scheduled reminders dispatch job.
- [ ] Add overdue reminder escalation job/state update.
- [ ] Add sync run logs per business:
  - started/ended timestamps
  - counts
  - failure reasons
- [ ] Add basic metrics/monitoring hooks for sync and reminders.

## 9) Rollout / Migration

- [ ] Backfill/migrate customer tags and dates from legacy `notes` metadata.
- [ ] Add feature flag for server-side sync endpoint if needed.
- [ ] Validate on UAT with multi-business users before production release.

## 10) UAT Acceptance Checklist

- [ ] Shop buyer appears under correct business client list after sync.
- [ ] Re-running sync does not create duplicates.
- [ ] Client profile notes persist across devices/sessions.
- [ ] Client reminders persist and can be edited/deleted.
- [ ] Statement reflects selected date range from frontend.
- [ ] Tags/DOB/anniversary update and round-trip in API responses.
