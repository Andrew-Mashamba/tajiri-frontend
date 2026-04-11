# My Class / Darasa Langu — Feature Description

## Tanzania Context

In Tanzanian universities and colleges, class management is almost entirely informal. When students join a new semester, they rely on WhatsApp groups created by class representatives (CR) to share information. Finding the CR's number itself is a challenge — students ask around, check notice boards, or wait until the first lecture. Lecturer contact information is scattered: some post office hours on doors, others share phone numbers verbally. Class rosters don't exist digitally for students — you only know your classmates by face recognition after weeks of lectures.

Key pain points:
- WhatsApp groups become chaotic with 200+ members, mixing social chat with important announcements
- New students struggle to find their class group or know who the CR is
- No centralized place to see all classmates, especially in large programs (UDSM BA Education can have 500+ students)
- Lecturer office hours and contact info are hard to find
- Class photos and memories are scattered across individual phones
- When a CR changes (elections), information transfer is messy

## International Reference Apps

1. **Google Classroom** — Class creation with join codes, assignment distribution, announcement board, material sharing. Clean teacher-student hierarchy.
2. **ClassDojo** — Class roster with student profiles, behavior tracking, parent communication, class story (photo/video feed). Strong community feel.
3. **Remind** — Class-specific messaging, announcement broadcasts, scheduled messages, translation support. Simple and focused.
4. **Schoology** — Course management, attendance tracking, gradebook, resource library. Full LMS features.
5. **Edmodo** — Social-learning platform with class groups, polls, quizzes, assignment submission.

## Feature List

1. Create a class with name, course code, semester, and year (e.g., "CS 201 - Data Structures, Semester 1, 2026")
2. Generate unique class join code (6-character alphanumeric) for easy sharing
3. Class roster displaying all members with profile photos, phone numbers (optional), and roles
4. Designate class roles: Class Representative (CR), Assistant CR, Subject Rep, Secretary
5. Lecturer/teacher profile cards with name, department, office location, office hours, email, and phone
6. Class announcements board — only CR and lecturers can post, all can comment
7. Shared class timetable visible to all members
8. Class photo album — members contribute photos from lectures, events, field trips
9. Attendance tracker with QR code check-in (CR generates code, students scan)
10. Class directory with search and filter by name
11. Academic year/semester management — archive old classes, carry forward to next semester
12. Class statistics: total enrolled, attendance rate, gender ratio
13. Export class roster to PDF/Excel for official purposes
14. Pin important messages (exam dates, room changes, makeup classes)
15. Emergency broadcast: urgent notifications that bypass mute settings
16. Class document repository for shared syllabi, reading lists, and handouts
17. Invite members via WhatsApp share, SMS, or TAJIRI username
18. Multi-class support — students can be in multiple classes simultaneously
19. Class representative election/voting feature
20. Notification preferences per class (all, announcements only, muted)

## Key Screens

- **My Classes List** — Grid/list of all joined classes with unread badge counts
- **Class Home** — Overview with announcements, quick actions, member count, next class info
- **Class Roster** — Scrollable member list with roles highlighted, search bar
- **Join Class** — Enter class code or scan QR to join
- **Create Class** — Form with course details, semester, department
- **Class Settings** — Manage roles, permissions, class info, leave/archive class
- **Lecturer Directory** — Cards showing all lecturers for the class with contact info
- **Attendance View** — Calendar view of attendance records, percentage stats
- **Class Album** — Grid of shared photos and videos

## TAJIRI Integration Points

- **GroupService.createGroup()** — Each class auto-creates a TAJIRI group with integrated chat; class = group with auto-created conversation
- **GroupService.joinGroup() / getMembers()** — Join class via code triggers group join; roster powered by group membership list
- **MessageService.createGroup() / sendMessage()** — Class announcements and follow-up discussions use TAJIRI messaging infrastructure (class chat)
- **PeopleSearchService.search(school:)** — Find classmates by institution; discover students in the same program or department
- **ProfileService.getProfile()** — Class membership shows on student profiles ("Currently studying CS 201"); pull education data (school, university, course)
- **CalendarService.createEvent()** — Class schedule, exam dates, and deadlines sync to personal TAJIRI calendar
- **NotificationService + FCMService** — Class reminders, room changes, and CR announcements delivered via push notifications
- **ContributionService** — Collect class contributions (printing fees, field trip funds) via M-Pesa
- **PostService.createPost()** — Share class achievements, announcements, and updates to the TAJIRI feed
- **PhotoService.uploadPhoto()** — Class photo album; members contribute photos from lectures, events, and field trips
- **events/ module** — Class events (study sessions, outings, field trips) create TAJIRI events with auto-invite
- **timetable module** — Classes sync with the timetable for schedule display; CR-set timetables push to all members
- **class_notes module** — Notes shared in class link to the class notes repository
- **study_groups module** — Create study groups from class membership; class-linked groups via GroupService
- **HashtagService** — Class-specific hashtags (#CS201, #UDSM) for discoverability
