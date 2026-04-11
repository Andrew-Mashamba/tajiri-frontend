# Sala (Prayer) — Feature Description

## Tanzania Context

Prayer is central to Christian life in Tanzania. "Sala" means prayer in Swahili. Tanzanian Christians typically pray multiple times daily — morning devotions, mealtime prayers, evening prayers, and special intercessory prayer sessions. Churches hold dedicated prayer meetings (often early morning at 5-6 AM). Prayer chains are common, where church members commit to pray for specific needs in sequence. Jumuiya (small groups) maintain prayer lists that are updated weekly.

Many churches lack a systematic way to track prayer requests and answers. Requests are shared verbally or via WhatsApp groups, making them easy to lose. There is a strong culture of communal intercessory prayer — people believe deeply in the power of others praying for them and want to know when someone is praying for their request.

## International Reference Apps

1. **PrayerMate** — Organized prayer lists, daily prayer sessions, partner with organizations
2. **Echo Prayer** — Prayer request sharing with groups, answered prayer tracking
3. **Pray.com** — Audio devotionals, prayer communities, guided prayer
4. **Abide** — Guided Christian meditation and prayer with audio
5. **Prayer Chain App** — Church prayer chain management with notification system

## Feature List

1. Prayer journal — personal dated entries with scripture references and reflections
2. Prayer requests — create requests with title, description, urgency level, and category
3. Share requests — post to jumuiya group, church, or trusted friends for intercession
4. Prayer chain — sequential prayer commitment where members pray in assigned time slots
5. Pray for others — browse shared requests, tap "I'm praying" to notify the requester
6. Prayer counter — see how many people are praying for a specific request
7. Answered prayers log — mark requests as answered with testimony, share praise reports
8. Daily devotionals — short morning and evening devotional with scripture and prayer prompt
9. Prayer reminders — customizable notification times for prayer throughout the day
10. Guided prayer — audio-guided prayer sessions by topic (gratitude, intercession, repentance)
11. Fasting tracker — log fasting periods with prayer focus, track streak
12. Prayer categories — personal, family, church, nation, health, finances, relationships
13. Prayer partners — pair with another believer for mutual daily prayer
14. Scripture-linked prayers — attach Bible verses to prayer entries
15. Prayer calendar — view prayer history on calendar, see consistency streaks
16. Privacy levels — private (journal only), jumuiya, church-wide, or public

## Key Screens

- **Prayer Home** — today's devotional, active prayer requests, prayer streak indicator
- **Prayer Journal** — chronological journal entries with add button, search
- **Create Prayer Request** — title, description, category, urgency, sharing scope
- **Prayer Request Feed** — shared requests from jumuiya/church with "praying" buttons
- **Prayer Chain View** — timeline showing prayer slots with participant names
- **Answered Prayers** — celebration feed of answered prayers with testimonies
- **Devotional Reader** — daily devotional with scripture, reflection, and prayer prompt
- **Prayer Reminders Settings** — set multiple daily reminder times
- **Fasting Tracker** — active fast with countdown, prayer focus, water reminder option

## TAJIRI Integration Points

- **PostService.createPost()** — share answered prayer testimonies to social feed (opt-in) with #PrayerAnswered hashtag
- **MessageService.sendMessage(), createGroup()** — send prayer encouragements in chat; create dedicated prayer group channels; notify when praying for someone's request
- **GroupService.getMembers()** — prayer requests shared within jumuiya small group; group prayer chain coordination
- **NotificationService + FCMService** — prayer reminders at customizable times, "someone is praying for you" alerts, devotional push notifications
- **CalendarService.createEvent()** — prayer times and fasting periods synced to TAJIRI calendar with reminders
- **LiveUpdateService** — real-time prayer chain updates; live prayer counter showing how many people are praying for a request
- **FriendService.getFriends()** — prayer partner matching within trusted connections; share prayer requests with specific friends
- **Cross-module: Biblia** — link scripture passages to prayer journal entries; daily Bible reading feeds into prayer devotional
- **Cross-module: Jumuiya** — prayer requests shared within small group via GroupService; group prayer chain uses MessageService for coordination
- **Cross-module: Kanisa Langu** — church-wide prayer wall for congregational intercession; prayer requests visible to all church members
