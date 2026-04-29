# Invoices — Business Invoice Lifecycle System

## Tanzania Context

An invoice is the moment a business says "you owe me money for work I did." It is the bridge between delivering value and getting paid. In Tanzania, this bridge is broken for most SMEs:

**Cash flow kills businesses.** The number one cause of SME death in Tanzania is not lack of customers — it's late payments. A fundi finishes a job and waits 3 months to get paid. A supplier delivers goods and the retailer says "nitakulipa mwezi ujao" (I'll pay you next month). Invoices sit as WhatsApp messages or handwritten notes with no tracking, no reminders, and no follow-up. Money owed is money forgotten.

**Informality is the default.** Most Tanzanian businesses don't issue proper invoices. A carpenter finishes cabinets and tells the customer "ni laki tatu" (it's 300,000) verbally. No record, no TIN, no VAT breakdown. When TRA asks for documentation, there's nothing. When the customer disputes the amount, it's word against word. A professional invoice with business details, line items, and a reference number is a competitive advantage — it signals legitimacy.

**TRA compliance is not optional.** Tanzania Revenue Authority requires businesses to issue fiscal receipts through the Virtual Fiscal Device (VFD) system. Every sale must generate a VFD receipt. Businesses that invoice outside the VFD system risk penalties. The invoice and the fiscal receipt must be connected — not separate workflows that a busy business owner has to manually reconcile.

**Customers pay every way imaginable.** M-Pesa, Tigo Pesa, Airtel Money, bank transfer, cash, and now TAJIRI wallet. A business sends an invoice and has no idea which channel the customer will use to pay. The invoice system must accept all of these and track them all in one place.

**"Kidogo kidogo" is how business works.** Partial payments are the norm, not the exception. A TZS 500,000 invoice gets paid TZS 200,000 now, TZS 150,000 next week, and the rest "soon." Without a system tracking partial payments against each invoice, businesses lose track of who owes what. The accounting becomes guesswork.

**Recurring relationships are the backbone.** Landlords invoice tenants monthly. Suppliers invoice retailers on credit terms. Service providers bill retainer clients quarterly. These aren't one-off transactions — they're the heartbeat of B2B commerce. A business that manually creates the same invoice every month is wasting hours that should go to actual work.

## Scope

Invoices are scoped to the **business module** (`lib/business/`). Only registered businesses with a valid business profile can create and send invoices. This is not a general-purpose billing tool — it's a formal business document system that requires TIN, VRN, and business registration.

Currency is **TZS only** — keeping integration with TRA/VFD straightforward and wallet reconciliation clean.

## International Reference Apps

1. **Wave (Free Invoicing)** — The gold standard for small business invoicing. Clean invoice creation, automatic payment tracking, recurring invoices, client management, financial reporting. Key insight we adopt: **invoicing and accounting are one system**, not separate tools. Wave connects invoices to income tracking automatically.

2. **Zoho Invoice** — Professional invoice templates with multi-channel delivery (email, SMS, client portal). Real-time tracking shows when the client views the invoice. Key insight we adopt: **delivery tracking changes business behavior** — knowing your customer saw the invoice 3 days ago and hasn't paid is actionable information.

3. **Invoice Ninja** — Open-source invoicing with partial payments, deposits, credits, and flexible payment terms. Key insight we adopt: **partial payment tracking as a first-class concept** — not an afterthought. Every payment against an invoice is recorded with method, reference, and date.

4. **QuickBooks** — Full accounting integration where invoices feed directly into profit/loss, tax reports, and cash flow projections. Key insight we adopt: **invoices as the entry point for financial data** — every invoice paid feeds into budget tracking, tax reporting, and business analytics.

5. **Kashoo** — Simple invoicing with direct M-Pesa integration for East African markets. Receipts generated automatically. Key insight we adopt: **mobile money is a first-class payment method**, not a workaround.

6. **Blinksale** — Minimalist invoicing focused on speed. Create and send an invoice in under 60 seconds. Key insight we adopt: **speed of creation matters** — if it takes 10 minutes to create an invoice, businesses won't do it. Saved templates, customer autofill, and smart defaults make invoicing fast enough to do on the spot.

7. **FreshBooks** — Client-facing invoice portal where customers view invoices, see payment history, and pay online. Key insight we adopt: **the customer-facing experience matters** — a professional payment page builds trust and reduces payment friction.

