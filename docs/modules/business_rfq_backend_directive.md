# TAJIRI Business RFQ Backend Directive

## Goal
Implement a dedicated end-to-end RFQ lifecycle for business management so the frontend no longer relies on generic quotes plus embedded note parsing.

The frontend now expects dedicated RFQ inbox and response APIs with explicit linkage, delivery state, viewed state, and RFQ-level decision orchestration.

## Business Outcome
- Buyers can send RFQs to one or many supplier businesses.
- Suppliers receive RFQs in a dedicated inbox.
- Suppliers respond with priced quotations.
- Buyers compare responses and accept one.
- Accepting one response can auto-close the rest.
- Notification and email delivery state are visible in the app.

## Required Database Additions

### 1. `business_rfq_requests`
Core RFQ record, one row per supplier destination.

Suggested columns:
- `id`
- `request_number` string unique
- `request_group_uuid` uuid nullable
- `requester_business_id` foreign key
- `destination_business_id` foreign key
- `created_by_user_id` foreign key
- `status` enum: `draft`, `sent`, `viewed`, `responded`, `accepted`, `rejected`, `cancelled`, `expired`
- `source_mode` enum: `catalog_match`, `free_text`
- `currency` string default `TZS`
- `requirements` text nullable
- `notes` text nullable
- `needed_by` datetime nullable
- `response_deadline` datetime nullable
- `branded_document_url` string nullable
- `notification_sent_at` datetime nullable
- `notification_delivery_status` string nullable
- `email_sent_at` datetime nullable
- `email_delivery_status` string nullable
- `viewed_at` datetime nullable
- `accepted_response_id` foreign key nullable
- `created_at`
- `updated_at`

Notes:
- `request_group_uuid` groups multi-recipient RFQs created from one buyer action.
- One supplier business should have one RFQ row per request group.

### 2. `business_rfq_items`
Requested products/services for each RFQ.

Suggested columns:
- `id`
- `rfq_request_id` foreign key
- `requested_product_id` foreign key nullable
- `item_type` enum: `product`, `service`, `custom`
- `title`
- `description` text nullable
- `quantity` decimal(12,2) default `1`
- `unit_label` string nullable
- `similarity_status` enum nullable: `exact`, `similar`, `manual`, `custom`
- `match_score` decimal(5,2) nullable
- `created_at`
- `updated_at`

### 3. `business_rfq_responses`
Supplier quotation response header.

Suggested columns:
- `id`
- `rfq_request_id` foreign key
- `responder_business_id` foreign key
- `status` enum: `draft`, `submitted`, `accepted`, `rejected`, `not_selected`, `withdrawn`
- `currency` string default `TZS`
- `subtotal` decimal(14,2) default `0`
- `vat_rate` decimal(5,2) default `0`
- `vat_amount` decimal(14,2) default `0`
- `total_amount` decimal(14,2) default `0`
- `lead_time` string nullable
- `validity` string nullable
- `terms` text nullable
- `notes` text nullable
- `submitted_at` datetime nullable
- `viewed_by_buyer_at` datetime nullable
- `created_at`
- `updated_at`

Constraint:
- Unique on `rfq_request_id + responder_business_id` unless you intentionally allow multiple revisions.

### 4. `business_rfq_response_items`
Priced line items returned by the supplier.

Suggested columns:
- `id`
- `rfq_response_id` foreign key
- `rfq_item_id` foreign key nullable
- `title`
- `quantity` decimal(12,2)
- `unit_price` decimal(14,2)
- `total_price` decimal(14,2)
- `created_at`
- `updated_at`

### 5. Optional email support

#### `users`
- add nullable `email`
- keep unique validation only when present

#### `businesses`
- add nullable `email`
- optional business contact email for RFQ delivery

## Required API Endpoints

All endpoints below should be authenticated.

### 1. Create RFQ
`POST /api/business/rfq`

Purpose:
- Create one or many RFQ records from a single buyer action.

