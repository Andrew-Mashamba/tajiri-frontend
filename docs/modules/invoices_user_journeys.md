# Invoices — Complete User Journeys

**Module:** lib/business/ (invoice features within business module)
**Source spec:** docs/modules/invoices.md

Every feature must be: **Interactive** (notifications, reminders, prompts), **Connected** (wallet, quotes, VFD, budget, calendar, customers), and **Insightful** (reports, trends, recommendations).

---

## 1. INVOICE DASHBOARD

**Entry:** Profile → BUSINESS category → "Invoices" tab (`biz_invoices`, order 31) → `InvoicesPage(businessId:)`
**Stage/Context:** Business owner opens invoice section from their profile to see financial overview

### User Journey
1. User taps "Ankara" / "Invoices" from business home navigation
2. Dashboard loads with three hero cards at top:
   - **Total Outstanding:** sum of all unpaid invoice balances (amber if > 0)
   - **Total Overdue:** sum of all overdue invoice balances (red if > 0)
   - **Revenue This Month:** sum of all paid invoices in current month (green)
3. Below hero cards: **Aging Report** horizontal bar showing:
   - 0–30 days: TZS [amount] ([count] ankara)
   - 31–60 days: TZS [amount] ([count] ankara)
   - 61–90 days: TZS [amount] ([count] ankara)
   - 90+ days: TZS [amount] ([count] ankara) — red highlight
4. Below aging: **Revenue Trend** mini sparkline chart — monthly paid invoice revenue over last 6 months
5. Tab bar: "Zote" / "All" | "Rasimu" / "Drafts" | "Zimetumwa" / "Sent" | "Zimelipwa" / "Paid" | "Zimechelewa" / "Overdue"
6. Invoice list loads under selected tab — each invoice shown as InvoiceCard:
   - Invoice number, customer name, total amount, balance remaining
   - Status chip (color-coded), due date, days overdue if applicable
   - Payment progress bar for partially-paid invoices
7. Search bar at top: search by invoice number or customer name
8. Sort options: by date (newest/oldest), by amount (highest/lowest), by due date
9. Black pill button (top-right corner): "+ Unda Ankara" / "+ Create Invoice"
10. Pull-to-refresh reloads all data
11. **Empty state (no invoices):** Illustration with text "Huna ankara bado. Unda ankara yako ya kwanza!" / "No invoices yet. Create your first invoice!" with "Unda Ankara" / "Create Invoice" button
12. **Error state:** "Imeshindikana kupakia ankara. Jaribu tena" / "Failed to load invoices. Try again" with retry button
13. **Offline state:** Shows cached data with banner "Hutumii mtandao — taarifa za mwisho" / "You're offline — showing last data"

### CRUD Operations
- **Create:** Black pill button (top-right) → Create Invoice page (see Feature 2)
- **Read:** Invoice list with tabs, search, sort; tap card → Invoice Detail (see Feature 3)
- **Edit:** NOT AVAILABLE from dashboard — edit only from Invoice Detail (draft invoices only)
- **Delete:** NOT AVAILABLE — invoices are voided, never deleted (audit trail)

### Notifications & Reminders
- 📊 **Weekly outstanding summary (Monday 8am):** "📊 Ankara zako: TZS [outstanding] hazijalipwa, TZS [overdue] zimechelewa. Ankara [count] zinangojea malipo" / "📊 Your invoices: TZS [outstanding] unpaid, TZS [overdue] overdue. [count] invoices awaiting payment"
- 📊 **Monthly revenue summary (1st of month):** "📊 Mapato ya ankara mwezi uliopita: TZS [amount] kutoka ankara [count]. Mwezi huu umeanza na TZS [outstanding] hazijalipwa" / "📊 Last month's invoice revenue: TZS [amount] from [count] invoices. This month starts with TZS [outstanding] unpaid"
- 💡 **First invoice prompt (if no invoices after 3 days of business registration):** "💡 Bado hujaunda ankara. Ankara za kitaalamu zinasaidia kupata malipo haraka — unda ya kwanza!" / "💡 You haven't created an invoice yet. Professional invoices help get paid faster — create your first one!"

### Reports & Insights
- **Dashboard hero cards:** Real-time outstanding, overdue, and monthly revenue totals
- **Aging report:** Visual breakdown of receivables by age bucket (0-30, 31-60, 61-90, 90+)
- **Revenue trend:** 6-month sparkline showing paid invoice revenue trajectory
- **Collection rate:** Percentage of invoices paid within due date this month vs last month
- **Average payment time:** "Wastani wa siku za malipo: [X] siku" / "Average payment time: [X] days"

### Cross-Module
- **Budget:** Dashboard revenue feeds `IncomeService.getIncomeSummary(source: 'invoice_payment')` — invoice revenue appears in Biashara envelope income
- **Wallet:** Outstanding amount reflects expected wallet inflows
- **Shangazi AI:** "Uliza Shangazi kuhusu ankara zako" / "Ask Shangazi about your invoices" — Shangazi can analyze: "Una TZS 2M zimechelewa zaidi ya siku 60. Tuma vikumbusho!" / "You have TZS 2M overdue for 60+ days. Send reminders!"

---

## 2. CREATE INVOICE

**Entry:** Profile → BUSINESS → "Invoices" tab → black pill button (top-right) "+ Unda Ankara" / "+ Create Invoice" OR Quote Detail → "Badilisha kuwa Ankara" / "Convert to Invoice"
**Stage/Context:** Business owner creates a new invoice for a customer

### User Journey
1. User taps "+ Unda Ankara" / "+ Create Invoice" black pill button (top-right) → Create Invoice page opens
2. **Customer section (mirrors quote customer selection pattern):**
   - **Option A — Existing customer:** Dropdown "Chagua Mteja" / "Select Customer" populated from `BusinessService.getCustomers(token, businessId)`. Searchable. Selecting a customer auto-fills name, phone, email, TIN, address.
   - **Option B — Search TAJIRI user/business:** If customer is not in existing list, user taps "Tafuta kwenye TAJIRI" / "Search on TAJIRI" → search field appears with same dual-search pattern as quotes:
     - TextField with search icon: "Tafuta jina, @handle, au biashara" / "Search name, @handle, or business"
     - On typing (debounced 320ms): parallel search via `PeopleSearchService.search()` + `BusinessService.searchBusinesses()`
     - Results dropdown split into two sections:
       - **"Watumiaji" / "Users"** — person avatar, full name, @handle. Tap to select.
       - **"Biashara" / "Businesses"** — store icon, business name, owner handle/sector. Tap to select.
     - Selecting a **user** → loads their businesses via `BusinessService.getMyBusinesses(token, userId)`. If user has businesses, show business picker dropdown "Chagua biashara" / "Select business". Selected business auto-fills customer name, TIN if available.
     - Selecting a **business directly** → auto-fills customer name from business name, TIN from business TIN.
     - Loading spinner while searching, "Hakuna matokeo" / "No results" if empty.
     - Clear button (X) to reset search.
   - Selected customer (from either path) saved to business customer list on invoice save for future reuse
   - **Key difference from quotes:** Invoice targets ONE customer (no multi-recipient chips like RFQ). Single selection only.
3. **Line items section:**
   - "Ongeza Bidhaa" / "Add Item" button → bottom sheet:
     - TextField: Maelezo / Description (required)
     - Number field: Kiasi / Quantity (default: 1, decimal allowed)
     - Dropdown: Kipimo / Unit — pcs, hrs, kg, m², liters, custom text
     - Number field: Bei / Unit Price (required, TZS)
     - Toggle: "Ushuru wa VAT" / "VAT Applicable" (default: on, per item)
     - Calculated: Jumla / Total = quantity × unit price (shown real-time)
     - "Tafuta bidhaa" / "Search catalog" button — search business product/service catalog → auto-fills description + price
   - "Hifadhi" / "Save" adds item to list
   - Items shown as editable cards with swipe-to-delete
   - Drag handles for reordering
   - Minimum 1 item required to save invoice
4. **Totals section (auto-calculated, shown real-time):**
   - Jumla ndogo / Subtotal: sum of line items
   - Punguzo / Discount: toggle → picker: "Asilimia" / "Percentage" or "Kiasi" / "Fixed Amount" → enter value
   - VAT (18%): calculated on VAT-applicable items after discount
   - **Jumla / Total: subtotal - discount + VAT** (large bold text)
