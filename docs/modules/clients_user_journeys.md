# Clients Module — Complete User Journeys

**Module:** lib/clients/
**Source spec:** docs/modules/clients.md

Every feature must be: **Interactive** (notifications, reminders, prompts), **Connected** (wallet, budget, calendar, shop, Shangazi AI), and **Insightful** (reports, trends, recommendations).

---

## 1. CLIENT LIST

**Entry:** Profile → Business tab → Clients
**Stage/Context:** Any time the business owner needs to view, find, or act on their client base

### User Journey
1. User taps the Clients tab inside their Business profile
2. Screen loads `ClientsPage` — shows a searchable list of all clients
3. **Loading state:** Centered `CircularProgressIndicator` while fetching from `GET /business/:id/customers`
4. **Empty state:** Person-outline icon, "Hakuna wateja bado" / "No customers yet", sub-text "Use 'New Customer' / 'Mteja Mpya' to add your first customer", "Add First Client" / "Ongeza Mteja" button
5. **Populated state:** Each card shows:
   - Circle avatar with first initial (dark background)
   - Client name (bold, 14sp)
   - Phone number (12sp, grey)
   - If `totalDebt > 0`: Red badge "Owes TZS [amount]"
   - "Sales: TZS [amount]" (11sp, grey)
   - Last activity chip: "Last purchase [X] days ago" or "Inactive [X] days" (grey, right-aligned)
   - Quick-action icons: 📞 (call), 💬 (WhatsApp) — visible on card, no tap required
6. **Summary bar above list:**
   - "Total clients: [N] · With debt: [N] · Total owed: TZS [amount]"
7. **Search:** TextField at top — "Search by name, phone..." / "Tafuta jina, simu..." — filters client-side by name, phone, email
8. **Filter pills:** Horizontally scrollable row — "All" · "VIP" · "Wholesale" · "Retail" · "Inactive" · custom tags — tap to filter
9. **Refresh:** Pull to refresh calls API again
10. **Error state:** Error icon, error message, "Retry" / "Jaribu tena" button

### CRUD Operations
- **Create:** "New Customer" / "Mteja Mpya" pill button (top-right) → opens add/edit bottom sheet
- **Read:** List cards + search + tag filter; tap card → Client Profile Page
- **Edit:** Tap client card → Profile Page → tap edit icon → pre-filled bottom sheet
- **Delete:** Tap card → Profile Page → delete icon button → confirmation dialog

### Notifications & Reminders
- 📊 **Monthly summary** (1st of each month, 8:00am): "📋 Biashara yako ina wateja [N]. Madeni yanayosubiri: TZS [amount]. Angalia ripoti yako ya mwezi." / "Your business has [N] clients. Outstanding debt: TZS [amount]. View your monthly report."
- ⚠️ **High debt alert** (when total debt exceeds TZS 500,000): "⚠️ Madeni ya wateja yako yamefika TZS [amount]. Wateja [N] wana deni lililokwisha muda." / "Client debt has reached TZS [amount]. [N] clients have overdue payments."
- 💡 **Inactive client prompt** (every 2 weeks if any client inactive >30 days): "💡 Wateja [N] hawajanunua kwa zaidi ya siku 30. Wasiliana nao leo!" / "[N] clients haven't purchased in 30+ days. Reach out today!"

### Reports & Insights
- **Client base summary:** Total clients, growth vs last month, active vs inactive ratio
- **Debt concentration:** Top 5 clients by outstanding debt, % of total debt they represent
- **Revenue leaders:** Top 5 clients by total purchases (this month vs last month)
- **Churn risk list:** Clients with no activity in 30, 60, 90 days — surfaced as a "Need attention" section

### Cross-Module Connections
- **Budget:** Total client revenue feeds into `IncomeService` monthly summary
- **Wallet:** Debt repayments received via M-Pesa automatically reconcile against client debt records
- **Shangazi AI:** "Ask Shangazi how to grow my client base" — passes total client count, active ratio, and top revenue segment as context

---

## 2. CLIENT PROFILE PAGE

**Entry:** Clients list → tap any client card
**Stage/Context:** Before a call, before a delivery, before reconciling accounts, any time the owner needs full context on one client

### User Journey
1. User taps a client card in the list
2. Navigates to `ClientProfilePage` (route: `/clients/:id`)
3. **Header section:**
   - Large circle avatar (80px radius) — initials or photo if uploaded
   - Client name (22sp, bold)
   - Phone number with 📞 tap-to-call
   - Email with ✉️ tap-to-compose
   - Tag chips (VIP, Wholesale, etc.) in a wrap row
