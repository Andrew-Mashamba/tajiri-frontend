# My Parents — Elder Care Management

## Tanzania Context

In Tanzania, caring for aging parents is a deeply rooted cultural duty (*Heshima kwa Wazazi*). Adult children — often living in different cities — are expected to manage their parents' health, finances, and wellbeing. Challenges include: tracking medications for chronic conditions (diabetes, hypertension affect 33% of Tanzanians over 50), managing NHIF coverage and renewals, coordinating doctor visits remotely, sending monthly financial support via M-Pesa, and handling emergencies when you're not nearby.

TAJIRI's My Parents module gives adult children a single dashboard to manage their parents' health, medications, appointments, finances, insurance, and emergency preparedness — whether the parent lives with them or in a different region.

## International Reference Apps

1. **CareZone** — Medication management, health journal, contact list for care team. Key insight: **medication list is the centerpiece** — scan pill bottles, set reminders, track refills.

2. **Medisafe** — Pill reminder app with 95% adherence rate. Family dashboard shows if parent took their meds. Key insight: **caregiver visibility** — adult child sees parent's medication adherence in real-time.

3. **Caring Village** — Care coordination for aging parents. Shared calendar, task lists, health records, care team messaging. Key insight: **multiple siblings coordinating** — not just one child caring alone.

4. **Life360** — Family location sharing with safety features. Key insight: **wellness check-ins** — "Are you OK?" prompts with auto-alert if no response.

5. **MyTherapy** — Health tracking + medication reminders + symptom diary. Key insight: **simple enough for elderly to use** — large buttons, minimal text.

## Feature List

### Parent Registration
1. Register parent — name, date of birth, gender, photo
2. Relationship type — Mother/Father/Guardian/In-law
3. Location — region, district, ward (where parent lives)
4. Contact info — phone number, WhatsApp availability
5. Living situation — lives alone / with spouse / with family / care facility
6. Multiple parents supported (mother, father, in-laws)
7. Link to existing Family module member (if already registered)

### Health Profile
8. Blood type
9. Chronic conditions list (diabetes, hypertension, heart disease, arthritis, etc.)
10. Current medications list (name, dosage, frequency, prescribing doctor)
11. Allergies (drug, food, environmental)
12. Mobility status (independent / uses aid / wheelchair / bedridden)
13. Cognitive status (sharp / mild forgetfulness / needs supervision)
14. Emergency medical info (blood type, allergies, conditions — shareable card)

### Medication Management
15. Medication list with dosage, frequency, start date, prescribing doctor
16. Medication reminders — push notification at scheduled times
17. Refill reminders — alert when medication supply is running low (based on pills remaining)
18. Side effects log — record any adverse reactions
19. Medication adherence tracking — did parent take their meds? (caregiver can log remotely or parent confirms)
20. Pharmacy integration — "Refill this medication" → PharmacyModule

### Health Monitoring
21. Blood pressure log (systolic/diastolic/pulse, date, time)
22. Blood sugar log (fasting/random/post-meal, value, date)
23. Weight tracking with trend
24. Pain/symptom diary (location, severity 1-10, duration, notes)
25. Doctor visit log (date, doctor, reason, diagnosis, prescription, cost, follow-up)
26. Health summary exportable for doctor visits

### Appointments & Reminders
27. Doctor appointment scheduler with reminders (3 days, 1 day, 2 hours before)
28. Medication pickup/refill dates
29. Insurance renewal dates
30. Annual health checkup reminders
31. Calendar sync — all appointments synced to TAJIRI Calendar

### Financial Support
32. Monthly support tracker — how much you send to parents (M-Pesa, bank transfer)
33. Support history with totals (monthly, yearly)
34. Medical expense tracker — doctor visits, medications, tests (auto-tracked from health log)
35. Insurance premium payments
36. Budget integration — parent care expenses tracked in `wazazi` envelope
37. Wallet integration — quick "Send to Parent" via Tajiri Pay

### Insurance Management
38. NHIF status and card number
39. NHIF renewal reminders (annual)
40. Insurance claims tracking
41. Coverage verification — what's covered, what's not
42. Other insurance policies (life, health supplement)

