# Notes / Maelezo — Feature Description

## Tanzania Context

Lecture notes sharing is one of the most active informal economies in Tanzanian student life. The demand is enormous and the current solutions are deeply inadequate:

- Students who attend lectures take handwritten notes or photos of the whiteboard/projector. These are shared via WhatsApp groups, often as compressed, barely readable images
- When a student misses class (common due to illness, transport issues, or fee-related absence), getting notes is a social negotiation: "Who went to DSA today? Send notes please"
- Some lecturers provide printed handouts or upload PDFs to university portals (e.g., UDSM's Moodle), but most don't. The portal is often down or inaccessible on mobile
- USB drives circulate in hostels with folders of notes accumulated over years — a digital oral tradition
- Senior students sell or trade notes from previous years. "Mtihani wa mwaka jana" (last year's exam) notes are gold
- Typing notes is rare due to lack of laptops in lectures. Most notes are handwritten, then photographed
- Telegram channels like "UDSM Notes" have emerged but are unorganized and unsearchable
- Quality varies enormously: some students write excellent, detailed notes while others capture incomplete fragments

The opportunity is massive: a well-organized, searchable notes platform could transform academic performance across Tanzanian institutions.

## International Reference Apps

1. **Studocu** — Notes sharing by course and university, quality ratings, download system, contributor rewards. 25M+ users globally.
2. **Course Hero** — Study resources marketplace, tutor Q&A, flashcards, practice problems. Subscription model with free uploads.
3. **Notion** — Flexible note-taking with databases, wikis, templates, collaboration. Popular with organized students.
4. **OneNote** — Microsoft's note-taking with sections, pages, handwriting support, collaboration. Free with Microsoft account.
5. **Google Drive** — File sharing with folders, commenting, version history. Many student groups use shared Drive folders.

## Feature List

1. Upload notes in multiple formats: PDF, images (photos of handwritten notes), Word documents, PowerPoint slides
2. Organize notes by institution, department, course/subject, unit/topic, and week number
3. Semester and year tagging for historical organization
4. Full-text search within uploaded documents (OCR for handwritten notes and images)
5. Download notes for offline access with progress indicator
6. Rate notes quality: 1-5 stars with written reviews
7. Top contributors leaderboard: recognize students who share the most and best notes
8. Request notes: post a request for specific lecture notes you missed ("Need CS201 Week 5 notes on Binary Trees")
9. Fulfill requests: other students can respond to note requests with uploads
10. Lecturer-uploaded materials section: official handouts, slides, reading lists
11. Version history: when better notes for the same lecture are uploaded, link them
12. Bookmark/save notes to personal collection for quick access
13. Highlight and annotate: mark important sections within downloaded notes
14. Note templates: structured templates for different subjects (lab reports, case studies, lecture summaries)
15. Batch upload: upload multiple files at once for an entire week's lectures
16. Contributor badges: "Top Contributor," "Subject Expert," "Note Master" achievements
17. Report low-quality or incorrect notes with moderator review
18. Collaborative notes: multiple students contribute to a single shared document in real-time
19. Subject-specific formatting: math equations, chemical formulas, diagrams
20. Share notes externally via link (for friends not yet on TAJIRI)
21. Storage quota with bonus for contributing (upload notes to earn more download quota)
22. Notes statistics: view count, download count, average rating per upload

## Key Screens

- **Notes Home** — Browse by subject with recently added, most popular, and highest rated sections
- **Subject Notes** — All notes for a specific course, organized by week/topic
- **Upload Notes** — Multi-step form: select files, tag subject/week/topic, add description
- **Note Viewer** — In-app document viewer with zoom, page navigation, highlight tools
- **Note Requests** — Feed of unfulfilled note requests with subject and date filters
- **My Uploads** — Dashboard of all notes you've shared with view/download/rating stats
- **My Downloads** — Library of saved notes organized by subject
- **Leaderboard** — Top contributors ranked by uploads, ratings, and helpfulness
- **Search** — Search across all notes with filters for subject, year, rating, format
- **Contributor Profile** — View a student's shared notes, ratings, and badges

## TAJIRI Integration Points

- **PhotoService.uploadPhoto()** — Upload note photos (handwritten notes, whiteboard captures, slides) at original quality
- **PostService.createPost() / sharePost()** — Share notes as posts to the TAJIRI feed; promote top-rated notes to wider audience
- **ProfileService.getProfile()** — Contributor stats, badges, and upload history display on TAJIRI profile
- **WalletService.deposit(amount, provider:'mpesa')** — Purchase premium notes or tutor-created materials via TAJIRI wallet
- **GroupService.getMembers()** — Notes auto-organize by class membership; class notes section links here
- **MessageService.sendMessage()** — Share notes directly in class chat; files shared in chat can be "promoted" to notes repository
- **VideoUploadService** — Upload video explanations and tutorial recordings alongside written notes
- **ClipService** — Short video note summaries and visual study tips
- **HashtagService** — Tag notes with #UDSM, #CS201, #FormFour for discoverability
- **my_class module** — Notes auto-organize by class enrollment; class notes section links here
- **class_chat module** — Files shared in chat can be "promoted" to the notes repository with proper tagging
- **assignments module** — Link relevant notes to assignments for reference while working
- **exam_prep module** — Notes feed into flashcard and quiz generation via Newton AI
- **newton module** — AI summarizes notes, generates questions from notes, explains difficult concepts
- **study_groups module** — Study group members share and collaborate on notes within group context
- **past_papers module** — Link notes to relevant past paper questions for comprehensive study material
