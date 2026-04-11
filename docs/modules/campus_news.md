# Campus News / Habari za Chuo — Feature Description

## Tanzania Context

Information flow within Tanzanian campuses is unreliable and fragmented. Students miss critical deadlines, events, and announcements regularly because there is no single, trustworthy information channel:

- **Notice boards** — The traditional information channel. Physical boards outside department offices, student union offices, and administration blocks. Students must physically walk to check them, and notices are often posted over older ones, torn, or faded
- **WhatsApp forwarding chains** — Campus news spreads through WhatsApp forwards, but accuracy degrades rapidly. By the time a deadline announcement reaches the third group, the date might be wrong
- **Student union (DARUSO/TUSO/etc.)** — Student government organizations post updates on their social media pages, but many students don't follow them. Communication is political and not always trusted
- **University websites** — Most are outdated. UDSM's website may show events from months ago on the homepage. Navigation is poor, and mobile experience is broken
- **SMS from registrar** — Some institutions send bulk SMS for critical announcements (exam dates, fee deadlines). These are rare and easy to miss
- **Word of mouth** — The most common way students learn about events, deadlines, and opportunities. Unreliable and excludes introverted or isolated students
- **Registration deadlines** — Missing registration windows means adding courses late (with penalty fees) or being locked out entirely. This happens to hundreds of students every semester
- **Campus safety** — Emergency communication (power outage, water shortage, security threat) has no standardized channel. Students rely on WhatsApp rumors

The need for a centralized, verified campus information platform is acute.

## International Reference Apps

1. **Campus Labs (Anthology Engage)** — Campus event management, organization directory, news feed, involvement tracking. Used by 1,500+ institutions.
2. **UniNow** — Campus-specific news, dining menus, timetable, campus map, event calendar, push notifications. German university app adapted for each campus.
3. **Guidebook** — Event and campus app builder with schedules, maps, notifications, social features. Conference and university focused.
4. **Corq** — Student event discovery, organization management, campus activity feed, attendance tracking. Social campus life.
5. **Student App (by Ex Libris)** — Personalized campus feed, library, courses, grades, notifications. Integrated student portal.

## Feature List

1. Official announcements feed: verified posts from university administration, departments, and registrar
2. Student union news: DARUSO/TUSO/SUASO updates, election announcements, meeting minutes
3. Event listings: campus events with date, time, venue, organizer, and RSVP
4. Academic deadline reminders: registration open/close, exam dates, fee payment, course add/drop
5. Department-specific news: filter announcements by your department/faculty
6. Club and society activities: posts from registered student organizations
7. Dining menu: daily cafeteria menu with prices (where available)
8. Campus map: interactive map with buildings, lecture halls, offices, cafeterias, ATMs, photocopy shops
9. Emergency alerts: high-priority notifications for safety issues, campus closures, utility outages
10. Push notification categories: choose which types of news trigger notifications
11. Verified sources: only approved accounts can post as official sources, preventing misinformation
12. Comment and react: students can comment on announcements for clarification
13. Save announcements: bookmark important posts for reference
14. Share news: forward announcements to TAJIRI chats or external apps
15. Search archive: find past announcements by keyword or date
16. Job postings: campus employment opportunities (library assistant, lab monitor, etc.)
17. Lost and found: post and find lost items on campus
18. Accommodation notices: hostel allocations, room change announcements, maintenance schedules
19. Health services: campus clinic hours, vaccination campaigns, health advisories
20. Transport updates: campus shuttle schedules, route changes, fuel shortage impact
21. Marketplace bulletin: textbook sales, laptop sales, room subletting (links to TAJIRI shop)
22. Weekly digest: summary of the week's most important announcements

## Key Screens

- **News Feed** — Chronological feed of all campus news with category tabs (Official, Events, Clubs, Urgent)
- **Announcement Detail** — Full announcement with attachments, comments, share button, save option
- **Event Listing** — Event card with date, time, venue, description, RSVP button, add to calendar
- **Events Calendar** — Month view showing all campus events and deadlines
- **Campus Map** — Interactive map with building labels, search, directions, and service locations
- **Categories** — Filter news by type: Academic, Administrative, Events, Sports, Health, Safety
- **Saved** — Bookmarked announcements for quick reference
- **Dining** — Today's cafeteria menu with prices and operating hours
- **Emergency** — Dedicated emergency information page with contacts and current alerts
- **Settings** — Notification preferences by category, institution selection, language

## TAJIRI Integration Points

- **PostService.createPost() / sharePost()** — Share campus news as posts to the TAJIRI feed; promote announcements to wider audience
- **NotificationService + FCMService** — Integrated push notification system with priority levels; emergency alerts bypass mute settings
- **CalendarService.createEvent()** — Campus events and academic deadlines (registration, exams) appear in personal TAJIRI calendar
- **MessageService.sendMessage()** — Share news items directly in TAJIRI chats and class conversations
- **ProfileService.getProfile()** — Institution affiliation (school, university) determines which campus news you see
- **GroupService.getMembers()** — Student organization posts link to their TAJIRI group pages; department-filtered news
- **LiveUpdateService** — Real-time class announcements and emergency broadcasts pushed instantly
- **HashtagService** — Tag news with #UDSM, #UDOM, #CampusLife for discoverability
- **events/ module** — Campus events link to TAJIRI events for RSVP and attendance tracking
- **my_class module** — Class-specific announcements (room changes, lecture cancellations) from campus news
- **timetable module** — Exam dates and schedule changes sync to timetable view
- **fee_status module** — Fee deadline announcements link to fee payment module
- **study_groups module** — Academic event announcements (workshops, seminars) shared with relevant study groups
