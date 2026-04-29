# My Children Module — Complete User Journeys

**Audit date:** 2026-04-12
**Module:** lib/my_children/ (43 files)

Every feature must be: **Interactive** (notifications, reminders, prompts), **Connected** (shop, pharmacy, doctor, chat, calendar, budget), and **Insightful** (reports, trends, recommendations).

---

## 1. CHILD REGISTRATION

**Entry:** Profile → My Children tab → "Add Child" button
**Stage:** All ages (0-18)

### User Journey
1. User taps "My Children" tab on profile
2. Sees child list or empty state with "Add Child" / "Ongeza Mtoto" button
3. User taps "Add Child"
4. Bottom sheet opens: "Register Child" / "Sajili Mtoto"
5. Age-adaptive form fields (fields appear/hide based on DOB):
   - **Child's Name** (required)
   - **Date of Birth** (date picker, up to 18 years back) — shows age badge
   - **Gender** (Boy/Girl choice chips)
   - **Blood Type** (dropdown: A+/A-/B+/B-/AB+/AB-/O+/O-)
   - **IF infant (0-2):** Birth Weight (g), Birth Length (cm)
   - **IF school age (5+):** School Name, Grade
   - **Allergies** (comma-separated)
   - **Emergency Contact** (name + phone)
6. User taps "Register" → API call → snackbar → list reloads

### Edit
- Long-press child card → "Edit Child" → ALL fields editable (name, DOB, gender, blood type, allergies, emergency contacts, school, birth measurements)

### Delete
- Long-press child card → "Delete Child" → confirmation → API call

### Notifications & Prompts
- **Birthday reminder:** Push notification on child's birthday morning: "Happy Birthday [name]! 🎂 [name] turns [age] today"
- **Birthday countdown:** 7 days before: "[name]'s birthday is in 7 days"
- **Stage transition:** When child crosses an age boundary (2, 5, 12, 18): "🎉 [name] is now [age]! New features are available in their dashboard"
- **Incomplete profile prompt:** If allergies or emergency contacts are empty, show a card on the dashboard: "Complete [name]'s profile — add allergies and emergency contacts for safety"
- **Photo prompt:** Monthly: "Take a monthly photo of [name] to track their growth!"

### Reports
- **Family summary card** on home page: total children, next upcoming birthday, next vaccination due, next doctor visit

### Cross-Module
- **Calendar:** Birthday synced as annual event
- **Family:** Child auto-synced to Family module members
- **Shangazi AI:** Child data (age, stage, allergies) available for context-aware parenting advice via chat

---

## 2. FEEDING TRACKER

**Entry:** Baby Dashboard → "Feeding" button or Speed-Dial FAB
**Stage:** Infant (0-2)

### User Journey
1. Three type tabs: Breastfeeding (timer), Bottle (amount), Solid Food (6+ months)
2. **Breastfeeding:** Select side → Start timer → Save when done
3. **Bottle:** Enter ml amount (quick buttons: 30, 60, 90, 120, 150, 180) → Save
4. **Solid Food:** Enter food description (quick chips: Porridge, Banana, etc.) → Save
5. History: date-selectable list with type, amount/duration, time

### Delete
- Long-press entry → confirmation → API call

### Notifications & Reminders
- **Next feed alert:** Based on baby's feeding pattern, push notification: "It's been [X] hours since [name]'s last feed — time to feed?"
- **Feeding pattern change:** If feeding frequency drops significantly: "⚠️ [name] had fewer feeds today than usual. Is everything OK?"
- **Solid food milestone:** At 6 months: "🥣 [name] is 6 months! Time to introduce solid foods. Tap for age-appropriate food suggestions"
- **Daily summary notification** (evening): "[name] today: [X] feeds, [Y] ml bottle, [Z] min breastfeeding"

### Reports
- **Daily summary:** Total feeds, total ml, total breastfeeding minutes
- **Weekly trend:** Feeds per day chart, comparing this week vs last week
- **Pattern insights:** "Baby feeds most at 6am and 10pm", "Average gap between feeds: 2.5 hours"
- **Monthly report:** Feeding type breakdown (breast vs bottle vs solid), volume trend

### Cross-Module
- **Shop:** "Running low on formula? Shop baby formula" link → opens Shop with baby formula search
- **Pharmacy:** If baby has feeding difficulties: "Talk to a pharmacist about feeding supplements"
- **Shangazi AI:** "Ask Shangazi about introducing solid foods" — passes baby's age and feeding history as context
- **Budget:** Formula/bottle purchases trackable as `watoto` expenditure

---

## 3. SLEEP TRACKER

**Entry:** Baby Dashboard → "Sleep" button or Speed-Dial FAB
**Stage:** Infant (0-2)

### User Journey
1. Tap "Start Sleep" FAB → select Nap or Night Sleep → session starts with live timer
2. Tap "Stop" → session ends, logged to API
3. Nap suggestion card: predicts next nap based on wake windows

### Delete
- Long-press session → confirmation → API call

### Notifications & Reminders
- **Nap time alert:** "⏰ [name] has been awake for [X] hours — nap time approaching" (based on age-appropriate wake windows)
- **Bedtime reminder:** "🌙 [name]'s usual bedtime is around [time]. Start the bedtime routine"
- **Sleep regression warning:** At known regression ages (4mo, 8mo, 12mo, 18mo): "Sleep may be disrupted this week — [name] is going through a developmental leap"
- **Abnormal sleep alert:** If total sleep drops below WHO minimum: "⚠️ [name] slept only [X] hours yesterday (recommended: [Y]+ hours)"