## How It Works

### The Invoice Lifecycle

```
┌──────────────────────────────────────────────────────────────────┐
│                    INVOICE LIFECYCLE                              │
│                                                                  │
│  ┌───────┐    ┌──────┐    ┌───────────┐    ┌────────┐           │
│  │ DRAFT │───▶│ SENT │───▶│ DELIVERED │───▶│ VIEWED │           │
│  └───────┘    └──────┘    └───────────┘    └────────┘           │
│      │                                        │                  │
│      │ (void)                    ┌────────────┤                  │
│      ▼                          ▼             ▼                  │
│  ┌──────┐              ┌───────────────┐  ┌──────┐              │
│  │ VOID │              │ PARTIALLY_PAID│─▶│ PAID │              │
│  └──────┘              └───────────────┘  └──────┘              │
│                                               │                  │
│                                               ▼                  │
│                                        ┌──────────────┐         │
│                                        │  VFD RECEIPT  │         │
│                                        └──────────────┘         │
│                                               │                  │
│                                               ▼ (if needed)     │
│                                        ┌──────────────┐         │
│                                        │ CREDIT NOTE  │         │
│                                        │ + REVERSE VFD│         │
│                                        └──────────────┘         │
└──────────────────────────────────────────────────────────────────┘
```

**Overdue** is a computed status, not a stored one — any invoice past its due date that isn't fully paid is overdue. The UI highlights it, but the underlying status remains `sent`, `delivered`, `viewed`, or `partially_paid`.

### Quote → Invoice → VFD Pipeline

```
┌──────────────────────────────────────────────────────────────────┐
│                                                                  │
│   QUOTE / RFQ                     INVOICE                        │
│   ┌─────────────┐                ┌─────────────┐                │
│   │ Create Quote │──(accepted)──▶│Create Invoice│                │
│   │ or RFQ       │   converts    │ (pre-filled) │                │
│   └─────────────┘                └──────┬──────┘                │
│                                         │                        │
│                                    Send → Pay                    │
│                                         │                        │
│                                         ▼                        │
│                                  ┌─────────────┐                │
│                                  │ VFD Receipt  │                │
│                                  │ (auto TRA)   │                │
│                                  └─────────────┘                │
│                                                                  │
│   Quote.convertedInvoiceId ◄──── Invoice.sourceQuoteId          │
│   RfqResponse.id ◄──────────── Invoice.sourceRfqResponseId     │
│                                                                  │
└──────────────────────────────────────────────────────────────────┘
```

When a quote is accepted or an RFQ response is chosen, the business taps "Convert to Invoice." All line items, customer details, VAT settings, and notes carry over. The quote is marked as `converted` and linked to the new invoice via `convertedInvoiceId`. The invoice stores `sourceQuoteId` or `sourceRfqResponseId` for traceability.

### Delivery Channels

```
┌─────────────┐
│   INVOICE   │
│  (ready to  │
│    send)    │
└──────┬──────┘
       │
       ├──▶ WhatsApp  ── PDF attachment + pre-filled message
       │
       ├──▶ In-App    ── notification + "Pay Now" in wallet
       │                  (TAJIRI users only)
       │
       ├──▶ Email     ── HTML email + PDF + "Pay Online" button
       │
       └──▶ PDF       ── download / print for physical delivery
```

Each send creates a delivery record. Multiple channels can be used for the same invoice (send via WhatsApp first, then email as follow-up). The business sees a timeline of all delivery attempts and their statuses.

### Payment Flow

```
┌─────────────────────────────────────────────────────────────┐
│                    PAYMENT PATHS                             │
│                                                             │
│  Path A: TAJIRI Wallet (auto-reconciled)                    │
│  ┌──────────┐    ┌────────────┐    ┌──────────────────┐    │
│  │ Customer │───▶│ Pay button │───▶│ Wallet → Business │    │
│  │ views    │    │ on invoice │    │ wallet transfer   │    │
│  │ invoice  │    └────────────┘    └────────┬─────────┘    │
│  └──────────┘                               │               │
│                                    auto-creates              │
│                                    InvoicePayment            │
│                                    + updates status          │
│                                                             │
│  Path B: External (manually recorded)                       │
│  ┌──────────┐    ┌────────────┐    ┌──────────────────┐    │
│  │ Customer │───▶│ Pays via   │───▶│ Business records │    │
│  │ receives │    │ M-Pesa /   │    │ payment manually │    │
│  │ invoice  │    │ bank /cash │    │ with reference   │    │
│  └──────────┘    └────────────┘    └────────┬─────────┘    │
│                                             │               │
│                                    creates                  │
│                                    InvoicePayment           │
│                                    + updates status         │
│                                                             │
│  Both paths:                                                │
│  if (totalPaid >= totalAmount) → status = paid → VFD        │
│  else → status = partially_paid                             │
└─────────────────────────────────────────────────────────────┘
```