5. **Payment details:**
   - "Tarehe ya mwisho" / "Due Date" picker — quick presets: Net 7, Net 14, Net 30, Net 60, Custom date
   - TextField: "Masharti ya malipo" / "Payment Terms" (optional free text, e.g., "50% kabla, 50% baada" / "50% upfront, 50% on delivery")
   - TextField: "Maelekezo ya malipo" / "Payment Instructions" — auto-populated from InvoiceSettings (M-Pesa number, bank details). Editable per invoice.
6. **Notes section:**
   - TextField: "Maelezo / Notes" — multiline, bilingual notes visible on invoice
7. **Bottom actions:**
   - "Hifadhi Rasimu" / "Save Draft" — saves as draft status, returns to dashboard
   - "Hakiki" / "Preview" — opens Invoice Preview (see Feature 7)
   - "Hifadhi kama Kiolezo" / "Save as Template" — saves for reuse on future invoices
8. **Validation errors:**
   - No customer selected: "Tafadhali chagua mteja" / "Please select a customer"
   - No line items: "Ongeza bidhaa angalau moja" / "Add at least one item"
   - Zero total: "Jumla ya ankara haiwezi kuwa sifuri" / "Invoice total cannot be zero"
   - Due date in past: "Tarehe ya mwisho haiwezi kuwa zamani" / "Due date cannot be in the past"
9. **Success:** Snackbar "Ankara imeundwa!" / "Invoice created!" — returns to dashboard or opens Send Invoice
10. **API failure:** Snackbar "Imeshindikana kuhifadhi ankara. Jaribu tena" / "Failed to save invoice. Try again" — form stays open, no data lost

### CRUD Operations
- **Create:** Full form as described above → `BusinessService.createInvoice(token, businessId, invoiceData)`
- **Read:** Preview mode shows rendered invoice before saving
- **Edit:** Only available for draft invoices — tap invoice from list → same form pre-filled
- **Delete:** NOT AVAILABLE — drafts can be voided

### Notifications & Reminders
- 🎉 **First invoice created:** "🎉 Ankara yako ya kwanza imeundwa! Tuma kwa mteja wako ili upate malipo" / "🎉 Your first invoice created! Send it to your customer to get paid"
- 💡 **Draft sitting unsent (24hrs):** "💡 Ankara #[number] bado ni rasimu. Tuma kwa [customer] ili uanze kupata malipo" / "💡 Invoice #[number] is still a draft. Send it to [customer] to start getting paid"

### Reports & Insights
- **Template usage:** Track which templates are used most — surface at top of template picker
- **Average invoice value:** "Ankara zako za wastani ni TZS [amount]" / "Your average invoice is TZS [amount]"

### Cross-Module
- **Quotes:** "Convert to Invoice" from accepted quote → all line items, customer, VAT auto-filled. Quote marked `converted`, `convertedInvoiceId` set. Source shown: "Kutoka Nukuu #[quote_number]" / "From Quote #[quote_number]"
- **RFQ:** "Convert to Invoice" from accepted RFQ response → same auto-fill flow. `sourceRfqResponseId` set on invoice
- **Customers:** Customer picker pulls from `BusinessService.getCustomers()`. New customers auto-saved to customer list
- **Product Catalog:** "Search catalog" in line item → browse business products/services → auto-fill description + price

---

## 3. INVOICE DETAIL

**Entry:** Profile → BUSINESS → "Invoices" tab → tap InvoiceCard
**Stage/Context:** Business owner views full details of a specific invoice

### User Journey
1. User taps an invoice card from the dashboard list
2. Invoice Detail page loads with sections:
3. **Header:**
   - Invoice number (large, bold): "Ankara #INV-2026-042"
   - Status chip (color-coded): Rasimu/Draft, Imetumwa/Sent, Imelipwa/Paid, Imechelewa/Overdue, etc.
   - If overdue: red banner "Imechelewa siku [X]" / "Overdue by [X] days"
4. **Business info block:** Business name, TIN, VRN, address, phone, logo
5. **Customer info block:** Customer name, phone, email, TIN (if provided), address
6. **Line items table:**
   - Column headers: Maelezo/Description, Kiasi/Qty, Bei/Price, Jumla/Total
   - Each item row with VAT indicator if applicable
   - VAT-exempt items marked with "(Hakuna VAT)" / "(VAT exempt)"
7. **Totals block:**
   - Jumla ndogo / Subtotal
   - Punguzo / Discount (if any)
   - VAT (18%)
   - **Jumla / Total** (large bold)
   - Kiasi kilicholipwa / Amount Paid (green)
   - **Baki / Balance Remaining** (red if unpaid, green if zero)
8. **Payment progress bar:** visual percentage with "TZS [paid] / TZS [total] ([percentage]%)"
9. **Payment history section** (if any payments):
   - Each payment as a card: date, amount, method icon, reference number, "Auto" or "Manual" badge
   - Chronological order (newest first)
10. **Delivery timeline section:**
    - Visual timeline: "Imetumwa kwa WhatsApp 2 saa zilizopita → Imepokelewa → Haijafunguliwa bado"
    - Each delivery attempt with channel icon, timestamp, status
11. **Notes section:** Invoice notes/terms
12. **Source reference** (if from quote/RFQ): "Kutoka Nukuu #QT-2026-015" / "From Quote #QT-2026-015" — tappable to view original
13. **VFD section** (if paid): VFD receipt number, download button
14. **Credit notes section** (if any): List of credit notes with amounts, tappable to view
15. **Action bar at bottom:**
    - Draft: "Hariri" / "Edit" | "Tuma" / "Send" | "Futa" / "Void"
    - Sent/Delivered/Viewed: "Tuma" / "Send" (resend) | "Kumbuka" / "Remind" | "Pokea Malipo" / "Record Payment"
    - Partially paid: "Pokea Malipo" / "Record Payment" | "Kumbuka" / "Remind"
    - Paid: "Nota ya Mkopo" / "Credit Note" | "Pakua PDF" / "Download PDF"
    - All statuses: overflow menu with "Pakua PDF" / "Download PDF" | "Shiriki" / "Share"
16. **Back button** returns to Invoice Dashboard

### CRUD Operations
- **Create:** N/A (created from Feature 2)
- **Read:** Full invoice detail as described
- **Edit:** "Hariri" / "Edit" button (draft only) → opens Create Invoice form pre-filled → save updates invoice
- **Delete:** NOT AVAILABLE — "Futa" / "Void" voids the invoice with confirmation dialog: "Ankara hii itafutwa na haiwezi kurudishwa. Una uhakika?" / "This invoice will be voided and cannot be reversed. Are you sure?" → voids, shows strikethrough visual

### Notifications & Reminders
- 🔔 **Invoice viewed:** "👁 [customer] ameangalia ankara #[number] — TZS [amount]" / "👁 [customer] viewed invoice #[number] — TZS [amount]"
- ⚠️ **Viewed but not paid (3 days):** "⚠️ [customer] aliona ankara #[number] siku 3 zilizopita lakini hajalipa bado" / "⚠️ [customer] viewed invoice #[number] 3 days ago but hasn't paid yet"

### Reports & Insights
- **Invoice timeline:** Visual history of all events (created, sent, viewed, payments, credit notes)
- **Days to payment:** If paid — how many days from sent to fully paid

### Cross-Module
- **Quotes:** Tappable source reference → navigates to original quote/RFQ detail
- **VFD:** Tappable VFD receipt number → opens VFD receipt detail/download
- **Calendar:** Due date synced as calendar event: "Ankara #[number] — TZS [amount] mwisho wa malipo" / "Invoice #[number] — TZS [amount] payment due"

---

## 4. SEND INVOICE

**Entry:** Invoice Detail → "Tuma" / "Send" button OR Create Invoice → "Tuma" after save
**Stage/Context:** Business owner sends invoice to customer via chosen channel(s)

### User Journey
1. User taps "Tuma" / "Send" on an invoice (draft or resend)
2. Send Invoice sheet opens with channel options:
3. **Channel selection (multi-select allowed):**
   - ☐ WhatsApp — requires customer phone number
   - ☐ Barua pepe / Email — requires customer email
   - ☐ Ndani ya TAJIRI / In-App — requires customer to be TAJIRI user (auto-detected)
   - ☐ Pakua PDF / Download PDF — saves locally
