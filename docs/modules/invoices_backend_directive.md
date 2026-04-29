# TAJIRI Invoice Module — Backend Implementation Directive

## Goal

Implement the complete invoice lifecycle backend to support the Flutter frontend at `lib/invoices/`. The frontend is fully built with 12 pages, 16 user journeys, and 25+ API calls — all pointing at endpoints that need to exist. Every endpoint returns JSON: `{"success": true/false, "data": ..., "message": "..."}`.

## Business Outcome

- Businesses create, send, track, and collect payment on invoices
- Customers receive invoices in-app and pay via TAJIRI wallet
- Partial payments tracked with running balance per invoice
- Credit notes reverse paid invoices with TRA VFD compliance
- Recurring invoice templates auto-generate on schedule
- VFD fiscal receipts auto-generated on full payment via TRA API
- Invoice revenue feeds into budget module via IncomeService/ExpenditureService
- Customer statements generated from invoice + payment history

## Server Details

| Item | Value |
|------|-------|
| Server | `172.240.241.180` |
| SSH | `root@172.240.241.180`, password `ZimaBlueApps` |
| Project path | `/var/www/tajiri.zimasystems.com` |
| Framework | Laravel 12, PHP 8.3 |
| Database | PostgreSQL 16 (user: postgres, password: postgres, db: tajiri) |
| Controller | `app/Http/Controllers/Api/MyBusinessController.php` |
| Routes | `routes/api.php` |
| Base URL | `https://tajiri.zimasystems.com/api` |

## Frontend Service Reference

All API calls: `lib/business/services/business_service.dart`
All models: `lib/business/models/business_models.dart`
Auth: Bearer token in `Authorization` header via `ApiConfig.authHeaders(token)`

---

## Required Database Tables

### 1. `business_invoices`

```sql
CREATE TABLE IF NOT EXISTS business_invoices (
    id SERIAL PRIMARY KEY,
    business_id INTEGER NOT NULL REFERENCES user_businesses(id) ON DELETE CASCADE,
    invoice_number VARCHAR(50) NOT NULL,
    customer_id INTEGER REFERENCES business_customers(id) ON DELETE SET NULL,
    customer_name VARCHAR(255),
    customer_phone VARCHAR(50),
    customer_email VARCHAR(255),
    customer_tin VARCHAR(50),
    customer_address TEXT,

    items JSONB NOT NULL DEFAULT '[]',

    subtotal DECIMAL(14,2) NOT NULL DEFAULT 0,
    discount_type VARCHAR(20),
    discount_value DECIMAL(14,2) DEFAULT 0,
    discount_amount DECIMAL(14,2) DEFAULT 0,
    vat_rate DECIMAL(5,2) DEFAULT 18.00,
    vat_amount DECIMAL(14,2) DEFAULT 0,
    total_amount DECIMAL(14,2) NOT NULL DEFAULT 0,
    amount_paid DECIMAL(14,2) DEFAULT 0,
    balance_remaining DECIMAL(14,2) GENERATED ALWAYS AS (total_amount - amount_paid) STORED,

    status VARCHAR(30) NOT NULL DEFAULT 'draft',
    due_date TIMESTAMP,
    payment_terms VARCHAR(255),
    payment_instructions TEXT,
    notes TEXT,

    source_quote_id INTEGER,
    source_rfq_response_id INTEGER,
    recurring_invoice_id INTEGER,

    vfd_receipt_number VARCHAR(100),
    vfd_receipt_url TEXT,

    created_at TIMESTAMP DEFAULT NOW(),
    updated_at TIMESTAMP DEFAULT NOW(),
    paid_at TIMESTAMP,
    voided_at TIMESTAMP,

    UNIQUE(business_id, invoice_number)
);

CREATE INDEX idx_bi_business ON business_invoices(business_id);
CREATE INDEX idx_bi_customer ON business_invoices(customer_id);
CREATE INDEX idx_bi_status ON business_invoices(status);
```

**Status values:** `draft`, `sent`, `delivered`, `viewed`, `partially_paid`, `paid`, `overdue`, `cancelled`, `credit_noted`, `void`