Request body:
```json
{
  "requester_business_id": 15,
  "recipient_business_ids": [33, 40, 52],
  "currency": "TZS",
  "source_mode": "catalog_match",
  "needed_by": "2026-04-20T00:00:00Z",
  "response_deadline": "2026-04-18T17:00:00Z",
  "requirements": "Need delivery to Kariakoo branch.",
  "notes": "Optional extra message from buyer.",
  "items": [
    {
      "requested_product_id": 9001,
      "item_type": "product",
      "title": "Office chair",
      "description": "Black ergonomic chair",
      "quantity": 20
    }
  ]
}
```

Response:
- return created RFQ threads, one per recipient
- generate `request_group_uuid`
- generate `request_number` for each RFQ
- generate branded RFQ document URL if supported
- dispatch notification + email jobs immediately

### 2. Sent RFQ inbox
`GET /api/business/rfq/sent?requester_business_id={id}&status={optional}`

Return array of RFQ threads created by the buyer business.

Each item must include:
- RFQ header data
- destination business name
- destination owner handle if available
- items count
- matched items count
- notification delivery state
- email delivery state
- viewed/opened state
- responses summary count

### 3. Received RFQ inbox
`GET /api/business/rfq/received?destination_business_id={id}&status={optional}`

Return array of RFQs addressed to the supplier business.

Each item must include:
- requester business name
- requester logo URL if available
- viewed/opened state
- delivery state
- items
- deadlines

### 4. RFQ detail
`GET /api/business/rfq/{rfqId}`

Return one RFQ thread with:
- header
- requested items
- delivery metadata
- viewed metadata
- optional embedded responses summary

### 5. Mark RFQ viewed
`PATCH /api/business/rfq/{rfqId}/viewed`

Behavior:
- set `viewed_at` if null
- update status from `sent` to `viewed` if appropriate

### 6. Submit supplier response
`POST /api/business/rfq/{rfqId}/respond`

Request body:
```json
{
  "responder_business_id": 33,
  "responder_user_id": 88,
  "currency": "TZS",
  "subtotal": 250000,
  "vat_rate": 18,
  "vat_amount": 45000,
  "total_amount": 295000,
  "lead_time": "5 days",
  "validity": "Valid for 7 days",
  "terms": "Delivery after confirmation.",
  "notes": "Stock available immediately.",
  "items": [
    {
      "rfq_item_id": 1001,
      "title": "Office chair",
      "quantity": 20,
      "unit_price": 12500,
      "total_price": 250000
    }
  ]
}
```

Behavior:
- create `business_rfq_responses`
- create `business_rfq_response_items`
- update RFQ status to `responded`
- notify buyer in-app
- email buyer if requester user/business email exists

Implementation note:
- preferred behavior is to derive the responder user from the authenticated token and not require `responder_user_id`
- if backend validation currently depends on it, accept `responder_user_id` as an optional compatibility field and verify it matches the authenticated user

### 7. RFQ responses list
`GET /api/business/rfq/{rfqId}/responses`

Return ranked or chronological supplier responses with:
- `id`
- `rfq_id`
- responder business id/name
- subtotal
- VAT
- total
- lead time
- validity
- terms
- notes
- status
- items

Contract requirement:
- this endpoint must return the same response rows exposed inside `GET /api/business/rfq/{rfqId}` under `responses`
- it must not return an empty array when the RFQ detail payload already has `responses_count > 0` and embedded responses
- buyer authorization should be scoped to the RFQ requester business

### 8. Accept RFQ response
`PATCH /api/business/rfq/{rfqId}/accept`

Request body:
```json
{
  "response_id": 5002,
  "close_others": true
}
```

Behavior:
- mark chosen response `accepted`
- set RFQ `accepted_response_id`
- set RFQ status `accepted`
- if `close_others=true`, mark sibling responses `not_selected`
- notify winning supplier
- notify non-selected suppliers if auto-close applied
- optionally emit domain event for invoice/order creation

