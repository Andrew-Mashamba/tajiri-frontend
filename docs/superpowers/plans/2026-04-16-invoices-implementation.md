# Invoices Implementation Plan

> **For agentic workers:** REQUIRED SUB-SKILL: Use superpowers:subagent-driven-development (recommended) or superpowers:executing-plans to implement this plan task-by-task. Steps use checkbox (`- [ ]`) syntax for tracking.

**Goal:** Implement the complete invoice lifecycle system within the business module — creation with TAJIRI user/business search, detail view, payments, delivery, credit notes, recurring, settings, analytics, and customer-side wallet payment.

**Architecture:** Extends existing `lib/business/` module. New models added to `business_models.dart`, new service methods added to `business_service.dart`, new pages under `lib/business/pages/`. Follows existing patterns: static service methods, `fromJson` factories with null-safe parsers, bilingual UI, black pill buttons, embedded tab pages without AppBar.

**Tech Stack:** Flutter/Dart, http package, Hive (LocalStorageService), PeopleSearchService for user search, BusinessService for business search, existing InvoiceItem model shared with quotes.

---

## Sub-Project Breakdown

### Sub-Project 1: Core Invoice CRUD (Tasks 1-7)
Models, service methods, enhanced create invoice with customer search, invoice detail page, preview, quote-to-invoice conversion. Foundation for everything else.

### Sub-Project 2: Delivery & Payments (Tasks 8-11)
Send invoice (multi-channel sheet), record payment (partial payments), send reminder, payment progress UI on cards.

### Sub-Project 3: Credit Notes & VFD (Tasks 12-14)
Credit note model + page, VFD receipt section on invoice detail, reverse VFD on credit note.

### Sub-Project 4: Recurring, Settings, Reports & Customer Side (Tasks 15-19)
Enhanced recurring invoices, invoice settings page, customer statement, analytics/reports page, customer-side wallet pay-now.

---

## SUB-PROJECT 1: Core Invoice CRUD

### Task 1: Extend Invoice Models

**Files:**
- Modify: `lib/business/models/business_models.dart`

- [ ] **Step 1: Add new InvoiceStatus values**

Add `delivered`, `viewed`, `partially_paid`, `credit_noted`, `void_status` to InvoiceStatus enum. Update `_parseInvoiceStatus` and `invoiceStatusLabel`.

```dart
enum InvoiceStatus { draft, sent, delivered, viewed, partially_paid, paid, overdue, cancelled, credit_noted, void_status }

String invoiceStatusLabel(InvoiceStatus s, {bool swahili = false}) {
  switch (s) {
    case InvoiceStatus.draft: return swahili ? 'Rasimu' : 'Draft';
    case InvoiceStatus.sent: return swahili ? 'Imetumwa' : 'Sent';
    case InvoiceStatus.delivered: return swahili ? 'Imepokelewa' : 'Delivered';
    case InvoiceStatus.viewed: return swahili ? 'Imeangaliwa' : 'Viewed';
    case InvoiceStatus.partially_paid: return swahili ? 'Malipo ya sehemu' : 'Partially Paid';
    case InvoiceStatus.paid: return swahili ? 'Imelipwa' : 'Paid';
    case InvoiceStatus.overdue: return swahili ? 'Imechelewa' : 'Overdue';
    case InvoiceStatus.cancelled: return swahili ? 'Imefutwa' : 'Cancelled';
    case InvoiceStatus.credit_noted: return swahili ? 'Nota ya mkopo' : 'Credit Noted';
    case InvoiceStatus.void_status: return swahili ? 'Imebatilishwa' : 'Voided';
  }
}
```

- [ ] **Step 2: Extend Invoice model with new fields**

Add these fields to the Invoice class: `customerPhone`, `customerEmail`, `customerTin`, `customerAddress`, `discountType`, `discountValue`, `discountAmount`, `amountPaid`, `balanceRemaining`, `paymentTerms`, `paymentInstructions`, `sourceQuoteId`, `sourceRfqResponseId`, `recurringInvoiceId`, `vfdReceiptNumber`, `vfdReceiptUrl`, `voidedAt`. Update constructor, fromJson, and toJson.

- [ ] **Step 3: Extend InvoiceItem model**

Add `unitLabel`, `productId`, `isVatExempt` fields to InvoiceItem. Update constructor, fromJson, toJson.

```dart
class InvoiceItem {
  final String description;
  final double quantity;
  final String? unitLabel; // pcs, hrs, kg, m², liters
  final double unitPrice;
  final double totalPrice;
  final int? productId;
  final bool isVatExempt;
  // ...
}
```

