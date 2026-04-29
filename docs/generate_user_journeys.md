# Generate User Journey Document

You are generating a **Complete User Journeys** document for a TAJIRI module. TAJIRI is a Tanzanian super-app (Flutter/Dart) where every module must feel alive, connected, and useful — not just a data entry form.

## Input

You will be given a module design document from `docs/modules/[module_name].md`. Read it completely. Then generate a user journey document following the structure below.

## Core Principles

Every feature in the module must be:

1. **Interactive** — The app talks to the user. It sends push notifications, shows reminders, prompts actions, celebrates achievements, and warns about problems. The user should never have to remember to do something — the app reminds them.

2. **Connected** — No feature is an island. Every feature should give and receive data from other TAJIRI modules. When a user logs an expense, Budget knows. When a user books a doctor, Calendar knows. When a user buys medicine, Pharmacy and Shop are involved. The cross-module connections are what make TAJIRI a super-app, not a collection of separate apps.

3. **Insightful** — Raw data is useless. Every feature that collects data must produce reports, trends, summaries, comparisons, and recommendations. The user should learn something new about their situation every time they open the app.

## Available TAJIRI Modules for Cross-Connection

When writing cross-module integrations, connect to these real modules:

| Module | What It Does | Integration Pattern |
|--------|-------------|-------------------|
| **Doctor** (lib/doctor/) | Find doctors, book appointments, consultations | Navigate to DoctorModule for health concerns |
| **Pharmacy** (lib/pharmacy/) | Search medicine, place orders, pharmacist chat | Navigate to PharmacyModule for medication needs |
| **Shop** (lib/screens/shop/) | Browse/buy products by category | Navigate to Shop with contextual search query |
| **Insurance** (lib/insurance/) | Browse policies, manage claims, check coverage | Navigate to InsuranceModule for coverage checks |
| **Budget** (lib/budget/) | Envelope budgeting, expense tracking | Record expenses via ExpenditureService, income via IncomeService |
| **Wallet** (lib/my_wallet/) | M-Pesa top-up, transfers, payments | WalletService for money movement |
| **Calendar** (lib/calendar/) | Events, reminders, schedules | CalendarService.createEvent() for date-based items |
| **Family** (lib/my_family/) | Family members, shared records | MyFamilyService for family data sync |
| **Community** (lib/community/) | Local posts, groups, services | CommunityModule for group features |
| **Shangazi AI** | AI parenting/life assistant in chat | Pass context data for AI-powered advice |
| **Notifications** (lib/services/fcm_service.dart) | Push notifications via FCM + local | FlutterLocalNotificationsPlugin for scheduled alerts |
| **My Circle** (lib/my_circle/) | Period/fertility tracking | For women's health cross-references |
| **My Pregnancy** (lib/my_pregnancy/) | Prenatal tracking | For pregnancy → birth → child handoff |
| **My Children** (lib/my_children/) | Child management 0-18 | For child-related cross-references |
| **VICOBA/Kikoba** (lib/vicoba/) | Savings groups | For group savings features |
| **Tajirika** (lib/tajirika/) | Partner/freelancer program | For service provider connections |

## Document Structure

Generate the document with this exact structure:

```markdown
# [Module Name] — Complete User Journeys

**Module:** lib/[module_name]/
**Source spec:** docs/modules/[module_name].md

Every feature must be: **Interactive** (notifications, reminders, prompts), **Connected** (shop, pharmacy, doctor, chat, calendar, budget), and **Insightful** (reports, trends, recommendations).

---

## [N]. [FEATURE NAME]

**Entry:** [Exact navigation path from module home to this feature]
**Stage/Context:** [When/where this feature is relevant]

### User Journey
1. [Step-by-step what the user sees and does]
2. [Every tap, every form field, every button label]
3. [What happens after each action — API call, snackbar, navigation]
4. [Include the FULL flow, not just the happy path]

### CRUD Operations
- **Create:** [How user creates data — form fields, validation, what API is called]
- **Read:** [How data is displayed — list, card, chart, calendar]
- **Edit:** [How user modifies existing data — tap to edit, pre-filled form]
- **Delete:** [How user removes data — long-press, swipe, confirmation dialog]
- [Mark "NOT AVAILABLE" for any missing operation and flag it as a gap]

### Notifications & Reminders
- **[Trigger]:** "[Exact notification text with [name] placeholders]"
- [List EVERY notification this feature should send]
- [Include: timing (when), channel (push/local/in-app), frequency]
- [Categories: reminders, alerts, celebrations, prompts, summaries]

### Reports & Insights
- **[Report name]:** [What it shows, how it's calculated]
- [Daily, weekly, monthly summaries where applicable]
- [Trend analysis, comparisons, pattern detection]
- [Shareable/exportable reports where useful]

### Cross-Module Connections
- **[Module name]:** [What data flows, in which direction, triggered by what]
- [Be specific: "When user logs medication, offer 'Refill at Pharmacy' link → PharmacyModule with medication name pre-filled"]
- [Every connection should be actionable, not theoretical]

---
```

