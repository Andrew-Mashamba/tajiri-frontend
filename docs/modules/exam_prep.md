# Exam Prep / Mitihani — Feature Description

## Tanzania Context

Exam preparation in Tanzania follows predictable but stressful patterns. Most students rely on a combination of:

- **Past papers** — The single most valued resource. Students believe (often correctly) that lecturers recycle questions. Getting past papers from seniors is a social ritual
- **"Mabesheni"** — Informal study groups that form 2-3 weeks before exams, often in hostels or under trees on campus. Students teach each other, share notes, and quiz one another
- **Private tutors** — Students who excelled in a subject offer paid tutoring, especially for difficult courses like Engineering Mathematics, Organic Chemistry, or Accounting
- **All-night studying ("kusoma usiku")** — Campus libraries fill up during exam season. Power outages are a constant threat, so students buy candles or use phone flashlights
- **Cramming culture** — Many students don't study consistently throughout the semester, leading to intense last-minute preparation
- **Mental health impact** — Exam anxiety is significant but rarely addressed. Failed exams mean repeating courses (supplementary exams cost extra fees) or losing HESLB loans
- **Study materials scarcity** — Textbooks are expensive and library copies are limited. Students share photocopied chapters
- **NECTA preparation** — For secondary school students, Form 4 and Form 6 national exams determine entire futures. Prep starts months in advance

Digital study tools are barely used. Students who discover Quizlet or Anki gain significant advantages but few know about them.

## International Reference Apps

1. **Quizlet** — Flashcard creation, spaced repetition, learn mode, match games, test mode. 60M+ monthly users. Gold standard for flashcards.
2. **Anki** — Spaced repetition algorithm, custom card types, community decks, cross-platform sync. Preferred by medical and law students.
3. **Khan Academy** — Video lessons, practice exercises, progress tracking, personalized learning paths. Free and comprehensive.
4. **Pomodoro Timer apps (Forest, Focus To-Do)** — Study session timing with breaks, productivity stats, distraction blocking.
5. **Notion/RemNote** — Connected notes with flashcard generation, knowledge graphs, spaced repetition. Modern study workflow.

## Feature List

1. Flashcard creator: front/back cards with text, images, and math equations
2. Flashcard study mode with swipe left (don't know) / swipe right (know) and spaced repetition algorithm
3. Auto-generate flashcards from uploaded notes using Newton AI
4. Quiz generator: create multiple-choice, true/false, fill-in-the-blank, and short answer quizzes
5. Quiz from notes: AI analyzes uploaded notes and generates relevant quiz questions
6. Study timer with Pomodoro technique: 25-min focus / 5-min break (configurable)
7. Study session tracking: total hours studied per subject, daily/weekly streaks
8. Exam countdown widgets: show days remaining until each exam with urgency colors
9. Study plan generator: input exam dates and topics, AI creates a daily revision schedule
10. Revision checklists: list all topics per subject, check off as reviewed
11. Formula sheets: quick-reference cards for math, physics, chemistry, accounting formulas
12. Concept maps: visual mind maps linking related topics and concepts
13. Study streak tracking: consecutive days studied with motivational badges
14. Focus mode: minimize distractions during study sessions (block non-essential notifications)
15. Group quiz battles: challenge classmates to timed quizzes on shared topics
16. Performance analytics: track quiz scores over time, identify weak topics
17. Difficulty rating per topic: self-assess confidence level (Red/Yellow/Green) for each exam topic
18. Study music/ambient sounds: lo-fi beats, rain sounds, library ambiance for concentration
19. Exam day checklist: ID card, stationery, calculator, exam venue, reporting time
20. Post-exam reflection: record what went well, what to improve for next exam
21. Share flashcard decks and quizzes with classmates
22. Community decks: browse and use flashcards created by other students in the same course

## Key Screens

- **Exam Prep Dashboard** — Overview with upcoming exams, study streaks, weak topics, quick actions
- **Flashcard Creator** — Create/edit flashcard decks with card preview
- **Flashcard Study** — Full-screen card flip with swipe gestures and progress bar
- **Quiz Mode** — Timed quiz with question display, answer selection, score at end
- **Study Timer** — Large timer display with session counter, break indicator, ambient sound toggle
- **Study Plan** — Calendar view of AI-generated study schedule with daily topics
- **Revision Checklist** — Subject-organized topic list with completion checkboxes and confidence ratings
- **Exam Countdown** — List of upcoming exams with countdown timers and prep progress
- **Analytics** — Charts showing study hours, quiz performance trends, topic mastery
- **Formula Sheets** — Categorized quick-reference cards with search

## TAJIRI Integration Points

- **CalendarService.createEvent()** — Exam dates and AI-generated study plan sessions sync to TAJIRI calendar; exam countdown events
- **NotificationService + FCMService** — Study session reminders, exam countdown alerts, and streak notifications via push
- **MusicService** — Study playlists from TAJIRI music module for ambient studying during focus sessions
- **ProfileService.getProfile()** — Study streaks, badges, and subject mastery stats display on TAJIRI profile
- **ClipService** — Educational short videos and study tips; video solutions for practice questions
- **EventTrackingService** — Study analytics: track hours studied, quiz scores, topic mastery over time
- **GroupService.createGroup()** — Group quiz battles and shared study sessions via study groups
- **MessageService.sendMessage()** — Share flashcard decks and quiz challenges with classmates
- **class_notes module** — Generate flashcards and quizzes directly from uploaded class notes
- **past_papers module** — Past paper questions feed into quiz mode for realistic NECTA/university practice
- **study_groups module** — Group quiz battles and shared study sessions with synchronized timers
- **newton module** — AI generates questions, explains wrong answers, creates personalized study plans
- **my_class module** — Exam schedule pulled from class timetable
- **timetable module** — Exam schedule overlay synced with timetable view
