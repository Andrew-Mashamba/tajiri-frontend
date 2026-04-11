# My Baby — Postnatal Child Tracker

## Tanzania Context

Tanzania's under-5 mortality rate is approximately 50 per 1,000 live births. Key contributing factors include missed vaccinations, malnutrition, and delayed recognition of illness. The Tanzania Expanded Programme on Immunization (EPI) schedule includes BCG, OPV, DPT-HepB-Hib, PCV13, Rotavirus, Measles-Rubella, and Vitamin A supplementation — all at specific age milestones that parents struggle to track with paper records.

TAJIRI's My Baby module provides Tanzanian parents with a comprehensive postnatal tracker that follows the Tanzania EPI vaccination schedule, WHO growth standards, and evidence-based developmental milestones.

## International Reference Apps

1. **Huckleberry** (5M+ families) — Gold standard for sleep tracking. SweetSpot® AI predicts optimal nap times. One-touch feeding/diaper/sleep logging. Multi-caregiver sync. Key insight: **one-second access to "add feeding" button** — sleep-deprived parents need zero friction.

2. **Wonder Weeks** — Predicts 10 mental developmental leaps in first 20 months. Fussy phase warnings, skill phase celebrations. 77 developmental play games. Personal diary. Partner app sync. Key insight: **explaining WHY the baby is fussy** — parents need understanding, not just tracking.

3. **Baby Tracker (Nighp)** — Most comprehensive logging: feeding (breast timer both sides, bottle amount, solid food), sleep, diaper (wet/dirty/both), growth, medications, temperature, milestones, pumping. WHO growth charts. CSV/PDF export for doctor visits. Key insight: **export for doctor** — data must be shareable.

4. **Nurtura** — Weekly review summaries, predictions, clear charts, simple insights. Track sleep, feeds, diapers, growth, and milestones. Key insight: **weekly summary** — parents want a digest, not just raw data.

5. **TheParentZ** — Vaccination tracker with reminders, growth percentile charts (WHO), health logging, milestone tracking. Key insight: **country-specific vaccination schedule** — Tanzania EPI schedule, not US CDC.

6. **HelpMum (Africa)** — Reducing maternal and infant mortality in Africa. Vaccination tracking focused on African immunization schedules. Key insight: **Africa-specific health context** matters.

## Feature List

### Baby Registration
1. Receive baby data from My Pregnancy ("Baby is Born" flow) — name, DOB, gender, birth weight
2. Manual baby registration — name, date of birth, gender, birth weight (grams), birth length (cm)
3. Support multiple babies (twins, subsequent children)
4. Baby profile photo upload
5. Each baby has independent tracking

### Feeding Tracker
6. **Breastfeeding timer** — start/stop per side (left/right), duration tracked automatically
7. **Bottle feeding** — log amount (ml), formula/expressed milk type
8. **Solid food** — log food description, amount, time (available from 6 months)
9. **Feeding history** — daily log with time, type, duration/amount
10. **Feeding summary** — daily total: X feeds, Y minutes breastfeeding, Z ml bottle
11. **Feeding reminder** — notify when next feed is due based on pattern (every 2-3 hours for newborn)
12. **One-tap logging** — fastest possible interaction for sleep-deprived parents

### Sleep Tracker (NEW — inspired by Huckleberry)
13. **Sleep session logging** — start/stop with one tap
14. **Nap prediction** — based on baby's age and wake windows, suggest next nap time
15. **Sleep summary** — total sleep hours per day, number of naps, longest stretch
16. **Night vs day split** — track nighttime sleep vs daytime naps separately
17. **Sleep quality trend** — weekly chart showing sleep pattern development

### Diaper Tracker (NEW — inspired by Baby Tracker Nighp)
18. **Quick log** — one tap: wet / dirty / both
19. **Daily count** — total diapers changed today
20. **Pattern tracking** — alert if wet diapers drop below 6/day (dehydration risk)
21. **Color tracker** — optional stool color log (green/yellow/brown/black — black or bloody = doctor alert)

### Growth Monitoring
22. **Weight logging** — manual entry at each clinic visit or home measurement
23. **Height/length logging** — manual entry
24. **Head circumference** — manual entry
25. **WHO growth charts** — weight-for-age, height-for-age, weight-for-height, head circumference-for-age percentile charts
26. **Growth trend arrows** — ↑↓ indicating direction vs WHO median
27. **Underweight/overweight alert** — flag if below 3rd or above 97th percentile
28. **Export growth data** — PDF/image for sharing with doctor

### Vaccination Schedule (Tanzania EPI)
29. **Full Tanzania EPI schedule:**
    - Birth: BCG, OPV-0
    - 6 weeks: DPT-HepB-Hib-1, OPV-1, PCV13-1, Rotavirus-1
    - 10 weeks: DPT-HepB-Hib-2, OPV-2, PCV13-2, Rotavirus-2
    - 14 weeks: DPT-HepB-Hib-3, OPV-3, PCV13-3, IPV
    - 6 months: Vitamin A (1st dose)
    - 9 months: Measles-Rubella-1, Vitamin A (2nd dose)
    - 12 months: Vitamin A (3rd dose)
    - 15 months: Measles-Rubella-2
    - 18 months: DPT-HepB-Hib booster, Vitamin A
30. **Auto-calculate due dates** from baby's date of birth
31. **Mark vaccination as given** — date, facility, batch number (optional)
32. **Overdue alerts** — push notification when vaccination is overdue
33. **Vaccination card photo** — snap and store the physical RCH card
34. **Share vaccination record** with doctor via TAJIRI

