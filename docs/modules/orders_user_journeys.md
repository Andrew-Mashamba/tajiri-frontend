# Orders Module — Complete User Journeys

**Audit date:** 2026-04-22
**Module:** lib/orders/
**Source spec:** docs/modules/orders.md (to be written)

The Orders module is the **receiving inbox** for purchase orders placed against any business the user owns. A user may own multiple businesses; this module aggregates all incoming orders and lets the user filter per-business.

Every feature must be: **Interactive** (notifications, reminders, prompts), **Connected** (suppliers, chat, calls, calendar, accounting), and **Insightful** (reports, trends, recommendations).

---

## 1. ORDERS INBOX

**Entry:** Profile → Commerce → "Orders" tab (id: `orders_incoming`)
**Context:** Any user who owns at least one business can receive orders.

### User Journey
1. User taps "Orders" / "Maagizo" on their profile.
2. Top of page: segmented chips, one per owned business (e.g., "Baraka Shop", "Baraka Electronics", "All"). Default: "All".
3. Status filter row: "All", "Submitted", "Accepted", "Shipped", "Delivered", "Rejected".
4. List of orders, newest first, grouped visually under a "Receiving: [biz name]" header when "All" is selected.
5. Each row shows: PO number, buyer name + avatar (individual OR business logo), total amount, expected delivery date, status chip, ago-timestamp.
6. Pull-to-refresh reloads from `GET /api/business/users/{userId}/incoming-orders`.
7. Empty state: "No orders yet. When someone orders from one of your businesses, you'll see it here." / "Hakuna maagizo bado. Mtu akiagiza kwa biashara yako, yataonekana hapa."

### CRUD
- **Create:** NOT APPLICABLE — orders are created buyer-side (supplier detail page → New Order tab).
- **Read:** List + filters per business / status.
- **Edit:** Receiver cannot edit line items. Receiver can change status (see feature 3).
- **Delete:** NOT AVAILABLE — orders are audit records; rejected orders persist.

### Notifications & Prompts
- 🔔 **New order received** (push): "🛒 New order from [buyer name] — [items count] items, TZS [total]. Tap to review."
- ⚠️ **Stale submitted order** (local, 24h after submit): "Order [PO#] from [buyer] has been waiting 24h. Accept or reject?"
- 📊 **Daily digest** (evening): "Today: [X] new orders, [Y] accepted, [Z] pending. TZS [total] in pipeline."

### Reports
- **Today strip:** Count of submitted, accepted, shipped, delivered, rejected orders.
- **This week vs last week:** Order count trend per business.
- **Top buyers (30 days):** Top 5 buyers by order count or TZS value.
- **Fulfillment time:** Median hours from submitted → delivered.

### Cross-Module
- **Chat** (`/chat/:id` via `MessageService.getPrivateConversation`): "Message buyer" on each order.
- **Calls** (`OutgoingCallFlowScreen`): "Call buyer" action on individual buyers.
- **Calendar:** Accepted orders with `expected_delivery_date` auto-create a reminder event in Calendar.
- **Accounting:** On "Delivered", prompt "Record this as revenue?" → routes to income entry in Accounting.
- **Suppliers (buyer side):** Tapping a repeat buyer navigates back to their profile.

---

## 2. ORDER DETAIL

**Entry:** Tap any order row in inbox.

### User Journey
1. Full-screen view with buyer header card (avatar, name, handle, phone, "Chat" / "Call" actions if individual, or "Visit business" if buyer is a business).
2. "Receiving as: [my business name]" header.
3. Status timeline chip: submitted → accepted → shipped → delivered (rejected branch shown inline).
4. Items table: description, qty, unit price, line total. Subtotal, VAT (18%), total.
5. Expected delivery date, notes, PO number, created-at.
6. Action bar at bottom (visible by status — see feature 3).

### CRUD
- **Create / Edit / Delete:** NOT APPLICABLE on receiver side.
- **Read:** Full detail as above.

### Notifications & Prompts
- ⏰ **Delivery due reminder** (1 day before `expected_delivery_date`): "Order [PO#] for [buyer] is due tomorrow. Still on track?"
- 💡 **Prompt to message buyer** if order sat in "accepted" for >48h without shipping update: "Let [buyer] know when to expect delivery."