4. **Financial summary strip (3 cards):**
   - "Total Purchases / Ununuzi Wote" — TZS [amount]
   - "Outstanding Debt / Deni" — TZS [amount] (red if >0, green if 0)
   - "Last Purchase / Ununuzi wa Mwisho" — "3 days ago" / "Siku 3 zilizopita"
5. **Action bar (persistent bottom):**
   - 📞 "Call" / "Piga Simu"
   - 💬 "WhatsApp"
   - ✉️ "Email" (if email exists)
   - 📋 "Statement" / "Taarifa"
6. **Tab bar:**
   - "Activity" / "Shughuli"
   - "Invoices" / "Ankara"
   - "Debts" / "Madeni"
   - "Appointments" / "Miadi"
   - "Notes" / "Maelezo"
7. Each tab loads its content section (lazy loaded)
8. **Edit button** (pencil icon, top-right) → opens pre-filled edit bottom sheet
9. **Back button** → returns to clients list, position preserved

### CRUD Operations
- **Create:** Not applicable (created from list)
- **Read:** Full profile, all tabs, financial summary
- **Edit:** Top-right pencil → bottom sheet with all client fields pre-filled; save → `PUT /business/customers/:id`
- **Delete:** Three-dot menu → "Delete Client" / "Futa Mteja" → confirmation dialog: "Are you sure you want to delete [name]? All their records will be removed." → `DELETE /business/customers/:id` → navigate back to list

### Notifications & Reminders
- 🔔 **Before call reminder** (user sets): "🔔 Kumbukumbu: Piga simu [name] leo saa [time]." / "Reminder: Call [name] today at [time]."
- ⚠️ **Overdue debt alert** (triggered when debt due date passes): "⚠️ [name] ana deni la TZS [amount] lililokwisha tarehe [date]. Wasiliana nao sasa." / "[name] has an overdue debt of TZS [amount] due [date]. Contact them now."
- 💡 **Reorder prompt** (30 days after last purchase): "💡 [name] alinunua mara ya mwisho siku 30 zilizopita. Je, wanahitaji tena?" / "[name] last purchased 30 days ago. Do they need to reorder?"

### Reports & Insights
- **Client lifetime value:** Total purchases since first transaction
- **Purchase frequency:** Average days between purchases
- **Debt history:** Paid on time vs late payment ratio
- **Best month:** Month with highest spend from this client

### Cross-Module Connections
- **Calendar:** "Schedule follow-up" → `CalendarService.createEvent()` with client name and note pre-filled
- **Wallet:** "Record payment" from profile → WalletService logs incoming payment, debt record updated
- **Budget:** Client's total purchases feed into business income summary in Budget module
- **Shangazi AI:** "Ask Shangazi how to handle this client" — passes client debt, last activity, and purchase history as context

---

## 3. ACTIVITY FEED PER CLIENT

**Entry:** Client Profile Page → "Activity" / "Shughuli" tab
**Stage/Context:** Before calling a client, reviewing relationship history, understanding the full picture in one scroll

### User Journey
1. User taps "Activity" tab inside Client Profile Page
2. Feed loads: reverse-chronological list of all events for this client
3. **Loading state:** Shimmer skeleton of 5 activity rows
4. **Empty state:** Clipboard icon, "Hakuna shughuli bado" / "No activity yet", sub-text "Transactions, notes, and appointments will appear here"
5. **Feed items** — each shows:
   - Left: colored icon circle (type-specific: 🧾 invoice, 💰 payment, 📅 appointment, 📝 note, ⚠️ debt, 🔔 reminder fired)
   - Center: summary line (bold) + detail line (grey)
   - Right: date chip ("Today", "Yesterday", "14 Apr")
   - Amount badge (right-aligned, green for income, red for debt)
6. **Event types and display:**
   - Invoice issued: "Invoice #INV-042 sent · TZS 85,000" → tap → opens invoice detail
   - Payment received: "Payment received · TZS 30,000" → tap → payment record
   - Debt recorded: "Debt added · TZS 20,000 · Due 15 May" → tap → debt record
   - Appointment: "Appointment booked · Haircut · 14 Apr 10:00am" → tap → appointment detail
   - Note added: "[First 60 chars of note]..." → tap → full note
   - Reminder fired: "Reminder sent: follow up on quote" (greyed out, info only)
7. **Date section headers:** "Today", "This Week", "March 2026", "February 2026"
8. **Load more:** "Load older activity" / "Pakia zaidi" button at bottom (pagination)

### CRUD Operations
- **Create:** NOT AVAILABLE directly from activity tab — items created through their native features (invoices, notes, appointments)
- **Read:** Scrollable chronological feed; tap any item to navigate to its full detail
- **Edit:** NOT AVAILABLE from activity tab — edit from the item's native screen
- **Delete:** NOT AVAILABLE from activity tab — delete from native screen