### 9. Reject RFQ response
`PATCH /api/business/rfq/{rfqId}/reject`

Request body:
```json
{
  "response_id": 5003
}
```

Behavior:
- mark response `rejected`
- do not close RFQ unless this was the last active response and business logic requires it

## Response Shape Required By Frontend

### RFQ thread
```json
{
  "id": 91,
  "request_number": "RFQ-2026-00091",
  "requester_business_id": 15,
  "requester_business_name": "My Shop",
  "requester_logo_url": "https://...",
  "destination_business_id": 33,
  "destination_business_name": "Kariakoo Furniture",
  "destination_owner_handle": "@kariakoo-furniture",
  "status": "viewed",
  "source_mode": "catalog_match",
  "currency": "TZS",
  "requirements": "Need black ergonomic chairs",
  "notes": "Deliver to Kariakoo branch",
  "needed_by": "2026-04-20T00:00:00Z",
  "response_deadline": "2026-04-18T17:00:00Z",
  "items_count": 1,
  "matched_items_count": 1,
  "branded_document_url": "https://...",
  "notification_delivery_status": "delivered",
  "email_delivery_status": "queued",
  "notification_sent_at": "2026-04-15T10:00:02Z",
  "email_sent_at": "2026-04-15T10:00:03Z",
  "viewed": true,
  "viewed_at": "2026-04-15T10:05:00Z",
  "responses_count": 2,
  "active_responses_count": 1,
  "accepted_response_id": 5002,
  "created_at": "2026-04-15T10:00:00Z",
  "updated_at": "2026-04-15T10:03:00Z",
  "items": [
    {
      "id": 1001,
      "requested_product_id": 9001,
      "item_type": "product",
      "title": "Office chair",
      "description": "Black ergonomic chair",
      "quantity": 20,
      "similarity_status": "exact",
      "match_score": 100
    }
  ],
  "responses": []
}
```

### RFQ response
```json
{
  "id": 5002,
  "rfq_id": 91,
  "responder_business_id": 33,
  "responder_business_name": "Kariakoo Furniture",
  "subtotal": 250000,
  "vat_rate": 18,
  "vat_amount": 45000,
  "total_amount": 295000,
  "currency": "TZS",
  "lead_time": "5 days",
  "validity": "Valid for 7 days",
  "terms": "Delivery after confirmation.",
  "notes": "Stock available immediately.",
  "status": "submitted",
  "created_at": "2026-04-15T13:00:00Z",
  "items": [
    {
      "id": 7001,
      "title": "Office chair",
      "quantity": 20,
      "unit_price": 12500,
      "total_price": 250000
    }
  ]
}
```

## Notification and Email Rules
- Send in-app notification when RFQ is created.
- Send email when RFQ is created if `businesses.email` exists.
- Also send email to owning user if `users.email` exists.
- Send in-app notification when supplier submits a response.
- Send email to buyer business/user when response is submitted.
- Send in-app notification when a response is accepted, rejected, or marked not selected.
- Expose delivery status back to frontend, not just a boolean fire-and-forget.

## Decision Orchestration Rules
- A buyer can compare all responses for one RFQ.
- A buyer can accept only one active response per RFQ.
- If `close_others=true`, all other active responses become `not_selected`.
- Once accepted, RFQ should not accept new responses unless explicitly reopened.

## Validation Rules
- `requester_business_id` must belong to authenticated user.
- every `recipient_business_id` must exist and not equal requester.
- at least one item or a free-text requirement is required.
- supplier can respond only if business matches RFQ destination.
- buyer can accept/reject only if business matches RFQ requester.
- monetary values must be non-negative.
- if `responder_user_id` is sent, it must match the authenticated user.
- if `requester_business_id` is sent to `accept` or `reject`, it must match the authenticated user and the RFQ owner.

## Suggested Backend Events
- `RfqCreated`
- `RfqViewed`
- `RfqResponseSubmitted`
- `RfqResponseAccepted`
- `RfqResponseRejected`
- `RfqResponseNotSelected`

