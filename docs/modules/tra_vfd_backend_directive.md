# TAJIRI TRA VFD - Full Backend Implementation Directive

**Module location:** `lib/vfd/` (standalone module, wired to invoice/business events)  
**Source journeys:** `docs/modules/tra_vfd_user_journeys.md`  
**Frontend callers:** `lib/business/services/business_service.dart`, `lib/vfd/pages/vfd_receipts_page.dart`

---

## 1) Objective

Deliver a production-grade Laravel backend for TRA VFD that fully supports all six user journeys:

1. Invoice full-payment -> auto fiscal receipt
2. VFD receipt view/share/verification
3. Daily Z report close
4. Failed queue & retry center
5. Compliance dashboard & audit export
6. VFD settings, credential rotation, safety controls

This backend must expose stable contracts already consumed by frontend and preserve TRA compliance guarantees (immutable payloads, monotonic counters, auditable retries).

---

## 2) Frontend Contract (Must Match Exactly)

All endpoints must return:

```json
{ "success": true|false, "data": ..., "message": "..." }
```

### Existing/required VFD endpoints in use

- `GET /api/business/{businessId}/vfd?user_id={userId}`
- `POST /api/business/{businessId}/vfd/register`
- `GET /api/business/{businessId}/fiscal-receipts?user_id={userId}[&page={n}]`
- `POST /api/business/invoices/{invoiceId}/fiscal-receipt`

### Operations-center endpoints now used by frontend

- `GET /api/business/{businessId}/vfd/outbox?user_id={userId}[&status=pending|sending|ack_success|ack_failed|network_retry|dead_letter]`
- `POST /api/business/vfd/outbox/{outboxId}/retry` with `{"user_id":123}`
- `POST /api/business/{businessId}/vfd/outbox/retry-all` with `{"user_id":123}`
- `POST /api/business/{businessId}/vfd/z-report` with `{"user_id":123,"business_date":"YYYY-MM-DD"}`
- `GET /api/business/{businessId}/vfd/z-reports?user_id={userId}[&from_date=YYYY-MM-DD&to_date=YYYY-MM-DD]`
- `GET /api/business/{businessId}/vfd/compliance?user_id={userId}&period=today|7d|30d[&from_date=...&to_date=...]`
- `POST /api/business/{businessId}/vfd/compliance/export`
- `GET /api/business/{businessId}/vfd/settings?user_id={userId}`
- `PUT /api/business/{businessId}/vfd/settings` with `{"user_id":123,...}`
- `POST /api/business/{businessId}/vfd/credentials/rotate` with `{"user_id":123,...}`

### Optional but strongly recommended

- `POST /api/business/{businessId}/vfd/token/refresh` with `{"user_id":123}`

---

## 3) Data Model and Migrations

## 3.1 `business_vfd_configs`

One row per business:

- `id`, `business_id (unique FK)`, `tin`, `vrn`, `serial_number`
- `registration_id`, `certificate_key`, `receipt_code`, `routing_key`
- `username`, `password_encrypted`, `token_value`, `token_expires_at`
- `environment` enum(`test`,`production`) default `test`
- `max_retry_attempts` int default 10
- `backoff_schedule` string default `1,3,10,30,120`
- `alerts_enabled` bool default true
- `block_unsafe_retries` bool default true
- `require_admin_confirmation` bool default true
- `current_gc` bigint default 0
- `current_rctnum` bigint default 0
- `current_dc` int default 0
- `current_dc_date` date nullable
- `is_active` bool default false
- `last_ack_code`, `last_ack_message`, `registered_at`, `last_synced_at`
- `created_by`, `updated_by` nullable user IDs for audit
- timestamps

Indexes:

- unique(`business_id`)
- index(`tin`)
- index(`is_active`)

## 3.2 `business_fiscal_receipts`

- `id`, `business_id`, `invoice_id (unique)`
- `receipt_number` (RCTNUM)
- `fiscal_code` (RCTVNUM or verification code bundle)
- `gc`, `dc`, `znum` (for exact Journey 2 display)
- `qr_code`, `verification_url`
- `tin`, `vrn`
- `total_amount`, `vat_amount`
- `issued_at`
- `ack_code`, `ack_message`
- `raw_request_xml`, `raw_response_xml`
- timestamps

Indexes:

- unique(`invoice_id`)
- index(`business_id`,`issued_at`)
- index(`business_id`,`receipt_number`)

## 3.3 `business_vfd_outbox`