## Feature List

### Invoice Dashboard (Top of Invoice Screen)
1. Hero cards: Total Outstanding (unpaid invoices), Total Overdue, Revenue This Month (paid invoices)
2. Aging summary: 0–30 days, 31–60 days, 61–90 days, 90+ days overdue
3. Quick action: "Unda Ankara Mpya" / "Create New Invoice" prominent button
4. Revenue trend: mini sparkline showing monthly invoice revenue over last 6 months

### Invoice Creation
5. Customer picker from existing customer list with search
6. Add new customer inline (name, phone, email, TIN — saved to customer list)
7. Line items builder: description, quantity, unit label (pcs/hrs/kg/m²/etc.), unit price
8. Link line item to product/service from business catalog (optional — auto-fills description + price)
9. Per-item VAT flag: include or exempt (some goods are VAT-exempt in Tanzania)
10. VAT calculation at 18% standard rate, with exempt items separated
11. Discount: percentage or fixed amount applied to subtotal
12. Due date picker with quick presets: Net 7, Net 14, Net 30, Net 60, Custom
13. Payment terms text: free-text field for special terms (e.g., "50% upfront, 50% on delivery")
14. Payment instructions: M-Pesa number, bank account details, TAJIRI wallet info
15. Notes field: bilingual notes/terms visible on the invoice
16. Auto-generated invoice number: `INV-{YYYY}-{sequential}` (editable prefix in business settings)
17. Business details auto-populated from business profile (name, TIN, VRN, address, phone, logo)
18. Save as draft without sending
19. Preview before sending: full invoice rendered as it will appear to the customer
20. Invoice templates: save a frequently-used invoice as a template for quick reuse

### Invoice from Quote / RFQ
21. "Convert to Invoice" button on accepted quotes — all line items, customer, VAT carry over
22. "Convert to Invoice" button on accepted RFQ responses — same auto-population
23. Source quote/RFQ reference shown on the invoice ("Based on Quote #QT-2026-015")
24. Converted quote status updates to `converted` with link to generated invoice
25. If quote had special terms or notes, they carry into the invoice notes field
26. Line items can be edited after conversion (quantities may change between quote and final invoice)

### Sending & Delivery
27. Send via WhatsApp: generates PDF, opens WhatsApp share with pre-filled bilingual message
28. Send via in-app: invoice appears in customer's TAJIRI notifications with "Pay Now" action (customer must be TAJIRI user)
29. Send via email: professional HTML email with invoice summary + PDF attachment + "Pay Online" button
30. Download PDF: branded PDF with business logo, QR code for online payment, TRA-compliant layout
31. Print-ready PDF formatting for physical delivery
32. Multi-channel send: use multiple channels for the same invoice (WhatsApp + email)
33. Delivery tracking per channel: pending → sent → delivered → viewed
34. Resend invoice: resend via any channel with one tap
35. Send reminder: send a follow-up reminder for unpaid/overdue invoices with days-overdue context

### Delivery Tracking
36. Per-invoice delivery timeline: "Sent via WhatsApp 2hrs ago → Delivered → Not yet viewed"
37. Email open tracking: track when customer opens the email
38. In-app view tracking: track when customer opens the invoice in TAJIRI
39. WhatsApp delivery status via share confirmation
40. Batch view: see delivery status across all outstanding invoices at a glance

