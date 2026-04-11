# Huduma (Sermons) — Feature Description

## Tanzania Context

"Huduma" in Swahili means "ministry" or "service" and is commonly used to refer to sermon/preaching sessions. Sermons are the centerpiece of Tanzanian church services, often lasting 45-90 minutes. Many Tanzanians listen to sermons throughout the week — on radio, TV, and increasingly on phones via WhatsApp audio files.

Popular Tanzanian preachers like Bishop Kakobe, Pastor Josephat Gwajima, and Bishop Method Kilaini have massive followings. Sermon recordings are widely shared but in a disorganized manner — forwarded as WhatsApp voice notes or uploaded to YouTube without proper cataloging. There is no centralized Swahili-first platform for sermon discovery, organized by topic, speaker, or Bible book. Rural Christians who miss Sunday service particularly need access to quality sermon content.

## International Reference Apps

1. **SermonAudio** — Largest sermon library with search by speaker, topic, scripture, date
2. **Subsplash** — Church media platform with sermon hosting and podcast distribution
3. **Gospel Coalition / Desiring God** — Curated sermon content with study resources
4. **Podcast apps (Apple/Spotify)** — Sermon podcasts with subscription and offline download
5. **Right Now Media** — Video Bible study and sermon content library ("Netflix of Bible study")

## Feature List

1. Sermon recordings — upload and browse audio/video sermons
2. Speaker profiles — pastor/preacher bio, photo, church affiliation, all sermons listed
3. Series organization — group sermons into thematic series (e.g., "Marriage," "Faith & Finance")
4. Topic categorization — browse by topic: salvation, marriage, parenting, finances, prayer, healing
5. Scripture-linked — sermons tagged by Bible book/chapter for easy cross-reference
6. Search — full-text search by title, speaker, topic, scripture reference
7. Audio player — background playback, speed control (0.5x-2x), sleep timer
8. Video player — full-screen video with quality selection for data savings
9. Download for offline — save sermons locally for areas with poor connectivity
10. Sermon notes — text notes attached to specific sermons, synced across devices
11. Bookmark timestamps — mark specific moments in a sermon for later reference
12. Share sermons — share to TAJIRI feed, messages, or external (WhatsApp, social media)
13. Follow speakers — get notified when favorite preachers upload new sermons
14. Recommended sermons — personalized suggestions based on listening history
15. Sermon transcripts — auto-generated text transcripts (Swahili and English)
16. Sermon of the day — featured sermon on the home screen daily
17. Church upload portal — churches can upload and manage their sermon library

## Key Screens

- **Sermons Home** — featured sermon, recently added, trending, continue listening
- **Browse/Discover** — filter by topic, speaker, series, scripture, denomination
- **Speaker Profile** — photo, bio, church, sermon count, follow button, sermon list
- **Sermon Player** — audio/video player with notes panel, bookmark, share, download
- **Series View** — ordered list of sermons in a series with progress tracking
- **Search Results** — sermon cards with speaker, duration, date, topic tags
- **My Library** — downloaded sermons, bookmarked, recently played, followed speakers
- **Sermon Notes** — personal notes viewer/editor linked to specific sermon

## TAJIRI Integration Points

- **LivestreamService.createStream()** — live stream church services and sermon sessions in real-time
- **VideoUploadService** — upload sermon video recordings with metadata (speaker, topic, scripture, series)
- **MusicService** — sermon audio recordings stored and streamed; worship songs from same service linked to sermon
- **ClipService** — create short sermon clips (1-3 minutes) for sharing as highlights or teasers
- **PostService.createPost(), sharePost()** — share sermon clips or recommendations to social feed; sermon of the day posts
- **MessageService.sendMessage()** — send sermon links directly in chat conversations
- **NotificationService + FCMService** — new sermon alerts from followed speakers and home church; sermon series update push notifications
- **CalendarService.createEvent()** — sermon series schedules synced to personal calendar
- **HashtagService** — #Sermon, #BibleTeaching for discoverable sermon content
- **Cross-module: Kanisa Langu** — sermons automatically appear in church profile sermon library via GroupService
- **Cross-module: Biblia** — tap scripture references in sermon to open Bible passage directly
- **Cross-module: Ibada** — worship songs from the same service linked to sermon via MusicService
- **Cross-module: Jumuiya** — assign sermons for group discussion and reflection via MessageService.sendMessage()