- `id`, `business_id`, `invoice_id` nullable
- `payload_type` enum(`receipt`,`z_report`)
- `status` enum(`pending`,`sending`,`ack_success`,`ack_failed`,`network_retry`,`dead_letter`)
- `sequence_no` bigint
- `request_xml` longText (immutable after first send)
- `request_hash` string(64)
- `attempt_count` int default 0
- `last_error` text nullable
- `ack_code`, `ack_message`
- `next_retry_at`, `first_attempted_at`, `last_attempted_at`, `resolved_at`
- `retry_logs` json nullable (attempt snapshots for queue detail UI)
- timestamps

Indexes:

- index(`business_id`,`status`,`next_retry_at`)
- unique(`business_id`,`sequence_no`)
- index(`invoice_id`)

## 3.4 `business_vfd_z_reports`

- `id`, `business_id`, `business_date`, `znum`
- `total_daily_amount`, `vat_total`, `receipt_count`
- `payment_breakdown_json`, `void_count`, `correction_count`
- `status`, `ack_code`, `ack_message`
- `raw_request_xml`, `raw_response_xml`
- `submitted_at`
- timestamps

Unique:

- unique(`business_id`,`business_date`)

## 3.5 `business_vfd_audit_logs`

- `id`, `business_id`, `user_id`, `action`, `before_json`, `after_json`, `metadata_json`, timestamps

Used for settings changes, rotate credentials, manual retries.

---

## 4) Endpoint Behavior Specification

## 4.1 Register VFD

`POST /api/business/{businessId}/vfd/register`

Validation:

- `user_id`: required (must match owned business context)
- `tin`: required, digits, len 9
- `serial_number`: required, min 4
- `vrn`: nullable
- `environment`: optional (`test|production`)

Flow:

1. Ownership check (`user_id` from auth and optional request body).
2. Build signed registration XML.
3. Call TRA registration endpoint based on config environment.
4. Persist registration/certificate fields.
5. Initialize counters and activate config.
6. Return normalized `VfdConfig`.

## 4.2 Issue fiscal receipt

`POST /api/business/invoices/{invoiceId}/fiscal-receipt`

Rules:

- Invoice belongs to requester business.
- Invoice fully settled.
- Idempotent by `invoice_id`.

Flow:

1. Load active VFD config.
2. Refresh token if expired.
3. Atomically reserve counters (`GC`, `RCTNUM`, `DC` reset by date).
4. Create immutable request XML and outbox row.
5. Submit immediately or queue job.
6. On success:
   - insert `business_fiscal_receipts` with `gc/dc/znum` persisted
   - update invoice `vfd_receipt_number`, `vfd_receipt_url`
   - outbox -> `ack_success`
7. On failure:
   - outbox -> `ack_failed` or `network_retry`

## 4.3 List fiscal receipts

`GET /api/business/{businessId}/fiscal-receipts`

Return all fields needed by Journey 2, including:

- `receipt_number`, `fiscal_code`, `gc`, `dc`, `znum`, `verification_url`, `issued_at`
- `gc/dc/znum` may be null on legacy rows until backfill is complete

## 4.4 Outbox list

`GET /api/business/{businessId}/vfd/outbox`

Supports `status` filter. Each item should include:

- `id`, `payload_type`, `status`, `attempt_count`, `last_error`, `next_retry_at`, `request_hash`, `retry_logs`
- `user_id` must be accepted and enforced on this endpoint

## 4.5 Retry item

`POST /api/business/vfd/outbox/{outboxId}/retry`

Must use stored immutable XML and original counters/timestamp context.
No `confirmed` flag is required for current frontend flow.

## 4.6 Retry all eligible

`POST /api/business/{businessId}/vfd/outbox/retry-all`

Retry all `ack_failed` or `network_retry` items that pass guardrails.
Guardrail behavior (must match handoff):

- if `block_unsafe_retries=true`: retry only `network_retry` and `pending`
- if `block_unsafe_retries=false`: allow `ack_failed` as well

## 4.7 Z report submit

`POST /api/business/{businessId}/vfd/z-report`

Request:

```json
{ "business_date": "2026-04-17" }
```

Flow:

1. Build draft totals for date:
   - `total_daily_amount`
   - `payment_breakdown`
   - `vat_total`
   - `void_count`, `correction_count`
2. Create/lock outbox row (`payload_type=z_report`).
3. Submit signed XML.
4. Persist `business_vfd_z_reports` row with status + ACK data.

## 4.8 Z report list

`GET /api/business/{businessId}/vfd/z-reports`