### Reports
- **Daily:** Total hours, nap count, longest stretch, night wakeups
- **Weekly chart:** Sleep hours per day, nap vs night breakdown
- **Sleep quality score:** Based on total hours vs WHO recommendation for age
- **Pattern insight:** "Best nap time is 10:30am", "Night sleep improving — 30 min more than last week"

### Cross-Module
- **Doctor:** If persistent sleep issues: "Sleep has been below normal for 7 days. Book a doctor consultation?" → DoctorModule
- **Shop:** "White noise machines and sleep aids" → Shop search
- **Shangazi AI:** "Ask Shangazi about sleep training methods for [age]"

---

## 4. DIAPER TRACKER

**Entry:** Baby Dashboard → "Diaper" button
**Stage:** Infant (0-2)

### User Journey
1. One-tap logging: Wet / Dirty / Both buttons
2. Dirty/Both → optional color picker (Green, Yellow, Brown, Black)
3. History: daily log with type, color, time

### Delete
- Long-press entry → confirmation → API call

### Notifications & Reminders
- **Dehydration alert:** After 6PM, if wet diapers < 6: "⚠️ [name] has had only [X] wet diapers today. This could indicate dehydration — offer more fluids"
- **Black/bloody stool alert:** If black or bloody color logged: "🚨 Black or bloody stool detected for [name]. Please contact your doctor immediately" → link to DoctorModule
- **Diaper supply reminder:** Weekly: "Time to restock diapers? Shop now" → Shop link

### Reports
- **Daily count:** Wet, Dirty, Both, Total
- **Weekly trend:** Diaper count per day
- **Pattern insight:** "Most diaper changes happen between 6-8am"

### Cross-Module
- **Doctor:** Automatic alert for concerning stool colors → "Book a doctor appointment?"
- **Shop:** "Shop diapers and wipes" → Shop with baby care search
- **Budget:** Diaper purchases tracked as `watoto` expenditure

---

## 5. VACCINATION

**Entry:** Any dashboard → "Vaccination" / "Chanjo"
**Stage:** All (birth through 15 years, Tanzania EPI)

### User Journey
1. Full Tanzania EPI schedule (24 vaccines) with auto-calculated due dates
2. Summary: Given / Remaining / Overdue counts
3. Tap checkmark to mark vaccine as given → API call
4. Upload RCH card photo

### Undo
- Long-press completed vaccine → "Unmark" → confirmation → API call

### Notifications & Reminders
- **7 days before:** "📅 [Vaccine name] is due in 7 days for [name]. Book a clinic visit"
- **1 day before:** "Tomorrow: [Vaccine name] for [name] at your nearest clinic"
- **Due date:** "Today: [Vaccine name] is due for [name]"
- **Overdue alert:** "⚠️ [Vaccine name] is overdue by [X] days for [name]. Delayed vaccination puts your child at risk — visit a clinic soon"
- **After vaccination:** "✅ [Vaccine name] recorded! Next vaccine: [next name] due on [date]"
- **Vitamin A reminders:** At 6mo, 12mo, 18mo intervals

### Reports
- **Vaccination card:** Complete printable/shareable record with dates
- **Compliance score:** % of vaccines given on time
- **Upcoming schedule:** Next 3 vaccines with due dates
- **Overdue list:** All missed vaccines with days overdue

### Cross-Module
- **Doctor:** "Book vaccination appointment" → DoctorModule pre-filled with reason "Vaccination: [vaccine name]"
- **Calendar:** All vaccine due dates synced as calendar events
- **Pharmacy:** After vaccination: "Baby may have mild fever. Shop infant paracetamol?" → PharmacyModule
- **Insurance:** "Check if vaccination is covered by your health insurance" → InsuranceModule
- **Shangazi AI:** "Ask Shangazi about vaccine side effects and what to expect"

---

## 6. MILESTONES

**Entry:** Any dashboard → "Milestones" / "Hatua za Maendeleo"
**Stage:** Infant, Toddler

### User Journey
1. Age-grouped checklist: Motor, Language, Social, Cognitive
2. Mark milestone achieved → API call → optional photo capture
3. Can undo milestone

### Notifications & Reminders
- **Monthly milestone alert:** "🎯 [name] is [X] months! Here are the milestones to watch for this month: [list]"
- **Wonder Weeks leap:** "Your baby may be extra fussy this week — a mental developmental leap is happening. This is normal!"
- **Achievement celebration:** When milestone marked: "🎉 Amazing! [name] achieved [milestone]! Capture this moment with a photo?"
- **Delay awareness:** If key milestone not achieved by expected age + 2 months: "💛 [name] hasn't reached [milestone] yet. Most children achieve this by [age]. Consider discussing with your doctor" → DoctorModule link
- **Play suggestion:** "Try this activity to encourage [milestone category]: [activity description]"

### Reports
- **Progress dashboard:** Milestones achieved vs expected for age, by category
- **Development timeline:** Visual timeline of when milestones were hit
- **Category scores:** Motor %, Language %, Social %, Cognitive % complete for age

### Cross-Module
- **Doctor:** Delay alerts link to doctor consultation
- **Photo Journal:** Milestone photos auto-added to photo timeline
- **Shangazi AI:** "Ask Shangazi about activities to encourage [milestone]"
- **Community:** "Share [name]'s first steps with family!" → share card

---

