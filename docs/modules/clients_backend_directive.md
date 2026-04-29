# Clients Backend Directive

## Objective

Implement backend support for full parity with `docs/modules/clients_user_journeys.md`, including:

- client profile orchestration,
- merged activity feed,
- timestamped notes log (CRUD),
- reminders/follow-ups (CRUD + automation hooks),
- statement data endpoint,
- tags/categories + birthday/anniversary fields,
- reporting-friendly response structures.

This directive is the backend handoff for `lib/clients/`.

---

## 1) API Envelope and Conventions

All endpoints should return:

```json
{
  "success": true,
  "message": "Human readable",
  "data": {},
  "meta": {}
}
```

Failure:

```json
{
  "success": false,
  "message": "Validation failed",
  "code": "VALIDATION_ERROR",
  "errors": {
    "field": ["Error text"]
  }
}
```

Auth/ownership:

- Require authenticated actor + `user_id` for mutations where contract requires it.
- Enforce business ownership for every client resource access.

---

## 2) Data Model Additions

## `user_business_customers` (extend)

- `tags` JSON nullable
- `date_of_birth` date nullable
- `anniversary_date` date nullable
- `last_activity_at` timestamp nullable (maintained by server events)

## `business_client_notes` (new)

- `id`
- `business_id`
- `customer_id`
- `type` enum/string (`call`, `order`, `general`, `alert`)
- `body` text
- `created_by` user id
- `created_at`, `updated_at`
- soft delete optional

## `business_client_reminders` (new)

- `id`
- `business_id`
- `customer_id`
- `type` enum/string (`call`, `delivery`, `payment`, `quote`, `general`)
- `note` varchar(120) / text
- `remind_at` timestamp
- `status` enum (`pending`, `done`, `snoozed`, `cancelled`)
- `snoozed_until` timestamp nullable
- `completed_at` timestamp nullable
- `created_by` user id
- `created_at`, `updated_at`

---

## 3) Endpoints

## 3.1 Client activity feed (merged)

- `GET /api/business/{businessId}/clients/{clientId}/activity`

Query:

- `page` (optional)
- `per_page` (optional; default 30)

Response `data[]` item shape:

```json
{
  "id": 1234,
  "type": "invoice",
  "title": "Invoice #INV-042 sent",
  "subtitle": "TZS 85,000",
  "amount": 85000,
  "currency": "TZS",
  "occurred_at": "2026-04-17T08:00:00Z",
  "ref_type": "invoice",
  "ref_id": 7788
}
```

Supported types:

- `invoice`
- `payment`
- `debt`
- `appointment`
- `note`
- `reminder`
- `contact_log` (optional but recommended)

Sort:

- reverse chronological by `occurred_at`

## 3.2 Notes CRUD

- `GET /api/business/clients/{clientId}/notes`
- `POST /api/business/clients/{clientId}/notes`
- `PUT /api/business/clients/notes/{noteId}`
- `DELETE /api/business/clients/notes/{noteId}`

POST body:

```json
{
  "user_id": 123,
  "type": "call",
  "body": "Client requested reorder next week"
}
```

Validation:

- `type` required, enum
- `body` required, max 300 chars

## 3.3 Reminders CRUD

- `GET /api/business/clients/{clientId}/reminders`
- `POST /api/business/clients/{clientId}/reminders`
- `PUT /api/business/clients/reminders/{reminderId}`
- `DELETE /api/business/clients/reminders/{reminderId}`

POST body:

```json
{
  "user_id": 123,
  "type": "call",
  "note": "Follow up on quote",
  "remind_at": "2026-05-01T09:00:00Z"
}
```

Validation:

- `note` required, max 120 chars
- `remind_at` required datetime in future (allow short grace)
- `type` required enum

## 3.4 Statement endpoint

- `GET /api/business/clients/{clientId}/statement?from=...&to=...`

Response:

```json
{
  "success": true,
  "data": {
    "client": {
      "id": 10,
      "name": "Amina",
      "phone": "0712345678",
      "email": "a@example.com"
    },
    "period": {
      "from": "2026-03-01",
      "to": "2026-03-31"
    },
    "rows": [
      {
        "date": "2026-03-03",
        "description": "Invoice #INV-041",
        "debit": 85000,
        "credit": 0,
        "balance": 85000
      },
      {
        "date": "2026-03-08",
        "description": "Payment received",
        "debit": 0,
        "credit": 50000,
        "balance": 35000
      }
    ],
    "summary": {
      "total_invoiced": 85000,
      "total_paid": 50000,
      "balance_outstanding": 35000
    }
  }
}
```

---

## 4) Automatic Reminder Rules (Server-side jobs)

Implement scheduled jobs (FCM push + in-app cards):

- Inactive client alert (default inactivity >= 30 days)
- Overdue debt alert (1 day after due date)
- Quote follow-up reminder (7 days after unresponded quote)
- Birthday day-of + 3-day countdown
- Anniversary reminder
- Weekly digest and monthly summary (configurable windows)

Rate limit:

- Max 2 push notifications/day per user for clients module; overflow as in-app cards.

---

## 5) Tags and Segmentation

Customers should support:

- multi-tag assignment (`tags` JSON array),
- list filtering and analytics by segment.

Mutation contract for customer update should accept:

```json
{
  "user_id": 123,
  "tags": ["VIP", "Wholesale"],
  "date_of_birth": "1992-10-14",
  "anniversary_date": "2020-06-01"
}
```

---

## 6) Reporting Aggregates

Expose helpers for clients dashboard/report views:

- top debtors
- top revenue clients
- active vs inactive ratio
- segment revenue totals
- reminder conversion metrics (done reminder -> purchase within 7 days)

Can be one endpoint or several, but must be accessible for clients insights cards.

---

## 7) Observability & Audit

Log for every note/reminder mutation:

- actor user id
- business id
- client id
- action type (create/update/delete/done/snooze)
- timestamp

Include correlation/request id support for support debugging.

---

## 8) Frontend Alignment Notes

Frontend now has service methods ready in `BusinessService`:

- `getClientActivity(...)`
- `getClientNotes(...)`
- `addClientNote(...)`
- `updateClientNote(...)`
- `deleteClientNote(...)`
- `getClientReminders(...)`
- `addClientReminder(...)`
- `updateClientReminder(...)`
- `deleteClientReminder(...)`
- `getClientStatement(...)`

Ensure endpoint paths and envelopes match these methods to avoid adapter changes.

---

## 9) Definition of Done

- All endpoints above implemented with ownership validation.
- Notes/reminders persisted and queryable.
- Activity endpoint returns merged, paginated feed.
- Statement endpoint returns transaction table + summary.
- Tags/dob/anniversary fields supported on customer schema/API.
- Scheduled reminders jobs active and rate-limited.
- Error envelope standardized with `code` + `errors`.

