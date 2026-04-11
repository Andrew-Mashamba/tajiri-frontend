# Nightlife (Burudani ya Usiku) — Feature Description

## Tanzania Context

Tanzania has a vibrant nightlife scene, particularly in Dar es Salaam, Arusha, and Zanzibar. Dar es Salaam's nightlife centers around areas like Masaki, Oysterbay, Mikocheni, and the city center, with venues ranging from upscale rooftop lounges to local bars (vilabu). Popular venues include Slow Leopard, Samaki Samaki, Elements, and numerous beach bars along the Msasani Peninsula. Arusha caters to both locals and safari tourists with venues around the Njiro and city center areas. Zanzibar's Stone Town has a unique nightlife culture blending local and tourist crowds, with venues like Mercury's and Livingstone Beach Restaurant.

Currently, there is no centralized platform for discovering nightlife in Tanzania. People rely on word of mouth, Instagram, and WhatsApp group chats to find out what is happening on any given night. DJs and promoters announce events on social media, but information is fragmented. Cover charges, dress codes, and table reservation processes are often unclear. The bongo flava and amapiano music scenes drive much of the nightlife energy, with local DJs and artists performing regularly.

## International Reference Apps

1. **Discotech** — Club/nightlife discovery with guest lists, table reservations, ticket purchasing
2. **Dice** — Event discovery and ticket purchasing for music and nightlife events
3. **Resident Advisor** — Electronic music events, venue reviews, DJ profiles
4. **Xceed** — Nightlife discovery with guest lists and table booking (Europe/LatAm)
5. **Fever** — Curated nightlife and entertainment discovery with booking

## Feature List

1. Venue directory — clubs, bars, lounges, beach bars, rooftop spots with profiles
2. Tonight's events — curated list of what is happening tonight in your city
3. DJ lineups — who is playing where, with DJ profiles and music samples
4. Table reservations — request/book tables with pricing and minimum spend info
5. Cover charge info — entry fees, guest list options, VIP pricing
6. Event calendar — upcoming events, album launch parties, concerts, themed nights
7. Venue profiles — photos, location, capacity, music style, dress code, operating hours
8. Reviews and ratings — community reviews of venues with atmosphere, music, service ratings
9. Photos and videos — venue photos, event galleries, crowd shots
10. Group plans — "Who's going tonight" feature to coordinate with friends
11. Guest list signup — add your name to event guest lists for discounts or free entry
12. Drink menus — venue drink menus with pricing (where available)
13. Safety features — share live location with trusted contacts, ride-hailing quick access
14. Promoter profiles — event promoters and their upcoming events
15. Music genre filter — filter by bongo flava, amapiano, afrobeats, dancehall, house, live band
16. Happy hour listings — venues with active happy hour deals and times
17. Age verification — 18+ content gating with appropriate warnings

## Key Screens

- **Tonight Screen** — curated events happening tonight, sorted by proximity and popularity
- **Venue Directory** — map and list view of venues with genre/type filters
- **Venue Profile** — photo gallery, details, upcoming events, reviews, reserve/guest list buttons
- **Event Detail** — lineup, time, cover charge, dress code, RSVP, share, directions
- **DJ/Artist Profile** — bio, upcoming gigs, music links, social media
- **Group Plan** — create plan for tonight, invite friends, vote on venue, share status
- **Table Reservation** — select date, table type, party size, minimum spend, confirm
- **Reviews** — venue review feed with atmosphere/music/service breakdown
- **My Nightlife** — saved venues, upcoming reservations, past events, friends' plans
- **Safety Hub** — share location, emergency contacts, request ride home

## TAJIRI Integration Points

