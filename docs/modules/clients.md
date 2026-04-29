# Clients Module

**Location:** `lib/clients/`
**Entry point:** `lib/clients/pages/clients_page.dart` → `ClientsPage`
**Dependencies:** `lib/business/models/business_models.dart` (Customer model), `lib/business/services/business_service.dart`

---

## Overview

The Clients module is the central CRM (Client Relationship Management) layer for small business owners on TAJIRI. It gives a business owner a complete, always-accessible view of every client — who they are, what they owe, when they last bought, and what needs to happen next. For a business with up to 100 clients, this module should replace the need for a notebook, a spreadsheet, or a separate contacts app.

---

## Current State

The existing `ClientsPage` provides:
- A flat list of clients with name, phone, debt, and total sales
- Search (client-side, by name/phone/email)
- Add / edit / delete via bottom sheet
- Tap to view a detail bottom sheet with call and WhatsApp shortcuts
- Pull to refresh

This is a working foundation but lacks depth. The features below describe what needs to be built to make this module genuinely useful.

---

## Feature Specifications

---

### 1. Client Profile Page

**What it is:**
A full-screen dedicated page for a single client, accessible by tapping their card in the list. Replaces the current bottom sheet detail view, which is too shallow for real use.

**What it shows:**
- **Header:** Avatar (initials or photo), name, phone, email, tags/labels
- **Financial summary strip:** Total purchases, outstanding debt, last transaction date — in large readable numbers
- **Tabs or sections:**
  - *Activity* — chronological feed of all interactions (purchases, invoices, payments, appointments, notes)
  - *Invoices* — list of invoices linked to this client
  - *Debts* — outstanding and settled debts
  - *Appointments* — upcoming and past appointments
  - *Notes* — timestamped notes log

**Why it matters:**
Before calling a client, a business owner needs to know at a glance: what did they buy last, do they owe anything, when did we last speak? A bottom sheet cannot hold this context. A dedicated page can.

**Implementation notes:**
- Route: `/clients/:id`
- Data is assembled by fetching from multiple endpoints: customer detail, invoices filtered by `customer_id`, debts filtered by `customer_id`, appointments filtered by `customer_id`
- The profile page is the hub — all other features (notes, reminders, statements) are accessible from here

---

### 2. Activity Feed Per Client

**What it is:**
A reverse-chronological list of every recorded event for a client, shown inside the Client Profile Page. Each event has a type, date, and summary line.

**Event types:**
| Type | Example display |
|------|----------------|
| Purchase / Invoice | "Invoice #INV-042 — TZS 85,000 · Paid" |
| Payment received | "Payment received — TZS 30,000" |
| Debt recorded | "Debt added — TZS 20,000 · Due 15 May" |
| Appointment | "Appointment: Haircut · 14 Apr 10:00am" |
| Note | "Called — she wants to reorder next week" |
| Reminder fired | "Reminder sent: follow up on quote" |

**Why it matters:**
The most common question a business owner asks before calling a client is "what's the last thing that happened with them?" This feed answers that in under a second. It removes the need to check invoices, debts, and appointments separately.

**Implementation notes:**
- Assembled client-side by merging sorted results from invoices, debts, appointments, and notes APIs
- Each item renders a small icon, a summary line, a date string ("3 days ago" / "14 Apr"), and an amount if applicable
- Tapping an activity item navigates to the relevant detail (invoice, appointment, etc.)

---

### 3. Reminders & Follow-ups

**What it is:**
A lightweight task/reminder system attached to individual clients. A business owner can set a one-off reminder ("Call Amina on Friday about the quote") or rely on automatic reminders triggered by business rules.

**Manual reminders:**
- Set from the Client Profile Page: pick a date/time and write a short note
- Reminders appear in a "Today" list on the Clients home screen
- Push notification fires at the set time

**Automatic reminders:**
- *Inactive client alert:* If a client has not made a purchase in X days (configurable, default 30), the business owner is notified
- *Overdue debt alert:* If a debt's due date has passed without payment, a reminder fires
- *Quote follow-up:* If a quote was sent and not responded to in 7 days, remind the owner to follow up

**Why it matters:**
Small business owners lose revenue not from bad products but from forgotten follow-ups. A client who was interested last month and never got a call back is a lost sale. Automatic reminders make the app proactive rather than passive.

**Implementation notes:**
- Store reminders locally (Hive) with a background isolate or FCM-scheduled push to fire them
- Backend endpoint to store reminders: `POST /business/clients/:id/reminders`
- Automatic rules are evaluated server-side and delivered via FCM

---

### 4. Quick Communication