### Payments
41. "Record Payment" action on any unpaid invoice
42. Payment entry: amount, method (wallet/M-Pesa/Tigo Pesa/Airtel Money/bank/cash), reference number, date, notes
43. Wallet payment: customer taps "Pay Now" on in-app invoice → wallet-to-wallet transfer → auto-reconciled
44. Partial payment support: any amount less than balance creates a partial payment
45. Payment progress bar on invoice card: TZS 200,000 / 500,000 (40%)
46. Payment history on invoice detail: list of all payments with dates, amounts, methods, references
47. Auto-status update: partially_paid when partial, paid when total payments >= invoice total
48. Remaining balance displayed prominently on partially-paid invoices
49. Payment receipt: each payment (partial or full) generates a receipt
50. Overpayment handling: warn if payment would exceed invoice balance, allow with note

### Partial Payment UX
51. Outstanding balance card on invoice detail showing: total, paid so far, remaining
52. "Lipa Kiasi" / "Pay Partial" button distinct from "Lipa Yote" / "Pay Full"
53. Payment schedule suggestion: for large invoices, suggest splitting into installments
54. Reminder for remaining balance: auto-reminder X days after last partial payment
55. Aging per invoice: how many days since last payment activity

### VFD / TRA Integration
56. On full payment: auto-trigger VFD receipt generation via TRA API
57. VFD receipt number stored and displayed on invoice
58. VFD receipt downloadable as PDF from invoice detail
59. Failed VFD submissions: queued for retry with alert to business owner
60. VFD receipt data: TIN, VRN, items with HS codes, VAT breakdown, payment method, receipt timestamp
61. All VFD fields captured during invoice creation (item codes, tax categories)
62. VFD receipt link shareable with customer as proof of fiscal compliance
63. Monthly VFD summary: all receipts issued, total VAT collected, TRA report-ready data

### Credit Notes
64. "Issue Credit Note" action on paid/partially-paid invoices
65. Select line items to credit: full items or partial quantities
66. Credit note reason: goods returned, service not delivered, pricing error, other (free text)
67. Credit note number: auto-generated `CN-{YYYY}-{sequential}`
68. Credit note PDF: same branding as invoice, references original invoice
69. Reverse VFD receipt: auto-triggered when credit note is issued
70. Original invoice marked as `credit_noted` with link to credit note
71. Credit application: credit amount can be applied to customer's next invoice or refunded to wallet
72. Credit note delivery: same channels as invoice (WhatsApp, email, in-app, PDF)

### Recurring Invoices
73. Create recurring invoice template: same fields as regular invoice + schedule
74. Schedule options: weekly, monthly, quarterly, annually, custom interval
75. Auto-generate: recurring template auto-creates a real invoice on schedule
76. Auto-send: generated invoice auto-sends via chosen channel (optional — can be draft-only)
77. Smart numbering: each generated invoice gets the next sequential number
78. End conditions: end date, number of cycles, or manual cancellation
79. Late payment flag: if previous recurring invoice is unpaid, alert before generating the next one
80. Pause/resume: temporarily pause a recurring invoice without deleting it
81. Edit template: changes apply to future generated invoices, not past ones
82. History: list of all invoices generated from a recurring template

### Reminders & Notifications
83. Auto-reminder for overdue invoices: configurable — 1 day, 3 days, 7 days, 14 days after due date
84. Payment received notification: "Ankara #042 imelipwa TZS 850,000" / "Invoice #042 paid TZS 850,000"
85. Partial payment notification: "Ankara #042: TZS 200,000 imelipwa, baki TZS 300,000" / "Invoice #042: TZS 200,000 paid, balance TZS 300,000"
86. Invoice viewed notification: "Mteja ameangalia ankara #042" / "Customer viewed invoice #042"
87. Overdue alert: "Ankara #042 imechelewa siku 7 — TZS 500,000" / "Invoice #042 is 7 days overdue — TZS 500,000"
88. Weekly outstanding summary: total unpaid, total overdue, top 5 overdue invoices
89. Recurring invoice generated notification: "Ankara ya kila mwezi imetolewa kwa [Customer]"
90. VFD failure alert: "Risiti ya VFD haijatoka kwa ankara #042 — jaribu tena"
91. Credit note issued notification to customer

### Invoice Settings (per business)
92. Invoice number prefix: customizable (default: `INV`)
93. Default payment terms: Net 7 / Net 14 / Net 30 / Net 60
94. Default VAT inclusion: on/off
95. Default payment instructions: M-Pesa number, bank details (auto-populate on new invoices)
96. Default notes/terms: standard footer text for all invoices
97. Auto-reminder settings: enable/disable, timing after due date
98. Business logo on invoices: upload once, appears on all PDFs
99. Invoice color accent: subtle branding color on PDF layout (within monochrome design system)

