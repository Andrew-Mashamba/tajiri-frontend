# Suppliers Module

**Location:** `lib/suppliers/`
**Entry points:**
- `lib/suppliers/pages/suppliers_page.dart` → `SuppliersPage`
- `lib/suppliers/pages/purchase_orders_page.dart` → `PurchaseOrdersPage`
**Barrel:** `lib/suppliers/suppliers.dart`
**Models:** `lib/business/models/business_models.dart` (`Supplier`, `PurchaseOrder`, `PurchaseOrderStatus`, `poStatusLabel`)
**Service:** `lib/business/services/business_service.dart` (static methods, shared with all business modules)

---

## Overview

The Suppliers module is the procurement layer of TAJIRI's business toolkit. It covers the two core concerns of buying from vendors: managing the vendor directory (who you buy from) and managing purchase orders (what you ordered, from whom, and whether it arrived). Together these pages answer the question every business owner asks on a delivery day: "What did we order, from who, and is it all here?"

In Tanzania's informal economy, supplier relationships are often tracked on paper, in notebooks, or not at all. A business owner who places 5–10 purchase orders per week with different suppliers has no consolidated view of what is pending, what has been received, and what is still outstanding. This module provides that view.

---

## Current State

### Suppliers (`SuppliersPage`)
- Flat list of business suppliers with name, phone, email, and TIN
- Search (server-side, by name)
- Add / edit / delete via bottom sheet form
- Tap card → detail bottom sheet: full contact info (phone, email, address, TIN, notes) + Edit and Delete actions
- Pull to refresh

### Purchase Orders (`PurchaseOrdersPage`)
- Tabbed list: All / Draft / Sent / Received (fourth tab for Cancelled is implicit in All)
- Create PO: supplier picker (dropdown from saved suppliers or freehand name), line item builder (description, quantity, price), delivery date picker, notes field
- Per-PO actions inline on card:
  - Draft → **Send** + **Cancel**
  - Sent → **Received** + **Cancel**
- Tap card → `_PurchaseOrderDetailPage`: full screen with items table (qty, totals), notes, delivery date, and contextual action buttons (Send Order / Mark as Received / Cancel Order)
- Pull to refresh per tab

---

## Backend Endpoints

| Method | Endpoint | Service method | Purpose |
|--------|----------|----------------|---------|
| `GET` | `/business/:id/suppliers?search=` | `getSuppliers` | Fetch supplier list |
| `POST` | `/business/:id/suppliers` | `addSupplier` | Create supplier |
| `PUT` | `/business/suppliers/:id` | `updateSupplier` | Update supplier |
| `DELETE` | `/business/suppliers/:id` | `deleteSupplier` | Delete supplier |
| `POST` | `/business/:id/purchase-orders` | `createPurchaseOrder` | Create PO (status: draft) |
| `GET` | `/business/:id/purchase-orders?status=` | `getPurchaseOrders` | Fetch PO list |
| `POST` | `/business/purchase-orders/:id/send` | `markPOSent` | Advance draft → sent |
| `POST` | `/business/purchase-orders/:id/received` | `markPOReceived` | Advance sent → received |
| `POST` | `/business/purchase-orders/:id/cancel` | `cancelPO` | Cancel draft or sent PO |

---

## Data Models

### Supplier
```
Supplier {
  id              → backend ID (nullable during creation)
  businessId      → owning business
  name            → supplier company or person name (required)
  phone           → contact phone (nullable)
  email           → contact email (nullable)
  address         → physical address (nullable)
  tinNumber       → TRA TIN (nullable, for supplier invoices and tax records)
  notes           → free text notes (nullable)
  createdAt       → creation timestamp (nullable)
}
```

### PurchaseOrder
```
PurchaseOrder {
  id                   → backend ID
  businessId           → owning business
  poNumber             → auto-generated reference (e.g., "PO-2026-042"); falls back to "PO-{id}" in UI if empty
  supplierId           → linked supplier ID (nullable — freehand supplier name allowed)
  supplierName         → display name (may come from linked supplier or typed directly)
  items                → List<InvoiceItem> — line items (description, quantity, unitPrice, totalPrice)
  subtotal             → sum of item totals
  vatAmount            → VAT on the order (currently always 0 — not yet applied)
  totalAmount          → subtotal + vatAmount
  status               → draft | sent | received | cancelled
  expectedDeliveryDate → expected arrival date (nullable)
  notes                → delivery or quality instructions (nullable)
  createdAt            → creation timestamp (nullable)
}
```

### PurchaseOrderStatus
```
draft      → created, not yet sent to supplier      (Rasimu)
sent       → submitted to supplier, awaiting goods  (Imetumwa)
received   → goods delivered and accepted           (Imepokelewa)
cancelled  → voided before receipt                  (Imefutwa)
```

---

## PO Lifecycle