### Developmental Milestones (NEW — inspired by Wonder Weeks)
35. **Monthly milestone checklist** — age-appropriate milestones based on WHO standards:
    - Motor: head control, rolling, sitting, crawling, standing, walking
    - Language: cooing, babbling, first words, two-word phrases
    - Social: smiling, laughing, stranger anxiety, pointing, pretend play
    - Cognitive: object permanence, cause-effect, problem solving
36. **Mark milestones achieved** — date of achievement
37. **Developmental leap alerts** — "Your baby may be fussy this week — a mental leap is happening" (Wonder Weeks concept)
38. **Play activities** — age-appropriate activity suggestions to encourage development
39. **Milestone photo journal** — attach photo to milestone (first smile, first step, etc.)
40. **Delay awareness** — gentle alert if key milestones are significantly delayed, suggest doctor visit

### Health Log (NEW)
41. **Temperature log** — record fever readings with time
42. **Medication tracker** — name, dosage, frequency, start/end date
43. **Illness diary** — log symptoms, duration, treatment, outcome
44. **Allergy tracker** — record food/environmental allergies discovered
45. **Doctor visit log** — date, reason, diagnosis, prescription, follow-up

### Daily Summary & Insights (NEW — inspired by Nurtura/Huckleberry)
46. **Daily dashboard** — today's feeds, sleeps, diapers at a glance
47. **Weekly summary** — trend analysis: "Baby slept 2 hours more this week than last"
48. **Pattern insights** — "Baby feeds most at 6am and 10pm" — detected automatically
49. **Milestone alerts** — "Baby is 4 months! Time for these milestones: ..."

### Multi-Caregiver Sharing (NEW — inspired by Huckleberry)
50. **Invite caregiver** — share baby tracking with partner, grandparent, nanny via invite code
51. **Real-time sync** — all caregivers see the same data
52. **Caregiver attribution** — each log entry tagged with who logged it
53. **Read-only option** — some caregivers can view but not log

### Photo Journal & Memories (NEW)
54. **Monthly photo prompt** — "Baby is 3 months! Take a photo to remember"
55. **First moments collection** — first bath, first food, first tooth, first steps
56. **Photo timeline** — scrollable visual timeline of baby's growth
57. **Shareable cards** — generate image cards: "Baby X is 6 months! Weight: Xkg, Height: Xcm"

## Key Screens

1. **Baby Home** — Baby list (if multiple), daily dashboard (feeds/sleep/diapers at a glance), quick-log buttons, next vaccination reminder, milestone alert
2. **Baby Dashboard** — Individual baby: photo, age, quick stats, daily log summary, growth chart preview
3. **Feeding Tracker** — Breast timer (left/right), bottle input, solid food log, daily history
4. **Sleep Tracker** — Start/stop sleep session, nap prediction, daily sleep chart
5. **Diaper Tracker** — One-tap wet/dirty/both, daily count, pattern alerts
6. **Growth Charts** — WHO percentile charts with plotted measurements, trend indicators
7. **Vaccination Schedule** — Tanzania EPI timeline, mark given, overdue alerts, RCH card photo
8. **Milestones** — Monthly checklist, mark achieved, photo journal, activity suggestions
9. **Health Log** — Temperature, medication, illness, allergies, doctor visits
10. **Weekly Summary** — Trend analysis, insights, milestone alerts
11. **Caregiver Sharing** — Invite/manage caregivers, access levels

## TAJIRI Integration Points

| Integration | How |
|---|---|
| **My Pregnancy** | Receives baby data from "Baby is Born" — name, DOB, gender, weight |
| **Doctor** | Vaccination appointments, well-baby checkups via DoctorModule |
| **Pharmacy** | Baby medicine, formula, diapers via PharmacyModule |
| **Insurance** | NHIF child health coverage check |
| **Calendar** | Vaccination due dates synced as events |
| **Notifications** | Vaccination reminders, feeding reminders, milestone alerts |
| **Budget** | Baby expenses (diapers, formula, medicine, clothes) tracked as `watoto` expenditure |
| **Shop** | Baby products (diapers, clothes, toys) discoverable from within module |
| **Family** | When child grows beyond baby stage → transition to Family module |
| **Privacy** | Tab only visible on own profile |
| **Caregiver sharing** | Partner/grandparent/nanny access via invite code |

## Business Rules

1. **Baby is created from My Pregnancy OR manually** — both paths supported
2. **Multiple babies supported** — each with independent tracking
3. **Vaccination schedule = Tanzania EPI** — auto-generated from DOB
4. **WHO growth charts** — weight/height/head percentiles
5. **Feeding type by age:** breast/bottle only until 6 months, solid food available from 6 months
6. **Diaper alert threshold:** fewer than 6 wet diapers in 24 hours = possible dehydration, suggest doctor
7. **Milestone delays:** if key milestone not marked by expected age + 2 months, gentle alert
8. **Privacy:** baby data visible only to parent and invited caregivers
9. **Caregiver roles:** owner (full access), caregiver (can log), viewer (read-only)
10. **Data export:** vaccination record and growth chart exportable as PDF for doctor visits

Sources:
- [Adamosoft: 15 Pregnancy Tracker Apps](https://adamosoft.com/blog/healthcare-software-development/pregnancy-tracker-apps/)
- [Huckleberry Baby Tracker](https://huckleberrycare.com/)
- [Wonder Weeks](https://thewonderweeks.com/)
- [Consumer Reports: Baby Tracking Apps](https://www.consumerreports.org/babies-kids/baby-tracking-apps/best-baby-tracking-apps-a6067862820/)
- [PANDA Tanzania mHealth System](https://www.mdpi.com/1660-4601/19/22/15342)
- [Tanzania ANC Guidelines (WHO)](https://platform.who.int/docs/default-source/mca-documents/policy-documents/guideline/tza-mn-21-01-guideline-2018-eng-anc-guidelines.pdf)