Returns rows for history panel with:

- `znum`, `business_date`, `status`, `ack_code`, `ack_message`, `submitted_at`
- endpoint expects `user_id` query parameter

## 4.9 Compliance dashboard

`GET /api/business/{businessId}/vfd/compliance`

Return:

- `compliance_score`
- `pending_count`
- `failed_count`
- `missed_z_reports`
- `token_health`
- `certificate_health`
- `risk_reason` (nullable)
- `period` object/range (`from`,`to`)
- `trend`

## 4.10 Compliance export

`POST /api/business/{businessId}/vfd/compliance/export`

Request:

```json
{
  "format": "pdf|csv",
  "include_detail_logs": true,
  "period": "today|7d|30d"
}
```

Return:

```json
{
  "success": true,
  "data": {
    "download_url": "https://..."
  }
}
```

Deployment note: exported files must be reachable via HTTPS URL (ensure storage symlink/public mapping is configured, equivalent to `storage:link`).

## 4.11 Settings read/update

- `GET /api/business/{businessId}/vfd/settings`
- `PUT /api/business/{businessId}/vfd/settings`

Fields:

- `environment`
- `certificate_serial` (metadata only)
- `certificate_key_reference` (metadata only)
- `max_retry_attempts`
- `backoff_schedule`
- `alerts_enabled`
- `block_unsafe_retries`
- `require_admin_confirmation`

Every update must write audit log entry.

## 4.12 Rotate credentials

`POST /api/business/{businessId}/vfd/credentials/rotate`

Request:

```json
{
  "user_id": 123,
  "environment": "test|production",
  "certificate_serial": "...",
  "certificate_key_reference": "..."
}
```

Flow:

1. Re-validate credentials against TRA token/health check.
2. Persist if valid.
3. Log audit event.

---

## 5) Queue, Retry, and Idempotency Rules

- Immutable XML per outbox row after first send.
- Retry must reuse same `request_xml` and `request_hash`.
- Sequence order per business by `sequence_no ASC`.
- Backoff from config (`backoff_schedule`) with cap + jitter.
- Move to `dead_letter` after `max_retry_attempts`.
- Functional ACK failures do not auto-loop forever.

---

## 6) TRA Compliance Rules

- Signed XML only from backend.
- Headers: `Client: webapi`, routing keys (`vfdrct`, `vfdzreport`).
- Enforce monotonic `GC`, `RCTNUM`.
- Reset `DC` daily.
- `ZNUM` as date-serial standard used by TRA.
- No future timestamps.
- Persist `ack_code` and `ack_message` everywhere relevant.

---

## 7) Security and Audit Requirements

- Encrypt passwords, token values, cert secrets at rest.
- Never return sensitive secrets to frontend.
- Mask secrets in logs.
- Add audit logs for:
  - settings update
  - credential rotation
  - manual retry/retry-all actions
- Require server-side authz checks; do not trust frontend `user_id` blindly.

---

## 8) Observability

Track metrics:

- receipt submit success/failure and latency
- z-report submit success/failure and latency
- outbox backlog counts by status
- retry success by attempt number
- top ACK codes
- settings-change and rotation counts

Add structured logs with correlation IDs:

- invoice_id / outbox_id / business_id

---

## 9) Laravel Implementation Plan

1. Migrations for all VFD tables above.
2. Eloquent models + casts.
3. Service layer:
   - `VfdConfigService`
   - `VfdReceiptService`
   - `VfdOutboxService`
   - `VfdZReportService`
   - `VfdComplianceService`
   - `VfdSettingsService`
4. Controllers and FormRequests for all endpoints.
5. Jobs:
   - `IssueFiscalReceiptJob`
   - `SubmitVfdZReportJob`
   - `ReplayPendingVfdOutboxJob`
6. Scheduler for replay, missed Z detection, compliance snapshots.
7. Policy/authorization per business ownership.
8. Integration tests and staging TRA test validation.

---

## 10) Definition of Done

- [ ] All endpoints in section 2 return expected shapes
- [ ] Frontend journeys 1-6 fully data-backed (no placeholder-only responses)
- [ ] Counter reservation is atomic and tested under concurrency
- [ ] Outbox replay and retry operate with immutable payload guarantee
- [ ] `gc/dc/znum` available in fiscal receipt API for Journey 2 display
- [ ] Z report draft/submit/list flows complete
- [ ] Compliance export returns downloadable artifact URL
- [ ] Settings/rotation changes create audit logs
- [ ] Secrets encrypted and never leaked
- [ ] Staging tests pass against TRA test environment