- [ ] **Step 4: Add InvoicePayment model**

```dart
class InvoicePayment {
  final int? id;
  final int? invoiceId;
  final double amount;
  final String method; // wallet, mpesa, tigo_pesa, airtel_money, bank, cash
  final String? reference;
  final DateTime? paidAt;
  final String recordedBy; // auto, manual
  final int? walletTransactionId;
  final String? notes;
  final DateTime? createdAt;

  // constructor, fromJson, toJson
}
```

- [ ] **Step 5: Add InvoiceDelivery model**

```dart
class InvoiceDelivery {
  final int? id;
  final int? invoiceId;
  final String channel; // whatsapp, in_app, email, pdf_download
  final String? recipientAddress;
  final DateTime? sentAt;
  final DateTime? deliveredAt;
  final DateTime? viewedAt;
  final String status; // pending, sent, delivered, viewed, failed
  final String? failureReason;

  // constructor, fromJson, toJson
}
```

- [ ] **Step 6: Add CreditNote and CreditNoteItem models**

```dart
class CreditNoteItem {
  final String description;
  final double quantity;
  final double unitPrice;
  final double totalPrice;
  final int? originalInvoiceItemIndex;
  // constructor, fromJson, toJson
}

class CreditNote {
  final int? id;
  final String creditNoteNumber;
  final int? invoiceId;
  final int? businessId;
  final int? customerId;
  final List<CreditNoteItem> items;
  final String reason; // goods_returned, service_not_delivered, pricing_error, other
  final String? reasonText;
  final double subtotal;
  final double vatAmount;
  final double totalAmount;
  final String status; // draft, issued
  final String? applicationMethod; // next_invoice, wallet_refund, manual
  final int? appliedToInvoiceId;
  final int? walletRefundId;
  final String? vfdReverseReceiptNumber;
  final DateTime? issuedAt;
  final DateTime? createdAt;
  // constructor, fromJson, toJson
}
```

- [ ] **Step 7: Add InvoiceSettings model**

```dart
class InvoiceSettings {
  final int? businessId;
  final String numberPrefix;
  final int nextSequence;
  final String defaultPaymentTerms; // net_7, net_14, net_30, net_60
  final bool defaultIncludeVat;
  final String? defaultPaymentInstructions;
  final String? defaultNotes;
  final bool autoReminderEnabled;
  final List<int> reminderDaysAfterDue; // [1, 3, 7, 14]
  final String? logoUrl;
  // constructor, fromJson, toJson
}
```

- [ ] **Step 8: Extend RecurringInvoice model**

Add: `endDate`, `maxCycles`, `autoSend`, `sendChannel`, `status` (active/paused/cancelled/completed), `customIntervalDays`, `paymentTerms`, `notes`. Update fromJson/toJson.

- [ ] **Step 9: Verify compilation**

Run: `flutter analyze lib/business/models/business_models.dart`

---

### Task 2: Extend BusinessService with Invoice API Methods

**Files:**
- Modify: `lib/business/services/business_service.dart`

- [ ] **Step 1: Add invoice CRUD methods**

```dart
// Update existing createInvoice to accept businessId in path
static Future<BusinessResult<Invoice>> createInvoice(String token, int businessId, Map<String, dynamic> body)
  // POST $baseUrl/business/$businessId/invoices

static Future<BusinessResult<Invoice>> updateInvoice(String token, int invoiceId, Map<String, dynamic> body)
  // PUT $baseUrl/business/invoices/$invoiceId

static Future<BusinessResult<Invoice>> getInvoice(String token, int invoiceId)
  // GET $baseUrl/business/invoices/$invoiceId

static Future<BusinessResult<void>> voidInvoice(String token, int invoiceId)
  // POST $baseUrl/business/invoices/$invoiceId/void
```

- [ ] **Step 2: Add payment methods**

```dart
static Future<BusinessResult<InvoicePayment>> recordInvoicePayment(String token, int invoiceId, Map<String, dynamic> body)
  // POST $baseUrl/business/invoices/$invoiceId/payments

static Future<BusinessListResult<InvoicePayment>> getInvoicePayments(String token, int invoiceId)
  // GET $baseUrl/business/invoices/$invoiceId/payments
```

- [ ] **Step 3: Add delivery methods**

