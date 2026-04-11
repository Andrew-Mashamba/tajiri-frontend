# Biblia (Bible) — Feature Description

## Tanzania Context

The Bible is the most widely read book in Tanzania. The primary Swahili translation is the SUV (Swahili Union Version), used across most Protestant denominations. Catholics often use the Biblia Habari Njema (Good News Bible in Swahili). English translations (NIV, KJV, ESV) are popular among educated urban Tanzanians. Many rural churches still rely on printed Bibles, and internet connectivity issues make offline access critical.

Bible study is deeply communal — small groups (jumuiya) meet weekly to discuss scripture. Pastors often assign weekly readings. Young people increasingly want digital Bible access on their phones but most global Bible apps lack good Swahili audio Bible options and culturally relevant reading plans.

## International Reference Apps

1. **YouVersion Bible App** — 2,000+ translations, reading plans, verse of the day, audio, community features
2. **Bible Gateway** — Robust search, parallel translations, commentaries, cross-references
3. **Logos Bible** — Advanced study tools, original language, word studies
4. **Bible.is (Faith Comes By Hearing)** — Audio Bibles in 1,800+ languages including Swahili
5. **Olive Tree Bible** — Offline-first, study notes, highlighting, resource library

## Feature List

1. Full Bible text — Swahili SUV and Biblia Habari Njema as primary translations
2. English translations — NIV, KJV, ESV available as secondary
3. Parallel reading — view two translations side by side
4. Verse of the day — daily verse with Swahili and English, shareable as image card
5. Audio Bible — full audio narration in Swahili (SUV), playback speed control
6. Reading plans — curated plans (e.g., Bible in a Year, Gospels in 30 Days, Psalms for Comfort)
7. Custom reading plans — create personal plans or follow pastor-assigned plans
8. Bookmarks — save specific verses with custom labels
9. Highlights — color-code verses (5 highlight colors)
10. Notes — add personal study notes to any verse
11. Search — full-text search across translations with filters (Old/New Testament, book)
12. Share verses — share as text, image card, or to TAJIRI feed/messages
13. Cross-references — tap to navigate linked verses
14. Offline mode — download entire translations for offline reading and audio
15. History — recently read chapters and search history
16. Daily devotionals — short morning/evening devotional tied to scripture
17. Jumuiya integration — share passages directly to jumuiya group chat
18. Font and display settings — adjustable font size, night mode, serif/sans-serif

## Key Screens

- **Bible Home** — verse of the day card, continue reading, active reading plan progress
- **Bible Reader** — chapter view with verse numbers, tap-to-select for highlight/note/share
- **Book Selector** — grid of all 66 books grouped by OT/NT, then chapter picker
- **Search Results** — verse results with context snippets, filter controls
- **Reading Plans Browser** — plan cards with duration, description, start button
- **Reading Plan Tracker** — daily checklist with streak counter
- **Bookmarks & Highlights** — organized list with color filters
- **Audio Player** — persistent mini-player for Bible audio, chapter navigation
- **Verse Share Card** — styled verse image with translation attribution

## TAJIRI Integration Points

- **PostService.createPost()** — share verse cards to TAJIRI social feed with #BibleVerse hashtag; friends can react and comment
- **StoryService.createStory()** — post daily verse of the day as a story with styled verse image card
- **MessageService.sendMessage()** — send verses directly in chat conversations or jumuiya group chat
- **FriendService.getFriends()** — share verses with friends list; suggest Bible reading partners
- **NotificationService + FCMService** — daily verse push notification, reading plan reminders, devotional alerts
- **HashtagService** — #BibleVerse, #VerseOfTheDay for discoverable verse posts
- **Cross-module: Sala (Prayer)** — daily Bible reading feeds into prayer journal entries; scripture-linked prayers reference Bible passages
- **Cross-module: Jumuiya** — weekly Bible study passages linked from jumuiya schedule via GroupService; study guides shared in group chat via MessageService
- **Cross-module: Kanisa Langu** — church-assigned reading plans synced to Bible module; pastor-curated study series
- **Cross-module: Ibada (Worship)** — worship songs tagged with scripture references link back to Bible reader via MusicService
- **Cross-module: Huduma (Sermons)** — tap scripture references in sermon notes to open Bible passage directly
- **Offline Support** — full offline capability via LocalStorageService for downloaded translations and audio