### Emergency Preparedness
43. Emergency card — parent's critical health info, shareable with hospitals
44. Emergency contacts list (siblings, neighbors, local hospital)
45. Nearest hospital/clinic info (based on parent's location)
46. SOS alert — one-tap alert to all family members
47. Ambulance service link → TAJIRI Ambulance module

### Wellness Check-ins
48. Daily/weekly check-in prompts — "How is [parent] today?"
49. Mood tracking for parent (happy, okay, sad, unwell)
50. Activity tracking — did parent eat, take medicine, exercise, socialize?
51. Auto-alert if check-in missed for 2+ days
52. Sibling coordination — multiple children can share parent care duties

### Care Team
53. Add siblings/family as co-caregivers (shared access to parent data)
54. Task assignment — assign care tasks to siblings (buy medicine, take to doctor, send money)
55. Task completion tracking
56. Care notes — log observations about parent's condition
57. Chat/message coordination between siblings

## Key Screens

1. **My Parents Home** — Parent cards (photo, name, age, health status badge), add parent button
2. **Parent Dashboard** — Health summary, medication status, upcoming appointments, recent expenses, wellness check-in
3. **Health Profile** — Conditions, medications, allergies, mobility/cognitive status
4. **Medication Manager** — Full medication list with reminders, adherence, refill tracking
5. **Health Log** — Blood pressure, blood sugar, weight, symptoms, doctor visits
6. **Appointments** — Upcoming and past appointments with reminders
7. **Financial Support** — Support history, medical expenses, insurance, budget summary
8. **Emergency Card** — Shareable critical health info
9. **Wellness Check-in** — Daily status, mood, activities
10. **Care Team** — Siblings, task assignments, coordination

## TAJIRI Integration Points

| Integration | How |
|---|---|
| **Doctor** | Book appointments for parent, share health records |
| **Pharmacy** | Refill medications, order medicine for parent |
| **Insurance** | NHIF management, claims, coverage verification |
| **Budget** | Parent care expenses in `wazazi` envelope |
| **Wallet** | "Send to Parent" money transfers |
| **Calendar** | Appointments, medication reminders, insurance renewals |
| **Family** | Parents auto-synced as family members |
| **Ambulance** | Emergency SOS with parent's location |
| **Shangazi AI** | Elder care advice, medication questions |
| **Community** | Caregiver support groups |
| **Notifications** | Medication reminders, appointment alerts, check-in prompts |
| **My Children** | Bidirectional — parent's grandchildren visible |

## Data Model

### Parent
```
Parent {
  id, userId, name, dateOfBirth, gender, photoUrl,
  relationship (mother/father/guardian/in_law),
  phone, whatsappAvailable,
  regionId, districtId, wardId, locationName,
  livingSituation (alone/with_spouse/with_family/care_facility),
  bloodType, mobilityStatus, cognitiveStatus,
  chronicConditions[], allergies[], 
  nhifNumber, nhifStatus,
  emergencyContacts[{name, phone, relationship}]
}
```

### ParentMedication
```
ParentMedication {
  id, parentId, name, dosage, frequency (daily/twice_daily/thrice_daily/weekly),
  timeSlots[] (e.g. ["08:00", "20:00"]),
  startDate, endDate, prescribingDoctor,
  pillsRemaining, pillsPerDose, refillThreshold,
  sideEffects[], isActive
}
```

### ParentHealthReading
```
ParentHealthReading {
  id, parentId, type (blood_pressure/blood_sugar/weight/symptom),
  value, value2 (for BP: systolic/diastolic),
  unit, notes, measuredAt
}
```

### ParentAppointment
```
ParentAppointment {
  id, parentId, doctorName, facility,
  reason, date, time, 
  diagnosis, prescription, cost,
  followUpDate, notes, status (upcoming/completed/cancelled)
}
```

### FinancialSupport
```
FinancialSupport {
  id, parentId, amount, type (monthly_support/medical/insurance/other),
  description, date, paymentMethod (mpesa/bank/cash),
  receiptUrl
}
```

### WellnessCheckIn
```
WellnessCheckIn {
  id, parentId, date,
  mood (happy/okay/sad/unwell),
  ateMeals, tookMedication, exercised, socialized,
  notes, checkedBy (userId)
}
```

### CareTask
```
CareTask {
  id, parentId, assignedTo (userId), assignedBy (userId),
  title, description, dueDate,
  status (pending/in_progress/completed),
  completedAt, notes
}
```

## Business Rules

1. Multiple parents supported — each fully independent
2. Co-caregiver access — all siblings see same parent data
3. Medication reminders are critical — never miss, high-priority notifications
4. Financial support auto-tracked in Budget `wazazi` envelope
5. Emergency card always accessible — even offline (cached locally)
6. Wellness check-in auto-alerts if missed 2+ days
7. Health data is private — only registered caregivers can see
8. NHIF renewal is annual — remind 30 days before expiry
9. Parent's location used for nearest hospital lookup
10. All monetary values in TZS