```dart
static Future<BusinessResult<void>> sendInvoiceMultiChannel(String token, int invoiceId, Map<String, dynamic> body)
  // POST $baseUrl/business/invoices/$invoiceId/send  (body has channels array)

static Future<BusinessResult<void>> sendInvoiceReminder(String token, int invoiceId, Map<String, dynamic> body)
  // POST $baseUrl/business/invoices/$invoiceId/remind

static Future<BusinessListResult<InvoiceDelivery>> getInvoiceDeliveries(String token, int invoiceId)
  // GET $baseUrl/business/invoices/$invoiceId/deliveries
```

- [ ] **Step 4: Add credit note methods**

```dart
static Future<BusinessResult<CreditNote>> createCreditNote(String token, int invoiceId, Map<String, dynamic> body)
  // POST $baseUrl/business/invoices/$invoiceId/credit-notes

static Future<BusinessListResult<CreditNote>> getInvoiceCreditNotes(String token, int invoiceId)
  // GET $baseUrl/business/invoices/$invoiceId/credit-notes
```

- [ ] **Step 5: Add settings methods**

```dart
static Future<BusinessResult<InvoiceSettings>> getInvoiceSettings(String token, int businessId)
  // GET $baseUrl/business/$businessId/invoice-settings

static Future<BusinessResult<InvoiceSettings>> updateInvoiceSettings(String token, int businessId, Map<String, dynamic> body)
  // PUT $baseUrl/business/$businessId/invoice-settings
```

- [ ] **Step 6: Add invoice stats/summary method**

```dart
static Future<BusinessResult<Map<String, dynamic>>> getInvoiceSummary(String token, int businessId)
  // GET $baseUrl/business/$businessId/invoices/summary
  // Returns: { total_outstanding, total_overdue, revenue_this_month, aging: {...} }
```

- [ ] **Step 7: Verify compilation**

Run: `flutter analyze lib/business/services/business_service.dart`

---

### Task 3: Rewrite InvoicesPage (Dashboard)

**Files:**
- Modify: `lib/business/pages/invoices_page.dart`

Rewrite with: hero summary cards (outstanding/overdue/revenue), aging bar, tab filtering, search, enhanced InvoiceCard with payment progress, black pill button top-right. Keep existing pattern: no AppBar (embedded tab page), `SingleTickerProviderStateMixin`, bilingual.

- [ ] **Step 1: Add state variables for summary data**

Add `_summary` map, `_searchQuery`, hero card calculations from invoice list.

- [ ] **Step 2: Build hero cards section**

Three cards in a Row: Outstanding (amber), Overdue (red), Revenue This Month (green). Each with icon, label, amount.

- [ ] **Step 3: Build aging report bar**

Horizontal colored segments: 0-30 (grey), 31-60 (amber), 61-90 (orange), 90+ (red). Calculated from `_invoices` by comparing `dueDate` to `DateTime.now()`.

- [ ] **Step 4: Add search bar**

TextField above tabs filtering `_invoices` by `invoiceNumber` or `customerName` containing query.

- [ ] **Step 5: Keep tab bar + filtered list + pill button**

Same pattern as existing but with enhanced filtering including `partially_paid` status. Add `overdue` computed filter (any unpaid invoice past due date).

- [ ] **Step 6: Navigate to CreateInvoicePage and InvoiceDetailPage**

Pill button navigates to `CreateInvoicePage`. Card tap navigates to new `InvoiceDetailPage`. Pass invoice data.

- [ ] **Step 7: Verify compilation**

Run: `flutter analyze lib/business/pages/invoices_page.dart`

---

### Task 4: Rewrite CreateInvoicePage with Customer Search

**Files:**
- Modify: `lib/business/pages/create_invoice_page.dart`

Major enhancement: add TAJIRI user/business search (Option B), unit label picker, per-item VAT toggle, discount section, payment terms with presets, payment instructions field.

- [ ] **Step 1: Add customer search state variables**

Add `_peopleSearch` (PeopleSearchService instance), `_targetSearchCtrl`, `_targetSearchFocusNode`, `_searchingTargets`, `_targetUsers`, `_targetBusinessMatches`, `_selectedUserBusinesses`, `_selectedTargetUser`, `_selectedTargetBusiness`, `_targetSearchDebounce`, `_showTajiriSearch` toggle, `_loadingBusinesses`.

- [ ] **Step 2: Add search methods**

Port `_onTargetQueryChanged`, `_searchRequestTargets`, `_selectTargetUser`, `_selectTargetBusiness` from `create_quote_page.dart`. Single-select only (no multi-recipient).

- [ ] **Step 3: Build customer section UI**

