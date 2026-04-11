# Past Papers / Mitihani ya Zamani — Feature Description

## Tanzania Context

Past exam papers are arguably the single most sought-after academic resource in Tanzania. The demand is universal — from Form 4 students preparing for NECTA national exams to university final-year students. The current ecosystem is fascinating and deeply flawed:

- **NECTA past papers** — The National Examinations Council of Tanzania publishes some past papers on necta.go.tz, but the website is slow, poorly organized, and often offline during peak demand (exam season). PDFs are low quality scans
- **University past papers** — These are NOT officially distributed in most institutions. Students obtain them through informal networks: seniors pass down USB drives of accumulated papers, photocopy shops near campus sell printed bundles, WhatsApp groups circulate them
- **The "Majibu" culture** — Students don't just want questions; they want "majibu" (answers/solutions). Worked solutions are worth more than the questions themselves. Students who can solve past papers become informal tutors
- **Photocopy shop economy** — Shops near every campus (e.g., "Bango Photocopies" near UDSM) have built businesses around printing past papers. They organize papers by department and charge per page
- **Quality issues** — Papers are often incomplete, mislabeled by year, or have incorrect marking schemes. No quality verification exists
- **Marking scheme scarcity** — Official marking schemes are rarely available. Students rely on "model answers" created by top-performing seniors
- **CSEE and ACSEE** — Certificate of Secondary Education Examination (Form 4) and Advanced Certificate (Form 6) past papers are critical for millions of students annually. Private schools and tuition centers build their entire curriculum around past paper drilling

A centralized, quality-verified past papers platform would serve millions of Tanzanian students.

## International Reference Apps

1. **PastPapers.co** — Cambridge IGCSE/A-Level past papers organized by subject, year, season, paper variant. Clean interface, free downloads. The gold standard.
2. **SaveMyExams** — Organized by exam board, topic-based questions from past papers, marking schemes, revision notes. Freemium model.
3. **GCE Guide** — Cambridge past papers with marking schemes, examiner reports, grade thresholds. Comprehensive archive.
4. **Exam.net** — Digital exam platform with paper browser, randomized questions from past papers. Teacher-focused.
5. **Brainly** — Community Q&A where students post past paper questions and get crowdsourced solutions. Social learning.

## Feature List

1. Browse papers by education level: Primary (PSLE), Form 4 (CSEE/NECTA), Form 6 (ACSEE), Diploma, Degree, Masters
2. Filter by subject: Mathematics, Physics, Chemistry, Biology, English, Kiswahili, History, Geography, Commerce, Accounting, etc.
3. Filter by year: 2015-2026+ with clear year labels
4. Filter by institution: UDSM, UDOM, ARU, SUA, MUST, MU, specific secondary schools
5. Filter by exam type: Mid-semester, End-semester, Supplementary, NECTA, Mock exam
6. Download papers as PDF for offline access
7. In-app PDF viewer with zoom, page navigation, and night mode
8. Marking schemes/model answers linked to each paper
9. Worked solutions: step-by-step answers with explanations (community-contributed or AI-generated)
10. Difficulty rating: community votes on paper difficulty (Easy/Medium/Hard)
11. Bookmark favorite papers for quick access
12. Contribute papers: upload past papers with metadata (subject, year, institution, exam type)
13. Quality verification: moderators review uploaded papers for completeness and accuracy
14. Contributor rewards: badges and leaderboard for top uploaders
15. Paper discussion: comment section per paper for questions about specific problems
16. Practice mode: attempt questions with timer, then reveal answers
17. Topic-based browsing: find questions on specific topics across multiple years
18. Related papers: "Students who viewed this also viewed..." recommendations
19. Paper statistics: download count, view count, average difficulty rating
20. Notification when new papers are added for bookmarked subjects
21. Request a paper: post request for specific papers not yet in the system
22. AI-powered similar question finder: "Show me more questions like this one"
23. Share papers via WhatsApp, Telegram, or TAJIRI messaging
24. Offline library: manage downloaded papers with local search

## Key Screens

- **Past Papers Home** — Browse by level with popular subjects highlighted, recently added papers
- **Subject Browser** — Grid of subjects with paper count, filter chips for year/level/institution
- **Paper List** — Filtered list of papers with year, type, difficulty rating, download count
- **Paper Viewer** — Full-screen PDF viewer with toolbar (download, bookmark, share, discuss)
- **Marking Scheme** — Side-by-side or tabbed view with question paper and marking scheme
- **Upload Paper** — Multi-step form: upload file, tag metadata, preview, submit for review
- **My Library** — Downloaded papers organized by subject, search within downloads
- **Discussion** — Comment thread per paper for questions, solutions, and tips
- **Paper Request Board** — Feed of requested papers with subject and year
- **Contributor Dashboard** — Stats on uploads, downloads of your papers, badges earned

## TAJIRI Integration Points

- **ClipService** — Video solutions for past paper questions; short video walkthroughs of worked answers
- **PostService.sharePost()** — Share papers directly in class channels and to the TAJIRI feed
- **MessageService.sendMessage()** — Share papers directly in class chat conversations
- **ProfileService.getProfile()** — Contributor badges and upload stats display on TAJIRI profile
- **WalletService.deposit(amount, provider:'mpesa')** — Purchase premium worked solutions or tutor-verified answers
- **GroupService.getMembers()** — Papers auto-suggest based on class enrollment and group membership
- **HashtagService** — Tag papers with #NECTA, #UDSM, #FormFour, #CSEE for discoverability
- **NotificationService** — Alerts when new papers are added for bookmarked subjects
- **exam_prep module** — Past paper questions feed into quiz mode and flashcard generation
- **newton module** — AI generates worked solutions for past paper questions, explains step-by-step concepts
- **class_notes module** — Link relevant lecture notes to past paper topics for comprehensive review
- **study_groups module** — Groups discuss past papers together with shared viewer and timed practice
- **class_chat module** — Share papers directly in class channels for discussion
- **my_class module** — Papers auto-suggest based on class enrollment
- **career module** — Professional exam past papers (CPA, ACCA, ATEC) for career advancement