4. **WhatsApp selected:**
   - Preview message shown: "Habari [customer], ankara yako #[number] ya TZS [amount] iko tayari. Tafadhali lipa kabla ya [due_date]. Ahsante! — [business_name]"
   - "Tuma kwa WhatsApp" / "Send via WhatsApp" → generates PDF → opens WhatsApp share sheet with customer number and message pre-filled
5. **Email selected:**
   - Preview email: subject "Ankara #[number] kutoka [business]" / "Invoice #[number] from [business]"
   - Body preview with invoice summary table + "Pay Online" button
   - PDF attachment shown
   - "Tuma barua pepe" / "Send email" → API sends email
6. **In-App selected:**
   - Preview: "[customer] atapata arifa na ankara katika TAJIRI wallet yake"
   - "Tuma ndani ya TAJIRI" / "Send via TAJIRI" → creates notification + payable item in customer's wallet
7. **PDF selected:**
   - "Pakua" / "Download" → PDF saved to device, share sheet opens
8. **Multi-channel:** User can select multiple channels — each creates separate InvoiceDelivery record
9. **Send confirmation:** "Ankara imetumwa!" / "Invoice sent!" — snackbar with channel summary
10. Invoice status updates: draft → sent
11. **Missing info warnings:**
    - WhatsApp without phone: "Mteja hana nambari ya simu. Ongeza kwanza" / "Customer has no phone number. Add one first"
    - Email without email: "Mteja hana barua pepe. Ongeza kwanza" / "Customer has no email. Add one first"
    - In-App without TAJIRI account: greyed out with note "Mteja hayupo TAJIRI" / "Customer not on TAJIRI"
12. **API failure:** "Imeshindikana kutuma ankara. Jaribu tena" / "Failed to send invoice. Try again"

### CRUD Operations
- **Create:** Each send creates an InvoiceDelivery record
- **Read:** Delivery status visible on Invoice Detail timeline
- **Edit:** NOT AVAILABLE — resend creates a new delivery record
- **Delete:** NOT AVAILABLE — delivery records are immutable audit trail

### Notifications & Reminders
- 🔔 **Send confirmation (to business owner):** "✅ Ankara #[number] imetumwa kwa [customer] kupitia [channel]" / "✅ Invoice #[number] sent to [customer] via [channel]"
- 🔔 **Delivery confirmation:** "📬 Ankara #[number] imepokelewa na [customer]" / "📬 Invoice #[number] delivered to [customer]"
- 🔔 **Invoice received (to customer, in-app):** "📄 Umepokea ankara #[number] ya TZS [amount] kutoka [business]. Lipa sasa au angalia maelezo" / "📄 You received invoice #[number] for TZS [amount] from [business]. Pay now or view details"
- ⚠️ **Delivery failed:** "⚠️ Ankara #[number] haijafika kwa [customer] kupitia [channel]. Jaribu njia nyingine" / "⚠️ Invoice #[number] failed to deliver to [customer] via [channel]. Try another method"

### Reports & Insights
- **Delivery success rate:** Percentage of invoices successfully delivered per channel
- **Best channel:** "Wateja wako wanajibu haraka zaidi kwa WhatsApp" / "Your customers respond fastest to WhatsApp"

### Cross-Module
- **Wallet (customer side):** In-app invoices appear as payable items in customer's TAJIRI wallet with "Lipa Sasa" / "Pay Now" button
- **Notifications:** FCM push for in-app delivery, email via backend SMTP

---

## 5. RECORD PAYMENT

**Entry:** Invoice Detail → "Pokea Malipo" / "Record Payment"
**Stage/Context:** Business owner records a payment received against an invoice

### User Journey
1. User taps "Pokea Malipo" / "Record Payment" on unpaid/partially-paid invoice
2. Record Payment bottom sheet opens:
3. **Amount section:**
   - Display: "Baki: TZS [remaining]" / "Balance: TZS [remaining]" (prominent)
   - Number field: "Kiasi" / "Amount" — defaults to remaining balance, editable for partial payment
   - Quick buttons: "Lipa Yote" / "Pay Full" (fills remaining) | "Nusu" / "Half" (fills 50%)
   - If amount > remaining: warning "Kiasi kimezidi baki ya ankara" / "Amount exceeds invoice balance"
4. **Method picker:**
   - Radio buttons with icons: M-Pesa | Tigo Pesa | Airtel Money | Benki / Bank | Taslimu / Cash | TAJIRI Wallet
5. **Reference field:**
   - TextField: "Nambari ya uthibitisho" / "Reference number" — for M-Pesa confirmation code, bank reference, etc.
   - For cash: optional
6. **Date picker:**
   - "Tarehe ya malipo" / "Payment date" — defaults to today, selectable for backdated recording
7. **Notes:**
   - TextField: "Maelezo" / "Notes" — optional (e.g., "Malipo ya kwanza" / "First installment")
8. **Confirm button:** "Hifadhi Malipo" / "Save Payment"
9. **On save:**
   - InvoicePayment record created via API
   - Invoice `amountPaid` updated, `balanceRemaining` recalculated
   - If fully paid: status → `paid`, `paidAt` set, VFD receipt auto-triggered
   - If partially paid: status → `partially_paid`
   - Payment receipt generated (downloadable)
   - Snackbar: "Malipo ya TZS [amount] yamehifadhiwa" / "Payment of TZS [amount] recorded"
10. **Wallet auto-payment (customer-initiated):**
    - Customer taps "Lipa Sasa" on in-app invoice → wallet-to-wallet transfer
    - InvoicePayment auto-created with method=wallet, recordedBy=auto
    - Business receives push notification — no manual recording needed

### CRUD Operations
- **Create:** Payment form → `BusinessService.recordInvoicePayment(token, invoiceId, paymentData)`
- **Read:** Payment history on Invoice Detail — each payment with date, amount, method, reference
- **Edit:** NOT AVAILABLE — payments are immutable financial records
- **Delete:** NOT AVAILABLE — issue credit note to reverse

### Notifications & Reminders
- 🎉 **Full payment received:** "🎉 Ankara #[number] imelipwa! TZS [amount] kutoka [customer] kupitia [method]" / "🎉 Invoice #[number] paid! TZS [amount] from [customer] via [method]"
- 🔔 **Partial payment received:** "💰 Malipo ya TZS [amount] yamepokewa kwa ankara #[number]. Baki: TZS [remaining]" / "💰 Payment of TZS [amount] received for invoice #[number]. Balance: TZS [remaining]"
- 🔔 **VFD receipt generated:** "✅ Risiti ya VFD #[vfd_number] imetolewa kwa ankara #[number]" / "✅ VFD receipt #[vfd_number] issued for invoice #[number]"
- ⚠️ **VFD generation failed:** "⚠️ Risiti ya VFD haijatoka kwa ankara #[number]. Tutajaribu tena — au bonyeza hapa kujaribu mwenyewe" / "⚠️ VFD receipt failed for invoice #[number]. We'll retry — or tap here to try manually"
- 💡 **Payment receipt suggestion:** "💡 Shiriki risiti ya malipo na [customer]?" / "💡 Share payment receipt with [customer]?"

### Reports & Insights
- **Payment method breakdown:** Which methods customers use most (M-Pesa 60%, Bank 25%, Cash 15%)
- **Average partial payment size:** "Wastani wa malipo ya awamu: TZS [amount]" / "Average installment: TZS [amount]"
- **Collection velocity:** Average days from invoice sent to first payment, and to full payment

### Cross-Module
- **Wallet:** Wallet payment auto-creates InvoicePayment; wallet balance updates on both sides
- **Budget:** `IncomeService.recordIncome(userId, amount, source: 'invoice_payment', sourceModule: 'business', referenceId: 'inv_payment_[id]', description: 'Ankara #[number] — [customer]')`
- **VFD:** Full payment → auto-trigger `BusinessService.generateVfdReceipt(invoiceId)` → TRA API
- **ExpenditureService (customer):** `ExpenditureService.recordExpenditure(userId: customerId, amount, category: 'biashara', sourceModule: 'business', description: 'Ankara #[number] — [business_name]')`

---

## 6. SEND REMINDER

**Entry:** Invoice Detail → "Kumbuka" / "Remind" button
**Stage/Context:** Business owner sends a follow-up reminder for unpaid/overdue invoice