- **Wallet (WalletService)** — Pay cover charges via `WalletService.deposit()` with M-Pesa/Tigo/Airtel STK push. Table reservation deposits and minimum spend payments processed through wallet. Drink tab payments via `WalletService.transfer()` to venue. Group bill splitting for shared expenses. Event ticket purchases through wallet. Guest list fee payments. Transaction history via `WalletService.getTransactions()` shows all nightlife spending categorized by venue and event
- **Events Module (events/)** — Nightlife events appear in TAJIRI events calendar with full event system integration (committee, budget, tickets, michango). DJ sets, album launch parties, and themed nights created as events with RSVP, ticketing, and lineup details. Event-specific michango for group table reservations. VIP package booking through events ticketing
- **Posts & Stories (PostService + StoryService)** — Share "going out tonight" posts via `PostService.createPost()` with venue check-ins and friend tags. Event reviews with atmosphere, music, and service ratings. Venue check-in posts. Night out photo/video stories via `StoryService.createStory()`. `PostService.likePost()`, `PostService.sharePost()`, `PostService.commentOnPost()` for social engagement on nightlife content
- **Messaging (MessageService)** — Coordinate group plans via `MessageService.createGroup()` — create group chats for tonight's plans. Vote on venue selection within group. Share venue details and directions. Guest list coordination. Post-night photo sharing in group chat. `MessageService.sendMessage()` for venue inquiries and table reservation requests
- **Transport Module (transport/)** — Integrated ride-hailing for safe transportation to/from venues. "Request ride home" safety feature with pre-set home address. Group ride coordination for shared transport. Surge pricing alerts for late-night rides. Driver safety rating visibility
- **Music Module (music/ + MusicService)** — DJ playlists and bongo flava content linked from artist profiles via `MusicService`. Preview DJ set lists and music samples. Artist discography browsable from DJ profiles. Venue music genre tags linked to music catalog. Amapiano, afrobeats, and dancehall playlists curated from venue lineups
- **My Circle (my_circle/)** — See which friends are going out tonight. Coordinate plans with inner circle. Share live location with trusted friends during night out. "Who's nearby" discovery for mutual friends at same venue. Friend activity status (going out, at venue, heading home)
- **Friends (FriendService)** — See which friends are going to specific events via `FriendService.getFriends()`. Mutual friends at venues shown for social discovery. Group plan invitations sent through friend list. Block/safety features for unwanted contacts at venues
- **Location (LocationService)** — Venue locations with directions and estimated travel time via `LocationService.searchLocations()` using Tanzania hierarchy. Map view of tonight's hotspots. Distance-based venue discovery. GPS-based venue check-in. Share live location with safety contacts during night out
- **Notifications (FCMService + NotificationService)** — Push notifications via `FCMService` for: event reminders (tonight, 2 hours before), guest list confirmations, friend going-out activity alerts, table reservation confirmations, happy hour start alerts for favorited venues, new events from followed venues/promoters, safety check-in reminders ("Are you home safe?")
- **Profile (ProfileService)** — Nightlife preferences on profile via `ProfileService.getProfile()` — favorite genres, venues, and music styles. "Night owl" badge for active nightlife participants. Venue check-in history. Age verification status for 18+ content
- **Groups (GroupService)** — Nightlife community groups via `GroupService.createGroup()` — genre-specific groups (bongo flava lovers, amapiano fans), venue fan groups. Event promoter groups. Group posts via `GroupService.getGroupPosts()` for venue reviews and event announcements
- **Calendar (CalendarService)** — Event dates synced to calendar via `CalendarService.createEvent()`. Table reservation times. DJ set time reminders. Weekly "what's happening" digest based on favorite venues
- **Media (PhotoService + VideoUploadService)** — Venue photos and event galleries via `PhotoService.uploadPhoto()`. Photo albums for events via `PhotoService.createAlbum()`. Crowd shots and atmosphere videos. DJ performance recordings. Venue profile photo galleries
- **Presence (PresenceService)** — Show friend's "going out" status via `PresenceService`. Real-time venue crowd level indicator. Promoter online status for inquiries
- **Content Discovery (ContentEngineService + HashtagService)** — Personalized event recommendations based on music preferences and past venue visits via `ContentEngineService`. Trending nightlife hashtags (#DarNightlife, #BongoFlava, #AmapianoTZ) via `HashtagService`. Venue discovery through content engine
- **Real-time Updates (LiveUpdateService)** — Firestore listeners for real-time group plan updates. Event capacity alerts. Friend check-in notifications. Live venue status updates (crowd level, current DJ)
- **Clips (ClipService)** — Short video clips from events and venue atmospheres via `ClipService`. DJ set highlights. Venue ambiance previews. Crowd energy clips shared to TAJIRI clips feed
- **LiveStream (LivestreamService)** — Live stream DJ sets and special performances from venues via `LivestreamService.createStream()`. Virtual attendance for sold-out events. Remote nightlife experience
- **Food Module (food/)** — Late-night food ordering from nearby restaurants. Post-venue food delivery. Venue food menu integration where available
- **Budget (BudgetService)** — Nightlife spending tracked via `BudgetService`. Entertainment budget alerts. Monthly nightlife expense summaries
