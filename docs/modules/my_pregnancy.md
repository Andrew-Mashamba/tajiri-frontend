# My Pregnancy — Prenatal Tracker

## Tanzania Context

Maternal mortality remains a challenge in Tanzania — the country's maternal mortality ratio is approximately 524 per 100,000 live births. Key contributing factors include late booking for ANC, poor adherence to the recommended 8-contact ANC model (WHO 2016), lack of awareness of danger signs, and difficulty tracking pregnancy milestones. The "Wazazi Nipendeni" SMS service reached 750,000+ registrants, proving demand for digital maternal health support.

TAJIRI's My Pregnancy module provides Tanzanian women with a comprehensive prenatal tracker that follows the WHO ANC model, adapted to the Tanzanian healthcare context (dispensary → health center → district hospital referral chain).

## International Reference Apps

1. **Flo** (77M+ users) — Week-by-week development info, AI chatbot, anonymous mode for privacy, largest community forums, symptom tracking with medical research backing.

2. **Pregnancy+** — Realistic 3D fetal development imagery, contraction timer, weight tracker, kick counter, nutrition guidance, doctor appointment logging.

3. **Ovia** — Baby size comparisons (fruit/animal), food safety database, weight gain tracking, wearable device integration (heart rate, sleep), customized health insights.

4. **Sprout** — 3D fetal development, pregnancy journal, kick counter, contraction timer, daily doctor-supplied tips.

5. **What to Expect** — Trusted editorial content from bestselling book, expert-backed labor videos, symptom monitoring, newborn care resources, community Q&A.

6. **Glow Nurture** — Symptom tracking with medical records integration, contraction tracking, baby movement detection, scheduled health alerts, wearable integration.

7. **PANDA (Tanzania)** — Icon-based ANC data collection, danger sign alerts, educational videos in Kiswahili, WHO-adapted content with local illustrations.

8. **Carry** — Pregnancy meditation, emotional cycle monitoring, stress tracking, self-care journaling, mental health professional connections.

## Feature List

### Pregnancy Setup & Tracking
1. Receive pregnancy data from My Circle ("I'm pregnant" flow) — last period date + due date auto-calculated
2. Manual pregnancy setup — enter last period date OR due date, system calculates the other
3. Week-by-week progress tracking (1-42 weeks)
4. Trimester indicator (1st: weeks 1-12, 2nd: 13-27, 3rd: 28-40)
5. Due date countdown — days remaining prominently displayed
6. Optional baby name and gender entry
7. Pregnancy journal — daily notes and photos

### Weekly Content
8. Weekly baby development summary — what's happening this week (bilingual)
9. Baby size comparison — fruit/vegetable analogy per week (Swahili names)
10. Baby measurements — length (cm) and weight (grams) per week
11. Mother's tips — what to expect, body changes, advice (bilingual)
12. Weekly checklist — things to do this week
13. Symptom logger — track symptoms per week (cramps, nausea, fatigue, etc.)
14. Symptom danger detection — flag bleeding, severe headache, high fever as emergencies

### ANC Schedule (Antenatal Care)
15. Tanzania-adapted WHO 8-contact model schedule
16. Auto-generate ANC visit dates based on pregnancy start date
17. Visit descriptions — what happens at each visit (tests, measurements, counseling)
18. Mark visits as completed with date, facility name, and notes
19. Overdue visit alerts — highlight missed visits
20. Link to TAJIRI Doctor module for booking ANC appointments
21. Sync ANC dates to TAJIRI Calendar
22. Push notification reminders 2 days before each ANC visit

### Kick Counter
23. Real-time kick counting session with timer
24. Goal: 10 kicks in under 2 hours (standard medical guidance)
25. Visual counter with animated tap feedback
26. Session history — daily/weekly kick count records
27. Alert if kicks significantly decrease from pattern

### Danger Signs Awareness
28. 8 key danger signs with descriptions and immediate actions (WHO-based)
29. Emergency call buttons — 112 (emergency), 114 (ambulance), 115 (fire)
30. "Go to hospital immediately" guidance for critical signs
31. Nearest hospital/facility finder (future: GPS integration)

### Contraction Timer (NEW — inspired by Pregnancy+)
32. Tap-to-start / tap-to-stop contraction logging
33. Duration and interval tracking
34. Pattern recognition — alert when contractions are regular (5-1-1 rule: 5 min apart, 1 min long, for 1 hour)
35. "Time to go to the hospital" guidance

