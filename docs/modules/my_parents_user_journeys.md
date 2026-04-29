# My Parents Module — Complete User Journeys

**Module:** lib/my_parents/
**Source spec:** docs/modules/my_parents.md

Every feature must be: **Interactive** (notifications, reminders, prompts), **Connected** (doctor, pharmacy, insurance, wallet, calendar, budget), and **Insightful** (reports, trends, recommendations).

---

## 1. PARENT REGISTRATION

**Entry:** Profile → My Parents tab → "Add Parent" button
**Stage:** All

### User Journey
1. User taps "My Parents" tab on profile
2. Sees parent list or empty state with "Add Parent" / "Ongeza Mzazi" button
3. User taps "Add Parent"
4. Bottom sheet: "Register Parent" / "Sajili Mzazi"
5. Fields:
   - **Name** (required)
   - **Date of Birth** (date picker)
   - **Gender** (Male/Female chips)
   - **Relationship** (dropdown: Mother/Father/Guardian/In-law)
   - **Phone Number** (with WhatsApp toggle)
   - **Location** (Region, District, Ward — text fields)
   - **Living Situation** (dropdown: Alone/With Spouse/With Family/Care Facility)
   - **Blood Type** (dropdown)
   - **Chronic Conditions** (comma-separated)
   - **Allergies** (comma-separated)
   - **NHIF Number** (optional)
6. User taps "Register" → API call → snackbar → list reloads

### CRUD
- **Create:** Registration form as above
- **Edit:** Long-press parent card → "Edit" → pre-filled form → update via API
- **Delete:** Long-press parent card → "Delete" → confirmation → API call
- **Read:** Parent cards on home page with photo, name, age, health status

### Notifications & Reminders
- 🎂 **Birthday:** 7 days before + on the day: "[parent] turns [age] on [date]!"
- ⚠️ **Incomplete profile:** "Complete [parent]'s profile — add chronic conditions and medications for safety"

### Reports
- **Family summary:** Total parents, next appointment, overdue medications

### Cross-Module
- **Family:** Parent auto-synced as family member
- **Calendar:** Birthday as annual event

---

## 2. HEALTH PROFILE

**Entry:** My Parents → [parent card] → Parent Dashboard → "Health Profile"
**Stage:** All

### User Journey
1. Shows current health snapshot: conditions, medications, allergies, mobility, cognitive status
2. Each section is editable

### CRUD
- **Edit conditions:** Tap section → add/remove conditions from predefined list + custom
- **Edit medications:** Links to Medication Manager for full CRUD
- **Edit mobility/cognitive:** Dropdown selection → save

### Notifications
- 📋 **Annual review:** "Time to review [parent]'s health profile. Has anything changed?"
- ⚠️ **New condition added:** "[condition] added to [parent]'s profile. Discuss with their doctor"

### Cross-Module
- **Doctor:** "Share health profile with doctor" → DoctorModule
- **Emergency Card:** Conditions auto-synced
- **Shangazi AI:** "Ask about managing [condition] in elderly"

---

## 3. MEDICATION MANAGEMENT

**Entry:** Parent Dashboard → "Medications" / "Dawa"
**Stage:** All

### User Journey
1. Active medications list with name, dosage, frequency, next dose time
2. Adherence indicator per medication (green check / red X for today)
3. + FAB → Add medication form:
   - **Name** (required)
   - **Dosage** (e.g. "500mg")
   - **Frequency** (daily/twice/thrice/weekly)
   - **Time Slots** (e.g. 08:00, 20:00)
   - **Pills Remaining** (for refill tracking)
   - **Prescribing Doctor** (text)
4. Tap medication → details + adherence history + side effects log
5. Long-press → Edit / Delete

### CRUD
- **Create:** Add form with all fields
- **Read:** Active list + adherence + refill status
- **Edit:** Tap → edit form pre-filled
- **Delete:** Long-press → confirm → API

### Notifications & Reminders
- 💊 **Dose reminder:** At each scheduled time: "Time for [parent]'s [medication] — [dosage]"
- ⚠️ **Missed dose:** 30 min after scheduled: "[parent] may have missed their [medication]. Check with them"
- 📦 **Refill alert:** When pills remaining < refill threshold: "[parent]'s [medication] is running low — [X] pills left. Order refill?"
- ✅ **Adherence summary:** Weekly: "[parent] took [X]% of medications on time this week"

### Reports
- **Adherence chart:** Daily/weekly/monthly adherence %
- **Refill forecast:** When each medication needs refill
- **Side effects log:** Timeline of reported reactions