Option A: existing dropdown from `_customers` list.
Toggle: "Tafuta kwenye TAJIRI" / "Search on TAJIRI" → shows Option B search field.
Option B: dual-search container (same UI as create_quote_page) with Users/Businesses sections.
When user/business selected → auto-fill customer name, phone, email, TIN from the selected entity.

- [ ] **Step 4: Enhance line items with unit label and VAT toggle**

Add unit label dropdown (pcs/hrs/kg/m²/liters/custom) and per-item VAT exempt toggle to the add-item bottom sheet.

- [ ] **Step 5: Add discount section**

Toggle to show discount. Picker: percentage or fixed amount. Calculate discount in totals.

- [ ] **Step 6: Add payment terms section**

Due date with quick presets (Net 7/14/30/60 chips + custom). Payment terms text field. Payment instructions text field (auto-populated from settings if available).

- [ ] **Step 7: Add quote conversion support**

Accept optional `Quote? sourceQuote` parameter. If provided, pre-fill all fields from quote data. Show "Kutoka Nukuu #[number]" banner. Set `sourceQuoteId` in save body.

- [ ] **Step 8: Update save method**

Build body with all new fields. Call `BusinessService.createInvoice(token, businessId, body)`. Handle edit mode (if invoice passed, call `updateInvoice` instead).

- [ ] **Step 9: Verify compilation**

Run: `flutter analyze lib/business/pages/create_invoice_page.dart`

---

### Task 5: Create InvoiceDetailPage

**Files:**
- Create: `lib/business/pages/invoice_detail_page.dart`

Full invoice detail view with: header, business/customer info, line items, totals, payment progress, payment history, delivery timeline, action bar.

- [ ] **Step 1: Create page scaffold with state**

`StatefulWidget` accepting `Invoice invoice` and `int businessId`. State: `_token`, `_loading`, `_invoice` (refreshable), `_payments`, `_deliveries`, `_creditNotes`.

- [ ] **Step 2: Build header section**

Invoice number (large bold), status chip (color-coded), overdue banner if applicable.

- [ ] **Step 3: Build business and customer info blocks**

Two cards side by side: business details (name, TIN, VRN, address) and customer details (name, phone, email, TIN).

- [ ] **Step 4: Build line items table**

Column headers + item rows. VAT exempt indicator per item. Unit labels shown.

- [ ] **Step 5: Build totals block**

Subtotal, discount, VAT, total, amount paid (green), balance remaining (red/green).

- [ ] **Step 6: Build payment progress bar**

Linear progress indicator: `amountPaid / totalAmount`. Text: "TZS [paid] / TZS [total] ([%]%)".

- [ ] **Step 7: Build payment history section**

List of InvoicePayment cards. Each: date, amount, method icon, reference, auto/manual badge.

- [ ] **Step 8: Build delivery timeline section**

Vertical timeline of InvoiceDelivery records. Channel icon, timestamp, status badge.

- [ ] **Step 9: Build source reference section**

If `sourceQuoteId` set: tappable "Kutoka Nukuu #[number]" chip.

- [ ] **Step 10: Build action bar**

Bottom action bar with context-sensitive buttons based on invoice status:
- Draft: Edit | Send | Void
- Sent/Delivered/Viewed: Send (resend) | Remind | Record Payment
- Partially paid: Record Payment | Remind
- Paid: Credit Note | Download PDF
- All: overflow menu with Download PDF | Share

- [ ] **Step 11: Implement void action**

Confirmation dialog → `BusinessService.voidInvoice()` → refresh.

- [ ] **Step 12: Wire navigation**

Edit → `CreateInvoicePage` with invoice pre-filled. Send → `_showSendSheet()` (placeholder for Sub-project 2). Record Payment → `_showRecordPaymentSheet()` (placeholder for Sub-project 2).

- [ ] **Step 13: Verify compilation**

Run: `flutter analyze lib/business/pages/invoice_detail_page.dart`

---

### Task 6: Enhance InvoiceCard Widget

**Files:**
- Modify: `lib/business/widgets/invoice_card.dart`

Add: payment progress bar, balance remaining, overdue days indicator, partially_paid/viewed/delivered status colors.

- [ ] **Step 1: Add new status colors**

Add colors for `delivered`, `viewed`, `partially_paid`, `credit_noted`, `void_status`.

- [ ] **Step 2: Add payment progress bar**

If `amountPaid > 0 && status != paid`: show `LinearProgressIndicator` with "TZS [paid] / TZS [total]" text.

