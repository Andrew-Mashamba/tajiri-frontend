# NECTA (National Examinations Council of Tanzania) — Feature Description

## Tanzania Context

NECTA is the government body responsible for administering all national examinations in Tanzania, established under the National Examinations Council Act, 1973. It is arguably the most emotionally significant government agency for Tanzanian families — exam results determine a child's educational future.

**What NECTA Administers:**
- **PSLE (Primary School Leaving Examination)** — Standard 7, taken by ~1 million students annually
- **FTNA (Form Two National Assessment)** — Screening exam at Form 2 level
- **CSEE (Certificate of Secondary Education Examination)** — Form 4, the critical gateway exam
- **ACSEE (Advanced Certificate of Secondary Education Examination)** — Form 6, determines university admission
- **DSEE/DTEE** — Diploma and teacher education examinations
- **QT (Qualifying Test)** — For Standard 4 students

**How Citizens Interact:**
- **Results checking** — Parents, students, and teachers flood necta.go.tz when results are published. This is the highest-traffic government event in Tanzania
- **Past papers** — Students and teachers need past examination papers for revision. NECTA sells printed copies but demand far exceeds supply
- **Certificate verification** — Employers and universities request verification of examination certificates
- **Exam registration** — Schools register candidates through NECTA systems
- **Certificate collection** — Graduates collect physical certificates from regional offices

**Current Pain Points:**
- **Website crashes on results day** — necta.go.tz consistently fails when CSEE/ACSEE/PSLE results are released. Millions of users hit the server simultaneously. Students and parents spend hours refreshing
- **Past papers are scarce** — Official past papers are sold as printed booklets at NECTA offices. Digital versions are scattered across unofficial sites with varying quality and accuracy
- **Certificate verification is slow** — Employers wait weeks for certificate verification. No online instant verification exists
- **No mobile app** — Results are only available through the website, which is not optimized for mobile
- **Results format is hard to parse** — Results are published as massive HTML tables organized by school. Finding an individual student requires scrolling through the entire school's results
- **No historical tracking** — Students can't easily access their complete examination history across PSLE, CSEE, and ACSEE in one place
- **SMS results service is unreliable** — NECTA offers SMS results checking but the service is overwhelmed on results day

## International Reference Apps

1. **KNEC (Kenya)** — Kenya National Examinations Council with KNEC portal for results, online certificate verification via QR code, and past papers
2. **WAEC (West Africa)** — West African Examinations Council with mobile app for results checking, certificate verification, and e-learning resources
3. **Cambridge Assessment** — Digital results service with candidate portal, statement of results download, and certificate verification API
4. **ZIMSEC (Zimbabwe)** — Zimbabwe Schools Examinations Council with online results and certificate verification
5. **Matric Results (South Africa)** — Department of Basic Education results app with push notifications, individual results lookup, and school performance statistics

## Feature List

1. **Check Exam Results** — Look up PSLE, FTNA, CSEE, and ACSEE results by exam number/index number. Clean, readable format showing subject grades, division/points, and pass/fail status
2. **Results Notifications** — Register exam numbers to receive push notifications the moment results are published. No more refreshing necta.go.tz — get instant alerts
3. **Results History** — Store and view all examination results in one place. PSLE through ACSEE progression tracked over the years. Family mode: track multiple students (children, siblings)
4. **Past Papers Library** — Downloadable past papers organized by exam type (PSLE/CSEE/ACSEE), subject, and year. Include marking schemes where available. Offline access after download
5. **Certificate Verification** — Verify authenticity of a NECTA certificate by entering certificate number. For employers, universities, and immigration purposes
6. **Exam Timetable** — Current year's examination timetable for all exam types. Calendar view with subject, date, time, and duration. Add to phone calendar
7. **Registration Status** — Check examination registration status by candidate number. Confirm registration details are correct before exam day
8. **Exam Centres Directory** — Find examination centres by region/district. View centre details: name, location, capacity, contact information
9. **School Performance** — View results statistics by school — pass rate, division distribution, subject performance, year-over-year trends. Compare schools within a district or region
10. **Regional Statistics** — Results analysis by region and district. Performance rankings, subject-level analysis, gender comparison, trends over multiple years
11. **Subject Analysis** — Detailed performance breakdown by subject across all candidates. Identify strongest/weakest subjects nationally and by region
12. **Results Comparison** — Compare current year results with previous years. Track national performance trends, division distribution changes
13. **Certificate Request Tracking** — Track status of certificate collection or replacement request. Nearest NECTA office for collection
14. **Exam Preparation Resources** — Study tips, subject-specific revision guides, recommended reading lists linked to past paper topics
15. **Results Sharing** — Share individual results via WhatsApp, social media, or within TAJIRI. Generate a clean results card image for sharing
16. **Exam Day Checklist** — Requirements for exam day: permitted items, reporting time, rules, what to do in case of emergency. Push reminder the day before each exam

## Key Screens

- **Home Dashboard** — Quick results lookup, upcoming exams, recent results announcements
- **Results Checker** — Input exam number with exam type selector. Display results in clean card format
- **My Results** — Stored results history for registered exam numbers
- **Past Papers** — Browse/search/download interface organized by exam, subject, year
- **Certificate Verify** — Input certificate number with verification result
- **Exam Timetable** — Calendar/list view of upcoming exams
- **School Stats** — School search with performance dashboard
- **Regional Rankings** — Map or list view of performance by region

## TAJIRI Integration Points