## Key Screens

1. **Invoice Dashboard** — Hero cards (outstanding, overdue, monthly revenue), aging report, invoice list with status tabs (All / Drafts / Sent / Paid / Overdue), search by number/customer, FAB to create
2. **Create Invoice** — Customer picker, line items builder with catalog search, VAT/discount/due date, payment instructions, notes, template save, preview
3. **Invoice Detail** — Full invoice view (header, items, totals), delivery timeline, payment history with progress bar, action buttons (send, remind, record payment, credit note, void, download PDF, share)
4. **Send Invoice** — Channel picker (WhatsApp / Email / In-App), message preview, recipient confirmation, send button
5. **Record Payment** — Amount input (with remaining balance shown), method picker, reference number, date picker, notes
6. **Credit Note** — Select items to credit (checkboxes with quantity adjustment), reason picker, preview, issue button
7. **Invoice Preview** — Full rendered invoice as customer will see it (PDF-like view), approve and send or back to edit
8. **Recurring Invoices** — List of recurring templates with schedule, status (active/paused/cancelled), generated invoice history, create new template
9. **Invoice Settings** — Number prefix, default terms, default payment instructions, reminder settings, logo upload

## TAJIRI Integration Points

### Quotes & RFQ System (`lib/business/pages/quotes_page.dart`, `create_quote_page.dart`)

The quote-to-invoice pipeline is the primary integration:

| Quote/RFQ Action | Invoice Integration |
|---|---|
| Quote accepted by customer | "Convert to Invoice" button appears — one tap creates pre-filled invoice |
| RFQ response accepted by buyer | Same "Convert to Invoice" flow — RFQ response items → invoice line items |
| Quote converted | Quote status → `converted`, `convertedInvoiceId` set to new invoice ID |
| Invoice created from quote | `sourceQuoteId` on invoice references the original quote |
| Invoice created from RFQ | `sourceRfqResponseId` on invoice references the RFQ response |
| Line item model | Shared `InvoiceItem` class used by both Quote and Invoice |

**Conversion rules:**
- All line items carry over with descriptions, quantities, unit prices
- Customer details carry over from quote
- VAT settings carry over
- Notes carry over with editable option
- Quantities/prices CAN be edited post-conversion (final invoice may differ from quote)
- Converted quote cannot be converted again (one quote → one invoice)

### Customer List (`lib/business/`)

| Action | Integration |
|---|---|
| Invoice creation | Customer picker pulls from business customer list |
| New customer on invoice | "Add New Customer" saves to customer list for reuse |
| Customer detail | Shows all invoices for that customer, total outstanding, payment history |
| Customer statement | Generate PDF statement showing all invoices + payments for a date range |

### Business Wallet (`lib/my_wallet/`)

| Action | Integration |
|---|---|
| In-app payment | Customer taps "Pay Now" → wallet-to-wallet transfer → auto-recorded on invoice |
| Payment received | Business wallet balance updates, invoice status auto-updates |
| Income recording | Paid invoice triggers `IncomeService.recordIncome()` with source = `invoice_payment` |
| Refund via credit note | Credit note with wallet refund → wallet-to-wallet transfer back to customer |

### VFD System (`lib/business/pages/vfd_page.dart`)

| Action | Integration |
|---|---|
| Invoice fully paid | Auto-trigger VFD receipt via TRA API |
| Credit note issued | Auto-trigger reverse VFD receipt |
| VFD receipt stored | Linked to invoice, downloadable from invoice detail |
| Monthly VFD report | Aggregates all invoice-triggered VFD receipts |

### Budget Module (`lib/budget/`)

| Action | Integration |
|---|---|
| Invoice paid | `IncomeService.recordIncome(source: 'invoice_payment', sourceModule: 'business')` |
| Budget tracking | Invoice revenue feeds into Biashara (Business Expenses) envelope as income |
| Monthly report | Invoice revenue appears in income breakdown |

### Expenses (`lib/business/pages/expenses_page.dart`)

| Action | Integration |
|---|---|
| Business P&L | Invoice revenue (paid invoices) shown as income against recorded expenses |
| Profitability | Revenue from invoices minus business expenses = business profit |

### LiveUpdateService / FCM