**Items JSONB element structure:**
```json
{
    "description": "Website development",
    "quantity": 1,
    "unit_label": "hrs",
    "unit_price": 50000,
    "total_price": 50000,
    "product_id": null,
    "is_vat_exempt": false
}
```

### 2. `business_invoice_payments`

```sql
CREATE TABLE IF NOT EXISTS business_invoice_payments (
    id SERIAL PRIMARY KEY,
    invoice_id INTEGER NOT NULL REFERENCES business_invoices(id) ON DELETE CASCADE,
    amount DECIMAL(14,2) NOT NULL,
    method VARCHAR(30) NOT NULL,
    reference VARCHAR(255),
    paid_at TIMESTAMP NOT NULL DEFAULT NOW(),
    recorded_by VARCHAR(20) NOT NULL DEFAULT 'manual',
    wallet_transaction_id INTEGER,
    notes TEXT,
    created_at TIMESTAMP DEFAULT NOW()
);

CREATE INDEX idx_bip_invoice ON business_invoice_payments(invoice_id);
```

**Method values:** `wallet`, `mpesa`, `tigo_pesa`, `airtel_money`, `bank`, `cash`
**Recorded_by values:** `auto` (wallet payment), `manual` (business owner entered)

### 3. `business_invoice_deliveries`

```sql
CREATE TABLE IF NOT EXISTS business_invoice_deliveries (
    id SERIAL PRIMARY KEY,
    invoice_id INTEGER NOT NULL REFERENCES business_invoices(id) ON DELETE CASCADE,
    channel VARCHAR(30) NOT NULL,
    recipient_address VARCHAR(255),
    delivery_type VARCHAR(20) DEFAULT 'invoice',
    sent_at TIMESTAMP DEFAULT NOW(),
    delivered_at TIMESTAMP,
    viewed_at TIMESTAMP,
    status VARCHAR(20) DEFAULT 'pending',
    failure_reason TEXT,
    created_at TIMESTAMP DEFAULT NOW()
);

CREATE INDEX idx_bid_invoice ON business_invoice_deliveries(invoice_id);
```

**Channel values:** `whatsapp`, `in_app`, `email`, `pdf_download`
**Delivery_type values:** `invoice`, `reminder`
**Status values:** `pending`, `sent`, `delivered`, `viewed`, `failed`

### 4. `business_credit_notes`

```sql
CREATE TABLE IF NOT EXISTS business_credit_notes (
    id SERIAL PRIMARY KEY,
    credit_note_number VARCHAR(50) NOT NULL,
    invoice_id INTEGER NOT NULL REFERENCES business_invoices(id) ON DELETE CASCADE,
    business_id INTEGER NOT NULL REFERENCES user_businesses(id) ON DELETE CASCADE,
    customer_id INTEGER,
    customer_name VARCHAR(255),
    items JSONB NOT NULL DEFAULT '[]',
    reason VARCHAR(50) NOT NULL,
    reason_text TEXT,
    subtotal DECIMAL(14,2) DEFAULT 0,
    vat_amount DECIMAL(14,2) DEFAULT 0,
    total_amount DECIMAL(14,2) DEFAULT 0,
    status VARCHAR(20) DEFAULT 'draft',
    application_method VARCHAR(30),
    applied_to_invoice_id INTEGER,
    wallet_refund_id INTEGER,
    vfd_reverse_receipt_number VARCHAR(100),
    issued_at TIMESTAMP,
    created_at TIMESTAMP DEFAULT NOW()
);

CREATE INDEX idx_bcn_invoice ON business_credit_notes(invoice_id);
CREATE INDEX idx_bcn_business ON business_credit_notes(business_id);
```

**Reason values:** `goods_returned`, `service_not_delivered`, `pricing_error`, `other`
**Application_method values:** `next_invoice`, `wallet_refund`, `manual`

### 5. `business_invoice_settings`