- [ ] **Step 3: Add overdue indicator**

If not paid and `dueDate < DateTime.now()`: show red "Imechelewa siku [X]" / "Overdue [X] days" text.

- [ ] **Step 4: Add balance remaining display**

Show "Baki: TZS [remaining]" below total when partially paid.

- [ ] **Step 5: Verify compilation**

Run: `flutter analyze lib/business/widgets/invoice_card.dart`

---

### Task 7: Add Quote-to-Invoice Conversion Button

**Files:**
- Modify: `lib/business/pages/quotes_page.dart`

Add "Convert to Invoice" action on accepted quotes. Navigate to `CreateInvoicePage` with quote data pre-filled.

- [ ] **Step 1: Add conversion button to quote cards**

For quotes with `status == QuoteStatus.accepted` and `convertedInvoiceId == null`: show "Badilisha kuwa Ankara" / "Convert to Invoice" button.

- [ ] **Step 2: Add already-converted indicator**

For quotes with `convertedInvoiceId != null`: show disabled text "Tayari imebadilishwa → Ankara #[number]" tappable to view invoice.

- [ ] **Step 3: Navigate to CreateInvoicePage with source quote**

Pass quote data to `CreateInvoicePage(businessId: ..., sourceQuote: quote)`.

- [ ] **Step 4: Verify compilation**

Run: `flutter analyze lib/business/pages/quotes_page.dart`

---

## SUB-PROJECT 2: Delivery & Payments (Tasks 8-11)

### Task 8: Send Invoice Sheet (multi-channel)
Create `_showSendInvoiceSheet()` in InvoiceDetailPage. Channel checkboxes (WhatsApp/Email/In-App/PDF). WhatsApp: generate message + share. Email: API call. In-App: API call. PDF: download. Multi-select allowed.

### Task 9: Record Payment Sheet (partial payments)
Create `_showRecordPaymentSheet()` in InvoiceDetailPage. Amount field (default: remaining balance), method picker (radio with icons), reference field, date picker, notes. Quick buttons: Pay Full / Half. Overpayment warning. Call `BusinessService.recordInvoicePayment()`.

### Task 10: Send Reminder Sheet
Create `_showReminderSheet()` in InvoiceDetailPage. Pre-filled message based on status (overdue/due soon/partially paid). Channel picker. Cooldown warning if reminder sent in last 3 days. Call `BusinessService.sendInvoiceReminder()`.

### Task 11: Wire payment/delivery UI in InvoiceDetailPage
Connect the sheets from Tasks 8-10 to the action bar buttons. Refresh invoice data after each action.

---

## SUB-PROJECT 3: Credit Notes & VFD (Tasks 12-14)

### Task 12: Create CreditNotePage
Full page for issuing credit notes. Original invoice summary at top. Line item checkboxes with quantity adjustment. Reason picker (radio). Totals calculation. Application method (next invoice / wallet refund / manual). Confirmation dialog. Call `BusinessService.createCreditNote()`.

### Task 13: VFD Receipt Section in InvoiceDetailPage
Show VFD receipt number + download button when invoice is paid. Failure state with retry button. Reverse VFD info when credit note exists.

### Task 14: Credit Note Detail Page
Read-only view of a credit note. Same branding as invoice. PDF download. Link back to original invoice.

---

## SUB-PROJECT 4: Recurring, Settings, Reports & Customer Side (Tasks 15-19)

### Task 15: Enhanced RecurringInvoicesPage
Rewrite with: template detail view, generated invoice history, pause/resume/cancel actions, end conditions (date/count), auto-send toggle with channel picker, late payment detection banner.

### Task 16: InvoiceSettingsPage
New page: number prefix, default payment terms dropdown, default VAT toggle, payment instructions text, default notes text, logo upload, auto-reminder toggle with timing multi-select. Save via `BusinessService.updateInvoiceSettings()`.

### Task 17: CustomerStatementPage
New page: date range picker with presets, transaction list (invoices as debits, payments as credits, credit notes as credits), running balance, opening/closing balance, summary totals. PDF download. Send to customer.

### Task 18: InvoiceReportsPage
New page: revenue summary with period picker, revenue bar chart, collection performance metrics, detailed aging table, top customers list, payment method pie chart, VAT summary with TRA export.

### Task 19: Customer-Side Invoice View (Wallet Pay Now)
New page accessible from notifications: read-only invoice view with Pay Now button. Wallet balance display, amount field (partial/full), confirmation dialog. Wallet transfer on confirm.