### Cross-Module
- **Pharmacy:** "Refill [medication]" → PharmacyModule with medication name
- **Doctor:** "Discuss [side effect] with doctor" → DoctorModule
- **Budget:** Medication costs tracked as `wazazi` expenditure
- **Shangazi AI:** "Ask about [medication] side effects for elderly"

---

## 4. HEALTH MONITORING

**Entry:** Parent Dashboard → "Health Log" / "Afya"
**Stage:** All

### User Journey
1. Four tabs: Blood Pressure, Blood Sugar, Weight, Symptoms
2. Each tab shows recent readings + trend chart + add button

### Blood Pressure
- Fields: Systolic, Diastolic, Pulse, Date/Time
- Chart: trend line over time
- Alert zones: <90/60 (low), >140/90 (high)

### Blood Sugar
- Fields: Type (Fasting/Random/Post-meal), Value (mmol/L), Date
- Alert zones: <4.0 (low), >7.0 fasting / >11.1 random (high)

### Weight
- Fields: Weight (kg), Date
- Trend chart with BMI calculation

### Symptoms
- Fields: Location, Severity (1-10), Duration, Notes, Date

### CRUD
- **Create:** + button per tab → form → API
- **Read:** Scrollable history + chart
- **Delete:** Long-press → confirm → API

### Notifications
- 🩺 **Abnormal BP:** "⚠️ [parent]'s blood pressure is [value] — above normal range. Consult doctor"
- 🩸 **Abnormal sugar:** "⚠️ [parent]'s blood sugar is [value] — [high/low]. Take action"
- 📏 **Monthly check:** "Time to check [parent]'s blood pressure and blood sugar"
- 📊 **Weekly health summary:** "[parent]'s health this week: BP avg [X], Sugar avg [Y]"

### Reports
- **BP trend:** Weekly/monthly average with chart
- **Sugar trend:** Fasting vs random averages
- **Weight trend:** BMI over time
- **Health summary:** Exportable for doctor visits

### Cross-Module
- **Doctor:** Abnormal readings → "Book appointment for [parent]" → DoctorModule
- **Calendar:** Monthly check-up reminders synced
- **Shangazi AI:** "Ask about managing [parent]'s hypertension"

---

## 5. APPOINTMENTS

**Entry:** Parent Dashboard → "Appointments" / "Miadi"
**Stage:** All

### User Journey
1. Upcoming appointments list (sorted by date)
2. Past appointments with diagnosis and notes
3. + FAB → Add appointment:
   - **Doctor Name** (text)
   - **Facility/Hospital** (text)
   - **Reason** (text)
   - **Date & Time** (pickers)
4. After appointment → update with diagnosis, prescription, cost, follow-up date

### CRUD
- Full CRUD: Create, Read, Edit, Delete

### Notifications
- 📅 **3 days before:** "[parent]'s appointment with Dr. [X] is in 3 days"
- 📅 **1 day before:** "Tomorrow: [parent]'s appointment at [facility]"
- ⏰ **2 hours before:** "[parent]'s appointment is in 2 hours"
- 🔄 **Follow-up:** "Time for [parent]'s follow-up appointment"

### Reports
- **Appointment history:** All visits with outcomes
- **Cost summary:** Total medical expenses per month/year
- **Doctor directory:** Frequently visited doctors

### Cross-Module
- **Doctor:** "Book via TAJIRI Doctor" → DoctorModule
- **Calendar:** All appointments synced
- **Budget:** Visit costs as `wazazi` expenditure
- **Insurance:** "Claim this visit" → InsuranceModule
- **Pharmacy:** If prescription given → "Order medication" → PharmacyModule

---

## 6. FINANCIAL SUPPORT

**Entry:** Parent Dashboard → "Support" / "Msaada"
**Stage:** All

### User Journey
1. Monthly support card: amount sent this month, total this year
2. Transaction history
3. + FAB → Log support:
   - **Amount** (TZS)
   - **Type** (Monthly Support/Medical/Insurance/Other)
   - **Payment Method** (M-Pesa/Bank/Cash)
   - **Date**
   - **Notes**
4. "Send Now" button → opens Wallet transfer to parent's phone

### CRUD
- Full CRUD on support records

### Notifications
- 💰 **Monthly reminder:** "Time to send monthly support to [parent]. Last sent: [date]"
- 📊 **Monthly summary:** "This month you sent TZS [X] to [parent]. Total this year: TZS [Y]"

### Reports
- **Monthly/yearly totals:** By type (support, medical, insurance)
- **Trend chart:** Support amounts over months
- **Tax-relevant:** Total parent care expenses for tax purposes

### Cross-Module
- **Wallet:** "Send to Parent" → WalletService.transfer(recipientPhone)
- **Budget:** All support tracked as `wazazi` expenditure
- **Shangazi AI:** "How much should I budget for parent care?"