```sql
CREATE TABLE IF NOT EXISTS business_invoice_settings (
    id SERIAL PRIMARY KEY,
    business_id INTEGER NOT NULL UNIQUE REFERENCES user_businesses(id) ON DELETE CASCADE,
    number_prefix VARCHAR(20) DEFAULT 'INV',
    next_sequence INTEGER DEFAULT 1,
    default_payment_terms VARCHAR(20) DEFAULT 'net_30',
    default_include_vat BOOLEAN DEFAULT TRUE,
    default_payment_instructions TEXT,
    default_notes TEXT,
    auto_reminder_enabled BOOLEAN DEFAULT FALSE,
    reminder_days_after_due JSONB DEFAULT '[1, 3, 7, 14]',
    reminder_channels JSONB DEFAULT '["email"]',
    logo_url TEXT,
    created_at TIMESTAMP DEFAULT NOW(),
    updated_at TIMESTAMP DEFAULT NOW()
);
```

### 6. `business_recurring_invoices` (extend existing)

Ensure these columns exist:
```sql
ALTER TABLE business_recurring_invoices ADD COLUMN IF NOT EXISTS end_date TIMESTAMP;
ALTER TABLE business_recurring_invoices ADD COLUMN IF NOT EXISTS max_invoices INTEGER;
ALTER TABLE business_recurring_invoices ADD COLUMN IF NOT EXISTS custom_interval_days INTEGER;
ALTER TABLE business_recurring_invoices ADD COLUMN IF NOT EXISTS auto_send BOOLEAN DEFAULT FALSE;
ALTER TABLE business_recurring_invoices ADD COLUMN IF NOT EXISTS auto_send_channels JSONB DEFAULT '[]';
ALTER TABLE business_recurring_invoices ADD COLUMN IF NOT EXISTS payment_terms VARCHAR(255);
ALTER TABLE business_recurring_invoices ADD COLUMN IF NOT EXISTS notes TEXT;
ALTER TABLE business_recurring_invoices ADD COLUMN IF NOT EXISTS unpaid_count INTEGER DEFAULT 0;
```

---

## Complete API Endpoint List

Every endpoint the Flutter frontend calls. Grouped by feature.

### A. Invoice CRUD

| Method | URL | Flutter Method | Purpose |
|--------|-----|----------------|---------|
| `GET` | `/business/{bizId}/invoices` | `getInvoices(token, bizId)` | List all invoices for a business |
| `GET` | `/business/{bizId}/invoices?status=draft` | `getInvoices(token, bizId, status: 'draft')` | Filter by status |
| `POST` | `/business/{bizId}/invoices` | `createInvoice(token, body)` | Create new invoice |
| `GET` | `/business/invoices/{id}` | `getInvoice(token, id)` | Get single invoice |
| `PUT` | `/business/invoices/{id}` | `updateInvoice(token, id, body)` | Update draft invoice |
| `POST` | `/business/invoices/{id}/void` | `voidInvoice(token, id)` | Void an invoice |
| `GET` | `/business/invoices/{id}/pdf` | `getInvoicePdf(token, id)` | Get PDF download URL |

#### `POST /business/{bizId}/invoices` — Create Invoice

**Request body:**
```json
{
    "business_id": 1,
    "customer_id": 5,
    "customer_name": "ABC Corp",
    "customer_phone": "0712345678",
    "customer_email": "info@abc.co.tz",
    "customer_tin": "123-456-789",
    "customer_address": "Dar es Salaam",
    "items": [
        {
            "description": "Web development",
            "quantity": 40,
            "unit_label": "hrs",
            "unit_price": 50000,
            "total_price": 2000000,
            "is_vat_exempt": false
        }
    ],
    "subtotal": 2000000,
    "discount_type": "percentage",
    "discount_value": 10,
    "discount_amount": 200000,
    "vat_rate": 18,
    "vat_amount": 324000,
    "total_amount": 2124000,
    "due_date": "2026-05-16T00:00:00.000Z",
    "payment_terms": "Net 30",
    "payment_instructions": "M-Pesa: 0712345678\nNMB: 1234567890",
    "notes": "Thank you for your business",
    "status": "draft",
    "source_quote_id": null,
    "source_rfq_response_id": null
}
```