### Weight Tracker (NEW — inspired by Ovia/Glow)
36. Log weight at each ANC visit or weekly
37. Weight gain chart — track against recommended range per trimester
38. BMI-based guidance (underweight/normal/overweight ranges)

### Nutrition Guide (NEW — inspired by Go Go Gaia)
39. Safe/unsafe food list for pregnancy (Tanzania-specific: raw meat, cassava, certain herbs)
40. Daily nutrient recommendations (iron, folic acid, calcium)
41. Hydration reminder
42. Meal suggestions using common Tanzanian foods

### Birth Plan & Preparation (NEW — inspired by What to Expect)
43. Hospital bag checklist (mother + baby items)
44. Birth plan builder — delivery preferences (natural/caesarean, pain relief, who's present)
45. Hospital/facility selector — choose where to deliver
46. Emergency contacts list

### Mental Health (NEW — inspired by Carry)
47. Daily mood tracker (emoji-based, same as My Circle)
48. Pregnancy affirmations (bilingual)
49. Stress check — simple weekly wellness questionnaire
50. Link to professional counseling via TAJIRI Doctor module

### "Baby is Born" Transition
51. Prominent "Baby is Born" button (visible from 36 weeks, text link before)
52. Delivery details dialog — date, type (normal/caesarean), weight, name, gender
53. Auto-update pregnancy status to "delivered"
54. Auto-register baby in My Baby module
55. Navigate to My Baby tab
56. Transfer pregnancy data (ANC history, kick records) to baby's health record

## Key Screens

1. **Pregnancy Home** — Week progress card (fruit comparison, days remaining, trimester), quick actions (Kick Counter, ANC, Danger Signs), next ANC reminder, weekly tip, emergency banner, "Baby is Born" button
2. **Weekly Detail** — Baby development, mother tips, checklist, symptom logger, size/weight info
3. **ANC Schedule** — 8-visit timeline with status (done/upcoming/overdue), mark complete dialog
4. **Kick Counter** — Real-time session with animated counter, timer, goal indicator, history
5. **Danger Signs** — 8 danger signs with emergency call buttons, hospital guidance
6. **Contraction Timer** — Tap-based contraction logging with pattern analysis
7. **Weight Tracker** — Weight log chart with recommended range overlay
8. **Birth Plan** — Checklist for hospital bag, delivery preferences, emergency contacts

## TAJIRI Integration Points

| Integration | How |
|---|---|
| **My Circle** | Receives pregnancy data when user declares "I'm pregnant" — `createPregnancy(lastPeriodDate)` |
| **My Baby** | "Baby is Born" creates baby record → navigates to My Baby module |
| **Doctor** | ANC appointments booked via DoctorModule. "Talk to a Doctor" links to gynecology |
| **Pharmacy** | Prenatal vitamins, iron supplements ordered via PharmacyModule |
| **Insurance** | NHIF maternity coverage check via InsuranceModule |
| **Calendar** | ANC visit dates + due date synced as private events |
| **Notifications** | ANC reminders (2 days before), kick counter reminders, danger sign alerts |
| **Budget** | ANC visit costs, prenatal vitamin costs tracked as `afya` expenditure |
| **Shangazi AI** | Pregnancy questions answerable via Tea chat (`getCycleSummaryForAI` includes pregnancy status) |
| **Community** | Women's Health groups for peer support during pregnancy |
| **Privacy** | Tab only visible on own profile (privacy guard) |

## Business Rules

1. **Pregnancy starts from My Circle or manual entry** — never both simultaneously
2. **Due date = LMP + 280 days** (standard Naegele's rule)
3. **Trimester calculation:** T1: weeks 1-12, T2: 13-27, T3: 28-40+
4. **ANC schedule auto-generated** from LMP following WHO 8-contact model
5. **Kick counter goal = 10 kicks** in under 2 hours
6. **Danger signs are NEVER dismissed** — always show emergency action
7. **"Baby is Born" creates two records:** updates Pregnancy to `delivered` AND creates Baby
8. **Pregnancy tab hides after delivery** — My Baby tab takes over
9. **All data is private** — only visible to the user and shared partner