## Rules for Writing Journeys

### User Journey Rules
- **Be specific:** "User taps + FAB" not "user can add items"
- **Name every field:** "TextField: Subject, Score (number), Grade (text)" not "user fills in the form"
- **Name every button:** "Register" / "Sajili" not "user submits"
- **Show bilingual labels:** English first, Swahili in quotes: "Register" / "Sajili"
- **Include error paths:** What happens if API fails, if field is empty, if network is down
- **Include empty states:** What does the user see when there's no data yet
- **Include the return path:** How does the user get back to where they were

### Notification Rules
- **Be specific with text:** Write the actual notification string with [name], [age], [amount] placeholders
- **Include timing:** "7 days before due date", "Every evening at 8pm", "When value exceeds threshold"
- **Categorize notifications:**
  - 🔔 **Reminders** — things the user should do (take medicine, log data, pay fee)
  - ⚠️ **Alerts** — things that need attention (overdue, abnormal value, risk)
  - 🎉 **Celebrations** — achievements and milestones (streak, goal reached, first time)
  - 📊 **Summaries** — periodic digests (daily, weekly, monthly reports)
  - 💡 **Prompts** — suggestions and tips (try this, consider that, did you know)
- **Don't over-notify:** Max 2-3 push notifications per day per module. Use in-app cards for lower-priority items.

### Report Rules
- **Every data collection point needs a report.** If you collect 7 days of data, you should show a weekly trend.
- **Reports should compare:** This week vs last week, this month vs last month, child vs WHO/CDC standards
- **Reports should recommend:** Not just "sleep was 8 hours" but "sleep was 8 hours (recommended: 10-12 for age). Consider earlier bedtime"
- **Reports should be shareable:** Exportable as text or PDF for doctor visits, school records, family sharing

### Cross-Module Rules
- **Every module connects to at least 3 other modules**
- **Shangazi AI is available everywhere** — every feature can offer "Ask Shangazi about [topic]" with relevant context passed
- **Budget tracks all money movement** — any feature involving payment/expense/fee must report to ExpenditureService or IncomeService
- **Calendar captures all dates** — any feature with due dates, appointments, schedules must sync to Calendar
- **Shop is contextual** — suggest products relevant to the current feature ("Shop diapers" from diaper tracker, "Shop textbooks" from academic tracker)
- **Doctor is the health safety net** — any health concern should offer "Book a doctor consultation" link
- **Pharmacy connects to medication** — any medication mention should offer "Order from pharmacy" link

## Tanzania Context

- Currency is TZS (Tanzania Shillings), formatted with comma separators: 1,500,000
- Phone format: 0712 345 678 or +255 712 345 678
- Bilingual: English (default) + Swahili. Pattern: `isSwahili ? 'Swahili' : 'English'`
- Primary payment: M-Pesa (Vodacom), Tigo Pesa, Airtel Money
- Health: Tanzania EPI vaccination schedule, WHO growth standards, NHIF insurance
- Education: Standard 1-7 (primary), Form 1-6 (secondary), NECTA exams, HESLB loans
- Key institutions: NIDA (national ID), BRELA (business registration), TRA (tax), NHIF (health insurance)

## Output

Save the generated document to: `docs/modules/[module_name]_user_journeys.md`

## Reference Document

Use `docs/modules/my_children_user_journeys.md` as the gold-standard reference. It demonstrates exactly how every feature should be documented. Study it before generating a new user journey document. Key patterns to replicate:

- **35 features** documented end-to-end
- Each feature has: entry path, stage, step-by-step journey, CRUD, notifications, reports, cross-module
- **100+ notification types** covering all 5 categories (reminders, alerts, celebrations, summaries, prompts)
- **Notification text is exact:** `"📅 [Vaccine name] is due in 7 days for [name]. Book a clinic visit"` — not vague descriptions
- **Cross-module links are actionable:** `"Refill [medication]" link → PharmacyModule with medication name pre-filled` — not just "connects to Pharmacy"
- **Reports include comparisons:** `"This week vs last week"`, `"child vs WHO standard"` — not just raw numbers
- **CRUD gaps flagged explicitly:** `"Edit: NOT AVAILABLE — delete and re-create"` — honest about what's missing
- **Notification channel summary table** at the end showing all triggers and frequencies
- **Cross-module integration map table** at the end showing all data flows between modules

When generating a new document, aim for the same depth and specificity. Every feature should feel like a real product spec that an engineer can implement without asking questions.

## Example Usage

To generate user journeys for the Budget module:
1. Read `docs/modules/budget.md` (the spec)
2. Read `docs/modules/my_children_user_journeys.md` (the reference)
3. Apply this prompt's structure and rules
4. Output `docs/modules/budget_user_journeys.md`