---

## 11) Practical frontend notes

1. Auth: `user_id` remains required in query/body alongside ownership checks.
2. Secrets: passwords, tokens, and raw cert material are never returned.
3. Receipts: expose `gc/dc/znum` for Journey 2 detail/share UI.
4. Outbox UI: `retry_logs` and `request_hash` must be available for support/debug.
5. Exports: `download_url` should open as normal external HTTPS file.
# TAJIRI TRA VFD — Backend Implementation Directive

**Module location:** `lib/vfd/` (standalone module, wired to invoice/business events)

## Goal

Implement end-to-end TRA VFD setup and fiscalization as a standalone module, wired to business registration and invoice payment events, so TAJIRI can produce legally compliant fiscal receipts in Tanzania.

This directive is written for the backend coding AI and should be implemented in Laravel API used by TAJIRI.

## Journey-Driven Scope (from `docs/modules/tra_vfd_user_journeys.md`)

Backend implementation must cover these user-facing journey features end-to-end:

1. **Invoice full-payment -> auto fiscal receipt**
2. **VFD receipt view/share/verification data**
3. **Daily Z report close**
4. **Failed queue & retry center**
5. **Compliance dashboard & audit export**
6. **VFD settings, credential rotation, and safety controls**

All endpoint, schema, and job decisions below should be traceable to one or more of those six journeys.

---

## Frontend Contract (Already In App)

The Flutter app already calls these endpoints via `lib/business/services/business_service.dart` and expects `{"success": bool, "data": ..., "message": ...}`:

- `GET /api/business/{businessId}/vfd` -> `VfdConfig`
- `POST /api/business/{businessId}/vfd/register` -> `VfdConfig`
- `GET /api/business/{businessId}/fiscal-receipts` -> `FiscalReceipt[]`
- `POST /api/business/invoices/{invoiceId}/fiscal-receipt` -> `FiscalReceipt`

Models expected by app:

- `VfdConfig` fields: `id`, `business_id`, `tin`, `vrn`, `serial_number`, `registration_id`, `certificate_key`, `is_active`, `registered_at`
- `FiscalReceipt` fields: `id`, `invoice_id`, `receipt_number`, `fiscal_code`, `qr_code`, `tin`, `vrn`, `total_amount`, `vat_amount`, `issued_at`, `verification_url`

---

## Business Outcome

- Business owner can set up VFD during business registration.
- Paid invoices automatically get fiscalized with TRA.
- Retry-safe queue handles network/TRA outages.
- Counters and sequence rules stay compliant (`RCTNUM`, `GC`, `DC`, `ZNUM`).
- Finance/admin can track failures and re-try from backend safely.

---

## Required Database Additions

## 1) `business_vfd_configs`

One row per business VFD profile.

Suggested columns:

- `id` (PK)
- `business_id` (FK -> `user_businesses.id`, unique)
- `tin` string(30) not null
- `vrn` string(50) nullable
- `serial_number` string(120) not null
- `registration_id` string(120) nullable (`REGID`)
- `certificate_key` string(255) nullable (`EFDSERIAL`/cert key as returned by TRA)
- `receipt_code` string(80) nullable (`RECEIPTCODE`)
- `routing_key` string(50) nullable (from registration response)
- `username` string(120) nullable (TRA token username)
- `password_encrypted` text nullable (encrypted at rest)
- `token_value` text nullable
- `token_expires_at` timestamp nullable
- `current_gc` bigint default 0
- `current_rctnum` bigint default 0
- `current_dc` int default 0
- `current_dc_date` date nullable
- `is_active` boolean default false
- `last_ack_code` int nullable
- `last_ack_message` string(255) nullable
- `registered_at` timestamp nullable
- `last_synced_at` timestamp nullable
- `created_at`, `updated_at`

Indexes:

- unique(`business_id`)
- index(`tin`)
- index(`is_active`)

---

## 2) `business_fiscal_receipts`

Stores successful fiscal receipts and metadata for UI.

Suggested columns:

- `id` (PK)
- `business_id` (FK)
- `invoice_id` (FK -> `business_invoices.id`, unique)
- `receipt_number` string(120) nullable (`RCTNUM` or TRA returned number)
- `fiscal_code` string(200) nullable (`RCTVNUM` or equivalent)
- `qr_code` text nullable (generated URL/code payload)
- `tin` string(30) not null
- `vrn` string(50) nullable
- `total_amount` decimal(14,2) not null default 0
- `vat_amount` decimal(14,2) not null default 0
- `issued_at` timestamp nullable
- `verification_url` text nullable
- `ack_code` int nullable
- `ack_message` string(255) nullable
- `raw_request_xml` longText nullable
- `raw_response_xml` longText nullable
- `created_at`, `updated_at`

