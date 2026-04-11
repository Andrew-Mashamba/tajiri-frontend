# Results / Matokeo — Feature Description

## Tanzania Context

Exam results are a high-stakes, emotionally charged topic in Tanzanian student life. The current experience of receiving and managing results is fragmented and stressful:

- **NECTA results** — National exam results are published on necta.go.tz. On results day, the website crashes from traffic. Students crowd around school notice boards or check via SMS (send exam number to a short code). The moment is life-defining — Form 4 results determine if you go to A-Level or vocational training
- **University results** — Each institution has its own portal (UDSM uses ARIS, UDOM has its own system). These portals are frequently down, slow, and poorly designed. Students check results by logging in repeatedly for days until grades are posted
- **GPA confusion** — Tanzanian universities use different grading scales. Some use 5.0 GPA (A=5, B+=4, B=3...), others use 4.0 scale. Converting between systems is confusing, especially when applying for graduate programs abroad
- **HESLB implications** — Students on government loans (HESLB) must maintain a minimum GPA to retain funding. A bad semester can mean losing your loan, making grade tracking critical
- **Manual tracking** — Most students track grades in notebooks or not at all. They know their overall GPA but often can't recall individual course grades from previous semesters
- **Transcript access** — Getting an official transcript requires visiting the registrar's office, paying a fee, and waiting days or weeks. No digital version exists at most institutions
- **Supplementary exams** — Failed courses require supplementary exams with additional fees. Students need to track which courses need retaking
- **Class ranking** — Students want to know their standing but official rankings are not shared. Informal comparison happens constantly

## International Reference Apps

1. **PowerSchool** — Grade tracking, GPA calculation, attendance, parent portal, assignment grades, progress reports. Used by 45M+ students in the US.
2. **Infinite Campus** — Student information system with grade book, report cards, transcripts, parent notifications. K-12 focused.
3. **GradePoint** — Simple GPA calculator with semester tracking, what-if scenarios, course management. Student-focused mobile app.
4. **MyEdu** — Academic planner with GPA tracking, course reviews, degree planning. College student tool.
5. **Grades (iOS)** — Clean GPA tracker with multiple scale support, weight calculations, semester organization. Minimalist and effective.

## Feature List

1. Enter grades manually: select course, enter grade (letter or percentage), credit hours
2. Import grades from university portal (where API is available, e.g., ARIS for UDSM)
3. GPA calculator supporting multiple scales: 5.0 (Tanzanian), 4.0 (international), percentage
4. Semester-by-semester tracking with cumulative GPA
5. Performance trend chart: line graph of GPA over semesters
6. Subject strength analysis: bar chart showing performance by subject area
7. Credit hours tracker: total earned vs. required for graduation
8. Course list per semester with grade, credits, and status (Pass/Fail/Incomplete/Supplementary)
9. Supplementary exam tracker: flag courses needing retake with deadline and fee
10. HESLB GPA threshold alert: warning when GPA approaches minimum loan requirement
11. What-if calculator: "If I get an A in Course X, my GPA becomes..."
12. Grade prediction: based on current CA scores, predict final grade
13. Transcript builder: generate unofficial transcript PDF with all semesters
14. Share results: send semester results to parents/sponsors (privacy-controlled)
15. Class average comparison: see your grade vs. anonymous class average (if data available)
16. Dean's list tracking: highlight semesters where GPA qualifies for honors
17. Graduation progress: visual tracker showing percentage of degree completed
18. Grade notification: alert when new results are posted on university portal
19. Historical archive: store results from secondary school (NECTA) through university
20. NECTA results checker: enter exam number, retrieve and store CSEE/ACSEE results
21. Multiple degree support: track results for students pursuing double majors or multiple qualifications
22. Export results as PDF or image for sharing

## Key Screens

- **Results Dashboard** — Current semester GPA, cumulative GPA, trend chart, quick stats
- **Semester View** — Table of courses with grades, credits, and semester GPA
- **Add/Edit Grade** — Form with course name, code, grade input, credit hours, semester picker
- **GPA Calculator** — Interactive calculator with scale switcher (5.0/4.0/percentage)
- **Performance Charts** — Line graph (GPA trend), bar chart (subject analysis), pie chart (grade distribution)
- **What-If Calculator** — Hypothetical grade entry with projected GPA outcome
- **Transcript** — Formatted transcript preview with download/share options
- **NECTA Results** — Secondary school results display with division and points
- **Graduation Progress** — Visual progress bar with credits earned, required, and remaining
- **Settings** — Grading scale selection, HESLB threshold, institution, degree program

## TAJIRI Integration Points

- **ProfileService.getProfile()** — Education history (school, university, course) and optional GPA display on TAJIRI profile (privacy-controlled)
- **NotificationService + FCMService** — Grade posting alerts, HESLB GPA threshold warnings, and results release push notifications
- **WalletService.deposit(amount, provider:'mpesa')** — Pay supplementary exam fees and transcript fees via M-Pesa
- **LiveUpdateService** — Real-time grade updates pushed instantly when results are posted on university portal
- **PostService.createPost()** — Share academic achievements (Dean's list, graduation) to the TAJIRI feed
- **StoryService.createStory()** — Share results celebrations and milestone moments as stories
- **CalendarService.createEvent()** — Supplementary exam dates and result release dates synced to calendar
- **fee_status module** — GPA linked to HESLB loan eligibility; low GPA triggers fee funding risk alert (heslb tab)
- **my_class module** — Auto-populate course list from class enrollment for grade entry
- **assignments module** — CA grades from assignments feed into grade prediction
- **career module** — GPA and transcript data integrated with job/internship applications via ProfileService
- **newton module** — "What GPA do I need this semester to reach a cumulative 3.5?" calculations
- **campus_news module** — Results release announcements linked to results checker
