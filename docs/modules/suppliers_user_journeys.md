# Suppliers Module — Complete User Journeys

**Module:** `lib/suppliers/`
**Source spec:** `docs/modules/suppliers.md`

Every feature must be: **Interactive** (notifications, reminders, prompts), **Connected** (budget, wallet, calendar, expenses, Shangazi AI), and **Insightful** (reports, trends, recommendations).

---

## 1. SUPPLIER DIRECTORY

**Entry:** Profile → Business tab → "Wasambazaji" / "Suppliers"
**Stage/Context:** Any time the business owner needs to find a supplier's contact, verify their TIN, or manage their vendor list

### User Journey
1. User taps "Wasambazaji" / "Suppliers" from their Business profile tabs
2. Screen loads `SuppliersPage(businessId:)` — `GET /business/:id/suppliers`
3. **Loading state:** Centered `CircularProgressIndicator` (strokeWidth 2, dark)
4. **Empty state:**
   - Local shipping icon (64px, grey)
   - "Hakuna wasambazaji bado" / "No suppliers yet"
   - Sub-text: "Bonyeza + kuongeza msambazaji" / "Tap + to add a supplier"
5. **Populated state:** Search TextField at top, then scrollable list of supplier cards. Each card shows:
   - Circle avatar with first initial (dark background, white text)
   - Supplier name (bold, 14sp)
   - Phone + email joined by " | " — "0712 345 678 | hassan@suppliers.co.tz" (12sp, grey) — omitted if both blank
   - If `tinNumber` is set: "TIN: [number]" (11sp, lighter grey) below phone/email line
   - Trailing `⋮` popup menu: "Hariri" / "Edit" and "Futa" / "Delete" (red)
6. **Search:** Server-side search on keystroke via `GET /business/:id/suppliers?search=[q]`. Placeholder: "Tafuta msambazaji..." / "Search supplier..."
7. **Tap card:** Opens `_showSupplierDetail(s)` — full detail bottom sheet (see Feature 3)
8. **Pull to refresh:** Reloads `_load()` with current search term cleared
9. **Error state:** Error outline icon, error message, "Jaribu Tena" / "Retry" button
10. **FAB (+):** Bottom-right, dark background → opens Add Supplier sheet (Feature 2)

### CRUD Operations
- **Create:** FAB (+) → Add Supplier bottom sheet (Feature 2)
- **Read:** List with search; tap card → detail bottom sheet (Feature 3)
- **Edit:** Tap card → detail sheet → "Hariri" / "Edit" button OR `⋮` → "Hariri" / "Edit" from list
- **Delete:** `⋮` → "Futa" / "Delete" from list card OR detail sheet → "Futa" / "Delete" button → confirmation dialog

### Notifications & Reminders
- 💡 **First supplier prompt** (if zero suppliers after 7 days of business registration): "💡 Ongeza msambazaji wako wa kwanza kwenye TAJIRI — weka mawasiliano yao, TIN, na anwani mahali pamoja" / "💡 Add your first supplier to TAJIRI — keep their contact, TIN, and address in one place"
- 📊 **Monthly vendor count summary** (sent only if module is active): included in the monthly business digest as "Wasambazaji [N] wamesajiliwa" / "[N] suppliers registered"

### Reports & Insights
- **Supplier count:** Total registered suppliers per business — shown in business analytics overview
- **Most ordered from:** Supplier ranked by number of POs issued (computed from PO data)
- **Highest spend:** Supplier ranked by total TZS value of received POs

### Cross-Module Connections
- **Expenses:** Payments to suppliers from accounts payable (Feature 13) record via `ExpenditureService` as business expense category "Manunuzi" / "Procurement"
- **Wallet:** Supplier payments initiated from accounts payable can route through Wallet for M-Pesa disbursement
- **Shangazi AI:** "Uliza Shangazi kuhusu wasambazaji" / "Ask Shangazi about suppliers" — passes supplier count and top spend category as context; Shangazi can suggest: "Una wasambazaji 3 wa bidhaa zinazofanana. Unaweza kupata bei nzuri zaidi ukichanganya orders" / "You have 3 suppliers selling similar goods. You could get better prices by consolidating orders"

---

## 2. ADD / EDIT SUPPLIER

**Entry:** Supplier list → FAB (+) for add; or tap card → detail sheet → "Hariri" / "Edit"; or `⋮` → "Hariri" / "Edit" from list
**Stage/Context:** Onboarding a new vendor, or updating an existing one's contact details or TIN after they share an updated invoice

