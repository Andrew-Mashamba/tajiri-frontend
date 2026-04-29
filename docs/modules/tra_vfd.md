# TAJIRI TRA VFD Integration Guide

**Module location:** `lib/vfd/` (standalone module, integrated with invoices)

## Goal

Define a production-ready integration blueprint for Tanzania Revenue Authority (TRA) Virtual Fiscal Device (VFD) APIs implemented as a standalone TAJIRI module, integrated with invoices, payments, and fiscal receipt generation.

## Scope

- Register business VFD credentials with TRA
- Fetch and manage TRA access tokens
- Submit invoice/receipt fiscal payloads to TRA
- Submit daily Z report payloads
- Generate and verify fiscal receipt links/codes
- Handle retries, offline queueing, and sequence/counter compliance

---

## System Overview

TRA VFD is an XML-based API (not REST-style JSON) that requires:

- Signed XML payloads using a TRA-issued certificate/private key
- Certificate serial in request headers
- Bearer token for receipt/Z-report submission
- Strict sequence controls for counters (`RCTNUM`, `GC`, `DC`, `ZNUM`)

In TAJIRI flow, the standalone VFD module should trigger when an invoice reaches fully paid state and produce a verifiable fiscal receipt reference for customer/business use.

---

## Confirmed Endpoints

### Test/UAT

- Registration: `https://virtual.tra.go.tz/efdmsRctApi/api/vfdRegReq`
- Token: `https://virtual.tra.go.tz/efdmsRctApi/vfdtoken`
- Receipt/Invoice posting: `https://virtual.tra.go.tz/efdmsRctApi/api/efdmsRctInfo`
- Z report posting: `https://virtual.tra.go.tz/efdmsRctApi/api/efdmszreport`
- Receipt verification UI: `https://virtual.tra.go.tz/efdmsRctVerify/Home/Index`

### Production

- Registration: `https://vfd.tra.go.tz/api/vfdRegReq`
- Token: `https://vfd.tra.go.tz/vfdtoken`
- Receipt/Invoice posting: `https://vfd.tra.go.tz/api/efdmsRctInfo`
- Z report posting: `https://vfd.tra.go.tz/api/efdmszreport`
- Receipt verification UI: `https://verify.tra.go.tz/`

---

## Integration Lifecycle

### 1) Registration (one-time initialization)

Send seller TIN and device serial/cert key to register VFD and obtain integration metadata.

Expected persisted output from registration:

- `REGID`
- `EFDSERIAL` / `SERIAL`
- `RECEIPTCODE`
- `USERNAME`
- `PASSWORD`
- `TOKENPATH`
- `ROUTINGKEY`
- initial `GC`
- taxpayer profile details (TIN/VRN/address/name/tax office)

### 2) Token retrieval

Use registration `USERNAME` + `PASSWORD` with `grant_type=password`.
Persist token and expiry; request new token only after expiry.

### 3) Receipt/invoice submission

On each fiscal event, post signed XML to receipt endpoint with valid bearer token and required counters.

### 4) Z report submission

At end of business day, post signed Z report summary before next-day operations.

### 5) Verification

Store and display verification info (code/link/QR generation inputs) on invoice/fiscal receipt screens.

---

## Required Headers

### Registration request

- `Content-Type: application/xml`
- `Client: webapi`
- `Cert-Serial: <base64 certificate serial>`

### Receipt posting request

- `Content-Type: application/xml`
- `Routing-Key: vfdrct`
- `Cert-Serial: <base64 certificate serial>`
- `Authorization: bearer <token>`

### Z report posting request

- `Content-Type: application/xml`
- `Routing-Key: vfdzreport`
- `Cert-Serial: <base64 certificate serial>`
- `Authorization: bearer <token>`

### Token request

- `Content-Type: application/x-www-form-urlencoded`
- body keys: `username`, `password`, `grant_type=password`

---

## Receipt Payload Requirements (Core Fields)

Receipt/invoice XML should contain:

- `DATE` (`YYYY-MM-DD`)
- `TIME` (`HH:MM:SS`)
- `TIN` (seller TIN)
- `REGID`
- `EFDSERIAL`
- `CUSTIDTYPE`, `CUSTID`, `CUSTNAME`, `MOBILENUM`
- `RCTNUM` (receipt number)
- `DC` (daily counter)
- `GC` (global counter)
- `ZNUM` (`YYYYMMDD`)
- `RCTVNUM` (often receipt-code + global counter scheme)
- `ITEMS` (ID, DESC, QTY, TAXCODE, AMT)
- `TOTALS` (`TOTALTAXEXCL`, `TOTALTAXINCL`, `DISCOUNT`)
- `PAYMENTS` (`PMTTYPE`, `PMTAMOUNT`)
- `VATTOTALS` (`VATRATE`, `NETTAMOUNT`, `TAXAMOUNT`)
- XML signature node

---

## Counter and Sequence Compliance Rules

These are critical for acceptance and auditability:

- `RCTNUM` must be unique and monotonically increasing
- `GC` must be unique and monotonically increasing
- `GC` and `RCTNUM` should remain aligned per TRA guidance
- `DC` resets daily and increments per transaction for the day
- `ZNUM` must match transaction date in `YYYYMMDD`
- Never reuse canceled/failed number IDs for a new transaction
- No future-dated timestamps

If first submission outcome is unknown (timeout/no response), retry with the exact original fiscal payload for that transaction.

---

## Retry, Offline, and Delivery Semantics

Implement as an outbox/queue with durable state:

- `pending` -> `sending` -> `ack_success` / `ack_failed` / `network_retry`
- Keep original XML body immutable once first submitted
- Retry in-order (FIFO) to preserve sequence integrity
- Do not submit next transaction in sequence until current status is resolved when strict ordering is required
- Continue issuing business transactions offline, enqueue fiscal payloads, auto-resubmit when connectivity returns

Recommended backoff:

- Exponential with jitter (e.g. 2s, 5s, 10s, 20s...) up to cap
- Separate retry policy for network errors vs ACK business errors

---

## ACK Code Handling (Observed)

Observed mappings from maintained community implementation:

- `0`: success
- `1`: invalid signature
- `3`: invalid TIN
- `4`: registration approval required
- `5`: unhandled exception
- `6`: invalid serial / serial not registered to web API/TIN
- `7`: invalid client header
- `8`: wrong certificate used for registration

Note: Treat this set as practical guidance; confirm against TRA onboarding/UAT responses for final production behavior.

---

## Security Requirements

- Store certificate/private key in secure secret storage; never expose in client app binaries
- Perform TRA signing and submission server-side only
- Rotate and audit credential access (certificate, token, registration credentials)
- Log request metadata, not raw sensitive secrets
- Encrypt at rest for VFD credentials and keys

Hash/signing note:

- Existing field implementations commonly use RSA + SHA1 signing for payload sections
- TRA test tooling references SHA1/SHA256 options
- Final algorithm/profile must be validated with TRA during certification/UAT

---

## TAJIRI Backend Data Model Additions (Recommended)

### `business_vfd_profiles`

- `business_id` (FK)
- `tin`, `vrn`
- `regid`, `efdserial`, `receipt_code`
- `username`, `password_encrypted`
- `token`, `token_expires_at`
- `cert_serial`, `cert_key_ref`, `cert_password_ref`
- `current_gc`, `current_rctnum`, `current_dc`, `current_znum`
- status/audit columns

### `business_vfd_outbox`

- `id`, `business_id`, `invoice_id`
- `payload_type` (`receipt` | `z_report`)
- `sequence_key` (for ordering)
- `original_payload_xml`
- `status`, `attempt_count`, `last_error`
- `ack_code`, `ack_msg`, `ack_number`, `ack_date`, `ack_time`
- timestamps (`created_at`, `sent_at`, `resolved_at`)

### `business_vfd_receipts`

- `invoice_id`
- `rctnum`, `gc`, `dc`, `znum`, `rctvnum`
- verification link/code
- raw ack payload
- sync status fields

---

## API/Service Contract for TAJIRI

Expose internal backend service methods:

- `registerVfd(businessId)`
- `refreshVfdToken(businessId)`
- `queueInvoiceFiscalization(invoiceId)`
- `submitNextPendingVfdPayload(businessId)`
- `submitZReport(businessId, businessDate)`
- `retryVfdPayload(outboxId)`
- `getVfdReceipt(invoiceId)`

Frontend-facing endpoints (suggested):

- `GET /business/{id}/vfd/profile`
- `POST /business/{id}/vfd/register`
- `POST /business/{id}/vfd/token/refresh`
- `POST /business/invoices/{invoiceId}/vfd/fiscalize`
- `GET /business/invoices/{invoiceId}/vfd/receipt`
- `POST /business/{id}/vfd/z-report`
- `GET /business/{id}/vfd/outbox`
- `POST /business/vfd/outbox/{outboxId}/retry`

---

## Operational Checklist

- Registration data persisted and encrypted
- Token refresh only on expiry
- Counters atomically incremented in DB transaction
- Payload XML escaped for special characters
- Original payload retained for unknown-response retries
- Offline queue replay enabled and ordered
- Verification link/code visible in UI and printable
- Monitoring dashboard for ACK failures and stuck outbox entries

---

## Risks and Mitigations

- **Counter drift** -> enforce DB locking + atomic increments
- **Duplicate receipt submission** -> idempotency keys + immutable original payload
- **Certificate mismatch/expiry** -> proactive certificate health checks
- **Network instability** -> durable queue + retry worker
- **Protocol change** -> feature flags + environment-specific endpoint/signing config

---

## Reference Sources

- TRA VFD API guide (community, detailed): <https://tra-docs.netlify.app/guide/api/>
- TRA introduction (community): <https://tra-docs.netlify.app/guide/introduction/>
- TRA test API landing: <https://virtual.tra.go.tz/efdmsRctApi/>
- TRA test verification: <https://virtual.tra.go.tz/efdmsRctVerify/Home/Index>
- TRA production verification: <https://verify.tra.go.tz/>
- Golang TRA VFD SDK: <https://github.com/Golang-Tanzania/tra-vfd>
- SDK endpoint constants: <https://raw.githubusercontent.com/Golang-Tanzania/tra-vfd/main/vfd.go>
- SDK receipt flow: <https://raw.githubusercontent.com/Golang-Tanzania/tra-vfd/main/receipt.go>
- SDK registration flow: <https://raw.githubusercontent.com/Golang-Tanzania/tra-vfd/main/register.go>
- SDK token flow: <https://raw.githubusercontent.com/Golang-Tanzania/tra-vfd/main/token.go>
- SDK ACK code mapping: <https://raw.githubusercontent.com/Golang-Tanzania/tra-vfd/main/errors.go>

---

## Notes

- Public documentation around full ACK catalogs and protocol revisions is limited; confirm final acceptance criteria directly in TRA onboarding/UAT.
- This guide is implementation-focused for TAJIRI and should be updated after first successful end-to-end UAT fiscalization run.