**Backend logic:**
1. Get/create `business_invoice_settings` for this business
2. Generate invoice number: `{prefix}-{YYYY}-{next_sequence padded to 4 digits}`
3. Increment `next_sequence` in settings
4. If no `customer_id` but `customer_name` provided: auto-create in `business_customers`, set the new `customer_id`
5. If `source_quote_id` set: update quote's `status = 'converted'` and `converted_invoice_id = new_invoice_id`
6. Insert invoice, return with generated ID and invoice_number

**Response:** `{"success": true, "data": {invoice_object}, "message": "Invoice created"}`

### B. Invoice Delivery

| Method | URL | Flutter Method | Purpose |
|--------|-----|----------------|---------|
| `POST` | `/business/invoices/{id}/send` | `sendInvoiceMultiChannel(token, id, body)` | Send via channels |
| `POST` | `/business/invoices/{id}/send` | `sendInvoice(token, id)` | Simple send (legacy) |
| `POST` | `/business/invoices/{id}/remind` | `sendInvoiceReminder(token, id, body)` | Send reminder |
| `GET` | `/business/invoices/{id}/deliveries` | `getInvoiceDeliveries(token, id)` | List delivery records |

#### `POST /business/invoices/{id}/send` — Multi-Channel Send

**Request body:** `{"channels": ["whatsapp", "email", "in_app"]}`

**Backend logic per channel:**
- `email`: Send HTML email with invoice PDF attachment via SMTP. Create delivery record `status = 'sent'`.
- `in_app`: Create FCM push notification to customer's user ID. Create delivery record `status = 'sent'`.
- `whatsapp`: Record delivery attempt (client handles actual WhatsApp share). Create delivery record `status = 'sent'`.
- Update invoice `status` from `draft` → `sent` if currently draft.

#### `POST /business/invoices/{id}/remind` — Send Reminder

**Request body:** `{"channel": "whatsapp", "message": "..."}`

Create delivery record with `delivery_type = 'reminder'`. Send via specified channel.

### C. Payments

| Method | URL | Flutter Method | Purpose |
|--------|-----|----------------|---------|
| `POST` | `/business/invoices/{id}/payments` | `recordInvoicePayment(token, id, body)` | Record payment |
| `GET` | `/business/invoices/{id}/payments` | `getInvoicePayments(token, id)` | List payments |
| `POST` | `/business/invoices/{id}/paid` | `markInvoicePaid(token, id)` | Mark fully paid (legacy) |

#### `POST /business/invoices/{id}/payments` — Record Payment

**Request body:**
```json
{
    "amount": 200000,
    "method": "mpesa",
    "reference": "QBH72K9X",
    "paid_at": "2026-04-16T10:30:00.000Z",
    "recorded_by": "manual",
    "notes": "First installment"
}
```

**CRITICAL backend logic after inserting payment:**
1. Recalculate: `UPDATE business_invoices SET amount_paid = (SELECT COALESCE(SUM(amount), 0) FROM business_invoice_payments WHERE invoice_id = ?) WHERE id = ?`
2. If `amount_paid >= total_amount`: set `status = 'paid'`, `paid_at = NOW()` → trigger VFD receipt generation (async queue)
3. Else if `amount_paid > 0`: set `status = 'partially_paid'`
4. **Record income:** Insert into income tracking table: `source = 'invoice_payment'`, `source_module = 'business'`, `reference_id = 'inv_payment_{payment_id}'`, `amount = payment_amount`, `description = 'Ankara #{invoice_number} — {customer_name}'`
5. **If method = 'wallet' AND recorded_by = 'auto':** Also record expenditure on customer side: `category = 'biashara'`, `source_module = 'business'`, `description = 'Ankara #{invoice_number} — {business_name}'`
6. **FCM push to business owner:** "Payment of TZS {amount} received for invoice #{number}"

### D. Credit Notes