### User Journey
1. User taps "Kumbuka" / "Remind" on a sent/overdue/partially-paid invoice
2. Reminder sheet opens with:
   - Invoice summary: #[number], TZS [balance_remaining], due [date], overdue [X] days (if applicable)
   - Pre-filled reminder message:
     - If overdue: "Habari [customer], ankara #[number] ya TZS [amount] ilipaswa kulipwa [due_date] (siku [X] zilizopita). Tafadhali lipa haraka iwezekanavyo. Ahsante! — [business]"
     - If due soon: "Habari [customer], ankara #[number] ya TZS [amount] mwisho wake ni [due_date] (siku [X] zimebaki). Tafadhali lipa ndani ya muda. Ahsante! — [business]"
     - If partially paid: "Habari [customer], asante kwa malipo ya TZS [paid]. Baki ya ankara #[number] ni TZS [remaining]. Tafadhali kamilisha malipo. Ahsante! — [business]"
   - Message editable before sending
3. Channel picker: WhatsApp | Email | In-App (same as Send Invoice)
4. "Tuma Kikumbusho" / "Send Reminder" → dispatched via chosen channel
5. Reminder logged in delivery timeline as type "reminder"
6. Snackbar: "Kikumbusho kimetumwa kwa [customer]" / "Reminder sent to [customer]"
7. **Reminder cooldown:** If reminder was sent in last 3 days, warn: "Kikumbusho kilitumwa siku [X] zilizopita. Tuma tena?" / "Reminder was sent [X] days ago. Send again?"

### CRUD Operations
- **Create:** Reminder message → send via channel → InvoiceDelivery record with type=reminder
- **Read:** Reminder history visible in Invoice Detail delivery timeline
- **Edit:** Message editable before sending
- **Delete:** NOT AVAILABLE — delivery records immutable

### Notifications & Reminders
- 🔔 **Reminder sent confirmation:** "📤 Kikumbusho kimetumwa kwa [customer] kwa ankara #[number]" / "📤 Reminder sent to [customer] for invoice #[number]"
- 🔔 **Reminder to customer (in-app):** "🔔 Kikumbusho: Ankara #[number] ya TZS [amount] kutoka [business] — lipa sasa" / "🔔 Reminder: Invoice #[number] for TZS [amount] from [business] — pay now"
- 💡 **Auto-reminder suggestion:** "💡 Ankara #[number] imechelewa siku 7. Tuma kikumbusho kwa [customer]?" / "💡 Invoice #[number] is 7 days overdue. Send reminder to [customer]?"

### Reports & Insights
- **Reminder effectiveness:** "Ankara [X]% zinalipwa ndani ya siku 3 baada ya kikumbusho" / "[X]% of invoices are paid within 3 days after a reminder"
- **Optimal reminder timing:** "Vikumbusho vya Jumatatu vinafanya kazi zaidi kwa wateja wako" / "Monday reminders work best for your customers"

### Cross-Module
- **Shangazi AI:** Shangazi can auto-suggest: "Una ankara 5 zimechelewa — nitume vikumbusho kwa wote?" / "You have 5 overdue invoices — shall I send reminders to all?"

---

## 7. INVOICE PREVIEW & PDF

**Entry:** Create Invoice → "Hakiki" / "Preview" OR Invoice Detail → "Pakua PDF" / "Download PDF"
**Stage/Context:** Business owner previews or downloads the professional invoice PDF

### User Journey
1. User taps "Hakiki" / "Preview" during creation or "Pakua PDF" from detail
2. Full-screen invoice preview renders showing exactly what the customer will see:
3. **PDF layout:**
   - **Top:** Business logo (left), "ANKARA / INVOICE" title (right)
   - **Business block:** Name, TIN, VRN, address, phone, email
   - **Customer block:** Name, phone, email, TIN, address
   - **Invoice info:** Invoice number, issue date, due date, payment terms
   - **Line items table:** # | Description | Qty | Unit | Price | Total
   - **Totals:** Subtotal, Discount, VAT (18%), **Grand Total**
   - **Payment status:** Amount paid, **Balance Due** (if partial payments exist)
   - **Payment instructions:** M-Pesa number, bank details, QR code for online payment
   - **Notes/Terms:** Footer text
   - **QR code:** Links to online invoice view / payment page
   - **Source reference:** "Based on Quote #QT-2026-015" (if converted from quote)
   - **VFD info** (if paid): VFD receipt number, TRA compliance text
4. **Actions from preview:**
   - "Tuma" / "Send" → opens Send Invoice flow
   - "Pakua" / "Download" → saves PDF to device
   - "Shiriki" / "Share" → native share sheet
   - "Chapisha" / "Print" → system print dialog
   - "Rudi Kuhariri" / "Back to Edit" (only from creation flow)
5. **QR code on PDF:** Scannable by customer → opens:
   - For TAJIRI users: invoice detail in-app with "Pay Now" button
   - For non-TAJIRI users: web page showing invoice summary with payment instructions

### CRUD Operations
- **Create:** PDF generated on-demand from invoice data
- **Read:** Full preview render
- **Edit:** NOT AVAILABLE from preview — go back to edit form
- **Delete:** NOT AVAILABLE

### Notifications & Reminders
- 💡 **Logo missing:** "💡 Ongeza nembo ya biashara yako ili ankara zionekane kitaalamu zaidi" / "💡 Add your business logo to make invoices look more professional"

### Reports & Insights
- **PDF downloads:** Track how often PDFs are downloaded per invoice — indicates customer sharing behavior

### Cross-Module
- **VFD:** If paid, VFD receipt info appears on PDF
- **Quotes:** Source quote reference shown on PDF for traceability

---

## 8. CREDIT NOTE

**Entry:** Invoice Detail (paid/partially-paid) → "Nota ya Mkopo" / "Credit Note"
**Stage/Context:** Business owner issues a credit note to partially or fully reverse a paid invoice

### User Journey
1. User taps "Nota ya Mkopo" / "Credit Note" on a paid/partially-paid invoice
2. Credit Note page opens with original invoice summary at top:
   - Invoice #[number], TZS [total], customer [name]
   - Existing credit notes against this invoice (if any) with total credited
   - Remaining creditable amount: TZS [total - already_credited]
3. **Item selection:**
   - Original line items listed with checkboxes
   - Each item: ☐ Description | Qty | Price | Total
   - Tap checkbox → item included in credit note
   - Quantity editable: partial credit (e.g., 2 of 5 items returned)
   - Per-item credit amount calculated: credited_qty × unit_price
4. **Reason picker:**
   - Radio: "Bidhaa zimerudishwa" / "Goods returned"
   - Radio: "Huduma haijatolewa" / "Service not delivered"
   - Radio: "Kosa la bei" / "Pricing error"
   - Radio: "Nyingine" / "Other" → TextField for explanation
5. **Totals (auto-calculated):**
   - Jumla ndogo ya mkopo / Credit subtotal
   - VAT ya mkopo / Credit VAT
   - **Jumla ya mkopo / Credit Total**
6. **Application method:**
   - Radio: "Ondoa kwenye ankara ijayo" / "Apply to next invoice" — credit stored for future invoice offset
   - Radio: "Rejesha kwenye wallet" / "Refund to wallet" — wallet-to-wallet refund (TAJIRI users only)
   - Radio: "Mwongozo" / "Manual" — business handles refund outside TAJIRI
7. **Preview & Issue:**
   - "Hakiki" / "Preview" → shows credit note PDF
   - "Toa Nota ya Mkopo" / "Issue Credit Note" → confirmation dialog: "Nota ya mkopo ya TZS [amount] itatolewa. Hatua hii haiwezi kurudishwa. Endelea?" / "A credit note of TZS [amount] will be issued. This cannot be undone. Continue?"
   - On confirm: credit note created, reverse VFD receipt triggered, original invoice marked `credit_noted`
8. **Validation:**
   - No items selected: "Chagua bidhaa angalau moja" / "Select at least one item"
   - Credit exceeds remaining: "Mkopo umezidi kiasi kinachoruhusiwa" / "Credit exceeds allowed amount"
9. **Success:** Snackbar "Nota ya mkopo #CN-2026-008 imetolewa" / "Credit note #CN-2026-008 issued"
10. **Credit note PDF:** Same branding as invoice, references original invoice number, downloadable/shareable