## 7. GROWTH CHARTS

**Entry:** Any dashboard → "Growth Charts" / "Chati ya Ukuaji"
**Stage:** All

### User Journey
1. WHO charts (0-5yr) / CDC charts (5-18yr) auto-selected
2. Tabs: Weight, Height, Head Circumference (infant), BMI (2+)
3. Gender-specific percentile lines (3rd, 50th, 97th)
4. Add measurement via + FAB: weight (kg), height (cm), head (cm), date

### Delete
- Long-press measurement → confirmation → API call

### Notifications & Reminders
- **Monthly measurement reminder:** "📏 Time to measure [name]! Take this month's weight and height measurement"
- **Clinic visit reminder:** "RCH clinic visit recommended — record [name]'s measurements at the clinic"
- **Percentile alert (underweight):** If weight drops below 3rd percentile: "⚠️ [name]'s weight is below normal range. Please consult your doctor" → DoctorModule
- **Percentile alert (overweight):** If BMI above 97th percentile: "⚠️ [name]'s BMI is above normal range. Consider discussing diet with your doctor"
- **Growth spurt notification:** If significant weight/height jump: "📈 [name] grew [X] cm this month — a growth spurt!"

### Reports
- **Growth card:** Current percentiles for weight, height, BMI
- **Trend report:** 3-month and 6-month growth trends
- **Comparison to WHO/CDC:** Where child falls relative to median
- **Exportable PDF:** Growth chart with all measurements for doctor visits

### Cross-Module
- **Doctor:** Percentile alerts link to consultation. Exportable chart for doctor visits
- **Nutrition (Toddler):** If underweight: "Review [name]'s meal plan" → ToddlerNutritionPage
- **Shop:** "Shop nutritional supplements for children" if underweight flag
- **Shangazi AI:** "Ask Shangazi about healthy weight gain for [age]"
- **Budget:** Medical costs from growth-related doctor visits tracked

---

## 8. HEALTH LOG

**Entry:** Any dashboard → "Health Log" / "Kumbukumbu za Afya"
**Stage:** All

### User Journey
1. Six log types: Temperature, Medication, Illness, Allergy, Doctor Visit, Dental
2. Tap + FAB → select type → type-specific form → Save
3. Type-specific fields:
   - **Temperature:** value, notes
   - **Medication:** drug name, dosage, frequency, start/end date
   - **Illness:** name, symptoms, treatment, outcome
   - **Allergy:** allergen, reaction severity, notes
   - **Doctor Visit:** doctor, reason, date, diagnosis, cost
   - **Dental:** dentist, date, procedure, notes

### Delete
- Long-press entry → confirmation → API call

### Notifications & Reminders
- **Medication reminders:** "💊 Time for [name]'s [medication] — [dosage] due now"
- **Medication end date:** "✅ [name]'s [medication] course ends today"
- **Follow-up reminder:** If doctor visit has follow-up date: "📅 [name]'s follow-up appointment is tomorrow"
- **Fever alert:** If temperature > 38.5°C logged: "🌡️ [name] has a high fever ([temp]°C). If it persists more than 3 days, consult a doctor" → DoctorModule link
- **Allergy alert:** When new allergy added: "⚠️ New allergy recorded: [allergen]. This has been added to [name]'s emergency card and will be flagged in meal plans"
- **Annual checkup reminder:** "It's been [X] months since [name]'s last doctor visit. Schedule an annual checkup"

### Reports
- **Health timeline:** Chronological view of all health events
- **Medication history:** All medications with dates and durations
- **Illness frequency:** How often child gets sick, common illnesses
- **Cost summary:** Total medical expenses per month/year
- **Doctor visit summary:** Exportable health history for new doctor visits

### Cross-Module
- **Doctor:** "Book follow-up appointment" from doctor visit entries → DoctorModule
- **Pharmacy:** "Refill [medication]" link → PharmacyModule with medication name pre-filled
- **Insurance:** "Claim medical expenses" link after doctor visits → InsuranceModule
- **Calendar:** Doctor visits and follow-ups synced as calendar events
- **Budget:** All medical costs auto-tracked as `afya` expenditure
- **Emergency Card:** Allergies and conditions auto-synced to emergency card
- **Shangazi AI:** "Ask Shangazi about [illness/symptom] in [age] year olds"
- **Toddler Nutrition:** New allergy auto-flagged in meal plan allergen cross-reference

---

## 9. DAILY SUMMARY

**Entry:** Baby Dashboard → "Summary"
**Stage:** Infant (expand to All stages)

### User Journey
1. Date picker → shows selected day's complete picture
2. Stats: feeds, sleep hours, diaper counts
3. Week-over-week comparison
4. Auto-detected patterns
5. Upcoming milestone alerts

### Notifications & Reminders
- **Evening digest** (8pm daily): "📊 [name]'s day: [X] feeds, [Y] hrs sleep, [Z] diapers. Tap to see insights"
- **Weekly summary** (Sunday evening): "📈 [name]'s week: sleep improved by 30min, feeding pattern stable. View full report"

### Reports
- **Daily report card:** Shareable summary of the day
- **Weekly comparison:** This week vs last week per metric
- **Monthly highlights:** Best/worst sleep days, feeding trends, milestone achievements

### Cross-Module
- **Shangazi AI:** Summary data available for parenting Q&A context

---

## 10. PHOTO JOURNAL

**Entry:** Any dashboard → "Photo Journal" / "Picha"
**Stage:** All

