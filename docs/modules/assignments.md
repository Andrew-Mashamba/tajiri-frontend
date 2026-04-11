# Assignments / Kazi — Feature Description

## Tanzania Context

Assignment management in Tanzanian education is chaotic. Lecturers announce assignments verbally in class, write them on the whiteboard, or post them on departmental notice boards. Students who miss class rely on WhatsApp messages from classmates — often getting incomplete or garbled instructions. Common scenarios:

- A lecturer says "submit by Friday" but doesn't specify which Friday, the format, or submission method
- Group assignments are a nightmare: coordinating 4-5 students across different schedules using WhatsApp voice notes and shared Word docs via email
- Submission is often physical: printed papers stapled and dropped in a box outside the lecturer's office. Some accept email, some want both
- Students track deadlines mentally or in small notebooks. Many forget until the night before
- HESLB loan students face extra pressure — poor grades mean losing funding
- Continuous assessment (CA) typically counts 40-60% of the final grade, making assignments critical
- Plagiarism is rampant because students share work freely. Some lecturers use Turnitin, most don't
- Late submission policies vary wildly: some lecturers accept late work, others give zero with no appeal

## International Reference Apps

1. **Google Classroom** — Assignment creation with due dates, file attachments, rubrics, private comments, grade return. Industry standard for education.
2. **My Study Life** — Task management with subject linking, priority levels, due dates, completion tracking. Student-focused simplicity.
3. **Todoist** — General task management with projects, labels, priorities, recurring tasks, natural language dates. Great UX model.
4. **Microsoft Teams (Education)** — Assignment distribution, submission, grading, feedback loop, plagiarism detection. Enterprise-grade.
5. **Turnitin** — Submission with originality checking, feedback studio, rubric-based grading. Academic integrity focus.

## Feature List

1. Create assignment with title, description, subject/course, and due date/time
2. Subject tagging: link assignment to a specific class from My Class module
3. Priority levels: Low (worth few marks), Medium, High (major CA component), Critical (exam-equivalent)
4. Due date with countdown timer showing days/hours remaining
5. Status tracking: Not Started, In Progress, Submitted, Graded, Late
6. File attachments: attach assignment brief (PDF, image of whiteboard, voice recording of instructions)
7. Submission attachments: attach your completed work (documents, photos of handwritten work, code files)
8. Group assignment support: create group, assign members, track individual contributions
9. Smart reminders: 1 week, 3 days, 1 day, 12 hours, 2 hours before deadline (configurable)
10. Grade recording: enter marks received, auto-calculate running CA average
11. Late submission flagging: visual indicator when submitted after deadline
12. Recurring assignments: for weekly lab reports, reading responses, etc.
13. Assignment calendar: month view showing all deadlines across subjects
14. Share assignment details with classmates (forward to class chat)
15. Checklist within assignment: break large assignments into sub-tasks
16. Photo of handwritten assignment brief: capture whiteboard/notice board with camera
17. Voice memo: record lecturer's verbal instructions for reference
18. Submission confirmation: timestamp proof of when you submitted
19. Performance analytics: track assignment completion rate, average grade by subject
20. Archive completed assignments by semester
21. Search and filter: by subject, status, priority, date range
22. Offline access: view assignment details without internet

## Key Screens

- **Assignment Dashboard** — Overview showing upcoming (sorted by urgency), overdue (red), and recently completed
- **Create Assignment** — Form with title, description, subject picker, due date, priority, attachments
- **Assignment Detail** — Full view with description, attachments, status, submission area, grade
- **Calendar View** — Month calendar with deadline dots, tap date to see assignments due
- **Group Assignment** — Member list, task delegation, group chat link, submission coordinator
- **Grades Summary** — Table of all graded assignments by subject with running average
- **Subject Filter** — View assignments filtered by specific course/subject
- **Reminders Settings** — Configure notification preferences per assignment or globally

## TAJIRI Integration Points

- **CalendarService.createEvent()** — Assignment deadlines auto-sync to personal TAJIRI calendar; due dates create calendar events with reminders
- **NotificationService + FCMService** — Smart deadline reminders (1 week, 3 days, 1 day, 12 hours, 2 hours before) via push notifications
- **PhotoService.uploadPhoto()** — Submit photos of handwritten assignments, capture whiteboard instructions, attach assignment brief images
- **MessageService.sendMessage()** — Share assignment details and discuss in class chat channels
- **GroupService.createGroup()** — Group assignments auto-suggest forming a study group; coordinate group members
- **PostService.createPost()** — Share completed assignment achievements or helpful resources to the feed
- **WalletService.deposit(amount, provider:'mpesa')** — Pay for printing/binding services for physical submissions
- **VideoUploadService** — Record and upload video presentations or project demonstrations
- **my_class module** — Assignments link to specific classes; CR can create assignments visible to all class members
- **class_notes module** — Link relevant lecture notes to assignments for reference while working
- **newton module** — "Help me understand" button opens Newton AI in Socratic mode (guides, doesn't solve)
- **exam_prep module** — CA grades from assignments feed into grade prediction and exam preparation
- **results module** — Assignment grades contribute to running CA average and GPA calculation