### CRUD Operations
- **Create:** Credit note form → `BusinessService.createCreditNote(token, invoiceId, creditNoteData)` → reverse VFD
- **Read:** Credit notes listed on original Invoice Detail; credit note detail page with PDF
- **Edit:** NOT AVAILABLE — credit notes are immutable once issued
- **Delete:** NOT AVAILABLE — credit notes are permanent financial records

### Notifications & Reminders
- 🔔 **Credit note issued (to business):** "📝 Nota ya mkopo #[cn_number] ya TZS [amount] imetolewa kwa ankara #[invoice_number]" / "📝 Credit note #[cn_number] for TZS [amount] issued against invoice #[invoice_number]"
- 🔔 **Credit note received (to customer):** "📝 Umepokea nota ya mkopo ya TZS [amount] kutoka [business] kwa ankara #[invoice_number]" / "📝 You received a credit note of TZS [amount] from [business] for invoice #[invoice_number]"
- 🔔 **Wallet refund:** "💰 TZS [amount] imerejeshwa kwenye wallet yako — nota ya mkopo kutoka [business]" / "💰 TZS [amount] refunded to your wallet — credit note from [business]"

### Reports & Insights
- **Credit note ratio:** "Nota za mkopo ni [X]% ya ankara zako — kawaida ni chini ya 5%" / "Credit notes are [X]% of your invoices — normal is under 5%"
- **Top reasons:** Pie chart of credit note reasons — identifies recurring quality/pricing issues

### Cross-Module
- **VFD:** Auto-trigger reverse VFD receipt via TRA API on credit note issuance
- **Wallet:** Wallet refund option → `WalletService.transfer()` from business to customer
- **Budget:** Credit note recorded as negative income: `IncomeService.recordIncome(amount: -creditAmount, source: 'credit_note')`

---

## 9. RECURRING INVOICES

**Entry:** Profile → BUSINESS → "Recurring" tab (`biz_recurring`, order 32) → `RecurringInvoicesPage(businessId:)` OR from Invoices tab → navigate to recurring
**Stage/Context:** Business owner sets up automatic invoice generation on a schedule

### User Journey
1. User taps "Ankara za Kujirudia" / "Recurring" tab on dashboard
2. List of recurring invoice templates loads:
   - Each card: customer name, total amount, frequency, next generation date, status (active/paused/cancelled)
   - Active templates shown with green indicator
   - Paused templates shown with amber indicator
3. **Create new recurring invoice:**
   - User taps "+ Unda" / "+ Create" black pill button (top-right) → Recurring Invoice form (similar to Create Invoice)
   - Same fields as regular invoice (customer, items, VAT, payment terms, notes)
   - **Additional schedule section:**
     - Frequency picker: "Kila Wiki" / "Weekly" | "Kila Mwezi" / "Monthly" | "Kila Robo Mwaka" / "Quarterly" | "Kila Mwaka" / "Annually" | "Desturi" / "Custom"
     - Custom interval: number field + "siku" / "days"
     - Start date: "Tarehe ya kuanza" / "Start date" — when first invoice generates
     - End condition radio:
       - "Bila mwisho" / "No end date" — continues until manually cancelled
       - "Hadi tarehe" / "Until date" → date picker
       - "Ankara [X] tu" / "Only [X] invoices" → number field
     - Auto-send toggle: "Tuma moja kwa moja" / "Auto-send" — if on, choose channel (WhatsApp/email/in-app)
   - "Hifadhi Kiolezo" / "Save Template" → template created, first invoice scheduled
4. **Managing existing templates:**
   - Tap template → detail view showing:
     - Template details (customer, items, schedule)
     - Generated invoice history: list of all invoices created from this template with statuses
     - "Simamisha" / "Pause" — pauses generation, no invoices created until resumed
     - "Endelea" / "Resume" — resumes paused template
     - "Sitisha" / "Cancel" — permanently stops the template (confirmation required)
     - "Hariri" / "Edit" — edit template (changes apply to future invoices only)
   - Long-press → context menu with same actions
5. **Late payment detection:**
   - When generating next recurring invoice, system checks if previous one is unpaid
   - If unpaid: banner "⚠️ Ankara ya awali #[number] bado haijalipwa (TZS [amount]). Unda ankara mpya?" / "⚠️ Previous invoice #[number] still unpaid (TZS [amount]). Generate new invoice?"
   - Business can proceed or skip this cycle
6. **Empty state:** "Huna ankara za kujirudia. Zinafaa kwa wateja wanaolipa kila mwezi!" / "No recurring invoices. Great for customers who pay monthly!"

### CRUD Operations
- **Create:** Recurring template form → `BusinessService.createRecurringInvoice(token, businessId, templateData)`
- **Read:** Template list with generated invoice history
- **Edit:** "Hariri" / "Edit" → same form pre-filled — changes affect future invoices only
- **Delete:** NOT AVAILABLE — templates are cancelled, not deleted. "Sitisha" / "Cancel" with confirmation

### Notifications & Reminders
- 🔔 **Invoice auto-generated:** "📄 Ankara ya kila mwezi #[number] imeundwa kwa [customer] — TZS [amount]" / "📄 Monthly invoice #[number] generated for [customer] — TZS [amount]"
- 🔔 **Invoice auto-sent:** "📤 Ankara #[number] imetumwa moja kwa moja kwa [customer] kupitia [channel]" / "📤 Invoice #[number] auto-sent to [customer] via [channel]"
- ⚠️ **Previous unpaid warning:** "⚠️ [customer] bado haijalipa ankara #[previous_number] (TZS [amount]) — ankara mpya ya kujirudia iko tayari" / "⚠️ [customer] hasn't paid invoice #[previous_number] (TZS [amount]) — next recurring invoice is ready"
- 💡 **Recurring suggestion:** "💡 Umeunda ankara 3 kwa [customer] mwezi huu. Unda ankara ya kujirudia?" / "💡 You've created 3 invoices for [customer] this month. Set up recurring?"

### Reports & Insights
- **Recurring revenue forecast:** "Mapato ya kujirudia mwezi ujao: TZS [amount] kutoka wateja [count]" / "Recurring revenue next month: TZS [amount] from [count] customers"
- **Recurring payment health:** Which recurring customers pay on time vs late
- **Churn detection:** Alert if a customer misses 2+ consecutive recurring payments

### Cross-Module
- **Calendar:** Each recurring schedule synced: "Ankara ya kujirudia — [customer] — TZS [amount]" on generation dates
- **Budget:** Recurring revenue projected in cash flow forecast via IncomeService
- **Wallet:** Recurring wallet payments auto-reconciled each cycle

---

## 10. INVOICE SETTINGS

**Entry:** Profile → BUSINESS → "Invoices" tab → ⚙️ gear icon OR Business Profile → "Mipangilio ya Ankara" / "Invoice Settings"
**Stage/Context:** Business owner configures default invoice behavior

### User Journey
1. User taps settings gear on Invoice Dashboard
2. Invoice Settings page loads with sections:
3. **Numbering section:**
   - TextField: "Kiambishi awali" / "Prefix" — default "INV", editable (e.g., "ANK", "BILL")
   - Display: "Ankara ijayo: [prefix]-[year]-[next_sequence]" showing preview
   - Note: "Nambari haziwezi kurudi nyuma" / "Numbers cannot be reset"
4. **Default payment terms:**
   - Dropdown: Net 7 | Net 14 | Net 30 | Net 60
   - "Hii itatumika kwa ankara zote mpya" / "This will be used for all new invoices"
5. **Default VAT:**
   - Toggle: "Jumuisha VAT kwa ankara zote" / "Include VAT on all invoices" (default: on)
6. **Default payment instructions:**
   - TextField (multiline): M-Pesa number, bank details, TAJIRI wallet info
   - "Maelekezo haya yataonekana kwenye kila ankara mpya" / "These instructions will appear on every new invoice"
   - Suggestion: "Ongeza nambari yako ya M-Pesa na akaunti ya benki" / "Add your M-Pesa number and bank account"
7. **Default notes/terms:**
   - TextField (multiline): Standard footer text for all invoices
   - Placeholder: "Masharti ya biashara, sera ya urejeshaji, n.k." / "Business terms, return policy, etc."