### User Journey
1. Photo grid organized chronologically
2. First Moments slots: First Smile, Bath, Food, Tooth, Steps, Word, Birthday
3. Tap + FAB → Camera or Gallery → upload with caption

### Delete
- Long-press photo → confirmation → API call

### Notifications & Reminders
- **Monthly photo prompt:** "📸 [name] is [X] months today! Take a monthly growth photo"
- **First moment prompt:** "Has [name] started [crawling/walking/talking]? Capture the moment!"
- **Memory flashback:** "1 year ago today: [photo from last year]" (if photos exist)
- **Growth comparison:** "See how much [name] has grown! Compare this month to 3 months ago"

### Reports
- **Photo timeline:** Scrollable visual timeline
- **Growth comparison grid:** Side-by-side monthly photos
- **Shareable milestone cards:** Auto-generated cards: "[name] is [X] months! Weight: [X]kg"

### Cross-Module
- **Milestones:** Milestone photos linked to milestone entries
- **Community:** "Share [name]'s milestone with family and friends"

---

## 11. CAREGIVER SHARING

**Entry:** Any dashboard → "Caregivers" / "Walezi"
**Stage:** All

### User Journey
1. Invite: Select role (Co-parent/Caregiver/Viewer) → Generate code → Share
2. Accept: Enter code → Accept → Access granted
3. Revoke: Tap revoke → Access removed

### Notifications & Reminders
- **New caregiver activity:** When a caregiver logs data: "👶 [caregiver name] logged a feeding for [name]"
- **Caregiver invitation accepted:** "[caregiver name] accepted your invitation and can now access [name]'s data"
- **Pending invitations:** "You have [X] pending caregiver invitations"
- **Inactive caregiver cleanup:** "🧹 [caregiver name] hasn't accessed [name]'s data in 30 days. Remove access?"

### Reports
- **Caregiver activity log:** Who logged what and when
- **Access summary:** All caregivers with their roles and last activity date

### Cross-Module
- **Chat/Messages:** "Send a message to [caregiver name]" for coordination
- **Calendar:** Shared calendar events visible to caregivers

---

## 12. POTTY TRACKER

**Entry:** Toddler Dashboard → "Potty" / "Choo"
**Stage:** Toddler

### User Journey
1. Two one-tap buttons: Success (green) / Accident (amber) → logs immediately
2. Stats: today's successes, accidents, success rate %

### Delete
- Long-press entry → confirmation → API call

### Notifications & Reminders
- **Potty schedule:** "⏰ Try sitting [name] on the potty — it's been [X] hours since last attempt"
- **Streak celebration:** "🎉 [name] has had [X] successes in a row! Keep going!"
- **Weekly progress:** "📊 This week: [X]% success rate — [better/same/worse] than last week"
- **Readiness tips:** If success rate stays low: "Potty training takes time. Here are tips for [name]'s age" → tips content

### Reports
- **Daily scorecard:** Successes, accidents, rate
- **Weekly trend:** Success rate over time chart
- **Monthly milestone:** "First accident-free day!", "First accident-free week!"

### Cross-Module
- **Shop:** "Shop potty training supplies — training pants, seat, rewards chart" → Shop
- **Shangazi AI:** "Ask Shangazi for potty training tips for [age]"

---

## 13. SPEECH TRACKER

**Entry:** Toddler Dashboard → "Speech" / "Lugha"
**Stage:** Toddler

### User Journey
1. Tap + FAB → log word/phrase: Word, Type (First Word/New/Sentence/Conversation), Language (Kiswahili/English/Both)
2. Word list with type badges and dates

### Delete
- Long-press word → confirmation → API call

### Notifications & Reminders
- **Word count milestone:** "🗣️ [name] now knows [50/100/200] words! That's amazing for [age]"
- **First word celebration:** "🎉 [name]'s first word! Don't forget to capture this in the Photo Journal"
- **Speech milestone check:** "At [age], children typically say [X] words. [name] has [Y]. [Encouragement or suggestion]"
- **Language balance:** "💡 [name] has more Kiswahili words than English. Try reading English books together to balance"
- **Weekly new words:** "This week [name] learned [X] new words: [list]"

### Reports
- **Vocabulary size:** Total words, by language, by type
- **Growth chart:** Words per month over time
- **Language breakdown:** Kiswahili vs English ratio
- **First words timeline:** When each first word/sentence/conversation happened

### Cross-Module
- **Shop:** "Shop children's books and flashcards" → Shop
- **Learning Activities:** "Activities to encourage speech development" link
- **Doctor:** If significantly below expected word count: "Consider a speech assessment" → DoctorModule
- **Shangazi AI:** "Ask Shangazi about speech development activities for [age]"

---

## 14. BEHAVIOR CHART

**Entry:** Toddler Dashboard → "Behavior" / "Tabia"
**Stage:** Toddler

### User Journey
1. 5 categories: Sharing, Listening, Helping, Kindness, Patience
2. Tap category to award sticker → count increments
3. Reward threshold (configurable) — celebration when reached

### Notifications & Reminders
- **Daily behavior prompt:** "How was [name]'s behavior today? Award stickers for good moments!"
- **Reward threshold reached:** "🏆 [name] earned [X] stickers and reached the reward! Time for a treat!"
- **Weekly behavior summary:** "This week: [name] earned [X] sharing stickers, [Y] listening stickers..."
- **Positive reinforcement tip:** "💡 Tip: Praise specific behavior — 'Great job sharing your toys!' works better than 'Good girl!'"