### Notifications & Reminders
- 📊 **Weekly digest** (every Monday 8:00am): "📊 Wiki iliyopita na [name]: Ankara [N], Malipo TZS [amount], Miadi [N]. Angalia ripoti kamili." / "Last week with [name]: [N] invoices, TZS [amount] paid, [N] appointments. View full report."
- ⚠️ **Silence alert** (no activity for 45 days): "⚠️ Hakuna shughuli na [name] kwa siku 45. Angalia historia yao." / "No activity with [name] for 45 days. Review their history."

### Reports & Insights
- **Activity density chart:** Bar chart — transactions per month for the last 6 months
- **Transaction value trend:** Line chart — average transaction value per month
- **Seasonal pattern:** "This client buys most in December and June — consider reaching out in November"
- **Response to contact:** "After calls logged, [name] usually purchases within 3 days"

### Cross-Module Connections
- **Calendar:** Appointment items in the feed link directly to Calendar event
- **Shangazi AI:** "Ask Shangazi about this client's buying pattern" — passes last 10 activity items as context

---

## 4. REMINDERS & FOLLOW-UPS

**Entry:** Client Profile Page → three-dot menu → "Add Reminder" / "Ongeza Kumbukumbu" OR automatic triggers
**Stage/Context:** After a meeting, after a quote is sent, when debt is due

### User Journey

**Manual reminder:**
1. User opens Client Profile Page for a specific client
2. Taps three-dot menu → "Add Reminder" / "Ongeza Kumbukumbu"
3. Bottom sheet opens:
   - **TextField:** "Reminder note" / "Andika kumbukumbu" (required, max 120 chars)
   - **Date picker:** "Remind me on" / "Nikumbushe tarehe" (defaults to tomorrow)
   - **Time picker:** "At time" / "Saa" (defaults to 9:00am)
   - **Type chips:** Call / Delivery / Payment / Quote / General
4. User taps "Set Reminder" / "Weka Kumbukumbu" → reminder saved locally (Hive) + scheduled as local notification
5. Snackbar: "Kumbukumbu imewekwa kwa [date]" / "Reminder set for [date]"
6. Reminder appears in client activity feed with 🔔 icon and a "due in X days" badge

**Viewing reminders:**
1. Clients home screen shows "Today" / "Leo" section at top when any reminder is due today
2. Each reminder card: client name, reminder text, time, "Done" / "Imekwisha" and "Snooze" / "Ahirisha" buttons
3. "Done" → marks complete, removes from today list, logs to activity feed as completed
4. "Snooze" → reschedules +1 day

**Automatic reminder — inactive client:**
- Triggered by backend when client has no purchase for 30 days
- Notification fires with suggested action: "Contact [name]"

**Automatic reminder — overdue debt:**
- Triggered day after debt due date
- Notification with "Call now" deep-link into client profile

### CRUD Operations
- **Create:** Three-dot menu on client profile → "Add Reminder" bottom sheet → "Set Reminder"
- **Read:** Today section on Clients home, activity feed on client profile, dedicated "Reminders" list (filter in activity feed by type = reminder)
- **Edit:** Tap reminder in activity feed → "Edit Reminder" → re-opens bottom sheet with fields pre-filled
- **Delete:** Swipe left on reminder in today list → "Delete" → confirmation → removed

### Notifications & Reminders
- 🔔 **Manual reminder fires** (at set time): "🔔 [Reminder text] — [Client name]" → tapping opens Client Profile Page
- 🔔 **1-hour warning** (60 min before reminder time): "⏰ Kumbukumbu yako na [name] ni baada ya saa moja." / "Your reminder with [name] is in 1 hour."
- ⚠️ **Inactive client auto-reminder** (30 days no purchase): "💡 [name] hajanunua kwa siku 30. Ni wakati wa kuwasiliana nao!" / "[name] hasn't purchased in 30 days. Time to reach out!"
- ⚠️ **Overdue debt auto-reminder** (1 day after due date): "⚠️ Deni la [name] la TZS [amount] limekwisha tarehe [date]. Piga simu sasa." / "[name]'s debt of TZS [amount] was due [date]. Call now."
- 📊 **Weekly reminders summary** (every Friday 5:00pm): "📋 Wiki hii: Kumbukumbu [N] zimekamilika, [N] zinasubiri. Angalia orodha yako." / "This week: [N] reminders completed, [N] pending. Review your list."

### Reports & Insights
- **Follow-up conversion rate:** Of reminders marked "Done", what % led to a purchase within 7 days
- **Response time insight:** "After you contact clients, average purchase happens in [X] days"
- **Reminder backlog:** Count of overdue/snoozed reminders — shown as badge on Clients tab