```
┌───────┐    send     ┌──────┐    received   ┌──────────┐
│ DRAFT │───────────▶│ SENT │──────────────▶│ RECEIVED │
└───────┘             └──────┘              └──────────┘
    │                    │
    │ cancel             │ cancel
    ▼                    ▼
┌───────────┐        ┌───────────┐
│ CANCELLED │        │ CANCELLED │
└───────────┘        └───────────┘
```

- A PO is created as `draft`. It can be edited only while in draft (currently no edit UI — a gap).
- `send` advances it to `sent`. The supplier should now act on it.
- `received` marks goods as arrived. This is the final positive state.
- `cancel` is available from draft or sent; cancelled POs remain visible in the "All" tab.

---

## Navigation Entry Points

The module is reached from the Business profile screen. Both pages are embedded via `BizTabWrapper`:

```dart
// lib/screens/profile/profile_screen.dart
case '/biz_suppliers':
  page = BizTabWrapper(
    userId: profileUserId,
    builder: (uid, all, first, fId) =>
        fId != null ? SuppliersPage(businessId: fId) : const SizedBox.shrink(),
  );

case '/biz_po':
  page = BizTabWrapper(
    userId: profileUserId,
    builder: (uid, all, first, fId) =>
        fId != null ? PurchaseOrdersPage(businessId: fId) : const SizedBox.shrink(),
  );
```

The reminder deep-link system (`lib/reminders/reminder_navigation.dart`) also registers both routes (`/biz_suppliers`, `/biz_po`) so reminders about pending POs can navigate directly to the list.

---

## Feature Specifications

---

### 1. PO Editing (Draft Amendment)

**What it is:**
Allow a draft PO to be edited — add, remove, or update line items; change supplier; change delivery date or notes — before it is sent.

**Current state:** Once created, a draft PO can only be sent or cancelled. There is no edit action.

**Why it matters:**
Orders change. A business owner creates a draft, then realises they need 20 units instead of 10, or forgot to add an item. The only current workaround is to cancel and re-create from scratch.

**Implementation notes:**
- Add an "Edit" action to the draft PO card and the detail page (alongside Send and Cancel)
- Reuse `_showCreateSheet` pre-filled with existing PO data, but call `updatePurchaseOrder` on submit
- Backend: `PUT /business/purchase-orders/:id` — update items, delivery date, notes (draft only; sent/received/cancelled are locked)
- Disallow editing once status is `sent`

---

### 2. Send PO to Supplier (WhatsApp / Email / PDF)

**What it is:**
When a PO is marked "sent," share a formatted PO document with the supplier directly from the app.

**Current state:** The "Send" action updates status to `sent` but does not actually notify the supplier. There is no delivery mechanism — the business owner must inform the supplier separately.

**Why it matters:**
A purchase order that never reaches the supplier is just an internal record. The value of a PO system is that both parties have the same document. Sharing via WhatsApp (the dominant business communication channel in Tanzania) closes the loop.

**Implementation notes:**
- After `markPOSent` succeeds, show a share bottom sheet: "Share PO with supplier?"
- Options: WhatsApp (pre-filled message with PO summary + PDF), PDF download, Copy reference number
- PDF: business name + logo, supplier name, PO number, line items table, total, delivery date, notes, "Issued by TAJIRI"
- If supplier has a phone number, pre-fill the WhatsApp number; otherwise show a phone input
- Supplier's phone comes from the linked `Supplier` record if `supplierId` is set

---

### 3. Goods Receipt with Partial Delivery

**What it is:**
When marking a PO as received, allow the business owner to record which items actually arrived and in what quantity. Flag any shortfall.

**Current state:** "Mark as Received" is binary — the whole PO is either received or not. There is no way to record partial delivery.

**Why it matters:**
Partial delivery is common. A supplier delivers 8 of the 10 items ordered and says the rest is coming next week. The business currently has no way to record this — they must either mark the whole PO received (incorrect) or leave it as `sent` indefinitely (loses track).

**Implementation notes:**
- On "Received" tap, show a confirmation sheet with the PO's line items
- Each item has a "received qty" input (pre-filled with ordered qty)
- If all quantities match: status → `received`
- If any shortfall: status → `partially_received` (new status) with shortfall items stored
- `partially_received` PO shows in Sent tab (still active), with a note showing which items are pending
- Backend: `POST /business/purchase-orders/:id/received` updated to accept `{ items: [{id, received_qty}] }`

---

### 4. Supplier Catalog (Items Usually Bought)

**What it is:**
A per-supplier list of products or services the business regularly orders from them — essentially a saved item list that can be loaded into a new PO with one tap.

**Why it matters:**
A business that buys the same 12 items from a supplier every week currently types those items manually into every PO. A catalog eliminates that friction. "New PO from [Supplier]" pre-fills the usual items and quantities; the owner just adjusts and sends.