### Reports
- **Sticker dashboard:** Per-category counts with visual progress bars
- **Weekly/monthly trends:** Which behaviors are improving
- **Reward history:** When thresholds were reached

### Cross-Module
- **Allowance (when school age):** Good behavior stickers contribute toward allowance system
- **Shangazi AI:** "Ask Shangazi about positive discipline techniques for toddlers"

---

## 15. LEARNING ACTIVITIES

**Entry:** Toddler Dashboard → "Learning" / "Kujifunza"
**Stage:** Toddler

### User Journey
1. Age-appropriate predefined activities (Colors, Shapes, Numbers, Letters)
2. Tap checkbox to mark complete
3. Materials needed and estimated time shown

### Notifications & Reminders
- **Daily activity suggestion:** "🎨 Today's activity for [name]: [activity name]. You need: [materials]. Time: [X] minutes"
- **New age activities:** When child reaches new age bracket: "🆕 [name] is now [age]! New learning activities are available"
- **Completion streak:** "[name] has completed activities [X] days in a row!"
- **Category reminder:** "💡 [name] hasn't done any number activities this week. Try counting games today!"

### Reports
- **Completion dashboard:** % complete per category
- **Activity log:** Which activities done and when
- **Skill readiness:** "Ready for preschool" indicators based on completion

### Cross-Module
- **Shop:** "Shop educational toys and learning materials for [age]" → Shop
- **Preschool:** Completion data feeds into preschool readiness assessment
- **Shangazi AI:** "Ask Shangazi for more activities for [skill category]"

---

## 16. PRESCHOOL

**Entry:** Toddler Dashboard → "Preschool" / "Shule"
**Stage:** Toddler

### User Journey
1. Three tabs: Attendance, Fees, Daily Reports
2. Attendance: calendar grid, tap to mark Attended/Absent
3. Fees: monthly records (amount, paid, date) → syncs to Budget
4. Daily Reports: per-date teacher notes

### Notifications & Reminders
- **Morning attendance reminder:** "🏫 Mark [name]'s attendance for today"
- **Fee due date:** "📋 Preschool fee for [month] is due. Amount: TZS [X]"
- **Fee overdue:** "⚠️ Preschool fee for [month] is overdue by [X] days"
- **Attendance pattern:** "⚠️ [name] has been absent [X] times this month. Is everything OK?"
- **End of term:** "📊 [name]'s term attendance: [X]% ([Y] present, [Z] absent)"

### Reports
- **Attendance rate:** Monthly and termly percentages
- **Fee payment history:** Paid vs outstanding per month
- **Daily report archive:** Searchable by date

### Cross-Module
- **Budget:** Fees tracked as `ada_shule` expenditure via ExpenditureService
- **Calendar:** School term dates and fee deadlines synced
- **Shangazi AI:** "Ask Shangazi about preschool readiness for [age]"

---

## 17. TODDLER NUTRITION

**Entry:** Toddler Dashboard → "Nutrition" / "Lishe"
**Stage:** Toddler

### User Journey
1. Two tabs: Meal Plan (weekly grid, editable), Suggestions (food guides + allergy warnings)
2. Tap meal cell → type or pick from suggestions → saves
3. Allergy cross-reference: child's allergies from profile auto-flagged in suggestions

### Notifications & Reminders
- **Meal plan reminder:** "🍽️ Today's meals for [name]: Breakfast: [meal], Lunch: [meal]. Tap to edit"
- **New food introduction:** "💡 [name] is [age] — time to introduce [food group]! Here are safe options"
- **Allergy reminder:** When planning meals: "⚠️ Remember: [name] is allergic to [allergen]. Avoid [food items]"
- **Nutrition tip:** Weekly: "💪 Tip: Children aged [age] need [X] servings of protein daily"
- **Picky eater suggestion:** If same meals repeated: "Try offering [new food] alongside [familiar food] — toddlers may need 10-15 exposures to accept new foods"

### Reports
- **Weekly meal plan summary:** What was planned per day
- **Food variety score:** How diverse the meal plan is
- **Allergen tracking:** All flagged meals this week

### Cross-Module
- **Shop:** "Shop toddler food and snacks" → Shop
- **Pharmacy:** "Shop vitamins and supplements for toddlers" → Pharmacy
- **Health Log:** If allergy reaction logged, nutrition page auto-flags the allergen
- **Shangazi AI:** "Ask Shangazi about healthy meals for [age]"

---

## 18. SAFETY AWARENESS

**Entry:** Toddler/School Age Dashboard → "Safety" / "Usalama"
**Stage:** Toddler, School Age

### User Journey
- Read-only informational page: Water, Road, Fire, Home Safety tips by age

### Notifications & Reminders
- **Seasonal safety tips:** "☀️ Summer safety: Never leave [name] unattended near water"
- **Age-appropriate alerts:** At each new age: "🔒 New safety tips for [age]-year-olds available"
- **Home safety checklist prompt:** "Have you childproofed your home for [name]'s age? Check the safety checklist"

### Cross-Module
- **Shop:** "Shop childproofing supplies — cabinet locks, outlet covers" → Shop
- **Shangazi AI:** "Ask Shangazi about age-appropriate safety rules"

---

## 19. ACADEMIC TRACKER

**Entry:** School Age/Teen Dashboard → "Grades" / "Matokeo"
**Stage:** School Age, Teen