### Cross-Module Connections
- **Calendar:** Each reminder synced as a `CalendarService.createEvent()` with client name and note — appears in main TAJIRI calendar
- **Shangazi AI:** "Ask Shangazi what to say to [name] about this reminder" — passes reminder context and client history

---

## 5. QUICK COMMUNICATION

**Entry:** Clients list → client card action icons OR Client Profile Page → persistent action bar
**Stage/Context:** Any time the owner needs to reach a client without navigating into a full profile

### User Journey

**From list card:**
1. User sees client card in the list
2. On the right side of every card: 📞 and 💬 icon buttons (always visible, no tap to reveal)
3. Tapping 📞 → immediately opens device dialer with client's number pre-filled via `tel:` URL
4. Tapping 💬 → immediately opens WhatsApp to client's number via `https://wa.me/[phone]`
5. If no phone number: icons are hidden (not shown in greyed-out state)

**From profile action bar:**
1. User opens Client Profile Page
2. Persistent bottom action bar shows: 📞 "Call" / "Piga Simu" · 💬 "WhatsApp" · ✉️ "Email" · 📋 "Statement"
3. Tapping any button launches the appropriate system action
4. **Email button:** Opens device mail client with `mailto:[email]`, pre-fills subject: "TAJIRI Business — [Business Name]"
5. **SMS (long-press on 📞):** Opens SMS compose to client's number

**Communication log (automatic):**
- When user taps 📞 or 💬, a "Contact logged" note is automatically added to the client's activity feed: "📞 Called via app · [time]" or "💬 WhatsApp opened · [time]"
- This gives a passive activity record without requiring manual note entry

### CRUD Operations
- **Create:** Contact log auto-created on each communication tap
- **Read:** Communication history visible in Activity Feed (filter by type = contact)
- **Edit:** NOT AVAILABLE — contact logs are append-only
- **Delete:** NOT AVAILABLE — contact logs are append-only (preserve audit trail)

### Notifications & Reminders
- 💡 **No-contact prompt** (if client has debt and no contact logged in 7 days): "💡 Hujampigia [name] simu kwa siku 7 na ana deni. Wasiliana leo." / "You haven't contacted [name] in 7 days and they have outstanding debt. Reach out today."
- 📊 **Weekly communication summary** (Fridays): "📞 Wiki hii ulipiga simu wateja [N], WhatsApp [N]. Umefikia [%] ya wateja wako." / "This week you called [N] clients, WhatsApp [N]. You reached [%] of your clients."

### Reports & Insights
- **Most contacted clients:** Ranked by call/WhatsApp frequency
- **Never contacted list:** Clients who have never had a communication log entry — prompt to reach out
- **Contact-to-purchase correlation:** "Clients you contact by WhatsApp are [X]% more likely to reorder within 3 days"

### Cross-Module Connections
- **Shangazi AI:** "Draft a WhatsApp message to [name] about their overdue debt" — Shangazi generates a polite Swahili/English message the owner can copy-paste
- **Budget:** Communication costs (airtime) trackable via `ExpenditureService` if user manually logs

---

## 6. TAGS & CATEGORIES

**Entry:** Client Profile Page → tag chips → "Edit Tags" OR Add/Edit client form → Tags field
**Stage/Context:** Onboarding new clients, segmenting for promotions, filtering before a bulk action

### User Journey

**Assigning tags:**
1. User opens Client Profile Page
2. Below the client name: tag chips (e.g. "VIP", "Wholesale") with a "+" chip at the end
3. User taps "+" → "Manage Tags" / "Simamia Lebo" bottom sheet opens
4. Sheet shows:
   - **Preset tags:** VIP · Wholesale · Retail · New · Inactive · Credit Risk (toggle chips)
   - **Custom tags section:** existing custom tags with toggle chips
   - **"Add new tag" / "Ongeza lebo"** text field + "Add" button
5. User toggles desired tags → taps "Save" / "Hifadhi" → `PUT /business/customers/:id` with updated `tags` array
6. Chips update instantly on profile page

**Filtering by tag:**
1. On Clients list, horizontal pill row: "All" / "Wote" · "VIP" · "Wholesale" · "Retail" · "Inactive" + any custom tags
2. User taps a pill → list filters instantly (client-side, no API call)
3. Multi-select: tapping multiple pills shows clients matching ANY selected tag (OR logic)
4. Active filter count badge: "Filtered: 12 clients" / "Waliochaguliwa: 12"
5. "Clear filter" / "Ondoa chujio" appears when any filter is active