---

## 7. INSURANCE MANAGEMENT

**Entry:** Parent Dashboard → "Insurance" / "Bima"
**Stage:** All

### User Journey
1. NHIF card display (number, status, expiry)
2. Other policies list
3. Claims history

### Notifications
- 📋 **Renewal:** 30 days before NHIF expiry: "[parent]'s NHIF expires on [date]. Renew now"
- ✅ **Claim status:** "Claim #[X] for [parent] has been [approved/denied]"

### Cross-Module
- **Insurance:** Full integration with InsuranceModule for browse/purchase/claims
- **Budget:** Premiums tracked as `wazazi` expenditure

---

## 8. EMERGENCY CARD

**Entry:** Parent Dashboard → "Emergency Card" / "Kadi ya Dharura"
**Stage:** All

### User Journey
1. Displays: name, age, blood type, conditions, medications, allergies, emergency contacts, NHIF
2. Shareable as formatted text
3. Editable via bottom sheet form

### Notifications
- ⚠️ **Incomplete:** "Complete [parent]'s emergency card for safety"
- 📋 **Annual review:** "Review [parent]'s emergency card — has anything changed?"

### Cross-Module
- **Insurance:** NHIF status display
- **Ambulance:** "Call Ambulance" → Ambulance module with parent's location

---

## 9. WELLNESS CHECK-IN

**Entry:** Parent Dashboard → "Check-in" / "Hali"
**Stage:** All

### User Journey
1. Daily check-in card: "How is [parent] today?"
2. Quick status: Mood (4 emojis), Ate meals?, Took medication?, Exercised?, Socialized?
3. Notes field for observations
4. History calendar showing check-in streaks

### Notifications
- 🔔 **Daily prompt:** "How is [parent] today? Log a wellness check-in"
- ⚠️ **Missed 2 days:** "[parent] hasn't been checked on for 2 days. Is everything OK?"
- 📊 **Weekly summary:** "This week: [parent] — mood mostly [X], medication [Y]% adherent"

### Cross-Module
- **Doctor:** If mood consistently "unwell" → "Consider doctor visit"
- **Shangazi AI:** "Ask about caring for elderly parent with [condition]"

---

## 10. CARE TEAM (Sibling Coordination)

**Entry:** Parent Dashboard → "Care Team" / "Timu ya Huduma"
**Stage:** All

### User Journey
1. Caregiver list (siblings/family sharing parent care)
2. Invite via code (same pattern as My Children caregiver sharing)
3. Task board: assigned tasks with status
4. + FAB → Assign task: Title, Description, Assigned To, Due Date

### CRUD
- Full CRUD on tasks + invite/revoke caregivers

### Notifications
- ✅ **Task completed:** "[sibling] completed '[task]' for [parent]"
- ⏰ **Task overdue:** "Your task '[task]' for [parent] is overdue"
- 👋 **New team member:** "[name] joined [parent]'s care team"

### Cross-Module
- **Chat:** "Message [sibling]" for coordination

---

## NOTIFICATION CHANNELS SUMMARY

| Trigger | Frequency | Priority |
|---------|-----------|----------|
| Medication dose reminder | Multiple daily | HIGH |
| Missed dose alert | 30 min after dose time | HIGH |
| Refill alert | When pills low | MEDIUM |
| Appointment (3d, 1d, 2h before) | Per appointment | MEDIUM |
| Wellness check-in prompt | Daily | MEDIUM |
| Missed check-in (2 days) | As needed | HIGH |
| Monthly support reminder | Monthly | LOW |
| NHIF renewal (30 days before) | Annual | MEDIUM |
| Birthday | Annual | LOW |
| Abnormal health reading | As needed | HIGH |
| Weekly health/adherence summary | Weekly | LOW |
| Care task overdue | As needed | MEDIUM |

## CROSS-MODULE INTEGRATION MAP

| From My Parents | To Module | Trigger |
|-----------------|-----------|---------|
| Medication refill | **Pharmacy** | Pills running low |
| Health concern | **Doctor** | Abnormal reading or appointment booking |
| Medical expenses | **Budget** | Doctor visit, medication, insurance costs → `wazazi` envelope |
| Send money | **Wallet** | Monthly support transfer to parent's phone |
| Insurance management | **Insurance** | NHIF renewal, claims, coverage check |
| All appointments/dates | **Calendar** | Synced as events with reminders |
| Parent as family member | **Family** | Auto-synced |
| Emergency | **Ambulance** | SOS alert with parent's location |
| Care advice | **Shangazi AI** | Elder care questions with parent's health context |
| Caregiver groups | **Community** | Caregiver support groups |