| Method | URL | Flutter Method | Purpose |
|--------|-----|----------------|---------|
| `POST` | `/business/invoices/{id}/credit-notes` | `createCreditNote(token, id, body)` | Issue credit note |
| `GET` | `/business/invoices/{id}/credit-notes` | `getInvoiceCreditNotes(token, id)` | List credit notes |

#### `POST /business/invoices/{id}/credit-notes` — Issue Credit Note

**Request body:**
```json
{
    "items": [{"description": "...", "quantity": 1, "unit_price": 50000, "total_price": 50000}],
    "reason": "goods_returned",
    "reason_text": null,
    "subtotal": 50000,
    "vat_amount": 9000,
    "total_amount": 59000,
    "application_method": "wallet_refund"
}
```

**Backend logic:**
1. Validate: total of all credit notes for this invoice + new credit ≤ invoice total_amount
2. Generate number: `CN-{YYYY}-{sequence}`
3. Insert with `status = 'issued'`, `issued_at = NOW()`
4. Update original invoice `status = 'credit_noted'`
5. Trigger reverse VFD receipt (async)
6. If `application_method = 'wallet_refund'`: create wallet transfer from business to customer
7. Record negative income: `source = 'credit_note'`, `amount = -total_amount`
8. FCM push to customer: "Credit note received — TZS {amount}"

### E. VFD Receipts

| Method | URL | Flutter Method | Purpose |
|--------|-----|----------------|---------|
| `POST` | `/business/invoices/{id}/vfd` | `generateVfdReceipt(token, id)` | Generate VFD receipt |
| `POST` | `/business/invoices/{id}/vfd/retry` | `retryVfdReceipt(token, id)` | Retry failed VFD |

**Backend logic:**
1. Load invoice with items
2. Call TRA VFD API with invoice data (TIN, VRN, items, VAT breakdown)
3. On success: store `vfd_receipt_number` and `vfd_receipt_url` on invoice
4. On failure: log error, will be retried by scheduled job

### F. Invoice Settings

| Method | URL | Flutter Method | Purpose |
|--------|-----|----------------|---------|
| `GET` | `/business/{bizId}/invoice-settings` | `getInvoiceSettings(token, bizId)` | Get settings |
| `PUT` | `/business/{bizId}/invoice-settings` | `updateInvoiceSettings(token, bizId, body)` | Update settings |
| `POST` | `/business/{bizId}/invoice-settings/logo` | (future) | Upload logo |

#### `GET /business/{bizId}/invoice-settings`

If no settings exist, create defaults and return:
```json
{
    "success": true,
    "data": {
        "business_id": 1,
        "number_prefix": "INV",
        "next_sequence": 1,
        "default_payment_terms": "net_30",
        "default_include_vat": true,
        "default_payment_instructions": null,
        "default_notes": null,
        "auto_reminder_enabled": false,
        "reminder_days_after_due": [1, 3, 7, 14],
        "reminder_channels": ["email"],
        "logo_url": null
    }
}
```

#### `POST /business/{bizId}/invoice-settings/logo` — Logo Upload

Accept multipart form with image file. Store in `storage/app/public/business/{bizId}/invoice-logo.{ext}`. Update `logo_url` in settings. Return public URL.

### G. Invoice Summary

| Method | URL | Flutter Method | Purpose |
|--------|-----|----------------|---------|
| `GET` | `/business/{bizId}/invoices/summary` | `getInvoiceSummary(token, bizId)` | Dashboard stats |

**Response:**
```json
{
    "success": true,
    "data": {
        "total_outstanding": 5500000,
        "total_overdue": 2000000,
        "revenue_this_month": 3200000,
        "invoice_count": 45,
        "paid_count": 30,
        "overdue_count": 5,
        "aging": {
            "0_30": {"count": 5, "amount": 1500000},
            "31_60": {"count": 3, "amount": 2000000},
            "61_90": {"count": 1, "amount": 500000},
            "90_plus": {"count": 1, "amount": 1500000}
        }
    }
}
```

### H. Received Invoices (Customer Side)

| Method | URL | Flutter Method | Purpose |
|--------|-----|----------------|---------|
| `GET` | `/invoices/received?user_id={userId}` | `getReceivedInvoices(token, userId)` | Customer's received invoices |