**Implementation notes:**
- New model: `SupplierCatalogItem { id, supplierId, description, defaultQuantity, unitPrice, createdAt }`
- UI: In supplier detail page, add "Catalog" section — list of saved items with add/edit/delete
- When creating a PO and a supplier is selected: "Load from catalog" button fills items array
- Backend: `GET /business/suppliers/:id/catalog`, `POST /business/suppliers/:id/catalog`, `PUT /business/suppliers/catalog/:id`, `DELETE /business/suppliers/catalog/:id`

---

### 5. Spending Analytics per Supplier

**What it is:**
A summary view per supplier showing total spend (received POs), number of orders, most ordered items, and a monthly trend.

**Why it matters:**
A business owner negotiating with a supplier needs to know: "I've bought TZS 2.4M from you this year — I should be getting a discount." Without numbers, that negotiation is guesswork.

**Implementation notes:**
- Accessible from the supplier detail page: "View Spending"
- Show: Total spent (all-time and current month), Number of received POs, Most ordered items (top 3 by total value), Monthly trend chart (last 6 months, bar chart)
- Computed from existing PO data — no new models required
- Backend: `GET /business/:id/suppliers/:sid/analytics` returning aggregated spend data
- Client-side: could be computed from existing PO list filtered by `supplierId`, but server aggregation is more accurate over time

---

### 6. Accounts Payable (What You Owe Suppliers)

**What it is:**
A view showing received POs that have not yet been paid. The business ordered and received goods on credit terms and owes the supplier.

**Current state:** The module has no payment tracking. "Received" = done. There is no way to record that the supplier extended credit or track when payment is due.

**Why it matters:**
Supplier credit is ubiquitous in Tanzanian small business. A retailer receives stock and pays the supplier in 30 days. Without tracking this, the business has no visibility into its total supplier liabilities — a real cash flow risk.

**Implementation notes:**
- New model: `SupplierPayable { id, poId, supplierId, businessId, amount, dueDate, status (unpaid|partially_paid|paid), payments: List<SupplierPayment> }`
- A payable is created when a PO is marked received and the business records credit terms
- On "Mark as Received," ask: "Pay now or pay later?" If later, enter due date and amount owed
- Payables list accessible from supplier detail page and a top-level summary in the Suppliers screen header
- Integration with Expenses: paying a supplier payable records a business expense

---

### 7. Reorder from Existing PO

**What it is:**
A "Reorder" action on any completed PO that creates a new draft PO pre-filled with the same supplier, items, quantities, and delivery notes.

**Why it matters:**
Reorder is the most common PO action for a running business. A restaurant that orders the same supplies weekly shouldn't have to rebuild the PO from scratch each time.

**Implementation notes:**
- "Reorder" button on received/cancelled PO detail page
- Creates a new draft PO with the same data (supplier, items, notes) and today's date
- Delivery date defaults to +7 days from today
- Opens the create sheet pre-filled so the owner can adjust before creating

---

## Data Model Changes Required

| Field / Model | Where | Purpose |
|---------------|-------|---------|
| `status: partially_received` | `PurchaseOrderStatus` | Track partial delivery |
| `received_quantities` | `PurchaseOrder` | Per-item received qty on partial delivery |
| `SupplierCatalogItem` | New model | Saved items per supplier for fast PO creation |
| `SupplierPayable` | New model | Accounts payable for credit-term purchases |
| `SupplierPayment` | New model | Payment records against a payable |

---

## Backend Endpoints Required

| Method | Endpoint | Purpose |
|--------|----------|---------|
| `PUT` | `/business/purchase-orders/:id` | Edit draft PO |
| `GET` | `/business/suppliers/:id/catalog` | Fetch supplier catalog |
| `POST` | `/business/suppliers/:id/catalog` | Add catalog item |
| `PUT` | `/business/suppliers/catalog/:id` | Update catalog item |
| `DELETE` | `/business/suppliers/catalog/:id` | Delete catalog item |
| `GET` | `/business/:id/suppliers/:sid/analytics` | Spend analytics per supplier |
| `GET` | `/business/:id/payables` | All accounts payable |
| `POST` | `/business/purchase-orders/:id/payable` | Record credit terms on received PO |
| `POST` | `/business/payables/:id/payment` | Record payment against payable |

---

## Build Priority

| Priority | Feature | Effort |
|----------|---------|--------|
| 🔴 High | PO editing (draft amendment) | Low |
| 🔴 High | Send PO to supplier via WhatsApp/PDF | Medium |
| 🔴 High | Goods receipt with partial delivery | Medium |
| 🟡 Medium | Supplier catalog | Medium |
| 🟡 Medium | Reorder from existing PO | Low |
| 🟡 Medium | Spending analytics per supplier | Medium |
| 🟢 Later | Accounts payable (credit terms) | High |