**What it is:**
One-tap communication buttons visible directly on the client list card, not buried inside a detail sheet. The goal: open WhatsApp or dial in two taps from the list.

**Current state:** Call and WhatsApp buttons exist only after tapping a card and opening the bottom sheet (3–4 taps away).

**Proposed:**
- Each client card in the list shows small icon buttons on the right: 📞 call, 💬 WhatsApp
- These are visible without opening any sheet
- A third icon for SMS or email if available
- On the Client Profile Page, a persistent action bar at the bottom with Call, WhatsApp, and Message

**Why it matters:**
The primary action for managing a client relationship is communication. Making it require 4 taps instead of 2 is friction that discourages use. For a business owner checking clients while walking between customers, speed is everything.

**Implementation notes:**
- Use `url_launcher` (already a dependency): `tel:`, `https://wa.me/`, `sms:`, `mailto:`
- Strip `+` from phone number for WhatsApp URL
- Show buttons only if the relevant contact info exists (don't show email button if no email stored)

---

### 5. Tags & Categories

**What it is:**
A freeform and/or preset labelling system for clients. Each client can have one or more tags. The list can be filtered by tag.

**Preset tags (suggested defaults):**
- VIP
- Wholesale
- Retail
- New
- Inactive
- Credit risk

**Custom tags:** Business owner can create their own (e.g. "Kariakoo", "Online", "School supplier").

**Filter UI:**
- A horizontally scrollable pill row at the top of the Clients list: `All · VIP · Wholesale · Retail · Inactive`
- Selecting a pill filters the list instantly (client-side)
- Multiple tags can be selected simultaneously

**Why it matters:**
Not all clients are equal. A wholesale buyer who orders TZS 500,000 per month needs different attention than a walk-in retail customer. Tags let the owner instantly surface the clients that matter most in a given moment — before a sales call, before end-of-month reconciliation, before a promotion push.

**Implementation notes:**
- Store tags as a `List<String>` on the `Customer` model
- Backend: `tags` field on the customers table, stored as JSON array
- Filter is applied client-side after fetch; no extra API calls needed for filtering

---

### 6. Birthday & Anniversary Reminders

**What it is:**
Optional date fields on the client profile — date of birth and/or business anniversary. The app sends a push notification on the day with a suggested action ("Wish Fatuma a happy birthday — she's a VIP client").

**Fields added to client form:**
- Date of birth (optional)
- Business anniversary / client-since date (optional)

**Notification behaviour:**
- Fires at 8:00am on the day
- Notification text: "🎂 Today is [Name]'s birthday. Send them a message!"
- Tapping the notification opens the client's WhatsApp directly

**Why it matters:**
For a small business serving a local community, personal relationships are the product. Remembering a client's birthday costs nothing and builds loyalty that no discount can buy. This feature requires zero ongoing effort from the owner after the date is entered once.

**Implementation notes:**
- Store `date_of_birth` and `anniversary_date` on the Customer model
- Server evaluates upcoming dates daily and sends FCM push
- Alternatively, schedule local notifications using `flutter_local_notifications` without server involvement

---

### 7. Client Statements

**What it is:**
A one-tap generated summary of all financial activity for a client over a selected period — invoices issued, payments received, outstanding balance. The statement can be shared as a PDF via WhatsApp, email, or any share target.

**Statement contents:**
- Business name and logo at the top
- Client name and contact info
- Period: "01 March 2026 – 31 March 2026"
- Table of transactions: date, description, amount, payment status
- Running balance column
- Total owed at the bottom
- Powered by TAJIRI footer

**Trigger:**
- Button on Client Profile Page: "Generate Statement"
- Date range picker (this month / last month / custom)
- Generates PDF → opens share sheet

**Why it matters:**
When a client disputes a balance or asks "how much do I owe?", the owner currently has no clean answer. A statement closes that loop professionally. It also signals to the client that the business is organised and serious.

**Implementation notes:**
- Use `pdf` and `printing` packages (or `flutter_pdfview`) for generation and sharing
- Data comes from existing invoices and debts APIs, filtered by `customer_id` and date range
- Backend endpoint: `GET /business/clients/:id/statement?from=&to=` returns pre-aggregated data

---

### 8. Import from Phone Contacts

**What it is:**
A flow that reads the device's contacts and lets the business owner pick one or more to import as clients. The client form is pre-filled with name and phone; the owner adds any business-specific fields before saving.

**Flow:**
1. Tap "Import from Contacts" on the Clients list
2. App requests contacts permission
3. Shows a searchable list of device contacts
4. Owner selects contacts (multi-select supported)
5. Each selected contact is previewed as a pre-filled client form
6. Owner confirms → contacts saved as clients via the existing `addCustomer` API

**Why it matters:**
A business owner setting up the app already has their clients saved as phone contacts. Making them re-type 100 names is a fatal onboarding friction. Import turns a 30-minute setup into a 2-minute one.

**Implementation notes:**
- Use `flutter_contacts` package (handles Android + iOS permissions cleanly)
- Deduplicate: before importing, check if a contact's phone number already exists as a client and skip or warn
- Batch import: send multiple `addCustomer` calls, show a progress indicator

---

### 9. Balance at a Glance

**What it is:**
Enhanced client list cards that surface the most important financial signals without requiring any tap.

**Current card shows:** Name, phone, debt amount, total sales.

**Enhanced card shows:**
- Name (bold)
- Phone number
- **If debt > 0:** Red badge — "Owes TZS 45,000"
- **Last activity:** "Last purchase 3 days ago" or "No activity in 45 days" (greyed out)
- **Payment status dot:** Green (no debt), amber (debt but not overdue), red (overdue debt)

**List-level summary bar (above the list):**
- Total clients: 87
- Clients with debt: 12
- Total debt outstanding: TZS 340,000

**Why it matters:**
The clients list is the first screen an owner sees. It should answer "who needs my attention today?" without any navigation. A client who owes money and hasn't been seen in 30 days is a priority — the card should signal that immediately.

**Implementation notes:**
- `last_activity_at` field needed from backend (or derived client-side from invoice/appointment data)
- Summary bar computed client-side from the fetched list
- Color-coded debt badge: green if `totalDebt == 0`, amber if `totalDebt > 0` and not overdue, red if any debt is past due date

---

### 10. Notes with Dates (Timestamped Notes Log)

**What it is:**
Replace the single `notes` text field on a client with a chronological log of timestamped notes — one note per entry, each with a date, time, and optionally a type/category.

**Note types:**
- 💬 Call — "Called, she'll pay end of week"
- 📦 Order — "Wants 5 kanga prints in blue, following up Monday"
- 📝 General — "Prefers delivery on Tuesdays"
- ⚠️ Alert — "Bounced cheque in Jan — cash only going forward"

**UI:**
- Notes appear in the Activity Feed on the Client Profile Page
- A floating "Add Note" button on the profile page opens a quick-entry sheet: select type, type text, save
- Notes are displayed as a timeline with relative dates ("Yesterday", "3 days ago", "14 Mar")

**Why it matters:**
A single notes field gets overwritten. A business owner who wrote "prefers delivery on Tuesdays" six months ago has no way to know when that was written or whether it's still true. A log of notes with dates gives full context — it's the difference between a CRM and a sticky note.

**Implementation notes:**
- New model: `ClientNote { id, clientId, businessId, type, body, createdAt }`
- Backend endpoints: `GET /business/clients/:id/notes`, `POST /business/clients/:id/notes`, `DELETE /business/clients/notes/:id`
- Store locally in Hive for offline access; sync on reconnect

---

## Data Model Changes Required

| Field | Where | Purpose |
|-------|-------|---------|
| `tags` | Customer | Array of label strings |
| `date_of_birth` | Customer | Birthday reminder |
| `anniversary_date` | Customer | Client-since date |
| `last_activity_at` | Customer | Computed: last invoice/appointment date |
| `ClientNote` | New model | Timestamped notes log |
| `ClientReminder` | New model | Manual follow-up reminders |

---

## Backend Endpoints Required

| Method | Endpoint | Purpose |
|--------|----------|---------|
| GET | `/business/:id/clients/:cid/activity` | Merged activity feed |
| GET | `/business/clients/:id/notes` | Fetch notes log |
| POST | `/business/clients/:id/notes` | Add a note |
| DELETE | `/business/clients/notes/:id` | Delete a note |
| GET | `/business/clients/:id/reminders` | Fetch reminders |
| POST | `/business/clients/:id/reminders` | Set a reminder |
| GET | `/business/clients/:id/statement?from=&to=` | Generate statement data |

---

## Build Priority

| Priority | Feature | Effort |
|----------|---------|--------|
| 🔴 High | Client Profile Page | Medium |
| 🔴 High | Balance at a glance (enhanced cards) | Low |
| 🔴 High | Quick communication on cards | Low |
| 🟡 Medium | Timestamped notes log | Medium |
| 🟡 Medium | Activity feed | Medium |
| 🟡 Medium | Tags & categories | Low–Medium |
| 🟡 Medium | Import from contacts | Medium |
| 🟢 Later | Reminders & follow-ups | High |
| 🟢 Later | Client statements (PDF) | High |
| 🟢 Later | Birthday reminders | Low (after dob field added) |