**Backend logic:**
1. Find all invoices where the customer's user ID matches (via `business_customers.user_id` or matched by phone/email)
2. Also include invoices sent via `in_app` delivery where the target user ID matches
3. Return as standard invoice list

**NOTE:** This endpoint is outside the `/business/` prefix since it's user-scoped, not business-scoped.

### I. Recurring Invoices (extend existing)

| Method | URL | Flutter Method | Purpose |
|--------|-----|----------------|---------|
| `GET` | `/business/{bizId}/recurring-invoices` | `getRecurringInvoices(token, bizId)` | List templates |
| `POST` | `/business/{bizId}/recurring-invoices` | `createRecurringInvoice(token, bizId, body)` | Create template |
| `PUT` | `/business/recurring-invoices/{id}` | `updateRecurringInvoice(token, id, body)` | Update/pause/resume |
| `POST` | `/business/recurring-invoices/{id}/cancel` | `cancelRecurringInvoice(token, id)` | Cancel template |

**Update body for pause/resume:** `{"is_active": false}` or `{"is_active": true}`

**When returning recurring invoices, include `unpaid_count`:**
```sql
SELECT ri.*, (
    SELECT COUNT(*) FROM business_invoices
    WHERE recurring_invoice_id = ri.id
    AND status NOT IN ('paid', 'void', 'cancelled')
) AS unpaid_count
FROM business_recurring_invoices ri WHERE ri.business_id = ?
```

### J. Quote Conversion (existing endpoint)

| Method | URL | Flutter Method | Purpose |
|--------|-----|----------------|---------|
| `POST` | `/business/quotes/{id}/convert` | `convertQuoteToInvoice(token, id)` | Server-side conversion |

**Note:** The frontend also supports client-side conversion by navigating to CreateInvoicePage with `sourceQuote` prefilled, then calling `createInvoice` with `source_quote_id`. Both paths should work.

---

## Invoice Number Generation

```php
private function generateInvoiceNumber($businessId) {
    $settings = DB::table('business_invoice_settings')
        ->where('business_id', $businessId)->first();

    if (!$settings) {
        DB::table('business_invoice_settings')->insert([
            'business_id' => $businessId,
            'created_at' => now(), 'updated_at' => now()
        ]);
        $settings = (object)['number_prefix' => 'INV', 'next_sequence' => 1];
    }

    $prefix = $settings->number_prefix ?? 'INV';
    $seq = $settings->next_sequence ?? 1;
    $year = date('Y');
    $number = sprintf('%s-%s-%04d', $prefix, $year, $seq);

    DB::table('business_invoice_settings')
        ->where('business_id', $businessId)
        ->update(['next_sequence' => $seq + 1, 'updated_at' => now()]);

    return $number;
}
```

Credit note numbers: same pattern with prefix `CN`.

---

## Route Registration

Add to `routes/api.php`:

```php
// Invoice module routes
Route::prefix('business')->controller(MyBusinessController::class)->group(function () {
    // Invoice CRUD
    Route::get('{businessId}/invoices', 'getInvoices');
    Route::get('{businessId}/invoices/summary', 'getInvoiceSummary');
    Route::post('{businessId}/invoices', 'createInvoice');
    Route::get('invoices/{invoiceId}', 'getInvoice');
    Route::put('invoices/{invoiceId}', 'updateInvoice');
    Route::post('invoices/{invoiceId}/void', 'voidInvoice');
    Route::get('invoices/{invoiceId}/pdf', 'getInvoicePdf');

    // Delivery
    Route::post('invoices/{invoiceId}/send', 'sendInvoiceMultiChannel');
    Route::post('invoices/{invoiceId}/remind', 'sendInvoiceReminder');
    Route::get('invoices/{invoiceId}/deliveries', 'getInvoiceDeliveries');

    // Payments
    Route::post('invoices/{invoiceId}/payments', 'recordInvoicePayment');
    Route::get('invoices/{invoiceId}/payments', 'getInvoicePayments');
    Route::post('invoices/{invoiceId}/paid', 'markInvoicePaid');

    // Credit Notes
    Route::post('invoices/{invoiceId}/credit-notes', 'createCreditNote');
    Route::get('invoices/{invoiceId}/credit-notes', 'getInvoiceCreditNotes');

    // VFD
    Route::post('invoices/{invoiceId}/vfd', 'generateVfdReceipt');
    Route::post('invoices/{invoiceId}/vfd/retry', 'retryVfdReceipt');

    // Settings
    Route::get('{businessId}/invoice-settings', 'getInvoiceSettings');
    Route::put('{businessId}/invoice-settings', 'updateInvoiceSettings');
    Route::post('{businessId}/invoice-settings/logo', 'uploadInvoiceLogo');

    // Recurring (extend existing)
    Route::get('{businessId}/recurring-invoices', 'getRecurringInvoices');
    Route::post('{businessId}/recurring-invoices', 'createRecurringInvoice');
    Route::put('recurring-invoices/{id}', 'updateRecurringInvoice');
    Route::post('recurring-invoices/{id}/cancel', 'cancelRecurringInvoice');
});

// Customer-side (outside /business/ prefix)
Route::get('invoices/received', [MyBusinessController::class, 'getReceivedInvoices']);
```

---

## Scheduled Jobs

Add to `app/Console/Kernel.php`:

### 1. Auto-generate recurring invoices (hourly)

```php
$schedule->call(function () {
    $templates = DB::table('business_recurring_invoices')
        ->where('is_active', true)
        ->where('next_issue_date', '<=', now())
        ->get();

    foreach ($templates as $t) {
        // Create invoice from template
        $invNumber = $this->generateInvoiceNumber($t->business_id);
        $invoiceId = DB::table('business_invoices')->insertGetId([
            'business_id' => $t->business_id,
            'invoice_number' => $invNumber,
            'customer_id' => $t->customer_id,
            'customer_name' => $t->customer_name,
            'items' => $t->items,
            'subtotal' => $t->subtotal,
            'vat_amount' => $t->vat_amount,
            'total_amount' => $t->total_amount,
            'status' => $t->auto_send ? 'sent' : 'draft',
            'recurring_invoice_id' => $t->id,
            'due_date' => now()->addDays(30),
            'payment_terms' => $t->payment_terms,
            'notes' => $t->notes,
            'created_at' => now(),
            'updated_at' => now(),
        ]);

        // Auto-send if configured
        if ($t->auto_send && $t->auto_send_channels) {
            $channels = json_decode($t->auto_send_channels, true) ?? [];
            // Send via each channel...
        }

        // Update template
        $nextDate = $this->calculateNextDate($t);
        $issued = $t->total_issued + 1;
        $active = true;
        if ($t->max_invoices && $issued >= $t->max_invoices) $active = false;
        if ($t->end_date && $nextDate > $t->end_date) $active = false;

        DB::table('business_recurring_invoices')
            ->where('id', $t->id)
            ->update([
                'next_issue_date' => $nextDate,
                'total_issued' => $issued,
                'is_active' => $active,
            ]);
    }
})->hourly();
```

### 2. Auto-send overdue reminders (daily 9am EAT)

```php
$schedule->call(function () {
    $settings = DB::table('business_invoice_settings')
        ->where('auto_reminder_enabled', true)->get();

    foreach ($settings as $s) {
        $reminderDays = json_decode($s->reminder_days_after_due, true) ?? [];
        $invoices = DB::table('business_invoices')
            ->where('business_id', $s->business_id)
            ->whereNotIn('status', ['paid', 'void', 'cancelled', 'draft'])
            ->where('due_date', '<', now())
            ->get();

        foreach ($invoices as $inv) {
            $daysOverdue = now()->diffInDays($inv->due_date);
            if (in_array($daysOverdue, $reminderDays)) {
                // Check no reminder sent today
                $sentToday = DB::table('business_invoice_deliveries')
                    ->where('invoice_id', $inv->id)
                    ->where('delivery_type', 'reminder')
                    ->whereDate('sent_at', today())
                    ->exists();

                if (!$sentToday) {
                    // Send reminder via configured channels
                    $channels = json_decode($s->reminder_channels, true) ?? ['email'];
                    foreach ($channels as $channel) {
                        // Send + create delivery record
                    }
                }
            }
        }
    }
})->dailyAt('09:00');
```