8. **Logo:**
   - Image picker: "Pakua nembo" / "Upload logo" — appears on all invoice PDFs
   - Preview of current logo
   - "Ondoa" / "Remove" to remove logo
9. **Auto-reminders:**
   - Toggle: "Vikumbusho vya moja kwa moja" / "Auto-reminders" (default: off)
   - If on: multi-select reminder timing: 1 day | 3 days | 7 days | 14 days after due date
   - Channel: WhatsApp | Email | In-App
   - "Vikumbusho vitatumwa moja kwa moja kwa ankara zilizochelewa" / "Reminders will be sent automatically for overdue invoices"
10. **Save:** "Hifadhi" / "Save" → `BusinessService.updateInvoiceSettings(token, businessId, settings)` → snackbar "Mipangilio imehifadhiwa" / "Settings saved"

### CRUD Operations
- **Create:** Settings auto-created with defaults on first invoice page visit
- **Read:** Settings page shows current configuration
- **Edit:** All fields editable, save updates
- **Delete:** NOT AVAILABLE — settings can be reset to defaults

### Notifications & Reminders
- 💡 **Incomplete settings (first visit):** "💡 Weka maelekezo ya malipo ili wateja wajue jinsi ya kulipa" / "💡 Set up payment instructions so customers know how to pay"
- 💡 **Missing logo:** "💡 Ankara zenye nembo zinaonekana kitaalamu zaidi — pakua nembo yako" / "💡 Invoices with a logo look more professional — upload yours"

### Reports & Insights
- N/A (settings page, not a data-collecting feature)

### Cross-Module
- **Business Profile:** Logo, TIN, VRN, address pulled from business profile — settings adds invoice-specific customizations on top

---

## 11. CUSTOMER STATEMENT

**Entry:** Profile → BUSINESS → "Invoices" tab → Invoice Detail → overflow menu → "Taarifa ya Mteja" / "Customer Statement" OR Profile → BUSINESS → "Customers" tab → customer detail → "Taarifa" / "Statement"
**Stage/Context:** Business owner generates a summary of all invoices and payments for a customer over a date range

### User Journey
1. User taps "Taarifa ya Mteja" / "Customer Statement" for a specific customer
2. Statement page opens with:
   - Customer name and details at top
   - Date range picker: "Kuanzia" / "From" — "Hadi" / "To" (defaults to current month)
   - Quick presets: "Mwezi huu" / "This Month" | "Miezi 3" / "3 Months" | "Mwaka huu" / "This Year"