### User Journey
1. Year and Term selectors
2. Per-subject cards with score/grade
3. + FAB → Add: Subject, Score, Grade, Term, Year → API call
4. Tap subject → Edit form → Update → API call
5. Long-press → Delete → confirmation → API call

### Notifications & Reminders
- **Grade entry reminder:** "📝 New term results are out! Enter [name]'s grades to track progress"
- **Grade drop alert:** "📉 [name]'s [subject] grade dropped from [X] to [Y]. Consider extra help"
- **Improvement celebration:** "📈 [name]'s [subject] grade improved from [X] to [Y]! Great work!"
- **Term report ready:** "📊 [name]'s term report is ready. Tap to view average score and subject breakdown"
- **NECTA reminder (teen):** At Form 2/4/6: "NECTA exams approaching. Check [name]'s performance and identify weak subjects"

### Reports
- **Term report card:** Average score, per-subject grades, rank
- **Progress trend:** Score changes across terms
- **Subject strength/weakness:** Best and worst subjects
- **Year-over-year comparison:** Academic growth trajectory
- **Exportable report:** PDF for parent-teacher meetings

### Cross-Module
- **Career (teen):** Low science scores → "Explore arts/business career paths"; High math → "Explore engineering careers"
- **Shop:** "Shop textbooks and past papers for [subject]" → Shop
- **Budget:** Tutoring costs tracked as `ada_shule` expenditure
- **Shangazi AI:** "Ask Shangazi for study tips for [weak subject]"
- **Community:** "Find study groups for [subject]" → parent community

---

## 20. HOMEWORK TRACKER

**Entry:** School Age Dashboard → "Homework" / "Kazi"
**Stage:** School Age

### User Journey
1. Assignments grouped: Overdue, Due Today, Upcoming, Completed
2. + FAB → Add: Subject, Description, Due Date → saves locally
3. Tap checkbox to mark complete/undone
4. Long-press → Delete

### Notifications & Reminders
- **Due today:** "📚 [name] has [X] assignments due today: [list]"
- **Due tomorrow:** "📝 Reminder: [assignment] is due tomorrow"
- **Overdue alert:** "⚠️ [name] has [X] overdue assignments. Help them catch up"
- **Weekly completion rate:** "📊 This week: [name] completed [X]% of assignments on time"
- **No homework logged:** "No assignments logged this week. Check with [name]'s teacher"

### Reports
- **Completion rate:** On-time vs late vs overdue percentages
- **Subject breakdown:** Assignments per subject
- **Weekly summary:** Completed, pending, overdue counts

### Cross-Module
- **Calendar:** Assignment due dates synced as calendar events
- **Shangazi AI:** "Ask Shangazi for help with [subject] homework"

---

## 21. CHORE CHART

**Entry:** School Age Dashboard → "Chores" / "Majukumu"
**Stage:** School Age

### User Journey
1. Chore list with progress bar and total earned
2. + FAB → Create: title, reward amount, frequency → API call
3. Tap complete button → API + auto-expenditure to Budget
4. Long-press → Delete → confirmation → API call

### Notifications & Reminders
- **Daily chore reminder:** "🧹 [name] has [X] chores to complete today: [list]"
- **Chore completed:** "✅ [name] completed [chore]! TZS [amount] earned"
- **Weekly payout:** "💰 This week [name] earned TZS [total] from completing [X] chores"
- **Unfinished chores:** "⚠️ [name] has [X] chores still unfinished today"
- **Streak recognition:** "🌟 [name] has completed all chores for [X] days straight!"

### Reports
- **Weekly scorecard:** Completed vs assigned per day
- **Earnings summary:** Total earned this week/month
- **Chore completion rate:** Per-chore and overall percentages

### Cross-Module
- **Allowance:** Chore earnings auto-added to allowance balance
- **Budget:** Chore payouts tracked as `watoto` expenditure for parent
- **Wallet:** Parent can transfer earned amount to child's phone

---

## 22. ALLOWANCE

**Entry:** School Age/Teen Dashboard → "Allowance" / "Posho"
**Stage:** School Age, Teen

### User Journey
1. Balance card: current, earned, saved, spent
2. Parent wallet balance shown
3. Transaction history
4. + FAB → Log: amount, description, type (earned/spent/saved/given)
5. "Send to Child's Phone" → transfer via WalletService
6. Long-press transaction → Delete

### Notifications & Reminders
- **Weekly allowance summary:** "💰 [name]'s allowance this week: Earned TZS [X], Spent TZS [Y], Saved TZS [Z]"
- **Savings goal progress:** "🎯 [name] is [X]% toward their savings goal of TZS [target]!"
- **Savings goal reached:** "🎉 [name] reached their savings goal! Time to celebrate"
- **Overspending alert:** If spent > earned: "⚠️ [name] has spent more than earned this month. Talk about budgeting"
- **Earning opportunity:** "💡 [name] can earn TZS [X] by completing today's chores"

### Reports
- **Balance sheet:** Income, expenses, savings, gifts
- **Spending breakdown:** What money was spent on
- **Savings rate:** % of earnings saved
- **Monthly trend:** Earning and spending over time

### Cross-Module
- **Wallet:** Parent wallet balance, real money transfers
- **Chore Chart:** Auto-linked earnings
- **Financial Literacy (teen):** Feeds into budget/save/spend/give framework
- **Shop:** "What can [name] buy with TZS [balance]?" → Shop with price filter
- **Budget:** Parent's child expenses tracked in `watoto` envelope

---

## 23. ACTIVITY MANAGER

