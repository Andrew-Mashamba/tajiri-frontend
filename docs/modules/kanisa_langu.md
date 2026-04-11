# Kanisa Langu (My Church) — Feature Description

## Tanzania Context

"Kanisa Langu" means "My Church" in Swahili. Churches are the center of community life for most Tanzanian Christians. A typical Tanzanian church manages announcements through paper bulletins, WhatsApp groups, and verbal notices during services. Many churches have thousands of members but lack any digital infrastructure for communication, event coordination, or member management.

The Catholic Church in Tanzania is organized into parishes with jumuiya ndogo (small Christian communities), each requiring coordination for meetings, contributions, and activities. Protestant churches — especially fast-growing Pentecostal churches — need tools for managing multiple services, branches, youth groups, women's groups (wanawake), and men's fellowships. Sermons are often recorded on personal phones and shared informally via WhatsApp.

## International Reference Apps

1. **Church Center (Planning Center)** — Church member app with events, groups, giving, directory
2. **Subsplash** — Custom church apps with sermons, push notifications, giving
3. **Faithlife / Logos Church** — Church management with integrated Bible study tools
4. **YouVersion Events** — Live sermon notes synced with pastor's presentation
5. **Tithe.ly Church App** — Church app builder with media, giving, and communication tools

## Feature List

1. Church profile page — name, denomination, location (map), service times, pastor info, photos
2. Church announcements — push notifications from church leadership to members
3. Events calendar — church events with RSVP, reminders, and location details
4. Sermon library — audio/video recordings organized by date, series, speaker, topic
5. Live sermon notes — follow along with pastor's outline during service
6. Member directory — searchable list of church members (privacy-controlled)
7. Church groups — list of all church groups (youth, women, men, choir, ushers, etc.)
8. Giving integration — direct link to Fungu la Kumi for church-specific giving
9. Volunteer signup — sign up for service roles (usher, greeter, Sunday school, worship team)
10. Service schedule — weekly service roster showing who is serving where
11. Prayer wall — church-wide prayer requests visible to all members
12. Visitor welcome — first-time visitor check-in with welcome packet info
13. Church news feed — posts from church leadership and ministry leaders
14. Multi-branch support — churches with multiple campuses can manage under one profile
15. Church contact — direct message to church office or pastoral team
16. Attendance tracking — optional check-in for service attendance records

## Key Screens

- **Church Home** — banner image, next service countdown, latest announcement, quick actions
- **Announcements Feed** — chronological list with push notification badges
- **Events Calendar** — month/list view with event cards, RSVP buttons
- **Sermon Library** — searchable grid/list with audio/video player
- **Member Directory** — alphabetical list with search, tap for profile
- **Groups List** — all church groups with member count, join button
- **Volunteer Board** — available service opportunities with sign-up
- **Church Settings** — notification preferences, privacy settings, leave church

## TAJIRI Integration Points

- **GroupService.createGroup(), joinGroup(), getMembers()** — each church is a TAJIRI group; member directory with roles (pastor, deacon, elder, usher); join/leave church group; manage multiple church branches under one group
- **MessageService.sendMessage(), createGroup()** — church group chats for announcements; pastoral messaging; ministry-specific channels (youth, women, men, choir)
- **PostService.createPost()** — church news feed posts visible to members in their social feed; church leadership announcements
- **CalendarService.createEvent()** — church service times, events, and volunteer schedules synced to personal TAJIRI calendar
- **ContributionService.createCampaign(), donate()** — church building fund campaigns; giving campaigns with congregation progress tracking
- **NotificationService + FCMService** — push announcements from church leadership, event reminders, volunteer schedule alerts
- **LivestreamService.createStream()** — live stream Sunday services and special church events
- **PhotoService.uploadPhoto()** — church profile photos, event photo galleries, ministry photos
- **VideoUploadService** — sermon video recordings stored and accessible from church profile
- **LocationService.getRegions(), getDistricts()** — church location on map; multi-branch location management
- **events/ module** — church events (Easter, Christmas, crusades, conferences) appear in TAJIRI events feed
- **Cross-module: Fungu la Kumi** — giving campaigns and tithe payments linked to specific church via WalletService
- **Cross-module: Jumuiya** — small groups within the church with meeting schedules via GroupService
- **Cross-module: Huduma** — sermon recordings accessible from church profile via MusicService and ClipService
- **Cross-module: Ibada** — worship team playlists and song selections for services via MusicService
- **Cross-module: Tafuta Kanisa** — church discovery leads to Kanisa Langu profile for joining via LocationService