3. Statement loads showing:
   - **Opening balance:** Amount owed at start of period
   - **Transaction list (chronological):**
     - Each row: Date | Description (Invoice #X or Payment) | Debit (invoice amount) | Credit (payment amount) | Running Balance
     - Invoices shown as debits (money owed increases)
     - Payments shown as credits (money owed decreases)
     - Credit notes shown as credits
   - **Closing balance:** Amount owed at end of period
   - **Summary:** Total invoiced, total paid, total credited, net balance
4. **Actions:**
   - "Pakua PDF" / "Download PDF" — branded statement PDF
   - "Tuma kwa [customer]" / "Send to [customer]" — via WhatsApp/email
   - "Chapisha" / "Print"
5. **Empty state:** "Hakuna shughuli na [customer] katika kipindi hiki" / "No transactions with [customer] in this period"

### CRUD Operations
- **Create:** Statement generated on-demand from invoice + payment data
- **Read:** Full statement view with running balance
- **Edit:** NOT AVAILABLE — statements are read-only reports
- **Delete:** NOT AVAILABLE

### Notifications & Reminders
- 💡 **Monthly statement suggestion:** "💡 Tuma taarifa ya mwezi kwa wateja wako walio na baki? Inasaidia kupata malipo haraka" / "💡 Send monthly statements to customers with balances? It helps get paid faster"

### Reports & Insights
- **Customer lifetime value:** Total invoiced to this customer since first invoice
- **Payment behavior:** Average days to pay, preferred payment method, partial payment frequency

### Cross-Module
- **Customers:** Statement pulls from customer record → shows all invoices + payments for that customer

---

## 12. INVOICE ANALYTICS & REPORTS

**Entry:** Profile → BUSINESS → "Invoices" tab → "Ripoti" / "Reports" button
**Stage/Context:** Business owner reviews invoice performance, revenue trends, and customer analysis

### User Journey
1. User taps "Ripoti" / "Reports" from invoice dashboard
2. Reports page loads with:
3. **Revenue Summary (top section):**
   - Period picker: "Mwezi huu" / "This Month" | "Robo Mwaka" / "Quarter" | "Mwaka huu" / "This Year" | "Desturi" / "Custom"
   - Hero number: Total Revenue (paid invoices) for period
   - Comparison: "[+/-X]% vs kipindi kilichopita" / "[+/-X]% vs previous period"
4. **Revenue Chart:**
   - Bar chart: monthly revenue over selected period
   - Tap bar for month detail breakdown
5. **Collection Performance:**
   - Average days to payment (sent → fully paid)
   - Collection rate: % of invoices paid within due date
   - Overdue rate: % of invoices that went overdue before payment
   - Trend arrows comparing to previous period
6. **Aging Report (detailed):**
   - Table: Age bucket | Count | Total Amount | % of Outstanding
   - 0–30 days | [count] | TZS [amount] | [%]
   - 31–60 days | [count] | TZS [amount] | [%]
   - 61–90 days | [count] | TZS [amount] | [%]
   - 90+ days | [count] | TZS [amount] | [%]
7. **Top Customers (by revenue):**
   - List: Customer name | Invoiced | Paid | Outstanding | Avg Days
   - Tap customer → Customer Statement
8. **Payment Method Breakdown:**
   - Pie chart: M-Pesa [%], Bank [%], Cash [%], Wallet [%], Tigo/Airtel [%]
9. **VAT Summary:**
   - Total VAT collected for period (TRA-ready)
   - Breakdown by month
   - "Pakua kwa TRA" / "Download for TRA" — formatted for tax reporting
10. **Export:**
    - "Pakua PDF" / "Download PDF" — full report as PDF
    - "Pakua CSV" / "Download CSV" — raw data export for spreadsheets
    - "Shiriki" / "Share" — send report to partner/accountant

### CRUD Operations
- **Create:** Reports auto-generated from invoice data
- **Read:** Full interactive report with charts and tables
- **Edit:** NOT AVAILABLE — reports are read-only
- **Delete:** NOT AVAILABLE

### Notifications & Reminders
- 📊 **Monthly report ready (1st of month):** "📊 Ripoti ya ankara ya [month] iko tayari! Mapato: TZS [revenue], Ukusanyaji: [collection_rate]%" / "📊 [month] invoice report is ready! Revenue: TZS [revenue], Collection: [collection_rate]%"
- 📊 **Quarterly VAT summary:** "📊 Muhtasari wa VAT wa robo mwaka uko tayari — TZS [vat_total]. Pakua kwa TRA" / "📊 Quarterly VAT summary ready — TZS [vat_total]. Download for TRA"
- 🎉 **Revenue milestone:** "🎉 Umevuka TZS [milestone] ya mapato ya ankara mwezi huu!" / "🎉 You crossed TZS [milestone] in invoice revenue this month!"

### Reports & Insights
- **Revenue forecasting:** Based on recurring invoices + historical patterns, project next month's revenue
- **Customer concentration risk:** "⚠️ [customer] ni [X]% ya mapato yako — hatari ya kutegemea mteja mmoja" / "⚠️ [customer] is [X]% of your revenue — customer concentration risk"
- **Seasonal patterns:** "Ankara zako huongezeka [month] kila mwaka" / "Your invoices increase in [month] every year"
- **Recommendation:** "💡 Wateja [X] wamelipa ankara zao ndani ya siku 7 kila wakati — wape punguzo la malipo ya mapema?" / "💡 [X] customers always pay within 7 days — offer them an early payment discount?"

### Cross-Module
- **Budget:** Revenue data feeds `IncomeService` for business budget tracking
- **VFD:** VAT summary cross-references VFD receipts for TRA compliance
- **Shangazi AI:** "Uliza Shangazi kuchambua ripoti yako" / "Ask Shangazi to analyze your report" → AI-powered insights on trends and anomalies

---

## 13. WALLET PAY NOW (CUSTOMER SIDE)

**Entry:** Customer's TAJIRI notifications → tap invoice notification OR Wallet → "Ankara" / "Invoices" section
**Stage/Context:** Customer who received an in-app invoice pays directly from their TAJIRI wallet

### User Journey
1. Customer receives push notification: "📄 Umepokea ankara #[number] ya TZS [amount] kutoka [business]"
2. Tap notification → Invoice view opens (customer-facing, read-only):
   - Business details and logo
   - Line items table
   - Totals with balance remaining
   - Payment history (if partial payments exist)
   - Due date with countdown: "Siku [X] zimebaki" / "[X] days remaining" OR "Imechelewa siku [X]" / "[X] days overdue"
3. **Pay Now section:**
   - Display wallet balance: "Salio lako: TZS [balance]"
   - Amount field: pre-filled with balance remaining, editable for partial payment
   - Quick buttons: "Lipa Yote" / "Pay Full" | "Lipa Nusu" / "Pay Half" | "Kiasi Kingine" / "Other Amount"
   - If wallet balance < invoice amount: warning "Salio halitoshi. Jaza wallet kwanza au lipa kiasi unachoweza" / "Insufficient balance. Top up wallet first or pay what you can"
     - "Jaza Wallet" / "Top Up" button → Wallet deposit flow
4. "Lipa Sasa" / "Pay Now" → confirmation: "Lipa TZS [amount] kwa [business] kwa ankara #[number]?" / "Pay TZS [amount] to [business] for invoice #[number]?"
5. On confirm:
   - Wallet-to-wallet transfer executed
   - InvoicePayment auto-created (method=wallet, recordedBy=auto)
   - Invoice status updates
   - If fully paid: VFD receipt triggered
   - Customer sees: "✅ Malipo yamefanikiwa! TZS [amount] kwa [business]" / "✅ Payment successful! TZS [amount] to [business]"
   - Payment receipt downloadable
6. Business receives real-time notification of payment
7. **Decline option:** Customer can ignore — no action required, but reminders will follow

### CRUD Operations
- **Create:** Payment via wallet → auto-creates InvoicePayment
- **Read:** Customer can view invoice detail and payment history
- **Edit:** NOT AVAILABLE — customer can only pay, not modify
- **Delete:** NOT AVAILABLE

### Notifications & Reminders
- 🔔 **Invoice received (customer):** "📄 Umepokea ankara #[number] ya TZS [amount] kutoka [business]. Mwisho wa malipo: [due_date]" / "📄 Invoice #[number] for TZS [amount] from [business]. Due: [due_date]"
- 🔔 **Payment success (customer):** "✅ Umelipa TZS [amount] kwa [business] — ankara #[number]" / "✅ You paid TZS [amount] to [business] — invoice #[number]"
- 🔔 **Reminder (customer):** "🔔 Ankara #[number] ya TZS [amount] kutoka [business] — mwisho [due_date]" / "🔔 Invoice #[number] for TZS [amount] from [business] — due [due_date]"
- ⚠️ **Overdue (customer):** "⚠️ Ankara #[number] ya TZS [amount] kutoka [business] imechelewa siku [X]" / "⚠️ Invoice #[number] for TZS [amount] from [business] is [X] days overdue"

### Reports & Insights
- **Customer payment history:** All invoices paid from this business — amounts, dates, methods

### Cross-Module
- **Wallet:** Direct integration — wallet balance shown, transfer executed
- **ExpenditureService:** `ExpenditureService.recordExpenditure(userId: customerId, amount, category: 'biashara', description: 'Ankara #[number] — [business]')` → feeds customer's budget
- **Calendar:** Invoice due date appears in customer's calendar if in-app delivery accepted

---

## 14. RECEIVED INVOICES INBOX (CUSTOMER SIDE)

**Entry:** Profile → BUSINESS category → "Received" tab (`received_invoices`, order 31) → `ReceivedInvoicesPage(userId:)`
**Stage/Context:** Any TAJIRI user views invoices sent to them by businesses, tracks what they owe, and pays directly

### User Journey
1. User taps "Invoices" tab in the FINANCE section of their profile
2. Page loads with a dark hero card showing total outstanding amount and unpaid invoice count
3. Three tabs: "Zote" / "All" | "Hazijalipwa" / "Unpaid" | "Zimelipwa" / "Paid"
4. Invoice list loads under selected tab — each card shows:
   - Business name and logo (who sent the invoice)
   - Invoice number
   - Total amount and balance remaining
   - Payment progress bar (if partially paid)
   - Due date with countdown or overdue days (red)
   - Status badge: Sent/Viewed/Partially Paid/Paid/Overdue
5. Tap any unpaid invoice card → opens `InvoicePayPage` (Journey 13 wallet pay flow)
6. Tap any paid invoice card → opens `InvoicePayPage` showing read-only receipt with payment history
7. Pull-to-refresh reloads all data
8. **Empty state:** "Huna ankara zilizopokewa. Ankara zitaonekana hapa zikitumwa kwako" / "No received invoices. Invoices will appear here when sent to you"
9. **Error state:** Standard error with retry button

### CRUD Operations
- **Create:** NOT AVAILABLE — invoices are created by businesses, not customers
- **Read:** Invoice list with tabs, tap for detail + pay
- **Edit:** NOT AVAILABLE — customer cannot modify invoices
- **Delete:** NOT AVAILABLE — invoices are controlled by the business

### Notifications & Reminders
- 🔔 **New invoice received:** "📄 Umepokea ankara #[number] ya TZS [amount] kutoka [business]. Mwisho wa malipo: [due_date]" / "📄 Invoice #[number] for TZS [amount] from [business]. Due: [due_date]"
- 🔔 **Reminder:** "🔔 Ankara #[number] ya TZS [amount] kutoka [business] — mwisho [due_date]" / "🔔 Invoice #[number] for TZS [amount] from [business] — due [due_date]"
- ⚠️ **Overdue:** "⚠️ Ankara #[number] ya TZS [amount] kutoka [business] imechelewa siku [X]" / "⚠️ Invoice #[number] for TZS [amount] from [business] is [X] days overdue"
- 📊 **Weekly summary (Sunday):** "📊 Una ankara [count] hazijalipwa — jumla TZS [amount]" / "📊 You have [count] unpaid invoices — total TZS [amount]"

### Reports & Insights
- **Total outstanding:** Sum of all unpaid invoice balances (shown on hero card)
- **Payment history:** Visible per invoice on the pay page

### Cross-Module
- **Wallet:** Tap to pay → wallet transfer flow via InvoicePayPage
- **Budget (ExpenditureService):** Wallet payments recorded as expenditure on customer's budget
- **Calendar:** Invoice due dates sync to customer's calendar
- **Notifications:** FCM push on new invoice, reminders, overdue alerts

---

## 15. VFD RECEIPT MANAGEMENT (renumbered from 14)

**Entry:** Profile → BUSINESS → "Invoices" tab → Invoice Detail → "Risiti ya VFD" / "VFD Receipt" section OR Profile → BUSINESS → "TRA VFD" tab (`biz_vfd`, order 33)
**Stage/Context:** Business owner manages VFD fiscal receipts linked to paid invoices

### User Journey
1. When an invoice is fully paid, VFD receipt generation auto-triggers
2. On Invoice Detail, VFD section shows:
   - Status: "Inatengenezwa" / "Generating" → "Imekamilika" / "Complete" → VFD receipt number displayed
   - "Pakua Risiti" / "Download Receipt" → PDF of VFD fiscal receipt
   - "Shiriki na Mteja" / "Share with Customer" → send VFD receipt to customer
3. **VFD failure handling:**
   - If TRA API fails: status shows "Imeshindikana" / "Failed" with retry button
   - "Jaribu Tena" / "Retry" → re-attempts VFD generation
   - After 3 auto-retries fail: escalate to business owner with notification
   - Manual retry available anytime from invoice detail
4. **Reverse VFD (credit note):**
   - When credit note is issued, reverse VFD receipt auto-generated
   - Linked to credit note record
   - Both original and reverse VFD receipts visible on invoice detail
5. **Monthly VFD summary:**
   - Accessible from Invoice Reports → "Muhtasari wa VFD" / "VFD Summary"
   - All VFD receipts for the month with: receipt number, invoice number, amount, VAT, date
   - Total VAT collected
   - "Pakua kwa TRA" / "Download for TRA" — formatted CSV/PDF for TRA submission

### CRUD Operations
- **Create:** Auto-created on full payment → TRA API call
- **Read:** VFD receipt viewable/downloadable from Invoice Detail
- **Edit:** NOT AVAILABLE — VFD receipts are immutable TRA records
- **Delete:** NOT AVAILABLE — only reversible via credit note

### Notifications & Reminders
- ✅ **VFD generated:** "✅ Risiti ya VFD #[vfd_number] imetolewa kwa ankara #[invoice_number]" / "✅ VFD receipt #[vfd_number] issued for invoice #[invoice_number]"
- ⚠️ **VFD failed:** "⚠️ Risiti ya VFD haijatoka kwa ankara #[number]. Jaribu tena au wasiliana na TRA" / "⚠️ VFD receipt failed for invoice #[number]. Retry or contact TRA"
- 📊 **Monthly VFD ready:** "📊 Muhtasari wa VFD wa [month] uko tayari — risiti [count], VAT jumla TZS [amount]" / "📊 [month] VFD summary ready — [count] receipts, total VAT TZS [amount]"

### Reports & Insights
- **VFD compliance rate:** % of paid invoices with successful VFD receipts
- **VFD failure rate:** Track and alert on increasing failure rates

### Cross-Module
- **VFD (Business module):** Links to existing VFD page for overall VFD management
- **TRA:** Direct API integration for receipt generation and reversal
- **Budget:** VAT amounts feed into tax-related budget tracking

---

## 16. QUOTE-TO-INVOICE CONVERSION (renumbered from 15)

**Entry:** Profile → BUSINESS → "Quotes" tab (`biz_quotes`, order 30) → accepted quote → "Badilisha kuwa Ankara" / "Convert to Invoice" OR RFQ inbox → accepted response → "Badilisha kuwa Ankara"
**Stage/Context:** Business owner converts an accepted quote or RFQ response into a formal invoice

### User Journey
1. User navigates to Quotes page → taps an accepted quote
2. Quote detail shows "Badilisha kuwa Ankara" / "Convert to Invoice" button (only for accepted quotes)
3. User taps → Create Invoice page opens with pre-filled data:
   - Customer: auto-filled from quote customer
   - Line items: all quote items carried over (same `InvoiceItem` model)
   - VAT settings: carried from quote
   - Notes: carried from quote (editable)
   - Source reference: "Kutoka Nukuu #[quote_number]" / "From Quote #[quote_number]" (read-only)
4. User can modify anything (quantities may differ, additional items, adjusted prices)
5. "Hifadhi" / "Save" → invoice created with `sourceQuoteId` set
6. Quote status updates to `converted`, `convertedInvoiceId` set to new invoice ID
7. Snackbar: "Ankara imeundwa kutoka nukuu #[quote_number]" / "Invoice created from quote #[quote_number]"
8. **Already converted guard:** If quote already converted, button is disabled with text "Tayari imebadilishwa → Ankara #[invoice_number]" / "Already converted → Invoice #[invoice_number]" (tappable to view invoice)
9. **RFQ path:** Same flow from RFQ response detail → `sourceRfqResponseId` set instead of `sourceQuoteId`

### CRUD Operations
- **Create:** Conversion creates a new Invoice from Quote/RFQ data
- **Read:** Source reference visible on invoice detail; converted status visible on quote
- **Edit:** Invoice is editable in draft (even after conversion)
- **Delete:** NOT AVAILABLE — void the invoice; quote remains converted

### Notifications & Reminders
- 🔔 **Conversion success:** "✅ Nukuu #[quote_number] imebadilishwa kuwa ankara #[invoice_number]" / "✅ Quote #[quote_number] converted to invoice #[invoice_number]"
- 💡 **Unconverted accepted quotes (3 days):** "💡 Nukuu #[quote_number] imekubaliwa siku 3 zilizopita lakini bado haijaundwa ankara. Badilisha sasa?" / "💡 Quote #[quote_number] was accepted 3 days ago but no invoice created. Convert now?"

### Reports & Insights
- **Conversion rate:** % of accepted quotes that become invoices
- **Quote-to-invoice time:** Average days from quote acceptance to invoice creation
- **Revenue from quotes:** Total invoice revenue originating from quotes vs direct invoices

### Cross-Module
- **Quotes:** Bidirectional link — quote knows its invoice, invoice knows its source quote
- **RFQ:** Same bidirectional link for RFQ responses
- **Customers:** Customer continuity from quote to invoice — no re-entry needed

---

## NOTIFICATION CHANNELS SUMMARY

| Trigger | Channel | Frequency |
|---------|---------|-----------|
| Invoice created (first ever) | Push | Once |
| Draft sitting unsent (24hrs) | Push | Once per draft |
| Invoice sent confirmation | Push | Per send action |
| Invoice delivered | Push | Per delivery |
| Invoice viewed by customer | Push | Per view event |
| Delivery failed | Push | Per failure |
| Full payment received | Push | Per invoice paid |
| Partial payment received | Push | Per payment |
| VFD receipt generated | Push | Per paid invoice |
| VFD receipt failed | Push | Per failure + retries |
| Invoice overdue (auto-reminder) | Push + channel | 1, 3, 7, 14 days post-due |
| Viewed but not paid (3 days) | Push | Once |
| Weekly outstanding summary | Push | Monday 8am |
| Monthly revenue report | Push | 1st of month |
| Quarterly VAT summary | Push | End of quarter |
| Revenue milestone | Push | Per milestone crossed |
| Recurring invoice generated | Push | Per schedule cycle |
| Previous recurring unpaid | Push | Per generation with unpaid prior |
| Recurring suggestion (3+ invoices to same customer) | Push | Once per customer |
| Unconverted accepted quote (3 days) | Push | Once per quote |
| Monthly statement suggestion | In-app | Monthly |
| Missing logo / payment instructions | In-app | On settings visit |
| Customer invoice received | Push (customer) | Per invoice |
| Customer reminder | Push (customer) | Per reminder |
| Customer overdue | Push (customer) | Matching business reminder timing |
| Customer payment success | Push (customer) | Per payment |
| Credit note received (customer) | Push (customer) | Per credit note |
| Wallet refund (customer) | Push (customer) | Per refund |

**Max push notifications per day:** 2-3 to business owner (aggregate low-priority into weekly summary), 1-2 to customer per invoice

---

## CROSS-MODULE INTEGRATION MAP

| From Invoices | To Module | Trigger | Data Flow |
|--------------|-----------|---------|-----------|
| Invoice paid | **Budget (IncomeService)** | Full/partial payment recorded | `recordIncome(source: 'invoice_payment', amount, referenceId: 'inv_[id]')` |
| Customer pays invoice | **Budget (ExpenditureService)** | Customer wallet payment | `recordExpenditure(category: 'biashara', amount)` on customer side |
| Invoice created | **Customers** | New customer on invoice | Auto-save to business customer list |
| Invoice due date | **Calendar** | Invoice created/sent | `CalendarService.createEvent(title: 'Ankara #[number] mwisho', date: dueDate)` |
| Recurring schedule | **Calendar** | Recurring template created | Calendar events for each generation date |
| Quote accepted | **Quotes** | Convert to Invoice action | Quote → Invoice with `convertedInvoiceId` link |
| RFQ accepted | **RFQ** | Convert to Invoice action | RFQ response → Invoice with `sourceRfqResponseId` link |
| Invoice fully paid | **VFD** | Payment completes invoice | Auto-trigger VFD receipt via TRA API |
| Credit note issued | **VFD** | Credit note created | Auto-trigger reverse VFD receipt |
| Wallet payment | **Wallet** | Customer taps Pay Now | Wallet-to-wallet transfer, auto-reconcile |
| Credit note refund | **Wallet** | Refund to wallet selected | Wallet-to-wallet refund transfer |
| Invoice insights | **Shangazi AI** | User asks about invoices | Pass invoice data context to AI for analysis |
| Revenue data | **Business Analytics** | Ongoing | Invoice revenue feeds business performance metrics |
| Invoice sent/remind | **Notifications (FCM)** | Send/remind action | Push notification via FCM to customer |
| Customer concentration | **Business Reports** | Monthly analysis | Flag customers > 30% of revenue |