### 3. VFD retry queue (every 15 minutes)

```php
$schedule->call(function () {
    $invoices = DB::table('business_invoices')
        ->where('status', 'paid')
        ->whereNull('vfd_receipt_number')
        ->where('paid_at', '>', now()->subDay())
        ->get();

    foreach ($invoices as $inv) {
        // Retry VFD generation (max 3 attempts tracked via a retry_count column or log)
        // Call TRA API...
    }
})->everyFifteenMinutes();
```

---

## Cross-Module Side Effects

### On payment recorded:
- Insert income record (`income_records` table if exists)
- If wallet payment: insert expenditure on customer side
- FCM push to business owner

### On invoice fully paid:
- Trigger VFD receipt generation (queue job)
- FCM push "Invoice #{number} fully paid!"

### On credit note issued:
- Insert negative income record
- Trigger reverse VFD receipt
- If wallet_refund: wallet transfer
- FCM push to customer

### On invoice sent (in-app):
- FCM push to customer with invoice details
- Create entry in customer's notification feed

---

## Implementation Priority

1. **Invoice CRUD** — `getInvoices`, `createInvoice`, `getInvoice`, `updateInvoice`, `voidInvoice` + invoice number generation + settings auto-create
2. **Payments** — `recordInvoicePayment`, `getInvoicePayments` + amount_paid recalculation + status transition
3. **Delivery** — `sendInvoiceMultiChannel`, `sendInvoiceReminder`, `getInvoiceDeliveries`
4. **Settings** — `getInvoiceSettings`, `updateInvoiceSettings`
5. **Credit Notes** — `createCreditNote`, `getInvoiceCreditNotes`
6. **Summary** — `getInvoiceSummary`
7. **Received Invoices** — `getReceivedInvoices` (customer side)
8. **VFD** — `generateVfdReceipt`, `retryVfdReceipt` (TRA API integration)
9. **Invoice PDF** — `getInvoicePdf` (PDF generation with business branding)
10. **Logo Upload** — `uploadInvoiceLogo`
11. **Recurring Extensions** — `unpaid_count` in response, new columns
12. **Scheduled Jobs** — recurring generation, auto-reminders, VFD retry
13. **Cross-Module** — IncomeService, ExpenditureService, FCM notifications

## Testing

After implementing each endpoint:

```bash
# Test create
curl -s -X POST "https://tajiri.zimasystems.com/api/business/1/invoices" \
  -H "Content-Type: application/json" \
  -H "Authorization: Bearer {token}" \
  -d '{"customer_name":"Test","items":[{"description":"Test","quantity":1,"unit_price":10000,"total_price":10000}],"subtotal":10000,"vat_amount":1800,"total_amount":11800,"status":"draft"}' | python3 -m json.tool

# Test list
curl -s "https://tajiri.zimasystems.com/api/business/1/invoices" \
  -H "Authorization: Bearer {token}" | python3 -m json.tool

# Test payment
curl -s -X POST "https://tajiri.zimasystems.com/api/business/invoices/{id}/payments" \
  -H "Content-Type: application/json" \
  -H "Authorization: Bearer {token}" \
  -d '{"amount":11800,"method":"mpesa","reference":"ABC123","paid_at":"2026-04-16T10:00:00Z","recorded_by":"manual"}' | python3 -m json.tool

# Test settings
curl -s "https://tajiri.zimasystems.com/api/business/1/invoice-settings" \
  -H "Authorization: Bearer {token}" | python3 -m json.tool

# Test received (customer side)
curl -s "https://tajiri.zimasystems.com/api/invoices/received?user_id=32" \
  -H "Authorization: Bearer {token}" | python3 -m json.tool
```