## Suggested Follow-up Integration
- allow `accept` endpoint to optionally create invoice or purchase order in the next step
- preserve audit history for delivery/view/decision actions
- expose response ranking fields if backend wants to pre-rank by total price or lead time

## Frontend Compatibility Note
The frontend has already been updated to call these dedicated endpoints:
- `GET /api/business/rfq/sent`
- `GET /api/business/rfq/received`
- `GET /api/business/rfq/{id}`
- `PATCH /api/business/rfq/{id}/viewed`
- `POST /api/business/rfq/{id}/respond`
- `GET /api/business/rfq/{id}/responses`
- `PATCH /api/business/rfq/{id}/accept`
- `PATCH /api/business/rfq/{id}/reject`

The frontend also now expects these RFQ thread fields when available:
- `notification_delivery_status`
- `email_delivery_status`
- `notification_sent_at`
- `email_sent_at`
- `viewed_at`
- `responses_count`
- `active_responses_count`
- `accepted_response_id`

Live compatibility notes from API testing:
- `POST /api/business/rfq` may return created threads under `data.threads` instead of a flat `data[]`; frontend now tolerates both shapes
- `POST /api/business/rfq/{id}/respond` should ideally work with `responder_business_id` alone, but frontend now also sends `responder_user_id` when available for compatibility with current backend validation
- `GET /api/business/rfq/{id}/responses` must be fixed server-side if it can return `[]` while `GET /api/business/rfq/{id}` already includes embedded responses

If these endpoints are not yet implemented, RFQ inbox and comparison behavior will remain incomplete server-side even though the frontend is ready for the dedicated contract.

## Short Backend AI Directive

Use this as a focused follow-up directive for the backend AI:

```text
Please fix the remaining RFQ API contract gaps for `/api/business/rfq`.

Context:
- Frontend is already using the dedicated RFQ flow successfully for create, sent inbox, received inbox, detail, viewed, respond, accept, and reject.
- Live integration testing found two remaining backend inconsistencies.

Required fixes:

1. Fix `GET /api/business/rfq/{rfqId}/responses`
- Right now this endpoint can return an empty array even when `GET /api/business/rfq/{rfqId}` already contains embedded `responses` and `responses_count > 0`.
- Make sure `GET /api/business/rfq/{rfqId}/responses` returns the exact same response rows for that RFQ that are already serialized inside the RFQ detail payload.
- Validate buyer access using the RFQ requester business ownership.
- Return full response objects including:
  - `id`
  - `rfq_id`
  - `responder_business_id`
  - `responder_business_name`
  - `subtotal`
  - `vat_rate`
  - `vat_amount`
  - `total_amount`
  - `currency`
  - `lead_time`
  - `validity`
  - `terms`
  - `notes`
  - `status`
  - `items`

2. Make `POST /api/business/rfq/{rfqId}/respond` auth-driven
- Preferred behavior: derive the responder user from the authenticated token/session instead of requiring `responder_user_id` in the request body.
- Keep validating that the responder business matches the RFQ destination business and belongs to the authenticated user.
- For backward compatibility you may still accept `responder_user_id`, but it should be optional and, if present, must match the authenticated user.

3. Keep response shapes consistent
- `POST /api/business/rfq` may return created threads under `data.threads`; that is acceptable as long as it stays consistent.
- `POST /api/business/rfq/{rfqId}/respond` should ideally return the created RFQ response object directly, or clearly documented thread payload with embedded responses. Avoid ambiguous shapes.

Acceptance criteria:
- After a supplier submits a quotation response, both endpoints below must show that response immediately:
  - `GET /api/business/rfq/{rfqId}`
  - `GET /api/business/rfq/{rfqId}/responses`
- Buyer can then accept the response successfully.
- No extra frontend parsing hacks should be required beyond the dedicated RFQ contract.
```