**Creating a custom tag:**
1. In the Manage Tags sheet → "Add new tag" field → type name → "Add" button
2. Tag is added to the custom tags library (stored in Hive locally, synced to backend)
3. Immediately available for toggle

### CRUD Operations
- **Create:** "Add new tag" field in Manage Tags sheet → creates tag and applies it
- **Read:** Tag chips on client profile; filter pills on list; grouped client lists by tag
- **Edit:** Tags are toggled on/off per client — no separate edit screen needed
- **Delete:** In Manage Tags sheet, long-press a custom tag → "Delete tag from all clients?" confirmation → removes from all clients + tag library

### Notifications & Reminders
- 💡 **Segmentation prompt** (if >20 clients with no tags): "💡 Wateja wako [N] hawana lebo. Panga wachache kama VIP au Wholesale ili uweze kuwafikia haraka." / "Your [N] clients have no tags. Label some as VIP or Wholesale to reach them faster."
- 📊 **Segment report** (monthly): "📊 Wateja VIP [N] walileta TZS [amount] mwezi huu — [%] ya mapato yako yote." / "Your [N] VIP clients brought TZS [amount] this month — [%] of all your revenue."

### Reports & Insights
- **Revenue by segment:** Bar chart — total purchases per tag (VIP vs Wholesale vs Retail)
- **Debt by segment:** Which client category carries the most overdue debt
- **Growth by segment:** New clients per tag per month
- **Inactive segment:** All clients tagged "Inactive" with days-since-last-purchase sorted descending

### Cross-Module Connections
- **Budget:** VIP client revenue tracked separately as income subcategory
- **Shangazi AI:** "How should I approach my wholesale clients differently from retail?" — Shangazi uses segment data to tailor advice

---

## 7. BIRTHDAY & ANNIVERSARY REMINDERS

**Entry:** Add/Edit client form → "Date of Birth" / "Tarehe ya Kuzaliwa" field
**Stage/Context:** During client onboarding or profile editing; reminders fire automatically each year

### User Journey

**Adding a birthday:**
1. User opens Add Client or Edit Client bottom sheet
2. Optional field: "Date of Birth" / "Tarehe ya Kuzaliwa" — date picker (day and month; year optional)
3. Optional field: "Client since" / "Mteja Tangu" — date the relationship started
4. User fills in date → saves client
5. System registers annual FCM reminder for that date

**On the birthday:**
1. At 8:00am on the client's birthday, push notification fires
2. Notification text: "🎂 Leo ni siku ya kuzaliwa ya [name]! Tuma ujumbe wa pongezi." / "🎂 Today is [name]'s birthday! Send a birthday message."
3. Tapping notification opens Client Profile Page with a birthday banner at top: "🎂 Happy Birthday [name]!"
4. Profile shows WhatsApp button highlighted with label "Send Birthday Message" / "Tuma Pongezi"
5. Tapping "Send Birthday Message" opens WhatsApp with pre-composed text: "Heri ya siku ya kuzaliwa [name]! Asante kwa kuwa mteja wetu." / "Happy Birthday [name]! Thank you for being our valued customer."

**Client anniversary:**
1. On the anniversary of `client_since` date: "🎉 [name] amekuwa mteja wako kwa mwaka [N]! Mshukuru." / "[name] has been your client for [N] year(s)! Thank them."

### CRUD Operations
- **Create:** Date entered in add client form
- **Read:** Birthday/anniversary shown on Client Profile Page header; "Upcoming Birthdays" / "Siku za Kuzaliwa Zinazokuja" section on Clients home screen showing next 7 days
- **Edit:** Edit client form → update date of birth
- **Delete:** Edit client form → clear date of birth field → save

### Notifications & Reminders
- 🎉 **Birthday notification** (8:00am on birthday): "🎂 Leo ni siku ya kuzaliwa ya [name]! Tuma ujumbe wa pongezi." / "Today is [name]'s birthday! Send a birthday message."
- 🔔 **Birthday countdown** (3 days before): "🎂 Siku ya kuzaliwa ya [name] ni baada ya siku 3. Jitayarishe kutuma pongezi." / "[name]'s birthday is in 3 days. Prepare to send wishes."
- 🎉 **Client anniversary** (on anniversary date): "🎉 [name] amekuwa mteja wako kwa mwaka [N]! Mshukuru leo." / "[name] has been your client for [N] year(s)! Thank them today."
- 📊 **Upcoming birthdays digest** (every Sunday evening): "🎂 Wiki hii: Wateja [N] wana siku za kuzaliwa. Angalia orodha." / "This week: [N] clients have birthdays. Check the list."

