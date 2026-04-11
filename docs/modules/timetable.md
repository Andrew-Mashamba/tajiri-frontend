# Timetable / Ratiba — Feature Description

## Tanzania Context

Timetable management is one of the biggest daily frustrations for Tanzanian students. At the start of each semester, universities like UDSM, UDOM, and ARU post timetables on physical notice boards outside department offices. Students crowd around, take blurry photos on their phones, and share them on WhatsApp. These photos become the primary reference for the entire semester. The problems multiply:

- Timetable changes mid-semester are common (lecturer unavailable, room double-booked) and communicated only via notice board or WhatsApp rumor
- Room numbers use confusing internal codes (e.g., "NB 101" at UDSM means New Block room 101) that new students can't decode
- Students taking electives across departments must manually merge multiple timetables
- Exam timetables are separate documents, posted weeks before exams, causing last-minute panic
- Evening program students and regular students share rooms, causing conflicts
- No way to find free rooms for self-study or group work
- Many students still use paper or mental memory for their daily schedule

## International Reference Apps

1. **My Study Life** — Weekly/daily timetable view, recurring classes, exam schedule, task integration, rotation schedules. Clean and student-focused.
2. **TimeTree** — Shared calendar with color coding, event categories, memo attachments, widget support. Great for group scheduling.
3. **iStudiez Pro** — Semester-based scheduling, GPA tracking, assignment integration, instructor details per class. Premium student planner.
4. **Timetable (Gabriele Cozzi)** — Simple weekly grid, color-coded subjects, widget, notification reminders. Lightweight and fast.
5. **UniDays / Student Beans** — While primarily discount apps, their schedule features show how student-centric UX works.

## Feature List

1. Weekly view showing Monday-Saturday grid (Tanzanian universities often have Saturday classes)
2. Daily view with detailed time blocks including room, lecturer, and subject
3. Add classes manually: subject name, course code, lecturer, room number, building
4. Color coding by subject for visual clarity (auto-assign or custom pick)
5. Recurring schedule support (same class every Monday and Wednesday)
6. Building/room location descriptions with campus landmarks ("NB 101 — New Block, ground floor, near cafeteria")
7. Exam schedule overlay — toggle exam dates on top of regular timetable
8. Free period finder: identify gaps between classes for study or rest
9. Share entire timetable with classmates via link or image export
10. Import timetable from class (when CR sets up class timetable, members auto-receive)
11. Home screen widget showing next class with countdown timer
12. Push notification 15 minutes before each class (configurable: 5/10/15/30 min)
13. Semester management: create multiple semesters, switch between them
14. Room change alerts: CR or lecturer can push room/time changes to all class members
15. Clash detection: warn when two classes overlap in time
16. Break time display: show lunch breaks, prayer times
17. Today view: simplified card showing only today's classes with current/next highlighting
18. Export timetable as image (for sharing on WhatsApp) or PDF
19. Dark mode support matching TAJIRI's design system
20. Offline access: timetable cached locally, works without internet
21. Multi-campus support for students attending classes at different campuses (e.g., UDSM Mlimani vs Muhimbili)
22. Add custom events: tutorials, labs, office hours, study sessions

## Key Screens

- **Week View** — 6-day grid (Mon-Sat) with colored class blocks, swipe between weeks
- **Day View** — Vertical timeline for selected day with detailed class cards
- **Add/Edit Class** — Form with subject, lecturer, room, building, time, recurrence pattern
- **Semester Manager** — List of semesters, create new, set active, archive old
- **Exam Schedule** — Dedicated exam timetable with date, time, venue, subject
- **Free Rooms** — Search available rooms by time slot (if campus data available)
- **Today Widget** — Compact card for home screen showing current/next class
- **Share Timetable** — Preview and export as image or share link
- **Settings** — Notification timing, week start day, default semester, theme

## TAJIRI Integration Points

- **CalendarService.createEvent()** — Timetable entries sync to personal TAJIRI calendar; exam dates, class times, and schedule changes auto-create calendar events
- **NotificationService + FCMService** — Class reminders (15/30 min before), room change alerts, and exam schedule notifications via push
- **MessageService.sendMessage()** — Tap lecturer name to message them directly on TAJIRI; room change announcements sent to class chat
- **GroupService.getMembers()** — Timetable auto-populates from class membership; CR-set timetables push to all group members
- **ProfileService.getProfile()** — Current semester schedule visible on profile (optional privacy setting); pull education data for semester context
- **LiveUpdateService** — Real-time class announcements and room changes pushed instantly to timetable
- **my_class module** — Timetable auto-populates from class enrollment; CR manages shared timetable for the class
- **study_groups module** — Free periods identified for study group session scheduling
- **campus_news module** — Room change and schedule announcements link to timetable updates
- **exam_prep module** — Exam schedule overlay pulled from exam countdown data
