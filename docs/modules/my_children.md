# My Children — Complete Child Management (Ages 0-18)

## Tanzania Context

Tanzanian parents face unique challenges managing their children's development across ages. Paper-based RCH (Reproductive and Child Health) cards get lost, school fee receipts are scattered, vaccination records are incomplete, and tracking multiple children's needs across different ages is overwhelming. The "Wazazi Nipendeni" SMS service proved demand (750,000+ registrants) — parents want digital support.

TAJIRI's My Children module provides a comprehensive child management platform that **evolves with the child's age** — automatically showing age-appropriate features from birth through 18 years. It integrates deeply with TAJIRI's education, health, financial, and social modules to create a unified parenting dashboard.

## International Reference Apps

1. **Huckleberry** (5M+ families) — Gold standard for infant/toddler tracking. Sleep prediction, feeding timer, growth charts. Key insight: **one-second logging for sleep-deprived parents**.

2. **Wonder Weeks** — Developmental leap predictions for 0-20 months. Explains WHY the child is fussy. Key insight: **parents need understanding, not just tracking**.

3. **CDC Milestone Tracker** — Evidence-based developmental milestones 2 months to 5 years. Act Early alerts. Key insight: **share milestone data with doctors for early intervention**.

4. **Greenlight** (USA) — Kids' debit card + financial literacy. Chores → earn allowance → save/spend/invest. Key insight: **connecting work to money teaches financial responsibility**.

5. **FamilyWall** — Family organizer with shared calendar, location tracking, safe zones, task management, messaging. Key insight: **whole family on one platform** — everyone sees the same schedule.

6. **Bark** — Parental monitoring for teens. Screen time, safe zone alerts, content monitoring. Key insight: **age-appropriate digital safety** — more control for younger, more freedom for older.

7. **Cozi** — Shared family calendar for school events, doctor appointments, activities. Key insight: **one calendar for the whole family** eliminates "I didn't know about that."

8. **SavvyKids** — Chore tracking + allowance + savings goals for financial literacy. Key insight: **gamification makes chores fun** — kids compete for rewards.

9. **eRedbook (UK)** — Digital child health record replacing the paper "Red Book." Vaccination records, growth charts, health visitor notes, all digitized. Key insight: **replace the paper health card with a digital version** that can't be lost.

10. **ParentApp (Tanzania)** — Offline-first parenting programme adapted for Tanzanian context. Home visit support, caregiving skills. Key insight: **Tanzania-specific content in Kiswahili** matters.

## How It Works

```
┌─────────────────────────────────────────────────────┐
│                   MY CHILDREN                        │
│                                                     │
│  ┌─────────┐  ┌─────────┐  ┌─────────┐            │
│  │ Amina   │  │ Juma    │  │ Neema   │            │
│  │ 6 months│  │ 7 years │  │ 15 years│            │
│  └────┬────┘  └────┬────┘  └────┬────┘            │
│       │            │            │                   │
│  INFANT MODE  SCHOOL MODE  TEEN MODE               │
│  - Feeding    - Grades     - Academic              │
│  - Sleep      - Homework   - Career                │
│  - Diapers    - Chores     - Financial             │
│  - Growth     - Allowance  - Health                │
│  - Vaccines   - Activities - Safety                │
│  - Milestones - Health     - Independence          │
└─────────────────────────────────────────────────────┘
```

Each child's profile **automatically adapts** based on their current age. A 6-month-old shows feeding timers and vaccination reminders. A 7-year-old shows school grades and chore charts. A 15-year-old shows career guidance and financial literacy.

## Age-Based Feature Stages

### Stage 1: Infant (0-2 years) — ALREADY BUILT
This is the existing `lib/my_baby/` module, now embedded as the infant stage:
- Feeding tracker (breast timer, bottle, solid food from 6mo)
- Sleep tracker with nap prediction
- Diaper tracker with dehydration alerts
- Growth monitoring (WHO percentile charts)
- Tanzania EPI vaccination schedule (21 vaccines)
- Developmental milestones (Wonder Weeks leaps)
- Health log (temperature, medication, illness, allergy, doctor visits)
- Daily summary and insights
- Caregiver sharing
- Photo journal

### Stage 2: Toddler (2-5 years)
1. **Potty training tracker** — log successes/accidents, streak counter, reward stickers
2. **Speech development** — first words log, vocabulary milestone checklist, age-appropriate speech milestones
3. **Preschool/daycare** — attendance tracking, fee payments (→ Budget `ada_shule`), daily reports from caregiver
4. **Behavior chart** — positive behavior stickers, reward system for good behavior
5. **Learning activities** — age-appropriate activity suggestions (colors, shapes, counting, ABCs in Swahili/English)
6. **Nutrition transition** — meal planner for toddler diet, allergy tracking, picky eater suggestions
7. **Continued vaccination** — booster shots, Vitamin A supplements through 5 years
8. **Growth monitoring continues** — WHO charts extend to 5 years
9. **Developmental milestones** — 2-5 year milestones (running, jumping, sentences, pretend play, empathy)
10. **Safety awareness** — age-appropriate safety tips (water, road, home hazards)