### Reports & Insights
- **Birthday calendar:** Monthly view on Clients home showing all client birthdays in the month
- **Birthday outreach rate:** % of clients you sent a birthday message — tracked from WhatsApp taps
- **Loyalty correlation:** Do clients who receive birthday messages purchase more in the following month?

### Cross-Module Connections
- **Calendar:** Birthday and anniversary dates synced as annual recurring events via `CalendarService.createEvent()` with client name and "Send birthday message" reminder
- **Shop:** "Send [name] a birthday gift" → Shop search for gift items
- **Shangazi AI:** "Draft a birthday message for [name] in Swahili" — Shangazi generates personalised message using client name and purchase history

---

## 8. CLIENT STATEMENTS

**Entry:** Client Profile Page → bottom action bar → 📋 "Statement" / "Taarifa"
**Stage/Context:** End of month reconciliation, when a client questions their balance, before debt collection

### User Journey
1. User opens Client Profile Page
2. Taps 📋 "Statement" / "Taarifa" in the bottom action bar
3. **Date range picker sheet** opens:
   - Quick options: "This Month" / "Mwezi Huu" · "Last Month" / "Mwezi Uliopita" · "Last 3 Months" / "Miezi 3" · "This Year" / "Mwaka Huu" · "Custom" / "Maalum"
   - "Custom" → from/to date pickers
4. User selects range → taps "Generate" / "Tengeneza"
5. Loading indicator while fetching from `GET /business/clients/:id/statement?from=&to=`
6. **Statement preview screen** (full-screen, scroll):
   - **Header:** Business name + logo, "CLIENT STATEMENT / TAARIFA YA MTEJA"
   - **Client info:** Name, phone, email, address
   - **Period:** "01 March 2026 – 31 March 2026"
   - **Transaction table:**
     | Date | Description | Debit | Credit | Balance |
     |------|------------|-------|--------|---------|
     | 03 Mar | Invoice #INV-041 | 85,000 | — | 85,000 |
     | 08 Mar | Payment received | — | 50,000 | 35,000 |
   - **Summary row:** Total invoiced, total paid, balance outstanding (highlighted red if >0)
   - **Footer:** "Powered by TAJIRI" + business phone + generated date
7. **Action buttons at bottom:**
   - "Share PDF" / "Shiriki PDF" → generates PDF → system share sheet (WhatsApp, email, etc.)
   - "Share via WhatsApp" / "Tuma WhatsApp" → PDF sent directly to client's WhatsApp
   - "Print" / "Chapisha" → `Printing.layoutPdf()`
8. If no transactions in period: "Hakuna shughuli katika kipindi hiki." / "No transactions in this period."

### CRUD Operations
- **Create:** NOT AVAILABLE — statements are generated on demand, not saved
- **Read:** Generated on demand from API; preview on screen
- **Edit:** NOT AVAILABLE — re-generate with different date range
- **Delete:** NOT AVAILABLE — ephemeral; not stored server-side

### Notifications & Reminders
- 🔔 **End-of-month prompt** (last day of month, 9:00am, only if client has debt): "📋 Mwisho wa mwezi: Tengeneza taarifa ya [name] — wana deni la TZS [amount]." / "End of month: Generate [name]'s statement — they owe TZS [amount]."
- 💡 **Debt dispute prompt** (when debt > TZS 100,000 and older than 30 days): "💡 [name] ana deni la zamani la TZS [amount]. Tuma taarifa yao ili kukubaliana." / "[name] has an old debt of TZS [amount]. Send their statement to reconcile."

### Reports & Insights
- **Statements sent log:** History of when statements were generated and shared for each client
- **Payment after statement:** Did client pay within 7 days of receiving a statement? Track conversion
- **Outstanding balance trend:** Client's balance at end of each month — chart showing whether they're paying down or accumulating debt

### Cross-Module Connections
- **Wallet:** "Request payment via M-Pesa" button on statement → WalletService initiates payment request to client's phone number
- **Budget:** Statement totals feed into business income and receivables in Budget module
- **Shangazi AI:** "Ask Shangazi how to approach [name] about this outstanding balance" — passes statement summary as context

---

## 9. IMPORT FROM PHONE CONTACTS

**Entry:** Clients list → "Import Contacts" / "Ingiza Anwani" button (secondary action, below "New Customer" pill)
**Stage/Context:** First-time setup, or adding a batch of new clients at once