### User Journey
1. Bottom sheet slides up from bottom. Drag handle at top-center (40×4px pill).
2. **Title:** "Ongeza Msambazaji" / "Add Supplier" (new) or "Hariri Msambazaji" / "Edit Supplier" (existing)
3. **Form fields (all in filled TextFields, rounded border radius 10, background #FAFAFA):**
   - "Jina *" / "Name *" — required. Pre-filled if editing.
   - "Simu" / "Phone" — `TextInputType.phone`. Pre-filled if editing.
   - "Email" — `TextInputType.emailAddress`. Pre-filled if editing.
   - "Anwani" / "Address" — free text. Pre-filled if editing.
   - "TIN" — TRA tax identification number. Pre-filled if editing.
   - "Maelezo" / "Notes" — any notes about this supplier (terms, delivery schedule, etc.). Pre-filled if editing.
4. **Submit button (full-width, 48dp, dark background, rounded 12):**
   - "Ongeza" / "Add" for new; "Sasisha" / "Update" for edit
   - Disabled and shows `CircularProgressIndicator` while submitting
5. **Validation:** Name field must not be empty. Inline check before API call — no error shown for optional fields.
6. **Success (add):** Sheet closes. Snackbar: none shown explicitly — list reloads and new supplier appears
7. **Success (edit):** Sheet closes. List reloads with updated data.
8. **API failure:** `setSheetState(() => submitting = false)` — sheet stays open. Snackbar: "Imeshindikana. Jaribu tena." / "Failed. Please try again." (red background)
9. **Keyboard handling:** `EdgeInsets.only(bottom: MediaQuery.of(ctx).viewInsets.bottom + 20)` — sheet lifts above keyboard
10. **Dismiss:** Swipe down or tap outside to dismiss without saving

### CRUD Operations
- **Create:** `POST /business/:id/suppliers` — body includes `business_id`, `name`, `phone`, `email`, `address`, `tin_number`, `notes`
- **Read:** Form is pre-filled from existing `Supplier` object on edit
- **Edit:** `PUT /business/suppliers/:id` — same body fields
- **Delete:** NOT AVAILABLE from this sheet — delete is via confirmation dialog from list `⋮` menu or detail sheet

### Notifications & Reminders
- *(No notifications for add/edit — action is synchronous and confirmed by list update)*

### Reports & Insights
- *(No dedicated report — supplier data feeds into spending analytics per supplier, Feature 12)*

### Cross-Module Connections
- **Contacts:** Future integration — pre-fill from device contact (import from phone book)
- **Shangazi AI:** If TIN field is blank when saving: in-app nudge card "Ongeza TIN ya msambazaji kwa maandishi ya kisheria zaidi" / "Add supplier's TIN for more formal procurement records"

---

## 3. SUPPLIER DETAIL VIEW

**Entry:** Supplier list → tap any supplier card → `_showSupplierDetail(s)`
**Stage/Context:** Before placing a new order, before calling the supplier, or before sharing their details with a colleague

### User Journey
1. User taps a supplier card anywhere on the row (not the `⋮` menu)
2. Modal bottom sheet slides up with `isScrollControlled: true`
3. **Header:**
   - Drag handle (40×4px, top-center)
   - CircleAvatar (radius 24, dark background) with supplier's first initial (18sp, white, bold)
   - Supplier name (16sp, bold) beside avatar
4. **Detail rows** (only rendered if field is non-null and non-empty):
   - 📞 "Simu" / "Phone" — `[phone]`
   - ✉️ "Email" — `[email]`
   - 📍 "Anwani" / "Address" — `[address]`
   - 🔢 "TIN" — `[tinNumber]`
   - 📝 "Maelezo" / "Notes" — `[notes]`
5. If all optional fields are blank: shows only name + avatar (no empty rows)
6. **Action row (two buttons, side by side):**
   - "Hariri" / "Edit" (outlined, dark border) → closes sheet, opens Edit Supplier sheet (Feature 2) pre-filled
   - "Futa" / "Delete" (outlined, red border) → closes sheet, calls `_deleteSupplier(s)` which shows confirmation dialog
7. **Delete confirmation dialog:**
   - Title: "Futa Msambazaji?" / "Delete Supplier?"
   - Content: 'Futa "[name]"? Hatua hii haiwezi kurudishwa.' / 'Delete "[name]"? This action cannot be undone.'
   - Buttons: "Hapana" / "Cancel" | "Ndio, Futa" / "Yes, Delete" (red text)
   - On confirm: `DELETE /business/suppliers/:id` → snackbar "Msambazaji amefutwa" / "Supplier deleted" → list reloads
   - On API failure: snackbar with error message (red background)
8. Swipe down or tap outside to close without action

### CRUD Operations
- **Create:** NOT AVAILABLE from this sheet — use FAB on the list
- **Read:** All Supplier fields rendered inline
- **Edit:** "Hariri" / "Edit" button → Edit sheet (Feature 2)
- **Delete:** "Futa" / "Delete" button → confirmation dialog → `DELETE /business/suppliers/:id`

### Notifications & Reminders
- *(No notifications from detail view — informational only)*

### Reports & Insights
- **Future:** "Angalia Matumizi" / "View Spending" button — opens Spending Analytics for this supplier (Feature 12)
- **Future:** PO history count chip: "Maagizo 7 yaliyopita" / "7 past orders" — tap to filter PO list by supplier

### Cross-Module Connections
- **Purchase Orders:** "Agizo Jipya" / "New Order" shortcut button (future) — opens Create PO sheet with this supplier pre-selected
- **Calendar:** If supplier has a scheduled delivery due today: show alert chip "Agizo linatazamiwa leo" / "Order expected today" linking to that PO
- **Shangazi AI:** Pass supplier name and spend total to Shangazi for negotiation advice: "Nimekuwa nikinunua kutoka [Supplier] kwa TZS [amount] mwaka huu — nikusaidie jinsi ya kupata bei nzuri?" / "I've bought TZS [amount] from [Supplier] this year — help me negotiate a better price?"

---

## 4. PURCHASE ORDER LIST

**Entry:** Profile → Business tab → "Maagizo ya Manunuzi" / "Purchase Orders"
**Stage/Context:** Morning check of what was ordered and what has arrived; end-of-day reconciliation; before placing a new supplier call

### User Journey
1. User taps Purchase Orders from business profile tabs
2. `PurchaseOrdersPage(businessId:)` loads — initializes `TabController(length: 4)`
3. **Tab bar** (scrollable, dark indicator, grey unselected):
   - "Zote" / "All"
   - "Rasimu" / "Draft"
   - "Zimetumwa" / "Sent"
   - "Zimepokelewa" / "Received"
4. `_init()` runs in parallel: `_loadOrders()` + `_loadSuppliers()` (suppliers needed for create sheet)
5. **Loading state:** `CircularProgressIndicator` fills the Expanded area below tabs
6. **Empty state (per tab):**
   - Shopping cart icon (64px, grey)
   - "Hakuna maagizo bado" / "No orders yet"
   - "Bonyeza + kuunda agizo jipya" / "Tap + to create a new order"
7. **Populated state:** Each PO card (`Container`, rounded 12, white bg, grey border) shows:
   - Row 1: PO number (bold, 14sp, truncated) + status chip (color-coded: grey=draft, blue=sent, green=received, red=cancelled)
   - Row 2: Supplier name (13sp, grey)
   - Row 3: "TZS [total]" (bold, 14sp) + "Kupokea: [dd/MM/yyyy]" / "Due: [dd/MM/yyyy]" (11sp, grey) if delivery date set
   - Row 4 (inline action buttons, 32dp height, shown for draft and sent only):
     - **Draft:** "Tuma" / "Send" (outlined) + "Futa" / "Cancel" (outlined)
     - **Sent:** "Pokelewa" / "Received" (outlined) + "Futa" / "Cancel" (outlined)
     - **Received/Cancelled:** no action buttons
8. **Tap anywhere on card** (except action buttons): navigates to `_PurchaseOrderDetailPage` (Feature 6)
9. **Tab switch:** `TabController` listener calls `_loadOrders()` with the new status filter
10. **Pull to refresh:** Reloads current tab's orders
11. **Error state:** Error icon, error text, "Jaribu Tena" / "Retry" button
12. **FAB (+):** Bottom-right → opens Create PO sheet (Feature 5)

### CRUD Operations
- **Create:** FAB (+) → Create PO sheet (Feature 5)
- **Read:** Tabbed list; tap card → PO Detail page (Feature 6)
- **Edit:** NOT AVAILABLE — gap flagged in spec (Feature 8)
- **Delete/Cancel:** "Futa" / "Cancel" inline action → `_cancelOrder()` → confirmation dialog → `POST /business/purchase-orders/:id/cancel`

### Notifications & Reminders
- 🔔 **Delivery due today** (8:00am on `expectedDeliveryDate`): "🚚 Agizo [PO-number] kutoka [supplier] linatarajiwa leo. Je, bidhaa zimefika?" / "🚚 Order [PO-number] from [supplier] is due for delivery today. Have the goods arrived?"
- 🔔 **Delivery overdue** (1 day after `expectedDeliveryDate`, status still `sent`): "⏰ Agizo [PO-number] lilikuwa litafikia jana — bado halijapokelewa. Wasiliana na [supplier]" / "⏰ Order [PO-number] was due yesterday — not yet received. Contact [supplier]"
- 📊 **Weekly PO summary** (Monday 8:00am): "📦 Wiki hii: maagizo [N] yaliyotumwa, [N] yaliyopokelewa, [N] yanayosubiri. Jumla ya manunuzi: TZS [amount]" / "📦 This week: [N] orders sent, [N] received, [N] pending. Total procurement: TZS [amount]"
- ⚠️ **Draft sitting idle** (draft PO not sent after 3 days): "⚠️ Agizo [PO-number] bado ni rasimu kwa siku 3. Litume au lifute ili orodha iwe safi" / "⚠️ Order [PO-number] has been a draft for 3 days. Send or cancel to keep your list clean"

### Reports & Insights
- **Procurement summary:** Total POs this month by status (draft/sent/received/cancelled) — shown as summary chips above the list
- **Pending value:** Total TZS value of all sent POs not yet received — "goods in transit"
- **Receipt rate:** % of sent POs marked received within the expected delivery window (this month vs last month)
- **Most active supplier:** Supplier with the most POs this month

### Cross-Module Connections
- **Expenses:** Each received PO feeds `ExpenditureService` as a business expense when payment is recorded (accounts payable, Feature 13)
- **Budget:** Procurement spend tracked against business operating budget envelope
- **Calendar:** Delivery dates from POs sync to `CalendarService.createEvent()` as "Kupokea: [PO-number]" / "Receive: [PO-number]" — visible in the Calendar module
- **Reminders:** Overdue delivery and idle draft POs surface in the Reminders module (`/biz_po` source route already registered in `reminder_navigation.dart`)
- **Shangazi AI:** "Nikusaidie kuchunguza matumizi ya manunuzi" / "Help me analyse my procurement spending" — Shangazi receives PO summary and surfaces patterns

---

## 5. CREATE PURCHASE ORDER

**Entry:** Purchase Order list → FAB (+) → `_showCreateSheet()`
**Stage/Context:** Placing a new order with a supplier — after stock runs low, before market day, or in response to a customer request

### User Journey
1. User taps FAB (+) on the PO list
2. `_showCreateSheet()` modal bottom sheet slides up (scrollable, white background, rounded top 20)
3. **Drag handle** at top-center
4. **Title:** "Agizo Jipya la Manunuzi" / "New Purchase Order" (16sp, bold)
5. **Supplier section:**
   - If `_suppliers` list is non-empty: Dropdown "Chagua Msambazaji" / "Select Supplier" showing all registered suppliers + a "Andika jina" / "Type name" option at top
   - Selecting a named supplier auto-fills name; selecting "Type name" shows a TextField: "Jina la Msambazaji" / "Supplier Name" for freehand entry
   - If `_suppliers` is empty: only the TextField shown
6. **Line items builder:**
   - Row of 3 inputs + Add icon button:
     - `Flex(2)` TextField: "Bidhaa" / "Item" (description, 13sp)
     - `SizedBox(50)` TextField: "Qty" (number keyboard, 13sp, default 1)
     - `Expanded` TextField: "Bei" / "Price" (number keyboard, 13sp)
     - `IconButton(Icons.add_circle_rounded)` — validates and adds item
   - Validation for Add button: description non-empty AND price > 0; quantity defaults to 1 if blank
   - Added items listed above the input row: "[description] x[qty]" on left, "TZS [total]" on right (13sp)
   - After 1+ items added: Divider + "JUMLA / TOTAL: TZS [sum]" row (bold)
7. **Delivery date picker:**
   - `InputDecorator` showing "Tarehe ya Kupokea" / "Expected Delivery Date" + calendar icon
   - Tap → `showDatePicker(firstDate: today, lastDate: today+365)`
   - Defaults to 7 days from today
8. **Notes field:**
   - 2-line TextField: "Maelezo" / "Notes" — delivery instructions, quality requirements, etc.
9. **Submit button** ("Unda Agizo" / "Create Order", full-width 48dp, dark):
   - Disabled while submitting — shows `CircularProgressIndicator(strokeWidth: 2, color: white)`
   - Validates: supplier name non-empty AND at least one item added
   - On tap: `POST /business/:id/purchase-orders` with body: `{business_id, supplier_id?, supplier_name, items[], subtotal, vat_amount: 0, total_amount, status: 'draft', expected_delivery_date, notes}`
10. **On success:** Sheet closes (`ctx.mounted` check) → Snackbar "Agizo limeundwa" / "Order created" → `_loadOrders()` refreshes list
11. **On failure (catch):** `setSheetState(() => submitting = false)` — sheet stays open. Snackbar: "Imeshindikana. Jaribu tena." / "Failed. Please try again." (red)

### CRUD Operations
- **Create:** `POST /business/:id/purchase-orders` — creates in `draft` status
- **Read:** NOT from this sheet — view via PO list and detail page
- **Edit:** NOT AVAILABLE after creation — gap flagged (Feature 8)
- **Delete:** NOT AVAILABLE from this sheet — cancel via PO list card action

### Notifications & Reminders
- 🎉 **First PO created:** "🎉 Agizo lako la kwanza la manunuzi limeundwa! Litume kwa msambazaji wako ili uanze." / "🎉 Your first purchase order is created! Send it to your supplier to get started."
- 💡 **No supplier linked** (if freehand supplier name used): in-app snackbar suggestion after success: "Hifadhi '[name]' kama msambazaji wa kudumu?" / "Save '[name]' as a permanent supplier?" — Yes button opens Add Supplier sheet pre-filled

### Reports & Insights
- **Item frequency:** Which items appear most often across POs — feeds into Supplier Catalog suggestion (Feature 11)
- **Average order value:** Per supplier, computed over time

### Cross-Module Connections
- **Calendar:** On PO creation, offer to save delivery date to calendar: "Hifadhi tarehe ya kupokea kwenye kalenda?" / "Save delivery date to calendar?" — calls `CalendarService.createEvent(title: 'Kupokea: [PO-number]', date: expectedDeliveryDate)`
- **Supplier Catalog (future):** When a supplier is selected from the dropdown, show "Pakia orodha ya kawaida" / "Load usual items" button → fills item rows from saved catalog
- **Budget:** On create, immediately log projected expense against procurement budget envelope (confirmed on receipt)

---

## 6. PURCHASE ORDER DETAIL PAGE

**Entry:** PO list → tap any PO card → `_PurchaseOrderDetailPage`
**Stage/Context:** Reviewing an order before sending it, inspecting a received delivery, or verifying what was originally ordered vs what arrived

### User Journey
1. User taps anywhere on a PO card (outside action buttons)
2. `Navigator.push` to `_PurchaseOrderDetailPage` (full Scaffold)
3. **AppBar:**
   - Back button (dark)
   - Title: PO number ("PO-2026-042") or fallback "PO-[id]"
   - Trailing status chip: color-coded badge (grey=Draft, blue=Sent, green=Received, red=Cancelled)
4. **Detail rows (shown only if field non-null/non-empty):**
   - "Msambazaji" / "Supplier" — supplier name
   - "Tarehe ya Kupokea" / "Expected Delivery" — dd/MM/yyyy
   - "Maelezo" / "Notes" — notes text
5. **Items section:**
   - Section header: "Bidhaa" / "Items" (14sp, bold)
   - **Empty:** "Hakuna bidhaa" / "No items" (grey, 13sp)
   - **With items:** White card with rounded border, containing:
     - Header row: "Maelezo" / "Description" · "Qty" · "Jumla" / "Total" (11sp, grey, bold)
     - Divider
     - Per-item row: description (Expanded) | qty.toStringAsFixed(0) | "TZS [totalPrice]" (90px wide, right-aligned, 13sp, bold)
     - Divider
     - Total row: "JUMLA" / "TOTAL" (bold) | "TZS [totalAmount]" (15sp, bold, right-aligned)
6. **Action buttons (full-width, 48dp):**
   - **Draft:** "Tuma Agizo" / "Send Order" (dark FilledButton with send icon) — calls `_markSent()` then pops; + "Futa Agizo" / "Cancel Order" (red OutlinedButton)
   - **Sent:** "Imepokelewa" / "Mark as Received" (green FilledButton with check icon) — calls `_markReceived()` then pops; + "Futa Agizo" / "Cancel Order" (red OutlinedButton)
   - **Received / Cancelled:** no action buttons shown
7. Action handlers pop the detail page first, then call the parent's action method (snackbar + reload happen on the list screen)

### CRUD Operations
- **Create:** NOT AVAILABLE from detail — use FAB on list
- **Read:** Full PO data rendered — items, totals, dates, notes, status
- **Edit:** NOT AVAILABLE — gap flagged (Feature 8)
- **Delete/Cancel:** "Futa Agizo" / "Cancel Order" button → parent `_cancelOrder()` → confirmation dialog → API call

### Notifications & Reminders
- *(Notifications triggered by Send/Received/Cancel actions — covered in Feature 7, 9)*

### Reports & Insights
- **Future:** "Reorder" button — creates a copy of this PO as a new draft (Feature 10)
- **Future:** "Angalia Matumizi" / "View Analytics" link to supplier spending chart (Feature 12)

### Cross-Module Connections
- **Expenses:** "Lipa Msambazaji" / "Pay Supplier" button (future, Feature 13) → routes to accounts payable entry for this PO
- **Shangazi AI:** "Uliza Shangazi kuhusu agizo hili" / "Ask Shangazi about this order" — passes items and total; Shangazi can assess if market prices are competitive

---

## 7. SEND PURCHASE ORDER TO SUPPLIER

**Entry:** PO list → Draft card → "Tuma" / "Send" button; or PO Detail → "Tuma Agizo" / "Send Order"
**Stage/Context:** Business owner has finalised the order and wants to formally notify the supplier

### User Journey
1. User taps "Tuma" / "Send" on the PO card or "Tuma Agizo" / "Send Order" on the detail page
2. `_markSent()` calls `POST /business/purchase-orders/:id/send`
3. **On API success:**
   - Snackbar: "Agizo limetumwa" / "Order sent" (default background)
   - `_loadOrders()` refreshes list — PO moves from "Rasimu" / "Draft" tab to "Zimetumwa" / "Sent" tab
   - **Share prompt** (bottom sheet): "Tuma agizo kwa msambazaji?" / "Share order with supplier?"
     - Option A: **WhatsApp** (icon + label) — generates pre-filled message with PO summary and opens `wa.me/[supplierPhone]`
     - Option B: **Pakua PDF** / **Download PDF** — generates and downloads branded PDF
     - Option C: **Nakili Nambari** / **Copy Reference** — copies PO number to clipboard with "Imenakiliwa" / "Copied" snackbar
     - "Sasa Hivi Sio" / "Not Now" — dismisses sheet
4. **WhatsApp message pre-fill:**
   ```
   Habari [supplier_name],
   
   Naomba kuagiza bidhaa zifuatazo:
   
   [item 1] × [qty] — TZS [total]
   [item 2] × [qty] — TZS [total]
   ...
   
   Jumla: TZS [totalAmount]
   Tarehe ya kupokea: [dd/MM/yyyy]
   Nambari ya Agizo: [PO-number]
   
   Asante,
   [businessName] (kupitia TAJIRI)
   ```
5. **PDF content:**
   - Business name + logo at top
   - "AGIZO LA MANUNUZI" / "PURCHASE ORDER" heading
   - PO number, date issued, expected delivery date
   - Supplier details (name, phone, address, TIN if available)
   - Business details (name, TIN, phone)
   - Line items table (description, qty, unit price, total)
   - Subtotal, VAT, Grand Total row
   - Notes section
   - "Imetolewa kupitia TAJIRI" footer
6. **On API failure:** Snackbar: error message (red background) — status does not change

### CRUD Operations
- **Create:** NOT AVAILABLE (PO already exists as draft)
- **Read:** PO data rendered in share message / PDF
- **Edit:** NOT AVAILABLE — edit draft before sending (Feature 8)
- **Delete:** NOT AVAILABLE — cancel via Cancel action

### Notifications & Reminders
- 🔔 **Supplier not confirmed after 48 hours** (sent PO with no received status): "🔔 Agizo [PO-number] limetumwa siku 2 zilizopita — hakuna uthibitisho bado. Piga simu [supplier]" / "🔔 Order [PO-number] sent 2 days ago — no confirmation yet. Call [supplier]"
- 🔔 **Delivery date approaching** (3 days before): "🚚 Agizo [PO-number] linatarajiwa kufika katika siku 3. Thibitisha na [supplier]" / "🚚 Order [PO-number] expected in 3 days. Confirm with [supplier]"

### Reports & Insights
- **Send-to-receive time:** Average days between PO sent and marked received per supplier — surfaces slow suppliers
- **Unconfirmed sent POs:** Count of sent POs older than 7 days with no received status (attention list)

### Cross-Module Connections
- **Calendar:** Delivery date event created automatically when order is sent (if not already created at order creation)
- **Reminders:** Sent PO with approaching delivery date appears in Reminders module as "🚚 Delivery due: [PO-number]"
- **WhatsApp (url_launcher):** `url_launcher` opens `https://wa.me/[phone]?text=[encoded message]`

---

## 8. PO EDITING (Draft Amendment)

**Entry:** PO list → Draft card → "Hariri" / "Edit" action (not yet implemented) OR PO Detail → "Hariri Agizo" / "Edit Order"
**Stage/Context:** Business owner created a draft but needs to change items, quantities, or delivery date before sending

### User Journey
1. User taps "Hariri" / "Edit" on a draft PO (list card `⋮` menu or detail page button)
2. Opens the same sheet as Create PO, but pre-filled:
   - Supplier dropdown or name field pre-selected
   - Line items pre-populated (each item row shown with delete icon)
   - Delivery date pre-set
   - Notes pre-filled
3. User changes items: tap item to edit inline, or swipe item left to delete, or add new item via input row
4. Taps "Sasisha Agizo" / "Update Order" (replaces "Unda Agizo" / "Create Order")
5. `PUT /business/purchase-orders/:id` — body: same as create body
6. **On success:** Sheet closes → Snackbar "Agizo limesasishwa" / "Order updated" → list reloads
7. **On failure:** Sheet stays open → Snackbar error (red)
8. **Lock:** Edit is only available when status is `draft`. Attempting to edit a `sent` PO shows: "Agizo lililotumwa haliwezi kubadilishwa. Unda agizo jipya." / "A sent order cannot be edited. Create a new order."

### CRUD Operations
- **Create:** NOT AVAILABLE from edit sheet
- **Read:** Form pre-filled from existing `PurchaseOrder` object
- **Edit:** `PUT /business/purchase-orders/:id`
- **Delete:** NOT AVAILABLE from edit sheet — cancel via list

### Notifications & Reminders
- *(No push notifications for edit — internal action)*

### Reports & Insights
- *(No dedicated report — edit feeds into the PO record that analytics use)*

### Cross-Module Connections
- **Calendar:** If delivery date changes, update the corresponding calendar event for that PO

---

## 9. GOODS RECEIPT (Mark as Received)

**Entry:** PO list → Sent card → "Pokelewa" / "Received" button; or PO Detail → "Imepokelewa" / "Mark as Received"
**Stage/Context:** Delivery truck arrives; business owner counts goods and records what came in

### User Journey
1. User taps "Pokelewa" / "Received" on the PO card or detail page
2. **Phase 1 (current):** `_markReceived()` calls `POST /business/purchase-orders/:id/received`
   - Snackbar: "Imepokelewa" / "Marked as received" on success
   - `_loadOrders()` refreshes — PO moves to "Zimepokelewa" / "Received" tab
3. **Phase 2 — Partial Delivery (spec):** Before calling API, show a receipt confirmation sheet:
   - Title: "Thibitisha Kupokea" / "Confirm Receipt"
   - Sub-text: "Ingiza kiasi kilichopokelewa kwa kila bidhaa" / "Enter the quantity received for each item"
   - Per-item row: item description + ordered qty on left → received qty TextField on right (pre-filled with ordered qty)
   - "Thibitisha" / "Confirm" button (dark, full-width)
4. **If all received quantities == ordered quantities:**
   - `POST /business/purchase-orders/:id/received` with no changes → status → `received`
   - Snackbar: "Bidhaa zote zimepokelewa" / "All goods received"
5. **If any shortfall:**
   - `POST /business/purchase-orders/:id/received` with body `{items: [{id, received_qty}]}`
   - Status → `partially_received`
   - Snackbar: "Baadhi ya bidhaa hazijafika — agizo linarekebisha" / "Some items missing — order updated"
   - PO card now shows shortfall summary: "Imepoteza bidhaa [N]" / "[N] items short"
6. **Received PO (in list):** Status chip shows green "Imepokelewa" / "Received" — no action buttons
7. **Received PO (in detail):** Action buttons removed; items table shows "Received: [qty]" if partial

### CRUD Operations
- **Create:** NOT AVAILABLE — receipt updates the existing PO
- **Read:** PO detail shows received status and item confirmation
- **Edit:** NOT AVAILABLE — receipt is final
- **Delete:** NOT AVAILABLE — received POs are permanent records

### Notifications & Reminders
- 🎉 **Full receipt:** "✅ Agizo [PO-number] kutoka [supplier] limepokelewa kikamilifu. TZS [totalAmount] ya manunuzi." / "✅ Order [PO-number] from [supplier] fully received. TZS [totalAmount] in procurement."
- ⚠️ **Partial receipt:** "⚠️ Agizo [PO-number]: bidhaa [N] bado hazijakuja kutoka [supplier]. Wasiliana nao." / "⚠️ Order [PO-number]: [N] items still missing from [supplier]. Contact them."
- 🔔 **Shortfall follow-up** (3 days after partial receipt): "🔔 Agizo [PO-number] bado lina upungufu wa bidhaa [N]. Je, msambazaji ameleta?" / "🔔 Order [PO-number] still has [N] missing items. Has the supplier delivered?"

### Reports & Insights
- **Fill rate:** % of ordered quantity actually received per supplier — identifies unreliable vendors
- **Delivery time:** Days from PO sent to PO received — average and trend per supplier
- **Shortfall history:** Which suppliers have the most partial deliveries

### Cross-Module Connections
- **Expenses:** On full receipt, prompt: "Rekodi malipo ya msambazaji" / "Record supplier payment" → opens accounts payable entry (Feature 13)
- **Inventory (future):** Received items can trigger stock increment if inventory module is connected
- **Calendar:** Mark delivery calendar event as "completed" when receipt is confirmed
- **Budget:** Received PO value logged as actual procurement expense vs projected budget

---

## 10. REORDER FROM EXISTING PO

**Entry:** PO Detail (received or cancelled PO) → "Agiza Tena" / "Reorder" button (not yet implemented)
**Stage/Context:** Weekly restock — same items, same supplier, roughly same quantities

### User Journey
1. User opens a received or cancelled PO via PO Detail page
2. Taps "Agiza Tena" / "Reorder" button (below the items table)
3. App creates a new draft PO pre-filled with:
   - Same supplier (linked or freehand name)
   - Same line items and quantities
   - Same notes
   - Delivery date: today + 7 days (editable)
4. Opens the Create PO sheet pre-filled (not directly creating without review)
5. User can adjust quantities, add/remove items, change delivery date
6. Taps "Unda Agizo" / "Create Order" → same flow as Feature 5
7. Snackbar: "Agizo jipya limeundwa kutoka agizo [PO-number]" / "New order created from [PO-number]"

### CRUD Operations
- **Create:** New draft PO via `POST /business/:id/purchase-orders`
- **Read:** Original PO data used to pre-fill form
- **Edit:** Pre-filled form is fully editable before submission
- **Delete:** NOT AVAILABLE — cancel the new draft via list if needed

### Notifications & Reminders
- 💡 **Reorder suggestion** (when a supplier's received PO is older than 14 days and no new PO exists for same supplier): "💡 Uliagiza kutoka [supplier] wiki 2 zilizopita. Je, ni wakati wa kuagiza tena?" / "💡 You ordered from [supplier] 2 weeks ago. Time to reorder?"
- 💡 **Recurring pattern detected** (if same items ordered every 7 days): "💡 Unaagiza [item] kila wiki. Unataka kuunda agizo la mara kwa mara?" / "💡 You order [item] weekly. Want to create a recurring order?"

### Reports & Insights
- **Reorder cycle:** Average days between consecutive orders from the same supplier — suggests optimal restock frequency
- **Order consistency:** Whether quantities per item are stable or fluctuating — if stable, catalog it

### Cross-Module Connections
- **Supplier Catalog:** Items from reordered POs suggested for addition to the supplier's catalog (Feature 11)
- **Budget:** Reorder triggers same projected expense logging as a fresh PO

---

## 11. SUPPLIER CATALOG

**Entry:** Supplier Detail view → "Orodha ya Kawaida" / "Catalog" section (not yet implemented)
**Stage/Context:** Setting up standard items to fast-track future purchase orders — done once per supplier, saves time every reorder

### User Journey
1. User taps a supplier → detail sheet → taps "Orodha" / "Catalog" tab or button
2. List of `SupplierCatalogItem` rows: item description, default quantity, unit price (13sp)
3. **Empty state:** "Hakuna bidhaa za orodha bado. Ongeza bidhaa zinazoonekana mara nyingi" / "No catalog items yet. Add items you order frequently"
4. **Add item** via + FAB or "Ongeza Bidhaa" / "Add Item" button:
   - Bottom sheet: Description (required), Default Qty (number, default 1), Unit Price (TZS, required)
   - "Ongeza" / "Add" → `POST /business/suppliers/:id/catalog`
5. **Edit item:** Tap item → pre-filled sheet → "Sasisha" / "Update" → `PUT /business/suppliers/catalog/:id`
6. **Delete item:** Swipe left → delete icon → confirmation → `DELETE /business/suppliers/catalog/:id`
7. **Use in Create PO:** When creating a PO with a supplier that has a catalog:
   - "Pakia Orodha ya Kawaida" / "Load Usual Items" button appears in the Create PO sheet
   - Tapping it fills all item rows from the catalog (quantities and prices pre-set)
   - User adjusts and taps "Unda Agizo" / "Create Order"

### CRUD Operations
- **Create:** "Ongeza Bidhaa" / "Add Item" → `POST /business/suppliers/:id/catalog`
- **Read:** Catalog item list in supplier detail; auto-loaded in Create PO sheet
- **Edit:** Tap item → edit sheet → `PUT /business/suppliers/catalog/:id`
- **Delete:** Swipe left / long press → `DELETE /business/suppliers/catalog/:id`

### Notifications & Reminders
- 💡 **Catalog setup prompt** (after 3 POs from the same supplier): "💡 Umeagiza kutoka [supplier] mara 3. Hifadhi bidhaa za kawaida ili kuunda maagizo haraka" / "💡 You've ordered from [supplier] 3 times. Save usual items to create orders faster"

### Reports & Insights
- **Catalog coverage:** % of PO line items that match catalog items — higher = faster order creation
- **Price drift:** If the price in a PO differs from the catalog price by >10%: highlight "Bei imebadilika. Sasisha orodha?" / "Price changed. Update catalog?"

### Cross-Module Connections
- **Reorder (Feature 10):** Reorder flow auto-populates from catalog if available
- **Spending Analytics (Feature 12):** Catalog items contribute to per-item spend breakdown

---

## 12. SPENDING ANALYTICS PER SUPPLIER

**Entry:** Supplier Detail view → "Angalia Matumizi" / "View Spending" button (not yet implemented); or Business Analytics overview → Suppliers section
**Stage/Context:** Before a supplier negotiation, at month-end reconciliation, or when deciding whether to switch vendors

### User Journey
1. User taps "Angalia Matumizi" / "View Spending" from a supplier's detail sheet
2. Navigates to `SupplierAnalyticsPage(supplierId:, supplierName:)` (full screen)
3. **AppBar:** "Matumizi — [Supplier Name]" / "Spending — [Supplier Name]"
4. **Header stats (3 cards):**
   - "Mwezi Huu" / "This Month" — TZS [amount]
   - "Mwaka Huu" / "This Year" — TZS [amount]
   - "Maagizo Yote" / "Total Orders" — [count] received POs
5. **Monthly trend chart:** Bar chart, last 6 months. Each bar = total TZS received from this supplier that month. Tap bar → shows exact amount.
6. **Top items section:** "Bidhaa Zinazoonekana Zaidi" / "Most Ordered Items" — top 3 items by total value, each shown as: item name · "TZS [total]" · "[N] mara" / "[N] times"
7. **PO history list:** Last 5 received POs from this supplier — PO number, date received, total amount. Tap → PO detail
8. **Comparison note:** "Mwezi huu vs mwezi uliopita: [+/-X%]" / "This month vs last month: [+/-X%]" (green if down, red if up — spending lower is good)
9. `GET /business/:id/suppliers/:sid/analytics` returns: monthly totals, item frequency, PO list

### CRUD Operations
- **Create:** NOT AVAILABLE — analytics is read-only
- **Read:** Charts, totals, and PO history rendered from analytics endpoint
- **Edit:** NOT AVAILABLE
- **Delete:** NOT AVAILABLE

### Notifications & Reminders
- ⚠️ **Spend spike** (current month spend >50% higher than previous month for same supplier): "⚠️ Matumizi kutoka [supplier] yamepanda [X]% mwezi huu — TZS [amount] vs TZS [last_month]. Angalia maagizo yako" / "⚠️ Spending from [supplier] up [X]% this month — TZS [amount] vs TZS [last_month]. Review your orders"
- 📊 **Monthly supplier digest** (included in business monthly report): "Msambazaji mkubwa mwezi huu: [supplier] — TZS [amount]"

### Reports & Insights
- **Spend per supplier as % of total procurement:** "Supplier X accounts for 42% of total procurement — concentration risk"
- **Price trend:** Average unit price paid for a catalog item over time — detects price creep
- **Delivery time trend:** Average days from PO sent to received per supplier — deteriorating trend flags reliability issues
- **Shareable:** "Shiriki Ripoti" / "Share Report" → generates a text summary for sharing via WhatsApp with the supplier as leverage in negotiations

### Cross-Module Connections
- **Budget:** Supplier spend feeds into procurement budget envelope with variance tracking
- **Expenses:** Supplier spend total reconciled against recorded expenses category
- **Shangazi AI:** Pass analytics data to Shangazi: "Ninamlipa [supplier] TZS [amount] kwa mwaka. Nikusaidie kupata mkakati wa kupunguza gharama?" / "I'm paying [supplier] TZS [amount] per year. Help me strategise to reduce costs?"

---

## 13. ACCOUNTS PAYABLE (Credit Terms with Suppliers)

**Entry:** PO Detail (received PO) → "Lipa Msambazaji" / "Pay Supplier" (not yet implemented); or Business → Accounts Payable overview
**Stage/Context:** Supplier delivered goods on credit — "lipa mwezi ujao" — business needs to track and settle the balance before relationship sours

### User Journey
1. User marks a PO as received (Feature 9)
2. **Prompt:** "Umelipa msambazaji?" / "Did you pay the supplier?"
   - "Ndio, Nimelipa" / "Yes, Paid Now" → records an expense immediately (see step 7)
   - "Hapana, Nitalipia Baadaye" / "No, Pay Later" → opens credit terms entry sheet (step 3)
   - "Sio Sasa" / "Not Now" — dismisses without recording
3. **Credit terms sheet:**
   - Amount owed (pre-filled with PO total, editable)
   - Due date picker: "Lipa ifikapo" / "Pay by" (default: today + 30 days)
   - Notes (optional): "Makubaliano" / "Agreement notes"
   - "Hifadhi" / "Save Payable" → `POST /business/purchase-orders/:id/payable`
4. **Accounts Payable list** (accessible from Business overview or Supplier detail):
   - Shows all unpaid payables: supplier name, amount owed, due date, days until due / days overdue
   - Status chips: "Inadai" / "Unpaid" (grey), "Inakaribia" / "Due Soon" (amber), "Imechelewa" / "Overdue" (red)
5. **Record Payment** on a payable:
   - Tap payable → detail sheet: amount, supplier, due date, notes
   - "Rekodi Malipo" / "Record Payment" button → payment sheet:
     - Amount (pre-filled with balance, editable for partial)
     - Method: M-Pesa / Tigo Pesa / Airtel Money / Bank / Cash
     - Reference number (optional)
     - Date (defaults today)
     - Notes
   - Submit → `POST /business/payables/:id/payment`
6. **Partial payment:** Payable balance reduces; status shows "Imelipwa kiasi" / "Partially Paid" with remaining balance
7. **Full payment (or immediate pay at receipt):** `ExpenditureService.recordExpenditure(amount, category: 'Manunuzi', note: 'Supplier: [name], PO: [number]')` — feeds Budget module as a business expense

### CRUD Operations
- **Create:** Post-receipt prompt → `POST /business/purchase-orders/:id/payable`
- **Read:** Accounts payable list; tap → detail sheet with payment history
- **Edit:** NOT AVAILABLE — cancel payable and re-create if terms change
- **Delete:** "Futa Deni" / "Remove Payable" with confirmation — removes the payable record (does not affect PO status)

### Notifications & Reminders
- 🔔 **Due in 7 days:** "🔔 Malipo ya TZS [amount] kwa [supplier] yanakwisha siku 7. Jiandae!" / "🔔 TZS [amount] payment to [supplier] due in 7 days. Prepare!"
- 🔔 **Due tomorrow:** "⏰ Malipo ya TZS [amount] kwa [supplier] yanakwisha kesho. Lipa leo ili kuepuka usumbufu." / "⏰ TZS [amount] to [supplier] due tomorrow. Pay today to avoid issues."
- ⚠️ **Overdue (1 day past due):** "⚠️ Malipo ya TZS [amount] kwa [supplier] yamechelewa! Wasiliana nawe sasa." / "⚠️ TZS [amount] to [supplier] is overdue! Contact them now."
- ⚠️ **Overdue (7 days past due):** "⚠️ Madeni ya msambazaji [supplier] yamechelewa siku 7 — TZS [amount]. Hii inaweza kuathiri uhusiano wenu." / "⚠️ [supplier] payment is 7 days overdue — TZS [amount]. This may affect your relationship."
- 📊 **Weekly payables summary** (Monday 8am): "📋 Madeni ya wasambazaji: TZS [total_unpaid]. Malipo [N] yanayokwisha wiki hii." / "📋 Supplier payables: TZS [total_unpaid]. [N] payments due this week."

### Reports & Insights
- **Total accounts payable:** Sum of all unpaid supplier balances — prominently shown in business financial overview
- **Overdue aging:** Payables grouped by age (0–7 days, 7–30 days, 30+ days)
- **Cash flow forecast:** Projected supplier payments due over next 30 days — "Unahitaji TZS [amount] kwa siku 30 zijazo kwa wasambazaji" / "You need TZS [amount] in the next 30 days for suppliers"
- **Supplier reliability:** Which suppliers give the longest credit terms, which demand immediate payment

### Cross-Module Connections
- **Budget:** Supplier payment records via `ExpenditureService` with category "Manunuzi" / "Procurement" — appears in envelope spending breakdown
- **Wallet:** "Lipa kupitia M-Pesa" / "Pay via M-Pesa" button routes through Wallet for digital disbursement and auto-references the PO number
- **Calendar:** Due dates for payables sync to Calendar as "💳 Lipa [supplier]: TZS [amount]" — visible in business calendar view
- **Reminders:** Payable due dates appear in Reminders module (`/biz_po` route, linked to accounts payable section) so the business owner never misses a supplier payment
- **Shangazi AI:** "Ninamdaiwa [supplier] TZS [amount] — nikusaidie kuandaa mtiririko wa pesa?" / "I owe [supplier] TZS [amount] — help me plan my cash flow?" — Shangazi receives payable schedule and wallet balance to recommend when to pay

---

## Notification Channel Summary

| Trigger | Text | Timing | Channel | Category |
|---------|------|---------|---------|----------|
| Delivery due today | "🚚 Agizo [PO-number] kutoka [supplier] linatarajiwa leo" | 8:00am on delivery date | Push | 🔔 Reminder |
| Delivery overdue (1 day) | "⏰ Agizo [PO-number] lilikuwa litafikia jana — bado halijapokelewa" | Day+1 after delivery date | Push | ⚠️ Alert |
| Sent PO unconfirmed (48h) | "🔔 Agizo [PO-number] limetumwa siku 2 — hakuna uthibitisho" | 48h after send | Push | 🔔 Reminder |
| Delivery approaching (3 days) | "🚚 Agizo [PO-number] linatarajiwa kufika siku 3" | 3 days before delivery date | Push | 🔔 Reminder |
| Full receipt confirmed | "✅ Agizo [PO-number] limepokelewa kikamilifu" | On action | In-app | 🎉 Celebration |
| Partial receipt | "⚠️ Agizo [PO-number]: bidhaa [N] bado hazijakuja" | On action | Push | ⚠️ Alert |
| Draft idle 3 days | "⚠️ Agizo [PO-number] bado ni rasimu kwa siku 3" | 3 days after creation | Push | ⚠️ Alert |
| First PO created | "🎉 Agizo lako la kwanza la manunuzi limeundwa!" | On action | In-app | 🎉 Celebration |
| First supplier prompt | "💡 Ongeza msambazaji wako wa kwanza kwenye TAJIRI" | 7 days after business registration | Push | 💡 Prompt |
| Catalog setup suggestion | "💡 Hifadhi bidhaa za kawaida ili kuunda maagizo haraka" | After 3rd PO from same supplier | Push | 💡 Prompt |
| Reorder suggestion | "💡 Uliagiza kutoka [supplier] wiki 2 zilizopita. Je, ni wakati wa kuagiza tena?" | 14 days after last received PO | Push | 💡 Prompt |
| Spend spike | "⚠️ Matumizi kutoka [supplier] yamepanda [X]% mwezi huu" | End of month | Push | ⚠️ Alert |
| Weekly PO summary | "📦 Wiki hii: maagizo [N] yaliyotumwa, [N] yaliyopokelewa" | Monday 8:00am | Push | 📊 Summary |
| Payable due in 7 days | "🔔 Malipo ya TZS [amount] kwa [supplier] yanakwisha siku 7" | 7 days before due date | Push | 🔔 Reminder |
| Payable due tomorrow | "⏰ Malipo ya TZS [amount] kwa [supplier] yanakwisha kesho" | 1 day before due date | Push | 🔔 Reminder |
| Payable overdue (1 day) | "⚠️ Malipo ya TZS [amount] kwa [supplier] yamechelewa!" | Day+1 after due date | Push | ⚠️ Alert |
| Payable overdue (7 days) | "⚠️ Madeni ya [supplier] yamechelewa siku 7" | Day+7 after due date | Push | ⚠️ Alert |
| Weekly payables summary | "📋 Madeni ya wasambazaji: TZS [total]. Malipo [N] yanayokwisha wiki hii" | Monday 8:00am | Push | 📊 Summary |

---

## Cross-Module Integration Map

| This Module | Direction | Other Module | Data / Trigger |
|-------------|-----------|--------------|----------------|
| Suppliers | → | Calendar | Delivery dates from POs synced as events |
| Suppliers | → | Reminders | Overdue delivery, idle drafts, payable due dates registered as reminders |
| Suppliers | → | Budget (ExpenditureService) | Supplier payments recorded as "Manunuzi" / "Procurement" expenses |
| Suppliers | → | Wallet | Supplier payment disbursement via M-Pesa routed through Wallet |
| Suppliers | ← | Reminders | `/biz_po` deep-link opens PO list from reminder tap |
| Suppliers | ↔ | Shangazi AI | Spend summary, negotiation context, cash flow planning |
| Suppliers | → | Analytics | Procurement spend feeds business financial overview and monthly report |
| Purchase Orders | → | Expenses | Received PO triggers expense record (immediate or via payable) |
| Purchase Orders | → | Calendar | `CalendarService.createEvent()` on PO creation and send |
| Accounts Payable | → | Budget | Payable settlement records as actual vs projected procurement spend |
| Accounts Payable | → | Wallet | M-Pesa payment initiation with PO reference |
| Accounts Payable | → | Calendar | Due dates synced as "💳 Lipa [supplier]" calendar events |