### Stage 3: School Age (5-12 years)
11. **School enrollment** — link child to school (→ TAJIRI Education modules: My Class, Timetable, Fee Status)
12. **Academic tracking** — grades/results per subject, term reports, progress trend charts
13. **Homework tracker** — assignments with due dates, completion status
14. **School fee management** — fee balance, payment history, receipt storage (→ Budget `ada_shule` envelope)
15. **Extracurricular activities** — sports, arts, clubs with schedule and fees
16. **Chore chart** — assigned chores with completion tracking, weekly rotation
17. **Allowance system** — earn allowance from chores, track savings goals (→ Wallet integration)
18. **Reading log** — books read, pages, reading streak
19. **Health checkups** — annual checkup reminders, vision/hearing tests, dental visits
20. **Growth monitoring continues** — WHO/CDC charts to 18
21. **Emotional well-being** — mood check-ins, bullying awareness, self-esteem activities
22. **Digital safety basics** — screen time awareness, safe internet habits education

### Stage 4: Teenager (12-18 years)
23. **Academic dashboard** — NECTA results integration, GPA tracking, subject strengths/weaknesses
24. **Career guidance** — interest assessments, career exploration, subject-career mapping
25. **Financial literacy** — budget basics, savings goals, earn-save-spend-give framework
26. **First job/hustle tracking** — earnings from odd jobs, small business (→ Budget/Wallet)
27. **Health & puberty** — age-appropriate health info, mental health check-ins, substance awareness
28. **University preparation** — HESLB application reminders, university research, programme matching (→ TAJIRI Education)
29. **Life skills** — cooking basics, laundry, time management, study skills
30. **Independence milestones** — first phone, first bank account, first ID (NIDA at 18)
31. **Driving preparation** — driving license eligibility at 18 (→ TAJIRI Driving Licence module)
32. **Community service** — volunteer hours tracking (→ TAJIRI Jumuiya module)

## Cross-Age Features (All Stages)

### Child Profile
33. **Photo profile** with name, DOB, gender, blood type
34. **Age auto-calculated** with stage auto-detection
35. **Multiple children** with independent profiles
36. **Digital RCH card** — replaces paper health card, always accessible
37. **Emergency info card** — blood type, allergies, emergency contacts, insurance number — shareable with schools/hospitals

### Health Record (0-18)
38. **Vaccination record** — full schedule from EPI (0-5) through school boosters, HPV (girls 14+), tetanus
39. **Growth charts** — WHO 0-5, CDC 5-18 percentile tracking
40. **Comprehensive health history** — all doctor visits, diagnoses, medications, allergies across all ages
41. **Insurance coverage** — NHIF status, CHF status, what's covered (→ TAJIRI Insurance module)
42. **Dental record** — first tooth, dental visits, braces tracking

### Family Calendar Integration
43. **School calendar** — term dates, exams, parent-teacher meetings (→ TAJIRI Calendar)
44. **Vaccination reminders** — push notifications before due dates
45. **Doctor appointment reminders**
46. **Activity schedule** — sports practice, tutoring, religious classes
47. **Birthday countdown** — days until birthday, party planning checklist

### Financial Tracking Per Child
48. **Child expense tracking** — all costs attributed to this child flow into Budget `watoto` envelope
49. **School fees** — paid/outstanding balance per term (→ Fee Status module)
50. **Medical expenses** — doctor/pharmacy costs per child
51. **Activity fees** — sports, tutoring, club memberships
52. **Clothing/supplies** — seasonal needs tracking
53. **Allowance account** — virtual piggy bank within TAJIRI Wallet (→ child sub-wallet)

### Shared Access
54. **Co-parent access** — both parents see same child data (divorced/separated families supported)
55. **Caregiver access** — nanny, grandparent, teacher can view selected data
56. **Doctor access** — share health records with doctor for appointments
57. **School access** — share attendance/health info with school admin

## Key Screens

1. **My Children Home** — Child cards (photo, name, age, stage badge), add child button, family summary stats
2. **Child Dashboard** — Age-adapted: shows relevant quick actions, stats, reminders based on child's current stage
3. **Health Record** — Unified health timeline across all ages, vaccination schedule, growth charts, doctor visits
4. **School Hub** — Grades, fees, homework, timetable (links to TAJIRI Education modules)
5. **Chore Chart** — Assigned tasks, completion status, allowance earned, reward shop
6. **Growth Charts** — WHO/CDC percentiles 0-18 years, weight/height/BMI
7. **Milestones** — Age-appropriate checklist (infant motor → toddler speech → school academic → teen life skills)
8. **Financial** — Child's expenses, allowance balance, savings goals
9. **Photo Timeline** — Monthly/yearly photos, milestone moments, shareable cards
10. **Emergency Card** — Shareable card with child's critical info for schools/hospitals
11. **Activity Manager** — Sports, clubs, tutoring schedule with costs