### User Journey
1. User taps "Import Contacts" / "Ingiza Anwani"
2. **Permission request:** System dialog — "TAJIRI would like to access your contacts to help you import clients." → "Allow" / "Deny"
3. If denied: Snackbar: "Ruhusa ya anwani inahitajika. Nenda Mipangilio → TAJIRI → Anwani." / "Contacts permission required. Go to Settings → TAJIRI → Contacts." with "Open Settings" button
4. If allowed: Contacts list loads — searchable, full name + phone number per row
5. **Deduplication:** Any contact whose phone number already exists as a client shows a grey "Already added" / "Ameshaongezwa" badge and cannot be selected
6. User searches / scrolls → taps contacts to select (checkbox appears, contact row highlights)
7. **Selection count badge** at top: "Selected: [N]" / "Waliochaguliwa: [N]"
8. User taps "Import [N] Contacts" / "Ingiza [N]" — floating action button at bottom
9. **Confirmation sheet:**
   - Preview: "[Name 1] — 0712 345 678", "[Name 2] — 0754 123 456"...
   - "These will be added as clients to [Business Name]"
   - "Confirm Import" / "Thibitisha" · "Cancel" / "Ghairi"
10. Progress indicator: "Importing 1 of [N]..." → calls `POST /business/customers` for each
11. **Success state:** "Wateja [N] wameongezwa!" / "[N] clients added!" + confetti animation
12. Returns to Clients list, newly imported clients visible

### CRUD Operations
- **Create:** Batch `addCustomer` API calls — one per selected contact
- **Read:** Contact list from device — searchable
- **Edit:** NOT AVAILABLE during import — edit individual clients after import via normal edit flow
- **Delete:** NOT AVAILABLE — imported clients deleted via normal delete flow

### Notifications & Reminders
- 💡 **First-time prompt** (if user has 0 clients and has phone contacts): "💡 Una anwani [N] kwenye simu yako. Ingiza wateja haraka zaidi!" / "You have [N] contacts on your phone. Import clients faster!"
- 🎉 **Import success** (in-app): "🎉 Wateja [N] wameongezwa kutoka kwa anwani zako!" / "[N] clients imported from your contacts!"

### Reports & Insights
- **Import history:** Date and count of each import batch — shown in settings or profile
- **Post-import activity:** Of imported clients, how many had a transaction within 30 days of import?

### Cross-Module Connections
- **Shangazi AI:** "How should I introduce my business to newly imported contacts?" — Shangazi drafts a WhatsApp broadcast message template
- **Community:** "Invite imported contacts to follow your business on TAJIRI" — one-tap broadcast invite via WhatsApp

---

## 10. TIMESTAMPED NOTES LOG

**Entry:** Client Profile Page → "Notes" / "Maelezo" tab → "Add Note" / "Ongeza Maelezo" FAB
**Stage/Context:** After a phone call, after a meeting, when client makes a special request, after a dispute

### User Journey

**Adding a note:**
1. User opens Client Profile Page → taps "Notes" / "Maelezo" tab
2. Floating "+" FAB at bottom-right → "Add Note" / "Ongeza Maelezo"
3. **Quick-entry bottom sheet:**
   - **Type chips** (required): 📞 Call · 📦 Order · 📝 General · ⚠️ Alert
   - **TextField:** "What happened?" / "Nini kilitokea?" (required, max 300 chars) — multiline
   - **Optional follow-up toggle:** "Set reminder based on this note" / "Weka kumbukumbu" — if toggled, shows date picker
   - "Save Note" / "Hifadhi" button
4. Taps "Save Note" → `POST /business/clients/:id/notes` → sheet closes → note appears at top of list
5. Snackbar: "Maelezo yamehifadhiwa" / "Note saved"

**Viewing notes:**
1. "Notes" tab shows reverse-chronological list
2. Each note card:
   - Type icon + label (📞 Call, 📦 Order, etc.)
   - Note body (max 3 lines, "Read more" if longer)
   - Timestamp: "Today 2:30pm" / "Yesterday" / "14 Mar 2026"
   - If reminder attached: "🔔 Reminder set for [date]" chip
3. **Empty state:** Pencil icon, "Hakuna maelezo bado" / "No notes yet", "Your timestamped notes will appear here"

**Call notes — automatic prompt:**
- When user taps 📞 "Call" from the profile action bar, a prompt appears 30 seconds after the call intent launches: "📝 Habari ya simu? Ongeza maelezo mfupi." / "How was the call? Add a quick note." — one-tap to open note sheet pre-set to type = Call

### CRUD Operations
- **Create:** FAB on Notes tab → quick-entry bottom sheet → "Save Note" → `POST /business/clients/:id/notes`
- **Read:** Notes tab — reverse-chronological list; notes also surface in Activity Feed as type = note
- **Edit:** Long-press note card → "Edit Note" / "Hariri" → re-opens bottom sheet with content pre-filled → "Update" / "Sasisha" → `PUT /business/clients/notes/:id`
- **Delete:** Long-press note card → "Delete Note" / "Futa" → confirmation dialog: "Futa maelezo haya?" / "Delete this note?" → `DELETE /business/clients/notes/:id` → removed from list