Indexes:

- unique(`invoice_id`)
- index(`business_id`, `issued_at`)

---

## 3) `business_vfd_outbox`

Durable queue for receipt + Z report submissions.

Suggested columns:

- `id` (PK)
- `business_id` (FK)
- `invoice_id` FK nullable
- `payload_type` enum: `receipt`, `z_report`
- `status` enum: `pending`, `sending`, `ack_success`, `ack_failed`, `network_retry`, `dead_letter`
- `sequence_no` bigint not null
- `request_xml` longText not null (immutable after first send)
- `request_hash` string(64) not null
- `attempt_count` int default 0
- `last_error` text nullable
- `ack_code` int nullable
- `ack_message` string(255) nullable
- `next_retry_at` timestamp nullable
- `first_attempted_at` timestamp nullable
- `last_attempted_at` timestamp nullable
- `resolved_at` timestamp nullable
- `created_at`, `updated_at`

Indexes:

- index(`business_id`, `status`, `next_retry_at`)
- unique(`business_id`, `sequence_no`)
- index(`invoice_id`)

---

## 4) Optional `business_vfd_z_reports`

If you need dedicated report history.

- `id`, `business_id`, `znum`, `business_date`, totals JSON/columns, `ack_code`, `ack_message`, `submitted_at`, `raw_request_xml`, `raw_response_xml`, timestamps.

---

## API Endpoints to Implement

All endpoints authenticated with existing bearer auth and ownership checks.

## 1. Get VFD Config

`GET /api/business/{businessId}/vfd`

Rules:

- Verify user owns business.
- Return active config if exists; if not, return `success: true` with `data: null` (frontend handles unregistered state).

---

## 2. Register VFD

`POST /api/business/{businessId}/vfd/register`

Request body:

```json
{
  "tin": "123456789",
  "vrn": "40-123456-A",
  "serial_number": "10TZXXXXXX"
}
```

Validation:

- `tin`: required, digits only, len 9
- `serial_number`: required, min 4
- `vrn`: nullable

Flow:

1. Load/create `business_vfd_configs` row.
2. Build and sign TRA registration XML.
3. Call TRA registration endpoint (env-aware).
4. Parse ACK:
   - if success, persist `registration_id`, `certificate_key`, `receipt_code`, `username`, encrypted password, counters.
   - set `is_active = true`, `registered_at = now()`.
5. Return normalized `VfdConfig` JSON shape.

Failure:

- Return `success: false`, include ACK code/message mapping.

---

## 3. Issue Fiscal Receipt for Invoice

`POST /api/business/invoices/{invoiceId}/fiscal-receipt`

Rules:

- Verify invoice belongs to current user business.
- Invoice should be `paid` or fully settled (`balance_remaining <= 0`).
- Idempotent behavior: if receipt already exists for `invoice_id`, return existing success response.

Flow:

1. Load active VFD config.
2. Ensure valid token (refresh only if expired).
3. Reserve counters atomically (DB transaction + row lock):
   - increment `current_gc`
   - increment `current_rctnum`
   - increment/reset `current_dc` by date
4. Generate receipt XML from invoice items/totals and fixed timestamp.
5. Save outbox record (`pending`) with immutable request XML.
6. Attempt immediate submit (or dispatch job) using same XML.
7. On ACK success:
   - create `business_fiscal_receipts`
   - update invoice `vfd_receipt_number`, `vfd_receipt_url`
   - outbox -> `ack_success`
8. On failure:
   - outbox -> `ack_failed` or `network_retry`
   - return `success: false` with actionable message.

---

## 4. List Fiscal Receipts

`GET /api/business/{businessId}/fiscal-receipts?page={n}`

Return paginated or simple list in expected model format.

---

## 5. (New) Refresh VFD Token Manually

`POST /api/business/{businessId}/vfd/token/refresh`

Use when ops needs explicit refresh; return expiry metadata.

---

## 6. (New) Retry Failed Outbox Item

`POST /api/business/vfd/outbox/{outboxId}/retry`

Rules:

- ensure ownership by business.
- use stored immutable XML; do not regenerate with new counters/timestamp.

---

## 7. (New) Submit Z Report