## TAJIRI Integration Points

| Integration | How |
|---|---|
| **My Pregnancy** | Receives child data from "Baby is Born" flow |
| **Education** (My Class, Timetable, Assignments, Results, Fee Status, Past Papers, Exam Prep, NECTA, HESLB) | School data flows into child's academic dashboard |
| **Doctor** | Child health records shared with doctor for appointments |
| **Pharmacy** | Child medication ordered with allergy cross-check |
| **Insurance** (NHIF) | Child coverage verification, claims for checkups |
| **Calendar** | School events, vaccination dates, doctor appointments synced |
| **Budget** | Child expenses tracked in `watoto` envelope, school fees in `ada_shule` |
| **Wallet** | Child's allowance as sub-wallet, chore earnings deposited |
| **Notifications** | Vaccination reminders, school fee deadlines, checkup reminders, homework due dates |
| **Shop** | School supplies, uniforms, baby products discoverable from child profile |
| **Groups** | Parent groups (school parent community, age-group parenting support) |
| **Shangazi AI** | Parenting questions answered in Tea chat with child's age context |
| **Family** | Children data flows into Family tab for whole-family view |
| **Driving Licence** | At 18, prompt for driving licence application |
| **NIDA** | At 18, prompt for national ID application |
| **Career** | Teen career exploration linked to TAJIRI Career module |

## Architecture: Age-Adaptive UI

The module uses a single child profile model that automatically shows different UI based on `child.ageInYears`:

```dart
Widget build(BuildContext context) {
  final age = child.ageInYears;
  
  if (age < 2) return InfantDashboard(child: child);      // existing My Baby screens
  if (age < 5) return ToddlerDashboard(child: child);     // new
  if (age < 12) return SchoolAgeDashboard(child: child);   // new
  return TeenDashboard(child: child);                       // new
}
```

Each dashboard shows age-appropriate quick actions, stats, and navigation. Features from previous stages don't disappear — they move to a "History" section (e.g., a 10-year-old can still view their vaccination history from infancy).

## Business Rules

1. **Child age determines visible features** — auto-calculated from DOB
2. **Previous stage data is always accessible** — just moved to history/archive section
3. **Multiple children supported** — each fully independent
4. **Co-parent sharing is equal** — both parents have full access by default
5. **Caregiver access is role-based** — full access, log-only, or view-only
6. **Health data is always private** — never visible on social profile
7. **School integration requires linking** — child must be linked to a specific school to see grades
8. **Allowance is real money** — earned from chores, stored in TAJIRI Wallet sub-account
9. **Vaccination schedule adapts** — EPI for 0-5, school boosters for 5-12, HPV/tetanus for teens
10. **Growth charts switch** — WHO for 0-5, CDC for 5-18

## Data Model

### Child (extends existing Baby model)
```
Child {
  id, userId, name, dateOfBirth, gender,
  bloodType, photoUrl,
  birthWeightGrams, birthLengthCm,
  schoolId, schoolName, grade,
  insuranceNumber, nhifStatus,
  emergencyContacts[],
  allergies[],
  stage → computed: infant/toddler/school_age/teen
  ageInYears → computed from DOB
  ageInMonths → computed from DOB
}
```

### ChoreAssignment
```
ChoreAssignment {
  id, childId, title, titleSwahili,
  frequency (daily/weekly), 
  rewardAmount (TZS),
  isCompleted, completedAt,
  assignedBy
}
```

### AllowanceTransaction
```
AllowanceTransaction {
  id, childId, amount, type (earned/spent/saved/given),
  description, source (chore/gift/other),
  date
}
```

### AcademicRecord
```
AcademicRecord {
  id, childId, term, year,
  subject, grade, score,
  teacherNotes, schoolId
}
```

### ActivityEnrollment
```
ActivityEnrollment {
  id, childId, activityName, category,
  schedule, feeAmount, feeFrequency,
  startDate, endDate
}
```

Sources:
- [CDC Milestone Tracker](https://www.cdc.gov/act-early/milestones-app/index.html)
- [Greenlight Kids Banking](https://greenlight.com)
- [FamilyWall](https://www.familywall.com)
- [Huckleberry Baby Tracker](https://huckleberrycare.com/)
- [Wonder Weeks](https://thewonderweeks.com/)
- [SavvyKids](https://savvy-kids.com/)
- [eRedbook Digital Health Record](https://www.eredbook.org.uk/)
- [ParentApp Tanzania](https://pubmed.ncbi.nlm.nih.gov/38351094/)
- [Bark Parental Controls](https://www.bark.us/)
