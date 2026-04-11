# Maulid (Maulid Events) — Feature Description

## Tanzania Context

Maulid (also spelled Mawlid) celebrates the birth of Prophet Muhammad (peace be upon him), observed on 12 Rabi ul-Awwal in the Hijri calendar. In Tanzania, Maulid is one of the most important and festive Islamic celebrations, particularly in coastal regions and Zanzibar. The celebration has a distinct East African character — communities gather for Maulid recitations (qaswida), feasting, and communal prayers.

Qaswida (Swahili Islamic poetry/songs) are the centerpiece of Maulid celebrations in Tanzania. Groups like Kijitonyama Muslim Youth and various qaswida ensembles perform elaborate recitations praising the Prophet. Maulid events can last entire nights, with food distribution, communal dhikr, and lectures about the Prophet's life (sira). In Zanzibar, Maulid celebrations are particularly grand, with processions through Stone Town streets. Despite its cultural significance, there is no dedicated platform for discovering Maulid events, accessing qaswida recordings, or coordinating community celebrations.

## International Reference Apps

1. **Muslim Pro** — Islamic event listings and calendar (basic Maulid recognition)
2. **SoundCloud/YouTube** — Informal hosting of Maulid recordings and qaswida
3. **Eventbrite** — General event discovery platform (not Islamic-specific)
4. **Islamic Events App** — Islamic event listings in Muslim-majority countries
5. **Spotify** — Some qaswida/nasheed content available but poorly categorized

## Feature List

1. Maulid event listings — discover Maulid celebrations by location and date
2. Event details — venue, time, organizers, featured qaswida groups, expected program
3. Qaswida recordings — audio/video library of Maulid qaswida performances
4. Qaswida groups — profiles of well-known qaswida ensembles with their recordings
5. Maulid history — educational content about the Prophet's birth, life, and significance
6. Sira (biography) — condensed biography of Prophet Muhammad in Swahili
7. Local celebration announcements — mosques and communities post their Maulid plans
8. Live streaming — watch/listen to Maulid events live from anywhere
9. Event RSVP — indicate attendance and share with friends
10. Maulid countdown — days until 12 Rabi ul-Awwal with celebration reminders
11. Poetry/nasheed collection — traditional Maulid poems and nasheeds with text and audio
12. Photo galleries — community photos from Maulid celebrations
13. Share events — invite friends and share Maulid events on feed
14. Past events archive — recordings and photos from previous years
15. Zanzibar Maulid special — dedicated section for Zanzibar's grand celebrations
16. Food traditions — traditional Maulid foods and recipes shared during celebrations

## Key Screens

- **Maulid Home** — countdown to next Maulid, featured events, latest qaswida, history snippets
- **Events List** — upcoming Maulid events by location with date, venue, organizer
- **Event Detail** — full program, qaswida groups performing, RSVP, directions, share
- **Qaswida Library** — browsable audio/video recordings by group, year, or style
- **Qaswida Player** — audio/video player with lyrics display (Arabic and Swahili)
- **Group Profile** — qaswida group info, members, recordings, upcoming performances
- **Maulid History** — scrollable educational content about the Prophet's birth
- **Sira Reader** — biography chapters with illustrations and timeline
- **Live Stream** — real-time video/audio of active Maulid events
- **Photo Gallery** — community celebration photos organized by event and year

## TAJIRI Integration Points

- **MusicService** — qaswida recordings and nasheeds accessible through TAJIRI music player; qaswida group profiles and discographies
- **LivestreamService.createStream()** — live stream Maulid celebrations, qaswida performances, and communal dhikr sessions
- **PostService.createPost(), sharePost()** — Maulid event shares, celebration posts, qaswida recommendations to social feed
- **MessageService.sendMessage()** — share Maulid event invitations and qaswida links in chat conversations
- **CalendarService.createEvent()** — Maulid events scheduled on TAJIRI calendar; 12 Rabi ul-Awwal countdown
- **NotificationService + FCMService** — Maulid event reminders, live stream alerts, Maulid date countdown push notifications
- **PhotoService.uploadPhoto()** — community celebration photos from Maulid events; photo galleries by year
- **VideoUploadService** — Maulid event video recordings; qaswida performance videos
- **ClipService** — short qaswida clips and Maulid highlights for sharing
- **ProfileService.getProfile()** — Maulid content available to users with Muslim faith profile
- **events/ module** — Maulid celebrations appear in TAJIRI events calendar and discovery feed
- **Cross-module: Kalenda Hijri** — 12 Rabi ul-Awwal date from Islamic calendar with countdown integration via CalendarService
- **Cross-module: Tafuta Msikiti** — mosques hosting Maulid events highlighted in listings via LocationService
- **Cross-module: food/ module** — traditional Maulid food recipes crosslinked