| Event | Response |
|---|---|
| Invoice paid (wallet) | Real-time notification to business owner |
| Invoice viewed (in-app) | Real-time "viewed" status update |
| Payment received | Push notification with amount and invoice number |
| Overdue trigger | Background check triggers overdue reminder push |

### ExpenditureService (Customer Side)

| Action | Integration |
|---|---|
| Customer pays invoice via wallet | `ExpenditureService.recordExpenditure()` on customer side |
| Category | Auto-categorized based on business type or customer assigns envelope |

## Data Model

### Invoice
```
Invoice {
  id                    → backend ID
  businessId            → owning business
  invoiceNumber         → auto-generated "INV-2026-042" (prefix configurable)
  customerId            → linked customer (nullable for one-off customers)
  customerName          → display name
  customerPhone         → phone number
  customerEmail         → email address
  customerTin           → TIN for B2B invoices
  items                 → List<InvoiceItem> — line items
  subtotal              → sum of line item totals
  discountType          → percentage | fixed
  discountValue         → discount amount or percentage
  discountAmount        → calculated discount in TZS
  vatRate               → 18.0 (standard Tanzania VAT)
  vatAmount             → VAT calculated on taxable items
  totalAmount           → subtotal - discount + VAT
  amountPaid            → sum of all InvoicePayments
  balanceRemaining      → totalAmount - amountPaid
  status                → draft | sent | delivered | viewed | partially_paid | paid | void | credit_noted
  dueDate               → payment due date
  paymentTerms          → "Net 30", free text
  paymentInstructions   → M-Pesa number, bank details, etc.
  notes                 → bilingual notes/terms
  sourceQuoteId         → if converted from a quote (nullable)
  sourceRfqResponseId   → if converted from an RFQ response (nullable)
  recurringInvoiceId    → if generated from a recurring template (nullable)
  vfdReceiptNumber      → TRA fiscal receipt number (nullable, set on payment)
  vfdReceiptUrl         → downloadable VFD receipt (nullable)
  createdAt             → creation timestamp
  paidAt                → full payment timestamp (nullable)
  voidedAt              → void timestamp (nullable)
}
```

### InvoiceItem
```
InvoiceItem {
  description           → line item description
  quantity              → quantity (decimal for partial units)
  unitLabel             → pcs | hrs | kg | m² | liters | custom
  unitPrice             → price per unit in TZS
  totalPrice            → quantity × unitPrice
  productId             → linked catalog product (nullable)
  isVatExempt           → whether this item is VAT-exempt
}
```

### InvoicePayment
```
InvoicePayment {
  id                    → backend ID
  invoiceId             → linked invoice
  amount                → payment amount in TZS
  method                → wallet | mpesa | tigo_pesa | airtel_money | bank | cash
  reference             → M-Pesa confirmation code, bank ref, etc.
  paidAt                → payment date/time
  recordedBy            → auto | manual
  walletTransactionId   → TAJIRI wallet transaction ID (nullable, for auto-reconciled)
  notes                 → optional payment note
  createdAt             → record creation timestamp
}
```

### InvoiceDelivery
```
InvoiceDelivery {
  id                    → backend ID
  invoiceId             → linked invoice
  channel               → whatsapp | in_app | email | pdf_download
  recipientAddress      → phone number, email, or TAJIRI user ID
  sentAt                → when dispatched
  deliveredAt           → confirmed delivery (nullable)
  viewedAt              → customer opened (nullable)
  status                → pending | sent | delivered | viewed | failed
  failureReason         → error message if failed (nullable)
}
```

### CreditNote
```
CreditNote {
  id                    → backend ID
  creditNoteNumber      → auto-generated "CN-2026-008"
  invoiceId             → original invoice
  businessId            → owning business
  customerId            → same customer as original invoice
  items                 → List<CreditNoteItem> — items being credited
  reason                → goods_returned | service_not_delivered | pricing_error | other
  reasonText            → free-text explanation
  subtotal              → sum of credited item totals
  vatAmount             → VAT on credited items
  totalAmount           → total credit amount
  status                → draft | issued
  applicationMethod     → next_invoice | wallet_refund | manual
  appliedToInvoiceId    → if applied to next invoice (nullable)
  walletRefundId        → if refunded to wallet (nullable)
  vfdReverseReceiptNumber → reverse VFD receipt number
  issuedAt              → issue timestamp
  createdAt             → creation timestamp
}
```