**Entry:** School Age Dashboard → "Activities" / "Shughuli"
**Stage:** School Age

### User Journey
1. Enrolled activities list with cost summary
2. + FAB → Enroll: Activity Name, Category, Schedule, Fee, Frequency → API
3. Long-press → Delete → confirmation → API call

### Notifications & Reminders
- **Activity schedule:** "⚽ [name] has [activity] today at [time]"
- **Fee due:** "💳 [activity] fee of TZS [amount] is due this [week/month]"
- **Season end:** "📅 [activity] season ends on [date]. Re-enroll?"
- **New activity suggestion:** "💡 [name] might enjoy these activities: [suggestions based on age/interests]"

### Reports
- **Monthly cost:** Total activity fees
- **Schedule overview:** Weekly activity calendar
- **Activity history:** Past and current enrollments

### Cross-Module
- **Calendar:** Activity schedules synced as recurring events
- **Budget:** Fees tracked as `watoto` expenditure
- **Shop:** "Shop sports equipment and gear" → Shop

---

## 24. READING LOG

**Entry:** School Age Dashboard → "Reading" / "Kusoma"
**Stage:** School Age

### User Journey
1. Stats: total books, completed, pages, reading streak
2. + FAB → Add: Title, Pages Read, Notes, Completed → API call
3. Long-press → Delete

### Notifications & Reminders
- **Daily reading reminder:** "📖 Reading time! [name] is on day [X] of their reading streak"
- **Streak at risk:** "⚠️ [name] hasn't logged reading today. Don't break the streak!"
- **Book finished:** "📚 [name] finished [book title]! That's [X] books this year"
- **Reading milestone:** "🏆 [name] has read [100/500/1000] pages this year!"
- **Book recommendation:** "Based on [name]'s reading: try these books for [age]"

### Reports
- **Reading stats:** Books per month, pages per day, completion rate
- **Reading streak calendar:** Streak visualization
- **Genre/subject breakdown:** What types of books

### Cross-Module
- **Shop:** "Shop children's books for [age]" → Shop
- **Shangazi AI:** "Ask Shangazi for book recommendations for [age]"

---

## 25. EMOTIONAL WELLBEING

**Entry:** School Age Dashboard → "Well-being"
**Stage:** School Age

### User Journey
1. 5 emoji mood levels → tap to set today's mood
2. Mood calendar display
3. Coping resources and self-esteem activities

### Notifications & Reminders
- **Daily mood check:** "🌈 How is [name] feeling today? Log their mood"
- **Low mood pattern:** If 3+ low mood days in a week: "💛 [name] has been feeling down lately. Here are ways to help" + tips
- **Bullying awareness:** "💬 Talk to [name] about their day. Signs of bullying include [list]"
- **Positive day:** When good mood logged: "😊 Great to hear [name] is feeling good today!"

### Reports
- **Mood calendar:** Monthly view with emoji per day
- **Mood trend:** Average mood score over weeks
- **Low periods:** Dates with consistently low moods

### Cross-Module
- **Doctor:** If persistent low mood: "Consider speaking with a counselor" → DoctorModule
- **Shangazi AI:** "Ask Shangazi about supporting [name]'s emotional health"

---

## 26. CAREER GUIDANCE

**Entry:** Teen Dashboard → "Career" / "Kazi"
**Stage:** Teen

### User Journey
1. 10-question interest assessment (rated 1-5)
2. Five clusters: Science, Business, Arts, Social, Trade
3. Results: top career paths with specific careers listed
4. Can retake assessment

### Notifications & Reminders
- **Assessment prompt:** "🎯 Help [name] explore career options! Take the career interest assessment"
- **Academic alignment:** "[name]'s career interests match [cluster]. Strong [subject] grades will help — current grade: [X]"
- **Career exploration:** "💡 This week: learn about what a [career] does. Tap to explore"
- **University prep link:** "🎓 For [career cluster], these universities in Tanzania offer relevant programs: [list]"

### Reports
- **Interest profile:** Radar chart of 5 clusters
- **Career matches:** Top 10 career matches with descriptions
- **Subject-career map:** Which subjects matter most for top careers

### Cross-Module
- **Academic Tracker:** Links grades to career requirements
- **University Prep:** Career-aligned university programs
- **Shangazi AI:** "Ask Shangazi about career paths in [cluster] in Tanzania"

---

## 27. FINANCIAL LITERACY

**Entry:** Teen Dashboard → "Financial" / "Fedha"
**Stage:** Teen

### User Journey
1. Four tabs: Earn (chore earnings), Budget (spending tracker), Save (savings goals), Give (volunteer hours)
2. Log spending, set savings targets, track volunteer hours

### Notifications & Reminders
- **Savings milestone:** "🎯 [name] saved TZS [amount]! [X]% toward the goal"
- **Budget check:** "📊 [name] has spent TZS [X] out of TZS [Y] allowance this week"
- **Financial tip:** Weekly: "💡 Money tip: [age-appropriate financial wisdom]"
- **Volunteer milestone:** "🤝 [name] has volunteered [X] hours this year!"

### Reports
- **Financial dashboard:** Income, expenses, savings, giving breakdown
- **Savings progress:** Goal tracking with projections
- **Spending habits:** Category breakdown

### Cross-Module
- **Allowance:** Earnings feed into financial literacy tracking
- **Wallet:** Real money transfers for savings
- **Budget:** Parent views child's spending in budget module
- **Shangazi AI:** "Ask Shangazi about teaching teens about money"