- **Notifications (FCMService + NotificationService)** — The killer feature: instant push alerts via `FCMService` when PSLE/FTNA/CSEE/ACSEE results are published — eliminates the need to crash necta.go.tz. Register multiple exam numbers to receive individual result notifications. Push alerts for: results publication, exam timetable changes, registration status confirmation, certificate ready for collection, exam day reminders (day before and morning of), school performance statistics publication. Channel-based notifications for different exam types
- **Groups (GroupService)** — School alumni groups via `GroupService.createGroup()` — organized by school name and graduation year. Study groups for active students. Parent-teacher association groups. Exam preparation communities by subject. Group posts via `GroupService.getGroupPosts()` for sharing past papers, study tips, revision schedules, and result celebrations. Regional education groups (by district/region). `GroupService.inviteUsers()` for teachers to invite students to study groups. `GroupService.getMembers()` for class management
- **My Family Module (my_family/)** — Track children's exam results across PSLE, FTNA, CSEE, and ACSEE from one family dashboard. Parents receive result notifications for each child's exam numbers. Multi-child result comparison. Education progression tracking (Standard 7 through Form 6). Family celebration moments when results are good. Sibling academic history comparison. Elderly family members' historical results stored for record
- **Messaging (MessageService)** — Share results with family and friends via `MessageService.sendMessage()` with formatted result cards. Teacher-parent communication about student performance. Study group coordination messages. Results sharing with formatted result images. `MessageService.createGroup()` for class chats during exam preparation. Past paper sharing in group conversations
- **Profile (ProfileService)** — Education history section on TAJIRI profile via `ProfileService.getProfile()` showing verified examination results (PSLE, CSEE, ACSEE). Verified academic credentials badge. Division/grade achievements displayed. School attended and graduation year. Academic performance serves as trust indicator for employers and institutions browsing profiles
- **Calendar (CalendarService)** — Exam dates auto-added to calendar via `CalendarService.createEvent()` with subject, time, duration, and venue. Exam timetable synced for entire exam season. Revision schedule reminders. Results publication expected dates. Certificate collection appointment scheduling. Application deadline reminders (HESLB, university admission linked to results)
- **Posts & Stories (PostService + StoryService)** — National results announcements shared via `PostService.createPost()`. Top performer celebrations. Results sharing as stories via `StoryService.createStory()` with formatted result cards. School performance comparison posts. Education policy update discussions. `PostService.likePost()`, `PostService.sharePost()`, `PostService.commentOnPost()` for result celebration engagement. Past paper sharing posts in education communities
- **HESLB Module (heslb/)** — ACSEE results directly linked to HESLB loan application eligibility. Results verification feeds into means-testing process. Academic performance from NECTA supports loan application and appeal documentation. Post-ACSEE automatic HESLB application guide triggered
- **Media (PhotoService + VideoUploadService)** — Results card image generation and sharing via `PhotoService.uploadPhoto()`. Past papers stored as downloadable documents. Certificate photos for digital storage. Exam preparation video tutorials. School performance charts as shareable images. Photo albums for school memories via `PhotoService.createAlbum()`
- **Content Discovery (ContentEngineService + HashtagService)** — Personalized exam preparation content based on student's exam type and subjects via `ContentEngineService`. Trending education hashtags (#NECTACSEE, #MatokeoForm4, #PSLEResults) via `HashtagService`. Subject-specific study material recommendations. School ranking content pushed during results season
- **Location (LocationService)** — Examination centre directory with locations via `LocationService.searchLocations()` using Tanzania hierarchy (Region, District). Nearest NECTA office for certificate collection. School locations for performance comparison. Regional results statistics mapped geographically
- **Real-time Updates (LiveUpdateService)** — Firestore listeners for real-time results publication alerts. NECTA website status monitoring (up/down indicator). New results batch publication events. School statistics update events during results processing period
- **Friends (FriendService)** — Share results with friends via `FriendService.getFriends()`. See friends' school performance (with privacy controls). Classmate connections for study groups. Alumni network building from school connections. Mutual friends at same school shown for community building
- **Presence (PresenceService)** — Show study group member availability via `PresenceService` for real-time study coordination. Teacher availability for questions during revision period
- **People Search (PeopleSearchService)** — Find classmates and alumni via `PeopleSearchService.search()` by school name and graduation year. Find tutors and teachers by subject expertise. Connect with students in same exam cohort
- **Clips (ClipService)** — Short educational video clips for exam preparation via `ClipService`. Subject-specific revision tips in clip format. Trending study technique videos. Teacher explanation clips
- **LiveStream (LivestreamService)** — Live revision sessions by teachers via `LivestreamService.createStream()`. Subject expert Q&A sessions before exams. Results day live commentary and analysis
- **Wallet (WalletService)** — Payment for premium past papers and study materials via `WalletService.deposit()`. Tutor session payments. Certificate replacement fees. Study material purchases
- **Analytics (AnalyticsService)** — Personal academic analytics: grade progression across PSLE/CSEE/ACSEE, subject strength/weakness analysis, performance relative to school and national averages. School performance trend visualizations. Regional comparison dashboards

## Available APIs

- **NECTA Results Portal** — necta.go.tz/results publishes results as HTML pages (scrape-able, structured by year/exam type/school)
- **NECTA SMS Service** — Existing SMS-based results checking (reference for data format)
- **KNEC API (Kenya)** — Reference implementation for examination results and certificate verification
- **WAEC API** — Reference for results checking and certificate verification endpoints
- **Cambridge Results API** — Gold standard for examination results delivery architecture
- TAJIRI backend should cache NECTA results data aggressively — scrape results when published and serve from our infrastructure to avoid adding load to necta.go.tz. This alone would make TAJIRI indispensable to millions of Tanzanian families