### CreditNoteItem
```
CreditNoteItem {
  description           → item description (from original invoice)
  quantity              → quantity being credited
  unitPrice             → original unit price
  totalPrice            → credited amount
  originalInvoiceItemIndex → index in original invoice items list
}
```

### RecurringInvoice
```
RecurringInvoice {
  id                    → backend ID
  businessId            → owning business
  customerId            → customer receiving recurring invoices
  templateItems         → List<InvoiceItem> — template line items
  subtotal              → template subtotal
  vatRate               → template VAT rate
  vatAmount             → template VAT amount
  totalAmount           → template total
  frequency             → weekly | monthly | quarterly | annually | custom
  customIntervalDays    → custom interval in days (nullable)
  nextGenerationDate    → when next invoice will be generated
  endDate               → stop generating after this date (nullable)
  maxCycles             → stop after N invoices (nullable)
  cyclesCompleted       → invoices generated so far
  autoSend              → auto-send via chosen channel on generation
  sendChannel           → whatsapp | email | in_app (nullable, used if autoSend)
  status                → active | paused | cancelled | completed
  notes                 → template notes
  paymentTerms          → template payment terms
  lastGeneratedAt       → when last invoice was generated
  createdAt             → creation timestamp
}
```

### InvoiceSettings (per business, stored in backend + cached locally)
```
InvoiceSettings {
  businessId            → owning business
  numberPrefix          → default "INV", customizable
  nextSequence          → next sequential number
  defaultPaymentTerms   → Net 7 | Net 14 | Net 30 | Net 60
  defaultIncludeVat     → true/false
  defaultPaymentInstructions → M-Pesa, bank details (template text)
  defaultNotes          → standard footer/terms text
  autoReminderEnabled   → enable/disable overdue reminders
  reminderDaysAfterDue  → [1, 3, 7, 14] — when to send reminders
  logoUrl               → business logo for PDF branding
}
```

## Business Rules

1. **Invoice numbers are unique per business.** Format: `{prefix}-{YYYY}-{sequential}`. The prefix is configurable in settings. Sequential number never resets (even across years) to prevent duplicates.

2. **Invoices can only be edited in draft status.** Once sent, the invoice is locked. To change a sent invoice: void it and create a new one, or issue a credit note for partial adjustment.

3. **Void is not delete.** Voided invoices remain in the system for audit trail. They show as "Imefutwa" / "Voided" with a strikethrough visual treatment. Voided invoices are excluded from financial totals.

4. **Partial payments are additive.** Each payment is recorded separately. The invoice tracks `amountPaid` (sum of payments) and `balanceRemaining` (total - paid). Status is `partially_paid` when 0 < amountPaid < totalAmount.

5. **VFD receipt triggers on full payment only.** Partial payments do not generate VFD receipts. When the final payment brings the invoice to fully paid, VFD is triggered. Each partial payment gets a payment receipt (not a fiscal receipt).

6. **Credit notes cannot exceed the original invoice amount.** Total credit notes against an invoice must be ≤ invoice total amount. Multiple credit notes can be issued against one invoice.

7. **Converted quotes are immutable.** Once a quote is converted to an invoice, the quote is marked `converted` and cannot be converted again. The invoice CAN be edited (in draft) — line items may differ from the quote.

8. **Recurring invoices generate real invoices.** A recurring invoice is a template. On each cycle, it creates a full Invoice record that goes through the normal lifecycle. The template is never sent directly.

9. **Due date drives overdue computation.** `isOverdue = status not in [paid, void, credit_noted] AND dueDate < today`. Overdue is a visual/filter state, not a database status.

10. **Delivery tracking is best-effort.** WhatsApp delivery relies on share confirmation (no guaranteed tracking). Email tracking uses open pixels (not 100% reliable). In-app tracking is precise. The system shows what it knows without promising certainty.

11. **Payment instructions are per-invoice.** Default from settings but editable per invoice. A business might have different M-Pesa numbers for different product lines.

12. **Customer TIN is optional but encouraged for B2B.** If customer TIN is provided, it appears on the invoice and VFD receipt. The system nudges: "Ongeza TIN ya mteja kwa ankara rasmi zaidi" / "Add customer TIN for a more official invoice."
