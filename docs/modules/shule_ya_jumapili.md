# Shule ya Jumapili (Sunday School) — Feature Description

## Tanzania Context

"Shule ya Jumapili" means "Sunday School" in Swahili. Sunday School is a vital ministry in virtually every Tanzanian church, serving children from age 3 through teenage years. Classes are typically divided by age group: watoto wadogo (young children, 3-6), watoto wakubwa (older children, 7-12), and vijana (teens, 13-17). In many churches, Sunday School runs simultaneously with the main adult service.

Teachers are usually volunteers from the congregation with minimal training. They often lack structured curriculum — many improvise lessons weekly or rely on outdated printed materials. There is a significant shortage of age-appropriate, culturally relevant, Swahili-language Sunday School materials. Parents often have no visibility into what their children are learning, and attendance tracking is entirely manual (paper registers that get lost).

## International Reference Apps

1. **Gospel Project (Lifeway)** — Chronological Bible curriculum for all ages with multimedia
2. **Orange Kids Ministry** — Curriculum, leader training, parent engagement tools
3. **Sunday School App (Church of God)** — Digital lessons, activities, memory verses
4. **Bible App for Kids (YouVersion)** — Interactive Bible stories with animations for children
5. **Minno** — Christian kids content streaming with discussion guides for parents

## Feature List

1. Lesson plans — structured weekly lessons by age group with objectives and activities
2. Curriculum library — browse curricula organized by series, theme, and age level
3. Teacher resources — lesson guides, visual aids, craft templates, song suggestions
4. Activity sheets — printable/digital coloring pages, puzzles, and worksheets
5. Memory verses — weekly verse with gamified memorization tracker per child
6. Attendance tracking — digital register with check-in by class and date
7. Teacher scheduling — assign teachers to classes and dates, manage rotation
8. Parent notifications — weekly summary sent to parents: lesson topic, memory verse, activities
9. Progress tracking — child's attendance, memory verse completion, participation badges
10. Story animations — simple animated Bible stories for young children (Swahili narration)
11. Song library — children's worship songs with lyrics and actions (Swahili and English)
12. Certificate generation — completion certificates for series/programs
13. Volunteer management — recruit and train Sunday School teachers
14. Training modules — short video/text courses for teacher development
15. Safe check-in — secure child check-in/check-out with parent verification
16. Special events — VBS (Vacation Bible School), holiday programs, children's camps

## Key Screens

- **Sunday School Home** — this week's lesson overview, teacher schedule, quick attendance
- **Lesson Viewer** — structured lesson with sections: opening, Bible story, discussion, activity, closing
- **Curriculum Browser** — series cards with age group, duration, description, preview
- **Attendance Dashboard** — class list with check-in buttons, historical view
- **Memory Verse Tracker** — verse display, practice mode, child progress list
- **Activity Library** — downloadable/viewable worksheets and craft instructions
- **Teacher Dashboard** — my classes, upcoming lessons, assigned dates, resources
- **Parent View** — child's progress, attendance, this week's lesson summary
- **Child Profile** — name, age group, attendance history, achievements

## TAJIRI Integration Points

- **CalendarService.createEvent()** — class schedules, special events (VBS, camps), and teacher assignment rotation synced to TAJIRI calendar
- **MessageService.sendMessage(), createGroup()** — teacher-parent communication channel; parent notifications with weekly lesson summary, memory verse, and activities
- **NotificationService + FCMService** — parent lesson summaries pushed weekly, teacher schedule reminders, attendance alerts
- **PostService.createPost()** — share Sunday School event photos to social feed (with parental consent protocols)
- **PhotoService.uploadPhoto()** — class activity photos, event documentation, craft project galleries
- **Cross-module: Kanisa Langu** — Sunday School embedded as a ministry within church profile via GroupService; teacher volunteer signup
- **Cross-module: Biblia** — memory verses and lesson scriptures link directly to Bible reader
- **Cross-module: Ibada** — children's worship song playlists linked from music module via MusicService
- **Cross-module: my_family/** — children's spiritual progress (attendance, memory verses, badges) visible in family module
