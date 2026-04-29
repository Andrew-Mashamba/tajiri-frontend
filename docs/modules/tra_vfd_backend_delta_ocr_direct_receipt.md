# TRA VFD Backend Delta: OCR + Direct Receipt

## Purpose

This document captures **new backend directives** required by the latest VFD frontend enhancements in `lib/vfd/`:

1. External invoice creation from scanned/uploaded image with OCR prefill.
2. Direct TRA VFD receipt generation when user has no existing invoice.

This is a **delta** to `docs/modules/tra_vfd_backend_directive.md`, not a replacement.

---

## Frontend Flows Now Live

### Flow A: External Invoice (Scan/Upload) -> Fiscalize

From VFD module, user can:
- scan/upload image,
- OCR prefill vendor/customer, invoice number, amount, TIN, VRN,
- confirm/edit values,
- create paid invoice,
- issue fiscal receipt immediately.

### Flow B: Direct TRA VFD Receipt (No Invoice)

From VFD module, user can:
- enter quick sale details (customer, amount, VAT, notes),
- trigger one action to generate receipt.

Current frontend compatibility strategy:
- creates a minimal internal paid invoice,
- then calls invoice fiscalization endpoint.

---

## Mandatory Backend Requirements

## 1) Keep Invoice Fiscalization Endpoint Stable

Endpoint already used:
- `POST /business/invoices/{invoiceId}/fiscal-receipt`

Requirements:
- continue accepting `{"user_id": <int>}` body,
- fiscalize invoices created with `status=paid`,
- return full fiscal receipt payload used by frontend cards.

Expected response shape (success):
- `data.id`
- `data.invoice_id`
- `data.verification_code`
- `data.verification_url`
- `data.qr_code`
- `data.fiscal_code`
- `data.gc`, `data.dc`, `data.znum` (nullable for legacy, preferred populated)
- `data.ack_code`, `data.ack_message`
- `data.created_at`

## 2) Support Minimal Paid Invoice Creation for Direct Mode

Endpoint already used:
- `POST /business/invoices`

Must accept payloads with minimal fields:
- `business_id`
- `customer_name` (can be "Walk-in Customer")
- `items[]` (single line allowed)
- `subtotal`, `vat_rate`, `vat_amount`, `total_amount`
- `status = "paid"`
- `amount_paid = total_amount`
- `balance_remaining = 0`
- `due_date`
- `notes`
- optional `customer_tin`

Validation guidance:
- do not require pre-existing customer profile for walk-in receipts,
- allow invoice creation with just above fields when business and auth are valid.

## 3) Persist OCR/Source Metadata

Backend must preserve metadata passed in `notes`, including:
- `external_invoice_number: ...`
- `external_vendor_tin: ...`
- `external_vendor_vrn: ...`
- `external_invoice_image: ...` (local client path for trace, optional to ignore for storage)
- `source: external_scan_upload`
- `source: direct_vfd_receipt_no_source_invoice`

Also persist structured fields where available:
- `customer_tin`

## 4) Idempotency and Duplicate Protection

Prevent duplicate fiscalization when user retries/taps quickly.

Minimum acceptable behavior:
- if same invoice already fiscalized, return deterministic conflict/result,
- avoid issuing a second TRA receipt for same invoice unless explicit correction flow.

Preferred behavior:
- idempotency key or deterministic invoice state lock,
- return existing fiscal receipt reference when duplicate request is detected.

---

## New Recommended Endpoint (Phase 2)

To remove synthetic internal invoice creation from frontend, add:

- `POST /business/{businessId}/vfd/direct-receipt`

### Request (recommended)

```json
{
  "user_id": 123,
  "customer_name": "Walk-in Customer",
  "customer_tin": "123456789",
  "customer_vrn": "40-123456-A",
  "source": "direct_vfd_receipt_no_source_invoice",
  "invoice_reference": "EXT-2026-0001",
  "items": [
    {
      "description": "Direct VFD sale",
      "quantity": 1,
      "unit_label": "pcs",
      "unit_price": 100000,
      "total_price": 100000,
      "is_vat_exempt": false
    }
  ],
  "subtotal": 100000,
  "vat_rate": 18,
  "vat_amount": 18000,
  "total_amount": 118000,
  "payment_type": "cash",
  "notes": "source: external_scan_upload"
}
```

### Response (recommended)

```json
{
  "success": true,
  "message": "Risiti ya TRA imetolewa",
  "data": {
    "id": 8891,
    "invoice_id": null,
    "verification_code": "ABCD-1234-EFGH",
    "verification_url": "https://verify.tra.go.tz/...",
    "qr_code": "https://verify.tra.go.tz/...",
    "fiscal_code": "RCTNUM:1001;GC:901;DC:1;ZNUM:45",
    "gc": 901,
    "dc": 1,
    "znum": 45,
    "ack_code": 0,
    "ack_message": "ACCEPTED",
    "created_at": "2026-04-17T10:30:00Z"
  }
}
```

---

## Tanzania-Specific Parsing/Validation Requirements

Frontend now extracts TIN/VRN/invoice references from OCR. Backend should:

- accept `TIN` and `VRN` when provided,
- normalize spaces/hyphens/case before validation,
- treat malformed TIN/VRN as clear 422 validation errors,
- include field-specific errors in response:
  - `errors.customer_tin`
  - `errors.customer_vrn`

Suggested tolerant patterns (subject to TRA standardization):
- TIN: numeric, length 9-12
- VRN: alphanumeric/hyphen, length 6-20

---

## Error Contract (Required for Frontend UX)

Return consistent JSON errors:

```json
{
  "success": false,
  "message": "Human readable summary",
  "code": "VFD_TOKEN_EXPIRED",
  "errors": {
    "field_name": ["Validation message"]
  }
}
```

Codes to standardize:
- `VFD_NOT_REGISTERED`
- `VFD_TOKEN_EXPIRED`
- `VFD_TOKEN_INVALID`
- `FISCALIZATION_DUPLICATE`
- `TRA_REJECTED`
- `VALIDATION_ERROR`
- `FORBIDDEN_OWNER_MISMATCH`

---

## Ownership and Security

Enforce for all related endpoints:
- authenticated user must match provided `user_id`,
- user must own the target business,
- all mutations audit-logged with actor, business, request hash, outcome.

Never trust OCR-extracted values as authoritative:
- frontend OCR is assistive only,
- backend remains source of truth for validation and persistence.

---

## Definition of Done for This Delta

- Minimal paid invoice creation succeeds for walk-in/direct sales.
- Invoice fiscalization works reliably for those invoices.
- OCR-origin metadata is preserved and queryable.
- Duplicate fiscalization is prevented or safely idempotent.
- Structured error contract is implemented.
- Optional phase-2 direct endpoint is implemented (recommended), or explicitly deferred with timeline.

