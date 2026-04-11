# Study Groups / Vikundi vya Kusoma — Feature Description

## Tanzania Context

Study groups ("vikundi vya kusoma" or "mabesheni") are a cornerstone of Tanzanian student academic culture. The tradition is deeply rooted:

- **Hostel-based groups** — Students in university hostels naturally form study groups with roommates and neighbors. At UDSM Mabibo hostels, you'll find groups studying under corridor lights when rooms are too hot or during power outages
- **Tree and bench groups** — Many campuses have iconic study spots: specific trees, benches, or outdoor areas where groups gather. These spots become associated with particular courses ("the Accounting tree" at IFM)
- **Subject expertise sharing** — Tanzanian students strongly believe in collaborative learning. A student strong in Mathematics helps others, and in return gets help with English or History. This barter system of knowledge is culturally valued
- **Exam season intensity** — Study groups peak 2-3 weeks before exams. Students who barely talked all semester suddenly form tight study units. Late-night sessions (sometimes until 3-4 AM) are common
- **WhatsApp coordination** — Groups are formed via WhatsApp but coordination is painful: finding a time everyone is free, agreeing on a location, deciding what topics to cover, sharing materials beforehand
- **Unequal participation** — A common complaint is "free riders" who join groups but don't contribute. No mechanism exists to track who actually participates
- **Rural vs. urban gap** — Students in rural campuses (e.g., SUA in Morogoro) have fewer study resources and rely more heavily on peer groups than their Dar es Salaam counterparts
- **Gender dynamics** — Mixed-gender study groups can face cultural friction. Women-only study groups are common, especially in conservative areas
- **Library competition** — Campus library study rooms are booked out during exams. Groups fight for space

## International Reference Apps

1. **StudyBlue** — Flashcard sharing, study groups, course materials, class search, progress tracking. Peer learning platform.
2. **Brainly** — Community Q&A, expert answers, photo question upload, group collaboration. 350M+ users globally. Homework help community.
3. **Discord (Study Servers)** — Voice/text channels, screen sharing, study bots (Pomodoro, music), role management. Massive adoption among Gen Z students.
4. **Fiveable** — Live study sessions, study guides, practice questions, student community. AP exam focused but excellent group study model.
5. **Quizlet Live** — Real-time collaborative quiz games, team formation, competitive learning. Gamification of group study.

## Feature List

1. Create study group: name, subject, description, semester, maximum members
2. Join study groups: browse available groups by subject, institution, or invite code
3. Group chat: integrated TAJIRI messaging for group communication
4. Schedule study sessions: set date, time, duration, location (physical or virtual), topic
5. Session calendar: view all upcoming and past study sessions
6. Shared notes: group members upload and access shared study materials
7. Study session check-in: members confirm attendance, building reliability scores
8. Find study partners nearby: location-based discovery of students studying the same subject
9. Group quiz battles: competitive quizzes where group members challenge each other
10. Study timer: synchronized Pomodoro timer for group sessions (everyone starts/stops together)
11. Contribution tracker: track who shares notes, asks questions, answers questions, attends sessions
12. Study streak: consecutive days the group has been active, with milestone badges
13. Group leaderboard: rank members by participation score
14. Role assignment: Group Leader, Note Taker, Quiz Master, Scheduler
15. Voice/video study room: start a virtual study session with screen sharing
16. Whiteboard: shared digital whiteboard for explaining concepts
17. Topic checklist: list of topics to cover before exam, track group progress
18. Request to join: group leaders approve or deny membership requests
19. Group size limits: set maximum members to keep groups effective (recommended 4-8)
20. Archive groups: end-of-semester archiving with access to shared materials
21. Group recommendations: AI suggests groups based on your courses and study patterns
22. Study statistics: total hours studied as a group, sessions completed, topics covered

## Key Screens

- **Study Groups Home** — My groups list with next session info, discover new groups section
- **Group Detail** — Overview with members, next session, shared notes, chat preview, stats
- **Create Group** — Form with name, subject, description, max members, privacy (open/invite-only)
- **Discover Groups** — Browse/search available groups with filters for subject, institution, size
- **Schedule Session** — Set date, time, location, topic, send invites to all members
- **Session View** — Active session with timer, attendance check-in, topic checklist, notes
- **Group Chat** — Messaging interface within the study group context
- **Shared Materials** — Files, notes, and resources uploaded by group members
- **Leaderboard** — Member rankings by contribution, attendance, and quiz performance
- **Find Partners** — Map/list view of nearby students studying the same subject

## TAJIRI Integration Points

- **GroupService.createGroup() / joinGroup()** — Study group = TAJIRI group; create, join, and manage groups with roles and membership
- **MessageService.sendMessage() / createGroup()** — Group chat powered by TAJIRI messaging infrastructure; integrated conversation per study group
- **CalendarService.createEvent()** — Study sessions sync to TAJIRI calendar; schedule sessions with date, time, location, and topic
- **NotificationService + FCMService** — Session reminders, new material alerts, and quiz challenge invites via push notifications
- **ProfileService.getProfile()** — Study group membership, participation stats, and contribution badges displayed on profile
- **FriendService.getFriends() / getMutualFriends()** — Find study partners among friends and mutual connections studying the same subject
- **PeopleSearchService.search(school:)** — Discover students at the same institution studying the same course
- **PhotoService.uploadPhoto()** — Share note photos and whiteboard captures within the group
- **PostService.createPost()** — Share study group achievements and open session invitations to the feed
- **my_class module** — Study groups created from class membership; class-linked groups
- **class_notes module** — Shared notes within groups link to the class notes repository
- **exam_prep module** — Group quiz battles use exam prep quiz engine; shared study sessions
- **timetable module** — Study sessions appear in personal timetable during free periods
- **newton module** — AI can join group sessions to answer questions in real-time
- **events/ module** — Study sessions posted as semi-public TAJIRI events for open groups
- **kikoba/ module** — Student savings groups for shared academic expenses (textbooks, printing)