`POST /api/business/{businessId}/vfd/z-report`

Request:

```json
{
  "business_date": "2026-04-17"
}
```

Backend computes totals from invoices/receipts; signs + submits Z report payload.

---

## TRA Integration Rules (Must Enforce)

- Signed XML payloads required.
- Use `Client: webapi` for registration.
- Use `Routing-Key: vfdrct` for receipt and `vfdzreport` for Z report.
- Token endpoint uses form-urlencoded with `grant_type=password`.
- Counter rules:
  - `GC` and `RCTNUM` unique and increasing.
  - `DC` resets daily.
  - `ZNUM` = date `YYYYMMDD`.
- No future timestamps.
- For unknown delivery outcome (timeout/no response), retry using the exact original XML.

---

## ACK Code Handling

Handle at minimum these observed codes:

- `0` success
- `1` invalid signature
- `3` invalid TIN
- `4` registration approval required
- `5` unhandled exception
- `6` invalid serial/not registered
- `7` invalid client header
- `8` wrong certificate

Persist `ack_code` + `ack_message` on config/outbox/receipt rows.

---

## Jobs, Queue, and Retry Policy

Create queue jobs:

- `IssueFiscalReceiptJob(outboxId)`
- `SubmitVfdZReportJob(outboxId)`
- `ReplayPendingVfdOutboxJob(businessId)`

Retry strategy:

- network errors -> exponential backoff with jitter (e.g. 1m, 3m, 10m, 30m, 2h; cap 24h)
- ACK functional errors -> mark `ack_failed` (manual fix/retry path)
- move to `dead_letter` after max attempts (configurable, e.g. 10)

Ordering:

- process pending outbox by `sequence_no ASC` per business.

---

## Business Registration Integration (Important)

Because frontend now includes VFD setup in registration:

When creating a new business profile:

1. `POST /api/business` creates business as usual.
2. If frontend passes VFD setup intent, app triggers `POST /api/business/{id}/vfd/register`.
3. Backend should support immediate registration after business creation without extra prerequisites.

Future improvement:

- accept optional `vfd` block directly inside business create payload and execute registration transactionally after create.

---

## Security Requirements

- Keep cert credentials/password/token encrypted at rest.
- Never return raw secrets to client.
- Mask sensitive fields in logs.
- Sign and call TRA only from backend.
- Add audit trail for config changes and manual retries.

---

## Observability and Admin Support

Add structured logs and metrics:

- registration success/failure count
- token refresh count/failures
- receipt submit latency/success rate
- outbox backlog size per business
- top ACK error codes

Add internal admin endpoint/page to inspect stuck outbox rows.

---

## Response Examples

Success register:

```json
{
  "success": true,
  "message": "VFD imesajiliwa kwa TRA",
  "data": {
    "id": 4,
    "business_id": 22,
    "tin": "123456789",
    "vrn": "40-123456-A",
    "serial_number": "10TZ0022",
    "registration_id": "TZ111222333",
    "certificate_key": "10TZ0022",
    "is_active": true,
    "registered_at": "2026-04-17T10:20:00Z"
  }
}
```

Failure register:

```json
{
  "success": false,
  "message": "VFD registration failed: Invalid TIN (ACK 3)"
}
```

---

## Acceptance Checklist (Definition of Done)

- [ ] Migrations created for VFD config, receipts, outbox (and optional z reports)
- [ ] Existing 4 frontend endpoints work with expected JSON and fields
- [ ] Business registration + immediate VFD register path works
- [ ] Token refresh logic implemented and persisted
- [ ] Counter generation is atomic and sequence-safe
- [ ] Idempotent fiscal receipt issuance by `invoice_id`
- [ ] Outbox retry worker handles network failures and resumes in-order
- [ ] ACK codes persisted and visible in logs
- [ ] Unit/integration tests for register, token, receipt success, timeout retry, duplicate prevention
- [ ] Staging validation against TRA test endpoints completed

---

## Suggested Test Cases

1. Register VFD with valid TIN/serial -> active config returned.
2. Register with invalid TIN -> ACK fail surfaced with clear message.
3. Issue receipt on paid invoice -> creates fiscal receipt + updates invoice receipt fields.
4. Re-issue same invoice receipt -> returns existing receipt, no duplicate row.
5. Token expired -> auto-refresh then successful submission.
6. TRA timeout -> outbox `network_retry` with preserved original XML.
7. Retry endpoint uses same payload hash and succeeds later.
8. DC resets after date change; GC/RCTNUM continue sequence.