---

## 28. LIFE SKILLS

**Entry:** Teen Dashboard → "Life Skills" / "Ujuzi"
**Stage:** Teen

### User Journey
1. Categorized checklist: Cooking, Laundry, Time Management, Study Skills, etc.
2. Tap to mark learned (records date)
3. Independence milestones: first phone, bank account, NIDA at 18
4. Driving prep card at 17+

### Notifications & Reminders
- **New skill suggestion:** "💡 This week's life skill to practice with [name]: [skill]"
- **Independence milestone:** At 16: "🎂 [name] is old enough for a bank account! Help them open one"
- **At 18:** "🪪 [name] is 18! Time to apply for NIDA national ID"
- **Driving prep:** At 17: "🚗 [name] can start preparing for a driving licence next year"
- **Progress check:** "📊 [name] has mastered [X]% of life skills for their age"

### Reports
- **Skills completion:** % complete per category
- **Readiness score:** Overall preparedness for independence

### Cross-Module
- **NIDA module:** Link to ID application at 18
- **Driving Licence module:** Link at 18
- **Wallet:** "Open first bank account" links to Tajiri Pay
- **Shangazi AI:** "Ask Shangazi about teaching [skill] to teenagers"

---

## 29. EMERGENCY CARD

**Entry:** Any dashboard → "Emergency Card"
**Stage:** All

### User Journey
1. Displays: blood type, allergies, conditions, medications, contacts, insurance, doctor
2. Edit: tap edit icon → full form → Save via API
3. Share: tap share → formatted text via system share sheet
4. Insurance: shows active policy from InsuranceService

### Notifications & Reminders
- **Incomplete card:** "⚠️ [name]'s emergency card is missing [field]. Complete it for safety"
- **Annual review:** "📋 Review [name]'s emergency card — has anything changed? (allergies, medications, contacts)"
- **Insurance expiry:** "📅 [name]'s health insurance expires on [date]. Renew?"
- **School year start:** "🏫 Share [name]'s emergency card with their new school"

### Reports
- **Card completeness:** % of fields filled
- **Shareable card:** Formatted for schools, hospitals, babysitters

### Cross-Module
- **Insurance:** Active policy display + browse/purchase link
- **Doctor:** Share card with doctor before appointments
- **School Sharing:** Emergency data included in school share
- **Health Log:** Allergies auto-synced from health log entries

---

## 30-35. REMAINING FEATURES (Condensed)

### Dental Record (All stages)
- **Notifications:** "🦷 Time for [name]'s dental checkup" (every 6 months), "First tooth alert!"
- **Cross-module:** Doctor → dental specialist referral, Shop → toothbrush/toothpaste, Budget → dental costs

### Digital RCH Card (All stages)
- **Reports:** Unified health snapshot exportable as PDF for clinic visits
- **Cross-module:** Doctor → share before appointment, Insurance → coverage verification

### Doctor Sharing (All stages)
- **Notifications:** Before doctor appointment: "Prepare [name]'s health records to share with the doctor"
- **Cross-module:** Doctor → search and share, Calendar → appointment sync

### School Sharing (School Age, Teen)
- **Notifications:** School year start: "Share [name]'s records with the school"
- **Cross-module:** School enrollment data, health records, emergency info

### Health Checkups (School Age, Teen)
- **Notifications:** "📅 [name]'s annual checkup is overdue", "Vision test recommended at age [X]"
- **Cross-module:** Doctor → book checkup appointment, Calendar → checkup reminders, Insurance → coverage check

### University Prep (Teen, 16+)
- **Notifications:** "HESLB application deadline approaching", "NECTA results are out — check [name]'s scores"
- **Cross-module:** Career → aligned programs, Academic → grade requirements

---

## NOTIFICATION CHANNELS SUMMARY

| Channel | Trigger | Frequency |
|---------|---------|-----------|
| **baby** | Feeding due, nap time, diaper alert, vaccine due, milestone, growth measurement due | Multiple daily (infant) |
| **baby** | Homework due, chore reminder, grade alert, checkup due | Daily (school age) |
| **baby** | Career prompt, financial tip, life skill, uni prep | Weekly (teen) |
| **system** | Birthday, stage transition, profile incomplete | As needed |
| **budget** | Fee due, activity fee, medical expense | As needed |

## CROSS-MODULE INTEGRATION MAP

| From My Children | To Module | Trigger |
|-----------------|-----------|---------|
| Feeding/Sleep/Diaper alerts | **Doctor** | Persistent concerning patterns |
| Vaccination schedule | **Doctor** | Book vaccination appointment |
| Medication refill | **Pharmacy** | Medication end date approaching |
| Vaccine side effects | **Pharmacy** | After vaccination logged |
| Baby supplies | **Shop** | Formula, diapers, clothes prompts |
| School supplies | **Shop** | School year, activity enrollment |
| Books, toys | **Shop** | Reading log, learning activities |
| Parenting questions | **Shangazi AI** | Every feature has "Ask Shangazi" |
| Medical expenses | **Budget** | Doctor visits, medication, fees |
| School fees | **Budget** | Preschool, school, activity fees |
| All events | **Calendar** | Vaccines, appointments, birthdays, school |
| Health coverage | **Insurance** | Doctor visits, medication, checkups |
| Child profile | **Family** | Auto-sync children as family members |
| Parent groups | **Community** | Join parent support groups |
| Money transfers | **Wallet** | Allowance payouts, transfers |