### Notifications & Reminders
- 💡 **Post-call note prompt** (30s after call tap): "📝 Maelezo ya simu na [name]? Andika haraka." / "Call note for [name]? Write it quickly."
- 🔔 **Reminder from note fires** (at set time): "🔔 Maelezo yako: '[Note text truncated to 40 chars]' — [name]" → opens Client Profile Notes tab
- 💡 **Note decay prompt** (90 days since last note on an active client): "💡 Haujaacha maelezo kuhusu [name] kwa siku 90. Je, kuna taarifa yoyote mpya?" / "No notes on [name] for 90 days. Any updates to record?"

### Reports & Insights
- **Note frequency per client:** Clients with most notes = most active relationships; clients with zero notes = potentially neglected
- **Note type breakdown:** % of notes that are Calls vs Orders vs Alerts — reveals communication patterns
- **Alert note tracker:** All notes of type ⚠️ Alert across all clients — surfaced as a "Watch list" on the Clients home screen
- **Order notes pipeline:** Notes of type 📦 Order that are older than 7 days without a linked invoice — "Pending order follow-ups"

### Cross-Module Connections
- **Calendar:** If "Set reminder" is toggled on a note, `CalendarService.createEvent()` is called with note text as event description and client name as event title
- **Shangazi AI:** "Ask Shangazi how to respond to this client situation" — passes note content and client profile as context, Shangazi provides scripted response
- **Budget:** Notes of type 📦 Order are flagged as potential pending income — Budget module shows "Unconfirmed orders: TZS [estimated]"

---

## Notification Channel Summary

| Trigger | Text (EN) | Timing | Channel | Frequency |
|---------|-----------|--------|---------|-----------|
| Monthly summary | "Your business has [N] clients. Outstanding debt: TZS [X]." | 1st of month 8am | Push | Monthly |
| High debt alert | "Client debt has reached TZS [X]. [N] clients are overdue." | When threshold crossed | Push | As triggered |
| Inactive client | "[N] clients haven't purchased in 30+ days. Reach out today!" | Weekly check | Push | Max 1/week |
| Manual reminder fires | "[Reminder text] — [Client name]" | User-set time | Local notification | As set |
| Overdue debt | "[name]'s debt of TZS [X] was due [date]. Call now." | 1 day after due date | Push | Per debt |
| Birthday (day-of) | "Today is [name]'s birthday! Send a birthday message." | 8am on birthday | Push | Annually |
| Birthday countdown | "[name]'s birthday is in 3 days." | 3 days before | Push | Annually |
| Client anniversary | "[name] has been your client for [N] year(s)! Thank them." | 8am on anniversary | Push | Annually |
| No communication + debt | "You haven't contacted [name] in 7 days and they have debt." | 7 days after last contact | Push | Weekly max |
| End-of-month statement | "Generate [name]'s statement — they owe TZS [X]." | Last day of month 9am | Push | Monthly |
| Post-call note prompt | "Call note for [name]? Write it quickly." | 30s after call tap | Local notification | Per call |
| Upcoming birthdays digest | "This week: [N] clients have birthdays." | Sunday 6pm | Push | Weekly |
| Weekly client digest | "[N] invoices, TZS [X] paid, [N] appointments this week." | Monday 8am | Push | Weekly |

**Max push notifications per day:** 2 (highest priority only). Remaining alerts delivered as in-app cards on Clients home screen.

---

## Cross-Module Integration Map

| From Clients | To Module | Data Flow | Trigger |
|-------------|-----------|-----------|---------|
| Debt repayment received | **Wallet** | Payment amount, client ID → reconcile against debt | User logs payment |
| Invoice issued / paid | **Budget** | Revenue amount → `IncomeService.record()` | Invoice status changes |
| Statement generated | **Wallet** | "Request M-Pesa payment" from statement → WalletService | User taps "Request Payment" |
| Follow-up reminder | **Calendar** | Event title = client name, description = reminder text | User sets reminder |
| Birthday / anniversary | **Calendar** | Annual recurring event per client | Date entered on profile |
| Birthday message | **Shop** | "Send [name] a gift" → Shop search: gift items | User taps birthday action |
| Imported contact | **Community** | "Invite to follow business on TAJIRI" broadcast | After import success |
| Order note (unfulfilled) | **Budget** | Pending income flag, estimated amount | Note type = Order, no linked invoice |
| Client context (any screen) | **Shangazi AI** | Name, debt, last activity, tags, notes → AI context | "Ask Shangazi" tapped |
| Any client interaction | **Tajirika** | Business activity signal for partner program score | Ongoing |