### Reports
- **Per-order:** Total value, payment status (when payable is linked), days since submitted.
- **Buyer history:** "[Buyer] has placed [N] orders with [my biz] totaling TZS [sum]."

### Cross-Module
- **Chat:** "Message buyer" in header → `/chat/:id` with `promptAfterCall` support for voice/video.
- **Calls:** Voice/video via `OutgoingCallFlowScreen`.
- **Suppliers:** Back-link to the buyer's profile if they're a platform business.
- **Calendar:** Delivery due auto-appears on day view.

---

## 3. STATUS LIFECYCLE

**Entry:** Action bar on Order Detail page.
**Context:** Receiver-driven status changes.

### User Journey (per status)
1. **Submitted:** Bar shows "Accept" (primary) + "Reject" (secondary). Tap Accept → API call → status → accepted. Tap Reject → dialog: "Reject order [PO#]?" with optional reason → API call → status → rejected.
2. **Accepted:** Bar shows "Mark Shipped" (primary) + "Message Buyer" (secondary).
3. **Shipped:** Bar shows "Mark Delivered" (primary).
4. **Delivered / Rejected:** Read-only, bar hidden.

All transitions hit `PATCH /api/business/incoming-orders/{id}/status` with `{user_id, status}`. Backend verifies the caller owns the receiving business.

### Notifications (receiver → buyer)
- **Accepted:** Push to buyer: "✅ [My biz] accepted your order [PO#]."
- **Rejected:** Push to buyer: "❌ [My biz] couldn't accept order [PO#]. [optional reason]"
- **Shipped:** Push to buyer: "📦 [My biz] shipped order [PO#]. Expected by [date]."
- **Delivered:** Push to buyer: "🎉 Order [PO#] delivered. Thanks for your business!"

### Reports
- **Accept rate:** accepted / (accepted + rejected) over 30 days per business.
- **Avg time to accept:** Median hours from submit → accept.

### Cross-Module
- **Budget / Accounting:** On "Delivered", offer "Record TZS [total] as revenue in [biz] accounting."
- **Calendar:** On "Accepted", add expected-delivery event automatically.
- **Chat:** Every status change offers a one-tap "Notify buyer" shortcut (opens chat with pre-filled message).

---

## 4. BUYER PROFILE PEEK

**Entry:** Tap buyer name/avatar on any order row or detail.

### User Journey
- **Individual buyer:** Navigate to `/profile/:userId`.
- **Business buyer:** Navigate to that business's public profile.

### Cross-Module
- **Chat / Calls:** Available from buyer profile (existing platform flows).

---

## 5. ORDERS SEARCH

**Entry:** Search icon in app bar of Orders Inbox.

### User Journey
1. Search by PO number, buyer name, item description.
2. Live-filters the current list client-side.

### Reports
- Search history is not stored (privacy by default).

---

## Notification Channel Summary

| Trigger | Channel | Frequency | Recipient |
|---|---|---|---|
| New order submitted | Push | On event | Receiver |
| Stale submitted (24h) | Local | Once per order | Receiver |
| Daily digest | Local | Daily evening | Receiver |
| Delivery due reminder | Local | 1 day before | Receiver |
| Accepted/Rejected/Shipped/Delivered | Push | On event | Buyer |

## Cross-Module Integration Map

| Module | Direction | Trigger |
|---|---|---|
| Chat (lib/services/message_service.dart) | Orders → Chat | "Message buyer" action |
| Calls (lib/screens/calls) | Orders → Calls | "Call buyer" action |
| Calendar (lib/calendar/) | Orders → Calendar | Status → accepted (add expected-delivery event) |
| Accounting (lib/accounting/) | Orders → Accounting | Status → delivered (offer revenue entry) |
| Suppliers (lib/suppliers/) | Suppliers → Orders | PO creation is the single upstream writer |
| Shangazi AI | Orders → AI | "Ask Shangazi about this buyer" with order context |

## Gaps (v1 deferred)

- Buyer-side status notifications not yet wired (push payloads to buyer on status change) — backend emits event, frontend listens TBD.
- "Record as revenue" Accounting hook is a prompt only — deep link into accounting income entry TBD.
- Rejection reason not persisted (column not added).
